import SwiftUI

// MARK: - 底栏主题

/// 首页底栏的配色。取自首页 / 日语页：白卡片、近黑描边、一点橙。
/// `Color(light:dark:)` 定义在 MujiDetailView.swift。
enum TabTheme {
    static let surface  = Color(light: 0xFFFFFF, dark: 0x1C1C1E)  // 底栏底色
    static let pill     = Color(light: 0xF2F2F4, dark: 0x2C2C2E)  // 选中胶囊
    static let ink      = Color(light: 0x1C1C1E, dark: 0xF2F2F4)  // 选中图标与文字
    static let idle     = Color(light: 0x9C9CA1, dark: 0x7C7C82)  // 未选中
    static let accent   = Color(light: 0xE07A5F, dark: 0xE8876D)  // 「• Claude」那颗橙点

    static let lineWidth: CGFloat = 1.6   // 图标描边，按 24pt 画布计
    static let iconSize: CGFloat = 26
}

// MARK: - 数据

enum VesperTab: CaseIterable, Identifiable {
    case home, calendar, play, settings

    var id: Self { self }

    var title: String {
        switch self {
        case .home:     "首页"
        case .calendar: "日历"
        case .play:     "娱乐"
        case .settings: "设置"
        }
    }
}

// MARK: - 图标

/// 细线图标。每个图标拆成两层：描边主体，和选中时变橙的一个小部件。
/// 坐标按 24×24 画布写，绘制时等比缩放。
struct TabGlyph: Shape {
    enum Layer { case outline, accent }

    let tab: VesperTab
    let layer: Layer

    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 24
        let origin = CGPoint(x: rect.midX - 12 * s, y: rect.midY - 12 * s)
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: origin.x + x * s, y: origin.y + y * s)
        }
        func r(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
            CGRect(x: origin.x + x * s, y: origin.y + y * s, width: w * s, height: h * s)
        }

        var path = Path()
        switch (tab, layer) {

        // 首页：屋顶 + 方体，门是橙色
        case (.home, .outline):
            path.move(to: p(4.5, 10.4))
            path.addLine(to: p(12, 4.3))
            path.addLine(to: p(19.5, 10.4))
            path.addLine(to: p(19.5, 18))
            path.addQuadCurve(to: p(17.5, 20), control: p(19.5, 20))
            path.addLine(to: p(6.5, 20))
            path.addQuadCurve(to: p(4.5, 18), control: p(4.5, 20))
            path.closeSubpath()
        case (.home, .accent):
            path.addRoundedRect(in: r(10, 13.5, 4, 6.5), cornerSize: CGSize(width: 1.4 * s, height: 1.4 * s))

        // 日历：框 + 两个挂钩 + 一条横线，今天是橙点
        case (.calendar, .outline):
            path.addRoundedRect(in: r(4, 5.5, 16, 14.5), cornerSize: CGSize(width: 3.5 * s, height: 3.5 * s))
            path.move(to: p(8.5, 3.5));  path.addLine(to: p(8.5, 7.2))
            path.move(to: p(15.5, 3.5)); path.addLine(to: p(15.5, 7.2))
            path.move(to: p(4, 10.2));   path.addLine(to: p(20, 10.2))
        case (.calendar, .accent):
            path.addEllipse(in: r(13.9, 13.4, 3.2, 3.2))

        // 娱乐：三个方格 + 一个圆，圆是橙色
        case (.play, .outline):
            let corner = CGSize(width: 2.2 * s, height: 2.2 * s)
            path.addRoundedRect(in: r(4, 4, 7, 7), cornerSize: corner)
            path.addRoundedRect(in: r(13, 4, 7, 7), cornerSize: corner)
            path.addRoundedRect(in: r(4, 13, 7, 7), cornerSize: corner)
        case (.play, .accent):
            path.addEllipse(in: r(13, 13, 7, 7))

        // 设置：两根滑杆，代替齿轮；下面那颗旋钮是橙色
        case (.settings, .outline):
            path.move(to: p(4, 8));     path.addLine(to: p(6.4, 8))
            path.move(to: p(11.6, 8));  path.addLine(to: p(20, 8))
            path.addEllipse(in: r(6.6, 5.6, 4.8, 4.8))
            path.move(to: p(4, 16));    path.addLine(to: p(12.4, 16))
            path.move(to: p(17.6, 16)); path.addLine(to: p(20, 16))
        case (.settings, .accent):
            path.addEllipse(in: r(12.6, 13.6, 4.8, 4.8))
        }
        return path
    }
}

/// 一个完整图标。未选中时整只灰色线稿；选中时主体变墨色，小部件填成橙色。
struct TabIcon: View {
    let tab: VesperTab
    let isSelected: Bool

    var body: some View {
        GeometryReader { geo in
            let width = TabTheme.lineWidth * min(geo.size.width, geo.size.height) / 24
            let style = StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
            ZStack {
                TabGlyph(tab: tab, layer: .outline)
                    .stroke(isSelected ? TabTheme.ink : TabTheme.idle, style: style)
                if isSelected {
                    TabGlyph(tab: tab, layer: .accent)
                        .fill(TabTheme.accent)
                        .transition(.scale(scale: 0.4).combined(with: .opacity))
                } else {
                    TabGlyph(tab: tab, layer: .accent)
                        .stroke(TabTheme.idle, style: style)
                }
            }
        }
        .frame(width: TabTheme.iconSize, height: TabTheme.iconSize)
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
                TabIcon(tab: tab, isSelected: isSelected)
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

#Preview {
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
