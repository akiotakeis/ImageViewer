//
//  IVCollectionViewCell.swift
//  ImageViewer
//
//  Created by Akio Takei on 19/12/2017.
//  Copyright © 2017 Akio Takei. All rights reserved.
//

import UIKit

class IVCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var itemImageView: UIImageView!
    
    func setupCell(_ item: IVImage) {

        guard let url = item.url else {
            return
        }
        
        if let image = IVImageCache.shared.images[url] {
            itemImageView.image = image
            return
        }
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            URLSession.shared.dataTask(with: URL(string: url)!, completionHandler: { (data, response, error) in
                if error == nil, let data = data, let image = UIImage(data: data) {
                    IVImageCache.shared.images[url] = image
                    DispatchQueue.main.async {
                        UIView.transition(with: self!.itemImageView, duration: 0.45, options: .transitionFlipFromBottom, animations: {
                            self?.itemImageView.image = image
                        })
                    }
                }
            }).resume()
        }
    }
}
