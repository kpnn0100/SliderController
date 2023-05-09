import QtQuick

Item {
    id: xyPad
    property double valueX: dummyXYPAD.width/width
    property double valueY: dummyXYPAD.height/height
    property color color: whiteColor
    function setX(newX)
    {
        dummyXYPAD.width=xyPad.width*newX
    }
    function setY(newY)
    {
        dummyXYPAD.height=xyPad.height*newY
    }
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
