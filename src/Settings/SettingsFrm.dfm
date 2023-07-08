object SettingsForm: TSettingsForm
  Left = 363
  Top = 183
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Settings'
  ClientHeight = 422
  ClientWidth = 568
  Color = clBtnFace
  ParentFont = True
  OldCreateOrder = False
  Position = poMainFormCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 487
    Top = 0
    Width = 81
    Height = 422
    Align = alRight
    TabOrder = 0
    object OkTButton: TButton
      Left = 8
      Top = 272
      Width = 65
      Height = 25
      Caption = 'OK'
      ModalResult = 1
      TabOrder = 0
    end
    object CancelTButton: TButton
      Left = 8
      Top = 312
      Width = 65
      Height = 25
      Cancel = True
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 1
    end
  end
  object PageControl: TPageControl
    Left = 0
    Top = 0
    Width = 487
    Height = 422
    Align = alClient
    TabOrder = 1
    OnChange = PageControlChange
  end
end
