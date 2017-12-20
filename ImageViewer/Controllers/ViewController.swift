//
//  ViewController.swift
//  ImageViewer
//
//  Created by Akio Takei on 19/12/2017.
//  Copyright © 2017 Akio Takei. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import CHTCollectionViewWaterfallLayout
import MobileCoreServices
import AVKit
import SimpleImageViewer

class ViewController: UIViewController {

    let viewModel = IVImageViewModel()
    @IBOutlet weak var itemsCollectionView: UICollectionView!
    let metal = IVMetal.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bind()
    }
    
    func bind() {
        viewModel.getItems()
        setupCollectionView()
    }
    
    func setupCollectionView() {
        let layout = CHTCollectionViewWaterfallLayout()
        layout.columnCount = 2
        layout.minimumColumnSpacing = 5
        layout.minimumInteritemSpacing = 5
        itemsCollectionView.collectionViewLayout = layout
        
        itemsCollectionView.register(UINib(nibName: "IVCollectionViewCell", bundle: nil), forCellWithReuseIdentifier:"itemCell")
        
        viewModel.items.asObservable().bind(to: itemsCollectionView.rx.items(cellIdentifier: "itemCell")) {(index, item, cell: IVCollectionViewCell) in
            cell.setupCell(item)
        }.disposed(by: viewModel.disposeBag)

        itemsCollectionView.delegate = self
        itemsCollectionView.alwaysBounceVertical = true
    }
    
    @IBAction func onShowImageOptions(_ sender: Any) {
        let actionController = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            actionController.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (_) in
                self.openCamera(.camera)
            }))
        }
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            actionController.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { (_) in
                self.openCamera(.photoLibrary)
            }))
        }
        
        actionController.addAction(UIAlertAction(title: "Cancel", style: .destructive))
        
        self.present(actionController, animated: true, completion: nil)
    }
    
    @IBAction func onVideoButtonPressed(_ sender: Any) {
        
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            return
        }
        openCamera(.camera, type: kUTTypeMovie as String)
    }
    
    func openCamera(_ source: UIImagePickerControllerSourceType, type: String = kUTTypeImage as String) {
        let picker = UIImagePickerController()
        picker.sourceType = source
        picker.mediaTypes = [type]
        picker.delegate = self
        picker.allowsEditing = type == kUTTypeMovie as String
        picker.videoMaximumDuration = 0.5
        present(picker, animated: true)
    }
    
    func combineFirstTwoFrameAndUpload(_ url: URL) {
        
        DispatchQueue.global().async {
            let asset = AVAsset(url: url)
            let assetImgGenerate = AVAssetImageGenerator(asset: asset)
            assetImgGenerate.appliesPreferredTrackTransform = true
            if let cgImage = try? assetImgGenerate.copyCGImage(at: CMTimeMake(0, 10), actualTime: nil),
               let cgImage2 = try? assetImgGenerate.copyCGImage(at: CMTimeMake(1, 10), actualTime: nil) {
                DispatchQueue.main.async(execute: {
                    let image = UIImage(cgImage: cgImage)
                    let image2 = UIImage(cgImage: cgImage2)
                    self.metal.combineImages(image, image2, { (combinedImage) in
                        if let combinedImage = combinedImage {
                            self.viewModel.addImage(combinedImage)
                        }
                    })
                })
            }
        }
    }
}

extension ViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! String
        if mediaType == kUTTypeMovie as String, let url = info[UIImagePickerControllerMediaURL] as? URL {
            combineFirstTwoFrameAndUpload(url)
        } else if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            viewModel.addImage(image)
        }
        picker.dismiss(animated: true)
    }
}

extension ViewController: CHTCollectionViewDelegateWaterfallLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        return viewModel.getImageSize(indexPath.row)
    }
}

extension ViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let url = viewModel.items.value[indexPath.item].url,
            let image = IVImageCache.shared.images[url] else {
                return
        }
        let configuration = ImageViewerConfiguration(configurationClosure: { (config) in
            config.image = image
        })
        let imageViewController = ImageViewerController(configuration: configuration)
        self.present(imageViewController, animated: true)
    }
}
