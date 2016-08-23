&AtClient
Var AllowClose;
&AtClient
Var WaitingCompleted;
&AtClient
Var CommitCompleted;

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
 
	// Skipping the initialization to guarantee that the form will be received if the SelfTest parameter is passed.
	If Parameters.Property("SelfTest") Then 
		Return;
	EndIf;
	
	Duration = Parameters.Duration;
	
	RequestProcessingResultStorage = Parameters.StorageAddress;
	RequestProcessingResult = GetFromTempStorage(RequestProcessingResultStorage);
	
	StartCommitingApplyingRequests(RequestProcessingResult.RequestIDs);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AllowClose = False;
	
	If Duration > 0 Then
		WaitingCompleted = False;
		AttachIdleHandler("AfterWaitForSettingsApplyingInCluster", Duration, True);
	Else
		WaitingCompleted = True;
	EndIf;
	
	CommitCompleted = False;
	CheckIteration = 1;
	AttachRequestProcessingIdleHandler(3);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If Not AllowClose Then
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure StartCommitingApplyingRequests(Val RequestIDs)
	
	JobParameters = New Array();
	JobParameters.Add(RequestIDs);
	
	Job = BackgroundJobs.Execute("SafeModeInternal.ApplyRequests", JobParameters);
	JobID = Job.UUID;
	
EndProcedure

&AtClient
Procedure ValidateCommitingRequestApplying()
	
	Try
		Done = RequestApplyingCommited(JobID);
	Except
		Close(DialogReturnCode.Cancel);
		Raise;
	EndTry;
	
	If Done Then
		FinishCommitingRequestApplying();
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
Function RequestApplyingCommited(Val JobID)
	
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
Procedure FinishCommitingRequestApplying()
	
	CommitCompleted = True;
	CloseForm();
	
EndProcedure

&AtClient
Procedure AttachRequestProcessingIdleHandler(Val Interval)
	
	AttachIdleHandler("ValidateCommitingRequestApplying", Interval, True);
	
EndProcedure

&AtClient
Procedure AfterWaitForSettingsApplyingInCluster()
	
	WaitingCompleted = True;
	CloseForm();
	
EndProcedure

&AtClient
Procedure CloseForm()
	
	If CommitCompleted And WaitingCompleted Then
		
		AllowClose = True;
		Close(DialogReturnCode.OK);
		
	EndIf;
	
EndProcedure

#EndRegion