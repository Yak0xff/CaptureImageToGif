//
//  GifShowView.h
//  CaptureImageToGif
//
//  Created by Yongchao on 22/11/13.
//  Copyright (c) 2013 Yongchao. All rights reserved.
//

#import <UIKit/UIKit.h>  
#import <MobileCoreServices/MobileCoreServices.h>
 

@interface GifShowView : UIView
{
    UIImageView *_animatedImageView;
    
    
    NSURL *_gifURL;
}


- (id)initWithGifURL:(NSURL *)gifURL andSize:(CGSize)size;
- (void)presentInView:(UIView *)view;

@end
