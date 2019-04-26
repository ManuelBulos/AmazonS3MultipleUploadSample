//
//  NotificationService.swift
//  AmazonS3MultipleUploadSample
//
//  Created by Jose Manuel Solis Bulos on 4/26/19.
//  Copyright © 2019 manuelbulos. All rights reserved.
//

import UIKit
import UserNotifications

final class NotificationService {

    fileprivate enum Keys {
        static let identifier = "NotificationServiceIdentifier"
    }

    final class func configure(delegate: UNUserNotificationCenterDelegate, application: UIApplication) {
        UNUserNotificationCenter.current().delegate = delegate
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound, .alert]) { (_, _) in }
        application.registerForRemoteNotifications()
    }

    final class func fireMessage(title: String, subtitle: String? = nil, body: String? = nil) {
        let content = UNMutableNotificationContent()

        content.title = title

        if let subtitle = subtitle {
            content.subtitle = subtitle
        }

        if let body = body {
            content.body = body
        }

        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)

        let request = UNNotificationRequest(identifier: Keys.identifier,
                                            content: content,
                                            trigger: trigger)

        UNUserNotificationCenter.current().add(request) { (_) in }
    }
}
