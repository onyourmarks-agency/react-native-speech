#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <os/log.h>

using namespace JS::NativeSpeech;

@interface Ducking : NSObject

- (void)startDucking;
- (void)stopDucking;

@end
