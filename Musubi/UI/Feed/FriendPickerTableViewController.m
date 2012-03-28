/*
 * Copyright 2012 The Stanford MobiSocial Laboratory
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


//
//  FriendPickerTableViewController.m
//  Musubi
//
//  Created by Willem Bult on 3/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FriendPickerTableViewController.h"
#import "IdentityManager.h"
#import "MIdentity.h"
#import "MApp.h"
#import "Musubi.h"
#import "FeedManager.h"
#import "AppManager.h"
#import <QuartzCore/QuartzCore.h>
#import "Three20/Three20.h"

@interface FriendPickerTableViewController ()

@end

@implementation FriendPickerTableViewController

@synthesize identityManager = _identityManager, identities = _identities, index = _index, selection = _selection;

- (id)init {
    self = [super init];
    NSLog(@"Normal init");
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    NSLog(@"Nib init");
    return self;
}

- (void) updateIdentityListWithFilter: (NSString*) filter
{
    if (filter.length == 0)
        filter = nil;
    
    NSMutableArray* idents = [NSMutableArray arrayWithCapacity:265];
    for (MIdentity* mId in [_identityManager query:nil]) {
        if (!mId.owned && mId.name.length > 0) {
            if (!filter || [mId.name rangeOfString:filter options:NSCaseInsensitiveSearch].location != NSNotFound)
                [idents addObject:mId];
        }
    }
    
    NSComparisonResult (^compare) (MIdentity*, MIdentity*) = ^(MIdentity* obj1, MIdentity* obj2) {
        return [obj1.name compare:obj2.name];
    };    
    [idents sortUsingComparator: compare];
    
    
    NSMutableArray* index = [NSMutableArray arrayWithCapacity:26];
    NSMutableDictionary* indexedIds = [NSMutableDictionary dictionaryWithCapacity:26];    
    
    char charPtr = 0;
    NSMutableArray* charIdentities = nil;
    for (int i=0; i<idents.count; i++) {
        MIdentity* ident = [idents objectAtIndex:i];
        
        char curChar = [ident.name characterAtIndex:0];
        if (curChar <= 'Z')
            curChar += ('a' - 'A');
        
        if (curChar > charPtr) {
            charPtr = curChar;
            charIdentities = [NSMutableArray array];
            
            [index addObject:[NSString stringWithFormat:@"%c", charPtr]];
            [indexedIds setObject:charIdentities forKey:[NSString stringWithFormat:@"%c", charPtr]];
        }
        
        [charIdentities addObject:ident];
    }
    
    [self setIndex: index];
    [self setIdentities: indexedIds];

}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setSelection: [NSMutableArray array]];
    
    [self setIdentityManager:[[IdentityManager alloc] initWithStore:[Musubi sharedInstance].mainStore]];
    [self updateIdentityListWithFilter:nil];
        
    [tableView setDelegate: self];
    [tableView setDataSource: self];
    
    pickerTextField = [[[TTPickerTextField alloc] init] autorelease];
    pickerTextField.dataSource = self;
    pickerTextField.delegate = self;
    pickerTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    pickerTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    pickerTextField.rightViewMode = UITextFieldViewModeAlways;
    pickerTextField.returnKeyType = UIReturnKeyDone;
    pickerTextField.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    pickerTextField.font = [UIFont systemFontOfSize:14.0];

    [recipientView addSubview:pickerTextField];
    [pickerTextField setFrame:CGRectMake(0, 0, recipientView.frame.size.width, recipientView.frame.size.height)];
    recipientView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    recipientView.layer.borderWidth = 1.0;

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _index.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[_identities objectForKey: [_index objectAtIndex:section]] count];
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FriendCell";
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    MIdentity* ident = [[_identities objectForKey: [_index objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    [[cell textLabel] setText: ident.name];
    [[cell imageView] setImage: [UIImage imageWithData:ident.thumbnail]];
    
    if ([_selection containsObject:ident]) {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }

    return cell;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return _index;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MIdentity* ident = [[_identities objectForKey: [_index objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    
    BOOL add = ![_selection containsObject:ident];
    
    if (add) {
        [_selection addObject: ident];
    } else {
        // Don't remove here. 
        // Remove from picker, which will call delegate to remove from table
    }

    [tv reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];

    if (add) {
        [pickerTextField addCellWithObject: ident];
    } else {
        [pickerTextField removeCellWithObject: ident];
    }
        
    if (pickerTextField.lineCount > 1) {
        [pickerTextField setFrame:CGRectMake(0, 0, 320, 30 * pickerTextField.lineCount + 6)];
        
        [recipientView setFrame:CGRectMake(0, 0, 320, 70)];
        [tableView setFrame:CGRectMake(0, 70, 320, 362)];
        
        int newY = 30 * (pickerTextField.lineCount - 2);
        [recipientView setContentOffset:CGPointMake(0, newY) animated:NO];
    }
}

#pragma mark - TTTableView data source

- (id<TTModel>)model {
    return nil;
}

- (NSString*) tableView:(UITableView*)tv labelForObject:(id) obj {
    return ((MIdentity*)obj).name;
}

- (void)search:(NSString *)text {
    [self updateIdentityListWithFilter:text];
    [tableView reloadData];
    
    int newY = MAX(0, 30 * (pickerTextField.lineCount - 2));
    [recipientView setContentOffset:CGPointMake(0, newY) animated:NO];
}

#pragma mark -- TTPickerTextField delegate
- (void) textField: (UITextField*)tf didRemoveCellAtIndex: (int) idx {
    NSLog(@"Removed %d", idx);
    [_selection removeObject: [_selection objectAtIndex:idx]];
    [tableView reloadData];
}

- (IBAction)createFeed:(id)sender {
    NSLog(@"Creating feed");
    
    PersistentModelStore* store = [Musubi sharedInstance].mainStore;
    
//    [[Musubi sharedInstance].storeFactory newStore];
    
    AppManager* am = [[AppManager alloc] initWithStore:store];
    MApp* app = [am ensureAppWithAppId:@"mobisocial.musubi"];
    
    FeedManager* fm = [[FeedManager alloc] initWithStore: store];
    MFeed* f = [fm createExpandingFeedWithParticipants:_selection andSendIntroductionFromApp:app];
    NSLog(@"Feed: %@", f);
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
