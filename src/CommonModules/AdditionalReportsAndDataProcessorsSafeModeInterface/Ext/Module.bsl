////////////////////////////////////////////////////////////////////////////////
// ADDITIONAL REPORTS AND DATA PROCESSORS PERMISSION INTERFACE HANDLER MODULE
//
////////////////////////////////////////////////////////////////////////////////

#Region Interface

// Returns the namespace of the current message interface version (it is 
// the version used in the caller script).
Function Package() Export
	
	Return "http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/" + Version();
	
EndFunction

// Returns the current message interface version (it is the version used in
// the caller script).
Function Version() Export
	
	Return "1.0.0.1";
	
EndFunction

// Returns the name of the message API.
Function Interface() Export
	
	Return "ApplicationExtensionsPermissions";
	
EndFunction

// Registers supported message interface versions.
//
// Parameters:
//  SupportedVersionStructure - Structure:
//    Key   - software interface name. 
//    Value - array of supported versions.
//
Procedure RegisterInterface(Val SupportedVersionStructure) Export
	
	VersionArray = New Array;
	VersionArray.Add("1.0.0.1");
	SupportedVersionStructure.Insert(Interface(), VersionArray);
	
EndProcedure

// Registers message handlers as message exchange channel handlers.
//
// Parameters:
//  HandlerArray - Array.
//
Procedure MessageChannelHandlers(Val HandlerArray) Export
	
EndProcedure

// Returns action kind ID of configuration method call.
//
Function ConfigurationMethodCallActionKind() Export
	
	Return "ConfigurationMethod"; // Do not localize this parameter
	
EndFunction

// Returns action kind ID of data processor method call.
//
Function DataProcessorMethodCallActionKind() Export
	
	Return "DataProcessorMethod"; // Do not localize this parameter
	
EndFunction

// Returns parameter kind ID of startup key.
//
Function SessionKeyParameterKind() Export
	
	Return "SessionKey"; // Do not localize this parameter
	
EndFunction

// Returns parameter kind ID of fixed value.
//
Function ValuePropertyKind() Export
	
	Return "FixedValue"; // Do not localize this parameter
	
EndFunction

// Returns parameter kind ID of saved value.
//
Function ValueToSaveParameterKind() Export
	
	Return "ValueToSave"; // Do not localize this parameter
	
EndFunction

// Returns parameter kind ID of saved value collection.
//
Function ValueToSaveCollectionParameterKind() Export
	
	Return "ValueToSaveCollection"; // Do not localize this parameter
	
EndFunction

// Returns parameter kind ID of command execution parameter.
//
Function CommandRunParameterParameterKind() Export
	
	Return "CommandRunParameter"; // Do not localize this parameter
	
EndFunction

// Returns parameter kind ID of target object collection.
//
Function TargetObjectParameterKind() Export
	
	Return "TargetObjects"; // Do not localize this parameter
	
EndFunction

// Constructor of a blank value table that is
// used as a description of safe mode scenario.
//
// Returns: ValueTable.
//
Function NewScenario() Export
	
	Result = New ValueTable();
	Result.Columns.Add("ActionKind", New TypeDescription("String"));
	Result.Columns.Add("MethodName", New TypeDescription("String"));
	Result.Columns.Add("Parameters", New TypeDescription("ValueTable"));
	Result.Columns.Add("ResultSaving", New TypeDescription("String"));
	
	Return Result;
	
EndFunction

// Adds a stage that includes execution of a configuration method
// to safe mode data processor execution scenario.
//
// Parameters:
//  Scenario     - ValueTable - structure of columns should match 
//                 the return value of NewScenario() function.
//  MethodName   - String - configuration method name that is called
//                 in this scenario stage.
//  ResultSaving - String - name of the saved scenario value that stores 
//                 the execution result of the method passed as MethodName parameter.
//
// Returns: ValueTableRow.
//
Function AddConfigurationMethod(Scenario, Val MethodName, Val ResultSaving = "") Export
	
	Return AddStage(Scenario, ConfigurationMethodCallActionKind(), MethodName, ResultSaving);
	
EndFunction

// Adds a stage that includes execution of a data processor method
// to safe mode data processor execution scenario.
//
// Parameters:
//  Scenario     - ValueTable - structure of columns should match 
//                 the return value of NewScenario() function.
//  MethodName   - String - configuration method name that is called
//                 in this scenario stage.
//  ResultSaving - String - name of the saved scenario value that stores 
//                 the execution result of the method passed as MethodName parameter.
//
// Returns: ValueTableRow.
//
Function AddDataProcessorMethod(Scenario, Val MethodName, Val ResultSaving = "") Export
	
	Return AddStage(Scenario, DataProcessorMethodCallActionKind(), MethodName, ResultSaving);
	
EndFunction

// Constructor of a blank value table that is used as a description 
// of safe mode scenario item parameters.
//
// Returns: ValueTable.
//
Function NewParameterTable() Export
	
	Result = New ValueTable();
	Result.Columns.Add("Kind", New TypeDescription("String"));
	Result.Columns.Add("Value");
	
	Return Result;
	
EndFunction

// Adds a startup key of the current data processor to a table of parameters.
//
// Parameters:
//  Stage - ValueTableRow - value returned by AddConfigurationMethod or AddDataProcessorMethod.
//   
//
Procedure AddSessionKey(Stage) Export
	
	AddParameter(Stage, SessionKeyParameterKind());
	
EndProcedure

// Adds a fixed value to a table of parameters.
//
// Parameters:
//  Stage - ValueTableRow - value returned by AddConfigurationMethod or AddDataProcessorMethod.
//  Value - Arbitrary - fixed value.
//
Procedure AddValue(Stage, Val Value) Export
	
	AddParameter(Stage, ValuePropertyKind(), Value);
	
EndProcedure

// Adds a fixed value to a table of parameters.
//
// Parameters:
//  Stage       - ValueTableRow - value returned by AddConfigurationMethod or AddDataProcessorMethod.
//  ValueToSave - String - name of a saved value variable inside a scenario.
//
Procedure AddStoredValue(Stage, Val ValueToSave) Export
	
	AddParameter(Stage, ValueToSaveParameterKind(), ValueToSave);
	
EndProcedure

// Adds a saved value collection to a table of parameters.
//
// Parameters:
//  Stage - ValueTableRow - value returned by AddConfigurationMethod or AddDataProcessorMethod.
//
Procedure AddValueToSaveCollection(Stage) Export
	
	AddParameter(Stage, ValueToSaveCollectionParameterKind());
	
EndProcedure

// Adds a command execution parameter to a table of parameters.
//
// Parameters:
//  Stage         - ValueTableRow - value returned  by AddConfigurationMethod  or AddDataProcessorMethod.
//  ParameterName - String - command execution parameter name.
//
Procedure AddCommandRunParameter(Stage, Val ParameterName) Export
	
	AddParameter(Stage, CommandRunParameterParameterKind(), ParameterName);
	
EndProcedure

// Adds a purpose object collection to a table of parameters.
//
// Parameters:
//  Stage - ValueTableRow - value returned by AddConfigurationMethod or AddDataProcessorMethod..
//  
Procedure AddTargetObjects(Stage) Export
	
	AddParameter(Stage, TargetObjectParameterKind());
	
EndProcedure

// Returns {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}CreateComObject type
//
// Parameters:
//  PackageUsed - String - namespace of message interface version
//                     whose message type is retrieved.
//
// Returns:
//  XDTOType
//
Function COMObjectCreationType(Val PackageUsed = Undefined) Export
	
	Return GenerateMessageType(PackageUsed, "CreateComObject");
	
EndFunction

// Returns {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}CreateComObject object
//
// Parameters:
//  ProgId.
//  PackageUsed - String - namespace of message interface version
//                     whose message type is retrieved.
//
// Returns:
//  XDTODataObject
//
Function PermissionToCreateCOMObject(Val ProgId, Val PackageUsed = Undefined) Export
	
	Type = COMObjectCreationType(PackageUsed);
	Permission = XDTOFactory.Create(Type);
	Permission.ProgId = ProgId;
	
	Return Permission;
	
EndFunction

// Returns {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}AttachAddin type
//
// Parameters:
//  PackageUsed - String - namespace of message interface version
//                     whose message type is retrieved.
//
// Returns:
//  XDTOType
//
Function AddInAttachingType(Val PackageUsed = Undefined) Export
	
	Return GenerateMessageType(PackageUsed, "AttachAddin");
	
EndFunction

// Returns {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}AttachAddin object
//
// Parameters:
//  CommonTemplateName - String.
//  PackageUsed   - String - namespace of message interface version
//                       whose message type is retrieved.
//
// Returns:
//  XDTODataObject
//
Function ConnectAddInFormConfigurationCommonTemplatePermission(Val CommonTemplateName, Val PackageUsed = Undefined) Export
	
	Type = AddInAttachingType(PackageUsed);
	Permission = XDTOFactory.Create(Type);
	Permission.TemplateName = "CommonTemplate." + CommonTemplateName;
	
	Return Permission;
	
EndFunction

// Returns {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}AttachAddin object
//
// Parameters:
//  MetadataObject.
//  TemplateName.
//  PackageUsed - String - namespace of message interface version
//                     whose message type is retrieved.
//
// Returns:
//  XDTODataObject
//
Function PermissionToAttachAddInFromConfigurationTemplate(Val MetadataObject, Val TemplateName, Val PackageUsed = Undefined) Export
	
	Type = AddInAttachingType(PackageUsed);
	Permission = XDTOFactory.Create(Type);
	Permission.TemplateName = MetadataObject.FullName() + ".Template" + TemplateName;
	
	Return Permission;
	
EndFunction

// Returns {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}GetFileFromExternalSoftware type
//
// Parameters:
//  PackageUsed - String - namespace of message interface version
//                     whose message type is retrieved.
//
// Returns:
//  XDTOType
//
Function FileReceivingFromExternalObjectType(Val PackageUsed = Undefined) Export
	
	Return GenerateMessageType(PackageUsed, "GetFileFromExternalSoftware");
	
EndFunction

// Returns {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}GetFileFromExternalSoftware object
//
// Parameters:
//  PackageUsed - String - namespace of message interface version
//                     whose message type is retrieved.
//
// Returns:
//  XDTODataObject
//
Function PermissionToGetFileFromExternalObject(Val PackageUsed = Undefined) Export
	
	Type = FileReceivingFromExternalObjectType(PackageUsed);
	Permission = XDTOFactory.Create(Type);
	
	Return Permission;
	
EndFunction

// Returns {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}SendFileToExternalSoftware type
//
// Parameters:
//  PackageUsed - String - namespace of message interface version
//                     whose message type is retrieved.
//
// Returns:
//  XDTOType
//
Function TransferFileToExternalObjectType(Val PackageUsed = Undefined) Export
	
	Return GenerateMessageType(PackageUsed, "SendFileToExternalSoftware");
	
EndFunction

// Returns {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}SendFileToExternalSoftware object
//
// Parameters:
//  PackageUsed - String - namespace of message interface version
//                     whose message type is retrieved.
//
// Returns:
//  XDTODataObject
//
Function PermissionToSendFileToExternalObject(Val PackageUsed = Undefined) Export
	
	Type = TransferFileToExternalObjectType(PackageUsed);
	Permission = XDTOFactory.Create(Type);
	
	Return Permission;
	
EndFunction

// Returns {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}GetFileFromInternet type
//
// Parameters:
//  PackageUsed - String - namespace of message interface version
//                     whose message type is retrieved.
//
// Returns:
//  XDTOType
//
Function DataReceivingFromInternetType(Val PackageUsed = Undefined) Export
	
	Return GenerateMessageType(PackageUsed, "GetFileFromInternet");
	
EndFunction

// Returns {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}GetFileFromInternet object
//
// Parameters:
//  Protocol   - String.
//  Server     - String.
//  Port       - String.
//  PackageUsed - String - namespace of message interface version
//                     whose message type is retrieved.
//
// Returns:
//  XDTODataObject
//
Function PermissionToGetDataFromInternet(Val Protocol, Val Server, Val Port, Val PackageUsed = Undefined) Export
	
	Type = DataReceivingFromInternetType(PackageUsed);
	Permission = XDTOFactory.Create(Type);
	Permission.Protocol = Upper(Protocol);
	Permission.Host = Server;
	Permission.Port = Port;
	
	Return Permission;
	
EndFunction

// Returns {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}SendFileToInternet type
//
// Parameters:
//  PackageUsed - String - namespace of message interface version
//                     whose message type is retrieved.
//
// Returns:
//  XDTOType
//
Function DataSendingToInternetType(Val PackageUsed = Undefined) Export
	
	Return GenerateMessageType(PackageUsed, "SendFileToInternet");
	
EndFunction

// Returns {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}SendFileToInternet object
//
// Parameters:
//  Protocol         - String.
//  Server           - String.
//  Port             - String.
//  PackageUsed - String - namespace of message interface version
//                     whose message type is retrieved.
//
// Returns:
//  XDTODataObject
//
Function SendDataToInternetPermission(Val Protocol, Val Server, Val Port, Val PackageUsed = Undefined) Export
	
	Type = DataSendingToInternetType(PackageUsed);
	Permission = XDTOFactory.Create(Type);
	Permission.Protocol = Upper(Protocol);
	Permission.Host = Server;
	Permission.Port = Port;
	
	Return Permission;
	
EndFunction

// Returns {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}SoapConnection type
//
// Parameters:
//  PackageUsed - String - namespace of message interface version
//                     whose message type is retrieved.
//
// Returns:
//  XDTOType
//
Function WSConnectionType(Val PackageUsed = Undefined) Export
	
	Return GenerateMessageType(PackageUsed, "SoapConnection");
	
EndFunction

// Returns {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}SoapConnection object
//
// Parameters:
//  WSDLAddress      - String.
//  PackageUsed - String - namespace of message interface version
//                     whose message type is retrieved.
//
// Returns:
//  XDTODataObject
//
Function WSConnectionPermission(Val WSDLAddress, Val PackageUsed = Undefined) Export
	
	Type = WSConnectionType(PackageUsed);
	Permission = XDTOFactory.Create(Type);
	Permission.WsdlDestination = WSDLAddress;
	
	Return Permission;
	
EndFunction

// Returns {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}DocumentPosting type
//
// Parameters:
//  PackageUsed - String - namespace of message interface version
//                     whose message type is retrieved.
//
// Returns:
//  XDTOType
//
Function DocumentPostingType(Val PackageUsed = Undefined) Export
	
	Return GenerateMessageType(PackageUsed, "DocumentPosting");
	
EndFunction

// Returns {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}DocumentPosting object
//
// Parameters:
//  MetadataObject   - String.
//  WriteMode        - String.
//  PackageUsed - String - namespace of message interface version
//                     whose message type is retrieved.
//
// Returns:
//  XDTODataObject
//
Function DocumentPostingPermission(Val MetadataObject, Val WriteMode, Val PackageUsed = Undefined) Export
	
	Type = DocumentPostingType(PackageUsed);
	Permission = XDTOFactory.Create(Type);
	Permission.DocumentType = MetadataObject.FullName();
	If WriteMode = DocumentWriteMode.Posting Then
		Permission.Action = "Posting";
	Else
		Permission.Action = "UndoPosting";
	EndIf;
	
	Return Permission;
	
EndFunction

// Returns {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}InternalFileHandler type
//
// Parameters:
//  PackageUsed - String - namespace of message interface version
//                     whose message type is retrieved.
//
// Returns:
//  XDTOType
//
Function ParameterPassedFile(Val PackageUsed = Undefined) Export
	
	Return GenerateMessageType(PackageUsed, "InternalFileHandler");
	
EndFunction

// Returns the value that matches "any restriction" value (*) during the registration of permissions
// that are requested by additional data processor.
//
// Returns: Undefined.
//
Function AnyValue() Export
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region InternalProceduresAndFunctions

Function GenerateMessageType(Val PackageUsed, Val Type)
		
	If PackageUsed = Undefined Then
		PackageUsed = Package();
	EndIf;
	
	Return XDTOFactory.Type(PackageUsed, Type);
	
EndFunction

Function AddStage(Scenario, Val StageKind, Val MethodName, Val ResultSaving = "")
	
	Stage = Scenario.Add();
	Stage.ActionKind = StageKind;
	Stage.MethodName = MethodName;
	Stage.Parameters = NewParameterTable();
	If Not IsBlankString(ResultSaving) Then
		Stage.ResultSaving = ResultSaving;
	EndIf;
	
	Return Stage;
	
EndFunction

Procedure AddParameter(Stage, Val ParameterKind, Val Value = Undefined)
	
	Parameter = Stage.Parameters.Add();
	Parameter.Kind = ParameterKind;
	If Value <> Undefined Then
		Parameter.Value = Value;
	EndIf;
	
EndProcedure

// Converts permissions from version 2.1.3 format to version 2.2.2 format.
//
Function ConvertVersion_2_1_3_PermissionsToVersion_2_2_2Permissions(Val AdditionalReportOrDataProcessor, Val Permissions) Export
	
	Result = New Array();
	
	// If a data processor has commands that represent a scenario,
  // adding access to the temporary file directory
 	ScenarioFilter = New Structure("RunningVariant", Enums.AdditionalDataProcessorCallMethods.ScenarioInSafeMode);
	HasScenarios = AdditionalReportOrDataProcessor.Commands.FindRows(ScenarioFilter).Count() > 0;
	If HasScenarios Then
		Result.Add(SafeMode.PermissionToUseTempDirectory(True, True));
	EndIf;
	
	// Converting permissions to safe mode "expansion" notations.
	For Each Permission In Permissions Do
		
		If Permission.Type() = DataReceivingFromInternetType(Package()) Then
			
			Result.Add(
				SafeMode.PermissionToUseInternetResource(
					Permission.Protocol,
					Permission.Host,
					Permission.Port));
			
		ElsIf Permission.Type() = DataSendingToInternetType(Package()) Then
			
			Result.Add(
				SafeMode.PermissionToUseInternetResource(
					Permission.Protocol,
					Permission.Host,
					Permission.Port));
			
		ElsIf Permission.Type() = WSConnectionType(Package()) Then
			
			URLStructure = CommonUseClientServer.URIStructure(Permission.WsdlDestination);
			
			Result.Add(
				SafeMode.PermissionToUseInternetResource(
					URLStructure.Schema,
					URLStructure.ServerName,
					Number(URLStructure.Port)));
			
		ElsIf Permission.Type() = COMObjectCreationType(Package()) Then
			
			Result.Add(
				SafeMode.PermissionToCreateCOMClass(
					Permission.ProgId,
					COMClassIDInBackwardCompatibilityMode(Permission.ProgId)));
			
		ElsIf Permission.Type() = AddInAttachingType(Package()) Then
			
			Result.Add(
				SafeMode.PermissionToUseAddIn(
					Permission.TemplateName));
			
		ElsIf Permission.Type() = FileReceivingFromExternalObjectType(Package()) Then
			
			Result.Add(
				SafeMode.PermissionToUseTempDirectory(True, True));
			
		ElsIf Permission.Type() = TransferFileToExternalObjectType(Package()) Then
			
			Result.Add(
				SafeMode.PermissionToUseTempDirectory(True, True));
			
		ElsIf Permission.Type() = DocumentPostingType(Package()) Then
			
			Result.Add(SafeMode.PermissionToUsePrivilegedMode());
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

Function COMClassIDInBackwardCompatibilityMode(Val ProgId)
	
	SupportedIDs = COMClassIDsInBackwardCompatibilityMode();
	CLSID = SupportedIDs.Get(ProgId);
	
	If CLSID = Undefined Then
		
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Permission to use %1 COM class cannot be granted to an additional data processor running in backward compatibility mode with permission functionality implemented in SL version 2.1.3.
                  |To be able to use the COM class, refactor the additional report or data processor to eliminate the need to run it in compatibility mode.'"),
				  ProgId
		);
		
	Else
		
		Return CLSID;
		
	EndIf;
	
EndFunction

Function COMClassIDsInBackwardCompatibilityMode()
	
	Result = New Map();
	
	// V83.ComConnector
	Result.Insert(CommonUse.COMConnectorName(), CommonUse.COMConnectorID(CommonUse.COMConnectorName()));
	// Word.Application
	Result.Insert("Word.Application", "000209FF-0000-0000-C000-000000000046");
	// Excel.Application
	Result.Insert("Excel.Application", "00024500-0000-0000-C000-000000000046");
	
	Return Result;
	
EndFunction

#EndRegion
