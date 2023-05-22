import QtQuick 2.15
import QtQuick.Shapes
import QtQuick.Controls
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
    Dialog {
        id: dialog
        title: "Set tracker's position"
        width: 300
        height: 200
        modal: true
        anchors.centerIn: parent
        property real xValue: 0.0
        property real yValue: 0.0
        property real zValue: 0.0

        onAccepted: {
            // Save the values entered by the user
            dialog.xValue = parseFloat(xInput.text)
            dialog.yValue = parseFloat(yInput.text)
            dialog.zValue = parseFloat(zInput.text)
        }

        contentItem: Column {
            spacing: 10
            Row {
                spacing: 10
                Label {
                    text: "X:"
                }
                TextField {
                    id: xInput

                    text: dialog.xValue.toString()
                }
            }
            Row {
                spacing: 10
                Label {
                    text: "Y:"
                }
                TextField {
                    id: yInput

                    text: dialog.yValue.toString()
                }
            }
            Row {
                spacing: 10
                Label {
                    text: "Z:"
                }
                TextField {
                    id: zInput

                    text: dialog.zValue.toString()
                }
            }
        }
        standardButtons: Dialog.Ok | Dialog.Cancel
    }
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
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: globalSpacing/2
            spacing: globalSpacing/2
            z:4
            CheckBox
            {
                id: isAutoPanning
                text: "Auto panning"
            }
            CheckBox
            {
                id: isAutoTilt
                text: "Auto tilt"
                visible: opacity
                opacity: isAutoPanning.isChecked ? 1:0
                Behavior on opacity {
                    SmoothedAnimation {velocity: 5}
                }
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

                    text: "x: " + trackerX.toFixed(2) + "m"
                    font.pixelSize: globalSpacing
                    color:whiteColor
                }
                Text {

                    text: "y: " + trackerY.toFixed(2) + "m"
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
        XYPadLinear {
            id: xyPad
            property color color: whiteColor
            anchors.fill: parent
            MouseArea
            {
                anchors.fill: parent
                onDoubleClicked:
                {
                    dialog.open()
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
        //Draw background camera for tilt
        Item
        {
            id: backgroundCamera
            anchors.centerIn: parent
            height: parent.width>parent.height? parent.height/2:parent.width/2
            width:height

            Item
            {
                height:parent.height
                width:height
                anchors.centerIn: parent
                transform: Rotation {
                    origin.x: backgroundCamera.width/2; origin.y: backgroundCamera.height/2; angle: -tilt
                    Behavior on angle
                    {
                        SmoothedAnimation {velocity:200}
                    }
                }
                antialiasing: true
                opacity: 0.1
                Rectangle
                {
                    width: parent.width/4
                    height:parent.height/2
                    anchors.centerIn: parent
                    color:whiteColor
                    antialiasing: true
                    Rectangle
                    {
                        anchors.left: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: -globalSpacing/10
                        height:parent.height/1.5
                        width:parent.width/3
                        color: whiteColor
                        antialiasing: true
                        Rectangle
                        {
                            anchors.left: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: -globalSpacing/10
                            height:parent.height/1.2
                            width:parent.width*2
                            color: whiteColor
                            antialiasing: true
                        }
                    }
                }
            }
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

                    Behavior on angle
                    {
                        SmoothedAnimation {velocity:200}
                    }
                }
            ]
        }
    }
    //X and zoom
    Item {
        id: controlPad
        height:globalSpacing*8
        width:modelRegion.width
        anchors.horizontalCenter: modelRegion.horizontalCenter
        anchors.top: modelRegion.bottom
        anchors.topMargin: globalSpacing*2
        MultiPointTouchArea
        {
            anchors.fill: parent
            id: multiTouchPadHandler
            property TouchPoint leftPoint
            property TouchPoint rightPoint
            property int leftHold: 0
            property int rightHold: 0
            touchPoints: [
                TouchPoint { id: point1 },
                TouchPoint { id: point2 }
            ]
            onPressed: (points) =>
                       {
                           if (!(leftHold || rightHold))
                           {
                               if (point1.x<leftPadRegion.width && point1.y<leftPadRegion.height)
                               {
                                   multiTouchPadHandler.leftPoint = Qt.binding(function () { return point1})
                                   multiTouchPadHandler.leftPoint.xChanged.connect(multiTouchPadHandler.leftPointXHandler)
                                   multiTouchPadHandler.leftPoint.yChanged.connect(multiTouchPadHandler.leftPointYHandler)
                                   oldLeftX = leftPoint.x
                                   oldLeftY = leftPoint.y
                                   leftHold = 1
                               }
                               else
                               if (point1.x>rightPadRegion.x
                                   && point1.x<(rightPadRegion.x + rightPadRegion.width)
                                   && point1.y<(rightPadRegion.height))
                               {
                                   multiTouchPadHandler.rightPoint = Qt.binding(function () { return point1})
                                   multiTouchPadHandler.rightPoint.xChanged.connect(multiTouchPadHandler.rightPointXHandler)
                                   multiTouchPadHandler.rightPoint.yChanged.connect(multiTouchPadHandler.rightPointYHandler)
                                   oldRightX = rightPoint.x
                                   oldRightY = rightPoint.y
                                   rightHold = 1
                               }
                           }
                           else
                           {
                                console.log("point 2 activated")
                               if (point2.x<leftPadRegion.width && point2.y<leftPadRegion.height)
                               {
                                   console.log("point 2 is left")
                                   multiTouchPadHandler.leftPoint = Qt.binding(function () { return point2})
                                   multiTouchPadHandler.leftPoint.xChanged.connect(multiTouchPadHandler.leftPointXHandler)
                                   multiTouchPadHandler.leftPoint.yChanged.connect(multiTouchPadHandler.leftPointYHandler)
                                   leftHold = 2
                                   oldLeftX = leftPoint.x
                                   oldLeftY = leftPoint.y
                               }
                               else
                               if (point2.x>rightPadRegion.x
                                   && point2.x<(rightPadRegion.x + rightPadRegion.width)
                                   && point2.y<(rightPadRegion.height))
                               {
                                   console.log("point 2 is right")
                                   multiTouchPadHandler.rightPoint = Qt.binding(function () { return point2})
                                   multiTouchPadHandler.rightPoint.xChanged.connect(multiTouchPadHandler.rightPointXHandler)
                                   multiTouchPadHandler.rightPoint.yChanged.connect(multiTouchPadHandler.rightPointYHandler)
                                   oldRightX = rightPoint.x
                                   oldRightY = rightPoint.y
                                   rightHold = 2
                               }
                           }

                           //               if (point1.x<leftPadRegion.width && point1.y<leftPadRegion.height)
                           //              {
                           //                   leftPoint = point1
                           //              }
                       }
            onReleased:
            {
                if (!point1.pressed)
                {
                    if (leftHold === 1)
                    {
                        multiTouchPadHandler.leftPoint.xChanged.disconnect(multiTouchPadHandler.leftPointXHandler)
                        multiTouchPadHandler.leftPoint.yChanged.disconnect(multiTouchPadHandler.leftPointYHandler)
                        leftHold = 0
                    }
                    if (rightHold === 1)
                    {
                        multiTouchPadHandler.rightPoint.xChanged.disconnect(multiTouchPadHandler.rightPointXHandler)
                        multiTouchPadHandler.rightPoint.yChanged.disconnect(multiTouchPadHandler.rightPointYHandler)
                        rightHold = 0
                    }
                }
                if (!point2.pressed)
                {
                    if (leftHold === 2)
                    {
                        multiTouchPadHandler.leftPoint.xChanged.disconnect(multiTouchPadHandler.leftPointXHandler)
                        multiTouchPadHandler.leftPoint.yChanged.disconnect(multiTouchPadHandler.leftPointYHandler)
                        leftHold = 0
                    }
                    if (rightHold === 2)
                    {
                        multiTouchPadHandler.rightPoint.xChanged.disconnect(multiTouchPadHandler.rightPointXHandler)
                        multiTouchPadHandler.rightPoint.yChanged.disconnect(multiTouchPadHandler.rightPointYHandler)
                        rightHold = 0
                    }
                }
            }
            property double oldLeftX
            property double oldLeftY
            property double oldRightX
            property double oldRightY
            function leftPointXHandler()
            {
//                console.log("left x "+ leftPoint.x)
                if (dummyLeftPad.width+(leftPoint.x-oldLeftX)>leftPad.width)
                {
                    dummyLeftPad.width=leftPad.width
                }
                else
                if (dummyLeftPad.width+(leftPoint.x-oldLeftX)<0)
                {
                    dummyLeftPad.width=0
                }
                else
                dummyLeftPad.width+=(leftPoint.x-oldLeftX)
               oldLeftX= leftPoint.x

            }
            function rightPointXHandler()
            {
//                                console.log("right x "+ rightPoint.x)
                if (dummyRightPad.width+(rightPoint.x-oldRightX)>rightPad.width)
                {
                    dummyRightPad.width=rightPad.width
                }
                else
                if (dummyRightPad.width+(rightPoint.x-oldRightX)<0)
                {
                    dummyRightPad.width=0
                }
                else
                dummyRightPad.width+=(rightPoint.x-oldRightX)
               oldRightX= rightPoint.x
            }
            function leftPointYHandler()
            {
//                                console.log("left y"+ leftPoint.y)
                if (dummyLeftPad.height+(oldLeftY-leftPoint.y)>leftPad.height)
                {
                    dummyLeftPad.height=leftPad.height
                }
                else
                if (dummyLeftPad.height+(oldLeftY-leftPoint.y)<0)
                {
                    dummyLeftPad.height=0
                }
                else
                dummyLeftPad.height+=(oldLeftY-leftPoint.y)
               oldLeftY= leftPoint.y
            }
            function rightPointYHandler()
            {
//                console.log("right y"+ rightPoint.y)
                if (dummyRightPad.height+(oldRightY-rightPoint.y)>rightPad.height)
                {
                    dummyRightPad.height=rightPad.height
                }
                else
                if (dummyRightPad.height+(oldRightY-rightPoint.y)<0)
                {
                    dummyRightPad.height=0
                }
                else
                dummyRightPad.height+=(oldRightY-rightPoint.y)
               oldRightY= rightPoint.y
            }
        }

        Rectangle
        {
            id: leftPadRegion
            height:globalSpacing*8
            width:parent.width/2-globalSpacing

            anchors.left: parent.left
            border.color: "white"
            border.width:globalStroke/2
            color:"Transparent"
            //get value
            Text {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.leftMargin: globalSpacing
                transform: Rotation { origin.x: 0; origin.y: globalSpacing/2; angle: 90}
                text: qsTr("Focal")
                font.pixelSize: globalSpacing
                color:whiteColor
                font.bold: true

            }
            Text {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.rightMargin: font.pixelSize/4
                text: qsTr("Position")
                font.pixelSize: globalSpacing
                color:whiteColor
                font.bold: true

            }
            Item {
                id: leftPad
                anchors.fill: parent
                property double valueX: dummyLeftPad.width/width
                property double valueY: dummyLeftPad.height/height
                property double defaultX:0
                property double defaultY:0
                property double xPressed
                property double yPressed
                Item
                {
                    id:dummyLeftPad
                    width:leftPad.defaultX*parent.width
                    height:leftPad.defaultY*parent.height
                }
            }

        }
        Rectangle
        {
            id: rightPadRegion
            height:globalSpacing*8
            width:parent.width/2-globalSpacing

            anchors.right: parent.right

            border.color: "white"
            border.width:globalStroke/2
            color:"Transparent"
            //get value
            Text {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.leftMargin: globalSpacing
                transform: Rotation { origin.x: 0; origin.y: globalSpacing/2; angle: 90}
                text: qsTr("Tilt")
                font.pixelSize: globalSpacing
                color:whiteColor
                font.bold: true

            }
            Text {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.rightMargin: font.pixelSize/4
                text: qsTr("Pan")
                font.pixelSize: globalSpacing
                color:whiteColor
                font.bold: true

            }
            Item {
                id: rightPad
                anchors.fill: parent
                property double valueX: dummyRightPad.width/width
                property double valueY: dummyRightPad.height/height
                property double defaultX:0.5
                property double defaultY:0
                property double xPressed
                property double yPressed
                Item
                {
                    id:dummyRightPad
                    width:rightPad.defaultX*parent.width
                    height:rightPad.defaultY*parent.height
                }
            }
        }
    }
}
