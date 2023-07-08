object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 514
  ClientWidth = 495
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 120
  TextHeight = 16
  object Label1: TLabel
    Left = 8
    Top = 10
    Width = 100
    Height = 16
    Caption = '.CIR File To Read'
  end
  object Label2: TLabel
    Left = 8
    Top = 142
    Width = 108
    Height = 16
    Caption = 'Component Names'
  end
  object CIRFileNameTEdit: TEdit
    Left = 8
    Top = 32
    Width = 433
    Height = 24
    TabOrder = 0
    Text = 'CIRFileNameTEdit'
  end
  object CIRFileNameTButton: TButton
    Left = 447
    Top = 32
    Width = 34
    Height = 25
    Caption = '...'
    TabOrder = 1
    OnClick = CIRFileNameTButtonClick
  end
  object WriteComponentNameFileTButton: TButton
    Left = 8
    Top = 445
    Width = 209
    Height = 25
    Caption = 'Write  Component Names File'
    TabOrder = 2
    OnClick = WriteComponentNameFileTButtonClick
  end
  object Memo1: TMemo
    Left = 8
    Top = 164
    Width = 233
    Height = 275
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Courier New'
    Font.Style = []
    Lines.Strings = (
      'Memo1')
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 3
  end
  object ReadCIRFileTButton: TButton
    Left = 8
    Top = 88
    Width = 129
    Height = 25
    Caption = 'Read .CIR file'
    TabOrder = 4
    OnClick = ReadCIRFileTButtonClick
  end
  object OpenDialog1: TOpenDialog
    Options = [ofHideReadOnly, ofFileMustExist, ofEnableSizing]
    Left = 448
    Top = 64
  end
  object SaveDialog1: TSaveDialog
    Options = [ofOverwritePrompt, ofHideReadOnly, ofFileMustExist, ofEnableSizing]
    Left = 232
    Top = 448
  end
end
