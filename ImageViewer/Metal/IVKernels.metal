//
//  IVKernels.metal
//  ImageViewer
//
//  Created by Akio Takei on 2017/12/20.
//  Copyright © 2017 Akio Takei. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void combine(texture2d<float, access::read> inTexture [[texture(0)]],
                    texture2d<float, access::read> inTexture2 [[texture(1)]],
                    texture2d<float, access::write> outTexture [[texture(2)]],
                    device unsigned int *width [[buffer(0)]],
                    uint2 gid [[thread_position_in_grid]]) {
    
    float4 colorAtPixel;
    if (gid.x < width[0]) {
        colorAtPixel = inTexture.read(uint2(width[0] - 1 - gid.x, gid.y));
    } else {
        colorAtPixel = inTexture2.read(uint2(gid.x - width[0], gid.y));
    }
    float4 rgbaColor = float4(colorAtPixel.r, colorAtPixel.g, colorAtPixel.b, colorAtPixel.a);
    outTexture.write(rgbaColor, gid);
}
