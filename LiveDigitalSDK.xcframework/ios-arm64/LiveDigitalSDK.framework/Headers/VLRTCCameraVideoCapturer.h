#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import <WebRTC/RTCMacros.h>
#import <WebRTC/RTCVideoCapturer.h>

@class UIWindowScene;

NS_ASSUME_NONNULL_BEGIN

RTC_OBJC_EXPORT

/// A camera-based video capturer built on top of `AVCaptureSession`.
///
/// `VLRTCCameraVideoCapturer` captures video frames from a device camera and
/// forwards them to a `RTCVideoCapturerDelegate` (typically an `RTCVideoSource`).
/// It bridges AVFoundation capture pipelines with the WebRTC video pipeline.
NS_EXTENSION_UNAVAILABLE_IOS("Camera not available in app extensions.")
@interface RTC_OBJC_TYPE (VLRTCCameraVideoCapturer) : RTC_OBJC_TYPE(RTCVideoCapturer)

/// Creates a camera video capturer.
///
/// - Parameters:
///   - delegate: The delegate that receives captured frames.
///   - scene: Optional scene used to select the appropriate capture environment (iOS 13+).
- (instancetype)initWithDelegate:(id<RTC_OBJC_TYPE(RTCVideoCapturerDelegate)>)delegate
	scene:(nullable UIWindowScene *)scene;

/// The underlying `AVCaptureSession` used for video capture.
///
/// This session is created during initialization and remains valid
/// for the lifetime of the capturer.
@property(readonly, nonatomic) AVCaptureSession *captureSession;

/// Returns the available capture devices that support video input.
+ (NSArray<AVCaptureDevice *> *)captureDevices;

/// Returns the supported capture formats for the specified device.
///
/// - Parameter device: The capture device.
/// - Returns: An array of supported formats.
+ (NSArray<AVCaptureDeviceFormat *> *)supportedFormatsForDevice:(AVCaptureDevice *)device;

/// Returns the preferred output pixel format for this capturer.
///
/// The returned format is optimized for efficient processing within the WebRTC pipeline.
- (FourCharCode)preferredOutputPixelFormat;

/// Starts the capture session asynchronously.
///
/// The device captures video using the specified format and frame rate.
/// If the format's pixel type is compatible with the WebRTC pipeline, it is
/// used directly; otherwise, the capturer falls back to `preferredOutputPixelFormat`.
///
/// - Parameters:
///   - device: The capture device.
///   - format: The capture format.
///   - fps: The desired frame rate.
///   - completionHandler: Called when capture starts or fails.
- (void)startCaptureWithDevice:(AVCaptureDevice *)device
	format:(AVCaptureDeviceFormat *)format
	fps:(NSInteger)fps
	completionHandler:(nullable void (^)(NSError *_Nullable))completionHandler;

/// Stops the capture session asynchronously.
///
/// - Parameter completionHandler: Called when capture has fully stopped.
- (void)stopCaptureWithCompletionHandler:(nullable void (^)(void))completionHandler;

/// Starts the capture session asynchronously without a completion callback.
- (void)startCaptureWithDevice:(AVCaptureDevice *)device
	format:(AVCaptureDeviceFormat *)format
	fps:(NSInteger)fps;

/// Stops the capture session asynchronously without a completion callback.
- (void)stopCapture;

@end

NS_ASSUME_NONNULL_END
