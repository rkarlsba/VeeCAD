unit ColorScheme;

interface

uses Graphics;

// ***************************************************************
//   TveColorScheme is used to pass color settings data around
// ***************************************************************

type TveColorScheme = record
	  ShowColor : boolean;	// monochrome by default
	  Board : TColor;
	  Strips : TColor;
	  Body : TColor;
	  Pin : TColor;
end;



implementation

end.
