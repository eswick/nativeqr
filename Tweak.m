#import <UIKit/UIKit.h>
#import <ZBarSDK/ZBarSDK.h>
#import <CoreGraphics/CoreGraphics.h>
#import <AVFoundation/AVFoundation.h>
//#import <PhotoLibrary/PhotoLibrary.h>
#import "QROutputController.h"
#import "QRCode.h"
#import "QREncoder.h"
#import "DataMatrix.h"


#define OPTIONS_PANE_SPACER_SIZE 15


static char qrControllerKey;



typedef enum {
    PLCameraModePhoto = 0,
    PLCameraModeVideo = 1,
    PLCameraModePanorama = 2
} PLCameraMode;

typedef enum {
    PLCameraDeviceBack = 0,
    PLCameraDeviceFront = 1
} PLCameraDevice;



/* Debug code
%hook SpringBoard



- (void)applicationOpenURL:(id)arg1 withApplication:(id)arg2 sender:(id)arg3 publicURLsOnly:(BOOL)arg4 animating:(BOOL)arg5 needsPermission:(BOOL)arg6 additionalActivationFlags:(id)arg7{
	NSLog(@"arg1: %@\narg2: %@\narg3: %@\npublicURLsOnly: %d\nanimating: %d\nneedsPermission: %d\nadditionalActivationFlags: %@", arg1, arg2, arg3, arg4, arg5, arg6, arg7);
	%orig;
}


%end */

@interface PLCameraController : NSObject{

}

@property(readonly) float panoramaPreviewScale;
@property(readonly, nonatomic) struct CGSize panoramaPreviewSize;

@end


%hook PLCameraController


%new
- (void)_associateQRController:(id) object{
    objc_setAssociatedObject(self, &qrControllerKey, object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new
- (id)_getQRController {
    return objc_getAssociatedObject(self, &qrControllerKey);
}

%new 
-(void)qrCodeSwitchChanged:(id) sender{
	if([sender isOn]){
      		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		[userDefaults setBool:true forKey:@"PLQRIsEnabled"];
		[userDefaults synchronize];
		[[self _getQRController] setEnabledBySwitch:true];
    } else{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setBool:false forKey:@"PLQRIsEnabled"];
	[userDefaults synchronize];
    	[[self _getQRController] setEnabledBySwitch:false];
    }
}






- (BOOL)_setupCamera {
	NSLog(@"Setup Camera");
    BOOL orig = %orig();
    
    if ([self isCameraApp] && orig) {
        QROutputController *outputController = [[QROutputController alloc] init];
        [outputController setDelegate:self];

        [self _associateQRController:outputController];
        
        [outputController release];
    }
    
    return orig;
}

/*
- (void)_destroyCamera{
	//[self _associateQRController:nil];
	%orig;
}*/
- (void)_setCameraMode:(int)arg1 cameraDevice:(int)arg2 {
	NSLog(@"Set camera mode!");
	%orig;
}

- (void)_configureSessionWithCameraMode:(PLCameraMode)cameraMode cameraDevice:(PLCameraDevice)cameraDevice {

	/*if(cameraMode != PLCameraModePanorama){
		%orig;
	}*/

   


    	AVCaptureOutput *output = [[self _getQRController] output];
    if (!output) return;
    

    if (cameraMode == PLCameraModePhoto) {
        if ([[self currentSession] canAddOutput:output]) {
        	if(![[[self currentSession] outputs] containsObject:output]){
            	[[self currentSession] addOutput:output];
        	}
			[[self _getQRController] setEnabled:true];
        }else{
        	NSLog(@"Can't add output!");
        }
    } else {
		[[self _getQRController] setEnabled:false];
		
		if([[[self currentSession] outputs] containsObject:output]){

    		[[self currentSession] removeOutput:output];
    	}
       
    }

    //if(cameraMode == PLCameraModePanorama){
    	%orig;
    //}

    NSLog(@"Controller preview scale: %f", [[objc_getClass("PLCameraController") sharedInstance] panoramaPreviewScale]);
	CGSize previewSize = [[objc_getClass("PLCameraController") sharedInstance] panoramaPreviewSize];
	NSLog(@"Controller preview size: width: %f, height: %f", previewSize.width, previewSize.height);
    


    NSLog(@"%@", [[self currentSession] outputs]);
}

/*- (void)cameraControllerModeWillChange:(id)cameraController{
		AVCaptureOutput *output = [[self _getQRController] output];
    if (!output) return;
	[[self currentSession] removeOutput:output];

		[[self _getQRController] setEnabled:false];
		%orig;
}*/

%new
- (void)scannedSymbols:(ZBarSymbolSet*)symbols{
	for(ZBarSymbol *symbol in symbols){
		QRCode *code = [[QRCode alloc] initWithCodeData:[symbol data] outputController:[self _getQRController]];
 		[code performAction];
		//[code release];
	}
}



%end



%hook PLCameraPanoramaView



- (id)initWithFrame:(struct CGRect)arg1 centerYOffset:(float)arg2 panoramaPreviewScale:(float)arg3 panoramaPreviewSize:(struct CGSize)arg4{
	/*
	NSArray *stack = [NSThread callStackSymbols];
	NSString *methodThatDidLogging = [stack objectAtIndex:1];

	NSLog(@"Method: %@", methodThatDidLogging);

	NSLog(@"frame: width: %f height: %f", arg1.size.width, arg1.size.height);
	NSLog(@"Center Y offset: %f", arg2);
	NSLog(@"Preview scale: %f", arg3);
	NSLog(@"Preview Size: width: %f height: %f", arg4.width, arg4.height);

	NSLog(@"Controller preview scale: %f", [[objc_getClass("PLCameraController") sharedInstance] panoramaPreviewScale]);

	
	NSLog(@"Controller preview size: width: %f, height: %f", previewSize.width, previewSize.height);*/
	CGSize previewSize = CGSizeMake(306, 86);

	return %orig(arg1, arg2, 0.5, previewSize);
}




%end








static char qrGroupKey;

%hook PLCameraSettingsView

%new
- (void)setQRGroup:(id) object{
    objc_setAssociatedObject(self, &qrGroupKey, object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new
- (id)qrGroup {
    return objc_getAssociatedObject(self, &qrGroupKey);
}




- (id)initWithFrame:(CGRect)arg1 showGrid:(BOOL)arg2 showHDR:(BOOL)arg3 showPano:(BOOL)arg4{
	Class PLCameraSettingsGroupView = objc_getClass("PLCameraSettingsGroupView");


	UIView *qrGroup = [[PLCameraSettingsGroupView alloc] initWithFrame:CGRectMake(0, 0, arg1.size.width, 50)];
	[qrGroup setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
	[qrGroup setTitle:@"Enable QR"];


	UISwitch *qrSwitch = [[UISwitch alloc] init];
	[qrSwitch addTarget:[objc_getClass("PLCameraController") sharedInstance] action:@selector(qrCodeSwitchChanged:) forControlEvents:UIControlEventValueChanged];
	[qrSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"PLQRIsEnabled"] animated:false];
	[[objc_getClass("PLCameraController") sharedInstance] qrCodeSwitchChanged:qrSwitch];
	[qrSwitch setOnTintColor:[UIColor colorWithRed:0.176 green:0.176 blue:0.176 alpha:1]];
	[qrGroup setAccessorySwitch:qrSwitch];


	CGRect arg1modifier = arg1;
	arg1modifier.size.height += qrGroup.frame.size.height + OPTIONS_PANE_SPACER_SIZE;


	self = %orig(arg1modifier, arg2, arg3, arg4);



	[self setClipsToBounds:true];
	
	[self setQRGroup:qrGroup];

	return self;
	
}

- (void)layoutSubviews{
	%orig;
	UIView *qrGroup = [self qrGroup];
	
	CGRect arg1modifier = [self frame];
	arg1modifier.size.height += qrGroup.frame.size.height + OPTIONS_PANE_SPACER_SIZE;
	[self setFrame:arg1modifier];
	

	
	[qrGroup setType:0];	
	[self addSubview:qrGroup];
	
	for (UIView *subview in [self subviews]){
		if(subview == qrGroup) continue;
		CGRect frame = subview.frame;
		frame.origin.y += qrGroup.frame.size.height + OPTIONS_PANE_SPACER_SIZE;
		[subview setFrame:frame];
	}
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
		CGRect frame = [self frame];
		frame.origin.y -= qrGroup.frame.size.height + OPTIONS_PANE_SPACER_SIZE;
		[self setFrame:frame];
	}

}

%end







/*

%hook ABPersonTableViewActionsDelegate

- (id)addActionWithTitle:(id)arg1 content:(id)arg2 target:(id)arg3 selector:(SEL)arg4 property:(int)arg5 actionGrouping:(int)arg6 ordering:(int)arg7{
	NSLog(@"Title: %@", arg1);
	%orig;
}
- (id)addActionWithTitle:(id)arg1 shortTitle:(id)arg2 detailText:(id)arg3 style:(int)arg4 target:(id)arg5 selector:(SEL)arg6 property:(int)arg7 actionGrouping:(int)arg8 ordering:(int)arg9{
NSLog(@"Title: %@", arg1);
	%orig;
}
- (id)addActionWithTitle:(id)arg1 shortTitle:(id)arg2 target:(id)arg3 selector:(SEL)arg4 property:(int)arg5 actionGrouping:(int)arg6 ordering:(int)arg7{
NSLog(@"Title: %@", arg1);
	%orig;
}


%end*/






@interface ABActionSheetDelegate : NSObject{

}

-(BOOL)canShareContact;

@end




%hook SBAssistantController

- (BOOL)uiPlugin:(id)arg1 openURL:(id)arg2{
	NSLog(@"UIPlugin: %@", arg1);
	return %orig;
}

- (BOOL)uiPlugin:(id)arg1 launchApplicationWithBundleID:(id)arg2 openURL:(id)arg3{
	NSLog(@"(bundleID) UIPlugin: %@", arg1);
	return %orig;
}


%end


%hook ABPersonTableViewSharingDelegate


- (void)shareContact:(id)arg1{
	 

	   UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Share Contact Using:"
                                                                 delegate:self
                                                        cancelButtonTitle:nil
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:nil];
	if([self canSendMail]){
		[actionSheet addButtonWithTitle:@"Email"];
	}
	if([self canSendMMS]){
		[actionSheet addButtonWithTitle:@"Message"];
	}

	[actionSheet addButtonWithTitle:@"QR Code"];
	actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:@"Cancel"];
	[actionSheet showInView:[[self helper] viewForActionSheet]];
	//[actionSheet release];
	//%orig;
}


%new
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
	switch(buttonIndex){
		case 0:[self shareContactByEmail:self]; break;
		case 1:[self shareContactByTextMessage:self]; break;
		case 2:[self shareContactByQRCode]; break;
	}

}

- (BOOL)canShareContact{
	return true;
}

static UINavigationController *qrController;

%new
-(void)shareContactByQRCode{
	UIViewController *viewController = [[UIViewController alloc] init];
	UINavigationController *navController = [[UINavigationController alloc] init];

	 
    


	[viewController setTitle:@"Share"];
    
	 UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeQRView)];
	
	viewController.navigationItem.rightBarButtonItem = closeButton;

	

	ABRecordRef person = [[self helper] _personToUseForAddressBook];

	ABRecordRef people[1];
	people[0] = person;
	CFArrayRef peopleArray = CFArrayCreate(NULL, (const void **)people, 1, &kCFTypeArrayCallBacks);
	NSData *vCardData = CFBridgingRelease(ABPersonCreateVCardRepresentationWithPeople(peopleArray));
	NSString *vCard = [[NSString alloc] initWithData:vCardData encoding:NSUTF8StringEncoding];




	 int qrcodeImageDimension = viewController.view.bounds.size.width;
	  DataMatrix* qrMatrix = [QREncoder encodeWithECLevel:QR_ECLEVEL_AUTO version:QR_VERSION_AUTO string:[self removeImageFromVCF:vCard]];
	  UIImage* qrcodeImage = [QREncoder renderDataMatrix:qrMatrix imageDimension:qrcodeImageDimension];
	 UIImageView* qrcodeImageView = [[UIImageView alloc] initWithImage:qrcodeImage];
	CGRect controllerFrame = [viewController.view frame];
	[qrcodeImageView setFrame:CGRectMake(0, 0, controllerFrame.size.width, controllerFrame.size.width)];




	
    UITableView *backgroundView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] bounds] style: UITableViewStyleGrouped];
    backgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [viewController.view addSubview:backgroundView];
    [viewController.view addSubview:qrcodeImageView];

	[navController pushViewController:viewController animated:NO];

	viewController.view.backgroundColor = [UIColor whiteColor];
	[[[self helper] viewController] presentModalViewController:navController animated:YES];
	qrController = navController;


	[qrcodeImageView setCenter:[backgroundView center]];
	
	//[[self helper] pushViewController:viewController];
    /*UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(someMethod)];
    [self navigationItem] setLeftBarButtonItem:cancelButton];
    [cancelButton release];*/
}


%new
-(void)closeQRView{
	[qrController dismissModalViewControllerAnimated:true];
}

%new 
- (NSString *)removeImageFromVCF:(NSString *)yourString { //Gracias freshking

NSScanner *theScanner;
NSString *text = nil;

theScanner = [NSScanner scannerWithString:yourString];

if ([yourString rangeOfString:@"X-SOCIALPROFILE"].location == NSNotFound) {

    while ([theScanner isAtEnd] == NO) {

        [theScanner scanUpToString:@"PHOTO" intoString:NULL] ;
        [theScanner scanUpToString:@"END:VCARD" intoString:&text] ;

        yourString = [yourString stringByReplacingOccurrencesOfString:
                      [NSString stringWithFormat:@"%@", text] withString:@""];
    }

}else{

    while ([theScanner isAtEnd] == NO) {

        [theScanner scanUpToString:@"PHOTO" intoString:NULL] ;
        [theScanner scanUpToString:@"X-SOCIALPROFILE" intoString:&text] ;

        [theScanner scanUpToString:@"END:VCARD" intoString:NULL];

        yourString = [yourString stringByReplacingOccurrencesOfString:
                      [NSString stringWithFormat:@"%@", text] withString:@""];


    }

}

return yourString;
}

%end




