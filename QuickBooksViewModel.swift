//
//  QuickBooksViewModel.swift
//  TestingSpaceQuickBooks
//
//  Created by Manuel Aurora on 19.07.17.
//  Copyright © 2017 Manuel Aurora. All rights reserved.
//

import Foundation
import RxSwift

struct QuickBooksViewModel
{
    private let quickBooksService: QuickBookDataManager
    
    init(quickBooksService: QuickBookDataManager) {
        self.quickBooksService = quickBooksService
    }
    
    func getInfoFor(kpiName: String) -> Observable<resultArray> {
        return quickBooksService.dataFor(kpi: QiuckBooksKPIs(rawValue: kpiName)!)
    }
    
    func getData(kpiName: String, realmId: String, token: String, tokenSecret: String) {
        quickBooksService.companyID = realmId
        quickBooksService.oauthswift.client.credential.oauthToken = token
        quickBooksService.oauthswift.client.credential.oauthTokenSecret = tokenSecret
        quickBooksService.formListOfRequests(from: [(SettingName: kpiName,
                                                     value: true)])
        
        quickBooksService.fetchDataFromIntuit(isCreation: false)
    }
}
