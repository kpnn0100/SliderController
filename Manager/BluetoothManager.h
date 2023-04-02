#ifndef BLUETOOTHMANAGER_H
#define BLUETOOTHMANAGER_H

#include <QBluetoothDeviceDiscoveryAgent>
#include <QBluetoothDeviceInfo>
#include <QLowEnergyController>
#include <QLowEnergyService>
#include <qregularexpression.h>
#include <QBluetoothDeviceDiscoveryAgent>
#include <QBluetoothSocket>
#include <Bean/DeviceInfo.h>



#define UARTSERVICEUUID "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
#define RXUUID "6e400002-b5a3-f393-e0a9-e50e24dcca9e"
#define TXUUID "6e400003-b5a3-f393-e0a9-e50e24dcca9e"
using namespace Qt;
class BluetoothManager : public QObject
{
    Q_OBJECT
public:
    //TODO Error handling
    enum bluetoothleState {
        Idle = 0,
        Scanning,
        ScanFinished,
        Connecting,
        Connected,
        ServiceFound,
        AcquireData
    };
    Q_ENUM(bluetoothleState)

    BluetoothManager();
    ~BluetoothManager();

    Q_INVOKABLE void writeData(QString s);
    void setState(BluetoothManager::bluetoothleState newState);
    Q_INVOKABLE BluetoothManager::bluetoothleState getState() const;
    Q_INVOKABLE QList<QString> getDeviceList();


private slots:
    /* Slots for QBluetothDeviceDiscoveryAgent */
    void addDevice(const QBluetoothDeviceInfo&);
    void scanFinished();
    void deviceScanError(QBluetoothDeviceDiscoveryAgent::Error);

    /* Slots for QLowEnergyController */
    void serviceDiscovered(const QBluetoothUuid &);
    void serviceScanDone();
    void controllerError(QLowEnergyController::Error);
    void deviceConnected();
    void deviceDisconnected();

    /* Slotes for QLowEnergyService */
    void serviceStateChanged(QLowEnergyService::ServiceState s);
    void updateData(const QLowEnergyCharacteristic &c, const QByteArray &value);
    void confirmedDescriptorWrite(const QLowEnergyDescriptor &d, const QByteArray &value);
public slots:
    /* Slots for user */
    void startScan();
    void startConnect(int i);

signals:
    /* Signals for user */
    void newData(QString s);
    void changedState(BluetoothManager::bluetoothleState newState);


private:
    DeviceInfo m_currentDevice;
    QBluetoothDeviceDiscoveryAgent *m_deviceDiscoveryAgent;
    QList<QObject*> m_qlDevices;
    QList<QString> m_qlFoundDevices;
    QVector<quint16> m_qvMeasurements;
    QLowEnergyController *m_control;
    QLowEnergyService *m_service;
    QLowEnergyDescriptor m_notificationDescTx;
    QLowEnergyService *m_UARTService;
    bool m_bFoundUARTService;

    BluetoothManager::bluetoothleState m_state;

};
#endif // BLUETOOTHMANAGER_H
