////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
// Internal procedures and functions for working with the event log.
//  
////////////////////////////////////////////////////////////////////////////////

#Region Interface

// Procedure of the batch message recording to the event log.
// 
// Parameters:
//  EventsForEventLog - ValueList - global client variable. The variable is cleared
//                      once the events are recorded.
//
Procedure WriteEventsToEventLog(EventsForEventLog) Export
	
	If TypeOf(EventsForEventLog) <> Type("ValueList") Then
		Return;
	EndIf;	
	
	If EventsForEventLog.Count() = 0 Then
		Return;
	EndIf;
	
	For Each LogMessage In EventsForEventLog Do
		MessagesValue = LogMessage.Value;
		EventName = MessagesValue.EventName;
		EventLevel = EventLevelByPresentation(MessagesValue.LevelPresentation);
		EventDate = CurrentSessionDate();
		If MessagesValue.Property("EventDate") And ValueIsFilled(MessagesValue.EventDate) Then
			EventDate = MessagesValue.EventDate;
		EndIf;
		Comment = String(EventDate) + " " + MessagesValue.Comment;
		WriteLogEvent(EventName, EventLevel,,, Comment);
	EndDo;
	EventsForEventLog.Clear();
	
EndProcedure

#EndRegion

#Region InternalInterface

// Reads event log message texts taking into account the filter settings.
//
// Parameters:
//
//     ReportParameters - Structure - contains parameters for reading event log
//                        message texts. Includes the following fields:
//                        * Log                    - ValueTable - contains event log 
//                                                   records.
//                        * EventLogFilterAtClient - Structure - contains filter
//                                                   settings for reading event log
//                                                   message texts.
//                        * EventCount             - Number - limits the number of
//                                                   event log message texts to be
//                                                   read.
//                        * UUID                   - UUID - unique form ID.
//                        * OwnerManager           - Arbitrary - Event log is
//                                                   displayed on the form of this 
//                                                   object. The manager is used to
//                                                   call back appearance functions.
//                        * AddAdditionalColumns   - Boolean - flag that shows whether 
//                                                   a callback is required for adding 
//                                                   additional columns.
//     StorageAddress   - String, UUID - temporary storage address where the result is
//                        placed.
//
// Result is a structure with the following fields:
//     LogEvents - ValueTable - selected events.
//
Procedure ReadEventLogEvents(ReportParameters, StorageAddress) Export
	
	Log                    = ReportParameters.Log;
	EventLogFilterAtClient = ReportParameters.EventLogFilter;
	EventCount             = ReportParameters.EventCountLimit;
	UUID                   = ReportParameters.UUID;
	OwnerManager           = ReportParameters.OwnerManager;
	AddAdditionalColumns   = ReportParameters.AddAdditionalColumns;
	
	// Verifying the parameters
	StartDate = Undefined;
	EndDate   = Undefined;
	FilterDatesSpecified= EventLogFilterAtClient.Property("StartDate", StartDate) And EventLogFilterAtClient.Property("EndDate", EndDate)
		And ValueIsFilled(StartDate) And ValueIsFilled(EventLogFilterAtClient.EndDate);
		
	If FilterDatesSpecified And StartDate > EndDate Then
		Raise NStr("en = 'The event log filter parameters are specified incorrectly. Start date exceeds End date.'");
	EndIf;
	
	// Preparing the filter
	Filter = New Structure;
	For Each FilterItem In EventLogFilterAtClient Do
		Filter.Insert(FilterItem.Key, FilterItem.Value);
	EndDo;
	FilterTransform(Filter);
	
	// Exporting the selected events and generating the table structure
	LogEvents = New ValueTable;
	UnloadEventLog(LogEvents, Filter, , , EventCount);
	
	LogEvents.Columns.Add("PictureNumber", New TypeDescription("Number"));
	LogEvents.Columns.Add("DataAddress",  New TypeDescription("String"));
	
	If CommonUseCached.CanUseSeparatedData() Then
		LogEvents.Columns.Add("SessionDataSeparation", New TypeDescription("String"));
		LogEvents.Columns.Add("SessionDataSeparationPresentation", New TypeDescription("String"));
	EndIf;
	
	If AddAdditionalColumns Then
		OwnerManager.AddAdditionalEventColumns(LogEvents);
	EndIf;
	
	If CommonUseCached.DataSeparationEnabled()
	   And CommonUseCached.CanUseSeparatedData()
	   And CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations") Then
		
		SaaSOperationsModule = CommonUse.CommonModule("SaaSOperations");
		UserAliases          = New Map();
	Else
		SaaSOperationsModule = Undefined;
		UserAliases          = Undefined;
	EndIf;
	
	For Each LogEvent In LogEvents Do
		// Filling numbers of row pictures
		OwnerManager.SetPictureNumber(LogEvent);
		
		If AddAdditionalColumns Then
			// Filling additional fields that are defined for the owner only
			OwnerManager.FillAdditionalEventColumns(LogEvent);
		EndIf;
		
		// Converting the array of metadata into a value list
		MetadataPresentationList = New ValueList;
		If TypeOf(LogEvent.MetadataPresentation) = Type("Array") Then
			MetadataPresentationList.LoadValues(LogEvent.MetadataPresentation);
			LogEvent.MetadataPresentation = MetadataPresentationList;
		Else
			LogEvent.MetadataPresentation = String(LogEvent.MetadataPresentation);
		EndIf;
		
		// Converting the SessionDataSeparationPresentation array into a value list
		If CommonUseCached.DataSeparationEnabled()
			And Not CommonUseCached.CanUseSeparatedData() Then
			FullSessionDataSeparationPresentation = "";
			
			SessionDataSeparation = LogEvent.SessionDataSeparation;
			SeparatedDataAttributeList = New ValueList;
			For Each SessionSeparator In SessionDataSeparation Do
				SeparatorPresentation = Metadata.CommonAttributes.Find(SessionSeparator.Key).Synonym;
				SeparatorPresentation = SeparatorPresentation + " = " + SessionSeparator.Value;
				SeparatorValue = SessionSeparator.Key + "=" + SessionSeparator.Value;
				SeparatedDataAttributeList.Add(SeparatorValue, SeparatorPresentation);
				FullSessionDataSeparationPresentation = ?(Not IsBlankString(FullSessionDataSeparationPresentation),
				                                            FullSessionDataSeparationPresentation + "; ", "") +
				                                            SeparatorPresentation;
			EndDo;
			LogEvent.SessionDataSeparation = SeparatedDataAttributeList;
			LogEvent.SessionDataSeparationPresentation = FullSessionDataSeparationPresentation;
		EndIf;
		
		// Processing special event data
		If LogEvent.Event = "_$Access$_.Access" Then
			SetDataAddressString(LogEvent);
			
			If LogEvent.Data <> Undefined Then
				LogEvent.Data = ?(LogEvent.Data.Data = Undefined, "", "...");
			EndIf;
			
		ElsIf LogEvent.Event = "_$Access$_.AccessDenied" Then
			SetDataAddressString(LogEvent);
			
			If LogEvent.Data <> Undefined Then
				If LogEvent.Data.Property("Right") Then
					LogEvent.Data = StringFunctionsClientServer.SubstituteParametersInString(
						NStr("en = 'Right: %1'"), 
						LogEvent.Data.Right);
				Else
					LogEvent.Data = StringFunctionsClientServer.SubstituteParametersInString(
						NStr("en = 'Action: 1%2'"), 
						LogEvent.Data.Action, ?(LogEvent.Data.Data = Undefined, "", ", ...") );
				EndIf;
			EndIf;
			
		ElsIf LogEvent.Event = "_$Session$_.Authentication"
		      Or LogEvent.Event = "_$Session$_.AuthenticationError" Then
			
			SetDataAddressString(LogEvent);
			
			LogEventData = "";
			If LogEvent.Data <> Undefined Then
				For Each KeyAndValue In LogEvent.Data Do
					If ValueIsFilled(LogEventData) Then
						LogEventData = LogEventData + ", ...";
						Break;
					EndIf;
					LogEventData = KeyAndValue.Key + ": " + KeyAndValue.Value;
				EndDo;
			EndIf;
			LogEvent.Data = LogEventData;
			
		ElsIf LogEvent.Event = "_$User$_.Delete" Then
			SetDataAddressString(LogEvent);
			
			LogEventData = "";
			If LogEvent.Data <> Undefined Then
				For Each KeyAndValue In LogEvent.Data Do
					LogEventData = KeyAndValue.Key + ": " + KeyAndValue.Value;
					Break;
				EndDo;
			EndIf;
			LogEvent.Data = LogEventData;
			
		ElsIf LogEvent.Event = "_$User$_.New"
		      Or LogEvent.Event = "_$User$_.Update" Then
			SetDataAddressString(LogEvent);
			
			InfobaseUserName = "";
			If LogEvent.Data <> Undefined Then
				LogEvent.Data.Property("Name", InfobaseUserName);
			EndIf;
			LogEvent.Data = StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'the: %1 name ...'"),
				InfobaseUserName);
			
		EndIf;
		
		SetPrivilegedMode(True);
		// Processing special user name values
		If LogEvent.User = New UUID("00000000-0000-0000-0000-000000000000") Then
			LogEvent.UserName = NStr("en = '<Undefined>'");
			
		ElsIf LogEvent.UserName = "" Then
			LogEvent.UserName = Users.UnspecifiedUserFullName();
			
		ElsIf InfobaseUsers.FindByUUID(LogEvent.User) = Undefined Then
			LogEvent.UserName = StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = '%1 <Deleted>'"),
				LogEvent.UserName);
		EndIf;
		
		If SaaSOperationsModule <> Undefined Then
			If UserAliases.Get(LogEvent.User) = Undefined Then
				UserAlias = SaaSOperationsModule.InfobaseUserAlias(LogEvent.User);
				UserAliases.Insert(LogEvent.User, UserAlias);
			Else
				UserAlias = UserAliases.Get(LogEvent.User);
			EndIf;
			
			If ValueIsFilled(UserAlias) Then
				LogEvent.UserName = UserAlias;
			EndIf;
		EndIf;
		
			// Converting the UUID into a name. Further this name will be used in filter settings.
		LogEvent.User = InfobaseUsers.FindByUUID(LogEvent.User);
		SetPrivilegedMode(False);
	EndDo;
	
	// Processing is completed
	Result = New Structure;
	Result.Insert("LogEvents", LogEvents);
	
	PutToTempStorage(Result, StorageAddress);
EndProcedure

// Creates a custom event log presentation.
//
// Parameters:
//  FilterPresentation    - String - contains a custom filter presentation.
//  EventLogFilter        - Structure - contains event log filter values.
//  DefaultEventLogFilter - Structure - contains the default event log filter values.
//                          (Default filter value is not included in the custom 
//                          presentation).
//
Procedure GenerateFilterPresentation(FilterPresentation, EventLogFilter, 
		DefaultEventLogFilter = Undefined) Export
	
	FilterPresentation = "";
	// Interval
	IntervalStartDate    = Undefined;
	IntervalEndDate = Undefined;
	If Not EventLogFilter.Property("StartDate", IntervalStartDate)
		Or IntervalStartDate = Undefined Then
		IntervalStartDate    = '00010101000000';
	EndIf;
	
	If Not EventLogFilter.Property("EndDate", IntervalEndDate)
		Or IntervalEndDate = Undefined Then
		IntervalEndDate = '00010101000000';
	EndIf;
	
	If Not (IntervalStartDate = '00010101000000' And IntervalEndDate = '00010101000000') Then
		FilterPresentation = PeriodPresentation(IntervalStartDate, IntervalEndDate);
	EndIf;
	
	AddRestrictionToFilterPresentation(EventLogFilter, FilterPresentation, "User");
	AddRestrictionToFilterPresentation(EventLogFilter, FilterPresentation,
		"Event", DefaultEventLogFilter);
	AddRestrictionToFilterPresentation(EventLogFilter, FilterPresentation,
		"ApplicationName", DefaultEventLogFilter);
	AddRestrictionToFilterPresentation(EventLogFilter, FilterPresentation, "Session");
	AddRestrictionToFilterPresentation(EventLogFilter, FilterPresentation, "Level");
	
	// All other restrictions are specified by presentations without values
	For Each FilterItem In EventLogFilter Do
		RestrictionName = FilterItem.Key;
		If Upper(RestrictionName) = Upper("StartDate")
			Or Upper(RestrictionName) = Upper("EndDate")
			Or Upper(RestrictionName) = Upper("Event")
			Or Upper(RestrictionName) = Upper("ApplicationName")
			Or Upper(RestrictionName) = Upper("User")
			Or Upper(RestrictionName) = Upper("Session")
			Or Upper(RestrictionName) = Upper("Level") Then
			Continue; // Interval and special restrictions are already displayed
		EndIf;
		
		// Changing restrictions for some of presentations
		If Upper(RestrictionName) = Upper("ApplicationName") Then
			RestrictionName = NStr("en = 'Application'");
		ElsIf Upper(RestrictionName) = Upper("TransactionStatus") Then
			RestrictionName = NStr("en = 'Transaction status'");
		ElsIf Upper(RestrictionName) = Upper("DataPresentation") Then
			RestrictionName = NStr("en = 'Data presentation'");
		ElsIf Upper(RestrictionName) = Upper("ServerName") Then
			RestrictionName = NStr("en = 'Server name'");
		ElsIf Upper(RestrictionName) = Upper("Port") Then
			RestrictionName = NStr("en = 'Port'");
		ElsIf Upper(RestrictionName) = Upper("SyncPort") Then
			RestrictionName = NStr("en = 'Sync port'");
		ElsIf Upper(RestrictionName) = Upper("SessionDataSeparation") Then
			RestrictionName = NStr("en = 'Session data separation'");
		EndIf;
		
		If Not IsBlankString(FilterPresentation) Then 
			FilterPresentation = FilterPresentation + "; ";
		EndIf;
		FilterPresentation = FilterPresentation + RestrictionName;
		
	EndDo;
	
	If IsBlankString(FilterPresentation) Then
		FilterPresentation = NStr("en = 'Not defined'");
	EndIf;
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

// Filter conversion.
//
// Parameters:
//  Filter - Filter - passed filter.
//
Procedure FilterTransform(Filter)
	
	For Each FilterItem In Filter Do
		If TypeOf(FilterItem.Value) = Type("ValueList") Then
			FilterItemTransform(Filter, FilterItem);
		ElsIf Upper(FilterItem.Key) = Upper("TransactionID") Then
			If Find(FilterItem.Value, "(") = 0 Then
				Filter.Insert(FilterItem.Key, "(" + FilterItem.Value);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Filter item conversion.
//
// Parameters:
//  Filter     - Filter - passed filter.
//  FilterItem - Filter item - passed filter item.
//
Procedure FilterItemTransform(Filter, FilterItem)
	
	FilterStructureKey = FilterItem.Key;
	// Is called if a filter item is a value list.
	// Transforms the value list into an array because the filter cannot process a list.
	If Upper(FilterStructureKey) = Upper("SessionDataSeparation") Then
		NewValue = New Structure;
	Else
		NewValue = New Array;
	EndIf;
	
	FilterStructureKey = FilterItem.Key;
	
	For Each ValueFromList In FilterItem.Value Do
		If Upper(FilterStructureKey) = Upper("Level") Then
			// Message text level is a string, it must be converted into an enumeration
			NewValue.Add(DataProcessors.EventLog.EventLogLevelValueByName(ValueFromList.Value));
		ElsIf Upper(FilterStructureKey) = Upper("TransactionStatus") Then
			// Transaction status is a string, it must be converted into an enumeration
			NewValue.Add(DataProcessors.EventLog.EventLogEntryTransactionStatusValueByName(ValueFromList.Value));
		ElsIf Upper(FilterStructureKey) = Upper("SessionDataSeparation") Then
			SeparatorValueArray = New Array;
			FilterStructureKey = "SessionDataSeparation";
			DataSeparationArray = StringFunctionsClientServer.SplitStringIntoSubstringArray(ValueFromList.Value, "=");
			
			SeparatorValues = StringFunctionsClientServer.SplitStringIntoSubstringArray(DataSeparationArray[1], ",");
			For Each SeparatorValue In SeparatorValues Do
				SeparatorFilterItem = New Structure("Value, Use", Number(SeparatorValue), True);
				SeparatorValueArray.Add(SeparatorFilterItem);
			EndDo;
			
			NewValue.Insert(DataSeparationArray[0], SeparatorValueArray);
			
		Else
			NewValue.Add(ValueFromList.Value);
		EndIf;
	EndDo;
	
	Filter.Insert(FilterItem.Key, NewValue);
	
EndProcedure

// Adds a restriction to the filter presentation.
//
// Parameters:
//  EventLogFilter        - Filter - event log filter.
//  FilterPresentation    - String - filter presentation.
//  RestrictionName       - String - restriction name.
//  DefaultEventLogFilter - Filter - default event log filter.
//
Procedure AddRestrictionToFilterPresentation(EventLogFilter, FilterPresentation, RestrictionName,
	DefaultEventLogFilter = Undefined)
	
	RestrictionList = "";
	Restriction = "";
	
	If EventLogFilter.Property(RestrictionName, RestrictionList) Then
		
		// If filter value is a default value there is no need to get a presentation of it
		If DefaultEventLogFilter <> Undefined Then
			DefaultRestrictionList = "";
			If DefaultEventLogFilter.Property(RestrictionName, DefaultRestrictionList) 
				And CommonUseClientServer.ValueListsEqual(DefaultRestrictionList, RestrictionList) Then
				Return;
			EndIf;
		EndIf;
		
		If RestrictionName = "Event" And RestrictionList.Count() > 5 Then
			
			Restriction = FilterPresentation + StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Events (%1)'"), RestrictionList.Count());
			
		ElsIf RestrictionName = "Session" And RestrictionList.Count() > 3 Then
			
			Restriction = StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Sessions (%1)'"), RestrictionList.Count());
			
		Else
			
			For Each ListItem In RestrictionList Do
				
				If Not IsBlankString(Restriction) Then
					Restriction = Restriction + ", ";
				EndIf;
				
				If (Upper(RestrictionName) = Upper("Session")
				Or Upper(RestrictionName) = Upper("Level"))
				And IsBlankString(Restriction) Then
				
					Restriction = NStr("en = '[RestrictionName]: [Value]'");
					Restriction = StrReplace(Restriction, "[Value]", ListItem.Value);
					Restriction = StrReplace(Restriction, "[RestrictionName]", RestrictionName);
					
				ElsIf Upper(RestrictionName) = Upper("Session")
				Or Upper(RestrictionName) = Upper("Level")Then
					Restriction = Restriction + ListItem.Value;
				Else
					Restriction = Restriction + ListItem.Presentation;
				EndIf;
				
			EndDo;
			
		EndIf;
		
		If Not IsBlankString(FilterPresentation) Then 
			FilterPresentation = FilterPresentation + "; ";
		EndIf;
		
		FilterPresentation = FilterPresentation + Restriction;
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// INTERNAL PROCEDURES AND FUNCTIONS

// For internal use only.
//
Procedure PutDataToTempStorage(LogEvents, UUID) Export
	
	For Each EventRow In LogEvents Do
		If IsBlankString(EventRow.DataAddress) Then
			DataAddress = "";
		Else
			XMLReader= New XMLReader();
			XMLReader.SetString(EventRow.DataAddress);
			DataAddress = XDTOSerializer.ReadXML(XMLReader);
		EndIf;
		EventRow.DataAddress = PutToTempStorage(DataAddress, UUID);
	EndDo;
	
EndProcedure

// For internal use only
//
Procedure SetDataAddressString(LogEvent)
	
	XMLWriter = New XMLWriter();
	XMLWriter.SetString();
	XDTOSerializer.WriteXML(XMLWriter, LogEvent.Data); 
	LogEvent.DataAddress = XMLWriter.Close();
	
EndProcedure

Function EventLevelByPresentation(LevelPresentation)
	If LevelPresentation = "Information" Then
		Return EventLogLevel.Information;
	ElsIf LevelPresentation = "Error" Then
		Return EventLogLevel.Error;
	ElsIf LevelPresentation = "Warning" Then
		Return EventLogLevel.Warning; 
	ElsIf LevelPresentation = "Note" Then
		Return EventLogLevel.Note;
	EndIf;	
EndFunction

#EndRegion
