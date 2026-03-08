//
//  SettingsView.swift
//  Sleepless
//
//  偏好设置窗口（与菜单内设置同步；此处为完整表单）
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var prefs = PreferencesStore.shared

    var body: some View {
        Form {
            Section {
                Toggle("开机时启动 Sleepless", isOn: $prefs.launchAtLogin)
                Toggle("启动时自动开启防休眠", isOn: $prefs.activateOnLaunch)
            } header: {
                Text("通用")
            }

            Section {
                ForEach(DefaultDuration.allCases, id: \.id) { duration in
                    DurationRow(
                        duration: duration,
                        isSelected: prefs.defaultDurationMinutes == duration.rawValue
                    ) {
                        prefs.defaultDuration = duration
                    }
                }
            } header: {
                Text("默认防休眠时长")
            } footer: {
                Text("通过菜单栏点击开启防休眠时，将在此时间后自动关闭；选「不自动关闭」则需手动关闭。")
            }

            Section {
                ForEach(MenuBarIconStyle.allCases, id: \.id) { style in
                    Button {
                        prefs.iconStyle = style
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: prefs.iconStyle == style ? "circle.inset.filled" : "circle")
                                .foregroundStyle(prefs.iconStyle == style ? Color.accentColor : .secondary)
                            Image(systemName: style.symbolOff)
                                .frame(width: 22, alignment: .center)
                            Text(style.label)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("菜单栏图标")
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 420)
    }
}

// MARK: - 时长单选行

private struct DurationRow: View {
    let duration: DefaultDuration
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "circle.inset.filled" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                Text(duration.label)
                    .foregroundStyle(.primary)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView()
}
