#include <QApplication>
#include <QQmlApplicationEngine>
#include <QAbstractNativeEventFilter>

// galgame 游玩记录 — 程序入口
// 用 QApplication（而非 QGuiApplication）：QtCharts 的 QML ChartView 内部依赖
// QGraphicsView / QtWidgets，必须用 QApplication 初始化 Widgets，否则崩溃。

#ifdef Q_OS_WIN
#include <windows.h>
#include <windowsx.h>
#include <cmath>

// 无边框窗口边缘缩放支持：拦截 WM_NCHITTEST，让 Windows 识别窗口边缘 6px 为缩放区
// 适用于所有设置了 Qt::FramelessWindowHint 的窗口（Windows 上对应 WS_POPUP 样式）
// 中央区域返回 false 交由 Qt 默认处理（HTCLIENT），QML 侧用 startSystemMove() 处理拖动
class FramelessResizeFilter : public QAbstractNativeEventFilter {
public:
    bool nativeEventFilter(const QByteArray &eventType, void *message, qintptr *result) override {
        if (eventType != "windows_generic_MSG")
            return false;

        MSG *msg = static_cast<MSG*>(message);
        if (msg->message != WM_NCHITTEST)
            return false;

        // 只处理无边框窗口（WS_POPUP 样式），避免影响系统对话框/菜单
        const LONG style = GetWindowLong(msg->hwnd, GWL_STYLE);
        if (!(style & WS_POPUP))
            return false;

        const LONG x = GET_X_LPARAM(msg->lParam);
        const LONG y = GET_Y_LPARAM(msg->lParam);

        RECT winRect;
        GetWindowRect(msg->hwnd, &winRect);

        const int border = 6;  // 边缘缩放感应区宽度
        const bool left   = x < winRect.left + border;
        const bool right  = x >= winRect.right - border;
        const bool top    = y < winRect.top + border;
        const bool bottom = y >= winRect.bottom - border;

        if (top && left)     { *result = HTTOPLEFT;     return true; }
        if (top && right)    { *result = HTTOPRIGHT;    return true; }
        if (bottom && left)  { *result = HTBOTTOMLEFT;  return true; }
        if (bottom && right) { *result = HTBOTTOMRIGHT; return true; }
        if (left)            { *result = HTLEFT;        return true; }
        if (right)           { *result = HTRIGHT;       return true; }
        if (top)             { *result = HTTOP;         return true; }
        if (bottom)          { *result = HTBOTTOM;      return true; }

        return false;  // 中央区域由 QML 处理（startSystemMove）
    }
};
#endif

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    QQmlApplicationEngine engine;
    engine.loadFromModule("galgame", "Main");

    if (engine.rootObjects().isEmpty())
        return -1;

#ifdef Q_OS_WIN
    // 安装全局无边框窗口缩放过滤器（自动适配所有 Qt::FramelessWindowHint 窗口）
    app.installNativeEventFilter(new FramelessResizeFilter);
#endif

    return app.exec();
}
