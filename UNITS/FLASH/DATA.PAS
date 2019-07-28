unit data;

interface

type
    tcolors=record
     paper,
     lightpen,
     darkpen,
     border:byte;
    end;
const
    colors:tcolors=(
     paper:137;
     lightpen:80;
     darkpen:77;
     border:76);
type
    tfont_col=record
     curr,
     light,
     dark:byte;
    end;
const
     font_col:tfont_col=(
      curr:28;
      light:80;
      dark:46 );
type
    tbutt_cfg=record
     delay:word;
     leftupper,
     rightlower,
     border:byte
    end;
const
     butt_cfg:tbutt_cfg=(
      delay:50;
      leftupper:78;
      rightlower:72;
      border:0 );

const
     cmenufr_size=3;
     cmenuc:array[0..cmenufr_size-1] of byte=
     (76,78,0);
     cmenuground=46;
     cGOODCOLOR =72;

implementation
end.
