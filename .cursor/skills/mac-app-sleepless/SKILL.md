---
name: mac-app-sleepless
description: Create and maintain a Caffeine-style macOS menu-bar app that prevents sleep using IOKit, with Xcode under app/, a pattern-free app icon, and Husky hooks that build the app on commit/push. Use when building or modifying the Sleepless Mac app or similar “keep awake” utilities.
---

# Mac 防休眠应用（Sleepless）技能

## 项目结构

- **app/**：Xcode 工程目录
  - **app/Sleepless.xcodeproj/**：Xcode 项目（project.pbxproj）
  - **app/Sleepless/**：源码与资源
    - `SleeplessApp.swift`：`@main` + `NSApplicationDelegate`，菜单栏图标与生命周期
    - `SleepGuard.swift`：封装 IOKit 防休眠逻辑
    - `Info.plist`：`LSUIElement = true`（仅菜单栏、不显示在 Dock）
    - **Assets.xcassets/AppIcon.appiconset/**：应用图标
- **scripts/generate-icon.mjs**：用 Node + sharp 生成 1024×1024 无重复图案图标
- **package.json**：根目录 npm 项目，`build:app` 调用 xcodebuild，`prepare` 安装 Husky
- **.husky/pre-commit**、**.husky/pre-push**：执行 `npm run build:app`，保证提交/推送前应用可构建

## 防休眠实现（IOKit）

- 使用 `IOKit.pwr_mgt` 的 `IOPMAssertionCreateWithName`：
  - `kIOPMAssertionTypeNoIdleSleep`：禁止系统空闲休眠
  - `kIOPMAssertionTypeNoDisplaySleep`：禁止显示器休眠
- 创建 assertion 后保存 `IOPMAssertionID`，退出或关闭功能时调用 `IOPMAssertionRelease`。
- 参考：`app/Sleepless/SleepGuard.swift`。

## 图标（无图案问题）

- 避免重复、平铺、细密纹理，否则在部分尺寸下会出现摩尔纹或接缝。
- 做法：单色背景 + 简单几何形状（如月牙用两圆叠加），纯色、无渐变/纹理。
- 提供 1024×1024 PNG 即可，Xcode 会生成各尺寸；若需精确尺寸可再生成多档。
- 生成脚本：`scripts/generate-icon.mjs`（依赖 npm 的 `sharp`），运行 `npm run generate-icon`。

## Husky 与构建

- 根目录 `npm install` 会执行 `prepare`，安装 Husky。
- 提交前（pre-commit）、推送前（pre-push）均运行 `npm run build:app`，即：
  `xcodebuild -project app/Sleepless.xcodeproj -scheme Sleepless -configuration Debug -quiet build`
- 若构建失败，提交/推送会被中止；修复 Xcode 报错后重试。

## 常用命令

| 操作           | 命令 |
|----------------|------|
| 构建 Debug     | `npm run build:app` |
| 构建 Release   | `npm run build:app:release` |
| 生成图标       | `npm run generate-icon` |
| 在 Xcode 中打开 | `open app/Sleepless.xcodeproj` |

## 修改与扩展

- 新增 Swift 文件：在 Xcode 中添加到 Sleepless target，或在 project.pbxproj 中增加 `PBXBuildFile` / `PBXFileReference` 并加入 Sources 阶段。
- 调整防休眠行为：只改 `SleepGuard.swift`（例如只保留 NoIdleSleep 或只保留 NoDisplaySleep）。
- 更换图标：修改 `scripts/generate-icon.mjs` 输出路径与绘图逻辑，保持单图、无重复图案，再运行 `npm run generate-icon` 并替换 `AppIcon.appiconset` 中的 PNG。
