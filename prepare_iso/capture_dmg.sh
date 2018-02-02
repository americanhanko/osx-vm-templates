#!/bin/bash

none='\033[0m'
green='\033[0;32m'
red='\033[0;31m'

msg_status(){
  echo -e "$green-- $1"
  echo -ne "$none"
}

msg_error(){
  echo -e "$red-- $1"
  echo -ne "$none"
}

exit_with_error(){
  msg_error "$1"
  exit 1
}

DISK_DEV="$1"
OUT_DIR="$2"
VHD_NAME="${OUT_DIR%.vhd}"

if [ -z "$DISK_DEV" ]; then
  exit_with_error "An explicit device is required as the first argument. (e.g. /dev/disk2)"
elif [ -z "$OUT_DIR" ]; then
  exit_with_error "Currently an explicit output directory is required as the second argument."
elif [ ! -d "$OUT_DIR" ]; then
  msg_status "Destination dir $OUT_DIR doesn't exist, creating.."
  mkdir -p "$OUT_DIR"
fi

if [ -z "$OUTPUT_DMG" ]; then
  OUTPUT_DMG="$OUT_DIR/$VHD_NAME"
elif [ -e "$OUTPUT_DMG" ]; then
  exit_with_error "Output file $OUTPUT_DMG already exists! We're not going to overwrite it, exiting.."
fi

DISK_SIZE_GB=32
DISK_SIZE_BYTES=$((DISK_SIZE_GB * 1024 * 1024 * 1024))

if [ ! -e "$DISK_DEV" ]; then
  exit_with_error "Failed to find the device file of the image"
fi

msg_status "Exporting from $DISK_DEV to $OUTPUT_DMG"
VBoxManage convertfromraw stdin "$OUTPUT_DMG" "$DISK_SIZE_BYTES" < "$DISK_DEV" --format VHD
