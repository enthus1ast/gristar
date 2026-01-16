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

proc cliListFiles(path: string, globPattern = "") =
  ## list all files in a grist database
  var ar = newGristAr(path)
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


proc cat(path: string, fileName: string) =
  ## writes the content of the file to stdout
  var ar = newGristAr(path)
  let ga = ar.getFileViaName(fileName)
  ar.streamAttachmentToStdout(ga)

# import libsqliteadditions

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
