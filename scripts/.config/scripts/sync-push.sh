#!/usr/bin/env bash

set -euo pipefail

# Override either value for a one-off invocation, for example:
# SYNC_DIR="$HOME/other-folder" sync-push.sh
SYNC_DIR="${SYNC_DIR:-$HOME/Documents/sync}"
SYNC_REMOTE="${SYNC_REMOTE:-git@github.com:easni/sync.git}"
SYNC_BRANCH="${SYNC_BRANCH:-main}"

die() {
  printf 'sync-push: %s\n' "$*" >&2
  exit 1
}

command -v git >/dev/null 2>&1 || die "git is required"
command -v rsync >/dev/null 2>&1 || die "rsync is required"
[[ -d "$SYNC_DIR" ]] || die "folder does not exist: $SYNC_DIR"
[[ "$SYNC_DIR" != "/" && "$SYNC_DIR" != "$HOME" ]] || die "refusing unsafe folder: $SYNC_DIR"
[[ ! -e "$SYNC_DIR/.git" ]] || die "refusing to snapshot a Git working tree: $SYNC_DIR"

temporary_dir=$(mktemp -d "${TMPDIR:-/tmp}/sync-push.XXXXXX")
trap 'rm -rf -- "$temporary_dir"' EXIT

# Build the commit in a temporary repository, leaving the synced folder clean.
rsync -a -- "$SYNC_DIR/" "$temporary_dir/repository/"
cd "$temporary_dir/repository"
git init --quiet
git symbolic-ref HEAD "refs/heads/$SYNC_BRANCH"

# Use the user's Git identity when available, with a local fallback.
git config user.name >/dev/null 2>&1 || git config user.name "Folder Sync"
git config user.email >/dev/null 2>&1 || git config user.email "folder-sync@localhost"

git add --all
git commit --quiet --allow-empty -m "Snapshot $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
git remote add origin "$SYNC_REMOTE"
git push --force origin "HEAD:refs/heads/$SYNC_BRANCH"

printf 'Published %s to %s (%s).\n' "$SYNC_DIR" "$SYNC_REMOTE" "$SYNC_BRANCH"
