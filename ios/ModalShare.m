#import "ModalShare.h"
#import <React/RCTLog.h>
#import <React/RCTLog.h>
#import <MessageUI/MFMailComposeViewController.h>

@import FBSDKCoreKit;
@import FBSDKShareKit;

@implementation ModalShare

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(shareNative:(NSString *)imagePath resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    NSString *imageFilePath = [imagePath stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    
    self.documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:imageFilePath]];
    self.documentInteractionController.delegate = self;
    self.documentInteractionController.UTI = @"net.whatsapp.image";
    [self.documentInteractionController presentOptionsMenuFromRect:CGRectZero inView:rootViewController.view animated:YES];
    
    resolve(@(true));
}

RCT_EXPORT_METHOD(getBase64String:(NSURL *)imagePath resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSData* data = [NSData dataWithContentsOfURL:imagePath];
        resolve([data base64EncodedStringWithOptions:0]);
    });
}

RCT_EXPORT_METHOD(checkAppExist:(NSString *)schemeURL resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    if ([schemeURL length] > 0){
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:schemeURL]]) {
                resolve(@(true));
            } else {
                resolve(@(false));
            }
        });
    } else {
        resolve(@(false));
    }
}


RCT_EXPORT_METHOD(shareTo:(NSString *)schemeURL data:(NSString *)data resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    NSMutableDictionary *json=[NSJSONSerialization JSONObjectWithData:[data dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
    
    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    
    NSString *message = @"";

    if ([json valueForKey:@"message"] != nil) {
        message = [[json valueForKey:@"message"] stringByAppendingString: @" "];
    }
    if ([json valueForKey:@"url"] != nil) {
        message = [message stringByAppendingString: [json valueForKey:@"url"]];
    }

    NSString *messageEncoded = [message stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
    
    __block NSURL *shareURL = nil;
    __block UIImage *image = nil;
    __block NSData *imageData = nil;
    __block NSString *imageFilePath = nil;
    __block NSString *imageMimeType = nil;
    __block NSString *imageFileName = nil;
    __block NSString *imageExt = nil;
    
    if ([json valueForKey:@"image"] != nil){
        imageFilePath = [[json valueForKey:@"image"] stringByReplacingOccurrencesOfString:@"file://" withString:@""];
        
        BOOL imageExists = [[NSFileManager defaultManager] fileExistsAtPath:imageFilePath];
        
        if (imageExists){
            image = [UIImage imageWithContentsOfFile:imageFilePath];
            
            imageFileName = [ModalShare getFileName:[json valueForKey:@"image"] withExtension:true];
            imageMimeType = [ModalShare getMimeType:imageFileName];
            imageExt = [imageMimeType stringByReplacingOccurrencesOfString:@"image/" withString:@"."];
            
            if ([imageExt isEqualToString:@".jpeg"]){
                imageData = UIImageJPEGRepresentation(image, 0.9);
            } else if ([imageExt isEqualToString:@".png"]){
                imageData = UIImagePNGRepresentation(image);
            }
        }
    }
    
    if ([schemeURL length] > 0){
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:schemeURL]]) {
                
                if ([schemeURL isEqualToString: @"whatsapp://"]){
                    shareURL = [NSURL URLWithString: [[schemeURL stringByAppendingString:@"send?text="] stringByAppendingString:messageEncoded]];
                } else if ([schemeURL isEqualToString: @"twitter://"]) {
                    shareURL = [NSURL URLWithString: [[schemeURL stringByAppendingString:@"post?message="] stringByAppendingString:messageEncoded]];
                } else if ([schemeURL isEqualToString: @"tg://"]) {
                    shareURL = [NSURL URLWithString: [[schemeURL stringByAppendingString:@"msg?text="] stringByAppendingString:messageEncoded]];
                }
                
                if ([schemeURL isEqualToString: @"fb://"]) {
                    FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] initWithViewController: rootViewController content: nil delegate: nil];
                    dialog.fromViewController = rootViewController;
                    
                    if ([image CIImage] != nil || [image CGImage] != NULL){
                        FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] initWithViewController: rootViewController content: nil delegate: nil];
                        FBSDKSharePhotoContent *content = [[FBSDKSharePhotoContent alloc] init];
                        content.photos = @[photo];
                        
                        dialog.shareContent = content;
                        dialog.mode = FBSDKShareDialogModeShareSheet;
                        [dialog show];
                    } else {
                        FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
                        content.contentURL = [NSURL URLWithString:[json valueForKey:@"url"]];
                        
                        dialog.shareContent = content;
                        dialog.mode = FBSDKShareDialogModeShareSheet;
                        [dialog show];
                    }
                }
                else if ([schemeURL isEqualToString: @"fb-messenger://"]) {
                    
                    if ([image CIImage] != nil || [image CGImage] != NULL){
                        FBSDKSharePhoto *photo = [[FBSDKSharePhoto alloc] initWithImage: image isUserGenerated:YES];
                        FBSDKSharePhotoContent *content = [[FBSDKSharePhotoContent alloc] init];
                        content.photos = @[photo];
                        
                        [FBSDKMessageDialog showWithContent:content delegate:nil];
                    } else {
                        
                        FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
                        content.contentURL = [NSURL URLWithString: [json valueForKey:@"url"]];
                        
                        [FBSDKMessageDialog showWithContent:content delegate:nil];
                    }
                    
                } else if ([schemeURL isEqualToString: @"mailto://"] && [MFMailComposeViewController canSendMail]) {
                    
                    MFMailComposeViewController *mcvc = [[MFMailComposeViewController alloc] init];
                    mcvc.mailComposeDelegate = self;
                    [mcvc setToRecipients:[NSArray arrayWithObjects:@"your@mates.com",nil]];
                    [mcvc setSubject: [json valueForKey:@"subject"]];
                    [mcvc setMessageBody:message isHTML:NO];
                    
                    if ([image CIImage] != nil || [image CGImage] != NULL){
                        [mcvc addAttachmentData:imageData mimeType:imageMimeType fileName:imageFileName];
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [rootViewController presentViewController:mcvc animated:YES completion:NULL];
                    });
                    
                } else if([schemeURL isEqualToString: @"message://"] && [MFMessageComposeViewController canSendText]) {
                    
                    MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
                    messageController.messageComposeDelegate = self;
                    messageController.recipients = [NSArray arrayWithObjects:@"012-3456789",nil];
                    messageController.body = message;
                    
                    if ([image CIImage] != nil || [image CGImage] != NULL){
                        if ([MFMessageComposeViewController canSendAttachments]){
                            [messageController addAttachmentData:imageData typeIdentifier:imageMimeType filename:imageFileName];
                        }
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [rootViewController presentViewController:messageController animated:YES completion:NULL];
                    });
                }
                else {
                    if ([image CIImage] != nil || [image CGImage] != NULL){
                        self.documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:imageFilePath]];
                        self.documentInteractionController.delegate = self;
                        self.documentInteractionController.UTI = @"net.whatsapp.image";
                        [self.documentInteractionController presentOptionsMenuFromRect:CGRectZero inView:rootViewController.view animated:YES];
                    }
                    [[UIApplication sharedApplication] openURL: shareURL];
                }
                
                resolve(@(true));
            } else {
                resolve(@(false));
            }
        });
    } else {
        resolve(@(false));
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    [rootViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    [rootViewController dismissViewControllerAnimated:YES completion:NULL];
}

+ (NSString *)getMimeType:(NSString *)fileName {
    NSArray *fileNameArray = [fileName componentsSeparatedByString:@"."];
    NSString *extension;
    
    if ([fileNameArray count] > 0){
        extension = [fileNameArray objectAtIndex:[fileNameArray count] - 1];
        
        if ([extension isEqualToString:@"jpg"] || [extension isEqualToString:@"jpeg"]){
            return @"image/jpeg";
        } else if ([extension isEqualToString:@"png"]){
            return @"image/png";
        }
    }
    return @"";
}

+ (NSString *)getFileName:(NSString *)filePath withExtension:(Boolean)wExt {
    NSArray *stringArray = [filePath componentsSeparatedByString:@"/"];
    NSString *fileName = [stringArray objectAtIndex:[stringArray count] - 1];
    
    if ([fileName length] > 0){
        NSArray *fileNameArray = [fileName componentsSeparatedByString:@"."];
        NSString *fileNameOnly = [fileNameArray objectAtIndex:0];
        
        if ([fileNameOnly length] > 0 && !wExt){
            return fileNameOnly;
        }
        return fileName;
    }
    return nil;
}

+ (NSString *)getFileExtension:(NSString *)filePath {
    NSArray *stringArray = [filePath componentsSeparatedByString:@"/"];
    NSString *fileName = [stringArray objectAtIndex:[stringArray count] - 1];
    
    if ([fileName length] > 0){
        NSArray *fileNameArray = [fileName componentsSeparatedByString:@"."];
        NSString *fileExtension = [fileNameArray objectAtIndex:[fileNameArray count] - 1];
        
        return fileExtension;
    }
    return nil;
}

@end
