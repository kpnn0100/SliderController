#ifndef FILEMANAGER_H
#define FILEMANAGER_H

#include <QObject>
#include <QList>
#include <QVariantMap>
#include <QUrl>

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QFile>

#include <QString>
class FileManager : public QObject
{
    Q_OBJECT
public:
    explicit FileManager(QObject *parent = nullptr);
    ~FileManager();
    QList<QVariantMap> dataToBeProcess() const;
    void setDataToBeProcess(const QList<QVariantMap> &newDataToBeProcess);
    Q_INVOKABLE void saveFile(const QList<QVariantMap> &data, const QString &fileUrl);
    Q_INVOKABLE QList<QVariantMap> loadFile(const QString &fileUrl);
private:
    QList<QVariantMap> mDataToBeProcess;
    Q_PROPERTY(QList<QVariantMap> dataToBeProcess READ dataToBeProcess WRITE setDataToBeProcess NOTIFY dataToBeProcessChanged)

signals:

    void dataToBeProcessChanged();
};

#endif // FILEMANAGER_H
