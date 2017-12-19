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

class ViewController: UIViewController {

    let viewModel = IVImageViewModel()
    @IBOutlet weak var itemsCollectionView: UICollectionView!
    
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
    
    func openCamera(_ source: UIImagePickerControllerSourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = source
        picker.delegate = self
        picker.allowsEditing = false
        present(picker, animated: true)
    }
}

extension ViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
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
