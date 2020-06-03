//
//  MLBackgroundSettings.m
//  Monal
//
//  Created by Anurodh Pokharel on 11/19/18.
//  Copyright © 2018 Monal.im. All rights reserved.
//

#import "MLBackgroundSettings.h"
#import "MLSettingCell.h"
#import "MLImageManager.h"
@import CoreServices;
@import AVFoundation;

@interface MLBackgroundSettings ()
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) NSArray *imageList;
@property (nonatomic, assign) NSUInteger selectedIndex;
@property (nonatomic, assign) NSUInteger displayedPhotoIndex;
@property (nonatomic, strong) UIImage *leftImage;
@property (nonatomic, strong) UIImage *rightImage;

@end

@implementation MLBackgroundSettings

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title=@"Hintergrundbilder";
    
    self.imageList = @[@"Golden_leaves_by_Mauro_Campanelli",
                       @"Stop_the_light_by_Mato_Rachela",
                       @"THE_'OUT'_STANDING_by_ydristi",
                       @"Tie_My_Boat_by_Ray_García",
                       @"Winter_Fog_by_Daniel_Vesterskov",
                       ];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

-(NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Hintergrundbild für Chats auswählen";
}

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return @"Die Standardhintergrundbilder sind aus Ubuntu." ;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell* toreturn;
    switch (indexPath.row) {
        case 0: {
            MLSettingCell* cell=[[MLSettingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"AccountCell"];
            cell.parent= self;
            cell.switchEnabled=YES;
            cell.defaultKey=@"ChatBackgrounds";
            cell.textLabel.text=@"Chat Hintergrundbilder verwenden";
            toreturn=cell;
            break;
        }
            
        case 1: {
           UITableViewCell* cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SelectCell"];
            cell.textLabel.text=@"Hintergrundbild auswählen";
            cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
            toreturn=cell;
            break;
        }
            
        case 2: {
            UITableViewCell* cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SelectCell"];
#if TARGET_OS_MACCATALYST
            cell.textLabel.text=@"Bilddatei auswählen";
#else
            cell.textLabel.text=@"Hintergrundbild aus der Gallerie auswählen";
#endif
            cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
            toreturn=cell;
            break;
        }
            
        default:
            break;
    }
   
    return toreturn;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    switch(indexPath.row)
    {
        case 1: {
            [self showImages];
            break;
        }
        case 2: {
            [self showPhotos];
            break;
        }
        default: break;
            
    }
    
}

-(void) showPhotos
{
#if TARGET_OS_MACCATALYST
    //UTI @"public.data" for everything
    NSString *images = (NSString *)kUTTypeImage;
   UIDocumentPickerViewController *imagePicker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[images] inMode:UIDocumentPickerModeImport];
    imagePicker.allowsMultipleSelection=NO;
    imagePicker.delegate=self;
    [self presentViewController:imagePicker animated:YES completion:nil];
#else
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate =self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        if(granted)
        {
            [self presentViewController:imagePicker animated:YES completion:nil];
        }
    }];
#endif
}


-(void) showImages
{
    self.photos = [NSMutableArray array];

    NSString *currentBackground = [[NSUserDefaults standardUserDefaults] objectForKey:@"BackgroundImage"];
    self.selectedIndex=-1;
    // Add photos
    [self.imageList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *name =(NSString *) obj;
        IDMPhoto *photo= [IDMPhoto photoWithImage:[UIImage imageNamed:name]];
        photo.caption = [name stringByReplacingOccurrencesOfString:@"_" withString:@" "];
        [self.photos addObject:photo];
        
        if([currentBackground isEqualToString:name])
        {
            self.selectedIndex=idx;
        }
    }];
 
    // Create browser (must be done each time photo browser is
    // displayed. Photo browser objects cannot be re-used)
    IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:self.photos];
    browser.navigationItem.title=@"Hintergrundbild auswählen";
    browser.delegate=self;
    UIBarButtonItem *close = [[UIBarButtonItem alloc] initWithTitle:@"Schließen" style:UIBarButtonItemStyleDone target:self action:@selector(close)];
    browser.navigationItem.rightBarButtonItem=close;
    
    browser.autoHideInterface=NO;
    browser.displayArrowButton = YES;
    browser.displayCounterLabel = YES;
    browser.displayActionButton=NO;
    browser.displayToolbar=YES;
    
    self.leftImage=[UIImage imageNamed:@"IDMPhotoBrowser_arrowLeft"];
    self.rightImage=[UIImage imageNamed:@"IDMPhotoBrowser_arrowRight"];
    browser.leftArrowImage =self.leftImage;
    browser.rightArrowImage =self.rightImage;

    UINavigationController *nav =[[UINavigationController alloc] initWithRootViewController:browser];

    // Present
    [self presentViewController:nav animated:YES completion:nil];
}

-(void) close {
    [[NSUserDefaults standardUserDefaults] setObject:[self.imageList objectAtIndex:self.displayedPhotoIndex] forKey:@"BackgroundImage"];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls
{
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] init];
    [coordinator coordinateReadingItemAtURL:urls.firstObject options:NSFileCoordinatorReadingForUploading error:nil byAccessor:^(NSURL * _Nonnull newURL) {
        NSData *data =[NSData dataWithContentsOfURL:newURL];
        if([[MLImageManager sharedInstance] saveBackgroundImageData:data]) {
            [[NSUserDefaults standardUserDefaults] setObject:@"CUSTOM" forKey:@"BackgroundImage"];
        }
    }];
}

#pragma mark - photo browser delegate
- (void)photoBrowser:(IDMPhotoBrowser *)photoBrowser didShowPhotoAtIndex:(NSUInteger)index
{
   self.displayedPhotoIndex=index;
}

- (void)photoBrowser:(IDMPhotoBrowser *)photoBrowser didDismissAtPageIndex:(NSUInteger)index
{
    [[NSUserDefaults standardUserDefaults] setObject:[self.imageList objectAtIndex:index] forKey:@"BackgroundImage"];
}

#pragma mark - image picker delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    if([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        UIImage *selectedImage= info[UIImagePickerControllerEditedImage];
        if(!selectedImage) selectedImage= info[UIImagePickerControllerOriginalImage];
        NSData *jpgData=  UIImageJPEGRepresentation(selectedImage, 0.5f);
        if(jpgData)
        {
            
            if([[MLImageManager sharedInstance] saveBackgroundImageData:jpgData]) {
                [[NSUserDefaults standardUserDefaults] setObject:@"CUSTOM" forKey:@"BackgroundImage"];
            }
            
        }
        
    }
    
}



- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
