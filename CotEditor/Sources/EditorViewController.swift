/*
 
 EditorViewController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by nakamuxu on 2006-03-18.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2017 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

final class EditorViewController: NSSplitViewController {
    
    // MARK: Public Properties
    
    var textStorage: NSTextStorage? {
        
        didSet {
            guard let textStorage = textStorage else { return }
            
            self.textView?.layoutManager?.replaceTextStorage(textStorage)
        }
    }
    
    var textView: EditorTextView? {
        
        return self.textViewController?.textView
    }
    
    var navigationBarController: NavigationBarController? {
        
        return self.navigationBarItem?.viewController as? NavigationBarController
    }
    
    
    // MARK: Private Properties
    
    @IBOutlet private weak var navigationBarItem: NSSplitViewItem?
    @IBOutlet private weak var textViewItem: NSSplitViewItem?
    
    
    
    // MARK: -
    // MARK: Split View Controller Methods
    
    /// setup UI
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.navigationBarController?.textView = self.textView
    }
    
    
    /// avoid showing draggable cursor
    override func splitView(_ splitView: NSSplitView, effectiveRect proposedEffectiveRect: NSRect, forDrawnRect drawnRect: NSRect, ofDividerAt dividerIndex: Int) -> NSRect {
        
        // -> must call super's delegate method anyway.
        super.splitView(splitView, effectiveRect: proposedEffectiveRect, forDrawnRect: drawnRect, ofDividerAt: dividerIndex)
        
        return .zero
    }
    
    
    /// validate actions
    override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        
        guard let action = item.action else { return false }
        
        switch action {
        case #selector(selectPrevItemOfOutlineMenu):
            return self.navigationBarController?.canSelectPrevItem ?? false
            
        case #selector(selectNextItemOfOutlineMenu):
            return self.navigationBarController?.canSelectNextItem ?? false
            
        default: break
        }
        
        return super.validateUserInterfaceItem(item)
    }
    
    
    
    // MARK: Public Methods
    
    /// Whether line number view is visible
    var showsLineNumber: Bool {
        
        get {
            return self.textViewController?.showsLineNumber ?? false
        }
        set {
            self.textViewController?.showsLineNumber = newValue
        }
    }
    
    
    /// Whether navigation bar is visible
    var showsNavigationBar: Bool {
        
        get {
            return !(self.navigationBarItem?.isCollapsed ?? true)
        }
        set {
            self.navigationBarItem?.isCollapsed = !newValue
        }
    }
    
    
    /// apply syntax style to inner text view
    func apply(syntax: SyntaxStyle) {
        
        self.textViewController?.syntaxStyle = syntax
    }
    
    
    
    // MARK: Action Messages
    
    /// select previous outline menu item (bridge action from menu bar)
    @IBAction func selectPrevItemOfOutlineMenu(_ sender: Any?) {
        
        self.navigationBarController?.selectPrevItemOfOutlineMenu(sender)
    }
    
    
    /// select next outline menu item (bridge action from menu bar)
    @IBAction func selectNextItemOfOutlineMenu(_ sender: Any?) {
        
        self.navigationBarController?.selectNextItemOfOutlineMenu(sender)
    }
    
    
    
    // MARK: Private Methods
    
    /// split view item to view controller
    private var textViewController: EditorTextViewController? {
        
        return self.textViewItem?.viewController as? EditorTextViewController
    }
    
}
