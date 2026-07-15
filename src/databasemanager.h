#ifndef DATABASEMANAGER_H
#define DATABASEMANAGER_H

#include <QObject>
#include <QString>
#include <QStringList>
#include <qqmlintegration.h>
#include <QVariantMap>

// 数据库管理类：打开 SQLite、建表、增删改查、封面导入。
// 用 QML_ELEMENT 注册到 galgame 模块。对应 galgame.md 第 4.4 节。
class DatabaseManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
public:
    explicit DatabaseManager(QObject *parent = nullptr);

    Q_INVOKABLE bool initializeDatabase();

    // 把选中的封面图片复制到 data/covers/，返回复制后的路径（空串=失败）
    Q_INVOKABLE QString importCover(const QString &sourcePath);

    // 把选中的背景视频复制到 data/bg_videos/，返回复制后的路径（空串=失败）
    Q_INVOKABLE QString importBgVideo(const QString &sourcePath);

    // 裁剪图片，保存裁剪后的图片到 data/covers/，返回裁剪后的路径
    // cropRect: x, y, width, height (相对原图像素坐标)
    Q_INVOKABLE QString cropImage(const QString &sourcePath, int x, int y, int width, int height);

    Q_INVOKABLE bool addGame(const QString &name, const QStringList &types,
                             double rating, const QString &status, int playTime,
                             const QString &startDate, const QString &finishDate,
                             const QString &notes, const QString &coverPath);

    Q_INVOKABLE bool deleteGame(int id);

    Q_INVOKABLE bool updateGame(int id, const QString &name, const QStringList &types,
                                double rating, const QString &status, int playTime,
                                const QString &startDate, const QString &finishDate,
                                const QString &notes, const QString &coverPath);

    Q_INVOKABLE int getGameCount();

    // 导出全部游戏为 JSON 文件 / 从 JSON 文件导入
    Q_INVOKABLE bool exportData(const QString &filePath);   // JSON
    Q_INVOKABLE bool exportTxt(const QString &filePath);    // TXT 纯文本
    Q_INVOKABLE bool exportCsv(const QString &filePath);    // CSV（Excel/WPS 可打开）
    Q_INVOKABLE bool importData(const QString &filePath);

    // 统计：平均分（排除未评分）、各状态数量、各类型数量
    Q_INVOKABLE double getAverageRating();
    Q_INVOKABLE QVariantMap getStatusCounts();
    Q_INVOKABLE QVariantMap getTypeCounts();

    // 背景图片历史：添加/查询/删除
    Q_INVOKABLE bool addBgImage(const QString &imagePath, double opacity = 0.35, double blur = 0.5);
    Q_INVOKABLE QVariantList getBgImages();
    Q_INVOKABLE bool deleteBgImage(int id);
    Q_INVOKABLE bool updateBgImage(int id, double opacity, double blur);

    // 回忆模块（截图）：根目录配置、导入、查询、删除、排序、全局参数
    Q_INVOKABLE QString getMemoryRoot();
    Q_INVOKABLE bool setMemoryRoot(const QString &path);

    // 通用设置读写（外观/语言/主题等持久化，存入 app_settings 表）
    Q_INVOKABLE QString getSetting(const QString &key, const QString &defaultValue = QString());
    Q_INVOKABLE bool setSetting(const QString &key, const QString &value);
    Q_INVOKABLE QString importScreenshot(int gameId, const QString &sourcePath);
    Q_INVOKABLE QVariantList getScreenshots(int gameId);
    Q_INVOKABLE bool deleteScreenshot(int id);
    Q_INVOKABLE bool moveScreenshot(int id, int direction);            // direction: -1 上移 / +1 下移
    Q_INVOKABLE bool reorderScreenshot(int id, int newIndex);          // 拖拽排序：将截图移到新位置（0-based）
    Q_INVOKABLE QVariantMap getScreenshotSettings(int gameId);          // 全局：interval(ms)/fade(ms)
    Q_INVOKABLE bool setScreenshotSettings(int gameId, int interval, int fade);
    Q_INVOKABLE bool setScreenshotScale(int id, double scale);          // 设置单张截图的缩放比例（0.1–10.0）
    Q_INVOKABLE bool setScreenshotCropMode(int id, int mode);           // 0=适配 1=填充
    Q_INVOKABLE bool setScreenshotOffset(int id, double offsetX, double offsetY);  // 设置单张截图的位置偏移
    Q_INVOKABLE int getScreenshotCount(int gameId);

private:
    bool createGamesTable();
    bool createBgImagesTable();
    bool createScreenshotsTable();
    bool createSettingsTable();
    static QString csvCell(const QString &s);   // CSV 字段转义
    static QString typesToJson(const QStringList &types);  // QStringList → JSON 数组字符串
    bool resetIds();   // 删除后重排所有 id 连续（1,2,3...）
    void cleanupCropsDir();   // 清理 data/crops/ 中不被 bg_images 引用的冗余裁剪文件
};

#endif // DATABASEMANAGER_H
