//
//  JSONHelperTests.swift
//  JSONHelperTests
//
//  Created by Baris Sencan on 28/08/14.
//  Copyright (c) 2014 Baris Sencan. All rights reserved.
//

import UIKit
import XCTest

class JSONHelperTests: XCTestCase {
    // Initialize our test subject with a dummy API response.
    let result = TestModel(data: [
        "string_val": "a",
        "int_val": 1,
        "bool_val": true,
        "date_val": "2014-09-19",
        "url_val": "http://github.com/",
        "string_array_val": ["a", "b", "c"],
        "int_array_val": [2, 2, 2, 2, 1],
        "bool_array_val": [true, false, true],
        "instance_val": [
            "string_val": "Mark"
        ],
        "instance_array_val": [
            [
                "string_val": "Hannibal"
            ], [
                "string_val": "Sabrina"
            ]
        ]
        ])

    let resultWithChangedDefaults = TestModel(data: [
        "string_val": "a",
        "defaultable_string": "not default",
        "int_val": 1,
        "defaultable_int": 99,
        "bool_val": true,
        "defaultable_bool": false,
        "date_val": "2014-09-19",
        "defaultable_date": "2015-09-19",
        "url_val": "http://github.com/",
        "defaultable_url": "http://quora.com/",
        "string_array_val": ["a", "b", "c"],
        "int_array_val": [2, 2, 2, 2, 1],
        "bool_array_val": [true, false, true],
        "instance_val": [
            "string_val": "Mark"
        ],
        "instance_array_val": [
            [
                "string_val": "Hannibal"
            ], [
                "string_val": "Sabrina"
            ]
        ]
        ])

    // Test different deserializations.
    func testString() {
        XCTAssertEqual(result.stringVal!, "a", "result.stringVal should equal 'a'")
    }

    func testDefaultableString() {
        XCTAssertEqual(result.defaultableString, "default", "result.defaultableString should equal 'default'")
        XCTAssertEqual(resultWithChangedDefaults.defaultableString, "not default", "resultWithChangedDefaults.defaultableString should equal 'not default'")
    }
    
    func testInt() {
        XCTAssertEqual(result.intVal!, 1, "result.intVal should equal 1")
    }

    func testDefaultableInt() {
        XCTAssertEqual(result.defaultableInt, 91, "result.defaultableInt should equal 91")
        XCTAssertEqual(resultWithChangedDefaults.defaultableInt, 99, "resultWithChangedDefaults.defaultableInt should equal 99")
    }

    func testStringToOptionalInt() {
        var number: Int?
        number <<< "5"

        XCTAssertEqual(number!, 5, "Strings containing numbers should successfully deserialize into optional Ints.")
    }

    func testStringToInt() {
        var number = 0
        number <<< "5"

        XCTAssertEqual(number, 5, "Strings containing numbers should successfully deserialize into Ints.")
    }

    func testBool() {
        XCTAssertEqual(result.boolVal!, true, "result.boolVal should be true")
    }

    func testDefaultableBool() {
        XCTAssertEqual(result.defaultableBool, true, "result.defaultableBool should be true")
        XCTAssertEqual(resultWithChangedDefaults.defaultableBool, false, "resultWithChangedDefaults.defaultableBool should be false")
    }

    func testDate() {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let testDate = dateFormatter.dateFromString("2014-09-19")

        XCTAssertEqual(result.dateVal!.compare(testDate!), NSComparisonResult.OrderedSame, "result.dateVal should be 2014-09-19")
    }

    func testDefaultableDate() {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let testDate = dateFormatter.dateFromString("2015-09-19")

        XCTAssertEqual(resultWithChangedDefaults.defaultableDate.compare(testDate!), NSComparisonResult.OrderedSame, "resultWithChangedDefaults.defaultableDate should be 2015-09-19")
    }

    func testURL() {
        XCTAssertEqual(result.urlVal!.host!, "github.com", "result.urlVal's host should be github.com")
    }

    func testDefaultableURL() {
        XCTAssertEqual(result.defaultableURL.host!, "google.com", "result.defaultableURL's host should be google.com")
        XCTAssertEqual(resultWithChangedDefaults.defaultableURL.host!, "quora.com", "resultWithChangedDefaults.defaultableURL's host should be quora.com")
    }

    func testStringArray() {
        XCTAssertEqual(result.stringArrayVal!.count, 3, "result.stringArrayVal should have 3 members")
    }

    func testIntArray() {
        XCTAssertEqual(result.intArrayVal!.count, 5, "result.intArrayVal should have 5 members")
    }

    func testBoolArray() {
        XCTAssertEqual(result.boolArrayVal!.count, 3, "result.boolArrayVal should have 3 members")
    }

    func testInstance() {
        XCTAssertEqual(result.instanceVal!.stringVal!, "Mark", "result.instanceVal?.stringVal should equal 'Mark'")
    }

    func testInstanceArray() {
        XCTAssertEqual(result.instanceArrayVal!.count, 2, "result.instanceArrayVal should have 2 members")
    }

    func testJSONStringParsing() {
        class Person: Deserializable {
            var name = ""

            required init(data: [String: AnyObject]) {
                name <<< data["name"]
            }
        }

        var jsonString = "[{\"name\": \"I am \"},{\"name\": \"Groot!\"}]"
        var people = [Person]()
        var areYouGroot = ""

        people <<<<* jsonString
        
        for person in people {
            areYouGroot += person.name
        }

        XCTAssertEqual(areYouGroot, "I am Groot!", "Groot should be Groot")
    }
}
