//
//  ViewController.m
//  SNSTest
//
//  Created by Chanmi Park on 2017. 2. 20..
//  Copyright © 2017년 SDTeam. All rights reserved.
//

#import "ViewController.h"
#import <KakaoOpenSDK/KakaoOpenSDK.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <Google/SignIn.h>
#import "KakaoViewController.h"
#import "NaverThirdPartyLoginConnection.h"
#import "NLoginThirdPartyOAuth20InAppBrowserViewController.h"

@interface ViewController () <FBSDKLoginButtonDelegate, NaverThirdPartyLoginConnectionDelegate, GIDSignInDelegate, GIDSignInUIDelegate> {
    UIButton* kakaoLoginBtn;
    FBSDKLoginButton *facebookLoginBtn;
    UIButton *naverLoginBtn;
    GIDSignInButton *googleSignInBtn;
    
    NSString *loginInfoStr;
    BOOL isLogin, isKakaoLogin, isFacebookLogin, isNaverLogin, isGoogleLogin;
}

@end

@implementation ViewController

@synthesize LoginInfoLabel;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /* KAKAO */
    // 인증되어 있는지 여부
    if ([[KOSession sharedSession] isOpen]) {
        // 현재 로그인된 사용자의 AccessTokenInfo 정보를 얻을 수 있습니다.
        // @param completionHandler 요청 완료시 실행될 핸들러
        /*[KOSessionTask accessTokenInfoTaskWithCompletionHandler:^(KOAccessTokenInfo *accessTokenInfo, NSError *error) {
            if (error) {
                switch (error.code) {
                    case KOErrorDeactivatedSession:
                        // 세션이 만료된(access_token, refresh_token이 모두 만료된 경우) 상태
                        NSLog(@"[1] 카카오 - 세션이 만료된(access_token, refresh_token이 모두 만료된 경우) 상태");
                        break;
                    default:
                        // 예기치 못한 에러. 서버 에러
                        NSLog(@"[1] 카카오 - 예기치 못한 에러. 서버 에러");
                        break;
                }
            } else {
                // 성공 (토큰이 유효함)
                NSLog(@"access token: %@", [[KOSession sharedSession] accessToken]);
                NSLog(@"refresh token: %@", [[KOSession sharedSession] refreshToken]);
                NSLog(@"남은 유효시간: %@ (단위: ms)", accessTokenInfo.expiresInMillis);
            }
        }];*/
        NSLog(@"[카카오] access token: %@", [[KOSession sharedSession] accessToken]);
        NSLog(@"[카카오] refresh token: %@", [[KOSession sharedSession] refreshToken]);
        KakaoViewController *kakaoViewController = [[KakaoViewController alloc] init];
        [self.navigationController pushViewController:kakaoViewController animated:YES];
        kakaoViewController = nil;
    }
    
    int xMargin = 30;
    int marginBottom = 25;
    CGFloat btnWidth = self.view.frame.size.width - xMargin * 2;
    int btnHeight = 42;
    kakaoLoginBtn = [[KOLoginButton alloc] initWithFrame:CGRectMake(xMargin, self.view.frame.size.height - btnHeight - marginBottom, btnWidth, btnHeight)];
    kakaoLoginBtn.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:kakaoLoginBtn];
    [kakaoLoginBtn addTarget:self action:@selector(invokeLoginWithTarget:) forControlEvents:UIControlEventTouchUpInside];
    
    /* FACEBOOK */
    // 현재 로그인 상태 확인 - 사용자가 현재 앱에 로그인했음을 표시
    if ([FBSDKAccessToken currentAccessToken]) {
        NSLog(@"만료일: %@", [[FBSDKAccessToken currentAccessToken] expirationDate]);
        NSLog(@"오오늘: %@", [NSDate date]);
        NSLog(@"페이스북 토큰: %@", [[FBSDKAccessToken currentAccessToken] tokenString]);
        if ([[FBSDKAccessToken currentAccessToken] expirationDate] == [[[FBSDKAccessToken currentAccessToken] expirationDate] earlierDate:[NSDate date]]) {
            NSLog(@"페이스북 - 토큰 만료됨!!");
            [FBSDKAccessToken refreshCurrentAccessToken:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                if (error) {
                    NSLog(@"페이스북 - 토큰 재발급 실패");
                } else {
                    NSLog(@"페이스북 - 재발급 성공");
                    NSLog(@"재발급 만료일: %@", [[FBSDKAccessToken currentAccessToken] expirationDate]);
                    NSLog(@"재발급 페이스북 토큰: %@", [[FBSDKAccessToken currentAccessToken] tokenString]);
                }
            }];
        }
        // userID - 사용자 식별에 사용 가능
        loginInfoStr = [NSString stringWithFormat:@"FACEBOOK\nUserName: %@\nUserID: %@",
                        [FBSDKProfile currentProfile].name, [FBSDKProfile currentProfile].userID];
        LoginInfoLabel.text = loginInfoStr;
    }
    // 페이스북 로그인 버튼 추가
    facebookLoginBtn = [[FBSDKLoginButton alloc] initWithFrame:CGRectMake(xMargin, self.view.frame.size.height - 2*btnHeight - marginBottom - 10, btnWidth, btnHeight)];
    [self.view addSubview:facebookLoginBtn];
    // 공개 프로필, 이메일 정보 읽기 권한
    facebookLoginBtn.readPermissions = @[@"public_profile", @"email"];
    // 로그인 결과 및 로그아웃 이벤트 알림을 받기 위한 delegate 할당
    facebookLoginBtn.delegate = self;
    // 페이스북 프로필 정보 얻어오기 위한 코드
    [FBSDKProfile enableUpdatesOnAccessTokenChange:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(profileUpdated:) name:FBSDKProfileDidChangeNotification object:nil];
    
    /* NAVER */
    naverLoginBtn = [[UIButton alloc] initWithFrame:CGRectMake(xMargin, self.view.frame.size.height - 3*btnHeight - marginBottom - 20, btnWidth, btnHeight)];
    [naverLoginBtn setImage:[UIImage imageNamed:@"NaverAuth.bundle/naver_login_green.png"] forState:UIControlStateNormal];
    [self.view addSubview:naverLoginBtn];
    [naverLoginBtn addTarget:self action:@selector(requestThirdpartyLogin:) forControlEvents:UIControlEventTouchUpInside];
    // 접근 토큰이 유효한지 체크 (접근 토큰이 있고, 유효기간이 남아있는 경우 YES / 접근 토큰이 없거나 유효기간이 지난 경우 NO 반환)
    if (![[NaverThirdPartyLoginConnection getSharedInstance] isValidAccessTokenExpireTimeNow]) {
        // 네이버 - 유효기간이 지난 접근 토큰은 requestAccessTokenWithRefreshToken 메서드로 재발급을 요청!
        NSLog(@"네이버 접근 토큰이 유효하지 않아요. 재발급을 요청합니다!");
        [NaverThirdPartyLoginConnection getSharedInstance].delegate = self;
        [[NaverThirdPartyLoginConnection getSharedInstance] requestAccessTokenWithRefreshToken];
    } else {
        isNaverLogin = YES;
        [naverLoginBtn setImage:[UIImage imageNamed:@"NaverAuth.bundle/naver_logout_green.png"] forState:UIControlStateNormal];
        NaverThirdPartyLoginConnection *naverConnection = [NaverThirdPartyLoginConnection getSharedInstance];
        NSString *accessToken = naverConnection.accessToken;
        loginInfoStr = [NSString stringWithFormat:@"NAVER\nAccess Token: %@", accessToken];
        LoginInfoLabel.text = loginInfoStr;
        
        NSLog(@"네이버 access token: %@", naverConnection.accessToken);
        NSLog(@"네이버 accessTokenExpireDate: %@", naverConnection.accessTokenExpireDate);
        NSLog(@"네이버 refresh token: %@", naverConnection.refreshToken);
        NSLog(@"네이버 tokenType: %@", naverConnection.tokenType);
        NSString *urlString = @"https://openapi.naver.com/v1/nid/getUserProfile.xml";  // 사용자 프로필 호출
        NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
        NSString *authValue = [NSString stringWithFormat:@"Bearer %@", naverConnection.accessToken];
        [urlRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
        NSHTTPURLResponse *response = nil;
        NSError *error = nil;
        NSData *receivedData = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
        NSString *decodingString = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
        if (error) {
            NSLog(@"Error happened - %@", [error description]);
        } else {
            NSLog(@"네이버 recevied data - %@", decodingString);
        }
    }
    
    /* GOOGLE */
    // GIDSignInDelegate, GIDSignInUIDelegate 등록
    [GIDSignIn sharedInstance].delegate = self;
    [GIDSignIn sharedInstance].uiDelegate = self;
    // 사용자가 현재 로그인했거나, 이전에 인증했는지 여부..
    if ([[GIDSignIn sharedInstance] hasAuthInKeychain]) {
        // 상호작용없이 이전에 인증된 사용자를 로그인
        [[GIDSignIn sharedInstance] signInSilently];
    }
    googleSignInBtn = [[GIDSignInButton alloc] initWithFrame:CGRectMake(xMargin, self.view.frame.size.height - 4*btnHeight - marginBottom - 30, btnWidth, btnHeight)];
    [self.view addSubview:googleSignInBtn];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - KAKAO
- (IBAction)invokeLoginWithTarget:(id)sender {
    // 인증 토큰을 제거하여 session을 무효화한다.
    [[KOSession sharedSession] close];
    
    // 기기의 로그인 수행 가능한 카카오 앱에 로그인 요청을 전달한다.
    // @param completionHandler 요청 완료시 실행될 block. 오류 처리와 로그인 완료 작업을 수행한다.
    // @param authParams 로그인 요청시의 인증에 필요한 부가적인 파라미터들을 전달한다.
    // @param authType 로그인 요청시의 인증 타입(KOAuthType)의 array(var arguments로서 nil-terminated list). 주의) list의 마지막은 꼭 nil로 끝나야함. 예) KOAuthTypeTalk, KOAuthTypeStory, KOAuthTypeAccount, nil
    [[KOSession sharedSession] openWithCompletionHandler:^(NSError *error) {
        if ([[KOSession sharedSession] isOpen]) {
            NSLog(@"kakao login succeeded.");
            NSLog(@"카카오톡 accessToken: %@", [KOSession sharedSession].accessToken);
            NSLog(@"카카오톡 refreshToken: %@", [KOSession sharedSession].refreshToken);
            KakaoViewController *kakaoViewController = [[KakaoViewController alloc] init];
            [self.navigationController pushViewController:kakaoViewController animated:YES];
            kakaoViewController = nil;
        } else {
            NSLog(@"kakao login failed.");
        }
    } authParams:nil authType:(KOAuthType)KOAuthTypeTalk, (KOAuthType)KOAuthTypeAccount, nil];
}

#pragma mark - FACEBOOK
-(void)profileUpdated:(NSNotification *) notification {
    loginInfoStr = [NSString stringWithFormat:@"FACEBOOK\nUserName: %@\nUserID: %@", [FBSDKProfile currentProfile].name, [FBSDKProfile currentProfile].userID];
    LoginInfoLabel.text = loginInfoStr;
    //NSLog(@"페이스북 로그인 토큰 만료: %@", [FBSDKAccessToken currentAccessToken].expirationDate);
    //NSLog(@"페이스북 로그인 토큰: %@", [[FBSDKAccessToken currentAccessToken] tokenString]);
    
    //NSLog(@"페이스북 access token - appID: %@", [[FBSDKAccessToken currentAccessToken] appID]);
    NSLog(@"페이스북 access token - declinedPermissions: %@", [[FBSDKAccessToken currentAccessToken] declinedPermissions]);
    NSLog(@"페이스북 access token - expirationDate: %@", [[FBSDKAccessToken currentAccessToken] expirationDate]);
    NSLog(@"페이스북 access token - permissions: %@", [[FBSDKAccessToken currentAccessToken] permissions]);
    NSLog(@"페이스북 access token - refreshDate: %@", [[FBSDKAccessToken currentAccessToken] refreshDate]);
    NSLog(@"페이스북 access token - tokenString: %@", [[FBSDKAccessToken currentAccessToken] tokenString]);
    NSLog(@"페이스북 access token - userID: %@", [[FBSDKAccessToken currentAccessToken] userID]);
    NSLog(@"페이스북 profile - userID: %@", [FBSDKProfile currentProfile].userID);
    NSLog(@"페이스북 profile - firstName: %@", [FBSDKProfile currentProfile].firstName);
    NSLog(@"페이스북 profile - middleName: %@", [FBSDKProfile currentProfile].middleName);
    NSLog(@"페이스북 profile - lastName: %@", [FBSDKProfile currentProfile].lastName);
    NSLog(@"페이스북 profile - name: %@", [FBSDKProfile currentProfile].name);
    NSLog(@"페이스북 profile - linkURL: %@", [FBSDKProfile currentProfile].linkURL);
    NSLog(@"페이스북 profile - refreshDate: %@", [FBSDKProfile currentProfile].refreshDate);
    
}

#pragma mark FBSDKLoginButtonDelegate
// 로그인 직후
- (void)loginButton:(FBSDKLoginButton *)loginButton didCompleteWithResult:(FBSDKLoginManagerLoginResult *)result error:(NSError *)error {
    // 권한 검사, 로그인 취소 여부...
}
// 로그인 버튼 클릭 시 호출
- (BOOL)loginButtonWillLogin:(FBSDKLoginButton *)loginButton {
    return YES;
}
// 로그아웃
- (void)loginButtonDidLogOut:(FBSDKLoginButton *)loginButton {
    loginInfoStr = @"Log Out";
    LoginInfoLabel.text = loginInfoStr;
}

#pragma mark - NAVER
- (IBAction)requestThirdpartyLogin:(id)sender {
    NaverThirdPartyLoginConnection *naverConnection = [NaverThirdPartyLoginConnection getSharedInstance];
    if (isNaverLogin) {
        // 로그아웃 - 앱에 저장된 토큰 정보 삭제
        [naverConnection resetToken];
        isNaverLogin = NO;
        [naverLoginBtn setImage:[UIImage imageNamed:@"NaverAuth.bundle/naver_login_green.png"] forState:UIControlStateNormal];
        LoginInfoLabel.text = @"";
    } else {
        naverConnection.delegate = self;
        // 네이버 앱/ 인앱 브라우저 이용 여부..
        [naverConnection setIsInAppOauthEnable:YES];
        [naverConnection setIsNaverAppOauthEnable:YES];
        // 네아로 설정
        [naverConnection setConsumerKey:kConsumerKey];
        [naverConnection setConsumerSecret:kConsumerSecret];
        [naverConnection setAppName:kServiceAppName];
        [naverConnection setServiceUrlScheme:kServiceAppUrlScheme];
        // 네이버 로그인 요청
        [naverConnection requestThirdPartyLogin];
    }
}

#pragma mark NaverThirdPartyLoginConnectionDelegate
// 로그인 성공
- (void)oauth20ConnectionDidFinishRequestACTokenWithAuthCode {
    NSLog(@"네이버 로그인 성공");
    isNaverLogin = YES;
    [naverLoginBtn setImage:[UIImage imageNamed:@"NaverAuth.bundle/naver_logout_green.png"] forState:UIControlStateNormal];
    NaverThirdPartyLoginConnection *naverConnection = [NaverThirdPartyLoginConnection getSharedInstance];
    NSString *accessToken = naverConnection.accessToken;
    loginInfoStr = [NSString stringWithFormat:@"NAVER\nAccess Token: %@", accessToken];
    LoginInfoLabel.text = loginInfoStr;
    NSLog(@"네이버 Access Token: %@", accessToken);
    NSLog(@"네이버 토큰 만료 시간: %@", [NaverThirdPartyLoginConnection getSharedInstance].accessTokenExpireDate);
    
    NSLog(@"네이버 access token: %@", naverConnection.accessToken);
    NSLog(@"네이버 accessTokenExpireDate: %@", naverConnection.accessTokenExpireDate);
    NSLog(@"네이버 refresh token: %@", naverConnection.refreshToken);
    NSLog(@"네이버 tokenType: %@", naverConnection.tokenType);
    NSString *urlString = @"https://openapi.naver.com/v1/nid/getUserProfile.xml";  // 사용자 프로필 호출
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    NSString *authValue = [NSString stringWithFormat:@"Bearer %@", naverConnection.accessToken];
    [urlRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
    NSHTTPURLResponse *response = nil;
    NSError *error = nil;
    NSData *receivedData = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
    NSString *decodingString = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
    if (error) {
        NSLog(@"Error happened - %@", [error description]);
    } else {
        NSLog(@"네이버 recevied data - %@", decodingString);
    }
    
}
// 로그인 실패 / 토큰 갱신 실패
- (void)oauth20Connection:(NaverThirdPartyLoginConnection *)oauthConnection didFailWithError:(NSError *)error {
    NSLog(@"네이버 로그인 실패 or 토큰 갱신 실패");
}
- (void)oauth20ConnectionDidOpenInAppBrowserForOAuth:(NSURLRequest *)request {
    NLoginThirdPartyOAuth20InAppBrowserViewController *inAppBrowserViewController = [[NLoginThirdPartyOAuth20InAppBrowserViewController alloc] initWithRequest:request];
    inAppBrowserViewController.parentOrientation = (UIInterfaceOrientation)[[UIDevice currentDevice] orientation];
    [self presentViewController:inAppBrowserViewController animated:NO completion:nil];
}
- (void)oauth20ConnectionDidFinishRequestACTokenWithRefreshToken {
    NSLog(@"토큰 재발급 성공");
    NSLog(@"네이버 Access Token: %@", [NaverThirdPartyLoginConnection getSharedInstance].accessToken);
    
    NaverThirdPartyLoginConnection* naverConnection = [NaverThirdPartyLoginConnection getSharedInstance];
    NSLog(@"네이버 access token: %@", naverConnection.accessToken);
    NSLog(@"네이버 accessTokenExpireDate: %@", naverConnection.accessTokenExpireDate);
    NSLog(@"네이버 refresh token: %@", naverConnection.refreshToken);
    NSLog(@"네이버 tokenType: %@", naverConnection.tokenType);
    NSString *urlString = @"https://openapi.naver.com/v1/nid/getUserProfile.xml";  // 사용자 프로필 호출
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    NSString *authValue = [NSString stringWithFormat:@"Bearer %@", naverConnection.accessToken];
    [urlRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
    NSHTTPURLResponse *response = nil;
    NSError *error = nil;
    NSData *receivedData = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
    NSString *decodingString = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
    if (error) {
        NSLog(@"Error happened - %@", [error description]);
    } else {
        NSLog(@"네이버 recevied data - %@", decodingString);
    }
}
- (void)oauth20ConnectionDidFinishDeleteToken {
    NSLog(@"네이버 인증해제");
}

#pragma mark - GOOGLE
#pragma mark GIDSignInUIDelegate
// pressed the Sign In button
- (void)signInWillDispatch:(GIDSignIn *)signIn error:(NSError *)error {
    // 로그인 버튼 클릭 시, 로그인 상태면 로그아웃 처리
    if ([signIn hasAuthInKeychain]) {
        [signIn signOut];
    }
}

// Present a view that prompts the user to sign in with Google
- (void)signIn:(GIDSignIn *)signIn presentViewController:(UIViewController *)viewController {
    [self presentViewController:viewController animated:YES completion:nil];
}

// Dismiss the "Sign in with Google" view
- (void)signIn:(GIDSignIn *)signIn dismissViewController:(UIViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark GIDSignInDelegate
// 구글 로그인/로그아웃 결과로 call됨
- (void)signIn:(GIDSignIn *)signIn didSignInForUser:(GIDGoogleUser *)user withError:(NSError *)error {
    // error가 nil이면 성공
    NSLog(@"구글 접근 토큰 만료: %@", [user.authentication accessTokenExpirationDate]);
    NSLog(@"접근 토큰: %@", [user.authentication accessToken]);
    /*NSDate *accessTokenExpireDate = [user.authentication accessTokenExpirationDate];
    NSDate *idTokenExpireDate = [user.authentication idTokenExpirationDate];
    if (accessTokenExpireDate == [accessTokenExpireDate earlierDate:[NSDate date]]
        || idTokenExpireDate == [idTokenExpireDate earlierDate:[NSDate date]]) {
        NSLog(@"구글 토큰 만료 지남");
        // 접근 토큰과 ID 토큰 refresh
        [user.authentication refreshTokensWithHandler:^(GIDAuthentication *authentication, NSError *error) {
            if (error) {
                NSLog(@"구글 재발급 실패");
            } else {
                NSLog(@"구글 재발급 성공");
                NSLog(@"[재발급] 구글 접근 토큰 만료: %@", [authentication accessTokenExpirationDate]);
                NSLog(@"[재발급] 구글 ID 토큰 만료: %@", [authentication idTokenExpirationDate]);
                NSLog(@"접근 토큰: %@", [user.authentication accessToken]);
                NSLog(@"ID 토큰: %@", [user.authentication idToken]);
                
            }
        }];
    }*/
    NSLog(@"구글 GIDGoogleUser - userID: %@", user.userID);
    NSLog(@"구글 GIDAuthentication - access token: %@", [user.authentication accessToken]);
    NSLog(@"구글 GIDAuthentication - refresh token: %@", [user.authentication refreshToken]);
    NSLog(@"구글 GIDAuthentication - accessTokenExpirationDate: %@", [user.authentication accessTokenExpirationDate]);
    NSLog(@"구글 GIDAuthentication - id token: %@", [user.authentication idToken]);
    NSLog(@"구글 GIDAuthentication - idTokenExpirationDate: %@", [user.authentication idTokenExpirationDate]);
    NSLog(@"구글 GIDProfileData - email: %@", user.profile.email);
    NSLog(@"구글 GIDProfileData - name: %@", user.profile.name);
    NSLog(@"구글 GIDProfileData - givenName: %@", user.profile.givenName);
    NSLog(@"구글 GIDProfileData - familyName: %@", user.profile.familyName);
    
    if ([signIn hasAuthInKeychain]) {
        loginInfoStr = [NSString stringWithFormat:@"GOOGLE\nID: %@\nfullName: %@", user.userID, user.profile.name];
        LoginInfoLabel.text = loginInfoStr;
    } else {
        loginInfoStr = @"GOOGLE LOGOUT";
        LoginInfoLabel.text = loginInfoStr;
    }
}

@end
