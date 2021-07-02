#import <UIKit/UIKit.h>
#import <MessageUI/MFMessageComposeViewController.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <React/RCTBridgeModule.h>

@interface ModalShare : NSObject <RCTBridgeModule, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, UIDocumentInteractionControllerDelegate>

@property (nonatomic, strong) UIDocumentInteractionController *documentInteractionController;

@end
