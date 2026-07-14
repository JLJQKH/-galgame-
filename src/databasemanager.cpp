#include "databasemanager.h"

#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QDateTime>
#include <QCoreApplication>
#include <QDebug>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QImage>
#include <QList>
#include <QPair>
#include <QSet>

DatabaseManager::DatabaseManager(QObject *parent)
    : QObject(parent)
{
}

bool DatabaseManager::initializeDatabase()
{
    if (QSqlDatabase::contains(QSqlDatabase::defaultConnection))
        return true;

    const QString appDir = QCoreApplication::applicationDirPath();
    const QString dataDir = appDir + QStringLiteral("/data");
    QDir().mkpath(dataDir);

    const QString dbPath = dataDir + QStringLiteral("/galgame.db");

    QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"));
    db.setDatabaseName(dbPath);

    if (!db.open()) {
        qWarning() << "[数据库] 打开失败:" << db.lastError().text();
        return false;
    }
    qDebug() << "[数据库] 已打开:" << dbPath;
    const bool ok = createGamesTable() && createBgImagesTable() && createScreenshotsTable() && createSettingsTable();
    if (ok) cleanupCropsDir();
    return ok;
}

bool DatabaseManager::createGamesTable()
{
    QSqlQuery query;
    const QString sql = QStringLiteral(
        "CREATE TABLE IF NOT EXISTS games ("
        "  id INTEGER PRIMARY KEY AUTOINCREMENT, "
        "  name TEXT NOT NULL, "
        "  cover_path TEXT, "
        "  types TEXT, "
        "  rating REAL, "
        "  status TEXT, "
        "  play_time INTEGER DEFAULT 0, "
        "  start_date TEXT, "
        "  finish_date TEXT, "
        "  notes TEXT, "
        "  created_at TEXT DEFAULT (datetime('now','localtime'))"
        ")"
    );
    if (!query.exec(sql)) {
        qWarning() << "[数据库] 建表失败:" << query.lastError().text();
        return false;
    }
    query.exec(QStringLiteral("ALTER TABLE games ADD COLUMN play_time INTEGER DEFAULT 0"));
    qDebug() << "[数据库] games 表已就绪";
    return true;
}

bool DatabaseManager::createBgImagesTable()
{
    QSqlQuery query;
    const QString sql = QStringLiteral(
        "CREATE TABLE IF NOT EXISTS bg_images ("
        "  id INTEGER PRIMARY KEY AUTOINCREMENT, "
        "  image_path TEXT NOT NULL, "
        "  opacity REAL DEFAULT 0.35, "
        "  blur REAL DEFAULT 0.5, "
        "  created_at TEXT DEFAULT (datetime('now','localtime'))"
        ")"
    );
    if (!query.exec(sql)) {
        qWarning() << "[数据库] bg_images 建表失败:" << query.lastError().text();
        return false;
    }
    // 迁移：旧表可能没有 opacity/blur 列，尝试添加
    query.exec(QStringLiteral("ALTER TABLE bg_images ADD COLUMN opacity REAL DEFAULT 0.35"));
    query.exec(QStringLiteral("ALTER TABLE bg_images ADD COLUMN blur REAL DEFAULT 0.5"));
    qDebug() << "[数据库] bg_images 表已就绪";
    return true;
}

bool DatabaseManager::createScreenshotsTable()
{
    QSqlQuery query;
    const QString sql = QStringLiteral(
        "CREATE TABLE IF NOT EXISTS screenshots ("
        "  id INTEGER PRIMARY KEY AUTOINCREMENT, "
        "  game_id INTEGER NOT NULL, "
        "  image_path TEXT NOT NULL, "
        "  sort_order INTEGER DEFAULT 0, "
        "  scale REAL DEFAULT 1.0, "
        "  crop_mode INTEGER DEFAULT 0, "
        "  offset_x REAL DEFAULT 0.0, "
        "  offset_y REAL DEFAULT 0.0, "
        "  created_at TEXT DEFAULT (datetime('now','localtime')), "
        "  FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE"
        ")"
    );
    if (!query.exec(sql)) {
        qWarning() << "[数据库] screenshots 建表失败:" << query.lastError().text();
        return false;
    }
    // 迁移：旧表可能没有 sort_order / scale / crop_mode / offset_x / offset_y 列
    query.exec(QStringLiteral("ALTER TABLE screenshots ADD COLUMN sort_order INTEGER DEFAULT 0"));
    query.exec(QStringLiteral("ALTER TABLE screenshots ADD COLUMN scale REAL DEFAULT 1.0"));
    query.exec(QStringLiteral("ALTER TABLE screenshots ADD COLUMN crop_mode INTEGER DEFAULT 0"));
    query.exec(QStringLiteral("ALTER TABLE screenshots ADD COLUMN offset_x REAL DEFAULT 0.0"));
    query.exec(QStringLiteral("ALTER TABLE screenshots ADD COLUMN offset_y REAL DEFAULT 0.0"));
    qDebug() << "[数据库] screenshots 表已就绪";
    return true;
}

bool DatabaseManager::createSettingsTable()
{
    QSqlQuery query;
    const QString sql = QStringLiteral(
        "CREATE TABLE IF NOT EXISTS app_settings ("
        "  key TEXT PRIMARY KEY, "
        "  value TEXT"
        ")"
    );
    if (!query.exec(sql)) {
        qWarning() << "[数据库] app_settings 建表失败:" << query.lastError().text();
        return false;
    }
    qDebug() << "[数据库] app_settings 表已就绪";
    return true;
}

// ===== 回忆模块（截图）方法 =====

QString DatabaseManager::getMemoryRoot()
{
    QSqlQuery query;
    query.prepare(QStringLiteral("SELECT value FROM app_settings WHERE key = 'memory_root'"));
    if (query.exec() && query.next()) {
        QString saved = query.value(0).toString();
        if (!saved.isEmpty()) return saved;
    }
    // 默认回忆根目录：galgame.exe 同目录下的 memories 子目录
    QString defaultRoot = QCoreApplication::applicationDirPath() + QStringLiteral("/memories");
    QDir().mkpath(defaultRoot);
    return defaultRoot;
}

bool DatabaseManager::setMemoryRoot(const QString &path)
{
    QSqlQuery query;
    query.prepare(QStringLiteral(
        "INSERT INTO app_settings (key, value) VALUES ('memory_root', :v) "
        "ON CONFLICT(key) DO UPDATE SET value = :v"));
    query.bindValue(":v", path);
    if (!query.exec()) {
        qWarning() << "[数据库] 设置回忆根目录失败:" << query.lastError().text();
        return false;
    }
    qDebug() << "[数据库] 回忆根目录已设置:" << path;
    return true;
}

// 通用设置读取（外观/语言/主题等持久化）
QString DatabaseManager::getSetting(const QString &key, const QString &defaultValue)
{
    QSqlQuery query;
    query.prepare(QStringLiteral("SELECT value FROM app_settings WHERE key = :k"));
    query.bindValue(":k", key);
    if (query.exec() && query.next()) {
        return query.value(0).toString();
    }
    return defaultValue;
}

// 通用设置写入（外观/语言/主题等持久化）
bool DatabaseManager::setSetting(const QString &key, const QString &value)
{
    QSqlQuery query;
    query.prepare(QStringLiteral(
        "INSERT INTO app_settings (key, value) VALUES (:k, :v) "
        "ON CONFLICT(key) DO UPDATE SET value = :v"));
    query.bindValue(":k", key);
    query.bindValue(":v", value);
    if (!query.exec()) {
        qWarning() << "[数据库] 写入设置失败:" << key << query.lastError().text();
        return false;
    }
    return true;
}

QString DatabaseManager::importScreenshot(int gameId, const QString &sourcePath)
{
    if (sourcePath.isEmpty()) return QString();

    QString root = getMemoryRoot();
    if (root.isEmpty()) {
        qWarning() << "[回忆] 未设置回忆根目录";
        return QString();
    }

    // 创建游戏子文件夹
    QString gameDir = root + "/" + QString::number(gameId);
    QDir().mkpath(gameDir);

    // 生成唯一文件名
    QFileInfo fi(sourcePath);
    QString ext = fi.suffix().isEmpty() ? "jpg" : fi.suffix();
    QString fileName = QStringLiteral("screenshot_%1.%2")
                           .arg(QDateTime::currentDateTime().toString("yyyyMMddHHmmsszzz"))
                           .arg(ext);
    QString destPath = gameDir + "/" + fileName;

    // 复制文件
    if (!QFile::copy(sourcePath, destPath)) {
        qWarning() << "[回忆] 复制图片失败:" << sourcePath << "->" << destPath;
        return QString();
    }

    // 存储相对路径（gameId/filename）
    QString relPath = QString::number(gameId) + "/" + fileName;

    // 计算新 sort_order：当前最大值 + 1
    QSqlQuery orderQuery;
    orderQuery.prepare(QStringLiteral("SELECT MAX(sort_order) FROM screenshots WHERE game_id = :gid"));
    orderQuery.bindValue(":gid", gameId);
    int nextOrder = 0;
    if (orderQuery.exec() && orderQuery.next()) {
        bool ok = false;
        int v = orderQuery.value(0).toInt(&ok);
        if (ok) nextOrder = v + 1;
    }

    // 写入数据库
    QSqlQuery query;
    query.prepare(QStringLiteral(
        "INSERT INTO screenshots (game_id, image_path, sort_order) VALUES (:gid, :path, :so)"));
    query.bindValue(":gid", gameId);
    query.bindValue(":path", relPath);
    query.bindValue(":so", nextOrder);
    if (!query.exec()) {
        qWarning() << "[回忆] 写入数据库失败:" << query.lastError().text();
        QFile::remove(destPath);
        return QString();
    }

    qDebug() << "[回忆] 已导入截图:" << relPath;
    return relPath;
}

QVariantList DatabaseManager::getScreenshots(int gameId)
{
    QVariantList result;
    QString root = getMemoryRoot();

    QSqlQuery query;
    query.prepare(QStringLiteral(
        "SELECT id, image_path, sort_order, scale, crop_mode, offset_x, offset_y FROM screenshots WHERE game_id = :gid "
        "ORDER BY sort_order ASC, id ASC"));
    query.bindValue(":gid", gameId);
    if (!query.exec()) {
        qWarning() << "[回忆] 查询截图失败:" << query.lastError().text();
        return result;
    }

    while (query.next()) {
        QVariantMap item;
        item["id"] = query.value(0).toInt();
        QString relPath = query.value(1).toString();
        item["path"] = root + "/" + relPath;
        item["sort_order"] = query.value(2).toInt();
        item["scale"] = query.value(3).toDouble();
        item["crop_mode"] = query.value(4).toInt();
        item["offset_x"] = query.value(5).toDouble();
        item["offset_y"] = query.value(6).toDouble();
        result.append(item);
    }

    return result;
}

bool DatabaseManager::deleteScreenshot(int id)
{
    // 先获取路径，删除文件
    QString root = getMemoryRoot();
    QSqlQuery query;
    query.prepare(QStringLiteral("SELECT image_path FROM screenshots WHERE id = :id"));
    query.bindValue(":id", id);
    if (query.exec() && query.next()) {
        QString fullPath = root + "/" + query.value(0).toString();
        QFile::remove(fullPath);
    }

    // 删除数据库记录
    QSqlQuery del;
    del.prepare(QStringLiteral("DELETE FROM screenshots WHERE id = :id"));
    del.bindValue(":id", id);
    if (!del.exec()) {
        qWarning() << "[回忆] 删除截图失败:" << del.lastError().text();
        return false;
    }
    qDebug() << "[回忆] 已删除截图 id:" << id;
    return true;
}

bool DatabaseManager::moveScreenshot(int id, int direction)
{
    // direction: -1 上移 / +1 下移
    if (direction != -1 && direction != 1) return false;

    // 查找当前记录
    QSqlQuery cur;
    cur.prepare(QStringLiteral("SELECT game_id, sort_order FROM screenshots WHERE id = :id"));
    cur.bindValue(":id", id);
    if (!cur.exec() || !cur.next()) {
        qWarning() << "[回忆] 移动失败：找不到 id" << id;
        return false;
    }
    int gameId = cur.value(0).toInt();
    int curOrder = cur.value(1).toInt();

    // 查找相邻记录（按 sort_order 排序）
    QSqlQuery neighbor;
    if (direction == -1) {
        neighbor.prepare(QStringLiteral(
            "SELECT id, sort_order FROM screenshots WHERE game_id = :gid AND sort_order < :cur "
            "ORDER BY sort_order DESC LIMIT 1"));
    } else {
        neighbor.prepare(QStringLiteral(
            "SELECT id, sort_order FROM screenshots WHERE game_id = :gid AND sort_order > :cur "
            "ORDER BY sort_order ASC LIMIT 1"));
    }
    neighbor.bindValue(":gid", gameId);
    neighbor.bindValue(":cur", curOrder);
    if (!neighbor.exec() || !neighbor.next()) {
        qDebug() << "[回忆] 无可移动的相邻记录";
        return false;   // 已到边界
    }
    int nId = neighbor.value(0).toInt();
    int nOrder = neighbor.value(1).toInt();

    // 交换两者的 sort_order（用临时值避免唯一约束问题——本表 sort_order 无唯一约束，直接交换）
    QSqlQuery upd1;
    upd1.prepare(QStringLiteral("UPDATE screenshots SET sort_order = :so WHERE id = :id"));
    upd1.bindValue(":so", nOrder);
    upd1.bindValue(":id", id);
    upd1.exec();

    QSqlQuery upd2;
    upd2.prepare(QStringLiteral("UPDATE screenshots SET sort_order = :so WHERE id = :id"));
    upd2.bindValue(":so", curOrder);
    upd2.bindValue(":id", nId);
    upd2.exec();

    qDebug() << "[回忆] 已移动截图 id:" << id << "方向:" << direction;
    return true;
}

bool DatabaseManager::reorderScreenshot(int id, int newIndex)
{
    // 拖拽排序：将指定截图移到新位置（0-based 索引）
    if (newIndex < 0) return false;

    // 1. 查找当前记录的 game_id
    QSqlQuery cur;
    cur.prepare(QStringLiteral("SELECT game_id FROM screenshots WHERE id = :id"));
    cur.bindValue(":id", id);
    if (!cur.exec() || !cur.next()) {
        qWarning() << "[回忆] 拖拽排序失败：找不到 id" << id;
        return false;
    }
    int gameId = cur.value(0).toInt();

    // 2. 获取该游戏所有截图（按 sort_order 升序）
    QSqlQuery list;
    list.prepare(QStringLiteral("SELECT id FROM screenshots WHERE game_id = :gid ORDER BY sort_order ASC"));
    list.bindValue(":gid", gameId);
    if (!list.exec()) return false;

    QVector<int> orderedIds;
    while (list.next()) orderedIds.append(list.value(0).toInt());
    if (orderedIds.isEmpty()) return false;

    // 3. 找到当前 id 在列表中的位置并移除
    int curPos = -1;
    for (int i = 0; i < orderedIds.size(); ++i) {
        if (orderedIds[i] == id) { curPos = i; break; }
    }
    if (curPos < 0) return false;
    orderedIds.removeAt(curPos);

    // 4. 在 newIndex 位置插入
    int target = qMin(newIndex, orderedIds.size());
    orderedIds.insert(target, id);

    // 5. 事务批量更新 sort_order
    QSqlDatabase db = QSqlDatabase::database();
    if (!db.transaction()) return false;
    QSqlQuery upd;
    upd.prepare(QStringLiteral("UPDATE screenshots SET sort_order = :so WHERE id = :id"));
    bool ok = true;
    for (int i = 0; i < orderedIds.size(); ++i) {
        upd.bindValue(":so", i);
        upd.bindValue(":id", orderedIds[i]);
        if (!upd.exec()) { ok = false; break; }
    }
    if (ok) {
        db.commit();
        qDebug() << "[回忆] 拖拽排序完成 id:" << id << "新位置:" << target;
        return true;
    } else {
        db.rollback();
        qWarning() << "[回忆] 拖拽排序事务失败，已回滚";
        return false;
    }
}

QVariantMap DatabaseManager::getScreenshotSettings(int gameId)
{
    QVariantMap settings;
    // 默认值：间隔 3000ms，淡入淡出 800ms
    settings["interval"] = 3000;
    settings["fade"] = 800;

    // 从 app_settings 读取，key 格式：ss_interval_<gameId> / ss_fade_<gameId>
    QSqlQuery q1;
    q1.prepare(QStringLiteral("SELECT value FROM app_settings WHERE key = :k"));
    q1.bindValue(":k", QStringLiteral("ss_interval_%1").arg(gameId));
    if (q1.exec() && q1.next()) {
        bool ok = false;
        int v = q1.value(0).toInt(&ok);
        if (ok && v > 0) settings["interval"] = v;
    }
    QSqlQuery q2;
    q2.prepare(QStringLiteral("SELECT value FROM app_settings WHERE key = :k"));
    q2.bindValue(":k", QStringLiteral("ss_fade_%1").arg(gameId));
    if (q2.exec() && q2.next()) {
        bool ok = false;
        int v = q2.value(0).toInt(&ok);
        if (ok && v >= 0) settings["fade"] = v;
    }
    return settings;
}

bool DatabaseManager::setScreenshotSettings(int gameId, int interval, int fade)
{
    bool ok = true;
    QSqlQuery query;
    query.prepare(QStringLiteral(
        "INSERT INTO app_settings (key, value) VALUES (:k, :v) "
        "ON CONFLICT(key) DO UPDATE SET value = :v"));

    query.bindValue(":k", QStringLiteral("ss_interval_%1").arg(gameId));
    query.bindValue(":v", interval);
    if (!query.exec()) ok = false;

    query.bindValue(":k", QStringLiteral("ss_fade_%1").arg(gameId));
    query.bindValue(":v", fade);
    if (!query.exec()) ok = false;

    if (!ok) qWarning() << "[回忆] 保存播放参数失败 gameId:" << gameId;
    else qDebug() << "[回忆] 已保存播放参数 gameId:" << gameId << "interval:" << interval << "fade:" << fade;
    return ok;
}

bool DatabaseManager::setScreenshotScale(int id, double scale)
{
    QSqlQuery query;
    query.prepare(QStringLiteral("UPDATE screenshots SET scale = :s WHERE id = :id"));
    query.bindValue(":s", scale);
    query.bindValue(":id", id);
    if (!query.exec()) {
        qWarning() << "[回忆] 设置缩放失败 id:" << id << query.lastError().text();
        return false;
    }
    return true;
}

bool DatabaseManager::setScreenshotCropMode(int id, int mode)
{
    QSqlQuery query;
    query.prepare(QStringLiteral("UPDATE screenshots SET crop_mode = :m WHERE id = :id"));
    query.bindValue(":m", mode);
    query.bindValue(":id", id);
    if (!query.exec()) {
        qWarning() << "[回忆] 设置裁剪模式失败 id:" << id << query.lastError().text();
        return false;
    }
    return true;
}

bool DatabaseManager::setScreenshotOffset(int id, double offsetX, double offsetY)
{
    QSqlQuery query;
    query.prepare(QStringLiteral("UPDATE screenshots SET offset_x = :x, offset_y = :y WHERE id = :id"));
    query.bindValue(":x", offsetX);
    query.bindValue(":y", offsetY);
    query.bindValue(":id", id);
    if (!query.exec()) {
        qWarning() << "[回忆] 设置位置偏移失败 id:" << id << query.lastError().text();
        return false;
    }
    return true;
}

int DatabaseManager::getScreenshotCount(int gameId)
{
    QSqlQuery query;
    query.prepare(QStringLiteral("SELECT COUNT(*) FROM screenshots WHERE game_id = :gid"));
    query.bindValue(":gid", gameId);
    if (query.exec() && query.next())
        return query.value(0).toInt();
    return 0;
}

bool DatabaseManager::addBgImage(const QString &imagePath, double opacity, double blur)
{
    if (imagePath.isEmpty()) return false;
    // 去重：同一路径不重复添加
    QSqlQuery check;
    check.prepare(QStringLiteral("SELECT id FROM bg_images WHERE image_path = :p"));
    check.bindValue(":p", imagePath);
    if (check.exec() && check.next()) {
        // 已存在则更新 opacity/blur
        QSqlQuery upd;
        upd.prepare(QStringLiteral("UPDATE bg_images SET opacity = :o, blur = :b WHERE image_path = :p"));
        upd.bindValue(":o", opacity);
        upd.bindValue(":b", blur);
        upd.bindValue(":p", imagePath);
        upd.exec();
        qDebug() << "[数据库] 背景图已存在，更新参数:" << imagePath;
        return true;
    }
    QSqlQuery query;
    query.prepare(QStringLiteral("INSERT INTO bg_images (image_path, opacity, blur) VALUES (:p, :o, :b)"));
    query.bindValue(":p", imagePath);
    query.bindValue(":o", opacity);
    query.bindValue(":b", blur);
    if (!query.exec()) {
        qWarning() << "[数据库] 添加背景图失败:" << query.lastError().text();
        return false;
    }
    qDebug() << "[数据库] 已添加背景图:" << imagePath << "opacity:" << opacity << "blur:" << blur;
    return true;
}

QVariantList DatabaseManager::getBgImages()
{
    QVariantList list;
    QSqlQuery query;
    if (!query.exec(QStringLiteral("SELECT id, image_path, opacity, blur, created_at FROM bg_images ORDER BY created_at DESC"))) {
        qWarning() << "[数据库] 查询背景图失败:" << query.lastError().text();
        return list;
    }
    while (query.next()) {
        QVariantMap item;
        item["id"] = query.value(0).toInt();
        item["imagePath"] = query.value(1).toString();
        item["opacity"] = query.value(2).toDouble();
        item["blur"] = query.value(3).toDouble();
        item["createdAt"] = query.value(4).toString();
        list.append(item);
    }
    return list;
}

bool DatabaseManager::deleteBgImage(int id)
{
    // 先获取路径，删除文件（图片和视频副本统一删除）
    QSqlQuery find;
    find.prepare(QStringLiteral("SELECT image_path FROM bg_images WHERE id = :id"));
    find.bindValue(":id", id);
    if (find.exec() && find.next()) {
        const QString path = find.value(0).toString();
        if (!path.isEmpty() && QFile::exists(path)) {
            QFile::remove(path);
            qDebug() << "[数据库] 已删除背景文件:" << path;
        }
    }
    QSqlQuery query;
    query.prepare(QStringLiteral("DELETE FROM bg_images WHERE id = :id"));
    query.bindValue(":id", id);
    if (!query.exec()) {
        qWarning() << "[数据库] 删除背景图记录失败:" << query.lastError().text();
        return false;
    }
    qDebug() << "[数据库] 已删除背景图记录 id:" << id;
    return true;
}

bool DatabaseManager::updateBgImage(int id, double opacity, double blur)
{
    QSqlQuery query;
    query.prepare(QStringLiteral("UPDATE bg_images SET opacity = :o, blur = :b WHERE id = :id"));
    query.bindValue(":o", opacity);
    query.bindValue(":b", blur);
    query.bindValue(":id", id);
    if (!query.exec()) {
        qWarning() << "[数据库] 更新背景图参数失败:" << query.lastError().text();
        return false;
    }
    qDebug() << "[数据库] 已更新背景图参数 id:" << id << "opacity:" << opacity << "blur:" << blur;
    return true;
}

bool DatabaseManager::resetIds()
{
    // 删除后重排：按创建顺序，把所有 id 重新设为 1,2,3...
    // 先记录 old_id -> new_id 的映射，再更新 screenshots.game_id
    QSqlQuery mapQuery;
    mapQuery.prepare(QStringLiteral(
        "SELECT id FROM games ORDER BY created_at, id"));
    QList<QPair<int,int>> idMap;   // (oldId, newId)
    if (mapQuery.exec()) {
        int newId = 1;
        while (mapQuery.next()) {
            idMap.append(qMakePair(mapQuery.value(0).toInt(), newId++));
        }
    }

    QSqlQuery q;
    if (!q.exec(QStringLiteral(
            "CREATE TABLE games_tmp (id INTEGER PRIMARY KEY, name TEXT NOT NULL, "
            "cover_path TEXT, types TEXT, rating REAL, status TEXT, "
            "play_time INTEGER, start_date TEXT, finish_date TEXT, notes TEXT, created_at TEXT)"))) {
        qWarning() << "[数据库] 重排建临时表失败:" << q.lastError().text();
        return false;
    }
    if (!q.exec(QStringLiteral(
            "INSERT INTO games_tmp (id, name, cover_path, types, rating, status, play_time, start_date, finish_date, notes, created_at) "
            "SELECT ROW_NUMBER() OVER (ORDER BY created_at, id), name, cover_path, types, rating, status, play_time, start_date, finish_date, notes, created_at FROM games"))) {
        qWarning() << "[数据库] 重排复制失败:" << q.lastError().text();
        return false;
    }
    if (!q.exec(QStringLiteral("DROP TABLE games"))) return false;
    if (!q.exec(QStringLiteral("ALTER TABLE games_tmp RENAME TO games"))) return false;
    q.exec(QStringLiteral("DELETE FROM sqlite_sequence WHERE name = 'games'"));  // 重置自增序列

    // 同步更新 screenshots 表的 game_id 引用
    for (const auto &pair : idMap) {
        if (pair.first == pair.second) continue;   // 未变化
        QSqlQuery upd;
        upd.prepare(QStringLiteral("UPDATE screenshots SET game_id = :new WHERE game_id = :old"));
        upd.bindValue(":new", pair.second);
        upd.bindValue(":old", pair.first);
        upd.exec();
    }

    qDebug() << "[数据库] id 已重排为连续（含 screenshots 引用同步）";
    return true;
}

QString DatabaseManager::importCover(const QString &sourcePath)
{
    if (sourcePath.isEmpty())
        return QString();

    // 复制到 data/covers/ 下，用时间戳生成唯一文件名，保留原扩展名
    const QString appDir = QCoreApplication::applicationDirPath();
    const QString coversDir = appDir + QStringLiteral("/data/covers");
    QDir().mkpath(coversDir);

    QFileInfo info(sourcePath);
    const QString ext = info.suffix().isEmpty() ? QStringLiteral("jpg") : info.suffix().toLower();
    const QString newName = QStringLiteral("cover_%1.%2")
        .arg(QDateTime::currentDateTime().toString("yyyyMMddHHmmsszzz"))
        .arg(ext);
    const QString dest = coversDir + "/" + newName;

    if (QFile::exists(dest)) QFile::remove(dest);
    if (!QFile::copy(sourcePath, dest)) {
        qWarning() << "[数据库] 复制封面失败:" << sourcePath << "->" << dest;
        return QString();
    }
    qDebug() << "[数据库] 封面已导入:" << dest;

    // 清理冗余：若源文件位于 data/crops/ 临时裁剪目录，复制成功后删除源
    const QString cropsDir = appDir + QStringLiteral("/data/crops");
    const QString normalizedSource = QFileInfo(sourcePath).absoluteFilePath();
    const QString normalizedCropsDir = QFileInfo(cropsDir).absoluteFilePath();
    if (normalizedSource.startsWith(normalizedCropsDir, Qt::CaseInsensitive)) {
        if (QFile::remove(sourcePath)) {
            qDebug() << "[数据库] 已清理裁剪临时文件:" << sourcePath;
        }
    }
    return dest;
}

QString DatabaseManager::importBgVideo(const QString &sourcePath)
{
    if (sourcePath.isEmpty())
        return QString();

    // 复制到 data/bg_videos/ 下，用时间戳生成唯一文件名，保留原扩展名
    const QString appDir = QCoreApplication::applicationDirPath();
    const QString videosDir = appDir + QStringLiteral("/data/bg_videos");
    QDir().mkpath(videosDir);

    QFileInfo info(sourcePath);
    const QString ext = info.suffix().isEmpty() ? QStringLiteral("mp4") : info.suffix().toLower();
    const QString newName = QStringLiteral("bg_video_%1.%2")
        .arg(QDateTime::currentDateTime().toString("yyyyMMddHHmmsszzz"))
        .arg(ext);
    const QString dest = videosDir + "/" + newName;

    if (QFile::exists(dest)) QFile::remove(dest);
    if (!QFile::copy(sourcePath, dest)) {
        qWarning() << "[数据库] 复制背景视频失败:" << sourcePath << "->" << dest;
        return QString();
    }
    qDebug() << "[数据库] 背景视频已导入:" << dest;
    return dest;
}

QString DatabaseManager::cropImage(const QString &sourcePath, int x, int y, int width, int height)
{
    QImage source(sourcePath);
    if (source.isNull()) {
        qWarning() << "[裁剪] 加载图片失败:" << sourcePath;
        return QString();
    }
    QImage cropped = source.copy(x, y, width, height);
    if (cropped.isNull()) {
        qWarning() << "[裁剪] 裁剪区域无效";
        return QString();
    }
    const QString appDir = QCoreApplication::applicationDirPath();
    const QString cropsDir = appDir + QStringLiteral("/data/crops");
    QDir().mkpath(cropsDir);
    const QString newName = QStringLiteral("bg_crop_%1.jpg")
        .arg(QDateTime::currentDateTime().toString("yyyyMMddHHmmsszzz"));
    const QString dest = cropsDir + "/" + newName;
    if (!cropped.save(dest, "JPG", 95)) {
        qWarning() << "[裁剪] 保存失败:" << dest;
        return QString();
    }
    qDebug() << "[裁剪] 已保存:" << dest;
    return dest;
}

// 清理 data/crops/ 中不被 bg_images 引用的冗余裁剪文件
// data/crops/ 存放 cropImage 的中间产物：封面裁剪的会被 importCover 复制走（应删除），
// 背景裁剪的（mode="bg"）直接作为背景路径使用（需保留），通过 bg_images 引用判断
void DatabaseManager::cleanupCropsDir()
{
    const QString appDir = QCoreApplication::applicationDirPath();
    const QString cropsDir = appDir + QStringLiteral("/data/crops");
    QDir dir(cropsDir);
    if (!dir.exists()) return;

    // 收集 bg_images 表中引用的所有路径（背景裁剪结果存于 data/crops/，需保留）
    QSet<QString> referenced;
    QSqlQuery query;
    if (query.exec(QStringLiteral("SELECT image_path FROM bg_images"))) {
        while (query.next()) {
            referenced.insert(QFileInfo(query.value(0).toString()).absoluteFilePath());
        }
    }

    // 删除 data/crops/ 中不被引用的冗余文件（封面裁剪中间产物）
    const QStringList files = dir.entryList(QDir::Files);
    int removed = 0;
    for (const QString &file : files) {
        const QString fullPath = dir.absoluteFilePath(file);
        if (!referenced.contains(QFileInfo(fullPath).absoluteFilePath())) {
            if (QFile::remove(fullPath)) ++removed;
        }
    }
    if (removed > 0) {
        qDebug() << "[数据库] 已清理 crops 冗余文件:" << removed << "个";
    }
}

bool DatabaseManager::addGame(const QString &name, const QStringList &types,
                              double rating, const QString &status, int playTime,
                              const QString &startDate, const QString &finishDate,
                              const QString &notes, const QString &coverPath)
{
    QSqlQuery query;
    query.prepare(QStringLiteral(
        "INSERT INTO games (name, types, rating, status, play_time, start_date, finish_date, notes, cover_path) "
        "VALUES (:name, :types, :rating, :status, :play_time, :start_date, :finish_date, :notes, :cover_path)"
    ));

    QJsonArray typeArray;
    for (const QString &t : types)
        typeArray.append(t);
    const QString typesJson = QString::fromUtf8(
        QJsonDocument(typeArray).toJson(QJsonDocument::Compact));

    query.bindValue(":name", name);
    query.bindValue(":types", typesJson);
    query.bindValue(":rating", rating);
    query.bindValue(":status", status);
    query.bindValue(":play_time", playTime);
    query.bindValue(":start_date", startDate);
    query.bindValue(":finish_date", finishDate);
    query.bindValue(":notes", notes);
    query.bindValue(":cover_path", coverPath);

    if (!query.exec()) {
        qWarning() << "[数据库] 添加游戏失败:" << query.lastError().text();
        return false;
    }
    qDebug() << "[数据库] 已添加游戏:" << name;
    return true;
}

bool DatabaseManager::deleteGame(int id)
{
    // 先删除该游戏的所有截图文件和记录
    QString root = getMemoryRoot();
    QSqlQuery ssQuery;
    ssQuery.prepare(QStringLiteral("SELECT id, image_path FROM screenshots WHERE game_id = :gid"));
    ssQuery.bindValue(":gid", id);
    if (ssQuery.exec()) {
        while (ssQuery.next()) {
            QString fullPath = root + "/" + ssQuery.value(1).toString();
            QFile::remove(fullPath);
        }
    }
    QSqlQuery ssDel;
    ssDel.prepare(QStringLiteral("DELETE FROM screenshots WHERE game_id = :gid"));
    ssDel.bindValue(":gid", id);
    ssDel.exec();

    // 删除该游戏的回忆子文件夹
    if (!root.isEmpty()) {
        QDir gameDir(root + "/" + QString::number(id));
        gameDir.removeRecursively();
    }

    // 删除该游戏的回忆播放参数
    QSqlQuery setDel1;
    setDel1.prepare(QStringLiteral("DELETE FROM app_settings WHERE key = :k"));
    setDel1.bindValue(":k", QStringLiteral("ss_interval_%1").arg(id));
    setDel1.exec();
    QSqlQuery setDel2;
    setDel2.prepare(QStringLiteral("DELETE FROM app_settings WHERE key = :k"));
    setDel2.bindValue(":k", QStringLiteral("ss_fade_%1").arg(id));
    setDel2.exec();

    // 删除该游戏的封面文件（仅限 data/covers/ 内的文件，避免误删用户外部图片）
    QSqlQuery coverQuery;
    coverQuery.prepare(QStringLiteral("SELECT cover_path FROM games WHERE id = :id"));
    coverQuery.bindValue(":id", id);
    if (coverQuery.exec() && coverQuery.next()) {
        const QString coverPath = coverQuery.value(0).toString();
        if (!coverPath.isEmpty()) {
            const QString coversDir = QCoreApplication::applicationDirPath()
                                      + QStringLiteral("/data/covers");
            const QString normalizedCover = QFileInfo(coverPath).absoluteFilePath();
            const QString normalizedCoversDir = QFileInfo(coversDir).absoluteFilePath();
            if (normalizedCover.startsWith(normalizedCoversDir, Qt::CaseInsensitive)
                && QFile::exists(coverPath)) {
                if (QFile::remove(coverPath)) {
                    qDebug() << "[数据库] 已删除封面文件:" << coverPath;
                }
            }
        }
    }

    QSqlQuery query;
    query.prepare(QStringLiteral("DELETE FROM games WHERE id = :id"));
    query.bindValue(":id", id);

    if (!query.exec()) {
        qWarning() << "[数据库] 删除失败:" << query.lastError().text();
        return false;
    }
    qDebug() << "[数据库] 已删除游戏 id:" << id << "（含回忆文件/记录/参数/封面）";
    resetIds();   // 删除后重排 id 连续（1,2,3...）
    return true;
}

bool DatabaseManager::updateGame(int id, const QString &name, const QStringList &types,
                                 double rating, const QString &status, int playTime,
                                 const QString &startDate, const QString &finishDate,
                                 const QString &notes, const QString &coverPath)
{
    QSqlQuery query;
    query.prepare(QStringLiteral(
        "UPDATE games SET name = :name, types = :types, rating = :rating, "
        "status = :status, play_time = :play_time, start_date = :start_date, "
        "finish_date = :finish_date, notes = :notes, cover_path = :cover_path WHERE id = :id"
    ));

    QJsonArray typeArray;
    for (const QString &t : types)
        typeArray.append(t);
    const QString typesJson = QString::fromUtf8(
        QJsonDocument(typeArray).toJson(QJsonDocument::Compact));

    query.bindValue(":name", name);
    query.bindValue(":types", typesJson);
    query.bindValue(":rating", rating);
    query.bindValue(":status", status);
    query.bindValue(":play_time", playTime);
    query.bindValue(":start_date", startDate);
    query.bindValue(":finish_date", finishDate);
    query.bindValue(":notes", notes);
    query.bindValue(":cover_path", coverPath);
    query.bindValue(":id", id);

    if (!query.exec()) {
        qWarning() << "[数据库] 更新失败:" << query.lastError().text();
        return false;
    }
    qDebug() << "[数据库] 已更新游戏 id:" << id;
    return true;
}

int DatabaseManager::getGameCount()
{
    QSqlQuery query;
    if (!query.exec(QStringLiteral("SELECT COUNT(*) FROM games"))) {
        qWarning() << "[数据库] 统计总数失败:" << query.lastError().text();
        return 0;
    }
    if (query.next())
        return query.value(0).toInt();
    return 0;
}

double DatabaseManager::getAverageRating()
{
    QSqlQuery query;
    if (!query.exec(QStringLiteral("SELECT AVG(rating) FROM games WHERE rating > 0"))) {
        qWarning() << "[数据库] 平均分查询失败:" << query.lastError().text();
        return 0;
    }
    if (query.next()) {
        QVariant v = query.value(0);
        if (!v.isNull()) return v.toDouble();
    }
    return 0;
}

QVariantMap DatabaseManager::getStatusCounts()
{
    QVariantMap counts;
    QSqlQuery query;
    if (!query.exec(QStringLiteral("SELECT status, COUNT(*) FROM games GROUP BY status"))) {
        qWarning() << "[数据库] 状态统计失败:" << query.lastError().text();
        return counts;
    }
    while (query.next())
        counts.insert(query.value(0).toString(), query.value(1).toInt());
    return counts;
}

QVariantMap DatabaseManager::getTypeCounts()
{
    // types 是 JSON 数组，逐行解析统计每个类型出现次数
    QVariantMap counts;
    QSqlQuery query;
    if (!query.exec(QStringLiteral("SELECT types FROM games"))) {
        qWarning() << "[数据库] 类型统计失败:" << query.lastError().text();
        return counts;
    }
    while (query.next()) {
        const QString typesJson = query.value(0).toString();
        if (typesJson.isEmpty()) continue;
        const QJsonArray arr = QJsonDocument::fromJson(typesJson.toUtf8()).array();
        for (const QJsonValue &v : arr) {
            const QString t = v.toString();
            if (!t.isEmpty())
                counts[t] = counts.value(t).toInt() + 1;
        }
    }
    return counts;
}

bool DatabaseManager::exportData(const QString &filePath)
{
    QSqlQuery query;
    if (!query.exec(QStringLiteral(
            "SELECT name, cover_path, types, rating, status, play_time, start_date, finish_date, notes FROM games"))) {
        qWarning() << "[数据库] 导出查询失败:" << query.lastError().text();
        return false;
    }
    QJsonArray arr;
    while (query.next()) {
        QJsonObject o;
        o["name"]        = query.value(0).toString();
        o["cover_path"]  = query.value(1).toString();
        o["types"]       = query.value(2).toString();
        o["rating"]      = query.value(3).toDouble();
        o["status"]      = query.value(4).toString();
        o["play_time"]   = query.value(5).toInt();
        o["start_date"]  = query.value(6).toString();
        o["finish_date"] = query.value(7).toString();
        o["notes"]       = query.value(8).toString();
        arr.append(o);
    }

    QFile f(filePath);
    if (!f.open(QIODevice::WriteOnly)) {
        qWarning() << "[数据库] 导出写文件失败:" << filePath;
        return false;
    }
    f.write(QJsonDocument(arr).toJson(QJsonDocument::Indented));
    qDebug() << "[数据库] 已导出" << arr.size() << "条到" << filePath;
    return true;
}

bool DatabaseManager::exportTxt(const QString &filePath)
{
    QSqlQuery query;
    query.exec(QStringLiteral(
        "SELECT name, types, rating, status, play_time, start_date, finish_date, notes FROM games ORDER BY created_at DESC"));

    QString text = QStringLiteral("galgame 游玩记录\n========================\n\n");
    int i = 1;
    while (query.next()) {
        text += QStringLiteral("%1. %2").arg(i++).arg(query.value(0).toString());
        if (query.value(2).toDouble() > 0)
            text += QStringLiteral("   %1 分").arg(query.value(2).toDouble(), 0, 'f', 1);
        if (!query.value(3).toString().isEmpty())
            text += QStringLiteral("   [%1]").arg(query.value(3).toString());
        if (query.value(4).toInt() > 0)
            text += QStringLiteral("   %1h").arg(query.value(4).toInt());
        text += "\n";

        const QJsonArray tArr = QJsonDocument::fromJson(query.value(1).toString().toUtf8()).array();
        if (!tArr.isEmpty()) {
            QStringList ts;
            for (const QJsonValue &v : tArr) ts << v.toString();
            text += QStringLiteral("   类型：%1\n").arg(ts.join("、"));
        }
        if (!query.value(7).toString().isEmpty())
            text += QStringLiteral("   评价：%1\n").arg(query.value(7).toString());
        text += "\n";
    }

    QFile f(filePath);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Text)) return false;
    f.write(text.toUtf8());
    return true;
}

bool DatabaseManager::exportCsv(const QString &filePath)
{
    QSqlQuery query;
    query.exec(QStringLiteral(
        "SELECT name, cover_path, types, rating, status, play_time, start_date, finish_date, notes FROM games"));

    QString csv = QStringLiteral("名称,封面路径,类型,评分,状态,游玩时长(小时),开始日期,完成日期,评价\n");
    while (query.next()) {
        const QJsonArray tArr = QJsonDocument::fromJson(query.value(2).toString().toUtf8()).array();
        QStringList ts;
        for (const QJsonValue &v : tArr) ts << v.toString();

        QStringList row;
        row << csvCell(query.value(0).toString())
            << csvCell(query.value(1).toString())
            << csvCell(ts.join("/"))
            << QString::number(query.value(3).toDouble())
            << csvCell(query.value(4).toString())
            << QString::number(query.value(5).toInt())
            << csvCell(query.value(6).toString())
            << csvCell(query.value(7).toString())
            << csvCell(query.value(8).toString());
        csv += row.join(",") + "\n";
    }

    QFile f(filePath);
    if (!f.open(QIODevice::WriteOnly)) return false;
    f.write("\xEF\xBB\xBF");
    f.write(csv.toUtf8());
    return true;
}

QString DatabaseManager::csvCell(const QString &s)
{
    // 含逗号/引号/换行的字段，用双引号包裹，内部引号双写转义
    if (s.contains(',') || s.contains('"') || s.contains('\n'))
        return "\"" + QString(s).replace("\"", "\"\"") + "\"";
    return s;
}

bool DatabaseManager::importData(const QString &filePath)
{
    QFile f(filePath);
    if (!f.open(QIODevice::ReadOnly)) {
        qWarning() << "[数据库] 导入读文件失败:" << filePath;
        return false;
    }
    const QJsonArray arr = QJsonDocument::fromJson(f.readAll()).array();

    QSqlDatabase db = QSqlDatabase::database();
    db.transaction();   // 事务包装：批量插入大幅提速

    int count = 0;
    for (const QJsonValue &v : arr) {
        const QJsonObject o = v.toObject();
        // types 是 JSON 字符串，解析回 list
        QStringList types;
        const QJsonDocument td = QJsonDocument::fromJson(o.value("types").toString().toUtf8());
        for (const QJsonValue &t : td.array())
            types << t.toString();

        if (addGame(o.value("name").toString(), types, o.value("rating").toDouble(),
                    o.value("status").toString(), o.value("play_time").toInt(),
                    o.value("start_date").toString(), o.value("finish_date").toString(),
                    o.value("notes").toString(), o.value("cover_path").toString()))
            ++count;
    }

    db.commit();
    qDebug() << "[数据库] 已导入" << count << "条";
    return true;
}
