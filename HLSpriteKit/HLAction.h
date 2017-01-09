//
//  HLAction.h
//  Gargoyles
//
//  Created by Karl Voskuil on 12/22/16.
//  Copyright © 2016 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

typedef NS_ENUM(NSInteger, HLActionTimingMode) {
  HLActionTimingLinear,
  HLActionTimingEaseIn,
  HLActionTimingEaseOut,
  HLActionTimingEaseInEaseOut,
};

@class HLAction;

@interface HLActionRunner : NSObject <NSCoding>

- (instancetype)init;

- (void)update:(NSTimeInterval)elapsedTime node:(SKNode *)node;

- (void)runAction:(HLAction *)action forKey:(NSString *)key;

- (BOOL)hasActions;

- (HLAction *)actionForKey:(NSString *)key;

- (void)removeActionForKey:(NSString *)key;

- (void)removeAllActions;

@end

@interface HLAction : NSObject <NSCoding>

- (instancetype)initWithDuration:(NSTimeInterval)duration;

@property (nonatomic, assign) NSTimeInterval duration;

@property (nonatomic, readonly) NSTimeInterval elapsedTime;

@property (nonatomic, assign) HLActionTimingMode timingMode;

- (BOOL)update:(NSTimeInterval)elapsedTime node:(SKNode *)node;

@end

@interface HLGroupAction : HLAction <NSCoding>

- (instancetype)initWithActions:(NSArray *)actions;

@end

@interface HLSequenceAction : HLAction <NSCoding>

- (instancetype)initWithActions:(NSArray *)actions;

@end

@interface HLWaitAction : HLAction <NSCoding>

@end

@interface HLMoveToAction : HLAction <NSCoding>

- (instancetype)initWithDestination:(CGPoint)destination duration:(NSTimeInterval)duration;

@end

@interface HLCustomAction : HLAction <NSCoding>

- (instancetype)initWithWeakTarget:(id)weakTarget
                          selector:(SEL)selector
                          duration:(NSTimeInterval)duration
                          userData:(id)userData;

@end

@interface HLAction (HLActions)

+ (HLGroupAction *)group:(NSArray *)actions;

+ (HLSequenceAction *)sequence:(NSArray *)actions;

+ (HLWaitAction *)waitForDuration:(NSTimeInterval)duration;

+ (HLMoveToAction *)moveTo:(CGPoint)destination duration:(NSTimeInterval)duration;

+ (HLCustomAction *)customActionWithDuration:(NSTimeInterval)duration
                                    selector:(SEL)selector
                                  weakTarget:(id)weakTarget
                                    userData:(id)userData;
@end

/**
 A commonly-useful encodable user data object to use with `HLCustomAction`.

 A common use case for `HLCustomAction` is tweening between two values (whether position,
 alpha, scale, or something else), which can be tracked by this user data object.  In the
 following example, a user data object is provided to the custom action in order to track
 a start and finish value for an overshooting slide.

     - (void)slideUpdate:(SKNode *)node
             elapsedTime:(CGFloat)elapsedTime
                duration:(NSTimeInterval)duration
                userData:(HLCustomActionEndPoints *)userData
     {
       CGFloat normalTime = (CGFloat)(elapsedTime / duration);
       CGFloat normalValue = BackStandardEaseInOut(normalTime);
       node.position = CGPointMake(userData.start * (1.0f - normalValue) + userData.finish * normalValue, 0.0f);
     }

     - (void)slideNode:(SKNode *)node
     {
       HLCustomActionTwoValues *slideUserData = [[HLCustomActionTwoValues alloc] init];
       slideUserData.start = node.position.x;
       slideUserData.finish = self.size.width / 2.0f;

       HLCustomAction *slideAction = [HLAction customActionWithDuation:2.0
                                                              selector:@selector(slideUpdate:elapsedTime:duration:userData:)
                                                            WeakTarget:self
                                                              userData:slideUserData];
       [_actionRunner runAction:slideAction.action];
     }
*/
@interface HLCustomActionTwoValues : NSObject <NSCoding>

@property (nonatomic, assign) CGFloat start;

@property (nonatomic, assign) CGFloat finish;

@end

/**
 A commonly-useful encodable user data object to use with `HLCustomAction`.

 See notes for `HLCustomActionTwoValues`.  This is the same idea, but offering a start
 and finish `CGPoint` rather than `CGFloat`.
*/
@interface HLCustomActionTwoPoints : NSObject <NSCoding>

@property (nonatomic, assign) CGPoint start;

@property (nonatomic, assign) CGPoint finish;

@end
