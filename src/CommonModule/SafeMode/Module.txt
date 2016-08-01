////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
// Common server procedures and functions for working with:
// - Application with security profiles enabled.
//
////////////////////////////////////////////////////////////////////////////////

#Region Interface

////////////////////////////////////////////////////////////////////////////////
// Permission constructors
//

// Returns the internal description of the permission to use the file system directory.
//
// Parameters:
//  Address     - String - file system resource address,
//  DataReading - Boolean - flag that shows whether permissions to read data from the file
//                system directory must be granted.
//  DataWriting - Boolean - flag that shows whether permissions to write data from the file
//                system directory must be granted.
//  Details     - String - details on the reasons to grant the permission.
//
// Returns:
//  XDTODataObject - internal description of the requested permissions.
//  Is intended only for passing as a parameter to the
//  SafeMode.RequestToUseExternalResources(),
//  SafeMode.RequestForCancelingPermissionsForExternalResources(), and
//  SafeMode.RequestForClearingPermissionsForExternalResources() functions.
//
Function PermissionToUseFileSystemDirectory(Val Address, Val DataReading = False, Val DataWriting = False, Val Details = "") Export
	
	Package = SafeModeInternal.PermissionPresentationXDTOPackage();
	Result = XDTOFactory.Create(XDTOFactory.Type(Package, "FileSystemAccess"));
	Result.Description = Details;
	
	If Right(Address, 1) = "\" Or Right(Address, 1) = "/" Then
		Address = Left(Address, StrLen(Address) - 1);
	EndIf;
	
	Result.Path = Address;
	Result.AllowedRead = DataReading;
	Result.AllowedWrite = DataWriting;
	
	Return Result;
	
EndFunction

// Returns the internal description of the permission to use the temporary directory.
//
// Parameters:
//  Address     - String - file system resource address,
//  DataReading - Boolean - flag that shows whether permissions to read data from the temporary
//                directory must be granted.
// DataWriting  - Boolean - flag that shows whether permissions to write data from the 
//                temporary directory must be granted.
// Details      - String - details on the reasons to grant the permission.
//
// Returns:
//  XDTODataObject - internal description of the requested permissions.
//  Is intended only for passing as a parameter to the
//  SafeMode.RequestToUseExternalResources(),
//  SafeMode.RequestForCancelingPermissionsForExternalResources(), and
//  SafeMode.RequestForClearingPermissionsForExternalResources() functions.
//
Function PermissionToUseTempDirectory(Val DataReading = False, Val DataWriting = False, Val Details = "") Export
	
	Return PermissionToUseFileSystemDirectory(TempDirectoryAlias(), DataReading, DataWriting);
	
EndFunction

// Returns the internal description of the permission to use the application directory.
//
// Parameters:
//  Address     - String - file system resource address,
//  DataReading - Boolean - flag that shows whether permissions to read data from the 
//                application directory must be granted.
// DataWriting  - Boolean - flag that shows whether permissions to write data from the
//                application directory must be granted.
// Details      - String - details on the reasons to grant the permission.
//
// Returns:
//  XDTODataObject - internal description of the requested permissions.
//  Is intended only for passing as a parameter to the
//  SafeMode.RequestToUseExternalResources(),
//  SafeMode.RequestForCancelingPermissionsForExternalResources(), and
//  SafeMode.RequestForClearingPermissionsForExternalResources() functions.
//
Function PermissionToUseApplicationDirectory(Val DataReading = False, Val DataWriting = False, Val Details = "") Export
	
	Return PermissionToUseFileSystemDirectory(ApplicationDirectoryAlias(), DataReading, DataWriting);
	
EndFunction

// Returns the internal description of the permission to use the COM class.
//
// Parameters:
//  ProgID       - String - ProgID of the COM class in the operating system.
//                 For example, "Excel.Application".
//  CLSID        - String - CLSID of the COM class in the operating system.
//  ComputerName - String - name of the computer where the specified object must be created.
//                 If the parameter is omitted, the object is created on the computer where the
//                 current process runs.
//  Details      - String - details on the reasons to grant the permission.
//
// Returns:
//  XDTODataObject - internal description of the requested permissions.
//  Is intended only for passing as a parameter to the
//  SafeMode.RequestToUseExternalResources(),
//  SafeMode.RequestForCancelingPermissionsForExternalResources(), and
//  SafeMode.RequestForClearingPermissionsForExternalResources() functions.
//
Function PermissionToCreateCOMClass(Val ProgID, Val CLSID, Val ComputerName = "", Val Details = "") Export
	
	Package = SafeModeInternal.PermissionPresentationXDTOPackage();
	Result = XDTOFactory.Create(XDTOFactory.Type(Package, "CreateComObject"));
	Result.Description = Details;
	
	Result.ProgId = ProgID;
	Result.CLSID = String(CLSID);
	Result.ComputerName = ComputerName;
	
	Return Result;
	
EndFunction

// Returns the internal description of the permission to use the external component distributed
// in the common configuration template.
//
// Parameters:
//  TemplateName - String - name of the common template with the distributed component.
//  Details      - String - details on the reasons to grant the permission.
//
// Returns:
//  XDTODataObject - internal description of the requested permissions.
//  Is intended only for passing as a parameter to the
//  SafeMode.RequestToUseExternalResources(),
//  SafeMode.RequestForCancelingPermissionsForExternalResources(), and
//  SafeMode.RequestForClearingPermissionsForExternalResources() functions.
//
Function PermissionToUseAddIn(Val TemplateName, Val Details = "") Export
	
	Package = SafeModeInternal.PermissionPresentationXDTOPackage();
	Result = XDTOFactory.Create(XDTOFactory.Type(Package, "AttachAddin"));
	Result.Description = Details;
	
	Result.TemplateName = TemplateName;
	
	Return Result;
	
EndFunction

// Returns the internal description of the permission to use the operating system application.
//
// Parameters:
// CommandLinePattern - String - command line pattern to start the application. See details in
//                      the 1C:Enterprice platform documentation.
// Details            - String - details on the reasons to grant the permission.
//
// Returns:
//  XDTODataObject - internal description of the requested permissions.
//  Is intended only for passing as a parameter to the
//  SafeMode.RequestToUseExternalResources(),
//  SafeMode.RequestForCancelingPermissionsForExternalResources(), and
//  SafeMode.RequestForClearingPermissionsForExternalResources() functions.
//
Function PermissionToUseOperatingSystemApplications(Val CommandLinePattern, Val Details = "") Export
	
	Package = SafeModeInternal.PermissionPresentationXDTOPackage();
	Result = XDTOFactory.Create(XDTOFactory.Type(Package, "RunApplication"));
	Result.Description = Details;
	
	Result.CommandMask = CommandLinePattern;
	
	Return Result;
	
EndFunction

// Returns the internal description of the permissions to use the Internet resource.
//
// Parameters:
//  Protocol - String - protocol that is used to interact with the resource. Allowed values are:
//              IMAP,
//              POP3,
//              SMTP,
//              HTTP,
//              HTTPS,
//              FTP,
//              FTPS.
//  URL      - String - resource URL without protocol.
//  Port     - Number - number of the port that is used to interact with the resource.
//  Details  - String - details on the reasons to grant the permission.
//
// Returns:
//  XDTODataObject - internal description the requested permissions.
//  Is Intended only for transfer in as parameter in function
//  SafeMode.RequestToUseExternalResources(),
//  SafeMode.RequestForCancelingPermissionsForExternalResources() and
//  SafeMode.RequestForClearingPermissionsForExternalResources().
//
Function PermissionToUseInternetResource(Val Protocol, Val URL, Val Port = Undefined, Val Details = "") Export
	
	If Port = Undefined Then
		StandardPorts = StandardInternetProtocolPorts();
		If StandardPorts.Property(Upper(Protocol)) <> Undefined Then
			Port = StandardPorts[Upper(Protocol)];
		EndIf;
	EndIf;
	
	Package = SafeModeInternal.PermissionPresentationXDTOPackage();
	Result = XDTOFactory.Create(XDTOFactory.Type(Package, "InternetResourceAccess"));
	Result.Description = Details;
	
	Result.Protocol = Protocol;
	Result.Host = URL;
	Result.Port = Port;
	
	Return Result;
	
EndFunction

// Returns the internal description of the permissions for extended data processing (including 
// the privileged mode) for external modules.
//
// Parameters:
//  Details - String - details on the reasons to grant the permission.
//
// Returns: XDTODataObject - internal description the requested permissions.
//  Is Intended only for transfer in as parameter in function
//  SafeMode.RequestToUseExternalResources(),
//  SafeMode.RequestForCancelingPermissionsForExternalResources() and
//  SafeMode.RequestForClearingPermissionsForExternalResources().
//
Function PermissionToUsePrivilegedMode(Val Details = "") Export
	
	Package = SafeModeInternal.PermissionPresentationXDTOPackage();
	Result = XDTOFactory.Create(XDTOFactory.Type(Package, "ExternalModulePrivilegedModeAllowed"));
	Result.Description = Details;
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Creating requests for permissions to use external resources
//

// Creates a request for permissions to use external resources.
//
// Parameters:
//  NewPermissions  - Array of XDTODataObject - array of objects corresponded to the internal
//                    descriptions of the requested permissions to access external resources.
//                    It is assumed that all XDTODataObjects passed as parameters are generated 
//                    using the SafeMode.Permission*() functions.
//  Owner           - AnyRef - reference to the infobase object that is logically associated
//                    with the requested permissions. For example, all permissions to access
//                    file storage volume directories are logically associated with the relevant
//                    FileStorageVolumes catalog items, all permissions to access data exchange
//                    directories (or other resources according to the used exchange transport)
//                    are logically associated with the relevant exchange plan nodes and so on.
//                    If the permission is logically isolated (for example, if the permission is
//                    managed by the value of a Boolean type constant) we recommend that you 
//                    use reference to the MetadataObjectIDs catalog item.
//  ReplacementMode - Boolean - defines the replacement mode of the permissions previously
//                    granted for this owner. It the value is True, in addition to the granting
//                    the requested permissions, clearing all permissions that were previously
//                    requested for the owner are added to the request.
//
// Returns:
//  UUID - reference to the permission request recorded in the infobase. When all requests are
//  created, the changes must be applied using the SafeModeClient.ApplyExternalResourceRequests()
// procedure.
//
Function RequestToUseExternalResources(Val NewPermissions, Val Owner = Undefined, Val ReplacementMode = True) Export
	
	Return SafeModeInternal.ExternalResourcesPermissionChangeRequest(
		Owner,
		ReplacementMode,
		NewPermissions);
	
EndFunction

// Creates a request for cancelling permissions to use external resources.
//
// Parameters:
// Owner               - AnyRef - reference to the infobase object that is logically associated
//                       with the requested permissions. For example, all permissions to 
//                       access file storage volume directories are logically associated with 
//                       the relevant FileStorageVolumes catalog items, all permissions to 
//                       access data exchange directories (or other resources according to the 
//                       used exchange transport) are logically associated with the relevant 
//                       exchange plan nodes and so on. If the permission is logically isolated 
//                       (for example, if the permission is managed by the value of a Boolean  
//                       type constant) we recommend that you use reference to the
//                       MetadataObjectIDs catalog item.
// PermissionsToCancel - Array of XDTODataObject - array of objects corresponded to the internal
//                       descriptions of the requested permissions to access external resources.
//                       It is assumed that all XDTODataObjects passed as parameters are 
//                       generated using the SafeMode.Permission*() functions.
//
// Returns:
//  UUID - reference to the permission request recorded in the infobase. When all requests are
//  created, the changes must be applied using the SafeModeClient.ApplyExternalResourceRequests()
//  procedure.
Function RequestForCancelingPermissionsForExternalResources(Val Owner, Val PermissionsToCancel) Export
	
	Return SafeModeInternal.ExternalResourcesPermissionChangeRequest(
		Owner,
		False,
		,
		PermissionsToCancel);
	
EndFunction

// Creates a request for cancelling all owner's permissions to use external resources.
//
// Parameters:
// Owner - AnyRef - reference to the infobase object that is logically associated with the
//         requested permissions. For example, all permissions to access file storage volume
//         directories are logically associated with the relevant FileStorageVolumes catalog 
//         items, all permissions to access data exchange directories (or other resources
//         according to the used exchange transport) are logically associated with the relevant
//         exchange plan nodes and so on. If the permission is logically isolated (for example,
//         if the permission is managed by the value of a Boolean type constant) we recommend
//         that you use reference to the MetadataObjectIDs catalog item.
//
// Returns:
//  UUID - reference to the permission request recorded in the infobase. When all requests are
//  created, the changes must be applied using the SafeModeClient.ApplyExternalResourceRequests()
//  procedure.
//
Function RequestForClearingPermissionsForExternalResources(Val Owner) Export
	
	Return SafeModeInternal.ExternalResourcesPermissionChangeRequest(
		Owner,
		True);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Supporting security profiles in a configuration where connecting external modules with the 
// disabled safe mode is not allowed.
//

// Checks whether the safe mode is enabled ignoring the security profile safe mode that is used 
// as a security profile with the configuration privilege level.
//
// Returns
//  Boolean.
//
Function SafeModeSet() Export
	
	CurrentSafeMode = SafeMode();
	
	If TypeOf(CurrentSafeMode) = Type("String") Then
		
		If Not SwichingToPrivilegedModeAvailable() Then
			Return True; // If the safe mode is not set, switching to the privilege mode is always available
		EndIf;
		
		Try
			ConfigurationProfile = ProfileWithConfigurationPrivileges();
		Except
			Return True;
		EndTry;
		
		Return (CurrentSafeMode <> ConfigurationProfile);
		
	ElsIf TypeOf(CurrentSafeMode) = Type("Boolean") Then
		
		Return CurrentSafeMode;
		
	EndIf;
	
EndFunction

// Evaluates the passed expression, setting the safe mode of script execution and the safe mode
// of data separation for all separators of the configuration.
// As the result, when the expressions are being calculated:
//  - attempts to set the privileged mode are ignored;
//  - all external (relative to the 1C:Enterprise platform) actions (COM, external component
//    loading, external application startup, operating system command execution, file system
//    and Internet resource access) are prohibited;
//  - session separators cannot be disabled;
//  - session separator values cannot be changed (if data separation is not disabled
//    conditionally);
//  - objects that manage the conditional separation state cannot be changed.
//
// Parameters:
//  Expression - String - expression to be evaluated.
//  Parameters - Arbitrary - one can pass parameters required for expression evaluation.
//
// Returns:
//  Arbitrary - result of the expression evaluation.
//
Function EvaluateInSafeMode(Val Expression, Val Parameters = Undefined) Export
	
	SetSafeMode(True);
	
	SeparatorArray = SafeModeInternalCached.SeparatorArray();
	
	For Each SeparatorName In SeparatorArray Do
		
		SetDataSeparationSafeMode(SeparatorName, True);
		
	EndDo;
	
	Return Eval(Expression);
	
EndFunction

// Executes an arbitrary algorithm in the 1C:Enterprise script, setting the safe mode of script
// execution and the safe mode of data separation for all separators of the configuration.
// As the result, when the expressions are being calculated:
//  - attempts to set the privileged mode are ignored;
//  - all external (relative to the 1C:Enterprise platform) actions (COM, external component
//    loading, external application startup, operating system command execution, file system
//    and Internet resource access) are prohibited;
//  - session separators cannot be disabled;
//  - session separator values cannot be changed (if data separation is not disabled
//    conditionally);
//  - objects that manage the conditional separation state cannot be changed.
//
// Parameters:
//  Algorithm  - String - arbitrary algorithm in the 1C:Enterprise script to be executed.
//  Parameters - Arbitrary - one can pass parameters required for the algorithm execution.
//
Procedure ExecuteInSafeMode(Val Algorithm, Val Parameters = Undefined) Export
	
	SetSafeMode(True);
	
	SeparatorArray = SafeModeInternalCached.SeparatorArray();
	
	For Each SeparatorName In SeparatorArray Do
		
		SetDataSeparationSafeMode(SeparatorName, True);
		
	EndDo;
	
	Execute Algorithm;
	
EndProcedure

// Executes the export procedure by the name with the configuration privilege level.
// To enable the security profile for calling the Execute() operator, the safe mode with the
// security profile of the configuration is used (if no other safe mode was set in stack
// previously).
// 
// Parameters:
//  ExportProcedureName - String - name of the export procedure in the following format: 
//                        <object name>.<procedure name>, where <object name> is a common or
//                        object manager module.
// Parameters           - Array - parameters are passed to the <ExportProcedureName> procedure 
//                        in the order of elements in the array.
// 
// Example:
//  Parameters = New Array();
//  Parameters.Add("1");
//  SafeMode.ExecuteConfigurationMethod("MyCommonModule.MyProcedure", Parameters);
//
Procedure ExecuteConfigurationMethod(Val ExportProcedureName, Val Parameters = Undefined) Export
	
	ValidateConfigurationMethodName(ExportProcedureName);
	
	If GetFunctionalOption("UseSecurityProfiles") And Not SafeModeSet() Then
		
		ConfigurationProfile = ProfileWithConfigurationPrivileges();
		
		If ValueIsFilled(ConfigurationProfile) Then
			
			SetSafeMode(ConfigurationProfile);
			If SafeMode() = True Then
				SetSafeMode(False);
			EndIf;
			
		EndIf;
		
	EndIf;
	
	ParametersString = "";
	If Parameters <> Undefined And Parameters.Count() > 0 Then
		For Index = 0 to Parameters.UBound() Do 
			ParametersString = ParametersString + "Parameters[" + Index + "],";
		EndDo;
		ParametersString = Mid(ParametersString, 1, StrLen(ParametersString) - 1);
	EndIf;
	
	Execute ExportProcedureName + "(" + ParametersString + ")";
	
EndProcedure

// Executes the export procedure of the data processor (included in the configuration) by the
// name with the configuration privilege level.
// To enable the security profile for calling the Execute() operator, the safe mode with the
// security profile of the configuration is used (if no other safe mode was set in stack
// previously).
// 
// Parameters:
//  DataProcessor - String - name of the export procedure in the following format: 
//                  <object name>.<procedure name>, where <object name> is a common or object
//                  manager module.
// Parameters     - Array - parameters are passed to the <ExportProcedureName> procedure in the
//                  order of elements in the array.
// 
// Example:
//  Parameters = New Array();
//  Parameters.Add("1");
//  SafeMode.ExecuteConfigurationMethod("MyCommonModule.MyProcedure", Parameters);
//
Procedure ExecuteObjectMethod(DataProcessor, Val ProcedureName, Val Parameters = Undefined) Export
	
	// Validating the method name
	Try
		Test = New Structure(ProcedureName, ProcedureName);
	Except
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='Incorrect value of the ProcedureName parameter: (%1)'"),
			ProcedureName);
	EndTry;
	
	If GetFunctionalOption("UseSecurityProfiles") And Not SafeModeSet() Then
		
		ConfigurationProfile = ProfileWithConfigurationPrivileges();
		
		If ValueIsFilled(ConfigurationProfile) Then
			
			SetSafeMode(ConfigurationProfile);
			If SafeMode() = True Then
				SetSafeMode(False);
			EndIf;
			
		EndIf;
		
	EndIf;
	
	ParametersString = "";
	If Parameters <> Undefined And Parameters.Count() > 0 Then
		For Index = 0 to Parameters.UBound() Do 
			ParametersString = ParametersString + "Parameters[" + Index + "],";
		EndDo;
		ParametersString = Mid(ParametersString, 1, StrLen(ParametersString) - 1);
	EndIf;
	
	Execute "DataProcessor." + ProcedureName + "(" + ParametersString + ")";
	
EndProcedure

// Checks whether the passed name is a name of an export procedure of the configuration.
// Can be used for checking whether the passed string does not content an arbitrary algorithm
// in the 1C:Enterprise script before one use this script in the Execute() and Eval()
// operators.
//
// If the passed string does not correspond to the configuration method name an exception is 
// raised.
//
Procedure ValidateConfigurationMethodName(Val ExportProcedureName) Export
	
	// Checking preconditions to the ExportProcedureName format.
	NameParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(ExportProcedureName, ".");
	If NameParts.Count() <> 2 And NameParts.Count() <> 3 Then
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='Incorrect ExportProcedureName parameter format: (%1)'"),
			ExportProcedureName);
	EndIf;
	
	ObjectName = NameParts[0];
	If NameParts.Count() = 2 And Metadata.CommonModules.Find(ObjectName) = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='Incorrect ExportProcedureName parameter format: (%1).
			         |The %2 common module is not found.'"),
			ExportProcedureName,
			ObjectName);
	EndIf;
	
	If NameParts.Count() = 3 Then
		ValidTypeNames = New Array;
		ValidTypeNames.Add(Upper(CommonUse.TypeNameConstants()));
		ValidTypeNames.Add(Upper(CommonUse.TypeNameInformationRegisters()));
		ValidTypeNames.Add(Upper(CommonUse.TypeNameAccumulationRegisters()));
		ValidTypeNames.Add(Upper(CommonUse.TypeNameAccountingRegisters()));
		ValidTypeNames.Add(Upper(CommonUse.TypeNameCalculationRegisters()));
		ValidTypeNames.Add(Upper(CommonUse.TypeNameCatalogs()));
		ValidTypeNames.Add(Upper(CommonUse.TypeNameDocuments()));
		ValidTypeNames.Add(Upper(CommonUse.TypeNameReports()));
		ValidTypeNames.Add(Upper(CommonUse.TypeNameDataProcessors()));
		ValidTypeNames.Add(Upper(CommonUse.TypeNameBusinessProcesses()));
		ValidTypeNames.Add(Upper(CommonUse.TypeNameDocumentJournals()));
		ValidTypeNames.Add(Upper(CommonUse.TypeNameTasks()));
		ValidTypeNames.Add(Upper(CommonUse.TypeNameChartsOfAccounts()));
		ValidTypeNames.Add(Upper(CommonUse.TypeNameExchangePlans()));
		ValidTypeNames.Add(Upper(CommonUse.TypeNameChartsOfCharacteristicTypes()));
		ValidTypeNames.Add(Upper(CommonUse.TypeNameChartsOfCalculationTypes()));
		TypeName = Upper(NameParts[0]);
		If ValidTypeNames.Find(TypeName) = Undefined Then
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en='Incorrect ExportProcedureName parameter format: (%1).
				         |The %2 metadata object collection is not found
				         |or execution in the safe mode is not supported for this collection.'"),
				ExportProcedureName,
				ObjectName);
		EndIf;
	EndIf;
	
	MethodName = NameParts[NameParts.UBound()];
	TempStructure = New Structure;
	Try
		// Checking whether the MethodName is a valid ID.
		// For example: MyProcedure.
		TempStructure.Insert(MethodName);
	Except
		WriteLogEvent(NStr("en = 'Executing method in safe mode'", CommonUseClientServer.DefaultLanguageCode()),
			EventLogLevel.Error, , , DetailErrorDescription(ErrorInfo()));
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='Incorrect ExportProcedureName parameter format: (%1).
			         |The %2 method name does not meet the requirements of variable naming.'"),
			ExportProcedureName,
			MethodName);
	EndTry;
	
EndProcedure

// Checks whether handlers that set session parameters can be executed.
// If the current settings of security profile (of the server cluster or of the infobase) deny
// the execution of the handlers that set session parameters, an exception is generated. The
// exception contains reasons why handler execution is denied and the list of actions required to
// solve this problem.
//
Procedure CanExecuteSessionParameterSettingHandlers() Export
	
	If CommonUse.FileInfobase(InfobaseConnectionString()) Then
		Return;
	EndIf;
	
	Try
		PrivilegedModeAvailable = Eval("SwichingToPrivilegedModeAvailable()");
	Except
		
		If GetFunctionalOption("UseSecurityProfiles") Then
			
			Profile = ProfileWithConfigurationPrivileges();
			SetSafeMode(Profile);
			If SafeMode() = True Then
				Raise StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en = 'Handlers that set session parameters cannot be executed by the following reason: the %1 security profile is not found.
                          |
                          |Perhaps it was deleted through the cluster console.
                          |In this case, disable security profile through the cluster console and
                          |enable it using the configuration interface. You can find the
                          |corresponded command in the application settings section.'"),
					Profile
				);
			EndIf;
			PrivilegedModeAvailable = Eval("SwichingToPrivilegedModeAvailable()");
			SetSafeMode(False);
			If Not PrivilegedModeAvailable Then
				NStr("en = 'Handlers that set session parameters cannot be executed by the following reason: the %1 security profile denies the privileged mode.
                      |
                      |Perhaps the profile was edited through the cluster console.
                      |In this case, disable security profile through the cluster console and
                      |enable it using the configuration interface. You can find the
                      |corresponded command in the application settings section.'",
					Profile
				);
			EndIf;
			
		Else
			
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Handlers that set session parameters cannot be executed by the following reason: %1.
                      |
                      |Perhaps a security profile that deny execution of the external modules 
                      |without safe mode was set for the infobase through the cluster console.
                      |In this case, disable security profile through the cluster console and
                      |enable it using the configuration interface. You can find the
                      |corresponded command in the application settings section. The application 
                      |will be correctly configured for using security profiles automatically.'"),
				BriefErrorDescription(ErrorInfo())
			);
			
		EndIf;
		
	EndTry;
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

// Checks whether the privilege mode can be set from the current safe mode.
//
// Returns:
//  Boolean.
//
Function SwichingToPrivilegedModeAvailable()
	
	SetPrivilegedMode(True);
	Return PrivilegedMode();
	
EndFunction

// Returns the name of the security profile that provides privileges for configuration script.
//
// Returns:
//  String - security profile name.
//
Function ProfileWithConfigurationPrivileges()
	
	SetPrivilegedMode(True);
	
	Return Constants.InfobaseSecurityProfile.Get();
	
EndFunction

// Returns the predefined alias of the application directory.
//
// Returns:
//  String.
//
Function ApplicationDirectoryAlias()
	
	Return "/bin";
	
EndFunction

// Returns the predefined alias of the temporary directory.
//
// Returns:
//  String.
//
Function TempDirectoryAlias()
	
	Return "/temp";
	
EndFunction

// Returns the standard ports of the Internet protocols that can be processed using the
// 1C:Enterprise script. Is used to determine the port if the applied script requests the
// permission but does not define the port.
//
// Returns:
//  FixedStructure where:
//   * Key   - String - Internet protocol name,
//   * Value - Number - port number.
//
Function StandardInternetProtocolPorts()
	
	Result = New Structure();
	
	Result.Insert("IMAP",  143);
	Result.Insert("POP3",  110);
	Result.Insert("SMTP",  25);
	Result.Insert("HTTP",  80);
	Result.Insert("HTTPS", 443);
	Result.Insert("FTP",   21);
	Result.Insert("FTPS",  21);
	
	Return New FixedStructure(Result);
	
EndFunction

#EndRegion
