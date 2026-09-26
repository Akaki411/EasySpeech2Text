import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Rectangle {
    signal close()

    property color bgPage:             "#1A1A1A"
    property color bgCard:             "#242424"
    property color bgInput:            "#2C2C2C"
    property color accent:             "#29B6F6"
    property color accentInk:          "#0D1B2A"
    property color textHigh:           "#EEEEEE"
    property color textLow:            "#616161"
    property color success:            "#66BB6A"
    property color error:              "#EF5350"
    property color transparentSuccess: "#3266BB6A"
    property color transparentError:   "#32EF5350"

    property string successInk: "../resources/vector/square-rounded-check.svg"
    property string errorInk:   "../resources/vector/square-rounded-x.svg"

    id: root
    width: 700
    height: 500
    anchors.centerIn: parent
    color: root.bgPage
    radius: 5
    z: 15

    ListModel {
        id: apiModel
    }

    Component.onCompleted: {
        let saved = backend.loadKeys()
        for (let i = 0; i < saved.length; i++)
            apiModel.append({name: saved[i].name, key: saved[i].key, isValid: saved[i].isValid, checking: false})
    }

    Connections {
        target: backend
        function onKeyChecked(provider, valid, message) {
            for (let i = 0; i < apiModel.count; i++) {
                if (apiModel.get(i).name === provider) {
                    apiModel.setProperty(i, "isValid", valid)
                    apiModel.setProperty(i, "checking", false)
                    break
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        Text {
            text: "API ключи"
            color: root.textHigh
            font.pixelSize: 14
            font.bold: true
        }

        ScrollView {
            id: scrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ScrollBar.vertical: ScrollBar {
                parent: scrollView
                anchors.top: scrollView.top
                anchors.bottom: scrollView.bottom
                anchors.right: scrollView.right
                policy: ScrollBar.AsNeeded
                width: 8
                background: Rectangle { color: "transparent" }
                contentItem: Rectangle {
                    color: root.textLow
                    radius: 4
                }
            }

            GridLayout {
                width: scrollView.availableWidth - 15
                columns: 1
                rowSpacing: 10

                Repeater {
                    model: apiModel

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 60
                        color: "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 15

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: model.name
                                    color: root.textLow
                                    font.pixelSize: 12
                                    font.bold: true
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 32
                                    color: root.bgInput
                                    radius: 4

                                    TextInput {
                                        id: keyInput
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        text: model.key
                                        color: root.textHigh
                                        font.pixelSize: 13
                                        echoMode: TextInput.Password
                                        selectByMouse: true
                                        clip: true
                                        onTextEdited: model.key = text
                                    }
                                }
                            }

                            Rectangle {
                                Layout.alignment: Qt.AlignBottom
                                width: 32; height: 32; radius: 16
                                color: model.isValid ? root.transparentSuccess : root.transparentError
                                visible: model.key !== "" && !model.checking

                                Behavior on color { ColorAnimation { duration: 120 } }

                                Image {
                                    source: model.isValid ? root.successInk : root.errorInk
                                    width: 16
                                    height: 16
                                    anchors.centerIn: parent
                                }
                            }

                            Button {
                                Layout.fillWidth: false
                                Layout.fillHeight: false
                                Layout.alignment: Qt.AlignBottom

                                Layout.minimumWidth: 120
                                Layout.maximumWidth: 120
                                Layout.preferredWidth: 120

                                Layout.minimumHeight: 32
                                Layout.maximumHeight: 32
                                Layout.preferredHeight: 32

                                padding: 0
                                topPadding: 0
                                bottomPadding: 0
                                enabled: model.key !== "" && !model.checking

                                background: Rectangle {
                                    anchors.fill: parent
                                    radius: 5
                                    color: Qt.rgba(0.16, 0.71, 0.96, 0.12)
                                    opacity: parent.enabled ? 1.0 : 0.4
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: model.checking ? "Проверка…" : "Проверить"
                                    color: root.accent
                                    font.pixelSize: 12
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: model.key !== "" && !model.checking
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        apiModel.setProperty(index, "checking", true)
                                        backend.checkKey(model.name, model.key)
                                    }
                                }
                            }
                        }
                    }
                }
                Item {
                    width: 1
                    height: 10
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 50

            Item { Layout.fillWidth: true }

            Button {
                id: saveButton
                Layout.preferredWidth: 130
                Layout.preferredHeight: 42

                background: Rectangle {
                    radius: 5
                    color: root.accent
                }

                Text {
                    anchors.centerIn: parent
                    text: "Сохранить"
                    color: root.accentInk
                    font.pixelSize: 12
                    font.bold: true
                    font.letterSpacing: 1.1
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.close()
                }
            }
        }
    }
}
