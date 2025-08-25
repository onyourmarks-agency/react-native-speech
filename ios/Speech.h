#import "generated/RNSpeechSpec/RNSpeechSpec.h"
#import "AVFoundation/AVFoundation.h"

using namespace JS::NativeSpeech;

NS_ASSUME_NONNULL_BEGIN

@interface Speech : NativeSpeechSpecBase <NativeSpeechSpec, AVSpeechSynthesizerDelegate>
@property (nonatomic, strong) AVSpeechSynthesizer *synthesizer;
@property (nonatomic) BOOL isDucking;
@property (nonatomic, strong) NSDictionary *globalOptions;
@property (nonatomic, assign) NSInteger activeUtteranceCount;
@end

NS_ASSUME_NONNULL_END
