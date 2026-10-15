# keyboardX

**键盘增强 + 剪贴板管理 二合一 iOS 插件**，由 [Kayoko](https://github.com/AlexandraAurora/Kayoko)（剪贴板管理器，作者 Alexandra Aurora Göttlicher）与 [TypeX](https://github.com/lindo-zy/TypeX)（键盘增强插件）合并而成。

## 功能

### 键盘增强（来自 TypeX）
- **双工具栏**：键盘上方工具栏 + 键盘 dock 工具栏，按钮拖动排序，两套外观参数独立
- **35 种内置键盘动作**：编辑 / 删除 / 选择 / 光标 / 工具五组
- **六向手势**：每个按钮可分别配置单击、长按、上滑、下滑、左滑、右滑
- **滑动面板**：可创建任意数量的命名面板（键盘面板 / 手势面板），内置系统控件
- **桌面手势**：状态栏三分区 × 5 种手势共 15 个绑定，Dock 三向手势
- **自定义动作**：文本 / URL / URL Scheme / 打开应用 / 快捷方式 / JavaScript / 系统动作
- **系统动作**：27 项固定动作（媒体、设备、控制中心）+ PixPin 截图
- **JavaScript 引擎**：基于 JavaScriptCore 的脚本动作
- **AI 问答面板**：多引擎、流式输出、人设、Markdown 渲染
- **短信验证码提取**、**剪贴板悬浮粘贴**

### 剪贴板管理（来自 Kayoko）
- 剪贴板历史记录、收藏、搜索（按内容 / 应用 / 标签）
- 自定义标签与标签管理、彩色标签
- 悬浮预览、富文本保留、缩略图缓存
- 多种激活方式：预测栏 / 听写键 / 输入法切换键 / 上滑手势 / 呼出菜单
- 从 Kayoko / CopyLog 历史导入

## 架构

合并后保留两个上游各自验证过的进程模型，共 4 个产物：

| 产物 | 内容 | Filter |
| --- | --- | --- |
| `KeyboardX` | TypeX 全部源码 + Kayoko Helper | `com.apple.UIKit` |
| `KeyboardXCore` | Kayoko Core（剪贴板存储 / SpringBoard 侧） | `com.apple.springboard`, `druid`, `pasted` |
| `KeyboardXPreferences` | 两套偏好面板合并为单一 bundle | — |
| `keyboardx_updater` | Kayoko 剪贴板历史导入器（CLI） | — |

偏好域与数据目录保持与两个上游一致（`com.lindo.typex` / `com.muzi.kayoko.preferences` / `/var/mobile/Library/com.muzi.kayoko`），升级不丢配置与剪贴板历史。

## 构建

需要 [Theos](https://theos.dev) 与 iOS SDK（`TARGET = iphone:clang:16.5:15.0`）。

```sh
export THEOS=/path/to/theos
make package FINALPACKAGE=1                       # 默认 rootless
THEOS_PACKAGE_SCHEME=roothide make package FINALPACKAGE=1
```

也可直接推送到 GitHub，由 `.github/workflows/build-deb.yml` 在 macOS runner 上构建 rootless / roothide 两种包并上传 artifact。

> 低内存环境（< 2GB 可用）请用 `make -j2`；`-j4` 在大文件（`DXFloatingAppRuntime.mm`、经 Logos 展开的 `TypeX.xm`）上会因内存耗尽被 OOM 杀死。

## 许可

合并产物整体以 **AGPL-3.0** 发布（见 `LICENSE`）。上游组件：

- Kayoko —— GPL-3.0（`COPYING.Kayoko-GPL-3.0`）
- TypeX —— AGPL-3.0
- AltList —— MIT
- PullOver X —— GPL-3.0

GPL-3.0 与 AGPL-3.0 允许合并为同一程序，合并后整体适用 AGPL-3.0。
