////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
// Common server procedures and functions for working with:
// - infobase data;
// - applied types and value collections;
// - math operations;
// - external connections;
// - forms;
// - types, metadata objects, and their string presentations;
// - metadata object type definition;
// - saving/reading/deleting settings to/from storages;
// - spreadsheet documents;
// - event log;
// - data separation mode;
// - API versioning.
//
// The module also includes auxiliary procedures and functions.
//
////////////////////////////////////////////////////////////////////////////////

#Region Interface

////////////////////////////////////////////////////////////////////////////////
// Common procedures and functions for working with infobase data.

// Returns a structure that contains attribute values read from the infobase by
// object reference.
// 
// If access to any of the attributes is denied, an exception is raised.
// To be able to read attribute values irrespective of current user rights, 
// turn privileged mode on.
// 
// Is not intended for retrieving empty reference attribute values.
//
// Parameters:
//  Ref        - AnyRef - reference to the object whose attribute values are retrieved.
//  Attributes - String - attribute names separated with commas, formatted according to
//               structure requirements 
//               Example: "Code, Description, Parent".
//             - Structure, FixedStructure -  keys are field aliases used for resulting
//               structure keys, values (optional) are field names. If a value is empty, it
//               is considered equal to the key.
//             - Array, FixedArray - attribute names formatted according to structure
//               property requirements.
//
// Returns:
//  Structure - contains names (keys) and values of the requested attributes.
//              If the string of the requested attributes is empty, an empty structure is returned.
//              If an empty reference is passed as the object reference, all return attribute
//              will be Undefined.
//
Function ObjectAttributeValues(Ref, Val Attributes) Export
	
	If TypeOf(Attributes) = Type("String") Then
		If IsBlankString(Attributes) Then
			Return New Structure;
		EndIf;
		Attributes = StringFunctionsClientServer.SplitStringIntoSubstringArray(Attributes, ",", True);
	EndIf;
	
	AttributeStructure = New Structure;
	If TypeOf(Attributes) = Type("Structure") Or TypeOf(Attributes) = Type("FixedStructure") Then
		AttributeStructure = Attributes;
	ElsIf TypeOf(Attributes) = Type("Array") Or TypeOf(Attributes) = Type("FixedArray") Then
		For Each Attribute In Attributes Do
			AttributeStructure.Insert(StrReplace(Attribute, ".", ""), Attribute);
		EndDo;
	Else
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Invalid Attributes parameter type: %1'"),
			String(TypeOf(Attributes)));
	EndIf;
	
	FieldTexts = "";
	For Each KeyAndValue In AttributeStructure Do
		FieldName   = ?(ValueIsFilled(KeyAndValue.Value),
		              TrimAll(KeyAndValue.Value),
		              TrimAll(KeyAndValue.Key));
		
		Alias = TrimAll(KeyAndValue.Key);
		
		FieldTexts  = FieldTexts + ?(IsBlankString(FieldTexts), "", ",") + "" + FieldName + " AS " + Alias;
	EndDo;
	
	Query = New Query;
	Query.SetParameter("Ref", Ref);
	Query.Text =
	"SELECT
	|" + FieldTexts + " FROM " + Ref.Metadata().FullName() + " AS SpecifiedTableAlias
	| WHERE
	| SpecifiedTableAlias.Ref = &Ref
	|";
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Result = New Structure;
	For Each KeyAndValue In AttributeStructure Do
		Result.Insert(KeyAndValue.Key);
	EndDo;
	FillPropertyValues(Result, Selection);
	
	Return Result;
	
EndFunction

// Returns an attribute value read from the infobase by object reference.
// 
// If access to the attribute is denied, an exception is raised.
// To be able to read the attribute value irrespective of current user rights, 
// turn the privileged mode on.
// 
// Is not intended for retrieving empty reference attribute values.
// 
// Parameters:
//  Ref           - AnyRef - reference to a catalog, a document, or any other infobase object.
//  AttributeName - String - for example, "Code".
// 
// Returns:
//  Arbitrary. It depends on the type of the read attribute.

// 
Function ObjectAttributeValue(Ref, AttributeName) Export
	
	Result = ObjectAttributeValues(Ref, AttributeName);
	Return Result[StrReplace(AttributeName, ".", "")];
	
EndFunction
 

// Returns a map that contains attribute values of several objects read from the infobase.
// 
// If access to any of the attributes is denied, an exception is raised.
// To be able to read attribute values irrespective of current user rights, 
// turn privileged mode on.
// 
// Is not intended for retrieving empty reference attribute values.
// 
// Parameters:
//  RefArray       - array of references to objects of the same type (it is important that all
//                   referenced objects have the same type);
//  AttributeNames - String - it must contains attribute names separated with commas.
// 			             These attributes will be used for keys in the resulting structures.
// 			             Example: "Code, Description, Parent".
// 
// Returns:
//  Map where keys are object references, and values are structures that
//  contains AttributeNames as keys and attribute values as values.
// 
Function ObjectsAttributeValues(RefArray, AttributeNames) Export
	
	AttributeValues = New Map;
	If RefArray.Count() = 0 Then
		Return AttributeValues;
	EndIf;
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	Ref AS Ref, " + AttributeNames + "FROM" + RefArray[0].Metadata().FullName() + " AS Table
		| WHERE Table.Ref IN (&RefArray)";
	Query.SetParameter("RefArray", RefArray);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Result = New Structure(AttributeNames);
		FillPropertyValues(Result, Selection);
		AttributeValues[Selection.Ref] = Result;
	EndDo;
	
	Return AttributeValues;
	
EndFunction

// Returns values of a specific attribute for several objects read from the infobase.
// 
// If access to the attribute is denied, an exception is raised.
// To be able to read attribute values irrespective of current user rights, 
// turn privileged mode on.
// 
// Is not intended for retrieving empty reference attribute values.
// 
// Parameters:
//  RefArray     - array of references to objects of the same type (it is important that all
//                 referenced objects have the same type);
// AttributeName - String - for example, "Code".
// 
// Returns:
//  Map where keys are object references, and values are attribute values.
// 
Function ObjectsAttributeValue(RefArray, AttributeName) Export
	
	AttributeValues = ObjectsAttributeValues(RefArray, AttributeName);
	For Each Item In AttributeValues Do
		AttributeValues[Item.Key] = Item.Value[AttributeName];
	EndDo;
		
	Return AttributeValues;
	
EndFunction

// Checks whether the documents are posted.
//
// Parameters:
//  Documents - Array - documents to be checked.
//
// Returns:
//  Array - unposted documents from the Documents array.
//

Function CheckDocumentsPosted(Val Documents) Export
	
	Result = New Array;
	
	QueryPattern = 	
		"SELECT
		|	SpecifiedTableAlias.Ref AS Ref
		|FROM
		|	&DocumentName AS SpecifiedTableAlias
		|WHERE
		|	SpecifiedTableAlias.Ref IN(&DocumentArray)
		|	And Not SpecifiedTableAlias.Posted";
	
	UnionAllText =
		"UNION ALL";
		
	DocumentNames = New Array;
	For Each Document In Documents Do
		DocumentMetadata = Document.Metadata();
		If DocumentNames.Find(DocumentMetadata.FullName()) = Undefined
			And Metadata.Documents.Contains(DocumentMetadata)
			And DocumentMetadata.Posting = Metadata.ObjectProperties.Posting.Allow Then
				DocumentNames.Add(DocumentMetadata.FullName());
		EndIf;
	EndDo;
	
	QueryText = "";
	For Each DocumentName In DocumentNames Do
		If Not IsBlankString(QueryText) Then
			QueryText = QueryText + UnionAllText;
		EndIf;
		SubqueryText = StrReplace(QueryPattern, "&DocumentName", DocumentName);
		QueryText = QueryText + SubqueryText;
	EndDo;
		
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("DocumentArray", Documents);
	
	If Not IsBlankString(QueryText) Then
		Result = Query.Execute().Unload().UnloadColumn("Ref");
	EndIf;
	
	Return Result;
	
EndFunction

// Attempts to post the documents.
//
// Parameters:
// Documents - Array - documents to be posted.
//
// Returns:
// Array - array of structures with the following fields:
// 								Ref              - unposted document;
// 								ErrorDescription - posting error text.
//
Function PostDocuments(Documents) Export

	UnpostedDocuments = New Array;
	
	For Each DocumentRef In Documents Do
		
		CompletedSuccessfully = False;
		DocumentObject = DocumentRef.GetObject();
		If DocumentObject.CheckFilling() Then
			Try
				DocumentObject.Write(DocumentWriteMode.Posting);
				CompletedSuccessfully = True;
			Except
				ErrorPresentation = BriefErrorDescription(ErrorInfo());
			EndTry;
		Else
			ErrorPresentation = NStr("en = 'Document fields are not filled.'");
		EndIf;
		
		If NOT CompletedSuccessfully Then
			UnpostedDocuments.Add(New Structure("Ref,ErrorDescription", DocumentRef, ErrorPresentation));
		EndIf;
		
	EndDo;
	
	Return UnpostedDocuments;
	
EndFunction
 
// Checks whether there are references to the object in the infobase.
//
// Parameters:
//  Ref                     - AnyRef,
//                          - Array of AnyRef.
//  SearchInInternalObjects - Boolean - default value is False.
//                            If it is set to True, the list of search exceptions for 
//                            references will not be taken into account.
//  OtherExceptions         - Array - full names of metadata objects to be also excluded from
//                            the reference search.
// Returns:
//  Boolean.
//
Function ReferencesToObjectFound(Val RefOrRefArray, Val SearchInInternalObjects = False,  OtherExceptions = Undefined) Export
	
	SetPrivilegedMode(True);
	
	If TypeOf(RefOrRefArray) = Type("Array") Then
		RefArray = RefOrRefArray;
	Else
		RefArray = New Array;
		RefArray.Add(RefOrRefArray);
	EndIf;
	
	RefsTable = FindByRef(RefArray);
	RefsTable.Columns[0].Name = "SourceRef";
	RefsTable.Columns[1].Name = "FoundItemReference";
	RefsTable.Columns[2].Name = "FoundMetadata";
	
	If NOT SearchInInternalObjects Then
		RefSearchExclusions = GetOverallRefSearchExceptionList();
		Exceptions = New Array;
		
		For Each TableRow In RefsTable Do
			SearchException = RefSearchExclusions[TableRow.FoundMetadata];
			If SearchException = "*" Then
				Exceptions.Add(TableRow);
			EndIf;
		EndDo;
		
		For Each TableRow In Exceptions Do
			RefsTable.Delete(TableRow);
		EndDo;
	EndIf;
	
	If TypeOf(OtherExceptions) = Type("Array") Then
		RefSearchExclusions = New Map;
		Exceptions = New Array;
		
		For Each FullName In OtherExceptions Do
			MetadataObject = Metadata.FindByFullName(FullName);
			If MetadataObject <> Undefined Then
				RefSearchExclusions.Insert(MetadataObject, "*");
			EndIf;
		EndDo;
		
		For Each TableRow In RefsTable Do
			SearchException = RefSearchExclusions[TableRow.FoundMetadata];
			If SearchException = "*" Then
				Exceptions.Add(TableRow);
			EndIf;
		EndDo;
		
		For Each TableRow In Exceptions Do
			RefsTable.Delete(TableRow);
		EndDo;
	EndIf;
	
	Return RefsTable.Count() > 0;
	
EndFunction

// Replaces references in the entire configuration. There is an option to delete all unused
// references after the replacement.
// References are replaced in transactions by the object to be changed and its relations but
// not by the analyzing reference.
//
// Parameters:
//  ReplacementCouples - Map - Key is a reference to be found, Value is a reference to be
//                       substituted. References to themselves and empty search references are
//                       ignored.
//  Parameters         - Structure - replacement parameters. Can include the following fields:
//                        * DeletionMethod            - String - deletion method marker. Can
//                                                      take the following values:
//                                                       "Directly" - If after the replacement 
//                                                                    the reference is not 
//                                                                    used, it is deleted
//                                                                    directly.
//                                                       "Mark"     - If after the replacement
//                                                                    the reference is not
//                                                                    used, it is marked for
//                                                                    deletion.
//                                                      Any other value means no deletion is
//                                                      required.
//                                                      The default value is an empty string.
//                        * ConsiderBusinessLogic     - Boolean - flag that shows whether the
//                                                      business logic must be taken int
//                                                      accounts when writing objects.
//                                                      The default value is True.
//
//                        * ReplacePairsInTransaction - Boolean - If True, the transaction
//                                                      covers all replacements for one pair of
//                                                      references.
//                                                      False means each reference replacement
//                                                      in a single object is executed in a
//                                                      separate transaction.
//                                                      The default value is True.
//                        * WriteInPrivilegedMode     - Boolean - If True, the data is written
//                                                      in the privileged mode, otherwise the
//                                                      current rights are taken into account.
//                                                      The default value is False.
//     ResultAddress   - String - optional address in a temporary storage where a copy of the
//                       replacement result is saved.
//
// Returns - ValueTable - details on unsuccessful replacements (errors) with the following
//           columns:
//            * Ref                     - AnyRef - reference that cannot be replaced.
//            * ErrorObject             - Arbitrary - Object - error cause.
//            * ErrorObjectPresentation - String - string presentation of the error object.
//            * ErrorType               - String - error type marker. Possible options:
//                                         "LockError"   - some objects were locked during the
//                                                         reference processing.
//                                         "DataChanged" - data was changed by other user
//                                                         during the processing.
//                                         "WriteError"  - cannot write the object.
//                                         "UnknownData" - data not planned to be analyzed was
//                                                         found during the replacement
//                                                         process. The replacement is not
//                                                         completed.
//            * ErrorText               - String - Detailed error description.
//
Function ReplaceReferences(Val ReplacementCouples, Val Parameters = Undefined, Val ResultAddress = "") Export
	
	// Default values
	ReplacementParameters = New Structure;
	ReplacementParameters.Insert("DeleteDirectly",        False); 
	ReplacementParameters.Insert("MarkForDeletion",       False); 
	ReplacementParameters.Insert("ControlOnWrite",        True); 
	ReplacementParameters.Insert("WriteInPrivilegedMode", False);
	
	LongTransaction = True;
	
	If Parameters <> Undefined Then
		ParameterValue = Undefined;
		
		If Parameters.Property("DeletionMethod", ParameterValue) Then
			If ParameterValue = "Directly" Then
				ReplacementParameters.DeleteDirectly  = True;
				ReplacementParameters.MarkForDeletion = False;
			ElsIf ParameterValue = "Mark" Then
				ReplacementParameters.DeleteDirectly  = False;
				ReplacementParameters.MarkForDeletion = True;
			EndIf;
		EndIf;
		
		If Parameters.Property("ConsiderBusinessLogic", ParameterValue) Then
			If ParameterValue = True Then
				ReplacementParameters.ControlOnWrite = True;
			ElsIf ParameterValue = False Then
				ReplacementParameters.ControlOnWrite = False;
			EndIf;
		EndIf;
		
		If Parameters.Property("ReplacePairsInTransaction", ParameterValue) Then
			If ParameterValue = True Then
				LongTransaction = True;
			ElsIf ParameterValue = False Then
				LongTransaction = False;
			EndIf;
		EndIf;
		
		If Parameters.Property("WriteInPrivilegedMode", ParameterValue) Then
			If ParameterValue = True Then
				ReplacementParameters.WriteInPrivilegedMode = True;
			ElsIf ParameterValue = False Then
				ReplacementParameters.WriteInPrivilegedMode = False;
			EndIf;
		EndIf;
		
	EndIf;
	
	StringType = New TypeDescription("String");

	ReplacementResult = New ValueTable;
	ReplacementResult.Columns.Add("Ref");
	ReplacementResult.Columns.Add("ErrorObject");
	ReplacementResult.Columns.Add("ErrorObjectPresentation", StringType);
	ReplacementResult.Columns.Add("ErrorType", StringType);
	ReplacementResult.Columns.Add("ErrorText", StringType);
	ReplacementResult.Indexes.Add("Ref");
	ReplacementResult.Indexes.Add("Ref, ErrorObject, ErrorType");
	
	MetadataCache = New Map;
	
	ReferenceList = New Array;
	For Each KeyValue In ReplacementCouples Do
		CurrentRef = KeyValue.Key;
		DestinationRef = KeyValue.Value;
		
		If CurrentRef = DestinationRef Or CurrentRef.IsEmpty() Then
			// Do not replacing references with themselves and empty strings
			Continue;
		EndIf;
		
		ReferenceList.Add(CurrentRef);
	EndDo;
	
	SearchTable = UsageInstances(ReferenceList);
	
	// Replacements for each object reference is executed in the following order: "Constant",
	// "Object", "Set".
	// At the same time, an empty string in this column is a flag that means the replacement is
	// not required or was already made.
	SearchTable.Columns.Add("ReplacementKey", StringType);
	SearchTable.Indexes.Add("Ref, ReplacementKey");
	SearchTable.Indexes.Add("Data, ReplacementKey");
	
	// Auxiliary data
	SearchTable.Columns.Add("DestinationRef");
	
	Configuration = New Structure;
	Configuration.Insert("AllRefsType",   AllRefsTypeDescription() );
	Configuration.Insert("MetaConstants", Metadata.Constants);
	Configuration.Insert("RecordKeyType", RecordKeysTypeDescription() );
	
	// Defining the processing order and validating items that can be handled
	ReplacementToProcess = New Array;
	For Each CurrentRef In ReferenceList Do
		DestinationRef = ReplacementCouples[CurrentRef];
		
		MarkupResult = Undefined; 
		MarkUsageInstances(Configuration, CurrentRef, DestinationRef, SearchTable, MarkupResult);
		
		If MarkupResult.MarkupErrors.Count() = 0 Then
			ReplacementToProcess.Add(CurrentRef);
			
		Else
			// Unknown replacement types are found, skipping the reference to prevent data from incoherence
			For Each Error In MarkupResult.MarkupErrors Do
				ErrorObjectPresentation = String(Error.Object);
				AddReplacementResult(ReplacementResult, CurrentRef, 
					ReplacementErrorDetails("UnknownData", Error.Object, ErrorObjectPresentation, Error.Text)
				);
			EndDo;
			
		EndIf;
		
	EndDo;
	
	If LongTransaction Then
		For Each Ref In ReplacementToProcess Do
			ReplaceReferenceInLongTransaction(ReplacementResult, Ref, ReplacementParameters, SearchTable);
		EndDo;
	Else
		ReplaceReferenceInShortTransactions(ReplacementResult, ReplacementParameters, ReplacementToProcess, SearchTable);
	EndIf;
	
	If NOT IsBlankString(ResultAddress) Then
		PutToTempStorage(ReplacementResult, ResultAddress);
	EndIf;
	
	Return ReplacementResult;
EndFunction


// Retrieves all places where references are used.
// If any of the references is not used, it will not be presented in the result table.
// 
// Parameters:
//     ReferenceSet  - Array - references whose usage instances are searched.
//     ResultAddress - String - optional address in a temporary storage where a copy of the
//                     replacement result is saved.
// 
// Returns:
//     ValueTable - consists of the following columns:
//       * Ref              - AnyRef         - Reference to be analyzed.
//       * Data             - Arbitrary      - Data that contains the reference to be analyzed.
//       * Metadata         - MetadataObject - Metadata of the found data.
//       * DataPresentation - String - Presentation of the data that contains the reference to
//                            be analyzed.
//       * RefType          - Type - Type of the reference to be analyzed.
//       * AuxiliaryData    - Boolean - True if the data is used by the reference to be 
//                            analyzed as auxiliary data (leading dimension and so on).
//
Function UsageInstances(Val ReferenceSet, Val ResultAddress = "") Export
	
	UsageInstances = New ValueTable;
	
	SetPrivilegedMode(True);
	UsageInstances = FindByRef(ReferenceSet);
	
	UsageInstances.Columns.Add("DataPresentation", New TypeDescription("String"));
	UsageInstances.Columns.Add("RefType");
	UsageInstances.Columns.Add("AuxiliaryData", New TypeDescription("Boolean"));
	
	UsageInstances.Indexes.Add("Ref");
	UsageInstances.Indexes.Add("Data");
	UsageInstances.Indexes.Add("AuxiliaryData");
	UsageInstances.Indexes.Add("Ref, AuxiliaryData");
	
	RecordKeysType = RecordKeysTypeDescription();
	AllRefsType    = AllRefsTypeDescription();
	
	MetaSequences = Metadata.Sequences;
	MetaConstants = Metadata.Constants;
	MetaDocuments = Metadata.Documents;
	
	AuxiliaryMetadata = GetOverallRefSearchExceptionList();
	
	DimensionCache = New Map;
	
	For Each Row In UsageInstances Do
		Ref      = Row.Ref;
		Data     = Row.Data;
		Meta     = Row.Metadata;
		DataType = TypeOf(Data);
		
		AuxiliaryDataPath = AuxiliaryMetadata[Meta];
		
		If AuxiliaryDataPath = Undefined Then
			IsAuxiliaryData = (Ref = Data);
			
		ElsIf AuxiliaryDataPath = "*" Then
			IsAuxiliaryData = True;
			
		ElsIf RecordKeysType.ContainsType(DataType) Then
			IsAuxiliaryData = False;
			For Each DataRow In Data Do
				If Ref = EvaluateDataValueByPath(DataRow, AuxiliaryDataPath) Then
					IsAuxiliaryData = True;
					Break;
				EndIf;
			EndDo;
			
		Else
			IsAuxiliaryData = (Ref = EvaluateDataValueByPath(Data, AuxiliaryDataPath) );
			
		EndIf;
		
		If MetaDocuments.Contains(Meta) Then
			Presentation = String(Data);
			
		ElsIf MetaConstants.Contains(Meta) Then
			Presentation = Meta.Presentation() + " (" + NStr("en = 'constant'") + ")";
			
		ElsIf MetaSequences.Contains(Meta) Then
			Presentation = Meta.Presentation() + " (" + NStr("en = 'sequence'") + ")";
			
		ElsIf DataType = Undefined Then
			Presentation = String(Data);
			
		ElsIf AllRefsType.ContainsType(DataType) Then
			MetaObjectPresentation = New Structure("ObjectPresentation");
			FillPropertyValues(MetaObjectPresentation, Meta);
			If IsBlankString(MetaObjectPresentation.ObjectPresentation) Then
				MetaPresentation = Meta.Presentation();
			Else
				MetaPresentation = MetaObjectPresentation.ObjectPresentation;
			EndIf;
			Presentation = String(Data);
			If NOT IsBlankString(MetaPresentation) Then
				Presentation = Presentation + " (" + MetaPresentation + ")";
			EndIf;
			
		ElsIf RecordKeysType.ContainsType(DataType) Then
			Presentation = Meta.RecordPresentation;
			If IsBlankString(Presentation) Then
				Presentation = Meta.Presentation();
			EndIf;
			
			DimensionDescription = "";
			For Each KeyValue In SetDimensionDescription(Meta, DimensionCache) Do
				Value = Data[KeyValue.Key];
				Details = KeyValue.Value;
				If Value = Ref Then
					If Details.Master Then
						IsAuxiliaryData = True;
					EndIf;
				EndIf;
				Format = Details.Format; 
				DimensionDescription = DimensionDescription + "," 
					+ Details.Presentation + " """ + ?(Format = Undefined, String(Value), Format(Value, Format)) + """";
			EndDo;
			DimensionDescription = Mid(DimensionDescription, 3);
			
			If NOT IsBlankString(DimensionDescription) Then
				Presentation = Presentation + " (" + DimensionDescription + ")";
			EndIf;
			
		Else
			Presentation = String(Data);
			
		EndIf;
		
		Row.DataPresentation = Presentation;
		Row.AuxiliaryData    = IsAuxiliaryData;
		Row.RefType          = TypeOf(Row.Ref);
	EndDo;
	
	If NOT IsBlankString(ResultAddress) Then
		PutToTempStorage(UsageInstances, ResultAddress);
	EndIf;
	
	Return UsageInstances;
EndFunction

// Searches for duplicates for the specified values.
//
// Parameters:
//     SearchArea           - String - data table name (full metadata name) of the search area.
//                            For example "Catalog.ProductsAndServices". The search are
//                            supported in catalogs, charts of characteristic types, 
//                            calculation types, charts of accounts.
//     Item                 - Arbitrary - object with data of the item whose duplicates are
//                            searched.
//     AdditionalParameters - Arbitrary - parameter to be passed to manager event handlers.
//
// Returns:
//     ValueTable - contains rows with descriptions of duplicates.
// 
Function FindItemDuplicates(Val SearchArea, Val SampleObject, Val AdditionalParameters) Export
	
	SearchForDuplicatesParameters = New Structure;
	SearchForDuplicatesParameters.Insert("PrefilterComposer");
	SearchForDuplicatesParameters.Insert("AreaToSearchForDuplicates", SearchArea);
	SearchForDuplicatesParameters.Insert("TakeAppliedRulesIntoAccount", True);
	
	// From parameters
	SearchForDuplicatesParameters.Insert("SearchRules", New ValueTable);
	SearchForDuplicatesParameters.SearchRules.Columns.Add("Attribute", New TypeDescription("String"));
	SearchForDuplicatesParameters.SearchRules.Columns.Add("Rule",  New TypeDescription("String"));
	
	// See DataProcessor.SearchAndDeletionOfDuplicates
	SearchForDuplicatesParameters.PrefilterComposer = New DataCompositionSettingsComposer;
	MetaArea = Metadata.FindByFullName(SearchArea);
	AvailableFilterAttributes = AvailableFilterMetaAttributeNames(MetaArea.StandardAttributes);
	AvailableFilterAttributes = ?(IsBlankString(AvailableFilterAttributes), ",", AvailableFilterAttributes)
		+ AvailableFilterMetaAttributeNames(MetaArea.Attributes);
	
	CompositionSchema = New DataCompositionSchema;
	DataSource = CompositionSchema.DataSources.Add();
	DataSource.DataSourceType = "Local";
	
	DataSet = CompositionSchema.DataSets.Add(Type("DataCompositionSchemaDataSetQuery"));
	DataSet.Query = "SELECT " + Mid(AvailableFilterAttributes, 2) + " FROM" + SearchArea;
	DataSet.AutoFillAvailableFields = True;
	
	SearchForDuplicatesParameters.PrefilterComposer.Initialize( New DataCompositionAvailableSettingsSource(CompositionSchema) );
	
	// Calling the applied script
	SearchProcessing = DataProcessors.SearchAndDeletionOfDuplicates.Create();
	
	SearchAreaManager = SearchProcessing.SearchForDuplicatesAreaManager(SearchArea);
	UseAppliedRules = SearchProcessing.HasSearchForDuplicatesAreaAppliedRules(SearchAreaManager);
	If UseAppliedRules Then
		AppliedParameters = New Structure;
		AppliedParameters.Insert("SearchRules",        SearchForDuplicatesParameters.SearchRules);
		AppliedParameters.Insert("FilterComposer",    SearchForDuplicatesParameters.PrefilterComposer);
		AppliedParameters.Insert("CompareRestrictions", New Array);
		AppliedParameters.Insert("ItemCountForCompare", 1500);
		
		SearchAreaManager.SearchForDuplicatesParameters(AppliedParameters, AdditionalParameters);
		
		SearchForDuplicatesParameters.Insert("AdditionalParameters", AdditionalParameters);
	EndIf;
	
	DuplicateGroups = SearchProcessing.DuplicateGroups(SearchForDuplicatesParameters, SampleObject);
	Result = DuplicateGroups.DuplicateTable;
	
	// Only one group, returning the requiring items
	For Each Row In Result.FindRows(New Structure("Parent", Undefined)) Do
		Result.Delete(Row);
	EndDo;
	EmptyRef = SearchAreaManager.EmptyRef();
	For Each Row In Result.FindRows(New Structure("Ref", EmptyRef)) Do
		Result.Delete(Row);
	EndDo;
	
	Return Result; 
EndFunction

// Returns a type description that includes all configuration reference types.
//
Function AllRefsTypeDescription() Export
	
	Return New TypeDescription(New TypeDescription(New TypeDescription(New TypeDescription(New TypeDescription(
		New TypeDescription(New TypeDescription(New TypeDescription(New TypeDescription(
			   Catalogs.AllRefsType(),
			   Documents.AllRefsType().Types()
			), ExchangePlans.AllRefsType().Types()
			), Enums.AllRefsType().Types()
			), ChartsOfCharacteristicTypes.AllRefsType().Types()
			), ChartsOfAccounts.AllRefsType().Types()
			), ChartsOfCalculationTypes.AllRefsType().Types()
			), BusinessProcesses.AllRefsType().Types()
			), BusinessProcesses.RoutePointsAllRefsType().Types()
			), Tasks.AllRefsType().Types()
		);
	
EndFunction


////////////////////////////////////////////////////////////////////////////////
// Common procedures and functions for handling applied types and value collection

// Retrieves the name of the enumeration value as a metadata object.
//
// Parameters:
//  Value - value of the enumeration whose name is retrieved.
//
// Returns:
//  String - enumeration value name as a metadata object.
//
Function EnumValueName(Value) Export
	
	MetadataObject = Value.Metadata();
	
	ValueIndex = Enums[MetadataObject.Name].IndexOf(Value);
	
	Return MetadataObject.EnumValues[ValueIndex].Name;
	
EndFunction 

// Fills the destination array with unique values from the source array.
// If an element from the source array is already present, it is not added.
//
// Parameters:
//  DestinationArray – Array – array to be filled with unique values;
//  SourceArray      – Array – array of values for filling DestinationArray.
//
Procedure FillArrayWithUniqueValues(DestinationArray, SourceArray) Export
	
	UniqueValues = New Map;
	
	For Each Value In DestinationArray Do
		UniqueValues.Insert(Value, True);
	EndDo;
	
	For Each Value In SourceArray Do
		If UniqueValues[Value] = Undefined Then
			DestinationArray.Add(Value);
			UniqueValues.Insert(Value, True);
		EndIf;
	EndDo;
	
EndProcedure

// Deletes AttributeArray elements that match object attribute names from 
// the NoncheckableAttributeArray array.
// The procedure is intended to be used in FillCheckProcessing event handlers.
//
// Parameters:
// AttributeArray             - Array of String - contains names of object attributes;
// NoncheckableAttributeArray - Array of String - contains names of object attributes
//                              excluded from checking.
//
Procedure DeleteNoCheckAttributesFromArray(AttributeArray, NoncheckableAttributeArray) Export
	
	For Each ArrayElement In NoncheckableAttributeArray Do
	
		SequenceNumber = AttributeArray.Find(ArrayElement);
		If SequenceNumber <> Undefined Then
			AttributeArray.Delete(SequenceNumber);
		EndIf;
	
	EndDo;
	
EndProcedure

//	Converts the value table into an array.
//	Use this function to pass data  received on the server as a value table to the client.
//	This is only possible if all of values from the value table can be passed to the client.
//
//	The resulting array contains structures that duplicate value table row structures.
//
//	It is recommended that you do not use this procedure to convert value tables
//	with a large number of rows.
//
//	Parameters: 
//	  ValueTable - ValueTable.
//
//	Returns:
//	  Array.
//
Function ValueTableToArray(ValueTable) Export
	
	Array = New Array();
	StructureString = "";
	CommaRequired = False;
	For Each Column In ValueTable.Columns Do
		If CommaRequired Then
			StructureString = StructureString + ",";
		EndIf;
		StructureString = StructureString + Column.Name;
		CommaRequired = True;
	EndDo;
	For Each String In ValueTable Do
		NewRow = New Structure(StructureString);
		FillPropertyValues(NewRow, String);
		Array.Add(NewRow);
	EndDo;
	Return Array;

EndFunction

// Creates a structure with properties whose names match the value table column names
// of the passed row. Fills this structure with values from the row.
// 
// Parameters:
//  ValueTableRow - ValueTableRow.
//
// Returns:
//  Structure.
//
Function ValueTableRowToStructure(ValueTableRow) Export
	
	Structure = New Structure;
	For Each Column In ValueTableRow.Owner().Columns Do
		Structure.Insert(Column.Name, ValueTableRow[Column.Name]);
	EndDo;
	
	Return Structure;
	
EndFunction

// Creates a structure that matches the information register record manager. 
// 
// Parameters:
//  RecordManager    - InformationRegisterRecordManager;
//  RegisterMetadata - information register metadata.
//
Function StructureByRecordManager(RecordManager, RegisterMetadata) Export
	
	RecordAsStructure = New Structure;
	
	If RegisterMetadata.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then
		RecordAsStructure.Insert("Period", RecordManager.Period);
	EndIf;
	For Each Field In RegisterMetadata.Dimensions Do
		RecordAsStructure.Insert(Field.Name, RecordManager[Field.Name]);
	EndDo;
	For Each Field In RegisterMetadata.Resources Do
		RecordAsStructure.Insert(Field.Name, RecordManager[Field.Name]);
	EndDo;
	For Each Field In RegisterMetadata.Attributes Do
		RecordAsStructure.Insert(Field.Name, RecordManager[Field.Name]);
	EndDo;
	
	Return RecordAsStructure;
	
EndFunction

// Creates an array and copies values from the row collection column into this array.
//
// Parameters:
// RowCollection    - collection where iteration using For each ... In ... Do operator 
//                    is available;
// ColumnName       - String - name of the collection field to be retrieved;
// UniqueValuesOnly - Boolean, optional - if True, the resulting array will contain unique
//                     values only. 
//
Function UnloadColumn(RowCollection, ColumnName, UniqueValuesOnly = False) Export

	ValueArray = New Array;
	
	UniqueValues = New Map;
	
	For Each CollectionRow In RowCollection Do
		Value = CollectionRow[ColumnName];
		If UniqueValuesOnly And UniqueValues[Value] <> Undefined Then
			Continue;
		EndIf;
		ValueArray.Add(Value);
		UniqueValues.Insert(Value, True);
	EndDo; 
	
	Return ValueArray;
	
EndFunction

// Converts XML text into a structure with value tables.
// The function creates table columns based on the XML description.
//
// Parameters:
//  XML - text in the XML format.
//
// XML schema:
//<?xml version="1.0" encoding="utf-8"?>
//<xs:schema attributeFormDefault="unqualified" elementFormDefault="qualified" xmlns:xs="http://www.w3.org/2001/XMLSchema">
// <xs:element name="Items">
//	<xs:complexType>
//	 <xs:sequence>
//		<xs:element maxOccurs="unbounded" name="Item">
//		 <xs:complexType>
//			<xs:attribute name="Code" type="xs:integer" use="required" />
//			<xs:attribute name="Name" type="xs:string" use="required" />
//			<xs:attribute name="Abbr" type="xs:string" use="required" />
//			<xs:attribute name="Index" type="xs:string" use="required" />
//		 </xs:complexType>
//		</xs:element>
//	 </xs:sequence>
//	 <xs:attribute name="Description" type="xs:string" use="required" />
//	 <xs:attribute name="Columns" type="xs:string" use="required" />
//	</xs:complexType>
// </xs:element>
//</xs:schema>
//
// Example:
// ClassifierTable = ReadXMLToTable(InformationRegisters.AddressClassifier.
// GetTemplate("AddressClassifierUnits").GetText());
//
// Returns:
//  Structure - with the following fields: 
//    * TableName - String.
//    * Data      - ValueTable.
//
Function ReadXMLToTable(Val XML) Export
	
	If TypeOf(XML) <> Type("XMLReader") Then
		Reader = New XMLReader;
		Reader.SetString(XML);
	Else
		Reader = XML;
	EndIf;
	
	// Reading the first node and checking it
	If Not Reader.Read() Then
			Raise NStr("en = 'XML is empty'");
	ElsIf Reader.Name <> "Items" Then
		Raise NStr("en = 'Error in the XML structure'");
	EndIf;
	
	// Getting table details and creating the table
	TableName = Reader.GetAttribute("Description");
	ColumnNames = StrReplace(Reader.GetAttribute("Columns"), ",", Chars.LF);
	Columns = StrLineCount(ColumnNames);
	
	ValueTable = New ValueTable;
	For Cnt = 1 to Columns Do
		ValueTable.Columns.Add(StrGetLine(ColumnNames, Cnt), New TypeDescription("String"));
	EndDo;
	
	// Filling the table with values
	While Reader.Read() Do
		
		If Reader.NodeType = XMLNodeType.EndElement AND Reader.Name = "Items" Then
			Break;
		ElsIf Reader.NodeType <> XMLNodeType.StartElement Then
			Continue;
		ElsIf Reader.Name <> "Item" Then
			Raise NStr("en = 'Error in the XML structure'");
		EndIf;
		
		NewRow = ValueTable.Add();
		For Cnt = 1 to Columns Do
			ColumnName = StrGetLine(ColumnNames, Cnt);
			NewRow[Cnt-1] = Reader.GetAttribute(ColumnName);
		EndDo;
		
	EndDo;
	
	// Filling the resulting value table
	Result = New Structure;
	Result.Insert("TableName", TableName);
	Result.Insert("Data", ValueTable);
	
	Return Result;
	
EndFunction

// Compares two row collections. 
// Both collections must meet the following requirements:
// - iteration using For each ... In ... Do operator is available;
// - both collections include all columns that are passed to the ColumnNames parameter.
// If ColumnNames is empty, all columns included in one of the collections must be included 
// into the other one and vice versa.
//
// Parameters:
// RowsCollection1   - ValueCollection - collection that meets the requirements listed above;
// RowsCollection2   - ValueCollection - collection that meets the requirements listed above;
// ColumnNames       - String - names of columns separated with commas 
// 					            whose values will be compared. 
// 					            This parameter is optional for collections
// 					            that allow retrieving their column names:
// 					            ValueTable, ValueList, Map, and Structure.
// 					            If this parameter is not specified, values of all columns
// 					            will be compared. For collections of other types,
// 					            this parameter is mandatory.
// ExcludingColumns  - String - names of columns whose values are not compared. Optional.
// IncludingRowOrder - Boolean - If True, the collections are considered 
// 					            equal only if they have identical row order.
//
// Returns:
//  Boolean.
//
Function IdenticalCollections(RowsCollection1, RowsCollection2, ColumnNames = "", ExcludingColumns = "", IncludingRowOrder = False) Export
	
	// Collection types that allow retrieving their column names
	SpecialCollectionTypes = New Array;
	SpecialCollectionTypes.Add(Type("ValueTable"));
	SpecialCollectionTypes.Add(Type("ValueList"));
	
	KeyAndValueCollectionTypes = New Array;
	KeyAndValueCollectionTypes.Add(Type("Map"));
	KeyAndValueCollectionTypes.Add(Type("Structure"));
	KeyAndValueCollectionTypes.Add(Type("FixedMap"));
	KeyAndValueCollectionTypes.Add(Type("FixedStructure"));
	
	If IsBlankString(ColumnNames) Then
		If SpecialCollectionTypes.Find(TypeOf(RowsCollection1)) <> Undefined 
			Or KeyAndValueCollectionTypes.Find(TypeOf(RowsCollection1)) <> Undefined Then
			ColumnsToCompare = New Array;
			If TypeOf(RowsCollection1) = Type("ValueTable") Then
				For Each Column In RowsCollection1.Columns Do
					ColumnsToCompare.Add(Column.Name);
				EndDo;
			ElsIf TypeOf(RowsCollection1) = Type("ValueList") Then
				ColumnsToCompare.Add("Value");
				ColumnsToCompare.Add("Picture");
				ColumnsToCompare.Add("Check");
				ColumnsToCompare.Add("Presentation");
			ElsIf KeyAndValueCollectionTypes.Find(TypeOf(RowsCollection1)) <> Undefined Then
				ColumnsToCompare.Add("Key");
				ColumnsToCompare.Add("Value");
			EndIf;
		Else
			ErrorMessage = NStr("en = 'For collections of the %1 type, you have to specify names of fields that will be compared.'");
			Raise StringFunctionsClientServer.SubstituteParametersInString(ErrorMessage, TypeOf(RowsCollection1));
		EndIf;
	Else
		ColumnsToCompare = StringFunctionsClientServer.SplitStringIntoSubstringArray(ColumnNames);
	EndIf;

	// Removing excluded columns
	ColumnsToCompare = CommonUseClientServer.ReduceArray(ColumnsToCompare, 
						StringFunctionsClientServer.SplitStringIntoSubstringArray(ExcludingColumns));
						
	If IncludingRowOrder Then
		
		// Iterating both collections in parallel
		CollectionRowNumber1 = 0;
		For Each CollectionRow1 In RowsCollection1 Do
			// Searching for the same row in the second collection
			CollectionRowNumber2 = 0;
			HasCollectionRows2 = False;
			For Each CollectionRow2 In RowsCollection2 Do
				HasCollectionRows2 = True;
				If CollectionRowNumber2 = CollectionRowNumber1 Then
					Break;
				EndIf;
				CollectionRowNumber2 = CollectionRowNumber2 + 1;
			EndDo;
			If Not HasCollectionRows2 Then
				// Second collection has no rows
				Return False;
			EndIf;
			// Comparing field values for two rows
			For Each ColumnName In ColumnsToCompare Do
				If CollectionRow1[ColumnName] <> CollectionRow2[ColumnName] Then
					Return False;
				EndIf;
			EndDo;
			CollectionRowNumber1 = CollectionRowNumber1 + 1;
		EndDo;
		
		CollectionRowCount1 = CollectionRowNumber1;
		
		// Calculating rows in the second collection
		CollectionRowCount2 = 0;
		For Each CollectionRow2 In RowsCollection2 Do
			CollectionRowCount2 = CollectionRowCount2 + 1;
		EndDo;
		
		// If the first collection has no rows, 
		// the second collection must have no rows too.
		If CollectionRowCount1 = 0 Then
			For Each CollectionRow2 In RowsCollection2 Do
				Return False;
			EndDo;
			CollectionRowCount2 = 0;
		EndIf;
		
		// Number of rows must be equal in both collections
		If CollectionRowCount1 <> CollectionRowCount2 Then
			Return False;
		EndIf;
		
	Else
	
		// Compares two row collections without taking row order into account.
		
		// Accumulating compared rows in the first collection to ensure that:
		// - the search for identical rows is only performed once,
		// - all accumulated rows exist in the second collection.
		
		FilterRows = New ValueTable;
		FilterParameters = New Structure;
		For Each ColumnName In ColumnsToCompare Do
			FilterRows.Columns.Add(ColumnName);
			FilterParameters.Insert(ColumnName);
		EndDo;
		
		HasCollectionRows1 = False;
		For Each FilterRow In RowsCollection1 Do
			
			FillPropertyValues(FilterParameters, FilterRow);
			If FilterRows.FindRows(FilterParameters).Count() > 0 Then
				// The row with such field values is already checked
				Continue;
			EndIf;
			FillPropertyValues(FilterRows.Add(), FilterRow);
			
			// Calculating the number of rows in the first collection
			CollectionRowsFound1 = 0;
			For Each CollectionRow1 In RowsCollection1 Do
				RowFits = True;
				For Each ColumnName In ColumnsToCompare Do
					If CollectionRow1[ColumnName] <> FilterRow[ColumnName] Then
						RowFits = False;
						Break;
					EndIf;
				EndDo;
				If RowFits Then
					CollectionRowsFound1 = CollectionRowsFound1 + 1;
				EndIf;
			EndDo;
			
			// Calculating the number of rows in the second collection
			CollectionRowsFound2 = 0;
			For Each CollectionRow2 In RowsCollection2 Do
				RowFits = True;
				For Each ColumnName In ColumnsToCompare Do
					If CollectionRow2[ColumnName] <> FilterRow[ColumnName] Then
						RowFits = False;
						Break;
					EndIf;
				EndDo;
				If RowFits Then
					CollectionRowsFound2 = CollectionRowsFound2 + 1;
					// If the number of rows in the second collection is greater then the number of 
					// rows in the first one, the collections are not equal.
					If CollectionRowsFound2 > CollectionRowsFound1 Then
						Return False;
					EndIf;
				EndIf;
			EndDo;
			
			// The number of rows must be equal for both collections
			If CollectionRowsFound1 <> CollectionRowsFound2 Then
				Return False;
			EndIf;
			
			HasCollectionRows1 = True;
			
		EndDo;
		
		// If the first collection has no rows, 
		// the second collection must have no rows too.
		If Not HasCollectionRows1 Then
			For Each CollectionRow2 In RowsCollection2 Do
				Return False;
			EndDo;
		EndIf;
		
		// Checking that all rows from the second collection exist in the first one.
		For Each CollectionRow2 In RowsCollection2 Do
			FillPropertyValues(FilterParameters, CollectionRow2);
			If FilterRows.FindRows(FilterParameters).Count() = 0 Then
				Return False;
			EndIf;
		EndDo;
	
	EndIf;
	
	Return True;
	
EndFunction

// Compares data of a complex structure taking nesting into account.
//
// Parameters:
//  Data1 - Structure ,   FixedStructure -
//        - Map,          FixedMap -
//        - Array,        FixedArray - 
//        - ValueStorage, ValueTable -
//        - Simple types - that can be compared for equality, for example, String, Number, Boolean.
//
//  Data2 - Arbitrary - same types that the Data1 parameter has.
//
// Returns:
//  Boolean.
//
Function IsEqualData(Data1, Data2) Export
	
	If TypeOf(Data1) <> TypeOf(Data2) Then
		Return False;
	EndIf;
	
	If TypeOf(Data1) = Type("Structure")
	 Or TypeOf(Data1) = Type("FixedStructure") Then
		
		If Data1.Count() <> Data2.Count() Then
			Return False;
		EndIf;
		
		For Each KeyAndValue In Data1 Do
			OldValue = Undefined;
			
			If NOT Data2.Property(KeyAndValue.Key, OldValue)
			 Or NOT IsEqualData(KeyAndValue.Value, OldValue) Then
			
				Return False;
			EndIf;
		EndDo;
		
		Return True;
		
	ElsIf TypeOf(Data1) = Type("Map")
	      Or TypeOf(Data1) = Type("FixedMap") Then
		
		If Data1.Count() <> Data2.Count() Then
			Return False;
		EndIf;
		
		NewMapKeys = New Map;
		
		For Each KeyAndValue In Data1 Do
			NewMapKeys.Insert(KeyAndValue.Key, True);
			OldValue = Data2.Get(KeyAndValue.Key);
			
			If NOT IsEqualData(KeyAndValue.Value, OldValue) Then
				Return False;
			EndIf;
		EndDo;
		
		For Each KeyAndValue In Data2 Do
			If NewMapKeys[KeyAndValue.Key] = Undefined Then
				Return False;
			EndIf;
		EndDo;
		
		Return True;
		
	ElsIf TypeOf(Data1) = Type("Array")
	      Or TypeOf(Data1) = Type("FixedArray") Then
		
		If Data1.Count() <> Data2.Count() Then
			Return False;
		EndIf;
		
		Index = Data1.Count()-1;
		While Index >= 0 Do
			If NOT IsEqualData(Data1.Get(Index), Data2.Get(Index)) Then
				Return False;
			EndIf;
			Index = Index - 1;
		EndDo;
		
		Return True;
		
	ElsIf TypeOf(Data1) = Type("ValueTable") Then
		
		If Data1.Count() <> Data2.Count() Then
			Return False;
		EndIf;
		
		If Data1.Columns.Count() <> Data2.Columns.Count() Then
			Return False;
		EndIf;
		
		For Each Column In Data1.Columns Do
			If Data2.Columns.Find(Column.Name) = Undefined Then
				Return False;
			EndIf;
			
			Index = Data1.Count()-1;
			While Index >= 0 Do
				If NOT IsEqualData(Data1[Index][Column.Name], Data2[Index][Column.Name]) Then
					Return False;
				EndIf;
				Index = Index - 1;
			EndDo;
		EndDo;
		
		Return True;
		
	ElsIf TypeOf(Data1) = Type("ValueStorage") Then
	
		If NOT IsEqualData(Data1.Get(), Data2.Get()) Then
			Return False;
		EndIf;
		
		Return True;
	EndIf;
	
	Return Data1 = Data2;
	
EndFunction

// Fixes data of the Structure, Map, and Array types taking nesting into account.
//
// Parameters:
//  Data           - Structure, Map, Array - collection, whose values are primitive types,
//                   value storages, or cannot be changed. The following value types are
//                   supported: Boolean, String, Number, Date, Undefined, UUID, Null, Type,
//                              ValueStorage, CommonModule, MetadataObject, XDTOValueType,
//                              XDTODataObjectType, AnyRef.
//
//  RaiseException - Boolean - initial value is True. If it is False and there is data that
//                   cannot be fixed, no exception is raised but as much data as possible is
//                   fixed.
//
// Returns:
//  Fixed data, similar to the data passed in the Data parameter.
// 
Function FixedData(Data, RaiseException = True) Export
	
	If TypeOf(Data) = Type("Array") Then
		Array = New Array;
		
		Index = Data.Count() - 1;
		
		For Each Value In Data Do
			
			If TypeOf(Value) = Type("Structure")
			 Or TypeOf(Value) = Type("Map")
			 Or TypeOf(Value) = Type("Array") Then
				
				Array.Add(FixedData(Value, RaiseException));
			Else
				If RaiseException Then
					CheckDataFixed(Value, True);
				EndIf;
				Array.Add(Value);
			EndIf;
		EndDo;
		
		Return New FixedArray(Array);
		
	ElsIf TypeOf(Data) = Type("Structure")
	      Or TypeOf(Data) = Type("Map") Then
		
		If TypeOf(Data) = Type("Structure") Then
			Collection = New Structure;
		Else
			Collection = New Map;
		EndIf;
		
		For Each KeyAndValue In Data Do
			Value = KeyAndValue.Value;
			
			If TypeOf(Value) = Type("Structure")
			 Or TypeOf(Value) = Type("Map")
			 Or TypeOf(Value) = Type("Array") Then
				
				Collection.Insert(
					KeyAndValue.Key, FixedData(Value, RaiseException));
			Else
				If RaiseException Then
					CheckDataFixed(Value, True);
				EndIf;
				Collection.Insert(KeyAndValue.Key, Value);
			EndIf;
		EndDo;
		
		If TypeOf(Data) = Type("Structure") Then
			Return New FixedStructure(Collection);
		Else
			Return New FixedMap(Collection);
		EndIf;
		
	ElsIf RaiseException Then
		CheckDataFixed(Data);
	EndIf;
	
	Return Data;
	
EndFunction

// Clones the XDTO object.
//
// Parameters:
//  Factory - XDTOFactory - factory that created the source object.
//  Object  - XDTODataObject  - object, whose copy will be create.
//
// Returns:
//  XDTODataObject - copy of the source XDTO object
//
Function CopyXDTO(Val Factory, Val Object) Export
	
	Write = New XMLWriter;
	Write.SetString();
	Factory.WriteXML(Write, Object, , , , XMLTypeAssignment.Explicit);
	
	XMLPresentation = Write.Close();
	
	Reader = New XMLReader;
	Reader.SetString(XMLPresentation);
	
	Return Factory.ReadXML(Reader, Object.Type());
	
EndFunction

// Returns XML presentation of the XDTO type.
//
// Parameters:
//  XDTOType - XDTODataObjectType, XDTOValueType - XDTO type whose XML presentation will be retrieved
//
// Returns:
//  String - XML presentation of the XDTO type.
//
Function XDTOTypePresentation(XDTOType) Export
	
	Return XDTOSerializer.XMLString(New XMLExpandedName(XDTOType.NamespaceURI, XDTOType.Name))
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Math procedures and functions

// Distributes the amount according to the specified coefficients.
//
// Parameters:
// 	AmountToDistribute       - Number - amount to be distributed; 
// 	DistributionCoefficients - Array - weight coefficients; 
// 	Accuracy                 - rounding accuracy. Optional.
//
// Returns:
// 	Array - array of the distributed amounts.
//           It contains amounts calculated according to the distribution coefficients
//           If distribution cannot be performed (amount = 0, number of coefficients = 0,
//           or coefficient sum = 0), the return value is Undefined.
//

Function DistributeAmountProportionallyCoefficients(Val AmountToDistribute, DistributionCoefficients, Val Accuracy = 2) Export
	
	Return CommonUseClientServer.DistributeAmountProportionallyCoefficients(AmountToDistribute, DistributionCoefficients, Accuracy);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for working with external connections.

// Returns the COM class name for establishing connection to 1C:Enterprise.
//
Function COMConnectorName() Export
	
	SystemInfo = New SystemInfo;
	VersionSubstrings = StringFunctionsClientServer.SplitStringIntoSubstringArray(
		SystemInfo.AppVersion, ".");
	Return "v" + VersionSubstrings[0] + VersionSubstrings[1] + ".COMConnector";
	
EndFunction


// Returns the CLSID COM class for working with 1C:Enterprise 8 through a COM connection.
//
// Parameters:
//  COMConnectorName - String - name of the COM class for working with 1C:Enterprise 8 through
//                     a COM connection.
//
// Returns:
//  String - string presentation of CLSID.
//
Function COMConnectorID(Val COMConnectorName) Export
	
	If COMConnectorName = "v83.COMConnector" Then
	
		Return "181E893D-73A4-4722-B61D-D604B3D67D47";
		
	EndIf;
	
	ErrorMessage = NStr("en = 'CLSID for the %1 class is not specified'");
	ErrorMessage = StringFunctionsClientServer.SubstituteParametersInString(ErrorMessage, COMConnectorName);
	Raise ErrorMessage;
	
EndFunction

// Establishes an external connection to the infobase by passed connection parameters,
// and returns this connection.
// 
// Parameters:
//  Parameters        - Structure - contains parameters for establishing an external connection 
//                      to the infobase.
//                      See the CommonUseClientServer.ExternalConnectionParameterStructure
//                      function for details:
//                       * InfobaseOperationMode        - Number - infobase operation mode: 0 
//                                                        for the file mode, 1 for the
//                                                        client/server mode;
//                       * InfobaseDirectory            - String - infobase directory, used in 
//                                                        the file mode;
//                       * PlatformServerName           - String - platform server name, used 
//                                                        in the client/server mode;
//                       * InfobaseNameAtPlatformServer - String - infobase name at the 
//                                                        platform server;
//                       * OSAuthentication             - Boolean - flag that shows whether the
//                                                        infobase user is selected based on 
//                                                        the operating system user;
//                       * UserName                     - String - infobase user name;
//                       * UserPassword                 - String - infobase user password.
// 
// ErrorMessageString – String – optional. If an error occurs when establishing the external
//                      connection, the error message text is returned to this parameter.
//
// Returns:
//  COM object - if the external connection has been established successfully;
//  Undefined  - if the external connection has not been established.
//
Function EstablishExternalConnection(Parameters, ErrorMessageString = "", ErrorAttachingAddIn = False) Export
	Result = EstablishExternalConnectionWithInfobase(Parameters);
	ErrorAttachingAddIn = Result.ErrorAttachingAddIn;
	ErrorMessageString  = Result.DetailedErrorDetails;
	
	Return Result.Connection;
EndFunction


// Establishes an external connection to the infobase by passed connection parameters,
// and returns a pointer to this connection.
// 
// Parameters:
//  Parameters        - Structure - contains parameters for establishing an external connection 
//                      to the infobase.
//                      See the CommonUseClientServer.ExternalConnectionParameterStructure
//                      function for details:
//                       * InfobaseOperationMode        - Number - infobase operation mode: 0 
//                                                        for the file mode, 1 for the
//                                                        client/server mode;
//                       * InfobaseDirectory            - String - infobase directory, used in 
//                                                        the file mode;
//                       * PlatformServerName           - String - platform server name, used 
//                                                        in the client/server mode;
//                       * InfobaseNameAtPlatformServer - String - infobase name at the 
//                                                        platform server;
//                       * OSAuthentication             - Boolean - flag that shows whether the
//                                                        infobase user is selected based on 
//                                                        the operating system user;
//                       * UserName                     - String - infobase user name;
//                       * UserPassword                 - String - infobase user password.
// 
// ErrorMessageString – String – optional. If an error occurs when establishing the external
//                      connection, the error message text is returned to this parameter.
// 
// Returns:
//  Structure:
//    * Connection           - COMObject, Undefined - COM object pointer or Undefined if a
//                             connection error occurred;
//    * BriefErrorDetails    - String - brief error description;
//    * DetailedErrorDetails - String - detailed error description;
//    * ErrorAttachingAddIn  - Boolean - COM connection error flag.
//
Function EstablishExternalConnectionWithInfobase(Parameters) Export
	
	Result = New Structure("Connection, BriefErrorDetails, DetailedErrorDetails, ErrorAttachingAddIn",
	Undefined, "", "", False);
	
	If IsLinuxServer() Then
		Result.Connection = Undefined;
		Result.DetailedErrorDetails = NStr("en = 'A direct connection to the infobase is not supported on a server that runs Linux.'");
		Result.BriefErrorDetails = Result.DetailedErrorDetails;
		Return Result;
	EndIf;
	
	Try
		COMConnector = New COMObject(COMConnectorName()); // "V83.COMConnector"
	Except
		Information = ErrorInfo();
		ErrorMessageString = NStr("en = 'Cannot establish a connection to another application: %1'");
		
		Result.ErrorAttachingAddIn  = True;
		Result.DetailedErrorDetails = StringFunctionsClientServer.SubstituteParametersInString(ErrorMessageString, DetailErrorDescription(Information));
		Result.BriefErrorDetails    = StringFunctionsClientServer.SubstituteParametersInString(ErrorMessageString, BriefErrorDescription(Information));
		
		Return Result;
	EndTry;
	
	If Parameters.InfobaseOperationMode = 0 Then
		// File mode
		If IsBlankString(Parameters.InfobaseDirectory) Then
			ErrorMessageString = NStr("en = 'The infobase directory location is not set.'");
			Result.DetailedErrorDetails = ErrorMessageString;
			Result.BriefErrorDetails   = ErrorMessageString;
			Return Result;
			
		EndIf;
		
		If Parameters.OSAuthentication Then
			ConnectionString = "File = ""&InfobaseDirectory""";
			
			ConnectionString = StrReplace(ConnectionString, "&InfobaseDirectory", Parameters.InfobaseDirectory);
			
		Else
			ConnectionString = "File = ""&InfobaseDirectory""; Usr = ""&UserName""; Pwd = ""&UserPassword""";
			
			ConnectionString = StrReplace(ConnectionString, "&InfobaseDirectory", Parameters.InfobaseDirectory);
			ConnectionString = StrReplace(ConnectionString, "&UserName",           Parameters.UserName);
			ConnectionString = StrReplace(ConnectionString, "&UserPassword",        Parameters.UserPassword);
			
		EndIf;
		
	Else 
		// Client/server mode
		If IsBlankString(Parameters.PlatformServerName) Or IsBlankString(Parameters.InfobaseNameAtPlatformServer) Then
			ErrorMessageString = NStr("en = 'The mandatory connection parameters are not set: ""Server name""; ""Infobase name on the server"".'");
			
			Result.DetailedErrorDetails = ErrorMessageString;
			Result.BriefErrorDetails   = ErrorMessageString;
			Return Result;
			
		EndIf;
		
		If Parameters.OSAuthentication Then
			ConnectionString = "Srvr = ""&PlatformServerName""; Ref = ""&InfobaseNameAtPlatformServer"";";
			
			ConnectionString = StrReplace(ConnectionString, "&PlatformServerName",                     Parameters.PlatformServerName);
			ConnectionString = StrReplace(ConnectionString, "&InfobaseNameAtPlatformServer", Parameters.InfobaseNameAtPlatformServer);
			
		Else
			ConnectionString = "Srvr = ""&PlatformServerName""; Ref = ""&InfobaseNameAtPlatformServer""; Usr = ""&UserName""; Pwd = ""&UserPassword""";
			
			ConnectionString = StrReplace(ConnectionString, "&PlatformServerName",                     Parameters.PlatformServerName);
			ConnectionString = StrReplace(ConnectionString, "&InfobaseNameAtPlatformServer", Parameters.InfobaseNameAtPlatformServer);
			ConnectionString = StrReplace(ConnectionString, "&UserName",                             Parameters.UserName);
			ConnectionString = StrReplace(ConnectionString, "&UserPassword",                          Parameters.UserPassword);
			
		EndIf;
		
	EndIf;
	
	Try
		Result.Connection = COMConnector.Connect(ConnectionString);
	Except
		Information = ErrorInfo();
		ErrorMessageString = NStr("en = 'Cannot establish a connection to another application: %1'");
		
		Result.ErrorAttachingAddIn = True;
		Result.DetailedErrorDetails     = StringFunctionsClientServer.SubstituteParametersInString(ErrorMessageString, DetailErrorDescription(Information));
		Result.BriefErrorDetails       = StringFunctionsClientServer.SubstituteParametersInString(ErrorMessageString, BriefErrorDescription(Information));
		
	EndTry;
	
	Return Result;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Auxiliary procedures and functions

// Determines the infobase mode: file (True) or client/server (False).
// This function uses the InfobaseConnectionString parameter. 
// You can specify this parameter explicitly.
//
// Parameters:
// InfobaseConnectionString - String - if this parameter is empty, 
// the connection string of the current infobase connection is used.
//
// Returns:
// Boolean.
//
Function FileInfobase(Val InfobaseConnectionString = "") Export
			
	If IsBlankString(InfobaseConnectionString) Then
		InfobaseConnectionString = InfobaseConnectionString();
	EndIf;
	Return Find(Upper(InfobaseConnectionString), "FILE=") = 1;
	
EndFunction 
 
// Resets session parameters to Not set. 
// 
// Parameters: 
// ClearingParameters - String - names of session parameters to be cleared separated with
//                      commas;
// Exceptions         - String - names of the session parameters to be preserved separated with 
//                      commas.
//
Procedure ClearSessionParameters(ClearingParameters = "", Exceptions = "") Export
	  
	ExceptionArray             = StringFunctionsClientServer.SplitStringIntoSubstringArray(Exceptions);
	ParametersForClearingArray = StringFunctionsClientServer.SplitStringIntoSubstringArray(ClearingParameters);
	
	If ParametersForClearingArray.Count() = 0 Then
		For Each SessionParameter In Metadata.SessionParameters Do
			If ExceptionArray.Find(SessionParameter.Name) = Undefined Then
				ParametersForClearingArray.Add(SessionParameter.Name);
			EndIf;
		EndDo;
	EndIf;
	
	Index = ParametersForClearingArray.Find("ClientParametersOnServer");
	If Index > 0 Then
		ParametersForClearingArray.Delete(Index);
	EndIf;
	
	SessionParameters.Clear(ParametersForClearingArray);
	
EndProcedure

// Returns subject details in the string format.
// 
// Parameters
// SubjectRef – AnyRef – object of reference type.
//
// Returns:
// String
// 
Function SubjectString(SubjectRef) Export
	
	Result = "";
	
	EventHandlers = InternalEventHandlers(
		"StandardSubsystems.BaseFunctionality\SubjectPresentationOnDefine");
	
	For Each Handler In EventHandlers Do
		Handler.Module.SubjectPresentationOnDefine(SubjectRef, Result);
	EndDo;
	
	CommonUseOverridable.SetSubjectPresentation(SubjectRef, Result);
	
	If IsBlankString(Result) Then
		If SubjectRef = Undefined Or SubjectRef.IsEmpty() Then
			Result = NStr("en = 'not set'");
		ElsIf Metadata.Documents.Contains(SubjectRef.Metadata()) Then
			Result = String(SubjectRef);
		Else
			ObjectPresentation = SubjectRef.Metadata().ObjectPresentation;
			If IsBlankString(ObjectPresentation) Then
				ObjectPresentation = SubjectRef.Metadata().Presentation();
			EndIf;
			Result = StringFunctionsClientServer.SubstituteParametersInString(
				"%1 (%2)", String(SubjectRef), ObjectPresentation);
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

// Generates a map to delete objects.
Function GetOverallRefSearchExceptionList() Export
	
	RefSearchExclusions = New Map;
	
	ExceptionArray = New Array;
	EventHandlers = InternalEventHandlers(
		"StandardSubsystems.BaseFunctionality\OnAddReferenceSearchException");
	For Each Handler In EventHandlers Do
		Handler.Module.OnAddReferenceSearchException(ExceptionArray);
	EndDo;
	AddRefSearchExclusions(RefSearchExclusions, ExceptionArray);
	
	//ExceptionArray = CommonUseOverridable.GetRefSearchExceptions();
	//AddRefSearchExclusions(RefSearchExclusions, ExceptionArray);
	
	ExceptionArray = New Array;
	CommonUseOverridable.OnAddReferenceSearchException(ExceptionArray);
	AddRefSearchExclusions(RefSearchExclusions, ExceptionArray);

	Return RefSearchExclusions;
	
EndFunction

// Returns the value in the XML string format.
// The following value types can be serialized into an XML string with this function: 
// Undefined, Null, Boolean, Number, String, Date, Type, UUID, BinaryData,
// ValueStorage, TypeDescription, data object references and the data 
// objects themselves, sets of register records, and the constant value manager.
//
// Parameters:
//  Value – Arbitrary - value to be serialized into an XML string.
//
// Returns:
//  String - resulting string.
//
Function ValueToXMLString(Value) Export
	
	XMLWriter = New XMLWriter;
	XMLWriter.SetString();
	XDTOSerializer.WriteXML(XMLWriter, Value, XMLTypeAssignment.Explicit);
	
	Return XMLWriter.Close();
EndFunction

// Returns a value restored from the XML string. 
// The following value types can be restored from the XML string with this function: 
// Undefined, Null, Boolean, Number, String, Date, Type, UUID, BinaryData,
// ValueStorage, TypeDescription, data object references and the data 
// objects themselves, sets of register records, and the constant value manager.
//
// Parameters:
//  XMLString – serialized string.
//
// Returns:
//  String - resulting string.
//
Function ValueFromXMLString(XMLString) Export
	
	XMLReader = New XMLReader;
	XMLReader.SetString(XMLString);
	
	Return XDTOSerializer.ReadXML(XMLReader);
EndFunction

// Returns an XML presentation of the XDTO object.
//
// Parameters:
//  XDTODataObject - XDTODataObject - object, whose XML presentation will be generated.
//  Factory        - XDTOFactory - factory used for generating the XML presentation.
//                   If the parameter is not specified, the global XDTO factory is used.
//
// Returns: 
//   String - XML presentation of the XDTO object.
//
Function XDTODataObjectIntoXMLString(Val XDTODataObject, Val Factory = Undefined) Export
	
	If Factory = Undefined Then
		Factory = XDTOFactory;
	EndIf;
	
	Write = New XMLWriter();
	Write.SetString();
	Factory.WriteXML(Write, XDTODataObject, , , , XMLTypeAssignment.Explicit);
	
	Return Write.Close();
	
EndFunction

// Generates an XDTO object by the XML presentation.
//
// Parameters:
//  XMLLine - String      - XML presentation of the XDTO object.
//  Factory - XDTOFactory - factory used to generate the XDTO object.
//            If the parameter is not, the global XDTO factory is used.
//
// Returns: 
//   XDTODataObject.
//
Function XDTODataObjectFromXMLString(Val XMLLine, Val Factory = Undefined) Export
	
	If Factory = Undefined Then
		Factory = XDTOFactory;
	EndIf;
	
	Reader = New XMLReader;
	Reader.SetString(XMLLine);
	
	Return Factory.ReadXML(Reader);
	
EndFunction

// Generates a query search string from the source string.
//
// Parameters:
// SearchString - String - source string that contains characters prohibited in queries. 	
//
// Returns:
// String - resulting string.
//
Function GenerateSearchQueryString(Val SearchString) Export
	
	ResultingSearchString = SearchString;
	ResultingSearchString = StrReplace(ResultingSearchString, "~", "~~");
	ResultingSearchString = StrReplace(ResultingSearchString, "%", "~%");
	ResultingSearchString = StrReplace(ResultingSearchString, "_", "~_");
	ResultingSearchString = StrReplace(ResultingSearchString, "[", "~[");
	ResultingSearchString = StrReplace(ResultingSearchString, "-", "~-");
	
	Return ResultingSearchString;
	
EndFunction

// Returns the WSProxy object created using the passed parameters.
//
// Parameters:
//  WSDLAddress  - String - wsdl location.
//  NamespaceURI - String - web service namespace URI.
//  ServiceName  - String - service name.
//  EndpointName - String - if not specified, it is generated as <ServiceName>Soap.
//  UserName     - String - user name for logging on to the server.
//  Password     - String - User password.
//  Timeout      - Number - timeout for operations executed through the proxy. 
//
// Returns:
//  WSProxy
//
Function WSProxy(Val WSDLAddress,
	Val NamespaceURI,
	Val ServiceName,
	Val EndpointName = "",
	Val UserName,
	Val Password,
	Val Timeout = Undefined,
	Val ProbingCallRequired = False) Export

	If ProbingCallRequired AND Timeout <> Undefined AND Timeout > 20 Then
		
		WSProxyPing = CommonUseCached.WSProxy(
			WSDLAddress,
			NamespaceURI,
			ServiceName,
			EndpointName,
			UserName,
			Password,
			3);
		
		Try
			WSProxyPing.Ping();
		Except
			WriteLogEvent(NStr("en = 'WSProxy'", CommonUseClientServer.DefaultLanguageCode()),
				EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
			Raise;
		EndTry;
		
	EndIf;
	
	Return CommonUseCached.WSProxy(
		WSDLAddress,
		NamespaceURI,
		ServiceName,
		EndpointName,
		UserName,
		Password,
		Timeout);
	
EndFunction

// Defines whether the metadata object is enabled by functional options.
//
// Parameters:
//   MetadataObject - MetadataObject - metadata object to be checked.
//
// Returns: 
//  Boolean - True if the object is enabled.
//
Function MetadataObjectEnabledByFunctionalOptions(MetadataObject) Export
	Return CommonUseCached.ObjectsEnabledByOption()[MetadataObject] <> False;
EndFunction

// Sets or clears the deletion mark for all objects subordinated to the "owner".
//
// Parameters:
//  Owner        - ExchangePlanRef, CatalogRef, DocumentRef - reference to the object that is an owner of the objects to be marked for deletion.
//
//  DeletionMark - Boolean - flag that shows whether deletion marks of all subordinate objects must be set/cleared.
//
Procedure SetDeletionMarkForSubordinateObjects(Val Owner, Val DeletionMark) Export
	
	BeginTransaction();
	Try
		
		ReferenceList = New Array;
		ReferenceList.Add(Owner);
		References = FindByRef(ReferenceList);
		
		For Each Ref In References Do
			
			If ReferenceTypeValue(Ref[1]) Then
				
				Ref[1].GetObject().SetDeletionMark(DeletionMark);
				
			EndIf;
			
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure


// Tries to execute a query in several attempts.
// Is used for reading fast-changing data outside a transaction.
// If it is called in a transaction, leads to an error.
//
// Parameters:
//  Query - Query - query to be executed.
//
// Returns:
//  QueryResult - query execution result.
//
Function ExecuteQueryOutsideTransaction(Val Query) Export
	
	If TransactionActive() Then
		Raise(NStr("en = 'Transaction is active. Cannot execute a query outside a transaction.'"));
	EndIf;
	
	AttemptCount = 0;
	
	Result = Undefined;
	While True Do
		Try
			Result = Query.Execute(); // Reading outside a transaction, the following error can occur:
			                          // Could not continue scan with NOLOCK due to data movement.
			                          // In this case, attempt to read one more time.
			Break;
		Except
			AttemptCount = AttemptCount + 1;
			If AttemptCount = 5 Then
				Raise;
			EndIf;
		EndTry;
	EndDo;
	
	Return Result;
	
EndFunction

// Returns common basic functionality parameters.
//
// Returns: 
//  Structure - structure with the following properties:
//   * PersonalSettingsFormName        - String - name of a forms intended for editing personal
//                                       settings.
//                                       Previously, it was defined in
//                                       CommonUseOverridable.PersonalSettingsFormName;
//   * LowestPlatformVersion           - String - full platform version number for starting the
//                                       application. For example, "8.3.4.365".
//                                       Previously, it was defined in
//                                       CommonUseOverridable.GetMinRequiredPlatformVersion.
//   * MustExit                        - Boolean - initial value is False.
//   * AskConfirmationOnExit           - Boolean - default value is True. If False, the exit
//                                       confirmation is not requested when exiting the
//                                       application, if it is not clearly enabled in the
//                                       personal application settings.
//   * DisableMetadataObjectIDsCatalog - Boolean - disables MetadataObjectIDs catalog filling,
//                                       procedures of catalog item importing and exporting in
//                                       DIB nodes.
//                                       You can use it for the partial embedding of certain
//                                       library functions into configuration without enabling
//                                       the support.
//
Function CommonBaseFunctionalityParameters() Export
		
CommonParameters = New Structure;
	CommonParameters.Insert("PersonalSettingsFormName", "");
	CommonParameters.Insert("LowestPlatformVersion", "8.3.4.365");
	CommonParameters.Insert("MustExit", True); // Blocking the startup if the version is lower that the required one
	CommonParameters.Insert("AskConfirmationOnExit", True);
	CommonParameters.Insert("DisableMetadataObjectIDsCatalog", False);
	
	CommonUseOverridable.BaseFunctionalityCommonParametersOnDefine(CommonParameters);
	
	Return CommonParameters;
	
EndFunction

// Determines whether this infobase is a subordinate node of a distributed infobase (DIB).
//
// Returns: 
//  Boolean
//
Function IsSubordinateDIBNode() Export
	
	SetPrivilegedMode(True);
	
	Return ExchangePlans.MasterNode() <> Undefined;
	
EndFunction

// Returns True the infobase configuration of the subordinate DIB node must be updated.
// In the master node always returns False.
//
// Returns: 
//  Boolean
//
Function DIBSubordinateNodeConfigurationUpdateRequired() Export
	
	Return IsSubordinateDIBNode() AND ConfigurationChanged();
	
EndFunction

// Returns True if the current session runs on a Linux server.
//
// Returns:
//  Boolean - True if the server runs Linux.
//
Function IsLinuxServer() Export
	
	SystemInfo = New SystemInfo;
	Return SystemInfo.PlatformType = PlatformType.Linux_x86 Or SystemInfo.PlatformType = PlatformType.Linux_x86_64;
	
EndFunction

// Is intended to be inserted into the beginning of the OnCreateAtServer handler of the managed
// forms that are placed at the desktop.
//
// Prevents the form opening in the following special cases:
//  - if the desktop is opened before the infobase data update is complete (to prevent reading
//    obsolete data);
//  - if the user attempts to log on to a separated infobase with the unset DataAreaMainData 
//    separator value (to prevent reading separated data from a shared session);
//
// Do not use it in forms that is used before the system start and in forms that are intended
// to be used in shared sessions.
//
// Parameters:
//  Form               - ManagedForm - reference to the form to be created.
//  Cancel             - Boolean - parameter passed to the OnCreateAtServer form handler.
//  StandardProcessing - Boolean - parameter passed to the OnCreateAtServer form handler.
//
// Returns:
//  Boolean - False if the form creation cancellation flag is set.
//
Function OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	If CommonUseCached.DataSeparationEnabled()
		AND NOT CommonUseCached.CanUseSeparatedData() Then
		Cancel = True;
		Return False;
	EndIf;
	
	If Form.Parameters.Property("Autotest") Then
		// Skipping the initialization to guarantee that the form will be received if the Autotest parameter is passed.
		Return False;
	EndIf;
	
	SetPrivilegedMode(True);
	If SessionParameters.ClientParametersOnServer.Get("HideDesktopOnStart") <> Undefined Then
		Cancel = True;
		Return False;
	EndIf;
	SetPrivilegedMode(False);
	
	Return True;
	
EndFunction

// Performs actions before continue executing a scheduled job handler.
//
// For example, checks whether a scheduled job handler can be executed.
// If the administrator has not been disabled the execution of scheduled jobs before an
// infobase update completion, the handler execution must be stopped.
// 
Procedure ScheduledJobOnStart() Export
	
	If StandardSubsystemsServer.ApplicationParametersUpdateRequired() Then
		Raise
			NStr("en = 'The application is being updated. Cannot log on to the application now.
			           |We recommend that you disable scheduled job execution when updating the infobase.'");
	EndIf;
	
	SetPrivilegedMode(True);
	
	If NOT CommonUseCached.DataSeparationEnabled()
	   AND ExchangePlans.MasterNode() = Undefined
	   AND ValueIsFilled(Constants.MasterNode.Get()) Then
		
		Raise
			NStr("en = 'Cannot log on to the application while the connection to the master node is not established.
			           |We recommend that you disable scheduled job execution when recovering the infobase.'");
	EndIf;
	
EndProcedure

// Returns the configuration revision number.
// The revision is two first digits of a full configuration version.
// For example, the version "1.2.3.4" means the revision is "1.2".
//
// Returns:
//  String - configuration revision number.
//
Function ConfigurationRevision() Export
	
	Result = "";
	ConfigurationVersion = Metadata.Version;
	
	Position = Find(ConfigurationVersion, ".");
	If Position > 0 Then
		Result = Left(ConfigurationVersion, Position);
		ConfigurationVersion = Mid(ConfigurationVersion, Position + 1);
		Position = Find(ConfigurationVersion, ".");
		If Position > 0 Then
			Result = Result + Left(ConfigurationVersion, Position - 1);
		Else
			Result = "";
		EndIf;
	EndIf;
	
	If IsBlankString(Result) Then
		Result = Metadata.Version;
	EndIf;
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for working with forms.
//

// Fills a form attribute of the ValueTree type.
//
// Parameters:
//  TreeItemCollection – FormDataTree - form attribute of the ValueTree type;
//                       It will be filled with values from the ValueTree parameter.
//  ValueTree          – ValueTree – data for filling TreeItemCollection.
//
Procedure FillFormDataTreeItemCollection(TreeItemCollection, ValueTree) Export
	
	For Each Row In ValueTree.Rows Do
		
		TreeItem = TreeItemCollection.Add();
		
		FillPropertyValues(TreeItem, Row);
		
		If Row.Rows.Count() > 0 Then
			
			FillFormDataTreeItemCollection(TreeItem.GetItems(), Row);
			
		EndIf;
		
	EndDo;
	
EndProcedure
 
// Gets a picture for displaying it on a page that contains the comment. 
// The picture will be displayed if the comment text is not empty.
//
// Parameters
//  Comment - String - comment text.
//
// Returns:
//  Picture - picture to be displayed on a page that contains the comment.
//
Function GetCommentPicture(Comment) Export
	
	If Not IsBlankString(Comment) Then
		Picture = PictureLib.Comment;
	Else
		Picture = New Picture;
	EndIf;
	
	Return Picture;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for working with types, metadata objects, and their string presentations.

// Gets the configuration metadata tree with the specified filter by metadata objects.
// 
// Parameters:
// Filter – Structure – contains filter item values.
// 					If this parameter is specified, the metadata tree will be retrieved according to the
//          filter value; 
// 					 Key   - String – metadata item property name;
// 					 Value - Array – array of filter values.
// 
// Example of initializing the Filter variable:
// 
// Array = New Array;
// Array.Add("Constant.UseDataExchange");
// Array.Add("Catalog.Currencies");
// Array.Add("Catalog.Companies");
// Filter = New Structure;
// Filter.Insert("FullName", Array);
// 
// Returns:
// ValueTree - configuration metadata tree.
//
Function GetConfigurationMetadataTree(Filter = Undefined) Export
	
	UseFilter = (Filter <> Undefined);
	
	MetadataObjectCollections = New ValueTable;
	MetadataObjectCollections.Columns.Add("Name");
	MetadataObjectCollections.Columns.Add("Synonym");
	MetadataObjectCollections.Columns.Add("Picture");
	MetadataObjectCollections.Columns.Add("ObjectPicture");
	
	NewMetadataObjectCollectionRow("Constants",                   NStr("en = 'Constants'"),                      PictureLib.Constant,                   PictureLib.Constant,                         MetadataObjectCollections);
	NewMetadataObjectCollectionRow("Catalogs",                    NStr("en = 'Catalogs'"),                       PictureLib.Catalog,                    PictureLib.Catalog,                          MetadataObjectCollections);
	NewMetadataObjectCollectionRow("Documents",                   NStr("en = 'Documents'"),                      PictureLib.Document,                   PictureLib.DocumentObject,                    MetadataObjectCollections);
	NewMetadataObjectCollectionRow("ChartsOfCharacteristicTypes", NStr("en = 'Charts of characteristic types'"), PictureLib.ChartOfCharacteristicTypes, PictureLib.ChartOfCharacteristicTypesObject, MetadataObjectCollections);
	NewMetadataObjectCollectionRow("ChartsOfAccounts",            NStr("en = 'Charts of accounts'"),             PictureLib.ChartOfAccounts,            PictureLib.ChartOfAccountsObject,            MetadataObjectCollections);
	NewMetadataObjectCollectionRow("ChartsOfCalculationTypes",    NStr("en = 'Charts of calculation types'"),    PictureLib.ChartOfCalculationTypes,    PictureLib.ChartOfCalculationTypesObject,   MetadataObjectCollections);
	NewMetadataObjectCollectionRow("InformationRegisters",        NStr("en = 'Information registers'"),          PictureLib.InformationRegister,        PictureLib.InformationRegister,              MetadataObjectCollections);
	NewMetadataObjectCollectionRow("AccumulationRegisters",       NStr("en = 'Accumulation registers'"),         PictureLib.AccumulationRegister,       PictureLib.AccumulationRegister,             MetadataObjectCollections);
	NewMetadataObjectCollectionRow("AccountingRegisters",         NStr("en = 'Accounting registers'"),           PictureLib.AccountingRegister,         PictureLib.AccountingRegister,               MetadataObjectCollections);
	NewMetadataObjectCollectionRow("CalculationRegisters",        NStr("en = 'Calculation registers'"),          PictureLib.CalculationRegister,        PictureLib.CalculationRegister,               MetadataObjectCollections);
	NewMetadataObjectCollectionRow("BusinessProcesses",           NStr("en = 'Business processes'"),             PictureLib.BusinessProcess,            PictureLib.BusinessProcessObject,          MetadataObjectCollections);
	NewMetadataObjectCollectionRow("Tasks",                       NStr("en = 'Tasks'"),                          PictureLib.Task,                       PictureLib.TaskObject,                 MetadataObjectCollections);
	
	// Return value
	MetadataTree = New ValueTree;
	MetadataTree.Columns.Add("Name");
	MetadataTree.Columns.Add("FullName");
	MetadataTree.Columns.Add("Synonym");
	MetadataTree.Columns.Add("Picture");
	
	For Each CollectionRow In MetadataObjectCollections Do
		
		TreeRow = MetadataTree.Rows.Add();
		FillPropertyValues(TreeRow, CollectionRow);
		For Each MetadataObject In Metadata[CollectionRow.Name] Do
			
			If UseFilter Then
				
				ObjectPassedFilter = True;
				For Each FilterItem In Filter Do
					
					Value = ?(Upper(FilterItem.Key) = Upper("FullName"), MetadataObject.FullName(), MetadataObject[FilterItem.Key]);
					If FilterItem.Value.Find(Value) = Undefined Then
						ObjectPassedFilter = False;
						Break;
					EndIf;
					
				EndDo;
				
				If NOT ObjectPassedFilter Then
					Continue;
				EndIf;
				
			EndIf;
			
			MOTreeRow = TreeRow.Rows.Add();
			MOTreeRow.Name     = MetadataObject.Name;
			MOTreeRow.FullName = MetadataObject.FullName();
			MOTreeRow.Synonym  = MetadataObject.Synonym;
			MOTreeRow.Picture  = CollectionRow.ObjectPicture;
			
		EndDo;
		
	EndDo;
	
	// Deleting rows that have no subordinate items
	If UseFilter Then
		
		// Using reverse value tree iteration order
		CollectionItemCount = MetadataTree.Rows.Count();
		
		For ReverseIndex = 1 to CollectionItemCount Do
			
			CurrentIndex = CollectionItemCount - ReverseIndex;
			TreeRow = MetadataTree.Rows[CurrentIndex];
			If TreeRow.Rows.Count() = 0 Then
				MetadataTree.Rows.Delete(CurrentIndex);
			EndIf;
			
		EndDo;
	
	EndIf;
	
	Return MetadataTree;
	
EndFunction

// Gets the infobase presentation for displaying it to the user.
//
// Returns:
//  String - infobase presentation. 
//
// Result example:
// - if the infobase runs in the file mode: \\FileServer\1C_ib
// - if the infobase runs in the client/server mode: ServerName:1111 / infobase_name
//
Function GetInfobasePresentation() Export
	
	InfobaseConnectionString = InfobaseConnectionString();
	
	If FileInfobase(InfobaseConnectionString) Then
		Return Mid(InfobaseConnectionString, 6, StrLen(InfobaseConnectionString) - 6);
	EndIf;
		
	// Adding the infobase name to the server name
	SearchPosition = Find(Upper(InfobaseConnectionString), "SRVR=");
	If SearchPosition <> 1 Then
		Return Undefined;
	EndIf;
	
	SemicolonPosition = Find(InfobaseConnectionString, ";");
	CopyStartPosition = 6 + 1;
	CopyingEndPosition = SemicolonPosition - 2; 
	
	ServerName = Mid(InfobaseConnectionString, CopyStartPosition, CopyingEndPosition - CopyStartPosition + 1);
	
	InfobaseConnectionString = Mid(InfobaseConnectionString, SemicolonPosition + 1);
	
	// Server name position
	SearchPosition = Find(Upper(InfobaseConnectionString), "REF=");
	If SearchPosition <> 1 Then
		Return Undefined;
	EndIf;
	
	CopyStartPosition = 6;
	SemicolonPosition = Find(InfobaseConnectionString, ";");
	CopyingEndPosition = SemicolonPosition - 2; 
	
	InfobaseNameAtServer = Mid(InfobaseConnectionString, CopyStartPosition, CopyingEndPosition - CopyStartPosition + 1);
	PathToDB = ServerName + "/ " + InfobaseNameAtServer;
	Return PathToDB;
	
EndFunction

// Returns a string of configuration metadata object attributes of the specified type.
// 
// Parameters:
//  Ref  – AnyRef – reference to the infobase item whose attributes will be retrieved;
//  Type – Type – attribute value type.
// 
// Returns:
//  String – string with configuration metadata object attributes separated with commas.
//
Function AttributeNamesByType(Ref, Type) Export
	
	Result = "";
	ObjectMetadata = Ref.Metadata();
	
	For Each Attribute In ObjectMetadata.Attributes Do
		If Attribute.Type.ContainsType(Type) Then
			Result = Result + ?(IsBlankString(Result), "", ",") + Attribute.Name;
		EndIf;
	EndDo;
	
	Return Result;
EndFunction

// Returns a name of the base type by the passed metadata object value.
// 
// Parameters:
// MetadataObject - metadata object for determining the base type.
// 
// Returns:
// String - base type name.
//
Function BaseTypeNameByMetadataObject(MetadataObject) Export
	
	If Metadata.Documents.Contains(MetadataObject) Then
		Return TypeNameDocuments();
		
	ElsIf Metadata.Catalogs.Contains(MetadataObject) Then
		Return TypeNameCatalogs();
		
	ElsIf Metadata.Enums.Contains(MetadataObject) Then
		Return TypeNameEnums();
		
	ElsIf Metadata.InformationRegisters.Contains(MetadataObject) Then
		Return TypeNameInformationRegisters();
		
	ElsIf Metadata.AccumulationRegisters.Contains(MetadataObject) Then
		Return TypeNameAccumulationRegisters();
		
	ElsIf Metadata.AccountingRegisters.Contains(MetadataObject) Then
		Return TypeNameAccountingRegisters();
		
	ElsIf Metadata.CalculationRegisters.Contains(MetadataObject) Then
		Return TypeNameCalculationRegisters();
		
	ElsIf Metadata.ExchangePlans.Contains(MetadataObject) Then
		Return TypeNameExchangePlans();
		
	ElsIf Metadata.ChartsOfCharacteristicTypes.Contains(MetadataObject) Then
		Return TypeNameChartsOfCharacteristicTypes();
		
	ElsIf Metadata.BusinessProcesses.Contains(MetadataObject) Then
		Return TypeNameBusinessProcesses();
		
	ElsIf Metadata.Tasks.Contains(MetadataObject) Then
		Return TypeNameTasks();
		
	ElsIf Metadata.ChartsOfAccounts.Contains(MetadataObject) Then
		Return TypeNameChartsOfAccounts();
		
	ElsIf Metadata.ChartsOfCalculationTypes.Contains(MetadataObject) Then
		Return TypeNameChartsOfCalculationTypes();
		
	ElsIf Metadata.Constants.Contains(MetadataObject) Then
		Return TypeNameConstants();
		
	ElsIf Metadata.DocumentJournals.Contains(MetadataObject) Then
		Return TypeNameDocumentJournals();

	ElsIf Metadata.Sequences.Contains(MetadataObject) Then
		Return SequenceTypeName();

			ElsIf Metadata.ScheduledJobs.Contains(MetadataObject) Then
		Return ScheduledJobTypeName();

				
	Else
		
		Return "";
		
	EndIf;
	
EndFunction

// Returns an object manager by the full metadata object name.
//
// Restriction: This function does not handle business process route points.
//
// Parameters:
//  FullName - String - metadata object full name,
//             for example: "Catalog.Companies".
//
// Returns:
// ObjectManager (CatalogManager, DocumentManager, and so on). 
//
Function ObjectManagerByFullName(FullName) Export
	Var MOClass, MOName, Manager;
	
	NameParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(FullName, ".");
	
	If NameParts.Count() >= 2 Then
		MOClass = NameParts[0];
		MOName  = NameParts[1];
	EndIf;
	
	If    Upper(MOClass) = "EXCHANGEPLAN" Then
		Manager = ExchangePlans;
		
	ElsIf Upper(MOClass) = "CATALOG" Then
		Manager = Catalogs;
		
	ElsIf Upper(MOClass) = "DOCUMENT" Then
		Manager = Documents;
		
	ElsIf Upper(MOClass) = "DOCUMENTJOURNAL" Then
		Manager = DocumentJournals;
		
	ElsIf Upper(MOClass) = "ENUM" Then
		Manager = Enums;
		
	ElsIf Upper(MOClass) = "REPORT" Then
		Manager = Reports;
		
	ElsIf Upper(MOClass) = "DATAPROCESSOR" Then
		Manager = DataProcessors;
		
	ElsIf Upper(MOClass) = "CHARTOFCHARACTERISTICTYPES" Then
		Manager = ChartsOfCharacteristicTypes;
		
	ElsIf Upper(MOClass) = "CHARTOFACCOUNTS" Then
		Manager = ChartsOfAccounts;
		
	ElsIf Upper(MOClass) = "CHARTOFCALCULATIONTYPES" Then
		Manager = ChartsOfCalculationTypes;
		
	ElsIf Upper(MOClass) = "INFORMATIONREGISTER" Then
		Manager = InformationRegisters;
		
	ElsIf Upper(MOClass) = "ACCUMULATIONREGISTER" Then
		Manager = AccumulationRegisters;
		
	ElsIf Upper(MOClass) = "ACCOUNTINGREGISTER" Then
		Manager = AccountingRegisters;
		
	ElsIf Upper(MOClass) = "CALCULATIONREGISTER" Then
		If NameParts.Count() = 2 Then
			// Calculation register
			Manager = CalculationRegisters;
		Else
			SubordinateMOClass = NameParts[2];
			SubordinateMOName = NameParts[3];
			If Upper(SubordinateMOClass) = "RECALCULATION" Then
				// Recalculation
				Try
					Manager = CalculationRegisters[MOName].Recalculations;
					MOName = SubordinateMOName;
				Except
					Manager = Undefined;
				EndTry;
			EndIf;
		EndIf;
		
	ElsIf Upper(MOClass) = "BUSINESSPROCESS" Then
		Manager = BusinessProcesses;
		
	ElsIf Upper(MOClass) = "TASK" Then
		Manager = Tasks;
		
	ElsIf Upper(MOClass) = "CONSTANT" Then
		Manager = Constants;
		
	ElsIf Upper(MOClass) = "SEQUENCE" Then
		Manager = Sequences;
	EndIf;
	
	If Manager <> Undefined Then
		Try
			Return Manager[MOName];
		Except
			Manager = Undefined;
		EndTry;
	EndIf;
	
	Raise StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en = 'Unknown metadata object type: %1.'"), FullName);
	
EndFunction

// Returns an object manager by the object reference.
//
// This function does not process business process route points.
//
// Parameters:
//  Ref - AnyRef - object reference (catalog item, document, and so on).
//
// Returns:
//  ObjectManager (CatalogManager, DocumentManager, and so on). 
//
Function ObjectManagerByRef(Ref) Export
	
	ObjectName = Ref.Metadata().Name;
	RefType = TypeOf(Ref);
	
	If Catalogs.AllRefsType().ContainsType(RefType) Then
		Return Catalogs[ObjectName];
		
	ElsIf Documents.AllRefsType().ContainsType(RefType) Then
		Return Documents[ObjectName];
		
	ElsIf BusinessProcesses.AllRefsType().ContainsType(RefType) Then
		Return BusinessProcesses[ObjectName];
		
	ElsIf ChartsOfCharacteristicTypes.AllRefsType().ContainsType(RefType) Then
		Return ChartsOfCharacteristicTypes[ObjectName];
		
	ElsIf ChartsOfAccounts.AllRefsType().ContainsType(RefType) Then
		Return ChartsOfAccounts[ObjectName];
		
	ElsIf ChartsOfCalculationTypes.AllRefsType().ContainsType(RefType) Then
		Return ChartsOfCalculationTypes[ObjectName];
		
	ElsIf Tasks.AllRefsType().ContainsType(RefType) Then
		Return Tasks[ObjectName];
		
	ElsIf ExchangePlans.AllRefsType().ContainsType(RefType) Then
		Return ExchangePlans[ObjectName];
		
	ElsIf Enums.AllRefsType().ContainsType(RefType) Then
		Return Enums[ObjectName];
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Checks whether the infobase record exists by its reference.
// 
// Parameters:
//  AnyRef - any infobase reference value.
// 
// Returns:
//  True if the record exists;
//  False if the record does not exist.
//
Function RefExists(AnyRef) Export
	
	QueryText = "
	|SELECT
	|	Ref AS Ref
	|FROM
	|	[TableName]
	|WHERE
	|	Ref = &Ref
	|";
	
	QueryText = StrReplace(QueryText, "[TableName]", TableNameByRef(AnyRef));
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", AnyRef);
	
	SetPrivilegedMode(True);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// Returns a metadata object kind name 
// by the object reference.
//
// Restriction: This function does not handle business process route points.
//
// Parameters:
//  Ref - AnyRef - object reference (catalog item, document, and so on).
//
// Returns:
//  String - metadata object kind name ("Catalog", "Document", and so on).
//
Function ObjectKindByRef(Ref) Export
	
	Return ObjectKindByType(TypeOf(Ref));
	
EndFunction
 
// Returns a metadata object kind name by the object type.
//
// Restriction: This function does not handle business process route points.
//
// Parameters:
//  Type - Type - applied object type.
//
// Returns:
//  String - metadata object kind name ("Catalog", "Document", and so on).
//
Function ObjectKindByType(Type) Export
	
	If Catalogs.AllRefsType().ContainsType(Type) Then
		Return "Catalog";
	
	ElsIf Documents.AllRefsType().ContainsType(Type) Then
		Return "Document";
	
	ElsIf BusinessProcesses.AllRefsType().ContainsType(Type) Then
		Return "BusinessProcess";
	
	ElsIf ChartsOfCharacteristicTypes.AllRefsType().ContainsType(Type) Then
		Return "ChartOfCharacteristicTypes";
	
	ElsIf ChartsOfAccounts.AllRefsType().ContainsType(Type) Then
		Return "ChartOfAccounts";
	
	ElsIf ChartsOfCalculationTypes.AllRefsType().ContainsType(Type) Then
		Return "ChartOfCalculationTypes";
	
	ElsIf Tasks.AllRefsType().ContainsType(Type) Then
		Return "Task";
	
	ElsIf ExchangePlans.AllRefsType().ContainsType(Type) Then
		Return "ExchangePlan";
	
	ElsIf Enums.AllRefsType().ContainsType(Type) Then
		Return "Enumeration";
	
	Else
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Invalid parameter value type %1.'"), String(Type));
	
	EndIf;
	
EndFunction

// Returns full metadata object name by the passed reference value.
// Examples:
//  "Catalog.Items";
//  "Document.Invoice".
// 
// Parameters:
//  Ref - AnyRef - value of the reference whose infobase table name will be retrieved.
// 
// Returns:
//  String - full metadata object name.
//
Function TableNameByRef(Ref) Export
	
	Return Ref.Metadata().FullName();
	
EndFunction

// Checks whether the value is a reference type value.
//
// Parameters:
//  Value - Any;
//
// Returns:
//  Boolean - True if the value has a reference type.
//
Function ReferenceTypeValue(Value) Export
	
	Return IsReference(TypeOf(Value));
	
EndFunction

// Checking whether the passed type is a reference data type.
// "Undefined" returned False.
//
// Returns:
//  Boolean.
//
Function IsReference(Type) Export
	
	Return Type <> Type("Undefined") 
		AND (Catalogs.AllRefsType().ContainsType(Type)
		Or Documents.AllRefsType().ContainsType(Type)
		Or Enums.AllRefsType().ContainsType(Type)
		Or ChartsOfCharacteristicTypes.AllRefsType().ContainsType(Type)
		Or ChartsOfAccounts.AllRefsType().ContainsType(Type)
		Or ChartsOfCalculationTypes.AllRefsType().ContainsType(Type)
		Or BusinessProcesses.AllRefsType().ContainsType(Type)
		Or BusinessProcesses.RoutePointsAllRefsType().ContainsType(Type)
		Or Tasks.AllRefsType().ContainsType(Type)
		Or ExchangePlans.AllRefsType().ContainsType(Type));
	
EndFunction

// Checks whether the object is an item group.
//
// Parameters:
//  Object - AnyRef, Object - object to be validated.
//
// Returns:
//  Boolean.
//
Function ObjectIsFolder(Object) Export
	
	If ReferenceTypeValue(Object) Then
		Ref = Object;
	Else
		Ref = Object.Ref;
	EndIf;
	
	ObjectMetadata = Ref.Metadata();
	
	If IsCatalog(ObjectMetadata) Then
		
		If NOT ObjectMetadata.Hierarchical
		 Or ObjectMetadata.HierarchyType
		     <> Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems Then
			
			Return False;
		EndIf;
		
	ElsIf NOT IsChartOfCharacteristicTypes(ObjectMetadata) Then
		Return False;
		
	ElsIf NOT ObjectMetadata.Hierarchical Then
		Return False;
	EndIf;
	
	If Ref <> Object Then
		Return Object.IsFolder;
	EndIf;
	
	Return ObjectAttributeValue(Ref, "IsFolder") = True;
	
EndFunction

// Returns a reference that corresponds to the metadata object.
// 
// Example:
// ID = CommonUse.MetadataObjectID(TypeOf(Ref));
// ID = CommonUse.MetadataObjectID(MetadataObject);
// ID = CommonUse.MetadataObjectID("Catalog.Companies");
//
// Supported metadata objects:
// - Subsystems (you have to program renaming for it)
// - Roles (have to program renaming for it)
// - ExchangePlans
// - Constants
// - Catalogs
// - Documents
// - DocumentJournals
// - Reports
// - DataProcessors
// - ChartsOfCharacteristicTypes
// - ChartsOfAccounts
// - ChartsOfCalculationTypes
// - InformationRegisters
// - AccumulationRegisters
// - AccountingRegisters
// - CalculationRegisters
// - BusinessProcesses
// - Tasks
// 
// See MetadataObjectIDs.ManagerModule.MetadataObjectCollectionProperties()
// for details.
//
// Parameters:
//  MetadataObjectName - MetadataObject - configuration metadata object;
//                     - Type - type that can be used in Metadata.FindByType();
//                     - String - full metadata object name that can be used 
//                       in Metadata.FindByFullName().
//
// Returns:
//  CatalogRef.MetadataObjectIDs.
//
Function MetadataObjectID(MetadataObjectName) Export
	
	MetadataObjectDescriptionType = TypeOf(MetadataObjectName);
	If MetadataObjectDescriptionType = Type("Type") Then
		
		MetadataObject = Metadata.FindByType(MetadataObjectName);
		If MetadataObject = Undefined Then
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Error executing CommonUse.MetadataObjectID().
				 |
				 |Metadata object is not found by its type:
				 |%1.'"),

				MetadataObjectName);
		Else
			MetadataObjectFullName = MetadataObject.FullName();
		EndIf;
		
	ElsIf MetadataObjectDescriptionType = Type("String") Then
		MetadataObjectFullName = MetadataObjectName;
	Else
		MetadataObjectFullName = MetadataObjectName.FullName();
	EndIf;
	
	Return StandardSubsystemsCached.MetadataObjectID(MetadataObjectFullName);
	
EndFunction

// Returns a metadata object by the passed ID.
//
// Parameters:
//  ID - CatalogRef.MetadataObjectIDs
//
// Returns:
//  MetadataObject
//
Function MetadataObjectByID(ID) Export
	
	StandardSubsystemsCached.CatalogMetadataObjectIDsUsageCheck(True);
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("Ref", ID);
	Query.Text =
	"SELECT
	|	IDs.Ref AS Ref,
	|	IDs.MetadataObjectKey,
	|	IDs.FullName,
	|	IDs.DeletionMark
	|FROM
	|	Catalog.MetadataObjectIDs AS IDs
	|Where
	|	IDs.Ref = &Ref";
	
	Data = Query.Execute().Unload();
	
	If Data.Count() = 0 Then
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Error executing CommonUse.MetadataObjectByID().
			           |
			           |The %1 ID
			           |is not found in the Metadata objects IDs catalog.'")
			+ StandardSubsystemsServer.ApplicationRunParameterErrorClarificationForDeveloper(),
			String(ID));
	EndIf;
	
	// Checking whether metadata object key corresponds to the full metadata object name
	CheckResult = Catalogs.MetadataObjectIDs.MetadataObjectKeyCorrespondsFullName(Data[0]);
	If CheckResult.NotCorresponds Then
		If CheckResult.MetadataObject = Undefined Then
			If CheckResult.MetadataObjectKey = Undefined Then
				Raise StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en = Error executing CommonUse.MetadataObjectByID().
					           |
					           |The %1 ID
					           |is found in the Metadata objects IDs catalog but it corresponds to
					           |the metadata object that does not exist:
					           |%2.'")
					+ StandardSubsystemsServer.ApplicationRunParameterErrorClarificationForDeveloper(),
					String(ID),
					Data[0].FullName);
			Else
				Raise StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en = Error executing CommonUse.MetadataObjectByID().
					           |
					           |The %1 ID
					           |is found in the Metadata objects IDs catalog, but it corresponds to
					           |the deleted metadata object.'")
					+ StandardSubsystemsServer.ApplicationRunParameterErrorClarificationForDeveloper(),
					String(ID));
			EndIf;
		Else
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Error executing CommonUse.MetadataObjectByID().
				           |
				           |The %1 ID
				           |is found in the Metadata objects IDs catalog, but it corresponds to 
				           |the %2 metadata object whose full name is different from
				           |the full name specified in the ID.'")
				+ StandardSubsystemsServer.ApplicationRunParameterErrorClarificationForDeveloper(),
				String(ID),
				CheckResult.MetadataObject.FullName());
		EndIf;
	EndIf;
	
	If Data[0].DeletionMark Then
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = Error executing CommonUse.MetadataObjectByID().
			           |
			           |The %1 ID is found in the Metadata objects IDs catalog, but
			           |its deletion mark is set to True.'")
			+ StandardSubsystemsServer.ApplicationRunParameterErrorClarificationForDeveloper(),
			String(ID));
	EndIf;
	
	Return CheckResult.MetadataObject;
	
EndFunction

// To be used in the RenamedMetadataObjectsOnAdd procedure of the CommonUseOverridable common
// module for defining the metadata object renaming.
// 
// Parameters:
//   Total              - Structure - is passed to the procedure by the BaseFunctionality subsystem.
//   InfobaseVersion    - String - renaming must be performed when updating to this version.
//   OldFullName        - String - old full metadata object name to be renamed rename.
//   NewFullName        - String - new full metadata object name to be renamed rename.
//   LibraryID          - String - internal ID of the library where InfobaseVersion belongs.
//                                 Does not required for a base configuration.
// 
Procedure AddRenaming(Total, InfobaseVersion, OldFullName, NewFullName, LibraryID = "") Export
	
	StandardSubsystemsCached.CatalogMetadataObjectIDsUsageCheck();
	
	OldCollectionName = Upper(CollectionName(OldFullName));
	NewCollectionName = Upper(CollectionName(NewFullName));
	
	ErrorTitle =
		NStr("en = 'Error in the RenamedMetadataObjectsOnAdd procedure of the CommonUseOverridable common module.'");
	
	If OldCollectionName <> NewCollectionName Then
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			ErrorTitle + Chars.LF + Chars.LF
			+ NStr("en = 'The type names of the renamed metadata object do not match.
			             |Former type: %1,
 			            |new type: %2.'"),
			OldFullName,
			NewFullName);
	EndIf;
	
	If Total.CollectionsWithoutKey[OldCollectionName] = Undefined Then
		
		AllowedTypeList = "";
		For Each KeyAndValue In Total.CollectionsWithoutKey Do
			AllowedTypeList = AllowedTypeList + KeyAndValue.Value + "," + Chars.LF;
		EndDo;
		AllowedTypeList = TrimR(AllowedTypeList);
		AllowedTypeList = ?(ValueIsFilled(AllowedTypeList),
			Left(AllowedTypeList, StrLen(AllowedTypeList) - 1), "");
		
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			ErrorTitle + Chars.LF + Chars.LF
			+ NStr("en = 'The %1 metadata object type does not require renaming description, because details on this metadata objects are updated automatically.
			             |
			             |Only the following types require renaming to be described:
			             |%2.'"),
			OldFullName,
			NewFullName,
			AllowedTypeList);
	EndIf;
	
	If ValueIsFilled(LibraryID) Then
		Library = Upper(LibraryID) <> Upper(Metadata.Name);
	Else
		LibraryID = Metadata.Name;
		Library = False;
	EndIf;
	
	LibraryOrder = Total.LibrariesOrder[LibraryID];
	If LibraryOrder = Undefined Then
		LibraryOrder = Total.LibrariesOrder.Count();
		Total.LibrariesOrder.Insert(LibraryID, LibraryOrder);
	EndIf;
	
	LibVersion = Total.LibraryVersions[LibraryID];
	If LibVersion = Undefined Then
		LibVersion = InfobaseUpdateInternal.InfobaseVersion(LibraryID);
		Total.LibraryVersions.Insert(LibraryID, LibVersion);
	EndIf;
	
	If LibVersion = "0.0.0.0" Then
		// Does not required during initial renaming filling.
		Return;
	EndIf;
	
	
	Result = CommonUseClientServer.CompareVersions(InfobaseVersion, LibVersion);
	If Result > 0 Then
		VersionParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(InfobaseVersion, ".");
		
		DetailsOnRenaming = Total.Table.Add();
		DetailsOnRenaming.LibraryOrder  = LibraryOrder;
		DetailsOnRenaming.VersionPart1  = Number(VersionParts[0]);
		DetailsOnRenaming.VersionPart2  = Number(VersionParts[1]);
		DetailsOnRenaming.VersionPart3  = Number(VersionParts[2]);
		DetailsOnRenaming.VersionPart4  = Number(VersionParts[3]);
		DetailsOnRenaming.OldFullName   = OldFullName;
		DetailsOnRenaming.NewFullName   = NewFullName;
		DetailsOnRenaming.AdditionOrder = Total.Table.IndexOf(DetailsOnRenaming);
	EndIf;
	
EndProcedure

// Returns a string presentation of the type. 
// In case of reference types the function returns a presentation in the following format:
// "CatalogRef.ObjectName" or "DocumentRef.ObjectName".
// For other types it transforms the type to a string, for example, "Number".
//
// Returns:
//  String.
//
Function TypePresentationString(Type) Export
	
	Presentation = "";
	
	If IsReference(Type) Then
	
		FullName = Metadata.FindByType(Type).FullName();
		ObjectName = StringFunctionsClientServer.SplitStringIntoSubstringArray(FullName, ".")[1];
		
		If Catalogs.AllRefsType().ContainsType(Type) Then
			Presentation = "CatalogRef";
		
		ElsIf Documents.AllRefsType().ContainsType(Type) Then
			Presentation = "DocumentRef";
		
		ElsIf BusinessProcesses.AllRefsType().ContainsType(Type) Then
			Presentation = "BusinessProcessRef";
		
		ElsIf ChartsOfCharacteristicTypes.AllRefsType().ContainsType(Type) Then
			Presentation = "ChartOfCharacteristicTypesRef";
		
		ElsIf ChartsOfAccounts.AllRefsType().ContainsType(Type) Then
			Presentation = "ChartOfAccountsRef";
		
		ElsIf ChartsOfCalculationTypes.AllRefsType().ContainsType(Type) Then
			Presentation = "ChartOfCalculationTypesRef";
		
		ElsIf Tasks.AllRefsType().ContainsType(Type) Then
			Presentation = "TaskRef";
		
		ElsIf ExchangePlans.AllRefsType().ContainsType(Type) Then
			Presentation = "ExchangePlanRef";
		
		ElsIf Enums.AllRefsType().ContainsType(Type) Then
			Presentation = "EnumRef";
		
		EndIf;
		
		Result = ?(Presentation = "", Presentation, Presentation + "." + ObjectName);
		
	Else
		
		Result = String(Type);
		
	EndIf;
	
	Return Result;
	
EndFunction

// Checks whether the type description contains only one value type and it 
// is equal to the specified type.
//
// Parameters:
//   TypeDescription - TypeDescription - type collection to be checked;
//   ValueType       - Type - type to be checked.
//
// Returns:
//   Boolean - True if match.
//
Function TypeDescriptionContainsType(TypeDescription, ValueType) Export
	
	If TypeDescription.Types().Count() = 1
	 And TypeDescription.Types().Get(0) = ValueType Then
		Return True;
	EndIf;
	
	Return False;

EndFunction

// Checks whether the catalog has the tabular section.
//
// Parameters:
//  CatalogName        - String - name of the catalog to be checked.
//  TabularSectionName - String - name of the tabular section whose existence will be checked.
//
// Returns:
//  Boolean - True if the catalog has the tabular section, otherwise is False.
//
// Example:
//  If Not CommonUse.CatalogHasTabularSection(CatalogName, "ContactInformation") Then
//  	Return;
//  EndIf;
//
Function CatalogHasTabularSection(CatalogName, TabularSectionName) Export
	
	Return (Metadata.Catalogs[CatalogName].TabularSections.Find(TabularSectionName) <> Undefined);
	
EndFunction

// Generates an extended object presentation.
// An extended object presentation contains an object presentation, a code, and a description.
// If generating an extended object presentation failed,
// then the function returns a standard object presentation generated by the platform.
//
// An example of the returning value:
// "Counterparty 0A-0001234, Telecom LLC"
//
// Parameters:
// Object - CatalogRef,
//        - ChartOfAccountsRef,
//        - ExchangePlanRef,
//        - ChartOfCharacteristicTypesRef,
//        - ChartOfCalculationTypesRef.
//          The object whose extended presentation is be generated.
//
// Returns:
// String - extended object presentation.
// 
Function ExtendedObjectPresentation(Object) Export
	
	MetadataObject = Object.Metadata();
	
	BaseTypeName = BaseTypeNameByMetadataObject(MetadataObject);
	
	If BaseTypeName = TypeNameCatalogs()
		Or BaseTypeName = TypeNameChartsOfAccounts()
		Or BaseTypeName = TypeNameExchangePlans()
		Or BaseTypeName = TypeNameChartsOfCharacteristicTypes()
		Or BaseTypeName = TypeNameChartsOfCalculationTypes()
		Then
		
		If  IsStandardAttribute(MetadataObject.StandardAttributes, "Code")
			AND IsStandardAttribute(MetadataObject.StandardAttributes, "Description") Then
			
			AttributeValues = ObjectAttributeValues(Object, "Code, Description");
			
			ObjectPresentation = ?(IsBlankString(MetadataObject.ObjectPresentation), 
										?(IsBlankString(MetadataObject.Synonym), MetadataObject.Name, MetadataObject.Synonym
										),
									MetadataObject.ObjectPresentation);

			
			Result = "[ObjectPresentation] [Code], [Description]";
			Result = StrReplace(Result, "[ObjectPresentation]", ObjectPresentation);
			Result = StrReplace(Result, "[Code]", ?(IsBlankString(AttributeValues.Code), "<>", AttributeValues.Code));
			Result = StrReplace(Result, "[Description]", ?(IsBlankString(AttributeValues.Description), "<>", AttributeValues.Description));
			
		Else
			
			Result = String(Object);
			
		EndIf;
		
	Else
		
		Result = String(Object);
		
	EndIf;
	
	Return Result;
EndFunction

// Returns a flag that shows whether the attribute is a standard attribute.
// 
// Parameters:
//  StandardAttributes – StandardAttributeDescriptions - collection whose types and values
//                       describe standard attributes;
//  AttributeName      – String – attribute to be checked.
// 
// Returns:
//  Boolean. True if attribute is a standard attribute, otherwise is False.
//
Function IsStandardAttribute(StandardAttributes, AttributeName) Export
	
	For Each Attribute In StandardAttributes Do
		
		If Attribute.Name = AttributeName Then
			
			Return True;
			
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

// Gets a value table with the required property information of all metadata object attributes.
// Gets property values of standard and custom attributes (Custom attributes are attributes
// created in Designer mode.)
//
// Parameters:
//  MetadataObject - MetadataObject - metadata object whose attribute property values is retrieved.
//                   For example: Metadata.Document.Invoice;
//  Properties     - String - attribute properties separated by commas whose values is retrieved.
//                   For example: "Name, Type, Synonym, ToolTip".
//
// Returns:
//  ValueTable - returning value table.
//
Function GetObjectPropertyInfoTable(MetadataObject, Properties) Export
	
	PropertyArray = StringFunctionsClientServer.SplitStringIntoSubstringArray(Properties);
	
	// The value to be returned
	ObjectPropertyInfoTable = New ValueTable;
	
	// Adding fields to the value table according to the names of the passed properties
	For Each PropertyName In PropertyArray Do
		
		ObjectPropertyInfoTable.Columns.Add(TrimAll(PropertyName));
		
	EndDo;
	
	// Filling table rows with metadata object attribute values
	For Each Attribute In MetadataObject.Attributes Do
		
		FillPropertyValues(ObjectPropertyInfoTable.Add(), Attribute);
		
	EndDo;
	
	// Filling table rows with values of the standard metadata object attributes 
	For Each Attribute In MetadataObject.StandardAttributes Do
		
		FillPropertyValues(ObjectPropertyInfoTable.Add(), Attribute);
		
	EndDo;
	
	Return ObjectPropertyInfoTable;
	
EndFunction

// Returns a common attribute content item usage state.
//
// Parameters:
//  ContentItem             - MetadataObject - common attribute content item 
//                           whose usage will be checked;
//  CommonAttributeMetadata - MetadataObject - common attribute metadata 
//                           whose ContentItem usage will be checked.
//
// Returns:
//  Boolean - True if the content item is used, otherwise is False.
//
Function CommonAttributeContentItemUsed(Val ContentItem, Val CommonAttributeMetadata) Export
	
	If ContentItem.Use = Metadata.ObjectProperties.CommonAttributeUse.Use Then
		Return True;
	ElsIf ContentItem.Use = Metadata.ObjectProperties.CommonAttributeUse.DontUse Then
		Return False;
	Else
		Return CommonAttributeMetadata.AutoUse = Metadata.ObjectProperties.CommonAttributeAutoUse.Use;
	EndIf;
	
EndFunction

// Returns a flag that shows whether the metadata object is used in a common separators.
//
// Parameters:
//  MetadataObject - String; MetadataObject - if metadata object is specified by the string,
//                   the function calls the CommonUseCached module.
//  Separator      - String - name common attribute separator that is searched.
//
// Returns:
//  Boolean - True if the metadata object is used in one or more common separators.
//
Function IsSeparatedMetadataObject(Val MetadataObject, Val Separator) Export
	
	If TypeOf(MetadataObject) = Type("String") Then
		MetadataObjectFullName = MetadataObject;
	Else
		MetadataObjectFullName = MetadataObject.FullName();
	EndIf;
	
	SeparatedMetadataObjects = CommonUseCached.SeparatedMetadataObjects(Separator);
	Return SeparatedMetadataObjects.Get(MetadataObjectFullName) <> Undefined;
	
EndFunction

// Returns the name of the predefined item by the specified reference.
// To be used instead of the obsolete GetPredefinedItemName method in configurations made for
// the platform 8.2.
//
// Parameters:
//  Ref - AnyRef - reference to the predefined item.
//
// Returns:
//  String - predefined item name.
//
Function PredefinedName(Val Ref) Export
	
	Return ObjectAttributeValue(Ref, "PredefinedDataName");
	
EndFunction

// Constructor of the TypeDescription object that contains the String type.
//
// Parameters:
//  StringLength - Number.
//
// ReturnValue:
//  TypeDescription.
//
Function StringTypeDescription(StringLength) Export

	Array = New Array;
	Array.Add(Type("String"));

	StringQualifier = New StringQualifiers(StringLength, AllowedLength.Variable);

	Return New TypeDescription(Array, , StringQualifier);

EndFunction

// Constructor of the TypeDescription object that contains the Number type.
//
// Parameters:
//  DigitCapacity - Number - total number of number digits (the number of digits in the integer
//                  part plus the number of digits in the fractional part).
//  FractionDigits - Number - number of fractional part digits.
//  NumberSign    - AllowedSign - allowed number sign.
//
// ReturnValue:
//  TypeDescription.
//
Function NumberTypeDescription(DigitCapacity, FractionDigits = 0, NumberSign = Undefined) Export

	If NumberSign = Undefined Then
		NumberQualifier = New NumberQualifiers(DigitCapacity, FractionDigits);
	Else
		NumberQualifier = New NumberQualifiers(DigitCapacity, FractionDigits, NumberSign);
	EndIf;

	Return New TypeDescription("Number", NumberQualifier);

EndFunction

// Constructor of the TypeDescription object that contains the Date type.
//
// Parameters:
//  DateFractions - DateFractions - set of Date type value usage options.
//
// ReturnValue:
//  TypeDescription.
//
Function DateTypeDescription(DateFractions) Export

	Array = New Array;
	Array.Add(Type("Date"));

	DateQualifier = New DateQualifiers(DateFractions);

	Return New TypeDescription(Array, , , DateQualifier);

EndFunction

// Checks whether the attribute with the passed name exists among the object attributes.
//
// Parameters:
//  AttributeName  - String - Attribute name;
//  ObjectMetadata - MetadataObject - object, where the attribute is searched.
//
// Returns:
//  Boolean.
//
Function HasObjectAttribute(AttributeName, ObjectMetadata) Export

	Return NOT (ObjectMetadata.Attributes.Find(AttributeName) = Undefined);

EndFunction

////////////////////////////////////////////////////////////////////////////////
// Functions for working with metadata object type definition.
//

// Reference data types. 

// Checks whether the metadata object belongs to the Document type.
// 
// Parameters:
//  MetadataObject – metadata object to be checked.
// 
// Returns:
//  Boolean.
//
Function IsDocument(MetadataObject) Export
	
	Return Metadata.Documents.Contains(MetadataObject);
	
EndFunction

// Checks whether the metadata object belongs to the Catalog type.
// 
// Parameters:
//  MetadataObject – metadata object to be checked.
// 
// Returns:
//  Boolean.
//
Function IsCatalog(MetadataObject) Export
	
	Return Metadata.Catalogs.Contains(MetadataObject);
	
EndFunction

// Checks whether the metadata object belongs to the Enumeration type.
// 
// Parameters:
//  MetadataObject – metadata object to be checked.
// 
// Returns:
//  Boolean.
//
Function IsEnum(MetadataObject) Export
	
	Return Metadata.Enums.Contains(MetadataObject);
	
EndFunction

// Checks whether the metadata object belongs to the Exchange plan type.
// 
// Parameters:
//  MetadataObject – metadata object to be checked.
// 
// Returns:
//  Boolean.
//
Function IsExchangePlan(MetadataObject) Export
	
	Return Metadata.ExchangePlans.Contains(MetadataObject);
	
EndFunction

// Checks whether the metadata object belongs to the Chart of characteristic types type.
// 
// Parameters:
//  MetadataObject – metadata object to be checked.
// 
// Returns:
//  Boolean.
//
Function IsChartOfCharacteristicTypes(MetadataObject) Export
	
	Return Metadata.ChartsOfCharacteristicTypes.Contains(MetadataObject);
	
EndFunction

// Checks whether the metadata object belongs to the Business process type.
// 
// Parameters:
//  MetadataObject – metadata object to be checked.
// 
// Returns:
//  Boolean.
//
Function IsBusinessProcess(MetadataObject) Export
	
	Return Metadata.BusinessProcesses.Contains(MetadataObject);
	
EndFunction

// Checks whether the metadata object belongs to the Task type.
// 
// Parameters:
//  MetadataObject – metadata object to be checked.
// 
// Returns:
//  Boolean.
//
Function IsTask(MetadataObject) Export
	
	Return Metadata.Tasks.Contains(MetadataObject);
	
EndFunction

// Checks whether the metadata object belongs to the Chart of accounts type.
// 
// Parameters:
//  MetadataObject – metadata object to be checked.
// 
// Returns:
//  Boolean.
//
Function IsChartOfAccounts(MetadataObject) Export
	
	Return Metadata.ChartsOfAccounts.Contains(MetadataObject);
	
EndFunction

// Checks whether the metadata object belongs to the Chart of calculation types type.
// 
// Parameters:
//  MetadataObject – metadata object to be checked.
// 
// Returns:
//  Boolean.
//
Function IsChartOfCalculationTypes(MetadataObject) Export
	
	Return Metadata.ChartsOfCalculationTypes.Contains(MetadataObject);
	
EndFunction

// Registers

// Checks whether the metadata object belongs to the Information register type.
// 
// Parameters:
//  MetadataObject – metadata object to be checked.
// 
// Returns:
//  Boolean.
//
Function IsInformationRegister(MetadataObject) Export
	
	Return Metadata.InformationRegisters.Contains(MetadataObject);
	
EndFunction

// Checks whether the metadata object belongs to the Accumulation register type.
// 
// Parameters:
//  MetadataObject – metadata object to be checked.
// 
// Returns:
//  Boolean.
//
Function IsAccumulationRegister(MetadataObject) Export
	
	Return Metadata.AccumulationRegisters.Contains(MetadataObject);
	
EndFunction

// Checks whether the metadata object belongs to the Accounting register type.
// 
// Parameters:
//  MetadataObject – metadata object to be checked.
// 
// Returns:
//  Boolean.
//
Function IsAccountingRegister(MetadataObject) Export
	
	Return Metadata.AccountingRegisters.Contains(MetadataObject);
	
EndFunction

// Checks whether the metadata object belongs to the Calculation register type.
// 
// Parameters:
//  MetadataObject – metadata object to be checked.
// 
// Returns:
//  Boolean.
//
Function IsCalculationRegister(MetadataObject) Export
	
	Return Metadata.CalculationRegisters.Contains(MetadataObject);
	
EndFunction

// Constants.

// Checks whether the metadata object belongs to the Constant type.
// 
// Parameters:
//  MetadataObject – metadata object to be checked.
// 
// Returns:
//  Boolean.
//
Function IsConstant(MetadataObject) Export
	
	Return Metadata.Constants.Contains(MetadataObject);
	
EndFunction

// Document journals.

// Checks whether the metadata object belongs to the Document journal type.
// 
// Parameters:
//  MetadataObject – metadata object to be checked.
// 
// Returns:
//  Boolean.
//
Function IsDocumentJournal(MetadataObject) Export
	
	Return Metadata.DocumentJournals.Contains(MetadataObject);
	
EndFunction

// Sequences.

// Checks whether the metadata object belongs to the Sequence type.
// 
// Parameters:
//  MetadataObject – metadata object to be checked.
// 
// Returns:
//  Boolean.
//
Function IsSequence(MetadataObject) Export
	
	Return Metadata.Sequences.Contains(MetadataObject);
	
EndFunction

// ScheduledJobs

// Checks whether the metadata object belongs to the Scheduled job type.
// 
// Parameters:
//  MetadataObject – metadata object to be checked.
// 
// Returns:
//  Boolean.
//
Function IsScheduledJob(MetadataObject) Export
	
	Return Metadata.ScheduledJobs.Contains(MetadataObject);
	
EndFunction

// Common.

// Checks whether the metadata object belongs to a register type.
// 
// Parameters:
//  MetadataObject – metadata object to be checked.
// 
// Returns:
//  Boolean.
//
Function IsRegister(MetadataObject) Export
	
	Return Metadata.AccountingRegisters.Contains(MetadataObject)
		Or Metadata.AccumulationRegisters.Contains(MetadataObject)
		Or Metadata.CalculationRegisters.Contains(MetadataObject)
		Or Metadata.InformationRegisters.Contains(MetadataObject);
		
EndFunction

// Checks whether the metadata object belongs to a reference type.
// 
// Parameters:
//  MetadataObject – metadata object to be checked.
// 
// Returns:
//  Boolean.
//
Function IsReferenceTypeObject(MetadataObject) Export
	
	MetadataObjectName = MetadataObject.FullName();
	Position = Find(MetadataObjectName, ".");
	If Position > 0 Then 
		BaseTypeName = Left(MetadataObjectName, Position - 1);
		Return BaseTypeName = "Catalog"
			Or BaseTypeName = "Document"
			Or BaseTypeName = "BusinessProcess"
			Or BaseTypeName = "Task"
			Or BaseTypeName = "ChartOfAccounts"
			Or BaseTypeName = "ExchangePlan"
			Or BaseTypeName = "ChartOfCharacteristicTypes"
			Or BaseTypeName = "ChartOfCalculationTypes";
	Else
		Return False;
	EndIf;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Type names.

// Returns a value for identification of the Information registers type. 
//
// Returns:
//  String.
//
Function TypeNameInformationRegisters() Export
	
	Return "InformationRegisters";
	
EndFunction

// Returns a value for identification of the Accumulation registers type. 
//
// Returns:
//  String.
//
Function TypeNameAccumulationRegisters() Export
	
	Return "AccumulationRegisters";
	
EndFunction

// Returns a value for identification of the Accounting registers type. 
//
// Returns:
//  String.
//
Function TypeNameAccountingRegisters() Export
	
	Return "AccountingRegisters";
	
EndFunction

// Returns a value for identification of the Calculation registers type. 
//
// Returns:
//  String.
//
Function TypeNameCalculationRegisters() Export
	
	Return "CalculationRegisters";
	
EndFunction

// Returns a value for identification of the Documents type. 
//
// Returns:
// String.
//
Function TypeNameDocuments() Export
	
	Return "Documents";
	
EndFunction

// Returns a value for identification of the Catalogs type. 
//
// Returns:
//  String.
//
Function TypeNameCatalogs() Export
	
	Return "Catalogs";
	
EndFunction

// Returns a value for identification of the Enumerations type. 
//
// Returns:
// String.
//
Function TypeNameEnums() Export
	
	Return "Enums";
	
EndFunction

// Returns a value for identification of the Reports type. 
//
// Returns:
//  String.
//
Function TypeNameReports() Export
	
	Return "Reports";
	
EndFunction

// Returns a value for identification of the Data processors type. 
//
// Returns:
//  String.
//
Function TypeNameDataProcessors() Export
	
	Return "DataProcessors";
	
EndFunction

// Returns a value for identification of the Exchange plans type. 
//
// Returns:
//  String.
//
Function TypeNameExchangePlans() Export
	
	Return "ExchangePlans";
	
EndFunction

// Returns a value for identification of the Charts of characteristic types type. 
//
// Returns:
//  String.
//
Function TypeNameChartsOfCharacteristicTypes() Export
	
	Return "ChartsOfCharacteristicTypes";
	
EndFunction

// Returns a value for identification of the Business processes type. 
//
// Returns:
//  String.
//
Function TypeNameBusinessProcesses() Export
	
	Return "BusinessProcesses";
	
EndFunction

// Returns a value for identification of the Tasks type. 
//
// Returns:
//  String.
//
Function TypeNameTasks() Export
	
	Return "Tasks";
	
EndFunction

// Returns a value for identification of the Charts of accounts type. 
//
// Returns:
//  String.
//
Function TypeNameChartsOfAccounts() Export
	
	Return "ChartsOfAccounts";
	
EndFunction

// Returns a value for identification of the Charts of calculation types type. 
//
// Returns:
//  String.
//
Function TypeNameChartsOfCalculationTypes() Export
	
	Return "ChartsOfCalculationTypes";
	
EndFunction

// Returns a value for identification of the Constants type. 
//
// Returns:
// String.
//
Function TypeNameConstants() Export
	
	Return "Constants";
	
EndFunction

// Returns a value for identification of the Document journals type. 
//
// Returns:
//  String.
//
Function TypeNameDocumentJournals() Export
	
	Return "DocumentJournals";
	
EndFunction

// Returns a value for identification of the Sequences type. 
//
// Returns:
//  String.
//
Function SequenceTypeName() Export
	
	Return "Sequences";
	
EndFunction

// Returns a value for identification of the Sequences type. 
//
// Returns:
//  String.
//
Function ScheduledJobTypeName() Export
	
	Return "ScheduledJobs";
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Saving, reading, and deleting settings from storages.

// Saves settings to the common settings storage.
//
// Parameters:
//   ObjectKey                 - String - settings object key.
//   SettingsKey               - String - key of the settings to be saved.
//   Value                     - Arbitrary - settings to be saved in a storage. 
//   SettingsDescription       - SettingsDescription - auxiliary settings data.
//   UserName                  - String - name of a user whose settings are saved.
//                               If it is not specified, current user settings are saved.
//   NeedToRefreshCachedValues - Boolean - flag that shows whether cashes of Cashed modules
//                               must be reset.
//
// See also:
//   "StandardSettingsStorageManager.Save" in Syntax Assistant.
//
Procedure CommonSettingsStorageSave(ObjectKey, SettingsKey = "", Value,
	SettingsDescription = Undefined, UserName = Undefined, 
	NeedToRefreshCachedValues = False) Export
	
	StorageSave(
		CommonSettingsStorage,
		ObjectKey,
		SettingsKey,
		Value,
		SettingsDescription,
		UserName,
		NeedToRefreshCachedValues);
	
EndProcedure

// Loads settings from the common settings storage.
//
// Parameters:
//   ObjectKey           - String - settings object key.
//   SettingsKey         - String - optional. A key of the settings to be saved.
//   DefaultValue        - Arbitrary - optional. The value to be substituted if the settings
//                         cannot be loaded.
//   SettingsDescription - SettingsDescription - optional. When reading the settings value,
//                         auxiliary settings data is written to this parameter.
//   UserName            - String - optional. A name of a user whose settings are loaded.
//                         If it is not specified, current user settings are loaded.
//
// Returns: 
//   Arbitrary - settings loaded from the storage.
//   Undefined - if settings are not found and the DefaultValue parameter is not specified.
//
// See also:
//   "StandardSettingsStorageManager.Load" in Syntax Assistant.
//
Function CommonSettingsStorageLoad(ObjectKey, SettingsKey = "", DefaultValue = Undefined, 
	SettingsDescription = Undefined, UserName = Undefined) Export
	
	Return StorageLoad(
		CommonSettingsStorage,
		ObjectKey,
		SettingsKey,
		DefaultValue,
		SettingsDescription,
		UserName);
	
EndFunction

// Deletes the settings item from the common settings storage.
//
// Parameters:
//   ObjectKey   - String - settings object key. 
//               - Undefined - settings for all objects are deleted.
//   SettingsKey - String - key of the settings to be saved.
//               - Undefined - settings and all keys are deleted.
//   UserName    - String - name of a user whose settings are deleted.
//               - Undefined - settings of all users are deleted.
//
// See also:
//   "StandardSettingsStorageManager.Delete" in Syntax Assistant.
//
Procedure CommonSettingsStorageDelete(ObjectKey, SettingsKey, UserName) Export
	
	StorageDelete(
		CommonSettingsStorage,
		ObjectKey,
		SettingsKey,
		UserName);
	
EndProcedure

// Saves the array of user settings to StructureArray. 
// Can be called on client.
// 
// Parameters:
//  StructureArray            - Array - Array of Structure with the following fields:
//                              Object, SettingsItem, Value;
//  NeedToRefreshCachedValues - Boolean - flag that shows whether cached values will be updated.
//
Procedure CommonSettingsStorageSaveArray(StructureArray,
	NeedToRefreshCachedValues = False) Export
	
	If Not AccessRight("SaveUserData", Metadata) Then
		Return;
	EndIf;
	
	For Each Item In StructureArray Do
		CommonSettingsStorage.Save(Item.Object, SettingsKey(Item.Settings), Item.Value);
	EndDo;
	
	If NeedToRefreshCachedValues Then
		RefreshReusableValues();
	EndIf;
	
EndProcedure

// Saves the StructureArray user settings array and updates 
// cached values. Can be called on client.
// 
// Parameters:
//  StructureArray - Array - Array of Structure with the following fields:
//                    Object, SettingsItem, Value.
//
Procedure CommonSettingsStorageSaveArrayAndRefreshCachedValues(StructureArray) Export
	
	CommonSettingsStorageSaveArray(StructureArray, True);
	
EndProcedure

// Saves the settings item to the common settings storage and updates 
// cached values.
// 
// Parameters:
//  Corresponds to the CommonSettingsStorage.Save method. 
//  See StorageSave() procedure parameters for details. 
//
Procedure CommonSettingsStorageSaveAndRefreshCachedValues(ObjectKey, SettingsKey, Value) Export
	
	CommonSettingsStorageSave(ObjectKey, SettingsKey, Value,,,True);
	
EndProcedure

// Saves settings item to the system settings storage.
//
// Parameters:
//   ObjectKey                 - String - settings object key.
//   SettingsKey               - String - key of the settings to be saved.
//   Value                     - Arbitrary - settings to be saved in a storage. 
//   SettingsDescription       - SettingsDescription - auxiliary settings data.
//   UserName                  - String - name of a user whose settings are saved.
//                               If it is not specified, current user settings are saved.
//   NeedToRefreshCachedValues - Boolean - flag that shows whether cashes of Cashed modules
//                               must be reset.
//
// See also:
//   "StandardSettingsStorageManager.Save" in Syntax Assistant.
//
Procedure SystemSettingsStorageSave(ObjectKey, SettingsKey = "", Value,
	SettingsDescription = Undefined, UserName = Undefined, 
	NeedToRefreshCachedValues = False) Export
	
	StorageSave(
		SystemSettingsStorage, 
		ObjectKey, 
		SettingsKey, 
		Value,
		SettingsDescription, 
		UserName, 
		NeedToRefreshCachedValues);
	
EndProcedure


// Loads settings item from the system settings storage.
//
// Parameters:
//   ObjectKey           - String - settings object key.
//   SettingsKey         - String - Optional. key of the settings to be saved.
//   DefaultValue        - Arbitrary - Optional.
//                         The value to be substituted if the settings cannot be loaded.
//   SettingsDescription - SettingsDescription - Optional. When reading the settings value,
//                         auxiliary settings data is written to this parameter.
//   UserName            - String - Optional. The name of a user whose settings are loaded.
//                         If it is not specified, current user settings are loaded.
//
// Returns: 
//   Arbitrary - settings loaded from the storage.
//   Undefined - if settings are not found and the DefaultValue parameter is not specified.
//
// See also:
//   "StandardSettingsStorageManager.Load" in Syntax Assistant.
//
Function SystemSettingsStorageLoad(ObjectKey, SettingsKey = "", DefaultValue = Undefined, 
	SettingsDescription = Undefined, UserName = Undefined) Export
	
	Return StorageLoad(
		SystemSettingsStorage, 
		ObjectKey, 
		SettingsKey, 
		DefaultValue, 
		SettingsDescription, 
		UserName);
	
EndFunction


// Deletes settings item from the system settings storage.
//
// Parameters:
//   ObjectKey   - String - settings object key. 
//               - Undefined - Settings for all objects are deleted.
//   SettingsKey - String - key of the settings to be saved.
//               - Undefined - Settings and all keys are deleted.
//   UserName    - String - name of a user whose settings are deleted.
//               - Undefined - Settings of all users are deleted.
//
// See also:
//   "StandardSettingsStorageManager.Delete" in Syntax Assistant.
//
Procedure SystemSettingsStorageDelete(ObjectKey, SettingsKey, UserName) Export
	
	StorageDelete(
		SystemSettingsStorage,
		ObjectKey,
		SettingsKey,
		UserName);
	
EndProcedure

// Saves settings item to the form data settings storage.
//
// Parameters:
//   ObjectKey                 - String - settings object key.
//   SettingsKey               - String - key of the settings to be saved.
//   Value                     - Arbitrary - settings to be saved in a storage. 
//   SettingsDescription       - SettingsDescription - auxiliary settings data.
//   UserName                  - String - name of a user whose settings are saved.
//                               If it is not specified, current user settings are saved.
//   NeedToRefreshCachedValues - Boolean - flag that shows whether cashes of Cashed modules
//                               must be reset.
//
// See also:
//   "StandardSettingsStorageManager.Save" in Syntax Assistant.
//
Procedure FormDataSettingsStorageSave(ObjectKey, SettingsKey = "", Value,
	SettingsDescription = Undefined, UserName = Undefined, 
	NeedToRefreshCachedValues = False) Export
	
	StorageSave(
		FormDataSettingsStorage, 
		ObjectKey, 
		SettingsKey, 
		Value,
		SettingsDescription, 
		UserName, 
		NeedToRefreshCachedValues);
	
EndProcedure

// Loads settings item from the form data settings storage.
//
// Parameters:
//   ObjectKey           - String - settings object key.
//   SettingsKey         - String - Optional. key of the settings to be saved.
//   DefaultValue        - Arbitrary - Optional.
//                         The value to be substituted if the settings cannot be loaded.
//   SettingsDescription - SettingsDescription - Optional. When reading the settings value,
//                         auxiliary settings data is written to this parameter.
//   UserName            - String - Optional. The name of a user whose settings are loaded.
//                         If it is not specified, current user settings are loaded.
//
// Returns: 
//   Arbitrary - settings loaded from the storage.
//   Undefined - if settings are not found and the DefaultValue parameter is not specified.
//
// See also:
//   "StandardSettingsStorageManager.Load" in Syntax Assistant.
//
Function FormDataSettingsStorageLoad(ObjectKey, SettingsKey = "", DefaultValue = Undefined, 
	SettingsDescription = Undefined, UserName = Undefined) Export
	
	Return StorageLoad(
		FormDataSettingsStorage, 
		ObjectKey, 
		SettingsKey, 
		DefaultValue, 
		SettingsDescription, 
		UserName);
	
EndFunction


// Deletes settings item from the form data settings storage.
//
// Parameters:
//   ObjectKey   - String - settings object key. 
//               - Undefined - Settings for all objects are deleted.
//   SettingsKey - String - key of the settings to be saved.
//               - Undefined - Settings and all keys are deleted.
//   UserName    - String - Name of a user whose settings are deleted.
//               - Undefined - Settings of all users are deleted.
//
// See also:
//   "StandardSettingsStorageManager.Delete" in Syntax Assistant.
//
Procedure FormDataSettingsStorageDelete(ObjectKey, SettingsKey, UserName) Export
	
	StorageDelete(
		FormDataSettingsStorage,
		ObjectKey,
		SettingsKey,
		UserName);
	
EndProcedure

// Saves settings item to the settings storage through its manager.
//
// Parameters:
//   StorageManager            - StandardSettingsStorageManager - Storage where the settings saved.
//   ObjectKey                 - String - settings object key.
//   SettingsKey               - String - key of the settings to be saved.
//   Value                     - Arbitrary - settings to be saved in a storage. 
//   SettingsDescription       - SettingsDescription - auxiliary settings data.
//   UserName                  - String - name of a user whose settings are saved.
//                               If it is not specified, current user settings are saved.
//   NeedToRefreshCachedValues - Boolean - flag that shows whether cashes of Cashed modules must be reset.
//
// See. also:
//   "StandardSettingsStorageManager.Save" in Syntax Assistant.
//   "Settings that are automatically saved to the system storage" in Syntax Assistant.
//
Procedure StorageSave(StorageManager, ObjectKey, SettingsKey, Value,
	SettingsDescription, UserName, NeedToRefreshCachedValues)
	
	If NOT AccessRight("SaveUserData", Metadata) Then
		Return;
	EndIf;
	
	StorageManager.Save(ObjectKey, SettingsKey(SettingsKey), Value, SettingsDescription, UserName);
	
	If NeedToRefreshCachedValues Then
		RefreshReusableValues();
	EndIf;
	
EndProcedure

// Loads settings item from the settings storage through its manager.
//
// Parameters:
//   StorageManager      - StandardSettingsStorageManager - storage from which the settings
//                         item is loaded.
//   ObjectKey           - String - settings object key.
//   SettingsKey         - String - Optional. The key of the settings to be saved.
//   DefaultValue        - Arbitrary - Optional. The value to be substituted if the settings
//                         cannot be loaded.
//   SettingsDescription - SettingsDescription - Optional. When reading the settings value, 
//                         auxiliary settings data is written to this parameter.
//   UserName            - String - Optional. name of a user whose settings are loaded.
//                         If it is not specified, current user settings are loaded.
//
// Returns: 
//   Arbitrary - settings loaded from the storage.
//   Undefined - if settings are not found and the DefaultValue parameter is not specified.
//
// See also:
//   "StandardSettingsStorageManager.Load" in Syntax Assistant.
//   "Settings that are automatically saved to the system storage" in Syntax Assistant.
//
Function StorageLoad(StorageManager, ObjectKey, SettingsKey, DefaultValue,
	SettingsDescription, UserName)
	
	Result = Undefined;
	
	If AccessRight("SaveUserData", Metadata) Then
		Result = StorageManager.Load(ObjectKey, SettingsKey(SettingsKey), SettingsDescription, UserName);
	EndIf;
	
	If Result = Undefined Then
		Result = DefaultValue;
	Else
		SetPrivilegedMode(True);
		If DeleteDeadReferences(Result) Then
			Result = DefaultValue;
		EndIf;
	EndIf;
	
	Return Result;
EndFunction


// Deletes dead references from a variable.
//
// Parameters:
//   RefOrCollection - AnyRef, Arbitrary - object to be checked or collection to be cleared.
//
// Returns: 
//   Boolean - 
//    * True  - if the RefOrCollection of a reference type and the object are not found in the infobase.
//    * False - when the RefOrCollection of a reference type or the object are found in the infobase.
//
Function DeleteDeadReferences(RefOrCollection)
	
	Type = TypeOf(RefOrCollection);
	
	If Type = Type("Undefined")
		Or Type = Type("Boolean")
		Or Type = Type("String")
		Or Type = Type("Number")
		Or Type = Type("Date") Then // Optimization - often used primitive types.
		
		Return False; // Not a reference.
		
	ElsIf Type = Type("Array") Then
		
		Count = RefOrCollection.Count();
		For Number = 1 To Count Do
			ReverseIndex = Count - Number;
			Value = RefOrCollection[ReverseIndex];
			If DeleteDeadReferences(Value) Then
				RefOrCollection.Delete(ReverseIndex);
			EndIf;
		EndDo;
		
		Return False; // Not a reference.
		
	ElsIf Type = Type("Structure")
		Or Type = Type("Map") Then
		
		For Each KeyAndValue In RefOrCollection Do
			Value = KeyAndValue.Value;
			If DeleteDeadReferences(Value) Then
				RefOrCollection.Insert(KeyAndValue.Key, Undefined);
			EndIf;
		EndDo;
		
		Return False; // Not a reference.
		
	ElsIf IsReference(Type) Then
		
		If ObjectAttributeValue(RefOrCollection, "Ref") = Undefined Then
			RefOrCollection = Undefined;
			Return True; // Dead reference.
		Else
			Return False; // Object found.
		EndIf;
		
	Else
		
		Return False; // Not a reference.
		
	EndIf;
	
EndFunction


// Deletes settings item from the settings storage through its manager.
//
// Parameters:
//   StorageManager - StandardSettingsStorageManager - storage where the settings item is deleted.
//   ObjectKey   - String - settings object key. 
//               - Undefined - Settings for all objects are deleted.
//   SettingsKey - String - key of the settings to be saved.
//               - Undefined - Settings and all keys are deleted.
//   UserName    - String - Name of a user whose settings are deleted.
//               - Undefined - Settings of all users are deleted.
//
// See also:
//   "StandardSettingsStorageManager.Delete" in Syntax Assistant.
//   "Settings that are automatically saved to the system storage" in Syntax Assistant.
//
Procedure StorageDelete(StorageManager, ObjectKey, SettingsKey, UserName)
	
	If AccessRight("SaveUserData", Metadata) Then
		StorageManager.Delete(ObjectKey, SettingsKey(SettingsKey), UserName);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Functions for setting up the working date

// Saves user working date settings.
//
// Parameters:
//  NewWorkingDate - Date - date to be set as a user working date.
//  UserName       - String - name of a user whose working date will be set.
//                   If it is not set, the current user working date will be set.
//			
Procedure SetUserWarkingDate(NewWorkingDate, UserName = Undefined) Export

	ObjectKey = Upper("WorkingDate");
	
	CommonSettingsStorageSave(ObjectKey, , NewWorkingDate, , UserName);

EndProcedure

// Returns the user working date settings value.
//
// Parameters:
//  UserName - String - name of a user whose working date is requested.
//             If it is not set, the current user working date will be set.
//
// Returns:
//  Date - user working date settings value or an empty date if the date is not set.
//
Function UserWorkingDate(UserName = Undefined) Export

	ObjectKey = Upper("WorkingDate");

	Result = CommonSettingsStorageLoad(ObjectKey, , '0001-01-01', , UserName);
	
	If TypeOf(Result) <> Type("Date") Then
		Result = '0001-01-01';
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the user working date settings value or the current session date if the user working
// date is not set.
//
// Parameters:
//  UserName - String - name of a user whose working date is requested.
//             If it is not set, the current user working date will be set.
//
// Returns:
//  Date - user working date settings value or the current session date if the user date is not set.
//
Function CurrentUserDate(UserName = Undefined) Export

	Result = UserWorkingDate(UserName);
	
	If NOT ValueIsFilled(Result) Then
		Result = CurrentSessionDate();
	EndIf;
	
	Return BegOfDay(Result);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Functions for handling spreadsheet documents.

// Checks whether the passed spreadsheet document fits a single page in the print layout.
//
// Parameters
//  Spreadsheet   - SpreadsheetDocument – spreadsheet document;
//  AreasToPut    – Array, SpreadsheetDocument - to be checked;
//  ResultOnError - Boolean - result to be returned in case of error.
//
// Returns:
//  Boolean – flag that shows whether the passed spreadsheet document fits a single page.
//
Function SpreadsheetDocumentFitsPage(Spreadsheet, AreasToPut, ResultOnError = True) Export

	Try
		Return Spreadsheet.CheckPut(AreasToPut);
	Except
		Return ResultOnError;
	EndTry;

EndFunction
 
////////////////////////////////////////////////////////////////////////////////
// Common procedures and functions for working in the data separation mode.

// Enables the exclusive infobase (data area) access mode.
//
// If data separation is enabled,
// the procedure starts a transaction and sets an exclusive managed lock
// on lock namespaces of all metadata object that are included in the DataArea separator.
//
// In other cases (for example, in case of the local mode) the procedure enables the exclusive mode.
//
// Parameters:
//   CheckNoOtherSessions - Boolean - flag that shows whether a search for other user sessions
//                          with the same separator value must be performed.
//                          If other sessions are found an exception will be raised.
//                          The parameter is used only when the application runs in the service
//                          mode.
//
Procedure LockInfobase(Val CheckNoOtherSessions = True) Export
	
	If Not CommonUseCached.DataSeparationEnabled() 
		Or Not CommonUseCached.CanUseSeparatedData() Then
		
		If NOT ExclusiveMode() Then
			SetExclusiveMode(True);
		EndIf;
	Else
		If SubsystemExists("StandardSubsystems.SaaSOperations") Then
			SaasOperationsModule = CommonModule("SaaSOperations");
			SaasOperationsModule.LockCurrentDataArea(CheckNoOtherSessions);
		Else
			Raise(NStr("en = 'The ""SaaS operations"" subsystem is not available'"));
		EndIf;
	EndIf;
		
EndProcedure

// Disables the exclusive infobase (data area) access mode.
//
// If data separation is enabled and this procedure is called from the 
// exception handler, it rolls a transaction back.
// If data separation is enabled and this procedure is called not from the exception 
// handler, it commits a transaction.
//
// In other cases (for example, in case of the local mode) the procedure disables the exclusive mode.
//
Procedure UnlockInfobase() Export
	
	If NOT CommonUseCached.DataSeparationEnabled() 
		Or NOT CommonUseCached.CanUseSeparatedData() Then
		
		If ExclusiveMode() Then
			SetExclusiveMode(False);
		EndIf;
	Else
		If SubsystemExists("StandardSubsystems.SaaSOperations") Then
			SaasOperationsModule = CommonModule("SaaSOperations");
			SaasOperationsModule.UnlockCurrentDataArea();
		Else
			Raise(NStr("en = 'The ""SaaS operations"" subsystem is not available'"));
		EndIf;
	EndIf;
	
EndProcedure

// Sets session separation.
//
// Parameters:
//   Use      - Boolean - flag that shows whether the DataArea separator is used in the session.
//   DataArea - Number - DataArea separator value
//
Procedure SetSessionSeparation(Val Use, Val DataArea = Undefined) Export
	
	SessionSeparationOnSet(Use, DataArea);
	
EndProcedure

// Returns a value of the current data area separator.
// If the value is not set an error is raised.
// 
// Returns: 
//   Separator value type - value of the current data area separator. 
// 
Function SessionSeparatorValue() Export
	
	If NOT CommonUseCached.DataSeparationEnabled() Then
		Return 0;
	Else
		SeparatorValue = Undefined;
		SessionSeparatorValueOnSet(SeparatorValue);
		Return SeparatorValue;
	EndIf;
	
EndFunction

// Returns the flag that shows whether DataArea separator is used.
// 
// Returns: 
//   Boolean - True if the separator is used.
// 
Function UseSessionSeparator() Export
	
	UseSeparator = Undefined;
	UseSessionSeparatorOnGet(UseSeparator);
	Return UseSeparator;
	
EndFunction

// Initializes the infobase separation.
// 
// Parameters:
//  TurnOnDataSeparation - Boolean - flag that shows whether 
//                         the infobase separation will be enabled.
//
Procedure SetInfobaseSeparationParameters(Val TurnOnDataSeparation = False) Export
	
	If TurnOnDataSeparation Then
		Constants.UseSeparationByDataAreas.Set(True);
	Else
		Constants.UseSeparationByDataAreas.Set(False);
	EndIf;
	
EndProcedure

// Writes the value of a reference type separated with AuxiliaryDataSeparator switching the
// session separator during the writing.
//
// Parameters:
//  AuxiliaryDataObject - AnyRef, ObjectDeletion - object of a reference type or ObjectDeletion.
//
Procedure WriteAuxiliaryData(AuxiliaryDataObject) Export
	
	If SubsystemExists("StandardSubsystems.SaaSOperations") Then
		SaasOperationsModule = CommonModule("SaaSOperations");
		SaasOperationsModule.WriteAuxiliaryData(AuxiliaryDataObject);
	Else
		AuxiliaryDataObject.Write();
	EndIf;
	
EndProcedure

// Deletes the value of a reference type separated with AuxiliaryDataSeparator switching the
// session separator during the writing.
//
// Parameters:
//  AuxiliaryDataObject - AnyRef - reference type value.
//
Procedure DeleteAuxiliaryData(AuxiliaryDataObject) Export
	
	If SubsystemExists("StandardSubsystems.SaaSOperations") Then
		SaasOperationsModule = CommonModule("SaaSOperations");
		SaasOperationsModule.DeleteAuxiliaryData(AuxiliaryDataObject);
	Else
		AuxiliaryDataObject.Delete();
	EndIf;
	
EndProcedure

/////////////////////////////////////////////////////////////////////////////////
// Interface versioning.

// Returns an array of version numbers supported by the remote system interface.
//
// Parameters:
//  URL           - String - service URL - interface versioning web service URL;
//  UserName      - String - service user name;
//  Password      - String - service user password;
//  InterfaceName - String - interface name.
//
// Returns:
//  FixedArray - Array of String - each string contains interface version number presentation.
//               For example, "1.0.2.1".
//
// Example:
//  ConnectionParameters = New Structure;
//  ConnectionParameters.Insert("URL", "http://vsrvx/sm");
//  ConnectionParameters.Insert("UserName", "Doe");
//  VersionArray = GetInterfaceVersions(ConnectionParameters, "FileTransferService");
//
// Note: when getting versions, a cache is used. It updates once a day.
// If you need to update the cache, you have to delete corresponding records from the
// ProgramInterfaceCache information register.
//
Function GetInterfaceVersions(Val Address, Val User, Val Password = Undefined, Val Interface = Undefined) Export
	
	If TypeOf(Address) = Type("Structure") Then
		ConnectionParameters = Address;
		InterfaceName = User;
	Else
		ConnectionParameters = New Structure;
		ConnectionParameters.Insert("URL", Address);
		ConnectionParameters.Insert("UserName", User);
		ConnectionParameters.Insert("Password", Password);
		InterfaceName = Interface;
	EndIf;
	
	If Not ConnectionParameters.Property("URL") 
		Or Not ValueIsFilled(ConnectionParameters.URL) Then
		
		Raise(NStr("en = 'Service URL is not specified.'"));
	EndIf;
	
	ReceivingParameters = New Array;
	ReceivingParameters.Add(ConnectionParameters);
	ReceivingParameters.Add(InterfaceName);
	
	Return CommonUseCached.GetVersionCacheData(
		VersionCacheRecordID(ConnectionParameters.URL, InterfaceName), 
		Enums.ProgramInterfaceCacheDataTypes.InterfaceVersions, 
		ValueToXMLString(ReceivingParameters),
		True);
	
EndFunction

// Returns an array of version numbers supported by the interface of a system that is connected
// via the external connection.
//
// Parameters:
//  ExternalConnection - COMObject - COM connection object that is used for working with a correspondent;
//  InterfaceName      - String.
//
// Returns:
// FixedArray - Array of String - each string contains interface version number presentation.
//              For example, "1.0.2.1".
//
// Example:
// Parameters = ...
// ExternalConnection = CommonUse.EstablishExternalConnection(Parameters);
// VersionArray = CommonUse.GetInterfaceVersionsViaExternalConnection(ExternalConnection, "DataExchange");
//
Function GetInterfaceVersionsViaExternalConnection(ExternalConnection, Val InterfaceName) Export
	Try
		XMLInterfaceVersions = ExternalConnection.StandardSubsystemsServer.SupportedVersions(InterfaceName);
	Except
		MessageString = NStr("en = 'The correspondent does not support interface versioning.
			|Error details: %1'");
		MessageString = StringFunctionsClientServer.SubstituteParametersInString(MessageString, DetailErrorDescription(ErrorInfo()));
		WriteLogEvent(NStr("en = 'Getting interface versions'", CommonUseClientServer.DefaultLanguageCode()),
			EventLogLevel.Error, , , MessageString);
		
		Return New FixedArray(New Array);
	EndTry;
	
	Return New FixedArray(ValueFromXMLString(XMLInterfaceVersions));
EndFunction

// Deletes version cache records that contain the specified
// substring in IDs. It can be, for example, a name of an interface that is not used any   
// more in the configuration as a substring.
//
// Parameters:
//  IDSearchSubstring - String - ID search substring. It cannot contain percent (%),
//  underscore (_), and left bracket ([).
//
Procedure VersionCacheRecordDeletion(Val IDSearchSubstring) Export
	
	BeginTransaction();
	
	Try
		
		DataLock = New DataLock;
		DataLock.Add("InformationRegister.ProgramInterfaceCache");
		SearchSubstring = GenerateSearchQueryString(IDSearchSubstring);

		QueryText =
			"SELECT
			|	CacheTable.ID AS ID,
			|	CacheTable.DataType AS DataType
			|FROM
			|	InformationRegister.ProgramInterfaceCache AS CacheTable
			|Where
			|	CacheTable.ID Like ""%" + SearchSubstring + "%""
			|		ESCAPE ""~""";
		
		Query = New Query(QueryText);
		Result = Query.Execute();
		Selection = Result.Select();
		While Selection.Next() Do
			
			Write = InformationRegisters.ProgramInterfaceCache.CreateRecordManager();
			Write.ID = Selection.ID;
			Write.DataType = Selection.DataType;
			
			Write.Delete();
			
		EndDo;
		
		CommitTransaction();
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// Procedures and functions for processing and calling optional subsystems.

// Returns True if the "functional" subsystem exists.
// Is intended for calling optional subsystems (condition call).
//
// The subsystem is referred to as "functional" if its "Include in command interface" check box 
// is cleared.
//
// Parameters:
//  FullSubsystemName - String - full name of the subsystem metadata object without
//                      "Subsystem." and with character case taken into account.
//                      For example: "StandardSubsystems.ReportOptions".
//
// Example:
//
//  If CommonUse.SubsystemExists("StandardSubsystem.ReportOptions") Then 
//    ReportOptionsModuleClient = CommonUseClient.CommonModule("ReportOptionsClient"));
//  	ReportOptionsModuleClient.<Method name>();
//  EndIf;
//
// Returns:
//  Boolean.
//
Function SubsystemExists(FullSubsystemName) Export
	
	SubsystemNames = StandardSubsystemsCached.SubsystemNames();
	Return SubsystemNames.Get(FullSubsystemName) <> Undefined;
	
EndFunction

// Returns a reference to the common module by the name.
//
// Parameters:
//   Name - String - common module name, for example: CommonUse, CommonUseClient.
//
// Returns:
//  CommonModule.
//
Function CommonModule(Name) Export
	
	If Metadata.CommonModules.Find(Name) <> Undefined Then
		Module = SafeMode.EvaluateInSafeMode(Name);
	ElsIf StrOccurrenceCount(Name, ".") = 1 Then
		Return ServerManagerModule(Name);
	Else
		Module = Undefined;
	EndIf;
	
	If TypeOf(Module) <> Type("CommonModule") Then
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'The %1 common module is not found.'"), Name);
	EndIf;
	
	Return Module;
	
EndFunction

#EndRegion

#Region InternalProceduresAndFunctions

////////////////////////////////////////////////////////////////////////////////
// Getting handlers of server events.

// Returns a structure used for adding a mandatory event.
//
// Returns:
//  Structure - 
//    * EventName - String - event presentation.
//                  Example: "StandardSubsystems.InfobaseVersionUpdate\OnAddUpdateHandlers".
//
//    * Required - Boolean - if True, this events requires handler declaration.
//
Function NewEvent() Export
	
	Return New Structure("Name, Required", "", False);

EndFunction

// Returns handlers of the specified server event.
//
// Parameters:
//  Event  - String, for example, "StandardSubsystems.InfobaseVersionUpdate\OnAddUpdateHandlers".
//
// Returns:
//  FixedArray - of FixedStructure with the following properties:
//    * Version - String - handler version, for example, "2.1.3.4". An empty string is returned
//                if the version is not specified.
//    * Module  - CommonModule - common server module.
// 
Function EventHandlers(Event) Export
	
	Return StandardSubsystemsCached.ServerEventHandlers(Event, False);
	
EndFunction

// Returns handlers of the specified internal server event.
//
// Parameters:
//  Event - String - for example, "StandardSubsystems.BaseFunctionality\SupportedInterfaceVersionsOnDefine".
//
// Returns:
//  FixedArray with values of the FixedStructure type with the following properties:
//    * Version - String - handler version, for example, "2.1.3.4". An empty string is returned
//                         if the version is not specified.
//    * Module  - CommonModule - common server module.
// 
Function InternalEventHandlers(Event) Export
	
	Return StandardSubsystemsCached.ServerEventHandlers(Event, True);
	
EndFunction

// Updates data in the version cache.
//
// Parameters:
//  ID                  - String - cache record ID.
//  DataType            - EnumRef.ProgramInterfaceCacheDataTypes - type of data to be update.
//  ReceivingParameters - Array - additional options of getting data to the cache.
//
Procedure RefreshVersionCacheData(Val ID, Val DataType, Val ReceivingParameters) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	CacheTable.UpdateDate AS UpdateDate,
		|	CacheTable.Data AS Data,
		|	CacheTable.DataType AS DataType
		|FROM
		|	InformationRegister.ProgramInterfaceCache AS CacheTable
		|Where
		|	CacheTable.ID = &ID
		|	AND CacheTable.DataType = &DataType";
	ID = ID;
	Query.SetParameter("ID", ID);
	Query.SetParameter("DataType", DataType);
	
	BeginTransaction();
	
	LockingError = False;
	
	Try
		
		KeyStructure = New Structure("ID, DataType", ID, DataType);
		RecordKey = InformationRegisters.ProgramInterfaceCache.CreateRecordKey(KeyStructure);
		Try
			LockDataForEdit(RecordKey);
		Except
			// The data is being updated from another session
			LockingError = True;
			Raise;
		EndTry;
		
		DataLock = New DataLock;
		LockItem = DataLock.Add("InformationRegister.ProgramInterfaceCache");
		LockItem.SetValue("ID", ID);
		LockItem.SetValue("DataType", DataType);
		DataLock.Lock();
		
		Result = Query.Execute();
		
		// Making sure the data must be updated
		If NOT Result.IsEmpty() Then
			Selection = Result.Select();
			Selection.Next();
			If NOT VersionCacheRecordObsolete(Selection) Then
				// Data is up-to-date
				RollbackTransaction();
				Return;
			EndIf;
		EndIf;
		
		Set = InformationRegisters.ProgramInterfaceCache.CreateRecordSet();
		
		Set.Filter.ID.Set(ID);
		Set.Filter.DataType.Set(DataType);
		
		Write = Set.Add();
		Write.ID = ID;
		Write.DataType = DataType;
		Write.UpdateDate = CurrentUniversalDate();
		
		If NOT CommonUseCached.DataSeparationEnabled() Or NOT CommonUseCached.CanUseSeparatedData() Then
		
			Data = PrepareVersionCacheData(DataType, ReceivingParameters);
			Write.Data = New ValueStorage(Data);
			
		Else
			
			Set.AdditionalProperties.Insert("ReceivingParameters", ReceivingParameters);
			
		EndIf;
		
		Set.Write();
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		If LockingError Then
			Return;
		Else
			Raise;
		EndIf;
		
	EndTry;
	
EndProcedure

// Prepares the data for the interface cache.
//
// Parameters:
//  DataType            - EnumRef.ProgramInterfaceCacheDataTypes - type of data to be update.
//  ReceivingParameters - Array - additional options of getting data to the cache.
//
Function PrepareVersionCacheData(Val DataType, Val ReceivingParameters) Export
	
	If DataType = Enums.ProgramInterfaceCacheDataTypes.InterfaceVersions Then
		Data = GetInterfaceVersionsToCache(ReceivingParameters[0], ReceivingParameters[1]);
	ElsIf DataType = Enums.ProgramInterfaceCacheDataTypes.WebServiceDetails Then
		Data = GetWSDL(ReceivingParameters[0], ReceivingParameters[1], ReceivingParameters[2], ReceivingParameters[3]);
	Else
		TextPattern = NStr("en = 'Unknown version cache data type: %1'");
		MessageText = StringFunctionsClientServer.SubstituteParametersInString(TextPattern, DataType);
		Raise(MessageText);
	EndIf;
	
	Return Data;
	
EndFunction

// Returns a flag that shows whether the version cache record is obsolete.
//
// Parameters:
//  Record - InformationRegisterRecordManager.ProgramInterfaceCache - record to be checked.
//
// Returns:
//  Boolean - flag that shows whether the record is obsolete.
//
Function VersionCacheRecordObsolete(Val Record) Export
	
	If Record.DataType = Enums.ProgramInterfaceCacheDataTypes.WebServiceDetails Then
		Return Not ValueIsFilled(Record.UpdateDate)
	Else
		Return Record.UpdateDate + 86400 < CurrentUniversalDate();
	EndIf;
	
EndFunction

// Generates a version cache record ID based on a server address and a resource name.
//
// Parameters:
//  Address - String - server address.
//  Name    - String - resource name.
//
// Returns:
//  String - version cache record ID. 
//
Function VersionCacheRecordID(Val Address, Val Name) Export
	
	Return Address + "|" + Name;
	
EndFunction

// Returns the WSDefinitions object created with the passed parameters.
//
// Comment: during the Definition retrieving the function uses the cache that is
// updated when the configuration version is changed. If you need to update cached
// value before this time (for example, in debug purposes), delete the respective 
// records from the ProgramInterfaceCache information register.
//
// Parameters:
//  WSDLAddress - String - wsdl location.
//  UserName    - String - user name for log on to the server.
//  Password    - String - user password.
//  Timeout    - Number  - wsdl retrieving timeout
//
// Returns:
//  WSDefinitions
 
//
Function WSDefinitions(Val WSDLAddress, Val UserName, Val Password, Val Timeout = 10) Export
	
	If NOT SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		Return New WSDefinitions(WSDLAddress, UserName, Password, ,Timeout);
	EndIf;
	
	ReceivingParameters = New Array;
	ReceivingParameters.Add(WSDLAddress);
	ReceivingParameters.Add(UserName);
	ReceivingParameters.Add(Password);
	ReceivingParameters.Add(Timeout);
	
	WSDLData = CommonUseCached.GetVersionCacheData(
		WSDLAddress, 
		Enums.ProgramInterfaceCacheDataTypes.WebServiceDetails, 
		ValueToXMLString(ReceivingParameters),
		False);
		
	WSDLFileName = GetTempFileName("wsdl");
	
	WSDLData.Write(WSDLFileName);
	
	Definitions = New WSDefinitions(WSDLFileName);
	
	Try
		DeleteFiles(WSDLFileName);
	Except
		WriteLogEvent(NStr("en = 'Getting WSDL'", CommonUseClientServer.DefaultLanguageCode()),
			EventLogLevel.Error, , , DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return Definitions;
EndFunction

// Returns the WSProxy object created using the passed parameters.
//
// Parameters:
//  WSDLAddress  - String - wsdl location.
//  NamespaceURI - String - web service namespace URI.
//  ServiceName  - String - service name.
//  EndpointName - String - if not specified, it is generated as <ServiceName>Soap.
//  UserName     - String - user name for logging on to the server.
//  Password     - String - User password.
//  Timeout      - Number - timeout for operations executed through the proxy. 
//
// Returns:
//  WSProxy.
//
Function InnerWSProxy(Val WSDLAddress, Val NamespaceURI, Val ServiceName,
	Val EndpointName = "", Val UserName, Val Password,
	Val Timeout = Undefined) Export
	
	WSDefinitions = CommonUseCached.WSDefinitions(WSDLAddress, UserName, Password);
	
	If IsBlankString(EndpointName) Then
		EndpointName = ServiceName + "Soap";
	EndIf;
	
	InternetProxy = Undefined;
	If SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		GetFilesFromInternetClientServerModule = CommonModule("GetFilesFromInternetClientServer");
		InternetProxy = GetFilesFromInternetClientServerModule.GetProxy(WSDLAddress);
	EndIf;
	
	Proxy = New WSProxy(WSDefinitions, NamespaceURI, ServiceName, EndpointName, InternetProxy, Timeout);
	Proxy.User     = UserName;
	Proxy.Password = Password;
	
	Return Proxy;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// AUXILIARY PROCEDURES AND FUNCTIONS

Procedure NewMetadataObjectCollectionRow(Name, Synonym, Picture, ObjectPicture, Tab)
	
	NewRow = Tab.Add();
	NewRow.Name          = Name;
	NewRow.Synonym       = Synonym;
	NewRow.Picture       = Picture;
	NewRow.ObjectPicture = ObjectPicture;
	
EndProcedure

Function GetInterfaceVersionsToCache(Val ConnectionParameters, Val InterfaceName)
	
	If NOT ConnectionParameters.Property("URL") 
		Or NOT ValueIsFilled(ConnectionParameters.URL) Then
		
		Raise(NStr("en = 'Service URL is not set.'"));
	EndIf;
	
	If ConnectionParameters.Property("UserName")
		AND ValueIsFilled(ConnectionParameters.UserName) Then
		
		UserName = ConnectionParameters.UserName;
		
		If ConnectionParameters.Property("Password") Then
			UserPassword = ConnectionParameters.Password;
		Else
			UserPassword = Undefined;
		EndIf;
		
	Else
		UserName = Undefined;
		UserPassword = Undefined;
	EndIf;
	
	ServiceURL = ConnectionParameters.URL + "/ws/InterfaceVersion?wsdl";
	
	VersioningProxy = WSProxy(ServiceURL, "http://www.1c.ru/SaaS/1.0/WS",
		"InterfaceVersion", , UserName, UserPassword, 3);
		
	XDTOArray = VersioningProxy.GetVersions(InterfaceName);
	If XDTOArray = Undefined Then
		Return New FixedArray(New Array);
	Else	
		Serializer = New XDTOSerializer(VersioningProxy.XDTOFactory);
		Return New FixedArray(Serializer.ReadXDTO(XDTOArray));
	EndIf;
	
EndFunction

Function GetWSDL(Val Address, Val UserName, Val Password, Val Timeout)
	
	ReceivingParameters = New Structure;
	If NOT IsBlankString(UserName) Then
		ReceivingParameters.Insert("User", UserName);
		ReceivingParameters.Insert("Password", Password);
	EndIf;
	ReceivingParameters.Insert("Timeout", Timeout);
	
	FileDetails = Undefined;
	
	FileOnDownloadOnServer(Address, ReceivingParameters, FileDetails);
	
	If NOT FileDetails.Status Then
		Raise(NStr("en = 'Error getting the Web service description file:'") + Chars.LF + FileDetails.ErrorMessage)
	EndIf;
	
	// Trying to create WS definitions based on the received file
	Definitions = New WSDefinitions(FileDetails.Path);
	If Definitions.Services.Count() = 0 Then
		MessagePattern = NStr("en = 'Error getting the Web service description file:
			|The received file does not contain any service descriptions.
			|
			|Perhaps, the description file address is specified incorrectly:
			|%1'");
		MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessagePattern, Address);
		Raise(MessageText);
	EndIf;
	Definitions = Undefined;
	
	FileData = New BinaryData(FileDetails.Path);
	
	Try
		DeleteFiles(FileDetails.Path);
	Except
		WriteLogEvent(NStr("en = 'Getting WSDL'", CommonUseClientServer.DefaultLanguageCode()),
			EventLogLevel.Error, , , DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return FileData;
	
EndFunction

Function CollectionName(FullName)
	
	DotPosition = Find(FullName, ".");
	
	If DotPosition > 0 Then
		Return Left(FullName, DotPosition - 1);
	EndIf;
	
	Return "";
	
EndFunction

Procedure CheckDataFixed(Data, DataInFixedTypeValue = False)
	
	DataType = TypeOf(Data);
	
	If DataType = Type("ValueStorage")
	 Or DataType = Type("FixedArray")
	 Or DataType = Type("FixedStructure")
	 Or DataType = Type("FixedMap") Then
		
		Return;
	EndIf;
	
	If DataInFixedTypeValue Then
		
		If DataType = Type("Boolean")
		 Or DataType = Type("String")
		 Or DataType = Type("Number")
		 Or DataType = Type("Date")
		 Or DataType = Type("Undefined")
		 Or DataType = Type("UUID")
		 Or DataType = Type("Null")
		 Or DataType = Type("Type")
		 Or DataType = Type("ValueStorage")
		 Or DataType = Type("CommonModule")
		 Or DataType = Type("MetadataObject")
		 Or DataType = Type("XDTOValueType")
		 Or DataType = Type("XDTOObjectType")
		 Or IsReference(DataType) Then
			
			Return;
		EndIf;
	EndIf;
	
	Raise StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en = 'Error in CommonUse.FixedData:
		           |Data of the %1 type cannot be fixed.'"),
		String(DataType) );
	
EndProcedure

Procedure AddRefSearchExclusions(RefSearchExclusions, ExceptionArray)
	For Each ArrayElement In ExceptionArray Do
		If TypeOf(ArrayElement) = Type("String") Then
			MetadataItem = Metadata.FindByFullName(ArrayElement);
		Else
			MetadataItem = ArrayElement;
		EndIf;
		
		MetadataParent = MetadataItem.Parent();
		
		// Registering a whole metadata object to be struck off (all references it can contain).
		If TypeOf(MetadataParent) = Type("ConfigurationMetadataObject") Then
			RefSearchExclusions.Insert(MetadataItem, "*");
			Continue;
		EndIf;
		
		// Registering the metadata object attribute to be struck off.
		RelativePathToAttribute = MetadataItem.Name;
		ParentParent = MetadataParent.Parent();
		While TypeOf(ParentParent) <> Type("ConfigurationMetadataObject") Do
			RelativePathToAttribute = MetadataParent.Name + "." + RelativePathToAttribute;
			MetadataParent = ParentParent;
			ParentParent   = MetadataParent.Parent();
		EndDo;
		
		PathsToAttributes = RefSearchExclusions.Get(MetadataParent);
		If PathsToAttributes = Undefined Then
			PathsToAttributes = New Array;
		ElsIf PathsToAttributes = "*" Then
			Continue; // Skipping if the entire metadata object has already been struck off.
		EndIf;
		PathsToAttributes.Add(RelativePathToAttribute);
		
		RefSearchExclusions.Insert(MetadataParent, PathsToAttributes);
	EndDo;
EndProcedure

// Returns a settings key string within a valid length.
// Checks the length of the passed string. If it exceeds 128, converts its end according to the
// MD5 algorithm into a short alternative. As the result, the string becomes 128 character
// length.
// If the original string is less then 128 characters, it is returned as is.
//
// Parameters:
//  String - String - string of an arbitrary length.
//
Function SettingsKey(Val String)
	Result = String;
	If StrLen(String) > 128 Then // A key longer than 128 characters raises an exception when accessing the settings storage
		Result = Left(String, 96);
		DataHashing = New DataHashing(HashFunction.MD5);
		DataHashing.Append(Mid(String, 97));
		Result = Result + StrReplace(DataHashing.HashSum, " ", "");
	EndIf;
	Return Result;
EndFunction

// Returns a server manager module by the object name.
Function ServerManagerModule(Name)
	ObjectFound = False;
	
	NameParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(Name, ".");
	If NameParts.Count() = 2 Then
		
		KindName = Upper(NameParts[0]);
		ObjectName = NameParts[1];
		
		If KindName = Upper(TypeNameConstants()) Then
			If Metadata.Constants.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(TypeNameInformationRegisters()) Then
			If Metadata.InformationRegisters.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(TypeNameAccumulationRegisters()) Then
			If Metadata.AccumulationRegisters.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(TypeNameAccountingRegisters()) Then
			If Metadata.AccountingRegisters.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(TypeNameCalculationRegisters()) Then
			If Metadata.CalculationRegisters.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(TypeNameCatalogs()) Then
			If Metadata.Catalogs.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(TypeNameDocuments()) Then
			If Metadata.Documents.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(TypeNameReports()) Then
			If Metadata.Reports.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(TypeNameDataProcessors()) Then
			If Metadata.DataProcessors.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(TypeNameBusinessProcesses()) Then
			If Metadata.BusinessProcesses.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(TypeNameDocumentJournals()) Then
			If Metadata.DocumentJournals.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(TypeNameTasks()) Then
			If Metadata.Tasks.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(TypeNameChartsOfAccounts()) Then
			If Metadata.ChartsOfAccounts.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(TypeNameExchangePlans()) Then
			If Metadata.ExchangePlans.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(TypeNameChartsOfCharacteristicTypes()) Then
			If Metadata.ChartsOfCharacteristicTypes.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(TypeNameChartsOfCalculationTypes()) Then
			If Metadata.ChartsOfCalculationTypes.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		EndIf;
		
	EndIf;
	
	If NOT ObjectFound Then
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'The ""%1"" metadata object is not found or does not have a module manager.'"), Name);
	EndIf;
	
	Module = SafeMode.EvaluateInSafeMode(Name);
	
	Return Module;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Handlers of conditional calls of other subsystems

// Gets a file from the internet via HTTP(S) or FTP and saves it to a temporary file.
//
// Parameters:
// URL                 - String - file URL in the following format:
//                       [Protocol://]<Server>/<Path to file on server>;
// ReceivingParameters - structure with the following properties:
//                        PathForSaving     - String - path on the 1C:Enterprise server
//                                            (including a file name) for
//                                            saving the downloaded file;
//                        User              - String - account used for connecting to the HTTP
//                                            or FTP server;
//                        Password          - String - password used for connecting to the HTTP
//                                            or FTP server;
//                        Port              - Number - port used for connecting to the HTTP or
//                                            FTP server; 
//                        SecureConnection  - Boolean - in case of HTTP this flag shows
//                                            whether a secure HTTPS connection is used;
//                        PassiveConnection - Boolean - in case of FTP this flag shows 
//                                            whether the connection mode is passive or active;
// Returns:
//  Structure with the following properties:
//   State        - Boolean - this key is always present in the structure, it can have the
//                  following values:
//                   True  - function execution completed successfully;
//                   False - function execution failed;
//                   Path  - String - path to the file on the 1C:Enterprise server. This
//                           key is used only 
//                           if State is True.
//   ErrorMessage - String - error message if State is False.
//
Procedure FileOnDownloadOnServer(Val Address, Val ReceivingParameters, ReturnValue)
	
	If SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		GetFilesFromInternetModule = CommonModule("GetFilesFromInternet");
		ReturnValue = GetFilesFromInternetModule.DownloadFileAtServer(Address, ReceivingParameters);
	EndIf;
	
EndProcedure

// Sets session separation.
//
// Parameters:
// Use      - Boolean - flag that shows whether the DataArea separator is used in the session.
// DataArea - Number - DataArea separator value
//
Procedure SessionSeparationOnSet(Val Use, Val DataArea = Undefined)
	
	If SubsystemExists("StandardSubsystems.SaaSOperations") Then
		SaasOperationsModule = CommonModule("SaaSOperations");
		SaasOperationsModule.SetSessionSeparation(Use, DataArea);
	EndIf;
	
EndProcedure

// Returns a value of the current data area separator.
// If the value is not set an error is raised.
// 
// Parameters:
//  SeparatorValue - The value of the current data area separator. Return value.
//
Procedure SessionSeparatorValueOnSet(SeparatorValue)
	
	If SubsystemExists("StandardSubsystems.SaaSOperations") Then
		SaasOperationsModule = CommonModule("SaaSOperations");
		SeparatorValue = SaasOperationsModule.SessionSeparatorValue();
	Else
		Raise(NStr("en = 'The ""SaaS operations"" subsystem is not available'"));
	EndIf;
	
EndProcedure

// Returns the flag that shows whether DataArea separator is used.
// 
// Parameters:
// UseSeparator - Boolean - True if separation is used, otherwise returns False. Return value.
// 
Procedure UseSessionSeparatorOnGet(UseSeparator) Export
	
	If SubsystemExists("StandardSubsystems.SaaSOperations") Then
		SaasOperationsModule = CommonModule("SaaSOperations");
		UseSeparator = SaasOperationsModule.UseSessionSeparator();
	Else
		Raise(NStr("en = 'The ""SaaS operations"" subsystem is not available'"));
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// AUXILIARY PROCEDURES AND FUNCTIOS (Reference replacement)

Function RecordKeysTypeDescription()
	
	AddedTypes = New Array;
	For Each Meta In Metadata.InformationRegisters Do
		AddedTypes.Add(Type("InformationRegisterRecordKey." + Meta.Name));
	EndDo;
	For Each Meta In Metadata.AccumulationRegisters Do
		AddedTypes.Add(Type("AccumulationRegisterRecordKey." + Meta.Name));
	EndDo;
	For Each Meta In Metadata.AccountingRegisters Do
		AddedTypes.Add(Type("AccountingRegisterRecordKey." + Meta.Name));
	EndDo;
	For Each Meta In Metadata.CalculationRegisters Do
		AddedTypes.Add(Type("CalculationRegisterRecordKey." + Meta.Name));
	EndDo;
	
	Return New TypeDescription(AddedTypes); 
EndFunction

Procedure MarkUsageInstances(Val Configuration, Val Ref, Val DestinationRef, Val SearchTable, MarkupResult = Undefined)
	SetPrivilegedMode(True);

	RecordKeyType = Configuration.RecordKeyType;
	MetaConstants = Configuration.MetaConstants;
	AllRefsType   = Configuration.AllRefsType;
	RecordKeyType = Configuration.RecordKeyType;
	
	// Setting the order of known objects and checking whether there are unidentified ones
	RefFilter = New Structure("Ref, ReplacementKey", Ref, "");
	
	MarkupResult = New Structure;
	MarkupResult.Insert("UsageInstances", SearchTable.FindRows(RefFilter) );
	MarkupResult.Insert("MarkupErrors",   New Array);
	
	For Each UsageInstance In MarkupResult.UsageInstances Do
		InstancesMetadata = UsageInstance.Metadata;
		
		If UsageInstance.AuxiliaryData Then
			// Skipping dependent data
			Continue;
			
		ElsIf MetaConstants.Contains(InstancesMetadata) Then
			UsageInstance.ReplacementKey = "Constant";
			UsageInstance.DestinationRef = DestinationRef;
			
		Else
			DataType = TypeOf(UsageInstance.Data);
			If AllRefsType.ContainsType(DataType) Then
				UsageInstance.ReplacementKey = "Object";
				UsageInstance.DestinationRef = DestinationRef;
				
			ElsIf RecordKeyType.ContainsType(DataType) Then
				UsageInstance.ReplacementKey = "RecordKey";
				UsageInstance.DestinationRef = DestinationRef;
				
			Else
				// Unknown object for reference replacement
				Text = NStr("en = 'Unknown data type (%1) for replacing %2'");
				Text = StrReplace(Text, "%1", String(UsageInstance.Data));
				Text = StrReplace(Text, "%2", String(Ref));
				MarkupResult.MarkupErrors.Add(
					New Structure("Object, Text", UsageInstance.Data, Text));
				
				Break;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

Procedure ReplaceInConstant(Results, Val UsageInstance, Val WriteParameters, Val InnerTransaction = True)
	SetPrivilegedMode(True);
	
	Data = UsageInstance.Data;
	Meta = UsageInstance.Metadata;
	
	DataPresentation = String(Data);
	
	// Performing all replacement of the data in the same time
	Filter = New Structure("Data, ReplacementKey", Data, "Constant");
	RowsToProcess = UsageInstance.Owner().FindRows(Filter);
	
	ActionState = "";
	
	If InnerTransaction Then
		BeginTransaction();
		
		DataLock = New DataLock;
		DataLock.Add(Meta.FullName());
	
		Try
			DataLock.Lock();
		Except
			// Adding the record to the unsuccessful lock attempt result
			Error = NStr("en = 'Cannot lock the %1 constant'");
			Error = StrReplace(Error, "%1", DataPresentation);
			
			ActionState = "LockError";
		EndTry;
		
	EndIf;	// Need of locking
	
	If ActionState = "" Then
		Manager = Constants[Meta.Name].CreateValueManager();
		Manager.Read();
		
		ReplacementPerformed = True;
		For Each Row In RowsToProcess Do
			If Manager.Value = Row.Ref Then
				Manager.Value = Row.DestinationRef;
				ReplacementPerformed = True;
			EndIf;
		EndDo;
		
		If ReplacementPerformed Then
			// Attempting to save
			If Not WriteParameters.WriteInPrivilegedMode Then
				SetPrivilegedMode(False);
			EndIf;
			
			Try
				WriteObject(Manager, WriteParameters);
			Except
				// Saving the cause
				Information = ErrorInfo();
				WriteLogEvent(ReferenceReplacementEventLogMessageText(),
					EventLogLevel.Error, Meta, DetailErrorDescription(Information));
				
				// Adding a record to the record error result
				ErrorDescription = BriefErrorDescription(Information);
				If IsBlankString(ErrorDescription) Then
					ErrorDescription = Information.Details;
				EndIf;
				
				Error = NStr("en = 'Cannot write %1 by the following reason: %2'");
				Error = StrReplace(Error, "%1", DataPresentation);
				Error = StrReplace(Error, "%2", ErrorDescription);
				
				For Each Row In RowsToProcess Do
					AddReplacementResult(Results, Row.Ref, 
						ReplacementErrorDetails("WritingError", Data, DataPresentation, Error)
					);
				EndDo;
				
				ActionState = "WritingError";
			EndTry;
			
			If NOT WriteParameters.WriteInPrivilegedMode Then
				SetPrivilegedMode(True);
			EndIf;
			
		EndIf;
	EndIf;
	
	If InnerTransaction Then
		If ActionState = "" Then
			CommitTransaction();
		Else
			RollbackTransaction();
		EndIf;
	EndIf;
	
	// Marking as processed
	For Each Row In RowsToProcess Do
		Row.ReplacementKey = "";
	EndDo;

EndProcedure

Procedure ReplaceInObject(Results, Val UsageInstance, Val WriteParameters, Val InnerTransaction = True)
	SetPrivilegedMode(True);
	
	Data = UsageInstance.Data;
	Meta   = UsageInstance.Metadata;
	
	DataPresentation = String(Data);
	
	// Performing all replacement of the data in the same time
	Filter = New Structure("Data, ReplacementKey", Data, "Object");
	RowsToProcess = UsageInstance.Owner().FindRows(Filter);
	
	SequenceDescription       = SequenceDescription(Meta);
	RegisterRecordDescription = RegisterRecordDescription(Meta);

	ActionState = "";
	
	If InnerTransaction Then
		// Process all connected data at the same time
		BeginTransaction();
		
		DataLock = New DataLock;
		
		// The item
		DataLock.Add(Meta.FullName()).SetValue("Ref", Data);
		
		// RegisterRecords 
		For Each Item In RegisterRecordDescription Do
			// Everything by the recorder
			DataLock.Add(Item.LockSpace + ".RecordSet").SetValue("Recorder", Data);
			
			// All candidates are dimensions for saving the results
			For Each KeyValue In Item.MeasurementList Do
				DimensionType  = KeyValue.Value;
				For Each UsageInstance In RowsToProcess Do
					CurrentRef = UsageInstance.Ref;
					If DimensionType.ContainsType(TypeOf(CurrentRef)) Then
						DataLock.Add(Item.LockSpace).SetValue(KeyValue.Key, UsageInstance.Ref);
					EndIf;
				EndDo;
			EndDo;
		EndDo;
		
		// Sequences
		For Each Item In SequenceDescription Do
			DataLock.Add(Item.LockSpace).SetValue("Recorder", Data);
			
			For Each KeyValue In Item.MeasurementList Do
				DimensionType = KeyValue.Value;
				For Each UsageInstance In RowsToProcess Do
					CurrentRef = UsageInstance.Ref;
					If DimensionType.ContainsType(TypeOf(CurrentRef)) Then
						DataLock.Add(Item.LockSpace).SetValue(KeyValue.Key, CurrentRef);
					EndIf;
				EndDo;
			EndDo;
		EndDo;
		
		Try
			DataLock.Lock();
		Except
			// Adding the record to the unsuccessful lock attempt result
			Error = NStr("en = 'Cannot lock one or several objects from the %1 list'");
			Error = StrReplace(Error, "%1", LockListDescription(DataLock));
			For Each Row In RowsToProcess Do
				AddReplacementResult(Results, Row.Ref, 
					ReplacementErrorDetails("LockError", Data, DataPresentation, Error)
				);
			EndDo;
			
			ActionState = "LockError";
		EndTry;
		
	EndIf;	// Need of locking
	
	If ActionState = "" Then
		WritingObjects = ModifiedObjectsOnReplaceInObject(Data, RowsToProcess, RegisterRecordDescription, SequenceDescription);
		
		// Attempting to save, the object goes last
		If Not WriteParameters.WriteInPrivilegedMode Then
			SetPrivilegedMode(False);
		EndIf;
		
		Try
			If WriteParameters.DontCheck Then
				// Writing without the business logic control
				For Each KeyValue In WritingObjects Do
					WriteObject(KeyValue.Key, WriteParameters);
				EndDo;
				
			Else
				// First writing iteration without the control to fix loop references
				WriteParameters.DontCheck = True;
				For Each KeyValue In WritingObjects Do
					WriteObject(KeyValue.Key, WriteParameters);
				EndDo;
				
				// Second writing iteration with the control
				WriteParameters.DontCheck = False;
				For Each KeyValue In WritingObjects Do
					WriteObject(KeyValue.Key, WriteParameters);
				EndDo;
			EndIf;
			
		Except
			// Saving the cause
			Information = ErrorInfo();
			WriteLogEvent(ReferenceReplacementEventLogMessageText(),
				EventLogLevel.Error, Meta, DetailErrorDescription(Information));
				
			ErrorDescription = BriefErrorDescription(Information);
			If IsBlankString(ErrorDescription) Then
				ErrorDescription = Information.Details;
			EndIf;
			
			// Adding a record to the record error result
			Error = NStr("en = 'Cannot write %1 by the following reason: %2'");
			Error = StrReplace(Error, "%1", DataPresentation);
			Error = StrReplace(Error, "%2", ErrorDescription);
			
			For Each Row In RowsToProcess Do
				AddReplacementResult(Results, Row.Ref, 
					ReplacementErrorDetails("WritingError", Data, DataPresentation, Error)
				);
			EndDo;
			
			ActionState = "WritingError";
		EndTry;
		
		If NOT WriteParameters.WriteInPrivilegedMode Then
			SetPrivilegedMode(True);
		EndIf;
		
		// Deleting processed register records and sequences from the search table
	EndIf;
	
	If InnerTransaction Then
		If ActionState = "" Then
			CommitTransaction();
		Else
			RollbackTransaction();
		EndIf;
	EndIf;
	
	// Marking as processed
	For Each Row In RowsToProcess Do
		Row.ReplacementKey = "";
	EndDo;
	
EndProcedure

Procedure ReplaceInSet(Results, Val UsageInstance, Val WriteParameters, Val InnerTransaction = True)
	SetPrivilegedMode(True);
	
	Data = UsageInstance.Data;
	Meta = UsageInstance.Metadata;
	
	DataPresentation = String(Data);
	
	// Performing all replacement of the data in the same time
	Filter = New Structure("Data, ReplacementKey", Data, "RecordKey");
	RowsToProcess = UsageInstance.Owner().FindRows(Filter);
	
	SetDescription = RecordKeyDescription(Meta);
	RecordSet = SetDescription.RecordSet;
	
	ReplacementCouples = New Map;
	For Each Row In RowsToProcess Do
		ReplacementCouples.Insert(Row.Ref, Row.DestinationRef);
	EndDo;
	
	ActionState = "";
	
	If InnerTransaction Then
		BeginTransaction();
		
		// Locking and preparing the set
		DataLock = New DataLock;
		For Each KeyValue In SetDescription.MeasurementList Do
			DimensionType = KeyValue.Value;
			Name          = KeyValue.Key;
			Value     = Data[Name];
			
			For Each Row In RowsToProcess Do
				CurrentRef = Row.Ref;
				If DimensionType.ContainsType(TypeOf(CurrentRef)) Then
					DataLock.Add(SetDescription.LockSpace).SetValue(Name, CurrentRef);
				EndIf;
			EndDo;
			
			RecordSet.Filter[Name].Set(Value);
		EndDo;
		
		Try
			DataLock.Lock();
		Except
			// Adding the record to the unsuccessful lock attempt result
			Error = NStr("en = 'Cannot lock the %1 set'");
			Error = StrReplace(Error, "%1", DataPresentation);
			
			ActionState = "LockError";
		EndTry;
		
	EndIf;	// Need of locking
		
	If ActionState = "" Then
		RecordSet.Read();
		ReplaceInRowCollection(RecordSet, SetDescription.FieldList, ReplacementCouples);
		
		If RecordSet.Modified() Then
			// Attempting to save
			If NOT WriteParameters.WriteInPrivilegedMode Then
				SetPrivilegedMode(False);
			EndIf;
			
			Try
				WriteObject(RecordSet, WriteParameters);
			Except
				// Saving the cause
				Information = ErrorInfo();
				WriteLogEvent(ReferenceReplacementEventLogMessageText(),
					EventLogLevel.Error, Meta, DetailErrorDescription(Information));
					
				ErrorDescription = BriefErrorDescription(Information);
				If IsBlankString(ErrorDescription) Then
					ErrorDescription = Information.Details;
				EndIf;
				
				// Adding a record to the record error result
				Error = NStr("en = 'Cannot write %1 by the following reason: %2'");
				Error = StrReplace(Error, "%1", DataPresentation);
				Error = StrReplace(Error, "%2", ErrorDescription);
				
				For Each Row In RowsToProcess Do
					AddReplacementResult(Results, Row.Ref, 
						ReplacementErrorDetails("WritingError", Data, DataPresentation, Error)
					);
				EndDo;
				
				ActionState = "WritingError";
			EndTry;
			
			If NOT WriteParameters.WriteInPrivilegedMode Then
				SetPrivilegedMode(True);
			EndIf;
			
		EndIf;
	EndIf;
	
	If InnerTransaction Then
		If ActionState = "" Then
			CommitTransaction();
		Else
			RollbackTransaction();
		EndIf;
	EndIf;
	
	// Marking as processed
	For Each Row In RowsToProcess Do
		Row.ReplacementKey = "";
	EndDo;
	
EndProcedure

Function ModifiedObjectsOnReplaceInObject(Val Data, Val RowsToProcess, Val RegisterRecordDescription, Val SequenceDescription)
	SetPrivilegedMode(True);
	
	// Returning modified processed objects
	Modified = New Map;
	
	// Reading
	Details = ObjectDescription(Data.Metadata());
	Try
		Object = Data.GetObject();
	Except
		// Already processed with errors
		Object = Undefined;
	EndTry;
	
	If Object = Undefined Then
		Return Modified;
	EndIf;
	
	For Each RegisterRecordDescription In RegisterRecordDescription Do
		RegisterRecordDescription.RecordSet.Filter.Recorder.Set(Data);
		RegisterRecordDescription.RecordSet.Read();
	EndDo;
	
	For Each SequenceDescription In SequenceDescription Do
		SequenceDescription.RecordSet.Filter.Recorder.Set(Data);
		SequenceDescription.RecordSet.Read();
	EndDo;
	
	// Replacing all at once
	ReplacementCouples = New Map;
	For Each UsageInstance In RowsToProcess Do
		ReplacementCouples.Insert(UsageInstance.Ref, UsageInstance.DestinationRef);
	EndDo;
	
	// Attributes
	For Each KeyValue In Details.Attributes Do
		Name = KeyValue.Key;
		DestinationRef = ReplacementCouples[ Object[Name] ];
		If DestinationRef <> Undefined Then
			Object[Name] = DestinationRef;
		EndIf;
	EndDo;
		
	// Standard attributes
	For Each KeyValue In Details.StandardAttributes Do
		Name = KeyValue.Key;
		DestinationRef = ReplacementCouples[ Object[Name] ];
		If DestinationRef <> Undefined Then
			Object[Name] = DestinationRef;
		EndIf;
	EndDo;
		
	// Tabular sections
	For Each Item In Details.TabularSections Do
		ReplaceInRowCollection(Object[Item.Name], Item.FieldList, ReplacementCouples);
	EndDo;
	
	// Standard tabular section
	For Each Item In Details.StandardTabularSections Do
		ReplaceInRowCollection(Object[Item.Name], Item.FieldList, ReplacementCouples);
	EndDo;
		
	// RegisterRecords
	For Each RegisterRecordDescription In RegisterRecordDescription Do
		ReplaceInRowCollection(RegisterRecordDescription.RecordSet, RegisterRecordDescription.FieldList, ReplacementCouples);
	EndDo;
	
	// Sequences
	For Each SequenceDescription In SequenceDescription Do
		ReplaceInRowCollection(SequenceDescription.RecordSet, SequenceDescription.FieldList, ReplacementCouples);
	EndDo;
	
	For Each RegisterRecordDescription In RegisterRecordDescription Do
		If RegisterRecordDescription.RecordSet.Modified() Then
			Modified.Insert(RegisterRecordDescription.RecordSet, False);
		EndIf;
	EndDo;
	
	For Each SequenceDescription In SequenceDescription Do
		If SequenceDescription.RecordSet.Modified() Then
			Modified.Insert(SequenceDescription.RecordSet, False);
		EndIf;
	EndDo;
	
	// The object is last - to provide posting if necessary
	If Object.Modified() Then
		Modified.Insert(Object, Details.CanBePosted);
	EndIf;
	
	Return Modified;
EndFunction

Procedure DeleteReferencesWithMark(DeletionResult, Val ReferenceList, Val WriteParameters, Val InnerTransaction = True)
	
	DeleteReferencesNotExclusive(DeletionResult, ReferenceList, WriteParameters, InnerTransaction, False);
	
EndProcedure

Procedure DeleteReferencesDirectly(DeletionResult, Val ReferenceList, Val WriteParameters, Val InnerTransaction = True)
	
	DeleteReferencesNotExclusive(DeletionResult, ReferenceList, WriteParameters, InnerTransaction, True);
	
EndProcedure

Procedure DeleteReferencesNotExclusive(DeletionResult, Val ReferenceList, Val WriteParameters, Val InnerTransaction, Val DeleteDirectly)
	
	SetPrivilegedMode(True);
	
	ToDelete = New Array;
	
	If InnerTransaction Then
		BeginTransaction();
	EndIf;
		
	For Each Ref In ReferenceList Do
		DataLock = New DataLock;
		DataLock.Add(Ref.Metadata().FullName()).SetValue("Ref", Ref);
		
		RefPresentation = String(Ref);
		
		Try 
			DataLock.Lock();
			ToDelete.Add(Ref);
		Except
			AddReplacementResult(DeletionResult, Ref, 
				ReplacementErrorDetails("LockError", Ref, RefPresentation, NStr("en = 'Cannot lock the reference for deletion'"))
			);
		EndTry
	EndDo;
		
	SearchTable = UsageInstances(ToDelete);
	Filter = New Structure("Ref");
	
	For Each Ref In ToDelete Do
		RefPresentation = String(Ref);
		
		Filter.Ref = Ref;
		UsageInstances = SearchTable.FindRows(Filter);
		
		Index = UsageInstances.UBound();
		While Index >= 0 Do
			If UsageInstances[Index].AuxiliaryData Then
				UsageInstances.Delete(Index);
			EndIf;
			Index = Index - 1;
		EndDo;
		
		If UsageInstances.Count() > 0 Then
			// Was modified, cannot be deleted
			AddModifiedObjectReplacementResults(DeletionResult, UsageInstances);
			Continue;
		EndIf;
		
		Object = Ref.GetObject();
		If Object = Undefined Then
			// Already deleted
			Continue;
		EndIf;
			
		If NOT WriteParameters.WriteInPrivilegedMode Then
			SetPrivilegedMode(False);
		EndIf;
			
		Try
			If DeleteDirectly Then
				HandleObjectWithMessageInterception(Object, "DirectDeletion", Undefined, WriteParameters);
			Else
				HandleObjectWithMessageInterception(Object, "DeletionMark", Undefined, WriteParameters);
			EndIf;
		Except
			ErrorInfo = ErrorInfo();
			AddReplacementResult(DeletionResult, Ref, 
				ReplacementErrorDetails("DeletionError", Ref, RefPresentation,
				NStr("en = 'Deletion error'") + Chars.LF + TrimAll( BriefErrorDescription(ErrorInfo)))
			);
		EndTry;
			
		If NOT WriteParameters.WriteInPrivilegedMode Then
			SetPrivilegedMode(True);
		EndIf;
	EndDo;
	
	If InnerTransaction Then
		CommitTransaction();
	EndIf;
EndProcedure

Procedure AddModifiedObjectReplacementResults(ResultTable, RepeatSearchTable)
	
	RecordKeyType = RecordKeysTypeDescription();
	
	Filter = New Structure("ErrorType, Ref, ErrorObject", "");
	For Each Row In RepeatSearchTable Do
		Test = New Structure("AuxiliaryData", False);
		FillPropertyValues(Test, Row);
		If Test.AuxiliaryData Then
			Continue;
		EndIf;
		
		Data = Row.Data;
		Ref  = Row.Ref;
		
		DataPresentation = String(Data);
		
		Filter.ErrorObject = Data;
		Filter.Ref         = Ref;
		If ResultTable.FindRows(Filter).Count() = 0 Then
			AddReplacementResult(ResultTable, Ref, 
				ReplacementErrorDetails("DataChanged", Data, DataPresentation,
				NStr("en = 'Data were added or changed by another user'"))
			);
		EndIf;
	EndDo;
	
EndProcedure

Function SetDimensionDescription(Val Meta, Cache)
	
	DimensionDescription = Cache[Meta];
	If DimensionDescription<>Undefined Then
		Return DimensionDescription;
	EndIf;
	
	// Period and recorder, if there are
	DimensionDescription = New Structure;
	
	DataDimensions = New Structure("Master, Presentation, Format, Type", False);
	
	If Metadata.InformationRegisters.Contains(Meta) Then
		// Perhaps there is a period
		MetaPeriod  = Meta.InformationRegisterPeriodicity; 
		Periodicity = Metadata.ObjectProperties.InformationRegisterPeriodicity;
		
		If MetaPeriod = Periodicity.RecorderPosition Then
			DataDimensions.Type         = Documents.AllRefsType();
			DataDimensions.Presentation = NStr("en='Recorder'");
			DataDimensions.Master       = True;
			DimensionDescription.Insert("Recorder", DataDimensions);
			
		ElsIf MetaPeriod = Periodicity.Year Then
			DataDimensions.Type         = New TypeDescription("Date");
			DataDimensions.Presentation = NStr("en='Period'");
			DataDimensions.Format       = "L=en_US; DF='yyyy'; DE='Date not set'";
			DimensionDescription.Insert("Period", DataDimensions);
			
		ElsIf MetaPeriod = Periodicity.Day Then
			DataDimensions.Type           = New TypeDescription("Date");
			DataDimensions.Presentation = NStr("en='Period'");
			DataDimensions.Format        = "L=en_US; DLF=D; DE='Date not set'";
			DimensionDescription.Insert("Period", DataDimensions);
			
		ElsIf MetaPeriod = Periodicity.Quarter Then
			DataDimensions.Type         = New TypeDescription("Date");
			DataDimensions.Presentation = NStr("en='Period'");
			DataDimensions.Format       = "L=en_US; DF='""""quarter """" K """" of """" yyyy'; DE='Date not set'";
			DimensionDescription.Insert("Period", DataDimensions);
			
		ElsIf MetaPeriod = Periodicity.Month Then
			DataDimensions.Type         = New TypeDescription("Date");
			DataDimensions.Presentation = NStr("en='Period'");
			DataDimensions.Format       = "L=en_US; DF='MMMM yyyy'; DE='Date not set'";
			DimensionDescription.Insert("Period", DataDimensions);
			
		ElsIf MetaPeriod = Periodicity.Second Then
			DataDimensions.Type         = New TypeDescription("Date");
			DataDimensions.Presentation = NStr("en='Period'");
			DataDimensions.Format       = "L=en_US; DLF=DT; DE='Date not set'";
			DimensionDescription.Insert("Period", DataDimensions);
			
		EndIf;
		
	Else
		DataDimensions.Type         = Documents.AllRefsType();
		DataDimensions.Presentation = NStr("en='Recorder'");
		DataDimensions.Master       = True;
		DimensionDescription.Insert("Recorder", DataDimensions);
		
	EndIf;
	
	// All dimensions
	For Each MetaDimension In Meta.Dimensions Do
		DataDimensions = New Structure("Master, Presentation, Format, Type");
		DataDimensions.Type         = MetaDimension.Type;
		DataDimensions.Presentation = MetaDimension.Presentation();
		DataDimensions.Master       = MetaDimension.Master;
		DimensionDescription.Insert(MetaDimension.Name, DataDimensions);
	EndDo;
	
	Cache[Meta] = DimensionDescription;
	Return DimensionDescription;
EndFunction

Function RegisterRecordDescription(Val Meta)
	// can be cached by Meta
	
	RegisterRecordDescription = New Array;
	If Not Metadata.Documents.Contains(Meta) Then
		Return RegisterRecordDescription;
	EndIf;
	
	For Each RegisterRecord In Meta.RegisterRecords Do
		
		If Metadata.AccumulationRegisters.Contains(RegisterRecord) Then
			RecordSet = AccumulationRegisters[RegisterRecord.Name].CreateRecordSet();
			ExcludeFields = "Active, LineNumber, Period, Recorder"; 
			
		ElsIf Metadata.InformationRegisters.Contains(RegisterRecord) Then
			RecordSet = InformationRegisters[RegisterRecord.Name].CreateRecordSet();
			ExcludeFields = "Active, RecordType, LineNumber, Period, Recorder"; 
			
		ElsIf Metadata.AccountingRegisters.Contains(RegisterRecord) Then
			RecordSet = AccountingRegisters[RegisterRecord.Name].CreateRecordSet();
			ExcludeFields = "Active, RecordType, LineNumber, Period, Recorder"; 
			
		ElsIf Metadata.CalculationRegisters.Contains(RegisterRecord) Then
			RecordSet = CalculationRegisters[RegisterRecord.Name].CreateRecordSet();
			ExcludeFields = "Active, EndOfBasePeriod, BegOfBasePeriod, LineNumber, ActionPeriod, EndOfActionPeriod, BegOfActionPeriod, RegistrationPeriod, Recorder, ReversingEntry, ActualActionPeriod";
		Else
			// Unknown type
			Continue;
		EndIf;
		
		// Fields of reference types and dimensions are candidates
		Details = FieldListsByType(RecordSet, RegisterRecord.Dimensions, ExcludeFields);
		If Details.FieldList.Count() = 0 Then
			// No need to handle
			Continue;
		EndIf;
		
		Details.Insert("RecordSet", RecordSet);
		Details.Insert("LockSpace", RegisterRecord.FullName() );
		
		RegisterRecordDescription.Add(Details);
	EndDo; // Register record metadata
	
	Return RegisterRecordDescription;
EndFunction

Function SequenceDescription(Val Meta)
	
	SequenceDescription = New Array;
	If NOT Metadata.Documents.Contains(Meta) Then
		Return SequenceDescription;
	EndIf;
	
	For Each Sequence In Metadata.Sequences Do
		If NOT Sequence.Documents.Contains(Meta) Then
			Continue;
		EndIf;
		
		TableName = Sequence.FullName();
		
		// List of fields and dimensions
		Details = FieldListsByType(TableName, Sequence.Dimensions, "Recorder");
		If Details.FieldList.Count() > 0 Then
			
			Details.Insert("RecordSet",  Sequences[Sequence.Name].CreateRecordSet());
			Details.Insert("LockSpace",  TableName + ".Records");
			Details.Insert("Dimensions", New Structure);
			
			SequenceDescription.Add(Details);
		EndIf;
		
	EndDo;
	
	Return SequenceDescription;
EndFunction

Function ObjectDescription(Val Meta)
	// can be cached by Meta
	
	AllRefsType = AllRefsTypeDescription();
	
	Candidates = New Structure("Attributes, StandardAttributes, TabularSections, StandardTabularSections");
	FillPropertyValues(Candidates, Meta);
	
	ObjectDescription = New Structure;
	
	ObjectDescription.Insert("Attributes", New Structure);
	If Candidates.Attributes <> Undefined Then
		For Each MetaAttribute In Candidates.Attributes Do
			If DescriptionTypesIntersect(MetaAttribute.Type, AllRefsType) Then
				ObjectDescription.Attributes.Insert(MetaAttribute.Name);
			EndIf;
		EndDo;
	EndIf;
	
	ObjectDescription.Insert("StandardAttributes", New Structure);
	If Candidates.StandardAttributes <> Undefined Then
		ToExclude = New Structure("Ref");
		
		For Each MetaAttribute In Candidates.StandardAttributes Do
			Name = MetaAttribute.Name;
			If Not ToExclude.Property(Name) AND DescriptionTypesIntersect(MetaAttribute.Type, AllRefsType) Then
				ObjectDescription.Attributes.Insert(MetaAttribute.Name);
			EndIf;
		EndDo;
	EndIf;
	
	ObjectDescription.Insert("TabularSections", New Array);
	If Candidates.TabularSections <> Undefined Then
		For Each MetaTable In Candidates.TabularSections Do
			
			FieldList = New Structure;
			For Each MetaAttribute In MetaTable.Attributes Do
				If DescriptionTypesIntersect(MetaAttribute.Type, AllRefsType) Then
					FieldList.Insert(MetaAttribute.Name);
				EndIf;
			EndDo;
			
			If FieldList.Count() > 0 Then
				ObjectDescription.TabularSections.Add(New Structure("Name, FieldList", MetaTable.Name, FieldList));
			EndIf;
		EndDo;
	EndIf;
	
	ObjectDescription.Insert("StandardTabularSections", New Array);
	If Candidates.StandardTabularSections <> Undefined Then
		For Each MetaTable In Candidates.StandardTabularSections Do
			
			FieldList = New Structure;
			For Each MetaAttribute In MetaTable.StandardAttributes Do
				If DescriptionTypesIntersect(MetaAttribute.Type, AllRefsType) Then
					FieldList.Insert(MetaAttribute.Name);
				EndIf;
			EndDo;
			
			If FieldList.Count() > 0 Then
				ObjectDescription.StandardTabularSections.Add(New Structure("Name, FieldList", MetaTable.Name, FieldList));
			EndIf;
		EndDo;
	EndIf;
	
	ObjectDescription.Insert("CanBePosted", Metadata.Documents.Contains(Meta));
	Return ObjectDescription;
EndFunction

Function RecordKeyDescription(Val Meta)
	// can be cached by Meta
	
	TableName = Meta.FullName();
	
	// Fields of reference types are candidates and a dimension set
	KeyDescription = FieldListsByType(TableName, Meta.Dimensions, "Period, Recorder");
		
	If Metadata.InformationRegisters.Contains(Meta) Then
		RecordSet = InformationRegisters[Meta.Name].CreateRecordSet();
		
	ElsIf Metadata.AccumulationRegisters.Contains(Meta) Then
		RecordSet = AccumulationRegisters[Meta.Name].CreateRecordSet();
		
	ElsIf Metadata.AccountingRegisters.Contains(Meta) Then
		RecordSet = AccountingRegisters[Meta.Name].CreateRecordSet();
		
	ElsIf Metadata.CalculationRegisters.Contains(Meta) Then
		RecordSet = CalculationRegisters[Meta.Name].CreateRecordSet();
		
	Else
		RecordSet = Undefined;
	EndIf;
		
	KeyDescription.Insert("RecordSet", RecordSet);
	KeyDescription.Insert("LockSpace", TableName);

	Return KeyDescription;
EndFunction

Function LockListDescription(Val DataLock)
	// Unique values only
	ProcessedItems = New Map;
	
	DescriptionString = "";
	For Each Item In DataLock Do
		For Each Field In Item.Fields Do
			Value = Field.Value;
			If ProcessedItems[Value] = Undefined Then
				DescriptionString = DescriptionString + Chars.LF + Field.Value;
				ProcessedItems[Value] = True;
			EndIf
		EndDo;
	EndDo;
	
	Return TrimL(DescriptionString);
EndFunction

Function DescriptionTypesIntersect(Val Description1, Val Description2)
	
	For Each Type In Description1.Types() Do
		If Description2.ContainsType(Type) Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
EndFunction

// Returns a description by the table name or by the record set
Function FieldListsByType(Val DataSource , Val MetaDimensions, Val ExcludeFields)
	// can be cached
	
	Details = New Structure;
	Details.Insert("FieldList",           New Structure);
	Details.Insert("MeasurementList",     New Structure);
	Details.Insert("MasterDimentionList", New Structure);
	
	ControlType = AllRefsTypeDescription();
	ToExclude = New Structure(ExcludeFields);
	
	DataSourceType = TypeOf(DataSource);
	
	If DataSourceType = Type("String") Then
		// Table name is a source, getting fields with query
		Query = New Query("SELECT * FROM " + DataSource + " WHERE FALSE");
		FieldSource = Query.Execute();
	Else
		// Record set is a source
		FieldSource = DataSource.UnloadColumns();
	EndIf;
	
	For Each Column In FieldSource.Columns Do
		Name = Column.Name;
		If Not ToExclude.Property(Name) AND DescriptionTypesIntersect(Column.ValueType, ControlType) Then
			Details.FieldList.Insert(Name);
			
			// Checking for a master dimension
			Meta = MetaDimensions.Find(Name);
			If Meta <> Undefined Then
				Details.MeasurementList.Insert(Name, Meta.Type);
				Test = New Structure("Master", False);
				FillPropertyValues(Test, Meta);
				If Test.Master Then
					Details.MasterDimentionList.Insert(Name, Meta.Type);
				EndIf;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return Details;
EndFunction

Procedure AddReplacementResult(Table, Val Ref, Val ErrorDescription)
	Row = Table.Add();
	
	Row.Ref = Ref;
	
	Row.ErrorObjectPresentation = ErrorDescription.ErrorObjectPresentation;
	Row.ErrorObject             = ErrorDescription.ErrorObject;
	Row.ErrorText               = ErrorDescription.ErrorText;
	Row.ErrorObject             = ErrorDescription.ErrorObject;
	
EndProcedure

Function ReplacementErrorDetails(Val ErrorType, Val ErrorObject, Val ErrorObjectPresentation, Val ErrorText)
	Result = New Structure;
	
	Result.Insert("ErrorType",               ErrorType);
	Result.Insert("ErrorObject",             ErrorObject);
	Result.Insert("ErrorObjectPresentation", ErrorObjectPresentation);
	Result.Insert("ErrorText",               ErrorText);
	
	Return Result;
EndFunction

Procedure ReplaceInRowCollection(Collection, Val FieldList, Val ReplacementCouples)
	WorkingCollection = Collection.Unload();
	Modified = False;
	
	For Each Row In WorkingCollection Do
		
		For Each KeyValue In FieldList Do
			Name = KeyValue.Key;
			DestinationRef = ReplacementCouples[ Row[Name] ];
			If DestinationRef <> Undefined Then
				Row[Name] = DestinationRef;
				Modified = True;
			EndIf;
		EndDo;
		
	EndDo;
	
	If Modified Then
		Collection.Load(WorkingCollection);
	EndIf;
EndProcedure

Procedure ReportDeferredMessages(Val Messages)
	
	For Each Message In Messages Do
		Message.Message();
	EndDo;
	
EndProcedure

Procedure HandleObjectWithMessageInterception(Val Object, Val Action, Val WriteMode, Val WriteParameters)
	
	// Saving the current messages before the exceptions
	PreviousMessages = GetUserMessages(True);
	ReportRepeatedly = CurrentRunMode() <> Undefined;
	
	Try
		
		If Action = "Write" Then
			SetWritingParameters(Object, WriteParameters);
			If WriteMode = Undefined Then
				Object.Write();
			Else
				Object.Write(WriteMode);
			EndIf;
			
		ElsIf Action = "DeletionMark" Then
			SetWritingParameters(Object, WriteParameters);
			Object.SetDeletionMark(True, False);
			
		ElsIf Action = "DirectDeletion" Then
			SetWritingParameters(Object, WriteParameters);
			Object.Delete();
			
		EndIf;
		
	Except
		Information = ErrorInfo(); 
		
		// Intercepting all reported error messages and adding them to a single exception
		ErrorMessage = "";
		For Each Message In GetUserMessages(False) Do
			ErrorMessage = ErrorMessage + Chars.LF + Message.Text;
		EndDo;
		
		// Reporting the previous message
		If ReportRepeatedly Then
			ReportDeferredMessages(PreviousMessages);
		EndIf;
		
		// Exiting
		If IsBlankString(ErrorMessage) Then
			Raise;
		EndIf;
		
		Raise TrimAll(BriefErrorDescription(Information) + Chars.LF + TrimAll(ErrorMessage));
	EndTry;
	
	If ReportRepeatedly Then
		ReportDeferredMessages(PreviousMessages);
	EndIf;
	
EndProcedure

Procedure WriteObject(Val Object, Val WriteParameters)
	
	ObjectMetadata = Object.Metadata();
	
	If IsDocument(ObjectMetadata) Then
		HandleObjectWithMessageInterception(Object, "Write", DocumentWriteMode.Write, WriteParameters);
		Return;
	EndIf;
	
	// Checking for loop references
	AttributeTest= New Structure("Hierarchical, ExtDimensionTypes, Owners", False, Undefined, New Array);
	FillPropertyValues(AttributeTest, ObjectMetadata);
	
	// By parent
	If AttributeTest.Hierarchical Or AttributeTest.ExtDimensionTypes <> Undefined Then 
		
		If Object.Parent = Object.Ref Then
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'When writing %1 a loop reference occurs in hierarchy.'"),
				String(Object));
			EndIf;
			
	EndIf;
	
	// By owner
	For Each MetaOwner In AttributeTest.Owners Do
		
		If Object.Owner = Object.Ref Then
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'When writing %1 a loop reference occurs in subordination.'"),
				String(Object));
		EndIf;
		Break;
		
	EndDo;
	
	// Just writing
	HandleObjectWithMessageInterception(Object, "Write", Undefined, WriteParameters);
EndProcedure

Procedure SetWritingParameters(Object, Val WriteParameters)
	
	AttributeTest = New Structure("DataExchange");
	FillPropertyValues(AttributeTest, Object);
	If TypeOf(AttributeTest.DataExchange) = Type("DataExchangeParameters") Then
		Object.DataExchange.Load = WriteParameters.DontCheck;
		Object.DataExchange.Recipients.AutoFill = Not WriteParameters.DontCheck;
	EndIf;
	
	Object.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism", WriteParameters.DontCheck);
	
EndProcedure

Function ReferenceReplacementEventLogMessageText()
	Return NStr("en='Reference search and deletion'", 
		Metadata.DefaultLanguage.LanguageCode);
EndFunction


Procedure ReplaceReferenceInShortTransactions(ReplacementResult, Val ReplacementParameters, Val ReplacementToProcess, Val SearchTable)
	
	// Main data processor loop
	WriteParameters = New Structure;
	WriteParameters.Insert("DontCheck", Not ReplacementParameters.ControlOnWrite);
	WriteParameters.Insert("WriteInPrivilegedMode", ReplacementParameters.WriteInPrivilegedMode);
	
	ReferenceFilter = New Structure("Ref, ReplacementKey");
	For Each Ref In ReplacementToProcess Do
		ReferenceFilter.Ref = Ref;
		
		ReferenceFilter.ReplacementKey = "Constant";
		UsageInstances = SearchTable.FindRows(ReferenceFilter);
		For Each UsageInstance In UsageInstances Do
			ReplaceInConstant(ReplacementResult, UsageInstance, WriteParameters);
		EndDo;
		
		ReferenceFilter.ReplacementKey = "Object";
		UsageInstances = SearchTable.FindRows(ReferenceFilter);
		For Each UsageInstance In UsageInstances Do
			ReplaceInObject(ReplacementResult, UsageInstance, WriteParameters);
		EndDo;
		
		ReferenceFilter.ReplacementKey = "RecordKey";
		UsageInstances = SearchTable.FindRows(ReferenceFilter);
		For Each UsageInstance In UsageInstances Do
			ReplaceInSet(ReplacementResult, UsageInstance, WriteParameters);
		EndDo;
	EndDo;
	
	// Final actions
	If ReplacementParameters.DeleteDirectly Then
		DeleteReferencesDirectly(ReplacementResult, ReplacementToProcess, WriteParameters, True);
		
	ElsIf ReplacementParameters.MarkForDeletion Then
		DeleteReferencesWithMark(ReplacementResult, ReplacementToProcess, WriteParameters);
		
	Else 
		// Searching for new items
		RepeatSearchTable = UsageInstances(ReplacementToProcess);
		AddModifiedObjectReplacementResults(ReplacementResult, RepeatSearchTable);
	EndIf;
		
EndProcedure

Procedure ReplaceReferenceInLongTransaction(ReplacementResult, Val Ref, Val ReplacementParameters, Val SearchTable)
	SetPrivilegedMode(True);
	
	WriteParameters = New Structure;
	WriteParameters.Insert("DontCheck", Not ReplacementParameters.ControlOnWrite);
	WriteParameters.Insert("WriteInPrivilegedMode", ReplacementParameters.WriteInPrivilegedMode);
	
	ActionState = "";
	
	// 1. Locking all usage instances
	DataLock = New DataLock;
	
	UsageInstancesConstants = SearchTable.FindRows(New Structure("Ref, ReplacementKey", Ref, "Constant"));
	AddObjectsLockConstants(DataLock, UsageInstancesConstants);
	
	UsageInstancesObjects = SearchTable.FindRows(New Structure("Ref, ReplacementKey", Ref, "Object"));
	AddLockObjectsObjects(DataLock, UsageInstancesObjects);
	
	UsageInstancesSets = SearchTable.FindRows(New Structure("Ref, ReplacementKey", Ref, "RecordKey"));
	AddLockObjectsSets(DataLock, UsageInstancesSets);
		
	BeginTransaction();
	Try
		DataLock.Lock();
	Except
		// Adding the record to the unsuccessful lock attempt result
		Error = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Cannot lock all usage instances of %1'"),
			Ref
		);
		AddReplacementResult(ReplacementResult, Ref, 
			ReplacementErrorDetails("LockError", Undefined, Undefined, Error)
		);
	
		ActionState = "LockError";
	EndTry;
	
	SetPrivilegedMode(False);
	
	// 2. Replacing everywhere
	If ActionState = "" Then
		ErrorsCount = ReplacementResult.Count();
		
		For Each UsageInstance In UsageInstancesConstants Do
			ReplaceInConstant(ReplacementResult, UsageInstance, WriteParameters, False);
		EndDo;
		
		For Each UsageInstance In UsageInstancesObjects Do
			ReplaceInObject(ReplacementResult, UsageInstance, WriteParameters, False);
		EndDo;
		
		For Each UsageInstance In UsageInstancesSets Do
			ReplaceInSet(ReplacementResult, UsageInstance, WriteParameters, False);
		EndDo;
		
		If ErrorsCount <> ReplacementResult.Count() Then
			ActionState = "WritingError";
		EndIf;
	EndIf;
	
	// 3. Delete 
	ReplacementToProcess = New Array;
	ReplacementToProcess.Add(Ref);
	
	If ActionState = "" Then
		ErrorsCount = ReplacementResult.Count();
		
		If ReplacementParameters.DeleteDirectly Then
			DeleteReferencesDirectly(ReplacementResult, ReplacementToProcess, WriteParameters, False);
			
		ElsIf ReplacementParameters.MarkForDeletion Then
			DeleteReferencesWithMark(ReplacementResult, ReplacementToProcess, WriteParameters, False);
			
		Else 
			// Searching for new items
			RepeatSearchTable = UsageInstances(ReplacementToProcess);
			AddModifiedObjectReplacementResults(ReplacementResult, RepeatSearchTable);
		EndIf;
		
		If ErrorsCount <> ReplacementResult.Count() Then
			ActionState = "DataChanged";
		EndIf;
	EndIf;
	
	If ActionState = "" Then
		CommitTransaction();
	Else
		RollbackTransaction();
	EndIf;
	
EndProcedure
	
Procedure AddObjectsLockConstants(DataLock, Val UsageRows)
	
	For Each Row In UsageRows Do
		DataLock.Add(Row.Metadata.FullName());
	EndDo;
	
EndProcedure


Procedure AddLockObjectsObjects(DataLock, Val UsageRows)
	
	For Each UsageInstance In UsageRows Do
		Data = UsageInstance.Data;
		Meta = UsageInstance.Metadata;
		
		// The item
		DataLock.Add(Meta.FullName()).SetValue("Ref", Data);
		
		// RegisterRecords 
		RegisterRecordDescription = RegisterRecordDescription(Meta);
		For Each Item In RegisterRecordDescription Do
			// Everything by the recorder
			DataLock.Add(Item.LockSpace + ".RecordSet").SetValue("Recorder", Data);
			
			// All candidates are dimensions for saving the results
			For Each KeyValue In Item.MeasurementList Do
				DimensionType = KeyValue.Value;
				For Each UsageInstance In UsageRows Do
					CurrentRef = UsageInstance.Ref;
					If DimensionType.ContainsType(TypeOf(CurrentRef)) Then
						DataLock.Add(Item.LockSpace).SetValue(KeyValue.Key, UsageInstance.Ref);
					EndIf;
				EndDo;
			EndDo;
		EndDo;
		
		// Sequences
		SequenceDescription = SequenceDescription(Meta);
		For Each Item In SequenceDescription Do
			DataLock.Add(Item.LockSpace).SetValue("Recorder", Data);
			
			For Each KeyValue In Item.MeasurementList Do
				DimensionType = KeyValue.Value;
				For Each UsageInstance In UsageRows Do
					CurrentRef = UsageInstance.Ref;
					If DimensionType.ContainsType(TypeOf(CurrentRef)) Then
						DataLock.Add(Item.LockSpace).SetValue(KeyValue.Key, CurrentRef);
					EndIf;
				EndDo;
			EndDo;
		EndDo;
	
	EndDo;

EndProcedure


Procedure AddLockObjectsSets(DataLock, Val UsageRows)
	
	For Each UsageInstance In UsageRows Do
		Data = UsageInstance.Data;
		Meta = UsageInstance.Metadata; 
		
		SetDescription = RecordKeyDescription(Meta);
		RecordSet = SetDescription.RecordSet;
		
		For Each KeyValue In SetDescription.MeasurementList Do
			DimensionType = KeyValue.Value;
			Name          = KeyValue.Key;
			Value         = Data[Name];
			
			For Each Row In UsageRows Do
				CurrentRef = Row.Ref;
				If DimensionType.ContainsType(TypeOf(CurrentRef)) Then
					DataLock.Add(SetDescription.LockSpace).SetValue(Name, CurrentRef);
				EndIf;
			EndDo;
			
			RecordSet.Filter[Name].Set(Value);
		EndDo;
		
	EndDo;
	
EndProcedure

Function EvaluateDataValueByPath(Val Data, Val DataPath)
	PathParts = StrReplace(DataPath, ".", Chars.LF);
	PathPartCount = StrLineCount(PathParts);
	
	InterimResult = Data;
	
	For Index = 1 To PathPartCount Do
		AttributeName = StrGetLine(PathParts, Index);
		
		Test = New Structure(AttributeName, Undefined);
		FillPropertyValues(Test, InterimResult);
		If Test[AttributeName] = Undefined Then
			Test[AttributeName] = -1;
			FillPropertyValues(Test, InterimResult);
			If Test[AttributeName] = Undefined Then
				Raise StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en='Cannot evaluate %1 for the %2 object. The %3 attribute is not found.'"),
					DataPath, Data, AttributeName 
				);
			EndIf;
		EndIf;
		
		Result = Test[AttributeName];
		If Index = PathPartCount Then
			Return Result;
			
		ElsIf Result = Undefined Then
			// No need to continue evaluation
			Return Undefined;
			
		EndIf;
		
		InterimResult = Result;
	EndDo;
	
	Return Undefined;
EndFunction

// Internal. Starts background jobs during reference replacement.
Procedure InstanceCountCalculatingInBackground(Val ReferenceSet, Val ResultAddress) Export
	
	SearchTable = UsageInstances(ReferenceSet);
	
	Filter = New Structure("AuxiliaryData", False);
	ActualRows = SearchTable.FindRows(Filter);
	
	Result = SearchTable.Copy(ActualRows, "Ref");
	Result.Columns.Add("Entries", New TypeDescription("Number"));
	Result.FillValues(1, "Entries");
	
	Result.Collapse("Ref", "Entries");
	For Each Ref In ReferenceSet Do
		If Result.Find(Ref, "Ref") = Undefined Then
			Result.Add().Ref = Ref;
		EndIf;
	EndDo;
	
	PutToTempStorage(Result, ResultAddress);
EndProcedure


// See. DataProcessor.SearchAndDeletionOfDuplicates
Function AvailableFilterMetaAttributeNames(Val MetaCollection)
	Result = "";
	StoreType = Type("ValueStorage");
	
	For Each MetaAttribute In MetaCollection Do
		IsStorage = MetaAttribute.Type.ContainsType(StoreType);
		If Not IsStorage Then
			Result = Result + "," + MetaAttribute.Name;
		EndIf
	EndDo;
	
	Return Result;
EndFunction

#EndRegion
