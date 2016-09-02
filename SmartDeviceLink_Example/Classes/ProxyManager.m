//
//  ProxyManager.m
//  SmartDeviceLink-iOS

@import SmartDeviceLink;

#import "ProxyManager.h"

#import "Preferences.h"


NSString *const SDLAppName = @"SDL Example App";
NSString *const SDLAppId = @"9999";

typedef NS_ENUM(NSUInteger, SDLHMIFirstState) {
    SDLHMIFirstStateNone,
    SDLHMIFirstStateNonNone,
    SDLHMIFirstStateFull
};


@interface ProxyManager () <SDLManagerDelegate>

// Describes the first time the HMI state goes non-none and full.
@property (assign, nonatomic) SDLHMIFirstState firstTimeState;

@end


@implementation ProxyManager

#pragma mark - Initialization

+ (instancetype)sharedManager {
    static ProxyManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[ProxyManager alloc] init];
    });
    
    return sharedManager;
}

- (instancetype)init {
    self = [super init];
    if (self == nil) {
        return nil;
    }
    
    _firstTimeState = SDLHMIFirstStateNone;
    
    return self;
}

- (void)startIAP {
    SDLLifecycleConfiguration *lifecycleConfig = [self.class sdlex_setLifecycleConfigurationPropertiesOnConfiguration:[SDLLifecycleConfiguration defaultConfigurationWithAppName:SDLAppName appId:SDLAppId]];
    
    // Assume this is production and disable logging
    lifecycleConfig.logFlags = SDLLogOutputNone;
    
    SDLConfiguration *config = [SDLConfiguration configurationWithLifecycle:lifecycleConfig lockScreen:[SDLLockScreenConfiguration enabledConfiguration]];
    self.sdlManager = [[SDLManager alloc] initWithConfiguration:config delegate:self];
    
    [self startManager];
}

- (void)startTCP {
    SDLLifecycleConfiguration *lifecycleConfig = [self.class sdlex_setLifecycleConfigurationPropertiesOnConfiguration:[SDLLifecycleConfiguration debugConfigurationWithAppName:SDLAppName appId:SDLAppId ipAddress:[Preferences sharedPreferences].ipAddress port:[Preferences sharedPreferences].port]];
    SDLConfiguration *config = [SDLConfiguration configurationWithLifecycle:lifecycleConfig lockScreen:[SDLLockScreenConfiguration enabledConfiguration]];
    self.sdlManager = [[SDLManager alloc] initWithConfiguration:config delegate:self];
    
    [self startManager];
}

- (void)startManager {
    __weak typeof (self) weakSelf = self;
    [self.sdlManager startWithReadyHandler:^(BOOL success, NSError * _Nullable error) {
        if (!success) {
            NSLog(@"SDL errored starting up: %@", error);
        }
        
        if ([weakSelf.sdlManager.hmiLevel isEqualToEnum:[SDLHMILevel FULL]]) {
            [weakSelf showInitialData];
        }
    }];
}

- (void)reset {
    [self.sdlManager stop];
}

- (void)showInitialData {
    SDLArtwork* softButtonImage = [self softButtonImage];
    if ([self.sdlManager.fileManager.remoteFileNames containsObject:softButtonImage.name] == NO) {
        [self uploadInterfaceFiles];
    } else {
        __weak typeof(self) weakSelf = self;
        SDLSoftButton* softButton = [[SDLSoftButton alloc] initWithHandler:^(__kindof SDLRPCNotification * _Nonnull notification) {
            if ([notification isKindOfClass:[SDLOnButtonPress class]]) {
                SDLOnButtonPress* buttonPress = (SDLOnButtonPress*)notification;
                if ([buttonPress.customButtonID isEqualToNumber:@100]) {
                    SDLAlert* alert = [[SDLAlert alloc] init];
                    alert.alertText1 = @"You pushed the button!";
                    [weakSelf.sdlManager sendRequest:alert];
                }
            }
        }];
        softButton.text = @"Press";
        softButton.softButtonID = @100;
        softButton.type = SDLSoftButtonType.BOTH;
        
        SDLImage* image = [[SDLImage alloc] init];
        image.imageType = SDLImageType.DYNAMIC;
        image.value = softButtonImage.name;
        softButton.image = image;

        SDLShow *initialData = [SDLRPCRequestFactory buildShowWithMainField1:@"SDL" mainField2:@"Test App" alignment:[SDLTextAlignment CENTERED] correlationID:@0];
        initialData.softButtons = [@[softButton] mutableCopy];
        [self.sdlManager sendRequest:initialData];
    }
}

+ (SDLLifecycleConfiguration *)sdlex_setLifecycleConfigurationPropertiesOnConfiguration:(SDLLifecycleConfiguration *)config {
    SDLArtwork *appIconArt = [SDLArtwork persistentArtworkWithImage:[UIImage imageNamed:@"AppIcon60x60@2x"] name:@"AppIcon" asImageFormat:SDLArtworkImageFormatPNG];
    
    config.shortAppName = @"SDL Example";
    config.appIcon = appIconArt;
    config.voiceRecognitionCommandNames = @[@"S D L Example"];
    config.ttsName = @[[SDLTTSChunkFactory buildTTSChunkForString:config.shortAppName type:[SDLSpeechCapabilities TEXT]]];
    
    return config;
}


#pragma mark - RPC builders

- (SDLAddCommand *)speakNameCommand {
    NSString *commandName = @"Speak App Name";
    
    SDLMenuParams *commandMenuParams = [[SDLMenuParams alloc] init];
    commandMenuParams.menuName = commandName;
    
    SDLAddCommand *speakNameCommand = [[SDLAddCommand alloc] init];
    speakNameCommand.vrCommands = [NSMutableArray arrayWithObject:commandName];
    speakNameCommand.menuParams = commandMenuParams;
    speakNameCommand.cmdID = @0;
    
    __weak typeof(self) weakSelf = self;
    speakNameCommand.handler = ^void(SDLOnCommand *notification) {
        [weakSelf.sdlManager sendRequest:[self.class appNameSpeak]];
    };
    
    return speakNameCommand;
}

- (SDLAddCommand *)interactionSetCommand {
    NSString *commandName = @"Perform Interaction";
    
    SDLMenuParams *commandMenuParams = [[SDLMenuParams alloc] init];
    commandMenuParams.menuName = commandName;
    
    SDLAddCommand *performInteractionCommand = [[SDLAddCommand alloc] init];
    performInteractionCommand.vrCommands = [NSMutableArray arrayWithObject:commandName];
    performInteractionCommand.menuParams = commandMenuParams;
    performInteractionCommand.cmdID = @1;
    
    // NOTE: You may want to preload your interaction sets, because they can take a while for the remote system to process. We're going to ignore our own advice here.
    __weak typeof(self) weakSelf = self;
    performInteractionCommand.handler = ^void(SDLOnCommand *notification) {
        [weakSelf.sdlManager sendRequest:[self.class createOnlyChoiceInteractionSet] withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
            [weakSelf.class sendPerformOnlyChoiceInteractionWithManager:weakSelf.sdlManager];
        }];
    };
    
    return performInteractionCommand;
}

- (SDLArtwork*)softButtonImage {
    SDLArtwork* softButtonImage = [SDLArtwork artworkWithImage:[UIImage imageNamed:@"sdl_softbutton_icon"] name:@"SoftButtonIcon" asImageFormat:SDLArtworkImageFormatPNG];
    
    return softButtonImage;
}

+ (SDLSpeak *)appNameSpeak {
    SDLSpeak *speak = [[SDLSpeak alloc] init];
    speak.ttsChunks = [NSMutableArray arrayWithObject:[SDLTTSChunkFactory buildTTSChunkForString:@"S D L Example App" type:[SDLSpeechCapabilities TEXT]]];
    
    return speak;
}

+ (SDLSpeak *)goodJobSpeak {
    SDLSpeak *speak = [[SDLSpeak alloc] init];
    speak.ttsChunks = [NSMutableArray arrayWithObject:[SDLTTSChunkFactory buildTTSChunkForString:@"Good job" type:[SDLSpeechCapabilities TEXT]]];
    
    return speak;
}

+ (SDLSpeak *)youMissedItSpeak {
    SDLSpeak *speak = [[SDLSpeak alloc] init];
    speak.ttsChunks = [NSMutableArray arrayWithObject:[SDLTTSChunkFactory buildTTSChunkForString:@"You missed it" type:[SDLSpeechCapabilities TEXT]]];
    
    return speak;
}

+ (SDLCreateInteractionChoiceSet *)createOnlyChoiceInteractionSet {
    SDLCreateInteractionChoiceSet *createInteractionSet = [[SDLCreateInteractionChoiceSet alloc] init];
    createInteractionSet.interactionChoiceSetID = @0;
    
    NSString *theOnlyChoiceName = @"The Only Choice";
    SDLChoice *theOnlyChoice = [[SDLChoice alloc] init];
    theOnlyChoice.choiceID = @0;
    theOnlyChoice.menuName = theOnlyChoiceName;
    theOnlyChoice.vrCommands = [NSMutableArray arrayWithObject:theOnlyChoiceName];
    
    createInteractionSet.choiceSet = [NSMutableArray arrayWithArray:@[theOnlyChoice]];
    
    return createInteractionSet;
}

+ (void)sendPerformOnlyChoiceInteractionWithManager:(SDLManager *)manager {
    SDLPerformInteraction *performOnlyChoiceInteraction = [[SDLPerformInteraction alloc] init];
    performOnlyChoiceInteraction.initialText = @"Choose the only one! You have 5 seconds...";
    performOnlyChoiceInteraction.initialPrompt = [NSMutableArray arrayWithObject:[SDLTTSChunkFactory buildTTSChunkForString:@"Choose it" type:[SDLSpeechCapabilities TEXT]]];
    performOnlyChoiceInteraction.interactionMode = [SDLInteractionMode BOTH];
    performOnlyChoiceInteraction.interactionChoiceSetIDList = [NSMutableArray arrayWithObject:@0];
    performOnlyChoiceInteraction.helpPrompt = [NSMutableArray arrayWithObject:[SDLTTSChunkFactory buildTTSChunkForString:@"Do it" type:[SDLSpeechCapabilities TEXT]]];
    performOnlyChoiceInteraction.timeoutPrompt = [NSMutableArray arrayWithObject:[SDLTTSChunkFactory buildTTSChunkForString:@"Too late" type:[SDLSpeechCapabilities TEXT]]];
    performOnlyChoiceInteraction.timeout = @5000;
    performOnlyChoiceInteraction.interactionLayout = [SDLLayoutMode LIST_ONLY];
    
    [manager sendRequest:performOnlyChoiceInteraction withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLPerformInteractionResponse * _Nullable response, NSError * _Nullable error) {
        if ((response == nil) || (error != nil)) {
            NSLog(@"Something went wrong, no perform interaction response: %@", error);
        }
        
        if ([response.choiceID isEqualToNumber:@0]) {
            [manager sendRequest:[self goodJobSpeak]];
        } else {
            [manager sendRequest:[self youMissedItSpeak]];
        }
    }];
}

- (void)uploadInterfaceFiles {
    __weak typeof(self) weakSelf = self;
    [self.sdlManager.fileManager uploadFile:[self softButtonImage] completionHandler:^(BOOL success, NSUInteger bytesAvailable, NSError * _Nullable error) {
        if (success == NO) {
            if (error) {
                NSLog(@"Something went wrong, image could not upload: %@", error);
            } else {
                // This will never happen
                NSLog(@"Something went wrong, and we don't know what happened.");
            }
        } else {
            if ([weakSelf.sdlManager.hmiLevel isEqualToEnum:[SDLHMILevel FULL]]) {
                [weakSelf showInitialData];
            }
        }
    }];
}

#pragma mark - SDLManagerDelegate

- (void)managerDidDisconnect {
    self.firstTimeState = SDLHMIFirstStateNone;
}

- (void)hmiLevel:(SDLHMILevel *)oldLevel didChangeToLevel:(SDLHMILevel *)newLevel {
    if (self.firstTimeState == SDLHMIFirstStateNone) {
        [self uploadInterfaceFiles];
    }
    
    if (![newLevel isEqualToEnum:[SDLHMILevel NONE]] && (self.firstTimeState == SDLHMIFirstStateNone)) {
        // This is our first time in a non-NONE state
        self.firstTimeState = SDLHMIFirstStateNonNone;
        
        // Send AddCommands
        [self.sdlManager sendRequest:[self speakNameCommand]];
        [self.sdlManager sendRequest:[self interactionSetCommand]];
    }
    
    if ([newLevel isEqualToEnum:[SDLHMILevel FULL]] && (self.firstTimeState != SDLHMIFirstStateFull)) {
        // This is our first time in a FULL state
        self.firstTimeState = SDLHMIFirstStateFull;
        
        [self showInitialData];
    }
}

@end
