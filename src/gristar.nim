import strutils, os
import cligen
import db_connector/db_sqlite
import glob
import nisane


# CREATE TABLE "_grist_Attachments" (id INTEGER PRIMARY KEY, "fileIdent" TEXT DEFAULT '', "fileName" TEXT DEFAULT '', "fileType" TEXT DEFAULT '', "fileSize" INTEGER DEFAULT 0, "fileExt" TEXT DEFAULT '', "imageHeight" INTEGER DEFAULT 0, "imageWidth" INTEGER DEFAULT 0, "timeDeleted" DATETIME DEFAULT NULL, "timeUploaded" DATETIME DEFAULT NULL)

# sqlite> .schema _gristsys_Files
# CREATE TABLE _gristsys_Files (
#         id INTEGER PRIMARY KEY,
#         ident TEXT UNIQUE,
#         data BLOB,
#         storageId TEXT
#        );

# proc listAttachments(path: string) =
#   ## list all files in a grist database
#   var db = open(path, "", "", "")
#   for row in db.rows(sql"select ident, length(data) as filesize from _gristsys_Files;"):
#     echo row[0], formatSize(row[1].parseInt()).align(20)
#   db.close()



proc listFiles(path: string, globPattern = "") =
  ## list all files in a grist database
  var db = open(path, "", "", "")
  let maxLen = db.getValue(sql"select max(length(fileName)) as len from _grist_Attachments ;").parseInt
  var pattern = glob(globPattern)
  for row in db.rows(sql"select fileName, fileSize from _grist_Attachments;"):
    if globPattern != "":
      if not row[0].matches(pattern):
        continue
    let tName = (row[0] & " ").alignLeft(maxLen, padding = ' ')
    let tSize = (formatSize(row[1].parseInt()) & " ").align(20, padding = ' ')
    echo tName, "\t", tSize
  db.close()

proc extractFiles(path: string, globPattern = "", dirToExtract: string) = 
  ## extracts all files to the given folder

  # select aa.fileName, ff.ident, ff.data from _gristsys_Files as ff INNER JOIN _grist_Attachments as aa on ff.ident = aa.fileident  ;
  # select aa.fileName, aa.fileSize, ff.ident, ff.data from _gristsys_Files as ff INNER JOIN _grist_Attachments as aa on ff.ident = aa.fileident  ;



  var db = open(path, "", "", "")
  if not dirExists(dirToExtract):
    createDir(dirToExtract)

  var pattern = glob(globPattern)
  for row in db.rows(sql"select fileName, fileSize from _grist_Attachments;"):
    if globPattern != "":
      if not row[0].matches(pattern):
        continue
    

  for row in db.rows(sql"select ident, length(data) as filesize, data from _gristsys_Files;"):
    if globPattern != "":
      if not row[0].matches(pattern):
        continue
    echo row[0], formatSize(row[1].parseInt()).align(20, padding = '.')
    let fh = open(dirToExtract / row[0], fmWrite)
    fh.write(row[2])
    fh.close()
  db.close()
  
# proc extractAllFiles(path: string, dirToExtract: string) = 

proc cat(path: string, fileIdent: string) =
  ## writes the content of the file to stdout
  var db = open(path, "", "", "")
  for row in db.rows(sql"select data from _gristsys_Files where ident = ?;", fileIdent):
    stdout.write(row[0])
    stdout.flushFile()
    return

     # -c, --create               Create a new archive
     # -u, --update               Add or update files with changed mtime
     # -i, --insert               Like -u but always add even if unchanged
     # -r, --remove               Remove files from archive
     # -t, --list                 List contents of archive
     # -x, --extract              Extract files from archive
     #

when isMainModule:
  dispatchMulti(
    [listFiles],
    [extractFiles],
    [cat]
  )
