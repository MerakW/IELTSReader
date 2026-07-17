# IELTSReader 1.5.0

IELTSReader 是一个为雅思机考阅读练习设计的原生 macOS 应用。它可以把 PDF 练习材料整理成更接近真实机考的阅读环境：左侧显示文章，中间显示题目，右侧记录答案，适合用已有 PDF 材料做日常训练。

GitHub: https://github.com/MerakW/IELTSReader

下载：<https://github.com/MerakW/IELTSReader/releases/latest>

## 系统要求

- macOS 13.0 或更新版本
- 推荐下载 Universal 版本
- 支持 Apple Silicon / M 系列芯片 Mac
- 支持 Intel Mac

## 功能

- 📄 导入本地 PDF 阅读材料
- 🧭 文章区和题目区分栏显示
- 🔢 直接输入 Passage / Questions 页码范围
- ✍️ 支持文字答案、选择题、True / False / Not Given
- 🔁 自定义题号，后续题号自动递增
- 🖍️ 基于 PDF 文字选择进行高亮、下划线、删除线标注
- 🧽 支持清理标注
- ⏱️ 内置计时器
- 🔒 Strict Mode：全屏、保持焦点、退出前确认
- 💾 保存 / 载入练习 session
- 📤 答案可复制为文本，也可导出为图片

## 安装

请前往 [Releases](https://github.com/MerakW/IELTSReader/releases/latest) 下载最新版本。

Release 会提供两个版本：

```text
IELTSReader-1.5.0-Universal.app.zip
IELTSReader-1.5.0-Apple-Silicon.app.zip
```

大多数用户推荐下载 `Universal` 版本；如果你确定只在 Apple Silicon / M 系列 Mac 上使用，也可以下载 `Apple-Silicon` 版本。

下载后：

1. 双击 `.zip` 文件解压。
2. 将解压得到的 `IELTSReader.app` 拖入 `Applications` 文件夹。
3. 从 `Applications` 中打开 IELTSReader。

## 如果 macOS 提示 App 已损坏

由于 IELTSReader 是开源应用，并非通过 Mac App Store 或 Apple Developer ID 公证分发，部分 macOS 版本可能会因为 quarantine 标记提示：

> “IELTSReader” is damaged and can’t be opened.

如果你确认文件来自本项目的 GitHub Release，可以在安装后打开 Terminal，运行：

```sh
sudo xattr -rd com.apple.quarantine /Applications/IELTSReader.app
```

然后重新打开 IELTSReader。

## 基本流程

1. 点击 `Import` 导入 PDF。
2. 在 Passage / Questions 顶部输入页码范围。
3. 在右侧答案区作答。
4. 需要标注时，先选中 PDF 文字，再点高亮、下划线或删除线。
5. 练习结束后，可以保存 session，或导出答案为文字 / 图片。

## For EN Users

IELTSReader is a native macOS app for IELTS computer-based reading practice. It turns PDF practice materials into a focused split-view workspace with passage pages, question pages, answer tracking, markup tools, timer, strict mode, and session saving.

To install, download:

```text
IELTSReader-1.5.0-Universal.app.zip
IELTSReader-1.5.0-Apple-Silicon.app.zip
```

Most users should download the `Universal` build. Use the `Apple-Silicon` build only if you are sure your Mac uses Apple Silicon.

Unzip the archive, drag `IELTSReader.app` into `Applications`, then open it from Applications.

If macOS says the app is damaged, remove the quarantine flag with:

```sh
sudo xattr -rd com.apple.quarantine /Applications/IELTSReader.app
```

## Credit

Made by Merak. Released under the MIT License.
