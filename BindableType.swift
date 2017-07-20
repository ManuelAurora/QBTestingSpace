//
//  BindableType.swift
//  TestingSpaceQuickBooks
//
//  Created by Manuel Aurora on 19.07.17.
//  Copyright © 2017 Manuel Aurora. All rights reserved.
//

import Foundation

protocol BindableType
{
    associatedtype ViewModelType
    
    var viewModel: ViewModelType! { get set }
    
    func bindViewModel()
}

extension BindableType where Self: ViewController
{
    mutating func attach(viewModel: ViewModelType) {
        self.viewModel = viewModel
        loadView()
        bindViewModel()
    }
}
