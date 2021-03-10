//
//  ColourCollectionDataSource.swift
//  PhotoEditor
//
//  Created by RoH!T on 06/03/21.
//

import UIKit

///
protocol ColorDelegate: class {
    ///
    func onEraserTapped()
    ///
    func onColorTapped(_ color: String)
}

/// Managed Colour Collection View DataSource and Delegate
class ColourCollectionDataSource: NSObject {

    // MARK: - Variable
    /// set hex# colo
    var colorCollection = [String]()
    ///
    weak var delegate: ColorDelegate?
    
    // MARK: - Initializing methods
    ///
    convenience init(withCollectionView collectionView: UICollectionView) {
        self.init()
        colorCollection = ["", "0000FF", "00FFFF", "FF0000", "FFFF00", "A52A2A", "008000", "FFA500", "800080", "FF00FF", "A9A9A9", "000000", "ffffff", "d3d3d3", "808080"]
        collectionView.delegate = self
        collectionView.dataSource = self
    }
}

extension ColourCollectionDataSource: UICollectionViewDataSource, UICollectionViewDelegate {
    ///
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    ///
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colorCollection.count
    }
    ///
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as? ColorCollectionVC else {
            fatalError("error in cell")
        }
        if indexPath.item == 0 {
            cell.colorView.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "ic_eraser"))
        } else {
            cell.colorView.backgroundColor = UIColor(hex: colorCollection[indexPath.item ])
        }
        return cell
    }
    ///
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == 0 {
            delegate?.onEraserTapped()
        } else {
            delegate?.onColorTapped(colorCollection[indexPath.item])
        }
    }
}
