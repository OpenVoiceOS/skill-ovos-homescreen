import QtQuick.Layouts 1.4
import QtQuick 2.9
import QtQuick.Controls 2.12
import org.kde.kirigami 2.11 as Kirigami
import QtGraphicalEffects 1.0
import Mycroft 1.0 as Mycroft
import "." as Local

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
    property bool rtlMode: sessionData.rtl_mode ? Boolean(sessionData.rtl_mode) : false
    property bool examplesEnabled: sessionData.skill_info_enabled ? Boolean(sessionData.skill_info_enabled) : true
    property bool weatherEnabled: sessionData.weather_api_enabled ? Boolean(sessionData.weather_api_enabled) : false
    property var dateFormat: sessionData.dateFormat ? sessionData.dateFormat : "DMY"
    property var timeString: sessionData.time_string
    property string exampleEntry
    signal exampleEntryUpdate(string exampleEntry)

    controlBar: Local.AppsBar {
        id: appBar
        anchors {
            bottom: parent.bottom
        }
        parentItem: idleRoot
        appsModel: sessionData.applications_model
        z: 100
    }

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
        console.log("TextModelChanged")
        exampleEntry = idleRoot.textModel[0]
        exampleEntryUpdate(exampleEntry)
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
            textTimer.runEntryChangeB()
            var index = idleRoot.textModel.indexOf(exampleEntry);
            var nextItem;
            if(index >= 0) {
                nextItem = idleRoot.textModel[index + 1]
                idleRoot.exampleEntry = nextItem
                exampleEntryUpdate(exampleEntry)
            }
        }, 500);
    }

    Timer {
        id: textTimer
        interval: 30000
        running: false
        repeat: true
        signal runEntryChangeA
        signal runEntryChangeB

        onTriggered: {
            runEntryChangeA()
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
        width: Mycroft.Units.gridUnit * 4
        height: Mycroft.Units.gridUnit * 12
        anchors.right: parent.right
        anchors.rightMargin: -Mycroft.Units.gridUnit * 2
        anchors.verticalCenter: parent.verticalCenter
        visible: mainView.currentIndex == 0 || mainView.currentIndex == 1
        enabled: mainView.currentIndex == 0 || mainView.currentIndex == 1
        z: 2

        Rectangle {
            id: rightAreaHandler
            width: Mycroft.Units.gridUnit * 0.5
            height: horizontalMode ? Mycroft.Units.gridUnit * 3.5 : Mycroft.Units.gridUnit * 2.5
            anchors.right: parent.right
            anchors.rightMargin: Mycroft.Units.gridUnit * 0.5
            anchors.verticalCenter: parent.verticalCenter
            color: Qt.rgba(0.5, 0.5, 0.5, 0.5)
            radius: Mycroft.Units.gridUnit
            z: 2
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if(mainView.currentIndex == 0) {
                    mainView.currentIndex = 1
                } else if (mainView.currentIndex == 1) {
                    mainView.currentIndex = 2
                    boxesView.layoutGrid()
                }
            }
        }
    }

    Item {
        width: Mycroft.Units.gridUnit * 12
        height: Mycroft.Units.gridUnit * 4
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -Mycroft.Units.gridUnit * 2
        anchors.horizontalCenter: parent.horizontalCenter
        visible: mainView.currentIndex == 1
        enabled: mainView.currentIndex == 1
        z: 2

        Rectangle {
                id: bottomAreaHandler
                width: horizontalMode ? Mycroft.Units.gridUnit * 3.5 : Mycroft.Units.gridUnit * 2.5
                height: Mycroft.Units.gridUnit * 0.5
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Mycroft.Units.gridUnit * 0.5
                anchors.horizontalCenter: parent.horizontalCenter
                color: Qt.rgba(0.5, 0.5, 0.5, 0.5)
                radius: Mycroft.Units.gridUnit
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                controlBarItem.open()
            }
        }
    }

    Item {
        width: Mycroft.Units.gridUnit * 4
        height: Mycroft.Units.gridUnit * 12
        anchors.left: parent.left
        anchors.leftMargin: -Mycroft.Units.gridUnit * 2
        anchors.verticalCenter: parent.verticalCenter
        visible: mainView.currentIndex == 1 || mainView.currentIndex == 2
        enabled: mainView.currentIndex == 1 || mainView.currentIndex == 2
        z: 2

        Rectangle {
            id: leftAreaHandler
            width: Mycroft.Units.gridUnit * 0.5
            height: horizontalMode ? Mycroft.Units.gridUnit * 3.5 : Mycroft.Units.gridUnit * 2.5
            anchors.left: parent.left
            anchors.leftMargin: Mycroft.Units.gridUnit * 0.5
            anchors.verticalCenter: parent.verticalCenter
            color: Qt.rgba(0.5, 0.5, 0.5, 0.5)
            radius: Mycroft.Units.gridUnit
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if(mainView.currentIndex == 1) {
                    mainView.currentIndex = 0
                } else if (mainView.currentIndex == 2) {
                    mainView.currentIndex = 1
                }
            }
        }
    }

    StackLayout {
        id: mainView
        currentIndex: 1
        anchors.fill: parent

        NightTimePage {
            id: nightTimeView
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        MainPage {
            id: mainPageView
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        BoxesPage {
            id: boxesView
            Layout.fillWidth: true
            Layout.fillHeight: true
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
