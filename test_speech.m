#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import <Speech/Speech.h>

@interface MyAppDelegate : NSObject <NSApplicationDelegate> {
    AVAudioEngine *audioEngine;
    SFSpeechAudioBufferRecognitionRequest *recognitionRequest;
    SFSpeechRecognitionTask *recognitionTask;
}
@end

@implementation MyAppDelegate
- (id)init {
    self = [super init];
    audioEngine = [[AVAudioEngine alloc] init];
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSArray *args = [[NSProcessInfo processInfo] arguments];
    
    SFSpeechRecognizer *speechRecognizer;
    if ([args count] > 1) {
        speechRecognizer= [[SFSpeechRecognizer alloc] initWithLocale: [NSLocale localeWithLocaleIdentifier: args[1]]];
    } else {
        speechRecognizer = [[SFSpeechRecognizer alloc] init];
    }
    AVAudioInputNode *inputNode = [audioEngine inputNode];
    AVAudioFormat *format = [inputNode outputFormatForBus: 0];
    [inputNode installTapOnBus: 0 bufferSize: 1024 format: format  block: ^(AVAudioPCMBuffer *buf, AVAudioTime *when) {
        [self->recognitionRequest appendAudioPCMBuffer: buf];
    }];
    
    [SFSpeechRecognizer requestAuthorization: ^(SFSpeechRecognizerAuthorizationStatus status){
        self->recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
        
        recognitionRequest.shouldReportPartialResults = true;
        [speechRecognizer recognitionTaskWithRequest: recognitionRequest resultHandler: ^(SFSpeechRecognitionResult *result, NSError *error) {
            bool isFinal = false;
            
            if (result) {
                isFinal = result.isFinal;
                NSLog(@"text: %@", result.bestTranscription.formattedString);
                NSLog(@"isFinal: %d", result.isFinal);
                
                if ((error != nil) || isFinal) {
                    NSLog(@"clean up");
                    [self->audioEngine stop];
                    [inputNode removeTapOnBus: 0];
                    self->recognitionRequest = nil;
                    self->recognitionTask = nil;
                    [[NSApplication sharedApplication] terminate:self];
                }
            }
            return;
        }];
        NSLog(@"start audio engine");
        [audioEngine prepare];
        [audioEngine startAndReturnError: nil];
        
        return;
    }];
}

@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        [app setDelegate:[[[MyAppDelegate alloc] init] autorelease]];
        [app run];
    }
    return 0;
}
