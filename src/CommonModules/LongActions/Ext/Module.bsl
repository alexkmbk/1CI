////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
// Support of long server actions at the web client.
//
//////////////////////////////////////////////////////////////////////////////// 

#Region Interface

// Executes procedures in a background job.
// 
// Parameters:
// FormID                   - UUID - form ID, the long action is started from this
//                            form.
// ExportProcedureName      - String - name of the export procedure to be executed in
//                            a background job.
// Parameters               - Structure - all parameters necessary for executing the
//                            ExportProcedureName procedure.
// JobDescription           - String - background job description. If JobDescription
//                            is not specified it is equal to ExportProcedureName.
// UseAdditionalTempStorage - Boolean - flag that shows whether an additional
//                            temporary storage is used for transferring data to the
//                            parent session from the background job. The default
//                            value is False.  
//
// Returns:
//  Structure - returns the following job execution properties: 
//              * StorageAddress           - String - address of the temporary storage 
//                                           where the job execution result is stored;
//              * StorageAddressAdditional - String - address of the additional
//                                           temporary storage where the job execution
//                                           result is stored. (Enabled only if
//                                           UseAdditionalTempStorage is True).  
//              * JobID                    - UUID - UUID of the background job being
//                                           started. 
//              * JobCompleted             - True if job completed successfully. 
//
 Function ExecuteInBackground(Val FormID, Val ExportProcedureName, 
	Val Parameters, Val JobDescription = "",  UseAdditionalTempStorage = False) Export
	
	StorageAddress =  PutToTempStorage(Undefined,  FormID);
	
	If Not ValueIsFilled(JobDescription) Then
		JobDescription = ExportProcedureName;
	EndIf;
	
	ExportProcedureParameters = New Array;
	ExportProcedureParameters.Add(Parameters);
	ExportProcedureParameters.Add(StorageAddress);
	
	If UseAdditionalTempStorage Then
		StorageAddressAdditional = PutToTempStorage(Undefined,  FormID);
		ExportProcedureParameters.Add(StorageAddressAdditional);
	EndIf;
	
	JobParameters = New Array;
	JobParameters.Add(ExportProcedureName);
	JobParameters.Add(ExportProcedureParameters);

	If GetClientConnectionSpeed() = ClientConnectionSpeed.Low Then
		Timeout = 4;
	Else
		Timeout = 2;
	EndIf;
	
	Job = BackgroundJobs.Execute("SafeMode.ExecuteConfigurationMethod",  JobParameters,, JobDescription);
	Try
		Job.WaitForCompletion(Timeout);
	Except	
			// No special processing is required. Perhaps the exception was raised because a
			// time-out occurred.
 	EndTry;
	
	Result = New  Structure;
	Result.Insert("StorageAddress", StorageAddress);
	Result.Insert("JobCompleted", JobCompleted(Job.UUID));
	Result.Insert("JobID", Job.UUID);
	
	If  UseAdditionalTempStorage Then
		Result.Insert("StorageAddressAdditional", StorageAddressAdditional);
	EndIf;
	
	Return Result;
	
EndFunction
 
// Cancels background job execution by the passed ID.
// 
// Parameters:
// JobID - UUID - background job ID.
// 
Procedure CancelJobExecution(Val JobID) Export 
	
	If Not ValueIsFilled(JobID) Then
		Return;
	EndIf;
	
	Job = FindJobByID(JobID);
	If Job = Undefined
		Or Job.State <> BackgroundJobState.Active Then
		
		Return;
	EndIf;
	
	Try
		Job.Cancel();
	Except
		// Perhaps job finished just at this moment and there is no error.
		WriteLogEvent(NStr("en = 'Long actions.Background job cancellation'",  CommonUseClientServer.DefaultLanguageCode()),
			EventLogLevel.Error, , ,DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

// Checks background job state by the passed ID.
// If the job is terminated abnormally, the exception is raised.
// 
// Parameters:
//  JobID - UUID - background job ID. 
//
// Returns:
//  Boolean - job execution state.
//
Function JobCompleted(Val JobID) Export
	
	Job = FindJobByID(JobID);
	
	If Job <>  Undefined
		And Job.State =  BackgroundJobState.Active Then
		Return False;
	EndIf;
	
	ActionNotExecuted = True;
	ShowFullErrorText = False;
	If Job = Undefined Then
		WriteLogEvent(NStr("en = 'Long actions.Background job not found'", CommonUseClientServer.DefaultLanguageCode()),
			EventLogLevel.Error, , ,String(JobID));
	Else

		If Job.State = BackgroundJobState.Failed Then
			JobError = Job.ErrorInfo;
			If JobError <> Undefined Then
				ShowFullErrorText = True;

			EndIf;
		ElsIf Job.State =  BackgroundJobState.Canceled Then
			WriteLogEvent(
				NStr("en = 'Long actions.Administrator canceled background job'",  CommonUseClientServer.DefaultLanguageCode()),
				EventLogLevel.Error,
				,
				,
				NStr("en = 'The job finished with an unknown error.'"));
		Else
			Return True;
		EndIf;
	EndIf;
	
	If ShowFullErrorText Then
		ErrorText = BriefErrorDescription(GetErrorInfo(Job.ErrorInfo));
		Raise(ErrorText);
	ElsIf ActionNotExecuted Then
		Raise(NStr("en = 'This job cannot be executed.
|See details in the Event log.'"));
	EndIf;
	
EndFunction

// Registers background job execution details in messages.
// The retrieved details can be read on client using the ReadProgress function.
//
// Parameters:
//  Percent              - Number - Optional. Percent of completion.
//  Text                 - String - Optional. Current action details.
//  AdditionalParameters - Arbitrary - Optional.  Any Additional data to be passed to
//                         client. Only simple (serializable to XML string) values
//                         allowed.
//
Procedure RegisterProgress(Val Percent =  Undefined, Val Text = Undefined, Val AdditionalParameters = Undefined) Export
	
	ValueToPass = New Structure;
	If Percent <>  Undefined Then
		ValueToPass.Insert("Percent", Percent);
	EndIf;
	If Text <>  Undefined Then
		ValueToPass.Insert("Text", Text);
	EndIf;
	If AdditionalParameters <> Undefined Then
		ValueToPass.Insert("AdditionalParameters", AdditionalParameters);
	EndIf;
	
	TextToPass = CommonUse.ValueToXMLString(ValueToPass);
	
	Message = New  UserMessage;
	Message.Text = "{" + SubsystemName() + "}"  + TextToPass;
	
	GetUserMessages(True); // Deleting previous messages
	
	Message.Message();
	
EndProcedure

// Finds the background job and reads execution details from its message.
//
// Returns:
//  Structure - background job execution details. Keys and values of the structure
//              correspond to the names and values of the procedure
//              RegisterProgress() parameters.
//
Function ReadProgress(Val JobID) Export
	Var Result;
	
	Job = BackgroundJobs.FindByUUID(JobID);
	If Job = Undefined Then
		Return Result;
	EndIf;
	
	ArrayOfMessages = Job.GetUserMessages(True);
	If ArrayOfMessages =  Undefined Then
		Return Result;
	EndIf;
	
	Count = ArrayOfMessages.Count();
	
	For Number = 1 to Count Do
		ReverseIndex = Count - Number;
		Message = ArrayOfMessages[ReverseIndex];
		
		If Left(Message.Text, 1) = "{" Then
			Position = Find(Message.Text, "}");
			If Position >  2 Then
				MechanismID = Mid(Message.Text, 2, Position  - 2);
				If MechanismID = SubsystemName() Then
					ResultText = Mid(Message.Text, Position + 1);
					Result = CommonUse.ValueFromXMLString(ResultText);
					Break;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
	Return Result;
EndFunction

#EndRegion

#Region InternalProceduresAndFunctions

Function FindJobByID(Val JobID)
	
	Job = BackgroundJobs.FindByUUID(JobID);
	
	Return Job;
	
EndFunction

Function GetErrorInfo(ErrorInfo)
	
	Result = ErrorInfo;
	If ErrorInfo <> Undefined Then
		If ErrorInfo.Cause <> Undefined Then
			Result = GetErrorInfo(ErrorInfo.Cause);
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

Procedure ExecuteDataProcessorObjectModule(Parameters, StorageAddress) Export 
	
	MethodName = Parameters.MethodName;
	TempStructure = New Structure;
	Try
		TempStructure.Insert(MethodName);
	Except
		WriteLogEvent(NStr("en = 'Safe execution of date processor method'",  CommonUseClientServer.DefaultLanguageCode()),
			EventLogLevel.Error, , ,  DetailErrorDescription(ErrorInfo()));
		Raise  StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='The method name ""%1"" does not meet the requirements of variable name formation.'"),
			MethodName);
	EndTry;
	
	ExecutionParameters = Parameters.ExecutionParameters;
	If Parameters.IsExternalDataProcessor Then
		If ValueIsFilled(Parameters.AdditionalDataProcessorRef) And CommonUse.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
			AdditionalReportsAndDataProcessorsModule =  CommonUse.CommonModule("AdditionalReportsAndDataProcessors");
			DataProcessor =  AdditionalReportsAndDataProcessorsModule.GetExternalDataProcessorsObject(Parameters.AdditionalDataProcessorRef);
		Else
			DataProcessor = ExternalDataProcessors.Create(Parameters.DataProcessorName);
		EndIf;
	Else
		DataProcessor = DataProcessors[Parameters.DataProcessorName].Create();
	EndIf;
	
	Execute("DataProcessor." + MethodName + "(ExecutionParameters, StorageAddress)");
	
EndProcedure

Function SubsystemName()
	Return "StandardSubsystems.LongActions";
EndFunction

#EndRegion