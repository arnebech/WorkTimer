import Foundation
import TSCBasic

public class WorkTimeCli {
    let manager: WorkTimeTracker
    var outputEnabled = true
    let shortDateFormatter: DateFormatter
    let endTimeFormatter: DateFormatter
    let shortDurationFormatter: DateComponentsFormatter
    var statusTimer = Timer()
    var endTimer: Timer?
    let terminal: TerminalController
    var dayFinished = false
    let statusTimeInterval: TimeInterval
    
    public init(manager: WorkTimeTracker, terminal: TerminalController, statusUpdateEvery statusTimeInterval: TimeInterval) {
        self.manager = manager
        self.terminal = terminal
        self.statusTimeInterval = statusTimeInterval
        
        endTimeFormatter = DateFormatter()
        endTimeFormatter.dateStyle = .none
        endTimeFormatter.timeStyle = .short
        
        shortDateFormatter = DateFormatter()
        shortDateFormatter.dateStyle = .short
        shortDateFormatter.timeStyle = .short
        
        shortDurationFormatter = DateComponentsFormatter()
        shortDurationFormatter.unitsStyle = .short
        shortDurationFormatter.allowedUnits = [.minute, .hour]
        
        manager.onEventCallback = onAddInternalEntry
        
        scheduleRecurringStatusUpdates(timerInterval: statusTimeInterval)
        
    }
    
    func onAddInternalEntry(type: EventType, time: Date = Date()) {
        if type == .Wake || type == .ScreenWake {
            outputEnabled = true
        }
        if outputEnabled {
            terminal.write("\(type) - \(shortDateFormatter.string(from: time))\n")
            if type == .Wake || type == .ScreenWake {
                printCurrentStatus()
            }
        }
        if type == .Sleep || type == .ScreenSleep {
            outputEnabled = false
        }
    }
    
    func printWorkFinishedMessage() {
        let formattedTimeDone = shortDurationFormatter.string(from: manager.getWorkTimeDone()) ?? ""
        writeLine("🎉🎉🎉🎉🎉🎉🎉🎉🎉")
        writeLine("Worked: \(terminal.wrap(formattedTimeDone, inColor: .cyan))")
        writeLine("🎉🎉🎉🎉🎉🎉🎉🎉🎉")
    }
    
    func handleWorkTimeFinish() {
        let timeLeft = manager.getWorkTimeLeft();
        
        endTimer?.invalidate()
        
        if timeLeft > 0 {
            dayFinished = false
            if timeLeft < statusTimeInterval {
                endTimer = Timer.scheduledTimer(withTimeInterval: timeLeft, repeats: false) { (timer) in
                    self.handleWorkTimeFinish()
                }
            }
            return
        }
        
        if dayFinished {
            return
        }
        
        if timeLeft <= 0 && !dayFinished {
            dayFinished = true
            printWorkFinishedMessage()
        }
    }
    
    func printCurrentStatus() {
        let timeDone = manager.getWorkTimeDone()
        
        var duration = shortDurationFormatter.string(from: timeDone) ?? ""
        duration = duration.padding(toLength: 16, withPad: " ", startingAt: 0)
    
        let workEndDate = manager.getEstimatedDoneTime()
        let workEndDateFormatted = endTimeFormatter.string(from: workEndDate)
        let doneColor: TerminalController.Color = workEndDate < Date() ? .yellow : .cyan
        terminal.write("Worked: \(terminal.wrap(duration, inColor: .cyan)) Done: \(terminal.wrap(workEndDateFormatted, inColor: doneColor))\n")
    }
    
    func scheduleRecurringStatusUpdates(timerInterval: TimeInterval) {
        let timer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { (timer) in
            if self.outputEnabled {
                self.printCurrentStatus()
            }
            self.handleWorkTimeFinish()
        }
        timer.fire()
        statusTimer = timer
    }
    
    public func processInput() {
        while (true) {
            let val = readLine()
            outputEnabled = false
            if val == "?" {
                printOptions()
            } else {
                writeLine("Unrecognized option. Use ? + enter to view commands.")
            }
            outputEnabled = true
        }
    }
    
    func writeLine(_ line: String) {
        terminal.write("\(line)\n")
    }
    
    func printOptions() {
        writeLine("Options: ")
        writeLine(" 1. Add/Remove time")
        writeLine(" 2. List todays events")
        terminal.write("Enter Option: ")
        let val = readLine()
        if val == "1" {
            handleAdjustTime()
        } else if val == "2" {
            printHistoryEvents()
        } else {
            writeLine("Invalid option")
        }
    }
    
    func handleAdjustTime() {
        terminal.write("Enter time adjustment such as 00:10 or -01:10: ")
        let val = readLine()
        
        if let val = val {
            let parts = val.trimmingCharacters(in: .whitespaces).split(separator: ":")
            let numbers = parts.map { (numberString) -> TimeInterval in
                return abs(TimeInterval(numberString) ?? 0)
            }
            let factor: TimeInterval = val.starts(with: "-") ? -1 : 1;
            let minutes = numbers.count == 1 ? numbers[0] : numbers[1]
            let hours = numbers.count == 1 ? 0 : numbers[0];
            let duration = factor * (hours * 60 * 60 + minutes * 60);
            manager.adjustTime(time: duration)
            writeLine("Adjusted time by \(shortDurationFormatter.string(from: duration) ?? "?")s at \(shortDateFormatter.string(from: Date()))")
            printCurrentStatus()
        }
    }
    
    func printHistoryEvents() {
        manager.events.forEach { (item) in
            writeLine("\(item.type) - \(shortDateFormatter.string(from: item.time))")
        }
    }
}

