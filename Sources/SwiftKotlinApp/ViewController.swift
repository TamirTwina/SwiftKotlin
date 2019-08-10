//
//  ViewController.swift
//  SwiftKotlinApp
//
//  Created by Angel Garcia on 09/11/16.
//  Copyright © 2016 Angel G. Olloqui. All rights reserved.
//

import Cocoa
import SwiftKotlinFramework
import Transform

class ViewController: NSViewController,NSOpenSavePanelDelegate {
    var lastUsedURL: URL?

    let swiftTokenizer = SwiftTokenizer(
        tokenTransformPlugins: [
            CommentsAdditionTransformPlugin()
        ]
    )
    let kotlinTokenizer = KotlinTokenizer(
        sourceTransformPlugins: [
            GeneratedHeaderCommentPlugin()
        ],
        tokenTransformPlugins: [
            XCTTestToJUnitTokenTransformPlugin(),
            FoundationMethodsTransformPlugin(),
            CommentsAdditionTransformPlugin(),
            KotlinOnlyCodeFromComment()
        ]
    )
    
    @IBOutlet var swiftTextView: NSTextView!
    @IBOutlet var kotlinTextView: NSTextView!
    @IBOutlet var feedbackTextField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.swiftTextView.isAutomaticQuoteSubstitutionEnabled = false
        self.swiftTextView.isAutomaticDashSubstitutionEnabled = false
        self.swiftTextView.isAutomaticTextReplacementEnabled = false
        self.kotlinTextView.isAutomaticQuoteSubstitutionEnabled = false
        self.kotlinTextView.isAutomaticDashSubstitutionEnabled = false
        self.kotlinTextView.isAutomaticTextReplacementEnabled = false
        
        self.translateSwift()
    }
    
    @IBAction func openSwiftFile(_ sender: AnyObject) {
        let oPanel: NSOpenPanel = NSOpenPanel()
        oPanel.canChooseDirectories = false
        oPanel.canChooseFiles = true
        oPanel.allowsMultipleSelection = false
        oPanel.allowedFileTypes = ["swift"]
        oPanel.prompt = "Open"
        
        oPanel.beginSheetModal(for: self.view.window!, completionHandler: { (button: NSApplication.ModalResponse) -> Void in
            if button == NSApplication.ModalResponse.OK {
                let filePath = oPanel.urls.first!.path
                self.lastUsedURL = oPanel.urls.first
                let fileHandle = FileHandle(forReadingAtPath: filePath)
                if let data = fileHandle?.readDataToEndOfFile() {
                    self.swiftTextView.textStorage?.beginEditing()
                    self.swiftTextView.textColor = NSColor.black
                    self.swiftTextView.string = String(data: data, encoding: .utf8) ?? ""
                    self.swiftTextView.textStorage?.endEditing()
                    self.translateSwift()
                }
            }
        })
    }
    
    
    @IBAction func saveSwift(_ sender: Any) {
        NSLog("Save file")
        let savePanel = NSSavePanel()
        savePanel.delegate = self
        savePanel.title = "Save swift file"
        savePanel.nameFieldStringValue = "New File"
        savePanel.showsTagField = false
        if let currentUrl = self.lastUsedURL {
            savePanel.directoryURL = currentUrl.deletingLastPathComponent()
            savePanel.nameFieldStringValue = currentUrl.lastPathComponent
        }
        savePanel.beginSheetModal(for: self.view.window!, completionHandler: {(result) in

            if result == NSApplication.ModalResponse.OK,
            let saveUrl = savePanel.url {
                self.lastUsedURL = nil
                print("Saving file to: \(saveUrl)")
                let swiftCode = self.swiftTextView.string
                if let _ = try? swiftCode.write(toFile: saveUrl.absoluteString, atomically: true, encoding: .utf8) {
                    // File saved correctly
                } else {
                    self.feedbackTextField.textColor = NSColor.red
                    self.feedbackTextField.stringValue = "❌ Failed to save file"
                }
                
            }
        })


    }
    
    
    @IBAction func formatSwift(_ sender: AnyObject) {
        let swift = swiftTextView.string
        let result = swiftTokenizer.translate(content: swift)
        updateFeedback(result: result)
        guard let swiftTokens = result.tokens else {
            return
        }
        let formatted = self.attributedStringFromTokens(tokens: swiftTokens)
        self.swiftTextView.textStorage?.beginEditing()
        self.swiftTextView.textStorage?.setAttributedString(formatted)
        self.swiftTextView.textStorage?.endEditing()
    }
    
    func translateSwift() {
        let swift = swiftTextView.string
        let result = kotlinTokenizer.translate(content: swift)
        updateFeedback(result: result)
        guard let kotlinTokens = result.tokens else {
            return
        }
        DispatchQueue.main.async {
            self.kotlinTextView.textStorage?.beginEditing()
            let formatted = self.attributedStringFromTokens(tokens: kotlinTokens)
            self.kotlinTextView.textStorage?.setAttributedString(formatted)
            self.kotlinTextView.textStorage?.endEditing()
        }
    }
    
    func attributedStringFromTokens(tokens: [Token]) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        tokens.forEach {
            attributedString.append($0.attributedString)
        }
        return attributedString
    }
    
    func updateFeedback(result: TokenizationResult) {
        if let exception = result.exception {
            feedbackTextField.textColor = NSColor.red
            feedbackTextField.stringValue = "❌ - \(exception.localizedDescription)"
        } else if !result.diagnostics.isEmpty {
            if let error = result.diagnostics.filter({ $0.level != .warning }).first {
                self.feedbackTextField.textColor = NSColor.red
                self.feedbackTextField.stringValue = "❌ Line \(error.location.line) Col \(error.location.column) - \(error.kind.diagnosticMessage)"
            } else {
                let warn = result.diagnostics.first!
                feedbackTextField.textColor = NSColor.yellow
                feedbackTextField.stringValue =  "⚠️ Line \(warn.location.line) Col \(warn.location.column) - \(warn.kind.diagnosticMessage)"
            }
        } else {
            feedbackTextField.stringValue = "✅"
        }
    }
}

extension ViewController: NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        translateSwift()
    }
}

extension Token {
    var attributes: [NSAttributedString.Key : Any] {
        switch self.kind {
        case .keyword:
            return [NSAttributedString.Key.foregroundColor: NSColor(red: 170.0/255.0, green: 13.0/255.0, blue: 145.0/255.0, alpha: 1)]
        case .number:
            return [NSAttributedString.Key.foregroundColor: NSColor(red: 28.0/255.0, green: 0.0/255.0, blue: 207.0/255.0, alpha: 1)]
        case .string:
            return [NSAttributedString.Key.foregroundColor: NSColor(red: 196.0/255.0, green: 26.0/255.0, blue: 22.0/255.0, alpha: 1)]
        case .comment:
            return [NSAttributedString.Key.foregroundColor: NSColor(red: 0, green: 116.0/255.0, blue: 0, alpha: 1)]
            
        default:
            if #available(OSX 10.14, *)
            {
                return [NSAttributedString.Key.foregroundColor: NSApp.mainWindow?.effectiveAppearance.name == .darkAqua ? NSColor.white : NSColor.black]
            } else {
                return [:]
            }
        }
    }
    
    var attributedString: NSAttributedString {
        return NSAttributedString(string: self.value, attributes: self.attributes)
    }
}

