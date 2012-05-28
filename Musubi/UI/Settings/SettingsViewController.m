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
//  SettingsViewController.m
//  musubi
//
//  Created by Willem Bult on 1/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SettingsViewController.h"
#import "AppDelegate.h"
#import "FacebookAuth.h"
#import "MAccount.h"
#import "Musubi.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "PersistentModelStore.h"
#import "AppDelegate.h"
#import "MIdentity.h"
#import "IdentityManager.h"
#import "ProfileObj.h"

@implementation SettingsViewController

@synthesize authMgr, accountTypes;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setAuthMgr:[[AccountAuthManager alloc] initWithDelegate:self]];
    [self setAccountTypes: [NSDictionary dictionaryWithObjectsAndKeys:@"Facebook", kAccountTypeFacebook, @"Google", kAccountTypeGoogle, nil]];
    
    for (NSString* type in accountTypes.allKeys) {
        [authMgr performSelectorInBackground:@selector(checkStatus:) withObject:type];
        [authMgr checkStatus: type];
    }
    
    dbUploadProgress = kDBOperationNotStarted;
    dbDownloadProgress = kDBOperationNotStarted;

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    [self setAuthMgr: nil];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[self dbRestClient] loadMetadata:@"/"];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:2]] withRowAnimation:UITableViewRowAnimationNone];    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)pictureClicked:(id)sender {    
    UIImagePickerController* picker = [[UIImagePickerController alloc] init];
    [picker setSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
    [picker setDelegate:self];
    
    [self presentModalViewController:picker animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 32;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 1;
        case 1:
            return accountTypes.count;
        case 2:
            return 2;
    }
    
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
    switch (section) {
        case 0:
            return @"Profile";
        case 1:
            return @"Networks";
        case 2:
            return @"Dropbox Backup";
    }
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0: {
            NamePictureCell* cell = (NamePictureCell*) [tableView dequeueReusableCellWithIdentifier:@"NamePictureCell"];
            PersistentModelStore* store = [[Musubi sharedInstance] newStore];
            IdentityManager* idm = [[IdentityManager alloc] initWithStore:store];
            NSArray* mine = [idm ownedIdentities];
            if(mine.count > 0) {
                MIdentity* me = [mine objectAtIndex:0];
                if(me.musubiThumbnail) {
                    cell.picture.image = [UIImage imageWithData:me.musubiThumbnail];
                }
                cell.nameTextField.text = me.musubiName;
            }
            return cell;
        }
        case 1: {
            UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"];
            }
            
            NSString* accountType = [accountTypes.allKeys objectAtIndex:indexPath.row];
            NSString* account = [accountTypes objectForKey:accountType];
            [[cell textLabel] setText: account];
            [[cell detailTextLabel] setText: [authMgr isConnected:accountType] ? @"Connected" : @"Click to connect"];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];

            return cell;
        }
        case 2: {
            UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"];
            }
            
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            
            switch (indexPath.row) {
                case 0: {
                    [[cell textLabel] setText: @"Save"];
                    
                    if (dbUploadProgress == kDBOperationCompleted) {
                        [[cell detailTextLabel] setText: @"Done"];
                    } else if (dbUploadProgress == kDBOperationFailed) {
                        [[cell detailTextLabel] setText: @"Failed"];                
                    } else if (dbUploadProgress >= 0) {
                        [[cell detailTextLabel] setText: [NSString stringWithFormat:@"%d%%", dbUploadProgress]];                
                    } else {
                        [[cell detailTextLabel] setText: [[DBSession sharedSession] isLinked] ? @"Click to save" : @"Click to connect"];
                    }

                    break;
                }
                case 1: {
                    [[cell textLabel] setText: @"Restore"];
                    
                    if (dbDownloadProgress == kDBOperationCompleted) {
                        [[cell detailTextLabel] setText: @"Done"];
                    } else if (dbDownloadProgress == kDBOperationFailed) {
                        [[cell detailTextLabel] setText: @"Failed"];                
                    } else if (dbDownloadProgress >= 0) {
                        [[cell detailTextLabel] setText: [NSString stringWithFormat:@"%d%%", dbDownloadProgress]];                
                    } else if (dbRestoreFile != nil) {
                        [[cell detailTextLabel] setText: @"Click to restore"];                            
                    } else {
                        [[cell detailTextLabel] setText: [[DBSession sharedSession] isLinked] ? @"No backup found" : @"Click to connect"];                        
                    }
                        
                    break;
                }
            }
            
           
            return cell;
        }
    }
    
    /*
    User* user = [[Identity sharedInstance] user];
    if ([user picture] != nil) {
        
        UIButton* button = [cell picture];
        [button setImage:[UIImage imageWithData:[user picture]] forState:UIControlStateNormal];
    }
    [[cell nameTextField] setText: [user name]];*/
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: {
            return 90;
        }
        default: {
            return 44;
        }
    }
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

- (DBRestClient *)dbRestClient {
    if (!dbRestClient) {
        dbRestClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        dbRestClient.delegate = self;
    }
    return dbRestClient;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    
    switch (indexPath.section) {
        case 0:{
            break;
        }
        case 1: {
            NSString* accountType = [accountTypes.allKeys objectAtIndex:indexPath.row];
            if (![authMgr isConnected: accountType]) {
                [authMgr performSelectorInBackground:@selector(connect:) withObject:accountType];
            } else {
                [authMgr disconnect:accountType];
                // Debug notification
                //[[Musubi sharedInstance].notificationCenter postNotification:[NSNotification notificationWithName:kMusubiNotificationFacebookFriendRefresh object:nil]];
            }
            
            break;
        }
        case 2: {
            if (![[DBSession sharedSession] isLinked]) {
                [[DBSession sharedSession] link];
            } else {
                switch (indexPath.row) {
                    case 0: {
                        if (dbUploadProgress == kDBOperationNotStarted || dbUploadProgress == kDBOperationFailed) {
                            NSURL* path = [PersistentModelStoreFactory pathForStoreWithName:@"Store"];
                            [self updateDBUploadProgress:0];
                            
                            [[self dbRestClient] uploadFile:@"Backup.musubiRestore" toPath:@"/"
                                              withParentRev:nil fromPath:[path path]];
                        }
                        
                        break;
                    }
                    case 1: {
                        if (dbDownloadProgress == kDBOperationNotStarted || dbDownloadProgress == kDBOperationFailed) {
                            
                            [self updateDBDownloadProgress:0];
                            
                            NSURL* path = [PersistentModelStoreFactory pathForStoreWithName:@"Store_Restore"];
                            [[self dbRestClient] loadFile:dbRestoreFile intoPath:path.path];
                        }
                        break;
                    }
                }
            }
                        
            break;
        }
    }
}

- (void) updateDBDownloadProgress: (int) progress {
    dbDownloadProgress = progress;
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:1 inSection:2]] withRowAnimation:UITableViewRowAnimationNone];    
}

- (void) updateDBUploadProgress: (int) progress {
    dbUploadProgress = progress;
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:2]] withRowAnimation:UITableViewRowAnimationNone];    
}


#pragma mark - DBRestClient delegate

- (void)restClient:(DBRestClient *)client uploadProgress:(CGFloat)progress forFile:(NSString *)destPath from:(NSString *)srcPath {
    [self updateDBUploadProgress:(int) round(progress * 100)];
}

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath
              from:(NSString*)srcPath metadata:(DBMetadata*)metadata {

    [self updateDBUploadProgress:kDBOperationCompleted];
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
    [self updateDBUploadProgress:kDBOperationFailed];
}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    if (metadata.isDirectory) {        
        NSString* backupFile = nil;
        NSDate* backupFileDate = nil;
        
        // Use the last matching file (newest)
        for (DBMetadata *file in metadata.contents) {
            
            if ([file.filename rangeOfString:@".musubiRestore"].location != NSNotFound) {
                if (backupFileDate == nil || backupFileDate.timeIntervalSince1970 < file.lastModifiedDate.timeIntervalSince1970) {
                    backupFile = file.path;
                    backupFileDate = file.lastModifiedDate;
                }
            }
        }

        dbRestoreFile = backupFile;
        
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:1 inSection:2]] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error {
    dbRestoreFile = nil;
}

- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)localPath {
    @try {
        [PersistentModelStoreFactory restoreStoreFromFile: [NSURL fileURLWithPath:localPath]];        
        [self updateDBDownloadProgress:kDBOperationCompleted];
        [((AppDelegate*)[UIApplication sharedApplication].delegate) restart];
        
    } @catch (NSError* err) {      
        NSLog(@"Error: %@", err);
        [self updateDBDownloadProgress:kDBOperationFailed];
    }
}

- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error {
    [self updateDBDownloadProgress:kDBOperationFailed];
}

- (void)restClient:(DBRestClient *)client loadProgress:(CGFloat)progress forFile:(NSString *)destPath {
    [self updateDBDownloadProgress:(int) round(progress * 100)];
}

#pragma mark - AccountAuthManager delegate

- (void)accountWithType:(NSString *)type isConnected:(BOOL)connected {
    int row = [accountTypes.allKeys indexOfObject:type];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:row inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
    
}

#pragma mark - Text field delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    PersistentModelStore* store = [[Musubi sharedInstance] newStore];
    IdentityManager* idm = [[IdentityManager alloc] initWithStore:store];
    NSArray* mine = [idm ownedIdentities];
    if(mine.count == 0) {
        NSLog(@"No identity, connect an account");
        return;
    }
    if(textField.text.length == 0) {
        MIdentity* me = [mine objectAtIndex:0];
        textField.text = me.musubiName;
        return;
    }
    long long now = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
    for(MIdentity* me in mine) {
        me.musubiName = textField.text;
        me.receivedProfileVersion = now;
   }
    [store save];
    [ProfileObj sendAllProfilesWithStore:store];
}

#pragma mark - Image picker delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo {
    if(!image)
        return;
    
    PersistentModelStore* store = [[Musubi sharedInstance] newStore];
    IdentityManager* idm = [[IdentityManager alloc] initWithStore:store];
    NSArray* mine = [idm ownedIdentities];
    if(mine.count == 0) {
        NSLog(@"No identity, connect an account");
        return;
    }
    NSData* thumbnail = nil;
    double scale = MIN(1, 256 / MAX([image size].width, [image size].height));
    if (scale < 1) {
        CGSize newSize = CGSizeMake([image size].width * scale, [image size].height * scale);
        image = [image resizedImage:newSize interpolationQuality:0.9];
    }
    thumbnail = UIImageJPEGRepresentation(image, 0.90);

    long long now = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
    for(MIdentity* me in mine) {
        me.musubiThumbnail = thumbnail;
        me.receivedProfileVersion = now;
    }
    [store save];
    [ProfileObj sendAllProfilesWithStore:store];

    
    [[self tableView] reloadData];
    [[self modalViewController] dismissModalViewControllerAnimated:YES];
}

@end

