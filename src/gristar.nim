##              GristAr 
##
## `ar` for .grist files
## Manipulate / List / Extract 
## attachments from grist files

import strutils, os
import cligen
import db_connector/db_sqlite
import glob
import nisane
import libgristar

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
  for gawd in ar.listFilesWithData(globPattern):
    echo gawd
    let fh = open(dirToExtract / gawd.fileName, fmWrite)
    fh.write(gawd.data)
    fh.close()
  echo "# Sum: ", ar.getFileSizeSum(globPattern).formatSize()


  
# proc extractAllFiles(path: string, dirToExtract: string) = 

proc cat(path: string, fileName: string) =
  ## writes the content of the file to stdout
  var ar = newGristAr(path)
  let gawd = ar.getFileViaName(fileName)
  if gawd.fileName == "":
    return
  stdout.write(gawd.data)
  stdout.flushFile()
  return

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
    [cliListFiles, cmdName = "At", doc = "List contents of archive"],
    [cliListFiles, cmdName = "listFiles", doc = "List contents of archive"],
    # [extract,  = "x", doc = "Extract files from archive"],
    # [cat, cmdName = "cat", doc = "Print file content to stdout"],
    # [insert, cmdName = "i", doc = "Insert/Update files in archive"]
  )
