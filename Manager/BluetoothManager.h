#ifndef BLUETOOTHMANAGER_H
#define BLUETOOTHMANAGER_H

#include <QBluetoothDeviceDiscoveryAgent>
#include <QBluetoothDeviceInfo>
#include <QLowEnergyController>
#include <QLowEnergyService>
#include <qregularexpression.h>
#include <QBluetoothDeviceDiscoveryAgent>
#include <QBluetoothSocket>

#include <QByteArray>
using namespace Qt;
class BluetoothManager : public QObject
{
    Q_OBJECT
    QBluetoothDeviceDiscoveryAgent *discoveryAgent;
    QBluetoothSocket *socket;
    QByteArray doubleToByteArray(double input);
public:
    explicit BluetoothManager(QObject *parent = nullptr);
    ~BluetoothManager();
    Q_INVOKABLE void write(QString message);
    Q_INVOKABLE void write(double value);
    Q_INVOKABLE void findAndConnectSlider();
private slots:

    void deviceDiscovered(const QBluetoothDeviceInfo &deviceInfo);
    void socketConnected();
};
#endif // BLUETOOTHMANAGER_H
