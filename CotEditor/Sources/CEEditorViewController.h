/*
 
 CEEditorViewController.h
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2006-03-18.
 
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

@import Cocoa;


@class CETextView;
@class CENavigationBarController;
@class CESyntaxStyle;


@interface CEEditorViewController : NSViewController <NSTextViewDelegate>

// readonly
@property (readonly, nonatomic, nullable) CETextView *textView;
@property (readonly, nonatomic, nullable) CENavigationBarController *navigationBarController;


// initializer
- (nonnull instancetype)initWithTextStorage:(nonnull NSTextStorage *)textStorage;

// Public method
- (void)setShowsLineNum:(BOOL)showsLineNum;
- (void)setShowsNavigationBar:(BOOL)showsNavigationBar animate:(BOOL)performAnimation;
- (void)applySyntax:(nonnull CESyntaxStyle *)syntaxStyle;

// action messages
- (IBAction)selectPrevItemOfOutlineMenu:(nullable id)sender;
- (IBAction)selectNextItemOfOutlineMenu:(nullable id)sender;

@end
