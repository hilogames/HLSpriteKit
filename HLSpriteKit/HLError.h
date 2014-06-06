//
//  HLError.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 6/6/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum HLErrorLevel {
  HLLevelError,
  HLLevelWarning,
} HLErrorLevel;

static void
HLError(HLErrorLevel level, NSString *message)
{
  // TODO: Use CocoaLumberjack for non-critical error logging.
  NSString *levelLabel;
  if (level == HLLevelWarning) {
    levelLabel = @"WARNING";
  } else {
    levelLabel = @"ERROR";
  }
  NSLog(@"%@: %@", levelLabel, message);
}
