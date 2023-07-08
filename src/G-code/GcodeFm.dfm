object GcodeForm: TGcodeForm
  Left = 0
  Top = 0
  HelpContext = 693
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'G-code'
  ClientHeight = 502
  ClientWidth = 423
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Memo1: TMemo
    Left = 8
    Top = 8
    Width = 392
    Height = 369
    Lines.Strings = (
      'Memo1')
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object Button1: TButton
    Left = 19
    Top = 465
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Close'
    ModalResult = 11
    TabOrder = 1
  end
  object Panel1: TPanel
    Left = 8
    Top = 392
    Width = 397
    Height = 57
    ShowCaption = False
    TabOrder = 2
    object Label1: TLabel
      Left = 8
      Top = 1
      Width = 54
      Height = 13
      Caption = 'Save to file'
    end
    object FileNameTEdit: TEdit
      Left = 8
      Top = 20
      Width = 353
      Height = 21
      TabOrder = 0
    end
    object FileNameTButton: TButton
      Left = 367
      Top = 16
      Width = 25
      Height = 25
      Caption = '...'
      TabOrder = 1
      OnClick = FileNameTButtonClick
    end
  end
  object SaveTButton: TButton
    Left = 330
    Top = 465
    Width = 75
    Height = 25
    Caption = 'Save'
    TabOrder = 3
    OnClick = SaveTButtonClick
  end
  object CopyTButton: TButton
    Left = 238
    Top = 465
    Width = 75
    Height = 25
    Caption = 'Copy'
    TabOrder = 4
    OnClick = CopyTButtonClick
  end
end
