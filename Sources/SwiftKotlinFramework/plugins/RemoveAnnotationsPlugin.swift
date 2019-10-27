//
//  RemoveAnnotationsPlugin.swift
//  SwiftKotlinFramework
//
//  Created by Ofer Moshaioff on 10/7/2019.
//

import Foundation

public class RemoveAnnotationsPlugin : SourceTransformPlugin {
    static let kotlinCodeRegex = "(@\\w+)"

    
    public func transform(source: String) throws -> String {
        return try transform(source: source, sourceIdentifier: "Not Available")
    }
    
    public func transform(source: String, sourceIdentifier: String?) throws -> String {
        
        return source.replacingOccurrences(of: RemoveAnnotationsPlugin.kotlinCodeRegex, with: "", options: .regularExpression)
    }
    
    public var name: String {
        return "Removing annotations"
    }
    
    public var description: String {
        return "Removing annotations"
    }
    
    public init() {}
}
