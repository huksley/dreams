{$S-,Q-,R-}
Unit PLMOVE;

interface

procedure movedat32(var src,dst; size:word);
procedure moveskip(var src,dst; skip:byte; size:word);
procedure move_add(var src,dst; size,after,addon:word);
procedure move_skip(var src,dst; skip:byte;size,after,addon:word);

implementation

procedure movedat32(var src,dst; size:word);
assembler; asm
 cld
 push ds
 les di,dst
 lds si,src
 mov cx,size
 shr cx,1
 jnc @@onlywords
 movsb
 @@onlywords:
  rep movsw
 pop ds
end;

procedure moveskip(var src,dst; skip:byte; size:word);
assembler; asm
 cld
 push ds
  les di,dst
  lds si,src
  mov cx,size
  @@domove:
      lodsb
      cmp al,0
      jz @@skipwrt
      stosb
      loop @@domove
      @@skipwrt:
      inc di
      loop @@domove
 pop ds
end;

procedure move_add(var src,dst; size,after,addon:word);
assembler; asm
 cld
 push ds
  les di,dst
  lds si,src
  mov cx,size
  mov dx,after
  @@domove:
      movsb
      dec dx
      cmp dx,0
      jz @@makeadd
      loop @@domove
      @@makeadd:
       add di,addon
       mov dx,after
       loop @@domove
 pop ds
end;

procedure move_skip(var src,dst; skip:byte;size,after,addon:word);
assembler; asm
 cld
 push ds
  les di,dst
  lds si,src
  mov cx,size
  mov dx,after
  @@domove:
      lodsb
      cmp al,skip
      jz @@doskip
      stosb
      jmp @@donext
      @@doskip:
      inc di
      @@donext:
      dec dx
      cmp dx,0
      jz @@makeadd
      loop @@domove
      @@makeadd:
       add di,addon
       mov dx,after
       loop @@domove
 pop ds
end;

end.
