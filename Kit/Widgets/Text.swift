//
//  Text.swift
//  Kit
//
//  Created by Serhiy Mytrovtsiy on 08/09/2024
//  Using Swift 5.0
//  Running on macOS 14.6
//
//  Copyright © 2024 Serhiy Mytrovtsiy. All rights reserved.
//  

import Cocoa

public enum CompactMenuBar {
    private static let gigabyte: Int64 = 1_000_000_000
    private static let gibibyte: Int64 = 1 << 30
    public static let defaultDiskTemplate = "$capacity.free[000] GB"
    public static let defaultMemoryTemplate = "$mem.free[00] GB"

    private static let diskExpression = formatExpression(for: "$capacity.free")
    private static let memoryExpression = formatExpression(for: "$mem.free")

    public enum Tone: Equatable {
        case normal, yellow, orange, red

        public func color(dark: Bool) -> NSColor {
            let rgb: (Int, Int, Int)
            switch self {
            case .normal: return .textColor
            case .yellow: rgb = dark ? (255, 213, 74) : (117, 87, 0)
            case .orange: rgb = dark ? (255, 171, 103) : (138, 60, 0)
            case .red: rgb = dark ? (255, 133, 141) : (166, 23, 38)
            }
            return NSColor(srgbRed: CGFloat(rgb.0) / 255, green: CGFloat(rgb.1) / 255, blue: CGFloat(rgb.2) / 255, alpha: 1)
        }
    }

    public struct Reading {
        public let text: String
        public let tone: Tone
    }

    public static func keyboardCode(languageTag: String) -> String? {
        guard let code = languageTag.split(whereSeparator: { $0 == "-" || $0 == "_" }).first,
              (2...3).contains(code.count), code.utf8.allSatisfy({ (65...90).contains($0) || (97...122).contains($0) }) else { return nil }
        return code.uppercased()
    }

    public static func disk(freeBytes: Int64, template: String = "$capacity.free") -> Reading? {
        let tone: Tone
        switch freeBytes {
        case ..<(15 * gigabyte): tone = .red
        case ..<(40 * gigabyte): tone = .yellow
        default: tone = .normal
        }
        return render(template, expression: diskExpression, bytes: freeBytes, format: (gigabyte, 3), tone: tone)
    }

    public static func memory(freeBytes: Int64, template: String = "$mem.free") -> Reading? {
        let tone: Tone
        switch freeBytes {
        case ...gibibyte: tone = .red
        case ...(2 * gibibyte): tone = .orange
        default: tone = .normal
        }
        return render(template, expression: memoryExpression, bytes: freeBytes, format: (gibibyte, 2), tone: tone)
    }

    private static func formatExpression(for variable: String) -> NSRegularExpression? {
        let token = NSRegularExpression.escapedPattern(for: variable)
        return try? NSRegularExpression(pattern: "\(token)(?![a-zA-Z0-9_])(?:\\[(0{1,6})(?:\\.(0{1,3}))?\\]|(?!\\[))")
    }

    private static func render(_ template: String, expression: NSRegularExpression?, bytes: Int64, format: (unit: Int64, digits: Int), tone: Tone) -> Reading? {
        guard let expression else { return nil }
        let matches = expression.matches(in: template, range: NSRange(template.startIndex..., in: template))
        guard !matches.isEmpty else { return nil }

        let (unit, digits) = format
        let rendered = NSMutableString(string: template)
        for match in matches.reversed() {
            let width = match.range(at: 1).length > 0 ? match.range(at: 1).length : digits
            let precision = match.range(at: 2).length
            let limit = (0..<width).reduce(Int64(0)) { limit, _ in limit * 10 + 9 }
            let value = max(0, bytes)
            let whole = value / unit
            var number = padded(min(whole, limit), digits: width)
            if precision > 0 {
                let scale = (0..<precision).reduce(Int64(1)) { scale, _ in scale * 10 }
                let fraction = whole > limit ? scale - 1 : (value % unit) * scale / unit
                number += "." + padded(fraction, digits: precision)
            }
            rendered.replaceCharacters(in: match.range, with: number)
        }
        return Reading(text: rendered as String, tone: tone)
    }

    private static func padded(_ value: Int64, digits: Int) -> String {
        let text = String(value)
        return String(repeating: "0", count: max(0, digits - text.count)) + text
    }

    public static func showsBattery(level: Double, onBatteryPower: Bool, isCharging: Bool) -> Bool {
        onBatteryPower && !isCharging && (0..<0.5).contains(level)
    }

    public static func batteryPercentage(level: Double) -> String {
        guard level.isFinite else { return "–" }
        return "\(Int((min(1, max(0, level)) * 100).rounded()))%"
    }
}

public class TextWidget: WidgetWrapper {
    private var value: String = ""
    private var tone: CompactMenuBar.Tone?
    private static let variableRegex = try? NSRegularExpression(pattern: "(\\$[a-zA-Z0-9_]+)(?:\\.([a-zA-Z0-9_]+))?")
    
    public init(title: String, preview: Bool = false) {
        super.init(.text, title: title, frame: CGRect(
            x: 0,
            y: Constants.Widget.margin.y,
            width: 30 + (2*Constants.Widget.margin.x),
            height: Constants.Widget.height - (2*Constants.Widget.margin.y)
        ))
        
        if preview {
            self.value = "Text"
        }
        
        self.canDrawConcurrently = true
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let (value, tone) = self.queue.sync { (self.value, self.tone) }
        
        if value.isEmpty {
            self.setWidth(0)
            return
        }
        
        let valueSize: CGFloat = 12
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        let font = tone == nil ? NSFont.systemFont(ofSize: valueSize) : NSFont.monospacedDigitSystemFont(ofSize: valueSize, weight: .medium)
        let stringAttributes = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: tone?.color(dark: isDarkMode) ?? NSColor.textColor,
            NSAttributedString.Key.paragraphStyle: style
        ]
        let attributedString = NSAttributedString(string: value, attributes: stringAttributes)
        let size = attributedString.boundingRect(
            with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        )
        let width = (size.width+Constants.Widget.margin.x*2).roundedUpToNearestTen()
        let origin: CGPoint = CGPoint(x: Constants.Widget.margin.x, y: ((Constants.Widget.height-valueSize-1)/2))
        let rect = CGRect(x: origin.x, y: origin.y, width: width - (Constants.Widget.margin.x*2), height: valueSize)
        attributedString.draw(with: rect)
        
        self.setWidth(width)
    }
    
    public override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        self.needsDisplay = true
    }

    public func setValue(_ newValue: String, tone: CompactMenuBar.Tone? = nil) {
        let updated = self.queue.sync { () -> Bool in
            guard self.value != newValue || self.tone != tone else { return false }
            self.value = newValue
            self.tone = tone
            return true
        }
        guard updated else { return }
        DispatchQueue.main.async(execute: {
            self.needsDisplay = true
        })
    }
    
    static public func parseText(_ raw: String) -> [KeyValue_t] {
        var pairs: [KeyValue_t] = []
        guard let regex = TextWidget.variableRegex else { return pairs }
        let matches = regex.matches(in: raw, range: NSRange(raw.startIndex..., in: raw))
        for match in matches {
            if let keyRange = Range(match.range(at: 1), in: raw) {
                let key = String(raw[keyRange])
                let value: String?
                if match.range(at: 2).location != NSNotFound, let valueRange = Range(match.range(at: 2), in: raw) {
                    value = String(raw[valueRange])
                } else {
                    value = nil
                }
                pairs.append(KeyValue_t(key: key, value: value ?? ""))
            }
        }
        return pairs
    }
}
