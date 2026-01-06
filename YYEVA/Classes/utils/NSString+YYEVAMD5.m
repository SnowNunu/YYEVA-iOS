//
//  NSString+YYEVAMD5.m
//  YYEVA
//
//  Created by Mandora on 1/6/26.
//

#import "NSString+YYEVAMD5.h"

#import <CommonCrypto/CommonDigest.h>

@implementation NSString (YYEVAMD5)

- (NSString *)yyeva_md5String {
    const char *cStr = [self UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    
    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02x", result[i]];
    }
    return ret;
}

@end
