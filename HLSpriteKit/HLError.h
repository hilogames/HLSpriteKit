//
//  HLError.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 6/6/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 The error level for logging non-critical errors using `HLError()`.

 @deprecated Please use HLLog() instead.
*/
DEPRECATED_MSG_ATTRIBUTE("Please use HLLog() instead.")
typedef NS_ENUM(NSInteger, HLErrorLevel) {
  /**
   Errors.
  */
  HLLevelError,
  /**
   Warnings.
  */
  HLLevelWarning,
  /**
   Information.
  */
  HLLevelInfo,
};

/**
 Logs a non-critical error.

 @deprecated Please use HLLog() instead.
*/
DEPRECATED_MSG_ATTRIBUTE("Please use HLLog() instead.")
static inline void
HLError(HLErrorLevel level, NSString *message)
{
  // TODO: This is a placeholder for a better mechanism for non-critical error logging,
  // e.g. CocoaLumberjack.
  NSString *levelLabel;
  switch (level) {
    case HLLevelInfo:
      levelLabel = @"INFO";
      break;
    case HLLevelWarning:
      levelLabel = @"WARNING";
      break;
    case HLLevelError:
      levelLabel = @"ERROR";
      break;
  }
  NSLog(@"%@: %@", levelLabel, message);
}
