//
//  HLLog.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 10/6/17.
//  Copyright (c) 2017 Hilo Games. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 The log level when using `HLLog()`.
*/
typedef NS_ENUM(NSInteger, HLLogLevel) {
  /**
   Errors.
  */
  HLLogError,
  /**
   Warnings.
  */
  HLLogWarning,
  /**
   Information.
  */
  HLLogInfo,
};

/**
 Writes a log message with an associated level.
*/
static inline void
HLLog(HLLogLevel level, NSString *format, ...)
{
  // note: This is a placeholder for a better logging mechanism, e.g. CocoaLumberjack.

  va_list args;
  va_start(args, format);
  NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
  va_end(args);

  NSString *levelLabel;
  switch (level) {
    case HLLogInfo:
      levelLabel = @"INFO";
      break;
    case HLLogWarning:
      levelLabel = @"WARNING";
      break;
    case HLLogError:
      levelLabel = @"ERROR";
      break;
  }

  NSLog(@"%@: %@", levelLabel, message);
}
