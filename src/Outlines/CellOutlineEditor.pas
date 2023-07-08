unit CellOutlineEditor;

interface

uses Grids, Windows, Messages, Classes, Controls,
    CelledOutlines, ExceptSafe;

type
    ESafeCelledOutlineEditor = class( ESafe );


type TCellOutlneEditor = class(TCustomControl)

    protected

    FOutline : TveCellOutline;
    FOnChanged : TNotifyEvent;

    FColCount : integer;
    FRowCount : integer;
    FRowHeight : integer;
    FColWidth : integer;
    FLineWidth : integer;
    FTopRow : integer;
    FLeftCol : integer;

    FCol, FRow : integer;

    // buffered access to pin names
    NewOutline : boolean;
    EditX, EditY : integer;
    EditText : string;

    // buffered access to pin names
    function GetPinName( x, y : integer ) : string;
    procedure SetPinName( x, y : integer; value : string );

    procedure WMVScroll(var Msg: TWMVScroll); message WM_VSCROLL;
    procedure WMHScroll(var Msg: TWMHScroll); message WM_HSCROLL;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WMGetDlgCode(var message: TMessage); message WM_GETDLGCODE;

    procedure KeyPress(var Key: Char); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

    function ColsAcross : integer;
    function RowsDown : integer;
    procedure PaintHeadings;
    procedure PaintCell( ACol, ARow : integer );
    procedure Paint; override;

    procedure SetHorzScroll;
    procedure SetVertScroll;
    procedure Changed;
    procedure SetOutline( value : TveCellOutline ) ;

    public

    constructor Create(AOwner: TComponent); override;
    property Outline : TveCellOutline read FOutline write SetOutline;

    property Align;
    property Color;
    property Ctl3D;
    property Enabled;
    property Font;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Visible;
    property OnEnter;
    property OnExit;

    property OnChanged : TNotifyEvent read FOnChanged write FOnChanged;

    property RowHeight : integer read FRowHeight write FRowHeight;
    property ColWidth : integer read FColWidth write FColWidth;
    property LineWidth : integer read FLineWidth write FLineWidth;
end;



implementation

uses SysUtils, Graphics, Outlines, Forms;  //(forms added during debug)

// *********************************
//      TCellOutlineEditor
// *********************************

constructor TCellOutlneEditor.Create(AOwner: TComponent);
begin
    inherited Create(AOwner);
    FColCount := 7;
    FRowCount := 7;

    // these values will need initialising depending on Screen.PixelsPerInch
    FRowHeight := 15;
    FColWidth := 30;
    FLineWidth := 1;

    // initialise here - may need different code later
    FColCount := TveCellOutline_MaxWidth;
    FRowCount := TveCellOutline_MaxHeight;
end;

procedure TCellOutlneEditor.CreateParams(var Params: TCreateParams);
begin
    inherited CreateParams(Params);
    Params.Style := Params.Style or WS_VSCROLL or WS_HSCROLL {or WS_BORDER};
end;


procedure TCellOutlneEditor.Changed;
begin
    if Assigned( FOnChanged ) then begin
        FOnChanged( self );
    end;
end;


// Handle a Windows Message to request arrow key messages sent to this
// TWinControl as well as ordinary key messages.  Plus, DLGC_WANTCHARS
// stops the containing form from stealing accelerator keys when ALT is not
// pressed - Delphi forms behave like that. This message is sent on every
// keystroke received when this control has the focus.
procedure TCellOutlneEditor.WMGetDlgCode(var message: TMessage);
begin
    message.Result := DLGC_WANTARROWS or DLGC_WANTCHARS;
end;


// *** UTILITY FUNCTION BUFFERS PIN NAMES ***
// Call this to read value of a pin
// Once user edits a pin name, we use a buffered value of Name, so as to allow
// user to add spaces - however the Name saved into the TveCellOutline has
// leading/trailing spaces removed.

function TCellOutlneEditor.GetPinName( x, y : integer ) : string;
begin
    // in newly editing this cell, load from outline
    if NewOutline or (EditX <> x) or (EditY <> y) then begin
        NewOutline := False;
        EditX := x;
        EditY := y;
        EditText := FOutline.CellPinNames[FCol,FRow];
    end;

    result := EditText;
end;

// *** UTILITY FUNCTION BUFFERS PIN NAMES ***
// Call this to set value of a pin
procedure TCellOutlneEditor.SetPinName( x, y : integer; value : string );
begin
    // in newly editing this cell remember it!
    if NewOutline or (EditX <> x) or (EditY <> y) then begin
        NewOutline := False;
        EditX := x;
        EditY := y;
    end;

     // buffered value allows editing with spaces
    EditText := value;
    // outline value must not begin/end with a space
    FOutline.CellPinNames[FCol,FRow] := trim( value );
end;


procedure TCellOutlneEditor.KeyDown(var Key: Word; Shift: TShiftState);
var
    OldCellX, OldCellY : integer;

begin
    // do nothing if no outline or wrong type of outline
    if not Assigned(FOutline) then begin
        exit;
    end;

    // will repaint previous selected cell to remove highlight
    OldCellX := FCol;
    OldCellY := FRow;

    // act on key
    case Key of

        VK_LEFT : begin
            dec( FCol );
            if FCol < 0 then begin
                FCol := 0;
            end;
            if FCol < FLeftCol then begin
                FLeftCol := FCol;
                SetHorzScroll;
                Paint;
                exit;
            end;
        end;
        VK_RIGHT : begin
            inc( FCol );
            if FCol >= FColCount then begin
                FCol := FColCount -1;
            end;
            if FCol >= FLeftCol + ColsAcross then begin
                FLeftCol := FCol - ColsAcross +1;
                SetHorzScroll;
                Paint;
                exit;
            end;
        end;
        VK_UP : begin
            dec( FRow );
            if FRow < 0 then begin
                FRow := 0
            end;
            if FRow < FTopRow then begin
                FTopRow := FRow;
                SetVertScroll;
                Paint;
                exit;
            end;
        end;
        VK_DOWN : begin
            inc( FRow );
            if FRow >= FRowCount then begin
                FRow := FRowCount -1;
            end;
            if FRow >= FTopRow + RowsDown then begin
                FTopRow := FRow - RowsDown +1;
                SetVertScroll;
                Paint;
                exit;
            end;
        end;
        VK_HOME : begin
            FCol := 0;
            FRow := 0;
            FLeftCol := 0;
            FTopRow := 0;
            SetVertScroll;
            SetHorzScroll;
            Paint;
            exit;
        end;
        VK_END : begin
            FCol := FOutline.Width -1;
            FRow := FOutline.Height -1;
            FTopRow := 0;
            FLeftCol := 0;
            if FRow >= FTopRow + RowsDown then begin
                FTopRow := FRow - RowsDown +1;
            end;
            if FCol >= FLeftCol + ColsAcross then begin
                FLeftCol := FCol - ColsAcross +1;
            end;
            SetVertScroll;
            SetHorzScroll;
            Paint;
            exit;
        end;
        VK_PRIOR : begin
            SendMessage( handle, WM_VSCROLL, SB_PAGEUP,  0 );
        end;
        VK_NEXT : begin
            SendMessage( handle, WM_VSCROLL, SB_PAGEDOWN,  0 );
        end;
{
        VK_SPACE : begin
            if FOutline.CellTypes[FCol,FRow] = ctFree then begin
                FOutline.CellTypes[FCol,FRow] := ctBody;
            end
            else begin
                FOutline.CellTypes[FCol,FRow] := ctFree;
            end;
            Changed;
        end;
}
        VK_DELETE : begin
            if FOutline.CellTypes[FCol,FRow] = ctPin then begin
                FOutline.CellTypes[FCol,FRow] := ctBody;
            end
            else if FOutline.CellTypes[FCol,FRow] = ctBody then begin
                FOutline.CellTypes[FCol,FRow] := ctFree;
            end
            else begin
                FOutline.CellTypes[FCol,FRow] := ctBody;
            end;
            Changed;
        end;

        VK_RETURN : begin
            if FOutline.CellTypes[FCol,FRow] = ctPin then begin
            end
            else if FOutline.CellTypes[FCol,FRow] = ctBody then begin
                FOutline.CellTypes[FCol,FRow] := ctFree;
            end
            else begin
                FOutline.CellTypes[FCol,FRow] := ctBody;
            end;
            Changed;
        end;

        // ignore other keys
        else begin
            // swallow every other key unless it is an Accelerator, otherwise
            // The parent form may swallow it - Delphi forms will act
            // accelerator keys *even if the ALT key is not pressed*
{
            if not( ssAlt in Shift) then begin
                Key := 0;
            end;
}
            exit;
        end;
    end;

    // paint previously selected cell
    PaintCell( OldCellX, OldCellY );

    // paint new selected cell to show highlight
    PaintCell( FCol, FRow );
end;


procedure TCellOutlneEditor.KeyPress(var Key: Char);
var
//    CellType : TCellType;
    Value : string;
    PinName : string;
begin
//    inherited KeyPress( Key );

    // do nothing if no outline or wrong type of outline
    if not Assigned(FOutline) then begin
        exit;
    end;

    // we respond to number keys here in KeyPress, because main & keypad
    // number keys get converted to a single ASCII value.  In OnKeyDown,
    // these keys are not combined and possibly may even be different for
    // different language keyboards.

    case Key of

        char(VK_BACK) : begin

            // if cell is pin, then use key value to alter existing PinNo
            if FOutline.CellTypes[FCol,FRow] = ctPin then begin
                PinName := GetPinName( FCol, FRow );
                PinName := Trim( Copy( PinName, 1, Length(PinName)-1 ) );

                // blank pin names are not allowed - turn into body cell
                if PinName = '' then begin
                    FOutline.CellTypes[FCol,FRow] := ctBody;
                end

                // show edited pin
                else begin
                    SetPinName( FCol, FRow, PinName );
                end;

               // paint selected cell to show change
               PaintCell( FCol, FRow );
               Changed;
            end
        end;

        else begin 

            Value := Key;
            Key := Char(0);

            // if cell is a pin, retrieve its PinName
            if FOutline.CellTypes[FCol,FRow] = ctPin then begin
                PinName := GetPinName( FCol, FRow );
            end

            // if cell is not pin, make it a pin & give it key value as PinNo
            else begin

                // too many pins?
                if FOutline.PinCount > TveMaxPinIndex then begin
                    raise ESafeCelledOutlineEditor.Create( 'Too many pins' );
                end;

                FOutline.CellTypes[FCol,FRow] := ctPin;
                SetPinName( FCol, FRow, '' );
                PinName := '';
            end;

            // use key value to alter existing PinNo
            // Trim means no spaces will ever appear in pin name, because
            // the only way to add a space is to type it on the end of the
            // string
            PinName := PinName + Value;

            // blank pin names are not allowed - turn into body cell
            if PinName = '' then begin
                FOutline.CellTypes[FCol,FRow] := ctBody;
            end
            // show edited pin
            else begin
                SetPinName( FCol, FRow, PinName );
            end;

            // paint selected cell to show change
            PaintCell( FCol, FRow );
            Changed;
        end;
    end
end;

procedure TCellOutlneEditor.MouseDown(
    Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

var
    NewCellX, NewCellY : integer;
    OldCellX, OldCellY : integer;
begin
    // do nothing if no outline or wrong type of outline
    if not Assigned(FOutline) then begin
        exit;
    end;

    // calculate X, Y or clicked cell
    NewCellX := FLeftCol + (X div (FColWidth + FLineWidth)) -1;
    NewCellY := FTopRow + (Y div (FRowHeight +FLineWidth)) -1;

    // if clicked position doesn not map to a visible cell
    if (NewCellX < FLeftCol) or (NewCellX >= FLeftCol + ColsAcross) or
        (NewCellY < FTopRow) or (NewCellY >= FTopRow + RowsDown) then begin
        exit;
    end;

    // will repaint previous selected cell to remove highlight
    OldCellX := FCol;
    OldCellY := FRow;

    // move selection to new cell selected
    FCol := NewCellX;
    FRow := NewCellY;

    // if a right-click, toggle cell state between blank and body
    if Shift = [ssRight] then begin

        if FOutline.CellTypes[FCol,FRow] = ctFree then begin
            FOutline.CellTypes[FCol,FRow] := ctBody;
        end
        else begin
            FOutline.CellTypes[FCol,FRow] := ctFree;
        end;
        Changed;
     end;

    // paint previously selected cell
    PaintCell( OldCellX, OldCellY );

    // paint new selected cell to show highlight
    PaintCell( FCol, FRow );

    // focus means Windows will direct keystrokes to this control
    SetFocus;
end;

const CellSelectedColor = clLtGray; // clGray;    //clBtnFace;

procedure TCellOutlneEditor.PaintCell( ACol, ARow : integer );
var
    X1, Y1 : integer;
    X2, Y2 : integer;
    ARect : TRect;
    TheText : string;
    PenWidth : integer;
    OldWidth : integer;

begin
    // no data
    if not Assigned( FOutline ) then begin
        Canvas.Brush.Color := clWindow;
        Canvas.FillRect( ARect );
        exit;
    end;

    // nothing to do if outside display window
    if (ACol < FLeftCol) or (ACol > FLeftCol + ColsAcross +1) or
        (ARow < FTopRow) or (ARow > FTopRow + RowsDown +1) then begin

        exit;
    end;

    Canvas.Font := Font;

    // calculate cell bounding rectangle
    X1 := FLineWidth + ((ACol+1-FLeftCol)* (FColWidth + FLineWidth));
    X2 := X1 + FColWidth {+ FLineWidth};
    Y1 := FLineWidth + ((ARow+1-FTopRow) * (FRowHeight + FLineWidth));
    Y2 := Y1 + FRowHeight {+ FLineWidth};
    ARect := Rect(X1, Y1, X2, Y2);

    case FOutline.CellTypes[ACol,ARow] of
        ctFree : begin
            // leave blank
            Canvas.Brush.Color := clWindow;
            Canvas.FillRect( ARect );
        end;
        ctBody : begin
            // draw rectangle
            Canvas.Brush.Color := CellSelectedColor;
            Canvas.FillRect( ARect );
        end;
        ctPin : begin
            // draw pin number
            Canvas.Brush.Color := CellSelectedColor;
            Canvas.Pen.Color := clWindowText;
            TheText := FOutline.CellPinNames[ACol,ARow];
            with ARect, Canvas do
            TextRect(ARect, Left + (Right - Left - TextWidth(TheText)) div 2,
                Top + (Bottom - Top - TextHeight(TheText)) div 2, TheText);
        end;
    end;

    // if cell is selected, highlight it
    if (ACol = FCol) and (ARow = FRow) then begin
        PenWidth := (ARect.Right - ARect.Left) div 12;
        Canvas.Pen.Color := clHighLight;
        OldWidth := Canvas.Pen.Width;
        Canvas.Pen.Width := PenWidth;
        Canvas.Brush.Style := bsClear;

        Canvas.MoveTo( ARect.Right-1, ARect.Top + 1);
        Canvas.LineTo( ARect.Right-1, ARect.Bottom-1);
        Canvas.LineTo( ARect.Left + 1, ARect.Bottom-1);
        Canvas.Pen.Width := OldWidth;
    end;
end;

function TCellOutlneEditor.ColsAcross : integer;
begin
   result :=
        (Width - FLineWidth - FLineWidth - FColWidth - GetSystemMetrics(SM_CXVSCROLL))
        div (FColWidth + FLineWidth);
end;

function TCellOutlneEditor.RowsDown : integer;
begin
    result :=
        (Height - FLineWidth - FLineWidth - FRowHeight - GetSystemMetrics(SM_CYHSCROLL))
        div (FRowHeight + FLineWidth);
end;


procedure TCellOutlneEditor.PaintHeadings;
var
    i : integer;
    TheText : string;
    ARect : TRect;
    X1, Y1 : integer;
    X2, Y2 : integer;
begin
    Canvas.Font := Font;

    Canvas.Brush.Color := clBtnFace;
    Canvas.Pen.Color := clWindowText;

    // top row contains col headings
    Y1 := FLineWidth;
    Y2 := Y1 + FRowHeight;

    for i := 1 to ColsAcross do begin

        // cell dimensions
        X1 := FLineWidth + (i * (FColWidth + FLineWidth));
        X2 := X1 + FColWidth {+ FLineWidth};
        ARect := Rect(X1, Y1, X2, Y2);

        // text inside cell
        TheText := IntToStr( i + FLeftCol );
        Canvas.TextRect(ARect, X1 + (X2 - X1 - Canvas.TextWidth(TheText)) div 2,
            Y1 + (Y2 - Y1 - Canvas.TextHeight(TheText)) div 2, TheText);

        // line around cell
        Canvas.MoveTo( X1-1, Y1-1 );
        Canvas.LineTo( X2, Y1-1 );
        Canvas.LineTo( X2, Y2 );
        Canvas.LineTo( X1-1, Y2 );
        Canvas.LineTo( X1-1, Y1-1 );
    end;

    // left col contains row of headings
    X1 := FLineWidth;
    X2 := X1 + FColWidth;

    for i := 1 to RowsDown do begin

        // cell dimensions
        Y1 := FLineWidth + (i * (FRowHeight + FLineWidth));
        Y2 := Y1 + FRowHeight;
        ARect := Rect(X1, Y1, X2, Y2);

        // text inside cell
        TheText := IntToStr( i + FTopRow );
        Canvas.TextRect(ARect, X1 + (X2 - X1 - Canvas.TextWidth(TheText)) div 2,
            Y1 + (Y2 - Y1 - Canvas.TextHeight(TheText)) div 2, TheText);

        // line around cell
        Canvas.MoveTo( X1 -1, Y1-1 );
        Canvas.LineTo( X2, Y1-1 );
        Canvas.LineTo( X2, Y2 );
        Canvas.LineTo( X1-1, Y2 );
        Canvas.LineTo( X1-1, Y1-1 );
    end;
end;


procedure TCellOutlneEditor.Paint;
var
    i , j : integer;
begin
    PaintHeadings;

    // paint cells
    for i := 0 to FColCount -1 do begin
        for j := 0 to FRowCount -1 do begin
            PaintCell( i, j );
        end;
    end;
end;


procedure TCellOutlneEditor.SetHorzScroll;
var ScrollInfo : TScrollInfo;
begin
    ScrollInfo.cbSize := sizeof(TScrollInfo);
    ScrollInfo.fMask := SIF_POS or SIF_RANGE or SIF_PAGE;
    ScrollInfo.nMin := 0;
    ScrollInfo.nMax := FColCount - 1;
    ScrollInfo.nPage := ColsAcross;
    ScrollInfo.nPos := FLeftCol;
    ScrollInfo.nTrackPos := 0;

    SetScrollInfo( handle, SB_HORZ, ScrollInfo, TRUE );
end;

procedure TCellOutlneEditor.SetVertScroll;
var ScrollInfo : TScrollInfo;
begin
    ScrollInfo.cbSize := sizeof(TScrollInfo);
    ScrollInfo.fMask := SIF_POS or SIF_RANGE or SIF_PAGE;
    ScrollInfo.nMin := 0;
    ScrollInfo.nMax := FRowCount -1;
    ScrollInfo.nPage := RowsDown;
    ScrollInfo.nPos := FTopRow;
    ScrollInfo.nTrackPos := 0;

    SetScrollInfo( handle, SB_VERT, ScrollInfo, TRUE );
end;


procedure TCellOutlneEditor.WMVScroll(var Msg: TWMVScroll);
begin
    case Msg.ScrollCode of

        SB_THUMBPOSITION, SB_THUMBTRACK : begin
            FTopRow := Msg.Pos;
        end;
        SB_LINEDOWN : begin
            Inc( FTopRow );
            if FTopRow > FRowCount - RowsDown then begin
                FTopRow := FRowCount - RowsDown;
            end;
        end;
        SB_LINEUP : begin
            Dec( FTopRow );
            if FTopRow < 0 then begin
                FTopRow := 0;
            end;
        end;
        SB_PAGEDOWN : begin
            Inc( FTopRow, RowsDown -1 );
            if FTopRow > FRowCount - RowsDown then begin
                FTopRow := FRowCount - RowsDown;
            end;
        end;
        SB_PAGEUP : begin
            Dec( FTopRow, RowsDown -1 );
            if FTopRow < 0 then begin
                FTopRow := 0;
            end;
        end
        else begin
            exit;
        end;
    end;

    SetVertScroll;
    Paint;
    {
  TWMScroll = packed record
    Msg: Cardinal;
    ScrollCode: Smallint; // SB_xxxx
    Pos: Smallint;
    ScrollBar: HWND;
    Result: Longint;
  end;
}
end;

procedure TCellOutlneEditor.WMHScroll(var Msg: TWMHScroll);
begin
    case Msg.ScrollCode of

        SB_THUMBPOSITION, SB_THUMBTRACK : begin
            FLeftCol := Msg.Pos;
        end;
        SB_LINERIGHT : begin
            Inc( FLeftCol );
            if FLeftCol > FColCount - ColsAcross then begin
                FLeftCol := FColCount - ColsAcross;
            end;
        end;
        SB_LINELEFT : begin
            Dec( FLeftCol );
            if FLeftCol < 0 then begin
                FLeftCol := 0;
            end;
        end;
        SB_PAGERIGHT : begin
            Inc( FLeftCol, ColsAcross -1 );
            if FLeftCol > FColCount - ColsAcross then begin
                FLeftCol := FColCount - ColsAcross;
            end;
        end;
        SB_PAGELEFT : begin
            Dec( FLeftCol, ColsAcross -1 );
            if FLeftCol < 0 then begin
                FLeftCol := 0;
            end;
        end
        else begin
            exit;
        end;
    end;
    SetHorzScroll;
    Paint;
end;



procedure TCellOutlneEditor.SetOutline( value : TveCellOutline ) ;
begin
    FOutline := value;
    FRow := 0;
    FCol := 0;
    FTopRow := 0;
    FLeftCol := 0;
    SetVertScroll;
    SetHorzScroll;
    Paint;
    NewOutline := True;
end;

end.


