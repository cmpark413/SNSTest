//
//  KakaoViewController.h
//  SNSTest
//
//  Created by Chanmi Park on 2017. 2. 23..
//  Copyright © 2017년 SDTeam. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KakaoViewController : UIViewController

@property (nonatomic, weak) IBOutlet UILabel *idLabel;
@property (nonatomic, weak) IBOutlet UILabel *nicknameLabel;
@property (nonatomic, weak) IBOutlet UITextField *ageField;
@property (nonatomic, weak) IBOutlet UISegmentedControl *genderControl;
@property (nonatomic, weak) IBOutlet UIButton *saveBtn;
@property (nonatomic, weak) IBOutlet UIButton *logoutBtn;
@property (nonatomic, weak) IBOutlet UIButton *unlinkBtn;

-(IBAction)updateInfoKakao:(id)sender;
-(IBAction)logoutKakao:(id)sender;
-(IBAction)unlinkKakao:(id)sender;

@end

