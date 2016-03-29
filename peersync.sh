#!/bin/bash
# PeerSync - a file syncronization tool for clustered hosts 
# Author: roland.lammel@neotel.at
# (C)2015, NeoTel Telefonservice GmbH & Co KG

VERSION=0.9.0
PEERSYNCCONFIGS="$HOME/.peersync /etc/peersync.conf"
DEBUG=${DEBUG-0}
VERBOSE=${VERBOSE-0}
DRYRUN=1

# User-configurable options, which may be overridden in PEERSYNCCONF
PEER=peer
SYNCROOT=/etc/
SYNCFILES=/etc/peersync.files
RSYNCOPTS="-avhizO --numeric-ids --checksum --delete-after"
SYNCTMPDIR=/tmp
DIFFBIN=diff
DIFFOPTS="-urw"

### FUNCTIONS

debuglog() {
    if [ $DEBUG -eq 1 ]; then
        echo "[DEBUG] $*"
    fi
}

verbose() {
    if [ $VERBOSE -eq 1 ]; then
        echo "$*"
    fi
}

version() {
    echo "PeerSync v$VERSION - A peer file syncronisation tool based on rsync"
    echo "(C)2014, NeoTel Telefonservice GmbH & Co KG"
}

rsync_peer() {
    debuglog "Executing (verbose=$VERBOSE): rsync $RSYNCOPTS --filter=". $SYNCFILES" $SYNCROOT $PEER:$SYNCROOT"

    if [ $DRYRUN -eq 1 ]; then
        RSYNCOPTS="$RSYNCOPTS --dry-run"
    fi

    if [ $VERBOSE -eq 1 ]; then
        rsync $RSYNCOPTS --filter=". $SYNCFILES" $SYNCROOT $PEER:$SYNCROOT
    else
        rsync $RSYNCOPTS --filter=". $SYNCFILES" $SYNCROOT $PEER:$SYNCROOT | grep -v '^\.[fdL]\.\.t\.\.\.\.\.\. '
    fi

    RC=$?
    debuglog "Rsync returned exit code $RC"
}

rdiff_peer() {
    if [ -z "$DIFFTMPDIR" -o "$DIFFTMPDIR" = "" ]; then
        TMPDIR=`mktemp -d /tmp/peersync.XXXX`
    else
        TMPDIR=$DIFFTMPDIR
    fi

    if [ ! -d "$TMPDIR" ]; then
        verbose "* Create temp. path $TMPDIR for diff"
        mkdir -p "$TMPDIR"
    else
        ### Cleanup tmpdir for new compare
        rm -rf "$TMPDIR/local"
        rm -rf "$TMPDIR/peer"
    fi

    write_tempfilter $TMPDIR/peerdiff.files

    verbose "* Sync local ($SYNCROOT) and remote ($PEER:$SYNCROOT) files to $TMPDIR"

    rsync -ahd --filter=". $SYNCFILES" $PEER:$SYNCROOT $TMPDIR/peer/;
    rsync -ahd --filter=". $SYNCFILES" $SYNCROOT $TMPDIR/local/;

    verbose "* Compare content ($DIFFBIN) in $TMPDIR/peer and $TMPDIR/local"
    verbose ""
    $DIFFBIN $DIFFOPTS $TMPDIR/peer $TMPDIR/local

    if [ $DEBUG -eq 0 ]; then
        debuglog "Cleanup tmpdir $TMPDIR"
        rm -rf "$TMPDIR"
    fi
}

write_tempfilter() {
    TMPFILTER=$1
    shift

    debuglog "* Prepare filelist for remote diff in $TMPFILTER: $*"
    echo "# auto-generated peersync compare filter" > $TMPFILTER
    if [ $# -gt 0 ]; then
        for path in $*; do
            debuglog "  * Adding: $path"
            echo $path | awk -F '/' '{ PATH=""; for (i = 1; i < NF; i++) { PATH=PATH $i "/"; print "+ " PATH }; print "+ " $0 }' >> $TMPFILTER
        done
    else
        rsync -aiO --dry-run --filter=". $SYNCFILES" $SYNCROOT $PEER:$SYNCROOT | awk '{ print $2 }' | awk -F '/' '{ PATH=""; for (i = 1; i < NF; i++) { PATH=PATH $i "/"; print "+ " PATH }; print "+ " $0 }' | sort -u > $TMPFILTER
    fi
    echo "- *" >> $TMPFILTER
    if [ $DEBUG -eq 1 ]; then
        cat $TMPFILTER
    fi
}

### BASIC CLI PROCESSING

if [ "$1" = "version" ]; then
    version
    exit 1
fi

if [ "$1" = "help" ]; then
    version
    cat <<__EOF_HELP

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
        If "verbose" is specified also candidate files not considered for 
        syncing are shown

    diff [FILE1 FILE2 ...]
        Compare the file contents of changed file against peer. Both local and
        remote files will be synced to a temporary directory and processed by a
        local diff command (default: diff -urw)

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

The configuration for peersync can be placed in $HOME/.peersync or 
/etc/peersync.conf. The first file found will be loaded. 

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

__EOF_HELP
    exit 1
fi

### PREPROCESS COMMANDLINE

debuglog "Preprocessing commandline $* "
while getopts "ds:Cc:p:" opt $*; do
  debuglog "Processing option $opt"
  case $opt in
    s)
      debuglog "Setting syncroot to $OPTARG"
      FORCESYNCROOT=$OPTARG
      ;;
    C)
      debuglog "Setting no configuration file"
      PEERSYNCCONF=-
      SYNCFILES=-
      ;;
    c)
      debuglog "Setting configuration file to $OPTARG"
      PEERSYNCCONF=$OPTARG
      ;;
    p)
      debuglog "Setting peer to $OPTARG"
      FORCEPEER=$OPTARG
      ;;
    d)
      DEBUG=1
      ;;
    \?)
      echo "Invalid option: -$OPTARG"
      ;;
  esac
done
shift $((OPTIND-1))

CMD=$1
shift
if [ -z "$CMD" ]; then
    CMD="show"
fi

### LOAD CONFIGURATION

if [ -z "$PEERSYNCCONF" ]; then
    debuglog "* Searching for configuration"
    for conf in $PEERSYNCCONFIGS; do
        debuglog " - Try loading: $conf"
        if [ -r "$conf" ]; then
            debuglog "Using configuration - Try loading: $conf"
            PEERSYNCCONF=$conf
            break
        fi
    done
fi

if [ "$PEERSYNCCONF" != "-" ]; then
    if [ ! -r "$PEERSYNCCONF" ]; then
        echo "PeerSync configuration file $PEERSYNCCONF not found. Please create."
        echo "See peersync help for details."
        exit 1
    fi

    debuglog "Loading configuration $PEERSYNCCONF"
    . "$PEERSYNCCONF"
fi

if [ ! -z $FORCEPEER ]; then
    PEER=$FORCEPEER
fi
if [ ! -z $FORCESYNCROOT ]; then
    SYNCROOT=$FORCESYNCROOT
fi

debuglog "Using configuration"
debuglog "    PEER=$PEER"
debuglog "    SYNCFILES=$SYNCFILES"
debuglog "    SYNCROOT=$SYNCROOT"
debuglog "    RSYNCOPTS=$RSYNCOPTS"

### VERIFY CONFIGURATION IS SET

if [ "$SYNCFILES" != "-" ]; then
    if [ -z "$SYNCFILES" ]; then
        echo "ERROR: PeerSync file filter rules are not defined."
        echo "Please ensure SYNCFILES is set to a file specifying filtering rules"
        exit 1
    fi
fi

if [ -z "$SYNCROOT" ]; then
    echo "ERROR: SYNCROOT is not set. Please ensure SYNCROOT is set to a valid directory."
    exit 1
fi



### VERIFY CONFIGURATION IS VALID

if [ "$SYNCFILES" != "-" ]; then
    if [ ! -r "$SYNCFILES" ]; then
        echo "ERROR: Peersync file filtering rules '$SYNCFILES' not found. Please create."
        echo "For instructions see peersync help"
        exit 1
    fi
fi

if [[ ! "$SYNCROOT" =~ /$ ]]; then
    SYNCROOT=$SYNCROOT/
    echo "Appending '/' to syncroot: $SYNCROOT"
fi
if [ ! -d "$SYNCROOT" ]; then
    echo "ERROR: Specified SYNCROOT '$SYNCROOT' is not a directory or not readable."
    exit 1
fi


### PROCESS COMMANDS

# Disable wildcard expension now
set -f

case "$CMD" in
    sync | force)
        echo "*** Synchronizing and writting files in $SYNCROOT to $PEER"
        echo ""
        DRYRUN=0
        if [ "$1" = "verbose" ]; then
            VERBOSE=1
        fi
        if [ $# -gt 0 ]; then
            SYNCFILES=`mktemp`
            debuglog "sync using custom filelist $SYNCFILES"
            write_tempfilter $SYNCFILES $*
            rsync_peer
            rm $SYNCFILES
        else
            rsync_peer
        fi
        ;;
    show)
        echo "*** Show differences of files in $SYNCROOT against $PEER"
        echo ""
        DRYRUN=1
        if [ "$1" = "verbose" ]; then
            VERBOSE=1
        fi
        if [ $# -gt 0 ]; then
            SYNCFILES=`mktemp`
            debuglog "show using custom filelist $SYNCFILES"
            write_tempfilter $SYNCFILES $*
            rsync_peer
            rm $SYNCFILES
        else
            rsync_peer
        fi
        ;;
    diff)
        echo "*** Show content differences against $PEER"
        echo ""
        VERBOSE=1
        if [ $# -gt 0 ]; then
            debuglog "rdiff using custom filelist"
            SYNCFILES=`mktemp`
            write_tempfilter $SYNCFILES $*
            rdiff_peer
            rm $SYNCFILES
        else
            rdiff_peer
        fi
        ;;
    config)
        echo "*** Show peersync configuration $PEERSYNCCONF"
        cat $PEERSYNCCONF
        echo ""
        echo "*** Show file filtering configuration $SYNCFILES"
        cat $SYNCFILES
        echo ""
        ;;
    *)
        echo "Unknown command $CMD. Please see help for details"
        ;;
esac

