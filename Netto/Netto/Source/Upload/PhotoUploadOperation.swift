//
//  PhotoUploadOperation
//  Netto
//
//  Created by Puran Singh on 9/22/16.
//  Copyright © 2016 Huma Labs. All rights reserved.
//
import Foundation

public typealias UploadHandler = ((imageId:String?, error:NSError?) -> Void)

/**
 * Handles actual photo upload operation on the background thread via operation queue.
 * It also handles retries if upload fails due to any issues, max retry count defined by
 * kMAX_RETRY_COUNT value.
 */
class PhotoUploadOperation : NSOperation {
    let kMAX_RETRY_COUNT = 3
    
    internal var uploadOperationHandler:UploadHandler!
    internal var upload:UIImage
    internal var retryCounter:Int = 0
    internal var uploadError:NSError? = nil
    internal var photoData:NSData? = nil
    internal var headerParams:Dictionary<String, String>? = nil
    
    init(image:UIImage, completionHandler:UploadHandler, headerParams:Dictionary<String, String>?) {
        self.upload = image
        self.uploadOperationHandler = completionHandler
        self.headerParams = headerParams
    }
    
    override func main() {
        if (self.cancelled || self.finished) {
            return
        }
        print("Image upload operation started")
        self.startUpload()
    }
    
    private func startUpload() {
        let uploadUrl = NSURL(string:Netto.apiBaseUrl() + "/files/upload")
        let imageData = UIImageJPEGRepresentation(self.upload, 1.0)!

        print("Uploading image size %d", getVaList([imageData.length]))
        
        let uploadNetworkTask = NettoUploader.doUpload(uploadUrl!, fileName:NSUUID().UUIDString,
            fileData: imageData, headerParams:self.headerParams)
        uploadNetworkTask.completion({ (responseData:[String : AnyObject]?, error:NSError?) -> Void in
            if (error != nil) {
                self.uploadError = error
                print("Image upload operation failed, retrying upload again")
                self.retryUpload()
            } else {
                print("Image upload operation finished")
                if isNotNil(responseData?["data"]) {
                    let imageId = responseData?["data"] as! String
                    self.uploadOperationHandler(imageId:imageId, error:nil)
                } else if isNotNil(responseData?["error"]) {
                    let errorMessage = responseData?["error"] as! String
                    if (errorMessage == "InvalidFileType") {
                        self.uploadOperationHandler(imageId:nil, error:NSError(domain: "InvalidFileType", code: 400, userInfo: ["error":errorMessage]))
                    } else {
                        self.uploadOperationHandler(imageId:nil, error:NSError(domain: "UploadError", code: 500, userInfo: ["error":errorMessage]))
                    }
                }
                self.photoData = nil
                self.uploadOperationHandler = nil
            }
        })
    }
    
    private func retryUpload() {
        if self.retryCounter < kMAX_RETRY_COUNT {
            self.retryCounter = self.retryCounter + 1;
            print("Retrying upload, \(self.retryCounter) attempt")

            //go for upload again
            self.startUpload()
        } else {
            print("Image upload operation failed even after retries")
            self.uploadOperationHandler(imageId:nil, error:self.uploadError)
            self.uploadOperationHandler = nil
        }
    }
}