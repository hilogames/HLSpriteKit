//
//  HLEmitterStore.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/20/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import "HLEmitterStore.h"

@implementation HLEmitterStore
{
  NSMutableDictionary *_emitters;
}

+ (HLEmitterStore *)sharedStore
{
  static HLEmitterStore *sharedStore = nil;
  if (!sharedStore) {
    sharedStore = [[HLEmitterStore alloc] init];
  }
  return sharedStore;
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    _emitters = [NSMutableDictionary dictionary];
  }
  return self;
}

- (SKEmitterNode *)emitterCopyForKey:(NSString *)key
{
  SKEmitterNode *emitter = _emitters[key];
  if (!emitter) {
    return nil;
  }
  return [emitter copy];
}

- (SKEmitterNode *)emitterForKey:(NSString *)key
{
  SKEmitterNode *emitter = _emitters[key];
  if (!emitter) {
    return nil;
  }
  return emitter;
}

- (void)setEmitter:(SKEmitterNode *)emitterNode forKey:(NSString *)key
{
  _emitters[key] = emitterNode;
}

- (SKEmitterNode *)setEmitterWithResource:(NSString *)name forKey:(NSString *)key
{
  SKEmitterNode *emitter = nil;
#if TARGET_OS_IPHONE

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 120000
  NSError *error = nil;
  NSData *emitterData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:@"sks"]];
  emitter = [NSKeyedUnarchiver unarchivedObjectOfClass:[SKEmitterNode class] fromData:emitterData error:&error];
  if (!emitter) {
    [NSException raise:@"HLEmitterStoreEmitterNotFound" format:@"Could not find emitter in bundle with name '%@' and type 'sks': %@", name, error];
  }
#else
  if (@available(iOS 11.0, *)) {
    NSError *error = nil;
    NSData *emitterData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:@"sks"]];
    emitter = [NSKeyedUnarchiver unarchivedObjectOfClass:[SKEmitterNode class] fromData:emitterData error:&error];
    if (!emitter) {
      [NSException raise:@"HLEmitterStoreEmitterNotFound" format:@"Could not find emitter in bundle with name '%@' and type 'sks': %@", name, error];
    }
  } else {
    emitter = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:name ofType:@"sks"]];
    if (!emitter) {
      [NSException raise:@"HLEmitterStoreEmitterNotFound" format:@"Could not find emitter in bundle with name '%@' and type 'sks'.", name];
    }
  }
#endif

#else

  if (@available(macOS 10.13, *)) {
    NSError *error = nil;
    NSData *emitterData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:@"sks"]];
    emitter = [NSKeyedUnarchiver unarchivedObjectOfClass:[SKEmitterNode class] fromData:emitterData error:&error];
    if (!emitter) {
      [NSException raise:@"HLEmitterStoreEmitterNotFound" format:@"Could not find emitter in bundle with name '%@' and type 'sks': %@", name, error];
    }
  } else {
    emitter = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:name ofType:@"sks"]];
    if (!emitter) {
      [NSException raise:@"HLEmitterStoreEmitterNotFound" format:@"Could not find emitter in bundle with name '%@' and type 'sks'.", name];
    }
  }

#endif

  _emitters[key] = emitter;
  return emitter;
}

- (void)removeAll
{
  [_emitters removeAllObjects];
}

@end
