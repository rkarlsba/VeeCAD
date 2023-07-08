unit ExceptSafe;

interface

uses SysUtils;

{
Exceptions derived from this ENotFatal will be displayed to the user
in a pop-up message box, exactly as for the default Delphi exception
handling. All other exception types will be displayed, and then the
application will be shut down once the user clicks the "Close" button.

For example:

type EProject = class( Exception );
type EProject = class( ENotFatal );
}

type ESafe = class( Exception );

implementation

end.
