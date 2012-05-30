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
#import "MFeed.h"
#import "FeedManager.h"
#import "MObj.h"
#import "FeedListViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface FriendPickerTableViewController ()

@end

@implementation FriendPickerTableViewController

@synthesize identityManager = _identityManager, identities = _identities, index = _index, selection = _selection, friendsSelectedDelegate = _friendsSelectedDelegate, pinnedIdentities = _pinnedIdentities;

- (void)loadView {
    [super loadView];
    
    importingLabel = [[UILabel alloc] init];
    importingLabel.font = [UIFont systemFontOfSize: 13.0];
    importingLabel.text = @"";
    importingLabel.backgroundColor = [UIColor colorWithRed:78.0/256.0 green:137.0/256.0 blue:236.0/256.0 alpha:1];
    importingLabel.textColor = [UIColor whiteColor];
    
    remainingImports = [NSMutableDictionary dictionaryWithCapacity:2];
}

- (void) updateIdentityListWithFilter: (NSString*) filter
{
    if (filter.length == 0)
        filter = nil;
    
    NSMutableArray* idents = [NSMutableArray arrayWithCapacity:265];
    for (MIdentity* mId in [_identityManager query:nil]) {
        NSString* name = [IdentityManager displayNameForIdentity:mId];
        if (mId.owned || name.length == 0 || [name isEqualToString:@"Unknown"])
            continue;
        //skip the ones that are already members
        if(!filter && [_pinnedIdentities containsObject:mId]) 
            continue;
        if (!filter || (mId.name && [mId.name rangeOfString:filter options:NSCaseInsensitiveSearch].location != NSNotFound)
            || (mId.musubiName && [mId.musubiName rangeOfString:filter options:NSCaseInsensitiveSearch].location != NSNotFound)
            || (mId.principal && [mId.principal rangeOfString:filter options:NSCaseInsensitiveSearch].location != NSNotFound)) {
            [idents addObject:mId];
        }
    }
    
    NSComparisonResult (^compare) (MIdentity*, MIdentity*) = ^(MIdentity* obj1, MIdentity* obj2) {
        NSString* a = [IdentityManager displayNameForIdentity:obj1];
        NSString* b = [IdentityManager displayNameForIdentity:obj2];
        a = [a stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        b = [b stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        return [a caseInsensitiveCompare:b];
    };
    [idents sortUsingComparator: compare];

    
    NSMutableArray* pinnedIdents = [NSMutableArray arrayWithCapacity:_pinnedIdentities.count];
    if(!filter) {
        //if we are filtering, no pinned identities
        for(MIdentity* mId in _pinnedIdentities)
            [pinnedIdents addObject:mId];
    }
    [pinnedIdents sortUsingComparator: compare];

    int pinned = pinnedIdents.count;
    NSMutableArray* all = pinned ? [NSMutableArray arrayWithArray:pinnedIdents] : [NSMutableArray array];
    [all addObjectsFromArray:idents];
    
    NSMutableArray* index = [NSMutableArray arrayWithCapacity:27];
    NSMutableDictionary* indexedIds = [NSMutableDictionary dictionaryWithCapacity:27];    
    
    if(pinned) {
        [index addObject:@"\u2713"];
        [indexedIds setObject:pinnedIdents forKey:@"\u2713"];
    }     
    char charPtr = 0;
    NSMutableArray* charIdentities = nil;
    for (int i=pinned; i<all.count; i++) {
        MIdentity* ident = [all objectAtIndex:i];
        
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
    
    pickerTextField = [[TTPickerTextField alloc] init];
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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([self.identityManager ownedIdentities].count <= 0) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"No known identity" message:@"Please connect to an account from the settings screen first" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
        
        [self.navigationController popViewControllerAnimated:TRUE];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [importingLabel removeFromSuperview];
    [self.view addSubview:importingLabel];
    
    [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(updateImporting:) name:kMusubiNotificationIdentityImported object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[Musubi sharedInstance].notificationCenter removeObserver:self name:kMusubiNotificationIdentityImported object:nil];
}

- (void) updateImporting: (NSNotification*) notification {
    if (![NSThread currentThread].isMainThread) {
        [self performSelectorOnMainThread:@selector(updateImporting:) withObject:notification waitUntilDone:NO];
        return;
    }    

    if ([notification.object objectForKey:@"index"]) {
        NSNumber* index = [notification.object objectForKey:@"index"];
        NSNumber* total = [notification.object objectForKey:@"total"];
        
        [remainingImports setObject:[NSNumber numberWithInt:total.intValue - index.intValue - 1] forKey:[notification.object objectForKey:@"type"]];

        int remaining = 0;
        for (NSNumber* rem in remainingImports.allValues) {
            remaining += rem.intValue;
        }
        
        if (remaining > 0) {
            [importingLabel setText:[NSString stringWithFormat: @"  Importing %d contacts...", remaining]];
            [importingLabel setFrame:CGRectMake(0, 386, 320, 30)];
        } else {
            importingLabel.text = @"";
            [importingLabel setFrame:CGRectMake(0, 420, 0, 0)];    
        }
        
        if (remaining % 20 == 0) {
            [self search: pickerTextField.text];
        }
    }
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

    if([_pinnedIdentities containsObject:ident]) {
        cell.userInteractionEnabled = NO;
        cell.textLabel.alpha = 0.439216f;
    } else {
        cell.textLabel.alpha = 1.0;
    }

    cell.textLabel.text = ident.musubiName;
    if(!cell.textLabel.text) cell.textLabel.text = ident.name;
    if(!cell.textLabel.text) cell.textLabel.text = ident.principal;
    if(!cell.textLabel.text) cell.textLabel.text = @"Unknown";
    [[cell detailTextLabel] setText: ident.principal];

    if(ident.musubiThumbnail) {
        [[cell imageView] setImage: [UIImage imageWithData:ident.musubiThumbnail]];
    } else {
        [[cell imageView] setImage: [UIImage imageWithData:ident.thumbnail]];
    }
    
    if ([_selection containsObject:ident] || [_pinnedIdentities containsObject:ident]) {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }

    return cell;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return _index;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString* t = [_index objectAtIndex:section];
    if([t isEqualToString:@"\u2713"])
        t = @"Already Addded";
    return t;
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
- (void)setModel:(id<TTModel>)model {
    NSLog(@"Model changes not supported continuing blindly");
}

- (NSString*) tableView:(UITableView*)tv labelForObject:(id) obj {
    return ((MIdentity*)obj).name;
}

- (NSString*) tableView:(UITableView *)tableView subLabelForObject:(id)obj {
    return ((MIdentity*)obj).principal;
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
    
    int newY = MAX(0, 30 * (pickerTextField.lineCount - 2));
    [recipientView setContentOffset:CGPointMake(0, newY) animated:NO];
}

- (IBAction)friendsSelected:(id)sender {
    [_friendsSelectedDelegate friendsSelected:_selection];
}

@end
