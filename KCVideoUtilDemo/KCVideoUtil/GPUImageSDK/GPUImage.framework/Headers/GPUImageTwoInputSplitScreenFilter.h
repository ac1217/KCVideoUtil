//
//  GPUImageTwoInputSplitScreenFilter.h
//  KGSVideoUtilDemo
//
//  Created by Erica on 2018/8/29.
//  Copyright © 2018年 Erica. All rights reserved.
//

#import "GPUImageTwoInputFilter.h"
#import "GPUImageSplitScreenFilter.h"

//typedef enum : NSUInteger {
//    GPUImageSplitScreenDirectionHorizontal,
//    GPUImageSplitScreenDirectionVertical
//} GPUImageSplitScreenDirection;

@interface GPUImageTwoInputSplitScreenFilter : GPUImageTwoInputFilter
{
    GLint ratioUniform;
    GLint directionUniform;
}


@property(readwrite, nonatomic) CGFloat ratio;
@property(readwrite, nonatomic) GPUImageSplitScreenDirection direction;

@end
