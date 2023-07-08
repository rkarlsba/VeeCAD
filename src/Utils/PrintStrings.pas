unit PrintStrings;

interface

uses Classes, Graphics, GdiHandles;

// *****************************************************
//     TStringsPrinter OUTPUTS A TStrings TO PRINTER
// *****************************************************

// Uses a fixed pitch font.

type
TStringsPrinter = class

  protected
    FStrings : TStrings;
    FontHandle : TFontHandle;
    FPrinterTitle : string;
    FPageTitle : string;
    FTextSizePoints : integer;
    FLeftMarginChars : integer;

    // page & text settings
    //.. start lines at this many pixels X
    LineLeft : integer;
    //.. inc Y by this many pixels to start printing next line
    LineSpacing : integer;
    //.. each char requires this many pixels Y
    //CharWidth : integer;
    //.. this many characters will fit across a line
    //CharsPerLine : integer;
    PageTop : integer;
    PageBottom : integer;
    PageRight : integer;

    // index of last line in FStrings which we should print
    LastLineIndex : integer;

    procedure CalculateVerticals;
    procedure CalculateLastLineIndex;
    procedure PrintPage( LastLineIndex : integer; var LineIndex : integer );
  public
    // reference to a TStrings which you want printed
    property Strings : TStrings read FStrings write FStrings;
    // Page title.
    // Title can include %d format in order to print the page number,
    // eg. 'Radio Circuit    p.%d'
    property PageTitle : string read FPageTitle write FPageTitle;
    // Windows printer uses this document title
    property PrinterTitle : string read FPrinterTitle write FPrinterTitle;
    // size of text to use
    property TextSizePoints : integer read FTextSizePoints write FTextSizePoints;
    // left margin in characters
    property LeftMarginChars : integer read FLeftMarginChars write FLeftMarginChars;

    // do a "dummy print" and calculate number of pages
    function CountPages : integer;

    // Print now!
    procedure Execute;

    constructor Create;
    destructor Destroy; override;
end;


implementation

uses Printers, SysUtils, Windows;


constructor TStringsPrinter.Create;
begin
    inherited;
    FontHandle := TFontHandle.Create;
    FPageTitle := 'Page %d';
    FTextSizePoints := 11;
    FLeftMarginChars := 6;
end;

destructor TStringsPrinter.Destroy;
begin
    FontHandle.Free;
    inherited;
end;


// *******************************************************
//             CALCULATE VERTICAL PAGE LAYOUT
// *******************************************************

// Sets LineSpacing, PageTop, PageBottom variables.

procedure TStringsPrinter.CalculateVerticals;
var
    CharacterSizePixels : integer;
    TextHeightPixels : integer;
    PrinterPixelsPerInchY : integer;
begin
    // we can't build the font by setting the point size, because this
    // depends on PixelsPerInch of the TCanvas - and the function CountPages()
    // used to predict the number of pages as pre-printing information, does
    // not have a TCanvas available.  Thus we ESTIMATE the text height from
    // the font size;

    PrinterPixelsPerInchY := GetDeviceCaps( Printer.Handle, LOGPIXELSY );

    // turn points (character size) into pixels
    CharacterSizePixels := ( TextSizePoints * PrinterPixelsPerInchY ) div 72;

    // We estimate the Windows Text Height from the character size.
    // Regardless of the actual Text Height, this is the text height we
    // assume for the purposes of calculating line spacing.
    TextHeightPixels := ( CharacterSizePixels * 98 ) div 91;

    // We use Line Spacing = TextHeight - a typical choice for line spacing
    LineSpacing := TextHeightPixels;

    // also calculates line spacing
    PageTop := LineSpacing * 2;
    PageBottom := Printer.PageHeight - (LineSpacing * 2);
end;

// ****************************************************
//      CALCULATE INDEX OF LAST LINE TO PRINT
// ****************************************************

procedure TStringsPrinter.CalculateLastLineIndex;
var
    i : integer;
begin
    if not Assigned( Strings ) then begin
        LastLineIndex := -1;
    end;

    // test lines starting from last, to find index of last non-blank line
    LastLineIndex := -1;
    for i := Strings.Count -1 downto 0 do begin
        // if found some text
        if Trim(Strings[i]) <> '' then begin
            LastLineIndex := i;
            break;
        end;
    end;
end;


procedure TStringsPrinter.PrintPage( LastLineIndex : integer; var LineIndex : integer );
var
    hFontSave : THandle;
    PageY : integer;
    PageHeading : string;
    PageHeadingRect : TSize;
begin
    hFontSave := SelectObject( Printer.Canvas.Handle, FontHandle.Handle );
    try
        PageY := PageTop;
        // print header, including page number, at right hand page side
        // .. Title can include %d format in order to print the page number,
        //.. eg. 'Radio Circuit    p.%d'
        PageHeading := Format( FPageTitle, [Printer.PageNumber]);
        GetTextExtentPoint32(
            Printer.Canvas.Handle,
            pChar( PageHeading ),
            length( PageHeading ),
            &PageHeadingRect
        );

        TextOut(
            Printer.Canvas.Handle,
            PageRight - PageHeadingRect.cx,
            PageY,
            pChar(PageHeading),
            length(PageHeading)
        );
        // couple of blank lines below heading
        Inc( PageY, LineSpacing );
        Inc( PageY, LineSpacing );

        while True do begin

            // if line is too long, it is truncated - not wrapped
            TextOut(
                Printer.Canvas.Handle,
                LineLeft,
                PageY,
                pChar(Strings[LineIndex]),
                length(Strings[LineIndex])
            );

            // to next line
            Inc( LineIndex );
            if LineIndex > LastLineIndex then begin
                exit;
            end;

            // to next line position on page
            Inc( PageY, LineSpacing );
            if PageY > PageBottom - LineSpacing then begin
                exit;
            end;
        end;
    finally
        SelectObject( Printer.Canvas.Handle, hFontSave );
    end;
end;



procedure TStringsPrinter.Execute;
var
    LineIndex : integer;
    hFontSave : THandle;
    TextMetrics : TTextMetric;
    PixelsPerInchY : integer;
begin
    CalculateLastLineIndex;

    // if all lines were blank, nothing to print
    if LastLineIndex < 0 then begin
         exit;
    end;

    // Calculate Vertical Page Layout
    CalculateVerticals;

    // initialise
    LineIndex := 0;

    // Orientation, Copies, Title must be set before Printer.BeginDoc()
    //    Printer.Orientation := FOrientation;
    //    Printer.Copies := PagesCopiesTUpDown.Position;
    //.. windows shows this title in printer queue
    Printer.Title := FPrinterTitle;

    // printer canvas & properties are invalid until we do BeginDoc
    Printer.BeginDoc;

    //    PixelsPerInchX := GetDeviceCaps(Printer.Handle, LOGPIXELSX);
    PixelsPerInchY := GetDeviceCaps(Printer.Canvas.Handle, LOGPIXELSY);

    // font handle provides a fixed pitch font without specifying a name
    FontHandle.Name := '';
    FontHandle.Pitch := piFixed;
    //.. convert points to pixels height
    FontHandle.Height := ( TextSizePoints * PixelsPerInchY ) div 72;

    // use font to calculate page appearance
    //.. font is created when we first access its handle
    hFontSave := SelectObject( Printer.Canvas.Handle, FontHandle.Handle );
    try
        // calculate sensible borders, line spacing etc. based on font
        // tmHeight is same as Printer.Canvas.Textheight( 'X' );
        GetTextMetrics( Printer.Canvas.Handle, TextMetrics );
        LineLeft := TextMetrics.tmAveCharWidth * FLeftMarginChars;
        PageRight := Printer.PageWidth - ( TextMetrics.tmAveCharWidth * 6 );
    finally
        SelectObject( Printer.Canvas.Handle, hFontSave );
    end;

    // print lines and pages until finished
    while True do begin

        // print as many lines will fit on a page
        PrintPage( LastLineIndex, LineIndex );

        // if all lines printed, finish
        if LineIndex > LastLineIndex then begin
            break;
        end;

        // new page into printer
        Printer.NewPage;
    end;

    Printer.EndDoc;
end;


// do a "dummy print" and calculate number of pages
function TStringsPrinter.CountPages : integer;

    procedure PrintPage( LastLineIndex : integer; var LineIndex : integer );
    var
        PageY : integer;
    begin
        PageY := PageTop;

        // Print Heading here..

        // couple of blank lines below heading
        Inc( PageY, LineSpacing );
        Inc( PageY, LineSpacing );


        while True do begin

            // Print Line Here..

            // to next line
            Inc( LineIndex );
            if LineIndex > LastLineIndex then begin
                exit;
            end;

            // to next line position on page
            Inc( PageY, LineSpacing );
            if PageY > PageBottom - LineSpacing then begin
                exit;
            end;
        end;
    end;

var
    LineIndex : integer;
    PageCount : integer;
begin
    // we print from first line to FStrings[LastLineIndex]
    CalculateLastLineIndex;

    // no lines to print!
    if LastLineIndex < 0 then begin
        result := 0;
        exit;
    end;

    CalculateVerticals;


    // pretend to print lines and pages until finished
    PageCount := 1;
    LineIndex := 0;
    while True do begin

        // print as many lines will fit on a page
        PrintPage( LastLineIndex, LineIndex );

        // if all lines printed, finish
        if LineIndex > LastLineIndex then begin
            break;
        end;

        // new page into printer
        Inc( PageCount );
    end;

    result := PageCount;
end;


end.

