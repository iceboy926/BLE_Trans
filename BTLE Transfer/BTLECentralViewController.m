/*
 
 File: LECentralViewController.m
 
 Abstract: Interface to use a CBCentralManager to scan for, and receive
 data from, a version of the app in Peripheral Mode
 
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by
 Apple Inc. ("Apple") in consideration of your agreement to the
 following terms, and your use, installation, modification or
 redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use,
 install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc.
 may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple.  Except
 as expressly stated in this notice, no other rights or licenses, express
 or implied, are granted by Apple herein, including but not limited to
 any patent rights that may be infringed by your derivative works or by
 other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
 */

#import "BTLECentralViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

#import "TransferService.h"

@interface BTLECentralViewController () <CBCentralManagerDelegate, CBPeripheralDelegate, UITextViewDelegate>

//@property (strong, nonatomic) IBOutlet UITextView   *textview;
@property (strong, nonatomic) CBCentralManager      *centralManager;
@property (strong, nonatomic) CBPeripheral          *discoveredPeripheral;
@property (strong, nonatomic) CBPeripheral          *connectPeripheral;
@property (strong, nonatomic) CBCharacteristic      *character;
@property (strong, nonatomic) NSMutableData         *data;
@property (strong, nonatomic) CBCharacteristic      *characteristicWrite;
@property (strong, nonatomic) NSData *dataReadySend;

@end



@implementation BTLECentralViewController

@synthesize UIInputTextView = _UIInputTextView;
@synthesize UIOutputTextView = _UIOutputTextView;
@synthesize uiSendButton = _uiSendButton;



#pragma mark - View Lifecycle

typedef  unsigned int DWORD;


char g_receiveData[2048] = {0};


DWORD AscToHex(char *Dest,char *Src,DWORD SrcLen)
{
    DWORD i;
    for ( i = 0; i < SrcLen; i ++ )
    {
        sprintf(Dest + i * 2,"%02X",(unsigned char)Src[i]);
    }
    Dest[i * 2] = 0;
    return 2*SrcLen;
}

DWORD HexToAsc(char *pDst, char *pSrc, DWORD nSrcLen)
{
    for(DWORD i=0; i<nSrcLen; i+=2)
    {
        //输出高4位
        if(*pSrc>='0' && *pSrc<='9')
        {
            *pDst = (*pSrc - '0') << 4;
        }
        else if(*pSrc>='A' && *pSrc<='F')
        {
            *pDst = (*pSrc - 'A' + 10) << 4;
        }
        else
        {
            *pDst = (*pSrc - 'a' + 10) << 4;
        }
        
        pSrc++;
        
        // 输出低4位
        if(*pSrc>='0' && *pSrc<='9')
        {
            *pDst |= *pSrc - '0';
        }
        else if(*pSrc>='A' && *pSrc<='F')
        {
            *pDst |= *pSrc - 'A' + 10;
        }
        else
        {
            *pDst |= *pSrc - 'a' + 10;
        }
        
        pSrc++;
        pDst++;
    }
    //返回目标数据长度
    return nSrcLen / 2;
}



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Start up the CBCentralManager
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    // And somewhere to store the incoming data
    _data = [[NSMutableData alloc] init];
    
    
    _dataReadySend = nil;
    
    self.isCanSendData = YES;
    
    
//    UIButton * signButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
//    [signButton setFrame:CGRectMake(80, 80, 120, 32)];
//    [signButton setTitle:@"发送数据" forState:UIControlStateNormal];
//    [signButton addTarget:self action:@selector(buttonOperation:) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:signButton];
    
    _UIInputTextView.delegate = self;
    //_UIInputTextView.text = @"5948a70080f20001a03c3f786d6c2076657273696f6e3d22312e302220656e636f64696e673d227574662d38223f3e3c543e3c443e3c4d3e3c6b3ee694b6e6acbee4babae5908de7a7b03a3c2f6b3e3c763ee5bca0e4b8893c2f763e3c2f4d3e3c4d3e3c6b3ee694b6e6acbee4babae8b4a6e58fb73a3c2f6b3e3c763e313233343536373839303132333435363c2f763e3c2f4d3e3c4d3e3c6b3ee98791e9a29d3a3c2f6b3e3c763e85c0";
    
    
    
    _UIInputTextView.text = @"5948070080f200000006e4";
    
    _UIOutputTextView.delegate = self;
    _UIOutputTextView.text = @"59484d0080f20001463132332e32333c2f763e3c2f4d3e3c2f443e3c453e3c4d3e3c6b3ee6b581e6b0b4e58fb73a3c2f6b3e3c763e313233343536373839303c2f763e3c2f4d3e3c2f453e3c2f543ef27f";
    
    [self InitUI];
    
    //[self scan];

}

-(void) InitUI
{
    UIToolbar *topView = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
    [topView setBarStyle:UIBarStyleBlack];
    
    UIBarButtonItem *spaceBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
    
    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonSystemItemDone target:self action:@selector(ReturnDone)];
    
    NSArray *arrybtn = @[spaceBtn, doneBtn];
    
    [topView setItems:arrybtn];
    
    [_UIInputTextView setInputAccessoryView:topView];
    
    [_UIOutputTextView setInputAccessoryView:topView];
    
}

-(void)ReturnDone
{
    NSLog(@"ReturnDone  ");
    
    [_UIInputTextView resignFirstResponder];
    [_UIOutputTextView resignFirstResponder];
}


- (void)buttonOperation:(id) sender
{
//    NSLog(@"send data");
//    
//    char command[245] = {0};
//    
//    command[0] = 0x00;
//    command[1] = 0x24;
//    command[2] = 0x00;
//    command[3] = 0x82;
//    command[4] = 0x10;
//    
//    
//    NSData *commandData = [[NSData alloc] initWithBytes:command length:5];
//
//    NSLog(@"[MyPeripheral] data = %@", commandData);
//
//    [self.connectPeripheral writeValue:commandData forCharacteristic:self.character type:CBCharacteristicWriteWithResponse];
}



- (void)viewWillDisappear:(BOOL)animated
{
    // Don't keep it going while we're not showing.
    [self.centralManager stopScan];
    NSLog(@"Scanning stopped");
    
    [super viewWillDisappear:animated];
}



#pragma mark - Central Methods


- (IBAction)SendBlueData:(id)sender {
    
    NSLog(@"SendBlueData");
    
    _UIDataOutputTextView.text = @"";
    
    char szInputData[1024] = {0};
    
    NSString *strInput = _UIInputTextView.text;
    
    const char *szInputDataHex = [strInput UTF8String];
    
    int inputDataLen = HexToAsc(szInputData, szInputDataHex, strlen(szInputDataHex));
    
    NSData *dataInput = [NSData dataWithBytes:szInputData length:inputDataLen];
    
    
    [self sendData:dataInput];
    
    //_UIInputTextView.text = @"<#string#>"
    
    
}

/** centralManagerDidUpdateState is a required protocol method.
 *  Usually, you'd check for other states to make sure the current device supports LE, is powered on, etc.
 *  In this instance, we're just using it to wait for CBCentralManagerStatePoweredOn, which indicates
 *  the Central is ready to be used.
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state != CBCentralManagerStatePoweredOn)
    {
        // In a real app, you'd deal with all the states correctly
        return;
    }
    
    // The state must be CBCentralManagerStatePoweredOn...

    // ... so start scanning
    [self scan];
    
}


/** Scan for peripherals - specifically for our service's 128bit CBUUID
 */
- (void)scan
{
    [self.centralManager scanForPeripheralsWithServices:nil
                                                options:nil];
    
    NSLog(@"Scanning started");
}

-(void)stopscan
{
    [self.centralManager stopScan];
    
     NSLog(@"Scanning stoped");
}



- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if([text isEqualToString:@"\n"])
    {
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}


/** This callback comes whenever a peripheral that is advertising the TRANSFER_SERVICE_UUID is discovered.
 *  We check the RSSI, to make sure it's close enough that we're interested in it, and if it is, 
 *  we start the connection process
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
//    // Reject any where the value is above reasonable range
//    if (RSSI.integerValue > -15)
//    {
//        return;
//    }
//        
//    // Reject if the signal strength is too low to be close enough (Close is around -22dB)
//    if (RSSI.integerValue < -35)
//    {
//        return;
//    }
//    
    NSLog(@"Discovered %@ at %@", peripheral.name, RSSI);
    
    // Ok, it's in range - have we already seen it?
    if (self.discoveredPeripheral != peripheral)
    {
        
        // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
        self.discoveredPeripheral = peripheral;
        
        if( (peripheral.name != nil)&& [peripheral.name rangeOfString:@"JYH-SPP"].location != NSNotFound )
        {
            // And connect
            NSLog(@"Connecting to peripheral %@", peripheral);
            self.connectPeripheral = peripheral;
            [self.centralManager connectPeripheral:peripheral options:nil];
        }
        

    }
}


/** If the connection fails for whatever reason, we need to deal with it.
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Failed to connect to %@. (%@)", peripheral, [error localizedDescription]);
    [self cleanup];
}


/** We've connected to the peripheral, now we need to discover the services and characteristics to find the 'transfer' characteristic.
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Peripheral Connected");
    
    // Stop scanning
    [self.centralManager stopScan];
    NSLog(@"Scanning stopped");
    
    // Clear the data that we may already have
    [self.data setLength:0];

    // Make sure we get the discovery callbacks
    peripheral.delegate = self;
    
    // Search only for services that match our UUID
    [peripheral discoverServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]];
    
    [self stopscan];
}





/** The Transfer Service was discovered
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error)
    {
        NSLog(@"Error discovering services: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    
    // Discover the characteristic we want...
    
    // Loop through the newly filled peripheral.services array, just in case there's more than one.
    for (CBService *service in peripheral.services)
    {
        [peripheral discoverCharacteristics:nil forService:service];
    }
}


/** The Transfer characteristic was discovered.
 *  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    // Deal with errors (if any)
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    
    // Again, we loop through the array, just in case.
    for (CBCharacteristic *characteristic in service.characteristics)
    {
        
        // And check if it's the right one
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_ISSC_TRANS_TX]])
        {
     
            // If it is, subscribe to it
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
        else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_ISSC_TRANS_RX]])
        {
            self.characteristicWrite = characteristic;;
        }
    }
    
    // Once this is complete, we just need to wait for the data to come in.
}


/** This callback lets us know more data has arrived via notification on the characteristic
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        return;
    }
    
    //NSLog(@"didUpdateValueForCharacte ");
    
    NSLog(@"receive characteristic.value  = %@ len = %d", characteristic.value, [characteristic.value length]);

    NSData *dataRec = characteristic.value;
    
    
    //_UIDataOutputTextView.text = @"";
    
    char *outdata = [dataRec bytes];
    
    int len = [dataRec length];
    
    char szoutdata[1024] = {0};
    
    int outlen = 0;
    
    outlen = AscToHex(szoutdata, outdata, len);
    
    NSString *strout = [[NSString alloc] initWithBytes:szoutdata length:outlen encoding:NSASCIIStringEncoding];
    
    _UIDataOutputTextView.text = strout;
    
    
   //
}


/** The peripheral letting us know whether our subscribe/unsubscribe happened or not
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
    }
    
    
    NSLog(@"didUpdateNotificationStateForCharacteristic  ok");
    
    // Exit if it's not the transfer characteristic
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_ISSC_TRANS_TX]]) {
        return;
    }
    
    
    NSLog(@"didUpdateNotificationStateForCharacteristic ");
//    // Notification has started
//    if (characteristic.isNotifying)
//    {
//        NSLog(@"Notification began on %@", characteristic);
//    }
//    
//    // Notification has stopped
//    else {
//        // so disconnect from the peripheral
//        NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
//        [self.centralManager cancelPeripheralConnection:peripheral];
//    }
}


- (void)sendData:(NSData *)dataMsg
{
    //writeFileLog("sendData","begain");
    if (self.connectPeripheral == nil)
    {
        NSLog(@"没有找到匹配成功的外围设备");
    }
    else if(dataMsg.length == 0)
    {
        NSLog(@"请输入发送文本");
    }
    else if(self.isCanSendData)
    {
        NSData *dataSend = nil;
        self.isCanSendData = NO;
        
        if (dataMsg.length > PACKAGE_DATA_MAXLEN)
        {
            dataSend = [dataMsg subdataWithRange:NSMakeRange(0, PACKAGE_DATA_MAXLEN)];
            _dataReadySend = [dataMsg subdataWithRange:NSMakeRange(PACKAGE_DATA_MAXLEN, dataMsg.length - PACKAGE_DATA_MAXLEN)];
        }
        else
        {
            dataSend = [dataMsg subdataWithRange:NSMakeRange(0, dataMsg.length)];
            _dataReadySend = nil;
        }
        [self.connectPeripheral writeValue:dataSend forCharacteristic:self.characteristicWrite type:CBCharacteristicWriteWithResponse];
        NSLog(@"senddata = %@", dataSend);
        dataSend =nil;
    }
    //writeFileLog("sendData","end");
}

 - (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    NSLog(@"didWriteValueForCharacteristic error msg:%d, %@, %@", error.code ,[error localizedFailureReason], [error localizedDescription]);
    NSLog(@"characteristic data = %@ len = %d id = %@",characteristic.value,[characteristic.value length],characteristic.UUID);
    

    
    self.isCanSendData = YES;
    
    if (_dataReadySend) {
        [self sendData:_dataReadySend];
    }
    
}


/** Once the disconnection happens, we need to clean up our local copy of the peripheral
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Peripheral Disconnected");
    self.discoveredPeripheral = nil;
    
    // We're disconnected, so start scanning again
    [self scan];
}


/** Call this when things either go wrong, or you're done with the connection.
 *  This cancels any subscriptions if there are any, or straight disconnects if not.
 *  (didUpdateNotificationStateForCharacteristic will cancel the connection if a subscription is involved)
 */
- (void)cleanup
{
    // Don't do anything if we're not connected
//    if (!self.discoveredPeripheral.isConnected) {
//        return;
//    }
    
    // See if we are subscribed to a characteristic on the peripheral
    if (self.discoveredPeripheral.services != nil)
    {
        for (CBService *service in self.discoveredPeripheral.services)
        {
            if (service.characteristics != nil)
            {
                for (CBCharacteristic *characteristic in service.characteristics)
                {
                    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_ISSC_TRANS_TX]])
                    {
                        if (characteristic.isNotifying)
                        {
                            [self.discoveredPeripheral setNotifyValue:NO forCharacteristic:characteristic];
                            return;
                        }
                    }
                }
            }
        }
    }
    [self.centralManager cancelPeripheralConnection:self.discoveredPeripheral];
}


@end
