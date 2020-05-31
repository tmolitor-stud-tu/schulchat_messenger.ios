//
//  ParseStream.h
//  Monal
//
//  Created by Anurodh Pokharel on 6/29/13.
//
//

#import <Foundation/Foundation.h>
#import "XMPPParser.h"


@interface ParseStream :XMPPParser

@property (nonatomic,readonly, assign) BOOL supportsLegacyAuth;
@property (nonatomic,readonly, assign) BOOL supportsUserReg;
@property (nonatomic,readonly, assign) BOOL supportsSM3;
@property (nonatomic,readonly, assign) BOOL supportsCarbons2;
@property (nonatomic,readonly, assign) BOOL supportsRosterVer;


//Auth mechanisms
@property (nonatomic,readonly, assign) BOOL supportsSASL;
@property (nonatomic,readonly, assign) BOOL SASLSuccess;
@property (nonatomic,readonly, assign) BOOL SASLPlain;
@property (nonatomic,readonly, assign) BOOL SASLCRAM_MD5;
@property (nonatomic,readonly, assign) BOOL SASLDIGEST_MD5;

// xmpp state
@property (nonatomic,readonly, assign) BOOL callStartTLS;
@property (nonatomic,readonly, assign) BOOL startTLSProceed;

@property (nonatomic,readonly, assign) BOOL bind;

@property (nonatomic,readonly, assign) BOOL supportsClientState;


@end
