
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("Autotest") Then
		Return;
	EndIf;
	
	InfobaseUpdateOverridable.GetApplicationUpdateResultDetailsText(HintText);
	If Not IsBlankString(HintText) Then
		Items.InformationHint.Title = HintText;
		Items.WhereFindThisFormHint.Title = HintText;
		Items.InformationFormPlacementHint.Title = HintText;
	EndIf;
	
	If Not Users.InfobaseUserWithFullAccess(, True) Then
		
		Items.MinimalUserActivityPeriodHintGroup.Visible = False;
		Items.WhereFindThisFormHint.Title = 
			NStr("en = 'You can check the progress of application data processing using the Application release notes command in the Information section on the desktop.'");
		
	EndIf;
	
	// Reading the constant value
	UpdateDetails = InfobaseUpdateInternal.InfobaseUpdateDetails();
	UpdateEndTime = UpdateDetails.UpdateEndTime;
	
	DeferredUpdateStartTime = UpdateDetails.DeferredUpdateStartTime;
	DeferredUpdateEndTime = UpdateDetails.DeferredUpdateEndTime;
	
	FileInfobase = CommonUse.FileInfobase();
	
	If ValueIsFilled(UpdateEndTime) Then
		Items.UpdateCompletedInformation.Title = StringFunctionsClientServer.SubstituteParametersInString(
			Items.UpdateCompletedInformation.Title,
			Metadata.Version,
			Format(UpdateEndTime, "DLF=D"),
			Format(UpdateEndTime, "DLF=T"),
			UpdateDetails.UpdateDuration);
	Else
		UpdateCompletedTitle = NStr("en = 'The application is updated to version %1'");
		Items.UpdateCompletedInformation.Title = StringFunctionsClientServer.SubstituteParametersInString(
			UpdateCompletedTitle,
			Metadata.Version);
	EndIf;
	
	If UpdateDetails.DeferredUpdateEndTime = Undefined Then
		
		If Not Users.InfobaseUserWithFullAccess(, True) Then
			Items.UpdateStatus.CurrentPage = Items.UserUpdateStatus;
		Else
			
			If Not FileInfobase And UpdateDetails.DeferredUpdateCompletedSuccessfully = Undefined Then
				Items.UpdateStatus.CurrentPage = Items.UpdateInProgress;
			Else
				Items.UpdateStatus.CurrentPage = Items.FileInfobaseUpdate;
			EndIf;
			
		EndIf;
		
	Else
		MessageText = UpdateResultMessage(UpdateDetails);
		Items.UpdateStatus.CurrentPage = Items.UpdateCompleted;
		
		UpdateDetails = InfobaseUpdateInternal.InfobaseUpdateDetails();
		CaptionPattern = NStr("en = 'Additional update procedures completed on %1 at %2'");
		Items.DeferredUpdateCompletedInformation1.Title = 
		StringFunctionsClientServer.SubstituteParametersInString(CaptionPattern, 
			Format(UpdateDetails.DeferredUpdateEndTime, "DLF=D"),
			Format(UpdateDetails.DeferredUpdateEndTime, "DLF=T"));
		
	EndIf;
	
	If Not FileInfobase Then
		UpdateCompleted = False;
		ShowUpdateStatus(UpdateDetails, UpdateCompleted);
		
		If UpdateCompleted Then
			RefreshUpdateCompletedPage(UpdateDetails);
			Items.UpdateStatus.CurrentPage = Items.UpdateCompleted;
			Return;
		EndIf;
		
	Else
		Items.UpdateStatusInformation.Visible = False;
		Items.ChangeSchedule.Visible = False;
	EndIf;
	
	If Users.InfobaseUserWithFullAccess(, True) Then
		
		If CommonUseCached.DataSeparationEnabled() Then
			Items.ChangeSchedule.Visible = False;
		Else
			Schedule = ScheduledJobs.FindPredefined(
				Metadata.ScheduledJobs.DeferredInfobaseUpdate).Schedule;
		EndIf;
		
	EndIf;
	
	If CommonUseCached.DataSeparationEnabled() Then
		Items.MainUpdateHyperlink.Visible = False;
	EndIf;
	
	HideExtraGroupsOnForm(Parameters.OpeningFromAdministrationPanel);
	
	Items.OpenDeferredHandlerList.Title = MessageText;
	Items.InformationTitle.Title = StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en = 'Executing additional procedures for updating data to version %1 
    |Access to this data is temporarily limited'"), Metadata.Version);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Parameters.Property("Autotest") Then
		Return;
	EndIf;
	
	If Not FileInfobase Then
		AttachIdleHandler("CheckHandlerExecutionStatus", 15);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemEventHandlers

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "DeferredUpdate" Then
		
		If Not FileInfobase Then
			Items.UpdateStatus.CurrentPage = Items.UpdateInProgress;
		EndIf;
		
		AttachIdleHandler("RunDeferredUpdate", 0.5, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateStatusInformationClick(Item)
	OpenForm("DataProcessor.InfobaseUpdate.Form.DeferredHandlers");
EndProcedure

&AtClient
Procedure MainUpdateHyperlinkClick(Item)
	
	FormParameters = New Structure;
	FormParameters.Insert("StartDate", DeferredUpdateStartTime);
	If DeferredUpdateEndTime <> Undefined Then
		FormParameters.Insert("EndDate", DeferredUpdateEndTime);
	EndIf;
	
	OpenForm("DataProcessor.EventLog.Form.EventLog", FormParameters);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure CloseForm(Command)
	Close();
EndProcedure

&AtClient
Procedure Update(Command)
	
	If Not FileInfobase Then
		Items.UpdateStatus.CurrentPage = Items.UpdateInProgress;
	EndIf;
	
	AttachIdleHandler("RunDeferredUpdate", 0.5, True);
	
EndProcedure

&AtClient
Procedure OpenDeferredHandlerList(Command)
	OpenForm("DataProcessor.InfobaseUpdate.Form.DeferredHandlers");
EndProcedure

&AtClient
Procedure ChangeSchedule(Command)
	
	Dialog = New ScheduledJobDialog(Schedule);
	
	NotifyDescription = New NotifyDescription("ChangeScheduleCompletion", ThisObject);
	Dialog.Show(NotifyDescription);
	
EndProcedure

&AtClient
Procedure EnableScheduledJobs(Command)
	If CommonUseClient.SubsystemExists("StandardSubsystems.UserSessions") Then
		// Excluding from the dependency check. The link is conditional, thus does not require documenting.
		ApplicationLockFormName = "DataProcessor" + ".ApplicationLock.Form.Form";
		OpenForm(ApplicationLockFormName);
	EndIf;
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure HideExtraGroupsOnForm(OpeningFromAdministrationPanel)
	
	InfobaseUserWithFullAccess = Users.InfobaseUserWithFullAccess(, True);
	
	If Not InfobaseUserWithFullAccess Or OpeningFromAdministrationPanel Then
		WindowOptionsKey = "FormForOrdinaryUser";
		
		Items.FormPlacementHintGroup.Visible = False;
		Items.FormPlacementHintOnUpdateGroup.Visible = False;
		Items.InformationFormPlacementHint.Visible = False;
		Items.IndentUpdateCompleted.Visible = False;
		
		If Not Users.RolesAvailable("ViewEventLog") Then
			Items.MainUpdateHyperlink.Visible = False;
		EndIf;
		
	Else
		WindowOptionsKey = "FormForAdministrator";
	EndIf;
	
	If Not CommonUse.SubsystemExists("StandardSubsystems.UserSessions") Then
		Items.UnlockScheduledJobs.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure RunDeferredUpdate()
	
	ExecuteUpdateAtServer();
	If Not FileInfobase Then
		AttachIdleHandler("CheckHandlerExecutionStatus", 15);
		Return;
	EndIf;
	
	Items.UpdateStatus.CurrentPage = Items.UpdateCompleted;
	
EndProcedure

&AtClient
Procedure CheckHandlerExecutionStatus()
	
	UpdateCompleted = False;
	CheckHandlerExecutionStatusAtServer(UpdateCompleted);
	If UpdateCompleted Then
		Items.UpdateStatus.CurrentPage = Items.UpdateCompleted;
		DetachIdleHandler("CheckHandlerExecutionStatus")
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckHandlerExecutionStatusAtServer(UpdateCompleted)
	
	UpdateDetails = InfobaseUpdateInternal.InfobaseUpdateDetails();
	If UpdateDetails.DeferredUpdateEndTime <> Undefined Then
		UpdateCompleted = True;
	Else
		ShowUpdateStatus(UpdateDetails, UpdateCompleted);
	EndIf;
	
	If UpdateCompleted = True Then
		RefreshUpdateCompletedPage(UpdateDetails);
	EndIf;
	
EndProcedure

&AtServer
Procedure ExecuteUpdateAtServer()
	
	UpdateDetails = InfobaseUpdateInternal.InfobaseUpdateDetails();
	
	UpdateDetails.DeferredUpdateCompletedSuccessfully = Undefined;
	UpdateDetails.DeferredUpdateEndTime = Undefined;
	For Each TreeRowLibrary In UpdateDetails.HandlerTree.Rows Do
		For Each TreeRowVersion In TreeRowLibrary.Rows Do
			For Each Handler In TreeRowVersion.Rows Do
				Handler.AttemptNumber = 0;
			EndDo;
		EndDo;
	EndDo;
	InfobaseUpdateInternal.WriteInfobaseUpdateDetails(UpdateDetails);
	
	If Not FileInfobase Then
		
		If CommonUseCached.DataSeparationEnabled() Then
			InfobaseUpdateInternal.OnEnableDeferredUpdate(True);
		Else
			ScheduledJob = ScheduledJobs.FindPredefined(Metadata.ScheduledJobs.DeferredInfobaseUpdate);
			ScheduledJob.Use = True;
			ScheduledJob.Write();
		EndIf;
		Return;
		
	EndIf;
	
	InfobaseUpdateInternal.PerformDeferredUpdateNow();
	
	UpdateDetails = InfobaseUpdateInternal.InfobaseUpdateDetails();
	RefreshUpdateCompletedPage(UpdateDetails);
	
EndProcedure

&AtServer
Procedure RefreshUpdateCompletedPage(UpdateDetails)
	
	CaptionPattern = NStr("en = 'Additional update procedures completed on %1 at %2'");
	MessageText = UpdateResultMessage(UpdateDetails);
	
	Items.DeferredUpdateCompletedInformation1.Title = 
		StringFunctionsClientServer.SubstituteParametersInString(CaptionPattern, 
			Format(UpdateDetails.DeferredUpdateEndTime, "DLF=D"),
			Format(UpdateDetails.DeferredUpdateEndTime, "DLF=T"));
	
	Items.OpenDeferredHandlerList.Title = MessageText;
	
	DeferredUpdateEndTime = UpdateDetails.DeferredUpdateEndTime;
	
EndProcedure

&AtServer
Function UpdateResultMessage(UpdateDetails)
	
	HandlerList = UpdateDetails.HandlerTree;
	HandlersSuccessfullyExecuted = 0;
	TotalHandlers                = 0;
	For Each TreeRowLibrary In UpdateDetails.HandlerTree.Rows Do
		For Each TreeRowVersion In TreeRowLibrary.Rows Do
			TotalHandlers = TotalHandlers + TreeRowVersion.Rows.Count();
			For Each Handler In TreeRowVersion.Rows Do
				
				If Handler.Status = "Completed" Then
					HandlersSuccessfullyExecuted = HandlersSuccessfullyExecuted + 1;
				EndIf;
				
			EndDo;
		EndDo;
	EndDo;
	
	If TotalHandlers = HandlersSuccessfullyExecuted Then
		
		If TotalHandlers = 0 Then
			Items.NoDeferredHandlerInformation.Visible = True;
			Items.TransitionToDeferredHandlerListGroup.Visible = False;
		Else
			MessageText = NStr("en = 'All update procedures are completed (%1)'");
		EndIf;
		Items.InformationPicture1.Picture = PictureLib.Done32;
	Else
		MessageText = NStr("en = 'Some of the update procedures are not completed (%1 out of %2 completed)'");
		Items.InformationPicture1.Picture = PictureLib.Error32;
	EndIf;
	Return StringFunctionsClientServer.SubstituteParametersInString(
		MessageText, HandlersSuccessfullyExecuted, TotalHandlers);
	
EndFunction

&AtServer
Procedure ShowUpdateStatus(UpdateDetails, UpdateCompleted = False)
	
	HandlersExecuted = 0;
	TotalHandlers    = 0;
	For Each TreeRowLibrary In UpdateDetails.HandlerTree.Rows Do
		For Each TreeRowVersion In TreeRowLibrary.Rows Do
			TotalHandlers = TotalHandlers + TreeRowVersion.Rows.Count();
			For Each Handler In TreeRowVersion.Rows Do
				
				If Handler.Status = "Completed" Then
					HandlersExecuted = HandlersExecuted + 1;
				EndIf;
				
			EndDo;
		EndDo;
	EndDo;
	
	If TotalHandlers = 0 Then
		UpdateCompleted = True;
	EndIf;
	
	Items.UpdateStatusInformation.Title = StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en = 'Completed: %1 out of %2'"),
		HandlersExecuted,
		TotalHandlers);
	
EndProcedure

&AtServer
Procedure SetDeferredUpdateSchedule(Schedule)
	
	ScheduledJob = ScheduledJobs.FindPredefined(Metadata.ScheduledJobs.DeferredInfobaseUpdate);
	ScheduledJob.Schedule = Schedule;
	ScheduledJob.Write();
	
EndProcedure

&AtClient
Procedure ChangeScheduleCompletion(Schedule, AdditionalParameters) Export
	
	If Schedule <> Undefined Then
		SetDeferredUpdateSchedule(Schedule);
	EndIf;
	
EndProcedure

#EndRegion
