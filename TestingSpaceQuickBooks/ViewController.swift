//
//  ViewController.swift
//  TestingSpaceQuickBooks
//
//  Created by Manuel Aurora on 19.07.17.
//  Copyright © 2017 Manuel Aurora. All rights reserved.
//

import Cocoa
import RxSwift
import RxCocoa

class ViewController: NSViewController, BindableType
{
    @IBOutlet weak var tokenTextField: NSTextField!
    @IBOutlet weak var tokenSecretTextField: NSTextField!
    @IBOutlet weak var realmIdTextField: NSTextField!
    @IBOutlet weak var kpiListPopUp: NSPopUpButton!
    @IBOutlet weak var dumpTextView: NSTextView!
    @IBOutlet weak var dumpButton: NSButton!
    
    private let nc = NotificationCenter.default
    private let bag = DisposeBag()
    var viewModel: QuickBooksViewModel!
    private var choosenKpiName = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        kpiListPopUp.removeAllItems()
        kpiListPopUp.addItems(withTitles: [
            "Income",
            "Expenses",
            "Balance",
            "Balance by Bank Accounts",
            "Profit and Loss",
            "Open Invoices",
            "Overdue Invoices"
            ])
        
        let qbService  = QuickBookDataManager()
        let viewModel  = QuickBooksViewModel(quickBooksService: qbService)
        self.viewModel = viewModel
        bindViewModel()
    }
    
    func bindViewModel() {
        nc.rx.notification(.qbManagerRecievedData)
            .flatMap { [unowned self] _ in
                return self.viewModel.getInfoFor(kpiName: self.choosenKpiName)
            }
            .do(onNext: { (resultArray) in
                var resultString = ""
                resultArray.forEach { element in
                    resultString.append("Key: \(element.leftValue)  Value: \(element.rightValue)\n")
                }
                self.dumpTextView.textStorage?.mutableString.setString(resultString)
            })
            .subscribe(onNext: { result in
                print(result)
            })
            .disposed(by: bag)
        
        dumpButton.rx.tap
            .debounce(0.5, scheduler: MainScheduler.instance)
            .map { [unowned self] _ -> QiuckBooksKPIs? in
                let kpi = QiuckBooksKPIs(rawValue: self.kpiListPopUp.selectedItem!.title)!
                return kpi
            }
            .do(onNext: { [unowned self] _ in
               self.choosenKpiName = self.kpiListPopUp.selectedItem!.title
            })
            .subscribe(onNext: {[unowned self] kpi in
                let realmId = self.realmIdTextField.stringValue
                let token   = self.tokenTextField.stringValue
                let secret  = self.tokenSecretTextField.stringValue

                self.viewModel.getData(kpiName: kpi!.rawValue,
                                       realmId: realmId,
                                       token: token,
                                       tokenSecret: secret)
        })
        .disposed(by: bag)
    }
}

////                let realmId	= "193514555825569"
////                let tokennn = "qyprdKch0F3SIw1kSNbxj8auuUF60GNFlLR9rgsFF9AqSEno"
////                let secret  = "f0XrEJEjgQachadH4FD36mpKdd9aguaaDyazf9aY"
//

