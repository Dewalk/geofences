//
//  ViewController.m
//  GeoFencesCoupon
//
//  Created by Dawn E. Walker on 1/9/17.
//  Copyright © 2017 Dawn E. Walker. All rights reserved.
//



#import "ViewController.h"
#import "MapKit/MapKit.h"


@interface ViewController () <MKMapViewDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UISwitch *uiSwitch;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *checkStatus;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *eventLabel;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (strong, nonatomic) CLLocationManager *locationManager;

@property (nonatomic, assign) BOOL mapIsMoving;

@property (strong, nonatomic) MKPointAnnotation *currentAnno;
@property (strong, nonatomic) MKPointAnnotation *maisonKayserAnno;

@property (strong, nonatomic) CLCircularRegion *geoRegion;

-(void) showCouponAlert:(NSString *) myCoupon;



@end

@implementation ViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    // Turn off the User Interface until permission is obtained
    self.uiSwitch.enabled = NO;
    self.checkStatus.enabled = NO;
    
    self.mapIsMoving = NO;
    
    
    self.eventLabel.text = @"";
    self.statusLabel.text = @"";
    


    //set up location manager
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    //self.locationManager.allowsBackgroundLocationUpdates = YES;
    self.locationManager.pausesLocationUpdatesAutomatically = YES;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = 3; //meters
    
  
    
    //Zoom the map very close
    CLLocationCoordinate2D noLocation; //This is a dummy variable that does not get used
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(noLocation, 500, 500); // 500 by 500
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:viewRegion];
    [self.mapView setRegion:adjustedRegion animated:YES];
    
    
    //create an annotation for the user's location
    [self addCurrentAnnotation];
    
    //create an annotation for the business' location
    [self addAnnotation];
    
    //Set up a geoRegion object
    [self setUpGeoRegion];

//Check if the device can do geofences/region preferences
    if([CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]] == YES){
        //Regardless of authorization, if hardware can support it set up georegion
        [self setUpGeoRegion];
        
    CLAuthorizationStatus currentStatus = [CLLocationManager authorizationStatus];
    if((currentStatus == kCLAuthorizationStatusAuthorizedWhenInUse) ||
       (currentStatus == kCLAuthorizationStatusAuthorizedAlways)){
                self.uiSwitch.enabled = YES;
            
        }
        else{
            // If not authorized try and get authorization
            [self.locationManager requestAlwaysAuthorization];
            //[self.locationManager requestWhenInUseAuthorization];
        }
        
        //Ask for notification permissions if the app is in the background
        UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
        UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
    }
    else{
        self.statusLabel.text = @"GeoRegions not supported";
    }
    
    }
-(void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{
    CLAuthorizationStatus currentStatus = [CLLocationManager authorizationStatus];
    if((currentStatus == kCLAuthorizationStatusAuthorizedWhenInUse) || (currentStatus == kCLAuthorizationStatusAuthorizedAlways)){
        self.uiSwitch.enabled = YES;
    }

}

-(void) mapView: (MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated{
    self.mapIsMoving = YES;
}

-(void) mapView: (MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    self.mapIsMoving = NO;
}

-(void) setUpGeoRegion{
    //Create the geographic region to be monitored
    self.geoRegion = [[CLCircularRegion alloc]
                      initWithCenter:CLLocationCoordinate2DMake(40.752227,-73.981826)radius:3 identifier:@"MyRegionIdentifier"];
}


- (IBAction)switchTapped:(id)sender {
    if(self.uiSwitch.isOn){
        self.mapView.showsUserLocation = YES;
        [self.locationManager startUpdatingLocation];
        [self.locationManager startMonitoringForRegion:self.geoRegion];
        self.checkStatus.enabled = YES;
         }
         else{
             self.checkStatus.enabled = NO;
             [self.locationManager stopMonitoringForRegion:self.geoRegion];
             [self.locationManager stopUpdatingLocation];
             self.mapView.showsUserLocation = NO;
         }
}

-(void) addCurrentAnnotation{
    self.currentAnno = [[MKPointAnnotation alloc] init];
    self.currentAnno.coordinate = CLLocationCoordinate2DMake(0.0, 0.0);
    self.currentAnno.title = @"My Location";
    }

-(void) addAnnotation{
    self.maisonKayserAnno = [[MKPointAnnotation alloc] init];
    self.maisonKayserAnno.coordinate = CLLocationCoordinate2DMake(40.752500, -73.982584);
    self.maisonKayserAnno.title = @"Maison Kayser";
    
    [self.mapView addAnnotation:self.maisonKayserAnno];

}



-(void) centerMap:(MKPointAnnotation *)centerPoint{
    [self.mapView setCenterCoordinate:centerPoint.coordinate animated:YES];
}

-(void) showCouponAlert:(NSString *) myCoupon{
    UIAlertController *couponAlert;
    couponAlert = [UIAlertController alertControllerWithTitle:@"" message:@" USE COUPON CODE CHOC10 FOR A 10 PERCENT DISCOUNT ON CHOCOLATES AT MAISON KAYSER!!! GOOD FOR THE NEXT 30 MINUTES ONLY!" preferredStyle:UIAlertControllerStyleAlert];
    
    [couponAlert addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil]];

    [self presentViewController:couponAlert animated:YES completion:nil];

}
    
    
#pragma marks - location call backs

-(void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    self.currentAnno.coordinate = locations.lastObject.coordinate;
    if(self.mapIsMoving == NO){
        [self centerMap:self.currentAnno];
    }
}


- (IBAction)checkStatusTapped:(id)sender {
    [self.locationManager requestStateForRegion:self.geoRegion];
}

#pragma marks - geofence call backs

-(void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region{
    if(state == CLRegionStateUnknown){
        self.statusLabel.text = @"Unkown";
    }else if(state == CLRegionStateInside){
        self.statusLabel.text = @"Inside";
        [self showCouponAlert:@""];
        
    }else if(state == CLRegionStateOutside){
        self.statusLabel.text = @"Outside";
    }
    else{
        self.statusLabel.text = @"Mystery";
    }
    
}


-(void) locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region{
    
    UILocalNotification *note = [[UILocalNotification alloc] init];
    note.fireDate = nil;
    note.repeatInterval = 0;
    note.alertTitle = @"MAISON KAYSER DISCOUNT!";
    note.alertBody = [NSString stringWithFormat:@"USE COUPON CODE CHOC10 FOR A 10 PERCENT DISCOUNT ON CHOCOLATES AT MAISON KAYSER!!! GOOD FOR THE NEXT 30 MINUTES ONLY!"];
    [[UIApplication sharedApplication] scheduleLocalNotification:note];
    
    self.eventLabel.text = @"Entered";
}

-(void) locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    
    UILocalNotification *note = [[UILocalNotification alloc] init];
    note.fireDate = nil;
    note.repeatInterval = 0;
    note.alertTitle = @"BYE!!";
    note.alertBody = [NSString stringWithFormat:@"DON'T FORGET TO USE YOUR DISCOUNT COUPON BEFORE IT EXPIRES!!!"];
    [[UIApplication sharedApplication] scheduleLocalNotification:note];
    
    self.eventLabel.text = @"Exited";
}



@end