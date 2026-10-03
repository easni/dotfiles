pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    property var player: null

    property string title: ""
    property string artist: ""
    property string artUrl: ""

    property bool isPlaying: false

    property int position: 0
    property int length: 0

    property url icon: Qt.resolvedUrl("../assets/icons/music.svg")

    property string subtitle:
        hasPlayer
            ? title
            : "Nothing Playing"

    readonly property bool hasPlayer: player !== null

    readonly property int playbackPlaying: 1
    readonly property int playbackPaused: 2

    function updatePosition(rawPosition) {
        position = Number.isFinite(rawPosition) ? Math.max(0, Math.floor(rawPosition)) : 0
    }

    function updateLength(rawLength) {

        // Quickshell falls back to position when the player has no duration.
        length = player && player.lengthSupported &&
            Number.isFinite(rawLength) && rawLength > 0 ? rawLength : 0
    }

    function updatePlayer() {

        if (Mpris.players.values.length === 0) {

            player = null

            title = ""
            artist = ""
            artUrl = ""

            isPlaying = false
            position = 0
            length = 0

            return
        }

        player = Mpris.players.values[0]

        title = player.trackTitle
        artist = player.trackArtist

        // Keep the last valid artwork.
        if (player.trackArtUrl !== "")
            artUrl = player.trackArtUrl

        isPlaying = player.playbackState === playbackPlaying

        updatePosition(player.position)
        updateLength(player.length)
    }

    function formatTime(seconds) {

        if (!seconds || seconds < 0)
            return "0:00"

        let minutes = Math.floor(seconds / 60)
        let secs = Math.floor(seconds % 60)

        return minutes + ":" + (secs < 10 ? "0" + secs : secs)
    }

    function togglePlayback() {

        if (!player)
            return

        player.togglePlaying()
    }

    function nextTrack() {

        if (!player)
            return

        player.next()
    }

    function previousTrack() {

        if (!player)
            return

        player.previous()
    }

    Timer {
        interval: 1000
        repeat: true
        running: true

        onTriggered: root.updatePlayer()
    }

    Connections {

        target: player

        function onTrackTitleChanged() {
            root.title = player.trackTitle
            root.updateLength(player.length)
        }

        function onTrackArtistChanged() {
            root.artist = player.trackArtist
            root.updateLength(player.length)
        }

        function onTrackArtUrlChanged() {

            if (player.trackArtUrl !== "")
                root.artUrl = player.trackArtUrl
        }

        function onPlaybackStateChanged() {
            root.isPlaying =
                player.playbackState === root.playbackPlaying
        }

        function onPositionChanged() {
            root.updatePosition(player.position)
        }

        function onLengthChanged() {

            if (!player)
                return

            root.updateLength(player.length)
        }

        function onLengthSupportedChanged() {
            root.updateLength(player.length)
        }
    }

    Component.onCompleted: updatePlayer()
}
