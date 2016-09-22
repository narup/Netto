//
//  NettoDownloader.swift
//  Netto
//
//  Created by Puran Singh on 9/22/16.
//  Copyright © 2016 Huma Labs. All rights reserved.
//
import Foundation

public typealias DownloadLocation = (NSHTTPURLResponse) -> (NSURL?)
public typealias DownloadProgressHandler = ((Int64, Int64, Int64) -> Void)
public typealias DownloadCompletionHandler = ((NSURL?, NSError?) -> Void)

class NettoDownloader {
    
    /* Download the file from the given file url to a download location. Set backgroundMode true for background mode support */
    class func doDownload(fileUrl:String!, downloadLocation:DownloadLocation) -> DownloadTask {
        let downloadDelegate = DownloadSessionDelegate()
        downloadDelegate.downloadLocation = downloadLocation
        
        //TODO: Using default config now, please test this!
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        //disable URL caching for download operation
        configuration.URLCache = nil
        
        let downloadSession = NSURLSession(configuration: configuration, delegate: downloadDelegate, delegateQueue: nil)
        let internalDownloadTask = downloadSession.downloadTaskWithURL(NSURL(string: fileUrl)!)
        
        let downloadTask = DownloadTask(task: internalDownloadTask, downloadDelegate: downloadDelegate)
        print("Starting download process for url \(fileUrl)")
        downloadTask.resume()
        
        return downloadTask
    }
}