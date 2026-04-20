/*
 *  Copyright 2017 The WebRTC Project Authors. All rights reserved.
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


/// A Metal-based renderer optimized for NV12 (bi-planar YUV) pixel buffers.
///
/// `VLMTLNV12Renderer` renders video frames in NV12 format using Metal.
/// This format is commonly produced by hardware capture pipelines (e.g.,
/// `AVCaptureOutput`) and is efficient for zero-copy GPU rendering.
///
/// It is typically used when working with camera or screen capture sources
/// that provide NV12 buffers directly.
NS_AVAILABLE(10_11, 9_0)
@interface VLMTLNV12Renderer : VLMTLRenderer

@end
