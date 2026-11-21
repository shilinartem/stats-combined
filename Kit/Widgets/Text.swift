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

    public static func disk(freeBytes: Int64) -> Reading {
        let tone: Tone
        switch freeBytes {
        case ..<(15 * gigabyte): tone = .red
        case ..<(40 * gigabyte): tone = .yellow
        default: tone = .normal
        }
        let count = min(999, max(0, freeBytes / gigabyte))
        return Reading(text: String(format: "%03lld", count), tone: tone)
    }

    public static func memory(freeBytes: Int64) -> Reading {
        let tone: Tone
        switch freeBytes {
        case ...gibibyte: tone = .red
        case ...(2 * gibibyte): tone = .orange
        default: tone = .normal
        }
        let count = min(99, max(0, freeBytes / gibibyte))
        return Reading(text: String(format: "%02lld", count), tone: tone)
    }

    public static func showsBattery(level: Double, onBatteryPower: Bool, isCharging: Bool) -> Bool {
        onBatteryPower && !isCharging && (0..<0.5).contains(level)
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
