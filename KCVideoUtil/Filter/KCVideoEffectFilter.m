//
//  KCVideoFilterGroup.m
//  KCVideoUtil
//
//  Created by Erica on 2018/11/20.
//  Copyright © 2018 Erica. All rights reserved.
//

#import "KCVideoEffectFilter.h"
#import "KCVideoStyle.h"

@interface KCVideoEffectFilter(){
    KCVideoEffectType _effectType;
}

@property (nonatomic,strong) GPUImageFilter *passFilter;

@property (nonatomic,strong) GPUImageBeautyFilter *beautyFilter;
@property (nonatomic,strong) GPUImageCropFilter *cropFilter;

@property (nonatomic,strong) GPUImageLookupFilter *lookupFilter;

@property (nonatomic,strong) GPUImageFilter *styleFilter;


@end

@implementation KCVideoEffectFilter


- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setEffectType:0];
    }
    return self;
}

- (GPUImageLookupFilter *)lookupFilter
{
    if (!_lookupFilter) {
        _lookupFilter = [[GPUImageLookupFilter alloc] init];
    }
    return _lookupFilter;
}

- (GPUImageFilter *)passFilter
{
    if (!_passFilter) {
        _passFilter = [[GPUImageFilter alloc] init];
        
    }
    return _passFilter;
}

- (GPUImageCropFilter *)cropFilter
{
    if (!_cropFilter) {
        _cropFilter = [[GPUImageCropFilter alloc] init];
        
    }
    return _cropFilter;
}

- (GPUImageBeautyFilter *)beautyFilter
{
    if (!_beautyFilter) {
        _beautyFilter = [[GPUImageBeautyFilter alloc] init];
        [_beautyFilter setBrightLevel:0.5];
        [_beautyFilter setToneLevel:0.5];
    }
    return _beautyFilter;
}

- (void)updateFilters
{
//    runSynchronouslyOnVideoProcessingQueue(^{
    
        [filters removeAllObjects];
        self.initialFilters = nil;
        self.terminalFilter = nil;
    
        if (_effectType == KCVideoEffectTypeNone) {
            
            [self appendFilter:self.passFilter];
            
        }else {
            
            if (_effectType & KCVideoEffectTypeCrop) {
                
                [self appendFilter:self.cropFilter];
            }
            
            if (_effectType & KCVideoEffectTypeBeauty) {
                
                [self appendFilter:self.beautyFilter];
                
            }
            
            
            if (_effectType & KCVideoEffectTypeStyle) {
                
                [self appendFilter:self.styleFilter];
            }
            
            
        }
        
//    });

   
}

- (void)setEffectType:(KCVideoEffectType)effectType
{
    _effectType = effectType;
    
    [self updateFilters];
    
}

- (void)appendFilter:(GPUImageOutput<GPUImageInput> *)filter
{
    if (!filter) {
        return;
    }
    
    [self addFilter:filter];
    
    GPUImageOutput<GPUImageInput> *newTerminalFilter = filter;
    
    NSInteger count = self.filterCount;
    
    if (count == 1)
    {
        self.initialFilters = @[newTerminalFilter];
        self.terminalFilter = newTerminalFilter;
        
    } else
    {
        GPUImageOutput<GPUImageInput> *terminalFilter    = self.terminalFilter;
        NSArray *initialFilters                          = self.initialFilters;
        
        [terminalFilter addTarget:newTerminalFilter];
        
        self.initialFilters = @[initialFilters[0]];
        self.terminalFilter = newTerminalFilter;
    }
    
}

- (void)setVideoStyle:(KCVideoStyle *)m
{
    if (m) {
        self.styleFilter = [self filterForVideoStyle:m];
    }else {
        self.styleFilter = nil;
    }
    
    [self updateFilters];
    
}

- (GPUImageFilter *)filterForVideoStyle:(KCVideoStyle *)videoStyle
{
    GPUImageFilter *filter = nil;
    switch (videoStyle.type) {
        case KCVideoStyleTypeLookup:{
            
            GPUImagePicture *lookup = [[GPUImagePicture alloc] initWithImage:videoStyle.lookup];
            GPUImageLookupFilter *lookupFilter = [[GPUImageLookupFilter alloc] init];
            lookupFilter.intensity = 1;
            
            [lookup addTarget:lookupFilter atTextureLocation:1];
            [lookup processImage];
            filter = lookupFilter;
            
        }
            
            break;
        case KCVideoStyleTypeContrast:
        {
            GPUImageContrastFilter *contrastFilter = [[GPUImageContrastFilter alloc] init];
            contrastFilter.contrast = 2;
            filter = contrastFilter;
        }
            break;
        case KCVideoStyleTypeSepia:
        {
            GPUImageSepiaFilter *sepiafilter = [[GPUImageSepiaFilter alloc] init];
            filter = sepiafilter;
        }
            break;
        case KCVideoStyleTypeGamma:
        {
            GPUImageGammaFilter *gammafilter = [[GPUImageGammaFilter alloc] init];
            gammafilter.gamma = 2;
            filter = gammafilter;
        }
            break;
        case KCVideoStyleTypeInvert:
        {
            GPUImageColorInvertFilter *invertfilter = [[GPUImageColorInvertFilter alloc] init];
            filter = invertfilter;
        }
            break;
        case KCVideoStyleTypeGreyScale:
        {
            GPUImageGrayscaleFilter *grayfilter = [[GPUImageGrayscaleFilter alloc] init];
            filter = grayfilter;
        }
            break;
        case KCVideoStyleTypeSobelEdgeDetection:
        {
            GPUImageSobelEdgeDetectionFilter *sefilter = [[GPUImageSobelEdgeDetectionFilter alloc] init];
            sefilter.edgeStrength = 1;
            filter = sefilter;
        }
            break;
        case KCVideoStyleTypeMonochrome:
        {
            GPUImageMonochromeFilter *sefilter = [[GPUImageMonochromeFilter alloc] init];
            sefilter.intensity = 1;
            GPUVector4 color = {0.6, 0.45, 0.3, 1.0};
            sefilter.color = color;
            filter = sefilter;
        }
            break;
        case KCVideoStyleTypeVignette:
        {
            GPUImageVignetteFilter *sefilter = [[GPUImageVignetteFilter alloc] init];
            sefilter.vignetteCenter = CGPointMake(0.5, 0.5);
            GPUVector3 color = {0, 0, 0};
            sefilter.vignetteColor = color;
            sefilter.vignetteStart = 0.3;
            sefilter.vignetteEnd = 0.75;
            
            filter = sefilter;
        }
            break;
        case KCVideoStyleTypeBlendDissolve:
        {
            GPUImagePicture *lookup = [[GPUImagePicture alloc] initWithImage:videoStyle.lookup];
            
            GPUImageDissolveBlendFilter *sefilter = [[GPUImageDissolveBlendFilter alloc] init];
            [lookup addTarget:sefilter atTextureLocation:1];
            [lookup processImage];
            filter = sefilter;
        }
            break;
            
        case KCVideoStyleTypeDilation:
        {
            GPUImageDilationFilter *sefilter = [[GPUImageDilationFilter alloc] init];
            filter = sefilter;
        }
            break;
        case KCVideoStyleTypeKuwahara:
        {
            GPUImageKuwaharaFilter *sefilter = [[GPUImageKuwaharaFilter alloc] init];
            filter = sefilter;
        }
            break;
        case KCVideoStyleTypeSketch:
        {
            GPUImageSketchFilter *sefilter = [[GPUImageSketchFilter alloc] init];
            filter = sefilter;
        }
            break;
        case KCVideoStyleTypeToon:
        {
            GPUImageToonFilter *sefilter = [[GPUImageToonFilter alloc] init];
            filter = sefilter;
        }
            break;
        case KCVideoStyleTypeSwirl:
        {
            GPUImageSwirlFilter *sefilter = [[GPUImageSwirlFilter alloc] init];
            filter = sefilter;
        }
            break;
        case KCVideoStyleTypeFalseColor:
        {
            GPUImageFalseColorFilter *sefilter = [[GPUImageFalseColorFilter alloc] init];
            filter = sefilter;
        }
            break;
            
        default:
            break;
    }
    
    return filter;
    
}


- (void)setBeauty:(CGFloat)strength
{
    [self.beautyFilter setBeautyLevel:strength];
}

- (void)setBasic:(CGFloat)strength
{
    
//#ifdef KC_USAGE_SENSETIME
//    [self.senseArFilter setSlimFace:strength];
//    [self.senseArFilter setBigEye:strength];
//#endif
//
//#ifdef KC_USAGE_AIYA
//    [self.aiyaFilter setSlimFace:strength];
//    [self.aiyaFilter setBigEye:strength];
//
//#endif
}

- (void)setStickers:(KCVideoStickers *)m
{
    
//#ifdef KC_USAGE_SENSETIME
//    //    [self.manager.processer setEffect:m];
//    [self.senseArFilter setEffect:m.extra];
//#endif
//
//#ifdef KC_USAGE_AIYA
//    //    [self.manager setEffectPath:m.path];
//    [self.aiyaFilter setEffect:m.path];
//#endif
    
}

- (void)setCropRegion:(CGRect)cropRegion
{
    self.cropFilter.cropRegion = cropRegion;
}

@end
