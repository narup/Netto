//
//  UploadSessionDelegate
//  Netto
//
//  Created by Puran Singh on 9/22/16.
//  Copyright © 2016 Huma Labs. All rights reserved.
//
import Foundation

/* Internal session delegates implementation */
public class UploadSessionDelegate : NSObject, NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate {
    let progress: NSProgress
    
    var responseData:NSMutableData? = nil
    var uploadError:NSError? = nil
    
    /* Handlers */
    var uploadProgress:UploadProgressHandler? = nil
    var completionHandler:UploadCompletionHandler? = nil
    
    override init() {
        self.progress = NSProgress(totalUnitCount: 0)
    }
    
    //MARK: -NSURLSessionDelegate Methods
    public func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        print("Upload session became invalid with error \(error)")
        if error != nil {
            self.uploadError = error;
        }
        invokeCompletionHandler(session)
    }
    
    //MARK: -NSURLSessionTaskDelegate methods
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if error != nil {
            print("session \(session) occurred error \(error?.localizedDescription)")
            self.uploadError = error
        } else if responseData != nil {
            print("session \(session) upload completed")
        } else {
            self.uploadError = NSError(domain: "InvalidUploadResponse", code: 500, userInfo: [:])
        }
        invokeCompletionHandler(session)
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let progressValue: Float = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
        print("PROGRESS:\(progressValue)")
        progress.totalUnitCount = totalBytesExpectedToSend
        progress.completedUnitCount = totalBytesSent
        
        uploadProgress?(totalBytesSent, totalBytesSent, totalBytesExpectedToSend)
    }
    
    //MARK: -NSURLSessionDataDelegate methods
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        if (self.responseData == nil) {
            self.responseData = NSMutableData()
        }
        self.responseData?.appendData(data)
    }
    
    func invokeCompletionHandler(session:NSURLSession) {
        var finalUploadResponse:[String : AnyObject]? = nil
        
        if self.responseData != nil && self.uploadError == nil {
            let resData = NSData(data: self.responseData!)
            do {
                if let uploadResponse:AnyObject = try NSJSONSerialization.JSONObjectWithData(resData, options: NSJSONReadingOptions.AllowFragments) {
                    finalUploadResponse = uploadResponse as? [String : AnyObject]
                } else {
                    let dataString = NSString(data:resData, encoding:NSUTF8StringEncoding)
                    print("RESPONSE STRING DATA = \(dataString)")
                    
                    var userInfo = [String:String]()
                    if (dataString != nil) {
                        userInfo["errorResponse"] = dataString! as String
                    }
                    
                    self.uploadError = NSError(domain: "InvalidUploadResponse", code: 500, userInfo: userInfo)
                }
            } catch let error as NSError {
                print("UPLOAD ERROR:\(error)")
            }
        } else {
            self.uploadError = NSError(domain: "InvalidUploadResponse", code: 500, userInfo: [:])
        }
        
        if self.completionHandler != nil {
            self.completionHandler!(finalUploadResponse, self.uploadError)
            self.completionHandler = nil
        }
        session.finishTasksAndInvalidate()
    }
}