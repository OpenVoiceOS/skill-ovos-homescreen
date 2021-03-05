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
    property int notificationCounter: sessionData.notifcation_counter
    property var notificationData: sessionData.notification
    property var notificationModel: sessionData.notification_model
    property var previous_model
    signal clearNotificationSessionData
    
    onNotificationDataChanged: {
        console.log("Notification Should Have Changed")
        console.log(idleRoot.notificationModel.storedmodel)
        if(sessionData.notification.text && sessionData.notification !== "") {
            display_notification()
        }
    }
    
    onNotificationModelChanged: {
        if(notificationModel.count > 0) {
            notificationsStorageView.model = sessionData.notification_model.storedmodel
        } else {
            notificationsStorageView.model = sessionData.notification_model.storedmodel
            notificationsStorageView.forceLayout()
            if(notificationsStorageViewBox.opened) {
                notificationsStorageViewBox.close()
            }
        }
    }
    
    Connections {
        target: idleRoot
        onClearNotificationSessionData: {
            triggerGuiEvent("homescreen.notification.pop.clear", {"notification": idleRoot.notificationData})
        }
    }
    
    function display_notification() {
        console.log("Notification Counter Changed")
        console.log(notificationData)
        if(idleRoot.notificationData !== undefined) {
            console.log("Got A Notification")
            if(idleRoot.notificationData.type == "sticky"){
                console.log("Got Sticky Type")
                var component = Qt.createComponent("NotificationPopSticky.qml");
            } else {
                console.log("Got Other Type")
                var component = Qt.createComponent("NotificationPopTransient.qml");
            }
            if (component.status != Component.Ready)
            {
                if (component.status == Component.Error) {
                    console.debug("Error: "+ component.errorString());
                }
                return;
            } else {
                var notif_object = component.createObject(notificationPopupLayout, {currentNotification: idleRoot.notificationData})
            }
        } else {
            console.log(idleRoot.notificationData)
        }
    }
        
    Button {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: Kirigami.Theme.iconSizes.Large
        height: width
        icon.source: Qt.resolvedUrl("img/notification-icon.svg")
        visible: idleRoot.notificationModel.count > 0
        
        onClicked: {
            notificationsStorageViewBox.open()
        }
        
        Rectangle {
            color: "red"
            anchors.right: parent.right
            anchors.rightMargin: -Kirigami.Units.largeSpacing * 0.50
            anchors.top: parent.top
            anchors.topMargin: -Kirigami.Units.largeSpacing * 0.50
            width: parent.width * 0.50
            height: parent.height * 0.50
            radius: width
            
            Label {
                color: "white"
                anchors.centerIn: parent
                text: idleRoot.notificationModel.count
            }
        }
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
    
    Column {
        id: notificationPopupLayout
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing * 4
        property int cellWidth: idleRoot.width
        property int cellHeight: idleRoot.height
        z: 9999
    }

    Button {
        id: msArea
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: 150
        height: 100
        text: "Transient Notification"
        onClicked: {
                triggerGuiEvent("homescreen.notification.set", {"sender": "Example Skill " + Math.random(), "text": "Received A Sample Notification, This Is Sample Content!", "action": "none", "type": "transient"})
        }
    }
    
    Button {
        id: msArea2
        anchors.bottom: parent.bottom
        anchors.left: msArea.right
        anchors.leftMargin: Kirigami.Units.largeSpacing
        width: 150
        height: 100
        text: "Sticky Notification"
        onClicked: {
                triggerGuiEvent("homescreen.notification.set", {"sender": "Example Skill " + Math.random(), "text": "Received A Sticky Sample Notification, This Is Sample Sticky Content!", "action": "none", "type": "sticky"})
        }
    }
    
    Popup {
        id: notificationsStorageViewBox
        width: parent.width * 0.80
        height: parent.height * 0.80
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        parent: idleRoot
        
        background: Rectangle {
            color: "transparent"
        }
        
        Row {
            id: topBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.height * 0.15
            spacing: parent.width * 0.10

            Rectangle {
                width: parent.width * 0.50
                height: parent.height
                color: "#313131"
                radius: 10
                
                Kirigami.Heading {
                    level: 3
                    width: parent.width
                    anchors.left: parent.left
                    anchors.leftMargin: Kirigami.Units.largeSpacing
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Notifications"
                    color: "#ffffff"
                }
            }
            
            Rectangle {
                width: parent.width * 0.40
                height: parent.height
                color: "#313131"
                radius: 10
                
                RowLayout {
                    anchors.centerIn: parent
                    
                    Kirigami.Icon {
                        Layout.preferredWidth: Kirigami.iconSizes.medium
                        Layout.preferredHeight: Kirigami.iconSizes.medium
                        source: Qt.resolvedUrl("img/clear.svg")
                    }
                   
                    Kirigami.Heading {
                        level: 3
                        width: parent.width
                        Layout.fillWidth: true
                        text: "Clear"
                        color: "#ffffff"
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        triggerGuiEvent("homescreen.notification.storage.clear", {})
                    }
                }
            }
        }
        
        ListView {
            id: notificationsStorageView
            anchors.top: topBar.bottom
            anchors.topMargin: Kirigami.Units.smallSpacing
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            clip: true
            highlightFollowsCurrentItem: false
            spacing: Kirigami.Units.smallSpacing
            property int cellHeight: notificationsStorageView.height            
            delegate: NotificationDelegate{}
        }
    }
}
