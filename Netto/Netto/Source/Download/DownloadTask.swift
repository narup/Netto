
import Foundation

/* Handle for a download task in process to check on progress, response and completion etc.*/
class DownloadTask {
    
    private let downloadDelegate: DownloadSessionDelegate
    
    /// The underlying task.
    let task: NSURLSessionDownloadTask
    
    /// The response received from the server, if any.
    var response: NSHTTPURLResponse? { return task.response as? NSHTTPURLResponse }
    
    /// The progress of the request lifecycle.
    var progress: NSProgress? { return downloadDelegate.progress }
    
    init(task: NSURLSessionDownloadTask, downloadDelegate:DownloadSessionDelegate) {
        self.task = task
        self.downloadDelegate = downloadDelegate
    }
    
    //MARK: Download Task Methods
    func progress(progressHandler: DownloadProgressHandler) -> Self {
        downloadDelegate.downloadProgress = progressHandler
        return self
    }
    
    func completion(completionHandler:DownloadCompletionHandler) -> Self {
        downloadDelegate.completionHandler = completionHandler
        
        return self
    }
    
    func suspend() {
        task.suspend()
    }
    
    func resume() {
        task.resume()
    }
    
    func cancel() {
        task.cancelByProducingResumeData { (data) in
            self.downloadDelegate.resumeData = data
        }
    }
}