#If Server Or ThickClientOrdinaryApplication Or  ExternalConnection Then


#Region Interface

// Updates catalog data by configuration metadata.
//
// Parameters:
//  HasChanges - Boolean (return value), True is returned if changes were made, otherwise it is 
//               not changed.
//  HasDeleted - Boolean (return value), True is returned if one or more catalog items were
//               marked for deletion, otherwise it is not changed.
//  CheckOnly  - Boolean (return value) - does not make any changes, just set the HasChanges
//               and HasDeleted flags.
//
Procedure UpdateCatalogData(HasChanges = False, HasDeleted = False,  CheckOnly = False) Export

	
	UpdateData(HasChanges, HasDeleted, CheckOnly);
	
EndProcedure

// Is used to export all metadata object IDs to the subordinate DIB nodes if the catalog was
// not included into the DIB before.
// Also can be used to fix catalog data in the DIB nodes.
//
Procedure  RegisterTotalChangeForSubordinateDIBNodes()  Export
	
	CheckForUsage();
	
	If CommonUse.IsSubordinateDIBNode() Then
		Return;
	EndIf;
	
	DIBNodes = New Array;
	For Each ExchangePlan In Metadata.ExchangePlans Do
		If ExchangePlan.DistributedInfobase
		 And ExchangePlan.Content.Contains(Metadata.Catalogs.MetadataObjectIDs)Then
			
		ExchangePlanManager = CommonUse.ObjectManagerByFullName(ExchangePlan.FullName());
		Selection = ExchangePlanManager.Select();
		While Selection.Next() Do
			If Selection.Ref <> ExchangePlanManager.ThisNode() Then
				DIBNodes.Add(Selection.Ref);
			EndIf;
		EndDo;
		EndIf;
	EndDo;
	
	If DIBNodes.Count() > 0 Then
		StandardSubsystemsServer.ExchangePlansManager().RecordChanges(
			DIBNodes, Metadata.Catalogs.MetadataObjectIDs);
	EndIf;
	
EndProcedure
 
// Returns the list of attributes that can be edited
// using the Batch object modification data processor.
// 
Function  BatchProcessingEditableAttributes() Export
	
	EditableAttributes = New Array;
	
	Return EditableAttributes;
	
EndFunction
 
////////////////////////////////////////////////////////////////////////////////
// Data import from file

// Prohibits importing data to the catalog from the "Import data from file" subsystem.
// Batch data import to that catalog is potentially insecure.
//
Function UseDataImportFromFile() Export
	Return False;
EndFunction
 
#EndRegion


#Region InternalInterface
 
// Returns True if verification, update, and replacement of duplicates finished.
//
// Parameters:
// Message - Boolean - if True is passed, an error exception is raised when the not updated
//           application parameters are called.
//
Function DataUpdated(Message = False) Export
	
	If Message Then
		Cancel = Undefined;
	Else
		Cancel = False;
	EndIf;
	
	StandardSubsystemsServer.CheckIfApplicationParametersUpdated(
		"BaseFunctionalityParameters", "MetadataObjectIDs",  Cancel);
	
	Return Cancel <>  True;
	
EndFunction
 
// Updates catalog data by configuration metadata.
//
// Parameters:
//  HasChanges            - Boolean (return value) - True is returned if changes were saved,
//                          otherwise it is not changed. 
//  HasDeleted            - Boolean (return value) - True is returned if one or more catalog
//                          items were marked for deletion, otherwise it is not changed.
//  CheckOnly             - Boolean (return value) - does not make any changes, just set the
//                          HasChanges, HasDeleted, and HasCriticalChanges flags.
//  HasCriticalChanges    - Boolean (return value) - True is returned if critical changes are
//                          found, otherwise it is not changed.
//                          Critical changes (only for items not marked for deletion):
//                           - FullName attribute is changed,
//                           - new catalog item is added.
//                          In a general case, critical changes require the exclusive mode.
//
//  ListOfCriticalChanges - String (return value) - contains full names of metadata objects
//                          that were added or must be added, and also whose names were changed
//                          or must be changed.
//
Procedure UpdateData(HasChanges = False, HasDeleted = False,  CheckOnly = False,
			HasCriticalChanges = False, ListOfCriticalChanges  = "")  Export
	
	CheckForUsage();
	
	SetPrivilegedMode(True);
	
	HasCurrentChanges = False;
	ReplaceSubordinateNodeDuplicatesFoundOnImport(CheckOnly,  HasCurrentChanges);
	If HasCurrentChanges Then
		HasChanges = True;
	EndIf;
	
	MetadataObjectProperties =  MetadataObjectProperties();
	CatalogManager = CommonUse.ObjectManagerByFullName("Catalog.MetadataObjectIDs");
	
	// Found - the ID is found for the metadata object
	MetadataObjectProperties.Columns.Add("found", New TypeDescription("Boolean"));
	
	// Update order:
	// 1. Renaming metadata objects (taking child subsystems into account).
	// 2. Updating predefined IDs (metadata object collections).
	// 3. Updating IDs of metadata objects that have metadata object key.
	// 4. Updating IDs of metadata objects that do not have metadata object key.
	// 5. While 3 and 4 setting deletion mark of ID duplicates (by full names).
	// 6. Adding new IDs of metadata objects.
	// 7. Updating parents of metadata object IDs and saving updated items.
	
	Lock = New  DataLock;
	LockItem = Lock.Add("Catalog.MetadataObjectIDs");
	LockItem.Mode = DataLockMode.Exclusive;
	
	DisableExclusiveMode = False;
	BeginTransaction();
	Try
		Lock.Lock();
		
		Data = ExportAllIDs();
		Data.Columns.Add("Updated", New TypeDescription("Boolean"));
		Data.Columns.Add("MetadataObject");
		Data.Columns.Delete("NewRef");
		
		If Not CommonUse.IsSubordinateDIBNode() Then
			// Renaming full names before data will be processed (for DIB in the Master node only)
			RenameFullNames(Data);
		EndIf;
		
		MetadataObjectRenamingList = "";
		HasCurrentCriticalChanges = False;
		
		// Processing metadata object IDs
		For Each Properties  In Data Do
			
			// Verifying and updating properties of metadata object collection IDs
			If Properties.IsCollection Then
				CheckUpdateCollectionProperties(Properties);
				Continue;
			EndIf;
			
			MetadataObjectKey = Properties.MetadataObjectKey;
			MetadataObject = MetadataObjectByKey(MetadataObjectKey);
			
			If MetadataObject = Undefined Then
				// If the metadata object has no key, it can be found by the full name only
				MetadataObject =  MetadataFindByFullName(Properties.FullName);
			Else
				// If the metadata object is deleted for restructuring, old ID must be used for the new
				// metadata object and old metadata objects must get new IDs.
				If Upper(Left(MetadataObject.Name, StrLen("Delete"))) = Upper("Delete")
				 And Upper(Left(Properties.Name,  StrLen("Delete"))) <> Upper("Delete") Then
					
					NewMetadataObject =  MetadataFindByFullName(Properties.FullName);
					If NewMetadataObject <> Undefined Then
						MetadataObject =  NewMetadataObject;
						MetadataObjectKey = Undefined; // To update the ID
					EndIf;
				EndIf;
			EndIf;
			
			// If the metadata object is found by key or full name, the metadata object property row
			// must be prepared.
			If MetadataObject <> Undefined Then
				ObjectProperties =  MetadataObjectProperties.Find(MetadataObject.FullName(), "FullName");
				If ObjectProperties = Undefined Then
					MetadataObject = Undefined;
				Else
					Properties.MetadataObject = MetadataObject;
				EndIf;
			EndIf;
			
			If MetadataObject = Undefined Or ObjectProperties.Found Then
				// If the metadata object is not found or found repeatedly, the ID must be marked for deletion
				PropertiesUpdated = False;
				RefreshMarkedForDeletionItemProperties(Properties, PropertiesUpdated, HasDeleted);
				If PropertiesUpdated Then
					Properties.Updated = True;
				EndIf;
			Else
				// Updating properties of existing metadata objects, if changed
				ObjectProperties.Found = True;
				If Properties.Description <> ObjectProperties.Description
				 Or Properties.CollectionOrder <> ObjectProperties.CollectionOrder
				 Or Properties.Name <> ObjectProperties.Name
				 Or Properties.Synonym <> ObjectProperties.Synonym
				 Or Properties.FullName <> ObjectProperties.FullName
				 Or Properties.FullSynonym <> ObjectProperties.FullSynonym
				 Or Properties.WithoutData <> ObjectProperties.WithoutData
				 Or Properties.EmptyRefValue <> ObjectProperties.EmptyRefValue
				 Or Properties.PredefinedDataName <> ""
				 Or Properties.DeletionMark
				 Or MetadataObjectKey = Undefined
				 Or ObjectProperties.WithoutMetadataObjectKey
				 And MetadataObjectKey <> Type("Undefined") Then
					
					If Upper(Properties.FullName) <> Upper(ObjectProperties.FullName) Then
						HasCurrentCriticalChanges = True;
						HasCriticalChanges = True;
						MetadataObjectRenamingList = MetadataObjectRenamingList
							+ ?(ValueIsFilled(MetadataObjectRenamingList), "," + Chars.LF,  "")
							+ Properties.FullName + " ->" +  ObjectProperties.FullName;
					EndIf;
					
					// Setting new properties of the metadata object ID
					FillPropertyValues(Properties, ObjectProperties);
					
					Properties.PredefinedDataName = "";
					
					If MetadataObjectKey = Undefined
					 Or ObjectProperties.WithoutMetadataObjectKey
					 And MetadataObjectKey <> Type("Undefined") Then
						
						Properties.MetadataObjectKey = MetadataObjectKey(ObjectProperties.FullName);
					EndIf;
					
					Properties.DeletionMark = False;
					Properties.Updated =  True;
				EndIf;
			EndIf;
		EndDo;
		
		ListOfNewMetadataObjects = "";
		
		// Adding IDs of new metadata objects
		For Each  ObjectProperties In MetadataObjectProperties.FindRows(New Structure("found", False)) Do
			Properties = Data.Add();
			FillPropertyValues(Properties, ObjectProperties);
			Properties.IsNew = True;
			Properties.Ref = GetRef();
			Properties.DeletionMark = False;
			Properties.MetadataObject = ObjectProperties.MetadataObject;
			Properties.MetadataObjectKey = MetadataObjectKey(Properties.FullName);
			HasCurrentCriticalChanges = True;
			HasCriticalChanges = True;
			ListOfNewMetadataObjects =  ListOfNewMetadataObjects
				+ ?(ValueIsFilled(ListOfNewMetadataObjects), "," +  Chars.LF, "")
				+ ObjectProperties.FullName;
		EndDo;
		
		ListOfCriticalChanges = "";
		If ValueIsFilled(MetadataObjectRenamingList) Then
			ListOfCriticalChanges = NStr("en = 'Renaming metadata object IDs OldFullName -> NewFullName:'")
				+ Chars.LF + MetadataObjectRenamingList + Chars.LF +  Chars.LF;
		EndIf;
		If ValueIsFilled(ListOfNewMetadataObjects) Then
			ListOfCriticalChanges =  ListOfCriticalChanges
				+ NStr("en = 'Adding new metadata objects IDs:'")
				+ Chars.LF + ListOfNewMetadataObjects + Chars.LF;
		EndIf;
		
		If Not (CheckOnly Or  ExclusiveMode())
		 And HasCurrentCriticalChanges Then
			
			CommitTransaction();
			Try
				SetExclusiveMode(True);
			Except
				BeginTransaction();
				Raise;
			EndTry;
			DisableExclusiveMode = True;
			BeginTransaction();
		EndIf;
		
		// Updating metadata object ID parents.
		For Each Properties  In Data Do
			
			If Not  Properties.IsCollection Then
				ObjectProperties =  MetadataObjectProperties.Find(Properties.FullName, "FullName");
				NewParent = EmptyRef();
				
				If ObjectProperties <> Undefined Then
				
					If Not  ValueIsFilled(ObjectProperties.ParentFullName) Then
						// Metadata object collection
						NewParent = ObjectProperties.Parent;
					Else
						// Not a metadata object collection, for example, a subsystem
						ParentDetails = Data.Find(ObjectProperties.ParentFullName, "FullName");
						If ParentDetails <> Undefined Then
							NewParent = ParentDetails.Ref;
						EndIf;
					EndIf;
				EndIf;
				
				If Properties.Parent <> NewParent Then
					Properties.Parent = NewParent;
					Properties.Updated = True;
				EndIf;
			EndIf;
			
			If Properties.IsNew Then
				TableObject = CreateItem();
				TableObject.SetNewObjectRef(Properties.Ref);
				
			ElsIf Properties.Updated Then
				TableObject = Properties.Ref.GetObject();
			Else
				Continue;
			EndIf;
			
			HasCurrentChanges = True;
			HasChanges = True;
			If CheckOnly Then
				CommitTransaction();
				Return;
			EndIf;
			
			FillPropertyValues(TableObject, Properties);
			TableObject.MetadataObjectKey = New ValueStorage(Properties.MetadataObjectKey);
			TableObject.AdditionalProperties.Insert("ExecutingAutomaticCatalogDataUpdate");
			TableObject.Write();
		EndDo;
		
		If ValueIsFilled(ListOfCriticalChanges) Then
			WriteLogEvent(
				NStr("en = 'Metadata object IDs.Critical changes made'",
					CommonUseClientServer.DefaultLanguageCode()),
				EventLogLevel.Information,
				,
				,
				ListOfCriticalChanges,
				EventLogEntryTransactionMode.Transactional);
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		If DisableExclusiveMode Then
			SetExclusiveMode(False);
		EndIf;
		Raise;
	EndTry;
	
	If Not  CheckOnly And Not CommonUseCached.DataSeparationEnabled() Then
		ClientLaunchParameter = SessionParameters.ClientParametersOnServer.Get("LaunchParameter");
		If Find(Lower(ClientLaunchParameter), Lower("RegisterFullMOIDChangeForSubordinateDIBNodes")) > 0  Then
			RegisterTotalChangeForSubordinateDIBNodes();
		EndIf;
	EndIf;
	
	If DisableExclusiveMode Then
		SetExclusiveMode(False);
	EndIf;
	
	If Not  CheckOnly Or Not  HasCurrentChanges Then
		StandardSubsystemsServer.ConfirmApplicationParametersUpdate(
			"BaseFunctionalityParameters", "MetadataObjectIDs");
	EndIf;
	
EndProcedure
 
// Returns catalog attributes that are a natural key for catalog items.
//
// Returns: Array of String -  array of attribute names that are a natural key.
//
Function NaturalKeyFields() Export
	
	Result = New  Array();
	
	Result.Add("FullName");
	
	Return Result;
	
EndFunction
 
// For internal use only.
//
// Parameters:
// Objects - Array of CatalogObject.MetadataObjectIDs to be imported.
//
Procedure ImportDataToSubordinateNode(Objects) Export
	
	CheckForUsage();
	
	If CommonUseCached.DataSeparationEnabled() Then
		// Not supported in the SaaS mode
		Return;
	EndIf;
	
	If Not CommonUse.IsSubordinateDIBNode() Then
		Return;
	EndIf;
	
	Lock = New DataLock;
	LockItem = Lock.Add("Catalog.MetadataObjectIDs");
	LockItem.Mode = DataLockMode.Exclusive;
	
	DisableExclusiveMode = False;
	BeginTransaction();
	Try
		Lock.Lock();
		
		// Preparing the outgoing table with renaming for searching for duplicates
		Data = ExportAllIDs();
		Data.Columns.Add("DuplicateUpdated", New TypeDescription("Boolean"));
		Data.Columns.Add("FullNameLowerCase", New TypeDescription("String"));
		
		// Filtering only those items to import that have differences from the existing ones
		TableOfItemsToImport = New ValueTable;
		TableOfItemsToImport.Columns.Add("Object");
		TableOfItemsToImport.Columns.Add("Ref");
		TableOfItemsToImport.Columns.Add("MetadataObjectByKey");
		TableOfItemsToImport.Columns.Add("MetadataObjectByFullName");
		TableOfItemsToImport.Columns.Add("Matches", New TypeDescription("Boolean"));
		
		For Each Object In Objects Do
			PropertiesOfItemsToImport =  TableOfItemsToImport.Add();
			PropertiesOfItemsToImport.Object = Object;
			
			If ValueIsFilled(Object.Ref) Then
				PropertiesOfItemsToImport.Ref = Object.Ref;
			Else
				PropertiesOfItemsToImport.Ref = Object.GetNewObjectRef();
				If Not  ValueIsFilled(PropertiesOfItemsToImport.Ref) Then
					Raise  StringFunctionsClientServer.SubstituteParametersInString(
						NStr("en = 'Failed to import metadata object IDs.
						 |Cannot import a new item whose reference is not specified:
						 |%1.'"),
						Object.FullName);
				EndIf;
			EndIf;
			
			// Preprocessing
			
			If Not IsCollection(PropertiesOfItemsToImport.Ref) Then
				PropertiesOfItemsToImport.MetadataObjectByKey = MetadataObjectByKey(
					Object.MetadataObjectKey.Get());
				
				PropertiesOfItemsToImport.MetadataObjectByFullName =
					MetadataFindByFullName(Object.FullName);
				
				If PropertiesOfItemsToImport.MetadataObjectByKey = Undefined
				 And PropertiesOfItemsToImport.MetadataObjectByFullName =  Undefined
				 And Object.DeletionMark <> True Then
					// If for some reason the object to be imported is not found in the metadata, it must
					// be marked for deletion.
					Object.DeletionMark = True;
				EndIf;
			EndIf;
			
			If Object.DeletionMark Then
				// Objects marked for deletion cannot have correct full names, hence, to ensure this
				// condition, the update procedure of the marked for deletion object properties are
				// applied before the import.
				RefreshMarkedForDeletionItemProperties(Object);
			EndIf;
			
			Properties = Data.Find(PropertiesOfItemsToImport.Ref, "Ref");
			If Properties <> Undefined
			 And Properties.Description = Object.Description
			 And Properties.Parent = Object.Parent
			 And Properties.CollectionOrder = Object.CollectionOrder
			 And Properties.Name = Object.Name
			 And Properties.Synonym = Object.Synonym
			 And Properties.FullName = Object.FullName
			 And Properties.FullSynonym = Object.FullSynonym
			 And Properties.WithoutData = Object.WithoutData
			 And Properties.EmptyRefValue = Object.EmptyRefValue
			 And Properties.PredefinedDataName = Object.PredefinedDataName
			 And Properties.DeletionMark = Object.DeletionMark
			 And SameMetadataObjectKeys(Properties, Object) Then
			
				PropertiesOfItemsToImport.Matches = True;
			EndIf;
			
			If Properties <> Undefined Then
				Data.Delete(Properties); // No need to rename items to be imported
			EndIf;
		EndDo;
		TableOfItemsToImport.Indexes.Add("Ref");
		
		// Renaming existing items (without those that are imported) for searching for duplicates
		
		RenameFullNames(Data);
		For Each Row In Data Do
			Row.FullNameLowerCase = Lower(Row.FullName);
		EndDo;
		Data.Indexes.Add("MetadataObjectKey");
		Data.Indexes.Add("FullNameLowerCase");
		
		// Preparing objects to be imported and duplicates of existing ones
		
		ObjectsToWrite = New Array;
		FullNamesOfItemsToImport = New Map;
		KeysOfItemsToImport = New Map;
		
		For Each  PropertiesOfItemsToImport In TableOfItemsToImport Do
			Object = PropertiesOfItemsToImport.Object;
			Ref= PropertiesOfItemsToImport.Ref;
			
			If PropertiesOfItemsToImport.Matches Then
				Continue;  // No need to import objects that match exactly
			EndIf;
			
			If IsCollection(Ref) Then
				ObjectsToWrite.Add(Object);
				Continue;
			EndIf;
			
			// Checking whether there are no duplicates among the items to be imported
			
			If FullNamesOfItemsToImport.Get(Lower(Object.FullName)) <> Undefined Then
				Raise  StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en = 'Failed to import metadata object IDs.
					 |Cannot import two items with the same full name:
					 |%1.'"),
					Object.FullName);
			EndIf;
			FullNamesOfItemsToImport.Insert(Lower(Object.FullName));
			
			MetadataObjectKey = Object.MetadataObjectKey.Get();
			If TypeOf(MetadataObjectKey) = Type("Type")
			 And MetadataObjectKey <> Type("Undefined") Then
				
				If KeysOfItemsToImport.Get(MetadataObjectKey) <> Undefined Then
					Raise  StringFunctionsClientServer.SubstituteParametersInString(
						NStr("en = 'Failed to import metadata object IDs.
						 |Cannot import two items with the same metadata object keys:
						 |%1.'"),
						String(MetadataObjectKey));
				EndIf;
				KeysOfItemsToImport.Insert(MetadataObjectKey);
				
				If PropertiesOfItemsToImport.MetadataObjectByKey <>  PropertiesOfItemsToImport.MetadataObjectByFullName  Then
					Raise  StringFunctionsClientServer.SubstituteParametersInString(
						NStr("en = 'Failed to import metadata object IDs.
						 |Cannot import item whose metadata object key
						 |%1 does not correspond with its full name %2.'"),
						String(MetadataObjectKey), Object.FullName);
				EndIf;
				
				If Not  Object.DeletionMark Then
					// Determining duplicates among existing metadata objects by key
					Rows = Data.FindRows(New Structure("MetadataObjectKey",  MetadataObjectKey));
					For Each Row In Rows Do
						
						If Row.Ref <> Ref
						 And TableOfItemsToImport.Find(Row.Ref, "Ref") =  Undefined Then
							
							RefreshMarkedForDeletionItemProperties(Row);
							Row.NewRef = Ref;
							Row.DuplicateUpdated = True;
							// Replacing new references to a duplicate with the new reference specified for the
							// duplicate (if any)
							OldDuplicates = Data.FindRows(New Structure("NewRef", Row.Ref));
							For Each  OldDuplicate In OldDuplicates Do
								RefreshMarkedForDeletionItemProperties(OldDuplicate);
								OldDuplicate.NewRef = Ref;
							EndDo;
						EndIf;
					EndDo;
				EndIf;
			EndIf;
			
			If Not Object.DeletionMark Then
				// Determining duplicates among existing metadata objects by full name
				Rows = Data.FindRows(New Structure("FullNameLowerCase", Lower(Object.FullName)));
				For Each Row In Rows Do
					
					If Row.Ref <> Ref
					 And TableOfItemsToImport.Find(Row.Ref, "Ref") =  Undefined Then
					
						RefreshMarkedForDeletionItemProperties(Row);
						Row.NewRef = Ref;
						Row.DuplicateUpdated = True;
						// Replacing new references to a duplicate with the new reference specified for the
						// duplicate (if any)
						OldDuplicates = Data.FindRows(New Structure("NewRef", Row.Ref));
						For Each  OldDuplicate In OldDuplicates Do
							RefreshMarkedForDeletionItemProperties(OldDuplicate);
							OldDuplicate.NewRef = Ref;
						EndDo;
					EndIf;
				EndDo;
			EndIf;
			
			ObjectsToWrite.Add(Object);
		EndDo;
		
		// Updating duplicates
		Rows = Data.FindRows(New Structure("DuplicateUpdated", True));
		For Each Properties In Rows Do
			DuplicateObject = Properties.Ref.GetObject();
			FillPropertyValues(DuplicateObject, Properties);
			DuplicateObject.MetadataObjectKey = New ValueStorage(Properties.MetadataObjectKey);
			DuplicateObject.DataExchange.Load = True;
			DuplicateObject.Write();
		EndDo;
		
		// Importing objects
		For Each Object In ObjectsToWrite  Do
			Object.DataExchange.Load = True;
			Object.Write();
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure 
 
// For internal use only
Procedure CheckForUsage() Export
	
	If StandardSubsystemsCached.DisableMetadataObjectIDsCatalog() Then
		Raise
			NStr("en = 'The""Metadata object IDs"" catalog is not used.'");
	EndIf;
	
	SetPrivilegedMode(True);
	
	If StandardSubsystemsServer.ExchangePlansManager().MasterNode() = Undefined
	 And ValueIsFilled(CommonUse.ObjectManagerByFullName("Constant.MasterNode").Get())  Then
		
		Raise
			NStr("en = 'The""Metadata object IDs"" catalog cannot be used in the infobase with unconfirmed master node disconnection.
			 |
			 |To reconnect to the master node, start the application and click Reconnect or set the master node in the Master node constant using 1C:Enterprise script.
			 |
			 |To confirm master node disconnection, start the application and click Disconnect or clear the Master node constant using 1C:Enterprise script'");
	EndIf;
	
EndProcedure

#EndRegion 
 
#Region InternalProceduresAndFunctions

// For internal use only
Function MetadataObjectKeyCorrespondsFullName(CurIDProperties) Export
	
	CheckResult = New Structure;
	CheckResult.Insert("NotCorresponds", True);
	CheckResult.Insert("MetadataObjectKey", Undefined);
	
	MetadataObjectKey = CurIDProperties.MetadataObjectKey.Get();
	
	If MetadataObjectKey <> Undefined
	 And MetadataObjectKey <> Type("Undefined") Then
		// Key is set, searching metadata object by the key
		CheckResult.Insert("MetadataObjectKey", MetadataObjectKey);
		MetadataObject = MetadataObjectByKey(MetadataObjectKey);
		If MetadataObject <> Undefined Then
			CheckResult.NotCorresponds = MetadataObject.FullName() <> CurIDProperties.FullName;
		EndIf;
	Else
		// Key is not set, searching metadata object by the full name
		MetadataObject = Metadata.FindByFullName(CurIDProperties.FullName);
		If MetadataObject = Undefined Then
			// Possible, collection is set
 		Row = StandardSubsystemsCached.MetadataObjectCollectionProperties().Find(CurIDProperties.Ref, "CollectionID");	
  		If Row <> Undefined Then
				MetadataObject = Metadata[Row.Name];
				CheckResult.NotCorresponds = Row.Name <> CurIDProperties.FullName;
			EndIf;
		Else
			CheckResult.NotCorresponds = False;
		EndIf;
	EndIf;
	
	CheckResult.Insert("MetadataObject", MetadataObject);
	
	Return CheckResult;
	
EndFunction
 
 // For internal use only

Function FullNameUsed(FullName, ExceptID = Undefined) Export
	
	Query = New  Query;
	Query.SetParameter("FullName", FullName);
	Query.SetParameter("Ref",  ExceptID);
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS TrueValue
	|In
	|	Catalog.MetadataObjectIDs AS MetadataObjectIDs
	|Where
	|	MetadataObjectIDs.Ref <> &Ref
	|	And MetadataObjectIDs.FullName = &FullName";
	
	Return Not  Query.Execute().IsEmpty();
	
EndFunction
 
// For internal use only.
// FullName in the object must be set correctly.
//
Procedure UpdateIDProperties(Object) Export
	
	FullName = Object.FullName;
	
	// Restoring old values
	If ValueIsFilled(Object.Ref) Then
		OldValues = CommonUse.ObjectAttributeValues(
			Object.Ref,
			"Description,
			|CollectionOrder,
			|Name,
			|FullName,
			|Synonym,
			|FullSynonym,
			|WithoutData,
			|EmptyRefValue,
			|MetadataObjectKey");
		FillPropertyValues(Object, OldValues);
	EndIf;
	
	MetadataObject =  MetadataFindByFullName(FullName);
	
	If MetadataObject = Undefined Then
		Object.DeletionMark = True;
		Object.Parent = EmptyRef();
		Object.Description = InsertQuestionMark(Object.Description);
		Object.Name =  InsertQuestionMark(Object.Name);
		Object.Synonym = InsertQuestionMark(Object.Synonym);
		Object.FullName = InsertQuestionMark(Object.FullName);
		Object.FullSynonym = InsertQuestionMark(Object.FullSynonym);
		Object.EmptyRefValue = Undefined;
		
		If TypeOf(Object) <> Type("FormDataStructure") Then
			Object.MetadataObjectKey = Undefined;
		EndIf;
	Else
		Object.DeletionMark = False;
		
		FullName = MetadataObject.FullName();
		DotPosition = Find(FullName, ".");
		BaseTypeName = Left(FullName, DotPosition -1);
		
		CollectionProperties = StandardSubsystemsCached.MetadataObjectCollectionProperties();
		Filter = New Structure("SingularName", BaseTypeName);
		Rows = CollectionProperties.FindRows(Filter);
		
		MetadataObjectProperties = MetadataObjectProperties(CollectionProperties.Copy(Rows));
		ObjectProperties = MetadataObjectProperties.Find(FullName, "FullName");
		
		FillPropertyValues(Object, ObjectProperties);
		
		If TypeOf(Object) <> Type("FormDataStructure") Then
			MetadataObjectKey = Object.MetadataObjectKey.Get();
			If MetadataObjectKey = Undefined
			 Or ObjectProperties.WithoutMetadataObjectKey
			 And MetadataObjectKey <> Type("Undefined") Then
				
				Object.MetadataObjectKey = New ValueStorage(MetadataObjectKey(ObjectProperties.FullName));
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure 
 
// For internal use only

Function CannotChangeFullName(Object) Export
	
	If IsCollection(Object.Ref) Then
		Return True;
	EndIf;
	
	DotPosition = Find(Object.FullName, ".");
	BaseTypeName = Left(Object.FullName, DotPosition - 1);
	
	CollectionProperties = StandardSubsystemsCached.MetadataObjectCollectionProperties(
		).Find(BaseTypeName, "SingularName");
	
	If CollectionProperties <> Undefined
	 And Not CollectionProperties.WithoutMetadataObjectKey Then
		
		Return True;
	EndIf;
	
	Return False;
	
EndFunction 
 
// For internal use only
Function  TableOfRenamingForCurrentVersion() Export
	
	TableOfRenaming = New ValueTable;
	TableOfRenaming.Columns.Add("LibraryOrder", New TypeDescription("Number"));
	TableOfRenaming.Columns.Add("VersionPart1", New TypeDescription("Number"));
	TableOfRenaming.Columns.Add("VersionPart2", New TypeDescription("Number"));
	TableOfRenaming.Columns.Add("VersionPart3", New TypeDescription("Number"));
	TableOfRenaming.Columns.Add("VersionPart4", New TypeDescription("Number"));
	TableOfRenaming.Columns.Add("AdditionOrder", New TypeDescription("Number"));
	TableOfRenaming.Columns.Add("OldFullName", New TypeDescription("String"));
	TableOfRenaming.Columns.Add("NewFullName", New TypeDescription("String"));
	
	CollectionsWithoutKey = New Map;
	
	Filter = New Structure("WithoutMetadataObjectKey", True);
	
	CollectionWithoutMetadataObjectKey =
		StandardSubsystemsCached.MetadataObjectCollectionProperties().FindRows(Filter);
	
	For Each Row In CollectionWithoutMetadataObjectKey Do
		CollectionsWithoutKey.Insert(Upper(Row.SingularName), Row.SingularName);
	EndDo;
	
	Total = New  Structure;
	Total.Insert("Table", TableOfRenaming);
	Total.Insert("CollectionsWithoutKey", CollectionsWithoutKey);
	Total.Insert("LibraryVersions", New Map);
	Total.Insert("LibrariesOrder", New Map);
	
	CommonUseOverridable.RenamedMetadataObjectsOnAdd(Total);
	CommonUseOverridable.RenamedMetadataObjectsOnAdd(Total);
	
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.BaseFunctionality\RenamedMetadataObjectsOnAdd");
	
	For Each Handler In EventHandlers Do
		Handler.Module.RenamedMetadataObjectsOnAdd(Total);
	EndDo;
	
	TableOfRenaming.Sort(
		"LibraryOrder ASC,
		|VersionPart1 ASC,
		|VersionPart2 ASC,
		|VersionPart3 ASC,
		|VersionPart4 ASC,
		|AdditionOrder ASC");
	
 Return TableOfRenaming; 
	
EndFunction 
 
 // For internal use only

Function MetadataObjectCollectionProperties() Export
	
	MetadataObjectCollectionProperties = New ValueTable;
	MetadataObjectCollectionProperties.Columns.Add("Name",  New TypeDescription("String",, New StringQualifiers(50)));
	MetadataObjectCollectionProperties.Columns.Add("SingularName", New TypeDescription("String",,  New StringQualifiers(50)));
	MetadataObjectCollectionProperties.Columns.Add("Synonym",  New TypeDescription("String",, New StringQualifiers(255)));
	MetadataObjectCollectionProperties.Columns.Add("SingularSynonym", New TypeDescription("String",,  New StringQualifiers(255)));
	MetadataObjectCollectionProperties.Columns.Add("CollectionOrder", New TypeDescription("Number"));
	MetadataObjectCollectionProperties.Columns.Add("WithoutData", New TypeDescription("Boolean"));
	MetadataObjectCollectionProperties.Columns.Add("WithoutMetadataObjectKey", New TypeDescription("Boolean"));
	MetadataObjectCollectionProperties.Columns.Add("CollectionID", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	MetadataObjectCollectionProperties.Columns.Add("ID", New TypeDescription("String",,  New StringQualifiers(36)));
	
	// Constants
	Row = MetadataObjectCollectionProperties.Add();
	Row.ID              = "627a6fb8-872a-11e3-bb87-005056c00008";
	Row.Name            = "Constants";
	Row.Synonym         = NStr("en = 'Constants'");
	Row.SingularName    = "Constant";
	Row.SingularSynonym = NStr("en = 'Constant'");
	
	// Subsystems
	Row = MetadataObjectCollectionProperties.Add();
	Row.ID              = "cdf5ac50-08e8-46af-9a80-4e63fd4a88ff";
	Row.Name            = "Subsystems";
	Row.Synonym         = NStr("en = 'Subsystems'");
	Row.SingularName    = "Subsystem";
	Row.SingularSynonym = NStr("en = 'Subsystem'");
	Row.WithoutData     = True;
	Row.WithoutMetadataObjectKey = True;
	
	// Roles
	Row = MetadataObjectCollectionProperties.Add();
	Row.ID              = "115c4f55-9c20-4e86-a6d0-d0167ec053a1";
	Row.Name            = "Roles";
	Row.Synonym         = NStr("en = 'Roles'");
	Row.SingularName    = "Role";
	Row.SingularSynonym = NStr("en = 'Role'");
	Row.WithoutData     = True;
	Row.WithoutMetadataObjectKey = True;
	
	// ExchangePlans
	Row = MetadataObjectCollectionProperties.Add();
	Row.ID              = "269651e0-4b06-4f9d-aaab-a8d2b6bc6077";
	Row.Name            = "ExchangePlans";
	Row.Synonym         = NStr("en = 'Exchange plans'");
	Row.SingularName    = "ExchangePlan";
	Row.SingularSynonym = NStr("en = 'Exchange plan'");
	
	// Catalogs
	Row = MetadataObjectCollectionProperties.Add();
	Row.ID              = "ede89702-30f5-4a2a-8e81-c3a823b7e161";
	Row.Name            = "Catalogs";
	Row.Synonym         = NStr("en = 'Catalogs'");
	Row.SingularName    = "Catalog";
	Row.SingularSynonym = NStr("en = 'Catalog'");
	
	// Documents
	Row = MetadataObjectCollectionProperties.Add();
	Row.ID                 = "96c6ab56-0375-40d5-99a2-b83efa3dac8b";
	Row.Name               = "Documents";
	Row.Synonym            = NStr("en = 'Documents'");
	Row.SingularName       = "Document";
	Row.SingularSynonym = NStr("en = 'Document'");
	
	// DocumentJournals
	Row = MetadataObjectCollectionProperties.Add();
	Row.ID              = "07938234-e29b-4cff-961a-9af07a4c6185";
	Row.Name            = "DocumentJournals";
	Row.Synonym         = NStr("en = 'Document journals'");
	Row.SingularName    = "DocumentJournal";
	Row.SingularSynonym = NStr("en = 'Document journal'");
	Row.WithoutData     = True;
	
	// Reports
	Row = MetadataObjectCollectionProperties.Add();
	Row.ID              = "706cf832-0ae5-45b5-8a4a-1f251d054f3b";
	Row.Name            = "Reports";
	Row.Synonym         = NStr("en = 'Reports'");
	Row.SingularName    = "Report";
	Row.SingularSynonym = NStr("en = 'Report'");
	Row.WithoutData     = True;
	
	// DataProcessors
	Row = MetadataObjectCollectionProperties.Add();
	Row.ID              = "ae480426-487e-40b2-98ba-d207777449f3";
	Row.Name            = "DataProcessors";
	Row.Synonym         = NStr("en = 'Data processors'");
	Row.SingularName    = "DataProcessor";
	Row.SingularSynonym = NStr("en = 'Data processor");
	Row.WithoutData     = True;
	
	// ChartsOfCharacteristicTypes
	Row = MetadataObjectCollectionProperties.Add();
	Row.ID              = "8b5649b9-cdd1-4698-9aac-12ba146835c4";
	Row.Name            = "ChartsOfCharacteristicTypes";
	Row.Synonym         = NStr("en = 'Charts of characteristic types'");
	Row.SingularName    = "ChartOfCharacteristicTypes";
	Row.SingularSynonym = NStr("en = 'Chart of characteristic types'");
	
	// ChartsOfAccounts
	Row = MetadataObjectCollectionProperties.Add();
	Row.ID              = "4295af27-543f-4373-bcfc-c0ace9b7620c";
	Row.Name            = "ChartsOfAccounts";
	Row.Synonym         = NStr("en = 'Charts of accounts'");
	Row.SingularName    = "ChartOfAccounts";
	Row.SingularSynonym = NStr("en = 'Chart of accounts'");
	
	// ChartsOfCalculationTypes
	Row = MetadataObjectCollectionProperties.Add();
	Row.ID              = "fca3e7e1-1bf1-49c8-9921-aafb4e787c75";
	Row.Name            = "ChartsOfCalculationTypes";
	Row.Synonym         = NStr("en = 'Charts of calculation types'");
	Row.SingularName    = "ChartOfCalculationTypes";
	Row.SingularSynonym = NStr("en = 'Chart of calculation types'");
	
	// InformationRegisters
	Row = MetadataObjectCollectionProperties.Add();
	Row.ID              = "d7ecc1e9-c068-44dd-83c2-1323ec52dbbb";
	Row.Name            = "InformationRegisters";
	Row.Synonym         = NStr("en = 'Information registers'");
	Row.SingularName    = "InformationRegister";
	Row.SingularSynonym = NStr("en = 'Information register'");
	
	// AccumulationRegisters
	Row = MetadataObjectCollectionProperties.Add();
	Row.ID              = "74083488-b01e-4441-84a6-c386ce88cdb5";
	Row.Name            = "AccumulationRegisters";
	Row.Synonym         = NStr("en = 'Accumulation registers'");
	Row.SingularName    = "AccumulationRegister";
	Row.SingularSynonym = NStr("en = 'Accumulation register'");
	
	// AccountingRegisters
	Row = MetadataObjectCollectionProperties.Add();
	Row.ID              = "9a0d75ff-0eda-454e-b2b7-d2412ffdff18";
	Row.Name            = "AccountingRegisters";
	Row.Synonym         = NStr("en = 'Accounting registers'");
	Row.SingularName    = "AccountingRegister";
	Row.SingularSynonym = NStr("en = 'Accounting register'");
	
	// CalculationRegisters
	Row = MetadataObjectCollectionProperties.Add();
	Row.ID              = "f330686a-0acf-4e26-9cda-108f1404687d";
	Row.Name            = "CalculationRegisters";
	Row.Synonym         = NStr("en = 'Calculation registers'");
	Row.SingularName    = "CalculationRegister";
	Row.SingularSynonym = NStr("en = 'Calculation register'");
	
	// BusinessProcesses
	Row = MetadataObjectCollectionProperties.Add();
	Row.ID              = "a8cdd0e0-c27f-4bf0-9718-10ec054dc468";
	Row.Name            = "BusinessProcesses";
	Row.Synonym         = NStr("en = 'Business processes'");
	Row.SingularName    = "BusinessProcess";
	Row.SingularSynonym = NStr("en = 'Business process'");
	
	// Tasks
	Row = MetadataObjectCollectionProperties.Add();
	Row.ID              = "8d9153ad-7cea-4e25-9542-a557ee59fd16";
	Row.Name            = "Tasks";
	Row.Synonym         = NStr("en = 'Tasks'");
	Row.SingularName    = "Task";
	Row.SingularSynonym = NStr("en = 'Task'");
	
	For Each Row In MetadataObjectCollectionProperties Do
		Row.CollectionOrder = MetadataObjectCollectionProperties.IndexOf(Row);
		Row.CollectionID = GetRef(New UUID(Row.ID));
	EndDo;
	
	MetadataObjectCollectionProperties.Indexes.Add("CollectionID");
	
	Return MetadataObjectCollectionProperties;
	
EndFunction 
 
// For internal use only

Function IsCollection(Ref) Export
	
	Return StandardSubsystemsCached.MetadataObjectCollectionProperties(
		).Find(Ref, "CollectionID") <> Undefined;
	
EndFunction  
 
Function ExportAllIDs()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	IDs.Ref,
	|	IDs.PredefinedDataName AS PredefinedDataName,
	|	IDs.Parent,
	|	IDs.DeletionMark,
	|	IDs.Description,
	|	IDs.CollectionOrder,
	|	IDs.Name,
	|	IDs.Synonym,
	|	IDs.FullName,
	|	IDs.FullSynonym,
	|	IDs.WithoutData,
	|	IDs.EmptyRefValue,
	|	IDs.MetadataObjectKey AS KeyStorage,
	|	IDs.NewRef
	|FROM
	|	Catalog.MetadataObjectIDs AS IDs";
	Data = Query.Execute().Unload();
	Data.Columns.Add("MetadataObjectKey");
	Data.Columns.Add("WithoutMetadataObjectKey", New TypeDescription("Boolean"));
	Data.Columns.Add("IsCollection", New TypeDescription("Boolean"));
	Data.Columns.Add("IsNew", New TypeDescription("Boolean"));
	
	// Ordering IDs before processing
	For Each Row In Data Do
		If TypeOf(Row.KeyStorage) = Type("ValueStorage") Then
			Row.MetadataObjectKey = Row.KeyStorage.Get();
		Else
			Row.MetadataObjectKey = Undefined;
		EndIf;
		
		Row.WithoutMetadataObjectKey = Row.MetadataObjectKey = Undefined
		 Or Row.MetadataObjectKey = Type("Undefined");
	EndDo;
	
	Data.Indexes.Add("Ref");
	Data.Indexes.Add("FullName");
	
	CollectionProperties =  StandardSubsystemsCached.MetadataObjectCollectionProperties();
	
	For Each  CollectionProperties In CollectionProperties Do
		Row = Data.Find(CollectionProperties.CollectionID, "Ref");
		If Row = Undefined Then
			Row = Data.Add();
			Row.Ref   = CollectionProperties.CollectionID;
			Row.IsNew = True;
		EndIf;
		Row.IsCollection =  True;
	EndDo;
	
	Data.Sort("IsCollection DESC,
	 |DeletionMark ASC,
	 |WithoutMetadataObjectKey ASC");
	
	Return Data;
	
EndFunction
 
Procedure RenameFullNames(Data)
	
	TableOfRenaming = TableOfRenamingForCurrentVersion();
	
	For Each DetailsOnRenaming In TableOfRenaming Do
		OldFullNameLength = StrLen(DetailsOnRenaming.OldFullName);
		IsSubsystem = Upper(Left(DetailsOnRenaming.OldFullName, 11)) = Upper("Subsystem.");
		
		For Each Row In Data Do
			
			If Row.IsCollection Then
				Continue;
			EndIf;
			
			If IsSubsystem Then
				If Upper(Left(Row.FullName, OldFullNameLength))
				 = Upper(DetailsOnRenaming.OldFullName) Then
					
					Row.FullName =  DetailsOnRenaming.NewFullName
						+ Mid(Row.FullName, OldFullNameLength + 1);
				EndIf;
			Else
				If Upper(Row.FullName) = Upper(DetailsOnRenaming.OldFullName) Then
					Row.FullName = DetailsOnRenaming.NewFullName;
				EndIf;
			EndIf;
			
		EndDo;
	EndDo;
	
EndProcedure 
 
Procedure RefreshMarkedForDeletionItemProperties(Properties, PropertiesUpdated = False,  HasDeleted = False)

	
	If TypeOf(Properties.MetadataObjectKey) = Type("ValueStorage") Then
		MetadataObjectKey = Properties.MetadataObjectKey.Get();
	Else
		MetadataObjectKey = Properties.MetadataObjectKey;
	EndIf;
	
	If Not Properties.DeletionMark
	 Or ValueIsFilled(Properties.Parent)
	 Or Left(Properties.Description, 1) <> "?"
	 Or Left(Properties.Name, 1)        <> "?"
	 Or Left(Properties.Synonym, 1)     <> "?"
	 Or Left(Properties.FullName, 1)    <> "?"
	 Or Left(Properties.FullSynonym, 1) <> "?"
	 Or Find(Properties.FullName, "(")  = 0
	 Or Properties.EmptyRefValue        <> Undefined
	 Or MetadataObjectKey               <> Undefined Then
		
		If Not Properties.DeletionMark Or Left(Properties.FullName, 1) <> "?"  Then
			HasDeleted = True;
		EndIf;
		
		// Setting new properties of the metadata object ID
		Properties.DeletionMark  = EmptyRef();
		Properties.Description   = InsertQuestionMark(Properties.Description);
		Properties.Name          = InsertQuestionMark(Properties.Name);
		Properties.Synonym       = InsertQuestionMark(Properties.Synonym);
		Properties.FullName      = UniqueFullName(Properties);
		Properties.FullSynonym   = InsertQuestionMark(Properties.FullSynonym);
		Properties.EmptyRefValue = Undefined;
		If TypeOf(Properties.MetadataObjectKey) = Type("ValueStorage") Then
			Properties.MetadataObjectKey = New ValueStorage(Undefined);
		Else
			Properties.MetadataObjectKey = Undefined;
		EndIf;
		PropertiesUpdated = True;
	EndIf;

EndProcedure 
 
Procedure CheckUpdateCollectionProperties(Val CurrentProperties)
	
	NewProperties =  StandardSubsystemsCached.MetadataObjectCollectionProperties(
		).Find(CurrentProperties.Ref, "CollectionID");
	
	CollectionDescription = NewProperties.Synonym;
	
	If CurrentProperties.Description         <> CollectionDescription
	 Or CurrentProperties.CollectionOrder    <> NewProperties.CollectionOrder
	 Or CurrentProperties.Name               <> NewProperties.Name
	 Or CurrentProperties.Synonym            <> NewProperties.Synonym
	 Or CurrentProperties.FullName           <> NewProperties.Name
	 Or CurrentProperties.FullSynonym        <> NewProperties.Synonym
	 Or CurrentProperties.WithoutData        <> False
	 Or CurrentProperties.EmptyRefValue      <> Undefined
	 Or CurrentProperties.PredefinedDataName <> ""
	 Or CurrentProperties.DeletionMark       <> False
	 Or CurrentProperties.MetadataObjectKey  <> Undefined Then
		
		// Setting new properties
		CurrentProperties.Description        = CollectionDescription;
		CurrentProperties.CollectionOrder    = NewProperties.CollectionOrder;
		CurrentProperties.Name               = NewProperties.Name;
		CurrentProperties.Synonym            = NewProperties.Synonym;
		CurrentProperties.FullName           = NewProperties.Name;
		CurrentProperties.FullSynonym        = NewProperties.Synonym;
		CurrentProperties.WithoutData        = False;
		CurrentProperties.EmptyRefValue      = Undefined;
		CurrentProperties.PredefinedDataName = "";
		CurrentProperties.DeletionMark       = False;
		CurrentProperties.MetadataObjectKey  = Undefined;
 
		CurrentProperties.Updated            = True;
	EndIf;
	
EndProcedure 

Function MetadataObjectKey(FullName)
	
	DotPosition = Find(FullName, ".");
	
	MOClass = Left( FullName, DotPosition-1);
	MOName = Mid(FullName, DotPosition+1);
	
	If Upper(MOClass) = Upper("ExchangePlan") Then
		Return Type(MOClass + "Ref." + MOName);
 
	ElsIf Upper(MOClass) = Upper("Constant") Then

		Return TypeOf(CommonUse.ObjectManagerByFullName(FullName));
		
	ElsIf Upper(MOClass) = Upper("Catalog") Then
		Return Type(MOClass + "Ref." + MOName);
		
	ElsIf Upper(MOClass) = Upper("Document") Then
		Return Type(MOClass + "Ref." + MOName);
		
	ElsIf Upper(MOClass) = Upper("DocumentJournal") Then
		Return TypeOf(CommonUse.ObjectManagerByFullName(FullName));
		
	ElsIf Upper(MOClass) = Upper("Report") Then
		Return Type(MOClass + "Object." + MOName);
		
	ElsIf Upper(MOClass) = Upper("DataProcessor") Then
		Return Type(MOClass + "Object." + MOName);
		
	ElsIf Upper(MOClass) = Upper("ChartOfCharacteristicTypes") Then
		Return Type(MOClass + "Ref." + MOName);
		
	ElsIf Upper(MOClass) = Upper("ChartOfAccounts") Then
		Return Type(MOClass + "Ref." + MOName);
		
	ElsIf Upper(MOClass) = Upper("ChartOfCalculationTypes") Then
		Return Type(MOClass + "Ref." + MOName);
		
	ElsIf Upper(MOClass) = Upper("InformationRegister") Then
		Return Type(MOClass + "RecordKey." + MOName);
		
	ElsIf Upper(MOClass) = Upper("AccumulationRegister") Then
		Return Type(MOClass + "RecordKey." + MOName);
		
	ElsIf Upper(MOClass) = Upper("AccountingRegister") Then
		Return Type(MOClass + "RecordKey." + MOName);
		
	ElsIf Upper(MOClass) = Upper("CalculationRegister") Then
		Return Type(MOClass + "RecordKey." + MOName);
		
	ElsIf Upper(MOClass) = Upper("BusinessProcess") Then
		Return Type(MOClass + "Ref." + MOName);
		
	ElsIf Upper(MOClass) = Upper("Task") Then
		Return Type(MOClass + "Ref." + MOName);
	Else
		// Without metadata object key
		Return Type("Undefined");
	EndIf;
	
EndFunction 
 
Function SameMetadataObjectKeys(Properties, Object)
	
	Return Properties.MetadataObjectKey = Object.MetadataObjectKey.Get();
	
EndFunction 
 
Function MetadataObjectByKey(MetadataObjectKey)
	
	MetadataObject = Undefined;
	
	If TypeOf(MetadataObjectKey) = Type("Type") Then

		MetadataObject = Metadata.FindByType(MetadataObjectKey);
	EndIf;
	
	Return MetadataObject;
	
EndFunction

Function MetadataObjectProperties(CollectionProperties = Undefined)
	
	MetadataObjectProperties = New ValueTable;
	MetadataObjectProperties.Columns.Add("Description",              New TypeDescription("String",, New StringQualifiers(150)));
	MetadataObjectProperties.Columns.Add("FullName",                 New TypeDescription("String",, New StringQualifiers(510)));      
	MetadataObjectProperties.Columns.Add("ParentFullName",           New TypeDescription("String",, New StringQualifiers(510)));
	MetadataObjectProperties.Columns.Add("CollectionOrder",          New TypeDescription("Number")); 
	MetadataObjectProperties.Columns.Add("Parent",                   New TypeDescription("CatalogRef.MetadataObjectIDs"));
	MetadataObjectProperties.Columns.Add("Name",                     New TypeDescription("String",, New StringQualifiers(150)));
	MetadataObjectProperties.Columns.Add("Synonym",                  New TypeDescription("String",, New StringQualifiers(255)));
	MetadataObjectProperties.Columns.Add("FullSynonym",              New TypeDescription("String",, New StringQualifiers(510)));
	MetadataObjectProperties.Columns.Add("WithoutData",              New TypeDescription("Boolean"));
	MetadataObjectProperties.Columns.Add("WithoutMetadataObjectKey", New TypeDescription("Boolean"));
	MetadataObjectProperties.Columns.Add("EmptyRefValue");
	
	 MetadataObjectProperties.Columns.Add("MetadataObject");

	
	If CollectionProperties = Undefined Then
		CollectionProperties = StandardSubsystemsCached.MetadataObjectCollectionProperties();
	EndIf;
	
	For Each CollectionProperties In CollectionProperties Do
		AddMetadataObjectProperties(Metadata[CollectionProperties.Name], CollectionProperties, MetadataObjectProperties);
	EndDo;
	
	MetadataObjectProperties.Indexes.Add("FullName");
	
	Return MetadataObjectProperties;
	
EndFunction

Procedure AddMetadataObjectProperties(Val MetadataObjectCollection,
                                      Val CollectionProperties,
                                      Val MetadataObjectProperties,
                                      Val ParentFullName = "",
                                      Val ParentFullSynonym = "")
	
	For Each MetadataObject In MetadataObjectCollection Do
		
		FullName = MetadataObject.FullName();
		
		If Find(CollectionProperties.SingularName, "Subsystem") <> 0  Then

			MetadataFindByFullName(FullName);
		EndIf;
		
		If Not  CollectionProperties.WithoutData
		 And Find(CollectionProperties.SingularName, "Register")  = 0
		 And Find(CollectionProperties.SingularName, "Constant") = 0 Then			
			EmptyRefValue = CommonUse.ObjectManagerByFullName(FullName).EmptyRef();
		Else
			EmptyRefValue = Undefined;
		EndIf;
				
		NewRow = MetadataObjectProperties.Add();
		FillPropertyValues(NewRow, CollectionProperties);
		NewRow.Parent         = CollectionProperties.CollectionID;
		NewRow.Description    = MetadataObjectPresentation(MetadataObject, CollectionProperties);
		NewRow.FullName       = FullName;
		NewRow.ParentFullName = ParentFullName;
		NewRow.Name           = MetadataObject.Name;
		NewRow.Synonym        = ?(ValueIsFilled(MetadataObject.Synonym), MetadataObject.Synonym, MetadataObject.Name);
		NewRow.FullSynonym    = ParentFullSynonym + CollectionProperties.SingularSynonym + "." + NewRow.Synonym;
		NewRow.EmptyRefValue  = EmptyRefValue;
		NewRow.MetadataObject = MetadataObject;
		
		If CollectionProperties.Name = "Subsystems" Then
			AddMetadataObjectProperties(
			MetadataObject.Subsystems,
			CollectionProperties,
			MetadataObjectProperties,
			FullName,
			NewRow.FullSynonym + ".");
		EndIf;
	EndDo;
	
EndProcedure

Function MetadataObjectPresentation(Val MetadataObject, Val CollectionProperties);
	
	Postfix = "(" + CollectionProperties.SingularSynonym + ")";
	
	Synonym = ?(ValueIsFilled(MetadataObject.Synonym), MetadataObject.Synonym, MetadataObject.Name);
	
	SynonymMaxLength = 150 - StrLen(Postfix);
	If StrLen(Synonym) > SynonymMaxLength + 1 Then
		Return Left(Synonym, SynonymMaxLength - 2) + "..." + Postfix;
	EndIf;
	
	Return Synonym + " (" + CollectionProperties.SingularSynonym + ")";
	
EndFunction
 
Function InsertQuestionMark(Val String)
	
	If Left(String, 1) <> "?"  Then
		If Left(String, 1) <> " " Then
			String = "?" + String;
		Else
			String = "?" + String;
		EndIf;
	EndIf;
	
	Return String;
	
EndFunction
 
Function UniqueFullName(Properties)
	
	FullName = InsertQuestionMark(Properties.FullName);
	
	If Find(FullName, "") = 0 Then
		FullName = FullName + " " + String(Properties.Ref.UUID())+ "";
	EndIf;
	
	Return FullName;
	
EndFunction 
 

 Function MetadataFindByFullName(FullName)

	
	MetadataObject = Metadata.FindByFullName(FullName);
	
	If MetadataObject =  Undefined Then
		Return Undefined;
	EndIf;
	
	If Upper(MetadataObject.FullName()) <>  Upper(FullName) Then
		
		If StrOccurrenceCount(Upper(FullName), Upper("Subsystem.")) > 1 Then
			Subsystem =  FindSubsystemByFullName(FullName);

			If Subsystem =  Undefined Then
				Return Undefined;
			EndIf;
			Raise  StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Cannot find the child subsystem by full name (when searching ""%1"",""%2"" is found).
				 |Subsystems should have different names or use a newer platform version.'"),
				FullName,
				MetadataObject.FullName());
		Else
			Raise  StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Cannot find the metadata object by full name (when searching ""%1"",""%2""is found ).'"),
				FullName,
				MetadataObject.FullName());
		EndIf;
	EndIf;
	
	Return MetadataObject;
	
EndFunction 
 
 Function FindSubsystemByFullName(FullName, SubsystemCollection = Undefined)
	
	If SubsystemCollection = Undefined Then
		SubsystemCollection = Metadata.Subsystems;
	EndIf;
	
	CutName = Mid(FullName, StrLen("Subsystem.") +  1);
	Position = Find(Upper(CutName), Upper("Subsystem."));
	If Position > 0 Then
		SubsystemName = Left(CutName, Position - 2);
		CutName = Mid(FullName, Position + StrLen("Subsystem."));
	Else
		SubsystemName = CutName;
		CutName = Undefined;
	EndIf;
	
	FoundSubsystem = Undefined;
	For Each Subsystem  In SubsystemCollection Do
		If Upper(Subsystem.Name) = Upper(SubsystemName) Then
			FoundSubsystem = Subsystem;
			Break;
		EndIf;
	EndDo;
	
	If FoundSubsystem = Undefined Then
		Return Undefined;
	EndIf;
	
	If CutName =  Undefined Then
		Return FoundSubsystem;
	EndIf;
	
	Return FindSubsystemByFullName(CutName,  FoundSubsystem.Subsystems);
	
EndFunction 
 
////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for replacing an ID in the database  
 
 Procedure  ReplaceSubordinateNodeDuplicatesFoundOnImport(CheckOnly, HasChanges)

	
	If CommonUseCached.DataSeparationEnabled() Then
		// Not supported in the SaaS mode
		Return;
	EndIf;
	
	If Not CommonUse.IsSubordinateDIBNode() Then
		Return;
	EndIf;
	
	// Replacing duplicates in the subordinate DIB node
	Query = New  Query;
	Query.Text =
	"SELECT
	|	IDs.Ref,
	|	IDs.NewRef
	|FROM
	|	Catalog.MetadataObjectIDs AS IDs
	|Where
	|	IDs.NewRef <> VALUE(Catalog.MetadataObjectIDs.EmptyRef)";
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	If CheckOnly Then
		HasChanges = True;
		Return;
	EndIf;
	
	If ExclusiveMode()  Then
		DisableExclusiveMode = False;
	Else
		DisableExclusiveMode = True;
		SetExclusiveMode(True);
	EndIf;
	
	Try
		Selection = QueryResult.Select();
		ReferencesToReplace = New Array;
		OldAndNewReferences = New Map;
		While Selection.Next() Do
			ReferencesToReplace.Add(Selection.Ref);
			OldAndNewReferences.Insert(Selection.Ref, Selection.NewRef);
		EndDo;
		
		DataFound = FindByRef(ReferencesToReplace);
		DataFound.Columns[0].Name = "Ref";
		DataFound.Columns[1].Name = "Data";
		DataFound.Columns[2].Name = "Metadata";
		DataFound.Columns.Add("Enabled");
		DataFound.FillValues(True, "Enabled");
		
		If DataFound.Count() > 0 Then
			BeginTransaction();
			Try
				ExecuteItemReplacement(OldAndNewReferences,  DataFound, True);
				
				// Clearing new references in ID duplicates
				For Each  ReferenceToReplace In ReferencesToReplace Do
					DuplicateObject = ReferenceToReplace.GetObject();
					DuplicateObject.NewRef = Undefined;
					DuplicateObject.DataExchange.Load = True;
					DuplicateObject.Write();
				EndDo;
				
				CommitTransaction();
			Except
				RollbackTransaction();
				Raise;
			EndTry;
		EndIf;
	Except
		If DisableExclusiveMode Then
			SetExclusiveMode(False);
		EndIf;
		Raise;
	EndTry;
	
	If DisableExclusiveMode Then
		SetExclusiveMode(False);
	EndIf;
	
EndProcedure 
 
// The function is from the SearchAndReplaceValues universal data processor
// Changes:
// - Removed form handlers 
// - Removed the UserInterruptProcessing() procedure 
// - InformationRegisters[TableRow.Metadata.Name] have been replaced by
// CommonUse.ObjectManagerByFullName(TableRow.Metadata.FullName())
//
Function ExecuteItemReplacement(Val Replaceable, Val RefsTable, Val DisableWriteControl = False, Val ExecuteTransactioned = False)
	
	Parameters = New Structure;
	
	For Each AccountingRegister In Metadata.AccountingRegisters Do
		Parameters.Insert(AccountingRegister.Name + "ExtDimension", AccountingRegister.ChartOfAccounts.MaxExtDimensionCount);
		Parameters.Insert(AccountingRegister.Name + "Correspondence", AccountingRegister.Correspondence);
	EndDo;
	
	Parameters.Insert("Object", Undefined);
	
	RefToProcess = Undefined;
	HasException = False;
		
	If ExecuteTransactioned Then
		BeginTransaction();
	EndIf;
	
	Try
		For Each TableRow In RefsTable Do
			If Not TableRow.Enabled Then
				Continue;
			EndIf;
			CorrectItem = Replaceable[TableRow.Ref];
			
			Ref = TableRow.Ref;
			
			If RefToProcess <> TableRow.Data Then
				If RefToProcess <> Undefined And Parameters.Object <> Undefined Then
					
					If DisableWriteControl Then
						Parameters.Object.DataExchange.Load = True;
					EndIf;
					
					Try
						Parameters.Object.Write();
					Except
						HasException = True;
						If ExecuteTransactioned Then
							Raise;
						EndIf;
						ReportError(ErrorInfo());
					EndTry;
					Parameters.Object = Undefined;
				EndIf;
				RefToProcess = TableRow.Data;
			EndIf;
			
			If Metadata.Documents.Contains(TableRow.Metadata) Then
				
				If Parameters.Object = Undefined Then
					Parameters.Object = TableRow.Data.GetObject();
				EndIf;
				
				For Each Attribute In TableRow.Metadata.Attributes Do
					If Attribute.Type.ContainsType(TypeOf(Ref)) And Parameters.Object[Attribute.Name] = Ref Then
						Parameters.Object[Attribute.Name] = CorrectItem;
					EndIf;
				EndDo;
					
				For Each TabularSection In TableRow.Metadata.TabularSections Do
					For Each Attribute In TabularSection.Attributes Do
						If Attribute.Type.ContainsType(TypeOf(Ref)) Then
							TabularSectionRow = Parameters.Object[TabularSection.Name].Find(Ref, Attribute.Name);
							While TabularSectionRow <> Undefined Do
								TabularSectionRow[Attribute.Name] = CorrectItem;
								TabularSectionRow = Parameters.Object[TabularSection.Name].Find(Ref, Attribute.Name);
							EndDo;
						EndIf;
					EndDo;
				EndDo;
				
				For Each RegisterRecord In TableRow.Metadata.RegisterRecords Do
					
					IsAccountingRegisterRecord = Metadata.AccountingRegisters.Contains(RegisterRecord);
					HasCorrespondence = IsAccountingRegisterRecord And Parameters[RegisterRecord.Name + "Correspondence"];
					
					RecordSet = Parameters.Object.RegisterRecords[RegisterRecord.Name];
					RecordSet.Read();
					MustWrite = False;
					SetTable = RecordSet.Unload();
					
					If SetTable.Count() = 0 Then
						Continue;
					EndIf;
					
					ColumnNames = New Array;
					
					// Getting names of dimensions that can contain a reference
					For Each Dimension In RegisterRecord.Dimensions Do
						
						If Dimension.Type.ContainsType(TypeOf(Ref)) Then
							
							If IsAccountingRegisterRecord Then
								
								If Dimension.AccountingFlag <> Undefined Then
									
									ColumnNames.Add(Dimension.Name + "Dr");
									ColumnNames.Add(Dimension.Name + "Cr");
								Else
									ColumnNames.Add(Dimension.Name);
								EndIf;
							Else
								ColumnNames.Add(Dimension.Name);
							EndIf;
						EndIf;
					EndDo;
					
					// Getting names of resources that can contain a reference
					If Metadata.InformationRegisters.Contains(RegisterRecord) Then
						For Each Resource In RegisterRecord.Resources Do
							If Resource.Type.ContainsType(TypeOf(Ref)) Then
								ColumnNames.Add(Resource.Name);
							EndIf;
						EndDo;
					EndIf;
					
					// Getting names of attributes that can contain a reference
					For Each Attribute In RegisterRecord.Attributes Do
						If Attribute.Type.ContainsType(TypeOf(Ref)) Then
							ColumnNames.Add(Attribute.Name);
						EndIf;
					EndDo;
					
					// Executing replacements in the table
					For Each ColumnName In ColumnNames Do
						TabularSectionRow = SetTable.Find(Ref, ColumnName);
						While TabularSectionRow <> Undefined Do
							TabularSectionRow[ColumnName] = CorrectItem;
							MustWrite = True;
							TabularSectionRow = SetTable.Find(Ref, ColumnName);
						EndDo;
					EndDo;
					
					If Metadata.AccountingRegisters.Contains(RegisterRecord) Then
						
						For ExtDimensionIndex = 1 to Parameters[RegisterRecord.Name + "ExtDimension"] Do
							If HasCorrespondence Then
								TabularSectionRow = SetTable.Find(Ref, "ExtDimensionDr"+ExtDimensionIndex);
								While TabularSectionRow <> Undefined Do
									TabularSectionRow["ExtDimensionDr"+ExtDimensionIndex] = CorrectItem;
									MustWrite = True;
									TabularSectionRow = SetTable.Find(Ref, "ExtDimensionDr"+ExtDimensionIndex);
								EndDo;
								TabularSectionRow = SetTable.Find(Ref, "ExtDimensionCr"+ExtDimensionIndex);
								While TabularSectionRow <> Undefined Do
									TabularSectionRow["ExtDimensionCr"+ExtDimensionIndex] = CorrectItem;
									MustWrite = True;
									TabularSectionRow = SetTable.Find(Ref, "ExtDimensionCr"+ExtDimensionIndex);
								EndDo;
							Else
								TabularSectionRow = SetTable.Find(Ref, "ExtDimension"+ExtDimensionIndex);
								While TabularSectionRow <> Undefined Do
									TabularSectionRow["ExtDimension"+ExtDimensionIndex] = CorrectItem;
									MustWrite = True;
									TabularSectionRow = SetTable.Find(Ref, "ExtDimension"+ExtDimensionIndex);
								EndDo;
							EndIf;
						EndDo;
						
						If Ref.Metadata() = RegisterRecord.ChartOfAccounts Then
							For Each TabularSectionRow In SetTable Do
								If HasCorrespondence Then
									If TabularSectionRow.AccountDr = Ref Then
										TabularSectionRow.AccountDr = CorrectItem;
										MustWrite = True;
									EndIf;
									If TabularSectionRow.AccountCr = Ref Then
										TabularSectionRow.AccountCr = CorrectItem;
										MustWrite = True;
									EndIf;
								Else
									If TabularSectionRow.Account = Ref Then
										TabularSectionRow.Account = CorrectItem;
										MustWrite = True;
									EndIf;
								EndIf;
							EndDo;
						EndIf;
					EndIf;
					
					If Metadata.CalculationRegisters.Contains(RegisterRecord) Then
						TabularSectionRow = SetTable.Find(Ref, "CalculationType");
						While TabularSectionRow <> Undefined Do
							TabularSectionRow["CalculationType"] = CorrectItem;
							MustWrite = True;
							TabularSectionRow = SetTable.Find(Ref, "CalculationType");
						EndDo;
					EndIf;
					
					If MustWrite Then
						RecordSet.Load(SetTable);
						If DisableWriteControl Then
							RecordSet.DataExchange.Load = True;
						EndIf;
						Try
							RecordSet.Write();
						Except
							HasException = True;
							If ExecuteTransactioned Then
								Raise;
							EndIf;
							ReportError(ErrorInfo());
						EndTry;
					EndIf;
				EndDo;
				
				For Each Sequence In Metadata.Sequences Do
					If Sequence.Documents.Contains(TableRow.Metadata) Then
						MustWrite = False;
						RecordSet = Sequences[Sequence.Name].CreateRecordSet();
						RecordSet.Filter.Recorder.Set(TableRow.Data);
						RecordSet.Read();
						
						If RecordSet.Count() > 0 Then
							For Each Dimension In Sequence.Dimensions Do
								If Dimension.Type.ContainsType(TypeOf(Ref)) And RecordSet[0][Dimension.Name]=Ref Then
									RecordSet[0][Dimension.Name] = CorrectItem;
									MustWrite = True;
								EndIf;
							EndDo;
							If MustWrite Then
								If DisableWriteControl Then
									RecordSet.DataExchange.Load = True;
								EndIf;
								Try
									RecordSet.Write();
								Except
									HasException = True;
									If ExecuteTransactioned Then
										Raise;
									EndIf;
									ReportError(ErrorInfo());
								EndTry;
							EndIf;
						EndIf;
					EndIf;
				EndDo;
				
			ElsIf Metadata.Catalogs.Contains(TableRow.Metadata) Then
				
				If Parameters.Object = Undefined Then
					Parameters.Object = TableRow.Data.GetObject();
				EndIf;
				
				If TableRow.Metadata.Owners.Contains(Ref.Metadata()) And Parameters.Object.Owner = Ref Then
					Parameters.Object.Owner = CorrectItem;
				EndIf;
				
				If TableRow.Metadata.Hierarchical And Parameters.Object.Parent = Ref Then
					Parameters.Object.Parent = CorrectItem;
				EndIf;
				
				For Each Attribute In TableRow.Metadata.Attributes Do
					If Attribute.Type.ContainsType(TypeOf(Ref)) And Parameters.Object[Attribute.Name] = Ref Then
						Parameters.Object[Attribute.Name] = CorrectItem;
					EndIf;
				EndDo;
				
				For Each TS In TableRow.Metadata.TabularSections Do
					For Each Attribute In TS.Attributes Do
						If Attribute.Type.ContainsType(TypeOf(Ref)) Then
							TabularSectionRow = Parameters.Object[TS.Name].Find(Ref, Attribute.Name);
							While TabularSectionRow <> Undefined Do
								TabularSectionRow[Attribute.Name] = CorrectItem;
								TabularSectionRow = Parameters.Object[TS.Name].Find(Ref, Attribute.Name);
							EndDo;
						EndIf;
					EndDo;
				EndDo;
				
			ElsIf Metadata.ChartsOfCharacteristicTypes.Contains(TableRow.Metadata)
			 or Metadata.ChartsOfAccounts.Contains (TableRow.Metadata)
			 or Metadata.ChartsOfCalculationTypes.Contains (TableRow.Metadata)
			 or Metadata.Tasks.Contains (TableRow.Metadata)
			 or Metadata.BusinessProcesses.Contains (TableRow.Metadata) Then
				
				If Parameters.Object = Undefined Then
					Parameters.Object = TableRow.Data.GetObject();
				EndIf;
				
				For Each Attribute In TableRow.Metadata.Attributes Do
					If Attribute.Type.ContainsType(TypeOf(Ref)) And Parameters.Object[Attribute.Name] = Ref Then
						Parameters.Object[Attribute.Name] = CorrectItem;
					EndIf;
				EndDo;
				
				For Each TS In TableRow.Metadata.TabularSections Do
					For Each Attribute In TS.Attributes Do
						If Attribute.Type.ContainsType(TypeOf(Ref)) Then
							TabularSectionRow = Parameters.Object[TS.Name].Find(Ref, Attribute.Name);
							While TabularSectionRow <> Undefined Do
								TabularSectionRow[Attribute.Name] = CorrectItem;
								TabularSectionRow = Parameters.Object[TS.Name].Find(Ref, Attribute.Name);
							EndDo;
						EndIf;
					EndDo;
				EndDo;
				
			ElsIf Metadata.Constants.Contains(TableRow.Metadata) Then
				
				CommonUse.ObjectManagerByFullName(

					TableRow.Metadata.FullName()).Set(CorrectItem);
				
			ElsIf Metadata.InformationRegisters.Contains(TableRow.Metadata) Then
				
				DimensionStructure = New Structure;
				RecordSet = CommonUse.ObjectManagerByFullName(TableRow.Metadata.FullName()).CreateRecordSet();
				For Each Dimension In TableRow.Metadata.Dimensions Do
					RecordSet.Filter[Dimension.Name].Set(TableRow.Data[Dimension.Name]);
					DimensionStructure.Insert(Dimension.Name);
				EndDo;
				If TableRow.Metadata.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then
					RecordSet.Filter["Period"].Set(TableRow.Data.Period);
				EndIf;
				RecordSet.Read();
				
				If RecordSet.Count() = 0 Then
					Continue;
				EndIf;
				
				SetTable = RecordSet.Unload();
				RecordSet.Clear();
				
				If DisableWriteControl Then
					RecordSet.DataExchange.Load = True;
				EndIf;
				
				
				If Not ExecuteTransactioned Then
					BeginTransaction();
				EndIf;
				
				Try
					RecordSet.Write();
					
					For Each Column In SetTable.Columns Do
						If SetTable[0][Column.Name] = Ref Then
							SetTable[0][Column.Name] = CorrectItem;
							If DimensionStructure.Property(Column.Name) Then
								RecordSet.Filter[Column.Name].Set(CorrectItem);
							EndIf;
							
						EndIf;
					EndDo;
					
					RecordSet.Load(SetTable);
					
					RecordSet.Write();
					
					If Not ExecuteTransactioned Then
						CommitTransaction();
					EndIf;
					
				Except
					HasException = True;
					If ExecuteTransactioned Then
						Raise;
					EndIf;
					RollbackTransaction();
					ReportError(ErrorInfo());
				EndTry;
			Else
				ReportError(StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Values in data of %1 type are not replaced'"), TableRow.Metadata));
			EndIf;
		EndDo;
	
	If Parameters.Object <> Undefined Then
			If DisableWriteControl Then
				Parameters.Object.DataExchange.Load = True;
			EndIf;
			Try
				Parameters.Object.Write();
			Except
				HasException = True;
				If ExecuteTransactioned Then
					Raise;
				EndIf;
				ReportError(ErrorInfo());
			EndTry;
		EndIf;
		
		If ExecuteTransactioned Then
			CommitTransaction();
		EndIf;
	Except
		HasException = True;
		If ExecuteTransactioned Then
			RollbackTransaction();
		EndIf;
		ReportError(ErrorInfo());
	EndTry;
	
	Return Not HasException;
	
EndFunction

// The procedure is from the SearchAndReplaceValues universal data processor
// Changes:
// - the Message(...) method has been replaced with WriteLogEvent(...)
//
Procedure ReportError(Val Details)
	
	If TypeOf(Details) = Type("ErrorInfo") Then
		Details = ?(Details.Cause = Undefined, Details, Details.Cause).Details;
	EndIf;
	
	WriteLogEvent(
		NStr("en = 'Metadata object IDs. ID replacement'", CommonUseClientServer.DefaultLanguageCode()),
		EventLogLevel.Error,
		,
		,
		Details,
		EventLogEntryTransactionMode.Independent);
	
EndProcedure
 
#EndRegion

#EndIf