unit Globals;

interface

uses Registry, Forms, FormMinder, Editor;

procedure InitialiseGlobals;

procedure ReadSettings( Editor : TveEditor );
procedure SaveSettings( Editor : TveEditor );

function GetRegIniFile : TRegIniFile;
function GetFormMinder : TFormMinder;

//const HKEY_CURRENT_USER_KEY = 'Software\VeeCAD\1.0';
const HKEY_CURRENT_USER_KEY = 'Software\RKL\VeeCAD\2';

{
procedure ReadCustomOutlineEditorSettings( Editor : TveCustomOutlineEditor );
procedure SaveCustomOutlineEditorSettings( Editor : TveCustomOutlineEditor );


var
    CustomEditorCellGrey : TColor;
}

implementation

uses SysUtils, Cursors, Graphics, Painter, Windows;

{
function GetIniFileName : string;
var
    Extension : string;
begin
    result := ParamStr( 0 );
    Extension := ExtractFileExt( result );
    Delete( result, length(result) - length(Extension) +2, 255 );
    result := result + 'ini';
end;
}


function GetRegIniFile : TRegIniFile;
begin
    result := TRegIniFile.Create( HKEY_CURRENT_USER_KEY );
end;

var Minder : TFormMinder;

function GetFormMinder : TFormMinder;
begin
    result := Minder;
end;

procedure InitialiseGlobals;
begin
end;

procedure ReadSettings( Editor : TveEditor );
var
    RegIniFile : TRegIniFile;
    LeadStyle : string;
begin
    CursorMinder.HKEY_CURRENT_USER_KEY := HKEY_CURRENT_USER_KEY;
    CursorMinder.LoadSettings;

    RegIniFile := GetRegIniFile;
    try
        Editor.ComponentLineWidth  :=
            RegIniFile.ReadInteger( 'General', 'ComponentLineWidth',
            // two pixels wide default line width
            2  );
        Editor.PixelsPerCell :=
            RegIniFile.ReadInteger( 'General', 'PixelsPerCell',
                // default 13 pixels per cell at 96 dpi or equivalent at other dpi.
                (Screen.PixelsPerInch * 13) div 96 );

        // default is colors for "Lime" Color Scheme with Red selection.
        Editor.BodyColor :=
            RegIniFile.ReadInteger( 'Color', 'Body', $001F99 );
        Editor.PinColor :=
            RegIniFile.ReadInteger( 'Color', 'Pin', $21B300 );
        Editor.StripColor :=
            RegIniFile.ReadInteger( 'Color', 'Strip', $9FD7FF );
        Editor.BoardColor :=
            RegIniFile.ReadInteger( 'Color', 'Board', $FFFFFF );
        Editor.SelectionColor :=
            RegIniFile.ReadInteger( 'Color', 'Selection', $0000FF );

        Editor.NodeColors[0] :=
            RegIniFile.ReadInteger( 'Color', 'Net1', $C9C9C9 );
        Editor.NodeColors[1] :=
            RegIniFile.ReadInteger( 'Color', 'Net2', $CAC829 );
         Editor.NodeColors[2] :=
            RegIniFile.ReadInteger( 'Color', 'Net3', $0091FF );
        Editor.NodeColors[3] :=
            RegIniFile.ReadInteger( 'Color', 'Net4', $56D768 );
         Editor.NodeColors[4] :=
            RegIniFile.ReadInteger( 'Color', 'Net5', $FF5978 );
        Editor.NodeColors[5] :=
            RegIniFile.ReadInteger( 'Color', 'Net6', $23E5E2 );

        Editor.ConnectionErrorsVisible :=
            RegIniFile.ReadBool( 'Overlay', 'ConnectionErrors', False );
        Editor.NetTraceVisible :=
            RegIniFile.ReadBool( 'Overlay', 'NetTrace', False );

        LeadStyle := RegIniFile.ReadString( 'General', 'LeadStyle', '' );
        if LeadStyle = 'Line' then begin
            Editor.LeadStyle := lsLine;
        end
        else begin // LeadStyle = 'Hollow'  , also default case
            Editor.LeadStyle := lsHollow;
        end;

        // hot keys
        Editor.SelectModeShortCut := RegIniFile.ReadInteger( 'Keys', 'Select', VK_ESCAPE );
        Editor.BreakModeShortCut := RegIniFile.ReadInteger( 'Keys', 'Break', VK_F2 );
        Editor.LinkModeShortCut := RegIniFile.ReadInteger( 'Keys', 'Link', VK_F3 );
        Editor.WireModeShortCut := RegIniFile.ReadInteger( 'Keys', 'Wire', VK_F4 );
        Editor.TextModeShortCut := RegIniFile.ReadInteger( 'Keys', 'Text', VK_F5 );
        Editor.RedrawShortCut := RegIniFile.ReadInteger( 'Keys', 'Redraw', VK_F6 );

    finally
        RegIniFile.Free;
    end;
end;

procedure SaveSettings( Editor : TveEditor );
var
    RegIniFile : TRegIniFile;
const
    LeadStyle2Str : array[TLeadStyle] of string = ( 'Hollow', 'Line' );
begin
    RegIniFile := GetRegIniFile;
    try
        RegIniFile.WriteInteger( 'General', 'ComponentLineWidth',
            Editor.ComponentLineWidth );
        RegIniFile.WriteInteger( 'General', 'PixelsPerCell', Editor.PixelsPerCell );

        RegIniFile.WriteString( 'Color', 'Body', Format('$%6.6X', [Editor.BodyColor]) );
        RegIniFile.WriteString( 'Color', 'Pin', Format('$%6.6X', [Editor.PinColor]) );
        RegIniFile.WriteString( 'Color', 'Strip', Format('$%6.6X', [Editor.StripColor]) );
        RegIniFile.WriteString( 'Color', 'Board', Format('$%6.6X', [Editor.BoardColor]) );
        RegIniFile.WriteString( 'Color', 'Selection', Format('$%6.6X', [Editor.SelectionColor]) );

        RegIniFile.WriteString( 'Color', 'Net1', Format('$%6.6X', [Editor.NodeColors[0]] ));
        RegIniFile.WriteString( 'Color', 'Net2', Format('$%6.6X', [Editor.NodeColors[1]] ));
        RegIniFile.WriteString( 'Color', 'Net3', Format('$%6.6X', [Editor.NodeColors[2]] ));
        RegIniFile.WriteString( 'Color', 'Net4', Format('$%6.6X', [Editor.NodeColors[3]] ));
        RegIniFile.WriteString( 'Color', 'Net5', Format('$%6.6X', [Editor.NodeColors[4]] ));
        RegIniFile.WriteString( 'Color', 'Net6', Format('$%6.6X', [Editor.NodeColors[5]] ));


        RegIniFile.WriteBool( 'Overlay', 'ConnectionErrors', Editor.ConnectionErrorsVisible );
        RegIniFile.WriteBool( 'Overlay', 'NetTrace', Editor.NetTraceVisible );
        RegIniFile.WriteString( 'General', 'LeadStyle', LeadStyle2Str[Editor.LeadStyle] );

    finally
        RegIniFile.Free;
    end;
end;

initialization
    Minder := TFormMinder.Create( HKEY_CURRENT_USER_KEY );
finalization
    Minder.Free;
end.



