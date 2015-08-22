/*
 
 CEGeneralPaneController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2015-07-15.

 ------------------------------------------------------------------------------
 
 © 2015 1024jp
 
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

#import "CEGeneralPaneController.h"

#ifndef APPSTORE
#import "CEUpdaterManager.h"
#endif


@interface CEGeneralPaneController ()

@property (nonatomic) BOOL hasUpdater;
@property (nonatomic, getter=isPrerelease) BOOL prerelease;

@end




#pragma mark -

@implementation CEGeneralPaneController

// ------------------------------------------------------
/// setup UI
- (void)viewDidLoad
// ------------------------------------------------------
{
    [super viewDidLoad];
    
    // remove updater option on AppStore ver.
#ifdef APPSTORE
    // cut down height for updater checkbox
    NSRect frame = [[self view] frame];
    frame.size.height -= 73;
    [[self view] setFrame:frame];
#else
    [self setHasUpdater:YES];
    
    if ([[CEUpdaterManager sharedManager] isPrerelease]) {
        [self setPrerelease:YES];
    } else {
        // cut down height for pre-release note
        NSRect frame = [[self view] frame];
        frame.size.height -= 18;
        [[self view] setFrame:frame];
    }
#endif
}

@end
