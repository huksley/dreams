Unit flplay;

interface

procedure playfli(filename:string);

implementation

USES SwSet,DOSFunctions,misc,fx_mouse;

VAR
	FLCWidth: WORD;
	FLCHeight: WORD;

CONST
	FLCChunkColor256 = 4;
	FLCChunkSS2 = 7;
	FLCChunkColor = 11;
	FLCChunkLC = 12;
	FLCChunkBlack = 13;
	FLCChunkBRun = 15;
	FLCChunkCopy = 16;
	FLCChunkPStamp = 18;

	FLCChunkPrefix = $F100;
	FLCChunkFrame = $F1FA;

	FLCFileMagicFLI = $AF11;
	FLCFileMagicFLC = $AF12;

CONST
	errReadingFile: STRING[19] = 'Error reading file!';
	errOpeningFile: STRING[19] = 'Error opening file!';
	errInvalidFile: STRING[17] = 'Invalid FLC file!';
	errUnsupportedBigFile: STRING[24] = 'Resolution is too large!';
	errEmptyFile: STRING[15] = 'Empty FLC file!';
	errSubChunkTooBig: STRING[42] = 'Frame''s SubChunk in FLC file is too large!';

TYPE
	PFLCHeader = ^TFLCHeader;
	TFLCHeader = RECORD
		FileSize: LONGINT;
		FileMagic: WORD;
		FramesCount: WORD;
		ScreenWidth: WORD;
		ScreenHeight: WORD;
		ScreenDepth: WORD;
		Flags: WORD;
		PlaybackSpeed: LONGINT;
		Reserved1: WORD;
		CreationDate: LONGINT;
		Creator: ARRAY[1..4] OF CHAR;
		UpdateDate: LONGINT;
		Updater: ARRAY[1..4] OF CHAR;
		ScreenAspectx: WORD;
		ScreenAspecty: WORD;
		Reserved2: ARRAY[1..38] OF BYTE;
		OffsetFrame1: LONGINT;
		OffsetFrame2: LONGINT;
		Reserved3: ARRAY[1..40] OF BYTE;
	END;

	PFLCChunk = ^TFLCChunk;
	TFLCChunk = RECORD
		ChunkSize: LONGINT;
		ChunkType: WORD;
		SubChunksCount: WORD;
		Reserved1: ARRAY[1..8] OF BYTE;
	END;

	PFLCSubChunk = ^TFLCSubChunk;
	TFLCSubChunk = RECORD
		ChunkSize: LONGINT;
		ChunkType: WORD;
	END;

PROCEDURE ProcessChunkColor256(Data: POINTER);
ASSEMBLER;
ASM
	CLD
	PUSH DS
	LDS SI,[Data]

	LODSW
	CMP AX,0
	JE @@Done

	MOV DI,AX
	XOR BL,BL

@@PacketProcessLoop:
	LODSW
	ADD BL,AL

	MOV CL,AH
	XOR CH,CH
	CMP CX,0
	JA @@ColorElementFill

	INC CH

@@ColorElementFill:
	MOV DX,3C8H
	MOV AL,BL
	OUT DX,AL

	MOV DX,3C9H
	LODSW
	SHR AL,2
	SHR AH,2
	OUT DX,AL
	MOV AL,AH
	OUT DX,AL
	LODSB
	SHR AL,2
	OUT DX,AL

	INC BL
	LOOP @@ColorElementFill

	DEC DI
	JNZ @@PacketProcessLoop

@@Done:
	POP DS
END;

PROCEDURE ProcessChunkColor(Data: POINTER);
ASSEMBLER;
ASM
	CLD
	PUSH DS
	LDS SI,[Data]

	LODSW
	CMP AX,0
	JE @@Done

	MOV DI,AX
	XOR BL,BL

@@PacketProcessLoop:
	LODSW
	ADD BL,AL

	MOV CL,AH
	XOR CH,CH
	CMP CX,0
	JA @@ColorElementFill

	INC CH

@@ColorElementFill:
	MOV DX,3C8H
	MOV AL,BL
	OUT DX,AL

	MOV DX,3C9H
	LODSW
	OUT DX,AL
	MOV AL,AH
	OUT DX,AL
	LODSB
	OUT DX,AL

	INC BL
	LOOP @@ColorElementFill

	DEC DI
	JNZ @@PacketProcessLoop

@@Done:
	POP DS
END;

PROCEDURE ProcessChunkBlack(Data: POINTER; Offsetx,Offsety: INTEGER; wx1,wy1,wx2,wy2: INTEGER);
ASSEMBLER;
ASM
	CLD

	INC [wx2]
	INC [wy2]
	MOV CX,[FLCWidth]
	MOV SI,[Offsetx]
	MOV DX,CX
	ADD DX,SI
	CMP DX,[wx1]
	JL @@Done

	CMP SI,[wx2]
	JG @@Done

	CMP SI,[wx1]
	JGE @@NoClipLeft

	MOV BX,[wx1]
	SUB BX,SI
	SUB CX,BX
	MOV SI,[wx1]

@@NoClipLeft:
	CMP DX,[wx2]
	JLE @@NoClipRight

	MOV BX,DX
	SUB BX,[wx2]
	SUB CX,BX

@@NoClipRight:
	MOV DX,[FLCHeight]
	MOV DI,[Offsety]
	MOV AX,DX
	ADD AX,DI
	CMP AX,[wy1]
	JL @@Done

	CMP DI,[wy2]
	JG @@Done

	CMP DI,[wy1]
	JGE @@NoClipTop

	MOV BX,[wy1]
	SUB BX,DI
	SUB DX,BX
	MOV DI,[wy1]

@@NoClipTop:
	CMP AX,[wy2]
	JLE @@NoClipBottom

	MOV BX,AX
	SUB BX,[wy2]
	SUB DX,BX

@@NoClipBottom:
	MOV BX,320
	SUB BX,CX

	PUSH DX
	MOV AX,SegA000
	MOV ES,AX
	MOV AX,320
	MUL DI
	ADD AX,SI
	MOV DI,AX
	POP DX
	MOV SI,CX
	XOR AX,AX

@@FillLoop:
	MOV CX,SI
	SHR CX,1
	JNC @@DoWords

	STOSB

@@DoWords:
	REP STOSW

	ADD DI,BX
	DEC DX
	JNZ @@FillLoop

@@Done:
END;

PROCEDURE ProcessChunkCopy(Data: POINTER; Offsetx,Offsety: INTEGER; wx1,wy1,wx2,wy2: INTEGER);
ASSEMBLER;
VAR
	iox,ioy: WORD;
ASM
	PUSH DS
	CLD

	INC [wx2]
	INC [wy2]
	MOV [iox],0
	MOV [ioy],0
	MOV CX,[FLCWidth]
	MOV SI,[Offsetx]
	MOV DX,CX
	ADD DX,SI
	CMP DX,[wx1]
	JL @@Done

	CMP SI,[wx2]
	JG @@Done

	CMP SI,[wx1]
	JGE @@NoClipLeft

	MOV BX,[wx1]
	SUB BX,SI
	ADD [iox],BX
	SUB CX,BX
	MOV SI,[wx1]

@@NoClipLeft:
	CMP DX,[wx2]
	JLE @@NoClipRight

	MOV BX,DX
	SUB BX,[wx2]
	SUB CX,BX

@@NoClipRight:
	MOV DX,[FLCHeight]
	MOV DI,[Offsety]
	MOV AX,DX
	ADD AX,DI
	CMP AX,[wy1]
	JL @@Done

	CMP DI,[wy2]
	JG @@Done

	CMP DI,[wy1]
	JGE @@NoClipTop

	MOV BX,[wy1]
	SUB BX,DI
	ADD [ioy],BX
	SUB DX,BX
	MOV DI,[wy1]

@@NoClipTop:
	CMP AX,[wy2]
	JLE @@NoClipBottom

	MOV BX,AX
	SUB BX,[wy2]
	SUB DX,BX

@@NoClipBottom:
	MOV BX,320
	SUB BX,CX

	PUSH BP
	PUSH DX
	MOV AX,SegA000
	MOV ES,AX
	MOV AX,320
	MUL DI
	ADD AX,SI
	MOV DI,AX
	MOV AX,[ioy]
	MUL [FLCWidth]
	ADD AX,[iox]
	MOV DX,[FLCWidth]
	SUB DX,CX
	LDS SI,[Data]
	ADD SI,AX
	MOV BP,DX
	POP DX
	MOV AX,CX

@@CopyLoop:
	MOV CX,AX
	SHR CX,1
	JNC @@DoWords

	MOVSB

@@DoWords:
	REP MOVSW

	ADD DI,BX
	ADD SI,BP
	DEC DX
	JNZ @@CopyLoop

	POP BP

@@Done:
	POP DS
END;

PROCEDURE ProcessChunkLC(Data: POINTER; Offsetx,Offsety: INTEGER; wx1,wy1,wx2,wy2: INTEGER);
ASSEMBLER;
VAR
	LeftLimit: WORD;
	RightLimit: WORD;
	VerticalCount: WORD;
	x,y: WORD;
	FrameWidth: WORD;
	Increment: WORD;
	PacketsLeft: BYTE;
	DISave: WORD;
ASM
	CLD
	PUSH DS

	INC [wx2]
	INC [wy2]
	MOV AX,[FLCWidth]
	MOV [FrameWidth],AX

	LDS SI,[Data]

	LODSW
	MOV CX,[DS:SI]
	ADD SI,2
	ADD AX,[Offsety]
	MOV BX,AX
	ADD AX,CX
	MOV [y],BX
	XOR DX,DX

	CMP AX,[wy1]
	JL @@Done

	CMP BX,[wy2]
	JG @@Done

	CMP BX,[wy1]
	JGE @@NoTopClip

	MOV DX,[wy1]
	MOV [y],DX
	SUB DX,BX
	SUB CX,DX

@@NoTopClip:
	CMP AX,[wy2]
	JLE @@NoBottomClip

	SUB AX,[wy2]
	SUB CX,AX

@@NoBottomClip:
	MOV [VerticalCount],CX

	CMP DX,0
	JE @@NoPass

	XOR CH,CH

@@PassLoop:
	INC SI
	MOV CL,[DS:SI-1]
	JCXZ @@PassNextLine

@@PassLoopLoadPacket:
	LODSW
	CMP AH,0
	JL @@PassLoopReplicateData

@@PassLoopCopyData:
	MOV AL,AH
	XOR AH,AH
	ADD SI,AX
	LOOP @@PassLoopLoadPacket

	JMP @@PassNextLine

@@PassLoopReplicateData:
	INC SI
	LOOP @@PassLoopLoadPacket

@@PassNextLine:
	DEC DX
	JNZ @@PassLoop

@@NoPass:
	MOV [LeftLimit],0
	MOV CX,[FrameWidth]
	MOV BX,[Offsetx]
	MOV AX,BX
	ADD AX,CX
	MOV [x],BX

	CMP AX,[wx1]
	JL @@Done

	CMP BX,[wx2]
	JG @@Done

	CMP BX,[wx1]
	JGE @@NoLeftClip

	MOV DX,[wx1]
	MOV [x],DX
	SUB DX,BX
	SUB CX,DX
	MOV [LeftLimit],DX

@@NoLeftClip:
	CMP AX,[wx2]
	JLE @@NoRightClip

	SUB AX,[wx2]
	SUB CX,AX

@@NoRightClip:
	ADD CX,[LeftLimit]
	MOV [RightLimit],CX

	MOV AX,SegA000
	MOV ES,AX
	MOV AX,320
	MUL [y]
	ADD AX,[Offsetx]
	MOV [DISave],AX

@@DrawLoop:
	LODSB
	MOV [PacketsLeft],AL
	XOR DX,DX

@@LoadPacketLoop:
	MOV DI,[DISave]

	CMP [PacketsLeft],0
	JE @@NextLine

	DEC [PacketsLeft]

	XOR CH,CH
	LODSW
	CMP AH,0
	JL @@ReplicateData

@@CopyData:
	MOV CL,AH
	JCXZ @@LoadPacketLoop

	XOR AH,AH
	ADD DX,AX

	MOV BX,DX
	ADD DX,CX
	MOV AX,BX

	CMP AX,[RightLimit]
	JL @@NoLoadAndDropCopy

	ADD SI,CX
	JMP @@PacketPassLoop

@@NoLoadAndDropCopy:
	MOV [Increment],0
	CMP AX,[LeftLimit]
	JGE @@NoLeftClipCopy

	ADD AX,CX
	CMP AX,[LeftLimit]
	JGE @@NotEmpty

	ADD SI,CX
	JMP @@LoadPacketLoop

@@NotEmpty:
	MOV AX,[LeftLimit]
	SUB AX,BX
	SUB CX,AX
	ADD BX,AX
	ADD SI,AX

@@NoLeftClipCopy:
	MOV AX,BX
	ADD AX,CX
	CMP AX,[RightLimit]
	JLE @@DoCopy

	SUB AX,[RightLimit]
	SUB CX,AX
	MOV [Increment],AX

@@DoCopy:
	ADD DI,BX
	SHR CX,1
	JNC @@DoWords1

	MOVSB

@@DoWords1:
	REP MOVSW
	ADD SI,[Increment]
	JMP @@LoadPacketLoop

@@ReplicateData:
	NEG AH
	MOV CL,AH
	XOR AH,AH
	ADD DX,AX

	INC SI

	MOV BX,DX
	ADD DX,CX
	MOV AX,BX

	CMP AX,[RightLimit]
	JGE @@PacketPassLoop

	CMP AX,[LeftLimit]
	JGE @@NoLeftClipRepl

	ADD AX,CX
	CMP AX,[LeftLimit]
	JL @@LoadPacketLoop

	MOV AX,[LeftLimit]
	SUB AX,BX
	SUB CX,AX
	ADD BX,AX

@@NoLeftClipRepl:
	MOV AX,BX
	ADD AX,CX
	CMP AX,[RightLimit]
	JLE @@DoReplicate

	SUB AX,[RightLimit]
	SUB CX,AX

@@DoReplicate:
	ADD DI,BX
	MOV AL,[DS:SI-1]
	MOV AH,AL
	SHR CX,1
	JNC @@DoWords2

	STOSB

@@DoWords2:
	REP STOSW
	JMP @@LoadPacketLoop

@@NextLine:
	ADD [DISave],320
	DEC [VerticalCount]
	JNZ @@DrawLoop

	JMP @@Done

@@PacketPassLoop:
	CMP [PacketsLeft],0
	JE @@NextLine

	DEC [PacketsLeft]

	LODSW
	CMP AH,0
	JL @@LoadAndDropReplicateData

@@LoadAndDropCopyData:
	MOV CL,AH
	ADD SI,CX
	JMP @@PacketPassLoop

@@LoadAndDropReplicateData:
	INC SI
	JMP @@PacketPassLoop

@@Done:
	POP DS
END;

PROCEDURE ProcessChunkBRun(Data: POINTER; Offsetx,Offsety: INTEGER; wx1,wy1,wx2,wy2: INTEGER);
ASSEMBLER;
VAR
	TopPass: WORD;
	LeftLimit: WORD;
	RightLimit: WORD;
	VerticalCount: WORD;
	FrameWidth: WORD;
	Increment: WORD;
	x,y: WORD;
ASM
	CLD
	PUSH DS

	INC [wx2]
	INC [wy2]
	MOV AX,[FLCWidth]
	MOV [FrameWidth],AX

	MOV [TopPass],0
	MOV CX,[FLCHeight]
	MOV BX,[Offsety]
	MOV AX,BX
	ADD AX,CX
	MOV [y],BX

	CMP AX,[wy1]
	JL @@Done

	CMP BX,[wy2]
	JG @@Done

	CMP BX,[wy1]
	JGE @@NoTopClip

	MOV DX,[wy1]
	MOV [y],DX
	SUB DX,BX
	SUB CX,DX
	MOV [TopPass],DX

@@NoTopClip:
	CMP AX,[wy2]
	JLE @@NoBottomClip

	SUB AX,[wy2]
	SUB CX,AX

@@NoBottomClip:
	MOV [VerticalCount],CX

	MOV [LeftLimit],0
	MOV CX,[FLCWidth]
	MOV BX,[Offsetx]
	MOV AX,BX
	ADD AX,CX
	MOV [x],BX

	CMP AX,[wx1]
	JL @@Done

	CMP BX,[wx2]
	JG @@Done

	CMP BX,[wx1]
	JGE @@NoLeftClip

	MOV DX,[wx1]
	MOV [x],DX
	SUB DX,BX
	SUB CX,DX
	MOV [LeftLimit],DX

@@NoLeftClip:
	CMP AX,[wx2]
	JLE @@NoRightClip

	SUB AX,[wx2]
	SUB CX,AX

@@NoRightClip:
	MOV [RightLimit],CX

	MOV BX,[FLCWidth]
	LDS SI,[Data]

	MOV DI,[TopPass]
	CMP DI,0
	JE @@NoPass

	XOR AH,AH

@@PassLoop:
	XOR DX,DX
	INC SI

@@PassLoopLoadPacket:
	LODSB
	CMP AL,0
	JGE @@PassLoopReplicateData

@@PassLoopCopyData:
	NEG AL
	ADD SI,AX
	JMP @@PassLoopLoadNext

@@PassLoopReplicateData:
	INC SI

@@PassLoopLoadNext:
	ADD DX,AX
	CMP DX,BX
	JB @@PassLoopLoadPacket

	DEC DI
	JNZ @@PassLoop

@@NoPass:
	MOV AX,[LeftLimit]
	ADD [RightLimit],AX

	MOV AX,SegA000
	MOV ES,AX
	MOV AX,320
	MUL [y]
	MOV DI,AX
	XOR CH,CH

@@DrawLoop:
	PUSH DI
	ADD DI,[x]
	XOR DX,DX
	INC SI

@@LoadPacketLoop:
	CMP DX,[FrameWidth]
	JAE @@NextLine

	XOR CH,CH
	LODSB
	CMP AL,0
	JGE @@ReplicateData

@@CopyData:
	NEG AL
	MOV CL,AL

	MOV BX,DX
	ADD DX,CX
	MOV AX,BX

	CMP AX,[RightLimit]
	JL @@NoLoadAndDropCopy

	ADD SI,CX
	JMP @@PacketPassLoop

@@NoLoadAndDropCopy:
	MOV [Increment],0
	CMP AX,[LeftLimit]
	JGE @@NoLeftClipCopy

	ADD AX,CX
	CMP AX,[LeftLimit]
	JGE @@NotEmpty

	ADD SI,CX
	JMP @@LoadPacketLoop

@@NotEmpty:
	MOV AX,[LeftLimit]
	SUB AX,BX
	SUB CX,AX
	ADD BX,AX
	ADD SI,AX

@@NoLeftClipCopy:
	MOV AX,BX
	ADD AX,CX
	CMP AX,[RightLimit]
	JLE @@DoCopy

	SUB AX,[RightLimit]
	SUB CX,AX
	ADD [Increment],AX

@@DoCopy:
	SHR CX,1
	JNC @@DoWords1

	MOVSB

@@DoWords1:
	REP MOVSW
	ADD SI,[Increment]
	JMP @@LoadPacketLoop

@@ReplicateData:
	MOV CL,AL
	JCXZ @@LoadPacketLoop

	INC SI

	MOV BX,DX
	ADD DX,CX
	MOV AX,BX

	CMP AX,[RightLimit]
	JGE @@PacketPassLoop

	CMP AX,[LeftLimit]
	JGE @@NoLeftClipRepl

	ADD AX,CX
	CMP AX,[LeftLimit]
	JL @@LoadPacketLoop

	MOV AX,[LeftLimit]
	SUB AX,BX
	SUB CX,AX
	ADD BX,AX

@@NoLeftClipRepl:
	MOV AX,BX
	ADD AX,CX
	CMP AX,[RightLimit]
	JLE @@DoReplicate

	SUB AX,[RightLimit]
	SUB CX,AX

@@DoReplicate:
	MOV AL,[DS:SI-1]
	MOV AH,AL
	SHR CX,1
	JNC @@DoWords2

	STOSB

@@DoWords2:
	REP STOSW
	JMP @@LoadPacketLoop

@@NextLine:
	POP DI
	ADD DI,320
	DEC [VerticalCount]
	JNZ @@DrawLoop

	JMP @@Done

@@PacketPassLoop:
	XOR AH,AH

@@LoadAndDropPacket:
	CMP DX,[FrameWidth]
	JAE @@NextLine

	LODSB
	CMP AL,0
	JGE @@LoadAndDropReplicateData

@@LoadAndDropCopyData:
	NEG AL
	ADD SI,AX
	ADD DX,AX
	JMP @@LoadAndDropPacket

@@LoadAndDropReplicateData:
	INC SI
	ADD DX,AX
	JMP @@LoadAndDropPacket

@@Done:
	POP DS
END;

PROCEDURE ProcessChunkSS2(Data: POINTER; Offsetx,Offsety: INTEGER; wx1,wy1,wx2,wy2: INTEGER);
ASSEMBLER;
VAR
	LeftLimit: WORD;
	RightLimit: WORD;
	TopLimit: WORD;
	BottomLimit: WORD;
	Increment: WORD;
	PacketsLeft: WORD;
	LinesLeft: WORD;
	CurrentLine: WORD;
	DISave: WORD;
ASM
	CLD
	PUSH DS

	INC [wx2]
	INC [wy2]
	MOV [LeftLimit],0
	MOV CX,[FLCWidth]
	MOV BX,[Offsetx]
	MOV AX,BX
	ADD AX,CX

	CMP AX,[wx1]
	JL @@Done

	CMP BX,[wx2]
	JG @@Done

	CMP BX,[wx1]
	JGE @@NoLeftClip

	MOV DX,[wx1]
	SUB DX,BX
	SUB CX,DX
	MOV [LeftLimit],DX

@@NoLeftClip:
	CMP AX,[wx2]
	JLE @@NoRightClip

	SUB AX,[wx2]
	SUB CX,AX

@@NoRightClip:
	ADD CX,[LeftLimit]
	MOV [RightLimit],CX

	MOV [TopLimit],0
	MOV CX,[FLCHeight]
	MOV BX,[Offsety]
	MOV AX,BX
	ADD AX,CX

	CMP AX,[wy1]
	JL @@Done

	CMP BX,[wy2]
	JG @@Done

	CMP BX,[wy1]
	JGE @@NoTopClip

	MOV DX,[wy1]
	SUB DX,BX
	SUB CX,DX
	MOV [TopLimit],DX

@@NoTopClip:
	CMP AX,[wy2]
	JLE @@NoBottomClip

	SUB AX,[wy2]
	SUB CX,AX

@@NoBottomClip:
	ADD CX,[TopLimit]
	MOV [BottomLimit],CX

	LDS SI,[Data]

	LODSW
	MOV [LinesLeft],AX
	MOV [CurrentLine],0
	MOV AX,SegA000
	MOV ES,AX

@@LineFillLoop:
	CMP [LinesLeft],0
	JE @@Done

	DEC [LinesLeft]

@@OptionalWordLoad:
	LODSW
	TEST AX,1000000000000000B
	JZ @@PacketDrawLoop

	NEG AX
	ADD [CurrentLine],AX
	JMP @@OptionalWordLoad

@@PacketDrawLoop:
	MOV [PacketsLeft],AX

	MOV AX,[CurrentLine]
	INC [CurrentLine]
	CMP AX,[TopLimit]
	JL @@PacketPassLoop

	CMP AX,[BottomLimit]
	JG @@Done

	ADD AX,[Offsety]
	MOV BX,320
	MUL BX
	ADD AX,[Offsetx]
	MOV DI,AX
	MOV [DISave],DI
	XOR DX,DX

@@LoadPacketLoop:
	CMP [PacketsLeft],0
	JE @@LineFillLoop

	DEC [PacketsLeft]

	MOV DI,[DISave]
	XOR CX,CX
	LODSW
	CMP AH,0
	JL @@ReplicateData

@@CopyData:
	MOV CL,AH
	JCXZ @@LoadPacketLoop

	SHL CX,1

	XOR AH,AH
	ADD DX,AX

	MOV [Increment],0
	MOV BX,DX
	ADD DX,CX
	MOV AX,BX

	CMP AX,[RightLimit]
	JL @@NoLoadAndDropCopy

	ADD SI,CX
	JMP @@PacketPassLoop

@@NoLoadAndDropCopy:
	CMP AX,[LeftLimit]
	JGE @@NoLeftClipCopy

	ADD AX,CX
	CMP AX,[LeftLimit]
	JGE @@NotEmpty

	ADD SI,CX
	JMP @@LoadPacketLoop

@@NotEmpty:
	MOV AX,[LeftLimit]
	SUB AX,BX
	SUB CX,AX
	ADD BX,AX
	ADD SI,AX

@@NoLeftClipCopy:
	MOV AX,BX
	ADD AX,CX
	CMP AX,[RightLimit]
	JLE @@DoCopy

	SUB AX,[RightLimit]
	SUB CX,AX
	MOV [Increment],AX

@@DoCopy:
	ADD DI,BX
	SHR CX,1
	JNC @@DoWords1

	MOVSB

@@DoWords1:
	REP MOVSW
	ADD SI,[Increment]
	JMP @@LoadPacketLoop

@@ReplicateData:
	NEG AH
	MOV CL,AH
	SHL CX,1
	XOR AH,AH
	ADD DX,AX

	ADD SI,2

	MOV BX,DX
	ADD DX,CX
	MOV AX,BX

	CMP AX,[RightLimit]
	JGE @@PacketPassLoop

	CMP AX,[LeftLimit]
	JGE @@NoLeftClipRepl

	ADD AX,CX
	CMP AX,[LeftLimit]
	JL @@LoadPacketLoop

	MOV AX,[LeftLimit]
	SUB AX,BX
	SUB CX,AX
	ADD BX,AX

@@NoLeftClipRepl:
	MOV AX,BX
	ADD AX,CX
	CMP AX,[RightLimit]
	JLE @@DoReplicate

	SUB AX,[RightLimit]
	SUB CX,AX

@@DoReplicate:
	ADD DI,BX
	MOV AX,[DS:SI-2]
	TEST DI,1
	JZ @@NoFlip

	XCHG AH,AL

@@NoFlip:
	SHR CX,1
	JNC @@DoWords2

	STOSB
	XCHG AH,AL

@@DoWords2:
	REP STOSW
	JMP @@LoadPacketLoop

@@PacketPassLoop:
	CMP [PacketsLeft],0
	JE @@LineFillLoop

	DEC [PacketsLeft]
	XOR CH,CH

	LODSW
	CMP AH,0
	JL @@LoadAndDropReplicateData

@@LoadAndDropCopyData:
	MOV CL,AH
	SHL CX,1
	ADD SI,CX
	JMP @@PacketPassLoop

@@LoadAndDropReplicateData:
	ADD SI,2
	JMP @@PacketPassLoop

@@Done:
	POP DS
END;

PROCEDURE ExitWithError(Message: STRING);
BEGIN
	WRITELN(Message);
	HALT;
END;

VAR
	ExitProcSave: POINTER;
	Int8Save: POINTER;
	Int8CallFract: WORD;
	Int8CallOverflow: WORD;
	TimerCounter: LONGINT;

PROCEDURE ExitHandler; FAR;
BEGIN
	ExitProc:=ExitProcSave;

	ASM
		MOV AL,00110110B
		OUT 43H,AL
		XOR AL,AL
		OUT 40H,AL
		OUT 40H,AL
	END;

	DOSInterruptVectorSet($8,Int8Save);
END;

PROCEDURE TimerHandler; FAR;
ASSEMBLER;
ASM
	PUSH DS
	PUSH AX
	MOV AX,SEG @Data
	MOV DS,AX

	ADD [WORD PTR TimerCounter],1
	ADC [WORD PTR TimerCounter+2],0

	MOV AX,[Int8CallFract]
	ADD [Int8CallOverflow],AX
	JNC @@NoOld8Call

	PUSHF
	CALL [Int8Save]
	JMP @@Done

@@NoOld8Call:
	MOV AL,20H
	OUT 20H,AL

@@Done:
	POP AX
	POP DS
	IRET
END;

PROCEDURE InstallTimerHandler;
BEGIN
	Int8Save:=DOSInterruptVectorGet($8);
	DOSInterruptVectorSet($8,@TimerHandler);

	ASM
		MOV AL,00110110B
		OUT 43H,AL

		XOR AX,AX
		MOV DX,18
		MOV BX,1000
		DIV BX
		MOV [Int8CallFract],AX
		ADD [Int8CallOverflow],08000H

		MOV AX,0DC34H
		MOV DX,12H
		DIV BX

		OUT 40H,AL
		XCHG AL,AH
		OUT 40H,AL
	END;
END;



procedure playfli(filename:string);

VAR
	FLCHeader: PFLCHeader;
	FLCChunk: PFLCChunk;
	FLCSubChunk: PFLCSubChunk;
	InFile: TDOSFileHandle;
	CurrentFrame: WORD;
	i: WORD;
	CurrentSubChunk: WORD;
	FirstFramePos: LONGINT;
	NextFramePos: LONGINT;
	SubChunkData: POINTER;
	Offsetx,Offsety: INTEGER;
	PauseCount: LONGINT;
	PauseFrame: LONGINT;
BEGIN

        if Not ShowMovie then Exit;
	InstallTimerHandler;

	NEW(FLCHeader);
	NEW(FLCChunk);
	NEW(FLCSubChunk);

	DOSFileOpen(InFile,filename,DOSFileAccessRead);

	IF DOSResult<>0 THEN
		ExitWithError(errOpeningFile);

	DOSFileRead(InFile,FLCHeader^,SIZEOF(FLCHeader^),i);

	IF (DOSResult<>0) OR (i<>SIZEOF(FLCHeader^)) THEN
		ExitWithError(errReadingFile);

	IF ((FLCHeader^.FileMagic<>FLCFileMagicFLI) AND (FLCHeader^.FileMagic<>FLCFileMagicFLC)) THEN
		ExitWithError(errInvalidFile);

	IF (LONGINT(FLCHeader^.ScreenWidth)*FLCHeader^.ScreenHeight>64000) THEN
		ExitWithError(errUnsupportedBigFile);

	IF (FLCHeader^.FramesCount=0) THEN
		ExitWithError(errEmptyFile);

	CurrentFrame:=1;
	FirstFramePos:=DOSFilePositionGet(InFile);
	NextFramePos:=FirstFramePos;

	FLCWidth:=FLCHeader^.ScreenWidth;
	FLCHeight:=FLCHeader^.ScreenHeight;

	IF FLCHeader^.PlaybackSpeed=0 THEN
		FLCHeader^.PlaybackSpeed:=1;

	IF FLCHeader^.FileMagic=FLCFileMagicFLI THEN
		FLCHeader^.PlaybackSpeed:=FLCHeader^.PlaybackSpeed*1000 DIV 70;

	Offsetx:=160-(FLCHeader^.ScreenWidth) DIV 2;
	Offsety:=100-(FLCHeader^.ScreenHeight) DIV 2;

	REPEAT
		IF CurrentFrame>FLCHeader^.FramesCount THEN
			BEGIN
                                Break;
				NextFramePos:=FirstFramePos;
				CurrentFrame:=1;
			END;

		REPEAT
			DOSFilePositionSet(InFile,NextFramePos);
			DOSFileRead(InFile,FLCChunk^,SIZEOF(FLCChunk^),i);

			IF (DOSResult<>0) OR (i<>SIZEOF(FLCChunk^)) THEN
				ExitWithError(errReadingFile);

			NextFramePos:=NextFramePos+FLCChunk^.ChunkSize;
		UNTIL FLCChunk^.ChunkType=FLCChunkFrame;

		TimerCounter:=0;

		REPEAT
		UNTIL TimerCounter>=FLCHeader^.PlaybackSpeed;

		FOR CurrentSubChunk:=1 TO FLCChunk^.SubChunksCount DO
			BEGIN
				DOSFileRead(InFile,FLCSubChunk^,SIZEOF(FLCSubChunk^),i);

				IF (DOSResult<>0) OR (i<>SIZEOF(FLCSubChunk^)) THEN
					ExitWithError(errReadingFile);

				IF FLCSubChunk^.ChunkSize-SIZEOF(FLCSubChunk^)>$FFF0 THEN
					ExitWithError(errSubChunkTooBig);

				GETMEM(SubChunkData,FLCSubChunk^.ChunkSize-SIZEOF(FLCSubChunk^));
				DOSFileRead(InFile,SubChunkData^,FLCSubChunk^.ChunkSize-SIZEOF(FLCSubChunk^),i);

				IF (DOSResult<>0) OR (i<>FLCSubChunk^.ChunkSize-SIZEOF(FLCSubChunk^)) THEN
					ExitWithError(errReadingFile);

				CASE FLCSubChunk^.ChunkType OF
					FLCChunkColor256: ProcessChunkColor256(SubChunkData);
					FLCChunkColor: ProcessChunkColor(SubChunkData);
					FLCChunkBlack: ProcessChunkBlack(SubChunkData,Offsetx,Offsety,0,0,319,199);
					FLCChunkCopy: ProcessChunkCopy(SubChunkData,Offsetx,Offsety,0,0,319,199);
					FLCChunkBRun: ProcessChunkBRun(SubChunkData,Offsetx,Offsety,0,0,319,199);
					FLCChunkLC: ProcessChunkLC(SubChunkData,Offsetx,Offsety,0,0,319,199);
					FLCChunkSS2: ProcessChunkSS2(SubChunkData,Offsetx,Offsety,0,0,319,199);
				END;

				FREEMEM(SubChunkData,FLCSubChunk^.ChunkSize-SIZEOF(FLCSubChunk^));
			END;

		CurrentFrame:=CurrentFrame+1;
         if MouseButtons<>0 then break;
	UNTIL (Keypressed);

        While MouseButtons<>0 do;
        While Keypressed do readkey;
	DOSFileClose(InFile);
	DISPOSE(FLCHeader);
        ExitHandler;
END;

end.