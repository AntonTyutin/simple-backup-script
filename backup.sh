#!/bin/bash

DATE_MARK="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$(readlink -f "${1:-$PWD}")"
RECENT_BACKUP_NAME=""
RECENT_BACKUP_FILE=""
SELECTEL_AUTH_TOKEN=""

# backup_files <chdir> [<tar-name> <directory or file> ...|<single file or directory>]
backup_files() {
    [ "$#" -lt 2 ] && err "Too few arguments passed to backup_files (chdir file_or_dir)"
    local CHDIR="$1"; shift
    RECENT_BACKUP_NAME="$1_files"; [ "$#" -gt 1 ] && shift
    RECENT_BACKUP_FILE="$BACKUP_DIR/${RECENT_BACKUP_NAME}_${DATE_MARK}.tgz"
    local TAR_ARGS
    if [ -n "$INCREMENTAL" ]
    then
        local INCREMENTAL_SNAPSHOT_FILE="$BACKUP_DIR/${RECENT_BACKUP_NAME}.inc-snapshot"
        local MAKE_FULL_BACKUP=0
        local LATEST_FULL_BACKUP="$(ls -1 --sort=time "$BACKUP_DIR/${RECENT_BACKUP_NAME}_"????????-??????".tgz" 2>/dev/null | head -1)"
        if [ -z "$LATEST_FULL_BACKUP" -o ! -f "$INCREMENTAL_SNAPSHOT_FILE" ]
        then
            MAKE_FULL_BACKUP=1
        elif [ "$INCREMENTAL" -gt "0" ]
        then
            local INC_COUNT="$(find "$BACKUP_DIR" -name "${RECENT_BACKUP_NAME}_????????-??????_inc.tgz" -type f -newer "$LATEST_FULL_BACKUP" | wc -l)"
            if [ "$INC_COUNT" -ge "$INCREMENTAL" ]
            then
                MAKE_FULL_BACKUP=1
            fi
        fi
        if ! (( "$MAKE_FULL_BACKUP" ))
        then
            RECENT_BACKUP_FILE="$BACKUP_DIR/${RECENT_BACKUP_NAME}_${DATE_MARK}_inc.tgz"
            INC_LEVEL=-1 # любое значение != 0
        fi
        TAR_ARGS="$TAR_ARGS --level=$INC_LEVEL --listed-incremental=$INCREMENTAL_SNAPSHOT_FILE"
    fi
    tar --create --gzip --file="$RECENT_BACKUP_FILE" --preserve-permissions \
        $TAR_ARGS --no-check-device --exclude-vcs --exclude-caches \
        --exclude-tag-under=.backupignore -C "$CHDIR" "$@"
}

# backup_mysql <database name>
backup_mysql() {
    local DATABASE="$1"
    RECENT_BACKUP_NAME="${DATABASE}_mysql"
    RECENT_BACKUP_FILE="$BACKUP_DIR/${DATABASE}_${DATE_MARK}.sql.gz"
    mysqldump --single-transaction "$DATABASE" | gzip > "$RECENT_BACKUP_FILE" || err "mysql dump failed ($@)"
}

# purge <items to keep>
purge() {
    [ -z "$RECENT_BACKUP_NAME" ] && err "purge command must follow by backup command"
    ls -1 --sort=time "$BACKUP_DIR/${RECENT_BACKUP_NAME}_*" 2>/dev/null | tail -n$(expr "$1" + 1) | xargs rm 2>/dev/null
}

# upload_ssh <ssh destination>
upload_ssh() {
    [ -z "$RECENT_BACKUP_FILE" ] && err "upload command must follow by backup command"
    scp -q "$RECENT_BACKUP_FILE" "$1" || err "ssh upload failed ($@)"
}

# upload_selectel <user name> <password> <bucket name>
upload_selectel() {
    [ -z "$RECENT_BACKUP_FILE" ] && err "upload command must follow by backup command"
    local ACCOUNT="${1%%_*}";
    local USER="${1#*_}"; shift
    local PASS="$1"; shift
    local BUCKET="$1"; shift
    [ -z "$SELECTEL_AUTH_TOKEN" ] \
        && SELECTEL_AUTH_TOKEN="$(curl -si https://api.selcdn.ru/auth/v1.0 -H "X-Auth-User: ${ACCOUNT}_${USER}" -H "X-Auth-Key: $PASS" | grep -i '^x-auth-token:' | awk '{print $2}' | tr -d "\r\n")"
    [ -z "$SELECTEL_AUTH_TOKEN" ] && err "Unable to get Selectel Auth Token"
    curl -s -XPUT -H "X-Auth-Token: $SELECTEL_AUTH_TOKEN" "https://api.selcdn.ru/v1/SEL_$ACCOUNT/$BUCKET/$(basename $RECENT_BACKUP_FILE)" -T "$RECENT_BACKUP_FILE"
}

# ----- private helpers

err() { echo "$@" >&2; exit 1; }

CONFIG_FILE="$BACKUP_DIR/.backup.conf"

[ -f "$CONFIG_FILE" ] || err "Unable to find scenario file in \"$BACKUP_DIR\" directory"

umask 0077

. "$CONFIG_FILE"
