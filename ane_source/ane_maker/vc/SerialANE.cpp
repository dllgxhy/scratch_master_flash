/*
* Version: MPL 1.1
*
* The contents of this file are subject to the Mozilla Public License Version
* 1.1 (the "License"); you may not use this file except in compliance with
* the License. You may obtain a copy of the License at
* http://www.mozilla.org/MPL/
*
* Software distributed under the License is distributed on an "AS IS" basis,
* WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
* for the specific language governing rights and limitations under the
* License.
*
* The Original Code is SerialANE.c
*
* The Initial Developer of the Original Code is Nicholas Kwiatkowski.
* Portions created by the Initial Developer are Copyright (C) 2011
* the Initial Developer. All Rights Reserved.
*
* The Assistant Developer is Ellis Elkins on behalf of DirectAthletics.
* Portions created by the Assistant Developer are Copyright (C) 2013
* DirectAthletics. All Rights Reserved.
*
*/

#include "SerialANE.h"

#include "stdio.h"
#include "pthread.h"
#include "stdlib.h"
#include "stdint.h"
#include "String.h"
#include "rs232.h"

#include "FlashRuntimeExtensions.h"

#ifdef _WIN32
uint32_t isSupportedInOS = 1;
#else
uint32_t isSupportedInOS = 0;
#endif

FREContext dllContext;
pthread_t ptrToThread;
unsigned char buffer[4096];
int bufferSize;
int32_t comPort;
int baud;
int sentEvent;

pthread_mutex_t safety = PTHREAD_MUTEX_INITIALIZER;

void multiplatformSleep(int time)
{
#ifdef _WIN32
	Sleep(time); // windows delay timer
#else
	usleep(time); // POSIX/Unix/Mac delay timer
#endif
}

void *pollForData(void *)
{
	unsigned char incomingBuffer[4096];
	int incomingBufferSize = 0;
	uint8_t prevCollection = 0;

	while (1)
	{
		multiplatformSleep(2);   // used only for testing.  I want manageable loops, not crazy ones.
		                          //从10ms缩短到2ms，可以提高通信速率_wh
		incomingBufferSize = PollComport(comPort, incomingBuffer, 4095);
		if (incomingBufferSize > 0)
		{
			pthread_mutex_lock(&safety);
			memcpy(buffer + bufferSize, incomingBuffer, incomingBufferSize);
			bufferSize = bufferSize + incomingBufferSize;
			buffer[bufferSize] = 0;
			pthread_mutex_unlock(&safety);
			prevCollection = 1;
		}
		else
		{
			prevCollection = 0;
		}

		if ((sentEvent == 0) && (((prevCollection == 0) && (bufferSize > 0)) || (bufferSize > 1024)))
		{
			sentEvent = 1;
			FREDispatchStatusEventAsync(dllContext, (uint8_t*) "bufferHasData", (const uint8_t*) "INFO");
		}
		else
			if (sentEvent == 1)
			{
				multiplatformSleep(200);//从500ms减到200ms_wh
				sentEvent = 0;
			}
	}
	return NULL;
}

//检测当前串口是否可用，修改了原先功能_wh
FREObject isSupported(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[])
{
	HANDLE hCom;
	int32_t comPort_t;
	char  cPortName[11];
	FREObject result;
	FREGetObjectAsInt32(argv[0], &comPort_t);//从as获取信息_wh
	sprintf(cPortName, "\\\\.\\COM%i", comPort_t);
	hCom = CreateFileA(cPortName,
		GENERIC_READ | GENERIC_WRITE,
		0,                          /* no share  */
		NULL,                       /* no security */
		OPEN_EXISTING,
		0,                          /* no threads */
		NULL);                      /* no templates */;
	if (hCom == INVALID_HANDLE_VALUE)
	{
		FRENewObjectFromBool(0, &result);
	}
	else
	{
		FRENewObjectFromBool(1, &result);
		CloseHandle(hCom);
		hCom = INVALID_HANDLE_VALUE;
	}
	return result;
}

FREObject getBytesAsArray(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[])
{
	FREObject result;

	FRENewObject((const uint8_t*) "Array", 0, NULL, &result, NULL);
	FRESetArrayLength(result, bufferSize - 1);

	FREObject myChar;
	int i;

	pthread_mutex_lock(&safety);
	for (i = 0; i < bufferSize; i++)
	{
		FRENewObjectFromUTF8(1, (unsigned char *)buffer + i, &myChar);
		FRESetArrayElementAt(result, i, myChar);
	}

	bufferSize = 0;
	sentEvent = 0;
	pthread_mutex_unlock(&safety);

	return result;
}

FREObject getBytesAsString(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[])
{
	FREObject result;

	pthread_mutex_lock(&safety);
	FRENewObjectFromUTF8(bufferSize, (unsigned char *)buffer, &result);
	bufferSize = 0;
	sentEvent = 0;
	pthread_mutex_unlock(&safety);

	return result;
}

FREObject getBytesAsByteArray(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[])
{
	FREObject result;
	FREByteArray incomingBytes;

	FREAcquireByteArray(argv[0], &incomingBytes);

	pthread_mutex_lock(&safety);
	memcpy(incomingBytes.bytes, buffer, bufferSize);
	FRENewObjectFromInt32(bufferSize, &result);
	bufferSize = 0;
	sentEvent = 0;
	pthread_mutex_unlock(&safety);

	FREReleaseByteArray(&incomingBytes);

	return result;
}

FREObject getByte(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[])
{
	FREObject result;

	pthread_mutex_lock(&safety);
	FRENewObjectFromUint32(buffer[0], &result);
	memcpy(buffer, buffer + 1, bufferSize - 1);
	bufferSize--;
	if (bufferSize == 0)
	{
		sentEvent = 0;
	}
	pthread_mutex_unlock(&safety);

	return result;
}

//缓存区数据量_wh
FREObject getAvailableBytes(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[])
{
	FREObject result;
	pthread_mutex_lock(&safety);//开启线程互斥锁_wh
	FRENewObjectFromInt32(bufferSize, &result);//赋予result为as实例_wh
	pthread_mutex_unlock(&safety);//关闭线程互斥锁_wh
	return result;
}

FREObject sendByte(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[])
{
	FREObject result;

	uint32_t dataToSend;
	int sendResult = 0;

	FREGetObjectAsUint32(argv[0], &dataToSend);

	sendResult = SendByte(comPort, (unsigned char)dataToSend);

	if (sendResult == -1)
	{
		FRENewObjectFromBool(0, &result);
	}
	else
	{
		FRENewObjectFromBool(1, &result);
	}
	return result;
}

FREObject sendString(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[])
{
	FREObject result;

	uint32_t lengthToSend;
	const uint8_t *dataToSend;
	int sendResult = 0;

	FREGetObjectAsUTF8(argv[0], &lengthToSend, &dataToSend);

	sendResult = SendBuf(comPort, (unsigned char *)dataToSend, lengthToSend);

	if (sendResult == -1)
	{
		FRENewObjectFromBool(0, &result);
	}
	else
	{
		FRENewObjectFromBool(1, &result);
	}
	return result;
}

FREObject sendByteArray(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[])
{
	FREObject result;
	FREByteArray dataToSend;
	int sendResult = 0;

	FREAcquireByteArray(argv[0], &dataToSend);

	sendResult = SendBuf(comPort, (unsigned char *)&dataToSend.bytes, dataToSend.length);

	FREReleaseByteArray(argv[0]);

	if (sendResult == -1)
	{
		FRENewObjectFromBool(0, &result);
	}
	else
	{
		FRENewObjectFromBool(1, &result);
	}
	return result;
}

//设置并开启串口_wh
FREObject setupPort(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[])
{
	FREObject result;
	int comPortError = 0;
	int useDtrControl;

	FREGetObjectAsInt32(argv[0], &comPort);//从as获取信息_wh
	FREGetObjectAsInt32(argv[1], &baud);
	FREGetObjectAsInt32(argv[2], &useDtrControl);

	bufferSize = 0;

	comPortError = OpenComport(comPort, baud, useDtrControl);
	if (comPortError == 0)
	{
		//pthread_cancel(ptrToThread);//杀掉该线程，以免重新开启串口时之前线程残留_wh
		multiplatformSleep(20);//从100ms减到20ms，与as呼应，避免响应不对应_wh
		pthread_create(&ptrToThread, NULL, pollForData, NULL);
		FRENewObjectFromBool(1, &result);
	}
	else
	{
		FRENewObjectFromBool(0, &result);
	}

	return result;
}

FREObject closePort(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[])
{
	FREObject result;

	CloseComport(comPort);
	FRENewObjectFromBool(1, &result);

	return result;
}

void contextInitializer(void* extData, const uint8_t* ctxType, FREContext ctx, uint32_t* numFunctions, const FRENamedFunction** functions)
{
	*numFunctions = 11;
	FRENamedFunction* func = (FRENamedFunction*)malloc(sizeof(FRENamedFunction)* (*numFunctions));

	func[0].name = (const uint8_t*) "isSupported";
	func[0].functionData = NULL;
	func[0].function = &isSupported;

	func[1].name = (const uint8_t*) "getBytesAsArray";
	func[1].functionData = NULL;
	func[1].function = &getBytesAsArray;

	func[2].name = (const uint8_t*) "sendString";
	func[2].functionData = NULL;
	func[2].function = &sendString;

	func[3].name = (const uint8_t*) "setupPort";
	func[3].functionData = NULL;
	func[3].function = &setupPort;

	func[4].name = (const uint8_t*) "getBytesAsString";
	func[4].functionData = NULL;
	func[4].function = &getBytesAsString;

	func[5].name = (const uint8_t*) "sendByteArray";
	func[5].functionData = NULL;
	func[5].function = &sendByteArray;

	func[6].name = (const uint8_t*) "getBytesAsByteArray";
	func[6].functionData = NULL;
	func[6].function = &getBytesAsByteArray;

	func[7].name = (const uint8_t*) "getByte";
	func[7].functionData = NULL;
	func[7].function = &getByte;

	func[8].name = (const uint8_t*) "sendByte";
	func[8].functionData = NULL;
	func[8].function = &sendByte;

	func[9].name = (const uint8_t*) "getAvailableBytes";
	func[9].functionData = NULL;
	func[9].function = &getAvailableBytes;

	func[10].name = (const uint8_t*) "closePort";
	func[10].functionData = NULL;
	func[10].function = &closePort;

	*functions = func;

	dllContext = ctx;
	sentEvent = 0;
}

void contextFinalizer(FREContext ctx)
{
	pthread_cancel(ptrToThread);
	CloseComport(comPort);
	return;
}

void SerialANEinitializer(void** extData, FREContextInitializer* ctxInitializer, FREContextFinalizer* ctxFinalizer)
{
	*ctxInitializer = &contextInitializer;
	*ctxFinalizer = &contextFinalizer;
}

void SerialANEfinalizer(void* extData)
{
	FREContext nullCTX;
	nullCTX = 0; //We want to point to the current contex.
	contextFinalizer(nullCTX);
	return;
}

