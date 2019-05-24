#!/bin/bash

: << 'ZALOHADOCU'
###########################################################

MIT License

Copyright (c) 2019 Fitus

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

###########################################################

OVERVIEW

Zaloha is a shellscript for synchronization of files and directories. It is a much simpler alternative to RSYNC, with key differences:

 - Zaloha is a bash shellscript that uses only FIND, SORT and AWK. All you need is THIS file. For documentation, also read THIS file.
 - Both <sourceDir> and <backupDir> must be available locally (local HDD/SSD, flash drive, mounted Samba or NFS volume).
 - Zaloha does not lock files while copying them. No writing on either directory may occur while Zaloha runs.
 - Zaloha always copies whole files (not parts of files like RSYNC). This is, however, fully sufficient in many situations.
 - Zaloha has optional reverse-synchronization features (details below).
 - Zaloha prepares scripts for case of eventual restore (details below).

To detect which files need synchronization, Zaloha compares file sizes and modification times.
It is clear that such detection is not 100% waterproof. A waterproof solution would require comparing file contents, e.g. via an MD5 checksum.
However, as such comparing would increase the runtime by orders of magnitude, it is not implemented.

Zaloha asks to confirm actions before they are executed, i.e. prepared actions can be skipped, exceptional cases manually resolved, and Zaloha re-run.
For automatic operations, use the "--noExec" option to tell Zaloha to not ask and to not execute the actions (but still prepare the scripts).

<sourceDir> and <backupDir> can be on different filesystem types if the filesystem limitations are not hit.
Such limitations are (e.g. in case of ext4 -> FAT32): not allowed characters in filenames, filename uppercase conversions, file size limits, etc.

No writing on either directory may occur while Zaloha runs (no file locking is implemented).
In demanding IT operations where backup must run concurrently with writing, a higher class of backup solution should be deployed,
like storage snapshots (must be supported by underlying OS/hardware).

Handling of "weird" characters in filenames was a special focus during development of Zaloha (details below).

On Linux/Unics, Zaloha runs natively. On Windows, Cygwin is needed.

Repository: https://github.com/Fitus/Zaloha.sh

###########################################################

MORE DETAILED DESCRIPTION

The operation of Zaloha can be partitioned into three steps, in that following actions are performed:

Exec1:    remove obsolete files/directories from <backupDir>, or objects of conflicting types which occupy needed namespace
------
RMDIR     regular remove directory from <backupDir>
REMOVE    regular remove file from <backupDir>
REMOVE.!  remove file from <backupDir> which is newer than the last run of Zaloha
REMOVE.x  remove other object on <backupDir> that occupies needed namespace, x = object type (l/p/s/c/b/D)

Exec2:    copy files/directories to <backupDir> which exist only on <sourceDir>, or files which are newer on <sourceDir>
------
MKDIR     regular create new directory on <backupDir>
NEW       regular create new file on <backupDir>
UPDATE    regular update file on <backupDir>
UPDATE.!  update file on <backupDir> which is newer than the last run of Zaloha
UPDATE.?  update file on <backupDir> by a file on <sourceDir> which is not newer (by more than 1 sec (or 3601 secs if "--ok3600s"))
unl.UP    unlink file on <backupDir> + UPDATE (can be switched off via "--noUnlink" option, see below)
unl.UP.!  unlink file on <backupDir> + UPDATE.! (can be switched off via "--noUnlink" option, see below)
unl.UP.?  unlink file on <backupDir> + UPDATE.? (can be switched off via "--noUnlink" option, see below)
ATTR:ugm  update only attributes on <backupDir> (u=user ownership, g=group ownership, m=mode) (optional feature, see below)

Exec3:    reverse-synchronization from <backupDir> to <sourceDir> (optional feature, can be activated via the "--revNew" and "--revUp" options)
------
REV.MKDI  reverse-create parent directory on <sourceDir> due to REV.NEW
REV.NEW   reverse-create file on <sourceDir> (if a standalone file on <backupDir> is newer than the last run of Zaloha)
REV.UP    reverse-update file on <sourceDir> (if the file on <backupDir> is newer than the file on <sourceDir>)
REV.UP.!  reverse-update file on <sourceDir> which is newer than the last run of Zaloha

(internal use, for completion only)
-----------------------------------
OK        object without needed action on <sourceDir> (but still to be included in restore scripts)
KEEP      keep other object on <backupDir> (= do not remove its parent directories)

Exec1:
------
This must be the first step, because objects of conflicting types on <backupDir> would prevent synchronization (e.g. a file cannot overwrite a directory).
Zaloha removes all obsolete files and directories on <backupDir>. Other objects than files and directories are removed only if they occupy namespace
needed to write files and directories to <backupDir>.

Not every "standalone" file on <backupDir> is "obsolete" if REV.NEW is active: see REV.NEW under Exec3.

Exec2:
------
Files and directories which exist only on <sourceDir> are copied to <backupDir> (action codes NEW and MKDIR).

If the same file exists on both <sourceDir> and <backupDir>, and the file on <sourceDir> is newer, Zaloha "updates" the file on <backupDir> (action code UPDATE).
If the file on <backupDir> is multiply linked (hardlinked), Zaloha removes (unlinks) it first, to prevent updating a multiply linked file,
which could lead to follow-up effects (action code unl.UP). This unlinking can be switched off via the "--noUnlink" option.

If the files differ only in attributes (u=user ownership, g=group ownership, m=mode), and attribute synchronization is switched on
via the "--pUser", "--pGroup" and "--pMode" options, then only these attributes will be synchronized (action code ATTR).
However, this is an optional feature, because: (1) the filesystem of <backupDir> might not be capable of storing these attributes,
or (2) it may be wanted that all files and directories on <backupDir> are owned by the user who runs Zaloha.

Regardless of whether these attributes are synchronized or not, an eventual restore of <sourceDir> from <backupDir> including these attributes
is possible thanks to the restore scripts which Zaloha prepares in its metadata directory (see below).

Symbolic links on <sourceDir> are neither followed nor synchronized to <backupDir>, but Zaloha prepares a restore script in its metadata directory.

Zaloha contains an optional feature to detect multiply linked (hardlinked) files on <sourceDir>.
If this feature is switched on (via the "--hLinks" option), Zaloha internally flags the second, third, etc. links to same file as "hardlinks",
and synchronizes to <backupDir> only the first link (the "file"). The "hardlinks" are not synchronized to <backupDir>, but Zaloha prepares a restore script
in its metadata directory. If this feature is switched off (no "--hLinks" option), then each link to a multiply linked file is treated as a separate regular file.
Use this feature only on filesystems of <sourceDir> which support hardlinks and for which the inode-deduplication is known to work correctly (NTFS, ext4).
Please be cautious because inode-related issues exist on some filesystems and network-mounted filesystems.

Zaloha does not synchronize other types of objects on <sourceDir> (named pipes, sockets, special devices, etc).
These objects are considered to be part of the operating system or parts of applications, and dedicated scripts for their (re-)creation should exist.

Exec3:
------
This step is optional and can be activated via the "--revNew" and "--revUp" options.

Why is this feature useful? Imagine you use a Windows notebook while working in the field.
At home, you have got a Linux server to that you regularly synchronize your data. However, sometimes you work directly on the Linux server.
That work should be "reverse-synchronized" from the Linux server (<backupDir>) back to the Windows notebook (<sourceDir>).
(Of course, assumed that the two works do not conflict).

REV.NEW: If a standalone file on <backupDir> is newer than the last run of Zaloha, and REV.NEW is active ("--revNew" option),
then that file will be reverse-copied to <sourceDir> (REV.NEW) including all necessary parent directories (REV.MKDI).

REV.UP: If the same file exists on both <sourceDir> and <backupDir>, and the file on <backupDir> is newer, and REV.UP is active
("--revUp" option), then that file will be used to reverse-update the older file on <sourceDir> (action code REV.UP).

Optionally, to preserve attributes during the REV.MKDI, REV.NEW and REV.UP operations: use options "--pRevUser", "--pRevGroup" and "--pRevMode".

If REV.NEW is not active (no "--revNew" option), then each standalone file on <backupDir> is considered obsolete (and removed).
If REV.UP is not active (no "--revUp" option), then files on <sourceDir> always update files on <backupDir> if they differ.

Reverse-synchronization to <sourceDir> increases the overall complexity of the solution. Use it only in the interactive regime of Zaloha,
where human oversight and confirmation of prepared actions are in place. Do not use it in automatic operations.

Metadata directory of Zaloha
----------------------------
Zaloha creates a metadata directory: <backupDir>/.Zaloha_metadata. The purposes of individual files in that directory are described in a separate section below.
Briefly, the metadata directory is used for:

 - AWK program files (produced from "here documents" in Zaloha)
 - CSV metadata files
 - Exec1/2/3 shellscripts
 - restore shellscripts
 - touchfile marking execution of actions

Files persist in the metadata directory until the next invocation of Zaloha.

To obtain information about what Zaloha did (counts of removed/copied files, total counts, etc), do not parse the screen output, but query the CSV metadata files.
Query the CSV files after AWKCLEANER. Do not query the raw CSV outputs of FIND commands (before AWKCLEANER) and the produced shellscripts,
because due to eventual newlines in filenames, they may contain multiple lines per "record".

Shellscripts for case of restore
--------------------------------
Zaloha prepares shellscripts for the case of restore in its metadata directory (scripts 800 through 860).
Each type of operation is contained in a separate shellscript, to give maximum freedom (= for each script, decide whether to apply or to not apply).
Further, each shellscript has a header part where key variables for whole script are defined (and can be adjusted as needed).

The script to copy files (script 810) is the most time consuming. In some situations, copying files in parallel might speed things up.
For that case, the 810 script contains support for parallel operation of up to 8 parallel processes. To utilize this, create 8 copies of the 810 script.
In first copy, keep only CP1 and TOUCH1 assigned to real commands, and assign the remaining ones to empty command (:).
Adjust the other copies accordingly. Then run the copies in parallel.

###########################################################

INVOCATION

Zaloha.sh --sourceDir=<sourceDir> --backupDir=<backupDir> [ other options ... ]

--sourceDir=<sourceDir> is mandatory. <sourceDir> must exist, otherwise Zaloha throws an error.

--backupDir=<backupDir> is mandatory. <backupDir> must exist, otherwise Zaloha throws an error.

Other options are always introduced by a double dash (--), and either have a value, or are options without a value:

--findSourceOps=<findSourceOps> are additional operands for FIND command that searches <sourceDir>. It allows to implement any filtering achievable by FIND operands.
    Please see the FIND manual page for more info. The operands must form an OR-connected chain: operandA -o operandB -o operandC -o operandD -o
    This is required because Zaloha internally combines <findSourceOps> with <findGeneralOps> and with own operands, and all of them follow this convention.
    If an earlier operand in the OR-connected chain evaluates TRUE, FIND does not evaluate following operands, leading to no output being produced.
    The main use of <findSourceOps> is to exclude individual files and directories from synchronization:

    a) to exclude whole subdirectories on <sourceDir> (= do not descend into them):
      -path <subdir path pattern> -prune -o
      -name <subdir name pattern> -prune -o

    b) to exclude individual files on <sourceDir>:
      -path <file path pattern> -o
      -name <file name pattern> -o

    <findSourceOps> applies only to <sourceDir>. If a file on <sourceDir> is excluded by <findSourceOps> and the same file exists on <backupDir>,
    then Zaloha evaluates the file on <backupDir> as obsolete (= removes it). Compare this with <findGeneralOps> (see below).

    Although <findSourceOps> consists of multiple words, it is passed in as a single string (= enclose it in double-quotes or single-quotes in your shell).
    Zaloha contains a special parser (AWKPARSER) to split it into separate words (arguments for the FIND command).
    If a pattern (word) in <findSourceOps> contains spaces, enclose it in double-quotes. Note: to protect the double-quotes from your shell, use \".
    If a pattern (word) in <findSourceOps> itself contains a double quote, use \". Note: to protect the backslash and the double-quote from your shell, use \\\".

    Please note that in the patterns of the -path and -name operands, FIND itself interprets following characters specially (see FIND documentation): *, ?, [, ], \.
    If these characters are to be taken literally, they must be backslash-escaped. Again, take care of protecting backslashes from your shell.

    <findSourceOps> may contain the placeholder ///d/ for <sourceDir> (more precisely, <sourceDir> followed by directory separator and properly escaped,
    double-quoted and eventually prepended by "./" for use in FIND patterns).

    Example: exclude directory <sourceDir>/.git, all directories Windows Security and all files My "Secret" Things (double-quoted and single-quoted versions):

    --findSourceOps="-path ///d/.git -prune -o -name \"Windows Security\" -prune -o -name \"My \\\"Secret\\\" Things\" -o"
    --findSourceOps='-path ///d/.git -prune -o -name "Windows Security" -prune -o -name "My \"Secret\" Things" -o'

--findGeneralOps=<findGeneralOps> underlies the same rules as <findSourceOps>. The key difference is that <findGeneralOps> acts on both <sourceDir> and <backupDir>.
    Hence, generally speaking, it can be used to constrain synchronization to only subsets of files and directories, based on filtering by FIND operands.
    The main use of <findGeneralOps> is to exclude "Trash" directories from synchronization. <findGeneralOps> has an internally defined default, used to exclude:

    <sourceDir or backupDir>/$RECYCLE.BIN               ... Windows Recycle Bin (assumed to exist directly under <sourceDir> or <backupDir>)
    <sourceDir or backupDir>/.Trash_<number>*           ... Linux Trash (assumed to exist directly under <sourceDir> or <backupDir>)
    <sourceDir or backupDir>/lost+found                 ... Linux lost filesystem fragments (assumed to exist directly under <sourceDir> or <backupDir>)

    The placeholder ///d/ is for <sourceDir> or <backupDir>, depending on the actual search.
    To extend (= combine, not replace) the internally defined <findGeneralOps> with own extension, pass in own extension prepended by plus sign ("+").

--noExec        ... needed if Zaloha is invoked automatically: do not ask, do not execute the actions (but still prepare the scripts, see further notes below)

--revNew        ... activate REV.NEW (= if standalone file on <backupDir> is newer than the last run of Zaloha, reverse-copy it to <sourceDir>)

--revUp         ... activate REV.UP (= if file on <backupDir> is newer than file on <sourceDir>, reverse-update the file on <sourceDir>)

--hLinks        ... perform hardlink detection (inode-deduplication) on <sourceDir>

--ok3600s       ... additional tolerance for modification time differences of exactly +/- 3600 seconds (explained below)

--noUnlink      ... never unlink multiply linked files on <backupDir> before writing to them

--touch         ... use cp + touch instead of cp --preserve=timestamps (explained below)

--pUser         ... synchronize user ownerships on <backupDir> based on <sourceDir>

--pGroup        ... synchronize group ownerships on <backupDir> based on <sourceDir>

--pMode         ... synchronize modes (permission bits) on <backupDir> based on <sourceDir>

--pRevUser      ... preserve user ownerships during REV operations

--pRevGroup     ... preserve group ownerships during REV operations

--pRevMode      ... preserve modes (permission bits) during REV operations

--noProgress    ... suppress progress messages (less screen output)

--color         ... use color highlighting (can be used on terminals which support ANSI escape codes)

--wTest         ... (do not use in real operations) support for special testing of weird characters in filenames

--lTest         ... (do not use in real operations) support for lint-testing of AWK programs

If option "--noExec" is used, Zaloha does not execute the actions, but still prepares the scripts. The prepared scripts do not contain shell tracing
and they do not contain the "set -e" instruction. Also, the scripts ignore individual failed commands and try to do as much work as possible, which is
a behavior different from the interactive regime, where scripts are traced and halt on the first error.

If both options "--noExec" and "--noProgress" are used, Zaloha does not produce any output on stdout (traditional behavior of Unics tools).

Zaloha must be run by a user with sufficient privileges to read <sourceDir> and to write and perform other required actions on <backupDir>.
In case of the REV actions, privileges to write and perform other required actions on <sourceDir> are required as well.
Zaloha does not contain any internal checks as to whether privileges are sufficient. Failures of commands run by Zaloha must be monitored instead.

Zaloha does not contain protection against concurrent invocations with conflicting <backupDir> (and for REV also conflicting <sourceDir>): this is a responsibility
of the invoker, especially due to the fact that Zaloha may conflict with other processes as well.

In case of failure: resolve the problem and re-run Zaloha with same parameters.
In the second run, Zaloha should not repeat the actions completed by the first run: it should continue from the action on which the first run failed.
If the first run completed successfully, no actions should be performed in the second run (this is an important test case, see below).

Typically, Zaloha is invoked by a wrapper script that does the necessary directory mounts, then runs Zaloha with the required parameters, then directory unmounts.

###########################################################

TESTING, DEPLOYMENT, INTEGRATION

First, test Zaloha on a small and noncritical set of your data. Although Zaloha has been tested on several environments, it can happen that Zaloha malfunctions on
your environment due to different behavior of the operating system, bash, FIND, SORT, AWK and other utilities. Perform tests in the interactive regime first.
If Zaloha prepares wrong actions, abort to skip the executions.

After first synchronization, an important test is to run second synchronization, which should execute no actions, as the directories should be already synchronized.

Test Zaloha under all scenarios which can occur on your environment. Test Zaloha with filenames containing "weird" or national characters.

Verify that all your programs that write to <sourceDir> change modification times of the files written, so that Zaloha does not miss changed files.

Simulate the loss of <sourceDir> and perform test of the recovery scenario using the recovery scripts prepared by Zaloha.

Automatic operations
--------------------

Additional care must be taken when using Zaloha in automatic operations ("--noExec" option):

Exit status and standard error of Zaloha and of the scripts prepared by Zaloha must be monitored by a monitoring system used within your IT landscape.
Nonzero exit status and writes to standard error must be brought to attention and investigated. If Zaloha itself fails, the process must be aborted.
The scripts prepared under the "--noExec" option do not halt on the first error, also their zero exit status does not imply that there were no failed individual commands.

Implement sanity checks to avoid data disasters like synchronizing <sourceDir> to <backupDir> in the moment when <sourceDir> is unmounted, which would lead
to loss of backup data. Evaluate counts of actions prepared by Zaloha (count records in CSV files in Zaloha metadata directory). Abort the process if the
action counts exceed sanity thresholds defined by you, e.g. when Zaloha prepares an unexpectedly high number of removals.

The process which invokes Zaloha in automatic regime should function as follows (pseudocode):

  run Zaloha.sh --noExec
  in case of fail: abort process
  perform sanity checks on prepared actions
  if ( sanity checks OK ) then
    execute script 610_exec1.sh
    execute script 620_exec2.sh
    execute script 630_exec3.sh
    monitor execution (writing to stderr)
    if ( execution successful ) then
      execute script 690_touch.sh
    end if
  end if

###########################################################

SPECIAL AND CORNER CASES

To detect which files need synchronization, Zaloha compares file sizes and modification times. If the file sizes differ, synchronization is needed.
The modification time is more tricky: Zaloha tolerates +/- 1 second differences, due to FAT32 rounding to the nearest 2 seconds.
Additionally, when daylight saving time is incorrectly set up on the OS level, it is necessary to tolerate differences of exactly +/- 1 hour (+/- 3600 seconds) as well.
This can be activated via the "--ok3600s" option.

<backupDir> can be a subdirectory of <sourceDir> or vice versa. In such cases, conditions to avoid recursive copying must be passed in via <findGeneralOps>.

The sorting order of the internally used SORT commands is influenced by locale (environment variable LC_COLLATE, or LC_ALL). However, the only requirements of Zaloha
are that equal values are adjacent in the sorted output and shorter matching substrings (parent directories) come first, and this should be fulfilled in any case.

In some situations (e.g. Linux Samba + Linux Samba client), cp --preserve=timestamps does not preserve modification timestamps (unless on empty files).
In that case, Zaloha should be instructed (via the "--touch" option) to use subsequent touch commands instead, which is a more robust solution.
In the scripts for case of restore, touch commands are used unconditionally.

Corner case REV.NEW + namespace on <sourceDir> needed for REV.MKDI or REV.NEW action is occupied by object of conflicting type:
The file on <backupDir> will not be reverse-copied to <sourceDir>, but removed. As this file is newer than the last run of Zaloha, the action will be REMOVE.!.

Corner case REV.NEW + <findSourceOps>: If the same file exists on both <sourceDir> and <backupDir>, and on <sourceDir> that file is excluded by <findSourceOps>
and on <backupDir> that file is newer than the last run of Zaloha, REV.NEW on that file will be prepared. This is an error which Zaloha is unable to detect.
Hence, the shellscript for Exec3 contains a test that throws an error in such situation.

Corner case REV.UP + "--ok3600s": The "--ok3600s" option makes it harder to determine which file is newer (decision UPDATE vs REV.UP).
The implemented solution for that case is that for REV.UP, the <backupDir> file must be newer by more than 3601 seconds.

Corner case REV.UP + hardlinked file: Reverse-updating a multiply linked (hardlinked) file on <sourceDir> may lead to follow-up effects.

Corner case REV.UP + "--hLinks": If hardlink detection on <sourceDir> is active ("--hLinks" option), then Zaloha supports reverse-update of only the first link
on <sourceDir> (the one that stays tagged as "file" (f) in CSV data after AWKHLINKS).

Corner case if directory .Zaloha_metadata exists under <sourceDir> as well (e.g. in case of backups of backups): It will be ignored. If a backup of that directory
is needed as well, it should be solved separately (Hint: if the secondary backup starts one directory higher, then .Zaloha_metadata of the original backup will be taken).

###########################################################

HOW ZALOHA WORKS INTERNALLY

Handling and checking of input parameters should be self-explanatory.

The actual program logic is embodied in AWK programs, which are contained in Zaloha as "here documents".

The AWK program AWKPARSER parses the FIND arguments assembled from <findSourceOps> and <findGeneralOps> and constructs the FIND commands.
The outputs of these FIND commands are tab-separated CSV files that contain all data needed for following steps.
These CSV files, however, must first be processed by AWKCLEANER to handle (escape) eventual tabs and newlines in filenames.

The cleaned CSV files are then checked by AWKCHECKER for unexpected deviations (in which case an error is thrown and the processing stops).

The next (optional) step is to detect hardlinks: the CSV file from <sourceDir> is sorted by device number + inode number. This means that multiply-linked files
will be in adjacent records. The AWK program AWKHLINKS evaluates this situation: The type of the first link will be kept as "file" (f),
the types of the other links will be changed to "hardlinks" (h).

Then comes the core function of Zaloha. The CSV files from <sourceDir> and <backupDir> will be united and sorted by filename and the <sourceDir>/<backupDir> indicator.
This means that objects existing in both directories will be in adjacent records, with the <backupDir> record coming first.
The AWK program AWKDIFF evaluates this situation (as well as records from objects existing in only one of the directories), and writes target state
of synchronized directories with actions to reach that target state.

The output of AWKDIFF is then sorted by filename in reverse order (so that parent directories come after their children) and post-processed by AWKPOSTPROC.
AWKPOSTPROC modifies actions on parent directories of files to REV.NEW and other objects to KEEP on <backupDir>.

The remaining code uses the produced data to perform actual work, and should be self-explanatory.

###########################################################

TECHNIQUES FOR HANDLING OF WEIRD CHARACTERS IN FILENAMES

Handling of "weird" characters in filenames was a special focus during development of Zaloha.
Actually, it was an exercise of how far can be gone with shellscript alone, without reverting to a C program.
Tested were: !"#$%&'()*+,-.:;<=>?@[\]^`{|}~, spaces, tabs, newlines, alert (bell) and few national characters (above ASCII 127).
Please note that on some filesystem types, some weird characters are not allowed at all.

Zaloha internally uses tab-separated CSV files, also tabs and newlines are major disruptors. The solution is based on following idea:
POSIX (the most "liberal" standard under which Zaloha must function) says that filenames may contain all characters except slash (/, the directory separator)
and ASCII NUL. Hence, no character except these two can be used as an escape character. Also, let us have a look at the directory separator itself:
It cannot occur inside of filenames, and it separates file and directory names in the paths. As filenames cannot have zero length, no two slashes can appear in sequence.
The only exception is the naming convention for network-mounted directories, which may contain two consecutive slashes at the beginning.
But three consecutive slashes (a triplet ///) are impossible. Hence, it is a waterproof escape sequence.
This opens the way to represent a tab as ///t and newline as ///n.

For display of filenames on terminal (and only there), control characters (other than tabs and newlines) are displayed as ///c, to avoid terminal disruption.
(Such control characters are still original in the CSV files).

Further, /// are used as leading fields in the CSV files, to allow easy separation of record lines from continuation lines caused by newlines in filenames
(it is impossible that continuation lines have /// as the first field, because filenames cannot contain the newline + /// sequence).

Finally, /// are used as terminator fields in the CSV files, to be able to determine where the filenames end in a situation when they contain tabs and newlines
(it is impossible that filenames produce a field containing /// alone, because filenames cannot contain the tab + /// sequence).

An additional challenge is passing of variable values to AWK. During its lexical parsing, AWK interprets backslash-led escape sequences.
To avoid this, backslashes are converted to ///b in the bash script, and ///b are converted back to backslashes in the AWK programs.

Zaloha checks that no input parameters contain ///, to avoid breaking of the internal quoting rules from the outside.
The only exception are <findSourceOps> and <findGeneralOps>, which may contain the ///d/ sequence.

In the shellscripts produced by Zaloha, single quoting is used, hence single quotes are disruptors. As a solution, the '"'"' quoting technique is used.

Zaloha does not contain any explicit handling of national characters in filenames (= characters above ASCII 127).
It is assumed that the commands used by Zaloha handle them transparently (which should be tested on environments where national characters are used in filenames).
<sourceDir> and <backupDir> must use the same code page for national characters in filenames, because Zaloha does not contain any code page conversions.

###########################################################

DEFINITION OF INDIVIDUAL FILES IN METADATA DIRECTORY OF ZALOHA:
ZALOHADOCU

metadataDir=".Zaloha_metadata"           # Metadata directory of Zaloha, located directly under <backupDir>

f000Base="000_parameters.csv"            # parameters under which Zaloha was invoked and internal variables

f100Base="100_awkpreproc.awk"            # AWK preprocessor for other AWK programs
f102Base="102_xtrace2term.awk"           # AWK program for terminal display of shell traces (with control characters escaped), including color handling
f104Base="104_actions2term.awk"          # AWK program for terminal display of actions (with control characters escaped), including color handling
f106Base="106_parser.awk"                # AWK program for parsing of find arguments and construction of FIND commands
f110Base="110_cleaner.awk"               # AWK program for handling of tabs and newlines in raw outputs of FIND
f130Base="130_checker.awk"               # AWK program for checking
f150Base="150_hlinks.awk"                # AWK program for hardlink detection (inode-deduplication)
f170Base="170_diff.awk"                  # AWK program for difference processing
f190Base="190_postproc.awk"              # AWK program for difference post-processing and splitting off Exec1 actions

f200Base="200_find_lastrun.sh"           # shellscript for FIND on <backupDir>/<zalohaDir>/999_mark_executed
f210Base="210_find_source.sh"            # shellscript for FIND on <sourceDir>
f220Base="220_find_backup.sh"            # shellscript for FIND on <backupDir>

f300Base="300_lastrun.csv"               # output of FIND on <backupDir>/<zalohaDir>/999_mark_executed
f310Base="310_source_raw.csv"            # raw output of FIND on <sourceDir>
f320Base="320_backup_raw.csv"            # raw output of FIND on <backupDir>
f330Base="330_source_clean.csv"          # <sourceDir> file list cleaned (escaped tabs and newlines)
f340Base="340_backup_clean.csv"          # <backupDir> file list cleaned (escaped tabs and newlines)
f350Base="350_source_s_hlinks.csv"       # <sourceDir> file list sorted for hardlink detection (inode-deduplication)
f360Base="360_source_hlinks.csv"         # <sourceDir> file list after hardlink detection (inode-deduplication)
f370Base="370_union_s_diff.csv"          # <sourceDir> + <backupDir> file lists united and sorted for difference processing
f380Base="380_diff.csv"                  # result of difference processing (target state with actions)
f390Base="390_diff_r_post.csv"           # difference result reverse sorted for post-processing and splitting off Exec1 actions

f405Base="405_select23.awk"              # AWK program for selection of Exec2 and Exec3 actions
f410Base="410_exec1.awk"                 # AWK program for preparation of shellscript for Exec1
f420Base="420_exec2.awk"                 # AWK program for preparation of shellscript for Exec2
f430Base="430_exec3.awk"                 # AWK program for preparation of shellscript for Exec3
f490Base="490_touch.awk"                 # AWK program for preparation of shellscript to touch file 999_mark_executed

f500Base="500_target_r.csv"              # target state of synchronized directories reverse sorted
f505Base="505_target.csv"                # target state of synchronized directories
f510Base="510_exec1.csv"                 # Exec1 actions (reverse sorted)
f520Base="520_exec2.csv"                 # Exec2 actions
f530Base="530_exec3.csv"                 # Exec3 actions

f610Base="610_exec1.sh"                  # shellscript for Exec1
f620Base="620_exec2.sh"                  # shellscript for Exec2
f630Base="630_exec3.sh"                  # shellscript for Exec3
f690Base="690_touch.sh"                  # shellscript to touch file 999_mark_executed

f700Base="700_restore.awk"               # AWK program for preparation of shellscripts for the case of restore

f800Base="800_restore_dirs.sh"           # for the case of restore: shellscript to restore directories
f810Base="810_restore_files.sh"          # for the case of restore: shellscript to restore files
f820Base="820_restore_sym_links.sh"      # for the case of restore: shellscript to restore symbolic links
f830Base="830_restore_hardlinks.sh"      # for the case of restore: shellscript to restore hardlinks
f840Base="840_restore_user_own.sh"       # for the case of restore: shellscript to restore user ownerships
f850Base="850_restore_group_own.sh"      # for the case of restore: shellscript to restore group ownerships
f860Base="860_restore_mode.sh"           # for the case of restore: shellscript to restore modes (permission bits)

f999Base="999_mark_executed"             # empty touchfile marking execution of actions

###########################################################
set -e
set -u
set -o pipefail

function error_exit {
  echo "Zaloha.sh: ${1}" >&2
  exit 1
}

trap 'error_exit "Error on line ${LINENO}"' ERR

function start_progress {
  if [ ${noProgress} -eq 0 ]; then
    echo -n "    ${1} ${DOTS50:1:$(( 47 - ${#1} ))} "
  fi
}

function stop_progress {
  if [ ${noProgress} -eq 0 ]; then
    echo "done."
  fi
}

TAB=$'\t'
NLINE=$'\n'
BSLASHPATTERN="\\\\"
DQUOTEPATTERN="\\\""
DQUOTE="\""
ASTERISKPATTERN="\\*"
ASTERISK="*"
QUESTIONMARKPATTERN="\\?"
QUESTIONMARK="?"
LBRACKETPATTERN="\\["
LBRACKET="["
RBRACKETPATTERN="\\]"
RBRACKET="]"
CNTRLPATTERN="[[:cntrl:]]"
TRIPLETDSEP="///d/"         # placeholder for <sourceDir> or <backupDir> followed by directory separator
TRIPLETT="///t"             # escape for tab
TRIPLETN="///n"             # escape for newline
TRIPLETB="///b"             # escape for backslash
TRIPLETC="///c"             # display of control characters on terminal
TRIPLET="///"               # escape sequence, leading field, terminator field

FSTAB=$'\t'
TERMNORM=$'\033'"[0m"
TERMBLUE=$'\033'"[94m"
DOTS10=".........."
DOTS50="${DOTS10}${DOTS10}${DOTS10}${DOTS10}${DOTS10}"

###########################################################
sourceDir=
backupDir=
findSourceOps=
findGeneralOps=
noExec=0
revNew=0
revUp=0
hLinks=0
ok3600s=0
noUnlink=0
touch=0
pUser=0
pGroup=0
pMode=0
pRevUser=0
pRevGroup=0
pRevMode=0
noProgress=0
color=0
wTest=0
lTest=0

for tmpVal in "${@}"
do
  case ${tmpVal} in
    --sourceDir=*)       sourceDir="${tmpVal#*=}";        shift ;;
    --backupDir=*)       backupDir="${tmpVal#*=}";        shift ;;
    --findSourceOps=*)   findSourceOps="${tmpVal#*=}";    shift ;;
    --findGeneralOps=*)  findGeneralOps="M${tmpVal#*=}";  shift ;;
    --noExec)            noExec=1 ;                       shift ;;
    --revNew)            revNew=1 ;                       shift ;;
    --revUp)             revUp=1 ;                        shift ;;
    --hLinks)            hLinks=1 ;                       shift ;;
    --ok3600s)           ok3600s=1 ;                      shift ;;
    --noUnlink)          noUnlink=1 ;                     shift ;;
    --touch)             touch=1 ;                        shift ;;
    --pUser)             pUser=1 ;                        shift ;;
    --pGroup)            pGroup=1 ;                       shift ;;
    --pMode)             pMode=1 ;                        shift ;;
    --pRevUser)          pRevUser=1 ;                     shift ;;
    --pRevGroup)         pRevGroup=1 ;                    shift ;;
    --pRevMode)          pRevMode=1 ;                     shift ;;
    --noProgress)        noProgress=1 ;                   shift ;;
    --color)             color=1 ;                        shift ;;
    --wTest)             wTest=1 ;                        shift ;;
    --lTest)             lTest=1 ;                        shift ;;
    *) error_exit "Unknown option: ${tmpVal}" ;;
  esac
done

###########################################################
if [ "" == "${sourceDir}" ]; then
    error_exit "<sourceDir> is mandatory"
fi
if [ "${sourceDir/${TRIPLET}/}" != "${sourceDir}" ]; then
    error_exit "<sourceDir> contains the directory separator triplet (${TRIPLET})"
fi
if [ "/" != "${sourceDir:0:1}" ] && [ "./" != "${sourceDir:0:2}" ]; then
    sourceDir="./${sourceDir}"
fi
if [ "/" != "${sourceDir: -1:1}" ]; then
    sourceDir="${sourceDir}/"
fi
if [ ! -d "${sourceDir}" ] && [ ${wTest} -eq 0 ]; then
    error_exit "<sourceDir> is not a directory"
fi
sourceDirAwk="${sourceDir//${BSLASHPATTERN}/${TRIPLETB}}"
sourceDirParsAwk="${sourceDirAwk//${DQUOTEPATTERN}/${TRIPLETB}${DQUOTE}}"
sourceDirParsPattAwk="${sourceDir//${BSLASHPATTERN}/${TRIPLETB}${TRIPLETB}}"
sourceDirParsPattAwk="${sourceDirParsPattAwk//${DQUOTEPATTERN}/${TRIPLETB}${DQUOTE}}"
sourceDirParsPattAwk="${sourceDirParsPattAwk//${ASTERISKPATTERN}/${TRIPLETB}${ASTERISK}}"
sourceDirParsPattAwk="${sourceDirParsPattAwk//${QUESTIONMARKPATTERN}/${TRIPLETB}${QUESTIONMARK}}"
sourceDirParsPattAwk="${sourceDirParsPattAwk//${LBRACKETPATTERN}/${TRIPLETB}${LBRACKET}}"
sourceDirParsPattAwk="${sourceDirParsPattAwk//${RBRACKETPATTERN}/${TRIPLETB}${RBRACKET}}"
sourceDirEsc="${sourceDir//${TAB}/${TRIPLETT}}"
sourceDirEsc="${sourceDirEsc//${NLINE}/${TRIPLETN}}"
if [ ${color} -eq 1 ]; then
  sourceDirTerm="${sourceDirEsc//${CNTRLPATTERN}/${TERMBLUE}${TRIPLETC}${TERMNORM}}"
  sourceDirTerm="${sourceDirTerm//${TRIPLETT}/${TERMBLUE}${TRIPLETT}${TERMNORM}}"
  sourceDirTerm="${sourceDirTerm//${TRIPLETN}/${TERMBLUE}${TRIPLETN}${TERMNORM}}"
else
  sourceDirTerm="${sourceDirEsc//${CNTRLPATTERN}/${TRIPLETC}}"
fi

###########################################################
if [ "" == "${backupDir}" ]; then
    error_exit "<backupDir> is mandatory"
fi
if [ "${backupDir/${TRIPLET}/}" != "${backupDir}" ]; then
    error_exit "<backupDir> contains the directory separator triplet (${TRIPLET})"
fi
if [ "/" != "${backupDir:0:1}" ] && [ "./" != "${backupDir:0:2}" ]; then
    backupDir="./${backupDir}"
fi
if [ "/" != "${backupDir: -1:1}" ]; then
    backupDir="${backupDir}/"
fi
if [ ! -d "${backupDir}" ]; then
    error_exit "<backupDir> is not a directory"
fi
backupDirAwk="${backupDir//${BSLASHPATTERN}/${TRIPLETB}}"
backupDirParsAwk="${backupDirAwk//${DQUOTEPATTERN}/${TRIPLETB}${DQUOTE}}"
backupDirParsPattAwk="${backupDir//${BSLASHPATTERN}/${TRIPLETB}${TRIPLETB}}"
backupDirParsPattAwk="${backupDirParsPattAwk//${DQUOTEPATTERN}/${TRIPLETB}${DQUOTE}}"
backupDirParsPattAwk="${backupDirParsPattAwk//${ASTERISKPATTERN}/${TRIPLETB}${ASTERISK}}"
backupDirParsPattAwk="${backupDirParsPattAwk//${QUESTIONMARKPATTERN}/${TRIPLETB}${QUESTIONMARK}}"
backupDirParsPattAwk="${backupDirParsPattAwk//${LBRACKETPATTERN}/${TRIPLETB}${LBRACKET}}"
backupDirParsPattAwk="${backupDirParsPattAwk//${RBRACKETPATTERN}/${TRIPLETB}${RBRACKET}}"
backupDirEsc="${backupDir//${TAB}/${TRIPLETT}}"
backupDirEsc="${backupDirEsc//${NLINE}/${TRIPLETN}}"
if [ ${color} -eq 1 ]; then
  backupDirTerm="${backupDirEsc//${CNTRLPATTERN}/${TERMBLUE}${TRIPLETC}${TERMNORM}}"
  backupDirTerm="${backupDirTerm//${TRIPLETT}/${TERMBLUE}${TRIPLETT}${TERMNORM}}"
  backupDirTerm="${backupDirTerm//${TRIPLETN}/${TERMBLUE}${TRIPLETN}${TERMNORM}}"
else
  backupDirTerm="${backupDirEsc//${CNTRLPATTERN}/${TRIPLETC}}"
fi

###########################################################
tmpVal="${findSourceOps//${TRIPLETDSEP}/M}"
if [ "${tmpVal/${TRIPLET}/}" != "${tmpVal}" ]; then
    error_exit "<findSourceOps> contains the directory separator triplet (${TRIPLET})"
fi
findSourceOpsAwk="${findSourceOps//${BSLASHPATTERN}/${TRIPLETB}}"
findSourceOpsEsc="${findSourceOps//${TAB}/${TRIPLETT}}"
findSourceOpsEsc="${findSourceOpsEsc//${NLINE}/${TRIPLETN}}"

###########################################################
findGeneralOpsInternal=
findGeneralOpsInternal="${findGeneralOpsInternal} -ipath ${TRIPLETDSEP}\$RECYCLE.BIN -prune -o"
findGeneralOpsInternal="${findGeneralOpsInternal} -path ${TRIPLETDSEP}.Trash-[0-9]* -prune -o"
findGeneralOpsInternal="${findGeneralOpsInternal} -path ${TRIPLETDSEP}lost+found -prune -o"
if [ "M+" == "${findGeneralOps:0:2}" ]; then
    findGeneralOps="${findGeneralOpsInternal} ${findGeneralOps:2}"
elif [ "M" == "${findGeneralOps:0:1}" ]; then
    findGeneralOps="${findGeneralOps:1}"
else
    findGeneralOps="${findGeneralOpsInternal}"
fi
tmpVal="${findGeneralOps//${TRIPLETDSEP}/M}"
if [ "${tmpVal/${TRIPLET}/}" != "${tmpVal}" ]; then
    error_exit "<findGeneralOps> contains the directory separator triplet (${TRIPLET})"
fi
findGeneralOpsAwk="${findGeneralOps//${BSLASHPATTERN}/${TRIPLETB}}"
findGeneralOpsEsc="${findGeneralOps//${TAB}/${TRIPLETT}}"
findGeneralOpsEsc="${findGeneralOpsEsc//${NLINE}/${TRIPLETN}}"

###########################################################
if [ ! -d "${backupDir}${metadataDir}" ]; then
  mkdir "${backupDir}${metadataDir}"
fi

f000="${backupDir}${metadataDir}/${f000Base}"
f100="${backupDir}${metadataDir}/${f100Base}"
f102="${backupDir}${metadataDir}/${f102Base}"
f104="${backupDir}${metadataDir}/${f104Base}"
f106="${backupDir}${metadataDir}/${f106Base}"
f110="${backupDir}${metadataDir}/${f110Base}"
f130="${backupDir}${metadataDir}/${f130Base}"
f150="${backupDir}${metadataDir}/${f150Base}"
f170="${backupDir}${metadataDir}/${f170Base}"
f190="${backupDir}${metadataDir}/${f190Base}"
f200="${backupDir}${metadataDir}/${f200Base}"
f210="${backupDir}${metadataDir}/${f210Base}"
f220="${backupDir}${metadataDir}/${f220Base}"
f300="${backupDir}${metadataDir}/${f300Base}"
f310="${backupDir}${metadataDir}/${f310Base}"
f320="${backupDir}${metadataDir}/${f320Base}"
f330="${backupDir}${metadataDir}/${f330Base}"
f340="${backupDir}${metadataDir}/${f340Base}"
f350="${backupDir}${metadataDir}/${f350Base}"
f360="${backupDir}${metadataDir}/${f360Base}"
f370="${backupDir}${metadataDir}/${f370Base}"
f380="${backupDir}${metadataDir}/${f380Base}"
f390="${backupDir}${metadataDir}/${f390Base}"
f405="${backupDir}${metadataDir}/${f405Base}"
f410="${backupDir}${metadataDir}/${f410Base}"
f420="${backupDir}${metadataDir}/${f420Base}"
f430="${backupDir}${metadataDir}/${f430Base}"
f490="${backupDir}${metadataDir}/${f490Base}"
f500="${backupDir}${metadataDir}/${f500Base}"
f505="${backupDir}${metadataDir}/${f505Base}"
f510="${backupDir}${metadataDir}/${f510Base}"
f520="${backupDir}${metadataDir}/${f520Base}"
f530="${backupDir}${metadataDir}/${f530Base}"
f610="${backupDir}${metadataDir}/${f610Base}"
f620="${backupDir}${metadataDir}/${f620Base}"
f630="${backupDir}${metadataDir}/${f630Base}"
f690="${backupDir}${metadataDir}/${f690Base}"
f700="${backupDir}${metadataDir}/${f700Base}"
f800="${backupDir}${metadataDir}/${f800Base}"
f810="${backupDir}${metadataDir}/${f810Base}"
f820="${backupDir}${metadataDir}/${f820Base}"
f830="${backupDir}${metadataDir}/${f830Base}"
f840="${backupDir}${metadataDir}/${f840Base}"
f850="${backupDir}${metadataDir}/${f850Base}"
f860="${backupDir}${metadataDir}/${f860Base}"
f999="${backupDir}${metadataDir}/${f999Base}"

f300Awk="${backupDirAwk}${metadataDir}/${f300Base}"
f310Awk="${backupDirAwk}${metadataDir}/${f310Base}"
f320Awk="${backupDirAwk}${metadataDir}/${f320Base}"
f500Awk="${backupDirAwk}${metadataDir}/${f500Base}"
f510Awk="${backupDirAwk}${metadataDir}/${f510Base}"
f520Awk="${backupDirAwk}${metadataDir}/${f520Base}"
f530Awk="${backupDirAwk}${metadataDir}/${f530Base}"
f800Awk="${backupDirAwk}${metadataDir}/${f800Base}"
f810Awk="${backupDirAwk}${metadataDir}/${f810Base}"
f820Awk="${backupDirAwk}${metadataDir}/${f820Base}"
f830Awk="${backupDirAwk}${metadataDir}/${f830Base}"
f840Awk="${backupDirAwk}${metadataDir}/${f840Base}"
f850Awk="${backupDirAwk}${metadataDir}/${f850Base}"
f860Awk="${backupDirAwk}${metadataDir}/${f860Base}"

findArgsLastRunAwk="${DQUOTE}${backupDirParsAwk}${DQUOTE}${metadataDir} -path ${TRIPLETDSEP}${metadataDir}/${f999Base}"
findArgsLastRunAwk="${findArgsLastRunAwk//${TRIPLETDSEP}/${DQUOTE}${backupDirParsPattAwk}${DQUOTE}}"

findArgsSourceAwk="${DQUOTE}${sourceDirParsAwk}${DQUOTE} -path ${TRIPLETDSEP}${metadataDir} -prune -o ${findGeneralOpsAwk} ${findSourceOpsAwk}"
findArgsSourceAwk="${findArgsSourceAwk//${TRIPLETDSEP}/${DQUOTE}${sourceDirParsPattAwk}${DQUOTE}}"

findArgsBackupAwk="${DQUOTE}${backupDirParsAwk}${DQUOTE} -path ${TRIPLETDSEP}${metadataDir} -prune -o ${findGeneralOpsAwk}"
findArgsBackupAwk="${findArgsBackupAwk//${TRIPLETDSEP}/${DQUOTE}${backupDirParsPattAwk}${DQUOTE}}"

awkLint=
if [ ${lTest} -eq 1 ]; then
  awkLint="-Lfatal"
fi

###########################################################
awk ${awkLint} '{ print }' << PARAMFILE > "${f000}"
${TRIPLET}${FSTAB}sourceDir${FSTAB}${sourceDir}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}sourceDirAwk${FSTAB}${sourceDirAwk}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}sourceDirParsAwk${FSTAB}${sourceDirParsAwk}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}sourceDirParsPattAwk${FSTAB}${sourceDirParsPattAwk}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}sourceDirEsc${FSTAB}${sourceDirEsc}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}sourceDirTerm${FSTAB}${sourceDirTerm}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}backupDir${FSTAB}${backupDir}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}backupDirAwk${FSTAB}${backupDirAwk}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}backupDirParsAwk${FSTAB}${backupDirParsAwk}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}backupDirParsPattAwk${FSTAB}${backupDirParsPattAwk}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}backupDirEsc${FSTAB}${backupDirEsc}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}backupDirTerm${FSTAB}${backupDirTerm}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}findSourceOps${FSTAB}${findSourceOps}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}findSourceOpsAwk${FSTAB}${findSourceOpsAwk}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}findSourceOpsEsc${FSTAB}${findSourceOpsEsc}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}findGeneralOps${FSTAB}${findGeneralOps}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}findGeneralOpsAwk${FSTAB}${findGeneralOpsAwk}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}findGeneralOpsEsc${FSTAB}${findGeneralOpsEsc}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}noExec${FSTAB}${noExec}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}revNew${FSTAB}${revNew}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}revUp${FSTAB}${revUp}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}hLinks${FSTAB}${hLinks}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}ok3600s${FSTAB}${ok3600s}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}noUnlink${FSTAB}${noUnlink}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}touch${FSTAB}${touch}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}pUser${FSTAB}${pUser}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}pGroup${FSTAB}${pGroup}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}pMode${FSTAB}${pMode}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}pRevUser${FSTAB}${pRevUser}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}pRevGroup${FSTAB}${pRevGroup}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}pRevMode${FSTAB}${pRevMode}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}noProgress${FSTAB}${noProgress}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}color${FSTAB}${color}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}wTest${FSTAB}${wTest}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}lTest${FSTAB}${lTest}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}metadataDir${FSTAB}${metadataDir}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}findArgsLastRunAwk${FSTAB}${findArgsLastRunAwk}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}findArgsSourceAwk${FSTAB}${findArgsSourceAwk}${FSTAB}${TRIPLET}
${TRIPLET}${FSTAB}findArgsBackupAwk${FSTAB}${findArgsBackupAwk}${FSTAB}${TRIPLET}
PARAMFILE

###########################################################
awk ${awkLint} '{ print }' << 'AWKAWKPREPROC' > "${f100}"
BEGIN {
  eex = "BEGIN {\n"                                                     \
        "  error_exit_fn = \"\"\n"                                      \
        "}\n"                                                           \
        "function error_exit( msg ) {\n"                                \
        "  if ( \"\" == error_exit_fn ) {\n"                            \
        "    if ( \"\" != FILENAME ) {\n"                               \
        "      error_exit_fn = FILENAME\n"                              \
        "      sub( /^.*\\//, \"\", error_exit_fn )\n"                  \
        "      msg = \"(\" error_exit_fn \" FNR:\" FNR \") \" msg\n"    \
        "    }\n"                                                       \
        "    print \"\\nZaloha AWK: \" msg > \"/dev/stderr\"\n"         \
        "    close( \"/dev/stderr\" )\n"                                \
        "    exit 1\n"                                                  \
        "  }\n"                                                         \
        "}"
}
{
  gsub( /ERROR_EXIT/, eex )
  gsub( /BIN_BASH/, "print \"#!/bin/bash\"" )
  gsub( /SECTION_LINE/, "print \"#\" FSTAB TRIPLET" )
  gsub( /TABREGEX/, "/\\t/" )
  gsub( /FSTAB/, "\"\\t\"" )
  gsub( /TAB/, "\"\\t\"" )
  gsub( /NLINE/, "\"\\n\"" )
  gsub( /BSLASH/, "\"\\\\\"" )
  gsub( /DQUOTE/, "\"\\\"\"" )
  gsub( /TRIPLETTREGEX/, "/\\/\\/\\/t/" )
  gsub( /TRIPLETNREGEX/, "/\\/\\/\\/n/" )
  gsub( /TRIPLETBREGEX/, "/\\/\\/\\/b/" )
  gsub( /TRIPLETT/, "\"///t\"" )
  gsub( /TRIPLETN/, "\"///n\"" )
  gsub( /TRIPLETC/, "\"///c\"" )
  gsub( /TRIPLET/, "\"///\"" )
  gsub( /QUOTEREGEX/, "/'/" )
  gsub( /QUOTEESC/, "\"'\\\"'\\\"'\"" )
  gsub( /NUMBERREGEX/, "/^[0-9]+$/" )
  gsub( /ZEROREGEX/, "/^0+$/" )
  gsub( /CNTRLREGEX/, "/[[:cntrl:]]/" )
  gsub( /TERMNORM/, "\"\\033[0m\"" )
  gsub( /TERMRED/, "\"\\033[91m\"" )
  gsub( /TERMBLUE/, "\"\\033[94m\"" )
  print
}
AWKAWKPREPROC

awk ${awkLint} -f "${f100}" << 'AWKXTRACE2TERM' > "${f102}"
{
  if ( 1 == color ) {
    gsub( TABREGEX, TRIPLETT )
    gsub( CNTRLREGEX, TERMBLUE TRIPLETC TERMNORM )
    gsub( TRIPLETTREGEX, TERMBLUE TRIPLETT TERMNORM )
  } else {
    gsub( TABREGEX, TRIPLETT )
    gsub( CNTRLREGEX, TRIPLETC )
  }
  print
}
AWKXTRACE2TERM

awk ${awkLint} -f "${f100}" << 'AWKACTIONS2TERM' > "${f104}"
BEGIN {
  FS = FSTAB
}
{
  pt = $13
  if ( 1 == color ) {
    gsub( CNTRLREGEX, TERMBLUE TRIPLETC TERMNORM, pt )
    gsub( TRIPLETNREGEX, TERMBLUE TRIPLETN TERMNORM, pt )
    gsub( TRIPLETTREGEX, TERMBLUE TRIPLETT TERMNORM, pt )
    if ( $2 ~ /^(REMOVE|UPDATE|unl\.UP|REV\.UP)/ ) {    # actions requiring more attention
      printf "%s%-10s%s%s\n", TERMRED, $2, TERMNORM, pt
    } else {
      printf "%-10s%s\n", $2, pt
    }
  } else {
    gsub( CNTRLREGEX, TRIPLETC, pt )
    printf "%-10s%s\n", $2, pt
  }
}
AWKACTIONS2TERM

###########################################################
awk ${awkLint} -f "${f100}" << 'AWKPARSER' > "${f106}"
ERROR_EXIT
BEGIN {
  gsub( TRIPLETBREGEX, BSLASH, findArgs )
  gsub( TRIPLETBREGEX, BSLASH, outFile )
  gsub( QUOTEREGEX, QUOTEESC, outFile )
  cmd = "find"                    # FIND command being constructed
  wrd = ""                        # word of FIND command being constructed
  iwd = 0                         # flag inside of word
  idq = 0                         # flag inside of double-quote
  bsl = 0                         # flag backslash remembered
  findArgs = findArgs " "
  for ( i = 1; i <= length( findArgs ); i++ ) {
    c = substr( findArgs, i, 1 )
    if ( 1 == bsl ) {
      bsl = 0
      if ( DQUOTE == c ) {
        wrd = wrd c
        continue
      } else {
        wrd = wrd BSLASH
      }
    }
    if ( BSLASH == c ) {
      iwd = 1
      bsl = 1
    } else if ( DQUOTE == c ) {
      if ( 1 == idq ) {
        idq = 0
      } else {
        idq = 1
      }
    } else if ( " " == c ) {
      if ( 1 == idq ) {
        iwd = 1
        wrd = wrd c
      } else {
        iwd = 0
      }
    } else {
      iwd = 1
      wrd = wrd c
    }
    if (( 0 == iwd ) && ( "" != wrd )) {
      gsub( QUOTEREGEX, QUOTEESC, wrd )
      cmd = cmd " '" wrd "'"
      wrd = ""
    }
  }
  if ( 1 == idq ) {
    error_exit( "<findArgs> contains unpaired double quote" )
  }
  cmd = cmd " -printf '"
  cmd = cmd TRIPLET                    # column  1: leading field
  cmd = cmd "\\t" srcBackup            # column  2: S = <sourceDir>, B = <backupDir>, L = last run record
  cmd = cmd "\\t%y"                    # column  3: file's type (d = directory, f = file, l = symbolic link, [h = hardlink], p/s/c/b/D = other)
  cmd = cmd "\\t%s"                    # column  4: file's size in bytes
  cmd = cmd "\\t%Ts"                   # column  5: file's last modification time, seconds since 01/01/1970
  cmd = cmd "\\t%F"                    # column  6: type of the filesystem the file is on
  cmd = cmd "\\t%D"                    # column  7: device number the file is on
  cmd = cmd "\\t%i"                    # column  8: file's inode number
  cmd = cmd "\\t%n"                    # column  9: number of hardlinks to file
  cmd = cmd "\\t%u"                    # column 10: file's user name
  cmd = cmd "\\t%g"                    # column 11: file's group name
  cmd = cmd "\\t%m"                    # column 12: file's permission bits (in octal)
  cmd = cmd "\\t%P"                    # column 13: file's path with <sourceDir> or <backupDir> stripped
  cmd = cmd "\\t" TRIPLET              # column 14: terminator field
  cmd = cmd "\\t%l"                    # column 15: object of symbolic link
  cmd = cmd "\\t" TRIPLET              # column 16: terminator field
  cmd = cmd "\\n' > '" outFile "'"
  BIN_BASH
  print "BASH_XTRACEFD=1"
  print "PS4='    '"
  print "set -e"
  if ( 0 == noProgress ) {
    print "set -x"
  }
  print cmd
}
AWKPARSER

if [ ${noProgress} -eq 0 ]; then
  echo
  echo "ANALYZING ${sourceDirTerm} AND ${backupDirTerm}"
  echo "==========================================="
fi

start_progress "Parsing"

awk ${awkLint}                              \
    -f "${f106}"                            \
    -v srcBackup="L"                        \
    -v findArgs="${findArgsLastRunAwk}"     \
    -v outFile="${f300Awk}"                 \
    -v noProgress=${noProgress}             > "${f200}"

awk ${awkLint}                              \
    -f "${f106}"                            \
    -v srcBackup="S"                        \
    -v findArgs="${findArgsSourceAwk}"      \
    -v outFile="${f310Awk}"                 \
    -v noProgress=${noProgress}             > "${f210}"

awk ${awkLint}                              \
    -f "${f106}"                            \
    -v srcBackup="B"                        \
    -v findArgs="${findArgsBackupAwk}"      \
    -v outFile="${f320Awk}"                 \
    -v noProgress=${noProgress}             > "${f220}"

stop_progress

bash "${f200}" | awk ${awkLint} -f "${f102}" -v color=${color}

bash "${f210}" | awk ${awkLint} -f "${f102}" -v color=${color}

bash "${f220}" | awk ${awkLint} -f "${f102}" -v color=${color}

###########################################################
awk ${awkLint} -f "${f100}" << 'AWKCLEANER' > "${f110}"
ERROR_EXIT
BEGIN {
  FS = FSTAB   # FSTAB or TAB, because fields are separated both by tabs produced by FIND as well as by tabs contained in filenames
  fin = 1      # field index in output record
  fpr = 0      # flag field in progress
}
{
  if (( 1 == fin ) && ( 16 == NF ) && ( TRIPLET == $1 ) && ( TRIPLET == $16 )) {
    print                                               # the unproblematic case performance-optimized
  } else {                                              # full processing otherwise
    if ( 0 == NF ) {
      if ( 1 == fpr ) {
        rec = rec TRIPLETN
      } else {
        error_exit( "Unexpected blank line in raw output of FIND" )
      }
    } else {
      for ( i = 1; i <= NF; i++ ) {
        if (( 1 == i ) && ( TRIPLET == $i ) && (( 1 != fin ) || ( 0 != fpr ))) {
          error_exit( "AWK cleaner in unexpected state at begin of new record" )
        }
        if ( 1 == fpr ) {
          if ( TRIPLET == $i ) {
            rec = rec FSTAB $i
            fin = fin + 2
            fpr = 0
          } else if ( 1 == i ) {
            rec = rec TRIPLETN $i
          } else {
            rec = rec TRIPLETT $i
          }
        } else {
          if ( 1 == fin ) {
            rec = $i                                    # output record
            fin = 2
          } else if (( 13 == fin ) || ( 15 == fin )) {  # fields delimited by subsequent terminator fields
            rec = rec FSTAB $i
            fpr = 1
          } else {
            rec = rec FSTAB $i
            fin = fin + 1
          }
        }
        if (( NF == i ) && ( TRIPLET == $i ) && (( 17 != fin ) || ( 0 != fpr ))) {
          error_exit( "AWK cleaner in unexpected state at end of record" )
        }
      }
    }
    if ( 17 == fin ) {                                  # 17 = field index of last field + 1
      print rec
      fin = 1
    }
  }
}
END {
  if (( 1 != fin ) || ( 0 != fpr )) {
    error_exit( "AWK cleaner in unexpected state at end of file" )
  }
}
AWKCLEANER

start_progress "Cleaning"

awk ${awkLint} -f "${f110}" "${f310}" > "${f330}"

awk ${awkLint} -f "${f110}" "${f320}" > "${f340}"

stop_progress

###########################################################
awk ${awkLint} -f "${f100}" << 'AWKCHECKER' > "${f130}"
ERROR_EXIT
BEGIN {
  FS = FSTAB
}
{
  if ( 16 != NF ) {
    error_exit( "Unexpected, cleaned CSV file does not contain 16 columns" )
  }
  if ( $1 != TRIPLET ) {
    error_exit( "Unexpected, column 1 of cleaned file is not leading field" )
  }
  if ( $2 !~ /[LSB]/ ) {
    error_exit( "Unexpected, column 2 of cleaned file contains invalid value" )
  }
  if ( $3 !~ /[dflpscbD]/ ) {
    error_exit( "Unexpected, column 3 of cleaned file contains invalid value" )
  }
  if ( $4 !~ NUMBERREGEX ) {
    error_exit( "Unexpected, column 4 of cleaned file is not numeric" )
  }
  if ( $5 !~ NUMBERREGEX ) {
    error_exit( "Unexpected, column 5 of cleaned file is not numeric" )
  }
  if (( $5 ~ ZEROREGEX ) && ( "f" == $3 )) {
    error_exit( "Unexpected, column 5 of cleaned file is zero for a file" )
  }
  if ( $7 !~ NUMBERREGEX ) {
    error_exit( "Unexpected, column 7 of cleaned file is not numeric" )
  }
  if ( $8 !~ NUMBERREGEX ) {
    error_exit( "Unexpected, column 8 of cleaned file is not numeric" )
  }
  if ( $9 !~ NUMBERREGEX ) {
    error_exit( "Unexpected, column 9 of cleaned file is not numeric" )
  }
  if ( $9 ~ ZEROREGEX ) {
    error_exit( "Unexpected, column 9 of cleaned file is zero" )
  }
  if ( $10 == "" ) {
    error_exit( "Unexpected, column 10 of cleaned file is empty" )
  }
  if ( $11 == "" ) {
    error_exit( "Unexpected, column 11 of cleaned file is empty" )
  }
  if ( $12 !~ NUMBERREGEX ) {
    error_exit( "Unexpected, column 12 of cleaned file is not numeric" )
  }
  if (( $13 == "" ) && ( 1 != FNR )) {
    error_exit( "Unexpected, column 13 of cleaned file is empty" )
  }
  if ( $14 != TRIPLET ) {
    error_exit( "Unexpected, column 14 of cleaned file is not terminator field" )
  }
  if (( $15 == "" ) && ( "l" == $3 )) {
    error_exit( "Unexpected, column 15 of cleaned file is empty for symbolic link" )
  }
  if (( $15 != "" ) && ( "l" != $3 )) {
    error_exit( "Unexpected, column 15 of cleaned file is not empty" )
  }
  if ( $16 != TRIPLET ) {
    error_exit( "Unexpected, column 16 of cleaned file is not terminator field" )
  }
}
AWKCHECKER

start_progress "Checking"

awk ${awkLint} -f "${f130}" "${f300}" "${f330}" "${f340}"

stop_progress

###########################################################
awk ${awkLint} -f "${f100}" << 'AWKHLINKS' > "${f150}"
ERROR_EXIT
BEGIN {
  FS = FSTAB
  OFS = FSTAB
  tp = ""
}
{
  # hardlink detection only for files
  # device and inode numbers prepended by "M" to enforce string comparisons (numbers would overflow)
  if ( ( "f" == tp ) && ( "f" == $3 )                     \
    && ( $7 !~ ZEROREGEX ) && (( "M" dv ) == ( "M" $7 ))  \
    && ( $8 !~ ZEROREGEX ) && (( "M" id ) == ( "M" $8 ))  \
  ) {
    hcn = hcn + 1
    if ( $9 < hcn ) {
      error_exit( "Unexpected, detected hardlink count is higher than number of hardlinks to file" )
    }
    if (( "M" sz ) != ( "M" $4 )) {
      error_exit( "Unexpected falsely detected hardlink (size differs)" )
    }
    if (( "M" tm ) != ( "M" $5 )) {
      error_exit( "Unexpected falsely detected hardlink (modification time differs)" )
    }
    if ( nh != $9 ) {
      error_exit( "Unexpected falsely detected hardlink (number of hardlinks differs)" )
    }
    if ( us != $10 ) {
      error_exit( "Unexpected falsely detected hardlink (user name differs)" )
    }
    if ( gr != $11 ) {
      error_exit( "Unexpected falsely detected hardlink (group name differs)" )
    }
    if ( md != $12 ) {
      error_exit( "Unexpected falsely detected hardlink (mode differs)" )
    }
    $3 = "h"    # hardlink
    $15 = pt    # object of hardlink
  } else {
    hcn = 1     # detected hardlink count
    tp = $3     # previous record's column  3: file's type (d = directory, f = file, l = symbolic link, [h = hardlink], p/s/c/b/D = other)
    sz = $4     # previous record's column  4: file's size in bytes
    tm = $5     # previous record's column  5: file's last modification time, seconds since 01/01/1970
    dv = $7     # previous record's column  7: device number the file is on
    id = $8     # previous record's column  8: file's inode number
    nh = $9     # previous record's column  9: number of hardlinks to file
    us = $10    # previous record's column 10: file's user name
    gr = $11    # previous record's column 11: file's group name
    md = $12    # previous record's column 12: file's permission bits (in octal)
    pt = $13    # previous record's column 13: file's path with <sourceDir> or <backupDir> stripped
  }
  print
}
AWKHLINKS

if [ ${hLinks} -eq 1 ]; then

  start_progress "Sorting (1)"

  sort -t "${FSTAB}" -k7,7 -k8,8 -k13,13 "${f330}" > "${f350}"

  stop_progress

  start_progress "Hardlinks detecting"

  awk ${awkLint} -f "${f150}" "${f350}" > "${f360}"

  stop_progress

  fAfterHLinks="${f360}"
else
  fAfterHLinks="${f330}"
fi

###########################################################
awk ${awkLint} -f "${f100}" << 'AWKDIFF' > "${f170}"
ERROR_EXIT
BEGIN {
  FS = FSTAB
  OFS = FSTAB
  lru = 0     # time of the last run of Zaloha
  xrn = ""    # occupied namespace for REV.NEW
  xkp = ""    # occupied namespace for other objects to KEEP on <backupDir>
  prr = 0     # flag previous record remembered
  sb = ""
}
function print_previous( acode ) {
  print TRIPLET, acode, tp, sz, tm, ft, dv, id, nh, us, gr, md, pt, TRIPLET, ol, TRIPLET
}
function print_current( acode ) {
  print TRIPLET, acode, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, TRIPLET, $15, TRIPLET
}
function remove_file() {
  if (( 0 != lru ) && ( lru < tm )) {
    print_previous( "REMOVE.!" )
  } else {
    print_previous( "REMOVE" )
  }
}
function update_file() {
  if (( 0 == noUnlink ) && ( 1 != nh )) {
    bac = "unl.UP"
  } else {
    bac = "UPDATE"
  }
  if (( 0 != lru ) && ( lru < tm )) {
    print_current( bac ".!" )
  } else if ( 1 == ok3600s ) {
    if ( tdi <= 3601 ) {
      print_current( bac ".?" )
    } else {
      print_current( bac )
    }
  } else {
    if ( tdi <= 1 ) {
      print_current( bac ".?" )
    } else {
      print_current( bac )
    }
  }
}
function rev_up_file() {
  if ( 1 == ok3600s ) {
    if (( 0 != lru ) && ( lru < 3600 + $5 )) {
      print_previous( "REV.UP.!" )
    } else {
      print_previous( "REV.UP" )
    }
  } else {
    if (( 0 != lru ) && ( lru < $5 )) {
      print_previous( "REV.UP.!" )
    } else {
      print_previous( "REV.UP" )
    }
  }
}
function attributes_or_ok() {
  atr = ""
  if (( 1 == pUser ) && ( $10 != us )) {
    atr = atr "u"
  }
  if (( 1 == pGroup ) && ( $11 != gr )) {
    atr = atr "g"
  }
  if (( 1 == pMode ) && ( $12 != md )) {
    atr = atr "m"
  }
  if ( "" != atr ) {
    print_current( "ATTR:" atr )
  } else {
    print_current( "OK" )
  }
}
function process_previous_record() {
  if ( "S" == sb ) {
    if ( "d" == tp ) {                         # directory only on <sourceDir>
      print_previous( "MKDIR" )
    } else if ( "f" == tp ) {                  # file only on <sourceDir>
      print_previous( "NEW" )
    } else if ( "l" == tp ) {                  # symbolic link only on <sourceDir> (record needed for the restore scripts)
      print_previous( "OK" )
    } else if ( "h" == tp ) {                  # hardlink only on <sourceDir> (record needed for the restore scripts)
      print_previous( "OK" )
    }
  } else {
    if ( "d" == tp ) {                         # directory only on <backupDir>
      print_previous( "RMDIR" )
    } else if ( "f" == tp ) {                  # file only on <backupDir>
      if (( 1 == revNew ) && ( 0 != lru ) && ( lru < tm )) {
        if ( "" == xrn ) {
          print_previous( "REV.NEW" )
        } else if ( 1 == index( pt, xrn )) {
          print_previous( "REMOVE.!" )
        } else {
          print_previous( "REV.NEW" )
          xrn = ""
        }
      } else {
        remove_file()
      }
    } else {                                   # other object only on <backupDir>
      if ( "" == xkp ) {
        print_previous( "KEEP" )
      } else if ( 1 == index( pt, xkp )) {
        print_previous( "REMOVE." tp )
      } else {
        print_previous( "KEEP" )
        xkp = ""
      }
    }
  }
}
{
  if (( sb == $2 ) && ( pt == $13 )) {
    error_exit( "Unexpected, duplicate record" )
  }
  if ( "L" == $2 ) {
    if ( 1 != NR ) {
      error_exit( "Unexpected, misplaced L record" )
    }
    if ( "f" != $3 ) {
      error_exit( "Unexpected, L record is not a file" )
    }
    lru = $5
  } else {
    if ( 1 == prr ) {
      if ( pt == $13 ) {                       ### same name on <sourceDir> and <backupDir>
        if ( "d" == $3 ) {                     ## directory on <sourceDir>
          if ( "d" == tp ) {                   # directory on <sourceDir>, directory on <backupDir>
            attributes_or_ok()
          } else if ( "f" == tp ) {            # directory on <sourceDir>, file on <backupDir>
            remove_file()
            print_current( "MKDIR" )
          } else {                             # directory on <sourceDir>, other object on <backupDir>
            print_previous( "REMOVE." tp )
            print_current( "MKDIR" )
          }
        } else if ( "f" == $3 ) {              ## file on <sourceDir>
          if ( "d" == tp ) {                   # file on <sourceDir>, directory on <backupDir>
            xrn = pt
            xkp = pt
            print_previous( "RMDIR" )
            print_current( "NEW" )
          } else if ( "f" == tp ) {            # file on <sourceDir>, file on <backupDir>
            oka = 0
            if ( "M" $4 == "M" sz ) {
              if ( "M" $5 == "M" tm ) {
                oka = 1
              } else {
                tdi = $5 - tm
                tda = tdi
                if ( tda < 0 ) {
                  tda = - tda
                }
                if ( 1 == tda ) {
                  oka = 1
                } else if (( 1 == ok3600s ) && ( 3599 <= tda ) && ( tda <= 3601 )) {
                  oka = 1
                } else if ( 0 == tda ) {
                  error_exit( "Unexpected, numeric overflow occurred" )
                }
              }
            }
            if ( 1 == oka ) {
              attributes_or_ok()
            } else {
              tdi = $5 - tm
              if ( 1 == revUp ) {
                if ( 1 == ok3600s ) {
                  if ( tdi < -3601 ) {
                    rev_up_file()
                  } else {
                    update_file()
                  }
                } else {
                  if ( tdi < -1 ) {
                    rev_up_file()
                  } else {
                    update_file()
                  }
                }
              } else {
                update_file()
              }
            }
          } else {                             # file on <sourceDir>, other object on <backupDir>
            print_previous( "REMOVE." tp )
            print_current( "NEW" )
          }
        } else {                               ## other object on <sourceDir>
          if ( "d" == tp ) {                   # other object on <sourceDir>, directory on <backupDir>
            xrn = pt
            print_previous( "RMDIR" )
          } else if ( "f" == tp ) {            # other object on <sourceDir>, file on <backupDir>
            remove_file()
          } else {                             # other object on <sourceDir>, other object on <backupDir>
            print_previous( "KEEP" )
          }
          if ( "l" == $3 ) {                   # symbolic link on <sourceDir> (record needed for the restore scripts)
            print_current( "OK" )
          } else if ( "h" == $3 ) {            # hardlink on <sourceDir> (record needed for the restore scripts)
            print_current( "OK" )
          }
        }
        prr = 0
      } else {                                 ### different name on <sourceDir> and <backupDir>
        process_previous_record()
        prr = 1
      }
    } else {
      prr = 1
    }
  }
  sb = $2       # previous record's column  2: S = <sourceDir>, B = <backupDir>, L = last run record
  tp = $3       # previous record's column  3: file's type (d = directory, f = file, l = symbolic link, [h = hardlink], p/s/c/b/D = other)
  sz = $4       # previous record's column  4: file's size in bytes
  tm = $5       # previous record's column  5: file's last modification time, seconds since 01/01/1970
  ft = $6       # previous record's column  6: type of the filesystem the file is on
  dv = $7       # previous record's column  7: device number the file is on
  id = $8       # previous record's column  8: file's inode number
  nh = $9       # previous record's column  9: number of hardlinks to file
  us = $10      # previous record's column 10: file's user name
  gr = $11      # previous record's column 11: file's group name
  md = $12      # previous record's column 12: file's permission bits (in octal)
  pt = $13      # previous record's column 13: file's path with <sourceDir> or <backupDir> stripped
  ol = $15      # previous record's column 15: object of symbolic link
}
END {
  if ( 1 == prr ) {
    process_previous_record()
  }
  if ( 0 == lru ) {
    print "\nZaloha AWK: Warning: No last run of Zaloha found (this is OK if this is the first run)" > "/dev/stderr"
    close( "/dev/stderr" )
  }
}
AWKDIFF

start_progress "Sorting (2)"

sort -t "${FSTAB}" -k13,13 -k2,2 "${fAfterHLinks}" "${f340}" > "${f370}"

stop_progress

start_progress "Differences processing"

awk ${awkLint}                              \
    -f "${f170}"                            \
    -v revNew=${revNew}                     \
    -v revUp=${revUp}                       \
    -v ok3600s=${ok3600s}                   \
    -v noUnlink=${noUnlink}                 \
    -v pUser=${pUser}                       \
    -v pGroup=${pGroup}                     \
    -v pMode=${pMode}                       \
    "${f300}" "${f370}"                     > "${f380}"

stop_progress

###########################################################
awk ${awkLint} -f "${f100}" << 'AWKPOSTPROC' > "${f190}"
BEGIN {
  FS = FSTAB
  OFS = FSTAB
  gsub( TRIPLETBREGEX, BSLASH, f500 )
  gsub( TRIPLETBREGEX, BSLASH, f510 )
  printf "" > f500
  printf "" > f510
  lrn = ""       # last file on <backupDir> to REV.NEW
  lkp = ""       # last other object to KEEP on <backupDir>
}
function print_split() {
  if ( $2 ~ /^(RMDIR|REMOVE)/ ) {
    print > f510
  } else {
    print > f500
  }
}
{
  if ( $2 ~ /^REV\.NEW/ ) {
    lrn = $13             # remember path, output REV.NEW
    print_split()
  } else if ( $2 ~ /^KEEP/ ) {
    lkp = $13             # just remember path, do not output KEEP
  } else if ( $2 ~ /^RMDIR/ ) {
    if ( 1 == index( lrn, $13 )) {
      $2 = "REV.MKDI"     # convert RMDIR to REV.MKDI on parent directory of a file to REV.NEW
      print_split()
    } else if ( 1 == index( lkp, $13 )) {
      # no action         # cancel RMDIR on parent directory of other object to KEEP on <backupDir>
    } else {
      print_split()
    }
  } else {
    print_split()
  }
}
END {
  close( f510 )
  close( f500 )
}
AWKPOSTPROC

start_progress "Sorting (3)"

sort -t "${FSTAB}" -k13r,13 "${f380}" > "${f390}"

stop_progress

start_progress "Post-processing and splitting off Exec1"

awk ${awkLint}                              \
    -f "${f190}"                            \
    -v f500="${f500Awk}"                    \
    -v f510="${f510Awk}"                    \
    "${f390}"

stop_progress

###########################################################
awk ${awkLint} -f "${f100}" << 'AWKSELECT23' > "${f405}"
BEGIN {
  FS = FSTAB
  gsub( TRIPLETBREGEX, BSLASH, f520 )
  gsub( TRIPLETBREGEX, BSLASH, f530 )
  printf "" > f520
  printf "" > f530
}
{
  if ( $2 ~ /^(MKDIR|NEW|UPDATE|unl\.UP|ATTR)/ ) {
    print > f520
  } else if ( $2 ~ /^(REV\.MKDI|REV\.NEW|REV\.UP)/ ) {
    print > f530
  }
}
END {
  close( f530 )
  close( f520 )
}
AWKSELECT23

start_progress "Sorting (4)"

sort -t "${FSTAB}" -k13,13 "${f500}" > "${f505}"

stop_progress

start_progress "Selecting Exec2 and Exec3"

awk ${awkLint}                              \
    -f "${f405}"                            \
    -v f520="${f520Awk}"                    \
    -v f530="${f530Awk}"                    \
    "${f505}"

stop_progress

###########################################################
awk ${awkLint} -f "${f100}" << 'AWKEXEC1' > "${f410}"
ERROR_EXIT
BEGIN {
  FS = FSTAB
  gsub( TRIPLETBREGEX, BSLASH, backupDir )
  gsub( QUOTEREGEX, QUOTEESC, backupDir )
  BIN_BASH
  print "backupDir='" backupDir "'"
  print "RMDIR='rmdir'"
  print "RM='rm -f'"
  if ( 0 == noExec ) {
    print "BASH_XTRACEFD=1"
    print "PS4='    '"
    print "set -e"
    print "set -x"
  }
  SECTION_LINE
}
{
  pt = $13
  gsub( QUOTEREGEX, QUOTEESC, pt )
  gsub( TRIPLETNREGEX, NLINE, pt )
  gsub( TRIPLETTREGEX, TAB, pt )
  b = "\"${backupDir}\"'" pt "'"
  if ( $2 ~ /^RMDIR/ ) {
    print "${RMDIR} " b
  } else if ( $2 ~ /^REMOVE/ ) {
    print "${RM} " b
  } else {
    error_exit( "Unexpected action code" )
  }
}
END {
  SECTION_LINE
}
AWKEXEC1

start_progress "Preparing shellscript for Exec1"

awk ${awkLint}                              \
    -f "${f410}"                            \
    -v backupDir="${backupDirAwk}"          \
    -v noExec=${noExec}                     \
    "${f510}"                               > "${f610}"

stop_progress

###########################################################
awk ${awkLint} -f "${f100}" << 'AWKEXEC2' > "${f420}"
ERROR_EXIT
BEGIN {
  FS = FSTAB
  gsub( TRIPLETBREGEX, BSLASH, sourceDir )
  gsub( TRIPLETBREGEX, BSLASH, backupDir )
  gsub( QUOTEREGEX, QUOTEESC, sourceDir )
  gsub( QUOTEREGEX, QUOTEESC, backupDir )
  BIN_BASH
  print "sourceDir='" sourceDir "'"
  print "backupDir='" backupDir "'"
  print "MKDIR='mkdir'"
  if ( 1 == touch ) {
    print "CP='cp'"
    print "TOUCH='touch -r'"
  } else {
    print "CP='cp --preserve=timestamps'"
  }
  if ( 0 == noUnlink ) {
    print "RM='rm -f'"
  }
  if ( 1 == pUser ) {
    print "CHOWN='chown'"
  }
  if ( 1 == pGroup ) {
    print "CHGRP='chgrp'"
  }
  if ( 1 == pMode ) {
    print "CHMOD='chmod'"
  }
  if ( 0 == noExec ) {
    print "BASH_XTRACEFD=1"
    print "PS4='    '"
    print "set -e"
    print "set -x"
  }
  SECTION_LINE
}
function copy_file() {
  print "${CP} " s " " b
  if ( 1 == touch ) {
    print "${TOUCH} " s " " b
  }
}
function apply_attr() {
  if ( 1 == pUser ) {
    print "${CHOWN} " u " " b
  }
  if ( 1 == pGroup ) {
    print "${CHGRP} " g " " b
  }
  if ( 1 == pMode ) {
    print "${CHMOD} " m " " b
  }
}
{
  us = $10
  gr = $11
  md = $12
  pt = $13
  gsub( QUOTEREGEX, QUOTEESC, us )
  gsub( QUOTEREGEX, QUOTEESC, gr )
  gsub( QUOTEREGEX, QUOTEESC, pt )
  gsub( TRIPLETNREGEX, NLINE, pt )
  gsub( TRIPLETTREGEX, TAB, pt )
  u = "'" us "'"
  g = "'" gr "'"
  m = "'" md "'"
  s = "\"${sourceDir}\"'" pt "'"
  b = "\"${backupDir}\"'" pt "'"
  if ( $2 ~ /^MKDIR/ ) {
    print "${MKDIR} " b
    apply_attr()
  } else if ( $2 ~ /^NEW/ ) {
    copy_file()
    apply_attr()
  } else if ( $2 ~ /^UPDATE/ ) {
    copy_file()
    apply_attr()
  } else if ( $2 ~ /^unl\.UP/ ) {
    print "${RM} " b
    copy_file()
    apply_attr()
  } else if ( $2 ~ /^ATTR/ ) {
    if ( $2 ~ /u/ ) {
      print "${CHOWN} " u " " b
    }
    if ( $2 ~ /g/ ) {
      print "${CHGRP} " g " " b
    }
    if ( $2 ~ /m/ ) {
      print "${CHMOD} " m " " b
    }
  } else {
    error_exit( "Unexpected action code" )
  }
}
END {
  SECTION_LINE
}
AWKEXEC2

start_progress "Preparing shellscript for Exec2"

awk ${awkLint}                              \
    -f "${f420}"                            \
    -v sourceDir="${sourceDirAwk}"          \
    -v backupDir="${backupDirAwk}"          \
    -v noExec=${noExec}                     \
    -v noUnlink=${noUnlink}                 \
    -v touch=${touch}                       \
    -v pUser=${pUser}                       \
    -v pGroup=${pGroup}                     \
    -v pMode=${pMode}                       \
    "${f520}"                               > "${f620}"

stop_progress

###########################################################
awk ${awkLint} -f "${f100}" << 'AWKEXEC3' > "${f430}"
ERROR_EXIT
BEGIN {
  FS = FSTAB
  gsub( TRIPLETBREGEX, BSLASH, sourceDir )
  gsub( TRIPLETBREGEX, BSLASH, backupDir )
  gsub( QUOTEREGEX, QUOTEESC, sourceDir )
  gsub( QUOTEREGEX, QUOTEESC, backupDir )
  BIN_BASH
  print "sourceDir='" sourceDir "'"
  print "backupDir='" backupDir "'"
  print "MKDIR='mkdir'"
  if ( 1 == touch ) {
    print "CP='cp'"
    print "TOUCH='touch -r'"
  } else {
    print "CP='cp --preserve=timestamps'"
  }
  if ( 1 == pRevUser ) {
    print "CHOWN='chown'"
  }
  if ( 1 == pRevGroup ) {
    print "CHGRP='chgrp'"
  }
  if ( 1 == pRevMode ) {
    print "CHMOD='chmod'"
  }
  print "function rev_exists_err {"
  print "  echo \"Zaloha: Object exists on <sourceDir> (excluded by <findSourceOps> ?): $1\" >&2"
  if ( 0 == noExec ) {
    print "  exit 1"
  }
  print "}"
  if ( 0 == noExec ) {
    print "BASH_XTRACEFD=1"
    print "PS4='    '"
    print "set -e"
    print "set -x"
  }
  SECTION_LINE
}
function rev_check_nonex() {
  print "[ ! -e " s " ] || rev_exists_err '" ptt "'"
}
function rev_copy_file() {
  print "${CP} " b " " s
  if ( 1 == touch ) {
    print "${TOUCH} " b " " s
  }
}
function rev_apply_attr() {
  if ( 1 == pRevUser ) {
    print "${CHOWN} " u " " s
  }
  if ( 1 == pRevGroup ) {
    print "${CHGRP} " g " " s
  }
  if ( 1 == pRevMode ) {
    print "${CHMOD} " m " " s
  }
}
{
  us = $10
  gr = $11
  md = $12
  pt = $13
  gsub( QUOTEREGEX, QUOTEESC, us )
  gsub( QUOTEREGEX, QUOTEESC, gr )
  gsub( QUOTEREGEX, QUOTEESC, pt )
  ptt = pt
  gsub( TRIPLETNREGEX, NLINE, pt )
  gsub( TRIPLETTREGEX, TAB, pt )
  gsub( CNTRLREGEX, TRIPLETC, ptt )
  u = "'" us "'"
  g = "'" gr "'"
  m = "'" md "'"
  s = "\"${sourceDir}\"'" pt "'"
  b = "\"${backupDir}\"'" pt "'"
  if ( $2 ~ /^REV\.MKDI/ ) {
    rev_check_nonex()
    print "${MKDIR} " s
    rev_apply_attr()
  } else if ( $2 ~ /^REV\.NEW/ ) {
    rev_check_nonex()
    rev_copy_file()
    rev_apply_attr()
  } else if ( $2 ~ /^REV\.UP/ ) {
    rev_copy_file()
    rev_apply_attr()
  } else {
    error_exit( "Unexpected action code" )
  }
}
END {
  SECTION_LINE
}
AWKEXEC3

start_progress "Preparing shellscript for Exec3"

awk ${awkLint}                              \
    -f "${f430}"                            \
    -v sourceDir="${sourceDirAwk}"          \
    -v backupDir="${backupDirAwk}"          \
    -v noExec=${noExec}                     \
    -v touch=${touch}                       \
    -v pRevUser=${pRevUser}                 \
    -v pRevGroup=${pRevGroup}               \
    -v pRevMode=${pRevMode}                 \
    "${f530}"                               > "${f630}"

stop_progress

###########################################################
awk ${awkLint} -f "${f100}" << 'AWKTOUCH' > "${f490}"
BEGIN {
  gsub( TRIPLETBREGEX, BSLASH, backupDir )
  gsub( QUOTEREGEX, QUOTEESC, backupDir )
  BIN_BASH
  print "backupDir='" backupDir "'"
  print "TOUCH='touch -r'"
  SECTION_LINE
  print "${TOUCH} \"${backupDir}\"" metadataDir "/" f000Base \
                " \"${backupDir}\"" metadataDir "/" f999Base
  SECTION_LINE
}
AWKTOUCH

start_progress "Preparing shellscript to touch file 999"

awk ${awkLint}                              \
    -f "${f490}"                            \
    -v backupDir="${backupDirAwk}"          \
    -v metadataDir="${metadataDir}"         \
    -v f000Base="${f000Base}"               \
    -v f999Base="${f999Base}"               > "${f690}"

stop_progress

###########################################################
awk ${awkLint} -f "${f100}" << 'AWKRESTORE' > "${f700}"
BEGIN {
  FS = FSTAB
  pin = 1         # parallel index for 810 script
  gsub( TRIPLETBREGEX, BSLASH, backupDir )
  gsub( TRIPLETBREGEX, BSLASH, restoreDir )
  gsub( TRIPLETBREGEX, BSLASH, f800 )
  gsub( TRIPLETBREGEX, BSLASH, f810 )
  gsub( TRIPLETBREGEX, BSLASH, f820 )
  gsub( TRIPLETBREGEX, BSLASH, f830 )
  gsub( TRIPLETBREGEX, BSLASH, f840 )
  gsub( TRIPLETBREGEX, BSLASH, f850 )
  gsub( TRIPLETBREGEX, BSLASH, f860 )
  gsub( QUOTEREGEX, QUOTEESC, backupDir )
  gsub( QUOTEREGEX, QUOTEESC, restoreDir )
  BIN_BASH > f800
  BIN_BASH > f810
  BIN_BASH > f820
  BIN_BASH > f830
  BIN_BASH > f840
  BIN_BASH > f850
  BIN_BASH > f860
  print "restoreDir='" restoreDir "'" > f800
  print "backupDir='" backupDir "'" > f810
  print "restoreDir='" restoreDir "'" > f810
  print "restoreDir='" restoreDir "'" > f820
  print "restoreDir='" restoreDir "'" > f830
  print "restoreDir='" restoreDir "'" > f840
  print "restoreDir='" restoreDir "'" > f850
  print "restoreDir='" restoreDir "'" > f860
  print "MKDIR='mkdir'" > f800
  print "CP1='cp'" > f810
  print "CP2='cp'" > f810
  print "CP3='cp'" > f810
  print "CP4='cp'" > f810
  print "CP5='cp'" > f810
  print "CP6='cp'" > f810
  print "CP7='cp'" > f810
  print "CP8='cp'" > f810
  print "TOUCH1='touch -r'" > f810
  print "TOUCH2='touch -r'" > f810
  print "TOUCH3='touch -r'" > f810
  print "TOUCH4='touch -r'" > f810
  print "TOUCH5='touch -r'" > f810
  print "TOUCH6='touch -r'" > f810
  print "TOUCH7='touch -r'" > f810
  print "TOUCH8='touch -r'" > f810
  print "LNSYMB='ln -s'" > f820
  print "LNHARD='ln'" > f830
  print "CHOWN='chown -h'" > f840
  print "CHGRP='chgrp -h'" > f850
  print "CHMOD='chmod'" > f860
  SECTION_LINE > f800
  SECTION_LINE > f810
  SECTION_LINE > f820
  SECTION_LINE > f830
  SECTION_LINE > f840
  SECTION_LINE > f850
  SECTION_LINE > f860
}
{
  us = $10
  gr = $11
  md = $12
  pt = $13
  ol = $15
  gsub( QUOTEREGEX, QUOTEESC, us )
  gsub( QUOTEREGEX, QUOTEESC, gr )
  gsub( QUOTEREGEX, QUOTEESC, pt )
  gsub( QUOTEREGEX, QUOTEESC, ol )
  gsub( TRIPLETNREGEX, NLINE, pt )
  gsub( TRIPLETNREGEX, NLINE, ol )
  gsub( TRIPLETTREGEX, TAB, pt )
  gsub( TRIPLETTREGEX, TAB, ol )
  u = "'" us "'"
  g = "'" gr "'"
  m = "'" md "'"
  b = "\"${backupDir}\"'" pt "'"
  r = "\"${restoreDir}\"'" pt "'"
  o = "\"${restoreDir}\"'" ol "'"
  if ( "d" == $3 ) {
    print "${MKDIR} " r > f800
    print "${CHOWN} " u " " r > f840
    print "${CHGRP} " g " " r > f850
    print "${CHMOD} " m " " r > f860
  } else if ( "f" == $3 ) {
    print "${CP" pin "} " b " " r > f810
    print "${TOUCH" pin "} " b " " r > f810
    print "${CHOWN} " u " " r > f840
    print "${CHGRP} " g " " r > f850
    print "${CHMOD} " m " " r > f860
    if ( 8 <= pin ) {
      pin = 1
    } else {
      pin = pin + 1
    }
  } else if ( "l" == $3 ) {
    print "${LNSYMB} '" ol "' " r > f820
    print "${CHOWN} " u " " r > f840
    print "${CHGRP} " g " " r > f850
  } else if ( "h" == $3 ) {
    print "${LNHARD} " o " " r > f830
  }
}
END {
  SECTION_LINE > f860
  SECTION_LINE > f850
  SECTION_LINE > f840
  SECTION_LINE > f830
  SECTION_LINE > f820
  SECTION_LINE > f810
  SECTION_LINE > f800
  close( f860 )
  close( f850 )
  close( f840 )
  close( f830 )
  close( f820 )
  close( f810 )
  close( f800 )
}
AWKRESTORE

start_progress "Preparing shellscripts for case of restore"

awk ${awkLint}                              \
    -f "${f700}"                            \
    -v backupDir="${backupDirAwk}"          \
    -v restoreDir="${sourceDirAwk}"         \
    -v f800="${f800Awk}"                    \
    -v f810="${f810Awk}"                    \
    -v f820="${f820Awk}"                    \
    -v f830="${f830Awk}"                    \
    -v f840="${f840Awk}"                    \
    -v f850="${f850Awk}"                    \
    -v f860="${f860Awk}"                    \
    "${f505}"

stop_progress

###########################################################

if [ ${noExec} -eq 1 ]; then
  exit 0
fi

echo
echo "TO BE REMOVED FROM ${backupDirTerm}"
echo "==========================================="

awk ${awkLint} -f "${f104}" -v color=${color} "${f510}"

if [ -s "${f510}" ]; then
  echo
  read -p "Execute above listed removals from ${backupDirTerm} ? [Y/y=Yes, other=do nothing and abort]: " tmpVal
  if [ "Y" == "${tmpVal/y/Y}" ]; then
    echo
    bash "${f610}" | awk ${awkLint} -f "${f102}" -v color=${color}
  else
    error_exit "User requested Zaloha to abort"
  fi
fi

echo
echo "TO BE COPIED TO ${backupDirTerm}"
echo "==========================================="

awk ${awkLint} -f "${f104}" -v color=${color} "${f520}"

if [ -s "${f520}" ]; then
  echo
  read -p "Execute above listed copies to ${backupDirTerm} ? [Y/y=Yes, other=do nothing and abort]: " tmpVal
  if [ "Y" == "${tmpVal/y/Y}" ]; then
    echo
    bash "${f620}" | awk ${awkLint} -f "${f102}" -v color=${color}
  else
    error_exit "User requested Zaloha to abort"
  fi
fi

if [ ${revNew} -eq 1 ] || [ ${revUp} -eq 1 ]; then
  echo
  echo "TO BE REVERSE-COPIED TO ${sourceDirTerm}"
  echo "==========================================="

  awk ${awkLint} -f "${f104}" -v color=${color} "${f530}"

  if [ -s "${f530}" ]; then
    echo
    read -p "Execute above listed reverse-copies to ${sourceDirTerm} ? [Y/y=Yes, other=do nothing and abort]: " tmpVal
    if [ "Y" == "${tmpVal/y/Y}" ]; then
      echo
      bash "${f630}" | awk ${awkLint} -f "${f102}" -v color=${color}
    else
      error_exit "User requested Zaloha to abort"
    fi
  fi
else
  if [ -s "${f530}" ]; then
    error_exit "Unexpected, REV actions prepared although neither --revNew nor --revUp options given"
  fi
fi

bash "${f690}"       # touch the file 999_mark_executed

###########################################################

# end
