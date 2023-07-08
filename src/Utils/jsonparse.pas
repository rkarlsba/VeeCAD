unit jsonparse;

interface

uses Generics.Collections, Sysutils;

type EJParse = class( Exception );

// nesting stack records opening, closing of Objects, Arrays
type TNesting = ( nsObject, nsArray );

// token describes type of token
type TToken = ( tkInitial, tkKey, tkValue, tkObject, tkArray, tkObjectEnd,
    tkArrayEnd, tkFinished );

// values accepted as next token
type TExpectedToken = (
  exObject, exArray, exKey, exValue, exComma, exColon, exCloseObject, exCloseArray );
TExpectedTokens = set of TExpectedToken;

// parse state for reporting to user
type TParseState = (
    psInitial,
    psValueString, psValueNumber, psValueInteger, psValueBoolean, psValueNull,
    psObject, psArray, psEndObject, psEndArray,
    psEnd
    );


type TJsonParser = class

  protected

    // the JSON text
    FText : string;
    // index into Text is scan position
    FScanIndex : integer;
    // most recently scanned token
    FToken : string;
    // stack, unstack object & array opens, closes.
    Stack : TStack<TNesting>;
    // state machine records set of acceptable tokens for next token
    ExpectedTokens : TExpectedTokens;
    // possibly not needed??
    FParseState : TParseState;

    FKey : string;
    FValue : string;

    FValueString : string;
    FValueInteger : integer;
    FValueFloat : extended;
    FValueBoolean : boolean;

    function AtEnd : boolean;
    function ScanToken : string;
    procedure SkipSpaces;
    function ProcessToken : boolean;
    procedure ScanEscape;
    function Escape( const S : string ) : string;

    function GetParseStateString : string;

    procedure DecodeValue;

    function GetValueString : string;
    function GetValueInteger : integer;
    function GetValueFloat : extended;
    function GetValueBoolean : boolean;

  public
    property Text : string read FText write FText;
    property ScanIndex : integer read FScanIndex write FScanIndex;

    property Token : string read FToken;
    property ParseState : TParseState read FParseState;
    property ParseStateString : string read GetParseStateString;
    property Key : string read FKey;
    property Value : string read FValue;

    // could report psValueString psValueInteger psValueFloat psValueBoolean, psValueNull
    // OR psString psInteger psFloat psBoolean, psNull
    property ValueString : string read GetValueString;
    property ValueInteger : integer read GetValueInteger;
    property ValueFloat : extended read GetValueFloat;
    property ValueBoolean : boolean read GetValueBoolean;

    procedure LoadFromFile( const FileName : string );
    procedure Reset;
    function Scan : boolean;
    function ScanLine : integer;


    constructor Create;
    destructor Destroy; override;
end;

// convert a string to JSON Escaped form
function JEsc( const S : string ) : string;

implementation

uses Classes;

constructor TJsonParser.Create;
begin
    Stack := TStack<TNesting>.Create;
end;

destructor TJsonParser.Destroy;
begin
    Stack.Free;
end;

// find which line number that current scan point
// Slow, but only used for error reporting.

function TJsonParser.ScanLine : integer;
var
    i : integer;
    c : char;
    lastchar : char;
begin
    // work thru text, counting lines until ScanIndex is reached

    lastchar := #0;
    result := 1;
    for i := 1 to FScanIndex do begin
        c := FText[i];

        if c = #13 then begin
            inc( result );
        end
        else if (c = #10) and (lastchar <> #13) then begin
            inc( result );
        end;
        lastchar := c;
    end;

    // scan is one ahead of visible text lines, so if just hit end of line,
    // jump back
    if (lastchar = #10) or (lastchar = #13) then begin
        dec( result );
    end;
end;

function TJsonParser.GetParseStateString : string;
const
    StateToStr : array[TParseState] of string =
    (
    'psInitial',
    'psValueString', 'psValueNumber', 'psValueInteger', 'psValueBoolean', 'psValueNull',
    'psObject', 'psArray', 'psEndObject', 'psEndArray',
    'psEnd'
    );
begin
    result := StateToStr[FParseState];
end;


procedure TJsonParser.SkipSpaces;
var
    c : char;
begin
    while True do begin
        c := FText[FScanIndex];
        // json never includes nulls - so use Delphi end of string null
        if c = #0 then begin
            exit;
        end;

        // ignore these chars : space, LF, CR, TAB
        if (c <> ' ') and (c <> #10) and (c <> #13) and (c <> #9) then begin
            exit;
        end;
        inc( FScanIndex );
    end;
end;

function TJsonParser.AtEnd : boolean;
begin
    result := FScanIndex > length(FText);
end;


function TJsonParser.Escape( const S : string ) : string;
var
    Limit : integer;
    i : integer;
    c : char;
begin
    // don't escape first and last " quotes
    Limit := length( S ) - 1;
    i := 2;
    // insert first " quote
    Result := '"';

    while i <= Limit do begin
        c := S[i];
        case (c) of
            #0, #10, #13: begin
                raise EJParse.CreateFmt('Unterminated string on line %d', [Scanline]);
            end;
            '\': begin
                Inc( i );
                c := S[i];
                case (c) of
                    'b': result := result + #8;
                    't': result := result + #9;
                    'n': result := result + #10;
                    'f': result := result + #12;
                    'r': result := result + #13;
                    'u': begin
                          Inc( i );
                          // next 4 chars are a hex number
                          Result := Result + WideChar(StrToInt('$' + Copy( S, i, 4 )));
                          Inc( i, 3 );
                    end;
                    '"', '\', '/' : begin
                        Result := Result + c;
                    end
                    else begin
                        raise EJParse.CreateFmt('Invalid escaped character "%s" on line %d',
                        [c, Scanline]);
                    end;
                end;
                Inc( i );
            end
            else begin
                result := result + c;
                Inc( i );
            end;
        end;
    end;

    // replace trailing " quote
    result := result + '"';
end;


// move ScanIndex to character following escape sequence,
// ScanIndex must currently reference character after a '/' character in the
// input stream.
{
   To escape an extended character that is not in the Basic Multilingual
   Plane, the character is represented as a twelve-character sequence,
   encoding the UTF-16 surrogate pair.  So, for example, a string
   containing only the G clef character (U+1D11E) may be represented as
   "\uD834\uDD1E".
}
procedure TJsonParser.ScanEscape;
var
    c : char;
    i : integer;
begin
    case FText[FScanIndex] of
        // skip over simple escape sequences
        '"', '\', '/', 'b', 'f', 'n', 'r', 't' : begin
            Inc( FScanIndex )
        end;
        'u' : begin
            for i := 0 to 3 do begin
                Inc( FScanIndex );
                c := FText[FScanIndex];
                if not CharInSet( c, ['0'..'9','A'..'F'] ) then begin
                    raise EJParse.CreateFmt( 'Invalid hex digit "%s" on line %d',
                    [ c, Scanline ] );
                end;
            end;
            Inc( FScanIndex );
         end
        else begin
            raise EJParse.CreateFmt( 'Invalid escape sequence "\%s" on line %d',
                [ FText[ScanIndex], Scanline ] );
        end;
    end;
end;

function TJsonParser.ScanToken : string;
var
    c : char;
    StartIndex : integer;
    HaveEscape : boolean;
begin
    SkipSpaces;

    if AtEnd then begin
        result := '';
        exit;
    end;

    // get first character
    c := FText[FScanIndex];
    inc( FScanIndex );


    // single token
    if Pos( c, '[]{},:' ) <> 0 then begin
         result := c;
         exit;
    end;

    // quoted token
    if c = '"' then begin

        HaveEscape := False;
        StartIndex := FScanIndex -1;

        while True do begin

            c := FText[FScanIndex];
            Inc( FScanIndex );

            // if quote not closed with second "
            if Pos( c, #10#13#0 ) <> 0 then begin
                raise EJParse.CreateFmt(
                    'unterminated quote ": %s at line %d',
                    [Copy(FText, StartIndex, FScanIndex - StartIndex), ScanLine] );
            end;

            // do escaping here
            if c = '\' then begin
                HaveEscape := True;
                ScanEscape;
            end;

            // closing quote
            if c = '"' then begin
                result := Copy(FText, StartIndex, FScanIndex - StartIndex);
                // if we had to scan over one or more escape sequences, then
                // convert escapes to characters
                if HaveEscape then begin
                    result := Escape( Result );
                end;
                exit;
            end;
        end;
    end;

    // comment
    if (c = '/') and (FText[FScanIndex] = '*') then begin
        // skip '*'
       Inc( FScanIndex );

        // skip tokens until closing '*/'
        while True do begin
            // if found end of comment
            if (FText[FScanIndex] = '*') and (FText[FScanIndex +1] = '/')then begin
                Inc( FScanIndex, 2 );
                // then scan next token (recursion)
                result := ScanToken;
                exit;
            end;
            Inc( FScanIndex );
        end;

    end;

    // unquoted token like number, true, false, null
    StartIndex := FScanIndex -1;

    while True do begin

        c := FText[FScanIndex];

        // if terminator character
        if Pos( c, '[]{},: '#10#13#0 ) <> 0 then begin
            result := Copy(FText, StartIndex, FScanIndex - StartIndex);
            exit;
        end;

        // include char once we know it is part of our value
        Inc( FScanIndex );
    end;
end;

// Consume a single token from stream, adjusting state machine in response.
// Return True=Major Scan Stage, False=Minor Scan Stage
// Major is stuff like key, value pair, array item

{
type TParseState = ( psInitial, psString, psValue, psObject, psArray,
    psEndObject, psEndArray, psEnd );
}
function TJsonParser.ProcessToken : boolean;
begin
    FToken := ScanToken;

    // nothing more to scan - end of text
    if FToken = '' then begin
        // parse state for reporting to user
        FParseState := psEnd;
        result := True;
        exit;
    end;

    // act on token

    if FToken = '{' then begin
        if (ExpectedTokens * [exObject, exValue])= []  then begin
            raise EJParse.CreateFmt( 'Misplaced "{" at Line %d', [ScanLine] );
        end;
        Stack.Push( nsObject );
        ExpectedTokens := [exKey, exCloseObject];
        FParseState := psObject;
        result := True;
        exit;
    end

    else if FToken = '}' then begin
        if (ExpectedTokens * [exCloseObject]) = [] then begin
            raise EJParse.CreateFmt( 'Unexpected "}" at Line %d', [ScanLine] );
        end;
        if (Stack.Count = 0) or (Stack.Pop <> nsObject) then begin
            raise EJParse.CreateFmt( 'Unpaired "}" at Line %d', [ScanLine] );
        end;
        if Stack.Count = 0 then begin
            ExpectedTokens := [];
        end
        else begin
            ExpectedTokens := [exComma, exCloseObject, exCloseArray];
        end;
        FParseState := psEndObject;
        result := True;
        exit;
    end

    else if FToken = '[' then begin
        if (ExpectedTokens * [exArray, exValue])= []  then begin
            raise EJParse.CreateFmt( 'Misplaced "[" at Line %d', [ScanLine] );
        end;
        Stack.Push( nsArray );
        ExpectedTokens := [exValue, exCloseArray];
        FParseState := psArray;
        result := True;
        exit;
    end

    else if FToken = ']' then begin
        if (ExpectedTokens * [exCloseArray]) = [] then begin
            raise EJParse.CreateFmt( 'Unexpected "]" at Line %d', [ScanLine] );
        end;
        if (Stack.Count = 0) or (Stack.Pop <> nsArray)                                                then begin
            raise EJParse.CreateFmt( 'Unpaired "]" at Line %d', [ScanLine] );
        end;
        if Stack.Count = 0 then begin
            ExpectedTokens := [];
        end
        else begin
            ExpectedTokens := [exComma, exCloseObject, exCloseArray];
        end;
        FParseState := psEndArray;
        result := True;
        exit;
    end

    else if FToken = ',' then begin

        if (ExpectedTokens * [exComma]) = [] then begin
            raise EJParse.CreateFmt( 'Unexpected "," at Line %d', [ScanLine] );
        end;

        if (Stack.Count = 0) then begin
            raise EJParse.CreateFmt( '"," outside of object or array at Line %d', [ScanLine] );
        end;

        // if we are inside an object
        if Stack.Peek = nsObject then begin
            ExpectedTokens := [exKey];
        end
        // else we are inside an array
        else begin
            ExpectedTokens := [exValue];
        end;
    end

    else if FToken = ':' then begin

        if (ExpectedTokens * [exColon]) = [] then begin
            raise EJParse.CreateFmt( 'Unexpected ":" at Line %d', [ScanLine] );
        end;

        ExpectedTokens := [exValue];
    end

    // quoted text
    else if FToken[1] = '"' then begin

        if exKey in ExpectedTokens then begin
            ExpectedTokens := [exColon];
            // de-quote
            FKey := Copy( FToken, 2, length(FToken) -2 );
        end
        else if exValue in ExpectedTokens then begin
            ExpectedTokens := [exComma, exCloseObject, exCloseArray];
            FValue := FToken;
            FValueString := Copy( FToken, 2, length(FToken) -2 );
            FParseState := psValueString;
            result := True;
            exit;
        end
        else begin
            raise EJParse.CreateFmt( 'Unexpected token %s at Line %d', [FToken, ScanLine] );
        end;
    end

    // unquoted text
    else begin
        if not (exValue in ExpectedTokens) then begin
            raise EJParse.CreateFmt( 'Unexpected value "%s" at Line %d', [FToken, ScanLine] );
        end;
        ExpectedTokens := [exComma, exCloseObject, exCloseArray];
        FValue := FToken;
        DecodeValue;
        result := True;
        exit;
    end;

    result := False;
end;

procedure TJsonParser.Reset;
begin
    FScanIndex := 1;
    ExpectedTokens := [exObject, exArray];
    FParseState := psInitial;
end;


// returns True = scan results available, False = Scan Finished Text Stream.
function TJsonParser.Scan : boolean;
begin
    FKey := '';
    FValue := '';

    while not ProcessToken do begin
    end;

    // nothing more to scan - end of text
    if FToken = '' then begin
        if Stack.Count <> 0 then begin
            raise EJParse.Create(
              'Parse stack shows array or object still open' );
        end
        else begin
            result := False;
            exit;
        end;
    end

    // key, value hold scanned info
    else begin
        result := True;
    end;
end;

procedure TJsonParser.LoadFromFile( const FileName : string );
var
    ss : TStringStream;
begin
    ss := TStringStream.Create( '', TEncoding.UTF8 );
    try
        ss.LoadFromFile( FileName );
        FText := ss.DataString;
    finally
        ss.Free;
    end;

    Reset;
end;

(*
procedure TJasonParser.LoadFromStream( S : stream );
begin
    ss := TStringStream.Create( '', TEncoding.UTF8 );
    try
        ss.CopyFrom( S, S.size );
        Text := ss.DataString;
    finally
        ss.Free;
    end;

    Reset;
end;
*)

function TJsonParser.GetValueString : string;
begin
    if FParseState = psValueString then begin
        result := FValueString;
    end
    else begin
        raise EJParse.CreateFmt(
            'Attempted to read a string from: %s on line %d', [FToken, Scanline] );
    end;
end;

function TJsonParser.GetValueInteger : integer;
begin
    if FParseState = psValueInteger then begin
        result := FValueInteger;
    end
    else begin
        raise EJParse.CreateFmt(
            'Attempted to read an Integer from: %s on line %d', [FToken, Scanline] );
    end;
end;

function TJsonParser.GetValueFloat : extended;
begin
    if FParseState = psValueNumber then begin
        result := FValueFloat;
    end
    else if FParseState = psValueInteger then begin
        result := FValueInteger;
    end
    else begin
        raise EJParse.CreateFmt(
            'Attempted to read a Float from: %s on line %d', [FToken, Scanline] );
    end;
end;

function TJsonParser.GetValueBoolean : boolean;
begin
    if FParseState = psValueBoolean then begin
        result := FValueBoolean;
    end
    else begin
        raise EJParse.CreateFmt(
            'Attempted to read a Boolean from: %s on line %d', [FToken, Scanline] );
    end;
end;

// Decide if value is integer, number (float), boolean, null

procedure TJsonParser.DecodeValue;
begin
    if FValue = 'null' then begin
        FParseState := psValueNull;
    end
    else if FValue = 'true' then begin
        FParseState := psValueBoolean;
        FValueBoolean := True;
    end
    else if FValue = 'false' then begin
        FParseState := psValueBoolean;
        FValueBoolean := False;
    end
    // must be an integer or number?
    // integer
    else if (Pos( '.', FValue ) = 0) and (Pos( 'E', FValue ) = 0) then begin
        FParseState := psValueInteger;
        try
            FValueInteger := StrToInt( FValue );
        except
            raise EJParse.CreateFmt( 'Unknown value %s on line %d', [FValue, Scanline] );
        end;
    end
    // float
    else begin
        FParseState := psValueNumber;
        try
            // warning: depends on DecimalSeparator system global value
            FValueFloat := StrToFloat( FValue );
        except
            raise EJParse.CreateFmt( 'Unknown value %s on line %d', [FValue, Scanline] );
        end;
    end;
end;

// Escape Special Characters as Required for JSON Strings
// This function operates on UTF16, but the results remain correct
// when saved to file in UTF8 encoding.
function JEsc( const S : string ) : string;
var
    i : integer;
    c : char;
    NeedEscape : boolean;
begin
    // Mostly, the string will not require any characters escaped,
    // so see if we can get away with doing nothing\
    NeedEscape := False;
    for i := 1 to Length( S ) do begin
        c := S[i];
        if CharInSet( c, ['"', '\', '/', #8, #12, #10, #13, #09] ) or
            (c < ' ') then begin
            // character needs escaping
            NeedEscape := True;
            break;
        end;
    end;

    // if nothing to escape, just assign (reference counted) input string for
    // lowest overhead
    if not NeedEscape then begin
        result := S;
        exit;
    end;

    // we have to escape one or more characters
    result := '';
    for i := 1 to Length(s) do begin
        c := S[i];
        case c of
            '/', '\', '"': result := result + '\' + s[i];
            #8: result := result + '\b';
            #9: result := result + '\t';
            #10: result := result + '\n';
            #13: result := result + '\r';
            #12: result := result + '\f';
            else begin
                if ord(c) < 32 then
                    result := result + '\u' + inttohex(ord(c), 4)
                else begin
                    result := result + c;
                end;
            end;
        end;
    end;
end;


end.

