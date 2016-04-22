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
#import "UATracker+Internal.h"

@import XCTest;

@interface Tests : XCTestCase

@property (nonatomic, strong) id mockAirship;
@property (nonatomic, strong) UATracker *tracker;
@property (nonatomic, strong) id mockAnalytics;

@end

@implementation Tests

- (void)setUp {
    [super setUp];

    NSObject<GAITracker> *tracker = [[GAI sharedInstance] trackerWithTrackingId:@"testing_tracker"];

    self.tracker = [UATracker trackerWithGATracker:tracker];

    self.mockAnalytics = [OCMockObject niceMockForClass:[UAAnalytics class]];

    self.mockAirship = [OCMockObject niceMockForClass:[UAirship class]];
    [[[self.mockAirship stub] andReturn:self.mockAirship] shared];
    [[[self.mockAirship stub] andReturn:self.mockAnalytics] analytics];
}

- (void)tearDown {

    [self.mockAirship stopMocking];
    [self.mockAnalytics stopMocking];

    [super tearDown];
}

/**
 Tests Screen View event.
 **/
- (void)testScreenViewEvent {

    __block NSDictionary *eventData;
    __block NSDictionary *expectedEventData =  @{@"event_name" : kGAIScreenView,
                                                 @"properties" : @{@"&an" : @"\"UrbanAirship-iOS-GA-Tracker_Example\"",
                                                                   @"&cd" : @"\"Home Screen\"",
                                                                   @"&tid" : @"\"testing_tracker\""}};

    [self.tracker set:kGAIScreenName
                value:@"Home Screen"];


    [[self.mockAnalytics expect] addEvent:[OCMArg checkWithBlock:^BOOL(id obj) {
        if (![obj isKindOfClass:[UACustomEvent class]]) {
            return NO;
        }

        UACustomEvent *event = obj;
        eventData = event.data;

        // cid is generated, so don't compare to static expected value
        NSMutableDictionary *properties = [eventData valueForKey:@"properties"];
        [properties removeObjectForKey:@"&cid"];

        return [eventData isEqualToDictionary:expectedEventData];
    }]];

    [self.tracker send:[[GAIDictionaryBuilder createScreenView] build]];

    XCTAssertNoThrow([self.mockAnalytics verify], @"Event parameters should match");
}

/**
 Tests Standard GA Event.
 **/
- (void)testStandardGAEvent {

    __block NSDictionary *eventData;
    // These values are escaped instead of JSON decoded for convenience
    __block NSDictionary *expectedEventData = @{@"event_name" : kGAIEvent,
                                                @"properties": @{@"&an" : @"\"UrbanAirship-iOS-GA-Tracker_Example\"",
                                                                 @"&ea" : @"\"button_press\"",
                                                                 @"&ec" : @"\"ui_action\"",
                                                                 @"&el" : @"\"play\"",
                                                                 @"&ev" : @"\"1\"",
                                                                 @"&tid" : @"\"testing_tracker\""}};

    // This screen name value will remain set on the tracker and sent with
    // hits until it is set to a new value or to nil.
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

    XCTAssertNoThrow([self.mockAnalytics verify], @"Event parameters should match");
}

/**
 Tests Social Event.
 **/
- (void)testSocialEvent {

    __block NSDictionary *eventData;
    // These values are escaped instead of JSON decoded for convenience
    __block NSDictionary *expectedEventData = @{@"event_name" : kGAISocial,
                                                @"properties": @{@"&an" : @"\"UrbanAirship-iOS-GA-Tracker_Example\"",
                                                                 @"&sa" : @"\"Tweet\"",
                                                                 @"&sn" : @"\"Twitter\"",
                                                                 @"&st" : @"\"https:\\/\\/developers.google.com\\/analytics\"",
                                                                 @"&tid" : @"\"testing_tracker\""}};

    NSString *targetUrl = @"https://developers.google.com/analytics";

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

    [self.tracker send:[[GAIDictionaryBuilder createSocialWithNetwork:@"Twitter"
                                                               action:@"Tweet"
                                                               target:targetUrl] build]];

    XCTAssertNoThrow([self.mockAnalytics verify], @"Event parameters should match");
}

/**
 Tests Transaction Event.
 **/
- (void)testTransactionEvent {

    __block NSDictionary *eventData;
    // These values are escaped instead of JSON decoded for convenience
    __block NSDictionary *expectedEventData = @{@"event_name" : kGAITransaction,
                                                @"properties": @{@"&an" : @"\"UrbanAirship-iOS-GA-Tracker_Example\"",
                                                                 @"&cu" : @"\"USD\"",
                                                                 @"&ta" : @"\"In-app Store\"",
                                                                 @"&ti" : @"\"0_123456\"",
                                                                 @"&tid" :@"\"testing_tracker\"",
                                                                 @"&tr" : @"\"2.16\"",
                                                                 @"&ts" : @"\"0\"",
                                                                 @"&tt" : @"\"0.17\""}};

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

    [self.tracker send:[[GAIDictionaryBuilder createTransactionWithId:@"0_123456"
                                                          affiliation:@"In-app Store"
                                                              revenue:@2.16F
                                                                  tax:@0.17F
                                                             shipping:@0
                                                         currencyCode:@"USD"] build]];

    XCTAssertNoThrow([self.mockAnalytics verify], @"Event parameters should match");
}

/**
 Tests Item Event.
 **/
- (void)testItemEvent {

    __block NSDictionary *eventData;
    // These values are escaped instead of JSON decoded for convenience
    __block NSDictionary *expectedEventData = @{@"event_name" : kGAIItem,
                                                @"properties": @{@"&an" : @"\"UrbanAirship-iOS-GA-Tracker_Example\"",
                                                                 @"&ic" : @"\"L_789\"",
                                                                 @"&in" : @"\"Space Expansion\"",
                                                                 @"&ip" : @"\"1.9\"",
                                                                 @"&iq" : @"\"1\"",
                                                                 @"&iv" : @"\"Game expansions\"",
                                                                 @"&tid" : @"\"testing_tracker\""}};

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

    [self.tracker send:[[GAIDictionaryBuilder createItemWithTransactionId:@"0_123456"
                                                                     name:@"Space Expansion"
                                                                      sku:@"L_789"
                                                                 category:@"Game expansions"
                                                                    price:@1.9F
                                                                 quantity:@1
                                                             currencyCode:@"USD"] build]];


    XCTAssertNoThrow([self.mockAnalytics verify], @"Event parameters should match");
}

/**
 Tests Exception Event.
 **/
- (void)testExceptionEvent {

    __block NSDictionary *eventData;
    // These values are escaped instead of JSON decoded for convenience
    __block NSDictionary *expectedEventData = @{@"event_name" : kGAIException,
                                                @"properties": @{@"&an" : @"\"UrbanAirship-iOS-GA-Tracker_Example\"",
                                                                 @"&exd" : @"\"Connection timeout\"",
                                                                 @"&exf" : @"\"0\"",
                                                                 @"&tid" : @"\"testing_tracker\""}};

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

    [self.tracker send:[[GAIDictionaryBuilder
                         createExceptionWithDescription:@"Connection timeout"
                         withFatal:@NO] build]];

    XCTAssertNoThrow([self.mockAnalytics verify], @"Event parameters should match");
}

/**
 Tests Timing Event.
 **/
- (void)testTimingEvent {

    __block NSDictionary *eventData;
    // These values are escaped instead of JSON decoded for convenience
    __block NSDictionary *expectedEventData = @{@"event_name" : kGAITiming,
                                                @"properties": @{@"&an" : @"\"UrbanAirship-iOS-GA-Tracker_Example\"",
                                                                 @"&tid" : @"\"testing_tracker\"",
                                                                 @"&utc" : @"\"resources\"",
                                                                 @"&utl" : @"null",
                                                                 @"&utt" : @"\"1000\"",
                                                                 @"&utv" : @"\"high scores\""}};

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

    [self.tracker send:[[GAIDictionaryBuilder createTimingWithCategory:@"resources"
                                                              interval:@((NSUInteger)(1000))
                                                                  name:@"high scores"
                                                                 label:nil] build]];

    XCTAssertNoThrow([self.mockAnalytics verify], @"Event parameters should match");
}


/**
 Tests creating a default event.
 **/
- (void)testDefaultEventCreation {

    __block NSDictionary *eventData;
    // These values are escaped instead of JSON decoded for convenience
    __block NSDictionary *expectedEventData = @{@"event_name" : kGAIEvent,
                                                @"properties": @{@"&an" : @"\"UrbanAirship-iOS-GA-Tracker_Example\"",
                                                                 @"&ea" : @"\"button_press\"",
                                                                 @"&ec" : @"\"ui_action\"",
                                                                 @"&el" : @"\"play\"",
                                                                 @"&ev" : @"\"1\"",
                                                                 @"&tid" : @"\"testing_tracker\""}};

    // This screen name value will remain set on the tracker and sent with
    // hits until it is set to a new value or to nil.
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

    XCTAssertNoThrow([self.mockAnalytics verify], @"Event parameters should match");
}

/**
 Tests creating an event with the event creation block.
 **/
- (void)testBlockCreatedEventCreation {

    __block NSDictionary *expectedEventData =  @{@"event_name" : @"testEventName",
                                                 @"properties" : @{@"testPropertyKey": @"\"testPropertyValue\""}};

    // This screen name value will remain set on the tracker and sent with
    // hits until it is set to a new value or to nil.
    [self.tracker set:kGAIScreenName
                value:@"Home Screen"];

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

    XCTAssertNoThrow([self.mockAnalytics verify], @"Event parameters should match");
}

/**
 Tests customizing an event with the event customization block.
 **/
- (void)testBlockCustomizedEventCreation {

    __block NSDictionary *eventData;

    __block NSDictionary *expectedEventData =  @{@"event_name" : kGAIScreenView,
                                                 @"properties" : @{@"&an" : @"\"UrbanAirship-iOS-GA-Tracker_Example\"",
                                                                   @"&cd" : @"\"Home Screen\"",
                                                                   @"&tid" : @"\"testing_tracker\"",
                                                                   @"testPropertyKey" : @"\"testPropertyValue\""}};

    // This screen name value will remain set on the tracker and sent with
    // hits until it is set to a new value or to nil.
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

    XCTAssertNoThrow([self.mockAnalytics verify], @"Event parameters should match");
}

/**
 Tests sending when GA tracker is disabled.
 **/
- (void)testSendGADisabled {

    id mockGATracker = [OCMockObject partialMockForObject:self.tracker.GATracker];

    //Test that no send call is made when GA forwarding is disabled
    self.tracker.googleAnalyticsEnabled = NO;

    // Attempt to send dummy screen event
    [self.tracker set:kGAIScreenName
                value:@"Home Screen"];

    [[mockGATracker reject] send:OCMOCK_ANY];
    [[self.mockAnalytics reject] addEvent:OCMOCK_ANY];

    [mockGATracker verify];
    [mockGATracker stopMocking];
}

/**
 Tests sending when GA tracker is enabled.
 **/
- (void)testSendGoogleAnalyticsEnabled {

    id mockGATracker = [OCMockObject partialMockForObject:self.tracker.GATracker];

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

