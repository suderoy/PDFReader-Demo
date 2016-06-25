//
//  QImageView.h
//
//  Created by Sudeshna Roy on 12/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QImageView : UIImageView 
{
	BOOL mouseSwiped;
	CGPoint startPoint;
	CGPoint lastPoint;
	
	//customize
	float pencilThickness;
	UIColor *pencilColor;
	BOOL eraser;
}

@property float pencilThickness;
@property (nonatomic, retain) UIColor *pencilColor;
@property BOOL eraser;

-(void)undo;
@end