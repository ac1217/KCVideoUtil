//
//  KCVideoWriter.h
//  KChortVideo
//
//  Created by Erica on 2018/8/6.
//  Copyright © 2018年 Erica. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class KCVideoWriter;
@protocol KCVideoWriterDelegate<NSObject>

@optional
- (void)updateWriteDuration:(NSTimeInterval)duration;

@end
@interface KCVideoWriter : NSObject

@property (nonatomic,strong) NSArray <AVMetadataItem *>*metadata;

@property (nonatomic, assign) id<KCVideoWriterDelegate> delegate;

@property (nonatomic,assign) BOOL writing;
@property (nonatomic,assign, readonly) NSTimeInterval duration;

//- (void)appendPixelBuffer:(CVPixelBufferRef)p forTime:(CMTime)time;
- (void)appendVideoSampleBuffer:(CMSampleBufferRef)ref;
- (void)appendAudioSampleBuffer:(CMSampleBufferRef)ref;

- (void)startWriting:(NSURL *)path;
- (void)finishWriting:(void (^)(NSTimeInterval duration))completion;
- (void)cancelWriting;

@property (nonatomic,assign) CGSize preferedVideoSize;
@property (nonatomic,assign) int preferedFrameRate;
@property (nonatomic,assign) long preferedBitRate;
//@property (nonatomic,strong) NSDictionary *videoOutputSetting;
//@property (nonatomic,strong) NSDictionary *audioOutputSetting;

@end
