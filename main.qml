import QtQuick
import QtQuick.Shapes
import "Control"
import "View"
Window {
    id: mainWindow
    width: 540
    height: 960
    visible: true
    title: qsTr("Hello World")
    property double position: manualHorizontal.position
    property double focal: manualHorizontal.focal
    property double pan: manualHorizontal.pan
    property color backGroundColor: "#151717"
    property color whiteColor: "#f2f2f2"
    property color darkColor: "#2E4F4F"
    property color mainColor: "#0E8388"
        property color mainColor2: "#9E4784"
    property color lightColor: "#CBE4DE"
    property color lightBackgroundColor: "#414545"
    property double globalSpacing: height/64
    property double globalStroke: globalSpacing/4
    property double xMaximum: 2.0
    property double panMaximum: 180
    property double focalMinimum: 18
    property double focalMaximum: 55
    property double cropFactor: 1.0
    property double diagonal: 43.2666153056/1.0
    color: backGroundColor
    Item
    {
        id:header
        anchors.top: parent.top
        anchors.left: parent.left
        width: parent.width
        height: mainWindow.height/16
        Rectangle
        {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: globalSpacing
            width: parent.width/2
            height: mainWindow.height/16
            color: "transparent"
            radius: height/2
            Text {
                id: sliderText
                text: qsTr("Slider")
                font.pixelSize: parent.height/2
                font.bold: true
                color: whiteColor
            }
            Text {
                text: qsTr("Controller")
                font.pixelSize: parent.height/2
                color: whiteColor
                x: sliderText.contentWidth
            }
        }
    }
    ManualHorizontal
    {
        id: manualHorizontal
    }

    Rectangle
    {
        id: footer
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        height: mainWindow.height/32
        color: "Transparent"
    }
}
