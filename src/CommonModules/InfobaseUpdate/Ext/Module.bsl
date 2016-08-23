////////////////////////////////////////////////////////////////////////////////
// Infobase version update subsystem
// Server procedures and functions related to infobase update in the scenario where the configuration version is changed.
//
////////////////////////////////////////////////////////////////////////////////

#Region Interface

// Check if infobase update is required when changing the configuration version.
//
// Returns:
//   Boolean
//
Function InfobaseUpdateRequired() Export
	
	Return InfobaseUpdateInternalCached.InfobaseUpdateRequired();
	
EndFunction

// Returns True if the infobase is being updated.
//
// Returns:
//   Boolean
//
Function ExecutingInfobaseUpdate() Export
	
	If CommonUseCached.DataSeparationEnabled()
		And Not CommonUseCached.CanUseSeparatedData() Then
		Return InfobaseUpdateRequired();
	EndIf;
	
	Return SessionParameters.InfobaseUpdateInProgress;
	
EndFunction

// Returns an empty table of update handlers and initial infobase filling handlers.
//
// Returns:
//   ValueTable - table with columns:
//     * InitialFilling          - Boolean  - if True, the handler is executed in an empty infobase only.
//     * Version                 - String   - for example, 2.1.3.39. Configuration version number. The handler is executed when
//                                            the configuration is updated to this version number. If an empty string is specified,
//                                            this handler is intended for initial filling only (when the InitialFilling parameter 
//                                            is specified).
//     * Procedure               - String   - full name of the update handler or initial infobase filling handler. For example,
//                                            MEMInfobaseUpdate.FillNewAttribute. This must be an export procedure.
//
//     * ExecuteInMandatoryGroup - Boolean  - specify this parameter if the handler must be executed in the group that contains
//                                            handlers for version "*". You can change the order of handlers in the group 
//                                            by changing their priorities.
//     * Priority                - Number   - for internal use.
//
//     * SharedData              - Boolean  - If True, the handler is executed before any handlers that use separated data.
//     * HandlerManagement       - Boolean  - If True, the handler has a parameter of structure type with SeparatedHandlers property, 
//                                            which is a value table that stores the structure returned by this function. 
//                                            In this case the version column is ignored. If separated handler execution is required, 
//                                            you have to add a row with the description of the handler procedure.
//                                            This only makes sense for mandatory (Version = "*") update handlers with SharedData flag.
//     * Comment                  - String  - description of actions performed by the update handler.
//     * ExecutionMode            - String  - update handler execution mode. Valid values: Exclusive, Deferred, Nonexclusive.
//                                            If this value is not specified, the handler is considered exclusive.
//     * ExclusiveMode            - Undefined, Boolean - If Undefined, the handler is executed unconditionally in exclusive mode.
//                                              For handlers of update to specific versions (Version <> "*"):
//                                                False - handler execution does not require exclusive mode.
//                                                True  - handler execution requires exclusive mode. 
//                                              For mandatory update handlers (Version = "*"):
//                                                False - handler execution does not require exclusive mode.
//                                                True  - handler execution might require exclusive mode. A parameter of structure
//                                                   type with ExclusiveMode property (of Boolean type) is passed to such handlers. 
//                                                   To execute the handler in exclusive mode, set this parameter to True.
//                                                   In this case the handler must perform the required update operations.
//                                                   Changing the parameter in the handler body is ignored. 
//                                                   To execute the handler in nonexclusive mode, set this parameter to False.
//                                                   In this case the handler must not make any changes to the infobase.
//                                                   If the analysis shows that the handler requires changing infobase data,
//                                                   set the parameter to True and stop the handler execution.
//                                                   In this case nonexclusive infobase update is canceled and an error message
//                                                   with a recommendation to perform the update in exclusive mode is displayed.
//
Function NewUpdateHandlerTable() Export
	
	Handlers = New ValueTable;
	// Main properties
	Handlers.Columns.Add("InitialFilling", New TypeDescription("Boolean"));
	Handlers.Columns.Add("Version",        New TypeDescription("String", New StringQualifiers(0)));
	Handlers.Columns.Add("Procedure",      New TypeDescription("String", New StringQualifiers(0)));
	Handlers.Columns.Add("Comment",        New TypeDescription("String", New StringQualifiers(0)));
	Handlers.Columns.Add("ExecutionMode",  New TypeDescription("String"));
	// Additional properties (for libraries)
	Handlers.Columns.Add("ExecuteInMandatoryGroup", New TypeDescription("Boolean"));
	Handlers.Columns.Add("Priority",                New TypeDescription("Number", New NumberQualifiers(2)));
	// Service model support
	Handlers.Columns.Add("SharedData",              New TypeDescription("Boolean"));
	Handlers.Columns.Add("HandlerManagement",       New TypeDescription("Boolean"));
	Handlers.Columns.Add("ExclusiveMode");
 
    // Obsolete. Reverse compatibility to revision "2.2".
	Handlers.Columns.Add("Optional");
	
	Return Handlers;
	
EndFunction

// Executes handlers from the UpdateHandlers list for LibraryID library update to InfobaseMetadataVersion version.
//
// LibraryID
//   Parameters              - String - configuration name or library ID.
//   InfobaseMetadataVersion - String - metadata version. The configuration or library is updated to this version.
//   UpdateHandlers          - Map    - update handler list.
//
// Returns:
//   ValueTree - executed update handlers.
//
Function ExecuteUpdateIteration(Val LibraryID, Val InfobaseMetadataVersion, 
	Val UpdateHandlers, Val HandlerExecutionProgress, Val NonexclusiveUpdate = False) Export
	
	UpdateIteration = InfobaseUpdateInternal.UpdateIteration(LibraryID, 
		InfobaseMetadataVersion, UpdateHandlers);
		
	Parameters = New Structure;
	Parameters.Insert("HandlerExecutionProgress", HandlerExecutionProgress);
	Parameters.Insert("NonexclusiveUpdate", NonexclusiveUpdate);
	Parameters.Insert("InBackground", False);
	
	Return InfobaseUpdateInternal.ExecuteUpdateIteration(UpdateIteration, 
		HandlerExecutionProgress, NonexclusiveUpdate);
	
EndFunction

// Execute noninteractive infobase update.
// This function is intended for calling through an external connection.
// 
// For use in other libraries and configurations.
//
// Returns:
//  String - descriptor that shows whether the update handlers are executed:
//           CHECK ON TEST
//           "Done", "NotRequired", "ExclusiveModeSettingError".
//
Function ExecuteInfobaseUpdate() Export
	
	Return InfobaseUpdateInternal.ExecuteInfobaseUpdate();
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for use in update handlers.
//

// Writes changes into the passed object.
// For use in update handlers.
//
// Parameters:
//   Data                        - Arbitrary - object, record set, or manager of the constant to be written.
//   RegisterOnExchangePlanNodes - Boolean   - enables registration in all of the exchange plan nodes when writing the object.
//   EnableBusinessLogic         - Boolean   - enables the use of business logic when writing the object.
//
Procedure WriteData(Val Data, Val RegisterOnExchangePlanNodes = False, 
	Val EnableBusinessLogic = False) Export
	
	Data.DataExchange.Load = Not EnableBusinessLogic;
	If Not RegisterOnExchangePlanNodes Then
		Data.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
		Data.DataExchange.Recipients.AutoFill = False;
	EndIf;
	
	Data.Write();
	
EndProcedure

// Deletes the passed object.
// For use in update handlers.
//
// Parameters:
//  Data                        - Arbitrary - object to be deleted.
//  RegisterOnExchangePlanNodes - Boolean   - enables registration in all of the exchange plan nodes when writing the object.
//  EnableBusinessLogic         - Boolean   - enables the use of business logic when writing the object.
//
Procedure DeleteData(Val Data, Val RegisterOnExchangePlanNodes = False, 
	Val EnableBusinessLogic = False) Export
	
	Data.DataExchange.Load = Not EnableBusinessLogic;
	If Not RegisterOnExchangePlanNodes Then
		Data.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
		Data.DataExchange.Recipients.AutoFill = False;
	EndIf;
	
	Data.Delete();
	
EndProcedure

// Returns a string constant for the generation of event log messages.
//
// Returns:
//   String
//
Function EventLogMessageText() Export
	
	Return InfobaseUpdateInternal.EventLogMessageText();
	
EndFunction

// Get configuration or parent configuration (library) version that is stored in the infobase.
//
// Parameters:
//  LibraryID - String - configuration name or library ID.
//
// Returns:
//   String - version.
//
// Usage example:
//   InfobaseConfigurationVersion = InfobaseVersion(Metadata.Name);
//
Function InfobaseVersion(Val LibraryID) Export
	
	Return InfobaseUpdateInternal.InfobaseVersion(LibraryID);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Other procedures and functions.
//

// Returns a table of subsystem versions used in the configuration.
// The procedure is used in batch import and export of subsystem versions.
//
// Returns:
//   ValueTable - table with columns:
//     * SubsystemName  - String - subsystem name.
//     * Version        - String - subsystem version.
//
Function SubsystemVersions() Export

	Query = New Query;
	Query.Text =
	"SELECT
	|	SubsystemVersions.SubsystemName AS SubsystemName,
	|	SubsystemVersions.Version AS Version
	|FROM
	|	InformationRegister.SubsystemVersions AS SubsystemVersions";
	
	Return Query.Execute().Unload();

EndFunction 

// Sets all subsystem versions.
// The procedure is used in batch import and export of subsystem versions.
//
// Parameters:
//   SubsystemVersions - ValueTable - table with columns:
//     * SubsystemName - String     - subsystem name.
//     * Version       - String     - subsystem version.
//
Procedure SetSubsystemVersions(SubsystemVersions) Export

	RecordSet = InformationRegisters.SubsystemVersions.CreateRecordSet();
	
	For Each Version In SubsystemVersions Do
		NewRecord = RecordSet.Add();
		NewRecord.SubsystemName = Version.SubsystemName;
		NewRecord.Version = Version.Version;
		NewRecord.IsMainConfiguration = (Version.SubsystemName = Metadata.Name);
	EndDo;
	
	RecordSet.Write();

EndProcedure

#EndRegion