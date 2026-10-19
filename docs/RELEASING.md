# 构建与发布检查

以下命令在仓库根目录执行。脚本只创建本地产物，不会自动上传 GitHub 或创建 Release。

## 完整构建

```sh
sh scripts/build-macos-arm64.sh
```

要求 Apple Silicon Mac、支持所需 C++23 功能的工具链及 CMake 3.25+。脚本构建开启 GPU 支持的 ARM64 版本，运行本地化检查，并调用两个打包脚本。缺少 lowdown 时仅跳过手册生成。

## 仅重新打包

已有 `build/macos-arm64/btop-zh` 时可执行：

```sh
sh scripts/package-macos-arm64.sh
sh scripts/package-macos-dmg.sh
```

前一条生成程序、主题、安装脚本、文档、第三方许可及 `PAYLOAD.sha256`，再封装为 ZIP 和 TAR.GZ。后一条使用该目录生成安装/卸载应用及 DMG。

必须先完成内层目录打包，再生成 DMG，以免混入旧版说明或安装器。签名或修改文件后，需要重新生成受影响的校验值。

## 输出文件

```text
dist/
├── btop-zh-macos-arm64/                 解包目录
├── btop-zh-macos-arm64.zip              一键安装 ZIP
├── btop-zh-macos-arm64.tar.gz           一键安装 TAR.GZ
├── btop-zh-macos-arm64.tar.gz.sha256     TAR.GZ 单独校验文件
├── btop-zh-macos-arm64.dmg              DMG 安装包
└── SHA256SUMS                           三种安装包的 SHA-256
```

`build/`、`dist/`、`.DS_Store` 和 Python 缓存不提交到源码仓库。二进制安装包应作为 GitHub Release 附件分发。

## 检查命令

```sh
ctest --test-dir build/macos-arm64 --output-on-failure
python3 tests/check_option_translations.py
python3 tests/mac_ui_smoke.py build/macos-arm64/btop-zh
python3 tests/mac_installer_smoke.py dist/btop-zh-macos-arm64
python3 tests/mac_dmg_smoke.py dist/btop-zh-macos-arm64.dmg
(cd dist && shasum -a 256 -c SHA256SUMS)
```

- 选项覆盖检查包含不同平台的条件配置项。
- 界面检查覆盖 120×40/80×24 中文、120×40 英文及主要菜单。
- 安装器检查使用临时主目录，覆盖安装、重装、升级、冲突处理、卸载和包内校验。
- DMG 检查会只读挂载映像，检查应用入口、临时签名、文件完整性并测试安装器，结束后推出映像。

可选的 `--process-dialogs` 界面检查需要能读取真实进程列表的普通用户环境；只打开并取消信号与优先级窗口，不确认任何进程操作。

## 整理源码包

在 Git 工作区中执行：

```sh
sh scripts/package-source.sh
```

生成 `dist/btop-zh-source.zip` 和对应的 `.sha256`。包含当前已跟踪和未被忽略的项目文件，不含 `.git/`、构建结果或安装包。发布前仍应检查文件列表；该源码快照不包含 Git 历史。

## 发布前确认

1. 更新 `CHANGELOG.md`，记录本次修改及实际测试环境。
2. 确认架构、部署目标和说明一致，保留根目录 LICENSE 与第三方许可。
3. 从实际下载或只读挂载的安装包验证安装，并检查新终端中的 `btop` 命令。
4. 上传 DMG、ZIP、TAR.GZ 及 `SHA256SUMS` 至本仓库 Release，避免引用上游发布页作为本项目的下载入口。
5. 当前包未做 Developer ID 正式签名和 Apple 公证，应如实标注。本地临时签名检查不等于 Gatekeeper 分发验证。

许可证声明和文档打包规则在 `scripts/package-macos-arm64.sh` 中维护。DMG 入口资源在 `packaging/macos/dmg/` 中维护。
