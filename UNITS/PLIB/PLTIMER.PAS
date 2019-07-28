Unit pltimer;

 interface

procedure install_own_int8_handler(proc:pointer);
function get_timer_value:longint;

 implementation

uses pl_error,pl_dos;

VAR
        InstalledUSER:byte;
        UserINT8Handler:Pointer;
        Int8Save: POINTER;
	Int8CallFract: WORD;
	Int8CallOverflow: WORD;
	TimerCounter: LONGINT;

PROCEDURE ExitHandler; FAR;
BEGIN
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
ASSEMBLER; ASM
	PUSH DS
	PUSH AX
	MOV AX,SEG @Data
	MOV DS,AX

	ADD [WORD PTR TimerCounter],1
	ADC [WORD PTR TimerCounter+2],0

        CMP InstalledUSER,1
        JNE @@DONTDO
        CALL UserINT8Handler
        @@DONTDO:

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
        InstalledUSER:=0;
        {install_exit_handler(@Exithandler);}
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
                MOV DX,12h     { 12DC34h  }
		DIV BX

		OUT 40H,AL
		XCHG AL,AH
		OUT 40H,AL
	END;
END;

procedure install_own_int8_handler(proc:pointer);
begin
 UserINT8Handler:=Proc;
 InstalledUSER:=1;
end;
function get_timer_value:longint;
begin
 get_timer_value:=TimerCounter;
end;

begin
 InstallTimerHandler;
end.

