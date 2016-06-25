//
//  PDFReaderViewController.h
//  PDFReader
//
//  Created by Sudeshna Roy on 12/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LeavesViewController.h"

@interface PDFReaderViewController : LeavesViewController <UITextFieldDelegate, UISearchBarDelegate>{
	CGPDFDocumentRef pdf;
	QImageView *qImageView;
	UITextField *pageNumberTextField;
	
	NSString *fileName;

}
@property (nonatomic,retain) QImageView *qImageView;
@property (nonatomic,retain) NSString *fileName;

- (id)init;
- (id)initWithFileName:(NSString *)name;
-(IBAction)saveSignature;
-(IBAction)clearAnnotation;

- (BOOL) parsePDF;
@end

