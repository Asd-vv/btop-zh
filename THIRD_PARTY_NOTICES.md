# 第三方来源与许可声明

## aristocratos/btop

- 项目：https://github.com/aristocratos/btop
- 基线提交：`4792b0700e617cb2ee5ffbced50c1e52528b912a`
- 许可：Apache License 2.0，见仓库根目录的 `LICENSE`。
- 原作者及贡献者的版权声明保留在原始源文件中。
- 本项目使用其资源采集、终端界面、主题和构建实现。

## dijiaozhibei-top/btop-cn

- 项目：https://github.com/dijiaozhibei-top/btop-cn
- 参考内容：`btop_locale.hpp`、`btop_locale.cpp` 中的国际化接口和中文词条，以及相关界面接入方式。
- 许可：Apache License 2.0。参考快照中附带的许可与本仓库根目录的 `LICENSE` 一致。
- 参考时取得 main 分支压缩包，未取得对应提交号；快照 SHA-256 见 `docs/SOURCES.md`。
- 中文措辞、设置说明、宽字符处理、语言状态管理和 macOS 安装流程已在本项目中继续修改。

## 内置组件

- `{fmt}`：版权所有 Victor Zverovich 及贡献者；按其 MIT 许可分发，全文见 `include/fmt/LICENSE.rst`。二进制安装包同时包含 `licenses/fmt-LICENSE.rst`。
- 宽字符宽度数据：`include/widechar_width.hpp`，来源与 Unicode 数据版本见该文件头部说明，原有说明保留。
- 其他上游附带代码、图标、主题和平台支持文件保留原有版权与许可声明。

## 本项目的修改

本项目新增或修改了中文词条与设置说明、终端列宽处理、部分界面布局、语言配置、macOS ARM64 构建、用户级安装器和发布文档。主要修改记录见 `CHANGELOG.md`。

本项目不替代或改变原作者的署名，不代表两个来源项目的官方版本。项目整体沿用 Apache-2.0；第三方组件按其自身许可证保留相应声明。
