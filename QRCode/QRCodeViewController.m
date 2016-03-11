//
//  ViewController.m
//  QRCode
//
//  Created by admin on 15/9/23.
//  Copyright © 2015年 admin. All rights reserved.
//

#import "QRCodeViewController.h"

@interface QRCodeViewController (){
    CGPoint _points[4];
}
@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) AVCaptureDeviceInput *inputDevice;
@property (strong, nonatomic) AVCaptureMetadataOutput *metadataOutput;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property CGRect screenRect;
@property CGFloat width;

@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@end

@implementation QRCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _screenRect = self.view.frame;
    _width = _screenRect.size.width / 1.5;
    [self initPoints];
    
    [self initCapture];
    
    [self initMaskLayer];
}

-(void)viewDidDisappear:(BOOL)animated{
    [_session stopRunning];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - init methods
-(void)initCapture{
    NSError *err = nil;
    
    //init session
    _session = [[AVCaptureSession alloc]init];
    _session.sessionPreset = AVCaptureSessionPresetHigh;
    
    //add input
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    _inputDevice = [AVCaptureDeviceInput deviceInputWithDevice:device error:&err];
    if (!err) {
        if ([_session canAddInput:_inputDevice]) {
            [_session addInput:_inputDevice];
        }
    }else{
        NSLog(@"err: %@", err);
    }
    
    //add output
    _metadataOutput = [[AVCaptureMetadataOutput alloc]init];
    [_metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    _metadataOutput.rectOfInterest = CGRectMake(_points[0].y / _screenRect.size.height, _points[0].x/ _screenRect.size.width, _width / _screenRect.size.height, _width / _screenRect.size.width);
    if ([_session canAddOutput:_metadataOutput]) {
        [_session addOutput:_metadataOutput];
    }
    _metadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
    
    //init preview
    _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _previewLayer.frame = _screenRect;
    [self.view.layer insertSublayer:_previewLayer atIndex:0];
    [_session startRunning];
}

-(void)initPoints{//四个角的坐标
    CGPoint topLeft = CGPointMake((_screenRect.size.width - _width) / 2, _screenRect.size.height / 2 - _width);
    CGPoint topRight = CGPointMake((_screenRect.size.width + _width) / 2, _screenRect.size.height / 2 - _width);
    CGPoint bottomLeft = CGPointMake((_screenRect.size.width - _width) / 2, _screenRect.size.height / 2);
    CGPoint bottomRight = CGPointMake((_screenRect.size.width + _width) / 2, _screenRect.size.height / 2);
    
    _points[0] = topLeft;
    _points[1] = topRight;
    _points[2] = bottomLeft;
    _points[3] = bottomRight;
}

-(void)initMaskLayer{
    
    CALayer *maskLayer = [[CALayer alloc]init];
    maskLayer.frame = _screenRect;
    maskLayer.delegate = self;
    [maskLayer setNeedsDisplay];//自动调用drawLayer...的方法
    
    CALayer *layerTop = [self getMaskSubLayerWithFrame:CGRectMake(0, 0, _screenRect.size.width, _screenRect.size.height / 2 - _width)];
    CALayer *layerBottom = [self getMaskSubLayerWithFrame:CGRectMake(0, _points[2].y, _screenRect.size.width, _screenRect.size.height / 2)];
    CALayer *layerLeft = [self getMaskSubLayerWithFrame:CGRectMake(0,  _points[0].y, (_screenRect.size.width - _width) / 2, _width)];
    CALayer *layerRight = [self getMaskSubLayerWithFrame:CGRectMake(_points[1].x, _points[1].y , _screenRect.size.width, _width)];
    
    [maskLayer addSublayer:layerTop];
    [maskLayer addSublayer:layerBottom];
    [maskLayer addSublayer:layerLeft];
    [maskLayer addSublayer:layerRight];    
    
    [self.view.layer insertSublayer:maskLayer above:_previewLayer];
}

-(CALayer *)getMaskSubLayerWithFrame:(CGRect)frame{
    CALayer *layer = [[CALayer alloc]init];
    layer.frame = frame;
    layer.opacity = 0.5;
    layer.backgroundColor = [[UIColor blackColor]CGColor];
    
    return layer;
}

#pragma mark - metadataOutput delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if ([metadataObjects count] > 0) {
        [_session stopRunning];
        AVMetadataMachineReadableCodeObject *metadataObject = metadataObjects[0];
        NSString *value = metadataObject.stringValue;
        NSLog(@"%@", value);//https://login.weixin.qq.com/l/AfamDhRKMA==
        _valueLabel.text = value;
    }
}

#pragma mark -maskLayer delegate
-(void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx{
    //绘制直线
    CGContextSetRGBStrokeColor(ctx, 0, 1, 0, 1);
    CGContextSetLineWidth(ctx, 2);
    CGFloat len = 50;
    
    CGPoint L_TPoints[3];
    L_TPoints[0] = CGPointMake(_points[0].x, _points[0].y + len);
    L_TPoints[1] = _points[0];
    L_TPoints[2] = CGPointMake(_points[0].x + len, _points[0].y);
    CGContextAddLines(ctx, L_TPoints, 3);
    
    CGPoint R_TPoints[3];
    R_TPoints[0] = CGPointMake(_points[1].x - len, _points[1].y);
    R_TPoints[1] = _points[1];
    R_TPoints[2] = CGPointMake(_points[1].x, _points[1].y + len);
    CGContextAddLines(ctx, R_TPoints, 3);
    
    CGPoint L_BPoints[3];
    L_BPoints[0] = CGPointMake(_points[2].x, _points[2].y - len);
    L_BPoints[1] = _points[2];
    L_BPoints[2] = CGPointMake(_points[2].x + len, _points[2].y);
    CGContextAddLines(ctx, L_BPoints, 3);
    
    CGPoint R_BPoints[3];
    R_BPoints[0] = CGPointMake(_points[3].x - len, _points[3].y);
    R_BPoints[1] = _points[3];
    R_BPoints[2] = CGPointMake(_points[3].x, _points[3].y - len);
    CGContextAddLines(ctx, R_BPoints, 3);
    
    CGContextDrawPath(ctx, kCGPathStroke);
}
@end
