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
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

#import <WebRTC/RTCVideoFrame.h>

NS_ASSUME_NONNULL_BEGIN

/// A protocol for rendering `RTCVideoFrame` instances into Metal-backed views.
///
/// Types conforming to `VLMTLRenderer` receive video frames from the WebRTC
/// pipeline and render them into one or more destination views.
@protocol VLMTLRenderer <NSObject>

/// Indicates whether the rendered video is mirrored horizontally.
@property(nonatomic) BOOL mirrored;

/// Indicates whether the rendered video is mirrored vertically.
@property(nonatomic) BOOL verticallyMirrored;

/// Renders the provided video frame.
///
/// - Parameter frame: The frame to render.
- (void)drawFrame:(RTC_OBJC_TYPE(RTCVideoFrame) *)frame;

/// Adds a view as a rendering destination, if supported.
///
/// - Parameter view: The view that should receive rendered video output.
/// - Returns: `YES` if the view was accepted as a rendering destination;
///   otherwise `NO`. If the method returns `NO`, the caller is responsible
///   for any required cleanup.

#if TARGET_OS_IOS
- (BOOL)addRenderingDestination:(__kindof UIView *)view;
#else
- (BOOL)addRenderingDestination:(__kindof NSView *)view;
#endif

@end

/// Default Metal-backed implementation of the `VLMTLRenderer` protocol.
NS_AVAILABLE(10_11, 9_0)
@interface VLMTLRenderer : NSObject <VLMTLRenderer>

/// An optional wrapped `RTCVideoRotation` value that overrides frame rotation.
///
/// When set, the renderer ignores the rotation metadata carried by incoming
/// frames and uses this value instead.
@property(atomic, nullable) NSValue *rotationOverride;

@end

NS_ASSUME_NONNULL_END
