//
//  ColorCollectionVC.swift
//  PhotoEditor
//
//  Created by RoH!T on 06/03/21.
//

import UIKit

/// Manage the Color Collection view cell
class ColorCollectionVC: UICollectionViewCell {
    /// IBOutlet
    @IBOutlet weak var colorView: UIView!
    ///
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    ///
    override func layoutSubviews() {
        super.layoutSubviews()
        // MARK: - set cell view cornerRadius and border
        colorView.layer.cornerRadius = colorView.frame.width / 2
        colorView.clipsToBounds = true
        colorView.layer.borderWidth = 1.0
        colorView.layer.borderColor = UIColor.white.cgColor
    }
    // MARK: - set cell view animation
    /// set animation on selected cell
    override var isSelected: Bool {
        didSet {
            if isSelected {
                let previouTransform =  colorView.transform
                UIView.animate(withDuration: 0.3/1.5, animations: {
                    self.colorView.transform = CGAffineTransform.init(scaleX: 1.1, y: 1.1)
                }, completion: { _ in
                    UIView.animate(withDuration: 0.3 / 2, animations: {
                        self.colorView.transform = CGAffineTransform.init(scaleX: 0.9, y: 0.9)
                    }) { finished in
                        UIView.animate(withDuration: 0.3 / 2, animations: {
                            self.colorView.transform = previouTransform
                        })
                    }
                })
            }
        }
    }
}
