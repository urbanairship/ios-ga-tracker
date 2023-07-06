:warning: **This tracker is no longer supported**: On July 1, 2023, [Google Analytics 4 (GA4) replaced Universal Analytics](https://support.google.com/firebase/answer/9167112). For information about Airship's support for GA4 please [visit this documentation](https://docs.airship.com/integrations/google-analytics).

# UrbanAirship-iOS-GA-Tracker

[![Version](https://img.shields.io/cocoapods/v/UrbanAirship-iOS-GA-Tracker.svg?style=flat)](http://cocoapods.org/pods/UrbanAirship-iOS-GA-Tracker)
[![License](https://img.shields.io/cocoapods/l/UrbanAirship-iOS-GA-Tracker.svg?style=flat)](http://cocoapods.org/pods/UrbanAirship-iOS-GA-Tracker)
[![Platform](https://img.shields.io/cocoapods/p/UrbanAirship-iOS-GA-Tracker.svg?style=flat)](http://cocoapods.org/pods/UrbanAirship-iOS-GA-Tracker)

## Installation

UrbanAirship-iOS-GA-Tracker is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "UrbanAirship-iOS-GA-Tracker"
```

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Usage

### Overview

The Urban Airship Google Analytics tracker consumes Google Analytics events via a UATracker instance then uses this data to generate Custom Events. The UATracker is configured by default to upload the generated Custom Events to Urban Airship, then forward the original event data to Google Analytics. The UATracker generates custom events with a pre-defined subset of Google analytics fields that can be customized by with a customization block, or defined completely with a creation block.

### Examples

Configuring the UATracker:

```objc

// Set the googleAnalyticsEnabled flag to NO to prevent forwarding events to Google Analytics
tracker.googleAnalyticsEnabled = NO;

// Set the urbanAirshipEnabled flag to NO to prevent forwarding custom events to Urban Airship
tracker.urbanAirshipEnabled = NO;

```

Creating a screen tracking event:

```objc

// Initialize a Google Analytics tracker
NSObject<GAITracker> *googleAnalyticsTracker = [[GAI sharedInstance] trackerWithTrackingId:@"GA_tracker"];

// Initialize a Urban Airship tracker
UATracker *tracker = [UATracker trackerWithGATracker:googleAnalyticsTracker]; 

// Enable GA tracker (enabled by default)
tracker.googleAnalyticsEnabled = YES;

// Enable UA tracker (enabled by default)
tracker.urbanAirshipEnabled = YES;

// Add screen tracking event
[tracker set:kGAIScreenName value:@"Home Screen"];

// Send screen tracking event
[tracker send:[[GAIDictionaryBuilder createScreenView] build]];

```

Adding Custom Event properties with the customization block:

```objc

// Add event customization block to add properties to the generated customEvent
tracker.eventCustomizationBlock = ^void(UACustomEvent *customEvent, NSDictionary *parameters) {
    [customEvent setStringProperty:@"propertyValue" forKey:@"propertyKey"];
};

```

Creating a custom event using an event creation block:

```objc

tracker.eventCreationBlock = ^UACustomEvent *(NSDictionary *parameters,  NSObject<GAITracker> *tracker) {

    UACustomEvent *customEvent = [UACustomEvent eventWithName:@"eventName"];

    [customEvent setStringProperty:@"propertyValue" forKey:@"propertyKey"];

    return customEvent;
};

```

## Author

Urban Airship, support@urbanairship.com

## License

UrbanAirship-iOS-GA-Tracker is available under Apache License, Version 2.0. See the LICENSE file for more info.
