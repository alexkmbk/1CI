////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
// Client procedures and functions of common use for working with:
// - Security profiles.
//
/////////////////////////////////////////////////////////////////////////////////
 
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection  Then

#Region InternalProceduresAndFunctions
 
////////////////////////////////////////////////////////////////////////////////
// Creating permission requests.
//

// Creates external resource permission change request.
// For internal use only.
//
// Parameters:
//  Owner               - AnyRef - owner of the external resource permissions.
//                      - Undefined - if requesting permission for the configuration but not 
//                        for configuration objects.
//  ReplacementMode     - Boolean - replacement mode for the previously granted permissions.
//  PermissionsToAdd    - Array of XDTODataObject - array of the XDTO data objects 
//                        corresponding to the external resource access permissions to be 
//                        requested. It is supposed that all passed XDTODataObjects are 
//                        generated with the SafeMode.Permission*() functions.
//  PermissionsToDelete - Array of XDTODataObject - array of the XDTO data objects
//                        corresponding to the external resource access permissions to be
//                        revoked. It is supposed that all passed XDTODataObjects are generated
//                        with the SafeMode.Permission*() functions.
//  ExternalModule      - AnyRef - reference corresponding to the external module for which
//                        permissions are requested. 
//                      - Undefined - if requesting permission for the configuration but not
//                        for configuration objects.
//
// Returns: UUID - created query ID.
//
Function ExternalResourcesPermissionChangeRequest(Val Owner,  Val ReplacementMode, Val PermissionsToAdd = Undefined, Val PermissionsToDelete = Undefined, Val ExternalModule = Undefined) Export
	
	If Not ExternalResourcePermissionRequestRequired() Then
		Return New UUID();
	EndIf;
	
	If Owner = Undefined Then
		Owner = Catalogs.MetadataObjectIDs.EmptyRef();
	EndIf;
	
	If ExternalModule = Undefined Then
		ExternalModule = Catalogs.MetadataObjectIDs.EmptyRef();
	EndIf;
	
	If SafeMode.SafeModeSet() Then
		SafeMode = SafeMode();
	Else
		SafeMode = False;
	EndIf;
	
	Manager = InformationRegisters.RequestsForPermissionsToUseExternalResources.CreateRecordManager();
	Manager.RequestID = New UUID();
	Manager.PointInTime = CurrentUniversalDate();
	Manager.SafeMode = SafeMode;
	Manager.ReplacementMode = ReplacementMode;
	Manager.Status =  Enums.ExternalResourceRequestStates.New;
	
	OwnerProperties = PropertiesForPermissionRegister(Owner);
	Manager.OwnerType = OwnerProperties.Type;
	Manager.OwnerID = OwnerProperties.ID;
	
	ModuleProperties = PropertiesForPermissionRegister(ExternalModule);
	Manager.ModuleType = ModuleProperties.Type;
	Manager.ModuleID = ModuleProperties.ID;
	
	If PermissionsToAdd <> Undefined Then
		
		PermissionArray = New Array();
		For Each  NewPermission In PermissionsToAdd Do
			PermissionArray.Add(CommonUse.XDTODataObjectIntoXMLString(NewPermission));
		EndDo;
		
		If PermissionArray.Count() > 0 Then
			Manager.PermissionsToAdd = CommonUse.ValueToXMLString(PermissionArray);
		EndIf;
		
	EndIf;
	
	If PermissionsToDelete <> Undefined Then
		
		PermissionArray = New Array();
		For Each  PermissionToRevoke In PermissionsToDelete Do
			PermissionArray.Add(CommonUse.XDTODataObjectIntoXMLString(PermissionToRevoke));
		EndDo;
		
		If PermissionArray.Count() > 0 Then
			Manager.PermissionsToDelete = CommonUse.ValueToXMLString(PermissionArray);
		EndIf;
		
	EndIf;
	
	Manager.Write();
	
	Return Manager.RequestID;
	
EndFunction
 
// Creates external resource permission administration request (creating / deleting security
// profiles, setting security profiles for the infobase, and so on).
//
// Parameters:
//  ExternalModule - AnyRef - reference corresponding to the external module for which 
//                   permissions are requested. 
//                   Undefined - if requesting permission for the configuration but not for
//                   external modules.
//  Operation      - EnumRef.OperationsWithPermissionSets - operation to be performed during
//                   the administering the permission request.
//
// Returns - UUID - created query ID.
//
Function ExternalResourcePermissionAdministrationRequest(Val ExternalModule, Val Operation) Export
	
	If Not ExternalResourcePermissionRequestRequired() Then
		Return New UUID();
	EndIf;
	
	If Operation = Enums.OperationsWithPermissionSets.Create Then
		SecurityProfileName = NewSecurityProfileName(ExternalModule);
	Else
		SecurityProfileName = SecurityProfileName(ExternalModule);
	EndIf;
	
	Manager = InformationRegisters.ExternalResourcePermissionAdministrationRequests.CreateRecordManager();
	Manager.RequestID = New UUID();
	Manager.Operation = Operation;
	Manager.PointInTime = CurrentUniversalDate();
	Manager.Status = Enums.ExternalResourceRequestStates.New;
	Manager.Name = SecurityProfileName;
	
	ModuleProperties = PropertiesForPermissionRegister(ExternalModule);
	Manager.ModuleType = ModuleProperties.Type;
	Manager.ModuleID = ModuleProperties.ID;
	
	Manager.Write();
	
	Return Manager.RequestID;
	
EndFunction
 
// Creates requests for disabling security profiles.
//
// Parameters:
//  IncludingInfobaseProfile - Boolean - if False, the procedure creates requests for deleting security profiles of external modules only.
//
// Returns: Array of UUID - IDs of the requests for disabling security profiles.
//
Function SecurityProfileDisablingRequests(Val IncludingInfobaseProfile = True)
	
	Result = New Array();
	
	BeginTransaction();
	
	Try
		
		If IncludingInfobaseProfile Then
			
			InfobaseProfileDeletionRequestID = SafeModeInternal.PermissionSetDeletingRequest(
				Catalogs.MetadataObjectIDs.EmptyRef());
			
			Result.Add(InfobaseProfileDeletionRequestID);
			
		EndIf;
		
		QueryText =
			"SELECT DISTINCT
			|	ExternalModuleAddingModes.ModuleType AS ModuleType,
			|	ExternalModuleAddingModes.ModuleID AS ModuleID
			|FROM
			|	InformationRegister.ExternalModuleAddingModes AS ExternalModuleAddingModes";
		Query = New Query(QueryText);
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			Result.Add(SafeModeInternal.PermissionSetDeletingRequest(
				ReferenceFormPermissionRegister(Selection.ModuleType, Selection.ModuleID)));
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
	Return Result;
	
EndFunction
 
// Creates "empty" replacement queries for all previously granted permissions.
//
// Returns: Array of UUID - IDs of queries for replacing all previously granted permissions.
//
Function ReplacementQueriesForAllGrantedPermissions()
	
	Result = New Array();
	
	RegisterManagers = PermissionRegisterManagers();
	
	RegisterTableQueryPattern = "SELECT DISTINCT PermissionTable.ModuleType AS ModuleType, PermissionTable.ModuleID AS ModuleID, PermissionTable.OwnerType AS OwnerType,  PermissionTable.OwnerID AS OwnerID FROM %1 AS PermissionTable";
	RegisterTableQueryText = "";
	
	For Each RegisterManager In RegisterManagers Do
		
		MetadataObject = RegisterManager.CreateRecordSet().Metadata();
		
		If Not  IsBlankString(RegisterTableQueryText) Then
			RegisterTableQueryText =  RegisterTableQueryText + " UNION ALL";
		EndIf;
		
		RegisterTableQueryText =  RegisterTableQueryText +  StringFunctionsClientServer.SubstituteParametersInString(
			RegisterTableQueryPattern,  MetadataObject.FullName());
		
	EndDo;
	
	QueryText = StringFunctionsClientServer.SubstituteParametersInString(
		"SELECT DISTINCT NestedQuery.ModuleType AS ModuleType, NestedQuery.ModuleID AS ModuleID, NestedQuery.OwnerType AS OwnerType, NestedQuery.OwnerID AS OwnerID FROM (%1) AS  NestedQuery",
		RegisterTableQueryText);
	
	Query = New Query(QueryText);
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		ProgramModule = ReferenceFormPermissionRegister(
			Selection.ModuleType,
			Selection.ModuleID);
		
		Owner = ReferenceFormPermissionRegister(
			Selection.OwnerType,
			Selection.OwnerID);
		
		ReplacementRequest = SafeModeInternal.ExternalResourcesPermissionChangeRequest(
			Owner, True, New Array(), , ProgramModule);
		
		Result.Add(ReplacementRequest);
		
	EndDo;
	
	Return Result;
	
EndFunction
 
// Checks whether the interactive request for external resource permissions is required.
//
// Returns: Boolean.
//
Function ExternalResourcePermissionRequestRequired()
	
	If Not CanRequestForExternalResourcePermissions()  Then
		Return False;
	EndIf;
	
	Return Constants.UseSecurityProfiles.Get() And Constants.AutomaticallySetUpPermissionsInSecurityProfiles.Get();
	
EndFunction
 
// Checks whether the external resource permissions can be requested interactively.
//
// Returns: Boolean.
//
Function CanRequestForExternalResourcePermissions()
	
	If CommonUse.FileInfobase(InfobaseConnectionString()) Or Not GetFunctionalOption("UseSecurityProfiles")  Then
		
		// In file mode or when security profiles are disabled, permission requests can be 
		// written if the privileged mode is on or by the administrator.
		Return PrivilegedMode() Or Users.InfobaseUserWithFullAccess();
		
	Else
		
		// In client/server mode, when security profiles are enabled, permission requests can be
		// written by administrator only and does not depend on whether the privileged mode is on or
		// not.
		If Not  Users.InfobaseUserWithFullAccess() Then
			
			Raise NStr("en = 'Insufficient access rights for requesting for external resource permissions.'");
			
		EndIf;
		
		Return True;
		
	EndIf; 
	
EndFunction
 
// Clears obsolete external resource requests.
//
Procedure ClearObsoleteExternalResourceRequests() Export
	
	QueryText =
		"SELECT
		|	Requests.RequestID AS RequestID,
		|	Requests.ModuleType AS ModuleType,
		|	Requests.ModuleID AS ModuleID,
		|	Requests.OwnerType AS OwnerType,
		|	Requests.OwnerID AS OwnerID,
		|	Requests.SafeMode AS SafeMode
		|In
		|	InformationRegister.RequestsForPermissionsToUseExternalResources AS Requests
		|Where
		|	Requests.PointInTime  <= &RequestDate";
	Query = New Query(QueryText);
	Query.SetParameter("RequestDate", CurrentUniversalDate() - 3600); // Request lifetime - 1 hour
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		BeginTransaction();
		
		Try
			
			Key = InformationRegisters.RequestsForPermissionsToUseExternalResources.CreateRecordKey(
				New Structure("RequestID, ModuleType, ModuleID, OwnerType, OwnerID, SafeMode",
				Selection.RequestID,
				Selection.ModuleType,
				Selection.ModuleID,
				Selection.OwnerType,
				Selection.OwnerID,
				Selection.SafeMode));
			LockDataForEdit(Key);
			
		Except
			
			// No exception processing required.
			// Expected exception is an attempt to delete the same register record from another
			// session.
			RollbackTransaction();
			Continue;
			
		EndTry;
		
		Set = InformationRegisters.RequestsForPermissionsToUseExternalResources.CreateRecordSet();
		Set.Filter.RequestID.Set(Selection.RequestID);
		Set.Write();
		
		CommitTransaction();
		
	EndDo;
	
	QueryText =
		"SELECT
		|	Requests.RequestID AS RequestID,
		|	Requests.ModuleType AS ModuleType,
		|	Requests.ModuleID AS  ModuleID
		|In
		|	InformationRegister.ExternalResourcePermissionAdministrationRequests  AS Requests
		|Where
		|	Requests.PointInTime  <= &RequestDate";
	Query = New Query(QueryText);
	Query.SetParameter("RequestDate", CurrentUniversalDate() - 3600); // Request lifetime - 1 hour
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		BeginTransaction();
		
		Try
			
			Key = InformationRegisters.ExternalResourcePermissionAdministrationRequests.CreateRecordKey(
				New Structure("RequestID, ModuleType, ModuleID",
				Selection.RequestID, Selection.ModuleType, Selection.ModuleID));
			LockDataForEdit(Key);
			
		Except
			
			// No exception processing required.
			// Expected exception is an attempt to delete the same register record from another
			// session.
			RollbackTransaction();
			Continue;
			
		EndTry;
		
		Set = InformationRegisters.ExternalResourcePermissionAdministrationRequests.CreateRecordSet();
		Set.Filter.RequestID.Set(Selection.RequestID);
		Set.Write();
		
		CommitTransaction();
		
	EndDo;
	
EndProcedure
 
////////////////////////////////////////////////////////////////////////////////
// Processing permission tables.
//

// Returns a structure that contains the external resource permission tables.
//
// Return value: Structure:
//                * Key   - String - name of the XDTO type that specifies the permission type,
//                 *Value - ValueTable - column structure matches the field set of the
//                          information register that is used for storing the list of granted
//                          permissions of the type (see PermissionRegisterManagers()).
//
Function PermissionTables() Export
	
	Result = New Structure();
	
	Managers = PermissionRegisterManagers();
	
	For Each Manager In Managers Do
		
		RegisterMetadata = Manager.CreateRecordSet().Metadata();
		Table = PermissionTable(RegisterMetadata);
		Result.Insert(Manager.PermissionPresentationXDTOType().Name, Table);
		
	EndDo;
	
	Return Result;
	
EndFunction
 
// Returns a table that fits for storing the list of the granted permissions of the type.
//
// Parameters:
//  RegisterMetadata - InformationRegister metadata object - metadata object that corresponds
//                     with the information register used for storing the list of granted 
//                     permissions of the type (see PermissionRegisterManagers()).
//  IndexDimensions  - Boolean - flag that shows whether the table columns corresponding with
//                     the register dimensions must be indexed.
//
// Returns: ValueTable whose column structure corresponds with the field structure of the
//          information register used for storing the list of granted permissions of the type.
//
Function PermissionTable(Val RegisterMetadata, Val IndexDimensions = False)  Export
	
	Table = New ValueTable();
	IndexFields = New Array();
	
	For Each Dimension In RegisterMetadata.Dimensions  Do
		Table.Columns.Add(Dimension.Name, Dimension.Type);
		If IndexDimensions Then
			IndexFields.Add(Dimension.Name);
		EndIf;
	EndDo;
	
	For Each Resource In RegisterMetadata.Resources Do
		Table.Columns.Add(Resource.Name, Resource.Type);
	EndDo;
	
	For Each Attribute  In RegisterMetadata.Attributes  Do
		Table.Columns.Add(Attribute.Name, Attribute.Type);
	EndDo;
	
	If IndexFields.Count() > 0 Then
		Table.Indexes.Add(StringFunctionsClientServer.StringFromSubstringArray(IndexFields, ","));
	EndIf;
	
	Return Table;
	
EndFunction
 
// Returns the number of permissions in the permission tables.
//
// Parameters:
//  Tables - Structure - permission tables to be analyzed (see. PermissionTables()).
//
// Returns: Number - number of permissions in the tables.
//
Function PermissionsInTablesCount(Val Tables)  Export
	
	Result = 0;
	
	For Each KeyAndValue In Tables Do
		Result = Result + KeyAndValue.Value.Count();
	EndDo;
	
	Return Result;
	
EndFunction
 
////////////////////////////////////////////////////////////////////////////////
// Processing registers that store permissions.
//

// Return an array of managers of the information registers used for storing the list of the 
// granted permissions.
//
// Returns: Array of InformationRegisterManager.
//
Function PermissionRegisterManagers() Export
	
	Result = New  Array();
	
	Result.Add(InformationRegisters.AllowedFileSystemDirectories);
	Result.Add(InformationRegisters.AllowedCOMClasses);
	Result.Add(InformationRegisters.AllowedAddIns);
	Result.Add(InformationRegisters.AllowedOperatingSystemApplications);
	Result.Add(InformationRegisters.AllowedInternetResources);
	Result.Add(InformationRegisters.PermissionsForSwichingToPrivilegedMode);
	
	Return Result;
	
EndFunction
 
// Set the exclusive managed lock for all the tables of registers used for storing the list of
// the granted permissions.
//
// Parameters:
//  ExternalModule               - AnyRef - reference to the catalog item that corresponds to 
//                                 the external module whose details on the previously granted
//                                 permissions must be locked. If the parameter value is not
//                                 set, the data on granted permissions for all external 
//                                 modules is locked.
// LockExternalModuleAddingModes - Boolean - flag that shows whether additional lock of
//                                 external module adding modes is required.
//
Procedure  LockRegistersOfGrantedPermissions(Val ExternalModule = Undefined, Val LockExternalModuleAddingModes = True)
	
	If Not TransactionActive() Then
		Raise NStr("en = 'Transaction is not active.'");
	EndIf;
	
	Lock = New DataLock();
	
	Registers = PermissionRegisterManagers();
	
	If  LockExternalModuleAddingModes Then
		Registers.Add(InformationRegisters.ExternalModuleAddingModes);
	EndIf;
	
	For Each Register In Registers Do
		RegisterLock = Lock.Add(Register.CreateRecordSet().Metadata().FullName());
		If ExternalModule <> Undefined Then
			ModuleProperties = PropertiesForPermissionRegister(ExternalModule);
			RegisterLock.SetValue("ModuleType", ModuleProperties.Type);
			RegisterLock.SetValue("ModuleID", ModuleProperties.ID);
		EndIf;
	EndDo;
	
	Lock.Lock();
	
EndProcedure
 
// Clears information registers used for storing the list of the granted permissions.
//
// Parameters:
//  ExternalModule                - AnyRef - reference to the catalog item that corresponds to
//                                  the external module whose details on the previously granted
//                                  permissions must be cleared. If the parameter value is not 
//                                  set, the data on granted permissions for all external
//                                  modules is cleared.
// ClearExternalModuleAddingModes - Boolean - flag that shows whether additional clearing of
//                                  external module adding modes is required.
//
Procedure ClearPermissions(Val ExternalModule = Undefined, Val ClearExternalModuleAddingModes = True) Export
	
	BeginTransaction();
	
	Try
		
		LockRegistersOfGrantedPermissions(ExternalModule, ClearExternalModuleAddingModes);
		
		Managers = PermissionRegisterManagers();
		
		If ClearExternalModuleAddingModes Then
			Managers.Add(InformationRegisters.ExternalModuleAddingModes);
		EndIf;
		
		For Each Manager In Managers Do
			Set = Manager.CreateRecordSet();
			If ExternalModule <> Undefined Then
				ModuleProperties = PropertiesForPermissionRegister(ExternalModule);
				Set.Filter.ModuleType.Set(ModuleProperties.Type);
				Set.Filter.ModuleID.Set(ModuleProperties.ID);
			EndIf;
			Set.Write(True);
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure
  
// Returns the current slice of the granted external resource permissions.
//
// Returns: Structure - see PermissionTables().
//
Function CurrentPermissionSlice()
	
	Result = PermissionTables();
	
	Managers = PermissionRegisterManagers();
	For Each Manager In Managers Do
		
		CurrentSliceQuery = New Query(Manager.CurrentSliceQuery(False));
		Result[Manager.PermissionPresentationXDTOType().Name] = CurrentSliceQuery.Execute().Unload();
		
	EndDo;
	
	Return Result;
	
EndFunction
 
////////////////////////////////////////////////////////////////////////////////
// Applying permission requests.
//

// Calculates changes in external resources permissions to be added to the security profile
// settings when processing requests for external resources.
//
// Parameters:
//  RequestIDs - Array of UUID - IDs of external resource requests that require to get changes 
//               to be added to security profile settings when the permissions are applied.
//
// Returns: ValueTable with the following fields:
//           * ExternalModule - AnyRef - reference to the catalog item that corresponds to the
//                              external module for which the external resource permissions are
//                              requested.
//           * Changes        - Structure with the following fields:
//                               * ToAdd    - Structure - contains tables with details on the
//                                            permissions to be added to the security profile
//                                            settings in the server cluster when applying the
//                                            requests (see PermissionTables()).
//                               * ToDelete - Structure - contains tables with details on the
//                                            permissions to be revoked from the security
//                                            profile settings in the server cluster when 
//                                            applying the requests (see PermissionTables()).
//                               * Priority - Number - priority of the current external module
//                                            (for displaying the calculated delta in the user
//                                            interface).
//
Function ExternalResourcePermissionChangeDelta(Val RequestIDs) Export
	
	RegisterManagers = PermissionRegisterManagers();
	DeltaCalculationMap = New Map();
	
	BeginTransaction();
	
	Try
		
		LockRegistersOfGrantedPermissions();
		
		FirstTTNames  = "TT_Before";
		SecondTTNames = "TT_After";
		AliasesOfTablesToPut = "Table";
		
		CurrentSlice = CurrentPermissionSlice();
		For Each RegisterManager In RegisterManagers Do
			
			TableName = RegisterManager.PermissionPresentationXDTOType().Name;
			CurrentSliceByTable = CurrentSlice[TableName];
			
			TTManager = New TempTablesManager();
			
			TTCreationQuery = New Query(TTCreationQueryText(CurrentSliceByTable,  AliasesOfTablesToPut, FirstTTNames));
			TTCreationQuery.SetParameter(AliasesOfTablesToPut, CurrentSliceByTable);
			TTCreationQuery.TempTablesManager = TTManager;
			TTCreationQuery.Execute();
			
			DeltaCalculationMap.Insert(RegisterManager, TTManager);
			
		EndDo;
		
		ApplyPermissionTableRequests(RequestIDs, CurrentSlice);
		
		ToAdd    = PermissionTables();
		ToDelete = PermissionTables();
		
		For Each DeltaCalculationMapItem In DeltaCalculationMap Do
			
			RegisterManager =  DeltaCalculationMapItem.Key;
			TableName = RegisterManager.PermissionPresentationXDTOType().Name;
			TTManager = DeltaCalculationMapItem.Value;
			
			CurrentSliceByTable = CurrentSlice[TableName];
			
			TTCreationQuery = New Query(TTCreationQueryText(CurrentSliceByTable,  AliasesOfTablesToPut, SecondTTNames));
			TTCreationQuery.SetParameter(AliasesOfTablesToPut, CurrentSliceByTable);
			TTCreationQuery.TempTablesManager = TTManager;
			TTCreationQuery.Execute();
			
			Query = New Query(RegisterManager.DeltaGettingQuery());
			Query.TempTablesManager = TTManager;
			
			Results = Query.ExecuteBatch();
			
			Portion = ToDelete[TableName];
			If Portion = Undefined Then
				ToDelete.Insert(TableName, Results[0].Unload());
			Else
				CommonUseClientServer.SupplementTable(Results[0].Unload(), Portion);
				ToDelete.Insert(TableName, Portion);
			EndIf;
			
			Portion = ToAdd[TableName];
			If Portion = Undefined Then
				ToAdd.Insert(TableName, Results[1].Unload());
			Else
				CommonUseClientServer.SupplementTable(Results[1].Unload(), Portion);
				ToAdd.Insert(TableName, Portion);
			EndIf;
			
		EndDo;
		
		Result = New  ValueTable();
		Result.Columns.Add("ExternalModule");
		Result.Columns.Add("Changes", New TypeDescription("Structure"));
		
		For Each KeyAndValue In ToAdd Do
			
			TableName = KeyAndValue.Key;
			Table = KeyAndValue.Value;
			
			For Each Row In Table Do
				
				ExternalModule = ReferenceFormPermissionRegister(
					Row.ModuleType, Row.ModuleID);
				
				FilterByModule = New Structure("ExternalModule", ExternalModule);
				RowsByModule = Result.FindRows(FilterByModule);
				If RowsByModule.Count() = 0 Then
					RowByModule = Result.Add();
					RowByModule.ExternalModule = ExternalModule;
					ResultByModule = New Structure("ToAdd, ToDelete", PermissionTables(), PermissionTables());
				ElsIf RowsByModule.Count() = 1 Then
					RowByModule = RowsByModule.Get(0);
					ResultByModule = RowByModule.Changes;
				Else
					Raise NStr("en = 'Ambiguity occurred when changing permissions'");
				EndIf;
				
				ResultTable = ResultByModule.ToAdd[TableName];
				ResultTableRow = ResultTable.Add();
				FillPropertyValues(ResultTableRow, Row);
				
				ResultByModule.ToAdd.Insert(TableName, ResultTable);
				
				RowByModule.Changes = ResultByModule;
				
			EndDo;
			
		EndDo;
		
		For Each KeyAndValue In ToDelete Do
			
			TableName = KeyAndValue.Key;
			Table = KeyAndValue.Value;
			
			For Each Row In Table Do
				
				ExternalModule = ReferenceFormPermissionRegister(
					Row.ModuleType, Row.ModuleID);
				
				FilterByModule = New Structure("ExternalModule", ExternalModule);
				RowsByModule = Result.FindRows(FilterByModule);
				If RowsByModule.Count() = 0 Then
					RowByModule = Result.Add();
					RowByModule.ExternalModule = ExternalModule;
					ResultByModule = New Structure("ToAdd, ToDelete", PermissionTables(), PermissionTables());
				ElsIf RowsByModule.Count() = 1 Then
					RowByModule = RowsByModule.Get(0);
					ResultByModule = RowByModule.Changes;
				Else
					Raise NStr("en = 'Ambiguity occurred when changing permissions'");
				EndIf;
				
				ResultTable = ResultByModule.ToDelete[TableName];
				ResultTableRow =  ResultTable.Add();
				FillPropertyValues(ResultTableRow, Row);
				
				ResultByModule.ToDelete.Insert(TableName, ResultTable);
				
				RowByModule.Changes = ResultByModule;
				
			EndDo;
			
		EndDo;
		
		Result.Columns.Add("Priority", New TypeDescription("Number"));
		For Each ResultRow In Result Do
			If ResultRow.ExternalModule = Catalogs.MetadataObjectIDs.EmptyRef() Then
				ResultRow.Priority = 1;
			Else
				ResultRow.Priority = 2;
			EndIf;
		EndDo;
		Result.Sort("Priority");
		
		CommitTransaction();
		
		Return Result;
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndFunction
 
// Generates a query text used for creating the temporary table for calculating the delta.

//
// Parameters:
//  CurrentTable - ValueTable - see PermissionTable().
//  TableAlias   - String - alias of the temporary table to be used in the query text.
//  TTName       - String - name of the temporary table to be used in the query text.
//
// Returns: String - query text.
//
Function TTCreationQueryText(Val CurrentTable, Val TableAlias, Val TTName)
	
	SelectionFields = New Array();
	
	For Each Column In CurrentTable.Columns Do
		SelectionFields.Add(Column.Name);
	EndDo;
	
	SelectionText = "";
	For Each SelectionField In SelectionFields Do
		
		If Not IsBlankString(SelectionText) Then
			SelectionText = SelectionText + ",";
		EndIf;
		
		SelectionText = SelectionText + TableAlias + "." +  SelectionField + " AS" + SelectionField;
		
	EndDo;
	
	QueryText = "SELECT %1 INTO %2 FROM &%3 AS %3";
	QueryText = StringFunctionsClientServer.SubstituteParametersInString(
		QueryText, SelectionText, TTName, TableAlias);
	
	Return QueryText;
	
EndFunction

// Creates an external resource request applying plan.
//
// Parameters:
//  RequestIDs - Array of UUID - IDs of external resource requests that require to get changes
//               to be added to security profile settings when the permissions are applied.
//
// Returns: Structure with the following fields:
//           * ToReplaceByType - ValueTable - replacement plan for the previously granted
//                               permissions:
//                                * ExternalModule - AnyRef - reference to the catalog item
//                                                   used as external module.
//                                * Owner          - AnyRef - reference to the catalog item 
//                                                   used as an owner of the permissions.
//                                * Type           - String - name of XDTO type that describes 
//                                                   the permission type. The type must be 
//                                                   defined in the
//                                                   {http://www.1c.ru/1cFresh/Application/Permissions/a.b.c.d}
//                                                   package.
//           * ToAddByTypes    - ValueTable - external resource permission adding plan:
//                               * ExternalModule - AnyRef - reference to the catalog item
//                                                  used as external module.
//                               * Owner          - AnyRef - reference to the catalog item 
//                                                  used as an owner of the permissions.
//                               * Type           - String - name of XDTO type that describes 
//                                                  the permission type. The type must be
//                                                  defined in the
//                                                  {http://www.1c.ru/1cFresh/Application/Permissions/a.b.c.d}
//                                                  package.
//                               * Permissions    - Array of XDTODataObject -  array of XDTO
//                                                  data objects that describe the external
//                                                  resource permissions. The types of objects
//                                                  must be defined in the 
//                                                  {http://www.1c.ru/1cFresh/Application/Permissions/a.b.c.d}
//                                                  package.
//           * ToDeleteByTypes - ValueTable - external resource permission deletion plan:
//                                * ExternalModule - AnyRef - reference to the catalog item
//                                                   used as external module.
//                                * Owner          - AnyRef - reference to the catalog item
//                                                   used as an owner of the permissions.
//                                * Type           - String - name of XDTO type that describes 
//                                                   the permission type. The type must be
//                                                   defined in the
//                                                   {http://www.1c.ru/1cFresh/Application/Permissions/a.b.c.d}
//                                                   package.
//                                * Permissions    - Array of XDTODataObject - array of XDTO
//                                                   data objects that describe the external
//                                                   resource permissions. The types of objects
//                                                   must be defined in the
//                                                   {http://www.1c.ru/1cFresh/Application/Permissions/a.b.c.d}
//                                                   package.
//
Function  ExternalResourceRequestApplyingPlan(Val RequestIDs)
	
	Managers = PermissionRegisterManagers();
	
	ToReplaceByType = New ValueTable();
	ToReplaceByType.Columns.Add("ExternalModule");
	ToReplaceByType.Columns.Add("Owner");
	ToReplaceByType.Columns.Add("Type", New TypeDescription("String"));
	
	ToAddByTypes = New ValueTable();
	ToAddByTypes.Columns.Add("ExternalModule");
	ToAddByTypes.Columns.Add("Owner");
	ToAddByTypes.Columns.Add("Type", New TypeDescription("String"));
	ToAddByTypes.Columns.Add("Permissions", New TypeDescription("Array"));
	
	ToDeleteByTypes = New  ValueTable();
	ToDeleteByTypes.Columns.Add("ExternalModule");
	ToDeleteByTypes.Columns.Add("Owner",);
	ToDeleteByTypes.Columns.Add("Type", New TypeDescription("String"));
	ToDeleteByTypes.Columns.Add("Permissions", New TypeDescription("Array")); 
	
	QueryText =
		"SELECT
		|	Queries.RequestID,
		|	Queries.ModuleType,
		|	Queries.ModuleID,
		|	Queries.OwnerType,
		|	Queries.OwnerID,
		|	Queries.ReplacementMode,
		|	Queries.PermissionsToAdd,
		|	Queries.PermissionsToDelete,
		|	Queries.PointInTime
		|In
		|	InformationRegister.RequestsForPermissionsToUseExternalResources AS  Queries
		|Where
		|	Queries.RequestID In(&IDs)";
	Query = New  Query(QueryText);
	Query.SetParameter("IDs", RequestIDs);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		If Selection.ReplacementMode Then
			
			// Replacing in all tables
			
			For Each Manager In Managers Do
				
				TableType = Manager.PermissionPresentationXDTOType().Name;
				
				ReplacementRow = ToReplaceByType.Add();
				ReplacementRow.ExternalModule = ReferenceFormPermissionRegister(
					Selection.ModuleType, Selection.ModuleID);
				ReplacementRow.Owner = ReferenceFormPermissionRegister(
					Selection.OwnerType, Selection.OwnerID);
				ReplacementRow.Type = TableType;
				
			EndDo;
			
		EndIf;
		
		If Not IsBlankString(Selection.PermissionsToAdd) Then
			
			PermissionToAddArray = CommonUse.ValueFromXMLString(Selection.PermissionsToAdd);
			For Each  PermissionPresentation In PermissionToAddArray Do
				
				Permission = CommonUse.XDTODataObjectFromXMLString(PermissionPresentation);
				
				ProgramModule = ReferenceFormPermissionRegister(
					Selection.ModuleType, Selection.ModuleID);
				Owner = ReferenceFormPermissionRegister(Selection.OwnerType, Selection.OwnerID);
				
				PermissionType = Permission.Type().Name;
				Filter = New  Structure("ExternalModule,Owner,Type", ProgramModule, Owner, PermissionType);
				Rows = ToAddByTypes.FindRows(Filter);
				If Rows.Count() = 0 Then
					Row = ToAddByTypes.Add();
					Row.ExternalModule = ProgramModule;
					Row.Owner =  Owner;
					Row.Type = PermissionType;
				Else
					Row = Rows.Get(0);
				EndIf;
				
				Row.Permissions.Add(Permission);
				
			EndDo;
			
		EndIf;
		
		If Not IsBlankString(Selection.PermissionsToDelete) Then
			
			PermissionsToDeleteArray = CommonUse.ValueFromXMLString(Selection.PermissionsToDelete);
			For Each  PermissionPresentation In PermissionsToDeleteArray Do
				
				Permission = CommonUse.XDTODataObjectFromXMLString(PermissionPresentation);
				
				ProgramModule = ReferenceFormPermissionRegister(
					Selection.ModuleType, Selection.ModuleID);
				Owner = ReferenceFormPermissionRegister(Selection.OwnerType, Selection.OwnerID);
				
				PermissionType = Permission.Type().Name;
				Filter = New Structure("ExternalModule,Owner,Type", ProgramModule, Owner, PermissionType);
				Rows = ToDeleteByTypes.FindRows(Filter);
				If Rows.Count() = 0 Then
					Row = ToAddByTypes.Add();
					Row.ExternalModule = ProgramModule;
					Row.Owner = Owner;
					Row.Type = PermissionType;
				Else
					Row = Rows.Get(0);
				EndIf;
				
				Row.Permissions.Add(Permission);
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	Result = New Structure();
	Result.Insert("ToReplaceByType", ToReplaceByType);
	Result.Insert("ToAddByTypes", ToAddByTypes);
	Result.Insert("ToDeleteByTypes" ,ToDeleteByTypes);
	
	Return Result;
	
EndFunction
 
// Applies external resource requests to permission tables.
//
// Parameters:
//  RequestIDs      - Array of UUID - IDs of external resource permission requests whose
//                    changes must be retrieved to be added to security profile settings.
// PermissionTables - Structure - describes external resource permissions (see
//                    PermissionTables()).
//
Procedure ApplyPermissionTableRequests(Val RequestIDs,  PermissionTables)
	
	Managers = PermissionRegisterManagers();
	
	Plan = ExternalResourceRequestApplyingPlan(RequestIDs);
	
	For Each ToReplaceByType In Plan.ToReplaceByType Do
		
		TypeName = ToReplaceByType.Type;
		Table = PermissionTables[TypeName];
		
		FilterParameters = New Structure();
		
		ModuleProperties =  PropertiesForPermissionRegister(ToReplaceByType.ExternalModule);
		FilterParameters.Insert("ModuleType", ModuleProperties.Type);
		FilterParameters.Insert("ModuleID",   ModuleProperties.ID);
		
		OwnerProperties =  PropertiesForPermissionRegister(ToReplaceByType.Owner);
		FilterParameters.Insert("OwnerType", OwnerProperties.Type);
		FilterParameters.Insert("OwnerID",   OwnerProperties.ID);
		
		Rows = Table.FindRows(FilterParameters);
		For Each Row In Rows Do
			Table.Delete(Row);
		EndDo;
		
	EndDo;
	
	For Each ToAddByType In Plan.ToAddByTypes Do
		
		TypeName = ToAddByType.Type;
		Table = PermissionTables[TypeName];
		
		CurrentManager = Undefined;
		For Each Manager In Managers Do
			If Manager.PermissionPresentationXDTOType().Name = TypeName Then
				CurrentManager = Manager;
			EndIf;
		EndDo;
		If CurrentManager = Undefined Then
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'An error occurred during parsing the external resource permission request: %1 is an unknown name type.'"),
				TypeName);
		EndIf;
		
		RecordSet = CurrentManager.RecordSetFromPresentationXDTO(ToAddByType.Permissions, ToAddByType.ExternalModule, ToAddByType.Owner, False);
		
		For Each Write In RecordSet Do
			Row = Table.Add();
			FillPropertyValues(Row, Write);
		EndDo;
		
	EndDo;
	
	For Each ToDeleteByType In Plan.ToDeleteByTypes Do
		
		TypeName = ToDeleteByType.Type;
		Table = PermissionTables[TypeName];
		
		CurrentManager = Undefined;
		For Each Manager  In Managers Do
			If Manager.PermissionPresentationXDTOType().Name = TypeName Then
				CurrentManager = Manager;
			EndIf;
		EndDo;
		If CurrentManager = Undefined Then
			Raise  StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'An error occurred during parsing the external resource permission request: %1 is an unknown name type.'"),
				TypeName);
		EndIf;
		
		RecordSet = CurrentManager.RecordSetFromPresentationXDTO(ToDeleteByType.Permissions, ToDeleteByType.ExternalModule, ToDeleteByType.Owner, True);
		
		FilterParameters = New Structure();
		For Each  FilterItem In RecordSet.Filter Do
			If FilterItem.Use Then
				If Table.Columns.Find(FilterItem.DataPath) <> Undefined Then
					If FilterItem.ComparisonType = ComparisonType.Equal Then
						FilterParameters.Insert(FilterItem.DataPath, FilterItem.Value);
					Else
						Raise NStr("en = 'Incorrect comparison type.'");
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		
		Rows = Table.FindRows(FilterParameters);
		For Each Row In Rows Do
			Table.Delete(Row);
		EndDo;
		
	EndDo;
	
EndProcedure
 
// Applies external resource requests to permission registers.
//
// Parameters:
//  RequestIDs - Array of UUID - IDs of external resource requests that require to get changes
//               to be added to security profile settings when the permissions are applied.
//
Procedure  ApplyRequestsToPermissionRegisters(Val RequestIDs)
	
	BeginTransaction();
	
	Try
		
		Managers = PermissionRegisterManagers();
		
		Plan = ExternalResourceRequestApplyingPlan(RequestIDs);
		
		For Each ToReplaceByType In Plan.ToReplaceByType Do
			
			TypeName = ToReplaceByType.Type;
			CurrentManager = Undefined;
			For Each Manager In Managers Do
				If Manager.PermissionPresentationXDTOType().Name = TypeName Then
					CurrentManager = Manager;
				EndIf;
			EndDo;
			If CurrentManager =  Undefined Then
				Raise StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en = 'An error occurred during parsing the external resource permission request: %1 is an unknown name type.'"),
					TypeName);
			EndIf;
			
			Module = ToReplaceByType.ExternalModule;
			Owner = ToReplaceByType.Owner;
			
			RecordSet = CurrentManager.RecordSetFromPresentationXDTO(Undefined, Module, Owner, True);
			RecordSet.Write(True);
			
		EndDo;
		
		For Each ToAddByType In Plan.ToAddByTypes Do
			
			TypeName = ToAddByType.Type;
			CurrentManager = Undefined;
			For Each Manager  In Managers Do
				If Manager.PermissionPresentationXDTOType().Name  = TypeName Then
					CurrentManager = Manager;
				EndIf;
			EndDo;
			If CurrentManager =  Undefined Then
				Raise  StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en = 'An error occurred during parsing the external resource permission request: %1 is an unknown name type.'"),
					TypeName);
			EndIf;
			
			Module = ToAddByType.ExternalModule;
			Owner = ToAddByType.Owner;
			
			RecordSet = CurrentManager.RecordSetFromPresentationXDTO(ToAddByType.Permissions, Module, Owner, False);
			RecordSet.Write(False);
			
		EndDo;
		
		For Each ToDeleteByType In Plan.ToDeleteByTypes Do
			
			TypeName = ToDeleteByType.Type;
			CurrentManager = Undefined;
			For Each Manager  In Managers Do
				If Manager.PermissionPresentationXDTOType().Name  = TypeName Then
					CurrentManager = Manager;
				EndIf;
			EndDo;
			If CurrentManager = Undefined Then
				Raise  StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en = 'An error occurred during parsing the external resource permission request: %1 is an unknown name type.'"),
					TypeName);
			EndIf;
			
			Module = ToDeleteByType.ExternalModule;
			Owner = ToDeleteByType.Owner;
			
			RecordSet = CurrentManager.RecordSetFromPresentationXDTO(ToDeleteByType.Permissions, Module, Owner, True);
			RecordSet.Write(True);
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure
 
// Applies external resource requests. Is called when the security profile settings in the
// server cluster have been changed.
//
// Parameters:
//  RequestIDs - Array of UUID - IDs of the requests to be applied.
//
Procedure ApplyRequests(Val RequestIDs) Export
	
	If ExclusiveMode()  Then
		
		ClearObsoleteExternalResourceRequests();
		
	Else
		
		Try
			
			JobParameters = New Array();
			JobParameters.Add("DataProcessors.ExternalResourcePermissionSetup.ClearObsoleteExternalResourceRequests");
			
			BackgroundJobs.Execute("SafeMode.ExecuteConfigurationMethod",  JobParameters,"f023cc5d-1846-4c49-b0ba-27aa65924879");
			
		Except
			// No exception processing required.
			// Expected exception is several jobs with the same key.
		EndTry;
		
	EndIf;
	
	BeginTransaction();
	
	Try
		
		LockRegistersOfGrantedPermissions();
		ApplyRequestsToPermissionRegisters(RequestIDs);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure
 
// Performs additional actions after applying external resource requests.
//
// Parameters:
//  RequestIDs - Array of UUID - IDs of the requests to be applied.
//
Procedure RequestsAfterProcess(Val RequestIDs) Export
	
	BeginTransaction();
	
	Try
		
		QueryText =
			"SELECT
			|	Requests.RequestID AS RequestID,
			|	Requests.ModuleType AS ModuleType,
			|	Requests.ModuleID AS ModuleID,
			|	Requests.Operation,
			|	Requests.Name
			|In
			|	InformationRegister.ExternalResourcePermissionAdministrationRequests AS Requests
			|Where
			|	Requests.RequestID In(&IDs)";
		Query = New Query(QueryText);
		Query.SetParameter("IDs", RequestIDs);
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			
			ProgramModule = ReferenceFormPermissionRegister(
				Selection.ModuleType, Selection.ModuleID);
			
			IsConfigurationProfile = (ProgramModule = Catalogs.MetadataObjectIDs.EmptyRef());
			
			If Selection.Operation = Enums.OperationsWithPermissionSets.Create Then
				
				If IsConfigurationProfile Then
					
					Constants.InfobaseSecurityProfile.Set(Selection.Name);
					
				Else
					
					Set = InformationRegisters.ExternalModuleAddingModes.CreateRecordSet();
					Set.Filter.ModuleType.Set(Selection.ModuleType);
					Set.Filter.ModuleID.Set(Selection.ModuleID);
					Write = Set.Add();
					Write.ModuleType = Selection.ModuleType;
					Write.ModuleID  = Selection.ModuleID;
					Write.SafeMode = Selection.Name;
					Set.Write();
					
				EndIf;
				
			Else
				
				If IsConfigurationProfile Then
					
					Constants.InfobaseSecurityProfile.Set("");
					ClearPermissions();
					
				Else
					
					ClearPermissions(ProgramModule, True);
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure
 
// Generates the external resource request applying result.
//
// Parameters:
//  RequestIDs - Array of UUID - IDs of the requests to be applied.
//
// Returns: Map, where:
//           * Key   - AnyRef - reference to the catalog item that corresponds to the external
//                     module.
//           * Value - Structure - permission tables as they must be after applying external
//                     resource requests (see PermissionTables()).
//
Function  ExternalResourceRequestApplyingResult(Val RequestIDs)
	
	BeginTransaction();
	
	Try
		
		LockRegistersOfGrantedPermissions();
		
		CurrentSlice = CurrentPermissionSlice();
		ApplyPermissionTableRequests(RequestIDs,  CurrentSlice);
		
		For Each SliceItem In CurrentSlice Do
			
			GroupingColumns = New Array();
			For Each Column In SliceItem.Value.Columns Do
				GroupingColumns.Add(Column.Name);
			EndDo;
			Index = GroupingColumns.Find("Owner");
			If Index <> Undefined Then
				GroupingColumns.Delete(Index);
			EndIf;
			
			SliceItem.Value.Collapse(StringFunctionsClientServer.StringFromSubstringArray(GroupingColumns, ","));
			
		EndDo;
		
		Result = New Map();
		
		For Each KeyAndValue In CurrentSlice Do
			
			TableName = KeyAndValue.Key;
			Table = KeyAndValue.Value;
			
			For Each Row In Table Do
				
				ExternalModule = ReferenceFormPermissionRegister(Row.ModuleType, Row.ModuleID);
				
				ResultByModule = Result.Get(ExternalModule);
				If ResultByModule = Undefined Then
					ResultByModule = PermissionTables();
				EndIf;
				
				ResultTable = ResultByModule[TableName];
				ResultTableRow = ResultTable.Add();
				FillPropertyValues(ResultTableRow, Row);
				
				ResultByModule.Insert(TableName, ResultTable);
				Result.Insert(ExternalModule, ResultByModule);
				
			EndDo;
			
		EndDo;
		
		CommitTransaction();
		
		Return Result;
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndFunction
 
// Generates an external resource request applying scenario.
//
// Parameters:
//  RequestIDs - Array of UUID - IDs of external resource permission requests for whose
//               applying the scenario is generated.
//
// Returns - Array of Structure - external resource request applying scenario. Array values are
//           structures with the following fields:
//            * Operation   - EnumRef.OperationsWithPermissionSets - operation to be executed.
//            * Profile     - String - security profile name.
//            * Permissions - Structure - security profile property details, see
//                            ClusterAdministrationClientServer.SecurityProfileProperties().
//
Function  ApplyingScenarioOfRequestsToChangeExternalResourceAccess(Val RequestIDs)
	
	Result = New Array();
	
	ProfileNames = New Map();
	
	AdministrationOperations = AdministrationActionsInRequests(RequestIDs);
	
	For Each Details In AdministrationOperations Do
		
		IsConfigurationProfile = (Details.ExternalModule = Catalogs.MetadataObjectIDs.EmptyRef());
		ProfileName = Details.Name;
		
		ProfileNames.Insert(Details.ExternalModule, ProfileName);
		
		ResultItem = New Structure("Operation,Profile,Permissions");
		ResultItem.Operation = Details.Operation;
		ResultItem.Profile = ProfileName;
		
		AdditionalResultItem = Undefined;
		AdditionalItemPriority = False;
		
		If IsConfigurationProfile And Details.Operation = Enums.OperationsWithPermissionSets.Create Then
			
			AdditionalResultItem = New Structure("Operation,Profile,Permissions");
			AdditionalResultItem.Operation = Enums.OperationsWithPermissionSets.Grant;
			AdditionalResultItem.Profile = ProfileName;
			
			AdditionalItemPriority = False;
			
		EndIf;
		
		If IsConfigurationProfile And Details.Operation = Enums.OperationsWithPermissionSets.Delete  Then
			
			AdditionalResultItem = New Structure("Operation,Profile,Permissions");
			AdditionalResultItem.Operation = Enums.OperationsWithPermissionSets.Deny;
			AdditionalResultItem.Profile = ProfileName;
			
			AdditionalItemPriority = True;
			
		EndIf;
		
		If AdditionalResultItem = Undefined Then
			
			Result.Add(ResultItem);
			
		Else
			
			If AdditionalItemPriority Then
				
				Result.Add(AdditionalResultItem);
				Result.Add(ResultItem);
				
			Else
				
				Result.Add(ResultItem);
				Result.Add(AdditionalResultItem);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Delta =  ExternalResourcePermissionChangeDelta(RequestIDs);
	RequestApplyingResult = ExternalResourceRequestApplyingResult(RequestIDs);
	
	For Each ChangeFragment In Delta Do
		
		Module = ChangeFragment.ExternalModule;
		
		ProfileName = ProfileNames.Get(Module);
		If ProfileName = Undefined Then
			
			If Module <>  Catalogs.MetadataObjectIDs.EmptyRef() Then
				ProfileName = ExternalModuleAttachingMode(Module);
			Else
				ProfileName = Constants.InfobaseSecurityProfile.Get();
			EndIf;
			
		EndIf;
		
		ProfileDescription = NewSecurityProfileDescription(Module);
		
		Add = True;
		ResultItem = Undefined;
		For Each Stage In Result Do
			If Stage.Operation = Enums.OperationsWithPermissionSets.Create And Stage.Profile = ProfileName Then
				ResultItem = Stage;
				Break;
			EndIf;
		EndDo;
		If ResultItem = Undefined Then
			
			ResultItem = New Structure("Operation,Profile,Permissions");
			
			ResultItem.Operation = Enums.OperationsWithPermissionSets.Update;
			ResultItem.Profile = ProfileName;
			
		Else
			Add = False;
		EndIf;
		
		If Module <> Catalogs.MetadataObjectIDs.EmptyRef() And ResultItem.Operation = Enums.OperationsWithPermissionSets.Update Then
			
			If Not SecurityProfileSetToExternalModule(ResultItem.Profile) Then
				ResultItem.Operation = Enums.OperationsWithPermissionSets.Create;
			EndIf;
			
		EndIf;
		
		ResultItem.Permissions = ProfileInClusterAdministrationInterfaceNotation(ResultItem.Profile, ProfileDescription, RequestApplyingResult.Get(Module));
		
		If Add Then
			Result.Add(ResultItem);
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction
 
// Creates security profile description in the cluster server administration interface
// notation.
//
// Parameters:
//  ProfileName        - String - security profile name. 
//  ProfileDescription - String - security profile description.
//  Permissions        - Array of XDTODataObject - array of XDTO data objects that describe
//                       the external resource permissions. The types of objects must be
//                       defined in the
//                       {http://www.1c.ru/1cFresh/Application/Permissions/a.b.c.d} package.
//
// Returns: Structure - see ClusterAdministrationClientServer.SecurityProfileProperties().
//
Function ProfileInClusterAdministrationInterfaceNotation(Val ProfileName, Val ProfileDescription, Val Permissions)
	
	Profile = ClusterAdministrationClientServer.SecurityProfileProperties();
	Profile.Name = ProfileName;
	Profile.Details = ProfileDescription;
	Profile.SafeModeProfile = True;
	
	Profile.FullFileSystemAccess = False;
	Profile.FullCOMObjectAccess = False;
	Profile.FullAddInAccess = False;
	Profile.FullExternalModuleAccess = False;
	Profile.FullOperatingSystemApplicationAccess = False;
	Profile.FullInternetResourceAccess = False;
	
	Profile.FullAccessToPrivilegedMode  = False;
	
	Managers = PermissionRegisterManagers();
	
	For Each KeyAndValue In Permissions Do
		
		TableProcessed = True;
		
		For Each Manager In Managers Do
			
			If Manager.PermissionPresentationXDTOType() = XDTOFactory.Type(SafeModeInternal.PermissionPresentationXDTOPackage(), KeyAndValue.Key) Then
				
				Table = KeyAndValue.Value;
				
				For Each Row In Table Do
					
					Manager.FillSecurityProfilePropertiesInAdministrationInterfaceNotation(
						Row, Profile);
					
				EndDo;
				
			EndIf;
			
		EndDo;
		
		If Not TableProcessed Then
			Raise  StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Unknown permission type name: %1.'"), KeyAndValue.Key);
		EndIf;
		
	EndDo;
	
	Return Profile;
	
EndFunction
 
// Returns administration operations that are in external resource requests.
//
// Parameters:
//  RequestIDs - Array of UUID - IDs of external resource permission requests.
//
// Returns: ValueTable, with the following fields:
//           * ExternalModule - AnyRef - reference to the catalog item used as an external
//                              module.
//           * Operation      - EnumRef.OperationsWithPermissionSets.
//           * Name           - String - security profile name.
//
Function AdministrationActionsInRequests(Val RequestIDs) Export
	
	Result = New ValueTable();
	Result.Columns.Add("ExternalModule");
	Result.Columns.Add("Operation", New TypeDescription("EnumRef.OperationsWithPermissionSets"));
	Result.Columns.Add("Name", New  TypeDescription("Row"));
	
	QueryText =
		"SELECT
		|	Requests.RequestID AS RequestID,
		|	Requests.ModuleType AS ModuleType,
		|	Requests.ModuleID AS  ModuleID,
		|	Requests.Operation AS  Operation,
		|	Requests.Name AS Name
		|In
		|	InformationRegister.ExternalResourcePermissionAdministrationRequests AS Requests
		|Where
		|	Requests.RequestID In(&IDs)";
	Query = New Query(QueryText);
	Query.SetParameter("IDs", RequestIDs);
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		Row = Result.Add();
		Row.ExternalModule = ReferenceFormPermissionRegister(
			Selection.ModuleType, Selection.ModuleID);
		Row.Operation = Selection.Operation;
		Row.Name = Selection.Name;
		
	EndDo;
	
	Return Result;
	
EndFunction
 
////////////////////////////////////////////////////////////////////////////////
// Serializing / deserializing of external resource requests.
//

// Serializes external resource requests.
//
// Parameters:
//  IDs -  Array of UUID - IDs of external resource requests to be serialized.
//
// Returns: Array of String -  array of the permission request serialization result.
//
Function SerializeRequestsForProcessingWithRecovery(Val IDs)
	
	Result = New Array();
	
	For Each ID In IDs Do
		
		Set = InformationRegisters.RequestsForPermissionsToUseExternalResources.CreateRecordSet();
		Set.Filter.RequestID.Set(ID);
		Set.Read();
		
		If Set.Count() > 0 Then
			
			RecordStream = New  XMLWriter();
			RecordStream.SetString();
			XDTOSerializer.WriteXML(RecordStream, Set);
			Result.Add(RecordStream.Close());
			
		EndIf;
		
		Set = InformationRegisters.ExternalResourcePermissionAdministrationRequests.CreateRecordSet();
		Set.Filter.RequestID.Set(ID);
		Set.Read();
		
		If Set.Count() > 0 Then
			
			RecordStream = New  XMLWriter();
			RecordStream.SetString();
			XDTOSerializer.WriteXML(RecordStream, Set);
			Result.Add(RecordStream.Close());
			
		EndIf;
		
	EndDo;
	
	Return New FixedArray(Result);
	
EndFunction
 
// Deserializes external resource requests and writes them to the infobase.
//
// Parameters:
//  Serialization -  Array of String - see SerializeRequestsForProcessingWithRecovery().
//
Procedure DeserializeRequestsForProcessingWithRecovery(Val Serialization)
	
	For Each SerializationItem In Serialization Do
		
		ReaderStream = New XMLReader();
		ReaderStream.SetString(SerializationItem);
		ReaderStream.MoveToContent();
		
		Set = XDTOSerializer.ReadXML(ReaderStream);
		Set.Write();
		
	EndDo;
	
EndProcedure
 
////////////////////////////////////////////////////////////////////////////////
// External resource permission setup wizard logic.
//

// Processes external resource requests when the permission setup wizard is initialized.
//
// Parameters:
//  RequestIDs         - Array of UUID - IDs of requests for whose applying the wizard is
//                       initialized. 
//  TempStorageAddress - String - address of the temporary storage where the result of the
//                       external resource request processing is placed.
//
// As the result of the procedure execution, the following structure is passes to the specified 
// address:
//  * RequestIDs   - Array of UUID - IDs of requests for which the wizard is initialized. 
//  * Presentation - SpreadsheetDocument - presentations of changes in external resource 
//                   permissions to be added to the security profile settings in the server
//                   cluster.
//  * Scenario     - Array of Structure - scenario of adding changes to the security profile
//                   settings in the server cluster to be executed when the requests are
//                   applied. Array values are structures with the following fields:
//                    * Operation   - EnumRef.OperationsWithPermissionSets - operation to be 
//                                    executed.
//                    * Profile     - String - security profile name.
//                    * Permissions - Structure - security profile property details, see
//                                    ClusterAdministrationClientServer.SecurityProfileProperties().
//
Procedure ExecuteRequestProcessing(Val RequestIDs, TempStorageAddress) Export
	
	AdministrationOperations = AdministrationActionsInRequests(RequestIDs);
	Delta = ExternalResourcePermissionChangeDelta(RequestIDs);
	
	Result = New Structure();
	
	Result.Insert("RequestIDs", RequestIDs);
	Result.Insert("Presentation", Reports.ExternalResourcesInUse.ExternalResourceRequestApplyingResultPresentation(AdministrationOperations, Delta));
	Result.Insert("Scenario", ApplyingScenarioOfRequestsToChangeExternalResourceAccess(RequestIDs));
	
	PutToTempStorage(Result, TempStorageAddress);
	
EndProcedure
 
// Processes external resource requests after the configuration update (or during enabling
// security profiles initially).
//
// Parameters:
//  TempStorageAddress - String - address of the temporary storage where the result of the
//                       external resource request processing is placed.
//
// As the result of the procedure execution, the following structure is passes to the specified
// address:
//  * RequestIDs   - Array of UUID - IDs of requests for which the wizard is initialized. 
//  * Presentation - SpreadsheetDocument -  presentations of changes in external resource
//                   permissions to be added to the security profile settings in the server
//                   cluster.
//  * Scenario     - Array of Structure - scenario of adding changes to the security profile
//                   settings in the server cluster to be executed when the requests are 
//                   applied. Array values are structures with the following fields:
//                    * Operation   - EnumRef.OperationsWithPermissionSets -  operation to be
//                                    executed.
//                    * Profile     - String - security profile name.
//                    * Permissions - Structure - security profile property details, see
//                                    ClusterAdministrationClientServer.SecurityProfileProperties().
//
Procedure  ExecuteUpdateRequestProcessing(TempStorageAddress) Export
	
	CallWithDisabledProfiles = Not Constants.AutomaticallySetUpPermissionsInSecurityProfiles.Get();
	
	If CallWithDisabledProfiles Then
		
		BeginTransaction();
		
		Constants.UseSecurityProfiles.Set(True);
		Constants.AutomaticallySetUpPermissionsInSecurityProfiles.Set(True);
		
		RequestIDs = SafeModeInternal.RequestsToUpdateConfigurationPermissions();
		RequestSerialization = SerializeRequestsForProcessingWithRecovery(RequestIDs);
		
	EndIf;
	
	ExecuteRequestProcessing(RequestIDs, TempStorageAddress);
	
	If CallWithDisabledProfiles Then
		
		RollbackTransaction();
		DeserializeRequestsForProcessingWithRecovery(RequestSerialization);
		
	EndIf;
	
EndProcedure
 
// Processes requests for disabling security profiles for the infobase.
//
// Parameters:
//  TempStorageAddress - String - address of the temporary storage where the result of the
//                       external resource request processing is placed.
//
// As the result of the procedure execution, the following structure is passes to the specified
// address:
//  * RequestIDs   - Array of UUID - IDs of requests for which the wizard is initialized. 
//  * Presentation - SpreadsheetDocument -  presentations of changes in external resource
//                   permissions to be added to the security profile settings in the server
//                   cluster.
//  * Scenario     - Array of Structure - scenario of adding changes to the security profile
//                   settings in the server cluster to be executed when the requests are 
//                   applied. Array values are structures with the following fields:
//                    * Operation   - EnumRef.OperationsWithPermissionSets - operation to be 
//                                    executed.
//                    * Profile     - String - security profile name.
//                    * Permissions - Structure - security profile property details, see
//                                    ClusterAdministrationClientServer.SecurityProfileProperties().
//
Procedure  ExecuteDisableRequestProcessing(TempStorageAddress) Export
	
	Requests = SecurityProfileDisablingRequests();
	ExecuteRequestProcessing(Requests, TempStorageAddress);
	
EndProcedure
 
// Processes requests for recovering security profiles by the current infobase state.
//
// Parameters:
//  TempStorageAddress - String - address of the temporary storage where the result of the
//                       external resource request processing is placed.
//
// As the result of the procedure execution, the following structure is passes to the specified 
// address:
//  * RequestIDs   - Array of UUID - IDs of requests for which the wizard is initialized. 
//  * Presentation - SpreadsheetDocument -  presentations of changes in external resource
//                   permissions to be added to the security profile settings in the server
//                   cluster.
//  * Scenario     - Array of Structure - scenario of adding changes to the security profile
//                   settings in the server cluster to be executed when the requests are
//                   applied. Array values are structures with the following fields:
//                    * Operation   - EnumRef.OperationsWithPermissionSets - operation to be
//                                    executed.
//                    * Profile     - String - security profile name.
//                    * Permissions - Structure - security profile property details, see
//                                    ClusterAdministrationClientServer.SecurityProfileProperties().
//
Procedure ExecuteRecoveryRequestProcessing(TempStorageAddress) Export
	
	BeginTransaction();
	
	ClearPermissions(, False);
	
	RequestIDs = SafeModeInternal.RequestsToUpdateConfigurationPermissions(False);
	
	RequestSerialization = SerializeRequestsForProcessingWithRecovery(RequestIDs);
	
	ExecuteRequestProcessing(RequestIDs, TempStorageAddress);
	
	RollbackTransaction();
	
	DeserializeRequestsForProcessingWithRecovery(RequestSerialization);
	
EndProcedure
 
// Processes requests for checking whether the action, within the scope of which
// the external resource requests were applied, is finished.
//
// Parameters:
//  TempStorageAddress - String - address of the temporary storage where the result of the
//                       external resource request processing is placed.
//
// As the result of the procedure execution, the following structure is passes to the specified 
// address:
//  * RequestIDs   - Array of UUID - IDs of requests for which the wizard is initialized. 
//  * Presentation - SpreadsheetDocument - presentations of changes in external resource
//                   permissions to be added to the security profile settings in the server
//                   cluster.
//  * Scenario     - Array of Structure - scenario of adding changes to the security profile
//                   settings in the server cluster to be executed when the requests are
//                   applied. Array values are structures with the following fields:
//                    * Operation   - EnumRef.OperationsWithPermissionSets - operation to be
//                                    executed.
//                    * Profile     - String - security profile name.
//                    * Permissions - Structure - security profile property details, see
//                      ClusterAdministrationClientServer.SecurityProfileProperties().
//
Procedure ExecuteCheckForApplyRequestProcessing(TempStorageAddress) Export
	
	RequestIDs = New Array();
	CommonUseClientServer.SupplementArray(RequestIDs, ReplacementQueriesForAllGrantedPermissions());
	CommonUseClientServer.SupplementArray(RequestIDs,  SafeModeInternal.RequestsToUpdateConfigurationPermissions(False));
	
	ExecuteRequestProcessing(RequestIDs, TempStorageAddress);
	
EndProcedure
 
////////////////////////////////////////////////////////////////////////////////
// External modules
//

// Returns external module attaching mode.
//
// Parameters:
//  ExternalModule - AnyRef - reference corresponding to the external module whose applying
//                   mode is retrieved.
//
// Returns: String - name of the security profile to be used for attaching the external
//                   module. If the attaching mode is not registered for the external module,
//                   Undefined is returned.
//
Function ExternalModuleAttachingMode(Val ExternalModule) Export
	
	If SafeMode.SafeModeSet() Then
		
		Return SafeMode();
		
	Else
		
		SetPrivilegedMode(True);
		
		ModuleProperties = PropertiesForPermissionRegister(ExternalModule);
		
		Manager = InformationRegisters.ExternalModuleAddingModes.CreateRecordManager();
		Manager.ModuleType = ModuleProperties.Type;
		Manager.ModuleID = ModuleProperties.ID;
		Manager.Read();
		If Manager.Selected() Then
			Return Manager.SafeMode;
		Else
			Return Undefined;
		EndIf;
		
	EndIf;
	
EndFunction
 
////////////////////////////////////////////////////////////////////////////////
// Others
//

// Generates security profile name for the infobase or the external module.
//
// Parameters:
//  ExternalModule -  AnyRef - reference to the catalog item used as the external module.
//
// Return value: String - security profile name.
//
Function NewSecurityProfileName(Val ExternalModule)
	
	If ExternalModule = Catalogs.MetadataObjectIDs.EmptyRef() Then
		
		Result = "Infobase_" + String(New UUID());
		
	Else
		
		ExternalModule = ExternalModule;
		
		ModuleManager = SafeModeInternal.ExternalModuleManager(ExternalModule);
		Pattern = ModuleManager.SecurityProfileNamePattern(ExternalModule);
		Return StrReplace(Pattern, "%1", String(New UUID()));
		
	EndIf;
	
	Return Result;
	
EndFunction
 
// Generates the security profile description for the infobase or the external module.
//
// Parameters:
//  ExternalModule - AnyRef - reference to the catalog item used as the external module.
//
// Return value: String - security profile description.
//
Function NewSecurityProfileDescription(Val ExternalModule) Export
	
	Pattern = NStr("en = '[IB %1] %2""%3""'");
	
	InfobaseName = "";
	ConnectionString =  InfobaseConnectionString();
	Substrings = StringFunctionsClientServer.SplitStringIntoSubstringArray(ConnectionString, ";");
	For Each Substring In Substrings Do
		If Left(Substring, 3) = "Ref" Then
			InfobaseName = StrReplace(Right(Substring, StrLen(Substring) - 4), """", "");
		EndIf;
	EndDo;
	If IsBlankString(InfobaseName) Then
		Raise NStr("en = 'The infobase connection string does not contain the infobase name.'");
	EndIf;
	
	If ExternalModule =  Catalogs.MetadataObjectIDs.EmptyRef() Then
		Return StringFunctionsClientServer.SubstituteParametersInString(Pattern, InfobaseName,
			NStr("en = 'Default security profile for'"),  InfobaseConnectionString());
	Else
		Dictionary =  SafeModeInternal.ExternalModuleManager(ExternalModule).ExternalModuleContainerDictionary();
		ModuleDescription = CommonUse.ObjectAttributeValue(ExternalModule, "Description");
		Return StringFunctionsClientServer.SubstituteParametersInString(Pattern, InfobaseName, Dictionary.NominativeCase, ModuleDescription);
	EndIf;
	
EndFunction
 
// Returns the security profile name for the infobase or the external module.
//
// Parameters:
//  ExternalModule - AnyRef - reference to the catalog item used as the external module.
//
// Return value: String - security profile name.
//
Function SecurityProfileName(Val ExternalModule) Export
	
	If ExternalModule = Catalogs.MetadataObjectIDs.EmptyRef() Then
		
		Return Constants.InfobaseSecurityProfile.Get();
		
	Else
		
		Return ExternalModuleAttachingMode(ExternalModule);
		
	EndIf;
	
EndFunction
 
// Checks whether the security profile is set to the external module.
//
// Parameters:
//  ProfileName - String - security profile name.
//
// Returns: Boolean.
//
Function SecurityProfileSetToExternalModule(Val ProfileName)
	
	QueryText =
		"SELECT
		|	ExternalModuleAddingModes.ModuleType AS ModuleType,
		|	ExternalModuleAddingModes.ModuleID AS ModuleID
		|In
		|	InformationRegister.ExternalModuleAddingModes AS ExternalModuleAddingModes
		|Where
		|	ExternalModuleAddingModes.SafeMode = &SafeMode";
	Query = New  Query(QueryText);
	Query.SetParameter("SafeMode", ProfileName);
	QueryResult = Query.Execute();
	Return Not QueryResult.IsEmpty();
	
EndFunction
 
// Generates parameters for storing references in permission registers.
//
// Parameters:
//  Ref -  AnyRef.
//
// Returns: Structure:
//           * Type - CatalogRef.MetadataObjectIDs
//           * ID   - String - contains UUID casted into string.
//
Function PropertiesForPermissionRegister(Val Ref)  Export
	
	Result = New  Structure("Type,ID");
	
	If Ref = Catalogs.MetadataObjectIDs.EmptyRef() Then
		
		Result.Type = Catalogs.MetadataObjectIDs.EmptyRef();
		Result.ID = "";
		
	Else
		
		Result.Type = CommonUse.MetadataObjectID(Ref.Metadata());
		Result.ID = String(Ref.UUID());
		
	EndIf;
	
	Return Result;
	
EndFunction
 
// Generates the reference by data from the permission registers.
//
// Parameters:
//  Type - CatalogRef.MetadataObjectID,
//  ID   - String - reference UUID casted into string.
//
// Returns: AnyRef.
//
Function ReferenceFormPermissionRegister(Val Type, Val ID)
	
	If Type = Catalogs.MetadataObjectIDs.EmptyRef() Then
		Return Type;
	Else
		
		MetadataObject = CommonUse.MetadataObjectByID(Type);
		Manager = CommonUse.ObjectManagerByFullName(MetadataObject.FullName());
		
		If IsBlankString(ID) Then
			Return Manager.EmptyRef();
		Else
			UUID = New UUID(ID);
			Return Manager.GetRef(UUID);
		EndIf;
		
	EndIf;
	
EndFunction

#EndRegion

#EndIf
