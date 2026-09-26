import QtQuick
import Qt.labs.folderlistmodel
import QtQuick.Controls 2.15

import "../components"
import "../core"
import "../services"
import "../styles"

FocusScope {
    id: root

    property real availableWidth: 560
    property real availableHeight: 480
    implicitWidth: Math.min(560, availableWidth)
    implicitHeight: Math.min(480, availableHeight)

    focus: true

    property int selectedIndex: 0
    readonly property int columns: Math.max(1, Math.min(3, Math.floor((width - 40) / 150)))

    Component.onCompleted: {
        for (let i = 0; i < ThemeService.themes.count; ++i)
            if (ThemeService.themes.get(i).themeId === ThemeService.currentTheme) selectedIndex = i
        forceActiveFocus()
    }
    onSelectedIndexChanged: themeView.positionViewAtIndex(selectedIndex, GridView.Contain)

    Column {

        anchors.fill: parent
        anchors.margins: 20

        spacing: 10

        Item {

            width: parent.width
            height: 30

            Text {

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                text: "Themes"

                font.pixelSize: 20

                color: Theme.textPrimary
            }

            Text {

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                text: ThemeService.themes.count + " Themes"

                font.pixelSize: 13

                color: Theme.textSecondary
            }
        }

        GridView {

            id: themeView

            width: parent.width
            height: Math.max(0, root.height - 80)


            clip: true

            interactive: true

            boundsBehavior: Flickable.StopAtBounds

            cellWidth: width / root.columns
            cellHeight: 116

            model: ThemeService.themes

            currentIndex: root.selectedIndex

            delegate: Item {

                width: themeView.cellWidth
                height: themeView.cellHeight


                ThemeCard {

                    anchors.fill: parent

                    anchors.margins: 8

                    themeId: model.themeId

                    themeName: model.name

                    backgroundColor: model.background

                    color1: model.color1
                    color2: model.color2
                    color3: model.color3

                    accentColor: model.accent

                    textColor: model.text

                    selected: index === themeView.currentIndex
                }


                MouseArea {

                    anchors.fill: parent

                    cursorShape: Qt.PointingHandCursor

                    onClicked: {

                        root.selectedIndex = index

                        ThemeService.apply(model.themeId)

                    }
                }
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }
        }
    }

    Keys.onPressed: function(event) {

        switch (event.key) {

        case Qt.Key_Left:
        case Qt.Key_H:

            if (selectedIndex % columns > 0)
                selectedIndex--

            event.accepted = true
            break


        case Qt.Key_Right:
        case Qt.Key_L:

            if (selectedIndex % columns < columns - 1 &&
                selectedIndex < ThemeService.themes.count - 1)

                selectedIndex++

            event.accepted = true
            break


        case Qt.Key_Up:
        case Qt.Key_K:

            if (selectedIndex - columns >= 0)
                selectedIndex -= columns

            event.accepted = true
            break


        case Qt.Key_Down:
        case Qt.Key_J:

            if (selectedIndex + columns < ThemeService.themes.count)
                selectedIndex += columns

            event.accepted = true
            break


        case Qt.Key_Return:
        case Qt.Key_Enter:

            ThemeService.apply(
                ThemeService.themes.get(selectedIndex).themeId
            )

            event.accepted = true
            break


        case Qt.Key_Escape:

            IslandController.reset()

            event.accepted = true
            break
        }
    }
}
