//
//  KakaoViewController.m
//  SNSTest
//
//  Created by Chanmi Park on 2017. 2. 23..
//  Copyright © 2017년 SDTeam. All rights reserved.
//

#import "KakaoViewController.h"
#import <KakaoOpenSDK/KakaoOpenSDK.h>

@interface KakaoViewController ()

@end

@implementation KakaoViewController

@synthesize idLabel, nicknameLabel, ageField, genderControl, saveBtn, logoutBtn, unlinkBtn;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    self.navigationItem.title = @"카카오";
    
    // @abstract 현재 로그인된 사용자에 대한 정보를 얻을 수 있습니다.
    // @param completionHandler 사용자 정보를 얻어 처리하는 핸들러
    [KOSessionTask meTaskWithCompletionHandler:^(KOUser* result, NSError *error) {
        if (result) {
            NSLog(@"카카오톡 accessToken: %@", [KOSession sharedSession].accessToken);
            NSLog(@"카카오톡 refreshToken: %@", [KOSession sharedSession].refreshToken);
            NSLog(@"카카오톡 id: %@", [NSString stringWithFormat:@"%@", result.ID]);
            NSLog(@"카카오톡 nickname: %@", [result propertyForKey:@"nickname"]);
            idLabel.text = [NSString stringWithFormat:@"%@", result.ID];
            nicknameLabel.text = [result propertyForKey:@"nickname"];
            ageField.text = [result propertyForKey:@"age"];
            NSString* gender = [result propertyForKey:@"gender"];
            if ([gender isEqualToString:@"Male"]) {
                [genderControl setSelectedSegmentIndex:0];
            } else if ([gender isEqualToString:@"Female"]) {
                [genderControl setSelectedSegmentIndex:1];
            }
        } else {
            NSLog(@"failed to get ID, Nickname.");
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)updateInfoKakao:(id)sender {
    NSString* gender = @"";
    NSString* age = 0;
    if (genderControl.selectedSegmentIndex == 0) {
        gender = @"Male";
    } else {
        gender = @"Female";
    }
    age = ageField.text;
    
    NSDictionary *properties = [[NSDictionary alloc] initWithObjectsAndKeys:age, @"age", gender, @"gender", nil];
    [KOSessionTask profileUpdateTaskWithProperties:properties completionHandler:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"succeeded to set my properties.");
            [self.view endEditing:YES];
            [self.view setNeedsDisplay];
        } else {
            NSLog(@"failed to set my properties.");
        }
    }];
}

// 로그아웃
- (IBAction)logoutKakao:(id)sender {
    [[KOSession sharedSession] logoutAndCloseWithCompletionHandler:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"logout success.");
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            NSLog(@"failed to logout.");
        }
    }];
}

- (IBAction)unlinkKakao:(id)sender {
    [KOSessionTask unlinkTaskWithCompletionHandler:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"unlink success.");
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            NSLog(@"unlink fail.");
        }
    }];
}

@end
