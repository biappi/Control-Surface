//
//  LogicControl.m
//  ControlSurface
//
//  Created by Antonio "Willy" Malara on 05/02/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LogicControl.h"

static void InputPortCallback (const MIDIPacketList *pktlist, void *refCon, void *connRefCon);
static char Mackie7SegDisplayCharToChar(uint8_t c, BOOL * dotted);

@interface LogicControl()

@property(nonatomic, assign)   BOOL       online;

@property(nonatomic, retain)   NSString * tcrCode;
@property(nonatomic, retain)   NSString * stripTop;
@property(nonatomic, retain)   NSString * stripBottom;

@property(nonatomic, readonly) uint8_t  * sysexPrefix;

- (void)createMidiClient;
- (void)disposeMidiClient;

- (BOOL)acceptsSysexWithPrefix:(uint8_t *)sysex;

- (void)sendHostConnectionQuery;
- (void)sendHostConnectionConfirmation;
- (void)sendVersionReply;

/* - */

- (void)sendNoteOn:(uint8_t)channel note:(uint8_t)note velocity:(uint8_t)velocity;

- (void)receivedNoteOnChannel:(uint8_t)channel note:(uint8_t)note velocity:(uint8_t)velocity;
- (void)receivedControlChangeChannel:(uint8_t)channel controller:(uint8_t)controller value:(uint8_t)value;
- (void)receivedChannelPressureChannel:(uint8_t)channel value:(uint8_t)value;
- (void)receivedPitchWheelChannel:(uint8_t)channel value:(uint16_t)value;
- (void)receivedSysEx:(uint8_t *)d;

- (void)sendMidiBytes:(uint8_t *)bytes count:(size_t)count;

@end

@implementation LogicControl

@synthesize name;
@synthesize online;
@synthesize tcrCode;
@synthesize stripTop;
@synthesize stripBottom;

- (id)init;
{
	return [self initWithName:@"LogicControl"];
}

- (id)initWithName:(NSString *)theName;
{
	if ((self = [super init]) == nil)
		return nil;
	
	name = [theName copy];
	
	memset(tcrCodeCString, 0x20, sizeof(tcrCodeCString));
	tcrCodeCString[sizeof(tcrCodeCString)-1] = 0;
	
	memset(stripTopCString, 0x20, sizeof(stripTopCString));
	stripTopCString[sizeof(stripTopCString)-1] = 0;
	
	memset(stripBottomCString, 0x20, sizeof(stripTopCString));
	stripBottomCString[sizeof(stripBottomCString)-1] = 0;
	
	[self createMidiClient];
	
	return self;
}

- (void)dealloc;
{
	[name release];
	[super dealloc];
}

- (void)createMidiClient;
{
	OSStatus    r;
	CFStringRef theName;
	
	theName = (CFStringRef)name;
	
	r = MIDIClientCreate(theName, NULL, NULL, &client);
	
	r = MIDISourceCreate(client, theName, &source);
	r = MIDIDestinationCreate(client, theName, InputPortCallback, self, &destination);
}

- (void)disposeMidiClient;
{
	// TODO
}

- (uint8_t)modelId;
{
	return 0x10;
}

- (uint8_t *)sysexPrefix;
{
	static uint8_t prefix[] = { 0xF0, 0x00, 0x00, 0x66, 0x10 };
	prefix[4] = self.modelId;
	return prefix;
}

- (BOOL)acceptsSysexWithPrefix:(uint8_t *)sysex;
{
	return (memcmp(sysex, self.sysexPrefix, 5) == 0);
}

- (void)prefixBufferWithSysex:(uint8_t *)buffer;
{
	memcpy(buffer, self.sysexPrefix, 5);
}

- (void)sendHostConnectionQuery;
{
	uint8_t reply[] =
	{
		0x00, 0x00, 0x00, 0x00, 0x00,      // Prefix
		0x01,                              // Host Connection Query
		'a', 'b', 'c', 'd', 'e', 'f', 'g', // Serial Number
		0x01, 0x02, 0x03, 0x04,            // Challenge Code
		0xF7                               // EOX
	};
	
	NSLog(@" -- SENDING MAKIE HOST CONNECTION QUERY MODEL");
	
	[self prefixBufferWithSysex:reply];
	[self sendMidiBytes:reply count:sizeof(reply)];
}

- (void)sendHostConnectionConfirmation;
{
	uint8_t reply[] =
	{
		0x00, 0x00, 0x00, 0x00, 0x00,      // Prefix
		0x03,                              // Connection Confirmation
		'a', 'b', 'c', 'd', 'e', 'f', 'g', // Serial Number
		0xF7                               // EOX
	};
	
	NSLog(@" -- SENDING MAKIE CONNECTION CONFIRMATION");
	
	[self prefixBufferWithSysex:reply];
	[self sendMidiBytes:reply count:sizeof(reply)];	
}

- (void)sendVersionReply;
{
	uint8_t reply[] =
	{
		0x00, 0x00, 0x00, 0x00, 0x00, // Prefix
		0x14,                         // Version Reply
		'a', 'b', 'c', 'd', '0',      // Version
		0xF7,                         // EOX
	};
	
	NSLog(@" -- SENDING MAKIE VERSION REPLY");
	
	[self prefixBufferWithSysex:reply];
	[self sendMidiBytes:reply count:sizeof(reply)];	
}

/* - */

- (void)buttonPress:(uint8_t)buttonId;
{
	[self sendNoteOn:0 note:buttonId velocity:127];
	[self sendNoteOn:0 note:buttonId velocity:0];
}

/* - */

- (void)sendNoteOn:(uint8_t)channel note:(uint8_t)note velocity:(uint8_t)velocity;
{
	unsigned char reply[] = { 0x90 | (channel & 0x0F), note, velocity };
	[self sendMidiBytes:reply count:sizeof(reply)];
}

// 0x9x
- (void)receivedNoteOnChannel:(uint8_t)channel note:(uint8_t)note velocity:(uint8_t)velocity;
{
	NSLog(@"Mackie Set Led %02x Status %02x", note, velocity);
}

// 0xBx
- (void)receivedControlChangeChannel:(uint8_t)channel controller:(uint8_t)controller value:(uint8_t)value;
{
	if ((controller & 0xF0) == 0x10)
	{
		NSLog(@"Mackie V-Pot %02x direction %02x delta %02x", controller, value & 0x40, value & 0x3F);
	}
	
	if ((controller & 0xF0) == 0x30)
	{
		NSLog(@"Mackie Set LED Ring %02x to %02x", controller, value);
	}
	
	if ((controller & 0xF0) == 0x40)
	{
		BOOL dotted;
		int  digit = controller & 0x0F;
		
		if (digit < 0x0C)
		{
			tcrCodeCString[11 - digit] = Mackie7SegDisplayCharToChar(value, &dotted);
			self.tcrCode = [NSString stringWithCString:tcrCodeCString encoding:NSUTF8StringEncoding];
			NSLog(@"Mackie TCR Display updated: %s", tcrCodeCString);
		}
		else if (digit < 0x0C)
		{
			NSLog(@"Mackie PN Display");
		}
		
		NSLog(@"Mackie TCR Display digit %02x char '%c'", controller, Mackie7SegDisplayCharToChar(value, &dotted));
	}
}

// 0xDx
- (void)receivedChannelPressureChannel:(uint8_t)channel value:(uint8_t)value;
{
	NSLog(@"Mackie Peak Level %02x", value);
}

// 0xEx
- (void)receivedPitchWheelChannel:(uint8_t)channel value:(uint16_t)value;
{
	NSLog(@"Mackie Fader Position %02x %04x", channel, value);
}

// 0xF0
- (void)receivedSysEx:(uint8_t *)d;
{	
	switch (d[5])
	{
		case 0x00:
			NSLog(@"Mackie Device Query Model");
			[self sendHostConnectionQuery];
			break;
		
		case 0x02:
			NSLog(@"Mackie Host Connection Reply %c%c%c%c%c%c%c %02x %02x %02x %02x", d[6], d[7], d[8], d[9], d[10], d[11], d[12], d[13], d[14], d[15], d[16]);
			[self sendHostConnectionConfirmation];
			break;
		
		case 0x10:
			NSLog(@"Not Impl: TCR LCD");
			break;
			
		case 0x12:
		{
			unsigned char   i   = d[6];
			unsigned char * src = &d[7];
			
			while (*src != 0xF7)
			{
				if (i < 56)
					stripTopCString[i] = *src;
				else
					stripBottomCString[i - 57] = *src;
				
				src++;
				i++;
			}
			
			self.stripTop = [NSString stringWithCString:stripTopCString encoding:NSUTF8StringEncoding];
			self.stripBottom = [NSString stringWithCString:stripBottomCString encoding:NSUTF8StringEncoding];
			
			if (0)
			{
				unsigned char pippo[0x70] = { 0 };
				unsigned char offset = d[6];
				
				unsigned char * src = &d[7];
				unsigned char * dst = pippo;
				
				while (*src != 0xF7)
					*(dst++) = *(src++);
				
				*dst = 0;
				
				NSLog(@"Mackie LCD Update, offset: %02x string: %s", offset, pippo);
			}
			break;
		}
			
		case 0x13:
			NSLog(@"Mackie Device Version Request");
			[self sendVersionReply];
			break;
		
		case 0x0A:
			NSLog(@"Mackie Transport Button Click %02x", d[6]);
			break;
		
		case 0x0B:
			NSLog(@"Mackie LCD Backlight saver %02x ", d[6]);
			break;
		
		case 0x0C:
			NSLog(@"Mackie Touchless movable fader %02x ", d[6]);
			break;
		
		case 0x0E:
			NSLog(@"Mackie Fader %02x touch sensitivity %02x ", d[6], d[7]);
			break;
		
		case 0x20:
		{
			char * lcd  = d[7] & 0x4 ? "LCD " : "----";
			char * peak = d[7] & 0x2 ? "PEAK" : "----";
			char * sign = d[7] & 0x1 ? "SIGN" : "----";
			
			NSLog(@"Mackie Channel %02x meter mode ( %s %s %s ) ", d[6], lcd, peak, sign);
			
			break;
		}
		
		case 0x21:
			NSLog(@"Mackie Global LCD Meter Mode %s", d[6] ? "verical" : "horizontal");
			break;
	}
}

- (void)sendMidiBytes:(uint8_t *)bytes count:(size_t)count;
{
	char packetListData[1024];
	
	MIDIPacketList * packetList = (MIDIPacketList *)packetListData;
	MIDIPacket     * curPacket  = NULL;
	
	curPacket = MIDIPacketListInit(packetList);
	curPacket = MIDIPacketListAdd(packetList, 1024, curPacket, 0, count, bytes);
	
	NSLog(@" >>> %@", [NSData dataWithBytes:bytes length:count]);
	
	MIDIReceived(source, packetList);
}

@end

static void InputPortCallback(const MIDIPacketList * pktlist, void * refCon, void * connRefCon)
{
	NSAutoreleasePool * pool   = [[NSAutoreleasePool alloc] init];
	MIDIPacket        * packet = (MIDIPacket *)pktlist->packet;
	LogicControl      * zelf   = (LogicControl *)refCon;
	
	for (unsigned int j = 0; j < pktlist->numPackets; j++)
	{
		uint8_t * d = packet->data;
		uint8_t   c = d[0] & 0xF0;
		
		switch (d[0] & 0xF0)
		{
			case 0x90:
				[zelf receivedNoteOnChannel:c note:d[1] velocity:d[2]];
				break;
			
			case 0xB0:
				[zelf receivedControlChangeChannel:c controller:d[1] value:d[2]];
				break;
			
			case 0xD0:
				[zelf receivedChannelPressureChannel:c value:(d[1] | (d[2] << 7))];
				break;
			
			case 0xF0:
				if ([zelf acceptsSysexWithPrefix:packet->data])
					[zelf receivedSysEx:packet->data];
				break;
		}
		
		packet = MIDIPacketNext(packet);		
	}
	
	[pool release];
}

static char Mackie7SegDisplayCharToChar(uint8_t c, BOOL * dotted)
{
	char r  = (c <  0x20) ? c + 0x40 : c;
	*dotted = (c >= 0x40);
	return (*dotted) ? r - 0x40 : c;
}
