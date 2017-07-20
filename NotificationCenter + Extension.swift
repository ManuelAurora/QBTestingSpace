//
//  NotificationCenter + Extension.swift
//  TestingSpaceQuickBooks
//
//  Created by Manuel Aurora on 19.07.17.
//  Copyright © 2017 Manuel Aurora. All rights reserved.
//

import Foundation

extension Notification.Name
{
    static let userTappedSecuritySwitch      = Notification.Name("UserTappedSecuritySwitch")
    static let qbManagerRecievedData         = Notification.Name("qbManagerRecievedData")
    static let paypalManagerRecievedData     = Notification.Name("paypalManagerRecievedData")
    static let newExternalKPIadded           = Notification.Name("NewExternalKPIAdded")
    static let modelDidChanged               = Notification.Name("modelDidChange")
    static let userLoggedIn                  = Notification.Name("UserLoggedIn")
    static let userLoggedOut                 = Notification.Name("UserLoggedOut")
    static let userAddedPincode              = Notification.Name("UserAddedPincode")
    static let userRemovedPincode            = Notification.Name("UserRemovedPincode")
    static let userFailedToLogin             = Notification.Name("LoginAttemptFailed")
    static let appDidEnteredBackground       = Notification.Name("AppDidEnteredBackground")
    static let errorDownloadingFile          = Notification.Name("errorDownloadingFile")
    static let googleManagerRecievedData     = Notification.Name("googleManagerRecievedData")
    static let hubspotManagerRecievedData    = Notification.Name("hubspotManagerRecievedData")
    static let salesForceManagerRecievedData = Notification.Name("salesForceManagerRecievedData")
    static let hubspotCodeRecieved           = Notification.Name("HubspotCodeRecieved")
    static let hubspotTokenRecieved          = Notification.Name("HubspotTokenRecieved")
    static let reportDataForKpiRecieved      = Notification.Name("ReportDataForKpiRecieved")
    static let addedNewExtKpiOnServer        = Notification.Name("addedNewExternalKpiOnServer")
    static let internetConnectionLost        = Notification.Name("internetConnectionLost")
    static let integratedServicesListLoaded  = Notification.Name("integratedServicesListLoaded")
}
