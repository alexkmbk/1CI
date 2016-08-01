#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region InternalInterface

// Setting the placement in the report pane.
//
// Parameters:
// Settings       - Collection - is used to set report settings and options.
//                  See ReportOptions.ConfigurationReportOptionSettingsTree() for
//                  details.
// ReportSettings - ValueTreeRow - layout settings for all report options
//                  See "Attributes that can be changed" of the 
//                  ReportOptions.ConfigurationReportOptionSettingsTree() function.
//
// Details:
//  See ReportOptionsOverridable.SetUpReportOptions().
//
// Auxiliary methods:
//  OptionSettings = ReportOptions.OptionDetails(Settings, ReportSettings "<OptionName>");
//  ReportOptions.SetOutputModeInReportPanes(Settings, ReportSettings, True/False);
//  The report can be generated only in this mode.
//
Procedure SetUpReportOptions(Settings, ReportSettings) Export
	
	ReportOptionsModule = CommonUse.CommonModule("ReportOptions");
	
	ReportSettings = ReportOptionsModule.ReportDetails(Settings, Create().Metadata());
	ReportSettings.Details = NStr("en = 'External resources that the application and additional modules use'");
	ReportSettings.DefineFormSettings = True;
	
EndProcedure

// Generates external resource permission presentations by the permission tables.
//
// Parameters:
//  PermissionTables - Structure - See DataProcessors.ExternalResourcePermissionSetup.PermissionTables().
//
// Returns:
//  SpreadsheetDocument - permission presentations.
//
Function ExternalResourcePermissionPresentation(Val PermissionTables) Export
	
	Template = GetTemplate("PermissionPresentations");
	SpreadsheetDocument = New SpreadsheetDocument();
	
	GeneratePermissionPresentation(SpreadsheetDocument, PermissionTables, Template, True);
	
	Return SpreadsheetDocument;
	
EndFunction

#EndRegion

#Region InternalProceduresAndFunctions

// Generates a presentations of external resource permission changes that were made
// during applying requests.
//
// Parameters:
//  AdministrationOperations - ValueTable, see DataProcessors.ExternalResourcePermissionSetup.AdministrationActionsInRequests(),
//  PermissionDelta          - Structure, see DataProcessors.ExternalResourcePermissionSetup.ExternalResourcePermissionChangeDelta(),
//  AsRequired               - Boolean - flag that shows whether the presentation of
//                             terms is "the following resources are required" instead
//                             of "the following resources will be granted."
//
// Returns:
//  SpreadsheetDocument.
//
Function ExternalResourceRequestApplyingResultPresentation(Val AdministrationOperations, Val PermissionDelta, Val AsRequired = False) Export
	
	SpreadsheetDocument = New SpreadsheetDocument();
	FillExternalResourceRequestResultPresentation(SpreadsheetDocument, AdministrationOperations, PermissionDelta);
	Return SpreadsheetDocument;
	
EndFunction

// Fills the passed spreadsheet document with presentations of changes in external
// resource permissions that were made during applying requests.
//
// Parameters:
//  SpreadsheetDocument      - SpreadsheetDocument to be filled. 
//  AdministrationOperations - ValueTable - see DataProcessors.ExternalResourcePermissionSetup.AdministrationActionsInRequests().
//  PermissionDelta          - Structure - see DataProcessors.ExternalResourcePermissionSetup.ExternalResourcePermissionChangeDelta().
//  AsRequired               - Boolean - flag that shows whether the presentation of
//                             terms is "the following resources are required" instead
//                             of "the following resources will be granted."
//
Procedure FillExternalResourceRequestResultPresentation(SpreadsheetDocument, Val AdministrationOperations, Val PermissionDelta, Val AsRequired = False) Export
	
	Template = GetTemplate("PermissionPresentations");
	OffsetArea = Template.GetArea("Offset");
	
	GenerateOperationPresentation(SpreadsheetDocument, Template, AdministrationOperations);
	
	OutputGroups = PermissionDelta.Count() > 1;
	
	For Each ChangeFragment In PermissionDelta Do
		
		Module = ChangeFragment.ExternalModule;
		
		If Module = Catalogs.MetadataObjectIDs.EmptyRef() Then
		
			ModuleDescription = Metadata.Synonym;
			
		Else
			
			Dictionary = SafeModeInternal.ExternalModuleManager(Module).ExternalModuleContainerDictionary();
			ModuleDescription = CommonUse.ObjectAttributeValue(Module, "Description");
			
		EndIf;
		
		Difference = ChangeFragment.Changes;
		
		ItemsToAddCount = DataProcessors.ExternalResourcePermissionSetup.PermissionsInTablesCount(Difference.ToAdd);
		ToDeleteCount = DataProcessors.ExternalResourcePermissionSetup.PermissionsInTablesCount(Difference.ToDelete);
		
		If ItemsToAddCount > 0 Then
			
			SpreadsheetDocument.Put(OffsetArea);
			
			If AsRequired Then
				HeaderArea = Template.GetArea("RequiredPermissionsHeader");
			Else
				HeaderArea = Template.GetArea("NewPermissionsHeader");
			EndIf;
			HeaderArea.Parameters.Description = ModuleDescription;
			If Module <> Catalogs.MetadataObjectIDs.EmptyRef() Then
				HeaderArea.Parameters.Module = Module;
			EndIf;
			SpreadsheetDocument.Put(HeaderArea);
			
			If OutputGroups Then
				SpreadsheetDocument.StartRowGroup();
			EndIf;
			
			SpreadsheetDocument.Put(OffsetArea);
			
			GeneratePermissionPresentation(SpreadsheetDocument, Difference.ToAdd, Template, AsRequired);
			
			If OutputGroups Then
				SpreadsheetDocument.EndRowGroup();
				SpreadsheetDocument.PutHorizontalPageBreak();
			EndIf;
			
		EndIf;
		
		If ToDeleteCount > 0 Then
			
			If OutputGroups Then
				SpreadsheetDocument.StartRowGroup();
			EndIf;
			
			HeaderArea = Template.GetArea("PermissionsToDeleteHeader");
			HeaderArea.Parameters.Description = ModuleDescription;
			SpreadsheetDocument.Put(HeaderArea);
			GeneratePermissionPresentation(SpreadsheetDocument, Difference.ToDelete, Template, AsRequired);
			
			If OutputGroups Then
				SpreadsheetDocument.EndRowGroup();
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Generates presentations of external resource permission administration operations.
//
// Parameters:
//  SpreadsheetDocument      - SpreadsheetDocument where operation presentations are
//                             output.
//  Template                 - SpreadsheetDocument retrieved from the template of the 
//                             PermissionPresentations report.
//  AdministrationOperations - ValueTable - see DataProcessors.ExternalResourcePermissionSetup.AdministrationActionsInRequests().
//
Procedure GenerateOperationPresentation(SpreadsheetDocument, Val Template, Val AdministrationOperations)
	
	For Each Details In AdministrationOperations Do
		
		If Details.Operation = Enums.OperationsWithPermissionSets.Delete Then
			
			IsConfigurationProfile = (Details.ExternalModule = Catalogs.MetadataObjectIDs.EmptyRef());
			
			If IsConfigurationProfile Then
				
				ModuleDescription = Metadata.Synonym;
				
			Else
				
				Dictionary = SafeModeInternal.ExternalModuleManager(Details.ExternalModule).ExternalModuleContainerDictionary();
				ModuleDescription = CommonUse.ObjectAttributeValue(Details.ExternalModule, "Description");
				
			EndIf;
			
			Region = Template.GetArea("SecurityProfileDeletionHeader");
			Region.Parameters["Description"] = ModuleDescription;
			
			SpreadsheetDocument.Put(Region);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Generates permission presentations.
//
// Parameters:
//  SpreadsheetDocument  - SpreadsheetDocument where operation presentations are
//                         output.
//  PermissionSets       - Structure - see DataProcessors.ExternalResourcePermissionSetup.PermissionTables(),
//  Template             - SpreadsheetDocument retrieved from the template of the 
//                         PermissionPresentations report.
//  AsRequired - Boolean - flag that shows whether the presentation of terms is "the
//                         following resources are required" instead of "the following
//                         resources will be granted."
//
Procedure GeneratePermissionPresentation(SpreadsheetDocument, Val PermissionSets, Val Template, Val AsRequired = False)
	
	TemplateAreas = TemplateAreas(AsRequired);
	
	OffsetArea = Template.GetArea("Offset");
	
	For Each KeyAndValue In PermissionSets Do
		
		PermissionType = KeyAndValue.Key;
		Permissions = KeyAndValue.Value;
		
		If Permissions.Count() > 0 Then
			
			GroupAreaName = TemplateAreas.Find(PermissionType, "PermissionType").Group;
			GroupArea = Template.GetArea(GroupAreaName);
			FillPropertyValues(GroupArea.Parameters, New Structure("Count", Permissions.Count()));
			SpreadsheetDocument.Put(GroupArea);
			
			SpreadsheetDocument.StartRowGroup(PermissionType, True);
			
			HeaderNameArea = TemplateAreas.Find(PermissionType, "PermissionType").TableHeader;
			HeaderArea = Template.GetArea(HeaderNameArea);
			SpreadsheetDocument.Put(HeaderArea);
			
			RowAreaName = TemplateAreas.Find(PermissionType, "PermissionType").TableRow;
			RowArea = Template.GetArea(RowAreaName);
			
			For Each Permission In Permissions Do
				
				If PermissionType = "FileSystemAccess" Then
					
					If Permission.Address = "/temp" Then
						Permission.Address = NStr("en = 'Temporary directory'");
					EndIf;
					
					If Permission.Address = "/bin" Then
						Permission.Address = NStr("en = '1C:Enterprise server installation directory'");
					EndIf;
					
				EndIf;
				
				FillPropertyValues(RowArea.Parameters, Permission);
				SpreadsheetDocument.Put(RowArea);
				
			EndDo;
			
			SpreadsheetDocument.EndRowGroup();
			
			SpreadsheetDocument.Put(OffsetArea);
			
		EndIf;
		
	EndDo;
	
EndProcedure
 
// Returns a map of permission types and PermissionPresentations template areas.
//
// Returns:
//  ValueTable with the following fields:
//   * PermissionsType - String - XDTO type name describing the permission type.
//                       The type must be defined in the
//                       {http://www.1c.ru/1cFresh/Application/Permissions/a.b.c.d}
//                       package,
//   * Group           - String - name of the template area to be used as a group for 
//                       the permission type.
//   * TableHeader     - String - name of the template area to be used as a table  
//                       header for the permission type.
//   * TableRow        - String - name of the template area to be used as a table  
//                       row for the permission type.
//
Function TemplateAreas(Val AsRequired)
	
	Result = New ValueTable();
	Result.Columns.Add("PermissionType", New TypeDescription("String"));
	Result.Columns.Add("Group", New TypeDescription("String"));
	Result.Columns.Add("TableHeader", New TypeDescription("String"));
	Result.Columns.Add("TableRow", New TypeDescription("String"));
	
	NewRow = Result.Add();
	NewRow.PermissionType = "FileSystemAccess";
	If AsRequired Then
		NewRow.Group = "RequirementsFileSystemDirectories";
	Else
		NewRow.Group = "PermissionsFileSystemDirectories";
	EndIf;
	NewRow.TableHeader = "FileSystemDirectoriesTableHeader";
	NewRow.TableRow = "FileSystemDirectoriesTableRow";
	
	NewRow = Result.Add();
	NewRow.PermissionType = "CreateComObject";
	If AsRequired Then
		NewRow.Group = "RequirementsCOMObjects";
	Else
		NewRow.Group = "PermissionsCOMObjects";
	EndIf;
	NewRow.TableHeader = "COMObjectsTableHeader";
	NewRow.TableRow = "COMObjectsTableRow";
	
	NewRow = Result.Add();
	NewRow.PermissionType = "AttachAddin";
	If AsRequired Then
		NewRow.Group = "RequirementsAddIns";
	Else
		NewRow.Group = "PermissionsAddIns";
	EndIf;
	NewRow.TableHeader = "AddInsTableHeader";
	NewRow.TableRow = "AddInsTableRow";
	
	NewRow = Result.Add();
	NewRow.PermissionType = "RunApplication";
	If AsRequired Then
		NewRow.Group = "OSApplicationRequirements";
	Else
		NewRow.Group = "OSApplicationPermissions";
	EndIf;
	NewRow.TableHeader = "OSApplicationsTableHeader";
	NewRow.TableRow = "OSApplicationsTableRow";
	
	NewRow = Result.Add();
	NewRow.PermissionType = "InternetResourceAccess";
	If AsRequired Then
		NewRow.Group = "RequirementsInternetResources";
	Else
		NewRow.Group = "PermissionsInternetResources";
	EndIf;
	NewRow.TableHeader = "InternetResourcesTableHeader";
	NewRow.TableRow = "InternetResourcesTableRow";
	
	NewRow = Result.Add();
	If AsRequired Then
		NewRow.Group = "RequirementsPrivilegedMode";
	Else
		NewRow.Group = "PermissionsPrivilegedMode";
	EndIf;
	NewRow.PermissionType = "ExternalModulePrivilegedModeAllowed";
	NewRow.TableHeader = "PrivilegedModeTableHeader";
	NewRow.TableRow = "PrivilegedModeTableRow";
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf