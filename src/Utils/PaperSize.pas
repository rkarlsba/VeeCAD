unit PaperSize;

interface

function GetPaperSize : string;


implementation

uses Windows, Printers, WinSpool, SysUtils;



function GetPaperSize : string;

type
    TPaperName = array[0..63] of Char;
    TPaperNameArray = array[1..High(Integer) div Sizeof(TPaperName)] of
    TPaperName;
    PPaperNameArray = ^TPaperNameArray;
    TPaperArray = array[1..High(Integer) div Sizeof(Word)] of Word;
    PPaperArray = ^TPaperArray;

var
    Device, Driver, Port: array[0..80] of Char;
    hDevMode: THandle;
    pDevmode: PDeviceMode;
    dmPaperSize : SHORT;   // SHORT = Smallint;   defined in Windows.pas
//    dmPaperLength: SHORT;
//    dmPaperWidth: SHORT;
    HaveSize, HaveLength, HaveWidth : boolean;

    // vars for lookup paper size
    Found : boolean;
    PaperCount : integer;
    i : integer;
    pPaperNames: PPaperNameArray;
    pPapers: PPaperArray;

begin
    // get paper size info from DEVMOD structure
    Printer.GetPrinter(Device, Driver, Port, hDevMode);
    if hDevMode = 0 then begin
        result := 'unknown (0)';
        exit;
    end;

    pDevMode := GlobalLock( hDevmode );
    if pDevMode = nil then begin
        result := 'unknown (1)';
        exit;
    end;
    try
        HaveSize := False;
        HaveLength := False;
        HaveWidth := False;

        dmPaperSize := 0;    // stops compiler warning "unititialised variable"
        if ((DM_PAPERSIZE and pDevmode^.dmFields) > 0) then begin
            dmPaperSize := pDevmode^.dmPaperSize;
            HaveSize := True;
        end;

//        dmPaperLength := 0;  // stops compiler warning "unititialised variable"
        if ((DM_PAPERLENGTH and pDevmode^.dmFields) > 0) then begin
//            dmPaperLength := pDevmode^.dmPaperLength;
            HaveLength := True;
        end;

//        dmPaperWidth := 0;   // stops compiler warning "unititialised variable"
        if ((DM_PAPERWIDTH and pDevmode^.dmFields) > 0) then begin
//            dmPaperWidth := pDevmode^.dmPaperLength;
            HaveWidth := True;
        end;

    finally
        // unlock devmode handle.
        GlobalUnlock( hDevmode );
    end;

    // process information
    // ...printer drivers should fill out dmPaperSize
    if not HaveSize then begin
        result := 'unknown (2)';
        exit;
    end;

    if dmPaperSize = 0 then begin
        if not (HaveLength and HaveWidth) then begin
            result := 'unknown (3)';
            exit;
        end;

        // paper sizes in tenths of a millimeter
{
        result := Format( 'custom %d.%d x %d.%d',
            [  dmPaperLength div 10, dmPaperLength mod 10,
               dmPaperWidth div 10, dmPaperWidth mod 10
            ] );
}
        result := 'custom';
        exit;
    end;

    // look up dmPaperSize in DeviceCapabilities, to get text stringg
    PaperCount := WinSpool.DeviceCapabilities(Device, Port, DC_PAPERNAMES, nil, nil);
    Found := False;
    if PaperCount > 0 then begin
        GetMem( pPaperNames, PaperCount * Sizeof(TPaperName) );
        try
            GetMem( pPapers, PaperCount * Sizeof(Word) );
            try
                DeviceCapabilities(Device, Port, DC_PAPERNAMES, Pchar(pPaperNames), nil);
                DeviceCapabilities(Device, Port, DC_PAPERS, Pchar(pPapers), nil);

                for i := 1 to PaperCount do begin
                    if pPapers^[i] = WORD( dmPaperSize ) then begin
                        // null terminated char array converts to string
                        result := pPaperNames^[i];
                        Found := True;
                        break;
                    end;
                end;

            finally
                FreeMem( pPapers );
            end;

        finally
            FreeMem( pPaperNames );
        end;
    end;

    // process information
    if not Found then begin
        result := 'unknown (4)';
        exit;
    end;
end;

end.

