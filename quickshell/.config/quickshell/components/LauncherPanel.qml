pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../styles"
import "../core"

FocusScope {
    id: root
    objectName: "launcherPanel"
    property string title: ""
    property string placeholder: ""
    property string actionLabel: "Open"
    property bool clipboard: false
    property bool loading: false
    property bool busy: false
    property string error: ""
    property string emptyText: "No results"
    property var results: []
    property real availableWidth: 560
    property real availableHeight: 480
    readonly property string query: search.text
    property int selectedIndex: results.length ? 0 : -1
    signal activate(string entryId)

    implicitWidth: Math.max(1, Math.min(560, availableWidth))
    implicitHeight: Math.max(1, Math.min(480, availableHeight))
    focus: true
    onResultsChanged: selectedIndex = results.length ? 0 : -1
    onSelectedIndexChanged: { if (list) list.positionViewAtIndex(selectedIndex, ListView.Contain) }
    Component.onCompleted: Qt.callLater(function() { search.forceActiveFocus() })

    function moveSelection(delta) {
        if (!results.length || loading || busy) return
        selectedIndex = Math.max(0, Math.min(results.length - 1, selectedIndex + delta))
    }
    function activateSelection() {
        if (busy || loading || selectedIndex < 0 || selectedIndex >= results.length) return
        activate(results[selectedIndex].id)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 10
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: root.title
                color: Theme.textPrimary
                font.pixelSize: 18
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }
            Text {
                text: root.loading ? "Loading…" : root.results.length + (root.clipboard ? " entries" : " apps")
                color: Theme.textMuted
                font.pixelSize: 11
            }
            NotificationButton {
                text: "×"
                subtle: true
                Accessible.name: "Close " + root.title
                onClicked: LauncherController.close()
            }
        }
        TextField {
            id: search
            objectName: "launcherSearch"
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            placeholderText: root.placeholder
            placeholderTextColor: Theme.textMuted
            color: Theme.textPrimary
            selectionColor: Theme.accent
            selectedTextColor: Theme.background
            font.pixelSize: 14
            leftPadding: 14
            rightPadding: 14
            selectByMouse: true
            background: Rectangle {
                radius: Theme.radiusMedium
                color: Theme.surface
                border.width: 1
                border.color: search.activeFocus ? Theme.accent : Theme.border
            }
            Keys.priority: Keys.BeforeItem
            Keys.onPressed: event => {
                const ctrl = event.modifiers & Qt.ControlModifier
                if (event.key === Qt.Key_Escape) LauncherController.close()
                else if (ctrl && event.key === Qt.Key_W) {
                    if (search.selectionStart !== search.selectionEnd) {
                        search.remove(search.selectionStart, search.selectionEnd)
                    } else {
                        const end = search.cursorPosition
                        const start = search.text.slice(0, end).replace(/\S+\s*$|\s+$/, "").length
                        search.remove(start, end)
                    }
                }
                else if (event.key === Qt.Key_Down || (ctrl && event.key === Qt.Key_N)) root.moveSelection(1)
                else if (event.key === Qt.Key_Up || (ctrl && event.key === Qt.Key_P)) root.moveSelection(-1)
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.activateSelection()
                else { event.accepted = false; return }
                event.accepted = true
            }
        }
        Text {
            Layout.fillWidth: true
            visible: root.error !== ""
            text: root.error
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            color: Theme.warning
            font.pixelSize: 12
        }
        ListView {
            id: list
            objectName: "launcherResults"
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            model: root.results
            currentIndex: root.selectedIndex
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar {}
            delegate: LauncherResult {
                required property var modelData
                required property int index
                entry: modelData
                width: list.width
                selected: index === root.selectedIndex
                clipboard: root.clipboard
                enabled: !root.busy && !root.loading
                onClicked: {
                    root.selectedIndex = index
                    root.activateSelection()
                }
            }
            Text {
                anchors.centerIn: parent
                width: Math.max(0, parent.width - 24)
                horizontalAlignment: Text.AlignHCenter
                visible: root.loading || root.results.length === 0
                text: root.loading ? "Loading history…" : root.emptyText
                color: Theme.textMuted
                font.pixelSize: 13
                wrapMode: Text.Wrap
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: "↑↓  Navigate     ↵  " + root.actionLabel + "     Esc  Close"
                color: Theme.textMuted
                font.pixelSize: 10
                elide: Text.ElideRight
            }
            Text {
                visible: root.busy
                text: root.clipboard ? "Copying…" : "Launching…"
                color: Theme.accent
                font.pixelSize: 11
            }
        }
    }
}
