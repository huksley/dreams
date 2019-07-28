 var talkrec:ttalkrec;

     procedure new_talk(s:string);
     begin
      init_talkrec(s,talkrec);
     end;
     procedure addchoice_talk(s:string);
     begin
      addchoice_talkrec(s,talkrec);
     end;
     procedure addtext_talk(s:string);
     begin
      addtext_talkrec(s,talkrec);
     end;
     procedure addvar_talk(s:string);
     begin
      addvar_talkrec(s,talkrec);
     end;
     procedure topictext_talk(s:string);
     begin
      topic2text(s,talkrec);
     end;
     procedure topicchoice_talk(s:string);
     begin
      topic2choice(s,talkrec);
     end;
     procedure topicvar_talk(s:string);
     begin
      topic2var(s,talkrec);
     end;
     procedure do_talk(s:string);
     begin
      quered:=show_talk(talkrec,screen);
      done_talkrec(talkrec);
     end;

     procedure regist_talk;
     begin
      appendcomm('talkopen',new_talk);

      appendcomm('talktext',addtext_talk);
      appendcomm('talkchoice',addchoice_talk);
      appendcomm('talkvar',addvar_talk);

      appendcomm('talklibtext',topictext_talk);
      appendcomm('talklibchoice',topicchoice_talk);
      appendcomm('talklibvar',topicvar_talk);

      appendcomm('talkdo',do_talk);
     end;
