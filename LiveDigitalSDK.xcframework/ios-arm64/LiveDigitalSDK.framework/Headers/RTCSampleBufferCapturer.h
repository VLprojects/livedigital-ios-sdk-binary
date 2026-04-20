#import <Foundation/Foundation.h>
#import <WebRTC/RTCVideoCapturer.h>


NS_ASSUME_NONNULL_BEGIN

/// A video capturer that forwards externally provided CMSampleBuffer frames into WebRTC.
///
/// `RTCSampleBufferCapturer` is intended for use cases where video frames are produced
/// outside of WebRTC (e.g., ReplayKit screen capture, custom pipelines) and need to be
/// injected into the WebRTC video pipeline.
@interface RTCSampleBufferCapturer : RTCVideoCapturer

/// Delivers a captured sample buffer to the WebRTC pipeline.
///
/// - Parameters:
///   - sampleBuffer: The captured video frame as a CMSampleBuffer.
///   - angle: The rotation angle (in degrees) to apply to the frame.
- (void)didCaptureSampleBuffer:(CMSampleBufferRef)sampleBuffer rotation:(NSInteger)angle;

@end

NS_ASSUME_NONNULL_END
