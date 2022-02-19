import QtQuick.Layouts 1.4
import QtQuick 2.9
import QtQuick.Controls 2.12
import org.kde.kirigami 2.11 as Kirigami
import QtGraphicalEffects 1.0
import Mycroft 1.0 as Mycroft

Mycroft.CardDelegate {
    id: idleRoot
    skillBackgroundColorOverlay: "transparent"
    cardBackgroundOverlayColor: "transparent"
    cardRadius: 0
    skillBackgroundSource: Qt.resolvedUrl(sessionData.wallpaper_path + sessionData.selected_wallpaper)
    property bool horizontalMode: idleRoot.width > idleRoot.height ? 1 : 0
    readonly property color primaryBorderColor: Qt.rgba(1, 0, 0, 0.9)
    readonly property color secondaryBorderColor: Qt.rgba(1, 1, 1, 0.7)
    property var notificationModel: sessionData.notification_model
    property var textModel: sessionData.skill_examples.examples
    property color shadowColor: Qt.rgba(0, 0, 0, 0.7)
    property bool rtlMode: Boolean(sessionData.rtl_mode)
    property bool weatherEnabled: Boolean(sessionData.weather_api_enabled)
    property var dateFormat: sessionData.dateFormat ? sessionData.dateFormat : "DMY"
    property bool showExamples: Boolean(sessionData.show_examples)

    background: Item {
        anchors.fill: parent

        LinearGradient {
            anchors.fill: parent
            start: Qt.point(0, 0)
            end: Qt.point(0, (parent.height + 20))
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0)}
                GradientStop { position: 0.75; color: Qt.rgba(0, 0, 0, 0.1)}
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.3)}
            }
        }

        RadialGradient {
            anchors.fill: parent
            angle: 0
            verticalRadius: parent.height * 0.625
            horizontalRadius: parent.width * 0.5313
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0)}
                GradientStop { position: 0.6; color: Qt.rgba(0, 0, 0, 0.2)}
                GradientStop { position: 0.75; color: Qt.rgba(0, 0, 0, 0.3)}
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.5)}
            }
        }
    }

    onRtlModeChanged: {
        console.log("RTL MODE:")
        console.log(idleRoot.rtlMode)
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

    onTextModelChanged: {
        exampleLabel.entry = textModel[0]
        textTimer.running = true
    }

    onVisibleChanged: {
        if(visible && idleRoot.textModel){
            textTimer.running = true
        }
    }

    function getWeatherImagery(weathercode) {
        console.log(weathercode);
        switch(weathercode) {
        case 0:
            return "icons/sun.svg";
            break
        case 1:
            return "icons/partial_clouds.svg";
            break
        case 2:
            return "icons/clouds.svg";
            break
        case 3:
            return "icons/rain.svg";
            break
        case 4:
            return "icons/rain.svg";
            break
        case 5:
            return "icons/storm.svg";
            break
        case 6:
            return "icons/snow.svg";
            break
        case 7:
            return "icons/fog.svg";
            break
        }
        return weathercode;
    }

    function setExampleText(){
        timer.setTimeout(function(){
            entryChangeB.running = true;
            var index = idleRoot.textModel.indexOf(exampleLabel.entry);
            var nextItem;
            if(index >= 0) {
                nextItem = idleRoot.textModel[index + 1]
                exampleLabel.entry = nextItem
            }
        }, 500);
    }

    Timer {
        id: textTimer
        interval: 30000
        running: false
        repeat: true

        onTriggered: {
            entryChangeA.running = true;
            setExampleText()
        }
    }

    Timer {
        id: timer
        function setTimeout(cb, delayTime) {
            timer.interval = delayTime;
            timer.repeat = false;
            timer.triggered.connect(cb);
            timer.triggered.connect(function release () {
                timer.triggered.disconnect(cb); // This is important
                timer.triggered.disconnect(release); // This is important as well
            });
            timer.start();
        }
    }

    Item {
        id: mainContentItemArea
        anchors.fill: parent

        AppsBar {
            id: appsBar
            width: parent.width
            height: parent.height * 0.35
            parent: idleRoot
            appsModel: sessionData.applications_model
        }

        SwipeArea {
            id: swipeAreaType
            anchors.fill: parent
            propagateComposedEvents: true
            onSwipe: {
                if(direction == "up") {
                    appsBar.open()
                }
                if(direction == "left") {
                    triggerGuiEvent("homescreen.swipe.change.wallpaper", {})
                }
            }
        }

        Kirigami.Icon {
            id: downArrowMenuHint
            anchors.top: parent.top
            anchors.topMargin: -Mycroft.Units.gridUnit
            anchors.horizontalCenter: parent.horizontalCenter
            width: Mycroft.Units.gridUnit * 2.5
            height: Mycroft.Units.gridUnit * 2.5
            opacity: 0
            source:  Qt.resolvedUrl("icons/down.svg")
            color: "white"

            SequentialAnimation {
                id: downArrowMenuHintAnim
                running: idleRoot.visible ? 1 : 0

                PropertyAnimation {
                    target: downArrowMenuHint
                    property: "opacity"
                    to: 1
                    duration: 1000
                }

                PropertyAnimation {
                    target: downArrowMenuHint
                    property: "opacity"
                    to: 0.5
                    duration: 1000
                }

                PropertyAnimation {
                    target: downArrowMenuHint
                    property: "opacity"
                    to: 1
                    duration: 1000
                }

                PropertyAnimation {
                    target: downArrowMenuHint
                    property: "opacity"
                    to: 0
                    duration: 1000
                }
            }
        }

        ColumnLayout {
            id: grid
            anchors.fill: parent
            spacing: 0

            Rectangle {
                color: "transparent"
                Layout.fillWidth: true
                Layout.leftMargin: Mycroft.Units.gridUnit
                Layout.rightMargin: Mycroft.Units.gridUnit
                Layout.minimumHeight: parent.height * 0.17

                Row {
                    id: widgetsRow
                    anchors.left: parent.left
                    anchors.right: weatherItemBox.left
                    height: parent.height
                    spacing: Mycroft.Units.gridUnit

                    Kirigami.Icon {
                        id: notificationWigBtn
                        width: parent.height
                        height: width
                        visible: idleRoot.notificationModel.count > 0
                        enabled: idleRoot.notificationModel.count > 0
                        source: Qt.resolvedUrl("icons/notificationicon.svg")

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                notificationsStorageViewBox.open()
                            }
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
                            z: 10

                            Label {
                                color: "white"
                                anchors.centerIn: parent
                                text: idleRoot.notificationModel.count
                            }
                        }
                    }

                    Kirigami.Icon {
                        id: timerWigBtn
                        width: parent.height
                        height: width
                        visible: false
                        enabled: false
                        source: Qt.resolvedUrl("icons/timericon.svg")

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                            }
                        }
                    }


                    Kirigami.Icon {
                        id: alarmWigBtn
                        width: parent.height
                        height: width
                        visible: false
                        enabled: false
                        source: Qt.resolvedUrl("icons/alarmicon.svg")

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                            }
                        }
                    }
                }

                Item {
                    id: weatherItemBox
                    anchors.right: parent.right
                    anchors.rightMargin: Mycroft.Units.gridUnit * 0.50
                    width: parent.width * 0.30
                    height: parent.height + Mycroft.Units.gridUnit * 2
                    visible: idleRoot.weatherEnabled

                    Kirigami.Icon {
                        id: weatherItemIcon
                        source: Qt.resolvedUrl(getWeatherImagery(sessionData.weather_code)) //Qt.resolvedUrl("icons/sun.svg")
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        width: horizontalMode ? parent.height * 0.80 : parent.width * 0.50
                        height: width
                        visible: true
                        layer.enabled: true
                        layer.effect: DropShadow {
                            verticalOffset: 4
                            color: idleRoot.shadowColor
                            radius: 11
                            spread: 0.4
                            samples: 16
                        }
                    }

                    Text {
                        id: weatherItem
                        text: sessionData.weather_temp + "°" //"50°"
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.left: weatherItemIcon.right
                        anchors.right: parent.right
                        anchors.leftMargin: Mycroft.Units.gridUnit
                        fontSizeMode: Text.Fit
                        minimumPixelSize: 50
                        font.pixelSize: horizontalMode ? parent.height : parent.height * 0.65
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        color: "white"
                        visible: true
                        layer.enabled: true
                        layer.effect: DropShadow {
                            verticalOffset: 4
                            color: idleRoot.shadowColor
                            radius: 11
                            spread: 0.4
                            samples: 16
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.minimumHeight: Math.round(parent.height * 0.125)
            }

            Rectangle {
                color: "transparent"
                Layout.fillWidth: true
                Layout.preferredHeight: parent.height * 0.30
                Layout.leftMargin: Mycroft.Units.gridUnit
                Layout.rightMargin: Mycroft.Units.gridUnit
                Layout.topMargin: 1
                Layout.bottomMargin: 1

                Label {
                    id: time
                    width: parent.width
                    height: parent.height
                    font.capitalization: Font.AllUppercase
                    horizontalAlignment: idleRoot.rtlMode ? Text.AlignRight : Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    font.weight: Font.ExtraBold
                    //font.pixelSize: parent.height
                    font.pixelSize: horizontalMode ? parent.height : parent.height * 0.65
                    color: "white"
                    text: sessionData.time_string.replace(":", "꞉")
                    layer.enabled: true
                    layer.effect: DropShadow {
                        verticalOffset: 4
                        color: idleRoot.shadowColor
                        radius: 11
                        spread: 0.4
                        samples: 16
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.minimumHeight: Mycroft.Units.gridUnit
            }

            Rectangle {
                color: "transparent"
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: Mycroft.Units.gridUnit * 2
                Layout.rightMargin: Mycroft.Units.gridUnit * 2

                Label {
                    id: weekday
                    width: parent.width
                    height: parent.height
                    fontSizeMode: Text.Fit
                    minimumPixelSize: 50
                    font.pixelSize: horizontalMode ? Math.round(parent.height * 0.725) : Math.round(parent.height * 0.5)
                    horizontalAlignment: idleRoot.rtlMode ? Text.AlignRight : Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.1
                    property var longShortMonth: horizontalMode ? sessionData.month_string : sessionData.month_string.substring(0,3)
                    text: switch(idleRoot.dateFormat) {
                        case "DMY":
                            return sessionData.weekday_string.substring(0,3) + " " + sessionData.day_string + " " +  longShortMonth + ", " + sessionData.year_string
                            break
                        case "MDY":
                            return longShortMonth + " " + sessionData.weekday_string.substring(0,3) + " " + sessionData.day_string + ", " + sessionData.year_string
                            break
                        case "YMD":
                            return sessionData.year_string + ", " + longShortMonth + " " + sessionData.weekday_string.substring(0,3) + " " + sessionData.day_string
                            break
                        default:
                            return sessionData.weekday_string.substring(0,3) + " " + sessionData.day_string + " " +  longShortMonth + ", " + sessionData.year_string
                            break
                    }
                    color: "white"
                    layer.enabled: true
                    layer.effect: DropShadow {
                        verticalOffset: 4
                        color: idleRoot.shadowColor
                        radius: 11
                        spread: 0.4
                        samples: 16
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.minimumHeight: Mycroft.Units.gridUnit
            }

            Rectangle {
                color: "transparent"
                Layout.fillWidth: true
                Layout.leftMargin: Mycroft.Units.gridUnit * 2
                Layout.rightMargin: Mycroft.Units.gridUnit * 2
                Layout.fillHeight: true

                Row {
                    width: parent.width
                    height: parent.height
                    spacing: Mycroft.Units.gridUnit * 0.5

                    Kirigami.Icon {
                        id: exampleLabelIcon
                        visible: showExamples
                        source: Qt.resolvedUrl("icons/mic-min.svg")
                        width: horizontalMode ? parent.height * 0.65 : parent.height * 0.45
                        anchors.verticalCenter: parent.verticalCenter
                        height: width
                    }

                    Label {
                        id: exampleLabel
                        width: parent.width
                        height: parent.height
                        fontSizeMode: Text.Fit
                        visible: true
                        minimumPixelSize: 50
                        font.pixelSize: horizontalMode ? Math.round(parent.height * 0.475) : Math.round(parent.height * 0.2)
                        horizontalAlignment: idleRoot.rtlMode ? Text.AlignRight : Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.WordWrap
                        font.weight: Font.DemiBold
                        property string entry
                        text: '<i>“Ask Me, ' + entry + '”</i>'
                        color: "white"
                        layer.enabled: true
                        layer.effect: DropShadow {
                            verticalOffset: 4
                            color: idleRoot.shadowColor
                            radius: 11
                            spread: 0.4
                            samples: 16
                        }

                        PropertyAnimation {
                            id: entryChangeA
                            target: exampleLabel
                            running: false
                            property: "opacity"
                            to: 0.5
                            duration: 500
                        }

                        PropertyAnimation {
                            id: entryChangeB
                            target: exampleLabel
                            running: false
                            property: "opacity"
                            to: 1
                            duration: 500
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.minimumHeight: Mycroft.Units.gridUnit
            }
        }
    }

    Popup {
        id: notificationsStorageViewBox
        width: parent.width * 0.80
        height: parent.height * 0.80
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        parent: idleRoot
        dim: true

        Overlay.modeless: Rectangle {
            id: modelessBg
            color: Qt.rgba(0, 0, 0, 0.75)

            FastBlur {
                anchors.fill: modelessBg
                source: modelessBg
                radius: 32
            }
        }

        background: Rectangle {
            color: "transparent"
        }

        Row {
            id: topBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.height * 0.20
            spacing: parent.width * 0.10

            Rectangle {
                width: parent.width * 0.15
                height: parent.height
                color: "#212121"
                radius: 10

                Kirigami.Icon {
                    width: parent.width * 0.75
                    height: width
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    source: Qt.resolvedUrl("icons/dialog-close.svg")
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        notificationsStorageViewBox.close()
                    }
                }
            }

            Rectangle {
                width: parent.width * 0.35
                height: parent.height
                color: "#212121"
                radius: 10

                Kirigami.Heading {
                    level: 2
                    width: parent.width
                    anchors.left: parent.left
                    anchors.leftMargin: Kirigami.Units.largeSpacing
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Notifications"
                    color: "#ffffff"
                }
            }

            Rectangle {
                width: parent.width * 0.30
                height: parent.height
                color: "#212121"
                radius: 10

                RowLayout {
                    anchors.centerIn: parent

                    Kirigami.Icon {
                        Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                        Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                        source: Qt.resolvedUrl("icons/clear.svg")
                        color: "white"
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
                        Mycroft.MycroftController.sendRequest("ovos.notification.api.storage.clear", {})
                    }
                }
            }
        }

        ListView {
            id: notificationsStorageView
            anchors.top: topBar.bottom
            anchors.topMargin: Kirigami.Units.largeSpacing
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
