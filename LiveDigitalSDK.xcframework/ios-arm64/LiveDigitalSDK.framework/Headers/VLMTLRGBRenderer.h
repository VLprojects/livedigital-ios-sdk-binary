/*
 *  Copyright 2018 The WebRTC Project Authors. All rights reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import <Foundation/Foundation.h>

#if __has_include(<VLMTLRenderer.h>)
	#import <VLMTLRenderer.h>
#else
	#import <LiveDigitalSDK/VLMTLRenderer.h>
#endif


/// A Metal-based renderer for RGB and BGR pixel buffers.
///
/// `VLMTLRGBRenderer` renders video frames provided in common packed RGB formats,
/// including `kCVPixelFormatType_32BGRA` and `kCVPixelFormatType_32ARGB`.
///
/// This renderer is typically used when frames are already in an RGB-compatible
/// format (e.g., post-processed frames, screenshots, or custom pipelines),
/// avoiding the need for YUV conversion.
NS_AVAILABLE(10_11, 9_0)
@interface VLMTLRGBRenderer : VLMTLRenderer

@end
