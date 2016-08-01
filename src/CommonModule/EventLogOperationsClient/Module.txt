////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
// Internal procedures and functions for working with the event log.
//  
////////////////////////////////////////////////////////////////////////////////

#Region Interface

// Writes the message to the event log. 
// If WriteEvents is True, the message is written immediately (server call). 
// If WriteEvents is False (by default), the message is placed in a queue to be 
// written later, with the next call of this or another procedure. The queue of the
// messages to be written is passed in the MessagesForEventLog parameter.
//
//  Parameters: 
//   EventName         - String - event name for the event log.
//   LevelPresentation - String - event level details for defining the event level
//                       during writing on the server.
//                       For example: "Error", "Warning".
//                       Are corresponded to the names of the EventLogLevel 
//                       enumeration items.
//   Comment           - String - comment for the event log.
//   EventDate         - Date - accurate date of the event that is described in the 
//                       message. This date will be added to the beginning of the
//                       comment.
//   WriteEvents       - Boolean - flag that shows whether all accumulated messages
//                       must be written.
//
// Example:
//  EventLogClient.AddMessageForEventLog(EventLogMessageText(), "Warning",
//     NStr("en = 'Cannot establish connection to the Internet for checking for
//     updates.'"));
//
Procedure AddMessageForEventLog(Val EventName, Val LevelPresentation = "Information", 
	Val Comment = "", Val EventDate = "", Val WriteEvents = False) Export
	
	// If it is required, initializing the global message list for the event log
	If MessagesForEventLog = Undefined Then
		MessagesForEventLog = New ValueList;
	EndIf;
	
	If TypeOf(EventDate) = Type("Date") Then
		EventDate = Format(EventDate, "DLF=DT");
	EndIf;
	
	MessageStructure = New Structure("EventName, LevelPresentation, Comment, EventDate", 
		EventName, LevelPresentation, Comment, EventDate);
		
	MessagesForEventLog.Add(MessageStructure);
	
	If WriteEvents Then
		EventLogOperationsServerCall.WriteEventsToEventLog(MessagesForEventLog);
	EndIf;
		
EndProcedure

#EndRegion

#Region InternalInterface

// Opens the event log form with the set filter.
//
// Parameters:
//  Filter - Structure - fields and values to filter the log.
//  Owner  - ManagedForm - form that opens the event log.
//
Procedure OpenEventLog(Val Filter = Undefined, Owner = Undefined) Export
	
	OpenForm("DataProcessor.EventLog.Form", Filter, Owner);
	
EndProcedure

// Opens the form for viewing additional event data.
//
// Parameters:
// CurrentData - Value table row - event log row.
//

Procedure OpenDataForViewing(CurrentData) Export
	
	If CurrentData = Undefined Or CurrentData.Data = Undefined Then
		ShowMessageBox(, NStr("en = 'This event log item is not linked to data (see the Data column)'"));
		Return;
	EndIf;
	
	Try
		ShowValue(, CurrentData.Data);
	Except
		WarningText = NStr("en = 'This event log item is linked to data, but there is no way to display it.
									|%1.'");
		If CurrentData.Event = "_$Data$_.Delete" Then 
			// This is a deletion event 
			WarningText =
					StringFunctionsClientServer.SubstituteParametersInString(
						WarningText,
						NStr("en = 'Data is deleted from the Infobase'"));
		Else
			WarningText =
				StringFunctionsClientServer.SubstituteParametersInString(
						WarningText,
						NStr("en = 'Perhaps, data was deleted from the Infobase'"));
		EndIf;
		ShowMessageBox(, WarningText);
	EndTry;
	
EndProcedure

// Opens the event view form of the Event log data processor to display selected event 
// detailed data.
//
// Parameters:
// Data - Value table row - event log row.
//

Procedure ViewCurrentEventInSeparateWindow(Data) Export
	
	If Data = Undefined Then
		Return;
	EndIf;
	
	OpenForm("DataProcessor.EventLog.Form.EventForm", EventLogEventToStructure(Data));
	
EndProcedure

// Prompts the user for the period restriction and includes it in the event log filter
//
// Parameters:
// DateInterval   - StandardPeriod - filter date interval.
// EventLogFilter - Structure - event log filter.
//

Procedure SetViewDateInterval(DateInterval, EventLogFilter, NotificationHandler = Undefined) Export
	
	// Retrieving the current period
	StartDate = Undefined;
	EndDate   = Undefined;
	EventLogFilter.Property("StartDate", StartDate);
	EventLogFilter.Property("EndDate", EndDate);
	StartDate = ?(TypeOf(StartDate) = Type("Date"), StartDate, '00010101000000');
	EndDate   = ?(TypeOf(EndDate)   = Type("Date"), EndDate,   '00010101000000');
	
	If DateInterval.StartDate <> StartDate Then
		DateInterval.StartDate = StartDate;
	EndIf;
	
	If DateInterval.EndDate <> EndDate Then
		DateInterval.EndDate = EndDate;
	EndIf;
	
	// Editing the current period
	Dialog = New StandardPeriodEditDialog;
	Dialog.Period = DateInterval;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("EventLogFilter", EventLogFilter);
	AdditionalParameters.Insert("DateInterval", DateInterval);
	AdditionalParameters.Insert("NotificationHandler", NotificationHandler);
	
	Notification = New NotifyDescription("SetViewDateIntervalCompletion", ThisObject, AdditionalParameters);
	Dialog.Show(Notification);
	
EndProcedure

// Handles selection of a single event in the event table.
//
// Parameters:
// CurrentData    - Value table row - event log row.
// Field          - Value table field - field.
// DateInterval   - interval.
// EventLogFilter - Structure - event log filter.
//
Procedure EventsSelection(CurrentData, Field, DateInterval, EventLogFilter) Export
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Field.Name = "Data" Or Field.Name = "DataPresentation" Then
		If CurrentData.Data <> Undefined
			And Not ValueIsFilled(CurrentData.Comment)
			And (TypeOf(CurrentData.Data) <> Type("String")
			And ValueIsFilled(CurrentData.Data)) Then
			
			OpenDataForViewing(CurrentData);
			Return;
		EndIf;
	EndIf;
	
	If Field.Name = "Date" Then
		SetViewDateInterval(DateInterval, EventLogFilter);
		Return;
	EndIf;
	
	ViewCurrentEventInSeparateWindow(CurrentData);
	
EndProcedure

// Fills the filter according to the value in the current event column.
//
// Parameters:
//  CurrentData    - value table row.
//  CurrentItem - current value table row item.
//  EventLogFilter - Structure - event log filter.
//  ExcludeColumns - ValueList - columns to be excluded.
//
// Returns:
//  Boolean - True if the filter is applied, otherwise is False.
//
Function SetFilterByValueInCurrentColumn(CurrentData, CurrentItem, EventLogFilter, ExcludeColumns) Export
	
	If CurrentData = Undefined Then
		Return False;
	EndIf;
	
	PresentationColumnName = CurrentItem.Name;
	
	If PresentationColumnName = "SessionDataSeparationPresentation" Then
		EventLogFilter.Delete("SessionDataSeparationPresentation");
		EventLogFilter.Insert("SessionDataSeparation", CurrentData.SessionDataSeparation);
		PresentationColumnName = "SessionDataSeparation";
	EndIf;
	
	If ExcludeColumns.Find(PresentationColumnName) <> Undefined Then
		Return False;
	EndIf;
	SelectValue = CurrentData[PresentationColumnName];
	Presentation  = CurrentData[PresentationColumnName];
	
	FilterItemName = PresentationColumnName;
	If PresentationColumnName = "UserName" Then 
		FilterItemName = "User";
		SelectValue = CurrentData["User"];
	ElsIf PresentationColumnName = "ApplicationPresentation" Then
		FilterItemName = "ApplicationName";
		SelectValue = CurrentData["ApplicationName"];
	ElsIf PresentationColumnName = "EventPresentation" Then
		FilterItemName = "Event";
		SelectValue = CurrentData["Event"];
	EndIf;
	
	// Filtering by a blanked string is not allowed
	If TypeOf(SelectValue) = Type("String") And IsBlankString(SelectValue) Then
		// The default user has a blank name, it is allowed to filter by this user
		If PresentationColumnName <> "UserName" Then 
			Return False;
		EndIf;
	EndIf;
	
	CurrentValue = Undefined;
	If EventLogFilter.Property(FilterItemName, CurrentValue) Then
		// Filter is already applied
		EventLogFilter.Delete(FilterItemName);
	EndIf;
	
	If FilterItemName = "Data" Or     // Filter type is not a list but a single value.
		FilterItemName = "Comment" Or
		FilterItemName = "TransactionID" Or
		FilterItemName = "DataPresentation" Then 
		EventLogFilter.Insert(FilterItemName, SelectValue);
	Else
		
		If FilterItemName = "SessionDataSeparation" Then
			FilterList = SelectValue.Copy();
		Else
			FilterList = New ValueList;
			FilterList.Add(SelectValue, Presentation);
		EndIf;
		
		EventLogFilter.Insert(FilterItemName, FilterList);
	EndIf;
	
	Return True;
	
EndFunction

#EndRegion

#Region InternalProceduresAndFunctions

// For internal use only.
//
Function EventLogEventToStructure(Data) Export
	
	If TypeOf(Data) = Type("Structure") Then
		Return Data;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Date",                 Data.Date);
	FormParameters.Insert("UserName",             Data.UserName);
	FormParameters.Insert("ApplicationPresentation",   Data.ApplicationPresentation);
	FormParameters.Insert("Computer",             Data.Computer);
	FormParameters.Insert("Event",                Data.Event);
	FormParameters.Insert("EventPresentation",    Data.EventPresentation);
	FormParameters.Insert("Comment",              Data.Comment);
	FormParameters.Insert("MetadataPresentation", Data.MetadataPresentation);
	FormParameters.Insert("Data",                 Data.Data);
	FormParameters.Insert("DataPresentation",     Data.DataPresentation);
	FormParameters.Insert("TransactionID",        Data.TransactionID);
	FormParameters.Insert("TransactionStatus",    Data.TransactionStatus);
	FormParameters.Insert("Session",              Data.Session);
	FormParameters.Insert("ServerName",           Data.ServerName);
	FormParameters.Insert("Port",                 Data.Port);
	FormParameters.Insert("SyncPort",             Data.SyncPort);
	
	If Data.Property("SessionDataSeparation") Then
		FormParameters.Insert("SessionDataSeparation", Data.SessionDataSeparation);
	EndIf;
	
	If ValueIsFilled(Data.DataAddress) Then
		FormParameters.Insert("DataAddress", Data.DataAddress);
	EndIf;
	
	Return FormParameters;
EndFunction

// For internal use only.
//
Procedure SetViewDateIntervalCompletion(Result, AdditionalParameters) Export
	
	EventLogFilter = AdditionalParameters.EventLogFilter;
	IntervalSet = False;
	
	If Result <> Undefined Then
		
		// Updating the current period
		DateInterval = Result;
		If DateInterval.StartDate = '00010101000000' Then
			EventLogFilter.Delete("StartDate");
		Else
			EventLogFilter.Insert("StartDate", DateInterval.StartDate);
		EndIf;
		
		If DateInterval.EndDate = '00010101000000' Then
			EventLogFilter.Delete("EndDate");
		Else
			EventLogFilter.Insert("EndDate", DateInterval.EndDate);
		EndIf;
		IntervalSet = True;
		
	EndIf;
	
	If AdditionalParameters.NotificationHandler <> Undefined Then
		ExecuteNotifyProcessing(AdditionalParameters.NotificationHandler, IntervalSet);
	EndIf;
	
EndProcedure

#EndRegion