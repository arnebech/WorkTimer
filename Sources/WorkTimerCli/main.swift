import Foundation
import AppKit
import ArgumentParser
import TSCBasic
import WorkTimerCore

struct WorkTimer: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "An utility for tracking time worked on a work computer.",
        version: "0.0.1"
    )
    
    @Option(default: 8, help: "Number of hours in a workday")
    var workHours: Float
    
    @Option(default: 5, help: "Number of minutes between work time status reports")
    var freq: Float
    
    func run() {
        let terminalOpt = TerminalController(stream: stdoutStream)
        guard let terminal = terminalOpt else {
            print("not a terminal? Exiting...")
            return
        }
        
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .short
        formatter.allowedUnits = [.minute, .hour]
        
        let timerInterval: TimeInterval = TimeInterval(60 * freq)
        
        terminal.write("****  Work timer started  ****\n")
        terminal.write("Type ? + enter for options\n")
        terminal.write("Work time is updated every \(formatter.string(from: timerInterval) ?? "?")\n")
        terminal.write("*****\n")
        
        
        let tracker = WorkTimeTracker(dailyWorkSeconds: TimeInterval(workHours * 60 * 60))
        let cli = WorkTimeCli(manager: tracker, terminal: terminal)
        cli.scheduleRecurringStatusUpdates(timerInterval: timerInterval)
        
        DispatchQueue.global(qos: .userInteractive).async {
            cli.processInput()
        }
        
        RunLoop.main.run()
    }
}

WorkTimer.main()
