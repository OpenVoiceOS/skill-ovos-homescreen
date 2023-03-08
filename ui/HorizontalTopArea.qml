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
        anchors.left: parent.left
        anchors.right: weatherItemBox.left
        height: parent.height
        spacing: Mycroft.Units.gridUnit
    }

    WeatherArea {
        id: weatherItemBox
        anchors.right: parent.right
        anchors.rightMargin: Mycroft.Units.gridUnit * 0.50
        width: parent.width * 0.30
        height: parent.height
    }
}
