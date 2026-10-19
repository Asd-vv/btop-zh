# btop-zh

面向 **Apple Silicon Mac** 的 btop 中文汉化版本，在终端中查看 CPU、GPU、内存、磁盘、网络与进程状态。

本项目以 [aristocratos/btop](https://github.com/aristocratos/btop) 为源码基础，参考 [dijiaozhibei-top/btop-cn](https://github.com/dijiaozhibei-top/btop-cn) 的中文翻译实现，补充 macOS ARM64 构建、中文排版及安装包支持。属于第三方衍生项目，由本仓库维护，不代表两个来源项目的官方发布。

## 功能

- 汉化主要面板、菜单、帮助、常用弹窗及全部 89 个配置项的说明。
- 调整中文字符的列宽、截断、对齐和部分鼠标点击区域。
- 使用更清楚的指标名称，如“CPU 总占用率”“各 GPU 占用率”“平均负载”。
- 支持中英文切换，退出并重新启动后生效。
- 原生 ARM64 构建，保留上游 macOS 采集实现。
- 提供 DMG、ZIP 和 TAR.GZ 安装包，安装后可直接输入 `btop`。
- 用户级安装、升级与卸载，与原版配置隔离。

## 系统要求

| 项目 | 要求 |
| --- | --- |
| 处理器 | Apple Silicon，M 系列芯片 |
| 系统 | macOS 15 或更高版本，当前编译包的部署目标为 15.0 |
| 终端 | 支持 UTF-8，字体包含中文及图表字符 |
| 安装预编译包 | 无需 Homebrew、编译器或管理员权限 |

已在 **Apple M1 / macOS 15.8.1** 验证。尚未覆盖所有 M 系列机型、终端和系统版本；GPU 指标是否可用取决于系统及设备支持。保留的其他平台源码不代表本项目已完成相应平台的汉化验证。

## 安装

从本仓库的 **Releases** 页面下载对应安装包。若尚未发布二进制文件，可按照下文从源码构建。

### DMG 安装

1. 打开 `btop-zh-macos-arm64.dmg`。
2. 双击 **安装 btop-zh.app**，按终端提示完成安装。
3. 重新打开终端，输入：

```sh
btop
```

这是终端工具，无需将安装入口拖入“应用程序”文件夹。安装完成后可以推出 DMG。

### ZIP / TAR.GZ 安装

解压完整安装包，双击 `Install.command`，或进入解压目录执行：

```sh
sh install.sh
```

在当前终端立即启用命令：

```sh
export PATH="$HOME/.local/bin:$PATH"
hash -r
btop
```

也可使用 `btop-zh` 命令。若系统已安装原版，安装器会询问是否让中文版成为默认 `btop`；非交互安装时需明确指定：

```sh
sh install.sh --take-over
```

系统位置的原版程序会保留。`~/.local/bin` 下的同名命令会先备份，卸载时按需恢复。

> 当前安装包未使用 Developer ID 正式签名，也未经过 Apple 公证；DMG 内的应用入口仅使用本地临时签名（ad-hoc）。本地测试通过不代表互联网下载后会被 Gatekeeper 自动放行。

### 安装位置与卸载

| 内容 | 默认位置 |
| --- | --- |
| 程序和主题 | `~/.local/share/btop-zh/` |
| 命令入口 | `~/.local/bin/btop`、`~/.local/bin/btop-zh` |
| 配置文件 | `~/.config/btop-zh/btop.conf` |

安装器会向 `.zshrc`（尊重 `ZDOTDIR`）和 `.bash_profile` 添加带标记的 PATH 配置。设置了 `XDG_CONFIG_HOME` 时，配置文件位于该目录下的 `btop-zh/btop.conf`。

卸载可双击 DMG 中的 **卸载 btop-zh.app**，或执行：

```sh
sh "$HOME/.local/share/btop-zh/uninstall.sh"
```

卸载保留用户配置及安装后对 shell 配置文件的其他修改。重复运行安装器可升级。

## 使用

| 快捷键 | 功能 |
| --- | --- |
| `m` / `Esc` | 打开或关闭菜单 |
| `o` / `F2` | 设置 |
| `h` / `F1` | 帮助 |
| `1`～`4` | 显示或隐藏 CPU、内存、网络、进程面板 |
| `d` | 显示或隐藏磁盘信息 |
| `i` | 切换磁盘空间与读写速度视图 |
| `e` | 切换进程树 |
| `s` | 为所选进程选择要发送的系统信号 |
| `N` | 调整所选进程的调度优先级（nice 值） |
| `q` | 退出 |

信号可以用于暂停、继续或请求进程退出，选择后需确认才会发送。`t终止` 发送 SIGTERM 请求退出；`k结束` 发送 SIGKILL 强制结束。启用 Vim 键位时，帮助与结束进程的快捷键需配合 Shift；完整按键说明见程序内帮助。

默认中文。在“选项 → 通用 → 语言”中选择 `zh` 或 `en`，重新启动后生效。也可编辑配置：

```ini
lang = "zh"
```

部分技术标识、配置值、命令行帮助及日志仍使用英文。

## 从源码构建

需要 Xcode Command Line Tools、CMake 3.25+，以及支持所需 C++23 特性的编译器和标准库。已使用 Apple Clang 17 完成构建，具体兼容性以 CMake 检测为准。完整打包与部分检查还需要 Python 3，以及 macOS 自带的磁盘映像和签名工具。

在仓库根目录执行：

```sh
sh scripts/build-macos-arm64.sh
```

该脚本会构建程序、运行本地化回归检查，并生成安装包。产物位于 `build/macos-arm64/` 和 `dist/`；不安装到当前用户环境。

也可直接构建程序：

```sh
cmake -S . -B build/macos-arm64 \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DBUILD_TESTING=OFF \
  -DBTOP_ZH_CHECKS=ON \
  -DBTOP_GPU=ON \
  -DBTOP_LTO=OFF
cmake --build build/macos-arm64 -j 4
ctest --test-dir build/macos-arm64 --output-on-failure
./build/macos-arm64/btop-zh
```

`BUILD_TESTING=OFF` 关闭上游需下载 GoogleTest 的测试；`BTOP_ZH_CHECKS=ON` 启用无需下载依赖的汉化回归检查。

更多构建、验证与打包命令见[安装与构建说明](docs/INSTALL_MACOS.md)和[发布说明](docs/RELEASING.md)。

## 项目结构

```text
src/                 监控核心、平台采集、界面与中文翻译
include/             上游内置依赖
themes/              界面主题
packaging/macos/     安装、卸载及 DMG 入口资源
scripts/             构建和打包脚本
tests/               本地化、界面及安装器检查
docs/                安装、发布、来源与移植记录
docs/upstream/       上游文档快照
build/               本地构建结果，不提交 Git
dist/                本地发布产物，不提交 Git
```

## 来源与致谢

| 项目 | 本项目中的用途 |
| --- | --- |
| [aristocratos/btop](https://github.com/aristocratos/btop) | 监控核心、终端界面、macOS 采集、主题及构建基础 |
| [dijiaozhibei-top/btop-cn](https://github.com/dijiaozhibei-top/btop-cn) | 中文翻译表、国际化接口及界面翻译接入参考 |

感谢两个项目的作者与贡献者。本项目在上游 btop 提交 `4792b07` 的基础上进行修改，并修复了参考汉化实现中的语言状态、回退和中文排版问题。来源版本、依赖许可和修改范围见[来源记录](docs/SOURCES.md)与[第三方声明](THIRD_PARTY_NOTICES.md)。

部分汉化、测试及打包代码使用 AI 辅助开发。欢迎通过 Issue 或 Pull Request 反馈翻译与兼容性问题，参与前请阅读[贡献说明](CONTRIBUTING.md)。

## 开源协议

本项目沿用 **Apache License 2.0**，完整文本见 [LICENSE](LICENSE)。保留原项目的版权与许可声明，并在修改文件和[更新记录](CHANGELOG.md)中标明本项目的变更。

内置第三方组件按各自的许可证分发，例如 `{fmt}` 的许可文本保留在 [include/fmt/LICENSE.rst](include/fmt/LICENSE.rst)。本项目与 Apple Inc. 无隶属或官方合作关系。
