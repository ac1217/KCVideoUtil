//
//  GPUImage4x4Filter.h
//  KGSVideoUtilDemo
//
//  Created by 陈希哲 on 2018/9/11.
//  Copyright © 2018年 Erica. All rights reserved.
//

#import "GPUImageTwoInputFilter.h"

typedef enum : NSUInteger {
    GPUImage4x4FliterStyle1,
 
    
} GPUImage4x4FliterStyle;

@interface GPUImage4x4Filter : GPUImageTwoInputFilter
@property(nonatomic,assign)GPUImage4x4FliterStyle style;
@property(nonatomic,assign)float step;
@end
