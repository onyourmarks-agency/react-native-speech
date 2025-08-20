#import "Ducking.h"

using namespace JS::NativeSpeech;

@implementation Ducking
- (void)startDucking {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error = nil;

    BOOL success = [session setCategory:AVAudioSessionCategoryPlayback
        withOptions:AVAudioSessionCategoryOptionDuckOthers
              error:&error];

    if (!success && error) {
      NSLog(@"[AudioDucking] startDucking error: %@", error.localizedDescription);
      return;
    }

    [session setActive:YES error:&error];
    if (error) {
      NSLog(@"[AudioDucking] Error activating session: %@", error.localizedDescription);
    }
}

- (void)stopDucking {
  AVAudioSession *session = [AVAudioSession sharedInstance];
  NSError *error = nil;

  [session setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
  if (error) {
    NSLog(@"[AudioDucking] stopDucking error: %@", error.localizedDescription);
  }
}
@end
