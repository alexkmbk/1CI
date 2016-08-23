&AtClient 
Var LongActioinForm;

&AtClient
Var IdleHandlerParams;

&AtServer
Procedure UpdateWarnings()
	
	If (Object.SuccessReportRecipients.Count() <> 0 or Object.FailureReportRecipients.Count() <> 0) and Not RepositoryTasks.SystemEmailAccountIsSet()Then
		Items.Warnings.Visible = True;
		Items.Warnings.Title = "It seems like the system email account is not set.";
	Else
		Items.Warnings.Visible = False;
	EndIf; 
	
EndProcedure


&AtClient
Procedure SetAvailabilityForSchedulePresentation()
	Items.SchedulePresentation.Enabled = Object.RunBySchedule;		
EndProcedure


&AtServerNoContext
Function JobCompleted(JobID)
	Return LongActions.JobCompleted(JobID);	
EndFunction
 
&AtServer
Procedure LoadResult()	
	Result = GetFromTempStorage(StorageAddress);
	If TypeOf(Result) = Type("String") And ValueIsFilled(Result) Then
		CommonUseClientServer.MessageToUser(Result);	
	EndIf; 			
EndProcedure
  
&AtClient
Procedure CheckJobFinishing() Export 
	
	Try
		If LongActioinForm.IsOpen() 
			And LongActioinForm.JobID = JobID Then
			If JobCompleted(JobID) Then 
				LongActionsClient.CloseLongActionForm(LongActioinForm);				
				LoadResult();
			Else
				LongActionsClient.UpdateIdleHandlerParameters(IdleHandlerParams);
				AttachIdleHandler("CheckJobFinishing", IdleHandlerParams.CurrentInterval, True);
			EndIf;
		EndIf;
	Except
		LongActionsClient.CloseLongActionForm(LongActioinForm);
		Raise;
	EndTry;	
	
EndProcedure

&AtClient
Procedure RunTaskInBackground(Task, RepUserName, RepPassword, Actions)
	JobStruct = RepositoryTasks.RunTaskInBackground(ThisForm.UUID, Task, True, Object.Owner, RepUserName, RepPassword, Actions, Object.Description);
	JobID = JobStruct.JobID;
	StorageAddress = JobStruct.StorageAddress;
	LongActioinForm = LongActionsClient.OpenLongActionForm(ThisForm, JobStruct.JobID);
	LongActionsClient.InitIdleHandlerParameters(IdleHandlerParams);
	AttachIdleHandler("CheckJobFinishing", IdleHandlerParams.CurrentInterval, True);
EndProcedure

&AtClient
Procedure RunTask(Command)	
	Actions = New Map();
	For Each Item In Object.Actions  Do
		Actions.Insert(Item.LineNumber,New Structure("Action,ActionParams",Item.Action, Item.ActionParams));
	EndDo; 
	
	RepUserName = Undefined;
	RepPassword = Undefined;
	
	RepositoryTasks.GetRepPasswordAndUserName(Object.Owner, RepUserName, RepPassword);	
	If ValueIsFilled(RepUserName) Then
		RunTaskInBackground(Object.Ref, RepUserName, RepPassword, Actions);
	Else
		Params = New Structure("Repository, Task",  Object.Owner, Object.Ref);
		OpenForm("CommonForm.RepositoryUserNameAndPasswordInput", Params, ThisForm, , WindowOpenVariant.SingleWindow);
	EndIf; 
	
EndProcedure

&AtClient
Procedure OpenActionSettings(Command)
	
	CurData = Items.Actions.CurrentData;
	
	FormPath = RepositoryTasks.GetActionsParamsFormPath(CurData.Action);
	If Not ValueIsFilled(FormPath) Then
		Return; 
	EndIf; 
		
	OpenForm(FormPath,New Structure("Task,ActionParamsUUID", Object.Ref, CurData.UUID), ThisForm);
	
EndProcedure

&AtClient
Procedure ActionsOnActivateRow(Item)
	If Item.CurrentData <> Undefined Then
		Items.OpenActionSettingsButton.Enabled = RepositoryTasks.ActionDataProcessorHasSettings(Item.CurrentData.Action); 
	Else
		Items.OpenActionSettingsButton.Enabled = False;	
	EndIf; 		
EndProcedure

&AtServer
Procedure UpdateSchedulePresentation()
	
	
	SchedulePresentation = String(JobSchedule);
	
	
	Если SchedulePresentation = String(New JobSchedule) Тогда
		
		SchedulePresentation = NStr("eu = 'Schedule is not specified'");
		
	КонецЕсли;
	
	Items.SchedulePresentation.Title = SchedulePresentation;
	
EndProcedure

&AtClient
Procedure ScheduledJobDialogClose(Schedule, Params) Export
	
	If Schedule <> Undefined Then
		JobSchedule = Schedule;		
	EndIf; 
	
	UpdateSchedulePresentation();
	
EndProcedure


&AtClient
Procedure OpenScheduleSettings(Command)
	
	If JobSchedule = Undefined Then
		JobSchedule = New JobSchedule();
	EndIf; 
	
	Dlg = New ScheduledJobDialog(JobSchedule);
	
	ND = New NotifyDescription("ScheduledJobDialogClose", ThisObject);
	Dlg.Show(ND);
	
EndProcedure

&AtClient
Procedure RunByScheduleOnChange(Item)
	SetAvailabilityForSchedulePresentation();
EndProcedure

&AtServer
Procedure SetScheduleJob(Cancel, CurrentObject)
	
	SetPrivilegedMode(True);
	If Object.RunBySchedule Then
		
		If ValueIsFilled(Object.ScheduledJobGUID) Then
			ScheduleJobObj = ScheduledJobs.FindByUUID(Object.ScheduledJobGUID);
		Else
			ScheduleJobObj = ScheduledJobs.CreateScheduledJob("RunRepositoryTask");
			ScheduleJobObj.Description = "Repository task running on schedule";
			ScheduleJobObj.Use = True;
			CurrentObject.ScheduledJobGUID = ScheduleJobObj.UUID;  
			Params = New Array;
			Params.Add(Object.Code);
			ScheduleJobObj.Parameters = Params;
		EndIf; 
		ScheduleJobObj.Schedule = JobSchedule;
		ScheduleJobObj.Write();
	else
		If ValueIsFilled(CurrentObject.ScheduledJobGUID) Then
			CurrentObject.ScheduledJobGUID = Undefined;
			ScheduleJobObj = ScheduledJobs.FindByUUID(Object.ScheduledJobGUID);
			If ScheduleJobObj = Undefined Then
				return;
			EndIf; 
			ScheduleJobObj.Delete();
			ScheduleJobObj.Write();
		EndIf;
		
	EndIf; 
	SetPrivilegedMode(False);
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	SetScheduleJob(Cancel, CurrentObject);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Object.RunBySchedule And JobSchedule = Undefined Then
		Message = New UserMessage();
		Message.Text = "Task running schedule is not specified.";
		Message.Field = "Object.RunBySchedule";
		Message.Message();
		Cancel = True;
		Return;
	EndIf; 
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetPrivilegedMode(True);
	
	If ValueIsFilled(Object.ScheduledJobGUID) Then
		ScheduledJobObj = ScheduledJobs.FindByUUID(Object.ScheduledJobGUID);
		If ScheduledJobObj <> Undefined Then
			JobSchedule = ScheduledJobObj.Schedule;
		EndIf; 		
	EndIf; 
	UpdateSchedulePresentation();		
	UpdateWarnings();
	SetPrivilegedMode(False);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	SetAvailabilityForSchedulePresentation();
EndProcedure

&AtServer
Procedure SetActionParams(UUID, Params)
	
	Rows = Object.Actions.FindRows(New Structure("UUID", UUID));
	If Rows.Count() > 0 Then
		Rows[0].ActionParams = ValueToStringInternal(Params);
	EndIf; 
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	
	If ChoiceSource.FormName = "CommonForm.RepositoryUserNameAndPasswordInput" Then
		If TypeOf(SelectedValue) = Type("Structure") Then
			UserName = Undefined;
			Password = Undefined;
			Task = Undefined;
			SelectedValue.Property("Task", Task);
			SelectedValue.Property("UserName", UserName);
			SelectedValue.Property("Password", Password);	
			Actions = New Map();
			For Each Item In Object.Actions  Do
				Actions.Insert(Item.LineNumber,New Structure("Action,ActionParams",Item.Action, Item.ActionParams));
			EndDo; 
			RunTaskInBackground(Task, UserName, Password, Actions);
		EndIf; 
	else
		SetActionParams(SelectedValue.ActionParamsUUID, SelectedValue.DataProcessorParams);	
	EndIf; 	
	
EndProcedure     


&AtClient
Procedure ActionsOnEditEnd(Item, NewRow, CancelEdit)
	If NewRow And Not CancelEdit Then
		Item.CurrentData.UUID = New UUID();
	EndIf; 
EndProcedure

&AtClient
Procedure ShowEmailAccountEditFormResult() Export 
	UpdateWarnings();		
EndProcedure
   
&AtClient
Procedure WarningsClick(Item)
	ShowValue(New NotifyDescription("ShowEmailAccountEditFormResult", ThisObject),RepositoryTasksClient.GetSystemEmailAccount());
EndProcedure


&AtClient
Procedure FailureReportRecipientsOnEditEnd(Item, NewRow, CancelEdit)
	If Not CancelEdit Then
		UpdateWarnings();
	EndIf; 
EndProcedure


&AtClient
Procedure SuccessReportRecipientsOnEditEnd(Item, NewRow, CancelEdit)
	If Not CancelEdit Then
		UpdateWarnings();
	EndIf; 
EndProcedure


&AtClient
Procedure ActionsBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	If Not CancelEdit Then		
		If Item.CurrentData <> Undefined Then
			Items.OpenActionSettingsButton.Enabled = RepositoryTasks.ActionDataProcessorHasSettings(Item.CurrentData.Action); 
		Else
			Items.OpenActionSettingsButton.Enabled = False;	
		EndIf; 		
	EndIf; 
EndProcedure


&AtClient
Procedure OpenTaskEvents(Command)
	TaskEventsListForm = GetForm("Document.TaskRunningEvent.ListForm");
	TaskEventsListForm.SetFilter(Object.Ref);
	TaskEventsListForm.Open();
EndProcedure
