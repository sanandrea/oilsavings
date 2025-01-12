// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

//
//  APAppDelegate.m
//  OilSavings
//
//  Created by Andi Palo on 5/23/14.
//  Copyright (c) 2014 Andi Palo. All rights reserved.
//

#import "APAppDelegate.h"
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>
#import <AFNetworkActivityLogger.h>
#import "SWRevealViewController.h"
#import "APCar.h"
#import "GAI.h"

@implementation APAppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    NSArray* objs = [[NSArray alloc] initWithObjects:
                     @(NO),
                     [NSNumber numberWithInt:1],//DB Version
                     [NSNumber numberWithInt:1],//Resource Version
                     [NSNumber numberWithInt:0],//Number of Cars
                     [NSNumber numberWithInt:-1],//Preferred Car Model ID
                     [NSNumber numberWithInt:20],//Default Cash Amount
                     [NSNumber numberWithInt:40],//Default tank Capacity
                     nil];
    NSArray* keys = [[NSArray alloc] initWithObjects:
                     kDBDowloaded,
                     kDBVersion,
                     kResVersion,
                     kCarsRegistered,
                     kPreferredCar,
                     kCashAmount,
                     kDefaultTankCapacity,
                     nil];
    
    NSDictionary *appDefaults = [NSDictionary dictionaryWithObjects:objs forKeys:keys];
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
    
    
    
    //This will automatically show the network activity indicator whenever AFNetworking is performing network requests.
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    
    //Enable Network Logging
//    [[AFNetworkActivityLogger sharedLogger] startLogging];
//    [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelDebug];
    
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    if ([[prefs objectForKey:kCarsRegistered] integerValue] == 0) {
        //Add the default Car
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        if ([[prefs objectForKey:kCarsRegistered] integerValue] == 0) {
            APCar *newCar = (APCar *)[NSEntityDescription insertNewObjectForEntityForName:@"Car"
                                                                   inManagedObjectContext:self.managedObjectContext];
            newCar.friendlyName = @"Alfa";
            newCar.brand = @"Alfa Romeo";
            newCar.model = @"Giuletta 1.6 JTDM (105 HP) Start&Stop";
            newCar.energy = [NSNumber numberWithInt:kEnergyGasoline];
            newCar.modelID = [NSNumber numberWithInt:8240];
            newCar.pA = [NSNumber numberWithFloat:31.573];
            newCar.pB = [NSNumber numberWithFloat:2.972];
            newCar.pC = [NSNumber numberWithFloat:-0.0016406];
            newCar.pD = [NSNumber numberWithFloat:0.0000577];
            
            [prefs setInteger:1 forKey:kCarsRegistered];
            [prefs setInteger:[newCar.modelID intValue] forKey:kPreferredCar];
            [prefs synchronize];
            
        }
        NSError *error;
        
        if (![self.managedObjectContext save:&error]) {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
    
    //Override point for customization after application launch.
    [GAI sharedInstance].dispatchInterval = 120;
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    
    //careful here before release set to NO
    if (kDEBUG == 1) {
        [[GAI sharedInstance] setDryRun:YES];
    }else if (kDEBUG == 0){
        [[GAI sharedInstance] setDryRun:NO];
    }
    
    //    [[GAI sharedInstance].logger setLogLevel:kGAILogLevelVerbose];
    
    self.tracker = [[GAI sharedInstance] trackerWithName:@"Clubs"
                                              trackingId:kTrackingID];
    
    // Change the background color of navigation bar
    [[UINavigationBar appearance] setBarTintColor:[UIColor whiteColor]];
    
    // Change the font style of the navigation bar
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];
    shadow.shadowOffset = CGSizeMake(0, 0);
    [[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [UIColor colorWithRed:10.0/255.0 green:10.0/255.0 blue:10.0/255.0 alpha:1.0], NSForegroundColorAttributeName,
                                                           shadow, NSShadowAttributeName,
                                                           [UIFont fontWithName:@"Helvetica-Light" size:21.0], NSFontAttributeName, nil]];
    return YES;
}

							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"OilSavings" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"OilSavings.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];

         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
