> 这是移植开始时的调研记录，文中的计划和“尚未验证”状态仅对应当时。当前功能与验证范围请见[项目主页](../README.md)和[安装说明](INSTALL_MACOS.md)。

# Apple Silicon macOS 中文汉化路径

调研日期：2026-10-19。

## 结论与基线

可行。推荐以 aristocratos/btop 上游为主线，择取 btop-cn 翻译模块和界面接入点，补齐中文列宽及语言状态管理，不整体覆盖上游文件。

参考项目：
- https://github.com/aristocratos/btop （本地提交 4792b0700e617cb2ee5ffbced50c1e52528b912a）
- https://github.com/dijiaozhibei-top/btop-cn （此次下载 main 源码快照，未取得提交号）

中文分支参考压缩包 SHA-256：35438c71664ee388c0ef846cf4aa9437c2246d0f94d8f1831351e674884e3d40。

## 已做的构建验证

本机为 arm64，Apple Clang 17.0.0，系统提供的 libc++ 通过上游 C++23 检测，包括 expected、ranges::to、optional monads。

两个项目均使用 CMake、Release、关闭 GPU 和 LTO、关闭测试完成编译链接；file 确认为 Mach-O 64-bit executable arm64；--version 正常返回。中文分支显示版本 1.4.7。

中文分支产物的 otool -L 仅列出系统 CoreFoundation、IOKit、libc++、libSystem，无 Homebrew 绝对路径依赖。该结果不代表已验证旧版 macOS 兼容性。

另外，上游开启 GPU 的 arm64 构建也已成功完成编译链接；GPU 实际读数尚未运行验证。

尚未验证：完整交互中文界面、鼠标区域、语言切换、长时间运行、各 M 系列机型、最低 macOS 版本。编译成功不等于完整汉化验收通过。

## 阶段一：建立可复现的原生构建

先固定上游提交，验证 CPU、内存、磁盘、网络、进程，GPU 单独验收。当前机器不必为初次构建额外安装 LLVM；其他机器应以 CMake 功能检测为准，编译器版本号不能替代标准库检测。

```sh
cmake -S . -B build/macos-arm64 \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DBUILD_TESTING=OFF \
  -DBTOP_STATIC=OFF \
  -DBTOP_GPU=OFF \
  -DBTOP_LTO=OFF
cmake --build build/macos-arm64 -j 4
file build/macos-arm64/btop
build/macos-arm64/btop --version
otool -L build/macos-arm64/btop
```

BUILD_TESTING=OFF 用于首轮产品构建，避免默认下载 GoogleTest；后续单元测试另建测试目录并启用测试。lowdown 缺失只会跳过手册生成。

## 阶段二：移入汉化层并修正其实现

1. 参考 btop-cn 的 src/btop_locale.hpp、src/btop_locale.cpp，移入中英文词条，在 CMakeLists.txt 中登记源文件。
2. 先修复语言状态：init 更新 current_lang；切换英文时不残留中文映射；非法语言有明确回退。当前参考实现 current_lang 一直为 en，init 在检查英文前已插入三条中文，且不清空 translations，不能直接复用。
3. get 当前返回 const string&，未命中时返回调用者 key 的引用；若传入临时字符串，跨表达式保存引用会悬空。建议返回 string 或使用生命周期明确的静态词条 string_view，并测试未命中路径。
4. 配置增加 lang，保留现有配置键及枚举值。首版可只支持重启后生效；若要热切换，应在安全时机切换不可变词表并清除菜单、标题缓存，避免渲染线程与词表修改并发。
5. 初始化放在配置读取后、渲染前。中文分支默认配置实际为 en，不能仅凭 README 假定默认中文。
6. 分批接入 btop_menu.cpp（帮助/设置/弹窗）、btop_draw.cpp（面板/表头/按钮）、btop.cpp（无面板提示）；再覆盖 CLI 文案及配置注释。
7. 参考词条需核对上游现有英文；以整句或稳定 ID 做键，带参数文案使用格式占位符。避免沿用 enu、erminate 等拆词翻译，按钮采用“菜单(m)”等独立快捷键样式。

## 阶段三：解决中文列宽

这是主要工作量，不能靠搜索替换完成。

- 统一按终端列宽处理测量、裁剪、居中和填充；中文通常占两列，UTF-8 字节数不等于显示宽度。
- btop_tools.cpp 的 ljust/rjust/cjust 即使传入 wide，也在补空格时调用默认 ulen；应统一计量，避免无符号减法先下溢。
- 检查 wide_ulen、uresize/luresize 的转换缓冲区、UTF-8 边界、无效序列和组合字符；uresize 宽字符分支按 wchar 数分配字节缓冲，不适合直接作为可靠的中文裁剪实现。
- 设置标题目前仍调用 cjust(..., 29) 默认字节模式，需改为列宽接口；说明区域增加按列宽换行与分页。
- main menu 的 OPTIONS/HELP/QUIT 是三行字符画，应改为中文文本菜单并同步更新选中效果、宽度和点击区域。
- 所有按钮、面板标题、进程表头同步计算显示宽度和 mouse_mappings；窄窗口可使用短中文标签或保留 CPU/GPU/PID 等标准缩写。
- ANSI 样式转义不计入文本宽度；原配置键、进程名、路径、信号名和数据字段不做翻译。

## 阶段四：Apple Silicon 专项验证

保留上游 src/osx 采集实现，先不移植 Linux GPU 或静态链接补丁。

基础版通过后，用独立构建目录开启 -DBTOP_GPU=ON，验证 arm64 路径的 IOReport 链接与采集行为。不能把 NVIDIA/AMD/Linux 的功能说明照搬成 Apple GPU 支持承诺。

测试 Terminal.app、iTerm2 中的 UTF-8 中文字体、浅深主题、80×24/120×40 等尺寸及拖动缩放。检查帮助分页、设置换行、进程详情、过滤输入、鼠标点击、重启读取语言。先以普通用户运行，按实际采集错误分析权限需求。

## 阶段五：打包和安装

- 输出 btop-zh-macos-arm64.tar.gz，内含 btop-zh、themes、LICENSE、中文说明与 SHA-256；保留两项目适用的版权及修改说明。
- 二进制命名之外，还需实现独立配置目录，例如 ~/.config/btop-zh，避免覆盖原版配置；仅改文件名不保证配置隔离。
- 不使用 btop-cn 的 _install.sh：它将 arm64 映射到 linux-aarch64，且使用 GNU sed -i 语法，不适合 macOS。
- 使用 macOS 专用安装脚本，先判断 uname -s 为 Darwin，再判断 uname -m 为 arm64，默认安装到用户可写目录。
- 最低 macOS 版本必须在选定部署目标和实际旧系统上验证，不能由本机编译成功推断。发布前检查依赖路径；如需分发签名/公证，另行配置签名身份。

## 验收顺序

A. 原生编译及版本检查 → B. 语言模块状态/回退测试 → C. 帮助和设置中文 → D. 主面板列宽和鼠标 → E. GPU 与多终端 → F. 可重复安装包。

有针对性的测试包括：中英文初始化及 zh→en 切换、缺失词条、中文/ASCII 混排裁剪不破坏 UTF-8、窄布局不产生超大填充、按钮可见范围与鼠标命中一致。

预估：熟悉该代码的开发者做出基础可用版本约 1–2 个工作日；补齐布局、回归和打包约再需 2–4 个工作日，取决于热切换、GPU 和旧系统支持范围。这是范围估算，不是交付承诺。
