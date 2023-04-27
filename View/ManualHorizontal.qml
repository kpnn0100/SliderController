import QtQuick 2.15
import QtQuick.Shapes
import "../Control"
Rectangle
{
    property double trackerX:xyPad.valueX*xMaximum
    property double trackerY:xyPad.valueY*modelRegion.height/modelRegion.width*xMaximum
    property double position: leftPad.valueX*xMaximum
    property double focal: leftPad.valueY*(focalMaximum-focalMinimum)+focalMinimum
    property double tilt: rightPad.valueY*tiltMaximum*2 - tiltMaximum
    property double pan: isAutoPanning.isChecked?
                             ((trackerX-position)>0?
                                  180-Math.atan(trackerY/(trackerX-position))/Math.PI*180:
                                  Math.atan(trackerY/Math.abs(trackerX-position))/Math.PI*180
                              )
                           :rightPad.valueX*panMaximum
    id: middle

    color: "transparent"
    //Slide Region
    Rectangle
    {
        id: modelRegion
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent
        anchors.margins: globalSpacing
        width:parent.width-globalSpacing*10
        height: parent.height-leftPadRegion.height-4*globalSpacing
        color: "Transparent"
        border.width: globalStroke/4
        border.color: whiteColor
        //data
        Column
        {
            y: implicitHeight-globalSpacing/2
            anchors.right: parent.right
            anchors.margins: globalSpacing/2
            spacing: globalSpacing/4
            z:4
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
                //Indicator
                //Position
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
                //Focal
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
                //Pan
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
                //tilt
                Item {
                    height: globalSpacing
                    width:20
                    Row
                    {
                        Text {
                            text: qsTr("Tilt Angle: ")
                            color:whiteColor
                            font.pixelSize: globalSpacing
                            font.bold: true
                        }
                        Text {
                            text: tilt.toFixed(2) + "°"
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
            x:xyPad.valueX*modelRegion.width
            y:(1-xyPad.valueY)*modelRegion.height
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
                    width:parent.width/2
                    height:parent.height/2

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
            x: leftPad.valueX*slider.width

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
                            id: mainPathAngleArc
                            centerX: backgroundAngle.width/2; centerY: backgroundAngle.height/2
                            radiusX: backgroundAngle.width/2; radiusY: backgroundAngle.width/2
                            startAngle: -90-sweepAngle/2
                            sweepAngle: 2*Math.atan(diagonal/(2*(leftPad.valueY*(focalMaximum-focalMinimum)+focalMinimum)))/Math.PI*180
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
                            sweepAngle: mainPathAngleArc.sweepAngle*1.005
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
                height:parent.height*leftPad.valueY+parent.height/4
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
    //X and zoom
    Rectangle
    {
        id: leftPadRegion
        height:globalSpacing*8
        width:modelRegion.width/2-globalSpacing
        anchors.top: modelRegion.bottom
        anchors.left: modelRegion.left
        anchors.topMargin: globalSpacing*2
        border.color: "white"
        border.width:globalStroke/2
        color:"Transparent"
        //get value
        Text {
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.rightMargin: font.pixelSize/4
            text: qsTr("Position")
            font.pixelSize: globalSpacing
            color:whiteColor
            font.bold: true

        }
        XYPad
        {
            id: leftPad
            anchors.fill: parent
        }
    }
    Rectangle
    {
        id: rightPadRegion
        height:globalSpacing*8
        width:modelRegion.width/2-globalSpacing
        anchors.top: modelRegion.bottom
        anchors.right: modelRegion.right
        anchors.topMargin: globalSpacing*2
        border.color: "white"
        border.width:globalStroke/2
        color:"Transparent"
        //get value
        XYPad
        {
            defaultX:0.5
            defaultY:0.5
            id: rightPad
            anchors.fill: parent
        }
    }
}
