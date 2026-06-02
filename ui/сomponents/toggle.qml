import QtQuick

Rectangle {
    signal click(bool state)

    readonly property color bgInput: "#2C2C2C"
    readonly property color accent:  "#29B6F6"
    readonly property color textLow: "#616161"

    property bool isOn: true
    property bool isEnabled: true

    id: root
    width: 36; height: 20
    radius: 10
    color: root.isOn ? Qt.rgba(0.16, 0.71, 0.96, 0.38) : root.bgInput

    Behavior on color { ColorAnimation { duration: 180 } }

    Rectangle {
        id: switchThumb
        width: 16; height: 16
        radius: 8
        anchors.verticalCenter: parent.verticalCenter
        x: root.isOn ? parent.width - width - 2 : 2
        color: root.isOn ? root.accent : root.textLow

        Behavior on x     { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation  { duration: 180 } }
    }

    MouseArea {
        enabled: root.isEnabled
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.isOn = !root.isOn
            click(root.isOn)
        }
    }
}