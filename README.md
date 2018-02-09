# CPEData
iOS native object mapping for MovieLabs Cross-Platform Extras Manifest, Common Metadata, AppData and Style specs, compatible with [CPEExperience](https://github.com/warnerbros/cpe-manifest-ios-experience) for a full UI implementation.

Currently supported specs:
* [Media Manifest v1.5](http://www.movielabs.com/md/manifest) conforming to [Interactivity Profile 1](http://www.movielabs.com/cpe/profiles/)
* [Common Metadata v2.4](http://www.movielabs.com/md/md)
* [CPE-AppData v1.0](http://www.movielabs.com/cpe/appdata)
* [CPE-Style v1.0](http://www.movielabs.com/cpe/style)

## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate CPEData into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'CPEData', '~> 3.0'
end
```

Then, run the following command:

```bash
$ pod install
```

### Carthage
[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager for Cocoa applications.
To integrate CPEData into your Xcode project using Carthage, specify it in your `Cartfile`:

```
github "warnerbros/cpe-manifest-ios-data" ~> 3.0
```
Then, add `CPEData.framework` and `SWXMLHash.framework` to "Linked Frameworks and Libraries" and Carthage's "copy-frameworks" script 

## Usage

Use the static `load` functions in `CPEXMLSuite` for a convenient way to initialize and parse all the supported spec files.

### Providing `URL` objects
```swift
CPEXMLSuite.load(manifestXMLURL: manifestXMLURL, appDataXMLURL: appDataXMLURL, cpeStyleXMLURL: cpeStyleXMLURL) { (error) in
    if let error = error {
        // Respond to error case
    } else {
        // Respond to parsing completion event (ExperienceLauncher.launch)
    }
}
```

### Providing `Data` objects
```swift
CPEXMLSuite.load(manifestXMLData: manifestXMLData, appDataXMLData: appDataXMLData, cpeStyleXMLData: cpeStyleXMLData) { (error) in
    if let error = error {
        // Respond to error case
    } else {
        // Respond to parsing completion event (ExperienceLauncher.launch)
    }
}
```

## Development

Open `Example/CPEDataExampleWorkspace.xcworkspace` in Xcode to build and run the sample project, which allows you to specify your own XML file URLs to be parsed and mapped to the library's native classes. The example project also provides a UI to explore the hierarchy of the parsed data:

![Example hierarchy of parsed Manifest](https://raw.githubusercontent.com/warnerbros/cpe-manifest-ios-data/assets/example_hierarchy.png)
