#if USEOPENAL


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
#include <OpenAL/al.h>
#include <OpenAL/alc.h>
#import <AudioToolbox/AudioToolbox.h>

cvar_t bgmvolume = {"bgmvolume", "1", true};
cvar_t volume = {"volume", "0.7", true};
cvar_t loadas8bit = {"loadas8bit", "0"};

volatile dma_t* shm;

#define	MAX_SFX		512
sfx_t		*known_sfx;		// hunk allocated [MAX_SFX]
int			num_sfx;

static ALCdevice* _device;
static ALCcontext* _context;

#define AssertNoOALError(inMessage)					\
if ((result = alGetError()) != AL_NO_ERROR)			\
{													\
Sys_Error(inMessage, result);									\
}

typedef ALvoid	AL_APIENTRY	(*alBufferDataStaticProcPtr) (const ALint bid, ALenum format, ALvoid* data, ALsizei size, ALsizei freq);
ALvoid  alBufferDataStaticProc(const ALint bid, ALenum format, ALvoid* data, ALsizei size, ALsizei freq)
{
	static	alBufferDataStaticProcPtr	proc = NULL;
    
    if (proc == NULL) {
        proc = (alBufferDataStaticProcPtr) alcGetProcAddress(NULL, (const ALCchar*) "alBufferDataStatic");
    }
    
    if (proc)
        proc(bid, format, data, size, freq);
	
    return;
}

typedef ALvoid  AL_APIENTRY (*alcMacOSXMixerOutputRateProcPtr) (const ALdouble value);  
ALvoid  alcMacOSXMixerOutputRateProc(const ALdouble value)  
{  
    static  alcMacOSXMixerOutputRateProcPtr proc = NULL;  
	
    if (proc == NULL) {  
        proc = (alcMacOSXMixerOutputRateProcPtr) alcGetProcAddress(NULL, (const ALCchar*) "alcMacOSXMixerOutputRate");  
    }  
	
    if (proc)  
        proc(value);  
	
    return;  
} 

void S_Init (void)
{
	shm = (void *) Hunk_AllocName(sizeof(*shm), "shm");
	shm->splitbuffer = 0;
	shm->samplebits = 16;
	shm->speed = 22050;
	shm->channels = 2;
	shm->samples = 32768;
	shm->samplepos = 0;
	shm->soundalive = true;
	shm->gamealive = true;
	shm->submission_chunk = 1;
		
	known_sfx = Hunk_AllocName (MAX_SFX*sizeof(sfx_t), "sfx_t");
	num_sfx = 0;

	// Setup our audio session
	OSStatus result = AudioSessionInitialize(NULL, NULL, NULL, NULL);
	if (result) printf("Error initializing audio session! %d\n", (int)result);
	else {
		UInt32 category = kAudioSessionCategory_AmbientSound;
		result = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(category), &category);
		if (result) printf("Error setting audio session category! %d\n", (int)result);
		else {
			result = AudioSessionSetActive(true);
			if (result) printf("Error setting audio session active! %d\n", (int)result);
		}
	}
	
	// Create the OpenAL output device
	result = noErr;
	_device = alcOpenDevice(NULL);
	AssertNoOALError("Error %x opening output device")
	
	if (_device == NULL)
		Sys_Error("No Sound Engine");
	
	// Set the sample rate for the mixer
	alcMacOSXMixerOutputRateProc(22050);
	
	// Create an OpenAL Context and make it current
	_context = alcCreateContext(_device, NULL);
	AssertNoOALError("Error %x creating OpenAL context")
	
	alcMakeContextCurrent(_context);
	AssertNoOALError("Error %x setting current OpenAL context")	
	
	float listenerPosAL[] = {0, 0, 0.};
	// Move our listener coordinates
	alListenerfv(AL_POSITION, listenerPosAL);
	
	float ori[] = {cos(0 + M_PI_2), sin(0 + M_PI_2), 0., 0., 0., 1.};
	// Set our listener orientation (rotation)
	alListenerfv(AL_ORIENTATION, ori);
}

void S_AmbientOff (void)
{
}

void S_AmbientOn (void)
{
}

void S_Shutdown (void)
{
	alcMakeContextCurrent(NULL);
	
	if (_context)
		alcDestroyContext(_context);
	
	if (_device)
		alcCloseDevice(_device);	
}

sfx_t *S_FindName (char *name)
{
	int		i;
	sfx_t	*sfx;
	
	if (!name)
		Sys_Error ("S_FindName: NULL\n");
	
	if (Q_strlen(name) >= MAX_QPATH)
		Sys_Error ("Sound name too long: %s", name);
	
	// see if already loaded
	for (i=0 ; i < num_sfx ; i++)
		if (!Q_strcmp(known_sfx[i].name, name))
		{
			return &known_sfx[i];
		}
	
	if (num_sfx == MAX_SFX)
		Sys_Error ("S_FindName: out of sfx_t");
	
	sfx = &known_sfx[i];
	strcpy (sfx->name, name);
	
	num_sfx++;
	
	return sfx;
}

void S_TouchSound (char *name)
{
	sfx_t	*sfx;
	
	sfx = S_FindName (name);
	Cache_Check (&sfx->cache);
}

void S_ClearBuffer (void)
{
}

void BindBuffer(sfxcache_t* sc) {
	// Generate a buffer and copy the data into it
	alGenBuffers(1, &sc->bufferID);
	
	if (sc->stereo != 1)
		Sys_Error("Can only play mono samples");
	
	if (sc->width != 2)
		Sys_Error("Can only play 16bit samples");

	if (sc->speed != 22050)
		Sys_Error("Cannot only play 22Khz samples");
	
	alBufferDataStaticProc(sc->bufferID, AL_FORMAT_MONO16, sc->data, sc->length, sc->speed);
}


void S_StaticSound (sfx_t *sfx, vec3_t origin, float vol, float attenuation)
{
	if (!sfx)
		return;
	else
		return;
		
	sfxcache_t	*sc = S_LoadSound(sfx);
	if (!sc)
		return;

	// Static sounds always loop
	if (sc->loopstart == -1)
	{
		Con_Printf ("Sound %s not looped\n", sfx->name);
		return;
	}
	
	if (sc->bufferID == 0)
		BindBuffer(sc);
	
	// Generate a source that loops forever
	ALuint sourceID;
	alGenSources(1, &sourceID);
	alSourcei(sourceID, AL_LOOPING, AL_TRUE);
	
	// Set the origin and volume
	alSourcefv(sourceID, AL_POSITION, origin);	
	alSourcei(sourceID, AL_REFERENCE_DISTANCE, 50.0f);
	alSourcef(sourceID, AL_GAIN, vol);
	alSourcei(sourceID, AL_BUFFER, sc->bufferID);
	
	// Start the source playing
	alSourcePlay(sourceID);
}


void S_StartSound (int entnum, int entchannel, sfx_t *sfx, vec3_t origin, float fvol,  float attenuation)
{
	if (!sfx)
		return;
	
	if (entchannel > 1)
		return;

	sfxcache_t	*sc = S_LoadSound(sfx);
	if (!sc)
		return;
	
	if (sc->bufferID == 0)
		BindBuffer(sc);

	ALuint sourceID;
	
	alGenSources(1, &sourceID);
	
	alSourcefv(sourceID, AL_POSITION, origin);
	
	alSourcei(sourceID, AL_REFERENCE_DISTANCE, 50.0f);
	
	alSourcef(sourceID, AL_GAIN, fvol);
	alSourcei(sourceID, AL_BUFFER, sc->bufferID);

	alSourcePlay(sourceID);
}

void S_StopSound (int entnum, int entchannel)
{
}

sfx_t *S_PrecacheSound (char *name)
{
	sfx_t	*sfx;
	
//	if (strcmp(name, "weapons/grenade.wav"))
//		return;

	
	sfx = S_FindName (name);
	
	// cache it in
	//if (precache.value)
	sfxcache_t	*sc;
	
	sc = S_LoadSound (sfx);
	
	if (sc->bufferID == 0)
		BindBuffer(sc);
	
	return sfx;
}

void S_ClearPrecache (void)
{
}

void S_Update (vec3_t origin, vec3_t v_forward, vec3_t v_right, vec3_t v_up)
{	
	alListenerfv(AL_POSITION, origin);
}

void S_StopAllSounds (qboolean clear)
{
}

void S_BeginPrecaching (void)
{
}

void S_EndPrecaching (void)
{
}

void S_ExtraUpdate (void)
{
}

void S_LocalSound (char *s)
{
}

#endif