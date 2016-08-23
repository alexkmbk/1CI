&AtClient
Var CheckIteration;
&AtClient
Var StorageAddress;

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
// Skipping the initialization to guarantee that the form will be received if the SelfTest parameter is passed.
	If Parameters.Property("SelfTest") Then 
		Return;
	EndIf;
	
	RequestProcessingResultStorage = Parameters.StorageAddress;
	RequestProcessingResult = GetFromTempStorage(RequestProcessingResultStorage);
	StorageAddressAtServer = PutToTempStorage(RequestProcessingResult, ThisObject.UUID);
	
	If GetFunctionalOption("UseSecurityProfiles") And Constants.AutomaticallySetUpPermissionsInSecurityProfiles.Get() Then
		If Parameters.CheckMode Then
			Items.PagesHeader.CurrentPage = Items.ObsoletePermissionCancellationRequiredInClusterHeaderPage;
		ElsIf Parameters.RecoveryMode Then
			Items.PagesHeader.CurrentPage = Items.SettingsInClusterToSetOnRecoveryHeaderPage;
		Else
			Items.PagesHeader.CurrentPage = Items.ChangesInClusterRequiredHeaderPage;
		EndIf;
	Else
		Items.PagesHeader.CurrentPage = Items.SettingsInClusterToSetOnEnableHeaderPage;
	EndIf;
	
	RequestApplyingScenario = RequestProcessingResult.Scenario;
	
	If RequestApplyingScenario.Count() = 0 Then
		ChangesInSecurityProfilesRequired = False;
		Return;
	EndIf;
	
	PermissionPresentations = RequestProcessingResult.Presentation;
	
	ChangesInSecurityProfilesRequired = True;
	InfobaseAdministrationParametersRequired = False;
	For Each ScenarioStep In RequestApplyingScenario Do
		If ScenarioStep.Operation = Enums.OperationsWithPermissionSets.Grant
				Or ScenarioStep.Operation = Enums.OperationsWithPermissionSets.Deny Then
			InfobaseAdministrationParametersRequired = True;
			Break;
		EndIf;
	EndDo;
	
	AdministrationParameters = StandardSubsystemsServer.AdministrationParameters();
	
	If CommonUseCached.CanUseSeparatedData() Then
		
		IBUser = InfobaseUsers.FindByName(AdministrationParameters.InfobaseAdministratorName);
		If IBUser <> Undefined Then
			InfobaseAdministratorID = IBUser.UUID;
		EndIf;
		
	EndIf;
	
	ConnectionType = AdministrationParameters.ConnectionType;
	ServerClusterPort = AdministrationParameters.ClusterPort;
	
	ServerAgentAddress = AdministrationParameters.ServerAgentAddress;
	ServerAgentPort = AdministrationParameters.ServerAgentPort;
	
	AdministrationServerAddress = AdministrationParameters.AdministrationServerAddress;
	AdministrationServerPort = AdministrationParameters.AdministrationServerPort;
	
	NameInCluster = AdministrationParameters.NameInCluster;
	ClusterAdministratorName = AdministrationParameters.ClusterAdministratorName;
	
	IBUser = InfobaseUsers.FindByName(AdministrationParameters.InfobaseAdministratorName);
	If IBUser <> Undefined Then
		InfobaseAdministratorID = IBUser.UUID;
	EndIf;
	
	Users.FindAmbiguousInfobaseUsers(, InfobaseAdministratorID);
	InfobaseAdministrator = Catalogs.Users.FindByAttribute("InfobaseUserID", InfobaseAdministratorID);
	
	Items.AdministrationGroup.Visible = InfobaseAdministrationParametersRequired;
	Items.RestartRequiredWarningGroup.Visible = InfobaseAdministrationParametersRequired;
	
	Items.FormAllow.Title = NStr("en = 'Next >'");
	Items.FormBack.Visible = False;
	
	VisibleManagement();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	#If WebClient Then
		ShowErrorOperationNotSupportedInWebClient();
		Return;
	#EndIf
	
	If ChangesInSecurityProfilesRequired Then
		
		StorageAddress = StorageAddressAtServer;
		
	Else
		
		Close(DialogReturnCode.Ignore);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, AttributesToCheck)
	
	If InfobaseAdministrationParametersRequired Then
		
		If Not ValueIsFilled(InfobaseAdministrator) Then
			Return;
		EndIf;
		
		FieldName = "InfobaseAdministrator";
		IBUser = GetInfobaseAdministrator();
		If IBUser = Undefined Then
			CommonUseClientServer.MessageToUser(NStr("en = 'The specified user does not have access to the infobase.'"),,
				FieldName,,Cancel);
			Return;
		EndIf;
		
		If Not Users.InfobaseUserWithFullAccess(IBUser, True) Then
			CommonUseClientServer.MessageToUser(NStr("en = 'The current user does not have administrative rights.'"),,
				FieldName,,Cancel);
			Return;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemEventHandlers

&AtClient
Procedure ConnectionTypeOnChange(Item)
	
	VisibleManagement();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Next(Command)
	
	If Items.GroupPages.CurrentPage = Items.PermissionsPage Then
		
		ErrorText = "";
		Items.ErrorGroup.Visible = False;
		Items.FormAllow.Title = NStr("en = 'Set up permissions in server cluster'");
		Items.GroupPages.CurrentPage = Items.ConnectionPage;
		Items.FormBack.Visible = True;
		
	ElsIf Items.GroupPages.CurrentPage = Items.ConnectionPage Then
		
		ErrorText = "";
		Try
			
			ApplyPermissions();
			FinishRequestApplying(StorageAddress);
			WaitForSettingsApplyingInCluster();
			
		Except
			ErrorText = BriefErrorDescription(ErrorInfo()); 
			Items.ErrorGroup.Visible = True;
		EndTry;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	If Items.GroupPages.CurrentPage = Items.ConnectionPage Then
		Items.GroupPages.CurrentPage = Items.PermissionsPage;
		Items.FormBack.Visible = False;
		Items.FormAllow.Title = NStr("en = 'Next >'");
	EndIf;
	
EndProcedure

&AtClient
Procedure ReregisterCOMConnector(Command)
	
	CommonUseClient.RegisterCOMConnector();
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure VisibleManagement()
	
	If ConnectionType = "COM" Then
		Items.ClusterConnectionParametersByProtocolsPages.CurrentPage = Items.COMClusterConnectionParametersPage;
		COMConnectorVersionErrorGroupVisible = True;
	Else
		Items.ClusterConnectionParametersByProtocolsPages.CurrentPage = Items.RASClusterConnectionParametersPage;
		COMConnectorVersionErrorGroupVisible = False;
	EndIf;
	
	Items.COMConnectorVersionErrorGroup.Visible = COMConnectorVersionErrorGroupVisible;
	
EndProcedure

&AtServer
Procedure ShowErrorOperationNotSupportedInWebClient()
	
	Items.PagesGlobal.CurrentPage = Items.ActionNotSupportedInWebClientPage;
	
EndProcedure

&AtServer
Function GetInfobaseAdministrator()
	
	If Not ValueIsFilled(InfobaseAdministrator) Then
		Return Undefined;
	EndIf;
	
	Return InfobaseUsers.FindByUUID(
		InfobaseAdministrator.InfobaseUserID);
	
EndFunction

&AtServerNoContext
Function InfobaseUserName(Val User)
	
	If ValueIsFilled(User) Then
		
		InfobaseUserID = CommonUse.ObjectAttributeValue(User, "InfobaseUserID");
		IBUser = InfobaseUsers.FindByUUID(InfobaseUserID);
		Return IBUser.Name;
		
	Else
		
		Return "";
		
	EndIf;
	
EndFunction

&AtClient
Procedure ApplyPermissions()
	
	ApplyingParameters = StartApplyingRequests(StorageAddress);
	
	OperationKinds = ApplyingParameters.OperationKinds;
	Scenario = ApplyingParameters.RequestApplyingScenario;
	InfobaseAdministrationParametersRequired = ApplyingParameters.InfobaseAdministrationParametersRequired;
	
	ClusterAdministrationParameters = ClusterAdministrationClientServer.ClusterAdministrationParameters();
	ClusterAdministrationParameters.ConnectionType = ConnectionType;
	ClusterAdministrationParameters.ServerAgentAddress = ServerAgentAddress;
	ClusterAdministrationParameters.ServerAgentPort = ServerAgentPort;
	ClusterAdministrationParameters.AdministrationServerAddress = AdministrationServerAddress;
	ClusterAdministrationParameters.AdministrationServerPort = AdministrationServerPort;
	ClusterAdministrationParameters.ClusterPort = ServerClusterPort;
	ClusterAdministrationParameters.ClusterAdministratorName = ClusterAdministratorName;
	ClusterAdministrationParameters.ClusterAdministratorPassword = ClusterAdministratorPassword;
	
	If InfobaseAdministrationParametersRequired Then
		InfobaseAdministrationParameters = ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters();
		InfobaseAdministrationParameters.NameInCluster = NameInCluster;
		InfobaseAdministrationParameters.InfobaseAdministratorName = InfobaseUserName(InfobaseAdministrator);
		InfobaseAdministrationParameters.InfobaseAdministratorPassword = InfobaseAdministratorPassword;
	Else
		InfobaseAdministrationParameters = Undefined;
	EndIf;
	
	ExternalResourcePermissionSetupClient.ApplyPermissionChangesInSecurityProfilesInServerCluster(
		OperationKinds, Scenario, ClusterAdministrationParameters, InfobaseAdministrationParameters);
	
EndProcedure

&AtServer
Function StartApplyingRequests(Val StorageAddress)
	
	Result = GetFromTempStorage(StorageAddress);
	RequestApplyingScenario = Result.Scenario;
	
	OperationKinds = New Structure();
	For Each EnumValue In Metadata.Enums.OperationsWithPermissionSets.EnumValues Do
		OperationKinds.Insert(EnumValue.Name, Enums.OperationsWithPermissionSets[EnumValue.Name]);
	EndDo;
	
	Return New Structure("OperationKinds, RequestApplyingScenario, InfobaseAdministrationParametersRequired",
		OperationKinds, RequestApplyingScenario, InfobaseAdministrationParametersRequired);
	
EndFunction

&AtServer
Procedure FinishRequestApplying(Val StorageAddress)
	
	SaveAdministrationParameters();
	
EndProcedure

&AtServer
Procedure SaveAdministrationParameters()
	
	AdministrationParametersToSave = New Structure();
	
	// Cluster administration parameters
	AdministrationParametersToSave.Insert("ConnectionType", ConnectionType);
	AdministrationParametersToSave.Insert("ServerAgentAddress", ServerAgentAddress);
	AdministrationParametersToSave.Insert("ServerAgentPort", ServerAgentPort);
	AdministrationParametersToSave.Insert("AdministrationServerAddress", AdministrationServerAddress);
	AdministrationParametersToSave.Insert("AdministrationServerPort", AdministrationServerPort);
	AdministrationParametersToSave.Insert("ClusterPort", ServerClusterPort);
	AdministrationParametersToSave.Insert("ClusterAdministratorName", ClusterAdministratorName);
	AdministrationParametersToSave.Insert("ClusterAdministratorPassword", "");
	
	// Infobase administration parameters
	AdministrationParametersToSave.Insert("NameInCluster", NameInCluster);
	AdministrationParametersToSave.Insert("InfobaseAdministratorName", InfobaseUserName(InfobaseAdministrator));
	AdministrationParametersToSave.Insert("InfobaseAdministratorPassword", "");
	
	StandardSubsystemsServer.SetAdministrationParameters(AdministrationParametersToSave);
	
EndProcedure

&AtClient
Procedure WaitForSettingsApplyingInCluster()
	
	Close(DialogReturnCode.OK);
	
EndProcedure

#EndRegion 