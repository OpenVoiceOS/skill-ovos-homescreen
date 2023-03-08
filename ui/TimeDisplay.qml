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

Rectangle {
    id: timeDisplay
    color: "transparent"
    property bool verticalMode: false
    property var time_string: sessionData.time_string ? sessionData.time_string.replace(":", "꞉") : ""

    Label {
        id: time
        width: parent.width
        height: parent.height
        font.capitalization: Font.AllUppercase
        horizontalAlignment: timeDisplay.verticalMode ? Text.AlignHCenter : (idleRoot.rtlMode ? Text.AlignRight : Text.AlignLeft)
        verticalAlignment: timeDisplay.verticalMode ? Text.AlignBottom : Text.AlignVCenter
        font.weight: Font.ExtraBold
        fontSizeMode: Text.Fit
        minimumPixelSize: timeDisplay.verticalMode ? parent.height / 2 : parent.height
        font.pixelSize: parent.height
        color: "white"
        text: timeDisplay.time_string
        layer.enabled: true
        layer.effect: DropShadow {
            verticalOffset: 4
            color: idleRoot.shadowColor
            radius: 11
            spread: 0.4
            samples: 16
        }
    }
}
