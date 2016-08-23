&AtClient
Var JobActive;

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
 
	// Skipping the initialization to guarantee that the form will be received if the SelfTest parameter is passed.
	If Parameters.Property("SelfTest") Then 
		Return;
	EndIf;
	
	StorageAddress = Parameters.StorageAddress;
	
	Items.Close.Enabled = Not Parameters.CheckMode;
	
	StartRequestProcessing(
		Parameters.IDs,
		Parameters.EnablingMode,
		Parameters.DisablingMode,
		Parameters.RecoveryMode,
		Parameters.CheckMode);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	JobActive = True;
	CheckIteration = 1;
	AttachRequestProcessingIdleHandler(3);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If JobActive Then
		
		CancelRequestProcessing(JobID);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Function StartRequestProcessing(Val Requests, Val EnablingMode, DisablingMode, Val RecoveryMode, Val CheckForApplyMode)
	
	PutToTempStorage(Undefined, StorageAddress);
	
	If EnablingMode Then
		
		JobParameters = New Array();
		JobParameters.Add(StorageAddress);
		
		MethodCallParameters = New Array();
		MethodCallParameters.Add("DataProcessors.ExternalResourcePermissionSetup.ExecuteUpdateRequestProcessing");
		MethodCallParameters.Add(JobParameters);
		
	ElsIf DisablingMode Then
		
		JobParameters = New Array();
		JobParameters.Add(StorageAddress);
		
		MethodCallParameters = New Array();
		MethodCallParameters.Add("DataProcessors.ExternalResourcePermissionSetup.ExecuteDisableRequestProcessing");
		MethodCallParameters.Add(JobParameters);
		
	ElsIf RecoveryMode Then
		
		JobParameters = New Array();
		JobParameters.Add(StorageAddress);
		
		MethodCallParameters = New Array();
		MethodCallParameters.Add("DataProcessors.ExternalResourcePermissionSetup.ExecuteRecoveryRequestProcessing");
		MethodCallParameters.Add(JobParameters);
		
	ElsIf CheckForApplyMode Then
		
		JobParameters = New Array();
		JobParameters.Add(StorageAddress);
		
		MethodCallParameters = New Array();
		MethodCallParameters.Add("DataProcessors.ExternalResourcePermissionSetup.ExecuteCheckForApplyRequestProcessing");
		MethodCallParameters.Add(JobParameters);
		
	Else
		
		JobParameters = New Array();
		JobParameters.Add(Requests);
		JobParameters.Add(StorageAddress);
		
		MethodCallParameters = New Array();
		MethodCallParameters.Add("DataProcessors.ExternalResourcePermissionSetup.ExecuteRequestProcessing");
		MethodCallParameters.Add(JobParameters);
		
	EndIf;
	
	Job = BackgroundJobs.Execute("SafeMode.ExecuteConfigurationMethod",
			MethodCallParameters,
			,
			NStr("en = 'Processing requests for external resources...'"));
	
	JobID = Job.UUID;
	
	Return StorageAddress;
	
EndFunction

&AtClient
Procedure CheckRequestProcessing()
	
	Try
		Done = RequestsProcessed(JobID);
	Except
		JobActive = False;
		Close(DialogReturnCode.Cancel);
		Raise;
	EndTry;
	
	If Done Then
		JobActive = False;
		EndRequestProcessing();
	Else
		
		CheckIteration = CheckIteration + 1;
		
		If CheckIteration = 2 Then
			AttachRequestProcessingIdleHandler(5);
		ElsIf CheckIteration = 3 Then
			AttachRequestProcessingIdleHandler(8);
		Else
			AttachRequestProcessingIdleHandler(10);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function RequestsProcessed(Val JobID)
	
	Job = BackgroundJobs.FindByUUID(JobID);
	
	If Job <> Undefined
		And Job.State = BackgroundJobState.Active Then
		
		Return False;
	EndIf;
	
	If Job = Undefined Then
		Raise(NStr("en = 'Cannot process requests. The request processing job is not found.'"));
	EndIf;
	
	If Job.State = BackgroundJobState.Failed Then
		JobError = Job.ErrorInfo;
		If JobError <> Undefined Then
			Raise(DetailErrorDescription(JobError));
		Else
			Raise(NStr("en = 'Cannot process requests. The request processing job failed with an unknown error.'"));
		EndIf;
	ElsIf Job.State = BackgroundJobState.Canceled Then
		Raise(NStr("en = 'Cannot process requests. The administrator stopped the request processing job.'"));
	Else
		JobID = Undefined;
		Return True;
	EndIf;
	
EndFunction

&AtClient
Procedure EndRequestProcessing()
	
	JobActive = False;
	
	If IsOpen() Then
		
		Close(DialogReturnCode.OK);
		
	Else
		
		NotifyDescription = ThisObject.NotifyOnCloseDescription;
		If NotifyDescription <> Undefined Then
			ExecuteNotifyProcessing(NotifyDescription, DialogReturnCode.OK);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure CancelRequestProcessing(Val JobID)
	
	Job = BackgroundJobs.FindByUUID(JobID);
	
	If Job = Undefined Or Job.State <> BackgroundJobState.Active Then
		Return;
	EndIf;
	
	Try
		Job.Cancel();
	Except
		// Perhaps job finished just at this moment and there is no error.
		WriteLogEvent(NStr("en = 'External resource permission setup.Background job cancellation'", CommonUseClientServer.DefaultLanguageCode()),
			EventLogLevel.Error, , , DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

&AtClient
Procedure AttachRequestProcessingIdleHandler(Val Interval)
	
	AttachIdleHandler("CheckRequestProcessing", Interval, True);
	
EndProcedure

#EndRegion