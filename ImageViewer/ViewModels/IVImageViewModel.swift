//
//  IVImageViewModel.swift
//  ImageViewer
//
//  Created by Akio Takei on 19/12/2017.
//  Copyright © 2017 Akio Takei. All rights reserved.
//

import Foundation
import RxSwift
import FirebaseDatabase
import FirebaseStorage
import ObjectMapper

class IVImageViewModel {
    var disposeBag = DisposeBag()
    var items = Variable([IVImage]())
    
    func getItems() {
        Database.database().reference().child("images").queryOrdered(byChild: "createdDate").observe(.value) { [weak self] (snapshot) in
            if let data = snapshot.value as? [String: Any] {
                let imageList = Mapper<IVImageList>().map(JSON: ["images": data])
                self?.items.value = imageList?.list?.map {
                    $0.value.key = $0.key
                    return $0.value
                } ?? []
            }
        }
    }
    
    func addImage(_ image: UIImage) {
        let ref = Database.database().reference().child("images").childByAutoId()
        let meta = StorageMetadata()

        meta.contentType = "image/jpeg"
        
        guard let data = UIImageJPEGRepresentation(image, 0.2) else {
            return
        }
        
        Storage.storage().reference().child("\(ref.key).jpg").putData(data, metadata: meta) { (metaData, error) in
            if error == nil, let path = metaData?.downloadURL()?.absoluteString {
                let item = IVImage()
                item.width = Double(image.size.width)
                item.height = Double(image.size.height)
                item.createdDate = Date().timeIntervalSince1970
                item.url = path
                ref.updateChildValues(item.toJSON())
            }
        }
    }
    
    func getImageSize(_ index: Int) -> CGSize {
        return CGSize(width: items.value[index].width ?? 0, height: items.value[index].height ?? 0)
    }
}
