##        GristAr 
##
## `ar` for .grist files
## Manipulate / List / Extract 
## attachments from grist files
##
## - https://getgrist.com
## - https://dkrause.org
##

import strutils, os
import cligen
import db_connector/db_sqlite
import glob
import nisane
import libgristar

const
  everythingBiggerIsStreamed = 1024 # in bytes, smaller kept completely in ram
  streamBufferSize = 1024 # we transfer in this steps # TODO test what is fast

# CREATE TABLE "_grist_Attachments" (id INTEGER PRIMARY KEY, "fileIdent" TEXT DEFAULT '', "fileName" TEXT DEFAULT '', "fileType" TEXT DEFAULT '', "fileSize" INTEGER DEFAULT 0, "fileExt" TEXT DEFAULT '', "imageHeight" INTEGER DEFAULT 0, "imageWidth" INTEGER DEFAULT 0, "timeDeleted" DATETIME DEFAULT NULL, "timeUploaded" DATETIME DEFAULT NULL)

# sqlite> .schema _gristsys_Files
# CREATE TABLE _gristsys_Files (
#         id INTEGER PRIMARY KEY,
#         ident TEXT UNIQUE,
#         data BLOB,
#         storageId TEXT
#        );


proc cliListFiles(path: string, globPattern = "") =
  ## list all files in a grist database
  var ar = newGristAr(path)
  # let maxLen = ar.getLongestAttachmentName()
  for attachment in ar.listFiles(globPattern):
    echo attachment
  echo "# Sum: ", ar.getFileSizeSum(globPattern).formatSize()
  ar.close()


  
proc extractFiles(path: string, globPattern = "", dirToExtract: string) = 
  ## extracts all files to the given folder
  var ar = newGristAr(path)
  if not dirExists(dirToExtract):
    createDir(dirToExtract)

  var sumSize = 0
  for ga in ar.listFiles(globPattern):
    echo ga
    sumSize.inc ga.fileSize
    ar.streamAttachmentToDisk(ga, dirToExtract / ga.fileName)
  echo "# Sum: ", sumSize.formatSize()




  # for gawd in ar.listFilesWithData(globPattern):
  #   echo gawd
  #   let fh = open(dirToExtract / gawd.fileName, fmWrite)
  #   fh.write(gawd.data)
  #   fh.close()
  # echo "# Sum: ", ar.getFileSizeSum(globPattern).formatSize()
  #

  
# proc extractAllFiles(path: string, dirToExtract: string) = 

proc cat(path: string, fileName: string) =
  ## writes the content of the file to stdout
  var ar = newGristAr(path)
  let ga = ar.getFileViaName(fileName)
  ar.streamAttachmentToStdout(ga)

import libsqliteadditions
# proc test(path: string) =
#   var ar = newGristAr(path)
#   echo ar.db.getValue(sql"select 1")
#   echo ar[]
#   # 01c617b1f19646812dba3b6c3889fbc1f514b3f0.jpg
#   # 04b117aaa94bbd045b25f4d4355e67c6670d2f98.jpg
#   let destPath = "/tmp/streamout.jpg"
#
#   let blob = ar.openBlobPointerViaIdent("01c617b1f19646812dba3b6c3889fbc1f514b3f0.jpg")
#   let size = blob_bytes(blob.blob)
#   let f = open(destPath, fmWrite)
#   echo "Size: ", size.formatSize()
#   if size > everythingBiggerIsStreamed:
#     echo "We gonna stream..."
#
#   const bufsize = 1024 * 16
#   # var buffer: array[bufsize, byte]
#   var buffer = newString(bufsize)
#   var offset: int = 0
#   while offset < size:
#     let toRead = min(bufsize, size - offset)
#     echo "DEBUG: read blob chunk: ", toRead
#     if blob_read(blob.blob, addr buffer[0], toRead.int32, offset.int32) == 0:
#       f.write(buffer[0 ..< toRead])
#     offset += toRead                               
#   f.close()
#
  


     # -c, --create               Create a new archive
     # -u, --update               Add or update files with changed mtime
     # -i, --insert               Like -u but always add even if unchanged
     # -r, --remove               Remove files from archive
     # -t, --list                 List contents of archive
     # -x, --extract              Extract files from archive
     #

# when isMainModule:
#   discard
#   dispatchMulti(
#     [cliListFiles],
#     [extractFiles],
#   #  # [cat]
#   )

when isMainModule:
  dispatchMulti(
    # [test],
    [extractFiles],
    [cliListFiles, cmdName = "At", doc = "List contents of archive"],
    [cliListFiles, cmdName = "listFiles", doc = "List contents of archive"],
    # [extract,  = "x", doc = "Extract files from archive"],
    [cat, cmdName = "cat", doc = "Print file content to stdout"],
    # [insert, cmdName = "i", doc = "Insert/Update files in archive"]
  )
