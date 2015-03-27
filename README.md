PeerSync
========

A peer file syncronisation tool based on rsync


USAGE
-----

    peersync [OPTIONS] [ show | sync | config | help | version ]

COMMANDS
--------

    show [verbose]
        Show files, link and directories with differences (in rsync itemize 
        format), no files will be modified on the peer
        If verbose is specified also candidate files not considered for syncing
        are shown

    sync [verbose]
        Sync of files to peer, files on the peer will be over-written 
        (no backup is generated)
        If "verbose" is specified also candidate files not considered for syncing
        are shown

    diff [FILE1 FILE2 ...]
        Compore the file contents of changed file against peer. A local copy will 
        be stored in  for both local and remote files, which will be
        processed by a local diff command (default: diff -urw)

    config
        Show the current peersync configuration and file filter for syncing

    help
        Show help on commands and configuration

When no command is specified "show" is assumed


OPTIONS
-------

    -c CONFIGFILE
        User configuraiton file from CONFIGFILE
    -C  Use no configuration file, be sure to specify -p and -s
    -p PEER
        Use PEER as peer to sync against (usually USER@HOST or HOST)
    -s SYNCROOT
        Use SYNCROOT as root for syncronisation, overrides configuration
    -d Enable DEBUG logging, for debug purposes only


CONFIGURATION FILE
------------------

The configuration for peersync can be placed in $HOME/.peersync or /etc/peersync.conf.
The first file found will be loaded. 

Example configuration in /etc/peersync.conf (commented options show defaults):

    PEER=myuser@mypeer
    SYNCROOT=/etc/
    # SYNCFILES=/etc/peersync.files
    # RSYNCOPTS=-avhizO --numeric-ids --checksum --delete-after
    # DIFFBIN=diff
    # DIFFOPTS=-urw
    # DIFFTMPDIR=


FILE FILTERING RULES
--------------------

Example file filtering in /etc/peersync.files:

    - /nginx/ssl/
    + /nginx/***
    - *

This example will sync only the nginx directory excluding the nginx/ssl sub-
directory, all other files and directory are not considered.

See the INCLUDE/EXCLUDE PATTERN RULES section in the rsync manpage for details.

COPYRIGHT
---------

(C)2015, NeoTel Telefonservice GmbH & Co KG
