object PrintSetupForm: TPrintSetupForm
  Left = 265
  Top = 161
  HelpContext = 650
  BorderIcons = [biSystemMenu, biMaximize]
  Caption = 'Print Setup'
  ClientHeight = 566
  ClientWidth = 792
  Color = clBtnFace
  ParentFont = True
  OldCreateOrder = False
  Position = poMainFormCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 792
    Height = 512
    ActivePage = PagesTTabSheet
    Align = alClient
    TabOrder = 0
    object PagesTTabSheet: TTabSheet
      Caption = 'Pages'
      ImageIndex = 1
      object Panel3: TPanel
        Left = 0
        Top = 0
        Width = 288
        Height = 484
        Align = alLeft
        TabOrder = 0
        object GroupBox7: TGroupBox
          Left = 3
          Top = 166
          Width = 281
          Height = 52
          Caption = 'Scale ( percent )'
          TabOrder = 1
          object Label10: TLabel
            Left = 168
            Top = 32
            Width = 46
            Height = 13
            Caption = '10 to 250'
          end
          object PagesScaleTEdit: TEdit
            Left = 16
            Top = 24
            Width = 57
            Height = 21
            TabOrder = 0
            Text = '100'
            OnKeyPress = PagesScaleTEditKeyPress
          end
          object PagesScaleTButton: TButton
            Left = 80
            Top = 22
            Width = 33
            Height = 25
            Caption = 'OK'
            TabOrder = 1
            OnClick = PagesScaleTButtonClick
          end
        end
        object GroupBox16: TGroupBox
          Left = 3
          Top = 224
          Width = 281
          Height = 41
          Caption = 'Orientation'
          TabOrder = 3
          object PagesPortraitTRadioButton: TRadioButton
            Left = 16
            Top = 18
            Width = 81
            Height = 17
            Caption = 'Portrait'
            TabOrder = 0
            OnClick = PagesPortraitTRadioButtonClick
          end
          object PagesLandscapeTRadioButton: TRadioButton
            Left = 128
            Top = 18
            Width = 89
            Height = 17
            Caption = 'Landscape'
            Checked = True
            TabOrder = 1
            TabStop = True
            OnClick = PagesLandscapeTRadioButtonClick
          end
        end
        object GroupBox1: TGroupBox
          Left = 3
          Top = 119
          Width = 281
          Height = 41
          Caption = 'View'
          TabOrder = 2
          object PagesFrontTRadioButton: TRadioButton
            Left = 16
            Top = 18
            Width = 73
            Height = 17
            Caption = 'Front'
            TabOrder = 0
            OnClick = PagesFrontTRadioButtonClick
          end
          object PagesRearTRadioButton: TRadioButton
            Left = 127
            Top = 18
            Width = 113
            Height = 17
            Caption = 'Rear'
            TabOrder = 1
            OnClick = PagesRearTRadioButtonClick
          end
        end
        object GroupBox2: TGroupBox
          Left = 3
          Top = 9
          Width = 281
          Height = 104
          Caption = 'Printer'
          TabOrder = 0
          object PagesPrinterNameTLabel: TLabel
            Left = 8
            Top = 24
            Width = 10
            Height = 13
            Caption = '??'
          end
          object Label4: TLabel
            Left = 8
            Top = 48
            Width = 32
            Height = 13
            Caption = 'Paper:'
          end
          object PaperSizeTLabel: TLabel
            Left = 56
            Top = 48
            Width = 10
            Height = 13
            Caption = '??'
          end
          object PagesPrinterSetupTButton: TButton
            Left = 8
            Top = 72
            Width = 113
            Height = 25
            Caption = 'Printer Setup...'
            TabOrder = 0
            OnClick = PagesPrinterSetupTButton1Click
          end
        end
        object GroupBox3: TGroupBox
          Left = 3
          Top = 359
          Width = 281
          Height = 45
          Caption = 'Copies'
          TabOrder = 4
          object Label3: TLabel
            Left = 112
            Top = 16
            Width = 151
            Height = 13
            Caption = '(resets to 1 when setup closes)'
          end
          object PagesCopiesTEdit: TEdit
            Left = 40
            Top = 16
            Width = 41
            Height = 21
            TabOrder = 0
            Text = '1'
          end
          object PagesCopiesTUpDown: TUpDown
            Left = 81
            Top = 16
            Width = 16
            Height = 21
            Associate = PagesCopiesTEdit
            Min = 1
            Max = 10
            Position = 1
            TabOrder = 1
          end
        end
        object Margins: TGroupBox
          Left = 3
          Top = 271
          Width = 281
          Height = 82
          Caption = 'Margins (mm)'
          TabOrder = 5
          object Label5: TLabel
            Left = 7
            Top = 53
            Width = 23
            Height = 13
            Caption = 'Left:'
          end
          object Label6: TLabel
            Left = 7
            Top = 26
            Width = 22
            Height = 13
            Caption = 'Top:'
          end
          object Label7: TLabel
            Left = 125
            Top = 53
            Width = 29
            Height = 13
            Caption = 'Right:'
          end
          object PagesMarginLeftTEdit: TEdit
            Left = 57
            Top = 50
            Width = 49
            Height = 21
            TabOrder = 0
            Text = '7'
            OnKeyPress = PagesMarginLeftTEditKeyPress
          end
          object PagesMarginRightTEdit: TEdit
            Left = 176
            Top = 50
            Width = 49
            Height = 21
            TabOrder = 1
            Text = '7'
            OnKeyPress = PagesMarginLeftTEditKeyPress
          end
          object PagesMarginTopTEdit: TEdit
            Left = 57
            Top = 23
            Width = 49
            Height = 21
            TabOrder = 2
            Text = '10'
            OnKeyPress = PagesMarginLeftTEditKeyPress
          end
          object PagesMarginsTButton: TButton
            Left = 233
            Top = 48
            Width = 33
            Height = 25
            Caption = 'OK'
            TabOrder = 3
            OnClick = PagesMarginsTButtonClick
          end
        end
        object PagesColorTGroupBox: TGroupBox
          Left = 3
          Top = 410
          Width = 281
          Height = 41
          Caption = 'Color'
          TabOrder = 6
          object PagesColorTRadioButton: TRadioButton
            Left = 128
            Top = 18
            Width = 113
            Height = 17
            Caption = 'Color'
            TabOrder = 0
            OnClick = PagesColorTRadioButtonClick
          end
          object PagesBlackWhiteTRadioButton: TRadioButton
            Left = 16
            Top = 18
            Width = 113
            Height = 17
            Caption = 'Black && White'
            Checked = True
            TabOrder = 1
            TabStop = True
            OnClick = PagesBlackWhiteTRadioButtonClick
          end
        end
      end
    end
    object AppearanceTTabSheet: TTabSheet
      Caption = 'Appearance'
      ImageIndex = 2
      object Panel2: TPanel
        Left = 0
        Top = 0
        Width = 288
        Height = 484
        Align = alLeft
        TabOrder = 0
        object GroupBox8: TGroupBox
          Left = 3
          Top = 9
          Width = 281
          Height = 88
          Caption = 'Show'
          TabOrder = 0
          object AppearanceHolesTCheckBox: TCheckBox
            Left = 8
            Top = 18
            Width = 65
            Height = 17
            Caption = 'Holes'
            TabOrder = 0
            OnClick = AppearanceHolesTCheckBoxClick
          end
          object AppearanceStripsTCheckBox: TCheckBox
            Left = 144
            Top = 18
            Width = 81
            Height = 17
            Caption = 'Strip Lines'
            TabOrder = 1
            OnClick = AppearanceStripsTCheckBoxClick
          end
          object AppearanceBreaksTCheckBox: TCheckBox
            Left = 8
            Top = 40
            Width = 97
            Height = 17
            Caption = 'Breaks'
            TabOrder = 2
            OnClick = AppearanceBreaksTCheckBoxClick
          end
          object AppearanceComponentsTCheckBox: TCheckBox
            Left = 144
            Top = 40
            Width = 97
            Height = 17
            Caption = 'Components'
            TabOrder = 3
            OnClick = AppearanceComponentsTCheckBoxClick
          end
          object AppearanceLinksTCheckBox: TCheckBox
            Left = 8
            Top = 64
            Width = 97
            Height = 17
            Caption = 'Links'
            TabOrder = 4
            OnClick = AppearanceLinksTCheckBoxClick
          end
          object AppearanceWiresTCheckBox: TCheckBox
            Left = 144
            Top = 64
            Width = 97
            Height = 17
            Caption = 'Wires'
            TabOrder = 5
            OnClick = AppearanceWiresTCheckBoxClick
          end
        end
        object TextTGroupBox: TGroupBox
          Left = 3
          Top = 105
          Width = 281
          Height = 64
          Caption = 'Component Text'
          TabOrder = 1
          object Label1: TLabel
            Left = 16
            Top = 40
            Width = 129
            Height = 13
            Caption = '(Text not visible from rear)'
          end
          object AppearanceNoTextTRadioButton: TRadioButton
            Left = 16
            Top = 16
            Width = 65
            Height = 17
            Caption = 'None'
            TabOrder = 0
            OnClick = AppearanceNoTextTRadioButtonClick
          end
          object AppearanceValuesTRadioButton: TRadioButton
            Left = 208
            Top = 16
            Width = 65
            Height = 17
            Caption = 'Values'
            TabOrder = 2
            OnClick = AppearanceValuesTRadioButtonClick
          end
          object AppearanceDesignatorsTRadioButton: TRadioButton
            Left = 96
            Top = 16
            Width = 89
            Height = 17
            Caption = 'Designators'
            TabOrder = 1
            OnClick = AppearanceDesignatorsTRadioButtonClick
          end
        end
        object GroupBox10: TGroupBox
          Left = 3
          Top = 177
          Width = 281
          Height = 41
          Caption = 'Lead Width'
          TabOrder = 2
          object AppearanceWideLeadTRadioButton: TRadioButton
            Left = 16
            Top = 16
            Width = 65
            Height = 17
            Caption = 'Wide'
            TabOrder = 0
            OnClick = AppearanceWideLeadTRadioButtonClick
          end
          object AppearanceNarrowLeadTRadioButton: TRadioButton
            Left = 112
            Top = 16
            Width = 89
            Height = 17
            Caption = 'Narrow'
            TabOrder = 1
            OnClick = AppearanceNarrowLeadTRadioButtonClick
          end
        end
        object GroupBox11: TGroupBox
          Left = 3
          Top = 226
          Width = 281
          Height = 52
          Caption = 'Holes Diameter ( 1/1000s of cell )'
          TabOrder = 3
          object Label2: TLabel
            Left = 152
            Top = 24
            Width = 105
            Height = 13
            Caption = '10 to 300, 200 typical'
          end
          object AppearanceHoleDiameterTEdit: TEdit
            Left = 8
            Top = 24
            Width = 57
            Height = 21
            TabOrder = 0
            Text = '160'
            OnKeyPress = AppearanceHoleDiameterTEditKeyPress
          end
          object AppearanceHoleDiameterTButton: TButton
            Left = 72
            Top = 22
            Width = 33
            Height = 25
            Caption = 'OK'
            TabOrder = 1
            OnClick = AppearanceHoleDiameterTButtonClick
          end
        end
        object GroupBox12: TGroupBox
          Left = 3
          Top = 286
          Width = 281
          Height = 52
          Caption = 'Component Line Width ( 1/1000s of cell )'
          TabOrder = 4
          object Label8: TLabel
            Left = 152
            Top = 24
            Width = 105
            Height = 13
            Caption = '10 to 250, 160 typical'
          end
          object AppearanceComponentLineWidthTEdit: TEdit
            Left = 8
            Top = 24
            Width = 57
            Height = 21
            TabOrder = 0
            Text = '160'
            OnKeyPress = AppearanceComponentLineWidthTEditKeyPress
          end
          object AppearanceComponentLineWidthTButton: TButton
            Left = 72
            Top = 22
            Width = 33
            Height = 25
            Caption = 'OK'
            TabOrder = 1
            OnClick = AppearanceComponentLineWidthTButtonClick
          end
        end
        object GroupBox13: TGroupBox
          Left = 3
          Top = 346
          Width = 281
          Height = 52
          Caption = 'Strip Line Width ( 1/1000s of cell )'
          TabOrder = 5
          object Label12: TLabel
            Left = 152
            Top = 16
            Width = 105
            Height = 13
            Caption = '20 to 500, 200 typical'
          end
          object Label13: TLabel
            Left = 152
            Top = 32
            Width = 76
            Height = 13
            Caption = '0 = 1 pixel wide'
          end
          object AppearanceStripLineWidthTEdit: TEdit
            Left = 8
            Top = 24
            Width = 57
            Height = 21
            TabOrder = 0
            Text = '160'
            OnKeyPress = AppearanceStripLineWidthTEditKeyPress
          end
          object AppearanceStripLineWidthTButton: TButton
            Left = 72
            Top = 22
            Width = 33
            Height = 25
            Caption = 'OK'
            TabOrder = 1
            OnClick = AppearanceStripLineWidthTButtonClick
          end
        end
      end
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 512
    Width = 792
    Height = 54
    Align = alBottom
    TabOrder = 1
    object CloseTButton: TButton
      Left = 398
      Top = 16
      Width = 113
      Height = 25
      Cancel = True
      Caption = 'Close'
      ModalResult = 2
      TabOrder = 0
    end
    object PrintTButton: TButton
      Left = 231
      Top = 16
      Width = 113
      Height = 25
      Caption = 'Print'
      TabOrder = 1
      OnClick = PrintTButtonClick
    end
  end
  object PrinterSetupDialog1: TPrinterSetupDialog
    Left = 28
    Top = 520
  end
end
