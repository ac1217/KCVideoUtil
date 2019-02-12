//
//  GPUImageNxNGridAlphaTwoInputFilter.h
//  KGSVideoUtilDemo
//
//  Created by 陈希哲 on 2018/9/12.
//  Copyright © 2018年 Erica. All rights reserved.
//

#import "GPUImageTwoInputFilter.h"

@interface GPUImageNxNGridAlphaTwoInputFilter : GPUImageTwoInputFilter
@property(nonatomic,assign)float step;
-(instancetype)initWithGridX:(NSInteger)x y:(NSInteger)y isFirst:(BOOL)first;

@end
