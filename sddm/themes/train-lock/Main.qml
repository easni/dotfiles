import QtQuick 2.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#11111b"

    property int sessionIndex: sessionPicker.index
    property string username: userModel.lastUser
    property string foreground: config.foreground || "#cdd6f4"
    property string mutedForeground: config.mutedForeground || "#bfc1c3"
    property string fontFamily: config.fontFamily || "JetBrainsMono Nerd Font"

    function tryLogin() {
        errorMessage.text = ""
        sddm.login(username, password.text, sessionIndex)
    }

    Connections {
        target: sddm

        function onLoginFailed() {
            password.text = ""
            errorMessage.text = "That password didn't work"
            password.forceActiveFocus()
        }

        function onInformationMessage(message) {
            errorMessage.text = message
        }
    }

    Image {
        anchors.fill: parent
        source: config.background || "background.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    Rectangle {
        anchors.fill: parent
        color: "#80000000"
    }

    Text {
        id: dateLabel
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -230
        color: mutedForeground
        text: Qt.formatDateTime(new Date(), "dddd, MMMM dd")
        font.family: fontFamily
        font.pixelSize: 38
    }

    Text {
        id: timeLabel
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -130
        color: mutedForeground
        text: Qt.formatDateTime(new Date(), "HH:mm")
        font.family: fontFamily
        font.pixelSize: 162
        font.weight: Font.ExtraBold
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var now = new Date()
            dateLabel.text = Qt.formatDateTime(now, "dddd, MMMM dd")
            timeLabel.text = Qt.formatDateTime(now, "HH:mm")
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 110
        color: foreground
        text: "Hi there, " + username
        font.family: fontFamily
        font.pixelSize: 20
    }

    Rectangle {
        id: passwordField
        width: 250
        height: 60
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 166
        radius: height / 2
        color: "#33000000"
        border.width: password.activeFocus ? 2 : 0
        border.color: foreground

        TextInput {
            id: password
            anchors.fill: parent
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            color: foreground
            selectionColor: "#6689b4fa"
            selectedTextColor: foreground
            echoMode: TextInput.Password
            passwordCharacter: "•"
            font.family: fontFamily
            font.pixelSize: 16
            horizontalAlignment: TextInput.AlignHCenter
            verticalAlignment: TextInput.AlignVCenter
            focus: true

            Keys.onReturnPressed: root.tryLogin()
            Keys.onEnterPressed: root.tryLogin()
        }

        Text {
            anchors.centerIn: parent
            visible: password.text.length === 0
            color: mutedForeground
            text: "Enter Password..."
            font.family: fontFamily
            font.pixelSize: 14
            font.italic: true
        }
    }

    Text {
        id: errorMessage
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: passwordField.bottom
        anchors.topMargin: 12
        color: "#f38ba8"
        font.family: fontFamily
        font.pixelSize: 14
    }

    Row {
        z: 100
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 24
        spacing: 12

        Rectangle {
            width: 170
            height: 34
            radius: height / 2
            color: "#33000000"
            border.width: usernameInput.activeFocus ? 2 : 1
            border.color: usernameInput.activeFocus ? foreground : mutedForeground

            TextInput {
                id: usernameInput
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                color: foreground
                text: root.username
                font.family: fontFamily
                font.pixelSize: 14
                horizontalAlignment: TextInput.AlignHCenter
                verticalAlignment: TextInput.AlignVCenter
                selectByMouse: true
                onTextChanged: root.username = text
                Keys.onReturnPressed: password.forceActiveFocus()
                Keys.onEnterPressed: password.forceActiveFocus()
            }
        }

        ComboBox {
            id: sessionPicker
            width: 190
            height: 34
            model: sessionModel
            index: sessionModel.lastIndex
            font.family: fontFamily
            font.pixelSize: 14
            color: "#33000000"
            menuColor: "#e611111b"
            textColor: foreground
            borderColor: mutedForeground
            focusColor: foreground
            hoverColor: "#6689b4fa"
        }

        Button {
            width: 100
            height: 34
            text: "Restart"
            font.family: fontFamily
            color: "#33000000"
            textColor: foreground
            activeColor: "#6689b4fa"
            pressedColor: "#9989b4fa"
            onClicked: sddm.reboot()
        }

        Button {
            width: 110
            height: 34
            text: "Shut down"
            font.family: fontFamily
            color: "#33000000"
            textColor: foreground
            activeColor: "#6689b4fa"
            pressedColor: "#9989b4fa"
            onClicked: sddm.powerOff()
        }
    }
}
