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

    property string _trackIdentity: ""
    property bool _usingSyntheticPosition: false
    property real _syntheticPositionStart: 0
    property double _syntheticPositionStartedAt: 0

    property url icon: Qt.resolvedUrl("../assets/icons/music.svg")

    property string subtitle:
        hasPlayer
            ? title
            : "Nothing Playing"

    readonly property bool hasPlayer: player !== null

    readonly property int playbackPlaying: 1
    readonly property int playbackPaused: 2

    function trackIdentityFor(player) {

        if (!player)
            return ""

        return [
            player.trackTitle,
            player.trackArtist
        ].join("\n")
    }

    function resetTimingIfTrackChanged() {

        let nextTrackIdentity = trackIdentityFor(player)

        if (nextTrackIdentity === _trackIdentity)
            return

        _trackIdentity = nextTrackIdentity
        resetTrackTiming()
    }

    function resetTrackTiming() {

        position = 0
        length = 0
        _usingSyntheticPosition = true
        _syntheticPositionStart = 0
        _syntheticPositionStartedAt = Date.now()
    }

    function syntheticPosition() {

        if (!_usingSyntheticPosition)
            return position

        if (!isPlaying)
            return _syntheticPositionStart

        return _syntheticPositionStart +
            ((Date.now() - _syntheticPositionStartedAt) / 1000)
    }

    function updatePosition(rawPosition) {

        let reportedPosition = Math.max(0, rawPosition || 0)

        if (!_usingSyntheticPosition) {
            position = reportedPosition
            return
        }

        let localPosition = syntheticPosition()
        let plausiblePosition =
            reportedPosition <= Math.max(10, localPosition + 4) &&
            (length <= 0 || reportedPosition <= length + 2)

        if (plausiblePosition) {
            _usingSyntheticPosition = false
            position = reportedPosition
            return
        }

        position = Math.floor(localPosition)
    }

    function updateLength(rawLength) {

        // Quickshell falls back to position when the player has no duration.
        length = player && player.lengthSupported &&
            Number.isFinite(rawLength) && rawLength > 0 ? rawLength : 0
    }

    function updatePlayer() {

        if (Mpris.players.values.length === 0) {

            player = null
            _trackIdentity = ""
            _usingSyntheticPosition = false

            title = ""
            artist = ""
            artUrl = ""

            isPlaying = false
            position = 0
            length = 0

            return
        }

        if (player !== Mpris.players.values[0]) {
            player = Mpris.players.values[0]
            _trackIdentity = ""
            resetTrackTiming()
        }

        resetTimingIfTrackChanged()

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
            root.resetTimingIfTrackChanged()
            root.updateLength(player.length)
        }

        function onTrackArtistChanged() {
            root.artist = player.trackArtist
            root.resetTimingIfTrackChanged()
            root.updateLength(player.length)
        }

        function onTrackArtUrlChanged() {

            if (player.trackArtUrl !== "")
                root.artUrl = player.trackArtUrl
        }

        function onPlaybackStateChanged() {
            let wasPlaying = root.isPlaying

            root.isPlaying =
                player.playbackState === root.playbackPlaying

            if (!root._usingSyntheticPosition || wasPlaying === root.isPlaying)
                return

            root._syntheticPositionStart = root.syntheticPosition()
            root._syntheticPositionStartedAt = Date.now()
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
