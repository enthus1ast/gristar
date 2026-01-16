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
  GristAr* = ref object
    pathToDb*: string
    db*: DbConn
  GristAttachment* = object
    fileName*: string
    fileIdent*: string
    fileSize*: int
  BlobPointer* = object # TODO # this is wrapped in an object to auto close with destructor!
   gristAr: GristAr
   blob*: PSqlite3Blob

proc newBlobPointer(gristAr: GristAr): BlobPointer =
  result.gristAr = gristAr


proc `$`*(attachment: GristAttachment, maxLen = 0): string =
    let tName = (attachment.fileName & " ").alignLeft(maxLen, padding = ' ')
    let tSize = (formatSize(attachment.fileSize) & " ").align(15, padding = ' ')
    return tSize & "\t" & tName 

proc newGristAr*(pathToDb: string): GristAr =
  result = GristAr()
  result.pathToDb = pathToDb
  result.db = open(pathToDb, "", "", "")

proc close*(gristAr: var GristAr) =
  gristAr.pathToDb = ""
  gristAr.db.close()

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
  for rowRaw in gristAr.db.rows(sql"select fileName, fileIdent, fileSize from _grist_Attachments;"):
    var row: GristAttachment
    rowRaw.to(row)
    if globPattern != "":
      if not row.fileName.matches(pattern):
        continue
    yield row


proc getFileSizeSum*(gristAr: GristAr, globPattern: string): int =
  for ga in gristAr.listFiles(globPattern):
    result.inc ga.fileSize


proc openBlobPointerViaIdent*(gristAr: GristAr, fileIdent: string): BlobPointer =
  ## Returns an opened blob pointer to the given file ident: "aasdfs...dfsadf.png"
  ## The blobpointer is closed automatically.
  ## But can also be closed manually with `closeBlobPointer`
  let id = gristAr.db.getValue(sql"SELECT id FROM _gristsys_Files WHERE ident = ?", fileIdent)
  if id == "":
    raise newException(IOError, "no file with given ident: " & fileIdent)
  let rowId: int64 = id.parseInt()
   # "main" is the default DB name; 0 is for read-only access
  if 0 != blob_open(
    gristAr.db.PSqlite3(), 
    "main".cstring, # main is the default DB name
    "_gristsys_Files".cstring,
    "data".cstring,
    rowId,
    0'i32,
    result.blob
  ): 
    raise newException(IOError, "could not open blob for ident: " & fileIdent)


proc closeBlobPointer*(blobPointer: BlobPointer) =
  ## Closes a blob pointer
  discard blob_close(blobPointer.blob)


proc `=destroy`*(blobPointer: BlobPointer) =
  discard blob_close(blobPointer.blob)
  

proc getFileViaName*(gristAr: GristAr, fileName: string): GristAttachment =
  let qq = sql"""
    SELECT 
      aa.fileName, 
      aa.fileIdent,
      aa.fileSize
    FROM _gristsys_Files AS ff 
    INNER JOIN _grist_Attachments AS aa 
    ON ff.ident = aa.fileIdent
    WHERE fileName = ?;
    """
  for row in gristAr.db.rows(qq, fileName):
    row.to(result)
    break


proc streamAttachmentToDisk*(gristAr: GristAr, attachment: GristAttachment, destPath: string) = 
  ## streams a grist attachment to disk
  const BUFSIZE = 1024 * 2
  let blob = gristAr.openBlobPointerViaIdent(attachment.fileIdent)
  let size = blob_bytes(blob.blob)
  let fh = open(destPath, fmWrite)
  var buffer = newString(BUFSIZE)
  var offset: int = 0
  while offset < size:
    let toRead = min(BUFSIZE, size - offset)
    #echo "DEBUG readChunk: ", toRead
    if blob_read(blob.blob, addr buffer[0], toRead.int32, offset.int32) == 0:
      fh.write(buffer[0 ..< toRead])
    offset += toRead                               
  fh.close()


proc streamAttachmentToStdout*(gristAr: GristAr, attachment: GristAttachment) = 
  ## streams a grist attachment to disk
  const BUFSIZE = 1024 * 4
  let blob = gristAr.openBlobPointerViaIdent(attachment.fileIdent)
  let size = blob_bytes(blob.blob)
  var buffer = newString(BUFSIZE)
  var offset: int = 0
  while offset < size:
    let toRead = min(BUFSIZE, size - offset)
    #echo "DEBUG readChunk: ", toRead
    if blob_read(blob.blob, addr buffer[0], toRead.int32, offset.int32) == 0:
      stdout.write(buffer[0 ..< toRead])
    offset += toRead                               
  stdout.flushFile()
