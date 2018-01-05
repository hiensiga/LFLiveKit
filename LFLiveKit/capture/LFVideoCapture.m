//
//  LFVideoCapture.m
//  LFLiveKit
//
//  Created by LaiFeng on 16/5/20.
//  Copyright © 2016年 LaiFeng All rights reserved.
//

#import "LFVideoCapture.h"
#import "LFGPUImageEmptyFilter.h"
#import "RKGPUImageColorFilter.h"
#import "RKGPUImageWarmFilter.h"
#import "RKGPUImageSoftFilter.h"
#import "RKGPUImageRoseFilter.h"
#import "RKGPUImageMorningFilter.h"
#import "RKGPUImageSunshineFilter.h"
#import "RKGPUImageSunsetFilter.h"
#import "RKGPUImageCoolFilter.h"
#import "RKGPUImageFreezeFilter.h"
#import "RKGPUImageOceanFilter.h"
#import "RKGPUImageDreamFilter.h"
#import "RKGPUImageVioletFilter.h"
#import "RKGPUImageMellowFilter.h"
#import "RKGPUImageMemoryFilter.h"
#import "RKGPUImagePureFilter.h"
#import "RKGPUImageCalmFilter.h"
#import "RKGPUImageAutumnFilter.h"
#import "RKGPUImageFantasyFilter.h"
#import "RKGPUImageFreedomFilter.h"
#import "RKGPUImageMildFilter.h"
#import "RKGPUImagePrairieFilter.h"
#import "RKGPUImageDeepFilter.h"
#import "RKGPUImageGlowFilter.h"
#import "RKGPUImageMistFilter.h"
#import "RKGPUImageVividFilter.h"
#import "RKGPUImagePinkyFilter.h"
#import "RKGPUImageAdventureFilter.h"

#import "RKGPUImageBeautyFilter.h"
#import "GPUImageSharpenFilter.h"
#import "GPUImageWhiteBalanceFilter.h"
#import "GPUImageContrastFilter.h"
#import "RKGPULogWhiteFilter.h"

#import <Vision/Vision.h>

#if __has_include(<GPUImage/GPUImage.h>)
#import <GPUImage/GPUImage.h>
#elif __has_include("GPUImage/GPUImage.h")
#import "GPUImage/GPUImage.h"
#else
#import "GPUImage.h"
#endif

static NSString * const kColorFilterTypeKey = @"type";
static NSString * const kColorFilterNameKey = @"name";
static NSString * const kColorFilterColorMapKey = @"colorMap";
static NSString * const kColorFilterSoftLightKey = @"softLight";
static NSString * const kColorFilterOverlayKey = @"overlay";

@interface LFVideoCapture () <GPUImageVideoCameraDelegate>

@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
@property (nonatomic, strong) GPUImageOutput<GPUImageInput> *filter;
@property (nonatomic, strong) GPUImageCropFilter *cropfilter;
@property (nonatomic, strong) GPUImageOutput<GPUImageInput> *output;
@property (nonatomic, strong) GPUImageView *gpuImageView;
@property (nonatomic, strong) LFLiveVideoConfiguration *configuration;

@property (nonatomic, strong) GPUImageAlphaBlendFilter *blendFilter;
@property (nonatomic, strong) GPUImageUIElement *uiElementInput;
@property (nonatomic, strong) UIView *waterMarkContentView;

@property (nonatomic, strong) GPUImageMovieWriter *movieWriter;

@property (nonatomic, assign) NSInteger currentColorFilterIndex;

@property (nonatomic, copy, readonly) NSArray<RKGPUImageColorFilter *> *colorFilters;

@property (nonatomic, strong) RKGPUImageColorFilter *colorFilter;

@property (nonatomic, strong) RKGPUImageBeautyFilter *beautyFilter;
@property (nonatomic, strong) GPUImageSharpenFilter *sharpenFilter;
@property (strong, nonatomic) GPUImageWhiteBalanceFilter *whiteBalanceFilter;
@property (strong, nonatomic) GPUImageContrastFilter *contrastFilter;
@property (strong, nonatomic) RKGPULogWhiteFilter *logWhiteFilter;

@property (strong, nonatomic) VNDetectFaceRectanglesRequest *faceRectRequest;
@property (strong, nonatomic) VNDetectFaceLandmarksRequest *faceMarkRequest;
@property (strong, nonatomic) VNSequenceRequestHandler *faceRectHandler;
@property (strong, nonatomic) VNSequenceRequestHandler *faceMarkHandler;

@end

@implementation LFVideoCapture
@synthesize torch = _torch;
@synthesize beautyLevel = _beautyLevel;
@synthesize brightLevel = _brightLevel;
@synthesize zoomScale = _zoomScale;

#pragma mark -- LifeCycle
- (instancetype)initWithVideoConfiguration:(LFLiveVideoConfiguration *)configuration {
    if (self = [super init]) {
        _currentColorFilterIndex = 0;
        _colorFilters = @[[[RKGPUImageColorFilter alloc] init],
                          [[RKGPUImageWarmFilter alloc] init],
                          [[RKGPUImageSoftFilter alloc] init],
                          [[RKGPUImageRoseFilter alloc] init],
                          [[RKGPUImageMorningFilter alloc] init],
                          [[RKGPUImageSunshineFilter alloc] init],
                          [[RKGPUImageSunsetFilter alloc] init],
                          [[RKGPUImageCoolFilter alloc] init],
                          [[RKGPUImageFreezeFilter alloc] init],
                          [[RKGPUImageOceanFilter alloc] init],
                          [[RKGPUImageDreamFilter alloc] init],
                          [[RKGPUImageVioletFilter alloc] init],
                          [[RKGPUImageMellowFilter alloc] init],
                          [[RKGPUImageMemoryFilter alloc] init],
                          [[RKGPUImagePureFilter alloc] init],
                          [[RKGPUImageCalmFilter alloc] init],
                          [[RKGPUImageAutumnFilter alloc] init],
                          [[RKGPUImageFantasyFilter alloc] init],
                          [[RKGPUImageFreedomFilter alloc] init],
                          [[RKGPUImageMildFilter alloc] init],
                          [[RKGPUImagePrairieFilter alloc] init],
                          [[RKGPUImageDeepFilter alloc] init],
                          [[RKGPUImageGlowFilter alloc] init],
                          [[RKGPUImageMistFilter alloc] init],
                          [[RKGPUImageVividFilter alloc] init],
                          [[RKGPUImagePinkyFilter alloc] init],
                          [[RKGPUImageAdventureFilter alloc] init]
                          ];
        _configuration = configuration;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterBackground:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarChanged:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
        
        self.beautyFace = YES;
        self.beautyLevel = 0.5;
        self.brightLevel = 0.5;
        self.zoomScale = 1.0;
        self.mirror = YES;
    }
    return self;
}

- (void)dealloc {
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_videoCamera stopCameraCapture];
    if(_gpuImageView){
        [_gpuImageView removeFromSuperview];
        _gpuImageView = nil;
    }
}

#pragma mark -- Public

- (void)previousColorFilter {
    self.currentColorFilterIndex--;
    [self reloadFilter];
}

- (void)nextColorFilter {
    self.currentColorFilterIndex++;
    [self reloadFilter];
}

#pragma mark -- Setter Getter

- (NSString *)currentColorFilterName {
    return self.colorFilter.localizedName;
}

- (void)setCurrentColorFilterIndex:(NSInteger)currentColorFilterIndex {
    if (currentColorFilterIndex < 0) {
        currentColorFilterIndex = self.colorFilters.count - 1;
        
    } else if (currentColorFilterIndex >= self.colorFilters.count) {
        currentColorFilterIndex = 0;
    }
    
    _currentColorFilterIndex = currentColorFilterIndex;
}

- (GPUImageVideoCamera *)videoCamera{
    if(!_videoCamera){
        _videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:_configuration.avSessionPreset cameraPosition:AVCaptureDevicePositionFront];
        _videoCamera.outputImageOrientation = _configuration.outputImageOrientation;
        _videoCamera.horizontallyMirrorFrontFacingCamera = NO;
        _videoCamera.horizontallyMirrorRearFacingCamera = NO;
        _videoCamera.frameRate = (int32_t)_configuration.videoFrameRate;
        //_videoCamera.delegate = self;
    }
    return _videoCamera;
}

- (void)setRunning:(BOOL)running {
    if (_running == running) return;
    _running = running;
    
    if (!_running) {
        [UIApplication sharedApplication].idleTimerDisabled = NO;
        [self.videoCamera stopCameraCapture];
        if(self.saveLocalVideo) [self.movieWriter finishRecording];
    } else {
        [UIApplication sharedApplication].idleTimerDisabled = YES;
        [self reloadFilter];
        [self.videoCamera startCameraCapture];
        if(self.saveLocalVideo) [self.movieWriter startRecording];
    }
}

- (void)setPreView:(UIView *)preView {
    if (self.gpuImageView.superview) {
        [self.gpuImageView removeFromSuperview];
    }
    [preView insertSubview:self.gpuImageView atIndex:0];
    self.gpuImageView.frame = CGRectMake(0, 0, preView.frame.size.width, preView.frame.size.height);
    
    [self reloadFilter];
}

- (UIView *)preView {
    return self.gpuImageView.superview;
}

- (void)setCaptureDevicePosition:(AVCaptureDevicePosition)captureDevicePosition {
    if(captureDevicePosition == self.videoCamera.cameraPosition) return;
    [self.videoCamera rotateCamera];
    self.videoCamera.frameRate = (int32_t)_configuration.videoFrameRate;
    [self reloadMirror];
}

- (AVCaptureDevicePosition)captureDevicePosition {
    return [self.videoCamera cameraPosition];
}

- (void)setVideoFrameRate:(NSInteger)videoFrameRate {
    if (videoFrameRate <= 0) return;
    if (videoFrameRate == self.videoCamera.frameRate) return;
    self.videoCamera.frameRate = (uint32_t)videoFrameRate;
}

- (NSInteger)videoFrameRate {
    return self.videoCamera.frameRate;
}

- (void)setTorch:(BOOL)torch {
    BOOL ret;
    if (!self.videoCamera.captureSession) return;
    AVCaptureSession *session = (AVCaptureSession *)self.videoCamera.captureSession;
    [session beginConfiguration];
    if (self.videoCamera.inputCamera) {
        if (self.videoCamera.inputCamera.torchAvailable) {
            NSError *err = nil;
            if ([self.videoCamera.inputCamera lockForConfiguration:&err]) {
                [self.videoCamera.inputCamera setTorchMode:(torch ? AVCaptureTorchModeOn : AVCaptureTorchModeOff) ];
                [self.videoCamera.inputCamera unlockForConfiguration];
                ret = (self.videoCamera.inputCamera.torchMode == AVCaptureTorchModeOn);
            } else {
                NSLog(@"Error while locking device for torch: %@", err);
                ret = false;
            }
        } else {
            NSLog(@"Torch not available in current camera input");
        }
    }
    [session commitConfiguration];
    _torch = ret;
}

- (BOOL)torch {
    return self.videoCamera.inputCamera.torchMode;
}

- (void)setMirror:(BOOL)mirror {
    _mirror = mirror;
}

- (void)setMirrorOutput:(BOOL)mirrorOutput {
    _mirrorOutput = mirrorOutput;
    [self reloadFilter];
}

- (void)setBeautyFace:(BOOL)beautyFace{
    _beautyFace = beautyFace;
    [self reloadFilter];
}

- (void)setBeautyLevel:(CGFloat)beautyLevel {
    _beautyLevel = beautyLevel;
    if (self.beautyFilter) {
//        [self.beautyFilter setBeautyLevel:_beautyLevel];
    }
}

- (CGFloat)beautyLevel {
    return _beautyLevel;
}

- (void)setBrightLevel:(CGFloat)brightLevel {
    _brightLevel = brightLevel;
    if (self.beautyFilter) {
//        [self.beautyFilter setBrightLevel:brightLevel];
    }
}

- (CGFloat)brightLevel {
    return _brightLevel;
}

- (void)setZoomScale:(CGFloat)zoomScale {
    if (self.videoCamera && self.videoCamera.inputCamera) {
        AVCaptureDevice *device = (AVCaptureDevice *)self.videoCamera.inputCamera;
        if ([device lockForConfiguration:nil]) {
            device.videoZoomFactor = zoomScale;
            [device unlockForConfiguration];
            _zoomScale = zoomScale;
        }
    }
}

- (CGFloat)zoomScale {
    return _zoomScale;
}

- (void)setWarterMarkView:(UIView *)warterMarkView{
    if(_warterMarkView && _warterMarkView.superview){
        [_warterMarkView removeFromSuperview];
        _warterMarkView = nil;
    }
    _warterMarkView = warterMarkView;
    self.blendFilter.mix = warterMarkView.alpha;
    [self.waterMarkContentView addSubview:_warterMarkView];
    [self reloadFilter];
}

- (GPUImageUIElement *)uiElementInput{
    if(!_uiElementInput){
        _uiElementInput = [[GPUImageUIElement alloc] initWithView:self.waterMarkContentView];
    }
    return _uiElementInput;
}

- (GPUImageAlphaBlendFilter *)blendFilter{
    if(!_blendFilter){
        _blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
        _blendFilter.mix = 1.0;
        [_blendFilter disableSecondFrameCheck];
    }
    return _blendFilter;
}

- (UIView *)waterMarkContentView{
    if(!_waterMarkContentView){
        _waterMarkContentView = [UIView new];
        _waterMarkContentView.frame = CGRectMake(0, 0, self.configuration.videoSize.width, self.configuration.videoSize.height);
        _waterMarkContentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _waterMarkContentView;
}

- (GPUImageView *)gpuImageView{
    if(!_gpuImageView){
        _gpuImageView = [[GPUImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        [_gpuImageView setFillMode:kGPUImageFillModePreserveAspectRatioAndFill];
        [_gpuImageView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    }
    return _gpuImageView;
}

-(UIImage *)currentImage{
    if(_filter){
        [_filter useNextFrameForImageCapture];
        return _filter.imageFromCurrentFramebuffer;
    }
    return nil;
}

- (GPUImageMovieWriter*)movieWriter{
    if(!_movieWriter){
        _movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:self.saveLocalVideoPath size:self.configuration.videoSize];
        _movieWriter.encodingLiveVideo = YES;
        _movieWriter.shouldPassthroughAudio = YES;
        self.videoCamera.audioEncodingTarget = self.movieWriter;
    }
    return _movieWriter;
}

#pragma mark -- Custom Method

- (void)reloadFilter{
    [self.filter removeAllTargets];
    [self.blendFilter removeAllTargets];
    [self.uiElementInput removeAllTargets];
    [self.videoCamera removeAllTargets];
    [self.output removeAllTargets];
    [self.cropfilter removeAllTargets];
    [self.colorFilter removeAllTargets];
    [self.beautyFilter removeAllTargets];
    [self.contrastFilter removeAllTargets];
    [self.whiteBalanceFilter removeAllTargets];
    [self.sharpenFilter removeAllTargets];
    [self.logWhiteFilter removeAllTargets];
    
    _blendFilter = nil;
    _uiElementInput = nil;
    self.beautyFilter = nil;
    self.sharpenFilter = nil;
    self.whiteBalanceFilter = nil;
    self.contrastFilter = nil;
    self.logWhiteFilter = nil;
    
    self.output = [[LFGPUImageEmptyFilter alloc] init];
    GPUImageFilterGroup *filterGroup = [[GPUImageFilterGroup alloc] init];
    
    self.colorFilter = self.colorFilters[self.currentColorFilterIndex];

    self.filter = filterGroup;

    // 美肌
    if (self.beautyFace) {
        [self applyBeautyFilters:filterGroup];
    } else {
        [self applyNormalFilters:filterGroup];
    }
    
    ///< 调节镜像
    [self reloadMirror];
    
    //< 480*640 比例为4:3  强制转换为16:9
    if([self.configuration.avSessionPreset isEqualToString:AVCaptureSessionPreset640x480]){
        CGRect cropRect = self.configuration.landscape ? CGRectMake(0, 0.125, 1, 0.75) : CGRectMake(0.125, 0, 0.75, 1);
        self.cropfilter = [[GPUImageCropFilter alloc] initWithCropRegion:cropRect];
        [self.videoCamera addTarget:self.cropfilter];
        [self.cropfilter addTarget:self.filter];
    }else{
        [self.videoCamera addTarget:self.filter];
    }
    
    //< 添加水印
    if(self.warterMarkView){
        [self.filter addTarget:self.blendFilter];
        [self.uiElementInput addTarget:self.blendFilter];
        if (self.preView) {
            [self.blendFilter addTarget:self.gpuImageView];
        }
        if(self.saveLocalVideo) [self.blendFilter addTarget:self.movieWriter];
        [self.filter addTarget:self.output];
        [self.uiElementInput update];
    }else{
        [self.filter addTarget:self.output];
        if (self.preView) {
            [self.filter addTarget:self.gpuImageView];
        } else {
            [self.output addTarget:[[LFGPUImageEmptyFilter alloc] init]];
        }
        if(self.saveLocalVideo) [self.output addTarget:self.movieWriter];
    }
    
    [self.filter forceProcessingAtSize:self.configuration.videoSize];
    [self.output forceProcessingAtSize:self.configuration.videoSize];
    [self.blendFilter forceProcessingAtSize:self.configuration.videoSize];
    [self.uiElementInput forceProcessingAtSize:self.configuration.videoSize];
    
    //< 输出数据
    __weak typeof(self) _self = self;
    [self.output setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
        glFlush();
        [_self processVideo:output];
    }];
    
}

- (void)processVideo:(GPUImageOutput *)output {
    __weak typeof(self) _self = self;
    @autoreleasepool {
        GPUImageFramebuffer *imageFramebuffer = output.framebufferForOutput;
        CVPixelBufferRef pixelBuffer = [imageFramebuffer pixelBuffer];
        if (pixelBuffer && _self.delegate && [_self.delegate respondsToSelector:@selector(captureOutput:pixelBuffer:)]) {
            [_self.delegate captureOutput:_self pixelBuffer:pixelBuffer];
        }
    }
}

- (void)applyBeautyFilters:(GPUImageFilterGroup *)filterGroup {
    self.logWhiteFilter = [[RKGPULogWhiteFilter alloc] init];
    [self.logWhiteFilter setBeta:4.0];
    
    self.beautyFilter = [[RKGPUImageBeautyFilter alloc] init];
    
    self.sharpenFilter = [[GPUImageSharpenFilter alloc] init];
    self.sharpenFilter.sharpness = 0.5;
    
    self.whiteBalanceFilter = [[GPUImageWhiteBalanceFilter alloc] init];
    self.whiteBalanceFilter.temperature = 4700;
    
    [filterGroup setInitialFilters:@[self.beautyFilter]];
    [filterGroup addFilter:self.beautyFilter];
    
    [self.beautyFilter addTarget:self.sharpenFilter];
    [filterGroup addFilter:self.sharpenFilter];
    
    [self.sharpenFilter addTarget:self.whiteBalanceFilter];
    [filterGroup addFilter:self.whiteBalanceFilter];
    
    [self.whiteBalanceFilter addTarget:self.logWhiteFilter];
    [filterGroup addFilter:self.logWhiteFilter];
    
    [self.logWhiteFilter addTarget:self.colorFilter];
    [filterGroup addFilter:self.colorFilter];
    [filterGroup setTerminalFilter:self.colorFilter];
}

- (void)applyNormalFilters:(GPUImageFilterGroup *)filterGroup {
    [filterGroup setInitialFilters:@[self.colorFilter]];
    [filterGroup addFilter:self.colorFilter];
    [filterGroup setTerminalFilter:self.colorFilter];
}

- (void)reloadMirror {
    [self.gpuImageView setInputRotation:(self.mirror && self.captureDevicePosition == AVCaptureDevicePositionFront) ? kGPUImageFlipHorizonal : kGPUImageNoRotation atIndex:0];
    
    [self.output setInputRotation:(self.mirrorOutput && self.captureDevicePosition == AVCaptureDevicePositionFront) ? kGPUImageFlipHorizonal : kGPUImageNoRotation atIndex:0];
}

#pragma mark Notification

- (void)willEnterBackground:(NSNotification *)notification {
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [self.videoCamera pauseCameraCapture];
    runSynchronouslyOnVideoProcessingQueue(^{
        glFinish();
    });
}

- (void)willEnterForeground:(NSNotification *)notification {
    [self.videoCamera resumeCameraCapture];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}

- (void)statusBarChanged:(NSNotification *)notification {
    NSLog(@"UIApplicationWillChangeStatusBarOrientationNotification. UserInfo: %@", notification.userInfo);
    UIInterfaceOrientation statusBar = [[UIApplication sharedApplication] statusBarOrientation];

    if(self.configuration.autorotate){
        if (self.configuration.landscape) {
            if (statusBar == UIInterfaceOrientationLandscapeLeft) {
                self.videoCamera.outputImageOrientation = UIInterfaceOrientationLandscapeRight;
            } else if (statusBar == UIInterfaceOrientationLandscapeRight) {
                self.videoCamera.outputImageOrientation = UIInterfaceOrientationLandscapeLeft;
            }
        } else {
            if (statusBar == UIInterfaceOrientationPortrait) {
                self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortraitUpsideDown;
            } else if (statusBar == UIInterfaceOrientationPortraitUpsideDown) {
                self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
            }
        }
    }
}

#pragma mark - GPUImageVideoCamera Delegate

- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (@available(iOS 11.0, *)) {
        [self processFacialBeauty:sampleBuffer];
    }
}

- (void)processFacialBeauty:(CMSampleBufferRef)sampleBuffer {
    NSTimeInterval start = CACurrentMediaTime();
    if (!_faceRectRequest) {
        _faceRectRequest = [[VNDetectFaceRectanglesRequest alloc] init];
        _faceMarkRequest = [[VNDetectFaceLandmarksRequest alloc] init];
        _faceRectHandler = [[VNSequenceRequestHandler alloc] init];
        _faceMarkHandler = [[VNSequenceRequestHandler alloc] init];
    }
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    NSError *error;
    [_faceRectHandler performRequests:@[_faceRectRequest] onCVPixelBuffer:pixelBuffer orientation:kCGImagePropertyOrientationLeftMirrored error:&error];
    if (error) {
        NSLog(@"face rect detection error = %@", error);
        return;
    }
    if (_faceRectRequest.results.count == 0) {
        return;
    }
    _faceMarkRequest.inputFaceObservations = _faceRectRequest.results;
    
    [_faceMarkHandler performRequests:@[_faceMarkRequest] onCVPixelBuffer:pixelBuffer orientation:kCGImagePropertyOrientationLeftMirrored error:&error];
    if (error) {
        NSLog(@"face mark detection error = %@", error);
        return;
    }
    //for (int i = 0; i < _faceMarkRequest.results.count; i++) {
    for (VNFaceObservation *obv in _faceMarkRequest.results) {
//        CGRect boundingBox = _faceMarkRequest.inputFaceObservations[i].boundingBox;
//        VNFaceObservation *obv = _faceMarkRequest.results[i];
        VNFaceLandmarkRegion2D *leftEye = obv.landmarks.leftEye;
//        _eyeFilter.leftEyePosition = [self centerOfPoints:leftEye.normalizedPoints count:leftEye.pointCount];
        VNFaceLandmarkRegion2D *rightEye = obv.landmarks.rightEye;
//        _eyeFilter.rightEyePosition = [self centerOfPoints:rightEye.normalizedPoints count:rightEye.pointCount];
    }
    NSLog(@"facial features take %f sec", CACurrentMediaTime() - start);
}

- (CGPoint)centerOfPoints:(CGPoint *)points count:(NSUInteger)count {
    CGFloat x = 0, y = 0;
    for (int i = 0; i < count; i++) {
        x += points[i].x;
        y += points[i].y;
    }
    return CGPointMake(x / count, y / count);
}

@end
