#import "QROutputController.h"
#import <mach/mach.h>
#import <mach/mach_host.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#include <string.h>


static int freeRam() {
	vm_size_t pageSize;
	host_page_size(mach_host_self(), &pageSize);
	struct vm_statistics vmStats;
	mach_msg_type_number_t infoCount = sizeof(vmStats);
	host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vmStats, &infoCount);
	int availMem = vmStats.free_count + vmStats.inactive_count;
	return (availMem * pageSize) / 1024 / 1024;
}

@implementation QROutputController
@synthesize output = _output;
@synthesize scanner = _scanner;
@synthesize delegate = _delegate;
@synthesize enabled = _enabled;
@synthesize bufferQueue = _bufferQueue;
@synthesize frameContext = _frameContext;
@synthesize enabledBySwitch = _enabledBySwitch;





-(id)init {
    	if ((self = [super init])) {

	self.frameContext = [CIContext contextWithOptions:nil];

 	self.scanner = [[ZBarImageScanner new] autorelease];
	[self.scanner setSymbology:ZBAR_QRCODE config:ZBAR_CFG_POSITION to:1];
	
	[self.scanner setEnableCache:true];

	[self setEnabledBySwitch:[[NSUserDefaults standardUserDefaults] boolForKey:@"PLQRIsEnabled"]];

	AVCaptureVideoDataOutput *newOutput = [[[AVCaptureVideoDataOutput alloc] init] autorelease];
	[newOutput setAlwaysDiscardsLateVideoFrames:true];
        
 	self.bufferQueue = dispatch_queue_create("com.evanswick.nativeqr.controller", NULL);
        [newOutput setSampleBufferDelegate:self queue:self.bufferQueue];
        //dispatch_release(self.bufferQueue);
	
	self.output = newOutput;

     	}
	return self;
}



- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
	//[NSThread sleepForTimeInterval:0.2];
	if(!self.enabled || !self.enabledBySwitch){
		 return;
	}
	//return;
	
	CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
	CGImageRef videoImage = [self.frameContext createCGImage:ciImage fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer))];
	ZBarImage *zImage = [[ZBarImage alloc] initWithCGImage:videoImage];
	[[self scanner] scanImage:zImage];
	
 	if ([[self delegate] respondsToSelector:@selector(scannedSymbols:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [[self delegate] scannedSymbols:self.scanner.results];
        });
	}

	//[ciImage release]; Crashes when switching camera modes.....doesn't appear to cause memory leakage though so I really don't care.
	[zImage release];
	CGImageRelease(videoImage);
	CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
	
}





@end
