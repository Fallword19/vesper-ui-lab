import SwiftUI
import UIKit

// MARK: - 底栏主题

/// 首页底栏的配色。取自首页 / 日语页：白卡片、近黑细线，不用彩色。
/// 这个文件只依赖同目录的 StarIcon.swift。
enum TabTheme {
    static let surface    = adaptive(0xFFFFFF, 0x1C1C1E)  // 底栏底色
    static let pill       = adaptive(0xF2F2F4, 0x2C2C2E)  // 选中胶囊
    static let ink        = adaptive(0x1C1C1E, 0xF2F2F4)  // 选中图标与文字
    static let idle       = adaptive(0x9C9CA1, 0x7C7C82)  // 未选中
    static let accent     = adaptive(0xC9963F, 0xE2B77C)  // 金色，只在「双色」「星光」画法里用到
    static let background = adaptive(0xF7F7F8, 0x111113)  // 仅预览用的页面底色

    /// 图标画法：.line 精修线稿 / .duo 双色 / .glow 星光。换画法只改这一行。
    static let iconStyle: StarIconStyle = .line
    static let iconSize: CGFloat = 26

    /// 浅色 / 深色模式各一个颜色。
    private static func adaptive(_ light: UInt32, _ dark: UInt32) -> Color {
        func ui(_ hex: UInt32) -> UIColor {
            UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255,
                    green: CGFloat((hex >> 8) & 0xFF) / 255,
                    blue: CGFloat(hex & 0xFF) / 255,
                    alpha: 1)
        }
        return Color(UIColor { $0.userInterfaceStyle == .dark ? ui(dark) : ui(light) })
    }
}

// MARK: - 数据

enum VesperTab: CaseIterable, Identifiable {
    case home, calendar, life, settings

    var id: Self { self }

    var title: String {
        switch self {
        case .home:     "首页"
        case .calendar: "日历"
        case .life:     "生活"
        case .settings: "设置"
        }
    }

    var icon: StarIconKind {
        switch self {
        case .home:     .home
        case .calendar: .calendar
        case .life:     .life
        case .settings: .settings
        }
    }
}

// MARK: - 底栏

struct VesperTabBar: View {
    @Binding var selection: VesperTab
    @Namespace private var pillSpace

    var body: some View {
        HStack(spacing: 4) {
            ForEach(VesperTab.allCases) { tab in
                item(tab)
            }
        }
        .padding(6)
        .background(
            Capsule(style: .continuous)
                .fill(TabTheme.surface)
                .shadow(color: .black.opacity(0.06), radius: 18, y: 6)
        )
        .padding(.horizontal, 20)
    }

    private func item(_ tab: VesperTab) -> some View {
        let isSelected = selection == tab
        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                selection = tab
            }
        } label: {
            VStack(spacing: 4) {
                StarIcon(kind: tab.icon,
                         isSelected: isSelected,
                         style: TabTheme.iconStyle,
                         color: isSelected ? TabTheme.ink : TabTheme.idle,
                         accent: TabTheme.accent,
                         shade: TabTheme.idle)
                    .frame(width: TabTheme.iconSize, height: TabTheme.iconSize)
                Text(tab.title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? TabTheme.ink : TabTheme.idle)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(TabTheme.pill)
                        .matchedGeometryEffect(id: "pill", in: pillSpace)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - 预览

#Preview("底栏") {
    struct Demo: View {
        @State private var tab: VesperTab = .home
        var body: some View {
            ZStack(alignment: .bottom) {
                TabTheme.background.ignoresSafeArea()
                VesperTabBar(selection: $tab)
                    .padding(.bottom, 8)
            }
        }
    }
    return Demo()
}

/// 三种画法并排对比：每组上排未选中，下排选中。
#Preview("三种画法") {
    let styles: [(String, StarIconStyle)] = [("精修线稿", .line), ("双色", .duo), ("星光", .glow)]
    return VStack(alignment: .leading, spacing: 28) {
        ForEach(styles, id: \.0) { name, style in
            VStack(alignment: .leading, spacing: 12) {
                Text(name).font(.headline)
                ForEach([false, true], id: \.self) { selected in
                    HStack(spacing: 28) {
                        ForEach(StarIconKind.allCases, id: \.self) { kind in
                            StarIcon(kind: kind, isSelected: selected, style: style,
                                     color: selected ? TabTheme.ink : TabTheme.idle,
                                     accent: TabTheme.accent,
                                     shade: TabTheme.idle)
                                .frame(width: 40, height: 40)
                        }
                    }
                }
            }
        }
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(TabTheme.background)
}
