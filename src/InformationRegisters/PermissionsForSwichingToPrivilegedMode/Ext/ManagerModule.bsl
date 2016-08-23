#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region InternalInterface

// Retrieves XDTO type that describes the permissions of the type corresponding to
// the cache item.
//
// Returns:
//  XDTODataObjectType.
//
Function PermissionPresentationXDTOType() Export
	
	Return XDTOFactory.Type(SafeModeInternal.PermissionPresentationXDTOPackage(), "ExternalModulePrivilegedModeAllowed");
	
EndFunction

// Generates a record set of the current cache register from permission XDTO
// presentations.
//
// Parameters:
//  ExternalModule    - AnyRef.
//  Owner             - AnyRef.
//  XDTOPresentations - Array of XDTODataObject.
//
// Returns:
//  InformationRegisterRecordSet.
//
Function RecordSetFromPresentationXDTO(Val XDTOPresentations, Val ExternalModule, Val Owner, Val ToDelete) Export
	
	Set = CreateRecordSet();
	
	ModuleProperties = DataProcessors.ExternalResourcePermissionSetup.PropertiesForPermissionRegister(ExternalModule);
	Set.Filter.ModuleType.Set(ModuleProperties.Type);
	Set.Filter.ModuleID.Set(ModuleProperties.ID);
	
	OwnerProperties = DataProcessors.ExternalResourcePermissionSetup.PropertiesForPermissionRegister(Owner);
	Set.Filter.OwnerType.Set(OwnerProperties.Type);
	Set.Filter.OwnerID.Set(OwnerProperties.ID);
	
	If ToDelete Then
		
		Return Set;
		
	Else
		
		ValuesTable = DataProcessors.ExternalResourcePermissionSetup.PermissionTable(CreateRecordSet().Metadata(), True);
		
		For Each XDTOPresentation In XDTOPresentations Do
			
			Key = New Structure("ModuleType,ModuleID,OwnerType,OwnerID",
				ModuleProperties.Type,
				ModuleProperties.ID,
				OwnerProperties.Type,
				OwnerProperties.ID);
			If ValuesTable.FindRows(Key).Count() = 0 Then
				Row = ValuesTable.Add();
				Row.ModuleType = ModuleProperties.Type;
				Row.ModuleID = ModuleProperties.ID;
				Row.OwnerType = OwnerProperties.Type;
				Row.OwnerID = OwnerProperties.ID;
			EndIf;
			
		EndDo;
		
		Set.Load(ValuesTable);
		Return Set;
		
	EndIf;
	
EndFunction

// Fills security profile properties (in the ClusterAdministrationClientServer common module interface notation) by the record manager of the current cache item.
//
// Parameters:
//  Manager - InformationRegisterRecordManager,
//  Profile - Structure.
//
Procedure FillSecurityProfilePropertiesInAdministrationInterfaceNotation(Val Manager, Profile) Export
	
	Profile.FullAccessToPrivilegedMode = True;
	
EndProcedure

// Returns a query text for getting the current slice of permissions of the cache
// item.
//
// Parameters:
//  CollapseOwners - Boolean - flag that shows whether the query result must be
//                   collapsed by owners.
//
// Returns:
//  String - query text.
//
Function CurrentSliceQuery(Val CollapseOwners = True) Export
	
	If CollapseOwners Then
		
		Return "SELECT DISTINCT
		        |	TRUE AS SwitchingToPrivilegedModeAllowed,
		        |	Permissions.ModuleType AS ModuleType,
		        |	Permissions.ModuleID AS ModuleID
		        |FROM
		        |	InformationRegister.PermissionsForSwichingToPrivilegedMode AS Permissions";
	Else
		
		Return "SELECT DISTINCT
		        |	TRUE AS SwitchingToPrivilegedModeAllowed,
		        |	Permissions.ModuleType AS ModuleType,
		        |	Permissions.ModuleID AS ModuleID,
		        |	Permissions.OwnerType AS OwnerType,
		        |	Permissions.OwnerID AS OwnerID
		        |FROM
		        |	InformationRegister.PermissionsForSwichingToPrivilegedMode AS Permissions";
		
	EndIf;
	
EndFunction

// Returns query text for getting permission change delta of the cache item.
//
// Returns:
//  String - query text.
//
Function DeltaGettingQuery() Export
	
	Return
		"SELECT DISTINCT
		|	TRUE AS SwitchingToPrivilegedModeAllowed,
		|	TT_Before.ModuleType,
		|	TT_Before.ModuleID
		|FROM
		|	TT_Before AS TT_Before
		|		LEFT JOIN TT_After AS TT_After
		|			ON TT_Before.ModuleType = TT_After.ModuleType
		|			AND TT_Before.ModuleID = TT_After.ModuleID
		|WHERE
		|	TT_After.ModuleType IS NULL 
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	TRUE AS SwitchingToPrivilegedModeAllowed,
		|	TT_After.ModuleType,
		|	TT_After.ModuleID
		|FROM
		|	TT_After AS TT_After
		|		LEFT JOIN TT_Before AS TT_Before
		|			ON TT_After.ModuleType = TT_Before.ModuleType
		|			AND TT_After.ModuleID = TT_Before.ModuleID
		|WHERE
		|	TT_Before.ModuleType IS NULL ";
	
EndFunction

#EndRegion

#EndIf