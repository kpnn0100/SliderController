import QtQuick
import QtQuick.Shapes
import QtQuick.Window 2.2
import "Control"
import "View"
import BluetoothManager
import QtQuick.Controls
Window {
    id: mainWindow
    visibility: Window.FullScreen
    //    height:720
    //    width:1280
    visible: true
    title: qsTr("Hello World")
    property double position: bar.currentIndex == 0 ? manualHorizontal.position : autoHorizontal.pos
    property double focal: bar.currentIndex == 0 ? manualHorizontal.focal : autoHorizontal.focal
    property double pan: bar.currentIndex == 0 ? manualHorizontal.pan : autoHorizontal.pan
    property double tilt: bar.currentIndex == 0 ? manualHorizontal.tilt : autoHorizontal.tilt
    onPositionChanged:
    {
        bleManager.blockCall()
        bleManager.write("x");
        bleManager.writeDouble(mainWindow.position);
        bleManager.unlockCall();
        console.log("move: x :" + mainWindow.position )
    }
//    onFocalChanged:
//    {
//        bleManager.blockCall()
//        bleManager.write("f");
//        bleManager.write(mainWindow.focal);
//        bleManager.unlockCall();
//        console.log("move: focal :" + mainWindow.focal )
//    }
    onPanChanged:
    {
        bleManager.blockCall()
        bleManager.write("p");
        bleManager.writeDouble(mainWindow.pan);
        bleManager.unlockCall();
        console.log("move: pan :" + mainWindow.pan )
    }
    onTiltChanged:
    {
        bleManager.blockCall()
        bleManager.write("t");
        bleManager.writeDouble(mainWindow.tilt);
        bleManager.unlockCall();
        console.log("move: tilt :" + mainWindow.tilt )
    }
    property color backGroundColor: "#151717"
    property color darkBackGroundColor: "#0a0a0a"
    property color whiteColor: "#f2f2f2"

    property color darkColor: "#2E4F4F"
    property color mainColor: "#0E8388"
    property color mainColorLowContrast: "#82b8ba"
    property color mainColor2: "#9E4784"
    property color mainColor3: "#a8731e"
    property color redColor: "#a8251e"
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
                    text: bleManager.status
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
    Item
    {
        y: header.height
        height:parent.height-header.height
        width:parent.width
        Item {
            id: bar
            width: parent.width
            height: globalSpacing*3
            anchors.top: parent.top
            property int currentIndex: 1
            Row
            {
                anchors.fill:parent
                Rectangle
                {
                    id:manualButton
                    width:parent.width/2
                    height:parent.height
                    color:bar.currentIndex === 0 ? mainColor : whiteColor

                    Text {
                        text: qsTr("Manual")
                        font.pixelSize: globalSpacing*1.5
                        anchors.centerIn: parent
                        color:bar.currentIndex === 0 ? whiteColor : mainColorLowContrast
                        font.bold: true
                    }
                    MouseArea
                    {
                        anchors.fill: parent
                        onClicked:
                        {
                            bar.currentIndex=0;
                        }
                    }
                }

                Rectangle
                {
                    id:autoButton
                    width:parent.width/2
                    height:parent.height
                    color:bar.currentIndex === 1 ? mainColor : whiteColor
                    Text {
                        text: qsTr("Automatic")
                        font.pixelSize: globalSpacing*1.5
                        anchors.centerIn: parent
                        color:bar.currentIndex === 1 ? whiteColor : mainColorLowContrast
                        font.bold: true
                    }
                    MouseArea
                    {
                        anchors.fill: parent
                        onClicked:
                        {
                            bar.currentIndex=1;
                        }
                    }
                }
            }
        }
        SwipeView {
            y:bar.height
            height:parent.height - y
            width:parent.width
            currentIndex: bar.currentIndex
            Component.onCompleted: contentItem.interactive = false
            Item
            {
                ManualHorizontal
                {
                    id: manualHorizontal
                    y: globalSpacing*2
                    width: parent.width
                    height: parent.height - footer.height

                }
            }
            Item {
                AutoHorizontal
                {
                    id: autoHorizontal
                    y: header.height+globalSpacing*2
                    width: parent.width
                    height: parent.height - header.height - footer.height
                }
            }
            Item {
                id: activityTab
            }
        }
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
