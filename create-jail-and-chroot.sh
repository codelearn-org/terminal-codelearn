#!/bin/bash

JAIL_DIR=/opt/users-rails-apps
DIR=/tmp/.$1
USER=user_`rand --max 4500`
#USER=user_16
NEW_JAIL_DIR=/opt/users-rails-apps/$DIR

mkdir $NEW_JAIL_DIR

#cp -r $JAIL_DIR/bin $NEW_JAIL_DIR/bin

#cp -r $JAIL_DIR/etc $NEW_JAIL_DIR/etc
#echo "root:x:0:0:root:/home:/bin/bash
mkdir $NEW_JAIL_DIR/etc
echo "$USER:x:1001:1001::/home:/bin/bash" > $NEW_JAIL_DIR/etc/passwd
cp $JAIL_DIR/etc/group $NEW_JAIL_DIR/etc/group

#mkdir $NEW_JAIL_DIR/usr
#mkdir $NEW_JAIL_DIR/lib

#mount /usr $NEW_JAIL_DIR/usr -o bind #--verbose
#mount -o remount,ro $NEW_JAIL_DIR/usr #--verbose
#mount /lib $NEW_JAIL_DIR/lib -o bind #--verbose
#mount -o remount,ro $NEW_JAIL_DIR/lib #--verbose

mkdir $NEW_JAIL_DIR/home
chown $USER $NEW_JAIL_DIR/home
echo "HOME=/home; cd /home; alias ls='ls --color=auto'; export PS1='\w\$ '" > $NEW_JAIL_DIR/home/.bashrc

#chroot --userspec guest $NEW_JAIL_DIR /bin/bash --rcfile /home/.bashrc
#chroot --userspec $USER $NEW_JAIL_DIR /bin/bash --rcfile /home/.bashrc -c "su user_16"
su $USER -c "ulimit -d 20000 -v 20000 -f 1000 -n 100 -s 512 -t 20 -x 20 -l 64;
proot -b /bin:/bin -b /usr:/usr -b /lib:/lib -b /dev:/dev -b /lib64:/lib64 -r $DIR -w /home  /bin/bash --rcfile /home/.bashrc"
