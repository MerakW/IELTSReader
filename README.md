# IELTSReader

一个原生 macOS 雅思阅读练习工具，用来把 PDF 练习材料变成更接近机考的双栏练习环境。

GitHub: https://github.com/MerakW/IELTSReader

下载：<https://github.com/MerakW/IELTSReader/releases/latest>

## 系统要求

- macOS 13.0 或更新版本
- 当前 Release 预构建版本面向 Apple Silicon，也就是 M 系列芯片 Mac
- Intel Mac 暂未提供预构建安装包；源码本身未刻意限制 Intel，但需要在 Intel Mac 上自行构建或之后提供 Universal / Intel 版本

## 功能

- 📄 导入本地 PDF
- 🧭 文章区和题目区双栏显示
- 🔢 分别输入 Passage / Questions 的页码范围
- ✍️ 答案区支持填空、选择题、True / False / Not Given
- 🔁 自定义题号后，后续题号自动递增
- 🖍️ 选中文字后高亮、下划线、删除线
- 🧽 清理选区或当前页标注
- ⏱️ 计时器
- 🔒 严格模式：全屏、保持焦点、退出前二次确认
- 💾 保存 / 载入练习 session
- 📤 导出答案为文字或图片

## 使用

请前往 [Releases](https://github.com/MerakW/IELTSReader/releases/latest) 下载最新版本的 Apple Silicon 安装包。

下载后打开 DMG，将 `IELTSReader.app` 拖入 `Applications` 文件夹即可使用。

如果 macOS 提示 App 已损坏，可以先确认文件来自本项目 Release，然后在终端运行：

```sh
sudo xattr -rd com.apple.quarantine /Applications/IELTSReader.app
```

DMG 中也包含 `Damaged App Help.txt` 和 `Fix Damaged App.command`，可以按其中说明处理。

## 基本流程

1. 点击 `Import` 导入 PDF。
2. 在 Passage / Questions 顶部输入页码范围。
3. 在右侧答案区作答。
4. 需要标注时，先选中 PDF 文字，再点高亮、下划线或删除线。
5. 练习结束后，可以保存 session，或导出答案为 `.txt` / `.png`。

## Credit

Made by Merak. Released under the MIT License.
