//
//  NSGestureRecognizer+MultipleActions.h
//  HLSpriteKit
//
//  Created by Brent Traut on 10/3/16.
//  Copyright © 2016 Hilo Games. All rights reserved.
//

#import <TargetConditionals.h>

#if ! TARGET_OS_IPHONE

#import <Cocoa/Cocoa.h>

/**
 Out of the box, NSGestureRecognizer only allows for one target+action unlike its
 UIGestureRecognizer counterpart which allows for multiple.
 NSGestureRecognizer_MultipleActions adds the ability to add multiple targets+actions.

 After registering all targets+actions with addTarget:action:, the NSGestureRecognizer
 must set its main target+action to this category's own handleGesture:.
*/
@interface NSGestureRecognizer (NSGestureRecognizer_MultipleActions)

/**
 Categories aren't typically allowed to add properties to a class, but a common
 workaround using objc_getAssociatedObject and objc_setAssociatedObject is used:
 http://stackoverflow.com/questions/4146183/instance-variables-for-objective-c-categories
*/
@property (nonatomic, strong) NSMutableArray *targetActionPairs;

/**
 Save a target+action pair for later.

 action must follow one of the signatures as NSGestureRecognizer's main action property:
 - (void)handleGesture;
 - (void)handleGesture:(NSGestureRecognizer *)gestureRecognizer;
*/
- (void)addTarget:(id)target action:(SEL)action;

/**
 Remove a target+action pair.
*/
- (void)removeTarget:(id)target action:(SEL)action;

/**
 Automatically propogate the gesture recognizer handler call to all of the
 targets+actions registered in addTarget:action:.
*/
- (void)handleGesture:(NSGestureRecognizer *)gestureRecognizer;

@end

#endif
