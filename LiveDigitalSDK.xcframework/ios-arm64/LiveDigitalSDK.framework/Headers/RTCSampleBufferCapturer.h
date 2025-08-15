#import <Foundation/Foundation.h>
#import <WebRTC/RTCVideoCapturer.h>


NS_ASSUME_NONNULL_BEGIN

@interface RTCSampleBufferCapturer : RTCVideoCapturer
- (void)didCaptureSampleBuffer:(CMSampleBufferRef)sampleBuffer rotation:(NSInteger)angle;
@end

NS_ASSUME_NONNULL_END
