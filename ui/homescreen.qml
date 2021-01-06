import QtQuick.Layouts 1.4
import QtQuick 2.4
import QtQuick.Controls 2.0
import org.kde.kirigami 2.4 as Kirigami
import QtGraphicalEffects 1.0
import Mycroft 1.0 as Mycroft

Mycroft.Delegate {
    id: idleRoot
    skillBackgroundColorOverlay: "transparent"
    skillBackgroundSource: Qt.resolvedUrl("img/background.jpg")
    property bool horizontalMode: idleRoot.width > idleRoot.height ? 1 : 0
    
    ColumnLayout {        
        id: grid  
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: 0
        
        Rectangle {
            color: "transparent"
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            Label {  
                id: time
                width: parent.width
                height: parent.height
                font.capitalization: Font.AllUppercase
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: "Noto Sans Display"
                font.weight: Font.Bold
                font.pixelSize: horizontalMode ? parent.height / 1 : parent.height / 1.5
                color: "white"
                text: sessionData.time_string.replace(":", "꞉")  
                layer.enabled: true
                layer.effect: DropShadow {
                    verticalOffset: 2
                    color: "#000000"
                    radius: 12
                    spread: 0.5
                    samples: 8
                }
            }
        }

        
        Rectangle {
            color: "transparent"
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            Label { 
                id: weekday
                width: parent.width
                height: parent.height
                font.pixelSize: horizontalMode ? parent.height / 3 : parent.height / 5
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignBottom
                wrapMode: Text.WordWrap
                font.family: "Noto Sans Display"
                font.weight: Font.SemiBold
                text: sessionData.weekday_string
                color: "white"
                layer.enabled: true
                layer.effect: DropShadow {
                    verticalOffset: 2
                    color: "#000000"
                    radius: 12
                    spread: 0.5
                    samples: 8
                }
            }
        }
        
        Rectangle {
            color: "transparent"
            Layout.fillWidth: true
            Layout.fillHeight: true

            Label {
                id: date
                width: parent.width
                height: parent.height
                font.pixelSize: horizontalMode ? parent.height / 3 : parent.height / 5
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignTop
                wrapMode: Text.WordWrap
                font.family: "Noto Sans Display"
                font.bold: true
                text: sessionData.month_string + ", " + sessionData.year_string
                color: "white"
                layer.enabled: true
                layer.effect: DropShadow {
                    verticalOffset: 2
                    color: "#000000"
                    radius: 12
                    spread: 0.5
                    samples: 8
                }
            }
        }
    }
}
