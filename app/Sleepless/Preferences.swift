//
//  Preferences.swift
//  Sleepless
//
//  RFC 001：偏好持久化（开机启动、启动时激活、默认时长）
//

import Foundation

// MARK: - UserDefaults 键

enum PreferencesKeys {
    static let launchAtLogin = "launchAtLogin"
    static let activateOnLaunch = "activateOnLaunch"
    static let defaultDurationMinutes = "defaultDurationMinutes"
    static let iconStyle = "iconStyle"
}

// MARK: - 菜单栏图标风格（可切换）

enum MenuBarIconStyle: String, CaseIterable, Identifiable {
    case moon = "moon"
    case cup = "cup"
    case bolt = "bolt"
    case eye = "eye"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .moon: return "月牙"
        case .cup: return "咖啡杯"
        case .bolt: return "闪电"
        case .eye: return "眼睛"
        }
    }

    /// 未激活时的 SF Symbol
    var symbolOff: String {
        switch self {
        case .moon: return "moon.zzz"
        case .cup: return "cup.and.saucer"
        case .bolt: return "bolt"
        case .eye: return "eye"
        }
    }

    /// 激活防休眠时的 SF Symbol
    var symbolOn: String {
        switch self {
        case .moon: return "moon.zzz.fill"
        case .cup: return "cup.and.saucer.fill"
        case .bolt: return "bolt.fill"
        case .eye: return "eye.fill"
        }
    }

    /// 根据是否防休眠返回当前应显示的 SF Symbol 名
    func symbol(active: Bool) -> String {
        active ? symbolOn : symbolOff
    }
}

// MARK: - 默认防休眠时长（分钟；0 表示不自动关闭）

enum DefaultDuration: Int, CaseIterable, Identifiable {
    case fiveMin = 5
    case fifteenMin = 15
    case thirtyMin = 30
    case oneHour = 60
    case twoHours = 120
    case indefinite = 0

    var id: Int { rawValue }

    var minutes: Int { rawValue }

    var isIndefinite: Bool { rawValue == 0 }

    /// 显示用文案
    var label: String {
        switch self {
        case .fiveMin: return "5 分钟"
        case .fifteenMin: return "15 分钟"
        case .thirtyMin: return "30 分钟"
        case .oneHour: return "1 小时"
        case .twoHours: return "2 小时"
        case .indefinite: return "不自动关闭"
        }
    }

    static func from(minutes: Int) -> DefaultDuration {
        DefaultDuration.allCases.first { $0.rawValue == minutes } ?? .indefinite
    }
}

// MARK: - 偏好读取与写入（Observable，供菜单栏直接绑定与图标更新）

final class PreferencesStore: ObservableObject {
    static let shared = PreferencesStore()
    private let defaults: UserDefaults

    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: PreferencesKeys.launchAtLogin)
            if #available(macOS 13.0, *) { LaunchAtLoginManager.isEnabled = launchAtLogin }
        }
    }

    @Published var activateOnLaunch: Bool {
        didSet { defaults.set(activateOnLaunch, forKey: PreferencesKeys.activateOnLaunch) }
    }

    @Published var defaultDurationMinutes: Int {
        didSet {
            let v = defaultDurationMinutes >= 0 ? defaultDurationMinutes : 0
            defaults.set(v, forKey: PreferencesKeys.defaultDurationMinutes)
        }
    }

    @Published var iconStyleRaw: String {
        didSet {
            let v = MenuBarIconStyle(rawValue: iconStyleRaw) != nil ? iconStyleRaw : MenuBarIconStyle.moon.rawValue
            defaults.set(v, forKey: PreferencesKeys.iconStyle)
        }
    }

    var defaultDuration: DefaultDuration {
        get { DefaultDuration.from(minutes: defaultDurationMinutes) }
        set { defaultDurationMinutes = newValue.rawValue }
    }

    var iconStyle: MenuBarIconStyle {
        get { MenuBarIconStyle(rawValue: iconStyleRaw) ?? .moon }
        set { iconStyleRaw = newValue.rawValue }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.launchAtLogin = defaults.bool(forKey: PreferencesKeys.launchAtLogin)
        self.activateOnLaunch = defaults.bool(forKey: PreferencesKeys.activateOnLaunch)
        let d = defaults.integer(forKey: PreferencesKeys.defaultDurationMinutes)
        self.defaultDurationMinutes = d >= 0 ? d : 0
        let raw = defaults.string(forKey: PreferencesKeys.iconStyle)
        self.iconStyleRaw = (raw.flatMap { MenuBarIconStyle(rawValue: $0) != nil ? $0 : nil }) ?? MenuBarIconStyle.moon.rawValue
    }
}
