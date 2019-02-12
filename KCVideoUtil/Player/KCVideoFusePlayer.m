//
//  KCVideoFusePlayer2.m
//  KCVideoUtil
//
//  Created by Erica on 2018/11/16.
//  Copyright © 2018 Erica. All rights reserved.
//

#import "KCVideoFusePlayer.h"
#import "KCVideoFuseCIFilter.h"
#import "KCVideoHelper.h"

@interface KCVideoFuseCompositionInstructionItem : NSObject

@property (nonatomic,assign) CMPersistentTrackID trackID;
@property (nonatomic,assign) GPUImageRotationMode rotationMode;
@property (nonatomic,assign) CMTime duration;
@property (nonatomic,assign) int orientation;
@property (nonatomic,assign) int fillMode;
@property (nonatomic,strong) CIImage *endImage;
@property (nonatomic,assign) CGRect coordinate;

// 预留
@property (nonatomic,assign) CMTime startTime;
@property (nonatomic,strong) CIImage *beginImage;
@end


@implementation KCVideoFuseCompositionInstructionItem


@end


@interface KCVideoFuseCompositionInstruction : NSObject <AVVideoCompositionInstruction>

@property (nonatomic,strong) NSArray <KCVideoFuseCompositionInstructionItem *>*items;

@property (nonatomic,strong) KCVideoFuseCIFilter *fuseCIFilter;

@property (nonatomic,strong) CIImage *placeholderImage;

@end

@implementation KCVideoFuseCompositionInstruction

@synthesize timeRange = _timeRange;
@synthesize enablePostProcessing = _enablePostProcessing;
@synthesize containsTweening = _containsTweening;
@synthesize requiredSourceTrackIDs = _requiredSourceTrackIDs;
@synthesize passthroughTrackID = _passthroughTrackID;


- (id)initWithRequiredSourceTrackIDs:(NSArray *)requiredSourceTrackIDs timeRange:(CMTimeRange)timeRange
{
    
    self = [super init];
    if (self) {
        _requiredSourceTrackIDs = requiredSourceTrackIDs;
        _passthroughTrackID = kCMPersistentTrackID_Invalid;
        _timeRange = timeRange;
        _containsTweening = TRUE;
        _enablePostProcessing = FALSE;
    }
    
    return self;
}

@end


@interface KCVideoFuseCompositor : NSObject<AVVideoCompositing>
{
    BOOL                                _shouldCancelAllRequests;
    dispatch_queue_t                    _renderingQueue;
    dispatch_queue_t                    _renderContextQueue;
    BOOL                                _inBackground;
    
    CIContext *_context;
}

@end

@implementation KCVideoFuseCompositor

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _renderingQueue = dispatch_queue_create("com.apple.aplcustomvideocompositor.renderingqueue", DISPATCH_QUEUE_SERIAL);
        _renderContextQueue = dispatch_queue_create("com.apple.aplcustomvideocompositor.rendercontextqueue", DISPATCH_QUEUE_SERIAL);
        
        EAGLContext *glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
          CIContext *context = [CIContext contextWithEAGLContext:glContext];
        _context = context;
        
//        _context = [CIContext contextWithOptions:nil];
        
//        _context = [CIContext contextWithMTLDevice:MTLCreateSystemDefaultDevice() options:nil];
        
    }
    return self;
}

- (NSDictionary *)sourcePixelBufferAttributes {
    return @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]};
}

- (NSDictionary *)requiredPixelBufferAttributesForRenderContext {
    return @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]};
}

- (void)startVideoCompositionRequest:(AVAsynchronousVideoCompositionRequest *)request {
    
        dispatch_async(_renderingQueue,^() {
    
            @autoreleasepool {
                // Check if all pending requests have been cancelled
                if (_shouldCancelAllRequests) {
                    [request finishCancelledRequest];
                } else {
                    
                    NSError *err = nil;
                    
                    CVPixelBufferRef resultPixels = [request.renderContext newPixelBuffer];
                    
                    KCVideoFuseCompositionInstruction *instruction = request.videoCompositionInstruction;
                    
                    KCVideoFuseCIFilter *fuCIFilter = instruction.fuseCIFilter;
                    
                    NSMutableArray *inputs = @[].mutableCopy;
                    for (int i = 0; i < instruction.items.count; i++) {
                        
//                        @autoreleasepool {
                        KCVideoFuseCompositionInstructionItem *item = instruction.items[i];
                            
                        CMPersistentTrackID trackID = item.trackID;
                        
                        KCVideoFuseFilterInput *input = [KCVideoFuseFilterInput new];
                        input.coordinate = item.coordinate;
                        input.fillMode = item.fillMode;
                        input.orientation = item.orientation;
                        [inputs addObject:input];
                        
                        if (trackID) {
                            
                            CVPixelBufferRef pixelBuffer = NULL;
                            
                            if (CMTimeCompare(item.duration, request.compositionTime) == 1) {
                                
                                pixelBuffer = [request sourceFrameByTrackID:trackID];
                                
                            }
                            
                            if (pixelBuffer) {
                                
                                CIImage *image = [CIImage imageWithCVImageBuffer:pixelBuffer];
                                
                                input.image = image;
                                
                            }else {
                                
                                if (item.endImage) {
                                    input.image = item.endImage;
                                }else {
                                    
                                    if (instruction.placeholderImage) {
                                        input.image = instruction.placeholderImage;
                                        input.fillMode = 1;
                                    }
                                }
                                
                            }
                          
                            
                        }else {
                            
                            if (instruction.placeholderImage) {
                                input.image = instruction.placeholderImage;
                                input.fillMode = 1;
                            }
                            
                        }
                        
                    }
                    
                    fuCIFilter.inputs = inputs;
                    
                    CIImage *outputImage = [fuCIFilter outputImage];
                    
                    [_context render:outputImage toCVPixelBuffer:resultPixels];
                    
                    if (@available(iOS 10.0, *)) {
                        [_context clearCaches];
                    }
                    
                    if (resultPixels) {
                        
                        [request finishWithComposedVideoFrame:resultPixels];
                        CFRelease(resultPixels);
                        
                        
                    } else {
                        [request finishWithError:err];
                    }
                    
                    
                }
            }
        });
}

- (void)renderContextChanged:(AVVideoCompositionRenderContext *)newRenderContext {
    
}
- (void)cancelAllPendingVideoCompositionRequests{
    
    _shouldCancelAllRequests = YES;
    
    dispatch_barrier_async(_renderingQueue, ^() {
        // start accepting requests again
        _shouldCancelAllRequests = NO;
    });
}

@end


@interface KCVideoFusePlayer()

@property (nonatomic,strong) KCVideoFuseCIFilter *fuseCIFilter;

@property (nonatomic,strong) KCVideoFuseCompositionInstruction *instruction;

@property (nonatomic,strong) NSArray *usageVideoFuses;

@end

@implementation KCVideoFusePlayer
#pragma mark -Setter
- (void)setVideoBorderWidth:(CGFloat)videoBorderWidth
{
    _videoBorderWidth = videoBorderWidth;
    self.fuseCIFilter.borderWidth = videoBorderWidth;
}

- (void)setVideoBgColor:(UIColor *)videoBgColor
{
    _videoBgColor = videoBgColor;
    
    self.fuseCIFilter.bgColor = [CIColor colorWithCGColor:videoBgColor.CGColor];
    
}

- (void)setVideoBorderColor:(UIColor *)videoBorderColor
{
    _videoBorderColor = videoBorderColor;
    
    self.fuseCIFilter.borderColor = [CIColor colorWithCGColor:videoBorderColor.CGColor];
    
    
}

- (void)setPreferedVideoSize:(CGSize)preferedVideoSize
{
    _preferedVideoSize = preferedVideoSize;
    
    self.fuseCIFilter.preferedSize = preferedVideoSize;
}

- (void)setPlaceholderImage:(UIImage *)placeholderImage
{
    _placeholderImage = placeholderImage;
    
    if (!self.instruction) {
        return;
    }
    
    if (placeholderImage) {
        
        self.instruction.placeholderImage = [CIImage imageWithCGImage:placeholderImage.CGImage];
        
    }else {
        
        CGRect rect=CGRectMake(0.0f, 0.0f, 1,1);
        UIGraphicsBeginImageContext(rect.size);//创建图片
        CGContextRef context = UIGraphicsGetCurrentContext();//创建图片上下文
        CGContextSetFillColorWithColor(context, [self.videoBgColor CGColor]);//设置当前填充颜色的图形上下文
        CGContextFillRect(context, rect);//填充颜色
        UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
        self.instruction.placeholderImage = [CIImage imageWithCGImage:theImage.CGImage];
        UIGraphicsEndImageContext();
        
    }
}

- (void)setVideoFuses:(NSArray<KCVideoFuse *> *)videoFuses
{
    _videoFuses = videoFuses;
    
    [self stop];
}

#pragma mark -Life Cycle
- (instancetype)init
{
    if (self = [super init]) {
        
        self.preferedVideoSize = CGSizeMake(720, 1280);
        self.playbackProgressTimeInterval = 0.1;
        self.videoBgColor = [UIColor blackColor];
        self.videoBorderColor = [UIColor blackColor];
        self.videoBorderWidth = 3;
        
        
    }
    return self;
}

- (void)setVolume:(float)volume forIndex:(NSInteger)index
{
    
    if (index >= self.videoFuses.count) {
        NSLog(@"传入的对象不在范围之内");
        return;
    }
    
    KCVideoFuse *vf = self.videoFuses[index];
    vf.volume = volume;
    
    NSInteger idx = [self.usageVideoFuses indexOfObject:vf];
    
    AVMutableAudioMix *audioMix = [self.player.currentItem.audioMix mutableCopy];
    
    NSMutableArray *inputParameters = audioMix.inputParameters.mutableCopy;
    
    AVMutableAudioMixInputParameters *params = [inputParameters[idx] mutableCopy];
    
    [params setVolume:vf.volume atTime:kCMTimeZero];
    
    inputParameters[idx] = params;
    
    audioMix.inputParameters = inputParameters;
    
    self.player.currentItem.audioMix = audioMix;
    
}

- (void)createPlayerResource
{
    self.fuseCIFilter = [[KCVideoFuseCIFilter alloc] init];
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    NSMutableArray *inputParameters = @[].mutableCopy;
    NSMutableArray *items = @[].mutableCopy;
    NSMutableArray *usageVideoFuses = @[].mutableCopy;
    NSMutableArray *sourceTrackIDs = @[].mutableCopy;
    self.usageVideoFuses = usageVideoFuses;
    
    for (KCVideoFuse *vf in self.videoFuses) {
        
        KCVideoFuseCompositionInstructionItem *item = [KCVideoFuseCompositionInstructionItem new];
        [items addObject:item];
        item.coordinate = vf.coordinate;
        
        if (vf.URL) {
            
            [usageVideoFuses addObject:vf];
            
            AVURLAsset *asset = [AVURLAsset assetWithURL:vf.URL];
            
            [asset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
                
            }];
            
            item.duration = asset.duration;
            
            AVAssetTrack *voiceTrack = [asset tracksWithMediaType:AVMediaTypeAudio].firstObject;
            AVAssetTrack *videoTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
            
            
            CGAffineTransform t = videoTrack.preferredTransform;
            if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
                
                item.orientation = kCGImagePropertyOrientationRight;
                
            }else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
                item.orientation = kCGImagePropertyOrientationLeft;
                
            }else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
                
                item.orientation = kCGImagePropertyOrientationDown;
                
            }else {
                
                item.orientation = kCGImagePropertyOrientationUp;
            }
            
            AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
            
            CMTimeRange videoTimeRange = videoTrack.timeRange;
            [compositionVideoTrack insertTimeRange:videoTimeRange ofTrack:videoTrack atTime:kCMTimeZero error:nil];
            
            AVMutableCompositionTrack *compositionVoiceTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            [compositionVoiceTrack insertTimeRange:voiceTrack.timeRange ofTrack:voiceTrack atTime:kCMTimeZero error:nil];
            
            AVMutableAudioMixInputParameters *inputParameter =
            [AVMutableAudioMixInputParameters audioMixInputParameters];
            [inputParameter setTrackID:compositionVoiceTrack.trackID];
            
            [inputParameter setVolume:vf.volume atTime:kCMTimeZero];
            [inputParameters addObject:inputParameter];
            
            item.trackID = compositionVideoTrack.trackID;
            item.fillMode = 0;
            
            [sourceTrackIDs addObject:@(compositionVideoTrack.trackID)];
            
            CGImageRef cgImage = [[KCVideoHelper sharedHelper] copyImageWithFilePath:vf.URL atTime:CMTimeGetSeconds(videoTrack.timeRange.duration)];
            
            item.endImage = [CIImage imageWithCGImage:cgImage];
            
            
            
            CGImageRelease(cgImage);
            
            
        }else {
            item.fillMode = 1;
            item.trackID = 0;
        }
        
    }
    
    audioMix.inputParameters = inputParameters;
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoCompositionWithPropertiesOfAsset:composition];
    videoComposition.frameDuration = CMTimeMake(1, 20); // 30 fps
    videoComposition.renderSize = self.preferedVideoSize;
    
    videoComposition.customVideoCompositorClass = [KCVideoFuseCompositor class];
    
    KCVideoFuseCompositionInstruction *instruction = [[KCVideoFuseCompositionInstruction alloc] initWithRequiredSourceTrackIDs:sourceTrackIDs timeRange:CMTimeRangeMake(kCMTimeZero, composition.duration)];
    
    instruction.fuseCIFilter = self.fuseCIFilter;
    instruction.items = items;
    videoComposition.instructions = @[instruction];
    
    self.instruction = instruction;
    
    self.placeholderImage = self.placeholderImage;
    self.preferedVideoSize = self.preferedVideoSize;
    self.videoBorderColor = self.videoBorderColor;
    self.videoBorderWidth = self.videoBorderWidth;
    self.videoBgColor = self.videoBgColor;
    
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:composition];
    item.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithmSpectral;
    item.videoComposition = videoComposition;
    item.audioMix = audioMix;
    
    self.playerItem = item;
}

- (void)destoryPlayerResource
{
    self.instruction = nil;
    self.fuseCIFilter = nil;
    self.usageVideoFuses = nil;
}

@end
