//
//  HTTPClient.m
//  MyWeather
//
//  Created by Daniel Lundqvist on 2019-02-28.
//  Copyright © 2019 Daniel Lundqvist. All rights reserved.
//

#import "HTTPClient.h"

static NSString * const BaseUrlString = @"https://api.met.no/weatherapi/";

@interface HTTPClient () <NSXMLParserDelegate>

@property (nonatomic) BOOL hasFirstTemperatureValue;
@property (nonatomic) BOOL hasFirstIconValue;

@end

@implementation HTTPClient

+ (instancetype)sharedHTTPClient {
    static dispatch_once_t onceToken;
    static HTTPClient *sharedHTTPClient;
    
    dispatch_once(&onceToken, ^{
        sharedHTTPClient = [[HTTPClient alloc] initWithBaseURL:[NSURL URLWithString:BaseUrlString]];
    });
    
    return sharedHTTPClient;
}

- (instancetype)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    
    if (self) {
        self.requestSerializer = [AFJSONRequestSerializer serializer];
        self.responseSerializer = [AFXMLParserResponseSerializer serializer];
    }
    
    return self;
}

- (void)fetchWeatherForLocation:(CLLocation *)location {
    NSString* urlString = [NSString stringWithFormat:@"locationforecast/1.9/?lat=%f&lon=%f", location.coordinate.latitude, location.coordinate.longitude];
    [self GET:urlString parameters:nil headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSXMLParser *XMLParser = (NSXMLParser *)responseObject;
        [XMLParser setShouldProcessNamespaces:YES];
        XMLParser.delegate = self;
        [XMLParser parse];
    } failure: nil];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    
    // Temperature data
    if([qName isEqualToString:@"temperature"]) {
        NSString *temperature = attributeDict[@"value"];
        NSString *unit = attributeDict[@"unit"];
        
        if (!self.self.hasFirstTemperatureValue && temperature.length > 0) {
            NSString *temperatureString = [NSString stringWithFormat:@"%@° %@", temperature, unit];
            
            if ([self.delegate respondsToSelector:@selector(didUpdateTemperatureString:)]) {
                self.hasFirstTemperatureValue = YES;
                [self.delegate didUpdateTemperatureString:temperatureString];
            }
        }
    }
    
    // Icon data
    if ([qName isEqualToString:@"symbol"]) {
        NSString *number = attributeDict[@"number"];
        
        if (!self.hasFirstIconValue && number.length > 0) {
            if ([self.delegate respondsToSelector:@selector(didUpdateSymbolUrlString:)]) {
                self.hasFirstIconValue = YES;
                NSString *urlString = [NSString stringWithFormat:@"https://api.met.no/weatherapi/weathericon/1.1/?symbol=%@&content_type=image/png", number];
                [self.delegate didUpdateSymbolUrlString:urlString];
            }
        }
    }
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    self.hasFirstTemperatureValue = self.hasFirstIconValue = NO;
}

@end
