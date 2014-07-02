#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <EventKit/EventKit.h>
#import "QROutputController.h"




@interface QRCode : NSObject <UIAlertViewDelegate>{
	NSString *codeData;
    QROutputController *outputController;
	int type;
}
@property (nonatomic, retain) NSString *codeData;
@property (nonatomic, readwrite) int type;
@property (nonatomic, retain) QROutputController *outputController;



-(id) initWithCodeData:(NSString*)codeData outputController:(QROutputController*)outputController;
-(int) parseCodeType;
-(void) performAction;




@end




