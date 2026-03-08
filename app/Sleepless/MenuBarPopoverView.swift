//
//  MenuBarPopoverView.swift
//  Sleepless
//
//  点击菜单栏图标后弹出的带 Tab 的窗口内容
//

import SwiftUI

struct MenuBarPopoverView: View {
    @ObservedObject var appDelegate: AppDelegate
    @ObservedObject var prefs: PreferencesStore
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // 顶部 Tab 标签栏（分段控件，明确是 Tab UI 不是菜单）
            Picker("", selection: $selectedTab) {
                Text("状态").tag(0)
                Text("通用").tag(1)
                Text("外观").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            // Tab 内容区
            Group {
                switch selectedTab {
                case 0:
                    StatusTab(appDelegate: appDelegate, prefs: prefs)
                case 1:
                    GeneralTab(prefs: prefs)
                case 2:
                    AppearanceTab(prefs: prefs)
                default:
                    StatusTab(appDelegate: appDelegate, prefs: prefs)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 260)

            Divider()

            HStack {
                if #available(macOS 14.0, *) {
                    SettingsLink {
                        Label("偏好设置…", systemImage: "gearshape")
                    }
                } else {
                    Button("偏好设置…") {
                        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    }
                }
                Spacer()
                Button("退出 Sleepless") {
                    appDelegate.quit()
                }
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
        .frame(width: 320, height: 380)
    }
}

// MARK: - 状态：主开关 + 本次临时时长

private struct StatusTab: View {
    @ObservedObject var appDelegate: AppDelegate
    @ObservedObject var prefs: PreferencesStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(appDelegate.statusTitle)
                .font(.headline)
                .foregroundStyle(.secondary)

            Button {
                appDelegate.toggleSleepPrevention()
            } label: {
                Label(
                    appDelegate.isPreventingSleep ? "关闭防休眠" : "开启防休眠",
                    systemImage: appDelegate.isPreventingSleep ? "moon.zzz" : "moon.zzz.fill"
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(appDelegate.isPreventingSleep ? .orange : .accentColor)
            .controlSize(.large)

            Divider()

            Text("本次临时时长")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 8) {
                ForEach(DefaultDuration.allCases, id: \.id) { duration in
                    Button {
                        appDelegate.selectDuration(duration)
                    } label: {
                        Text(duration.label)
                            .font(.caption)
                            .lineLimit(1)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                            .background(appDelegate.currentScheduledDuration == duration ? Color.accentColor.opacity(0.2) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(20)
    }
}

// MARK: - 通用：开机启动、启动时激活、默认时长

private struct GeneralTab: View {
    @ObservedObject var prefs: PreferencesStore

    var body: some View {
        Form {
            Toggle("开机时启动 Sleepless", isOn: $prefs.launchAtLogin)
            Toggle("启动时自动防休眠", isOn: $prefs.activateOnLaunch)

            Section {
                Picker("默认防休眠时长", selection: $prefs.defaultDurationMinutes) {
                    ForEach(DefaultDuration.allCases, id: \.id) { d in
                        Text(d.label).tag(d.rawValue)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("默认时长")
            } footer: {
                Text("点击「开启防休眠」时使用的默认时长。")
            }
        }
        .formStyle(.grouped)
        .padding(.vertical, 8)
    }
}

// MARK: - 外观：菜单栏图标

private struct AppearanceTab: View {
    @ObservedObject var prefs: PreferencesStore

    var body: some View {
        Form {
            Section {
                Picker("菜单栏图标", selection: $prefs.iconStyleRaw) {
                    ForEach(MenuBarIconStyle.allCases, id: \.rawValue) { style in
                        Label(style.label, systemImage: style.symbolOff)
                            .tag(style.rawValue)
                    }
                }
                .pickerStyle(.inline)
            } header: {
                Text("图标风格")
            }
        }
        .formStyle(.grouped)
        .padding(.vertical, 8)
    }
}
