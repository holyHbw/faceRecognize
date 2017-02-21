//
//  ViewController.m
//  faceRecognize
//
//  Created by 黄博闻 on 17/2/20.
//  Copyright © 2017年 黄博闻. All rights reserved.
//

#import "ViewController.h"

typedef struct{
    GLKVector3 positionCoords;
}SceneVertex;

static SceneVertex vertices[3];

@interface ViewController ()
{
    
    CIDetector *faceRecognizer;
    
    AVCaptureDevice *frontDevice;
    AVCaptureDevice *backDevice;
    
    AVCaptureDeviceInput *frontDeviceInput;
    AVCaptureDeviceInput *backDeviceInput;
    
    AVCaptureSession *session;
    
    AVCaptureVideoDataOutput *videoDataOutput;
    AVCaptureStillImageOutput *imageOutput;
    
    AVCaptureVideoPreviewLayer *previewLayer;
    BOOL isUsingFrontFacingCamera;
    
    GLKView *glkView;
    EAGLContext *glContext;
    CIContext *ciContext;
}
@end

@implementation ViewController

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(__bridge NSDictionary *)attachments];
    
#pragma 设置人脸识别的方向
    UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
    int exifOrientation;//捕捉到的图像的方向
    enum {
        PHOTOS_EXIF_0ROW_TOP_0COL_LEFT			= 1, //   1  =  0th row is at the top, and 0th column is on the left (THE DEFAULT).
        PHOTOS_EXIF_0ROW_TOP_0COL_RIGHT			= 2, //   2  =  0th row is at the top, and 0th column is on the right.
        PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT      = 3, //   3  =  0th row is at the bottom, and 0th column is on the right.
        PHOTOS_EXIF_0ROW_BOTTOM_0COL_LEFT       = 4, //   4  =  0th row is at the bottom, and 0th column is on the left.
        PHOTOS_EXIF_0ROW_LEFT_0COL_TOP          = 5, //   5  =  0th row is on the left, and 0th column is the top.
        PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP         = 6, //   6  =  0th row is on the right, and 0th column is the top.
        PHOTOS_EXIF_0ROW_RIGHT_0COL_BOTTOM      = 7, //   7  =  0th row is on the right, and 0th column is the bottom.
        PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM       = 8  //   8  =  0th row is on the left, and 0th column is the bottom.
    };
    
    switch (curDeviceOrientation) {
        case UIDeviceOrientationPortraitUpsideDown:  // Device oriented vertically, home button on the top
            exifOrientation = PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM;
            break;
        case UIDeviceOrientationLandscapeLeft:       // Device oriented horizontally, home button on the right
            if (isUsingFrontFacingCamera)
                exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
            else
                exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
            break;
        case UIDeviceOrientationLandscapeRight:      // Device oriented horizontally, home button on the left
            if (isUsingFrontFacingCamera)
                exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
            else
                exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
            break;
        case UIDeviceOrientationPortrait:   // Device oriented vertically, home button on the bottom
        default:
            exifOrientation = PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP;
            break;
    }
    
    NSDictionary *imageOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:exifOrientation] forKey:CIDetectorImageOrientation];
    NSArray *features = [faceRecognizer featuresInImage:ciImage options:imageOptions];
    
#pragma 原图的尺寸信息
    CMFormatDescriptionRef fdesc = CMSampleBufferGetFormatDescription(sampleBuffer);
    CGRect clap = CMVideoFormatDescriptionGetCleanAperture(fdesc, false /*originIsTopLeft == false*/);
    NSLog(@"%f,%f",clap.size.width,clap.size.height);
    NSLog(@"%f,%f,%f,%f",ciImage.extent.origin.x,ciImage.extent.origin.y,ciImage.extent.size.width,ciImage.extent.size.height);
    
    ciImage = [ciImage imageByApplyingTransform:[ciImage imageTransformForOrientation:6]];
    NSLog(@"%f,%f,%f,%f",ciImage.extent.origin.x,ciImage.extent.origin.y,ciImage.extent.size.width,ciImage.extent.size.height);
    
    [glkView bindDrawable];
    [ciContext drawImage:ciImage inRect:ciImage.extent fromRect:ciImage.extent ];
    
#pragma 与主线程同步
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self drawFaceBoxesForFeatures:features forVideoBox:clap orientation:curDeviceOrientation];
    });
    
    NSLog(@"%@",features);
}

- (void)drawFaceBoxesForFeatures:(NSArray *)features forVideoBox:(CGRect)clap orientation:(UIDeviceOrientation)orientation{
    NSLog(@"drawFaceBoxesForFeatures");
    for (CIFaceFeature *f in features) {
        
        NSLog (NSStringFromCGRect(f.bounds));
        
        //        if (f.hasLeftEyePosition)
        //            NSLog (@"left eye %g %g",f.leftEyePosition.x, f.leftEyePosition.y);
        //        if (f.hasRightEyePosition)
        //            NSLog (@"right eye %g %g",f.rightEyePosition.x, f.rightEyePosition.y);
        //        if (f.hasMouthPosition)
        //            NSLog (@"mouth eye %g %g",f.mouthPosition.x, f.mouthPosition.y);
        
        //        NSMutableArray *faceArr = [NSMutableArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(f.leftEyePosition.x, f.leftEyePosition.y)],[NSValue valueWithCGPoint:CGPointMake(f.rightEyePosition.x, f.rightEyePosition.y)],[NSValue valueWithCGPoint:CGPointMake(f.mouthPosition.x, f.mouthPosition.y)], nil];
        //        [previewLayer setFaceFeaturesArray:faceArr];
        //        [previewLayer testFunc];
        //        [previewLayer setNeedsDisplay];
        
        CGRect face_Rect = [f bounds];
        
        // flip preview width and height  变换宽与高、x与y坐标
        CGFloat temp = face_Rect.size.width;
        face_Rect.size.width = face_Rect.size.height;
        face_Rect.size.height = temp;
        temp = face_Rect.origin.x;
        face_Rect.origin.x = face_Rect.origin.y;
        face_Rect.origin.y = temp;
        // scale coordinates so they fit in the preview box, which may be scaled
        CGFloat widthScaleBy = [UIScreen mainScreen].bounds.size.width / clap.size.height;
        CGFloat heightScaleBy = [UIScreen mainScreen].bounds.size.height / clap.size.width;
        face_Rect.size.width *= widthScaleBy;
        face_Rect.size.height *= heightScaleBy;
        face_Rect.origin.x *= widthScaleBy;
        face_Rect.origin.y *= heightScaleBy;
        
        NSLog(@"clap:%f,%f,%f,%f",clap.origin.x,clap.origin.y,clap.size.width,clap.size.height);
        NSLog(@"face_Rect:%f,%f",face_Rect.size.width,face_Rect.size.height);
        
        CGFloat leftEyePositionX = f.leftEyePosition.y*([UIScreen mainScreen].bounds.size.width/clap.size.height);
        CGFloat leftEyePositionY = f.leftEyePosition.x*([UIScreen mainScreen].bounds.size.height/clap.size.width);
        
        NSLog (@"left eye: %g %g",f.leftEyePosition.x, f.leftEyePosition.y);
        NSLog (@"left eye after: %g %g",leftEyePositionX, leftEyePositionY );
        
        //先转换为openGLES坐标(未考虑z)
        CGFloat x = 2*leftEyePositionX/self.view.bounds.size.width-1;
        CGFloat y = 1-2*leftEyePositionY/self.view.bounds.size.height;
        
        NSLog(@"openGLES  x:%f, y:%f",x,y);
        
        GLKVector3 top = GLKVector3Make(x, y+0.02, 0);
        GLKVector3 right = GLKVector3Make(x+0.02, y-0.02, 0);
        GLKVector3 left = GLKVector3Make(x-0.02, y-0.02, 0);
        
        NSLog(@"openGLES top x:%f, y:%f",x,y+0.02);
        NSLog(@"openGLES right x:%f, y:%f",x+0.02,y-0.02);
        NSLog(@"openGLES left x:%f, y:%f",x-0.02,y-0.02);
        
        SceneVertex Top = {top};
        SceneVertex Right = {right};
        SceneVertex Left = {left};
        
        vertices[0] = Top;
        vertices[1] = Right;
        vertices[2] = Left;
        
        [self.baseEffect prepareToDraw];
        
        // Clear Frame Buffer (erase previous drawing)
        //glClear(GL_COLOR_BUFFER_BIT);
        
        // Generate, bind, and initialize contents of a buffer to be
        // stored in GPU memory
        glGenBuffers(1,                // STEP 1
                     &vertexBufferID);
        glBindBuffer(GL_ARRAY_BUFFER,  // STEP 2
                     vertexBufferID);
        glBufferData(                  // STEP 3
                     GL_ARRAY_BUFFER,  // Initialize buffer contents
                     sizeof(vertices), // Number of bytes to copy
                     vertices,         // Address of bytes to copy
                     GL_STATIC_DRAW);  // Hint: cache in GPU memory
        
        // Enable use of positions from bound vertex buffer
        glEnableVertexAttribArray(      // STEP 4
                                  GLKVertexAttribPosition);
        
        glVertexAttribPointer(          // STEP 5
                              GLKVertexAttribPosition,
                              3,                   // three components per vertex
                              GL_FLOAT,            // data is floating point
                              GL_FALSE,            // no fixed point scaling
                              sizeof(SceneVertex), // no gaps in data
                              NULL);               // NULL tells GPU to start at
        // beginning of bound buffer
        
        // Draw triangles using the first three vertices in the
        // currently bound vertex buffer
        glDrawArrays(GL_TRIANGLES,      // STEP 6
                     0,  // Start with first vertex in currently bound buffer
                     3); // Use three vertices from currently bound buffer
    }
    [glkView display];
}


-(AVCaptureDevice*)getDeviceWithPosition:(AVCaptureDevicePosition)position{
    
    NSArray *deviceArr = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *returnDevice;
    for (AVCaptureDevice *device in deviceArr) {
        if (device.position == position) {
            returnDevice = device;
            break;
        }
    }
    return returnDevice;
}

-(BOOL)prefersStatusBarHidden{
    return YES;
}

-(void)stopSession:(id)sender{
    
    [session stopRunning];
    ((UIButton *)sender).hidden = YES;
}

-(void)viewWillAppear:(BOOL)animated{
    backDevice = [self getDeviceWithPosition:AVCaptureDevicePositionBack];
    frontDevice = [self getDeviceWithPosition:AVCaptureDevicePositionFront];
    
    NSError *inputError;
    backDeviceInput = [[AVCaptureDeviceInput alloc]initWithDevice:backDevice error:&inputError];
    frontDeviceInput = [[AVCaptureDeviceInput alloc]initWithDevice:frontDevice error:&inputError];
    
    session = [[AVCaptureSession alloc]init];
    if ([session canAddInput:backDeviceInput]) {
        [session addInput:backDeviceInput];
        isUsingFrontFacingCamera = NO;
    }
    
    //    [session beginConfiguration]; // the session to which the receiver's AVCaptureDeviceInput is added.
    //    NSError *frameError;
    //    CMTime maxDuration = CMTimeMake(1, 10);
    //    if ( [backDevice lockForConfiguration:&frameError] ) {
    //        [backDevice setActiveVideoMaxFrameDuration:maxDuration];
    //        [backDevice unlockForConfiguration];
    //    }
    //    [session commitConfiguration];
    
    videoDataOutput = [[AVCaptureVideoDataOutput alloc]init];
    videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
    [videoDataOutput setVideoSettings:videoSettings];
    
    if ([session canAddOutput:videoDataOutput]) {
        [session addOutput:videoDataOutput];
    }
    
    dispatch_queue_t queue = dispatch_queue_create("cameraQueue", NULL);
    [videoDataOutput setSampleBufferDelegate:self queue:queue];
    
    NSDictionary *detectorOptions = [[NSDictionary alloc] initWithObjectsAndKeys:CIDetectorAccuracyLow, CIDetectorAccuracy, nil];
    faceRecognizer = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
    
}

-(void)start{
    [session startRunning];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    glContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    glkView = [[GLKView alloc]initWithFrame:self.view.bounds context:glContext];
    [EAGLContext setCurrentContext:glkView.context];
    [self.view addSubview:glkView];
    UIButton *start = [UIButton buttonWithType:UIButtonTypeCustom];
    [start setFrame:CGRectMake(150, 600, 80, 80)];
    [start setTitle:@"开始" forState:UIControlStateNormal];
    [start addTarget:self action:@selector(start) forControlEvents:UIControlEventTouchUpInside];
    [glkView addSubview:start];
    ciContext = [CIContext contextWithEAGLContext:glContext];
    
    self.baseEffect = [[GLKBaseEffect alloc] init];
    self.baseEffect.useConstantColor = GL_TRUE;
    self.baseEffect.constantColor = GLKVector4Make(
                                                   1.0f, // Red
                                                   1.0f, // Green
                                                   1.0f, // Blue
                                                   1.0f);// Alpha
    
    // Set the background color stored in the current context
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f); // background color
    
    //NSLog(@"%lu",sizeof(vertices));
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
