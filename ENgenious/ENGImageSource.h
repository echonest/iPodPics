//
//  ENGImageSource.h
//  ENgenious
//
//  Created by Paul Lamere on 6/26/13.
//  Copyright (c) 2013 Paul Lamere. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ENGImageSource : NSObject

- (void) getImagesForArtist:(NSString *) artistName
                      start: (int) start
                      count: (int) count
                   whenDone: (void (^)(int start, int count, int total, NSMutableArray *images)) complete;

@end
