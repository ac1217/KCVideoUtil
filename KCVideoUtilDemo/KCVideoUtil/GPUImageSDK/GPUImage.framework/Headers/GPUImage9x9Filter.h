//
//  GPUImage9x9Fliter.h
//  KGSVideoUtilDemo
//
//  Created by 陈希哲 on 2018/9/3.
//  Copyright © 2018年 Erica. All rights reserved.
//

#import "GPUImageTwoInputFilter.h"

typedef enum : NSUInteger {
    GPUImage9x9FliterStyle1,
    
    
} GPUImage9x9FliterStyle;

@interface GPUImage9x9Filter : GPUImageTwoInputFilter
@property(nonatomic,assign)GPUImage9x9FliterStyle style;
@property(nonatomic,assign)float step;
@end
