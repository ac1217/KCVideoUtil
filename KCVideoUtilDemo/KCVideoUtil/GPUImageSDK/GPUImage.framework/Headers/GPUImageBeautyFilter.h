//
//  GPUImageBeautyFilter.h
//  GPUImage
//
//  Created by Erica on 2018/11/10.
//  Copyright © 2018 Brad Larson. All rights reserved.
//

#import "GPUImageFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface GPUImageBeautyFilter : GPUImageFilter

/** 美颜程度 */
@property (nonatomic, assign) CGFloat beautyLevel;
/** 美白程度 */
@property (nonatomic, assign) CGFloat brightLevel;
/** 色调强度 */
@property (nonatomic, assign) CGFloat toneLevel;
@end

NS_ASSUME_NONNULL_END
