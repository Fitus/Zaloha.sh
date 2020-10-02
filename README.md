# Zaloha.sh

Zaloha is a small and simple directory synchronizer:

 * Zaloha is a BASH script that uses only FIND, SORT and AWK.
 * All you need is the Zaloha.sh file (contains ~76 kB of program code and ~78 kB of documentation).
 * No compilation, installation and configuration is required.
 * Cyber-secure: No new binary code, no new open ports, easily reviewable.
 * Both directories must be available locally (local HDD/SSD, flash drive, mounted Samba or NFS volume).
 * Zaloha does not lock files while copying them. No writing on either directory may occur while Zaloha runs.
 * Zaloha always copies whole files via the operating system's CP command (= no delta-transfer like in RSYNC).
 * Zaloha is not limited by memory (metadata is processed as CSV files, no limits for huge directory trees).
 * Zaloha has optional reverse-synchronization features.
 * Zaloha can optionally compare files byte by byte.
 * Zaloha prepares scripts for case of eventual restore.
 * :octocat: :octocat: :octocat: ***[Zaloha2.sh](https://github.com/Fitus/Zaloha2.sh) - new version with following new features has been released:***
 * *Optional backup to a remote backup host via SSH/SCP.*
 * *Optional backup from a remote source host via SSH/SCP.*
 * *Optional comparing contents of files via SHA-256 hashes.*

Full documentation is available both [online](DOCUMENTATION.md) as well as inside of Zaloha.sh.

On Linux/Unics, Zaloha runs natively. On Windows, Cygwin is needed.

## What are synchronization programs good for ?

[Read article here](https://fitus.github.io/).

## How does Zaloha.sh work ?

### Explained in five sentences

 * FIND is executed to scan both directories to obtain CSV metadata about files and subdirectories.
 * The CSV metadata is compared by a sequence of sorts and AWK processing steps.
 * The results (= prepared synchronization actions) are presented to the user for confirmation.
 * If the user confirms, the synchronization actions are executed.
 * A non-interactive regime is available as well.

### Explained by an Interactive Flowchart

[Open Interactive JavaScript Flowchart here](https://fitus.github.io/flowchart.html).

### Explained in full detail

Read the relevant sections in the [Documentation](DOCUMENTATION.md).

## Obtain Zaloha.sh

The simplest way: Under the green button "<b>Code</b>" above, choose "<b>Download ZIP</b>".
From the downloaded ZIP archive, extract Zaloha.sh and make it executable (<b>chmod u+x Zaloha.sh</b>).

For running the Simple Demo, extract also the scripts Simple_Demo_step1/2/3/4/5/6/7.sh and make them executable.

## Usage Examples

**Basic Usage**: Synchronize <code>test_source</code> to <code>test_backup</code>:

```bash
Zaloha.sh --sourceDir="test_source" --backupDir="test_backup"
```

Basic usage with **Colors** (on terminals with ANSI escape codes):

```bash
Zaloha.sh --sourceDir="test_source" --backupDir="test_backup" --color
```

Besides the standard synchronization,
if there are files in <code>test_backup</code> that are newer (younger) than the corresponding files in <code>test_source</code>,
copy them back to <code>test_source</code> (**Reverse-Update**):

```bash
Zaloha.sh --sourceDir="test_source" --backupDir="test_backup" --revUp
```

Besides the standard synchronization,
if there are files in <code>test_backup</code> that do not exist in <code>test_source</code>,
and those files are newer (younger) than the last run of Zaloha,
copy them back to <code>test_source</code> (**Reverse-New**):

```bash
Zaloha.sh --sourceDir="test_source" --backupDir="test_backup" --revNew
```

Do not remove objects that exist only in <code>test_backup</code> (unless they collide with new objects in <code>test_source</code>).
Simply said: If possible, **Do Not Remove** from <code>test_backup</code>, just add:

```bash
Zaloha.sh --sourceDir="test_source" --backupDir="test_backup" --noRemove
```

**Exclude directories** <code>.git</code> from the synchronization.
If such directories already exist in <code>test_backup</code>, they are considered obsolete (= removals are prepared):

```bash
Zaloha.sh --sourceDir="test_source" --backupDir="test_backup" \
          --findSourceOps='( -type d -a -name .git ) -prune -o'
```

**Exclude files** with ending <code>.NFO</code> from the synchronization.
If such files already exist in <code>test_backup</code>, they are considered obsolete (= removals are prepared):

```bash
Zaloha.sh --sourceDir="test_source" --backupDir="test_backup" \
          --findSourceOps='( -type f -a -name *.NFO ) -o'
```

**Generally Exclude files** with ending <code>.NFO</code> from the synchronization (never do anything with them:
note that <code>--findGeneralOps</code> is used instead of <code>--findSourceOps</code>):

```bash
Zaloha.sh --sourceDir="test_source" --backupDir="test_backup" \
          --findGeneralOps='+( -type f -a -name *.NFO ) -o'
```

Compare files **Byte-By-Byte** instead of by just their sizes and modification times (warning: this might take much time):

```bash
Zaloha.sh --sourceDir="test_source" --backupDir="test_backup" --byteByByte
```

Do not prepare scripts for the case of restore (**No Restore**, saves procesing time and disk space):

```bash
Zaloha.sh --sourceDir="test_source" --backupDir="test_backup" --noRestore
```

Instead of GNU AWK, use **MAWK**, the very fast AWK implementation based on a bytecode interpreter:

```bash
Zaloha.sh --sourceDir="test_source" --backupDir="test_backup" --mawk
```

Produce less screen output (**No Progress Messages**):

```bash
Zaloha.sh --sourceDir="test_source" --backupDir="test_backup" --noProgress
```

**Do Not Execute** the actions (just prepare the scripts):

```bash
Zaloha.sh --sourceDir="test_source" --backupDir="test_backup" --noExec
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
 * first run: 25 seconds (filesystem data not cached in the OS: the FINDs 2 x 12 secs, the sorts and AWKs 1 sec)
 * second run: 5 seconds (filesystem data cached in the OS: the FINDs 2 x 2 secs, the sorts and AWKs 1 sec)

Performance of the execution phase:
 * depends on how many files need synchronization: zero to several minutes

## Development status

 * From the perspective of my own requirements and ideas, Zaloha is a completed work.
 * Zaloha successfully passes all my test cases.
 * Eventual (conclusive) Problem Reports are welcome (via Issues).
 * Enhancement Requests so far they won't contradict the "small and simple synchronizer" idea (= no program code inflation, no new processing steps, no increase in runtime etc).

## Add-on script Zaloha_Snapshot.sh

An add-on script to create hardlink-based snapshots of the backup directory exists: [Zaloha_Snapshot](https://github.com/Fitus/Zaloha_Snapshot.sh).
This allows to create **Time&nbsp;Machine**-like backup solutions.

## License
MIT License
