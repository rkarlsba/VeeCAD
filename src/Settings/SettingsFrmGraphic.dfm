object SetGraphicCopyForm: TSetGraphicCopyForm
  Left = 410
  Top = 304
  HelpContext = 65
  Caption = 'Graphic Copy'
  ClientHeight = 362
  ClientWidth = 438
  Color = clBtnFace
  ParentFont = True
  OldCreateOrder = False
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 8
    Top = 251
    Width = 361
    Height = 86
    TabOrder = 0
    object Label1: TLabel
      Left = 11
      Top = 23
      Width = 161
      Height = 13
      Alignment = taRightJustify
      AutoSize = False
      Caption = 'Image Scale, Pixels Per Cell '
    end
    object Label2: TLabel
      Left = 99
      Top = 50
      Width = 73
      Height = 13
      Alignment = taRightJustify
      AutoSize = False
      Caption = 'Rulers'
    end
    object ScaleTUpDown: TUpDown
      Left = 245
      Top = 20
      Width = 16
      Height = 21
      Associate = ScaleTEdit
      Min = 8
      Max = 40
      Position = 10
      TabOrder = 0
      OnChangingEx = ScaleTUpDownChangingEx
    end
    object ScaleTEdit: TEdit
      Left = 196
      Top = 20
      Width = 49
      Height = 21
      TabOrder = 1
      Text = '10'
    end
    object RulersTComboBox: TComboBox
      Left = 196
      Top = 47
      Width = 157
      Height = 21
      ItemHeight = 13
      TabOrder = 2
      Text = 'RulersTComboBox'
      Items.Strings = (
        'None'
        'Numbers eg. "3,8"'
        'Letters & Numbers eg. "A8"')
    end
  end
  object PreviewTPanel: TPanel
    Left = 8
    Top = 8
    Width = 313
    Height = 225
    BevelOuter = bvNone
    TabOrder = 1
  end
end
