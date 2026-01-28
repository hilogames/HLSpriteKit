//
//  HLActionTests.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 2/17/17.
//  Copyright © 2017 Hilo Games. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "HLAction.h"

@interface HLActionTests : XCTestCase

@end

@implementation HLActionTests
{
  NSUInteger _counter;
}

- (void)HL_incrementCounter
{
  ++_counter;
}

- (void)testAction
{
  // Completion
  {
    HLAction *action = [HLAction waitForDuration:1.0];
    XCTAssertFalse([action update:1.1 node:nil]);
    XCTAssertGreaterThan(action.elapsedTime, action.duration);
  }
  {
    HLAction *action = [HLAction waitForDuration:1.0];
    XCTAssertTrue([action update:0.3 node:nil]);
    XCTAssertTrue([action update:0.3 node:nil]);
    XCTAssertTrue([action update:0.3 node:nil]);
    XCTAssertFalse([action update:0.3 node:nil]);
    XCTAssertGreaterThan(action.elapsedTime, action.duration);
  }

  // Timing mode
  {
    HLAction *action = [HLAction waitForDuration:1.0];
    action.timingMode = HLActionTimingEaseInEaseOut;
    XCTAssertTrue([action update:0.25 node:nil]);
    XCTAssertLessThan(action.elapsedTime, 0.25);
    XCTAssertTrue([action update:0.25 node:nil]);
    XCTAssertEqualWithAccuracy(action.elapsedTime, 0.5, 0.01);
    XCTAssertTrue([action update:0.25 node:nil]);
    XCTAssertGreaterThan(action.elapsedTime, 0.75);
    XCTAssertFalse([action update:0.3 node:nil]);
    XCTAssertGreaterThan(action.elapsedTime, action.duration);
  }

  // Speed
  {
    HLAction *action = [HLAction waitForDuration:1.0];
    action.speed = 2.0f;
    XCTAssertTrue([action update:0.3 node:nil]);
    XCTAssertFalse([action update:0.3 node:nil]);
    XCTAssertGreaterThan(action.elapsedTime, action.duration);
  }
  {
    HLAction *action = [HLAction waitForDuration:1.0];
    action.speed = 0.5f;
    XCTAssertTrue([action update:0.3 node:nil]);
    XCTAssertTrue([action update:0.3 node:nil]);
    XCTAssertTrue([action update:0.3 node:nil]);
    XCTAssertTrue([action update:0.3 node:nil]);
    XCTAssertTrue([action update:0.3 node:nil]);
    XCTAssertTrue([action update:0.3 node:nil]);
    XCTAssertFalse([action update:0.3 node:nil]);
    XCTAssertGreaterThan(action.elapsedTime, action.duration);
  }
}

- (void)testGroupAction
{
  // Group updates
  {
    HLAction *action1 = [HLAction waitForDuration:1.0];
    HLAction *action2 = [HLAction waitForDuration:1.0];
    HLGroupAction *groupAction = [HLAction group:@[ action1, action2 ]];
    XCTAssertEqual([groupAction.actions count], 2);
    XCTAssertFalse([groupAction update:1.1 node:nil]);
    XCTAssertEqual([groupAction.actions count], 0);
    XCTAssertGreaterThan(action1.elapsedTime, action1.duration);
    XCTAssertGreaterThan(action2.elapsedTime, action2.duration);
  }

  // Removal of individual actions
  {
    HLAction *shortAction = [HLAction waitForDuration:1.0];
    HLAction *longAction = [HLAction waitForDuration:2.0];
    HLGroupAction *groupAction = [HLAction group:@[ shortAction, longAction ]];
    XCTAssertTrue([groupAction update:0.6 node:nil]);
    XCTAssertEqual([groupAction.actions count], 2);
    XCTAssertTrue([groupAction update:0.5 node:nil]);
    XCTAssertEqual([groupAction.actions count], 1);
    XCTAssertTrue([groupAction update:0.5 node:nil]);
    XCTAssertEqual([groupAction.actions count], 1);
    XCTAssertFalse([groupAction update:0.5 node:nil]);
    XCTAssertEqual([groupAction.actions count], 0);
  }

  // Complete before duration with fast action
  {
    HLAction *fastAction = [HLAction waitForDuration:1.0];
    fastAction.speed = 2.0f;
    HLGroupAction *groupAction = [HLAction group:@[ fastAction ]];
    XCTAssertFalse([groupAction update:0.6 node:nil]);
    XCTAssertLessThan(groupAction.elapsedTime, groupAction.duration);
  }

  // But timely completion if normal action in fast group
  {
    HLAction *normalAction = [HLAction waitForDuration:1.0];
    HLGroupAction *groupAction = [HLAction group:@[ normalAction ]];
    groupAction.speed = 2.0f;
    XCTAssertFalse([groupAction update:0.6 node:nil]);
    XCTAssertEqualWithAccuracy(groupAction.elapsedTime, groupAction.duration, 0.2);
  }
  
  // Complete (long) after duration with slow action
  {
    HLAction *slowAction = [HLAction waitForDuration:1.0];
    slowAction.speed = 0.5f;
    HLGroupAction *groupAction = [HLAction group:@[ slowAction ]];
    XCTAssertTrue([groupAction update:1.1 node:nil]);
    XCTAssertFalse([groupAction update:1.0 node:nil]);
    XCTAssertGreaterThan(groupAction.elapsedTime, 2.0);
  }

  // But timely completion if normal action in slow group
  {
    HLAction *normalAction = [HLAction waitForDuration:1.0];
    HLGroupAction *groupAction = [HLAction group:@[ normalAction ]];
    groupAction.speed = 0.5f;
    XCTAssertTrue([groupAction update:1.1 node:nil]);
    XCTAssertFalse([groupAction update:1.0 node:nil]);
    XCTAssertEqualWithAccuracy(groupAction.elapsedTime, groupAction.duration, 0.2);
  }

  // Handling multiple actions with various speeds
  {
    HLAction *normalAction = [HLAction waitForDuration:1.0];
    HLAction *fastAction = [HLAction waitForDuration:1.0];
    fastAction.speed = 2.0;
    HLAction *slowAction = [HLAction waitForDuration:1.0];
    slowAction.speed = 0.5;
    HLGroupAction *groupAction = [HLAction group:@[ normalAction, fastAction, slowAction ]];
    XCTAssertEqual([groupAction.actions count], 3);
    XCTAssertTrue([groupAction update:0.6 node:nil]);
    XCTAssertEqual([groupAction.actions count], 2);
    XCTAssertGreaterThan(fastAction.elapsedTime, fastAction.duration);
    XCTAssertLessThan(groupAction.elapsedTime, groupAction.duration);
    XCTAssertTrue([groupAction update:0.5 node:nil]);
    XCTAssertEqual([groupAction.actions count], 1);
    XCTAssertGreaterThan(normalAction.elapsedTime, normalAction.duration);
    XCTAssertGreaterThan(groupAction.elapsedTime, groupAction.duration);
    XCTAssertTrue([groupAction update:0.5 node:nil]);
    XCTAssertEqual([groupAction.actions count], 1);
    XCTAssertFalse([groupAction update:0.5 node:nil]);
    XCTAssertEqual([groupAction.actions count], 0);
    XCTAssertGreaterThan(slowAction.elapsedTime, slowAction.duration);
    XCTAssertGreaterThan(groupAction.elapsedTime, groupAction.duration);
  }
}

- (void)testSequenceAction
{
  // Sequence updates and removal of actions
  {
    HLAction *action1 = [HLAction waitForDuration:1.0];
    HLAction *action2 = [HLAction waitForDuration:1.0];
    HLSequenceAction *sequenceAction = [HLAction sequence:@[ action1, action2 ]];
    XCTAssertEqual([sequenceAction.actions count], 2);
    XCTAssertTrue([sequenceAction update:1.1 node:nil]);
    XCTAssertEqual([sequenceAction.actions count], 1);
    XCTAssertFalse([sequenceAction update:1.0 node:nil]);
    XCTAssertEqual([sequenceAction.actions count], 0);
    XCTAssertGreaterThan(action1.elapsedTime, action1.duration);
    XCTAssertGreaterThan(action2.elapsedTime, action2.duration);
    XCTAssertGreaterThan(sequenceAction.elapsedTime, sequenceAction.duration);
  }

  // Complete before duration with fast action
  {
    HLAction *fastAction = [HLAction waitForDuration:1.0];
    fastAction.speed = 2.0f;
    HLSequenceAction *sequenceAction = [HLAction sequence:@[ fastAction ]];
    XCTAssertFalse([sequenceAction update:0.6 node:nil]);
    XCTAssertLessThan(sequenceAction.elapsedTime, sequenceAction.duration);
  }
  
  // But timely completion if normal action in fast sequence
  {
    HLAction *normalAction = [HLAction waitForDuration:1.0];
    HLSequenceAction *sequenceAction = [HLAction sequence:@[ normalAction ]];
    sequenceAction.speed = 2.0f;
    XCTAssertFalse([sequenceAction update:0.6 node:nil]);
    XCTAssertEqualWithAccuracy(sequenceAction.elapsedTime, sequenceAction.duration, 0.2);
  }
  
  // Complete (long) after duration with slow action
  {
    HLAction *slowAction = [HLAction waitForDuration:1.0];
    slowAction.speed = 0.5f;
    HLSequenceAction *sequenceAction = [HLAction sequence:@[ slowAction ]];
    XCTAssertTrue([sequenceAction update:1.1 node:nil]);
    XCTAssertFalse([sequenceAction update:1.0 node:nil]);
    XCTAssertGreaterThan(sequenceAction.elapsedTime, 2.0);
  }
  
  // But timely completion if normal action in slow sequence
  {
    HLAction *normalAction = [HLAction waitForDuration:1.0];
    HLSequenceAction *sequenceAction = [HLAction sequence:@[ normalAction ]];
    sequenceAction.speed = 0.5f;
    XCTAssertTrue([sequenceAction update:1.1 node:nil]);
    XCTAssertFalse([sequenceAction update:1.0 node:nil]);
    XCTAssertEqualWithAccuracy(sequenceAction.elapsedTime, sequenceAction.duration, 0.2);
  }

  // Handling multiple actions with various speeds
  {
    HLAction *normalAction = [HLAction waitForDuration:1.0];
    HLAction *fastAction = [HLAction waitForDuration:1.0];
    fastAction.speed = 2.0;
    HLAction *slowAction = [HLAction waitForDuration:1.0];
    slowAction.speed = 0.5;
    HLSequenceAction *sequenceAction = [HLAction sequence:@[ normalAction, fastAction, slowAction ]];
    XCTAssertEqual([sequenceAction.actions count], 3);
    XCTAssertTrue([sequenceAction update:0.6 node:nil]);
    XCTAssertEqual([sequenceAction.actions count], 3);
    XCTAssertTrue([sequenceAction update:0.5 node:nil]);
    XCTAssertEqual([sequenceAction.actions count], 2);
    XCTAssertGreaterThan(normalAction.elapsedTime, normalAction.duration);
    XCTAssertTrue([sequenceAction update:0.5 node:nil]);
    XCTAssertEqual([sequenceAction.actions count], 1);
    XCTAssertGreaterThan(fastAction.elapsedTime, fastAction.duration);
    XCTAssertTrue([sequenceAction update:0.5 node:nil]);
    XCTAssertTrue([sequenceAction update:0.5 node:nil]);
    XCTAssertTrue([sequenceAction update:0.5 node:nil]);
    XCTAssertEqual([sequenceAction.actions count], 1);
    XCTAssertFalse([sequenceAction update:0.5 node:nil]);
    XCTAssertEqual([sequenceAction.actions count], 0);
    XCTAssertGreaterThan(slowAction.elapsedTime, slowAction.duration);
    XCTAssertGreaterThan(sequenceAction.elapsedTime, 3.5);
  }

  // Batching non-durational actions
  {
    HLAction *normalAction1 = [HLAction waitForDuration:1.0];
    HLAction *normalAction2 = [HLAction waitForDuration:1.0];
    HLAction *instantAction1 = [HLAction waitForDuration:0.0];
    HLAction *instantAction2 = [HLAction waitForDuration:0.0];
    HLAction *instantAction3 = [HLAction waitForDuration:0.0];
    HLAction *instantAction4 = [HLAction waitForDuration:0.0];
    HLSequenceAction *sequenceAction = [HLAction sequence:@[ instantAction1, instantAction2, normalAction1, instantAction3, instantAction4, normalAction2 ]];
    XCTAssertEqual([sequenceAction.actions count], 6);
    XCTAssertTrue([sequenceAction update:0.6 node:nil]);
    XCTAssertEqual([sequenceAction.actions count], 4);
    XCTAssertTrue([sequenceAction update:0.5 node:nil]);
    XCTAssertEqual([sequenceAction.actions count], 1);
    XCTAssertTrue([sequenceAction update:0.5 node:nil]);
    XCTAssertEqual([sequenceAction.actions count], 1);
    XCTAssertFalse([sequenceAction update:0.5 node:nil]);
    XCTAssertEqual([sequenceAction.actions count], 0);
  }

  // Carryover of incremental time from completed action to next action in sequence
  {
    HLAction *action1 = [HLAction waitForDuration:1.0];
    HLAction *action2 = [HLAction waitForDuration:1.0];
    HLSequenceAction *sequenceAction = [HLAction sequence:@[ action1, action2 ]];
    XCTAssertTrue([sequenceAction update:1.5 node:nil]);
    XCTAssertEqual([sequenceAction.actions count], 1);
    XCTAssertGreaterThan(action1.elapsedTime, action1.duration);
    XCTAssertLessThan(action2.elapsedTime, action2.duration);
    XCTAssertEqualWithAccuracy(action2.elapsedTime, 0.5, 0.1);
    XCTAssertLessThan(sequenceAction.elapsedTime, sequenceAction.duration);
  }

  // Carryover of incremental time from completed action to next action in sequence, respecting speeds
  {
    HLAction *fastAction = [HLAction waitForDuration:1.0];
    fastAction.speed = 2.0f;
    HLAction *slowAction = [HLAction waitForDuration:1.0];
    slowAction.speed = 0.5f;
    HLSequenceAction *sequenceAction = [HLAction sequence:@[ fastAction, slowAction ]];
    XCTAssertTrue([sequenceAction update:0.6 node:nil]);
    // Fast action should complete after 0.5 seconds of sequence time.  In fast-action's frame,
    // it was given 1.2 seconds of elapsed time, leaving 0.2 extra after completion.  That should
    // get translated back into the sequence time frame as 0.1 seconds.  Then the sequence should
    // pass that along to the slow action, which will consider it to be half that, 0.05 seconds.
    XCTAssertEqualWithAccuracy(fastAction.elapsedTime, 1.2, 0.01);
    XCTAssertEqualWithAccuracy(sequenceAction.elapsedTime, 0.6, 0.01);
    XCTAssertEqualWithAccuracy(slowAction.elapsedTime, 0.05, 0.01);
  }
}

- (void)testRepeatAction
{
  // Template action unaffected
  {
    HLAction *templateAction = [HLAction waitForDuration:1.0];
    HLRepeatAction *repeatAction = [HLAction repeatActionForever:templateAction];
    XCTAssertTrue([repeatAction update:0.6 node:nil]);
    XCTAssertEqual(templateAction.elapsedTime, 0.0);
  }

  // Copied actions independent
  {
    HLAction *templateAction = [HLAction waitForDuration:1.0];
    HLRepeatAction *repeatAction = [HLAction repeatActionForever:templateAction];
    XCTAssertTrue([repeatAction update:0.6 node:nil]);
    HLAction *firstIterationAction = repeatAction.copiedAction;
    XCTAssertLessThan(firstIterationAction.elapsedTime, firstIterationAction.duration);
    XCTAssertTrue([repeatAction update:0.5 node:nil]);
    XCTAssertGreaterThan(firstIterationAction.elapsedTime, firstIterationAction.duration);
    XCTAssertTrue([repeatAction update:0.5 node:nil]);
    HLAction *secondIterationAction = repeatAction.copiedAction;
    XCTAssertLessThan(secondIterationAction.elapsedTime, secondIterationAction.duration);
    XCTAssertTrue([repeatAction update:0.5 node:nil]);
    XCTAssertGreaterThan(secondIterationAction.elapsedTime, secondIterationAction.duration);
    XCTAssertNotEqual(firstIterationAction, secondIterationAction);
  }

  // Finite repeat progresses with sensible elapsed time and duration
  {
    HLAction *templateAction = [HLAction waitForDuration:1.0];
    HLRepeatAction *repeatAction = [HLAction repeatAction:templateAction count:2];
    XCTAssertTrue([repeatAction update:1.1 node:nil]);
    XCTAssertLessThan(repeatAction.elapsedTime, repeatAction.duration);
    XCTAssertFalse([repeatAction update:1.0 node:nil]);
    XCTAssertGreaterThan(repeatAction.elapsedTime, repeatAction.duration);
  }
  
  // Infinite repeat tracks elapsed time (if not sensible duration) and doesn't complete after long time
  {
    _counter = 0;
    HLAction *templateAction = [HLAction sequence:@[ [HLAction waitForDuration:1.0],
                                                     [HLAction performSelector:@selector(HL_incrementCounter) onWeakTarget:self] ]];
    HLRepeatAction *repeatAction = [HLAction repeatActionForever:templateAction];
    XCTAssertTrue([repeatAction update:1.1 node:nil]);
    XCTAssertGreaterThan(repeatAction.elapsedTime, 1.0);
    XCTAssertTrue([repeatAction update:1.0 node:nil]);
    XCTAssertGreaterThan(repeatAction.elapsedTime, 2.0);
    XCTAssertTrue([repeatAction update:100.0 node:nil]);
    XCTAssertEqual(_counter, 102);
  }

  // Handling template action with non-unary speed
  {
    HLAction *templateAction = [HLAction waitForDuration:1.0];
    templateAction.speed = 0.5;
    HLRepeatAction *repeatAction = [HLAction repeatActionForever:templateAction];
    XCTAssertTrue([repeatAction update:1.1 node:nil]);
    HLAction *firstIterationAction = repeatAction.copiedAction;
    XCTAssertLessThan(firstIterationAction.elapsedTime, firstIterationAction.duration);
    XCTAssertTrue([repeatAction update:1.0 node:nil]);
    XCTAssertGreaterThan(firstIterationAction.elapsedTime, firstIterationAction.duration);
    XCTAssertTrue([repeatAction update:1.0 node:nil]);
    HLAction *secondIterationAction = repeatAction.copiedAction;
    XCTAssertLessThan(secondIterationAction.elapsedTime, secondIterationAction.duration);
    XCTAssertTrue([repeatAction update:1.0 node:nil]);
    XCTAssertGreaterThan(secondIterationAction.elapsedTime, secondIterationAction.duration);
    XCTAssertNotEqual(firstIterationAction, secondIterationAction);
  }

  // Carryover of incremental time from completed action to next action
  {
    HLAction *templateAction = [HLAction waitForDuration:1.0];
    HLRepeatAction *repeatAction = [HLAction repeatActionForever:templateAction];
    XCTAssertTrue([repeatAction update:1.5 node:nil]);
    XCTAssertEqualWithAccuracy(repeatAction.copiedAction.elapsedTime, 0.5, 0.1);
  }

  // Carryover of incremental time from completed action to next action, respecting speed
  {
    HLAction *templateAction = [HLAction waitForDuration:1.0];
    templateAction.speed = 2.0f;
    HLRepeatAction *repeatAction = [HLAction repeatActionForever:templateAction];
    XCTAssertTrue([repeatAction update:0.75 node:nil]);
    XCTAssertEqualWithAccuracy(repeatAction.copiedAction.elapsedTime, 0.5, 0.1);
  }
}

@end
