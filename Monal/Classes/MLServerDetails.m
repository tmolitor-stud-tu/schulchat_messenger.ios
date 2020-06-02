//
//  MLServerDetails.m
//  Monal
//
//  Created by Anurodh Pokharel on 12/21/17.
//  Copyright © 2017 Monal.im. All rights reserved.
//

#import "MLServerDetails.h"
#import "UIColor+Theme.h"

@interface MLServerDetails ()

@property (nonatomic, strong) NSMutableArray *serverCaps;
@property (nonatomic, strong) NSMutableArray *srvRecords;

@end

@implementation MLServerDetails

enum MLServerDetailsSections {
    SUPPORTED_SERVER_XEPS_SECTION,
    SRV_RECORS_SECTION,
    ML_SERVER_DETAILS_SECTIONS_CNT
};

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void) checkServerCaps:(MLXMPPConnection*) connection {
    if(connection.supportsSM3)
    {
        [self.serverCaps addObject:@{@"Title":@"XEP-0198: Stream Management", @"Description":@"Resume a stream when disconnected. Results in faster reconnect and saves battery life."}];
    }
    
    if(connection.supportsPush)
    {
        [self.serverCaps addObject:@{@"Title":@"XEP-0357: Push Notifications", @"Description":@"Receive push notifications from via Apple even when disconnected. Vastly improves reliability. "}];
    }
    
    if(connection.usingCarbons2)
    {
        [self.serverCaps addObject:@{@"Title":@"XEP-0280: Message Carbons", @"Description":@"Synchronize your messages on all loggedin devices."}];
    }
    
    if(connection.supportsMam2)
    {
        [self.serverCaps addObject:@{@"Title":@"XEP-0313: Message Archive Management", @"Description":@"Access message archives on the server."}];
    }
    
    if(self.xmppAccount.connectionProperties.supportsHTTPUpload)
    {
        [self.serverCaps addObject:@{@"Title":@"XEP-0363: HTTP File Upload", @"Description":@"Upload files to the server to share with others."}];
    }
    
    if(connection.supportsClientState)
    {
        [self.serverCaps addObject:@{@"Title":@"XEP-0352: Client State Indication", @"Description":@"Indicate when a particular device is active or inactive. Saves battery. "}];
    }
}

-(void) convertSRVRecordsToReadable {
    BOOL foundCurrentConn = NO;

    for(id srvEntry in self.xmppAccount.discoveredServersList) {
        NSString* hostname = [srvEntry objectForKey:@"server"];
        NSNumber* port = [srvEntry objectForKey:@"port"];
        NSString* isSecure = [[srvEntry objectForKey:@"isSecure"] boolValue] ? @"Yes" : @"No";
        NSString* prio = [srvEntry objectForKey:@"priority"];

        // Check if entry is currently in use
        NSString* entryColor = @"None";
        if([self.xmppAccount.connectionProperties.server.connectServer isEqualToString:hostname] &&
           self.xmppAccount.connectionProperties.server.connectPort == port &&
           self.xmppAccount.connectionProperties.server.isDirectTLS == [isSecure boolValue])
        {
            entryColor = @"Green";
            foundCurrentConn = YES;
        } else if(!foundCurrentConn) {
            // Set the color of all connections entries that failed to red
            // discoveredServersList is sorted. Therfore all entries before foundCurrentConn == YES have failed
            entryColor = @"Red";
        }

        [self.srvRecords addObject:@{@"Title": [NSString stringWithFormat:@"Server: %@", hostname], @"Description": [NSString stringWithFormat:@"Port: %@, Is Secure: %@, Prio: %@", port, isSecure, prio], @"Color": entryColor}];
    }
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.serverCaps = [[NSMutableArray alloc] init];
    self.srvRecords = [[NSMutableArray alloc] init];
    
    self.navigationItem.title = self.xmppAccount.connectionProperties.identity.domain;

    [self checkServerCaps:self.xmppAccount.connectionProperties];
    [self convertSRVRecordsToReadable];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return ML_SERVER_DETAILS_SECTIONS_CNT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == SUPPORTED_SERVER_XEPS_SECTION) {
        return self.serverCaps.count;
    } else if(section == SRV_RECORS_SECTION) {
        return self.srvRecords.count;
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"serverCell" forIndexPath:indexPath];

    NSDictionary* dic;
    if(indexPath.section == SUPPORTED_SERVER_XEPS_SECTION) {
        dic = [self.serverCaps objectAtIndex:indexPath.row];
    } else if(indexPath.section == SRV_RECORS_SECTION) {
        dic = [self.srvRecords objectAtIndex:indexPath.row];
    }

    cell.textLabel.text = [dic objectForKey:@"Title"];
    cell.detailTextLabel.text = [dic objectForKey:@"Description"];

    // Add background color to selected cells
    if([dic objectForKey:@"Color"]) {
        NSString* entryColor = [dic objectForKey:@"Color"];
        // Remove background color from textLabel & detailTextLabel
        cell.textLabel.backgroundColor = UIColor.clearColor;
        cell.detailTextLabel.backgroundColor = UIColor.clearColor;

        if([entryColor isEqualToString:@"Green"]) {
            [cell setBackgroundColor:[UIColor colorWithRed:0 green:0.8 blue:0 alpha:0.2]];
        } else if([entryColor isEqualToString:@"Red"]) {
            [cell setBackgroundColor:[UIColor colorWithRed:0.8 green:0 blue:0 alpha:0.2]];
        }
    }
    return cell;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(section == SUPPORTED_SERVER_XEPS_SECTION) {
        return @"These are the modern XMPP capabilities Monal detected on your server after you've logged in. ";
    } else if(section == SRV_RECORS_SECTION) {
        return @"These are SRV resource records found for your domain";
    }
    return @"";
}

@end
