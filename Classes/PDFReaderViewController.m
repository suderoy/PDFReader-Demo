 //
//  PDFReaderViewController.m
//  PDFReader
//
//  Created by Sudeshna Roy on 12/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PDFReaderViewController.h"
#import "Utilities.h"

@implementation PDFReaderViewController
@synthesize qImageView, fileName;
static BOOL annotating ;
int pageNum;

-(id)init {
	if (self = [super init]) {
		annotating = NO;
		fileName = @"overview_ipad_security.pdf";
		[[NSUserDefaults standardUserDefaults] setObject:self.fileName forKey:@"FILE_NAME"];
		CFURLRef  pdfURL = CFBundleCopyResourceURL(CFBundleGetMainBundle(), CFSTR("SCJP Sun Certified Programmer for Java 6-0071591060.pdf"), NULL, NULL);
		pdf = CGPDFDocumentCreateWithURL((CFURLRef)pdfURL);
		CFRelease(pdfURL);
    }
    return self;
}
- (id)initWithFileName:(NSString *)name {
    if (self = [super init]) {
		annotating = NO;
		self.fileName = name;
		if(fileName == nil)
			fileName = @"MobileHIG.pdf";
		
		[[NSUserDefaults standardUserDefaults] setObject:self.fileName forKey:@"FILE_NAME"];
		NSString *filePath = [NSString stringWithFormat:@"%@/%@",[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0],self.fileName];
		
		CFStringRef cfstring=(CFStringRef)filePath;
		CFURLRef  pdfURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, cfstring, 0, 0);
		//CFURLRef  pdfURL = CFBundleCopyResourceURL(CFBundleGetMainBundle(), cfstring, NULL, NULL);
		pdf = CGPDFDocumentCreateWithURL((CFURLRef)pdfURL);
		//CFRelease(pdfURL);
    }
    return self;
}

- (void)dealloc {
	CGPDFDocumentRelease(pdf);
	[pageNumberTextField release];
	[fileName release];
    [super dealloc];
}

-(void)openLink:(UIButton *)sender{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:sender.titleLabel.text]];
}
NSString *searchText;
NSMutableArray *hightlerArray;

- (void) displayPageNumber:(NSUInteger)pageNumber {
	pageNumberTextField.text = [NSString stringWithFormat:
								@"%u of %u", 
								pageNumber, 
								CGPDFDocumentGetNumberOfPages(pdf)];
	pageNum=pageNumber;
    
    for(UIView *view in [self.view subviews]){
        if([view isKindOfClass:[UILabel class]])
            [view removeFromSuperview];
    }
}

#pragma mark  LeavesViewDelegate methods
- (void) leavesView:(LeavesView *)leavesView willTurnToPageAtIndex:(NSUInteger)pageIndex {
	[self displayPageNumber:pageIndex + 1];
}
- (void) leavesView:(LeavesView *)leavesView touchesBeganInPageAtIndex:(NSUInteger)pageIndex{
	qImageView.hidden=YES;
}
- (void) leavesView:(LeavesView *)leavesView touchesEndInPageAtIndex:(NSUInteger)pageIndex{
	qImageView.hidden=NO;
}
#pragma mark LeavesViewDataSource methods

- (NSUInteger) numberOfPagesInLeavesView:(LeavesView*)leavesView {
	return CGPDFDocumentGetNumberOfPages(pdf);
}
UIButton *button;
- (void) renderPageAtIndex:(NSUInteger)index inContext:(CGContextRef)ctx {
	
	
	//If the view already contains a button control remove it
//	if ([[self.view subviews] containsObject:button]) {
//		[button removeFromSuperview];
//	}
    for(UIView *view in [self.view subviews]){
        if([view isKindOfClass:[UIButton class]])
            [view removeFromSuperview];
    }
	
	CGPDFPageRef page = CGPDFDocumentGetPage(pdf, index+1);
	CGAffineTransform transform1 = aspectFit(CGPDFPageGetBoxRect(page, kCGPDFMediaBox),
											 CGContextGetClipBoundingBox(ctx));
	CGContextConcatCTM(ctx, transform1);
	CGContextDrawPDFPage(ctx, page);

	
	CGPDFPageRef pageAd = CGPDFDocumentGetPage(pdf, index);
	
	CGPDFDictionaryRef pageDictionary = CGPDFPageGetDictionary(pageAd);
	
	CGPDFArrayRef outputArray;
	if(!CGPDFDictionaryGetArray(pageDictionary, "Annots", &outputArray)) {
		return;
	}
	
	int arrayCount = CGPDFArrayGetCount( outputArray );
	if(!arrayCount) {
		//continue;
	}
	
	for( int j = 0; j < arrayCount; ++j ) {
		CGPDFObjectRef aDictObj;
		if(!CGPDFArrayGetObject(outputArray, j, &aDictObj)) {
			return;
		}
		
		CGPDFDictionaryRef annotDict;
		if(!CGPDFObjectGetValue(aDictObj, kCGPDFObjectTypeDictionary, &annotDict)) {
			return;
		}
		CGPDFDictionaryRef aDict;
		if(!CGPDFDictionaryGetDictionary(annotDict, "A", &aDict)) {
			return;
		}

		CGPDFStringRef uriStringRef;
		if(!CGPDFDictionaryGetString(aDict, "URI", &uriStringRef)) {
			return;
		}
		
		CGPDFArrayRef rectArray;
		if(!CGPDFDictionaryGetArray(annotDict, "Rect", &rectArray)) {
			return;
		}
		
		int arrayCount = CGPDFArrayGetCount( rectArray );
		CGPDFReal coords[4];
		for( int k = 0; k < arrayCount; ++k ) {
			CGPDFObjectRef rectObj;
			if(!CGPDFArrayGetObject(rectArray, k, &rectObj)) {
				return;
			}
			
			CGPDFReal coord;
			if(!CGPDFObjectGetValue(rectObj, kCGPDFObjectTypeReal, &coord)) {
				return;
			}
			
			coords[k] = coord;
		}               
		
		char *uriString = (char *)CGPDFStringGetBytePtr(uriStringRef);
		
		NSString *uri = [NSString stringWithCString:uriString encoding:NSUTF8StringEncoding];
		CGRect rect = CGRectMake(coords[0],coords[1],coords[2],coords[3]);
		CGPDFInteger pageRotate = 0;
		CGPDFDictionaryGetInteger( pageDictionary, "Rotate", &pageRotate ); 
		CGRect pageRect = CGRectIntegral( CGPDFPageGetBoxRect( page, kCGPDFMediaBox ));
		if( pageRotate == 90 || pageRotate == 270 ) {
			CGFloat temp = pageRect.size.width;
			pageRect.size.width = pageRect.size.height;
			pageRect.size.height = temp;
		}
        float  pdfScale = (self.view.bounds.size.width/pageRect.size.width)<(self.view.bounds.size.height/pageRect.size.height)?self.view.bounds.size.width/pageRect.size.width:self.view.bounds.size.height/pageRect.size.height;
		rect.size.width -= rect.origin.x;
		rect.size.height -= rect.origin.y;
		
		CGAffineTransform trans = CGAffineTransformIdentity;
		trans = CGAffineTransformTranslate(trans, 35, pageRect.size.height+150);
		trans = CGAffineTransformScale(trans, pdfScale, -pdfScale);
		
		rect = CGRectApplyAffineTransform(rect, trans);
		
		NSURL *urlLink = [NSURL URLWithString:uri];
		[urlLink retain];
		
		//Create a button to get link actions
		button = [[UIButton alloc] initWithFrame:rect];
        button.titleLabel.text = uri;
        [button setBackgroundColor:[UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.2]];
		//[button setBackgroundImage:[UIImage imageNamed:@"link_bg.png"] forState:UIControlStateHighlighted];
		[button addTarget:self action:@selector(openLink:) forControlEvents:UIControlEventTouchUpInside];
		//[self.view addSubview:button];
	}   
	[leavesView reloadData];
 
}

#pragma mark free hand annotation methods
-(void)startAnnotation{
	
	qImageView.hidden=NO;
	[leavesView removeAnnotation];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *annotationFilePath = [NSString stringWithFormat:@"%@/%@-%d.png",[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0],fileName,pageNum];
	if ([fileManager fileExistsAtPath: annotationFilePath])
	{
		qImageView.image = [[UIImage alloc] initWithContentsOfFile:annotationFilePath];
	}
	else {
		qImageView.image=nil;
	}
	qImageView.userInteractionEnabled = YES;
}
-(void)stopAnnotation{
	
	[self saveSignature];
	[leavesView loadAnnotation];
	qImageView.image=nil;
	qImageView.userInteractionEnabled = NO;
}

-(IBAction)saveSignature{
	UIImage *image = qImageView.image;
	
	NSLog(@"%f,%f",image.size.width,image.size.height);
	NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	
	NSString *pngFilePath = [NSString stringWithFormat:@"%@/%@-%d.png",docDir,fileName,pageNum];
	NSData *data1 = [NSData dataWithData:UIImagePNGRepresentation(image)];
	[data1 writeToFile:pngFilePath atomically:YES];
}

-(IBAction)clearAnnotation{
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *annotationFilePath = [NSString stringWithFormat:@"%@/%@-%d.png",[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0],fileName,pageNum];
	if ([fileManager fileExistsAtPath: annotationFilePath])
	{
		//delete the file
		NSError **error;
		if([fileManager removeItemAtPath:annotationFilePath error:error]){
			qImageView.image = nil;
			[leavesView removeAnnotation];
		}
		else {
			NSLog(@"could not delete annotation");
		}
	}
	qImageView.image = nil;
	[leavesView removeAnnotation];
	return;
}
-(IBAction)eraseAnnotation:(id)sender{
	UIBarButtonItem *barButton = (UIBarButtonItem *)sender;
	if([barButton.title isEqualToString:@"Erase"]){
		qImageView.eraser=YES;
		if(!annotating){
			[self startAnnotation];
		}
		[barButton setTitle:@"Erasing"];
	}
	else {
		if(!annotating)
			[self stopAnnotation];
		[barButton setTitle:@"Erase"];
		qImageView.eraser=NO;
	}
//	if(annotating)
//		[qImageView undo];
}
-(IBAction)startStopAnnotation:(id)sender{
	
	UIBarButtonItem *barButton = (UIBarButtonItem *)sender;
	if([barButton.title isEqualToString:@"Highlighter"])
	   qImageView.pencilColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.1];
	else
		qImageView.pencilColor = [UIColor purpleColor];
	if(!annotating){
		[self startAnnotation];
		annotating=YES;
		[barButton setStyle:UIBarButtonItemStyleDone];
	}
	else {
		[self stopAnnotation];
		annotating=NO;
		[barButton setStyle:UIBarButtonItemStyleBordered];
	}
	
}
-(void)initiateAnnotationView{
	qImageView = [[QImageView alloc] initWithFrame:leavesView.bounds];
	qImageView.userInteractionEnabled = NO;
	qImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	qImageView.opaque=NO;
	qImageView.hidden=YES;
	//customize pencil
	qImageView.pencilThickness = 5.0;
	[qImageView setPencilColor:[UIColor purpleColor]];
	qImageView.eraser=NO;
	[leavesView addSubview:qImageView];
}
#pragma mark UIViewController
void ListDictionaryObjects (const char *key, CGPDFObjectRef object, void *info);
- (void) viewDidLoad {
	[super viewDidLoad];
	
	[self.navigationController.navigationBar setBarStyle:UIBarStyleBlackOpaque];
	//adding annotation toolbar
	UIToolbar* toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width/2+75, 45)];
	[toolbar setBarStyle: UIBarStyleBlackOpaque];
	NSMutableArray *items = [[NSMutableArray alloc] init];
	UIBarButtonItem *annotateButton = [[UIBarButtonItem alloc] initWithTitle:@"Annotate" style:UIBarButtonItemStyleBordered target:self action:@selector(startStopAnnotation:)];
	UIBarButtonItem *Highlighter = [[UIBarButtonItem alloc] initWithTitle:@"Highlighter" style:UIBarButtonItemStyleBordered target:self action:@selector(startStopAnnotation:)];
	UIBarButtonItem *clearButton = [[UIBarButtonItem alloc] initWithTitle:@"Clear All" style:UIBarButtonItemStyleBordered target:self action:@selector(clearAnnotation)];
	UIBarButtonItem *undoButton = [[UIBarButtonItem alloc] initWithTitle:@"Erase" style:UIBarButtonItemStyleBordered target:self action:@selector(eraseAnnotation:)];
	pageNumberTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 10, 100, 40)];
	pageNumberTextField.delegate=self;
	pageNumberTextField.textColor = [UIColor whiteColor];
	pageNumberTextField.font = [UIFont boldSystemFontOfSize:22];
	UIBarButtonItem *pageNumberBarButton = [[UIBarButtonItem alloc] initWithCustomView:pageNumberTextField];
	[items addObject:pageNumberBarButton];
	[items addObject:Highlighter];
    [items addObject:annotateButton];
	[items addObject:clearButton];
	[items addObject:undoButton];
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 353, 45)];
    searchBar.placeholder = NSLocalizedString(@"PLACEHOLDER_SEARCH_BOARDBOOKVIEWCONTROLLER", nil);
    searchBar.backgroundImage = nil;
    searchBar.delegate = self;
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:searchBar];
    self.navigationItem.leftBarButtonItem = rightItem;
    [rightItem release];
    [searchBar release];
    [toolbar setItems:items];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:toolbar];
	[toolbar release];
    [items release];
	[pageNumberBarButton release];
	[Highlighter release];
	[annotateButton release];
	[clearButton release];
	[undoButton release];
	
	//adding annotation view
	[self initiateAnnotationView];
	
	leavesView.backgroundRendering = YES;
	[self displayPageNumber:1];
	
//	CGPDFDictionaryRef pdfDocDictionary = CGPDFDocumentGetCatalog(pdf);
//	// loop through dictionary...
//	CGPDFDictionaryApplyFunction(pdfDocDictionary, ListDictionaryObjects, NULL); 
	
}
#pragma mark -
CGPDFDictionaryRef objectDictionary;
void ListDictionaryObjects (const char *key, CGPDFObjectRef object, void *info) {
    NSLog(@"key: %s", key);
	//	NSString *keyStr = [NSString stringWithCString:key encoding:NSUTF8StringEncoding];
	//	CGPDFDictionaryRef contentDict = (CGPDFDictionaryRef)info;
	
    CGPDFObjectType type = CGPDFObjectGetType(object);
    switch (type) { 
        case kCGPDFObjectTypeDictionary: {
            //CGPDFDictionaryRef objectDictionary;
            if (CGPDFObjectGetValue(object, kCGPDFObjectTypeDictionary, &objectDictionary)) {
                CGPDFDictionaryApplyFunction(objectDictionary, ListDictionaryObjects, NULL);
            }
        }
        case kCGPDFObjectTypeInteger: {
            CGPDFInteger objectInteger;
            if (CGPDFObjectGetValue(object, kCGPDFObjectTypeInteger, &objectInteger)) {
                NSLog(@"integer: %ld", (long int)objectInteger); 
            }
        }
		case kCGPDFObjectTypeBoolean: {
			//NSLog(@"object Type kCGPDFObjectTypeBoolean");
			//			CGPDFBoolean objectBool;
			//            if (CGPDFObjectGetValue(object, kCGPDFObjectTypeBoolean, &objectBool)) {
			//                NSLog(@"pdf Boolean value: %c", (unsigned char)objectBool); 
			//            }
        }
		case kCGPDFObjectTypeReal: {
			// NSLog(@"object Type kCGPDFObjectTypeReal");
			//			CGPDFReal objectReal;
			//            if (CGPDFObjectGetValue(object, kCGPDFObjectTypeReal, &objectReal)) {
			//                NSLog(@"pdf Real value: %f", (CGFloat)objectReal); 
			//            }
        }
		case kCGPDFObjectTypeName: {
			//NSLog(@"object Type kCGPDFObjectTypeName");
        }
		case kCGPDFObjectTypeString: {
			CGPDFStringRef stringRef;
            if (CGPDFObjectGetValue(object, kCGPDFObjectTypeString, &stringRef)) {
				NSString *cidString = (NSString *) CGPDFStringCopyTextString(stringRef);
				NSLog(@"string: %@",cidString);
			}
        }
		case kCGPDFObjectTypeArray: {
			CGPDFArrayRef rectArray;
			if(CGPDFDictionaryGetArray(objectDictionary, "Rect", &rectArray)) {
				//continue;
				NSLog(@" Array: %@",rectArray);    
				
			}
			
        }
		case kCGPDFObjectTypeStream: {
			// NSLog(@"object Type kCGPDFObjectTypeStream");
			
        }
			// cf. http://developer.apple.com/mac/library/documentation/GraphicsImaging/Reference/CGPDFObject/Reference/reference.html#//apple_ref/doc/uid/TP30001117-CH3g-SW1
    }    
}

#pragma mark -
#pragma mark parsing and searching
int level = 1;
int callbackHits = 0;
NSString *result;


//parsing text variables
float charSpace;
float wordSpace;
float tx, ty;
float tX, tY;
float tWidth, tHeight;
float leading,rise, scale;
int lineNumber;
#pragma mark text state operator
static void op_Tc (CGPDFScannerRef s, void *info)
{
	
    CGPDFReal realValue;
	
    if (!CGPDFScannerPopNumber(s, &realValue)) {
        //NSLog(@"Failed to get object for operator");
        return;
    }
    charSpace = (float)realValue;
}
static void op_Tw (CGPDFScannerRef s, void *info)
{
	
    CGPDFReal realValue;
	
    if (!CGPDFScannerPopNumber(s, &realValue)) {
        //NSLog(@"Failed to get object for operator");
        return;
    }
    wordSpace = (float)realValue;
}
//used only by the T*, ', and " operators.
static void op_TL (CGPDFScannerRef s, void *info)
{
	
    CGPDFReal realValue;
	
    if (!CGPDFScannerPopNumber(s, &realValue)) {
        //NSLog(@"Failed to get object for operator");
        return;
    }
    leading = (float)realValue;
}
static void op_Ts (CGPDFScannerRef s, void *info)
{
	
    CGPDFReal realValue;
	
    if (!CGPDFScannerPopNumber(s, &realValue)) {
        //NSLog(@"Failed to get object for operator");
        return;
    }
    rise = (float)realValue;
}
static void op_Tz (CGPDFScannerRef s, void *info)
{
	
    CGPDFReal realValue;
	
    if (!CGPDFScannerPopNumber(s, &realValue)) {
        //NSLog(@"Failed to get object for operator");
        return;
    }
    scale = (float)realValue;
}
#pragma mark text position operator
static void op_Td (CGPDFScannerRef s, void *info)
{
    CGPDFReal realValue;
	
    if (!CGPDFScannerPopNumber(s, &realValue)) {
        //NSLog(@"Failed to get object for operator");
        return;
    }
    tY += (float)realValue;
    if (!CGPDFScannerPopNumber(s, &realValue)) {
        //NSLog(@"Failed to get object for operator");
        return;
    }
    tX += (float)realValue;
}
static void op_TD (CGPDFScannerRef s, void *info)
{
    CGPDFReal realValue;
	
    if (!CGPDFScannerPopNumber(s, &realValue)) {
        //NSLog(@"Failed to get object for operator");
        return;
    }
    leading = -(float)realValue;
    tY += (float)realValue;
    if (!CGPDFScannerPopNumber(s, &realValue)) {
        //NSLog(@"Failed to get object for operator");
        return;
    }
    tX += (float)realValue;
}
static void op_Tm (CGPDFScannerRef s, void *info)
{
    CGPDFReal realValue;
	tX=0;tY=0;
    leading=1;
    rise=0;
    if (!CGPDFScannerPopNumber(s, &realValue)) {
        //NSLog(@"Failed to get object for operator");
        return;
    }
    ty = (float)realValue;
    if (!CGPDFScannerPopNumber(s, &realValue)) {
        return;
    }
    tx = (float)realValue;
    
    if (!CGPDFScannerPopNumber(s, &realValue)) {
        return;
    }
    tHeight = (float)realValue;
    if (!CGPDFScannerPopNumber(s, &realValue)) {
        return;
    }
    if (!CGPDFScannerPopNumber(s, &realValue)) {
        return;
    }
    if (!CGPDFScannerPopNumber(s, &realValue)) {
        return;
    }
    tWidth = (float)realValue;
    
}
static void op_T (CGPDFScannerRef s, void *info)
{
    tY += -leading;
}
#pragma mark text showing operator
static void op_j (CGPDFScannerRef s, void *info)
{
    ++callbackHits;
	
    CGPDFStringRef stringRef;
	
    if (!CGPDFScannerPopString(s, &stringRef)) {
        return;
    }
	NSString *string = (NSString *)CGPDFStringCopyTextString(stringRef);

    result = [NSString stringWithFormat:@"%@%@", result, string];
	
    NSRange range = [string rangeOfString:searchText options:NSCaseInsensitiveSearch];
    if(range.length != 0){
        NSLog(@"\n\n line %@\n (%f, %f)",string,tx+tX*tWidth,ty+tY*tHeight);

        [hightlerArray addObject:[NSNumber numberWithFloat:tx+tX*tWidth]];
        [hightlerArray addObject:[NSNumber numberWithFloat:ty+tY*tHeight+tHeight]];
        [hightlerArray addObject:[NSNumber numberWithFloat:(tWidth+charSpace)*searchText.length + range.location*tWidth]];
        [hightlerArray addObject:[NSNumber numberWithFloat:tHeight]];
    }
    //NSLog(@"Name: /%s", (char *) CGPDFStringGetBytePtr(name));
}
static void op_J (CGPDFScannerRef s, void *info)
{
    ++callbackHits;
	
    CGPDFArrayRef arrayRef;
	
    if (!CGPDFScannerPopArray(s, &arrayRef)) {
        //NSLog(@"Failed to get object for operator");
        return;
    }
	int count = CGPDFArrayGetCount(arrayRef);
    NSString *string;
    NSString *tempString;
    if(count>0){
        CGPDFStringRef stringRef;
        CGPDFArrayGetString(arrayRef, 0, &stringRef);
        string = [NSString stringWithFormat:@"%@", (NSString *)CGPDFStringCopyTextString(stringRef)];
        tempString = string;
    }
    float spacing=0;
    for(int i=1;i<count ; i++){
        
        CGPDFReal realValue;
        CGPDFArrayGetNumber(arrayRef, i++, &realValue);
        //spacing += (float)realValue;
        
        CGPDFStringRef stringRef;
        CGPDFArrayGetString(arrayRef, i, &stringRef);
        tempString = [NSString stringWithFormat:@"%@%@", tempString,(NSString *)CGPDFStringCopyTextString(stringRef)];
        string = [NSString stringWithFormat:@"%@%@", string,(NSString *)CGPDFStringCopyTextString(stringRef)];
        NSRange range = [tempString rangeOfString:searchText options:NSCaseInsensitiveSearch];
        if(range.length != 0){
            tempString = @"";
            spacing+=range.location;
            NSLog(@"\n\n line %@\n (%f, %f)",string,tx+tX*tWidth,ty+tY*tHeight);
            
            [hightlerArray addObject:[NSNumber numberWithFloat:tx+tX*tWidth]];
            [hightlerArray addObject:[NSNumber numberWithFloat:ty+tY*tHeight+tHeight]];
            [hightlerArray addObject:[NSNumber numberWithFloat:(tWidth+charSpace)*searchText.length+spacing*tWidth]];
            [hightlerArray addObject:[NSNumber numberWithFloat:tHeight]];
        }
    }
    result = [NSString stringWithFormat:@"%@%@", result, string];

    //NSLog(@"Name: /%s", (char *) CGPDFStringGetBytePtr(name));
}
//static void op_MP (CGPDFScannerRef s, void *info) {
//    const char *name;
//    if (!CGPDFScannerPopName(s, &name))
//        return;
//    printf("MP /%s\n", name);   
//}
//
//static void op_DP (CGPDFScannerRef s, void *info) {
//    const char *name;
//    if (!CGPDFScannerPopName(s, &name))
//        return;
//    printf("DP /%s\n", name);   
//}
//
//static void op_BMC (CGPDFScannerRef s, void *info) {
//    const char *name;
//    if (!CGPDFScannerPopName(s, &name))
//        return;
//    printf("BMC /%s\n", name);  
//}
//
//static void op_BDC (CGPDFScannerRef s, void *info) {
//    const char *name;
//    if (!CGPDFScannerPopName(s, &name))
//        return;
//    printf("BDC /%s\n", name);  
//}
//
//static void op_EMC (CGPDFScannerRef s, void *info) {
//    const char *name;
//    if (!CGPDFScannerPopName(s, &name))
//        return;
//    printf("EMC /%s\n", name);  
//}
- (CGPDFOperatorTableRef) createCallbackTable {
    CGPDFOperatorTableRef myTable;
	
    myTable = CGPDFOperatorTableCreate();
	/*
     CGPDFOperatorTableSetCallback (myTable, "MP", &op_MP);//Define marked-content point
     CGPDFOperatorTableSetCallback (myTable, "DP", &op_DP);//Define marked-content point with property list
     CGPDFOperatorTableSetCallback (myTable, "BMC", &op_BMC);//Begin marked-content sequence
     CGPDFOperatorTableSetCallback (myTable, "BDC", &op_BDC);//Begin marked-content sequence with property list
     CGPDFOperatorTableSetCallback (myTable, "EMC", &op_EMC);//End marked-content sequence
     */
     //Text State operators
     CGPDFOperatorTableSetCallback(myTable, "Tc", &op_Tc);
     CGPDFOperatorTableSetCallback(myTable, "Tw", &op_Tw);
     CGPDFOperatorTableSetCallback(myTable, "Tz", &op_Tz);
     CGPDFOperatorTableSetCallback(myTable, "TL", &op_TL);
//     CGPDFOperatorTableSetCallback(myTable, "Tf", &op_Tf);
//     CGPDFOperatorTableSetCallback(myTable, "Tr", &op_Tr);
     CGPDFOperatorTableSetCallback(myTable, "Ts", &op_Ts);
     
     //text showing operators
    CGPDFOperatorTableSetCallback (myTable, "Tj", &op_j);
	CGPDFOperatorTableSetCallback (myTable, "TJ", &op_J);
//    CGPDFOperatorTableSetCallback(myTable, "'", &op_apostrof);
//    CGPDFOperatorTableSetCallback(myTable, "\"", &op_double_apostrof);
    
    //text positioning operators        
    CGPDFOperatorTableSetCallback(myTable, "Td", &op_Td);
    CGPDFOperatorTableSetCallback(myTable, "TD", &op_TD);
    CGPDFOperatorTableSetCallback(myTable, "Tm", &op_Tm);
    CGPDFOperatorTableSetCallback(myTable, "T*", &op_T);
    
    //text object operators
//    CGPDFOperatorTableSetCallback(myTable, "BT", &op_BT);//Begin text object
//    CGPDFOperatorTableSetCallback(myTable, "ET", &op_ET);//End text object
    
    return myTable;
}

- (BOOL) parsePDF {
	
    level = 1;
    callbackHits = 0;
	
    tX = 0;
    tY = 0;
    //FileManipulationFacade *fileManipulator = [[FileManipulationFacade alloc] initWithFileNamed:@"PDF32000_2008.pdf"];

    CGPDFPageRef page = CGPDFDocumentGetPage (pdf, pageNum);
	
    CGPDFDictionaryRef d;
    d = CGPDFPageGetDictionary(page);
	
    // Print page structure
    //CGPDFDictionaryApplyFunction(d, ListDictionaryObjects, NULL);
	
    // Print page raw contents
    CGPDFStreamRef cont;
    if( !CGPDFDictionaryGetStream( d, "Contents", &cont ) )
    {
        NSLog(@"%@", @"failed to read contents stream for page ");
        return NO;
    }
    CFDataRef contdata = CGPDFStreamCopyData( cont, NULL );
    NSLog(@"%@", [NSString stringWithFormat:@"contents: %s", (char *) CFDataGetBytePtr( contdata )]);
	
    // Scan page printing MP contents
	
    CGPDFOperatorTableRef myTable = [self createCallbackTable];
    CGPDFContentStreamRef myContentStream = CGPDFContentStreamCreateWithPage (page);
	
    CGPDFScannerRef myScanner = CGPDFScannerCreate (myContentStream, myTable, NULL);
	result = [[NSString alloc] init];
    CGPDFScannerScan (myScanner);
	
    NSLog(@"Result: %@", result);
    NSLog(@" wordSpace %f, charSpace %f", wordSpace , charSpace);
    //NSLog(@" width %f, height %f",tWidth, tHeight);
    NSLog(@"Callback hits: %d", callbackHits);

    
    CGRect pageRect = CGPDFPageGetBoxRect(page, kCGPDFMediaBox);
//    float yscale = self.view.bounds.size.height/pageRect.size.height;
//    float xscale = self.view.bounds.size.width/pageRect.size.width;
      float  pdfScale = (self.view.bounds.size.width/pageRect.size.width)<(self.view.bounds.size.height/pageRect.size.height)?self.view.bounds.size.width/pageRect.size.width:self.view.bounds.size.height/pageRect.size.height;
    
    for(int i=0;i<[hightlerArray count];){

        float x = [[hightlerArray objectAtIndex:i] floatValue]*pdfScale;
        float y = self.view.frame.size.height - ([[hightlerArray objectAtIndex:i+1] floatValue]*pdfScale);
        CGRect rect = CGRectMake(x, y, [[hightlerArray objectAtIndex:i+2] floatValue]*pdfScale, [[hightlerArray objectAtIndex:i+3] floatValue]*pdfScale);
        
//		CGAffineTransform trans = CGAffineTransformIdentity;
//		trans = CGAffineTransformTranslate(trans, 35, pageRect.size.height);
//		trans = CGAffineTransformScale(trans, 1.15, -1.15);
//		
//		rect = CGRectApplyAffineTransform(rect, trans);
        
        UILabel *highlighterLabel = [[UILabel alloc] initWithFrame:rect];
        highlighterLabel.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:1.0 alpha:0.2];
        [self.view addSubview:highlighterLabel];
        [highlighterLabel release];
        i+=4;
    }
    
    if([result rangeOfString:searchText options:NSCaseInsensitiveSearch].length != 0){
        NSLog(@"found %@", searchText);
        return YES;
    } 
    return NO;
}
#pragma mark -
#pragma mark UITextField delegates
- (void)textFieldDidBeginEditing:(UITextField *)textField{
	//set cursor position. possible?
}
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField{
	[textField resignFirstResponder];
	return YES;
}
- (void)textFieldDidEndEditing:(UITextField *)textField{
	
	int pageNumber = [[[textField.text componentsSeparatedByString:@" of "] objectAtIndex:0] intValue];
	NSLog(@"go to page %d", pageNumber);
	if(pageNumber >0 && pageNumber<= CGPDFDocumentGetNumberOfPages (pdf))
	{
		//go to page
		leavesView.currentPageIndex = pageNumber-1;
		[leavesView reloadData];
		[self displayPageNumber:pageNumber];
	}
}
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
	
	if((range.location=0 || range.location<[textField.text rangeOfString:@" of"].location+[string length]) && range.length<=[textField.text rangeOfString:@" of"].location)
		return YES;
	return NO;
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
	[textField resignFirstResponder];
	return YES;
}

#pragma mark search bar delegate
static int i;

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    int totalPages = CGPDFDocumentGetNumberOfPages(pdf);
    searchText = searchBar.text;
    if(searchText.length >0){
    for(;i< totalPages ;i++){
        pageNum = i+1;
        if([self parsePDF]){
            leavesView.currentPageIndex = i;
            [leavesView reloadData];
            [self displayPageNumber:pageNum];
            
            hightlerArray = [[NSMutableArray alloc] init];
            [self parsePDF];
            i++;
            break;
        }
    }
    }
    if(i==totalPages-1)
        i=0;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    i =0;
}
@end
