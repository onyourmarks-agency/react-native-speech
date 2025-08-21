#import "generated/RNSpeechSpec/RNSpeechSpec.h"
#import "AVFoundation/AVFoundation.h"

using namespace JS::NativeSpeech;

NS_ASSUME_NONNULL_BEGIN

@interface Speech : NativeSpeechSpecBase <NativeSpeechSpec, AVSpeechSynthesizerDelegate>
@property (nonatomic, strong) AVSpeechSynthesizer *synthesizer;
@property (nonatomic, strong) BOOL *isDucking;
@property (nonatomic, strong) NSDictionary *globalOptions;
@end

NS_ASSUME_NONNULL_END
