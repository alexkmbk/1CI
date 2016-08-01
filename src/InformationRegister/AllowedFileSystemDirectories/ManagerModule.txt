#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region InternalInterface

// Retrieves XDTO type that describes the permissions of the type corresponding to
// the cache item.
//
// Returns:
//  XDTODataObjectType.
//
Function PermissionPresentationXDTOType() Export
	
	Return XDTOFactory.Type(SafeModeInternal.PermissionPresentationXDTOPackage(), "FileSystemAccess");
	
EndFunction

// Generates a record set of the current cache register from permission XDTO
// presentations.
//
// Parameters:
//  ExternalModule    - AnyRef,
//  Owner             - AnyRef,
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
		
		Table = DataProcessors.ExternalResourcePermissionSetup.PermissionTable(CreateRecordSet().Metadata(), True);
		
		For Each XDTOPresentation In XDTOPresentations Do
			
			Key = New Structure("ModuleType,ModuleID,OwnerType,OwnerID,Address",
				ModuleProperties.Type, 
				ModuleProperties.ID, 
				OwnerProperties.Type, 
				OwnerProperties.ID, 
				XDTOPresentation.Path);
			RowsByKey = Table.FindRows(Key);
			
			If RowsByKey.Count() = 0 Then
				Row = Table.Add();
				Row.ModuleType = ModuleProperties.Type;
				Row.ModuleID = ModuleProperties.ID;
				Row.OwnerType = OwnerProperties.Type;
				Row.OwnerID = OwnerProperties.ID;
				Row.Address = XDTOPresentation.Path;
				Row.DataReadingAllowed = XDTOPresentation.AllowedRead;
				Row.DataWritingAllowed = XDTOPresentation.AllowedWrite;
			ElsIf RowsByKey.Count() = 1 Then
				Row = RowsByKey[0];
				If XDTOPresentation.AllowedRead And Not Row.DataReadingAllowed Then
					Row.DataReadingAllowed = True;
				EndIf;
				If XDTOPresentation.AllowedWrite And Not Row.DataWritingAllowed Then
					Row.DataWritingAllowed = True;
				EndIf;
			Else
			EndIf;
			
		EndDo;
		
		Set.Load(Table);
		Return Set;
		
	EndIf;
	
EndFunction

// Fills security profile properties (in the ClusterAdministrationClientServer common
// module interface notation) by the record manager of the current cache item.
//
// Parameters:
//  Manager - InformationRegisterRecordManager,
//  Profile - Structure.
//
Procedure FillSecurityProfilePropertiesInAdministrationInterfaceNotation(Val Manager, Profile) Export
	
	If StandardVirtualDirectories().Get(Manager.Address) <> Undefined Then
		
		VirtualDirectory = ClusterAdministrationClientServer.VirtualDirectoryProperties();
		VirtualDirectory.LogicalURL = Manager.Address;
		VirtualDirectory.PhysicalURL = StandardVirtualDirectories().Get(Manager.Address);
		VirtualDirectory.DataReading = Manager.DataReadingAllowed;
		VirtualDirectory.DataWriting = Manager.DataWritingAllowed;
		Profile.VirtualDirectories.Add(VirtualDirectory);
		
	Else
		
		VirtualDirectory = ClusterAdministrationClientServer.VirtualDirectoryProperties();
		VirtualDirectory.LogicalURL = Manager.Address;
		VirtualDirectory.PhysicalURL = Manager.Address;
		VirtualDirectory.DataReading = Manager.DataReadingAllowed;
		VirtualDirectory.DataWriting = Manager.DataWritingAllowed;
		Profile.VirtualDirectories.Add(VirtualDirectory);
		
	EndIf;
	
EndProcedure

// Returns a query text for getting the current slice of permissions of the cache
// item.
//
// Parameters:
//  CollapseOwners - Boolean - flag that shows whether the query result must be
//                             collapsed by owners.
//
// Returns:
//  String - query text.
//
Function CurrentSliceQuery(Val CollapseOwners = True) Export
	
	If CollapseOwners Then
		
		Return "SELECT DISTINCT
		        |	Permissions.Address,
		        |	Permissions.DataReadingAllowed,
		        |	Permissions.DataWritingAllowed
		        |FROM
		        |	InformationRegister.AllowedFileSystemDirectories AS Permissions";
		
	Else
		
		Return "SELECT DISTINCT
		        |	Permissions.Address,
		        |	Permissions.DataReadingAllowed,
		        |	Permissions.DataWritingAllowed,
		        |	Permissions.ModuleType AS ModuleType,
		        |	Permissions.ModuleID AS ModuleID,
		        |	Permissions.OwnerType AS OwnerType,
		        |	Permissions.OwnerID AS OwnerID
		        |FROM
		        |	InformationRegister.AllowedFileSystemDirectories AS Permissions";
		
	EndIf;
	
EndFunction

// Returns a query text for getting permission change delta of the cache item.
//
// Returns:
//  String - query text.
//
Function DeltaGettingQuery() Export
	
	Return
		"SELECT DISTINCT
		|	TT_Before.Address,
		|	TT_Before.DataReadingAllowed,
		|	TT_Before.DataWritingAllowed,
		|	TT_Before.ModuleType,
		|	TT_Before.ModuleID
		|FROM
		|	TT_Before AS TT_Before
		|		LEFT JOIN TT_After AS TT_After
		|			ON TT_Before.ModuleType = TT_After.ModuleType
		|			AND TT_Before.ModuleID = TT_After.ModuleID
		|			AND TT_Before.Address = TT_After.Address
		|WHERE
		|	TT_After.Address IS NULL 
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	TT_After.Address,
		|	TT_After.DataReadingAllowed,
		|	TT_After.DataWritingAllowed,
		|	TT_After.ModuleType,
		|	TT_After.ModuleID
		|FROM
		|	TT_After AS TT_After
		|		LEFT JOIN TT_Before AS TT_Before
		|			ON TT_After.ModuleType = TT_Before.ModuleType
		|			AND TT_After.ModuleID = TT_Before.ModuleID
		|			AND TT_After.Address = TT_Before.Address
		|WHERE
		|	TT_Before.Address IS NULL ";
	
EndFunction

#EndRegion

#Region InternalProceduresAndFunctions

Function StandardVirtualDirectories()
	
	Result = New Map();
	
	Result.Insert("/temp", "%t/%i/%s/%p");
	Result.Insert("/bin", "%e");
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf