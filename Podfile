# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'AmazonS3MultipleUploadSample' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks

use_frameworks!

inhibit_all_warnings!

  # Pods for AmazonS3MultipleUploadSample

# Amazon
$awsVersion = '~> 2.8.0'
pod 'AWSMobileClient', $awsVersion
pod 'AWSS3', $awsVersion

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '4.2'
        end
    end
end

end
