// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest
@testable import Logger

final class LoggerTests: XCTestCase {
    private var beaverBuilder: MockSwiftyBeaverBuilder!
    private var sentryWrapper: MockSentryWrapper!

    override func setUp() {
        super.setUp()
        beaverBuilder = MockSwiftyBeaverBuilder()
        sentryWrapper = MockSentryWrapper()
        cleanUp()
    }

    override func tearDown() {
        super.tearDown()
        beaverBuilder = nil
        sentryWrapper = nil
        cleanUp()
    }

    // MARK: - Log

    func testLog_debug() {
        let subject = DefaultLogger(swiftyBeaverBuilder: beaverBuilder,
                                    sentryWrapper: sentryWrapper)
        subject.log("Debug log", level: .debug, category: .setup)
        XCTAssertEqual(MockSwiftyBeaver.debugCalled, 1)
    }

    func testLog_info() {
        let subject = DefaultLogger(swiftyBeaverBuilder: beaverBuilder,
                                    sentryWrapper: sentryWrapper)
        subject.log("Info log", level: .info, category: .setup)
        XCTAssertEqual(MockSwiftyBeaver.infoCalled, 1)
    }

    func testLog_warning() {
        let subject = DefaultLogger(swiftyBeaverBuilder: beaverBuilder,
                                    sentryWrapper: sentryWrapper)
        subject.log("Warning log", level: .warning, category: .setup)
        XCTAssertEqual(MockSwiftyBeaver.warningCalled, 1)
    }

    func testLog_fatal() {
        let subject = DefaultLogger(swiftyBeaverBuilder: beaverBuilder,
                                    sentryWrapper: sentryWrapper)
        subject.log("Fatal log", level: .fatal, category: .setup)
        XCTAssertEqual(MockSwiftyBeaver.errorCalled, 1)
    }

    func testLog_informationCorrelate() throws {
        let subject = DefaultLogger(swiftyBeaverBuilder: beaverBuilder,
                                    sentryWrapper: sentryWrapper)
        subject.log("Debug log",
                    level: .debug,
                    category: .setup,
                    extra: ["example": "test"],
                    description: "A description")

        XCTAssertEqual(MockSwiftyBeaver.savedMessage, "Debug log - A description, example: test")
        XCTAssertEqual(MockSwiftyBeaver.debugCalled, 1)
    }

    // MARK: - Sentry

    func testSentryLog_fatalIsSent_informationCorrelate() throws {
        let subject = DefaultLogger(swiftyBeaverBuilder: beaverBuilder,
                                    sentryWrapper: sentryWrapper)
        subject.log("Fatal log",
                    level: .fatal,
                    category: .setup,
                    extra: ["example": "test"],
                    description: "A description")

        XCTAssertEqual(sentryWrapper.message, "Fatal log")
        XCTAssertEqual(sentryWrapper.category, .setup)
        XCTAssertEqual(sentryWrapper.level, .fatal)
        let extra = try XCTUnwrap(sentryWrapper.extraEvents)
        XCTAssertEqual(extra, ["example": "test", "errorDescription": "A description"])
    }

    func testSentryLog_sendUsageDataNotCalled() {
        _ = DefaultLogger(swiftyBeaverBuilder: beaverBuilder,
                          sentryWrapper: sentryWrapper)
        XCTAssertNil(sentryWrapper.savedSendUsageData)
    }

    func testSentryLog_sendUsageDataCalled() throws {
        let subject = DefaultLogger(swiftyBeaverBuilder: beaverBuilder,
                                    sentryWrapper: sentryWrapper)
        subject.setup(sendUsageData: true)

        let savedSendUsageData = try XCTUnwrap(sentryWrapper.savedSendUsageData)
        XCTAssertTrue(savedSendUsageData)
    }
}

// MARK: - Helper
private extension LoggerTests {
    func cleanUp() {
        MockSwiftyBeaver.debugCalled = 0
        MockSwiftyBeaver.infoCalled = 0
        MockSwiftyBeaver.warningCalled = 0
        MockSwiftyBeaver.errorCalled = 0
        MockSwiftyBeaver.savedMessage = nil
    }
}

// MARK: - SwiftyBeaverBuilder
class MockSwiftyBeaverBuilder: SwiftyBeaverBuilder {
    func setup(with destination: URL?) -> SwiftyBeaverWrapper.Type {
        return MockSwiftyBeaver.self
    }
}

// MARK: - MockSwiftyBeaver
class MockSwiftyBeaver: SwiftyBeaverWrapper {
    static func logFileDirectoryPath(inDocuments: Bool) -> String? {
        return nil
    }

    static var fileDestination: URL?
    static var savedMessage: String?

    static var debugCalled = 0
    static func debug(_ message: @autoclosure () -> Any, _ file: String, _ function: String, line: Int, context: Any?) {
        debugCalled += 1
        savedMessage = "\(message())"
    }

    static var infoCalled = 0
    static func info(_ message: @autoclosure () -> Any, _ file: String, _ function: String, line: Int, context: Any?) {
        infoCalled += 1
        savedMessage = "\(message())"
    }

    static var warningCalled = 0
    static func warning(_ message: @autoclosure () -> Any, _ file: String, _ function: String, line: Int, context: Any?) {
        warningCalled += 1
        savedMessage = "\(message())"
    }

    static var errorCalled = 0
    static func error(_ message: @autoclosure () -> Any, _ file: String, _ function: String, line: Int, context: Any?) {
        errorCalled += 1
        savedMessage = "\(message())"
    }
}

// MARK: - SentryWrapper
class MockSentryWrapper: SentryWrapper {
    var crashedLastLaunch: Bool = false

    var savedSendUsageData: Bool?
    func setup(sendUsageData: Bool) {
        savedSendUsageData = sendUsageData
    }

    var message: String?
    var category: LoggerCategory?
    var level: LoggerLevel?
    var extraEvents: [String: String]?
    func send(message: String,
              category: LoggerCategory,
              level: LoggerLevel,
              extraEvents: [String: String]?) {
        self.message = message
        self.category = category
        self.level = level
        self.extraEvents = extraEvents
    }
}