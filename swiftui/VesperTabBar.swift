import SwiftUI

// MARK: - 底栏主题

/// 首页底栏的配色。取自首页 / 日语页：白卡片、近黑细线，不用彩色。
/// `Color(light:dark:)` 定义在 MujiDetailView.swift。
enum TabTheme {
    static let surface  = Color(light: 0xFFFFFF, dark: 0x1C1C1E)  // 底栏底色
    static let pill     = Color(light: 0xF2F2F4, dark: 0x2C2C2E)  // 选中胶囊
    static let ink      = Color(light: 0x1C1C1E, dark: 0xF2F2F4)  // 选中图标与文字
    static let idle     = Color(light: 0x9C9CA1, dark: 0x7C7C82)  // 未选中

    static let iconSize: CGFloat = 20
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

    /// 苹果的 SF Symbols。想换图标，改这里的名字即可，候选见底部「图标候选」预览。
    var symbol: String {
        switch self {
        case .home:     "house"
        case .calendar: "calendar"
        case .life:     "cup.and.saucer"
        case .settings: "gearshape"
        }
    }
}

// MARK: - 图标

/// 未选中：灰色细线。选中：墨色，有实心版本的图标会自动变实心。
struct TabIcon: View {
    let symbol: String
    let isSelected: Bool

    var body: some View {
        Image(systemName: symbol)
            .symbolVariant(isSelected ? .fill : .none)
            .font(.system(size: TabTheme.iconSize, weight: isSelected ? .medium : .regular))
            .foregroundStyle(isSelected ? TabTheme.ink : TabTheme.idle)
            .frame(width: 28, height: 26)
            .contentTransition(.symbolEffect(.replace))
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
                TabIcon(symbol: tab.symbol, isSelected: isSelected)
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
                Color(light: 0xF7F7F8, dark: 0x111113).ignoresSafeArea()
                VesperTabBar(selection: $tab)
                    .padding(.bottom, 8)
            }
        }
    }
    return Demo()
}

/// 每个 tab 几个候选图标，上排未选中、下排选中。看中哪个，把名字填进 `VesperTab.symbol`。
#Preview("图标候选") {
    let candidates: [(String, [String])] = [
        ("首页", ["house", "square.grid.2x2", "circle.grid.2x2", "rectangle.stack"]),
        ("日历", ["calendar", "calendar.day.timeline.left", "clock", "list.bullet.rectangle"]),
        ("生活", ["cup.and.saucer", "mug", "leaf", "sun.max", "heart", "sparkles"]),
        ("设置", ["gearshape", "slider.horizontal.3", "person.crop.circle", "ellipsis.circle"]),
    ]
    return ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(candidates, id: \.0) { title, symbols in
                VStack(alignment: .leading, spacing: 10) {
                    Text(title).font(.headline)
                    HStack(alignment: .top, spacing: 18) {
                        ForEach(symbols, id: \.self) { name in
                            VStack(spacing: 8) {
                                TabIcon(symbol: name, isSelected: false)
                                TabIcon(symbol: name, isSelected: true)
                                Text(name)
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 56)
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .background(Color(light: 0xF7F7F8, dark: 0x111113))
}
