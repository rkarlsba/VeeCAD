unit NetReaderOrcadPCB2;

interface

uses NetReader, ExceptSafe;

// Low level access to Orcad PCB2 Netlist files.

type ESafeOrcadPCB2Reader = class( ESafe );

type TrcParseState = ( psInitial, psEnter, psComponent, psEnd );
type TrcParseResult = ( prComponent, prNet, prEnd );

type TOrcadPCB2NetReader = class( TveNetReader )

protected
  LinePosition : integer;
  ParseState : TrcParseState;
  HavePeek : boolean;
  Peeked : string;
  CurrentDesignator : string;
  function ScanToken : string; //inline;
  function GetToken : string; //inline;
  function PeekToken : string; //inline;
  procedure PutBack( Token : string );
  function GetToLineEnd : string; //inline;
  function ReadTokenQuoted : string;
  function Parse(
      var Designator, Value, Outline : string; var Net, Pin : string ) : TrcParseResult;
  procedure ResetParser;
  function GetNetlistDescriptor : string; override;


public
  function CheckCompatibility : boolean; override;

  procedure ToFirstComponent; override;
  function GetNextComponent( var Designator, Value, Outline : string ) : boolean;
      override;
  procedure ToFirstConnection; override;
  function GetNextConnection( var NetName, Designator, PinName : string )
      : boolean; override;

//    constructor Create; virtual;
//    destructor Destroy; override;
end;


implementation

uses SysUtils;

function TOrcadPCB2NetReader.CheckCompatibility: boolean;
begin
    result := True;
end;

function TOrcadPCB2NetReader.GetNetlistDescriptor : string;
begin
    result := 'OrcadPCB2';
end;

procedure TOrcadPCB2NetReader.ResetParser;
begin
    // reset parser to start of file
    LineIndex := 0;
    LinePosition := 1;
    Line := Lines[LineIndex];
    ParseState := psInitial;
    HavePeek := False;
end;

// Utility Function

// if string begins and ends with quotes, remove beginning & ending quotes

function StripQuotes( const s : string ) : string;
var
    Len : integer;
begin
    Len := Length( s );

    // string too short to have two quotes?
    if Len < 2 then begin
        result := s;
    end

    // if quotes found at start and finish, then remove them
    else if ( s[1] = '"' ) and ( s[Len] = '"' ) then begin
        result := copy( s, 2, Len-2 );
    end

    // otherwise, leave string unchanged
    else begin
        result := s;
    end;
end;


// *********** GET TOKEN ************
{ Returns next token, or '' if end of file.
}

function TOrcadPCB2NetReader.ScanToken : string;
var
    c : char;
    start : integer;
begin

    while true do begin

        // if end of line, move to next line
        if LinePosition > Length(Line) then begin
            // to start of next line
            Inc( LineIndex );

            // no more lines: return blank token
            if LineIndex >= LineLimit then begin
                result := '';
                exit;
            end;

            Line := Lines[LineIndex];
            LinePosition := 1;
        end;

        // read character and move index to next character
        c := Line[LinePosition];
        Inc( LinePosition);

        // whitespace
        if c = ' ' then begin
            continue;
        end

        // got a token!
        else begin
            break;
        end;
    end;

    // scan token until whitespace or end of line
    start := LinePosition;
    while True do begin
        c := Line[LinePosition];
        Inc( LinePosition );
        if (c = ' ') or (c = #0) then begin
            result := copy( Line, start -1, LinePosition - start );
            break;
        end;
    end;
end;

// Consume next token

function TOrcadPCB2NetReader.GetToken : string;
begin
    // PeekToken might have found next token for us.
    if HavePeek then begin
        // consume the peeked token
        result := Peeked;
        HavePeek := False;
        exit;
    end
    else begin
        result := ScanToken;
    end;
end;

// Peek at next token, but do not consume it

function TOrcadPCB2NetReader.PeekToken : string;
begin
    if not HavePeek then begin
        Peeked := ScanToken;
        HavePeek := True;
    end;
    result := Peeked;
end;

procedure TOrcadPCB2NetReader.PutBack( Token: string );
begin
    Peeked := Token;
    HavePeek := True;
end;

// consume all text to end of the current line
// assumes HavePeek = false.

function TOrcadPCB2NetReader.GetToLineEnd : string;
begin
    result := Copy( Line, LinePosition, 255 );

    // setup so scanning starts on next line
    Inc( LineIndex );
    Line := Lines[LineIndex];
    LinePosition := 1;
    HavePeek := False;
end;

// consume a token - possibly enclosed in quotation marks
// assumes HavePeek = False.
// if enclosed in quotes, the quotes are not in returned string
{$HINTS OFF}
function TOrcadPCB2NetReader.ReadTokenQuoted: string;
var
    c : char;
    scanto : char;
    start : integer;
begin
    // avoid unititialised variable warning
    c := #0;

    // skip whitespace
    while True do begin
        if LinePosition > Length(Line) then begin
            result := '';
            exit;
        end;
        c := Line[LinePosition];
        if c <> ' ' then begin
            break;
        end;
        Inc( LinePosition );
    end;

    // if next char is quote, terminating char will also be a quote
    if c = '"' then begin
        scanto := '"';
        inc( LinePosition );
    end
    else begin
        scanto := ' ';
    end;

    // record start of our token
    start := LinePosition;

    // scan to terminating char
    while True do begin
        Inc( LinePosition );
        if LinePosition > Length(Line) then begin
            break;
        end;
        c := Line[LinePosition];
        if c = scanto then begin
            break;
        end;
    end;

    // check for matching quote
    if (scanto = '"') and (c <> '"') then begin
        raise ESafeOrcadPCB2Reader.CreateFmt(
            'Unmatched quote character on line %d', [LineIndex +1] );
    end;

    // return included characters
    result := Copy( Line, start, LinePosition - Start );

    // get past terminating " (also moves past terminating space, but that
    // does not hurt
    inc( LinePosition );

end;
{$HINTS ON}


// *********** PARSER ***************

{ OrcadPCB2 Parser reads the input stream.
The parser looks for tokens and maintains a record of its state - therefore it
has no expectations about text layout or line structure, other than assuming
that each token is not broken by an end of line.
}

function TOrcadPCB2NetReader.Parse(
  var Designator, Value, Outline : string; var Net, Pin : string ) : TrcParseResult;

var
    Token : string;

    // consume text of form ( 00000068 TO-252 Q1 MTD2955E
    // extracting outline, designator, value
    procedure ReadComponent;
    begin
        // consume first token & discard it - some kind of sequence number
        Token := GetToken;
        if ( Token = '(' ) or ( Token = ')' ) then begin
          raise ESafeOrcadPCB2Reader.CreateFmt(
              'Empty component definition on line %d', [LineIndex +1] );
        end;

        // next token is package (compulsory) this may be in quotes
        Token := ReadTokenQuoted;

        if Token = '' then begin
            raise ESafeOrcadPCB2Reader.CreateFmt(
                'Missing package name on line %d', [LineIndex +1] );
        end;

        // ensure we didn't skip outline due to blank
        if ( Token = '(' ) or ( Token = ')' ) then begin
          raise ESafeOrcadPCB2Reader.CreateFmt(
              'Missing package name on line %d', [LineIndex +1] );
        end;
        Outline := Token;

        // next token is designator
        Token := GetToken;
        if ( Token = '(' ) or ( Token = ')' ) then begin
          raise ESafeOrcadPCB2Reader.CreateFmt(
              'Missing designator on line %d', [LineIndex +1] );
        end;
        Designator := Token;
        CurrentDesignator := Designator;

        // everything up to line end is the component value
        // this breaks our line-independent parser, but here we want
        // spaces kept intact. Whitespace concept does not apply here.
        Value := GetToLineEnd;
    end;

    // consume text of form ( 1 NetQ1_D )
    // extracting pin number and net name.
    procedure ReadNet;
    begin
        // first is pin name
        Token := GetToken;
        if ( Token = '(' ) or ( Token = ')' ) then begin
          raise ESafeOrcadPCB2Reader.CreateFmt(
              'Missing pin name on line %d', [LineIndex +1] );
        end;
        Pin := Token;

        // second token is net name - an may include the closing ')' with
        // no space separating it. Line might end with '))' - one char is part
        // of the net name and the other char signals end of net definition
        Token := Trim( GetToLineEnd );
        // leave out closing ')'
        if Token[ Length(Token) ] = ')' then begin
            PutBack( ')' );
            Token := Copy( Token, 1, Length(Token) -1 );
        end;
        Token := Trim( Token );
        // net names may include spaces - in that case are between quotation marks
        Token := StripQuotes( Token );
        Net := Token;

        // consume closing ')'
        Token := GetToken;
        if Token <> ')' then begin
            raise ESafeOrcadPCB2Reader.CreateFmt(
                '")" expected on line %d', [LineIndex +1] );
        end;
    end;

begin

    while( True ) do begin

        Token := GetToken;

        // we stop parsing when the outer enclosing "}" is encounterd - not by
        // hitting end of file
        if Token = '' then begin
            raise ESafeOrcadPCB2Reader.Create(
                'Unexpected end of file' );
        end;

        case ParseState of

            // starting file
            psInitial: begin
                if Token <> '(' then begin
                    raise ESafeOrcadPCB2Reader.CreateFmt(
                        'First token not "(" on line %d', [LineIndex +1] );
                end;
                ParseState := psEnter;
            end;

            // inside opening "{'
            psEnter: begin

                // component
                if Token[1] = '(' then begin

                    if Length( Token ) > 1 then begin
                        PutBack( Copy( Token, 2, 255 ));
                    end;
                    // read component stuff
                    ReadComponent;
                    ParseState := psComponent;
                    result := prComponent;
                    exit;
                end

                // end of file
                else if Token = ')' then begin
                    ParseState := psEnd;
                    result := prEnd;
                    exit;
                end

                // comment
                else if Token[1] = '{' then begin
                    // consume comment
                    repeat
                        Token := GetToken;
                        if Token = '' then begin
                            raise ESafeOrcadPCB2Reader.Create(
                                'Comment not closed by "}"'  );
                        end;
                    until Copy( Token, Length(Token), 1) = '}';
                end

                // no other token allowed
                else begin
                    raise ESafeOrcadPCB2Reader.CreateFmt(
                        'Unexpected "%s" on line %d', [Token, LineIndex +1] );
                end;
            end;

            psComponent: begin

                // net definition within the component
                if Token[1] = '(' then begin
                    if Length( Token ) > 1 then begin
                        PutBack( Copy( Token, 2, 255 ));
                    end;
                    ReadNet;
                    result := prNet;
                    exit;
                end
                // leave component
                else if Token = ')' then begin
                    ParseState := psEnter;
                    CurrentDesignator := '';
                end;
            end;

            psEnd: begin
                raise ESafeOrcadPCB2Reader.Create(
                    'Internal error: parsing after outer ")"');
            end;

          end;
    end;
end;


procedure TOrcadPCB2NetReader.ToFirstComponent;
begin
    ResetParser;
end;

procedure TOrcadPCB2NetReader.ToFirstConnection;
begin
    ResetParser;
end;



function TOrcadPCB2NetReader.GetNextComponent( var Designator, Value, Outline : string ) : boolean;
var
    ParseResult : TrcParseResult; // = ( prComponent, prNet, prEnd );T
    NetName, PinName : string;
begin
    while True do begin

        ParseResult := Parse( Designator, Value, Outline, NetName, PinName );

        case ParseResult of

            // component - what we are looking for: report it
            prComponent : begin
                FCurrentLine := LineIndex;
                result := True;
                exit;
            end;

            // net - ignore and continue until next component
            prNet: ;

            // end of all records
            prEnd: begin
                result := False;
                exit;
            end;
        end;
    end;
end;

{$HINTS OFF}
function TOrcadPCB2NetReader.GetNextConnection( var NetName, Designator, PinName : string )
    : boolean;
var
    ParseResult : TrcParseResult; // = ( prComponent, prNet, prEnd );T
    Value, Outline : string;
begin
    while True do begin

        ParseResult := Parse( Designator, Value, Outline, NetName, PinName );

        case ParseResult of

            // component - ignore and continue until next net
            prComponent: ;

            // net - what we are looking for: report it
            prNet : begin
                // if Net name is '?', then ignore this pin to net assignment.
                // Kicad sets all unconnected pins to a net of '?' instead of
                // omitting these pins from the netlist like other schematic editors.
                if NetName = '?' then begin
                    ;
                end
                // else accept pin to net assignment
                else begin
                    FCurrentLine := LineIndex;
                    result := True;
                    exit;
                end;
            end;

            // end of all records
            prEnd: begin
                result := False;
                exit;
            end;
        end;
    end;
   result := False;
end;
{$HINTS ON}

end.
