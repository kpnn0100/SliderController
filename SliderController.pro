QT += quick
QT += bluetooth
QT += core
SOURCES += \
        Manager/BluetoothManager.cpp \
        Manager/FileManager.cpp \
        main.cpp
resources.files = main.qml 
resources.files += Control/
resources.files += View/
resources.prefix = /$${TARGET}
RESOURCES += resources \
    icon.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

DISTFILES += \
    Control/CheckBox.qml \
    Control/XYPad.qml \
    Control/XYPadLinear.qml \
    View/AutoHorizontal.qml \
    View/ManualHorizontal.qml \
    android/AndroidManifest.xml \
    android/build.gradle \
    android/gradle.properties \
    android/gradle/wrapper/gradle-wrapper.jar \
    android/gradle/wrapper/gradle-wrapper.properties \
    android/gradlew \
    android/gradlew.bat \
    android/res/values/libs.xml \
    resource/673903-200.png \
    resource/Icon-01.png \
    resource/Icon-02.png \
    resource/Icon-03.png \
    resource/Icon-04.png \
    resource/panning.png \
    resource/position.png

HEADERS += \
    Manager/BluetoothManager.h \
    Manager/FileManager.h

contains(ANDROID_TARGET_ARCH,arm64-v8a) {
    ANDROID_PACKAGE_SOURCE_DIR = \
        $$PWD/android
}
