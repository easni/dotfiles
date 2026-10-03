import QtQuick
import "../styles"
import "../core"

Text {
    id: date
    objectName: "calendarDate"

    color: Theme.textSecondary

    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: 11

    text: Qt.formatDate(new Date(), "ddd, MMM d")

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: IslandController.openCalendar()
    }

    Timer {
        interval: 60000
        running: true
        repeat: true

        onTriggered: {
            date.text = Qt.formatDate(new Date(), "ddd, MMM d")
        }
    }
}
