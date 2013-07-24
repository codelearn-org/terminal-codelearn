#!/bin/bash

DIR=$1
JAIL=/opt/terminal-demo

umount $JAIL/$DIR/usr
umount $JAIL/$DIR/lib
rm -rf $JAIL/$DIR
