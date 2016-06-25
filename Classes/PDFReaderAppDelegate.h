//
//  PDFReaderAppDelegate.h
//  PDFReader
//
//  Created by Sudeshna Roy on 12/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BookViewController;

@interface PDFReaderAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    BookViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet BookViewController *viewController;

@end

