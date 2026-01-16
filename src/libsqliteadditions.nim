import db_connector/sqlite3


# #######################################
# Sqlite3 additions
# #######################################
when defined(windows):
  when defined(nimOldDlls):
    const Lib = "sqlite3.dll"
  elif defined(cpu64):
    const Lib = "sqlite3_64.dll"
  else:
    const Lib = "sqlite3_32.dll"
elif defined(macosx):
  const
    Lib = "libsqlite3(|.0).dylib"
else:
  const
    Lib = "libsqlite3.so(|.0)"

when defined(staticSqlite):
  {.pragma: mylib.}
  {.compile("sqlite3.c", "-O3").}
else:
  {.pragma: mylib, dynlib: Lib.}
type
  # The opaque handle for the blob
  PSqlite3Blob* = ptr object

proc blob_open*(
    db: PSqlite3, 
    zDb: cstring, 
    zTable: cstring, 
    zColumn: cstring, 
    iRow: int64, 
    flags: int32, 
    ppBlob: var PSqlite3Blob
  ): int32 {.cdecl, mylib, importc: "sqlite3_blob_open".}

proc blob_bytes*(
    pBlob: PSqlite3Blob
  ): int32 {.cdecl, mylib, importc: "sqlite3_blob_bytes".}

proc blob_read*(
    pBlob: PSqlite3Blob, 
    z: pointer, 
    n: int32, 
    iOffset: int32
  ): int32 {.cdecl, mylib, importc: "sqlite3_blob_read".}

proc blob_close*(
    pBlob: PSqlite3Blob
  ): int32 {.cdecl, mylib, importc: "sqlite3_blob_close".}

proc blob_reopen*(
    pBlob: PSqlite3Blob, 
    iRow: int64
  ): int32 {.cdecl, mylib, importc: "sqlite3_blob_reopen".}
# #######################################

