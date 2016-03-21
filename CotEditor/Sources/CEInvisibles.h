/*
 
 CEInvisibles.h
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-01-03.
 
 ------------------------------------------------------------------------------
 
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

@import Foundation;


typedef NS_ENUM(NSUInteger, CEInvisibleType) {
    CEInvisibleSpace,
    CEInvisibleTab,
    CEInvisibleNewLine,
    CEInvisibleFullWidthSpace,
    CEInvisibleVerticalTab,
    CEInvisibleReplacement,
};


@interface CEInvisibles : NSObject

+ (nonnull NSString *)stringWithType:(CEInvisibleType)type Index:(NSUInteger)index;

// return substitution character for invisible character
+ (unichar)spaceCharWithIndex:(NSUInteger)index;
+ (unichar)tabCharWithIndex:(NSUInteger)index;
+ (unichar)newLineCharWithIndex:(NSUInteger)index;
+ (unichar)fullwidthSpaceCharWithIndex:(NSUInteger)index;
+ (unichar)verticalTabChar;
+ (unichar)replacementChar;

// all available substitution characters
+ (nonnull NSArray<NSString *> *)spaceStrings;
+ (nonnull NSArray<NSString *> *)tabStrings;
+ (nonnull NSArray<NSString *> *)newLineStrings;
+ (nonnull NSArray<NSString *> *)fullwidthSpaceStrings;

@end
