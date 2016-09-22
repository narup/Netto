//
//  UploadEngine
//  Netto
//
//  Created by Puran Singh on 9/22/16.
//  Copyright © 2016 Huma Labs. All rights reserved.
//
import Foundation

public typealias UploadProgressHandler = ((Int64, Int64, Int64) -> Void)
public typealias UploadCompletionHandler = (([String : AnyObject]?, NSError?) -> Void)

let kUPLOAD_NAME      = "file"
let kCONTENT_TYPE     = "multipart/form-data"
let kACCEPT_TYPE      = "application/json"
let kMIME_TYPE        = "image/jpeg"
let kBOUNDARY         = "0xKhTmLbOuNdArY"
let kTIMEOUT:NSTimeInterval          = 120 //seconds
/* Upload body fields before actual file data */
let kUPLOAD_FIELDS = "--{boundary}\r\nContent-Disposition: form-data; name=\"{upload_name}\"; filename=\"{file_name}\"\r\nContent-Type: {mime_type}\r\n\r\n"

public class NettoUploader {
    
    public class func doUpload(uploadUrl:NSURL, fileName:String, fileData:NSData,
        headerParams:Dictionary<String, String>?) -> UploadTask {
        let uploadBodyData = NSMutableData()
        
        let dict : Dictionary<String, String> = [
            "boundary" : kBOUNDARY,
            "upload_name" : kUPLOAD_NAME,
            "file_name" : fileName,
            "mime_type" : kMIME_TYPE
        ]
        
        let uploadString = Strings.render(kUPLOAD_FIELDS, dict: dict)
        let uploadEndString = Strings.render("\r\n--{boundary}--\r\n", dict: ["boundary" : kBOUNDARY])
        
        uploadBodyData.appendData(uploadString.dataUsingEncoding(NSUTF8StringEncoding)!)
        uploadBodyData.appendData(fileData)
        uploadBodyData.appendData(uploadEndString.dataUsingEncoding(NSUTF8StringEncoding)!)
        
        let contentTypeValue = Strings.render("multipart/form-data; boundary={boundary}", dict: ["boundary":kBOUNDARY])
        let contentLengthValue = String(uploadBodyData.length)
        print("CONTENT LENGTH:\(contentLengthValue)")
        
        let uploadRequest = NSMutableURLRequest(URL:uploadUrl)
        uploadRequest.HTTPMethod = "POST"
        uploadRequest.setValue(kACCEPT_TYPE, forHTTPHeaderField: "Accept")
        uploadRequest.setValue(contentTypeValue, forHTTPHeaderField: "Content-Type")
            
        if let headers = headerParams {
            for (headerName, headerValue) in headers {
                uploadRequest.setValue(headerValue, forHTTPHeaderField: headerName)
            }
        }
        
        let uploadDelegate = UploadSessionDelegate()
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.timeoutIntervalForRequest = kTIMEOUT
        let session = NSURLSession(configuration: configuration, delegate: uploadDelegate, delegateQueue: nil)

        let internalUploadTask = session.uploadTaskWithRequest(uploadRequest, fromData: uploadBodyData)
        let uploadTask = UploadTask(task: internalUploadTask, uploadDelegate: uploadDelegate)
        
        uploadTask.resume()
        
        return uploadTask
    }
}