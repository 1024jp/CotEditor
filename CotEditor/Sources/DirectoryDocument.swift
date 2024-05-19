//
//  DirectoryDocument.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-05-01.
//
//  ---------------------------------------------------------------------------
//
//  © 2024 1024jp
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import AppKit
import Observation
import UniformTypeIdentifiers
import OSLog

@Observable final class DirectoryDocument: NSDocument {
    
    private enum SerializationKey {
        
        static let documents = "documents"
    }
    
    
    // MARK: Public Properties
    
    private(set) var fileNode: FileNode?
    private(set) weak var currentDocument: Document?
    
    
    // MARK: Private Properties
    
    private var documents: [Document] = []
    private var windowController: DocumentWindowController?  { self.windowControllers.first as? DocumentWindowController }
    
    
    
    // MARK: Document Methods
    
    override class var autosavesInPlace: Bool {
        
        true  // for moving location from the proxy icon
    }
    
    
    override class func canConcurrentlyReadDocuments(ofType typeName: String) -> Bool {
        
        true
    }
    
    
    override func encodeRestorableState(with coder: NSCoder, backgroundQueue queue: OperationQueue) {
        
        super.encodeRestorableState(with: coder, backgroundQueue: queue)
        
        let fileData = self.documents
            .compactMap(\.fileURL)
            .compactMap { try? $0.bookmarkData(options: .withSecurityScope) }
        coder.encode(fileData, forKey: SerializationKey.documents)
    }
    
    
    override func restoreState(with coder: NSCoder) {
        
        super.restoreState(with: coder)
        
        if let fileData = coder.decodeArrayOfObjects(ofClass: NSData.self, forKey: SerializationKey.documents) as? [Data] {
            let fileURLs = fileData.compactMap {
                var isStale = false
                return try? URL(resolvingBookmarkData: $0, options: .withSecurityScope, bookmarkDataIsStale: &isStale)
            }
            Task {
                for fileURL in fileURLs {
                    await self.openDocument(at: fileURL)
                }
            }
        }
    }
    
    
    override func makeWindowControllers() {
        
        let document = Document()
        self.documents.append(document)
        NSDocumentController.shared.addDocument(document)
        
        let windowController = DocumentWindowController(document: document, directoryDocument: self)
        self.addWindowController(windowController)
        
        document.windowController = windowController
    }
    
    
    override nonisolated func read(from url: URL, ofType typeName: String) throws {
        
        let fileWrapper = try FileWrapper(url: url)
        let node = FileNode(fileWrapper: fileWrapper, fileURL: url)
        
        Task { @MainActor in
            self.fileNode = node
            self.windowController?.synchronizeWindowTitleWithDocumentName()
        }
    }
    
    
    override func data(ofType typeName: String) throws -> Data {
        
        fatalError("\(self.className) is readonly")
    }
    
    
    override func move(to url: URL) async throws {
        
        try await super.move(to: url)
        
        // remake node tree
        self.revert()
    }
    
    
    override func shouldCloseWindowController(_ windowController: NSWindowController, delegate: Any?, shouldClose shouldCloseSelector: Selector?, contextInfo: UnsafeMutableRawPointer?) {
        
        Task {
            // save unsaved changes in the file documents before closing
            var canClose = true
            for document in self.documents where document.isDocumentEdited {
                // ask to the user one-by-one
                guard await document.canClose() else {
                    canClose = false
                    break
                }
            }
            
            DelegateContext(delegate: delegate, selector: shouldCloseSelector, contextInfo: contextInfo).perform(from: self, flag: canClose)
        }
    }
    
    
    override func close() {
        
        super.close()
        
        for document in self.documents {
            document.close()
        }
    }
    
    
    // MARK: File Presenter Methods
    
    override nonisolated func presentedItemDidChange() {
        
        // called also when:
        // - subitem moved (presentedSubitem(at:didMoveTo:))
        // - new subitem added (presentedSubitemDidAppear(at:))
        
        super.presentedItemDidChange()
        
        // remake node tree
        Task { @MainActor in
            self.revert()
        }
    }
    
    
    override nonisolated func presentedItemDidMove(to newURL: URL) {
        
        super.presentedItemDidMove(to: newURL)
        
        // remake fileURLs with the new location
        Task { @MainActor in
            self.revert(fileURL: newURL)
        }
    }
    
    
    // MARK: Public Methods
    
    /// Opens a document as a member.
    ///
    /// - Parameter fileURL: The file URL of the document to open.
    /// - Returns: Return `true` if the document of the given file did successfully open.
    @discardableResult func openDocument(at fileURL: URL) async -> Bool {
        
        assert(!fileURL.hasDirectoryPath)
        
        guard fileURL != self.currentDocument?.fileURL else { return true }  // already open
        
        // existing document
        if let document = NSDocumentController.shared.document(for: fileURL) as? Document {
            if self.documents.contains(document) {
                self.changeFrontmostDocument(to: document)
                return true
                
            } else {
                return await withCheckedContinuation { continuation in
                    self.presentErrorAsSheet(DirectoryDocumentError.alreadyOpen(fileURL)) { _ in
                        document.showWindows()
                        continuation.resume(returning: false)
                    }
                }
            }
        }
        
        let contentType = try? fileURL.resourceValues(forKeys: [.contentTypeKey]).contentType
        
        // ignore (possibly) unsupported files
        guard contentType?.conforms(to: .text) == true || fileURL.pathExtension.isEmpty,
              fileURL.lastPathComponent != ".DS_Store"
        else { return true }
        
        // make document
        let document: NSDocument
        do {
            document = try NSDocumentController.shared.makeDocument(withContentsOf: fileURL, ofType: (contentType ?? .data).identifier)
        } catch {
            self.presentErrorAsSheet(error)
            return false
        }
        
        guard let document = document as? Document else { return false }
        
        self.documents.append(document)
        NSDocumentController.shared.addDocument(document)
        
        self.changeFrontmostDocument(to: document)
        
        return true
    }
    
    
    // MARK: Private Methods
    
    /// Changes the frontmost document.
    ///
    /// - Parameter document: The document to bring frontmost.
    private func changeFrontmostDocument(to document: Document) {
        
        assert(self.documents.contains(document))
        
        // remove window controller from current document
        self.windowController?.fileDocument?.windowController = nil
        
        document.windowController = self.windowController
        self.windowController?.fileDocument = document
        self.currentDocument = document
        document.makeWindowControllers()
        
        // clean-up
        self.disposeUnusedDocuments()
    }
    
    
    /// Disposes unused documents.
    private func disposeUnusedDocuments() {
        
        // -> postpone closing opened document if edited
        for document in self.documents where !document.isDocumentEdited && document != self.currentDocument {
            document.close()
            self.documents.removeFirst(document)
        }
        self.invalidateRestorableState()
    }
}


private enum DirectoryDocumentError: LocalizedError {
    
    case alreadyOpen(URL)
    
    
    var errorDescription: String? {
        
        switch self {
            case .alreadyOpen(let fileURL):
                String(localized: "DirectoryDocumentError.alreadyOpen.description", defaultValue: "The file “\(fileURL.lastPathComponent)” is already open in a different window.")
        }
    }
    
    
    var recoverySuggestion: String? {
        
        switch self {
            case .alreadyOpen:
                String(localized: "DirectoryDocumentError.alreadyOpen.recoverySuggestion", defaultValue: "To open it in this window, close the existing window first.", comment: "“it” is the file in description.")
        }
    }
}
