#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region InternalInterface
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Fills the list of all areas available for searching for duplicates.
//
// Parameters:
//  List                - ValueList - list to be filled. Contains:
//                         Value        - String - full name of the table object metadata.
//                         Presentation - String - presentation for user.
//                         Picture      - Picture - corresponding picture from the platform
//                                        library.
//                         Check        - Boolean - flag that shows whether there are applied
//                                        rules for searching  for duplicates. Is set to True 
//                                        only if the second parameter is True.
//
//  AnalyzeAppliedRules - Boolean - flag that shows whether the applied rules of search for 
//                        duplicates must be found.
//
Procedure AreasToSearchForDuplicates(List, Val AnalyzeAppliedRules = False) Export
	
	List.Clear();
	
	SearchForDuplicatesAreaGroup(List, AnalyzeAppliedRules, Catalogs,                    "Catalog");
	SearchForDuplicatesAreaGroup(List, AnalyzeAppliedRules, ChartsOfCharacteristicTypes, "ChartOfCharacteristicTypes");
	SearchForDuplicatesAreaGroup(List, AnalyzeAppliedRules, ChartsOfAccounts,            "ChartOfAccounts");
	SearchForDuplicatesAreaGroup(List, AnalyzeAppliedRules, ChartsOfCalculationTypes,    "ChartOfCalculationTypes");

EndProcedure

// Defines the object manager for calling the applied rules.
//
// Parameters:
//     DataSearchAreaName - String - area name (full metadata name).
//
// Returns:
//  CatalogsManager, ChartsOfCharacteristicTypes.Manager, ChartsOfAccounts.Manager,
//  ChartsOfCalculationTypes.Manager.
//
Function SearchForDuplicatesAreaManager(Val DataSearchAreaName) Export
	Meta = Metadata.FindByFullName(DataSearchAreaName);
	
	If Metadata.Catalogs.Contains(Meta) Then
		Return Catalogs[Meta.Name];
		
	ElsIf Metadata.ChartsOfCharacteristicTypes.Contains(Meta) Then
		Return ChartsOfCharacteristicTypes[Meta.Name];
		
	ElsIf Metadata.ChartsOfAccounts.Contains(Meta) Then
		Return ChartsOfAccounts[Meta.Name];
		
	ElsIf Metadata.ChartsOfCalculationTypes.Contains(Meta) Then
		Return ChartsOfCalculationTypes[Meta.Name];
		
	EndIf;
		
	Raise StrReplace(
		NStr("en = 'Unknown metadata object type: %1'"), 
		"%1", DataSearchAreaName
	);
	
EndFunction

// Default parameters to be passed to the applied script.
//
// Parameters:
//  SearchRules - ValueTable - proposed search rules, contains the following columns:
//                 Attribute - String - name of the search area attribute.
//                 Rule      - String - comparison rule ID. Can be Equal or Like.
//
// Returns:
//  Structure.
//
Function DefaultAppliedParameters(Val SearchRules, Val FilterComposer) Export

	DefaultParameters = New Structure;
	DefaultParameters.Insert("SearchRules",         SearchRules);
	DefaultParameters.Insert("CompareRestrictions", New Array);
	DefaultParameters.Insert("FilterComposer",      FilterComposer);
	DefaultParameters.Insert("ItemCountForCompare", 1000);
	
	Return DefaultParameters;
	
EndFunction

// Searches for duplicates in the background.
//
// Parameters:
//  Parameters    - Structure - data to be analyzed. 
//  ResultAddress - String - address in the temporary storage for saving the result.
//
Procedure BackgroundSearchForDuplicates(Val Parameters, Val ResultAddress) Export
	
	// Rebuilding the composer through the schema and the settings
	PrefilterComposer = New DataCompositionSettingsComposer;
	
	PrefilterComposer.Initialize( New DataCompositionAvailableSettingsSource(Parameters.CompositionSchema) );
	PrefilterComposer.LoadSettings(Parameters.PrefilterComposerSettings);
	
	Parameters.Insert("PrefilterComposer", PrefilterComposer);
	
	// Transforming the search rules into an indexed value table
	SearchRules = New ValueTable;
	SearchRules.Columns.Add("Attribute", New TypeDescription("String"));
	SearchRules.Columns.Add("Rule",      New TypeDescription("String"));
	SearchRules.Indexes.Add("Attribute");
	
	For Each Rule In Parameters.SearchRules Do
		FillPropertyValues(SearchRules.Add(), Rule);
	EndDo;
	Parameters.Insert("SearchRules", SearchRules);
	
	Parameters.Insert("CalculateWhereReferencesUsed", True);
	
	// Starting the search
	PutToTempStorage(DuplicateGroups(Parameters), ResultAddress);
EndProcedure

// Deletes duplicates in the background.
//
// Parameters:
//  Parameters    - Structure - data to be analyzed. 
//  ResultAddress - String - address in the temporary storage for saving the result.
//
Procedure BackgroundDuplicateDeletion(Val Parameters, Val ResultAddress) Export
	
	ReplacementParameters = New Structure;
	ReplacementParameters.Insert("DeletionMethod",        Parameters.DeletionMethod);
	ReplacementParameters.Insert("ConsiderBusinessLogic", True);
	
	ReplaceReferences(Parameters.ReplacementCouples, ReplacementParameters, ResultAddress);
	
EndProcedure

// Direct search for duplicates.
//
// Parameters:
//  SearchParameters - Structure - describes the search parameters.
//  SampleObject     - Arbitrary - object to be used for compare when searching for similar
//                     items. 
//
// Returns:
//  ValueTable - implementation of the value tree through Ref and Parent.
//               Groups are on the top level, found duplicates are on the bottom one.
//
Function DuplicateGroups(Val SearchParameters, Val SampleObject = Undefined) Export
	Var ReturnedPortionSize, CalculateWhereReferencesUsed;
	
	// 1. Determining parameters according to the applied script
	
	SearchParameters.Property("MaximumNumberOfDuplicates", ReturnedPortionSize);
	If Not ValueIsFilled(ReturnedPortionSize) Then
		// All found
		ReturnedPortionSize = 0;
	EndIf;
	
	If Not SearchParameters.Property("CalculateWhereReferencesUsed", CalculateWhereReferencesUsed) Then
		CalculateWhereReferencesUsed = False;
	EndIf;
		
	// For passing to the applied script
	AdditionalParameters = Undefined;
	SearchParameters.Property("AdditionalParameters", AdditionalParameters);
	
	// Calling the applied script
	SearchAreaManager = SearchForDuplicatesAreaManager(SearchParameters.AreaToSearchForDuplicates);
	UseAppliedRules = SearchParameters.TakeAppliedRulesIntoAccount And HasSearchForDuplicatesAreaAppliedRules(SearchAreaManager);
	
	EqualityCompareFields = ""; // Names of the attributes to be used for comparison by equality
	LikeCompareFields   = "";   // Names of the attributes that are used for fuzzy comparison 
	AdditionalDataFields = "";  // Names of the addition attributes defined with the applied rules
	AppliedPortionSize   = 0;   // Size of the data portion to be passed to the applied rules for calculating
	
	If UseAppliedRules Then
		AppliedParameters = DefaultAppliedParameters(SearchParameters.SearchRules, SearchParameters.PrefilterComposer);
 		
		SearchAreaManager.SearchForDuplicatesParameters(AppliedParameters, AdditionalParameters);
		
		AllAdditionalFields = New Map;
		For Each Restriction In AppliedParameters.CompareRestrictions Do
			For Each KeyValue In New Structure(Restriction.AdditionalFields) Do
				FieldName = KeyValue.Key;
				If AllAdditionalFields[FieldName] = Undefined Then
					AdditionalDataFields = AdditionalDataFields + "," + FieldName;
					AllAdditionalFields[FieldName] = True;
				EndIf; 
			EndDo;
		EndDo;
		AdditionalDataFields = Mid(AdditionalDataFields, 2);
		
		// Size of the data portion to be passed to the applied rules for calculating
		AppliedPortionSize = AppliedParameters.ItemCountForCompare;
	EndIf;
	
	// List of fields perhaps modified by the applied script
	For Each Row In SearchParameters.SearchRules Do
		If Row.Rule = "Equal" Then
			EqualityCompareFields = EqualityCompareFields + "," + Row.Attribute;
		ElsIf Row.Rule = "Like" Then
			LikeCompareFields = LikeCompareFields + "," + Row.Attribute;
		EndIf
	EndDo;
	EqualityCompareFields = Mid(EqualityCompareFields, 2);
	LikeCompareFields   = Mid(LikeCompareFields, 2);
	
	// 2. Constructing by perhaps modified filter settings composer
	Filter = ComposerSearchFilter(SearchParameters.PrefilterComposer);
	
	TableMetadata = Metadata.FindByFullName(SearchParameters.AreaToSearchForDuplicates);
	Characteristics= New Structure("CodeLength, DescriptionLength, Hierarchical, HierarchyType", 0, 0, False);
	FillPropertyValues(Characteristics, TableMetadata);
	
	HasDescription = Characteristics.DescriptionLength > 0;
	HasCode         = Characteristics.CodeLength > 0;
	
	If Characteristics.Hierarchical And Characteristics.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems Then
		// Do not searching among groups
		If IsBlankString(Filter.Text) Then
			Filter.Text = "NOT IsFolder";
		Else
			Filter.Text = "NOT IsFolder AND (" + Filter.Text + ")";
		EndIf;
	EndIf;
	
	// Additional fields can intersect other ones, they must get aliases
	CandidateTable = New ValueTable;
	CandidateColumns = CandidateTable.Columns;
	CandidateColumns.Add("Ref1");
	CandidateColumns.Add("Fields1");
	CandidateColumns.Add("Ref2");
	CandidateColumns.Add("Fields2");
	CandidateColumns.Add("IsDuplicates", New TypeDescription("Boolean"));
	CandidateTable.Indexes.Add("IsDuplicates");
	
	AdditionalFieldDetails = New Map;
	AdditionalAliases  = "";
	SequenceNumber = 0;
	For Each KeyValue In New Structure(AdditionalDataFields) Do
		FieldName = KeyValue.Key;
		Alias     = "Add" + Format(SequenceNumber, "NZ=; NG=") + "_" + FieldName;
		AdditionalFieldDetails.Insert(Alias, FieldName);
		
		AdditionalAliases = AdditionalAliases + "," + FieldName + " AS" + Alias;
		SequenceNumber = SequenceNumber + 1;
	EndDo;
	AdditionalAliases = Mid(AdditionalAliases, 2);
	
	// Similar fields are compared by equality
	IdentityFieldStructure = New Structure(EqualityCompareFields);
	IdentityCondition  = "";
	For Each KeyValue In IdentityFieldStructure Do
		FieldName = KeyValue.Key;
		IdentityCondition = IdentityCondition + "And" + FieldName + " = &" + FieldName + " ";
	EndDo;
	IdentityCondition = Mid(IdentityCondition, 2);
	
	SimilarityFieldStructure = New Structure(LikeCompareFields);
	
	CommonQueryPart = "
		|SELECT 
		|	" + ?(IsBlankString(EqualityCompareFields), "", EqualityCompareFields + "," ) + " " + ?(IsBlankString(LikeCompareFields),   "", LikeCompareFields   + "," ) + " " + ?(IsBlankString(AdditionalAliases), "", AdditionalAliases + "," ) + "Ref";
	If Not IdentityFieldStructure.Property("Code") And Not SimilarityFieldStructure.Property("Code") Then
		CommonQueryPart = CommonQueryPart + "," + ?(HasCode, "Code", "UNDEFINED") + " AS Code";
	EndIf;
	If Not IdentityFieldStructure.Property("Description") And Not SimilarityFieldStructure.Property("Description") Then
		CommonQueryPart = CommonQueryPart + "," + ?(HasDescription, "Description", "UNDEFINED") + " AS Description";
	EndIf;
	CommonQueryPart = CommonQueryPart + " FROM " + SearchParameters.AreaToSearchForDuplicates + " ";
	
	// Main query. Searching for duplicate candidates for each item.
	If SampleObject = Undefined Then
		
		Query = New Query(CommonQueryPart + " " + ?(IsBlankString(Filter.Text), " ", " WHERE " + Filter.Text) + " ORDER BY
		|	 Ref");
	Else
		
		PreselectionText = "
			|SELECT * INTO SampleObject FROM &_SampleObject AS Prototype
			|;////////////////////////////////////////////////////////////////////
			|SELECT 
			|	" + ?(IsBlankString(EqualityCompareFields), "", EqualityCompareFields + "," ) + "" + ?(IsBlankString(LikeCompareFields),   "", LikeCompareFields   + "," ) + "" + ?(IsBlankString(AdditionalAliases), "", AdditionalAliases + "," ) + "VALUE(" + SearchParameters.AreaToSearchForDuplicates + ".EmptyRef) AS Ref
			|";
		If Not IdentityFieldStructure.Property("Code") And Not SimilarityFieldStructure.Property("Code") Then
			PreselectionText = PreselectionText + "," + ?(HasCode, "Code", "UNDEFINED") + " AS Code";
		EndIf;
		If Not IdentityFieldStructure.Property("Description") And Not SimilarityFieldStructure.Property("Description") Then
			PreselectionText = PreselectionText + "," + ?(HasDescription, "Description", "UNDEFINED") + " AS Description";
		EndIf;
		PreselectionText = PreselectionText + "
			|FROM 
			| SampleObject
			|";
		
		Query = New Query(PreselectionText + "" + ?(IsBlankString(Filter.Text), "", "WHERE" + Filter.Text) + "");
			
		Query.SetParameter("_SampleObject", ObjectIntoValueTable(SampleObject));
	EndIf;
		
		
	// Search query for candidates for the current references.
	// Comparison of references and ordering in the previous query prevent recomparison.
	CandidateQuery = New Query(CommonQueryPart + "
		|WHERE 
		|	Ref >&_SourceRef
		|	" + ?(IsBlankString(Filter.Text), "", "AND (" + Filter.Text + ")") + "" + ?(IsBlankString(IdentityCondition), "", "AND (" + IdentityCondition+ ")") + "");
		
	For Each KeyValue In Filter.Parameters Do
		ParameterName  = KeyValue.Key;
		ParameterValue = KeyValue.Value;
		Query.SetParameter(ParameterName, ParameterValue);
		CandidateQuery.SetParameter(ParameterName, ParameterValue);
	EndDo;
	
	// Result and search loop
	DuplicateTable = New ValueTable;
	ResultColumns = DuplicateTable.Columns;
	ResultColumns.Add("Ref");
	For Each KeyValue In IdentityFieldStructure Do
		ResultColumns.Add(KeyValue.Key);
	EndDo;
	For Each KeyValue In SimilarityFieldStructure Do
		ResultColumns.Add(KeyValue.Key);
	EndDo;
	If ResultColumns.Find("Code") = Undefined Then
		ResultColumns.Add("Code");
	EndIf;
	If ResultColumns.Find("Description") = Undefined Then
		ResultColumns.Add("Description");
	EndIf;
	ResultColumns.Add("Parent");
	
	DuplicateTable.Indexes.Add("Ref");
	DuplicateTable.Indexes.Add("Parent");
	DuplicateTable.Indexes.Add("Ref, Parent");
	
	Result = New Structure("DuplicateTable, ErrorDescription", DuplicateTable);
	
	FieldStructure = New Structure;
	FieldStructure.Insert("AdditionalFieldDetails",   AdditionalFieldDetails);
	FieldStructure.Insert("IdentityFieldStructure",   IdentityFieldStructure);
	FieldStructure.Insert("SimilarityFieldStructure", SimilarityFieldStructure);
	FieldStructure.Insert("IdentityFieldList",        EqualityCompareFields);
	FieldStructure.Insert("SimilarityFieldList",      LikeCompareFields);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		// Selecting similar
		CandidateQuery.SetParameter("_SourceRef", Selection.Ref);
		For Each KeyValue In IdentityFieldStructure Do
			FieldName = KeyValue.Key;
			CandidateQuery.SetParameter(FieldName, Selection[FieldName]);
		EndDo;
		
		CandidateSelection = CandidateQuery.Execute().Select();
		While CandidateSelection.Next() Do
			
			// Skipping the item if it is previously considered as a duplicate in any group.
			If DuplicateTable.Find(CandidateSelection.Ref, "Ref") <> Undefined Then
				Continue;
			EndIf;
			
			NotDuplicates = False;
			
			// Using similarity rules for rows
			For Each KeyValue In SimilarityFieldStructure Do
				FieldName = KeyValue.Key;
				If Not StringsSimilar(Selection[FieldName], CandidateSelection[FieldName]) Then
					NotDuplicates = True;
					Break;
				EndIf;
			EndDo;
			If NotDuplicates Then
				Continue;
			EndIf;
			
			If UseAppliedRules Then
				// Filling the table for the applied rules, calling them if necessary
				AddCandidateRow(CandidateTable, Selection, CandidateSelection, FieldStructure);
				If CandidateTable.Count() = AppliedPortionSize Then
					AddDuplicatesByAppliedRules(DuplicateTable, SearchAreaManager, Selection, CandidateTable, FieldStructure, AdditionalParameters);
					CandidateTable.Clear();
				EndIf;
			Else
				AddDuplicateToResult(DuplicateTable, Selection, CandidateSelection, FieldStructure);
			EndIf;
			
		EndDo;
		
		// Processing the rest of the applied rule table
		If UseAppliedRules Then
			AddDuplicatesByAppliedRules(DuplicateTable, SearchAreaManager, Selection, CandidateTable, FieldStructure, AdditionalParameters);
			CandidateTable.Clear();
		EndIf;
		
		// Group analysis is completed, analyzing the result volume. Do not passing large volume of data to the client.
		If ReturnedPortionSize > 0 And (DuplicateTable.Count() > ReturnedPortionSize) Then
			// Rolling back the last group
			For Each Row In DuplicateTable.FindRows( New Structure("Parent", Selection.Ref) ) Do
				DuplicateTable.Delete(Row);
			EndDo;
			For Each Row In DuplicateTable.FindRows( New Structure("Ref", Selection.Ref) ) Do
				DuplicateTable.Delete(Row);
			EndDo;
			// In case of the last group, reporting an error
			If DuplicateTable.Count() = 0 Then
				Result.ErrorDescription = NStr("en = 'Too much items are found, not all groups of duplicates are determined.'");
			Else
				Result.ErrorDescription = NStr("en = 'Too much items are found. Accurate search criteria.'");
			EndIf;
			Break;
		EndIf;
		
	EndDo;
	
	If Result.ErrorDescription <> Undefined Then
		Return Result;
	EndIf;
	
	// Calculating places of use
	If CalculateWhereReferencesUsed Then
		ReferenceSet = New Array;
		For Each DuplicateRow In DuplicateTable Do
			If ValueIsFilled(DuplicateRow.Ref) Then
				ReferenceSet.Add(DuplicateRow.Ref);
			EndIf;
		EndDo;
		
		UsageInstances = SearchForReferences(ReferenceSet);
		UsageInstances = UsageInstances.Copy(
			UsageInstances.FindRows(New Structure("AuxiliaryData", False))
		);
		UsageInstances.Indexes.Add("Ref");
		
		Result.Insert("UsageInstances", UsageInstances);
	EndIf;
	
	Return Result;
EndFunction

// Determining whether the object has applied rules.
//
// Parameters:
//  AreaManager - CatalogManager - manager of the object to be checked.
//
// Returns:
//  Boolean - True if the applied rules are defined.
//
Function HasSearchForDuplicatesAreaAppliedRules(Val AreaManager) Export
	
	Try
		Result = (True = AreaManager.UseSearchForDuplicates());
	Except
		// No method or broken method. Consider that there are no rules.
		Result = False;
	EndTry;
	
	Return Result;
EndFunction

#EndRegion

#Region InternalProceduresAndFunctions
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Transforms the object into the table for passing to the query.
//
Function ObjectIntoValueTable(Val DataObject)
	Result = New ValueTable;
	DataRow = Result.Add();
	
	MetaObject = DataObject.Metadata();
	
	For Each MetaAttribute In MetaObject.StandardAttributes  Do
		Name = MetaAttribute.Name;
		Result.Columns.Add(Name, MetaAttribute.Type);
		DataRow[Name] = DataObject[Name];
	EndDo;
	
	For Each MetaAttribute In MetaObject.Attributes Do
		Name = MetaAttribute.Name;
		Result.Columns.Add(Name, MetaAttribute.Type);
		DataRow[Name] = DataObject[Name];
	EndDo;
	
	Return Result;
EndFunction
	
// Performs an additional analysis of the candidates for duplicates with the applied method.
//
Procedure AddDuplicatesByAppliedRules(ResultTreeRows, Val SearchAreaManager, Val BasicData, Val CandidateTable, Val FieldStructure, Val AdditionalParameters)
	If CandidateTable.Count() = 0 Then
		Return;
	EndIf;
	
	SearchAreaManager.DuplicatesOnSearch(CandidateTable, AdditionalParameters);
	
	Data1 = New Structure;
	Data2 = New Structure;
	
	For Each CandidateCouple In CandidateTable.FindRows(New Structure("IsDuplicates", True)) Do
		Data1.Insert("Ref",         CandidateCouple.Ref1);
		Data1.Insert("Code",        CandidateCouple.Fields1.Code);
		Data1.Insert("Description", CandidateCouple.Fields1.Description);
		
		Data2.Insert("Ref",         CandidateCouple.Ref2);
		Data2.Insert("Code",        CandidateCouple.Fields2.Code);
		Data2.Insert("Description", CandidateCouple.Fields2.Description);
		
		For Each KeyValue In FieldStructure.IdentityFieldStructure Do
			FieldName = KeyValue.Key;
			Data1.Insert(FieldName, CandidateCouple.Fields1[FieldName]);
			Data2.Insert(FieldName, CandidateCouple.Fields2[FieldName]);
		EndDo;
		For Each KeyValue In FieldStructure.SimilarityFieldStructure Do
			FieldName = KeyValue.Key;
			Data1.Insert(FieldName, CandidateCouple.Fields1[FieldName]);
			Data2.Insert(FieldName, CandidateCouple.Fields2[FieldName]);
		EndDo;
		
		AddDuplicateToResult(ResultTreeRows, Data1, Data2, FieldStructure);
	EndDo;
EndProcedure

// Adds a row to the table of candidates for the applied method.
//
Function AddCandidateRow(CandidateTable, Val MainItemData, Val CandidateData, Val FieldStructure)
	
	Row = CandidateTable.Add();
	Row.IsDuplicates = False;
	Row.Ref1  = MainItemData.Ref;
	Row.Ref2  = CandidateData.Ref;
	
	Row.Fields1 = New Structure("Code, Description", MainItemData.Code, MainItemData.Description);
	Row.Fields2 = New Structure("Code, Description", CandidateData.Code, CandidateData.Description);
	
	For Each KeyValue In FieldStructure.IdentityFieldStructure Do
		FieldName = KeyValue.Key;
		Row.Fields1.Insert(FieldName, MainItemData[FieldName]);
		Row.Fields2.Insert(FieldName, CandidateData[FieldName]);
	EndDo;
	
	For Each KeyValue In FieldStructure.SimilarityFieldStructure Do
		FieldName = KeyValue.Key;
		Row.Fields1.Insert(FieldName, MainItemData[FieldName]);
		Row.Fields2.Insert(FieldName, CandidateData[FieldName]);
	EndDo;
	
	For Each KeyValue In FieldStructure.AdditionalFieldDetails Do
		ColumnName = KeyValue.Value;
		FieldName  = KeyValue.Key;
		
		Row.Fields1.Insert(ColumnName, MainItemData[FieldName]);
		Row.Fields2.Insert(ColumnName, CandidateData[FieldName]);
	EndDo;
	
	Return Row;
EndFunction

// Adds the found option to the results tree.
//
Procedure AddDuplicateToResult(Result, Val MainItemData, Val CandidateData, Val FieldStructure)
	
	GroupFilter = New Structure("Ref, Parent", MainItemData.Ref);
	DuplicateGroup = Result.FindRows(GroupFilter);
	
	If DuplicateGroup.Count() = 0 Then
		DuplicateGroup = Result.Add();
		FillPropertyValues(DuplicateGroup, GroupFilter);
		
		DuplicateRow = Result.Add();
		FillPropertyValues(DuplicateRow, MainItemData, 
			"Ref, Code, Description" + FieldStructure.IdentityFieldList + "," + FieldStructure.SimilarityFieldList
		);
		
		DuplicateRow.Parent = DuplicateGroup.Ref;
	Else
		DuplicateGroup = DuplicateGroup[0];
	EndIf;
	
	DuplicateRow = Result.Add();
	FillPropertyValues(DuplicateRow, CandidateData, 
		"Ref, Code, Description" + FieldStructure.IdentityFieldList + "," + FieldStructure.SimilarityFieldList
	);
	
	DuplicateRow.Parent = DuplicateGroup.Ref;
EndProcedure

// Generates the query condition text and the set of parameters.
//
Function ComposerSearchFilter(Val FilterComposer)
	Result = New Structure("Parameters", New Structure);
	
	GroupStack = New Array;
	GroupStack.Insert(0, DataCompositionFilterItemsGroupType.AndGroup);
	
	Result.Insert("Text", FilterTextComposerGroups(FilterComposer.Settings.Filter.Items, GroupStack, Result.Parameters) );
	Result.Insert("Details", String(FilterComposer.Settings.Filter) );
	
	Return Result;
EndFunction

// Generates the text to be used in the query. Fills the parameters.
//
Function FilterTextComposerGroups(Val GroupItems, GroupStack, ComposerParameters)
	ItemCount = GroupItems.Count();
	
	If ItemCount = 0 Then
		// Condition group is empty
		Return "";
	EndIf;
	
	CurrentGroupType = GroupStack[0];
	
	Text = "";
	CompareToken = ComposerFilterGroupCompareToken(CurrentGroupType);
	
	For Each Item In GroupItems Do
		
		If TypeOf(Item) = Type("DataCompositionFilterItem") Then
			// Single item
			ParameterName  = "FilterParameter" + Format(ComposerParameters.Count(), "NZ=; NG=");
			
			SearchBySimilarity = False;
			Text = Text + " " + CompareToken + " " + ComposerFilterGroupCompareText(Item.LeftValue, Item.ComparisonType, "&" + ParameterName, SearchBySimilarity);
			
			If SearchBySimilarity Then
				ComposerParameters.Insert(ParameterName, "%" + Item.RightValue + "%");
			Else
				ComposerParameters.Insert(ParameterName, Item.RightValue);
			EndIf;
		Else
			// Nested group
			GroupStack.Insert(0, Item.GroupType);
			Text = Text + " " + CompareToken + " " + FilterTextComposerGroups(Item.Items, GroupStack, ComposerParameters);
			GroupStack.Delete(0);
		EndIf;
		
	EndDo;
	
	Text = Mid(Text, 2 + StrLen(CompareToken));
	Return ComposerFilterGroupOpeningToken(CurrentGroupType) 
		+ "(" + Text + ")";
EndFunction

// Compare token for items inside groups.
//
Function ComposerFilterGroupCompareToken(Val GroupType)
	
	If GroupType = DataCompositionFilterItemsGroupType.AndGroup Then 
		Return "AND";
		
	ElsIf GroupType = DataCompositionFilterItemsGroupType.OrGroup Then 
		Return "OR";
		
	ElsIf GroupType = DataCompositionFilterItemsGroupType.NotGroup Then
		Return "AND";
		
	EndIf;
	
	Return "";
EndFunction

// Operation token before group.
//
Function ComposerFilterGroupOpeningToken(Val GroupType)
	
	If GroupType = DataCompositionFilterItemsGroupType.NotGroup Then
		Return "NOT"
	EndIf;
	
	Return "";
EndFunction

// Compare text of two operands by the comparison type.
//
Function ComposerFilterGroupCompareText(Val Field, Val ComparisonType, Val ParameterName, SimilaritySearchUsed = False)
	
	SimilaritySearchUsed = False;
	CompareField         = String(Field);
	
	If ComparisonType = DataCompositionComparisonType.Greater Then
		Return CompareField + " >" + ParameterName;
		
	ElsIf ComparisonType = DataCompositionComparisonType.GreaterOrEqual Then
		Return CompareField + " >=" + ParameterName;
		
	ElsIf ComparisonType = DataCompositionComparisonType.InHierarchy Then
		Return CompareField + " IN HIERARCHY (" + ParameterName + ")";
		
	ElsIf ComparisonType = DataCompositionComparisonType.InList Then
		Return CompareField + " IN (" + ParameterName + ")";
		
	ElsIf ComparisonType = DataCompositionComparisonType.InListByHierarchy  Then
		Return CompareField + " IN HIERARCHY (" + ParameterName + ")";
		
	ElsIf ComparisonType = DataCompositionComparisonType.Filled Then
		SimilaritySearchUsed = True;
		Return CompareField + " NOT LIKE """"";
		
	ElsIf ComparisonType = DataCompositionComparisonType.Less Then
		Return CompareField + " <" + ParameterName;
		
	ElsIf ComparisonType = DataCompositionComparisonType.LessOrEqual Then
		Return CompareField + " <=" + ParameterName;
		
	ElsIf ComparisonType = DataCompositionComparisonType.NotInHierarchy Then
		Return CompareField + " NOT IN HIERARCHY (" + ParameterName + ")";
		
	ElsIf ComparisonType = DataCompositionComparisonType.NotInList Then
		Return CompareField + " NOT IN (" + ParameterName + ")";
		
	ElsIf ComparisonType = DataCompositionComparisonType.NotInListByHierarchy Then
		Return CompareField + " NOT IN HIERARCHY (" + ParameterName + ")";
		
	ElsIf ComparisonType = DataCompositionComparisonType.NotFilled Then
		SimilaritySearchUsed = True;
		Return CompareField + " LIKE """"";
		
	ElsIf ComparisonType = DataCompositionComparisonType.NotEqual Then
		Return CompareField + " <>" + ParameterName + " ";
		
	ElsIf ComparisonType = DataCompositionComparisonType.NotContains Then
		SimilaritySearchUsed = True;
		Return CompareField + " NOT LIKE" + ParameterName + " ";
		
	ElsIf ComparisonType = DataCompositionComparisonType.Equal Then
		Return CompareField + " =" + ParameterName;
		
	ElsIf ComparisonType = DataCompositionComparisonType.Contains Then
		SimilaritySearchUsed = True;
		Return CompareField + " Like" + ParameterName + " ";;
		
	EndIf;
	
	Return "";
EndFunction

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Fuzzy row comparison
//

Function StringsSimilar(Val String1, Val String2)
	
	Return RowSimilarityPercent(String1, String2) >= 90;
	
EndFunction

// Returns the similarity percentage: 0 - not similar, 100 - full match of strings.
//
Function RowSimilarityPercent(Val String1, Val String2) Export
	If String1 = String2 Then
		Return 100;
	EndIf;
	
	AllWords = New Map;
	WordOccurrences(AllWords, String1, 1);
	WordOccurrences(AllWords, String2, 2);
	
	// Different words only
	Sorter1 = New ValueList;
	Sorter2 = New ValueList;
	For Each KeyValue In AllWords Do
		If KeyValue.Value = 1 Then
			Sorter1.Add(KeyValue.Key);
		ElsIf KeyValue.Value = 2 Then
			Sorter2.Add(KeyValue.Key);
		EndIf;
	EndDo;
	
	FirstString  = WordsFromList(Sorter1);
	SecondString = WordsFromList(Sorter2);
	If FirstString = SecondString Then 
		Return 100;
	EndIf;
	
	Metrics = EditingMetrics(FirstString, SecondString);
	
	Return 100 - Metrics * 100 / Max(StrLen(String1), StrLen(String2))
EndFunction

Procedure WordOccurrences(Result, Val SourceString, Val Delta)
	
	StringToProcess = TrimAll(SourceString);
	While True Do
		Position = Find(StringToProcess, " ");
		If Position = 0 Then 
			Break;
		EndIf;
		
		CurrentString = Left(StringToProcess, Position - 1);
		If Not IsBlankString(CurrentString) Then
			Value = Result[CurrentString];
			If Value = Undefined Then
				Value = 0;
			EndIf;
			Result.Insert(CurrentString, Value + Delta);
		EndIf;
		
		StringToProcess = Mid(StringToProcess, Position + 1);
	EndDo;
	
	If Not IsBlankString(StringToProcess) Then
		Value = Result[StringToProcess];
		If Value = Undefined Then
			Value = 0;
		EndIf;
		Result.Insert(StringToProcess, Value + Delta);
	EndIf;
	
EndProcedure

Function WordsFromList(Val WordList)
	Result = "";
	
	WordList.SortByValue();
	For Each Item In WordList Do
		Result = Result + " " + Item.Value;
	EndDo;
	
	Return Mid(Result, 2);
EndFunction

Function EditingMetrics(Val String1, Val String2)
	If String1 = String2 Then
		Return 0;
	EndIf;
	
	Length1 = StrLen(String1);
	Length2 = StrLen(String2);
	
	If Length1 = 0 Then
		If Length2 = 0 Then
			Return 0;
		EndIf;
		Return Length2;
		
	ElsIf Length2 = "" Then
		Return Length1;
		
	EndIf;
	
	// Initialization
	Coefficients = New Array(Length1 + 1, Length2 + 1);
	For Position1 = 0 to Length1 Do
		Coefficients[Position1][0] = Position1;
	EndDo;
	For Position2 = 0 to Length2 Do
		Coefficients[0][Position2] = Position2
	EndDo;
	
	// Calculating
	For Position1 = 1 to Length1 Do
		PrevPosition1 = Position1 - 1;
		Char1         = Mid(String1, Position1, 1);
		
		For Position2 = 1 to Length2 Do
			PrevPosition2 = Position2 - 1;
			Char2         = Mid(String2, Position2, 1);
			
			Cost = ?(Char1 = Char2, 0, 1); // Replacement cost
			
			Coefficients[Position1][Position2] = Min(
				Coefficients[PrevPosition1][Position2]     + 1,	// Deletion cost
				Coefficients[Position1]    [PrevPosition2] + 1,	// Insertion cost
				Coefficients[PrevPosition1][PrevPosition2] + Cost
			);
			
			If Position1 > 1 And Position2 > 1 And Char1 = Mid(String2, PrevPosition2, 1) And Mid(String1, PrevPosition1, 1) = Char2 Then
				Coefficients[Position1][Position2] = Min(
					Coefficients[Position1][Position2],
					Coefficients[Position1 - 2][Position2 - 2] + Cost	// Order change cost
				);
			EndIf;
			
		EndDo;
	EndDo;
	
	Return Coefficients[Length1][Length2];
EndFunction

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Procedure SearchForDuplicatesAreaGroup(Result, Val AnalyzeAppliedRules, Val GroupManager, Val Icon)
	
	For Each Item In GroupManager Do
		Meta = Metadata.FindByType(TypeOf(Item));
		If Not AccessRight("Read", Meta) Then
			// Access denied, do not reflecting in the list
			Continue;
		EndIf;
		
		If AnalyzeAppliedRules Then
			HasAppliedRules = HasSearchForDuplicatesAreaAppliedRules( GroupManager[Meta.Name] );
		Else
			HasAppliedRules = False;
		EndIf;
		
		Result.Add(Meta.FullName(), String(Meta), HasAppliedRules, PictureLib[Icon]);
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Functional copy
//

// [CommonUse.UsageInstances]
Function SearchForReferences(Val ReferenceSet, Val ResultAddress = "")
	
	Return CommonUse.UsageInstances(ReferenceSet, ResultAddress);
	
EndFunction

// [CommonUse.ReplaceReferences]
Function ReplaceReferences(Val ReplacementCouples, Val Parameters = Undefined, Val ResultAddress = "")
	
	Return CommonUse.ReplaceReferences(ReplacementCouples, Parameters, ResultAddress);
	
EndFunction

#EndRegion


#EndIf