/*
 
 DefinitionTableViewDelegate.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-09-08.
 
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

final class DefinitionTableViewDelegate: NSObject, NSTableViewDelegate {
    
    // MARK: Private Properties
    
    @IBOutlet private weak var arrayController: NSArrayController?
    
    
    
    // MARK: -
    // MARK: Delegate
    
    /// selection did change
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        guard let tableView = notification.object as? NSTableView, tableView.numberOfRows > 0 else { return }
        
        let row = tableView.selectedRow
        
        // start editing automatically if the leftmost cell of the added row is blank
        guard
            row + 1 == tableView.numberOfRows,  // the last row is selected
            let rowView = tableView.rowView(atRow: row, makeIfNecessary: true),
            let (column, textField) = (0 ..< rowView.numberOfColumns).lazy  // find the leftmost text field column
                .flatMap({ (column) -> (Int, NSTextField)? in
                    guard let textField = (rowView.view(atColumn: column) as? NSTableCellView)?.textField else { return nil }
                    return (column, textField)
                }).first,
            textField.stringValue.isEmpty
            else { return }
        
        tableView.scrollRowToVisible(row)
        tableView.editColumn(column, row: row, with: nil, select: true)
    }
    
    
    /// set action on swiping a table row
    @available(macOS 10.11, *)
    func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableRowActionEdge) -> [NSTableViewRowAction] {
        
        guard edge == .trailing else { return [] }
        guard let arrayController = self.arrayController else { return [] }
        
        // delete
        return [NSTableViewRowAction(style: .destructive,
                                     title: NSLocalizedString("Delete", comment: "table view action title"),
                                     handler: { (action: NSTableViewRowAction, row: Int) in
                                        NSAnimationContext.runAnimationGroup({ context in
                                            // update UI
                                            tableView.removeRows(at: IndexSet(integer: row), withAnimation: .slideLeft)
                                            }, completionHandler: {
                                                // update data
                                                arrayController.remove(atArrangedObjectIndex: row)
                                        })
        })]
    }
    
    
    
    // MARK: Action Messages
    
    /// update all selected checkboxes in the same column
    @IBAction func didCheckboxClicked(_ checkbox: NSButton) {
        
        // find tableView
        let superview = sequence(first: checkbox, next: { $0.superview }).first { (view: NSView) -> Bool in view is NSTableView }
        
        guard let tableView = superview as? NSTableView, tableView.numberOfSelectedRows > 1 else { return }
        
        let columnIndex = tableView.column(for: checkbox)
        
        guard columnIndex != -1 else { return }
        
        let identifier = tableView.tableColumns[columnIndex].identifier
        let isChecked = checkbox.state == NSOnState
        
        tableView.enumerateAvailableRowViews { (rowView: NSTableRowView, row: Int) in
            guard
                rowView.isSelected,
                let view = rowView.view(atColumn: columnIndex) as? NSTableCellView
                else { return }
            
            (view.objectValue as AnyObject?)?.setValue(NSNumber(value: isChecked), forKey: identifier)
        }
    }
    
}
