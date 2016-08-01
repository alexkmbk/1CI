#If Server OR ThickClientOrdinaryApplication OR ExternalConnection Then

#Region InternalInterface

// Updates common user parameters when a configuration is changed.

// Parameters:
//  HasChanges - Boolean (return value) - True if data is changed; not set otherwise.

Procedure UpdateCommonParameters(HasChanges = Undefined, CheckOnly = False) Export
	
	SetPrivilegedMode(True);
	
	If CheckOnly Or ExclusiveMode() Then
		DisableExclusiveMode = False;
	Else
		DisableExclusiveMode = True;
		SetExclusiveMode(True);
	EndIf;
	
	InaccessibleRolesByUserTypes = InaccessibleRolesByUserTypes();
	
	AllRoles = AllRoles();
	
	DataLock = New DataLock;
	LockItem = DataLock.Add("Constant.UserSessionParameters");
	LockItem.Mode = DataLockMode.Exclusive;
	
	BeginTransaction();
	Try
		DataLock.Lock();
		
		Parameters = StandardSubsystemsServer.ApplicationParameters(
			"UserSessionParameters");
		
		// Checking and updating InaccessibleRolesByUserTypes parameter
		Saved = Undefined;
		
		If Parameters.Property("InaccessibleRolesByUserTypes") Then
			Saved = Parameters.InaccessibleRolesByUserTypes;
			
			If Not CommonUse.IsEqualData(
			          InaccessibleRolesByUserTypes, Saved) Then
				
				Saved = Undefined;
			EndIf;
		EndIf;
		
		If Saved = Undefined Then
			HasChanges = True;
			If CheckOnly Then
				CommitTransaction();
				Return;
			EndIf;
			StandardSubsystemsServer.SetApplicationParameter(
				"UserSessionParameters",
				"InaccessibleRolesByUserTypes",
				InaccessibleRolesByUserTypes);
		EndIf;
		
		StandardSubsystemsServer.ConfirmApplicationParametersUpdate(
			"UserSessionParameters", "InaccessibleRolesByUserTypes");
		
		// Checking and updating AllRoles parameter
		Saved = Undefined;
		
		If Parameters.Property("AllRoles") Then
			Saved = Parameters.AllRoles;
			
			If Not CommonUse.IsEqualData(AllRoles, Saved) Then
				Saved = Undefined;
			EndIf;
		EndIf;
		
		If Saved = Undefined Then
			HasChanges = True;
			If CheckOnly Then
				CommitTransaction();
				Return;
			EndIf;
			StandardSubsystemsServer.SetApplicationParameter(
				"UserSessionParameters",
				"AllRoles",
				AllRoles);
		EndIf;
		
		StandardSubsystemsServer.ConfirmApplicationParametersUpdate(
			"UserSessionParameters", "AllRoles");
		
		CommitTransaction();
	Except
		RollbackTransaction();
		If DisableExclusiveMode Then
			SetExclusiveMode(False);
		EndIf;
		Raise;
	EndTry;
	
	If DisableExclusiveMode Then
		SetExclusiveMode(False);
	EndIf;
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

Function InaccessibleRolesByUserTypes()
	
	InaccessibleRights                         = InaccessibleRightsByUserTypes();
	CommonDataChangeAllowed            = CommonDataChangeAllowed();
	EditableSharedData = EditableSharedData();
	
	
	InaccessibleRolesByUserTypes = New Map;
	
	For Each UserType In Enums.UserTypes Do
		InaccessibleRoles = New Map;
		
		For Each Role In Metadata.Roles Do
			RoleName = Role.Name;
			Total = New Structure;
			FoundInaccessibleRights = New Array;
			If InaccessibleRights[UserType] <> Undefined Then
				For Each KeyAndValue In InaccessibleRights[UserType] Do
					If AccessRight(KeyAndValue.Key, Metadata, Role) Then
						FoundInaccessibleRights.Add(KeyAndValue.Value);
					EndIf;
				EndDo;
				If FoundInaccessibleRights.Count() > 0 Then
					Total.Insert("Rights", FoundInaccessibleRights);
				EndIf;
			EndIf;
			
			If CommonDataChangeAllowed[UserType] <> True Then
				Filter = New Structure("Role", RoleName);
				FoundRows = EditableSharedData.FindRows(Filter);
				If FoundRows.Count() > 0 Then
					
					ChangeableSharedData =
						EditableSharedData.Copy(
							FoundRows, "Object, Right");
					
					ChangeableSharedData.GroupBy("Object, Right");
					Total.Insert("ChangeableSharedData", ChangeableSharedData);
				EndIf;
			EndIf;
			
			If Total.Count() > 0 Then
				InaccessibleRoles.Insert(RoleName, Total);
			EndIf;
		EndDo;
		
		InaccessibleRolesByUserTypes.Insert(UserType, InaccessibleRoles);
	EndDo;
	
	Return CommonUse.FixedData(InaccessibleRolesByUserTypes, False);
	
EndFunction

// Returns a table of  full names of shared metadata objects and the relevant sets of access rights.
//
// Returns:
//  ValueTable with the following columns: 
//   * role   - String - role name.
//   * Object - String - full metadata object name.
//   * right  - String - access right name.
//
Function EditableSharedData() Export
	
	CommonTable = New ValueTable;
	CommonTable.Columns.Add("Role",   New TypeDescription("String", , New StringQualifiers(0, AllowedLength.Variable)));
	CommonTable.Columns.Add("Object", New TypeDescription("String", , New StringQualifiers(0, AllowedLength.Variable)));
	CommonTable.Columns.Add("Right",  New TypeDescription("String", , New StringQualifiers(0, AllowedLength.Variable)));
	
	If Not CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.BaseFunctionalitySaaS") Then
		Return CommonTable;
	EndIf;
	
	MetadataKinds = New Array;
	MetadataKinds.Add(New Structure("Type, Reference" , Metadata.ExchangePlans, True));
	MetadataKinds.Add(New Structure("Type, Reference" , Metadata.Constants, False));
	MetadataKinds.Add(New Structure("Type, Reference" , Metadata.Catalogs, True));
	MetadataKinds.Add(New Structure("Type, Reference" , Metadata.Sequences, False));
	MetadataKinds.Add(New Structure("Type, Reference" , Metadata.Documents, True));
	MetadataKinds.Add(New Structure("Type, Reference" , Metadata.ChartsOfCharacteristicTypes, True));
	MetadataKinds.Add(New Structure("Type, Reference" , Metadata.ChartsOfAccounts, True));
	MetadataKinds.Add(New Structure("Type, Reference" , Metadata.ChartsOfCalculationTypes, True));
	MetadataKinds.Add(New Structure("Type, Reference" , Metadata.BusinessProcesses, True));
	MetadataKinds.Add(New Structure("Type, Reference" , Metadata.Tasks, True));
	MetadataKinds.Add(New Structure("Type, Reference" , Metadata.InformationRegisters, False));
	MetadataKinds.Add(New Structure("Type, Reference" , Metadata.AccumulationRegisters, False));
	MetadataKinds.Add(New Structure("Type, Reference" , Metadata.AccountingRegisters, False));
	MetadataKinds.Add(New Structure("Type, Reference" , Metadata.CalculationRegisters, False));
	
	CheckedRights = New Array;
	CheckedRights.Add(New Structure("Name, Reference", "Update",  False));
	CheckedRights.Add(New Structure("Name, Reference", "Insert", True));
	CheckedRights.Add(New Structure("Name, Reference", "Delete",   True));
	
	SetPrivilegedMode(True);
	
	SaaSOperationsCachedModule = CommonUse.CommonModule("SaaSOperationsCached");
	DataModel = SaaSOperationsCachedModule.GetDataAreaModel();
	
	SeparatedMetadataObjects = New Map();
	For Each ModelItemData In DataModel Do
		
		SeparatedMetadataObjects.Insert(
			Metadata.FindByFullName(ModelItemData.Key), True);
		
	EndDo;
	
	For Each KindDescription In MetadataKinds Do // By metadata type
		For Each MetadataObject In KindDescription.Type Do // By object of this type
			
			If SeparatedMetadataObjects.Get(MetadataObject) <> Undefined Then
				Continue;
			EndIf;
			
			For Each Role In Metadata.Roles Do
				
				If Not AccessRight("Read", MetadataObject, Role) Then
					Continue;
				EndIf;
				
				For Each RightDetails In CheckedRights Do
					If Not RightDetails.Reference
						Or KindDescription.Reference Then
						
						If AccessRight(RightDetails.Name, MetadataObject, Role) Then
							// Table of roles and objects that correspond to the roles
							RowRights = CommonTable.Add();
							RowRights.Role   = Role.Name;
							RowRights.Object = MetadataObject.FullName();
							RowRights.Right  = RightDetails.Name;
						EndIf;
						
					EndIf;
				EndDo;
				
			EndDo;
		EndDo;
	EndDo;
	
	CommonTable.Indexes.Add("Role");
	Return CommonTable;
	
EndFunction

Function InaccessibleRightsByUserTypes()
	
	InaccessibleRights = New Map;
	
	Rights = New Map;
	InaccessibleRights.Insert(Enums.UserTypes.ExternalUser, Rights);
	Rights.Insert("Administration",       NStr("en = 'Administration'"));
	Rights.Insert("DataAdministration", NStr("en = 'Data administration'"));
	
	Rights = New Map;
	InaccessibleRights.Insert(Enums.UserTypes.LocalApplicationUser, Rights);
	Rights.Insert("Administration",                     NStr("en = 'Administration'"));
	Rights.Insert("UpdateDataBaseConfiguration",      NStr("en = 'Update database configuration'"));
	
	Rights = New Map;
	InaccessibleRights.Insert(Enums.UserTypes.DataAreaUser, Rights);
	Rights.Insert("Administration",                     NStr("en = 'Administration'"));
	Rights.Insert("UpdateDataBaseConfiguration",      NStr("en = 'Update database configuration'"));
	Rights.Insert("ThickClient",                         NStr("en = 'Thick client'"));
	Rights.Insert("ExternalConnection",                     NStr("en = 'External connection'"));
	Rights.Insert("Automation",                            NStr("en = 'Automation'"));
	Rights.Insert("InteractiveOpenExtDataProcessors", NStr("en = 'Interactive open external data processors'"));
	Rights.Insert("InteractiveOpenExtReports",   NStr("en = 'Interactive open external reports'"));
	Rights.Insert("AllFunctionsMode",                       NStr("en = 'Mode ""All functions""'"));
	
	Return InaccessibleRights;
	
EndFunction

Function CommonDataChangeAllowed()
	
	Total = New Map;
	
	Total.Insert(Enums.UserTypes.ExternalUser,           True);
	Total.Insert(Enums.UserTypes.LocalApplicationUser, True);
	Total.Insert(Enums.UserTypes.DataAreaUser,     False);
	
	Return Total;
	
EndFunction

Function AllRoles()
	
	Array = New Array;
	Map = New Map;
	
	Table = New ValueTable;
	Table.Columns.Add("Name", New TypeDescription("String", , New StringQualifiers(256)));
	
	For Each Role In Metadata.Roles Do
		RoleName = Role.Name;
		
		Array.Add(RoleName);
		Map.Insert(RoleName, True);
		Table.Add().Name = RoleName;
	EndDo;
	
	AllRoles = New Structure;
	AllRoles.Insert("Array",       New FixedArray(Array));
	AllRoles.Insert("Map", New FixedMap(Map));
	AllRoles.Insert("Table",      Table);
	
	Return CommonUse.FixedData(AllRoles, False);
	
EndFunction

#EndRegion

#EndIf