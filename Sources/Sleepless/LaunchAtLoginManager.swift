//
//  LaunchAtLoginManager.swift
//  Sleepless
//
//  RFC 001：开机时启动（SMAppService，macOS 13+）
//

import Foundation
import ServiceManagement

@available(macOS 13.0, *)
enum LaunchAtLoginManager {
    /// 当前是否已注册为登录项（仅表示上次设置状态，实际以系统为准）
    static var isEnabled: Bool {
        get { PreferencesStore.shared.launchAtLogin }
        set {
            // 仅同步到系统；偏好由 PreferencesStore 的 Toggle 写入，此处避免再次写 prefs 造成循环
            if newValue {
                try? SMAppService.mainApp.register()
            } else {
                try? SMAppService.mainApp.unregister()
            }
        }
    }

    /// 从偏好同步到系统（启动时调用一次）
    static func syncWithPreferences() {
        let want = PreferencesStore.shared.launchAtLogin
        if want {
            try? SMAppService.mainApp.register()
        } else {
            try? SMAppService.mainApp.unregister()
        }
    }
}
