//
//  KCVideoFuseFilter.h
//  CoreImageDemo
//
//  Created by Erica on 2018/12/24.
//  Copyright © 2018 Erica. All rights reserved.
//

#import <CoreImage/CoreImage.h>

#import <UIKit/UIKit.h>

@interface KCVideoFuseFilterInput : NSObject

@property (nonatomic,strong) CIImage *image;
@property (nonatomic,assign) CGRect coordinate;
@property (nonatomic,assign) int fillMode;
@property (nonatomic,assign) int orientation;

@end


NS_ASSUME_NONNULL_BEGIN

@interface KCVideoFuseCIFilter : CIFilter

@property (nonatomic,strong) NSArray <KCVideoFuseFilterInput *>*inputs;

@property (nonatomic,assign) CGSize preferedSize;
@property (nonatomic,assign) CGFloat maxSize; // 1280 x 1280

// 废弃
//@property (nonatomic,strong) NSArray *inputImages;
//@property (nonatomic,strong) NSArray *coordinates;
//@property (nonatomic,strong) NSArray *fillModes;

@property (nonatomic,strong) CIColor *bgColor;
@property (nonatomic,strong) CIColor *borderColor;
@property (nonatomic,assign) float borderWidth;

@end

NS_ASSUME_NONNULL_END
