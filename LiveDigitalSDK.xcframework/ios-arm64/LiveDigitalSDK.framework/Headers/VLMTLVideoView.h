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

/**
 * VLMTLVideoView is thin wrapper around MTKView.
 *
 * It has id<RTCVideoRenderer> property that renders video frames in the view's
 * bounds using Metal.
 */
NS_CLASS_AVAILABLE_IOS(9)

RTC_OBJC_EXPORT
@interface RTC_OBJC_TYPE (VLMTLVideoView) : UIView<RTC_OBJC_TYPE(RTCVideoRenderer)>

@property(nonatomic, weak) id<RTC_OBJC_TYPE(RTCVideoViewDelegate)> delegate;

@property(nonatomic) UIViewContentMode videoContentMode;

/** @abstract Enables/disables rendering.
 */
@property(nonatomic, getter=isEnabled) BOOL enabled;

/** @abstract Enables/disables video mirroring across X axis.
 */
@property(nonatomic) BOOL mirrored;

/** @abstract Wrapped RTCVideoRotation, or nil.
 */
@property(nonatomic, nullable) NSValue* rotationOverride;

/** @abstract Size of last rendered frame with rotation applied.
 */
- (CGSize)drawableSize;

@end

NS_ASSUME_NONNULL_END
