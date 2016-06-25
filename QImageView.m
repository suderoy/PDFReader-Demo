//
//  QImageView.m
//
//  Created by Sudeshna Roy on 12/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "QImageView.h"

@interface QImageView () 

@property (assign) CGFloat redColor;
@property (assign) CGFloat greenColor;
@property (assign) CGFloat blueColor;
@property (assign) CGFloat alpha;
@end


@implementation QImageView
@synthesize pencilThickness,pencilColor,eraser;
@synthesize redColor,greenColor,blueColor,alpha;

//float xorigin, yorigin, xmax, ymax;

-(void)setPencilColor:(UIColor *)color{
	const CGFloat *colorComponents=CGColorGetComponents( color.CGColor);
	redColor = colorComponents[0];
	greenColor = colorComponents[1];
	blueColor = colorComponents[2];
	alpha = colorComponents[3];
}
- (void)dealloc {
	[pencilColor release];
	[super dealloc];
}

// Handles the start of a touch
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	mouseSwiped = NO;
	UITouch *touch = [touches anyObject];
	
	if ([touch tapCount] == 2)
	{
		self.image = nil;
		return;
	}
	startPoint = [touch locationInView:self];
	lastPoint = startPoint;
	//lastPoint.y -= 20;
//	xorigin = startPoint.x;
//	xmax = startPoint.x;
//	yorigin = startPoint.y;
//	ymax = startPoint.y;
}

// Handles the continuation of a touch.
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	mouseSwiped = YES;
	
	UITouch *touch = [touches anyObject];
	CGPoint currentPoint = [touch locationInView:self];
	//currentPoint.y -= 20;
//	xorigin = xorigin>currentPoint.x?currentPoint.x:xorigin;
//	xmax = xmax<currentPoint.x?currentPoint.x:xmax;
//	yorigin = yorigin>currentPoint.y?currentPoint.y:yorigin;
//	ymax = ymax<currentPoint.y?currentPoint.y:ymax;
	
	UIGraphicsBeginImageContext(self.frame.size);
	[self.image drawInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
	CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
	if(eraser)
		CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeClear);
	CGContextSetLineWidth(UIGraphicsGetCurrentContext(), self.pencilThickness);
	CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), redColor, greenColor, blueColor, alpha);
	CGContextBeginPath(UIGraphicsGetCurrentContext());
	CGContextMoveToPoint(UIGraphicsGetCurrentContext() , lastPoint.x, lastPoint.y);
	CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), currentPoint.x, currentPoint.y);
	CGContextStrokePath(UIGraphicsGetCurrentContext()) ;
	self.image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	lastPoint = currentPoint;
}

// Handles the end of a touch event when the touch is a tap.
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	
	if ([touch tapCount] == 2)
	{
		self.image = nil;
		return;
	}
	
	
	if(!mouseSwiped) {
		UIGraphicsBeginImageContext(self.frame.size);
		[self.image drawInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
		CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
		CGContextSetLineWidth(UIGraphicsGetCurrentContext(), self.pencilThickness);
		CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), redColor, greenColor, blueColor, alpha);
		CGContextMoveToPoint(UIGraphicsGetCurrentContext() , lastPoint.x, lastPoint.y);
		CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
		CGContextStrokePath(UIGraphicsGetCurrentContext()) ;
		CGContextFlush(UIGraphicsGetCurrentContext());
		self.image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
	}
}

-(void)undo{
	UIGraphicsBeginImageContext(self.frame.size);
	[self.image drawInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
	CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
	//CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeClear);
	CGContextSetLineWidth(UIGraphicsGetCurrentContext(), self.pencilThickness);
	//CGContextClearRect(UIGraphicsGetCurrentContext(), CGRectMake(xorigin-pencilThickness,yorigin-pencilThickness,xmax-xorigin+2*pencilThickness, ymax-yorigin+2*pencilThickness));
	CGContextStrokePath(UIGraphicsGetCurrentContext()) ;
	CGContextFlush(UIGraphicsGetCurrentContext());
	self.image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
}
@end