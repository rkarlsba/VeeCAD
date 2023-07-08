object veRadialOutlineEditor: TveRadialOutlineEditor
  Left = 494
  Top = 271
  BorderStyle = bsNone
  Caption = 'TveRadialOutlineEditor'
  ClientHeight = 225
  ClientWidth = 380
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -14
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Visible = True
  PixelsPerInch = 120
  TextHeight = 16
  object Label1: TLabel
    Left = 56
    Top = 78
    Width = 116
    Height = 16
    Alignment = taRightJustify
    AutoSize = False
    Caption = 'Body Diameter'
  end
  object Label2: TLabel
    Left = 56
    Top = 33
    Width = 116
    Height = 16
    Alignment = taRightJustify
    AutoSize = False
    Caption = 'Pin Spacing'
  end
  object Label3: TLabel
    Left = 89
    Top = 171
    Width = 83
    Height = 16
    Alignment = taRightJustify
    Caption = 'Ref Pin Name'
  end
  object Label4: TLabel
    Left = 56
    Top = 201
    Width = 116
    Height = 16
    Alignment = taRightJustify
    AutoSize = False
    Caption = 'Pin Name'
  end
  object LeadSpacingTEdit: TEdit
    Left = 192
    Top = 30
    Width = 44
    Height = 24
    ReadOnly = True
    TabOrder = 0
    Text = '1'
    OnChange = DiameterTEditChange
  end
  object DiameterTEdit: TEdit
    Left = 192
    Top = 75
    Width = 44
    Height = 24
    ReadOnly = True
    TabOrder = 1
    Text = '1'
    OnChange = DiameterTEditChange
  end
  object BodyHeightTUpdown: TUpDown
    Left = 236
    Top = 30
    Width = 19
    Height = 24
    Associate = LeadSpacingTEdit
    Min = 1
    Max = 25
    Position = 1
    TabOrder = 2
  end
  object BodyWidthTUpdown: TUpDown
    Left = 236
    Top = 75
    Width = 19
    Height = 24
    Associate = DiameterTEdit
    Min = 1
    Max = 25
    Position = 1
    TabOrder = 3
  end
  object Pin0NameTEdit: TEdit
    Left = 192
    Top = 168
    Width = 62
    Height = 24
    TabOrder = 4
    Text = 'Pin0NameTEdit'
    OnChange = DiameterTEditChange
  end
  object Pin1NameTEdit: TEdit
    Left = 192
    Top = 198
    Width = 62
    Height = 24
    TabOrder = 5
    Text = 'Pin1NameTEdit'
    OnChange = DiameterTEditChange
  end
end
