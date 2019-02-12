//
//  KCVideoFuseFilter.m
//  CoreImageDemo
//
//  Created by Erica on 2018/12/24.
//  Copyright © 2018 Erica. All rights reserved.
//

#import "KCVideoFuseCIFilter.h"
#import <AVFoundation/AVFoundation.h>


@implementation KCVideoFuseFilterInput

@end


@interface KCVideoFuseCIFilter()
@property (nonatomic,strong) NSMutableDictionary *kernels;
@property (nonatomic,strong) NSMutableDictionary *borderKernels;
@end

@implementation KCVideoFuseCIFilter

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        self.maxSize = 5000;
        self.kernels = @{}.mutableCopy;
        self.borderKernels = @{}.mutableCopy;
        
    }
    return self;
}

- (CIKernel *)kernelForCount:(int)count
{
    CIKernel *kernel = self.kernels[@(count)];
    
    if (!kernel) {
        kernel = [self kernelWithFuseCount:count];
        self.kernels[@(count)] = kernel;
    }
    return kernel;
}

- (CIKernel *)borderKernelForCount:(int)count
{
    CIKernel *borderKernel = self.borderKernels[@(count)];
    
    if (!borderKernel) {
        borderKernel = [self kernelBorderWithFuseCount:count];
        self.borderKernels[@(count)] = borderKernel;
    }
    return borderKernel;
}

- (CIImage *)outputImage
{
    
    return [self processKernel];
    
}

- (CIImage *)processKernel
{
    
    CGFloat width = self.preferedSize.width;
    CGFloat height = self.preferedSize.height;
    NSMutableArray *kernelArgs = @[].mutableCopy;
    NSMutableArray *borderKernelArgs = @[].mutableCopy;
    CGAffineTransform transform = CGAffineTransformConcat(CGAffineTransformMakeTranslation(0, -height), CGAffineTransformMakeScale(1, -1));
    
    for (KCVideoFuseFilterInput *input in self.inputs) {
        
        CGRect coordinate = input.coordinate;
        CGRect rect = CGRectMake(width * coordinate.origin.x, height * coordinate.origin.y, width * coordinate.size.width, height * coordinate.size.height);
        CIImage *image = input.image;
        image = [image imageByApplyingOrientation:input.orientation];
        
//        CGRect extent = image.extent;
        
        rect = CGRectApplyAffineTransform(rect, transform);
        CIVector *vectorRect = [CIVector vectorWithCGRect:rect];
//        CIVector *vectorExtent = [CIVector vectorWithCGRect:extent];
        NSNumber * mode = @(input.fillMode);
        
        [borderKernelArgs addObject:vectorRect];
        
        [kernelArgs addObjectsFromArray:@[image, vectorRect, mode]];
        
        
    }
    
    CIColor *bgColor = self.bgColor;
    if (!bgColor) {
        bgColor = [CIColor colorWithRed:0 green:0 blue:0];
    }
    
    [kernelArgs addObject:bgColor];
    
    NSInteger count = self.inputs.count;
    
    CIKernel *kernel = [self kernelForCount:count];
    
    CGRect maxRect = CGRectMake(0, 0, self.maxSize, self.maxSize);
    
    CIImage *outputImage = [kernel applyWithExtent:CGRectMake(0, 0, width, height) roiCallback:^CGRect(int index, CGRect destRect) {
        
        return maxRect;
        
    } arguments:kernelArgs];
    
    if (outputImage &&self.borderColor && self.borderWidth) {

        CIKernel *borderKernel = [self borderKernelForCount:count];

        [borderKernelArgs insertObject:self.borderColor atIndex:0];
        [borderKernelArgs insertObject:@(self.borderWidth) atIndex:0];
        [borderKernelArgs insertObject:outputImage atIndex:0];

        outputImage = [borderKernel applyWithExtent:outputImage.extent roiCallback:^CGRect(int index, CGRect destRect) {
            return destRect;
        } arguments:borderKernelArgs];

    }
    
    return outputImage;
    
}


#pragma mark - Fuse


- (CIKernel *)kernelWithFuseCount:(int)count {
    
    NSString *kernelCode = [self kernelCodeWithFuseCount:count];
    
    CIKernel *kernel = [CIKernel kernelsWithString:kernelCode].firstObject;
    
    
    return kernel;
}

- (NSString *)kernelCodeWithFuseCount:(int)count {
    NSMutableString *kernelStr = @"".mutableCopy;
    
    [kernelStr appendString:[self defineFunctionWithParamCount:count]];
    [kernelStr appendString:@"\n{\nvec2 dest = destCoord();\n"];
    
    for (int i = 0; i < count; i++) {
        [kernelStr appendString:[self codeBlock:[NSString stringWithFormat:@"image%d",i]
                                               :[NSString stringWithFormat:@"rect%d",i]
                                               :[NSString stringWithFormat:@"mode%d",i]
                                               ]];
    }
    
    [kernelStr appendString:@"\nreturn bgColor;\n}"];
    
    return kernelStr;
}

- (NSString *)codeBlock:(NSString *)param0 :(NSString *)param1 :(NSString *)param2 {
    NSMutableString *codeBlock = @"\nif (dest.x > _rect_.x && dest.y > _rect_.y && dest.x < _rect_.x + _rect_.z && dest.y < _rect_.y + _rect_.w) {\n\
    vec4 _extent_ = samplerExtent(_image_);\n\
    if (_mode_ == 0.0) {\n\
    \n\
    float ratio = _extent_.z / _extent_.w;\n\
    float ratioW = _rect_.z;\n\
    float ratioH = ratioW / ratio;\n\
    if (ratioH < _rect_.w) {\n\
    ratioH = _rect_.w;\n\
    ratioW = ratioH * ratio;\n\
    }\n\
    float scale = ratioW / _extent_.z;\n\
    \n\
    float offset_x = (ratioW - _rect_.z) * 0.5;\n\
    float offset_y = (ratioH - _rect_.w) * 0.5;\n\
    \n\
    float sample_x = (dest.x - _rect_.x + offset_x) / scale;\n\
    float sample_y = (dest.y - _rect_.y + offset_y) / scale;\n\
    \n\
    vec2 sample_point = vec2(sample_x + _extent_.x, sample_y + _extent_.y);\n\
    return sample(_image_, samplerTransform(_image_, sample_point));\n\
    \n\
    } else {\n\
    \n\
    float space_z = (_rect_.z - _extent_.z) * 0.5;\n\
    float space_w = (_rect_.w - _extent_.w) * 0.5;\n\
    float left = _rect_.x + space_z;\n\
    float right = _rect_.x + _rect_.z - space_z;\n\
    float top = _rect_.y + space_w;\n\
    float bottom =  _rect_.y + _rect_.w - space_w;\n\
    \n\
    if (dest.x > left && dest.x < right && dest.y > top && dest.y < bottom) {\n\
    vec2 point = vec2(dest.x - left, dest.y - top);\n\
    return sample(_image_, samplerTransform(_image_, point));\n\
    }\n\
    return bgColor;\n\
    }\n}\n".mutableCopy;
    codeBlock = [codeBlock stringByReplacingOccurrencesOfString:@"_image_" withString:param0].mutableCopy;
    codeBlock = [codeBlock stringByReplacingOccurrencesOfString:@"_rect_" withString:param1].mutableCopy;
//    codeBlock = [codeBlock stringByReplacingOccurrencesOfString:@"_extent_" withString:param2].mutableCopy;
    codeBlock = [codeBlock stringByReplacingOccurrencesOfString:@"_mode_" withString:param2].mutableCopy;
    return codeBlock;
}

- (NSString *)defineFunctionWithParamCount:(int)count {
    NSMutableArray *params = [NSMutableArray array];
    for (int i = 0; i < count; i++) {
        NSString *paramsStr = [NSString stringWithFormat:@"sampler image%d, vec4 rect%d, float mode%d",i,i,i];
        [params addObject:paramsStr];
    }
    [params addObject:@"__color bgColor"];
    NSString *paramsStr = [params componentsJoinedByString:@", "];
    NSString *defineStr = [NSString stringWithFormat:@"kernel vec4 KCvideoKernel(%@)",paramsStr];
    return defineStr;
}



#pragma mark - Fuse Border
- (CIKernel *)kernelBorderWithFuseCount:(int)count {
    NSString *kernelCode = [self kernelBorderCodeWithFuseCount:count];
    
    
    CIKernel *kernel = [CIKernel kernelsWithString:kernelCode].firstObject;
    
    
    return kernel;
}

- (NSString *)kernelBorderCodeWithFuseCount:(int)count {
    NSMutableString *kernelStr = @"".mutableCopy;
    
    [kernelStr appendString:[self defineBorderCodeFunctionWithParamCount:count]];
    [kernelStr appendString:@"\n{\n\
     vec2 dest = destCoord();\n\
     vec4 extentRect = samplerExtent(_image_);\n"];
    
    for (int i = 0; i < count; i++) {
        [kernelStr appendString:[self borderCodeBlock:[NSString stringWithFormat:@"borderRect%d",i]]];
    }
    
    [kernelStr appendString:@"\nreturn sample(_image_, samplerTransform(_image_, dest));\n}"];
    
    return kernelStr;
}

- (NSString *)borderCodeBlock:(NSString *)param0 {
    NSMutableString *codeBlock = @"\nif (dest.x > _borderRect_.x && dest.y > _borderRect_.y && dest.x < _borderRect_.x + _borderRect_.z && dest.y < _borderRect_.y + _borderRect_.w) {\n\
    float left = _borderRect_.x;\n\
    float right = _borderRect_.x + _borderRect_.z;\n\
    float top = _borderRect_.y;\n\
    float bottom =  _borderRect_.y + _borderRect_.w;\n\
    \n\
    float dif_left = left - dest.x;\n\
    float dif_right = right - dest.x;\n\
    float dif_top = top - dest.y;\n\
    float dif_bottom = bottom - dest.y;\n\
    \n\
    if (left == 0.0) {\n\
    dif_left = _borderW_;\n\
    } else if (dif_left < 0.0) {\n\
    dif_left = dif_left * -1.0;\n\
    }\n\
    if (right == extentRect.z) {\n\
    dif_right = _borderW_;\n\
    } else if (dif_right < 0.0) {\n\
    dif_right = dif_right * -1.0;\n\
    }\n\
    if (top == 0.0) {\n\
    dif_top = _borderW_;\n\
    } else if (dif_top < 0.0) {\n\
    dif_top = dif_top * -1.0;\n\
    }\n\
    if (bottom == extentRect.w) {\n\
    dif_bottom = _borderW_;\n\
    } else if (dif_bottom < 0.0) {\n\
    dif_bottom = dif_bottom * -1.0;\n\
    }\n\
    float borderW_r = _borderW_ * 0.5;\n\
    if (dif_left < borderW_r || dif_right < borderW_r || dif_top < borderW_r || dif_bottom < borderW_r) {\n\
    return _borderColor_;\n\
    }\n\
    }".mutableCopy;
    codeBlock = [codeBlock stringByReplacingOccurrencesOfString:@"_borderRect_" withString:param0].mutableCopy;
    return codeBlock;
}

- (NSString *)defineBorderCodeFunctionWithParamCount:(int)count {
    NSMutableArray *params = [NSMutableArray arrayWithObjects:@"sampler _image_", @"float _borderW_", @"__color _borderColor_", nil];
    for (int i = 0; i < count; i++) {
        [params addObject:[NSString stringWithFormat:@"vec4 borderRect%d",i]];
    }
    NSString *paramsStr = [params componentsJoinedByString:@", "];
    NSString *defineStr = [NSString stringWithFormat:@"kernel vec4 KCvideoBorderKernel(%@)",paramsStr];
    return defineStr;
}


@end
