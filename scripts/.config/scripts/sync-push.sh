#!/usr/bin/env bash

set -euo pipefail

# Override either value for a one-off invocation, for example:
# SYNC_DIR="$HOME/other-folder" sync-push.sh
SYNC_DIR="${SYNC_DIR:-$HOME/Documents/sync}"
SYNC_REMOTE="${SYNC_REMOTE:-git@github.com:easni/sync.git}"
SYNC_BRANCH="${SYNC_BRANCH:-main}"
SYNC_KEY_FILE="${SYNC_KEY_FILE:-$HOME/.config/folder-sync/key.txt}"
SYNC_STATE_FILE="${SYNC_STATE_FILE:-$HOME/.local/state/folder-sync/last-remote-commit}"
SYNC_FORCE="${SYNC_FORCE:-0}"

die() {
  printf 'sync-push: %s\n' "$*" >&2
  exit 1
}

command -v git >/dev/null 2>&1 || die "git is required"
command -v tar >/dev/null 2>&1 || die "tar is required"
command -v age >/dev/null 2>&1 || die "age 1.3.1 or newer is required"
[[ -d "$SYNC_DIR" ]] || die "folder does not exist: $SYNC_DIR"
[[ "$SYNC_DIR" != "/" && "$SYNC_DIR" != "$HOME" ]] || die "refusing unsafe folder: $SYNC_DIR"
[[ ! -e "$SYNC_DIR/.git" ]] || die "refusing to snapshot a Git working tree: $SYNC_DIR"
[[ -r "$SYNC_KEY_FILE" && -f "$SYNC_KEY_FILE" ]] || die "key file is missing or unreadable: $SYNC_KEY_FILE"
[[ "$SYNC_FORCE" == "0" || "$SYNC_FORCE" == "1" ]] || die "SYNC_FORCE must be 0 or 1"

remote_ref="refs/heads/$SYNC_BRANCH"
remote_line=$(git ls-remote "$SYNC_REMOTE" "$remote_ref") || die "could not read remote branch"
read -r remote_commit _ <<< "$remote_line"

if [[ "$SYNC_FORCE" != "1" ]]; then
  [[ -n "$remote_commit" ]] || die "remote branch is missing; use SYNC_FORCE=1 for an intentional first push"
  [[ -r "$SYNC_STATE_FILE" && -f "$SYNC_STATE_FILE" ]] || die "no sync state found; pull first, or use SYNC_FORCE=1 to overwrite intentionally"
  expected_commit=$(< "$SYNC_STATE_FILE")
  [[ "$expected_commit" == "$remote_commit" ]] || die "remote changed since your last sync; run syncpull first, or use SYNC_FORCE=1 syncpush to intentionally replace the remote version"
fi

temporary_dir=$(mktemp -d "${TMPDIR:-/tmp}/sync-push.XXXXXX")
trap 'rm -rf -- "$temporary_dir"' EXIT

# Build an encrypted archive in a temporary repository, leaving the synced
# folder clean and hiding both its contents and filenames from the remote.
mkdir -p -- "$temporary_dir/repository"
tar -czf - -C "$SYNC_DIR" . | \
  age --encrypt -i "$SYNC_KEY_FILE" \
    -o "$temporary_dir/repository/snapshot.tar.gz.age"
cd "$temporary_dir/repository"
git init --quiet
git symbolic-ref HEAD "refs/heads/$SYNC_BRANCH"

# Use the user's Git identity when available, with a local fallback.
git config user.name >/dev/null 2>&1 || git config user.name "Folder Sync"
git config user.email >/dev/null 2>&1 || git config user.email "folder-sync@localhost"

git add --all
git commit --quiet --allow-empty -m "Snapshot $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
git remote add origin "$SYNC_REMOTE"

published_commit=$(git rev-parse HEAD)
if [[ "$SYNC_FORCE" == "1" ]]; then
  git push --force origin "HEAD:$remote_ref"
else
  git push --force-with-lease="$remote_ref:$remote_commit" origin "HEAD:$remote_ref"
fi

state_dir=$(dirname -- "$SYNC_STATE_FILE")
mkdir -p -- "$state_dir"
state_tmp=$(mktemp "$state_dir/.last-remote-commit.XXXXXX")
printf '%s\n' "$published_commit" > "$state_tmp"
mv -- "$state_tmp" "$SYNC_STATE_FILE"

printf 'Published %s to %s (%s).\n' "$SYNC_DIR" "$SYNC_REMOTE" "$SYNC_BRANCH"
