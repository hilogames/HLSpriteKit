//
//  HLAction.h
//  Gargoyles
//
//  Created by Karl Voskuil on 12/22/16.
//  Copyright © 2016 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

typedef NS_ENUM(NSInteger, HLActionTimingMode) {
  HLActionTimingModeLinear,
  HLActionTimingModeEaseIn,
  HLActionTimingModeEaseOut,
  HLActionTimingModeEaseInEaseOut,
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
