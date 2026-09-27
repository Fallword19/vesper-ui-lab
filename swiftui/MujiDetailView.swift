import SwiftUI
import UIKit

// MARK: - 无印主题

/// 气泡详情页的「无印」配色与字体。浅色为设计稿原值，深色为对应的夜间版本。
enum Muji {
    static let paper    = Color(light: 0xF2EEE6, dark: 0x1D1B18)  // 底色：米灰纸
    static let ink      = Color(light: 0x3B3530, dark: 0xE8E2D8)  // 正文
    static let muted    = Color(light: 0x756C62, dark: 0xA39A8E)  // 次要文字
    static let faint    = Color(light: 0x9A9084, dark: 0x7E766C)  // 小变化、无变化
    static let rule     = Color(light: 0xD9D0C3, dark: 0x36322D)  // 细线
    static let track    = Color(light: 0xE2DACD, dark: 0x2E2A26)  // 条的底槽
    static let fill     = Color(light: 0x8F857A, dark: 0x8F857A)  // 条的填充
    static let accent   = Color(light: 0x8C2F24, dark: 0xC0584A)  // 大变化、判定

    static let sideInset: CGFloat = 28
    static let ruleWidth: CGFloat = 1

    /// 宋体。系统没有这个字体时自动退回系统字体。
    static func serif(_ size: CGFloat) -> Font {
        .custom("STSongti-SC-Regular", size: size)
    }

    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    static func label(_ size: CGFloat = 12) -> Font {
        .system(size: size)
    }
}

extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

// MARK: - 数据

/// 详情页需要的全部数据。把你现有的模型映射到这里即可。
struct BubbleDetail {
    var timestamp: Date
    var positionInTurn: Int          // 本轮第几个气泡
    var bubblesInTurn: Int           // 本轮一共几个
    var readSummary: String          // 「她在嘴硬挑衅，故意说反话」
    var tags: [String]               // 嘴硬、挑衅、反话
    var verdict: String              // 躁动上升
    var confidence: Double           // 0...1
    var judgeModel: String           // deepseek-v4-pro
    var emotions: [Dimension]
    var desires: [Dimension]
    var response: ResponseStats
}

struct Dimension: Identifiable {
    var id: String { name }
    var name: String
    var value: Double                // 0...100，当前值
    var delta: Double?               // 本轮变化；这一轮没算到就传 nil
}

struct ResponseStats {
    var duration: TimeInterval
    var cacheHitRate: Double         // 0...1
    var outputTokens: Int
    var rows: [KeyValue]             // 模型、思考强度、会话、各项 token……
}

struct KeyValue: Identifiable {
    var id: String { key }
    var key: String
    var value: String
}

// MARK: - 页面

struct MujiDetailView: View {
    let detail: BubbleDetail
    /// 变化的绝对值达到这个数才用强调色。
    var bigChangeThreshold: Double = 3

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header

                sectionLabel("读到的").padding(.top, 20)
                readBlock

                ruledList {
                    KeyValueRow(key: "判定", value: detail.verdict, valueColor: Muji.accent, mono: false)
                    KeyValueRow(key: "把握", value: "\(Int((detail.confidence * 100).rounded()))%")
                    KeyValueRow(key: "判断模型", value: detail.judgeModel, valueSize: 11)
                }
                .padding(.top, 26)

                sectionLabel("情绪").padding(.top, 44)
                dimensionList(detail.emotions).padding(.top, 10)

                sectionLabel("欲望").padding(.top, 36)
                dimensionList(detail.desires).padding(.top, 10)

                sectionLabel("本轮回答").padding(.top, 44)
                statsRow.padding(.top, 14)

                ruledList {
                    ForEach(detail.response.rows) { row in
                        KeyValueRow(key: row.key, value: row.value, size: 11, vPadding: 9)
                    }
                }
                .padding(.top, 20)
            }
            .padding(.horizontal, Muji.sideInset)
            .padding(.bottom, 36)
        }
        .background(Muji.paper.ignoresSafeArea())
        .foregroundStyle(Muji.ink)
    }

    // MARK: 顶部

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .light))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("返回")
            .padding(.leading, -14)

            Spacer()

            Text("\(Self.timeFormatter.string(from: detail.timestamp))　\(detail.positionInTurn)/\(detail.bubblesInTurn)")
                .font(Muji.mono(10))
                .tracking(0.8)
                .foregroundStyle(Muji.muted)
        }
        .frame(height: 52)
    }

    // MARK: 读到的

    private var readBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(detail.readSummary)
                .font(Muji.serif(17))
                .tracking(1)
                .lineSpacing(15)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 14)

            HStack(spacing: 14) {
                ForEach(detail.tags, id: \.self) { tag in
                    Text(tag)
                }
            }
            .font(Muji.label(11))
            .tracking(1.1)
            .foregroundStyle(Muji.muted)
        }
    }

    // MARK: 情绪 / 欲望

    private func dimensionList(_ items: [Dimension]) -> some View {
        ruledList {
            ForEach(items) { item in
                DimensionRow(item: item, threshold: bigChangeThreshold)
            }
        }
    }

    // MARK: 本轮回答

    private var statsRow: some View {
        HStack(alignment: .top, spacing: 0) {
            stat(String(format: "%.1fs", detail.response.duration), "耗时")
            stat(String(format: "%.2f%%", detail.response.cacheHitRate * 100), "缓存命中")
            stat("\(detail.response.outputTokens)", "输出")
        }
    }

    private func stat(_ value: String, _ caption: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(Muji.mono(20))
            Text(caption)
                .font(Muji.label(10))
                .tracking(1)
                .foregroundStyle(Muji.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: 通用

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(Muji.label(10))
            .tracking(3)
            .foregroundStyle(Muji.muted)
    }

    /// 顶上一条线，每一行下面一条线。
    private func ruledList<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 0) {
            Rule()
            content()
        }
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()
}

// MARK: - 行组件

private struct Rule: View {
    var body: some View {
        Rectangle()
            .fill(Muji.rule)
            .frame(height: Muji.ruleWidth)
    }
}

private struct KeyValueRow: View {
    let key: String
    let value: String
    var valueColor: Color = Muji.ink
    var mono = true
    var size: CGFloat = 12
    var valueSize: CGFloat? = nil
    var vPadding: CGFloat = 10

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(key)
                    .foregroundStyle(size < 12 ? Muji.muted : Muji.ink)
                Spacer(minLength: 12)
                Text(value)
                    .font(mono ? Muji.mono(valueSize ?? size) : Muji.label(valueSize ?? size))
                    .foregroundStyle(valueColor)
                    .multilineTextAlignment(.trailing)
            }
            .font(Muji.label(size))
            .padding(.vertical, vPadding)
            Rule()
        }
    }
}

private struct DimensionRow: View {
    let item: Dimension
    let threshold: Double

    private var isBig: Bool {
        guard let d = item.delta else { return false }
        return abs(d) >= threshold
    }

    private var deltaText: String {
        guard let d = item.delta else { return "—" }
        return String(format: "%+.1f", d)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text(item.name)
                    .font(Muji.label(12))
                    .frame(width: 62, alignment: .leading)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(Muji.track)
                        Rectangle()
                            .fill(Muji.fill)
                            .frame(width: geo.size.width * min(max(item.value, 0), 100) / 100)
                    }
                }
                .frame(height: 2)

                Text("\(Int(item.value.rounded()))")
                    .font(Muji.mono(12))
                    .frame(width: 24, alignment: .trailing)

                Text(deltaText)
                    .font(Muji.mono(10))
                    .foregroundStyle(isBig ? Muji.accent : Muji.faint)
                    .frame(width: 40, alignment: .trailing)
            }
            .frame(height: 37)
            Rule()
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 预览

#Preview {
    MujiDetailView(detail: .sample)
}

extension BubbleDetail {
    static let sample = BubbleDetail(
        timestamp: Date(),
        positionInTurn: 1,
        bubblesInTurn: 5,
        readSummary: "她在嘴硬挑衅，故意说反话。",
        tags: ["嘴硬", "挑衅", "反话"],
        verdict: "躁动上升",
        confidence: 0.9,
        judgeModel: "deepseek-v4-pro",
        emotions: [
            Dimension(name: "躁动", value: 84, delta: 10.7),
            Dimension(name: "不悦", value: 22, delta: 5.0),
            Dimension(name: "亲近", value: 94, delta: 1.5),
            Dimension(name: "想念", value: 73, delta: nil),
            Dimension(name: "心疼", value: 62, delta: nil),
            Dimension(name: "收紧程度", value: 51, delta: nil),
        ],
        desires: [
            Dimension(name: "性欲", value: 75, delta: 1.3),
            Dimension(name: "快乐", value: 68, delta: 1.3),
            Dimension(name: "内省", value: 50, delta: 1.3),
            Dimension(name: "亲密", value: 84, delta: 1.0),
            Dimension(name: "疲劳", value: 37, delta: 0.2),
            Dimension(name: "好奇", value: 51, delta: -0.2),
        ],
        response: ResponseStats(
            duration: 5.9,
            cacheHitRate: 0.9979,
            outputTokens: 88,
            rows: [
                KeyValue(key: "模型", value: "claude-opus-4-6"),
                KeyValue(key: "思考强度", value: "Medium"),
                KeyValue(key: "会话", value: "续接（缓存前缀完整）"),
                KeyValue(key: "新增输入 / 输出", value: "329 / 88"),
                KeyValue(key: "缓存读取 / 写入", value: "155,528 / 326"),
                KeyValue(key: "合计处理", value: "155,945"),
                KeyValue(key: "缓存时长", value: "1 小时"),
                KeyValue(key: "工具调用", value: "0 次"),
                KeyValue(key: "完成状态", value: "正常完成"),
            ]
        )
    )
}
