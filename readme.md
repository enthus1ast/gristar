# GristAr

**GristAr** is a command-line utility designed to manipulate, list, and extract attachments from `.grist` database files. Think of it as `ar` or `sqlar`, but specifically tailored for the [Grist](https://getgrist.com) internal storage schema.

It utilizes high-performance SQLite Incremental BLOB I/O to handle large attachments efficiently without loading them entirely into memory.

## Features

- **List**: View all attachments stored in a Grist file with size summaries.
- **Extract**: Bulk export attachments to a local directory with glob pattern support.
- **Cat**: Stream attachment content directly to `stdout` for piping to other tools.

## Installation

You can install GristAr and all its dependencies easily using Nimble:

```bash
nimble install gristar

```

## Usage

```text
GristAr
Usage:
  gristar {SUBCMD}  [sub-command options & parameters]
where {SUBCMD} is one of:
  help          print comprehensive or per-cmd help
  extractFiles  extracts all files to the given folder globPattern is something like: "foo/*.png" "baa_*_2026.png"
  listFiles     list all files in a grist database globPattern is something like: "foo/*.png" "baa_*_2026.png"
  cat           writes the content of the file to stdout

gristar {-h|--help} or with no args at all prints this message.
gristar --help-syntax gives general cligen syntax help.
Run "gristar {help SUBCMD|SUBCMD --help}" to see help for just SUBCMD.
Run "gristar help" to get *comprehensive* help.

```

## Examples

Below are common usage patterns. Replace `my_database.grist` with the path to your file.

**Extract all files to a specific folder:**

```bash
gristar extractFiles -p my_database.grist -d /tmp/images/

```

**Extract only specific files (using wildcards):**

```bash
# Extract all files matching *Martin*
gristar extractFiles -p my_database.grist -d /tmp/images/ -g "*Martin*"

# Extract only PNGs
gristar extractFiles -p my_database.grist -d /tmp/images/ -g "*.png"

```

**List files in the archive:**

```bash
gristar listFiles -p my_database.grist

```

## License

MIT 2026. Created by [dkrause.org](https://dkrause.org).


