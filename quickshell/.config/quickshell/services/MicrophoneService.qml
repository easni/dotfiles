pragma Singleton
import QtQuick
import Quickshell.Services.Pipewire

EndpointVolume {
    id: root
    endpoint: "@DEFAULT_AUDIO_SOURCE@"
    readonly property url icon: muted ? "../assets/icons/microphone-off.svg" : "../assets/icons/microphone.svg"
    readonly property string subtitle: !Pipewire.defaultAudioSource ? "Unavailable" : muted ? "Muted" : "Enabled"
    function toggle() { toggleMute() }
    Connections {
        target: Pipewire
        function onDefaultAudioSourceChanged() { root.defaultChanged() }
    }
}
