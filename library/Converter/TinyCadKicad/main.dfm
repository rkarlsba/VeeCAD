object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 731
  ClientWidth = 560
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 664
    Width = 560
    Height = 67
    Align = alBottom
    BevelKind = bkTile
    TabOrder = 0
    object CloseTButton: TButton
      Left = 464
      Top = 21
      Width = 75
      Height = 25
      Caption = 'Close'
      TabOrder = 1
      OnClick = CloseTButtonClick
    end
    object ConvertBatchTButton: TButton
      Left = 357
      Top = 21
      Width = 91
      Height = 25
      Caption = 'Convert Batch'
      TabOrder = 0
      OnClick = ConvertBatchTButtonClick
    end
    object SingleFileTGroupBox: TGroupBox
      Left = 9
      Top = 6
      Width = 200
      Height = 51
      Caption = 'Single File'
      TabOrder = 2
      object DisplayLibraryTButton: TButton
        Left = 15
        Top = 15
        Width = 91
        Height = 25
        Caption = 'Display Library'
        TabOrder = 0
        OnClick = DisplayLibraryTButtonAClick
      end
      object Button1: TButton
        Left = 112
        Top = 15
        Width = 81
        Height = 25
        Caption = 'Display Kicad'
        TabOrder = 1
        OnClick = DisplayKicadTButtonClick
      end
    end
  end
  object Memo1: TMemo
    Left = 0
    Top = 0
    Width = 560
    Height = 664
    Align = alClient
    BevelKind = bkFlat
    Lines.Strings = (
      'Memo1')
    ScrollBars = ssVertical
    TabOrder = 1
  end
end
