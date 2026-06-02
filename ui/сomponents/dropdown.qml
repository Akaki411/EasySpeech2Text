import QtQuick
import QtQuick.Controls.Material
import Qt5Compat.GraphicalEffects

ComboBox {
    signal select(string state)

    property var data: []
    property int index: 0

    readonly property color bgCard:   "#242424"
    readonly property color bgInput:  "#2C2C2C"
    readonly property color textHigh: "#EEEEEE"
    readonly property color textMid:  "#9E9E9E"

    id: root
    implicitWidth: Math.max(125, contentItem.implicitWidth + 5)
    height: 32
    currentIndex: root.index
    enabled: !root.isBusy
    model: root.data
    textRole: "name"

    onActivated: {
        let currentItem = model.get(currentIndex)
        if (currentItem)
        {
            select(currentItem.code);
        }
    }

    contentItem: Text {
        text: root.displayText
        font.pixelSize: 12
        verticalAlignment: Text.AlignVCenter
        leftPadding: 12
        rightPadding: 30
        color: root.textHigh
    }

    background: Rectangle {
        border.color: root.pressed ? "#2D9CDB" : "transparent"
        border.width: root.activeFocus ? 2 : 0
        radius: 4
        color: root.bgInput
    }

    popup: Popup {
        y: root.height
        width: root.width
        implicitHeight: Math.min(250, contentItem.implicitHeight)
        padding: 1

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex

            ScrollIndicator.vertical: ScrollIndicator { }
        }

        background: Item {
            implicitWidth: parent.width
            implicitHeight: parent.height

            Rectangle {
                id: bgRect
                anchors.fill: parent
                radius: 4
                color: root.bgCard
            }

            DropShadow {
                anchors.fill: bgRect
                source: bgRect
                horizontalOffset: 0
                verticalOffset: 6
                radius: 18
                samples: 35
                color: "#000000"
                transparentBorder: true
            }
        }
    }

    delegate: ItemDelegate {
        width: root.width
        height: 30

        contentItem: Text {
            text: model.name
            font.pixelSize: 12
            font.family: "Segoe UI Emoji, Noto Color Emoji"
            verticalAlignment: Text.AlignVCenter
            color: root.currentIndex === index ? root.textHigh : root.textMid
        }

        background: Rectangle {
            color: root.currentIndex === index ? root.bgInput : "transparent"
        }
    }
}