import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Dialogs

Rectangle {
    signal download()

    property string header: ""
    property string text: ""
    property bool waiting: false

    readonly property color bgCard:   "#242424"
    readonly property color accent:   "#29B6F6"
    readonly property color textHigh: "#EEEEEE"
    readonly property color textMid:  "#9E9E9E"
    readonly property color textLow:  "#616161"
    readonly property color divider:  "#2E2E2E"

    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true
    radius: 8
    color: root.bgCard
    clip: true

    Rectangle {
        id: cardHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 40
        color: "transparent"

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: root.divider
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 10

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Text {
                    font.pixelSize: 12
                    font.letterSpacing: 0.2
                    color: root.textMid
                    text: root.header
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Item { Layout.fillWidth: true }

                Text {
                    visible: root.text !== ""
                    text: root.text.length + " симв."
                    color: root.textLow
                    font.pixelSize: 10
                    font.letterSpacing: 0.3
                }

                Rectangle {
                    visible: root.transcriptText !== ""
                    width: 1; height: 16
                    color: root.divider
                    Layout.leftMargin: 4
                    Layout.rightMargin: 4
                }

                Rectangle {
                    id: copyBtn
                    width: 32; height: 32; radius: 16
                    color: copyMouse.containsMouse ? Qt.rgba(0.16, 0.71, 0.96, 0.12) : "transparent"
                    visible: root.text !== ""

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Image {
                        id: copyBtnImage
                        source: "../resources/vector/copy.svg"
                        width: 16
                        height: 16
                        anchors.centerIn: parent
                    }

                    Timer {
                        id: copyBtnImageTimer
                        interval: 3000
                        onTriggered: {
                            copyBtnImage.source = "../resources/vector/copy.svg"
                        }
                    }

                    MouseArea {
                        id: copyMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            clipHelper.text = root.text
                            clipHelper.selectAll()
                            clipHelper.copy()
                            copyBtnImage.source = "../resources/vector/rosette-discount-check.svg"
                            copyBtnImageTimer.restart()
                        }
                    }
                }

                Rectangle {
                    id: downloadBtn
                    width: 32; height: 32; radius: 16
                    color: downloadMouse.containsMouse ? Qt.rgba(0.16, 0.71, 0.96, 0.12) : "transparent"
                    visible: root.text !== ""

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Image {
                        id: downloadBtnImage
                        source: "../resources/vector/file-download.svg"
                        width: 16
                        height: 16
                        anchors.centerIn: parent
                    }

                    Timer {
                        id: downloadBtnImageTimer
                        interval: 3000
                        onTriggered: {
                            downloadBtnImage.source = "../resources/vector/file-download.svg"
                        }
                    }

                    MouseArea {
                        id: downloadMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            downloadBtnImage.source = "../resources/vector/rosette-discount-check.svg"
                            download()
                            downloadBtnImageTimer.restart()
                        }
                    }
                }
            }
        }
    }

    Flickable {
        anchors.top: cardHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        contentHeight: transcribeTextField.height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        TextEdit {
            id: transcribeTextField
            width: parent.width
            padding: 16
            wrapMode: TextEdit.WordWrap
            font.pixelSize: 13
            font.letterSpacing: 0.1
            text: root.text
            color: root.textHigh
            readOnly: true
            selectByMouse: true
            selectionColor: root.accent
            height: implicitHeight
        }
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: cardHeader.bottom
        anchors.margins: 16
        spacing: 10
        visible: root.waiting && root.text === ""

        Repeater {
            model: [0.9, 0.75, 0.85, 0.6, 0.8]
            delegate: Rectangle {
                width: parent.width * modelData
                height: 10
                radius: 5
                color: root.bgInput

                Rectangle {
                    width: 80; height: parent.height
                    radius: parent.radius
                    color: Qt.rgba(0.16, 0.71, 0.96, 0.15)

                    SequentialAnimation on x {
                        running: root.waiting
                        loops: Animation.Infinite
                        NumberAnimation { from: -80; to: parent.parent.width; duration: 1400 + index * 120; easing.type: Easing.InOutSine }
                    }
                }
            }
        }
    }
}