#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
   // Skipping the initialization to guarantee that the form will be received if the SelfTest parameter is passed.
	If Parameters.Property("SelfTest") Then
		Return;
	EndIf;
	
	FillImportanceAndStatus();
	FillFilterParameters();
 
	DefaultEvents = Parameters.DefaultEvents;
	If Not  CommonUseClientServer.ValueListsEqual(DefaultEvents, Events) Then
		EventsToDisplay = Events.Copy();
	EndIf;
	
	StandardSubsystemsServer.SetGroupTitleRepresentation(ThisObject, "DataGroup, TransactionIDGroup, OthersGroup");
	
	Items.SessionDataSeparation.Visible = Not CommonUseCached.CanUseSeparatedData();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	Var ListToEdit, ParametersToSelect, StandardProcessing;
	
	If EventName = "EventLogFilterItemValueChoice"
	 And Source = ThisObject Then
		If PropertyContentEditorItemName = Items.Users.Name Then
			UserList = Parameter;
		ElsIf PropertyContentEditorItemName = Items.Events.Name Then
			Events = Parameter;
		ElsIf PropertyContentEditorItemName = Items.Computers.Name Then
			Computers = Parameter;
		ElsIf PropertyContentEditorItemName = Items.Applications.Name Then
			Applications = Parameter;
		ElsIf PropertyContentEditorItemName = Items.Metadata.Name Then
			Metadata = Parameter;
		ElsIf PropertyContentEditorItemName = Items.ServerNames.Name Then
			ServerNames = Parameter;
		ElsIf PropertyContentEditorItemName = Items.Ports.Name Then
			MainIPPorts = Parameter;
		ElsIf PropertyContentEditorItemName = Items.SyncPorts.Name Then
			SyncPorts= Parameter;
		ElsIf PropertyContentEditorItemName  = Items.SessionDataSeparation.Name Then
			SessionDataSeparation = Parameter;
		EndIf;
	EndIf;
	
	EventsToDisplay.Clear();
	
	If Events.Count() = 0 Then
		Events = DefaultEvents;
		Return;
	EndIf;
	
	If Not  CommonUseClientServer.ValueListsEqual(DefaultEvents, Events) Then
		EventsToDisplay = Events.Copy();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemEventHandlers
 
&AtClient
Procedure ChoiceCompletion(Item, ChoiceData, StandardProcessing)
	
	Var ListToEdit, ParametersToSelect;
	
	StandardProcessing = False;
	
	PropertyContentEditorItemName = Item.Name;
	
	If PropertyContentEditorItemName = Items.Users.Name Then
		ListToEdit = UserList;
		ParametersToSelect = "User";
	ElsIf PropertyContentEditorItemName = Items.Events.Name Then
		ListToEdit = Events;
		ParametersToSelect = "Event";
	ElsIf PropertyContentEditorItemName = Items.Computers.Name Then
		ListToEdit = Computers;
		ParametersToSelect = "Computer";
	ElsIf PropertyContentEditorItemName = Items.Applications.Name Then
		ListToEdit = Applications;
		ParametersToSelect = "ApplicationName";
	ElsIf PropertyContentEditorItemName = Items.Metadata.Name Then
		ListToEdit = Metadata;
		ParametersToSelect = "Metadata";
	ElsIf PropertyContentEditorItemName = Items.ServerNames.Name Then
		ListToEdit = ServerNames;
		ParametersToSelect = "ServerName";
	ElsIf PropertyContentEditorItemName = Items.Ports.Name Then
		ListToEdit = Ports;
		ParametersToSelect = "Port";
	ElsIf PropertyContentEditorItemName = Items.SyncPorts.Name Then
		ListToEdit = SyncPorts;
		ParametersToSelect = "SyncPort";
 	ElsIf PropertyContentEditorItemName  = Items.SessionDataSeparation.Name Then

		FormParameters = New  Structure;
		FormParameters.Insert("SetFilter", SessionDataSeparation);
		OpenForm("DataProcessor.EventLog.Form.SessionDataSeparation",  FormParameters, ThisObject);
		Return;
	Else
		StandardProcessing = True;
		Return;
	EndIf;
	
	FormParameters = New Structure;
	
	FormParameters.Insert("ListToEdit", ListToEdit);
	FormParameters.Insert("ParametersToSelect", ParametersToSelect);
	
	// Opening the property editor
	OpenForm("DataProcessor.EventLog.Form.PropertyContentEditor",
	 FormParameters,
	 ThisObject);
	
EndProcedure
 
&AtClient

Procedure EventsClearing(Item, StandardProcessing)
	
	Events = DefaultEvents;
	
EndProcedure

&AtClient
Procedure FilterIntervalOnChange(Item)
	
	FilterIntervalStartDate = FilterInterval.StartDate;
	FilterIntervalEndDate = FilterInterval.EndDate;
	
EndProcedure

&AtClient
Procedure FilterIntervalDateOnChange(Item)
	
	FilterInterval.Variant = StandardPeriodVariant.Custom;
	FilterInterval.StartDate = FilterIntervalStartDate;
	FilterInterval.EndDate = FilterIntervalEndDate;
	
EndProcedure

#EndRegion


#Region FormCommandHandlers

&AtClient
Procedure SetFilterAndCloseForm(Command)
	
	NotifyChoice(
		New Structure("Event, Filter", 
			"EventLogFilterSet", 
			GetEventLogFilter()));
	
EndProcedure


&AtClient

Procedure SelectImportanceCheckBoxes(Command)
	For Each ListItem In Importance Do
		ListItem.Check = True;
	EndDo;
EndProcedure

&AtClient
Procedure ClearImportanceCheckBoxes(Command)
	For Each ListItem  In Importance Do
		ListItem.Check = False;
	EndDo;
EndProcedure

&AtClient
Procedure SelectTransactionStatusCheckBoxes(Command)
	For Each ListItem  In TransactionStatus Do
		ListItem.Check = True;
	EndDo;
EndProcedure

&AtClient
Procedure ClearTransactionStatusCheckBoxes(Command)
	For Each ListItem  In TransactionStatus Do
		ListItem.Check = False;
	EndDo;
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions
 
&AtServer
Procedure FillImportanceAndStatus()
	// Filling the Importance form item
	Importance.Add("Error", String(EventLogLevel.Error));
	Importance.Add("Warning", String(EventLogLevel.Warning));
	Importance.Add("Information", String(EventLogLevel.Information));
	Importance.Add("Note", String(EventLogLevel.Note));
	
	// Filling the TransactionStatus form item
	TransactionStatus.Add("NotApplicable", String(EventLogEntryTransactionStatus.NotApplicable));
	TransactionStatus.Add("Committed", String(EventLogEntryTransactionStatus.Committed));
	TransactionStatus.Add("Unfinished", String(EventLogEntryTransactionStatus.Unfinished));
	TransactionStatus.Add("RolledBack", String(EventLogEntryTransactionStatus.RolledBack));
	
EndProcedure

&AtServer
Procedure FillFilterParameters()
	
	FilterParameterList = Parameters.Filter;
	HasFilterByLevel = False;
	HasFilterByStatus = False;
	
	For Each FilterParameter In FilterParameterList Do
		ParameterName = FilterParameter.Presentation;
		Value = FilterParameter.Value;
		
		If Upper(ParameterName) = Upper("StartDate") Then
			// StartDate
			FilterInterval.StartDate = Value;
			FilterIntervalStartDate = Value;
			
		ElsIf Upper(ParameterName) = Upper("EndDate") Then
			// EndDate
			FilterInterval.EndDate = Value;
			FilterIntervalEndDate = Value;
			
		ElsIf Upper(ParameterName) = Upper("User") Then
			// User
			UserList = Value;
			
		ElsIf Upper(ParameterName) = Upper("Event") Then
			// Event
			Events = Value;
			
		ElsIf Upper(ParameterName) = Upper("Computer") Then
			// Computer
			Computers = Value;
			
		ElsIf Upper(ParameterName) = Upper("ApplicationName") Then
			// ApplicationName
			Applications = Value;
			
		ElsIf Upper(ParameterName) = Upper("Comment") Then
			// Comment
			Comment = Value;
			
		ElsIf Upper(ParameterName) = Upper("Metadata") Then
			// Metadata
			Metadata = Value;
			
		ElsIf Upper(ParameterName) = Upper("Data") Then
			// Data 
			Data = Value;
			
		ElsIf Upper(ParameterName) = Upper("DataPresentation") Then
			// DataPresentation
			DataPresentation = Value;
			
		ElsIf Upper(ParameterName) = Upper("TransactionID") Then
			// TransactionID
			TransactionID = Value;
			
		ElsIf Upper(ParameterName) = Upper("ServerName") Then
			// ServerName
			ServerNames = Value;
			
		ElsIf Upper(ParameterName) = Upper("Session") Then
			// Session
			Sessions = Value;
			SessionsString = "";
			For Each SessionNumber In Sessions Do
				SessionsString = SessionsString + ?(SessionsString = "", "", "; ") + SessionNumber;
			EndDo;
			
		ElsIf Upper(ParameterName) = Upper("Port") Then
			// Port
			Ports = Value;
			
		ElsIf Upper(ParameterName) = Upper("SyncPort") Then
			// SyncPort
			SyncPorts = Value;
			
		ElsIf Upper(ParameterName) = Upper("Level") Then
			// Level
			HasFilterByLevel = True;
			For Each ValueListItem In Importance Do
				If Value.FindByValue(ValueListItem.Value) <> Undefined Then
					ValueListItem.Check = True;
				EndIf;
			EndDo;
			
		ElsIf Upper(ParameterName) = Upper("TransactionStatus") Then
			// TransactionStatus
			HasFilterByStatus = True;
			For Each ValueListItem In TransactionStatus Do
				If Value.FindByValue(ValueListItem.Value) <> Undefined Then
					ValueListItem.Check = True;
				EndIf;
			EndDo;
 
 		ElsIf Upper(ParameterName) = Upper("SessionDataSeparation") Then

			
			If TypeOf(Value) =  Type("ValueList") Then
				SessionDataSeparation = Value.Copy();
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If Not HasFilterByLevel Then
		For Each ValueListItem In Importance Do
			ValueListItem.Check = True;
		EndDo;
	EndIf;
	
	If Not HasFilterByStatus Then
		For Each ValueListItem In TransactionStatus Do
			ValueListItem.Check = True;
		EndDo;
	EndIf;
		
	
EndProcedure

&AtClient
Function GetEventLogFilter()
	
	Sessions.Clear();
	Str = SessionsString;
	Str = StrReplace(Str, ";", " ");
	Str = StrReplace(Str, ",", " ");
	Str = TrimAll(Str);
	TS = New TypeDescription("Number");
	
	While Not IsBlankString(Str) Do
		Pos = Find(Str, " ");
		
		If Pos = 0 Then
			Value = TS.AdjustValue(Str);
			Str = "";
		Else
			Value = TS.AdjustValue(Left(Str, Pos-1));
			Str = TrimAll(Mid(Str, Pos+1));
		EndIf;
		
		If Value <> 0 Then
			Sessions.Add(Value);
		EndIf;
	EndDo;
	
	Filter = New ValueList;
	
	// Start and end dates
	If FilterIntervalStartDate <> '00010101000000' Then 
		Filter.Add(FilterIntervalStartDate, "StartDate");
	EndIf;
	If FilterIntervalEndDate <> '00010101000000' Then
		Filter.Add(FilterIntervalEndDate, "EndDate");
	EndIf;
	
	// User
	If UserList.Count() > 0 Then 
		Filter.Add(UserList, "User");
	EndIf;
	
	// Event
	If Events.Count() > 0 Then 
		Filter.Add(Events, "Event");
	EndIf;
	
	// Computer
	If Computers.Count() > 0 Then 
		Filter.Add(Computers, "Computer");
	EndIf;
	
	// ApplicationName
	If Applications.Count() > 0 Then 
		Filter.Add(Applications, "ApplicationName");
	EndIf;
	
	// Comment
	If Not IsBlankString(Comment) Then 
		Filter.Add(Comment, "Comment");
	EndIf;
	
	// Metadata
	If Metadata.Count() > 0 Then 
		Filter.Add(Metadata, "Metadata");
	EndIf;
	
	// Data 
	If (Data <> Undefined) And (Not Data.IsEmpty()) Then
		Filter.Add(Data, "Data");
	EndIf;
	
	// DataPresentation
	If Not IsBlankString(DataPresentation) Then 
		Filter.Add(DataPresentation, "DataPresentation");
	EndIf;
	
	// TransactionID
	If Not IsBlankString(TransactionID) Then 
		Filter.Add(TransactionID, "TransactionID");
	EndIf;
	
	// ServerName
	If ServerNames.Count() > 0 Then 
		Filter.Add(ServerNames, "ServerName");
	EndIf;
	
	// Session
	If Sessions.Count() > 0 Then 
		Filter.Add(Sessions, "Session");
	EndIf;
	
	// Port
	If Ports.Count() > 0 Then 
		Filter.Add(Ports, "Port");
	EndIf;
	
	// SyncPort
	If SyncPorts.Count() > 0 Then 
		Filter.Add(SyncPorts, "SyncPort");
	EndIf;
 
 	// SessionDataSeparation

	If SessionDataSeparation.Count() > 0 Then  
		Filter.Add(SessionDataSeparation, "SessionDataSeparation");
	EndIf;
	
	// Level
	LevelList = New ValueList;
	For Each ValueListItem In Importance Do
		If ValueListItem.Check Then 
			LevelList.Add(ValueListItem.Value, ValueListItem.Presentation);
		EndIf;
	EndDo;
	If LevelList.Count() > 0 And LevelList.Count() <> Importance.Count() Then
		Filter.Add(LevelList, "Level");
	EndIf;
	
	// TransactionStatus
	StatusList = New ValueList;
	For Each ValueListItem In TransactionStatus Do
		If ValueListItem.Check Then 
			StatusList.Add(ValueListItem.Value, ValueListItem.Presentation);
		EndIf;
	EndDo;
	If StatusList.Count() > 0 And StatusList.Count() <> TransactionStatus.Count() Then
		Filter.Add(StatusList, "TransactionStatus");
	EndIf;
	
	Return Filter;
	
EndFunction
 
#EndRegion