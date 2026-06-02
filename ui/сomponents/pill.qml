import QtQuick
import QtQuick.Layouts

Rectangle {

    property string status: "waiting"

    property var stateColors: ({
        "waiting": {"bg": "#2E2E2E", "accent": "#9E9E9E", "text": "Ожидание"},
        "skip":    {"bg": "#242424", "accent": "#616161", "text": "Пропуск"},
        "loading": {"bg": "#3F3318", "accent": "#C29E4A", "text": "Загрузка"},
        "process": {"bg": "#202E35", "accent": "#4FC3F7", "text": "Обработка"},
        "done":    {"bg": "#203A21", "accent": "#66BB6A", "text": "Готово"},
        "error":   {"bg": "#4D1C21", "accent": "#F6443A", "text": "Ошибка"}
    })
    id: root
    height: 24
    width: statusPill.width + 20
    radius: 12
    color: root.stateColors[root.status].bg

    RowLayout {
        id: statusPill
        anchors.centerIn: parent
        spacing: 5

        Rectangle {
            width: 6; height: 6; radius: 3
            color: root.stateColors[root.status].accent

            SequentialAnimation on opacity {
                running: true
                loops: Animation.Infinite
                NumberAnimation { to: 0.2; duration: 600 }
                NumberAnimation { to: 1.0; duration: 600 }
            }
        }

        Text {
            text: root.stateColors[root.status].text
            color: root.stateColors[root.status].accent
            font.pixelSize: 11
            font.weight: Font.Medium
        }
    }
}