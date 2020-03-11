
#import "RNPrinter.h"
#import "ConnecterManager.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "TscCommand.h"

static RCTPromiseResolveBlock _resolve;
static RCTPromiseRejectBlock _reject;

@interface RNPrinter ()<CBCentralManagerDelegate, CBPeripheralDelegate>
@property (nonatomic, strong) NSString *picUrl;
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *peripheral;
@end



@implementation RNPrinter


- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(print:(NSString *)msg  resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject ) {
  self.picUrl = msg;
    _resolve = resolve;
    _reject = reject;
   if (Manager.bleConnecter == nil) {
          [Manager didUpdateState:^(NSInteger state) {
              switch (state) {
                  case CBCentralManagerStateUnsupported:
                      NSLog(@"The platform/hardware doesn't support Bluetooth Low Energy.");
                      break;
                  case CBCentralManagerStateUnauthorized:
                      NSLog(@"The app is not authorized to use Bluetooth Low Energy.");
                      break;
                  case CBCentralManagerStatePoweredOff:
                      NSLog(@"Bluetooth is currently powered off.");
                      [self stopscan];
                      break;
                  case CBCentralManagerStatePoweredOn:
                      [self startScan];
                      NSLog(@"Bluetooth power on");
                      break;
                  case CBCentralManagerStateUnknown:
                  default:
                      break;
              }
          }];
      } else {
          [Manager write:[self tscCommand]];
          _resolve(@[[NSNumber numberWithInt:200]]);
      }

}

-(void)stopscan {
    self.isPrinting = NO;
    [Manager stopScan];

}

- (void)RetryConnectSaveDevice
{
   NSString *uuidStr = [[NSUserDefaults standardUserDefaults] stringForKey:@"DidConnectDeviceUUID"];

   NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidStr];
   if (uuidStr != nil) {

      NSArray *arr = [self.centralManager retrievePeripheralsWithIdentifiers:@[uuid]];
      for (CBPeripheral *aperipheral in arr) {
//            NSLog(@"connectPeripheral =======  %@",[aperipheral debugDescription]);
            [self.centralManager connectPeripheral:aperipheral options:nil];
      }

   }
}


-(void)startScan {
    NSString *uuidStr = [[NSUserDefaults standardUserDefaults] stringForKey:@"DidConnectDeviceUUID"];

    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidStr];
    if (uuid != nil) {
        NSArray *connectedDevices = [self.centralManager retrieveConnectedPeripheralsWithServices:@[uuid]];
        NSArray *connectedDevices2 = [self.centralManager retrievePeripheralsWithIdentifiers:@[uuid]];
//        NSLog(@"=============device:%@ ---device2:%@", connectedDevices, connectedDevices2);
        if (connectedDevices.count > 0) {
            for (CBPeripheral *peripheral in connectedDevices) {
                if (peripheral != nil && [peripheral.name containsString:@"1324D-WX-40DCB3"]) {
                    peripheral.delegate = self;
                    self.peripheral = peripheral;
                    [self.centralManager connectPeripheral:self.peripheral options:nil];
                }
            }
        } else {
            [Manager scanForPeripheralsWithServices:nil options:nil discover:^(CBPeripheral * _Nullable peripheral, NSDictionary<NSString *,id> * _Nullable advertisementData, NSNumber * _Nullable RSSI) {
//                NSLog(@"%@--%@--%@", peripheral, advertisementData, RSSI);
                if (peripheral.name != nil && [peripheral.name containsString:@"1324D-WX-40DCB3"]) {
//                    NSLog(@"name -> %@",peripheral.name);
                    [self stopscan];
                    [Manager connectPeripheral:peripheral options:nil timeout:2 connectBlack:^(ConnectState state) {
                        if (state == CONNECT_STATE_CONNECTED && !self.isPrinting) {
                            self.isPrinting = YES;
                            [[NSUserDefaults standardUserDefaults] setObject:peripheral.identifier.UUIDString forKey:@"DidConnectDeviceUUID"];
                            [Manager write:[self tscCommand]];
                            _resolve(@[[NSNumber numberWithInt:200]]);
                        }
                    }];
                }
            }];
        }
        
    } else {
        [Manager scanForPeripheralsWithServices:nil options:nil discover:^(CBPeripheral * _Nullable peripheral, NSDictionary<NSString *,id> * _Nullable advertisementData, NSNumber * _Nullable RSSI) {
                       NSLog(@"%@--%@--%@", peripheral, advertisementData, RSSI);
                       if (peripheral.name != nil && [peripheral.name containsString:@"1324D-WX-40DCB3"]) {
                           NSLog(@"name -> %@",peripheral.name);
                           [self stopscan];
                           [Manager connectPeripheral:peripheral options:nil timeout:2 connectBlack:^(ConnectState state) {
                               if (state == CONNECT_STATE_CONNECTED && !self.isPrinting) {
                                   self.isPrinting = YES;
                                   [[NSUserDefaults standardUserDefaults] setObject:peripheral.identifier.UUIDString forKey:@"DidConnectDeviceUUID"];
                                   [Manager write:[self tscCommand]];
                                   _resolve(@[[NSNumber numberWithInt:200]]);
                               }
                           }];
                       }
                   }];
    }
}

-(void)scanFroPeripherals{
    
}

RCT_EXPORT_METHOD(stopConnect) {
    [Manager stopScan];
}
RCT_EXPORT_METHOD(closeConnect) {
    [Manager close];
}

-(NSData *)tscCommand{
    TscCommand *command = [[TscCommand alloc]init];
    [command addSize:80 :60];
    [command addGapWithM:20 withN:0];
    [command addReference:14 :0];
    [command addTear:@"ON"];
    [command addQueryPrinterStatus:ON];
    [command addCls];
   UIImage *image = [UIImage imageWithContentsOfFile:self.picUrl];
    [command addBitmapwithX:20 withY:50 withMode:0 withWidth:640 withImage:image];
    [command addPrint:1 :1];
    return [command getCommand];
}

-(void)centralManagerDidUpdateState:(CBCentralManager *)central{
    
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
//    [Manager write:[self tscCommand]];
    _resolve(@[[NSNumber numberWithInt:200]]);
}

-(CBCentralManager *)centralManager{
    if (_centralManager == nil) {
        _centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:nil options:nil];
    }
    return _centralManager;
}



@end
  
