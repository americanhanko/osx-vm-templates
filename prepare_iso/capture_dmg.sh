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

INPUT_DMG="$1"
MOUNTOUTPUT=$(hdiutil attach "$INPUT_DMG" -nobrowse -owners on)
DISK_DEV=$(grep GUID_partition_scheme <<< "$MOUNTOUTPUT" | cut -f1 | tr -d '[:space:]')
OUT_DIR="$2"
VHD_NAME="${INPUT_DMG%.dmg}.vhd"
OUTPUT_VHD="$OUT_DIR/$VHD_NAME"

if [ -z "$INPUT_DMG" ]; then
  exit_with_error "A dmg is required as the first argument."
elif [ -z "$OUT_DIR" ]; then
  exit_with_error "Currently an explicit output directory is required as the second argument."
elif [ ! -d "$OUT_DIR" ]; then
  msg_status "Destination dir $OUT_DIR doesn't exist, creating.."
  mkdir -p "$OUT_DIR"
fi

if [ -z "$OUTPUT_VHD" ]; then
  OUTPUT_VHD="$OUT_DIR/$VHD_NAME"
elif [ -e "$OUTPUT_VHD" ]; then
  exit_with_error "Output file $OUTPUT_VHD already exists! We're not going to overwrite it, exiting.."
fi

DISK_SIZE_GB=32
DISK_SIZE_BYTES=$((DISK_SIZE_GB * 1024 * 1024 * 1024))

if [ ! -e "$DISK_DEV" ]; then
  exit_with_error "Failed to find the device file of the image"
fi

msg_status "Exporting from $DISK_DEV to $OUTPUT_VHD"
diskutil unmount "$DISK_DEV"
VBoxManage convertfromraw stdin "$OUTPUT_VHD" "$DISK_SIZE_BYTES" < "$DISK_DEV" --format VHD
