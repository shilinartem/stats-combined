//
//  types.swift
//  Kit
//
//  Created by Serhiy Mytrovtsiy on 10/04/2021.
//  Using Swift 5.0.
//  Running on macOS 10.15.
//
//  Copyright © 2021 Serhiy Mytrovtsiy. All rights reserved.
//

import Cocoa

public struct DoubleValue {
    public var ts: Date = Date()
    public let value: Double
    
    public init(_ value: Double = 0) {
        self.value = value
    }
}

public struct ColorValue: Equatable {
    public var ts: Date = Date()
    public let value: Double
    public var color: NSColor?
    
    public init(_ value: Double, color: NSColor? = nil) {
        self.value = value
        self.color = color
    }
    
    // swiftlint:disable function_name_whitespace
    public static func ==(lhs: ColorValue, rhs: ColorValue) -> Bool {
        return lhs.value == rhs.value
    }
    // swiftlint:enable function_name_whitespace
}

public enum AppUpdateInterval: String {
    case silent = "Silent"
    case atStart = "At start"
    case separator1 = "separator_1"
    case oncePerDay = "Once per day"
    case oncePerWeek = "Once per week"
    case oncePerMonth = "Once per month"
    case separator2 = "separator_2"
    case never = "Never"
}
public let AppUpdateIntervals: [KeyValue_t] = [
    KeyValue_t(key: "Silent", value: AppUpdateInterval.silent.rawValue),
    KeyValue_t(key: "At start", value: AppUpdateInterval.atStart.rawValue),
    KeyValue_t(key: "separator_1", value: "separator_1"),
    KeyValue_t(key: "Once per day", value: AppUpdateInterval.oncePerDay.rawValue),
    KeyValue_t(key: "Once per week", value: AppUpdateInterval.oncePerWeek.rawValue),
    KeyValue_t(key: "Once per month", value: AppUpdateInterval.oncePerMonth.rawValue),
    KeyValue_t(key: "separator_2", value: "separator_2"),
    KeyValue_t(key: "Never", value: AppUpdateInterval.never.rawValue)
]

public let TemperatureUnits: [KeyValue_t] = [
    KeyValue_t(key: "system", value: "System"),
    KeyValue_t(key: "separator", value: "separator"),
    KeyValue_t(key: "celsius", value: "Celsius", additional: UnitTemperature.celsius),
    KeyValue_t(key: "fahrenheit", value: "Fahrenheit", additional: UnitTemperature.fahrenheit)
]

public let CombinedModulesSpacings: [KeyValue_t] = [
    KeyValue_t(key: "none", value: "None"),
    KeyValue_t(key: "1", value: "1", additional: 1),
    KeyValue_t(key: "2", value: "2", additional: 2),
    KeyValue_t(key: "3", value: "3", additional: 3),
    KeyValue_t(key: "4", value: "4", additional: 4),
    KeyValue_t(key: "5", value: "5", additional: 5),
    KeyValue_t(key: "6", value: "6", additional: 6),
    KeyValue_t(key: "7", value: "7", additional: 7),
    KeyValue_t(key: "8", value: "8", additional: 8)
]

public let PublicIPAddressRefreshIntervals: [KeyValue_t] = [
    KeyValue_t(key: "never", value: "Never"),
    KeyValue_t(key: "separator", value: "separator"),
    KeyValue_t(key: "hour", value: "Every hour"),
    KeyValue_t(key: "12", value: "Every 12 hours"),
    KeyValue_t(key: "24", value: "Every 24 hours")
]

public enum DataSizeBase: String {
    case bit
    case byte
}
public let SpeedBase: [KeyValue_t] = [
    KeyValue_t(key: "bit", value: "Bit", additional: DataSizeBase.bit),
    KeyValue_t(key: "byte", value: "Byte", additional: DataSizeBase.byte)
]

public let NetworkSpeedUnitAuto = "auto"
public let NetworkSpeedUnits: [KeyValue_t] = [
    KeyValue_t(key: NetworkSpeedUnitAuto, value: "Auto"),
    KeyValue_t(key: SizeUnit.KB.key, value: "KB/Kb"),
    KeyValue_t(key: SizeUnit.MB.key, value: "MB/Mb"),
    KeyValue_t(key: SizeUnit.GB.key, value: "GB/Gb"),
    KeyValue_t(key: SizeUnit.TB.key, value: "TB/Tb")
]

public func networkSpeedUnit(from key: String) -> KeyValue_t {
    NetworkSpeedUnits.first(where: { $0.key.lowercased() == key.lowercased() }) ?? NetworkSpeedUnits[0]
}

public func networkSpeedSizeUnit(from key: String) -> SizeUnit? {
    let unit = networkSpeedUnit(from: key)
    return unit.key == NetworkSpeedUnitAuto ? nil : SizeUnit.fromString(unit.key)
}

public func networkSpeedPrefix(from key: String) -> String? {
    let unit = networkSpeedUnit(from: key)
    return unit.key == NetworkSpeedUnitAuto ? nil : String(unit.key.prefix(1))
}

internal enum StackMode: String {
    case auto = "automatic"
    case oneRow = "oneRow"
    case twoRows = "twoRows"
}

internal let SensorsWidgetValue: [KeyValue_t] = [
    KeyValue_t(key: "oi", value: "output/input"),
    KeyValue_t(key: "io", value: "input/output"),
    KeyValue_t(key: "separator", value: "separator"),
    KeyValue_t(key: "i", value: "input"),
    KeyValue_t(key: "o", value: "output")
]

internal let SensorsWidgetMode: [KeyValue_t] = [
    KeyValue_t(key: StackMode.auto.rawValue, value: "Automatic"),
    KeyValue_t(key: "separator", value: "separator"),
    KeyValue_t(key: StackMode.oneRow.rawValue, value: "One row"),
    KeyValue_t(key: StackMode.twoRows.rawValue, value: "Two rows")
]

internal let SpeedPictogram: [KeyValue_t] = [
    KeyValue_t(key: "none", value: "None"),
    KeyValue_t(key: "separator", value: "separator"),
    KeyValue_t(key: "dots", value: "Dots"),
    KeyValue_t(key: "arrows", value: "Arrows"),
    KeyValue_t(key: "chars", value: "Characters")
]
internal let SpeedPictogramColor: [KeyValue_t] = [
    KeyValue_t(key: "none", value: "None"),
    KeyValue_t(key: "separator", value: "separator"),
    KeyValue_t(key: "default", value: "Default color"),
    KeyValue_t(key: "transparent", value: "Transparent when no activity"),
    KeyValue_t(key: "constant", value: "Constant color")
]

internal let BatteryAdditionals: [KeyValue_t] = [
    KeyValue_t(key: "none", value: "None"),
    KeyValue_t(key: "separator", value: "separator"),
    KeyValue_t(key: "innerPercentage", value: "Percentage inside the icon"),
    KeyValue_t(key: "separator", value: "separator"),
    KeyValue_t(key: "percentage", value: "Percentage"),
    KeyValue_t(key: "time", value: "Time"),
    KeyValue_t(key: "percentageAndTime", value: "Percentage and time"),
    KeyValue_t(key: "timeAndPercentage", value: "Time and percentage")
]

internal let BatteryInfo: [KeyValue_t] = [
    KeyValue_t(key: "percentage", value: "Percentage"),
    KeyValue_t(key: "time", value: "Time"),
    KeyValue_t(key: "percentageAndTime", value: "Percentage and time"),
    KeyValue_t(key: "timeAndPercentage", value: "Time and percentage")
]

public let ShortLong: [KeyValue_t] = [
    KeyValue_t(key: "short", value: "Short"),
    KeyValue_t(key: "long", value: "Long")
]

public let ReaderUpdateIntervals: [KeyValue_t] = [
    KeyValue_t(key: "1", value: "1 sec"),
    KeyValue_t(key: "2", value: "2 sec"),
    KeyValue_t(key: "3", value: "3 sec"),
    KeyValue_t(key: "5", value: "5 sec"),
    KeyValue_t(key: "10", value: "10 sec"),
    KeyValue_t(key: "15", value: "15 sec"),
    KeyValue_t(key: "30", value: "30 sec"),
    KeyValue_t(key: "60", value: "60 sec")
]
public let NumbersOfProcesses: [Int] = [0, 3, 5, 8, 10, 15]

public let NetworkReaders: [KeyValue_t] = [
    KeyValue_t(key: "interface", value: "Interface based"),
    KeyValue_t(key: "process", value: "Processes based")
]

internal let Alignments: [KeyValue_t] = [
    KeyValue_t(key: "left", value: "Left alignment", additional: NSTextAlignment.left),
    KeyValue_t(key: "center", value: "Center alignment", additional: NSTextAlignment.center),
    KeyValue_t(key: "right", value: "Right alignment", additional: NSTextAlignment.right)
]

public struct SColor: KeyValue_p, Equatable {
    public let key: String
    public let value: String
    public var additional: Any?
    
    private static let customPrefix = "custom:"
    
    public static func == (lhs: SColor, rhs: SColor) -> Bool {
        return lhs.key == rhs.key
    }
    
    public static func custom(_ color: NSColor) -> SColor {
        return SColor(key: "\(customPrefix)\(color.hexString)", value: "Custom...", additional: color)
    }
    
    public var isCustom: Bool {
        return self.key.hasPrefix(SColor.customPrefix)
    }
}

extension SColor: CaseIterable {
    public static var utilization: SColor { SColor(key: "utilization", value: "Based on utilization", additional: NSColor.black) }
    public static var pressure: SColor { SColor(key: "pressure", value: "Based on pressure", additional: NSColor.black) }
    public static var cluster: SColor { SColor(key: "cluster", value: "Based on cluster", additional: NSColor.controlAccentColor) }
    
    public static var separator1: SColor { SColor(key: "separator_1", value: "separator_1", additional: NSColor.black) }
    
    public static var systemAccent: SColor { SColor(key: "system", value: "System accent", additional: NSColor.controlAccentColor) }
    public static var monochrome: SColor { SColor(key: "monochrome", value: "Monochrome accent", additional: NSColor.textColor) }
    
    public static var separator2: SColor { SColor(key: "separator_2", value: "separator_2", additional: NSColor.black) }
    
    public static var clear: SColor { SColor(key: "clear", value: "Clear", additional: NSColor.clear) }
    public static var white: SColor { SColor(key: "white", value: "White", additional: NSColor.white) }
    public static var black: SColor { SColor(key: "black", value: "Black", additional: NSColor.black) }
    public static var gray: SColor { SColor(key: "gray", value: "Gray", additional: NSColor.gray) }
    public static var secondGray: SColor { SColor(key: "secondGray", value: "Second gray", additional: NSColor.systemGray) }
    public static var darkGray: SColor { SColor(key: "darkGray", value: "Dark gray", additional: NSColor.darkGray) }
    public static var lightGray: SColor { SColor(key: "lightGray", value: "Light gray", additional: NSColor.lightGray) }
    public static var red: SColor { SColor(key: "red", value: "Red", additional: NSColor.red) }
    public static var secondRed: SColor { SColor(key: "secondRed", value: "Second red", additional: NSColor.systemRed) }
    public static var green: SColor { SColor(key: "green", value: "Green", additional: NSColor.green) }
    public static var secondGreen: SColor { SColor(key: "secondGreen", value: "Second green", additional: NSColor.systemGreen) }
    public static var blue: SColor { SColor(key: "blue", value: "Blue", additional: NSColor.blue) }
    public static var secondBlue: SColor { SColor(key: "secondBlue", value: "Second blue", additional: NSColor.systemBlue) }
    public static var yellow: SColor { SColor(key: "yellow", value: "Yellow", additional: NSColor.yellow) }
    public static var secondYellow: SColor { SColor(key: "secondYellow", value: "Second yellow", additional: NSColor.systemYellow) }
    public static var orange: SColor { SColor(key: "orange", value: "Orange", additional: NSColor.orange) }
    public static var secondOrange: SColor { SColor(key: "secondOrange", value: "Second orange", additional: NSColor.systemOrange) }
    public static var purple: SColor { SColor(key: "purple", value: "Purple", additional: NSColor.purple) }
    public static var secondPurple: SColor { SColor(key: "secondPurple", value: "Second purple", additional: NSColor.systemPurple) }
    public static var brown: SColor { SColor(key: "brown", value: "Brown", additional: NSColor.brown) }
    public static var secondBrown: SColor { SColor(key: "secondBrown", value: "Second brown", additional: NSColor.systemBrown) }
    public static var cyan: SColor { SColor(key: "cyan", value: "Cyan", additional: NSColor.cyan) }
    public static var magenta: SColor { SColor(key: "magenta", value: "Magenta", additional: NSColor.magenta) }
    public static var pink: SColor { SColor(key: "pink", value: "Pink", additional: NSColor.systemPink) }
    public static var teal: SColor { SColor(key: "teal", value: "Teal", additional: NSColor.systemTeal) }
    public static var indigo: SColor { SColor(key: "indigo", value: "Indigo", additional: NSColor.systemIndigo) }
    
    public static var allCases: [SColor] {
        return [.utilization, .pressure, .cluster, separator1,
                .systemAccent, .monochrome, separator2,
                .clear, .white, .black, .gray, .secondGray, .darkGray, .lightGray,
                .red, .secondRed, .green, .secondGreen, .blue, .secondBlue, .yellow, .secondYellow,
                .orange, .secondOrange, .purple, .secondPurple, .brown, .secondBrown,
                .cyan, .magenta, .pink, .teal, .indigo
        ]
    }
    
    public static var allColors: [SColor] {
        return [.systemAccent, .monochrome, .separator2, .clear, .white, .black, .gray, .secondGray, .darkGray, .lightGray,
                .red, .secondRed, .green, .secondGreen, .blue, .secondBlue, .yellow, .secondYellow,
                .orange, .secondOrange, .purple, .secondPurple, .brown, .secondBrown,
                .cyan, .magenta, .pink, .teal, .indigo
        ]
    }
    
    public static func fromString(_ key: String, defaultValue: SColor = .systemAccent) -> SColor {
        if let color = SColor.allCases.first(where: { $0.key == key }) {
            return color
        }
        if key.hasPrefix(customPrefix), let color = NSColor(hex: String(key.dropFirst(customPrefix.count))) {
            return SColor.custom(color)
        }
        return defaultValue
    }
}

internal class MonochromeColor {
    static internal let red: NSColor = NSColor(red: 145/255, green: 145/255, blue: 145/255, alpha: 1)
    static internal let blue: NSColor = NSColor(red: 113/255, green: 113/255, blue: 113/255, alpha: 1)
}

public typealias colorZones = (orange: Double, red: Double)

public extension Notification.Name {
    static let toggleSettings = Notification.Name("toggleSettings")
    static let toggleModule = Notification.Name("toggleModule")
    static let togglePopup = Notification.Name("togglePopup")
    static let popupVisibilityChanged = Notification.Name("popupVisibilityChanged")
    static let toggleWidget = Notification.Name("toggleWidget")
    static let togglePreview = Notification.Name("togglePreview")
    static let openModuleSettings = Notification.Name("openModuleSettings")
    static let clickInSettings = Notification.Name("clickInSettings")
    static let refreshPublicIP = Notification.Name("refreshPublicIP")
    static let resetTotalNetworkUsage = Notification.Name("resetTotalNetworkUsage")
    static let syncFansControl = Notification.Name("syncFansControl")
    static let checkFanModes = Notification.Name("checkFanModes")
    static let fanHelperState = Notification.Name("fanHelperState")
    static let toggleOneView = Notification.Name("toggleOneView")
    static let widgetRearrange = Notification.Name("widgetRearrange")
    static let moduleRearrange = Notification.Name("moduleRearrange")
    static let pause = Notification.Name("pause")
    static let toggleFanControl = Notification.Name("toggleFanControl")
    static let combinedModulesPopup = Notification.Name("combinedModulesPopup")
    static let remoteLoginSuccess = Notification.Name("remoteLoginSuccess")
    static let remoteState = Notification.Name("remoteState")
    static let remoteAuthenticated = Notification.Name("remoteAuthenticated")
    static let remoteUpdate = Notification.Name("remoteUpdate")
    static let openWindow = Notification.Name("openWindow")
}

public var isARM: Bool {
    SystemKit.shared.device.platform != .intel
}

public let notificationLevels: [KeyValue_t] = [
    KeyValue_t(key: "", value: "Disabled"),
    KeyValue_t(key: "0.03", value: "3%"),
    KeyValue_t(key: "0.05", value: "5%"),
    KeyValue_t(key: "0.1", value: "10%"),
    KeyValue_t(key: "0.15", value: "15%"),
    KeyValue_t(key: "0.2", value: "20%"),
    KeyValue_t(key: "0.25", value: "25%"),
    KeyValue_t(key: "0.3", value: "30%"),
    KeyValue_t(key: "0.35", value: "35%"),
    KeyValue_t(key: "0.4", value: "40%"),
    KeyValue_t(key: "0.45", value: "45%"),
    KeyValue_t(key: "0.5", value: "50%"),
    KeyValue_t(key: "0.55", value: "55%"),
    KeyValue_t(key: "0.6", value: "60%"),
    KeyValue_t(key: "0.65", value: "65%"),
    KeyValue_t(key: "0.7", value: "70%"),
    KeyValue_t(key: "0.75", value: "75%"),
    KeyValue_t(key: "0.8", value: "80%"),
    KeyValue_t(key: "0.85", value: "85%"),
    KeyValue_t(key: "0.9", value: "90%"),
    KeyValue_t(key: "0.95", value: "95%"),
    KeyValue_t(key: "0.97", value: "97%"),
    KeyValue_t(key: "1.0", value: "100%")
]

public struct Scale: KeyValue_p, Equatable {
    public let key: String
    public let value: String
    
    public static func == (lhs: Scale, rhs: Scale) -> Bool {
        return lhs.key == rhs.key
    }
}

extension Scale: CaseIterable {
    public static var none: Scale { return Scale(key: "none", value: "None") }
    public static var separator: Scale { return Scale(key: "separator", value: "separator") }
    public static var linear: Scale { return Scale(key: "linear", value: "Linear") }
    public static var square: Scale { return Scale(key: "square", value: "Square") }
    public static var cube: Scale { return Scale(key: "cube", value: "Cube") }
    public static var logarithmic: Scale { return Scale(key: "logarithmic", value: "Logarithmic") }
    public static var separator2: Scale { return Scale(key: "separator", value: "separator") }
    public static var fixed: Scale { return Scale(key: "fixed", value: "Fixed scale") }
    
    public static var allCases: [Scale] {
        return [.none, .separator, .linear, .square, .cube, .logarithmic, .separator2, .fixed]
    }
    
    public static func fromString(_ key: String, defaultValue: Scale = .linear) -> Scale {
        return Scale.allCases.first{ $0.key == key } ?? defaultValue
    }
}

public enum FanValue: String {
    case rpm
    case percentage
}
public let FanValues: [KeyValue_t] = [
    KeyValue_t(key: "rpm", value: "RPM", additional: FanValue.rpm),
    KeyValue_t(key: "percentage", value: "Percentage", additional: FanValue.percentage)
]

public var LineChartHistory: [KeyValue_p] = [
    KeyValue_t(key: "60", value: "1 minute"),
    KeyValue_t(key: "120", value: "2 minutes"),
    KeyValue_t(key: "180", value: "3 minutes"),
    KeyValue_t(key: "300", value: "5 minutes"),
    KeyValue_t(key: "600", value: "10 minutes")
]

public struct SizeUnit: KeyValue_p, Equatable {
    public let key: String
    public let value: String
    
    public static func == (lhs: SizeUnit, rhs: SizeUnit) -> Bool {
        return lhs.key == rhs.key
    }
}

extension SizeUnit: CaseIterable {
    public static var byte: SizeUnit { return SizeUnit(key: "byte", value: "Bytes") }
    public static var KB: SizeUnit { return SizeUnit(key: "KB", value: "KB") }
    public static var MB: SizeUnit { return SizeUnit(key: "MB", value: "MB") }
    public static var GB: SizeUnit { return SizeUnit(key: "GB", value: "GB") }
    public static var TB: SizeUnit { return SizeUnit(key: "TB", value: "TB") }
    
    public static var allCases: [SizeUnit] {
        [.byte, .KB, .MB, .GB, .TB]
    }
    
    public static func fromString(_ key: String, defaultValue: SizeUnit = .byte) -> SizeUnit {
        return SizeUnit.allCases.first{ $0.key == key } ?? defaultValue
    }
    
    public func toBytes(_ value: Int) -> Int {
        switch self {
        case .KB:
            return value * 1_000
        case .MB:
            return value * 1_000 * 1_000
        case .GB:
            return value * 1_000 * 1_000 * 1_000
        case .TB:
            return value * 1_000 * 1_000 * 1_000 * 1_000
        default:
            return value
        }
    }
}

public enum RAMPressure: String, Codable {
    case normal
    case warning
    case critical
    
    public func pressureColor() -> NSColor {
        switch self {
        case .normal:
            return NSColor.systemGreen
        case .warning:
            return NSColor.systemOrange
        case .critical:
            return NSColor.systemRed
        }
    }
    
    public func number() -> Int {
        switch self {
        case .normal:
            return 0
        case .warning:
            return 1
        case .critical:
            return 2
        }
    }
    
    public init(from: Int) {
        switch from {
        case 1:
            self = .warning
        case 2:
            self = .critical
        default:
            self = .normal
        }
    }
}

public struct TokenResponse: Codable {
    public let access_token: String
    public let refresh_token: String
}

public struct DeviceResponse: Codable {
    public let device_code: String
    public let user_code: String
    public let verification_uri_complete: URL
    public let interval: Int?
}

public enum CombinedModulesWidget: String {
    case widgets
    case icon
    case bars
    case rings
    case dial
    case diskRAMNumbers
    case diskRAMUnits
    case diskRAMLabels
    
    public static var all: [KeyValue_t] {
        [
            KeyValue_t(key: Self.widgets.rawValue, value: "Widgets"),
            KeyValue_t(key: Self.icon.rawValue, value: "App icon"),
            KeyValue_t(key: Self.bars.rawValue, value: "Mini bars"),
            KeyValue_t(key: Self.rings.rawValue, value: "Concentric rings"),
            KeyValue_t(key: Self.dial.rawValue, value: "Arc dial")
        ]
    }
    
    public static var current: CombinedModulesWidget {
        get {
            let fallback: CombinedModulesWidget = Store.shared.bool(key: "CombinedModules_icon", defaultValue: false) ? .icon : .widgets
            return CombinedModulesWidget(rawValue: Store.shared.string(key: "CombinedModules_display", defaultValue: fallback.rawValue)) ?? fallback
        }
        set { Store.shared.set(key: "CombinedModules_display", value: newValue.rawValue) }
    }
    
    public var isSummaryWidget: Bool { self == .bars || self == .rings || self == .dial }

    public var isDiskRAMStack: Bool { self == .diskRAMNumbers || self == .diskRAMUnits || self == .diskRAMLabels }

    public static var active: CombinedModulesWidget? {
        if StatusWidgetPreferences.enabled { return StatusWidgetPreferences.layout }
        guard Store.shared.bool(key: "CombinedModules", defaultValue: false), !current.isDiskRAMStack else { return nil }
        return current
    }

    public func includes(module: ModuleType) -> Bool {
        !self.isDiskRAMStack || module == .disk || module == .RAM || module == .battery
    }
}

public enum StatusWidgetValue {
    case storage(Int64?)
    case keyboard(String?)
    case battery(Int?)
}

public enum StatusWidgetCell: String, CaseIterable {
    case disk, keyboard, memory, battery

    public var title: String {
        switch self {
        case .disk: return "Disk"
        case .keyboard: return "Keyboard"
        case .memory: return "RAM"
        case .battery: return "Battery"
        }
    }

    public var metric: StatusWidgetMetric? { StatusWidgetMetric(rawValue: self.rawValue) }

    public func defaultFormat(for layout: CombinedModulesWidget) -> String {
        switch self {
        case .disk: return (layout == .diskRAMLabels ? "SSD " : "") + "$capacity.free$unit"
        case .memory: return (layout == .diskRAMLabels ? "RAM " : "") + "$mem.free$unit"
        case .keyboard: return "$layout"
        case .battery: return "$battery.level"
        }
    }

    public func render(_ template: String, value: StatusWidgetValue, showsUnits: Bool = false) -> String {
        switch (self, value) {
        case (.disk, .storage(let bytes)), (.memory, .storage(let bytes)):
            let text = CompactMenuBar.statusStorageText(template, bytes: bytes, isMemory: self == .memory)
            return Self.substitute("$unit", with: showsUnits ? " GB" : "", in: text)
        case (.keyboard, .keyboard(let layout)):
            return Self.substitute("$layout", with: layout ?? "–", in: template)
        case (.battery, .battery(let percentage)):
            let amount = percentage.map(String.init) ?? "–"
            let level = Self.substitute("$battery.level", with: amount + "%", in: template)
            return Self.substitute("$battery.percent", with: amount, in: level)
        default: return template
        }
    }

    private static func substitute(_ token: String, with value: String, in template: String) -> String {
        let pattern = NSRegularExpression.escapedPattern(for: token) + "(?![a-zA-Z0-9_.])"
        return template.replacingOccurrences(of: pattern, with: NSRegularExpression.escapedTemplate(for: value), options: .regularExpression)
    }
}

public struct StatusWidgetThresholds {
    public let warning: Int
    public let critical: Int

    public init(warning: Int, critical: Int) {
        self.warning = max(0, warning)
        self.critical = min(self.warning, max(0, critical))
    }
}

public enum StatusWidgetMetric: String, CaseIterable {
    case disk, memory, battery

    public var defaultThresholds: StatusWidgetThresholds {
        switch self {
        case .disk: return StatusWidgetThresholds(warning: 40, critical: 15)
        case .memory: return StatusWidgetThresholds(warning: 2, critical: 1)
        case .battery: return StatusWidgetThresholds(warning: 50, critical: 15)
        }
    }

    public func reading(_ amount: Double?, thresholds: StatusWidgetThresholds, prefix: String = "", suffix: String = "") -> CompactMenuBar.Reading {
        guard let amount, amount.isFinite else {
            return CompactMenuBar.Reading(text: prefix + "–" + suffix, tone: .normal)
        }
        let value = max(0, amount)
        let tone: CompactMenuBar.Tone
        if self.below(value, threshold: thresholds.critical) {
            tone = .red
        } else if self.below(value, threshold: thresholds.warning) {
            tone = self == .memory ? .orange : .yellow
        } else {
            tone = .normal
        }
        return CompactMenuBar.Reading(text: "\(prefix)\(Int(value))\(suffix)", tone: tone)
    }

    private func below(_ amount: Double, threshold: Int) -> Bool {
        self == .disk ? amount < Double(threshold) : amount <= Double(threshold)
    }
}

public struct StatusWidgetBatteryReading: Equatable {
    public let level: Double?
    public let label: CompactMenuBar.Reading
    public let showsIcon: Bool
    public let showsPowerPlug: Bool

    public init(level: Double?, isDischarging: Bool, thresholds: StatusWidgetThresholds, showsIcon: Bool, isOnACPower: Bool = false) {
        let level = level.flatMap { $0.isFinite ? min(1, max(0, $0)) : nil }
        let percentage = level.map { ($0 * 100).rounded() }
        let label = StatusWidgetMetric.battery.reading(percentage, thresholds: thresholds, suffix: "%")
        self.level = level
        self.label = isDischarging && !isOnACPower ? label : CompactMenuBar.Reading(text: label.text, tone: .normal)
        self.showsIcon = showsIcon
        self.showsPowerPlug = showsIcon && isOnACPower
    }
}

public enum StatusWidgetPreferences {
    public static var enabled: Bool {
        get { Store.shared.bool(key: "StatusWidget_enabled", defaultValue: false) }
        set { Store.shared.set(key: "StatusWidget_enabled", value: newValue) }
    }

    public static var layout: CombinedModulesWidget {
        get {
            let stored = Store.shared.string(key: "StatusWidget_layout", defaultValue: CombinedModulesWidget.diskRAMUnits.rawValue)
            guard let style = CombinedModulesWidget(rawValue: stored), style.isDiskRAMStack else { return .diskRAMUnits }
            return style
        }
        set { Store.shared.set(key: "StatusWidget_layout", value: newValue.rawValue) }
    }

    private static var legacyShowsUnits: Bool {
        get { Store.shared.bool(key: "StatusWidget_units", defaultValue: layout != .diskRAMNumbers) }
        set { Store.shared.set(key: "StatusWidget_units", value: newValue) }
    }

    public static func showsUnits(for cell: StatusWidgetCell) -> Bool {
        Store.shared.bool(key: "StatusWidget_\(cell.rawValue)_units", defaultValue: legacyShowsUnits)
    }

    public static func setShowsUnits(_ enabled: Bool, for cell: StatusWidgetCell) {
        Store.shared.set(key: "StatusWidget_\(cell.rawValue)_units", value: enabled)
    }

    public static func isVisible(_ cell: StatusWidgetCell) -> Bool {
        Store.shared.bool(key: "StatusWidget_\(cell.rawValue)", defaultValue: true)
    }

    public static func setVisible(_ enabled: Bool, for cell: StatusWidgetCell) {
        Store.shared.set(key: "StatusWidget_\(cell.rawValue)", value: enabled)
    }

    public static func format(for cell: StatusWidgetCell) -> String {
        Store.shared.string(key: "StatusWidget_\(cell.rawValue)_format", defaultValue: cell.defaultFormat(for: layout))
    }

    public static func setFormat(_ template: String, for cell: StatusWidgetCell) {
        Store.shared.set(key: "StatusWidget_\(cell.rawValue)_format", value: template)
    }

    public static var showsBatteryIcon: Bool {
        get { Store.shared.bool(key: "StatusWidget_batteryIcon", defaultValue: true) }
        set { Store.shared.set(key: "StatusWidget_batteryIcon", value: newValue) }
    }

    public static func thresholds(for metric: StatusWidgetMetric) -> StatusWidgetThresholds {
        let defaults = metric.defaultThresholds
        return StatusWidgetThresholds(
            warning: Store.shared.int(key: "StatusWidget_\(metric.rawValue)_warning", defaultValue: defaults.warning),
            critical: Store.shared.int(key: "StatusWidget_\(metric.rawValue)_critical", defaultValue: defaults.critical)
        )
    }

    public static func setThresholds(_ values: StatusWidgetThresholds, for metric: StatusWidgetMetric) {
        Store.shared.set(key: "StatusWidget_\(metric.rawValue)_warning", value: values.warning)
        Store.shared.set(key: "StatusWidget_\(metric.rawValue)_critical", value: values.critical)
    }

    public static func migrateCombinedLayout() {
        guard !Store.shared.exist(key: "StatusWidget_enabled"), CombinedModulesWidget.current.isDiskRAMStack else { return }
        layout = CombinedModulesWidget.current
        legacyShowsUnits = layout != .diskRAMNumbers
        setVisible(Store.shared.bool(key: "CombinedModules_keyboardAndBattery", defaultValue: true), for: .keyboard)
        enabled = Store.shared.bool(key: "CombinedModules", defaultValue: false)
        CombinedModulesWidget.current = .widgets
        Store.shared.set(key: "CombinedModules", value: false)
    }
}
