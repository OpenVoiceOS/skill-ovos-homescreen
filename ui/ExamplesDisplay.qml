/*
    SPDX-FileCopyrightText: 2023 Aditya Mehra <aix.m@outlook.com>
    SPDX-License-Identifier: Apache-2.0
*/

import QtQuick.Layouts 1.15
import QtQuick 2.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.19 as Kirigami
import Qt5Compat.GraphicalEffects
import Mycroft 1.0 as Mycroft

Rectangle {
    id: examplesDisplay
    property bool verticalMode: false
    property bool examplesPrefix: true
    color: "transparent"

    Connections {
        target: textTimer

        function onRunEntryChangeA() {
            entryChangeA.running = true
        }

        function onRunEntryChangeB() {
            entryChangeB.running = true
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Mycroft.Units.gridUnit / 2
        spacing: Mycroft.Units.gridUnit / 2

        Rectangle {
            color: "transparent"
            id: exampleLabelIconHolder
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            Layout.preferredWidth: examplesDisplay.verticalMode ? parent.width * 0.15 : exampleLabelIcon.width
            Layout.fillHeight: true

            Kirigami.Icon {
                id: exampleLabelIcon
                visible: idleRoot.examplesEnabled
                source: Qt.resolvedUrl("icons/mic-min.svg")
                anchors.right: examplesDisplay.verticalMode ? parent.right : undefined
                width: parent.height * 0.70
                height: parent.height
            }
        }

        Rectangle {
            color: "transparent"
            Layout.alignment: examplesDisplay.verticalMode ? Qt.AlignHCenter : (idleRoot.rtlMode ? Qt.AlignRight : Qt.AlignLeft)
            Layout.fillHeight: true
            Layout.fillWidth: true

            Label {
                id: exampleLabel
                width: parent.width
                height: parent.height
                visible: true
                fontSizeMode: Text.Fit
                maximumLineCount: 3
                elide: idleRoot.rtlMode ? Text.ElideLeft : Text.ElideRight
                minimumPixelSize: examplesDisplay.verticalMode ? 15 : 30
                font.pixelSize: Mycroft.Units.gridUnit * 6
                horizontalAlignment: idleRoot.rtlMode ? Text.AlignRight : Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
                font.weight: Font.DemiBold
                text: '<i>“' + (idleRoot.examplesPrefix ? qsTr("Ask Me") + " ": "") + idleRoot.exampleEntry + '”</i>'
                color: "white"
                layer.enabled: true
                layer.effect: DropShadow {
                    verticalOffset: 4
                    color: idleRoot.shadowColor
                    radius: 11
                    spread: 0.4
                    samples: 16
                }

                PropertyAnimation {
                    id: entryChangeA
                    target: exampleLabel
                    running: false
                    property: "opacity"
                    to: 0.5
                    duration: 500
                }

                PropertyAnimation {
                    id: entryChangeB
                    target: exampleLabel
                    running: false
                    property: "opacity"
                    to: 1
                    duration: 500
                }
            }
        }
    }
}
