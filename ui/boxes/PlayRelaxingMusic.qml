/*
    SPDX-FileCopyrightText: 2023 Aditya Mehra <aix.m@outlook.com>
    SPDX-License-Identifier: Apache-2.0
*/

import QtQuick.Layouts 1.15
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import org.kde.kirigami 2.19 as Kirigami
import Qt5Compat.GraphicalEffects
import Mycroft 1.0 as Mycroft
import "../delegates" as Delegates

Delegates.BoxAbstractDelegate {
    action: "play relaxing music"
    preferredCellWidth: 4
    preferredCellHeight: 8

    ColumnLayout {
        id: primaryContentBoxLayout
        anchors.fill: parent
        anchors.margins: Mycroft.Units.gridUnit / 2

        Rectangle {
            id: headerIconItemBox
            Layout.fillWidth: true
            Layout.preferredHeight: parent.height * 0.25
            Layout.margins: -Mycroft.Units.gridUnit / 2.5
            radius: 15
            color: Kirigami.Theme.highlightColor

            Kirigami.Icon {
                id: headerIcon
                anchors.centerIn: parent
                width: parent.height
                height: width
                color: Kirigami.Theme.backgroundColor
                source: "new-audio-alarm"
            }
        }

        Image {
            Layout.fillWidth: true
            Layout.fillHeight: true
            fillMode: Image.PreserveAspectCrop
            source: "https://source.unsplash.com/800x800/?music"
        }

        Rectangle {
            id: contentPrimaryItemBox
            Layout.fillWidth: true
            Layout.preferredHeight: parent.height * 0.25
            Layout.margins: -Mycroft.Units.gridUnit / 2.5
            radius: 15
            color: Kirigami.Theme.highlightColor

            Label {
                id: primaryBoxText
                width: parent.width
                height: parent.height
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                maximumLineCount: 3
                elide: Text.ElideRight
                wrapMode: Text.WordWrap
                fontSizeMode: Text.Fit
                minimumPixelSize: 10
                font.pixelSize: 100
                color: Kirigami.Theme.textColor
                text: "Play relaxing music & sounds"
            }
        }
    }
}

