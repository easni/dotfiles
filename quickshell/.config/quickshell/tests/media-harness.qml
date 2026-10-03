import QtQuick
import QtTest
import Quickshell
import "../components"
import "../services"

ShellRoot {
    FloatingWindow {
        visible: true
        implicitWidth: 400
        implicitHeight: 100
        SongInfo {
            id: song
            showCava: false
            titleWidth: 100
            artistWidth: 100
        }
        SongInfo {
            id: alignedSong
            x: 200
        }
    }

    TestCase {
        id: checks
        name: "Media"
        when: false

        function runChecks() {
            const verify = value => { if (!value) throw new Error("Verification failed") }
            const compare = (actual, expected) => {
                if (actual !== expected)
                    throw new Error("Expected " + expected + ", got " + actual)
            }
            const alignedTitleRow = alignedSong.children[0]
            const alignedTitle = alignedTitleRow.children[1]
            const alignedArtist = alignedSong.children[1]
            const visualizer = alignedTitleRow.children[0]
            visualizer.visible = true
            wait(50)
            compare(alignedTitle.x + alignedTitle.width, alignedArtist.width)
            visualizer.visible = false
            wait(50)
            compare(alignedTitle.x + alignedTitle.width, alignedArtist.width)
            const title = song.children[0].children[1]
            const artist = song.children[1]
            title.text = "A much longer title that will take more time"
            artist.text = "A shorter artist name"
            wait(100)
            verify(title.scrollDuration > artist.scrollDuration)
            verify(artist.scrollDuration > 0)
            compare(song.scrollElapsed, 0)
            wait(1500)
            compare(song.scrollElapsed, 0)
            wait(650)
            verify(song.scrollElapsed > 0)
            compare(title.elapsed, artist.elapsed)
            compare(title.textOffset, artist.textOffset)

            // Freeze the cycle to inspect both lines at exact shared times.
            song.visible = false
            wait(50)
            song.scrollElapsed = artist.scrollDuration + 50
            compare(artist.textOffset, 0)
            verify(title.textOffset !== 0)
            song.scrollElapsed = song.scrollDuration
            compare(title.textOffset, 0)
            compare(artist.textOffset, 0)

            song.visible = true
            wait(50)
            compare(song.scrollElapsed, 0)
            wait(2100)
            verify(song.scrollElapsed > 0)
            artist.text = "Changed artist metadata"
            wait(50)
            compare(song.scrollElapsed, 0)
            compare(title.textOffset, 0)
            compare(artist.textOffset, 0)

            title.text = "Short"
            artist.text = "Short"
            wait(50)
            compare(song.scrollDuration, 0)
            compare(song.scrollElapsed, 0)

            MediaService.updatePosition(123.8)
            compare(MediaService.position, 123)
            MediaService.updatePosition(480)
            compare(MediaService.position, 480)
            MediaService.updatePosition(3)
            compare(MediaService.position, 3)
            MediaService.updateLength(300)
            compare(MediaService.length, 0)
            console.log("PASS direct position, missing duration, and synchronized text cycles")
        }
    }

    Timer {
        interval: 100
        running: true
        onTriggered: {
            try {
                checks.runChecks()
            } finally {
                Qt.quit()
            }
        }
    }
}
