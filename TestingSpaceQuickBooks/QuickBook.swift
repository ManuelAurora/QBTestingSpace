//
//  QuickBook.swift
//  CoreKPI
//
//  Created by Manuel Aurora on 20.02.17.
//  Copyright © 2017 SmiChrisSoft. All rights reserved.
//

import Foundation
import OAuthSwift
import Alamofire
import OAuthSwiftAlamofire
import RxSwift

typealias resultArray = [(leftValue: String, centralValue: String, rightValue: String)]
typealias urlStringWithMethod = (
    urlString: String,
    method: QuickBookMethod?, kpiName: QiuckBooksKPIs?
)

typealias success = () -> ()

enum QiuckBooksKPIs: String {
    case income = "Income"
    case expenses = "Expenses"
    case balance = "Balance"
    case balanceByBankAccounts = "Balance by Bank Accounts"
    case profitLoss = "Profit and Loss"
    case NonPaidInvoices = "Non-Paid Invoices"
    case PaidInvoices = "Paid invoices"
    case PaidInvoicesByCustomers = "Paid invoices by Customers"
    case openInvoices = "Open Invoices"
    case overdueInvoices = "Overdue Invoices"
}

class QuickBookDataManager
{
    var choosenKpis = [Int]()
    
    lazy var sessionManager: SessionManager =  {
        let sm = SessionManager()
        sm.adapter = self.oauthswift.requestAdapter
        
        return sm
    }()
    
    enum ResultArrayType {
        case netIncome
        case balance
        case accountList
        case paidInvoicesByCustomer
        case paidInvoicesPercent
        case overdueCustomers
        case nonPaidInvoicesPercent
        case invoices
        case expencesByVendorSummary
        case openInvoicesByCustomers
        case incomeProfitKPIs
    }
    
    private let urlBase = "https://quickbooks.api.intuit.com/v3/company/"
    
    lazy var oauthswift: OAuth1Swift = {
        let oauthswift = OAuth1Swift(
            consumerKey:    "qyprdzqpTChNK3KI8Tgd033a9OaTok",
            consumerSecret: "5LPsMnCweP7SvGqQLkDqzwKlqVyq8z1GPlRLridZ",
            requestTokenUrl: "https://oauth.intuit.com/oauth/v1/get_request_token",
            authorizeUrl:    "https://appcenter.intuit.com/Connect/Begin",
            accessTokenUrl:  "https://oauth.intuit.com/oauth/v1/get_access_token"
        )
        return oauthswift
    }()
    
    var balanceSheet: resultArray = [] {
        didSet {
            guard balanceSheet.count > 0 else { return }
            //createNewEntityForArrayOf(type: .balance)
        }
    }
    
    var kpiRequestsToSave: [urlStringWithMethod] = [] //This Array stores values for saving new kpi's into CoreData
    var profitAndLoss: resultArray = []
    var accountList: resultArray  = []
    var paidInvoices: resultArray = []
    var income: resultArray = []
    var nonPaidInvoices: resultArray = []
    var paidInvoicesByCustomer: resultArray = []
    var nonPaidInvoicesPercent: resultArray = []
    var paidInvoicesPercent: resultArray = []
    var overdueInvoices: resultArray = []
    var expences: resultArray = []
    var openInvoices: resultArray = []
    var invoices: [Invoice] = []
   
    var queryMethod: QuickBookMethod?
    var companyID: String {
        set {
            serviceParameters[.companyId] = newValue
        }
        get {
            return serviceParameters[.companyId]!
        }
    }
    
    var listOfRequests: [urlStringWithMethod] = []
    var credentialTempList: [OAuthSwiftCredential] = []
    
    var kpiFilter =  [String: Bool]()
    
    lazy var serviceParameters: [AuthenticationParameterKeys: String] = {
        let parameters: [AuthenticationParameterKeys: String] = [
            .callbackUrl: "CoreKPI:/oauth-callback/intuit",
            .consumerKey:    "qyprdLYMArOQwomSilhpS7v9Ge8kke",
            .consumerSecret: "ogPRVftZXLA1A03QyWNyJBax1qOOphuVJVP121np"
        ]
        return parameters
    }()
    
    private func getInfoFor(kpi: QiuckBooksKPIs) -> resultArray {        
        switch kpi
        {
        case .balance:
            return balanceSheet       
            
        default:
            break
        }
        
        return resultArray()
    }
    
    class func shared() -> QuickBookDataManager {
        enum Singelton
        {
            static let manager = QuickBookDataManager()
        }
        
        return Singelton.manager
    }
    
    convenience init(method: QuickBookMethod) {
        self.init()
        queryMethod = method
    }
    
    func dataFor(kpi: QiuckBooksKPIs) -> Observable<resultArray> {
        var dataArray: resultArray
        
        switch kpi
        {
        case .balance: dataArray = balanceSheet
        case .balanceByBankAccounts:   dataArray = accountList
        case .income:                  dataArray = income
        case .NonPaidInvoices:         dataArray = nonPaidInvoicesPercent
        case .openInvoices:            dataArray = openInvoices
        case .overdueInvoices:         dataArray = overdueInvoices
        case .expenses:                dataArray = expences
        case .PaidInvoices:            dataArray = paidInvoicesPercent
        case .PaidInvoicesByCustomers: dataArray = paidInvoicesByCustomer
        case .profitLoss:              dataArray = profitAndLoss
        }
        return Observable<resultArray>.just(dataArray)
    }
    
    private func formUrlPath(method: QuickBookMethod) -> String {
        let fullUrlPath = self.urlBase +
            companyID +
            method.methodName.rawValue + "?" +
            method.queryParameters.stringFromHttpParameters()
        
        return fullUrlPath
    }
    
    private var queryInvoices: QuickBookMethod {
         var queryParameters: [QBQueryParameterKeys: String] {
            let previousMonth = Calendar.current.date(byAdding: .month, value: -5, to: Date())!
            let beginDate = previousMonth.beginningOfMonth?.stringForQuickbooksQuery()
            let endDate   = previousMonth.endOfMonth?.stringForQuickbooksQuery()
            var queryParameters = [QBQueryParameterKeys: String]()
            
            if let begin = beginDate, let end = endDate
            {
                queryParameters[.query] = "SELECT * FROM Invoice" //WHERE MetaData.CreateTime >= '\(begin)' AND MetaData.CreateTime <= '\(end)'"
            }
            
            return queryParameters
        }

        return QBQuery(with: queryParameters)
    }
    
    private var queryPurchases: QuickBookMethod {
        var queryParameters: [QBQueryParameterKeys: String] {
            let previousMonth = Calendar.current.date(byAdding: .month, value: -5, to: Date())!
            let beginDate = previousMonth.beginningOfMonth?.stringForQuickbooksQuery()
            let endDate   = previousMonth.endOfMonth?.stringForQuickbooksQuery()
            var queryParameters = [QBQueryParameterKeys: String]()
            
            if let begin = beginDate, let end = endDate
            {
                queryParameters[.query] = "SELECT * FROM Purchase" //WHERE MetaData.CreateTime >= '\(begin)' AND MetaData.CreateTime <= '\(end)'"
            }
            return queryParameters
        }
        return QBQuery(with: queryParameters)
    }
    
    private func queryPath(_ method: QuickBookMethod) -> String {
        return formUrlPath(method: method)
    }
    
    private func appendQueryRequest() {
        kpiFilter[QiuckBooksKPIs.income.rawValue] = true
        kpiFilter[QiuckBooksKPIs.NonPaidInvoices.rawValue] = true
        kpiFilter[QiuckBooksKPIs.openInvoices.rawValue] = true
        kpiFilter[QiuckBooksKPIs.overdueInvoices.rawValue] = true
        kpiFilter[QiuckBooksKPIs.PaidInvoices.rawValue] = true
    }
    
    func getIdFor(kpi: QiuckBooksKPIs) -> Int {
        switch kpi
        {
        case .balance: return 9
        case .balanceByBankAccounts: return 10
        case .profitLoss: return 11
        case .income: return 8
        case .NonPaidInvoices: return 13
        case .openInvoices: return 16
        case .overdueInvoices: return 17
        case .expenses: return 18
        case .PaidInvoices: return 14
        case .PaidInvoicesByCustomers: return 15
        }
    }
    
    func formListOfRequests(from array: [(SettingName: String, value: Bool)]) {
        
        for item in array
        {
            let kpi = QiuckBooksKPIs(rawValue: item.SettingName)!
            
            if kpiFilter[item.SettingName] == nil
            {
                switch kpi
                {
                case .income, .NonPaidInvoices, .openInvoices, .overdueInvoices, .PaidInvoices:
                    let req = urlStringWithMethod(urlString: queryPath(queryInvoices),
                                                  method: queryInvoices, kpiName: kpi)
                    
                    listOfRequests.append(req)
                    appendQueryRequest()
                    
                case .balance:
                    let balanceQueryParameters: [QBQueryParameterKeys: String] = [
                        .dateMacro: QBPredifinedDateRange.thisMonth.rawValue
                    ]
                    
                    let balanceSheet = QBBalanceSheet(with: balanceQueryParameters)
                    let pathForBalance = formUrlPath(method: balanceSheet)
                    let req = urlStringWithMethod(urlString: pathForBalance,
                                                  method: balanceSheet,
                                                  kpiName: kpi)
                    
                    listOfRequests.append(req)
                    kpiRequestsToSave.append(req)
                    
                case .balanceByBankAccounts:
                    let accountListParameters: [QBQueryParameterKeys: String] = [
                        .dateMacro: QBPredifinedDateRange.thisMonth.rawValue
                    ]
                    
                    let accountList = QBAccountList(with: accountListParameters)
                    let pathForAccountList = formUrlPath(method: accountList)
                    let req = urlStringWithMethod(urlString: pathForAccountList,
                                                  method: accountList,
                                                  kpiName: kpi)
                    
                    listOfRequests.append(req)
                    kpiRequestsToSave.append(req)
                    
                case .profitLoss:
                    let profitAndLossQuartal = QBProfitAndLoss(in: .thisQuarter)
                    
                    let reqQuartal = urlStringWithMethod(urlString: formUrlPath(method: profitAndLossQuartal),
                                                         method: profitAndLossQuartal,
                                                         kpiName: kpi)
                    
                    listOfRequests.append(reqQuartal)
                    
                case .PaidInvoicesByCustomers:
                    let paidInvoicesParameters: [QBQueryParameterKeys: String] = [
                        .dateMacro: QBPredifinedDateRange.thisQuarter.rawValue,
                        .summarizeBy: QBPredifinedSummarizeValues.customers.rawValue
                    ]
                    
                    let paidInvoices = QBPaidInvoicesByCustomers(with: paidInvoicesParameters)
                    let paidInvoicesPath = formUrlPath(method: paidInvoices)
                    let req = urlStringWithMethod(urlString: paidInvoicesPath, method: paidInvoices, kpiName: kpi)
                    
                    kpiRequestsToSave.append(req)
                    listOfRequests.append(req)
                    
                case .expenses:
                    let req = urlStringWithMethod(urlString: queryPath(queryPurchases), method: queryPurchases, kpiName: kpi)
                    
                    listOfRequests.append(req)
                    appendQueryRequest()                    
                }
            }
            else
            {
                kpiRequestsToSave.append(urlStringWithMethod(urlString: queryPath(queryInvoices), method: queryInvoices, kpiName: kpi))
            }
        }
    }
    
    private func clearAllData() {
        expences.removeAll()
        invoices.removeAll()
        income.removeAll()
        kpiFilter.removeAll()
        balanceSheet.removeAll()
        profitAndLoss.removeAll()
        accountList.removeAll()
        paidInvoices.removeAll()
        nonPaidInvoices.removeAll()
        paidInvoicesByCustomer.removeAll()
        nonPaidInvoicesPercent.removeAll()
        paidInvoicesPercent.removeAll()
        overdueInvoices.removeAll()
        openInvoices.removeAll()
    }
    
    func fetchDataFromIntuit(isCreation: Bool) {
        clearAllData()
        
        for request in listOfRequests
        {            
            let handler = QuickBookRequestHandler(oauthswift: oauthswift,
                                                  request: request,
                                                  manager: self,
                                                  isCreation: isCreation)
            
            handler.getData()
        }
        
        //if isCreation { saveNewEntities() }
        listOfRequests.removeAll()
    }
   
}




