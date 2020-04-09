# Zaloha.sh

Zaloha is a small and simple directory synchronizer:

 * Zaloha is a BASH script that uses only FIND, SORT and AWK.
 * All you need is the Zaloha.sh file (contains ~76 kB of program code and ~78 kB of documentation).
 * No compilation, installation and configuration is required.
 * Cyber-secure: No new binary code, no new open ports, easily reviewable.
 * Both directories must be available locally (local HDD/SSD, flash drive, mounted Samba or NFS volume).
 * Zaloha does not lock files while copying them. No writing on either directory may occur while Zaloha runs.
 * Zaloha always copies whole files (not parts of files like RSYNC). This is, however, fully sufficient in many situations.
 * Zaloha has optional reverse-synchronization features.
 * Zaloha can optionally compare files byte by byte.
 * Zaloha prepares scripts for case of eventual restore.

Full documentation is available both [online](DOCUMENTATION.md) as well as inside of Zaloha.sh.

On Linux/Unics, Zaloha runs natively. On Windows, Cygwin is needed.

## What are synchronization programs good for ?

[Read article here](https://fitus.github.io/).

## How does Zaloha.sh work - in five sentences

 * FIND is executed to scan both directories to obtain metadata about files and subdirectories.
 * The metadata is compared via several stages of sorting and AWK processing.
 * The results (= prepared synchronization actions) are presented to the user for confirmation.
 * If the user confirms, the synchronization actions are executed.
 * A non-interactive regime is available as well.

Are you interested in knowing more? Then see this [interactive JavaScript flowchart](https://fitus.github.io/flowchart.html)
and read the relevant sections in the [documentation](DOCUMENTATION.md).

## Obtain Zaloha.sh

The simplest way: Under the green button "<b>Clone or Download</b>" above, choose "<b>Download ZIP</b>".
From the downloaded ZIP archive, extract Zaloha.sh and make it executable (<b>chmod u+x Zaloha.sh</b>).

For running the Simple Demo, extract also the scripts Simple_Demo_step1/2/3/4/5/6/7.sh and make them executable.

## Usage Example

```bash
Zaloha.sh --sourceDir="test_source" --backupDir="test_backup" [other options, see docu]
```

## Usage Screenshot
![Simple_Demo_screenshot](Simple_Demo_screenshot.png)

## Performance data

Performance was measured on following system and data:

 * Standard commodity PC with Intel i3, 3.3GHz, 4GB RAM
 * Source directory: local Seagate HDD 500GB, 7200rpm, SATA III
 * Backup directory: a second local Seagate HDD 500GB, 7200rpm, SATA III
 * Filesystem: ext4 on both HDDs
 * Data synchronized: 110 GB, 88.000 files
 * Operating system: Linux (Fedora 30)
 * Binary utilities used by Zaloha: GNU find, GNU sort, mawk
 * Zaloha options: --noRestore YES, --mawk YES, --hLinks NO, --byteByByte NO

Measured performance of the analysis phase:
 * first run: 25 seconds (filesystem data not cached in the OS)
 * second run: 5 seconds (filesystem data cached in the OS)

Performance of the execution phase:
 * depends on how many files need synchronization: zero to several minutes

## Add-on script Zaloha_Snapshot.sh

An add-on script to create hardlink-based snapshots of the backup directory exists: [Zaloha_Snapshot](https://github.com/Fitus/Zaloha_Snapshot.sh).
This allows to create **Time&nbsp;Machine**-like backup solutions.

## License
MIT License
