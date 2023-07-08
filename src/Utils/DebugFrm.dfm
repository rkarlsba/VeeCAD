object DebugForm: TDebugForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMaximize]
  Caption = 'Debug'
  ClientHeight = 587
  ClientWidth = 322
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesigned
  PixelsPerInch = 96
  TextHeight = 13
  object Memo1: TMemo
    Left = 0
    Top = 0
    Width = 322
    Height = 546
    Align = alClient
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 0
    ExplicitWidth = 418
    ExplicitHeight = 529
  end
  object Panel1: TPanel
    Left = 0
    Top = 546
    Width = 322
    Height = 41
    Align = alBottom
    Caption = 'Panel1'
    ShowCaption = False
    TabOrder = 1
    ExplicitLeft = 72
    ExplicitTop = 544
    ExplicitWidth = 185
    object CopyTButton: TButton
      Left = 208
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Copy'
      TabOrder = 0
      OnClick = CopyTButtonClick
    end
  end
end
