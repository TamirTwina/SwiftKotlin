//
//  KotlinOnlyCodeFromComment.swift
//  SwiftKotlin
//
//  Created by Tamir Twina on 6/9/18.
//

import Foundation
import Transform
import AST

public class KotlinOnlyCodeFromComment : TokenTransformPlugin {
    private let kotlinKeyword: String = "kotlin"
    
    public var name: String {
        return "Kotlin only copy 'as-is'"
    }
    
    public var description: String {
        return "//kotlin <Some String> comment --> in kotlin trsform = <Some String>"
    }
    
    public init() {}
    
    public func transform(tokens: [Token], topDeclaration: TopLevelDeclaration) throws -> [Token] {
        var newTokens = [Token]()
        
        for token in tokens {
            if token.kind == .comment,
                let origin = token.origin, let node = token.node,
                let stringGroups = extractedLineValue(token.value,keyword: kotlinKeyword),
                let commentKeyword = stringGroups.first,
                commentKeyword == kotlinKeyword,
                let kotlineCodeAsIs = stringGroups.last {
                    newTokens.append(origin.newToken(.string, kotlineCodeAsIs,node))
            } else {
                newTokens.append(token)
            }
        }
        
        return newTokens
    }
    
    
    private func extractedLineValue(_ comment: String,keyword:String) -> [String]? {
        let groups = comment.capturedGroups(withRegex: "\\/{2}\\s*(\\w+):?\\s*(.*)")
        return groups.count == 2 ? groups : nil
    }
    
}

extension String {
    func capturedGroups(withRegex pattern: String) -> [String] {
        var results = [String]()
        
        var regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: pattern, options: [])
        } catch {
            return results
        }
        
        let matches = regex.matches(in: self, options: [], range: NSRange(location:0, length: self.count))
        
        guard let match = matches.first else { return results }
        
        let lastRangeIndex = match.numberOfRanges - 1
        guard lastRangeIndex >= 1 else { return results }
        
        for i in 1...lastRangeIndex {
            let capturedGroupIndex = match.range(at: i)
            let matchedString = (self as NSString).substring(with: capturedGroupIndex)
            results.append(matchedString)
        }
        
        return results
    }
}
