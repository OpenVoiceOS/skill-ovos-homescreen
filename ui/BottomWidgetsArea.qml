import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.12
import org.kde.kirigami 2.11 as Kirigami
import QtGraphicalEffects 1.0
import Mycroft 1.0 as Mycroft

Item {
    id: bottomWidgetsAreaRootItem
    property bool verticalMode: false
    property bool mediaWidgetDisplayEnabled: idleRoot.mediaWidgetEnabled

    onMediaWidgetDisplayEnabledChanged: {
        bottomWidgetsAreaRootItem.visible = false
        bottomWidgetsAreaRootItem.enabled = false
        bottomWidgetsAreaRootItem.visible = true
        bottomWidgetsAreaRootItem.enabled = true
    }

    ExamplesDisplay {
        color: "transparent"
        anchors.fill: parent
        visible: idleRoot.examplesEnabled && !mediaWidgetDisplay.enabled
        enabled: idleRoot.examplesEnabled && !mediaWidgetDisplay.enabled
        verticalMode: bottomWidgetsAreaRootItem.verticalMode
    }

    MediaWidgetDisplay {
        id: mediaWidgetDisplay
        anchors.left: parent.left
        anchors.right: parent.right        
        anchors.verticalCenter: parent.verticalCenter
        height: Mycroft.Units.gridUnit * 5        
        visible: idleRoot.mediaWidgetEnabled
        enabled: idleRoot.mediaWidgetEnabled
        verticalMode: bottomWidgetsAreaRootItem.verticalMode
    }
}
