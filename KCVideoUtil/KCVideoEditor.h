//
//  KCVideoEditor.h
//  KuShow
//
//  Created by Rex Wei on 2017/5/25.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface KCVideoEditor : NSObject

+ (instancetype)sharedEditor;

@property (nonatomic, copy) NSArray <AVMetadataItem *> *metadata;

// 压缩&裁剪
- (void)compressAndCutWithFilePath:(NSURL *)filePath
            videoProgressive:(NSInteger)videoProgressive
                   frameRate:(NSInteger)frameRate
                           bitRate:(NSInteger)bitRate
                         startTime:(NSTimeInterval)startTime
                          duration:(NSTimeInterval)duration
                  outputPath:(NSURL *)outputPath
                    progress:(void(^)(float))progress
                  completion:(void(^)(NSError *error))completion;

// 裁剪
- (void)cutWithStartTime:(NSTimeInterval)startTime
                duration:(NSTimeInterval)duration
                filePath:(NSURL *)filePath
              outputPath:(NSURL *)outputPath
                progress:(void(^)(float p))progress
              completion:(void(^)(NSError *error))completion;

// 压缩
// maxVideoSize: 分辨率：如：720x1280 则传720，内部会根据视频分辨率自动换算
// frameRate: 帧率默认30
// bitRate: 码率默认2M
- (void)compressWithFilePath:(NSURL *)filePath
                videoProgressive:(NSInteger)videoProgressive
                   frameRate:(NSInteger)frameRate
                   bitRate:(NSInteger)bitRate
                  outputPath:(NSURL *)outputPath
                    progress:(void(^)(float))progress
                  completion:(void(^)(NSError *error))completion;
// 倒叙
- (void)revertWithFilePath:(NSURL *)filePath
                outputPath:(NSURL *)outputPath
                  progress:(void(^)(float))progress
                completion:(void(^)(NSError *error))completion;
// 添加背音乐
- (void)addAudioWithFilePath:(NSURL *)filePath
               audioFilePath:(NSURL *)audioFilePath
              audioStartTime:(NSTimeInterval)audioStartTime
                  outputPath:(NSURL *)outputPath
                  completion:(void(^)(NSError *error))completion;
// 替换背音乐
- (void)replaceAudioWithFilePath:(NSURL *)filePath
                   audioFilePath:(NSURL *)audioFilePath
                  audioStartTime:(NSTimeInterval)audioStartTime
                      outputPath:(NSURL *)outputPath
                      completion:(void(^)(NSError *error))completion;


// 拼接
- (void)spliceWithFilePaths:(NSArray <NSURL *>*)filePaths
                 outputPath:(NSURL *)outputPath
                 completion:(void(^)(NSError *error))completion;

// 添加水印
- (void)addWatermarkWithFilePath:(NSURL *)filePath
                 wartermarkImage:(UIImage *)wartermarkImage
                           frame:(CGRect)frame
                      outputPath:(NSURL *)outputPath
                      completion:(void(^)(NSError *error))completion;

// 导出融合MV
- (void)exportWithVideoFuses:(NSArray *)vfs
                   videoSize:(CGSize)videoSize
            placeholderImage:(UIImage *)placeholderImage
                    isCancel:(BOOL *)isCancel
                  outputPath:(NSURL *)outputPath
                    progress:(void(^)(float p))progress
                      completion:(void(^)(NSError *error))completion;

// 导出composition
- (id)exportWithComposition:(AVComposition *)composition
         videoComposition:(AVVideoComposition *)vc
                 audioMix:(AVAudioMix *)mix
                  outputPath:(NSURL *)outputPath
                     progress:(void(^)(float p))progress
               completion:(void (^)(NSError *error))completion;

- (void)cancelExport:(id)ex;

// 导出多帧图像 : 废弃
//- (void)exportImagesWithFilePath:(NSURL *)filePath
//                         atTimes:(NSArray *)times
//                      completion:(void(^)(NSArray *images))completion;
@end
