object InputBoxForm: TInputBoxForm
  Left = 361
  Top = 558
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'InputBoxForm'
  ClientHeight = 111
  ClientWidth = 331
  Color = clBtnFace
  ParentFont = True
  OldCreateOrder = False
  Position = poMainFormCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object PromptTLabel: TLabel
    Left = 24
    Top = 22
    Width = 65
    Height = 13
    Caption = 'PromptTLabel'
  end
  object InputTEdit: TEdit
    Left = 24
    Top = 41
    Width = 281
    Height = 21
    TabOrder = 0
    Text = 'InputTEdit'
    OnKeyPress = InputTEditKeyPress
  end
  object OKTButton: TButton
    Left = 72
    Top = 80
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
  object CancelTButton: TButton
    Left = 192
    Top = 80
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
  end
end
