#import "Speech.h"

using namespace JS::NativeSpeech;

@implementation Speech
{
  NSDictionary *defaultOptions;
}

RCT_EXPORT_MODULE();

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
  static Speech *shared = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    shared = [super allocWithZone:zone];
  });
  return shared;
}

+ (BOOL)requiresMainQueueSetup {
  return NO;
}

- (instancetype)init {
  static BOOL initialized = NO;
  if (initialized) {
    return self; // return existing singleton
  }

  self = [super init];
  if (self) {
    _synthesizer = [[AVSpeechSynthesizer alloc] init];
    _synthesizer.delegate = self;
    _isDucking = NO;
    _activeUtteranceCount = 0;

    defaultOptions = @{
      @"pitch": @(1.0),
      @"volume": @(1.0),
      @"rate": @(AVSpeechUtteranceDefaultSpeechRate),
      @"language": [AVSpeechSynthesisVoice currentLanguageCode] ?: @"en-US"
    };
    self.globalOptions = [defaultOptions copy];

    initialized = YES;
    NSLog(@"✅ Speech singleton initialized %@", self);
  }
  return self;
}

- (void)enableDucking {
  if (self.isDucking) return;
  if (self.activeUtteranceCount > 0) return;

  NSError *error = nil;
  [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient
                                   withOptions:AVAudioSessionCategoryOptionDuckOthers
                                         error:&error];
  if (error) {
    NSLog(@"⚠️ Error enabling ducking: %@", error);
  }

  [[AVAudioSession sharedInstance] setActive:YES error:&error];
  if (error) {
    NSLog(@"⚠️ Error activating audio session: %@", error);
  }
  self.isDucking = YES;
}

- (void)disableDucking {
    if (!self.isDucking) return;
    if (self.activeUtteranceCount > 0) return;

    NSError *error = nil;
    [[AVAudioSession sharedInstance] setActive:NO
        withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
        error:&error];
    if (error) {
        NSLog(@"⚠️ Error deactivating audio session: %@", error);
    }

    self.isDucking = NO;
}

- (NSDictionary *)getEventData:(AVSpeechUtterance *)utterance {
  return @{
    @"id": @(utterance.hash)
  };
}

- (NSDictionary *)getVoiceItem:(AVSpeechSynthesisVoice *)voice {
  return @{
    @"name": voice.name,
    @"language": voice.language,
    @"identifier": voice.identifier,
    @"quality": voice.quality == AVSpeechSynthesisVoiceQualityEnhanced ? @"Enhanced" : @"Default"
  };
}

- (NSDictionary *)getValidatedOptions:(VoiceOptions &)options {
  NSMutableDictionary *validatedOptions = [NSMutableDictionary new];

  if (options.voice()) {
    validatedOptions[@"voice"] = options.voice();
  }
  if (options.language()) {
    validatedOptions[@"language"] = options.language();
  }
  if (options.pitch()) {
    float pitch = MAX(0.5, MIN(2.0, options.pitch().value()));
    validatedOptions[@"pitch"] = @(pitch);
  }
  if (options.volume()) {
    float volume = MAX(0, MIN(1.0, options.volume().value()));
    validatedOptions[@"volume"] = @(volume);
  }
  if (options.rate()) {
    float rate = MAX(AVSpeechUtteranceMinimumSpeechRate,
                    MIN(AVSpeechUtteranceMaximumSpeechRate, options.rate().value()));
    validatedOptions[@"rate"] = @(rate);
  }
  return validatedOptions;
}

- (AVSpeechUtterance *)getDefaultUtterance:(NSString *)text {
  AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:text];

  NSLog(@"🔊 Creating utterance for: %@", text);

  if (self.globalOptions[@"voice"]) {
    AVSpeechSynthesisVoice *voice = [AVSpeechSynthesisVoice voiceWithIdentifier:self.globalOptions[@"voice"]];
    NSLog(@"🔊 Voice lookup result: %@", voice);
    if (voice) {
      utterance.voice = voice;
      NSLog(@"🔊 Set voice by identifier: %@", voice.identifier);
    } else if (self.globalOptions[@"language"]) {
      utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:self.globalOptions[@"language"]];
      NSLog(@"🔊 Set voice by language fallback: %@", utterance.voice.identifier);
    }
  } else {
    utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:self.globalOptions[@"language"]];
    NSLog(@"🔊 Set voice by language: %@", utterance.voice.identifier);
  }

  utterance.rate = [self.globalOptions[@"rate"] floatValue];
  utterance.volume = [self.globalOptions[@"volume"] floatValue];
  utterance.pitchMultiplier = [self.globalOptions[@"pitch"] floatValue];

  NSLog(@"🔊 Final utterance voice: %@", utterance.voice.identifier);
  return utterance;
}

- (void)initialize:(VoiceOptions &)options {
    NSMutableDictionary *newOptions = [NSMutableDictionary dictionaryWithDictionary:self.globalOptions];
    NSDictionary *validatedOptions = [self getValidatedOptions:options];
    [newOptions addEntriesFromDictionary:validatedOptions];
    self.globalOptions = newOptions;

    AVSpeechUtterance *warmup = [[AVSpeechUtterance alloc] initWithString:@" "];
    warmup.volume = 0.0;
    warmup.rate = AVSpeechUtteranceMinimumSpeechRate;
    warmup.accessibilityHint = @"__warmup__";
    [self.synthesizer speakUtterance:warmup];
}

- (void)reset {
  self.globalOptions = [defaultOptions copy];
}

- (void)getAvailableVoices:(NSString *)language
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject
{
  NSMutableArray *voicesArray = [NSMutableArray new];
  NSArray *speechVoices = [AVSpeechSynthesisVoice speechVoices];

  if (language) {
    NSString *lowercaseLanguage = [language lowercaseString];

    for (AVSpeechSynthesisVoice *voice in speechVoices) {
      NSString *voiceLanguage = [voice.language lowercaseString];

      if ([voiceLanguage hasPrefix:lowercaseLanguage]) {
        [voicesArray addObject:[self getVoiceItem:voice]];
      }
    }
  } else {
    for (AVSpeechSynthesisVoice *voice in speechVoices) {
      [voicesArray addObject:[self getVoiceItem:voice]];
    }
  }
  resolve(voicesArray);
}

- (void)isSpeaking:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  BOOL speaking = self.synthesizer.isSpeaking;
  resolve(@(speaking));
}

- (void)stop:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  if (self.synthesizer.isSpeaking) {
    [self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
  }
  resolve(nil);
}

- (void)pause:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  if (self.synthesizer.isSpeaking && !self.synthesizer.isPaused) {
    BOOL paused = [self.synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    resolve(@(paused));
  } else {
    resolve(@(false));
  }
}

- (void)resume:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  if (self.synthesizer.isPaused) {
    BOOL resumed = [self.synthesizer continueSpeaking];
    resolve(@(resumed));
  } else {
    resolve(@(false));
  }
}

- (void)speak:(NSString *)text
    resolve:(RCTPromiseResolveBlock)resolve
    reject:(RCTPromiseRejectBlock)reject
{
  if (!text) {
    reject(@"speech_error", @"Text cannot be null", nil);
    return;
  }

  AVSpeechUtterance *utterance;

  @try {
    utterance = [self getDefaultUtterance:text];
    [self.synthesizer speakUtterance:utterance];
    resolve(nil);
  }
  @catch (NSException *exception) {
    [self emitOnError:[self getEventData:utterance]];
    reject(@"speech_error", exception.reason, nil);
  }
}

- (void)speakWithOptions:(NSString *)text
    options:(VoiceOptions &)options
    resolve:(RCTPromiseResolveBlock)resolve
    reject:(RCTPromiseRejectBlock)reject
{
  if (!text) {
    reject(@"speech_error", @"Text cannot be null", nil);
    return;
  }

  AVSpeechUtterance *utterance;

  @try {
    utterance = [self getDefaultUtterance:text];
    NSDictionary *validatedOptions = [self getValidatedOptions:options];

    if (validatedOptions[@"voice"]) {
      AVSpeechSynthesisVoice *voice = [AVSpeechSynthesisVoice voiceWithIdentifier:validatedOptions[@"voice"]];
      if (voice) {
        utterance.voice = voice;
      } else if (validatedOptions[@"language"]) {
        utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:validatedOptions[@"language"]];
      }
    }
    if (validatedOptions[@"pitch"]) {
      utterance.pitchMultiplier = [validatedOptions[@"pitch"] floatValue];
    }
    if (validatedOptions[@"volume"]) {
      utterance.volume = [validatedOptions[@"volume"] floatValue];
    }
    if (validatedOptions[@"rate"]) {
      utterance.rate = [validatedOptions[@"rate"] floatValue];
    }

    self.activeUtteranceCount += 1;
    [self enableDucking];
    [self.synthesizer speakUtterance:utterance];

    resolve(nil);
  }
  @catch (NSException *exception) {
    [self emitOnError:[self getEventData:utterance]];
    reject(@"speech_error", exception.reason, nil);
  }
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer
  didStartSpeechUtterance:(AVSpeechUtterance *)utterance {
    if (![utterance.accessibilityHint isEqualToString:@"__warmup__"]) {
      [self emitOnStart:[self getEventData:utterance]];
    }
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer
  willSpeakRangeOfSpeechString:(NSRange)characterRange utterance:(AVSpeechUtterance *)utterance {
  [self emitOnProgress:@{
    @"id": @(utterance.hash),
    @"length": @(characterRange.length),
    @"location": @(characterRange.location)
  }];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer
  didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
    if (![utterance.accessibilityHint isEqualToString:@"__warmup__"]) {
        self.activeUtteranceCount -= 1;
        [self emitOnFinish:[self getEventData:utterance]];
    }

    if (!self.synthesizer.isSpeaking && self.activeUtteranceCount <= 0) {
        [self disableDucking];
    }
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer
  didPauseSpeechUtterance:(nonnull AVSpeechUtterance *)utterance {
  [self emitOnPause:[self getEventData:utterance]];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer
  didContinueSpeechUtterance:(nonnull AVSpeechUtterance *)utterance {
  [self emitOnResume:[self getEventData:utterance]];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer
  didCancelSpeechUtterance:(AVSpeechUtterance *)utterance {
    if (![utterance.accessibilityHint isEqualToString:@"__warmup__"]) {
        self.activeUtteranceCount -= 1;
        [self emitOnStopped:[self getEventData:utterance]];
    }

    if (!synthesizer.isSpeaking) {
        [self disableDucking];
    }
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeSpeechSpecJSI>(params);
}

@end
