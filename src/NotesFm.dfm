object NotesForm: TNotesForm
  Left = 0
  Top = 0
  HelpContext = 635
  BorderIcons = [biSystemMenu]
  Caption = 'Notes'
  ClientHeight = 302
  ClientWidth = 445
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poMainFormCenter
  OnDeactivate = FormDeactivate
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 265
    Width = 445
    Height = 37
    Align = alBottom
    TabOrder = 0
    object PrintTButton: TButton
      Left = 335
      Top = 6
      Width = 75
      Height = 25
      Caption = 'Print...'
      TabOrder = 1
      OnClick = PrintTButtonClick
    end
    object CopyTButton: TButton
      Left = 254
      Top = 6
      Width = 75
      Height = 25
      Caption = 'Copy'
      TabOrder = 2
      OnClick = CopyTButtonClick
    end
    object CloseTButton: TButton
      Left = 16
      Top = 6
      Width = 75
      Height = 25
      Hint = 'Close window'
      Cancel = True
      Caption = 'Close'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 0
      OnClick = CloseTButtonClick
    end
  end
  object Memo1: TMemo
    Left = 0
    Top = 0
    Width = 445
    Height = 265
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 1
    WantTabs = True
    OnChange = Memo1Change
  end
end
