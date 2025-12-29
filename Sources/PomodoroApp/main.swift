import AppKit
import Carbon.HIToolbox

// MARK: - Notifications
extension Notification.Name {
    static let timerDidUpdate = Notification.Name("timerDidUpdate")
    static let sessionDidComplete = Notification.Name("sessionDidComplete")
    static let dailyGoalReached = Notification.Name("dailyGoalReached")
    static let languageDidChange = Notification.Name("languageDidChange")
}

// MARK: - Timer State
enum TimerState {
    case idle
    case running
    case paused
}

enum SessionType {
    case work
    case shortBreak
    case longBreak
    
    var localizedName: String {
        let L = LocalizationManager.shared
        switch self {
        case .work: return L.get("focus")
        case .shortBreak: return L.get("shortBreak")
        case .longBreak: return L.get("longBreak")
        }
    }
}

// MARK: - Localization Manager
class LocalizationManager {
    static let shared = LocalizationManager()
    
    private let defaults = UserDefaults.standard
    private let languageKey = "appLanguage"
    
    enum Language: String, CaseIterable {
        case french = "fr"
        case english = "en"
        
        var displayName: String {
            switch self {
            case .french: return "Français"
            case .english: return "English"
            }
        }
    }
    
    var currentLanguage: Language {
        get {
            let code = defaults.string(forKey: languageKey) ?? "fr"
            return Language(rawValue: code) ?? .french
        }
        set {
            defaults.set(newValue.rawValue, forKey: languageKey)
            NotificationCenter.default.post(name: .languageDidChange, object: nil)
        }
    }
    
    private let translations: [String: [Language: String]] = [
        // Session types
        "focus": [.french: "Focus", .english: "Focus"],
        "shortBreak": [.french: "Pause", .english: "Break"],
        "longBreak": [.french: "Pause longue", .english: "Long Break"],
        
        // Buttons
        "start": [.french: "Start", .english: "Start"],
        "pause": [.french: "Pause", .english: "Pause"],
        "resume": [.french: "Resume", .english: "Resume"],
        "reset": [.french: "Reset", .english: "Reset"],
        "skip": [.french: "Skip", .english: "Skip"],
        "quit": [.french: "Quitter", .english: "Quit"],
        "back": [.french: "← Retour", .english: "← Back"],
        
        // Settings
        "settings": [.french: "Paramètres", .english: "Settings"],
        "focusDuration": [.french: "Focus", .english: "Focus"],
        "shortBreakDuration": [.french: "Pause courte", .english: "Short Break"],
        "longBreakDuration": [.french: "Pause longue", .english: "Long Break"],
        "sessionsBeforeLong": [.french: "Sessions avant pause longue", .english: "Sessions before long break"],
        "dailyGoal": [.french: "Objectif journalier", .english: "Daily Goal"],
        "language": [.french: "Langue", .english: "Language"],
        "shortcut": [.french: "Raccourci: ⌘⇧P (Start/Pause)", .english: "Shortcut: ⌘⇧P (Start/Pause)"],
        
        // Tasks
        "tasks": [.french: "Tâches", .english: "Tasks"],
        "newTask": [.french: "Nouvelle tâche...", .english: "New task..."],
        "clearCompleted": [.french: "Effacer terminées", .english: "Clear completed"],
        
        // Goal messages
        "goalReached": [.french: "🎉 Objectif atteint!", .english: "🎉 Goal reached!"],
        "sessions": [.french: "sessions", .english: "sessions"],
        "remainingGoal": [.french: "Encore %d pour atteindre ton objectif", .english: "%d more to reach your goal"],
        "exceededGoal": [.french: "Tu as dépassé ton objectif! 💪", .english: "You exceeded your goal! 💪"],
        "resetDay": [.french: "Réinitialiser la journée", .english: "Reset day"],
        
        // Notifications
        "sessionComplete": [.french: "✅ Session terminée!", .english: "✅ Session complete!"],
        "letsGo": [.french: "💪 C'est reparti!", .english: "💪 Let's go!"],
        "goalReachedTitle": [.french: "🎉 Objectif atteint!", .english: "🎉 Goal reached!"],
        "goalReachedMessage": [.french: "Félicitations! Tu as atteint ton objectif du jour!\nContinue comme ça 💪", .english: "Congratulations! You reached your daily goal!\nKeep it up 💪"],
        "great": [.french: "Super!", .english: "Great!"],
    ]
    
    func get(_ key: String) -> String {
        return translations[key]?[currentLanguage] ?? key
    }
    
    func get(_ key: String, _ args: CVarArg...) -> String {
        let format = translations[key]?[currentLanguage] ?? key
        return String(format: format, arguments: args)
    }
}

// MARK: - Settings Manager
class SettingsManager {
    static let shared = SettingsManager()
    
    private let defaults = UserDefaults.standard
    
    private let workDurationKey = "workDuration"
    private let shortBreakKey = "shortBreakDuration"
    private let longBreakKey = "longBreakDuration"
    private let sessionsKey = "sessionsUntilLongBreak"
    private let dailyGoalKey = "dailyGoal"
    private let completedTodayKey = "completedToday"
    private let lastDateKey = "lastDate"
    
    var workDuration: Int {
        get { defaults.integer(forKey: workDurationKey) != 0 ? defaults.integer(forKey: workDurationKey) : 25 }
        set { defaults.set(newValue, forKey: workDurationKey) }
    }
    
    var shortBreakDuration: Int {
        get { defaults.integer(forKey: shortBreakKey) != 0 ? defaults.integer(forKey: shortBreakKey) : 5 }
        set { defaults.set(newValue, forKey: shortBreakKey) }
    }
    
    var longBreakDuration: Int {
        get { defaults.integer(forKey: longBreakKey) != 0 ? defaults.integer(forKey: longBreakKey) : 15 }
        set { defaults.set(newValue, forKey: longBreakKey) }
    }
    
    var sessionsUntilLongBreak: Int {
        get { defaults.integer(forKey: sessionsKey) != 0 ? defaults.integer(forKey: sessionsKey) : 4 }
        set { defaults.set(newValue, forKey: sessionsKey) }
    }
    
    var dailyGoal: Int {
        get { defaults.integer(forKey: dailyGoalKey) != 0 ? defaults.integer(forKey: dailyGoalKey) : 8 }
        set { defaults.set(newValue, forKey: dailyGoalKey) }
    }
    
    var completedToday: Int {
        get {
            checkAndResetIfNewDay()
            return defaults.integer(forKey: completedTodayKey)
        }
        set {
            defaults.set(newValue, forKey: completedTodayKey)
            defaults.set(todayString, forKey: lastDateKey)
        }
    }
    
    private var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private func checkAndResetIfNewDay() {
        let lastDate = defaults.string(forKey: lastDateKey) ?? ""
        if lastDate != todayString {
            defaults.set(0, forKey: completedTodayKey)
            defaults.set(todayString, forKey: lastDateKey)
        }
    }
}

// MARK: - Task Manager
class TaskManager {
    static let shared = TaskManager()
    
    private let defaults = UserDefaults.standard
    private let tasksKey = "tasks"
    
    var tasks: [(text: String, done: Bool)] {
        get {
            guard let data = defaults.array(forKey: tasksKey) as? [[String: Any]] else { return [] }
            return data.compactMap { dict in
                guard let text = dict["text"] as? String, let done = dict["done"] as? Bool else { return nil }
                return (text, done)
            }
        }
        set {
            let data = newValue.map { ["text": $0.text, "done": $0.done] as [String: Any] }
            defaults.set(data, forKey: tasksKey)
        }
    }
    
    func addTask(_ text: String) {
        var current = tasks
        current.append((text, false))
        tasks = current
    }
    
    func toggleTask(at index: Int) {
        var current = tasks
        if index < current.count {
            current[index].done.toggle()
            tasks = current
        }
    }
    
    func deleteTask(at index: Int) {
        var current = tasks
        if index < current.count {
            current.remove(at: index)
            tasks = current
        }
    }
    
    func clearCompleted() {
        tasks = tasks.filter { !$0.done }
    }
}

// MARK: - Global Hotkey Manager
class HotkeyManager {
    static let shared = HotkeyManager()
    
    private var eventHandler: EventHandlerRef?
    var onHotkey: (() -> Void)?
    
    func register() {
        var hotKeyRef: EventHotKeyRef?
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x504F4D4F) // "POMO"
        hotKeyID.id = 1
        
        // ⌘⇧P (Command + Shift + P)
        let modifiers: UInt32 = UInt32(cmdKey | shiftKey)
        let keyCode: UInt32 = 35 // P key
        
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        let handler: EventHandlerUPP = { _, event, _ -> OSStatus in
            HotkeyManager.shared.onHotkey?()
            return noErr
        }
        
        InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, nil, &eventHandler)
    }
}

// MARK: - Pomodoro Timer
class PomodoroTimer: NSObject {
    static let shared = PomodoroTimer()
    
    private let settings = SettingsManager.shared
    
    // State
    private(set) var state: TimerState = .idle
    private(set) var sessionType: SessionType = .work
    private(set) var timeRemaining: Int = 25 * 60
    private(set) var completedSessions: Int = 0
    
    private var timer: Timer?
    
    override init() {
        super.init()
        timeRemaining = settings.workDuration * 60
        completedSessions = settings.completedToday
    }
    
    func toggleStartPause() {
        if state == .running {
            pause()
        } else {
            start()
        }
    }
    
    func start() {
        guard state != .running else { return }
        state = .running
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        notifyUpdate()
    }
    
    func pause() {
        guard state == .running else { return }
        state = .paused
        timer?.invalidate()
        timer = nil
        notifyUpdate()
    }
    
    func reset() {
        timer?.invalidate()
        timer = nil
        state = .idle
        timeRemaining = currentSessionDuration
        notifyUpdate()
    }
    
    func skip() {
        timer?.invalidate()
        timer = nil
        completeSession()
    }
    
    func resetDay() {
        completedSessions = 0
        settings.completedToday = 0
        notifyUpdate()
    }
    
    func applySettings() {
        if state == .idle {
            timeRemaining = currentSessionDuration
            notifyUpdate()
        }
    }
    
    func setProgress(_ progress: Double) {
        // progress: 0.0 = début, 1.0 = fin
        let clampedProgress = max(0.0, min(1.0, progress))
        timeRemaining = Int(Double(currentSessionDuration) * (1.0 - clampedProgress))
        if timeRemaining <= 0 {
            timeRemaining = 1
        }
        notifyUpdate()
    }
    
    private func notifyUpdate() {
        NotificationCenter.default.post(name: .timerDidUpdate, object: nil)
    }
    
    private func tick() {
        timeRemaining -= 1
        if timeRemaining <= 0 {
            completeSession()
        }
        notifyUpdate()
    }
    
    private func completeSession() {
        timer?.invalidate()
        timer = nil
        
        let completedType = sessionType
        
        if sessionType == .work {
            completedSessions += 1
            settings.completedToday = completedSessions
            
            // Check if daily goal reached
            if completedSessions == settings.dailyGoal {
                NotificationCenter.default.post(name: .dailyGoalReached, object: nil)
            }
            
            if completedSessions % settings.sessionsUntilLongBreak == 0 {
                sessionType = .longBreak
            } else {
                sessionType = .shortBreak
            }
        } else {
            sessionType = .work
        }
        
        timeRemaining = currentSessionDuration
        state = .idle
        
        NotificationCenter.default.post(name: .sessionDidComplete, object: completedType)
        notifyUpdate()
    }
    
    var currentSessionDuration: Int {
        switch sessionType {
        case .work: return settings.workDuration * 60
        case .shortBreak: return settings.shortBreakDuration * 60
        case .longBreak: return settings.longBreakDuration * 60
        }
    }
    
    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var progress: Double {
        return 1.0 - (Double(timeRemaining) / Double(currentSessionDuration))
    }
}

// MARK: - Interactive Progress Bar
class InteractiveProgressBar: NSView {
    var progress: Double = 0.0 {
        didSet {
            needsDisplay = true
        }
    }
    
    var progressColor: NSColor = NSColor(red: 0.92, green: 0.34, blue: 0.34, alpha: 1.0)
    var onProgressChanged: ((Double) -> Void)?
    
    private var isDragging = false
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let bounds = self.bounds
        
        // Background track
        let trackPath = NSBezierPath(roundedRect: bounds, xRadius: bounds.height / 2, yRadius: bounds.height / 2)
        NSColor.systemGray.withAlphaComponent(0.3).setFill()
        trackPath.fill()
        
        // Progress fill
        if progress > 0 {
            let progressWidth = bounds.width * CGFloat(progress)
            let progressRect = NSRect(x: 0, y: 0, width: progressWidth, height: bounds.height)
            let progressPath = NSBezierPath(roundedRect: progressRect, xRadius: bounds.height / 2, yRadius: bounds.height / 2)
            progressColor.setFill()
            progressPath.fill()
        }
        
        // Handle indicator
        let handleX = bounds.width * CGFloat(progress)
        let handleSize: CGFloat = bounds.height + 8
        let handleRect = NSRect(
            x: handleX - handleSize / 2,
            y: (bounds.height - handleSize) / 2,
            width: handleSize,
            height: handleSize
        )
        
        // Handle shadow
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
        shadow.shadowOffset = NSSize(width: 0, height: -1)
        shadow.shadowBlurRadius = 2
        shadow.set()
        
        // Handle circle
        let handlePath = NSBezierPath(ovalIn: handleRect)
        NSColor.white.setFill()
        handlePath.fill()
        progressColor.setStroke()
        handlePath.lineWidth = 2
        handlePath.stroke()
    }
    
    override func mouseDown(with event: NSEvent) {
        isDragging = true
        updateProgress(with: event)
    }
    
    override func mouseDragged(with event: NSEvent) {
        if isDragging {
            updateProgress(with: event)
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        isDragging = false
    }
    
    private func updateProgress(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        let newProgress = Double(location.x / bounds.width)
        let clampedProgress = max(0.0, min(1.0, newProgress))
        progress = clampedProgress
        onProgressChanged?(clampedProgress)
    }
    
    // Change cursor on hover
    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }
}

// MARK: - Settings View Controller
class SettingsViewController: NSViewController {
    private let settings = SettingsManager.shared
    private let timer = PomodoroTimer.shared
    private let L = LocalizationManager.shared
    
    private var workStepper: NSStepper!
    private var workLabel: NSTextField!
    private var shortBreakStepper: NSStepper!
    private var shortBreakLabel: NSTextField!
    private var longBreakStepper: NSStepper!
    private var longBreakLabel: NSTextField!
    private var sessionsStepper: NSStepper!
    private var sessionsLabel: NSTextField!
    private var goalStepper: NSStepper!
    private var goalLabel: NSTextField!
    private var languagePopup: NSPopUpButton!
    
    var onClose: (() -> Void)?
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 280, height: 360))
        view.wantsLayer = true
        setupUI()
    }
    
    private func setupUI() {
        // Title
        let title = NSTextField(labelWithString: L.get("settings"))
        title.font = NSFont.systemFont(ofSize: 18, weight: .semibold)
        title.alignment = .center
        title.frame = NSRect(x: 0, y: 315, width: 280, height: 30)
        view.addSubview(title)
        
        // Language selector
        let langLabel = NSTextField(labelWithString: L.get("language"))
        langLabel.font = NSFont.systemFont(ofSize: 13)
        langLabel.frame = NSRect(x: 20, y: 270, width: 100, height: 20)
        view.addSubview(langLabel)
        
        languagePopup = NSPopUpButton(frame: NSRect(x: 150, y: 267, width: 110, height: 25))
        for lang in LocalizationManager.Language.allCases {
            languagePopup.addItem(withTitle: lang.displayName)
        }
        languagePopup.selectItem(withTitle: L.currentLanguage.displayName)
        languagePopup.target = self
        languagePopup.action = #selector(languageChanged)
        view.addSubview(languagePopup)
        
        // Work duration
        let workRow = createSettingRow(
            label: L.get("focusDuration"),
            value: settings.workDuration,
            min: 1,
            max: 60,
            y: 230,
            suffix: "min"
        )
        workStepper = workRow.stepper
        workLabel = workRow.valueLabel
        workStepper.target = self
        workStepper.action = #selector(workDurationChanged)
        
        // Short break
        let shortRow = createSettingRow(
            label: L.get("shortBreakDuration"),
            value: settings.shortBreakDuration,
            min: 1,
            max: 30,
            y: 190,
            suffix: "min"
        )
        shortBreakStepper = shortRow.stepper
        shortBreakLabel = shortRow.valueLabel
        shortBreakStepper.target = self
        shortBreakStepper.action = #selector(shortBreakChanged)
        
        // Long break
        let longRow = createSettingRow(
            label: L.get("longBreakDuration"),
            value: settings.longBreakDuration,
            min: 5,
            max: 45,
            y: 150,
            suffix: "min"
        )
        longBreakStepper = longRow.stepper
        longBreakLabel = longRow.valueLabel
        longBreakStepper.target = self
        longBreakStepper.action = #selector(longBreakChanged)
        
        // Sessions until long break
        let sessionsRow = createSettingRow(
            label: L.get("sessionsBeforeLong"),
            value: settings.sessionsUntilLongBreak,
            min: 2,
            max: 10,
            y: 110,
            suffix: ""
        )
        sessionsStepper = sessionsRow.stepper
        sessionsLabel = sessionsRow.valueLabel
        sessionsStepper.target = self
        sessionsStepper.action = #selector(sessionsChanged)
        
        // Daily goal
        let goalRow = createSettingRow(
            label: L.get("dailyGoal"),
            value: settings.dailyGoal,
            min: 1,
            max: 20,
            y: 70,
            suffix: ""
        )
        goalStepper = goalRow.stepper
        goalLabel = goalRow.valueLabel
        goalStepper.target = self
        goalStepper.action = #selector(goalChanged)
        
        // Shortcut info
        let shortcutLabel = NSTextField(labelWithString: L.get("shortcut"))
        shortcutLabel.font = NSFont.systemFont(ofSize: 11)
        shortcutLabel.textColor = .tertiaryLabelColor
        shortcutLabel.alignment = .center
        shortcutLabel.frame = NSRect(x: 0, y: 40, width: 280, height: 16)
        shortcutLabel.isEditable = false
        shortcutLabel.isBordered = false
        shortcutLabel.backgroundColor = .clear
        view.addSubview(shortcutLabel)
        
        // Back button
        let backButton = NSButton(title: L.get("back"), target: self, action: #selector(backTapped))
        backButton.bezelStyle = .inline
        backButton.frame = NSRect(x: 100, y: 15, width: 80, height: 20)
        view.addSubview(backButton)
    }
    
    private func createSettingRow(label: String, value: Int, min: Int, max: Int, y: CGFloat, suffix: String) -> (stepper: NSStepper, valueLabel: NSTextField) {
        // Label
        let labelField = NSTextField(labelWithString: label)
        labelField.font = NSFont.systemFont(ofSize: 13)
        labelField.frame = NSRect(x: 20, y: y, width: 150, height: 20)
        view.addSubview(labelField)
        
        // Value label
        let displayValue = suffix.isEmpty ? "\(value)" : "\(value) \(suffix)"
        let valueLabel = NSTextField(labelWithString: displayValue)
        valueLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        valueLabel.alignment = .right
        valueLabel.frame = NSRect(x: 170, y: y, width: 50, height: 20)
        valueLabel.isEditable = false
        valueLabel.isBordered = false
        valueLabel.backgroundColor = .clear
        view.addSubview(valueLabel)
        
        // Stepper
        let stepper = NSStepper(frame: NSRect(x: 230, y: y - 2, width: 20, height: 25))
        stepper.minValue = Double(min)
        stepper.maxValue = Double(max)
        stepper.intValue = Int32(value)
        stepper.increment = 1
        stepper.valueWraps = false
        view.addSubview(stepper)
        
        return (stepper, valueLabel)
    }
    
    @objc private func languageChanged() {
        let selectedTitle = languagePopup.selectedItem?.title ?? ""
        for lang in LocalizationManager.Language.allCases {
            if lang.displayName == selectedTitle {
                L.currentLanguage = lang
                break
            }
        }
    }
    
    @objc private func workDurationChanged() {
        let value = Int(workStepper.intValue)
        settings.workDuration = value
        workLabel.stringValue = "\(value) min"
        timer.applySettings()
    }
    
    @objc private func shortBreakChanged() {
        let value = Int(shortBreakStepper.intValue)
        settings.shortBreakDuration = value
        shortBreakLabel.stringValue = "\(value) min"
        timer.applySettings()
    }
    
    @objc private func longBreakChanged() {
        let value = Int(longBreakStepper.intValue)
        settings.longBreakDuration = value
        longBreakLabel.stringValue = "\(value) min"
        timer.applySettings()
    }
    
    @objc private func sessionsChanged() {
        let value = Int(sessionsStepper.intValue)
        settings.sessionsUntilLongBreak = value
        sessionsLabel.stringValue = "\(value)"
    }
    
    @objc private func goalChanged() {
        let value = Int(goalStepper.intValue)
        settings.dailyGoal = value
        goalLabel.stringValue = "\(value)"
    }
    
    @objc private func backTapped() {
        onClose?()
    }
}

// MARK: - Task View Controller
class TaskViewController: NSViewController {
    private let taskManager = TaskManager.shared
    private let L = LocalizationManager.shared
    private var scrollView: NSScrollView!
    private var taskContainer: NSView!
    private var inputField: NSTextField!
    
    var onClose: (() -> Void)?
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 280, height: 340))
        view.wantsLayer = true
        setupUI()
    }
    
    private func setupUI() {
        // Title
        let title = NSTextField(labelWithString: L.get("tasks"))
        title.font = NSFont.systemFont(ofSize: 18, weight: .semibold)
        title.alignment = .center
        title.frame = NSRect(x: 0, y: 300, width: 280, height: 30)
        view.addSubview(title)
        
        // Input field
        inputField = NSTextField(frame: NSRect(x: 20, y: 265, width: 200, height: 24))
        inputField.placeholderString = L.get("newTask")
        inputField.font = NSFont.systemFont(ofSize: 13)
        inputField.target = self
        inputField.action = #selector(addTask)
        view.addSubview(inputField)
        
        // Add button
        let addButton = NSButton(title: "+", target: self, action: #selector(addTask))
        addButton.frame = NSRect(x: 225, y: 265, width: 35, height: 24)
        addButton.bezelStyle = .rounded
        addButton.font = NSFont.systemFont(ofSize: 16, weight: .bold)
        view.addSubview(addButton)
        
        // Scroll view for tasks
        scrollView = NSScrollView(frame: NSRect(x: 10, y: 50, width: 260, height: 205))
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        
        taskContainer = NSView(frame: NSRect(x: 0, y: 0, width: 245, height: 205))
        scrollView.documentView = taskContainer
        view.addSubview(scrollView)
        
        // Clear completed button
        let clearButton = NSButton(title: L.get("clearCompleted"), target: self, action: #selector(clearCompleted))
        clearButton.frame = NSRect(x: 20, y: 18, width: 120, height: 24)
        clearButton.bezelStyle = .inline
        clearButton.font = NSFont.systemFont(ofSize: 11)
        view.addSubview(clearButton)
        
        // Back button
        let backButton = NSButton(title: L.get("back"), target: self, action: #selector(backTapped))
        backButton.bezelStyle = .inline
        backButton.frame = NSRect(x: 180, y: 18, width: 80, height: 24)
        view.addSubview(backButton)
        
        refreshTasks()
    }
    
    func refreshTasks() {
        // Clear existing
        taskContainer.subviews.forEach { $0.removeFromSuperview() }
        
        let tasks = taskManager.tasks
        let rowHeight: CGFloat = 30
        let totalHeight = max(CGFloat(tasks.count) * rowHeight, 205)
        
        taskContainer.frame = NSRect(x: 0, y: 0, width: 245, height: totalHeight)
        
        for (index, task) in tasks.enumerated() {
            let y = totalHeight - CGFloat(index + 1) * rowHeight
            
            // Checkbox
            let checkbox = NSButton(checkboxWithTitle: "", target: self, action: #selector(toggleTask(_:)))
            checkbox.frame = NSRect(x: 5, y: y, width: 20, height: rowHeight)
            checkbox.state = task.done ? .on : .off
            checkbox.tag = index
            taskContainer.addSubview(checkbox)
            
            // Task text
            let label = NSTextField(labelWithString: task.text)
            label.font = NSFont.systemFont(ofSize: 13)
            label.frame = NSRect(x: 28, y: y + 5, width: 180, height: 20)
            label.lineBreakMode = .byTruncatingTail
            if task.done {
                label.textColor = .tertiaryLabelColor
                let attributed = NSMutableAttributedString(string: task.text)
                attributed.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: task.text.count))
                label.attributedStringValue = attributed
            }
            taskContainer.addSubview(label)
            
            // Delete button
            let deleteButton = NSButton(title: "×", target: self, action: #selector(deleteTask(_:)))
            deleteButton.frame = NSRect(x: 215, y: y + 2, width: 25, height: 25)
            deleteButton.bezelStyle = .inline
            deleteButton.font = NSFont.systemFont(ofSize: 14)
            deleteButton.tag = index
            taskContainer.addSubview(deleteButton)
        }
    }
    
    @objc private func addTask() {
        let text = inputField.stringValue.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        
        taskManager.addTask(text)
        inputField.stringValue = ""
        refreshTasks()
    }
    
    @objc private func toggleTask(_ sender: NSButton) {
        taskManager.toggleTask(at: sender.tag)
        refreshTasks()
    }
    
    @objc private func deleteTask(_ sender: NSButton) {
        taskManager.deleteTask(at: sender.tag)
        refreshTasks()
    }
    
    @objc private func clearCompleted() {
        taskManager.clearCompleted()
        refreshTasks()
    }
    
    @objc private func backTapped() {
        onClose?()
    }
}

// MARK: - Status Bar Controller
class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private let timer = PomodoroTimer.shared
    private let L = LocalizationManager.shared
    private var pomodoroVC: PomodoroViewController!
    
    override init() {
        super.init()
        setupStatusItem()
        setupPopover()
        setupTimer()
        setupHotkey()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            updateStatusButton()
            button.action = #selector(togglePopover)
            button.target = self
        }
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 340)
        popover.behavior = .transient
        pomodoroVC = PomodoroViewController()
        pomodoroVC.onShowSettings = { [weak self] in
            self?.showSettings()
        }
        pomodoroVC.onShowTasks = { [weak self] in
            self?.showTasks()
        }
        popover.contentViewController = pomodoroVC
    }
    
    private func setupTimer() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTimerUpdate),
            name: .timerDidUpdate,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSessionComplete),
            name: .sessionDidComplete,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDailyGoalReached),
            name: .dailyGoalReached,
            object: nil
        )
    }
    
    private func setupHotkey() {
        HotkeyManager.shared.onHotkey = { [weak self] in
            self?.timer.toggleStartPause()
        }
        HotkeyManager.shared.register()
    }
    
    @objc private func handleTimerUpdate() {
        DispatchQueue.main.async {
            self.updateStatusButton()
        }
    }
    
    @objc private func handleSessionComplete(_ notification: Notification) {
        if let sessionType = notification.object as? SessionType {
            playSound(for: sessionType)
        }
    }
    
    private func updateStatusButton() {
        guard let button = statusItem.button else { return }
        
        if timer.state == .running {
            button.title = timer.formattedTime
        } else if timer.state == .paused {
            button.title = "\(timer.formattedTime) ⏸"
        } else {
            let icon = timer.sessionType == .work ? "🍅" : "☕"
            button.title = icon
        }
    }
    
    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    private func showSettings() {
        let settingsVC = SettingsViewController()
        settingsVC.onClose = { [weak self] in
            self?.popover.contentViewController = self?.pomodoroVC
            self?.pomodoroVC.refreshUI()
        }
        popover.contentViewController = settingsVC
    }
    
    private func showTasks() {
        let taskVC = TaskViewController()
        taskVC.onClose = { [weak self] in
            self?.popover.contentViewController = self?.pomodoroVC
        }
        popover.contentViewController = taskVC
    }
    
    private func playSound(for completedSession: SessionType) {
        // Jouer un son plus agréable
        if let sound = NSSound(named: "Glass") {
            sound.play()
        } else {
            NSSound.beep()
        }
        
        // Notification non-bloquante via le status bar
        DispatchQueue.main.async {
            if completedSession == .work {
                self.statusItem.button?.title = self.L.get("sessionComplete")
            } else {
                self.statusItem.button?.title = self.L.get("letsGo")
            }
            
            // Restaurer après 3 secondes
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.updateStatusButton()
            }
        }
    }
    
    @objc private func handleDailyGoalReached() {
        DispatchQueue.main.async {
            // Son spécial
            if let sound = NSSound(named: "Funk") {
                sound.play()
            }
            
            // Popup de félicitation
            let alert = NSAlert()
            alert.messageText = self.L.get("goalReachedTitle")
            alert.informativeText = self.L.get("goalReachedMessage")
            alert.alertStyle = .informational
            alert.addButton(withTitle: self.L.get("great"))
            alert.runModal()
        }
    }
}

// MARK: - Pomodoro View Controller
class PomodoroViewController: NSViewController {
    private let timer = PomodoroTimer.shared
    private let settings = SettingsManager.shared
    private let L = LocalizationManager.shared
    private var timeLabel: NSTextField!
    private var sessionLabel: NSTextField!
    private var progressBar: InteractiveProgressBar!
    private var startPauseButton: NSButton!
    private var resetButton: NSButton!
    private var skipButton: NSButton!
    private var sessionsLabel: NSTextField!
    private var goalLabel: NSTextField!
    private var quitButton: NSButton!
    private var resetDayButton: NSButton!
    
    var onShowSettings: (() -> Void)?
    var onShowTasks: (() -> Void)?
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 280, height: 340))
        view.wantsLayer = true
        setupUI()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTimerUpdate),
            name: .timerDidUpdate,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLanguageChange),
            name: .languageDidChange,
            object: nil
        )
        updateUI()
    }
    
    @objc private func handleTimerUpdate() {
        DispatchQueue.main.async {
            self.updateUI()
        }
    }
    
    @objc private func handleLanguageChange() {
        DispatchQueue.main.async {
            self.updateUI()
        }
    }
    
    func refreshUI() {
        updateUI()
    }
    
    private func setupUI() {
        // Session type label
        sessionLabel = createLabel(fontSize: 14, weight: .medium)
        sessionLabel.textColor = .secondaryLabelColor
        sessionLabel.frame = NSRect(x: 0, y: 280, width: 280, height: 24)
        view.addSubview(sessionLabel)
        
        // Time label
        timeLabel = createLabel(fontSize: 56, weight: .light)
        timeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 56, weight: .light)
        timeLabel.frame = NSRect(x: 0, y: 200, width: 280, height: 70)
        view.addSubview(timeLabel)
        
        // Progress bar (interactive)
        progressBar = InteractiveProgressBar(frame: NSRect(x: 40, y: 175, width: 200, height: 12))
        progressBar.onProgressChanged = { [weak self] newProgress in
            self?.timer.setProgress(newProgress)
        }
        view.addSubview(progressBar)
        
        // Buttons container
        let buttonY: CGFloat = 120
        let buttonWidth: CGFloat = 70
        let buttonHeight: CGFloat = 32
        let spacing: CGFloat = 10
        let totalWidth = buttonWidth * 3 + spacing * 2
        let startX = (280 - totalWidth) / 2
        
        // Start/Pause button
        startPauseButton = createButton(title: L.get("start"), action: #selector(startPauseTapped))
        startPauseButton.frame = NSRect(x: startX, y: buttonY, width: buttonWidth, height: buttonHeight)
        startPauseButton.bezelStyle = .rounded
        startPauseButton.keyEquivalent = " "
        view.addSubview(startPauseButton)
        
        // Reset button
        resetButton = createButton(title: L.get("reset"), action: #selector(resetTapped))
        resetButton.frame = NSRect(x: startX + buttonWidth + spacing, y: buttonY, width: buttonWidth, height: buttonHeight)
        resetButton.bezelStyle = .rounded
        view.addSubview(resetButton)
        
        // Skip button
        skipButton = createButton(title: L.get("skip"), action: #selector(skipTapped))
        skipButton.frame = NSRect(x: startX + (buttonWidth + spacing) * 2, y: buttonY, width: buttonWidth, height: buttonHeight)
        skipButton.bezelStyle = .rounded
        view.addSubview(skipButton)
        
        // Goal progress label
        goalLabel = createLabel(fontSize: 14, weight: .medium)
        goalLabel.frame = NSRect(x: 0, y: 75, width: 240, height: 24)
        view.addSubview(goalLabel)
        
        // Reset day button
        resetDayButton = NSButton(title: "↺", target: self, action: #selector(resetDayTapped))
        resetDayButton.frame = NSRect(x: 235, y: 75, width: 30, height: 24)
        resetDayButton.bezelStyle = .inline
        resetDayButton.font = NSFont.systemFont(ofSize: 14)
        resetDayButton.toolTip = L.get("resetDay")
        view.addSubview(resetDayButton)
        
        // Sessions counter
        sessionsLabel = createLabel(fontSize: 11, weight: .regular)
        sessionsLabel.textColor = .tertiaryLabelColor
        sessionsLabel.frame = NSRect(x: 0, y: 55, width: 280, height: 18)
        view.addSubview(sessionsLabel)
        
        // Settings button
        let settingsButton = createButton(title: "⚙️", action: #selector(settingsTapped))
        settingsButton.frame = NSRect(x: 40, y: 15, width: 40, height: 24)
        settingsButton.bezelStyle = .inline
        settingsButton.font = NSFont.systemFont(ofSize: 16)
        view.addSubview(settingsButton)
        
        // Tasks button
        let tasksButton = createButton(title: "📝", action: #selector(tasksTapped))
        tasksButton.frame = NSRect(x: 120, y: 15, width: 40, height: 24)
        tasksButton.bezelStyle = .inline
        tasksButton.font = NSFont.systemFont(ofSize: 16)
        view.addSubview(tasksButton)
        
        // Quit button
        quitButton = createButton(title: L.get("quit"), action: #selector(quitApp))
        quitButton.frame = NSRect(x: 195, y: 15, width: 65, height: 24)
        quitButton.bezelStyle = .inline
        quitButton.font = NSFont.systemFont(ofSize: 11)
        view.addSubview(quitButton)
    }
    
    private func createLabel(fontSize: CGFloat, weight: NSFont.Weight) -> NSTextField {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.systemFont(ofSize: fontSize, weight: weight)
        label.alignment = .center
        label.isEditable = false
        label.isBordered = false
        label.backgroundColor = .clear
        return label
    }
    
    private func createButton(title: String, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        return button
    }
    
    private func updateUI() {
        timeLabel.stringValue = timer.formattedTime
        sessionLabel.stringValue = timer.sessionType.localizedName
        progressBar.progress = timer.progress
        
        switch timer.state {
        case .idle:
            startPauseButton.title = L.get("start")
        case .running:
            startPauseButton.title = L.get("pause")
        case .paused:
            startPauseButton.title = L.get("resume")
        }
        
        // Update button labels
        resetButton.title = L.get("reset")
        skipButton.title = L.get("skip")
        quitButton.title = L.get("quit")
        resetDayButton.toolTip = L.get("resetDay")
        
        // Goal progress
        let completed = timer.completedSessions
        let goal = settings.dailyGoal
        let remaining = max(0, goal - completed)
        
        if completed >= goal {
            goalLabel.stringValue = L.get("goalReached")
            goalLabel.textColor = NSColor(red: 0.30, green: 0.69, blue: 0.31, alpha: 1.0)
        } else {
            goalLabel.stringValue = "\(completed)/\(goal) \(L.get("sessions"))"
            goalLabel.textColor = .labelColor
        }
        
        if remaining > 0 && completed < goal {
            sessionsLabel.stringValue = L.get("remainingGoal", remaining)
        } else if completed >= goal {
            sessionsLabel.stringValue = L.get("exceededGoal")
        } else {
            sessionsLabel.stringValue = ""
        }
        
        // Color based on session type
        let color: NSColor
        switch timer.sessionType {
        case .work:
            color = NSColor(red: 0.92, green: 0.34, blue: 0.34, alpha: 1.0)
        case .shortBreak:
            color = NSColor(red: 0.30, green: 0.69, blue: 0.31, alpha: 1.0)
        case .longBreak:
            color = NSColor(red: 0.25, green: 0.47, blue: 0.85, alpha: 1.0)
        }
        timeLabel.textColor = color
        progressBar.progressColor = color
    }
    
    @objc private func startPauseTapped() {
        timer.toggleStartPause()
    }
    
    @objc private func resetTapped() {
        timer.reset()
    }
    
    @objc private func skipTapped() {
        timer.skip()
    }
    
    @objc private func resetDayTapped() {
        timer.resetDay()
    }
    
    @objc private func settingsTapped() {
        onShowSettings?()
    }
    
    @objc private func tasksTapped() {
        onShowTasks?()
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController()
        NSApp.setActivationPolicy(.accessory)
    }
}

// MARK: - Main
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
