#import "QRCode.h"


@implementation QRCode
@synthesize codeData = _codeData;
@synthesize type = _type;
@synthesize outputController = _outputController;


typedef enum {
	QRCodeTypeText = 0,
	QRCodeTypeLink = 1,
	QRCodeTypeSMS = 2,
	QRCodeTypeVCard = 3,
	QRCodeTypeCall = 4,
	QRCodeTypeGeolocation = 5,
	QRCodeTypeVEvent = 6,
	QRCodeTypeVCalendar = 7,



	
} QRCodeType;





-(id) initWithCodeData:(NSString*)codeDataString outputController:(QROutputController*)outputController{

	if((self = [super init])){
		self.codeData = codeDataString;
		self.type = [self parseCodeType];
		self.outputController = outputController;
        

	}

	return self;
}






-(int) parseCodeType{


	NSArray *components = [self.codeData componentsSeparatedByString: @":"];

	if([[components objectAtIndex:0] caseInsensitiveCompare:@"smsto"] == NSOrderedSame || [[components objectAtIndex:0] caseInsensitiveCompare:@"sms"] == NSOrderedSame){
		return QRCodeTypeSMS;
	}

	if([[components objectAtIndex:0] caseInsensitiveCompare:@"tel"] == NSOrderedSame){
		return QRCodeTypeCall;
	}

	if([self.codeData hasPrefix:@"BEGIN:VCARD"]){
		return QRCodeTypeVCard;
	}
	
	/*if([self.codeData hasPrefix:@"BEGIN:VEVENT"]){
		return QRCodeTypeVEvent;
	}*/


	NSURL *candidateURL = [NSURL URLWithString:self.codeData];
	if (candidateURL && candidateURL.scheme && candidateURL.host) {
		return QRCodeTypeLink;
	}
	
	
	
	return QRCodeTypeText;
}


static UIViewController *contactDialog;



-(void)deviceLockViewCancelButtonPressed:(id)pressed{
	CGRect lockViewFrame = [pressed frame];
    lockViewFrame.origin.y += [[pressed keypadView] frame].size.height + [[pressed entryView] frame].size.height;

	[UIView animateWithDuration:0.5
        delay:0
        options: UIViewAnimationCurveEaseOut
        animations:^{
            [pressed setFrame:lockViewFrame];
        }
        completion:^(BOOL finished){
            [pressed removeFromSuperview];
        }];

	[self.outputController setEnabled:true];
}



-(void)deviceLockViewPasscodeEntered:(id)entered{
	bool passwordCorrect = [[objc_getClass("SBDeviceLockController") sharedController] attemptDeviceUnlockWithPassword:[entered passcode] appRequested:false];
	
	if(!passwordCorrect){
		[entered setShowingEntryStatusWarning:true];
		[entered setPasscode:@""];
		return;
	}

	CGRect lockViewFrame = [entered frame];
    lockViewFrame.origin.y += [[entered keypadView] frame].size.height + [[entered entryView] frame].size.height;

	[UIView animateWithDuration:0.5
        delay:0
        options: UIViewAnimationCurveEaseOut
        animations:^{
            [entered setFrame:lockViewFrame];
        }
        completion:^(BOOL finished){

            [entered removeFromSuperview];

            if(self.type == QRCodeTypeSMS || self.type == QRCodeTypeVCard)
            	[self performAction];
            if(self.type == QRCodeTypeCall || self.type == QRCodeTypeLink){
            	//id ac = [objc_getClass("SBAssistantController") sharedInstance];
            	/*NSString *openingAppID = [[UIApplication sharedApplication] displayIDForURLScheme:[[NSURL URLWithString:self.codeData] scheme] isPublic:true];
            	NSObject *openingApp = [[objc_getClass("SBApplicationController") sharedInstance] applicationWithDisplayIdentifier:openingAppID];
            	NSObject *animationController = [[objc_getClass("SBUIAnimationController") alloc] initWithActivatingApp:openingApp deactivatingApp:[[objc_getClass("SBApplicationController") sharedInstance] applicationWithDisplayIdentifier:@"com.apple.springboard"]];
            	[animationController setDelegate:self];
            	[animationController beginAnimation];*/
            	
            	//[[objc_getClass("SBAwayController") sharedAwayController] dismissCameraAnimated:true];
				
				//[[UIApplication sharedApplication] applicationOpenURL:[NSURL URLWithString:self.codeData] withApplication:openingApp sender:nil publicURLsOnly:false animating:true needsPermission:false additionalActivationFlags:[NSString new]];
				
				//[[UIApplication sharedApplication] applicationOpenURL:[NSURL URLWithString:self.codeData]];
				dispatch_async(dispatch_get_main_queue(), ^{
					[[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.codeData]];
				});
			}
            	//[[objc_getClass("SBAssistantController") sharedInstance] uiPlugin:[objc_getClass("SBAssistantController") sharedInstance] launchApplicationWithBundleID:@"com.apple.mobilesafari" openURL:[NSURL URLWithString:self.codeData]];
            	
        }];



}

-(void)animationControllerDidFinishAnimation:(id)arg1{
	NSLog(@"Finished animation!");
}

- (void)animationController:(id)arg1 didCommitAnimation:(BOOL)arg2 withDuration:(double)arg3 afterDelay:(double)arg4{

}

- (void)animationController:(id)arg1 willBeginAnimation:(BOOL)arg2{

}

-(void) displayPasscodeView{
	UIView *lockView = [objc_getClass("SBDeviceLockView") newWithStyle:[objc_getClass("SBDeviceLockView") defaultStyleForSiri] interfaceOrientation:1 showsEmergencyCall:false];
    [lockView setDelegate:self];
	[[lockView statusView] setHidden:true];
	CGRect lockViewFrame = [lockView frame];
    lockViewFrame.origin.y += [[lockView keypadView] frame].size.height + [[lockView entryView] frame].size.height;
    [lockView setFrame:lockViewFrame];
    lockViewFrame.origin.y = 0;
    [lockView setPlaysKeyboardClicks:true];
    //[[[UIApplication sharedApplication] keyWindow] addSubview:lockView];
	[[[[objc_getClass("SBAwayController") sharedAwayController] valueForKey:@"_cameraViewController"] view] addSubview:lockView];
    [UIView animateWithDuration:0.5
        delay:0
        options: UIViewAnimationCurveEaseOut
        animations:^{
            [lockView setFrame:lockViewFrame];
        }
        completion:^(BOOL finished){
            [lockView release];
        }];
}




-(void) performAction{
	switch(self.type){




		case QRCodeTypeText:
		{
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:self.codeData
                                                                     delegate:self
                                                            cancelButtonTitle:nil
                                                       destructiveButtonTitle:nil
                                                            otherButtonTitles:nil];
            [actionSheet addButtonWithTitle:@"Copy"];
            actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:@"Cancel"];

            [actionSheet showInView:[[UIApplication sharedApplication] keyWindow]];
            
           
            
       
		break;
		}








		case QRCodeTypeCall:
		{
			self.codeData = [self.codeData stringByReplacingOccurrencesOfString:@"TEL:" withString:@"tel:"];
			NSArray *components = [self.codeData componentsSeparatedByString: @":"];
            
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:[components objectAtIndex:1]
                                                                     delegate:self
                                                            cancelButtonTitle:nil
                                                       destructiveButtonTitle:nil
                                                            otherButtonTitles:nil];
            
            [actionSheet addButtonWithTitle:@"Call"];
        	
            [actionSheet addButtonWithTitle:@"Copy"];
            actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:@"Cancel"];
            
            [actionSheet showInView:[[UIApplication sharedApplication] keyWindow]];
			//[alert release];
			break;
		}



		case QRCodeTypeLink:
		{
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:self.codeData
                                                                     delegate:self
                                                            cancelButtonTitle:nil
                                                       destructiveButtonTitle:nil
                                                            otherButtonTitles:nil];
           
            [actionSheet addButtonWithTitle:@"Open"];
        	

            [actionSheet addButtonWithTitle:@"Copy"];
            actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:@"Cancel"];
            
            [actionSheet showInView:[[UIApplication sharedApplication] keyWindow]];
			//[alert release];
		break;

		}






		
		case QRCodeTypeSMS:
		{

			MFMessageComposeViewController *controller = [[[MFMessageComposeViewController alloc] init] autorelease];
			if([MFMessageComposeViewController canSendText])
			{
				NSArray *components = [self.codeData componentsSeparatedByString: @":"];
				controller.body = [components objectAtIndex:2];
				controller.recipients = [NSArray arrayWithObjects:[components objectAtIndex:1], nil];
				controller.messageComposeDelegate = self;
				




				if(![[objc_getClass("SBAwayController") sharedAwayController] cameraIsVisible]){
					[[UIApplication sharedApplication] setStatusBarHidden:false animated:true];
					[[[[UIApplication sharedApplication] keyWindow] rootViewController] presentModalViewController:controller animated:true];
				}else{
					  
            			if([[objc_getClass("SBDeviceLockController") sharedController] isDeviceLocked]){
            				
            				//DEBUGGING STUFF

            				/*[[objc_getClass("SBUIController") sharedInstance] promptUnlockForAppActivation:nil withCompletion:^(BOOL finished){
            					NSLog("Completion");
            				}];
            				return;*/

            				//END DEBUGGING

            				[self displayPasscodeView];
            			 	[self.outputController setEnabled:false];
            				return;
            			}
            		[[UIApplication sharedApplication] setStatusBarHidden:false animated:true];
					[[[objc_getClass("SBAwayController") sharedAwayController] valueForKey:@"_cameraViewController"] presentModalViewController:controller animated:true];
				}
			
				
			}
		}


		case QRCodeTypeVEvent:
		{
			
			EKEvent *event = [self parseVEvent:self.codeData];
			/*EKEventStore *store = [[EKEventStore alloc] init];
			[store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
   
			}];*/
		}

		case QRCodeTypeVCard:
		{
			

			CFDataRef vCardData = (CFDataRef)[self.codeData dataUsingEncoding:NSUTF8StringEncoding];
// If you're using ARC, use this line instead:
//CFDataRef vCardData = (__bridge CFDataRef)[vCardString dataUsingEncoding:NSUTF8StringEncoding];

			ABAddressBookRef book = ABAddressBookCreate();
			ABRecordRef defaultSource = ABAddressBookCopyDefaultSource(book);
			CFArrayRef vCardPeople = ABPersonCreatePeopleInSourceWithVCardRepresentation(defaultSource, vCardData);
			for (CFIndex index = 0; index < CFArrayGetCount(vCardPeople); index++) {
    				ABRecordRef person = CFArrayGetValueAtIndex(vCardPeople, index);




				ABUnknownPersonViewController *unknownPersonViewController = [[ABUnknownPersonViewController alloc] init];
				contactDialog = unknownPersonViewController;

    				unknownPersonViewController.displayedPerson = (ABRecordRef) person;
    				unknownPersonViewController.allowsAddingToAddressBook = YES;
				unknownPersonViewController.allowsActions = YES;
				unknownPersonViewController.unknownPersonViewDelegate = self;
				UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:unknownPersonViewController];

				unknownPersonViewController.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeContactDialog)] autorelease];
	
	 				if(![[objc_getClass("SBAwayController") sharedAwayController] cameraIsVisible]){
						[[UIApplication sharedApplication] setStatusBarHidden:false animated:true];
    					[[[[UIApplication sharedApplication] keyWindow] rootViewController] presentModalViewController:nc animated:true];
    				}else{
    				    
            			if([[objc_getClass("SBDeviceLockController") sharedController] isDeviceLocked]){
            				[self displayPasscodeView];
            				 [self.outputController setEnabled:false];
            				return;
            			}
            			[[UIApplication sharedApplication] setStatusBarHidden:false animated:true];
						[[[objc_getClass("SBAwayController") sharedAwayController] valueForKey:@"_cameraViewController"] presentModalViewController:nc animated:true];

    				}
    				[unknownPersonViewController release];





    				//ABAddressBookAddRecord(book, person, NULL);
    				//CFRelease(person);
			}

			CFRelease(vCardPeople);
			CFRelease(defaultSource);
			//ABAddressBookSave(book, NULL);
			//CFRelease(book);
			
		}

		
	}
    [self.outputController setEnabled:false];
//[[QROutputController sharedInstance] setEnabled:false];
}



- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
	NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];

	if([buttonTitle isEqualToString:@"Copy"]){
		switch(self.type){
			case QRCodeTypeText:{
   				UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            	pasteboard.string = self.codeData;
            	break;
			}
			case QRCodeTypeLink:{
				  UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            	 pasteboard.string = [actionSheet title];
			}
			case QRCodeTypeCall:{
 				 UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            	 pasteboard.string = [actionSheet title];
			}
		}
	}else if([buttonTitle isEqualToString:@"Open"] || [buttonTitle isEqualToString:@"Call"]){
		switch(self.type){
			case QRCodeTypeCall:{
				if([[objc_getClass("SBDeviceLockController") sharedController] isDeviceLocked]){
            				[self displayPasscodeView];
            				return;
            	}
				//[[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.codeData]];
				
			}

			case QRCodeTypeLink:{
				if([[objc_getClass("SBDeviceLockController") sharedController] isDeviceLocked]){
            				[self displayPasscodeView];
            				return;
            	}
				//[[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.codeData]];
				/*NSObject *openingApp = [[UIApplication sharedApplication] displayIDForURLScheme:[[NSURL URLWithString:self.codeData] scheme] isPublic:true];

				[[UIApplication sharedApplication] applicationOpenURL:[NSURL URLWithString:self.codeData] withApplication:openingApp sender:nil publicURLsOnly:false animating:true needsPermission:false additionalActivationFlags:nil];
            	*/
            	
            	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.codeData]];

			}
		}
	}

     [self.outputController setEnabled:true];
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 0) {
		
	}else {
		if(self.type == QRCodeTypeLink || self.type == QRCodeTypeCall){
			 [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.codeData]];
		}
	}
     [self.outputController setEnabled:true];
}



- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result{
	[[UIApplication sharedApplication] setStatusBarHidden:true animated:true];	
	[controller dismissModalViewControllerAnimated:true];	
	[self.outputController setEnabled:true];
}


- (void)unknownPersonViewController:(ABUnknownPersonViewController *)unknownPersonView didResolveToPerson:(ABRecordRef)person{
	//[unknownPersonView dismissModalViewControllerAnimated:true];
     [self.outputController setEnabled:true];
	return;
}


-(void) closeContactDialog{
	[[UIApplication sharedApplication] setStatusBarHidden:true animated:true];
	[contactDialog dismissModalViewControllerAnimated:true];
     [self.outputController setEnabled:true];
}


-(EKEvent*)parseVEvent:(NSString*)data{
	/*EKEventStore *store = [[EKEventStore alloc] init];
	EKEvent *event = [EKEvent eventWithEventStore:store];

	NSArray* dataLines = [data componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	for(NSString *line in dataLines){
		
		if([line hasPrefix:@"SUMMARY:"]){
			int index = [line rangeOfString:@":"].location;
			NSLog(@"SUMMARY: %i", index);
		}


	}
	return event;*/

}





@end
