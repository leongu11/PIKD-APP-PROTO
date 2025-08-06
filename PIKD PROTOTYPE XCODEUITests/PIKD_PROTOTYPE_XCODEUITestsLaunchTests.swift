//
//  PIKD_PROTOTYPE_XCODEUITestsLaunchTests.swift
//  PIKD PROTOTYPE XCODEUITests
//
//  Created by Leo Nguyen on 8/6/25.
//

import XCTest

final class PIKD_PROTOTYPE_XCODEUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
