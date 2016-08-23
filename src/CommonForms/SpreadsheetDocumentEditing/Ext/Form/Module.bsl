
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skipping the initialization to guarantee that the form will be received if the SelfTest parameter is passed.
	If Parameters.Property("SelfTest") Then 
		Return;
	EndIf;

	If Parameters.WindowOpeningMode <> Undefined Then
		WindowOpeningMode = Parameters.WindowOpeningMode;
	EndIf;
	
	If Parameters.SpreadsheetDocument.TableHeight = 0 Then
		If Not IsBlankString(Parameters.TemplateMetadataObjectName) Then
			LoadSpreadsheetDocumentFromMetadata();
		EndIf;
	Else
		SpreadsheetDocument = Parameters.SpreadsheetDocument;
	EndIf;
	
	Items.SpreadsheetDocument.Edit = Parameters.Edit;
	Items.SpreadsheetDocument.ShowGroups = True;
	
	IsTemplate = Not IsBlankString(Parameters.TemplateMetadataObjectName);
	Items.Warning.Visible = IsTemplate And Parameters.Edit;
	
	If Not IsBlankString(Parameters.DocumentName) Then
		DocumentName = Parameters.DocumentName;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not IsBlankString(Parameters.PathToFile) Then
		File = New File(Parameters.PathToFile);
		If IsBlankString(DocumentName) Then
			DocumentName = File.BaseName;
		EndIf;
		EditingProhibited = File.GetReadOnly();
	EndIf;
	
	If IsBlankString(DocumentName) Then
		UsedNames = New Array;
		Notify("SpreadsheetDocumentsToEditNameRequest", UsedNames, ThisObject);
		
		Index = 1;
		While UsedNames.Find(NewDocumentName() + Index) <> Undefined Do
			Index = Index + 1;
		EndDo;
		
		DocumentName = NewDocumentName() + Index;
	EndIf;
	
	Items.SpreadsheetDocument.Edit = Items.SpreadsheetDocument.Edit Or Not IsBlankString(Parameters.PathToFile) And Not EditingProhibited;
	
	SetTitle();
	SetUpCommandPresentation();
	SetUpSpreadsheetDocumentRepresentation();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	QueryText = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Do you want to save changes you made to %1?'"), DocumentName);
	NotifyDescription = New NotifyDescription("ConfirmAndClose", ThisObject);
	CommonUseClient.ShowFormClosingConfirmation(NotifyDescription, Cancel, QueryText);
	
	If Not Modified Then
		NotificationParameters = New Structure;
		NotificationParameters.Insert("PathToFile", Parameters.PathToFile);
		NotificationParameters.Insert("TemplateMetadataObjectName", Parameters.TemplateMetadataObjectName);
		If WritingComplited Then
			EventName = "Write_SpreadsheetDocument";
			NotificationParameters.Insert("SpreadsheetDocument", SpreadsheetDocument);
		Else
			EventName = "CancelSpreadsheetDocumentEditing";
		EndIf;
		Notify(EventName, NotificationParameters, ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfirmAndClose(Result = Undefined, AdditionalParameters = Undefined) Export
	If WriteSpreadsheetDocument() Then 
		Close();
	EndIf;
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "SpreadsheetDocumentsToEditNameRequest" And Source <> ThisObject Then
		Parameter.Add(DocumentName);
	ElsIf EventName = "OwnerFormClosing" And Source = FormOwner Then
		Close();
		If IsOpen() Then
			Parameter.Cancel = True;
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemEventHandlers

&AtClient
Procedure SpreadsheetDocumentOnAreaActivate(Item)
	UpdateCommandBarButtonMarks();
EndProcedure

#EndRegion

#Region FormCommandHandlers

// Processing a document

&AtClient
Procedure WriteAndClose(Command)
	If WriteSpreadsheetDocument() Then 
		Close();
	EndIf;
EndProcedure

&AtClient
Procedure Write(Command)
	WriteSpreadsheetDocument();
EndProcedure

&AtClient
Procedure Edit(Command)
	Items.SpreadsheetDocument.Edit = Not Items.SpreadsheetDocument.Edit;
	SetUpCommandPresentation();
	SetUpSpreadsheetDocumentRepresentation();
EndProcedure

// Formatting

&AtClient
Procedure Font(Command)
	
	FontChooseDialog = New FontChooseDialog;
	
	AreasToProcess = AreaListForChangingFont();
	If AreasToProcess.Count() = 0 Then
		Return;
	EndIf;
	
	#If Not WebClient Then
		CommonFont = New Font(AreasToProcess[0].Font);
		
		For DataAreaNumber = 1 To AreasToProcess.Count()-1 Do
			Area = AreasToProcess[DataAreaNumber];
			If Area.Font <> CommonFont Then
				FontName = ?(Area.Font.Name = CommonFont.Name, Undefined, "");
				Size = ?(Area.Font.Size = CommonFont.Size, Undefined, 0);
				Bold = ?(Area.Font.Bold = CommonFont.Bold, Undefined, False);
				Italic = ?(Area.Font.Italic = CommonFont.Italic, Undefined, False);
				Underscore = ?(Area.Font.Underline = CommonFont.Underline, Undefined, False);
				StrikeOut = ?(Area.Font.Strikeout= CommonFont.Strikeout, Undefined, False);
				
				CommonFont = New Font(AreasToProcess[0].Font, FontName, Size, Bold, Italic, Underscore, Strikeout);
			EndIf;
		EndDo;
		FontChooseDialog.Font = CommonFont;
	#EndIf
	
	NotifyDescription = New NotifyDescription("FontSelectionOnComplete", ThisObject, AreasToProcess);
	FontChooseDialog.Show(NotifyDescription);
	
EndProcedure

&AtClient
Procedure IncreaseFontSize(Command)
	
	For Each Area In AreaListForChangingFont() Do
		Size = Area.Font.Size;
		Size = Size + IncreaseFontSizeChangeStep(Size);
		Area.Font = New Font(Area.Font,,Size);
	EndDo;
	
EndProcedure

&AtClient
Procedure DecreaseFontSize(Command)
	
	For Each Area In AreaListForChangingFont() Do
		Size = Area.Font.Size;
		Size = Size - DecreaseFontSizeChangeStep(Size);
		If Size < 1 Then
			Size = 1;
		EndIf;
		Area.Font = New Font(Area.Font,,Size);
	EndDo;
	
EndProcedure

&AtClient
Procedure Bold(Command)
	
	ValueToSet = Undefined;
	For Each Area In AreaListForChangingFont() Do
		If ValueToSet = Undefined Then
			ValueToSet = Not Area.Font.Bold = True;
		EndIf;
		Area.Font = New Font(Area.Font,,,ValueToSet);
	EndDo;
	
	UpdateCommandBarButtonMarks();
	
EndProcedure

&AtClient
Procedure Italic(Command)
	
	ValueToSet = Undefined;
	For Each Area In AreaListForChangingFont() Do
		If ValueToSet = Undefined Then
			ValueToSet = Not Area.Font.Italic = True;
		EndIf;
		Area.Font = New Font(Area.Font,,,,ValueToSet);
	EndDo;
	
	UpdateCommandBarButtonMarks();
	
EndProcedure

&AtClient
Procedure Underline(Command)
	
	ValueToSet = Undefined;
	For Each Area In AreaListForChangingFont() Do
		If ValueToSet = Undefined Then
			ValueToSet = Not Area.Font.Underline = True;
		EndIf;
		Area.Font = New Font(Area.Font,,,,,ValueToSet);
	EndDo;
	
	UpdateCommandBarButtonMarks();
	
EndProcedure

&AtClient
Procedure Strikeout(Command)
	
	ValueToSet = Undefined;
	For Each Area In AreaListForChangingFont() Do
		If ValueToSet = Undefined Then
			ValueToSet = Not Area.Font.Strikeout = True;
		EndIf;
		Area.Font = New Font(Area.Font,,,,,,ValueToSet);
	EndDo;
	
	UpdateCommandBarButtonMarks();
	
EndProcedure

&AtClient
Procedure BackColor(Command)
	ColorChooseDialog = New ColorChooseDialog;
	#If Not WebClient Then
	ColorChooseDialog.Color = Items.SpreadsheetDocument.CurrentArea.BackColor;
	#EndIf
	
	NotifyDescription = New NotifyDescription("BackgroundColorSelectionOnComplete", ThisObject);
	ColorChooseDialog.Show(NotifyDescription);
EndProcedure

&AtClient
Procedure TextColor(Command)
	ColorChooseDialog = New ColorChooseDialog;
	#If Not WebClient Then
	ColorChooseDialog.Color = Items.SpreadsheetDocument.CurrentArea.TextColor;
	#EndIf
	
	NotifyDescription = New NotifyDescription("TextColorSelectionOnComplete", ThisObject);
	ColorChooseDialog.Show(NotifyDescription);
EndProcedure

// Aligning

&AtClient
Procedure AlignLeft(Command)
	
	For Each Area In Items.SpreadsheetDocument.GetSelectedAreas() Do
		Area.HorizontalAlign = HorizontalAlign.Left;
	EndDo;
	
	UpdateCommandBarButtonMarks();
	
EndProcedure

&AtClient
Procedure AlignRight(Command)
	
	For Each Area In Items.SpreadsheetDocument.GetSelectedAreas() Do
		Area.HorizontalAlign = HorizontalAlign.Right;
	EndDo;
	
	UpdateCommandBarButtonMarks();
	
EndProcedure

&AtClient
Procedure Center(Command)
	
	For Each Area In Items.SpreadsheetDocument.GetSelectedAreas() Do
		Area.HorizontalAlign = HorizontalAlign.Center;
	EndDo;
	
	UpdateCommandBarButtonMarks();
	
EndProcedure

&AtClient
Procedure Justify(Command)
	
	For Each Area In Items.SpreadsheetDocument.GetSelectedAreas() Do
		Area.HorizontalAlign = HorizontalAlign.Justify;
	EndDo;
	
	UpdateCommandBarButtonMarks();
	
EndProcedure

// Borders

&AtClient
Procedure LeftBorder(Command)
	
	Line = New Line(SpreadsheetDocumentCellLineType.Solid, 1);
	
	For Each AreaToProcess In Items.SpreadsheetDocument.GetSelectedAreas() Do
		DrawLeftBorder(AreaToProcess, Line);
	EndDo;
	
	UpdateCommandBarButtonMarks();
	
EndProcedure

&AtClient
Procedure TopBorder(Command)
	
	Line = New Line(SpreadsheetDocumentCellLineType.Solid, 1);
	
	For Each AreaToProcess In Items.SpreadsheetDocument.GetSelectedAreas() Do
		DrawTopBorder(AreaToProcess, Line);
	EndDo;
	
	UpdateCommandBarButtonMarks();
	
EndProcedure

&AtClient
Procedure RightBorder(Command)
	
	Line = New Line(SpreadsheetDocumentCellLineType.Solid, 1);
	
	For Each AreaToProcess In Items.SpreadsheetDocument.GetSelectedAreas() Do
		DrawRightBorder(AreaToProcess, Line);
	EndDo;
	
	UpdateCommandBarButtonMarks();
	
EndProcedure

&AtClient
Procedure BottomBorder(Command)
	
	Line = New Line(SpreadsheetDocumentCellLineType.Solid, 1);
	
	For Each AreaToProcess In Items.SpreadsheetDocument.GetSelectedAreas() Do
		DrawBottomBorder(AreaToProcess, Line);
	EndDo;
	
	UpdateCommandBarButtonMarks();
	
EndProcedure

&AtClient
Procedure AllBorders(Command)
	
	Line = New Line(SpreadsheetDocumentCellLineType.Solid, 1);
	
	For Each Area In Items.SpreadsheetDocument.GetSelectedAreas() Do
		Area.LeftBorder = Line;
		Area.TopBorder = Line;
		Area.RightBorder = Line;
		Area.BottomBorder = Line;
	EndDo;
	
	UpdateCommandBarButtonMarks();
	
EndProcedure

&AtClient
Procedure OutsideBorder(Command)
	
	Line = New Line(SpreadsheetDocumentCellLineType.Solid, 1);
	
	For Each Area In Items.SpreadsheetDocument.GetSelectedAreas() Do
		#If WebClient Then
			DrawLeftBorder(Area, Line);
			DrawTopBorder(Area, Line);
			DrawRightBorder(Area, Line);
			DrawBottomBorder(Area, Line);
		#Else
			Area.Outline(Line, Line, Line, Line);
		#EndIf
	EndDo;
	
	UpdateCommandBarButtonMarks();
	
EndProcedure

&AtClient
Procedure InsideBorder(Command)
	
	Line = New Line(SpreadsheetDocumentCellLineType.Solid, 1);
	
	For Each AreaToProcess In Items.SpreadsheetDocument.GetSelectedAreas() Do
		
		If AreaToProcess.Left <> AreaToProcess.Right Then
			Area = SpreadsheetDocument.Area(
			Items.SpreadsheetDocument.CurrentArea.Top,
			Items.SpreadsheetDocument.CurrentArea.Left + 1,
			Items.SpreadsheetDocument.CurrentArea.Bottom,
			Items.SpreadsheetDocument.CurrentArea.Right);
			
			Area.LeftBorder = Line;
		EndIf;
		
		If AreaToProcess.Top <> AreaToProcess.Bottom Then
			Area = SpreadsheetDocument.Area(
			Items.SpreadsheetDocument.CurrentArea.Top + 1,
			Items.SpreadsheetDocument.CurrentArea.Left,
			Items.SpreadsheetDocument.CurrentArea.Bottom,
			Items.SpreadsheetDocument.CurrentArea.Right);
			
			Area.TopBorder = Line;
		EndIf;
	EndDo;
	
	UpdateCommandBarButtonMarks();
	
EndProcedure

&AtClient
Procedure ThickOutsideBorder(Command)
	
	Line = New Line(SpreadsheetDocumentCellLineType.Solid, 2);
	
	For Each Area In Items.SpreadsheetDocument.GetSelectedAreas() Do
		#If WebClient Then
			DrawLeftBorder(Area, Line);
			DrawTopBorder(Area, Line);
			DrawRightBorder(Area, Line);
			DrawBottomBorder(Area, Line);
		#Else
			Area.Outline(Line, Line, Line, Line);
		#EndIf
	EndDo;
	
	UpdateCommandBarButtonMarks();
	
EndProcedure

&AtClient
Procedure BoldTopBorder(Command)
	
	Line = New Line(SpreadsheetDocumentCellLineType.Solid, 2);
	
	For Each AreaToProcess In Items.SpreadsheetDocument.GetSelectedAreas() Do
		DrawTopBorder(AreaToProcess, Line);
	EndDo;
	
	UpdateCommandBarButtonMarks();
	
EndProcedure

&AtClient
Procedure ThickBottomBorder(Command)
	
	Line = New Line(SpreadsheetDocumentCellLineType.Solid, 2);
	
	For Each AreaToProcess In Items.SpreadsheetDocument.GetSelectedAreas() Do
		DrawBottomBorder(AreaToProcess, Line);
	EndDo;
	
	UpdateCommandBarButtonMarks();
	
EndProcedure

&AtClient
Procedure NoBorder(Command)
	
	Line = New Line(SpreadsheetDocumentCellLineType.None);

	Area = Items.SpreadsheetDocument.CurrentArea;
	Area.LeftBorder = Line;
	Area.TopBorder = Line;
	Area.RightBorder = Line;
	Area.BottomBorder = Line;
	
	UpdateCommandBarButtonMarks();
	
EndProcedure

// Processing area

&AtClient
Procedure Merge(Command)
	
	Area = Items.SpreadsheetDocument.CurrentArea;
	Area.Union();
	
	UpdateCommandBarButtonMarks();
	
EndProcedure

&AtClient
Procedure UndoMerge(Command)
	
	Area = Items.SpreadsheetDocument.CurrentArea;
	Area.UndoMerge();
	
	UpdateCommandBarButtonMarks();
	
EndProcedure

&AtClient
Procedure InsertComment(Command)
	Comment = Items.SpreadsheetDocument.CurrentArea.Comment.Text;
	NotifyDescription = New NotifyDescription("InsertCommentCompletion", ThisObject);
	ShowInputString(NotifyDescription, Comment, NStr("en = 'Comment'"), , True);
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure LoadSpreadsheetDocumentFromMetadata()
	If CommonUse.SubsystemExists("StandardSubsystems.Print") Then
		PrintManagementModule = CommonUse.CommonModule("PrintManagement");
		SpreadsheetDocument = PrintManagementModule.PrintFormTemplate(Parameters.TemplateMetadataObjectName);
	EndIf;
EndProcedure

&AtClient
Procedure SetUpSpreadsheetDocumentRepresentation()
	Items.SpreadsheetDocument.ShowHeaders = Items.SpreadsheetDocument.Edit;
	Items.SpreadsheetDocument.ShowGrid = Items.SpreadsheetDocument.Edit;
EndProcedure

&AtClient
Procedure UpdateCommandBarButtonMarks();
	
	#If Not WebClient Then
	Area = Items.SpreadsheetDocument.CurrentArea;
	If TypeOf(Area) <> Type("SpreadsheetDocumentRange") Then
		Return;
	EndIf;
	
	// Font
	Font = Area.Font;
	Items.Bold.Check = Font <> Undefined And Font.Bold = True;
	Items.Italic.Check = Font <> Undefined And Font.Italic = True;
	Items.Underline.Check = Font <> Undefined And Font.Underline = True;
	Items.Strikeout.Check = Font <> Undefined And Font.Strikeout = True;
	
	// Horizontal alignment
	Items.AlignLeft.Check = Area.HorizontalAlign = HorizontalAlign.Left;
	Items.Center.Check = Area.HorizontalAlign = HorizontalAlign.Center;
	Items.AlignRight.Check = Area.HorizontalAlign = HorizontalAlign.Right;
	Items.Justify.Check = Area.HorizontalAlign = HorizontalAlign.Justify;
	
	#EndIf
	
EndProcedure

&AtClient
Function IncreaseFontSizeChangeStep(Size)
	If Size = -1 Then
		Return 10;
	EndIf;
	
	If Size < 10 Then
		Return 1;
	ElsIf 10 <= Size And  Size < 20 Then
		Return 2;
	ElsIf 20 <= Size And  Size < 48 Then
		Return 4;
	ElsIf 48 <= Size And  Size < 72 Then
		Return 6;
	ElsIf 72 <= Size And  Size < 96 Then
		Return 8;
	Else
		Return Round(Size / 10);
	EndIf;
EndFunction

&AtClient
Function DecreaseFontSizeChangeStep(Size)
	If Size = -1 Then
		Return -8;
	EndIf;
	
	If Size <= 11 Then
		Return 1;
	ElsIf 11 < Size And Size <= 23 Then
		Return 2;
	ElsIf 23 < Size And Size <= 53 Then
		Return 4;
	ElsIf 53 < Size And Size <= 79 Then
		Return 6;
	ElsIf 79 < Size And Size <= 105 Then
		Return 8;
	Else
		Return Round(Size / 11);
	EndIf;
EndFunction

&AtClient
Function AreaListForChangingFont()
	
	Result = New Array;
	
	For Each AreaToProcess In Items.SpreadsheetDocument.GetSelectedAreas() Do
		If AreaToProcess.Font <> Undefined Then
			Result.Add(AreaToProcess);
			Continue;
		EndIf;
		
		AreaToProcessTop = AreaToProcess.Top;
		AreaToProcessBottom = AreaToProcess.Bottom;
		AreaToProcessLeft = AreaToProcess.Left;
		AreaToProcessRight = AreaToProcess.Right;
		
		If AreaToProcessTop = 0 Then
			AreaToProcessTop = 1;
		EndIf;
		
		If AreaToProcessBottom = 0 Then
			AreaToProcessBottom = SpreadsheetDocument.TableHeight;
		EndIf;
		
		If AreaToProcessLeft = 0 Then
			AreaToProcessLeft = 1;
		EndIf;
		
		If AreaToProcessRight = 0 Then
			AreaToProcessRight = SpreadsheetDocument.TableWidth;
		EndIf;
		
		If AreaToProcess.AreaType = SpreadsheetDocumentCellAreaType.Columns Then
			AreaToProcessTop = AreaToProcess.Bottom;
			AreaToProcessBottom = SpreadsheetDocument.TableHeight;
		EndIf;
			
		For ColumnNumber = AreaToProcessLeft to AreaToProcessRight Do
			ColumnWidth = Undefined;
			For LineNumber = AreaToProcessTop to AreaToProcessBottom Do
				Cell = SpreadsheetDocument.Area(LineNumber, ColumnNumber, LineNumber, ColumnNumber);
				If AreaToProcess.AreaType = SpreadsheetDocumentCellAreaType.Columns Then
					If ColumnWidth = Undefined Then
						ColumnWidth = Cell.ColumnWidth;
					EndIf;
					If Cell.ColumnWidth <> ColumnWidth Then
						Continue;
					EndIf;
				EndIf;
				If Cell.Font <> Undefined Then
					Result.Add(Cell);
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
	Return Result;
	
EndFunction

&AtClient
Function WriteSpreadsheetDocument()
	
	If IsNew() Or EditingProhibited Then
		SaveFileDialog = New FileDialog(FileDialogMode.Save);
		SaveFileDialog.FullFileName = DocumentName;
		SaveFileDialog.Filter = NStr("en = 'Spreadsheet document'") + " (*.mxl)|*.mxl";
		If SaveFileDialog.Choose() Then
			Parameters.PathToFile = SaveFileDialog.FullFileName;
			DocumentName = Mid(SaveFileDialog.FullFileName, StrLen(SaveFileDialog.Directory) + 1);
			If Lower(Right(DocumentName, 4)) = ".mxl" Then
				DocumentName = Left(DocumentName, StrLen(DocumentName) - 4);
			EndIf;
		Else
			Return False;
		EndIf;
	EndIf;
		
	If Not IsBlankString(Parameters.PathToFile) Then
		SpreadsheetDocument.Write(Parameters.PathToFile);
		EditingProhibited = False;
	EndIf;
	
	WritingComplited = True;
	Modified = False;
	SetTitle();
	
	Return True;
	
EndFunction

&AtClient
Function NewDocumentName()
	Return NStr("en = 'New'");
EndFunction

&AtClient
Procedure SetTitle()
	
	Title = DocumentName;
	If IsNew() Then
		Title = Title + " (" + NStr("en = 'creating'") + ")";
	ElsIf EditingProhibited Then
		Title = Title + " (" + NStr("en = 'read only'") + ")";
	EndIf;
	
EndProcedure

&AtClient
Procedure SetUpCommandPresentation()
	
	CanEditDocument = Items.SpreadsheetDocument.Edit;
	Items.Edit.Check = CanEditDocument;
	Items.EditingCommands.Enabled = CanEditDocument;
	Items.WriteAndClose.Enabled = CanEditDocument Or Modified;
	Items.Write.Enabled = CanEditDocument Or Modified;
	
	If CanEditDocument And Not IsBlankString(Parameters.TemplateMetadataObjectName) Then
		Items.Warning.Visible = True;
	EndIf;
	
EndProcedure

&AtClient
Function IsNew()
	Return IsBlankString(Parameters.TemplateMetadataObjectName) And IsBlankString(Parameters.PathToFile);
EndFunction

&AtClient
Procedure DrawLeftBorder(AreaToProcess, Line)
	
	Area = SpreadsheetDocument.Area(
		AreaToProcess.Top,
		AreaToProcess.Left,
		AreaToProcess.Bottom,
		AreaToProcess.Left);
	
	Area.LeftBorder = Line;
	
EndProcedure

&AtClient
Procedure DrawTopBorder(AreaToProcess, Line)
	
	Area = SpreadsheetDocument.Area(
		AreaToProcess.Top,
		AreaToProcess.Left,
		AreaToProcess.Top,
		AreaToProcess.Right);
	
	Area.TopBorder = Line;
	
EndProcedure

&AtClient
Procedure DrawRightBorder(AreaToProcess, Line)
	
	Area = SpreadsheetDocument.Area(
		AreaToProcess.Top,
		AreaToProcess.Right,
		AreaToProcess.Bottom,
		AreaToProcess.Right);
	
	Area.RightBorder = Line;
	
EndProcedure

&AtClient
Procedure DrawBottomBorder(AreaToProcess, Line)
	
	Area = SpreadsheetDocument.Area(
		AreaToProcess.Bottom,
		AreaToProcess.Left,
		AreaToProcess.Bottom,
		AreaToProcess.Right);
	
	Area.BottomBorder = Line;
	
EndProcedure

&AtClient
Procedure InsertCommentCompletion(Row, AdditionalParameters) Export
	If Row <> Undefined Then
		Items.SpreadsheetDocument.CurrentArea.Comment.Text = Row;
	EndIf;
EndProcedure

&AtClient
Procedure FontSelectionOnComplete(SelectedFont, AreasToProcess) Export
	
	If SelectedFont = Undefined Then
		Return;
	EndIf;
	
	For Each Area In AreasToProcess Do
		Area.Font = SelectedFont;
	EndDo;
	
	UpdateCommandBarButtonMarks();
	
EndProcedure

&AtClient
Procedure BackgroundColorSelectionOnComplete(SelectedColor, AdditionalParameters) Export
	If SelectedColor <> Undefined Then
		Items.SpreadsheetDocument.CurrentArea.BackColor = SelectedColor;
	EndIf;
EndProcedure

&AtClient
Procedure TextColorSelectionOnComplete(SelectedColor, AdditionalParameters) Export
	If SelectedColor <> Undefined Then
		Items.SpreadsheetDocument.CurrentArea.TextColor = SelectedColor;
	EndIf;
EndProcedure

#EndRegion
