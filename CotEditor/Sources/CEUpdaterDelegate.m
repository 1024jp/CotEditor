/*
 ==============================================================================
 CEUpdaterDelegate
 
 CotEditor
 http://coteditor.com
 
 Created on 2015-05-01 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2015 CotEditor Project
 
 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License along with
 this program; if not, write to the Free Software Foundation, Inc., 59 Temple
 Place - Suite 330, Boston, MA  02111-1307, USA.
 
 ==============================================================================
 */

#import "CEUpdaterDelegate.h"
#import "EDSemver.h"


@implementation CEUpdaterDelegate

#pragma mark Delegate

//=======================================================
// SUUpdaterDelegate
//=======================================================

// ------------------------------------------------------
/// compare updater versions by myself
- (id <SUVersionComparison>)versionComparatorForUpdater:(SUUpdater *)updater
// ------------------------------------------------------
{
    return self;
}


// ------------------------------------------------------
/// force displaying release notes to nofity App Store migration
- (void)updater:(SUUpdater *)updater didFindValidUpdate:(SUAppcastItem *)update
// ------------------------------------------------------
{
    /// !!!: This method should be removed after updating CotEditor to the first Mac App Store version.
    NSString *thisVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    EDSemver *thisSemver = [EDSemver semverWithString:thisVersion];
    EDSemver *newSemver = [EDSemver semverWithString:[update versionString]];
    EDSemver *appStoreSemver = [EDSemver semverWithString:@"2.2.0"];
    
    if (([newSemver isEqualTo:appStoreSemver] || [newSemver isGreaterThan:appStoreSemver])
        && [thisSemver isLessThan:appStoreSemver])
    {
        // once reset the silent updating on Sparkle in order to announce the release of Mac App Store version to everyone.
        [[NSUserDefaults standardUserDefaults] setBool:@YES forKey:@"SUShowReleaseNotes"];
    }
}


//=======================================================
// SUVersionComparison Protocol
//=======================================================

// ------------------------------------------------------
/// compare versions using the Semantic Versioning 2.0
- (NSComparisonResult)compareVersion:(NSString *)versionA toVersion:(NSString *)versionB
// ------------------------------------------------------
{
    EDSemver *semverA = [EDSemver semverWithString:versionA];
    EDSemver *semverB = [EDSemver semverWithString:versionB];
    
    return [semverA compare:semverB];
}

@end
