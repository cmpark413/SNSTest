//
//  AppDelegate.m
//  SNSTest
//
//  Created by Chanmi Park on 2017. 2. 20..
//  Copyright © 2017년 SDTeam. All rights reserved.
//

#import "AppDelegate.h"
#import <KakaoOpenSDK/KakaoOpenSDK.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "NaverThirdPartyLoginConnection.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    /* KAKAO */
    // 토큰 자동 갱신 - access token의 자동 주기적 갱신 여부 설정. 해당 값이 YES일 경우 handleDidBecomeActive시 및 특정 시간 주기로 필요시 토큰을 자동 갱신함
    //[KOSession sharedSession].automaticPeriodicRefresh = YES;
    
    /* FACEBOOK */
    [[FBSDKApplicationDelegate sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
    
    /* NAVER */
    NaverThirdPartyLoginConnection *naverConnection = [NaverThirdPartyLoginConnection getSharedInstance];
    [naverConnection setServiceUrlScheme:kServiceAppUrlScheme];
    [naverConnection setConsumerKey:kConsumerKey];
    [naverConnection setConsumerSecret:kConsumerSecret];
    [naverConnection setAppName:kServiceAppName];
    
    /* GOOGLE */
    NSError *configureError;
    [[GGLContext sharedInstance] configureWithError:&configureError];
    NSAssert(!configureError, @"Error configuring Google Services: %@", configureError);
   
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    /* KAKAO */
    // application이 background 상태로 변경시 알려준다. - 토큰 자동 갱신을 위한 코드..
    //[KOSession handleDidEnterBackground];
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    /* KAKAO */
    // openWithCompletionHandler로 인증 도중에 빠져나와 앱으로 돌아올때의 인증처리를 취소한다.
    //[KOSession handleDidBecomeActive];
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(nullable NSString *)sourceApplication annotation:(nonnull id)annotation {

    /* KAKAO */
    // 카카오계정 로그인 callback인지 여부
    // @param url 카카오 계정 인증 요청 code 또는 오류정보를 담은 url
    if ([KOSession isKakaoAccountLoginCallback:url]) {
        // url에 포함된 code 정보로 oauth 인증 토큰을 요청한다. 인증 토큰 요청이 완료되면 completionHandler를 실행한다.
        // @param url 인증 요청 code 또는 오류 정보(error, error_description)를 담은 url
        NSLog(@"카카오 : %@", url);
        return [KOSession handleOpenURL:url];
    }
    
    /* NAVER */
    if ([[url scheme] isEqualToString:kServiceAppUrlScheme]) {
        return [self handleWithUrl:url];
    }
    
    /* GOOGLE */
    BOOL googleRes = [[GIDSignIn sharedInstance] handleURL:url
                                         sourceApplication:sourceApplication
                                                annotation:annotation];
    if (googleRes)
        return googleRes;
    
    return NO;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    
    /* KAKAO */
    if ([KOSession isKakaoAccountLoginCallback:url]) {\
        NSLog(@"카카오 : %@", url);
        return [KOSession handleOpenURL:url];
    }
    
    /* FACEBOOK */
    BOOL facebookRes = [[FBSDKApplicationDelegate sharedInstance] application:application
                                                                  openURL:url
                                                        sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
                                                               annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
    if (facebookRes)
        return facebookRes;
    
    /* NAVER */
    if ([[url scheme] isEqualToString:kServiceAppUrlScheme]) {
        return [self handleWithUrl:url];
    }
    
    /* GOOGLE */
    BOOL googleRes = [[GIDSignIn sharedInstance] handleURL:url
                                         sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
                                                annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
    if (googleRes)
        return googleRes;
    
    return NO;
}

/* NAVER */
- (BOOL)handleWithUrl:(NSURL *)url {
    // 인증코드 및 접근토큰 획득
    if ([[url host] isEqualToString:kCheckResultPage]) {
        NaverThirdPartyLoginConnection *thirdConnection = [NaverThirdPartyLoginConnection getSharedInstance];
        // receiveAccessToken: - 응답받은 url의 값이 파라미터로 전달한 URL scheme와 동일한지 확인 한 후, 해당 url을 네아로 라이브러리에 전달
        THIRDPARTYLOGIN_RECEIVE_TYPE resultType = [thirdConnection receiveAccessToken:url];
        // 결과코드
        switch (resultType) {
            case SUCCESS:
                NSLog(@"Getting auth code from NaverApp success!");
                break;
            case PARAMETERNOTSET:
                NSLog(@"fail! - PARAMETERNOTSET");
                break;
            case CANCELBYUSER:
                NSLog(@"fail! - CANCELBYUSER");
                break;
            case NAVERAPPNOTINSTALLED:
                NSLog(@"fail! - NAVERAPPNOTINSTALLED");
                break;
            case NAVERAPPVERSIONINVALID:
                NSLog(@"fail! - NAVERAPPVERSIONINVALID");
                break;
            case OAUTHMETHODNOTSET:
                NSLog(@"fail! - OAUTHMETHODNOTSET");
                break;
            case INVALIDREQUEST:
                NSLog(@"fail! - INVALIDREQUEST");
                break;
            case CLIENTNETWORKPROBLEM:
                NSLog(@"fail! - CLIENTNETWORKPROBLEM");
                break;
            case UNAUTHORIZEDCLIENT:
                NSLog(@"fail! - UNAUTHORIZEDCLIENT");
                break;
            case UNSUPPORTEDRESPONSETYPE:
                NSLog(@"fail! - UNSUPPORTEDRESPONSETYPE");
                break;
            case NETWORKERROR:
                NSLog(@"fail! - NETWORKERROR");
                break;
            case UNKNOWNERROR:
                NSLog(@"fail! - UNKNOWNERROR");
                break;
            default:
                break;
        }
    }
    return YES;
}

@end
