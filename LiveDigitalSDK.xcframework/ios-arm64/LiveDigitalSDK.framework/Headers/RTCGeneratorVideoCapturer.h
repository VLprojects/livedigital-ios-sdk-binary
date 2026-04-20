#import <Foundation/Foundation.h>
#import <WebRTC/RTCVideoCapturer.h>


NS_ASSUME_NONNULL_BEGIN

/// A video capturer that generates frames programmatically instead of using a physical camera.
///
/// `RTCGeneratorVideoCapturer` is used for testing scenarios where video frames are generated
/// by the application in runtime and need to be fed into the WebRTC pipeline.
@interface RTCGeneratorVideoCapturer: RTCVideoCapturer

/// Starts the capture process.
///
/// - Parameter completionHandler: A block invoked when capture starts,
///   providing an error if the operation fails.
- (void)startCapturingWithCompletionHandler:(nullable void (^)(NSError *_Nullable))completionHandler;

/// Stops the capture process and releases any associated resources.
- (void)stopCapture;

@end

NS_ASSUME_NONNULL_END
