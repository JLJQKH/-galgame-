#include "gamelistmodel.h"

#include <QSqlQuery>
#include <QSqlError>
#include <QDebug>

GameListModel::GameListModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int GameListModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_games.size();
}

QVariant GameListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_games.size())
        return {};

    const GameRecord &g = m_games.at(index.row());

    switch (role) {
    case IdRole:         return g.id;
    case NameRole:       return g.name;
    case CoverRole:      return g.coverPath;
    case TypesRole:      return g.types;
    case RatingRole:     return g.rating;
    case StatusRole:     return g.status;
    case PlayTimeRole:   return g.playTime;
    case StartDateRole:  return g.startDate;
    case FinishDateRole: return g.finishDate;
    case NotesRole:      return g.notes;
    }
    return {};
}

QHash<int, QByteArray> GameListModel::roleNames() const
{
    return {
        { IdRole,         "gameId" },
        { NameRole,       "gameName" },
        { CoverRole,      "gameCover" },
        { TypesRole,      "gameTypes" },
        { RatingRole,     "gameRating" },
        { StatusRole,     "gameStatus" },
        { PlayTimeRole,   "gamePlayTime" },
        { StartDateRole,  "gameStartDate" },
        { FinishDateRole, "gameFinishDate" },
        { NotesRole,      "gameNotes" }
    };
}

void GameListModel::refresh(const QString &keyword, const QString &status, const QString &sortBy)
{
    beginResetModel();
    m_games.clear();

    QStringList clauses;
    if (!keyword.isEmpty()) clauses << QStringLiteral("name LIKE :kw");
    if (!status.isEmpty())  clauses << QStringLiteral("status = :st");
    QString sql = QStringLiteral(
        "SELECT id, name, cover_path, types, rating, status, play_time, start_date, finish_date, notes FROM games");
    if (!clauses.isEmpty()) sql += QStringLiteral(" WHERE ") + clauses.join(" AND ");

    QString orderBy;
    if (sortBy == "name") {
        orderBy = QStringLiteral("ORDER BY name COLLATE NOCASE ASC");
    } else if (sortBy == "rating") {
        orderBy = QStringLiteral("ORDER BY rating DESC, created_at DESC");
    } else {
        orderBy = QStringLiteral("ORDER BY created_at DESC");
    }
    sql += " " + orderBy;

    QSqlQuery query;
    if (!query.prepare(sql)) {
        qWarning() << "[列表] SQL 预处理失败:" << query.lastError().text() << "SQL:" << sql;
        endResetModel();
        return;
    }
    if (!keyword.isEmpty()) query.bindValue(":kw", "%" + keyword + "%");
    if (!status.isEmpty())  query.bindValue(":st", status);

    if (!query.exec()) {
        qWarning() << "[列表] 查询失败:" << query.lastError().text();
        endResetModel();
        return;
    }

    while (query.next()) {
        GameRecord g;
        g.id         = query.value(0).toInt();
        g.name       = query.value(1).toString();
        g.coverPath  = query.value(2).toString();
        g.types      = query.value(3).toString();
        g.rating     = query.value(4).toDouble();
        g.status     = query.value(5).toString();
        g.playTime   = query.value(6).toInt();
        g.startDate  = query.value(7).toString();
        g.finishDate = query.value(8).toString();
        g.notes      = query.value(9).toString();
        m_games.append(g);
    }

    endResetModel();
    qDebug() << "[列表] 已加载" << m_games.size() << "条游戏";
}
