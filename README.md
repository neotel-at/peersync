PeerSync
========

A simple rsync-based peer file syncronisation tool to keep a defined list of 
directories and files in sync on two hosts. Usually used on cluster nodes 
sharing the same configurations.

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
        Compore the file contents of changed file against peer. A local copy
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

Example file filtering rules in /etc/peersync.files:

    - /nginx/ssl/
    + /nginx/***
    - *

For the `SYNCROOT=/etc/` this will sync all nginx configurations of /etc/nginx (and below), exlcuding the /etc/nginx/ssl directory.
All other files in /etc will also be excluded, due to the '`- *`' rule.

This example will sync only the `nginx` directory excluding the `nginx/ssl` sub-
directory, all other files and directory are not considered. The example assumes `/etc` as the synchronization root directory (`SYNCROOT=/etc/`).

See the INCLUDE/EXCLUDE PATTERN RULES section in the rsync manpage for details.

COPYRIGHT
---------

(C)2015-2018, NeoTel Telefonservice GmbH & Co KG
