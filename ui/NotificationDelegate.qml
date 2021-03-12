import QtQuick.Layouts 1.4
import QtQuick 2.4
import QtQuick.Controls 2.0
import org.kde.kirigami 2.4 as Kirigami
import QtGraphicalEffects 1.0
import Mycroft 1.0 as Mycroft

Rectangle {
    id: delegate
    color: "#313131"
    radius: 10
    readonly property ListView listView: ListView.view
    width: listView.width
    height: listView.height * 0.15 < minimumHeight ? minimumHeight : listView.width * 0.15
    property int minimumHeight: 100

    
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
                text: modelData.sender
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
                text: modelData.text
                Layout.fillWidth: true
                Layout.preferredHeight: paintedHeight
                color: "#ffffff"
            }
        }
        
        Button {
            Layout.preferredWidth: Kirigami.Theme.iconSizes.Large
            Layout.preferredHeight: width
            icon.source: Qt.resolvedUrl("img/delete.svg")
        }
    }
} 
