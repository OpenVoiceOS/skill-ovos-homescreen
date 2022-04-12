import QtQuick.Layouts 1.4
import QtQuick 2.12
import QtQuick.Controls 2.12
import org.kde.kirigami 2.11 as Kirigami
import QtGraphicalEffects 1.0
import Mycroft 1.0 as Mycroft

Control {
    id: boxoverlayroot
    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.View

    property alias model: gridBox.model
    property bool horizontalMode: boxoverlayroot.width > boxoverlayroot.height ? 1 : 0
    property bool layoutGridLoaded: false

    function layoutGrid() {
        if(!layoutGridLoaded){
            gridBox.enabled = true
            gridBox.visible = true
            timer.setTimeout(function(){
                boxesView.model.append({"url": Qt.resolvedUrl("boxes/SetAlarmBox.qml")})
                boxesView.model.append({"url": Qt.resolvedUrl("boxes/TakeNoteBox.qml")})
                boxesView.model.append({"url": Qt.resolvedUrl("boxes/PlayRelaxingMusic.qml")})
                boxesView.model.append({"url": Qt.resolvedUrl("boxes/PlayTheNews.qml")})
                layoutGridLoaded = true
            }, 500)
        }
    }

    background: Rectangle {
        width: idleRoot.width
        height: idleRoot.height
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: -Mycroft.Units.gridUnit * 2
        anchors.topMargin: -Mycroft.Units.gridUnit * 2
        color: Kirigami.Theme.backgroundColor
    }

    contentItem: Item {

        Kirigami.Heading {
            id: boxesOverlayHeader
            level: 1
            text: "Quick Access"
            color: Kirigami.Theme.textColor
            anchors.top: parent.top
            anchors.topMargin: Mycroft.Units.gridUnit / 2
            anchors.left: parent.left
            anchors.leftMargin: Mycroft.Units.gridUnit
        }

        Kirigami.Separator {
            id: boxesOverlayHeaderSept
            anchors.top: boxesOverlayHeader.bottom
            anchors.topMargin: Mycroft.Units.gridUnit / 2
            anchors.left: parent.left
            anchors.right: parent.right
            color: Kirigami.Theme.highlightColor
            height: 1
        }

        GridBox {
            id: gridBox
            enabled: false
            visible: false
            anchors.left: parent.left
            anchors.leftMargin: Mycroft.Units.gridUnit / 2
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: boxesOverlayHeaderSept.bottom
            anchors.topMargin: Mycroft.Units.gridUnit / 2
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Mycroft.Units.gridUnit / 2
        }
    }
}

