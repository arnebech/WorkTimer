import Foundation
import AppKit

public enum EventType {
    case Start, Sleep, Wake, ScreenSleep, ScreenWake, TimeAdjust
}

struct Event {
    let type: EventType
    let time: Date
    let timeAdjust: TimeInterval?
}

public class WorkTimeTracker {
    var events: [Event] = []
    var onEventCallback: ((_ type: EventType, _ time: Date) -> Void)?
    var dailyWorkSeconds: TimeInterval
    
    public init(dailyWorkSeconds: TimeInterval, startTime: Date = Date()) {
        self.dailyWorkSeconds = dailyWorkSeconds
        setupSleepAndWakeListeners()
        addInternalEntry(type: .Start, time: startTime)
    }
    
    func setupSleepAndWakeListeners() {
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: OperationQueue.current) { (notification) in
            self.addInternalEntry(type: .Sleep, time: Date())
        }
        
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: OperationQueue.current) { (notification) in
            self.addInternalEntry(type: .Wake, time: Date())
        }
        
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.screensDidSleepNotification, object: nil, queue: OperationQueue.current) { (notification) in
            self.addInternalEntry(type: .ScreenSleep, time: Date())
        }
        
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: OperationQueue.current) { (notification) in
            self.addInternalEntry(type: .ScreenWake, time: Date())
        }
    }
    
    func addInternalEntry(type: EventType, time: Date = Date()) -> Void {
        events.append(Event(type: type, time: time, timeAdjust: nil))
        if let callback = onEventCallback {
            callback(type, time)
        }
    }
    
    public func adjustTime(time: TimeInterval) {
        let now = Date()
        let type: EventType = .TimeAdjust
        events.append(Event(type: type, time: now, timeAdjust: time))
    }
    
    public func calculateTodaysWorkTime() -> TimeInterval {
        return calculateTodaysWorkTimeFor(now: Date())
    }
    
    func getTimeAdjustmentFrom(events: [Event]) -> TimeInterval {
        var isAsleep = false
        var nextCheck: EventType?
        var timeAdjustment: TimeInterval = 0
        var sleepStartTime: TimeInterval = 0
        for item in events {
            if item.type == .TimeAdjust && item.timeAdjust != nil {
                timeAdjustment += item.timeAdjust ?? 0
            } else if !isAsleep {
                if item.type == .ScreenSleep {
                    isAsleep = true
                    nextCheck = .ScreenWake
                    sleepStartTime = item.time.timeIntervalSinceReferenceDate
                } else if item.type == .Sleep {
                    isAsleep = true
                    nextCheck = .Wake
                    sleepStartTime = item.time.timeIntervalSinceReferenceDate
                }
            } else if item.type == nextCheck {
                isAsleep = false
                let sleepDuration = item.time.timeIntervalSinceReferenceDate - sleepStartTime
                timeAdjustment -= sleepDuration
            }
        }
        return timeAdjustment;
    }
    
    
    public func calculateTodaysWorkTimeFor(now: Date) -> TimeInterval {
        
        var workStart = Calendar.current.startOfDay(for: now)
        
        events.removeAll { (historyItem) -> Bool in
            return historyItem.time < workStart
        }
        
        if let firstEvent = events.first, firstEvent.type == .ScreenWake || firstEvent.type == .Wake || firstEvent.type == .Start {
            workStart = firstEvent.time
        }
        
        return now.timeIntervalSince(workStart) + getTimeAdjustmentFrom(events: events)
    }
    
    public func calculateEstimatedDoneTime() -> Date {
        let todaysWorkTime = calculateTodaysWorkTime()
        let workTimeLeft = dailyWorkSeconds - todaysWorkTime;
        
        let now = Date()
        
        let endTime = now.addingTimeInterval(workTimeLeft)
        return endTime
    }
}



