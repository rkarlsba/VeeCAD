program VeeCAD;

uses
  Forms,
  main in 'main.pas' {MainForm},
  Project in 'Project.pas',
  ProjectInput in 'ProjectInput.pas',
  ProjectOutput in 'ProjectOutput.pas',
  BoardSettings in 'BoardSettings.pas' {BoardSettingsForm},
  NewItem in 'NewItem.pas' {NewItemForm},
  SelectItem in 'SelectItem.pas' {SelectItemForm},
  Netlist in 'Netlist.pas',
  Import in 'Import.pas',
  Globals in 'Globals.pas',
  BoardItemSettings in 'BoardItemSettings.pas' {BoardItemSettingsForm},
  GraphicCopy in 'GraphicCopy.pas',
  About in 'About.pas' {AboutForm},
  NetlistSettings1 in 'NetlistSettings1.pas' {NetlistForm1},
  ProjectCheck in 'ProjectCheck.pas',
  BoardSize in 'BoardSize.pas',
  Materials in 'Materials.pas' {MaterialsForm},
  Cursors in 'Cursors.pas',
  ImportNetFrm in 'ImportNetFrm.pas' {ImportNetForm},
  NetImporter in 'NetImporter.pas',
  SortCompare in 'SortCompare.pas',
  Adjuster in 'Adjuster.pas',
  Editor in 'Editor.pas',
  Painter in 'Painter.pas',
  ColorPreviewer in 'ColorPreviewer.pas',
  Styles in 'Styles.pas',
  ClipbrdGraphic in 'ClipbrdGraphic.pas',
  WebUpdate in 'WebUpdate.pas',
  PrintSetup in 'PrintSetup.pas' {PrintSetupForm},
  PrintPainter in 'PrintPainter.pas',
  PrintPreviewBoard in 'PrintPreviewBoard.pas',
  PrintBoard in 'PrintBoard.pas',
  Placement in 'Placement.pas',
  Breaks in 'Breaks.pas',
  Selector in 'Selector.pas',
  Windows {for MessageBox()},
  PinNoEntry in 'PinNoEntry.pas' {PinNoEntryForm},
  LibraryTools in 'LibraryTools.pas',
  Rectangles in 'Utils\Rectangles.pas',
  BlockRotate in 'BlockRotate.pas',
  ClipbrdComponents in 'ClipbrdComponents.pas',
  HSVColorPicker in 'ColorPicker\HSVColorPicker.pas',
  HTMLColors in 'ColorPicker\HTMLColors.pas',
  mbColorPickerControl in 'ColorPicker\mbColorPickerControl.pas',
  mbTrackBarPicker in 'ColorPicker\mbTrackBarPicker.pas',
  PalUtils in 'ColorPicker\PalUtils.pas',
  RGBCIEUtils in 'ColorPicker\RGBCIEUtils.pas',
  RGBCMYKUtils in 'ColorPicker\RGBCMYKUtils.pas',
  RGBHSLUtils in 'ColorPicker\RGBHSLUtils.pas',
  RGBHSVUtils in 'ColorPicker\RGBHSVUtils.pas',
  Scanlines in 'ColorPicker\Scanlines.pas',
  SelPropUtils in 'ColorPicker\SelPropUtils.pas',
  VColorPicker in 'ColorPicker\VColorPicker.pas',
  HTMLHelpViewer,
  SysUtils,
  PrintReport in 'PrintReport.pas' {PrintReportForm},
  WineHelper in 'Utils\WineHelper.pas',
  ProjectInputCSV in 'ProjectInputCSV.pas',
  jsonparse in 'Utils\jsonparse.pas',
  Board in 'Board.pas',
  BoardPainter in 'BoardPainter.pas',
  ManagedItem in 'Utils\ManagedItem.pas',
  BoardPattern in 'BoardPattern.pas' {BoardPatternForm},
  PatternDisplayer in 'PatternDisplayer.pas',
  Intersect in 'Utils\Intersect.pas',
  ColorScheme in 'ColorScheme.pas',
  Connective in 'Connective.pas',
  Tracks in 'TrackEdit\Tracks.pas',
  TrackEditFm in 'TrackEdit\TrackEditFm.pas' {TrackEditForm},
  TrackPainter in 'TrackEdit\TrackPainter.pas',
  TrackEditor in 'TrackEdit\TrackEditor.pas',
  TrackItems in 'TrackEdit\TrackItems.pas',
  SegmentProperties in 'TrackEdit\SegmentProperties.pas' {SegmentPropertiesForm},
  BoardPainterConnective in 'BoardPainterConnective.pas',
  ColorNetLinkFm in 'ColorNetLinkFm.pas' {ColorNetLinkForm},
  ClipbrdTracks in 'TrackEdit\ClipbrdTracks.pas',
  textutils in 'Utils\textutils.pas',
  GcodeFm in 'G-code\GcodeFm.pas' {GcodeForm},
  Gcode in 'G-code\Gcode.pas',
  UndoEngine in 'Utils\UndoEngine.pas',
  NotesFm in 'NotesFm.pas' {NotesForm},
  GcodeTop in 'G-code\GcodeTop.pas',
  ArcLine in 'Utils\ArcLine.pas',
  NetReader in 'NetRead\NetReader.pas',
  NetReaderCrododilePhysics in 'NetRead\NetReaderCrododilePhysics.pas',
  NetReaderEasyPC in 'NetRead\NetReaderEasyPC.pas',
  NetReaderOrcadPCB2 in 'NetRead\NetReaderOrcadPCB2.pas',
  NetReaderProtelTango in 'NetRead\NetReaderProtelTango.pas',
  NetReaderSeetrax in 'NetRead\NetReaderSeetrax.pas',
  NetReaderUltiCap in 'NetRead\NetReaderUltiCap.pas',
  NetReaderZenit in 'NetRead\NetReaderZenit.pas',
  ParseCsv in 'Utils\ParseCsv.pas',
  Rotations in 'Utils\Rotations.pas',
  GdiHandles in 'Utils\GdiHandles.pas',
  FullPathName in 'Utils\FullPathName.pas',
  version in 'Utils\version.pas',
  MessageDialogFrm in 'Utils\MessageDialogFrm.pas' {MessageDialogForm},
  CopperTrace in 'CopperTrace.pas',
  NetReaderWirelist in 'NetRead\NetReaderWirelist.pas',
  PrintStrings in 'Utils\PrintStrings.pas',
  ExceptSafe in 'Utils\ExceptSafe.pas',
  ClipbrdUtils in 'Utils\ClipbrdUtils.pas',
  CelledOutlines in 'Outlines\CelledOutlines.pas',
  CellOutlineEditor in 'Outlines\CellOutlineEditor.pas',
  ClipbrdOutlines in 'Outlines\ClipbrdOutlines.pas',
  CustomOutlineBasicEditor in 'Outlines\CustomOutlineBasicEditor.pas' {veCustomOutlineBasicEditor},
  CustomOutlineEditor in 'Outlines\CustomOutlineEditor.pas',
  CustomOutlineEditorForm in 'Outlines\CustomOutlineEditorForm.pas' {veCustomOutlineEditorForm},
  CustomOutlines in 'Outlines\CustomOutlines.pas',
  OtherOutlines in 'Outlines\OtherOutlines.pas',
  OutlineDisplayer in 'Outlines\OutlineDisplayer.pas',
  Outlines in 'Outlines\Outlines.pas',
  OutlineSettings in 'Outlines\OutlineSettings.pas' {OutlineSettingsForm},
  RadialOutlineEditor in 'Outlines\RadialOutlineEditor.pas' {veRadialOutlineEditor},
  RadialOutlines in 'Outlines\RadialOutlines.pas',
  SizeableOutlines in 'Outlines\SizeableOutlines.pas',
  SmdOutlines in 'Outlines\SmdOutlines.pas',
  DebugFrm in 'Utils\DebugFrm.pas' {DebugForm},
  FileMenuHandler in 'Utils\FileMenuHandler.pas',
  FormMinder in 'Utils\FormMinder.pas',
  InputBoxFrm in 'Utils\InputBoxFrm.pas' {InputBoxForm},
  PaperSize in 'Utils\PaperSize.pas',
  PrintPageSizer in 'Utils\PrintPageSizer.pas',
  LeadEditorForm in 'Outlines\LeadEditorForm.pas' {veLeadOutlineEditor},
  SettingsFmLines in 'Settings\SettingsFmLines.pas' {Form2},
  SettingsFrm in 'Settings\SettingsFrm.pas' {SettingsForm},
  SettingsFrmColors in 'Settings\SettingsFrmColors.pas' {SetColorsForm},
  SettingsFrmCursors in 'Settings\SettingsFrmCursors.pas' {SetCursorsForm},
  SettingsFrmGraphic in 'Settings\SettingsFrmGraphic.pas' {SetGraphicCopyForm},
  SettingsFrmKeys in 'Settings\SettingsFrmKeys.pas' {SetKeysForm},
  Route in 'Route\Route.pas',
  RouteLeaded in 'Route\RouteLeaded.pas',
  RouteLinks in 'Route\RouteLinks.pas',
  Tracer in 'Tracer.pas',
  NetlistGenerate in 'Netlist\NetlistGenerate.pas',
  NetlistUser in 'Netlist\NetlistUser.pas',
  NetlistExport in 'Netlist\NetlistExport.pas';

{$R *.RES}
// WinXP themes, asInvoker Vista user, DPI aware
{$R VeeCAD_manifest.RES}

begin
  Application.Initialize;

  // report memory leaks if running in Delphi IDE
  if DebugHook <> 0 then begin
      ReportMemoryLeaksOnShutdown := True;
  end;

  Application.Title := 'VeeCAD Stripboard Editor';
  Application.MainFormOnTaskbar := True;
  Application.HelpFile := SysUtils.ExtractFilePath(Application.ExeName) + 'veecad.chm';
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TNetlistForm1, NetlistForm1);
  Application.CreateForm(TMaterialsForm, MaterialsForm);
  Application.CreateForm(TNotesForm, NotesForm);
  Application.CreateForm(TMessageDialogForm, MessageDialogForm);
  Application.CreateForm(TInputBoxForm, InputBoxForm);
  // this entire program assumes '.' is decimal separator
  // Affects StrToFloat, StrToCurrency
{$IFDEF VER200}
  DecimalSeparator := '.';
{$ELSE}
  FormatSettings.DecimalSeparator := '.';
{$ENDIF}
  Application.Run;
end.
