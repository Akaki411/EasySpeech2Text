import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Dialogs

ApplicationWindow {
    id: root
    visible: true
    width: 1000
    height: 600
    minimumWidth: 800
    minimumHeight: 500
    title: "EasySpeech2Text"

    Material.theme: Material.Dark
    Material.accent: "#29B6F6"
    Material.background: "#1A1A1A"
    Material.foreground: "#EEEEEE"

    readonly property color bgPage:      "#1A1A1A"
    readonly property color bgCard:      "#242424"
    readonly property color bgInput:     "#2C2C2C"
    readonly property color accent:      "#29B6F6"
    readonly property color accentLight: "#4FC3F7"
    readonly property color accentInk:   "#0D1B2A"
    readonly property color textHigh:    "#EEEEEE"
    readonly property color textMid:     "#9E9E9E"
    readonly property color textLow:     "#616161"
    readonly property color divider:     "#2E2E2E"
    readonly property color success:     "#66BB6A"
    readonly property color error:       "#EF5350"

    color: bgPage

    property string statusText: "Выберите файл"
    property string transcriptText: ""
    property string llmText: ""
    property string fileInfo: ""
    property string whisperModel: "medium"
    property string deepFilterState: "waiting"
    property string whisperState: "waiting"
    property string deepSeekState: "waiting"

    property bool isBusy: false
    property bool isReady: false

    property var stateColors: ({
        "waiting": {"bg": "#2E2E2E", "accent": "#9E9E9E", "text": "Ожидание"},
        "skip":    {"bg": "#242424", "accent": "#616161", "text": "Пропуск"},
        "loading": {"bg": "#3F3318", "accent": "#C29E4A", "text": "Загрузка"},
        "process": {"bg": "#202E35", "accent": "#4FC3F7", "text": "Обработка"},
        "done":    {"bg": "#203A21", "accent": "#66BB6A", "text": "Готово"},
        "error":   {"bg": "#4D1C21", "accent": "#F6443A", "text": "Ошибка"}
    })

    Connections {
        target: backend
        function onStatusChanged(msg)           {root.statusText = msg}
        function onGetRawText(text)             {root.transcriptText = text}
        function onGetNormalizedText(text)      {root.llmText = text}
        function onBusyChanged(busy)            {root.isBusy = busy}
        function onReadyChanged(ready)          {root.isReady = ready}
        function onFilterStatusChanged(state)   {root.deepFilterState = state}
        function onWhisperStatusChanged(state)  {root.whisperState = state}
        function onDeepSeekStatusChanged(state) {root.deepSeekState = state}
    }

    FileDialog {
        id: fileDialog
        title: "Выберите аудио или видео"
        nameFilters: ["Медиафайлы (*.mp4 *.mkv *.avi *.mov *.webm *.mp3 *.wav *.flac *.ogg *.m4a *.aac *.opus)", "Все файлы (*)"]
        onAccepted: {
            root.fileInfo = backend.getFileInfo(fileDialog.selectedFile.toString())
            root.statusText = root.isReady ? "Ожидание запуска" : "Выберите файл"
        }
    }

    TextEdit { id: clipHelper; visible: false }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 0
        spacing: 0

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 20
            spacing: 16

                // ШАПКА С ВЫБОРОМ ФАЙЛА И НАСТРОЙКАМИ
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    height: 150

                    Rectangle {
                        Layout.fillWidth: true
                        height: 150
                        radius: 8
                        color: dropArea.containsDrag ? Qt.rgba(0.16, 0.71, 0.96, 0.08) : root.bgCard

                        Behavior on border.color { ColorAnimation { duration: 200 } }
                        Behavior on color        { ColorAnimation { duration: 200 } }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: 5
                            color: "transparent"
                            border.color: dropArea.containsDrag ? Qt.rgba(0.16, 0.71, 0.96, 0.25) : "transparent"
                            border.width: 1
                        }

                        DropArea {
                            id: dropArea
                            anchors.fill: parent
                            onDropped: (drop) => {if (drop.hasUrls) backend.transcribeFile(drop.urls[0].toString(), root.deepFilterState !== "skip")}
                        }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 20

                            Column {
                                spacing: 0

                                Image {
                                    source: root.fileInfo !== "" ? "./resources/vector/rosette.svg" : "./resources/vector/microphone.svg"
                                    width: 32
                                    height: 32

                                    RotationAnimation on rotation {
                                        running: root.isBusy
                                        from: 0; to: 360
                                        duration: 2400
                                        loops: Animation.Infinite
                                    }
                                }
                            }

                            Column {
                                spacing: 6

                                Text {
                                    text: root.fileInfo !== "" ? root.fileInfo : "Перетащите файл сюда"
                                    color: root.fileInfo !== "" ? root.textHigh : root.textMid
                                    font.pixelSize: 14
                                    font.weight: root.fileInfo !== "" ? Font.Medium : Font.Normal
                                }

                                Text {
                                    visible: root.fileInfo === ""
                                    text: "MP4, MKV, MOV, MP3, WAV, FLAC и др."
                                    color: root.textLow
                                    font.pixelSize: 12
                                }

                                Rectangle {
                                    width: 130; height: 34
                                    radius: 4
                                    color: chooseMouse.containsMouse && !root.isBusy ? Qt.lighter(root.accent, 1.12) : root.accent
                                    opacity: root.isBusy ? 0.38 : 1.0

                                    Behavior on color   { ColorAnimation { duration: 100 } }
                                    Behavior on opacity { NumberAnimation { duration: 150 } }

                                    Rectangle {
                                        id: ripple
                                        anchors.centerIn: parent
                                        width: 0; height: 0
                                        radius: width / 2
                                        color: Qt.rgba(1, 1, 1, 0.2)
                                        opacity: 0

                                        ParallelAnimation {
                                            id: rippleAnim
                                            NumberAnimation { target: ripple; property: "width";   from: 0; to: 180; duration: 400; easing.type: Easing.OutQuad }
                                            NumberAnimation { target: ripple; property: "height";  from: 0; to: 180; duration: 400; easing.type: Easing.OutQuad }
                                            NumberAnimation { target: ripple; property: "opacity"; from: 0.3; to: 0; duration: 400 }
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "ВЫБРАТЬ ФАЙЛ"
                                        color: root.accentInk
                                        font.pixelSize: 11
                                        font.weight: Font.Bold
                                        font.letterSpacing: 1.2
                                    }

                                    MouseArea {
                                        id: chooseMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        enabled: !root.isBusy
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: { rippleAnim.start(); fileDialog.open() }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 150
                        color: "transparent"

                        RowLayout {
                            width: parent.width
                            height: parent.height
                            spacing: 0

                            Column
                            {
                                height: 120
                                width: 150
                                spacing: 20

                                GridLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    columns: 2
                                    rowSpacing: 15
                                    columnSpacing: 20

                                    Text {
                                        text: "Шумоподавление"
                                        color: root.deepFilterState !== "skip" ? root.accentLight : root.textLow
                                        font.pixelSize: 12
                                        font.letterSpacing: 0.4
                                        font.weight: Font.Medium

                                        Behavior on color { ColorAnimation { duration: 180 } }
                                    }

                                    Rectangle {
                                        id: denoiseSwitchTrack
                                        width: 36; height: 20
                                        radius: 10
                                        color: root.deepFilterState !== "skip" ? Qt.rgba(0.16, 0.71, 0.96, 0.38) : root.bgInput

                                        Behavior on color { ColorAnimation { duration: 180 } }

                                        Rectangle {
                                            id: denoiseSwitchThumb
                                            width: 16; height: 16
                                            radius: 8
                                            anchors.verticalCenter: parent.verticalCenter
                                            x: root.deepFilterState !== "skip" ? parent.width - width - 2 : 2
                                            color: root.deepFilterState !== "skip" ? root.accent : root.textLow

                                            Behavior on x     { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                            Behavior on color { ColorAnimation  { duration: 180 } }
                                        }

                                        MouseArea {
                                            enabled: !root.isBusy
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.deepFilterState = deepFilterState !== "skip" ? "skip" : "waiting"
                                        }
                                    }

                                    Text {
                                        text: "Нормализация"
                                        color: root.deepSeekState !== "skip" ? root.accentLight : root.textLow
                                        font.pixelSize: 12
                                        font.letterSpacing: 0.4
                                        font.weight: Font.Medium

                                        Behavior on color { ColorAnimation { duration: 180 } }
                                    }

                                    Rectangle {
                                        id: llmSwitchTrack
                                        width: 36; height: 20
                                        radius: 10
                                        color: root.deepSeekState !== "skip" ? Qt.rgba(0.16, 0.71, 0.96, 0.38) : root.bgInput

                                        Behavior on color { ColorAnimation { duration: 180 } }

                                        Rectangle {
                                            id: llmSwitchThumb
                                            width: 16; height: 16
                                            radius: 8
                                            anchors.verticalCenter: parent.verticalCenter
                                            x: root.deepSeekState !== "skip" ? parent.width - width - 2 : 2
                                            color: root.deepSeekState !== "skip" ? root.accent : root.textLow

                                            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                            Behavior on color { ColorAnimation  { duration: 180 } }
                                        }

                                        MouseArea {
                                            enabled: !root.isBusy
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.deepSeekState = deepSeekState !== "skip" ? "skip" : "waiting"
                                        }
                                    }

                                    Text {
                                        text: "Модель"
                                        color: root.textHigh
                                        font.pixelSize: 12
                                        font.letterSpacing: 0.4
                                        font.weight: Font.Medium

                                        Behavior on color { ColorAnimation { duration: 180 } }
                                    }

                                    ComboBox {
                                        id: control
                                        width: 100
                                        height: 32
                                        currentIndex: 3
                                        enabled: !root.isBusy
                                        model: ["tiny", "base", "small", "medium", "large"]

                                        onActivated: {
                                            root.whisperModel = currentText
                                        }

                                        contentItem: Text {
                                            text: control.displayText
                                            font.pixelSize: 12
                                            verticalAlignment: Text.AlignVCenter
                                            leftPadding: 12
                                            rightPadding: 30
                                            color: root.textHigh
                                        }

                                        background: Rectangle {
                                            border.color: control.pressed ? "#2D9CDB" : "transparent"
                                            border.width: control.activeFocus ? 2 : 0
                                            radius: 4
                                            color: root.bgInput
                                        }

                                        popup: Popup {
                                            y: control.height
                                            width: control.width
                                            implicitHeight: contentItem.implicitHeight
                                            padding: 1

                                            contentItem: ListView {
                                                clip: true
                                                implicitHeight: contentHeight
                                                model: control.popup.visible ? control.delegateModel : null
                                                currentIndex: control.highlightedIndex

                                                ScrollIndicator.vertical: ScrollIndicator { }
                                            }

                                            background: Rectangle {
                                                radius: 4
                                                color: root.bgCard
                                            }
                                        }

                                        delegate: ItemDelegate {
                                            width: control.width
                                            height: 30

                                            contentItem: Text {
                                                text: modelData
                                                font.pixelSize: 12
                                                verticalAlignment: Text.AlignVCenter
                                                color: control.currentIndex === index ? root.textHigh : root.textMid
                                            }

                                            background: Rectangle {
                                                color: control.currentIndex === index ? root.bgInput : "transparent"
                                            }
                                        }
                                    }
                                }

                                Button {
                                    id: btn
                                    width: 250
                                    height: 40
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Text {
                                        anchors.centerIn: parent
                                        text: "НАЧАТЬ"
                                        color: root.isReady && !root.isBusy ? root.accentInk : root.stateColors["skip"].accent
                                        font.pixelSize: 11
                                        font.weight: Font.Bold
                                        font.letterSpacing: 1.2
                                    }

                                    background: Rectangle {
                                        radius: 4
                                        color: root.isReady && !root.isBusy ? root.accent : root.stateColors["skip"].bg
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        enabled: root.isReady
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            backend.transcribeFile(root.whisperModel, root.deepFilterState !== "skip", root.deepSeekState !== "skip")
                                        }
                                    }
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                height: 1
                            }

                            GridLayout {
                                height: 120
                                width: 150
                                columns: 2
                                rowSpacing: 10
                                columnSpacing: 20

                                Text {
                                    text: "DeepFilterNet"
                                    color: root.textMid
                                    font.pixelSize: 12
                                    font.letterSpacing: 0.4
                                    font.weight: Font.Medium
                                }

                                Rectangle {
                                    height: 24
                                    width: deepFilerStatusPill.width + 20
                                    radius: 12
                                    color: root.stateColors[root.deepFilterState].bg

                                    RowLayout {
                                        id: deepFilerStatusPill
                                        anchors.centerIn: parent
                                        spacing: 5

                                        Rectangle {
                                            width: 6; height: 6; radius: 3
                                            color: root.stateColors[deepFilterState].accent

                                            SequentialAnimation on opacity {
                                                running: true
                                                loops: Animation.Infinite
                                                NumberAnimation { to: 0.2; duration: 600 }
                                                NumberAnimation { to: 1.0; duration: 600 }
                                            }
                                        }

                                        Text {
                                            text: root.stateColors[deepFilterState].text
                                            color: root.stateColors[deepFilterState].accent
                                            font.pixelSize: 11
                                            font.weight: Font.Medium
                                        }
                                    }
                                }

                                Text {
                                    text: "Whisper"
                                    color: root.textMid
                                    font.pixelSize: 12
                                    font.letterSpacing: 0.4
                                    font.weight: Font.Medium
                                }

                                Rectangle {
                                    height: 24
                                    width: whisperStatusPill.width + 20
                                    radius: 12
                                    color: root.stateColors[root.whisperState].bg

                                    RowLayout {
                                        id: whisperStatusPill
                                        anchors.centerIn: parent
                                        spacing: 5

                                        Rectangle {
                                            width: 6; height: 6; radius: 3
                                            color: root.stateColors[root.whisperState].accent

                                            SequentialAnimation on opacity {
                                                running: true
                                                loops: Animation.Infinite
                                                NumberAnimation { to: 0.2; duration: 600 }
                                                NumberAnimation { to: 1.0; duration: 600 }
                                            }
                                        }

                                        Text {
                                            text: root.stateColors[root.whisperState].text
                                            color: root.stateColors[root.whisperState].accent
                                            font.pixelSize: 11
                                            font.weight: Font.Medium
                                        }
                                    }
                                }

                                Text {
                                    text: "Deepseek"
                                    color: root.textMid
                                    font.pixelSize: 12
                                    font.letterSpacing: 0.4
                                    font.weight: Font.Medium
                                }

                                Rectangle {
                                    height: 24
                                    width: deepSeekStatusPill.width + 20
                                    radius: 12
                                    color: root.stateColors[root.deepSeekState].bg

                                    RowLayout {
                                        id: deepSeekStatusPill
                                        anchors.centerIn: parent
                                        spacing: 5

                                        Rectangle {
                                            width: 6; height: 6; radius: 3
                                            color: root.stateColors[root.deepSeekState].accent

                                            SequentialAnimation on opacity {
                                                running: true
                                                loops: Animation.Infinite
                                                NumberAnimation { to: 0.2; duration: 600 }
                                                NumberAnimation { to: 1.0; duration: 600 }
                                            }
                                        }

                                        Text {
                                            text: root.stateColors[root.deepSeekState].text
                                            color: root.stateColors[root.deepSeekState].accent
                                            font.pixelSize: 11
                                            font.weight: Font.Medium
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ═══════════════════════════════════════════════════════════════════
                // ПОЛОСА СТАТУСА
                // ═══════════════════════════════════════════════════════════════════

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        height: 2
                        radius: 1
                        color: root.divider

                        Rectangle {
                            id: bar
                            height: parent.height
                            radius: 1
                            color: root.accent
                            width: root.isBusy ? parent.width : 0

                            Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.InOutCubic } }

                            SequentialAnimation on opacity {
                                running: root.isBusy
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.35; duration: 700 }
                                NumberAnimation { to: 1.0;  duration: 700 }
                            }
                        }
                    }

                    RowLayout {
                        width: 100
                        Layout.fillHeight: true

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.statusText
                            color: root.statusText.startsWith("Ошибка") ? root.error :
                                root.statusText.startsWith("Готов") ? root.success :
                                    root.statusText.startsWith("Ожидание") ? root.accent : root.textLow
                            font.pixelSize: 11
                            font.letterSpacing: 0.2
                            elide: Text.ElideRight
                        }
                    }
                }

                // ═══════════════════════════════════════════════════════════════════
                // ВЫВОД ТЕКСТА
                // ═══════════════════════════════════════════════════════════════════

                RowLayout {
                    Layout.fillHeight: true
                    spacing: 10

                    // ПЕРВОЕ ПОЛЕ
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 8
                        color: root.bgCard
                        clip: true

                        Rectangle {
                            id: cardHeader1
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
                                        text: "Транскрибированный текст"
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    Item { Layout.fillWidth: true }

                                    Text {
                                        visible: root.transcriptText !== ""
                                        text: root.transcriptText.length + " симв."
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
                                        id: copyBtn1
                                        width: 32; height: 32; radius: 16
                                        color: copyMouse1.containsMouse ? Qt.rgba(0.16, 0.71, 0.96, 0.12) : "transparent"
                                        visible: root.transcriptText !== ""

                                        Behavior on color { ColorAnimation { duration: 120 } }

                                        Image {
                                            id: copyBtn1Image
                                            source: "./resources/vector/copy.svg"
                                            width: 16
                                            height: 16
                                            anchors.centerIn: parent
                                        }

                                        Timer {
                                            id: copyBtn1ImageTimer
                                            interval: 3000
                                            onTriggered: {
                                                copyBtn1Image.source = "./resources/vector/copy.svg"
                                            }
                                        }

                                        MouseArea {
                                            id: copyMouse1
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                clipHelper.text = root.transcriptText
                                                clipHelper.selectAll()
                                                clipHelper.copy()
                                                copyBtn1Image.source = "./resources/vector/rosette-discount-check.svg"
                                                copyBtn1ImageTimer.restart()
                                            }
                                        }
                                    }

                                    Rectangle {
                                        id: downloadBtn1
                                        width: 32; height: 32; radius: 16
                                        color: downloadMouse1.containsMouse ? Qt.rgba(0.16, 0.71, 0.96, 0.12) : "transparent"
                                        visible: root.transcriptText !== ""

                                        Behavior on color { ColorAnimation { duration: 120 } }

                                        Image {
                                            id: downloadBtn1Image
                                            source: "./resources/vector/file-download.svg"
                                            width: 16
                                            height: 16
                                            anchors.centerIn: parent
                                        }

                                        Timer {
                                            id: downloadBtn1ImageTimer
                                            interval: 3000
                                            onTriggered: {
                                                downloadBtn1Image.source = "./resources/vector/file-download.svg"
                                            }
                                        }

                                        MouseArea {
                                            id: downloadMouse1
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                downloadBtn1Image.source = "./resources/vector/rosette-discount-check.svg"
                                                backend.saveToDocx(root.transcriptText, "")
                                                downloadBtn1ImageTimer.restart()
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Flickable {
                            anchors.top: cardHeader1.bottom
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
                                text: root.transcriptText
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
                            anchors.top: cardHeader1.bottom
                            anchors.margins: 16
                            spacing: 10
                            visible: root.isBusy && root.transcriptText === ""

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
                                            running: root.isBusy
                                            loops: Animation.Infinite
                                            NumberAnimation { from: -80; to: parent.parent.width; duration: 1400 + index * 120; easing.type: Easing.InOutSine }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ВТОРОЕ ПОЛЕ
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 8
                        color: root.bgCard
                        clip: true

                        Rectangle {
                            id: cardHeader2
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

                                Text {
                                    font.pixelSize: 12
                                    font.letterSpacing: 0.2
                                    color: root.textMid
                                    text: "Нормализованный текст"
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        visible: root.llmText !== ""
                                        text: root.llmText.length + " симв."
                                        color: root.textLow
                                        font.pixelSize: 10
                                        font.letterSpacing: 0.3
                                    }

                                    Rectangle {
                                        visible: root.llmText !== ""
                                        width: 1; height: 16
                                        color: root.divider
                                        Layout.leftMargin: 4
                                        Layout.rightMargin: 4
                                    }

                                    Rectangle {
                                        id: copyBtn2
                                        width: 32; height: 32; radius: 16
                                        color: copyMouse2.containsMouse ? Qt.rgba(0.16, 0.71, 0.96, 0.12) : "transparent"
                                        visible: root.llmText !== ""

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 120
                                            }
                                        }

                                        Image {
                                            id: copyBtn2Image
                                            source: "./resources/vector/copy.svg"
                                            width: 16
                                            height: 16
                                            anchors.centerIn: parent
                                        }

                                        Timer {
                                            id: copyBtn2ImageTimer
                                            interval: 3000
                                            onTriggered: {
                                                copyBtn2Image.source = "./resources/vector/copy.svg"
                                            }
                                        }

                                        MouseArea {
                                            id: copyMouse2
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                clipHelper.text = root.transcriptText
                                                clipHelper.selectAll()
                                                clipHelper.copy()
                                                copyBtn2Image.source = "./resources/vector/rosette-discount-check.svg"
                                                copyBtn2ImageTimer.restart()
                                            }
                                        }
                                    }

                                    Rectangle {
                                        id: downloadBtn2
                                        width: 32; height: 32; radius: 16
                                        color: downloadMouse2.containsMouse ? Qt.rgba(0.16, 0.71, 0.96, 0.12) : "transparent"
                                        visible: root.llmText !== ""

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 120
                                            }
                                        }

                                        Image {
                                            id: downloadBtn2Image
                                            source: "./resources/vector/file-download.svg"
                                            width: 16
                                            height: 16
                                            anchors.centerIn: parent
                                        }

                                        Timer {
                                            id: downloadBtn2ImageTimer
                                            interval: 3000
                                            onTriggered: {
                                                downloadBtn2Image.source = "./resources/vector/file-download.svg"
                                            }
                                        }

                                        MouseArea {
                                            id: downloadMouse2
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                downloadBtn2Image.source = "./resources/vector/rosette-discount-check.svg"
                                                backend.saveToDocx(root.llmText, "_normalized")
                                                downloadBtn2ImageTimer.restart()
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Flickable {
                            anchors.top: cardHeader2.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            clip: true
                            contentHeight: llmTextField.height
                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                            TextEdit {
                                id: llmTextField
                                width: parent.width
                                padding: 16
                                wrapMode: TextEdit.WordWrap
                                font.pixelSize: 13
                                font.letterSpacing: 0.1
                                text: root.llmText
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
                            anchors.top: cardHeader2.bottom
                            anchors.margins: 16
                            spacing: 10
                            visible: root.isBusy && root.llmText === ""

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
                                            running: root.isBusy
                                            loops: Animation.Infinite
                                            NumberAnimation { from: -80; to: parent.parent.width; duration: 1400 + index * 120; easing.type: Easing.InOutSine }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }