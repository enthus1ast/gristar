# - TODO use sqlite3_open_blob and stream the blob when larger than x 
# - TODO replace a file.
# - TODO/MAYBE add files? 

import strutils, os
import cligen
import db_connector/db_sqlite
import libsqliteadditions
import glob
import nisane

type
  GristAr* = object
    pathToDb*: string
    db*: DbConn
  GristAttachment* = object
    fileName*: string
    fileSize*: int
  GristAttachmentWithData* = object ## Use this if you know you have a lot of small files
    fileName*: string
    fileSize*: int
    data*: string ## Stores the whole file
  # GristAttachmentWithStream* = object ## This conains a streaming handle where you can stream very large files as well
  #   fileName*: string
  #   fileSize*: int
  #   data*: string ## The streaming handle, to save memory on big files

  ## Consider this technique? 
  GristAttachmentKind* = enum
    MetadataOnly
    WithData
    WithStream
  GristAttachmentNew* = object
    fileName*: string
    fileSize*: int
    case kind: GristAttachmentKind 
    of MetadataOnly:
      discard
    of WithData:
      data: string
    of WithStream:
      stream: int # TODO use a stream or pointer? who knows


proc `$`*(attachment: GristAttachment | GristAttachmentWithData, maxLen = 0): string =
    let tName = (attachment.fileName & " ").alignLeft(maxLen, padding = ' ')
    let tSize = (formatSize(attachment.fileSize) & " ").align(15, padding = ' ')
    return tSize & "\t" & tName 

proc newGristAr*(pathToDb: string): GristAr =
  result.pathToDb = pathToDb
  result.db = open(pathToDb, "", "", "")

proc close*(gristAr: var GristAr) =
  gristAr.pathToDb = ""
  gristAr.db.close()

converter toGristAttachment*(val: GristAttachmentWithData): GristAttachment =
  result.fileSize = val.fileSize
  result.fileName = val.fileName

proc getLongestAttachmentName*(gristAr: GristAr): int =
  return gristAr.db.getValue(sql"""
    SELECT 
      max(length(fileName)) as len 
    FROM _grist_Attachments ;
  """).parseInt      


iterator listFiles*(gristAr: GristAr, globPattern: string): GristAttachment =
  let maxLen = gristAr.db.getValue(
    sql"select max(length(fileName)) as len from _grist_Attachments ;").parseInt
  var pattern = glob(globPattern)
  for rowRaw in gristAr.db.rows(sql"select fileName, fileSize from _grist_Attachments;"):
    var row: GristAttachment
    rowRaw.to(row)
    if globPattern != "":
      if not row.fileName.matches(pattern):
        continue
    yield row

iterator listFilesWithData*(gristAr: GristAr, globPattern: string): GristAttachmentWithData =
  let maxLen = gristAr.db.getValue(
    sql"select max(length(fileName)) as len from _grist_Attachments ;").parseInt
  var pattern = glob(globPattern)
  let qq = sql"""
    SELECT 
      aa.fileName, 
      aa.fileSize, 
      ff.data 
    FROM _gristsys_Files AS ff 
    INNER JOIN _grist_Attachments AS aa 
    ON ff.ident = aa.fileident  ;
    """
  for rowRaw in gristAr.db.rows(qq):
    var row: GristAttachmentWithData
    rowRaw.to(row)
    if globPattern != "":
      if not row.fileName.matches(pattern):
        continue
    yield row

proc getFileSizeSum*(gristAr: GristAr, globPattern: string): int =
  for ga in gristAr.listFiles(globPattern):
    result.inc ga.fileSize

proc getFileViaIdent*(gristAr: GristAr, fileIdent: string): GristAttachmentWithData =
  let qq = sql"select data from _gristsys_Files where ident = ?;"
  for row in gristAr.db.rows(qq, fileIdent):
    row.to(result)
    break

proc getFileViaName*(gristAr: GristAr, fileName: string): GristAttachmentWithData =
  let qq = sql"""
    SELECT 
      aa.fileName, 
      aa.fileSize, 
      ff.data 
    FROM _gristsys_Files AS ff 
    INNER JOIN _grist_Attachments AS aa 
    ON ff.ident = aa.fileName;
    WHERE fileName = ` 
    """
  for row in gristAr.db.rows(qq, fileName):
    row.to(result)
    break

