import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Dialogs
import "сomponents" as Components


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
    property string transcriptText: "321"
    property string llmText: "123"
    property string fileInfo: ""
    property string lang: "ru"
    property string whisperModel: "medium"
    property string llmModel: "Qwen/Qwen2.5-1.5B-Instruct"
    property string deepFilterState: "waiting"
    property string whisperState: "waiting"
    property string deepSeekState: "waiting"

    property bool useDeepFilter: true
    property bool useWhisper: true
    property bool useNormalize: true

    property bool isBusy: false
    property bool isReady: false

    property var models: [
        { code: "Qwen/Qwen2.5-1.5B-Instruct", name: "Qwen2.5 1.5B" },
        { code: "Qwen/Qwen2.5-3B-Instruct", name: "Qwen2.5 3B" },
        { code: "google/gemma-2-2b-it", name: "Gemma2 2B" },
        { code: "microsoft/Phi-3-mini-4k-instruct", name: "Phi-3 Mini 4K" },
        { code: "microsoft/Phi-3.5-mini-instruct", name: "Phi-3.5 Mini" },
        { code: "TinyLlama/TinyLlama-1.1B-Chat-v1.0", name: "TinyLlama 1.1B" },
        { code: "stabilityai/stablelm-2-zephyr-1_6b", name: "StableLM2 1.6B" },
        { code: "IlyaGusev/saiga_llama3_8b", name: "SaigaLlama3 8B" }
    ]

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
                        Layout.preferredWidth: root.width / 3
                        Layout.minimumWidth: 350
                        Layout.maximumWidth: root.width / 3
                        height: 150
                        radius: 8
                        color: dropArea.containsDrag ? Qt.rgba(0.16, 0.71, 0.96, 0.08) : root.bgCard
                        Behavior on color {ColorAnimation {duration: 200}}

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
                            onDropped: (drop) => {if (drop.hasUrls) backend.transcribeFile(drop.urls[0].toString(), root.useDeepFilter)}
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
                                    text: "MP4, MKV, MOV, MP3, WAV и др."
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

                        Column {
                            anchors.fill: parent
                            spacing: 0

                            Item {
                                width: parent.width
                                height: 115

                                GridLayout {
                                    id: settingsGrid

                                    Layout.preferredWidth: 150
                                    Layout.preferredHeight: 120
                                    anchors.left: parent.left
                                    columns: 2
                                    rowSpacing: 15
                                    columnSpacing: 20

                                    Text {
                                        text: "Шумоподавление"
                                        color: root.useDeepFilter ? root.accentLight : root.textLow
                                        font.pixelSize: 12
                                        font.letterSpacing: 0.4
                                        font.weight: Font.Medium

                                        Behavior on color { ColorAnimation { duration: 180 } }
                                    }

                                    Components.Toggle {
                                        isOn: root.useDeepFilter
                                        isEnabled: !root.isBusy
                                        onClick: function (state) {
                                            root.useDeepFilter = state
                                        }
                                    }

                                    Text {
                                        text: "Транскрибация"
                                        color: root.useWhisper ? root.accentLight : root.textLow
                                        font.pixelSize: 12
                                        font.letterSpacing: 0.4
                                        font.weight: Font.Medium

                                        Behavior on color { ColorAnimation { duration: 180 } }
                                    }

                                    Components.Toggle {
                                        isOn: root.useWhisper
                                        isEnabled: !root.isBusy
                                        onClick: function (state) {
                                            root.useWhisper = state
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

                                    Components.Toggle {
                                        isOn: root.useNormalize && root.useWhisper
                                        isEnabled: !root.isBusy && root.useWhisper
                                        onClick: function (state) {
                                            root.useNormalize = state && root.useWhisper
                                        }
                                    }
                                }

                                GridLayout {
                                    Layout.preferredWidth: 250
                                    Layout.preferredHeight: 120
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    columns: 2
                                    rowSpacing: 15
                                    columnSpacing: 10

                                    Text {
                                        text: "Локаль"
                                        color: root.textHigh
                                        font.pixelSize: 12
                                        font.letterSpacing: 0.4
                                        font.weight: Font.Medium

                                        Behavior on color { ColorAnimation { duration: 180 } }
                                    }

                                    Components.DropDown {
                                        data: ListModel {
                                            ListElement { code: "ru"; name: "🇷🇺 Русский" }
                                            ListElement { code: "ar"; name: "🇸🇦 Арабский" }
                                            ListElement { code: "en"; name: "🇬🇧 Английский" }
                                            ListElement { code: "fr"; name: "🇫🇷 Французский" }
                                            ListElement { code: "es"; name: "🇪🇸 Испанский" }
                                            ListElement { code: "zh"; name: "🇨🇳 Китайский" }
                                        }
                                        index: 0
                                        onSelect: (data) => {
                                            root.lang = data
                                        }
                                    }


                                    Text {
                                        text: "Whisper"
                                        color: root.textHigh
                                        font.pixelSize: 12
                                        font.letterSpacing: 0.4
                                        font.weight: Font.Medium

                                        Behavior on color { ColorAnimation { duration: 180 } }
                                    }

                                    Components.DropDown {
                                        data: ListModel {
                                            ListElement { code: "tiny"; name: "Tiny"}
                                            ListElement { code: "base"; name: "Base" }
                                            ListElement { code: "small"; name: "Small" }
                                            ListElement { code: "medium"; name: "Medium" }
                                            ListElement { code: "large"; name: "Large" }
                                        }
                                        index: 3
                                        onSelect: (data) => {
                                            root.whisperModel = data
                                        }
                                    }

                                    Text {
                                        text: "LLM"
                                        color: root.textHigh
                                        font.pixelSize: 12
                                        font.letterSpacing: 0.4
                                        font.weight: Font.Medium

                                        Behavior on color { ColorAnimation { duration: 180 } }
                                    }

                                    Components.DropDown {
                                        data: ListModel {
                                            id: llmModel
                                        }
                                        index: 0
                                        onSelect: (data) => {
                                            root.llmModel = data
                                        }
                                        Component.onCompleted: {
                                            for (let i = 0; i < root.models.length; i++)
                                            {
                                                llmModel.append(root.models[i]);
                                            }
                                        }
                                    }
                                }

                                GridLayout {
                                    Layout.preferredWidth: 150
                                    Layout.preferredHeight: 120
                                    anchors.right: parent.right
                                    columns: 2
                                    rowSpacing: 10
                                    columnSpacing: 20

                                    Text {
                                        text: "DeepFilter"
                                        color: root.textMid
                                        font.pixelSize: 12
                                        font.letterSpacing: 0.4
                                        font.weight: Font.Medium
                                    }

                                    Components.Pill {
                                        status: root.useDeepFilter ? root.deepFilterState : "skip"
                                    }

                                    Text {
                                        text: "Whisper"
                                        color: root.textMid
                                        font.pixelSize: 12
                                        font.letterSpacing: 0.4
                                        font.weight: Font.Medium
                                    }

                                    Components.Pill {
                                        status: root.useWhisper ? root.whisperState : "skip"
                                    }

                                    Text {
                                        text: {return root.models.filter(key => key.code === root.llmModel)[0].name}
                                        color: root.textMid
                                        font.pixelSize: 12
                                        font.letterSpacing: 0.4
                                        font.weight: Font.Medium
                                    }

                                    Components.Pill {
                                        status: root.useNormalize && root.useWhisper ? root.deepSeekState : "skip"
                                    }
                                }
                            }

                            Button {
                                id: btn
                                width: settingsGrid.width
                                height: 40
                                anchors.left: settingsGrid.left

                                Text {
                                    anchors.centerIn: parent
                                    text: "НАЧАТЬ"
                                    color: root.isReady && !root.isBusy ? root.accentInk : "#616161"
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    font.letterSpacing: 1.2
                                }

                                background: Rectangle {
                                    radius: 4
                                    color: root.isReady && !root.isBusy ? root.accent : "#242424"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: root.isReady
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        backend.transcribeFile(root.whisperModel, root.llmModel, root.lang, root.useDeepFilter, root.useWhisper, root.useNormalize)
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
                            Layout.alignment: Qt.AlignHCenter
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
                    Components.TextField {
                        header: "Транскрибированный текст"
                        text: root.transcriptText
                        waiting: root.isBusy
                        onDownload: () => {
                            backend.saveToDocx(root.transcriptText, "")
                        }
                    }

                    // ВТОРОЕ ПОЛЕ
                    Components.TextField {
                        header: "Нормализованный текст"
                        text: root.llmText
                        waiting: root.isBusy
                        onDownload: () => {
                            backend.saveToDocx(root.transcriptText, "_normalized")
                        }
                    }
                }
            }
        }
    }