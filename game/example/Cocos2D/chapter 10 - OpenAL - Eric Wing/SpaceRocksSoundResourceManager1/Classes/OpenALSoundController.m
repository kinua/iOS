//
//  OpenALSoundController.m
//  SpaceRocks
//
//  Created by Eric Wing on 7/11/09.
//  Copyright 2009 PlayControl Software, LLC. All rights reserved.
//

#import "OpenALSoundController.h"
#include "AudioSessionSupport.h"
#include "OpenALSupport.h"
#import "EWSoundBufferData.h"

#define MAX_NUMBER_OF_ALSOURCES 32

static void MyInterruptionCallback(void* user_data, UInt32 interruption_state)
{
	OpenALSoundController* openal_sound_controller = (OpenALSoundController*)user_data;
	if(kAudioSessionBeginInterruption == interruption_state)
	{
		openal_sound_controller.inInterruption = YES;
		alcSuspendContext(openal_sound_controller.openALContext);
		alcMakeContextCurrent(NULL);
	}
	else if(kAudioSessionEndInterruption == interruption_state)
	{
		OSStatus the_error = AudioSessionSetActive(true);
		if(noErr != the_error)
		{
			printf("Error setting audio session active! %d\n", the_error);
		}
		alcMakeContextCurrent(openal_sound_controller.openALContext);
		alcProcessContext(openal_sound_controller.openALContext);
		openal_sound_controller.inInterruption = NO;
	}
}

@implementation OpenALSoundController

@synthesize openALDevice;
@synthesize openALContext;
@synthesize inInterruption;
@synthesize soundCallbackDelegate;

#define PREFERRED_SAMPLE_OUTPUT_RATE 22050.0

// Singleton accessor.  this is how you should ALWAYS get a reference
// to the scene controller.  Never init your own. 
+ (OpenALSoundController*) sharedSoundController
{
	static OpenALSoundController* shared_sound_controller;
	@synchronized(self)
	{
		if(nil == shared_sound_controller)
		{
			shared_sound_controller = [[OpenALSoundController alloc] init];
		}
		return shared_sound_controller;
	}
	return shared_sound_controller;
}

- (id) init
{
	self = [super init];
	if(nil != self)
	{
		// Audio Session queries must be made after the session is setup
		InitAudioSession(kAudioSessionCategory_AmbientSound, MyInterruptionCallback, self, PREFERRED_SAMPLE_OUTPUT_RATE);
		soundFileDictionary = [[NSMutableDictionary alloc] init];
		[self initOpenAL];
		
	}
	return self;
}


- (void) initOpenAL
{
	openALDevice = alcOpenDevice(NULL);
	if(openALDevice != NULL)
	{
		// Use the Apple extension to set the mixer rate
		alcMacOSXMixerOutputRate(PREFERRED_SAMPLE_OUTPUT_RATE);
		
		// Create a new OpenAL Context
		// The new context will render to the OpenAL Device just created 
		openALContext = alcCreateContext(openALDevice, 0);
		if(openALContext != NULL)
		{
			// Make the new context the Current OpenAL Context
			alcMakeContextCurrent(openALContext);
		}
		else
		{
			NSLog(@"Error, could not create audio context.");
			return;
		}
	}
	else
	{
		NSLog(@"Error, could not get audio device.");
		return;
	}
	
	allSourcesArray = (ALuint*)calloc(MAX_NUMBER_OF_ALSOURCES, sizeof(ALuint));
	
	alGenSources(MAX_NUMBER_OF_ALSOURCES, allSourcesArray);

	availableSourcesCollection = [[NSMutableSet alloc] initWithCapacity:MAX_NUMBER_OF_ALSOURCES];
	inUseSourcesCollection = [[NSMutableSet alloc] initWithCapacity:MAX_NUMBER_OF_ALSOURCES];
	playingSourcesCollection = [[NSMutableSet alloc] initWithCapacity:MAX_NUMBER_OF_ALSOURCES];

	for(NSUInteger i=0; i<MAX_NUMBER_OF_ALSOURCES; i++)
	{
		[availableSourcesCollection addObject:[NSNumber numberWithUnsignedInt:allSourcesArray[i] ]];
	}	
}

- (void) tearDownOpenAL
{
	alSourceStopv(MAX_NUMBER_OF_ALSOURCES, allSourcesArray);
	alDeleteSources(MAX_NUMBER_OF_ALSOURCES, allSourcesArray);

	alcMakeContextCurrent(NULL);
	if(openALContext)
	{
		alcDestroyContext(openALContext);
		openALContext = NULL;
	}
	if(openALDevice)
	{
		alcCloseDevice(openALDevice);
		openALDevice = NULL;
	}
	
	[availableSourcesCollection release];
	[inUseSourcesCollection release];
	[playingSourcesCollection release];
}

- (void) dealloc
{
	[self tearDownOpenAL];
	[soundFileDictionary release];
	[super dealloc];
}


/**
 * Loads a sound file from the resource bundle and stores in a global dictionary.
 * File extensions looked for are caf, wav, aac, mp3, aiff, mp4, m4a.
 * If the file has already been loaded, it will be retrieved from the global dictionary.
 * @param sound_file_basename The basename of the file. It should not contain the file extension.
 * @return Returns an EWSoundBufferData object which is a simple data structure containing all the relevant
 * pieces we need.
 */
- (EWSoundBufferData*) soundBufferDataFromFileBaseName:(NSString*)sound_file_basename
{
	ALsizei data_size;
	ALenum al_format;
	ALsizei sample_rate;
	NSURL* file_url = nil;
	
	// First make sure the file hasn't already been loaded.
	EWSoundBufferData* sound_data = [soundFileDictionary valueForKey:sound_file_basename];
	if(nil != sound_data)
	{
		return sound_data;
	}
	
	// Create a temporary array that contains all the possible file extensions we want to handle.
	// Note: This list is not exhaustive of all the types Core Audio can handle.
	NSArray* file_extension_array = [[NSArray alloc] initWithObjects:@"caf", @"wav", @"aac", @"mp3", @"aiff", @"mp4", @"m4a", nil];
	for(NSString* file_extension in file_extension_array)
	{
		// We need to first check to make sure the file exists otherwise NSURL's initFileWithPath:ofType will crash if the file doesn't exist
		NSString* full_file_name = [NSString stringWithFormat:@"%@/%@.%@", [[NSBundle mainBundle] resourcePath], sound_file_basename, file_extension];
		if(YES == [[NSFileManager defaultManager] fileExistsAtPath:full_file_name])
		{
			file_url = [[NSURL alloc] initFileURLWithPath:[[NSBundle mainBundle] pathForResource:sound_file_basename ofType:file_extension]];
			break;
		}
	}
	[file_extension_array release];
	
	if(nil == file_url)
	{
		NSLog(@"Failed to locate audio file with basename: %@", sound_file_basename);
		return nil;
	}

	void* pcm_data_buffer = MyGetOpenALAudioDataAll((CFURLRef)file_url, &data_size, &al_format, &sample_rate);
	[file_url release];
	if(NULL == pcm_data_buffer)
	{
		NSLog(@"Failed to load audio data from file: %@", sound_file_basename);
		return nil;
	}

	sound_data = [[EWSoundBufferData alloc] init];	

	// Get the pcm data into the OpenAL buffer
	[sound_data bindDataBuffer:pcm_data_buffer withFormat:al_format dataSize:data_size sampleRate:sample_rate];
	
	// Put the data in a dictionary so we can find it by file name
	[soundFileDictionary setValue:sound_data forKey:sound_file_basename];
	return [sound_data autorelease];
}

// Must call reserveSource to get the source_id
- (void) playSound:(ALuint)source_id
{
	// Trusting the source_id passed in is valid
	[playingSourcesCollection addObject:[NSNumber numberWithUnsignedInt:source_id]];
	alSourcePlay(source_id);
}

- (void) stopSound:(ALuint)source_id
{
	// Trusting the source_id passed in is valid
	alSourceStop(source_id);
	alSourcei(source_id, AL_BUFFER, AL_NONE); // detach the buffer from the source
	// Remove from the playingSourcesCollection, no callback will be fired
	[playingSourcesCollection removeObject:[NSNumber numberWithUnsignedInt:source_id]];
	[self recycleSource:source_id];
}


- (BOOL) reserveSource:(ALuint*)source_id
{
	NSNumber* source_number;
	if([availableSourcesCollection count] == 0)
	{
		// No available sources
		return NO;
	}
	
	source_number = [availableSourcesCollection anyObject];
	
	[inUseSourcesCollection addObject:source_number];
	// Remember to remove the object last or the object may be destroyed before we finish changing the queues
	[availableSourcesCollection removeObject:source_number];
	
	*source_id = [source_number unsignedIntValue];
	return YES;
}

// Absolutely assumes that the source is not currently playing.
- (void) recycleSource:(ALuint)source_id
{
	NSNumber* source_number = [NSNumber numberWithUnsignedInt:source_id];

	// Remove from the inUse list
	[inUseSourcesCollection removeObject:source_number];
	
	// Add back to available sources list
	[availableSourcesCollection addObject:source_number];
}

// Should be called every frame to find out what's changed in the OpenAL state
- (void) update
{
	if(YES == inInterruption)
	{
		return;
	}
	alGetError(); // clear error
	NSMutableSet* items_to_be_purged_collection = [[NSMutableSet alloc] initWithCapacity:[playingSourcesCollection count]];
	for(NSNumber* current_number in playingSourcesCollection)
	{
		ALuint source_id = [current_number unsignedIntValue];
		ALenum source_state;
		alGetSourcei(source_id, AL_SOURCE_STATE, &source_state);
		if(AL_STOPPED == source_state)
		{
			alSourcei(source_id, AL_BUFFER, AL_NONE); // detach the buffer from the source
			// Because fast-enumeration is read-only on the enumerated container, we must save the values to be deleted later
			[items_to_be_purged_collection addObject:current_number];
		}
	}
	
	for(NSNumber* current_number in items_to_be_purged_collection)
	{
		// Remove from the playing list
		[playingSourcesCollection removeObject:current_number];

		[self recycleSource:[current_number unsignedIntValue]];
		if([self.soundCallbackDelegate respondsToSelector:@selector(soundDidFinishPlaying:)])
		{
			[self.soundCallbackDelegate soundDidFinishPlaying:current_number];
		}
	}
	
	[items_to_be_purged_collection release];
}

@end
