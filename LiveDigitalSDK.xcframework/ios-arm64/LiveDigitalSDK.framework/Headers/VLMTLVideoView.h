/*
 *  Copyright 2017 The WebRTC project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import <Foundation/Foundation.h>

#import <WebRTC/RTCMacros.h>
#import <WebRTC/RTCVideoFrame.h>
#import <WebRTC/RTCVideoRenderer.h>

NS_ASSUME_NONNULL_BEGIN

/// A Metal-backed video view for rendering WebRTC frames.
///
/// `VLMTLVideoView` is a lightweight `UIView` wrapper around an internal
/// Metal rendering surface. It conforms to `RTCVideoRenderer`, allowing it
/// to receive and display WebRTC video frames directly.
///
/// The view supports common rendering options such as content mode,
/// enable/disable state, mirroring, vertical flipping, and rotation override.
NS_CLASS_AVAILABLE_IOS(9)
RTC_OBJC_EXPORT
@interface RTC_OBJC_TYPE (VLMTLVideoView) : UIView<RTC_OBJC_TYPE(RTCVideoRenderer)>

/// The delegate notified about view-related rendering updates.
@property(nonatomic, weak) id<RTC_OBJC_TYPE(RTCVideoViewDelegate)> delegate;

/// The content mode used to lay out the rendered video within the view bounds.
@property(nonatomic) UIViewContentMode videoContentMode;

/// Indicates whether the view is actively rendering video frames.
@property(nonatomic, getter=isEnabled) BOOL enabled;

/// Indicates whether the rendered video is mirrored horizontally.
@property(nonatomic) BOOL mirrored;

/// Indicates whether the rendered video is mirrored vertically.
@property(nonatomic) BOOL verticallyMirrored;

/// An optional wrapped `RTCVideoRotation` value that overrides frame rotation.
@property(nonatomic, nullable) NSValue* rotationOverride;

/// Returns the size of the last rendered frame after rotation has been applied.
- (CGSize)drawableSize;

@end

NS_ASSUME_NONNULL_END
