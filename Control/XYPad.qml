import QtQuick

Item {
    property color color: "White"
    width:100
    height:100
    Rectangle
    {
        anchors.fill: parent
        color: parent.color
    }
}
