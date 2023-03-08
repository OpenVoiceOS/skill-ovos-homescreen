/*
    SPDX-FileCopyrightText: 2023 Aditya Mehra <aix.m@outlook.com>
    SPDX-License-Identifier: Apache-2.0
*/

import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.19 as Kirigami
import Mycroft 1.0 as Mycroft
import Qt5Compat.GraphicalEffects

Button {
    id: controlButton
    Layout.preferredWidth: Mycroft.Units.gridUnit * 5
    Layout.fillHeight: true
    Layout.margins: Mycroft.Units.gridUnit * 0.1
    property alias buttonIcon: controlButtonContentIcon.source

    SequentialAnimation {
        id: controlButtonAnim

        PropertyAnimation {
            target: controlButtonBackground
            property: "color"
            Kirigami.Theme.colorSet: Kirigami.Theme.Button
            Kirigami.Theme.inherit: false
            to: Kirigami.Theme.highlightColor
            duration: 200
        }

        PropertyAnimation {
            target: controlButtonBackground
            property: "color"
            Kirigami.Theme.colorSet: Kirigami.Theme.Button
            Kirigami.Theme.inherit: false
            to: Kirigami.Theme.backgroundColor
            duration: 200
        }
    }

    onPressed:(mouse)=> {
        controlButtonAnim.running = true;
    }

    contentItem: Item {
        Kirigami.Icon {
            id: controlButtonContentIcon
            width: Kirigami.Units.iconSizes.smallMedium
            height: width
            anchors.centerIn: parent

            ColorOverlay {
                source: parent
                anchors.fill: parent
                color: Kirigami.Theme.textColor
            }
        }
    }

    background: Rectangle {
        id: controlButtonBackground
        radius: 5
        Kirigami.Theme.colorSet: Kirigami.Theme.Button
        Kirigami.Theme.inherit: false
        color:  Kirigami.Theme.backgroundColor
        border.width: 1
        border.color: Kirigami.Theme.highlightColor
    }
}