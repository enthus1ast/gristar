import strutils, os
import cligen
import db_connector/db_sqlite
import glob
import nisane

type
  GristAr* = object
    pathToDb*: string
    db*: DbConn
  GristAttachment* = object
    fileName*: string
    #fileIdent*: string
    fileSize*: int
  GristAttachmentWithData* = object
    fileName*: string
    #fileIdent*: string
    fileSize*: int
    data*: string

# proc `$`*(ga: GristAttachment): string =
  

proc newGristAr*(pathToDb: string): GristAr =
  result.pathToDb = pathToDb
  result.db = open(pathToDb, "", "", "")

proc close*(gristAr: var GristAr) =
  gristAr.pathToDb = ""
  gristAr.db.close()

converter toGristAttachment*(val: GristAttachmentWithData): GristAttachment =
  result.fileSize = val.fileSize
  result.fileName = val.fileName
  # result.fileIdent = val.fileIdent

proc getLongestAttachmentName*(gristAr: GristAr): int =
  return gristAr.db.getValue(sql"""
    SELECT 
      max(length(fileName)) as len 
    FROM _grist_Attachments ;
  """).parseInt      

# template listFilesImpl(body: untyped) =
#   let maxLen = gristAr.db.getValue(
#     sql"select max(length(fileName)) as len from _grist_Attachments ;").parseInt
#   var pattern = glob(globPattern)
#   for rowRaw in gristAr.db.rows(sql"select fileName, fileSize from _grist_Attachments;"):
#     var row: GristAttachment
#     rowRaw.to(row)
#     if globPattern != "":
#       if not row.fileName.matches(pattern):
#         continue
#     yield row

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

proc getFileViaIdent*(gristAr: GristAr, fileIdent: string): GristAttachmentWithData =
  for row in gristAr.db.rows(sql"select data from _gristsys_Files where ident = ?;", fileIdent):
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

