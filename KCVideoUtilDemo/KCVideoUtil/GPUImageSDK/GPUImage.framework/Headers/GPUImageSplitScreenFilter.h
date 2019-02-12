//
//  GPUImageSplitScreenFilter.h
//  GPUImage
//
//  Created by Erica on 2018/8/31.
//  Copyright © 2018年 Brad Larson. All rights reserved.
//

#import "GPUImageFilter.h"

typedef enum : NSUInteger {
    GPUImageSplitScreenDirectionHorizontal,
    GPUImageSplitScreenDirectionVertical
} GPUImageSplitScreenDirection;

@interface GPUImageSplitScreenFilter : GPUImageFilter
{
    GLint ratioUniform;
    GLint directionUniform;
}


@property(readwrite, nonatomic) CGFloat ratio;
@property(readwrite, nonatomic) GPUImageSplitScreenDirection direction;


@end
