#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region InternalInterface

// Retrieves XDTO type that describes the permissions of the type corresponding to 
// the cache item.
//
// Returns:
//  XDTODataObjectType.
//
Function PermissionPresentationXDTOType() Export
	
	Return XDTOFactory.Type(SafeModeInternal.PermissionPresentationXDTOPackage(), "AttachAddin");
	
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
			
			Key = New Structure("ModuleType,ModuleID,OwnerType,OwnerID,TemplateName",
				ModuleProperties.Type,
				ModuleProperties.ID,
				OwnerProperties.Type,
				OwnerProperties.ID,
				XDTOPresentation.TemplateName);
			If Table.FindRows(Key).Count() = 0 Then
				
				NameStructure = StringFunctionsClientServer.SplitStringIntoSubstringArray(XDTOPresentation.TemplateName, ".");
				
				If NameStructure.Count() = 2 Then
					
					// This is a common template
					Template = GetCommonTemplate(NameStructure[1]);
					
				ElsIf NameStructure.Count() = 4 Then
					
					// This is a metadata object template
					ObjectManager = CommonUse.ObjectManagerByFullName(NameStructure[0] + "." + NameStructure[1]);
					Template = ObjectManager.GetTemplate(NameStructure[3]);
					
				Else
					Raise StringFunctionsClientServer.SubstituteParametersInString(
						NStr("en = 'Cannot generate a permission for the external component.
							  |Incorrect template name: %1.'"), XDTOPresentation.TemplateName);
				EndIf;
				
				If Template = Undefined Then
					Raise StringFunctionsClientServer.SubstituteParametersInString(
						NStr("en = 'Cannot generate a permission for the external component
							  |included in the %1 template: the template is not found in the configuration.'"), XDTOPresentation.TemplateName);
				EndIf;
				
				If Metadata.FindByFullName(XDTOPresentation.TemplateName).TemplateType <> Metadata.ObjectProperties.TemplateType.BinaryData Then
					Raise StringFunctionsClientServer.SubstituteParametersInString(
						NStr("en = 'Cannot generate a permission for the external component:
							  |The %1 template does not contain binary data.'"), XDTOPresentation.TemplateName);
				EndIf;
				
				TempFile = GetTempFileName("zip");
				Template.Write(TempFile);
				
				Archiver = New ZipFileReader(TempFile);
				DirectoryForUnpacking = GetTempFileName() + "\";
				CreateDirectory(DirectoryForUnpacking);
				
				ManifestFile = "";
				For Each ArchiveItem In Archiver.Items Do
					If Upper(ArchiveItem.Name) = "MANIFEST.XML" Then
						ManifestFile = DirectoryForUnpacking + ArchiveItem.Name;
						Archiver.Extract(ArchiveItem, DirectoryForUnpacking);
					EndIf;
				EndDo;
				
				If IsBlankString(ManifestFile) Then
					Raise StringFunctionsClientServer.SubstituteParametersInString(
						NStr("en = 'Cannot generate a permission for the external component, 
							  |included in the %1 template: the MANIFEST.XML file is not found in the archive.'"), XDTOPresentation.TemplateName);
				EndIf;
				
				ReaderStream = New XMLReader();
				ReaderStream.OpenFile(ManifestFile);
				KitDetails = XDTOFactory.ReadXML(ReaderStream, XDTOFactory.Type("http://v8.1c.ru/8.2/addin/bundle", "bundle"));
				For Each ComponentDetails In KitDetails.component Do
					
					If ComponentDetails.type = "native" Or ComponentDetails.type = "com" Then
						
						ComponentFile = DirectoryForUnpacking + ComponentDetails.path;
						
						Archiver.Extract(Archiver.Items.Find(ComponentDetails.path), DirectoryForUnpacking);
						
						Hashing = New DataHashing(HashFunction.SHA1);
						Hashing.AppendFile(ComponentFile);
						
						HashSum = Hashing.HashSum;
						HashSumAsBase64String = Base64String(HashSum);
						
						Row = Table.Add();
						Row.ModuleType = ModuleProperties.Type;
						Row.ModuleID = ModuleProperties.ID;
						Row.OwnerType = OwnerProperties.Type;
						Row.OwnerID = OwnerProperties.ID;
						Row.TemplateName = XDTOPresentation.TemplateName;
						Row.FileName = ComponentDetails.path;
						Row.HashSum = HashSumAsBase64String;
						
					EndIf;
					
				EndDo;
				
				ReaderStream.Close();
				Archiver.Close();
				
				Try
					DeleteFiles(DirectoryForUnpacking);
				Except
					// No exception processing required
				EndTry;
				
				Try
					DeleteFiles(TempFile);
				Except
					// No exception processing required
				EndTry;
				
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
	
	AddIn = ClusterAdministrationClientServer.AddInProperties();
	AddIn.Name = Manager.TemplateName + "\" + Manager.FileName;
	AddIn.HashSum = Manager.HashSum;
	Profile.AddIns.Add(AddIn);
	
EndProcedure

// Returns a query text for getting the current slice of permissions of the cache
// item.
//
// Parameters:
//  CollapseOwners - Boolean - flag that shows whether the query result must be
//                   collapsed by owners.
//
// Returns:
//  String  query text.
//
Function CurrentSliceQuery(Val CollapseOwners = True) Export
	
	If CollapseOwners Then
		
		Return "SELECT DISTINCT
		        |	Permissions.TemplateName,
		        |	Permissions.FileName,
		        |	Permissions.HashSum,
		        |	Permissions.ModuleType AS ModuleType,
		        |	Permissions.ModuleID AS ModuleID
		        |FROM
		        |	InformationRegister.AllowedAddIns AS Permissions";
		
	Else
		
		Return "SELECT DISTINCT
		        |	Permissions.TemplateName,
		        |	Permissions.FileName,
		        |	Permissions.HashSum,
		        |	Permissions.ModuleType AS ModuleType,
		        |	Permissions.ModuleID AS ModuleID,
		        |	Permissions.OwnerType AS OwnerType,
		        |	Permissions.OwnerID AS OwnerID
		        |FROM
		        |	InformationRegister.AllowedAddIns AS Permissions";
		
	EndIf;
	
EndFunction

// Returns query text for getting permission change delta of the cache item.
//
// Returns:
//  String query text.
//
Function DeltaGettingQuery() Export
	
	Return
		"SELECT DISTINCT
		|	TT_Before.TemplateName,
		|	TT_Before.FileName,
		|	TT_Before.HashSum,
		|	TT_Before.ModuleType,
		|	TT_Before.ModuleID
		|FROM
		|	TT_Before AS TT_Before
		|		LEFT JOIN TT_After AS TT_After
		|			ON TT_Before.ModuleType = TT_After.ModuleType
		|			AND TT_Before.ModuleID = TT_After.ModuleID
		|			AND TT_Before.TemplateName = TT_After.TemplateName
		|WHERE
		|	TT_After.TemplateName IS NULL 
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	TT_After.TemplateName,
		|	TT_After.FileName,
		|	TT_After.HashSum,
		|	TT_After.ModuleType,
		|	TT_After.ModuleID
		|FROM
		|	TT_After AS TT_After
		|		LEFT JOIN TT_Before AS TT_Before
		|			ON TT_After.ModuleType = TT_Before.ModuleType
		|			AND TT_After.ModuleID = TT_Before.ModuleID
		|			AND TT_After.TemplateName = TT_Before.TemplateName
		|WHERE
		|	TT_Before.TemplateName IS NULL ";
	
EndFunction

#EndRegion

#EndIf