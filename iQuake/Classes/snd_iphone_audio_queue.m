#if !USEOPENAL
/*
Copyright (C) 1996-1997 Id Software, Inc.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/

#include "quakedef.h"
#include <AudioToolbox/AudioToolbox.h>

int snd_inited;

AudioStreamBasicDescription queueFormat;
AudioQueueRef audioQueue;
AudioQueueBufferRef audioQueueBuffer;

#define BUFFER_SIZE		8192

unsigned char dma_buffer[BUFFER_SIZE];
unsigned char pend_buffer[BUFFER_SIZE];
int pending;


static void HandleOutputBuffer (
								void                *aqData,
								AudioQueueRef       inAQ,
								AudioQueueBufferRef inBuffer
) {
	// Enqueue it for playing
	OSStatus status = AudioQueueEnqueueBuffer (audioQueue, audioQueueBuffer, 0, NULL);
	if (status != 0)
		Sys_Error("Unable to enqeue buffer - %d", status);
	
}


qboolean SNDDMA_Init(void)
{
	snd_inited = 0;
    
	shm = &sn;
    shm->splitbuffer = 0;
	shm->samplepos = 0;
	
	// Copy the fake DMA format into the Audio Queue format
	
    queueFormat.mSampleRate = 22050.0f;
	queueFormat.mFormatID = kAudioFormatLinearPCM;
    queueFormat.mFormatFlags = //kLinearPCMFormatFlagIsBigEndian
     kLinearPCMFormatFlagIsSignedInteger
    | kLinearPCMFormatFlagIsPacked;
    queueFormat.mBytesPerPacket = 4; //16 / 8 * 2;
    queueFormat.mFramesPerPacket = 1;
    queueFormat.mBytesPerFrame = 4; //16 / 8 * 2;
    queueFormat.mChannelsPerFrame = 2;
    queueFormat.mBitsPerChannel = 16;
    queueFormat.mReserved = 0;
	
	OSStatus status = AudioQueueNewOutput (
		&queueFormat,
		HandleOutputBuffer, //inCallbackProc,
		(void*)shm, //						  void                                *inUserData,
		CFRunLoopGetCurrent (), //		CFRunLoopRef                        inCallbackRunLoop,
		kCFRunLoopCommonModes, //		CFStringRef                         inCallbackRunLoopMode,
		0, //						  UInt32                              inFlags,
		&audioQueue//						  AudioQueueRef                       *outAQ
	);
	
	if (status != 0)
		Sys_Error("Unable to create audio queue - %d\r\n", status);
	

	// Allocate a buffer on the queue (use the same size as the fake dma buffer
	status = AudioQueueAllocateBuffer (audioQueue, 1 << 16, &audioQueueBuffer);
	if (status != 0)
		Sys_Error("Unable to allocate audio queue buffer - %d", status);
		
	status = AudioQueueStart(audioQueue, NULL);
	if (status != 0)
		Sys_Error("Unable to start audio queue");
		
	shm->samplebits = 16;
	shm->channels = 2;
	shm->soundalive = true;
	shm->samples = sizeof(dma_buffer) / (shm->samplebits/8);
	shm->samplepos = 0;
	shm->submission_chunk = 1;
	shm->buffer = (unsigned char *)dma_buffer;
	
	snd_inited = 1;
	
	return 1;
}



int SNDDMA_GetDMAPos(void)
{
	if (!snd_inited)
		return 0;

	return (shm->samples * shm->channels) % shm->channels;
}

void SNDDMA_Shutdown(void)
{
	if (snd_inited)
	{
		AudioQueueStop(audioQueue, true);
		
		// Release the Audio Queue objects
		AudioQueueFreeBuffer (audioQueue, audioQueueBuffer);
		AudioQueueDispose(audioQueue, true);
		
		snd_inited = 0;
	}
}

/*
==============
SNDDMA_Submit

Send sound to device if buffer isn't really the dma buffer
===============
*/
void SNDDMA_Submit(void)
{
	if (snd_inited == 0)
		return;
	
	// Copy the dma buffer..
	//memcpy(audioQueueBuffer->mAudioData, shm->buffer, audioQueueBuffer->mAudioDataByteSize);
	memcpy(audioQueueBuffer->mAudioData, shm->buffer, paintedtime);
	
}
#endif
