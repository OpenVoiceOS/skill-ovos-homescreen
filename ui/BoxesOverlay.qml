import QtQuick.Layouts 1.4
import QtQuick 2.12
import QtQuick.Controls 2.12
import org.kde.kirigami 2.11 as Kirigami
import QtGraphicalEffects 1.0
import Mycroft 1.0 as Mycroft

Drawer {
    id: boxoverlayroot
    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.View
    edge: Qt.RightEdge

    height: parent.height
    width: parent.width
    interactive: false

    property alias model: gridBox.model
    property bool horizontalMode: boxoverlayroot.width > boxoverlayroot.height ? 1 : 0

    Overlay.modal: Rectangle {
        FastBlur{
            id: dblur
            anchors.fill: parent
            source: idleRoot
            radius: 64
        }
        color: Qt.rgba(0, 0, 0, 0.4)
    }

    onPositionChanged: {
        if(position == 1){
            boxoverlayroot.interactive = false
        }
    }

    background: Rectangle {
        color: "#000000"
    }

    contentItem: Item {

        Kirigami.Heading {
            id: boxesOverlayHeader
            level: 1
            text: "Quick Access"
            color: "white"
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
            color: "#313131"
            height: 1
        }

        Rectangle {
            id: leftBoxesOverlayAreaHandler
            width: Mycroft.Units.gridUnit * 0.5
            height: Mycroft.Units.gridUnit * 3.5
            anchors.left: parent.left
            anchors.leftMargin: Mycroft.Units.gridUnit / 2
            anchors.verticalCenter: parent.verticalCenter
            color: Qt.rgba(0.5, 0.5, 0.5, 0.5)
            radius: Mycroft.Units.gridUnit

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    boxoverlayroot.close()
                }
            }
        }

        GridBox {
            id: gridBox
            anchors.left: leftBoxesOverlayAreaHandler.right
            anchors.leftMargin: Mycroft.Units.gridUnit / 2
            anchors.right: parent.right
            anchors.top: boxesOverlayHeaderSept.bottom
            anchors.topMargin: Mycroft.Units.gridUnit / 2
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Mycroft.Units.gridUnit / 2
        }
    }
}

