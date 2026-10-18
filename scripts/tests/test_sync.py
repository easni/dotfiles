"""Exercise real sync tools against disposable local repositories and keys.

Run with: python3 -m unittest discover -s scripts/tests -v
Requires bash, git, tar, rsync, age, and age-keygen on PATH.
"""

import os
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile
import unittest


SCRIPTS = Path(__file__).resolve().parents[1] / ".config" / "scripts"
METADATA = (".DS_Store", ".ds_store", "._document.txt")


class SyncTests(unittest.TestCase):
    def setUp(self):
        for tool in ("bash", "git", "tar", "rsync", "age", "age-keygen"):
            if not shutil.which(tool):
                self.skipTest(f"{tool} is required")
        temporary = tempfile.TemporaryDirectory(prefix="sync-test-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.source = self.root / "source"
        self.destination = self.root / "destination"
        self.remote = self.root / "remote.git"
        self.state = self.root / "state" / "last-remote-commit"
        self.backups = self.root / "backups"
        self.key = self.root / "key.txt"
        self.env = os.environ.copy()
        for name in tuple(self.env):
            if name.startswith(("SYNC_", "GIT_")) or name == "IGNORE_LOCK_FILES":
                del self.env[name]
        self.env.update(
            HOME=str(self.root / "home"),
            GIT_CONFIG_NOSYSTEM="1",
            GIT_CONFIG_GLOBAL=os.devnull,
            GIT_AUTHOR_NAME="Sync Test",
            GIT_AUTHOR_EMAIL="sync-test@example.invalid",
            GIT_COMMITTER_NAME="Sync Test",
            GIT_COMMITTER_EMAIL="sync-test@example.invalid",
            COPYFILE_DISABLE="1",
            SYNC_REMOTE=self.remote.as_uri(),
            SYNC_KEY_FILE=str(self.key),
            SYNC_STATE_FILE=str(self.state),
            SYNC_BACKUP_DIR=str(self.backups),
        )
        Path(self.env["HOME"]).mkdir()
        self.source.mkdir()
        self.destination.mkdir()
        self.run_tool("git", "init", "--quiet", "--bare", self.remote)
        self.run_tool("age-keygen", "-o", self.key)

    def run_tool(self, *args, env=None, succeeds=True):
        result = subprocess.run(
            [str(arg) for arg in args],
            env=self.env | (env or {}),
            text=True,
            capture_output=True,
        )
        if succeeds:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def sync(self, direction, directory, *, succeeds=True, **env):
        return self.run_tool(
            "bash", SCRIPTS / f"sync-{direction}.sh",
            env={"SYNC_DIR": str(directory), **env}, succeeds=succeeds,
        )

    def populate(self, directory):
        nested = directory / "folder with spaces" / "nested"
        nested.mkdir(parents=True)
        for parent in (directory, nested):
            # Exercise both spellings even on a case-insensitive filesystem.
            metadata = METADATA if parent == directory else tuple(reversed(METADATA))
            for name in (*metadata, "document.txt", ".notes", ".DS_Store.txt"):
                (parent / name).write_text(f"contents of {name}\n")
        (directory / "document link").symlink_to("document.txt")

    def assert_clean_archive(self, archive):
        with tarfile.open(archive) as snapshot:
            names = {Path(member.name).as_posix() for member in snapshot}
        self.assertTrue({"document.txt", ".notes", ".DS_Store.txt", "document link"} <= names)
        self.assertIn("folder with spaces/nested/document.txt", names)
        self.assertFalse(
            [name for name in names if Path(name).name in METADATA], names
        )

    def publish_legacy_snapshot(self, corrupt=False):
        """Simulate an older client that archived metadata without filtering."""
        repository = self.root / "legacy"
        repository.mkdir()
        archive = self.root / "legacy.tar.gz"
        self.run_tool("tar", "-czf", archive, "-C", self.source, ".")
        encrypted = repository / "snapshot.tar.gz.age"
        if corrupt:
            encrypted.write_text("not an encrypted archive\n")
        else:
            self.run_tool("age", "--encrypt", "-i", self.key, "-o", encrypted, archive)
        self.run_tool("git", "-C", repository, "init", "--quiet")
        self.run_tool("git", "-C", repository, "symbolic-ref", "HEAD", "refs/heads/main")
        self.run_tool("git", "-C", repository, "add", "--all")
        self.run_tool("git", "-C", repository, "commit", "--quiet", "-m", "Legacy snapshot")
        self.run_tool("git", "-C", repository, "push", "--quiet", self.remote, "HEAD:main")

    def test_push_filters_metadata_and_preserves_sync_guards(self):
        self.populate(self.source)
        self.sync("push", self.source, SYNC_FORCE="1")
        repository = self.root / "download"
        self.run_tool("git", "clone", "--quiet", "--branch", "main", self.remote, repository)
        archive = self.root / "snapshot.tar.gz"
        self.run_tool("age", "--decrypt", "-i", self.key, "-o", archive,
                      repository / "snapshot.tar.gz.age")
        self.assert_clean_archive(archive)
        for name in METADATA:
            self.assertTrue((self.source / name).exists())

        self.sync("push", self.source)
        current_state = self.state.read_text()
        (self.source / "~$document.txt").write_text("open document")
        result = self.sync("push", self.source, succeeds=False)
        self.assertIn("lock or temporary files found", result.stderr)
        self.assertEqual(self.state.read_text(), current_state)
        self.sync("push", self.source, IGNORE_LOCK_FILES="1")
        (self.source / "~$document.txt").unlink()
        self.state.write_text(current_state)
        result = self.sync("push", self.source, succeeds=False)
        self.assertIn("remote changed since your last sync", result.stderr)

    def test_pull_filters_legacy_metadata_and_backups(self):
        self.populate(self.source)
        self.populate(self.destination)
        (self.destination / "document.txt").write_text("local document")
        (self.destination / "obsolete.txt").write_text("obsolete")
        for name in METADATA:
            (self.destination / name).write_text("local metadata")
            (self.destination / "folder with spaces" / "nested" / name).unlink(missing_ok=True)
        self.publish_legacy_snapshot()
        self.sync("pull", self.destination)
        self.assertEqual((self.destination / "document.txt").read_text(),
                         (self.source / "document.txt").read_text())
        self.assertFalse((self.destination / "obsolete.txt").exists())
        self.assertTrue((self.destination / "document link").is_symlink())
        for name in METADATA:
            self.assertEqual((self.destination / name).read_text(), "local metadata")
            self.assertFalse((self.destination / "folder with spaces" / "nested" / name).exists())
        backups = list(self.backups.glob("backup-*.tar.gz"))
        self.assertEqual(len(backups), 1)
        self.assert_clean_archive(backups[0])
        with tarfile.open(backups[0]) as backup:
            self.assertEqual(backup.extractfile("./document.txt").read(), b"local document")
        self.assertTrue(self.state.is_file())

    def test_failed_decryption_preserves_destination_backups_and_state(self):
        self.populate(self.destination)
        self.state.parent.mkdir()
        self.state.write_text("previous state")
        self.backups.mkdir()
        (self.backups / "backup-existing.tar.gz").write_text("existing backup")
        self.publish_legacy_snapshot(corrupt=True)
        self.sync("pull", self.destination, succeeds=False)
        self.assertEqual((self.destination / "document.txt").read_text(), "contents of document.txt\n")
        self.assertEqual(self.state.read_text(), "previous state")
        self.assertEqual([path.name for path in self.backups.iterdir()], ["backup-existing.tar.gz"])


if __name__ == "__main__":
    unittest.main()
