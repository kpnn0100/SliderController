import QtQuick 2.15
import QtQuick.Shapes
import "../Control"
Rectangle
{
    property double trackerX:tracker.x/modelRegion.width*xMaximum
    property double trackerY:(modelRegion.height - tracker.y)/modelRegion.width*xMaximum
    property double position: xyPad.valueX*xMaximum
    property double focal: xyPad.valueY*(focalMaximum-focalMinimum)+focalMinimum
    property double pan: isAutoPanning.isChecked?
                             ((trackerX-position)>0?
                                  180-Math.atan(trackerY/(trackerX-position))/Math.PI*180:
                                  Math.atan(trackerY/Math.abs(trackerX-position))/Math.PI*180
                              )
                           :panSlider.value*panMaximum
    id: middle
    y: header.height
    width: parent.width
    height: parent.height - header.height - footer.height
    color: "transparent"
    //Slide Region
    Rectangle
    {
        id: modelRegion
        anchors.centerIn: parent
        width:parent.width-globalSpacing*10
        height: parent.height-globalSpacing*20
        color: "Transparent"
        border.width: globalStroke/4
        border.color: whiteColor
        //data
        Column
        {
            y: -implicitHeight-globalSpacing/2
            anchors.right: parent.right
            spacing: globalSpacing/4
            CheckBox
            {
                id: isAutoPanning
                text: "Auto panning"
            }
        }
        Item
        {
            id: statusShow
            height:globalSpacing*16
            width: parent.width
            x:globalSpacing/2
            y:globalSpacing/4


            Column
            {
                spacing: globalSpacing/4
                Item {
                    height: globalSpacing
                    width:20
                    Row
                    {
                        Text {
                            text: qsTr("Position: ")
                            color:whiteColor
                            font.pixelSize: globalSpacing
                            font.bold: true
                        }
                        Text {
                            text: position.toFixed(2) + "m"
                            color:whiteColor
                            font.pixelSize: globalSpacing

                        }
                    }
                }
                Item {
                    height: globalSpacing
                    width:20
                    Row
                    {
                        Text {
                            text: qsTr("Focal length: ")
                            color:whiteColor
                            font.pixelSize: globalSpacing
                            font.bold: true
                        }
                        Text {
                            text: focal.toFixed(2) + "mm"
                            color:whiteColor
                            font.pixelSize: globalSpacing

                        }
                    }
                }
                Item {
                    height: globalSpacing
                    width:20
                    Row
                    {
                        Text {
                            text: qsTr("Pan Angle: ")
                            color:whiteColor
                            font.pixelSize: globalSpacing
                            font.bold: true
                        }
                        Text {
                            text: pan.toFixed(2) + "°"
                            color:whiteColor
                            font.pixelSize: globalSpacing

                        }
                    }
                }
            }
        }

        //Tracker
        Item {
            id: tracker
            height: globalSpacing*2
            width: height
            x:parent.width/2
            y:parent.height/2
            visible: opacity
            opacity: isAutoPanning.isChecked
            Column
            {
                anchors.left: parent.right
                anchors.margins: globalSpacing/2
                anchors.verticalCenter: parent.verticalCenter
                Text {

                    text: trackerX.toFixed(2) + "m"
                    font.pixelSize: globalSpacing
                    color:whiteColor
                }
                Text {

                    text: trackerY.toFixed(2) + "m"
                    font.pixelSize: globalSpacing
                    color:whiteColor
                }
            }

            Behavior on opacity
            {
                SmoothedAnimation { velocity:2}
            }

            z:2
            Rectangle
            {
                anchors.fill: parent
                color:"Transparent"
                border.width: globalStroke
                border.color: whiteColor
                radius: height/2
            }
            MouseArea
            {
                anchors.fill: parent
                drag.target: parent
                drag.maximumX: modelRegion.width
                drag.maximumY: modelRegion.height
                drag.minimumX:0
                drag.minimumY:0

            }
            transform: Translate
            {
                x: -tracker.width/2
                y: -tracker.width/2
            }
        }



        //xySlider
        Item {
            id: xyPad
            property double valueX: dummyXYPAD.width/width
            property double valueY: dummyXYPAD.height/height
            property color color: whiteColor
            anchors.fill: parent
            Item
            {
                anchors.fill: parent
                Item
                {
                    id:dummyXYPAD
                    width:0
                    height:0

                }
            }
            MouseArea
            {
                anchors.fill: parent
                onMouseXChanged:
                {
                    dummyXYPAD.width = mouseX
                    if (dummyXYPAD.width>xyPad.width)
                    {
                        dummyXYPAD.width=xyPad.width
                    }
                    if (dummyXYPAD.width<0)
                    {
                        dummyXYPAD.width=0
                    }

                }
                onMouseYChanged:
                {
                    dummyXYPAD.height = xyPad.height-mouseY
                    if (dummyXYPAD.height>xyPad.height)
                    {
                        dummyXYPAD.height=xyPad.height
                    }
                    if (dummyXYPAD.height<0)
                    {
                        dummyXYPAD.height=0
                    }
                }
            }
        }
        //Draw Slider
        Rectangle
        {
            id:slider
            anchors.bottom: parent.bottom
            width: parent.width
            height:globalStroke
            color:whiteColor
        }
        //Draw camera
        Rectangle
        {
            id: camera
            anchors.bottom: parent.bottom
            width: globalSpacing*4
            height:globalSpacing*1.5
            color:mainColor
            radius: height/8
            x: xyPad.valueX*slider.width

            //grip
            Rectangle
            {
                color:mainColor
                height:parent.height*1.2
                anchors.right: parent.right
                width: parent.width/4
                anchors.bottom: parent.bottom
                anchors.rightMargin:-width/2
                radius:height/2
            }

            Behavior on x
            {
                SmoothedAnimation {velocity: 200}
            }
            //BackgroundAngle
            Rectangle
            {
                id:backgroundAngle
                width: modelRegion.height*1.5//+xyPad.valueY*globalSpacing*16
                height: width
                anchors.centerIn: parent
                color: "Transparent"
                z:-1
                opacity:0.2
                Shape {
                    anchors.fill: parent
                    // Enable multisampled rendering
                    layer.enabled: true
                    layer.samples: 4

                    // Outer gray arc:
                    ShapePath {
                        fillColor: lightColor
                        strokeColor: "Transparent"
                        PathAngleArc {
                            centerX: backgroundAngle.width/2; centerY: backgroundAngle.height/2
                            radiusX: backgroundAngle.width/2; radiusY: backgroundAngle.width/2
                            startAngle: -90-sweepAngle/2
                            sweepAngle: 2*Math.atan(diagonal/(2*(xyPad.valueY*(focalMaximum-focalMinimum)+focalMinimum)))/Math.PI*180
                            Behavior on sweepAngle {
                                SmoothedAnimation{
                                    velocity:50
                                }
                            }
                        }
                        PathLine
                        {
                            x: backgroundAngle.width/2
                            y: backgroundAngle.height/2
                        }
                    }


                }
            }
            Rectangle
            {
                id:subBackgroundAngle
                width: modelRegion.height//+xyPad.valueY*globalSpacing*16
                height: width
                anchors.centerIn: parent
                color: "Transparent"
                z:-1
                opacity:0.2
                Shape {
                    anchors.fill: parent
                    // Enable multisampled rendering
                    layer.enabled: true
                    layer.samples: 4

                    // Outer gray arc:
                    ShapePath {
                        fillColor: lightColor
                        strokeColor: "Transparent"
                        PathAngleArc {
                            centerX: subBackgroundAngle.width/2; centerY: subBackgroundAngle.height/2
                            radiusX: subBackgroundAngle.width/2; radiusY: subBackgroundAngle.width/2
                            startAngle: -90-sweepAngle/2
                            sweepAngle: (2*Math.atan(diagonal/(2*(xyPad.valueY*(focalMaximum-focalMinimum)+focalMinimum)))/Math.PI*180)*1.005
                            Behavior on sweepAngle {
                                SmoothedAnimation{
                                    velocity:50
                                }
                            }
                        }
                        PathLine
                        {
                            x: subBackgroundAngle.width/2
                            y: subBackgroundAngle.height/2
                        }
                    }


                }
            }

            Rectangle
            {
                id: lens
                height:parent.height*xyPad.valueY+parent.height/4
                width: parent.width/2
                anchors.horizontalCenter: parent.horizontalCenter
                radius: width/8
                color: lightColor
                antialiasing: true
                y: -height*0.8
                z:-1
                Behavior on height
                {
                    SmoothedAnimation {velocity: 20}
                }
                Rectangle
                {
                    height:parent.height
                    width: parent.width/1.2
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: whiteColor
                    antialiasing: true
                    y: -height*0.8
                    z:-1
                }
            }

            transform: [Translate
                {
                    x: -globalSpacing*2
                    y: globalSpacing
                },
                Rotation
                {
                    origin.x:0
                    origin.y:globalSpacing*1.5
                    angle:isAutoPanning.isChecked?(-90+((trackerX-camera.x/xyPad.width*xMaximum)>0?
                                                        180-Math.atan(trackerY/(trackerX-camera.x/xyPad.width*xMaximum))/Math.PI*180:
                                                        Math.atan(trackerY/Math.abs(trackerX-camera.x/xyPad.width*xMaximum))/Math.PI*180
                    )) : -90+pan


                }
            ]
        }
    }
    //panSlider
    Rectangle
    {
        height:globalSpacing*8
        width:globalSpacing*16
        anchors.top: modelRegion.bottom
        anchors.margins: globalSpacing*2
        anchors.horizontalCenter: parent.horizontalCenter
        color: "Transparent"
        //get value
        Item {
            id: panSlider
            property double value: dummyPanSlider.width/panSlider.width
            property color color: whiteColor
            property double xPressed
            property double yPressed
            anchors.fill: parent

            Item
            {
                id:dummyPanSlider
                width:globalSpacing*8
                height:0

            }

            MouseArea
            {
                anchors.fill: parent
                onPressed:
                {
                    panSlider.xPressed = mouseX
                    panSlider.yPressed = mouseY
                }

                onMouseXChanged:
                {
                    dummyPanSlider.width+=(mouseX-panSlider.xPressed)
                    if (dummyPanSlider.width>panSlider.width)
                    {
                        dummyPanSlider.width=panSlider.width
                    }
                    if (dummyPanSlider.width<0)
                    {
                        dummyPanSlider.width=0
                    }
                    panSlider.xPressed = mouseX

                }
                onMouseYChanged:
                {
                    dummyPanSlider.width+=(panSlider.yPressed-mouseY)
                    if (dummyPanSlider.width>panSlider.width)
                    {
                        dummyPanSlider.width=panSlider.width
                    }
                    if (dummyPanSlider.width<0)
                    {
                        dummyPanSlider.width=0
                    }
                    panSlider.yPressed = mouseY
                }
            }
        }
        Item
        {
            height: parent.width/2
            width: parent.width
            clip:true
            Rectangle
            {
                id: panIndicator
                color:whiteColor
                width:globalStroke
                height:globalSpacing*2
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                antialiasing:true
                transform: Rotation
                {
                    origin.x:globalStroke/2
                    origin.y:globalSpacing*8
                    angle: -90+pan


                }
            }

            Rectangle
            {
                color: "transparent"
                height: parent.width
                width: parent.width
                radius: height/2
                border.color:lightColor
                border.width:globalSpacing*2
                opacity:0.1
            }
        }
    }
}
