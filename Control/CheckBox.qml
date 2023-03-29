import QtQuick

Item {
    id:main
    height:globalSpacing*1.2
    width:height
    property bool isChecked: false
    property string text: "[replace]"
    Text {
        anchors.right: checkBox.left
        anchors.verticalCenter: checkBox.verticalCenter
        text: main.text
        anchors.margins: globalSpacing/2
        color:whiteColor
        font.pixelSize: parent.height
    }
    Rectangle
    {
        id:checkBox
        anchors.fill: parent
        color:"Transparent"
        border.color: whiteColor
        border.width:globalStroke/2
        clip:true

        Rectangle
        {
            width:isChecked ? parent.height*2:0
            height:width
            anchors.centerIn: parent
            radius: height/2
            Behavior on width
            {
                PropertyAnimation
                {
                    duration: 400
                    easing.type: Easing.InOutCubic
                }
            }


            color:whiteColor
        }
        MouseArea
        {
            anchors.fill: parent
            onClicked:
            {
                main.isChecked = !main.isChecked
            }
        }
    }
}
