//
//  HLLog.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 4/8/20.
//  Copyright (c) 2020 Hilo Games. All rights reserved.
//

#import "HLLog.h"

void
HLLog(HLLogLevel level, NSString *format, ...)
{
#if DEBUG

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

#endif
}
