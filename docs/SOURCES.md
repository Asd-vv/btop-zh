# 来源与基线

## btop 上游

- 仓库：[aristocratos/btop](https://github.com/aristocratos/btop)
- 本次修改基线：[`4792b0700e617cb2ee5ffbced50c1e52528b912a`](https://github.com/aristocratos/btop/commit/4792b0700e617cb2ee5ffbced50c1e52528b912a)
- 程序基础版本：1.4.7。
- 原始许可证：Apache-2.0，根目录 `LICENSE` 保持原文。

监控核心、跨平台采集接口、macOS 采集、主题、内置依赖和构建基础均来自上游。原版文档快照保存在 `docs/upstream/`。

## 中文实现参考

- 仓库：[dijiaozhibei-top/btop-cn](https://github.com/dijiaozhibei-top/btop-cn)
- 参考时间：2026-10-19。
- 来源：当时的 main 分支源码压缩包，未取得对应提交号。
- 压缩包 SHA-256：`35438c71664ee388c0ef846cf4aa9437c2246d0f94d8f1831351e674884e3d40`。
- 原始许可证：Apache-2.0。

主要参考 `btop_locale.hpp`、`btop_locale.cpp`、中文词条和界面翻译调用。没有整体覆盖上游源文件，也没有直接使用面向 Linux 的安装脚本。

## btop-zh 的修改范围

- 按配置键组织的中文设置说明、术语修订与中文帮助。
- 语言初始化、英文回退、返回值生命周期及显示列宽处理。
- 中文菜单、图表标题、进程按钮和相应点击区域。
- Apple Silicon 构建、用户级安装/升级/卸载、ZIP/TAR.GZ/DMG 打包。
- 本地化、界面和安装包检查及相关文档。

本项目的部分实现使用 AI 辅助开发。版权和第三方许可见 [第三方声明](../THIRD_PARTY_NOTICES.md)，修改历史见 [CHANGELOG](../CHANGELOG.md)。
