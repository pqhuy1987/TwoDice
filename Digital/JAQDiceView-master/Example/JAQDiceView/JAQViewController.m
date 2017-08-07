//
//  JAQViewController.m
//  JAQDiceView
//
//  Created by Javier Querol on 11/19/2014.
//  Copyright (c) 2014 Javier Querol. All rights reserved.
//

#import "JAQViewController.h"
#import <JAQDiceView.h>
@import GoogleMobileAds;

BOOL areAdsRemoved = NO;

@interface JAQViewController () <JAQDiceProtocol>
@property (nonatomic, weak) IBOutlet JAQDiceView *playground;
@property (nonatomic, weak) IBOutlet UILabel *result;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentTab;
@property (weak, nonatomic) IBOutlet GADBannerView *bannerView;
@property (weak, nonatomic) IBOutlet GADBannerView *bannerView2;
@end

#define ADID @"ca-app-pub-5722562744549789/5911181754"
#define kRemoveAdsProductIdentifier @"com.gamming.dice1.100.removeads"
@interface JAQViewController ()<GADInterstitialDelegate>

@property (nonatomic, strong) GADInterstitial *interstitial;
@end

//put the name of your view controller in place of MyViewController
@interface JAQViewController() <SKProductsRequestDelegate, SKPaymentTransactionObserver>
-(IBAction)restore;
-(IBAction)tapsRemoveAds;
@end

@implementation JAQViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.segmentTab setSelectedSegmentIndex:UISegmentedControlNoSegment];
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    areAdsRemoved = [defaults boolForKey:kRemoveAdsProductIdentifier];
    if (areAdsRemoved){
        ;
    } else {
        self.bannerView.adUnitID = @"ca-app-pub-5722562744549789/4221694555";
        self.bannerView.rootViewController = self;
        [self.bannerView loadRequest:[GADRequest request]];
        
        self.bannerView2.adUnitID = @"ca-app-pub-5722562744549789/4221694555";
        self.bannerView2.rootViewController = self;
        [self.bannerView2 loadRequest:[GADRequest request]];
        
        
        [self interstisal];
        
        [self performSelector:@selector(LoadInterstitialAds) withObject:self afterDelay:1.0];
        
    }

}
- (void)diceView:(JAQDiceView *)view rolledWithFirstValue:(NSInteger)firstValue secondValue:(NSInteger)secondValue {
    
	self.result.text = [NSString stringWithFormat:@"%li",firstValue+secondValue];
	[self addPopAnimationToLayer:self.result.layer withBounce:0.1 damp:0.02];
}

- (void)addPopAnimationToLayer:(CALayer *)aLayer withBounce:(CGFloat)bounce damp:(CGFloat)damp {
    
    if (areAdsRemoved) {
    } else {
        [self interstisal];
        [self performSelector:@selector(LoadInterstitialAds) withObject:self afterDelay:1.0];
    }
    
	CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
	animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
	animation.duration = 1;
	
	NSInteger steps = 100;
	NSMutableArray *values = [NSMutableArray arrayWithCapacity:steps];
	double value = 0;
	CGFloat e = 2.71f;
	for (int t=0; t<100; t++) {
		value = pow(e, -damp*t) * sin(bounce*t) + 1;
		[values addObject:[NSNumber numberWithDouble:value]];
	}
	animation.values = values;
	[aLayer addAnimation:animation forKey:@"appearAnimation"];
    
    if (areAdsRemoved) {
    } else {
        [self interstisal];
        [self performSelector:@selector(LoadInterstitialAds) withObject:self afterDelay:1.0];
    }
}


- (IBAction)OntouchChange:(id)sender {
    //[self.segmentTab setSelectedSegmentIndex:UISegmentedControlNoSegment];
    switch (self.segmentTab.selectedSegmentIndex)
    {
        case 0:
            [self tapsRemoveAds];
            [self.segmentTab setSelectedSegmentIndex:UISegmentedControlNoSegment];
            break;
        case 1:
            [self restore];
            [self.segmentTab setSelectedSegmentIndex:UISegmentedControlNoSegment];
            break;
        default:
            break;
    }
}

-(void)interstisal{
    self.interstitial = [[GADInterstitial alloc] initWithAdUnitID:ADID];
    
    self.interstitial.delegate = self;
    
    GADRequest *request = [GADRequest request];
    
    [self.interstitial loadRequest:request];
    
}

-(void)LoadInterstitialAds{
    
    if (self.interstitial.isReady) {
        [self.interstitial presentFromRootViewController:self];
    }
}

//Add IAP in this project
//If you have more than one in-app purchase, you can define both of
//of them here. So, for example, you could define both kRemoveAdsProductIdentifier
//and kBuyCurrencyProductIdentifier with their respective product ids
//
//for this example, we will only use one product


- (IBAction)tapsRemoveAds{
    NSLog(@"User requests to remove ads");
    
    if([SKPaymentQueue canMakePayments]){
        NSLog(@"User can make payments");
        
        //If you have more than one in-app purchase, and would like
        //to have the user purchase a different product, simply define
        //another function and replace kRemoveAdsProductIdentifier with
        //the identifier for the other product
        
        SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:kRemoveAdsProductIdentifier]];
        productsRequest.delegate = self;
        [productsRequest start];
        
    }
    else{
        NSLog(@"User cannot make payments due to parental controls");
        //this is called the user cannot make payments, most likely due to parental controls
    }
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
    SKProduct *validProduct = nil;
    int count = [response.products count];
    if(count > 0){
        validProduct = [response.products objectAtIndex:0];
        NSLog(@"Products Available!");
        [self purchase:validProduct];
    }
    else if(!validProduct){
        NSLog(@"No products available");
        //this is called if your product id is not valid, this shouldn't be called unless that happens.
    }
}

- (void)purchase:(SKProduct *)product{
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (IBAction) restore{
    //this is called when the user restores purchases, you should hook this up to a button
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void) paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    NSLog(@"received restored transactions: %i", queue.transactions.count);
    for(SKPaymentTransaction *transaction in queue.transactions){
        if(transaction.transactionState == SKPaymentTransactionStateRestored){
            //called when the user successfully restores a purchase
            NSLog(@"Transaction state -> Restored");
            
            //if you have more than one in-app purchase product,
            //you restore the correct product for the identifier.
            //For example, you could use
            //if(productID == kRemoveAdsProductIdentifier)
            //to get the product identifier for the
            //restored purchases, you can use
            //
            //NSString *productID = transaction.payment.productIdentifier;
            [self doRemoveAds];
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            break;
        }
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions{
    for(SKPaymentTransaction *transaction in transactions){
        //if you have multiple in app purchases in your app,
        //you can get the product identifier of this transaction
        //by using transaction.payment.productIdentifier
        //
        //then, check the identifier against the product IDs
        //that you have defined to check which product the user
        //just purchased
        
        switch(transaction.transactionState){
            case SKPaymentTransactionStatePurchasing: NSLog(@"Transaction state -> Purchasing");
                //called when the user is in the process of purchasing, do not add any of your own code here.
                break;
            case SKPaymentTransactionStatePurchased:
                //this is called when the user has successfully purchased the package (Cha-Ching!)
                [self doRemoveAds]; //you can add your code for what you want to happen when the user buys the purchase here, for this tutorial we use removing ads
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                NSLog(@"Transaction state -> Purchased");
                break;
            case SKPaymentTransactionStateRestored:
                NSLog(@"Transaction state -> Restored");
                //add the same code as you did from SKPaymentTransactionStatePurchased here
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                //called when the transaction does not finish
                if(transaction.error.code == SKErrorPaymentCancelled){
                    NSLog(@"Transaction state -> Cancelled");
                    //the user cancelled the payment ;(
                }
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
        }
    }
}

- (void)doRemoveAds{
    self.bannerView.hidden = true;
    self.bannerView2.hidden = true;
    areAdsRemoved = YES;
    //set the bool for whether or not they purchased it to YES, you could use your own boolean here, but you would have to declare it in your .h file
    
    [[NSUserDefaults standardUserDefaults] setBool:areAdsRemoved forKey:@"com.gamming.dice1.100.removeads"];
    //use NSUserDefaults so that you can load wether or not they bought it
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
