# GristAr

**GristAr** is a command-line utility designed to manipulate, list, and extract attachments from `.grist` database files. Think of it as `ar` or `sqlar`, but specifically tailored for the [Grist](https://getgrist.com) internal storage schema.

It utilizes high-performance SQLite Incremental BLOB I/O to handle large attachments efficiently without loading them entirely into memory.

## Features

- **List**: View all attachments stored in a Grist file with size summaries.
- **Extract**: Bulk export attachments to a local directory with glob pattern support.
- **Cat**: Stream attachment content directly to `stdout` for piping to other tools.

## Installation

Use prebuild binaries from here: https://github.com/enthus1ast/gristar/releases/

or build it from source

You can install GristAr and all its dependencies easily using Nimble:

```bash
nimble install gristar
# or
nimble install https://github.com/enthus1ast/gristar.git
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

Below are common usage patterns showing real terminal output.

### 1. Extract specific files

Extracting all `.jpeg` images to a temporary folder.

```console
user@host:~/projects/gristar$ gristar extractFiles -p 'data/Inventory_2026.grist' -d /tmp/images3/ -g "*.jpeg"
    138.184KiB     Product___Alpha.jpeg 
    683.696KiB     Site___Inspection.jpeg 
       1.58MiB     Architecture___Draft.jpeg 
    401.319KiB     Scan___Receipt_01.jpeg 
      1.119MiB     Chart___Q1_Results.jpeg 
    124.018KiB     Logo___Variant_A.jpeg 
    122.023KiB     Logo___Variant_B.jpeg 
    461.554KiB     Team___Offsite.jpeg 
    146.976KiB     Mockup___V2.jpeg 
      1.969MiB     Marketing___Banner.jpeg 
     63.086KiB     Icon___User.jpeg 
    129.379KiB     Icon___Settings.jpeg 
     41.036KiB     Asset___Background.jpeg 
     45.999KiB     portrait-placeholder-1-[1].jpeg 
# Sum: 6.97MiB

```

### 2. List files with a pattern

Filtering the archive list for filenames containing "Martin".

```console
user@host:~/projects/gristar$ gristar listFiles -p 'data/Inventory_2026.grist' -g="*Martin*"
    558.042KiB     Design_Spec___Martin.png 
    315.318KiB     Signature___Martin.jpg 
# Sum: 873.36KiB

```

### 3. Stream a file

Piping a PDF directly from the Grist database to a local file.

```bash
gristar cat -p 'data/Inventory_2026.grist' -f "Manual_v1.pdf" > ./local_copy.pdf

```

## License

MIT 2026. Created by [dkrause.org](https://dkrause.org).

