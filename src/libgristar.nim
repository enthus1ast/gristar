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
  GristAttachmentWithData* = object ## Use this if you know you have a lot of small files
    fileName*: string
    fileIdent*: string
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
      data*: string
    of WithStream:
      stream*: int # TODO use a stream or pointer? who knows


proc `$`*(attachment: GristAttachment | GristAttachmentWithData, maxLen = 0): string =
    let tName = (attachment.fileName & " ").alignLeft(maxLen, padding = ' ')
    let tSize = (formatSize(attachment.fileSize) & " ").align(15, padding = ' ')
    return tSize & "\t" & tName 

proc `$`*(attachment: GristAttachmentNew, maxLen = 0): string =
    let tName = (attachment.fileName & " ").alignLeft(maxLen, padding = ' ')
    let tSize = (formatSize(attachment.fileSize) & " ").align(15, padding = ' ')
    case attachment.kind
    of MetadataOnly:
      discard
    of WithData:
      discard
    of WithStream:
      discard
    return tSize & "\t" & tName 

proc newGristAr*(pathToDb: string): GristAr =
  result = GristAr()
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
  for rowRaw in gristAr.db.rows(sql"select fileName, fileIdent, fileSize from _grist_Attachments;"):
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
      aa.fileIdent
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

type 
  BlobPointer* = object # TODO # this is wrapped in an object to auto close with destructor!
   gristAr: GristAr
   blob*: PSqlite3Blob

proc newBlobPointer(gristAr: GristAr): BlobPointer =
  result.gristAr = gristAr

##proc streamBlobToFile*(db: PSqlite3, rowId: int64, destPath: string) =
##  var blob: PSqlite3Blob
##  # "main" is the default DB name; 0 is for read-only access
##  if blob_open(db, "main", "_gristsys_Files", "data", rowId, 0, blob) == 0:
##    let size = blob_bytes(blob)
##    let f = open(destPath, fmWrite)
##    
##    var buffer = newString(8192) # 8KB buffer
##    var offset: int32 = 0
##    
##    while offset < size:
##      let toRead = min(8192, size - offset)
##      if blob_read(blob, addr buffer[0], toRead.int32, offset) == 0:
##        f.write(buffer[0 ..< toRead])
##      offset += toRead
##      
##    f.close()
##    discard blob_close(blob)

proc openBlobPointerViaIdent*(gristAr: GristAr, fileIdent: string): BlobPointer =
  ## Returns an opened blob pointer to the given file ident: "aasdfs...dfsadf.png"
  ## The blobpointer is closed automatically.
  ## But can also be closed manually with `closeBlobPointer`
  let val = gristAr.db.getValue(sql"SELECT id FROM _gristsys_Files WHERE ident = ?", fileIdent)
  if val == "":
    raise newException(IOError, "no file with given ident: " & fileIdent)

  let rowId: int64 = val.parseInt()
  echo "DEBUG rowId: ", rowID

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
  echo blob_close(blobPointer.blob)

proc `=destroy`*(blobPointer: BlobPointer) =
  echo blob_close(blobPointer.blob)
  
  #echo "Destroy Blob Pointer"
  #blobPointer.gristAr.closeBlobPointer(blobPointer)
  # closeBlobPointer(blobPointer) ## TODO how to bind the gristAr? We might need to set a ref to it in newBlobPointer or so

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
    echo "DEBUG readChunk: ", toRead
    if blob_read(blob.blob, addr buffer[0], toRead.int32, offset.int32) == 0:
      fh.write(buffer[0 ..< toRead])
    offset += toRead                               
  fh.close()




  


