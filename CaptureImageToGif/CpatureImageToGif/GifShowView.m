//
//  GifShowView.m
//  CaptureImageToGif
//
//  Created by Yongchao on 22/11/13.
//  Copyright (c) 2013 Yongchao. All rights reserved.
//

#import "GifShowView.h"
#import "AnimatedGif.h"

@interface GifShowView ()

@end

@implementation GifShowView

- (id)initWithGifURL:(NSURL *)gifURL andSize:(CGSize)size
{
    self = [super init];
    if (self != nil)
    {
        _animatedImageView = [AnimatedGif getAnimationForGifAtUrl:gifURL];
        _animatedImageView.userInteractionEnabled = YES;
        _animatedImageView.bounds = CGRectMake(0.0, 0.0, size.width, size.height);
        [self addSubview:_animatedImageView];
        
        UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                           action:@selector(dismiss:)];
        swipeGesture.direction = UISwipeGestureRecognizerDirectionDown;
        [_animatedImageView addGestureRecognizer:swipeGesture];
        [self addGestureRecognizer:swipeGesture];
        
        
        _gifURL = gifURL;
        
        self.backgroundColor = [UIColor blackColor];
        
    }
    
    return self;
}

- (void)presentInView:(UIView *)view
{
    [view addSubview:self];
    
    self.frame = view.layer.frame;
    
    
    
    
    CGRect centeredRect = CGRectMake((self.bounds.size.width - _animatedImageView.bounds.size.width) / 2,
                                     0.0,
                                     _animatedImageView.bounds.size.width,
                                     _animatedImageView.bounds.size.height);
    _animatedImageView.frame = CGRectOffset(centeredRect, 0, self.bounds.size.height);
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
                         _animatedImageView.frame = CGRectOffset(_animatedImageView.frame, 0, -self.bounds.size.height);
                     } completion:^(BOOL finished) {
                         //
                     }];
}

- (void)dismiss:(UISwipeGestureRecognizer *)swipeGesture
{
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
                         _animatedImageView.frame = CGRectOffset(_animatedImageView.frame, 0, self.bounds.size.height);
                     } completion:^(BOOL finished) {
                         [self removeFromSuperview];
                         [[NSNotificationCenter defaultCenter] postNotificationName:@"ResetView" object:nil];
                     }];
}

 

- (void)viewDidAppear:(BOOL)animated
{
    
    [_animatedImageView startAnimating];
}

@end


