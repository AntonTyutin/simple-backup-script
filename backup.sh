#!/bin/bash

DATE_MARK="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$(readlink -f "${1:-$PWD}")"

err() { echo "$@" >&2; exit 1; }
tgz() {
    [ "$#" -lt 2 ] && err "Мало аргументов у tgz (chdir file_or_dir)"
    CHDIR="$1"
    shift
    TAR_NAME="$1"
    [ "$#" -gt 1 ] && shift
    BACKUP_FILE="$BACKUP_DIR/${TAR_NAME}_${DATE_MARK}.tgz"
    tar czf "$BACKUP_FILE" -C "$CHDIR" "$@" >/dev/null || err "Ошибка архивации $@"
}
dump() {
    DATABASE="$1"
    BACKUP_FILE="$BACKUP_DIR/${DATABASE}_${DATE_MARK}.sql.gz"
    mysqldump --single-transaction "$DATABASE" | gzip > "$BACKUP_FILE" || err "Ошибка дампа $@"
}
sync() {
    rsync -aq --delete "$BACKUP_DIR/" "$1" || err "Ошибка синхронизации бэкапа $@"
}
purge() {
    DAYS="$1"; shift
    find "$BACKUP_DIR" \( "$@" \) -ctime +"$DAYS" -delete
}

CONFIG_FILE="$BACKUP_DIR/.backup.conf"

[ -f "$CONFIG_FILE" ] || err "Файл конфигурации не найден в директории $BACKUP_DIR"

. "$CONFIG_FILE"

