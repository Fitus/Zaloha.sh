# Zaloha.sh: End of Life

Zaloha has been superseded by **[Zaloha2.sh](https://github.com/Fitus/Zaloha2.sh)**.

 * Zaloha2.sh contains new features (the Remote Modes) and other improvements of design, program code and documentation.
 * For new deployments, go straight to [Zaloha2.sh](https://github.com/Fitus/Zaloha2.sh).
 * For migrations, check the table below if adaptations of your wrapper scripts are necessary.

## Full list of changes (Zaloha2.sh compared to Zaloha.sh)

Some design changes break backward compatibility with the original (now obsolete) Zaloha.sh.
For this reason, [Zaloha2.sh](https://github.com/Fitus/Zaloha2.sh) lives in a new repository.

Zaloha.sh&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | Zaloha2.sh
--------- | ----------
&nbsp; | New option **--sourceUserHost** to activate the Remote Source Mode via SSH/SCP
&nbsp; | New option **--backupUserHost** to activate the Remote Backup Mode via SSH/SCP
&nbsp; | New option **--sshOptions** to pass additional command-line options to SSH in the remote modes
&nbsp; | New option **--scpOptions** to pass additional command-line options to SCP in the remote modes
&nbsp; | New option **--findParallel** to run the local and remote FIND scans in parallel in the remote modes
Option **--metaDir** | In Remote Backup Mode: allows to place the Zaloha metadata directory on the remote backup host to a different location than the default.
&nbsp; | New option **--metaDirTemp**: In the remote modes, Zaloha2 needs a temporary Metadata directory too. This option allows to place it to a different location than the default.
Shellscript **610** | In Remote Backup Mode: executed on the remote side
Shellscript **620** | Split to **621** (pre-copy), **622** (copy), **623** (post-copy). In Remote Backup Mode: **621** and **623** are executed on the remote side. In both remote modes, **622** contains SCP commands instead of CP commands.
Shellscript **630** | Split to **631** (pre-copy), **632** (copy), **633** (post-copy). In Remote Source Mode: **631** and **633** are executed on the remote side. In both remote modes, **632** contains SCP commands instead of CP commands.
Shellscript **640** | In Remote Backup Mode: executed on the remote side
Shellscript **650** | Split to **651** (pre-copy), **652** (copy), **653** (post-copy). In Remote Backup Mode: **651** and **653** are executed on the remote side. In both remote modes, **652** contains SCP commands instead of CP commands.
Restore script **810** | In the remote modes: contains SCP commands instead of CP commands
Restore script **815** | Commands to preserve times of files have been moved from script **810** to script **815**
&nbsp; | New option **--sha256** for comparing the contents of files via SHA-256 hashes
CSV data model of **16&nbsp;columns** | Extended to **17&nbsp;columns** to accommodate the SHA-256 hashes in new separate column 13 (original columns 13+14+15+16 shifted to 14+15+16+17)
&nbsp; | New check for falsely detected hardlinks: SHA-256 hash differs
Option **--hLinks** | Renamed to **--detectHLinksS** (more descriptive option name)
Option **--touch** | Renamed to **--extraTouch** (more descriptive option name)
Option **--noExec1Hdr** | Renamed to **--no610Hdr**
Option **--noExec2Hdr** | Replaced by finer-grained options **--no621Hdr**, **--no622Hdr** and **--no623Hdr**
Option **--noExec3Hdr** | Replaced by finer-grained options **--no631Hdr**, **--no632Hdr** and **--no633Hdr**
Option **--noExec4Hdr** | Renamed to **--no640Hdr**
Option **--noExec5Hdr** | Replaced by finer-grained options **--no651Hdr**, **--no652Hdr** and **--no653Hdr**
&nbsp; | Ability to process **all symbolic links** (even those with target paths that contain three or more consective slashes). The implied change is additional escaping of slashes by ///s in column 16 for symbolic links.
&nbsp; | New Sanity Check for column 6 not alphanumeric
&nbsp; | More stringent directories hierarchy check
&nbsp; | More tolerant check of modification times of files (zero or even negative modification times are possible)
&nbsp; | More tolerant check of target paths of symbolic links (empty target paths are possible on some OSes)
&nbsp; | Minor code improvements and optimizations + improved documentation
Code size 76 kB | Code size 112 kB
Docu size 78 kB | Docu size 97 kB

## License
MIT License

