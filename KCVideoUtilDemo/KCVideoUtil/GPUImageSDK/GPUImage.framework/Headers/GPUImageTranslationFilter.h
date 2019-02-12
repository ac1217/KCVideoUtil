//
//  GPUImageTranslationFilter.h
//  KGSVideoUtil
//
//  Created by Erica on 2018/10/25.
//  Copyright © 2018 Erica. All rights reserved.
//

#import <GPUImage/GPUImageFramework.h>

typedef enum : NSUInteger {
     GPUImageTranslationDirectionRight,
    GPUImageTranslationDirectionLeft,
    GPUImageTranslationDirectionBottom,
    GPUImageTranslationDirectionTop
} GPUImageTranslationDirection;


@interface GPUImageTranslationFilter : GPUImageTwoInputFilter
{
    GLint ratioUniform;
    GLint directionUniform;
}


@property(readwrite, nonatomic) CGFloat ratio;
@property(readwrite, nonatomic) GPUImageTranslationDirection direction;

@end
