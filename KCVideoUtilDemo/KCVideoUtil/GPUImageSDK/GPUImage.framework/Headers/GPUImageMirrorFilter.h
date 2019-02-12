//
//  GPUImageMirrorFilter.h
//  SimpleVideoFilter
//
//  Created by Erica on 2018/8/21.
//  Copyright © 2018年 Cell Phone. All rights reserved.
//
#import "GPUImageFilter.h"

typedef enum : NSUInteger {
    GPUImageMirrorStyleXAxisymmetry, // X轴对称
    GPUImageMirrorStyleXCentersymmetry, // X中心对称
    GPUImageMirrorStyleYAxisymmetry, // Y轴对称
    GPUImageMirrorStyleYCentersymmetry, // Y中心对称
    GPUImageMirrorStyleXYSymmetry // XY对称
} GPUImageMirrorStyle;

@interface GPUImageMirrorFilter : GPUImageFilter
{
    GLint styleUniform;
}

@property(readwrite, nonatomic) GPUImageMirrorStyle style;

@end
