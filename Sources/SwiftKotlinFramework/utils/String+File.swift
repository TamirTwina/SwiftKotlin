//
//  String+File.swift
//  SwiftKotlinApp
//
//  Created by Tamir Twina on 6/24/18.
//

import Foundation

extension String {
    func writeToFile(toUrl url: URL) {
        guard let data = self.data(using: .utf8) else {
            return
        }
        
        if FileManager.default.fileExists(atPath: url.path) {
            //Overwrite existing file by deleting it
            try? FileManager.default.removeItem(at: url)
        }
        
        try? data.write(to: url, options: .atomic)
    }
}
