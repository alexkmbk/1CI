#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("Autotest") Then
		Return;
	EndIf;
	
	If Parameters.ChoiceMode Then
		WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
	EndIf;
	
	If Parameters.Property("Title") Then
		AutoTitle = False;
		Title = Parameters.Title;
	EndIf;
	If Parameters.Property("Representation") Then
		Items.List.Representation = TableRepresentation[Parameters.Representation];
	EndIf;
	
	ChoiceList = Items.PublicationFilter.ChoiceList;
	ChoiceList.Add(Undefined, " "); // NStr("en = 'All'")
	
	KindUsed = Enums.AdditionalReportsAndDataProcessorsPublicationVariants.Used;
	KindDisabled = Enums.AdditionalReportsAndDataProcessorsPublicationVariants.Disabled;
	KindDebugMode = Enums.AdditionalReportsAndDataProcessorsPublicationVariants.DebugMode;
	
	AvaliablePublicationKinds = AdditionalReportsAndDataProcessorsCached.AvaliablePublicationKinds();
	
	AllPublicationsExceptUnused = New Array;
	AllPublicationsExceptUnused.Add(KindUsed);
	If AvaliablePublicationKinds.Find(KindDebugMode) <> Undefined Then
		AllPublicationsExceptUnused.Add(KindDebugMode);
	EndIf;
	
	If AllPublicationsExceptUnused.Count() > 1 Then
		
		ArrayPresentation = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = '%1 or %2'"),
			String(AllPublicationsExceptUnused[0]),
			String(AllPublicationsExceptUnused[1]));
		
		ChoiceList.Add(1, ArrayPresentation);
		
	EndIf;
	
	For Each EnumValue In Enums.AdditionalReportsAndDataProcessorsPublicationVariants Do
		If AvaliablePublicationKinds.Find(EnumValue) <> Undefined Then
			ChoiceList.Add(EnumValue, String(EnumValue));
		EndIf;
	EndDo;
	
	ChoiceList = Items.KindFilter.ChoiceList;
	ChoiceList.Add(Undefined, " "); //NStr("en = 'All reports and data processors'")
	ChoiceList.Add(1, NStr("en = 'Reports only'"));
	ChoiceList.Add(2, NStr("en = 'Data processors only'"));
	For Each EnumValue In Enums.AdditionalReportAndDataProcessorKinds Do
		ChoiceList.Add(EnumValue, String(EnumValue));
	EndDo;
	
	AdditionalReportKinds = New Array;
	AdditionalReportKinds.Add(Enums.AdditionalReportAndDataProcessorKinds.AdditionalReport);
	AdditionalReportKinds.Add(Enums.AdditionalReportAndDataProcessorKinds.Report);
	
	List.Parameters.SetParameterValue("PublicationFilter",     PublicationFilter);
	List.Parameters.SetParameterValue("KindFilter",            KindFilter);
	List.Parameters.SetParameterValue("AdditionalReportKinds", AdditionalReportKinds);
	List.Parameters.SetParameterValue("AllPublicationsExceptUnused", AllPublicationsExceptUnused);
	
	Items.AddingButtons.Visible = AdditionalReportsAndDataProcessors.AddRight();
	
	If Not CommonUse.SubsystemExists("StandardSubsystems.BatchObjectModification") Then
		Items.ChangeSelected.Visible     = False;
		Items.ChangeSelectedList.Visible = False;
	EndIf;
	
	If Parameters.Property("AdditionalReportsAndDataProcessorsCheck") Then
		Items.Create.Visible       = False;
		Items.CreateFolder.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	PublicationFilter = Settings.Get("PublicationFilter");
	KindFilter        = Settings.Get("KindFilter");
	List.Parameters.SetParameterValue("PublicationFilter", PublicationFilter);
	List.Parameters.SetParameterValue("KindFilter",        KindFilter);
EndProcedure

#EndRegion

#Region FormHeaderItemEventHandlers

&AtClient
Procedure PublicationFilterOnChange(Item)
	DCParameterValue = List.Parameters.Items.Find("PublicationFilter");
	If DCParameterValue.Value <> PublicationFilter Then
		DCParameterValue.Value = PublicationFilter;
	EndIf;
EndProcedure

&AtClient
Procedure KindFilterOnChange(Item)
	DCParameterValue = List.Parameters.Items.Find("KindFilter");
	If DCParameterValue.Value <> KindFilter Then
		DCParameterValue.Value = KindFilter;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ExportToFile(Command)
	RowData = Items.List.CurrentData;
	If RowData = Undefined Or Not ItemSelected(RowData) Then
		Return;
	EndIf;
	
	ExportParameters = New Structure;
	ExportParameters.Insert("Ref",      RowData.Ref);
	ExportParameters.Insert("IsReport", RowData.IsReport);
	ExportParameters.Insert("FileName", RowData.FileName);
	AdditionalReportsAndDataProcessorsClient.ExportToFile(ExportParameters);
EndProcedure

&AtClient
Procedure ImportDataProcessorsReportFile(Command)
	RowData = Items.List.CurrentData;
	If RowData = Undefined Or Not ItemSelected(RowData) Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Key", RowData.Ref);
	FormParameters.Insert("ShowImportFromFileDialogOnOpen", True);
	OpenForm("Catalog.AdditionalReportsAndDataProcessors.ObjectForm", FormParameters);
EndProcedure

&AtClient
Procedure ChangeSelected(Command)
	BatchObjectModificationClientModule = CommonUseClient.CommonModule("BatchObjectModificationClient");
	BatchObjectModificationClientModule.ChangeSelected(Items.List);
EndProcedure

&AtClient
Procedure PublicationUsed(Command)
	ChangePublication("Used");
EndProcedure

&AtClient
Procedure PublicationDisabled(Command)
	ChangePublication("Disabled");
EndProcedure

&AtClient
Procedure PublicationDebugMode(Command)
	ChangePublication("DebugMode");
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtClient
Function ItemSelected(RowData)
	If TypeOf(RowData.Ref) <> Type("CatalogRef.AdditionalReportsAndDataProcessors") Then
		ShowMessageBox(, NStr("en = 'Cannot execute the command for the specified object.
			|Select additional report or data processor.'"));
		Return False;
	EndIf;
	If RowData.IsFolder Then
		ShowMessageBox(, NStr("en = 'Cannot execute the command for the group.
			|Select additional report or data processor.'"));
		Return False;
	EndIf;
	Return True;
EndFunction

&AtClient
Procedure ImportDataProcessorsReportFileCompletion(Result, AdditionalParameters) Export
	
	If Result = "FileImported" Then
		ShowValue(,Items.List.CurrentData.Ref);
	EndIf;
	
EndProcedure	

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

 

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.List.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Publication");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.AdditionalReportsAndDataProcessorsPublicationVariants.DebugMode;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDataColor);

	

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.List.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Publication");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.AdditionalReportsAndDataProcessorsPublicationVariants.Disabled;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleDataColor);

EndProcedure

&AtClient
Procedure ChangePublication(PublicationOption)
	
	ClearMessages();
	Result = PublicationChanging(PublicationOption);
	
	If TypeOf(Result) = Type("Structure") Then
		StandardSubsystemsClient.ShowExecutionResult(ThisObject, Result);
	EndIf;
	
EndProcedure

&AtServer
Function PublicationChanging(PublicationOption)
	
	NewExecutionResult = StandardSubsystemsClientServer.NewExecutionResult();
	SelectedRows = Items.List.SelectedRows;
	
	If SelectedRows.Count() = 0 Then
		MessageText = NStr("en = 'No additional report or data processor is selected.'");
		WarningOutput = NewExecutionResult.WarningOutput;
		WarningOutput.Use = True;
		WarningOutput.Text = MessageText;
		Return NewExecutionResult;
	EndIf;
	
	For Each SelectedRow In SelectedRows Do
		
		Try
			LockDataForEdit(SelectedRow);
		Except
			ErrorInfo = ErrorInfo();
			WarningOutput = NewExecutionResult.WarningOutput;
			WarningOutput.Use = True;
			WarningOutput.Text = BriefErrorDescription(ErrorInfo);
			
			Items.List.Refresh();
			Return NewExecutionResult;
		EndTry;
		
		BeginTransaction();
		
		Object = SelectedRow.GetObject();
		If PublicationOption = "Used" Then
			Object.Publication = Enums.AdditionalReportsAndDataProcessorsPublicationVariants.Used;
		ElsIf PublicationOption = "DebugMode" Then
			Object.Publication = Enums.AdditionalReportsAndDataProcessorsPublicationVariants.DebugMode;
		Else
			Object.Publication = Enums.AdditionalReportsAndDataProcessorsPublicationVariants.Disabled;
		EndIf;
		
		Object.AdditionalProperties.Insert("ListCheck");
		If Not Object.CheckFilling() Then
			RollbackTransaction();
			Items.List.Refresh();
			
			ErrorPresentation = "";
			ArrayOfMessages = GetUserMessages(True);
			For Each UserMessage In ArrayOfMessages Do
				ErrorPresentation = ErrorPresentation + UserMessage.Text + Chars.LF;
			EndDo;
			
			UnlockDataForEdit(SelectedRow);
			
			WarningOutput      = NewExecutionResult.WarningOutput;
			WarningOutput.Use  = True;
			WarningOutput.Text = ErrorPresentation;
			Return NewExecutionResult;
		EndIf;
		
		Object.Write();
		
		CommitTransaction();
		UnlockDataForEdit(SelectedRow);
		
	EndDo;
	
	Items.List.Refresh();
	
	If SelectedRows.Count() = 1 Then
		ObjectName  = CommonUse.ObjectAttributeValue(SelectedRows[0], "Description");
		MessageText = NStr("en = 'Availability of ""%1"" additional report or data processor is changed.'");
		MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText, ObjectName);
	Else
		MessageText = NStr("en = 'Availability of %1 additional reports or data processors is changed.'");
		MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText, SelectedRows.Count());
	EndIf;
	
	NotificationOutput       = NewExecutionResult.NotificationOutput;
	NotificationOutput.Use   = True;
	NotificationOutput.Text  = MessageText;
	NotificationOutput.Title = NStr("en = 'Availability change'");
	
	Return NewExecutionResult;
	
EndFunction

#EndRegion
