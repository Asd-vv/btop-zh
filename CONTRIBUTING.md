# 贡献说明

欢迎报告中文翻译、终端排版、Apple Silicon 兼容性和安装器问题。本项目是第三方汉化衍生版本；上游开发规范保存在 [docs/upstream/CONTRIBUTING.md](docs/upstream/CONTRIBUTING.md)。

## 报告问题

请在本仓库提交 Issue，并说明 macOS 版本、芯片型号、终端、字体、窗口大小、程序版本、复现步骤及预期结果。涉及配置时可附上相关配置项，提交前移除私人路径、进程参数等敏感内容。

## 提交修改

- 每次修改聚焦一个问题，说明行为变化与验证结果。
- 翻译应简洁、准确，区分系统术语与普通描述；保留配置键、单位及系统标识。
- 修改显示文字时同步检查显示列宽、窄窗口和鼠标点击区域。
- 新增配置项时补齐 `src/btop_options_zh.hpp` 的说明，并运行覆盖检查。
- 保留来源与版权声明，不将上游或参考项目的代码声明为原创。
- AI 生成的代码请明确披露；遵循上游约定，在相关 PR 中标注 `[AI generated]`。

C++ 代码遵循上游风格：Tab 缩进、宽度 4，使用 `and`、`or`、`not`。在条件允许时优先用 `fmt` 格式化输出，避免不必要的分配或渲染路径中的磁盘写入。

## 验证

在仓库根目录执行与修改相关的检查：

```sh
ctest --test-dir build/macos-arm64 --output-on-failure
python3 tests/check_option_translations.py
python3 tests/mac_ui_smoke.py build/macos-arm64/btop-zh
python3 tests/mac_installer_smoke.py dist/btop-zh-macos-arm64
python3 tests/mac_dmg_smoke.py dist/btop-zh-macos-arm64.dmg
```

安装器测试使用临时用户目录。DMG 检查会只读挂载并在结束后推出映像。基础构建、分阶段打包和发布检查见 [docs/RELEASING.md](docs/RELEASING.md)。
