import QtQuick
import QtQuick.Shapes
import QtQuick.Window 2.2
import "Control"
import "View"
import BluetoothManager
Window {
    id: mainWindow
    width: 360
    height: 640
    visible: true
    title: qsTr("Hello World")
    property double position: manualHorizontal.position
    property double focal: manualHorizontal.focal
    property double pan: manualHorizontal.pan
    property double tilt: manualHorizontal.tilt
    onPositionChanged:
    {
        bleManager.write("x");
        bleManager.write(mainWindow.position);
        bleManager.write("\n");
    }
    onFocalChanged:
    {
        bleManager.write("f");
        bleManager.write(mainWindow.focal);
        bleManager.write("\n");
    }
    onPanChanged:
    {
        bleManager.write("p");
        bleManager.write(mainWindow.pan);
        bleManager.write("\n");
    }
    onTiltChanged:
    {
        bleManager.write("t");
        bleManager.write(mainWindow.tilt);
        bleManager.write("\n");
    }
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
    property double tiltMaximum: 30
    property double panMaximum: 180
    property double focalMinimum: 18
    property double focalMaximum: 55
    property double cropFactor: 1.0
    property double diagonal: 43.2666153056/1.0
    color: backGroundColor
    BluetoothManager
    {
        id:bleManager
    }

    Item
    {
        id:header
        anchors.top: parent.top
        anchors.left: parent.left
        width: parent.width
        height: mainWindow.height/16
        Row
        {
            anchors.fill:parent
            Rectangle
            {

                width: parent.width/2
                height: mainWindow.height/16
                color: "transparent"
                radius: height/2
                Text {
                    id: sliderText
                    text: qsTr("Slider")
                    x:parent.height/2
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: parent.height/2
                    font.bold: true
                    color: whiteColor
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("Controller")
                    font.pixelSize: parent.height/2
                    color: whiteColor
                    x: sliderText.contentWidth+sliderText.x
                }
            }
            Item
            {
                id:connectRegion
                width:parent.width-x
                height: parent.height
                Rectangle
                {
                    id: connectedButtonDummy
                    anchors.fill: parent
                    color:whiteColor
                    opacity: 0
                    Behavior on opacity
                    {
                        SmoothedAnimation {velocity:1}
                    }
                }
                Text {
                    id: connectStatus
                    anchors.centerIn: parent
                    color:whiteColor
                    font.bold:true
                    font.pixelSize: mainWindow.globalSpacing
                    text: qsTr("Connect")
                }
                MouseArea
                {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked:
                    {
                        bleManager.findAndConnectSlider();
                    }

                    onEntered:
                    {
                        connectedButtonDummy.opacity=0.2
                    }
                    onExited:
                    {
                        connectedButtonDummy.opacity=0
                    }
                }
            }
        }
    }

    ManualHorizontal
    {
        id: manualHorizontal
        y: header.height+globalSpacing*2
        width: parent.width
        height: parent.height - header.height - footer.height
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
