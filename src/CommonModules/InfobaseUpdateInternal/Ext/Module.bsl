////////////////////////////////////////////////////////////////////////////////
// Infobase version update subsystem.
// Server procedures and functions related to infobase updates
// in the scenario where the configuration version is changed.
//
////////////////////////////////////////////////////////////////////////////////

#Region InternalInterface

// Declares InfobaseVersionUpdate subsystem events:
//
// Server events:
//   OnAddUpdateHandlers,
//   BeforeInfobaseUpdate,
//   AfterInfobaseUpdate.
//
// See the description of this procedure in the StandardSubsystemsServer module.
Procedure OnAddInternalEvent(ClientEvents, ServerEvents) Export
	
	// SERVER EVENTS
	
	// Adds update handlers that are required by the subsystem.
	//
	// Parameters:
	//  Handlers - ValueTable - see the description of NewUpdateHandlerTable function in the InfobaseUpdate common module.
	//
	// Syntax:
	// Procedure OnAddUpdateHandlers(Handlers) Export
	//
	// For use in other libraries.
	//
	// (Identical to function InfobaseUpdateOverridable.UpdateHandlers).
	ServerEvents.Add(
		"StandardSubsystems.InfobaseVersionUpdate\OnAddUpdateHandlers");
	
	// Called prior to the infobase data update handlers.
	//
	// Syntax:
	// Procedure BeforeInfobaseUpdate() Export
	//
	// (Identical to function InfobaseUpdateOverridable.BeforeInfobaseUpdate).
	//
	ServerEvents.Add("StandardSubsystems.InfobaseVersionUpdate\InfobaseBeforeUpdate");
	
	// Called after an exclusive infobase version update is complete.
	// 
	// Parameters:
	//   PreviousVersion  - String - subsystem version before update. "0.0.0.0" for an empty infobase.
	//   CurrentVersion   - String - subsystem version after update.
	//   ExecutedHandlers - ValueTree - the list of executed subsystem update handler procedures 
	//                                  grouped by version number.
	//                      Procedure for iteration through executed handlers:
	//
	// For Each Version In CompletedHandlers.Rows Do
	//		
	// 	If Version.Version
	// 		 = "*" Then 
	//      // Handler that is executed with each version change
	// 	Else
	// 		 // Handler that is executed for a certain version
	// 	EndIf;
	//		
	// 	For Each Handler In Version.Rows
	// 		Do ...
	// 	EndDo;
	//		
	// EndDo;
	//
	//   ShowUpdateDetails - Boolean (return value) - if True, the update description form is displayed.
	//   ExclusiveMode     - Boolean - flag specifying whether the update was performed in
	//                       exclusive mode.
	//                                 
	//
	// Syntax:
	// Procedure AfterInfobaseUpdate(Val PreviousVersion,
	// 		Val CurrentVersion, Val ExecutedHandlers, ShowUpdateDetails, ExclusiveMode) Export
	//
	// (Identical to function InfobaseUpdateOverridable.AfterInfobaseUpdate).
	//
	ServerEvents.Add("StandardSubsystems.InfobaseVersionUpdate\AfterInfobaseUpdate");
	
EndProcedure

// See the description of this procedure in the StandardSubsystemsServer module.
Procedure InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers) Export
	
	// CLIENT HANDLERS.
	
	ClientHandlers["StandardSubsystems.BaseFunctionality\AfterStart"].Add(
		"InfobaseUpdateClient");
	
	ClientHandlers["StandardSubsystems.BaseFunctionality\OnStart"].Add(
		"InfobaseUpdateClient");
	
	// SERVER HANDLERS
	
	ServerHandlers["StandardSubsystems.InfobaseVersionUpdate\OnAddUpdateHandlers"].Add(
		"InfobaseUpdateInternal");
	
	ServerHandlers["StandardSubsystems.BaseFunctionality\OnSendDataToSlave"].Add(
		"InfobaseUpdateInternal");
	
	ServerHandlers["StandardSubsystems.BaseFunctionality\OnSendDataToMaster"].Add(
		"InfobaseUpdateInternal");
	
	ServerHandlers["StandardSubsystems.BaseFunctionality\OnAddStandardSubsystemClientLogicParametersOnStart"].Add(
		"InfobaseUpdateInternal");
	
	ServerHandlers["StandardSubsystems.BaseFunctionality\OnGetMandatoryExchangePlanObjects"].Add(
		"InfobaseUpdateInternal");
	
	ServerHandlers["StandardSubsystems.BaseFunctionality\OnGetExchangePlanInitialImageObjects"].Add(
		"InfobaseUpdateInternal");
	
	ServerHandlers["StandardSubsystems.BaseFunctionality\SessionParameterSettingHandlersOnAdd"].Add(
		"InfobaseUpdateInternal");
	
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.JobQueue") Then
		ServerHandlers[
			"StandardSubsystems.SaaSOperations.JobQueue\OnReceiveTemplateList"].Add(
				"InfobaseUpdateInternal");
	EndIf;
	
	ServerHandlers["StandardSubsystems.BaseFunctionality\ExchangePlanObjectsToExcludeOnGet"].Add(
		"InfobaseUpdateInternal");
	
	If CommonUse.SubsystemExists("StandardSubsystems.ToDoList") Then
		ServerHandlers["StandardSubsystems.ToDoList\OnFillToDoList"].Add(
			"InfobaseUpdateInternal");
	EndIf;
	
EndProcedure

// Initializes the InfobaseUpdateInProgress session parameter.
//
Procedure SessionParametersSetting(Val ParameterName, SpecifiedParameters) Export
	
	If ParameterName <> "InfobaseUpdateInProgress" Then
		Return;
	EndIf;
	
	SessionParameters.InfobaseUpdateInProgress = InfobaseUpdate.InfobaseUpdateRequired();
	SpecifiedParameters.Add("InfobaseUpdateInProgress");
	
EndProcedure

// Checks whether it is necessary to update the shared infobase data during configuration version change.
//
Function SharedInfobaseDataUpdateRequired() Export
	
	SetPrivilegedMode(True);
	
	If CommonUseCached.DataSeparationEnabled() Then
		
		MetadataVersion = Metadata.Version;
		If IsBlankString(MetadataVersion) Then
			MetadataVersion = "0.0.0.0";
		EndIf;
		
		SharedDataVersion = InfobaseVersion(Metadata.Name, True);
		
		If UpdateRequired(MetadataVersion, SharedDataVersion) Then
			Return True;
		EndIf;
		
		If Not CommonUseCached.CanUseSeparatedData() Then
			
			SetPrivilegedMode(True);
			Run = SessionParameters.ClientParametersOnServer.Get("StartInfobaseUpdate");
			SetPrivilegedMode(False);
			
			If Run <> Undefined And CanUpdateInfobase() Then
				Return True;
			EndIf;
		EndIf;
	EndIf;
	
	Return False;
	
EndFunction

// Returns a string containing infobase lock reasons in case the
// current user has insufficient rights to update the infobase; returns an empty string otherwise.
//  
// Parameters:
//  ForPrivilegedMode - Boolean - if set to False, privileged mode
//                                    is ignored when verifying rights of the current user.
//  
// Returns:
//  String - empty string if the infobase is not locked, message containing infobase lock reason otherwise.
// 
Function InfobaseLockedForUpdate(ForPrivilegedMode = True) Export
	
	Message = "";
	
	CurrentInfobaseUser = InfobaseUsers.CurrentUser();
	
	// Administration rights are sufficient to access a locked infobase.
	If ForPrivilegedMode Then
		HasRightToAdministrate = AccessRight("Administration", Metadata);
	Else
		HasRightToAdministrate = AccessRight("Administration", Metadata, CurrentInfobaseUser);
	EndIf;
	
	MessageForSystemAdministrator =
		NStr("en = 'Cannot log on to the application while version update is in progress.
		           |Administrative-level rights (System administrator and Full rights roles)
		           |are required to complete the version update.'");
	
	SetPrivilegedMode(True);
	DataSeparationEnabled = CommonUseCached.DataSeparationEnabled();
	CanUseSeparatedData = CommonUseCached.CanUseSeparatedData();
	SetPrivilegedMode(False);
	
	If SharedInfobaseDataUpdateRequired() Then
		
		MessageForDataAreaAdministrator =
			NStr("en = 'Cannot log on to the application while version update is in progress.
			           |For more information, please contact the service administrator.'");
		
		If CanUseSeparatedData Then
			Message = MessageForDataAreaAdministrator;
			
		ElsIf Not CanUpdateInfobase(ForPrivilegedMode, False) Then
			
			If HasRightToAdministrate Then
				Message = MessageForSystemAdministrator;
			Else
				Message = MessageForDataAreaAdministrator;
			EndIf;
		EndIf;
		
		Return Message;
	EndIf;
	
	// No message is sent to the service administrator
	If DataSeparationEnabled And Not CanUseSeparatedData Then
		Return "";
	EndIf;
		
	If CanUpdateInfobase(ForPrivilegedMode, True) Then
		Return "";
	EndIf;
	
	RepeatedDataExchangeMessageImportBeforeStartRequired = False;
	If CommonUse.IsSubordinateDIBNode()
	   And CommonUse.SubsystemExists("StandardSubsystems.DataExchange") Then
		
		DataExchangeServerCallModule = CommonUse.CommonModule("DataExchangeServerCall");
		If DataExchangeServerCallModule.RetryDataExchangeMessageImportBeforeStart() Then
			RepeatedDataExchangeMessageImportBeforeStartRequired = True;
		EndIf;
	EndIf;
	
	If Not InfobaseUpdate.InfobaseUpdateRequired()
	   And Not MustCheckLegitimateSoftware()
	   And Not RepeatedDataExchangeMessageImportBeforeStartRequired Then
		Return "";
	EndIf;
	
	If HasRightToAdministrate Then
		Return MessageForSystemAdministrator;
	EndIf;

	If DataSeparationEnabled Then
		// Message to service user.
		Message =
			NStr("en = 'Cannot log on to the application while version update is in progress.
			           |For more information, please contact the service administrator.'");
	Else
		// Message to local mode user.
		Message =
			NStr("en = 'Cannot log on to the application while version update is in progress.
			           |Contact your administrator for details.'");
	EndIf;
	
	Return Message;
	
EndFunction

// Execute noninteractive infobase update.
// 
// Parameters:
// 
//  ExceptionWhenCannotLockInfobase - Boolean - if False, an unsuccessful attempt to set exclusive mode
//                                    does not raise an exception but returns 
//                                    "ExclusiveModeSettingError" string instead.
// 
//  OnClientStart - Boolean - False initially. If set
//                 to True, the application operating parameters are not updated, because
//                 on client start they are updated first (before user authorization and infobase update).
//                 This parameter is used to optimize the client
//                 start mode by avoiding repeated updates of application operating parameters.
//                 In case of external call (for example, in external
//                 connection session), application operating parameters must be updated before the infobase update can proceed.
// 
// Returns:
//  String -  descriptor that shows whether the update handlers are executed:
//           "Done", "NotRequired", "ExclusiveModeSettingError".
//
Function ExecuteInfobaseUpdate(ExceptionWhenCannotLockInfobase = True,
	Val OnClientStart = False, Restart = False, InfobaseLockSet = Undefined, InBackground = False) Export
	
	If Not OnClientStart Then
		Try
			StandardSubsystemsServer.ImportUpdateApplicationParameters();
		Except
			WriteError(DetailErrorDescription(ErrorInfo()));
			Raise;
		EndTry;
	EndIf;
	
	// Checking whether the configuration name is changed
	
	DataUpdateMode = DataUpdateMode();
	MetadataVersion = Metadata.Version;
	If IsBlankString(MetadataVersion) Then
		MetadataVersion = "0.0.0.0";
	EndIf;
	DataVersion = InfobaseVersion(Metadata.Name);
	
	// Before infobase update
	//
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.InfobaseVersionUpdateSaaS") Then
		InfobaseUpdateInternalSaaSModule = CommonUse.CommonModule("InfobaseUpdateInternalSaaS");
		InfobaseUpdateInternalSaaSModule.InfobaseBeforeUpdate();
		
		// Enabling privileged mode to allow infobase update SaaS,
		// in case the data area administrator accesses the area before it is fully updated
		If CommonUseCached.DataSeparationEnabled() And CommonUseCached.CanUseSeparatedData() Then
			SetPrivilegedMode(True);
		EndIf;
		
	EndIf;
	
	// Importing and exporting exchange messages after restart, as configuration changes are received
	If CommonUse.SubsystemExists("StandardSubsystems.DataExchange") Then
		DataExchangeServerModule = CommonUse.CommonModule("DataExchangeServer");
		DataExchangeServerModule.InfobaseBeforeUpdate(OnClientStart, Restart);
	EndIf;
		
	If Not InfobaseUpdate.InfobaseUpdateRequired() Then
		Return "NotRequired";
	EndIf;
	
	If InBackground Then
		CommonUseClientServer.MessageToUser("ProgressStep=15/5");
	EndIf;
	
	SubsystemDescriptions  = StandardSubsystemsCached.SubsystemDescriptions();
	For Each SubsystemName In SubsystemDescriptions.Order Do
		SubsystemDetails = SubsystemDescriptions.ByNames.Get(SubsystemName);
		If Not ValueIsFilled(SubsystemDetails.MainServerModule) Then
			Continue;
		EndIf;
		Module = CommonUse.CommonModule(SubsystemDetails.MainServerModule);
		Module.InfobaseBeforeUpdate();
	EndDo;
	InfobaseUpdateOverridable.InfobaseBeforeUpdate();
	
	// Verifying rights to update the infobase
	If Not CanUpdateInfobase() Then
		Message = NStr("en = 'Insufficient rights for application version update.'");
		WriteError(Message);
		Raise Message;
	EndIf;
	
	If DataUpdateMode = "MigrationFromAnotherApplication" Then
		Message = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Configuration name is changed to %1.
			           |Migration from another application will be performed.'"),
			Metadata.Name);
	ElsIf DataUpdateMode = "VersionUpdate" Then
		Message = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Configuration version number is changed from %1 to %2.
			           |Infobase update will be performed.'"),
			DataVersion, MetadataVersion);
	Else 
		Message = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Filling initial data for version %1.'"),
			MetadataVersion);
	EndIf;
	WriteInformation(Message);
	
	// Locking the infobase
	LockedAlready = InfobaseLockSet <> Undefined And InfobaseLockSet.Use;
	If LockedAlready Then
		UpdateIterations = UpdateIterations();
		InfobaseDataLock = InfobaseLockSet;
	Else
		InfobaseDataLock = Undefined;
		UpdateIterations = LockInfobase(InfobaseDataLock, ExceptionWhenCannotLockInfobase);
		If InfobaseDataLock.Error <> Undefined Then
			Return InfobaseDataLock.Error;
		EndIf;
	EndIf;
	
	NonexclusiveUpdate = InfobaseDataLock.NonexclusiveUpdate;
	RecordKey = InfobaseDataLock.RecordKey;
	
	Try
		
		If DataUpdateMode = "MigrationFromAnotherApplication" Then
			
			MigrateFromAnotherApplication();
			
			DataUpdateMode = DataUpdateMode();
			NonexclusiveUpdate = False;
			UpdateIterations = UpdateIterations();
		EndIf;
		
	Except
		
		If Not LockedAlready Then
			UnlockInfobase(InfobaseDataLock);
		EndIf;
		
		Raise;
	EndTry;
	
	If InBackground Then
		CommonUseClientServer.MessageToUser("ProgressStep=20/75");
	EndIf;
	
	Try
		
		Parameters = New Structure;
		Parameters.Insert("HandlerExecutionProgress", HandlerCountForCurrentVersion(UpdateIterations));
		Parameters.Insert("NonexclusiveUpdate", NonexclusiveUpdate);
		Parameters.Insert("InBackground", InBackground);
		
		// Executing all update handlers for configuration subsystems
		For Each UpdateIteration In UpdateIterations Do
			UpdateIteration.ExecutedHandlers = ExecuteUpdateIteration(UpdateIteration,	Parameters);
		EndDo;
		
		If InBackground Then
			CommonUseClientServer.MessageToUser("ProgressStep=95/5");
		EndIf;
		
		// During file infobase updates, the deferred handlers are executed in the primary update cycle
		If CommonUse.FileInfobase() And
			(Not CommonUseCached.DataSeparationEnabled()
			Or CommonUseCached.CanUseSeparatedData()) Then
			
			ScheduleDeferredUpdate(UpdateIterations);
			
			ClientLaunchParameter = SessionParameters.ClientParametersOnServer.Get("LaunchParameter");
			If Find(Lower(ClientLaunchParameter), Lower("DeferredUpdateDebug")) = 0 Then
				
				PerformDeferredUpdateNow();
				
			EndIf;
			
		EndIf;
		
	Except
		
		If Not LockedAlready Then
			UnlockInfobase(InfobaseDataLock);
		EndIf;
		
		Raise;
	EndTry;
	
	// Disabling the exclusive mode.
	If Not LockedAlready Then
		UnlockInfobase(InfobaseDataLock);
	EndIf;

	Message = StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en = 'The infobase is updated to version %1.'"), MetadataVersion);
	WriteInformation(Message);
	
	ShowUpdateDetails = (DataUpdateMode <> "InitialFilling");
	
	RefreshReusableValues();
	
	// After infobase update
	//
	ExecuteHandlersAfterInfobaseUpdate(
		UpdateIterations,
		Constants.WriteInfobaseUpdateDetailsToEventLog.Get(),
		ShowUpdateDetails,
		NonexclusiveUpdate);
	
	InfobaseUpdateOverridable.AfterInfobaseUpdate(
		DataVersion,
		MetadataVersion,
		UpdateIterations,
		ShowUpdateDetails,
		Not NonexclusiveUpdate);
	
	// Exporting the exchange message after restart, due to configuration changes received
	If CommonUse.SubsystemExists("StandardSubsystems.DataExchange") Then
		DataExchangeServerModule = CommonUse.CommonModule("DataExchangeServer");
		DataExchangeServerModule.AfterInfobaseUpdate();
	EndIf;
	
	// Scheduling execution of the deferred update handlers (for client-server infobases)
	If Not CommonUse.FileInfobase() Then
		
		If Not CommonUseCached.DataSeparationEnabled()
			Or CommonUseCached.CanUseSeparatedData() Then
			ScheduleDeferredUpdate(UpdateIterations);
		EndIf;
		
	EndIf;
	
	DefineUpdateDetailsDisplay(ShowUpdateDetails);
	
	// Clearing unsuccessful configuration update status in case of manual (without using scripts) update completion
	If CommonUse.SubsystemExists("StandardSubsystems.ConfigurationUpdate") Then
		ConfigurationUpdateModule = CommonUse.CommonModule("ConfigurationUpdate");
		ConfigurationUpdateModule.AfterInfobaseUpdate();
	EndIf;
	
	RefreshReusableValues();
	
	If CommonUseCached.DataSeparationEnabled()
		And CommonUseCached.CanUseSeparatedData() Then
		SessionParameters.InfobaseUpdateInProgress = False;
	EndIf;
	
	SetPrivilegedMode(True);
	StandardSubsystemsServer.SetInfobaseUpdateStartup(False);
	
	Return "Done";
	
EndFunction

// Gets configuration or parent configuration (library) version that is stored in the infobase.
//
// LibraryID
//  Parameters           - String  - configuration name or library ID.
//  GetCommonDataVersion - Boolean - if set to True, version in shared data is returned for SaaS.
//
// Returns:
//   String - version.
//
// Usage example:
//   InfobaseConfigurationVersion = InfobaseVersion(Metadata.Name);
//
Function InfobaseVersion(Val LibraryID, Val GetCommonDataVersion = False) Export
	
	SetPrivilegedMode(True);
	
	StandardProcessing = True;
	Result = "";
	
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.InfobaseVersionUpdateSaaS") Then
		
		InfobaseUpdateInternalSaaSModule = CommonUse.CommonModule("InfobaseUpdateInternalSaaS");
		InfobaseUpdateInternalSaaSModule.OnDetermineInfobaseVersion(LibraryID, GetCommonDataVersion,
			StandardProcessing, Result);
		
	EndIf;
	
	If StandardProcessing Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	SubsystemVersions.Version
		|FROM
		|	InformationRegister.SubsystemVersions AS SubsystemVersions
		|WHERE
		|	SubsystemVersions.SubsystemName = &SubsystemName";
		
		Query.SetParameter("SubsystemName", LibraryID);
		ValueTable = Query.Execute().Unload();
		Result = "";
		If ValueTable.Count() > 0 Then
			Result = TrimAll(ValueTable[0].Version);
		EndIf;
		
		//PARTIALLY_DELETED
		//If IsBlankString(Result) Then
		//	
		//	// Support for SL 2.1.2 updates
		//	QueryText =
		//		"SELECT
		//		|	DELETE.Version
		//		|FROM
		//		|	InformationRegister.DELETE AS DELETE
		//		|WHERE
		//		|	DELETE.SubsystemName = &SubsystemName
		//		|	AND DELETE.DataArea = &DataArea";
		//	Query = New Query(QueryText);
		//	Query.SetParameter("SubsystemName", LibraryID);
		//	If CommonUseCached.DataSeparationEnabled() Then
		//		Query.SetParameter("DataArea", -1);
		//	Else
		//		Query.SetParameter("DataArea", 0);
		//	EndIf;
		//	ValueTable = Query.Execute().Unload();
		//	If ValueTable.Count() > 0 Then
		//		Result = TrimAll(ValueTable[0].Version);
		//	EndIf;
			
		//EndIf;
		
	EndIf;
	
	Return ?(IsBlankString(Result), "0.0.0.0", Result);
	
EndFunction

// Writes a configuration or parent configuration (library) version to the infobase.
//
// Parameters:
//  LibraryID           - String  - configuration or parent configuration (library) name. 
//  VersionNumber       - String  - version number.
//  IsMainConfiguration - Boolean - flag specifying whether LibraryID matches the configuration name.
//
Procedure SetInfobaseVersion(Val LibraryID, Val VersionNumber, Val IsMainConfiguration) Export
	
	StandardProcessing = True;
	
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.InfobaseVersionUpdateSaaS") Then
		
		InfobaseUpdateInternalSaaSModule = CommonUse.CommonModule("InfobaseUpdateInternalSaaS");
		InfobaseUpdateInternalSaaSModule.OnSetInfobaseVersion(LibraryID, VersionNumber, StandardProcessing);
		
	EndIf;
	
	If Not StandardProcessing Then
		Return;
	EndIf;
		
	RecordSet = InformationRegisters.SubsystemVersions.CreateRecordSet();
	RecordSet.Filter.SubsystemName.Set(LibraryID);
	
	NewRecord = RecordSet.Add();
	NewRecord.SubsystemName = LibraryID;
	NewRecord.Version = VersionNumber;
	NewRecord.IsMainConfiguration = IsMainConfiguration;
	
	RecordSet.Write();
	
EndProcedure

// Returns an infobase data update mode.
// Can only be called before the infobase update starts (returns VersionUpdate otherwise).
// 
// Returns:
//   String   - "InitialFilling" if this is the first start of an empty infobase (data area);
//              "VersionUpdate" if this is the first start after infobase configuration update;
//              "MigrationFromAnotherApplication" if this is the first start 
//               after infobase configuration update where the base configuration name was changed.
//
Function DataUpdateMode() Export
	
	SetPrivilegedMode(True);
	
	StandardProcessing = True;
	DataUpdateMode = "";
	
	BaseConfigurationName = Metadata.Name;
	SubsystemDescriptions  = StandardSubsystemsCached.SubsystemDescriptions();
	For Each SubsystemName In SubsystemDescriptions.Order Do
		SubsystemDetails = SubsystemDescriptions.ByNames.Get(SubsystemName);
		If Not ValueIsFilled(SubsystemDetails.MainServerModule) Then
			Continue;
		EndIf;
		
		If SubsystemDetails.Name <> BaseConfigurationName Then
			Continue;
		EndIf;
		
		Module = CommonUse.CommonModule(SubsystemDetails.MainServerModule);
		Module.OnDetermineDataUpdateMode(DataUpdateMode, StandardProcessing);
	EndDo;
	
	If Not StandardProcessing Then
		CommonUseClientServer.ValidateParameter("OnDetermineDataUpdateMode", "DataUpdateMode",
			DataUpdateMode, Type("String"));
		Message = NStr("en = 'Invalid value of parameter %1 in %2. 
			|Expected: %3; passed value: %4 (type %5).'");
		Message = StringFunctionsClientServer.SubstituteParametersInString(Message,
			"DataUpdateMode", "OnDetermineDataUpdateMode", 
			NStr("en = 'InitialFilling, VersionUpdate, or MigrationFromAnotherApplication'"), 
			DataUpdateMode, TypeOf(DataUpdateMode));
		CommonUseClientServer.Validate(DataUpdateMode = "InitialFilling" Or 
			DataUpdateMode = "VersionUpdate" Or DataUpdateMode = "MigrationFromAnotherApplication", Message);
		Return DataUpdateMode;
	EndIf;

	Result = Undefined;
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.InfobaseVersionUpdateSaaS") Then
		InfobaseUpdateInternalSaaSModule = CommonUse.CommonModule("InfobaseUpdateInternalSaaS");
		InfobaseUpdateInternalSaaSModule.OnDetermineDataAreaFirstLogon(StandardProcessing, Result);
	EndIf;
	
	If Not StandardProcessing Then
		Return ?(Result = True, "InitialFilling", "VersionUpdate");
	EndIf;
	
	Return DataUpdateModeInLocalMode();
	
EndFunction

// Fills the parameter structure that enables the functioning of client configuration code.
//
// Parameters:
//   Parameters   - Structure - parameter structure.
//
Procedure AddClientParameters(Parameters) Export
	
EndProcedure

// Checks whether any handlers are available in the current update plan
//
// Parameters:
//   LibraryID - String - configuration name or library ID.
//
// Returns:
//   Boolean - True if the current update plan is empty, False otherwise.
//
Function CurrentUpdatePlanEmpty(Val LibraryID) Export
	
	RecordManager = InformationRegisters.SubsystemVersions.CreateRecordManager();
	RecordManager.SubsystemName = LibraryID;
	RecordManager.Read();
	If Not RecordManager.Selected() Then
		Return True;
	EndIf;
	
	PlanDetails = RecordManager.UpdatePlan.Get();
	
	If PlanDetails = Undefined Then
		Return True;
	EndIf;
	
	Return PlanDetails.Plan.Rows.Count() = 0;
	
EndFunction

// For internal use
Function UpdateInIntervalHandlers(Val InitialHandlerTable, Val VersionFrom, 
	Val VersionBefore, Val GetSeparated = False, Val Filter = "Exclusive") Export
	
	// Adding numbers to a table, to be sorted by adding order
	AllHandlers = InitialHandlerTable.Copy();
	
	AllHandlers.Columns.Add("SerialNumber", New TypeDescription("Number", New NumberQualifiers(10, 0)));
	For Index = 0 To AllHandlers.Count() - 1 Do
		HandlerRow = AllHandlers[Index];
		HandlerRow.SerialNumber = Index + 1;
	EndDo;
	
	// Preparing parameters
	SelectSeparatedHandlers = True;
	SelectSharedHandlers = True;
	
	If CommonUseCached.DataSeparationEnabled() Then
		If GetSeparated Then
			SelectSharedHandlers = False;
		Else
			If CommonUseCached.CanUseSeparatedData() Then
				SelectSharedHandlers = False;
			Else
				SelectSeparatedHandlers = False;
			EndIf;
		EndIf;
	EndIf;
	
	// Generating a handler tree
	Schema = GetCommonTemplate("GettingUpdateHandlerTree");
	Schema.Parameters.Find("SelectSeparatedHandlers").Value = SelectSeparatedHandlers;
	Schema.Parameters.Find("SelectSharedHandlers").Value = SelectSharedHandlers;
	Schema.Parameters.Find("VersionFrom").Value = VersionFrom;
	Schema.Parameters.Find("VersionBefore").Value = VersionBefore;
	Schema.Parameters.Find("VersionFromWeight").Value = VersionWeight(Schema.Parameters.Find("VersionFrom").Value);
	Schema.Parameters.Find("VersionToWeight").Value = VersionWeight(Schema.Parameters.Find("VersionBefore").Value);
	Schema.Parameters.Find("NonexclusiveUpdate").Value = (Filter = "Nonexclusive");
	Schema.Parameters.Find("DeferredUpdate").Value = (Filter = "Deferred");
	
	Composer = New DataCompositionTemplateComposer;
	Template = Composer.Execute(Schema, Schema.DefaultSettings, , , Type("DataCompositionValueCollectionTemplateGenerator"));
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(Template, New Structure("Handlers", AllHandlers), , True);
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	OutputProcessor.SetObject(New ValueTree);
	
	HandlersToExecute = OutputProcessor.Output(CompositionProcessor);
	
	HandlersToExecute.Columns.Version.Name = "RegistrationVersion";
	HandlersToExecute.Columns.VersionGroup.Name = "Version";
	
	Return HandlersToExecute;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Handlers of conditional calls to this subsystem.

// Called while executing the update script in procedure ConfigurationUpdate.FinishUpdate().
Procedure AfterUpdateCompletion() Export
	
	WriteLegitimateSoftwareConfirmation();
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

////////////////////////////////////////////////////////////////////////////////
// Common functions.

// For internal use.
//
Function UpdateRequired(Val MetadataVersion, Val DataVersion) Export
	Return Not IsBlankString(MetadataVersion) And DataVersion <> MetadataVersion;
EndFunction

// Returns numeric weight coefficient of a version, used to compare and prioritize between versions.
//
// Parameters:
//   Version - String - version number in string format.
//
// Returns:
//   Number - version weight.
//
Function VersionWeight(Val Version) Export
	
	If Version = "" Then
		Return 0;
	EndIf;
	
	Return VersionWeightFromStringArray(StringFunctionsClientServer.SplitStringIntoSubstringArray(Version, "."));
	
EndFunction

// For internal use.
//
Function UpdateIteration(ConfigurationOrLibraryName, Version, Handlers, IsMainConfiguration = Undefined) Export
	
	UpdateIteration = New Structure;
	UpdateIteration.Insert("Subsystem",  ConfigurationOrLibraryName);
	UpdateIteration.Insert("Version",      Version);
	UpdateIteration.Insert("IsMainConfiguration", 
		?(IsMainConfiguration <> Undefined, IsMainConfiguration, ConfigurationOrLibraryName = Metadata.Name));
	UpdateIteration.Insert("Handlers", Handlers);
	UpdateIteration.Insert("ExecutedHandlers", Undefined);
	UpdateIteration.Insert("MainServerModuleName", "");
	UpdateIteration.Insert("MainServerModule", "");
	UpdateIteration.Insert("PreviousVersion", "");
	Return UpdateIteration;
	
EndFunction

// For internal use.
//
Function UpdateIterations() Export
	
	BaseConfigurationName = Metadata.Name;
	MainSubsystemUpdateIteration = Undefined;
	
	UpdateIterations = New Array;
	SubsystemDescriptions  = StandardSubsystemsCached.SubsystemDescriptions();
	For Each SubsystemName In SubsystemDescriptions.Order Do
		SubsystemDetails = SubsystemDescriptions.ByNames.Get(SubsystemName);
		If Not ValueIsFilled(SubsystemDetails.MainServerModule) Then
			Continue;
		EndIf;
		Module = CommonUse.CommonModule(SubsystemDetails.MainServerModule);
		
		UpdateIteration = UpdateIteration(SubsystemDetails.Name, SubsystemDetails.Version, 
			InfobaseUpdate.NewUpdateHandlerTable(), SubsystemDetails.Name = BaseConfigurationName);
		UpdateIteration.MainServerModuleName = SubsystemDetails.MainServerModule;
		UpdateIteration.MainServerModule = Module;
		UpdateIteration.PreviousVersion = InfobaseVersion(SubsystemDetails.Name);
		UpdateIterations.Add(UpdateIteration);
		
		Module.OnAddUpdateHandlers(UpdateIteration.Handlers);
		
		If SubsystemDetails.Name = BaseConfigurationName Then
			MainSubsystemUpdateIteration = UpdateIteration;
		EndIf;
		
		ValidateHandlerProperties(UpdateIteration);
	EndDo;
	
	// For backward compatibility.
	If MainSubsystemUpdateIteration = Undefined Then
		
		UpdateIteration = UpdateIteration(BaseConfigurationName, Metadata.Version, 
			InfobaseUpdateOverridable.UpdateHandlers(), True);
		UpdateIteration.MainServerModuleName = "InfobaseUpdateOverridable";
		UpdateIteration.MainServerModule = InfobaseUpdateOverridable;
		UpdateIteration.PreviousVersion = InfobaseVersion(BaseConfigurationName);
		UpdateIterations.Add(UpdateIteration);
		
		ValidateHandlerProperties(UpdateIteration);
	EndIf;
	
	Return UpdateIterations;
	
EndFunction

// For internal use.
//
Function ExecuteUpdateIteration(Val UpdateIteration, Val Parameters) Export
	
	LibraryID = UpdateIteration.Subsystem;
	InfobaseMetadataVersion      = UpdateIteration.Version;
	UpdateHandlers   = UpdateIteration.Handlers;
	
	CurrentInfobaseVersion = UpdateIteration.PreviousVersion;
	
	NewInfobaseVersion = CurrentInfobaseVersion;
	MetadataVersion = InfobaseMetadataVersion;
	If IsBlankString(MetadataVersion) Then
		MetadataVersion = "0.0.0.0";
	EndIf;
	
	If CurrentInfobaseVersion <> "0.0.0.0"
		And CommonUseCached.DataSeparationEnabled()
		And CommonUseCached.CanUseSeparatedData() Then
		
		// Getting an update plan generated during the shared handler execution phase
		HandlersToExecute = GetUpdatePlan(LibraryID, CurrentInfobaseVersion, MetadataVersion);
		If HandlersToExecute = Undefined Then
			If UpdateIteration.IsMainConfiguration Then 
				MessagePattern = NStr("en = 'Update plan for configuration %1 (version %2 to %3) is not found'");
			Else
				MessagePattern = NStr("en = 'Update plan for library %1 (version %2 to %3) is not found'");
			EndIf;
			Message = StringFunctionsClientServer.SubstituteParametersInString(MessagePattern, LibraryID,
				CurrentInfobaseVersion, MetadataVersion);
			WriteInformation(Message);
			
			HandlersToExecute = UpdateInIntervalHandlers(UpdateHandlers, CurrentInfobaseVersion, MetadataVersion);
		EndIf;
	Else
		HandlersToExecute = UpdateInIntervalHandlers(UpdateHandlers, CurrentInfobaseVersion, MetadataVersion);
	EndIf;
	
	DetachUpdateHandlers(LibraryID, HandlersToExecute, MetadataVersion, Parameters.HandlerExecutionProgress);
	
	RequiredSeparatedHandlers = InfobaseUpdate.NewUpdateHandlerTable();
	SourceInfobaseVersion = CurrentInfobaseVersion;
	WriteToLog = Constants.WriteInfobaseUpdateDetailsToEventLog.Get();
	
	For Each Version In HandlersToExecute.Rows Do
		
		If Version.Version = "*" Then
			Message = NStr("en = 'Executing mandatory infobase update procedures.'");
		Else
			NewInfobaseVersion = Version.Version;
			If CurrentInfobaseVersion = "0.0.0.0" Then
				Message = NStr("en = 'Filling initial data.'");
			ElsIf UpdateIteration.IsMainConfiguration Then 
				Message = NStr("en = 'Updating infobase version %1 to version %2.'");
			Else
				Message = NStr("en = 'Updating library %3 version %1 to version %2.'");
			EndIf;
			Message = StringFunctionsClientServer.SubstituteParametersInString(Message,
				CurrentInfobaseVersion, NewInfobaseVersion, LibraryID);
		EndIf;
		WriteInformation(Message);
		
		For Each Handler In Version.Rows Do
			
			HandlerParameters = Undefined;
			If Handler.RegistrationVersion = "*" Then
				
				If Handler.HandlerManagement Then
					HandlerParameters = New Structure;
					HandlerParameters.Insert("SeparatedHandlers", RequiredSeparatedHandlers);
				EndIf;
				
				If Handler.ExclusiveMode = True Then
					If Parameters.NonexclusiveUpdate Then
						// Checks are performed in CanExecuteNonexclusiveUpdate(). 
						// For these handlers, the update is only performed in case of regular update.
						Continue;
					EndIf;
					
					If HandlerParameters = Undefined Then
						HandlerParameters = New Structure;
					EndIf;
					HandlerParameters.Insert("ExclusiveMode", True);
				EndIf;
			EndIf;
			
			AdditionalParameters = New Structure("WriteToLog, LibraryID, HandlerExecutionProgress, InBackground",
				WriteToLog, LibraryID, Parameters.HandlerExecutionProgress, Parameters.InBackground);
			ExecuteUpdateHandler(Handler, HandlerParameters, AdditionalParameters);
		EndDo;
		
		If Version.Version = "*" Then
			Message = NStr("en = 'Mandatory infobase update procedures are completed.'");
		Else
			If UpdateIteration.IsMainConfiguration Then 
				Message = NStr("en = 'Infobase version %1 update to version %2 is complete.'");
			Else
				Message = NStr("en = 'Library %3 version %1 update to version %2 is complete.'");
			EndIf;
			
			Message = StringFunctionsClientServer.SubstituteParametersInString(Message,
			  CurrentInfobaseVersion, NewInfobaseVersion, LibraryID);
		EndIf;
		WriteInformation(Message);
		
		If Version.Version <> "*" Then
			// Setting infobase version number
			SetInfobaseVersion(LibraryID, NewInfobaseVersion, UpdateIteration.IsMainConfiguration);
			CurrentInfobaseVersion = NewInfobaseVersion;
		EndIf;
		
	EndDo;
	
	// Setting infobase version number
	If InfobaseVersion(LibraryID) <> InfobaseMetadataVersion Then
		SetInfobaseVersion(LibraryID, InfobaseMetadataVersion, UpdateIteration.IsMainConfiguration);
	EndIf;
	
	If CurrentInfobaseVersion <> "0.0.0.0" Then
		
		If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.InfobaseVersionUpdateSaaS") Then
			
			InfobaseUpdateInternalSaaSModule = CommonUse.CommonModule("InfobaseUpdateInternalSaaS");
			InfobaseUpdateInternalSaaSModule.GenerateDataAreaUpdatePlan(LibraryID, UpdateHandlers,
				RequiredSeparatedHandlers, SourceInfobaseVersion, InfobaseMetadataVersion);
			
		EndIf;
		
	EndIf;
	
	Return HandlersToExecute;
	
EndFunction

// Verifies whether the current user has sufficient rights to update an infobase.
Function CanUpdateInfobase(ForPrivilegedMode = True, SeparatedData = Undefined) Export
	
	CheckSystemAdministrationRights = True;
	
	If SeparatedData = Undefined Then
		SeparatedData = Not CommonUseCached.DataSeparationEnabled()
			Or CommonUseCached.CanUseSeparatedData();
	EndIf;
	
	If CommonUseCached.DataSeparationEnabled()
	   And SeparatedData Then
		
		If Not CommonUseCached.CanUseSeparatedData() Then
			Return False;
		EndIf;
		CheckSystemAdministrationRights = False;
	EndIf;
	
	Return Users.InfobaseUserWithFullAccess(
		, CheckSystemAdministrationRights, ForPrivilegedMode);
	
EndFunction

// For internal use.
//
Function UpdateInfobaseInBackground(FormUUID, InfobaseDataLock) Export
	
	ErrorInfo = Undefined;
	
	// Starting background job
	InfobaseUpdateParameters = New Structure;
	InfobaseUpdateParameters.Insert("ExceptionWhenCannotLockInfobase", False);
	InfobaseUpdateParameters.Insert("InfobaseDataLock", InfobaseDataLock);
	InfobaseUpdateParameters.Insert("ClientParametersOnServer", SessionParameters.ClientParametersOnServer);
	
	// Enabling exclusive mode before starting the update procedure in background
	Try
		LockInfobase(InfobaseUpdateParameters.InfobaseDataLock, False);
	Except
		ErrorInfo = ErrorInfo();
		Result = New Structure;
		Result.Insert("JobCompleted", False);
		Result.Insert("InfobaseDataLock", InfobaseUpdateParameters.InfobaseDataLock);
		Result.Insert("BriefErrorMessage", BriefErrorDescription(ErrorInfo));
		Result.Insert("DetailedErrorMessage", DetailErrorDescription(ErrorInfo));
		Return Result;
	EndTry;
	
	InfobaseUpdateParameters.Insert("InBackground", Not InfobaseUpdateParameters.InfobaseDataLock.DebugMode);
	
	Try
		
		If Not InfobaseUpdateParameters.InBackground Then
			
			InfobaseUpdateParameters.Delete("ClientParametersOnServer");
			StorageAddress = PutToTempStorage(Undefined, FormUUID);
			ExecuteInfobaseUpdateInBackground(InfobaseUpdateParameters, StorageAddress);
			Result = New Structure;
			Result.Insert("StorageAddress", StorageAddress);
			Result.Insert("JobCompleted", True);
			
		Else // Starting the infobase update procedure in background
			Result = LongActions.ExecuteInBackground(
				FormUUID,
				"InfobaseUpdateInternal.ExecuteInfobaseUpdateInBackground",
				InfobaseUpdateParameters,
				NStr("en = 'Updating infobase in background'"));
		EndIf;
		
		Result.Insert("InfobaseDataLock", InfobaseUpdateParameters.InfobaseDataLock);
		Result.Insert("BriefErrorMessage", Undefined);
		Result.Insert("DetailedErrorMessage", Undefined);
	Except
		ErrorInfo = ErrorInfo();
		Result = New Structure;
		Result.Insert("JobCompleted", False);
		Result.Insert("InfobaseDataLock", InfobaseUpdateParameters.InfobaseDataLock);
		Result.Insert("BriefErrorMessage", BriefErrorDescription(ErrorInfo));
		Result.Insert("DetailedErrorMessage", DetailErrorDescription(ErrorInfo));
	EndTry;
	
	// If the infobase is already updated - unlocking the infobase.
	If Result.JobCompleted = True Or ErrorInfo <> Undefined Then
		UnlockInfobase(InfobaseUpdateParameters.InfobaseDataLock);
	EndIf;
	
	Return Result;
	
EndFunction

// Starts a time-consuming infobase update procedure.
Function ExecuteInfobaseUpdateInBackground(InfobaseUpdateParameters, StorageAddress) Export
	
	If InfobaseUpdateParameters.InBackground Then
		SessionParameters.ClientParametersOnServer = InfobaseUpdateParameters.ClientParametersOnServer;
	EndIf;
	
	ErrorInfo = Undefined;
	Try
		Result = ExecuteInfobaseUpdate(
			InfobaseUpdateParameters.ExceptionWhenCannotLockInfobase, True, False,
			InfobaseUpdateParameters.InfobaseDataLock, InfobaseUpdateParameters.InBackground);
	Except
		ErrorInfo = ErrorInfo();
	EndTry;
	
	If ErrorInfo <> Undefined Then
		UpdateResult = New Structure;
		UpdateResult.Insert("BriefErrorMessage", BriefErrorDescription(ErrorInfo));
		UpdateResult.Insert("DetailedErrorMessage", DetailErrorDescription(ErrorInfo));
	ElsIf Not InfobaseUpdateParameters.InBackground Then
		UpdateResult = Result;
	Else
		UpdateResult = New Structure;
		UpdateResult.Insert("ClientParametersOnServer", SessionParameters.ClientParametersOnServer);
		UpdateResult.Insert("Result", Result);
	EndIf;
	PutToTempStorage(UpdateResult, StorageAddress);
	
EndFunction

// For internal use.
//
Function LockInfobase(InfobaseDataLock, ExceptionWhenCannotLockInfobase)
	
	UpdateIterations = Undefined;
	If InfobaseDataLock = Undefined Then
		InfobaseDataLock = InfobaseDataLock();
	EndIf;
	
	InfobaseDataLock.Use = True;
	If CommonUseCached.DataSeparationEnabled() Then
		InfobaseDataLock.DebugMode = False;
	Else
		SettingValue = CommonSettingsStorage.Load("InfobaseVersionUpdate", "DebugMode");
		InfobaseDataLock.DebugMode = (SettingValue = True);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.InfobaseVersionUpdateSaaS") Then
		InfobaseUpdateInternalSaaSModule = CommonUse.CommonModule("InfobaseUpdateInternalSaaS");
		InfobaseDataLock.RecordKey = InfobaseUpdateInternalSaaSModule.LockDataAreaVersions();
	EndIf;
	
	UpdateIterations = UpdateIterations();
	InfobaseDataLock.NonexclusiveUpdate = False;
	
	If InfobaseDataLock.DebugMode Then
		Return UpdateIterations;
	EndIf;
	
	// Enabling exclusive mode for the infobase update purpose
	ErrorInfo = Undefined;
	Try
		CommonUse.LockInfobase();
		Return UpdateIterations;
	Except
		If CanExecuteNonexclusiveUpdate(UpdateIterations) Then
			InfobaseDataLock.NonexclusiveUpdate = True;
			Return UpdateIterations;
		EndIf;
		ErrorInfo = ErrorInfo();
	EndTry;
	
	// Processing a failed attempt to enable the exclusive mode
	Message = StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en = 'Cannot update the infobase:
			|- Cannot set exclusive mode
			|- This configuration version can only be updated in exclusive mode
			|
			|Error details: %1'"),
		BriefErrorDescription(ErrorInfo));
	
	WriteError(Message);
	
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.InfobaseVersionUpdateSaaS") Then
		InfobaseUpdateInternalSaaSModule = CommonUse.CommonModule("InfobaseUpdateInternalSaaS");
		InfobaseUpdateInternalSaaSModule.UnlockDataAreaVersions(InfobaseDataLock.RecordKey);
	EndIf;
	
	UserSessionsSubsystemUsed = False;
	OnDetermineUserSessionsSubsystemUsage(UserSessionsSubsystemUsed);
	FileInfobase = CommonUse.FileInfobase();
	
	If FileInfobase And Not ExceptionWhenCannotLockInfobase
		And UserSessionsSubsystemUsed Then
		
		ClientLaunchParameter = SessionParameters.ClientParametersOnServer.Get("LaunchParameter");
		If Find(ClientLaunchParameter, "ScheduledJobsDisabled") = 0 Then
			InfobaseDataLock.Error = "LockScheduledJobExecution";
		Else
			InfobaseDataLock.Error = "ExclusiveModeSettingError";
		EndIf;
	EndIf;
	
	Raise Message;
	
EndFunction

// For internal use.
//
Procedure UnlockInfobase(InfobaseDataLock) Export
	
	If InfobaseDataLock.DebugMode Then
		Return;
	EndIf;
		
	If ExclusiveMode() Then
		While TransactionActive() Do
			RollbackTransaction();
		EndDo;
	EndIf;
		
	CommonUse.UnlockInfobase();
	
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.InfobaseVersionUpdateSaaS") Then
		InfobaseUpdateInternalSaaSModule = CommonUse.CommonModule("InfobaseUpdateInternalSaaS");
		InfobaseUpdateInternalSaaSModule.UnlockDataAreaVersions(InfobaseDataLock.RecordKey);
	EndIf;
	
EndProcedure

// For internal use.
//
Function InfobaseDataLock()
	
	Result = New Structure;
	Result.Insert("Use", False);
	Result.Insert("Error", Undefined);
	Result.Insert("NonexclusiveUpdate", Undefined);
	Result.Insert("RecordKey", Undefined);
	Result.Insert("DebugMode", Undefined);
	Return Result;
	
EndFunction

// For internal use.
//
Function NewApplicationMigrationHandlerTable() Export
	
	Handlers = New ValueTable;
	Handlers.Columns.Add("PreviousConfigurationName",	New TypeDescription("String", New StringQualifiers(0)));
	Handlers.Columns.Add("Procedure",					New TypeDescription("String", New StringQualifiers(0)));
	Return Handlers;
	
EndFunction

// For internal use.
//
Function ApplicationMigrationHandlers(PreviousConfigurationName) 
	
	MigrationHandlers = NewApplicationMigrationHandlerTable();
	BaseConfigurationName = Metadata.Name;
	
	SubsystemDescriptions  = StandardSubsystemsCached.SubsystemDescriptions();
	For Each SubsystemName In SubsystemDescriptions.Order Do
		SubsystemDetails = SubsystemDescriptions.ByNames.Get(SubsystemName);
		If Not ValueIsFilled(SubsystemDetails.MainServerModule) Then
			Continue;
		EndIf;
		
		If SubsystemDetails.Name <> BaseConfigurationName Then
			Continue;
		EndIf;
		
		Module = CommonUse.CommonModule(SubsystemDetails.MainServerModule);
		Module.OnAddApplicationMigrationHandlers(MigrationHandlers);
	EndDo;
	
	Filter = New Structure("PreviousConfigurationName", "*");
	Result = MigrationHandlers.FindRows(Filter);
	
	Filter.PreviousConfigurationName = PreviousConfigurationName;
	CommonUseClientServer.SupplementArray(Result, MigrationHandlers.FindRows(Filter), True);
	
	Return Result;
	
EndFunction

Procedure MigrateFromAnotherApplication()
	
	// Previous name of the configuration to be used as migration source
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	SubsystemVersions.SubsystemName AS SubsystemName,
	|	SubsystemVersions.Version AS Version
	|FROM
	|	InformationRegister.SubsystemVersions AS SubsystemVersions
	|WHERE
	|	SubsystemVersions.IsMainConfiguration = TRUE";
	QueryResult = Query.Execute();
	// If the FillAttributeIsMainConfiguration update handler fails for any reason
	If QueryResult.IsEmpty() Then 
		Return;
	EndIf;
	
	If CommonUseCached.DataSeparationEnabled() Then
		Raise NStr("en = 'Application migration SaaS is not available.'");
	EndIf;
	
	QueryResult = Query.Execute().Unload()[0];
	PreviousConfigurationName = QueryResult.SubsystemName;
	PreviousConfigurationVersion = QueryResult.Version;
	Handlers = ApplicationMigrationHandlers(PreviousConfigurationName);
	
	// Executing all migration handlers
	For Each Handler In Handlers Do
		
		TransactionActiveAtExecutionStartTime = TransactionActive();
		Try
			SafeMode.ExecuteConfigurationMethod(Handler.Procedure);
		Except
			
			HandlerName = Handler.Procedure;
			WriteError(StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Error %2 occurred when calling application migration handler %1.'"),
				HandlerName,
				DetailErrorDescription(ErrorInfo())));
			
			Raise;
		EndTry;
		ValidateNestedTransaction(TransactionActiveAtExecutionStartTime, Handler.Procedure);
		
	EndDo;
		
	Parameters = New Structure();
	Parameters.Insert("ExecuteUpdateFromVersion", True);
	Parameters.Insert("ConfigurationVersion", Metadata.Version);
	Parameters.Insert("ClearPreviousConfigurationData", True);
	OnCompleteApplicationMigration(PreviousConfigurationName, PreviousConfigurationVersion, Parameters);
	
	// Setting current configuration name and version
	BeginTransaction();
	Try
		If Parameters.ClearPreviousConfigurationData Then
			RecordSet = InformationRegisters.SubsystemVersions.CreateRecordSet();
			RecordSet.Filter.SubsystemName.Set(PreviousConfigurationName);
			RecordSet.Write();
		EndIf;
		
		RecordSet = InformationRegisters.SubsystemVersions.CreateRecordSet();
		RecordSet.Filter.SubsystemName.Set(Metadata.Name);
		
		ConfigurationVersion = Metadata.Version; 
		If Parameters.ExecuteUpdateFromVersion Then
			ConfigurationVersion = Parameters.ConfigurationVersion;
		EndIf;
		NewRecord = RecordSet.Add();
		NewRecord.SubsystemName = Metadata.Name;
		NewRecord.Version = ConfigurationVersion;
		NewRecord.UpdatePlan = Undefined;
		NewRecord.IsMainConfiguration = True;
		
		RecordSet.Write();
		CommitTransaction();
	Except	
		RollbackTransaction();
		Raise;
	EndTry;
	
	RefreshReusableValues();
	
EndProcedure

Procedure OnCompleteApplicationMigration(PreviousConfigurationName, PreviousConfigurationVersion, Parameters)
	
	ConfigurationName = Metadata.Name;
	SubsystemDescriptions  = StandardSubsystemsCached.SubsystemDescriptions();
	For Each SubsystemName In SubsystemDescriptions.Order Do
		SubsystemDetails = SubsystemDescriptions.ByNames.Get(SubsystemName);
		If Not ValueIsFilled(SubsystemDetails.MainServerModule) Then
			Continue;
		EndIf;
		
		If SubsystemDetails.Name <> ConfigurationName Then
			Continue;
		EndIf;
		
		Module = CommonUse.CommonModule(SubsystemDetails.MainServerModule);
		Module.OnCompleteApplicationMigration(PreviousConfigurationName, PreviousConfigurationVersion, Parameters);
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Logging the update progress

// Returns a string constant for the generation of event log messages.
//
// Returns:
//   String.
//
Function EventLogMessageText() Export
	
	Return NStr("en = 'Infobase update'", CommonUseClientServer.DefaultLanguageCode());
	
EndFunction

// Returns a string constant used to create event log messages describing update handler execution progress.
//
// Returns:
//   String.
//
Function EventLogRecordProtocol() Export
	
	Return EventLogMessageText() + ". " + NStr("en = 'Execution log'", CommonUseClientServer.DefaultLanguageCode());
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Update details

// Generates a spreadsheet document containing change description for each version in the Sections version list.
//
Function UpdateDetailsDocument(Val Sections) Export
	
	UpdateDetailsDocument = New SpreadsheetDocument();
	If Sections.Count() = 0 Then
		Return UpdateDetailsDocument;
	EndIf;
	
	UpdateDetailsTemplate = Metadata.CommonTemplates.Find("ApplicationReleaseNotes");
	If UpdateDetailsTemplate <> Undefined Then
		UpdateDetailsTemplate = GetCommonTemplate(UpdateDetailsTemplate);
	Else
		Return New SpreadsheetDocument();
	EndIf;
	
	For Each Version In Sections Do
		
		OutputUpdateDetails(Version, UpdateDetailsDocument, UpdateDetailsTemplate);
		
	EndDo;
	
	Return UpdateDetailsDocument;
	
EndFunction

// Returns an array containing a list of versions later than the last displayed version, 
// provided that change descriptions are available for these versions.
//
// Returns:
//   Array - contains strings with version numbers.
//
Function NotShownUpdateDetailSections() Export
	
	Sections = UpdateDescriptionSections();
	
	LastVersion = SystemChangesDisplayLastVersion();
	
	If LastVersion = Undefined Then
		Return New Array;
	EndIf;
	
	Return GetLaterVersions(Sections, LastVersion);
	
EndFunction

// Sets the version change details display flag both for the current version and earlier versions.
//
// Parameters:
//  UserName - String - name of the user for whom the flag will be set.
//
Procedure SetDisplayDetailsToCurrentVersionFlag(Val UserName = Undefined) Export
	
	CommonUse.CommonSettingsStorageSave("InfobaseUpdate",
		"SystemChangesDisplayLastVersion", Metadata.Version, , UserName);
	
EndProcedure

// Sets the version change details display flag both for the current version and earlier versions,
// provided that the flag is not yet set for this user.
//
// Parameters:
//   UserName - String - name of the user for whom the flag will be set.
//
Procedure SetDisplayNewUserDescriptionsFlag(Val UserName = Undefined) Export
	
	If SystemChangesDisplayLastVersion(UserName) = Undefined Then
		SetDisplayDetailsToCurrentVersionFlag(UserName);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Deferred update mechanism

// Removes a deferred handler from the handler execution queue for the new version.
//
// Parameters:
//   HandlerName - String - String ID of the deferred handler.
//
Procedure RemoveDeferredHandlerFromQueue(HandlerName) Export
	
	UpdateDetails = InfobaseUpdateDetails();
	
	SelectedHandler = UpdateDetails.HandlerTree.Rows.FindRows(New Structure("HandlerName", HandlerName), True);
	If SelectedHandler <> Undefined And SelectedHandler.Count() > 0 Then
		
		For Each RowHandler In SelectedHandler Do
			RowHandler.Parent.Rows.Delete(RowHandler);
		EndDo;
		
	EndIf;
	
	WriteInfobaseUpdateDetails(UpdateDetails);
	
EndProcedure

// Generates a deferred handler tree and enables a scheduled job.
Procedure ScheduleDeferredUpdate(UpdateIterations)
	
	HandlerTree = PreviousVersionHandlersCompleted(UpdateIterations);
	UpdateDetails = InfobaseUpdateDetails();
	
	// Setting initial field values
	UpdateDetails.Insert("UpdateStartTime");
	UpdateDetails.Insert("UpdateEndTime");
	UpdateDetails.Insert("UpdateDuration");
	UpdateDetails.Insert("DeferredUpdateStartTime");
	UpdateDetails.Insert("DeferredUpdateEndTime");
	UpdateDetails.Insert("SessionNumber", New ValueList());
	UpdateDetails.Insert("UpdateHandlerParameters");
	UpdateDetails.Insert("DeferredUpdateCompletedSuccessfully");
	UpdateDetails.Insert("HandlerTree", New ValueTree());
	UpdateDetails.Insert("ShowUpdateDetails", False);
	
	LibraryName = "";
	VersionNumber   = "";
	
	For Each UpdateIteration In UpdateIterations Do
		
		LibraryName = UpdateIteration.Subsystem;
		HandlersByVersion = UpdateInIntervalHandlers(UpdateIteration.Handlers,
			UpdateIteration.PreviousVersion,
			UpdateIteration.Version,
			True,
			"Deferred");
			
		If HandlersByVersion.Rows.Count() = 0 Then
			Continue;
		EndIf;
		
		// Adding a library row
		FoundRow = HandlerTree.Rows.Find(LibraryName, "LibraryName");
		If FoundRow <> Undefined Then
			TreeRowLibrary = FoundRow;
		Else
			TreeRowLibrary = HandlerTree.Rows.Add();
			TreeRowLibrary.LibraryName = LibraryName;
		EndIf;
		TreeRowLibrary.Status = "";
		
		For Each VersionRow In HandlersByVersion.Rows Do
			
			FoundRow = TreeRowLibrary.Rows.Find(VersionRow.Version, "VersionNumber");
			HasUncompletedHandlers = False;
			If FoundRow <> Undefined Then
				FoundRow.Status = "";
				
				For Each UncompletedHandler In FoundRow.Rows Do
					HasUncompletedHandlers = True;
					UncompletedHandler.AttemptNumber = 0;
				EndDo;
				VersionsTreeRow = FoundRow;
			Else
				VersionsTreeRow = TreeRowLibrary.Rows.Add();
				VersionsTreeRow.VersionNumber   = VersionRow.Version;
				VersionsTreeRow.Status = "";
			EndIf;
			
			For Each HandlersRow In VersionRow.Rows Do
				
				If HasUncompletedHandlers Then
					FoundRow = VersionsTreeRow.Rows.Find(HandlersRow.Procedure, "HandlerName");
					If FoundRow <> Undefined Then
						Continue; // This handler already exists for this version
					EndIf;
				EndIf;
				
				If HandlersRow.ExclusiveMode = True Then
					
					ErrorText = NStr("en = 'Deferred handler %1
						|cannot have the ExclusiveMode flag set.'");
					ErrorText = StringFunctionsClientServer.SubstituteParametersInString(
						ErrorText, HandlersRow.Procedure);
					WriteError(ErrorText);
					Raise ErrorText;
					
				EndIf;
				
				HandlersTreeRow = VersionsTreeRow.Rows.Add();
				HandlersTreeRow.LibraryName = LibraryName;
				HandlersTreeRow.VersionNumber = HandlersRow.Version;
				HandlersTreeRow.RegistrationVersion = HandlersRow.RegistrationVersion;
				HandlersTreeRow.HandlerName = HandlersRow.Procedure;
				HandlersTreeRow.Comment = HandlersRow.Comment;
				HandlersTreeRow.Status = "Uncompleted";
				HandlersTreeRow.AttemptNumber = 0;
			EndDo;
			
		EndDo;
		
	EndDo;
	
	ValidateCompletedHandlerTree(HandlerTree);
	UpdateDetails.HandlerTree = HandlerTree;
	WriteInfobaseUpdateDetails(UpdateDetails);
	
	// Scheduling a scheduled job execution
	// Adding a scheduled job to queue (for SaaS)
	If Not CommonUse.FileInfobase() Then
		
		If CommonUseCached.DataSeparationEnabled() Then
			OnEnableDeferredUpdate(True);
		Else
			ScheduledJob = ScheduledJobs.FindPredefined(Metadata.ScheduledJobs.DeferredInfobaseUpdate);
			ScheduledJob.Use = True;
			ScheduledJob.Write();
		EndIf;
		
	EndIf;
	
EndProcedure

// Controls execution of the deferred update handlers.
// 
Procedure ExecuteDeferredUpdate() Export
	
	// OnScheduledJobStart is not called because the necessary actions are executed privately
	
	UpdateDetails = InfobaseUpdateDetails();
	
	If UpdateDetails.DeferredUpdateEndTime <> Undefined Then
		CancelDeferredUpdate();
		Return;
	EndIf;
	
	If UpdateDetails.DeferredUpdateStartTime = Undefined Then
		UpdateDetails.DeferredUpdateStartTime = CurrentSessionDate();
	EndIf;
	If TypeOf(UpdateDetails.SessionNumber) <> Type("ValueList") Then
		UpdateDetails.SessionNumber = New ValueList;
	EndIf;
	UpdateDetails.SessionNumber.Add(InfobaseSessionNumber());
	WriteInfobaseUpdateDetails(UpdateDetails);
	
	If Not ExecuteDeferredUpdateHandler(UpdateDetails) Then
		CancelDeferredUpdate();
	EndIf;
	
EndProcedure

// Executes all deferred update procedures in a single-call cycle.
//
Procedure PerformDeferredUpdateNow() Export
	
	UpdateDetails = InfobaseUpdateDetails();
	
	If UpdateDetails.DeferredUpdateEndTime <> Undefined Then
		Return;
	EndIf;

	If UpdateDetails.DeferredUpdateStartTime = Undefined Then
		UpdateDetails.DeferredUpdateStartTime = CurrentSessionDate();
	EndIf;
	
	If TypeOf(UpdateDetails.SessionNumber) <> Type("ValueList") Then
		UpdateDetails.SessionNumber = New ValueList;
	EndIf;
	UpdateDetails.SessionNumber.Add(InfobaseSessionNumber());
	WriteInfobaseUpdateDetails(UpdateDetails);
	
	IsHandlersCompleted = True;
	StartCount = 0; // Protection against infinite loops that can be caused by update handler errors
	While IsHandlersCompleted And StartCount < 10000 Do
		IsHandlersCompleted = ExecuteDeferredUpdateHandler(UpdateDetails);
		StartCount = StartCount + 1;
	EndDo;
	
EndProcedure

// Gets infobase update information.
Function InfobaseUpdateDetails() Export
	
	SetPrivilegedMode(True);
	
	If CommonUseCached.DataSeparationEnabled()
	   And Not CommonUseCached.CanUseSeparatedData() Then
		
		Return NewUpdateInformation();
	EndIf;
	
	InfobaseUpdateDetails = Constants.InfobaseUpdateDetails.Get().Get();
	If TypeOf(InfobaseUpdateDetails) <> Type("Structure") Then
		Return NewUpdateInformation();
	EndIf;
	If InfobaseUpdateDetails.Count() = 1 Then
		Return NewUpdateInformation();
	EndIf;
		
	InfobaseUpdateDetails = NewUpdateInformation(InfobaseUpdateDetails);
	Return InfobaseUpdateDetails;
	
EndFunction

// Writes the update data to UpdateDetails constant.
Procedure WriteInfobaseUpdateDetails(Val UpdateDetails) Export
	
	If UpdateDetails = Undefined Then
		NewValue = NewUpdateInformation();
	Else
		NewValue = UpdateDetails;
	EndIf;
	
	ConstantManager = Constants.InfobaseUpdateDetails.CreateValueManager();
	ConstantManager.Value = New ValueStorage(NewValue);
	InfobaseUpdate.WriteData(ConstantManager);
	
EndProcedure

// For internal use only
Function MustCheckLegitimateSoftware() Export
	
	If Not CommonUse.SubsystemExists("StandardSubsystems.LegitimateSoftwareCheck") Then
		Return False;
	EndIf;
	
	If StandardSubsystemsServer.IsBaseConfigurationVersion() Then
		Return False;
	EndIf;
	
	If CommonUseCached.DataSeparationEnabled() Then
		Return False;
	EndIf;
	
	If CommonUse.IsSubordinateDIBNode() Then
		Return False;
	EndIf;
	
	LegitimateVersion = "";
	
	If DataUpdateModeInLocalMode() = "InitialFilling" Then
		LegitimateVersion = Metadata.Version;
	Else
		UpdateDetails = InfobaseUpdateDetails();
		LegitimateVersion = UpdateDetails.LegitimateVersion;
	EndIf;
	
	Return LegitimateVersion <> Metadata.Version;
	
EndFunction

// For internal use only
Procedure WriteLegitimateSoftwareConfirmation() Export
	
	If CommonUseCached.DataSeparationEnabled()
	   And Not CommonUseCached.CanUseSeparatedData() Then
		
		Return;
	EndIf;
	
	UpdateDetails = InfobaseUpdateDetails();
	UpdateDetails.LegitimateVersion = Metadata.Version;
	WriteInfobaseUpdateDetails(UpdateDetails);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// SL event handlers

// Handler of the event that has the same name, which occurs during data exchange in a distributed infobase.
//
// Parameters:
//   see OnSendDataToSlave() event handler description in the Syntax Assistant.
// 
Procedure OnSendDataToSlave(DataItem, ItemSend, InitialImageCreating, Recipient) Export
	
	InfobaseUpdateEvents.OnSendSubsystemVersions(DataItem, ItemSend, InitialImageCreating);
	
EndProcedure

// Handler of the event that has the same name, which occurs during data exchange in a distributed infobase.
//
// Parameters:
//   see OnSendDataToMaster() event handler description in the Syntax Assistant.
// 
Procedure OnSendDataToMaster(DataItem, ItemSend, Recipient) Export
	
	InfobaseUpdateEvents.OnSendSubsystemVersions(DataItem, ItemSend);
	
EndProcedure

// Adds client mode parameters for the data exchange subsystem in SaaS mode at the application startup.
//
Procedure OnAddStandardSubsystemClientLogicParametersOnStart(Parameters) Export
	
	Parameters.Insert("InitialDataFilling", DataUpdateMode() = "InitialFilling");
	Parameters.Insert("ShowApplicationReleaseNotes", ShowApplicationReleaseNotes());
	
	If CommonUseCached.DataSeparationEnabled() Then
		Return;
	EndIf;
	HandlersStatus = UncompletedHandlersStatus();
	If HandlersStatus = "" Then
		Return;
	EndIf;
	If HandlersStatus = "ErrorStatus"
		And Users.InfobaseUserWithFullAccess(, True) Then
		Parameters.Insert("ShowMessageAboutErrorHandlers");
	Else
		Parameters.Insert("ShowNotExecutedHandlersNotification");
	EndIf;
	
EndProcedure

// Adds update handlers that are required by the subsystem.
//
// Parameters:
//  Handlers - ValueTable - see the description of NewUpdateHandlerTable function in the InfobaseUpdate common module.
// 
Procedure OnAddUpdateHandlers(Handlers) Export
	
	If CommonUse.SubsystemExists("StandardSubsystems.LegitimateSoftwareCheck") Then
		Handler = Handlers.Add();
		Handler.InitialFilling = True;
		Handler.Procedure = "InfobaseUpdateInternal.WriteLegitimateSoftwareConfirmation";
	EndIf;
	//PARTIALLY_DELETED
	//Handler = Handlers.Add();
	//Handler.Version = "2.1.3.19";
	//Handler.Procedure = "InfobaseUpdateInternal.MoveSubsystemVersionsToSharedData";
	//Handler.SharedData = True;
	
	//Handler = Handlers.Add();
	//Handler.Version = "2.2.2.7";
	//Handler.Procedure = "InfobaseUpdateInternal.FillAttributeIsMainConfiguration";
	//Handler.SharedData = True;
	
EndProcedure

// The procedure is used when getting metadata objects that are mandatory for the exchange plan.
// If the subsystem includes metadata objects that must be included in
// the exchange plan content, add these metadata objects to the Objects parameter.
//
// Parameters:
//   Objects - Array - the array of configuration metadata objects 
//                     that must be included in the exchange plan content.
//   DistributedInfobase (read only) - Boolean - flag that shows whether DIB exchange plan objects 
//                                     are retrieved.
//                                     True if list of DIB exchange plan objects is retrieved;
//                                     False if list of non-DIB exchange plan objects is retrieved.
//
Procedure OnGetMandatoryExchangePlanObjects(Objects, Val DistributedInfobase) Export
	
EndProcedure

// The procedure is used for getting metadata objects that must be included in the exchange plan content 
// but NOT included in the change record event subscriptions of this exchange plan.
// These metadata objects are used only when creating the initial image
// of a subordinate node and are not transferred during the exchange.
// If the subsystem includes metadata objects used only for creating the initial image
// of a subordinate node, add these metadata objects to the Objects parameter.
//
// Parameters:
//   Objects - Array - metadata object array.
//
Procedure OnGetExchangePlanInitialImageObjects(Objects) Export
	
	Objects.Add(Metadata.InformationRegisters.SubsystemVersions);
	
EndProcedure

// The procedure is used when getting metadata objects that must not be included in the exchange plan content.
// If the subsystem includes metadata objects that must not be included in
// the exchange plan content, add these metadata objects to the Objects parameter.
//
// Parameters:
//   Objects - Array - array of configuration metadata objects that should not be included 
//                     in the exchange plan content.
//   DistributedInfobase (read only) - Boolean - flag that shows whether DIB exchange plan objects
//                                     are retrieved.
//                                     True if list of DIB exchange plan objects is retrieved;
//                                     False if list of non-DIB exchange plan objects is retrieved.
//
Procedure ExchangePlanObjectsToExcludeOnGet(Objects, Val DistributedInfobase) Export
	
	If DistributedInfobase Then
		
		Objects.Add(Metadata.Constants.ApplicationChangeLogSections);
		
	EndIf;
	
EndProcedure

// OnReceiveTemplateList event handler.
//
// Generates a list of templates for queued jobs.
//
// Parameters:
//   Templates - String array - the parameter should include names of predefined shared scheduled jobs 
//                              to be used as queue job templates.
//
Procedure OnReceiveTemplateList(Templates) Export
	
	Templates.Add("DeferredInfobaseUpdate");
	
EndProcedure

// Returns the mapping between session parameter names and their initialization handlers.
//
Procedure SessionParameterSettingHandlersOnAdd(Handlers) Export
	
	Handlers.Insert("InfobaseUpdateInProgress", "InfobaseUpdateInternal.SessionParametersSetting");
	
EndProcedure

// Fills a user's to-do list.
//
// Parameters:
//  ToDoList - ValueTable - value table with the following columns:
//    * ID             - String  - internal user task ID used by the To-do list algorithm.
//    * HasUserTasks   - Boolean - if True, the user task is displayed in the user's to-do list.
//    * Important      - Boolean - If True, the user task is outlined in red.
//    * Presentation   - String  - user task presentation displayed to the user.
//    * Count          - Number  - quantitative indicator of the user task, displayed in the title of the user task.
//    * Form           - String  - full path to the form that is displayed by a click on the task hyperlink in the To-do list panel.
//    * FormParameters - Structure - parameters with which to open the user form.
//    * Owner          - String, metadata object - string ID of the user task that is the owner of the current user task, or a subsystem metadata object.
//    * Hint           - String - hint text.
//
Procedure OnFillToDoList(ToDoList) Export
	
	If Not Users.InfobaseUserWithFullAccess(, True) Then
		Return;
	EndIf;
	
	If CommonUseCached.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	// This procedure is only called when To do list subsystem is available. 
	// Therefore, the subsystem availability check is redundant.
	ToDoListInternalCachedModule = CommonUse.CommonModule("ToDoListInternalCached");
	
	ObjectsBelonging = ToDoListInternalCachedModule.ObjectsBelongingToCommandInterfaceSections();
	Sections = ObjectsBelonging[Metadata.DataProcessors.InfobaseUpdate.FullName()];
	
	If Sections = Undefined Then
		Return;
	EndIf;
	
	HandlersStatus           = UncompletedHandlersStatus();
	HasHandlersWithErrors      = (HandlersStatus = "ErrorStatus");
	HasUncompletedHandlers = (HandlersStatus = "UncompletedStatus");
	
	For Each Section In Sections Do
		ID = "DeferredUpdate" + StrReplace(Section.FullName(), ".", "");
		UserTask = ToDoList.Add();
		UserTask.ID = ID;
		UserTask.HasUserTasks      = (HasHandlersWithErrors Or HasUncompletedHandlers);
		UserTask.Important        = HasHandlersWithErrors;
		UserTask.Presentation = NStr("en = 'Application update is not completed'");
		UserTask.Form         = "DataProcessor.InfobaseUpdate.Form.DeferredInfobaseUpdateProgressIndicator";
		UserTask.Owner      = Section;
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Handlers of conditional calls of other subsystems

// Determines whether the User sessions subsystem is used in the configuration.
//
// Parameters:
//   Used - Boolean - True if the subsystem is used, False otherwise.
//
Procedure OnDetermineUserSessionsSubsystemUsage(Used)
	
	If CommonUse.SubsystemExists("StandardSubsystems.UserSessions") Then
		Used = True;
	EndIf;
	
EndProcedure

// Unlocks file infobase.
//
Procedure OnUnlockFileInfobase() Export
	
	If Not CommonUse.FileInfobase() Then
		Return;
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.UserSessions") Then
		InfobaseConnectionsModule = CommonUse.CommonModule("InfobaseConnections");
		InfobaseConnectionsModule.AllowUserLogon();
	EndIf;
	
EndProcedure

// Determines usage of a scheduled job intended to fill access management data.
//
// Parameters:
//   Use - Boolean - True if the job must be activated, False otherwise.
//
Procedure OnEnableDeferredUpdate(Val Use) Export
	
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.InfobaseVersionUpdateSaaS") Then
		InfobaseUpdateInternalSaaSModule = CommonUse.CommonModule("InfobaseUpdateInternalSaaS");
		InfobaseUpdateInternalSaaSModule.OnEnableDeferredUpdate(Use);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// INFOBASE UPDATE HANDLERS

// Transfers data from the DELETE information register to the SubsystemVersions information register.
//
Procedure MoveSubsystemVersionsToSharedData() Export
	
	//PARTIALLY_DELETED - InformationRegister.DELETE
	
	//BeginTransaction();
	//
	//Try
	//	
	//	If CommonUseCached.DataSeparationEnabled() Then
	//		SharedDataArea = -1;
	//	Else
	//		SharedDataArea = 0;
	//	EndIf;
	//	
	//	QueryText =
	//	"SELECT
	//	|	DELETE.SubsystemName,
	//	|	DELETE.Version,
	//	|	DELETE.UpdatePlan
	//	|FROM
	//	|	InformationRegister.DELETE AS DELETE
	//	|WHERE
	//	|	DELETE.DataArea = &DataArea";
	//	
	//	Query = New Query(QueryText);
	//	Query.SetParameter("DataArea", SharedDataArea);
	//	Selection = Query.Execute().Select();
	//	While Selection.Next() Do
	//		
	//		Manager = InformationRegisters.SubsystemVersions.CreateRecordManager();
	//		Manager.SubsystemName = Selection.SubsystemName;
	//		Manager.Version = Selection.Version;
	//		Manager.UpdatePlan = Selection.UpdatePlan;
	//		Manager.Write();
	//		
	//	EndDo;
	//	
	//	Set = InformationRegisters.DELETE.CreateRecordSet();
	//	Set.Filter.DataArea.Set(SharedDataArea);
	//	Set.Write();
	//	
	//	CommitTransaction();
	//	
	//Except
	//	
	//	RollbackTransaction();
	//	Raise;
	//	
	//EndTry;
	
EndProcedure

// Fiils the IsMainConfiguration attribute value for SubsystemVersions information register records.
//
Procedure FillAttributeIsMainConfiguration() Export
	
	SetInfobaseVersion(Metadata.Name, InfobaseVersion(Metadata.Name), True);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// AUXILIARY PROCEDURES AND FUNCTIONS

////////////////////////////////////////////////////////////////////////////////
// Common use

Function DataUpdateModeInLocalMode()
	
	SetPrivilegedMode(True);
	Query = New Query;
	//PARTIALLY_DELETED
	//Query.Text = 
	//	"SELECT
	//	|	1 AS Field1
	//	|FROM
	//	|	InformationRegister.SubsystemVersions AS SubsystemVersions
	//	|;
	//	|
	//	|////////////////////////////////////////////////////////////////////////////////
	//	|SELECT
	//	|	1
	//	|FROM
	//	|	InformationRegister.DELETE AS DELETE";
	//
	//BatchExecutionResult = Query.ExecuteBatch();
	//If BatchExecutionResult[0].IsEmpty() And BatchExecutionResult[1].IsEmpty() Then
	//	Return "InitialFilling";
	//ElsIf BatchExecutionResult[0].IsEmpty() And Not BatchExecutionResult[1].IsEmpty() Then
	//	Return "VersionUpdate"; // support for SL 2.1.2 updates
	//EndIf;
	
	Query.Text = 
		"SELECT
		|	1 AS Field1
		|FROM
		|	InformationRegister.SubsystemVersions AS SubsystemVersions";
	
	ExecutionResult = Query.Execute();
	If ExecutionResult.IsEmpty() Then
		Return "InitialFilling";
	EndIf;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	1 AS Field1
		|FROM
		|	InformationRegister.SubsystemVersions AS SubsystemVersions
		|WHERE
		|	SubsystemVersions.IsMainConfiguration = TRUE
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	1 AS Field1
		|FROM
		|	InformationRegister.SubsystemVersions AS SubsystemVersions
		|WHERE
		|	SubsystemVersions.SubsystemName = &BaseConfigurationName
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	1 AS Field1
		|FROM
		|	InformationRegister.SubsystemVersions AS SubsystemVersions
		|WHERE
		|	SubsystemVersions.IsMainConfiguration = TRUE
		|	AND SubsystemVersions.SubsystemName = &BaseConfigurationName";
	Query.SetParameter("BaseConfigurationName", Metadata.Name);
	BatchExecutionResult = Query.ExecuteBatch();
	If BatchExecutionResult[0].IsEmpty() And Not BatchExecutionResult[1].IsEmpty() Then
		Return "VersionUpdate"; // IsMainConfiguration attribute is not yet filled
	EndIf;
	
	// Making decision based on the IsMainConfiguration attribute filled earlier
	Return ?(BatchExecutionResult[2].IsEmpty(), "MigrationFromAnotherApplication", "VersionUpdate");
	
EndFunction	

Function CanExecuteNonexclusiveUpdate(UpdateIterations)
	
	HandlerSeparationFilters = New Array;
	If Not CommonUseCached.CanUseSeparatedData() Then
		HandlerSeparationFilters.Add(False);
	EndIf;
	HandlerSeparationFilters.Add(True);
	
	RequiredSeparatedHandlers = InfobaseUpdate.NewUpdateHandlerTable(); // In check mode, this parameter is not used
	
	WriteToLog = Constants.WriteInfobaseUpdateDetailsToEventLog.Get();
	
	// Validating update handlers with the ExclusiveMode flag for configuration subsystems
	For Each UpdateIteration In UpdateIterations Do
		
		For Each SeparationFlag In HandlerSeparationFilters Do
		
			HandlerTree = UpdateInIntervalHandlers(UpdateIteration.Handlers,
				UpdateIteration.PreviousVersion,
				UpdateIteration.Version,
				SeparationFlag,
				"Nonexclusive");
				
			If HandlerTree.Rows.Count() = 0 Then
				Continue;
			EndIf;
				
			If HandlerTree.Rows.Count() > 1 
				Or HandlerTree.Rows[0].Version <> "*" Then
				
				Return False; // Exclusive version update handlers are available
			EndIf;
			
			If SeparationFlag 
				And CommonUseCached.DataSeparationEnabled() 
				And Not CommonUseCached.CanUseSeparatedData() Then
				
				// When updating a shared infobase version, 
				// the exclusive mode for separated mandatory update handlers
				// is controlled by a shared handler
				Continue;
			EndIf;
			
			If HandlerTree.Rows[0].Rows.FindRows(
					New Structure("ExclusiveMode", Undefined)).Count() > 0 Then
					
				Return False; // Mandatory handlers with unconditional exclusive mode are available
			EndIf;
			
			// Calling the mandatory update handlers in check mode
			For Each Handler In HandlerTree.Rows[0].Rows Do
				If Handler.RegistrationVersion <> "*" Then
					Return False; // Exclusive version update handlers are available
				EndIf;
				
				HandlerParameters = New Structure;
				If Handler.HandlerManagement Then
					HandlerParameters.Insert("SeparatedHandlers", RequiredSeparatedHandlers);
				EndIf;
				HandlerParameters.Insert("ExclusiveMode", False);
				
				AdditionalParameters = New Structure("WriteToLog, LibraryID, HandlerExecutionProgress, InBackground",
					WriteToLog, UpdateIteration.Subsystem, Undefined, False);
				
				ExecuteUpdateHandler(Handler, HandlerParameters, AdditionalParameters);
				
				If HandlerParameters.ExclusiveMode = True Then
					Return False; // Update in exclusive mode is necessary
				EndIf;
			EndDo;
			
		EndDo;
	EndDo;
	
	Return True;
	
EndFunction

Procedure CopyRowsToTree(Val TargetRows, Val SourceRows, Val ColumnStructure)
	
	For Each SourceRow In SourceRows Do
		FillPropertyValues(ColumnStructure, SourceRow);
		FoundRows = TargetRows.FindRows(ColumnStructure);
		If FoundRows.Count() = 0 Then
			TargetRow = TargetRows.Add();
			FillPropertyValues(TargetRow, SourceRow);
		Else
			TargetRow = FoundRows[0];
		EndIf;
		
		CopyRowsToTree(TargetRow.Rows, SourceRow.Rows, ColumnStructure);
	EndDo;
	
EndProcedure

Function GetUpdatePlan(Val LibraryID, Val VersionFrom, Val VersionTo)
	
	RecordManager = InformationRegisters.SubsystemVersions.CreateRecordManager();
	RecordManager.SubsystemName = LibraryID;
	RecordManager.Read();
	If Not RecordManager.Selected() Then
		Return Undefined;
	EndIf;
	
	PlanDetails = RecordManager.UpdatePlan.Get();
	If PlanDetails = Undefined Then
		
		Return Undefined;
		
	Else
		
		If PlanDetails.VersionFrom <> VersionFrom
			Or PlanDetails.VersionTo <> VersionTo Then
			
			// The update plan is outdated and cannot be applied to the current version
			Return Undefined;
		EndIf;
		
		Return PlanDetails.Plan;
		
	EndIf;
	
EndFunction

// Detaches the updates handlers filled in procedure InfobaseUpdateOverridable.AddDetachableUpdateHandlers.
//
// Parameters:
//  LibraryID               - String    - configuration name or library ID.
//  HandlersToExecute       - ValueTree - infobase update handlers.
//  InfobaseMetadataVersion - String    - metadata version. Only the handlers with versions matching 
//                                        the metadata version are detached.
//
Procedure DetachUpdateHandlers(LibraryID, HandlersToExecute, MetadataVersion, HandlerExecutionProgress)
	
	DetachableHandlers = New ValueTable;
	DetachableHandlers.Columns.Add("LibraryID");
	DetachableHandlers.Columns.Add("Procedure");
	DetachableHandlers.Columns.Add("Version");
	
	InfobaseUpdateOverridable.AddDetachableUpdateHandlers(DetachableHandlers);
	// Searching for a tree row containing update handlers of version "*"
	LibraryHandlers = HandlersToExecute.Rows.Find("*", "Version", False);
	
	For Each DetachableHandler In DetachableHandlers Do
		
		// Checking whether the detachable handler belongs to the passed library
		If LibraryID <> DetachableHandler.LibraryID Then
			Continue;
		EndIf;
		
		// Checking whether the handler is in the exception list
		HandlerToExecute = HandlersToExecute.Rows.Find(DetachableHandler.Procedure, "Procedure", True);
		If HandlerToExecute <> Undefined And HandlerToExecute.Version = "*"
			And DetachableHandler.Version = MetadataVersion Then
			LibraryHandlers.Rows.Delete(HandlerToExecute);
			HandlerExecutionProgress.TotalHandlerCountForVersion = HandlerExecutionProgress.TotalHandlerCountForVersion - 1;
		ElsIf HandlerToExecute <> Undefined And HandlerToExecute.Version <> "*"
			And DetachableHandler.Version = MetadataVersion Then
			ErrorMessage = NStr("en='Update handler %1 cannot be detached, because it is only executed when updating to version %2'");
			ErrorMessage = StringFunctionsClientServer.SubstituteParametersInString(ErrorMessage,
				HandlerToExecute.Procedure, HandlerToExecute.Version);
			
			Raise ErrorMessage;
		ElsIf HandlerToExecute = Undefined Then
			ErrorMessage = NStr("en='Detachable update handler %1 does not exist'");
			ErrorMessage = StringFunctionsClientServer.SubstituteParametersInString(ErrorMessage,
				DetachableHandler.Procedure);
			
			Raise ErrorMessage;
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ExecuteUpdateHandler(Handler, Parameters, AdditionalParameters)
	
	WriteUpdateProgressInformation(Handler, AdditionalParameters.HandlerExecutionProgress, AdditionalParameters.InBackground);
	If AdditionalParameters.WriteToLog Then
		HandlerDetails = 
			PrepareUpdateProgressDetails(Handler, Parameters, AdditionalParameters.LibraryID);
	EndIf;
	
	If Parameters <> Undefined Then
		HandlerParameters = New Array;
		HandlerParameters.Add(Parameters);
	Else
		HandlerParameters = Undefined;
	EndIf;
	
	TransactionActiveAtExecutionStartTime = TransactionActive();
	
	Try
		SafeMode.ExecuteConfigurationMethod(Handler.Procedure, HandlerParameters);
	Except
		
		If AdditionalParameters.WriteToLog Then
			WriteUpdateProgressDetails(HandlerDetails);
		EndIf;
		
		HandlerName = Handler.Procedure + "(" + ?(HandlerParameters = Undefined, "", "Parameters") + ")";
		
		WriteError(StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Error %2 occurred
					   |when calling update handler %1.'"),
			HandlerName,
			DetailErrorDescription(ErrorInfo())));
		
		Raise;
	EndTry;
	
	ValidateNestedTransaction(TransactionActiveAtExecutionStartTime, Handler.Procedure);
	
	If AdditionalParameters.WriteToLog Then
		WriteUpdateProgressDetails(HandlerDetails);
	EndIf;
	
EndProcedure

Procedure ExecuteHandlersAfterInfobaseUpdate(Val UpdateIterations, Val WriteToLog, ShowUpdateDetails, Val NonexclusiveUpdate)
	
	For Each UpdateIteration In UpdateIterations Do
		
		If WriteToLog Then
			Handler = New Structure();
			Handler.Insert("Version", "*");
			Handler.Insert("RegistrationVersion", "*");
			Handler.Insert("ExecutionMode", "Nonexclusive");
			Handler.Insert("Procedure", UpdateIteration.MainServerModuleName + ".AfterInfobaseUpdate");
			HandlerDetails =  PrepareUpdateProgressDetails(Handler, Undefined, UpdateIteration.Subsystem);
		EndIf;
		
		Try
			
			UpdateIteration.MainServerModule.AfterInfobaseUpdate(
				UpdateIteration.PreviousVersion,
				UpdateIteration.Version,
				UpdateIteration.ExecutedHandlers,
				ShowUpdateDetails,
				Not NonexclusiveUpdate);
				
		Except
			
			If WriteToLog Then
				WriteUpdateProgressDetails(HandlerDetails);
			EndIf;
			
			Raise;
			
		EndTry;
		
		If WriteToLog Then
			WriteUpdateProgressDetails(HandlerDetails);
		EndIf;
		
	EndDo;
	
EndProcedure

Function PrepareUpdateProgressDetails(Handler, Parameters, LibraryID, HandlerDeferred = False)
	
	HandlerDetails = New Structure;
	HandlerDetails.Insert("Library", LibraryID);
	If HandlerDeferred Then
		HandlerDetails.Insert("Version", Handler.VersionNumber);
		HandlerDetails.Insert("Procedure", Handler.HandlerName);
	Else
		HandlerDetails.Insert("Version", Handler.Version);
		HandlerDetails.Insert("Procedure", Handler.Procedure);
	EndIf;
	HandlerDetails.Insert("RegistrationVersion", Handler.RegistrationVersion);
	HandlerDetails.Insert("Parameters", Parameters);
	
	If HandlerDeferred Then
		HandlerDetails.Insert("ExecutionMode", "Deferred");
	ElsIf ValueIsFilled(Handler.ExecutionMode) Then
		HandlerDetails.Insert("ExecutionMode", Handler.ExecutionMode);
	Else
		HandlerDetails.Insert("ExecutionMode", "Exclusive");
	EndIf;
	
	If CommonUseCached.IsSeparatedConfiguration()
		And CommonUse.UseSessionSeparator() Then
		
		HandlerDetails.Insert("DataAreaValue", CommonUse.SessionSeparatorValue());
		HandlerDetails.Insert("UseDataArea", True);
		
	Else
		
		HandlerDetails.Insert("DataAreaValue", -1);
		HandlerDetails.Insert("UseDataArea", False);
		
	EndIf;
	
	HandlerDetails.Insert("ValueAtStart", CurrentUniversalDateInMilliseconds());
	
	Return HandlerDetails;
	
EndFunction

Procedure WriteUpdateProgressDetails(HandlerDetails)
	
	Duration = CurrentUniversalDateInMilliseconds() - HandlerDetails.ValueAtStart;
	
	HandlerDetails.Insert("Completed", False);
	HandlerDetails.Insert("Duration", Duration / 1000); // In seconds
	
	WriteLogEvent(
		EventLogRecordProtocol(),
		EventLogLevel.Information,
		,
		,
		CommonUse.ValueToXMLString(HandlerDetails));
	
EndProcedure

Procedure ValidateNestedTransaction(TransactionActiveAtExecutionStartTime, HandlerName)
	
	EventName = EventLogMessageText() + ". " + NStr("en = 'Executing handlers'", CommonUseClientServer.DefaultLanguageCode());
	If TransactionActiveAtExecutionStartTime Then
		
		If TransactionActive() Then
			// Checking the absorbed exceptions in handlers
			Try
				Constants.UseSeparationByDataAreas.Get();
			Except
				CommentPattern = NStr("en = 'Update handler %1 execution error:
				|The update handler absorbed an exclusion during active external transaction.
				|If an active transaction was opened up the stack, the exception must also be moved up the stack.'");
				Comment = StringFunctionsClientServer.SubstituteParametersInString(CommentPattern, HandlerName);
				
				WriteLogEvent(EventName, EventLogLevel.Error,,, Comment);
				Raise(Comment);
			EndTry;
		Else
			CommentPattern = NStr("en = 'Update handler %1 execution error: 
			|The update handler closed a redundant transaction opened earlier (up the stack).'");
			Comment = StringFunctionsClientServer.SubstituteParametersInString(CommentPattern, HandlerName);
			
			WriteLogEvent(EventName, EventLogLevel.Error,,, Comment);
			Raise(Comment);
		EndIf;
	Else
		If TransactionActive() Then
			CommentPattern = NStr("en = 'Update handler %1 execution error: 
			|A transaction opened in the update handler was not cancelled or closed, and therefore remained active.'");
			Comment = StringFunctionsClientServer.SubstituteParametersInString(CommentPattern, HandlerName);
			
			WriteLogEvent(EventName, EventLogLevel.Error,,, Comment);
			Raise(Comment);
		EndIf;
	EndIf;
	
EndProcedure

Procedure ValidateHandlerProperties(UpdateIteration)
	
	For Each Handler In UpdateIteration.Handlers Do
		ErrorDescription = "";
		
		If IsBlankString(Handler.Version) Then
			
			If Handler.InitialFilling <> True Then
				ErrorDescription = NStr("en = 'Version or InitialFilling property of the handler is not filled.'");
			EndIf;
			
		ElsIf Handler.Version <> "*" Then
			
			Try
				ZeroVersion = CommonUseClientServer.CompareVersions(Handler.Version, "0.0.0.0") = 0;
			Except
				ZeroVersion = False;
				ErrorDescription = StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en = 'Invalid value of Version property of the handler %1.
					           |Valid format example: ""2.1.3.70"".'"),
					Metadata.Version);
			EndTry;
			
			If ZeroVersion Then
				ErrorDescription = StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en = 'Invalid value of Version property of the handler %1.
					           |Version number cannot be equal to zero.'"),
					Metadata.Version);
			EndIf;
			
			If Not ValueIsFilled(ErrorDescription)
			   And Handler.ExecuteInMandatoryGroup <> True
			   And Handler.Priority <> 0 Then
				
				ErrorDescription = NStr("en = 'Priority or ExecuteInMandatoryGroup property of the handler is filled incorrectly.'");
			EndIf;
		EndIf;
		
		If Handler.ExecutionMode <> ""
			And Handler.ExecutionMode <> "Exclusive"
			And Handler.ExecutionMode <> "Nonexclusive"
			And Handler.ExecutionMode <> "Deferred" Then
			ErrorDescription = StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Invalid value of ExecutionMode property of the handler %1.
				           |Allowed values: Exclusive, Deferred, Nonexclusive.'"),
				Handler.Procedure);
		EndIf;
		
		If Not ValueIsFilled(ErrorDescription)
		   And Handler.Optional = True
		   And Handler.InitialFilling = True Then
			
			ErrorDescription = NStr("en = 'Optional or InitialFilling property of the handler is filled incorrectly.'");
		EndIf;
			
		If Not ValueIsFilled(ErrorDescription) Then
			Continue;
		EndIf;
		
		If UpdateIteration.IsMainConfiguration Then
			ErrorTitle = NStr("en = 'Configuration update handler property error'");
		Else
			ErrorTitle = StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Library %1 (version %2) update handler property error'"),
				UpdateIteration.Subsystem,
				UpdateIteration.Version);
		EndIf;
		
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersInString(
			ErrorTitle + Chars.LF
			+ NStr("en = '(%1).'") + Chars.LF
			+ Chars.LF
			+ ErrorDescription,
			Handler.Procedure);
		
		WriteError(ErrorDescription);
		Raise ErrorDescription;

	EndDo;
	
EndProcedure

Function HandlerCountForCurrentVersion(UpdateIterations)
	
	HandlerCount = 0;
	For Each UpdateIteration In UpdateIterations Do
		
		HandlersByVersion = UpdateInIntervalHandlers(
			UpdateIteration.Handlers, UpdateIteration.PreviousVersion, UpdateIteration.Version);
		For Each HandlersRowVersion In HandlersByVersion.Rows Do
			HandlerCount = HandlerCount + HandlersRowVersion.Rows.Count();
		EndDo;
		
	EndDo;
	
	Message = NStr("en = 'Handlers %1 will be executed to update the application version.'");
	Message = StringFunctionsClientServer.SubstituteParametersInString(Message, HandlerCount);
	WriteInformation(Message);
	
	Return New Structure("TotalHandlers, HandlersCompleted", HandlerCount, 0);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Saves the update progress information.

Procedure WriteInformation(Val Text)
	
	WriteLogEvent(EventLogMessageText(), EventLogLevel.Information,,, Text);
	
EndProcedure

Procedure WriteError(Val Text)
	
	WriteLogEvent(EventLogMessageText(), EventLogLevel.Error,,, Text);
	
EndProcedure

Procedure WriteUpdateProgressInformation(Handler, HandlerExecutionProgress, InBackground)
	
	If HandlerExecutionProgress = Undefined Then
		Return;
	EndIf;
	
	HandlerExecutionProgress.HandlersCompleted = HandlerExecutionProgress.HandlersCompleted + 1;
	
	If Not CommonUseCached.DataSeparationEnabled() Then
		Message = NStr("en = 'Executing update handler %1 (%2 of %3).'");
		Message = StringFunctionsClientServer.SubstituteParametersInString(
			Message, Handler.Procedure,
			HandlerExecutionProgress.HandlersCompleted, HandlerExecutionProgress.TotalHandlers);
		WriteInformation(Message);
	EndIf;
	
	If InBackground Then
		Progress = HandlerExecutionProgress.HandlersCompleted / HandlerExecutionProgress.TotalHandlers * 100;
		CommonUseClientServer.MessageToUser("ProgressStepIncrement=" + Progress);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Update details

// Displays update change description for a specified version.
//
// Parameters
//   VersionNumber - String - Version number used when displaying the description 
//                            from UpdateDetailsTemplate spreadsheet document template 
//                            to UpdateDetailsDocument spreadsheet document.
//
Procedure OutputUpdateDetails(Val VersionNumber, UpdateDetailsDocument, UpdateDetailsTemplate)
	
	Number = StrReplace(VersionNumber, ".", "_");
	
	If UpdateDetailsTemplate.Areas.Find("Header" + Number) = Undefined Then
		Return;
	EndIf;
	
	UpdateDetailsDocument.Put(UpdateDetailsTemplate.GetArea("Header" + Number));
	UpdateDetailsDocument.StartRowGroup("Version" + Number);
	UpdateDetailsDocument.Put(UpdateDetailsTemplate.GetArea("Version" + Number));
	UpdateDetailsDocument.EndRowGroup();
	UpdateDetailsDocument.Put(UpdateDetailsTemplate.GetArea("Indent"));
	
EndProcedure

// Returns True when update details display is enabled for the user 
// and some update details not yet displayed are available.
//
Function ShowApplicationReleaseNotes()
	
	UpdateDetails = InfobaseUpdateDetails();
	If UpdateDetails.ShowUpdateDetails = False Then
		Return False;
	EndIf;
	
	If Not AccessRight("SaveUserData", Metadata) Then
		// Version update descriptions are not displayed for anonymous users
		Return False;
	EndIf;
	
	DisplayChangeDescriptionForAdministrator = CommonUse.CommonSettingsStorageLoad("InfobaseUpdate", "DisplayChangeDescriptionForAdministrator",,, UserName());
	If DisplayChangeDescriptionForAdministrator = True Then
		CommonUse.CommonSettingsStorageDelete("InfobaseUpdate", "DisplayChangeDescriptionForAdministrator", UserName());
		Return True;
	EndIf;
	
	If Not IsInRole(Metadata.Roles.ViewApllicationChangeLog)
		And Not IsInRole(Metadata.Roles.FullAccess) Then
		Return False;
	EndIf;
	
	LastVersion = SystemChangesDisplayLastVersion();
	If LastVersion = Undefined Then
		Return True;
	EndIf;
	
	Sections = UpdateDescriptionSections();
	
	If Sections = Undefined Then
		Return False;
	EndIf;
	
	Return GetLaterVersions(Sections, LastVersion).Count() > 0;
	
EndFunction

Function SystemChangesDisplayLastVersion(Val UserName = Undefined)
	
	If UserName = Undefined Then
		UserName = UserName();
	EndIf;
	
	LastVersion = CommonUse.CommonSettingsStorageLoad("InfobaseUpdate",
		"SystemChangesDisplayLastVersion", , , UserName);
	
	Return LastVersion;
	
EndFunction

// Gets version list from the ApplicationReleaseNotes common template
// and saves it to the ApplicationChangeLogSections constant.
//
Procedure UpdateChangeDescriptionSections()
	
	Sections = New ValueList;
	
	UpdateDetailsTemplate = Metadata.CommonTemplates.Find("ApplicationReleaseNotes");
	If UpdateDetailsTemplate <> Undefined Then
		VersionPredicate = "Version";
		HeaderPredicate = "Header";
		Template = GetCommonTemplate(UpdateDetailsTemplate);
		
		For Each Area In Template.Areas Do
			If Find(Area.Name, VersionPredicate) = 0 Then
				Continue;
			EndIf;
			
			VersionInDescriptionFormat = Mid(Area.Name, StrLen(VersionPredicate) + 1);
			
			If Template.Areas.Find(HeaderPredicate + VersionInDescriptionFormat) = Undefined Then
				Continue;
			EndIf;
			
			VersionDigitsAsStrings = StringFunctionsClientServer.SplitStringIntoSubstringArray(VersionInDescriptionFormat, "_");
			If VersionDigitsAsStrings.Count() <> 4 Then
				Continue;
			EndIf;
			
			VersionWeight = VersionWeightFromStringArray(VersionDigitsAsStrings);
			
			Version = ""
				+ Number(VersionDigitsAsStrings[0]) + "."
				+ Number(VersionDigitsAsStrings[1]) + "."
				+ Number(VersionDigitsAsStrings[2]) + "."
				+ Number(VersionDigitsAsStrings[3]);
				
			Sections.Add(VersionWeight, Version);
		EndDo;
		
		Sections.SortByValue(SortDirection.Desc);
	EndIf;
	
	Constants.ApplicationChangeLogSections.Set(New ValueStorage(Sections));
	
EndProcedure

Procedure DefineUpdateDetailsDisplay(ShowUpdateDetails)
	
	If Not CommonUseCached.DataSeparationEnabled()
		Or Not CommonUseCached.CanUseSeparatedData() Then
		
		UpdateChangeDescriptionSections();
	EndIf;
	
	If ShowUpdateDetails And Not CommonUseCached.DataSeparationEnabled() Then
		CommonUse.CommonSettingsStorageSave("InfobaseUpdate", "DisplayChangeDescriptionForAdministrator", True, , UserName());
	EndIf;
	
	If CommonUseCached.CanUseSeparatedData() Then
		InfobaseUpdateDetails = InfobaseUpdateDetails();
		InfobaseUpdateDetails.ShowUpdateDetails = ShowUpdateDetails;
		
		WriteInfobaseUpdateDetails(InfobaseUpdateDetails);
	EndIf;
	
EndProcedure

// Returns a list of update change details sections.
//
// Returns:
//  ValueList - Value - version weight (number).
// Presentation - version number string
//
Function UpdateDescriptionSections()
	
	Return Constants.ApplicationChangeLogSections.Get().Get();
	
EndFunction

Function VersionWeightFromStringArray(VersionDigitsAsStrings)
	
	Return 0
		+ Number(VersionDigitsAsStrings[0]) * 1000000000
		+ Number(VersionDigitsAsStrings[1]) * 1000000
		+ Number(VersionDigitsAsStrings[2]) * 1000
		+ Number(VersionDigitsAsStrings[3]);
	
EndFunction

Function GetLaterVersions(Sections, Version)
	
	Result = New Array;
	
	If Sections = Undefined Then
		UpdateChangeDescriptionSections();
		Sections = UpdateDescriptionSections();
	EndIf;
	
	VersionWeight = VersionWeight(Version);
	For Each ListItem In Sections Do
		If ListItem.Value <= VersionWeight Then
			Continue;
		EndIf;
		
		Result.Add(ListItem.Presentation);
	EndDo;
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Auxiliary procedures and deferred update functions

// For internal use only
//
Function PreviousVersionHandlersCompleted(UpdateIterations)
	
	UpdateDetails = InfobaseUpdateDetails();
	If UpdateDetails.DeferredUpdateCompletedSuccessfully <> True
		And UpdateDetails.HandlerTree <> Undefined
		And UpdateDetails.HandlerTree.Rows.Count() > 0 Then
		
		SaveUncompletedHandlersRequired = False;
		For Each Library In UpdateIterations Do
			// Clearing count of handler attempt with Error status
			HandlersFound = UpdateDetails.HandlerTree.Rows.FindRows(New Structure("Status, LibraryName", "Error", Library.Subsystem), True);
			For Each TreeItem In HandlersFound Do
				If TreeItem.VersionNumber <> "*"
					And CommonUseClientServer.CompareVersions(Library.PreviousVersion, TreeItem.VersionNumber) >= 0 Then
					SaveUncompletedHandlersRequired = True;
				EndIf;
				TreeItem.AttemptNumber = 0;
			EndDo;
			
			// Searching for uncompleted handlers that must be saved for further restart
			HandlersFound = UpdateDetails.HandlerTree.Rows.FindRows(New Structure("Status, LibraryName", "Uncompleted", Library.Subsystem), True);
			For Each TreeItem In HandlersFound Do
				If TreeItem.VersionNumber <> "*"
					And CommonUseClientServer.CompareVersions(Library.PreviousVersion, TreeItem.VersionNumber) >= 0 Then
					SaveUncompletedHandlersRequired = True;
				EndIf;
			EndDo;
			
			If SaveUncompletedHandlersRequired Then
				SaveUncompletedHandlersRequired = False;
			Else
				RowLibrary = UpdateDetails.HandlerTree.Rows.Find(Library.Subsystem, "LibraryName");
				If RowLibrary <> Undefined Then
					UpdateDetails.HandlerTree.Rows.Delete(RowLibrary);
				EndIf;
			EndIf;
			
		EndDo;
		
		// Deleting successfully completed handlers
		HandlersFound = UpdateDetails.HandlerTree.Rows.FindRows(New Structure("Status", "Completed"), True);
		For Each TreeItem In HandlersFound Do
			VersionString = TreeItem.Parent.Rows;
			VersionString.Delete(TreeItem);
		EndDo;
		
		Return UpdateDetails.HandlerTree;
		
	EndIf;
	
	Return NewUpdateHandlerInformation();
	
EndFunction

// For internal use only
//
Procedure ValidateCompletedHandlerTree(HandlerTree)
	
	For Each TreeRowLibrary In HandlerTree.Rows Do
		
		For Each TreeRowVersion In TreeRowLibrary.Rows Do
			
			If TreeRowVersion.Rows.Count() = 0 Then
				TreeRowVersion.Status = "Completed";
			Else
				TreeRowVersion.Status = "";
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// For internal use only
//
Procedure CancelDeferredUpdate()
	
	If CommonUseCached.DataSeparationEnabled() Then
		OnEnableDeferredUpdate(False);
	Else
		ScheduledJob = ScheduledJobs.FindPredefined(Metadata.ScheduledJobs.DeferredInfobaseUpdate);
		ScheduledJob.Use = False;
		ScheduledJob.Write();
	EndIf;
	
EndProcedure

// For internal use only
//
Function ExecuteDeferredUpdateHandler(UpdateDetails, ExecuteUnsuccessful = False)
	
	IsHandlersCompleted = False;
	HasUnsuccessful     = False;
	HasSkippedHandlers  = False;
	WriteToLog = Constants.WriteInfobaseUpdateDetailsToEventLog.Get();
	
	For Each HandlerTreeLibrary In UpdateDetails.HandlerTree.Rows Do
		
		If HandlerTreeLibrary.Status = "Completed" Then
			Continue;
		EndIf;
		
		For Each HandlerTreeVersion In HandlerTreeLibrary.Rows Do
			
			If HandlerTreeVersion.Status = "Completed" Then
				Continue;
			EndIf;
			
			For Each UpdateHandler In HandlerTreeVersion.Rows Do
				
				If UpdateHandler.Status = "Completed" Then
					Continue;
				EndIf;
				
				If UpdateHandler.AttemptNumber > 0 And Not ExecuteUnsuccessful Then
					HasUnsuccessful = True;
					Continue;
				EndIf;
				
				If UpdateHandler.AttemptNumber >= 3 Then
					HasSkippedHandlers = True;
					Continue;
				EndIf;
				
				TransactionActiveAtExecutionStartTime = TransactionActive();
				IsHandlersCompleted = True;
				HandlerName = UpdateHandler.HandlerName;
				Try
					HandlerExecutionMessage = NStr("en = 'Executing update procedure %1.'");
					HandlerExecutionMessage = StringFunctionsClientServer.SubstituteParametersInString(
						HandlerExecutionMessage, HandlerName);
					WriteLogEvent(EventLogMessageText(), 
							EventLogLevel.Information,,, HandlerExecutionMessage);
					
					Parameters = Undefined;
					If UpdateDetails.Property("UpdateHandlerParameters", Parameters) Then
						If TypeOf(Parameters) = Type("Structure") Then
							Parameters.Insert("ProcessingCompleted", True);
						Else
							Parameters = New Structure("ProcessingCompleted", True);
						EndIf;
					Else
						Parameters = New Structure("ProcessingCompleted", True);
					EndIf;
					
					HandlerParameters = New Array;
					HandlerParameters.Add(Parameters);
					
					If WriteToLog Then
						HandlerDetails = PrepareUpdateProgressDetails(UpdateHandler, Parameters, UpdateHandler.LibraryName, True);
					EndIf;
					
					UpdateHandler.Status = "Executing";
					SafeMode.ExecuteConfigurationMethod(HandlerName, HandlerParameters);
					
					// Update handler passed parameters that need to be saved.
					If Parameters.Count() > 1 And Not Parameters.ProcessingCompleted Then
						UpdateDetails.Insert("UpdateHandlerParameters", Parameters);
					EndIf;
					
					If Parameters.ProcessingCompleted Then
						UpdateHandler.Status = "Completed";
						UpdateDetails.Delete("UpdateHandlerParameters");
						WriteInfobaseUpdateDetails(UpdateDetails);
					EndIf;
					
					If UpdateHandler.Status = "Executing" Then
						WriteInfobaseUpdateDetails(UpdateDetails);
					EndIf;
					
				Except
					
					If WriteToLog Then
						WriteUpdateProgressDetails(HandlerDetails);
					EndIf;
					
					While TransactionActive() Do
						RollbackTransaction();
					EndDo;
					
					UpdateHandler.Status = "Error";
					UpdateDetails.Delete("UpdateHandlerParameters");
					UpdateHandler.AttemptNumber = UpdateHandler.AttemptNumber + 1;
					ErrorInfo = ErrorInfo();
					UpdateHandler.ErrorInfo = BriefErrorDescription(ErrorInfo());
					WriteInfobaseUpdateDetails(UpdateDetails);
					WriteError(DetailErrorDescription(ErrorInfo));
				EndTry;
				
				ValidateNestedTransaction(TransactionActiveAtExecutionStartTime, HandlerName);
				
				If WriteToLog Then
					WriteUpdateProgressDetails(HandlerDetails);
				EndIf;
				
				Break;
			EndDo;
			
			If Not IsHandlersCompleted And HasUnsuccessful And Not ExecuteUnsuccessful Then
				Return ExecuteDeferredUpdateHandler(UpdateDetails, True);
			EndIf;
			
			If HasUnsuccessful Or IsHandlersCompleted Then
				Break;
			Else
				
				If HasSkippedHandlers Then
					HandlerTreeVersion.Status = "HasSkippedHandlers";
				Else
					HandlerTreeVersion.Status = "Completed";
				EndIf;
				
			EndIf;
			
		EndDo;
		
		If HasUnsuccessful Or IsHandlersCompleted Then
			Break;
		Else
			
			If HasSkippedHandlers Then
				HandlerTreeLibrary.Status = "HasSkippedHandlers";
				Break;
			EndIf;
			
			HandlerTreeLibrary.Status = "Completed";
		EndIf;
		
	EndDo;
	
	If Not IsHandlersCompleted Then
		
		UpdateDetails.DeferredUpdateEndTime = CurrentSessionDate();
		UpdateDetails.DeferredUpdateCompletedSuccessfully = Not HasSkippedHandlers;
		WriteInfobaseUpdateDetails(UpdateDetails);
		
	EndIf;
	Return IsHandlersCompleted;
	
EndFunction

// For internal use only
//
Function NewUpdateInformation(OldInformation = Undefined)
	
	UpdateDetails = New Structure;
	UpdateDetails.Insert("UpdateStartTime");
	UpdateDetails.Insert("UpdateEndTime");
	UpdateDetails.Insert("UpdateDuration");
	UpdateDetails.Insert("DeferredUpdateStartTime");
	UpdateDetails.Insert("DeferredUpdateEndTime");
	UpdateDetails.Insert("SessionNumber", New ValueList());
	UpdateDetails.Insert("UpdateHandlerParameters");
	UpdateDetails.Insert("DeferredUpdateCompletedSuccessfully");
	UpdateDetails.Insert("HandlerTree", New ValueTree());
	UpdateDetails.Insert("ShowUpdateDetails", False);
	UpdateDetails.Insert("LegitimateVersion", "");
	
	If TypeOf(OldInformation) = Type("Structure") Then
		FillPropertyValues(UpdateDetails, OldInformation);
	EndIf;
	
	Return UpdateDetails;
	
EndFunction

// For internal use only
//
Function NewUpdateHandlerInformation()
	
	HandlerTree = New ValueTree;
	HandlerTree.Columns.Add("LibraryName");
	HandlerTree.Columns.Add("VersionNumber");
	HandlerTree.Columns.Add("RegistrationVersion");
	HandlerTree.Columns.Add("HandlerName");
	HandlerTree.Columns.Add("Status");
	HandlerTree.Columns.Add("AttemptNumber");
	HandlerTree.Columns.Add("ErrorInfo");
	HandlerTree.Columns.Add("Comment");
	
	Return HandlerTree;
	
EndFunction

// Validates status of deferred update handlers.
//
Function UncompletedHandlersStatus()
	
	UpdateDetails = InfobaseUpdateDetails();
	For Each TreeRowLibrary In UpdateDetails.HandlerTree.Rows Do
		For Each TreeRowVersion In TreeRowLibrary.Rows Do
			For Each Handler In TreeRowVersion.Rows Do
				If Handler.Status = "Error" Then
					Return "ErrorStatus";
				ElsIf Handler.Status <> "Completed" Then
					Return "UncompletedStatus";
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
	Return "";
	
EndFunction

#EndRegion