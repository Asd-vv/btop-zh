# macOS 安装、构建与验证

本文中的构建和测试命令均在仓库根目录执行。

基于 aristocratos/btop 当前源码（上游提交 `4792b07`），参考 dijiaozhibei-top/btop-cn 移入翻译表及界面翻译。保留上游 macOS 采集实现，使用原生 arm64 编译。

## 一键安装

打开 `dist/btop-zh-macos-arm64.dmg`，双击“安装 btop-zh.app”。也可解压 ZIP 版本，双击 `Install.command`。安装完成后重新打开终端，直接输入 `btop` 或 `btop-zh`。无需 Homebrew、编译工具或 sudo；要求 Apple Silicon Mac、macOS 15 或更高版本。

也可以在解压目录执行 `sh install.sh`。若要在当前终端立即使用，执行：

```sh
export PATH="$HOME/.local/bin:$PATH"; hash -r; btop
```

安装后可以推出 DMG，程序运行不依赖磁盘映像。DMG 中也提供独立的卸载入口。

程序安装在 `~/.local/share/btop-zh`，命令放在 `~/.local/bin`。安装器向 `.zshrc`（尊重 ZDOTDIR）和 `.bash_profile` 添加 PATH 配置。有原版命令时会询问是否采用中文版；无人值守时需明确指定 `--take-over`。原版系统文件保留，用户目录中的同名命令会备份。

重复安装可升级。卸载可双击 `Uninstall.command`，或执行：

```sh
sh "$HOME/.local/share/btop-zh/uninstall.sh"
```

卸载保留用户配置，并恢复已备份的同名命令。完整说明见安装包中的 `安装说明.txt`。

## 直接运行

```sh
./build/macos-arm64/btop-zh
```

发布目录中也提供 `dist/btop-zh-macos-arm64/bin/btop-zh`。此程序在终端中运行，不是双击打开的图形应用。

默认中文。按 `m` 打开菜单，`h` 打开帮助，`o` 打开设置，`q` 退出。在设置的“通用 → 语言”中选择 `zh` 或 `en`，退出并重新启动后生效。

进程操作中，`s发送信号` 打开系统信号选择窗口，可选择暂停、继续或退出等信号，确认后才会发送。`t终止` 发送 SIGTERM，请求进程退出；`k结束` 发送 SIGKILL，强制结束进程。`N优先级` 调整 nice 值：-20 至 19，数值越小，调度优先级越高。

配置文件默认位于 `~/.config/btop-zh/btop.conf`；设置了 `XDG_CONFIG_HOME` 时改用其下的 `btop-zh/btop.conf`。与原版 btop 隔离，配置键及枚举值继续使用英文。也可在配置文件写入：

```ini
lang = "zh"
```

## 构建与验证

需要 Xcode Command Line Tools、CMake 3.25+、Python 3 及支持项目 C++23 特性的编译器和标准库。本机 Apple Clang 17 已通过；其他机器以配置检测为准。

```sh
sh scripts/build-macos-arm64.sh
python3 tests/mac_ui_smoke.py build/macos-arm64/btop-zh
```

构建脚本开启 Apple Silicon GPU 支持、关闭 LTO，运行无需下载 GoogleTest 的本地化回归检查，并生成 ZIP、TAR.GZ、DMG 安装包和校验文件。系统缺少 lowdown 时只跳过 man 手册生成。

## 本次修改

- 参考中文分支的翻译表，翻译主要面板标签、菜单、帮助、设置及常用弹窗。
- 修复语言状态、英文回退、重载及未命中词条的返回值生命周期问题。
- 中文主菜单采用文本按钮；设置分类、进程表头和部分按钮按终端列宽排版。
- 修复宽字符裁剪、填充和有界 string_view 测宽；样式 CSI 转义不计入列宽。
- 原版和中文版配置、日志独立，CMake 输出名称为 btop-zh。

## 验证范围与限制

在 Apple M1、macOS 15.8.1 上完成原生 arm64 编译，开启 GPU 支持的链接成功。回归检查覆盖中英文状态、回退、UTF-8 裁剪、组合字符、ANSI 样式及窄列填充。伪终端冒烟检查覆盖 120×40/80×24 中文，以及 120×40 英文的主菜单、帮助、设置和退出，并检查主菜单鼠标点击、语言设置保存及各设置分类的中文说明。另在普通用户权限下验证了启动与进程采集。

此版本为可试用的初版汉化，部分技术标识、配置值、CLI 和日志保持英文；全部 89 个配置项的说明已补齐中文，按配置键匹配并自动换行；窗口高度不足时仅显示可容纳的行。尚未完成多个终端的人工视觉验收、全部鼠标交互、所有 M 系列型号及旧版 macOS 验证。GPU 编译通过不代表所有 GPU 指标均已验收。

当前产物按本机默认部署目标构建，不承诺旧系统兼容性；DMG 内的安装入口使用本地临时签名（ad-hoc），未配置 Developer ID 分发签名与 Apple 公证。

## 来源与许可

- 上游：https://github.com/aristocratos/btop
- 中文参考：https://github.com/dijiaozhibei-top/btop-cn

沿用 Apache-2.0；保留 LICENSE 和源文件版权声明。汉化参考快照、迁移依据见 [初始移植调研](ARM_MAC_ZH_PLAN.md)。本次二次修改由 Codex 辅助完成。

## 功耗显示

CPU 总负载行在温度后显示 CPU 功耗（W），并缩短负载条为数值留出空间；可用 `show_cpu_watts` 开关控制。Apple Silicon 版本通过 IOReport 的 `CPU Energy` 采样计算平均功率，无需 sudo。即使关闭 GPU 图表，CPU 功耗仍继续更新。

CPU 型号后的 `~8.61W` 表示整机功耗估算，读取 macOS 电源遥测 `SystemLoad`，不等于 CPU 与 GPU 功耗之和，也不是插座端功率。该字段属于未公开接口，机型和系统版本可能影响可用性；不可用时显示 `~--W`。CPU 功耗缺失时显示 `--W`。功率单位 W 与累计耗电量 Wh 不同。
