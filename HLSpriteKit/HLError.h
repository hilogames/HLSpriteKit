//
//  HLError.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 6/6/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, HLErrorLevel) {
  HLLevelError,
  HLLevelWarning,
};

static void
HLError(HLErrorLevel level, NSString *message)
{
  // TODO: This is a placeholder for a better mechanism for non-critical error logging,
  // e.g. CocoaLumberjack.
  NSString *levelLabel;
  if (level == HLLevelWarning) {
    levelLabel = @"WARNING";
  } else {
    levelLabel = @"ERROR";
  }
  NSLog(@"%@: %@", levelLabel, message);
}
