cmake_minimum_required(VERSION 3.16)

# 修复 MinGW 编译器无法创建临时文件的问题
# （Qt Creator 进程环境中 TMP/TEMP 可能丢失，导致 g++.exe 回退到 C:\Windows\ 无写权限）
# 必须在 project() 之前设置，因为 project() 会触发编译器检测（try_compile）
if(NOT DEFINED ENV{TMP} AND NOT DEFINED ENV{TEMP})
    set(ENV{TMP} "C:/Temp")
    set(ENV{TEMP} "C:/Temp")
endif()

project(galgame VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Quick QuickControls2 QuickDialogs2 Charts Sql Qml Widgets Multimedia)

qt_standard_project_setup(REQUIRES 6.5)

# MinGW 大文件支持：QML 编译为 C++ 后节区数可能超过 32767 限制
if(MINGW)
    add_compile_options(-Wa,-mbig-obj)
endif()

# 可执行程序：入口 + C++ 后端类
qt_add_executable(galgame
    src/main.cpp
    src/databasemanager.cpp
    src/gamelistmodel.cpp
)

# QML 模块：URI 为 galgame
qt_add_qml_module(galgame
    URI galgame
    VERSION 1.0
    QML_FILES
        qml/Main.qml
)

# 让 src/ 下的头文件可被 include（QML 类型注册需要）
target_include_directories(galgame PRIVATE src)

target_link_libraries(galgame PRIVATE
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::QuickDialogs2
    Qt6::Charts
    Qt6::Sql
    Qt6::Widgets
)

set_target_properties(galgame PROPERTIES
    WIN32_EXECUTABLE TRUE
)
