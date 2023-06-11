import QtQuick 2.15
import QtQuick.Shapes
import QtQuick.Controls
import QtQuick.Dialogs
import Qt.labs.settings 1.0
import FileManager
import "../Control"
Item {
    id: mainItem
    anchors.fill: parent
    property real pos: keyframeList.get(keyframeListView.currentIndex).position
    property real focal:keyframeList.get(keyframeListView.currentIndex).focal
    property real pan: keyframeList.get(keyframeListView.currentIndex).pan
    property real tilt: keyframeList.get(keyframeListView.currentIndex).tilt
    property bool isPlaying: false
    property bool isAtBegining: true
    property url currentScriptPath: null
    property string videoName
    property string scriptName
    FileManager
    {
        id: fileManager
    }

    onCurrentScriptPathChanged:
    {
        var nameSplit = currentScriptPath.toString().split('/')
        mainItem.videoName =  nameSplit[nameSplit.length-2]
        mainItem.scriptName =  nameSplit[nameSplit.length-1]
        keyframeListView.currentIndex=0
        mainItem.updateView()
    }

    signal saveKeyframe()
    signal addKeyframe()
    signal deleteKeyframe()
    signal playScript()
    signal stopScript()
    signal restartScript()
    signal sendScript()
    signal saveScript()
    signal newScript()
    signal openScript()
    function saveListModelToJson(listModel, filePath) {
        var variantMapList = [];
        for (var i = 0; i < listModel.count; i++) {
            var variantMap = {};
            for (var role in listModel.get(i)) {
                variantMap[role] = listModel.get(i)[role];
            }
            variantMapList.push(variantMap);
        }

        fileManager.saveFile(variantMapList,filePath)
    }
    function openFile(filePath) {
        var variantMapList = fileManager.loadFile(filePath);
        keyframeList.clear()
        for (var map in variantMapList)
        {
            keyframeList.append(variantMapList[map])
        }
    }
    function updateView()
    {

        timeTextInput.text = keyframeList.get(keyframeListView.currentIndex).time;
        positionTextInput.text = keyframeList.get(keyframeListView.currentIndex).position;
        focalTextInput.text = keyframeList.get(keyframeListView.currentIndex).focal;
        panTextInput.text = keyframeList.get(keyframeListView.currentIndex).pan;
        tiltTextInput.text = keyframeList.get(keyframeListView.currentIndex).tilt;
        ingoingTextInput.text = keyframeList.get(keyframeListView.currentIndex).ingoing;
        outgoingTextInput.text = keyframeList.get(keyframeListView.currentIndex).outgoing;
        nameTextInput.text = keyframeList.get(keyframeListView.currentIndex).keyframeName
        descriptionTextInput.text = keyframeList.get(keyframeListView.currentIndex).keyframeDescription
    }

    FileDialog
    {
        id: saveFileDialog
        fileMode :FileDialog.SaveFile
        defaultSuffix: "scst" //Slider Controller Script
        onAccepted:
        {
            mainItem.saveScript()
            keyframeList.clear()
            var url = selectedFile.toString().replace(/^(file:\/{3})/,"");
            saveListModelToJson(keyframeList,url)
            console.log(url)
            mainItem.currentScriptPath = url
        }
    }
    FileDialog
    {
        id: openFileDialog
        fileMode :FileDialog.OpenFile
        defaultSuffix: "scst" //Slider Controller Script
        onAccepted:
        {
            var url = selectedFile.toString().replace(/^(file:\/{3})/,"");
            openFile(url)
            console.log(url)
            mainItem.currentScriptPath = url
        }
    }
    onSaveScript:
    {
        if (currentScriptPath != null)
        {
            saveListModelToJson(keyframeList,currentScriptPath)
        }
    }

    onNewScript:
    {
        saveFileDialog.open()
    }

    onSendScript:
    {

    }

    onPlayScript:
    {
        mainItem.isPlaying = true
    }
    onStopScript:
    {
        mainItem.isPlaying = false
    }
    onRestartScript:
    {
        keyframeListView.currentIndex = 0;
    }
    onOpenScript:
    {
        openFileDialog.open()
    }

    function updateKeyframeList()
    {
        if (keyframeList.get(0).time !== 0)
        {
            keyframeList.insert(0,keyframeList.get(0));
            keyframeList.get(0).time=0;
        }

        for (var i = 0; i<keyframeList.count;i++)
        {
            for (var j = i; j<keyframeList.count;j++)
            {
                if (keyframeList.get(j).time < keyframeList.get(i).time)
                {
                    keyframeList.move(j,i,1);
                }
            }
        }
    }

    onSaveKeyframe:
    {

        if (keyframeListView.currentIndex >-1)
        {
            console.log("Saving keyframe")
            keyframeList.setProperty(keyframeListView.currentIndex, "time", parseFloat(timeTextInput.text))
            keyframeList.setProperty(keyframeListView.currentIndex, "position", parseFloat(positionTextInput.text))
            keyframeList.setProperty(keyframeListView.currentIndex, "focal", parseFloat(focalTextInput.text))
            keyframeList.setProperty(keyframeListView.currentIndex,"pan", parseFloat(panTextInput.text))
            keyframeList.setProperty(keyframeListView.currentIndex,"tilt" ,  parseFloat(tiltTextInput.text))
            keyframeList.setProperty(keyframeListView.currentIndex,"ingoing",parseFloat(ingoingTextInput.text))
            keyframeList.setProperty(keyframeListView.currentIndex, "outgoing",parseFloat(outgoingTextInput.text))
            keyframeList.setProperty(keyframeListView.currentIndex, "keyframeName", nameTextInput.text)
            keyframeList.setProperty(keyframeListView.currentIndex, "keyframeDescription" ,descriptionTextInput.text)
            updateKeyframeList()
        }
        mainItem.saveScript()
    }
    onDeleteKeyframe:
    {
        if (keyframeListView.currentIndex >-1)
        {
            keyframeList.remove(keyframeListView.currentIndex)
            keyframeListView.currentIndex = -1
            timeTextInput.text = ""
            positionTextInput.text = ""
            focalTextInput.text = ""
            panTextInput.text = ""
            tiltTextInput.text = ""
            ingoingTextInput.text =""
            outgoingTextInput.text = ""
            nameTextInput.text = ""
            descriptionTextInput.text = ""
        }
    }
    onAddKeyframe:
    {
        if (keyframeListView.count === 0)
        {
            keyframeList.append({})
        }
        else
            if (keyframeListView.currentIndex >-1)
            {
                keyframeList.append(keyframeList.get(keyframeListView.currentIndex))
            }
            else
            {
                keyframeList.append(keyframeList.get(keyframeList.count-1))
            }
    }

    ListModel
    {

        id: keyframeList
        ListElement
        {
            //            time: 0
            //            position: 0.75
            //            focal: 18
            //            pan: 90
            //            tilt: 0
            //            ingoing: 0.5
            //            outgoing: 0.5
            keyframeName: "Blank"
            //            keyframeDescription: "Cảnh này làm hành động 1"

        }
        //        ListElement
        //        {
        //            time: 4
        //            position: 0.20
        //            focal: 18
        //            pan: 150
        //            tilt: 0
        //            ingoing: 0.5
        //            outgoing: 0.5
        //            keyframeName: "Diễn viên di chuyển"
        //            keyframeDescription: "Cảnh này làm hành động 2"
        //        }
    }

    Item
    {

        id: mainRegion
        anchors.centerIn: parent
        width: parent.width*0.95
        height: parent.height*0.9
        Item {
            id: controlRegion
            height:parent.height
            width: parent.width/3 *2
            anchors.left: parent.left
            Item {
                anchors.fill: parent
                anchors.leftMargin: globalSpacing
                anchors.rightMargin: globalSpacing
                Column
                {
                    anchors.fill: parent
                    spacing: globalSpacing
                    Item
                    {
                        width: parent.width
                        height: parent.height/3
                        Row
                        {
                            width: parent.width
                            height: videoNameText.contentHeight +globalSpacing
                            Rectangle
                            {
                                id: videoNameRegion
                                width: parent.width/2
                                height: parent.height
                                color: mainColor
                                clip: true
                                Text {
                                    id: videoNameText
                                    text: videoName
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.margins: globalSpacing/2
                                    font.bold: true
                                    font.pixelSize: globalSpacing*2
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color:whiteColor
                                }
                            }
                            Rectangle
                            {
                                id: scriptNameRegion
                                width: parent.width-x-parent.height
                                height: parent.height
                                color: whiteColor
                                clip: true
                                Text {
                                    id: scriptNameText
                                    text: scriptName
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.margins: globalSpacing/2
                                    font.bold: true
                                    font.pixelSize: globalSpacing*2
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color:mainColor
                                }
                                MouseArea
                                {
                                    anchors.fill: parent
                                    onClicked:
                                    {
                                        mainItem.openScript()
                                    }
                                }
                            }
                            Rectangle
                            {
                                id: newScriptButton
                                width: parent.width - x
                                height:parent.height
                                color: mainColor2
                                Image {

                                    source: "qrc:/icon/resource/add.png"
                                    anchors.fill: parent
                                    anchors.margins: globalSpacing/2
                                }
                                MouseArea
                                {
                                    anchors.fill: parent
                                    onClicked:
                                    {
                                        mainItem.newScript()
                                    }
                                }
                            }
                        }
                        ScrollView
                        {
                            anchors.fill: parent
                            anchors.topMargin: scriptNameRegion.height
                            Rectangle
                            {
                                id: scrollViewBackground
                                anchors.fill: parent
                                color: darkBackGroundColor
                            }

                            ListView
                            {
                                id: keyframeListView
                                anchors.fill: parent
                                anchors.margins: globalSpacing
                                model: keyframeList
                                spacing: globalSpacing
                                Component.onCompleted:
                                {
                                    updateView()
                                }

                                delegate: Item {
                                    height:globalSpacing*3
                                    width: keyframeListView.width
                                    Rectangle
                                    {
                                        anchors.fill: parent
                                        anchors.margins: -globalSpacing/2
                                        color: whiteColor
                                        opacity: keyframeListView.currentIndex === index ? 0.9 : 0
                                        Behavior on opacity {
                                            SmoothedAnimation {velocity:4}
                                        }

                                        z: -1
                                    }

                                    Row
                                    {
                                        anchors.fill: parent
                                        spacing:globalSpacing

                                        Rectangle
                                        {
                                            id: indexOfKeyframe
                                            height: parent.height
                                            width: height
                                            color: keyframeListView.currentIndex === index ? mainColor : mainColorLowContrast
                                            Text {
                                                text: index
                                                anchors.centerIn: parent
                                                font.pixelSize: globalSpacing*2
                                                color: whiteColor
                                                font.bold: true
                                            }
                                        }
                                        Rectangle
                                        {
                                            id: nameOfKeyframe
                                            height: parent.height
                                            width: parent.width - x
                                            color: mainColor2
                                            Text {
                                                text: keyframeName
                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.left: parent.left
                                                anchors.leftMargin: globalSpacing
                                                font.pixelSize: globalSpacing*2
                                                color: whiteColor
                                                font.bold: true
                                            }
                                        }
                                    }
                                    MouseArea
                                    {
                                        anchors.fill: parent
                                        onClicked:
                                        {
                                            keyframeListView.currentIndex = index;
                                            timeTextInput.text = keyframeList.get(index).time;
                                            positionTextInput.text = keyframeList.get(index).position;
                                            focalTextInput.text = keyframeList.get(index).focal;
                                            panTextInput.text = keyframeList.get(index).pan;
                                            tiltTextInput.text = keyframeList.get(index).tilt;
                                            ingoingTextInput.text = keyframeList.get(index).ingoing;
                                            outgoingTextInput.text = keyframeList.get(index).outgoing;
                                            nameTextInput.text = keyframeList.get(index).keyframeName
                                            descriptionTextInput.text = keyframeList.get(index).keyframeDescription
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Rectangle
                    {
                        id: propertyEditRegion
                        width: parent.width
                        height: (parent.height-y)
                        property int alignSize:outgoingTitle.contentWidth
                        property int textBoxSize:leftEditorColumn.width/2
                        color: darkBackGroundColor
                        Row
                        {
                            id: keyframeTitle
                            width:parent.width
                            height: nameOnEditor.contentHeight+globalSpacing
                            Rectangle
                            {
                                width: nameOnEditor.contentWidth+2*globalSpacing
                                height: nameOnEditor.contentHeight +globalSpacing
                                color: mainColor
                                Text {
                                    id: nameOnEditor
                                    text: "NO. " +  keyframeListView.currentIndex
                                    anchors.centerIn: parent
                                    font.bold: true
                                    font.pixelSize: globalSpacing*2
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color:whiteColor
                                }
                            }
                            Rectangle
                            {
                                width: parent.width -x
                                height: nameOnEditor.contentHeight +globalSpacing
                                color: whiteColor
                                Text {
                                    id: titleOfEditor
                                    text: "Keyframe editor"
                                    anchors.centerIn: parent
                                    font.bold: true
                                    font.pixelSize: globalSpacing*2
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color:mainColor
                                }
                            }
                        }

                        Column
                        {
                            id: leftEditorColumn
                            width: parent.width/3
                            anchors.left: parent.left
                            anchors.top: keyframeTitle.bottom
                            anchors.bottom: parent.bottom
                            anchors.topMargin: globalSpacing
                            anchors.leftMargin: globalSpacing/2
                            spacing: globalSpacing
                            Item
                            {
                                height: globalSpacing*3
                                width: parent.width + globalSpacing*8
                                Row {
                                    height: parent.height
                                    Item {
                                        height: parent.height
                                        width: propertyEditRegion.alignSize
                                        Text {
                                            text: qsTr("Time: ")
                                            color: whiteColor
                                            font.bold: true
                                            font.pixelSize: globalSpacing*2
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    Rectangle
                                    {
                                        color: whiteColor
                                        height: parent.height
                                        width: propertyEditRegion.textBoxSize
                                        clip: true
                                        TextInput {
                                            id: timeTextInput
                                            validator: DoubleValidator {bottom: 0; top: 1000}
                                            width: parent.width
                                            x: globalSpacing/2
                                            font.bold: true
                                            font.pixelSize: globalSpacing*2
                                            color: darkBackGroundColor
                                            onTextChanged:
                                            {
                                                if (text.length>7)
                                                {
                                                    text = text.substring(0,7);
                                                }
                                            }
                                        }

                                    }
                                    Item {
                                        height: parent.height
                                        width: propertyEditRegion.alignSize
                                        Text {
                                            //unit
                                            x:globalSpacing/2
                                            text: qsTr("s")
                                            color: whiteColor
                                            font.bold: true
                                            font.pixelSize: globalSpacing*2
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }
                            }

                            Item
                            {
                                height: globalSpacing*3
                                width: parent.width/2
                                Row {
                                    height: parent.height
                                    Item {
                                        height: parent.height
                                        width: propertyEditRegion.alignSize
                                        Text {
                                            text: qsTr("Position: ")
                                            color: whiteColor
                                            font.bold: true
                                            font.pixelSize: globalSpacing*2
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    Rectangle
                                    {
                                        color: whiteColor
                                        height: parent.height
                                        width: propertyEditRegion.textBoxSize
                                        clip: true
                                        TextInput {
                                            id: positionTextInput
                                            validator: DoubleValidator {bottom: 0; top: 1000}
                                            text: 0.00 + ""
                                            width: parent.width
                                            x: globalSpacing/2
                                            font.bold: true
                                            font.pixelSize: globalSpacing*2
                                            color: darkBackGroundColor
                                            onTextChanged:
                                            {
                                                if (text.length>7)
                                                {
                                                    text = text.substring(0,7);
                                                }
                                            }
                                        }

                                    }
                                    Item {
                                        height: parent.height
                                        width: propertyEditRegion.alignSize
                                        Text {
                                            //unit
                                            x:globalSpacing/2
                                            text: qsTr("m")
                                            color: whiteColor
                                            font.bold: true
                                            font.pixelSize: globalSpacing*2
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }
                            }

                            Item
                            {
                                height: globalSpacing*3
                                width: parent.width/2
                                Row {
                                    height: parent.height
                                    Item {
                                        height: parent.height
                                        width: propertyEditRegion.alignSize
                                        Text {
                                            text: qsTr("Focal: ")
                                            color: whiteColor
                                            font.bold: true
                                            font.pixelSize: globalSpacing*2
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    Rectangle
                                    {
                                        color: whiteColor
                                        height: parent.height
                                        width: propertyEditRegion.textBoxSize
                                        clip: true
                                        TextInput {
                                            id: focalTextInput
                                            validator: DoubleValidator {bottom: 0; top: 1000}
                                            text: 0.00 + ""
                                            width: parent.width
                                            x: globalSpacing/2
                                            font.bold: true
                                            font.pixelSize: globalSpacing*2
                                            color: darkBackGroundColor
                                            onTextChanged:
                                            {
                                                if (text.length>7)
                                                {
                                                    text = text.substring(0,7);
                                                }
                                            }
                                        }

                                    }
                                    Item {
                                        height: parent.height
                                        width: propertyEditRegion.alignSize
                                        Text {
                                            //unit
                                            x:globalSpacing/2
                                            text: qsTr("mm")
                                            color: whiteColor
                                            font.bold: true
                                            font.pixelSize: globalSpacing*2
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }

                            }
                            Item
                            {
                                height: globalSpacing*3
                                width: parent.width/2
                                Row {
                                    height: parent.height
                                    Item {
                                        height: parent.height
                                        width: propertyEditRegion.alignSize
                                        Text {
                                            text: qsTr("Pan: ")
                                            color: whiteColor
                                            font.bold: true
                                            font.pixelSize: globalSpacing*2
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    Rectangle
                                    {
                                        color: whiteColor
                                        height: parent.height
                                        width: propertyEditRegion.textBoxSize
                                        clip: true
                                        TextInput {
                                            id: panTextInput
                                            validator: DoubleValidator {bottom: 0; top: 1000}
                                            text: 0.00 + ""
                                            width: parent.width
                                            x: globalSpacing/2
                                            font.bold: true
                                            font.pixelSize: globalSpacing*2
                                            color: darkBackGroundColor
                                            onTextChanged:
                                            {
                                                if (text.length>7)
                                                {
                                                    text = text.substring(0,7);
                                                }
                                            }
                                        }

                                    }
                                    Item {
                                        height: parent.height
                                        width: propertyEditRegion.alignSize
                                        Text {
                                            //unit
                                            x:globalSpacing/2
                                            text: qsTr("°")
                                            color: whiteColor
                                            font.bold: true
                                            font.pixelSize: globalSpacing*2
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }

                            }
                            Item
                            {
                                height: globalSpacing*3
                                width: parent.width/2
                                Row {
                                    height: parent.height
                                    Item {
                                        height: parent.height
                                        width: propertyEditRegion.alignSize
                                        Text {
                                            text: qsTr("Tilt: ")
                                            color: whiteColor
                                            font.bold: true
                                            font.pixelSize: globalSpacing*2
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    Rectangle
                                    {
                                        color: whiteColor
                                        height: parent.height
                                        width: propertyEditRegion.textBoxSize
                                        clip: true
                                        TextInput {
                                            id: tiltTextInput
                                            validator: DoubleValidator {bottom: 0; top: 1000}
                                            width: parent.width
                                            text:"0"
                                            x: globalSpacing/2
                                            font.bold: true
                                            font.pixelSize: globalSpacing*2
                                            color: darkBackGroundColor
                                            onTextChanged:
                                            {
                                                if (text.length>7)
                                                {
                                                    text = text.substring(0,7);
                                                }
                                            }
                                        }

                                    }
                                    Item {
                                        height: parent.height
                                        width: propertyEditRegion.alignSize
                                        Text {
                                            //unit
                                            x:globalSpacing/2
                                            text: qsTr("°")
                                            color: whiteColor
                                            font.bold: true
                                            font.pixelSize: globalSpacing*2
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }
                            }

                            Item
                            {
                                height: globalSpacing*3
                                width: parent.width/2
                                Row {
                                    height: parent.height
                                    Item {
                                        height: parent.height
                                        width: propertyEditRegion.alignSize
                                        Text {
                                            text: qsTr("Ingoing: ")
                                            color: whiteColor
                                            font.bold: true
                                            font.pixelSize: globalSpacing*2
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    Rectangle
                                    {
                                        color: whiteColor
                                        height: parent.height
                                        width: propertyEditRegion.textBoxSize
                                        clip: true
                                        TextInput {
                                            id: ingoingTextInput
                                            validator: DoubleValidator {bottom: 0; top: 1000}
                                            text: 0.00 + ""
                                            width: parent.width
                                            x: globalSpacing/2
                                            font.bold: true
                                            font.pixelSize: globalSpacing*2
                                            color: darkBackGroundColor
                                            onTextChanged:
                                            {
                                                if (text.length>7)
                                                {
                                                    text = text.substring(0,7);
                                                }
                                            }
                                        }

                                    }
                                    Item {
                                        height: parent.height
                                        width: propertyEditRegion.alignSize
                                        Text {
                                            //unit
                                            x:globalSpacing/2
                                            text: qsTr("%")
                                            color: whiteColor
                                            font.bold: true
                                            font.pixelSize: globalSpacing*2
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }

                            }
                            Item
                            {
                                height: globalSpacing*3
                                width: parent.width/2
                                Row {
                                    height: parent.height
                                    Item {
                                        height: parent.height
                                        width: propertyEditRegion.alignSize
                                        Text {
                                            id: outgoingTitle
                                            text: qsTr("Outgoing: ")
                                            color: whiteColor
                                            font.bold: true
                                            font.pixelSize: globalSpacing*2
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    Rectangle
                                    {
                                        color: whiteColor
                                        height: parent.height
                                        width: propertyEditRegion.textBoxSize
                                        clip: true
                                        TextInput {
                                            id: outgoingTextInput
                                            validator: DoubleValidator {bottom: 0; top: 1000}
                                            text: 0.00 + ""
                                            width: parent.width
                                            x: globalSpacing/2
                                            font.bold: true
                                            font.pixelSize: globalSpacing*2
                                            color: darkBackGroundColor
                                            onTextChanged:
                                            {
                                                if (text.length>7)
                                                {
                                                    text = text.substring(0,7);
                                                }
                                            }
                                        }

                                    }
                                    Item {
                                        height: parent.height
                                        width: propertyEditRegion.alignSize
                                        Text {
                                            //unit
                                            x:globalSpacing/2
                                            text: qsTr("%")
                                            color: whiteColor
                                            font.bold: true
                                            font.pixelSize: globalSpacing*2
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }

                            }

                        }
                        Column
                        {
                            id: rightEditorColumn
                            width: parent.width - leftEditorColumn.implicitWidth
                            anchors.top: keyframeTitle.bottom
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            anchors.topMargin: globalSpacing

                            spacing: globalSpacing
                            Item
                            {
                                height: globalSpacing*3
                                width: parent.width
                                anchors.right: parent.right
                                anchors.margins: globalSpacing
                                Row {
                                    height: parent.height
                                    width: parent.width
                                    Item {
                                        height: parent.height
                                        width: propertyEditRegion.alignSize*1.2
                                        Text {
                                            text: qsTr("Name: ")
                                            color: whiteColor
                                            font.bold: true
                                            font.pixelSize: globalSpacing*2
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    Rectangle
                                    {
                                        color: whiteColor
                                        height: parent.height
                                        width: parent.width-x
                                        clip: true
                                        TextInput {
                                            id: nameTextInput

                                            text: "Tên của keyframe"
                                            width: parent.width
                                            x: globalSpacing/2
                                            font.bold: true
                                            font.pixelSize: globalSpacing*2
                                            color: darkBackGroundColor
                                            onTextChanged:
                                            {
                                                if (text.length>200)
                                                {
                                                    text = text.substring(0,200);
                                                }
                                            }
                                        }

                                    }
                                }

                            }
                            Item
                            {
                                height: globalSpacing*12
                                width: parent.width
                                anchors.right: parent.right
                                anchors.margins: globalSpacing
                                Row {
                                    height: parent.height
                                    width: parent.width
                                    Item {
                                        height: parent.height
                                        width: propertyEditRegion.alignSize*1.2
                                        Text {
                                            text: qsTr("Description: ")
                                            color: whiteColor
                                            font.bold: true
                                            font.pixelSize: globalSpacing*2
                                            anchors.top: parent.top
                                        }
                                    }

                                    Rectangle
                                    {
                                        color: whiteColor
                                        height: parent.height
                                        width: parent.width-x
                                        clip: true
                                        ScrollView
                                        {
                                            height: parent.height
                                            contentWidth: parent.width
                                            TextInput {
                                                id: descriptionTextInput
                                                wrapMode: Text.Wrap
                                                text: "Mô tả của keyframe"
                                                width: parent.width
                                                x: globalSpacing/2
                                                font.bold: true
                                                font.pixelSize: globalSpacing*2
                                                color: darkBackGroundColor
                                                onTextChanged:
                                                {
                                                    if (text.length>200)
                                                    {
                                                        text = text.substring(0,200);
                                                    }
                                                }
                                            }
                                        }

                                    }
                                }

                            }
                            Row
                            {
                                height: globalSpacing*10
                                width: parent.width
                                anchors.right: parent.right
                                Item
                                {
                                    height: parent.height
                                    width: parent.width/3
                                    Rectangle
                                    {
                                        anchors.fill: parent
                                        anchors.margins: globalSpacing
                                        color: mainColor
                                        Image {

                                            source: "qrc:/icon/resource/save.png"
                                            anchors.fill: parent
                                            anchors.margins: globalSpacing
                                            fillMode: Image.PreserveAspectFit
                                        }
                                        MouseArea
                                        {
                                            anchors.fill: parent
                                            onClicked:
                                            {
                                                mainItem.saveKeyframe()
                                            }
                                        }
                                    }

                                }
                                Item
                                {
                                    height: parent.height
                                    width: parent.width/3
                                    Rectangle
                                    {
                                        anchors.fill: parent
                                        anchors.margins: globalSpacing
                                        color: mainColor3
                                        Image {

                                            source: "qrc:/icon/resource/add.png"
                                            anchors.fill: parent
                                            anchors.margins: globalSpacing
                                            fillMode: Image.PreserveAspectFit
                                        }
                                        MouseArea
                                        {
                                            anchors.fill: parent
                                            onClicked:
                                            {
                                                mainItem.addKeyframe()
                                            }
                                        }
                                    }

                                }
                                Item
                                {
                                    height: parent.height
                                    width: parent.width/3
                                    Rectangle
                                    {
                                        anchors.fill: parent
                                        anchors.margins: globalSpacing
                                        color: redColor
                                        Image {

                                            source: "qrc:/icon/resource/delete.png"
                                            anchors.fill: parent
                                            anchors.margins: globalSpacing
                                            fillMode: Image.PreserveAspectFit
                                        }
                                        MouseArea
                                        {
                                            anchors.fill: parent
                                            onClicked:
                                            {
                                                mainItem.deleteKeyframe()
                                            }
                                        }
                                    }

                                }
                            }

                        }

                    }
                }

            }
        }
        Rectangle
        {
            id: modelRegion
            width: parent.width/3
            height: parent.height
            anchors.right: parent.right
            color: darkBackGroundColor
            //Function button
            Item
            {
                width: parent.width
                height: width/3
                Item {
                    anchors.fill: parent
                    anchors.margins: globalSpacing
                    Row
                    {
                        anchors.fill: parent
                        spacing:globalSpacing/2
                        Rectangle
                        {
                            height:parent.height
                            width:parent.width/3-globalSpacing/3
                            color: mainColor
                            Image {
                                source: isPlaying?  "qrc:/icon/resource/pause.png" : "qrc:/icon/resource/start.png"
                                anchors.fill: parent
                                anchors.margins: globalSpacing
                                fillMode: Image.PreserveAspectFit
                            }
                            MouseArea
                            {
                                anchors.fill: parent
                                onClicked:
                                {
                                    if (!isPlaying)
                                        mainItem.playScript()
                                    else
                                        mainItem.stopScript()
                                }
                            }
                        }
                        Rectangle
                        {
                            height:parent.height
                            width:parent.width/3-globalSpacing/3
                            color: mainColor2
                            Image {
                                source: "qrc:/icon/resource/restart.png"
                                anchors.fill: parent
                                anchors.margins: globalSpacing
                                fillMode: Image.PreserveAspectFit
                            }
                            MouseArea
                            {
                                anchors.fill: parent
                                onClicked:
                                {
                                    mainItem.restartScript()
                                }
                            }
                        }
                        Rectangle
                        {
                            height:parent.height
                            width:parent.width/3-globalSpacing/3
                            color: mainColor3
                            Image {
                                source: "qrc:/icon/resource/send.png"
                                anchors.fill: parent
                                anchors.margins: globalSpacing
                                fillMode: Image.PreserveAspectFit
                            }
                            MouseArea
                            {
                                anchors.fill: parent
                                onClicked:
                                {
                                    mainItem.sendScript()
                                }
                            }
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
                x: pos/xMaximum*slider.width

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
                                sweepAngle: 2*Math.atan(diagonal/(2*(focal)))/Math.PI*180
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
                    height:parent.height*((focal-focalMinimum)/(focalMaximum-focalMinimum))+parent.height/4
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
                        angle: -90+pan

                        Behavior on angle
                        {
                            SmoothedAnimation {velocity:200}
                        }
                    }
                ]
            }
        }

    }
}
