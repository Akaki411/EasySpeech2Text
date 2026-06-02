import QtQuick
import QtQuick.Window

Window {
    property real progressValue: 0
    property string progressText: "0 / 0 MB"

    id: root
    width: 420
    height: 160
    visible: false
    color: "transparent"
    flags: Qt.FramelessWindowHint
    modality: Qt.ApplicationModal

    Component.onCompleted: {
        x = (Screen.width - width) / 2
        y = (Screen.height - height) / 2
    }

    Rectangle {
        anchors.fill: parent
        radius: 5
        color: "#1A1A1A"

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 50
            text: "Загрузка компонентов"
            color: "#EEEEEE"
            font.pixelSize: 14
        }

        Rectangle {
            id: progressBackground
            width: 320
            height: 10
            radius: 5
            anchors.horizontalCenter: parent.horizontalCenter
            y: 85
            color: "#2C2C2C"

            Rectangle {
                width: {return Math.round(320 * root.progressValue)}
                height: parent.height
                radius: 5

                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: "#29B6F6"
                    }
                    GradientStop {
                        position: 1
                        color: "#4FC3F7"
                    }
                }

                Behavior on width {
                    NumberAnimation {
                        duration: 100
                    }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: progressBackground.bottom
            anchors.topMargin: 5
            text: root.progressText
            color: "#616161"
            font.pixelSize: 12
        }

        Text {
            id: closeButton
            text: "✕"
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 10
            anchors.rightMargin: 12
            color: closeMouse.containsMouse ? "#EEEEEE" : "#9E9E9E"
            font.pixelSize: 14

            Behavior on color {
                ColorAnimation {
                    duration: 200
                }
            }

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    preloaderBridge.requestClose()
                }
            }
        }
    }
}