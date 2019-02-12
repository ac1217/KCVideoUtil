//
//  KCVideoRecorder.h
//  KCVideoUtil
//
//  Created by Erica on 2018/8/22.
//  Copyright © 2018年 Erica. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "KCVideoMacro.h"
#import "KCVideoStyle.h"
#import "KCVideoStickers.h"



@interface KCVideoRecorder : NSObject<KCVideoEffect>


// 最大录制时长
@property (nonatomic,assign) NSTimeInterval maxRecordDuration;
// 当前录制时长
@property (nonatomic,assign, readonly) NSTimeInterval currentRecordDuration;
// 是否正在录制
@property (nonatomic, assign, readonly) BOOL isRecording;
// 预览视图
@property (nonatomic, strong, readonly) UIView *preview;
// 写入视频元数据
@property (nonatomic,strong) NSArray <AVMetadataItem *>*metadata;
// 输出视频大小
@property (nonatomic,assign) CGSize preferedVideoSize;
// 录制状态
@property (nonatomic,assign) KCVideoRecordState recordState;

// 开始录制
- (void)startRecordVideo:(NSURL *)url;
// 停止录制
- (void)stopRecordVideo:(void(^)(NSTimeInterval duration))completion;
// 暂停录制
- (void)pauseRecordVideo;
// 继续录制
- (void)resumeRecordVideo;
// 开始预览
- (void)startPreview;
// 结束预览
- (void)stopPreview;
// 视频需要裁剪的区域（归一化坐标）
//@property(nonatomic) CGRect cropRect;

- (instancetype)initWithSessionPreset:(AVCaptureSessionPreset)sessionPreset;
//预览分辨率
//@property(nonatomic, copy) AVCaptureSessionPreset sessionPreset;

// 码率
@property(nonatomic,assign) NSInteger bitRate;
// 帧率
@property(nonatomic,assign) NSInteger frameRate;
// 闪光灯模式
@property(nonatomic) AVCaptureTorchMode torchMode;
// 暴光模式
@property(nonatomic) AVCaptureExposureMode exposureMode;
// 对焦模式
@property(nonatomic) AVCaptureFocusMode focusMode;
// 对焦点
@property(nonatomic) CGPoint focusPointOfInterest;
// 暴光点
@property(nonatomic) CGPoint exposePointOfInterest;
// ISO -> 0 ~ 1
@property(nonatomic) float ISORate;
// 是否支持闪光灯
@property (nonatomic,assign, readonly) BOOL isTorchSupport;
// 摄像头位置
@property (nonatomic,assign, readonly) AVCaptureDevicePosition cameraPosition;

// 录制状态回调
@property (nonatomic,copy) void(^recordStatusDidChangedBlock)(KCVideoRecorder *recorder, BOOL isRecording);

// 录制进度回调
@property (nonatomic,copy) void(^recordDurationDidChangedBlock)(KCVideoRecorder *recorder, NSTimeInterval maxRecordDuration, NSTimeInterval currentRecordDuration);

// 录制完成
@property (nonatomic,copy) void(^recordDidCompletedBlock)(KCVideoRecorder *recorder);


// 切换手电筒
- (void)switchTorch;

// 切换相机
- (void)switchCamera;


@end
