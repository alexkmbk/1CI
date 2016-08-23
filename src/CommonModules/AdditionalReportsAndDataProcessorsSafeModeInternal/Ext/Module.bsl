////////////////////////////////////////////////////////////////////////////////
// Additional reports and data processors subsystem, safe
// mode extension, internal procedures and functions.
//
////////////////////////////////////////////////////////////////////////////////

#Region InternalInterface

////////////////////////////////////////////////////////////////////////////////
// Adds handlers of internal events (subscriptions).

// See the description of this procedure in the StandardSubsystemsServer module.
Procedure InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers) Export
	
	// SERVER HANDLERS
	
	ServerHandlers["StandardSubsystems.BaseFunctionality\OnFillPermissionsToAccessExternalResources"].Add(
		"AdditionalReportsAndDataProcessorsSafeModeInternal");
	
	ServerHandlers["StandardSubsystems.BaseFunctionality\ExternalModuleManagersOnRegistration"].Add(
		"AdditionalReportsAndDataProcessorsSafeModeInternal");
	
EndProcedure

// The procedure is called when external module managers are registered.
//
// Parameters:
//  Managers - Array(CommonModule).
//
Procedure ExternalModuleManagersOnRegistration(Managers) Export
	
	Managers.Add(AdditionalReportsAndDataProcessorsSafeModeInternal);
	
EndProcedure

// Returns the template of an external module security profile name.
// The function should return the same value every time it is called.
//
// Parameters:
//  ExternalModule - AnyRef – a reference to an external module.
//
//  Returns: String - security profile name template 
//                    with "%1" character sequence to be replaced by UUID.
//
Function SecurityProfileNameTemplate(Val ExternalModule) Export
	
	Return "Extension_%1"; // Do not localize this parameter
	
EndFunction

// Returns dictionary of presentations for external container modules.
//
// Returns: Structure
//  * Nominative - String - external module type presentation in nominative case.
//  * Genitive   - String - external module type presentation in genitive case.
//
Function ExternalModuleContainerDictionary() Export
	
	Result = New Structure();
	
	Result.Insert("NominativeCase", NStr("en = 'Additional report or data processor'"));
	Result.Insert("Genitive", NStr("en = 'Additional report or data processor'"));
	
	Return Result;
	
EndFunction

// Returns array of reference metadata objects that 
// can be used as external module containers.
//
// Returns: Array(MetadataObject).
//
Function ExternalModuleContainers() Export
	
	Result = New Array();
	Result.Add(Metadata.Catalogs.AdditionalReportsAndDataProcessors);
	Return Result;
	
EndFunction

// Fills a list of requests for external permissions that must be granted when an infobase is created or an application is updated.
//
// Parameters:
//  PermissionRequests - Array - list of values returned by 
//                     SafeMode.RequestToUseExternalResources() method.
//
Procedure OnFillPermissionsToAccessExternalResources(PermissionRequests) Export
	
	If Not CommonUseCached.CanUseSeparatedData() Then
		Return;
	EndIf;
	
	QueryText =
		"SELECT DISTINCT
		|	AdditionalReportAndDataProcessorPermissions.Ref AS Ref
		|FROM
		|	Catalog.AdditionalReportsAndDataProcessors.Permissions AS AdditionalReportAndDataProcessorPermissions
		|WHERE
		|	AdditionalReportAndDataProcessorPermissions.Ref.Publication <> &Publication";
	Query = New Query(QueryText);
	Query.SetParameter("Publication", Enums.AdditionalReportsAndDataProcessorsPublicationVariants.Disabled);
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		Object = Selection.Ref.GetObject();
		NewRequests = AdditionalDataProcessorPermissionRequests(Object, Object.Permissions.Unload());
		CommonUseClientServer.SupplementArray(PermissionRequests, NewRequests);
		
	EndDo;
	
EndProcedure

Function AdditionalDataProcessorPermissionRequests(Object, PermissionsInData) Export
	
	If Object.Publication = Enums.AdditionalReportsAndDataProcessorsPublicationVariants.Disabled Then
		Return New Array();
	EndIf;
	
	HadPermissions = SafeModeInternal.ExternalModuleAttachingMode(Object.Ref) <> Undefined;
	HasPermissions = Object.Permissions.Count() > 0;
	
	If HadPermissions OR HasPermissions Then
		
		If Object.PermissionCompatibilityMode = Enums.AdditionalReportsAndDataProcessorsPermissionCompatibilityModes.Version_2_2_2 Then
			
			PermissionsToRequest = New Array();
			For Each PermissionInData In PermissionsInData Do
				Permission = XDTOFactory.Create(XDTOFactory.Type(SafeModeInternal.PermissionPresentationXDTOPackage(), PermissionInData.PermissionKind));
				PropertiesInData = PermissionInData.Parameters.Get();
				FillPropertyValues(Permission, PropertiesInData);
				PermissionsToRequest.Add(Permission);
			EndDo;
			
		Else
			
			OldPermissions = New Array();
			For Each PermissionInData In PermissionsInData Do
				Permission = XDTOFactory.Create(XDTOFactory.Type("http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/1.0.0.1", PermissionInData.PermissionKind));
				PropertiesInData = PermissionInData.Parameters.Get();
				FillPropertyValues(Permission, PropertiesInData);
				OldPermissions.Add(Permission);
			EndDo;
			
			PermissionsToRequest = AdditionalReportsAndDataProcessorsSafeModeInterface.ConvertVersion_2_1_3_PermissionsToVersion_2_2_2Permissions(Object, OldPermissions);
			
		EndIf;
		
		Return SafeModeInternal.ExternalResourceRequestsForExternalModule(Object.Ref, PermissionsToRequest);
		
	Else
		
		Return New Array();
		
	EndIf;
	
EndFunction

// For internal use only
Function GenerateSafeModeExtensionSessionKey(Val DataProcessor) Export
	
	Return DataProcessor.UUID();
	
EndFunction

// For internal use only
Function GetSafeModeExtentionSessionPermissions(Val SessionKey) Export
	
	SetPrivilegedMode(True);
	
	StandardProcessing = True;
	PermissionDetailList = Undefined;
	
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.AdditionalReportsAndDataProcessors\OnGetSafeModeExtentionSessionPermissions");
	
	For Each Handler In EventHandlers Do
		
		Handler.Module.OnGetSafeModeExtentionSessionPermissions(SessionKey, PermissionDetailList, StandardProcessing);
		
	EndDo;
	
	If StandardProcessing Then
		
		Ref = Catalogs.AdditionalReportsAndDataProcessors.GetRef(SessionKey);
		QueryText =
			"SELECT
			|	Permissions.PermissionKind AS PermissionKind,
			|	Permissions.Parameters AS Parameters
			|FROM
			|	Catalog.AdditionalReportsAndDataProcessors.Permissions AS Permissions
			|WHERE
			|	Permissions.Ref = &Ref";
		Query = New Query(QueryText);
		Query.SetParameter("Ref", Ref);
		PermissionDetailList = Query.Execute().Unload();
		
	EndIf;
	
	Result = New Map();
	
	For Each PermissionDetails In PermissionDetailList Do
		
		PermissionType = XDTOFactory.Type(
			AdditionalReportsAndDataProcessorsSafeModeInterface.Package(),
			PermissionDetails.PermissionKind);
		
		Result.Insert(PermissionType, PermissionDetails.Parameters.Get());
		
	EndDo;
	
	Return Result;
	
EndFunction

// For internal use only
Function ExecuteSafeModeScenario(Val SessionKey, Val Scenario, Val ExecutableObject, ExecutionParameters, ParametersToSave = Undefined, TargetObjects = Undefined) Export
	
	Exceptions = AdditionalReportsAndDataProcessorsSafeModeCached.GetAllowedMethods();
	
	If ParametersToSave = Undefined Then
		ParametersToSave = New Structure();
	EndIf;
	
	For Each ScenarioStep In Scenario Do
		
		PerformSafely = True;
		ExecutableVolume = "";
		
		If ScenarioStep.ActionKind = AdditionalReportsAndDataProcessorsSafeModeInterface.DataProcessorMethodCallActionKind() Then
			
			ExecutableVolume = "ExecutableObject." + ScenarioStep.MethodName;
			
		ElsIf ScenarioStep.ActionKind = AdditionalReportsAndDataProcessorsSafeModeInterface.ConfigurationMethodCallActionKind() Then
			
			ExecutableVolume = ScenarioStep.MethodName;
			
			If Exceptions.Find(ScenarioStep.MethodName) <> Undefined Then
				PerformSafely = False;
			EndIf;
			
		Else
			
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Unknown action type for the current scenario step: %1'"),
				ScenarioStep.ActionKind);
			
		EndIf;
		
		ParametersNotToSave = New Array();
		
		ParameterSubstring = "";
		
		MethodParameters = ScenarioStep.Parameters;
		For Each MethodParameter In MethodParameters Do
			
			If Not IsBlankString(ParameterSubstring) Then
				ParameterSubstring = ParameterSubstring + ", ";
			EndIf;
			
			If MethodParameter.Kind = AdditionalReportsAndDataProcessorsSafeModeInterface.ValuePropertyKind() Then
				
				ParametersNotToSave.Add(MethodParameter.Value);
				ParameterSubstring = ParameterSubstring + "ParametersNotToSave.Get(" +
					ParametersNotToSave.UBound() + ")";
				
			ElsIf MethodParameter.Kind = AdditionalReportsAndDataProcessorsSafeModeInterface.SessionKeyParameterKind() Then
				
				ParameterSubstring = ParameterSubstring + "SessionKey";
				
			ElsIf MethodParameter.Kind = AdditionalReportsAndDataProcessorsSafeModeInterface.ValueToSaveCollectionParameterKind() Then
				
				ParameterSubstring = ParameterSubstring + "ParametersToSave";
				
			ElsIf MethodParameter.Kind = AdditionalReportsAndDataProcessorsSafeModeInterface.ValueToSaveParameterKind() Then
				
				ParameterSubstring = ParameterSubstring + "ParametersToSave." + MethodParameter.Value;
				
			ElsIf MethodParameter.Kind = AdditionalReportsAndDataProcessorsSafeModeInterface.TargetObjectParameterKind() Then
				
				ParameterSubstring = ParameterSubstring + "TargetObjects";
				
			ElsIf MethodParameter.Kind = AdditionalReportsAndDataProcessorsSafeModeInterface.CommandRunParameterParameterKind() Then
				
				ParameterSubstring = ParameterSubstring + "ExecutionParameters." + MethodParameter.Value;
				
			Else
				
				Raise StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en = 'Unknown parameter kind for the current scenario step: %1'"),
					MethodParameter.Kind);
				
			EndIf;
			
		EndDo;
		
		ExecutableVolume = ExecutableVolume + "(" + ParameterSubstring + ")";
		
		If PerformSafely <> SafeMode() Then
			SetSafeMode(PerformSafely);
		EndIf;
		
		If Not IsBlankString(ScenarioStep.ResultSaving) Then
			Result = Eval(ExecutableVolume);
			ParametersToSave.Insert(ScenarioStep.ResultSaving, Result);
		Else
			Execute(ExecutableVolume);
		EndIf;
		
	EndDo;
	
EndFunction

// For internal use only
Procedure ValidateOperationLegitimacy(Val SessionKey, Val Permission) Export
	
	RequiredPermissionType = Permission.Type();
	
	SessionPermissions = GetSafeModeExtentionSessionPermissions(SessionKey);
	RestrictionPermissions = SessionPermissions.Get(RequiredPermissionType);
	
	If RestrictionPermissions = Undefined Then
		
		Raise PermissionNotGrantedExceptionText(
			SessionKey, RequiredPermissionType);
		
	Else
		
		RestrictionsToCheck = RequiredPermissionType.Properties;
		For Each RestrictionToCheck In RestrictionsToCheck Do
			
			RestrictionValue = Undefined;
			If RestrictionPermissions.Property(RestrictionToCheck.LocalName, RestrictionValue) Then
				
				If ValueIsFilled(RestrictionValue) Then
					
					Restrictor = Permission.GetXDTO(RestrictionToCheck);
					
					If RestrictionValue <> Restrictor.Value Then
						
						Raise PermissionNotGrantedForRestrictorExceptionText(
							SessionKey, RequiredPermissionType, RestrictionToCheck, Restrictor.Value);
						
					EndIf;
					
				EndIf;
				
			Else
				
				If Not RestrictionToCheck.CanBeEmpty Then
					
					Raise RequiredRestrictorNotSetExceptionText(
						SessionKey, RequiredPermissionType, RestrictionToCheck);
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

// For internal use
Function GetFileFromTemporaryStorage(Val BinaryDataAddress) Export
	
	TempFile = GetTempFileName();
	BinaryData = GetFromTempStorage(BinaryDataAddress);
	BinaryData.Write(TempFile);
	Return TempFile;
	
EndFunction

// For internal use only
Function ValidateCallByEnvironmentCorrectness() Export
	
	Return SafeMode() = False;
	
EndFunction

// For internal use only
Function GeneratePermissionPresentation(Val Permissions) Export
	
	PermissionDetailList = AdditionalReportsAndDataProcessorsSafeModeCached.Dictionary();
	
	Result = "<HTML><BODY bgColor=#fcfaeb>";
	
	For Each Permission In Permissions Do
		
		PermissionKind = Permission.PermissionKind;
		
		PermissionDetails = PermissionDetailList.Get(
			XDTOFactory.Type(
				AdditionalReportsAndDataProcessorsSafeModeInterface.Package(),
				PermissionKind));
		
		PermissionPresentation = PermissionDetails.Presentation;
		
		ParameterPresentations = "";
		Parameters = Permission.Parameters.Get();
		
		If Parameters <> Undefined Then
			
			For Each Parameter In Parameters Do
				
				If Not IsBlankString(ParameterPresentations) Then
					ParameterPresentations = ParameterPresentations + ", ";
				EndIf;
				
				ParameterPresentations = ParameterPresentations + String(Parameter.Value);
				
			EndDo;
			
		EndIf;
		
		If Not IsBlankString(ParameterPresentations) Then
			PermissionPresentation = PermissionPresentation + " (" + ParameterPresentations + ")";
		EndIf;
		
		Result = Result + StringFunctionsClientServer.SubstituteParametersInString(
			"<LI><FONT size=2>%1 <A href=""%2"">%3</A></FONT>",
			PermissionPresentation,
			"internal:" + PermissionKind,
			NStr("en = 'Details...'"));
		
	EndDo;
	
	Result = Result + "</LI></BODY></HTML>";
	
	Return Result;
	
EndFunction

// For internal use only
Function GenerateDetailedPermissionDetails(Val PermissionKind, Val PermissionParameters) Export
	
	PermissionDetailList = AdditionalReportsAndDataProcessorsSafeModeCached.Dictionary();
	
	Result = "<HTML><BODY bgColor=#fcfaeb>";
	
	PermissionDetails = PermissionDetailList.Get(
		XDTOFactory.Type(
			AdditionalReportsAndDataProcessorsSafeModeInterface.Package(),
			PermissionKind));
	
	PermissionPresentation = PermissionDetails.Presentation;
	PermissionDetails = PermissionDetails.Details;
	
	ParameterDescriptions = Undefined;
	HasParameters = PermissionDetails.Property("Parameters", ParameterDescriptions);
	
	Result = Result + "<P><FONT size=2><A href=""internal:home"">&lt;&lt; Back to permission list </A></FONT></P>";
	
	Result = Result + StringFunctionsClientServer.SubstituteParametersInString(
		"<P><STRONG><FONT size=4>%1</FONT></STRONG></P>",
		PermissionPresentation);
	
	Result = Result + StringFunctionsClientServer.SubstituteParametersInString(
		"<P><FONT size=2>%1%2</FONT></P>", PermissionDetails, ?(
			HasParameters,
			NStr("en = ' with the following restrictions:'"),
			"."));
	
	If HasParameters Then
		
		Result = Result + "<UL>";
		
		For Each Parameter In ParameterDescriptions Do
			
			ParameterName = Parameter.Name;
			ParameterValue = PermissionParameters[ParameterName];
			
			If ValueIsFilled(ParameterValue) Then
				
				ParameterDescription = StringFunctionsClientServer.SubstituteParametersInString(
					Parameter.Details, ParameterValue);
				
			Else
				
				ParameterDescription = StringFunctionsClientServer.SubstituteParametersInString(
					"<B>%1</B>", Parameter.AnyValueDetails);
				
			EndIf;
			
			Result = Result + StringFunctionsClientServer.SubstituteParametersInString(
				"<LI><FONT size=2>%1</FONT>", ParameterDescription);
			
		EndDo;
		
		Result = Result + "</LI></UL>";
		
	EndIf;
	
	ConsequenceDescriptions = "";
	If PermissionDetails.Property("Consequences", ConsequenceDescriptions) Then
		
		Result = Result + StringFunctionsClientServer.SubstituteParametersInString(
			"<P><FONT size=2><EM>%1</EM></FONT></P>",
			ConsequenceDescriptions);
		
	EndIf;
	
	Result = Result + "<P><FONT size=2><A href=""internal:home"">&lt;&lt; Back to permission list</A></FONT></P>";
	
	Result = Result + "</BODY></HTML>";
	
	Return Result;
	
EndFunction

#EndRegion

#Region InternalProceduresAndFunctions

// For internal use only
Function PermissionNotGrantedExceptionText(Val SessionKey, Val RequiredPermissionType)
	
	Return StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Additional report or data processor %1 is not granted permission {%2}%3.'"),
			String(SessionKey), RequiredPermissionType.NamespaceURI, RequiredPermissionType.Name);
	
EndFunction

// For internal use only
Function PermissionNotGrantedForRestrictorExceptionText(Val SessionKey, Val RequiredPermissionType, Val RestrictionToCheck, Val Restrictor)
	
	Return StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en = 'Additional report or data processor %1 is not granted permission {%2}%3 
               |when the %4 restriction value is equal to %5.'"),
		String(SessionKey), RequiredPermissionType.NamespaceURI, RequiredPermissionType.Name,
		RestrictionToCheck.LocalName, Restrictor);
	
EndFunction

// For internal use only
Function RequiredRestrictorNotSetExceptionText(Val SessionKey, Val RequiredPermissionType, Val RestrictionToCheck)
	
	Return StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en = 'For additional report or data processor %1 mandatory restriction %4 was not specified
              |  when the following permissions were granted: {%2}%3.'"),
		String(SessionKey), RequiredPermissionType.NamespaceURI, RequiredPermissionType.Name,
		RestrictionToCheck.LocalName);
	
EndFunction

#EndRegion
