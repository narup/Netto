//
//  NetworkErrors
//  Netto
//
//  Created by Puran Singh on 9/22/16.
//  Copyright © 2016 Huma Labs. All rights reserved.
//
import Foundation

struct NetworkErrors {
    static let kInvalidRequest                           = "invalidNetworkRequest"
    static let kRequestTimeoutError                      = "requestTimeoutError"
    static let kHostNotFoundError                        = "hostNotFoundError"
    static let kNotConnectedToInternetError              = "notConnectedToInternetError"
    static let kBadServerResponse                        = "badServerResponse"
    static let kUploadFailedError                        = "uploadFailedError"
    static let kAuthError                                = "authError"
    static let kInvalidToken                             = "invalidToken"
    
    // MARK: Generic
    static let kServerError                              = "serverError"
    static let kUnknownNetworkError                      = "unknownNetworkError"
    static let kNotConnectToInternetCode                 = -1009
    static let kHostNotFoundErrorCode                    = -1003
}