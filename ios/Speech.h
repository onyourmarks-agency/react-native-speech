#import "generated/RNSpeechSpec/RNSpeechSpec.h"
#import "AVFoundation/AVFoundation.h"
#import "Ducking.h"

using namespace JS::NativeSpeech;

NS_ASSUME_NONNULL_BEGIN

@interface Speech : NativeSpeechSpecBase <NativeSpeechSpec, AVSpeechSynthesizerDelegate>
@property (nonatomic, strong) AVSpeechSynthesizer *synthesizer;
@property (nonatomic, strong) NSDictionary *globalOptions;
@property (nonatomic, strong) Ducking *audioDucking;
@end

NS_ASSUME_NONNULL_END
