//
//  ScoreViewController.m
//  uRight2
//
//  Created by Sunsern Cheamanunkul on 11/9/12.
//
//

#import "ScoreViewController.h"

#import "PCLineChartView.h"
#import "GlobalStorage.h"
#import "Userdata.h"

@interface ScoreViewController () {
    PCLineChartView *_lineChartView;
    UIWebView *_webView;
    UIActivityIndicatorView *_activityView;
}
@end

@implementation ScoreViewController

- (id)init {
    self = [super init];
    if (self) {
        int width = self.view.frame.size.width;
        int height = self.view.frame.size.height;
        int y_offset = 0;
        
        // iphone 5
        if (height > 480) {
            y_offset = (568-480)/2;
        }
        
        // Set BG color
        [self.view setBackgroundColor:[UIColor whiteColor]];
        
        // Progress
        _lineChartView = [[PCLineChartView alloc]
                          initWithFrame:CGRectMake(20, y_offset+25,
                                                   width-40, 200)];
        
        [_lineChartView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [_lineChartView setAutoscaleYAxis:NO];
        [self.view addSubview:_lineChartView];
        
        UILabel *chartTitle = [[UILabel alloc]
                               initWithFrame:CGRectMake((width-200)/2, y_offset+10,
                                                        200, 40)];
        chartTitle.text = @"Your BPS History";
        chartTitle.textAlignment = NSTextAlignmentCenter;
        chartTitle.font = [UIFont fontWithName:@"Chalkduster" size:20];
        chartTitle.adjustsFontSizeToFitWidth = YES;
        [self.view addSubview:chartTitle];
        
        
        // Leaderboard
        _webView = [[UIWebView alloc]
                    initWithFrame:CGRectMake(20, y_offset+245,
                                             width-40, 190)];
        
        [[_webView scrollView] setBounces:NO];
        [[_webView scrollView] setShowsHorizontalScrollIndicator:NO];
        [_webView setDelegate:self];
        [self.view addSubview:_webView];
        
        UILabel *leaderboardTitle = [[UILabel alloc]
                                     initWithFrame:CGRectMake((width-200)/2, y_offset+210,
                                                              200, 40)];
        leaderboardTitle.text = @"Weekly Top-10";
        leaderboardTitle.textAlignment = NSTextAlignmentCenter;
        leaderboardTitle.font = [UIFont fontWithName:@"Chalkduster" size:20];
        leaderboardTitle.adjustsFontSizeToFitWidth = YES;
        [self.view addSubview:leaderboardTitle];
        
        // Loading icon
        _activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _activityView.center = CGPointMake(_webView.bounds.size.width/2, 100);
        [_webView addSubview:_activityView];
        
        // Close button
        UIImage *closeImage = [UIImage imageNamed:@"close.png"];
        UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        closeButton.frame = CGRectMake(0, 0, 40, 40);
        [closeButton setBackgroundImage:closeImage forState:UIControlStateNormal];
        [closeButton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:closeButton];
    }
    return self;
}


- (void)back {
    [self dismissModalViewControllerAnimated:YES];
}


- (void)viewWillAppear:(BOOL)animated {
    [self loadLineChart];
    [self loadScoreboard];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [_activityView startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [_activityView stopAnimating];
}

- (void)loadLineChart {
    Userdata *ud = [[GlobalStorage sharedInstance] activeUserdata];
    NSArray *scores = ud.scores;
    if (scores != nil && [scores count] > 0) {
        float max_score = -FLT_MAX;
        float min_score = FLT_MAX;
        float best_score = ud.bestBps;
        
        for (int i=0; i < [scores count]; i++) {
            float temp = [scores[i] floatValue];
            if (temp > max_score) {
                max_score = temp;
            }
            if (temp < min_score) {
                min_score = temp;
            }
        }
        
        if (max_score < best_score) {
            max_score = best_score;
        }
        
        //NSLog(@"min = %f", min_score);
        //NSLog(@"max = %f", max_score);
        
        [_lineChartView setMinValue:min_score-0.5];
        [_lineChartView setMaxValue:max_score+0.5];
        
        float interval = (max_score - min_score + 1.0) / 4.0;
        [_lineChartView setInterval:interval];
        
        NSMutableArray *components = [[NSMutableArray alloc] init];
        PCLineChartViewComponent *component = [[PCLineChartViewComponent alloc] init];
        [component setTitle:@""];
        [component setPoints:scores];
        [component setShouldLabelValues:NO];
        [component setColour:PCColorBlue];
        [components addObject:component];
        
        [_lineChartView setComponents:components];
        [_lineChartView setNumXLabels:[scores count]];
        [_lineChartView setMaxLineValue:best_score];
        [_lineChartView setNeedsDisplay];
    }
    else {
        [_lineChartView setMinValue:0];
        [_lineChartView setMaxValue:3];
        [_lineChartView setInterval:1.0];
        
        NSMutableArray *components = [[NSMutableArray alloc] init];
        PCLineChartViewComponent *component = [[PCLineChartViewComponent alloc] init];
        [component setTitle:@""];
        [component setPoints:@[@(0)]];
        [component setShouldLabelValues:NO];
        [component setColour:PCColorBlue];
        [components addObject:component];
        
        [_lineChartView setComponents:components];
        [_lineChartView setNumXLabels:1];
        [_lineChartView setMaxLineValue:0];
        [_lineChartView setNeedsDisplay];
    }
}

- (void)loadScoreboard {
    NSString *urlString = [NSString stringWithFormat:
                           @"%@/leaderboard", UR_BASE_URL];
    NSURL *url = [[NSURL alloc] initWithString:urlString];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    [_webView loadRequest:request];
}


@end
