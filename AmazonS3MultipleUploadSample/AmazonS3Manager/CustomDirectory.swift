import UIKit

public final class CustomDirectory: FileManager {

    fileprivate enum Keys {
        static let pathFormat = "%@%@"
        static let pathExtension = "jpg"
    }

    // FIXME: Change this to the actual folder name you want
    fileprivate var localFolderName = "FolderNameOnYourDevice"

    init(directoryName: String) {
        localFolderName = directoryName
    }

    public final func documentDirectoryPath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    public final func clearDocumentDirectory() -> Error? {
        let temporaryURL = URL(fileURLWithPath: documentDirectoryPath(), isDirectory: true)
        .appendingPathComponent(localFolderName)
        do {
            try removeItem(atPath: temporaryURL.path)
            return nil
        } catch {
            return error
        }
    }

    public final func save(image: UIImage, imageName: String) -> Error? {
        let temporaryURL = URL(fileURLWithPath: documentDirectoryPath(), isDirectory: true)
            .appendingPathComponent(localFolderName)
        do {
            try createDirectory(at: temporaryURL, withIntermediateDirectories: true)
        } catch {
            return error
        }

        let finalPath = temporaryURL.appendingPathComponent(imageName).appendingPathExtension(Keys.pathExtension)
        if let data = image.jpegData(compressionQuality: 0.8) {
            do {
                try data.write(to: finalPath)
                return nil
            } catch {
                return error
            }
        } else {
            return nil
        }
    }

    public final func getImage(imageName: String) -> UIImage? {
        let temporaryURL = URL(fileURLWithPath: documentDirectoryPath(), isDirectory: true)
            .appendingPathComponent(localFolderName)
            .appendingPathComponent(imageName)
            .appendingPathExtension(Keys.pathExtension)
        let image = UIImage(contentsOfFile: temporaryURL.path)
        return image
    }

    public final func removeImage(imageName: String) -> Error? {
        let temporaryURL = URL(fileURLWithPath: documentDirectoryPath(), isDirectory: true)
            .appendingPathComponent(localFolderName)
            .appendingPathComponent(imageName)
            .appendingPathExtension(Keys.pathExtension)
        do {
            try removeItem(at: temporaryURL)
            return nil
        } catch {
            return error
        }
    }

    public final func removeFile(fileURL: URL?) -> Error? {
        guard let url = fileURL else { return nil }
        do {
            try removeItem(at: url)
            return nil
        } catch {
            return error
        }
    }

    public final func getAllImagesNames() -> [String]? {
        let documentsURL = urls(for: .documentDirectory, in: .userDomainMask)[0]
        let path = documentsURL.appendingPathComponent(localFolderName)
        do {
            let fileURLs = try contentsOfDirectory(at: path, includingPropertiesForKeys: nil)
            let fileStrings = fileURLs.map({"\($0.lastPathComponent.components(separatedBy: ".").first ?? "")"})
            return fileStrings
        } catch {
            print("\(documentsURL.path): \(error.localizedDescription)")
            return nil
        }
    }

    public final func getAllImagesURL() -> [URL]? {
        let documentsURL = urls(for: .documentDirectory, in: .userDomainMask)[0]
        let path = documentsURL.appendingPathComponent(localFolderName)
        do {
            let fileURLs = try contentsOfDirectory(at: path, includingPropertiesForKeys: nil)
            return fileURLs
        } catch {
            print("\(documentsURL.path): \(error.localizedDescription)")
            return nil
        }
    }

}
