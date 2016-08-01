#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	// Skipping the initialization to guarantee that the form will be received if the SelfTest parameter is passed.
	If Parameters.Property("SelfTest") Then
		Return;
	EndIf;
	
	EventLogFilter = New Structure;
	DefaultEventLogFilter = New Structure;
	FilterValues =  GetEventLogFilterValues("Event").Event;
	FileInfobase = CommonUse.FileInfobase();
	
	If Not IsBlankString(Parameters.User) Then
		
		UserName = Parameters.User;
		FilterByUser = New ValueList;
		ByUser = FilterByUser.Add(UserName);
		If IsBlankString(UserName) Then
			ByUser.Presentation = Users.UnspecifiedUserFullName();
		Else
			ByUser.Presentation = UserName;
		EndIf;
		
		EventLogFilter.Insert("User", FilterByUser);
		
	EndIf;
	
	If ValueIsFilled(Parameters.EventLogMessageText) Then
		FilterByEvent = New ValueList;
		If TypeOf(Parameters.EventLogMessageText) = Type("Array") Then
			For Each Event In Parameters.EventLogMessageText Do
				EventPresentation = FilterValues[Event];

				FilterByEvent.Add(Event, EventPresentation); 
			EndDo; 
		Else
			FilterByEvent.Add(Parameters.EventLogMessageText, Parameters.EventLogMessageText);
		EndIf;
		EventLogFilter.Insert("Event", FilterByEvent);
	EndIf;
	
	If ValueIsFilled(Parameters.StartDate) Then
		EventLogFilter.Insert("StartDate", Parameters.StartDate);
	EndIf;
	
	If ValueIsFilled(Parameters.EndDate) Then
		EventLogFilter.Insert("EndDate", Parameters.EndDate);
	EndIf;
	
	If Parameters.Data <> Undefined Then
		EventLogFilter.Insert("Data", Parameters.Data);
	EndIf;
	
	If Parameters.Session <> Undefined Then
		EventLogFilter.Insert("Session", Parameters.Session);
	EndIf; 

	// Level is a value list.

	If Parameters.Level <> Undefined Then
		EventLogFilter.Insert("Level", Parameters.Level);
	EndIf;
	
	EventCountLimit = 200;
		
	DefaultFilter = DefaultFilter(FilterValues);
	If Not EventLogFilter.Property("Event") Then
		EventLogFilter.Insert("Event", DefaultFilter);
	EndIf;
	DefaultEventLogFilter.Insert("Event", DefaultFilter);
	Items.SessionDataSeparationPresentation.Visible = Not CommonUseCached.CanUseSeparatedData();
	
	Criticality = "AllEvents";
	
	// Set ExecuteNotInBackground to True if the log must be recorded not in background.
	ExecuteNotInBackground = Parameters.ExecuteNotInBackground;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	RefreshCurrentList();
	
EndProcedure
 
&AtClient
Procedure OnClose()
	
	If JobID <> New  UUID("00000000-0000-0000-0000-000000000000") Then
		OnCloseAtServer();
	EndIf;
	
EndProcedure

#EndRegion

#Region  FormHeaderItemEventHandlers

&AtClient
Procedure EventCountLimitOnChange(Item)
	
#If WebClient Then
	EventCountLimit = ?(EventCountLimit > 1000, 1000, EventCountLimit);
#EndIf
	
	RefreshCurrentList();
	
EndProcedure

&AtClient
Procedure CriticalityOnChange(Item)
	
	If Criticality = "AllEvents" Then
		EventLogFilter.Delete("Level");
		RefreshCurrentList();
	ElsIf Criticality = "Errors" Then
		FilterByLevel = New ValueList;
		FilterByLevel.Add("Error", "Error");
		EventLogFilter.Delete("Level");
		EventLogFilter.Insert("Level", FilterByLevel);
		RefreshCurrentList();
	ElsIf Criticality = "Warnings" Then
		FilterByLevel = New ValueList;
		FilterByLevel.Add("Warning", "Warning");
		EventLogFilter.Delete("Level");
		EventLogFilter.Insert("Level", FilterByLevel);
		RefreshCurrentList();
	EndIf;
	
EndProcedure

#EndRegion

#Region LogFormTableItemEventHandlers 
 
&AtClient
Procedure EventLogChoice(Item, SelectedRow, Field, StandardProcessing)
	
	EventLogOperationsClient.EventsSelection(
		Items.Log.CurrentData, 
		Field, 
		DateInterval, 
		EventLogFilter);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	
	If TypeOf(SelectedValue) = Type("Structure") And SelectedValue.Property("Event") Then
		
		If SelectedValue.Event = "EventLogFilterSet" Then
			
			EventLogFilter.Clear();
			For Each ListItem In SelectedValue.Filter Do
				EventLogFilter.Insert(ListItem.Presentation, ListItem.Value);
			EndDo;
 
 			If EventLogFilter.Property("Level")

				And EventLogFilter.Level.Count() > 1  Then
				Criticality = "";
			EndIf;
 			RefreshCurrentList();
		
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers


&AtClient
Procedure RefreshCurrentList()

	
	Items.Pages.CurrentPage = Items.LongActionIndicator;
	
	ExecutionResult = ReadEventLog();
	
	IdleHandlerParameters = New Structure;
	
	If Not ExecutionResult.JobCompleted Then

		LongActionsClient.InitIdleHandlerParameters(IdleHandlerParameters);
		AttachIdleHandler("Attachable_CheckJobExecution", 1, True);
		CommonUseClientServer.SetSpreadsheetDocumentFieldState(Items.LongActionIndicatorField, "ReportCreation");
	Else
		Items.Pages.CurrentPage = Items.EventLog;
		MoveToListEnd();
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearFilter()
	
	EventLogFilter =  DefaultEventLogFilter;
	Criticality = "AllEvents";
	RefreshCurrentList();
	
EndProcedure

&AtClient
Procedure OpenDataForViewing()
	
	EventLogOperationsClient.OpenDataForViewing(Items.Log.CurrentData);
	
EndProcedure

&AtClient
Procedure ViewCurrentEventInSeparateWindow()
	
	EventLogOperationsClient.ViewCurrentEventInSeparateWindow(Items.Log.CurrentData);
	
EndProcedure

&AtClient
Procedure SetViewDateInterval()
	
	Notification = New NotifyDescription("SetViewDateIntervalCompletion", ThisObject);
	EventLogOperationsClient.SetViewDateInterval(DateInterval,  EventLogFilter, Notification)
	
EndProcedure

&AtClient
Procedure SetFilter()
	
	SetFilterOnClient();
	
EndProcedure

&AtClient
Procedure FilterPresentationClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	SetFilterOnClient();
	
EndProcedure

&AtClient
Procedure SetFilterByValueInCurrentColumn()
	
	ExcludeColumns = New Array;
	ExcludeColumns.Add("Date");
	
	If EventLogOperationsClient.SetFilterByValueInCurrentColumn(
			Items.Log.CurrentData, 
			Items.Log.CurrentItem, 
			EventLogFilter, 
			ExcludeColumns
		) Then
		
		RefreshCurrentList();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtClient
Procedure SetViewDateIntervalCompletion(IntervalSet,  AdditionalParameters) Export
	
	If IntervalSet Then
		RefreshCurrentList();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnCloseAtServer()
	
	LongActions.CancelJobExecution(JobID);
	
EndProcedure

&AtServer
Function DefaultFilter(EventList)
	
	DefaultFilter = New  ValueList;
	
	For Each LogEvent In EventList Do
		
		If LogEvent.Key = "_$Transaction$_.Commit"
			Or LogEvent.Key = "_$Transaction$_.Begin"
			Or LogEvent.Key = "_$Transaction$_.Rollback" Then
			Continue;
		EndIf;
		
		DefaultFilter.Add(LogEvent.Key, LogEvent.Value);
		
	EndDo;
	
	Return DefaultFilter;
EndFunction

&AtServer
Function ReadEventLog()
	
	ReportParameters = ReportParameters();
	
	If Not  CheckFilling() Then 
		Return New  Structure("JobCompleted", True);
	EndIf;
	
	LongActions.CancelJobExecution(JobID);
	
	JobID = Undefined;
	
	CommonUseClientServer.SetSpreadsheetDocumentFieldState(Items.LongActionIndicatorField, "DontUse");
	
	If FileInfobase
		Or ExecuteNotInBackground Then
		StorageAddress =  PutToTempStorage(Undefined,  UUID);
		EventLogOperations.ReadEventLogEvents(ReportParameters, StorageAddress);
		ExecutionResult = New Structure("JobCompleted", True);
	Else
		ExecutionResult = LongActions.ExecuteInBackground(
			UUID, 
			"EventLogOperations.ReadEventLogEvents", 
			ReportParameters, 
			NStr("en = 'Updating the event log'"));
						
		StorageAddress = ExecutionResult.StorageAddress;
		JobID =  ExecutionResult.JobID;		
	EndIf;
	
	If ExecutionResult.JobCompleted Then
		LoadPreparedData();
	EndIf;
	
	EventLogOperations.GenerateFilterPresentation(FilterPresentation,  EventLogFilter,  DefaultEventLogFilter);
	
	Return ExecutionResult;
	
EndFunction

&AtServer
Function ReportParameters()
	ReportParameters = New  Structure;
	ReportParameters.Insert("EventLogFilter", EventLogFilter);
	ReportParameters.Insert("EventCountLimit", EventCountLimit);
	ReportParameters.Insert("UUID", UUID);
	ReportParameters.Insert("OwnerManager", DataProcessors.EventLog);
	ReportParameters.Insert("AddAdditionalColumns",  False);
	ReportParameters.Insert("Log",  FormAttributeToValue("Log"));

	Return ReportParameters;
EndFunction

&AtServer
Procedure LoadPreparedData()

	ExecutionResult =  GetFromTempStorage(StorageAddress);
	LogEvents = ExecutionResult.LogEvents;
	
	EventLogOperations.PutDataToTempStorage(LogEvents,  UUID);
	
	ValueToFormData(LogEvents, Log);

	JobID = Undefined;

EndProcedure

&AtClient
Procedure MoveToListEnd()
	If Log.Count() > 0 Then
		Items.Log.CurrentRow = Log[Log.Count() - 1].GetID();
	EndIf;
EndProcedure 

&AtClient
Procedure  Attachable_CheckJobExecution() 
	
	Try
		If JobCompleted(JobID) Then 
			LoadPreparedData();
			CommonUseClientServer.SetSpreadsheetDocumentFieldState(Items.LongActionIndicatorField,  "DontUse");
			Items.Pages.CurrentPage = Items.EventLog;
			MoveToListEnd();
		Else
			LongActionsClient.UpdateIdleHandlerParameters(IdleHandlerParameters);
			AttachIdleHandler(
				"Attachable_CheckJobExecution", 
				IdleHandlerParameters.CurrentInterval, 
				True);
		EndIf;
	Except
		CommonUseClientServer.SetSpreadsheetDocumentFieldState(Items.LongActionIndicatorField, "DontUse");
		Items.Pages.CurrentPage = Items.EventLog;
		MoveToListEnd();
		Raise;
	EndTry;	
EndProcedure

&AtServerNoContext
Function JobCompleted(JobID)
	
	Return LongActions.JobCompleted(JobID);
	
EndFunction

&AtClient
Procedure SetFilterOnClient()
	
	FormFilter = New ValueList;
	For Each KeyAndValue  In EventLogFilter Do
		FormFilter.Add(KeyAndValue.Value, KeyAndValue.Key);
	EndDo;
	
	OpenForm(
		"DataProcessor.EventLog.Form.EventLogFilter", 
		New Structure("Filter, DefaultEvents", FormFilter, DefaultEventLogFilter.Event), 
		ThisObject);
	
EndProcedure

#EndRegion