//
//  KCVideoFilterStyle.h
//  KCVideoUtil
//
//  Created by Erica on 2018/11/20.
//  Copyright © 2018 Erica. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KCVideoMacro.h"

NS_ASSUME_NONNULL_BEGIN

@interface KCVideoStyle : NSObject

// 风格标题
@property (nonatomic,copy) NSString *title;
// 风格ID
@property (nonatomic,copy) NSString *ID;

// 风格lookup图
@property (nonatomic,strong) UIImage *lookup;

// 风格类型
@property (nonatomic,assign) KCVideoStyleType type;

// 值
@property (nonatomic,assign) double value;

/*// 输入图片/输出
@property (nonatomic,strong) UIImage *inputImage;

@property (nonatomic,strong, readonly) UIImage *outputImage;*/

@end

NS_ASSUME_NONNULL_END
