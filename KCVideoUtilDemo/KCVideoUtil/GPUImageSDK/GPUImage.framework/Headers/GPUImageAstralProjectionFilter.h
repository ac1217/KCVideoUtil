//
//  GPUImageAstralProjectionFilter.h
//  GPUImage
//
//  Created by Erica on 2018/9/1.
//  Copyright © 2018年 Brad Larson. All rights reserved.
//

#import "GPUImageFilter.h"

@interface GPUImageAstralProjectionFilter : GPUImageFilter
{
    
    GLint transitionUniform;
}

// 过渡值
@property(readwrite, nonatomic) float transition;
@end
