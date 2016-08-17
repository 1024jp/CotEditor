/*
 
 EncodingListViewController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-03-26.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

final class EncodingListViewController: NSViewController, NSTableViewDelegate {
    
    // MARK: Private Properties
    
    private dynamic var encodings: [NSNumber] {
        didSet {
            // validate restorebility
            self.canRestore = (encodings != self.defaultEncodings)
        }
    }
    private let defaultEncodings: [NSNumber]
    private dynamic var canRestore: Bool  // enability of "Restore Default" button
    
    @IBOutlet private weak var tableView: NSTableView?
    @IBOutlet private weak var deleteSeparatorButton: NSButton?
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    override init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        
        self.defaultEncodings = NSUserDefaultsController.shared().initialValues?[DefaultKeys.encodingList.rawValue] as! [NSNumber]
        self.encodings = Defaults[.encodingList]
        self.canRestore = (self.encodings != self.defaultEncodings)
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override var nibName: String? {
        
        return "EncodingListView"
    }
    
    
    
    // MARK: Table View Delegate
    
    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        
        guard let textField = (rowView.view(atColumn: 0)  as? NSTableCellView)?.textField else { return }
        
        let cfEncoding = CFStringEncoding(self.encodings[row].uint32Value)
        
        // separator
        if cfEncoding == kCFStringEncodingInvalidId {
            textField.stringValue = String.separator
            return
        }
        
        // styled encoding name
        let encoding = String.Encoding(cfEncoding: cfEncoding)
        let encodingName = String.localizedName(of: encoding)
        let attrEncodingName = NSAttributedString(string: encodingName)
        
        let ianaName = (CFStringConvertEncodingToIANACharSetName(cfEncoding) as String?) ?? "-"
        let attrIanaName = NSAttributedString(string: " : " + ianaName,
                                              attributes: [NSForegroundColorAttributeName: NSColor.disabledControlTextColor])
        
        textField.attributedStringValue = attrEncodingName + attrIanaName
    }
    
    
    /// update UI just after selected rows are changed
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        // update enability of "Delete Separator" button
        self.deleteSeparatorButton?.isEnabled = {
            for index in self.tableView!.selectedRowIndexes.sorted() {
                let encoding = self.encodings[index].uint32Value
                
                if encoding == kCFStringEncodingInvalidId {
                    return true
                }
            }
            
            return false
        }()
    }
    
    
    @available(macOS 10.11, *)
    /// set action on swiping row
    func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableRowActionEdge) -> [NSTableViewRowAction] {
        
        guard edge == .trailing else { return [] }
        
        // only separater can be removed
        guard self.encodings[row].uint32Value == kCFStringEncodingInvalidId else { return [] }
        
        // delete
        return [NSTableViewRowAction(style: .destructive,
                                     title: NSLocalizedString("Delete", comment: "table view action title"),
                                     handler: { (action: NSTableViewRowAction, row: Int) in
                                        NSAnimationContext.runAnimationGroup({ context in
                                            // update UI
                                            tableView.removeRows(at: IndexSet(integer: row), withAnimation: .slideLeft)
                                            }, completionHandler: { [weak self] in
                                                // update data
                                                self?.encodings.remove(at: row)
                                        })
            })]
    }
    
    
    
    // MARK: Action Messages
    
    /// "OK" button was clicked
    @IBAction func save(_ sender: AnyObject?) {
        
        // write back current encoding list userDefaults
        Defaults[.encodingList] = self.encodings
        
        self.dismiss(sender)
    }
    
    
    /// restore encoding setting to default
    @IBAction func revertDefaultEncodings(_ sender: AnyObject?) {
        
        self.encodings = self.defaultEncodings
        self.tableView?.reloadData()
    }
    
    
    /// add separator below the selection
    @IBAction func addSeparator(_ sender: AnyObject?) {
        
        let index = self.tableView!.selectedRow + 1
        
        self.addSeparator(at: index)
    }
    
    
    /// remove separator
    @IBAction func deleteSeparator(_ sender: AnyObject?) {
        
        let indexes = self.tableView!.selectedRowIndexes
        
        self.deleteSeparators(at: indexes)
    }
    
    
    
    // MARK: Private Methods
    
    /// add separator to desired row
    private func addSeparator(at rowIndex: Int) {
        
        guard let tableView = self.tableView else { return }
        
        let indexes = IndexSet(integer: rowIndex)
        
        NSAnimationContext.runAnimationGroup({ context in
            // update UI
            tableView.insertRows(at: indexes, withAnimation: .effectGap)
            }, completionHandler: { [weak self] in
                // update data
                let item = NSNumber(value: kCFStringEncodingInvalidId)
                self?.encodings.insert(item, at: rowIndex)
                
                tableView.selectRowIndexes(indexes, byExtendingSelection: false)
        })
    }
    
    
    /// remove separators at desired rows
    private func deleteSeparators(at rowIndexes: IndexSet) {
        
        // pick only separators up
        var toDeleteIndexes = IndexSet()
        for index in rowIndexes.sorted() {
            let encoding = self.encodings[index].uint32Value
            
            if encoding == kCFStringEncodingInvalidId {
                toDeleteIndexes.insert(index)
            }
        }
        guard !toDeleteIndexes.isEmpty else { return }
        
        guard let tableView = self.tableView else { return }
        
        NSAnimationContext.runAnimationGroup({ context in
            // update UI
            tableView.removeRows(at: toDeleteIndexes, withAnimation: [.slideUp, .effectFade])
            }, completionHandler: { [weak self] in
                // update data
                self?.encodings.remove(in: toDeleteIndexes)
        })
    }
    
}
