&AtClient
Var ContinuationParameters;

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("Autotest") Then
		Return;
	EndIf;
	
	InfobaseVersionUpdateInProgress = True;
	UpdateStartTime = CurrentSessionDate();
	
	ProgressStepBeginning = 5;
	ProgressStepLength  = 5;
	ExecutionProgress = ProgressStepBeginning;
	
	DataUpdateMode = InfobaseUpdateInternal.DataUpdateMode();
	
	UpdateApplicationParametersOnly =
		Not InfobaseUpdate.InfobaseUpdateRequired();
	
	If UpdateApplicationParametersOnly Then
		Title = NStr("en = 'Application parameters update'");
		Items.RunMode.CurrentPage = Items.ApplicationParametersUpdate;
		ProgressStepLength = 95;
		
	ElsIf DataUpdateMode = "InitialFilling" Then
		Title = NStr("en = 'Filling initial data'");
		Items.RunMode.CurrentPage = Items.InitialFilling;
		
	ElsIf DataUpdateMode = "MigrationFromAnotherApplication" Then
		Title = NStr("en = 'Migration from another application'");
		Items.RunMode.CurrentPage = Items.MigrationFromAnotherApplication;
		Items.MigrationFromAnotherApplicationMessageText.Title = StringFunctionsClientServer.SubstituteParametersInString(
			Items.MigrationFromAnotherApplicationMessageText.Title, Metadata.Synonym);
	Else
		Title = NStr("en = 'Application update'");
		Items.RunMode.CurrentPage = Items.ApplicationVersionUpdate;
		Items.ConfigurationToUpdateMessageText.Title = StringFunctionsClientServer.SubstituteParametersInString(
			Items.ConfigurationToUpdateMessageText.Title, Metadata.Synonym, Metadata.Version);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Parameters.Property("Autotest") Then
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If InfobaseUpdateInProgress Then
		Cancel = True;
	ElsIf ExclusiveModeSet Then
		DisableExclusiveMode();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemEventHandlers

&AtClient
Procedure TechnicalInformationClick(Item)
	FilterParameters = New Structure;
	FilterParameters.Insert("ExecuteNotInBackground", True);
	
	OpenForm("DataProcessor.EventLog.Form.EventLog", FilterParameters);
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

////////////////////////////////////////////////////////////////////////////////
// Update of application parameters and shared data in SaaS mode

&AtServerNoContext
Procedure DisableExclusiveMode()
	
	If ExclusiveMode() Then
		SetExclusiveMode(False);
	EndIf;
	
	ExclusiveModeEnabled = False;
	
EndProcedure

&AtClient
Procedure ImportUpdateApplicationParameters(Parameters) Export
	
	ContinuationParameters = Parameters;
	
	AttachIdleHandler("ImportUpdateApplicationParametersBeginning", 0.1, True);
	
EndProcedure

&AtClient
Procedure ImportUpdateApplicationParametersBeginning()
	
	// Long action handler parameters.
	HandlerParameters = New Structure;
	HandlerParameters.Insert("MinInterval", 1);
	HandlerParameters.Insert("MaxInterval", 15);
	HandlerParameters.Insert("CurrentInterval", 1);
	HandlerParameters.Insert("IntervalIncreaseCoefficient", 1.4);
	
	BackgroundJobStorageAddress = Undefined;
	BackgroundJobID  = Undefined;
	
	ExecutionResult = ImportUpdateApplicationParametersInBackground();
	
	If ExecutionResult.JobCompleted
	 Or ExecutionResult.BriefErrorMessage <> Undefined Then
		
		ImportUpdateApplicationParametersProcessResult(
			ExecutionResult.BriefErrorMessage,
			ExecutionResult.DetailedErrorMessage);
	Else
		AttachIdleHandler("ApplicationParametersUpdateValidateAtClient", 1, True);
	EndIf;
	
EndProcedure

&AtServer
Function ImportUpdateApplicationParametersInBackground()
	
	RefreshReusableValues();
	
	CurrentUser = InfobaseUsers.CurrentUser();
	If AccessRight("Administration", Metadata, CurrentUser) Then
		SetPrivilegedMode(True);
	EndIf;
	
	ErrorInfo = Undefined;
	
	Try
		SetExclusiveMode(True);
		ExclusiveModeEnabled = True;
	Except
		// Raising an exception is not required because the need
 	// to set exclusive mode can arise only during background update execution.
 	// Therefore setting the exclusive mode in advance reduces excessive 
 	// background job execution in those cases when exclusive mode 
		// will be required later but can be set immediately without completion of the user sessions.
	EndTry;
	
	// Starting background job
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ClientParametersOnServer", SessionParameters.ClientParametersOnServer);
	DebugMode = CommonSettingsStorage.Load("InfobaseVersionUpdate", "DebugMode") = True;
	
	Try
		// Workaround for the shared database access error.
		If True Then
			ExecutionParameters.Delete("ClientParametersOnServer");
			StorageAddress = PutToTempStorage(Undefined, UUID);
			StandardSubsystemsServer.ImportUpdateApplicationParametersInBackground(ExecutionParameters, StorageAddress, False);
			
			Result = New Structure;
			Result.Insert("StorageAddress", StorageAddress);
			Result.Insert("JobCompleted", True);
			
		Else // Running the update in background.
			Result = LongActions.ExecuteInBackground(
				UUID,
				"StandardSubsystemsServer.ImportUpdateApplicationParametersInBackground",
				ExecutionParameters,
				NStr("en = 'Background update of application parameters'"));
		EndIf;
		
		Result.Insert("BriefErrorMessage",   Undefined);
		Result.Insert("DetailedErrorMessage", Undefined);
	Except
		ErrorInfo = ErrorInfo();
		Result = New Structure;
		Result.Insert("JobCompleted", False);
		Result.Insert("BriefErrorMessage",   BriefErrorDescription(ErrorInfo));
		Result.Insert("DetailedErrorMessage", DetailErrorDescription(ErrorInfo));
	EndTry;
	
	Result.Property("JobID", BackgroundJobID);
	Result.Property("StorageAddress", BackgroundJobStorageAddress);
	
	Return Result;
	
EndFunction

&AtClient
Procedure ImportUpdateApplicationParametersProcessResult(Val BriefErrorMessage, Val DetailedErrorMessage)
	
	ExclusiveModeSettingError = "";
	
	If BriefErrorMessage = Undefined Then
		ExecutionResult = GetFromTempStorage(BackgroundJobStorageAddress);
		
		If TypeOf(ExecutionResult) = Type("Structure") Then
			BriefErrorMessage   = ExecutionResult.BriefErrorMessage;
			DetailedErrorMessage = ExecutionResult.DetailedErrorMessage;
			ExclusiveModeSettingError = ExecutionResult.ExclusiveModeSettingError;
			
			If ExecutionResult.Property("ClientParametersOnServer") Then
				SetSessionParametersFromBackgroundJob();
			EndIf;
		Else
			BriefErrorMessage =
				NStr("en = 'Error getting background job result 
|when updating application parameters.'");
			
			DetailedErrorMessage = BriefErrorMessage;
		EndIf;
	EndIf;
	
	If ExclusiveModeSettingError = "LockScheduledJobExecution" Then
		RestartWithScheduledJobExecutionLock();
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("BriefErrorMessage",   BriefErrorMessage);
	AdditionalParameters.Insert("DetailedErrorMessage", DetailedErrorMessage);
	AdditionalParameters.Insert("ExclusiveModeSettingError", ExclusiveModeSettingError);
	
	If ValueIsFilled(ExclusiveModeSettingError) Then
		
		ImportUpdateApplicationParametersWhenCannotSetExclusiveMode(AdditionalParameters);
		Return;
		
	EndIf;
	
	ImportUpdateApplicationParametersEnd(AdditionalParameters);
	
EndProcedure

&AtClient
Procedure ImportUpdateApplicationParametersWhenCannotSetExclusiveMode(AdditionalParameters)
	
	If ValueIsFilled(AdditionalParameters.ExclusiveModeSettingError) Then
		
		// Opening a form for disabling active sessions
		Notification = New NotifyDescription(
			"ImportUpdateApplicationParametersWhenCannotSetExclusiveModeCompletion",
			ThisObject,
			AdditionalParameters);
		
		OnOpenExclusiveModeSetErrorForm(Notification, AdditionalParameters);
	Else
		ImportUpdateApplicationParametersEnd(AdditionalParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportUpdateApplicationParametersWhenCannotSetExclusiveModeCompletion(Cancel, AdditionalParameters) Export
	
	If Cancel <> False Then
		InfobaseUpdateServerCall.UnlockFileInfobase();
		CloseForm(True, False);
		Return;
	EndIf;
	
	ImportUpdateApplicationParametersBeginning();
	
EndProcedure

&AtClient
Procedure ImportUpdateApplicationParametersEnd(AdditionalParameters)
	
	If AdditionalParameters.BriefErrorMessage <> Undefined Then
		UnsuccessfulUpdateMessage(AdditionalParameters, Undefined);
		Return;
	EndIf;
	
	InfobaseUpdateServerCall.UnlockFileInfobase();
	ContinuationParameters.RetrievedClientParameters.Insert("ApplicationParametersUpdateRequired");
	ContinuationParameters.Insert("CountOfReceivedClientParameters",
		ContinuationParameters.RetrievedClientParameters.Count());
	RefreshReusableValues();
	
	ClientParameters = StandardSubsystemsClientCached.ClientParametersOnStart();
	
	If Not UpdateApplicationParametersOnly
	   And ClientParameters.CanUseSeparatedData Then
		
		ExecuteNotifyProcessing(ContinuationParameters.ContinuationHandler);
	Else
		If ClientParameters.Property("SharedInfobaseDataUpdateRequired") Then
			Try
				InfobaseUpdateServerCall.ExecuteInfobaseUpdate(, True);
			Except
				ErrorInfo = ErrorInfo();
				AdditionalParameters.Insert("BriefErrorMessage",   BriefErrorDescription(ErrorInfo));
				AdditionalParameters.Insert("DetailedErrorMessage", DetailErrorDescription(ErrorInfo));
			EndTry;
			If AdditionalParameters.BriefErrorMessage <> Undefined Then
				UnsuccessfulUpdateMessage(AdditionalParameters, Undefined);
				Return;
			EndIf;
		EndIf;
		CloseForm(False, False);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Procedures for getting the update handlers execution result
 
&AtClient
Procedure ApplicationParametersUpdateValidateAtClient()
	
	Result = ApplicationParametersUpdateCompleted();
	
	If Result.JobCompleted = True
	 Or Result.BriefErrorMessage <> Undefined Then
		
		ImportUpdateApplicationParametersProcessResult(
			Result.BriefErrorMessage, Result.DetailedErrorMessage);
	Else
		LongActionsClient.UpdateIdleHandlerParameters(HandlerParameters);
		AttachIdleHandler("ApplicationParametersUpdateValidateAtClient", HandlerParameters.CurrentInterval, True);
	EndIf;
	
EndProcedure

&AtServer
Function ApplicationParametersUpdateCompleted()
	
	ErrorInfo = Undefined;
	JobCompleted = False;
	
	MoveProgressIndicator(JobCompleted, ErrorInfo);
	
	Result = New Structure;
	Result.Insert("JobCompleted", JobCompleted);
	Result.Insert("BriefErrorMessage",   ?(ErrorInfo <> Undefined, BriefErrorDescription(ErrorInfo), Undefined));
	Result.Insert("DetailedErrorMessage", ?(ErrorInfo <> Undefined, DetailErrorDescription(ErrorInfo), Undefined));
	Result.Insert("ExecutionProgress", ExecutionProgress);
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Infobase update (entire infobase update in local mode, or data area update in SaaS mode)

&AtClient
Procedure UpdateInfobase() Export
	
	ProgressStepBeginning = 10;
	ProgressStepLength  = 5;
	ExecutionProgress = ProgressStepBeginning;
	
	AttachIdleHandler("UpdateInfobaseBeginning", 0.1, True);
	
EndProcedure

&AtClient
Procedure UpdateInfobaseBeginning()
	
	UpdateStartTime = CommonUseClient.SessionDate();
	
	// Long action handler parameters.
	HandlerParameters = New Structure;
	HandlerParameters.Insert("MinInterval", 1);
	HandlerParameters.Insert("MaxInterval", 15);
	HandlerParameters.Insert("CurrentInterval", 1);
	HandlerParameters.Insert("IntervalIncreaseCoefficient", 1.4);
	
	BackgroundJobStorageAddress = Undefined;
	BackgroundJobID = Undefined;
	
	InfobaseUpdateResult = UpdateInfobaseInBackground();
	
	If InfobaseUpdateResult.JobCompleted
	 Or InfobaseUpdateResult.BriefErrorMessage <> Undefined Then
		
		UpdateInfobaseProcessResult(
			InfobaseUpdateResult.BriefErrorMessage,
			InfobaseUpdateResult.DetailedErrorMessage);
	Else
		AttachIdleHandler("InfobaseUpdateValidateAtClient", 1, True);
	EndIf;
	
EndProcedure

&AtServer
Function UpdateInfobaseInBackground()
	
	Result = InfobaseUpdateInternal.UpdateInfobaseInBackground(UUID, InfobaseDataLock);
	InfobaseDataLock = Result.InfobaseDataLock;
	Result.Property("JobID", BackgroundJobID);
	Result.Property("StorageAddress", BackgroundJobStorageAddress);
	Return Result;
	
EndFunction

&AtClient
Procedure UpdateInfobaseProcessResult(Val BriefErrorMessage, Val DetailedErrorMessage)
	
	If BackgroundJobStorageAddress <> "" Then
		UpdateResult = GetFromTempStorage(BackgroundJobStorageAddress);
		
		If TypeOf(UpdateResult) = Type("Structure") Then
			If UpdateResult.Property("BriefErrorMessage")
				And UpdateResult.Property("DetailedErrorMessage") Then
				BriefErrorMessage = UpdateResult.BriefErrorMessage;
				DetailedErrorMessage = UpdateResult.DetailedErrorMessage;
			Else
				HandlersExecutionFlag = UpdateResult.Result;
				SetSessionParametersFromBackgroundJob();
			EndIf;
		Else
			HandlersExecutionFlag = UpdateResult;
		EndIf;
	Else
		HandlersExecutionFlag = InfobaseDataLock.Error;
	EndIf;
	
	If HandlersExecutionFlag = "LockScheduledJobExecution" Then
		RestartWithScheduledJobExecutionLock();
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("UpdateDetailsDocument", Undefined);
	AdditionalParameters.Insert("BriefErrorMessage", BriefErrorMessage);
	AdditionalParameters.Insert("DetailedErrorMessage", DetailedErrorMessage);
	AdditionalParameters.Insert("UpdateStartTime", UpdateStartTime);
	AdditionalParameters.Insert("UpdateEndTime", CommonUseClient.SessionDate());
	AdditionalParameters.Insert("HandlersExecutionFlag", HandlersExecutionFlag);
	
	If HandlersExecutionFlag = "ExclusiveModeSettingError" Then
		
		UpdateInfobaseWhenCannotSetExclusiveMode(AdditionalParameters);
		Return;
		
	EndIf;
	
	UnlockFileInfobase = False;
	If InfobaseDataLock.Property("UnlockFileInfobase", UnlockFileInfobase) Then
		
		If UnlockFileInfobase Then
			InfobaseUpdateServerCall.UnlockFileInfobase();
		EndIf;
		
	EndIf;
	
	UpdateInfobaseCompletion(AdditionalParameters);
	
EndProcedure

&AtClient
Procedure UpdateInfobaseWhenCannotSetExclusiveMode(AdditionalParameters)
	
	If AdditionalParameters.HandlersExecutionFlag = "ExclusiveModeSettingError" Then
		
		// Opening a form for disabling active sessions
		Notification = New NotifyDescription(
			"UpdateInfobaseWhenCannotSetExclusiveModeCompletion", ThisObject, AdditionalParameters);
		OnOpenExclusiveModeSetErrorForm(Notification, AdditionalParameters);
		
	Else
		UpdateInfobaseCompletion(AdditionalParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateInfobaseWhenCannotSetExclusiveModeCompletion(Cancel, AdditionalParameters) Export
	
	If Cancel <> False Then
		CloseForm(True, False);
		Return;
	EndIf;
	
	SetInfobaseLockParametersWhenCannotSetExclusiveMode();
	UpdateInfobaseBeginning();
	
EndProcedure

&AtClient
Procedure SetInfobaseLockParametersWhenCannotSetExclusiveMode()
	
	InfobaseDataLock.Insert("Use", False);
	InfobaseDataLock.Insert("UnlockFileInfobase", True);
	InfobaseDataLock.Insert("Error", Undefined);
	InfobaseDataLock.Insert("NonexclusiveUpdate", Undefined);
	InfobaseDataLock.Insert("RecordKey", Undefined);
	InfobaseDataLock.Insert("DebugMode", Undefined);
	
EndProcedure

&AtClient
Procedure UpdateInfobaseCompletion(AdditionalParameters)
	
	If AdditionalParameters.BriefErrorMessage <> Undefined Then
		UpdateEndTime = CommonUseClient.SessionDate();
		
		UnsuccessfulUpdateMessage(AdditionalParameters, UpdateEndTime);
		Return;
	EndIf;
	
	InfobaseUpdateServerCall.WriteUpdateExecutionTime(
		AdditionalParameters.UpdateStartTime, AdditionalParameters.UpdateEndTime);
	
	RefreshReusableValues();
	CloseForm(False, False);
	
EndProcedure

&AtClient
Procedure CloseForm(Cancel, Restart)
	
	InfobaseVersionUpdateInProgress = False;
	
	Close(New Structure("Cancel, Restart", Cancel, Restart));
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Procedures for getting the update handlers execution result
 
&AtClient
Procedure InfobaseUpdateValidateAtClient()
	
	Result = InfobaseUpdateCompleted();
	
	If Result.JobCompleted = True
	 Or Result.BriefErrorMessage <> Undefined Then
		
		UpdateInfobaseProcessResult(
			Result.BriefErrorMessage, Result.DetailedErrorMessage);
	Else
		LongActionsClient.UpdateIdleHandlerParameters(HandlerParameters);
		AttachIdleHandler("InfobaseUpdateValidateAtClient", HandlerParameters.CurrentInterval, True);
	EndIf;
	
EndProcedure

&AtServer
Function InfobaseUpdateCompleted()
	
	ErrorInfo = Undefined;
	JobCompleted = False;
	
	MoveProgressIndicator(JobCompleted, ErrorInfo);
	
	// If the infobase update is complete, unlocking the infobase.
	If JobCompleted = True Then
		InfobaseUpdateInternal.UnlockInfobase(InfobaseDataLock);
	EndIf;
	
	Result = New Structure;
	Result.Insert("JobCompleted", JobCompleted);
	Result.Insert("BriefErrorMessage",   ?(ErrorInfo <> Undefined, BriefErrorDescription(ErrorInfo),   Undefined));
	Result.Insert("DetailedErrorMessage", ?(ErrorInfo <> Undefined, DetailErrorDescription(ErrorInfo), Undefined));
	Result.Insert("ExecutionProgress", ExecutionProgress);
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Handlers of conditional calls of other subsystems

// The procedure is called during an unsuccessful attempt to set exclusive mode in a file infobase.
// 
// Parameters:
//  Cancel-Boolean-if True, closes the application.
//
&AtClient
Procedure OnOpenExclusiveModeSetErrorForm(Notification, AdditionalParameters)
	
	If CommonUseClient.SubsystemExists("StandardSubsystems.UserSessions") Then
		InfobaseConnectionsClientModule = CommonUseClient.CommonModule("InfobaseConnectionsClient");
		InfobaseConnectionsClientModule.OnOpenExclusiveModeSetErrorForm(Notification);
	Else
		UnsuccessfulUpdateMessage(AdditionalParameters, Undefined);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Common procedures for all stages

&AtClient
Procedure StartClosing() Export
	
	AttachIdleHandler("ContinueClosing", 0.1, True);
	
EndProcedure

&AtClient
Procedure ContinueClosing() Export
	
	InfobaseVersionUpdateInProgress = False;
	
	CloseForm(False, False);
	
EndProcedure

&AtClient
Procedure UnsuccessfulUpdateMessage(AdditionalParameters, UpdateEndTime)
	
	NotifyDescription = New NotifyDescription("UpdateInfobaseActionsOnError", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("BriefErrorMessage",   AdditionalParameters.BriefErrorMessage);
	FormParameters.Insert("DetailedErrorMessage", AdditionalParameters.DetailedErrorMessage);
	FormParameters.Insert("UpdateStartTime",      UpdateStartTime);
	FormParameters.Insert("UpdateEndTime",   UpdateEndTime);
	
	NameOfFormToOpen = "DataProcessor.InfobaseUpdate.Form.UnsuccessfulUpdateMessage";
	
	If ValueIsFilled(ExchangePlanName) Then
		
		DataExchangeClientModule = CommonUseClient.CommonModule("DataExchangeClient");
		DataExchangeClientModule.UnsuccessfulUpdateMessageFormName(NameOfFormToOpen);
		FormParameters.Insert("ExchangePlanName", ExchangePlanName);
		
	EndIf;
	
	OpenForm(NameOfFormToOpen, FormParameters,,,,,NotifyDescription);
	
EndProcedure

&AtClient
Procedure UpdateInfobaseActionsOnError(Exit, AdditionalParameters) Export
	
	If Exit <> False Then
		CloseForm(True, False);
	Else
		CloseForm(True, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure RestartWithScheduledJobExecutionLock()
	
	NewLaunchParameter = LaunchParameter + ";ScheduledJobsDisabled";
	NewLaunchParameter = "/AllowExecuteScheduledJobs - Off " + "/C """ + NewLaunchParameter + """";
	Terminate(True, NewLaunchParameter);
	
EndProcedure

&AtServer
Procedure MoveProgressIndicator(JobCompleted, ErrorInfo)
	
	If BackgroundJobID <> Undefined Then
		
		Try
			JobCompleted = LongActions.JobCompleted(BackgroundJobID);
			Job = BackgroundJobs.FindByUUID(BackgroundJobID);
			If Job <> Undefined Then
				AllMessages = Job.GetUserMessages(True);
				If AllMessages <> Undefined Then
					ProgressStepIncrement = 0;
					For Each UserMessage In AllMessages Do
						AllMessages = Job.GetUserMessages(True);
						If AllMessages = Undefined Then
							AllMessages = New Array;
						EndIf;
						
						BeginningOfTheLine = "ProgressStep=";
						If Left(UserMessage.Text, StrLen(BeginningOfTheLine)) = BeginningOfTheLine Then
							ProgressStepIncrement = 0;
							NewStepDetails = Mid(UserMessage.Text, StrLen(BeginningOfTheLine) + 1);
							SeparatorPosition = Find(NewStepDetails, "/");
							If SeparatorPosition > 0 Then
								ProgressStepBeginning = Number( Left(NewStepDetails, SeparatorPosition - 1));
								ProgressStepLength  = Number(Mid(NewStepDetails, SeparatorPosition + 1));
							EndIf;
						EndIf;
						
						BeginningOfTheLine = "ProgressStepIncrement=";
						If Left(UserMessage.Text, StrLen(BeginningOfTheLine)) = BeginningOfTheLine Then
							ProgressStepIncrement = Number(Mid(UserMessage.Text, StrLen(BeginningOfTheLine) + 1));
						EndIf;
					EndDo;
					// Moving the progress bar.
					NewExecutionProgress = ProgressStepBeginning + ProgressStepIncrement/100*ProgressStepLength;
					If ExecutionProgress < NewExecutionProgress Then
						ExecutionProgress = NewExecutionProgress;
					EndIf;
				EndIf;
			EndIf;
		Except
			
			Job = BackgroundJobs.FindByUUID(BackgroundJobID);
			If Job <> Undefined Then
				AllMessages = Job.GetUserMessages(True);
				If AllMessages <> Undefined Then
					For Each UserMessage In AllMessages Do
						
						BeginningOfTheLine = "DataExchange=";
						If Left(UserMessage.Text, StrLen(BeginningOfTheLine)) = BeginningOfTheLine Then
							ExchangePlanName = Mid(UserMessage.Text, StrLen(BeginningOfTheLine) + 1);
						EndIf;
						
					EndDo;
					
				EndIf;
				
			EndIf;
			
			ErrorInfo = ErrorInfo();
		EndTry;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetSessionParametersFromBackgroundJob()
	UpdateResult = GetFromTempStorage(BackgroundJobStorageAddress);
	SessionParameters.ClientParametersOnServer = UpdateResult.ClientParametersOnServer;
EndProcedure

#EndRegion
