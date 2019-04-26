import UIKit
import AWSS3
import AWSMobileClient

protocol AmazonS3ManagerDelegate: class {
    func progressChanged(_ progress: Float)
    func statusChanged(_ status: AmazonS3Manager.Status)
    func finishedUploadingImages()
}

class AmazonS3Manager: NSObject {

    enum Keys {
        // FIXME: Change this to your actual identity pool
        static let identityPool = "us-east-1:YOURIDENTITYPOOL"
        static let contentType = "image/png"
        static let onlinePathExtension = ".png"
    }

    enum Status {
        case started
        case failed(String)
        case finished(Int)
    }

    /// Singleton.
    public static var shared = AmazonS3Manager()

    /// AmazonS3ManagerDelegate.
    public weak var delegate: AmazonS3ManagerDelegate?

    var isCurrentlyUploading = Bool()

    fileprivate var customDirectory = CustomDirectory(directoryName: Keys.identityPool)
    fileprivate var backgroundUpdateTask: UIBackgroundTaskIdentifier?
    fileprivate let expression = AWSS3TransferUtilityUploadExpression()
    fileprivate var uploadCompletionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
    fileprivate var downloadCompletionHandler: AWSS3TransferUtilityDownloadCompletionHandlerBlock?
    fileprivate var uploadProgressBlock: AWSS3TransferUtilityProgressBlock?
    fileprivate var downloadProgressBlock: AWSS3TransferUtilityProgressBlock?
    fileprivate var uploadProgress = Float()
    fileprivate var downloadProgress = Float()
    fileprivate var currentFile: URL?

    // MARK: Exposed functions

    /// Set inside didFinishLaunchingWithOptions.
    public final class func configure(application: UIApplication,
                                      identifier: String,
                                      completionHandler: @escaping () -> Void) {
        AWSMobileClient.sharedInstance().initialize { (_, _) in }
        let identityPool = Keys.identityPool
        let credentialProvider = AWSCognitoCredentialsProvider(regionType: .USEast1,
                                                               identityPoolId: identityPool)
        let configuration = AWSServiceConfiguration.init(region: .USEast1, credentialsProvider: credentialProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        AWSS3TransferUtility.interceptApplication(application,
                                                  handleEventsForBackgroundURLSession: identifier,
                                                  completionHandler: completionHandler)
    }

    /// Attempts to upload images if they exist on local folder.
    public func resumeAnyUnfinishedUploads() {
        if !isCurrentlyUploading {
            updateCompletionBlocks()
            resumeUpload()
        }
    }

    /// Saves images to local folder, returns array with their names and resumes upload.
    public func updateLocalFolderAndResumeUpload(images: [UIImage]) -> [String] {
        var photoURLs = [String]()
        for image in images {
            let fileName = self.createUniqueFileName()
            guard let onlineFolderName = getOnlineFolderName() else { return [] }
            if let error = customDirectory.save(image: image, imageName: fileName) {
                print(error)
                return []
            }
            let photoURL = onlineFolderName + fileName + Keys.onlinePathExtension
            photoURLs.append(photoURL)
        }
        if !self.isCurrentlyUploading {
            self.resumeUpload()
        }
        return photoURLs
    }

    private func getOnlineFolderName() -> String? {
        // FIXME: Change this to your actual Amazon s3 image folder path
        let userIDEncrypted = "userIDExample"
        let folderName = "uploads/users/\(userIDEncrypted)/imagesFolder/"
        return folderName
    }

    // MARK: Private functions
    private func updateCompletionBlocks() {
        updateProgressBlock()
        updateStatusBlock()
    }

    private func updateProgressBlock() {
        uploadProgressBlock = {(task, progress) in
            DispatchQueue.main.async(execute: {
                if self.uploadProgress < Float(progress.fractionCompleted) {
                    self.uploadProgress = Float(progress.fractionCompleted)
                    self.delegate?.progressChanged(self.uploadProgress)
                }
            })
        }
    }

    private func updateStatusBlock() {
        uploadCompletionHandler = { (task, error) -> Void in
            self.isCurrentlyUploading = true
            DispatchQueue.main.async(execute: {
                if let error = error {
                    self.delegate?.statusChanged(.failed(error.localizedDescription))
                    self.finishTasks()
                } else if self.uploadProgress != 1.0 {
                    self.delegate?.statusChanged(.failed("interrupted"))
                    self.finishTasks()
                } else { // If image finished uploading correctly, remove image and check folder again
                    self.delegate?.statusChanged(.finished(self.getImagesLeft()))
                    self.repeatTask()
                }
            })
        }
    }

    private func repeatTask() {
        if let error = customDirectory.removeFile(fileURL: currentFile) {
            print(error)
            return
        }
        if let imageCount = customDirectory.getAllImagesURL()?.count, (imageCount > 0) {
            self.resumeUpload()
        } else {
            finishTasks()
        }
    }

    private func resumeUpload() {
        beginBackgroundUpload()
        let queue = DispatchQueue.global(qos: .background)
        queue.async {
            let imagesURL = self.customDirectory.getAllImagesURL()
            if let urlsArray = imagesURL, (urlsArray.count > 0),
                let imageURL = urlsArray.first,
                let key = imageURL.lastPathComponent.components(separatedBy: ".").first {
                self.currentFile = imageURL
                self.uploadFile(fileURL: imageURL, key: key)
            } else {
                self.finishTasks()
            }
        }
    }

    private func finishTasks() {
        self.isCurrentlyUploading = false
        self.delegate?.finishedUploadingImages()
        self.endBackgroundUpload()
        self.sendLocalNotification()
    }

    private func uploadFile(fileURL: URL, key: String) {
            let expression = AWSS3TransferUtilityUploadExpression()
            expression.progressBlock = self.uploadProgressBlock

            self.uploadProgress = 0
            self.delegate?.progressChanged(self.uploadProgress)

            let transferUtility = AWSS3TransferUtility.default()

            guard let onlineFolderName = self.getOnlineFolderName() else { return }

            transferUtility.uploadFile(
                fileURL,
                key: onlineFolderName + key + Keys.onlinePathExtension,
                contentType: Keys.contentType,
                expression: expression,
                completionHandler: self.uploadCompletionHandler).continueWith { [weak self] (task) -> Any? in
                    if let error = task.error {
                        self?.delegate?.statusChanged(.failed(error.localizedDescription))
                        self?.finishTasks()
                    }
                    return nil
            }
    }

    public func downloadImage(from urlPath: String, completion: @escaping (UIImage?) -> Void) {

        downloadCompletionHandler = { (task, location, data, error) -> Void in
            DispatchQueue.main.async(execute: {
                if error != nil {
                    completion(nil)
                } else if self.downloadProgress != 1.0 {
                    completion(nil)
                } else {
                    if let data = data {
                        completion(UIImage(data: data, scale: UIScreen.main.scale))
                    } else {
                        completion(nil)
                    }
                }
            })
        }

        expression.progressBlock = {(task, progress) in
            DispatchQueue.main.async(execute: {
                if  self.downloadProgress < Float(progress.fractionCompleted) {
                    self.downloadProgress = Float(progress.fractionCompleted)
                }
            })
        }

        downloadData(from: urlPath)
    }

    private func downloadData(from urlPath: String) {
        let expression = AWSS3TransferUtilityDownloadExpression()
        expression.progressBlock = self.downloadProgressBlock

        self.downloadProgress = 0

        let transferUtility = AWSS3TransferUtility.default()

        transferUtility.downloadData(
            forKey: urlPath,
            expression: expression,
            completionHandler: self.downloadCompletionHandler).continueWith { (_) -> Any? in
            return nil
        }
    }
}

// MARK: File Manager functions
private extension AmazonS3Manager {
    func createUniqueFileName() -> String {
        let uniqueString = NSUUID().uuidString
        return uniqueString
    }

    func clearImagesFolder() {
        if let error = customDirectory.clearDocumentDirectory() {
            print(error)
            return
        }
    }

    func getImagesLeft() -> Int {
        if let imagesLeft = customDirectory.getAllImagesURL()?.count {
            return imagesLeft
        } else {
            return 0
        }
    }
}

// MARK: UIBackgroundTask
private extension AmazonS3Manager {
    func beginBackgroundUpload() {
        let folderName = Keys.identityPool
        backgroundUpdateTask = UIApplication.shared.beginBackgroundTask(withName: folderName, expirationHandler: {
            self.endBackgroundUpload()
        })
    }

    func endBackgroundUpload() {
        if backgroundUpdateTask != nil {
            UIApplication.shared.endBackgroundTask(backgroundUpdateTask!)
            backgroundUpdateTask = UIBackgroundTaskIdentifier.invalid
        }
    }

    func sendLocalNotification() {
        DispatchQueue.main.async {
            if UIApplication.shared.applicationState == .background {
                NotificationService.fireMessage(title: "AmazonS3NotificationTitle",
                                                subtitle: "AmazonS3NotificationSubtitle")
            }
        }
    }
}
