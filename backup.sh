#!/bin/bash

# This scripts performs a full system backup. It requires 1 paramter, the PATH to the backup location.
# TODO Ensure this script brings the system down.

set -Eeuox pipefail
cd "$(dirname "$0")"

# The administrator should mount this directory.
#SPINNING HDD is best option since backups are blob and read and written lineraly.
BACKUP_PATH="$HOME/bcm_backup"

for i in "$@"; do
    case $i in
        --backup-path=*)
            BACKUP_PATH="${i#*=}"
            shift
        ;;
        *)
            # unknown option
        ;;
    esac
done

mkdir -p "$BACKUP_PATH"

DEFAULT_KEY_ID="$(cat $HOME/.gnupg/gpg.conf | grep 'default-key' | awk  '{print $2}')"

if [ -z $DEFAULT_KEY_ID ]; then
    echo "ERROR: The DEFAULT_KEY_ID could not be identified. You may need to run the bcm installer."
    exit
fi

# ~/media is where ubuntu mounts our disks, which is where we are usually saving our backups to, so we exclude it.
duplicity --verbosity info \
--encrypt-key "$DEFAULT_KEY_ID" \
--exclude "$BACKUP_PATH" \
"$HOME/bcm" "file://$BACKUP_PATH"

#duplicity remove-older-than 1Y --force ftp://FtpUserID@ftp.domain.com/etc
#--exclude "$HOME/bcm" \
#--exclude "$HOME/.cache" \
#--exclude "$HOME/.config" \
#--exclude "$HOME/bcm_disks" \
#--exclude "$HOME/.bitcoin" \
