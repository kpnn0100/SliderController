#include "BluetoothManager.h"
BluetoothManager::BluetoothManager() :
    m_currentDevice(QBluetoothDeviceInfo()),
    m_control(0),
    m_service(0),
    m_state(bluetoothleState::Idle)
{

    /* 1 Step: Bluetooth LE Device Discovery */
    m_deviceDiscoveryAgent = new QBluetoothDeviceDiscoveryAgent(this);


    /* Device Discovery Initialization */
    connect(m_deviceDiscoveryAgent, SIGNAL(deviceDiscovered(const QBluetoothDeviceInfo&)),
            this, SLOT(addDevice(const QBluetoothDeviceInfo&)));
    connect(m_deviceDiscoveryAgent, SIGNAL(error(QBluetoothDeviceDiscoveryAgent::Error)),
            this, SLOT(deviceScanError(QBluetoothDeviceDiscoveryAgent::Error)));
    connect(m_deviceDiscoveryAgent, SIGNAL(finished()), this, SLOT(scanFinished()));


}

BluetoothManager::~BluetoothManager(){


}



QList<QString> BluetoothManager::getDeviceList(){

    if(m_state == bluetoothleState::ScanFinished)
    {
        return m_qlFoundDevices;
    }
    else
    {
        return QList<QString>();
    }

}



void BluetoothManager::addDevice(const QBluetoothDeviceInfo &device)
{
    /* Is it a LE Bluetooth device? */
    if (device.coreConfigurations() & QBluetoothDeviceInfo::LowEnergyCoreConfiguration) {
        qWarning() << "Discovered LE Device name: " << device.name() << " Address: "
                   << device.address().toString();
        DeviceInfo *dev = new DeviceInfo(device);
        m_qlDevices.append(dev);
        qDebug() << "Low Energy device found. Scanning for more..." << endl;

         //delete jsut for debugging
        //if(device.name() == "Adafruit Bluefruit LE") emit m_deviceDiscoveryAgent->finished();
    }

}


void BluetoothManager::scanFinished()
{
    if (m_qlDevices.size() == 0)
    {
        qWarning() << "No Low Energy devices found" << endl;
    }
    else
    {
        for (int i = 0; i < m_qlDevices.size(); i++) {
           m_qlFoundDevices.append(((DeviceInfo*) m_qlDevices.at(i))->getName());
        }

    }
    setState(ScanFinished);

}


void BluetoothManager::deviceScanError(QBluetoothDeviceDiscoveryAgent::Error error)
{
    if (error == QBluetoothDeviceDiscoveryAgent::PoweredOffError)
        qDebug() << "The Bluetooth adaptor is powered off, power it on before doing discovery.";
    else if (error == QBluetoothDeviceDiscoveryAgent::InputOutputError)
        qDebug() << "Writing or reading from the device resulted in an error.";
    else
        qDebug() << "An unknown error has occurred.";
}



void BluetoothManager::startScan(){

    qDeleteAll(m_qlDevices);
    m_qlDevices.clear();

    m_qlFoundDevices.clear();

    m_deviceDiscoveryAgent->start();
    setState(Scanning);

    qDebug()<< "Searching for low energy devices..." ;

}


void BluetoothManager::startConnect(int i){

    m_qvMeasurements.clear();

    m_currentDevice.setDevice(((DeviceInfo*)m_qlDevices.at(i))->getDevice());

    if (m_control) {
        m_control->disconnectFromDevice();
        delete m_control;
        m_control = 0;

    }

    /* 2 Step: QLowEnergyController */
    m_control = QLowEnergyController::createCentral(m_currentDevice.getDevice(), this);



//    //m_control ->setRemoteAddressType(QLowEnergyController::RandomAddress);

//    connect(m_control, SIGNAL(serviceDiscovered(QBluetoothUuid)),
//            this, SLOT(serviceDiscovered(QBluetoothUuid)));
//    connect(m_control, SIGNAL(discoveryFinished()),
//            this, SLOT(serviceScanDone()));
//    connect(m_control, SIGNAL(error(QLowEnergyController::Error)),
//            this, SLOT(controllerError(QLowEnergyController::Error)));
//    connect(m_control, SIGNAL(connected()),
//            this, SLOT(deviceConnected()));
//    connect(m_control, SIGNAL(disconnected()),
//            this, SLOT(deviceDisconnected()));

//    /* Start connecting to device */
//    m_control->connectToDevice();
//    setState(Connecting);

    QBluetoothSocket *socket = new QBluetoothSocket(QBluetoothServiceInfo::RfcommProtocol);
     socket->connectToService(QBluetoothAddress(m_currentDevice.getAddress()), QBluetoothUuid(QBluetoothUuid::ServiceClassUuid::SerialPort));
     connect(socket, SIGNAL(connected()), this, SLOT(deviceConnected()));
     connect(socket, SIGNAL(error(QBluetoothSocket::SocketError)), this, SLOT(socketError(QBluetoothSocket::SocketError)));

}



void BluetoothManager::serviceDiscovered(const QBluetoothUuid &gatt){

    if(gatt==QBluetoothUuid(QUuid(UARTSERVICEUUID))){
        m_bFoundUARTService =true;
        qDebug() << "UART service found!";
    }
}



void BluetoothManager::serviceScanDone(){

    delete m_service;
    m_service=0;

    if(m_bFoundUARTService){
       qDebug() << "Connecting to UART service...";
        m_service = m_control->createServiceObject(QBluetoothUuid(QUuid(UARTSERVICEUUID)),this);
    }

    if(!m_service){
        qDebug() <<"UART service not found";
        return;
    }

    /* 3 Step: Service Discovery */
    connect(m_service, SIGNAL(stateChanged(QLowEnergyService::ServiceState)),
            this, SLOT(serviceStateChanged(QLowEnergyService::ServiceState)));
    connect(m_service, SIGNAL(characteristicChanged(QLowEnergyCharacteristic,QByteArray)),
            this, SLOT(updateData(QLowEnergyCharacteristic,QByteArray)));
    connect(m_service, SIGNAL(descriptorWritten(QLowEnergyDescriptor,QByteArray)),
            this, SLOT(confirmedDescriptorWrite(QLowEnergyDescriptor,QByteArray)));

    m_service->discoverDetails();
    setState(ServiceFound);

}

void BluetoothManager::deviceDisconnected()
{
    qDebug() << "UART service disconnected";
    qWarning() << "Remote device disconnected";
}

void BluetoothManager::deviceConnected()
{
   qDebug() << "Device connected";
    m_control->discoverServices();
    setState(Connected);
}

void BluetoothManager::controllerError(QLowEnergyController::Error error)
{
    qDebug() << "Cannot connect to remote device.";
    qWarning() << "Controller Error:" << error;
}


/* Slotes for QLowEnergyService */
void BluetoothManager::serviceStateChanged(QLowEnergyService::ServiceState s)
{

    // A descriptoc can only be written if the service is in the ServiceDiscovered state
    switch (s) {
    case QLowEnergyService::RemoteServiceDiscovered:
    {

        //looking for the TX characteristic
        const QLowEnergyCharacteristic TxChar = m_service->characteristic(QBluetoothUuid(QUuid(TXUUID)));
        if (!TxChar.isValid()){
            qDebug() << "Tx characteristic not found";
            break;
        }

         //looking for the RX characteristic
        const QLowEnergyCharacteristic  RxChar = m_service->characteristic(QBluetoothUuid(QUuid(RXUUID)));
        if (!RxChar.isValid()) {
           qDebug() << "Rx characteristic not found";
            break;
        }


       // Bluetooth LE spec Where a characteristic can be notified, a Client Characteristic Configuration descriptor
       // shall be included in that characteristic as required by the Bluetooth Core Specification
       // Tx notify is enabled
       const QLowEnergyDescriptor m_notificationDescTx = TxChar.descriptor(
                   QBluetoothUuid::DescriptorType::ClientCharacteristicConfiguration);
        if (m_notificationDescTx.isValid()) {
            // enable notification
            m_service->writeDescriptor(m_notificationDescTx, QByteArray::fromHex("0100"));
            setState(AcquireData);
            }

        break;
    }
    default:
        //nothing for now
        break;
    }
}

void BluetoothManager::updateData(const QLowEnergyCharacteristic &c,const QByteArray &value)
{
    // ignore any other characteristic change
    if (c.uuid() != QBluetoothUuid(QUuid(TXUUID)))
           return;

    emit newData((QString) value);


}

void BluetoothManager::confirmedDescriptorWrite(const QLowEnergyDescriptor &d,
                                         const QByteArray &value)
{
    if (d.isValid() && d == m_notificationDescTx && value == QByteArray("0000")) {
        //disabled notifications -> assume disconnect intent
        m_control->disconnectFromDevice();
        delete m_service;
        m_service = 0;
    }
}


void BluetoothManager::writeData(QString s){

//    const QLowEnergyCharacteristic  RxChar = m_service->characteristic(QBluetoothUuid(QUuid(RXUUID)));

//    qDebug()<< s;
//    QByteArray Data;
//    for (int i =0; i<s.size();i++)
//        Data.append(s[i].toLatin1());

//    m_service->writeCharacteristic(RxChar, Data,QLowEnergyService::WriteWithoutResponse);

        qDebug()<< s;
        QByteArray Data;
        for (int i =0; i<s.size();i++)
            Data.append(s[i].toLatin1());
        QBluetoothSocket *socket = qobject_cast<QBluetoothSocket *>(sender());
        if (socket) {
            socket->write(Data);
            socket->close();
            delete socket;
        }

}



void BluetoothManager::setState(BluetoothManager::bluetoothleState newState)
{
    if (m_state == newState)
            return;

    m_state = newState;
    emit changedState(newState);
}

BluetoothManager::bluetoothleState BluetoothManager::getState() const {
    return m_state;
}
