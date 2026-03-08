//
//  SleepGuard.swift
//  Sleepless
//
//  使用 IOKit 的 IOPMAssertion 阻止系统/显示器休眠
//

import Foundation
import IOKit.pwr_mgt

/// 封装 IOPMAssertion 的防休眠逻辑，支持「禁止空闲休眠」与「禁止显示器休眠」
final class SleepGuard {
    private var noIdleSleepID: IOPMAssertionID = 0
    private var noDisplaySleepID: IOPMAssertionID = 0
    private let assertionName = "Sleepless - 用户请求保持唤醒" as CFString

    private(set) var isPreventingSleep: Bool = false

    /// 开启防休眠：禁止空闲休眠 + 禁止显示器休眠
    func preventSleep() -> Bool {
        guard !isPreventingSleep else { return true }
        let idleOk = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoIdleSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            assertionName,
            &noIdleSleepID
        ) == kIOReturnSuccess
        let displayOk = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            assertionName,
            &noDisplaySleepID
        ) == kIOReturnSuccess
        if idleOk && displayOk {
            isPreventingSleep = true
            return true
        }
        if idleOk { IOPMAssertionRelease(noIdleSleepID) }
        if displayOk { IOPMAssertionRelease(noDisplaySleepID) }
        return false
    }

    /// 关闭防休眠
    func allowSleep() {
        guard isPreventingSleep else { return }
        IOPMAssertionRelease(noIdleSleepID)
        IOPMAssertionRelease(noDisplaySleepID)
        noIdleSleepID = 0
        noDisplaySleepID = 0
        isPreventingSleep = false
    }

    /// 切换当前防休眠状态
    func toggle() {
        if isPreventingSleep {
            allowSleep()
        } else {
            _ = preventSleep()
        }
    }
}
