#!/usr/bin/env bash

set -euo pipefail

# Prevent macOS archive tools from creating AppleDouble (._*) sidecar files.
export COPYFILE_DISABLE=1

SYNC_DIR="${SYNC_DIR:-$HOME/Documents/sync}"
SYNC_BACKUP_DIR="${SYNC_BACKUP_DIR:-$HOME/.local/state/folder-sync/backups}"

die() {
  printf 'sync-rewind: %s\n' "$*" >&2
  exit 1
}

usage() {
  printf 'Usage:\n'
  printf '  syncrewind list\n'
  printf '  syncrewind restore -p BACKUP_FILE\n'
  printf '  syncrewind restore -i BACKUP_NUMBER\n'
  printf '\n'
  printf 'Commands:\n'
  printf '  list                Show backups, newest first.\n'
  printf '  restore -p PATH     Restore a backup by its path.\n'
  printf '  restore -i NUMBER   Restore a backup by its number from the list.\n'
}

load_backups() {
  shopt -s nullglob
  backups=("$SYNC_BACKUP_DIR"/backup-*.tar.gz)
  (( ${#backups[@]} > 0 )) || die "no backups found in $SYNC_BACKUP_DIR"
}

if (( $# == 0 )); then
  usage
  exit 0
fi

if [[ "$1" == "list" && $# == 1 ]]; then
  load_backups
  backup_number=1
  for (( backup_index=${#backups[@]} - 1; backup_index >= 0; backup_index-- )); do
    printf '%d  %s\n' "$backup_number" "${backups[backup_index]}"
    (( backup_number++ ))
  done
  exit 0
fi

if [[ "$1" != "restore" || $# != 3 ]]; then
  usage >&2
  exit 2
fi

case "$2" in
  -p)
    backup_file=$3
    ;;
  -i)
    [[ "$3" =~ ^[1-9][0-9]*$ ]] || die "backup number must be a positive integer"
    backup_number=$((10#$3))
    load_backups
    (( backup_number <= ${#backups[@]} )) || die "backup number $3 does not exist; run syncrewind list"
    backup_index=$((${#backups[@]} - backup_number))
    backup_file=${backups[backup_index]}
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

command -v rsync >/dev/null 2>&1 || die "rsync is required"
command -v tar >/dev/null 2>&1 || die "tar is required"
[[ "$SYNC_DIR" != "/" && "$SYNC_DIR" != "$HOME" ]] || die "refusing unsafe folder: $SYNC_DIR"
[[ ! -e "$SYNC_DIR/.git" ]] || die "refusing to overwrite a Git working tree: $SYNC_DIR"
[[ -r "$backup_file" && -f "$backup_file" ]] || die "backup is missing or unreadable: $backup_file"

temporary_dir=$(mktemp -d "${TMPDIR:-/tmp}/sync-rewind.XXXXXX")
trap 'rm -rf -- "$temporary_dir"' EXIT

mkdir -p -- "$temporary_dir/extracted"
tar -xzf "$backup_file" -C "$temporary_dir/extracted"

mkdir -p -- "$SYNC_DIR"
rsync -a --delete --exclude='.git/' -- \
  "$temporary_dir/extracted/" "$SYNC_DIR/"

printf 'Restored %s from %s.\n' "$SYNC_DIR" "$backup_file"
