//
//  QuickBookRequestHandler.swift
//  CoreKPI
//
//  Created by Мануэль on 28.02.17.
//  Copyright © 2017 SmiChrisSoft. All rights reserved.
//

import Foundation
import OAuthSwift
import Alamofire
import SwiftyJSON

class QuickBookRequestHandler
{
    private var oauthswift: OAuth1Swift!
    var request: urlStringWithMethod!
    weak var manager: QuickBookDataManager!
    var isCreation: Bool
    let notificationCenter = NotificationCenter.default
    
    deinit {
        print("DEINIT QBREQHANDL")
    }
    
    init(oauthswift: OAuth1Swift, request: urlStringWithMethod, manager: QuickBookDataManager, isCreation: Bool = false) {
        
        self.oauthswift = oauthswift
        self.request = request
        self.manager = manager
        self.isCreation = isCreation
    }
    
    func getData() {
        
        manager.sessionManager.request(request.urlString, method: .get, headers: ["Accept":"application/json"])
            .responseJSON { response in
                guard response.result.isSuccess else { self.notificationCenter.post(name: .errorDownloadingFile, object: nil); return }
                
                if let method = self.request.method, let json = response.result.value as? [String: Any]
                {
                    _ = self.handle(response: json, method: method)
                }
        }
    }
    
    func handle(response: Any, method: QuickBookMethod) -> ExternalKpiInfo? {
        
        //TODO:  This method NEED to be refined, due equivalent responses
        //guard let queryMethod = method else { print("DEBUG: Query method not found"); return nil }
        
        let jsonDict = JSON(response)
        
        switch method.methodName
        {
        case .balanceSheet:
            let rows = jsonDict["Rows"]
            let rows2 = rows["Row"].arrayValue
            
            var kpiInfo = ExternalKpiInfo()
            
            for row in rows2
            {
                if let summary = row["Summary"]["ColData"].array
                {
                    let kpiSummary = summary[1]
                    //let kpiTitle = colDataSum[0] as! [String: String]
                    
                    kpiInfo.kpiValue = kpiSummary["value"].stringValue
                }
                kpiInfo.kpiName = QiuckBooksKPIs.balance.rawValue
            }
            
            let result = (kpiInfo.kpiName,"",kpiInfo.kpiValue)
            
            manager.balanceSheet.append(result)
            
        case .query:
            //Invoices
            let currentDate = Date()
            let dateFormatter = DateFormatter()
            
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            if let invoiceList = jsonDict["QueryResponse"]["Invoice"].array
            {
                let invoices = invoiceList.map(Invoice.init)
                manager.invoices.append(contentsOf: invoices)
                
                let calendar = Calendar.current
                var invoiceDateString = ""
                
                for day in 1...31
                {
                    let invoicesThatDay = invoices.filter {
                        let d = calendar.component(.day, from: $0.txnDate)
                        return d == day
                    }
                    
                    if invoicesThatDay.count > 0
                    {
                        invoiceDateString = invoicesThatDay[0].txnDateString
                        let incomeThatDay = invoicesThatDay.reduce(Float(0), { sum, invoice in
                            sum + invoice.totalAmt
                        })
                        manager.income.append(
                            (leftValue: "\(invoiceDateString)", centralValue: "", rightValue: "\(incomeThatDay)"))
                    }
                }
                manager.income.sort(by: {
                    let firstDate = dateFormatter.date(from: $0.leftValue)!
                    let secondDate = dateFormatter.date(from: $1.leftValue)!
                    return firstDate < secondDate
                })            
            }
            else if let purchaseList = jsonDict["QueryResponse"]["Purchase"].array
            {
                let purchases = purchaseList.map(Purchase.init)
                let calendar = Calendar.current
                var purchaseDateString = ""
                
                for day in 1...31
                {
                    let purchasesThatDay = purchases.filter {
                        let d = calendar.component(.day, from: $0.txnDate)
                        return d == day
                    }
                    
                    if purchasesThatDay.count > 0
                    {
                        purchaseDateString = purchasesThatDay[0].txnDateString
                        let purchaseThatDay = purchasesThatDay.reduce(Float(0), { sum, purchase in
                            sum + purchase.totalAmt
                        })
                        manager.expences.append(
                            (leftValue: "\(purchaseDateString)", centralValue: "", rightValue: "\(purchaseThatDay)"))
                    }
                }
            }
            formListOfOpenedInvoices()
            formListOfOverduedInvoices()
            
        case .profitLoss:
            let rowsDict   = jsonDict["Rows"]
            let rows       = rowsDict["Row"].arrayValue
            
            for row in rows
            {
                if let _ = row["group"].string
                {
                    let summary    = row["Summary"]
                    let colDataSum = summary["ColData"].arrayValue
                    let kpiTitle   = colDataSum[0]["value"].stringValue
                    let value      = colDataSum[1]["value"].floatValue
                    
                    if value > 0 || value < 0
                    {
                        manager.profitAndLoss.append((leftValue: kpiTitle,
                                                      centralValue: "",
                                                      rightValue: "\(value)"))
                    }
                }
            }
            
        case .accountList:
            let rows = jsonDict["Rows"]
            let rows2 = rows["Row"].arrayValue
            
            for row in rows2
            {
                let colData    = row["ColData"].arrayValue
                let accName    = colData[0]["value"].stringValue
                let accBalance = colData[4]["value"].floatValue
                let result     = (accName, "", "\(accBalance)")
                
                if accBalance > 0 || accBalance < 0
                {
                    manager.accountList.append(result)
                    print("DEBUG: \(result)")
                }
            }
            
        case .paidInvoicesByCustomers:
            let rows = jsonDict["Rows"] as! [String: Any]
            let rows2 = rows["Row"] as! [[String: Any]]
            
            for row in rows2
            {
                //let summary = row["Summary"] as! [String: Any]
                if let colData = row["ColData"] as? [[String: Any]] {
                    
                    let customer = colData[0]["value"] as! String
                    let income = colData[3]["value"] as! String
                    
                    let result = (leftValue: customer, centralValue: "", rightValue: income)
                    
                    manager.paidInvoicesByCustomer.append(result)
                }
            }
            
        case .paidExpenses:
            let jsonDict = JSON(response)
            let rows = jsonDict["Rows"]
            let rowsArr = rows["Row"].array
            
            guard let rowsArray = rowsArr else { return nil }
            
            for row in rowsArray
            {
                if let colData = row["ColData"].array
                {
                    let title  = colData[0]["value"].stringValue
                    let value  = colData.count == 1 ? "0" : colData[1].stringValue
                    let result = (title, "", value)
                    
                    manager.profitAndLoss.append(result)
                    print("DEBUG: \(manager.profitAndLoss)")
                }
            }
        }
        notificationCenter.post(name: .qbManagerRecievedData, object: nil)
        
        return nil
    }

    private func formListOfOverduedInvoices() {
        let overdueInvoices = manager.invoices.filter {
            let currentDate = Date()
            let dueDate = $0.dueDate
            
            return dueDate < currentDate && $0.balance != 0
        }
        
        let sorted = overdueInvoices.sorted { $0.dueDate < $1.dueDate }
        
        sorted.forEach {
            manager.overdueInvoices.append((leftValue: $0.customerName, centralValue: "", rightValue: "\($0.totalAmt)"))
        }
    }
    
    private func formListOfOpenedInvoices() {
        let openInvoices = manager.invoices.filter {
            let currentDate = Date()
            let dueDate = $0.dueDate
            
            return dueDate > currentDate && $0.balance != 0
        }
        
        let sorted = openInvoices.sorted { $0.dueDate < $1.dueDate }
        
        sorted.forEach {
            manager.openInvoices.append((leftValue: $0.customerName, centralValue: "", rightValue: "\($0.totalAmt)"))
        }
    }
}
