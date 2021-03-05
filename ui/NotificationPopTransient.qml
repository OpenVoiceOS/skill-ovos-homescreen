import QtQuick.Layouts 1.4
import QtQuick 2.4
import QtQuick.Controls 2.0
import org.kde.kirigami 2.4 as Kirigami
import QtGraphicalEffects 1.0
import Mycroft 1.0 as Mycroft

Rectangle {
    id: popbox
    color: "#313131"
    radius: 10
    anchors.left: parent.left
    anchors.right: parent.right
    height: parent.cellHeight * 0.15 < minimumHeight ? minimumHeight : parent.cellHeight * 0.15
    property int minimumHeight: 100
    property var currentNotification
    
    function getBoxWidth(){
        return popbox.width;
    }
    
    Rectangle {
        id: timerBar
        color: "skyblue"
        anchors.bottom: parent.bottom
        width: parent.width
        height: Kirigami.Units.smallSpacing * 1
        radius: parent.radius
        
        PropertyAnimation { 
            id: timerBarAnimation
            target: timerBar
            property: "width"
            to: 0
            duration: 10000
            running: timerBar.visible && timerBar.width > 0 ? 1 : 0
            onRunningChanged: {
                timerBarAnimation.from = getBoxWidth()
            }
        }
    }
    
    Timer {
        id: notificationEndTimer
        interval: 10000
        repeat: false
        running: parent.visible
        onTriggered: {
            idleRoot.clearNotificationSessionData()
            parent.destroy()
        }
    }
    
    RowLayout {
        id: notificationRowBoxLayout
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
    
        ColumnLayout {
            id: notificationColumnBoxLayout
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            Label {
                id: heading
                text: currentNotification.sender
                Layout.fillWidth: true
                minimumPixelSize: 20
                maximumLineCount: 1
                elide: Text.ElideRight
                font.bold: true
                fontSizeMode: Text.Fit
                font.pixelSize: heading.height
                color: "#ffffff"
            }
            
            Kirigami.Separator {
                Layout.fillWidth: true
                height: 1
                color: "#515151"
            }
            
            Label {
                id: content
                text: currentNotification.text
                Layout.fillWidth: true
                Layout.preferredHeight: paintedHeight
                color: "#ffffff"
            }
        }
        
        Button {
            Layout.preferredWidth: Kirigami.Theme.iconSizes.Large
            Layout.preferredHeight: width
            icon.source: Qt.resolvedUrl("img/close.svg")
            
            onClicked: {
                triggerGuiEvent("homescreen.notification.pop.clear.delete", {"notification": currentNotification})
                popbox.destroy()
            }
        }
    }
} 
