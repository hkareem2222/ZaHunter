//
//  ViewController.m
//  ZaHunter
//
//  Created by Husein Kareem on 5/28/15.
//  Copyright (c) 2015 Husein Kareem. All rights reserved.
//

#import "ViewController.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "Pizzeria.h"

@interface ViewController () <CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property CLLocationManager *locationManager;
@property NSMutableArray *pizzaStores;
@property Pizzeria *pizzeria;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UITableView *pizzaPlaceTable;
@property NSIndexPath *indexPath;
@property (weak, nonatomic) IBOutlet UITextView *timeTextView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    [self.locationManager requestWhenInUseAuthorization];
    [self.locationManager startUpdatingLocation];
    self.pizzaStores = [[NSMutableArray alloc] init];
    self.pizzeria = [Pizzeria new];
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"%@", error);
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    for (CLLocation *location in locations) {
        if (location.verticalAccuracy < 1000 && location.horizontalAccuracy < 1000) {
            NSLog(@"user located");
            [self reverseGeoCode:location];
            [self.locationManager stopUpdatingLocation];
        }
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    return self.pizzaStores.count;
    return self.pizzaStores.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"pizzaID"];
    Pizzeria *pizzaStore = [Pizzeria new];
    pizzaStore = self.pizzaStores[indexPath.row];
    cell.textLabel.text = pizzaStore.name;
    CLLocationDistance distanceMiles = [pizzaStore.placemark.location distanceFromLocation:self.locationManager.location] / 1609.34;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2f miles", distanceMiles];
    return cell;
}
//-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//
//}

-(void)reverseGeoCode:(CLLocation *)location {
    CLGeocoder *geoCoder = [CLGeocoder new];
    [geoCoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
            CLPlacemark *placemark = placemarks.firstObject;
//            Pizzeria *pizzaStore = [Pizzeria new];
//            pizzaStore.name = placemark.locality;
//            [self.pizzaStores addObject:pizzaStore];
            [self findPizzaPlace:placemark.location];
    }];
}

-(void)findPizzaPlace:(CLLocation *)location {
        MKLocalSearchRequest *request = [MKLocalSearchRequest new];

        request.naturalLanguageQuery = @"Pizza";
        request.region = MKCoordinateRegionMake(location.coordinate, MKCoordinateSpanMake(1, 1));

        MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];

        [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
            NSArray *mapItems = response.mapItems;
            Pizzeria *pizzaStore = [Pizzeria new];
            for (int i = 0; i < 4; i++) {
                pizzaStore = mapItems[i];
                [self.pizzaStores addObject:pizzaStore];
            }
            [self.pizzaPlaceTable reloadData];
        }];
}

- (IBAction)onRouteButtonPressed:(UIButton *)sender {
    [self getDirectionsTo:[self.pizzaStores objectAtIndex:self.indexPath.row]];

}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.indexPath = indexPath;
}


-(void)getDirectionsTo:(MKMapItem *)destinationItem {
    MKDirectionsRequest *request = [MKDirectionsRequest new];
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        request.transportType = MKDirectionsTransportTypeWalking;
    } else if (self.segmentedControl.selectedSegmentIndex == 1) {
        request.transportType = MKDirectionsTransportTypeAutomobile;
    }
    request.source = [MKMapItem mapItemForCurrentLocation];
    request.destination = destinationItem;
    NSMutableString *directionString = [NSMutableString new];

    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        NSArray *routes = response.routes;
        MKRoute *route = routes.firstObject;
    
        NSTimeInterval routeTime = route.expectedTravelTime;
        NSLog(@"route time: %f", routeTime);
        CLLocationDistance routeDistance = route.distance;
        NSLog(@"route distance: %f", routeDistance);
        int x = 1;
        double metersPerMin = routeDistance/(routeTime/60);
        for (MKRouteStep *step in route.steps) {
            NSLog(@"%@", step.instructions);
                [directionString appendFormat:@"%d: %.2f min %@\n", x, step.distance/metersPerMin, step.instructions];
            x++;
        }
        self.textView.text = directionString;
    }];
}
@end
