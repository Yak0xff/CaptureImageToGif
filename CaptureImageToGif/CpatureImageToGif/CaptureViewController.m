//
//  CaptureViewController.m
//  CaptureImageToGif
//
//  Created by Yongchao on 19/11/13.
//  Copyright (c) 2013 Yongchao. All rights reserved.
//

#import "CaptureViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "GifShowView.h"


static inline double radians (double degrees) {return degrees * M_PI/180;}
UIImage* rotate(UIImage* src, UIImageOrientation orientation)
{
    UIGraphicsBeginImageContext(src.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (orientation == UIImageOrientationRight) {
        CGContextRotateCTM (context, radians(90));
    } else if (orientation == UIImageOrientationLeft) {
        CGContextRotateCTM (context, radians(-90));
    } else if (orientation == UIImageOrientationDown) {
    } else if (orientation == UIImageOrientationUp) {
        CGContextRotateCTM (context, radians(90));
    }
    
    [src drawAtPoint:CGPointMake(0, 0)];
    
    return UIGraphicsGetImageFromCurrentImageContext();
}




@interface CaptureViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>

{
    UIButton *cameraBtn;
    UIButton *photoBtn;
    UIButton *flashBtn;
    UILabel *timerLabel;
    
    UIActivityIndicatorView *indicatorView;
    GifShowView *gifView;
    
    dispatch_queue_t queue;
}

@property (nonatomic, strong) AVCaptureSession *captureSession;


@property (nonatomic, strong) CALayer *customLayer;

@property (nonatomic,strong) NSMutableArray *imageArray;
@property (nonatomic,strong) NSTimer *timer;
@property (nonatomic,strong) UIImage *resultImage;


@property (nonatomic,strong) AVCaptureVideoDataOutput *captureOutput;
@property (nonatomic,strong) AVCaptureDeviceInput *captureInput;

@property (nonatomic,assign) BOOL flashOn;


- (void)setupCapture;

@property (nonatomic,assign) BOOL startCapture;

@end

@implementation CaptureViewController

#pragma mark -
#pragma mark Initialization

- (void)viewDidLoad {
    
    self.imageArray = [NSMutableArray array];
    self.navigationController.navigationBarHidden = YES;
    
    [self setWantsFullScreenLayout:YES];
    
    self.startCapture = NO;
    
    self.flashOn = NO;
    
	[self setupCapture]; 
}
-(void)setupUI{
    timerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 76, 36)];
    timerLabel.center = CGPointMake(CGRectGetMidX(self.view.frame), 35);
    timerLabel.layer.cornerRadius = 16.f;
    timerLabel.layer.borderColor = [UIColor lightGrayColor].CGColor;
    timerLabel.layer.borderWidth = 3.f;
    timerLabel.layer.masksToBounds = YES;
    timerLabel.font = [UIFont systemFontOfSize:14.f];
    timerLabel.textColor = [UIColor whiteColor];
    timerLabel.textAlignment = NSTextAlignmentCenter;
    timerLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    [self.view addSubview:timerLabel];
    
    timerLabel.text = @"20";
    
    
    flashBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    flashBtn.showsTouchWhenHighlighted = YES;
    [flashBtn setFrame:CGRectMake(5, 20, 100, 50)];
    [flashBtn setTitle:@"灯光" forState:UIControlStateNormal];
    [flashBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [flashBtn addTarget:self action:@selector(rotateFlash) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:flashBtn];
    
    UIButton *deviceBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [deviceBtn setTitle:@"前后" forState:UIControlStateNormal];
    [deviceBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [deviceBtn addTarget:self action:@selector(rotateCamera) forControlEvents:UIControlEventTouchUpInside];
    [deviceBtn setFrame:CGRectMake(self.view.frame.size.width-105, 20, 100, 50)];
    
    [self.view addSubview:deviceBtn];
    
    cameraBtn = [[UIButton alloc] initWithFrame:
                 CGRectMake(118, self.view.frame.size.height - 55, 100, 50)];
    [cameraBtn setTitle:@"开始" forState:UIControlStateNormal];
    [cameraBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    cameraBtn.showsTouchWhenHighlighted = YES;
    [cameraBtn addTarget:self action:@selector(startCaptureImage) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cameraBtn];
    
    photoBtn = [[UIButton alloc] initWithFrame:CGRectMake(245, self.view.frame.size.height - 55, 100, 50)];
    [photoBtn setTitle:@"合成" forState:UIControlStateNormal];
    [photoBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [photoBtn addTarget:self action:@selector(composeGif) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:photoBtn];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetView) name:@"ResetView" object:nil];
}

-(void)startCaptureImage{
    if(self.startCapture){
        [cameraBtn setTitle:@"开始" forState:UIControlStateNormal];
    }else{
        [cameraBtn setTitle:@"暂停" forState:UIControlStateNormal];
    }
    
    self.startCapture = !self.startCapture;
    
    if(!self.startCapture){
        [self.timer invalidate];
        self.timer = nil;
    }
}

-(void)resetView{
    self.startCapture = NO;
    [_captureSession startRunning];
    [self.imageArray removeAllObjects];
    gifView = nil;
    
    timerLabel.text = @"20";
    cameraBtn.enabled = YES;
    
    timerLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    timerLabel.textColor = [UIColor whiteColor];
    
    
}


- (void)composeGif
{
    if (self.imageArray.count < 2)
        return;
    
    
    [self.timer invalidate];
    self.timer = nil;
    self.startCapture = NO;
    
    [self.captureSession stopRunning];
    
    
    
    indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    indicatorView.center = CGPointMake(CGRectGetMidX(self.view.frame), CGRectGetMidY(self.view.frame));
    [self.view addSubview:indicatorView];
    [self.view bringSubviewToFront:indicatorView];
    [indicatorView startAnimating];
    
    self.flashOn = YES;
    
    [self performSelectorOnMainThread:@selector(rotateFlash) withObject:nil waitUntilDone:NO];
    
    
    [self performSelector:@selector(gifMaker) withObject:nil afterDelay:0.23f];
    
}


-(void)gifMaker{
    @try {
        NSUInteger frameCount = self.imageArray.count;
        
        NSDictionary *fileProperties = @{
                                         (__bridge id)kCGImagePropertyGIFDictionary: @{
                                                 (__bridge id)kCGImagePropertyGIFLoopCount: @0,
                                                 }
                                         };
        
        NSDictionary *frameProperties = @{
                                          (__bridge id)kCGImagePropertyGIFDictionary: @{
                                                  (__bridge id)kCGImagePropertyGIFDelayTime: @0.23f,                                               }
                                          };
        
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
        NSURL *fileURL = [documentsDirectoryURL URLByAppendingPathComponent:@"captureImageToGif.gif"];
        
        CGImageDestinationRef destination = NULL;
        
        destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)fileURL, kUTTypeGIF, frameCount + frameCount - 1, NULL);
        
        CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)fileProperties);
        
        for (NSUInteger i = 0; i < frameCount; i++) {
            @autoreleasepool {
                UIImage *image = rotate([self.imageArray[i] copy], UIImageOrientationDown);
                CGImageDestinationAddImage(destination, image.CGImage, (__bridge CFDictionaryRef)frameProperties);
            }
        }
        
        for (int i = (frameCount - 2); i >= 0; i--) {
            @autoreleasepool {
                UIImage *image = rotate([self.imageArray[i] copy], UIImageOrientationDown);
                CGImageDestinationAddImage(destination, image.CGImage, (__bridge CFDictionaryRef)frameProperties);
            }
        }
        
        if (!CGImageDestinationFinalize(destination)) {
            NSLog(@"failed to finalize image destination");
        }
        CFRelease(destination);
        
        UIImage *referenceImage = self.imageArray[0];
        
        
        gifView = [[GifShowView alloc] initWithGifURL:fileURL andSize:referenceImage.size];
        [indicatorView stopAnimating];
        [gifView presentInView:self.view];
    }
    @catch (NSException *exception) {
        
    }
}



-(void)dismissPickerController{
   
    [self dismissViewControllerAnimated:YES completion:nil];
  
    self.flashOn = YES;
    
    [self performSelectorOnMainThread:@selector(rotateFlash) withObject:nil waitUntilDone:NO];
    
    
}

- (void)setupCapture {
    _captureInput = [AVCaptureDeviceInput
										  deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo]
										  error:nil];
	
    _captureOutput = [[AVCaptureVideoDataOutput alloc] init];
	_captureOutput.alwaysDiscardsLateVideoFrames = YES;
	queue = dispatch_queue_create("cameraQueue", NULL);
	[_captureOutput setSampleBufferDelegate:self queue:queue];
    

    
	NSDictionary* videoSettings = @{(__bridge NSString*)kCVPixelBufferPixelFormatTypeKey: [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]};
	[_captureOutput setVideoSettings:videoSettings];
    
	self.captureSession = [[AVCaptureSession alloc] init];
    
	[self.captureSession addInput:_captureInput];
	[self.captureSession addOutput:_captureOutput];
    
    
    [self.captureSession setSessionPreset:AVCaptureSessionPresetMedium];
    
	self.customLayer = [CALayer layer];
	self.customLayer.frame = CGRectMake(0, 0, 320, self.view.frame.size.height);
    self.view.layer.masksToBounds = YES;
	self.customLayer.transform = CATransform3DRotate(CATransform3DIdentity, M_PI/2.0f, 0, 0, 1);
	self.customLayer.contentsGravity = kCAGravityResizeAspectFill;
	[self.view.layer addSublayer:self.customLayer];
	
	[self.captureSession startRunning];
    
    
    [self performSelectorOnMainThread:@selector(setupUI) withObject:nil waitUntilDone:NO];
	
}

#pragma mark -
#pragma mark AVCaptureSession delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if(sampleBuffer == NULL){
        return;
    }
    
	@autoreleasepool {
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        
        CVPixelBufferLockBaseAddress(imageBuffer,0);
        
        uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        if (!colorSpace)
        {
            return;
        }
        CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        CGImageRef newImage = CGBitmapContextCreateImage(newContext);
        
        
        CVPixelBufferUnlockBaseAddress(imageBuffer,0);
        
        
        CGContextRelease(newContext);
        CGColorSpaceRelease(colorSpace);
        
        
        [self.customLayer performSelectorOnMainThread:@selector(setContents:)
                                           withObject: (__bridge id)newImage waitUntilDone:YES];
        
        
        if(!self.startCapture){
            return;
        }
  
        
        self.resultImage= [UIImage imageWithCGImage:newImage scale:1.0 orientation:UIImageOrientationRight];
        
        
        [self performSelectorOnMainThread:@selector(setImage:)
                               withObject:self.resultImage waitUntilDone:YES];
        
        CGImageRelease(newImage);
    }
}

-(void)setImage:(UIImage *)image{
    if(self.timer == nil){
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(saveImage) userInfo:nil repeats:YES];
    }
}


-(void)saveImage{ 
    [self.imageArray addObject:self.resultImage];
    NSString *timerOut = [NSString stringWithFormat:@"%d",20 - self.imageArray.count];
    timerLabel.text = timerOut;
    
    if(self.imageArray.count >= 20){
        
        [self.timer invalidate];
        self.timer = nil;
        
        timerLabel.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.4f];
        timerLabel.textColor = [UIColor blackColor];
        
        [UIView animateWithDuration:0.5 animations:^(void){
            timerLabel.alpha = 0.0;
        }];
        
        [UIView animateWithDuration:0.5 animations:^(void){
            timerLabel.alpha = 1.0;
        }];
        
        [self performSelectorOnMainThread:@selector(composeGif) withObject:nil waitUntilDone:NO];
        
        return;
    }
}



-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
    [self.captureSession stopRunning];
    self.captureSession = nil;
    [self.timer invalidate];
    self.timer = nil;
    [self.imageArray removeAllObjects];
    self.imageArray = nil;
    gifView = nil;
   
}

-(void)viewDidUnload{
    [super viewDidUnload];
    
    self.customLayer = nil;
    
}



//摄像头切换
- (void)rotateCamera
{
	self.flashOn = YES;
    
    [self performSelectorOnMainThread:@selector(rotateFlash) withObject:nil waitUntilDone:NO];
    
    
    NSError *error;
    AVCaptureDeviceInput *newVideoInput;
    AVCaptureDevicePosition currentCameraPosition = [[_captureInput device] position];
    
    if (currentCameraPosition == AVCaptureDevicePositionBack)
    {
        currentCameraPosition = AVCaptureDevicePositionFront;
        flashBtn.enabled = NO;
    }
    else
    {
        currentCameraPosition = AVCaptureDevicePositionBack;
        flashBtn.enabled = YES;
    }
    
    AVCaptureDevice *backFacingCamera = nil;
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	for (AVCaptureDevice *device in devices)
	{
		if ([device position] == currentCameraPosition)
		{
			backFacingCamera = device;
		}
	}
    newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:backFacingCamera error:&error];
    
    if (newVideoInput != nil)
    {
        [_captureSession beginConfiguration];
        
        [_captureSession removeInput:_captureInput];
        if ([_captureSession canAddInput:newVideoInput])
        {
            [_captureSession addInput:newVideoInput];
            _captureInput = newVideoInput;
        }
        else
        {
            [_captureSession addInput:_captureInput];
        }
        [_captureSession commitConfiguration];
    }
    
}


-(void)rotateFlash{
    if(!self.flashOn){
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasTorch]) {
            [device lockForConfiguration:nil];
            [device setTorchMode: AVCaptureTorchModeOn];
            [device unlockForConfiguration];
        }
        self.flashOn = YES;
    }else{
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasTorch]) {
            [device lockForConfiguration:nil];
            [device setTorchMode: AVCaptureTorchModeOff];
            [device unlockForConfiguration];
        }
        self.flashOn = NO;
    }
}


@end


 
