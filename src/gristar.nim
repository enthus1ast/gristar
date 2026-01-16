#        GristAr 
#
# `ar` for .grist files
# Manipulate / List / Extract 
# attachments from grist files
#
# - https://getgrist.com
# - https://dkrause.org
#
# MIT 2026 

import strutils, os
import cligen
import db_connector/db_sqlite
import glob
import nisane
import libgristar

proc cliListFiles(path: string, globPattern = "") =
  ## list all files in a grist database
  ## globPattern is something like:
  ##  "foo/*.png"
  ##  "baa_*_2026.png"
  var ar = newGristAr(path)
  for attachment in ar.listFiles(globPattern):
    echo attachment
  echo "# Sum: ", ar.getFileSizeSum(globPattern).formatSize()
  ar.close()


proc extractFiles(path: string, globPattern = "", dirToExtract: string) = 
  ## extracts all files to the given folder
  ## globPattern is something like:
  ##  "foo/*.png"
  ##  "baa_*_2026.png"
  var ar = newGristAr(path)
  if not dirExists(dirToExtract):
    createDir(dirToExtract)
  var sumSize = 0
  for attachment in ar.listFiles(globPattern):
    echo attachment
    sumSize.inc attachment.fileSize
    ar.streamAttachmentToDisk(attachment, dirToExtract / attachment.fileName)
  echo "# Sum: ", sumSize.formatSize()


proc cat(path: string, fileName: string) =
  ## writes the content of the file to stdout
  var ar = newGristAr(path)
  let ga = ar.getFileViaName(fileName)
  ar.streamAttachmentToStdout(ga)


when isMainModule:
  dispatchMulti(
    [extractFiles, cmdName = "extractFiles"],
    [cliListFiles, cmdName = "listFiles"],
    [cat,          cmdName = "cat"]
  )
