#!/bin/bash

JAIL_DIR=/opt/users-rails-apps
NEW_JAIL_DIR=/opt/terminal-demo
DIR=$1

mkdir $NEW_JAIL_DIR/$DIR
cp -r $JAIL_DIR/bin $NEW_JAIL_DIR/$DIR/bin
cp -r $JAIL_DIR/etc $NEW_JAIL_DIR/$DIR/etc
mkdir $NEW_JAIL_DIR/$DIR/usr
mkdir $NEW_JAIL_DIR/$DIR/lib

mount /usr $NEW_JAIL_DIR/$DIR/usr -o bind #--verbose
mount -o remount,ro $NEW_JAIL_DIR/$DIR/usr #--verbose
mount /lib $NEW_JAIL_DIR/$DIR/lib -o bind #--verbose
mount -o remount,ro $NEW_JAIL_DIR/$DIR/lib #--verbose

mkdir $NEW_JAIL_DIR/$DIR/home
chown guest:guest $NEW_JAIL_DIR/$DIR/home
echo "HOME=/home; cd /home; export PS1='\[\e[32m\]\u@\h\[\e[0m\] \[\e[35m\]\w\[\e[0m\]\$ '" > $NEW_JAIL_DIR/$DIR/home/.bashrc

chroot --userspec guest $NEW_JAIL_DIR/$DIR /bin/bash --rcfile /home/.bashrc
