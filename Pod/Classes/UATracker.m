/*
 Copyright 2009-2016 Urban Airship Inc. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY THE URBAN AIRSHIP INC ``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 EVENT SHALL URBAN AIRSHIP INC OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "UATracker.h"
#import "UAirship.h"
#import "GAI.h"
#import "GAITracker.h"
#import "UAAnalytics.h"
#import "UACustomEvent.h"
#import "GAIFields.h"
#import "UATracker.h"

@interface UATracker ()

@property (nonatomic, strong) NSArray *trackerKeys;

@end

@implementation UATracker

- (instancetype)initWithGATracker:(NSObject<GAITracker> *)tracker
{
    self = [super init];
    if (self) {

        self.googleAnalyticsTracker = tracker;

        // Both trackers are enabled by default
        self.googleAnalyticsEnabled = YES;
        self.urbanAirshipEnabled = YES;

        self.allowIDFACollection = NO;

        self.trackerKeys = @[@"&v", @"&an", @"&tid", @"&uid", @"&dr", @"&cn", @"&cs", @"&cm", @"&ck", @"&cc", @"&ci", @"&gclid", @"&dclid", @"&dl", @"&dh", @"&dp", @"&dt", @"&cd", @"&av", @"&aid", @"&aiid"];
    }
    return self;
}

+ (UATracker *) trackerWithGATracker:(NSObject<GAITracker> *)tracker {
    return [[self alloc] initWithGATracker:tracker];
}

- (void)set:(NSString *)parameterName
      value:(NSString *)value {
    [self.googleAnalyticsTracker set:parameterName value:value];
}

- (NSString *)get:(NSString *)parameterName {
    return [self.googleAnalyticsTracker get:parameterName];
}

- (void)send:(NSDictionary *)parameters{
    if (self.googleAnalyticsEnabled) {
        [self.googleAnalyticsTracker send:parameters];
    }

    if (self.urbanAirshipEnabled) {
        UACustomEvent *event;
        if (self.eventCreationBlock) {
            event = self.eventCreationBlock(parameters, self.googleAnalyticsTracker);
        } else {
            event = [self generateCustomEventWithParameters:parameters];
        }

        if (!event) {
            return;
        }

        if (self.eventCustomizationBlock) {
            self.eventCustomizationBlock(event, parameters);
        }

        [[[UAirship shared] analytics] addEvent:event];
    }
}

- (UACustomEvent *)generateCustomEventWithParameters:(NSDictionary *)parameters {

    NSString *eventName = [parameters valueForKey:kGAIHitType];
    UACustomEvent *customEvent = [UACustomEvent eventWithName:eventName];

    // Add all the parameters
    for (NSString *key in parameters.allKeys) {
        NSString *parameter = [parameters valueForKey:key];

        // Don't add parameter if nil or <null> string
        if (!parameter || [parameter isEqualToString:@"<null>"] || [parameter isEqualToString:@"null"]) {
            continue;
        }

        [customEvent setStringProperty:parameters[key] forKey:key];
    }

    // Add all tracker keys listed in the tracker keys array
    for (NSString *trackerKey in self.trackerKeys) {
        NSString *parameter = [self.googleAnalyticsTracker get:trackerKey];

        // Don't add parameter if nil or <null> string
        if (!parameter || [parameter isEqualToString:@"<null>"] || [parameter isEqualToString:@"null"]) {
            continue;
        }

        [customEvent setStringProperty:parameter forKey:trackerKey];
    }

    return customEvent;
}


@end
