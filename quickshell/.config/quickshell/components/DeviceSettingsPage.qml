import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../core"
import "../styles"

FocusScope {
    id: root
    required property string title
    default property alias pageContents: sections.data
    property var islandContext: IslandRegistry.contextFor(parent)
    required property real availableWidth
    required property real availableHeight
    implicitWidth: Math.min(520, availableWidth)
    implicitHeight: Math.min(layout.implicitHeight + 40, availableHeight)
    focus: true
    Component.onCompleted: forceActiveFocus()
    Keys.forwardTo: [escapeKey]
    EscapeKeyHandler {
        id: escapeKey
        onTriggered: root.islandContext.navigation.closeDevicePage()
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12
        RowLayout {
            NotificationButton {
                text: "‹"
                Accessible.name: "Back to Control Center"
                onClicked: root.islandContext.navigation.closeDevicePage()
            }
            Text {
                text: root.title
                Layout.fillWidth: true
                color: Theme.textPrimary
                font.pixelSize: 18
                font.weight: Font.DemiBold
            }
            NotificationButton {
                text: "×"
                Accessible.name: "Close " + root.title.toLowerCase() + " settings"
                onClicked: root.islandContext.navigation.reset()
            }
        }
        Flickable {
            id: scroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitHeight: sections.implicitHeight
            contentWidth: width
            contentHeight: sections.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar {}
            ColumnLayout {
                id: sections
                width: scroll.width
                spacing: 10
            }
        }
    }
}
