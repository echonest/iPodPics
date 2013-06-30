//
//  ENGDetailViewController.m
//  ENgenious
//
//  Created by Paul Lamere on 6/25/13.
//  Copyright (c) 2013 Paul Lamere. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "ENGDetailViewController.h"
#import "ENAPI.h"
#import "ENGimageSource.h"
#import "UIImageView+AFNetworking.h"


@interface ENGDetailViewController ()
- (void)configureView;

@property (nonatomic, readwrite, strong)  MPMusicPlayerController * iPod;
@property (nonatomic, readwrite, strong)  ENGImageSource *imageSource;
@property (nonatomic, readwrite, strong)  NSString *curArtist;
@property (nonatomic, readwrite, strong)  NSArray *artistImages;
@property (nonatomic, readwrite)  int curIndex;
@property (nonatomic, readwrite, strong)  NSTimer *slideShowTimer;
@property (nonatomic, readwrite)  float secondsPerSlide;
@property (nonatomic, readwrite) CGFloat rotation;
@end

@implementation ENGDetailViewController

#pragma mark - Managing the detail item

- (void)configureView
{
    self.secondsPerSlide = 5;
    self.iPod = [MPMusicPlayerController iPodMusicPlayer];
    self.imageSource = [[ENGImageSource alloc] init];
    [self setupNotifications];
    [self startShowingImages];
}


- (void) setupNotifications {
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver: self
                           selector: @selector (handleNowPlayingItemChanged:)
                               name: MPMusicPlayerControllerNowPlayingItemDidChangeNotification
                             object: self.iPod];
    
    [notificationCenter
        addObserver: self
        selector:    @selector (handlePlaybackStateChanged:)
        name:        MPMusicPlayerControllerPlaybackStateDidChangeNotification
        object:      self.iPod];
   
    [self.iPod beginGeneratingPlaybackNotifications];
}

- (void) handleNowPlayingItemChanged:(NSNotification *) notification {
    [self checkForNewArtist];
}

- (void) checkForNewArtist {
    MPMediaItem *nowPlayingMediaItem = [self.iPod nowPlayingItem];
    NSString *artist = [nowPlayingMediaItem valueForProperty:MPMediaItemPropertyArtist];
    if (artist && ![artist isEqualToString:self.curArtist]) {
        NSLog(@"Now playing artist: %@", artist);
        self.curArtist = artist;
        [self loadImagesForNewArtist];
    }
}

- (void) loadImagesForNewArtist {
    NSLog(@"loading images for new artist");
    [self.imageSource getImagesForArtist:self.curArtist start:0 count:100
                                whenDone:^(int start, int count, int total, NSMutableArray *images) {
                                    self.curIndex = 0;
                                    [self shuffle:images];
                                    self.artistImages = images;
                                }];
}

-  (void)shuffle:(NSMutableArray *) arry {
    NSUInteger count = [arry count];
    for (NSUInteger i = 0; i < count; ++i) {
        // Select a random element between i and end of array to swap with.
        NSInteger nElements = count - i;
        NSInteger n = (arc4random() % nElements) + i;
        [arry exchangeObjectAtIndex:i withObjectAtIndex:n];
    }
}

- (void) startShowingImages {
    if (!self.slideShowTimer) {
        self.slideShowTimer = [NSTimer scheduledTimerWithTimeInterval:self.secondsPerSlide target:self
                                                             selector:@selector(showNextImage) userInfo:nil repeats:YES];
    }
}

- (void) stopShowingImages {
    [self.slideShowTimer invalidate];
    self.slideShowTimer = nil;
}


- (void) showNextImage {
    if ([self.artistImages count] > 0) {
        if (self.curIndex >= [self.artistImages count]) {
            self.curIndex = 0;
        }
        NSURL *nextImageURL = self.artistImages[self.curIndex++];
        UIImage *curImage = self.theImage.image;
        NSURLRequest *request = [NSURLRequest requestWithURL:nextImageURL];
        [self.theImage setImageWithURLRequest:request placeholderImage:curImage
                               success: ^(NSURLRequest *request , NSHTTPURLResponse *response , UIImage *image) {
                                   [UIView transitionWithView:self.theImage
                                                     duration:0.5f
                                                      options:UIViewAnimationOptionTransitionCrossDissolve
                                                   animations:^{
                                                       self.theImage.image = image;
                                                   } completion:nil];
                                   
                                   float wscale = image.size.width / self.theImage.bounds.size.width;
                                   float hscale = image.size.height / self.theImage.bounds.size.height;
                                   float uscale;
                                   
                                   if (wscale > hscale) {
                                       uscale = wscale / hscale;
                                   } else {
                                       uscale = hscale / wscale;
                                   }
                                   
                                   if (self.curIndex % 2 == 0) {
                                       uscale = 1;
                                   }
                                   
                                   
                                   CGAffineTransform xform = CGAffineTransformMakeScale(uscale, uscale);
                                   xform = CGAffineTransformRotate(xform, self.rotation);
                                   float delay = .5;
                                   [UIView animateWithDuration:self.secondsPerSlide - delay * 2
                                                         delay:delay
                                                       options: UIViewAnimationOptionBeginFromCurrentState  | UIViewAnimationOptionCurveEaseInOut
                                                    animations:(void (^)(void)) ^{
                                                        self.theImage.transform=xform;
                                                    }
                                                    completion:^(BOOL finished){
                                                        //self.theImage.transform=CGAffineTransformIdentity;
                                                    }];
                                   
                               }
                              
                               failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                   NSLog(@"failure");
                               }];
    }
    [self checkForNewArtist];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureView];
}

- (void) handlePlaybackStateChanged:(NSNotification *) notification {
    if (self.iPod.playbackState == MPMusicPlaybackStatePlaying) {
        NSLog(@"Running");
        [self startShowingImages];
    } else if (self.iPod.playbackState == MPMusicPlaybackStateStopped ||
               self.iPod.playbackState == MPMusicPlaybackStatePaused) {
        [self stopShowingImages];
        NSLog(@"Stopped");
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation) fromInterfaceOrientation {
    switch (self.interfaceOrientation) {
        
        case UIInterfaceOrientationPortrait: {
            self.rotation = 0;
            break;
        }
            
        case UIInterfaceOrientationPortraitUpsideDown:{
            self.rotation =  M_PI;
            break;
            
        }
            
        case UIInterfaceOrientationLandscapeLeft: {
            self.rotation =  -M_PI_2;
            break;
            
        }
            
        case UIInterfaceOrientationLandscapeRight: {
            self.rotation =  M_PI_2;
            break;
        }
    }
}

@end
