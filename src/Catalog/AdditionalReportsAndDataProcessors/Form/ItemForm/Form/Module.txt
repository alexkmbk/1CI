&AtClient
Var ClientCache;

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	SetConditionalAppearance();
	If Parameters.Property("Autotest") Then
		Return;
	EndIf;
	
	// Checking the right to download new data processors to the infobase
	IsNew = Object.Ref.IsEmpty();
	If IsNew And Not AdditionalReportsAndDataProcessors.AddRight() Then
		Raise NStr("en = 'Insufficient access rights for adding additional reports or data processors.'");
	EndIf;
	
	// Applying restrictions based on the infobase settings to the list of publication kinds
	Items.Publication.ChoiceList.Clear();
	AvaliablePublicationKinds = AdditionalReportsAndDataProcessorsCached.AvaliablePublicationKinds();
	For Each PublicationKind In AvaliablePublicationKinds Do
		Items.Publication.ChoiceList.Add(PublicationKind);
	EndDo;
	
	// Applying the "display extended information" restriction
	ExtendedInformationDisplaying = AdditionalReportsAndDataProcessors.ShowExtendedInformation(Object.Ref);
	Items.PageAdditionalInfo.Visible = ExtendedInformationDisplaying;
	
	// Applying restriction to importing data processors from files and exporting them to files
	Items.LoadFromFile.Visible = 
		AdditionalReportsAndDataProcessors.CanImportDataProcessorFromFile(Object.Ref);
	Items.ExportToFile.Visible =
		AdditionalReportsAndDataProcessors.CanExportDataProcessorToFile(Object.Ref);
	
	KindAdditionalDataProcessor = Enums.AdditionalReportAndDataProcessorKinds.AdditionalDataProcessor;
	KindAdditionalReport        = Enums.AdditionalReportAndDataProcessorKinds.AdditionalReport;
	ReportKind                  = Enums.AdditionalReportAndDataProcessorKinds.Report;
	
	Parameters.Property("ShowImportFromFileDialogOnOpen", ShowImportFromFileDialogOnOpen);
	
	If IsNew Then
		Object.UseForObjectForm = True;
		Object.UseForListForm   = True;
		ShowImportFromFileDialogOnOpen = True;
	EndIf;
	
	If ShowImportFromFileDialogOnOpen And Not Items.LoadFromFile.Visible Then
		Raise NStr("en = 'Insufficient rights to import additional report or data processor'");
	EndIf;
	
	FillCommands();
	
	PermissionAddress = PutToTempStorage(
		FormAttributeToValue("Object").Permissions.Unload(),
		ThisObject.UUID);
	
	SetVisibilityAvailability();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ClientCache = New Structure;
	
	If ShowImportFromFileDialogOnOpen Then
		AttachIdleHandler("UpdateFromFileStart", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	
	If Upper(ChoiceSource.FormName) = Upper("Catalog.AdditionalReportsAndDataProcessors.Form.PickSections") Then
		
		If TypeOf(SelectedValue) <> Type("ValueList") Then
			Return;
		EndIf;
		
		Object.Sections.Clear();
		For Each ListItem In SelectedValue Do
			NewRow = Object.Sections.Add();
			NewRow.Section = ListItem.Value;
		EndDo;
		
		Modified = True;
		SetVisibilityAvailability();
		
	ElsIf Upper(ChoiceSource.FormName) = Upper("Catalog.AdditionalReportsAndDataProcessors.Form.QuickAccessToAdditionalReportsAndDataProcessors") Then
		
		If TypeOf(SelectedValue) <> Type("ValueList") Then
			Return;
		EndIf;
		
		ItemCommand = Object.Commands.FindByID(ClientCache.CommandRowID);
		If ItemCommand = Undefined Then
			Return;
		EndIf;
		
		Found = QuickAccess.FindRows(New Structure("CommandID", ItemCommand.ID));
		For Each TableRow In Found Do
			QuickAccess.Delete(TableRow);
		EndDo;
		
		For Each ListItem In SelectedValue Do
			TableRow = QuickAccess.Add();
			TableRow.CommandID = ItemCommand.ID;
			TableRow.User = ListItem.Value;
		EndDo;
		
		ItemCommand.QuickAccessPresentation = UserQuickAccessPresentation(SelectedValue.Count());
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "MetadataObjectSelection" Then
		
		ImportSelectedMetadataObjects(Parameter);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	If AdditionalReportsAndDataProcessors.CanExportDataProcessorToFile(Object.Ref) Then
		
		DataProcessorDataAddress = PutToTempStorage(
			CurrentObject.DataProcessorStorage.Get(),
			UUID);
		
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Ref", CurrentObject.Ref);
	Query.Text =
	"SELECT
	|	RegisterData.CommandID,
	|	RegisterData.User
	|FROM
	|	InformationRegister.DataProcessorAccessUserSettings AS RegisterData
	|WHERE
	|	RegisterData.AdditionalReportOrDataProcessor = &Ref
	|	AND RegisterData.Available = TRUE";
	QuickAccess.Load(Query.Execute().Unload());
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	If DataProcessorRegistration And AdditionalReportsAndDataProcessors.CanImportDataProcessorFromFile(Object.Ref) Then
		DataProcessorBinaryData = GetFromTempStorage(DataProcessorDataAddress);
		CurrentObject.DataProcessorStorage = New ValueStorage(DataProcessorBinaryData, New Deflation(9));
	EndIf;
	
	If Object.Kind = KindAdditionalDataProcessor Or Object.Kind = KindAdditionalReport Then
		CurrentObject.AdditionalProperties.Insert("ActualCommands", Object.Commands.Unload());
	Else
		QuickAccess.Clear();
	EndIf;
	
	CurrentObject.AdditionalProperties.Insert("QuickAccess", QuickAccess.Unload());
	
	CurrentObject.Permissions.Load(GetFromTempStorage(PermissionAddress));
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	If CurrentObject.AdditionalProperties.Property("AttachingError") Then
		Message = New UserMessage;
		Message.Text = CurrentObject.AdditionalProperties.AttachingError;
		Message.Message();
	EndIf;
	IsNew = False;
	If DataProcessorRegistration Then
		RefreshReusableValues();
		DataProcessorRegistration = False;
	EndIf;
	FillCommands();
	SetVisibilityAvailability();
EndProcedure

#EndRegion

#Region FormHeaderItemEventHandlers

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	AdditionalReportsAndDataProcessorsClient.EditMultilineText(
		ThisObject,
		Item.EditText,
		Object,
		"Comment"
	);
EndProcedure

&AtClient
Procedure AdditionalReportOptionBeforeAddRow(Item, Cancel, Clone, Parent, Group)
	Cancel = True;
EndProcedure

&AtClient
Procedure AdditionalReportOptionBeforeRowChange(Item, Cancel)
	Cancel = True;
	OpenOption();
EndProcedure

&AtClient
Procedure AdditionalReportOptionsBeforeDelete(Item, Cancel)
	Cancel = True;
	Option = Items.AdditionalReportOptions.CurrentData;
	If Option = Undefined Then
		Return;
	EndIf;
	
	If Not Option.Custom Then
		ShowMessageBox(, NStr("en = 'Cannot mark a predefined report option for deletion.'"));
		Return;
	EndIf;
	
	QuestionText = NStr("en = 'Do you want to mark ""%1"" for deletion?'");
	QuestionText = StringFunctionsClientServer.SubstituteParametersInString(QuestionText, Option.Description);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Option", Option);
	Handler = New NotifyDescription("AdditionalReportOptionsBeforeDeleteCompletion", ThisObject, AdditionalParameters);
	ShowQueryBox(Handler, QuestionText, QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
EndProcedure

&AtClient
Procedure UseForListFormOnChange(Item)
	If Not Object.UseForObjectForm And Not Object.UseForListForm Then
		Object.UseForObjectForm = True;
	EndIf;
EndProcedure

&AtClient
Procedure UseForObjectFormOnChange(Item)
	If Not Object.UseForObjectForm And Not Object.UseForListForm Then
		Object.UseForListForm = True;
	EndIf;
EndProcedure

&AtClient
Procedure DecorationSecurityProfileEnablingLabelURLProcessing(Item, URL, StandardProcessing)
	
	If URL = "int://sp-on" Then
		
		OpenForm(
			"DataProcessor.ExternalResourcePermissionSetup.Form.SecurityProfileSetup",
			,
			,
			,
			,
			,
			,
			FormWindowOpeningMode.LockWholeInterface);
		
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ObjectCommandsFormTableItemEventHandlers

&AtClient
Procedure ObjectCommandsQuickAccessPresentationStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	ChangeQuickAccess();
EndProcedure

&AtClient
Procedure ObjectCommandsQuickAccessPresentationClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure ObjectCommandsScheduledJobUseOnChange(Item)
	EditScheduledJob(False, True);
EndProcedure

&AtClient
Procedure ObjectCommandsScheduledJobPresentationStartChoice(Item, ChoiceData, StandardProcessing)
	EditScheduledJob(True, False);
EndProcedure

&AtClient
Procedure ObjectCommandsScheduledJobPresentationClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure ObjectCommandsSetUpQuickAccess(Command)
	ChangeQuickAccess();
EndProcedure

&AtClient
Procedure ObjectCommandsSetSchedule(Command)
	EditScheduledJob(True, False);
EndProcedure

&AtClient
Procedure ObjectCommandsBeforeAddRow(Item, Cancel, Clone, Parent, Group)
	Cancel = True;
EndProcedure

&AtClient
Procedure ObjectCommandsBeforeDelete(Item, Cancel)
	Cancel = True;
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure CommandWriteAndClose(Command)
	WriteAtClient(True);
EndProcedure

&AtClient
Procedure CommandWrite(Command)
	WriteAtClient(False);
EndProcedure

&AtClient
Procedure LoadFromFile(Command)
	UpdateFromFileStart();
EndProcedure

&AtClient
Procedure ExportToFile(Command)
	ExportParameters = New Structure;
	ExportParameters.Insert("IsReport", Object.Kind = ReportKind Or Object.Kind = KindAdditionalReport);
	ExportParameters.Insert("FileName", Object.FileName);
	ExportParameters.Insert("DataProcessorDataAddress", DataProcessorDataAddress);
	AdditionalReportsAndDataProcessorsClient.ExportToFile(ExportParameters);
EndProcedure

&AtClient
Procedure AdditionalReportOptionsOpen(Command)
	Option = ThisObject.Items.AdditionalReportOptions.CurrentData;
	If Option = Undefined Then
		ShowMessageBox(, NStr("en = 'Select report option.'"));
		Return;
	EndIf;
	
	AdditionalReportsAndDataProcessorsClient.OpenAdditionalReportOption(Object.Ref, Option.VariantKey);
EndProcedure

&AtClient
Procedure PlaceInSections(Command)
	OptionArray = New Array;
	For Each RowID In Items.AdditionalReportOptions.SelectedRows Do
		Option = AdditionalReportOptions.FindByID(RowID);
		If ValueIsFilled(Option.Ref) Then
			OptionArray.Add(Option.Ref);
		EndIf;
	EndDo;
	
	// Opening a dialog for assigning multiple report options to command interface sections
	If CommonUseClient.SubsystemExists("StandardSubsystems.ReportOptions") Then
		ReportOptionsModuleClient = CommonUseClient.CommonModule("ReportOptionsClient");
		ReportOptionsModuleClient.OpenOptionArrangeInSectionsDialog(OptionArray);
	EndIf;
EndProcedure

&AtClient
Procedure CommandPurposeFillingFormClick(Item, StandardProcessing)
	StandardProcessing = False;
	
	If Object.Kind = KindAdditionalReport Or Object.Kind = KindAdditionalDataProcessor Then
		// Selecting sections
		AvailableSections = SectionList(Object.Sections);
		
		FormParameters = New Structure;
		FormParameters.Insert("Sections",      AvailableSections);
		FormParameters.Insert("DataProcessorKind", Object.Kind);
		
		OpenForm("Catalog.AdditionalReportsAndDataProcessors.Form.PickSections", FormParameters, ThisObject);
	Else
		// Selecting metadata objects
		FormParameters = PrepareMetadataObjectSelectionFormParameters();
		OpenForm("CommonForm.MetadataObjectSelection", FormParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ObjectCommandsScheduledJobUse.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ObjectCommandsScheduledJobPresentation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Commands.ScheduledJobAllowed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("ReadOnly", True);

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Client

&AtClient
Procedure WriteAtClient(CloseAfterWrite)
	Requests = PermissionUpdateRequests();
	SafeModeClient.ApplyExternalResourceRequests(Requests, ThisObject, New NotifyDescription("ContinueWriteAtClient", ThisObject, CloseAfterWrite));
EndProcedure

&AtClient
Procedure ContinueWriteAtClient(Result, CloseAfterWrite)  Export
	
	WriteParameters = New Structure;
	WriteParameters.Insert("DataProcessorRegistration", DataProcessorRegistration);
	WriteParameters.Insert("CloseAfterWrite", CloseAfterWrite);
	
	Success = Write(WriteParameters);
	If Not Success Then
		Return;
	EndIf;
	
	If WriteParameters.DataProcessorRegistration Then
		RefreshReusableValues();
		Handler = New NotifyDescription("WriteAtClientEnd", ThisObject, WriteParameters);
		WarningText = NStr("en = 'To apply the changes to the open windows, close and reopen them.'");
		ShowMessageBox(Handler, WarningText);
	Else
		WriteAtClientEnd(WriteParameters);
	EndIf;
	
EndProcedure

&AtServer
Function PermissionUpdateRequests()
	
	Return AdditionalReportsAndDataProcessorsSafeModeInternal.AdditionalDataProcessorPermissionRequests(
		Object, GetPermissionTable());
	
EndFunction

&AtClient
Procedure WriteAtClientEnd(WriteParameters) Export
	If WriteParameters.CloseAfterWrite And IsOpen() Then
		Close();
	EndIf;
EndProcedure

&AtClient
Procedure UpdateFromFileStart()
	RegistrationParameters = New Structure;
	RegistrationParameters.Insert("Success", False);
	RegistrationParameters.Insert("DataProcessorDataAddress", DataProcessorDataAddress);
	RegistrationParameters.Insert("ResultHandler", New NotifyDescription("UpdateFromFileCompletion", ThisObject));
	Handler = New NotifyDescription("UpdateFromFileAfterSelectFile", ThisObject, RegistrationParameters);
	
	DialogParameters = New Structure("Mode, Filter, FilterIndex, Title");
	DialogParameters.Mode  = FileDialogMode.Open;
	DialogParameters.Filter = AdditionalReportsAndDataProcessorsClientServer.SelectingAndSavingDialogFilter();
	If Object.Ref.IsEmpty() Then
		DialogParameters.FilterIndex = 0;
		DialogParameters.Title = NStr("en = 'Select external report or data processor file'");
	ElsIf Object.Kind = KindAdditionalReport Or Object.Kind = ReportKind Then
		DialogParameters.FilterIndex = 1;
		DialogParameters.Title = NStr("en = 'Select external report file'");
	Else
		DialogParameters.FilterIndex = 2;
		DialogParameters.Title = NStr("en = 'Select external data processor file'");
	EndIf;
	
	AdditionalReportsAndDataProcessorsClient.ShowFilePutting(Handler, UUID, Object.FileName, DialogParameters);
EndProcedure

&AtClient
Procedure UpdateFromFileAfterSelectFile (PlacedFiles, RegistrationParameters) Export
	If PlacedFiles = Undefined Or PlacedFiles.Count() = 0 Then
		ExecuteNotifyProcessing(RegistrationParameters.ResultHandler, RegistrationParameters);
		Return;
	EndIf;
	
	FileDetails = PlacedFiles[0];
	
	Keys = New Structure("FileName, IsReport, DisablePublication, DisableConflicts, Conflicting");
	CommonUseClientServer.SupplementStructure(RegistrationParameters, Keys, False);
	
	RegistrationParameters.DisablePublication = False;
	RegistrationParameters.DisableConflicts = False;
	RegistrationParameters.Conflicting = New ValueList;
	
	SubstringArray = StringFunctionsClientServer.SplitStringIntoSubstringArray(FileDetails.Name, "\");
	RegistrationParameters.FileName = SubstringArray.Get(SubstringArray.UBound());
	FileExtention = Upper(Right(RegistrationParameters.FileName, 3));
	
	If FileExtention = "ERF" Then
		RegistrationParameters.IsReport = True;
	ElsIf FileExtention = "EPF" Then
		RegistrationParameters.IsReport = False;
	Else
		RegistrationParameters.Success = False;
		AdditionalReportsAndDataProcessorsClient.ReturnResultAfterShowWarning(
			NStr("en = 'The file extension does not match external report extension (ERF) or external data processor extension (EPF).'"),
			RegistrationParameters.ResultHandler,
			RegistrationParameters);
		Return;
	EndIf;
	
	RegistrationParameters.DataProcessorDataAddress = FileDetails.Location;
	
	UpdateFromFileClientMechanics(RegistrationParameters);
EndProcedure

&AtClient
Procedure UpdateFromFileClientMechanics(RegistrationParameters)
	// Preparing for server call
	ResultHandler = RegistrationParameters.ResultHandler;
	RegistrationParameters.Delete("ResultHandler");
	// Server call
	UpdateFromFileServerMechanics(RegistrationParameters);
	// Canceling changes
	RegistrationParameters.Insert("ResultHandler", ResultHandler);
	
	If RegistrationParameters.DisableConflicts Then
		// Multiple objects are disabled, which requires dynamic list refresh
		NotifyChanged(Type("CatalogRef.AdditionalReportsAndDataProcessors"));
	EndIf;
	
	// Processing server execution result 
	If RegistrationParameters.Success Then
		NotificationTitle = ?(RegistrationParameters.IsReport, NStr("en = 'External report file is imported'"), NStr("en = 'External data processor file is imported'"));
		NotificationRef    = ?(IsNew, "", GetURL(Object.Ref));
		NotificationText     = RegistrationParameters.FileName;
		ShowUserNotification(NotificationTitle, NotificationRef, NotificationText);
		ExecuteNotifyProcessing(RegistrationParameters.ResultHandler, RegistrationParameters);
	Else
		// Checking the reason of canceling data processor import and displaying the reason to the user
		If RegistrationParameters.ObjectNameUsed Then
			UpdateFromFileShowConflicts(RegistrationParameters);
		Else
			AdditionalReportsAndDataProcessorsClient.ReturnResultAfterShowWarning(
			    RegistrationParameters.BriefErrorDescription,
				RegistrationParameters.ResultHandler,
				RegistrationParameters);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure UpdateFromFileShowConflicts(RegistrationParameters)
	If RegistrationParameters.ConflictsCount > 1 Then
		If RegistrationParameters.IsReport Then
			QuestionTitle = NStr("en = 'External report import conflict'");
			QuestionText = NStr("en = 'Internal report name ""[Name]"" is not unique. It is used in [Count] reports: [List].
			|
			|Select one of the following:
			|1. ""[Continue]"" - import the report and disable it.
			|2. ""[Disable]"" - import the report and disable all other conflicting reports.
			|3. ""[Open]"" - do not import the report and open the list of conflicting reports.'");     
     DisableButtonPresentation = NStr("en = 'Disable conflicting reports'");
		Else
			QuestionTitle = NStr("en = 'External data processor import conflict'");
			QuestionText = NStr("en = 'Internal data processor name ""[Name]"" is not unique. It is used in [Count] data processors: [List].
			|
			|Select one of the following:
			|1. ""[Continue]"" - import the data processor and disable it.
			|2. ""[Disable]"" - import the data processor and disable all other conflicting data processors.
			|3. ""[Open]"" - do not import the data processor and open the list of conflicting data processors.'");
		  DisableButtonPresentation = NStr("en = 'Disable conflicting data processors'");
   EndIf;
		OpenButtonPresentation = NStr("en = 'Cancel and view conflicts'");
	Else
		If RegistrationParameters.IsReport Then
			QuestionTitle = NStr("en = 'External report import conflict'");
			QuestionText = NStr("en = 'Internal report name ""[Name]"" is not unique. It is used in [List] report.
			|
			|Select one of the following:
			|1. ""[Continue]"" - import the report and disable it.
			|2. ""[Disable]"" - import the report and disable the other report.
			|3. ""[Open]"" - do not import the report and open the form of the other report.'");
			DisableButtonPresentation = NStr("en = 'Disable conflicting report'");
		Else
			QuestionTitle = NStr("en = 'External data processor import conflict'");
			QuestionText = NStr("en = 'Internal data processor name ""[Name]"" is not unique. It is used in [List] data processor.
			|
			|Select one of the following:
			|1. ""[Continue]"" - import the data processor and disable it.
			|2. ""[Disable]"" - import the data processor and disable the other data processor.
			|3. ""[Open]"" - do not import the data processor and open the form of the other data processor.'");
			DisableButtonPresentation = NStr("en = 'Disable conflicting data processor'");
		EndIf;
		OpenButtonPresentation = NStr("en = 'Cancel and view conflict'");
	EndIf;
	ContinueButtonPresentation = NStr("en = 'Debug'");
	QuestionText = StrReplace(QuestionText, "[Name]",  RegistrationParameters.ObjectName);
	QuestionText = StrReplace(QuestionText, "[Count]", RegistrationParameters.ConflictsCount);
	QuestionText = StrReplace(QuestionText, "[List]",  RegistrationParameters.LockerPresentation);
	QuestionText = StrReplace(QuestionText, "[Disable]",  DisableButtonPresentation);
	QuestionText = StrReplace(QuestionText, "[Open]",     OpenButtonPresentation);
	QuestionText = StrReplace(QuestionText, "[Continue]", ContinueButtonPresentation);
	
	QuestionButtons = New ValueList;
	QuestionButtons.Add("ContinueWithoutPublishing", ContinueButtonPresentation);
	QuestionButtons.Add("DisableConflictingItems",   DisableButtonPresentation);
	QuestionButtons.Add("CancelAndOpen",             OpenButtonPresentation);
	QuestionButtons.Add(DialogReturnCode.Cancel);
	
	Handler = New NotifyDescription("UpdateFromFileConflictSolution", ThisObject, RegistrationParameters);
	
	ShowQueryBox(Handler, QuestionText, QuestionButtons, , "ContinueWithoutPublishing", QuestionTitle);
EndProcedure

&AtClient
Procedure UpdateFromFileConflictSolution(Answer, RegistrationParameters) Export
	If Answer = "ContinueWithoutPublishing" Then
		// Repeating server call (publishing in debug mode) and processing the result
		RegistrationParameters.DisablePublication = True;
		UpdateFromFileClientMechanics(RegistrationParameters);
	ElsIf Answer = "DisableConflictingItems" Then
		// Repeating server call (switching conflicting items to debug mode) and processing the result
		RegistrationParameters.DisableConflicts = True;
		UpdateFromFileClientMechanics(RegistrationParameters);
	ElsIf Answer = "CancelAndOpen" Then
		// Canceling and showing conflicting items.
		// The list is displayed when multiple conflicts are detected.
		ShowList = (RegistrationParameters.ConflictsCount > 1);
		If RegistrationParameters.StandardObjectName = RegistrationParameters.ObjectName And Not IsNew Then
			// And also when the current item is already recorded with a conflicting name.
			// The list includes two items: the current one and the conflicting one,
			// so that user can decide which item should be disabled.
			ShowList = True;
		EndIf;
		If ShowList Then // List form with a filter by conflicting items
			FormName = "Catalog.AdditionalReportsAndDataProcessors.ListForm";
			FormTitle = NStr("en = 'Additional reports and data processors with ""%1"" internal name'");
			FormTitle = StrReplace(FormTitle, "%1", RegistrationParameters.ObjectName);
			FormParameters = New Structure;
			FormParameters.Insert("Filter", New Structure);
			FormParameters.Filter.Insert("ObjectName", RegistrationParameters.ObjectName);
			FormParameters.Filter.Insert("IsFolder", False);
			FormParameters.Insert("Title", FormTitle);
			FormParameters.Insert("Representation", "List");
		Else // Item form
			FormName = "Catalog.AdditionalReportsAndDataProcessors.ObjectForm";
			FormParameters = New Structure;
			FormParameters.Insert("Key", RegistrationParameters.Conflicting[0].Value);
		EndIf;
		ExecuteNotifyProcessing(RegistrationParameters.ResultHandler, RegistrationParameters);
		OpenForm(FormName, FormParameters, Undefined, True);
	Else // Cancel
		ExecuteNotifyProcessing(RegistrationParameters.ResultHandler, RegistrationParameters);
	EndIf;
EndProcedure

&AtClient
Procedure UpdateFromFileCompletion(Result, AdditionalParameters) Export
	If Result.Success = False Then
		If ShowImportFromFileDialogOnOpen And IsOpen() Then
			Close();
		EndIf;
	ElsIf Result.Success = True Then
		If Not IsOpen() Then
			Open();
		EndIf;
		Modified = True;
		DataProcessorRegistration = True;
		DataProcessorDataAddress = Result.DataProcessorDataAddress;
	EndIf;
EndProcedure

&AtClient
Procedure OpenOption()
	Option = Items.AdditionalReportOptions.CurrentData;
	If Option = Undefined Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Option.Ref) Then
		ErrorText = NStr("en = '""%1"" report option is not registered.'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersInString(ErrorText, Option.Description);
		ShowMessageBox(, ErrorText);
	Else
		ShowValue(, Option.Ref);
	EndIf;
EndProcedure

&AtClient
Procedure EditScheduledJob(ChoiceMode = False, CheckBoxChanged = False)
	
	ItemCommand = Items.ObjectCommands.CurrentData;
	If ItemCommand = Undefined Then
		Return;
	EndIf;
	
	If ItemCommand.RunningVariant <> PredefinedValue("Enum.AdditionalDataProcessorCallMethods.ServerMethodCall")
		And ItemCommand.RunningVariant <> PredefinedValue("Enum.AdditionalDataProcessorCallMethods.ScenarioInSafeMode") Then
		ErrorText = NStr("en = 'Cannot use a command with ""%1"" startup option in scheduled jobs.'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersInString(ErrorText, String(ItemCommand.RunningVariant));
		ShowMessageBox(, ErrorText);
		If CheckBoxChanged Then
			ItemCommand.ScheduledJobUse = Not ItemCommand.ScheduledJobUse;
		EndIf;
		Return;
	EndIf;
	
	If CheckBoxChanged Then
		If Not ItemCommand.ScheduledJobUse Then
			ItemCommand.ScheduledJobPresentation = DisabledSchedulePresentation();
			Return;
		EndIf;
	EndIf;
	
	If ItemCommand.ScheduledJobSchedule.Count() > 0 Then
		CommandSchedule = ItemCommand.ScheduledJobSchedule.Get(0).Value;
	Else
		CommandSchedule = Undefined;
	EndIf;
	
	If TypeOf(CommandSchedule) <> Type("JobSchedule") Then
		CommandSchedule = New JobSchedule;
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemCommand", ItemCommand);
	Handler = New NotifyDescription("EditScheduledJobCompletion", ThisObject, AdditionalParameters);
	
	EditSchedule = New ScheduledJobDialog(CommandSchedule);
	EditSchedule.Show(Handler);
	
EndProcedure

&AtClient
Procedure EditScheduledJobCompletion(Schedule, AdditionalParameters) Export
	If Schedule = Undefined Then
		Return;
	EndIf;
	
	ItemCommand = AdditionalParameters.ItemCommand;
	ItemCommand.ScheduledJobSchedule.Clear();
	ItemCommand.ScheduledJobSchedule.Add(Schedule);
	ItemCommand.ScheduledJobPresentation = String(Schedule);
	
	If ItemCommand.ScheduledJobPresentation = BlankSchedulePresentation() Then
		ItemCommand.ScheduledJobPresentation = DisabledSchedulePresentation();
		ItemCommand.ScheduledJobUse = False;
		Modified = True;
	Else
		ItemCommand.ScheduledJobUse = True;
	EndIf;
EndProcedure

&AtClient
Procedure ChangeQuickAccess()
	ItemCommand = Items.ObjectCommands.CurrentData;
	If ItemCommand = Undefined Then
		Return;
	EndIf;
	
	Found = QuickAccess.FindRows(New Structure("CommandID", ItemCommand.ID));
	UsersWithQuickAccess = New ValueList;
	For Each TableRow In Found Do
		UsersWithQuickAccess.Add(TableRow.User);
	EndDo;
	
	FormParameters = New Structure;
	FormParameters.Insert("UsersWithQuickAccess", UsersWithQuickAccess);
	FormParameters.Insert("CommandPresentation",  ItemCommand.Presentation);
	
	ClientCache.Insert("CommandRowID", ItemCommand.GetID());
	OpenForm("Catalog.AdditionalReportsAndDataProcessors.Form.QuickAccessToAdditionalReportsAndDataProcessors", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure PermissionsOnClick(Item, EventData, StandardProcessing)
	
	StandardProcessing = False;
	
	Transition = EventData.Href;
	If Not IsBlankString(Transition) Then
		AttachIdleHandler("PermissionsOnClick_Attachable", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure PermissionsOnClick_Attachable()
	
	InternalProcessingKey = "internal:";
	
	If Transition = InternalProcessingKey + "home" Then
		
		GeneratePermissionList();
		
	ElsIf Left(Transition, StrLen(InternalProcessingKey)) = InternalProcessingKey Then
		
		GeneratePermissionPresentations(Right(Transition, StrLen(Transition) - StrLen(InternalProcessingKey)));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AdditionalReportOptionsBeforeDeleteCompletion(Answer, AdditionalParameters) Export
	If Answer = DialogReturnCode.Yes Then
		Option = AdditionalParameters.Option;
		DeleteAdditionalReportOption("ExternalReport." + Object.ObjectName, Option.VariantKey);
		AdditionalReportOptions.Delete(Option);
	EndIf;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Client, Server

&AtClientAtServerNoContext
Function BlankSchedulePresentation()
	Return String(New JobSchedule);
EndFunction

&AtClientAtServerNoContext
Function DisabledSchedulePresentation()
	Return NStr("en = 'Schedule is not specified'");
EndFunction

&AtClientAtServerNoContext
Function UserQuickAccessPresentation(UserCount)
	If UserCount = 0 Then
		Return NStr("en = 'None'");
	EndIf;
	
  If UserCount = 1 Then
		QuickAccessPresentation = NStr("en = '1 user'");
	Else
		QuickAccessPresentation = NStr("en = '%1 users'");
	EndIf;
 //Raise("CHECK ON TEST");
 
	
	QuickAccessPresentation = StringFunctionsClientServer.SubstituteParametersInString(
		QuickAccessPresentation, 
		Format(UserCount, "NG=0"));
	
	Return QuickAccessPresentation;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Server call, Server

&AtServer
Procedure UpdateFromFileServerMechanics(RegistrationParameters)
	CatalogObject = FormAttributeToValue("Object");
	SavedCommands = CatalogObject.Commands.Unload();
	
	RegistrationResult = AdditionalReportsAndDataProcessors.RegisterDataProcessor(CatalogObject, RegistrationParameters);
	
	PermissionAddress = PutToTempStorage(CatalogObject.Permissions.Unload(), ThisObject.UUID);
	ValueToFormAttribute(CatalogObject, "Object");
	
	CommonUseClientServer.SupplementStructure(RegistrationParameters, RegistrationResult, True);
	
	If RegistrationParameters.Success Then
		FillCommands(SavedCommands);
	ElsIf RegistrationParameters.ObjectNameUsed Then
		// Locker object presentation.
		LockerPresentation = "";
		For Each ListItem In RegistrationParameters.Conflicting Do
			LockerPresentation = LockerPresentation 
			+ ?(LockerPresentation = "", "", ", ")
			+ TrimAll(ListItem.Presentation);
			If StrLen(LockerPresentation) > 80 Then
				LockerPresentation = Left(LockerPresentation, 70) + "... ";
				Break;
			EndIf;
		EndDo;
		RegistrationParameters.Insert("LockerPresentation", LockerPresentation);
		// Number of locker objects.
		RegistrationParameters.Insert("ConflictsCount", RegistrationParameters.Conflicting.Count());
	EndIf;
	
	SetVisibilityAvailability(True);
EndProcedure

&AtServer
Function PrepareMetadataObjectSelectionFormParameters()
	FilterByMetadataObjects = New ValueList;
	If Object.Kind = Enums.AdditionalReportAndDataProcessorKinds.ObjectFilling Then
		CommonCommand = Metadata.CommonCommands.ObjectFilling;
	ElsIf Object.Kind = Enums.AdditionalReportAndDataProcessorKinds.Report Then
		CommonCommand = Metadata.CommonCommands.ObjectReports;
	ElsIf Object.Kind = Enums.AdditionalReportAndDataProcessorKinds.PrintForm Then
		CommonCommand = Metadata.CommonCommands.AdditionalObjectPrintForms;
	ElsIf Object.Kind = Enums.AdditionalReportAndDataProcessorKinds.RelatedObjectCreation Then
		CommonCommand = Metadata.CommonCommands.RelatedObjectCreation;
	EndIf;
	For Each CommandParameterType In CommonCommand.CommandParameterType.Types() Do
		FilterByMetadataObjects.Add(Metadata.FindByType(CommandParameterType).FullName());
	EndDo;
	
	SelectedMetadataObjects = New ValueList;
	For Each PurposeItem In Object.Purpose Do
		If Not PurposeItem.TargetObject.DeletionMark Then
			SelectedMetadataObjects.Add(PurposeItem.TargetObject.FullName);
		EndIf;
	EndDo;
	
	FormParameters = New Structure;
	FormParameters.Insert("FilterByMetadataObjects", FilterByMetadataObjects);
	FormParameters.Insert("SelectedMetadataObjects", SelectedMetadataObjects);
	FormParameters.Insert("Title", NStr("en = 'Additional data processor purpose'"));
	
	Return FormParameters;
EndFunction

&AtServer
Procedure ImportSelectedMetadataObjects(Parameter)
	Object.Purpose.Clear();
	
	For Each ParameterItem In Parameter Do
		MetadataObject = Metadata.FindByFullName(ParameterItem.Value);
		If MetadataObject = Undefined Then
			Continue;
		EndIf;
		PurposeRow = Object.Purpose.Add();
		PurposeRow.TargetObject = CommonUse.MetadataObjectID(MetadataObject);
	EndDo;
	
	Modified = True;
	SetVisibilityAvailability();
EndProcedure

&AtServerNoContext
Procedure DeleteAdditionalReportOption(ObjectKey, VariantKey)
	SettingsStorages["ReportVariantsStorage"].Delete(ObjectKey, VariantKey, Undefined);
EndProcedure

&AtServer
Procedure SetVisibilityAvailability(Registration = False)
	
	If Not Registration And Not IsNew And Object.Kind = KindAdditionalReport Then
		AdditionalReportOptionsFill();
	Else
		AdditionalReportOptions.Clear();
	EndIf;
	
	IsGlobalDataProcessor = (Object.Kind = KindAdditionalDataProcessor Or Object.Kind = KindAdditionalReport);
	IsReport = (Object.Kind = KindAdditionalReport Or Object.Kind = ReportKind);
	
	VariantCount = AdditionalReportOptions.Count();
	CommandCount = Object.Commands.Count();
	VisibleTabNumber = 1;
	
	If Object.Kind = KindAdditionalReport And Object.UseOptionStorage Then
		
		VisibleTabNumber = VisibleTabNumber + 1;
		
		Items.PagesOptions.Visible = True;
		
		If Registration Or VariantCount = 0 Then
			Items.PagesOptions.CurrentPage = Items.OptionsHideToWrite;
			Items.PageOptions.Title = NStr("en = 'Report options'");
		Else
			Items.PagesOptions.CurrentPage = Items.OptionsShow;
			Items.PageOptions.Title = StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Report options (%1)'"),
				Format(VariantCount, "NG="));
		EndIf;
	Else
		Items.PagesOptions.Visible = False;
	EndIf;
	
	If CommandCount = 0 Then
		
		Items.PageCommands.Visible = False;
		Items.PageCommands.Title = NStr("en = 'Commands'");
		
	Else
		
		VisibleTabNumber = VisibleTabNumber + 1;
		
		Items.PageCommands.Visible = True;
		Items.PageCommands.Title = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Commands (%1)'"),
			Format(CommandCount, "NG="));
		
	EndIf;
	
	PermissionCount = GetPermissionTable().Count();
	PermissionCompatibilityMode = Object.PermissionCompatibilityMode;
	
	If PermissionCompatibilityMode = Enums.AdditionalReportsAndDataProcessorsPermissionCompatibilityModes.Version_2_1_3 Then
		SafeModeVar = Object.SafeMode;
		If SafeModeVar And PermissionCount > 0 And GetFunctionalOption("UseSecurityProfiles") Then
			If IsNew Then
				SafeModeVar = "";
			Else
				SafeModeVar = SafeModeInternal.ExternalModuleAttachingMode(Object.Ref);
			EndIf;
		EndIf;
	Else
		If PermissionCount = 0 Then
			SafeModeVar = True;
		Else
			If GetFunctionalOption("UseSecurityProfiles") Then
				If IsNew Then
					SafeModeVar = "";
				Else
					SafeModeVar = SafeModeInternal.ExternalModuleAttachingMode(Object.Ref);
				EndIf;
			Else
				SafeModeVar = False;
			EndIf;
		EndIf;
	EndIf;
	
	If PermissionCount = 0 Then
		
		Items.PermissionsPage.Visible = False;
		Items.GroupSafeModeGlobal.Visible = True;
		
		If SafeModeVar = True Then
			Items.PagesSafeModeGlobal.CurrentPage = Items.PageSafeModeTrue;
		ElsIf SafeModeVar = False Then
			Items.PagesSafeModeGlobal.CurrentPage = Items.PageSafeModeFalse;
		Else
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Invalid attachment mode for additional reports or data processors that do not require permissions to use security profiles: %1.'"),
				SafeModeVar);
		EndIf;
		
		Items.GroupSecurityProfileEnabling.Visible = False;
		
	Else
		
		VisibleTabNumber = VisibleTabNumber + 1;
		
		Items.PagesOptionsPermissionCommands.CurrentPage = Items.PermissionsPage;
		Items.PermissionsPage.Visible = True;
		Items.PermissionsPage.Title = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Permissions (%1)'"),
			Format(PermissionCount, "NG="));
		
		Items.GroupSafeModeGlobal.Visible = False;
		
		If PermissionCompatibilityMode = Enums.AdditionalReportsAndDataProcessorsPermissionCompatibilityModes.Version_2_1_3 Then
			Items.GroupPagesPermissionCompatibilityModes.CurrentPage = Items.PagePermissionsVersion_2_1_3;
		Else
			Items.GroupPagesPermissionCompatibilityModes.CurrentPage = Items.PagePermissionsVersion_2_2_2;
		EndIf;
		
		If SafeModeVar = True Then
			Items.PagesSafeModeWithPermissions.CurrentPage = Items.PageSafeModeWithPermissions;
		ElsIf SafeModeVar = False Then
			Items.PagesSafeModeWithPermissions.CurrentPage = Items.PageUnsafeModeWithPermissions;
		ElsIf TypeOf(SafeModeVar) = Type("String") Then
			Items.PagesSafeModeWithPermissions.CurrentPage = Items.PagePersonalSecurityProfile;
			Items.DecorationPersonalSecurityProfileLabel.Title = StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Additional report or data processor will be attached with %1 security profile,
                  |which allows only the following operations:'"), SafeModeVar);
		Else
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Invalid attachment mode for additional reports or data processors that require permissions to use security profiles: %1.'"),
				SafeModeVar);
		EndIf;
		
		If SafeModeVar = False And Not GetFunctionalOption("UseSecurityProfiles") And SafeModeInternal.CanSetUpSecurityProfiles() Then
			Items.GroupSecurityProfileEnabling.Visible = True;
		Else
			Items.GroupSecurityProfileEnabling.Visible = False;
		EndIf;
		
		GeneratePermissionList();
		
	EndIf;
	
	Items.PagesOptionsPermissionCommands.PagesRepresentation = FormPagesRepresentation[?(VisibleTabNumber > 1, "TabsOnTop", "None")];
	
	If IsGlobalDataProcessor Then
		If Object.Sections.Count() = 0 Then
			PurposePresentation = NStr("en = 'Undefined'");
		Else
			PurposePresentation = "";
			For Each SectionRow In Object.Sections Do
				If PurposePresentation <> "" Then
					PurposePresentation = PurposePresentation + ", ";
				EndIf;
				PurposePresentation = PurposePresentation + AdditionalReportsAndDataProcessors.SectionPresentation(SectionRow.Section);
			EndDo;
		EndIf;
	Else
		If Object.Purpose.Count() = 0 Then
			PurposePresentation = NStr("en = 'Undefined'");
		Else
			PurposePresentation = "";
			For Each PurposeRow In Object.Purpose Do
				If PurposePresentation <> "" Then
					PurposePresentation = PurposePresentation + ", ";
				EndIf;
				PurposePresentation = PurposePresentation + String(PurposeRow.TargetObject);
			EndDo;
		EndIf;
	EndIf;
	
	Items.ObjectCommandsQuickAccessPresentation.Visible  = IsGlobalDataProcessor;
	Items.ObjectCommandsSetUpQuickAccess.Visible         = IsGlobalDataProcessor;
	Items.ObjectCommandsScheduledJobPresentation.Visible = IsGlobalDataProcessor;
	Items.ObjectCommandsScheduledJobUse.Visible          = IsGlobalDataProcessor;
	Items.ObjectCommandsSetSchedule.Visible              = IsGlobalDataProcessor;
	Items.CommandArrange.Visible                        = IsGlobalDataProcessor;
	Items.CommandPurpose.Visible                        = Not IsGlobalDataProcessor;
	Items.FormTypes.Visible                             = Not IsGlobalDataProcessor;
	
	If IsNew Then
		Title = ?(IsReport, NStr("en = 'Additional report (create)'"), NStr("en = 'Additional data processor (create)'"));
	Else
		Title = Object.Description + " " + ?(IsReport, NStr("en = '(Additional report)'"), NStr("en = '(Additional data processor)'"));
	EndIf;
	
	If VariantCount > 0 Then
		
		OutputTableTitle = VisibleTabNumber <= 1 And Object.Kind = KindAdditionalReport And Object.UseOptionStorage;
		
		Items.AdditionalReportOptions.TitleLocation = FormItemTitleLocation[?(OutputTableTitle, "Top", "None")];
		Items.AdditionalReportOptions.Header          = Not OutputTableTitle;
		Items.AdditionalReportOptions.HorizontalLines = Not OutputTableTitle;
		
	EndIf;
	
	If CommandCount > 0 Then
		
		OutputTableTitle = VisibleTabNumber <= 1 And Not IsGlobalDataProcessor;
		
		Items.ObjectCommands.TitleLocation = FormItemTitleLocation[?(OutputTableTitle, "Top", "None")];
		Items.ObjectCommands.Header          = Not OutputTableTitle;
		Items.ObjectCommands.HorizontalLines = Not OutputTableTitle;
		
	EndIf;
	
	WindowOptionsKey = AdditionalReportsAndDataProcessors.KindToString(Object.Kind);
	
EndProcedure

&AtServer
Procedure GeneratePermissionPresentations(Val PermissionKind)
	
	PermissionTable = GetPermissionTable();
	PermissionRow = PermissionTable.Find(PermissionKind, "PermissionKind");
	If PermissionRow <> Undefined Then
		PermissionParameters = PermissionRow.Parameters.Get();
		PermissionPresentations_2_1_3 = AdditionalReportsAndDataProcessorsSafeModeInternal.GenerateDetailedPermissionDetails(
			PermissionKind, PermissionParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure GeneratePermissionList()
	
	If Object.PermissionCompatibilityMode = Enums.AdditionalReportsAndDataProcessorsPermissionCompatibilityModes.Version_2_1_3 Then
		PermissionPresentations_2_1_3 = AdditionalReportsAndDataProcessorsSafeModeInternal.GeneratePermissionPresentation(
			GetPermissionTable());
	ElsIf Object.PermissionCompatibilityMode = Enums.AdditionalReportsAndDataProcessorsPermissionCompatibilityModes.Version_2_2_2 Then
		PermissionPresentations_2_2_2 = SafeModeInternal.ExternalResourcePermissionPresentation(
			GetPermissionTables());
	EndIf;
	
EndProcedure

&AtServerNoContext
Function SectionList(Val Sections)
	
	AvailableSections = New ValueList;
	
	Query = New Query;
	Query.Text =  "SELECT
	                |	Sections.Section
	                |INTO Sections
	                |FROM
	                |	&Sections AS Sections
	                |;
	                |
	                |////////////////////////////////////////////////////////////////////////////////
	                |SELECT
	                |	ISNULL(MetadataObjectIDs.Ref, VALUE(Catalog.MetadataObjectIDs.EmptyRef)) AS Ref,
	                |	MetadataObjectIDs.DeletionMark
	                |FROM
	                |	Sections AS Sections
	                |		LEFT JOIN Catalog.MetadataObjectIDs AS MetadataObjectIDs
	                |		ON Sections.Section = MetadataObjectIDs.Ref
	                |WHERE
	                |	MetadataObjectIDs.DeletionMark = FALSE";

	Query.SetParameter("Sections", Sections.Unload(, "Section"));
	QueryResult = Query.Execute().Select();
	
	While QueryResult.Next() Do
		AvailableSections.Add(QueryResult.Ref);
	EndDo;
	
	Return AvailableSections;
EndFunction


////////////////////////////////////////////////////////////////////////////////
// Server

&AtServer
Procedure FillCommands(SavedCommands = Undefined)
	
	Object.Commands.Sort("Presentation");
	
	For Each ItemCommand In Object.Commands Do
		If Object.Kind = KindAdditionalDataProcessor Or Object.Kind = KindAdditionalReport Then
			Found = QuickAccess.FindRows(New Structure("CommandID", ItemCommand.ID));
			ItemCommand.QuickAccessPresentation = UserQuickAccessPresentation(
				Found.Count());
		EndIf;
		
		ItemCommand.ScheduledJobUse = False;
		ItemCommand.ScheduledJobAllowed = False;
		
		If Object.Kind = KindAdditionalDataProcessor
			And (ItemCommand.RunningVariant = Enums.AdditionalDataProcessorCallMethods.ServerMethodCall
			Or ItemCommand.RunningVariant = Enums.AdditionalDataProcessorCallMethods.ScenarioInSafeMode) Then
			
			ItemCommand.ScheduledJobAllowed = True;
			
			ScheduledJobGUID = ItemCommand.ScheduledJobGUID;
			If SavedCommands <> Undefined Then
				FoundRow = SavedCommands.Find(ItemCommand.ID, "ID");
				If FoundRow <> Undefined Then
					ScheduledJobGUID = FoundRow.ScheduledJobGUID;
				EndIf;
			EndIf;
			
			If ValueIsFilled(ScheduledJobGUID) Then
				ScheduledJob = AdditionalReportsAndDataProcessorsScheduledJobs.FindJob(ScheduledJobGUID);
				
				If ScheduledJob <> Undefined Then
					
					JobParameters = AdditionalReportsAndDataProcessorsScheduledJobs.GetJobParameters(ScheduledJob);
					
					ItemCommand.ScheduledJobGUID = ScheduledJobGUID;
					ItemCommand.ScheduledJobPresentation = String(JobParameters.Schedule);
					ItemCommand.ScheduledJobUse = JobParameters.Use;
					ItemCommand.ScheduledJobSchedule.Insert(0, JobParameters.Schedule);
					
					If ItemCommand.ScheduledJobPresentation = BlankSchedulePresentation() Then
						ItemCommand.ScheduledJobUse = False;
					EndIf;
					
				EndIf;
			EndIf;
			
			If Not ItemCommand.ScheduledJobUse Then
				ItemCommand.ScheduledJobPresentation = DisabledSchedulePresentation();
			EndIf;
		Else
			ItemCommand.ScheduledJobPresentation = StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Not applicable to commands with ""%1"" startup option'"),
				String(ItemCommand.RunningVariant));
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure AdditionalReportOptionsFill()
	AdditionalReportOptions.Clear();
	
	Try
		ExternalObject = AdditionalReportsAndDataProcessors.GetExternalDataProcessorsObject(Object.Ref);
	Except
		ErrorText = NStr("en = 'Cannot get the list of report options due to report attachment error:'");
		Message = New UserMessage;
		Message.Text = ErrorText + Chars.LF + DetailErrorDescription(ErrorInfo());
		Message.Message();
		Return;
	EndTry;
	
	If CommonUse.SubsystemExists("StandardSubsystems.ReportOptions") Then
		ReportOptionsModule = CommonUse.CommonModule("ReportOptions");
		
		ReportMetadata = ExternalObject.Metadata();
		DCSchemaMetadata = ReportMetadata.MainDataCompositionSchema;
		If DCSchemaMetadata <> Undefined Then
			DCSchema = ExternalObject.GetTemplate(DCSchemaMetadata.Name);
			For Each DCSettingsVariant In DCSchema.SettingVariants Do
				VariantKey = DCSettingsVariant.Name;
				OptionRef = ReportOptionsModule.GetRef(Object.Ref, VariantKey);
				If OptionRef <> Undefined Then
					Option = AdditionalReportOptions.Add();
					Option.VariantKey = VariantKey;
					Option.Description = DCSettingsVariant.Presentation;
					Option.Custom = False;
					Option.PictureIndex = 5;
					Option.Ref = OptionRef;
				EndIf;
			EndDo;
		Else
			VariantKey = "";
			OptionRef = ReportOptionsModule.GetRef(Object.Ref, VariantKey);
			If OptionRef <> Undefined Then
				Option = AdditionalReportOptions.Add();
				Option.VariantKey = VariantKey;
				Option.Description = ReportMetadata.Presentation();
				Option.Custom = False;
				Option.PictureIndex = 5;
				Option.Ref = OptionRef;
			EndIf;
		EndIf;
	Else
		ReportOptionsModule = Undefined;
	EndIf;
	
	If Object.UseOptionStorage Then
		Storage = SettingsStorages["ReportVariantsStorage"];
		ObjectKey = Object.Ref;
	Else
		Storage = ReportsVariantsStorage;
		ObjectKey = "ExternalReport." + Object.ObjectName;
	EndIf;
	
	SettingsList = Storage.GetList(ObjectKey);
	
	For Each ListItem In SettingsList Do
		Option = AdditionalReportOptions.Add();
		Option.VariantKey = ListItem.Value;
		Option.Description = ListItem.Presentation;
		Option.Custom = True;
		Option.PictureIndex = 3;
		If ReportOptionsModule <> Undefined Then
			Option.Ref = ReportOptionsModule.GetRef(Object.Ref, Option.VariantKey);
		EndIf;
	EndDo;
EndProcedure

&AtServer
Function GetPermissionTable()
	
	Return GetFromTempStorage(PermissionAddress);
	
EndFunction

&AtServer
Function GetPermissionTables()
	
	Managers = DataProcessors.ExternalResourcePermissionSetup.PermissionRegisterManagers();
	Result = DataProcessors.ExternalResourcePermissionSetup.PermissionTables();
	
	SourceTable = GetPermissionTable();
	For Each SourceTableRow In SourceTable Do
		
		Set = Undefined;
		For Each Manager In Managers Do
			If Manager.PermissionPresentationXDTOType().Name = SourceTableRow.PermissionKind Then
				XDTOPresentations = New Array();
				XDTOPresentations.Add(SourceTableRow.Parameters.Get());
				Set = Manager.RecordSetFromPresentationXDTO(XDTOPresentations, True, Object.Ref, False);
			EndIf;
		EndDo;
		
		If Set = Undefined Then
			Raise NStr("en = 'Unknown permission type.'");
		EndIf;
		
		ResultTable = Result[SourceTableRow.PermissionKind];
		
		For Each SetRow In Set Do
			
			ResultPermission = ResultTable.Add();
			FillPropertyValues(ResultPermission, SetRow);
			
		EndDo;
		
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion
