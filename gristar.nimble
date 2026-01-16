# Package

version       = "0.1.0"
author        = "David Krause (enthus1ast)"
description   = "extract files from grist files"
license       = "MIT"
srcDir        = "src"
bin           = @["gristar"]


# Dependencies

requires "nim >= 2.2.6"
requires "cligen"
requires "glob"
requires "nisane"
requires "nimja"
requires "db_connector"
