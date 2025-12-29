# Pomodoro Timer for macOS

A lightweight Pomodoro timer that lives in your macOS menu bar. Built with Swift, no dependencies.

![Timer](https://i.ibb.co/XfVz4vrp/Capture-d-e-cran-2025-12-29-a-16-21-44.png)

## Features

- **Menu bar app** - Always accessible, never in your way
- **Customizable durations** - Focus, short break, and long break timers
- **Daily goals** - Set and track your daily Pomodoro target
- **Task list** - Keep track of what you're working on
- **Bilingual** - French and English support
- **Global hotkey** - Start/Pause with `Cmd+Shift+P`
- **Interactive progress bar** - Click to adjust time remaining

## Screenshots

| Settings | Tasks |
|----------|-------|
| ![Settings](https://i.ibb.co/5xJcHVXM/Capture-d-e-cran-2025-12-29-a-16-21-58.png) | ![Tasks](https://i.ibb.co/7JrMMT1K/Capture-d-e-cran-2025-12-29-a-16-23-03.png) |

## Installation

### Build from source

```bash
# Clone the repo
git clone https://github.com/e-jaafar/pomodoroapp.git
cd pomodoroapp

# Build
swift build -c release

# Run
.build/release/PomodoroApp
```

### Create .app bundle

After building, you can create a proper macOS app bundle for drag-and-drop installation.

## Usage

1. Click the tomato icon in your menu bar
2. Press **Start** to begin a focus session
3. Take breaks when prompted
4. Track your progress toward your daily goal

## Keyboard Shortcut

| Shortcut | Action |
|----------|--------|
| `Cmd+Shift+P` | Start/Pause timer |

## License

MIT
