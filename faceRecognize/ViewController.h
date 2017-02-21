//
//  ViewController.h
//  faceRecognize
//
//  Created by 黄博闻 on 17/2/20.
//  Copyright © 2017年 黄博闻. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    GLuint vertexBufferID;
}
@property(strong,nonatomic)GLKBaseEffect *baseEffect;

@end

