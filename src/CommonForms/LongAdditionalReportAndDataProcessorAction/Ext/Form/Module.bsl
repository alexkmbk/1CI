
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("Autotest") Then
		Return;
	EndIf;
	
	BackgroundJobStartupParameters = Undefined;
	If Not Parameters.Property("BackgroundJobStartupParameters", BackgroundJobStartupParameters) Then
		Cancel = True;
		Return;
	EndIf;
	
	If BackgroundJobStartupParameters.Property("AccompanyingText") And ValueIsFilled(BackgroundJobStartupParameters.AccompanyingText) Then
		AccompanyingText = BackgroundJobStartupParameters.AccompanyingText;
	Else
		AccompanyingText = NStr("en = 'Executing command...'");
	EndIf;
	
	If BackgroundJobStartupParameters.Property("Title") And ValueIsFilled(BackgroundJobStartupParameters.Title) Then
		Title = BackgroundJobStartupParameters.Title;
	Else
		Title = NStr("en = 'Please wait'");
	EndIf;
	
	Try
		
		JobResult = LongActions.ExecuteInBackground(
			UUID,
			"AdditionalReportsAndDataProcessors.ExecuteCommand", 
			BackgroundJobStartupParameters,
			StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Execution of additional report or data processor: %1, command name: %2'"),
				String(BackgroundJobStartupParameters.AdditionalDataProcessorRef),
				BackgroundJobStartupParameters.CommandID));
		
		Completed = JobResult.JobCompleted;
		ExceptionRaised = False;
		
		If Completed Then
			Result = GetFromTempStorage(JobResult.StorageAddress);
		Else
			BackgroundJobID             = JobResult.JobID;
			BackgroundJobStorageAddress = JobResult.StorageAddress;
		EndIf;
		
	Except
		
		Completed = False;
		ExceptionRaised = True;
		ErrorText = BriefErrorDescription(ErrorInfo());
		
	EndTry;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Completed Then 
		Cancel = True;
		NotifyChoice(Result);
	Else
		CheckInterval = 1;
		BackgroundJobValidateOnClose = True;
		AttachIdleHandler("CheckExecution", CheckInterval, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose()
	If BackgroundJobValidateOnClose Then
		BackgroundJobValidateOnClose = False;
		CheckResult = CheckExecutionAtServer(BackgroundJobID, BackgroundJobStorageAddress, True);
		If CheckResult.JobCompleted Then
			NotifyChoice(CheckResult.Value);
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Cancel(Command)
	QuestionText = NStr("en = 'A long action is in progress.'");
	
	Buttons = New ValueList;
	Buttons.Add(1, NStr("en = 'Continue'"));
	Buttons.Add(DialogReturnCode.Abort);
	
	DetachIdleHandler("CheckExecution");
	
	Handler = New NotifyDescription("CancelCompletion", ThisObject);
	ShowQueryBox(Handler, QuestionText, Buttons, 60, 1);
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtClient
Procedure CheckExecution()
	CheckResult = CheckExecutionAtServer(BackgroundJobID, BackgroundJobStorageAddress, False);
	
	If CheckResult.JobCompleted Then
		BackgroundJobValidateOnClose = False;
		NotifyChoice(CheckResult.Value);
	EndIf;
	
	If CheckInterval < 15 Then
		CheckInterval = CheckInterval + 0.7;
	EndIf;
	AttachIdleHandler("CheckExecution", CheckInterval, True);
EndProcedure

&AtServerNoContext
Function CheckExecutionAtServer(BackgroundJobID, BackgroundJobStorageAddress, BreakeIfNotCompleted)
	CheckResult = New Structure("JobCompleted, Value", False, Undefined);
	If LongActions.JobCompleted(BackgroundJobID) Then
		CheckResult.JobCompleted = True;
		CheckResult.Value        = GetFromTempStorage(BackgroundJobStorageAddress);
	ElsIf BreakeIfNotCompleted Then
		LongActions.CancelJobExecution(BackgroundJobID);
	EndIf;
	Return CheckResult;
EndFunction

&AtClient
Procedure CancelCompletion(Answer, AdditionalParameters) Export
	BreakeIfNotCompleted = (Answer = DialogReturnCode.Abort);
	
	CheckResult = CheckExecutionAtServer(BackgroundJobID, BackgroundJobStorageAddress, BreakeIfNotCompleted);
	
	If CheckResult.JobCompleted Or BreakeIfNotCompleted Then
		BackgroundJobValidateOnClose = False;
		NotifyChoice(CheckResult.Value);
		Return;
	EndIf;
	
	If CheckInterval < 15 Then
		CheckInterval = CheckInterval + 0.7;
	EndIf;
	
	AttachIdleHandler("CheckExecution", CheckInterval, True);
EndProcedure

#EndRegion
