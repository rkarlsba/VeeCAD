unit FormMinder;

interface

uses Forms;

type TFormMinder = class

private
    FHKEY_CURRENT_USER_key : string;

public
    function RunModalForm( FormClass : TFormClass ) : integer;
    procedure AdjustForm( Form : TForm );
    procedure RecordForm( Form : TForm );
    constructor Create( const HKEY_CURRENT_USER_key : string );
end;


implementation

uses Registry, SysUtils, Windows;

// get sectionname from current resolution as recorded by Windows.

function GetSectionName : string;
begin
    result :=
        Format('DISPLAY_%d.%d.%d',
            [screen.width, screen.height, screen.pixelsperinch]);
end;

function TFormMinder.RunModalForm( FormClass : TFormClass ) : integer;
var
    Form : TForm;
begin
    Form := FormClass.Create(Application);
    TRY
        AdjustForm( Form );
        result := Form.ShowModal;
        RecordForm( Form );
    FINALLY
        Form.Free;
    END;
end;

// helper function

function ParseInteger( var pText : pChar; var number : integer ): boolean;
var
    letter : char;
begin
    number := 0;
    if pText^ = #0 then begin
        result := False;
        exit;
    end;

    while True do begin

        letter := pText^;

        if letter = #0 then begin
            result := True;
            exit;
        end;

        if letter = ',' then begin
            inc( pText );
            result := True;
            exit;
        end;

        if (letter >= '0') and (letter <= '9') then begin
            number := number * 10 + ord(letter) - ord('0');
        end;
        inc( pText );
    end;
end;



procedure TFormMinder.AdjustForm( Form : TForm );
var
    RegIniFile : TRegIniFile;
    IniString : string;
    Width, Height : integer;
    Left,Top : integer;
    Maximized : integer;
    MinShowing : integer;
    PIni : pChar;
    HaveLeft, HaveTop, HaveWidth, HaveHeight, HaveMaximized :boolean;

begin
    { screen center forms don't get sizing or positioning }
    if Form.Position = poScreenCenter then
        exit;

    { set form size / position }
    RegIniFile := TRegInifile.Create(FHKEY_CURRENT_USER_key);
    TRY
        IniString := RegIniFile.ReadString( GetSectionName, Form.ClassName, '' );
        PIni := PChar(IniString);   // access string as pointer to char
        HaveLeft := ParseInteger( Pini, Left );
        HaveTop := ParseInteger(Pini, Top );
        HaveWidth := ParseInteger(Pini, Width );
        HaveHeight := ParseInteger(Pini, Height );
        HaveMaximized := ParseInteger(Pini, Maximized );
    FINALLY
        RegIniFile.Free;
    END;

    MinShowing := GetSystemMetrics( SM_CXMINTRACK );

    { size form - move borders }
    if (Form.BorderStyle = bsSizeable) and HaveWidth and HaveHeight
        and (Width >  MinShowing) and (Width <= Screen.Width)
        and (Height > MinShowing) and (Height <= Screen.Height) then begin

        Form.Width := Width;
        Form.Height := Height;
    end;

    { position form - left, top }
    if  HaveLeft and HaveTop
        and (Left >= -MinShowing) and (Left < Screen.Width - MinShowing)
        and (Top >= -MinShowing) and (Top < Screen.Height - MinShowing)
        then begin
        Form.Left := Left;
        Form.Top := Top;
    end
    else begin
        Form.Left := (Screen.Width - Form.Width) div 2;
        Form.Top := (Screen.Height - Form.Height) div 2;
    end;

    { override above for maximised forms }
    if (HaveMaximized and (Maximized = 1)) {or 
        ( (not HaveMaximized) and (Form.BorderStyle = bsSizeable) ) } then begin
        Form.WindowState := wsMaximized;
    end;
end;

procedure TFormMinder.RecordForm( Form : TForm );
var
    RegIniFile : TRegIniFile;

begin
    { screen center forms don't get sizing or positioning }
    if Form.Position = poScreenCenter then
        exit;

    { capture any form size / position changes }
    RegIniFile := TRegInifile.Create(FHKEY_CURRENT_USER_key);
    TRY
        if Form.BorderStyle = bsSizeable then
            RegIniFile.WriteString( GetSectionName, Form.Classname,
                Format( '%d,%d,%d,%d,%d',
                [Form.Left,Form.Top,Form.Width,Form.Height,
                    Ord(Form.WindowState = wsMaximized )])
            )
        else
            RegIniFile.WriteString( GetSectionName, Form.Classname,
                Format( '%d,%d',
                [Form.left,Form.Top] ));

    FINALLY
        RegIniFile.Free;
    END;
end;

constructor TFormMinder.Create( const HKEY_CURRENT_USER_key : string );
begin
    FHKEY_CURRENT_USER_key := HKEY_CURRENT_USER_key;
end;



end.
