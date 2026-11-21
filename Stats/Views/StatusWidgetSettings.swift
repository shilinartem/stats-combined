import Cocoa
import Kit

final class StatusWidgetSettings: NSStackView, NSTextFieldDelegate {
    static let title = "Status Widget"

    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: Constants.Settings.width, height: Constants.Settings.height))
        self.translatesAutoresizingMaskIntoConstraints = false
        self.orientation = .vertical

        let scroll = ScrollableStackView(orientation: .vertical)
        scroll.stackView.edgeInsets = NSEdgeInsets(top: 0, left: 10, bottom: 10, right: 10)
        scroll.stackView.spacing = Constants.Settings.margin
        scroll.stackView.addArrangedSubview(PreferencesSection([
            PreferencesRow("Show in menu bar", component: self.switchView(action: #selector(changeEnabled), state: StatusWidgetPreferences.enabled))
        ]))
        for cells in [[StatusWidgetCell.disk, .keyboard], [.memory, .battery]] {
            let row = NSStackView(views: cells.map(self.card))
            row.orientation = .horizontal
            row.distribution = .fillEqually
            row.alignment = .top
            row.spacing = Constants.Settings.margin
            scroll.stackView.addArrangedSubview(row)
        }
        self.addArrangedSubview(scroll)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func card(_ cell: StatusWidgetCell) -> NSView {
        let visible = self.switchView(action: #selector(changeCellVisibility), state: StatusWidgetPreferences.isVisible(cell))
        visible.identifier = NSUserInterfaceItemIdentifier(cell.rawValue)
        visible.setAccessibilityLabel("Show \(cell.title)")
        let format = NSTextField(string: StatusWidgetPreferences.format(for: cell))
        format.identifier = NSUserInterfaceItemIdentifier("\(cell.rawValue).format")
        format.setAccessibilityLabel("\(cell.title) format")
        format.usesSingleLineMode = true
        format.widthAnchor.constraint(greaterThanOrEqualToConstant: 112).isActive = true
        format.delegate = self

        var rows: [NSView] = [
            PreferencesRow("Show", component: visible),
            PreferencesRow("Format", component: format, help: { showAlert("\(cell.title) format", Self.formatHelp(for: cell)) })
        ]
        switch cell {
        case .disk, .memory:
            let units = self.switchView(action: #selector(changeUnits), state: StatusWidgetPreferences.showsUnits(for: cell))
            units.identifier = NSUserInterfaceItemIdentifier(cell.rawValue)
            units.setAccessibilityLabel("Show GB for \(cell.title)")
            rows.append(PreferencesRow("Show GB", component: units))
        case .battery:
            rows.append(PreferencesRow("Battery icon", component: self.switchView(
                action: #selector(changeBatteryIcon), state: StatusWidgetPreferences.showsBatteryIcon
            )))
        case .keyboard:
            break
        }
        if let metric = cell.metric {
            rows.append(self.thresholdRow(for: cell, metric: metric))
        }
        return PreferencesSection(title: cell.title, rows)
    }

    private static func formatHelp(for cell: StatusWidgetCell) -> String {
        switch cell {
        case .disk: return "Use $capacity.free for free space, or $capacity.free[.0] for one decimal. $unit shows GB when Show GB is on."
        case .memory: return "Use $mem.free for free memory, or $mem.free[.0] for one decimal. $unit shows GB when Show GB is on."
        case .keyboard: return "Use $layout for the current keyboard code. For example, [$layout] shows [EN]."
        case .battery: return "With Battery icon off, use $battery.level for 42% or $battery.percent for 42."
        }
    }

    private func thresholdRow(for cell: StatusWidgetCell, metric: StatusWidgetMetric) -> NSView {
        let values = StatusWidgetPreferences.thresholds(for: metric)
        let fields = NSStackView(views: [
            self.thresholdField(values.warning, for: cell, name: "warning"),
            self.thresholdField(values.critical, for: cell, name: "critical")
        ])
        fields.orientation = .horizontal
        fields.spacing = 6
        let unit = metric == .battery ? "%" : "GB"
        return PreferencesRow("Warning / critical", unit, component: fields)
    }

    private func thresholdField(_ value: Int, for cell: StatusWidgetCell, name: String) -> NSTextField {
        let field = NSTextField(string: "\(value)")
        field.identifier = NSUserInterfaceItemIdentifier("\(cell.rawValue).\(name)")
        field.setAccessibilityLabel("\(cell.title) \(name) threshold")
        field.alignment = .right
        field.usesSingleLineMode = true
        field.widthAnchor.constraint(equalToConstant: 40).isActive = true
        field.delegate = self
        return field
    }

    func controlTextDidEndEditing(_ notification: Notification) {
        guard let field = notification.object as? NSTextField,
              let parts = field.identifier?.rawValue.split(separator: "."), parts.count == 2,
              let cell = StatusWidgetCell(rawValue: String(parts[0])) else { return }
        if parts[1] == "format" {
            let value = field.stringValue.isEmpty ? cell.defaultFormat(for: StatusWidgetPreferences.layout) : field.stringValue
            field.stringValue = value
            StatusWidgetPreferences.setFormat(value, for: cell)
        } else if let metric = cell.metric {
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
        }
        self.refresh()
    }

    @objc private func changeEnabled(_ sender: NSSwitch) {
        StatusWidgetPreferences.enabled = sender.state == .on
        NotificationCenter.default.post(name: .toggleOneView, object: nil)
        self.refresh()
    }

    @objc private func changeCellVisibility(_ sender: NSSwitch) {
        guard let id = sender.identifier?.rawValue, let cell = StatusWidgetCell(rawValue: id) else { return }
        StatusWidgetPreferences.setVisible(sender.state == .on, for: cell)
        self.refresh()
    }

    @objc private func changeUnits(_ sender: NSSwitch) {
        guard let id = sender.identifier?.rawValue, let cell = StatusWidgetCell(rawValue: id) else { return }
        StatusWidgetPreferences.setShowsUnits(sender.state == .on, for: cell)
        self.refresh()
    }

    @objc private func changeBatteryIcon(_ sender: NSSwitch) {
        StatusWidgetPreferences.showsBatteryIcon = sender.state == .on
        self.refresh()
    }

    private func refresh() {
        NotificationCenter.default.post(name: .moduleRearrange, object: nil)
    }
}
