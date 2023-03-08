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

ColumnLayout {
    anchors.fill: parent
    spacing: 0

    VerticalTopArea {
        id: vertArea
        Layout.fillWidth: true
        Layout.leftMargin: Mycroft.Units.gridUnit
        Layout.rightMargin: Mycroft.Units.gridUnit
        Layout.minimumHeight: parent.height * 0.30
    }

    Item {
        Layout.fillWidth: true
        Layout.minimumHeight: Math.round(parent.height * 0.125)
    }

    TimeDisplay {
        Layout.fillWidth: true
        Layout.preferredHeight: parent.height * 0.30
        Layout.leftMargin: Mycroft.Units.gridUnit
        Layout.rightMargin: Mycroft.Units.gridUnit
        Layout.topMargin: 1
        Layout.bottomMargin: 1
        Layout.alignment: Qt.AlignHCenter
        verticalMode: true
    }

    Item {
        Layout.fillWidth: true
        Layout.minimumHeight: Mycroft.Units.gridUnit
    }

    DayMonthDisplay {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.leftMargin: Mycroft.Units.gridUnit * 2
        Layout.rightMargin: Mycroft.Units.gridUnit * 2
        Layout.alignment: Qt.AlignHCenter
        verticalMode: true
    }

    Item {
        Layout.fillWidth: true
        Layout.minimumHeight: Mycroft.Units.gridUnit
    }

    BottomWidgetsArea {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.leftMargin: Mycroft.Units.gridUnit * 2
        Layout.rightMargin: Mycroft.Units.gridUnit * 2
        Layout.alignment: Qt.AlignHCenter
        verticalMode: true
    }

    Item {
        Layout.fillWidth: true
        Layout.minimumHeight: Mycroft.Units.gridUnit
    }
}

