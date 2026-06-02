from pathlib import Path
from PySide6.QtCore import QObject, Property, Signal, Slot, QCoreApplication
from PySide6.QtQml import QQmlApplicationEngine


class PreloaderBridge(QObject):
    progressChanged = Signal()
    textChanged = Signal()
    closeRequested = Signal()

    def __init__(self):
        super().__init__()
        self._progress = 0.0
        self._text = "0.0 / 0.0 MB"

    def getProgress(self):
        return self._progress

    def setProgress(self, value):
        if self._progress == value:
            return
        self._progress = value
        self.progressChanged.emit()

    def getText(self):
        return self._text

    def setText(self, value):
        if self._text == value:
            return
        self._text = value
        self.textChanged.emit()

    progress = Property(float, getProgress, notify=progressChanged)
    progressText = Property(str, getText, notify=textChanged)

    @Slot()
    def requestClose(self):
        self.closeRequested.emit()


class Preloader:
    def __init__(self, app):
        self.cancelled = False
        self.app = app

        self.bridge = PreloaderBridge()
        self.bridge.closeRequested.connect(self._close_requested)

        self.engine = QQmlApplicationEngine()
        self.engine.rootContext().setContextProperty("preloaderBridge", self.bridge)

        qml_path = (Path(__file__).parent / "preloader.qml")
        self.engine.load(str(qml_path))

        if not self.engine.rootObjects():
            raise RuntimeError(f"Cannot load {qml_path}")

        self.window = self.engine.rootObjects()[0]

    def _close_requested(self):
        self.cancelled = True
        self.window.close()
        raise SystemExit(0)

    def show(self):
        self.window.show()
        self.window.raise_()
        self.window.requestActivate()
        QCoreApplication.processEvents()

    def close(self):
        self.window.close()
        QCoreApplication.processEvents()

    def update_progress(self, downloaded_mb, total_mb):
        if self.cancelled:
            raise SystemExit(0)
        progress = 0
        if total_mb:
            progress = downloaded_mb / total_mb
        self.window.setProperty("progressValue", progress)
        self.window.setProperty("progressText",f"{downloaded_mb:.1f} / {total_mb:.1f} MB")
        QCoreApplication.processEvents()

    def set_status(self, text):
        if self.cancelled:
            raise SystemExit(0)
        self.window.setProperty("progressText", f"{text}")
        QCoreApplication.processEvents()