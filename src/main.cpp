#include <QApplication>
#include <QQmlApplicationEngine>

// galgame 游玩记录 — 程序入口
// 用 QApplication（而非 QGuiApplication）：QtCharts 的 QML ChartView 内部依赖
// QGraphicsView / QtWidgets，必须用 QApplication 初始化 Widgets，否则崩溃。
int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    QQmlApplicationEngine engine;
    engine.loadFromModule("galgame", "Main");

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
