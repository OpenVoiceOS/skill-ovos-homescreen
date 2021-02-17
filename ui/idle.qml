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
    readonly property color primaryBorderColor: Qt.rgba(1, 0, 0, 0.9)
    readonly property color secondaryBorderColor: Qt.rgba(1, 1, 1, 0.7)
    property bool runListenerAnimation: sessionData.show_listener_animation
    
    onRunListenerAnimationChanged: {
        root.visible = runListenerAnimation
    }

    Rectangle {
        id: root
        property Gradient borderGradient: borderGradient
        property int borderWidth: Kirigami.Units.largeSpacing - Kirigami.Units.smallSpacing
        anchors.fill: parent
        color: "transparent"
        visible: false
        anchors.leftMargin: -Kirigami.Units.largeSpacing
        anchors.rightMargin: -Kirigami.Units.largeSpacing
        anchors.topMargin: -Kirigami.Units.largeSpacing
        anchors.bottomMargin: -Kirigami.Units.largeSpacing

        Loader {
            id: loader
            width: parent.width
            height: parent.height
            anchors.centerIn: parent
            active: borderGradient
            sourceComponent: border
        }

        Gradient {
            id: borderGradient
            GradientStop {
                position: 0.000
                SequentialAnimation on color {
                    loops: Animation.Infinite
                    running: root.visible
                    ColorAnimation { from: primaryBorderColor; to: secondaryBorderColor;  duration: 1000 }
                    ColorAnimation { from: secondaryBorderColor; to: primaryBorderColor;  duration: 1000 }
                }
            }
            GradientStop {
                position: 0.256
                color: Qt.rgba(0, 1, 1, 1)
                SequentialAnimation on color {
                    loops: Animation.Infinite
                    running: root.visible
                    ColorAnimation { from: secondaryBorderColor; to: primaryBorderColor;  duration: 1000 }
                    ColorAnimation { from: primaryBorderColor; to: secondaryBorderColor;  duration: 1000 }
                }
            }
            GradientStop {
                position: 0.500
                SequentialAnimation on color {
                    loops: Animation.Infinite
                    running: root.visible
                    ColorAnimation { from: primaryBorderColor; to: secondaryBorderColor;  duration: 1000 }
                    ColorAnimation { from: secondaryBorderColor; to: primaryBorderColor;  duration: 1000 }
                }
            }
            GradientStop {
                position: 0.756
                SequentialAnimation on color {
                    loops: Animation.Infinite
                    running: root.visible
                    ColorAnimation { from: secondaryBorderColor; to: primaryBorderColor;  duration: 1000 }
                    ColorAnimation { from: primaryBorderColor; to: secondaryBorderColor;  duration: 1000 }
                }
            }
            GradientStop {
                position: 1.000
                SequentialAnimation on color {
                    loops: Animation.Infinite
                    running: root.visible
                    ColorAnimation { from: primaryBorderColor; to: secondaryBorderColor;  duration: 1000 }
                    ColorAnimation { from: secondaryBorderColor; to: primaryBorderColor;  duration: 1000 }
                }
            }
        }

        Component {
            id: border
            Item {
                ConicalGradient {
                    id: borderFill
                    anchors.fill: parent
                    gradient: borderGradient
                    visible: false
                }
                
                FastBlur {
                    anchors.fill: parent
                    source: parent
                    radius: 32
                }

                Rectangle {
                    id: mask
                    radius: root.radius
                    border.width: root.borderWidth
                    anchors.fill: parent
                    color: 'transparent'
                    visible: false
                }

                OpacityMask {
                    id: opM
                    anchors.fill: parent
                    source: borderFill
                    maskSource: mask
                }
            }
        }
    }
    
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
