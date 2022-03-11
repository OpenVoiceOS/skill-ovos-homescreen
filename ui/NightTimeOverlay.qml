import QtQuick.Layouts 1.4
import QtQuick 2.12
import QtQuick.Controls 2.12
import org.kde.kirigami 2.11 as Kirigami
import QtGraphicalEffects 1.0
import Mycroft 1.0 as Mycroft

Drawer {
    id: nightTimeOverlayRoot
    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.View
    edge: Qt.LeftEdge

    height: parent.height
    width: parent.width
    interactive: false

    property bool horizontalMode: nightTimeOverlayRoot.width > nightTimeOverlayRoot.height ? 1 : 0

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
            nightTimeOverlayRoot.interactive = false
        }
    }

    background: Rectangle {
        color: "#000000"
    }

    contentItem: Item {

        Rectangle {
            id: leftBoxesOverlayAreaHandler
            width: Mycroft.Units.gridUnit * 0.5
            height: Mycroft.Units.gridUnit * 3.5
            anchors.right: parent.right
            anchors.rightMargin: Mycroft.Units.gridUnit / 2
            anchors.verticalCenter: parent.verticalCenter
            color: Qt.rgba(0.5, 0.5, 0.5, 0.5)
            radius: Mycroft.Units.gridUnit

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    nightTimeOverlayRoot.close()
                }
            }
        }

        Label {
            anchors.fill: parent
            anchors.margins: Mycroft.Units.gridUnit * 4
            font.capitalization: Font.AllUppercase
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment:Text.AlignVCenter
            font.weight: Font.ExtraBold
            fontSizeMode: Text.Fit
            minimumPixelSize: 20
            font.pixelSize: parent.height
            color: "#cdcdcd"
            text: sessionData.time_string.replace(":", "꞉")
        }
    }
}

