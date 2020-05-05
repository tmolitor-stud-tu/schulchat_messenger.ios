//
//  MLPush.m
//  Monal
//
//  Created by Anurodh Pokharel on 9/16/19.
//  Copyright © 2019 Monal.im. All rights reserved.
//

#import "MLPush.h"
#import "MLXMPPManager.h"




@implementation MLPush


+(NSString *) stringFromToken:(NSData *) tokenIn {
    unsigned char *tokenBytes = (unsigned char *)[tokenIn bytes];
    
    NSMutableString *token = [[NSMutableString alloc] init];
    NSInteger counter=0;
    while(counter< tokenIn.length)
    {
        [token appendString:[NSString stringWithFormat:@"%02x", (unsigned char) tokenBytes[counter]]];
        counter++;
    }
    
    return token;
}

-(void) postToPushServer:(NSString *) token {
#ifndef TARGET_IS_EXTENSION
    NSString *node = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    NSString *post = [NSString stringWithFormat:@"type=apns&node=%@&token=%@", [node stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]],
                      [token stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%luld",[postData length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    //this is the hardcoded push api endpoint
    
    NSString *path =[NSString stringWithFormat:@"%@/register", PUSH_SERVER];
    [request setURL:[NSURL URLWithString:path]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            NSHTTPURLResponse *httpresponse= (NSHTTPURLResponse *) response;
            
            if(!error && httpresponse.statusCode==200)
            {
                DDLogInfo(@"connection to push api successful");
                
                NSString *responseBody = [[NSString alloc] initWithData:data  encoding:NSUTF8StringEncoding];
                DDLogInfo(@"push api returned: %@", responseBody);
                NSArray *responseParts=[responseBody componentsSeparatedByString:@"\n"];
                if(responseParts.count>0){
                    if([responseParts[0] isEqualToString:@"OK"] && [responseParts count]==3)
                    {
                        DDLogInfo(@"push api: node='%@', secret='%@'", responseParts[1], responseParts[2]);
                        [[MLXMPPManager sharedInstance] setPushNode:responseParts[1] andSecret:responseParts[2]];
                        return;
                    }
                    else {
                        DDLogError(@" push api returned invalid data: %@", [responseParts componentsJoinedByString: @" | "]);
                    }
                } else {
                    DDLogError(@"push api could  not be broken into parts");
                }
                
            } else
            {
                DDLogError(@" connection to push api NOT successful");
            }
            //use saved secret
            [[MLXMPPManager sharedInstance] setPushNode:node andSecret:nil];
        }] resume];
    });
#endif
}


-(void) unregisterPush
{
#ifndef TARGET_IS_EXTENSION
    NSString *node = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    NSString *post = [NSString stringWithFormat:@"type=apns&node=%@", [node stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%luld",[postData length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSString *path =[NSString stringWithFormat:@"%@/unregister", PUSH_SERVER];
    [request setURL:[NSURL URLWithString:path]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            NSHTTPURLResponse *httpresponse= (NSHTTPURLResponse *) response;
            
            if(!error && httpresponse.statusCode<400)
            {
                DDLogInfo(@"connection to push api successful");
                
                NSString *responseBody = [[NSString alloc] initWithData:data  encoding:NSUTF8StringEncoding];
                DDLogInfo(@"push api returned: %@", responseBody);
                NSArray *responseParts=[responseBody componentsSeparatedByString:@"\n"];
                if(responseParts.count>0){
                    if([responseParts[0] isEqualToString:@"OK"] )
                    {
                        DDLogInfo(@"push api: unregistered");
                    }
                    else {
                        DDLogError(@" push api returned invalid data: %@", [responseParts componentsJoinedByString: @" | "]);
                    }
                } else {
                    DDLogError(@"push api could  not be broken into parts");
                }
                
            } else
            {
                DDLogError(@" connection to push api NOT successful");
            }
            
        }] resume];
    });
#endif
}

@end
