//
//  QuickbooksService.swift
//  CoreKPI
//
//  Created by Manuel Aurora on 07.07.17.
//  Copyright © 2017 SmiChrisSoft. All rights reserved.
//

import Foundation
import RxSwift
import Action
import SwiftyJSON
import CoreData

class QuickbooksService
{
    enum QBError: Error
    {
        case coreDataSavingError
    }
    
    let authorize: Action<WebViewController, JSON> = Action(workFactory: { handler in
        return QuickbooksNetworkRouter.authorization(handler: handler).makeRequest()
    })

    lazy var saveAuthorizationInfo: Action<JSON, Void> = {
        return Action { [weak self] json in
            return self?.saveAuthInfo(json) ?? Observable.error(QBError.coreDataSavingError)
        }
    }()
    
    private let managedContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    private var quickbooksKPIManagedObjects: [QuickbooksKPI]? {
        let fetchQBKPI = NSFetchRequest<QuickbooksKPI>(entityName: "QuickbooksKPI")
        return try? managedContext.fetch(fetchQBKPI)
    }
    
    private func getIdFor(kpi: QiuckBooksKPIs) -> Int {
        switch kpi
        {
        case .Balance: return 9
        case .BalanceByBankAccounts: return 10
        case .IncomeProfitKPIs: return 11
        case .Invoices: return 12
        case .NetIncome: return 8
        case .NonPaidInvoices: return 13
        case .OpenInvoicesByCustomers: return 16
        case .OverdueCustomers: return 17
        case .PaidExpenses: return 18
        case .PaidInvoices: return 14
        case .PaidInvoicesByCustomers: return 15
        }
    }
    
    private func saveAuthInfo(_ json: JSON) -> Observable<Void> {
        let qbEntities = quickbooksKPIManagedObjects
        let realmId    = UserDefaults.standard.string(forKey: "realmId")
        
        var qbEntity: QuickbooksKPI
        
        if let entities = qbEntities, let entity = (entities.filter { $0.realmId == realmId}).first
        {
            qbEntity = entity
        } else { qbEntity = QuickbooksKPI() }
        
        qbEntity.oAuthToken        = json["oauth_token"].string ?? "NoToken"
        qbEntity.oAuthTokenSecret  = json["oauth_token_secret"].string ?? "NoToken"
        qbEntity.oAuthRefreshToken = json["oauth_refresh_token"].string ?? "NoToken"
        qbEntity.realmId           = realmId
        
        do {
            try managedContext.save()
            print("DEBUG: OAUTH SAVED")
            return Observable.empty()
        }
        catch let error {
             print("DEBUG: ERROR SAVING OAUTH")
            return Observable.error(error)
        }
    }
    
    private func updateOauthCredentialsFor(requestString: String) {
        
        let numbersInUrlString = requestString.components(separatedBy: CharacterSet.decimalDigits.inverted)
        
        let idArray = numbersInUrlString.filter {
            
            if $0.characters.count >= QuickbooksConstants.lenghtOfRealmId { return true }
            else { return false }
        }
        
        guard idArray.count > 0 else { return }
        
        let realmId = idArray[0]
        
        let fetchQuickbookKPI = NSFetchRequest<QuickbooksKPI>(entityName: "QuickbooksKPI")
        
        if let quickbooksKPI = try? managedContext.fetch(fetchQuickbookKPI), quickbooksKPI.count > 0
        {
            let filteredArray = quickbooksKPI.filter { $0.realmId == realmId }
            
            guard filteredArray.count > 0 else { return }
            
            let kpi = filteredArray[0]
            
            QuickbooksNetworkRouter.updateOauthCredentials(token: kpi.oAuthToken!,
                                                           tokenSecret: kpi.oAuthTokenSecret!,
                                                           refreshToken: kpi.oAuthRefreshToken!)
        }
    }
    
    func getChartDataFor(kpi: ExternalKPI) {
        
        var method: QuickbooksNetworkRouter!
        let kpiValue = QiuckBooksKPIs(rawValue: kpi.kpiName!)!
        
        switch kpiValue
        {
        case .Invoices:                method = .invoices
        case .NetIncome:               method = .netIncome
        case .OverdueCustomers:        method = .overdueCustomers
        case .PaidInvoices:            method = .paidInvoicesPercent
        case .NonPaidInvoices:         method = .nonPaidInvoicesPercent
        case .OpenInvoicesByCustomers: method = .openInvoicesByCustomers
        case .Balance:                 method = .balance
        case .BalanceByBankAccounts:   method = .accountList
        case .IncomeProfitKPIs:        method = .incomeProfitKPIs
        case .PaidExpenses:            method = .expencesByVendorSummary
        case .PaidInvoicesByCustomers: method = .paidInvoicesByCustomer
        }
        
        guard let realmId = kpi.quickbooksKPI?.realmId,
            let token = kpi.quickbooksKPI?.oAuthToken,
            let refreshToken = kpi.quickbooksKPI?.oAuthRefreshToken,
            let tokenSecret = kpi.quickbooksKPI?.oAuthTokenSecret else { fatalError("RealmId or credentials not found") }
        
        QuickbooksNetworkRouter.updateOauthCredentials(token: token,
                                                       tokenSecret: tokenSecret,
                                                       refreshToken: refreshToken)
        
        method.makeRequest(with: realmId).subscribe(onNext: { (json) in
            print(json)
        }, onError: { (error) in
            print(error)
        })
        
    }
    
    func addOnServerSelected(kpis: [semenSettingsTuple]) {
        var kpiIDs = [Int]()
        
        kpis.forEach { kpi in
            if let qbkpi = QiuckBooksKPIs(rawValue: kpi.SettingName)
            {
                let idForKpi = self.getIdFor(kpi: qbkpi)
                kpiIDs.append(idForKpi)
            }
        }
        let externalKPI = ExternalKPI()
        let realmId     = UserDefaults.standard.string(forKey: "realmId")!
        let addRequest  = AddKPI(model: ModelCoreKPI.modelShared)
        
        externalKPI.kpiName = "SemenKPI"
        externalKPI.quickbooksKPI = quickbooksKPIManagedObjects?.filter({
            $0.realmId == realmId
        }).first
        
        externalKPI.serviceName = IntegratedServices.Quickbooks.rawValue
        addRequest.type = IntegratedServicesServerID.quickbooks.rawValue
        
        let semenKPI = KPI(kpiID: -2,
                           typeOfKPI: .IntegratedKPI,
                           integratedKPI: externalKPI,
                           createdKPI: nil,
                           imageBacgroundColour: nil)
        
        addRequest.kpiIDs = kpiIDs
        addRequest.kpi = semenKPI
        
        addRequest.addKPI(success: { result in
            print("Added new Internal KPI on server")         
        }, failure: { error in
            print(error)
        })
    }
}

