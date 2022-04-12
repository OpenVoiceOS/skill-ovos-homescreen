import QtQuick.Layouts 1.4
import QtQuick 2.12
import QtQuick.Controls 2.12
import org.kde.kirigami 2.11 as Kirigami
import QtGraphicalEffects 1.0
import Mycroft 1.0 as Mycroft

Item {
    id: appBarRoot
    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.View
    clip: true
    implicitWidth: parentItem.width
    implicitHeight: parentItem.height
    opacity: opened

    property bool opened: false
    property bool enabled: true
    property var parentItem
    property var appsModel
    property bool horizontalMode: appBarRoot.width > appBarRoot.height ? 1 : 0

    function close() {
        appBarRoot.opened = false
    }

    function open() {
        appBarRoot.opened = true
    }

    Behavior on opacity {
        OpacityAnimator {
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InOutCubic
        }
    }

    Item {
        width: parent.width
        height: parent.height
        y: opened ? 0 : parent.height

        Rectangle {
            width:parent.width
            height: parent.height * 0.7
            anchors.top: parent.top
            FastBlur {
                id: dblur
                anchors.fill: parent
                source: idleRoot
                radius: 64
            }
            color: Qt.rgba(0, 0, 0, 0.4)

            Item {
                width: Mycroft.Units.gridUnit * 12
                height: Mycroft.Units.gridUnit * 4
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                visible: opened
                enabled: opened
                z: 2

                Rectangle {
                        id: bottomAreaHandler
                        width: horizontalMode ? Mycroft.Units.gridUnit * 3.5 : Mycroft.Units.gridUnit * 2.5
                        height: Mycroft.Units.gridUnit * 0.5
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: Mycroft.Units.gridUnit * 1.5
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Kirigami.Theme.highlightColor
                        radius: Mycroft.Units.gridUnit
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        appBarRoot.close()
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: parent.height * 0.3
            anchors.bottom: parent.bottom

            Rectangle {
                id: contentBar
                anchors.right: parent.right
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                width: parent.width
                height: parent.height
                color: Qt.lighter(Kirigami.Theme.backgroundColor, 1.25)

                Rectangle {
                    id: appsBarHeader
                    anchors.top: parent.top
                    width: parent.width
                    height: 5
                    color: Kirigami.Theme.highlightColor
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

                        model: appsModel

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
}
