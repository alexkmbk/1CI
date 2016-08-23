////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
// Common server procedures and functions for working with:
// - Security profiles.
//
////////////////////////////////////////////////////////////////////////////////

#Region InternalInterface

////////////////////////////////////////////////////////////////////////////////
// Event declaration.
//

// Declares internal events of the BaseFunctionality subsystem intended for supports security
// profiles.
//
// See the description of this procedure in the StandardSubsystemsServer module.
Procedure OnAddInternalEvent(ClientEvents, ServerEvents) Export
	
	// SERVER EVENTS.
	
	// Is called during the verification whether security profiles can be used.
	//
	// Parameters:
	//  Cancel - Boolean - set the parameter to True if security profiles cannot be used for the
	//           infobase.
	//
	// Syntax:
	//  Procedure CanUseSecurityProfilesOnCheck(Cancel) Export
	ServerEvents.Add(
		"StandardSubsystems.BaseFunctionality\CanUseSecurityProfilesOnCheck");
	
	// Is called during the verification whether security profiles can be set up.
	//
	// Parameters:
	//  Cancel - Boolean - set the parameter to True if security profiles cannot be used for the
	//           infobase.
	//
	// Syntax:
	//  Procedure CanSetupSecurityProfilesOnCheck(Cancel) Export
	ServerEvents.Add(
		"StandardSubsystems.BaseFunctionality\CanSetupSecurityProfilesOnCheck");
	
	// Is called when the security profiles are being enabled for the infobase.
	//
	// Syntax:
	// Procedure SecurityProfilesOnEnable() Export
	//
	ServerEvents.Add(
		"StandardSubsystems.BaseFunctionality\SecurityProfilesOnEnable");
	
	// Fills a request list of external permissions to be necessarily granted during the infobase
	// creation or updating.
	//
	// Parameters:
	//  PermissionRequests - Array - request list returned by the RequestToUseExternalResources
	//                       function of the SafeMode module.
	//
	// Syntax:
	//  Procedure OnFillPermissionsToAccessExternalResources(PermissionRequests) Export
	//
	ServerEvents.Add(
		"StandardSubsystems.BaseFunctionality\OnFillPermissionsToAccessExternalResources");
	
	// Is called during the registration of the external module managers.
	//
	// Parameters:
	//  Managers - Array of CommonModule.
	//
	// Syntax:
	//  Procedure ExternalModuleManagersOnRegistration(Managers) Export
	//
	ServerEvents.Add(
		"StandardSubsystems.BaseFunctionality\ExternalModuleManagersOnRegistration");
	
	// Is called when generating a request for administrating permissions to use external resources.
	//
	// Parameters:
	//  ExternalModule     - AnyRef; 
	//  Operation          - EnumRef.OperationsWithPermissionSets;
	//  StandardProcessing - Boolean - flag that shows whether the standard external resource
	//                       administration request processing is executed;
	//  Result             - UUID - request ID (if the StandardProcessing handler parameter is
	//                       False).
	//
	// Syntax:
	//  Procedure ExternalResourcePermissionAdministrationOnRequest(Val ExternalModule Val Operation, StandardProcessing Result) Export
	//
	ServerEvents.Add(
		"StandardSubsystems.BaseFunctionality\ExternalResourcePermissionAdministrationOnRequest");
	
	// Is called during the external resource request generation.
	//
	// Parameters:
	//  Owner               - AnyRef -  owner of the requested permissions to use external
	//                        resources.
	//  ReplacementMode     - Boolean - flag that shows whether the previously granted permissions
	//                        are replaced.
	//  PermissionsToAdd    - Array of XDTODataObject - array of permissions to be added.
	//  PermissionsToDelete - Array of XDTODataObject - array of permissions to be deleted.
	//  StandardProcessing  - Boolean - flag that shows whether the standard external resource
	//                        request generation processing is executed.
	//  Result              - UUID - request ID (if the StandardProcessing handler parameter is
	//                        False).
	//
	// Syntax:
	//  Procedure PermissionsToUseExternalResourceOnRequest(Val Owner, Val ReplacementMode Val PermissionsToAdd = Undefined, Val PermissionsToDelete = Undefined, StandardProcessing Result) Export
	//
	ServerEvents.Add(
		"StandardSubsystems.BaseFunctionality\PermissionsToUseExternalResourceOnRequest");
	
	// Is called during the calculation of the external resource change delta.
	//
	// Parameters:
	//  RequestIDs         - Array of UUID - array of request IDs for which the delta is 
	//                       calculated.
	//  RecoveryMode       - Boolean - flag that shows whether the delta is calculated in the
	//                       permission recovery mode.
	//  StandardProcessing - Boolean - flag that shows whether the standard delta calculation is
	//                       executed.
	//  Result             - ValueTable - external resource permission change delta (if the
	//                       StandardProcessing handler parameter is False).
	//
	// Syntax:
	//  Procedure ExternalResourceChangeDeltaOnCalculate(Val RequestIDs Val RecoveryMode StandardProcessing Result) Export
	//
	ServerEvents.Add(
		"StandardSubsystems.BaseFunctionality\ExternalResourceChangeDeltaOnCalculate");
	
	// Is called during the external resource request applying.
	//
	// Parameters:
	//  RequestIDs         - Array of UUID - array of request IDs.
	//  StandardProcessing - Boolean - flag that shows whether the standard external resource 
	//                       request applying processing is executed.
	//
	// Syntax:
	//  Procedure ExternalResourceRequestsOnApply(Val RequestIDs StandardProcessing) Export
	//
	ServerEvents.Add(
		"StandardSubsystems.BaseFunctionality\ExternalResourceRequestsOnApply");
	
	// Is called after the external resource request processing.
	//
	// Parameters:
	//  RequestIDs         - Array of UUID - array of request IDs,
	//  RecoveryMode       - Boolean - flag that shows whether the requests for permission 
	//                       recovery are called in the server cluster if writing of the objects 
	//                       that requires permissions to use external resources is canceled.
	//  StandardProcessing - Boolean - that shows whether the standard processing is executed.
	//
	// Syntax:
	//  Procedure ExternalResourceRequestsAfterProcess(Val RequestIDs Val RecoveryMode StandardProcessing) Export
	//
	ServerEvents.Add(
		"StandardSubsystems.BaseFunctionality\ExternalResourceRequestsAfterProcess");
	
	// CLIENT EVENTS.
	
	// Is called when processing the requests for permissions to use external resources.
	// 
	// Parameters:
	//  IDs                 - Array of UUID - IDs of the requests to be applied.
	//  OwnerForm           - ManagedForm - form to be locked while the permissions are being 
	//                        applied.
	//  ClosingNotification - NotifyDescription - to be called once the permissions are granted.
	//  StandardProcessing  - Boolean - flag that shows whether the standard external resource
	//                        permission applying processing (connecting the server agent through 
	//                        a COM connection or administration server with prompting the current 
	//                        user to enter the cluster connection parameters) is executed. Can be 
	//                        set to False in the handler body to cancel the standard processing.
	//
	// Syntax:
	//  Procedure ExternalResourceRequestsOnProcess(Val RequestIDs OwnerForm ClosingNotification StandardProcessing) Export
	//
	ClientEvents.Add(
		"StandardSubsystems.BaseFunctionality\ExternalResourceRequestsOnProcess");
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Using security profiles.
//

// Returns the namespace URI of the XDTOpackage used for permissions description
// in security profiles.
//
// Returns: Row, URI space namespace XDTOpackage.
//
Function PermissionPresentationXDTOPackage() Export
	
	Return Metadata.XDTOPackages.ApplicationPermissions_1_0_0_1.Namespace;
	
EndFunction

// Checks whether the security profiles can be used for the current infobase.
//
// Returns:
//  Boolean.
//
Function CanUseSecurityProfiles() Export
	
	If CommonUse.FileInfobase(InfobaseConnectionString()) Then
		Return False;
	EndIf;
	
	Cancel = False;
	
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.BaseFunctionality\CanUseSecurityProfilesOnCheck");
	For Each Handler In EventHandlers Do
		Handler.Module.CanUseSecurityProfilesOnCheck(Cancel);
		If Cancel Then
			Break;
		EndIf;
	EndDo;
	
	SafeModeOverride.CanUseSecurityProfilesOnCheck(Cancel);
	
	Return Not Cancel;
	
EndFunction

// Checks whether the security profiles can be set up for the current infobase.
//
// Returns:
//  Boolean.
//
Function CanSetUpSecurityProfiles() Export
	
	If CanUseSecurityProfiles() Then
		
		Cancel = False;
		
		EventHandlers = CommonUse.InternalEventHandlers(
			"StandardSubsystems.BaseFunctionality\CanSetupSecurityProfilesOnCheck");
		
		For Each Handler In EventHandlers Do
			Handler.Module.CanSetupSecurityProfilesOnCheck(Cancel);
			If Cancel Then
				Break;
			EndIf;
		EndDo;
		
		Return Not Cancel;
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction

// Performs additional (business logic defined) actions during the security profile enabling.
//
Procedure SecurityProfilesOnEnable() Export
	
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.BaseFunctionality\SecurityProfilesOnEnable");
	For Each Handler In EventHandlers Do
		Handler.Module.SecurityProfilesOnEnable();
	EndDo;
	
	SafeModeOverride.SecurityProfilesOnEnable();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Creating requests for permissions.
//

// Generates a request for changing permissions to use external resources.
// For internal use only.
//
// Parameters:
//  Owner               - AnyRef - external resource permission owner.
//                        Undefined if the request for permissions is generated for the 
//                        configuration but not for configuration objects.
//  ReplacementMode     - Boolean - replace previously granted permissions.
//  PermissionsToAdd    - Array of XDTODataObject - array of XDTODataObjects that corresponds
//                        to the internal descriptions of the permissions to use external
//                        resources.
//                        All XDTODataObjects passed in this parameter must be generated with
//                        SafeMode.*Permission() functions.
//  PermissionsToDelete - Array of XDTODataObject - array of XDTODataObjects that corresponds
//                        to the internal descriptions of the permissions to use  external
//                        resources.
//                        All XDTODataObjects passed in this parameter must be generated with
//                        SafeMode.*Permission() functions.
//  ExternalModule      - AnyRef - reference corresponding to the external module for which
//                        the permissions are requested. Undefined if the request for
//                        permissions is generated for the configuration but not for configuration objects.
//
// Returns:
//  UUID - ID of the generated request.
//
Function ExternalResourcesPermissionChangeRequest(Val Owner, Val ReplacementMode, Val PermissionsToAdd = Undefined, Val PermissionsToDelete = Undefined, Val ExternalModule = Undefined) Export
	
	StandardProcessing = True;
	Result = Undefined;
	
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.BaseFunctionality\PermissionsToUseExternalResourceOnRequest");
	For Each Handler In EventHandlers Do
		
		Handler.Module.PermissionsToUseExternalResourceOnRequest(
			Owner, ReplacementMode, PermissionsToAdd, PermissionsToDelete, StandardProcessing, Result);
		
		If Not StandardProcessing Then
			Break;
		EndIf;
		
	EndDo;
	
	If StandardProcessing Then
		
		Result = DataProcessors.ExternalResourcePermissionSetup.ExternalResourcesPermissionChangeRequest(
			Owner, ReplacementMode, PermissionsToAdd, PermissionsToDelete, ExternalModule);
		
	EndIf;
	
	Return Result;
	
EndFunction

// Generates external resource requests for the external module.
//
// Parameters:
//  ExternalModule - AnyRef - reference corresponding to the external module for which the
//                   permissions are requested.
//  NewPermissions - Array of XDTODataObject - array of XDTODataObjects that corresponds
//                   to the internal descriptions of the permissions to use external resources.
//                   All XDTODataObjects passed in this parameter must be generated with
//                   SafeMode.*Permission() functions.
//                   If the permissions are requested for external modules, they are always 
//                   added in the replacement mode.
//
// Returns 
//  Array of UUID - IDs of the generated requests.
//
Function ExternalResourceRequestsForExternalModule(Val ExternalModule, Val NewPermissions = Undefined) Export
	
	Result = New Array();
	
	If NewPermissions = Undefined Then
		NewPermissions = New Array();
	EndIf;
	
	If NewPermissions.Count() > 0 Then
		
		// If no security profile exists it must be created
		If ExternalModuleAttachingMode(ExternalModule) = Undefined Then
			Result.Add(PermissionSetCreatingRequest(ExternalModule));
		EndIf;
		
		Result.Add(
			ExternalResourcesPermissionChangeRequest(
				ExternalModule, True, NewPermissions, Undefined, ExternalModule
			)
		);
		
	Else
		
		// If the security profile exists it must be deleted
		If ExternalModuleAttachingMode(ExternalModule) <> Undefined Then
			Result.Add(PermissionSetDeletingRequest(ExternalModule));
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Generates the security profile creating request for the external module.
// For internal use only.
//
// Parameters:
//  ExternalModule - AnyRef - reference corresponding to the external module for which the
//                   permissions are requested. Undefined if the request for permissions is 
//                   generated for the configuration but not for configuration objects.
//
// Returns
//  UUID - ID of the generated request.
//
Function PermissionSetCreatingRequest(Val ExternalModule) Export
	
	StandardProcessing = True;
	Result = Undefined;
	Operation = Enums.OperationsWithPermissionSets.Create;
	
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.BaseFunctionality\ExternalResourcePermissionAdministrationOnRequest");
	For Each Handler In EventHandlers Do
		
		Handler.Module.ExternalResourcePermissionAdministrationOnRequest(
			ExternalModule, Operation, StandardProcessing, Result);
		
		If Not StandardProcessing Then
			Break;
		EndIf;
		
	EndDo;
	
	If StandardProcessing Then
		
		Result = DataProcessors.ExternalResourcePermissionSetup.ExternalResourcePermissionAdministrationRequest(
			ExternalModule, Operation);
		
	EndIf;
	
	Return Result;
	
EndFunction

// Generates the security profile deleting request for the external module.
// For internal use only.
//
// ExternalModule - AnyRef - reference corresponding to the external module for which the
//                  permissions are requested. Undefined if the request for permissions is 
//                  generated for the configuration but not for configuration objects.
//
// Returns
// UUID - ID of the request.
//
Function PermissionSetDeletingRequest(Val ExternalModule) Export
	
	StandardProcessing = True;
	Result = Undefined;
	Operation = Enums.OperationsWithPermissionSets.Delete;
	
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.BaseFunctionality\ExternalResourcePermissionAdministrationOnRequest");
	For Each Handler In EventHandlers Do
		
		Handler.Module.ExternalResourcePermissionAdministrationOnRequest(
			ExternalModule, Operation, StandardProcessing, Result);
		
		If Not StandardProcessing Then
			Break;
		EndIf;
		
	EndDo;
	
	If StandardProcessing Then
		
		Result = DataProcessors.ExternalResourcePermissionSetup.ExternalResourcePermissionAdministrationRequest(
			ExternalModule, Operation);
		
	EndIf;
	
	Return Result;
	
EndFunction

// Generate configuration permission updating requests.
//
// Parameters:
//  IncludingInfobaseProfileCreationRequest - Boolean - security profile creating request for
//                                            the current infobase must be included un the
//                                            result.
//
// Returns:
//  Array of UUID - IDs of requests for updating configuration permissions.
//
Function RequestsToUpdateConfigurationPermissions(Val IncludingInfobaseProfileCreationRequest = True) Export
	
	Result = New Array();
	
	BeginTransaction();
	
	Try
		
		If IncludingInfobaseProfileCreationRequest Then
			Result.Add(PermissionSetCreatingRequest(Catalogs.MetadataObjectIDs.EmptyRef()));
		EndIf;
		
		EventHandlers = CommonUse.InternalEventHandlers(
			"StandardSubsystems.BaseFunctionality\OnFillPermissionsToAccessExternalResources");
		For Each Handler In EventHandlers Do
			Handler.Module.OnFillPermissionsToAccessExternalResources(Result);
		EndDo;
		
		SafeModeOverride.OnFillPermissionsToAccessExternalResources(Result);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Applying requests for permissions to use external resources.
//

// Generates the presentation of permissions to use external resources by permission tables.
//
// Parameters:
//  Tables - Structure - table of permissions whose presentations are generated
//           (see PermissionTables()).
//
// Returns:
//  SpreadsheetDocument - presentation of permissions to use external resources.
//
Function ExternalResourcePermissionPresentation(Val PermissionTables) Export
	
	Return Reports.ExternalResourcesInUse.ExternalResourcePermissionPresentation(PermissionTables);
	
EndFunction

// Applies the external resource requests. The procedure must be called after security profile
// settings are changed in the server cluster.
//
// Parameters:
//  RequestIDs - Array of UUID - IDs of the requests to be applied.
//
Procedure ApplyRequests(Val RequestIDs) Export
	
	BeginTransaction();
	
	Try
		
		StandardProcessing = True;
		
		EventHandlers = CommonUse.InternalEventHandlers(
			"StandardSubsystems.BaseFunctionality\ExternalResourceRequestsOnApply");
		For Each Handler In EventHandlers Do
			
			Handler.Module.ExternalResourceRequestsOnApply(RequestIDs, StandardProcessing);
			
			If Not StandardProcessing Then
				Break;
			EndIf;
			
		EndDo;
		
		If StandardProcessing Then
			
			DataProcessors.ExternalResourcePermissionSetup.ApplyRequests(RequestIDs);
			
		EndIf;
		
		RequestsAfterProcess(RequestIDs);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

// Performs additional actions once the external resource requests are applied.
//
// Parameters:
//  RequestIDs - Array of UUID - IDs of the requests to be applied.
//
Procedure RequestsAfterProcess(Val RequestIDs) Export
	
	StandardProcessing = True;
	
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.BaseFunctionality\ExternalResourceRequestsAfterProcess");
	For Each Handler In EventHandlers Do
		
		Handler.Module.ExternalResourceRequestsAfterProcess(RequestIDs, False, StandardProcessing);
		
		If Not StandardProcessing Then
			Break;
		EndIf;
		
	EndDo;
	
	If StandardProcessing Then
		
		DataProcessors.ExternalResourcePermissionSetup.RequestsAfterProcess(RequestIDs);
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// External modules
//

// Returns the external module attaching mode.
//
// Parameters:
//  ExternalModule - AnyRef - reference corresponding to the external module for which the
//                   attaching mode are retrieved.
//
// Returns:
//  String    - name of the security profile to be used for attaching the external module.
//  Undefined - if the external module attaching mode is not registered.
//
Function ExternalModuleAttachingMode(Val ExternalModule) Export
	
	Return DataProcessors.ExternalResourcePermissionSetup.ExternalModuleAttachingMode(ExternalModule);
	
EndFunction

// Returns the module that is the external module manager.
//
//  ExternalModule - AnyRef - reference corresponding to the external module for which the
//                   manager is retrieved.
//
// Returns:
//  CommonModule.
//
Function ExternalModuleManager(Val ExternalModule) Export
	
	Containers = New Array();
	
	Managers = ExternalModuleManagers();
	For Each Manager In Managers Do
		ManagerContainers = Manager.ExternalModuleContainers();
		
		If TypeOf(ExternalModule) = Type("CatalogRef.MetadataObjectIDs") Then
			MetadataObject = CommonUse.MetadataObjectByID(ExternalModule);
		Else
			MetadataObject = ExternalModule.Metadata();
		EndIf;
		
		If ManagerContainers.Find(MetadataObject) <> Undefined Then
			Return Manager;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Controlling internal data recording.
//

// Is called during catalog item recording, is used as an external module container.
//
// Parameters:
//  Source - CatalogObject - catalog item to be recorded.
//  Cancel - Boolean - flag that shows whether the recording is canceled.
//
Procedure ExternalModuleContainerOnWrite(Source, Cancel) Export
	
	InternalDataOnWrite(Source);
	
EndProcedure

// Must be called during recording of all internal data that cannot be changed in the safe mode.
//
Procedure InternalDataOnWrite(Object) Export
	
	If SafeMode.SafeModeSet() Then
		
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'The %1 object cannot be written: safe mode is set: %2!'"),
			Object.Metadata().FullName(),
			SafeMode()
		);
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Declaring event handlers.
//

// See description in the StandardSubsystemsServer module.
//
Procedure InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers) Export
	
	// SERVER HANDLERS
	
	ServerHandlers["StandardSubsystems.InfobaseVersionUpdate\OnAddUpdateHandlers"].Add(
	"SafeModeInternal");
	
	If CommonUse.SubsystemExists("StandardSubsystems.ReportOptions") Then
		ServerHandlers["StandardSubsystems.ReportOptions\ReportOptionsOnSetup"].Add(
			"SafeModeInternal");
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Internal event handlers.
//

// Adds update handlers that the current subsystem requires.
//
// Parameters:
//  Handlers - ValueTable - see InfobaseUpdate.NewUpdateHandlerTable().
//
Procedure OnAddUpdateHandlers(Handlers) Export
	
	//PARTIALLY_DELETED <BR> //DataProcessors.ExternalResourcePermissionSetup.OnAddUpdateHandlers(<BR>  //Handlers);

	
EndProcedure

// Retrieves report option placement settings in the report panel.
//
// Parameters:
//   Settings - Collection - is used to set report settings and options. See
//              ReportOptions.ConfigurationReportOptionSettingsTree() for details.
//
// Details:
//   See ReportOptionsOverridable.SetUpReportOptions().
//
Procedure ReportOptionsOnSetup(Settings) Export
	ReportOptionsModule = CommonUse.CommonModule("ReportOptions");
	ReportOptionsModule.SetupReportInManagerModule(Settings, Metadata.Reports.ExternalResourcesInUse);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Conditional call handlers. 
//

Procedure AddClientParametersOnStart(Parameters) Export
	
	AddClientParameters(Parameters);
	
EndProcedure

Procedure AddClientParameters(Parameters) Export
	
	SetPrivilegedMode(True);
	Parameters.Insert("ShowPermissionSetupAssistant", InteractivePermissionRequestModeUsed());
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

////////////////////////////////////////////////////////////////////////////////
// Using security profiles.
//

// Checks whether the interactive permission request mode is required.
//
// Returns:
//  Boolean.
//
Function InteractivePermissionRequestModeUsed()
	
	If CanUseSecurityProfiles() Then
		
		Return GetFunctionalOption("UseSecurityProfiles") And Constants.AutomaticallySetUpPermissionsInSecurityProfiles.Get();
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// External modules.
//

// Returns an array of the catalog managers that are external module containers.
//
// Returns:
//  Array of CatalogManager.
//
Function ExternalModuleManagers()
	
	Managers = New Array();
	
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.BaseFunctionality\ExternalModuleManagersOnRegistration");
	For Each Handler In EventHandlers Do
		Handler.Module.ExternalModuleManagersOnRegistration(Managers);
	EndDo;
	
	Return Managers;
	
EndFunction

#EndRegion
