//
//  UploadTask
//  Netto
//
//  Created by Puran Singh on 9/22/16.
//  Copyright © 2016 Huma Labs. All rights reserved.
//
import Foundation

public class UploadTask {
    private let uploadDelegate: UploadSessionDelegate
    
    /// The underlying task.
    public let task: NSURLSessionUploadTask
    
    /// The response received from the server, if any.
    public var response: NSHTTPURLResponse? { return task.response as? NSHTTPURLResponse }
    
    /// The progress of the request lifecycle.
    public var progress: NSProgress? { return uploadDelegate.progress }
    
    public init(task: NSURLSessionUploadTask, uploadDelegate:UploadSessionDelegate) {
        self.task = task
        self.uploadDelegate = uploadDelegate
    }
    
    //MARK: Upload Task Methods
    public func progress(progressHandler: UploadProgressHandler) -> Self {
        uploadDelegate.uploadProgress = progressHandler
        return self
    }
    
    public func completion(completionHandler:UploadCompletionHandler) -> Self {
        uploadDelegate.completionHandler = completionHandler
        
        return self
    }
    
    public func suspend() {
        task.suspend()
    }
    
    public func resume() {
        task.resume()
    }
    
    public func cancel() {
        task.cancel()
    }
}