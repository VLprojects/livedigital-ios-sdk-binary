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


/// A Metal-based renderer that uses Core Image for frame processing.
///
/// `VLMTLCIRenderer` renders video frames using a Core Image pipeline
/// backed by Metal. It is suitable for workflows that require image
/// processing, filtering, or color transformations before display.
///
/// Compared to lower-level renderers, it provides more flexibility at the
/// cost of additional processing overhead.
NS_AVAILABLE(10_11, 9_0)
@interface VLMTLCIRenderer : VLMTLRenderer

@end
