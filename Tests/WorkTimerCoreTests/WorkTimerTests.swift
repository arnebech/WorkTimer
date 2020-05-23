import XCTest
import class Foundation.Bundle
@testable import WorkTimerCore

final class WorkTimerTests: XCTestCase {
    var manager: WorkTimeTracker = WorkTimeTracker(dailyWorkSeconds: TimeInterval(10000))
    let formatter: DateFormatter = DateFormatter()
    
    override func setUp() {
        formatter.dateFormat = "yyyy-MM-dd HH:mm";
        manager = WorkTimeTracker(dailyWorkSeconds: TimeInterval(8 * 60 * 60), startTime: date("2020-01-10 10:20"));
    }
    
    func date(_ dateString: String) -> Date {
        return formatter.date(from: dateString)!
    }
    func testStartInMiddleOfDay() {
        
        XCTAssertEqual(
            manager.getWorkTimeDone(now: date("2020-01-10 11:20")),
            3600)
    }
    
    func testTimeAdjustment() {
        manager.adjustTime(time: -250)
        XCTAssertEqual(
            manager.getWorkTimeDone(now: date("2020-01-10 11:20")),
            3600 - 250)
    }
    
    func testStartInMiddleOfDayWithSleepAndWake() {
        manager.addInternalEntry(type: .Sleep,
                                 time: date("2020-01-10 10:40"))
        
        manager.addInternalEntry(type: .Wake,
                                 time: date("2020-01-10 10:50"))
        
        XCTAssertEqual(
            manager.getWorkTimeDone(now: date("2020-01-10 11:20")),
            3000)
    }
    
    func testCrossDayBoundary() {
        XCTAssertEqual(
            manager.getWorkTimeDone(now: date("2020-01-11 01:00")),
            3600)
    }
    
    func testCrossDayBoundaryWhileSleeping() {
        manager.addInternalEntry(type: .Sleep,
                                 time: date("2020-01-10 10:40"))
        
        manager.addInternalEntry(type: .Wake,
                                 time: date("2020-01-11 10:50"))
        
        XCTAssertEqual(
            manager.getWorkTimeDone(now: date("2020-01-11 11:00")),
            600)
    }
}
