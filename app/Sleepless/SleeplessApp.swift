//
//  SleeplessApp.swift
//  Sleepless
//
//  Mac 防休眠应用：菜单内直接设置、可换图标、现代菜单 UI
//

import SwiftUI

@main
struct SleeplessApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var prefs = PreferencesStore.shared

    var body: some Scene {
        Settings {
            SettingsView()
        }
        MenuBarExtra {
            MenuBarPopoverView(appDelegate: appDelegate, prefs: prefs)
        } label: {
            Image(systemName: prefs.iconStyle.symbol(active: appDelegate.isPreventingSleep))
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - 应用级代理：防休眠与定时器（可被 SwiftUI 观察）

final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private let sleepGuard = SleepGuard()
    private let prefs = PreferencesStore.shared

    private var autoOffTimer: Timer?
    private(set) var currentScheduledDuration: DefaultDuration = .indefinite

    private(set) var isPreventingSleep: Bool = false {
        didSet { objectWillChange.send() }
    }

    var statusTitle: String {
        isPreventingSleep ? "正在防止休眠" : "允许休眠"
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // 不在启动时同步登录项，避免首次启动弹出系统「是否允许在登录时运行」对话框
        // 用户打开「开机时启动」时由 PreferencesStore.didSet 调用 LaunchAtLoginManager

        isPreventingSleep = sleepGuard.isPreventingSleep

        if prefs.activateOnLaunch {
            startPreventingSleep(with: prefs.defaultDuration)
        }
    }

    private func startPreventingSleep(with duration: DefaultDuration) {
        _ = sleepGuard.preventSleep()
        isPreventingSleep = true
        cancelAutoOffTimer()
        currentScheduledDuration = .indefinite
        objectWillChange.send()

        if !duration.isIndefinite && duration.minutes > 0 {
            currentScheduledDuration = duration
            objectWillChange.send()
            autoOffTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(duration.minutes * 60), repeats: false) { [weak self] _ in
                self?.performAutoOff()
            }
            RunLoop.main.add(autoOffTimer!, forMode: .common)
        }
    }

    private func performAutoOff() {
        autoOffTimer?.invalidate()
        autoOffTimer = nil
        currentScheduledDuration = .indefinite
        sleepGuard.allowSleep()
        isPreventingSleep = false
        objectWillChange.send()
    }

    private func cancelAutoOffTimer() {
        autoOffTimer?.invalidate()
        autoOffTimer = nil
        currentScheduledDuration = .indefinite
        objectWillChange.send()
    }

    func toggleSleepPrevention() {
        if sleepGuard.isPreventingSleep {
            cancelAutoOffTimer()
            sleepGuard.allowSleep()
            isPreventingSleep = false
        } else {
            startPreventingSleep(with: prefs.defaultDuration)
        }
    }

    func selectDuration(_ duration: DefaultDuration) {
        if !sleepGuard.isPreventingSleep {
            _ = sleepGuard.preventSleep()
            isPreventingSleep = true
        }
        cancelAutoOffTimer()
        if !duration.isIndefinite && duration.minutes > 0 {
            currentScheduledDuration = duration
            objectWillChange.send()
            autoOffTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(duration.minutes * 60), repeats: false) { [weak self] _ in
                self?.performAutoOff()
            }
            RunLoop.main.add(autoOffTimer!, forMode: .common)
        } else {
            currentScheduledDuration = .indefinite
        }
        objectWillChange.send()
    }

    func quit() {
        cancelAutoOffTimer()
        sleepGuard.allowSleep()
        isPreventingSleep = false
        NSApp.terminate(nil)
    }
}
