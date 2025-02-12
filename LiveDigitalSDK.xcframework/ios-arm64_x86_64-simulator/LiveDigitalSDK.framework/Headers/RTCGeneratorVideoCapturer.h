#import <Foundation/Foundation.h>
#import <WebRTC/RTCVideoCapturer.h>


NS_ASSUME_NONNULL_BEGIN

@interface RTCGeneratorVideoCapturer: RTCVideoCapturer
- (void)startCapturingWithCompletionHandler:(nullable void (^)(NSError *_Nullable))completionHandler;
- (void)stopCapture;
@end

NS_ASSUME_NONNULL_END
