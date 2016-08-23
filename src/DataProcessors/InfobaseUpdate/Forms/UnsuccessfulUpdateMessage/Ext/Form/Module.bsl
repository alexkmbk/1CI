
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("Autotest") Then
		Return;
	EndIf;
	
	WriteLogEvent(InfobaseUpdate.EventLogMessageText(), EventLogLevel.Error,
		, , Parameters.DetailedErrorMessage);
	
	ErrorMessageText = StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en = 'Error occurred when updating the application:
		           |
		           |%1'"),
		Parameters.BriefErrorMessage);
	
	Items.ErrorMessageText.Title = ErrorMessageText;
	
	UpdateStartTime = Parameters.UpdateStartTime;
	If Parameters.UpdateEndTime = Undefined Then
		UpdateEndTime = CurrentSessionDate();
	Else
		UpdateEndTime = Parameters.UpdateEndTime;
	EndIf;
	
	If Not Users.InfobaseUserWithFullAccess(, True) Then
		Items.OpenExternalDataProcessorForm.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemEventHandlers

&AtClient
Procedure ShowUpdateResultDetailsClick(Item)
	
	SessionTimeOffset = StandardSubsystemsClientCached.ClientParameters().SessionTimeOffset;
	
	FormParameters = New Structure;
	FormParameters.Insert("StartDate", UpdateStartTime - SessionTimeOffset);
	FormParameters.Insert("EndDate", UpdateEndTime - SessionTimeOffset);
	FormParameters.Insert("ExecuteNotInBackground", True);
	
	OpenForm("DataProcessor.EventLog.Form.EventLog", FormParameters);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ExitApplication(Command)
	Close(True);
EndProcedure

&AtClient
Procedure RestartApplication(Command)
	Close(False);
EndProcedure

&AtClient
Procedure OpenExternalDataProcessor(Command)
	
#If WebClient Then
	Notification = New NotifyDescription("OpenExternalDataProcessorWithoutExtension", ThisObject);
	BeginPutFile(Notification,,, True, UUID);
	Return;
#EndIf
	
	FileDialog = New FileDialog(FileDialogMode.Open);
	FileDialog.Filter = NStr("en = 'External data processor'") + "(*.epf)|*.epf";
	FileDialog.Multiselect = False;
	FileDialog.Title = NStr("en = 'Select external data processor'");
	If FileDialog.Choose() Then
		SelectedDataProcessor = New BinaryData(FileDialog.FullFileName);
		AddressInTempStorage = PutToTempStorage(SelectedDataProcessor, UUID);
		ExternalDataProcessorsName = AttachExternalDataProcessor(AddressInTempStorage);
		OpenForm(ExternalDataProcessorsName + ".Form");
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenExternalDataProcessorWithoutExtension(Result, Address, SelectedFileName, AdditionalParameters) Export
	
	If Result Then
		ExternalDataProcessorsName = AttachExternalDataProcessor(Address);
		OpenForm(ExternalDataProcessorsName + ".Form",, ThisObject,,,,, FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtServer
Function AttachExternalDataProcessor(AddressInTempStorage)
	If Not Users.InfobaseUserWithFullAccess(, True) Then
		Raise NStr("en = 'Limited access rights.'");
	EndIf;
	SelectedDataProcessor = GetFromTempStorage(AddressInTempStorage);
	TempFileName = GetTempFileName("epf");
	SelectedDataProcessor.Write(TempFileName);
	Return ExternalDataProcessors.Create(TempFileName, False).Metadata().FullName();
EndFunction

#EndRegion
