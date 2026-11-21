import Cocoa
import Kit

final class StatusWidgetSettings: NSStackView, NSTextFieldDelegate {
    static let title = "Status Widget"
    private var format: NSPopUpButton?
    private var units: NSSwitch?
    private var batteryIcon: NSSwitch?

    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: Constants.Settings.width, height: Constants.Settings.height))
        self.translatesAutoresizingMaskIntoConstraints = false
        self.orientation = .vertical

        let scroll = ScrollableStackView(orientation: .vertical)
        scroll.stackView.edgeInsets = NSEdgeInsets(top: 0, left: 10, bottom: 10, right: 10)
        scroll.stackView.spacing = Constants.Settings.margin

        let format = self.selectView(action: #selector(changeFormat), items: StatusWidgetPreferences.layouts, selected: StatusWidgetPreferences.layout.rawValue)
        let units = self.switchView(action: #selector(changeUnits), state: StatusWidgetPreferences.showsUnits)
        self.format = format
        self.units = units
        let batteryIcon = self.switchView(action: #selector(changeBatteryIcon), state: StatusWidgetPreferences.showsBatteryIcon)
        batteryIcon.isEnabled = StatusWidgetPreferences.showsBattery
        self.batteryIcon = batteryIcon
        scroll.stackView.addArrangedSubview(PreferencesSection(title: "Display", [
            PreferencesRow("Show in menu bar", component: self.switchView(action: #selector(changeEnabled), state: StatusWidgetPreferences.enabled)),
            PreferencesRow("Format", component: format),
            PreferencesRow("Show GB", component: units),
            PreferencesRow("Current keyboard layout", component: self.switchView(action: #selector(changeKeyboard), state: StatusWidgetPreferences.showsKeyboard)),
            PreferencesRow("Show battery", component: self.switchView(action: #selector(changeBattery), state: StatusWidgetPreferences.showsBattery)),
            PreferencesRow("Battery icon", component: batteryIcon)
        ]))
        scroll.stackView.addArrangedSubview(self.thresholdSection("Disk (GB)", metric: .disk, warning: "Yellow below", critical: "Red below"))
        scroll.stackView.addArrangedSubview(self.thresholdSection("RAM (GiB)", metric: .memory, warning: "Orange at or below", critical: "Red at or below"))
        scroll.stackView.addArrangedSubview(self.thresholdSection("Battery (%)", metric: .battery, warning: "Yellow at or below", critical: "Red at or below"))
        self.addArrangedSubview(scroll)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func thresholdSection(_ title: String, metric: StatusWidgetMetric, warning: String, critical: String) -> NSView {
        let values = StatusWidgetPreferences.thresholds(for: metric)
        let warningField = self.thresholdField(values.warning, metric: metric, name: "warning", label: "\(title) warning threshold")
        let criticalField = self.thresholdField(values.critical, metric: metric, name: "critical", label: "\(title) critical threshold")
        let subtitle = metric == .battery ? "On battery power" : ""
        return PreferencesSection(title: title, subtitle: subtitle, [PreferencesRow(warning, component: warningField), PreferencesRow(critical, component: criticalField)])
    }

    private func thresholdField(_ value: Int, metric: StatusWidgetMetric, name: String, label: String) -> NSTextField {
        let field = NSTextField(string: "\(value)")
        field.identifier = NSUserInterfaceItemIdentifier("\(metric.rawValue).\(name)")
        field.setAccessibilityLabel(label)
        field.alignment = .right
        field.usesSingleLineMode = true
        field.widthAnchor.constraint(equalToConstant: 64).isActive = true
        field.delegate = self
        return field
    }

    func controlTextDidEndEditing(_ notification: Notification) {
        guard let field = notification.object as? NSTextField,
              let parts = field.identifier?.rawValue.split(separator: "."), parts.count == 2,
              let metric = StatusWidgetMetric(rawValue: String(parts[0])) else { return }

        let values = StatusWidgetPreferences.thresholds(for: metric)
        let isWarning = parts[1] == "warning"
        let previous = isWarning ? values.warning : values.critical
        let requested = Int(field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)) ?? previous
        let value = min(metric == .battery ? 100 : 1_000_000, max(0, requested))
        let updated = isWarning
            ? StatusWidgetThresholds(warning: max(values.critical, value), critical: values.critical)
            : StatusWidgetThresholds(warning: values.warning, critical: value)
        field.stringValue = "\(isWarning ? updated.warning : updated.critical)"
        StatusWidgetPreferences.setThresholds(updated, for: metric)
        self.refresh()
    }

    @objc private func changeEnabled(_ sender: NSSwitch) {
        StatusWidgetPreferences.enabled = sender.state == .on
        self.refresh(regroup: true)
    }

    @objc private func changeFormat(_ sender: NSMenuItem) {
        guard let key = sender.representedObject as? String, let layout = CombinedModulesWidget(rawValue: key), layout.isDiskRAMStack else { return }
        StatusWidgetPreferences.layout = layout
        StatusWidgetPreferences.showsUnits = layout != .diskRAMNumbers
        self.units?.state = StatusWidgetPreferences.showsUnits ? .on : .off
        self.refresh()
    }

    @objc private func changeUnits(_ sender: NSSwitch) {
        let showsUnits = sender.state == .on
        StatusWidgetPreferences.showsUnits = showsUnits
        if StatusWidgetPreferences.layout != .diskRAMLabels {
            StatusWidgetPreferences.layout = showsUnits ? .diskRAMUnits : .diskRAMNumbers
            if let index = self.format?.itemArray.firstIndex(where: { ($0.representedObject as? String) == StatusWidgetPreferences.layout.rawValue }) {
                self.format?.selectItem(at: index)
            }
        }
        self.refresh()
    }

    @objc private func changeKeyboard(_ sender: NSSwitch) {
        StatusWidgetPreferences.showsKeyboard = sender.state == .on
        self.refresh()
    }

    @objc private func changeBattery(_ sender: NSSwitch) {
        StatusWidgetPreferences.showsBattery = sender.state == .on
        self.batteryIcon?.isEnabled = StatusWidgetPreferences.showsBattery
        self.refresh(regroup: true)
    }

    @objc private func changeBatteryIcon(_ sender: NSSwitch) {
        StatusWidgetPreferences.showsBatteryIcon = sender.state == .on
        self.refresh()
    }

    private func refresh(regroup: Bool = false) {
        if regroup {
            NotificationCenter.default.post(name: .toggleOneView, object: nil)
        }
        NotificationCenter.default.post(name: .moduleRearrange, object: nil)
    }
}
