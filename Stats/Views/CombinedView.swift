//
//  CombinedView.swift
//  Stats
//
//  Created by Serhiy Mytrovtsiy on 09/01/2023
//  Using Swift 5.0
//  Running on macOS 13.1
//
//  Copyright © 2023 Serhiy Mytrovtsiy. All rights reserved.
//

import Cocoa
import Carbon
import Kit
import Disk
import RAM
import Battery

internal class CombinedView: NSObject, NSGestureRecognizerDelegate {
    private var menuBarItem: NSStatusItem? = nil
    private var view: NSView = NSView(frame: NSRect(x: 0, y: 0, width: 0, height: Constants.Widget.height))
    private var popup: PopupWindow? = nil
    private var clickMonitor: Any? = nil
    private let summary: CombinedSummaryWidget = CombinedSummaryWidget()
    private let stacked = StackedMenuBarView()
    private var stackedItemWidth: CGFloat?
    private var diskDigits = 3
    private let memoryDigits = String(ProcessInfo.processInfo.physicalMemory / 1_073_741_824).count
    private static let inputSourceChanged = Notification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String)
    
    private var status: Bool {
        CombinedModulesWidget.active != nil && !Store.shared.bool(key: "pause", defaultValue: false)
    }
    private var display: CombinedModulesWidget { CombinedModulesWidget.active ?? .widgets }
    private var spacing: CGFloat {
        CGFloat(Int(Store.shared.string(key: "CombinedModules_spacing", defaultValue: "")) ?? 0)
    }
    private var separator: Bool {
        Store.shared.bool(key: "CombinedModules_separator", defaultValue: false)
    }
    
    private var activeModules: [Module] {
        let style = self.display
        let showsBattery = StatusWidgetPreferences.showsBattery
        return modules.filter {
            $0.enabled && $0.menuBar.presentationVisible && style.includes(module: $0.moduleType, showsBattery: showsBattery)
        }.sorted(by: { $0.combinedPosition < $1.combinedPosition })
    }
    
    private var combinedModulesPopup: Bool {
        get { Store.shared.bool(key: "CombinedModules_popup", defaultValue: true) }
        set { Store.shared.set(key: "CombinedModules_popup", value: newValue) }
    }
    private var combinedModulesAlternateDetails: Bool {
        get { Store.shared.bool(key: "CombinedModules_alternateDetails", defaultValue: true) }
        set { Store.shared.set(key: "CombinedModules_alternateDetails", value: newValue) }
    }
    private var combinedModulesModifierKeys: [UInt16] {
        get { Store.shared.array(key: "CombinedModules_modifierKeys", defaultValue: [58]) as? [UInt16] ?? [58] }
        set { Store.shared.set(key: "CombinedModules_modifierKeys", value: newValue) }
    }
    
    override init() {
        super.init()
        
        modules.forEach { (m: Module) in
            m.menuBar.callback = { [weak self] in
                if let s = self?.status, s {
                    DispatchQueue.main.async(execute: {
                        self?.recalculate()
                    })
                }
            }
            m.summaryCallback = { [weak self] module, value in
                guard let self else { return }
                self.summary.setValue(for: module, with: value)
                guard self.status else { return }
                let style = self.display
                if style.isSummaryWidget {
                    self.updateSummary()
                } else if style.isDiskRAMStack && style.includes(module: module, showsBattery: StatusWidgetPreferences.showsBattery) {
                    self.updateStackedReadings()
                }
            }
        }
        
        self.popup = PopupWindow(title: "Combined modules", module: .combined, view: Popup()) { _ in }
        
        if self.status {
            self.enable()
        }
        
        self.clickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            guard let self else { return event }
            return self.handleAlternateClick(event)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(listenForStateChange), name: .toggleOneView, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(listenForStateChange), name: .pause, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(listenForModuleRearrrange), name: .moduleRearrange, object: nil)
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(keyboardInputChanged), name: Self.inputSourceChanged, object: nil)
    }
    
    deinit {
        if let monitor = self.clickMonitor {
            NSEvent.removeMonitor(monitor)
        }
        NotificationCenter.default.removeObserver(self, name: .toggleOneView, object: nil)
        NotificationCenter.default.removeObserver(self, name: .pause, object: nil)
        NotificationCenter.default.removeObserver(self, name: .moduleRearrange, object: nil)
        DistributedNotificationCenter.default().removeObserver(self, name: Self.inputSourceChanged, object: nil)
    }
    
    public func enable() {
        guard self.menuBarItem == nil else { return }

        if self.display.isDiskRAMStack {
            self.updateStackedReadings()
            self.stackedItemWidth = self.stacked.frame.width
        }
        self.menuBarItem = NSStatusBar.system.statusItem(withLength: self.stackedItemWidth ?? 0)
        DispatchQueue.main.async(execute: {
            self.menuBarItem?.autosaveName = "CombinedModules"
        })
        self.menuBarItem?.button?.addSubview(self.view)
        self.menuBarItem?.button?.image = NSImage()
        self.menuBarItem?.button?.toolTip = localizedString("Combined modules")
        
        self.menuBarItem?.button?.target = self
        self.menuBarItem?.button?.action = #selector(self.handleClick)
        self.menuBarItem?.button?.sendAction(on: [.leftMouseDown, .rightMouseDown])
        
        DispatchQueue.main.async(execute: {
            self.recalculate()
        })
    }
    
    public func disable() {
        self.popup?.setIsVisible(false)
        if let item = self.menuBarItem {
            NSStatusBar.system.removeStatusItem(item)
        }
        self.menuBarItem = nil
        self.stackedItemWidth = nil
    }
    
    private func recalculate() {
        guard self.status, self.menuBarItem != nil else { return }
        if self.display.isDiskRAMStack {
            self.updateStackedReadings()
            return
        }

        self.stackedItemWidth = nil
        self.view.subviews.forEach({ $0.removeFromSuperview() })
        self.menuBarItem?.button?.toolTip = localizedString("Combined modules")
        self.menuBarItem?.button?.setAccessibilityLabel(localizedString("Combined modules"))
        
        if self.display.isSummaryWidget {
            self.updateSummary()
            return
        }
        
        if self.display == .icon {
            self.view.addSubview(AppIcon())
            self.view.setFrameSize(NSSize(width: AppIcon.size.width, height: self.view.frame.height))
            self.menuBarItem?.length = AppIcon.size.width
            return
        }
        
        let visibleModules = self.activeModules.filter({ !$0.menuBar.activeWidgets.isEmpty })
        var w: CGFloat = 0
        visibleModules.enumerated().forEach { (i, m) in
            if i != 0 {
                w += self.spacing
                if self.separator {
                    self.view.addSubview(SeparatorLineView(frame: NSRect(x: w, y: 3, width: 1, height: Constants.Widget.height-6)))
                    w += 3 + self.spacing
                }
            }
            self.view.addSubview(m.menuBar.view)
            m.menuBar.view.setFrameOrigin(NSPoint(x: w, y: 0))
            w += m.menuBar.view.frame.width
        }
        self.view.setFrameSize(NSSize(width: w, height: self.view.frame.height))
        self.menuBarItem?.length = w
    }

    @objc private func keyboardInputChanged() {
        DispatchQueue.main.async { [weak self] in
            guard StatusWidgetPreferences.showsKeyboard else { return }
            self?.updateStackedReadings()
        }
    }

    private func updateStackedReadings() {
        guard self.status else { return }
        let style = self.display
        guard style.isDiskRAMStack else { return }
        let disk = modules.lazy.compactMap { ($0 as? Disk)?.displayedCapacity }.first
        if let capacity = disk?.totalBytes, capacity > 0 {
            self.diskDigits = String(capacity / 1_000_000_000).count
        }
        let memory = modules.lazy.compactMap { ($0 as? RAM)?.displayedFreeBytes }.first
        let showsUnits = StatusWidgetPreferences.showsUnits
        guard let values = style.stackedReadings(
            diskFreeBytes: disk?.freeBytes, memoryFreeBytes: memory, showsUnits: showsUnits,
            diskThresholds: StatusWidgetPreferences.thresholds(for: .disk),
            memoryThresholds: StatusWidgetPreferences.thresholds(for: .memory)
        ) else { return }

        let keyboard = StatusWidgetPreferences.showsKeyboard ? self.keyboardCode() ?? "–" : nil
        var battery: StatusWidgetBatteryReading?
        if StatusWidgetPreferences.showsBattery {
            let charge = modules.lazy.compactMap { ($0 as? Battery)?.chargeStatus }.first
            battery = StatusWidgetBatteryReading(
                level: charge?.level, isDischarging: charge?.isDischarging ?? false,
                thresholds: StatusWidgetPreferences.thresholds(for: .battery), showsIcon: StatusWidgetPreferences.showsBatteryIcon,
                isOnACPower: charge?.isOnACPower ?? false
            )
        }
        if self.stacked.superview !== self.view {
            self.view.subviews.forEach { $0.removeFromSuperview() }
            self.view.addSubview(self.stacked)
        }
        self.stacked.update(
            [values.disk, values.memory], style: style, showsUnits: showsUnits,
            minimumDigits: max(3, self.diskDigits, self.memoryDigits), indicators: (keyboard, battery)
        )
        let frameSize = self.stacked.frame.size
        if self.view.frame.size != frameSize {
            self.view.setFrameSize(frameSize)
        }
        guard let item = self.menuBarItem else { return }
        if self.stackedItemWidth != frameSize.width {
            self.stackedItemWidth = frameSize.width
            item.length = frameSize.width
        }

        var description = "\(localizedString("Disk")): \(values.disk.text), \(localizedString("RAM")): \(values.memory.text)"
        if let keyboard { description += ", \(localizedString("Keyboard")): \(keyboard)" }
        if let battery { description += ", \(localizedString("Battery")): \(battery.label.text)" }
        if item.button?.toolTip != description {
            item.button?.toolTip = description
            item.button?.setAccessibilityLabel(description)
        }
    }

    private func keyboardCode() -> String? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else { return nil }
        if let property = TISGetInputSourceProperty(source, kTISPropertyLocalizedName) {
            let name = (Unmanaged<CFString>.fromOpaque(property).takeUnretainedValue() as String).lowercased()
            if name.contains("russian") || name.contains("рус") { return "RU" }
        }
        guard let property = TISGetInputSourceProperty(source, kTISPropertyInputSourceLanguages),
              let languages = Unmanaged<CFArray>.fromOpaque(property).takeUnretainedValue() as? [String],
              let language = languages.first else { return nil }
        return CompactMenuBar.keyboardCode(languageTag: language)
    }

    private func updateSummary() {
        guard self.menuBarItem != nil else { return }
        let list = self.activeModules.filter({ $0.config.hasSummary })
        
        if list.isEmpty {
            self.view.subviews.forEach({ $0.removeFromSuperview() })
            self.view.addSubview(AppIcon())
            self.view.setFrameSize(NSSize(width: AppIcon.size.width, height: self.view.frame.height))
            self.menuBarItem?.length = AppIcon.size.width
            self.menuBarItem?.button?.toolTip = localizedString("Combined modules")
            self.menuBarItem?.button?.setAccessibilityLabel(localizedString("Combined modules"))
            return
        }
        
        if self.summary.superview == nil {
            self.view.subviews.forEach({ $0.removeFromSuperview() })
            self.view.addSubview(self.summary)
        }
        
        self.summary.update(list)
        self.view.setFrameSize(self.summary.frame.size)
        self.menuBarItem?.length = self.summary.frame.width
        
        self.menuBarItem?.button?.toolTip = self.summary.toolTip
        self.menuBarItem?.button?.setAccessibilityLabel(self.summary.toolTip)
    }
    
    // call when popup appear/disappear
    private func visibilityCallback(_ state: Bool) {}
    
    @objc private func handleClick() {
        if self.display != .widgets || self.combinedModulesPopup {
            self.togglePopup()
        } else {
            self.openModulePopup()
        }
    }
    
    private func handleAlternateClick(_ event: NSEvent) -> NSEvent? {
        guard let window = self.menuBarItem?.button?.window, event.window == window,
              self.display == .widgets, self.combinedModulesAlternateDetails else { return event }
        
        let flags = CGEventSource.flagsState(.combinedSessionState)
        guard flags.isDisjoint(with: [.maskControl, .maskCommand]) else { return event }
        
        let keys = self.combinedModulesModifierKeys
        let matches = !keys.isEmpty && keys.allSatisfy { key in
            switch key {
            case 60: return flags.contains(.maskShift)
            case 58: return flags.contains(.maskAlternate)
            default: return false
            }
        }
        guard matches else { return event }
        
        if self.combinedModulesPopup {
            self.openModulePopup()
        } else {
            self.togglePopup()
        }
        return nil
    }
    
    private func openModulePopup() {
        guard let window = self.menuBarItem?.button?.window else { return }
        let location = self.view.convert(window.convertPoint(fromScreen: NSEvent.mouseLocation), from: nil)
        let visibleModules = self.activeModules.filter({ !$0.menuBar.activeWidgets.isEmpty })
        guard let module = visibleModules.last(where: { $0.menuBar.view.frame.minX <= location.x }) ?? visibleModules.first else { return }
        
        var userInfo: [String: Any] = [
            "module": module.name,
            "origin": window.frame.origin,
            "center": window.frame.width/2
        ]
        let widgetLocation = module.menuBar.view.convert(location, from: self.view)
        let widgets = module.menuBar.activeWidgets
        if let widget = widgets.last(where: { $0.item.frame.minX <= widgetLocation.x }) ?? widgets.first {
            userInfo["widget"] = widget.type
        }
        NotificationCenter.default.post(name: .togglePopup, object: nil, userInfo: userInfo)
    }
    
    private func togglePopup() {
        guard let popup = self.popup, let item = self.menuBarItem, let window = item.button?.window else { return }
        
        if popup.occlusionState.rawValue == 8192 {
            popup.contentView?.invalidateIntrinsicContentSize()
            
            let windowCenter = popup.contentView!.intrinsicContentSize.width / 2
            var x = window.frame.origin.x - windowCenter + window.frame.width/2
            let y = window.frame.origin.y - popup.contentView!.intrinsicContentSize.height - 3
            
            let buttonPoint = NSPoint(x: window.frame.midX, y: window.frame.midY)
            if let screen = NSScreen.screens.first(where: { $0.frame.contains(buttonPoint) }) ?? NSScreen.main {
                if x + popup.contentView!.intrinsicContentSize.width > screen.frame.maxX {
                    x = screen.frame.maxX - popup.contentView!.intrinsicContentSize.width - 3
                }
                if x < screen.frame.minX {
                    x = screen.frame.minX + 3
                }
            }
            
            popup.setFrameOrigin(NSPoint(x: x, y: y))
            popup.orderFrontRegardless()
            popup.makeKey()
        } else {
            popup.setIsVisible(false)
        }
    }
    
    @objc private func listenForStateChange(_ notification: Notification) {
        guard notification.userInfo?["module"] == nil else { return }
        
        if self.status {
            self.enable()
        } else {
            self.disable()
        }
    }
    
    @objc private func listenForModuleRearrrange() {
        self.recalculate()
    }
}

internal class StackedMenuBarView: NSView {
    private let font = NSFont.monospacedSystemFont(ofSize: 10, weight: .medium)
    private let inset: CGFloat = 3
    private let gap: CGFloat = 8
    private let batteryIconWidth: CGFloat = 17
    private let menuBarHeight = Constants.Widget.height
    private var readings: [CompactMenuBar.Reading] = []
    private var alignLabels = false
    private var keyboard: String?
    private var battery: StatusWidgetBatteryReading?
    private var readingsWidth: CGFloat = 0
    private var auxiliaryWidth: CGFloat = 0

    override var isFlipped: Bool { true }

    private var batteryTextWidth: CGFloat { self.text("100%").size().width }

    func update(
        _ readings: [CompactMenuBar.Reading], style: CombinedModulesWidget, showsUnits: Bool, minimumDigits: Int = 3,
        indicators: (keyboard: String?, battery: StatusWidgetBatteryReading?)
    ) {
        let (keyboard, battery) = indicators
        let alignLabels = style == .diskRAMLabels
        let templateLength = minimumDigits + (alignLabels ? 4 : 0) + (showsUnits ? 3 : 0)
        let readingsWidth = ceil(self.text(String(repeating: "0", count: templateLength)).size().width)
        let keyboardWidth = keyboard == nil ? 0 : self.text("000").size().width
        let batteryWidth = battery.map { $0.showsIcon ? self.batteryIconWidth : self.batteryTextWidth } ?? 0
        let auxiliaryWidth = ceil(max(keyboardWidth, batteryWidth))
        let auxiliarySpace = auxiliaryWidth > 0 ? self.gap + auxiliaryWidth : 0
        let size = NSSize(width: readingsWidth + auxiliarySpace + 2 * self.inset, height: self.menuBarHeight)

        guard self.readings != readings || self.alignLabels != alignLabels || self.keyboard != keyboard || self.battery != battery
                || self.readingsWidth != readingsWidth || self.auxiliaryWidth != auxiliaryWidth || self.frame.size != size else { return }
        self.readings = readings
        self.alignLabels = alignLabels
        self.keyboard = keyboard
        self.battery = battery
        self.readingsWidth = readingsWidth
        self.auxiliaryWidth = auxiliaryWidth
        if self.frame.size != size { self.setFrameSize(size) }
        self.needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let height = self.bounds.height / 2
        for (row, reading) in self.readings.enumerated() {
            let rect = NSRect(x: self.inset, y: CGFloat(row) * height, width: self.readingsWidth, height: height)
            self.draw(self.text(reading.text, color: reading.tone.color(dark: self.isDarkMode)), in: rect, alignment: self.alignLabels ? .left : .right)
        }
        let x = self.inset + self.readingsWidth + self.gap
        if let keyboard = self.keyboard {
            self.draw(self.text(keyboard), in: NSRect(x: x, y: 0, width: self.auxiliaryWidth, height: height), alignment: .center)
        }
        if let battery = self.battery {
            self.drawBattery(battery, in: NSRect(x: x, y: height, width: self.auxiliaryWidth, height: height))
        }
    }

    private func drawBattery(_ battery: StatusWidgetBatteryReading, in rect: NSRect) {
        let color = battery.label.tone.color(dark: self.isDarkMode)
        guard battery.showsIcon else {
            self.draw(self.text(battery.label.text, color: color), in: rect, alignment: .center)
            return
        }
        if battery.showsPowerPlug && self.drawPowerPlug(in: rect, color: color) { return }

        let left = (rect.midX - self.batteryIconWidth / 2).rounded()
        let y = (rect.midY - 4).rounded()
        let body = NSRect(x: left + 0.5, y: y + 0.5, width: 14, height: 7)
        let outline = NSBezierPath(roundedRect: body, xRadius: 2, yRadius: 2)
        outline.lineWidth = 1
        color.setStroke()
        outline.stroke()

        color.setFill()
        NSBezierPath(roundedRect: NSRect(x: left + 15.5, y: y + 2.5, width: 1.5, height: 3), xRadius: 0.5, yRadius: 0.5).fill()
        if let level = battery.level, level > 0 {
            var fill = body.insetBy(dx: 2, dy: 2)
            fill.size.width *= CGFloat(level)
            NSBezierPath(roundedRect: fill, xRadius: min(1, fill.width / 2), yRadius: 1).fill()
        }
    }

    private func drawPowerPlug(in rect: NSRect, color: NSColor) -> Bool {
        let configuration = NSImage.SymbolConfiguration(pointSize: 10, weight: .medium)
            .applying(NSImage.SymbolConfiguration(paletteColors: [color]))
        guard let image = NSImage(systemSymbolName: "powerplug.fill", accessibilityDescription: nil)?.withSymbolConfiguration(configuration),
              image.size.width > 0, image.size.height > 0 else { return false }
        image.isTemplate = false
        let scale = min(1, self.batteryIconWidth / image.size.width, rect.height / image.size.height)
        let size = NSSize(width: image.size.width * scale, height: image.size.height * scale)
        let target = NSRect(x: (rect.midX - size.width / 2).rounded(), y: (rect.midY - size.height / 2).rounded(), width: size.width, height: size.height)
        image.draw(in: target, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
        return true
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        self.needsDisplay = true
    }

    private func text(_ value: String, color: NSColor = .textColor) -> NSAttributedString {
        NSAttributedString(string: value, attributes: [.font: self.font, .foregroundColor: color])
    }

    private func draw(_ text: NSAttributedString, in rect: NSRect, alignment: NSTextAlignment) {
        let size = text.size()
        let x: CGFloat
        switch alignment {
        case .left: x = rect.minX
        case .right: x = rect.maxX - size.width
        default: x = rect.midX - size.width / 2
        }
        text.draw(at: NSPoint(x: x.rounded(), y: (rect.midY - size.height / 2).rounded()))
    }
}

private class CombinedSummaryWidget: NSView {
    private var values: [(ModuleType, Double?)] = []
    
    private var color: NSColor { self.isDarkMode ? .white : .black }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        switch CombinedModulesWidget.current {
        case .rings: self.drawRings()
        case .dial: self.drawDial()
        default: self.drawBars()
        }
    }
    
    private func color(for value: Double?, moduleType: ModuleType) -> NSColor {
        guard let value else { return self.color }
        return (moduleType == .battery ? value < 0.1 : value > 0.9) ? .systemRed : self.color
    }
    
    private func drawBars() {
        let height: CGFloat = min(16, self.bounds.height - 4)
        let width = CGFloat(self.values.count) * 6 - 2
        let origin = ((self.bounds.width - width) / 2).rounded()
        let y = ((self.bounds.height - height) / 2).rounded()
        
        for (i, (module, value)) in self.values.enumerated() {
            let color = self.color(for: value, moduleType: module)
            let rect = NSRect(x: origin + CGFloat(i) * 6, y: y, width: 4, height: height)
            let track = NSBezierPath(roundedRect: rect, xRadius: 1, yRadius: 1)
            color.withAlphaComponent(0.25).setFill()
            track.fill()
            
            if let value, value > 0 {
                let fill = NSRect(x: rect.minX, y: rect.minY, width: rect.width, height: height * CGFloat(value))
                NSGraphicsContext.saveGraphicsState()
                track.addClip()
                color.setFill()
                NSBezierPath(rect: fill).fill()
                NSGraphicsContext.restoreGraphicsState()
            }
        }
    }
    
    private func drawRings() {
        guard !self.values.isEmpty else { return }
        let diameter = min(20, self.bounds.height - 2)
        let spacing = min(3, diameter / (CGFloat(self.values.count) * 2))
        let lineWidth = spacing - 0.5
        let center = NSPoint(x: self.bounds.midX, y: self.bounds.midY)
        
        for (i, (module, value)) in self.values.enumerated() {
            let color = self.color(for: value, moduleType: module)
            let radius = (diameter - lineWidth) / 2 - CGFloat(i) * spacing
            let track = NSBezierPath(ovalIn: NSRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
            track.lineWidth = lineWidth
            color.withAlphaComponent(0.25).setStroke()
            track.stroke()
            
            if let value, value > 0 {
                color.setStroke()
                if value == 1 {
                    track.stroke()
                } else {
                    let fill = NSBezierPath()
                    fill.lineWidth = lineWidth
                    fill.lineCapStyle = .round
                    fill.appendArc(withCenter: center, radius: radius, startAngle: 90, endAngle: 90 - CGFloat(value) * 360, clockwise: true)
                    fill.stroke()
                }
            }
        }
    }
    
    private func drawDial() {
        guard !self.values.isEmpty else { return }
        let lineWidth: CGFloat = 2.5
        let radius = (min(20, self.bounds.height - 2) - lineWidth) / 2
        let center = NSPoint(x: self.bounds.midX, y: self.bounds.midY)
        let segment = 360 / CGFloat(self.values.count)
        let gap: CGFloat = self.values.count > 1 ? 32 : 0
        
        for (i, (module, value)) in self.values.enumerated() {
            let color = self.color(for: value, moduleType: module)
            let start = 90 - CGFloat(i) * segment - gap / 2
            let length = segment - gap
            let track = NSBezierPath()
            track.lineWidth = lineWidth
            track.lineCapStyle = .round
            track.appendArc(withCenter: center, radius: radius, startAngle: start, endAngle: start - length, clockwise: true)
            color.withAlphaComponent(0.25).setStroke()
            track.stroke()
            
            if let value, value > 0 {
                let fill = NSBezierPath()
                fill.lineWidth = lineWidth
                fill.lineCapStyle = .round
                fill.appendArc(withCenter: center, radius: radius, startAngle: start, endAngle: start - length * CGFloat(value), clockwise: true)
                color.setStroke()
                fill.stroke()
            }
        }
    }
    
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        self.needsDisplay = true
    }
    
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
    
    fileprivate func setValue(for module: ModuleType, with value: Double?) {
        let value = value.flatMap({ $0.isFinite ? min(max($0, 0), 1) : nil })
        if let index = self.values.firstIndex(where: { $0.0 == module }) {
            self.values[index].1 = value
        } else {
            self.values.append((module, value))
        }
    }
    
    fileprivate func update(_ list: [Module]) {
        self.values = list.map { module in
            (module.moduleType, self.values.first(where: { $0.0 == module.moduleType })?.1)
        }
        let width: CGFloat = CombinedModulesWidget.current == .bars ? max(22, CGFloat(self.values.count) * 6 + 2) : 22
        self.setFrameSize(NSSize(width: width, height: Constants.Widget.height))
        self.toolTip = list.map { module in
            let value = self.values.first(where: { $0.0 == module.moduleType })?.1.map({ "\(Int($0 * 100))%" }) ?? localizedString("Unknown")
            return "\(localizedString(module.name)): \(value)"
        }.joined(separator: "\n")
        self.needsDisplay = true
    }
}

private class SeparatorLineView: NSView {
    override var wantsUpdateLayer: Bool { true }
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        self.wantsLayer = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateLayer() {
        self.layer?.backgroundColor = (self.isDarkMode ? NSColor.white : NSColor.black).cgColor
    }
    
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        self.needsDisplay = true
    }
}

private class Popup: NSStackView, Popup_p {
    fileprivate var keyboardShortcut: [UInt16] = []
    fileprivate var sizeCallback: ((NSSize) -> Void)? = nil
    
    init() {
        self.keyboardShortcut = Store.shared.array(key: "CombinedModules_popup_keyboardShortcut", defaultValue: []) as? [UInt16] ?? []
        
        super.init(frame: NSRect(x: 0, y: 0, width: Constants.Popup.width, height: 0))
        
        self.orientation = .vertical
        self.distribution = .fill
        self.alignment = .width
        self.spacing = Constants.Popup.spacing*3
        
        self.reinit()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reinit), name: .toggleModule, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .toggleOneView, object: nil)
    }
    
    fileprivate func settings() -> NSView? { return nil }
    fileprivate func appear() {}
    fileprivate func disappear() {}
    fileprivate func setKeyboardShortcut(_ binding: [UInt16]) {
        self.keyboardShortcut = binding
        Store.shared.set(key: "CombinedModules_popup_keyboardShortcut", value: binding)
    }
    
    @objc private func reinit() {
        self.subviews.forEach({ $0.removeFromSuperview() })
        
        let availableModules = modules.filter({ $0.enabled && $0.portal != nil })
        var modulesHeight: CGFloat = 0
        availableModules.forEach { (m: Module) in
            if let p = m.portal {
                modulesHeight += p.height
                self.addArrangedSubview(p)
                p.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
            }
        }
        
        let h = modulesHeight + (CGFloat(availableModules.count-1)*self.spacing)
        if h > 0 {
            self.setFrameSize(NSSize(width: self.frame.width, height: h))
            self.sizeCallback?(self.frame.size)
        }
    }
}
