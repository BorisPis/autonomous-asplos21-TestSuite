#!/bin/bash

[ -z "$CORES" ] && CORES=4
[ -z "$ZC" ] && ZC=0
[ -z "$ZCOPY" ] && ZCOPY=0
[ -z "$ZCRC" ] && ZCRC=0
[ -z "$ZREQ" ] && ZREQ=0
[ -z "$FSIZE" ] && FSIZE=4096
[ -z "$CONNS" ] && CONNS=128

SUITE=$TBASE/TestSuite/
FSIZE=$FSIZE CONNS=$CONNS CORES=$CORES ZC=$ZC ZCOPY=$ZCOPY ZCRC=$ZCRC $SUITE/Tests/nginx/test.sh

