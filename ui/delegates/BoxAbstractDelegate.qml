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

Control {
    id: boxDelegateRootItem
    z: 1

    property var action: ""
    property int preferredCellWidth: 4
    property int preferredCellHeight: 4

    background: Rectangle {
        color: Kirigami.Theme.backgroundColor
        border.color: Kirigami.Theme.highlightColor
        border.width: 1
        radius: 15
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: false
            horizontalOffset: 3
            verticalOffset: 3
            color: Qt.rgba(0, 0, 0, 0.50)
            spread: 0.2
            samples: 8
        }
    }

    contentItem: Item {
        z: 2
    }
}
