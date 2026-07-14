#ifndef GAMELISTMODEL_H
#define GAMELISTMODEL_H

#include <QAbstractListModel>
#include <qqmlintegration.h>
#include <QVector>

// 一条游戏记录（对应 games 表一行）
struct GameRecord {
    int id = 0;
    QString name;
    QString coverPath;   // 封面图片路径
    QString types;       // JSON 数组字符串
    double rating = 0;
    QString status;
    int playTime = 0;
    QString startDate;
    QString finishDate;
    QString notes;
};

class GameListModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
public:
    enum Roles {
        IdRole = Qt::UserRole + 1,
        NameRole,
        CoverRole,
        TypesRole,
        RatingRole,
        StatusRole,
        PlayTimeRole,
        StartDateRole,
        FinishDateRole,
        NotesRole
    };

    explicit GameListModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void refresh(const QString &keyword = QString(), const QString &status = QString(), const QString &sortBy = QString());

private:
    QVector<GameRecord> m_games;
};

#endif // GAMELISTMODEL_H
