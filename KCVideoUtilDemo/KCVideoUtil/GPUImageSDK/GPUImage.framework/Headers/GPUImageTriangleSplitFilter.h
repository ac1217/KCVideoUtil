//
//  GPUImageTriangleSplitFilter.h
//  LearnOpenGLESWithGPUImage
//
//  Created by 陈希哲 on 2018/9/1.
//  Copyright © 2018年 林伟池. All rights reserved.
//

#import <GPUImage/GPUImageFramework.h>

typedef enum : NSUInteger {
    TriangleSplitTopLeft,
    TriangleSplitTopRight,

} TriangleSplitFilterType;

@interface GPUImageTriangleSplitFilter : GPUImageTwoInputFilter
@property(nonatomic,assign)TriangleSplitFilterType type;
@property(nonatomic,assign)float step;
@end
