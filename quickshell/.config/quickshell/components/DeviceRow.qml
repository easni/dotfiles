import QtQuick
import QtQuick.Layouts
import "../styles"

Rectangle {
    id: root
    property string deviceName: ""
    property string symbol: "󰂯"
    property string detail: ""
    property string batteryText: ""
    property bool lowBattery: false
    property string error: ""
    property alias actions: actionFlow.data
    implicitHeight: content.implicitHeight + 28
    radius: 16
    color: Theme.surface
    border.width: 1
    border.color: Theme.borderSubtle
    ColumnLayout {
        id: content
        x: 14; y: 14
        width: parent.width - 28
        spacing: 10
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Rectangle {
                Layout.preferredWidth: 34; Layout.preferredHeight: 34
                radius: 11
                color: Theme.buttonBackground
                Text {
                    anchors.centerIn: parent
                    text: root.symbol
                    font.family: Theme.iconFont
                    font.pixelSize: 19
                    color: Theme.textPrimary
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3
                Text {
                    Layout.fillWidth: true
                    text: root.deviceName
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    font.pixelSize: 14; font.weight: Font.DemiBold
                    color: Theme.textPrimary
                }
                Text {
                    Layout.fillWidth: true
                    text: root.detail
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    font.pixelSize: 12
                    color: Theme.textSecondary
                }
            }
        }
        Text {
            visible: text !== ""
            Layout.fillWidth: true
            text: root.batteryText
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            font.pixelSize: 12
            color: root.lowBattery ? Theme.warning : Theme.textSecondary
        }
        Flow {
            id: actionFlow
            Layout.fillWidth: true
            spacing: 8
            visible: children.length > 0
        }
        Text {
            visible: text !== ""
            Layout.fillWidth: true
            text: root.error
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            font.pixelSize: 12
            color: Theme.warning
        }
    }
}
