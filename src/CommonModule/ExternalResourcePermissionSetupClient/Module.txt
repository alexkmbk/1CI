////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
// Common client procedures and functions for working with:
// - Security profiles.
//
////////////////////////////////////////////////////////////////////////////////

#Region InternalInterface

////////////////////////////////////////////////////////////////////////////////
// Applying requests for permissions to use external resources.
//

// Applies the security profile permission changes in server cluster by the scenario.
//
// Parameters:
//  OperationKinds                   - Structure - describes the values of the
//                                     OperationsWithPermissionSets enumeration where:
//                                     * Key   - String - enumeration value name,
//                                     * Value - EnumRef.OperationsWithPermissionSets.
//  PermissionApplyingScenario       - Array of Structure - security profile permission change
//                                     applying scenario in the server cluster. Array values are
//                                     structures with the following fields:
//                                     * Operation   - EnumRef.OperationsWithPermissionSets - 
//                                                     operation to be executed,
//                                     * Profile     - String - security profile name,
//                                     * Permissions - Structure - security profile property
//                                                     description, see 
//                                                     ClusterAdministrationClientServer.SecurityProfileProperties(),
//  ClusterAdministrationParameters  - Structure - server cluster administration parameters, see
//                                     ClusterAdministrationClientServer.ClusterAdministrationParameters(),
//  InfobaseAdministrationParameters - Structure - infobase administration parameters, see
//                                     ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters().
//
Procedure ApplyPermissionChangesInSecurityProfilesInServerCluster(Val OperationKinds, Val PermissionApplyingScenario, Val ClusterAdministrationParameters, Val InfobaseAdministrationParameters = Undefined) Export
	
	If ClusterAdministrationParameters.ConnectionType = "COM" Then
		CommonUseClient.RegisterCOMConnector(False);
	EndIf;
	
	InfobaseAdministrationParametersRequired = (InfobaseAdministrationParameters <> Undefined);
	
	ClusterAdministrationClientServer.CheckAdministrationParameters(
		ClusterAdministrationParameters,
		InfobaseAdministrationParameters,
		True,
		InfobaseAdministrationParametersRequired);
	
	For Each ScenarioItem In PermissionApplyingScenario Do
		
		If ScenarioItem.Operation = OperationKinds.Creating Then
			ClusterAdministrationClientServer.CreateSecurityProfile(ClusterAdministrationParameters, ScenarioItem.Permissions);
		ElsIf ScenarioItem.Operation = OperationKinds.Purpose Then
			ClusterAdministrationClientServer.SetInfobaseSecurityProfile(ClusterAdministrationParameters, InfobaseAdministrationParameters, ScenarioItem.Profile);
		ElsIf ScenarioItem.Operation = OperationKinds.RefreshEnabled Then
			ClusterAdministrationClientServer.SetSecurityProfileProperties(ClusterAdministrationParameters, ScenarioItem.Permissions);
		ElsIf ScenarioItem.Operation = OperationKinds.Delete Then
			If ClusterAdministrationClientServer.SecurityProfileExists(ClusterAdministrationParameters, ScenarioItem.Profile) Then
				ClusterAdministrationClientServer.DeleteSecurityProfile(ClusterAdministrationParameters, ScenarioItem.Profile);
			EndIf;
		ElsIf ScenarioItem.Operation = OperationKinds.Deny Then
			ClusterAdministrationClientServer.SetInfobaseSecurityProfile(ClusterAdministrationParameters, InfobaseAdministrationParameters, "");
		EndIf;
		
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Switching between the external resource permission setup wizard operations. 
//

// Starts external resource permission setup wizard.
//
// Parameters:
//  IDs                 - Array of UUID - IDs of external resource requests, for which the  
//                        wizard is called.
//  OwnerForm           - ManagedForm or Undefined - parent whence the wizard is opened in 
//                        pseudomodal mode.
//  ClosureNotification - NotifyDescription or Undefined - notification description to be
//                        processed in case of wizard abnormal termination.
//  EnablingMode        - Boolean - flag that shows whether the wizard is called when security
//                        profiles are being enabled for the infobase.
//  DisablingMode       - Boolean - flag that shows whether the wizard is called when security 
//                        security profiles are being disabled for the infobase.
//  RecoveryMode        - Boolean - flag that shows whether the wizard is called for recovering
//                        security profile settings in the server cluster (based on the current 
//                        infobase data).
//  CheckMode           - Boolean - flag that shows whether the wizard is called to check if the
//                        operation whence requests for permissions to use external resources  
//                        were applied is finished.
//
// As a result of the procedure the
// DataProcessor.ExternalResourcePermissionSetup.Form.PermissionRequiestInitialization form is
// opened with the RequestForPermissionsToUseExternalResourcesAfterInitialize() procedure set as 
// a closure notification description. 
//
Procedure StartInitializingRequestForPermissionToUseExternalResources(
		Val IDs,
		OwnerForm,
		ClosureNotification,
		EnablingMode = False,
		DisablingMode = False,
		RecoveryMode = False,
		CheckMode = False) Export
	
	If EnablingMode Or ShowPermissionSetupAssistant() Then
		
		If OwnerForm <> Undefined Then
			StorageAddress = PutToTempStorage(Undefined, OwnerForm.UUID);
		Else
			StorageAddress = PutToTempStorage(Undefined);
		EndIf;
		
		Status = ExternalResourcePermissionRequestState();
		Status.StorageAddress = StorageAddress;
		Status.RequestIDs = IDs;
		Status.NotifyDescription = ClosureNotification;
		Status.OwnerForm = OwnerForm;
		Status.EnablingMode = EnablingMode;
		Status.DisablingMode = DisablingMode;
		Status.RecoveryMode = RecoveryMode;
		Status.CheckMode = CheckMode;
		
		FormParameters = New Structure();
		FormParameters.Insert("StorageAddress", StorageAddress);
		FormParameters.Insert("IDs", IDs);
		FormParameters.Insert("EnablingMode", Status.EnablingMode);
		FormParameters.Insert("DisablingMode", Status.DisablingMode);
		FormParameters.Insert("RecoveryMode", Status.RecoveryMode);
		FormParameters.Insert("CheckMode", Status.CheckMode);
		
		NotifyDescription = New NotifyDescription(
			"RequestForPermissionsToUseExternalResourcesAfterInitialize",
			ExternalResourcePermissionSetupClient,
			Status);
		
		OpenForm(
			"DataProcessor.ExternalResourcePermissionSetup.Form.PermissionRequiestInitialization",
			FormParameters,
			OwnerForm,
			,
			,
			,
			NotifyDescription,
			FormWindowOpeningMode.LockOwnerWindow
		);
		
	Else
		
		FinishExternalResourcePermissionSetupAsynchronously(ClosureNotification);
		
	EndIf;
	
EndProcedure

// Starts the security profile permission setup dialog.
//
// Parameters:
//  Result - DialogReturnCode - result of the previous operation of the external resource
//           permission applying wizard. Can be OK or Cancel.
//  Status - Structure - describes the state of the permission setup wizard (see
//           ExternalResourcePermissionRequestState()).
//
// As a result of the procedure the
// DataProcessor.ExternalResourcePermissionSetup.Form.ExternalResourcePermissionSetup form is
// opened with the ExternalResourcePermissionsAfterSetup() procedure set as a
// closure notification description. Abnormal wizard termination can be a result too.
//
Procedure RequestForPermissionsToUseExternalResourcesAfterInitialize(Result, Status) Export
	
	If Result = DialogReturnCode.OK Then
		
		FormParameters = New Structure();
		FormParameters.Insert("StorageAddress", Status.StorageAddress);
		FormParameters.Insert("RecoveryMode", Status.RecoveryMode);
		FormParameters.Insert("CheckMode", Status.CheckMode);
		
		NotifyDescription = New NotifyDescription(
			"ExternalResourcePermissionsAfterSetup",
			ExternalResourcePermissionSetupClient,
			Status);
		
		OpenForm(
			"DataProcessor.ExternalResourcePermissionSetup.Form.ExternalResourcePermissionSetup",
			FormParameters,
			Status.OwnerForm,
			,
			,
			,
			NotifyDescription,
			FormWindowOpeningMode.LockOwnerWindow
		);
		
	Else
		
		CancelExternalResourcePermissionSetupAsynchronously(Status.NotifyDescription);
		
	EndIf;
	
EndProcedure

// Starts the security profile settings applying waiting dialog.
//
// Parameters:
//  Result - DialogReturnCode - the result of the previous operation of the external resource
//           permission applying wizard. Can be OK, Cancel, or Ignore. Ignore is used if
//           security profiles have no changes but requests must be deemed as applied (for
//           example if all permissions for external resource  are already granted).
//  Status - Structure - describes the state of the permission setup wizard (see
//           ExternalResourcePermissionRequestState()).
//
// As a result of the procedure the
// DataProcessor.ExternalResourcePermissionSetup.Form.PermissionRequestEnd form is
// opened with the RequestForPermissionsToUseExternalResourceOnComplete() procedure set as a
// closure notification description. 
//
Procedure ExternalResourcePermissionsAfterSetup(Result, Status) Export
	
	If Result = DialogReturnCode.OK Or Result = DialogReturnCode.Ignore Then
		
		PlanPermissionApplyingCheckAfterOwnerFormClose(
			Status.OwnerForm,
			Status.RequestIDs);
		
		FormParameters = New Structure();
		FormParameters.Insert("StorageAddress", Status.StorageAddress);
		FormParameters.Insert("RecoveryMode", Status.RecoveryMode);
		
		If Result = DialogReturnCode.OK Then
			FormParameters.Insert("Duration", ChangeApplyingTimeout());
		Else
			FormParameters.Insert("Duration", 0);
		EndIf;
		
		NotifyDescription = New NotifyDescription(
			"RequestForPermissionsToUseExternalResourceOnComplete",
			ExternalResourcePermissionSetupClient,
			Status);
		
		OpenForm(
			"DataProcessor.ExternalResourcePermissionSetup.Form.PermissionRequestEnd",
			FormParameters,
			ThisObject,
			,
			,
			,
			NotifyDescription,
			FormWindowOpeningMode.LockOwnerWindow
		);
		
	Else
		
		CancelExternalResourcePermissionSetupAsynchronously(Status.NotifyDescription);
		
	EndIf;
	
EndProcedure

// Processes the data entered to the external resource permission applying wizard.
//
// Parameters:
//  Result - DialogReturnCode - the result of the previous operation of the external resource
//           permission applying wizard. Can be OK or Cancel.
//  Status - Structure - describes the state of the permission setup wizard (see
//           ExternalResourcePermissionRequestState()).
//
// The result of the procedure is processing of the notification description that was initially
// passed from the form whence the wizard is opened in pseudomodal mode.
//
Procedure RequestForPermissionsToUseExternalResourceOnComplete(Result, Status) Export
	
	If Result = DialogReturnCode.OK Then
		
		ShowUserNotification(NStr("en = 'Permission setup'"),,
			NStr("en = 'Security profile settings are changed in the server cluster.'"));
		
		FinishExternalResourcePermissionSetupAsynchronously(Status.NotifyDescription);
		
	Else
		
		CancelExternalResourcePermissionSetupAsynchronously(Status.NotifyDescription);
		
	EndIf;
	
EndProcedure

// Asynchronously (relative to the script whence the wizard is called) processes the
// notification description that was initially passed from the form whence the wizard is opened 
// in pseudomodal mode, if the return code is OK.
//
// Parameters:
//  NotifyDescription - NotifyDescription.
//
Procedure FinishExternalResourcePermissionSetupAsynchronously(Val NotifyDescription)
	
	NotificationOnExternalResourceRequestApply = NotifyDescription;
	AttachIdleHandler("FinishExternalResourcePermissionSetup", 0.1, True);
	
EndProcedure

// Asynchronously (relative to the script whence the wizard is called) processes the
// notification description that was initially passed from the form whence the wizard is opened 
// in pseudomodal mode, if the return code is Cancel.
//
// Parameters:
//  NotifyDescription - NotifyDescription.
//
Procedure CancelExternalResourcePermissionSetupAsynchronously(Val NotifyDescription)
	
	NotificationOnExternalResourceRequestApply = NotifyDescription;
	AttachIdleHandler("CancelExternalResourcePermissionSetup", 0.1, True);
	
EndProcedure

// Synchronously (relative to the script whence the wizard is called) processes the
// notification description that was initially passed from the form whence the wizard is opened 
// in pseudomodal mode.
//
// Parameters:
//  ReturnCode - DialogReturnCode.
//
Procedure SynchronouslyFinishExternalResourcePermissionSetup(Val ReturnCode) Export
	
	ClosureNotification = NotificationOnExternalResourceRequestApply;
	NotificationOnExternalResourceRequestApply = Undefined;
	If ClosureNotification <> Undefined Then
		ExecuteNotifyProcessing(ClosureNotification, ReturnCode);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// External resource permission setup wizard call logic for checking whether the operations
// whence requests was applied are completed.
//

// Plans (substituting the values of the NotifyOnCloseDescription form properties) the wizard 
// call for checking whether the operations are completed once the form that called the wizard 
// is closed.
//
// Parameters:
//  OwnerForm  - ManagedForm or Undefined - the procedure executes checks once this form is 
//               closed.
//  RequestIDs - Array of UUID - IDs of the requests for permissions to use external resources   
//               that were applied in the operation to be checked.
//
// The result of the procedure is a call of the PermissionApplyingCheckAfterOwnerFormClose()
// procedure once the form whence the wizard is opened in pseudomodal mode is closed.
//
Procedure PlanPermissionApplyingCheckAfterOwnerFormClose(FormOwner, RequestIDs) Export
	
	If TypeOf(FormOwner) = Type("ManagedForm") Then
		
		InitialNotifyDescription = FormOwner.NotifyOnCloseDescription;
		If InitialNotifyDescription <> Undefined Then
			
			If InitialNotifyDescription.Module = ExternalResourcePermissionSetupClient
					And InitialNotifyDescription.ProcedureName = "PermissionApplyingCheckAfterOwnerFormClose" Then
				Return;
			EndIf;
			
		EndIf;
		
		Status = PermissionApplyCheckStateAfterOwnerFormClose();
		Status.RequestIDs = RequestIDs;
		Status.NotifyDescription = InitialNotifyDescription;
		
		PermissionApplyingCheckNotifyDescription = New NotifyDescription(
			"PermissionApplyingCheckAfterOwnerFormClose",
			ExternalResourcePermissionSetupClient,
			Status);
		
		FormOwner.NotifyOnCloseDescription = PermissionApplyingCheckNotifyDescription;
		
	EndIf;
	
EndProcedure

// Starts the wizard in operation completion check mode. In this mode the wizard checks whether
// the operation whence requests for permissions to use external resources were applied.
//
// Parameters:
//  Result - Arbitrary - external resource permission setup wizard form closure result. Does
//           not used in the procedure body, the parameter is required for defining a form 
//           closure notification description procedure.
//  Status - describes the operation completion check state (see
//           PermissionApplyCheckStateAfterOwnerFormClose()).
//
// The result of the procedure is a startup of the external resource permission setup wizard in
// operation completion check mode. Once the wizard is closed, the
// PermissionApplyingAfterCheckAfterOwnerFormClose() procedure is used for processing the
// notification description. 
// 
Procedure PermissionApplyingCheckAfterOwnerFormClose(Result, Status) Export
	
	ClosureNotification = New NotifyDescription(
		"PermissionApplyingAfterCheckAfterOwnerFormClose",
		ExternalResourcePermissionSetupClient,
		Status);
	
	StartInitializingRequestForPermissionToUseExternalResources(
		Status.RequestIDs,
		,
		ClosureNotification,
		,
		,
		,
		True);
	
EndProcedure

// Processes original notification description of closure of the owner form instead of which the
// external resource permission setup wizard is started in operation completion check mode.
//
// Parameters:
//  Result - Arbitrary - external resource permission setup wizard forms closure result. Does
//           not used in the procedure body, the parameter is required for defining a form 
//           closure notification description procedure.
//  Status - Structure - describes the operation completion check state (see
//           PermissionApplyCheckStateAfterOwnerFormClose()).
//
// The result of the procedure is a completion of check of the operation, in which external 
// resource permissions were applied previously.
//
Procedure PermissionApplyingAfterCheckAfterOwnerFormClose(Result, Status) Export
	
	OriginalOnCloseNotifyDescription = Status.NotifyDescription;
	If OriginalOnCloseNotifyDescription <> Undefined Then
		ExecuteNotifyProcessing(OriginalOnCloseNotifyDescription, Result);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Calling the external resource permission setup wizard in special modes.
//

// Calls the external resource permission setup wizard in infobase security profile enabling
// mode.
//
// Parameters:
//  OwnerForm           - ManagedForm - form to be locked while the permissions are being
//                        applied.
//  ClosureNotification - NotifyDescription - to be called once the permissions are granted.
//
Procedure StartEnablingSecurityProfileUsage(OwnerForm, ClosureNotification = Undefined) Export
	
	StartInitializingRequestForPermissionToUseExternalResources(
		New Array(), OwnerForm, ClosureNotification, True, False, False);
	
EndProcedure

// Calls the external resource permission setup wizard in infobase security profile disabling 
// mode.
//
// Parameters:
//  OwnerForm           - ManagedForm - form to be locked while the permissions are being
//                        applied.
//  ClosureNotification - NotifyDescription - to be called once the permissions are granted.
//
Procedure StartDisablingSecurityProfileUsage(OwnerForm, ClosureNotification = Undefined) Export
	
	StartInitializingRequestForPermissionToUseExternalResources(
		New Array(), OwnerForm, ClosureNotification, False, True, False);
	
EndProcedure

// Calls the external resource permission setup wizard in server cluster security profile
// settings recovery mode based on the current infobase data.

//
// Parameters:
//  OwnerForm           - ManagedForm - form to be locked while the permissions are being
//                        applied.
//  ClosureNotification - NotifyDescription - to be called once the permissions are granted.
//
Procedure StartRestoringSecurityProfiles(OwnerForm, ClosureNotification = Undefined) Export
	
	StartInitializingRequestForPermissionToUseExternalResources(
		New Array(), OwnerForm, ClosureNotification, False, False, True);
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

// Checks whether the external (relative to the 1C:Enterprise server cluster) resource 
// permission setup assistant must be shown.
//
// Returns: 
//  Boolean.
//
Function ShowPermissionSetupAssistant()
	
	Return StandardSubsystemsClientCached.ClientParameters().ShowPermissionSetupAssistant;
	
EndFunction

// Creates a structure used for storing the external resource permission setup wizard state.
//
// Returns:
//  Structure - field descriptions. See the structure details in the function body.
//
Function ExternalResourcePermissionRequestState()
	
	Result = New Structure();
	
	// External resource request IDs to be granted - Array of UUID
	Result.Insert("RequestIDs", New Array());
	
	// Original notification description to be called once the request for permissions is applied
	Result.Insert("NotifyDescription", Undefined);
	
	// Address in a temporary storage for storing data passed between forms
	Result.Insert("StorageAddress", "");
	
	// Form whence the initial external resource request applying was called
	Result.Insert("OwnerForm");
	
	// Enabling mode. Flag that shows whether security profiles are being enabled.
	Result.Insert("EnablingMode", False);
	
	// Disabling mode. Flag that shows whether security profiles are being disabled.
	Result.Insert("DisablingMode", False);
	
	// Recovery mode. Flag that shows whether security profile permissions are being recovered 
	// (the request for permissions is executed from scratch, ignoring the previously granted
	//  permissions).
	Result.Insert("RecoveryMode", False);
	
	// Check mode. Flag that shows whether the operation that granted new permissions finished 
	// (for example, security profile permissions could be granted but the catalog item recording
	// was canceled).
	Result.Insert("CheckMode", False);
	
	Return Result;
	
EndFunction

// Creates a structure used for storing a state of check for completion of the operation where
// the requests for permissions to use external resources were applied.
//
// Returns:
//  Structure - field descriptions. See the structure details in the function body.
//
Function PermissionApplyCheckStateAfterOwnerFormClose()
	
	Result = New Structure();
	
	// IDs of external resource requests, during applying of which the server cluster security
	// profile permissions were granted (and for which the check for completion of the operation
	// where the requests for permissions to use external resources were applied is executed)
	// - Array of UUID.
	Result.Insert("RequestIDs", New Array());
	
	// Original notification description to be called once the permissions are applied
	Result.Insert("NotifyDescription", Undefined);
	
	Return Result;
	
EndFunction

// Returns the duration of waiting for server cluster security profile settings change applying.
//
// Returns - Number - duration of waiting for change applying (in seconds).
//
Function ChangeApplyingTimeout()
	
	Return 20; // rphost updates current security profile settings from rmngr once per 20 seconds
	
EndFunction

#EndRegion