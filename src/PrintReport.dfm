object PrintReportForm: TPrintReportForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Print Report'
  ClientHeight = 115
  ClientWidth = 292
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object PaperTLabel: TLabel
    Left = 97
    Top = 27
    Width = 10
    Height = 13
    Caption = '??'
  end
  object PrinterNameTLabel: TLabel
    Left = 16
    Top = 8
    Width = 10
    Height = 13
    Caption = '??'
  end
  object Label1: TLabel
    Left = 16
    Top = 27
    Width = 32
    Height = 13
    Caption = 'Paper:'
  end
  object Label2: TLabel
    Left = 17
    Top = 46
    Width = 60
    Height = 13
    Caption = 'Page Count:'
  end
  object PageCountTLabel: TLabel
    Left = 97
    Top = 46
    Width = 10
    Height = 13
    Caption = '??'
  end
  object Button1: TButton
    Left = 204
    Top = 82
    Width = 75
    Height = 25
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 0
  end
  object PrintTButton: TButton
    Left = 120
    Top = 82
    Width = 75
    Height = 25
    Caption = 'Print'
    TabOrder = 1
    OnClick = PrintTButtonClick
  end
  object SetupTButton: TButton
    Left = 16
    Top = 82
    Width = 75
    Height = 25
    Caption = 'Setup'
    TabOrder = 2
    OnClick = SetupTButtonClick
  end
  object PrinterSetupDialog1: TPrinterSetupDialog
    Left = 248
    Top = 16
  end
end
