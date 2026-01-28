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
void HLLog(HLLogLevel level, NSString *format, ...) NS_FORMAT_FUNCTION(2, 3);
