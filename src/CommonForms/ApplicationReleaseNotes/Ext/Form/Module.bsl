#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skipping the initialization to guarantee that the form will be received if the Autotest parameter is passed.
	If Parameters.Property("Autotest") Then 
		Return;
	EndIf;
	
	If Not Parameters.ShowOnlyChanges Then
		Items.FormAddressInApplication.Visible = False;
	EndIf;
	
	Title = NStr("en = 'What's new in %1'");
	Title = StringFunctionsClientServer.SubstituteParametersInString(Title, Metadata.Synonym);
	
	If ValueIsFilled(Parameters.UpdateStartTime) Then
		UpdateStartTime = Parameters.UpdateStartTime;
		UpdateEndTime = Parameters.UpdateEndTime;
	EndIf;
	
	Sections = InfobaseUpdateInternal.NotShownUpdateDetailSections();
	LastVersion = CommonUse.CommonSettingsStorageLoad(" InfobaseUpdate",
		"SystemChangesDisplayLastVersion", , , UserName());
	
	If Sections.Count() = 0 Then
		UpdateDetailsDocument = Metadata.CommonTemplates.Find("ApplicationReleaseNotes");
		If UpdateDetailsDocument <> Undefined
			And (LastVersion = Undefined
				Or Not Parameters.ShowOnlyChanges) Then
			UpdateDetailsDocument = GetCommonTemplate(UpdateDetailsDocument);
		Else
			UpdateDetailsDocument = New SpreadsheetDocument();
		EndIf;
	Else
		UpdateDetailsDocument = InfobaseUpdateInternal.UpdateDetailsDocument(Sections);
	EndIf;

	If UpdateDetailsDocument.TableHeight = 0 Then
		Text = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'The application is updated to version %1'"), Metadata.Version);
		UpdateDetailsDocument.Area("R1C1:R1C1").Text = Text;
	EndIf;
	
	SubsystemDescriptions = StandardSubsystemsCached.SubsystemDescriptions();
	For Each SubsystemName In SubsystemDescriptions.Order Do
		SubsystemDetails = SubsystemDescriptions.ByNames.Get(SubsystemName);
		If Not ValueIsFilled(SubsystemDetails.MainServerModule) Then
			Continue;
		EndIf;
		Module = CommonUse.CommonModule(SubsystemDetails.MainServerModule);
		Module.OnPrepareUpdateDetailsTemplate(UpdateDetailsDocument);
	EndDo;
	InfobaseUpdateOverridable.OnPrepareUpdateDetailsTemplate(UpdateDetailsDocument);
	
	UpdateDetails.Clear();
	UpdateDetails.Put(UpdateDetailsDocument);
	
	UpdateDetailsStruct = InfobaseUpdateInternal.InfobaseUpdateDetails();
	UpdateStartTime = UpdateDetailsStruct.UpdateStartTime;
	UpdateEndTime = UpdateDetailsStruct.UpdateEndTime;
	
	If Not CommonUseCached.CanUseSeparatedData()
		Or UpdateDetailsStruct.DeferredUpdateCompletedSuccessfully <> Undefined
		Or UpdateDetailsStruct.HandlerTree <> Undefined
			And UpdateDetailsStruct.HandlerTree.Rows.Count() = 0 Then
		Items.DeferredUpdate.Visible = False;
	EndIf;
	
	If CommonUse.FileInfobase() Then
		MessageTitle = NStr("en = 'Additional data processing required'");
		Items.DeferredDataUpdate.Title = MessageTitle;
	EndIf;
	
	If Not Users.InfobaseUserWithFullAccess(, True) Then
		Items.DeferredDataUpdate.Title =
			NStr("en = 'Additional data processing procedures are not executed'");
		Items.DeferredDataUpdateExplanation.Title = 
			NStr("en = 'Some operations are temporarily unavailable as the migration to the new version is not yet completed.'");
	EndIf;
	
	If Not ValueIsFilled(UpdateStartTime) And Not ValueIsFilled(UpdateEndTime) Then
		Items.TechnicalInformationOnUpdateResult.Visible = False;
	ElsIf Users.InfobaseUserWithFullAccess() And Not CommonUseCached.DataSeparationEnabled() Then
		Items.FormAddressInApplication.TitleHeight = 2;
		Items.TechnicalInformationOnUpdateResult.Visible = True;
	Else
		Items.TechnicalInformationOnUpdateResult.Visible = False;
	EndIf;
	
	ClientServerInfobase = Not CommonUse.FileInfobase();
	
	// Displaying the information that scheduled jobs are disabled.
	If Not ClientServerInfobase
		And Users.InfobaseUserWithFullAccess(, True) Then
		ClientLaunchParameter = SessionParameters.ClientParametersOnServer.Get("LaunchParameter");
		ScheduledJobsDisabledDone = Find(ClientLaunchParameter, "ScheduledJobsDisabled") <> 0;
		If Not ScheduledJobsDisabledDone Then
			Items.ScheduledJobsDisabledGroup.Visible = False;
		EndIf;
	Else
		Items.ScheduledJobsDisabledGroup.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose()
	
	WriteCurrentSettings();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If ClientServerInfobase Then
		AttachIdleHandler("UpdateDeferredUpdateStatus", 60);
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemEventHandlers

&AtClient
Procedure UpdateDetailsChoice(Item, Area, StandardProcessing)
	
	If Find(Area.Text, "http://") = 1 Or Find(Area.Text, "https://") = 1 Then
		GotoURL(Area.Text);
	EndIf;
	
	InfobaseUpdateClientOverridable.OnClickUpdateDetailsDocumentHyperlink(Area);
	
EndProcedure

&AtClient
Procedure ShowUpdateResultDetailsClick(Item)
	
	FormParameters = New Structure;
	FormParameters.Insert("ShowErrorsAndWarnings", True);
	FormParameters.Insert("StartDate", UpdateStartTime);
	FormParameters.Insert("EndDate", UpdateEndTime);
	
	OpenForm("DataProcessor.EventLog.Form.EventLog", FormParameters);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure DeferredDataUpdate(Command)
	OpenForm("DataProcessor.InfobaseUpdate.Form.DeferredInfobaseUpdateProgressIndicator");
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServerNoContext
Procedure WriteCurrentSettings()
	
	InfobaseUpdateInternal.SetDisplayDetailsToCurrentVersionFlag();
	
EndProcedure

&AtClient
Procedure  UpdateDeferredUpdateStatus()
	
	 UpdateDeferredUpdateStatusAtServer();
	
EndProcedure

&AtServer
Procedure  UpdateDeferredUpdateStatusAtServer()
	
	UpdateDetails = InfobaseUpdateInternal.InfobaseUpdateDetails();
	If UpdateDetails.DeferredUpdateEndTime <> Undefined Then
		Items.DeferredUpdate.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure ScheduledJobsDisabledURLProcessing(Item, URL, StandardProcessing)
	StandardProcessing = False;
	
	Notification = New NotifyDescription("ScheduledJobsDisabledURLProcessingCompletion", ThisObject);
	QuestionText = NStr("en = 'Restart the application?'");
	ShowQueryBox(Notification, QuestionText, QuestionDialogMode.YesNo,, DialogReturnCode.No);
EndProcedure

&AtClient
Procedure ScheduledJobsDisabledURLProcessingCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		NewLaunchParameter = StrReplace(LaunchParameter, "ScheduledJobsDisabled", "");
		NewLaunchParameter = StrReplace(NewLaunchParameter, "StartInfobaseUpdate", "");
		NewLaunchParameter = "/C """ + NewLaunchParameter + """";
		Terminate(True, NewLaunchParameter);
	EndIf;
	
EndProcedure

#EndRegion
