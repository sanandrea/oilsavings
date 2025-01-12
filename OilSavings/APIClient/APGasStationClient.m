//
//  APGasStationClient.m
//  OilSavings
//
//  Created by Andi Palo on 6/2/14.
//  Copyright (c) 2014 Andi Palo. 
//

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
#import "APGasStationClient.h"
#import "AFNetworking.h"
#import "APNetworkAPI.h"

#warning PUT YOUR REMOTE SERVICE ENDPOINT TO PROVIDE PRICES
static NSString * const BaseURLString = @"";
static NSString * const BaseStationString = @"";

static float const AREA_DISTANCE = 2.5;

@interface APGasStationClient ()


@end

@implementation APGasStationClient


- (id) initWithCenter:(CLLocationCoordinate2D) center andFuel:(ENERGY_TYPE) fuel{
    self = [super init];

    /*
     * http://en.wikipedia.org/wiki/Longitude#Length_of_a_degree_of_longitude
     */
    
    float latDelta = AREA_DISTANCE/111.2;
    
    //a region double in size that that of the map
    self.minLat = center.latitude - latDelta;
    self.maxLat = center.latitude + latDelta;
    

    float longDelta = AREA_DISTANCE/78.847;
    
    self.minLong = center.longitude - longDelta;
    self.maxLong = center.longitude + longDelta;
    
    self.fuel = fuel;
    
    self.gasStations = [[NSMutableArray alloc]init];

    return self;
}

- (void)getStations{
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];

    
    [manager.requestSerializer setValue:@"application/json;charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [manager.requestSerializer setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X-Requested-With"];
    
    NSArray* objs = [[NSArray alloc] initWithObjects:
                     [NSNumber numberWithDouble:self.minLat],
                     [NSNumber numberWithDouble:self.minLong],
                     [NSNumber numberWithDouble:self.maxLat],
                     [NSNumber numberWithDouble:self.maxLong],
                     [APConstants getEnergyStringForType:self.fuel],
                     [NSNumber numberWithInt:1],
                     @"",
                     @"getStations",
                     nil];
    NSArray* keys = [[NSArray alloc] initWithObjects:
                     @"min_lat",
                     @"min_long",
                     @"max_lat",
                     @"max_long",
                     @"fuels",
                     @"compact",
                     @"brand",
                     @"sel",
                     nil];
    
    NSDictionary *urlParams = [NSDictionary dictionaryWithObjects:objs forKeys:keys];
//    ALog("Query dict %@",urlParams);
    
    [manager GET:BaseURLString parameters:urlParams success:^(AFHTTPRequestOperation *operation, id responseObject) {
        // Process Response Object
        NSArray *response = (NSArray *)responseObject;
        APGasStation *gs;
        for (NSDictionary *dict in response) {
//            ALog("General price is %@",dict[@"price"]);
            if ([[dict objectForKey:@"price" ] length] == 0){
                continue;
            }
//            ALog("dict is %@",dict);
            gs = [[APGasStation alloc]initWithDict:dict andFuelType:self.fuel];
            [self.gasStations addObject:gs];
        }
        [self.delegate gasStation:self didFinishWithStations:YES];
        
        for (APGasStation *ags in self.gasStations) {
            [APGasStationClient getDetailsOfGasStation:ags intoDict:nil];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Handle Error
        [self .delegate gasStation:self didFinishWithStations:NO];
    }];
}
+ (void) getDetailsOfGasStation:(APGasStation*)gst intoDict:(void (^)(NSDictionary*))result{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    
    
    [manager.requestSerializer setValue:@"application/json;charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [manager.requestSerializer setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X-Requested-With"];
    
//    ALog("Gas station Id is %lu",(unsigned long)gst.gasStationID);
    
    NSArray* objs = [[NSArray alloc] initWithObjects:
                     [NSNumber numberWithUnsignedInteger:gst.gasStationID],
                     @"getStation",
                     nil];
    NSArray* keys = [[NSArray alloc] initWithObjects:
                     @"idstation",
                     @"sel",
                     nil];
    NSDictionary *urlParams = [NSDictionary dictionaryWithObjects:objs forKeys:keys];
    //    ALog("Query dict %@",urlParams);
    
    [manager GET:BaseStationString parameters:urlParams success:^(AFHTTPRequestOperation *operation, id responseObject) {
        // Process Response Object
        NSArray *objects = (NSArray *)responseObject;
        if ([objects count] == 0) {
            return;
        }
        NSDictionary *gasStationInfo = (NSDictionary*) objects[0];
        
        gst.street = gasStationInfo[@"address"];
        gst.postalCode = gasStationInfo[@"street_code"];
        NSArray *fuels = gasStationInfo[@"fuels"];
        NSMutableDictionary *availableFuels = [[NSMutableDictionary alloc]init];
        for (NSDictionary* fuelInfo in fuels) {
//            ALog("Fuel info is %@",fuelInfo);
            if ([fuelInfo[@"active"] intValue] == 1) {
                //key is fuel_descr and object is the enum ENERGY_TYPE translated from fuel_value
                [availableFuels setObject:[NSNumber numberWithInt:[APConstants getEnergyTypeForString:fuelInfo[@"fuel_value"]]] forKey:fuelInfo[@"fuel_descr"]];
            }
        }
        
//        ALog("Available fuels are: %@",availableFuels);
        for (NSDictionary *report in gasStationInfo[@"reports"]) {
//            ALog("Report is: %@",report);
            NSNumber *tt = [availableFuels objectForKey:report[@"fuel_descr"]];
            if (tt != nil) {
                [gst setPrice:[report[@"price"] floatValue] forEnergyType:[tt intValue]];
            }
        }
        
        
        //Debug
        /*
        for (int i = 0; i < ENERGIES_COUNT; i++) {
            ALog("Energy price: %4.3f", [gst getPrice:(ENERGY_TYPE)i]);
        }
        */

    }failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Handle Error
#warning Handle error
    }];
}

@end
