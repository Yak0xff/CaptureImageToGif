//
//  ViewController.m
//  CaptureImageToGif
//
//  Created by Yongchao on 22/11/13.
//  Copyright (c) 2013 Yongchao. All rights reserved.
//

#import "ViewController.h"
#import "CaptureViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setFrame:CGRectMake(0, 0, 100, 50)];
    [button setCenter:CGPointMake(CGRectGetWidth(self.view.frame) / 2, CGRectGetHeight(self.view.frame)/2)];
    [button setTitle:@"开始" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(benginCapture:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
}

-(void)benginCapture:(id)sender{
    CaptureViewController *captureViewController = [[CaptureViewController alloc] init];
    [self presentViewController:captureViewController animated:YES completion:NULL];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
