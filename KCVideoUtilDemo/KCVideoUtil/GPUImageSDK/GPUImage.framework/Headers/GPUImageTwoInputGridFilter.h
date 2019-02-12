//
//  GPUImageTwoInputGridFilter.h
//  GPUImage
//
//  Created by Erica on 2018/8/29.
//  Copyright © 2018年 Brad Larson. All rights reserved.
//

#import "GPUImageTwoInputFilter.h"

@interface GPUImageTwoInputGridFilter : GPUImageTwoInputFilter
{
    GLint lengthUniform;
    GLint sizeUniform;
    GLint invertUniform;
}

// length x length 网格滤镜，边长
@property(readwrite, nonatomic) NSInteger length;

@property(readwrite, nonatomic) CGSize size;

@property(readwrite, nonatomic) BOOL invert;

@end
