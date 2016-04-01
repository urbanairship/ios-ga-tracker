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

#import <Foundation/Foundation.h>
#import "GAITracker.h"
#import "UACustomEvent.h"

NS_ASSUME_NONNULL_BEGIN

@interface UATracker : NSObject <GAITracker>

/*!
 Enable Urban Airship tracking for GA events. Default is true.
 */
@property (nonatomic, assign) BOOL UATrackerEnabled;

/*!
 Enable Google analytics event tracking. Default is true.
 */
@property (nonatomic, assign) BOOL GAEnabled;

/*!
 Name of this tracker.
 */
@property(nonatomic, readonly) NSString *name;

/*!
 Allow collection of IDFA and related fields if set to true.  Default is false.
 */
@property(nonatomic) BOOL allowIDFACollection;

@property (nonatomic, copy, nullable) UACustomEvent * (^creationBlock)(NSDictionary *parameters, NSObject<GAITracker> *tracker);

@property (nonatomic, copy, nullable) void (^customizationBlock)(UACustomEvent *customEvent,  NSObject<GAITracker> *tracker);

/*!
 Set a tracking parameter.

 @param parameterName The parameter name.

 @param value The value to set for the parameter. If this is nil, the
 value for the parameter will be cleared.
 */
- (void)set:(NSString *)parameterName
      value:(NSString *)value;

/*!
 Get a tracking parameter.

 @param parameterName The parameter name.

 @returns The parameter value, or nil if no value for the given parameter is
 set.
 */
- (NSString *)get:(NSString *)parameterName;

/*!
 Queue tracking information with the given parameter values.

 @param parameters A map from parameter names to parameter values which will be
 set just for this piece of tracking information, or nil for none.
 */
- (void)send:(NSDictionary *)parameters;

NS_ASSUME_NONNULL_END

@end
