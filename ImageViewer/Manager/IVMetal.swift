//
//  IVMetal.swift
//  ImageViewer
//
//  Created by Akio Takei on 2017/12/20.
//  Copyright © 2017 Akio Takei. All rights reserved.
//

import Foundation
import Metal
import MetalKit

class IVMetal {
    
    public static var shared = IVMetal()
    
    let bytesPerPixel: Int = 4
    
    let queue = DispatchQueue(label: "com.metal.queue")
    
    lazy var device: MTLDevice! = MTLCreateSystemDefaultDevice()
    lazy var defaultLibrary: MTLLibrary! = {
        self.device.makeDefaultLibrary()
    }()
    lazy var commandQueue: MTLCommandQueue! = {
        NSLog("\(self.device.name)")
        return self.device.makeCommandQueue()
    }()
    
    var outTexture: MTLTexture!
    
    var pipelineState: MTLComputePipelineState!
    
    let threadGroupCount = MTLSizeMake(16, 16, 1)
    
    init() {
        queue.async {
            self.setUpMetal()
        }
    }
    
    private func setUpMetal() {
        if let kernelFunction = defaultLibrary.makeFunction(name: "combine") {
            do {
                pipelineState = try device.makeComputePipelineState(function: kernelFunction)
            }
            catch {
                fatalError("Impossible to setup Metal")
            }
        }
    }
    
    private func getTextureFromImage(_ image: UIImage) -> MTLTexture? {
        
        guard let cgImage = image.cgImage else {
            return nil
        }
        let textureLoader = MTKTextureLoader(device: self.device)
        do {
            return try textureLoader.newTexture(cgImage: cgImage, options: nil)
        }
        catch {
            return nil
        }
    }
    
    private func getImageFromTexture(_ texture: MTLTexture) -> UIImage {
        
        let imageByteCount = texture.width * texture.height * bytesPerPixel
        let bytesPerRow = texture.width * bytesPerPixel
        var src = [UInt8](repeating: 0, count: Int(imageByteCount))
        
        let region = MTLRegionMake2D(0, 0, texture.width, texture.height)
        texture.getBytes(&src, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        
        let bitmapInfo = CGBitmapInfo(rawValue:
            (CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitsPerComponent = 8
        let context = CGContext(data: &src,
                                width: texture.width,
                                height: texture.height,
                                bitsPerComponent: bitsPerComponent,
                                bytesPerRow: bytesPerRow,
                                space: colorSpace,
                                bitmapInfo: bitmapInfo.rawValue)
        
        let dstImageFilter = context?.makeImage()
        
        return UIImage(cgImage: dstImageFilter!, scale: 0.0, orientation: UIImageOrientation.up)
    }
    
    private func applyCombine(inTexture: MTLTexture, inTexture2: MTLTexture) {
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let commandEncoder = commandBuffer.makeComputeCommandEncoder()!
        
        commandEncoder.setComputePipelineState(pipelineState)
        commandEncoder.setTexture(inTexture, index: 0)
        commandEncoder.setTexture(inTexture2, index: 1)
        commandEncoder.setTexture(outTexture, index: 2)
        
        var pixelSize = inTexture.width
        let buffer = device.makeBuffer(bytes: &pixelSize, length: MemoryLayout<UInt>.size,
                                       options: MTLResourceOptions.storageModeShared)
        commandEncoder.setBuffer(buffer, offset: 0, index: 0)
        
        let threadGroups = MTLSizeMake(
            Int(inTexture.width + inTexture2.width) / self.threadGroupCount.width,
            Int(inTexture.height) / self.threadGroupCount.height, 1)
        commandEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
        commandEncoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    internal func combineImages(_ image: UIImage, _ image2: UIImage, _ completion: @escaping (UIImage?) -> Void) {
        
        queue.async { () -> Void in
            
            guard let inTexture = self.getTextureFromImage(image),
                let inTexture2 = self.getTextureFromImage(image2) else {
                    completion(nil)
                    return
            }
            
            let width = inTexture.width + inTexture2.width
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: .rgba8Unorm, width: width, height: inTexture.height, mipmapped: false)
            self.outTexture = self.device.makeTexture(descriptor: textureDescriptor)
            self.applyCombine(inTexture: inTexture, inTexture2: inTexture2)
            
            let resultImage = self.getImageFromTexture(self.outTexture)
            
            DispatchQueue.main.async {
                completion(resultImage)
            }
        }
    }
}
