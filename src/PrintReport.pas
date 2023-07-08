unit PrintReport;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, PrintStrings;

type
  TPrintReportForm = class(TForm)
    Button1: TButton;
    PrintTButton: TButton;
    SetupTButton: TButton;
    PaperTLabel: TLabel;
    PrinterNameTLabel: TLabel;
    Label1: TLabel;
    Label2: TLabel;
    PageCountTLabel: TLabel;
    PrinterSetupDialog1: TPrinterSetupDialog;
    procedure PrintTButtonClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure SetupTButtonClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    StringsPrinter : TStringsPrinter;
    FHKEY_CURRENT_USER_key : string;
    FReportStrings : TStrings;
    FPageTitle : string;
    FPrinterTitle : string;
    procedure LoadSettings;
    procedure SaveSettings;
    procedure DrawPrinterDisplay;
  public
    { Public declarations }
    property HKEY_CURRENT_USER_key : string
        read FHKEY_CURRENT_USER_key write FHKEY_CURRENT_USER_key;
    property ReportStrings : TStrings read FReportStrings write FReportStrings;
    property PageTitle : string read FPageTitle write FPageTitle;
    // Windows printer uses this document title
    property PrinterTitle : string read FPrinterTitle write FPrinterTitle;
    procedure Execute;
  end;

var
  PrintReportForm: TPrintReportForm;

implementation

uses Registry, Printers, PaperSize
{$IFNDEF VER200}, System.UITypes {$ENDIF} ;

{$R *.dfm}

// This form has position = poOwnerFormCenter, so it will appear in center
// of calling form. For this to work, this form must have an owner. Therefore
// use it like this:
(*
     ReportPrinter := TPrintReportForm.Create(self);
     try
        ..
     finally
        ReportPrinter.Free;
     end;

     NOT LIKE THIS **
     ReportPrinter := TPrintReportForm.Create(nil);
     try
        ..
     finally
        ReportPrinter.Free;
     end;
*)

// *************************************************
//         EXECUTE FUNCTION RUNS THE DIALOG
// *************************************************
procedure TPrintReportForm.Execute;
begin
    // abort if no printer available - avoid code problems
    if Printer.Printers.Count <= 0 then begin
        MessageDlg( 'No Printers installed in Windows!', mtError, [mbOK], 0 );
        exit;
    end;

    // show this form
    ShowModal;
end;

// *************************************************
//           UPDATE DISPLAY OF PRINTER DETAILS
// *************************************************
procedure TPrintReportForm.DrawPrinterDisplay;
var
    PageCount : integer;
begin
    PrinterNameTLabel.Caption := Printer.Printers[Printer.PrinterIndex];
    PaperTLabel.Caption := GetPaperSize;   // uses PaperSize.pas
    PageCount := StringsPrinter.CountPages;
    PageCountTLabel.Caption := IntToStr( PageCount );
    PrintTButton.Enabled := PageCount > 0;
end;


// *************************************************
//        INITIALISATION, FINALISATION
// *************************************************
procedure TPrintReportForm.FormCreate(Sender: TObject);
begin
    StringsPrinter := TStringsPrinter.Create;
end;

procedure TPrintReportForm.FormDestroy(Sender: TObject);
begin
    StringsPrinter.Free;
end;

procedure TPrintReportForm.FormShow(Sender: TObject);
begin
    StringsPrinter.Strings := FReportStrings;
    StringsPrinter.PageTitle := FPageTitle;
    StringsPrinter.PrinterTitle := FPrinterTitle;
    LoadSettings;
end;

procedure TPrintReportForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
    SaveSettings;
end;

// *************************************************
//          LOAD SETTINGS FROM REGISTRY
// *************************************************

procedure TPrintReportForm.LoadSettings;
const PortraitToOrientation : array[boolean] of TPrinterOrientation =
    ( poLandscape, poPortrait );
var
    IniFile : TRegIniFile;
    PrinterName : string;
    PrinterIndex : integer;
begin
    IniFile := TRegIniFile.Create( FHKEY_CURRENT_USER_KEY );
    try
        PrinterName := IniFile.ReadString( 'PrintReport', 'PrinterName', '' );
    finally
        IniFile.Free;
    end;

    // switch to printer read from INI file : stored in FPrinterName
    PrinterIndex := Printer.Printers.IndexOf( PrinterName );

    // if printer found in list, switch to it, otherwise, switches to
    // default printer (Index = -1)
    Printer.PrinterIndex := PrinterIndex;

    // update display of printer name, paper
    DrawPrinterDisplay
end;

// *************************************************
//           SAVE SETTINGS TO REGISTRY
// *************************************************
procedure TPrintReportForm.SaveSettings;
var
    IniFile : TRegIniFile;
begin
    IniFile := TRegIniFile.Create( FHKEY_CURRENT_USER_KEY );
    try
        IniFile.WriteString( 'PrintReport', 'PrinterName', Printer.Printers[Printer.PrinterIndex] );
    finally
        IniFile.Free;
    end;
end;

// *************************************************
//         USER CLICKS PRINTER SETUP BUTTON
// *************************************************

procedure TPrintReportForm.SetupTButtonClick(Sender: TObject);
begin
    // always show Portrait orientation in Printer Setup Dialog
    // If user changes orientation in Dialog, we will ignore it anyway
    Printer.Orientation := poPortrait;

    // Show Printer Setup Dialog
    if PrinterSetupDialog1.Execute then begin
        // show changed printer details
        DrawPrinterDisplay;
    end;
end;

// *************************************************
//            USE CLICKS PRINT BUTTON
// *************************************************

procedure TPrintReportForm.PrintTButtonClick(Sender: TObject);
begin
    // always portrait mode
    Printer.Orientation := poPortrait;

    // print pages on the currently selected printer
    StringsPrinter.Execute;

    // close this form
    ModalResult := mrOK;
end;

end.
