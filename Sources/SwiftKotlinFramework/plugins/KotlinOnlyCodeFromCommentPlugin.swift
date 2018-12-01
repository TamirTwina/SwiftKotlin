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
    static let kotlinCodeRegex = "^!\\s*(\\w+):?\\s*(.*)"
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
        
        var sortedComments = topDeclaration
            .comments
            .filter({ $0.content.isKotlinCodeComment() })
            .sorted {
                $0.location.line < $1.location.line
        }
        
        var position = 0
        while position < tokens.count && !sortedComments.isEmpty {
            let token = tokens[position]
            let comment = sortedComments[0]
            var consumeComment = false
            
            if let tokenRange = token.sourceRange,
                tokenRange.isValid {
                
                if tokenRange.start.isAfter(location: comment.location) {
                    consumeComment = true
                }
            }
            
            if consumeComment,
            let node = token.node,
            let origin = token.origin,
            let stringGroups = extractedLineValue(comment.content,keyword: kotlinKeyword),
            let commentKeyword = stringGroups.first,
            commentKeyword == kotlinKeyword,
            let kotlineCodeAsIs = stringGroups.last {
                sortedComments.removeFirst()
                newTokens.append(origin.newToken(.string, kotlineCodeAsIs,node))
                newTokens.append(origin.newToken(.linebreak, "\n",node))
            } else {
                newTokens.append(token)
                position += 1
            }
        }
        
        newTokens += tokens[position...]
        
        while !sortedComments.isEmpty {
            let comment = sortedComments[0]
            newTokens.append(topDeclaration.newToken(.comment, comment.fomattedContent()))
            sortedComments.removeFirst()
        }
        
        return newTokens
    }
    
    
    private func extractedLineValue(_ comment: String,keyword:String) -> [String]? {
        let groups = comment.capturedGroups(withRegex: KotlinOnlyCodeFromComment.kotlinCodeRegex)
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
    

    func isKotlinCodeComment() -> Bool {
        
        let regex = try! NSRegularExpression(pattern: KotlinOnlyCodeFromComment.kotlinCodeRegex, options: .caseInsensitive)
        let foundMatch:Bool = regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: count)) != nil
        return foundMatch
    }

}
