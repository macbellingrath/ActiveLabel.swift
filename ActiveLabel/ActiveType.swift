//
//  ActiveType.swift
//  ActiveLabel
//
//  Created by Johannes Schickling on 9/4/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation

enum ActiveElement {
    case url(String)
    case phone(String)
    case none
}

public enum ActiveType {
    case url
    case phone
    case none
}

struct ActiveBuilder {
    
    static func createURLElements(fromText text: String, range: NSRange) -> [(range: NSRange, element: ActiveElement)] {
        let urls = RegexParser.getURLs(fromText: text, range: range)
        let nsstring = text as NSString
        var elements: [(range: NSRange, element: ActiveElement)] = []
        
        for url in urls where url.range.length > 2 {
            let word = nsstring.substring(with: url.range)
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let element = ActiveElement.url(word)
            elements.append((url.range, element))
        }
        return elements
    }
    
    static func createPhoneNumberElements(fromText text: String, range: NSRange) -> [(range: NSRange, element: ActiveElement)] {
        let urls = RegexParser.getPhoneNumbers(fromText: text, range: range)
        let nsstring = text as NSString
        var elements: [(range: NSRange, element: ActiveElement)] = []
        
        for url in urls where url.range.length > 2 {
            let word = nsstring.substring(with: url.range)
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let element = ActiveElement.phone(word)
            elements.append((url.range, element))
        }
        return elements
    }
}
