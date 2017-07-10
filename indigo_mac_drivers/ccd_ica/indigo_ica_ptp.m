// Copyright (c) 2017 CloudMakers, s. r. o.
// All rights reserved.
//
// You can use this software under the terms of 'INDIGO Astronomy
// open-source license' (see LICENSE.md).
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHORS 'AS IS' AND ANY EXPRESS
// OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
// NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// version history
// 2.0 by Peter Polakovic <peter.polakovic@cloudmakers.eu>

/** INDIGO ICA PTP wrapper
 \file indigo_ica_ptp.m
 */


// Code is based on PTPPassThrough example provided by Apple Inc.
// https://developer.apple.com/legacy/library/samplecode/PTPPassThrough
//
// This Apple software is supplied to you by Apple Inc. ("Apple")
// in consideration of your agreement to the following terms, and your use,
// installation, modification or redistribution of this Apple software
// constitutes acceptance of these terms. If you do not agree with these
// terms, please do not use, install, modify or redistribute this Apple
// software.
//
// In consideration of your agreement to abide by the following terms, and
// subject to these terms, Apple grants you a personal, non - exclusive
// license, under Apple's copyrights in this original Apple software (the
// "Apple Software"), to use, reproduce, modify and redistribute the Apple
// Software, with or without modifications, in source and / or binary forms;
// provided that if you redistribute the Apple Software in its entirety and
// without modifications, you must retain this notice and the following text
// and disclaimers in all such redistributions of the Apple Software. Neither
// the name, trademarks, service marks or logos of Apple Inc. may be used to
// endorse or promote products derived from the Apple Software without specific
// prior written permission from Apple. Except as expressly stated in this
// notice, no other rights or licenses, express or implied, are granted by
// Apple herein, including but not limited to any patent rights that may be
// infringed by your derivative works or by other works in which the Apple
// Software may be incorporated.
//
// The Apple Software is provided by Apple on an "AS IS" basis. APPLE MAKES NO
// WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
// WARRANTIES OF NON - INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
// PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION
// ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//
// IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION
// AND / OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER
// UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR
// OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Copyright (C) 2009 Apple Inc. All Rights Reserved.
//
//------------------------------------------------------------------------------------------------------------------------------

#include "indigo_bus.h"

#import "indigo_ica_ptp.h"


static char ptpReadChar(unsigned char** buf) {
  char value = *(SInt8*)(*buf);
  (*buf) += 1;
  return value;
}

static void ptpWriteChar(unsigned char** buf, char value) {
  *(SInt8*)(*buf) = value;
  (*buf) += 1;
}

static unsigned char ptpReadUnsignedChar(unsigned char** buf) {
  char value = *(UInt8*)(*buf);
  (*buf) += 1;
  return value;
}

static void ptpWriteUnsignedChar(unsigned char** buf, unsigned char value) {
  *(UInt8*)(*buf) = value;
  (*buf) += 1;
}

static short ptpReadShort(unsigned char** buf) {
  SInt16 value = (SInt16)CFSwapInt16LittleToHost(*(UInt16*)(*buf));
  (*buf) += 2;
  return value;
}

static void ptpWriteShort(unsigned char** buf, short value) {
  *(SInt16*)(*buf) = (SInt16)CFSwapInt16HostToLittle(value);
  (*buf) += 2;
}

static unsigned short ptpReadUnsignedShort(unsigned char** buf) {
  unsigned short value = CFSwapInt16LittleToHost(*(unsigned short*)(*buf));
  (*buf) += 2;
  return value;
}

static void ptpWriteUnsignedShort(unsigned char** buf, unsigned short value) {
  *(unsigned short*)(*buf) = CFSwapInt16HostToLittle(value);
  (*buf) += 2;
}

static int ptpReadInt(unsigned char** buf) {
  int value = CFSwapInt32LittleToHost(*(int*)(*buf));
  (*buf) += 4;
  return value;
}

static void ptpWriteInt(unsigned char** buf, int value) {
  *(int*)(*buf) = (int)CFSwapInt32HostToLittle(value);
  (*buf) += 4;
}

static unsigned int ptpReadUnsignedInt(unsigned char** buf) {
  int value = CFSwapInt32LittleToHost(*(int*)(*buf));
  (*buf) += 4;
  return value;
}

static void ptpWriteUnsignedInt(unsigned char** buf, unsigned int value) {
  *(unsigned int*)(*buf) = CFSwapInt32HostToLittle(value);
  (*buf) += 4;
}

static long ptpReadLong(unsigned char** buf) {
  long value = (long)CFSwapInt64LittleToHost(*(long*)(*buf));
  (*buf) += 8;
  return value;
}

static void ptpWriteLong(unsigned char** buf, long value) {
  *(long*)(*buf) = (long)CFSwapInt64HostToLittle(value);
  (*buf) += 8;
}

static unsigned long ptpReadUnsignedLong(unsigned char** buf) {
  unsigned long value = CFSwapInt64LittleToHost(*(unsigned long*)(*buf));
  (*buf) += 8;
  return value;
}

static void ptpWriteUnsignedLong(unsigned char** buf, unsigned long value) {
  *(unsigned long*)(*buf) = CFSwapInt64HostToLittle(value);
  (*buf) += 8;
}

static NSString *ptpRead128(unsigned char** buf) {
	NSString *value = [NSString stringWithFormat:@"%02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x", (*buf)[0], (*buf)[1], (*buf)[2], (*buf)[3], (*buf)[4], (*buf)[5], (*buf)[6], (*buf)[7], (*buf)[8], (*buf)[9], (*buf)[10], (*buf)[11], (*buf)[12], (*buf)[13], (*buf)[14], (*buf)[15]];
	(*buf) += 16;
	return value;
}

static NSArray<NSNumber *> *ptpReadCharArray(unsigned char** buf) {
  int length = ptpReadUnsignedInt(buf);
  if (length) {
    NSMutableArray<NSNumber *> *result = [NSMutableArray array];
    for (int i = 0; i < length; i++)
      [result addObject:[NSNumber numberWithChar:ptpReadChar(buf)]];
    return result;
  }
  return nil;
}

static NSArray<NSNumber *> *ptpReadUnsignedCharArray(unsigned char** buf) {
  int length = ptpReadUnsignedInt(buf);
  if (length) {
    NSMutableArray<NSNumber *> *result = [NSMutableArray array];
    for (int i = 0; i < length; i++)
      [result addObject:[NSNumber numberWithUnsignedChar:ptpReadUnsignedChar(buf)]];
    return result;
  }
  return nil;
}

static NSArray<NSNumber *> *ptpReadShortArray(unsigned char** buf) {
  int length = ptpReadUnsignedInt(buf);
  if (length) {
    NSMutableArray<NSNumber *> *result = [NSMutableArray array];
    for (int i = 0; i < length; i++)
      [result addObject:[NSNumber numberWithShort:ptpReadShort(buf)]];
    return result;
  }
  return nil;
}

static NSArray<NSNumber *> *ptpReadUnsignedShortArray(unsigned char** buf) {
  int length = ptpReadUnsignedInt(buf);
  if (length) {
    NSMutableArray<NSNumber *> *result = [NSMutableArray array];
    for (int i = 0; i < length; i++)
      [result addObject:[NSNumber numberWithUnsignedShort:ptpReadUnsignedShort(buf)]];
    return result;
  }
  return nil;
}

static NSArray<NSNumber *> *ptpReadIntArray(unsigned char** buf) {
  int length = ptpReadUnsignedInt(buf);
  if (length) {
    NSMutableArray<NSNumber *> *result = [NSMutableArray array];
    for (int i = 0; i < length; i++)
      [result addObject:[NSNumber numberWithInt:ptpReadInt(buf)]];
    return result;
  }
  return nil;
}

static NSArray<NSNumber *> *ptpReadUnsignedIntArray(unsigned char** buf) {
  int length = ptpReadUnsignedInt(buf);
  if (length) {
    NSMutableArray<NSNumber *> *result = [NSMutableArray array];
    for (int i = 0; i < length; i++)
      [result addObject:[NSNumber numberWithUnsignedInt:ptpReadUnsignedInt(buf)]];
    return result;
  }
  return nil;
}

static NSArray<NSNumber *> *ptpReadLongArray(unsigned char** buf) {
  int length = ptpReadUnsignedInt(buf);
  if (length) {
    NSMutableArray<NSNumber *> *result = [NSMutableArray array];
    for (int i = 0; i < length; i++)
      [result addObject:[NSNumber numberWithLong:ptpReadLong(buf)]];
    return result;
  }
  return nil;
}

static NSArray<NSNumber *> *ptpReadUnsignedLongArray(unsigned char** buf) {
  int length = ptpReadUnsignedInt(buf);
  if (length) {
    NSMutableArray<NSNumber *> *result = [NSMutableArray array];
    for (int i = 0; i < length; i++)
      [result addObject:[NSNumber numberWithUnsignedLong:ptpReadUnsignedLong(buf)]];
    return result;
  }
  return nil;
}

static NSString *ptpReadString(unsigned char** buf) {
  int length = **buf;
  if (length) {
    int fixed;
    const unichar *pnt = (const unichar *)(*buf + 1);
    for (fixed = 0; fixed < length; fixed++) {
      if (*pnt++ == 0) {
        break;
      }
    }
    NSString *result = [NSString stringWithString:[NSString stringWithCharacters: (const unichar *)(*buf + 1) length:fixed]];
    *buf = (*buf) + length * 2 + 1;
    return result;
  }
  *buf = (*buf) + 1;
  return nil;
}

static unsigned char ptpWriteString(unsigned char **buf, NSString *value) {
  const char *cstr = [value cStringUsingEncoding:NSUnicodeStringEncoding];
  unsigned int length = (unsigned int)value.length + 1;
  if (length < 256) {
    **buf = length;
    memcpy(*buf + 1, cstr, 2 * length);
		*buf = (*buf) + 2 * length + 1;
    return 2 * length + 1;
  }
  return -1;
}

static NSObject *ptpReadValue(PTPDataTypeCode type, unsigned char **buf) {
  switch (type) {
    case PTPDataTypeCodeSInt8:
      return [NSNumber numberWithChar:ptpReadChar(buf)];
    case PTPDataTypeCodeUInt8:
      return [NSNumber numberWithUnsignedChar:ptpReadUnsignedChar(buf)];
    case PTPDataTypeCodeSInt16:
      return [NSNumber numberWithShort:ptpReadShort(buf)];
    case PTPDataTypeCodeUInt16:
      return [NSNumber numberWithUnsignedShort:ptpReadUnsignedShort(buf)];
    case PTPDataTypeCodeSInt32:
      return [NSNumber numberWithInt:ptpReadInt(buf)];
    case PTPDataTypeCodeUInt32:
      return [NSNumber numberWithUnsignedInt:ptpReadUnsignedInt(buf)];
    case PTPDataTypeCodeSInt64:
      return [NSNumber numberWithLong:ptpReadLong(buf)];
    case PTPDataTypeCodeUInt64:
      return [NSNumber numberWithUnsignedLong:ptpReadUnsignedLong(buf)];
		case PTPDataTypeCodeSInt128:
		case PTPDataTypeCodeUInt128:
			return ptpRead128(buf);
    case PTPDataTypeCodeArrayOfSInt8:
      return ptpReadCharArray(buf);
    case PTPDataTypeCodeArrayOfUInt8:
      return ptpReadUnsignedCharArray(buf);
    case PTPDataTypeCodeArrayOfSInt16:
      return ptpReadShortArray(buf);
    case PTPDataTypeCodeArrayOfUInt16:
      return ptpReadUnsignedShortArray(buf);
    case PTPDataTypeCodeArrayOfSInt32:
      return ptpReadIntArray(buf);
    case PTPDataTypeCodeArrayOfUInt32:
      return ptpReadUnsignedIntArray(buf);
    case PTPDataTypeCodeArrayOfSInt64:
      return ptpReadLongArray(buf);
    case PTPDataTypeCodeArrayOfUInt64:
      return ptpReadUnsignedLongArray(buf);
    case PTPDataTypeCodeUnicodeString:
      return ptpReadString(buf);
  }
  
  return nil;
}

//---------------------------------------------------------------------------------------------------------- PTPVendor

@implementation PTPVendor

+ (NSString *)vendorExtensionName:(PTPVendorExtension)vendorExtension {
  switch (vendorExtension) {
    case PTPVendorExtensionEastmanKodak: return @"PTPVendorExtensionEastmanKodak";
    case PTPVendorExtensionMicrosoft: return @"PTPVendorExtensionMicrosoft";
    case PTPVendorExtensionNikon: return @"PTPVendorExtensionNikon";
    case PTPVendorExtensionCanon: return @"PTPVendorExtensionCanon";
    case PTPVendorExtensionPentax: return @"PTPVendorExtensionPentax";
    case PTPVendorExtensionFuji: return @"PTPVendorExtensionFuji";
    case PTPVendorExtensionSony: return @"PTPVendorExtensionSony";
    case PTPVendorExtensionSamsung: return @"PTPVendorExtensionSamsung";
  }
  return [NSString stringWithFormat:@"PTPVendorExtension0x%04x", vendorExtension];
}

- (id)initWithVendorExtension:(PTPVendorExtension)vendorExtension {
	self = [super init];
	if (self) {
		_vendorExtension = vendorExtension;
	}
	return self;
}

- (NSString *)vendorExtensionName {
  return [PTPVendor vendorExtensionName:_vendorExtension];
}

@end
//---------------------------------------------------------------------------------------------------------- PTPOperationRequest

@implementation PTPOperationRequest

+ (NSString *)operationCodeName:(PTPOperationCode)operationCode vendorExtension:(PTPVendorExtension)vendorExtension {
  switch (operationCode) {
    case PTPOperationCodeUndefined: return @"PTPOperationCodeUndefined";
    case PTPOperationCodeGetDeviceInfo: return @"PTPOperationCodeGetDeviceInfo";
    case PTPOperationCodeOpenSession: return @"PTPOperationCodeOpenSession";
    case PTPOperationCodeCloseSession: return @"PTPOperationCodeCloseSession";
    case PTPOperationCodeGetStorageIDs: return @"PTPOperationCodeGetStorageIDs";
    case PTPOperationCodeGetStorageInfo: return @"PTPOperationCodeGetStorageInfo";
    case PTPOperationCodeGetNumObjects: return @"PTPOperationCodeGetNumObjects";
    case PTPOperationCodeGetObjectHandles: return @"PTPOperationCodeGetObjectHandles";
    case PTPOperationCodeGetObjectInfo: return @"PTPOperationCodeGetObjectInfo";
    case PTPOperationCodeGetObject: return @"PTPOperationCodeGetObject";
    case PTPOperationCodeGetThumb: return @"PTPOperationCodeGetThumb";
    case PTPOperationCodeDeleteObject: return @"PTPOperationCodeDeleteObject";
    case PTPOperationCodeSendObjectInfo: return @"PTPOperationCodeSendObjectInfo";
    case PTPOperationCodeSendObject: return @"PTPOperationCodeSendObject";
    case PTPOperationCodeInitiateCapture: return @"PTPOperationCodeInitiateCapture";
    case PTPOperationCodeFormatStore: return @"PTPOperationCodeFormatStore";
    case PTPOperationCodeResetDevice: return @"PTPOperationCodeResetDevice";
    case PTPOperationCodeSelfTest: return @"PTPOperationCodeSelfTest";
    case PTPOperationCodeSetObjectProtection: return @"PTPOperationCodeSetObjectProtection";
    case PTPOperationCodePowerDown: return @"PTPOperationCodePowerDown";
    case PTPOperationCodeGetDevicePropDesc: return @"PTPOperationCodeGetDevicePropDesc";
    case PTPOperationCodeGetDevicePropValue: return @"PTPOperationCodeGetDevicePropValue";
    case PTPOperationCodeSetDevicePropValue: return @"PTPOperationCodeSetDevicePropValue";
    case PTPOperationCodeResetDevicePropValue: return @"PTPOperationCodeResetDevicePropValue";
    case PTPOperationCodeTerminateOpenCapture: return @"PTPOperationCodeTerminateOpenCapture";
    case PTPOperationCodeMoveObject: return @"PTPOperationCodeMoveObject";
    case PTPOperationCodeCopyObject: return @"PTPOperationCodeCopyObject";
    case PTPOperationCodeGetPartialObject: return @"PTPOperationCodeGetPartialObject";
    case PTPOperationCodeInitiateOpenCapture: return @"PTPOperationCodeInitiateOpenCapture";
    case PTPOperationCodeGetNumDownloadableObjects: return @"PTPOperationCodeGetNumDownloadableObjects";
    case PTPOperationCodeGetAllObjectInfo: return @"PTPOperationCodeGetAllObjectInfo";
    case PTPOperationCodeGetUserAssignedDeviceName: return @"PTPOperationCodeGetUserAssignedDeviceName";
    case PTPOperationCodeMTPGetObjectPropsSupported: return @"PTPOperationCodeMTPGetObjectPropsSupported";
    case PTPOperationCodeMTPGetObjectPropDesc: return @"PTPOperationCodeMTPGetObjectPropDesc";
    case PTPOperationCodeMTPGetObjectPropValue: return @"PTPOperationCodeMTPGetObjectPropValue";
    case PTPOperationCodeMTPSetObjectPropValue: return @"PTPOperationCodeMTPSetObjectPropValue";
    case PTPOperationCodeMTPGetObjPropList: return @"PTPOperationCodeMTPGetObjPropList";
    case PTPOperationCodeMTPSetObjPropList: return @"PTPOperationCodeMTPSetObjPropList";
    case PTPOperationCodeMTPGetInterdependendPropdesc: return @"PTPOperationCodeMTPGetInterdependendPropdesc";
    case PTPOperationCodeMTPSendObjectPropList: return @"PTPOperationCodeMTPSendObjectPropList";
    case PTPOperationCodeMTPGetObjectReferences: return @"PTPOperationCodeMTPGetObjectReferences";
    case PTPOperationCodeMTPSetObjectReferences: return @"PTPOperationCodeMTPSetObjectReferences";
    case PTPOperationCodeMTPUpdateDeviceFirmware: return @"PTPOperationCodeMTPUpdateDeviceFirmware";
    case PTPOperationCodeMTPSkip: return @"PTPOperationCodeMTPSkip";
  }
  if (vendorExtension == PTPVendorExtensionNikon) {
    switch (operationCode) {
      case PTPOperationCodeNikonGetProfileAllData: return @"PTPOperationCodeNikonGetProfileAllData";
      case PTPOperationCodeNikonSendProfileData: return @"PTPOperationCodeNikonSendProfileData";
      case PTPOperationCodeNikonDeleteProfile: return @"PTPOperationCodeNikonDeleteProfile";
      case PTPOperationCodeNikonSetProfileData: return @"PTPOperationCodeNikonSetProfileData";
      case PTPOperationCodeNikonAdvancedTransfer: return @"PTPOperationCodeNikonAdvancedTransfer";
      case PTPOperationCodeNikonGetFileInfoInBlock: return @"PTPOperationCodeNikonGetFileInfoInBlock";
      case PTPOperationCodeNikonCapture: return @"PTPOperationCodeNikonCapture";
      case PTPOperationCodeNikonAfDrive: return @"PTPOperationCodeNikonAfDrive";
      case PTPOperationCodeNikonSetControlMode: return @"PTPOperationCodeNikonSetControlMode";
      case PTPOperationCodeNikonDelImageSDRAM: return @"PTPOperationCodeNikonDelImageSDRAM";
      case PTPOperationCodeNikonGetLargeThumb: return @"PTPOperationCodeNikonGetLargeThumb";
      case PTPOperationCodeNikonCurveDownload: return @"PTPOperationCodeNikonCurveDownload";
      case PTPOperationCodeNikonCurveUpload: return @"PTPOperationCodeNikonCurveUpload";
      case PTPOperationCodeNikonCheckEvent: return @"PTPOperationCodeNikonCheckEvent";
      case PTPOperationCodeNikonDeviceReady: return @"PTPOperationCodeNikonDeviceReady";
      case PTPOperationCodeNikonSetPreWBData: return @"PTPOperationCodeNikonSetPreWBData";
      case PTPOperationCodeNikonGetVendorPropCodes: return @"PTPOperationCodeNikonGetVendorPropCodes";
      case PTPOperationCodeNikonAfCaptureSDRAM: return @"PTPOperationCodeNikonAfCaptureSDRAM";
      case PTPOperationCodeNikonGetPictCtrlData: return @"PTPOperationCodeNikonGetPictCtrlData";
      case PTPOperationCodeNikonSetPictCtrlData: return @"PTPOperationCodeNikonSetPictCtrlData";
      case PTPOperationCodeNikonDelCstPicCtrl: return @"PTPOperationCodeNikonDelCstPicCtrl";
      case PTPOperationCodeNikonGetPicCtrlCapability: return @"PTPOperationCodeNikonGetPicCtrlCapability";
      case PTPOperationCodeNikonGetPreviewImg: return @"PTPOperationCodeNikonGetPreviewImg";
      case PTPOperationCodeNikonStartLiveView: return @"PTPOperationCodeNikonStartLiveView";
      case PTPOperationCodeNikonEndLiveView: return @"PTPOperationCodeNikonEndLiveView";
      case PTPOperationCodeNikonGetLiveViewImg: return @"PTPOperationCodeNikonGetLiveViewImg";
      case PTPOperationCodeNikonMfDrive: return @"PTPOperationCodeNikonMfDrive";
      case PTPOperationCodeNikonChangeAfArea: return @"PTPOperationCodeNikonChangeAfArea";
      case PTPOperationCodeNikonAfDriveCancel: return @"PTPOperationCodeNikonAfDriveCancel";
      case PTPOperationCodeNikonInitiateCaptureRecInMedia: return @"PTPOperationCodeNikonInitiateCaptureRecInMedia";
      case PTPOperationCodeNikonGetVendorStorageIDs: return @"PTPOperationCodeNikonGetVendorStorageIDs";
      case PTPOperationCodeNikonStartMovieRecInCard: return @"PTPOperationCodeNikonStartMovieRecInCard";
      case PTPOperationCodeNikonEndMovieRec: return @"PTPOperationCodeNikonEndMovieRec";
      case PTPOperationCodeNikonTerminateCapture: return @"PTPOperationCodeNikonTerminateCapture";
      case PTPOperationCodeNikonGetDevicePTPIPInfo: return @"PTPOperationCodeNikonGetDevicePTPIPInfo";
      case PTPOperationCodeNikonGetPartialObjectHiSpeed: return @"PTPOperationCodeNikonGetPartialObjectHiSpeed";
    }
  } else if (vendorExtension == PTPVendorExtensionCanon) {
    switch (operationCode) {
      case PTPOperationCodeCanonGetStorageIDs: return @"PTPOperationCodeCanonGetStorageIDs";
      case PTPOperationCodeCanonGetStorageInfo: return @"PTPOperationCodeCanonGetStorageInfo";
      case PTPOperationCodeCanonGetObjectInfo: return @"PTPOperationCodeCanonGetObjectInfo";
      case PTPOperationCodeCanonGetObject: return @"PTPOperationCodeCanonGetObject";
      case PTPOperationCodeCanonDeleteObject: return @"PTPOperationCodeCanonDeleteObject";
      case PTPOperationCodeCanonFormatStore: return @"PTPOperationCodeCanonFormatStore";
      case PTPOperationCodeCanonGetPartialObject: return @"PTPOperationCodeCanonGetPartialObject";
      case PTPOperationCodeCanonGetDeviceInfoEx: return @"PTPOperationCodeCanonGetDeviceInfoEx";
      case PTPOperationCodeCanonGetObjectInfoEx: return @"PTPOperationCodeCanonGetObjectInfoEx";
      case PTPOperationCodeCanonGetThumbEx: return @"PTPOperationCodeCanonGetThumbEx";
      case PTPOperationCodeCanonSendPartialObject: return @"PTPOperationCodeCanonSendPartialObject";
      case PTPOperationCodeCanonSetObjectAttributes: return @"PTPOperationCodeCanonSetObjectAttributes";
      case PTPOperationCodeCanonGetObjectTime: return @"PTPOperationCodeCanonGetObjectTime";
      case PTPOperationCodeCanonSetObjectTime: return @"PTPOperationCodeCanonSetObjectTime";
      case PTPOperationCodeCanonRemoteRelease: return @"PTPOperationCodeCanonRemoteRelease";
      case PTPOperationCodeCanonSetDevicePropValueEx: return @"PTPOperationCodeCanonSetDevicePropValueEx";
      case PTPOperationCodeCanonGetRemoteMode: return @"PTPOperationCodeCanonGetRemoteMode";
      case PTPOperationCodeCanonSetRemoteMode: return @"PTPOperationCodeCanonSetRemoteMode";
      case PTPOperationCodeCanonSetEventMode: return @"PTPOperationCodeCanonSetEventMode";
      case PTPOperationCodeCanonGetEvent: return @"PTPOperationCodeCanonGetEvent";
      case PTPOperationCodeCanonTransferComplete: return @"PTPOperationCodeCanonTransferComplete";
      case PTPOperationCodeCanonCancelTransfer: return @"PTPOperationCodeCanonCancelTransfer";
      case PTPOperationCodeCanonResetTransfer: return @"PTPOperationCodeCanonResetTransfer";
      case PTPOperationCodeCanonPCHDDCapacity: return @"PTPOperationCodeCanonPCHDDCapacity";
      case PTPOperationCodeCanonSetUILock: return @"PTPOperationCodeCanonSetUILock";
      case PTPOperationCodeCanonResetUILock: return @"PTPOperationCodeCanonResetUILock";
      case PTPOperationCodeCanonKeepDeviceOn: return @"PTPOperationCodeCanonKeepDeviceOn";
      case PTPOperationCodeCanonSetNullPacketMode: return @"PTPOperationCodeCanonSetNullPacketMode";
      case PTPOperationCodeCanonUpdateFirmware: return @"PTPOperationCodeCanonUpdateFirmware";
      case PTPOperationCodeCanonTransferCompleteDT: return @"PTPOperationCodeCanonTransferCompleteDT";
      case PTPOperationCodeCanonCancelTransferDT: return @"PTPOperationCodeCanonCancelTransferDT";
      case PTPOperationCodeCanonSetWftProfile: return @"PTPOperationCodeCanonSetWftProfile";
      case PTPOperationCodeCanonGetWftProfile: return @"PTPOperationCodeCanonGetWftProfile";
      case PTPOperationCodeCanonSetProfileToWft: return @"PTPOperationCodeCanonSetProfileToWft";
      case PTPOperationCodeCanonBulbStart: return @"PTPOperationCodeCanonBulbStart";
      case PTPOperationCodeCanonBulbEnd: return @"PTPOperationCodeCanonBulbEnd";
      case PTPOperationCodeCanonRequestDevicePropValue: return @"PTPOperationCodeCanonRequestDevicePropValue";
      case PTPOperationCodeCanonRemoteReleaseOn: return @"PTPOperationCodeCanonRemoteReleaseOn";
      case PTPOperationCodeCanonRemoteReleaseOff: return @"PTPOperationCodeCanonRemoteReleaseOff";
      case PTPOperationCodeCanonRegistBackgroundImage: return @"PTPOperationCodeCanonRegistBackgroundImage";
      case PTPOperationCodeCanonChangePhotoStudioMode: return @"PTPOperationCodeCanonChangePhotoStudioMode";
      case PTPOperationCodeCanonGetPartialObjectEx: return @"PTPOperationCodeCanonGetPartialObjectEx";
      case PTPOperationCodeCanonResetMirrorLockupState: return @"PTPOperationCodeCanonResetMirrorLockupState";
      case PTPOperationCodeCanonPopupBuiltinFlash: return @"PTPOperationCodeCanonPopupBuiltinFlash";
      case PTPOperationCodeCanonEndGetPartialObjectEx: return @"PTPOperationCodeCanonEndGetPartialObjectEx";
      case PTPOperationCodeCanonMovieSelectSWOn: return @"PTPOperationCodeCanonMovieSelectSWOn";
      case PTPOperationCodeCanonMovieSelectSWOff: return @"PTPOperationCodeCanonMovieSelectSWOff";
      case PTPOperationCodeCanonGetCTGInfo: return @"PTPOperationCodeCanonGetCTGInfo";
      case PTPOperationCodeCanonGetLensAdjust: return @"PTPOperationCodeCanonGetLensAdjust";
      case PTPOperationCodeCanonSetLensAdjust: return @"PTPOperationCodeCanonSetLensAdjust";
      case PTPOperationCodeCanonGetMusicInfo: return @"PTPOperationCodeCanonGetMusicInfo";
      case PTPOperationCodeCanonCreateHandle: return @"PTPOperationCodeCanonCreateHandle";
      case PTPOperationCodeCanonSendPartialObjectEx: return @"PTPOperationCodeCanonSendPartialObjectEx";
      case PTPOperationCodeCanonEndSendPartialObjectEx: return @"PTPOperationCodeCanonEndSendPartialObjectEx";
      case PTPOperationCodeCanonSetCTGInfo: return @"PTPOperationCodeCanonSetCTGInfo";
      case PTPOperationCodeCanonSetRequestOLCInfoGroup: return @"PTPOperationCodeCanonSetRequestOLCInfoGroup";
      case PTPOperationCodeCanonSetRequestRollingPitchingLevel: return @"PTPOperationCodeCanonSetRequestRollingPitchingLevel";
      case PTPOperationCodeCanonGetCameraSupport: return @"PTPOperationCodeCanonGetCameraSupport";
      case PTPOperationCodeCanonSetRating: return @"PTPOperationCodeCanonSetRating";
      case PTPOperationCodeCanonRequestInnerDevelopStart: return @"PTPOperationCodeCanonRequestInnerDevelopStart";
      case PTPOperationCodeCanonRequestInnerDevelopParamChange: return @"PTPOperationCodeCanonRequestInnerDevelopParamChange";
      case PTPOperationCodeCanonRequestInnerDevelopEnd: return @"PTPOperationCodeCanonRequestInnerDevelopEnd";
      case PTPOperationCodeCanonGpsLoggingDataMode: return @"PTPOperationCodeCanonGpsLoggingDataMode";
      case PTPOperationCodeCanonGetGpsLogCurrentHandle: return @"PTPOperationCodeCanonGetGpsLogCurrentHandle";
      case PTPOperationCodeCanonInitiateViewfinder: return @"PTPOperationCodeCanonInitiateViewfinder";
      case PTPOperationCodeCanonTerminateViewfinder: return @"PTPOperationCodeCanonTerminateViewfinder";
      case PTPOperationCodeCanonGetViewFinderData: return @"PTPOperationCodeCanonGetViewFinderData";
      case PTPOperationCodeCanonDoAf: return @"PTPOperationCodeCanonDoAf";
      case PTPOperationCodeCanonDriveLens: return @"PTPOperationCodeCanonDriveLens";
      case PTPOperationCodeCanonDepthOfFieldPreview: return @"PTPOperationCodeCanonDepthOfFieldPreview";
      case PTPOperationCodeCanonClickWB: return @"PTPOperationCodeCanonClickWB";
      case PTPOperationCodeCanonZoom: return @"PTPOperationCodeCanonZoom";
      case PTPOperationCodeCanonZoomPosition: return @"PTPOperationCodeCanonZoomPosition";
      case PTPOperationCodeCanonSetLiveAfFrame: return @"PTPOperationCodeCanonSetLiveAfFrame";
      case PTPOperationCodeCanonTouchAfPosition: return @"PTPOperationCodeCanonTouchAfPosition";
      case PTPOperationCodeCanonSetLvPcFlavoreditMode: return @"PTPOperationCodeCanonSetLvPcFlavoreditMode";
      case PTPOperationCodeCanonSetLvPcFlavoreditParam: return @"PTPOperationCodeCanonSetLvPcFlavoreditParam";
      case PTPOperationCodeCanonAfCancel: return @"PTPOperationCodeCanonAfCancel";
      case PTPOperationCodeCanonSetDefaultCameraSetting: return @"PTPOperationCodeCanonSetDefaultCameraSetting";
      case PTPOperationCodeCanonGetAEData: return @"PTPOperationCodeCanonGetAEData";
      case PTPOperationCodeCanonNotifyNetworkError: return @"PTPOperationCodeCanonNotifyNetworkError";
      case PTPOperationCodeCanonAdapterTransferProgress: return @"PTPOperationCodeCanonAdapterTransferProgress";
      case PTPOperationCodeCanonTransferComplete2: return @"PTPOperationCodeCanonTransferComplete2";
      case PTPOperationCodeCanonCancelTransfer2: return @"PTPOperationCodeCanonCancelTransfer2";
      case PTPOperationCodeCanonFAPIMessageTX: return @"PTPOperationCodeCanonFAPIMessageTX";
      case PTPOperationCodeCanonFAPIMessageRX: return @"PTPOperationCodeCanonFAPIMessageRX";
    }
  }
  return [NSString stringWithFormat:@"PTPOperationCode0x%04x", operationCode];
}

- (id)init {
	self = [super init];
	if (self) {
		_numberOfParameters = 0;
	}
	return self;
}

- (id)initWithVendorExtension:(PTPVendorExtension)vendorExtension {
  return [super initWithVendorExtension:vendorExtension];
}

- (NSData*)commandBuffer {
  unsigned int len = 12 + 4*_numberOfParameters;
  unsigned char* buffer = (unsigned char*)calloc(len, 1);
  unsigned char* buf = buffer;
  ptpWriteUnsignedInt(&buf, len);
  ptpWriteUnsignedShort(&buf, 1);
  ptpWriteUnsignedShort(&buf, _operationCode);
  ptpWriteUnsignedInt(&buf, 0);
  if (_numberOfParameters > 0)
    ptpWriteUnsignedInt(&buf, _parameter1);
  if (_numberOfParameters > 1)
    ptpWriteUnsignedInt(&buf, _parameter2);
  if (_numberOfParameters > 2)
    ptpWriteUnsignedInt(&buf, _parameter3);
  if (_numberOfParameters > 3)
    ptpWriteUnsignedInt(&buf, _parameter4);
  if (_numberOfParameters > 4)
    ptpWriteUnsignedInt(&buf, _parameter5);
  return [NSData dataWithBytesNoCopy:buffer length:len freeWhenDone:YES];
}

- (NSString *)operationCodeName {
  return [PTPOperationRequest operationCodeName:_operationCode vendorExtension:self.vendorExtension];
}

- (NSString*)description {
	NSMutableString* s = [NSMutableString stringWithFormat:@"%@", self.operationCodeName];
	if (self.numberOfParameters > 0)
		[s appendFormat:@"[ 0x%08X", self.parameter1];
	if (self.numberOfParameters > 1)
		[s appendFormat:@", 0x%08X", self.parameter2];
	if (self.numberOfParameters > 2)
		[s appendFormat:@", 0x%08X", self.parameter3];
	if (self.numberOfParameters > 3)
		[s appendFormat:@", 0x%08X", self.parameter4];
	if (self.numberOfParameters > 4)
		[s appendFormat:@", 0x%08X", self.parameter5];
  if (self.numberOfParameters > 0)
    [s appendString:@"]"];
	return s;
}

@end

//--------------------------------------------------------------------------------------------------------- PTPOperationResponse

@implementation PTPOperationResponse

+ (NSString *)responseCodeName:(PTPResponseCode)responseCode vendorExtension:(PTPVendorExtension)vendorExtension {
  switch (responseCode) {
    case PTPResponseCodeUndefined: return @"PTPResponseCodeUndefined";
    case PTPResponseCodeOK: return @"PTPResponseCodeOK";
    case PTPResponseCodeGeneralError: return @"PTPResponseCodeGeneralError";
    case PTPResponseCodeSessionNotOpen: return @"PTPResponseCodeSessionNotOpen";
    case PTPResponseCodeInvalidTransactionID: return @"PTPResponseCodeInvalidTransactionID";
    case PTPResponseCodeOperationNotSupported: return @"PTPResponseCodeOperationNotSupported";
    case PTPResponseCodeParameterNotSupported: return @"PTPResponseCodeParameterNotSupported";
    case PTPResponseCodeIncompleteTransfer: return @"PTPResponseCodeIncompleteTransfer";
    case PTPResponseCodeInvalidStorageID: return @"PTPResponseCodeInvalidStorageID";
    case PTPResponseCodeInvalidObjectHandle: return @"PTPResponseCodeInvalidObjectHandle";
    case PTPResponseCodeDevicePropNotSupported: return @"PTPResponseCodeDevicePropNotSupported";
    case PTPResponseCodeInvalidObjectFormatCode: return @"PTPResponseCodeInvalidObjectFormatCode";
    case PTPResponseCodeStoreFull: return @"PTPResponseCodeStoreFull";
    case PTPResponseCodeObjectWriteProtected: return @"PTPResponseCodeObjectWriteProtected";
    case PTPResponseCodeStoreReadOnly: return @"PTPResponseCodeStoreReadOnly";
    case PTPResponseCodeAccessDenied: return @"PTPResponseCodeAccessDenied";
    case PTPResponseCodeNoThumbnailPresent: return @"PTPResponseCodeNoThumbnailPresent";
    case PTPResponseCodeSelfTestFailed: return @"PTPResponseCodeSelfTestFailed";
    case PTPResponseCodePartialDeletion: return @"PTPResponseCodePartialDeletion";
    case PTPResponseCodeStoreNotAvailable: return @"PTPResponseCodeStoreNotAvailable";
    case PTPResponseCodeSpecificationByFormatUnsupported: return @"PTPResponseCodeSpecificationByFormatUnsupported";
    case PTPResponseCodeNoValidObjectInfo: return @"PTPResponseCodeNoValidObjectInfo";
    case PTPResponseCodeInvalidCodeFormat: return @"PTPResponseCodeInvalidCodeFormat";
    case PTPResponseCodeUnknownVendorCode: return @"PTPResponseCodeUnknownVendorCode";
    case PTPResponseCodeCaptureAlreadyTerminated: return @"PTPResponseCodeCaptureAlreadyTerminated";
    case PTPResponseCodeDeviceBusy: return @"PTPResponseCodeDeviceBusy";
    case PTPResponseCodeInvalidParentObject: return @"PTPResponseCodeInvalidParentObject";
    case PTPResponseCodeInvalidDevicePropFormat: return @"PTPResponseCodeInvalidDevicePropFormat";
    case PTPResponseCodeInvalidDevicePropValue: return @"PTPResponseCodeInvalidDevicePropValue";
    case PTPResponseCodeInvalidParameter: return @"PTPResponseCodeInvalidParameter";
    case PTPResponseCodeSessionAlreadyOpen: return @"PTPResponseCodeSessionAlreadyOpen";
    case PTPResponseCodeTransactionCancelled: return @"PTPResponseCodeTransactionCancelled";
    case PTPResponseCodeSpecificationOfDestinationUnsupported: return @"PTPResponseCodeSpecificationOfDestinationUnsupported";
    case PTPResponseCodeMTPUndefined: return @"PTPResponseCodeMTPUndefined";
    case PTPResponseCodeMTPInvalid_ObjectPropCode: return @"PTPResponseCodeMTPInvalid_ObjectPropCode";
    case PTPResponseCodeMTPInvalid_ObjectProp_Format: return @"PTPResponseCodeMTPInvalid_ObjectProp_Format";
    case PTPResponseCodeMTPInvalid_ObjectProp_Value: return @"PTPResponseCodeMTPInvalid_ObjectProp_Value";
    case PTPResponseCodeMTPInvalid_ObjectReference: return @"PTPResponseCodeMTPInvalid_ObjectReference";
    case PTPResponseCodeMTPInvalid_Dataset: return @"PTPResponseCodeMTPInvalid_Dataset";
    case PTPResponseCodeMTPSpecification_By_Group_Unsupported: return @"PTPResponseCodeMTPSpecification_By_Group_Unsupported";
    case PTPResponseCodeMTPSpecification_By_Depth_Unsupported: return @"PTPResponseCodeMTPSpecification_By_Depth_Unsupported";
    case PTPResponseCodeMTPObject_Too_Large: return @"PTPResponseCodeMTPObject_Too_Large";
    case PTPResponseCodeMTPObjectProp_Not_Supported: return @"PTPResponseCodeMTPObjectProp_Not_Supported";
  }
  if (vendorExtension == PTPVendorExtensionNikon) {
    switch (responseCode) {
      case PTPResponseCodeNikonHardwareError: return @"PTPResponseCodeNikonHardwareError";
      case PTPResponseCodeNikonOutOfFocus: return @"PTPResponseCodeNikonOutOfFocus";
      case PTPResponseCodeNikonChangeCameraModeFailed: return @"PTPResponseCodeNikonChangeCameraModeFailed";
      case PTPResponseCodeNikonInvalidStatus: return @"PTPResponseCodeNikonInvalidStatus";
      case PTPResponseCodeNikonSetPropertyNotSupported: return @"PTPResponseCodeNikonSetPropertyNotSupported";
      case PTPResponseCodeNikonWbResetError: return @"PTPResponseCodeNikonWbResetError";
      case PTPResponseCodeNikonDustReferenceError: return @"PTPResponseCodeNikonDustReferenceError";
      case PTPResponseCodeNikonShutterSpeedBulb: return @"PTPResponseCodeNikonShutterSpeedBulb";
      case PTPResponseCodeNikonMirrorUpSequence: return @"PTPResponseCodeNikonMirrorUpSequence";
      case PTPResponseCodeNikonCameraModeNotAdjustFNumber: return @"PTPResponseCodeNikonCameraModeNotAdjustFNumber";
      case PTPResponseCodeNikonNotLiveView: return @"PTPResponseCodeNikonNotLiveView";
      case PTPResponseCodeNikonMfDriveStepEnd: return @"PTPResponseCodeNikonMfDriveStepEnd";
      case PTPResponseCodeNikonMfDriveStepInsufficiency: return @"PTPResponseCodeNikonMfDriveStepInsufficiency";
      case PTPResponseCodeNikonAdvancedTransferCancel: return @"PTPResponseCodeNikonAdvancedTransferCancel";
    }
  }
  if (vendorExtension == PTPVendorExtensionCanon) {
    switch (responseCode) {
      case PTPResponseCodeUnknownCommand: return @"PTPResponseCodeUnknownCommand";
      case PTPResponseCodeOperationRefused: return @"PTPResponseCodeOperationRefused";
      case PTPResponseCodeLensCover: return @"PTPResponseCodeLensCover";
      case PTPResponseCodeBatteryLow: return @"PTPResponseCodeBatteryLow";
      case PTPResponseCodeNotReady: return @"PTPResponseCodeNotReady";    }
  }
  return [NSString stringWithFormat:@"PTPResponseCode0x%04x", responseCode];
}

- (id)initWithData:(NSData*)data vendorExtension:(PTPVendorExtension)vendorExtension {
  NSUInteger dataLength = [data length];
  if ((data == NULL) || (dataLength < 12) || (dataLength > 32))
    return NULL;
  unsigned char* buffer = (unsigned char*)[data bytes];
  unsigned int size = CFSwapInt32LittleToHost(*(unsigned int*)buffer);
  unsigned short type = CFSwapInt16LittleToHost(*(unsigned short*)(buffer+4));
  if (size < 12 || size > 32 || type != 3)
    return NULL;
  if ((self = [super initWithVendorExtension:vendorExtension])) {
    unsigned char* buf = buffer + 6;
    _responseCode = ptpReadUnsignedShort(&buf);
    _transactionID = ptpReadUnsignedInt(&buf);
    _numberOfParameters = (size-12) >> 2;
    if (_numberOfParameters > 0)
      _parameter1 = ptpReadUnsignedInt(&buf);
    if (_numberOfParameters > 1)
      _parameter2 = ptpReadUnsignedInt(&buf);
    if (_numberOfParameters > 2)
      _parameter3 = ptpReadUnsignedInt(&buf);
    if (_numberOfParameters > 3)
      _parameter4 = ptpReadUnsignedInt(&buf);
    if (_numberOfParameters > 4)
      _parameter5 = ptpReadUnsignedInt(&buf);
  }
  return self;
}

- (NSString *)responseCodeName {
  return [PTPOperationResponse responseCodeName:_responseCode vendorExtension:self.vendorExtension];
}

- (NSString*)description {
	NSMutableString* s = [NSMutableString stringWithFormat:@"%@", self.responseCodeName];
	if (self.numberOfParameters > 0)
		[s appendFormat:@"[ 0x%08X", self.parameter1];
	if (self.numberOfParameters > 1)
		[s appendFormat:@", 0x%08X", self.parameter2];
	if (self.numberOfParameters > 2)
		[s appendFormat:@", 0x%08X", self.parameter3];
	if (self.numberOfParameters > 3)
		[s appendFormat:@", 0x%08X", self.parameter4];
	if (self.numberOfParameters > 4)
		[s appendFormat:@", 0x%08X", self.parameter5];
  if (self.numberOfParameters > 0)
    [s appendString:@"]"];
	return s;
}

@end

//--------------------------------------------------------------------------------------------------------------------- PTPEvent

@implementation PTPEvent

+ (NSString *)eventCodeName:(PTPEventCode)eventCode vendorExtension:(PTPVendorExtension)vendorExtension {
  switch (eventCode) {
    case PTPEventCodeUndefined: return @"PTPEventCodeUndefined";
    case PTPEventCodeCancelTransaction: return @"PTPEventCodeCancelTransaction";
    case PTPEventCodeObjectAdded: return @"PTPEventCodeObjectAdded";
    case PTPEventCodeObjectRemoved: return @"PTPEventCodeObjectRemoved";
    case PTPEventCodeStoreAdded: return @"PTPEventCodeStoreAdded";
    case PTPEventCodeStoreRemoved: return @"PTPEventCodeStoreRemoved";
    case PTPEventCodeDevicePropChanged: return @"PTPEventCodeDevicePropChanged";
    case PTPEventCodeObjectInfoChanged: return @"PTPEventCodeObjectInfoChanged";
    case PTPEventCodeDeviceInfoChanged: return @"PTPEventCodeDeviceInfoChanged";
    case PTPEventCodeRequestObjectTransfer: return @"PTPEventCodeRequestObjectTransfer";
    case PTPEventCodeStoreFull: return @"PTPEventCodeStoreFull";
    case PTPEventCodeDeviceReset: return @"PTPEventCodeDeviceReset";
    case PTPEventCodeStorageInfoChanged: return @"PTPEventCodeStorageInfoChanged";
    case PTPEventCodeCaptureComplete: return @"PTPEventCodeCaptureComplete";
    case PTPEventCodeUnreportedStatus: return @"PTPEventCodeUnreportedStatus";
    case PTPEventCodeAppleDeviceUnlocked: return @"PTPEventCodeAppleDeviceUnlocked";
    case PTPEventCodeAppleUserAssignedNameChanged: return @"PTPEventCodeAppleUserAssignedNameChanged";
  }
  if (vendorExtension == PTPVendorExtensionNikon) {
    switch (eventCode) {
      case PTPEventCodeNikonObjectAddedInSDRAM: return @"PTPEventCodeNikonObjectAddedInSDRAM";
      case PTPEventCodeNikonCaptureCompleteRecInSdram: return @"PTPEventCodeNikonCaptureCompleteRecInSdram";
      case PTPEventCodeNikonAdvancedTransfer: return @"PTPEventCodeNikonAdvancedTransfer";
      case PTPEventCodeNikonPreviewImageAdded: return @"PTPEventCodeNikonPreviewImageAdded";
    }
  }
  if (vendorExtension == PTPVendorExtensionCanon) {
    switch (eventCode) {
      case PTPEventCodeCanonRequestGetEvent: return @"PTPEventCodeCanonRequestGetEvent";
      case PTPEventCodeCanonObjectAddedEx: return @"PTPEventCodeCanonObjectAddedEx";
      case PTPEventCodeCanonObjectRemoved: return @"PTPEventCodeCanonObjectRemoved";
      case PTPEventCodeCanonRequestGetObjectInfoEx: return @"PTPEventCodeCanonRequestGetObjectInfoEx";
      case PTPEventCodeCanonStorageStatusChanged: return @"PTPEventCodeCanonStorageStatusChanged";
      case PTPEventCodeCanonStorageInfoChanged: return @"PTPEventCodeCanonStorageInfoChanged";
      case PTPEventCodeCanonRequestObjectTransfer: return @"PTPEventCodeCanonRequestObjectTransfer";
      case PTPEventCodeCanonObjectInfoChangedEx: return @"PTPEventCodeCanonObjectInfoChangedEx";
      case PTPEventCodeCanonObjectContentChanged: return @"PTPEventCodeCanonObjectContentChanged";
      case PTPEventCodeCanonPropValueChanged: return @"PTPEventCodeCanonPropValueChanged";
      case PTPEventCodeCanonAvailListChanged: return @"PTPEventCodeCanonAvailListChanged";
      case PTPEventCodeCanonCameraStatusChanged: return @"PTPEventCodeCanonCameraStatusChanged";
      case PTPEventCodeCanonWillSoonShutdown: return @"PTPEventCodeCanonWillSoonShutdown";
      case PTPEventCodeCanonShutdownTimerUpdated: return @"PTPEventCodeCanonShutdownTimerUpdated";
      case PTPEventCodeCanonRequestCancelTransfer: return @"PTPEventCodeCanonRequestCancelTransfer";
      case PTPEventCodeCanonRequestObjectTransferDT: return @"PTPEventCodeCanonRequestObjectTransferDT";
      case PTPEventCodeCanonRequestCancelTransferDT: return @"PTPEventCodeCanonRequestCancelTransferDT";
      case PTPEventCodeCanonStoreAdded: return @"PTPEventCodeCanonStoreAdded";
      case PTPEventCodeCanonStoreRemoved: return @"PTPEventCodeCanonStoreRemoved";
      case PTPEventCodeCanonBulbExposureTime: return @"PTPEventCodeCanonBulbExposureTime";
      case PTPEventCodeCanonRecordingTime: return @"PTPEventCodeCanonRecordingTime";
      case PTPEventCodeCanonRequestObjectTransferTS: return @"PTPEventCodeCanonRequestObjectTransferTS";
      case PTPEventCodeCanonAfResult: return @"PTPEventCodeCanonAfResult";
      case PTPEventCodeCanonCTGInfoCheckComplete: return @"PTPEventCodeCanonCTGInfoCheckComplete";
      case PTPEventCodeCanonOLCInfoChanged: return @"PTPEventCodeCanonOLCInfoChanged";
      case PTPEventCodeCanonRequestObjectTransferFTP: return @"PTPEventCodeCanonRequestObjectTransferFTP";
    }
  }
  return [NSString stringWithFormat:@"PTPEventCodeCode0x%04x", eventCode];
}

- (id)initWithData:(NSData*)data vendorExtension:(PTPVendorExtension)vendorExtension {
  NSUInteger dataLength = [data length];
  if ((data == NULL) || (dataLength < 12) || (dataLength > 24))
    return NULL;
  unsigned char* buffer = (unsigned char*)[data bytes];
  unsigned int size = CFSwapInt32LittleToHost(*(unsigned int*)buffer);
  unsigned short type = CFSwapInt16LittleToHost(*(unsigned short*)(buffer+4));
  if (size < 12 || size > 24 || type != 4)
    return NULL;
  if ((self = [super initWithVendorExtension:vendorExtension])) {
    unsigned char* buf = buffer + 6;
    _eventCode = ptpReadUnsignedShort(&buf);
    _transactionID = ptpReadUnsignedInt(&buf);
    _numberOfParameters = (size-12) >> 2;
    if (_numberOfParameters > 0)
      _parameter1 = ptpReadUnsignedInt(&buf);
    if (_numberOfParameters > 1)
      _parameter2 = ptpReadUnsignedInt(&buf);
    if (_numberOfParameters > 2)
      _parameter3 = ptpReadUnsignedInt(&buf);
  }
  return self;
}

- (id)initWithCode:(PTPEventCode)eventCode parameter1:(unsigned int)parameter1 vendorExtension:(PTPVendorExtension)vendorExtension {
  self = [super initWithVendorExtension:vendorExtension];
  if (self) {
    _eventCode = eventCode;
    _numberOfParameters = 1;
    _parameter1 = parameter1;
  }
  return self;
}

- (NSString *)eventCodeName {
	return [PTPEvent eventCodeName:_eventCode vendorExtension:self.vendorExtension];
}

- (NSString*)description {
	NSMutableString* s = [NSMutableString stringWithFormat:@"%@", self.eventCodeName];
	if (self.numberOfParameters > 0)
		[s appendFormat:@"[ 0x%08X", self.parameter1];
	if (self.numberOfParameters > 1)
		[s appendFormat:@", 0x%08X", self.parameter2];
	if (self.numberOfParameters > 2)
		[s appendFormat:@", 0x%08X", self.parameter3];
  if (self.numberOfParameters > 0)
    [s appendString:@"]"];
	return s;
}

@end

//------------------------------------------------------------------------------------------------------------------------------ PTPProperty

@implementation PTPProperty

+ (NSString *)propertyCodeName:(PTPPropertyCode)propertyCode vendorExtension:(PTPVendorExtension)vendorExtension {
  switch (propertyCode) {
    case PTPPropertyCodeUndefined: return @"PTPPropertyCodeUndefined";
    case PTPPropertyCodeBatteryLevel: return @"PTPPropertyCodeBatteryLevel";
    case PTPPropertyCodeFunctionalMode: return @"PTPPropertyCodeFunctionalMode";
    case PTPPropertyCodeImageSize: return @"PTPPropertyCodeImageSize";
    case PTPPropertyCodeCompressionSetting: return @"PTPPropertyCodeCompressionSetting";
    case PTPPropertyCodeWhiteBalance: return @"PTPPropertyCodeWhiteBalance";
    case PTPPropertyCodeRGBGain: return @"PTPPropertyCodeRGBGain";
    case PTPPropertyCodeFNumber: return @"PTPPropertyCodeFNumber";
    case PTPPropertyCodeFocalLength: return @"PTPPropertyCodeFocalLength";
    case PTPPropertyCodeFocusDistance: return @"PTPPropertyCodeFocusDistance";
    case PTPPropertyCodeFocusMode: return @"PTPPropertyCodeFocusMode";
    case PTPPropertyCodeExposureMeteringMode: return @"PTPPropertyCodeExposureMeteringMode";
    case PTPPropertyCodeFlashMode: return @"PTPPropertyCodeFlashMode";
    case PTPPropertyCodeExposureTime: return @"PTPPropertyCodeExposureTime";
    case PTPPropertyCodeExposureProgramMode: return @"PTPPropertyCodeExposureProgramMode";
    case PTPPropertyCodeExposureIndex: return @"PTPPropertyCodeExposureIndex";
    case PTPPropertyCodeExposureBiasCompensation: return @"PTPPropertyCodeExposureBiasCompensation";
    case PTPPropertyCodeDateTime: return @"PTPPropertyCodeDateTime";
    case PTPPropertyCodeCaptureDelay: return @"PTPPropertyCodeCaptureDelay";
    case PTPPropertyCodeStillCaptureMode: return @"PTPPropertyCodeStillCaptureMode";
    case PTPPropertyCodeContrast: return @"PTPPropertyCodeContrast";
    case PTPPropertyCodeSharpness: return @"PTPPropertyCodeSharpness";
    case PTPPropertyCodeDigitalZoom: return @"PTPPropertyCodeDigitalZoom";
    case PTPPropertyCodeEffectMode: return @"PTPPropertyCodeEffectMode";
    case PTPPropertyCodeBurstNumber: return @"PTPPropertyCodeBurstNumber";
    case PTPPropertyCodeBurstInterval: return @"PTPPropertyCodeBurstInterval";
    case PTPPropertyCodeTimelapseNumber: return @"PTPPropertyCodeTimelapseNumber";
    case PTPPropertyCodeTimelapseInterval: return @"PTPPropertyCodeTimelapseInterval";
    case PTPPropertyCodeFocusMeteringMode: return @"PTPPropertyCodeFocusMeteringMode";
    case PTPPropertyCodeUploadURL: return @"PTPPropertyCodeUploadURL";
    case PTPPropertyCodeArtist: return @"PTPPropertyCodeArtist";
    case PTPPropertyCodeCopyrightInfo: return @"PTPPropertyCodeCopyrightInfo";
    case PTPPropertyCodeSupportedStreams: return @"PTPPropertyCodeSupportedStreams";
    case PTPPropertyCodeEnabledStreams: return @"PTPPropertyCodeEnabledStreams";
    case PTPPropertyCodeVideoFormat: return @"PTPPropertyCodeVideoFormat";
    case PTPPropertyCodeVideoResolution: return @"PTPPropertyCodeVideoResolution";
    case PTPPropertyCodeVideoQuality: return @"PTPPropertyCodeVideoQuality";
    case PTPPropertyCodeVideoFrameRate: return @"PTPPropertyCodeVideoFrameRate";
    case PTPPropertyCodeVideoContrast: return @"PTPPropertyCodeVideoContrast";
    case PTPPropertyCodeVideoBrightness: return @"PTPPropertyCodeVideoBrightness";
    case PTPPropertyCodeAudioFormat: return @"PTPPropertyCodeAudioFormat";
    case PTPPropertyCodeAudioBitrate: return @"PTPPropertyCodeAudioBitrate";
    case PTPPropertyCodeAudioSamplingRate: return @"PTPPropertyCodeAudioSamplingRate";
    case PTPPropertyCodeAudioBitPerSample: return @"PTPPropertyCodeAudioBitPerSample";
    case PTPPropertyCodeAudioVolume: return @"PTPPropertyCodeAudioVolume";
    case PTPPropertyCodeMTPSynchronizationPartner: return @"PTPPropertyCodeMTPSynchronizationPartner";
    case PTPPropertyCodeMTPDeviceFriendlyName: return @"PTPPropertyCodeMTPDeviceFriendlyName";
    case PTPPropertyCodeMTPVolumeLevel: return @"PTPPropertyCodeMTPVolumeLevel";
    case PTPPropertyCodeMTPDeviceIcon: return @"PTPPropertyCodeMTPDeviceIcon";
    case PTPPropertyCodeMTPSessionInitiatorInfo: return @"PTPPropertyCodeMTPSessionInitiatorInfo";
    case PTPPropertyCodeMTPPerceivedDeviceType: return @"PTPPropertyCodeMTPPerceivedDeviceType";
    case PTPPropertyCodeMTPPlaybackRate: return @"PTPPropertyCodeMTPPlaybackRate";
    case PTPPropertyCodeMTPPlaybackObject: return @"PTPPropertyCodeMTPPlaybackObject";
    case PTPPropertyCodeMTPPlaybackContainerIndex: return @"PTPPropertyCodeMTPPlaybackContainerIndex";
    case PTPPropertyCodeMTPPlaybackPosition: return @"PTPPropertyCodeMTPPlaybackPosition";
  }
  if (vendorExtension == PTPVendorExtensionNikon) {
    switch (propertyCode) {
      case PTPPropertyCodeNikonShootingBank: return @"PTPPropertyCodeNikonShootingBank";
      case PTPPropertyCodeNikonShootingBankNameA: return @"PTPPropertyCodeNikonShootingBankNameA";
      case PTPPropertyCodeNikonShootingBankNameB: return @"PTPPropertyCodeNikonShootingBankNameB";
      case PTPPropertyCodeNikonShootingBankNameC: return @"PTPPropertyCodeNikonShootingBankNameC";
      case PTPPropertyCodeNikonShootingBankNameD: return @"PTPPropertyCodeNikonShootingBankNameD";
      case PTPPropertyCodeNikonResetBank0: return @"PTPPropertyCodeNikonResetBank0";
      case PTPPropertyCodeNikonRawCompression: return @"PTPPropertyCodeNikonRawCompression";
      case PTPPropertyCodeNikonWhiteBalanceAutoBias: return @"PTPPropertyCodeNikonWhiteBalanceAutoBias";
      case PTPPropertyCodeNikonWhiteBalanceTungstenBias: return @"PTPPropertyCodeNikonWhiteBalanceTungstenBias";
      case PTPPropertyCodeNikonWhiteBalanceFluorescentBias: return @"PTPPropertyCodeNikonWhiteBalanceFluorescentBias";
      case PTPPropertyCodeNikonWhiteBalanceDaylightBias: return @"PTPPropertyCodeNikonWhiteBalanceDaylightBias";
      case PTPPropertyCodeNikonWhiteBalanceFlashBias: return @"PTPPropertyCodeNikonWhiteBalanceFlashBias";
      case PTPPropertyCodeNikonWhiteBalanceCloudyBias: return @"PTPPropertyCodeNikonWhiteBalanceCloudyBias";
      case PTPPropertyCodeNikonWhiteBalanceShadeBias: return @"PTPPropertyCodeNikonWhiteBalanceShadeBias";
      case PTPPropertyCodeNikonWhiteBalanceColorTemperature: return @"PTPPropertyCodeNikonWhiteBalanceColorTemperature";
      case PTPPropertyCodeNikonWhiteBalancePresetNo: return @"PTPPropertyCodeNikonWhiteBalancePresetNo";
      case PTPPropertyCodeNikonWhiteBalancePresetName0: return @"PTPPropertyCodeNikonWhiteBalancePresetName0";
      case PTPPropertyCodeNikonWhiteBalancePresetName1: return @"PTPPropertyCodeNikonWhiteBalancePresetName1";
      case PTPPropertyCodeNikonWhiteBalancePresetName2: return @"PTPPropertyCodeNikonWhiteBalancePresetName2";
      case PTPPropertyCodeNikonWhiteBalancePresetName3: return @"PTPPropertyCodeNikonWhiteBalancePresetName3";
      case PTPPropertyCodeNikonWhiteBalancePresetName4: return @"PTPPropertyCodeNikonWhiteBalancePresetName4";
      case PTPPropertyCodeNikonWhiteBalancePresetVal0: return @"PTPPropertyCodeNikonWhiteBalancePresetVal0";
      case PTPPropertyCodeNikonWhiteBalancePresetVal1: return @"PTPPropertyCodeNikonWhiteBalancePresetVal1";
      case PTPPropertyCodeNikonWhiteBalancePresetVal2: return @"PTPPropertyCodeNikonWhiteBalancePresetVal2";
      case PTPPropertyCodeNikonWhiteBalancePresetVal3: return @"PTPPropertyCodeNikonWhiteBalancePresetVal3";
      case PTPPropertyCodeNikonWhiteBalancePresetVal4: return @"PTPPropertyCodeNikonWhiteBalancePresetVal4";
      case PTPPropertyCodeNikonImageSharpening: return @"PTPPropertyCodeNikonImageSharpening";
      case PTPPropertyCodeNikonToneCompensation: return @"PTPPropertyCodeNikonToneCompensation";
      case PTPPropertyCodeNikonColorModel: return @"PTPPropertyCodeNikonColorModel";
      case PTPPropertyCodeNikonHueAdjustment: return @"PTPPropertyCodeNikonHueAdjustment";
      case PTPPropertyCodeNikonNonCPULensDataFocalLength: return @"PTPPropertyCodeNikonNonCPULensDataFocalLength";
      case PTPPropertyCodeNikonNonCPULensDataMaximumAperture: return @"PTPPropertyCodeNikonNonCPULensDataMaximumAperture";
      case PTPPropertyCodeNikonShootingMode: return @"PTPPropertyCodeNikonShootingMode";
      case PTPPropertyCodeNikonJPEGCompressionPolicy: return @"PTPPropertyCodeNikonJPEGCompressionPolicy";
      case PTPPropertyCodeNikonColorSpace: return @"PTPPropertyCodeNikonColorSpace";
      case PTPPropertyCodeNikonAutoDXCrop: return @"PTPPropertyCodeNikonAutoDXCrop";
      case PTPPropertyCodeNikonFlickerReduction: return @"PTPPropertyCodeNikonFlickerReduction";
      case PTPPropertyCodeNikonRemoteMode: return @"PTPPropertyCodeNikonRemoteMode";
      case PTPPropertyCodeNikonVideoMode: return @"PTPPropertyCodeNikonVideoMode";
      case PTPPropertyCodeNikonEffectMode: return @"PTPPropertyCodeNikonEffectMode";
      case PTPPropertyCodeNikon1Mode: return @"PTPPropertyCodeNikon1Mode";
      case PTPPropertyCodeNikonCSMMenuBankSelect: return @"PTPPropertyCodeNikonCSMMenuBankSelect";
      case PTPPropertyCodeNikonMenuBankNameA: return @"PTPPropertyCodeNikonMenuBankNameA";
      case PTPPropertyCodeNikonMenuBankNameB: return @"PTPPropertyCodeNikonMenuBankNameB";
      case PTPPropertyCodeNikonMenuBankNameC: return @"PTPPropertyCodeNikonMenuBankNameC";
      case PTPPropertyCodeNikonMenuBankNameD: return @"PTPPropertyCodeNikonMenuBankNameD";
      case PTPPropertyCodeNikonResetBank: return @"PTPPropertyCodeNikonResetBank";
      case PTPPropertyCodeNikonAFCModePriority: return @"PTPPropertyCodeNikonAFCModePriority";
      case PTPPropertyCodeNikonAFSModePriority: return @"PTPPropertyCodeNikonAFSModePriority";
      case PTPPropertyCodeNikonGroupDynamicAF: return @"PTPPropertyCodeNikonGroupDynamicAF";
      case PTPPropertyCodeNikonAFActivation: return @"PTPPropertyCodeNikonAFActivation";
      case PTPPropertyCodeNikonFocusAreaIllumManualFocus: return @"PTPPropertyCodeNikonFocusAreaIllumManualFocus";
      case PTPPropertyCodeNikonFocusAreaIllumContinuous: return @"PTPPropertyCodeNikonFocusAreaIllumContinuous";
      case PTPPropertyCodeNikonFocusAreaIllumWhenSelected: return @"PTPPropertyCodeNikonFocusAreaIllumWhenSelected";
      case PTPPropertyCodeNikonFocusAreaWrap: return @"PTPPropertyCodeNikonFocusAreaWrap";
      case PTPPropertyCodeNikonVerticalAFON: return @"PTPPropertyCodeNikonVerticalAFON";
      case PTPPropertyCodeNikonAFLockOn: return @"PTPPropertyCodeNikonAFLockOn";
      case PTPPropertyCodeNikonFocusAreaZone: return @"PTPPropertyCodeNikonFocusAreaZone";
      case PTPPropertyCodeNikonEnableCopyright: return @"PTPPropertyCodeNikonEnableCopyright";
      case PTPPropertyCodeNikonISOAutoTime: return @"PTPPropertyCodeNikonISOAutoTime";
      case PTPPropertyCodeNikonEVISOStep: return @"PTPPropertyCodeNikonEVISOStep";
      case PTPPropertyCodeNikonEVStep: return @"PTPPropertyCodeNikonEVStep";
      case PTPPropertyCodeNikonEVStepExposureComp: return @"PTPPropertyCodeNikonEVStepExposureComp";
      case PTPPropertyCodeNikonExposureCompensation: return @"PTPPropertyCodeNikonExposureCompensation";
      case PTPPropertyCodeNikonCenterWeightArea: return @"PTPPropertyCodeNikonCenterWeightArea";
      case PTPPropertyCodeNikonExposureBaseMatrix: return @"PTPPropertyCodeNikonExposureBaseMatrix";
      case PTPPropertyCodeNikonExposureBaseCenter: return @"PTPPropertyCodeNikonExposureBaseCenter";
      case PTPPropertyCodeNikonExposureBaseSpot: return @"PTPPropertyCodeNikonExposureBaseSpot";
      case PTPPropertyCodeNikonLiveViewAFArea: return @"PTPPropertyCodeNikonLiveViewAFArea";
      case PTPPropertyCodeNikonAELockMode: return @"PTPPropertyCodeNikonAELockMode";
      case PTPPropertyCodeNikonAELAFLMode: return @"PTPPropertyCodeNikonAELAFLMode";
      case PTPPropertyCodeNikonLiveViewAFFocus: return @"PTPPropertyCodeNikonLiveViewAFFocus";
      case PTPPropertyCodeNikonMeterOff: return @"PTPPropertyCodeNikonMeterOff";
      case PTPPropertyCodeNikonSelfTimer: return @"PTPPropertyCodeNikonSelfTimer";
      case PTPPropertyCodeNikonMonitorOff: return @"PTPPropertyCodeNikonMonitorOff";
      case PTPPropertyCodeNikonISOSensitivity: return @"PTPPropertyCodeNikonISOSensitivity";
      case PTPPropertyCodeNikonImgConfTime: return @"PTPPropertyCodeNikonImgConfTime";
      case PTPPropertyCodeNikonAutoOffTimers: return @"PTPPropertyCodeNikonAutoOffTimers";
      case PTPPropertyCodeNikonAngleLevel: return @"PTPPropertyCodeNikonAngleLevel";
      case PTPPropertyCodeNikonShootingSpeed: return @"PTPPropertyCodeNikonShootingSpeed";
      case PTPPropertyCodeNikonMaximumShots: return @"PTPPropertyCodeNikonMaximumShots";
      case PTPPropertyCodeNikonExposureDelayMode: return @"PTPPropertyCodeNikonExposureDelayMode";
      case PTPPropertyCodeNikonLongExposureNoiseReduction: return @"PTPPropertyCodeNikonLongExposureNoiseReduction";
      case PTPPropertyCodeNikonFileNumberSequence: return @"PTPPropertyCodeNikonFileNumberSequence";
      case PTPPropertyCodeNikonControlPanelFinderRearControl: return @"PTPPropertyCodeNikonControlPanelFinderRearControl";
      case PTPPropertyCodeNikonControlPanelFinderViewfinder: return @"PTPPropertyCodeNikonControlPanelFinderViewfinder";
      case PTPPropertyCodeNikonIllumination: return @"PTPPropertyCodeNikonIllumination";
      case PTPPropertyCodeNikonNrHighISO: return @"PTPPropertyCodeNikonNrHighISO";
      case PTPPropertyCodeNikonSHSETCHGUIDDISP: return @"PTPPropertyCodeNikonSHSETCHGUIDDISP";
      case PTPPropertyCodeNikonArtistName: return @"PTPPropertyCodeNikonArtistName";
      case PTPPropertyCodeNikonCopyrightInfo: return @"PTPPropertyCodeNikonCopyrightInfo";
      case PTPPropertyCodeNikonFlashSyncSpeed: return @"PTPPropertyCodeNikonFlashSyncSpeed";
      case PTPPropertyCodeNikonFlashShutterSpeed: return @"PTPPropertyCodeNikonFlashShutterSpeed";
      case PTPPropertyCodeNikonAAFlashMode: return @"PTPPropertyCodeNikonAAFlashMode";
      case PTPPropertyCodeNikonModelingFlash: return @"PTPPropertyCodeNikonModelingFlash";
      case PTPPropertyCodeNikonBracketSet: return @"PTPPropertyCodeNikonBracketSet";
      case PTPPropertyCodeNikonManualModeBracketing: return @"PTPPropertyCodeNikonManualModeBracketing";
      case PTPPropertyCodeNikonBracketOrder: return @"PTPPropertyCodeNikonBracketOrder";
      case PTPPropertyCodeNikonAutoBracketSelection: return @"PTPPropertyCodeNikonAutoBracketSelection";
      case PTPPropertyCodeNikonBracketingSet: return @"PTPPropertyCodeNikonBracketingSet";
      case PTPPropertyCodeNikonCenterButtonShootingMode: return @"PTPPropertyCodeNikonCenterButtonShootingMode";
      case PTPPropertyCodeNikonCenterButtonPlaybackMode: return @"PTPPropertyCodeNikonCenterButtonPlaybackMode";
      case PTPPropertyCodeNikonMultiselector: return @"PTPPropertyCodeNikonFultiselector";
      case PTPPropertyCodeNikonPhotoInfoPlayback: return @"PTPPropertyCodeNikonPhotoInfoPlayback";
      case PTPPropertyCodeNikonAssignFuncButton: return @"PTPPropertyCodeNikonAssignFuncButton";
      case PTPPropertyCodeNikonCustomizeCommDials: return @"PTPPropertyCodeNikonCustomizeCommDials";
      case PTPPropertyCodeNikonReverseCommandDial: return @"PTPPropertyCodeNikonReverseCommandDial";
      case PTPPropertyCodeNikonApertureSetting: return @"PTPPropertyCodeNikonApertureSetting";
      case PTPPropertyCodeNikonMenusAndPlayback: return @"PTPPropertyCodeNikonMenusAndPlayback";
      case PTPPropertyCodeNikonButtonsAndDials: return @"PTPPropertyCodeNikonButtonsAndDials";
      case PTPPropertyCodeNikonNoCFCard: return @"PTPPropertyCodeNikonNoCFCard";
      case PTPPropertyCodeNikonCenterButtonZoomRatio: return @"PTPPropertyCodeNikonCenterButtonZoomRatio";
      case PTPPropertyCodeNikonFunctionButton2: return @"PTPPropertyCodeNikonFunctionButton2";
      case PTPPropertyCodeNikonAFAreaPoint: return @"PTPPropertyCodeNikonAFAreaPoint";
      case PTPPropertyCodeNikonNormalAFOn: return @"PTPPropertyCodeNikonNormalAFOn";
      case PTPPropertyCodeNikonCleanImageSensor: return @"PTPPropertyCodeNikonCleanImageSensor";
      case PTPPropertyCodeNikonImageCommentString: return @"PTPPropertyCodeNikonImageCommentString";
      case PTPPropertyCodeNikonImageCommentEnable: return @"PTPPropertyCodeNikonImageCommentEnable";
      case PTPPropertyCodeNikonImageRotation: return @"PTPPropertyCodeNikonImageRotation";
      case PTPPropertyCodeNikonManualSetLensNo: return @"PTPPropertyCodeNikonManualSetLensNo";
      case PTPPropertyCodeNikonMovScreenSize: return @"PTPPropertyCodeNikonMovScreenSize";
      case PTPPropertyCodeNikonMovVoice: return @"PTPPropertyCodeNikonMovVoice";
      case PTPPropertyCodeNikonMovMicrophone: return @"PTPPropertyCodeNikonMovMicrophone";
      case PTPPropertyCodeNikonMovFileSlot: return @"PTPPropertyCodeNikonMovFileSlot";
      case PTPPropertyCodeNikonMovRecProhibitCondition: return @"PTPPropertyCodeNikonMovRecProhibitCondition";
      case PTPPropertyCodeNikonManualMovieSetting: return @"PTPPropertyCodeNikonManualMovieSetting";
      case PTPPropertyCodeNikonMovHiQuality: return @"PTPPropertyCodeNikonMovHiQuality";
      case PTPPropertyCodeNikonMovMicSensitivity: return @"PTPPropertyCodeNikonMovMicSensitivity";
      case PTPPropertyCodeNikonMovWindNoiceReduction: return @"PTPPropertyCodeNikonMovWindNoiceReduction";
      case PTPPropertyCodeNikonLiveViewScreenDisplaySetting: return @"PTPPropertyCodeNikonLiveViewScreenDisplaySetting";
      case PTPPropertyCodeNikonMonitorOffDelay: return @"PTPPropertyCodeNikonMonitorOffDelay";
      case PTPPropertyCodeNikonBracketing: return @"PTPPropertyCodeNikonBracketing";
      case PTPPropertyCodeNikonAutoExposureBracketStep: return @"PTPPropertyCodeNikonAutoExposureBracketStep";
      case PTPPropertyCodeNikonAutoExposureBracketProgram: return @"PTPPropertyCodeNikonAutoExposureBracketProgram";
      case PTPPropertyCodeNikonAutoExposureBracketCount: return @"PTPPropertyCodeNikonAutoExposureBracketCount";
      case PTPPropertyCodeNikonWhiteBalanceBracketStep: return @"PTPPropertyCodeNikonWhiteBalanceBracketStep";
      case PTPPropertyCodeNikonWhiteBalanceBracketProgram: return @"PTPPropertyCodeNikonWhiteBalanceBracketProgram";
      case PTPPropertyCodeNikonLensID: return @"PTPPropertyCodeNikonLensID";
      case PTPPropertyCodeNikonLensSort: return @"PTPPropertyCodeNikonLensSort";
      case PTPPropertyCodeNikonLensType: return @"PTPPropertyCodeNikonLensType";
      case PTPPropertyCodeNikonFocalLengthMin: return @"PTPPropertyCodeNikonFocalLengthMin";
      case PTPPropertyCodeNikonFocalLengthMax: return @"PTPPropertyCodeNikonFocalLengthMax";
      case PTPPropertyCodeNikonMaxApAtMinFocalLength: return @"PTPPropertyCodeNikonMaxApAtMinFocalLength";
      case PTPPropertyCodeNikonMaxApAtMaxFocalLength: return @"PTPPropertyCodeNikonMaxApAtMaxFocalLength";
      case PTPPropertyCodeNikonFinderISODisp: return @"PTPPropertyCodeNikonFinderISODisp";
      case PTPPropertyCodeNikonAutoOffPhoto: return @"PTPPropertyCodeNikonAutoOffPhoto";
      case PTPPropertyCodeNikonAutoOffMenu: return @"PTPPropertyCodeNikonAutoOffMenu";
      case PTPPropertyCodeNikonAutoOffInfo: return @"PTPPropertyCodeNikonAutoOffInfo";
      case PTPPropertyCodeNikonSelfTimerShootNum: return @"PTPPropertyCodeNikonSelfTimerShootNum";
      case PTPPropertyCodeNikonVignetteCtrl: return @"PTPPropertyCodeNikonVignetteCtrl";
      case PTPPropertyCodeNikonAutoDistortionControl: return @"PTPPropertyCodeNikonAutoDistortionControl";
      case PTPPropertyCodeNikonSceneMode: return @"PTPPropertyCodeNikonSceneMode";
      case PTPPropertyCodeNikonSceneMode2: return @"PTPPropertyCodeNikonSceneMode2";
      case PTPPropertyCodeNikonSelfTimerInterval: return @"PTPPropertyCodeNikonSelfTimerInterval";
      case PTPPropertyCodeNikonExposureTime: return @"PTPPropertyCodeNikonExposureTime";
      case PTPPropertyCodeNikonACPower: return @"PTPPropertyCodeNikonACPower";
      case PTPPropertyCodeNikonWarningStatus: return @"PTPPropertyCodeNikonWarningStatus";
      case PTPPropertyCodeNikonRemainingShots: return @"PTPPropertyCodeNikonRemainingShots";
      case PTPPropertyCodeNikonAFLockStatus: return @"PTPPropertyCodeNikonAFLockStatus";
      case PTPPropertyCodeNikonAELockStatus: return @"PTPPropertyCodeNikonAELockStatus";
      case PTPPropertyCodeNikonFVLockStatus: return @"PTPPropertyCodeNikonFVLockStatus";
      case PTPPropertyCodeNikonAutofocusLCDTopMode2: return @"PTPPropertyCodeNikonAutofocusLCDTopMode2";
      case PTPPropertyCodeNikonAutofocusSensor: return @"PTPPropertyCodeNikonAutofocusSensor";
      case PTPPropertyCodeNikonFlexibleProgram: return @"PTPPropertyCodeNikonFlexibleProgram";
      case PTPPropertyCodeNikonLightMeter: return @"PTPPropertyCodeNikonLightMeter";
      case PTPPropertyCodeNikonSaveMedia: return @"PTPPropertyCodeNikonSaveMedia";
      case PTPPropertyCodeNikonUSBSpeed: return @"PTPPropertyCodeNikonUSBSpeed";
      case PTPPropertyCodeNikonCCDNumber: return @"PTPPropertyCodeNikonCCDNumber";
      case PTPPropertyCodeNikonCameraInclination: return @"PTPPropertyCodeNikonCameraInclination";
      case PTPPropertyCodeNikonGroupPtnType: return @"PTPPropertyCodeNikonGroupPtnType";
      case PTPPropertyCodeNikonFNumberLock: return @"PTPPropertyCodeNikonFNumberLock";
      case PTPPropertyCodeNikonExposureApertureLock: return @"PTPPropertyCodeNikonExposureApertureLock";
      case PTPPropertyCodeNikonTVLockSetting: return @"PTPPropertyCodeNikonTVLockSetting";
      case PTPPropertyCodeNikonAVLockSetting: return @"PTPPropertyCodeNikonAVLockSetting";
      case PTPPropertyCodeNikonIllumSetting: return @"PTPPropertyCodeNikonIllumSetting";
      case PTPPropertyCodeNikonFocusPointBright: return @"PTPPropertyCodeNikonFocusPointBright";
      case PTPPropertyCodeNikonExternalFlashAttached: return @"PTPPropertyCodeNikonExternalFlashAttached";
      case PTPPropertyCodeNikonExternalFlashStatus: return @"PTPPropertyCodeNikonExternalFlashStatus";
      case PTPPropertyCodeNikonExternalFlashSort: return @"PTPPropertyCodeNikonExternalFlashSort";
      case PTPPropertyCodeNikonExternalFlashMode: return @"PTPPropertyCodeNikonExternalFlashMode";
      case PTPPropertyCodeNikonExternalFlashCompensation: return @"PTPPropertyCodeNikonExternalFlashCompensation";
      case PTPPropertyCodeNikonNewExternalFlashMode: return @"PTPPropertyCodeNikonNewExternalFlashMode";
      case PTPPropertyCodeNikonFlashExposureCompensation: return @"PTPPropertyCodeNikonFlashExposureCompensation";
      case PTPPropertyCodeNikonHDRMode: return @"PTPPropertyCodeNikonHDRMode";
      case PTPPropertyCodeNikonHDRHighDynamic: return @"PTPPropertyCodeNikonHDRHighDynamic";
      case PTPPropertyCodeNikonHDRSmoothing: return @"PTPPropertyCodeNikonHDRSmoothing";
      case PTPPropertyCodeNikonOptimizeImage: return @"PTPPropertyCodeNikonOptimizeImage";
      case PTPPropertyCodeNikonSaturation: return @"PTPPropertyCodeNikonSaturation";
      case PTPPropertyCodeNikonBWFillerEffect: return @"PTPPropertyCodeNikonBWFillerEffect";
      case PTPPropertyCodeNikonBWSharpness: return @"PTPPropertyCodeNikonBWSharpness";
      case PTPPropertyCodeNikonBWContrast: return @"PTPPropertyCodeNikonBWContrast";
      case PTPPropertyCodeNikonBWSettingType: return @"PTPPropertyCodeNikonBWSettingType";
      case PTPPropertyCodeNikonSlot2SaveMode: return @"PTPPropertyCodeNikonSlot2SaveMode";
      case PTPPropertyCodeNikonRawBitMode: return @"PTPPropertyCodeNikonRawBitMode";
      case PTPPropertyCodeNikonActiveDLighting: return @"PTPPropertyCodeNikonActiveDLighting";
      case PTPPropertyCodeNikonFlourescentType: return @"PTPPropertyCodeNikonFlourescentType";
      case PTPPropertyCodeNikonTuneColourTemperature: return @"PTPPropertyCodeNikonTuneColourTemperature";
      case PTPPropertyCodeNikonTunePreset0: return @"PTPPropertyCodeNikonTunePreset0";
      case PTPPropertyCodeNikonTunePreset1: return @"PTPPropertyCodeNikonTunePreset1";
      case PTPPropertyCodeNikonTunePreset2: return @"PTPPropertyCodeNikonTunePreset2";
      case PTPPropertyCodeNikonTunePreset3: return @"PTPPropertyCodeNikonTunePreset3";
      case PTPPropertyCodeNikonTunePreset4: return @"PTPPropertyCodeNikonTunePreset4";
      case PTPPropertyCodeNikonBeepOff: return @"PTPPropertyCodeNikonBeepOff";
      case PTPPropertyCodeNikonAutofocusMode: return @"PTPPropertyCodeNikonAutofocusMode";
      case PTPPropertyCodeNikonAFAssist: return @"PTPPropertyCodeNikonAFAssist";
      case PTPPropertyCodeNikonPADVPMode: return @"PTPPropertyCodeNikonPADVPMode";
      case PTPPropertyCodeNikonImageReview: return @"PTPPropertyCodeNikonImageReview";
      case PTPPropertyCodeNikonAFAreaIllumination: return @"PTPPropertyCodeNikonAFAreaIllumination";
      case PTPPropertyCodeNikonFlashMode: return @"PTPPropertyCodeNikonFlashMode";
      case PTPPropertyCodeNikonFlashCommanderMode: return @"PTPPropertyCodeNikonFlashCommanderMode";
      case PTPPropertyCodeNikonFlashSign: return @"PTPPropertyCodeNikonFlashSign";
      case PTPPropertyCodeNikonISOAuto: return @"PTPPropertyCodeNikonISOAuto";
      case PTPPropertyCodeNikonRemoteTimeout: return @"PTPPropertyCodeNikonRemoteTimeout";
      case PTPPropertyCodeNikonGridDisplay: return @"PTPPropertyCodeNikonGridDisplay";
      case PTPPropertyCodeNikonFlashModeManualPower: return @"PTPPropertyCodeNikonFlashModeManualPower";
      case PTPPropertyCodeNikonFlashModeCommanderPower: return @"PTPPropertyCodeNikonFlashModeCommanderPower";
      case PTPPropertyCodeNikonAutoFP: return @"PTPPropertyCodeNikonAutoFP";
      case PTPPropertyCodeNikonDateImprintSetting: return @"PTPPropertyCodeNikonDateImprintSetting";
      case PTPPropertyCodeNikonDateCounterSelect: return @"PTPPropertyCodeNikonDateCounterSelect";
      case PTPPropertyCodeNikonDateCountData: return @"PTPPropertyCodeNikonDateCountData";
      case PTPPropertyCodeNikonDateCountDisplaySetting: return @"PTPPropertyCodeNikonDateCountDisplaySetting";
      case PTPPropertyCodeNikonRangeFinderSetting: return @"PTPPropertyCodeNikonRangeFinderSetting";
      case PTPPropertyCodeNikonCSMMenu: return @"PTPPropertyCodeNikonCSMMenu";
      case PTPPropertyCodeNikonWarningDisplay: return @"PTPPropertyCodeNikonWarningDisplay";
      case PTPPropertyCodeNikonBatteryCellKind: return @"PTPPropertyCodeNikonBatteryCellKind";
      case PTPPropertyCodeNikonISOAutoHiLimit: return @"PTPPropertyCodeNikonISOAutoHiLimit";
      case PTPPropertyCodeNikonDynamicAFArea: return @"PTPPropertyCodeNikonDynamicAFArea";
      case PTPPropertyCodeNikonContinuousSpeedHigh: return @"PTPPropertyCodeNikonContinuousSpeedHigh";
      case PTPPropertyCodeNikonInfoDispSetting: return @"PTPPropertyCodeNikonInfoDispSetting";
      case PTPPropertyCodeNikonPreviewButton: return @"PTPPropertyCodeNikonPreviewButton";
      case PTPPropertyCodeNikonPreviewButton2: return @"PTPPropertyCodeNikonPreviewButton2";
      case PTPPropertyCodeNikonAEAFLockButton2: return @"PTPPropertyCodeNikonAEAFLockButton2";
      case PTPPropertyCodeNikonIndicatorDisp: return @"PTPPropertyCodeNikonIndicatorDisp";
      case PTPPropertyCodeNikonCellKindPriority: return @"PTPPropertyCodeNikonCellKindPriority";
      case PTPPropertyCodeNikonBracketingFramesAndSteps: return @"PTPPropertyCodeNikonBracketingFramesAndSteps";
      case PTPPropertyCodeNikonLiveViewMode: return @"PTPPropertyCodeNikonLiveViewMode";
      case PTPPropertyCodeNikonLiveViewDriveMode: return @"PTPPropertyCodeNikonLiveViewDriveMode";
      case PTPPropertyCodeNikonLiveViewStatus: return @"PTPPropertyCodeNikonLiveViewStatus";
      case PTPPropertyCodeNikonLiveViewImageZoomRatio: return @"PTPPropertyCodeNikonLiveViewImageZoomRatio";
      case PTPPropertyCodeNikonLiveViewProhibitCondition: return @"PTPPropertyCodeNikonLiveViewProhibitCondition";
      case PTPPropertyCodeNikonMovieShutterSpeed: return @"PTPPropertyCodeNikonMovieShutterSpeed";
      case PTPPropertyCodeNikonMovieFNumber: return @"PTPPropertyCodeNikonMovieFNumber";
      case PTPPropertyCodeNikonMovieISO: return @"PTPPropertyCodeNikonMovieISO";
      case PTPPropertyCodeNikonLiveViewImageSize: return @"PTPPropertyCodeNikonLiveViewImageSize";
      case PTPPropertyCodeNikonBlinkingStatus: return @"PTPPropertyCodeNikonBlinkingStatus";
      case PTPPropertyCodeNikonExposureIndicateStatus: return @"PTPPropertyCodeNikonExposureIndicateStatus";
      case PTPPropertyCodeNikonInfoDispErrStatus: return @"PTPPropertyCodeNikonInfoDispErrStatus";
      case PTPPropertyCodeNikonExposureIndicateLightup: return @"PTPPropertyCodeNikonExposureIndicateLightup";
      case PTPPropertyCodeNikonFlashOpen: return @"PTPPropertyCodeNikonFlashOpen";
      case PTPPropertyCodeNikonFlashCharged: return @"PTPPropertyCodeNikonFlashCharged";
      case PTPPropertyCodeNikonFlashMRepeatValue: return @"PTPPropertyCodeNikonFlashMRepeatValue";
      case PTPPropertyCodeNikonFlashMRepeatCount: return @"PTPPropertyCodeNikonFlashMRepeatCount";
      case PTPPropertyCodeNikonFlashMRepeatInterval: return @"PTPPropertyCodeNikonFlashMRepeatInterval";
      case PTPPropertyCodeNikonFlashCommandChannel: return @"PTPPropertyCodeNikonFlashCommandChannel";
      case PTPPropertyCodeNikonFlashCommandSelfMode: return @"PTPPropertyCodeNikonFlashCommandSelfMode";
      case PTPPropertyCodeNikonFlashCommandSelfCompensation: return @"PTPPropertyCodeNikonFlashCommandSelfCompensation";
      case PTPPropertyCodeNikonFlashCommandSelfValue: return @"PTPPropertyCodeNikonFlashCommandSelfValue";
      case PTPPropertyCodeNikonFlashCommandAMode: return @"PTPPropertyCodeNikonFlashCommandAMode";
      case PTPPropertyCodeNikonFlashCommandACompensation: return @"PTPPropertyCodeNikonFlashCommandACompensation";
      case PTPPropertyCodeNikonFlashCommandAValue: return @"PTPPropertyCodeNikonFlashCommandAValue";
      case PTPPropertyCodeNikonFlashCommandBMode: return @"PTPPropertyCodeNikonFlashCommandBMode";
      case PTPPropertyCodeNikonFlashCommandBCompensation: return @"PTPPropertyCodeNikonFlashCommandBCompensation";
      case PTPPropertyCodeNikonFlashCommandBValue: return @"PTPPropertyCodeNikonFlashCommandBValue";
      case PTPPropertyCodeNikonApplicationMode: return @"PTPPropertyCodeNikonApplicationMode";
      case PTPPropertyCodeNikonActiveSlot: return @"PTPPropertyCodeNikonActiveSlot";
      case PTPPropertyCodeNikonActivePicCtrlItem: return @"PTPPropertyCodeNikonActivePicCtrlItem";
      case PTPPropertyCodeNikonChangePicCtrlItem: return @"PTPPropertyCodeNikonChangePicCtrlItem";
      case PTPPropertyCodeNikonMovieNrHighISO: return @"PTPPropertyCodeNikonMovieNrHighISO";
    }
  }
  if (vendorExtension == PTPVendorExtensionCanon) {
    switch (propertyCode) {
      case PTPPropertyCodeCanonAperture: return @"PTPPropertyCodeCanonAperture";
      case PTPPropertyCodeCanonShutterSpeed: return @"PTPPropertyCodeCanonShutterSpeed";
      case PTPPropertyCodeCanonISOSpeed: return @"PTPPropertyCodeCanonISOSpeed";
      case PTPPropertyCodeCanonExpCompensation: return @"PTPPropertyCodeCanonExpCompensation";
      case PTPPropertyCodeCanonAutoExposureMode: return @"PTPPropertyCodeCanonAutoExposureMode";
      case PTPPropertyCodeCanonDriveMode: return @"PTPPropertyCodeCanonDriveMode";
      case PTPPropertyCodeCanonMeteringMode: return @"PTPPropertyCodeCanonMeteringMode";
      case PTPPropertyCodeCanonFocusMode: return @"PTPPropertyCodeCanonFocusMode";
      case PTPPropertyCodeCanonWhiteBalance: return @"PTPPropertyCodeCanonWhiteBalance";
      case PTPPropertyCodeCanonColorTemperature: return @"PTPPropertyCodeCanonColorTemperature";
      case PTPPropertyCodeCanonWhiteBalanceAdjustA: return @"PTPPropertyCodeCanonWhiteBalanceAdjustA";
      case PTPPropertyCodeCanonWhiteBalanceAdjustB: return @"PTPPropertyCodeCanonWhiteBalanceAdjustB";
      case PTPPropertyCodeCanonWhiteBalanceXA: return @"PTPPropertyCodeCanonWhiteBalanceXA";
      case PTPPropertyCodeCanonWhiteBalanceXB: return @"PTPPropertyCodeCanonWhiteBalanceXB";
      case PTPPropertyCodeCanonColorSpace: return @"PTPPropertyCodeCanonColorSpace";
      case PTPPropertyCodeCanonPictureStyle: return @"PTPPropertyCodeCanonPictureStyle";
      case PTPPropertyCodeCanonBatteryPower: return @"PTPPropertyCodeCanonBatteryPower";
      case PTPPropertyCodeCanonBatterySelect: return @"PTPPropertyCodeCanonBatterySelect";
      case PTPPropertyCodeCanonCameraTime: return @"PTPPropertyCodeCanonCameraTime";
      case PTPPropertyCodeCanonAutoPowerOff: return @"PTPPropertyCodeCanonAutoPowerOff";
      case PTPPropertyCodeCanonOwner: return @"PTPPropertyCodeCanonOwner";
      case PTPPropertyCodeCanonModelID: return @"PTPPropertyCodeCanonModelID";
      case PTPPropertyCodeCanonPTPExtensionVersion: return @"PTPPropertyCodeCanonPTPExtensionVersion";
      case PTPPropertyCodeCanonDPOFVersion: return @"PTPPropertyCodeCanonDPOFVersion";
      case PTPPropertyCodeCanonAvailableShots: return @"PTPPropertyCodeCanonAvailableShots";
      case PTPPropertyCodeCanonCaptureDestination: return @"PTPPropertyCodeCanonCaptureDestination";
      case PTPPropertyCodeCanonBracketMode: return @"PTPPropertyCodeCanonBracketMode";
      case PTPPropertyCodeCanonCurrentStorage: return @"PTPPropertyCodeCanonCurrentStorage";
      case PTPPropertyCodeCanonCurrentFolder: return @"PTPPropertyCodeCanonCurrentFolder";
      case PTPPropertyCodeCanonImageFormat: return @"PTPPropertyCodeCanonImageFormat";
      case PTPPropertyCodeCanonImageFormatCF: return @"PTPPropertyCodeCanonImageFormatCF";
      case PTPPropertyCodeCanonImageFormatSD: return @"PTPPropertyCodeCanonImageFormatSD";
      case PTPPropertyCodeCanonImageFormatExtHD: return @"PTPPropertyCodeCanonImageFormatExtHD";
      case PTPPropertyCodeCanonCompressionS: return @"PTPPropertyCodeCanonCompressionS";
      case PTPPropertyCodeCanonCompressionM1: return @"PTPPropertyCodeCanonCompressionM1";
      case PTPPropertyCodeCanonCompressionM2: return @"PTPPropertyCodeCanonCompressionM2";
      case PTPPropertyCodeCanonCompressionL: return @"PTPPropertyCodeCanonCompressionL";
      case PTPPropertyCodeCanonAEModeDial: return @"PTPPropertyCodeCanonAEModeDial";
      case PTPPropertyCodeCanonAEModeCustom: return @"PTPPropertyCodeCanonAEModeCustom";
      case PTPPropertyCodeCanonMirrorUpSetting: return @"PTPPropertyCodeCanonMirrorUpSetting";
      case PTPPropertyCodeCanonHighlightTonePriority: return @"PTPPropertyCodeCanonHighlightTonePriority";
      case PTPPropertyCodeCanonAFSelectFocusArea: return @"PTPPropertyCodeCanonAFSelectFocusArea";
      case PTPPropertyCodeCanonHDRSetting: return @"PTPPropertyCodeCanonHDRSetting";
      case PTPPropertyCodeCanonPCWhiteBalance1: return @"PTPPropertyCodeCanonPCWhiteBalance1";
      case PTPPropertyCodeCanonPCWhiteBalance2: return @"PTPPropertyCodeCanonPCWhiteBalance2";
      case PTPPropertyCodeCanonPCWhiteBalance3: return @"PTPPropertyCodeCanonPCWhiteBalance3";
      case PTPPropertyCodeCanonPCWhiteBalance4: return @"PTPPropertyCodeCanonPCWhiteBalance4";
      case PTPPropertyCodeCanonPCWhiteBalance5: return @"PTPPropertyCodeCanonPCWhiteBalance5";
      case PTPPropertyCodeCanonMWhiteBalance: return @"PTPPropertyCodeCanonMWhiteBalance";
      case PTPPropertyCodeCanonMWhiteBalanceEx: return @"PTPPropertyCodeCanonMWhiteBalanceEx";
      case PTPPropertyCodeCanonUnknownPropD14D: return @"PTPPropertyCodeCanonUnknownPropD14D";
      case PTPPropertyCodeCanonPictureStyleStandard: return @"PTPPropertyCodeCanonPictureStyleStandard";
      case PTPPropertyCodeCanonPictureStylePortrait: return @"PTPPropertyCodeCanonPictureStylePortrait";
      case PTPPropertyCodeCanonPictureStyleLandscape: return @"PTPPropertyCodeCanonPictureStyleLandscape";
      case PTPPropertyCodeCanonPictureStyleNeutral: return @"PTPPropertyCodeCanonPictureStyleNeutral";
      case PTPPropertyCodeCanonPictureStyleFaithful: return @"PTPPropertyCodeCanonPictureStyleFaithful";
      case PTPPropertyCodeCanonPictureStyleBlackWhite: return @"PTPPropertyCodeCanonPictureStyleBlackWhite";
      case PTPPropertyCodeCanonPictureStyleAuto: return @"PTPPropertyCodeCanonPictureStyleAuto";
      case PTPPropertyCodeCanonPictureStyleUserSet1: return @"PTPPropertyCodeCanonPictureStyleUserSet1";
      case PTPPropertyCodeCanonPictureStyleUserSet2: return @"PTPPropertyCodeCanonPictureStyleUserSet2";
      case PTPPropertyCodeCanonPictureStyleUserSet3: return @"PTPPropertyCodeCanonPictureStyleUserSet3";
      case PTPPropertyCodeCanonPictureStyleParam1: return @"PTPPropertyCodeCanonPictureStyleParam1";
      case PTPPropertyCodeCanonPictureStyleParam2: return @"PTPPropertyCodeCanonPictureStyleParam2";
      case PTPPropertyCodeCanonPictureStyleParam3: return @"PTPPropertyCodeCanonPictureStyleParam3";
      case PTPPropertyCodeCanonHighISOSettingNoiseReduction: return @"PTPPropertyCodeCanonHighISOSettingNoiseReduction";
      case PTPPropertyCodeCanonMovieServoAF: return @"PTPPropertyCodeCanonMovieServoAF";
      case PTPPropertyCodeCanonContinuousAFValid: return @"PTPPropertyCodeCanonContinuousAFValid";
      case PTPPropertyCodeCanonAttenuator: return @"PTPPropertyCodeCanonAttenuator";
      case PTPPropertyCodeCanonUTCTime: return @"PTPPropertyCodeCanonUTCTime";
      case PTPPropertyCodeCanonTimezone: return @"PTPPropertyCodeCanonTimezone";
      case PTPPropertyCodeCanonSummertime: return @"PTPPropertyCodeCanonSummertime";
      case PTPPropertyCodeCanonFlavorLUTParams: return @"PTPPropertyCodeCanonFlavorLUTParams";
      case PTPPropertyCodeCanonCustomFunc1: return @"PTPPropertyCodeCanonCustomFunc1";
      case PTPPropertyCodeCanonCustomFunc2: return @"PTPPropertyCodeCanonCustomFunc2";
      case PTPPropertyCodeCanonCustomFunc3: return @"PTPPropertyCodeCanonCustomFunc3";
      case PTPPropertyCodeCanonCustomFunc4: return @"PTPPropertyCodeCanonCustomFunc4";
      case PTPPropertyCodeCanonCustomFunc5: return @"PTPPropertyCodeCanonCustomFunc5";
      case PTPPropertyCodeCanonCustomFunc6: return @"PTPPropertyCodeCanonCustomFunc6";
      case PTPPropertyCodeCanonCustomFunc7: return @"PTPPropertyCodeCanonCustomFunc7";
      case PTPPropertyCodeCanonCustomFunc8: return @"PTPPropertyCodeCanonCustomFunc8";
      case PTPPropertyCodeCanonCustomFunc9: return @"PTPPropertyCodeCanonCustomFunc9";
      case PTPPropertyCodeCanonCustomFunc10: return @"PTPPropertyCodeCanonCustomFunc10";
      case PTPPropertyCodeCanonCustomFunc11: return @"PTPPropertyCodeCanonCustomFunc11";
      case PTPPropertyCodeCanonCustomFunc12: return @"PTPPropertyCodeCanonCustomFunc12";
      case PTPPropertyCodeCanonCustomFunc13: return @"PTPPropertyCodeCanonCustomFunc13";
      case PTPPropertyCodeCanonCustomFunc14: return @"PTPPropertyCodeCanonCustomFunc14";
      case PTPPropertyCodeCanonCustomFunc15: return @"PTPPropertyCodeCanonCustomFunc15";
      case PTPPropertyCodeCanonCustomFunc16: return @"PTPPropertyCodeCanonCustomFunc16";
      case PTPPropertyCodeCanonCustomFunc17: return @"PTPPropertyCodeCanonCustomFunc17";
      case PTPPropertyCodeCanonCustomFunc18: return @"PTPPropertyCodeCanonCustomFunc18";
      case PTPPropertyCodeCanonCustomFunc19: return @"PTPPropertyCodeCanonCustomFunc19";
      case PTPPropertyCodeCanonInnerDevelop: return @"PTPPropertyCodeCanonInnerDevelop";
      case PTPPropertyCodeCanonMultiAspect: return @"PTPPropertyCodeCanonMultiAspect";
      case PTPPropertyCodeCanonMovieSoundRecord: return @"PTPPropertyCodeCanonMovieSoundRecord";
      case PTPPropertyCodeCanonMovieRecordVolume: return @"PTPPropertyCodeCanonMovieRecordVolume";
      case PTPPropertyCodeCanonWindCut: return @"PTPPropertyCodeCanonWindCut";
      case PTPPropertyCodeCanonExtenderType: return @"PTPPropertyCodeCanonExtenderType";
      case PTPPropertyCodeCanonOLCInfoVersion: return @"PTPPropertyCodeCanonOLCInfoVersion";
      case PTPPropertyCodeCanonUnknownPropD19A: return @"PTPPropertyCodeCanonUnknownPropD19A";
      case PTPPropertyCodeCanonUnknownPropD19C: return @"PTPPropertyCodeCanonUnknownPropD19C";
      case PTPPropertyCodeCanonUnknownPropD19D: return @"PTPPropertyCodeCanonUnknownPropD19D";
      case PTPPropertyCodeCanonCustomFuncEx: return @"PTPPropertyCodeCanonCustomFuncEx";
      case PTPPropertyCodeCanonMyMenu: return @"PTPPropertyCodeCanonMyMenu";
      case PTPPropertyCodeCanonMyMenuList: return @"PTPPropertyCodeCanonMyMenuList";
      case PTPPropertyCodeCanonWftStatus: return @"PTPPropertyCodeCanonWftStatus";
      case PTPPropertyCodeCanonWftInputTransmission: return @"PTPPropertyCodeCanonWftInputTransmission";
      case PTPPropertyCodeCanonHDDirectoryStructure: return @"PTPPropertyCodeCanonHDDirectoryStructure";
      case PTPPropertyCodeCanonBatteryInfo: return @"PTPPropertyCodeCanonBatteryInfo";
      case PTPPropertyCodeCanonAdapterInfo: return @"PTPPropertyCodeCanonAdapterInfo";
      case PTPPropertyCodeCanonLensStatus: return @"PTPPropertyCodeCanonLensStatus";
      case PTPPropertyCodeCanonQuickReviewTime: return @"PTPPropertyCodeCanonQuickReviewTime";
      case PTPPropertyCodeCanonCardExtension: return @"PTPPropertyCodeCanonCardExtension";
      case PTPPropertyCodeCanonTempStatus: return @"PTPPropertyCodeCanonTempStatus";
      case PTPPropertyCodeCanonShutterCounter: return @"PTPPropertyCodeCanonShutterCounter";
      case PTPPropertyCodeCanonSpecialOption: return @"PTPPropertyCodeCanonSpecialOption";
      case PTPPropertyCodeCanonPhotoStudioMode: return @"PTPPropertyCodeCanonPhotoStudioMode";
      case PTPPropertyCodeCanonSerialNumber: return @"PTPPropertyCodeCanonSerialNumber";
      case PTPPropertyCodeCanonEVFOutputDevice: return @"PTPPropertyCodeCanonEVFOutputDevice";
      case PTPPropertyCodeCanonEVFMode: return @"PTPPropertyCodeCanonEVFMode";
      case PTPPropertyCodeCanonDepthOfFieldPreview: return @"PTPPropertyCodeCanonDepthOfFieldPreview";
      case PTPPropertyCodeCanonEVFSharpness: return @"PTPPropertyCodeCanonEVFSharpness";
      case PTPPropertyCodeCanonEVFWBMode: return @"PTPPropertyCodeCanonEVFWBMode";
      case PTPPropertyCodeCanonEVFClickWBCoeffs: return @"PTPPropertyCodeCanonEVFClickWBCoeffs";
      case PTPPropertyCodeCanonEVFColorTemp: return @"PTPPropertyCodeCanonEVFColorTemp";
      case PTPPropertyCodeCanonExposureSimMode: return @"PTPPropertyCodeCanonExposureSimMode";
      case PTPPropertyCodeCanonEVFRecordStatus: return @"PTPPropertyCodeCanonEVFRecordStatus";
      case PTPPropertyCodeCanonLvAfSystem: return @"PTPPropertyCodeCanonLvAfSystem";
      case PTPPropertyCodeCanonMovSize: return @"PTPPropertyCodeCanonMovSize";
      case PTPPropertyCodeCanonLvViewTypeSelect: return @"PTPPropertyCodeCanonLvViewTypeSelect";
      case PTPPropertyCodeCanonMirrorDownStatus: return @"PTPPropertyCodeCanonMirrorDownStatus";
      case PTPPropertyCodeCanonMovieParam: return @"PTPPropertyCodeCanonMovieParam";
      case PTPPropertyCodeCanonMirrorLockupState: return @"PTPPropertyCodeCanonMirrorLockupState";
      case PTPPropertyCodeCanonFlashChargingState: return @"PTPPropertyCodeCanonFlashChargingState";
      case PTPPropertyCodeCanonAloMode: return @"PTPPropertyCodeCanonAloMode";
      case PTPPropertyCodeCanonFixedMovie: return @"PTPPropertyCodeCanonFixedMovie";
      case PTPPropertyCodeCanonOneShotRawOn: return @"PTPPropertyCodeCanonOneShotRawOn";
      case PTPPropertyCodeCanonErrorForDisplay: return @"PTPPropertyCodeCanonErrorForDisplay";
      case PTPPropertyCodeCanonAEModeMovie: return @"PTPPropertyCodeCanonAEModeMovie";
      case PTPPropertyCodeCanonBuiltinStroboMode: return @"PTPPropertyCodeCanonBuiltinStroboMode";
      case PTPPropertyCodeCanonStroboDispState: return @"PTPPropertyCodeCanonStroboDispState";
      case PTPPropertyCodeCanonStroboETTL2Metering: return @"PTPPropertyCodeCanonStroboETTL2Metering";
      case PTPPropertyCodeCanonContinousAFMode: return @"PTPPropertyCodeCanonContinousAFMode";
      case PTPPropertyCodeCanonMovieParam2: return @"PTPPropertyCodeCanonMovieParam2";
      case PTPPropertyCodeCanonStroboSettingExpComposition: return @"PTPPropertyCodeCanonStroboSettingExpComposition";
      case PTPPropertyCodeCanonMovieParam3: return @"PTPPropertyCodeCanonMovieParam3";
      case PTPPropertyCodeCanonLVMedicalRotate: return @"PTPPropertyCodeCanonLVMedicalRotate";
      case PTPPropertyCodeCanonArtist: return @"PTPPropertyCodeCanonArtist";
      case PTPPropertyCodeCanonCopyright: return @"PTPPropertyCodeCanonCopyright";
      case PTPPropertyCodeCanonBracketValue: return @"PTPPropertyCodeCanonBracketValue";
      case PTPPropertyCodeCanonFocusInfoEx: return @"PTPPropertyCodeCanonFocusInfoEx";
      case PTPPropertyCodeCanonDepthOfField: return @"PTPPropertyCodeCanonDepthOfField";
      case PTPPropertyCodeCanonBrightness: return @"PTPPropertyCodeCanonBrightness";
      case PTPPropertyCodeCanonLensAdjustParams: return @"PTPPropertyCodeCanonLensAdjustParams";
      case PTPPropertyCodeCanonEFComp: return @"PTPPropertyCodeCanonEFComp";
      case PTPPropertyCodeCanonLensName: return @"PTPPropertyCodeCanonLensName";
      case PTPPropertyCodeCanonAEB: return @"PTPPropertyCodeCanonAEB";
      case PTPPropertyCodeCanonStroboSetting: return @"PTPPropertyCodeCanonStroboSetting";
      case PTPPropertyCodeCanonStroboWirelessSetting: return @"PTPPropertyCodeCanonStroboWirelessSetting";
      case PTPPropertyCodeCanonStroboFiring: return @"PTPPropertyCodeCanonStroboFiring";
      case PTPPropertyCodeCanonLensID: return @"PTPPropertyCodeCanonLensID";
      case PTPPropertyCodeCanonLCDBrightness: return @"PTPPropertyCodeCanonLCDBrightness";
      case PTPPropertyCodeCanonCADarkBright: return @"PTPPropertyCodeCanonCADarkBright";
    }
  }
  return [NSString stringWithFormat:@"PTPPropertyCode0x%04x", propertyCode];
}

+ (NSString *)typeName:(PTPDataTypeCode)type {
  switch (type) {
    case PTPDataTypeCodeUndefined: return @"PTPDataTypeCodeUndefined";
    case PTPDataTypeCodeSInt8: return @"PTPDataTypeCodeSInt8";
    case PTPDataTypeCodeUInt8: return @"PTPDataTypeCodeUInt8";
    case PTPDataTypeCodeSInt16: return @"PTPDataTypeCodeSInt16";
    case PTPDataTypeCodeUInt16: return @"PTPDataTypeCodeUInt16";
    case PTPDataTypeCodeSInt32: return @"PTPDataTypeCodeSInt32";
    case PTPDataTypeCodeUInt32: return @"PTPDataTypeCodeUInt32";
    case PTPDataTypeCodeSInt64: return @"PTPDataTypeCodeSInt64";
    case PTPDataTypeCodeUInt64: return @"PTPDataTypeCodeUInt64";
    case PTPDataTypeCodeSInt128: return @"PTPDataTypeCodeSInt128";
    case PTPDataTypeCodeUInt128: return @"PTPDataTypeCodeUInt128";
    case PTPDataTypeCodeArrayOfSInt8: return @"PTPDataTypeCodeArrayOfSInt8";
    case PTPDataTypeCodeArrayOfUInt8: return @"PTPDataTypeCodeArrayOfUInt8";
    case PTPDataTypeCodeArrayOfSInt16: return @"PTPDataTypeCodeArrayOfSInt16";
    case PTPDataTypeCodeArrayOfUInt16: return @"PTPDataTypeCodeArrayOfUInt16";
    case PTPDataTypeCodeArrayOfSInt32: return @"PTPDataTypeCodeArrayOfSInt32";
    case PTPDataTypeCodeArrayOfUInt32: return @"PTPDataTypeCodeArrayOfUInt32";
    case PTPDataTypeCodeArrayOfSInt64: return @"PTPDataTypeCodeArrayOfSInt64";
    case PTPDataTypeCodeArrayOfUInt64: return @"PTPDataTypeCodeArrayOfUInt64";
    case PTPDataTypeCodeArrayOfSInt128: return @"PTPDataTypeCodeArrayOfSInt128";
    case PTPDataTypeCodeArrayOfUInt128: return @"PTPDataTypeCodeArrayOfUInt128";
    case PTPDataTypeCodeUnicodeString: return @"PTPDataTypeCodeUnicodeString";
  }
  return [NSString stringWithFormat:@"PTPDataTypeCode0x%04x", type];
}

- (id)initWithCode:(PTPPropertyCode)propertyCode vendorExtension:(PTPVendorExtension)vendorExtension{
  if ((self = [super initWithVendorExtension:vendorExtension])) {
    _propertyCode = propertyCode;
    _type = PTPDataTypeCodeUndefined;
  }
  return self;
}
- (id)initWithData:(NSData*)data  vendorExtension:(PTPVendorExtension)vendorExtension{
  NSUInteger dataLength = [data length];
  if ((data == NULL) || (dataLength < 5))
    return NULL;
  unsigned char* buffer = (unsigned char*)[data bytes];
  if ((self = [super initWithVendorExtension:vendorExtension])) {
    unsigned char* buf = buffer;
    _propertyCode = ptpReadUnsignedShort(&buf);
    _type = ptpReadUnsignedShort(&buf);
    _readOnly = !ptpReadUnsignedChar(&buf);
    _defaultValue = ptpReadValue(_type, &buf);
    if (buf - buffer < dataLength) {
      _value = ptpReadValue(_type, &buf);
      if (buf - buffer < dataLength) {
        int form = ptpReadUnsignedChar(&buf);
        switch (form) {
          case 1: {
            _min = (NSNumber *)ptpReadValue(_type, &buf);
            _max = (NSNumber *)ptpReadValue(_type, &buf);
            _step = (NSNumber *)ptpReadValue(_type, &buf);
            break;
          }
          case 2: {
            int count = ptpReadUnsignedShort(&buf);
            NSMutableArray<NSObject*> *values = [NSMutableArray arrayWithCapacity:count];
            for (int i = 0; i < count; i++)
              [values addObject:ptpReadValue(_type, &buf)];
            _supportedValues = values;
            break;
          }
        }
      }
    }
  }
  return self;
}

- (NSString *)propertyCodeName {
  return [PTPProperty propertyCodeName:_propertyCode vendorExtension:self.vendorExtension];
}

- (NSString *)typeName {
  return [PTPProperty typeName:_type];
}

- (NSString*)description {
	NSMutableString* s = [NSMutableString stringWithFormat:@"%@ %@ %@", self.propertyCodeName, self.typeName, self.readOnly ? @"ro" : @"rw"];
	if (self.min)
		[s appendFormat:@", min = %@", self.min];
	if (self.max)
		[s appendFormat:@", max = %@", self.max];
	if (self.step)
		[s appendFormat:@", step = %@", self.step];
	if (self.supportedValues) {
		[s appendFormat:@", values = [%@", self.supportedValues.firstObject];
		for (int i = 1; i < self.supportedValues.count; i++)
			[s appendFormat:@", %@", [self.supportedValues objectAtIndex:i]];
		[s appendString:@"]"];
	}
	[s appendFormat:@", default = %@", self.defaultValue];
	[s appendFormat:@", value = %@", self.value];
	return s;
}

@end

//--------------------------------------------------------------------------------------------------------------------- PTPDeviceInfo

@implementation PTPDeviceInfo

- (id)initWithData:(NSData*)data {
  NSUInteger dataLength = [data length];
  if ((data == NULL) || (dataLength < 12))
    return NULL;
  self = [super init];
  unsigned char* buffer = (unsigned char*)[data bytes];
  if (self) {
    unsigned char* buf = buffer;
    _standardVersion = ptpReadUnsignedShort(&buf);
    self.vendorExtension = ptpReadUnsignedInt(&buf);
    _vendorExtensionVersion = ptpReadUnsignedShort(&buf);
    _vendorExtensionDesc = ptpReadString(&buf);
    if (buf - buffer >= dataLength)
      return self;
    _functionalMode = ptpReadUnsignedShort(&buf);
    _operationsSupported = ptpReadUnsignedShortArray(&buf);
    if (buf - buffer >= dataLength)
      return self;
    _eventsSupported = ptpReadUnsignedShortArray(&buf);
    if (buf - buffer >= dataLength)
      return self;
    _propertiesSupported = ptpReadUnsignedShortArray(&buf);
    if (buf - buffer >= dataLength)
      return self;
    ptpReadUnsignedShortArray(&buf); // capture formats
    if (buf - buffer >= dataLength)
      return self;
    ptpReadUnsignedShortArray(&buf); // capture formats
    
    if (buf - buffer >= dataLength)
      return self;
    _manufacturer = ptpReadString(&buf);
    
    if (self.vendorExtension == PTPVendorExtensionMicrosoft) {
      if ([_manufacturer containsString:@"Nikon"]) {
        self.vendorExtension = PTPVendorExtensionNikon;
        _vendorExtensionVersion = 100;
        _vendorExtensionDesc = @"Nikon & Microsoft PTP Extensions";
      } else if ([_manufacturer containsString:@"Canon"]) {
        self.vendorExtension = PTPVendorExtensionCanon;
        _vendorExtensionVersion = 100;
        _vendorExtensionDesc = @"Canon & Microsoft PTP Extensions";
      }
    }
    if (buf - buffer >= dataLength)
      return self;
    _model = ptpReadString(&buf);
    if (buf - buffer >= dataLength)
      return self;
    _version = ptpReadString(&buf);
    if (buf - buffer >= dataLength)
      return self;
    _serial = ptpReadString(&buf);
    
    _properties = [NSMutableDictionary dictionary];
  }
  return self;
}

- (NSString *)description {
  if (indigo_get_log_level() >= INDIGO_LOG_DEBUG)
    return [self debug];
  return [NSString stringWithFormat:@"%@ %@, PTP V%.2f + %8@ V%.2f", _model, _version, _standardVersion / 100.0, _vendorExtensionDesc, _vendorExtensionVersion / 100.0];
}

- (NSString *)debug {
  NSMutableString *s = [NSMutableString stringWithFormat:@"%@ %@, PTP V%.2f + %8@ V%.2f\n", _model, _version, _standardVersion / 100.0, _vendorExtensionDesc, _vendorExtensionVersion / 100.0];
  if (_operationsSupported.count > 0) {
    [s appendFormat:@"\nOperations:\n"];
    for (NSNumber *code in _operationsSupported)
      [s appendFormat:@"%@\n", [PTPOperationRequest operationCodeName:code.intValue vendorExtension:self.vendorExtension]];
  }
  if (_eventsSupported.count > 0) {
    [s appendFormat:@"\nEvents:\n"];
    for (NSNumber *code in _eventsSupported)
      [s appendFormat:@"%@\n", [PTPEvent eventCodeName:code.intValue vendorExtension:self.vendorExtension]];
  }
  if (_propertiesSupported.count > 0) {
    [s appendFormat:@"\nProperties:\n"];
    for (NSNumber *code in _propertiesSupported) {
      PTPProperty *property = _properties[code];
      if (property)
        [s appendFormat:@"%@\n", property];
      else
        [s appendFormat:@"%@\n", [PTPProperty propertyCodeName:code.intValue vendorExtension:self.vendorExtension]];
    }
  }
  return s;
}

@end

//------------------------------------------------------------------------------------------------------------------------------

@implementation NSObject(PTPExtensions)

-(int)intValue {
	return self.description.intValue;
}

@end

//------------------------------------------------------------------------------------------------------------------------------

@implementation ICCameraDevice(PTPExtensions)

- (void)checkForEvent {
  PTPDeviceInfo *info = self.ptpDeviceInfo;
  if (info.vendorExtension == PTPVendorExtensionNikon && [info.operationsSupported containsObject:[NSNumber numberWithUnsignedShort:PTPOperationCodeNikonCheckEvent]]) {
    [self sendPTPRequest:PTPOperationCodeNikonCheckEvent];
  }
  if (info.vendorExtension == PTPVendorExtensionCanon && [info.operationsSupported containsObject:[NSNumber numberWithUnsignedShort:PTPOperationCodeCanonGetEvent]]) {
    [self sendPTPRequest:PTPOperationCodeCanonGetEvent];
  }
}

- (void)getLiveViewImage {
	[self sendPTPRequest:PTPOperationCodeNikonGetLiveViewImg];
}

- (void)processEvent:(PTPEvent *)event {
	switch (event.eventCode) {
		case PTPEventCodeDevicePropChanged: {
			[self sendPTPRequest:PTPOperationCodeGetDevicePropDesc param1:event.parameter1];
			break;
		}
    case PTPEventCodeNikonObjectAddedInSDRAM: {
      NSLog(@"Object added to SDRAM");
    }
    case PTPEventCodeObjectAdded: {
      self.userData[PTP_OBJECT_ADDED] = @TRUE;
      break;
    }
    case PTPEventCodeCaptureComplete: {
      if (self.userData[PTP_OBJECT_ADDED] == nil) {
        [(PTPDelegate *)self.delegate cameraExposureFailed:self  message:@"Image data out of sequence"];
      } else {
        [self.userData removeObjectForKey:PTP_OBJECT_ADDED];
      }
    }
  }
}

- (void)didSendPTPCommand:(NSData*)command inData:(NSData*)data response:(NSData*)response error:(NSError*)error contextInfo:(void*)contextInfo {
  PTPOperationRequest*  ptpRequest  = (__bridge PTPOperationRequest*)contextInfo;
  if (response == nil) {
    if (indigo_get_log_level() >= INDIGO_LOG_DEBUG)
      NSLog(@"Completed %@ with error %@", ptpRequest, error);
  }
  PTPDeviceInfo *info = self.ptpDeviceInfo;
  PTPOperationResponse* ptpResponse = [[PTPOperationResponse alloc] initWithData:response vendorExtension:info.vendorExtension];
  if (indigo_get_log_level() >= INDIGO_LOG_DEBUG)
    NSLog(@"Completed %@ with %@", ptpRequest, ptpResponse);
  switch (ptpRequest.operationCode) {
    case PTPOperationCodeGetStorageIDs: {
      if (ptpResponse.responseCode == PTPResponseCodeOK) {
        NSLog(@"Initialized %@\n", info.debug);
        [(PTPDelegate *)self.delegate cameraConnected:self];
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(checkForEvent) userInfo:nil repeats:true];
        self.userData[PTP_EVENT_TIMER] = timer;
      }
      break;
    }
    case PTPOperationCodeSetDevicePropValue: {
      [self sendPTPRequest:PTPOperationCodeGetDevicePropDesc param1:ptpRequest.parameter1];
      break;
    }
    case PTPOperationCodeGetDeviceInfo: {
      if (ptpResponse.responseCode == PTPResponseCodeOK && data) {
        PTPDeviceInfo *info = [[PTPDeviceInfo alloc] initWithData:data];
        self.userData[PTP_DEVICE_INFO] = info;
        if ([info.operationsSupported containsObject:[NSNumber numberWithUnsignedShort:PTPOperationCodeInitiateCapture]]) {
          [(PTPDelegate *)self.delegate cameraCanCapture:self];
        }
        if (info.vendorExtension == PTPVendorExtensionNikon) {
          if ([info.operationsSupported containsObject:[NSNumber numberWithUnsignedShort:PTPOperationCodeNikonMfDrive]]) {
            [(PTPDelegate *)self.delegate cameraCanFocus:self];
          }
          [self sendPTPRequest:PTPOperationCodeNikonGetVendorPropCodes];
        } else if (info.vendorExtension == PTPVendorExtensionCanon) {
          [self sendPTPRequest:PTPOperationCodeCanonGetDeviceInfoEx];
        } else {
          for (NSNumber *code in info.propertiesSupported) {
            [self sendPTPRequest:PTPOperationCodeGetDevicePropDesc param1:code.unsignedShortValue];
          }
          [self sendPTPRequest:PTPOperationCodeGetStorageIDs];
        }
      }
      break;
    }
    case PTPOperationCodeGetDevicePropDesc: {
      PTPProperty *property = [[PTPProperty alloc] initWithData:data vendorExtension:info.vendorExtension];
      if (indigo_get_log_level() >= INDIGO_LOG_DEBUG)
        NSLog(@"Translated to %@", property);
      info.properties[[NSNumber numberWithUnsignedShort:property.propertyCode]] = property;
      switch (property.propertyCode) {
        case PTPPropertyCodeExposureProgramMode: {
          NSDictionary *map = @{ @1: @"Manual", @2: @"Program", @3: @"Aperture priority", @4: @"Shutter priority", @32784: @"Auto", @32785: @"Portrait", @32786: @"Landscape", @32787:@"Macro", @32788: @"Sport", @32789: @"Night portrait", @32790:@"Night landscape", @32791: @"Child", @32792: @"Scene", @32793: @"Effects" };
          NSMutableArray *values = [NSMutableArray array];
          NSMutableArray *labels = [NSMutableArray array];
          for (NSNumber *value in property.supportedValues) {
            [values addObject:value.description];
            NSString *label = map[value];
            if (label)
              [labels addObject:label];
            else
              [labels addObject:[NSString stringWithFormat:@"0x%04x", value.intValue]];
          }
          [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:values labels:labels readOnly:property.readOnly];
          break;
        }
        case PTPPropertyCodeFNumber: {
          NSMutableArray *values = [NSMutableArray array];
          NSMutableArray *labels = [NSMutableArray array];
          for (NSNumber *value in property.supportedValues) {
            [values addObject:value.description];
            [labels addObject:[NSString stringWithFormat:@"f/%g", value.intValue / 100.0]];
          }
          [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:values labels:labels readOnly:property.readOnly];
          break;
        }
        case PTPPropertyCodeExposureTime: {
          NSMutableArray *values = [NSMutableArray array];
          NSMutableArray *labels = [NSMutableArray array];
          for (NSNumber *value in property.supportedValues) {
            int intValue = value.intValue;
            [values addObject:value.description];
            if (intValue == -1)
              [labels addObject:[NSString stringWithFormat:@"Bulb"]];
            else if (intValue == -3)
              [labels addObject:[NSString stringWithFormat:@"Time"]];
            else if (intValue == 1)
              [labels addObject:[NSString stringWithFormat:@"1/8000 s"]];
            else if (intValue == 3)
              [labels addObject:[NSString stringWithFormat:@"1/3200 s"]];
            else if (intValue == 6)
              [labels addObject:[NSString stringWithFormat:@"1/1600 s"]];
            else if (intValue == 12)
              [labels addObject:[NSString stringWithFormat:@"1/800 s"]];
            else if (intValue == 15)
              [labels addObject:[NSString stringWithFormat:@"1/640 s"]];
            else if (intValue == 80)
              [labels addObject:[NSString stringWithFormat:@"1/125 s"]];
            else if (intValue < 100)
              [labels addObject:[NSString stringWithFormat:@"1/%g s", round(1000.0 / value.intValue) * 10]];
            else if (intValue < 10000)
              [labels addObject:[NSString stringWithFormat:@"1/%g s", round(10000.0 / value.intValue)]];
            else
              [labels addObject:[NSString stringWithFormat:@"%g s", value.intValue / 10000.0]];
          }
          [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:values labels:labels readOnly:property.readOnly];
          break;
        }
        case PTPPropertyCodeImageSize: {
          NSMutableArray *values = [NSMutableArray array];
          NSMutableArray *labels = [NSMutableArray array];
          for (NSString *value in property.supportedValues) {
            [values addObject:value];
            [labels addObject:value];
          }
          [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:values labels:labels readOnly:property.readOnly];
          break;
        }
        case PTPPropertyCodeCompressionSetting: {
          NSDictionary *map = @{ @0: @"JPEG Basic", @1: @"JPEG Norm", @2: @"JPEG Fine", @4: @"RAW", @5: @"RAW + JPEG Basic", @6: @"RAW + JPEG Norm", @7: @"RAW + JPEG Fine" };
          NSMutableArray *values = [NSMutableArray array];
          NSMutableArray *labels = [NSMutableArray array];
          for (NSNumber *value in property.supportedValues) {
            [values addObject:value.description];
            NSString *label = map[value];
            if (label)
              [labels addObject:label];
            else
              [labels addObject:[NSString stringWithFormat:@"0x%04x", value.intValue]];
          }
          [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:values labels:labels readOnly:property.readOnly];
          break;
        }
        case PTPPropertyCodeWhiteBalance: {
          NSDictionary *map = @{ @1: @"Manual", @2: @"Auto", @3: @"One-push Auto", @4: @"Daylight", @5: @"Fluorescent", @6: @"Incandescent", @7: @"Flash", @32784: @"Cloudy", @32785: @"Shade", @32786: @"Color Temperature", @32787: @"Preset" };
          NSMutableArray *values = [NSMutableArray array];
          NSMutableArray *labels = [NSMutableArray array];
          for (NSNumber *value in property.supportedValues) {
            [values addObject:value.description];
            NSString *label = map[value];
            if (label)
              [labels addObject:label];
            else
              [labels addObject:[NSString stringWithFormat:@"0x%04x", value.intValue]];
          }
          [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:values labels:labels readOnly:property.readOnly];
          break;
        }
        case PTPPropertyCodeExposureIndex: {
          NSMutableArray *values = [NSMutableArray array];
          NSMutableArray *labels = [NSMutableArray array];
          for (NSNumber *value in property.supportedValues) {
            [values addObject:value.description];
            [labels addObject:value.description];
          }
          [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:values labels:labels readOnly:property.readOnly];
          break;
        }
        case PTPPropertyCodeExposureBiasCompensation: {
          NSMutableArray *values = [NSMutableArray array];
          NSMutableArray *labels = [NSMutableArray array];
          for (NSNumber *value in property.supportedValues) {
            [values addObject:value.description];
            [labels addObject:[NSString stringWithFormat:@"%.1f", round(value.intValue / 100.0) / 10.0]];
          }
          [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:values labels:labels readOnly:property.readOnly];
          break;
        }
        case PTPPropertyCodeExposureMeteringMode: {
          NSDictionary *map = @{ @1: @"Average", @2: @"Center-Weighted Average", @3: @"Multi-spot", @4: @"Center-spot" };
          NSMutableArray *values = [NSMutableArray array];
          NSMutableArray *labels = [NSMutableArray array];
          for (NSNumber *value in property.supportedValues) {
            [values addObject:value.description];
            NSString *label = map[value];
            if (label)
              [labels addObject:label];
            else
              [labels addObject:[NSString stringWithFormat:@"0x%04x", value.intValue]];
          }
          [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:values labels:labels readOnly:property.readOnly];
          break;
        }
        case PTPPropertyCodeFocusMeteringMode: {
          NSDictionary *map = @{ @1: @"Center-spot", @2: @"Multi-spot", @32784: @"Single Area", @32785: @"Auto area", @32786: @"3D tracking", @32787: @"21 points", @32788: @"39 points" };
          NSMutableArray *values = [NSMutableArray array];
          NSMutableArray *labels = [NSMutableArray array];
          for (NSNumber *value in property.supportedValues) {
            [values addObject:value.description];
            NSString *label = map[value];
            if (label)
              [labels addObject:label];
            else
              [labels addObject:[NSString stringWithFormat:@"0x%04x", value.intValue]];
          }
          [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:values labels:labels readOnly:property.readOnly];
          break;
        }
        case PTPPropertyCodeFocalLength: {
          [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:(NSNumber *)[NSNumber numberWithInt:property.value.intValue / 100] min:[NSNumber numberWithInt:property.min.intValue / 100] max:[NSNumber numberWithInt:property.max.intValue / 100] step:nil readOnly:true];
          break;
        }
        case PTPPropertyCodeFlashMode: {
          NSDictionary *map = @{ @0: @"Undefined", @1: @"Automatic flash", @2: @"Flash off", @3: @"Fill flash", @4: @"Automatic Red-eye Reduction", @5: @"Red-eye fill flash", @6: @"External sync", @32784: @"Auto", @32785: @"Auto Slow Sync", @32786: @"Rear Curtain Sync + Slow Sync", @32787: @"Red-eye Reduction + Slow Sync" };
          NSMutableArray *values = [NSMutableArray array];
          NSMutableArray *labels = [NSMutableArray array];
          for (NSNumber *value in property.supportedValues) {
            [values addObject:value.description];
            NSString *label = map[value];
            if (label)
              [labels addObject:label];
            else
              [labels addObject:[NSString stringWithFormat:@"0x%04x", value.intValue]];
          }
          [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:values labels:labels readOnly:property.readOnly];
          break;
        }
        case PTPPropertyCodeFocusMode: {
          if (info.vendorExtension != PTPVendorExtensionNikon) {
            NSDictionary *map = @{ @1: @"Manual", @2: @"Automatic", @3:@"Macro", @32784: @"AF-S", @32785: @"AF-C", @32786: @"AF-A" };
            NSMutableArray *values = [NSMutableArray array];
            NSMutableArray *labels = [NSMutableArray array];
            for (NSNumber *value in property.supportedValues) {
              [values addObject:value.description];
              NSString *label = map[value];
              if (label)
                [labels addObject:label];
              else
                [labels addObject:[NSString stringWithFormat:@"0x%04x", value.intValue]];
            }
            [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:values labels:labels readOnly:property.readOnly];
          }
          break;
        }
        case PTPPropertyCodeStillCaptureMode: {
          NSDictionary *map = @{ @1: @"Single shot", @2: @"Continuous", @3:@"Timelapse", @32784: @"Continuous low speed", @32785: @"Timer", @32786: @"Mirror up", @32787: @"Remote", @32788: @"Timer + Remote", @32789: @"Delayed remote", @32790: @"Quiet shutter release" };
          NSMutableArray *values = [NSMutableArray array];
          NSMutableArray *labels = [NSMutableArray array];
          for (NSNumber *value in property.supportedValues) {
            [values addObject:value.description];
            NSString *label = map[value];
            if (label)
              [labels addObject:label];
            else
              [labels addObject:[NSString stringWithFormat:@"0x%04x", value.intValue]];
          }
          [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:values labels:labels readOnly:property.readOnly];
          break;
        }
      }
      if (info.vendorExtension == PTPVendorExtensionNikon) {
        switch (property.propertyCode) {
          case PTPPropertyCodeFocusMode: {
            break;
          }
          case PTPPropertyCodeNikonLiveViewStatus: {
            [(PTPDelegate *)self.delegate cameraCanStream:self];
            if (property.value.description.intValue) {
              [self setProperty:PTPPropertyCodeNikonLiveViewImageZoomRatio value:[self.userData[PTP_LIVE_VIEW_ZOOM] description]];
              [self sendPTPRequest:PTPOperationCodeNikonChangeAfArea param1:[self.userData[PTP_LIVE_VIEW_X] intValue] param2:[self.userData[PTP_LIVE_VIEW_Y] intValue]];
              NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(getLiveViewImage) userInfo:nil repeats:true];
              self.userData[PTP_LIVE_VIEW_TIMER] = timer;
            } else {
              NSTimer *timer = self.userData[PTP_LIVE_VIEW_TIMER];
              [timer invalidate];
            }
            break;
          }
          case PTPPropertyCodeNikonExternalFlashMode:
          case PTPPropertyCodeNikonColorSpace: {
            NSArray *values = @[ @"0", @"1" ];
            NSArray *labels = @[ @"sRGB", @"Adobe RGB" ];
            [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:values labels:labels readOnly:property.readOnly];
            break;
          }
          case PTPPropertyCodeNikonLiveViewImageZoomRatio: {
            NSArray *values = @[ @"0", @"1", @"2", @"3", @"4", @"5" ];
            NSArray *labels = @[ @"1x", @"2x", @"3x", @"4x", @"6x", @"8x" ];
            [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:values labels:labels readOnly:property.readOnly];
            break;
          }
          case PTPPropertyCodeNikonVignetteCtrl: {
            NSArray *values = @[ @"0", @"1", @"2", @"3" ];
            NSArray *labels = @[ @"High", @"Normal", @"Low", @"Off" ];
            [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:values labels:labels readOnly:property.readOnly];
            break;
          }
          case PTPPropertyCodeNikonBlinkingStatus: {
            NSArray *values = @[ @"0", @"1", @"2", @"3" ];
            NSArray *labels = @[ @"None", @"Shutter", @"Aperture", @"Shutter + Aperture" ];
            [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:values labels:labels readOnly:property.readOnly];
            break;
          }
          case PTPPropertyCodeNikonCleanImageSensor: {
            NSArray *values = @[ @"0", @"1", @"2", @"3" ];
            NSArray *labels = @[ @"At startup", @"At shutdown", @"At startup + shutdown", @"Off" ];
            [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:values labels:labels readOnly:property.readOnly];
            break;
          }
          case PTPPropertyCodeNikonHDRMode: {
            NSArray *values = @[ @"0", @"1", @"2", @"3", @"4", @"5" ];
            NSArray *labels = @[ @"Off", @"Low", @"Normal", @"High", @"Extra high", @"Auto" ];
            [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:values labels:labels readOnly:property.readOnly];
            break;
          }
          case PTPPropertyCodeNikonMovScreenSize: {
            NSArray *values = @[ @"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7" ];
            NSArray *labels = @[ @"1920x1080 50p", @"1920x1080 25p", @"1920x1080 24p", @"1280x720 50p", @"640x424 25p", @"1920x1080 25p", @"1920x1080 24p", @"1280x720 50p" ];
            [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:values labels:labels readOnly:property.readOnly];
            break;
          }
          case PTPPropertyCodeNikonEnableCopyright:
          case PTPPropertyCodeNikonAutoDistortionControl:
          case PTPPropertyCodeNikonAELockStatus:
          case PTPPropertyCodeNikonAFLockStatus:
          case PTPPropertyCodeNikonExternalFlashAttached:
          case PTPPropertyCodeNikonAFCModePriority:
          case PTPPropertyCodeNikonISOAutoTime:
          case PTPPropertyCodeNikonMovHiQuality:
          case PTPPropertyCodeNikonImageRotation:
          case PTPPropertyCodeNikonImageCommentEnable:
          case PTPPropertyCodeNikonManualMovieSetting:
          case PTPPropertyCodeNikonResetBank:
          case PTPPropertyCodeNikonResetBank0:
          case PTPPropertyCodeNikonExposureDelayMode:
          case PTPPropertyCodeNikonLongExposureNoiseReduction:
          case PTPPropertyCodeNikonMovWindNoiceReduction:
          case PTPPropertyCodeNikonBracketing:
          case PTPPropertyCodeNikonNoCFCard:
          case PTPPropertyCodeNikonACPower: {
            NSArray *values = @[ @"0", @"1" ];
            NSArray *labels = @[ @"Off", @"On" ];
            [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:values labels:labels readOnly:property.readOnly];
            break;
          }
          case PTPPropertyCodeNikonEVStep: {
            NSArray *values = @[ @"0", @"1" ];
            NSArray *labels = @[ @"1/3", @"1/2" ];
            [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:values labels:labels readOnly:property.readOnly];
            [self sendPTPRequest:PTPOperationCodeGetDevicePropDesc param1:PTPPropertyCodeExposureBiasCompensation];
            [self sendPTPRequest:PTPOperationCodeGetDevicePropDesc param1:PTPPropertyCodeNikonFlashExposureCompensation];
            [self sendPTPRequest:PTPOperationCodeGetDevicePropDesc param1:PTPPropertyCodeNikonExternalFlashCompensation];
            break;
          }
          case PTPPropertyCodeNikonFlashExposureCompensation:
          case PTPPropertyCodeNikonExternalFlashCompensation: {
            NSMutableArray *values = [NSMutableArray array];
            NSMutableArray *labels = [NSMutableArray array];
            int step;
            if (info.properties[[NSNumber numberWithUnsignedShort:PTPPropertyCodeNikonEVStep]].value.intValue == 0)
              step = 2;
            else
              step = 3;
            for (int i = property.min.intValue; i <= property.max.intValue; i += step) {
              [values addObject:[NSString stringWithFormat:@"%d", i ]];
              [labels addObject:[NSString stringWithFormat:@"%.1f", i * 0.16666 ]];
            }
            [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:values labels:labels readOnly:property.readOnly];
            break;
          }
          case PTPPropertyCodeNikonCameraInclination: {
            NSArray *values = @[ @"0", @"1", @"2", @"3" ];
            NSArray *labels = @[ @"Level", @"Grip is top", @"Grip is bottom", @"Up Down" ];
            [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:values labels:labels readOnly:property.readOnly];
            break;
          }
          case PTPPropertyCodeNikonLensID: {
            property.type = PTPDataTypeCodeUnicodeString;
            NSDictionary *lens = @{ @0x0000: @"Fisheye Nikkor 8mm f/2.8 AiS", @0x0001: @"AF Nikkor 50mm f/1.8", @0x0002: @"AF Zoom-Nikkor 35-70mm f/3.3-4.5", @0x0003: @"AF Zoom-Nikkor 70-210mm f/4", @0x0004: @"AF Nikkor 28mm f/2.8", @0x0005: @"AF Nikkor 50mm f/1.4", @0x0006: @"AF Micro-Nikkor 55mm f/2.8", @0x0007: @"AF Zoom-Nikkor 28-85mm f/3.5-4.5", @0x0008: @"AF Zoom-Nikkor 35-105mm f/3.5-4.5", @0x0009: @"AF Nikkor 24mm f/2.8", @0x000A: @"AF Nikkor 300mm f/2.8 IF-ED", @0x000B: @"AF Nikkor 180mm f/2.8 IF-ED", @0x000D: @"AF Zoom-Nikkor 35-135mm f/3.5-4.5", @0x000E: @"AF Zoom-Nikkor 70-210mm f/4", @0x000F: @"AF Nikkor 50mm f/1.8 N", @0x0010: @"AF Nikkor 300mm f/4 IF-ED", @0x0011: @"AF Zoom-Nikkor 35-70mm f/2.8", @0x0012: @"AF Nikkor 70-210mm f/4-5.6", @0x0013: @"AF Zoom-Nikkor 24-50mm f/3.3-4.5", @0x0014: @"AF Zoom-Nikkor 80-200mm f/2.8 ED", @0x0015: @"AF Nikkor 85mm f/1.8", @0x0017: @"Nikkor 500mm f/4 P ED IF", @0x0018: @"AF Zoom-Nikkor 35-135mm f/3.5-4.5 N", @0x001A: @"AF Nikkor 35mm f/2", @0x001B: @"AF Zoom-Nikkor 75-300mm f/4.5-5.6", @0x001C: @"AF Nikkor 20mm f/2.8", @0x001D: @"AF Zoom-Nikkor 35-70mm f/3.3-4.5 N", @0x001E: @"AF Micro-Nikkor 60mm f/2.8", @0x001F: @"AF Micro-Nikkor 105mm f/2.8", @0x0020: @"AF Zoom-Nikkor 80-200mm f/2.8 ED", @0x0021: @"AF Zoom-Nikkor 28-70mm f/3.5-4.5", @0x0022: @"AF DC-Nikkor 135mm f/2", @0x0023: @"Zoom-Nikkor 1200-1700mm f/5.6-8 P ED IF", @0x0024: @"AF Zoom-Nikkor 80-200mm f/2.8D ED", @0x0025: @"AF Zoom-Nikkor 35-70mm f/2.8D", @0x0026: @"AF Zoom-Nikkor 28-70mm f/3.5-4.5D", @0x0027: @"AF-I Nikkor 300mm f/2.8D IF-ED", @0x0028: @"AF-I Nikkor 600mm f/4D IF-ED", @0x002A: @"AF Nikkor 28mm f/1.4D", @0x002B: @"AF Zoom-Nikkor 35-80mm f/4-5.6D", @0x002C: @"AF DC-Nikkor 105mm f/2D", @0x002D: @"AF Micro-Nikkor 200mm f/4D IF-ED", @0x002E: @"AF Nikkor 70-210mm f/4-5.6D", @0x002F: @"AF Zoom-Nikkor 20-35mm f/2.8D IF", @0x0030: @"AF-I Nikkor 400mm f/2.8D IF-ED", @0x0031: @"AF Micro-Nikkor 60mm f/2.8D", @0x0032: @"AF Micro-Nikkor 105mm f/2.8D", @0x0033: @"AF Nikkor 18mm f/2.8D", @0x0034: @"AF Fisheye Nikkor 16mm f/2.8D", @0x0035: @"AF-I Nikkor 500mm f/4D IF-ED", @0x0036: @"AF Nikkor 24mm f/2.8D", @0x0037: @"AF Nikkor 20mm f/2.8D", @0x0038: @"AF Nikkor 85mm f/1.8D", @0x003A: @"AF Zoom-Nikkor 28-70mm f/3.5-4.5D", @0x003B: @"AF Zoom-Nikkor 35-70mm f/2.8D N", @0x003C: @"AF Zoom-Nikkor 80-200mm f/2.8D ED", @0x003D: @"AF Zoom-Nikkor 35-80mm f/4-5.6D", @0x003E: @"AF Nikkor 28mm f/2.8D", @0x003F: @"AF Zoom-Nikkor 35-105mm f/3.5-4.5D", @0x0041: @"AF Nikkor 180mm f/2.8D IF-ED", @0x0042: @"AF Nikkor 35mm f/2D", @0x0043: @"AF Nikkor 50mm f/1.4D", @0x0044: @"AF Zoom-Nikkor 80-200mm f/4.5-5.6D", @0x0045: @"AF Zoom-Nikkor 28-80mm f/3.5-5.6D", @0x0046: @"AF Zoom-Nikkor 35-80mm f/4-5.6D N", @0x0047: @"AF Zoom-Nikkor 24-50mm f/3.3-4.5D", @0x0048: @"AF-S Nikkor 300mm f/2.8D IF-ED", @0x0049: @"AF-S Nikkor 600mm f/4D IF-ED", @0x004A: @"AF Nikkor 85mm f/1.4D IF", @0x004B: @"AF-S Nikkor 500mm f/4D IF-ED", @0x004C: @"AF Zoom-Nikkor 24-120mm f/3.5-5.6D IF", @0x004D: @"AF Zoom-Nikkor 28-200mm f/3.5-5.6D IF", @0x004E: @"AF DC-Nikkor 135mm f/2D", @0x004F: @"IX-Nikkor 24-70mm f/3.5-5.6", @0x0050: @"IX-Nikkor 60-180mm f/4-5.6", @0x0053: @"AF Zoom-Nikkor 80-200mm f/2.8D ED", @0x0054: @"AF Zoom-Micro Nikkor 70-180mm f/4.5-5.6D ED", @0x0056: @"AF Zoom-Nikkor 70-300mm f/4-5.6D ED", @0x0059: @"AF-S Nikkor 400mm f/2.8D IF-ED", @0x005A: @"IX-Nikkor 30-60mm f/4-5.6", @0x005B: @"IX-Nikkor 60-180mm f/4.5-5.6", @0x005D: @"AF-S Zoom-Nikkor 28-70mm f/2.8D IF-ED", @0x005E: @"AF-S Zoom-Nikkor 80-200mm f/2.8D IF-ED", @0x005F: @"AF Zoom-Nikkor 28-105mm f/3.5-4.5D IF", @0x0060: @"AF Zoom-Nikkor 28-80mm f/3.5-5.6D", @0x0061: @"AF Zoom-Nikkor 75-240mm f/4.5-5.6D", @0x0063: @"AF-S Nikkor 17-35mm f/2.8D IF-ED", @0x0064: @"PC Micro-Nikkor 85mm f/2.8D", @0x0065: @"AF VR Zoom-Nikkor 80-400mm f/4.5-5.6D ED", @0x0066: @"AF Zoom-Nikkor 18-35mm f/3.5-4.5D IF-ED", @0x0067: @"AF Zoom-Nikkor 24-85mm f/2.8-4D IF", @0x0068: @"AF Zoom-Nikkor 28-80mm f/3.3-5.6G", @0x0069: @"AF Zoom-Nikkor 70-300mm f/4-5.6G", @0x006A: @"AF-S Nikkor 300mm f/4D IF-ED", @0x006B: @"AF Nikkor ED 14mm f/2.8D", @0x006D: @"AF-S Nikkor 300mm f/2.8D IF-ED II", @0x006E: @"AF-S Nikkor 400mm f/2.8D IF-ED II", @0x006F: @"AF-S Nikkor 500mm f/4D IF-ED II", @0x0070: @"AF-S Nikkor 600mm f/4D IF-ED II", @0x0072: @"Nikkor 45mm f/2.8 P", @0x0074: @"AF-S Zoom-Nikkor 24-85mm f/3.5-4.5G IF-ED", @0x0075: @"AF Zoom-Nikkor 28-100mm f/3.5-5.6G", @0x0076: @"AF Nikkor 50mm f/1.8D", @0x0077: @"AF-S VR Zoom-Nikkor 70-200mm f/2.8G IF-ED", @0x0078: @"AF-S VR Zoom-Nikkor 24-120mm f/3.5-5.6G IF-ED", @0x0079: @"AF Zoom-Nikkor 28-200mm f/3.5-5.6G IF-ED", @0x007A: @"AF-S DX Zoom-Nikkor 12-24mm f/4G IF-ED", @0x007B: @"AF-S VR Zoom-Nikkor 200-400mm f/4G IF-ED", @0x007D: @"AF-S DX Zoom-Nikkor 17-55mm f/2.8G IF-ED", @0x007F: @"AF-S DX Zoom-Nikkor 18-70mm f/3.5-4.5G IF-ED", @0x0080: @"AF DX Fisheye-Nikkor 10.5mm f/2.8G ED", @0x0081: @"AF-S VR Nikkor 200mm f/2G IF-ED", @0x0082: @"AF-S VR Nikkor 300mm f/2.8G IF-ED", @0x0083: @"FSA-L2, EDG 65, 800mm F13 G", @0x0089: @"AF-S DX Zoom-Nikkor 55-200mm f/4-5.6G ED", @0x008A: @"AF-S VR Micro-Nikkor 105mm f/2.8G IF-ED", @0x008B: @"AF-S DX VR Zoom-Nikkor 18-200mm f/3.5-5.6G IF-ED", @0x008C: @"AF-S DX Zoom-Nikkor 18-55mm f/3.5-5.6G ED", @0x008D: @"AF-S VR Zoom-Nikkor 70-300mm f/4.5-5.6G IF-ED", @0x008F: @"AF-S DX Zoom-Nikkor 18-135mm f/3.5-5.6G IF-ED", @0x0090: @"AF-S DX VR Zoom-Nikkor 55-200mm f/4-5.6G IF-ED", @0x0092: @"AF-S Zoom-Nikkor 14-24mm f/2.8G ED", @0x0093: @"AF-S Zoom-Nikkor 24-70mm f/2.8G ED", @0x0094: @"AF-S DX Zoom-Nikkor 18-55mm f/3.5-5.6G ED II", @0x0095: @"PC-E Nikkor 24mm f/3.5D ED", @0x0096: @"AF-S VR Nikkor 400mm f/2.8G ED", @0x0097: @"AF-S VR Nikkor 500mm f/4G ED", @0x0098: @"AF-S VR Nikkor 600mm f/4G ED", @0x0099: @"AF-S DX VR Zoom-Nikkor 16-85mm f/3.5-5.6G ED", @0x009A: @"AF-S DX VR Zoom-Nikkor 18-55mm f/3.5-5.6G", @0x009B: @"PC-E Micro Nikkor 45mm f/2.8D ED", @0x009C: @"AF-S Micro Nikkor 60mm f/2.8G ED", @0x009D: @"PC-E Micro Nikkor 85mm f/2.8D", @0x009E: @"AF-S DX VR Zoom-Nikkor 18-105mm f/3.5-5.6G ED", @0x009F: @"AF-S DX Nikkor 35mm f/1.8G", @0x00A0: @"AF-S Nikkor 50mm f/1.4G", @0x00A1: @"AF-S DX Nikkor 10-24mm f/3.5-4.5G ED", @0x00A2: @"AF-S Nikkor 70-200mm f/2.8G ED VR II", @0x00A3: @"AF-S Nikkor 16-35mm f/4G ED VR", @0x00A4: @"AF-S Nikkor 24mm f/1.4G ED", @0x00A5: @"AF-S Nikkor 28-300mm f/3.5-5.6G ED VR", @0x00A6: @"AF-S Nikkor 300mm f/2.8G IF-ED VR II", @0x00A7: @"AF-S DX Micro Nikkor 85mm f/3.5G ED VR", @0x00A8: @"AF-S Zoom-Nikkor 200-400mm f/4G IF-ED VR II", @0x00A9: @"AF-S Nikkor 200mm f/2G ED VR II", @0x00AA: @"AF-S Nikkor 24-120mm f/4G ED VR", @0x00AC: @"AF-S DX Nikkor 55-300mm f/4.5-5.6G ED VR", @0x00AD: @"AF-S DX Nikkor 18-300mm f/3.5-5.6G ED VR", @0x00AE: @"AF-S Nikkor 85mm f/1.4G", @0x00AF: @"AF-S Nikkor 35mm f/1.4G", @0x00B0: @"AF-S Nikkor 50mm f/1.8G", @0x00B1: @"AF-S DX Micro Nikkor 40mm f/2.8G", @0x00B2: @"AF-S Nikkor 70-200mm f/4G ED VR", @0x00B3: @"AF-S Nikkor 85mm f/1.8G", @0x00B4: @"AF-S Nikkor 24-85mm f/3.5-4.5G ED VR", @0x00B5: @"AF-S Nikkor 28mm f/1.8G", @0x00B6: @"AF-S VR Nikkor 800mm f/5.6E FL ED", @0x00B7: @"AF-S Nikkor 80-400mm f/4.5-5.6G ED VR", @0x00B8: @"AF-S Nikkor 18-35mm f/3.5-4.5G ED", @0x01A0: @"AF-S DX Nikkor 18-140mm f/3.5-5.6G ED VR", @0x01A1: @"AF-S Nikkor 58mm f/1.4G", @0x01A2: @"AF-S DX Nikkor 18-55mm f/3.5-5.6G VR II", @0x01A4: @"AF-S DX Nikkor 18-300mm f/3.5-6.3G ED VR", @0x01A5: @"AF-S Nikkor 35mm f/1.8G ED", @0x01A6: @"AF-S Nikkor 400mm f/2.8E FL ED VR", @0x01A7: @"AF-S DX Nikkor 55-200mm f/4-5.6G ED VR II", @0x01A8: @"AF-S Nikkor 300mm f/4E PF ED VR", @0x01A9: @"AF-S Nikkor 20mm f/1.8G ED", @0x02AA: @"AF-S Nikkor 24-70mm f/2.8E ED VR", @0x02AB: @"AF-S Nikkor 500mm f/4E FL ED VR", @0x02AC: @"AF-S Nikkor 600mm f/4E FL ED VR", @0x02AD: @"AF-S DX Nikkor 16-80mm f/2.8-4E ED VR", @0x02AE: @"AF-S Nikkor 200-500mm f/5.6E ED VR", @0x03A0: @"AF-P DX Nikkor 18-55mm f/3.5-5.6G VR", @0x03A3: @"AF-P DX Nikkor 70–300mm f/4.5–6.3G ED VR", @0x03A4: @"AF-S Nikkor 70-200mm f/2.8E FL ED VR", @0x03A5: @"AF-S Nikkor 105mm f/1.4E ED", @0x03AF: @"AF-S Nikkor 24mm f/1.8G ED" };
            [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:lens[property.value] readOnly:true];
            break;
          }
          case PTPPropertyCodeNikonLiveViewImageSize: {
            NSArray *values = @[ @"1", @"2" ];
            NSArray *labels = @[ @"QVGA", @"VGA" ];
            [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:values labels:labels readOnly:property.readOnly];
            break;
          }
          case PTPPropertyCodeNikonRawBitMode: {
            NSArray *values = @[ @"0", @"1" ];
            NSArray *labels = @[ @"12 bit", @"14 bit" ];
            [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:values labels:labels readOnly:property.readOnly];
            break;
          }
          case PTPPropertyCodeNikonSaveMedia: {
            NSArray *values = @[ @"0", @"1", @"2" ];
            NSArray *labels = @[ @"Card", @"SDRAM", @"Card + SDRAM" ];
            [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:values labels:labels readOnly:property.readOnly];
            break;
          }
          case PTPPropertyCodeNikonLiveViewAFArea: {
            NSArray *values = @[ @"0", @"1", @"2" ];
            NSArray *labels = @[ @"Face priority", @"Wide area", @"Normal area" ];
            [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:values labels:labels readOnly:property.readOnly];
            break;
          }
          case PTPPropertyCodeNikonFlourescentType: {
            NSArray *values = @[ @"0", @"1", @"2", @"3", @"4", @"5" ];
            NSArray *labels = @[ @"Sodium-vapor", @"Warm-white", @"White", @"Cool-white", @"Day white", @"Daylight", @"High temp. mercury-vapor" ];
            [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:values labels:labels readOnly:property.readOnly];
            break;
          }
          case PTPPropertyCodeNikonActiveDLighting: {
            NSArray *values = @[ @"0", @"1", @"2", @"3", @"4", @"5" ];
            NSArray *labels = @[ @"High", @"Normal", @"Low", @"Off", @"Extra high", @"Auto" ];
            [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:values labels:labels readOnly:property.readOnly];
            break;
          }
          case PTPPropertyCodeNikonActivePicCtrlItem: {
            NSArray *values = @[ @"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"201", @"202", @"203", @"204", @"205", @"206", @"207", @"208", @"209" ];
            NSArray *labels = @[ @"Undefined", @"Standard", @"Neutral", @"Vivid", @"Monochrome", @"Portrait", @"Landscape", @"Flat", @"Custom 1", @"Custom 2", @"Custom 3", @"Custom 4", @"Custom 5", @"Custom 6", @"Custom 7", @"Custom 8", @"Custom 9" ];
            [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:values labels:labels readOnly:property.readOnly];
            break;
          }
          case PTPPropertyCodeNikonEffectMode: {
            NSArray *values = @[ @"0", @"1", @"2", @"3", @"4", @"5", @"6" ];
            NSArray *labels = @[ @"Night Vision", @"Color Sketch", @"Miniature Effect", @"Selective Color", @"Silhouette", @"High Key", @"Low Key" ];
            [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:values labels:labels readOnly:property.readOnly];
            break;
          }
          case PTPPropertyCodeNikonSceneMode: {
            NSArray *values = @[ @"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", @"11", @"12", @"13", @"14", @"15", @"16", @"17", @"18" ];
            NSArray *labels = @[ @"NightLandscape", @"PartyIndoor", @"BeachSnow", @"Sunset", @"Duskdawn", @"Petportrait", @"Candlelight", @"Blossom", @"AutumnColors", @"Food", @"Silhouette", @"Highkey", @"Lowkey", @"Portrait", @"Landscape", @"Child", @"Sports", @"Closeup", @"NightPortrait" ];
            [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:values labels:labels readOnly:property.readOnly];
            break;
          }
          case PTPPropertyCodeNikonLiveViewAFFocus: {
            if (property.value.description.intValue == 3) {
              [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:@"3" values:@[@"3"] labels:@[@"M (fixed)"] readOnly:true];
            } else if (property.max.intValue == 1) {
              [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:@[@"0", @"2"] labels:@[@"AF-S", @"AF-F"] readOnly:property.readOnly];
            } else {
              [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:@[@"0", @"2", @"4"] labels:@[@"AF-S", @"AF-F", @"M"] readOnly:property.readOnly];
            }
            break;
          }
          case PTPPropertyCodeNikonAutofocusMode: {
            if (property.value.description.intValue == 3) {
              [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:PTPPropertyCodeFocusMode value:@"3" values:@[@"3"] labels:@[@"M (fixed)"] readOnly:true];
            } else if (property.max.intValue == 1) {
              [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:PTPPropertyCodeFocusMode value:property.value.description values:@[@"0", @"1"] labels:@[@"AF-S", @"AF-C"] readOnly:property.readOnly];
            } else {
              [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:PTPPropertyCodeFocusMode value:property.value.description values:@[@"0", @"1", @"2", @"4"] labels:@[@"AF-S", @"AF-C", @"AF-A", @"M"] readOnly:property.readOnly];
            }
            break;
          }
          default: {
            if (property.supportedValues) {
              NSMutableArray *values = [NSMutableArray array];
              for (NSNumber *number in property.supportedValues)
                [values addObject:number.description];
              [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description values:values labels:values readOnly:property.readOnly];
            } else if (property.type >= PTPDataTypeCodeSInt8 && property.type <= PTPDataTypeCodeUInt64) {
              [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:(NSNumber *)property.value min:property.min max:property.max step:property.step readOnly:property.readOnly];
            } else if (property.type == PTPDataTypeCodeSInt128 || property.type == PTPDataTypeCodeUInt128) {
              [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:(NSString *)property.value.description readOnly:true];
            } else if (property.type == PTPDataTypeCodeUnicodeString) {
              [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:(NSString *)property.value.description readOnly:property.readOnly];
            } else if (indigo_get_log_level() >= INDIGO_LOG_DEBUG) {
              NSLog(@"Ignored %@", property);
            }
            break;
          }
        }
      }
      break;
    }
    case PTPOperationCodeGetDevicePropValue: {
      if (info.vendorExtension == PTPVendorExtensionNikon) {
        switch (ptpRequest.parameter1) {
          case PTPPropertyCodeNikonLiveViewProhibitCondition: {
            if (ptpResponse.responseCode == PTPResponseCodeOK) {
              unsigned char *bytes = (void*)[data bytes];
              unsigned int value = ptpReadUnsignedInt(&bytes);
              if (value == 0) {
                [self sendPTPRequest:PTPOperationCodeNikonStartLiveView];
                usleep(100000);
              } else {
                NSMutableString *text = [NSMutableString stringWithFormat:@"LiveViewProhibitCondition 0x%08x", value];
                if (value & 0x80000000)
                  [text appendString:@", Exposure Mode is non-P,S,A,M"];
                if (value & 0x01000000)
                  [text appendString:@", When Retractable lens is set, the zoom ring does not extend"];
                if (value & 0x00200000)
                  [text appendString:@", Bulb warning, ShutterSpeed is Time"];
                if (value & 0x00100000)
                  [text appendString:@", Card not formatted"];
                if (value & 0x00080000)
                  [text appendString:@", Card error"];
                if (value & 0x00040000)
                  [text appendString:@", Card protected"];
                if (value & 0x00020000)
                  [text appendString:@", High temperature"];
                if (value & 0x00008000)
                  [text appendString:@", Capture command is executing"];
                if (value & 0x00004000)
                  [text appendString:@", No memory card is inserted in the camera"];
                if (value & 0x00000800)
                  [text appendString:@", Non-CPU lens is attached and ExposureMode is not Manual or Aperture priority"];
                if (value & 0x00000400)
                  [text appendString:@", The setting by Aperture ring is valid"];
                if (value & 0x00000200)
                  [text appendString:@", TTL error"];
                if (value & 0x00000100)
                  [text appendString:@", Battery shortage"];
                if (value & 0x00000080)
                  [text appendString:@", Mirror up"];
                if (value & 0x00000040)
                  [text appendString:@", Shutter bulb"];
                if (value & 0x00000020)
                  [text appendString:@", Aperture ring is not minimum"];
                if (value & 0x00000004)
                  [text appendString:@", Sequence error"];
                if (value & 0x00000001)
                  [text appendString:@", Recording media is CF/SD card"];
                [(PTPDelegate *)self.delegate cameraExposureFailed:self message:text];
              }
            } else {
              [(PTPDelegate *)self.delegate cameraExposureFailed:self message:[NSString stringWithFormat:@"LiveViewProhibiCondition failed (0x%04x = %@)", ptpResponse.responseCode, ptpResponse]];
            }
            break;
          }
        }
      }
      break;
    }
  }
  if (info.vendorExtension == PTPVendorExtensionNikon) {
    switch (ptpRequest.operationCode) {
      case PTPOperationCodeNikonDeviceReady: {
        if (ptpResponse.responseCode == PTPResponseCodeDeviceBusy) {
          usleep(100000);
        }
        break;
      }
      case PTPOperationCodeNikonGetVendorPropCodes: {
        unsigned char* buffer = (unsigned char*)[data bytes];
        unsigned char* buf = buffer;
        NSArray *codes = ptpReadUnsignedShortArray(&buf);
        PTPDeviceInfo *info = self.ptpDeviceInfo;
        [(NSMutableArray *)info.propertiesSupported addObjectsFromArray:codes];
        for (NSNumber *code in info.propertiesSupported) {
          [self sendPTPRequest:PTPOperationCodeGetDevicePropDesc param1:code.unsignedShortValue];
        }
        [self sendPTPRequest:PTPOperationCodeGetStorageIDs];
        break;
      }
      case PTPOperationCodeNikonInitiateCaptureRecInMedia: {
        if (ptpResponse.responseCode != PTPResponseCodeOK &&  ptpResponse.responseCode != PTPResponseCodeDeviceBusy) {
          [self sendPTPRequest:PTPOperationCodeNikonTerminateCapture param1:0 param2:0];
          [(PTPDelegate *)self.delegate cameraExposureFailed:self message:[NSString stringWithFormat:@"InitiateCaptureRecInMedia failed (0x%04x = %@)", ptpResponse.responseCode, ptpResponse]];
        }
        break;
      }
      case PTPOperationCodeNikonMfDrive: {
        if (ptpResponse.responseCode == PTPResponseCodeOK) {
          dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [(PTPDelegate *)self.delegate cameraFocusDone:self];
          });

        }
        else
          [(PTPDelegate *)self.delegate cameraFocusFailed:self message:[NSString stringWithFormat:@"MfDrive failed (0x%04x = %@)", ptpResponse.responseCode, ptpResponse]];
        break;
      }
      case PTPOperationCodeNikonGetLiveViewImg: {
        if (ptpResponse.responseCode == PTPResponseCodeOK && data) {
          char *bytes = (void*)[data bytes];
          NSData *image;
          if ((bytes[64] & 0xFF) == 0xFF && (bytes[65] & 0xFF) == 0xD8) {
            image = [NSData dataWithBytes:bytes + 64 length:data.length - 64];
            image = [NSData dataWithBytes:bytes + 128 length:data.length - 128];
            unsigned char *buf = (unsigned char *)bytes;
            ptpReadUnsignedShort(&buf); // image width
            ptpReadUnsignedShort(&buf); // image height
            ptpReadUnsignedShort(&buf); // whole width
            ptpReadUnsignedShort(&buf); // whole height
            int frameWidth = CFSwapInt16BigToHost(ptpReadUnsignedShort(&buf));
            int frameHeight = CFSwapInt16BigToHost(ptpReadUnsignedShort(&buf));
            int frameLeft = CFSwapInt16BigToHost(ptpReadUnsignedShort(&buf)) - frameWidth / 2;
            int frameTop = CFSwapInt16BigToHost(ptpReadUnsignedShort(&buf)) - frameHeight / 2;
            [(PTPDelegate *)self.delegate cameraFrame:self left:frameLeft top:frameTop width:frameWidth height:frameHeight];
          } else if ((bytes[128] & 0xFF) == 0xFF && (bytes[129] & 0xFF) == 0xD8) {
            image = [NSData dataWithBytes:bytes + 128 length:data.length - 128];
            unsigned char *buf = (unsigned char *)bytes;
            ptpReadUnsignedShort(&buf); // image width
            ptpReadUnsignedShort(&buf); // image height
            ptpReadUnsignedShort(&buf); // whole width
            ptpReadUnsignedShort(&buf); // whole height
            int frameWidth = CFSwapInt16BigToHost(ptpReadUnsignedShort(&buf));
            int frameHeight = CFSwapInt16BigToHost(ptpReadUnsignedShort(&buf));
            int frameLeft = CFSwapInt16BigToHost(ptpReadUnsignedShort(&buf)) - frameWidth / 2;
            int frameTop = CFSwapInt16BigToHost(ptpReadUnsignedShort(&buf)) - frameHeight / 2;
            [(PTPDelegate *)self.delegate cameraFrame:self left:frameLeft top:frameTop width:frameWidth height:frameHeight];
          } else if ((bytes[384] & 0xFF) == 0xFF && (bytes[385] & 0xFF) == 0xD8) {
            image = [NSData dataWithBytes:bytes + 384 length:data.length - 384];
            unsigned char *buf = (unsigned char *)bytes;
            int header = CFSwapInt32BigToHost(ptpReadUnsignedInt(&buf)); // header size
            if (header == 376) {
              ptpReadUnsignedInt(&buf); // image size
              ptpReadUnsignedShort(&buf); // image width
              ptpReadUnsignedShort(&buf); // image height
            }
            ptpReadUnsignedShort(&buf); // whole width
            ptpReadUnsignedShort(&buf); // whole height
            int frameWidth = CFSwapInt16BigToHost(ptpReadUnsignedShort(&buf));
            int frameHeight = CFSwapInt16BigToHost(ptpReadUnsignedShort(&buf));
            int frameLeft = CFSwapInt16BigToHost(ptpReadUnsignedShort(&buf)) - frameWidth / 2;
            int frameTop = CFSwapInt16BigToHost(ptpReadUnsignedShort(&buf)) - frameHeight / 2;
            [(PTPDelegate *)self.delegate cameraFrame:self left:frameLeft top:frameTop width:frameWidth height:frameHeight];
          }
          if (image)
            [(PTPDelegate *)self.delegate cameraExposureDone:self data:image filename:@"preview.jpeg"];
          else
            [(PTPDelegate *)self.delegate cameraExposureFailed:self message:@"JPEG magic not found"];
        } else {
          [(PTPDelegate *)self.delegate cameraExposureFailed:self message:[NSString stringWithFormat:@"No data received (0x%04x = %@)", ptpResponse.responseCode, ptpResponse]];
          NSTimer *timer = self.userData[PTP_LIVE_VIEW_TIMER];
          [timer invalidate];
        }
        break;
      }
      case PTPOperationCodeNikonCheckEvent: {
        unsigned char* buffer = (unsigned char*)[data bytes];
        unsigned char* buf = buffer;
        int count = ptpReadUnsignedShort(&buf);
        for (int i = 0; i < count; i++) {
          PTPEventCode code = ptpReadUnsignedShort(&buf);
          unsigned int parameter1 = ptpReadUnsignedInt(&buf);
          PTPEvent *event = [[PTPEvent alloc] initWithCode:code parameter1:parameter1 vendorExtension:self.ptpDeviceInfo.vendorExtension];
          if (indigo_get_log_level() >= INDIGO_LOG_DEBUG)
            NSLog(@"Translated to %@", [event description]);
          [self processEvent:event];
        }
        break;
      }
      case PTPOperationCodeNikonSetControlMode: {
        [self sendPTPRequest:PTPOperationCodeGetDevicePropDesc param1:PTPPropertyCodeExposureProgramMode];
        break;
      }
    }
  }
  if (info.vendorExtension == PTPVendorExtensionCanon) {
    switch (ptpRequest.operationCode) {
      case PTPOperationCodeCanonGetDeviceInfoEx: {
        unsigned char* buffer = (unsigned char*)[data bytes];
        unsigned char* buf = buffer;
        ptpReadInt(&buf); // size
        NSArray *events = ptpReadUnsignedIntArray(&buf);
        NSArray *codes = ptpReadUnsignedIntArray(&buf);
        PTPDeviceInfo *info = self.ptpDeviceInfo;
        for (NSNumber *code in events)
          [(NSMutableArray *)info.eventsSupported addObject:[NSNumber numberWithUnsignedShort:code.unsignedShortValue]];
        for (NSNumber *code in codes)
          [(NSMutableArray *)info.propertiesSupported addObject:[NSNumber numberWithUnsignedShort:code.unsignedShortValue]];
        for (NSNumber *code in info.propertiesSupported) {
          unsigned short ui = code.unsignedShortValue;
          if ((ui & 0xD100) != 0xD100)
            [self sendPTPRequest:PTPOperationCodeGetDevicePropDesc param1:ui];
        }
        [self sendPTPRequest:PTPOperationCodeCanonSetRemoteMode param1:1];
        [self sendPTPRequest:PTPOperationCodeCanonSetEventMode param1:1];
        [self sendPTPRequest:PTPOperationCodeCanonGetEvent];
        [self sendPTPRequest:PTPOperationCodeGetStorageIDs];
        break;
      }
      case PTPOperationCodeCanonGetEvent: {
        //NSLog(@"%@", data);
        long length = data.length;
        unsigned char* buffer = (unsigned char*)[data bytes];
        unsigned char* buf = buffer;
        unsigned char* record;
        while (buf - buffer < length) {
          record = buf;
          int size = ptpReadUnsignedInt(&buf);
          int type = ptpReadUnsignedInt(&buf);
          if (size == 8 && type == 0)
            break;
          switch (type) {
            case PTPEventCodeCanonPropValueChanged: {
              unsigned int code = ptpReadUnsignedInt(&buf);
              PTPProperty *property = [[PTPProperty alloc] initWithCode:code vendorExtension:PTPVendorExtensionCanon];
              switch (code) {
                case PTPPropertyCodeCanonFocusMode:
                case PTPPropertyCodeCanonBatteryPower:
                case PTPPropertyCodeCanonBatterySelect:
                case PTPPropertyCodeCanonModelID:
                case PTPPropertyCodeCanonPTPExtensionVersion:
                case PTPPropertyCodeCanonDPOFVersion:
                case PTPPropertyCodeCanonAvailableShots:
                case PTPPropertyCodeCanonCurrentStorage:
                case PTPPropertyCodeCanonCurrentFolder:
                case PTPPropertyCodeCanonMyMenu:
                case PTPPropertyCodeCanonMyMenuList:
                case PTPPropertyCodeCanonHDDirectoryStructure:
                case PTPPropertyCodeCanonBatteryInfo:
                case PTPPropertyCodeCanonAdapterInfo:
                case PTPPropertyCodeCanonLensStatus:
                case PTPPropertyCodeCanonCardExtension:
                case PTPPropertyCodeCanonTempStatus:
                case PTPPropertyCodeCanonShutterCounter:
                case PTPPropertyCodeCanonSerialNumber:
                case PTPPropertyCodeCanonDepthOfFieldPreview:
                case PTPPropertyCodeCanonEVFRecordStatus:
                case PTPPropertyCodeCanonLvAfSystem:
                case PTPPropertyCodeCanonFocusInfoEx:
                case PTPPropertyCodeCanonDepthOfField:
                case PTPPropertyCodeCanonBrightness:
                case PTPPropertyCodeCanonEFComp:
                case PTPPropertyCodeCanonLensName:
                case PTPPropertyCodeCanonLensID:
                  property.readOnly = true;
                  break;
                default:
                  property.readOnly = false;
                  break;
              }
              switch (code) {
                case PTPPropertyCodeCanonPictureStyle:
                case PTPPropertyCodeCanonWhiteBalance:
                case PTPPropertyCodeCanonMeteringMode:
                case PTPPropertyCodeCanonExpCompensation:
                  property.type = PTPDataTypeCodeUInt8;
                  break;
                case PTPPropertyCodeCanonAperture:
                case PTPPropertyCodeCanonShutterSpeed:
                case PTPPropertyCodeCanonISOSpeed:
                case PTPPropertyCodeCanonFocusMode:
                case PTPPropertyCodeCanonColorSpace:
                case PTPPropertyCodeCanonBatteryPower:
                case PTPPropertyCodeCanonBatterySelect:
                case PTPPropertyCodeCanonPTPExtensionVersion:
                case PTPPropertyCodeCanonDriveMode:
                case PTPPropertyCodeCanonAEB:
                case PTPPropertyCodeCanonBracketMode:
                case PTPPropertyCodeCanonQuickReviewTime:
                case PTPPropertyCodeCanonEVFMode:
                case PTPPropertyCodeCanonEVFOutputDevice:
                case PTPPropertyCodeCanonAutoPowerOff:
                case PTPPropertyCodeCanonEVFRecordStatus:
                  property.type = PTPDataTypeCodeUInt16;
                  break;
                case PTPPropertyCodeCanonAutoExposureMode:
                  property.type = PTPDataTypeCodeUInt16;
                  property.supportedValues = @[];
                  break;
                case PTPPropertyCodeCanonWhiteBalanceAdjustA:
                case PTPPropertyCodeCanonWhiteBalanceAdjustB:
                  property.type = PTPDataTypeCodeSInt16;
                  break;
                case PTPPropertyCodeCanonCameraTime:
                case PTPPropertyCodeCanonUTCTime:
                case PTPPropertyCodeCanonSummertime:
                case PTPPropertyCodeCanonAvailableShots:
                case PTPPropertyCodeCanonCaptureDestination:
                case PTPPropertyCodeCanonWhiteBalanceXA:
                case PTPPropertyCodeCanonWhiteBalanceXB:
                case PTPPropertyCodeCanonCurrentStorage:
                case PTPPropertyCodeCanonCurrentFolder:
                case PTPPropertyCodeCanonShutterCounter:
                case PTPPropertyCodeCanonModelID:
                case PTPPropertyCodeCanonLensID:
                case PTPPropertyCodeCanonStroboFiring:
                case PTPPropertyCodeCanonAFSelectFocusArea:
                case PTPPropertyCodeCanonContinousAFMode:
                  property.type = PTPDataTypeCodeUInt32;
                  break;
                case PTPPropertyCodeCanonOwner:
                case PTPPropertyCodeCanonArtist:
                case PTPPropertyCodeCanonCopyright:
                //case PTPPropertyCodeCanonSerialNumber:
                case PTPPropertyCodeCanonLensName:
                  property.type = PTPDataTypeCodeUnicodeString;
                  break;
              }
              switch (property.type) {
                case PTPDataTypeCodeUInt8:
                  property.value = [NSNumber numberWithUnsignedChar:ptpReadUnsignedChar(&buf)];
                  break;
                case PTPDataTypeCodeUInt16:
                  property.value = [NSNumber numberWithUnsignedChar:ptpReadUnsignedShort(&buf)];
                  break;
                case PTPDataTypeCodeSInt16:
                  property.value = [NSNumber numberWithUnsignedChar:ptpReadShort(&buf)];
                  break;
                case PTPDataTypeCodeUInt32:
                  property.value = [NSNumber numberWithUnsignedChar:ptpReadUnsignedInt(&buf)];
                  break;
                case PTPDataTypeCodeUnicodeString:
                  property.value = ptpReadString(&buf);
                  if (property.value == nil)
                    property.value = @"";
                  break;
              }
              if (property.type != PTPDataTypeCodeUndefined) {
                info.properties[[NSNumber numberWithUnsignedShort:code]] = property;
                [(PTPDelegate *)self.delegate cameraPropertyChanged:self code:property.propertyCode value:property.value.description readOnly:property.readOnly];
              }
              NSLog(@"PTPEventCodeCanonPropValueChanged %@", property);
              break;
            }
            case PTPEventCodeCanonAvailListChanged: {
              unsigned int code = ptpReadUnsignedInt(&buf);
              PTPProperty *property = [[PTPProperty alloc] initWithCode:code vendorExtension:PTPVendorExtensionCanon];

              NSLog(@"PTPEventCodeCanonAvailListChanged %@", property);
              break;
            }
            default:
              NSLog(@"size %d type 0x%04x", size, type);
              break;
          }
          
          buf = record + size;
        }
        break;
      }
    }
  }
}

-(PTPDeviceInfo *)ptpDeviceInfo {
  return self.userData[PTP_DEVICE_INFO];
}

-(void)setProperty:(PTPPropertyCode)code value:(NSString *)value {
  PTPDeviceInfo *info = self.ptpDeviceInfo;
  if (code == PTPPropertyCodeFocusMode && info.vendorExtension == PTPVendorExtensionNikon)
    code = PTPPropertyCodeNikonAutofocusMode;
  PTPProperty *property = info.properties[[NSNumber numberWithUnsignedShort:code]];
	if (property) {
		switch (property.type) {
			case PTPDataTypeCodeSInt8: {
				unsigned char *buffer = malloc(sizeof (char));
				unsigned char *buf = buffer;
				ptpWriteChar(&buf, (char)value.longLongValue);
				[self sendPTPRequest:PTPOperationCodeSetDevicePropValue param1:code withData:[NSData dataWithBytes:buffer length:sizeof (char)]];
				free(buffer);
				break;
			}
			case PTPDataTypeCodeUInt8: {
				unsigned char *buffer = malloc(sizeof (unsigned char));
				unsigned char *buf = buffer;
				ptpWriteUnsignedChar(&buf, (unsigned char)value.longLongValue);
				[self sendPTPRequest:PTPOperationCodeSetDevicePropValue param1:code withData:[NSData dataWithBytes:buffer length:sizeof (unsigned char)]];
				free(buffer);
				break;
			}
			case PTPDataTypeCodeSInt16: {
				unsigned char *buffer = malloc(sizeof (short));
				unsigned char *buf = buffer;
				ptpWriteShort(&buf, (short)value.longLongValue);
				[self sendPTPRequest:PTPOperationCodeSetDevicePropValue param1:code withData:[NSData dataWithBytes:buffer length:sizeof (short)]];
				free(buffer);
				break;
			}
			case PTPDataTypeCodeUInt16: {
				unsigned char *buffer = malloc(sizeof (unsigned short));
				unsigned char *buf = buffer;
				ptpWriteUnsignedShort(&buf, (unsigned short)value.longLongValue);
				[self sendPTPRequest:PTPOperationCodeSetDevicePropValue param1:code withData:[NSData dataWithBytes:buffer length:sizeof (unsigned short)]];
				free(buffer);
				break;
			}
			case PTPDataTypeCodeSInt32: {
				unsigned char *buffer = malloc(sizeof (int));
				unsigned char *buf = buffer;
				ptpWriteInt(&buf, (int)value.longLongValue);
				[self sendPTPRequest:PTPOperationCodeSetDevicePropValue param1:code withData:[NSData dataWithBytes:buffer length:sizeof (int)]];
				free(buffer);
				break;
			}
			case PTPDataTypeCodeUInt32: {
				unsigned char *buffer = malloc(sizeof (unsigned int));
				unsigned char *buf = buffer;
				ptpWriteUnsignedInt(&buf, (unsigned int)value.longLongValue);
				[self sendPTPRequest:PTPOperationCodeSetDevicePropValue param1:code withData:[NSData dataWithBytes:buffer length:sizeof (unsigned int)]];
				free(buffer);
				break;
			}
			case PTPDataTypeCodeSInt64: {
				unsigned char *buffer = malloc(sizeof (long));
				unsigned char *buf = buffer;
				ptpWriteLong(&buf, (long)value.longLongValue);
				[self sendPTPRequest:PTPOperationCodeSetDevicePropValue param1:code withData:[NSData dataWithBytes:buffer length:sizeof (long)]];
				free(buffer);
				break;
			}
			case PTPDataTypeCodeUInt64: {
				unsigned char *buffer = malloc(sizeof (unsigned long));
				unsigned char *buf = buffer;
				ptpWriteUnsignedLong(&buf, (unsigned long)value.longLongValue);
				[self sendPTPRequest:PTPOperationCodeSetDevicePropValue param1:code withData:[NSData dataWithBytes:buffer length:sizeof (unsigned long)]];
				free(buffer);
				break;
			}
			case PTPDataTypeCodeUnicodeString: {
				unsigned char *buffer = malloc(256);
				unsigned char *buf = buffer;
				int length = ptpWriteString(&buf, value);
				[self sendPTPRequest:PTPOperationCodeSetDevicePropValue param1:code withData:[NSData dataWithBytes:buffer length:length]];
				free(buffer);
				break;
			}
		}
	}
}

-(void)lock {
  PTPDeviceInfo *info = self.ptpDeviceInfo;
  switch (info.vendorExtension) {
    case PTPVendorExtensionNikon:
      [self sendPTPRequest:PTPOperationCodeNikonSetControlMode param1:1];
      break;
    case PTPVendorExtensionCanon:
      [self sendPTPRequest:PTPOperationCodeCanonSetUILock];
      break;
  }
}

-(void)unlock {
  PTPDeviceInfo *info = self.ptpDeviceInfo;
  switch (info.vendorExtension) {
    case PTPVendorExtensionNikon:
      [self sendPTPRequest:PTPOperationCodeNikonSetControlMode param1:0];
      break;
    case PTPVendorExtensionCanon:
      [self sendPTPRequest:PTPOperationCodeCanonResetUILock];
      break;
  }
}

- (void)startLiveViewZoom:(int)zoom x:(int)x y:(int)y {
	PTPDeviceInfo *info = self.ptpDeviceInfo;
	switch (info.vendorExtension) {
    case PTPVendorExtensionNikon: {
      if (zoom < 2)
        zoom = 0;
      else if (zoom < 3)
        zoom = 1;
      else if (zoom < 4)
        zoom = 2;
      else if (zoom < 6)
        zoom = 3;
      else if (zoom < 8)
        zoom = 4;
      else
        zoom = 5;
      self.userData[PTP_LIVE_VIEW_ZOOM] = [NSNumber numberWithUnsignedShort:zoom];
      self.userData[PTP_LIVE_VIEW_X] = [NSNumber numberWithUnsignedShort:x];
      self.userData[PTP_LIVE_VIEW_Y] = [NSNumber numberWithUnsignedShort:y];
      [self sendPTPRequest:PTPOperationCodeGetDevicePropValue param1:PTPPropertyCodeNikonLiveViewProhibitCondition];
      [self sendPTPRequest:PTPOperationCodeNikonDeviceReady];
			break;
    }
	}
}

-(void)stopLiveView {
	PTPDeviceInfo *info = self.ptpDeviceInfo;
	switch (info.vendorExtension) {
    case PTPVendorExtensionNikon: {
      NSTimer *timer = self.userData[PTP_LIVE_VIEW_TIMER];
      [timer invalidate];
			[self sendPTPRequest:PTPOperationCodeNikonEndLiveView];
      [self sendPTPRequest:PTPOperationCodeNikonDeviceReady];
			break;
    }
	}
}

-(void)startCapture {
  PTPDeviceInfo *info = self.ptpDeviceInfo;
  switch (info.vendorExtension) {
    case PTPVendorExtensionNikon:
      if ([info.operationsSupported containsObject:[NSNumber numberWithUnsignedShort:PTPOperationCodeNikonInitiateCaptureRecInMedia]]) {
        [self sendPTPRequest:PTPOperationCodeNikonInitiateCaptureRecInMedia param1:-1 param2:0];
        [self sendPTPRequest:PTPOperationCodeNikonDeviceReady];
      }
      else
        [self requestTakePicture];
      break;
    default:
      [self requestTakePicture];
      break;
  }
}

-(void)stopCapture {
  PTPDeviceInfo *info = self.ptpDeviceInfo;
  switch (info.vendorExtension) {
    case PTPVendorExtensionNikon:
      [self sendPTPRequest:PTPOperationCodeNikonTerminateCapture param1:0 param2:0];
      [self sendPTPRequest:PTPOperationCodeNikonDeviceReady];
      break;
  }
}

-(void)focus:(int)steps {
  PTPDeviceInfo *info = self.ptpDeviceInfo;
  PTPProperty *afMode = info.properties[[NSNumber numberWithUnsignedShort:PTPPropertyCodeNikonLiveViewAFFocus]];
  if (afMode.value.intValue != 0) {
    [self setProperty:PTPPropertyCodeNikonLiveViewAFFocus value:@"0"];
  }
  if (steps >= 0) {
    [self sendPTPRequest:PTPOperationCodeNikonMfDrive param1:1 param2:steps];
  } else {
    [self sendPTPRequest:PTPOperationCodeNikonMfDrive param1:2 param2:-steps];
  }
}

- (void)setFrameLeft:(int)left top:(int)top width:(int)width height:(int)height {
  PTPDeviceInfo *info = self.ptpDeviceInfo;
  switch (info.vendorExtension) {
    case PTPVendorExtensionNikon: {
      [self sendPTPRequest:PTPOperationCodeNikonChangeAfArea param1:(left + width / 2) param2:(top + height/2)];
      break;
    }
  }
}

-(void)sendPTPRequest:(PTPOperationCode)operationCode {
  PTPOperationRequest *request = [[PTPOperationRequest alloc] initWithVendorExtension:self.ptpDeviceInfo.vendorExtension];
  request.operationCode = operationCode;
  request.numberOfParameters = 0;
  [self requestSendPTPCommand:request.commandBuffer outData:nil sendCommandDelegate:self didSendCommandSelector:@selector(didSendPTPCommand:inData:response:error:contextInfo:) contextInfo:(void *)CFBridgingRetain(request)];
}

-(void)sendPTPRequest:(PTPOperationCode)operationCode param1:(unsigned int)parameter1 {
  PTPOperationRequest *request = [[PTPOperationRequest alloc] initWithVendorExtension:self.ptpDeviceInfo.vendorExtension];
  request.operationCode = operationCode;
  request.numberOfParameters = 1;
  request.parameter1 = parameter1;
  [self requestSendPTPCommand:request.commandBuffer outData:nil sendCommandDelegate:self didSendCommandSelector:@selector(didSendPTPCommand:inData:response:error:contextInfo:) contextInfo:(void *)CFBridgingRetain(request)];
}

-(void)sendPTPRequest:(PTPOperationCode)operationCode param1:(unsigned int)parameter1 param2:(unsigned int)parameter2 {
  PTPOperationRequest *request = [[PTPOperationRequest alloc] initWithVendorExtension:self.ptpDeviceInfo.vendorExtension];
  request.operationCode = operationCode;
  request.numberOfParameters = 2;
  request.parameter1 = parameter1;
  request.parameter2 = parameter2;
  [self requestSendPTPCommand:request.commandBuffer outData:nil sendCommandDelegate:self didSendCommandSelector:@selector(didSendPTPCommand:inData:response:error:contextInfo:) contextInfo:(void *)CFBridgingRetain(request)];
}

-(void)sendPTPRequest:(PTPOperationCode)operationCode param1:(unsigned int)parameter1 withData:(NSData *)data {
  PTPOperationRequest *request = [[PTPOperationRequest alloc] initWithVendorExtension:self.ptpDeviceInfo.vendorExtension];
  request.operationCode = operationCode;
  request.numberOfParameters = 1;
  request.parameter1 = parameter1;
  [self requestSendPTPCommand:request.commandBuffer outData:data sendCommandDelegate:self didSendCommandSelector:@selector(didSendPTPCommand:inData:response:error:contextInfo:) contextInfo:(void *)CFBridgingRetain(request)];
}

@end

//------------------------------------------------------------------------------------------------------------------------------

@implementation PTPDelegate {
  ICDeviceBrowser* deviceBrowser;
}

- (void)deviceBrowser:(ICDeviceBrowser*)browser didAddDevice:(ICDevice*)camera moreComing:(BOOL)moreComing {
  camera.delegate = self;
  [self cameraAdded:(ICCameraDevice *)camera];
}

- (void)deviceBrowser:(ICDeviceBrowser*)browser didRemoveDevice:(ICDevice*)camera moreGoing:(BOOL)moreGoing {
  [self cameraRemoved:(ICCameraDevice *)camera];
}

- (void)device:(ICDevice*)camera didOpenSessionWithError:(NSError*)error {
  [(ICCameraDevice *)camera sendPTPRequest:PTPOperationCodeGetDeviceInfo];
}

- (void)device:(ICDevice*)camera didCloseSessionWithError:(NSError*)error {
  [self cameraDisconnected:(ICCameraDevice *)camera];
}

- (void)device:(ICDevice*)camera didEncounterError:(NSError*)error {
  NSLog(@"Error '%@' on '%@'", error.localizedDescription, camera.name);
}

- (void)cameraDevice:(ICCameraDevice*)camera didAddItem:(ICCameraItem*)item {
  if (item.class == ICCameraFile.class) {
    ICCameraFile *file = (ICCameraFile *)item;
    if (file.wasAddedAfterContentCatalogCompleted) {
      camera.userData[PTP_OBJECT_ADDED] = @TRUE;
      [camera requestDownloadFile:file options:@{ ICDeleteAfterSuccessfulDownload: @TRUE, ICOverwrite: @TRUE, ICDownloadsDirectoryURL: [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:true] } downloadDelegate:self didDownloadSelector:@selector(didDownloadFile:error:options:contextInfo:) contextInfo:nil];
    }
  }
}

- (void)didDownloadFile:(ICCameraFile*)file error:(nullable NSError*)error options:(nullable NSDictionary<NSString*,id>*)options contextInfo:(nullable void*)contextInfo {
  ICCameraDevice *camera = file.device;
  if (error == nil) {
    NSURL *folder = options[ICDownloadsDirectoryURL];
    NSString *name = options[ICSavedFilename];
    if (folder != nil && name != nil) {
      [self cameraFrame:camera left:0 top:0 width:-1 height:-1];
      NSURL *url = [NSURL URLWithString:name relativeToURL:folder];
      NSData *data = [NSData dataWithContentsOfURL:url];
			[self cameraExposureDone:camera data:data filename:name];
      [NSFileManager.defaultManager removeItemAtURL:url error:nil];
      return;
    }
  }
  [self cameraExposureFailed:camera message:[NSString stringWithFormat:@"requestDownloadFile failed (%@)", error.localizedDescription]];
}


-(void)didRemoveDevice:(ICDevice *)device {
	NSTimer *timer = ((ICCameraDevice *)device).userData[PTP_LIVE_VIEW_TIMER];
	[timer invalidate];
	timer = ((ICCameraDevice *)device).userData[PTP_EVENT_TIMER];
	[timer invalidate];
}

- (void)cameraDevice:(ICCameraDevice*)camera didReceivePTPEvent:(NSData*)eventData {
  PTPEvent *event = [[PTPEvent alloc] initWithData:eventData vendorExtension:camera.ptpDeviceInfo.vendorExtension];
  if (indigo_get_log_level() >= INDIGO_LOG_DEBUG)
    NSLog(@"Received %@", event);
  switch (camera.ptpDeviceInfo.vendorExtension) {
    case PTPVendorExtensionNikon: {
      break;
    }
    default: {
      [camera processEvent:event];
      break;
    }
  }
}

@end

//------------------------------------------------------------------------------------------------------------------------------
