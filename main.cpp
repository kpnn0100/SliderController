#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "Manager/BluetoothManager.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;
    const QUrl url(u"qrc:/SliderController/main.qml"_qs);
    qmlRegisterType<BluetoothManager>("BluetoothManager", 1, 0, "BluetoothManager");
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
