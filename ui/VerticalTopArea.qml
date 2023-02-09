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
    color: "transparent"

    WidgetsArea {
        id: widgetsRow
        anchors.top: parent.top
        anchors.topMargin: Mycroft.Units.gridUnit
        anchors.horizontalCenter: parent.horizontalCenter
        height: parent.height / 2
        spacing: Mycroft.Units.gridUnit
        verticalMode: true
    }

    WeatherArea {
        id: weatherItemBox
        anchors.top: widgetsRow.bottom
        anchors.topMargin: -(Mycroft.Units.gridUnit + 8)
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        height: parent.height / 2
        verticalMode: true
    }
}
