////////////////////////////////////////////////////////////////////////////////////////////////
//                                          FORM USAGE                                       //
//
// The form is intended for selecting configuration metadata objects and passing them to a
// calling environment.
//
// Call parameters:
//  MetadataObjectToSelectCollection - ValueList - metadata object type filter, that can be
//                                     selected.
//                                     For example:
// 				                              FilterByReferenceMetadata = New ValueList;
// 				                              FilterByReferenceMetadata.Add("Catalogs");
// 				                              FilterByReferenceMetadata.Add("Documents");
//                                     In this example the form allows to select only Catalogs
//                                     and Documents metadata objects.
// SelectedMetadataObjects           - ValueList - metadata objects that are already selected.
//                                     In metadata tree this objects will be marked by flags.
//                                     It can be useful for setting up default selected metadata 
//                                     objects or for changing the list of selected ones.
// ParentSubsystems                  - ValueList - only child subsystems of this subsystems
//                                     will be displayed on the form.
// SubsystemsWithCIOnly              - Boolean - flag that shows whether there will be only  
//                                     included in the command interface subsystems in the list.
// SelectSingle                      - Boolean - flag that shows whether only one metadata
//                                     object will be selected.
//                                     In this case multiselect is not allowed, furthermore,
//                                     double-clicking a row with object makes selection;
// InitialSelectionValue             - String - full name of metadata where the list will be 
//                                     positioned during the form opening.
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to guarantee that the form will be received if the SelfTest parameter is passed.
	If Parameters.Property("SelfTest") Then
		Return;
	EndIf;
	
	SelectedMetadataObjects.LoadValues(Parameters.SelectedMetadataObjects.UnloadValues());
	
	If Parameters.FilterByMetadataObjects.Count() > 0 Then
		Parameters.MetadataObjectToSelectCollection.Clear();
		For Each MetadataObjectFullName In Parameters.FilterByMetadataObjects Do
			BaseTypeName = CommonUse.BaseTypeNameByMetadataObject(Metadata.FindByFullName(MetadataObjectFullName));
			If Parameters.MetadataObjectToSelectCollection.FindByValue(BaseTypeName) = Undefined Then
				Parameters.MetadataObjectToSelectCollection.Add(BaseTypeName);
			EndIf;
		EndDo;
	EndIf;
	
	If Parameters.Property("SubsystemsWithCIOnly") And Parameters.SubsystemsWithCIOnly Then
		SubsystemsList = Metadata.Subsystems;
		FillSubsystemList(SubsystemsList);
		SubsystemsWithCIOnly  = True;
	EndIf;
	
	If Parameters.Property("SelectSingle", SelectSingle) And SelectSingle Then		
		Items.Check.Visible = False;
	EndIf;
 
 	If Parameters.Property("Title") Then

		AutoTitle = False;
		Title = Parameters.Title;
 	EndIf;
	
	Parameters.Property("InitialSelectionValue", InitialSelectionValue);
	
	MetadataObjectTreeFill();
	
	If Parameters.ParentSubsystems.Count()> 0 Then
		Items.MetadataObjectTree.InitialTreeView = InitialTreeView.ExpandAllLevels;
	EndIf;
	
	SetInitialCollectionMarkValues(MetadataObjectTree);
			
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// Setting initial selection value
	If CurrentRowIDOnOpen > 0 Then
		
		Items.MetadataObjectTree.CurrentRow = CurrentRowIDOnOpen;
		
	EndIf;
	
EndProcedure

#EndRegion


#Region FormHeaderItemEventHandlers

// Clicking the Check field of the form tree event handler
&AtClient
Procedure CheckOnChange(Item)

	CurrentData = CurrentItem.CurrentData;
	If CurrentData.Check = 2 Then
		CurrentData.Check = 0;
	EndIf;
	SetNestedItemMarks(CurrentData);
	SetParentItemMarks(CurrentData);

EndProcedure

#EndRegion

#Region MetadataObjectTreeFormTableItemEventHandlers
 
&AtClient
Procedure MetadataObjectTreeChoice(Item, SelectedRow, Field, StandardProcessing)

	If SelectSingle Then
		
		ChooseExecute();
		
	EndIf;
	
EndProcedure

#EndRegion


#Region FormCommandHandlers

&AtClient
Procedure ChooseExecute()
	
	If SelectSingle Then
		
		CurData = Items.MetadataObjectTree.CurrentData;
		If CurData <> Undefined
			And CurData.IsMetadataObject Then
			
			SelectedMetadataObjects.Clear();
			SelectedMetadataObjects.Add(CurData.FullName);
			
		Else
			
			Return;
			
		EndIf;
	Else
		
		SelectedMetadataObjects.Clear();
		
		DataGet();
		
	EndIf;
	Notify("MetadataObjectSelection", SelectedMetadataObjects, Parameters.UUIDSource);
	
	Close();
	
EndProcedure

&AtClient
Procedure CloseExecute()
	
	Close();
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure FillSubsystemList(SubsystemsList) 
	For Each Subsystem In SubsystemsList Do
		If Subsystem.IncludeInCommandInterface Then
			SubsystemsWithCommandInterfaceItems.Add(Subsystem.FullName());
		EndIf;	
		
		If Subsystem.Subsystems.Count() > 0 Then
			FillSubsystemList(Subsystem.Subsystems);
		EndIf;
	EndDo;
EndProcedure

// Fills the configuration object value tree.
// If the Parameters.MetadataObjectToSelectCollection value list is not empty, the tree is
// limited by the passed metadata object collection list.
// If metadata objects from the generated tree are found in the 
// Parameters.SelectedMetadataObjects value list, they are marked as selected.
//
&AtServer
Procedure MetadataObjectTreeFill()
	
	MetadataObjectCollections = New ValueTable;
	MetadataObjectCollections.Columns.Add("Name");
	MetadataObjectCollections.Columns.Add("Synonym");
	MetadataObjectCollections.Columns.Add("Picture");
	MetadataObjectCollections.Columns.Add("ObjectPicture");
	MetadataObjectCollections.Columns.Add("IsCommonCollection");
	MetadataObjectCollections.Columns.Add("FullName");

	MetadataObjectCollections.Columns.Add("Parent"); 
	 
	MetadataObjectCollections_NewRow("Subsystems", NStr("en= 'Subsystems'"), 35, 36, True, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("CommonModules", NStr("en= 'Common modules'"), 37, 38, True, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("SessionParameters", NStr("en= 'Session parameters'"), 39, 40, True, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("Roles", NStr("en= 'Roles'"), 41, 42, True, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("ExchangePlans", NStr("en= 'Exchange plans'"), 43, 44, True, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("FilterCriteria", NStr("en= 'Filter criteria'"), 45, 46, True, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("EventSubscriptions", NStr("en= 'Event subscriptions'"), 47, 48, True, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("ScheduledJobs", NStr("en= 'Scheduled jobs'"), 49, 50, True, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("FunctionalOptions", NStr("en= 'Functional options'"), 51, 52, True, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("FunctionalOptionsParameters", NStr("en= 'Functional option parameters'"), 53, 54, True, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("SettingsStorages", NStr("en= 'Settings storages'"), 55, 56, True, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("CommonForms", NStr("en= 'Common forms'"), 57, 58, True, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("CommonCommands", NStr("en= 'Common commands'"), 59, 60, True, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("CommandGroups", NStr("en= 'Commands groups'"), 61, 62, True, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("Interfaces", NStr("en= 'Interfaces'"), 63, 64, True, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("CommonTemplates", NStr("en= 'Common templates'"), 65, 66, True, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("CommonPictures", NStr("en= 'Common pictures'"), 67, 68, True, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("XDTOPackages", NStr("en= 'XDTO packages'"), 69, 70, True, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("WebServices", NStr("en= 'Web services'"), 71, 72, True, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("WSReferences", NStr("en= 'WS references'"), 73, 74, True, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("Styles", NStr("en= 'Styles'"), 75, 76, True, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("Languages", NStr("en= 'Languages'"), 77, 78, True, MetadataObjectCollections);
	
	MetadataObjectCollections_NewRow("Constants", NStr("en= 'Constants'"), PictureLib.Constant, PictureLib.Constant, False, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("Catalogs", NStr("en= 'Catalogs'"), PictureLib.Catalog, PictureLib.Catalog, False, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("Documents", NStr("en= 'Documents'"), PictureLib.Document, PictureLib.DocumentObject, False, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("DocumentJournals", NStr("en= 'Document journals'"), PictureLib.DocumentJournal, PictureLib.DocumentJournal, False, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("Enums", NStr("en= 'Enumerations'"), PictureLib.Enum, PictureLib.Enum, False, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("Reports", NStr("en= 'Reports'"), PictureLib.Report, PictureLib.Report, False, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("DataProcessors", NStr("en= 'Data processors'"), PictureLib.DataProcessor, PictureLib.DataProcessor, False, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("ChartsOfCharacteristicTypes", NStr("en= 'Charts of characteristic types'"), PictureLib.ChartOfCharacteristicTypes, PictureLib.ChartOfCharacteristicTypesObject, False, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("ChartsOfAccounts", NStr("en= 'Charts of accounts'"), PictureLib.ChartOfAccounts, PictureLib.ChartOfAccountsObject, False, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("ChartsOfCalculationTypes", NStr("en= 'Charts of calculation types'"), PictureLib.ChartOfCharacteristicTypes, PictureLib.ChartOfCharacteristicTypesObject, False, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("InformationRegisters", NStr("en= 'Information registers'"), PictureLib.InformationRegister, PictureLib.InformationRegister, False, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("AccumulationRegisters", NStr("en= 'Accumulation registers'"), PictureLib.AccumulationRegister, PictureLib.AccumulationRegister, False, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("AccountingRegisters", NStr("en= 'AccountingRegisters'"), PictureLib.AccountingRegister, PictureLib.AccountingRegister, False, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("CalculationRegisters", NStr("en= 'Calculation registers'"), PictureLib.CalculationRegister, PictureLib.CalculationRegister, False, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("BusinessProcesses", NStr("en= 'Business processes'"), PictureLib.BusinessProcess, PictureLib.BusinessProcessObject, False, MetadataObjectCollections);
	MetadataObjectCollections_NewRow("Tasks", NStr("en= 'Tasks'"), PictureLib.Task, PictureLib.TaskObject, False, MetadataObjectCollections);
	
	// Creating predefined items.
	ItemParameters =  MetadataObjectTreeItemParameters();
	ItemParameters.Name =  Metadata.Name;
	ItemParameters.Synonym = Metadata.Synonym;
	ItemParameters.Picture = 79;
	ItemParameters.Parent = MetadataObjectTree;
	ConfigurationItem = NewTreeRow(ItemParameters);
	
	ItemParameters =  MetadataObjectTreeItemParameters();
	ItemParameters.Name =  "Common";
	ItemParameters.Synonym = "Common";
	ItemParameters.Picture = 0;
	ItemParameters.Parent = ConfigurationItem;
	ItemCommon = NewTreeRow(ItemParameters);
	
	// Filling metadata object tree.
	For Each Row In MetadataObjectCollections Do
		If Parameters.MetadataObjectToSelectCollection.Count() = 0 or
			 Parameters.MetadataObjectToSelectCollection.FindByValue(Row.Name) <> Undefined Then
			 Row.Parent = ?(Row.IsCommonCollection, ItemCommon, ConfigurationItem);

			 AddMetadataObjectTreeItem(Row, ?(Row.Name =  "Subsystems", Metadata.Subsystems, Undefined));
		EndIf;
	EndDo;
	
	If ItemCommon.GetItems().Count() = 0 Then
		ConfigurationItem.GetItems().Delete(ItemCommon);
	EndIf;
	
EndProcedure
 
// Returns a new metadata object tree item parameter structure.
//
// Returns:
//  Structure with the following fields:
//   Name          - String - parent item name.
//   Synonym       - String - parent item synonym.
//   Check         - Boolean - initial mark of the collection or the metadata object.
//   Picture       - Number - parent item picture code.
//   ObjectPicture - Number - subitem picture code.
//   Parent        - reference to the value tree item that is a root of the item to be added.
//
Function  MetadataObjectTreeItemParameters()
	
	Return New  Structure("Name,FullName,Synonym,Check,Picture,ObjectPicture,Parent", "", "", False, 0, 0, Undefined);
	
EndFunction
 
// Adds a new row to the form value tree and fills the full row set from metadata by the passed
// parameter.
// If the Subsystem parameter is filled, the function is called recursively for all child
// subsystems.
// 
// Parameters:
//  Name          - String - parent item name.
//  Synonym       - String - parent item synonym.
//  Check         - Boolean - initial collection or metadata object mark.
//  Picture       - Number - parent item image code.
//  ObjectPicture - Number - subitem image code;
//  Parent        - reference to value tree item that is a root for the adding item.
//  Subsystems    - if it is filled, it contains Metadata.Subsystems value that is an item
//                  collection;
//  Check         - Boolean - flag that shows whether belonging to parent subsystems are
//                  checked. 
// 
// Returns:
//  Metadata object tree row.
//
&AtServer
Function AddMetadataObjectTreeItem(ItemParameters, Subsystems = Undefined, Check = True)
 
	// Checking availability of command interface in tree leaves only
	If Subsystems <> Undefined And Parameters.Property("SubsystemsWithCIOnly") And Not IsBlankString(ItemParameters.FullName) And
		SubsystemsWithCommandInterfaceItems.FindByValue(ItemParameters.FullName) = Undefined Then
		Return Undefined;
	EndIf;
	
	If Subsystems = Undefined Then
		
		If Metadata[ItemParameters.Name].Count() = 0 Then
			
			// There are no metadata objects in the current tree branch. For example, if there are no
			// accounting registers, the Accounting registers root should not be added.
			Return Undefined;
			
		EndIf;
		
		NewRow = NewTreeRow(ItemParameters,  Subsystems <> Undefined And Subsystems <> Metadata.Subsystems);
		
		For Each MetadataCollectionItem In Metadata[ItemParameters.Name] Do
			If Parameters.FilterByMetadataObjects.Count() > 0 
				And Parameters.FilterByMetadataObjects.FindByValue(MetadataCollectionItem.FullName()) = Undefined Then
				Continue;
			EndIf;
 
			ItemParameters =  MetadataObjectTreeItemParameters();
			ItemParameters.Name = MetadataCollectionItem.Name;
			ItemParameters.FullName = MetadataCollectionItem.FullName();
			ItemParameters.Synonym = MetadataCollectionItem.Synonym;
			ItemParameters.ObjectPicture = ItemParameters.ObjectPicture;
			ItemParameters.Parent = NewRow;
			NewTreeRow(ItemParameters, True);
		EndDo;
						
		Return NewRow;
		
	EndIf;		
		
		If Subsystems.Count() = 0 And ItemParameters.Name = "Subsystems" Then
			// If there are no subsystems, the Subsystems root should not be added
			Return Undefined;
		EndIf;
		
		NewRow = NewTreeRow(ItemParameters, Subsystems <> Undefined And Subsystems <> Metadata.Subsystems);
		
		For Each MetadataCollectionItem In Subsystems Do
			
			If Not Check or Parameters.ParentSubsystems.Count() = 0 Or
				
			Parameters.ParentSubsystems.FindByValue(MetadataCollectionItem.Name) <> Undefined Then
		 			
			ItemParameters =  MetadataObjectTreeItemParameters();
			ItemParameters.Name = MetadataCollectionItem.Name;
			ItemParameters.FullName = MetadataCollectionItem.FullName();
			ItemParameters.Synonym = MetadataCollectionItem.Synonym;
			ItemParameters.Picture = ItemParameters.Picture;
			ItemParameters.ObjectPicture = ItemParameters.ObjectPicture;
			ItemParameters.Parent = NewRow;
			AddMetadataObjectTreeItem(ItemParameters,  MetadataCollectionItem.Subsystems, False);
			EndIf;
		EndDo;
	
	Return NewRow;
	
EndFunction

&AtServer
Function NewTreeRow(RowParameters, IsMetadataObject = False)
	
	Collection = RowParameters.Parent.GetItems();
	NewRow                  = Collection.Add();
	NewRow.Name             = RowParameters.Name;
	NewRow.Presentation     = ?(ValueIsFilled(RowParameters.Synonym), RowParameters.Synonym, RowParameters.Name);
	NewRow.Check        = ?(Parameters.SelectedMetadataObjects.FindByValue(RowParameters.FullName) = Undefined, 0, 1);
	NewRow.Picture          = RowParameters.Picture;
	NewRow.FullName         = RowParameters.FullName;
	NewRow.IsMetadataObject = IsMetadataObject;
	
	If NewRow.IsMetadataObject 
		And NewRow.FullName = InitialSelectionValue Then
		CurrentRowIDOnOpen = NewRow.GetID();
	EndIf;
	
	Return NewRow;
	
EndFunction

// Adds a new row to configuration metadata object type value table.
//
// Parameters:
// Name               - metadata object name or metadata object type.
// Synonym            - metadata object synonym.
// Picture            - picture referring to the metadata object or to the metadata object type.
// IsCommonCollection - flag that shows whether the current item contains subitems.
//
&AtServer
Procedure MetadataObjectCollections_NewRow(Name, Synonym, Picture, ObjectPicture, IsCommonCollection, Tab)
	
	NewRow = Tab.Add();
	NewRow.Name               = Name;
	NewRow.Synonym            = Synonym;
	NewRow.Picture            = Picture;
	NewRow.ObjectPicture      = ObjectPicture;
	NewRow.IsCommonCollection = IsCommonCollection;
	
EndProcedure

// Recursively selects/cleans the passed item parent marks.
//
// Parameters:
//  Item - FormDataTreeItemCollection 
//
&AtClient
Procedure SetParentItemMarks(Item)

	Parent = Item.GetParent();
	
	If Parent = Undefined Then
		Return;
	EndIf;
	
	If Not Parent.IsMetadataObject Then
	
		ParentItems = Parent.GetItems();
		If ParentItems.Count() = 0 Then
			Parent.Check = 0;
		ElsIf Item.Check = 2 Then
			Parent.Check = 2;
		Else
			Parent.Check = ItemMarkValues(ParentItems);
		EndIf;

	EndIf;
	
	SetParentItemMarks(Parent);

EndProcedure

&AtClient
Function ItemMarkValues(ParentItems)
	
	HasSelected    = False;
	HasNotSelected = False;
	
	For Each ParentItem In ParentItems Do
		
		If ParentItem.Check = 2 or (HasSelected And HasNotSelected) Then
			HasSelected    = True;
			HasNotSelected = True;
			Break;
		ElsIf ParentItem.IsMetadataObject Then
			HasSelected = HasSelected Or ParentItem.Check;
			HasNotSelected = HasNotSelected Or Not ParentItem.Check;
		Else
			NestedItems = ParentItem.GetItems();
			If NestedItems.Count() = 0 Then
				Continue;
			EndIf;
			NestedItemMarkValue = ItemMarkValues(NestedItems);
			HasSelected = HasSelected Or ParentItem.Check or NestedItemMarkValue;
			HasNotSelected = HasNotSelected Or Not ParentItem.Check Or Not NestedItemMarkValue;
		EndIf;
	EndDo;
	
 	If HasSelected Then

		If HasNotSelected Then
			Return 2;
		Else
			If SubsystemsWithCIOnly Then
				Return 2;
			Else
				Return 1;
			EndIf;
		EndIf;
	Else
		Return 0;
	EndIf;
	
EndFunction

&AtServer
Procedure MarkParentItemsAtServer(Item)

	Parent = Item.GetParent();
	
	If Parent = Undefined Then
		Return;
	EndIf;
	
		ParentItems = Parent.GetItems();
		If ParentItems.Count() = 0 Then
			Parent.Check = 0;
		ElsIf Item.Check = 2 Then
			Parent.Check = 2;
		Else
			Parent.Check = ItemMarkValuesAtServer(ParentItems);
		EndIf;
	
	MarkParentItemsAtServer(Parent);

EndProcedure

&AtServer
Function ItemMarkValuesAtServer(ParentItems)
	
	HasSelected    = False;
	HasNotSelected = False;
	
	For Each ParentItem In ParentItems Do
		
		If ParentItem.Check = 2 or (HasSelected And HasNotSelected) Then
			HasSelected    = True;
			HasNotSelected = True;
			Break;
		ElsIf ParentItem.IsMetadataObject Then
			HasSelected = HasSelected Or ParentItem.Check;
			HasNotSelected = HasNotSelected Or Not ParentItem.Check;
		Else
			NestedItems = ParentItem.GetItems();
			If NestedItems.Count() = 0 Then
				Continue;
			EndIf;
			NestedItemMarkValue = ItemMarkValuesAtServer(NestedItems);
			HasSelected = HasSelected or ParentItem.Check or NestedItemMarkValue;
			HasNotSelected = HasNotSelected or Not ParentItem.Check or Not NestedItemMarkValue;
		EndIf;
	EndDo;
	
	Return ?(HasSelected And HasNotSelected, 2, ?(HasSelected, 1, 0));
	
EndFunction


// Selects a mark of the metadata object collections that does not have metadata objects or
// whose metadata object marks are selected.
//
// Parameters:
//  Item - FormDataTreeItemCollection
// 
 Procedure SetInitialCollectionMarkValues(Parent)

	NestedItems = Parent.GetItems();
	
	For Each  NestedItem In NestedItems Do

		If NestedItem.Check Then
			MarkParentItemsAtServer(NestedItem);
		EndIf;

		SetInitialCollectionMarkValues(NestedItem);
	EndDo;
	
EndProcedure
 
// Recursively selects/clears marks of nested items starting from the passed item.
//
// Parameters:
// Item - FormDataTreeItemCollection.
// 
&AtClient
Procedure SetNestedItemMarks(Item)

	NestedItems = Item.GetItems();
	
	If NestedItems.Count() = 0 Then
		If Not Item.IsMetadataObject Then
			Item.Check = 0;
		EndIf;
	Else
 		For Each NestedItem In NestedItems Do
			If Not SubsystemsWithCIOnly Then
				NestedItem.Check = Item.Check;
			EndIf;
			SetNestedItemMarks(NestedItem);
		EndDo;
	EndIf;
	
EndProcedure

// Fills the selected tree item list. The function recursively scans the item tree and if an 
// item is selected adds its FullName to the selected list.
//
// Parent - FormDataTreeItem.
//
&AtServer
Procedure DataGet(Parent = Undefined)
	
	Parent = ?(Parent = Undefined, MetadataObjectTree, Parent);
	
	ItemCollection = Parent.GetItems();
	
	For Each Item In ItemCollection Do
		If Item.Check = 1 And Not IsBlankString(Item.FullName) Then
			SelectedMetadataObjects.Add(Item.FullName);
		EndIf;
		DataGet(Item);
	EndDo;
	
EndProcedure

#EndRegion