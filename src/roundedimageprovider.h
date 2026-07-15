#ifndef ROUNDEDIMAGEPROVIDER_H
#define ROUNDEDIMAGEPROVIDER_H

#include <QQuickImageProvider>
#include <QPixmap>
#include <QPainter>
#include <QPainterPath>
#include <QUrl>

// 圆角图片提供器：按目标显示尺寸生成抗锯齿圆角图片
// QML 用 image://rounded/宽x高/文件路径 请求（宽x高 = Image 组件尺寸 = 窗口尺寸）
// 用 QPixmap + CompositionMode_DestinationIn 合成圆角 alpha 通道（32bit ARGB 抗锯齿）
// 仅处理静态图片；GIF/视频保持原显示方式（由 C++ setMask 全局裁剪）
class RoundedImageProvider : public QQuickImageProvider {
public:
    RoundedImageProvider() : QQuickImageProvider(QQuickImageProvider::Pixmap) {}

    QPixmap requestPixmap(const QString &id, QSize *size, const QSize &requestedSize) override {
        // id 格式：宽x高/文件绝对路径（如 "960x540/C:/photos/bg.jpg"）
        // 宽x高 = 目标显示尺寸（Image 组件尺寸），用于先缩放原图再圆角，确保圆角在最终显示的四角
        int targetW = 0, targetH = 0;
        QString path;
        const int slashIdx = id.indexOf('/');
        if (slashIdx > 0) {
            const QString sizePart = id.left(slashIdx);
            const int xIdx = sizePart.indexOf('x');
            if (xIdx > 0) {
                targetW = sizePart.left(xIdx).toInt();
                targetH = sizePart.mid(xIdx + 1).toInt();
            }
            path = id.mid(slashIdx + 1);
        } else {
            path = id;
        }
        // URL 解码（Windows 路径中的特殊字符）
        path = QUrl::fromPercentEncoding(path.toUtf8());

        QPixmap source(path);
        if (source.isNull()) {
            if (size) size->setWidth(0), size->setHeight(0);
            return QPixmap();
        }

        // 目标尺寸：优先用 id 中的宽x高，其次 requestedSize，最后用原图尺寸
        int w = targetW > 0 ? targetW : (requestedSize.width() > 0 ? requestedSize.width() : source.width());
        int h = targetH > 0 ? targetH : (requestedSize.height() > 0 ? requestedSize.height() : source.height());

        // 1. 先把原图缩放到目标尺寸（PreserveAspectCrop 裁剪模式：保持宽高比填满，超出部分裁剪）
        QPixmap scaled = source.size() == QSize(w, h) ? source :
            source.scaled(w, h, Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation);
        // 居中裁剪到目标尺寸（模拟 PreserveAspectCrop）
        if (scaled.width() > w || scaled.height() > h) {
            int x = (scaled.width() - w) / 2;
            int y = (scaled.height() - h) / 2;
            scaled = scaled.copy(x, y, w, h);
        }

        // 2. 圆角半径（与 C++ setMask 的 cornerRadius 保持一致）
        const int radius = 8;

        // 3. 创建透明背景的结果 pixmap（32bit ARGB），尺寸 = 目标显示尺寸
        QPixmap result(w, h);
        result.fill(Qt::transparent);

        QPainter painter(&result);
        painter.setRenderHint(QPainter::Antialiasing);

        // 4. 先绘制圆角矩形（白色不透明），作为 alpha 形状
        painter.setBrush(Qt::white);
        painter.setPen(Qt::NoPen);
        painter.drawRoundedRect(result.rect(), radius, radius);

        // 5. 切换为 DestinationIn 合成模式：保留目标（圆角矩形）与源（缩放后原图）的交集 alpha
        //    即圆角矩形内的图片像素保留，圆角外的像素 alpha 归零变透明
        painter.setCompositionMode(QPainter::CompositionMode_DestinationIn);
        painter.drawPixmap(0, 0, scaled);

        painter.end();

        if (size) *size = result.size();
        return result;
    }
};

#endif // ROUNDEDIMAGEPROVIDER_H
