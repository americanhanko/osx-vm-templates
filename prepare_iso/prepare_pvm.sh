#!/bin/sh -e

usage() {
  cat <<EOF
Usage:
$(basename "$0") "/path/to/diskimage.vhd"

Description:
Creates and exports a Parallels virtual machine (PVM) from a virtual disk image

EOF
}

cleanup() {
  if [ -n "$VM" ] && prlctl list --all | grep -q "$VM"; then
    prlctl unregister "$VM"
  fi
}

# trap cleanup EXIT INT TERM

msg_status() {
  echo "\\033[0;32m-- $1\\033[0m"
}

msg_error() {
  echo "\\033[0;31m-- $1\\033[0m"
}

render_template() {
  eval "echo \"$(cat "$1")\""
}

if [ ! -f "$1" ]; then
  usage
  exit 1
fi

HARDDRIVE="$1"
VM="$(basename "${HARDDRIVE%.vhd}")"

OUTPUT="${HARDDRIVE%.vhd}.pvm"
ABS_PATH="$(realpath "$OUTPUT")"

ABS_PARENT="$(dirname "$ABS_PATH")"
CONVERTED_HDD="${ABS_PATH}/${VM}.hdd"
PARALLELS_HDD="${ABS_PATH}/Macintosh.hdd"

msg_status "Creating a new Parallels virtual machine: $VM"
prlctl create "$VM" --distribution macosx --no-hdd --dst="$ABS_PARENT"

msg_status "Converting VHD to Parallels format"
prl_convert "$HARDDRIVE" --dst="$OUTPUT" --allow-no-os
mv "$CONVERTED_HDD" "$PARALLELS_HDD"

msg_status "Compacting $PARALLELS_HDD"
prl_disk_tool compact --hdd "$PARALLELS_HDD"

msg_status "Adding SATA Controller and attaching Parallels HDD"
prlctl set "$VM" --device-add hdd --image "$PARALLELS_HDD" --iface sata --position 0

msg_status "Setting up Parallels virtual machine"
prlctl set "$VM" --efi-boot "on"
prlctl set "$VM" --cpus "2"
prlctl set "$VM" --memsize "4096"
prlctl set "$VM" --memquota "512:2048"
prlctl set "$VM" --3d-accelerate "highest"
prlctl set "$VM" --high-resolution "off"
prlctl set "$VM" --auto-share-camera "off"
prlctl set "$VM" --auto-share-bluetooth "off"
prlctl set "$VM" --on-window-close "keep-running"
prlctl set "$VM" --shf-host "off"

#msg_status "Installing Parallels tools"
#prlctl installtools "$VM"

cleanup

msg_status "Done. Virtual machine export located at $OUTPUT."
