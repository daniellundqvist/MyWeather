//
//  MyWeatherViewController.m
//  MyWeather
//
//  Created by Daniel Lundqvist on 2019-02-28.x
//  Copyright © 2019 Daniel Lundqvist. All rights reserved.
//

#import "MyWeatherViewController.h"
#import "HTTPClient.h"
#import "UIImageView+AFNetworking.h"
#import <CoreLocation/CoreLocation.h>

@interface MyWeatherViewController () <HTTPClientDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) IBOutlet UIImageView *weatherIconImageView;
@property (strong, nonatomic) IBOutlet UILabel *temperatureLabel;
@property (nonatomic) HTTPClient *httpClient;
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) CLLocation *lastLocation;
@property (nonatomic) NSTimer *timer;
@property (nonatomic) NSDate *lastUpdate;
@property (nonatomic) BOOL needsUpdate;

@end

@implementation MyWeatherViewController

- (void)dealloc {
    [self.timer invalidate];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.httpClient = [HTTPClient sharedHTTPClient];
    self.httpClient.delegate = self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(appDidEnterForeground) name:@"appDidEnterForeground" object:nil];
    
    self.locationManager = [CLLocationManager new];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.delegate = self;
    [self.locationManager requestAlwaysAuthorization];
    [self.locationManager startUpdatingLocation];
    
    // Add and start timer
    self.timer = [NSTimer timerWithTimeInterval:60.0f target:self selector:@selector(timerTriggered) userInfo:nil repeats:YES];
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [runLoop addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)appDidEnterForeground {
    self.needsUpdate = YES;
}

#pragma mark - HTTPClientDelegate

- (void)didUpdateTemperatureString:(NSString *)temperatureString {
    self.temperatureLabel.text = temperatureString;
    self.lastUpdate = [NSDate new];
}

- (void)didUpdateSymbolUrlString:(NSString *)iconUrl {
    NSURL *url = [NSURL URLWithString:iconUrl];
    [self.weatherIconImageView setImageWithURL:url];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *location = locations.firstObject;
    
    if (!self.lastLocation && location) {
        self.lastLocation = location;
        [self.httpClient fetchWeatherForLocation: location];
    } else if (self.lastLocation && location) {
        if ([self.lastLocation distanceFromLocation:location] > 500.0f || self.needsUpdate) {
            self.needsUpdate = NO;
            self.lastLocation = location;
            [self.httpClient fetchWeatherForLocation: location];
        }
    }
}

- (void)timerTriggered {
    if ([self.lastUpdate timeIntervalSinceNow] < -300.0f) {
        self.needsUpdate = YES;
    }
}

@end
