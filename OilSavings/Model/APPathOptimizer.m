//
//  APPathOptimizer.m
//  OilSavings
//
//  Created by Andi Palo on 6/7/14.
//  Copyright (c) 2014 Andi Palo. All rights reserved.
//

#import "APPathOptimizer.h"
#import "APGasStation.h"
#import "APDirectionsClient.h"

static const int REQUEST_BUNDLE = 5;
static const int SLEEP_INTERVAL = 250000; // 250ms

@implementation APPathOptimizer

- (id) initWithCar:(APCar*) mycar andDelegate:(id<APNetworkAPI>)dele{
    self = [super init];
    
    if (self) {
        self.car = mycar;
        self.delegate = dele;
        self.paths = [[NSMutableArray alloc]init];
    }
    
    return self;
}

- (void) optimizeRouteFrom:(CLLocationCoordinate2D)src
                        to:(CLLocationCoordinate2D)dst
            hasDestination:(BOOL)hasDest
           withGasStations:(NSArray*)gasStations{
    
    //init paths
    self.src = src;
    self.dst = dst;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self initPathsWithGasStations:gasStations hasDest:hasDest];
    });

}


- (void) initPathsWithGasStations:(NSArray*)gs hasDest:(BOOL)hd{

    APPath *path;
    for (APGasStation* g in gs) {
        if (!hd) {
            path = [[APPath alloc]initWith:self.src andGasStation:g];
        }else{
            path = [[APPath alloc]initWith:self.src and:self.dst andGasStation:g];
        }
        [self.paths addObject:path];
    }
    //sort
    [self.paths sortUsingSelector:@selector(compareAir:)];

    //now we are on global queue and have all paths sorted by air distance
    
    int counter = 1,index = 0;
    
    while (counter < [self.paths count] / REQUEST_BUNDLE + 1) {
//        ALog("External while: counter is %d and index is %d",counter, index);
        
        //save in what batch are;
        self.currentBatch = MIN(counter * REQUEST_BUNDLE, [self.paths count]);
        
        while (index < counter * REQUEST_BUNDLE && index < [self.paths count]) {
//            ALog("Internal while: counter is %d and index is %d",counter, index);
            [APDirectionsClient findDirectionsOfPath:[self.paths objectAtIndex:index] indexOfRequest:index delegateTo:self];
            index++;
        }
        usleep(SLEEP_INTERVAL);
        counter ++;
    }
    
}
- (void) foundPath:(APPath*)path withIndex:(NSInteger)index{
    BOOL bestFound = NO;
    
//    ALog("Found path in optimizer is called with index %d but %d",index, self.currentBatch);
    if ((index == 0) || ([path comparePath:self.bestPath] == NSOrderedAscending)){
        self.bestPath = path;
        bestFound = YES;
    }
    
    if (index == self.currentBatch - 1) {
//        ALog("REporting to map");
        // go on main thread now
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate foundPath:self.bestPath withIndex:0];
        });
    }
}

@end