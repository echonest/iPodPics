//
//  ENGImageSource.m
//  ENgenious
//
//  Created by Paul Lamere on 6/26/13.
//  Copyright (c) 2013 Paul Lamere. All rights reserved.
//

#import "ENGImageSource.h"
#import "ENAPI.h"

@implementation ENGImageSource


- (void) getImagesForArtist:(NSString *) artistName
                      start: (int) start
                      count:(int) count
                   whenDone: (void (^)(int, int, int, NSMutableArray *)) complete {
    
    NSDictionary * parameters = @{
                                  @"name": artistName,
                                  @"start" : [NSNumber numberWithInteger:start],
                                  @"results": [NSNumber numberWithInteger:count]
                                  };
    
    [ENAPIRequest GETWithEndpoint:@"artist/images"
                    andParameters:parameters
               andCompletionBlock:^(ENAPIRequest *request) {
                   NSMutableArray *urls = [[NSMutableArray alloc] init];
                   NSDictionary *response = request.response[@"response"];
                   int total = [response[@"total"] integerValue];
                   NSLog(@"Got %d of %d images for %@", [response[@"images"] count], total, artistName);
                   for (NSDictionary *image in response[@"images"]) {
                       NSString *surl = image[@"url"];
                       if ([self goodUrl:surl]) {
                           NSURL *url = [[NSURL alloc] initWithString:surl];
                           [urls addObject:url];
                       }
                   }
                   complete(start, count, total, urls);
               }];
}

- (BOOL) goodUrl:(NSString *) surl {
    if ([surl rangeOfString:@"wiki"].location != NSNotFound) {
        NSLog(@"Dropped %@", surl);
        return NO;
    }
    return YES;
}

@end
