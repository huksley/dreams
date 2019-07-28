UNIT DOSFunctions;

INTERFACE

TYPE
	PDOSFindRecord = ^TDOSFindRecord;
	TDOSFindRecord = RECORD
		Filler: ARRAY[1..21] OF BYTE;
		Attribute: BYTE;
		Time: LONGINT;
		Size: LONGINT;
		NameZ: ARRAY[0..12] OF CHAR;
	END;

TYPE
	PDOSFileHandle = ^TDOSFileHandle;
	TDOSFileHandle = RECORD
		Number: WORD;
	END;

TYPE
	PDOSMemoryHandle = ^TDOSMemoryHandle;
	TDOSMemoryHandle = RECORD
		Offs: WORD;
		Segment: WORD;
	END;

CONST
	DOSFileAccessRead = 0;
	DOSFileAccessWrite = 1;
	DOSFileAccessReadWrite = 2;

CONST
	DOSFileAttrReadOnly = $01;
	DOSFileAttrHidden = $02;
	DOSFileAttrSystem = $04;
	DOSFileAttrVolumeLabel = $08;
	DOSFileAttrDirectory = $10;
	DOSFileAttrArchive = $20;

FUNCTION DOSResult: WORD;
FUNCTION DOSInDOSFlagGet: BYTE;
PROCEDURE DOSTimeGet(VAR Hour,Minute,Second,Second100: BYTE);
PROCEDURE DOSTimeSet(Hour,Minute,Second,Second100: BYTE);
PROCEDURE DOSDateGet(VAR Year: WORD; VAR Month,Day,DayOfWeek: BYTE);
PROCEDURE DOSDateSet(Year: WORD; Month,Day: BYTE);
PROCEDURE DOSInterruptVectorSet(InterruptNumber: BYTE; InterruptHandler: POINTER);
FUNCTION DOSInterruptVectorGet(InterruptNumber: BYTE): POINTER;
PROCEDURE DOSFindFirst(VAR DOSFindRecord: TDOSFindRecord; FileName: STRING; Attributes: WORD);
PROCEDURE DOSFindNext(VAR DOSFindRecord: TDOSFindRecord);
PROCEDURE DOSFileTemporaryCreate(VAR UserFileHandle: TDOSFileHandle; VAR FileName: STRING);
PROCEDURE DOSFileCreate(VAR UserFileHandle: TDOSFileHandle; FileName: STRING);
PROCEDURE DOSFileOpen(VAR UserFileHandle: TDOSFileHandle; FileName: STRING; AccessType: BYTE);
PROCEDURE DOSFileClose(VAR UserFileHandle: TDOSFileHandle);
PROCEDURE DOSFileRead(VAR UserFileHandle: TDOSFileHandle; VAR ReadBuffer; ReadCount: WORD; VAR ActuallyRead: WORD);
PROCEDURE DOSFileWrite(VAR UserFileHandle: TDOSFileHandle; VAR WriteBuffer; WriteCount: WORD; VAR ActuallyWritten: WORD);
PROCEDURE DOSFilePositionSet(VAR UserFileHandle: TDOSFileHandle; NewLocation: LONGINT);
FUNCTION DOSFilePositionGet(VAR UserFileHandle: TDOSFileHandle): LONGINT;
PROCEDURE DOSFileTruncate(VAR UserFileHandle: TDOSFileHandle);
FUNCTION DOSFileSizeGet(VAR UserFileHandle: TDOSFileHandle): LONGINT;
FUNCTION DOSFileEnd(VAR UserFileHandle: TDOSFileHandle): BOOLEAN;
PROCEDURE DOSFileDelete(FileName: STRING);
PROCEDURE DOSFileRename(FileName, NewFileName: STRING);
PROCEDURE DOSDiskCurrentSet(DiskDrive: BYTE);
FUNCTION DOSDiskCurrentGet: BYTE;
FUNCTION DOSDiskValidCount: BYTE;
FUNCTION DOSDiskSpaceFree(DiskDrive: BYTE): LONGINT;
FUNCTION DOSDiskSpaceTotal(DiskDrive: BYTE): LONGINT;
PROCEDURE DOSMemoryAllocate(VAR DOSMemoryHandle: TDOSMemoryHandle; Size: WORD);
PROCEDURE DOSMemoryDeallocate(VAR DOSMemoryHandle: TDOSMemoryHandle);
FUNCTION DOSMemoryAvail: WORD;

IMPLEMENTATION

VAR
	LastError: WORD;
	InDOSFlagPtr: POINTER;

FUNCTION DOSResult: WORD;
ASSEMBLER;
ASM
	MOV AX,[LastError]
END;

PROCEDURE DOSTimeGet(VAR Hour,Minute,Second,Second100: BYTE);
ASSEMBLER;
ASM
	MOV AH,2CH
	INT 21H

	LES DI,[Hour]
	MOV [ES:DI],CH
	LES DI,[Minute]
	MOV [ES:DI],CL
	LES DI,[Second]
	MOV [ES:DI],DH
	LES DI,[Second100]
	MOV [ES:DI],DL

	MOV [LastError],0H
END;

PROCEDURE DOSTimeSet(Hour,Minute,Second,Second100: BYTE);
ASSEMBLER;
ASM
	MOV AH,2DH
	MOV CH,[Hour]
	MOV CL,[Minute]
	MOV DH,[Second]
	MOV DL,[Second100]
	INT 21H

	MOV [BYTE PTR LastError],AL
	MOV [BYTE PTR LastError+1],0H
END;

PROCEDURE DOSInterruptVectorSet(InterruptNumber: BYTE; InterruptHandler: POINTER);
ASSEMBLER;
ASM
	MOV BX,DS

	MOV AH,25H
	MOV AL,[InterruptNumber]
	LDS DX,[InterruptHandler]
	INT 21H

	MOV DS,BX

	MOV [LastError],0H
END;

FUNCTION DOSInterruptVectorGet(InterruptNumber: BYTE): POINTER;
ASSEMBLER;
ASM
	MOV AH,35H
	MOV AL,[InterruptNumber]
	INT 21H

	MOV AX,BX
	MOV DX,ES

	MOV [LastError],0H
END;

FUNCTION DOSInDOSFlagGet: BYTE;
ASSEMBLER;
ASM
	LES DI,[InDOSFlagPtr]
	MOV AL,[ES:DI]

	MOV [LastError],0H
END;

PROCEDURE DOSFindFirst(VAR DOSFindRecord: TDOSFindRecord; FileName: STRING; Attributes: WORD);
ASSEMBLER;
VAR
	PathBuffer: ARRAY[0..78] OF CHAR;
ASM
	PUSH DS
	MOV [LastError],0H

	MOV AH,1AH
	LDS DX,[DOSFindRecord]
	INT 21H

	CLD

	MOV AX,[WORD PTR FileName+2]
	MOV DS,AX
	MOV SI,[WORD PTR FileName]
	LEA DI,PathBuffer
	MOV DX,DI
	MOV BX,SS
	MOV ES,BX
	MOV CL,[DS:SI]
	XOR CH,CH
	INC SI
	CMP CL,79
	JBE @@MoveThem

	MOV CL,79

@@MoveThem:
	SHR CX,1
	JNC @@DoWords

	MOVSB

@@DoWords:
	REP MOVSW

	MOV [BYTE PTR ES:DI],0H

	MOV AX,ES
	MOV DS,AX
	MOV AH,4EH
	MOV CX,[Attributes]
	INT 21H
	POP DS
	JNC @@Done

	MOV [LastError],AX

@@Done:
END;

PROCEDURE DOSFindNext(VAR DOSFindRecord: TDOSFindRecord);
ASSEMBLER;
ASM
	MOV [LastError],0H

	MOV BX,DS
	MOV AH,1AH
	LDS DX,[DOSFindRecord]
	INT 21H
	MOV DS,BX

	MOV AH,4FH
	INT 21H
	JNC @@Done

	MOV [LastError],AX

@@Done:
END;

PROCEDURE DOSDateGet(VAR Year: WORD; VAR Month,Day,DayOfWeek: BYTE);
ASSEMBLER;
ASM
	MOV AH,2AH
	INT 21H

	LES DI,[Year]
	MOV [ES:DI],CX
	LES DI,[Month]
	MOV [ES:DI],DH
	LES DI,[Day]
	MOV [ES:DI],DL
	LES DI,[DayOfWeek]
	MOV [ES:DI],AL

	MOV [LastError],0H
END;

PROCEDURE DOSDateSet(Year: WORD; Month,Day: BYTE);
ASSEMBLER;
ASM
	MOV CX,[Year]
	MOV DH,[Month]
	MOV DL,[Day]
	MOV AH,2BH
	INT 21H

	MOV [BYTE PTR LastError],AL
	MOV [BYTE PTR LastError+1],0H
END;

PROCEDURE DOSFileCreate(VAR UserFileHandle: TDOSFileHandle; FileName: STRING);
ASSEMBLER;
VAR
	PathBuffer: ARRAY[0..78] OF CHAR;
ASM
	PUSH DS

	CLD

	MOV AX,[WORD PTR FileName+2]
	MOV SI,[WORD PTR FileName]
	LEA DI,PathBuffer
	MOV DX,DI
	MOV DS,AX
	MOV BX,SS
	MOV ES,BX

	LODSB
	XOR AH,AH
	MOV CX,AX
	CMP CL,79
	JBE @@MoveThem

	MOV CL,79

@@MoveThem:
	SHR CX,1
	JNC @@DoWords

	MOVSB

@@DoWords:
	REP MOVSW

	MOV [BYTE PTR ES:DI],0H

	MOV AX,ES
	MOV DS,AX
	MOV AH,3CH
	XOR CX,CX
	INT 21H
	POP DS
	JC @@Error

	LES DI,[UserFileHandle]
	MOV [TDOSFileHandle(ES:DI).Number],AX
	MOV [LastError],0H
	JMP @@Done

@@Error:
	MOV [LastError],AX

@@Done:
END;

PROCEDURE DOSFileTemporaryCreate(VAR UserFileHandle: TDOSFileHandle; VAR FileName: STRING);
ASSEMBLER;
ASM
	PUSH DS

	LDS DX,[FileName]
	INC DX
	MOV DI,DX
	MOV [BYTE PTR DS:DI],'\'
	MOV [BYTE PTR DS:DI+1],0H
	MOV AH,5AH
	XOR CX,CX
	INT 21H
	POP DS
	JC @@Error

	MOV BX,AX
	MOV AX,[WORD PTR FileName+2]
	MOV ES,AX
	XOR AL,AL
	MOV CX,79
	REPNE SCASB
	MOV AX,78
	SUB AX,CX
	MOV DI,DX
	MOV [BYTE PTR ES:DI-1],AL

	LES DI,[UserFileHandle]
	MOV [TDOSFileHandle(ES:DI).Number],BX
	MOV [LastError],0H
	JMP @@Done

@@Error:
	MOV [LastError],AX

@@Done:
END;

PROCEDURE DOSFileOpen(VAR UserFileHandle: TDOSFileHandle; FileName: STRING; AccessType: BYTE);
ASSEMBLER;
VAR
	PathBuffer: ARRAY[0..78] OF CHAR;
ASM
	PUSH DS

	CLD

	MOV AX,[WORD PTR FileName+2]
	MOV SI,[WORD PTR FileName]
	LEA DI,PathBuffer
	MOV DX,DI
	MOV DS,AX
	MOV BX,SS
	MOV ES,BX

	LODSB
	XOR AH,AH
	MOV CX,AX
	CMP CL,79
	JBE @@MoveThem

	MOV CL,79

@@MoveThem:
	SHR CX,1
	JNC @@DoWords

	MOVSB

@@DoWords:
	REP MOVSW

	MOV [BYTE PTR ES:DI],0H

	MOV AX,ES
	MOV DS,AX
	MOV AH,3DH
	MOV AL,[AccessType]
	INT 21H
	POP DS
	JC @@Error

	LES DI,[UserFileHandle]
	MOV [TDOSFileHandle(ES:DI).Number],AX
	MOV [LastError],0H
	JMP @@Done

@@Error:
	MOV [LastError],AX

@@Done:
END;

PROCEDURE DOSFileClose(VAR UserFileHandle: TDOSFileHandle);
ASSEMBLER;
ASM
	MOV AH,3EH
	LES DI,[UserFileHandle]
	MOV BX,[TDOSFileHandle(ES:DI).Number]
	INT 21H
	JC @@Error

	MOV [LastError],0H
	JMP @@Done

@@Error:
	MOV [LastError],AX

@@Done:
END;

PROCEDURE DOSFileRead(VAR UserFileHandle: TDOSFileHandle; VAR ReadBuffer; ReadCount: WORD; VAR ActuallyRead: WORD);
ASSEMBLER;
ASM
	PUSH DS

	MOV AH,3FH
	LES DI,[UserFileHandle]
	MOV BX,[TDOSFileHandle(ES:DI).Number]
	MOV CX,[ReadCount]
	LDS DX,[ReadBuffer]
	INT 21H
	POP DS
	JC @@Error

	LES DI,[ActuallyRead]
	MOV [ES:DI],AX
	MOV [LastError],0H
	JMP @@Done

@@Error:
	MOV [LastError],AX

@@Done:
END;

PROCEDURE DOSFileWrite(VAR UserFileHandle: TDOSFileHandle; VAR WriteBuffer; WriteCount: WORD; VAR ActuallyWritten: WORD);
ASSEMBLER;
ASM
	PUSH DS

	MOV CX,[WriteCount]
	JCXZ @@ZeroWrite

	MOV AH,40H
	LES DI,[UserFileHandle]
	MOV BX,[TDOSFileHandle(ES:DI).Number]
	LDS DX,[WriteBuffer]
	INT 21H
	POP DS
	JC @@Error

	LES DI,[ActuallyWritten]
	MOV [ES:DI],AX
	MOV [LastError],0H
	JMP @@Done

@@ZeroWrite:
	LES DI,[ActuallyWritten]
	MOV [WORD PTR ES:DI],CX
	MOV [LastError],CX
	JMP @@Done

@@Error:
	MOV [LastError],AX

@@Done:
END;

PROCEDURE DOSFilePositionSet(VAR UserFileHandle: TDOSFileHandle; NewLocation: LONGINT);
ASSEMBLER;
ASM
	MOV AX,4200H
	LES DI,[UserFileHandle]
	MOV BX,[TDOSFileHandle(ES:DI).Number]
	MOV DX,[WORD PTR NewLocation]
	MOV CX,[WORD PTR NewLocation+2]
	INT 21H
	JC @@Error

	MOV [LastError],0H
	JMP @@Done

@@Error:
	MOV [LastError],AX

@@Done:
END;

FUNCTION DOSFilePositionGet(VAR UserFileHandle: TDOSFileHandle): LONGINT;
ASSEMBLER;
ASM
	MOV AX,4201H
	LES DI,[UserFileHandle]
	MOV BX,[TDOSFileHandle(ES:DI).Number]
	XOR DX,DX
	XOR CX,CX
	INT 21H
	JC @@Error

	MOV [LastError],0H
	JMP @@Done

@@Error:
	MOV [LastError],AX

@@Done:
END;

PROCEDURE DOSFileTruncate(VAR UserFileHandle: TDOSFileHandle);
ASSEMBLER;
ASM
	MOV AH,40H
	XOR CX,CX
	LES DI,[UserFileHandle]
	MOV BX,[TDOSFileHandle(ES:DI).Number]
	INT 21H
	JC @@Error

	MOV [LastError],0H
	JMP @@Done

@@Error:
	MOV [LastError],AX

@@Done:
END;

FUNCTION DOSFileSizeGet(VAR UserFileHandle: TDOSFileHandle): LONGINT;
ASSEMBLER;
ASM
	MOV AX,4201H
	LES DI,[UserFileHandle]
	MOV BX,[TDOSFileHandle(ES:DI).Number]
	XOR DX,DX
	XOR CX,CX
	INT 21H
	JC @@Error

	PUSH AX
	PUSH DX

	MOV AX,4202H
	XOR DX,DX
	XOR CX,CX
	INT 21H
	JC @@Error

	POP DI
	POP SI
	PUSH AX
	PUSH DX

	MOV AX,4200H
	MOV DX,SI
	MOV CX,DI
	INT 21H
	JC @@Error

	MOV [LastError],0H
	POP DX
	POP AX
	JMP @@Done

@@Error:
	MOV [LastError],AX

@@Done:
END;

FUNCTION DOSFileEnd(VAR UserFileHandle: TDOSFileHandle): BOOLEAN;
ASSEMBLER;
ASM
	MOV AX,4201H
	LES DI,[UserFileHandle]
	MOV BX,[TDOSFileHandle(ES:DI).Number]
	XOR DX,DX
	XOR CX,CX
	INT 21H
	JC @@Error

	PUSH AX
	PUSH DX

	MOV AX,4202H
	XOR DX,DX
	XOR CX,CX
	INT 21H
	JC @@Error

	POP DI
	POP SI
	PUSH AX
	PUSH DX

	MOV AX,4200H
	MOV DX,SI
	MOV CX,DI
	INT 21H
	JC @@Error

	MOV [LastError],0H
	POP DX
	POP AX
	CMP DI,DX
	JA @@BeyondEnd
	JB @@BeforeEnd

	CMP SI,AX
	JB @@BeforeEnd

@@BeyondEnd:
	MOV AL,1
	JMP @@Done

@@BeforeEnd:
	XOR AL,AL
	JMP @@Done

@@Error:
	MOV [LastError],AX

@@Done:
END;

PROCEDURE DOSFileDelete(FileName: STRING);
ASSEMBLER;
VAR
	PathBuffer: ARRAY[0..78] OF CHAR;
ASM
	PUSH DS

	CLD

	MOV AX,[WORD PTR FileName+2]
	MOV SI,[WORD PTR FileName]
	LEA DI,PathBuffer
	MOV DX,DI
	MOV DS,AX
	MOV BX,SS
	MOV ES,BX

	LODSB
	XOR AH,AH
	MOV CX,AX
	CMP CL,79
	JBE @@MoveThem

	MOV CL,79

@@MoveThem:
	SHR CX,1
	JNC @@DoWords

	MOVSB

@@DoWords:
	REP MOVSW

	MOV [BYTE PTR ES:DI],0H

	MOV AX,ES
	MOV DS,AX
	MOV AH,41H
	MOV CL,0
	INT 21H
	POP DS
	JC @@Error

	MOV [LastError],0
	JMP @@Done

@@Error:
	MOV [LastError],AX

@@Done:
END;

PROCEDURE DOSFileRename(FileName, NewFileName: STRING);
ASSEMBLER;
VAR
	PathBuffer1: ARRAY[0..78] OF CHAR;
	PathBuffer2: ARRAY[0..78] OF CHAR;
ASM
	PUSH DS

	CLD

	MOV AX,[WORD PTR FileName+2]
	MOV SI,[WORD PTR FileName]
	LEA DI,PathBuffer1
	MOV DX,DI
	MOV DS,AX
	MOV BX,SS
	MOV ES,BX

	LODSB
	XOR AH,AH
	MOV CX,AX
	CMP CL,79
	JBE @@MoveThem

	MOV CL,79

@@MoveThem:
	SHR CX,1
	JNC @@DoWords

	MOVSB

@@DoWords:
	REP MOVSW

	MOV [BYTE PTR ES:DI],0H

	MOV AX,[WORD PTR NewFileName+2]
	MOV SI,[WORD PTR NewFileName]
	LEA DI,PathBuffer2
	MOV DS,AX

	LODSB
	XOR AH,AH
	MOV CX,AX
	CMP CL,79
	JBE @@MoveThem2

	MOV CL,79

@@MoveThem2:
	SHR CX,1
	JNC @@DoWords2

	MOVSB

@@DoWords2:
	REP MOVSW

	MOV [BYTE PTR ES:DI],0H

	MOV AX,ES
	MOV DS,AX
	LEA DI,PathBuffer2
	MOV AH,56H
	MOV CL,0
	INT 21H
	POP DS
	JC @@Error

	MOV [LastError],0
	JMP @@Done

@@Error:
	MOV [LastError],AX

@@Done:
END;

PROCEDURE DOSDiskCurrentSet(DiskDrive: BYTE);
ASSEMBLER;
ASM
	MOV AH,0EH
	MOV DL,[DiskDrive]
	INT 21H

	MOV [LastError],0H
END;

FUNCTION DOSDiskCurrentGet: BYTE;
ASSEMBLER;
ASM
	MOV AH,19H
	INT 21H

	MOV [LastError],0H
END;

FUNCTION DOSDiskValidCount: BYTE;
ASSEMBLER;
ASM
	MOV AH,19H
	INT 21H

	MOV AH,0EH
	MOV DL,AL
	INT 21H

	MOV [LastError],0H
END;

FUNCTION DOSDiskSpaceFree(DiskDrive: BYTE): LONGINT;
ASSEMBLER;
ASM
	MOV AH,36H
	MOV DL,[DiskDrive]
	INT 21H
	CMP AX,0FFFFH
	JE @@Error

	MUL CX
	MUL BX
	MOV [LastError],0
	JMP @@Done

@@Error:
	MOV AH,59H
	XOR BX,BX
	INT 21H
	MOV [LastError],AX

@@Done:
END;

FUNCTION DOSDiskSpaceTotal(DiskDrive: BYTE): LONGINT;
ASSEMBLER;
ASM
	MOV AH,36H
	MOV DL,[DiskDrive]
	INT 21H
	CMP AX,0FFFFH
	JE @@Error

	MOV BX,DX
	MUL CX
	MUL BX
	MOV [LastError],0
	JMP @@Done

@@Error:
	MOV AH,59H
	XOR BX,BX
	INT 21H
	MOV [LastError],AX

@@Done:
END;

PROCEDURE DOSMemoryAllocate(VAR DOSMemoryHandle: TDOSMemoryHandle; Size: WORD);
ASSEMBLER;
ASM
	LES DI,[DOSMemoryHandle]
	MOV AH,48H
	MOV BX,[Size]
	INT 21H
	JC @@Error

	MOV [TDOSMemoryHandle(ES:DI).Segment],AX
	MOV [TDOSMemoryHandle(ES:DI).Offs],0H
	MOV [LastError],0H
	JMP @@Done

@@Error:
	MOV [LastError],AX
	MOV [TDOSMemoryHandle(ES:DI).Segment],0H
	MOV [TDOSMemoryHandle(ES:DI).Offs],0H

@@Done:
END;

FUNCTION DOSMemoryAvail: WORD;
ASSEMBLER;
ASM
	MOV AH,48H
	MOV BX,0FFFFH
	INT 21H

	MOV [LastError],0H

	MOV AX,BX
END;

PROCEDURE DOSMemoryDeallocate(VAR DOSMemoryHandle: TDOSMemoryHandle);
ASSEMBLER;
ASM
	LES DI,[DOSMemoryHandle]
	MOV DX,ES
	MOV AX,[TDOSMemoryHandle(ES:DI).Segment]
	MOV ES,AX
	MOV AH,49H
	INT 21H
	MOV ES,DX
	JC @@Error

	MOV [TDOSMemoryHandle(ES:DI).Segment],0H
	MOV [TDOSMemoryHandle(ES:DI).Offs],0H
	MOV [LastError],0H
	JMP @@Done

@@Error:
	MOV [LastError],AX

@@Done:
END;

BEGIN
	ASM
		MOV AH,34H
		INT 21H

		MOV [WORD PTR InDOSFlagPtr],BX
		MOV BX,ES
		MOV [WORD PTR InDOSFlagPtr+2],BX

		MOV [LastError],0H
	END;
END.