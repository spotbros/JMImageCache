//
//  JMCacheViewController.m
//  JMCache
//
//  Created by Jake Marsh on 2/7/11.
//  Copyright 2011 Jake Marsh. All rights reserved.
//

#import "DemoViewController.h"
#import "JMImageCache.h"
#import "UIImageView+JMImageCache.h"

@interface DemoViewController ()

@property (strong, nonatomic) NSMutableArray *modelArray;
@property (strong, nonatomic) JMImageCache *imageCache;

@end

@implementation DemoViewController

@synthesize modelArray = _modelArray;
@synthesize imageCache = _imageCache;

- (id) init {
    self = [super init];
    if(!self) return nil;

    self.title = @"The Office";

    self.modelArray = [[NSMutableArray alloc] init];

    [self.modelArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"http://cl.ly/4hCR/Untitled-7.png", @"ImageURL", @"Michael Scott", @"Title", nil]];
    [self.modelArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"http://cl.ly/4iIc/Untitled-7.png", @"ImageURL", @"Jim Halpert", @"Title", nil]];
    [self.modelArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"http://cl.ly/4hVv/Untitled-7.png", @"ImageURL", @"Pam Beasley-Halpert", @"Title", nil]];
    [self.modelArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"http://cl.ly/4hF3/Untitled-7.png", @"ImageURL", @"Dwight Schrute", @"Title", nil]];
    [self.modelArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"http://cl.ly/4hxj/Untitled-7.png", @"ImageURL", @"Andy Bernard", @"Title", nil]];
    [self.modelArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"http://cl.ly/4iNI/Untitled-7.png", @"ImageURL", @"Kevin Malone", @"Title", nil]];
    [self.modelArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"http://cl.ly/4iAX/Untitled-7.png", @"ImageURL", @"Stanley Hudson", @"Title", nil]];		

    self.imageCache = [[JMImageCache alloc] initWithCacheDirectory:@"Library/Caches/JMCacheV2"];
    
    [self.imageCache adjustCacheSizeTo:(200 * 1024)];

	return self;
}

#pragma mark -
#pragma mark Autorotation Methods

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

#pragma mark -
#pragma mark Cleanup Methods

- (void) didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.modelArray count];
}
- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";

	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if(cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];

    NSString *urlString = [[self.modelArray objectAtIndex:indexPath.row] objectForKey:@"ImageURL"];

	cell.textLabel.text = [[self.modelArray objectAtIndex:indexPath.row] objectForKey:@"Title"];

    [cell.imageView setImageWithURL:[NSURL URLWithString:urlString]
                              cache:self.imageCache
                        placeholder:[UIImage imageNamed:@"placeholder"]];

	return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 90.0;
}
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end