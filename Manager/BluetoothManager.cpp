#include "BluetoothManager.h"
BluetoothManager::BluetoothManager(QObject *parent)
    : QObject{parent}
{
    QByteArray test =doubleToByteArray(0.142);
    qDebug()<<test;
    qDebug()<<test.size();
    setStatus("Connect");
    socket=nullptr;
}

BluetoothManager::~BluetoothManager(){


}

void BluetoothManager::write(QString message)
{
    if (socket!=nullptr)
    if (socket->isWritable())
    {
        qDebug()<< message<<endl;
        qDebug()<< socket->write(message.toUtf8())<<endl;
    }
}

void BluetoothManager::write(double value)
{
        if (socket!=nullptr)
    if (socket->isWritable())
    {
        qDebug()<<"output value" <<value<<endl;
        qDebug()<< socket->write(doubleToByteArray(value))<<endl;
    }
}




void BluetoothManager::findAndConnectSlider()
{
     setStatus("Connecting");
    QBluetoothDeviceDiscoveryAgent *discoveryAgent = new QBluetoothDeviceDiscoveryAgent(this);
    connect(discoveryAgent, SIGNAL(deviceDiscovered(QBluetoothDeviceInfo)), this, SLOT(deviceDiscovered(QBluetoothDeviceInfo)));
    discoveryAgent->start();
}

QByteArray BluetoothManager::doubleToByteArray(double input)
{
    QByteArray output; // Character array to store the converted bytes

    char* bytePtr = (char*)(&input); // Get a pointer to the first byte of the double value

    for (int i = 0; i < sizeof(double); i++) {
        output.append( char(*(bytePtr + i))); // Copy each byte of the double value to the character array
    }
    return output;
}

QString BluetoothManager::status() const
{
    return mStatus;
}

void BluetoothManager::setStatus(const QString &newStatus)
{
    if (mStatus == newStatus)
        return;
    mStatus = newStatus;
    emit statusChanged();
}
void BluetoothManager::deviceDiscovered(const QBluetoothDeviceInfo &deviceInfo)
{
    if (deviceInfo.name() == "SliderController") {
        setStatus("Found...");
        qDebug()<<"found"<<endl;
        socket = new QBluetoothSocket(QBluetoothServiceInfo::RfcommProtocol, this);
        socket->connectToService(deviceInfo.address(), QBluetoothUuid(QBluetoothUuid::ServiceClassUuid::SerialPort));
        connect(socket, SIGNAL(connected()), this, SLOT(socketConnected()));
        connect(socket, SIGNAL(error(QBluetoothSocket::SocketError)), this, SLOT(socketError(QBluetoothSocket::SocketError)));
    }
}
void BluetoothManager::socketConnected()
{
    setStatus("Connected");
    qDebug()<<"Connected"<<endl;
    qDebug()<< socket->write("!")<<endl;
}
