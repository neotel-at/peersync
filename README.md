peersync
========

A simple file syncronisation tool based on rsync to keep a defined list of
directories and files in sync on two hosts (peers). Usually used on cluster 
nodes to keep configurations consistent.

USAGE
-----

    peersync [ config | help | version ]
    peersync [OPTIONS] [ show | sync | diff ] [FILTER1 FILTER2 ...]

COMMANDS
--------

    show [FILTER1 FILTER2 ...]
        Show files, link and directories with differences (in rsync itemize 
        format), no files will be modified on the peer.
        If file filtering rules are specified, these will take precedence and
        only files matching this pattern will be considered. 
        See FILE FILTERING RULES below.

    sync [FILTER1 FILTER2 ...]
        Sync of files to peer, files on the peer will be over-written 
        (no backup is generated).
        File filtering rules may be specified (see show)

    diff [FILTER1 FILTER2 ...]
        Compare the file contents of changed file against peer. A local copy
        will be compared to a copy of the remote files using the diff command
        (default: diff -urw).
        File filtering rules may be specified (see show)

    config
        Show the current peersync configuration and file filter for syncing

    version
        Show the version of peersync

    help
        Show help on commands and configuration

When no command is specified "show" is assumed

OPTIONS
-------

    -c CONFIGFILE
        User configuraiton file from CONFIGFILE
    -C  Use no configuration file, be sure to specify -p and -s
    -h PEERHOST or -p PEERHOST
        Use PEERHOST as peer to sync against (usually USER@HOST or HOST)
    -s SYNCROOT
        Use SYNCROOT as root for syncronisation, overrides configuration
    -d Enable DEBUG logging, for debug purposes only

CONFIGURATION FILE
------------------

The configuration for peersync resides in $HOME/.peersync or /etc/peersync.conf.
The first file found will be loaded. 

Example configuration in /etc/peersync.conf (commented options show defaults):

    PEER=myuser@mypeer
    SYNCROOT=/etc/
    # SYNCFILES=/etc/peersync.files
    # RSYNCOPTS="-avhizO --checksum --delete-after"
    # DIFFBIN=diff
    # DIFFOPTS=-urw
    # DIFFTMPDIR=

To ensure consistent numeric user and group IDs the '--numeric-ids' rsync
option must be used. This requires a consistenc user configuation on the system:

    RSYNCOPTS="-avhizO --numeric-ids --checksum --delete-after"

FILE FILTERING RULES
--------------------

File filtering rules generally follow the rsync filter rules. Comments can be 
used by starting a line with '#'. See the INCLUDE/EXCLUDE PATTERN RULES section 
in the rsync manpage for details.

Example file filtering rules in /etc/peersync.files:

    # nginx configs
    - /nginx/ssl/
    + /nginx/***
    - *

The above example assumes '/etc' as the sync root directory ('SYNCROOT=/etc/')
and syncs only the 'nginx' directory excluding the 'nginx/ssl' sub directory. 
All other files and directory are exluded due to the trailing '- *' rule. 

COPYRIGHT
---------

(C)2015-2026, NeoTel Telefonservice GmbH & Co KG
