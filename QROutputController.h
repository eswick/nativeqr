#import <ZBarSDK/ZBarSDK.h>
#import <CoreGraphics/CoreGraphics.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>


@class QROutputController;



@protocol QROutputControllerDelegate <NSObject>
@optional
- (void)scannedSymbols:(ZBarSymbolSet*) symbols;
@end



@interface QROutputController : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>{
	ZBarImageScanner *scanner;
	AVCaptureVideoDataOutput *output;
	dispatch_queue_t queue;
	CIContext *frameContext;
}

@property (nonatomic, retain) AVCaptureVideoDataOutput *output;
@property (nonatomic, retain) ZBarImageScanner *scanner;
@property (nonatomic, assign) id<QROutputControllerDelegate> delegate;
@property (nonatomic, readwrite) BOOL enabled;
@property (nonatomic, readwrite) BOOL enabledBySwitch;
@property (nonatomic, readwrite) dispatch_queue_t bufferQueue;
@property (nonatomic, retain) CIContext *frameContext;


@end



