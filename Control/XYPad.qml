import QtQuick

Item {
    id: panSlider
    property double valueX: dummyPanSlider.width/panSlider.width
        property double valueY: dummyPanSlider.height/panSlider.height
    property double defaultX:0
    property double defaultY:0
    property color color: whiteColor
    property double xPressed
    property double yPressed
    anchors.fill: parent

    Item
    {
        id:dummyPanSlider
        width:defaultX*parent.width
        height:defaultY*parent.height
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

            if (dummyPanSlider.width+(mouseX-panSlider.xPressed)>panSlider.width)
            {
                dummyPanSlider.width=panSlider.width
            }
            else
            if (dummyPanSlider.width+(mouseX-panSlider.xPressed)<0)
            {
                dummyPanSlider.width=0
            }
            else
            dummyPanSlider.width+=(mouseX-panSlider.xPressed)
            panSlider.xPressed = mouseX

        }
        onMouseYChanged:
        {

            if (dummyPanSlider.height+(panSlider.yPressed-mouseY)>panSlider.height)
            {
                dummyPanSlider.height=panSlider.height
            }
            else
            if (dummyPanSlider.height+(panSlider.yPressed-mouseY)<0)
            {
                dummyPanSlider.height=0
            }
            else
                dummyPanSlider.height+=(panSlider.yPressed-mouseY)
            panSlider.yPressed = mouseY
        }
    }
}

