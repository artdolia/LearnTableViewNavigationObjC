//
//  DirectoryViewController.m
//  L33-34_tableViewNavigation
//
//  Created by Artsiom Dolia on 1/7/15.
//  Copyright (c) 2015 Artsiom Dolia. All rights reserved.
//

#import "DirectoryViewController.h"
#import "FolderCell.h"
#import "FileCell.h"

@interface DirectoryViewController () <UIAlertViewDelegate>

@property (strong, nonatomic) NSArray *contents;
@property (strong, nonatomic) NSString *selectedPath;

@property (strong, nonatomic) UIAlertView *deleteAlert;
@property (strong, nonatomic) NSIndexPath *deletePath;

@end

@implementation DirectoryViewController


- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void) viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    if(!self.path){
        self.path = @"Users/Artsiom/Documents";
    }
    
    //show buttons to add a dir and navigate to Root
    
    UIBarButtonItem *addDir = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addDirAction:)];
    
    UIBarButtonItem *navigateToRoot = [[UIBarButtonItem alloc] initWithTitle:@"Root" style:UIBarButtonItemStylePlain target:self action:@selector(navigateToRootAction:)];
    
    NSMutableArray *rightBarButtonItems = [NSMutableArray arrayWithObject:addDir];
    
    if ([self.navigationController.viewControllers count] > 1) {
        [rightBarButtonItems addObject:navigateToRoot];
    }
    self.navigationItem.rightBarButtonItems = rightBarButtonItems;
    
    self.tableView.editing = YES;
    self.tableView.allowsSelectionDuringEditing = YES;
}


- (id)initWithPath:(NSString *) path{

    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.path = path;
    }
    return self;
}


- (void) setPath:(NSString *)path{
    
    _path = path;
    self.contents = [self getContentAtPath:path];
    
    //do not show hidden files
    //show directories first following by files
    NSMutableArray *tmpContent = [NSMutableArray arrayWithArray:[self removeHiddenFilesFromContents:self.contents]];
    tmpContent = [self sortDirsFilesInArray:tmpContent];
    self.contents = tmpContent;
    [self.tableView reloadData];
    self.navigationItem.title = [self.path lastPathComponent];
}


#pragma mark - UITableViewDelegate


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if ([self isDirectoryAtIndexPath:indexPath]) {
        return 60.f;
    }else{
        return 90.f;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

    if ([self isDirectoryAtIndexPath:indexPath]) {

        NSString *filePath = [self getFilePathAtIndexPath:indexPath];
        
        //DirectoryViewController *vc = [[DirectoryViewController alloc] initWithPath:filePath];
        //[self.navigationController pushViewController:vc animated:YES];
        
        DirectoryViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"DirectoryViewController"];
        vc.path = filePath;
        
        [self.navigationController pushViewController:vc animated:YES];
    }
}


#pragma mark - UITableViewDataSource

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        NSString *fileName = [self.contents objectAtIndex:indexPath.row];
        NSString *message = [NSString stringWithFormat:@"ATTENTION! For testing purposes only! Delete at your own risk! You may loose the selected or other files: %@", fileName];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Delete file?" message:message delegate:self cancelButtonTitle:@"CANCEL" otherButtonTitles:@"DELETE", nil];
        
        self.deleteAlert = alertView;
        self.deletePath = indexPath;
        
        [alertView show];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.contents count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *fileIdentifier = @"FileCell";
    static NSString *folderIdentifier = @"FolderCell";
    
    NSString *fileName = [self.contents objectAtIndex:indexPath.row];
    
    if ([self isDirectoryAtIndexPath:indexPath]){
        
        FolderCell *cell = [tableView dequeueReusableCellWithIdentifier:folderIdentifier];
        
        cell.textLabel.text = fileName;
        cell.detailTextLabel.text = @"Dir";
        
        NSString *folderSize = [self getFormattedSizeFromSize:[self getFolderSizeAtPath:[self getFilePathAtIndexPath:indexPath]]];
        cell.folderSizeLabel.text = folderSize;
        
        return cell;
    
    }else{
        
        NSString *filePath = [self.path stringByAppendingPathComponent:fileName];
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        
        FileCell *cell = [tableView dequeueReusableCellWithIdentifier:fileIdentifier];
        
        cell.textLabel.text = fileName;
        cell.detailTextLabel.text = @"File";
        cell.fileSizeLabel.text = [NSString stringWithFormat:@"%@", [self getFormattedSizeFromSize:[attributes fileSize]]];
        
        static NSDateFormatter * dateFormatter = nil;
        
        if(!dateFormatter){
            dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"MM/dd/yyyy hh:mm a"];
        }
        cell.modifiedLabel.text = [dateFormatter stringFromDate:[attributes fileModificationDate]];
        
        return cell;
    }
}


#pragma mark - Actions

-(void) addDirAction:(UIBarButtonItem *) sender{
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Add Directory" message:@"Enter directory name:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertView show];
}

-(void) navigateToRootAction:(UIBarButtonItem *) sender{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - UIAlertViewDelegate

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if([alertView isEqual:self.deleteAlert]){
        
        if (buttonIndex == 1){

            //delete file
            //NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
            NSString* deletePath = [self getFilePathAtIndexPath:self.deletePath];
            
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:deletePath error:&error];
            if(error){
                NSLog(@"%@", error.localizedDescription);
            }
            
            //remove from contents
            NSMutableArray *tmpContents = [NSMutableArray arrayWithArray:self.contents];
            [tmpContents removeObject:[deletePath lastPathComponent]];
            self.contents = tmpContents;
            
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:@[self.deletePath] withRowAnimation:UITableViewRowAnimationRight];
            [self.tableView endUpdates];
        }
        
    }else{
        
        if (buttonIndex == 1) {
            NSString *addDirName = [[alertView textFieldAtIndex:0] text];
            
            //add a directory
            NSString *filePath = [self.path stringByAppendingPathComponent:addDirName];
            
            NSError *error = nil;
            [[NSFileManager defaultManager] createDirectoryAtPath:filePath
                                      withIntermediateDirectories:NO
                                                       attributes:nil
                                                            error:&error];
            if(error){
                NSLog(@"%@", error.localizedDescription);
            }
            
            //add to contents
            NSMutableArray *tmpContents = [NSMutableArray arrayWithArray:self.contents];
            [tmpContents addObject:addDirName];
            [self sortDirsFilesInArray:tmpContents];
            self.contents = tmpContents;
            [self.tableView reloadData];
            
        }
    }
}


#pragma mark - Private methods

-(NSArray *) removeHiddenFilesFromContents:(NSArray *) contents{
    
    NSMutableArray *tmpContents = [NSMutableArray array];
    for (NSString *content in contents){
        
        if (![[content substringToIndex:1] isEqualToString:@"."]){
            [tmpContents addObject:content];
        }
    }
    
    return [NSArray arrayWithArray:tmpContents];
}

-(NSArray *) getContentAtPath:(NSString*) path{
    
    NSError *error = nil;
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path
                                                                        error:&error];
    if(error){
        NSLog(@"%@", error.localizedDescription);
    }
    
    return contents;
}

-(BOOL) isDirectoryAtIndexPath:(NSIndexPath *) indexPath{
    
    BOOL isDirectory = NO;
    
    NSString *filePath = [self getFilePathAtIndexPath:indexPath];
    [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
    
    return isDirectory;
}


-(NSString *) getFilePathAtIndexPath:(NSIndexPath *) indexPath{
    
    NSString *fileName = [self.contents objectAtIndex:indexPath.row];
    NSString *filePath = [self.path stringByAppendingPathComponent:fileName];
    
    return  filePath;
}


-(BOOL) isFileDirectory:(NSString *) fileName{
    
    BOOL isDirectory = NO;
    
    NSString *filePath = [self.path stringByAppendingPathComponent:fileName];
    [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
    
    return isDirectory;
}

-(BOOL) isFileDirectoryAtPath:(NSString *) path{
    
    BOOL isDirectory = NO;

    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
    
    return isDirectory;
}


-(NSMutableArray *) sortDirsFilesInArray:(NSMutableArray *) sourceArray{
    
    [sourceArray sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        if([self isFileDirectory:obj1] <= [self isFileDirectory:obj2]){
            return (NSComparisonResult)NSOrderedDescending;
        }else{
            return (NSComparisonResult)NSOrderedAscending;
        }
    }];
    
    return  sourceArray;
}


-(NSString *) getFormattedSizeFromSize:(unsigned long long) size{
    
    NSArray *units = [NSArray arrayWithObjects:@"B", @"KB", @"MB", @"GB", @"TB", nil];
    int index = 0;
    double fileSize = (double)size;
    
    while (fileSize > 1024 && index < [units count]) {
        fileSize /= 1024;
        index ++;
    }
    
    return [NSString stringWithFormat:@"%.2f %@", fileSize, [units objectAtIndex:index]];
}


-(unsigned long long) getFolderSizeAtPath:(NSString *) path{
    
    unsigned long long size = 0;
    NSArray *contents = [self removeHiddenFilesFromContents:[self getContentAtPath:path]];
    
    for(NSString *content in contents){
        
        NSString *filePath = [path stringByAppendingPathComponent:content];
        
        if ([self isFileDirectoryAtPath:filePath]) {
            
            size += [self getFolderSizeAtPath:
                     filePath];
        }else if(![[content substringToIndex:1] isEqualToString:@"."]){
            
             NSDictionary *attributes = [[NSFileManager defaultManager]
                                         attributesOfItemAtPath:filePath
                                         error:nil];
            
            size += [attributes fileSize];
        }
    }
    
    return size;
}

@end
