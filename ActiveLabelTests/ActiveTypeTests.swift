//
//  ActiveTypeTests.swift
//  ActiveTypeTests
//
//  Created by Johannes Schickling on 9/4/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import XCTest
@testable import ActiveLabel

extension ActiveElement: Equatable {}

func ==(a: ActiveElement, b: ActiveElement) -> Bool {
    switch (a, b) {
    case (.url(let a), .url(let b)) where a == b: return true
    case (.none, .none): return true
    default: return false
    }
}

class ActiveTypeTests: XCTestCase {
    
    let label = ActiveLabel
    
    var activeElements: [ActiveElement] {
        return label.activeElements.flatMap({$0.1.flatMap({$0.element})})
    }
    
    var currentElementString: String {
        let currentElement = activeElements.first!
        switch currentElement {
        case .url(let url):
            return url
        case .phone(let number):
            return number
        case .none:
            return ""
        }
    }
    
    var currentElementType: ActiveType {
        let currentElement = activeElements.first!
        switch currentElement {
        case .url:
            return .url
        case .phone:
            return .phone
        case .none:
            return .none
        }
    }
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testInvalid() {
        label.text = ""
        XCTAssertEqual(activeElements.count, 0)
        label.text = " "
        XCTAssertEqual(activeElements.count, 0)
        label.text = "x"
        XCTAssertEqual(activeElements.count, 0)
        label.text = "ಠ_ಠ"
        XCTAssertEqual(activeElements.count, 0)
        label.text = "😁"
        XCTAssertEqual(activeElements.count, 0)
    }
    
    func testURL() {
        label.text = "http://www.google.com"
        XCTAssertEqual(activeElements.count, 1)
        XCTAssertEqual(currentElementString, "http://www.google.com")
        XCTAssertEqual(currentElementType, ActiveType.url)

        label.text = "https://www.google.com"
        XCTAssertEqual(activeElements.count, 1)
        XCTAssertEqual(currentElementString, "https://www.google.com")
        XCTAssertEqual(currentElementType, ActiveType.url)

        label.text = "http://www.google.com."
        XCTAssertEqual(activeElements.count, 1)
        XCTAssertEqual(currentElementString, "http://www.google.com")
        XCTAssertEqual(currentElementType, ActiveType.url)

        label.text = "www.google.com"
        XCTAssertEqual(activeElements.count, 1)
        XCTAssertEqual(currentElementString, "www.google.com")
        XCTAssertEqual(currentElementType, ActiveType.url)
        
        label.text = "pic.twitter.com/YUGdEbUx"
        XCTAssertEqual(activeElements.count, 1)
        XCTAssertEqual(currentElementString, "pic.twitter.com/YUGdEbUx")
        XCTAssertEqual(currentElementType, ActiveType.url)

        label.text = "google.com"
        XCTAssertEqual(activeElements.count, 0)
    }
    
    func testPhoneNumbers() {
        label.text = "1-800-555-5555"
        XCTAssertEqual(activeElements.count, 1)
        XCTAssertEqual(currentElementType, ActiveType.phone)
        
        label.text = "301.987.6543"
        XCTAssertEqual(activeElements.count, 1)
        XCTAssertEqual(currentElementType, ActiveType.phone)
        
        label.text = "1-800-COMCAST"
        XCTAssertEqual(activeElements.count, 1)
        XCTAssertEqual(currentElementType, ActiveType.phone)
        
        label.text = "+1-(800)-555-2468"
        XCTAssertEqual(activeElements.count, 1)
        XCTAssertEqual(currentElementType, ActiveType.phone)

        label.text = "8473292"
        XCTAssertEqual(activeElements.count, 1)
        XCTAssertEqual(currentElementType, ActiveType.phone)
    }

    
}
