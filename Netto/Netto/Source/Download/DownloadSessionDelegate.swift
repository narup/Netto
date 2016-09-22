import Foundation

/* Internal session delegates implementation */
class DownloadSessionDelegate : NSObject, NSURLSessionDelegate, NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate {
    let progress: NSProgress
    
    var resumeData: NSData?
    var downloadError:NSError? = nil
    var downloadedLocationUrl:NSURL? = nil
    
    /* Handlers */
    var downloadLocation:DownloadLocation? = nil
    var downloadProgress:DownloadProgressHandler? = nil
    var completionHandler:DownloadCompletionHandler? = nil
    
    override init() {
        self.progress = NSProgress(totalUnitCount: 0)
    }
    
    //MARK: -NSURLSessionDelegate Methods
    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        print("Download session became invalid with error \(error)")
        if error != nil {
            self.downloadError = error;
        }
        invokeCompletionHandler(session)
    }
    
    //MARK: -NSURLSessionDownloadDelegate Methods
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        print("Download finished for session at temp location: \(location)")
        if self.downloadLocation != nil {
            let downloadResponse = downloadTask.response as! NSHTTPURLResponse
            print("Download response: \(downloadResponse)")
            if let destination = self.downloadLocation!(downloadResponse) {
                print("Moving temp file to location: \(destination)")
                
                let fileManager = NSFileManager.defaultManager()
                do {
                    //First check if file exists and remove it
                    if (fileManager.fileExistsAtPath(destination.path!)) {
                        try fileManager.removeItemAtURL(destination)
                        try fileManager.moveItemAtURL(location, toURL: destination)
                    }
                } catch let fileError as NSError {
                    print("FILE ERROR:\(fileError)")
                }
            } else {
                self.downloadError = NSError(domain: "InvalidDownloadLocation", code: 400, userInfo: [:])
            }
        }
    }
    
    /* Sent periodically to notify the delegate of download progress. */
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        print("Download progress: {\(totalBytesWritten)} bytes out of {\(totalBytesExpectedToWrite)} bytes")
        
        progress.totalUnitCount = totalBytesExpectedToWrite
        progress.completedUnitCount = totalBytesWritten
        
        downloadProgress?(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
    }
    
    //MARK: -NSURLSessionTaskDelegate Methods
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if error != nil {
            print("Download session completed with error \(error)")
            self.downloadError = error;
        } else {
            print("Download session completed without error")
        }
        invokeCompletionHandler(session)
    }
    
    func invokeCompletionHandler(session:NSURLSession) {
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            if self.completionHandler != nil {
                self.completionHandler!(self.downloadedLocationUrl, self.downloadError)
                self.completionHandler = nil
            }
            session.finishTasksAndInvalidate()
        }
    }
}