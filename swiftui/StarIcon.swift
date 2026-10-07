import SwiftUI

// MARK: - 星象图标
//
// Vesper 底栏的四个图标：首页是暮星，日历是月相，生活是日出，设置是行星。
// 坐标都按 24×24 的画布写，绘制时整体等比缩放，所以线宽也跟着缩放。
// 和网页预览 https://claude.ai/artifact/UHN1uSFugssQreQozMcPx7 里的 SVG 一一对应。

enum StarIconKind: CaseIterable {
    case home, calendar, life, settings
}

/// 三种画法，对应预览页顶部的三个按钮。
enum StarIconStyle {
    case line   // 精修线稿：未选中是线，选中变实心
    case duo    // 双色：未选中透一点金色，选中金色填满
    case glow   // 星光：选中时身后有一圈慢慢呼吸的金色光
}

struct StarIcon: View {
    let kind: StarIconKind
    let isSelected: Bool
    var style: StarIconStyle = .line
    var color: Color
    var accent: Color
    /// 月相选中时，暗面那一窄条的颜色。传未选中的灰色即可，会再调淡一点。
    var shade: Color = .clear

    @State private var breathing = false

    var body: some View {
        Canvas { ctx, size in
            let s = min(size.width, size.height) / 24
            ctx.translateBy(x: (size.width - 24 * s) / 2, y: (size.height - 24 * s) / 2)
            ctx.scaleBy(x: s, y: s)
            draw(&ctx)
        }
        .background {
            if isSelected && style == .glow {
                Circle()
                    .fill(RadialGradient(colors: [accent.opacity(0.6), accent.opacity(0)],
                                         center: .center, startRadius: 0, endRadius: 14))
                    .scaleEffect(breathing ? 1.08 : 0.9)
                    .opacity(breathing ? 1 : 0.75)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                            breathing = true
                        }
                    }
                    .onDisappear { breathing = false }
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: 绘制

    private static let lineWidth: CGFloat = 1.35
    private var lineStyle: StrokeStyle {
        StrokeStyle(lineWidth: Self.lineWidth, lineCap: .round, lineJoin: .round)
    }

    private func draw(_ ctx: inout GraphicsContext) {
        switch kind {
        case .home:
            paint(&ctx, Glyph.star(cx: 10.5, cy: 13, rv: 8.5, rh: 7, k: 2.3))
            paint(&ctx, Glyph.star(cx: 18.6, cy: 5.4, rv: 3.2, rh: 2.5, k: 0.9))

        case .calendar:
            // 未选中：11 月 5 日的残月（左边亮，约 23%），整个月亮的轮廓淡淡地画出来
            // 选中：7 月 25 日的盈凸月（右边亮，约 80%），左边暗面填淡灰色
            let disc = Path(ellipseIn: CGRect(x: 4, y: 4, width: 16, height: 16))
            if isSelected {
                ctx.fill(disc, with: .color(shade.opacity(0.55)))
                line(&ctx, disc)
                paint(&ctx, Glyph.waxingGibbous)
            } else {
                line(&ctx, disc, opacity: 0.4)
                paint(&ctx, Glyph.waningCrescent)
            }

        case .life:
            paint(&ctx, Glyph.risingSun)
            line(&ctx, Glyph.sunRays)
            line(&ctx, Glyph.water)

        case .settings:
            var g = ctx
            g.translateBy(x: 12, y: 12)
            g.rotate(by: .degrees(-20))
            // 整圈星环
            line(&g, Path(ellipseIn: CGRect(x: -10.6, y: -2.5, width: 21.2, height: 5)))
            // 在星球周围擦出一圈空隙，星环后半段就藏到星球后面
            g.blendMode = .destinationOut
            g.fill(Path(ellipseIn: CGRect(x: -6.4, y: -6.4, width: 12.8, height: 12.8)), with: .color(.black))
            g.blendMode = .normal
            paint(&g, Path(ellipseIn: CGRect(x: -5.6, y: -5.6, width: 11.2, height: 11.2)))
            // 星环前半段从星球前面穿过，两边也留一道缝
            let front = Glyph.lowerHalfEllipse(rx: 10.6, ry: 2.5)
            g.blendMode = .destinationOut
            g.stroke(front, with: .color(.black), lineWidth: 2.4)
            g.blendMode = .normal
            line(&g, front)
            // 一颗小卫星
            ctx.fill(Path(ellipseIn: CGRect(x: 3.4 - 0.95, y: 6.2 - 0.95, width: 1.9, height: 1.9)),
                     with: .color(color))
        }
    }

    /// 星体：按选中状态和画法决定描边还是填满。
    private func paint(_ ctx: inout GraphicsContext, _ path: Path) {
        switch (isSelected, style) {
        case (false, .duo):
            ctx.fill(path, with: .color(accent.opacity(0.22)))
            ctx.stroke(path, with: .color(color), style: lineStyle)
        case (false, _):
            ctx.stroke(path, with: .color(color), style: lineStyle)
        case (true, .duo):
            ctx.fill(path, with: .color(accent))
            ctx.stroke(path, with: .color(color), style: lineStyle)
        case (true, _):
            ctx.fill(path, with: .color(color))
            ctx.stroke(path, with: .color(color), style: lineStyle)
        }
    }

    /// 只描线的部分：光芒、水面、轮廓。
    private func line(_ ctx: inout GraphicsContext, _ path: Path, opacity: Double = 1) {
        ctx.stroke(path, with: .color(color.opacity(opacity)), style: lineStyle)
    }
}

// MARK: - 形状

private enum Glyph {
    /// 把椭圆弧拆成三次贝塞尔曲线的系数。
    static let kappa: CGFloat = 0.5522847

    /// 四角星，四条边向内凹。rv 是上下半径，rh 是左右半径，k 越大星越胖。
    static func star(cx: CGFloat, cy: CGFloat, rv: CGFloat, rh: CGFloat, k: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: cx, y: cy - rv))
        p.addCurve(to: CGPoint(x: cx + rh, y: cy),
                   control1: CGPoint(x: cx + k * 0.3, y: cy - k), control2: CGPoint(x: cx + k, y: cy - k * 0.3))
        p.addCurve(to: CGPoint(x: cx, y: cy + rv),
                   control1: CGPoint(x: cx + k, y: cy + k * 0.3), control2: CGPoint(x: cx + k * 0.3, y: cy + k))
        p.addCurve(to: CGPoint(x: cx - rh, y: cy),
                   control1: CGPoint(x: cx - k * 0.3, y: cy + k), control2: CGPoint(x: cx - k, y: cy + k * 0.3))
        p.addCurve(to: CGPoint(x: cx, y: cy - rv),
                   control1: CGPoint(x: cx - k, y: cy - k * 0.3), control2: CGPoint(x: cx - k * 0.3, y: cy - k))
        p.closeSubpath()
        return p
    }

    /// 从椭圆最上面沿一侧画到最下面（downward），或反过来。调用前当前点必须在起点。
    static func addHalfEllipse(_ p: inout Path, cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat,
                               rightSide: Bool, downward: Bool) {
        let sx: CGFloat = rightSide ? 1 : -1
        let k = kappa
        let mid = CGPoint(x: cx + sx * rx, y: cy)
        if downward {
            p.addCurve(to: mid, control1: CGPoint(x: cx + sx * k * rx, y: cy - ry), control2: CGPoint(x: cx + sx * rx, y: cy - k * ry))
            p.addCurve(to: CGPoint(x: cx, y: cy + ry), control1: CGPoint(x: cx + sx * rx, y: cy + k * ry), control2: CGPoint(x: cx + sx * k * rx, y: cy + ry))
        } else {
            p.addCurve(to: mid, control1: CGPoint(x: cx + sx * k * rx, y: cy + ry), control2: CGPoint(x: cx + sx * rx, y: cy + k * ry))
            p.addCurve(to: CGPoint(x: cx, y: cy - ry), control1: CGPoint(x: cx + sx * rx, y: cy - k * ry), control2: CGPoint(x: cx + sx * k * rx, y: cy - ry))
        }
    }

    /// 盈凸月：右半边亮，明暗交界线向左鼓出去。
    static let waxingGibbous: Path = {
        var p = Path()
        p.move(to: CGPoint(x: 12, y: 4))
        addHalfEllipse(&p, cx: 12, cy: 12, rx: 8, ry: 8, rightSide: true, downward: true)
        addHalfEllipse(&p, cx: 12, cy: 12, rx: 4.8, ry: 8, rightSide: false, downward: false)
        p.closeSubpath()
        return p
    }()

    /// 残月：左边一道月牙。
    static let waningCrescent: Path = {
        var p = Path()
        p.move(to: CGPoint(x: 12, y: 4))
        addHalfEllipse(&p, cx: 12, cy: 12, rx: 8, ry: 8, rightSide: false, downward: true)
        addHalfEllipse(&p, cx: 12, cy: 12, rx: 4.32, ry: 8, rightSide: false, downward: false)
        p.closeSubpath()
        return p
    }()

    /// 地平线上的半个太阳。
    static let risingSun: Path = {
        let k = kappa, r: CGFloat = 5
        var p = Path()
        p.move(to: CGPoint(x: 7, y: 15.5))
        p.addCurve(to: CGPoint(x: 12, y: 10.5), control1: CGPoint(x: 7, y: 15.5 - k * r), control2: CGPoint(x: 12 - k * r, y: 10.5))
        p.addCurve(to: CGPoint(x: 17, y: 15.5), control1: CGPoint(x: 12 + k * r, y: 10.5), control2: CGPoint(x: 17, y: 15.5 - k * r))
        p.closeSubpath()
        return p
    }()

    static let sunRays: Path = {
        var p = Path()
        p.move(to: CGPoint(x: 12, y: 8.5));     p.addLine(to: CGPoint(x: 12, y: 6.6))
        p.move(to: CGPoint(x: 7.05, y: 10.55)); p.addLine(to: CGPoint(x: 5.71, y: 9.21))
        p.move(to: CGPoint(x: 16.95, y: 10.55)); p.addLine(to: CGPoint(x: 18.29, y: 9.21))
        return p
    }()

    /// 地平线（太阳两侧各一段）和两道水面倒影。
    static let water: Path = {
        var p = Path()
        p.move(to: CGPoint(x: 2.5, y: 15.5));  p.addLine(to: CGPoint(x: 5.6, y: 15.5))
        p.move(to: CGPoint(x: 18.4, y: 15.5)); p.addLine(to: CGPoint(x: 21.5, y: 15.5))
        p.move(to: CGPoint(x: 8.5, y: 18.3));  p.addLine(to: CGPoint(x: 15.5, y: 18.3))
        p.move(to: CGPoint(x: 10.5, y: 20.8)); p.addLine(to: CGPoint(x: 13.5, y: 20.8))
        return p
    }()

    /// 以原点为中心的椭圆下半段，从左端经最下面到右端。
    static func lowerHalfEllipse(rx: CGFloat, ry: CGFloat) -> Path {
        let k = kappa
        var p = Path()
        p.move(to: CGPoint(x: -rx, y: 0))
        p.addCurve(to: CGPoint(x: 0, y: ry), control1: CGPoint(x: -rx, y: k * ry), control2: CGPoint(x: -k * rx, y: ry))
        p.addCurve(to: CGPoint(x: rx, y: 0), control1: CGPoint(x: k * rx, y: ry), control2: CGPoint(x: rx, y: k * ry))
        return p
    }
}
