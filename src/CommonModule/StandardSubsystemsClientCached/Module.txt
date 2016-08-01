////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
//
//////////////////////////////////////////////////////////////////////////////// 

#Region Interface

// Returns a parameter structure required for running the application in the client
// mode, to be used is in the following event handlers:
// - BeforeStart, 
// - OnStart.
//
// Important: when running the application, do not use cache reset commands of 
// modules that reuse return values because this can lead to unpredictable errors 
// and unneeded service calls. 
//
// Returns:
//  FixedStructure - parameter structure for running the application on client.
//
Function ClientParametersOnStart() Export
	
 If TypeOf(ParametersOnApplicationStartAndExit) <> Type("Structure") Then

		ParametersOnApplicationStartAndExit = New Structure;
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("RetrievedClientParameters", Undefined);
	
	If  ParametersOnApplicationStartAndExit.Property("RetrievedClientParameters")
	 And TypeOf(ParametersOnApplicationStartAndExit.RetrievedClientParameters) = Type("Structure") Then
		
		Parameters.Insert("RetrievedClientParameters",
			ParametersOnApplicationStartAndExit.RetrievedClientParameters);
	EndIf;
	
	If  ParametersOnApplicationStartAndExit.Property("SkipClearingDesktopHiding") Then
		Parameters.Insert("SkipClearingDesktopHiding");
	EndIf;
	
#If WebClient Then
	IsWebClient = True;
#Else
	IsWebClient = False;
#EndIf
	
	SystemInfo = New SystemInfo;
	IsLinuxClient = SystemInfo.PlatformType = PlatformType.Linux_x86
	 Or SystemInfo.PlatformType = PlatformType.Linux_x86_64;

	Parameters.Insert("LaunchParameter", LaunchParameter);
	Parameters.Insert("InfobaseConnectionString", InfobaseConnectionString());
	Parameters.Insert("IsWebClient", IsWebClient);
	Parameters.Insert("IsLinuxClient", IsLinuxClient);
	Parameters.Insert("HideDesktopOnStart", False);
	
	ClientParameters =  StandardSubsystemsServerCall.ClientParametersOnStart(Parameters);
	
	// Updating the desktop hiding status on client by the state on server.
	StandardSubsystemsClient.HideDesktopOnStart(
		Parameters.HideDesktopOnStart, True);
	
	Return ClientParameters;	
EndFunction

// Returns a parameter structure required for running the application on client.
//
// Returns:
//  FixedStructure - parameter structure for running the application on client.
//
Function ClientParameters() Export
 
 	#If ThinClient Then  
		ClientFileNameToExecute = "1cv8c.exe";
	#Else
		ClientFileNameToExecute = "1cv8.exe";
	#EndIf
 
	CurrentDate = CurrentDate(); // current client computer date 
 
	ClientParameters = New Structure;

	RunParameters = StandardSubsystemsServerCall.ClientParameters();
	For Each Parameter In RunParameters Do
		ClientParameters.Insert(Parameter.Key, Parameter.Value);
	EndDo;
	ClientParameters.SessionTimeOffset = ClientParameters.SessionTimeOffset -  CurrentDate;
	ClientParameters.Insert("ClientFileNameToExecute", ClientFileNameToExecute);
	
	Return New  FixedStructure(ClientParameters);
	
EndFunction

#EndRegion

#Region InternalProceduresAndFunctions 

// Returns an array of client event handler details.
//
Function ClientEventHandlers(Event, Internal = False) Export
	
	PreparedHandlers = PreparedClientEventHandlers(Event, Internal);
	
	If PreparedHandlers = Undefined Then
		// Cache autoupdate. Cached values must be updated.
		StandardSubsystemsServerCall.EventHandlersGettingOnError();
		RefreshReusableValues();
		// Retrying to retrieve event handlers.
		PreparedHandlers =  PreparedClientEventHandlers(Event, Internal, False);
	EndIf;
	
	Return PreparedHandlers;
	
EndFunction

// Returns a map of names and client modules.
//
Function ClientModuleNames() Export
	
	NameArray = StandardSubsystemsServerCall.ClientModuleNameArray();
	
	ClientModules = New Map;
	
	For Each Name In NameArray Do
		ClientModules.Insert(Eval(Name), Name);
	EndDo;
	
	Return New FixedMap(ClientModules);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Processing predefined data.

// Retrieves the predefined item reference by the full name.
// For details see CommonUseClientServer.PredefinedItem().
//
Function PredefinedItem(Val PredefinedItemFullName) Export
	
	Return StandardSubsystemsServerCall.PredefinedItem(PredefinedItemFullName);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// AUXILIARY PROCEDURES AND FUNCTIONS

Function PreparedClientEventHandlers(Event, Internal = False, FirstTry = True)
	
	try
	Parameters = StandardSubsystemsClientCached.ClientParametersOnStart(
		).ClientEventsHandlers;
	Except
		Return Undefined;
	EndTry;
	
	If Internal Then
		Handlers = Parameters.InternalEventHandlers.Get(Event);
	Else
		Handlers = Parameters.EventHandlers.Get(Event);
	EndIf; 
	
	If FirstTry And Handlers = Undefined Then
		Return Undefined;
	EndIf;
	
	If Handlers = Undefined Then
		If Internal Then
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Client internal event ""%1"" is not found.'"),  Event);
		Else
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Client event ""%1"" is not found.'"),  Event);
		EndIf;
	EndIf;
	
	Array = New Array;
	
	For Each Handler In Handlers Do
		Item = New  Structure;
		Module = Undefined;
		If FirstTry Then
			Try
				Module = CommonUseClient.CommonModule(Handler.Module);
			Except
				Return Undefined;
			EndTry;
		Else
			Module = CommonUseClient.CommonModule(Handler.Module);
		EndIf;
		Item.Insert("Module",    Module);
		Item.Insert("Version",   Handler.Version);
		Item.Insert("Subsystem", Handler.Subsystem);
		Array.Add(New FixedStructure(Item));
	EndDo;
	
	Return New  FixedArray(Array);
	
EndFunction

#EndRegion