//
//  VariableHeightCollectionViewCellContent.swift
//  WWDCScholars
//
//  Created by Andrew Walker on 17/05/2017.
//  Copyright © 2017 WWDCScholars. All rights reserved.
//

import Foundation
import UIKit

protocol VariableHeightCollectionViewCellContent: VariableDimensionCollectionViewCellContent {}

extension VariableHeightCollectionViewCellContent {
    
    // MARK: - Functions
    
    func height(within collectionView: UICollectionView, minimumLineSpacing: CGFloat, edgeInsets: UIEdgeInsets) -> CGFloat {
        return self.dimension(within: collectionView, spacing: minimumLineSpacing, edgeInset1: edgeInsets.top, edgeInset2: edgeInsets.bottom)
    }
}
