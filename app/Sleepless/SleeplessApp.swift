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
    /// 是否已完成启动（用于避免首次渲染时 didSet 触发登录项对话框）
    static var hasFinishedLaunching = false

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

        isPreventingSleep = sleepGuard.isPreventingSleep

        if prefs.activateOnLaunch {
            startPreventingSleep(with: prefs.defaultDuration)
        }

        // 延迟一帧再标记启动完成，避免 UI 首次绑定触发 launchAtLogin didSet 弹出系统对话框
        DispatchQueue.main.async {
            AppDelegate.hasFinishedLaunching = true
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
