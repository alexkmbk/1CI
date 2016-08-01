#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region InternalInterface

// See description of the procedure of the same name in the StandardSubsystemsServer module.
Procedure OnAddInternalEvent(ClientEvents, ServerEvents) Export
	
	// SERVER EVENTS.
	
	// Is called once marked objects are deleted.
	//
	// Parameters:
	//   ExecutionParameters - Structure - marked object deletion context.
	//       * DeletedItems    - Array - references to deleted objects.
	//       * NotDeletedItems - Array - references to the objects that were not deleted.
	//
	// Syntax:
	//   Procedure MarkedAfterDelete(Val ExecutionParameters) Export
	//
	ServerEvents.Add(
		"StandardSubsystems.BaseFunctionality\MarkedAfterDelete");
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

////////////////////////////////////////////////////////////////////////////////
// Deleting marked objects interactively

// Deletes marked objects. Is used in case of interactive deletion in a background job.
//
// Parameters:
//   ExecutionParameters - Structure - parameters required for deletion.
//   StorageAddress      - String - temporary storage address.
//
Procedure DeleteMarkedObjectsInteractively(ExecutionParameters, StorageAddress) Export
	DeleteMarkedObjects(ExecutionParameters);
	PutToTempStorage(ExecutionParameters, StorageAddress);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Deleting marked objects using a scheduled job

// Deletes marked objects using a scheduled job.
Procedure DeleteMarkedObjectsUsingScheduledJob() Export
	
	ExecutionParameters = New Structure;
	DeleteMarkedObjects(ExecutionParameters);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Common mechanics

// Main mechanics of marked object deletion.
Procedure DeleteMarkedObjects(ExecutionParameters)
	
	If Not Users.InfobaseUserWithFullAccess() Then
		Raise NStr("en = 'Insufficient rights to perform the operation.'");
	EndIf;
	
	InitializeParameters(ExecutionParameters);
	
	PreventDeletion = New ValueTable;
	PreventDeletion.Columns.Add("ItemBeingDeletedRef");
	PreventDeletion.Columns.Add("ItemBeingDeletedType", New TypeDescription("Type"));
	PreventDeletion.Columns.Add("FoundItemReference");
	PreventDeletion.Columns.Add("FoundType", New TypeDescription("Type"));
	PreventDeletion.Columns.Add("FoundDeletionMark", New TypeDescription("Boolean"));
	
	ExecutionParameters.Insert("DeletedItems",         New Array);
	ExecutionParameters.Insert("NotDeletedItems",      New Array);
	ExecutionParameters.Insert("PreventDeletion", PreventDeletion);
	ExecutionParameters.Insert("ToRedelete",      New Array);
	ExecutionParameters.Insert("Interactive",     ExecutionParameters.Property("RecordPeriod"));
	
	If ExecutionParameters.MarkedForDeletion = Undefined Then
		If ExecutionParameters.Interactive Then
			LongActions.RegisterProgress(1, NStr("en = 'Searching for objects marked for deletion.'"));
		EndIf;
		GetMarkedForDeletion(ExecutionParameters);
	EndIf;
	
	SetPrivilegedMode(True);
	
	// Deleting technological objects (that were created and marked for deletion without user participation)
	If ExecutionParameters.TechnologicalObjects <> Undefined Then
		ClientSetCollectionIterationBeginning(ExecutionParameters, "TechnologicalObjects");
		For Each Ref In ExecutionParameters.TechnologicalObjects Do
			DeleteReference(ExecutionParameters, Ref);
			ClientSetCollectionIterationProgress(ExecutionParameters, "TechnologicalObjects");
		EndDo;
	EndIf;
	
	// Deleting objects marked for deletion
	ClientSetCollectionIterationBeginning(ExecutionParameters, "MarkedForDeletion");
	For Each Ref In ExecutionParameters.MarkedForDeletion Do
		Result = DeleteReference(ExecutionParameters, Ref);
		RecordDeletionResult(ExecutionParameters, Ref, Result, "MarkedForDeletion");
		ClientSetCollectionIterationProgress(ExecutionParameters, "MarkedForDeletion");
	EndDo;
	
	// Deleting chains (associated objects)
	ClientSetCollectionIterationBeginning(ExecutionParameters, "ToRedelete");
	While ExecutionParameters.ToRedelete.Count() > 0 Do
		Ref = ExecutionParameters.ToRedelete[0];
		ExecutionParameters.ToRedelete.Delete(0);
		
		Result = DeleteReference(ExecutionParameters, Ref);
		
		RecordDeletionResult(ExecutionParameters, Ref, Result, "ToRedelete");
		ClientSetCollectionIterationProgress(ExecutionParameters, "ToRedelete");
	EndDo;
	
	// Delete loops (loop object links)
	DeleteRemainingObjectsInSingleTransaction(ExecutionParameters);
	
	// Attached SL subsystems handlers
	Handlers = CommonUse.InternalEventHandlers("StandardSubsystems.BaseFunctionality\MarkedAfterDelete");
	For Each Handler In Handlers Do
		Handler.Module.MarkedAfterDelete(ExecutionParameters);
	EndDo;
	
EndProcedure

// Deleting a single object, checking the result and rolling back transaction in case of failure
Function DeleteReference(ExecutionParameters, Ref)
	Result = New Structure;
	Result.Insert("Success", Undefined);
	Result.Insert("ErrorInfo", Undefined);
	Result.Insert("PreventDeletion", Undefined);
	Result.Insert("NestedAndSubordinateObjects", New Array);
	Result.Insert("Count", 0);
	
	Information = GenerateTypeInfo(ExecutionParameters, TypeOf(Ref));
	
	BeginTransaction();
	Try
		AttemptDeleteReference(ExecutionParameters, Ref, Information, Result);
	Except
		Result.Success = False;
		Result.ErrorInfo = ErrorInfo();
	EndTry;
	If Result.Success Then
		CommitTransaction();
	Else
		RollbackTransaction();
		WriteWarning(Ref, Result.ErrorInfo);
	EndIf;
	
	If TypeOf(Result.PreventDeletion) = Type("ValueTable") Then
		Result.PreventDeletion.Columns[0].Name = "ItemBeingDeletedRef";
		Result.PreventDeletion.Columns[1].Name = "FoundItemReference";
		Result.PreventDeletion.Columns[2].Name = "FoundMetadata";
		For Each FoundItemReference In Result.NestedAndSubordinateObjects Do
			TableRow = Result.PreventDeletion.Add();
			TableRow.ItemBeingDeletedRef = Ref;
			TableRow.FoundItemReference        = FoundItemReference;
		EndDo;
	EndIf;
	
	Return Result;
EndFunction

// Mechanics of object deletion and reference search.
Procedure AttemptDeleteReference(ExecutionParameters, Ref, Information, Result)
	Lock = New DataLock;
	LockItem = Lock.Add(Information.FullName);
	LockItem.SetValue("Ref", Ref);
	Lock.Lock();
	
	Object = Ref.GetObject();
	If Object = Undefined Then
		Result.Success = True; // Object is already deleted
		Return;
	EndIf;
	If Object.DeletionMark <> True Then
		Result.Success = False;
		Result.ErrorInfo = NStr("en = 'The object is not marked for deletion.'");
		Return;
	EndIf;
	
	FindNestedAndSubordinateObjects(ExecutionParameters, Ref, Information, Result);
	
	Object.Delete();
	
	FindPreventDeletion(ExecutionParameters, Ref, Information, Result);
	
	If Result.Count = 0 Then
		Result.Success = True;
	Else
		Result.Success = False;
		Result.ErrorInfo = NStr("en = 'The object is used in other application objects.'");
	EndIf;
EndProcedure

// Searches for nested and subordinated references (hierarchy and owners). Is executed before
// a deletion.
Procedure FindNestedAndSubordinateObjects(ExecutionParameters, Ref, Information, Result)
	
	If Information.Hierarchical Then
		Query = New Query(Information.QueryTextByHierarchy);
		Query.SetParameter("ItemBeingDeletedRef", Ref);
		NestedObjects = Query.Execute().Unload();
		For Each TableRow In NestedObjects Do
			Result.NestedAndSubordinateObjects.Add(TableRow.Ref);
		EndDo;
		Result.Count = Result.Count + NestedObjects.Count();
	EndIf;
	
	If Information.HasSubordinate Then
		Query = New Query(Information.QueryTextBySubordinated);
		Query.SetParameter("ItemBeingDeletedRef", Ref);
		SubordinateObjects = Query.Execute().Unload();
		For Each TableRow In SubordinateObjects Do
			Result.NestedAndSubordinateObjects.Add(TableRow.Ref);
		EndDo;
		Result.Count = Result.Count + SubordinateObjects.Count();
	EndIf;
	
EndProcedure

// Searches for references by scanning all tables. Is executed after deletion.
Procedure FindPreventDeletion(ExecutionParameters, Ref, Information, Result)
	
	ReferenceSearch = New Array;
	ReferenceSearch.Add(Ref);
	
	PreventDeletion = FindByRef(ReferenceSearch);
	
	// Skipping references from the sequence
	Count = PreventDeletion.Count();
	ColumnName = PreventDeletion.Columns[1].Name;
	For Number = 1 to Count Do
		ReverseIndex = Count - Number;
		TableRow = PreventDeletion[ReverseIndex];
		PreventingReference = TableRow[ColumnName];
		If PreventingReference = Ref
			Or DocumentAlreadyDeleted(ExecutionParameters, PreventingReference) Then
			PreventDeletion.Delete(TableRow);
		EndIf;
	EndDo;
	
	// Recording the result
	Result.PreventDeletion = PreventDeletion;
	Result.Count = Result.Count + Result.PreventDeletion.Count();
	
EndProcedure

// Searches for the document reference in the infobase.
Function DocumentAlreadyDeleted(ExecutionParameters, Ref)
	If Ref = Undefined Then
		Return False; // Not a document
	EndIf;
	Information = GenerateTypeInfo(ExecutionParameters, TypeOf(Ref));
	If Information.Kind <> "DOCUMENT" Then
		Return False; // Not a document
	EndIf;
	Query = New Query("Select Top 1 1 From "+ Information.FullName +" Where Ref = &Ref");
	Query.SetParameter("Ref", Ref);
	Return Query.Execute().IsEmpty();
EndFunction

// Deleting loops (loop object links).
Procedure DeleteRemainingObjectsInSingleTransaction(ExecutionParameters)
	Var Ref;
	
	// 1. Objects that cannot be deleted.
	//    Are obtained by determining unsolvable links.
	ObjectsCannotDelete = New Array;
	NestedIrresolvableLinks = New Array;
	
	// 1.1. First sign of an unsolvable link is an object that preventing deletion and
	//      is not marked for deletion.
	For Each TableRow In ExecutionParameters.PreventDeletion Do
		If ExecutionParameters.NotDeletedItems.Find(TableRow.FoundItemReference) = Undefined
			And ObjectsCannotDelete.Find(TableRow.ItemBeingDeletedRef) = Undefined Then
			ObjectsCannotDelete.Add(TableRow.ItemBeingDeletedRef);
			Found = ExecutionParameters.PreventDeletion.FindRows(New Structure("FoundItemReference", TableRow.ItemBeingDeletedRef));
			NestedIrresolvableLinks.Add(Found);
		EndIf;
	EndDo;
	
	// 1.2. Using the NestedIrresolvableLinks array to get unsolvable subordinate links of all 
	//      nesting levels. 
	Index = 0;
	While Index < NestedIrresolvableLinks.Count() Do
		Found = NestedIrresolvableLinks[Index];
		Index = Index + 1;
		For Each TableRow In Found Do
			If ObjectsCannotDelete.Find(TableRow.ItemBeingDeletedRef) = Undefined Then
				ObjectsCannotDelete.Add(TableRow.ItemBeingDeletedRef);
				Found = ExecutionParameters.PreventDeletion.FindRows(New Structure("FoundItemReference", TableRow.ItemBeingDeletedRef));
				NestedIrresolvableLinks.Add(Found);
			EndIf;
		EndDo;
	EndDo;
	
	// 2. Objects that possibly can be deleted in a single transaction.
	//    = Array of objects to be deleted - Array of objects that cannot be deleted.
	RefArray = New Array;
	For Each Ref In ExecutionParameters.NotDeletedItems Do
		If ObjectsCannotDelete.Find(Ref) = Undefined Then
			RefArray.Add(Ref);
		EndIf;
	EndDo;
	
	Count = RefArray.Count();
	If Count = 0 Then
		Return; // No objects to be deleted
	EndIf;
	
	// 3. Including all objects in a single transaction and attempting to delete them.
	Success = False;
	BeginTransaction();
	Try
		For Number = 1 to Count Do
			ReverseIndex = Count - Number;
			Reference = RefArray[ReverseIndex];
			
			Information = GenerateTypeInfo(ExecutionParameters, TypeOf(Ref));
			
			Lock = New DataLock;
			LockItem = Lock.Add(Information.FullName);
			LockItem.SetValue("Ref", Ref);
			Lock.Lock();
			
			Object = Ref.GetObject();
			If Object = Undefined Then // The object is already deleted
				Continue;
			EndIf;
			If Object.DeletionMark <> True Then
				RefArray.Delete(ReverseIndex); // The object is not marked for deletion already
				Continue;
			EndIf;
			
			Object.Delete();
		EndDo;
		Ref= Undefined;
		
		If RefArray.Count() > 0 Then
			PreventDeletion = FindByRef(RefArray);
			
			ColumnName = PreventDeletion.Columns[1].Name;
			For Each Ref In RefArray Do
				SearchForNotPreventing = New Structure(ColumnName, Ref);
				NotPreventing = PreventDeletion.FindRows(SearchForNotPreventing);
				For Each TableRow In NotPreventing Do
					PreventDeletion.Delete(TableRow);
				EndDo;
			EndDo;
			
			If PreventDeletion.Count() = 0 Then
				Success = True;
			EndIf;
		EndIf;
		
	Except
		WriteWarning(Ref, ErrorInfo());
	EndTry;
	
	// 4. Recording the result (if case of success).
	If Success Then
		CommitTransaction();
		
		For Each Ref In RefArray Do
			// Adding the reference to the collection of deleted objects
			If ExecutionParameters.DeletedItems.Find(Ref) = Undefined Then
				ExecutionParameters.DeletedItems.Add(Ref);
			EndIf;
			
			// Deleting the reference from the collection of undeleted objects
			Index = ExecutionParameters.NotDeletedItems.Find(Ref);
			If Index <> Undefined Then
				ExecutionParameters.NotDeletedItems.Delete(Index);
			EndIf;
			
			// Clearing details on links "from" the deleted objects
			Found = ExecutionParameters.PreventDeletion.FindRows(New Structure("ItemBeingDeletedRef", Ref));
			For Each TableRow In Found Do
				ExecutionParameters.PreventDeletion.Delete(TableRow);
			EndDo;
			
			//Clearing details on links "to" the deleted objects
			Found = ExecutionParameters.PreventDeletion.FindRows(New Structure("FoundItemReference", Ref));
			For Each TableRow In Found Do
				ExecutionParameters.PreventDeletion.Delete(TableRow);
			EndDo;
		EndDo;
	Else
		RollbackTransaction();
	EndIf;
EndProcedure

// Records the deletion result and fills the ToRedelete collection.
Procedure RecordDeletionResult(ExecutionParameters, Ref, Result, CollectionName)
	If Result.Success Then
		// Adding the reference to the collection of deleted objects.
		ExecutionParameters.DeletedItems.Add(Ref);
		
		// Excepting the deleted object from the list of objects that prevent deletion. Searching.
		ObsoleteReasons = ExecutionParameters.PreventDeletion.FindRows(New Structure("FoundItemReference", Ref));
		For Each Reason In ObsoleteReasons Do
			// Deleting the reasons that prevent deletion of the other object
			ItemBeingDeletedRef = Reason.ItemBeingDeletedRef;
			ExecutionParameters.PreventDeletion.Delete(Reason);
			// Searching other reasons that prevent deletion of the other object
			If ExecutionParameters.PreventDeletion.Find(ItemBeingDeletedRef, "ItemBeingDeletedRef") = Undefined Then
				// All reasons that prevent deletion of the other object are eliminated.
				// Recording the other object for redeletion.
				ExecutionParameters.ToRedelete.Add(ItemBeingDeletedRef);
				If CollectionName = "ToRedelete" And ExecutionParameters.Interactive Then
					ExecutionParameters.Total = ExecutionParameters.Total + 1;
				EndIf;
				// Clearing records of the other object from the NotDeletedItems collection
				Index = ExecutionParameters.NotDeletedItems.Find(ItemBeingDeletedRef);
				If Index <> Undefined Then
					ExecutionParameters.NotDeletedItems.Delete(Index);
				EndIf;
			EndIf;
		EndDo;
		
	Else // Failed to delete
		
		ExecutionParameters.NotDeletedItems.Add(Ref);
		
		If TypeOf(Result.ErrorInfo) = Type("ErrorInfo") Then // Error text
			Reason = ExecutionParameters.PreventDeletion.Add();
			Reason.ItemBeingDeletedRef = Ref;
			Reason.ItemBeingDeletedType      = TypeOf(Reason.ItemBeingDeletedRef);
			Reason.FoundItemReference        = BriefErrorDescription(Result.ErrorInfo);
			Reason.FoundType                 = Type("String");
			
			GenerateTypeInfo(ExecutionParameters, Reason.ItemBeingDeletedType);
		Else // Recording the reasons that prevent deletion
			For Each TableRow In Result.PreventDeletion Do
				// Recording the reason that prevented deletion
				Reason = ExecutionParameters.PreventDeletion.Add();
				FillPropertyValues(Reason, TableRow);
				Reason.ItemBeingDeletedType = TypeOf(Reason.ItemBeingDeletedRef);
				Reason.FoundType            = TypeOf(Reason.FoundItemReference);
				
				If TableRow.FoundItemReference = Undefined Then
					If Metadata.Constants.Contains(TableRow.FoundMetadata) Then
						Reason.FoundType = Type("ConstantValueManager." + TableRow.FoundMetadata.Name);
					Else
						Reason.FoundItemReference = StringFunctionsClientServer.SubstituteParametersInString(
							NStr("en = 'Unsolvable links are found (%1)'"),
							TableRow.FoundMetadata.Presentation());
						Reason.FoundType = Type("String");
						Continue;
					EndIf;
				EndIf;
				
				// Recording metadata object details (if required)
				GenerateTypeInfo(ExecutionParameters, Reason.ItemBeingDeletedType);
				FoundItemInformation = GenerateTypeInfo(ExecutionParameters, Reason.FoundType);
				
				// Filling subordinate fields
				If FoundItemInformation.Ref Then
					Reason.FoundDeletionMark = Reason.FoundItemReference.DeletionMark;
				Else
					Reason.FoundDeletionMark = False;
				EndIf;
			EndDo;
		EndIf;
	EndIf; // Result.Done
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Passing information to the client

Procedure ClientSetCollectionIterationBeginning(ExecutionParameters, CollectionName)
	If Not ExecutionParameters.Interactive Then
		Return;
	EndIf;
	ExecutionParameters.Insert("Total", ExecutionParameters[CollectionName].Count());
	ExecutionParameters.Insert("Number", 0);
	ExecutionParameters.Insert("Time", '00010101');
EndProcedure

Procedure ClientSetCollectionIterationProgress(ExecutionParameters, CollectionName)
	If Not ExecutionParameters.Interactive Then
		Return;
	EndIf;
	
	// Recording the progress
	ExecutionParameters.Number = ExecutionParameters.Number + 1;
	
	// Checking whether it is time to pass the information to the client
	CurrentSessionDate = CurrentSessionDate();
	If CurrentSessionDate < ExecutionParameters.Time Then
		Return;
	EndIf;
	
	// Setting time of the next data transfer to the client
	ExecutionParameters.Time = CurrentSessionDate + ExecutionParameters.RecordPeriod;
	
	// Preparing parameters to be passed
	If CollectionName = "TechnologicalObjects" Then
		
		Percent = 5 + 5*ExecutionParameters.Number/ExecutionParameters.Total;
		Text = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Preparing for deletion (%1 of %2).'"),
			Format(ExecutionParameters.Number, "NZ=0; NG="),
			Format(ExecutionParameters.Total, "NZ=0; NG="));
		
	ElsIf CollectionName = "MarkedForDeletion" Then
		
		NotDeletedItems = ExecutionParameters.NotDeletedItems.Count();
		If NotDeletedItems = 0 Then
			Template = NStr("en = 'Deleted: %1 of %2 objects.'");
		Else
			Template = NStr("en = 'Processed: %1 of %2 objects including %3 not deleted.'");
		EndIf;
		Percent = 10 + 80*ExecutionParameters.Number/ExecutionParameters.Total;
		Text = StringFunctionsClientServer.SubstituteParametersInString(
			Template,
			Format(ExecutionParameters.Number, "NZ=0; NG="),
			Format(ExecutionParameters.Total, "NZ=0; NG="),
			Format(NotDeletedItems, "NZ=0; NG="));
		
	ElsIf CollectionName = "ToRedelete" Then
		
		Percent = 90 + 10*ExecutionParameters.Number/ExecutionParameters.Total;
		Text = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Rechecking not deleted objects: %1 of %2.'"),
			Format(ExecutionParameters.Number, "NZ=0; NG="),
			Format(ExecutionParameters.Total, "NZ=0; NG="));
		
	Else
		
		Return;
		
	EndIf;
	
	// Recording messages for reading from the client session
	LongActions.RegisterProgress(Percent, Text);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Internal methods

// Initializes a structure of parameters required for performing other internal methods.
Procedure InitializeParameters(ExecutionParameters) Export
	// Determining the application run parameters
	If Not ExecutionParameters.Property("SaaS") Then
		ExecutionParameters.Insert("SaaS", CommonUseCached.DataSeparationEnabled());
		If ExecutionParameters.SaaS Then
			ExecutionParameters.Insert("InDataArea", CommonUse.UseSessionSeparator());
			ExecutionParameters.Insert("MainDataSeparator",        CommonUseCached.MainDataSeparator());
			ExecutionParameters.Insert("AuxiliaryDataSeparator", CommonUseCached.AuxiliaryDataSeparator());
		EndIf;
	EndIf;
	If Not ExecutionParameters.Property("MarkedForDeletion") Then
		ExecutionParameters.Insert("MarkedForDeletion", Undefined);
	EndIf;
	If Not ExecutionParameters.Property("TypeInformation") Then
		ExecutionParameters.Insert("TypeInformation", New Map);
	EndIf;
	If Not ExecutionParameters.Property("TechnologicalObjects") Then
		ExecutionParameters.Insert("TechnologicalObjects", Undefined);
	EndIf;
EndProcedure

// Generates an array of marked for deletion objects taking separation into account.
Procedure GetMarkedForDeletion(ExecutionParameters) Export
	ExecutionParameters.MarkedForDeletion = New Array;
	ExecutionParameters.TechnologicalObjects = New Array;
	
	SetPrivilegedMode(True);
	
	// Getting the list of marked for deletion objects
	MarkedForDeletion = FindMarkedForDeletion();
	
	// Distributing marked for deletion objects by collections
	For Each Ref In MarkedForDeletion Do
		Information = GenerateTypeInfo(ExecutionParameters, TypeOf(Ref));
		
		If ExecutionParameters.SaaS
			And ExecutionParameters.InDataArea 
			And Not Information.Separated Then
			Continue; // Shared objects cannot be changed in data areas.
		EndIf;
		
		If Information.HasPredefined And Information.Predefined.Find(Ref) <> Undefined Then
			Continue; // Predefined items are only created and deleted automatically.
		EndIf;
		
		If Information.Technical = True Then
			ExecutionParameters.TechnologicalObjects.Add(Ref);
		Else
			ExecutionParameters.MarkedForDeletion.Add(Ref);
		EndIf;
	EndDo;
EndProcedure

// Retrieves metadata object type details (full name, presentation and so on).
Function GenerateTypeInfo(ExecutionParameters, Type) Export
	Information = ExecutionParameters.TypeInformation.Get(Type);
	If Information <> Undefined Then
		Return Information;
	EndIf;
	
	Information = New Structure("FullName, ItemPresentation, ListPresentation, 
	|Kind, Ref, Technical, Separated, 
	|Hierarchical, QueryTextByHierarchy, 
	|HasSubordinate, QueryTextBySubordinated, 
	|HasPredefined, Predefined");
	
	// Searching for metadata object
	MetadataObject = Metadata.FindByType(Type);
	
	// Filling primary data
	Information.FullName = Upper(MetadataObject.FullName());
	
	// Presentations of the item and the list
	StandardAttributes = New Structure("ObjectPresentation, ExtendedObjectPresentation, ListPresentation, ExtendedListPresentation");
	FillPropertyValues(StandardAttributes, MetadataObject);
	If ValueIsFilled(StandardAttributes.ObjectPresentation) Then
		Information.ItemPresentation = StandardAttributes.ObjectPresentation;
	ElsIf ValueIsFilled(StandardAttributes.ExtendedObjectPresentation) Then
		Information.ItemPresentation = StandardAttributes.ExtendedObjectPresentation;
	Else
		Information.ItemPresentation = MetadataObject.Presentation();
	EndIf;
	If ValueIsFilled(StandardAttributes.ListPresentation) Then
		Information.ListPresentation = StandardAttributes.ListPresentation;
	ElsIf ValueIsFilled(StandardAttributes.ExtendedListPresentation) Then
		Information.ListPresentation = StandardAttributes.ExtendedListPresentation;
	Else
		Information.ListPresentation = MetadataObject.Presentation();
	EndIf;
	
	// Kind and its properties.
	Information.Kind = Left(Information.FullName, Find(Information.FullName, ".")-1);
	If Information.Kind = "CATALOG"
		Or Information.Kind = "DOCUMENT"
		Or Information.Kind = "ENUM"
		Or Information.Kind = "CHARTOFCHARACTERISTICTYPES"
		Or Information.Kind = "CHARTOFACCOUNTS"
		Or Information.Kind = "CHARTOFCALCULATIONTYPES"
		Or Information.Kind = "BUSINESSPROCESS"
		Or Information.Kind = "TASK"
		Or Information.Kind = "EXCHANGEPLAN" Then
		Information.Ref = True;
	Else
		Information.Ref = False;
	EndIf;
	
	If Information.Kind = "CATALOG"
		Or Information.Kind = "CHARTOFCHARACTERISTICTYPES" Then
		Information.Hierarchical = MetadataObject.Hierarchical;
	ElsIf Information.Kind = "CHARTOFACCOUNTS" Then
		Information.Hierarchical = True;
	Else
		Information.Hierarchical = False;
	EndIf;
	If Information.Hierarchical Then
		QueryPattern = "SELECT Ref FROM &FullName WHERE Parent = &ItemBeingDeletedRef";
		Information.QueryTextByHierarchy = StrReplace(QueryPattern, "&FullName", Information.FullName);
	EndIf;
	
	Information.HasSubordinate = False;
	Information.QueryTextBySubordinated = "";
	If Information.Kind = "CATALOG"
		Or Information.Kind = "CHARTOFCHARACTERISTICTYPES"
		Or Information.Kind = "EXCHANGEPLAN"
		Or Information.Kind = "CHARTOFACCOUNTS"
		Or Information.Kind = "CHARTOFCALCULATIONTYPES" Then
		
		QueryPattern = "SELECT Ref FROM Catalog.&Name WHERE Owner = &ItemBeingDeletedRef";
		QueryText = "";
		
		For Each Catalog In Metadata.Catalogs Do
			If Catalog.Owners.Contains(MetadataObject) Then
				If Information.HasSubordinate = False Then
					Information.HasSubordinate = True;
				Else
					QueryText = QueryText + Chars.LF + "UNION ALL" + Chars.LF;
				EndIf;
				QueryText = QueryText + StrReplace(QueryPattern, "&Name", Catalog.Name);
			EndIf;
		EndDo;
		
		Information.QueryTextBySubordinated = QueryText;
	EndIf;
	
	If Information.FullName = "CATALOG.METADATAOBJECTIDS"
		Or Information.FullName = "CATALOG.PREDEFINEDREPORTOPTIONS" Then
		Information.Technical = True;
		Information.Separated = False;
	Else
		Information.Technical = False;
		If ExecutionParameters.SaaS Then
			Information.Separated = CommonUse.IsSeparatedMetadataObject(MetadataObject, ExecutionParameters.MainDataSeparator)
				Or CommonUse.IsSeparatedMetadataObject(MetadataObject, ExecutionParameters.AuxiliaryDataSeparator);
		EndIf;
	EndIf;
	
	If Information.Kind = "CATALOG"
		Or Information.Kind = "CHARTOFCHARACTERISTICTYPES"
		Or Information.Kind = "CHARTOFACCOUNTS"
		Or Information.Kind = "CHARTOFCALCULATIONTYPES" Then
		Query = New Query("SELECT Ref FROM "+ Information.FullName +" WHERE Predefined And DeletionMark");
		Information.Predefined = Query.Execute().Unload().UnloadColumn("Ref");
		Information.HasPredefined = Information.Predefined.Count() > 0;
	Else
		Information.HasPredefined = False;
	EndIf;
	
	ExecutionParameters.TypeInformation.Insert(Type, Information);
	
	Return Information;
EndFunction

// Records the warning to the event log.
Procedure WriteWarning(Ref, ErrorInfo)
	If TypeOf(ErrorInfo) = Type("ErrorInfo") Then
		TextForLog = DetailErrorDescription(ErrorInfo);
	Else
		TextForLog = ErrorInfo;
	EndIf;
	
	WriteLogEvent(
		NStr("en = 'Marked object deletion'"),
		EventLogLevel.Warning,
		,
		Ref,
		TextForLog);
EndProcedure

#EndRegion

#EndIf
