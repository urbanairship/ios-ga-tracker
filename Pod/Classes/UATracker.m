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
#import "UATracker+Internal.h"

@implementation UATracker

- (instancetype)initWithGATracker:(NSObject<GAITracker> *)tracker
{
    self = [super init];
    if (self) {

        self.GATracker = tracker;

        // Both trackers are enabled by default
        self.googleAnalyticsEnabled = YES;
        self.urbanAirshipEnabled = YES;

        self.allowIDFACollection = NO;
    }
    return self;
}

+ (UATracker *) trackerWithGATracker:(NSObject<GAITracker> *)tracker {
    return [[self alloc] initWithGATracker:tracker];
}

- (void)set:(NSString *)parameterName
      value:(NSString *)value {
    [self.GATracker set:parameterName value:value];
}

- (NSString *)get:(NSString *)parameterName {
    return [self.GATracker get:parameterName];
}

- (void)send:(NSDictionary *)parameters{
    if (self.googleAnalyticsEnabled) {
        [self.GATracker send:parameters];
    }

    if (self.urbanAirshipEnabled) {
        UACustomEvent *event;
        if (self.eventCreationBlock) {
            event = self.eventCreationBlock(parameters, self.GATracker);
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

    __block NSString *eventName = [parameters valueForKey:kGAIHitType];
    __block UACustomEvent *customEvent = [UACustomEvent eventWithName:eventName];

    __block void (^addProperty)(NSString *, NSString *) = ^void(NSString *GAIParameter, NSString *propertyName) {
        // Look on the tracker for the parameter first
        if ([self.GATracker get:GAIParameter]) {

            NSString *parameter;

            if (![self.GATracker get:GAIParameter]) {
                parameter = [self.GATracker get:GAIParameter];
                return;
            }

            if (![parameter isEqualToString:@"<null>"] || ![parameter isEqualToString:@"null"]) {
                [customEvent setStringProperty:[self.GATracker get:GAIParameter] forKey:propertyName];
            }
        }
        else {
            // Look in the parameters after checking the tracker

            NSString *parameter;

            if (![parameters valueForKey:GAIParameter]) {
                parameter = [parameters valueForKey:GAIParameter];
                return;
            }

            if (![parameter isEqualToString:@"<null>"] || ![parameter isEqualToString:@"null"]) {
                [customEvent setStringProperty:parameters[GAIParameter] forKey:propertyName];
            }
        }
    };

    // Add default properties
    addProperty(kGAIVersion, kGAIVersion);
    addProperty(kGAITrackingId, kGAITrackingId);
    addProperty(kGAIClientId, kGAIClientId);
    addProperty(kGAIAppName, kGAIAppName);

    // Screen View Event
    if ([eventName isEqualToString:kGAIScreenView]) {
        addProperty(kGAIScreenName, kGAIScreenName);
    }

    // Standard GA Event
    if ([eventName isEqualToString:kGAIEvent]) {
        addProperty(kGAIEventCategory, kGAIEventCategory);
        addProperty(kGAIEventAction, kGAIEventAction);
        addProperty(kGAIEventLabel, kGAIEventLabel);
        addProperty(kGAIEventValue, kGAIEventValue);
    }

    // Social Event
    if ([eventName isEqualToString:kGAISocial]) {
        addProperty(kGAISocialNetwork, kGAISocialNetwork);
        addProperty(kGAISocialAction, kGAISocialAction);
        addProperty(kGAISocialTarget, kGAISocialTarget);
    }

    // Transaction Event
    if ([eventName isEqualToString:kGAITransaction]) {
        addProperty(kGAITransactionAffiliation, kGAITransactionAffiliation);
        addProperty(kGAITransactionId, kGAITransactionId);
        addProperty(kGAITransactionRevenue, kGAITransactionRevenue);
        addProperty(kGAITransactionShipping, kGAITransactionShipping);
        addProperty(kGAITransactionTax, kGAITransactionTax);
        addProperty(kGAICurrencyCode, kGAICurrencyCode);
    }
    // Item Event
    if ([eventName isEqualToString:kGAIItem]) {
        addProperty(kGAIItemPrice, kGAIItemPrice);
        addProperty(kGAIItemQuantity, kGAIItemQuantity);
        addProperty(kGAIItemSku, kGAIItemSku);
        addProperty(kGAIItemName, kGAIItemName);
        addProperty(kGAIItemCategory, kGAIItemCategory);
    }
    // Exception Event
    if ([eventName isEqualToString:kGAIException]) {
        addProperty(kGAIExDescription, kGAIExDescription);
        addProperty(kGAIExFatal, kGAIExFatal);
    }
    // Timing Event
    if ([eventName isEqualToString:kGAITiming]) {
        addProperty(kGAITimingCategory, kGAITimingCategory);
        addProperty(kGAITimingVar, kGAITimingVar);
        addProperty(kGAITimingValue, kGAITimingValue);
        addProperty(kGAITimingLabel, kGAITimingLabel);
    }
    return customEvent;
}

@end
