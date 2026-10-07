import SwiftUI

// MARK: - 底栏主题

/// 首页底栏的配色。取自首页 / 日语页：白卡片、近黑细线，不用彩色。
/// `Color(light:dark:)` 定义在 MujiDetailView.swift。
enum TabTheme {
    static let surface  = Color(light: 0xFFFFFF, dark: 0x1C1C1E)  // 底栏底色
    static let pill     = Color(light: 0xF2F2F4, dark: 0x2C2C2E)  // 选中胶囊
    static let ink      = Color(light: 0x1C1C1E, dark: 0xF2F2F4)  // 选中图标与文字
    static let idle     = Color(light: 0x9C9CA1, dark: 0x7C7C82)  // 未选中

    static let lineWidth: CGFloat = 1.6   // 图标描边，按 24pt 画布计
    static let iconSize: CGFloat = 26
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
}

// MARK: - 图标

/// 纯线条图标，没有填充。坐标按 24×24 画布写，绘制时等比缩放。
struct TabGlyph: Shape {
    let tab: VesperTab

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
        switch tab {

        // 首页：屋顶 + 方体 + 一扇门
        case .home:
            path.move(to: p(4.5, 10.4))
            path.addLine(to: p(12, 4.3))
            path.addLine(to: p(19.5, 10.4))
            path.addLine(to: p(19.5, 18))
            path.addQuadCurve(to: p(17.5, 20), control: p(19.5, 20))
            path.addLine(to: p(6.5, 20))
            path.addQuadCurve(to: p(4.5, 18), control: p(4.5, 20))
            path.closeSubpath()
            path.move(to: p(10, 20))
            path.addLine(to: p(10, 15.5))
            path.addQuadCurve(to: p(11.5, 14), control: p(10, 14))
            path.addLine(to: p(12.5, 14))
            path.addQuadCurve(to: p(14, 15.5), control: p(14, 14))
            path.addLine(to: p(14, 20))

        // 日历：框 + 两个挂钩 + 一条横线
        case .calendar:
            path.addRoundedRect(in: r(4, 5.5, 16, 14.5), cornerSize: CGSize(width: 3.5 * s, height: 3.5 * s))
            path.move(to: p(8.5, 3.5));  path.addLine(to: p(8.5, 7.2))
            path.move(to: p(15.5, 3.5)); path.addLine(to: p(15.5, 7.2))
            path.move(to: p(4, 10.2));   path.addLine(to: p(20, 10.2))

        // 生活：一只杯子，两缕热气
        case .life:
            path.move(to: p(5, 10))
            path.addLine(to: p(16, 10))
            path.addLine(to: p(16, 15))
            path.addQuadCurve(to: p(11.5, 19.5), control: p(16, 19.5))
            path.addLine(to: p(9.5, 19.5))
            path.addQuadCurve(to: p(5, 15), control: p(5, 19.5))
            path.closeSubpath()
            path.move(to: p(16, 11.5))
            path.addLine(to: p(17.5, 11.5))
            path.addQuadCurve(to: p(19.5, 13.5), control: p(19.5, 11.5))
            path.addQuadCurve(to: p(17.5, 15.5), control: p(19.5, 15.5))
            path.addLine(to: p(16, 15.5))
            path.move(to: p(8.5, 4.5));  path.addLine(to: p(8.5, 7))
            path.move(to: p(12.5, 4.5)); path.addLine(to: p(12.5, 7))

        // 设置：两根滑杆，代替齿轮
        case .settings:
            path.move(to: p(4, 8));     path.addLine(to: p(6.6, 8))
            path.move(to: p(11.4, 8));  path.addLine(to: p(20, 8))
            path.addEllipse(in: r(6.6, 5.6, 4.8, 4.8))
            path.move(to: p(4, 16));    path.addLine(to: p(12.6, 16))
            path.move(to: p(17.4, 16)); path.addLine(to: p(20, 16))
            path.addEllipse(in: r(12.6, 13.6, 4.8, 4.8))
        }
        return path
    }
}

/// 一个完整图标。未选中灰色，选中变墨色。
struct TabIcon: View {
    let tab: VesperTab
    let isSelected: Bool

    var body: some View {
        GeometryReader { geo in
            let width = TabTheme.lineWidth * min(geo.size.width, geo.size.height) / 24
            TabGlyph(tab: tab)
                .stroke(isSelected ? TabTheme.ink : TabTheme.idle,
                        style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
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
