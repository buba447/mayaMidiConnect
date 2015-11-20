//
//  MCStreamClient.m
//  mConnect
//
//  Created by Brandon Withrow on 7/9/14.
//  Copyright (c) 2014 Brandon Withrow. All rights reserved.
//

#import "MCStreamClient.h"
#import "MCStreamRequest.h"
#import "GCDAsyncSocket.h"

static const int BUFFER_SIZE = 4096;

static MCStreamClient *sharedClient = nil;

@interface MCStreamClient () <GCDAsyncSocketDelegate>

@end

@implementation MCStreamClient {
  NSMutableArray *requests_;
  dispatch_queue_t streamQueue_;
  GCDAsyncSocket *socket_;
  NSString *_host;
  int _port;
  BOOL showingNetworkError;
}

- (void)startConnectionWithHost:(NSString *)host andPort:(int)port {
  if (socket_) {
    [self disconnectFromHost];
  }
  requests_ = [NSMutableArray array];
  if (!streamQueue_) {
    streamQueue_ = dispatch_queue_create("com.buba447.whatever", DISPATCH_QUEUE_SERIAL);
  }
  socket_ = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:streamQueue_];
  [socket_ connectToHost:host onPort:port error:NULL];
  _host = host;
  _port = port;
  [[MCStreamClient sharedClient] sendPyCommand:@"exec('import bw') in globals()" withCompletion:NULL withFailure:NULL];
  [[MCStreamClient sharedClient] sendPyCommand:@"exec('import midiConnect') in globals()" withCompletion:NULL withFailure:NULL];
  [[MCStreamClient sharedClient] sendPyCommand:@"bw.helloWorld()" withCompletion:NULL withFailure:NULL];
//  __weak typeof(self) weakSelf = self;
//  [[MCStreamClient sharedClient] sendPyCommand:@"bw.startSelectionPolling()" withCompletion:^(NSString *response) {
//    __strong typeof(self) strongSelf = weakSelf;
//    [strongSelf _startSelectionPolling];
//  } withFailure:NULL];
}

- (void)disconnectFromHost {
  [socket_ disconnect];
  for (MCStreamRequest *request in requests_) {
    request.failBlock(request);
  }
  [requests_ removeAllObjects];
  socket_ = nil;
  requests_ = nil;
}

#pragma mark - Shared Client

+ (MCStreamClient *)sharedClient {
  if (!sharedClient) {
    sharedClient = [[MCStreamClient alloc] init];
  }
  return sharedClient;
}

- (id)copyWithZone:(NSZone *)zone {
  return self;
}

#pragma mark - Property Overrides

- (BOOL)isConnected {
  return socket_.isConnected;
}

#pragma mark - Selection Polling


- (void)_startSelectionPolling {
  if (socket_.isConnected) {
    __weak typeof(self) weakSelf = self;
    [[MCStreamClient sharedClient] getJSONFromPyCommand:@"bw.slPoll()"
                                         withCompletion:^(id JSONObject) {
                                           __strong typeof(self) strongSelf = weakSelf;
                                           [strongSelf _handleSelectionPolling:JSONObject];
                                         } withFailure:NULL];
  }
}

- (void)_handleSelectionPolling:(id)response {
  if (response) {
    NSDictionary *userInfo = @{@"data" : response};
    [[NSNotificationCenter defaultCenter] postNotificationName:kMayaSelectionChangedNotification object:self userInfo:userInfo];
  }
  [self performSelector:@selector(_startSelectionPolling) withObject:NULL afterDelay:0.5];
}

#pragma mark - Helper Requests

- (MCStreamRequest *)sendPyCommand:(NSString *)command
       withCompletion:(void (^)(NSString *))completion
          withFailure:(void (^)(void))failure {
  MCStreamRequest *newRequest = [[MCStreamRequest alloc] initWithMessage:command];
  if (completion) {
    newRequest.completionBlock = ^(MCStreamRequest *response) {
      NSString *string = [NSString stringWithUTF8String:[response.responseData bytes]];
      completion(string);
    };
  }
  if (failure) {
    newRequest.failBlock = ^(MCStreamRequest *response) {
      failure();
    };
  }
  [self addRequestToQueue:newRequest];
  return newRequest;
}

- (void)selectObject:(NSString *)object {
  [self sendPyCommand:[NSString stringWithFormat:@"cmds.select('%@')", object] withCompletion:NULL withFailure:NULL];
}

- (MCStreamRequest *)getJSONFromPyCommand:(NSString *)command
              withCompletion:(void (^)(id JSONObject))completion
                 withFailure:(void (^)(void))failure {
  MCStreamRequest *newRequest = [[MCStreamRequest alloc] initWithMessage:command];
  if (completion) {
    newRequest.completionBlock = ^(MCStreamRequest *response) {
      NSError *error;
      id responseObject = nil;
      NSString *string = [NSString stringWithUTF8String:[response.responseData bytes]];
      if (string) {
        NSData *metOfficeData = [string dataUsingEncoding:NSUTF8StringEncoding];
        id jsonObject = [NSJSONSerialization JSONObjectWithData:metOfficeData options:kNilOptions error:&error];
        if (!error) {
          responseObject = jsonObject;
        }
      }
      completion(responseObject);
    };
  }
  if (failure) {
    newRequest.failBlock = ^(MCStreamRequest *response) {
      failure();
    };
  }
  [self addRequestToQueue:newRequest];
  return newRequest;
}

- (MCStreamRequest *)getNewAttributesFromSelectionWithCompletion:(void (^)(NSDictionary *))completion withFailure:(void (^)(void))failure {
  MCStreamRequest *newRequest = [[MCStreamRequest alloc] initWithMessage:@"bw.lsSelectedAndAttributes()"];
  if (completion) {
    newRequest.completionBlock =  ^(MCStreamRequest *response) {
      NSError *error;
      NSDictionary *responseObject = nil;
      NSString *string = [NSString stringWithUTF8String:[response.responseData bytes]];
      if (string) {
        NSData *metOfficeData = [string dataUsingEncoding:NSUTF8StringEncoding];
        responseObject = [NSJSONSerialization JSONObjectWithData:metOfficeData options:kNilOptions error:&error];
      }
      if (responseObject) {
        completion(responseObject);
      }
    };
  }
  if (failure) {
    newRequest.failBlock = ^(MCStreamRequest *response) {
      failure();
    };
  }
  [self addRequestToQueue:newRequest];
  return newRequest;
}

#pragma mark - Private Methods

- (void)notifyNetworkError {
// TODO Work out reconnect/network error problems
//  if (showingNetworkError) {
//    return;
//  }
//  showingNetworkError = YES;
//  
//  NSAlert *alert = [[NSAlert alloc] init];
//  [alert addButtonWithTitle:@"Retry"];
//  [alert addButtonWithTitle:@"Cancel"];
//  [alert setMessageText:@"Unable to connect with Maya."];
//  [alert setInformativeText:@"Check that you've installed the BW scripts and that Maya is running."];
//  [alert setAlertStyle:NSWarningAlertStyle];
//  
//  [alert beginSheetModalForWindow:[[NSApplication sharedApplication] mainWindow] completionHandler:^(NSModalResponse returnCode) {
//    showingNetworkError = NO;
//  }];
}

- (void)startQueueIfNecessary {
  if (requests_.count && socket_.isConnected) {
    MCStreamRequest *nextRequest = requests_.firstObject;
    if (nextRequest.status == MCStreamStatusWaiting) {
      nextRequest.status = MCStreamStatusActive;
      NSData *data = [nextRequest.pyCommand dataUsingEncoding:NSUTF8StringEncoding];
      [socket_ writeData:data withTimeout:5 tag:47];
    }
  }
  
  if (socket_.isDisconnected) {
    [self notifyNetworkError];
  }
}

- (void)addRequestToQueue:(MCStreamRequest *)request {
  [requests_ addObject:request];
  request.status = MCStreamStatusWaiting;
  [self startQueueIfNecessary];
}

- (void)clearQueue {
  
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
  [[NSNotificationCenter defaultCenter] postNotificationName:kMayaConnectionStatusChanged object:self userInfo:NULL];
  for (MCStreamRequest *request in requests_) {
    request.status = MCStreamStatusFailed;
    if (request.failBlock) {
      dispatch_async(dispatch_get_main_queue(), ^{
        request.failBlock(request);
      });
    }
  }
  [requests_ removeAllObjects];
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [self notifyNetworkError];
  });
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
  [[NSNotificationCenter defaultCenter] postNotificationName:kMayaConnectionStatusChanged object:self userInfo:NULL];
  dispatch_async(dispatch_get_main_queue(), ^{
    [self startQueueIfNecessary];
  });
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
  [socket_ readDataWithTimeout:5 tag:tag];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
  MCStreamRequest *currentRequest = requests_.firstObject;
  [currentRequest.responseData appendData:data];
  currentRequest.status = MCStreamStatusFinished;
  [requests_ removeObject:currentRequest];
  if (currentRequest.completionBlock) {
    dispatch_async(dispatch_get_main_queue(), ^{
      currentRequest.completionBlock(currentRequest);
    });
  }
  dispatch_async(dispatch_get_main_queue(), ^{
    [self startQueueIfNecessary];
  });
}

@end
