### OVERVIEW

<pre>
Zaloha is a shellscript for synchronization of files and directories. It is
a much simpler alternative to RSYNC, with key differences:

 * Zaloha is a bash shellscript that uses only FIND, SORT and AWK. All you need
   is THIS file. For documentation, also read THIS file.
 * Both &lt;sourceDir&gt; and &lt;backupDir&gt; must be available locally (local HDD/SSD,
   flash drive, mounted Samba or NFS volume).
 * Zaloha does not lock files while copying them. No writing on either directory
   may occur while Zaloha runs.
 * Zaloha always copies whole files (not parts of files like RSYNC). This is,
   however, fully sufficient in many situations.
 * Zaloha has optional reverse-synchronization features (details below).
 * Zaloha prepares scripts for case of eventual restore (details below).

To detect which files need synchronization, Zaloha compares file sizes and
modification times. It is clear that such detection is not 100% waterproof.
A waterproof solution requires comparing file contents, e.g. via "byte by byte"
comparison or via SHA-256 hashes. However, such comparing would increase the
runtime by orders of magnitude. Therefore, it is not enabled by default.
Section Advanced Use of Zaloha describes two alternatives how to enable or
implement it.

Zaloha asks to confirm actions before they are executed, i.e. prepared actions
can be skipped, exceptional cases manually resolved, and Zaloha re-run.
For automatic operations, use the <b>--noExec</b> option to tell Zaloha to not ask
and to not execute the actions (but still prepare the scripts).

&lt;sourceDir&gt; and &lt;backupDir&gt; can be on different filesystem types if the
filesystem limitations are not hit. Such limitations are (e.g. in case of
ext4 -&gt; FAT32): not allowed characters in filenames, filename uppercase
conversions, file size limits, etc.

No writing on either directory may occur while Zaloha runs (no file locking is
implemented). In demanding IT operations where backup must run concurrently with
writing, a higher class of backup solution should be deployed, like storage
snapshots (i.e. functionality that must be supported by the underlying
OS/hardware).

Handling of "weird" characters in filenames was a special focus during
development of Zaloha (details below).

On Linux/Unics, Zaloha runs natively. On Windows, Cygwin is needed.

Repository: <a href="https://github.com/Fitus/Zaloha.sh">https://github.com/Fitus/Zaloha.sh</a>
</pre>


### MORE DETAILED DESCRIPTION

<pre>
The operation of Zaloha can be partitioned into five steps, in that following
actions are performed:

Exec1:  unavoidable removals from &lt;backupDir&gt; (objects of conflicting types
        which occupy needed namespace)
-----------------------------------
<b>RMDIR</b>     regular remove directory from &lt;backupDir&gt;
<b>REMOVE</b>    regular remove file from &lt;backupDir&gt;
<b>REMOVE.!</b>  remove file from &lt;backupDir&gt; which is newer than the
          last run of Zaloha
<b>REMOVE.x</b>  remove other object on &lt;backupDir&gt; that occupies needed namespace,
          x = object type (l/p/s/c/b/D)

Exec2:  copy files/directories to &lt;backupDir&gt; which exist only on &lt;sourceDir&gt;,
        or files which are newer on &lt;sourceDir&gt;
-----------------------------------
<b>MKDIR</b>     regular create new directory on &lt;backupDir&gt;
<b>NEW</b>       regular create new file on &lt;backupDir&gt;
<b>UPDATE</b>    regular update file on &lt;backupDir&gt;
<b>UPDATE.!</b>  update file on &lt;backupDir&gt; which is newer than the last run of Zaloha
<b>UPDATE.?</b>  update file on &lt;backupDir&gt; by a file on &lt;sourceDir&gt; which is not newer
          (by more than 1 sec (or 3601 secs if <b>--ok3600s</b>))
<b>unl.UP</b>    unlink file on &lt;backupDir&gt; + <b>UPDATE</b> (can be switched off via the
          <b>--noUnlink</b> option, see below)
<b>unl.UP.!</b>  unlink file on &lt;backupDir&gt; + <b>UPDATE.!</b> (can be switched off via the
          <b>--noUnlink</b> option, see below)
<b>unl.UP.?</b>  unlink file on &lt;backupDir&gt; + <b>UPDATE.?</b> (can be switched off via the
          <b>--noUnlink</b> option, see below)
<b>ATTR:ugm</b>  update only attributes on &lt;backupDir&gt; (u=user ownership,
          g=group ownership, m=mode) (optional feature, see below)

Exec3:  reverse-synchronization from &lt;backupDir&gt; to &lt;sourceDir&gt; (optional
        feature, can be activated via the <b>--revNew</b> and <b>--revUp</b> options)
-----------------------------------
<b>REV.MKDI</b>  reverse-create parent directory on &lt;sourceDir&gt; due to <b>REV.NEW</b>
<b>REV.NEW</b>   reverse-create file on &lt;sourceDir&gt; (if a standalone file on
          &lt;backupDir&gt; is newer than the last run of Zaloha)
<b>REV.UP</b>    reverse-update file on &lt;sourceDir&gt; (if the file on &lt;backupDir&gt;
          is newer than the file on &lt;sourceDir&gt;)
<b>REV.UP.!</b>  reverse-update file on &lt;sourceDir&gt; which is newer
          than the last run of Zaloha

Exec4:  remaining removals of obsolete files/directories from &lt;backupDir&gt;
        (can be optionally switched off via the <b>--noRemove</b> option)
-----------------------------------
<b>RMDIR</b>     regular remove directory from &lt;backupDir&gt;
<b>REMOVE</b>    regular remove file from &lt;backupDir&gt;
<b>REMOVE.!</b>  remove file from &lt;backupDir&gt; which is newer than the
          last run of Zaloha
<b>REMOVE.x</b>  remove other object on &lt;backupDir&gt; that occupies needed namespace,
          x = object type (l/p/s/c/b/D)

Exec5:  updates resulting from optional "byte by byte" comparing of files
        (optional feature, can be activated via the <b>--byteByByte</b> option)
-----------------------------------
<b>UPDATE.b</b>  update file on &lt;backupDir&gt; because it is not identical byte by byte
<b>unl.UP.b</b>  unlink file on &lt;backupDir&gt; + <b>UPDATE.b</b> (can be switched off via the
          <b>--noUnlink</b> option, see below)

(internal use, for completion only)
-----------------------------------
<b>OK</b>        object without needed action on &lt;sourceDir&gt; (either files or
          directories already synchronized with &lt;backupDir&gt;, or other objects
          not to be synchronized to &lt;backupDir&gt;). These records are necessary
          for preparation of shellscripts for the case of restore.
<b>OK.b</b>      file proven identical byte by byte (in CSV metadata file 555)
<b>KEEP</b>      object to be kept only on &lt;backupDir&gt;
<b>uRMDIR</b>    unavoidable <b>RMDIR</b> which goes into Exec1 (in CSV files 380 and 390)
<b>uREMOVE</b>   unavoidable <b>REMOVE</b> which goes into Exec1 (in CSV files 380 and 390)
</pre>


### INDIVIDUAL STEPS IN FULL DETAIL

<pre>
Exec1:
------
Unavoidable removals from &lt;backupDir&gt; (objects of conflicting types which occupy
needed namespace). This must be the first step, because objects of conflicting
types on &lt;backupDir&gt; would prevent synchronization (e.g. a file cannot overwrite
a directory).

Exec2:
------
Files and directories which exist only on &lt;sourceDir&gt; are copied to &lt;backupDir&gt;
(action codes <b>NEW</b> and <b>MKDIR</b>).

Zaloha "updates" the file on &lt;backupDir&gt; (action code <b>UPDATE</b>) if the same file
exists on both &lt;sourceDir&gt; and &lt;backupDir&gt; and the comparisons of modification
time and file size indicate the necessity of this "update". If the file on
&lt;backupDir&gt; is multiply linked (hardlinked), Zaloha removes (unlinks) it first,
to prevent "updating" a multiply linked file, which could lead to follow-up
effects (action code <b>unl.UP</b>). This unlinking can be switched off via the
<b>--noUnlink</b> option.

If the files differ only in attributes (u=user ownership, g=group ownership,
m=mode), and attribute synchronization is switched on via the <b>--pUser,</b>
<b>--pGroup</b> and <b>--pMode</b> options, then only these attributes will be
synchronized (action code <b>ATTR</b>). However, this is an optional feature, because:
(1) the filesystem of &lt;backupDir&gt; might not be capable of storing these
attributes, or (2) it may be wanted that all files and directories on
&lt;backupDir&gt; are owned by the user who runs Zaloha.

Regardless of whether these attributes are synchronized or not, an eventual
restore of &lt;sourceDir&gt; from &lt;backupDir&gt; including these attributes is possible
thanks to the restore scripts which Zaloha prepares in its metadata directory
(see below).

Symbolic links on &lt;sourceDir&gt; are neither followed nor synchronized to
&lt;backupDir&gt;, but Zaloha prepares a restore script in its metadata directory.

Zaloha contains an optional feature to detect multiply linked (hardlinked) files
on &lt;sourceDir&gt;. If this feature is switched on (via the <b>--hLinks</b> option),
Zaloha internally flags the second, third, etc. links to same file as
"hardlinks", and synchronizes to &lt;backupDir&gt; only the first link (the "file").
The "hardlinks" are not synchronized to &lt;backupDir&gt;, but Zaloha prepares a
restore script in its metadata directory. If this feature is switched off
(no <b>--hLinks</b> option), then each link to a multiply linked file is treated as
a separate regular file.

The detection of hardlinks brings two risks: Zaloha might not detect that a file
is in fact a hardlink, or Zaloha might falsely detect a hardlink while the file
is in fact a unique file. The second risk is more severe, because the contents
of the unique file will not be synchronized to &lt;backupDir&gt; in such case.
For that reason, Zaloha contains additional checks against falsely detected
hardlinks (see code of AWKHLINKS). Generally, use this feature only after proper
testing on your filesystems. Be cautious as inode-related issues exist on some
filesystems and network-mounted filesystems.

Zaloha does not synchronize other types of objects on &lt;sourceDir&gt; (named pipes,
sockets, special devices, etc). These objects are considered to be part of the
operating system or parts of applications, and dedicated scripts for their
(re-)creation should exist.

It was a conscious decision to synchronize to &lt;backupDir&gt; only files and
directories and keep other objects in metadata only. This gives more freedom
in the choice of filesystem type for &lt;backupDir&gt;, because every filesystem type
is able to store files and directories, but not necessarily the other objects.

Exec3:
------
This step is optional and can be activated via the <b>--revNew</b> and <b>--revUp</b>
options.

Why is this feature useful? Imagine you use a Windows notebook while working in
the field.  At home, you have got a Linux server to that you regularly
synchronize your data. However, sometimes you work directly on the Linux server.
That work should be "reverse-synchronized" from the Linux server (&lt;backupDir&gt;)
back to the Windows notebook (&lt;sourceDir&gt;) (of course, assumed that there is no
conflict between the work on the notebook and the work on the server).

<b>REV.NEW:</b> If a standalone file on &lt;backupDir&gt; is newer than the last run of
Zaloha, and the <b>--revNew</b> option is given, then that file will be
reverse-copied to &lt;sourceDir&gt; (<b>REV.NEW</b>) including all necessary parent
directories (<b>REV.MKDI</b>).

<b>REV.UP:</b> If the same file exists on both &lt;sourceDir&gt; and &lt;backupDir&gt;, and the
file on &lt;backupDir&gt; is newer, and the <b>--revUp</b> option is given, then that file
will be used to reverse-update the older file on &lt;sourceDir&gt;
(action code <b>REV.UP</b>).

Optionally, to preserve attributes during the <b>REV.MKDI,</b> <b>REV.NEW</b> and <b>REV.UP</b>
operations: use options <b>--pRevUser,</b> <b>--pRevGroup</b> and <b>--pRevMode.</b>

If reverse-synchronization is not active: If no <b>--revNew</b> option is given,
then each standalone file on &lt;backupDir&gt; is considered obsolete (and removed).
If no <b>--revUp</b> option is given, then files on &lt;sourceDir&gt; always update files
on &lt;backupDir&gt; if they differ.

Reverse-synchronization to &lt;sourceDir&gt; increases the overall complexity of the
solution. Use it only in the interactive regime of Zaloha, where human oversight
and confirmation of prepared actions are in place.
Do not use it in automatic operations.

Exec4:
------
Zaloha removes all remaining obsolete files and directories from &lt;backupDir&gt;.
This function can be switched off via the <b>--noRemove</b> option.

Why are removals from &lt;backupDir&gt; split into two steps (Exec1 and Exec4)?
Imagine a scenario when a directory is renamed on &lt;sourceDir&gt;: If all removals
were concentrated in Exec1, then &lt;backupDir&gt; would transition through a state
(namely between Exec1 and Exec2) when the backup copy of the directory is
already removed (under the old name), but not yet created (under the new name).
To prevent such transient states, the removals (except the unavoidable ones)
are postponed to Exec4.

Advise to this topic: In case of bigger reorganizations of &lt;sourceDir&gt;, also
e.g. in case when a directory with large content is renamed, it is much better
to prepare a rename script (more generally speaking: a migration script) and
apply it to both &lt;sourceDir&gt; and &lt;backupDir&gt;, instead of letting Zaloha perform
massive copying followed by massive removing.

Exec5:
------
Zaloha updates files on &lt;backupDir&gt; for which the optional "byte by byte"
comparing revealed that they are in fact not identical (despite appearing
identical by looking at their sizes and modification times).

Action codes are <b>UPDATE.b</b> and <b>unl.UP.b</b> (the latter is update with prior
unlinking of multiply linked target file, as described under Exec2).

Please note that these actions might indicate deeper problems like storage
corruption (or even spoofing attempts), and should be actually perceived
as surprises.

This step is optional and can be activated via the <b>--byteByByte</b> option.

Metadata directory of Zaloha
----------------------------
Zaloha creates a metadata directory: &lt;backupDir&gt;/.Zaloha_metadata. The location
of the metadata directory can be changed via the <b>--metaDir</b> option.

The purposes of individual files are described as comments in program code.
Briefly, they are:

 * AWK program files (produced from "here documents" in Zaloha)
 * Shellscripts to run FIND commands
 * CSV metadata files
 * Exec1/2/3/4/5 shellscripts
 * Shellscripts for the case of restore
 * Touchfile marking execution of actions

Files persist in the metadata directory until the next invocation of Zaloha.

To obtain information about what Zaloha did (counts of removed/copied files,
total counts, etc), do not parse the screen output: Query the CSV metadata files
instead. Query the CSV metadata files after AWKCLEANER. Do not query the raw
CSV outputs of the FIND commands (before AWKCLEANER) and the produced
shellscripts, because due to eventual newlines in filenames, they may contain
multiple lines per "record".

Shellscripts for case of restore
--------------------------------
Zaloha prepares shellscripts for the case of restore in its metadata directory
(scripts 800 through 860). Each type of operation is contained in a separate
shellscript, to give maximum freedom (= for each script, decide whether to apply
or to not apply). Further, each shellscript has a header part where
key variables for whole script are defined (and can be adjusted as needed).
</pre>


### INVOCATION

<pre>
<b>Zaloha.sh</b> <b>--sourceDir</b>=&lt;sourceDir&gt; <b>--backupDir</b>=&lt;backupDir&gt; [ other options ... ]

<b>--sourceDir</b>=&lt;sourceDir&gt; is mandatory. &lt;sourceDir&gt; must exist, otherwise Zaloha
    throws an error (except when the <b>--noDirChecks</b> option is given).

<b>--backupDir</b>=&lt;backupDir&gt; is mandatory. &lt;backupDir&gt; must exist, otherwise Zaloha
    throws an error (except when the <b>--noDirChecks</b> option is given).

<b>--findSourceOps</b>=&lt;findSourceOps&gt; are additional operands for FIND command that
    searches &lt;sourceDir&gt;, to be used to exclude files or subdirectories from
    synchronization, based on file path or file name patterns:

      -path &lt;file path pattern&gt; -prune -o
      -name &lt;file name pattern&gt; -prune -o

    If the pattern matches a subdirectory, the "-prune" operand instructs FIND
    to not descend into it.

    Each expression must be followed by the OR operator (-o). If several
    expressions are given, they must form an OR-connected chain:
    expressionA -o expressionB -o expressionC -o ... This is required because
    Zaloha internally combines &lt;findSourceOps&gt; with &lt;findGeneralOps&gt; and with
    own operands, and all of them follow this convention. If an earlier
    expression in the OR-connected chain evaluates TRUE, FIND does not evaluate
    following operands, leading to no output being produced. 

    &lt;findSourceOps&gt; applies only to &lt;sourceDir&gt;. If a file on &lt;sourceDir&gt; is
    excluded by &lt;findSourceOps&gt; and the same file exists on &lt;backupDir&gt;,
    then Zaloha evaluates the file on &lt;backupDir&gt; as obsolete (= removes it).
    Compare this with &lt;findGeneralOps&gt; (see below).

    Although &lt;findSourceOps&gt; consists of multiple words, it is passed in as
    a single string (= enclose it in double-quotes or single-quotes in your
    shell). Zaloha contains a special parser (AWKPARSER) that splits it into
    separate words (arguments for the FIND command). If a word (pattern) in
    &lt;findSourceOps&gt; contains spaces, enclose it in double-quotes. Note: to
    protect the double-quotes from your shell, use \". If a word (pattern) in
    &lt;findSourceOps&gt; itself contains a double quote, use \". Note: to protect
    the backslash and the double-quote from your shell, use \\\".

    Please note that in the patterns of the -path and -name operands, FIND
    itself interprets following characters specially (see FIND documentation):
    *, ?, [, ], \. If these characters are to be taken literally, they must be
    backslash-escaped. Again, take care of protecting backslashes from your
    shell.

    If the expression with the "-path" test is used, the placeholder ///d/
    should be used in place of &lt;sourceDir&gt;/. Zaloha will replace ///d/ by
    &lt;sourceDir&gt;/ in the form that is passed to FIND, and with eventual FIND
    pattern special characters properly escaped (which relieves you from doing
    the same by yourself).

    Examples: * exclude &lt;sourceDir&gt;/.git,
              * exclude all files or subdirectories Windows Security
              * exclude all files or subdirectories My "Secret" Things

    (double-quoted and single-quoted versions):

    --findSourceOps="-path ///d/.git -prune -o"
    --findSourceOps="-name \"Windows Security\" -prune -o"
    --findSourceOps="-name \"My \\\"Secret\\\" Things\" -prune -o"

    --findSourceOps='-path ///d/.git -prune -o'
    --findSourceOps='-name "Windows Security" -prune -o'
    --findSourceOps='-name "My \"Secret\" Things" -prune -o'

<b>--findGeneralOps</b>=&lt;findGeneralOps&gt; underlies the same rules as &lt;findSourceOps&gt;
    (please read first). The key difference is that &lt;findGeneralOps&gt; applies to
    both &lt;sourceDir&gt; and &lt;backupDir&gt;. This means, that files and subdirectories
    excluded by &lt;findGeneralOps&gt; are not visible to Zaloha, so Zaloha will not
    act on them. The main use of &lt;findGeneralOps&gt; is to exclude "Trash"
    subdirectories from synchronization. &lt;findGeneralOps&gt; has an internally
    defined default, used to exclude:

    &lt;sourceDir or backupDir&gt;/$RECYCLE.BIN
      ... Windows Recycle Bin (assumed to exist directly under &lt;sourceDir&gt; or
          &lt;backupDir&gt;)

    &lt;sourceDir or backupDir&gt;/.Trash_&lt;number&gt;*
      ... Linux Trash (assumed to exist directly under &lt;sourceDir&gt; or
          &lt;backupDir&gt;)

    &lt;sourceDir or backupDir&gt;/lost+found
      ... Linux lost + found filesystem fragments (assumed to exist directly
          under &lt;sourceDir&gt; or &lt;backupDir&gt;)

    The placeholder ///d/ is for &lt;sourceDir&gt;/ or &lt;backupDir&gt;/, depending on the
    actual search, and it must be used if the expression with the "-path" test
    is used, unless, perhaps, the &lt;sourceDir&gt; and &lt;backupDir&gt; parts of the paths
    are matched by a wildcard.

    Beware of matching &lt;sourceDir&gt; or &lt;backupDir&gt; themselves by the patterns.

    To extend (= combine, not replace) the internally defined &lt;findGeneralOps&gt;
    with own extension, pass in own extension prepended by the plus sign ("+").

    *** CAUTION &lt;findSourceOps&gt; AND &lt;findGeneralOps&gt;: Zaloha will not prevent
    passing in other FIND expressions than described above, to allow eventual
    advanced use by knowledgeable users.

<b>--noExec</b>        ... needed if Zaloha is invoked automatically: do not ask,
    do not execute the actions, but still prepare the scripts. The prepared
    scripts then do not contain shell tracing and they do not contain the
    "set -e" instruction. This means that the scripts ignore individual failed
    commands and try to do as much work as possible, which is a behavior
    different from the interactive regime, where scripts are traced and halt
    on the first error.

<b>--noRemove</b>      ... do not remove files and directories which exist only
    on &lt;backupDir&gt;. This option is useful in situations like that &lt;sourceDir&gt;
    holds only "current" files but &lt;backupDir&gt; should hold "current" plus
    "historical" files.

    Please keep in mind that if objects of conflicting types on &lt;backupDir&gt;
    prevent synchronization (e.g. a file cannot overwrite a directory),
    removals are unavoidable and will be prepared regardless of this option.
    In such case Zaloha displays a warning message in the interactive regime.
    In automatic operations, the calling process should query the CSV metadata
    file 510 to detect this case.

<b>--revNew</b>        ... enable <b>REV.NEW</b> (= if standalone file on &lt;backupDir&gt; is
                    newer than the last run of Zaloha, reverse-copy it
                    to &lt;sourceDir&gt;)

<b>--revUp</b>         ... enable <b>REV.UP</b> (= if file on &lt;backupDir&gt; is newer than
                    file on &lt;sourceDir&gt;, reverse-update the file on &lt;sourceDir&gt;)

<b>--hLinks</b>        ... perform hardlink detection (inode-deduplication)
                    on &lt;sourceDir&gt;

<b>--ok3600s</b>       ... additional tolerance for modification time differences of
                    exactly +/- 3600 seconds (explained in Special Cases section
                    below)

<b>--byteByByte</b>    ... compare "byte by byte" files that appear identical (more
                    precisely, files for which no action (<b>OK</b>) or just update of
                    attributes (<b>ATTR</b>) has been prepared).
                    (Explained in the Advanced Use of Zaloha section below).
                    This comparison might be dramatically slower than other
                    steps. If additional updates of files result from this
                    comparison, they will be executed in step Exec5.

<b>--noUnlink</b>      ... never unlink multiply linked files on &lt;backupDir&gt; before
                    writing to them

<b>--touch</b>         ... use cp + touch instead of cp --preserve=timestamps
                    (explained in Special Cases section below)

<b>--pUser</b>         ... synchronize user ownerships on &lt;backupDir&gt;
                    based on &lt;sourceDir&gt;

<b>--pGroup</b>        ... synchronize group ownerships on &lt;backupDir&gt;
                    based on &lt;sourceDir&gt;

<b>--pMode</b>         ... synchronize modes (permission bits) on &lt;backupDir&gt;
                    based on &lt;sourceDir&gt;

<b>--pRevUser</b>      ... preserve user ownerships during REV operations

<b>--pRevGroup</b>     ... preserve group ownerships during REV operations

<b>--pRevMode</b>      ... preserve modes (permission bits) during REV operations

<b>--noRestore</b>     ... do not prepare scripts for the case of restore (= saves
    processing time and disk space, see optimization remarks below). The scripts
    for the case of restore can still be produced ex-post by manually running
    the respective AWK program (700 file) on the source CSV file (505 file).

<b>--optimCSV</b>      ... optimize space occupied by CSV metadata files by removing
    intermediary CSV files after use (see optimization remarks below).
    If intermediary CSV metadata files are removed, an ex-post analysis of
    eventual problems may be impossible.

<b>--metaDir</b>=&lt;metaDir&gt; allows to place the Zaloha metadata directory to a different
    location than the default (which is &lt;backupDir&gt;/.Zaloha_metadata).
    The reasons might be:
      a) non-writable &lt;backupDir&gt; (if Zaloha is used to perform comparison only
        (i.e. with <b>--noExec</b> option))
      b) a requirement to have Zaloha metadata on a separate storage
      c) advanced use of Zaloha, see Advanced Use of Zaloha section below
    It is possible (but not recommended) to place &lt;metaDir&gt; to a different
    location inside of &lt;backupDir&gt;, or inside of &lt;sourceDir&gt;. In such cases,
    FIND operands to exclude the metadata directory from the FIND searches must
    be explicitly passed in via &lt;findGeneralOps&gt;.
    If Zaloha is used to synchronize multiple directories, then each such
    instance of Zaloha must have its own separate metadata directory.

<b>--noDirChecks</b>   ... switch off the checks for existence of &lt;sourceDir&gt; and
    &lt;backupDir&gt;. (Explained in the Advanced Use of Zaloha section below).

<b>--noLastRun</b>     ... do not obtain information about the last run of Zaloha by
                    running FIND on file 999 in Zaloha metadata directory.
                    This makes Zaloha state-less, which might be a desired
                    property in certain situations. However, it sacrifices
                    features based on the last run of Zaloha: <b>REV.NEW</b> and
                    distinction of operations on files newer than the last run
                    of Zaloha (e.g. distinction between <b>UPDATE.!</b> and <b>UPDATE</b>).

<b>--noFindSource</b>  ... do not run FIND (script 210) to search &lt;sourceDir&gt;
                    and use externally supplied CSV metadata file 310 instead
<b>--noFindBackup</b>  ... do not run FIND (script 220) to search &lt;backupDir&gt;
                    and use externally supplied CSV metadata file 320 instead
   (Explained in the Advanced Use of Zaloha section below).

<b>--noExec1Hdr</b>    ... do not write header to the shellscript for Exec1 (file 610)
<b>--noExec2Hdr</b>    ... do not write header to the shellscript for Exec2 (file 620)
<b>--noExec3Hdr</b>    ... do not write header to the shellscript for Exec3 (file 630)
<b>--noExec4Hdr</b>    ... do not write header to the shellscript for Exec4 (file 640)
<b>--noExec5Hdr</b>    ... do not write header to the shellscript for Exec5 (file 650)
   These options can be used only together with the <b>--noExec</b> option.
   (Explained in the Advanced Use of Zaloha section below).

<b>--noR800Hdr</b>     ... do not write header to the restore script 800
<b>--noR810Hdr</b>     ... do not write header to the restore script 810
<b>--noR820Hdr</b>     ... do not write header to the restore script 820
<b>--noR830Hdr</b>     ... do not write header to the restore script 830
<b>--noR840Hdr</b>     ... do not write header to the restore script 840
<b>--noR850Hdr</b>     ... do not write header to the restore script 850
<b>--noR860Hdr</b>     ... do not write header to the restore script 860
   (Explained in the Advanced Use of Zaloha section below).

<b>--noProgress</b>    ... suppress progress messages (less screen output)
    If both options <b>--noExec</b> and <b>--noProgress</b> are used, Zaloha does not
    produce any output on stdout (traditional behavior of Unics tools).

<b>--color</b>         ... use color highlighting (can be used on terminals which
                    support ANSI escape codes)

<b>--lTest</b>         ... (do not use in real operations) support for lint-testing
                    of AWK programs

<b>--help</b>          ... show Zaloha documentation (using the LESS program) and exit

Optimization remarks: If Zaloha operates on directories with huge numbers of
files, especially small ones, then the size of metadata plus the size of scripts
for the case of restore may exceed the size of the files themselves. If this
leads to hitting of storage and/or processing time limits, use options
<b>--noRestore</b> and <b>--optimCSV.</b>

Zaloha must be run by a user with sufficient privileges to read &lt;sourceDir&gt; and
to write and perform other required actions on &lt;backupDir&gt;. In case of the REV
actions, privileges to write and perform other required actions on &lt;sourceDir&gt;
are required as well. Zaloha does not contain any internal checks as to whether
privileges are sufficient. Failures of commands run by Zaloha must be monitored
instead.

Zaloha does not contain protection against concurrent invocations with
conflicting &lt;backupDir&gt; (and for REV also conflicting &lt;sourceDir&gt;): this is
responsibility of the invoker, especially due to the fact that Zaloha may
conflict with other processes as well.

In case of failure: resolve the problem and re-run Zaloha with same parameters.
In the second run, Zaloha should not repeat the actions completed by the first
run: it should continue from the action on which the first run failed. If the
first run completed successfully, no actions should be performed in the second
run (this is an important test case, see below).

Typically, Zaloha is invoked from a wrapper script that does the necessary
directory mounts, then runs Zaloha with the required parameters, then directory
unmounts.
</pre>


### TESTING, DEPLOYMENT, INTEGRATION

<pre>
First, test Zaloha on a small and noncritical set of your data. Although Zaloha
has been tested on several environments, it can happen that Zaloha malfunctions
on your environment due to different behavior of the operating system, bash,
FIND, SORT, AWK and other utilities. Perform tests in the interactive regime
first. If Zaloha prepares wrong actions, abort it at the next prompt.

After first synchronization, an important test is to run second synchronization,
which should execute no actions, as the directories should be already
synchronized.

Test Zaloha under all scenarios which can occur on your environment. Test Zaloha
with filenames containing "weird" or national characters.

Verify that all your programs that write to &lt;sourceDir&gt; change modification
times of the files written, so that Zaloha does not miss changed files.

Simulate the loss of &lt;sourceDir&gt; and perform test of the recovery scenario using
the recovery scripts prepared by Zaloha.

Automatic operations
--------------------
Additional care must be taken when using Zaloha in automatic operations
(<b>--noExec</b> option):

Exit status and standard error of Zaloha and of the scripts prepared by Zaloha
must be monitored by a monitoring system used within your IT landscape.
Nonzero exit status and writes to standard error must be brought to attention
and investigated. If Zaloha itself fails, the process must be aborted.
The scripts prepared under the <b>--noExec</b> option do not halt on the first error,
also their zero exit status does not imply that there were no failed
individual commands.

Implement sanity checks to avoid data disasters like synchronizing &lt;sourceDir&gt;
to &lt;backupDir&gt; in the moment when &lt;sourceDir&gt; is unmounted, which would lead
to loss of backup data. Evaluate counts of actions prepared by Zaloha (count
records in CSV metadata files in Zaloha metadata directory). Abort the process
if the action counts exceed sanity thresholds defined by you, e.g. when Zaloha
prepares an unexpectedly high number of removals.

The process which invokes Zaloha in automatic regime should function as follows
(pseudocode):

  run Zaloha.sh --noExec
  in case of failure: abort process
  perform sanity checks on prepared actions
  if ( sanity checks OK ) then
    execute script 610_exec1.sh
    execute script 620_exec2.sh
    execute script 630_exec3.sh
    execute script 640_exec4.sh
    execute script 650_exec5.sh
    monitor execution (writing to stderr)
    if ( execution successful ) then
      execute script 690_touch.sh
    end if
  end if
</pre>


### SPECIAL AND CORNER CASES

<pre>
To detect which files need synchronization, Zaloha compares file sizes and
modification times. If the file sizes differ, synchronization is needed.
The modification time is more tricky: Zaloha tolerates +/- 1 second differences,
due to FAT32 rounding to the nearest 2 seconds. In some situations, it is
necessary to tolerate differences of exactly +/- 1 hour (+/- 3600 seconds)
as well (to be activated via the <b>--ok3600s</b> option). Typically, this occurs
when one of the directories is on a filesystem type that stores modification
times not in universal time but in local time (e.g. FAT32), and the OS is
not able, for some reason, to correctly reflect the switching of
daylight saving time while converting the local time.

The +/- 1 hour differences, tolerable via the <b>--ok3600s</b> option, are assumed
to exist between &lt;sourceDir&gt; and &lt;backupDir&gt;, but not between &lt;backupDir&gt;
and &lt;metaDir&gt;. This is relevant especially if &lt;metaDir&gt; is located outside of
&lt;backupDir&gt; (via the <b>--metaDir</b> option).

It is possible (but not recommended) for &lt;backupDir&gt; to be a subdirectory of
&lt;sourceDir&gt; and vice versa. In such cases, conditions to avoid recursive copying
must be passed in via &lt;findGeneralOps&gt;.

In some situations (e.g. Linux Samba + Linux Samba client),
cp --preserve=timestamps does not preserve modification timestamps (unless on
empty files). In that case, Zaloha should be instructed (via the <b>--touch</b>
option) to use subsequent touch commands instead, which is a more robust
solution. In the scripts for case of restore, touch commands are used
unconditionally.

Corner case <b>REV.NEW</b> with namespace on &lt;sourceDir&gt; needed for <b>REV.MKDI</b> or <b>REV.NEW</b>
action is occupied by object of conflicting type: The file on &lt;backupDir&gt;
will not be reverse-copied to &lt;sourceDir&gt;, but removed. As this file must be
newer than the last run of Zaloha, the action will be <b>REMOVE.!.</b>

Corner case <b>REV.NEW</b> with <b>--findSourceOps:</b> If the same file exists on both
&lt;sourceDir&gt; and &lt;backupDir&gt;, and on &lt;sourceDir&gt; that file is masked by
&lt;findSourceOps&gt; and on &lt;backupDir&gt; that file is newer than the last run of
Zaloha, <b>REV.NEW</b> on that file will be prepared. This is an error which Zaloha
is unable to detect. Hence, the shellscript for Exec3 contains a test that
throws an error in such situation.

Corner case <b>REV.UP</b> with <b>--ok3600s:</b> The <b>--ok3600s</b> option makes it harder
to determine which file is newer (decision <b>UPDATE</b> vs <b>REV.UP</b>). The implemented
solution for that case is that for <b>REV.UP,</b> the &lt;backupDir&gt; file must be newer
by more than 3601 seconds.

Corner case <b>REV.UP</b> with hardlinked file: Reverse-updating a multiply linked
(hardlinked) file on &lt;sourceDir&gt; may lead to follow-up effects.

Corner case <b>REV.UP</b> with <b>--hLinks:</b> If hardlink detection on &lt;sourceDir&gt; is
active (<b>--hLinks</b> option), then Zaloha supports reverse-update of only the
first link on &lt;sourceDir&gt; (the one that stays tagged as "file" (f) in
CSV metadata after AWKHLINKS).

Corner case update of attributes with hardlinked file: Updating attributes on a
multiply linked (hardlinked) file may lead to follow-up effects.

Corner case if directory .Zaloha_metadata exists under &lt;sourceDir&gt; as well
(e.g. in case of backups of backups): It will be ignored. If a backup of that
directory is needed as well, it should be solved separately (Hint: if the
secondary backup starts one directory higher, then .Zaloha_metadata of the
original backup will be taken).
</pre>


### HOW ZALOHA WORKS INTERNALLY

<pre>
Handling and checking of input parameters should be self-explanatory.

The actual program logic is embodied in AWK programs, which are contained in
Zaloha as "here documents".

The AWK program AWKPARSER parses the FIND operands assembled from
&lt;findSourceOps&gt; and &lt;findGeneralOps&gt; and constructs the FIND commands.
The outputs of running these FIND commands are tab-separated CSV metadata files
that contain all information needed for following steps. These CSV metadata
files, however, must first be processed by AWKCLEANER to handle (escape)
eventual tabs and newlines in filenames.

The cleaned CSV metadata files are then checked by AWKCHECKER for unexpected
deviations (in which case an error is thrown and the processing stops).

The next (optional) step is to detect hardlinks: the CSV metadata file from
&lt;sourceDir&gt; will be sorted by device number + inode number. This means that
multiply-linked files will be in adjacent records. The AWK program AWKHLINKS
evaluates this situation: The type of the first link will be kept as "file" (f),
the types of the other links will be changed to "hardlinks" (h).

Then comes the core function of Zaloha. The CSV metadata files from &lt;sourceDir&gt;
and &lt;backupDir&gt; will be united and sorted by filename and the Source/Backup
indicator. This means that objects existing in both directories will be in
adjacent records, with the &lt;backupDir&gt; record coming first. The AWK program
AWKDIFF evaluates this situation (as well as records from objects existing in
only one of the directories), and writes target state of synchronized
directories with actions to reach that target state.

The output of AWKDIFF is then sorted by filename in reverse order (so that
parent directories come after their children) and post-processed by AWKPOSTPROC.
AWKPOSTPROC modifies actions on parent directories of files to <b>REV.NEW</b> and
objects to <b>KEEP</b> only on &lt;backupDir&gt;.

The remaining code uses the produced data to perform actual work, and should be
self-explanatory.

Understanding AWKDIFF is the key to understanding of whole Zaloha. An important
hint to AWKDIFF is that it distinguishes three types of filesystem objects:
directories, files and other objects. At any given path, each of the three types
on &lt;sourceDir&gt; can meet each of the three types on &lt;backupDir&gt;. This gives a
3x3 matrix. Additionally, an object can be standalone on &lt;sourceDir&gt;, giving
further 3 cases, and standalone on &lt;backupDir&gt;, giving the last 3 cases.
Also, mathematically, there are 3x3 + 3 + 3 = 15 cases to be handled by AWKDIFF.
The AWKDIFF code is commented on key places to make orientation easier.
A good case to begin with is case 5 (file on &lt;sourceDir&gt;, file on &lt;backupDir&gt;),
as this is the most important (and complex) case.

If you are a database developer, you can think of the CSV metadata files as
tables, and Zaloha as a program that operates on these tables: It fills them
with data obtained from the filesystems (via FIND), then processes the data
(defined sequence of sorts, sequential processings, unions and selects), then
converts the data to shellscripts, and finally executes the shellscripts
to apply the required changes back to the filesystems.

Among the operations which Zaloha performs, there is no operation which would
require the CSV metadata to fit as a whole into memory. This means that the size
of memory does not constrain Zaloha on how big "tasks" it can handle.
The critical operations from this perspective are the sorts. However,
GNU sort, for instance, is able to intelligently switch to an external
sort-merge algorithm, if it determines that the data is "too big",
thus mitigating this concern.

Talking further in database developer's language: The data model of all CSV
metadata files is the same and is described in form of comments in AWKPARSER.
Files 310 and 320 do not qualify as tables, as their fields and records are
broken by eventual tabs and newlines in filenames. In files 330 through 370,
field 2 is the Source/Backup indicator. In files 380 through 555, field 2 is
the Action Code.

The natural primary key in files 330 through 360 is the file's path (column 13).
In files 370 through 505, the natural primary key is combined column 13 with
column 2. In files 510 through 555, the natural primary key is again
column 13 alone.

The combined primary key in file 505 is obvious e.g. in the case of other object
on &lt;sourceDir&gt; and other object on &lt;backupDir&gt;: File 505 then contains an
<b>OK</b> record for the former and a <b>KEEP</b> record for the latter, both with the same
file's path (column 13).
</pre>


### TECHNIQUES USED BY ZALOHA TO HANDLE WEIRD CHARACTERS IN FILENAMES

<pre>
Handling of "weird" characters in filenames was a special focus during
development of Zaloha. Actually, it was an exercise of how far can be gone with
shellscript alone, without reverting to a C program. Tested were:
!"#$%&amp;'()*+,-.:;&lt;=&gt;?@[\]^`{|}~, spaces, tabs, newlines, alert (bell) and
a few national characters (beyond ASCII 127). Please note that on some
filesystem types, some weird characters are not allowed at all.

Zaloha internally uses tab-separated CSV files, also tabs and newlines are major
disruptors. The solution is based on the following idea: POSIX (the most
"liberal" standard under which Zaloha must function) says that filenames may
contain all characters except slash (/, the directory separator) and ASCII NUL.
Hence, except these two, no character can be used as an escape character
(if we do not want to introduce some re-coding). Further, ASCII NUL is not
suitable, as it is widely used as a string delimiter. Then, let's have a look
at the directory separator itself: It cannot occur inside of filenames.
It separates file and directory names in the paths. As filenames cannot have
zero length, no two slashes can appear in sequence. The only exception is the
naming convention for network-mounted directories, which may contain two
consecutive slashes at the beginning. But three consecutive slashes
(a triplet ///) are impossible. Hence, it is a waterproof escape sequence.
This opens the way to represent a tab as ///t and a newline as ///n.

For display of filenames on terminal (and only there), control characters (other
than tabs and newlines) are displayed as ///c, to avoid terminal disruption.
(Such control characters are still original in the CSV metadata files).

Further, /// is used as first field in the CSV metadata files, to allow easy
separation of record lines from continuation lines caused by newlines in
filenames (it is impossible that continuation lines have /// as the first field,
because filenames cannot contain the newline + /// sequence).

Finally, /// are used as terminator fields in the CSV metadata files, to be able
to determine where the filenames end in a situation when they contain tabs and
newlines (it is impossible that filenames produce a field containing /// alone,
because filenames cannot contain the tab + /// sequence).

An additional challenge is passing of variable values to AWK. During its
lexical parsing, AWK interprets backslash-led escape sequences. To avoid this,
backslashes are converted to ///b in the bash script, and ///b are converted
back to backslashes in the AWK programs.

Zaloha checks that no input parameters contain ///, to avoid breaking of the
internal escape logic from the outside. The only exception are &lt;findSourceOps&gt;
and &lt;findGeneralOps&gt;, which may contain the ///d/ placeholder.

In the shellscripts produced by Zaloha, single quoting is used, hence single
quotes are disruptors. As a solution, the '"'"' quoting technique is used.

The SORT commands are run under the LC_ALL=C environment variable, to avoid
problems caused by some locales that ignore slashes and other punctuations
during sorting.

In the CSV metadata files 330 through 500 (i.e. those which undergo the sorts),
file's paths (field 13) have directory separators (/) appended and all
directory separators then converted to ///s. This is to ensure correct sort
ordering. Imagine the ordering bugs which would happen otherwise:
  Case 1: given dir and dir!, they would be sort ordered:
          dir, dir!, dir!/subdir, dir/subdir.
  Case 2: given dir and dir&lt;tab&gt;ectory, they would be sort ordered:
          dir/!subdir1, dir///tectory, dir/subdir2.

Zaloha does not contain any explicit handling of national characters in
filenames (= characters beyond ASCII 127). It is assumed that the commands used
by Zaloha handle them transparently (which should be tested on environments
where this topic is relevant). &lt;sourceDir&gt; and &lt;backupDir&gt; must use the same
code page for national characters in filenames, because Zaloha does not contain
any code page conversions.
</pre>


### ADVANCED USE OF ZALOHA - DIRECTORIES NOT AVAILABLE LOCALLY

<pre>
Zaloha contains several options to handle situations when &lt;sourceDir&gt; and/or
&lt;backupDir&gt; are not available locally. In the extreme case, Zaloha can be used
as a mere "difference engine" by a wrapper script, which obtains the inputs
(FIND data from &lt;sourceDir&gt; and/or &lt;backupDir&gt;) remotely, and also applies the
outputs (= executes the Exec1/2/3/4/5 scripts) remotely.

First useful option is <b>--noDirChecks:</b> This switches off the checks for local
existence of &lt;sourceDir&gt; and &lt;backupDir&gt;.

If &lt;backupDir&gt; is not available locally, it is necessary to use the <b>--metaDir</b>
option to place the Zaloha metadata directory to a different location accessible
to Zaloha.

Next useful options are <b>--noFindSource</b> and/or <b>--noFindBackup:</b> They instruct
Zaloha to not run FIND on &lt;sourceDir&gt; and/or &lt;backupDir&gt;, but use externally
supplied CSV metadata files 310 and/or 320 instead. This means that these files
must be produced by the wrapper script (e.g. by running FIND commands in an SSH
session) and downloaded to the Zaloha metadata directory before invoking Zaloha.
These files must, of course, have the same names and formats as the CSV metadata
files that would otherwise be produced by the scripts 210 and/or 220.

The <b>--noFindSource</b> and/or <b>--noFindBackup</b> options are also useful when
network-mounted directories are available locally, but running FIND on them is
slow. Running the FINDs directly on the respective file servers in SSH sessions
should be much quicker.

If &lt;sourceDir&gt; or &lt;backupDir&gt; are not available locally, the <b>--noExec</b> option
must be used to prevent execution of the Exec1/2/3/4/5 scripts by Zaloha itself.

Last set of useful options are <b>--noExec1Hdr</b> through <b>--noExec5Hdr.</b> They
instruct Zaloha to produce header-less Exec1/2/3/4/5 scripts (i.e. bodies only).
The headers normally contain definitions used in the bodies of the scripts.
Header-less scripts can be easily used with alternative headers that contain
different definitions. This gives much flexibility:

The "command variables" can be assigned to different commands (e.g. cp -&gt; scp).
Own shell functions can be defined and assigned to the "command variables".
This makes more elaborate processing possible, as well as calling commands that
have different order of command line arguments. Next, the "directory variables"
sourceDir and backupDir can be assigned to empty strings, thus causing the paths
passed to the commands to be not prefixed by &lt;sourceDir&gt; or &lt;backupDir&gt;.
</pre>


### ADVANCED USE OF ZALOHA - COPYING FILES IN PARALLEL

<pre>
First, let's clarify when parallel operations do not make sense: When copying
files locally, even one single process will probably fully utilize the available
bus capacity. In such cases, copying files in parallel does not make sense.

Contrary to this, imagine what happens when a process copies a small file over
a network with high latency: sending out the small file takes microseconds,
but waiting for the network round-trip to finish takes milliseconds. Also, the
process is idle most of the time, and the network capacity is under-utilized.
In such cases, also typically when many small files are copied over a network,
running the processes in parallel will speed up the process significantly.

Zaloha provides support for parallel operations of up to 8 parallel processes
(variable MAXPARALLEL). How to utilize this support:

Let's take the Exec2 script as an example (file 620): make 1+8=9 copies of the
Exec2 script. In the header of the first copy, keep only MKDIR, CHOWN_DIR,
CHGRP_DIR and CHMOD_DIR assigned to real commands, and assign all other
"command variables" to the empty command (shell builtin ":"). This first copy
will hence prepare only the directories and must run first. In the next copy,
keep only CP1, TOUCH1, UNLINK1, CHOWN1, CHGRP1 and CHMOD1 assigned to real
commands. In the over-next copy, keep only CP2, TOUCH2, UNLINK2, CHOWN2, CHGRP2
and CHMOD2 assigned to real commands, and so on in the other copies. Each of
these remaining 8 copies will hence process only its own portion of files, so
they can be run in parallel.

These manipulations should, of course, be automated by a wrapper script: The
wrapper script should invoke Zaloha with the <b>--noExec</b> and <b>--noExec2Hdr</b>
options, also Zaloha prepares the 620 script without header (i.e. body only).
The wrapper script should prepare the 1+8 different headers and use them
with the header-less 620 script.

Exec1 and Exec4: use the same recipe, except that the one script which removes
the directories must run last, of course, not first.
</pre>


### ADVANCED USE OF ZALOHA - COMPARING CONTENTS OF FILES

<pre>
First, let's make it clear that comparing contents of files will increase the
runtime dramatically, because instead of reading just the directory data to
obtain file sizes and modification times, the files themselves must be read.

ALTERNATIVE 1: option <b>--byteByByte</b> (suitable if both filesystems are local)

Option <b>--byteByByte</b> forces Zaloha to compare "byte by byte" files that appear
identical (more precisely, files for which no action (<b>OK</b>) or just update of
attributes (<b>ATTR</b>) has been prepared). If additional updates of files result from
this comparison, they will be executed in step Exec5.

ALTERNATIVE 2: overload the file size field (CSV column 4) with SHA-256 hash

The idea is: Zaloha does not compare file sizes numerically, but as strings.
Also, appending semicolon (";") and the SHA-256 hash to the file size field
achieves exactly what is needed: If the file size is identical but the SHA-256
hash differs, Zaloha will detect that the file needs synchronization.

There is an almost 100% security that files are identical if they have equal
sizes and SHA-256 hashes. An implementation requires use of the <b>--noFindSource</b>
and <b>--noFindBackup</b> options with own mechanism of (local or remote) preparation
of CSV metadata files 310 and 320 with column 4 overloaded as described.
</pre>
