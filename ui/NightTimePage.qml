/*
    SPDX-FileCopyrightText: 2023 Aditya Mehra <aix.m@outlook.com>
    SPDX-License-Identifier: Apache-2.0
*/

import QtQuick.Layouts 1.15
import QtQuick 2.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.19 as Kirigami
import Mycroft 1.0 as Mycroft
import Qt5Compat.GraphicalEffects

Control {
    id: nightTimeOverlayRoot
    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.View

    property bool horizontalMode: nightTimeOverlayRoot.width > nightTimeOverlayRoot.height ? 1 : 0
    property var time_string: sessionData.time_string ? sessionData.time_string.replace(":", "꞉") : ""

    background: Rectangle {
        width: idleRoot.width
        height: idleRoot.height
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: -Mycroft.Units.gridUnit * 2
        anchors.topMargin: -Mycroft.Units.gridUnit * 2
        color: "#000000"
    }

    contentItem: Item {

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
            text: nightTimeOverlayRoot.time_string
        }
    }
}

