//
//  Netto.swift
//  Netto
//
//  Created by Puran Singh on 9/22/16.
//  Copyright © 2016 Huma Labs. All rights reserved.
//
import Foundation
import UIKit

enum PostDataEncoding : String {
    case UrlEncoding = "application/x-www-form-urlencoded; charset=utf-8"
    case JsonEncoding = "application/json; charset=utf-8"
    case PlainTextEncoding = "text/plain; charset=utf-8"
}

struct NetworkConstants {
    static let kPostParams:String = "postParams"
}

class Netto {
    
    class func apiBaseUrl() -> String {
        //TODO: Read config file
        //return RexConfig.sharedInstance.serverBaseURL()
        return ""
    }
    
    class func apiUrlForPath(path:String!) -> NSURL {
        //TODO: read config 
        //let fullUrl = RexConfig.sharedInstance.serverBaseURL() + "/api" + path
        return NSURL(string:"")!
    }
    
    class func doPost(url url:NSURL!,
        postParams:Dictionary<String, AnyObject>,
        headerParams:Dictionary<String, String>,
        responseIsPlainText:Bool,
        completionHandler: (([String : AnyObject]?, NSError?) -> Void)) {
            
        self.doPost(url: url,
            postDataEncoding: PostDataEncoding.UrlEncoding,
            postParams: postParams,
            headerParams: headerParams,
            responseIsText:responseIsPlainText,
            completionHandler: completionHandler)
    }
    
    class func doPost(url url:NSURL!,
        postParams:Dictionary<String, AnyObject>,
        headerParams: Dictionary<String, String>,
        completionHandler: (([String : AnyObject]?, NSError?) -> Void)) {
            
        self.doPost(url: url,
            postDataEncoding: PostDataEncoding.UrlEncoding,
            postParams: postParams,
            headerParams: headerParams,
            responseIsText:false,
            completionHandler: completionHandler)
    }
    
    class func doJsonPost(url url:NSURL!,
        postParams:Dictionary<String, AnyObject>,
        headerParams:Dictionary<String, String>,
        completionHandler: (([String : AnyObject]?, NSError?) -> Void)) {
        
        self.doPost(url: url,
            postDataEncoding: PostDataEncoding.JsonEncoding,
            postParams: postParams,
            headerParams: headerParams,
            responseIsText:false,
            completionHandler: completionHandler)
    }
    
    class func doPlainTextPost(url url:NSURL!,
        postParams:Dictionary<String, AnyObject>,
        completionHandler: (([String : AnyObject]?, NSError?) -> Void)) {
        
            self.doPost(url: url,
                postDataEncoding: PostDataEncoding.PlainTextEncoding,
                postParams: postParams,
                headerParams:nil,
                responseIsText:false,
                completionHandler: completionHandler)
    }
    
    private class func doPost(url url:NSURL!,
        postDataEncoding:PostDataEncoding,
        postParams:Dictionary<String, AnyObject>,
        headerParams:Dictionary<String, String>?,
        responseIsText:Bool,
        completionHandler: (([String : AnyObject]?, NSError?) -> Void)) {
            
            let request = NSMutableURLRequest(URL: url, cachePolicy: NSURLRequestCachePolicy.UseProtocolCachePolicy, timeoutInterval: 60)
            request.HTTPMethod = "POST"
            if let headers = headerParams {
                for (headerName, headerValue) in headers {
                    request.setValue(headerValue, forHTTPHeaderField: headerName)
                }
            }
            
            //set POST request body
            self.setRequestBodyForEncoding(postDataEncoding, postParams: postParams, request:request)

            let postDataTask = NSURLSession.sharedSession().dataTaskWithRequest(request) {(data, response, error) in
                if error != nil {
                    let processedError = self.getErrorFromError(error)
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        completionHandler(nil, processedError)
                    });
                } else {
                    let httpResponse:NSHTTPURLResponse = response as! NSHTTPURLResponse
                    var userInfo = ["requestData" : postParams, "errorResponse":httpResponse]
                    
                    if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                        if (responseIsText) {
                            var datastring = ""
                            if let ds = NSString(data: data!, encoding:NSUTF8StringEncoding) {
                                datastring = ds as String
                            }
                            let responseDictionary = ["data":datastring]
                            completionHandler(responseDictionary, nil)
                        } else {
                            do {
                                let responseDictionary: AnyObject! = try NSJSONSerialization.JSONObjectWithData(data!,
                                    options: NSJSONReadingOptions())
                                
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    completionHandler(responseDictionary as? [String : AnyObject], nil)
                                })
                            } catch let jsonError as NSError {
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    completionHandler(nil, jsonError)
                                })
                            }
                        }
                    } else {
                        if (data != nil) {
                            let errorData = NSString(data: data!, encoding:NSUTF8StringEncoding)
                            userInfo["errorData"] = errorData
                        }
                        let processedError = self.processAndGetError(httpResponse, errorInfo: userInfo)
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            completionHandler(nil, processedError)
                        });
                    }
                }
            }
            //start data task
            postDataTask.resume()
    }
    
    class func doGet(urlString urlString:String,
        queryParams:Dictionary<String, String>?,
        completionHandler:([String:AnyObject]?, NSError?)->()) {
            
            var fullURL = urlString
            if (queryParams != nil  && !queryParams!.isEmpty.boolValue) {
                fullURL += "?" + self.constructUrlEncodedStringFromParams(queryParams!)
            }
            self.doGet(url: NSURL(string: fullURL)!, headerParams:nil, completionHandler: completionHandler)
    }
    
    class func doGet(url url:NSURL, headerParams:Dictionary<String, String>?, completionHandler:([String:AnyObject]?, NSError?)->()) {
        let request = NSMutableURLRequest(URL: url, cachePolicy: NSURLRequestCachePolicy.UseProtocolCachePolicy, timeoutInterval: 60)
        request.HTTPMethod = "GET"
        
        if let headers = headerParams {
            for (headerName, headerValue) in headers {
                request.setValue(headerValue, forHTTPHeaderField: headerName)
            }
        }
        
        let getTask = NSURLSession.sharedSession().dataTaskWithRequest(request,
            completionHandler: { (data:NSData?, response:NSURLResponse?, error:NSError?) -> Void in
                if (error != nil) {
                    let processedError = self.getErrorFromError(error)
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        completionHandler(nil, processedError)
                    });
                } else {
                    let httpResponse:NSHTTPURLResponse = response as! NSHTTPURLResponse
                    
                    var userInfo:[String:AnyObject] = ["requestUrl" : url.absoluteString]
                    userInfo["errorResponse"] = httpResponse
                    
                    if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                        do {
                            let response = try NSJSONSerialization.JSONObjectWithData(data!,
                                options: NSJSONReadingOptions.MutableContainers)
                            
                            var responseDictionary:[String:AnyObject]?
                            if (response is [AnyObject]) {
                                responseDictionary = ["base" : response]
                            } else {
                                responseDictionary = response as? [String:AnyObject]
                            }
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                completionHandler(responseDictionary, nil)
                            });
                        } catch let parseError as NSError {
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                completionHandler(nil, parseError)
                            });
                        }
                    } else {
                        let processedError = self.processAndGetError(httpResponse, errorInfo: userInfo)
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            completionHandler(nil, processedError)
                        });
                    }
                }
        })
        getTask.resume()
    }
    
    class func fetchImage(imageURL:String, completionHandler:(UIImage?, NSError?) -> ()) {
        self.fetchImageData(imageURL, headerParams:nil, completionHandler: { (imageData:NSData?, error:NSError?) -> () in
            if error != nil {
                completionHandler(nil, error)
            } else {
                let image = UIImage(data: imageData!)
                if (image != nil) {
                    completionHandler(image, nil)
                } else {
                    completionHandler(nil, NSError(domain: "CorruptImageData", code: 500, userInfo: ["imageURL":imageURL]))
                }
            }
        })
    }
    
    class func fetchImageData(imageURL:String, headerParams:Dictionary<String,String>?, completionHandler:(NSData?, NSError?) -> ()) {
        let url = NSURL(string: imageURL)!
        let request = NSMutableURLRequest(URL: url, cachePolicy: NSURLRequestCachePolicy.UseProtocolCachePolicy, timeoutInterval: 60)
        if let headers = headerParams {
            for (headerName, headerValue) in headers {
                request.setValue(headerValue, forHTTPHeaderField: headerName)
            }
        }
        
        let getImageTask = NSURLSession.sharedSession().dataTaskWithRequest(request,
            completionHandler: { (data:NSData?, response:NSURLResponse?, error:NSError?) -> Void in
            
            if error != nil {
                let processedError = self.getErrorFromError(error)
                completionHandler(nil, processedError)
            } else {
                let httpResponse:NSHTTPURLResponse = response as! NSHTTPURLResponse
                
                var userInfo:[String:AnyObject] = ["requestUrl" : url.absoluteString]
                userInfo["errorResponse"] = httpResponse
                
                if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    completionHandler(data, nil)
                } else {
                    let processedError = self.processAndGetError(httpResponse, errorInfo: userInfo)
                    completionHandler(nil, processedError)
                }
            }
        })
        getImageTask.resume()
    }
    
    private class func processAndGetError(httpResponse:NSHTTPURLResponse, errorInfo:[String:AnyObject]) -> NSError {
        var userInfo = errorInfo
        if (userInfo["requestData"] != nil) {
            var requestData = userInfo["requestData"] as! [NSObject : AnyObject]
            if (requestData["client_id"] != nil) {
                requestData["client_id"] = "****"
            }
            if (requestData["client_secret"] != nil) {
                requestData["client_secret"] = "****"
            }
            if (requestData["password"] != nil) {
                requestData["password"] = "****"
            }
            if (requestData["email"] != nil) {
                requestData["email"] = "*****"
            }
            userInfo["requestData"] = requestData
        }
        var error:NSError = NSError(domain: "UnknownNetworkError", code: 9999, userInfo: nil)
        if (httpResponse.statusCode >= 400 && httpResponse.statusCode < 500) {
            if let authError = httpResponse.allHeaderFields["www-Authenticate"] as? String {
                if (authError.contains("invalid_token")) {
                    error = NSError(domain: NetworkErrors.kInvalidToken, code: 400, userInfo: userInfo)
                } else {
                    error = NSError(domain: NetworkErrors.kAuthError, code: httpResponse.statusCode, userInfo: userInfo)
                }
            } else if let errorData = userInfo["errorData"] as? String {
                if errorData.contains("invalid_grant") {
                    error = NSError(domain: NetworkErrors.kAuthError, code: httpResponse.statusCode, userInfo: userInfo)
                }
            } else {
                error = NSError(domain: NetworkErrors.kInvalidRequest, code: httpResponse.statusCode, userInfo: userInfo)
            }
        } else if (httpResponse.statusCode == 500) {
            error = NSError(domain: NetworkErrors.kServerError, code: httpResponse.statusCode, userInfo: userInfo)
        } else {
            error = NSError(domain: NetworkErrors.kUnknownNetworkError, code: httpResponse.statusCode, userInfo: userInfo)
        }
        return error
    }
    
    private class func getErrorFromError(error:NSError!) -> NSError {
        var retError = error
        //look for important error code, also try best to group similar errors for better logging
        if error.code == NSURLErrorTimedOut {
            retError = NSError(domain: NetworkErrors.kRequestTimeoutError, code: NSURLErrorTimedOut, userInfo: [:])
        } else if (error.code == NSURLErrorCannotFindHost || error.code == NSURLErrorCannotConnectToHost ||
            error.code == NSURLErrorNetworkConnectionLost) {
                retError = NSError(domain: NetworkErrors.kHostNotFoundError, code: NSURLErrorCannotFindHost, userInfo: [:])
        } else if (error.code == NSURLErrorNotConnectedToInternet) {
            retError = NSError(domain: NetworkErrors.kNotConnectedToInternetError, code: NSURLErrorNotConnectedToInternet, userInfo: [:])
        } else if (error.code == NSURLErrorBadServerResponse) {
            retError = NSError(domain: NetworkErrors.kBadServerResponse, code: NSURLErrorBadServerResponse, userInfo: [:])
        }
        return retError
    }
    
    private class func setRequestBodyForEncoding(encoding:PostDataEncoding, postParams:Dictionary<String, AnyObject>, request:NSMutableURLRequest) -> NSError? {
        if (postParams.count == 0) {
            return nil
        }
        if encoding == PostDataEncoding.UrlEncoding {
            let postString:String = self.constructUrlEncodedStringFromParams(postParams)
            request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding)
        } else if encoding == PostDataEncoding.JsonEncoding || encoding == PostDataEncoding.PlainTextEncoding {
            if let jsonEncodedString = self.constructJSONEncodedStringFromParams(postParams) {
                if jsonEncodedString.error != nil {
                    return jsonEncodedString.error
                } else if jsonEncodedString.value == nil {
                    return NSError(domain: "", code: 3300, userInfo: [NetworkConstants.kPostParams:postParams])
                } else {
                    request.HTTPBody = jsonEncodedString.value?.dataUsingEncoding(NSUTF8StringEncoding)
                    request.setValue(encoding.rawValue, forHTTPHeaderField: "Content-Type")
                }
            }
        } else {
            //ignore
        }
        return nil
    }
    
    private class func constructUrlEncodedStringFromParams(postParams:Dictionary<String, AnyObject>) -> String {
        var postString:String = ""
        var count = 0
        let totalParams = postParams.count
        for (paramName, paramValue) in postParams {
            if let paramValueString = paramValue as? String {
                postString = postString + paramName.encodeUrl + "=" + paramValueString.encodeUrl
            }
            if (count < totalParams) {
                postString = postString + "&"
            }
            count = count + 1
        }
        return postString
    }
    
    private class func constructJSONEncodedStringFromParams(postParams:Dictionary<String, AnyObject>)
        -> (value:String?, error:NSError?)? {
            
        let jsonObject: AnyObject = postParams as AnyObject
        do {
            let data = try NSJSONSerialization.dataWithJSONObject(jsonObject, options:NSJSONWritingOptions())
            let stringData = NSString(data:data, encoding:NSUTF8StringEncoding) as! String
            
            return (stringData, nil)
        } catch let jsonError as NSError {
            return (nil, jsonError)
        }
    }
}