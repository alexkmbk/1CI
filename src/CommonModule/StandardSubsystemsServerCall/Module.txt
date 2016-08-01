////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
//  
////////////////////////////////////////////////////////////////////////////////

#Region InternalInterface

// Writes the exit confirmation state for the current user.
//
// Parameters:
// Value - Boolean - value to set.
// 
Procedure SaveExitConfirmationSettings(Value) Export
	
	CommonUse.CommonSettingsStorageSave("UserCommonSettings", "AskConfirmationOnExit", Value);
	
EndProcedure

// Returns a structure of the parameters required for executing the client script
// during the configuration startup, that is in the following event handlers:
// - BeforeStart, 
// - OnStart.
//
Function ClientParametersOnStart(Parameters) Export
	
	StoreTempParameters(Parameters);
	
	If Parameters.RetrievedClientParameters <> Undefined Then
		If Not Parameters.Property("SkipClearingDesktopHiding") Then
			HideDesktopOnStart(False);
		EndIf;
	EndIf;
	
	PrivilegedModeSetOnStart = PrivilegedMode();
	
	SetPrivilegedMode(True);
	If SessionParameters.ClientParametersOnServer.Count() = 0 Then
		// First server call from the client during the startup.
		ClientParameters = New Map;
		ClientParameters.Insert("LaunchParameter", Parameters.LaunchParameter);
		ClientParameters.Insert("InfobaseConnectionString", Parameters.InfobaseConnectionString);
		ClientParameters.Insert("PrivilegedModeSetOnStart", PrivilegedModeSetOnStart);
		ClientParameters.Insert("IsWebClient",    Parameters.IsWebClient);
		ClientParameters.Insert("IsLinuxClient", Parameters.IsLinuxClient);
		SessionParameters.ClientParametersOnServer = New FixedMap(ClientParameters);
		
		If Not CommonUseCached.DataSeparationEnabled() Then
			If ExchangePlans.MasterNode() <> Undefined
			 Or ValueIsFilled(Constants.MasterNode.Get()) Then
				// Preventing accidental predefined data update in the subordinate DIB note:
				// - during startup with the main node temporarily canceled;
				// - during restructuring data when the node is recovered.
				If GetInfobasePredefinedData()
				     <> PredefinedDataUpdate.DontAutoUpdate Then
					SetInfobasePredefinedDataUpdate(
						PredefinedDataUpdate.DontAutoUpdate);
				EndIf;
				If ExchangePlans.MasterNode() <> Undefined
				   And Not ValueIsFilled(Constants.MasterNode.Get()) Then
					// Saving the main node to provide recovery feature.
					MasterNodeManager = Constants.MasterNode.CreateValueManager();
					MasterNodeManager.Value = ExchangePlans.MasterNode();
					InfobaseUpdate.WriteData(MasterNodeManager);
				EndIf;
			EndIf;
		EndIf;		
	EndIf;
	SetPrivilegedMode(False);
	
	If Not StandardSubsystemsServer.AddClientParametersOnStart(Parameters) Then
		FixedParameters = FixedClientParametersWithoutTempParameters(Parameters);
		Return FixedParameters;
	EndIf;
	
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.BaseFunctionality\OnAddStandardSubsystemClientLogicParametersOnStart");
	For Each Handler In EventHandlers Do
		Handler.Module.OnAddStandardSubsystemClientLogicParametersOnStart(Parameters);
	EndDo;
	
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.BaseFunctionality\OnAddClientParametersOnStart");
	
	For Each Handler In EventHandlers Do
		Handler.Module.OnAddClientParametersOnStart(Parameters);
	EndDo;
	
	AppliedParameters = New Structure;
	CommonUseOverridable.ClientParametersOnStart(AppliedParameters);
	
	For Each Parameter In AppliedParameters Do
		Parameters.Insert(Parameter.Key, Parameter.Value);
	EndDo;
	
	FixedParameters = FixedClientParametersWithoutTempParameters(Parameters);
	Return FixedParameters;
	
EndFunction

// Returns the structure of parameters required for configuration client script
// execution. 
//
Function ClientParameters() Export
	
	Parameters = New Structure;
	
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.BaseFunctionality\StandardSubsystemClientLogicParametersOnAdd");
	
	For Each Handler In EventHandlers Do
		Handler.Module.StandardSubsystemClientLogicParametersOnAdd(Parameters);
	EndDo;
	
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.BaseFunctionality\ClientParametersOnAdd");
	
	For Each Handler In EventHandlers Do
		Handler.Module.ClientParametersOnAdd(Parameters);
	EndDo;
	
	AppliedParameters = New Structure;
	CommonUseOverridable.ClientParameters(AppliedParameters);
	
	For Each Parameter In AppliedParameters Do
		Parameters.Insert(Parameter.Key, Parameter.Value);
	EndDo;
	
	Return CommonUse.FixedData(Parameters);
	
EndFunction

// Returns the platform type as a string.
Function ServerPlatformTypeString() Export
	
	SystemInfo = New SystemInfo;
	
	If SystemInfo.PlatformType = PlatformType.Linux_x86 Then
		Return "Linux_x86";
		
	ElsIf SystemInfo.PlatformType = PlatformType.Linux_x86_64 Then
		Return "Linux_x86_64";
		
	ElsIf SystemInfo.PlatformType = PlatformType.Windows_x86 Then
		Return "Windows_x86";
		
	ElsIf SystemInfo.PlatformType = PlatformType.Windows_x86_64 Then
		Return "Windows_x86_64";
		
	ElsIf SystemInfo.PlatformType = Undefined Then
		Return Undefined;
	EndIf;
	
	Raise StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en = 'Unknown platform type: %1'"),
		String(SystemInfo.PlatformType));
	
EndFunction

// Returns an array of client module names.
Function ClientModuleNameArray() Export
	
	ClientModules = New Array;
	
	For Each CommonModule In Metadata.CommonModules Do
		If CommonModule.Global Then
			Continue;
		EndIf;
		If CommonModule.ClientManagedApllication Then
			ClientModules.Add(CommonModule.Name);
		EndIf;
	EndDo;
	
	Return ClientModules;
	
EndFunction

#EndRegion

#Region InternalProceduresAndFunctions

// Sets the parameter that cancels the desktop form creating.
// The procedure is used if there is a need to interact with the user during the
// startup.
//
// Is used from the StandardSubsystemsClient module procedure of the same name.
// The direct call on server has the meaning for reducing server call numbers
// if during preparing client parameters with Cached module it is already known that
// interactive processing is required.
//
// If the client parameter getting procedure directly calls this procedure, the state
// on the client is updated automatically, otherwise use the StandardSubsystemsClient
// module procedure of the same name to update it.  
//
// Parameters:
//  Hide - Boolean - pass True to set the state or False to clear it. You can call the
//         RefreshInterface method once the procedure is executed to recreate the 
//         interface.
//
Procedure HideDesktopOnStart(Hide = True) Export
	
	SetPrivilegedMode(True);
	
	CurrentParameters = New Map(SessionParameters.ClientParametersOnServer);
	
	If Hide = True Then
		CurrentParameters.Insert("HideDesktopOnStart", True);
		
	ElsIf CurrentParameters.Get("HideDesktopOnStart") <> Undefined Then
		CurrentParameters.Delete("HideDesktopOnStart");
	EndIf;
	
	SessionParameters.ClientParametersOnServer = New FixedMap(CurrentParameters);
	
EndProcedure

// Returns the structure of parameters required for executing the configuration client
// script during exiting the application.
//
Function ClientParametersOnExit() Export
	
	Parameters = New Structure();
	
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.BaseFunctionality\StandardSubsystemClientLogicParametersOnAddOnExit");
	
	For Each Handler In EventHandlers Do
		Handler.Module.StandardSubsystemClientLogicParametersOnAddOnExit(Parameters);
	EndDo;
	
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.BaseFunctionality\ClientParametersOnAddOnExit");
	
	For Each Handler In EventHandlers Do
		Handler.Module.ClientParametersOnAddOnExit(Parameters);
	EndDo;
	
	AppliedParameters = New Structure;
	CommonUseOverridable.ClientParametersOnExit(AppliedParameters);
	
	For Each Parameter In AppliedParameters Do
		Parameters.Insert(Parameter.Key, Parameter.Value);
	EndDo;
	
	Return CommonUse.FixedData(Parameters);
	
EndFunction

// For internal use only.
Procedure EventHandlersGettingOnError() Export
	
	If Not ExclusiveMode() And TransactionActive() Then
		Return;
	EndIf;
	
	If Not CommonUseCached.DataSeparationEnabled()
	 Or Not CommonUseCached.CanUseSeparatedData() Then
		// Cache autoupdate. Cached values must be updated.		
		If Not ExclusiveMode() Then
			Try
				SetExclusiveMode(True);
			Except
				Return;
			EndTry;
		EndIf;
		
		Try
			Constants.InternalEventParameters.CreateValueManager().Update();
		Except
			SetExclusiveMode(False);
			RefreshReusableValues();
			Raise;
		EndTry;
		
		RefreshReusableValues();
	EndIf;
	
EndProcedure

// Returns False if exclusive mode can be set
Function ExclusiveModeSettingError() Export
	
	SetPrivilegedMode(True);
	
	Cancel = False;
	Try
		SetExclusiveMode(True);
		SetExclusiveMode(False);
	Except
		Cancel = True
	EndTry;
	
	Return Cancel;
	
EndFunction

// For internal use only.
Function WriteErrorToEventLogOnStartOrExit(Exit, Val Event, Val ErrorText) Export
	
	If Event = "Start" Then
		EventName = NStr("en = 'Application startup'", CommonUseClientServer.DefaultLanguageCode());
		If Exit Then
			ErrorDetailsBeginning = NStr("en = 'An exception occurred during the application startup. The application will be terminated.'");
		Else
			ErrorDetailsBeginning = NStr("en = 'An exception occurred during the application startup.'");
		EndIf;
	Else
		EventName = NStr("en = 'Application exit'", CommonUseClientServer.DefaultLanguageCode());
		ErrorDetailsBeginning = NStr("en = 'An exception occurred during exiting the application.'");
	EndIf;
	
	ErrorDescription = ErrorDetailsBeginning
		+ Chars.LF + Chars.LF
		+ ErrorText;
	WriteLogEvent(EventName, EventLogLevel.Error,,, ErrorText);
	Return ErrorDetailsBeginning;

EndFunction

////////////////////////////////////////////////////////////////////////////////
// Predefined data processing

// Retrieves the predefined item reference by the full name.
// For details see CommonUseClientServer.PredefinedItem().
//
Function PredefinedItem(Val PredefinedItemFullName) Export
	
	Return StandardSubsystemsCached.PredefinedItem(PredefinedItemFullName);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// AUXILIARY PROCEDURES AND FUNCTIONS

Procedure StoreTempParameters(Parameters)
	
	Parameters.Insert("TempParameterNames", New Array);
	
	For Each KeyAndValue In Parameters Do
		Parameters.TempParameterNames.Add(KeyAndValue.Key);
	EndDo;
	
EndProcedure

Function FixedClientParametersWithoutTempParameters(Parameters)
	
	ClientParameters = Parameters;
	Parameters = New Structure;
	
	For Each TemporaryParameterName In ClientParameters.TempParameterNames Do
		Parameters.Insert(TemporaryParameterName, ClientParameters[TemporaryParameterName]);
		ClientParameters.Delete(TemporaryParameterName);
	EndDo;
	Parameters.Delete("TempParameterNames");
	
	SetPrivilegedMode(True);
	
	Parameters.HideDesktopOnStart =
		SessionParameters.ClientParametersOnServer.Get(
			"HideDesktopOnStart") <> Undefined;
	
	SetPrivilegedMode(False);
	
	Return CommonUse.FixedData(ClientParameters);
	
EndFunction

#EndRegion
