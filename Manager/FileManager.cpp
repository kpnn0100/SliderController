#include "FileManager.h"

FileManager::FileManager(QObject *parent)
    : QObject{parent}
{

}

FileManager::~FileManager()
{

}

QList<QVariantMap> FileManager::dataToBeProcess() const
{
    return mDataToBeProcess;
}

void FileManager::setDataToBeProcess(const QList<QVariantMap> &newDataToBeProcess)
{
    mDataToBeProcess = newDataToBeProcess;
    emit dataToBeProcessChanged();
}

void FileManager::saveFile(const QList<QVariantMap> &data, const QString &fileUrl)
{
    QJsonArray jsonArray;

    // Convert each QVariantMap to QJsonObject and add to the JSON array
    for (const QVariantMap& map : data) {
        QJsonObject jsonObject = QJsonObject::fromVariantMap(map);
        jsonArray.append(jsonObject);
    }

    // Create the JSON document
    QJsonDocument jsonDoc(jsonArray);

    // Open the file for writing
    QFile file(fileUrl);
    if (!file.open(QIODevice::WriteOnly)) {
        qDebug() << "Failed to open file for writing:" << file.errorString();
        return;
    }

    // Write the JSON data to the file
    file.write(jsonDoc.toJson());

    // Close the file
    file.close();
}

QList<QVariantMap> FileManager::loadFile(const QString &fileUrl)
{
    QList<QVariantMap> dataList;

      // Open the JSON file for reading
      QFile file(fileUrl);
      if (!file.open(QIODevice::ReadOnly)) {
          qDebug() << "Failed to open file for reading:" << file.errorString();
          return dataList;
      }

      // Read the JSON data from the file
      QByteArray jsonData = file.readAll();
      file.close();
      qDebug()<<jsonData;
      // Parse the JSON document
      QJsonDocument jsonDoc = QJsonDocument::fromJson(jsonData);
      if (jsonDoc.isNull()) {
          qDebug() << "Failed to parse JSON data from file:" << fileUrl;
          return dataList;
      }

      // Check if the top-level element is an array
      if (!jsonDoc.isArray()) {
          qDebug() << "Invalid JSON format. Top-level element is not an array.";
          return dataList;
      }

      // Get the JSON array
      QJsonArray jsonArray = jsonDoc.array();

      // Convert each QJsonValue to QVariantMap and add to the QList
      for (const QJsonValue& jsonValue : jsonArray) {
          if (!jsonValue.isObject()) {
              qDebug() << "Invalid JSON format. Array element is not an object.";
              continue;
          }

          QJsonObject jsonObject = jsonValue.toObject();
          QVariantMap map = jsonObject.toVariantMap();
          dataList.append(map);
      }

      return dataList;
}
