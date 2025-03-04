#!/bin/bash

SOURCE=$1

# Check if the ISO is already modified
if [ -n "$ENSURE_ISO_KICKSTART_LOGGING_DISABLED" -a -z "$(isoinfo -J -i $SOURCE -x /isolinux/isolinux.cfg | grep append | grep -v "inst\.nosave=all")" ]; then
  echo "'$SOURCE' has already been modified."
  exit 0
fi

set -e

echo "Modifying '$SOURCE'..."

WORKING=/tmp/remaster_iso_working
DESTINATION=$(echo $SOURCE | cut -d "." -f 1)-modified.iso

VOLUME_NAME=$(isoinfo -d -i $SOURCE | grep "Volume id:" | cut -d " " -f 3)

SOURCE_DIR=/tmp/remaster_iso_source

mkdir $SOURCE_DIR
mount -o loop $SOURCE $SOURCE_DIR
cp -ar $SOURCE_DIR $WORKING
umount $SOURCE_DIR
rm -rf $SOURCE_DIR

pushd $WORKING
  chmod -R u+w ./

  sed -i '/append/ s/$/ inst.nosave=all/' isolinux/isolinux.cfg

  mkisofs -o $DESTINATION -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -joliet-long -V "$VOLUME_NAME" -R -J -v -T .

popd

rm -rf $WORKING

implantisomd5 $DESTINATION

ORIGINAL=$(echo $SOURCE | cut -d "." -f 1)-original.iso
mv $SOURCE $ORIGINAL
mv $DESTINATION $SOURCE

set +e

echo "Modifying '$SOURCE'...Complete!"
