//
//  HTTPClient.h
//  MyWeather
//
//  Created by Daniel Lundqvist on 2019-02-28.
//  Copyright © 2019 Daniel Lundqvist. All rights reserved.
//

#import "AFHTTPSessionManager.h"
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HTTPClientDelegate;

@interface HTTPClient : AFHTTPSessionManager

@property (nonatomic) id<HTTPClientDelegate>delegate;

+ (instancetype)sharedHTTPClient;
- (void)fetchWeatherForLocation:(CLLocation *)location;

@end

@protocol HTTPClientDelegate <NSObject>
- (void)didUpdateTemperatureString:(NSString *)temperatureString;
- (void)didUpdateSymbolUrlString:(NSString *)iconUrl;
@end

NS_ASSUME_NONNULL_END
