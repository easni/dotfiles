#!/usr/bin/env bash

set -euo pipefail

# Prevent macOS archive tools from creating AppleDouble (._*) sidecar files.
export COPYFILE_DISABLE=1

# Override either value for a one-off invocation, for example:
# SYNC_DIR="$HOME/other-folder" sync-pull.sh
SYNC_DIR="${SYNC_DIR:-$HOME/Documents/sync}"
SYNC_REMOTE="${SYNC_REMOTE:-git@github.com:easni/sync.git}"
SYNC_BRANCH="${SYNC_BRANCH:-main}"
SYNC_KEY_FILE="${SYNC_KEY_FILE:-$HOME/.config/folder-sync/key.txt}"
SYNC_STATE_FILE="${SYNC_STATE_FILE:-$HOME/.local/state/folder-sync/last-remote-commit}"
SYNC_BACKUP_DIR="${SYNC_BACKUP_DIR:-$HOME/.local/state/folder-sync/backups}"
SYNC_BACKUP_KEEP="${SYNC_BACKUP_KEEP:-5}"

die() {
  printf 'sync-pull: %s\n' "$*" >&2
  exit 1
}

command -v git >/dev/null 2>&1 || die "git is required"
command -v rsync >/dev/null 2>&1 || die "rsync is required"
command -v tar >/dev/null 2>&1 || die "tar is required"
command -v age >/dev/null 2>&1 || die "age 1.3.1 or newer is required"
[[ "$SYNC_BACKUP_KEEP" =~ ^[0-9]+$ ]] || die "SYNC_BACKUP_KEEP must be a non-negative integer"
[[ "$SYNC_DIR" != "/" && "$SYNC_DIR" != "$HOME" ]] || die "refusing unsafe folder: $SYNC_DIR"
[[ ! -e "$SYNC_DIR/.git" ]] || die "refusing to overwrite a Git working tree: $SYNC_DIR"
[[ -r "$SYNC_KEY_FILE" && -f "$SYNC_KEY_FILE" ]] || die "key file is missing or unreadable: $SYNC_KEY_FILE"

temporary_dir=$(mktemp -d "${TMPDIR:-/tmp}/sync-pull.XXXXXX")
trap 'rm -rf -- "$temporary_dir"' EXIT

# Download successfully before touching the destination. The trailing slashes
# make the contents of the repository become the contents of SYNC_DIR.
git clone --quiet --depth 1 --single-branch --branch "$SYNC_BRANCH" \
  "$SYNC_REMOTE" "$temporary_dir/repository"

snapshot_file="$temporary_dir/repository/snapshot.tar.gz.age"
[[ -f "$snapshot_file" ]] || die "remote does not contain an encrypted snapshot"

# Authenticate and decrypt fully in temporary storage before touching either
# the destination or its backups.
mkdir -p -- "$temporary_dir/extracted"
age --decrypt -i "$SYNC_KEY_FILE" "$snapshot_file" | \
  tar -xzf - -C "$temporary_dir/extracted"
pulled_commit=$(git -C "$temporary_dir/repository" rev-parse HEAD)

# Save the current local contents only after the remote snapshot has downloaded.
# Set SYNC_BACKUP_KEEP=0 to disable backups.
if (( SYNC_BACKUP_KEEP > 0 )) && [[ -d "$SYNC_DIR" ]]; then
  mkdir -p -- "$SYNC_BACKUP_DIR"
  backup_file="$SYNC_BACKUP_DIR/backup-$(date -u '+%Y%m%dT%H%M%SZ')-$$.tar.gz"
  tar -czf "$backup_file" -C "$SYNC_DIR" .

  shopt -s nullglob
  backups=("$SYNC_BACKUP_DIR"/backup-*.tar.gz)
  while (( ${#backups[@]} > SYNC_BACKUP_KEEP )); do
    rm -- "${backups[0]}"
    backups=("${backups[@]:1}")
  done
fi

mkdir -p -- "$SYNC_DIR"
rsync -a --delete --exclude='.git/' -- \
  "$temporary_dir/extracted/" "$SYNC_DIR/"

state_dir=$(dirname -- "$SYNC_STATE_FILE")
mkdir -p -- "$state_dir"
state_tmp=$(mktemp "$state_dir/.last-remote-commit.XXXXXX")
printf '%s\n' "$pulled_commit" > "$state_tmp"
mv -- "$state_tmp" "$SYNC_STATE_FILE"

printf 'Replaced %s with %s (%s).\n' "$SYNC_DIR" "$SYNC_REMOTE" "$SYNC_BRANCH"
