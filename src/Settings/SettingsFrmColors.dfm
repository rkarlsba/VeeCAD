object SetColorsForm: TSetColorsForm
  Left = 363
  Top = 195
  HelpContext = 63
  Caption = 'Display'
  ClientHeight = 410
  ClientWidth = 478
  Color = clBtnFace
  ParentFont = True
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Label3: TLabel
    Left = 8
    Top = 275
    Width = 88
    Height = 13
    Caption = 'Line Width (pixels)'
  end
  object Label4: TLabel
    Left = 8
    Top = 325
    Width = 54
    Height = 13
    Caption = 'Lead Width'
  end
  object PreviewTPanel: TPanel
    Left = 0
    Top = 0
    Width = 249
    Height = 201
    BevelOuter = bvNone
    TabOrder = 0
  end
  object LeadStyleTComboBox: TComboBox
    Left = 8
    Top = 341
    Width = 145
    Height = 21
    ItemHeight = 13
    TabOrder = 1
    Text = 'ComboBox'
    OnChange = LeadStyleTComboBoxChange
    Items.Strings = (
      'Wide'
      'Narrow')
  end
  object LineWidthTUpDown: TUpDown
    Left = 81
    Top = 291
    Width = 16
    Height = 21
    Associate = LineWidthTEdit
    Min = 1
    Max = 4
    Position = 1
    TabOrder = 2
    OnChangingEx = LineWidthTUpDownChangingEx
  end
  object LineWidthTEdit: TEdit
    Left = 8
    Top = 291
    Width = 73
    Height = 21
    Color = clBtnFace
    ReadOnly = True
    TabOrder = 3
    Text = '1'
  end
  object ColorPickersTGroupBox: TGroupBox
    Left = 214
    Top = 8
    Width = 256
    Height = 385
    Caption = 'Alter Item Color'
    TabOrder = 4
    object Label5: TLabel
      Left = 198
      Top = 248
      Width = 3
      Height = 13
    end
    object BodyTRadioButton: TRadioButton
      Left = 16
      Top = 26
      Width = 113
      Height = 17
      Caption = 'Body'
      Checked = True
      TabOrder = 0
      TabStop = True
      OnClick = BodyTRadioButtonClick
    end
    object PinsTRadioButton: TRadioButton
      Left = 16
      Top = 49
      Width = 113
      Height = 17
      Caption = 'Pins'
      TabOrder = 1
      OnClick = BodyTRadioButtonClick
    end
    object StripsTRadioButton: TRadioButton
      Left = 16
      Top = 72
      Width = 113
      Height = 17
      Caption = 'Strips'
      TabOrder = 2
      OnClick = BodyTRadioButtonClick
    end
    object BoardTRadioButton: TRadioButton
      Left = 16
      Top = 95
      Width = 113
      Height = 17
      Caption = 'Board'
      TabOrder = 3
      OnClick = BodyTRadioButtonClick
    end
    object SelectedColorTRadioButton: TRadioButton
      Left = 16
      Top = 118
      Width = 81
      Height = 17
      Caption = 'Selected ----------'
      TabOrder = 4
      OnClick = BodyTRadioButtonClick
    end
    object SelectedColorResetTButton: TButton
      Left = 101
      Top = 114
      Width = 47
      Height = 25
      Caption = 'Reset'
      Enabled = False
      TabOrder = 5
      OnClick = SelectedColorResetTButtonClick
    end
    object Net1TRadioButton: TRadioButton
      Left = 168
      Top = 26
      Width = 60
      Height = 17
      Caption = 'Net 1'
      TabOrder = 6
      OnClick = BodyTRadioButtonClick
    end
    object Net2TRadioButton: TRadioButton
      Left = 168
      Top = 49
      Width = 60
      Height = 17
      Caption = 'Net 2'
      TabOrder = 7
      OnClick = BodyTRadioButtonClick
    end
    object Net3TRadioButton: TRadioButton
      Left = 168
      Top = 72
      Width = 60
      Height = 17
      Caption = 'Net 3'
      TabOrder = 8
      OnClick = BodyTRadioButtonClick
    end
    object Net4TRadioButton: TRadioButton
      Left = 168
      Top = 95
      Width = 60
      Height = 17
      Caption = 'Net 4'
      TabOrder = 9
      OnClick = BodyTRadioButtonClick
    end
    object Net5TRadioButton: TRadioButton
      Left = 168
      Top = 118
      Width = 60
      Height = 17
      Caption = 'Net 5'
      TabOrder = 10
      OnClick = BodyTRadioButtonClick
    end
    object Net6TRadioButton: TRadioButton
      Left = 168
      Top = 141
      Width = 60
      Height = 17
      Caption = 'Net 6'
      TabOrder = 11
      OnClick = BodyTRadioButtonClick
    end
  end
  object SpecialTButton: TButton
    Left = 8
    Top = 368
    Width = 75
    Height = 25
    Caption = 'Special'
    TabOrder = 5
    Visible = False
    OnClick = SpecialTButtonClick
  end
  object ClipboardTPopupMenu: TPopupMenu
    Left = 112
    Top = 283
    object CopyColorValuestoClipboard1: TMenuItem
      Caption = 'Copy Color Values to Clipboard'
      OnClick = CopyColorValuestoClipboard1Click
    end
    object PasteColorValuesfromClipboard1: TMenuItem
      Caption = 'Paste Color Values from Clipboard'
      OnClick = PasteColorValuesfromClipboard1Click
    end
  end
end
