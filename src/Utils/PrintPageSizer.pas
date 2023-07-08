unit PrintPageSizer;

interface

uses Types, Printers;

// Given Margins in Millimeters, Calculate the rectangle describing the
// printable area of the page in printer device pixels.

function CalculatePrintRectangle(
    MarginLeftMM, MarginTopMM, MarginRightMM : integer ) : TRect;


implementation

uses Windows;

function CalculatePrintRectangle(
    MarginLeftMM, MarginTopMM, MarginRightMM : integer ) : TRect;
var
    PixelsPerInchX : integer;
    PixelsPerInchY : integer;
    Margin : integer;
    MinMargin : integer;

begin
        PixelsPerInchX := GetDeviceCaps(Printer.Handle, LOGPIXELSX);
        PixelsPerInchY := GetDeviceCaps(Printer.Handle, LOGPIXELSY);

        // left margin
        //.. convert left margin to device pixels
        Margin := (MarginLeftMM * PixelsPerInchX * 10) div 254;
        //.. minimum margin allowed by printer
        MinMargin := GetDeviceCaps(Printer.Handle, PHYSICALOFFSETX);
        if Margin < MinMargin then begin
            Margin := MinMargin;
        end;
        //.. convert margin to offset from left printable point
        result.Left := Margin - MinMargin;

        // top margin
        //.. convert right margin to device pixels
        Margin := (MarginTopMM * PixelsPerInchY * 10) div 254;
        //.. minimum margin allowed by printer
        MinMargin := GetDeviceCaps(Printer.Handle, PHYSICALOFFSETY);
        if Margin < MinMargin then begin
            Margin := MinMargin;
        end;
        //.. convert margin to offset from left printable point
        result.Top := Margin - MinMargin;

        // right margin
        //.. convert right margin to device pixels
        Margin := (MarginRightMM * PixelsPerInchX * 10) div 254;
        MinMargin :=
            GetDeviceCaps(Printer.Handle, PHYSICALWIDTH) -
            GetDeviceCaps(Printer.Handle, HORZRES) -
            GetDeviceCaps(Printer.Handle, PHYSICALOFFSETX);
        if Margin < MinMargin then begin
            Margin := MinMargin;
        end;
        //.. convert margin to device pixels
        result.Right :=
            GetDeviceCaps(Printer.Handle, PHYSICALWIDTH) -
            Margin;

        // bottom has no margin - as far as is possible down the page
        result.Bottom := GetDeviceCaps(Printer.Handle, VERTRES);
end;

end.
