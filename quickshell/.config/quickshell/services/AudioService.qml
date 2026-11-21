pragma Singleton
import QtQuick
import Quickshell.Services.Pipewire

EndpointVolume {
    id: root
    endpoint: "@DEFAULT_AUDIO_SINK@"
    Connections {
        target: Pipewire
        function onDefaultAudioSinkChanged() { root.defaultChanged() }
    }
    readonly property url volumeIcon: {

        if (muted)
            return "../assets/icons/volume-off.svg"

        if (volume <= 5)
            return "../assets/icons/volume-0.svg"

        if (volume <= 40)
            return "../assets/icons/volume-1.svg"

        return "../assets/icons/volume-2.svg"
    }
}
