import QtQuick.Layouts 1.4
import QtQuick 2.12
import QtQuick.Controls 2.12
import org.kde.kirigami 2.11 as Kirigami
import QtGraphicalEffects 1.0
import Mycroft 1.0 as Mycroft

Drawer {
    id: root
    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.View
    edge: Qt.BottomEdge

    height: parent.height
    width: parent.width
    interactive: false

    property var appsModel
    property bool horizontalMode: root.width > root.height ? 1 : 0

    Overlay.modal: Rectangle {
        FastBlur{
            id: dblur
            anchors.fill: parent
            source: idleRoot
            radius: 64
        }
        color: Qt.rgba(0, 0, 0, 0.4)
    }

    SwipeArea {
        id: swipeAreaType
        height: idleRoot.height - (idleRoot.height * 0.35)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: contentBar.top
        propagateComposedEvents: true
        onSwipe: {
            if(direction == "down") {
                appsBar.close()
            }
        }
    }

    contentItem: Item {
        width: parent.width
        height: parent.height

        Rectangle {
            id: contentBar
            anchors.right: parent.right
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: parent.width
            height: parent.height
            gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { color: Qt.rgba(0, 0, 0, 0); position: 0 }
                    GradientStop { color: "#313131"; position: 0.001 }
                    GradientStop { color: "#313131"; position: 1 }
            }

            Rectangle {
                id: appsBarHeader
                anchors.top: parent.top
                width: parent.width
                height: 5
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { color: Qt.rgba(1, 0, 0, 0.9); position: 0 }
                    GradientStop { color: Qt.rgba(1, 0, 0, 0.9); position: 1 }
                }
            }

            Item {
                width: parent.width
                anchors.top: appsBarHeader.bottom
                anchors.bottom: parent.bottom

                GridView {
                    anchors.fill: parent
                    anchors.margins: Mycroft.Units.gridUnit
                    id: repeaterAppsModel
                    clip: true
                    cellWidth:  width / 3
                    cellHeight: root.horizontalMode ? height : (count > 3 ? height / 2 : height)

                    model: appsModel /*ListModel {
                        ListElement {name: "Mediaverse"; thumbnail: "https://www.pngrepo.com/download/182011/pentagram-music.png"}
                        ListElement {name: "Marketspace"; thumbnail: "https://cdn1.iconfinder.com/data/icons/round-vol-2/512/basket-512.png"}
                        ListElement {name: "Intellihome"; thumbnail: "https://www.seekpng.com/png/full/255-2557927_icon-round-idea-bulb-mobile-phone.png"}
                    }*/

                    delegate: AppEntry {
                        metricHeight: 12
                        implicitWidth: repeaterAppsModel.cellWidth
                        implicitHeight: repeaterAppsModel.cellHeight
                    }
                }
            }
        }
    }
}
