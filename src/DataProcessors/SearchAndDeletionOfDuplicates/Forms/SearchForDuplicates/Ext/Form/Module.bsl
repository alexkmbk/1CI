// Confirmation flag used during a nonmodal closing

&AtClient
Var FormClosingConfirmation;
 
#Region FormEventHandlers

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 
 &AtServer

Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetColorsAndConditionalAppearance();
		
	If Parameters.Property("SelfTest") Then
		Return;
	EndIf;
	
	InitMainParameters();
	
	InitFilterComposerAndRules();
	// The schema must be always reformed. Composer settings are according to SearchForDuplicates. 
	
	// Permanent Interface
	StatePresentation = Items.NoSearchExecuted.StatePresentation;
	StatePresentation.Visible = True;
	StatePresentation.Text = NStr("en = 'Search for duplicates was not executed. 
	 |Set the filter and comparison conditions and click Find duplicates.'");
	StatePresentation.Picture = Items.Warning32.Picture;
	
	StatePresentation = Items.Search.StatePresentation;
	StatePresentation.Visible = True;
	StatePresentation.Text = NStr("en = 'Searching for duplicates...'");
	StatePresentation.Picture = Items.LongAction48.Picture;
	
	StatePresentation = Items.Deletion.StatePresentation;
	StatePresentation.Visible = True;
	StatePresentation.Text = NStr("en = 'Deleting duplicates...'");
	StatePresentation.Picture = Items.LongAction48.Picture;
	
	StatePresentation = Items.DuplicatesNotFound.StatePresentation;
	StatePresentation.Visible = True;
	StatePresentation.Text = NStr("en = 'No duplicates were found by the specified parameters.
	 |Change the filter and comparison conditions and click Find duplicates.'");
	StatePresentation.Picture = Items.Warning32.Picture;
	
	// Step-by-step wizard
	InitWizard(Items.WizardSteps, Items.Next, Items.Back, Items.Cancel);
	
	// Adding steps based on the form logic
	InitWizardScenario();
	
	// Autosaving settings
	SavedInSettingsDataModified =  True;
EndProcedure
 
&AtClient

Procedure OnOpen(Cancel)
	
	// Verifying the settings
	UpdateDuplicateAreaSettings(AreaToSearchForDuplicates);
	
	// Specifying the start page
	SetWizardStartPage(Items.NoSearchExecutedStep);
	StartWizard();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	// Checking the client variable
	If FormClosingConfirmation<>True Then
		Notification = New  NotifyDescription("FormClosingCompletion",  ThisObject);
		Cancel = True;
		
		Text = NStr("en = 'Do you want to close the search and replacement of duplicates?'");
		ShowQueryBox(Notification, Text, QuestionDialogMode.YesNo);
	EndIf;
EndProcedure

&AtClient

Procedure ChoiceProcessing(SelectedValue,  ChoiceSource)
	
	If SelectedValue =  Undefined Then
		Return;
	EndIf;
	
	SourceFormName = Mid(ChoiceSource.FormName, StrLen(BaseFormName) + 1);
	If SourceFormName = "FilterRules" Then
		UpdateFilterComposer(SelectedValue);
		UpdateFilterDetails();
		
		GoToWizardStep(Items.NoSearchExecutedStep, True);
		
	ElsIf SourceFormName = "AreaToSearchForDuplicates" Then
		UpdateDuplicateAreaSettings(SelectedValue);
		
		GoToWizardStep(Items.NoSearchExecutedStep, True);
		
	ElsIf SourceFormName = "SearchRules" Then
		UpdateSearchRules(SelectedValue);
		UpdateSearchRuleDetails();
		
		GoToWizardStep(Items.NoSearchExecutedStep, True);
		
	EndIf;
	
EndProcedure
 
&AtServer

Procedure  BeforeLoadDataFromSettingsAtServer(Settings)
	
	// Verifying the aria to search for duplicates
	SettingsKey = "AreaToSearchForDuplicates";
	If AreasToSearchForDuplicates.FindByValue( Settings[SettingsKey] ) = Undefined Then
		Settings.Delete(SettingsKey);
	EndIf;
	
EndProcedure

#EndRegion

# Region FormHeaderItemEventHandlers

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

&AtClient
Procedure  SearchAreaPresentationStartChoice(Item, ChoiceData,  StandardProcessing)
	StandardProcessing = False;
	
	FormParameters = New  Structure;
	FormParameters.Insert("AreaToSearchForDuplicates", AreaToSearchForDuplicates);
	
	OpenForm(BaseFormName + "AreaToSearchForDuplicates", FormParameters, ThisObject);
EndProcedure

&AtClient
 Procedure PresentationOfAreaToSearchForDuplicatesClearing(Item, StandardProcessing)

	
	StandardProcessing = False;
	
EndProcedure

&AtClient

Procedure  AllUnprocessedItemUsageInstancesClick(Item)
	
	ReportParameters =  UsageInstanceReportParameters(UnprocessedDuplicates);
	OpenForm("Report.SearchForReferences.Form", ReportParameters);
	
EndProcedure

&AtClient

Procedure AllUsageInstancesClick(Item)
	
	ReportParameters =  UsageInstanceReportParameters(FoundDuplicates);
	OpenForm("Report.SearchForReferences.Form", ReportParameters);
	
EndProcedure

&AtClient

Procedure FilterRulesClick(Item)
	
	FormParameters = New  Structure;
	FormParameters.Insert("CompositionSchemaAddress", CompositionSchemaAddress);
	FormParameters.Insert("FilterComposerSettingsAddress",  FilterComposerSettingsAddress());
	FormParameters.Insert("MasterFormID", UUID);
	FormParameters.Insert("FilterAreaPresentation",
		Items.PresentationOfAreaToSearchForDuplicates.ChoiceList[0].Presentation);
	
	OpenForm(BaseFormName + "FilterRules", FormParameters, ThisObject);
	
EndProcedure
 
&AtClient

Procedure SearchRulesClick(Item)
	
	FormParameters = New Structure;
	FormParameters.Insert("AreaToSearchForDuplicates", AreaToSearchForDuplicates);
	FormParameters.Insert("AppliedRuleDetails", AppliedRuleDetails);
	FormParameters.Insert("SettingsAddress", SearchRuleSettingsAddress() );
	FormParameters.Insert("FilterAreaPresentation", 
		Items.PresentationOfAreaToSearchForDuplicates.ChoiceList[0].Presentation);
		
	OpenForm(BaseFormName + "SearchRules", FormParameters, ThisObject);
EndProcedure


#EndRegion
 
#Region  FoundDuplicatesTableEventHandlers

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

&AtClient
Procedure FoundDuplicatesOnActivateRow(Item)
	
	AttachIdleHandler("DuplicateRowActivationDeferredHandler", 0.1, True);
	
EndProcedure
 
&AtClient
Procedure  DuplicateRowActivationDeferredHandler()
	
	RowData = Items.FoundDuplicates.CurrentData;
	If RowData =  Undefined Then
		Return;
	EndIf;
	
	UpdateCandidateUsageInstances( RowData.GetID() );
EndProcedure
 
&AtServer
Procedure UpdateCandidateUsageInstances(Val DataRow)
	RowData = FoundDuplicates.FindByID(DataRow);
	
	If RowData.GetParent() = Undefined Then
		// Group details
		CandidateUsageInstances.Clear();
		
		OriginalDescription = Undefined;
		For Each Candidate In RowData.GetItems() Do
			If Candidate.Main  Then
				OriginalDescription = Candidate.Description;
				Break;
			EndIf;
		EndDo;
		
		Items.CurrentDuplicateGroupDetails.Title = RowFormat(
			NStr("en = 'The %1 item duplicates (%2) are found'"),
			OriginalDescription, RowData.Count
		);
		
		Items.UsageInstancesPages.CurrentPage = Items.GroupDetails;
		Return;
	EndIf;
	
	// List of usage instances
	UsageTable =  GetFromTempStorage(UsageInstanceAddress);
	Filter = New  Structure("Ref", RowData.Ref);
	
	CandidateUsageInstances.Load(
		UsageTable.Copy( UsageTable.FindRows(Filter) )
	);
	
	If RowData.Count = 0 Then
		Items.CurrentDuplicateGroupDetails.Title = RowFormat(NStr("en = 'The %1 item is not used'"), 
			RowData.Description
		);
		
		Items.UsageInstancesPages.CurrentPage = Items.GroupDetails;
	Else
		Items.CandidateUsageInstances.Title = RowFormat(NStr("en = '%1 usage instances (%2)'"), 
			RowData.Description, RowData.Count
		);
		
		Items.UsageInstancesPages.CurrentPage = Items.UsageInstances;
	EndIf;
	
EndProcedure
 
&AtClient

Procedure FoundDuplicatesSelection(Item, SelectedRow, Field, StandardProcessing)
	
	OpenDouplicateForm(Item.CurrentData);
	
EndProcedure

&AtClient

Procedure FoundDuplicatesCheckOnChange(Item)
	RowData = Items.FoundDuplicates.CurrentData;
	
	RowData.Check =  RowData.Check % 2;
	
	ChangeCandidateMarksHierarchically(RowData);
EndProcedure

#EndRegion

#Region UnprocessedDuplicatesTableEventHandlers

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

&AtClient
Procedure UnprocessedDuplicatesOnActivateRow(Item)
	
	AttachIdleHandler("UnprocessedDuplicateRowActivationDeferredHandler", 0.1, True);
	
EndProcedure

&AtClient
Procedure UnprocessedDuplicateRowActivationDeferredHandler()
	
	RowData = Items.UnprocessedDuplicates.CurrentData;
	If RowData =  Undefined Then
		Return;
	EndIf;
	
	UpdateUnprocessedItemUsageInstancesDuplicates( RowData.GetID() );
EndProcedure

&AtServer
Procedure UpdateUnprocessedItemUsageInstancesDuplicates(Val DataRow)
	RowData = UnprocessedDuplicates.FindByID(DataRow);
	
	If RowData.GetParent() = Undefined Then
		// Group details
		UnprocessedItemUsageInstances.Clear();
		
		OriginalDescription = Undefined;
		For Each Candidate In RowData.GetItems() Do
			If Candidate.Main Then
				OriginalDescription = Candidate.Description;
				Break;
			EndIf;
		EndDo;
		
		Items.CurrentDuplicateGroupDetails1.Title = RowFormat(
			NStr("en = 'Duplicates (%2) are found for the %1 item'"),
			OriginalDescription, RowData.Count
		);
		
		Items.UnprocessedItemUsageInstancesPages.CurrentPage = Items.UnprocessedItemGroupDetails;
		Return;
	EndIf;
	
	// List of error instances
	ErrorTable = GetFromTempStorage(ReplacementResultAddress);
	Filter = New Structure("Ref", RowData.Ref);
	
	Data = ErrorTable.Copy( ErrorTable.FindRows(Filter) );
	Data.Columns.Add("Icon");
	Data.FillValues(True, "Icon");
	UnprocessedItemUsageInstances.Load(Data);
	
	If RowData.Count = 0 Then
		Items.CurrentDuplicateGroupDetails1.Title = RowFormat(NStr("en = 'The %1 item is processed'"), 
			RowData.Description
		);
		
		Items.UnprocessedItemUsageInstancesPages.CurrentPage = Items.UnprocessedItemGroupDetails;
	Else
		Items.CandidateUsageInstances.Title = RowFormat(NStr("en = 'There are places where duplicates cannot be replaced (%1)'"), 
			RowData.Count
		);
		
		Items.UnprocessedItemUsageInstancesPages.CurrentPage = Items.UnprocessedItemUsageInstanceDetails;
	EndIf;
	
EndProcedure

&AtClient
Procedure UnprocessedDuplicatesSelection(Item, SelectedRow, Field, StandardProcessing)
	
	OpenDouplicateForm(Items.UnprocessedDuplicates.CurrentData);
	
EndProcedure

#EndRegion

#Region  UnprocessedItemUsageInstancesTableEventHandlers
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

&AtClient
Procedure  UnprocessedItemUsageInstancesOnActivateRow(Item)
	
	CurrentData = Item.CurrentData;
	If CurrentData =  Undefined Then
		UnprocessedItemErrorDescription = "";
	Else
		UnprocessedItemErrorDescription =  CurrentData.ErrorText;
	EndIf;
	
EndProcedure

&AtClient
Procedure  UnprocessedItemUsageInstancesSelection(Item, SelectedRow, Field, StandardProcessing)
	
	CurrentData =  UnprocessedItemUsageInstances.FindByID(SelectedRow);
	ShowValue(, CurrentData.ErrorObject);
	
EndProcedure

#EndRegion
 
#Region CandidateUsageInstancesTableEventHandlers
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

&AtClient
Procedure CandidateUsageInstancesCase(Item, SelectedRow, Field, StandardProcessing)
	
	CurrentData = CandidateUsageInstances.FindByID(SelectedRow);
	ShowValue(, CurrentData.Data);
	
EndProcedure

#EndRegion
 
#Region FormCommandHandlers
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

&AtClient
Procedure ClearFilterRules(Command)
	
	ClearFilterForcedly();
	
EndProcedure

&AtClient
Procedure SelectMainItem(Command)
	
	RowData = Items.FoundDuplicates.CurrentData;
	If RowData = Undefined	// No data
		Or RowData.Main	 	// Current item is a main one already
	Then
		Return;
	EndIf;
		
	Parent = RowData.GetParent();
	If Parent = Undefined Then
		Return;
	EndIf;
	
	ChangeMainItemHierarchically(RowData, Parent);
EndProcedure

&AtClient
Procedure OpenCandidateForDuplicate(Command)
	
	OpenDouplicateForm(Items.FoundDuplicates.CurrentData);
	
EndProcedure

&AtClient
Procedure ExpandDuplicateGroups(Command)
	
	ExpandDuplicateGroupHierarchically();
	
EndProcedure

&AtClient
Procedure CollapseDuplicateGroups(Command)
	
	CollapseDuplicateGroupHierarchically();
	
EndProcedure

&AtClient
Procedure RetrySearch(Command)
	
	GoToWizardStep(Items.SearchStep, True);
	
EndProcedure

&AtClient
Procedure WizardStepBack(Command)
	WizardStep("Back");
EndProcedure

&AtClient
Procedure WizardStepNext(Command)
	WizardStep("Next");
EndProcedure

&AtClient
Procedure WizardStepCancel(Command)
	WizardStep("Cancel");
EndProcedure

#EndRegion
 
#Region InternalProceduresAndFunctions

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

&AtClient
Procedure UpdateDuplicateAreaSettings(Val SelectedValue)
	
	Item = AreasToSearchForDuplicates.FindByValue(SelectedValue);
	If Item = Undefined Then
		PresentationOfAreaToSearchForDuplicates = "";
		AreaToSearchForDuplicates               = "";
	Else
		PresentationOfAreaToSearchForDuplicates = Item.Presentation;
		AreaToSearchForDuplicates               = SelectedValue;
	EndIf;
	
	InitFilterComposerAndRules();
EndProcedure

&AtClient
Procedure OpenDouplicateForm(Val CurrentData)
	If CurrentData = Undefined Or Not ValueIsFilled(CurrentData.Ref) Then
		Return;
	EndIf;
	
	ShowValue(,CurrentData.Ref);
EndProcedure

 &AtServer

Procedure SetColorsAndConditionalAppearance()
	
	InformationTextColor = StyleColorOrAuto("InformationText", 69, 81, 133);
	ErrorInformationTextColor = StyleColorOrAuto("ErrorInformationText", 255, 0, 0);
	ColorInaccessibleData = StyleColorOrAuto("ColorInaccessibleData", 192, 192, 192);
	
	ConditionalAppearanceItems = ConditionalAppearance.Items;
	ConditionalAppearanceItems.Clear();
	
	// No usage instances of the group
	AppearanceItem = ConditionalAppearanceItems.Add();
	
	AppearanceFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	AppearanceFilter.LeftValue = New DataCompositionField("FoundDuplicates.Ref");
	AppearanceFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	AppearanceFilter.RightValue = True;
	
	AppearanceItem.Appearance.SetParameterValue("Text", "");
	
	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("FoundDuplicatesCount");
	
	// 1. Row with the current main group item:
	
	// Picture
	AppearanceItem = ConditionalAppearanceItems.Add();
	
	AppearanceFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	AppearanceFilter.LeftValue = New DataCompositionField("FoundDuplicates.Main");
	AppearanceFilter.ComparisonType = DataCompositionComparisonType.Equal;
	AppearanceFilter.RightValue = True;
	
	AppearanceItem.Appearance.SetParameterValue("Visible", True);
	AppearanceItem.Appearance.SetParameterValue("Show", True);
	
	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("FoundDuplicatesMain");
	
	// Mark cleared
	AppearanceItem =  ConditionalAppearanceItems.Add();
	
	AppearanceFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	AppearanceFilter.LeftValue = New DataCompositionField("FoundDuplicates.Main");
	AppearanceFilter.ComparisonType = DataCompositionComparisonType.Equal;
	AppearanceFilter.RightValue = True;
	
	AppearanceItem.Appearance.SetParameterValue("Visible", False);
	AppearanceItem.Appearance.SetParameterValue("Show", False);
	
	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("FoundDuplicatesCheck");
	
	// 2. Row with a usual item
	
	// Picture
	AppearanceItem = ConditionalAppearanceItems.Add();
	
	AppearanceFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	AppearanceFilter.LeftValue = New DataCompositionField("FoundDuplicates.Main");
	AppearanceFilter.ComparisonType = DataCompositionComparisonType.Equal;
	AppearanceFilter.RightValue = False;
	
	AppearanceItem.Appearance.SetParameterValue("Visible", False);
	AppearanceItem.Appearance.SetParameterValue("Show", False);
	
	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("FoundDuplicatesMain");
	
	// Mark selected
	AppearanceItem = ConditionalAppearanceItems.Add();
	
	AppearanceFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	AppearanceFilter.LeftValue = New DataCompositionField("FoundDuplicates.Main");
	AppearanceFilter.ComparisonType = DataCompositionComparisonType.Equal;
	AppearanceFilter.RightValue = False;
	
	AppearanceItem.Appearance.SetParameterValue("Visible", True);
	AppearanceItem.Appearance.SetParameterValue("Show", True);
	
	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("FoundDuplicatesCheck");
	
	// 3. Usage instances
	AppearanceItem =  ConditionalAppearanceItems.Add();
	
	AppearanceFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	AppearanceFilter.LeftValue = New DataCompositionField("FoundDuplicates.Ref");
	AppearanceFilter.ComparisonType = DataCompositionComparisonType.Filled;
	AppearanceFilter.RightValue = True;
	
	AppearanceFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	AppearanceFilter.LeftValue = New DataCompositionField("FoundDuplicates.Count");
	AppearanceFilter.ComparisonType = DataCompositionComparisonType.Equal;
	AppearanceFilter.RightValue = 0;
	
	AppearanceItem.Appearance.SetParameterValue("Text", NStr("en = 'Not used'"));
	
	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("FoundDuplicatesCount");
	
	// 4. Inactive row
	AppearanceItem = ConditionalAppearanceItems.Add();
	
	AppearanceFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	AppearanceFilter.LeftValue = New DataCompositionField("FoundDuplicates.Check");
	AppearanceFilter.ComparisonType = DataCompositionComparisonType.Equal;
	AppearanceFilter.RightValue = 0;
	
	AppearanceItem.Appearance.SetParameterValue("TextColor", ColorInaccessibleData);
	
	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("FoundDuplicates");
	
EndProcedure
 
&AtServer
Procedure StartSearchForDuplicatesInBackground()
	
	If Not  IsTempStorageURL(CompositionSchemaAddress) Then
		// Not initialized
		Return;
	EndIf;
		
	SearchParameters = New Structure;
	SearchParameters.Insert("AreaToSearchForDuplicates", AreaToSearchForDuplicates);
	SearchParameters.Insert("MaximumNumberOfDuplicates", 1500);
	
	SearchRuleArray = New Array;
	For Each Rule In SearchRules Do
		SearchRuleArray.Add( New Structure("Attribute, Rule", Rule.Attribute, Rule.Rule) );
	EndDo;
	SearchParameters.Insert("SearchRules", SearchRuleArray);
	
	SearchParameters.Insert("TakeAppliedRulesIntoAccount", TakeAppliedRulesIntoAccount);
	
	If  CanExecuteDataProcessorObjectModuleProcedure Then
		// Passing the schema as the composition schema. Processing in the separate background
		// session.
		SearchParameters.Insert("CompositionSchema", GetFromTempStorage(CompositionSchemaAddress) );
	Else 
		// Passing the address as the composition schema. Processing in the current session
		SearchParameters.Insert("CompositionSchema", CompositionSchemaAddress);
	EndIf;
	SearchParameters.Insert("PrefilterComposerSettings", PrefilterComposer.Settings);
	
	StartLongWizardAction("BackgroundSearchForDuplicates",  SearchParameters, True, NStr("en = 'Duplicate group search'") );
EndProcedure
 
&AtServer
Function StyleColorOrAuto(Val Name,  Val R = Undefined, G = Undefined, B = Undefined)

	StyleItem = Metadata.StyleItems.Find(Name);
	If StyleItem <> Undefined And StyleItem.Type = Metadata.ObjectProperties.StyleElementType.Color Then
		Return StyleColors[Name];
	EndIf;
	
	Return ?(R = Undefined, New Color, New Color(R, G, B));
EndFunction

&AtServer
Function DuplicateReplacementCouples()
	ReplacementCouples = New  Map;
	
	DuplicateTree = FormAttributeToValue("FoundDuplicates");
	SearchFilter = New Structure("Main", True);
	
	For Each Parent  In DuplicateTree.Rows Do
		MainInGroup = Parent.Rows.FindRows(SearchFilter)[0].Ref;
		
		For Each Child In Parent.Rows Do
			If Child.Check = 1 Then 
				ReplacementCouples.Insert(Child.Ref, MainInGroup);
			EndIf;
		EndDo;
	EndDo;
	
	Return ReplacementCouples;
EndFunction
 
&AtClient
Function UsageInstanceReportParameters(Val Source)
	
	ReportParameters = New  Structure;
	ReportParameters.Insert("ReferenceSet", New Array);
	
	For Each Parent In Source.GetItems() Do
		For Each Child In Parent.GetItems() Do
			ReportParameters.ReferenceSet.Add(Child.Ref);
		EndDo;
	EndDo;
	
	Return ReportParameters;
EndFunction
 
&AtClient 
Procedure ExpandDuplicateGroupHierarchically(Val DataRow = Undefined)
	If DataRow <> Undefined Then
		Items.FoundDuplicates.Expand(DataRow, True);
	EndIf;
	
	// All of the first level
	AllRows = Items.FoundDuplicates;
	For Each RowData  In FoundDuplicates.GetItems() Do 
		AllRows.Expand(RowData.GetID(), True);
	EndDo;
EndProcedure
 
&AtClient 
Procedure CollapseDuplicateGroupHierarchically(Val DataRow = Undefined)
	If DataRow <> Undefined Then
		Items.FoundDuplicates.Collapse(DataRow);
		Return;
	EndIf;
	
	// All of the first level
	AllRows = Items.FoundDuplicates;
	For Each RowData In FoundDuplicates.GetItems() Do 
		AllRows.Collapse(RowData.GetID());
	EndDo;
EndProcedure
 
&AtClient

Procedure  ChangeCandidateMarksHierarchically(Val RowData)
	SetMarksForChilds(RowData);
	SetMarksForParents(RowData);
EndProcedure

&AtClient
Procedure SetMarksForChilds(Val RowData)
	Value = RowData.Check;
	For Each Child In RowData.GetItems() Do
		Child.Check = Value;
		SetMarksForChilds(Child);
	EndDo;
EndProcedure
 
&AtClient
Procedure SetMarksForParents(Val RowData)
	RowParent = RowData.GetParent();
	
	If RowParent <> Undefined Then
		AllTrue = True;
		NotAllFalse = False;
		
		For Each Child  In RowParent.GetItems() Do
			AllTrue = AllTrue And (Child.Check = 1);
			NotAllFalse = NotAllFalse Or (Child.Check > 0);
		EndDo;
		
		If AllTrue Then
			RowParent.Check = 1;
			
		ElsIf NotAllFalse Then
			RowParent.Check = 2;
			
		Else
			RowParent.Check = 0;
			
		EndIf;
		
		SetMarksForParents(RowParent);
	EndIf;
	
EndProcedure
 
&AtClient
Procedure ChangeMainItemHierarchically(Val RowData, Val Parent)
	For Each Child In Parent.GetItems() Do
		Child.Main = False;
	EndDo;
	RowData.Main = True;
	
	// Selected item is used always
	RowData.Check = 1;
	ChangeCandidateMarksHierarchically(RowData);
	
	// Changing the group name
	Parent.Description = RowFormat( NStr("en = '%1 (%2)'"), RowData.Description, Parent.Count);
EndProcedure
 
&AtServer
Function CheckDuplicateSearchState()
	ActionState = LongWizardActionState();
	
	If Not ActionState.Completed Then
		// Do not passing the state to the client yet
		ActionState.Result = Undefined;
		
	ElsIf ActionState.ErrorInfo <> Undefined Then
		// Completed with errors
		ActionState.Result = Undefined;
		
	ElsIf ActionState.Completed And  ActionState.Result <> Undefined Then
		// Generating the result tables
		ActionState.Result = FillDuplicateSearchResults(  ActionState.Result );
		
	EndIf;
	
	Return ActionState;
EndFunction
 
&AtServer
Function FillDuplicateSearchResults(Val Data)
	// Data is a DuplicateGroups module function result
	
	// Creating a tree for editing by the result tables
	TreeItems = FoundDuplicates.GetItems();
	TreeItems.Clear();
	
	UsageInstances = Data.UsageInstances;
	DuplicateTable = Data.DuplicateTable;
	
	RowFilter = New Structure("Parent");
	InstanceFilter = New Structure("Ref");
	
	FoundDuplicatesTotal = 0;
	
	AllGroups = DuplicateTable.FindRows(RowFilter);
	For Each CurGroup In AllGroups Do
		RowFilter.Parent = CurGroup.Ref;
		GroupItems = DuplicateTable.FindRows(RowFilter);
		
		TreeGroup = TreeItems.Add();
		TreeGroup.Count = GroupItems.Count();
		TreeGroup.Check = 1;
		
		MaxRow = Undefined;
		MaxInstances = -1;
		For Each Item In GroupItems Do
			TreeRow = TreeGroup.GetItems().Add();
			FillPropertyValues(TreeRow, Item, "Ref, Code, Description");
			TreeRow.Check = 1;
			
			InstanceFilter.Ref = Item.Ref;
			TreeRow.Count = UsageInstances.FindRows(InstanceFilter).Count();
			
			If MaxInstances < TreeRow.Count Then
				If MaxRow <> Undefined Then
					MaxRow.Main = False;
				EndIf;
				MaxRow = TreeRow;
				MaxInstances = TreeRow.Count;
				MaxRow.Main = True;
			EndIf;
			
			FoundDuplicatesTotal = FoundDuplicatesTotal + 1;
		EndDo;
		
		// Setting the candidate by the maximum reference
		TreeGroup.Description = MaxRow.Description + " (" + TreeGroup.Count + ")";
	EndDo;
	
	// Saving the usage instances for further filtering
	CandidateUsageInstances.Clear();
	Items.CurrentDuplicateGroupDetails.Title = NStr("en = 'No duplicates found'");
	
	If IsTempStorageURL(UsageInstanceAddress) Then
		DeleteFromTempStorage(UsageInstanceAddress);
	EndIf;
	UsageInstanceAddress = PutToTempStorage(UsageInstances, UUID);

	If Not IsBlankString(Data.ErrorDescription) Then
		// Background job crashed
		FoundDuplicateStateDetails = New FormattedString(Items.Attention16.Picture, "  ", 
			New FormattedString(Data.ErrorDescription, , ErrorInformationTextColor)
		);
		Return -1;
		
	EndIf;
		
	// No search errors
	If FoundDuplicatesTotal = 0 Then
		FoundDuplicateStateDetails = New FormattedString(Items.Information16.Picture, "  ",
			NStr("en = 'No duplicates found by the specified conditions'")
		);
	Else
		FoundDuplicateStateDetails = New FormattedString(RowFormat(
			NStr("en = 'Duplicate items found: %2 (among items: %1). All selected items will be marked for deletion
			|and replaced in the usage instances with the originals (marked with arrow).'"),
			FoundDuplicatesTotal, FoundDuplicatesTotal - TreeItems.Count()),
			, InformationTextColor
		);
	EndIf;
	
	Return FoundDuplicatesTotal;
EndFunction
 
&AtServer
Function CheckDuplicateDeletionState()
	
	ActionState = LongWizardActionState();
	
	If Not ActionState.Completed Then
		// Do not passing the state to the client yet
		ActionState.Result = Undefined;
		 
	ElsIf ActionState.ErrorInfo <> Undefined Then
		// Completed with errors
		ActionState.Result = Undefined;
		
	ElsIf ActionState.Completed And ActionState.Result <> Undefined Then
		// Generating the result tables
		ActionState.Result = FillDuplicateDeletionResults( ActionState.Result );
		
	EndIf;
	
	Return ActionState;
EndFunction
 
 &AtServer

Function FillDuplicateDeletionResults(Val ErrorTable)
	// ErrorTable is a ReplaceReferences module function result
	
	If IsTempStorageURL(ReplacementResultAddress) Then
		DeleteFromTempStorage(ReplacementResultAddress);
	EndIf;
	
	CompletedWithoutErrors = ErrorTable.Count() = 0;
	LastCandidate = Undefined;
	
	If CompletedWithoutErrors Then
		ProcessedItemsTotal = 0; 
		MainItemsTotal = 0;
		For Each DuplicateGroup  In FoundDuplicates.GetItems() Do
			If DuplicateGroup.Check Then
				For Each Candidate  In DuplicateGroup.GetItems() Do
					If Candidate.Main Then
						LastCandidate = Candidate.Ref;
						ProcessedItemsTotal = ProcessedItemsTotal + 1;
						MainItemsTotal = MainItemsTotal + 1;
					ElsIf Candidate.Check Then 
						ProcessedItemsTotal = ProcessedItemsTotal + 1;
					EndIf;
				EndDo;
			EndIf;
		EndDo;
		
		If MainItemsTotal =  1 Then
			// Multiple duplicates to the one item
			If LastCandidate = Undefined Then
				FoundDuplicateStateDetails = New FormattedString(Items.Information16.Picture, "  ", RowFormat(
					NStr("en = 'All found duplicates (%1) are merged'"),
						ProcessedItemsTotal)
				);
			Else
				LastCandidateLine =  CommonUse.SubjectString(LastCandidate);
				FoundDuplicateStateDetails = New FormattedString(Items.Information16.Picture, "  ", RowFormat(
					NStr("en = 'All found duplicates (%1) are merged into %2'"),
						ProcessedItemsTotal,  LastCandidateLine)
				);
			EndIf;
		Else
			// Multiple duplicates to the multiple groups
			FoundDuplicateStateDetails = New FormattedString(Items.Information16.Picture, "  ", RowFormat(
				NStr("en = 'All found duplicates (%1) are merged.
				 |Items left (%2)'"),
					ProcessedItemsTotal, MainItemsTotal)
			);
		EndIf;
	EndIf;
	
	UnprocessedDuplicates.GetItems().Clear();
	UnprocessedItemUsageInstances.Clear();
	CandidateUsageInstances.Clear();
	
	If CompletedWithoutErrors Then
		FoundDuplicates.GetItems().Clear();
		Return True;
	EndIf;
	
	// Saving for the further access when analyzing the references
	ReplacementResultAddress =  PutToTempStorage(ErrorTable, UUID);
	
	// Generating the duplicate tree by errors
	ValueToFormAttribute(FormAttributeToValue("FoundDuplicates"), "UnprocessedDuplicates");
	
	// Analyzing the remains
	Filter = New  Structure("Ref");
	Parents = UnprocessedDuplicates.GetItems();
	ParentPosition = Parents.Count() - 1;
	While ParentPosition >= 0 Do
		Parent = Parents[ParentPosition];
		
		Children = Parent.GetItems();
		ChildPosition = Children.Count() - 1;
		MainChild = Children[0];	// There is at least one
		
		While ChildPosition >= 0 Do
			Child = Children[ChildPosition];
			
			If Child.Main  Then
				MainChild = Child;
				Filter.Ref =  Child.Ref;
				Child.Count =  ErrorTable.FindRows(Filter).Count();
				
			ElsIf ErrorTable.Find(Child.Ref, "Ref") =  Undefined Then
				// Successfully deleted, no errors
				Children.Delete(Child);
				
			Else
				Filter.Ref =  Child.Ref;
				Child.Count =  ErrorTable.FindRows(Filter).Count();
				
			EndIf;
			
			ChildPosition = ChildPosition - 1;
		EndDo;
		
		ChildrenCount = Children.Count();
		If ChildrenCount = 1 And  Children[0].Main Then
			Parents.Delete(Parent);
		Else
			Parent.Count =  ChildrenCount - 1;
			Parent.Description = MainChild.Description + " (" + ChildrenCount + ")";
		EndIf;
		
		ParentPosition = ParentPosition - 1;
	EndDo;
	
	Return False;
EndFunction
 
&AtServer

Function FilterComposerSettingsAddress()
	
	Return PutToTempStorage(PrefilterComposer.Settings, UUID)
	
EndFunction

&AtServer
Function SearchRuleSettingsAddress()
	
	Settings = New  Structure;
	Settings.Insert("TakeAppliedRulesIntoAccount", TakeAppliedRulesIntoAccount);
	Settings.Insert("AllCompareOptions", AllCompareOptions);
	Settings.Insert("SearchRules", FormAttributeToValue("SearchRules"));
	
	Return PutToTempStorage(Settings);
EndFunction
 
&AtServer

Procedure UpdateFilterComposer(Address)
	
	PrefilterComposer.LoadSettings( GetFromTempStorage(Address) );
	DeleteFromTempStorage(Address);
	
EndProcedure 
 
&AtServer 

Procedure UpdateSearchRules(Address)
	Settings = GetFromTempStorage(Address);
	Address = Undefined;
	
	TakeAppliedRulesIntoAccount = Settings.TakeAppliedRulesIntoAccount;
	ValueToFormAttribute(Settings.SearchRules, "SearchRules");
EndProcedure 
 
&AtClient
Procedure UpdateSearchRuleDetails()
	RuleText = "";
	Conjunction = " " + NStr("en = 'AND'") + " ";
	
	For Each Rule In SearchRules Do
		
		If Rule.Rule  = "Equal" Then
			Comparison = NStr("en = '%1 matches'");
		ElsIf Rule.Rule = "Like" Then
			Comparison = NStr("en = '%1 matches by similar words'");
		Else
			Comparison = "";
		EndIf;
		
		RuleText = RuleText + ?(IsBlankString(Comparison), "", Conjunction)  + StrReplace(Comparison, "%1", Rule.AttributePresentation);
	EndDo;
	
	AppliedText = "";
	If TakeAppliedRulesIntoAccount Then
		For Position = 1 to StrLineCount(AppliedRuleDetails) Do
			RuleRow = TrimAll(StrGetLine(AppliedRuleDetails, Position));
			If Not  IsBlankString(RuleRow)  Then
				AppliedText = AppliedText + Conjunction + RuleRow;
			EndIf;
		EndDo;
	EndIf;
		
	RuleText = RuleText + AppliedText;
	If IsBlankString(RuleText) Then
		Items.SearchRules.Title = NStr("en = 'Rules not set'");
	Else
		Items.SearchRules.Title = TrimAll(Mid(RuleText, StrLen(Conjunction)));
	EndIf;
	
	Items.SearchRules.Enabled = Not IsBlankString(AreaToSearchForDuplicates);
EndProcedure
 
&AtClient
Procedure UpdateFilterDetails()
	
	FilterDetails = String(PrefilterComposer.Settings.Filter);
	If IsBlankString(FilterDetails) Then
		FilterDetails = NStr("en = 'All items'");
		Items.ClearFilterRules.Enabled = False;
	Else
		Items.ClearFilterRules.Enabled = True;
	EndIf;
	
	Items.FilterRules.Title = FilterDetails;
	
	Items.FilterRules.Enabled = Not IsBlankString(AreaToSearchForDuplicates);
EndProcedure
 
&AtClient

Procedure UpdateSearchAreaDetails()

	List = Items.PresentationOfAreaToSearchForDuplicates.ChoiceList;
	List.Clear();
	PresentationItem = List.Add();
	
	Current = AreasToSearchForDuplicates.FindByValue(AreaToSearchForDuplicates);
	If Current <> Undefined Then
		FillPropertyValues(PresentationItem, Current);
	EndIf;
	
	ThisObject.RefreshDataRepresentation();
EndProcedure

&AtClient
Procedure ClearFilterForcedly()
	
	PrefilterComposer.Settings.Filter.Items.Clear();
	UpdateFilterDetails();
	
EndProcedure
 
&AtServer
Procedure InitFilterComposerAndRules()
	// 1. Clearing all
	PrefilterComposer = New DataCompositionSettingsComposer;
	If IsTempStorageURL(CompositionSchemaAddress) Then
		DeleteFromTempStorage(CompositionSchemaAddress);
		CompositionSchemaAddress = "";
	EndIf;
	
	AppliedRuleDetails = Undefined;
	SearchRules.Clear();
	
	If IsBlankString(AreaToSearchForDuplicates) Then
		Return;
	EndIf;
	
	MetaArea = Metadata.FindByFullName(AreaToSearchForDuplicates);
	
	// 2. Creating the composer for searching and filtering
	AvailableFilterAttributes =  AvailableFilterMetaAttributeNames(MetaArea.StandardAttributes);
	AvailableFilterAttributes = ?(IsBlankString(AvailableFilterAttributes), ",",  AvailableFilterAttributes)
		+ AvailableFilterMetaAttributeNames(MetaArea.Attributes);
		
	CompositionSchema = New DataCompositionSchema;
	DataSource = CompositionSchema.DataSources.Add();
	DataSource.DataSourceType = "Local";
	
	DataSet = CompositionSchema.DataSets.Add(Type("DataCompositionSchemaDataSetQuery"));
	DataSet.Query =  "SELECT " + Mid(AvailableFilterAttributes, 2) + " FROM " +  AreaToSearchForDuplicates;
	DataSet.AutoFillAvailableFields = True;
	
	// Saving schema according to the default form to keep composer data current
	CompositionSchemaAddress = PutToTempStorage(CompositionSchema, UUID);
	
	PrefilterComposer.Initialize(New DataCompositionAvailableSettingsSource(CompositionSchema));
	
	// 3. Creating the rules proposed as default ones for the metadata type
	IgnoredAttributes = New Structure("DeletionMark, Ref, Predefined, PredefinedDataName, IsFolder");
	RulesTable = FormAttributeToValue("SearchRules");
	
	AllCompareOptions.Clear();
	AllCompareOptions.Add("Equal", NStr("en = 'Matches'"));
	AllCompareOptions.Add("Like", NStr("en = 'Matches by similar words'"));

	AddMetaAttributeRules(RulesTable, IgnoredAttributes, AllCompareOptions, MetaArea.StandardAttributes);
	AddMetaAttributeRules(RulesTable, IgnoredAttributes, AllCompareOptions, MetaArea.Attributes);
	
	SetDefaultRuleValues(AreaToSearchForDuplicates, PrefilterComposer, RulesTable);
	
	// 4. Processing applied data
	If AreasToSearchForDuplicates.FindByValue(AreaToSearchForDuplicates).Check Then
		// Has applied functionality
		
		// Empty parameter structure
		DataProcessorObject = FormAttributeToValue("Object");
		DefaultParameters = DataProcessorObject.DefaultAppliedParameters(
			SearchRules.Unload(,"Attribute, Rule"),
			PrefilterComposer
		);
		
		// Calling the applied script
		AreaManager = DataProcessorObject.SearchForDuplicatesAreaManager(AreaToSearchForDuplicates);
		AreaManager.SearchForDuplicatesParameters(DefaultParameters);
		
		// Generating the applied rule string
		AppliedRuleDetails = "";
		For Each Details In DefaultParameters.CompareRestrictions Do
			AppliedRuleDetails = AppliedRuleDetails + Chars.LF + Details.Presentation;
		EndDo;
		AppliedRuleDetails = TrimAll(AppliedRuleDetails);
	EndIf;
	
	RulesTable.Sort("AttributePresentation");
	ValueToFormAttribute(RulesTable, "SearchRules");
EndProcedure
 
&AtServerNoContext

Function AvailableFilterMetaAttributeNames(Val MetaCollection)
	Result = "";
	StorageType = Type("ValueStorage");
	
	For Each MetaAttribute  In MetaCollection Do
		IsStorage = MetaAttribute.Type.ContainsType(StorageType);
		If Not IsStorage Then
			Result = Result + "," + MetaAttribute.Name;
		EndIf
	EndDo;
	
	Return Result;
EndFunction

&AtServerNoContext
Procedure AddMetaAttributeRules(RulesTable, Val Ignore, Val AllCompareOptions, Val MetaCollection)
	
	For Each MetaAttribute  In MetaCollection Do
		If Not Ignore.Property(MetaAttribute.Name) Then
			CompareOptions = ComparisonOptionsForType(MetaAttribute.Type, AllCompareOptions);
			If CompareOptions <> Undefined Then
				// Can be compared
				RulesRow = RulesTable.Add();
				RulesRow.Attribute = MetaAttribute.Name;
				RulesRow.CompareOptions = CompareOptions;
				
				AttributePresentation = MetaAttribute.Synonym;
				RulesRow.AttributePresentation = ?(IsBlankString(AttributePresentation),  MetaAttribute.Name, AttributePresentation);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure
 
&AtServerNoContext
Procedure  SetDefaultRuleValues(Val SearchArea, Val FilterComposer, Val ComparisonRules) 
	
	// Filter rule
	FilterItems = FilterComposer.Settings.Filter.Items;
	FilterItem = FilterItems.Add(Type("DataCompositionFilterItem"));
	FilterItem.Use = True;
	FilterItem.LeftValue = New DataCompositionField("DeletionMark");
	FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem.RightValue = False;;
	
	// Comparison rule, only if there is a description
	Rule = ComparisonRules.Find("Description", "Attribute");
	If Rule <>  Undefined Then
		If Rule.CompareOptions.FindByValue("Like") <> Undefined Then
			Rule.Rule = "Like";
		EndIf;
	EndIf;
	
EndProcedure
 
&AtServerNoContext
Function ComparisonOptionsForType(Val AvailableTypes, Val AllCompareOptions) 
	
	IsStorage = AvailableTypes.ContainsType(Type("ValueStorage"));
	If IsStorage Then  
		// Cannot be compared
		Return Undefined;
	EndIf;
	
	IsString = AvailableTypes.ContainsType(Type("String"));
	IsFixedString = IsString And AvailableTypes.StringQualifiers <> Undefined 
		And AvailableTypes.StringQualifiers.Length <> 0;
		
	If IsString And  Not IsFixedString Then
		// Cannot be compared
		Return Undefined;
	EndIf;
	
	Result = New  ValueList;
	FillPropertyValues(Result.Add(), AllCompareOptions[0]);		//  Matches
	
	If IsString Then
		FillPropertyValues(Result.Add(), AllCompareOptions[1]);	//  Similar
	EndIf;
		
	Return Result;
EndFunction
 
&AtServer

Procedure InitMainParameters()
	
	// Setting rule accounting flag unconditionally
	TakeAppliedRulesIntoAccount = True;
	
	ObjectToProcess = FormAttributeToValue("Object");
	MetaObjectToProcess = ObjectToProcess.Metadata();
	
	IsExternalDataProcessor = Not Metadata.DataProcessors.Contains(MetaObjectToProcess);
	DataProcessorName = ?(IsExternalDataProcessor,  ObjectToProcess.UsedFileName, MetaObjectToProcess.Name);
	BaseFormName = MetaObjectToProcess.FullName() +  ".Form.";
	
	CanExecuteDataProcessorObjectModuleProcedure = Metadata.FindByFullName(
		"Subsystem.StandardSubsystems.Subsystem.BaseFunctionality"
	) <> Undefined;
	
	ObjectToProcess.AreasToSearchForDuplicates(AreasToSearchForDuplicates, True);
EndProcedure

// Generates a formatted string by the following pattern: "Text %1 %2"
//
&AtClientAtServerNoContext
Function RowFormat(Val Template,  
	Val P1 = Undefined, Val P2 = Undefined, Val P3 = Undefined, Val P4 = Undefined, Val P5 = Undefined,
	Val P6 = Undefined, Val P7 = Undefined, Val P8 = Undefined, Val P9 = Undefined
)

	StringPart = New  Array;
	AllowedTypes = New  TypeDescription("String, FormattedString, Picture");
	
	Beginning = 1;
	While True Do
		Particle = Mid(Template, Beginning);
		
		Position = Find(Particle, "%");
		If Position = 0 Then
			StringPart.Add(Particle);
			Break;
		EndIf;
		
		Next = Mid(Particle, Position + 1, 1);
		
		If Next = "1" Then
			Value = P1;
			
		ElsIf Next =  "2" Then
			Value = P2;
			
		ElsIf Next =  "3" Then
			Value = P3;
			
		ElsIf Next =  "4" Then
			Value = P4;
			
		ElsIf Next =  "5" Then
			Value = P5;
			
		ElsIf Next =  "6" Then
			Value = P6;
			
		ElsIf Next =  "7" Then
			Value = P7;
			
		ElsIf Next =  "8" Then
			Value = P8;
			
		ElsIf Next =  "9" Then
			Value = P9;
			
		ElsIf Next =  "%" Then
			Value = "%";
			
		Else
			Value = Undefined;
			Position = Position -  1;
			
		EndIf;
		
		StringPart.Add(Left(Particle,  Position - 1));
		
		If Value <> Undefined Then
			Value = AllowedTypes.AdjustValue(Value);
			If Value <> Undefined Then
				StringPart.Add( Value );
			EndIf;
		EndIf;
		
		Beginning = Beginning + Position + 1;
	EndDo;
	
	Return New FormattedString(StringPart);
EndFunction
 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Step-by-step assistant

&AtServer
Procedure InitWizardScenario()
	
	// 0. No search executed
	AddWizardStep(Items.NoSearchExecutedStep, 
			WizardStepAction("OnActivate", "NoSearchExecutedStepOnActivate",
			WizardStepAction("BeforeNextAction", "NoSearchExecutedStepBeforeNextAction",
			WizardStepAction("BeforeCancelAction", "NoSearchExecutedStepBeforeCancelAction",
		))),
			WizardStepButtons("Back", "", "", False, False, False, 
			WizardStepButtons("Next", NStr("en = 'Find duplicates'") + " >",  NStr("en = 'Find duplicates by the specified criteria'"), True,  True, True,
			WizardStepButtons("Cancel", NStr("en= 'Close'"), NStr("en = 'Cancel search and replacement of duplicates'"),
		)))
	);
	
	// 1. Long search
	AddWizardStep(Items.SearchStep, 
			WizardStepAction("OnActivate", "SearchStepOnActivate",
			WizardStepAction("BeforeCancelAction", "SearchStepBeforeCancelAction",
			WizardStepAction("OnIdleProcess", "SearchStepOnIdleProcess",
		))), 
			WizardStepButtons("Back", "", "", False, False, False, 
			WizardStepButtons("Next", "", "", False, False, False,
			WizardStepButtons("Cancel", NStr("en = 'Abort'"), NStr("en = 'Abort searching for duplicates'"),
		)))
	);
	
	// 2. Search result processing, main item selection
	AddWizardStep(Items.MainItemSelectionStep, 
			WizardStepAction("OnActivate", "MainItemSelectionStepOnActivate",
			WizardStepAction("BeforeCancelAction", "MainItemSelectionStepBeforeCancelAction",
			WizardStepAction("BeforeNextAction", "MainItemSelectionStepBeforeNextAction",
		))),
			WizardStepButtons("Back", "", "", False, False, False,
			WizardStepButtons("Next", NStr("en = 'Delete duplicates'") + " >",  NStr("en = 'Delete duplicates'"), True, True, True,
			WizardStepButtons("Cancel", NStr("en= 'Close'"), NStr("en = 'Cancel search and replacement of duplicates'"),
		)))
	);
	
	// 3. Long duplicate deletion
	AddWizardStep(Items.DeletionStep, 
			WizardStepAction("OnActivate", "DeletionStepOnActivate",
			WizardStepAction("BeforeCancelAction", "DeletionStepBeforeCancelAction",
			WizardStepAction("OnIdleProcess", "DeletionStepOnIdleProcess",
		))), 
			WizardStepButtons("Back", "", "", False, False, False, 
			WizardStepButtons("Next", "", "", False, False, False,
			WizardStepButtons("Cancel", NStr("en = 'Abort'"), NStr("en = 'Abort duplicate deletion'"),
		)))
	);
	
	// 4. Successful deletion
	AddWizardStep(Items.SuccessfulDeletionStep,
			WizardStepAction("OnActivate", "SuccessfulDeletionStepOnActivate",
			WizardStepAction("BeforeBackAction", "SuccessfulDeletionStepBeforeBackAction",
			WizardStepAction("BeforeCancelAction", "SuccessfulDeletionStepBeforeCancelAction",
		))),
			WizardStepButtons("Back", "<" + NStr("en = 'New search'"), NStr("en = 'Start new search with other parameters'"), True,  True, False, 
			WizardStepButtons("Next", "", "", False, False, False,
			WizardStepButtons("Cancel", NStr("en= 'Close'"), NStr("en = 'Close'"), True,  True, True
		)))
	);
	
	// 5. Incomplete deletion
	AddWizardStep(Items.UnsuccessfulReplacementsStep,
			WizardStepAction("OnActivate", "UnsuccessfulReplacementsStepOnActivate",
			WizardStepAction("BeforeNextAction", "UnsuccessfulReplacementsStepBeforeNextAction",
			WizardStepAction("BeforeCancelAction", "UnsuccessfulReplacementsStepBeforeCancelAction",
		))),
			WizardStepButtons("Back", "", "", False, False, False,
			WizardStepButtons("Next", NStr("en = 'Retry deletion'") + " >",  NStr("en = 'Delete duplicates'"), True, True, True,
			WizardStepButtons("Cancel", NStr("en= 'Close'"), NStr("en = 'Close'"), True,  True, False
		)))
	);
	
	// 6. No duplicates found
	AddWizardStep(Items.DuplicatesNotFoundStep,
			WizardStepAction("OnActivate", "DuplicatesNotFoundStepOnActivate",
			WizardStepAction("BeforeNextAction", "DuplicatesNotFoundStepBeforeNextAction",
			WizardStepAction("BeforeCancelAction", "DuplicatesNotFoundStepBeforeCancelAction",
		))),
			WizardStepButtons("Back", "", "", False, False, False,
			WizardStepButtons("Next", NStr("en = 'Find duplicates'") + " >",  NStr("en = 'Find duplicates by the specified criteria'"), True,  True, True,
			WizardStepButtons("Cancel", NStr("en= 'Close'"), NStr("en = 'Close'"), True,  True, False
		)))
	);
	
EndProcedure
 
// 0.  No search executed

&AtClient
Procedure NoSearchExecutedStepOnActivate(Val StepParameters, Val AdditionalParameters) Export
	
	Items.Title.Enabled = True;
	
	UpdateFilterDetails();
	UpdateSearchAreaDetails();
	UpdateSearchRuleDetails();
	
EndProcedure
 
&AtClient

Procedure NoSearchExecutedStepBeforeNextAction(Val StepParameters, Val AdditionalParameters) Export
	
	// Whether the search can be executed
	If Not  IsBlankString(AreaToSearchForDuplicates) Then
		ExitWizardStep(StepParameters);
		Return;
	EndIf;
	
	WarningText = NStr("en = 'Select area to search for duplicates'");
	ShowMessageBox(,  WarningText);
EndProcedure

&AtClient
Procedure  NoSearchExecutedStepBeforeCancelAction(Val StepParameters, Val AdditionalParameters) Export
	// Prompting for cancelation confirmation
	QueryText = NStr("en = 'Do you want to cancel search and replacement of duplicates?'");
	Details = New  NotifyDescription("CancellationCompletionAndFormTermination",  ThisObject, New Structure);
	Details.AdditionalParameters.Insert("StepParameters", StepParameters);
	
	ShowQueryBox(Details, QueryText,  QuestionDialogMode.YesNo);
EndProcedure 
  
// 1. Long search

&AtClient
Procedure SearchStepOnActivate(Val StepParameters, Val AdditionalParameters) Export
	
	Items.Title.Enabled = False;
	
	StartSearchForDuplicatesInBackground();
	
EndProcedure

&AtClient
Procedure  SearchStepOnIdleProcess(Stop, Val AdditionalParameters) Export
	
	// Waiting for searching for duplicates
	ActionState = CheckDuplicateSearchState();
	
	If Not  ActionState.Completed Then
		Return;
	EndIf;
	
	// Execution result
	ErrorDescription = Undefined;
	If ActionState.ErrorInfo <> Undefined Then
		ErrorDescription = ActionState.ErrorInfo;
	ElsIf ActionState.Result = -1 Then
		ErrorDescription =  FoundDuplicateStateDetails;
	EndIf;
	
	If ErrorDescription <> Undefined Then
		Stop = True;
		ShowMessageBox(, ErrorDescription );
		GoToWizardStep(Items.NoSearchExecutedStep, True);
		Return;
	EndIf;
	
	If ActionState.Result <> Undefined And  ActionState.Result >  0 Then
		// Some duplicates found
		WizardStep("Next");
		Return;
	EndIf;
	
	// No duplicates found by the current settings
	GoToWizardStep(Items.DuplicatesNotFoundStep, True);

EndProcedure
 
&AtClient

Procedure  SearchStepBeforeCancelAction(Val StepParameters, Val AdditionalParameters) Export
	// Prompting for cancelation confirmation
	QueryText = NStr("en = 'Do you want to abort searching for duplicates?'");
	Details = New NotifyDescription("CancellationCompletionAndFormTermination", ThisObject, New Structure);
	Details.AdditionalParameters.Insert("StepParameters", StepParameters);
	
	ShowQueryBox(Details, QueryText, QuestionDialogMode.YesNo);
EndProcedure
 
// 2. Search result processing, main item selection


&AtClient
Procedure MainItemSelectionStepOnActivate(Val StepParameters, Val AdditionalParameters) Export
	
	Items.Title.Enabled = True;
	
	// Allowing to repeat the search
	Items.RetrySearch.Visible = True;
	
	ExpandDuplicateGroupHierarchically();
	
EndProcedure

&AtClient

Procedure MainItemSelectionStepBeforeNextAction(Val StepParameters, Val AdditionalParameters) Export
	
	// Denying to repeat the search
	Items.RetrySearch.Visible = False;
	
	ExitWizardStep(StepParameters);
EndProcedure 
  
&AtClient

Procedure  MainItemSelectionStepBeforeCancelAction(Val StepParameters, Val AdditionalParameters) Export
	// Prompting for cancelation confirmation
	QueryText = NStr("en = 'Do you want to close searching for duplicates?'");
	Details = New  NotifyDescription("CancellationCompletionAndFormTermination",  ThisObject, New Structure);
	Details.AdditionalParameters.Insert("StepParameters", StepParameters);
	
	ShowQueryBox(Details, QueryText,  QuestionDialogMode.YesNo);
EndProcedure 
 
// 3. Long deletion


&AtClient
Procedure DeletionStepOnActivate(Val StepParameters, Val AdditionalParameters) Export
	
	Items.Title.Enabled = False;
	
	DeletionParameters = New  Structure;
	DeletionParameters.Insert("DeletionMethod", "Check");
	DeletionParameters.Insert("ReplacementCouples", DuplicateReplacementCouples() );
	
	StartLongWizardAction("BackgroundDuplicateDeletion",   DeletionParameters, True, NStr("en = 'Duplicate deletion'") );
EndProcedure 
 
&AtClient

Procedure DeletionStepOnIdleProcess(Stop, Val AdditionalParameters) Export
	
	// Waiting for searching for duplicates
	ActionState =  CheckDuplicateDeletionState();
	
	If Not ActionState.Completed Then
		Return;
	EndIf;
	
	If ActionState.ErrorInfo = Undefined Then
		// Completed. Data is generated and passed to the attributes
		If ActionState.Result = True Then
			// All duplicate groups are replaced
			WizardStep("Next");
		Else
			// Not all references are replaced
			GoToWizardStep(Items.UnsuccessfulReplacementsStep, True);
		EndIf;
	Else
		// Background job is completed with error
		Stop = True;
		ShowMessageBox(, ActionState.ErrorInfo);
		GoToWizardStep(Items.NoSearchExecutedStep, True);
	EndIf;

EndProcedure
 
&AtClient

Procedure  DeletionStepBeforeCancelAction(Val StepParameters, Val AdditionalParameters) Export
	// Prompting for cancelation confirmation
	QueryText = NStr("en = 'Do you want to abort duplicate deletion?'");
	Details = New  NotifyDescription("CancellationCompletionAndFormTermination",  ThisObject, New Structure);
	Details.AdditionalParameters.Insert("StepParameters", StepParameters);
	
	ShowQueryBox(Details, QueryText,  QuestionDialogMode.YesNo);
EndProcedure

// 4. Successful deletion 
 
&AtClient

Procedure SuccessfulDeletionStepOnActivate(Val StepParameters, Val AdditionalParameters) Export
	
	Items.Title.Enabled = False;
	
EndProcedure 
 
&AtClient

Procedure SuccessfulDeletionStepBeforeBackAction(Val StepParameters, Val AdditionalParameters) Export
	
	// Proceeding to the first step to start processing anew with new parameters
	GoToWizardStep(Items.NoSearchExecutedStep, True);
	
EndProcedure 
 
&AtClient

Procedure SuccessfulDeletionStepBeforeCancelAction(Val StepParameters, Val AdditionalParameters) Export
	
	// Processing complete. Prompting the user for cancellation confirmation.
	QueryText = NStr("en = 'Do you want to close searching for duplicates?'");
	Details = New  NotifyDescription("CancellationCompletionAndFormTermination",  ThisObject, New Structure);
	Details.AdditionalParameters.Insert("StepParameters", StepParameters);
	
	ShowQueryBox(Details, QueryText,  QuestionDialogMode.YesNo);
	
EndProcedure 
 
// 5. Incomplete deletion


&AtClient
Procedure UnsuccessfulReplacementsStepOnActivate(Val StepParameters, Val AdditionalParameters) Export
	
	Items.Title.Enabled = False;
	
EndProcedure 
 
&AtClient

Procedure UnsuccessfulReplacementsStepBeforeNextAction(Val StepParameters, Val AdditionalParameters) Export
	
	// Repeating deletion
	GoToWizardStep(Items.Deletion, True);
	
EndProcedure

&AtClient

Procedure UnsuccessfulReplacementsStepBeforeCancelAction(Val StepParameters, Val AdditionalParameters) Export
	
	// Processing completed unsuccessfully. Prompting the user for cancellation confirmation.
	QueryText = NStr("en = 'Do you want to close searching for duplicates?'");
	Details = New  NotifyDescription("CancellationCompletionAndFormTermination", ThisObject, New Structure);
	Details.AdditionalParameters.Insert("StepParameters", StepParameters);
	
	ShowQueryBox(Details, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

 // 6. No duplicates found


&AtClient
Procedure DuplicatesNotFoundStepOnActivate(Val StepParameters, Val AdditionalParameters) Export
	
	Items.Title.Enabled = True;
	
EndProcedure

&AtClient

Procedure DuplicatesNotFoundStepBeforeNextAction(Val StepParameters, Val AdditionalParameters) Export
	
	// Proceeding to the repeat search
	GoToWizardStep(Items.SearchStep, True);
	
EndProcedure
 
&AtClient

Procedure DuplicatesNotFoundStepBeforeCancelAction(Val StepParameters, Val AdditionalParameters) Export
	
	// Processing completed successfully
	ExitForm();
	
EndProcedure

// Common handler of a nonmodal continuation of cancellation with closing

//
&AtClient
Procedure CancellationCompletionAndFormTermination(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		// Confirming process continuation
		ExitWizardStep(AdditionalParameters.StepParameters);
		Return;
	EndIf;
	
	ExitForm();
EndProcedure
 
&AtClient
Procedure ExitForm(Val PopUpMessageText = Undefined)
	
	CancelLongWizardAction();
	
	If PopUpMessageText <> Undefined Then
		ShowUserNotification( , , PopUpMessageText, Items.Information32);
	EndIf;
	
	// Closing with no extra questions
	FormClosingConfirmation = True;
	Close();
EndProcedure
 
// Common closing confirmation handler

&AtClient
Procedure FormClosingCompletion(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult =  DialogReturnCode.Yes Then
		ExitForm();
	Else 
		FormClosingConfirmation = Undefined;
	EndIf;
EndProcedure
 
 ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Wizard block

// For embedding the wizard functional:
//
// 1) Draw a group with the wizard pages on the form.
// 2) Define three commands for Next, Back, and Cancel actions on the form. Define its handlers
//    as:
//
//     &AtClient
//     Procedure BackWizardStep(Command) 
//       WizardStep("Back");
//     EndProcedure
//
//     &AtClient
//     Procedure NextWizardStep(Command) 
//       WizardStep("Next");
//     EndProcedure
//
//     &AtClient
//     Procedure CancelWizardStep(Command)
//       WizardStep("Cancel");
//     EndProcedure
//
// 3) Add a block of step-by-step assistant methods.
//
// 4) In the server script:
//    - Initialize wizard structures by calling InitWizard with the passed corresponded form
//      items.
//
//    - Create a scenario for processing the serial calls of AddWizardStep. We recommend that
//      you use the following auxiliary functions: WizardStepAction and WizardStepButtons. For
//      example:
//
//      AddWizardStep(Items.TargetItemSelectionStep, 
// 			   WizardStepAction("OnActivate",         "TargetItemSelectionStepOnActivate",
// 			   WizardStepAction("BeforeNextAction",   "TargetItemSelectionStepBeforeNextAction",
// 		  	 WizardStepAction("BeforeCancelAction", "TargetItemSelectionStepBeforeCancelAction",
// 	  	 ))), 
// 		  	 WizardStepButtons("Next", NStr("en = 'Replace'") + " >", True, True, True,
// 	  		 WizardStepButtons("Back", "", False, False, False, 
// 	  		 WizardStepButtons("Cancel", NStr("en = 'Cancel'")
// 	  	 )))
//      ); 
//
// 5) In the client script (usually during opening):
//    - Specify the wizard start page by calling SetWizardStartPage.
//    - Call the start page by calling StartWizard.
//

// Initializes wizard structures.
//
// Parameters:
//  PageGroup    - FormGroup - form item, group of the "page" type that contains wizard step pages.
//  NextButton   - FormButton, CommandBarButton - form item used for the Next button. 
//  BackButton   - FormButton, CommandBarButton - form item used for the Back button.
//  CancelButton - FormButton, CommandBarButton - form item used for the Cancel button.
//
&AtServer
Procedure InitWizard(Val PageGroup, Val NextButton, Val BackButton, Val CancelButton)
	WizardSettings = New Structure;

	WizardSettings.Insert("Steps", New Array);
	WizardSettings.Insert("CurrentStepNumber", 0);
	WizardSettings.Insert("StartPage", Undefined);
	
	// Interface part IDs
	WizardSettings.Insert("PageGroup",    PageGroup.Name);
	WizardSettings.Insert("NextButton",   NextButton.Name);
	WizardSettings.Insert("BackButton",   BackButton.Name);
	WizardSettings.Insert("CancelButton", CancelButton.Name);
	
	// Handler call timeout
	WizardSettings.Insert("LongActionIdleTimeout",  
		?( GetClientConnectionSpeed() = ClientConnectionSpeed.Low, 5, 3) );
		
	// For long action processing
	WizardSettings.Insert("BackgroundJobID");
	WizardSettings.Insert("BackgroundJobResultAddress");
	
	// For storing user parameters
	WizardSettings.Insert("UserParameters", New Map);
	
	AttributesToBeAdded = New Array;
	AttributesToBeAdded.Add( New FormAttribute("StepByStepWizardSettings", New TypeDescription) );
	ChangeAttributes(AttributesToBeAdded);
	
	ThisObject.StepByStepWizardSettings = WizardSettings;
EndProcedure
 
// Adds wizard step. The page order creates according to the order of adding the pages.
//
// Parameters:
//
//  Page    - FormGroup - page-group that contains items of the current page step.
//  Actions - Structure - description of actions available in the current step. Structure
//            fields are:
//             *OnActivate         - String - optional name of the procedure to be executed 
//                                   before the page is activated with the following
//                                   parameters:
//                                    <Page>                 - FormGroup - group page to be
//                                                             activated.
//                                    <AdditionalParameters> - Undefined.
//             *BeforeNextAction   - String - optional name of the procedure to be executed 
//                                   when the Next button is clicked before switching to the 
//                                   next page. The procedure is called with two following
//                                   parameters:
//                                    <StepParameters>       - internal attribute. If the chain 
//                                                             of nonmodal calls is finished 
//                                                             successfully, the last handler
//                                                             must call 
//                                                             ExitWizardStep(StepParameters).
//                                    <AdditionalParameters> - Undefined.
//             *BeforeBackAction   - String - similar to BeforeNextAction, describes the 
//                                   behavior of the Back button.
//             *BeforeCancelAction - String - Similar to BeforeNextAction, describes the
//                                   behavior of the Cancel button.
//
//             *OnIdleProcess      - String - optional name of the procedure to be called with
//                                   the following parameters:
//                                    <Stop>                 - if the value is set to True when 
//                                                             exiting the procedure,
//                                                             periodical calls are stopped.
//                                    <AdditionalParameters> - Undefined.
//  Buttons - Structure - details on current step buttons. Structure fields are:
//             * Next   - Structure - "Next" button details. Fields: Title, Tooltip,
//                        Enabled, Visible, DefaultButton.
//                        The title is substituted for an empty value. The following values are 
//                        the default ones: Title = Next >, Enabled = True, Visible =
//                        True, DefaultButton = False;
//             * Back   - Structure - similarly to the Next button, the default values are:
//                        Title = < Back, Enabled = True, Visible = True, 
//                        DefaultButton = False;
//             * Cancel - Structure - similarly to the Next button, the default values are:
//                        Title = Cancel, Enabled = True, Visible = True,
//                        DefaultButton = False;
// We recommend that you use the following auxiliary methods for creating parameters:
// AddWizardStep, WizardStepAction, WizardStepButton.
//
&AtServer
Procedure AddWizardStep(Val Page,  Val Actions, Val Buttons)
	
	// Default preferences
	StepDetails = New Structure("OnActivate, BeforeNextAction, BeforeBackAction, BeforeCancelAction, OnIdleProcess");
	
	ButtonFields = "Enabled, Visible, DefaultButton, Tooltip";
	
	StepDetails.Insert("NextButton", New Structure(ButtonFields, True, True, True));
	StepDetails.NextButton.Insert("Title", NStr("en='Next'") + " >"  );
	
	StepDetails.Insert("BackButton", New Structure(ButtonFields, True, True, False));
	StepDetails.BackButton.Insert("Title", "<" +  NStr("en='Back'"));
	
	StepDetails.Insert("CancelButton",New Structure(ButtonFields, True, True, False));
	StepDetails.CancelButton.Insert("Title", NStr("en='Cancel'"));
	
	StepDetails.Insert("Page", Page.Name);
	
	// Setting actions
	FillPropertyValues(StepDetails, Actions);
	
	If Buttons.Property("Next") Then
		FillPropertyValues(StepDetails.NextButton, Buttons.Next);
	EndIf;
	If Buttons.Property("Back") Then
		FillPropertyValues(StepDetails.BackButton, Buttons.Back);
	EndIf;
	If Buttons.Property("Cancel") Then
		FillPropertyValues(StepDetails.CancelButton, Buttons.Cancel);
	EndIf;

	ThisObject.StepByStepWizardSettings.Steps.Add(StepDetails);
EndProcedure
 
// Auxiliary creation of a structure that describe the action.
//
// Parameters:
//  ID           - String - action ID, see the AddWizardStep method for details.
//  HandlerName  - String - procedure name, see the AddWizardStep method description for
//                 details.
//  InternalData - Structure - accumulates values.
//
// Returns: Structure - InternalData with extra fields.
&AtServer
Function WizardStepAction(Val ID, Val HandlerName, InternalData = Undefined)
	If InternalData =  Undefined Then
		InternalData = New  Structure;
	EndIf;
	InternalData.Insert(ID, HandlerName);
	Return InternalData;
EndFunction
 
// Auxiliary creation of a structure that describe the button.
//
// Parameters:
// ID            - String - button ID, can be "Next", "Back", "Cancel", see the AddWizardStep
//                 method details.
// Title         - String - button title.
// Tooltip       - String - button tooltip.
// Visible    - Boolean - button representation parameter.
// Enabled       - Boolean - button representation parameter.
// DefaultButton - Boolean - button representation parameter.
// InternalData  - Structure - accumulates values
//
// Returns: Structure - InternalData with extra fields.
//
&AtServer
Function WizardStepButtons(Val ID, Val Title = "", Val ToolTip = "", Val  Visible = True, Val Enabled = True, Val DefaultButton = False, Val  InternalData = Undefined)
	If InternalData =  Undefined Then
		InternalData = New  Structure;
	EndIf;
	
	ButtonDetails = New  Structure;
	ButtonDetails.Insert("Title", Title);
	ButtonDetails.Insert("ToolTip", ?(IsBlankString(ToolTip), Title, ToolTip));
	
	ButtonDetails.Insert("Enabled", Enabled);
	ButtonDetails.Insert("Visible", Visible);
	ButtonDetails.Insert("DefaultButton", DefaultButton);
	
	InternalData.Insert(ID, ButtonDetails);
	Return InternalData;
EndFunction
 
// Sets the start page for an initial wizard run
//
// Parameters:
// StartPage -  Number, String, FormGroup - step number, page-group, or its ID.
//
&AtClient
Procedure SetWizardStartPage(Val Page)
	
	ThisObject.StepByStepWizardSettings.StartPage =  WizardStepNumberByID(Page);
	
EndProcedure
 
// Starts the wizard from the page set with SetWizardStartPage
&AtClient
Procedure StartWizard()
	WizardSettings = ThisObject.StepByStepWizardSettings;
	
	If WizardSettings.StartPage = Undefined Then
		Raise NStr("en = 'The start page must be set before the wizard is started.'");
		
	ElsIf WizardSettings.StartPage = -1 Then
		// Warming up. Checking whether all steps have action handlers
		PossibleActions = New Structure("OnActivate, BeforeNextAction, BeforeBackAction, BeforeCancelAction, OnIdleProcess");
		For Each StepDetails In WizardSettings.Steps Do
			For Each  KeyValue In PossibleActions Do
				ActionName = KeyValue.Key;
				HandlerName = StepDetails[ActionName];
				If Not  IsBlankString(HandlerName)  Then
					Try
						Test = New NotifyDescription(HandlerName, ThisObject);
					Except
						Text = StringFunctionsClientServer.SubstituteParametersInString(
							NStr("en = 'Cannot create the %1 event handler for the %2 page. The %3 procedure is not found.'"),
							ActionName, 
							StepDetails.Page, 
							HandlerName
						);
						Raise Text;
					EndTry;
				EndIf;
			EndDo;
		EndDo;
		
		// Starting the wizard
		GoToWizardStep(WizardSettings.CurrentStepNumber, True);
	Else
		// Everything is disabled by default
		Items[WizardSettings.NextButton].Visible = False;
		Items[WizardSettings.BackButton].Visible = False;
		Items[WizardSettings.CancelButton].Visible = False;
		
		// Deferred start
		ThisObject.StepByStepWizardSettings.CurrentStepNumber =  WizardSettings.StartPage;
		ThisObject.StepByStepWizardSettings.StartPage = -1;
		AttachIdleHandler("StartWizard", 0.1, True);
	EndIf;
EndProcedure
 
// Switching the wizard to the next or previous page.
//
// Parameters:
// CommandCode - String - action ID, can be Next, Back, or Cancel.
//
&AtClient
Procedure WizardStep(Val CommandCode)
	WizardSettings = ThisObject.StepByStepWizardSettings;
	
	If CommandCode = "Next" Then
		Heading = 1;
	ElsIf CommandCode = "Back" Then
		Heading = -1;
	ElsIf CommandCode = "Cancel" Then
		Heading = 0;
	Else
		Raise NStr("en = 'Incorrect assistant step command'");
	EndIf;
		
	StepDetails = WizardSettings.Steps[WizardSettings.CurrentStepNumber];
	
	// Stopping a handler, if any
	If StepDetails.OnIdleProcess <> Undefined Then
		DetachIdleHandler("WizardPageIdleHandler");
	EndIf;
	
	// Processing leaving the current page
	If Heading = 1 Then
		Action = StepDetails.BeforeNextAction;
		
	ElsIf Heading =  -1 Then
		Action = StepDetails.BeforeBackAction;
		
	Else
		Action = StepDetails.BeforeCancelAction;
		
	EndIf;
	
	If IsBlankString(Action) Then
		ExitWizardStep(Heading);
	Else
		Notification = New  NotifyDescription(Action,  ThisObject);
		ExecuteNotifyProcessing(Notification, Heading);
	EndIf;
EndProcedure
 
// Moves to the wizard page unconditionally.
//
// Parameters:
// StepID     -  Number, String, FormGroup - number, form page-group, or its name for switching
// InitEvents -  Boolean - flag that shows whether the events associated with the step
//               activation must be called.
//
&AtClient
Procedure GoToWizardStep(Val StepID, Val InitEvents = False)
	WizardSettings = ThisObject.StepByStepWizardSettings;
	
	NextStep =  WizardStepNumberByID(StepID);
	If NextStep =  Undefined Then
		Error = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'The following wizard step is not found: %1'"),
			StepID
		);
		Raise Error;
	EndIf;
		
	StepDetails = WizardSettings.Steps[WizardSettings.CurrentStepNumber];
	
	// Stopping a handler, if any
	If StepDetails.OnIdleProcess <> Undefined Then
		DetachIdleHandler("WizardPageIdleHandler");
	EndIf;
	
	// Switching to the corresponded page
	UnconditionalCompletionWizardStep(NextStep,  InitEvents);
EndProcedure

// Confirms the wizard step action and switches the page.
//
// Parameters:
// StepParameters - Internal attribute get in the handler before the beginning of the action.
//
&AtClient
Procedure ExitWizardStep(Val StepParameters)
	WizardSettings = ThisObject.StepByStepWizardSettings;
	
	NextStep = WizardSettings.CurrentStepNumber +  StepParameters;
	FinalStep = WizardSettings.Steps.UBound();
	
	If StepParameters =  0 Then
		// Cancellation confirmation - doing nothing
		Return;
		
	ElsIf StepParameters = 1 And  NextStep > FinalStep Then
		// Attempt of doing a step forward outside the limits
		Raise NStr("en='Attempt of going outside the last wizard step'");
		
	ElsIf StepParameters = -1 And NextStep < 0 Then
		// Attempt of doing step back outside the limits
		Raise NStr("en='Attempt of going outside the first wizard step'");
		
	EndIf;
	
	UnconditionalCompletionWizardStep(NextStep);
EndProcedure
 
&AtClient
Procedure UnconditionalCompletionWizardStep(Val NextStep, Val InitEvents = True)
	WizardSettings = ThisObject.StepByStepWizardSettings;
	
	StepDetails = WizardSettings.Steps[NextStep];
	FinalStep = WizardSettings.Steps.UBound();
	
	// Switching to the corresponded page
	Items[WizardSettings.PageGroup].CurrentPage = Items[StepDetails.Page];
	
	// Refreshing buttons
	UpdateWizardButtonProperties(WizardSettings.NextButton, StepDetails.NextButton);
	UpdateWizardButtonProperties(WizardSettings.BackButton, StepDetails.BackButton);
	UpdateWizardButtonProperties(WizardSettings.CancelButton, StepDetails.CancelButton);
	
	// Switched successfully
	ThisObject.StepByStepWizardSettings.CurrentStepNumber = NextStep;
	
	If InitEvents And Not IsBlankString(StepDetails.OnActivate) Then
		// Processing OnActivate of the new page and starting the idle handler
		AttachIdleHandler("WizardPageActivationHandler",  0.1, True);
		
	ElsIf Not  IsBlankString(StepDetails.OnIdleProcess) Then
		// Starting the idle handler, if necessary
		AttachIdleHandler("WizardPageIdleHandler",  0.1, True);
		
	EndIf;
EndProcedure
 
&AtClient
Procedure UpdateWizardButtonProperties(Val ButtonName, Val Details)
	
	WizardButton = Items[ButtonName];
	FillPropertyValues(WizardButton, Details);
	WizardButton.ExtendedTooltip.Title = Details.ToolTip;
	
EndProcedure

&AtClient
Procedure WizardPageActivationHandler()
	WizardSettings = ThisObject.StepByStepWizardSettings;
	
	StepDetails = WizardSettings.Steps[WizardSettings.CurrentStepNumber];
	If Not  IsBlankString(StepDetails.OnActivate) Then
		Notification = New  NotifyDescription(StepDetails.OnActivate, ThisObject);
		ExecuteNotifyProcessing(Notification, Items[StepDetails.Page]);
	EndIf;
	
	// Starting idle processing, if required
	If Not  IsBlankString(StepDetails.OnIdleProcess) Then
		// First run is quick
		AttachIdleHandler("WizardPageIdleHandler",  0.1, True);
	EndIf;
EndProcedure
 
// Can be a step number, a page-group, or its ID.
&AtClient
Function WizardStepNumberByID(Val StepID)
	WizardSettings = ThisObject.StepByStepWizardSettings;
	StepNumber = Undefined;
	
	ParameterType = TypeOf(StepID);
	If ParameterType = Type("Number") Then
		StepNumber = StepID;
	Else
		SearchName = ?(ParameterType = Type("FormGroup"), StepID.Name, StepID); 
		For StepNumber=0 to WizardSettings.Steps.UBound() Do
			If WizardSettings.Steps[StepNumber].Page = SearchName Then
				StepNumber = StepNumber;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	Return StepNumber;
EndFunction
 
// Returns the cancellation flag
&AtClient
Function WizardPageIdleHandler()
	WizardSettings = ThisObject.StepByStepWizardSettings;
	
	StepDetails = WizardSettings.Steps[WizardSettings.CurrentStepNumber];
	Action = StepDetails.OnIdleProcess;
	If IsBlankString(Action) Then
		Return False;
	EndIf;
	
	Notification = New NotifyDescription(Action,  ThisObject);
	
	Stop = False;
	ExecuteNotifyProcessing(Notification, Stop);
	MustContinue = Not Stop;
	
	If MustContinue Then
		AttachIdleHandler("WizardPageIdleHandler",  WizardSettings.LongActionIdleTimeout, True);
	EndIf;
	
	Return MustContinue;
EndFunction
 
// Starts the long wizard action
// 
// Parameters:
// MethodName       - String - background job method name.
// MethodParameters - Array - method parameters for background job.
// ReturnsResult    - Boolean - flag that shows whether the result must be returned. If True,
//                    the result storage address is added as a last call parameter.
// MethodDetails    - String - optional method description to be displayed in the background
//                    job list.
//
&AtServer
Procedure StartLongWizardAction(Val MethodName, Val MethodParameters, Val ReturnsResult = False,  Val MethodDetails = "")
	
	// Possible, a previous unfinished long action is executed. Canceling if any.
	CancelLongWizardAction();
	
	If ReturnsResult Then
		ThisObject.StepByStepWizardSettings.BackgroundJobResultAddress =  PutToTempStorage(Undefined, UUID);
	Else
		ThisObject.StepByStepWizardSettings.BackgroundJobResultAddress =  Undefined;
	EndIf;
	
	InternalParameters = New Structure("AdditionalDataProcessorRef", Undefined);
	InternalParameters.Insert("IsExternalDataProcessor", IsExternalDataProcessor);
	InternalParameters.Insert("DataProcessorName", DataProcessorName);
	InternalParameters.Insert("MethodName", MethodName);
	InternalParameters.Insert("ExecutionParameters", MethodParameters);
	
	 If Not  CanExecuteDataProcessorObjectModuleProcedure Then
		// The job will be started by the direct call
		ThisObject.StepByStepWizardSettings.BackgroundJobID =  InternalParameters;
		Return;
	EndIf;
	
	// Using SL features
	LongActionParameters = New Array;
	LongActionParameters.Add(InternalParameters);
	LongActionParameters.Add(ThisObject.StepByStepWizardSettings.BackgroundJobResultAddress);
	
	Job = BackgroundJobs.Execute("LongActions.ExecuteDataProcessorObjectModule", LongActionParameters, , MethodDetails);
	ThisObject.StepByStepWizardSettings.BackgroundJobID = Job.UUID;
EndProcedure
 
// Gets the state of the current long action.
// 
// Returns: Structure - state details with the following fields:
//                       Completed - Boolean - flag that shows whether the long action is
//                                   active.
//                       ErrorInfo - ErrorInfo - contains error details if the long action job 
//                                   terminated abnormally.
//                       Result    - Arbitrary - if a long action job was started with the 
//                                   return result flag, it contains the current result value.
//
&AtServer
Function LongWizardActionState()
	WizardSettings = ThisObject.StepByStepWizardSettings;
	
	Data = New  Structure("Completed, Result, ErrorInfo", True);

	If WizardSettings.BackgroundJobID = Undefined Then
		Return Data;
		
	ElsIf TypeOf(WizardSettings.BackgroundJobID) <> Type("UUID") Then
		// Deferred execution. It must be executed now.
		ObjectToProcess = FormAttributeToValue("Object");
		
		MethodName = WizardSettings.BackgroundJobID.MethodName;
		ExecutionParameters = WizardSettings.BackgroundJobID.ExecutionParameters;
		ResultAddress = WizardSettings.BackgroundJobResultAddress;
		
		SetSafeMode(True);
		Execute("ObjectToProcess." + MethodName + "(ExecutionParameters, ResultAddress)");
		SetSafeMode(False);
		
		Job = Undefined;
	Else
		// Usual background job
		Job = BackgroundJobs.FindByUUID(WizardSettings.BackgroundJobID);
		
	EndIf;
	
	If Job <>  Undefined Then
		// All unintelligible jobs are completed, see the default values
		If Job.ErrorInfo <> Undefined Then
			Data.ErrorInfo = DetailErrorDescription(Job.ErrorInfo);
		EndIf;
		Data.Completed =  Job.State <> BackgroundJobState.Active;
		If Data.Completed  Then
			// Current background job messages
			AccumulatedMessages = Job.GetUserMessages(True);
			If AccumulatedMessages <> Undefined Then
				For Each Message  In AccumulatedMessages Do
					Message.Message();
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	
	If Not  IsBlankString(WizardSettings.BackgroundJobResultAddress) Then
		Data.Result = GetFromTempStorage(WizardSettings.BackgroundJobResultAddress);
	EndIf;
	
	If Data.Completed  Then
		ThisObject.StepByStepWizardSettings.BackgroundJobID = Undefined;
		ThisObject.StepByStepWizardSettings.BackgroundJobResultAddress =  Undefined;
	EndIf;
	
	Return Data;
EndFunction

// Cancels the current long action
&AtServer
Procedure CancelLongWizardAction()
	WizardSettings = ThisObject.StepByStepWizardSettings;
	
	If WizardSettings.BackgroundJobID <>  Undefined Then 
		Job = BackgroundJobs.FindByUUID(WizardSettings.BackgroundJobID);
		If Job <>  Undefined Then
			Job.Cancel();
		EndIf;
		ThisObject.StepByStepWizardSettings.BackgroundJobID = Undefined;
	EndIf;
	
	ThisObject.StepByStepWizardSettings.BackgroundJobResultAddress =  Undefined;
	
EndProcedure

#EndRegion