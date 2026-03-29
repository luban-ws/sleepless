---
name: mac-app-sleepless
description: Create and maintain a Caffeine-style macOS menu-bar app that prevents sleep using IOKit, SwiftPM at repo root, script-assembled .app, pattern-free app icon, and Husky hooks that build on commit/push. Use when building or modifying the Sleepless Mac app or similar “keep awake” utilities.
---

# Mac 防休眠应用（Sleepless）技能

## 项目结构

- **Package.swift**：SwiftPM 包定义；可执行目标 `Sleepless`（macOS 13+），链接 `ServiceManagement`、`IOKit`，并嵌入 `Resources/Info.plist` 便于直接运行 Mach-O。
- **Sources/Sleepless/**：应用源码
  - `SleeplessApp.swift`：`@main` + `NSApplicationDelegate`，菜单栏图标与生命周期
  - `SleepGuard.swift`：封装 IOKit 防休眠逻辑
  - `Preferences.swift`、`LaunchAtLoginManager.swift`、`MenuBarPopoverView.swift`
- **Resources/Info.plist**：`LSUIElement = true`（仅菜单栏、不显示在 Dock）；`CFBundleIconFile` = `AppIcon`。
- **Resources/icon_1024.png**：主图标源图（1024×1024）；构建时由脚本生成 `AppIcon.icns` 并打入 `.app`。
- **scripts/build-app.sh**：`swift build` + 组装 `build/Sleepless.app`（`PkgInfo`、复制 `Info.plist`、可选 `codesign -`）。
- **scripts/make-app-icon.sh**：`sips` + `iconutil` 从 `icon_1024.png` 生成 `Resources/AppIcon.icns`。
- **scripts/generate-icon.mjs**：用 Node + sharp 生成无重复图案的主 PNG，输出到 `Resources/icon_1024.png`。
- **Tests/SleeplessTests/**：`swift test` 单元测试。
- **package.json**：`build:app` / `build:app:release` 调用 `scripts/build-app.sh`；`test:swift` 为 `swift test`；`prepare` 安装 Husky。
- **.husky/pre-commit**、**.husky/pre-push**：执行 `npm run build:app`。

## 防休眠实现（IOKit）

- 使用 `IOKit.pwr_mgt` 的 `IOPMAssertionCreateWithName`：
  - `kIOPMAssertionTypeNoIdleSleep`：禁止系统空闲休眠
  - `kIOPMAssertionTypeNoDisplaySleep`：禁止显示器休眠
- 创建 assertion 后保存 `IOPMAssertionID`，退出或关闭功能时调用 `IOPMAssertionRelease`。
- 参考：`Sources/Sleepless/SleepGuard.swift`。

## 图标（无图案问题）

- 避免重复、平铺、细密纹理，否则在部分尺寸下会出现摩尔纹或接缝。
- 做法：单色背景 + 简单几何形状（如月牙用两圆叠加），纯色、无渐变/纹理。
- 提供 1024×1024 PNG 到 `Resources/icon_1024.png`；`make-app-icon.sh` 生成各档并产出 `AppIcon.icns`。
- 生成脚本：`scripts/generate-icon.mjs`（依赖 npm 的 `sharp`），运行 `npm run generate-icon`。

## Husky 与构建

- 根目录 `npm install` 会执行 `prepare`，安装 Husky。
- 提交前（pre-commit）、推送前（pre-push）均运行 `npm run build:app`（`swift build` + 组装 `.app`）。
- 若构建失败，提交/推送会被中止；修复 Swift/脚本报错后重试。

## 常用命令

| 操作           | 命令 |
|----------------|------|
| 构建 Debug .app | `npm run build:app` |
| 构建 Release .app | `npm run build:app:release` |
| 仅编译（不打包） | `swift build` |
| 单元测试       | `swift test` 或 `npm run test:swift` |
| 生成图标       | `npm run generate-icon` |
| 本地运行 Mach-O | `swift run Sleepless` |

## 修改与扩展

- 新增 Swift 文件：放入 `Sources/Sleepless/` 即可被目标编译。
- 调整防休眠行为：改 `SleepGuard.swift`（例如只保留 NoIdleSleep 或只保留 NoDisplaySleep）。
- 更换图标：改 `scripts/generate-icon.mjs` 的绘图逻辑，运行 `npm run generate-icon`，再构建以刷新 `AppIcon.icns`。
- 若需 App Store / 复杂 entitlement / Extension：可另建 Xcode 工程引用本包，或用 `xcodebuild archive` 单独发布流。
