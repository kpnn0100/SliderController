#ifndef BLUETOOTHMANAGER_H
#define BLUETOOTHMANAGER_H

#include <QBluetoothDeviceDiscoveryAgent>
#include <QBluetoothDeviceInfo>
#include <QLowEnergyController>
#include <QLowEnergyService>
#include <qregularexpression.h>
#include <QBluetoothDeviceDiscoveryAgent>
#include <QBluetoothSocket>
#include <QMutex>
#include <QByteArray>
#include <QThread>
#include <chrono>
#include <thread>
using namespace Qt;
class BluetoothManager : public QObject
{
    Q_OBJECT
    QBluetoothDeviceDiscoveryAgent *discoveryAgent;
    QBluetoothSocket *socket;
    QByteArray doubleToByteArray(double input);
    QByteArray intToByteArray(int input);
    QString mStatus;
    QMutex syncCall;
public:
    explicit BluetoothManager(QObject *parent = nullptr);
    ~BluetoothManager();
    Q_INVOKABLE void write(QString message);
    Q_INVOKABLE void writeDouble(double value);
    Q_INVOKABLE void writeInt(int value);
    Q_INVOKABLE void write(QByteArray value);
    Q_INVOKABLE void findAndConnectSlider();
    Q_INVOKABLE QByteArray byteArrayFromString(QString data);
    Q_INVOKABLE QByteArray byteArrayFromDouble(double data);
    Q_INVOKABLE void blockCall();
    Q_INVOKABLE void unlockCall();
    QString status() const;
    void setStatus(const QString &newStatus);

signals:
    void statusChanged();

private slots:

    void deviceDiscovered(const QBluetoothDeviceInfo &deviceInfo);
    void socketConnected();
private:

    Q_PROPERTY(QString status READ status WRITE setStatus NOTIFY statusChanged)
};
#endif // BLUETOOTHMANAGER_H
