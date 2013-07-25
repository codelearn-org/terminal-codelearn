#!/bin/bash

DIR=/tmp/.$1
JAIL=/opt/users-rails-apps

#umount $JAIL/$DIR/usr
#umount $JAIL/$DIR/lib
rm -rf $JAIL/$DIR
