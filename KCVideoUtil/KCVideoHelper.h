//
//  KCVideoHelper.h
//  KCVideoUtil
//
//  Created by Erica on 2018/12/19.
//  Copyright © 2018 Erica. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import <GPUImage/GPUImageFramework.h>
#import "KCVideoInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface KCVideoHelper : NSObject

+ (instancetype)sharedHelper;

// 获取视频信息
- (void)requestInfoWithFilePath:(NSURL *)filePath
                     completion:(void(^)(KCVideoInfo *info))completion;

// 同步获取某帧图像
- (UIImage *)reqeustImageWithFilePath:(NSURL *)filePath atTime:(NSTimeInterval)time;
// 同步获取某帧图像
- (CGImageRef)copyImageWithFilePath:(NSURL *)filePath atTime:(NSTimeInterval)time;
// 异步获取多帧图像
- (void)reqeustImagesWithFilePath:(NSURL *)filePath
                         atTimes:(NSArray *)times
                      completion:(void(^)(NSArray *images))completion;

- (GLuint)textureWithPixelBuffer:(CVPixelBufferRef)pixelBuffer;

- (CVPixelBufferRef)createPixelBufferWithImage:(UIImage *)image;


@end

NS_ASSUME_NONNULL_END
