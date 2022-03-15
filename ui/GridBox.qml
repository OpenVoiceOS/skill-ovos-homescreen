import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQml.Models 2.12
import QtQuick.Window 2.12
import Mycroft 1.0 as Mycroft

Item {
    id: gridBoxRoot
    width: parent.width
    height: parent.height
    property alias model: gridItemModel

    ListModel {
        id: gridItemModel
    }

    Flickable {
        id: gridLayoutFlickable
        width: parent.width
        height: parent.height
        clip: true

        function getEndPos(){
            var ratio = 1.0 - gridLayoutFlickable.visibleArea.widthRatio;
            var endPos = gridLayoutFlickable.contentWidth * ratio;
            return endPos;
        }

        function scrollToEnd(){
            gridLayoutFlickable.contentX = getEndPos();
        }

        DashLayout {
            id: gridItemView
            anchors.fill: parent

            onContentWidthChanged:{
                gridLayoutFlickable.contentWidth = gridItemView.contentWidth
                //gridLayoutFlickable.scrollToEnd()
            }

            Repeater {
                id: tileRepeater
                signal delegateItemChanged(var item)
                model: DelegateModel {
                id: visualModel
                model: gridItemModel

                delegate: MouseArea {
                        id: delegateRoot
                        property alias contentItem: contentLoader.item

                        onContentItemChanged: {
                            tileRepeater.delegateItemChanged(tileRepeater.itemAt(index))
                        }

                        property bool held: false
                        property int visualIndex: DelegateModel.itemsIndex
                        drag.target: held ? delegateContentItem : undefined

                        onDoubleClicked: {
                            Mycroft.MycroftController.sendText(contentItem.action)
                        }

                        onPressAndHold: {
                            held = true
                            delegateContentItem.opacity = 0.5
                        }

                        onReleased: {
                            if (held === true) {
                                held = false
                                delegateContentItem.opacity = 1
                                delegateContentItem.Drag.drop()
                            } else {
                                //action on release
                            }
                        }

                        Item {
                            id: delegateContentItem
                            anchors.fill: parent
                            anchors.margins: gridItemView.spacing
                            Drag.active: delegateRoot.drag.active
                            Drag.source: delegateRoot
                            Drag.hotSpot.x: 36
                            Drag.hotSpot.y: 36

                            states: [
                                State {
                                    when: delegateContentItem.Drag.active

                                    ParentChange {
                                        target: delegateContentItem
                                        parent: gridItemView
                                    }

                                    PropertyChanges {
                                        target: delegateContentItem
                                        anchors.fill: undefined
                                    }
                                }
                            ]

                            Loader {
                                id: contentLoader
                                anchors.fill: parent
                                anchors.margins: 16
                                source: model.url
                            }
                        }

                        DropArea {
                            id: dropArea

                            anchors {
                                fill: parent
                                margins: gridItemView.spacing
                            }

                            onDropped: {
                                contentLoader.active = false
                                contentLoader.active = true
                            }
                        }
                    }
                }
            }
        }
    }
}
