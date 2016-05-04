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

#import "UAirship.h"
#import <OCMock/OCMock.h>
#import <OCMock/OCMConstraint.h>
#import "GAI.h"
#import "GAITracker.h"
#import "GAIDictionaryBuilder.h"
#import "UAAnalytics.h"
#import "UATracker.h"

@import XCTest;

@interface Tests : XCTestCase

@property (nonatomic, strong) UATracker *tracker;
@property (nonatomic, strong) id mockAirship;
@property (nonatomic, strong) id mockAnalytics;

@end

@implementation Tests

- (void)setUp {
    [super setUp];

    id googleTracker = [[GAI sharedInstance] trackerWithTrackingId:@"testing_tracker"];
    self.tracker = [UATracker trackerWithGATracker:googleTracker];

    self.mockAnalytics = [OCMockObject niceMockForClass:[UAAnalytics class]];

    self.mockAirship = [OCMockObject niceMockForClass:[UAirship class]];
    [[[self.mockAirship stub] andReturn:self.mockAirship] shared];
    [[[self.mockAirship stub] andReturn:self.mockAnalytics] analytics];
}

- (void)tearDown {

    // Reset tracker after each test
    [[GAI sharedInstance] removeTrackerByName:@"testing_tracker"];

    [self.mockAirship stopMocking];
    [self.mockAnalytics stopMocking];

    [super tearDown];
}

/**
 Tests creating a default event with no tracker properties.
 **/
- (void)testDefaultEventCreation {

    __block NSDictionary *eventData;
    // These values are escaped instead of JSON decoded for convenience
    __block NSDictionary *expectedEventData = @{@"event_name" : kGAIEvent,
                                                    @"properties" :     @{
                                                            @"&aid" : @"\"com.urbanairship.PodSample\"",
                                                            @"&an" : @"\"UrbanAirship-iOS-GA-Tracker_Example\"",
                                                            @"&av" : @"\"1.0\"",
                                                            @"&ea" : @"\"button_press\"",
                                                            @"&ec" : @"\"ui_action\"",
                                                            @"&el" : @"\"play\"",
                                                            @"&ev" : @"\"1\"",
                                                            @"&t" : @"\"event\"",
                                                            @"&tid" : @"\"testing_tracker\"",
                                                            }};

    [[self.mockAnalytics expect] addEvent:[OCMArg checkWithBlock:^BOOL(id obj) {
        if (![obj isKindOfClass:[UACustomEvent class]]) {
            return NO;
        }

        UACustomEvent *event = obj;
        eventData = event.data;

        [eventData valueForKey:@"&cid"];

        // cid is generated, so don't compare to static expected value
        NSMutableDictionary *properties = [eventData valueForKey:@"properties"];
        [properties removeObjectForKey:@"&cid"];

        return [eventData isEqualToDictionary:expectedEventData];
    }]];

    [self.tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"
                                                               action:@"button_press"
                                                                label:@"play"
                                                                value:@1] build]];
    [self.mockAnalytics verify];
}

/**
 Tests creating a default event with a screen tracking property set on the tracker.
 **/
- (void)testDefaultEventCreationWithScreen {

    __block NSDictionary *eventData;
    // These values are escaped instead of JSON decoded for convenience
    __block NSDictionary *expectedEventData = @{@"event_name" : kGAIEvent,
                                                    @"properties" :     @{
                                                            @"&aid" : @"\"com.urbanairship.PodSample\"",
                                                            @"&an" : @"\"UrbanAirship-iOS-GA-Tracker_Example\"",
                                                            @"&av" : @"\"1.0\"",
                                                            @"&cd" : @"\"Home Screen\"",
                                                            @"&ea" : @"\"button_press\"",
                                                            @"&ec" : @"\"ui_action\"",
                                                            @"&el" : @"\"play\"",
                                                            @"&ev" : @"\"1\"",
                                                            @"&t" : @"\"event\"",
                                                            @"&tid" : @"\"testing_tracker\"",
                                                            }};

    // Set the screen to ensure tracker properties are properly parsed
    [self.tracker set:kGAIScreenName
                value:@"Home Screen"];

    [[self.mockAnalytics expect] addEvent:[OCMArg checkWithBlock:^BOOL(id obj) {
        if (![obj isKindOfClass:[UACustomEvent class]]) {
            return NO;
        }

        UACustomEvent *event = obj;
        eventData = event.data;

        [eventData valueForKey:@"&cid"];

        // cid is generated, so don't compare to static expected value
        NSMutableDictionary *properties = [eventData valueForKey:@"properties"];
        [properties removeObjectForKey:@"&cid"];

        return [eventData isEqualToDictionary:expectedEventData];
    }]];

    [self.tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"
                                                               action:@"button_press"
                                                                label:@"play"
                                                                value:@1] build]];
    [self.mockAnalytics verify];
}

/**
 Tests creating an event with the event creation block.
 **/
- (void)testBlockCreatedEventCreation {

    __block NSDictionary *expectedEventData =  @{@"event_name" : @"testEventName",
                                                 @"properties" : @{@"testPropertyKey": @"\"testPropertyValue\""}};

    self.tracker.eventCreationBlock = ^UACustomEvent *(NSDictionary *parameters,  NSObject<GAITracker> *tracker) {

        UACustomEvent *customEvent = [UACustomEvent eventWithName:@"testEventName"];

        [customEvent setStringProperty:@"testPropertyValue" forKey:@"testPropertyKey"];

        return customEvent;
    };

    [[self.mockAnalytics expect] addEvent:[OCMArg checkWithBlock:^BOOL(id obj) {
        if (![obj isKindOfClass:[UACustomEvent class]]) {
            return NO;
        }

        UACustomEvent *event = obj;
        //eventData = event.data;
        return [event.data isEqualToDictionary:expectedEventData];
    }]];

    [self.tracker send:[[GAIDictionaryBuilder createScreenView] build]];

    [self.mockAnalytics verify];
}

/**
 Tests customizing an event with the event customization block.
 **/
- (void)testBlockCustomizedEventCreation {

    __block NSDictionary *eventData;
    __block NSDictionary *expectedEventData = @{@"event_name" : @"screenview",
                                                     @"properties" :     @{
                                                             @"&aid" : @"\"com.urbanairship.PodSample\"",
                                                             @"&an" : @"\"UrbanAirship-iOS-GA-Tracker_Example\"",
                                                             @"&av" : @"\"1.0\"",
                                                             @"&cd" : @"\"Home Screen\"",
                                                             @"&t" : @"\"screenview\"",
                                                             @"&tid" : @"\"testing_tracker\"",
                                                             @"testPropertyKey" : @"\"testPropertyValue\"",
                                                             }};
    [self.tracker set:kGAIScreenName
                value:@"Home Screen"];

    self.tracker.eventCustomizationBlock = ^void(UACustomEvent *customEvent, NSDictionary *parameters) {
        [customEvent setStringProperty:@"testPropertyValue" forKey:@"testPropertyKey"];
    };

    [[self.mockAnalytics expect] addEvent:[OCMArg checkWithBlock:^BOOL(id obj) {
        if (![obj isKindOfClass:[UACustomEvent class]]) {
            return NO;
        }

        UACustomEvent *event = obj;
        eventData = event.data;

        [eventData valueForKey:@"&cid"];

        // cid is generated, so don't compare to static expected value
        NSMutableDictionary *properties = [eventData valueForKey:@"properties"];
        [properties removeObjectForKey:@"&cid"];

        return [eventData isEqualToDictionary:expectedEventData];
    }]];

    [self.tracker send:[[GAIDictionaryBuilder createScreenView] build]];

    [self.mockAnalytics verify];
}

/**
 Tests sending when GA tracker is disabled.
 **/
- (void)testSendGADisabled {

    id mockGATracker = [OCMockObject partialMockForObject:self.tracker.googleAnalyticsTracker];

    //Test that no send call is made when GA forwarding is disabled
    self.tracker.googleAnalyticsEnabled = NO;

    // Attempt to send dummy screen event
    [self.tracker set:kGAIScreenName
                value:@"Home Screen"];

    [[mockGATracker reject] send:OCMOCK_ANY];

    [self.tracker send:[[GAIDictionaryBuilder createScreenView] build]];

    [mockGATracker verify];
    [mockGATracker stopMocking];
}

/**
 Tests sending when GA tracker is enabled.
 **/
- (void)testSendGAEnabled {

    id mockGATracker = [OCMockObject partialMockForObject:self.tracker.googleAnalyticsTracker];

    //Test that no send call is made when GA forwarding is disabled
    self.tracker.googleAnalyticsEnabled = YES;

    // Attempt to send dummy screen event
    [self.tracker set:kGAIScreenName
                value:@"Home Screen"];

    [[mockGATracker expect] send:OCMOCK_ANY];

    [self.tracker send:[[GAIDictionaryBuilder createScreenView] build]];

    [mockGATracker verify];
    [mockGATracker stopMocking];
}

/**
 Tests sending when UA tracker is disabled.
 **/
- (void)testSendUADisabled {

    //Test that no send call is made when GA forwarding is disabled
    self.tracker.urbanAirshipEnabled = NO;

    // Attempt to send dummy screen event
    [self.tracker set:kGAIScreenName
                value:@"Home Screen"];

    [[self.mockAnalytics reject] addEvent:OCMOCK_ANY];

    [self.tracker send:[[GAIDictionaryBuilder createScreenView] build]];

    [self.mockAnalytics verify];
}

/**
 Tests sending when UA tracker is enabled.
 **/
- (void)testSendUAEnabled {

    //Test that no send call is made when GA forwarding is disabled
    self.tracker.urbanAirshipEnabled = YES;

    // Attempt to send dummy screen event
    [self.tracker set:kGAIScreenName
                value:@"Home Screen"];

    [[self.mockAnalytics expect] addEvent:OCMOCK_ANY];

    [self.tracker send:[[GAIDictionaryBuilder createScreenView] build]];

    [self.mockAnalytics verify];
}

@end

