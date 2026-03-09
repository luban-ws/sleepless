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
    private var scheduleCheckTimer: Timer?
    /// 当前防休眠是否由计划开启（计划结束时自动关闭）
    private var scheduleDroveOn = false

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

        startScheduleCheckIfNeeded()

        DispatchQueue.main.async {
            AppDelegate.hasFinishedLaunching = true
        }
    }

    // MARK: - 计划：按每日时段自动开/关

    private func startScheduleCheckIfNeeded() {
        scheduleCheckTimer?.invalidate()
        scheduleCheckTimer = nil
        guard prefs.scheduleEnabled else { return }
        scheduleCheckTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.performScheduleCheck()
        }
        RunLoop.main.add(scheduleCheckTimer!, forMode: .common)
        performScheduleCheck()
    }

    private func performScheduleCheck() {
        guard prefs.scheduleEnabled else { return }
        let now = Calendar.current.component(.hour, from: Date()) * 60 + Calendar.current.component(.minute, from: Date())
        let start = prefs.scheduleStartMinutes
        let end = prefs.scheduleEndMinutes
        let inWindow: Bool
        if start <= end {
            inWindow = now >= start && now < end
        } else {
            inWindow = now >= start || now < end
        }
        if inWindow {
            if !sleepGuard.isPreventingSleep {
                _ = sleepGuard.preventSleep()
                scheduleDroveOn = true
                isPreventingSleep = true
                objectWillChange.send()
            }
        } else {
            if scheduleDroveOn && sleepGuard.isPreventingSleep {
                sleepGuard.allowSleep()
                scheduleDroveOn = false
                isPreventingSleep = false
                cancelAutoOffTimer()
                currentScheduledDuration = .indefinite
                objectWillChange.send()
            }
        }
    }

    /// 用户手动切换时清除“由计划开启”标记
    private func clearScheduleDroveOn() {
        scheduleDroveOn = false
    }

    /// 计划开关或时间变更时由 UI 调用，重新启停计划检查
    func refreshSchedule() {
        startScheduleCheckIfNeeded()
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
        clearScheduleDroveOn()
        if sleepGuard.isPreventingSleep {
            cancelAutoOffTimer()
            sleepGuard.allowSleep()
            isPreventingSleep = false
        } else {
            startPreventingSleep(with: prefs.defaultDuration)
        }
    }

    func selectDuration(_ duration: DefaultDuration) {
        clearScheduleDroveOn()
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
