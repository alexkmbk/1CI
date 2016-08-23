// The form is parameterized
//
// Parameters:
//     ReferenceList - Array, ValueList - reference set to be analyzed. Can be a collection of 
//                                        items with Ref field.
//
// Confirmation flag used during a nonmodal closing
&AtClient
Var FormClosingConfirmation;

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	If Parameters.Property("SelfTest") Then
		Return;
	EndIf;
	
	// Passing the parameters to the UsageInstances table.
	// Initializing the MainItem, ReferencesToReplaceCommonOwner, and ParameterErrorText
	// attributes.
	InitReferencesToMerge( RefArrayFromSet(Parameters.ReferenceSet) );
	If Not IsBlankString(ParameterErrorText) Then
		// The warning is raised when opening
		Return;
	EndIf;
	
	MetaReference = MainItem.Ref.Metadata();
	
	HasRightsToDeletePermanently = AccessRight("DataAdministration", Metadata) Or AccessRight("InteractiveDelete", MetaReference);
	ReplacementNotificationEvent = DataProcessors.ReferenceReplacement.ReplacementNotificationEvent();
	
	CurrentDeletionOption = "Mark";
	
	InitWizard(Items.WizardSteps, Items.Next, Items.Back, Items.Cancel);
	
	// Adding steps based on the form logic
	InitWizardScenario();
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	// Checking whether an error message is required
	If Not IsBlankString(ParameterErrorText) Then
		Cancel = True;
		ShowMessageBox(, ParameterErrorText);
		Return;
	EndIf;
	
	// Specifying the start page
	SetWizardStartPage(Items.SearchForUsageInstancesStep);
	StartWizard();
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	// Checking the client variable
	If FormClosingConfirmation<>True Then
		Notification = New NotifyDescription("FormClosingCompletion", ThisObject);
		Cancel = True;
		
		Text = NStr("en = 'Do you want to close item merging?'");
		ShowQueryBox(Notification, Text, QuestionDialogMode.YesNo);
	EndIf;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// FORM HEADER EVENT HANDLERS

&AtClient
Procedure MainItemSelectionToolTipURLProcessing(Item, URLValue, StandardProcessing)
	StandardProcessing = False;
	
	If URLValue = "DeletionModeSwitching" Then
		If CurrentDeletionOption = "Directly" Then
			CurrentDeletionOption = "Mark" 
		Else
			CurrentDeletionOption = "Directly" 
		EndIf;
		GenerateMergingTooltip();
	EndIf;
	
EndProcedure

#EndRegion

#Region UsageInstancesFormTableItemEventHandlers

&AtClient
Procedure UsageInstancesChoice(Item, SelectedRow, Field, StandardProcessing)
	StandardProcessing = False;
	Ref = UsageInstances.FindByID(SelectedRow).Ref;
	
	If Field <> Items.UsageInstancesUsageCount Then
		ShowValue(, Ref);
		Return;
	EndIf;
	
	ReferenceSet = New Array;
	ReferenceSet.Add(Ref);
	
	StandardSubsystemsClient.ShowUsageInstances(ReferenceSet);
EndProcedure

&AtClient
Procedure UsageInstancesBeforeAddRow(Item, Cancel, Clone, Parent, Group)
	Cancel = True;
	If Clone Then
		Return;
	EndIf;
	
	// Always adding the item of the same type as the main one
	SelectionFormName = SelectionFormNameByReference(MainItem);
	If Not IsBlankString(SelectionFormName) Then
		FormParameters = New Structure("Multiselect", True);
		If ReferencesToReplaceCommonOwner <> Undefined Then
			FormParameters.Insert("Filter", New Structure("Owner", ReferencesToReplaceCommonOwner));
		EndIf;
		OpenForm(SelectionFormName, FormParameters, Item);
	EndIf;
EndProcedure

&AtClient
Procedure UsageInstancesBeforeDelete(Item, Cancel)
	Cancel = True;
	
	CurrentData = Item.CurrentData;
	If CurrentData=Undefined Or UsageInstances.Count()<3 Then
		Return;
	EndIf;
	
	Ref = CurrentData.Ref;
	Code    = String(CurrentData.Code);
	
	QueryText = StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en = 'Do you want to delete %1 from the list of items to be merged?'"),
		String(Ref) + ?(IsBlankString(Code), "", " (" + Code + ")" )
	);
	
	Notification = New NotifyDescription("UsageInstancesBeforeDeleteEnd", ThisObject, New Structure);
	Notification.AdditionalParameters.Insert("CurrentRow", Item.CurrentRow);
	ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
EndProcedure

&AtClient
Procedure UsageInstancesChoiceProcessing(Item, SelectedValue, StandardProcessing)
	StandardProcessing = False;
	
	If TypeOf(SelectedValue) = Type("Array") Then
		ToAdd = SelectedValue;
	Else
		ToAdd = New Array;
		ToAdd.Add(SelectedValue);
	EndIf;
	
	AddUsageInstancesRows(ToAdd);
	GenerateMergingTooltip();
EndProcedure

#EndRegion

#Region UnsuccessfulReplacementsFormTableItemEventHandlers

&AtClient
Procedure UnsuccessfulReplacementsOnActivateRow(Item)
	CurrentData = Item.CurrentData;
	If CurrentData = Undefined Then
		UnsuccessReasonDetails = "";
	Else
		UnsuccessReasonDetails = CurrentData.DetailedReason;
	EndIf;
EndProcedure

&AtClient
Procedure UnsuccessfulReplacementsCase(Item, SelectedRow, Field, StandardProcessing)
	StandardProcessing = False;
	
	Ref = UnsuccessfulReplacements.FindByID(SelectedRow).Ref;
	If Ref<>Undefined Then
		ShowValue(, Ref);
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandHandlers

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

&AtClient
Procedure OpenUsageInstancesItem(Command)
	CurrentData = Items.UsageInstances.CurrentData;
	If CurrentData <> Undefined Then
		ShowValue(, CurrentData.Ref);
	EndIf;
EndProcedure

&AtClient
Procedure AllUsageInstances(Command)
	
	If UsageInstances.Count() > 0 Then 
		StandardSubsystemsClient.ShowUsageInstances(UsageInstances);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetAsMain(Command)
	CurrentData = Items.UsageInstances.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	MainItem = CurrentData.Ref;
	GenerateMergingTooltip();
EndProcedure

&AtClient
Procedure OpenUnsuccessfulReplacementItem(Command)
	CurrentData = Items.UnsuccessfulReplacements.CurrentData;
	If CurrentData <> Undefined Then
		ShowValue(, CurrentData.Ref);
	EndIf;
EndProcedure

&AtClient
Procedure ExpandAllUnsuccessfulReplacements(Command)
	FormTree = Items.UnsuccessfulReplacements;
	For Each Item In UnsuccessfulReplacements.GetItems() Do
		FormTree.Expand(Item.GetID(), True);
	EndDo;
EndProcedure

&AtClient
Procedure CollapseAllUnsuccessfulReplacements(Command)
	FormTree = Items.UnsuccessfulReplacements;
	For Each Item In UnsuccessfulReplacements.GetItems() Do
		FormTree.Collapse(Item.GetID());
	EndDo;
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsageInstancesMain.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsageInstances.Ref");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("MainItem");

	Item.Appearance.SetParameterValue("Show", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsageInstancesRefs.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsageInstancesCode.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsageInstancesUsageCount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsageInstances.Ref");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("MainItem");

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , True, False, False, False, ));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsageInstancesNotUsed.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsageInstances.UsageCount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.LessOrEqual;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("Visible", True);
	Item.Appearance.SetParameterValue("Show", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsageInstancesNotUsed.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsageInstances.UsageCount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("Visible", False);
	Item.Appearance.SetParameterValue("Show", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsageInstancesUsageCount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsageInstances.UsageCount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.LessOrEqual;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("Visible", False);
	Item.Appearance.SetParameterValue("Show", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UnsuccessfulReplacementsCode.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UnsuccessfulReplacements.Code");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsageInstancesUsageCount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsageInstances.UsageCount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("Visible", True);
	Item.Appearance.SetParameterValue("Show", True);

EndProcedure

&AtServer
Procedure InitReferencesToMerge(Val RefArray)
	
	CheckResult = ValidateReferencesToMerge(RefArray);
	ParameterErrorText = CheckResult.Error;
	If Not IsBlankString(ParameterErrorText) Then
		Return;
	EndIf;
	
	MainItem = RefArray[0];
	ReferencesToReplaceCommonOwner = CheckResult.CommonOwner;
	
	UsageInstances.Clear();
	For Each Item In RefArray Do
		UsageInstances.Add().Ref = Item;
	EndDo;
EndProcedure

&AtServerNoContext 
Function ValidateReferencesToMerge(Val ReferenceSet)
	
	Result = New Structure("Error, CommonOwner");
	
	ReferenceCount = ReferenceSet.Count();
	If ReferenceCount < 2 Then
		Result.Error = NStr("en = 'Select more then one item to be merged.'");
		Return Result;
	EndIf;
	
	FirstItem = ReferenceSet[0];
	
	BasicMetadata = FirstItem.Metadata();
	Characteristics= New Structure("Owners, Hierarchical, HierarchyType", New Array, False);
	FillPropertyValues(Characteristics, BasicMetadata);
	
	HasOwners = Characteristics.Owners.Count() > 0;
	HasFolders    = Characteristics.Hierarchical And Characteristics.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems;
	
	AdditionalFields = "";
	If HasOwners Then
		AdditionalFields = AdditionalFields + ", Owner AS Owner";
	Else
		AdditionalFields = AdditionalFields + ", Undefined AS Owner";
	EndIf;
	
	If HasFolders Then
		AdditionalFields = AdditionalFields + ", IsFolder AS IsFolder";
	Else
		AdditionalFields = AdditionalFields + ", FALSE AS IsFolder";
	EndIf;
	
	TableName = BasicMetadata.FullName();
	Query = New Query("
		|SELECT Ref AS Ref" + AdditionalFields + " INTO ReferencesToReplace
		|FROM " + TableName + " WHERE Ref IN (&ReferenceSet) 
		|INDEX BY Owner, IsFolder
		|;
		|SELECT
		|	COUNT(DISTINCT Owner) AS OwnerCount,
		|	MIN(Owner)            AS CommonOwner,	
		|	MAX(IsFolder)         AS HasFolders,
		|	COUNT(Ref)            AS ReferenceCount
		|FROM
		|	ReferencesToReplace
		|");
	Query.SetParameter("ReferenceSet", ReferenceSet);
	
	Control = Query.Execute().Unload()[0];
	If Control.HasFolders Then
		Result.Error = NStr("en = 'One of the items to be merged is a group.
		                              |Groups cannot be merged.'");
	ElsIf Control.OwnerCount > 1 Then 
		Result.Error = NStr("en = 'The items to be merged have different owners.
		                              |Such items cannot be merged.'");
	ElsIf Control.ReferenceCount <> ReferenceCount Then
		Result.Error = NStr("en = 'All items to be merged must be of the same type.'");
	Else 
		// Successfully
		Result.CommonOwner = ?(HasOwners, Control.CommonOwner, Undefined);
	EndIf;
	
	Return Result;
EndFunction

// Common closing confirmation handler
&AtClient
Procedure FormClosingCompletion(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult = DialogReturnCode.Yes Then
		ExitForm();
	Else 
		FormClosingConfirmation = Undefined;
	EndIf;
EndProcedure

// Reference row deletion confirmation handler
&AtClient
Procedure UsageInstancesBeforeDeleteEnd(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	// Actual deletion from the table
	Row = UsageInstances.FindByID(AdditionalParameters.CurrentRow);
	If Row = Undefined Then
		Return;
	EndIf;
	
	DeletedRowIndex = UsageInstances.IndexOf(Row);
	CalculateMain   = Row.Ref = MainItem;
	
	UsageInstances.Delete(Row);
	If CalculateMain Then
		LatestRowIndex = UsageInstances.Count() - 1;
		If DeletedRowIndex <= LatestRowIndex Then 
			MainRowIndex = DeletedRowIndex;
		Else
			MainRowIndex = LatestRowIndex;
		EndIf;
			
		MainItem = UsageInstances[MainRowIndex].Ref;
	EndIf;
	
	GenerateMergingTooltip();
EndProcedure

&AtClient
Procedure ExitForm(Val PopUpMessageText = Undefined)
	
	CancelLongWizardAction();
	
	If PopUpMessageText <> Undefined Then
		ShowUserNotification( , , PopUpMessageText, PictureLib.Information32);
	EndIf;
	
	// Closing with no extra questions
	FormClosingConfirmation = True;
	Close();
EndProcedure

&AtServer
Procedure GenerateMergingTooltip()
	
	If HasRightsToDeletePermanently Then
		If CurrentDeletionOption = "Mark" Then
			HyperlinkText = NStr("en = 'marked for deletion'");
		Else
			HyperlinkText = NStr("en = 'deleted permanently'");
		EndIf;
		
		Hyperlink = FormattedStringHyperlink(HyperlinkText, 
			"DeletionModeSwitching");
	Else
		Hyperlink = NStr("en = 'marked for deletion'");
	EndIf;

	Items.ItemMainSelectionTipTool.Title = FormattedString(
		NStr("en = 'Merging items (%1) into %2.
		           |All items from the list will be %3 and replaced with %2 (marked with arrow) in all places where they are used.'"),
		UsageInstances.Count(),
		MainItem,
		Hyperlink
	);
	
EndProcedure

&AtClient
Function GenerateCompletionLabel()
	
	ResultText = StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en = 'Items (%1) have been merged into %2'"),
		UsageInstances.Count(),
		MainItem
	);
	
	Items.MergingResult.Title = ResultText;
	
	Return ResultText;
EndFunction

&AtClient
Procedure GenerateUnsuccessfulReplacementLabel()
	
	Items.ResultUnsuccessfulReplacements.Title = StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en = '%1 of %2 items cannot be merged. In some places %3 cannot be substituted automatically."),
		UnsuccessfulReplacements.GetItems().Count(),
		UsageInstances.Count(),
		MainItem
	);
	
EndProcedure

// Parameters:
//     DataList - Array - contains the modified data, whose type information is notified.
//
&AtClient
Procedure NotifySuccessfulReplacement(Val DataList)
	// Changing items
	TypeList = New Map;
	For Each Item In DataList Do
		Type = TypeOf(Item);
		If TypeList[Type] = Undefined Then
			NotifyChanged(Type);
			TypeList.Insert(Type, True);
		EndIf;
	EndDo;
	
	// Common notification
	If TypeList.Count()>0 Then
		Notify(ReplacementNotificationEvent, , ThisObject);
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------------------
&AtServer
Procedure StartFillingUsageInstances()
	
	FullNameMethod = "CommonUse.InstanceCountCalculatingInBackground";
	MethodParameters = New Array;
	MethodParameters.Add( RefArrayFromSet(UsageInstances) );
	
	StartLongWizardAction(FullNameMethod, MethodParameters, True);
EndProcedure

&AtServer
Function ValidateStateAndHandleUsageInstanceFilling();
	ActionState = LongWizardActionState();
	
	If ActionState.Completed And ActionState.ErrorInfo = Undefined Then
		FillUsageInstances(ActionState.Result);
	EndIf;
	
	// The result are always processed, no need to inform the client
	ActionState.Result = Undefined;
	
	Return ActionState;
EndFunction

&AtServer
Procedure FillUsageInstances(Val UsageTable)
	
	NewUsageInstances = UsageInstances.Unload();
	NewUsageInstances.Indexes.Add("Ref");
	
	IsUpdate = NewUsageInstances.Find(MainItem, "Ref") <> Undefined;
	
	If Not IsUpdate Then
		NewUsageInstances = UsageInstances.Unload(New Array);
		NewUsageInstances.Indexes.Add("Ref");
	EndIf;
	
	MetadataCache = New Map;
	
	MaxReference = Undefined;
	MaxInstances   = -1;
	For Each Row In UsageTable Do
		Ref = Row.Ref;
		
		UseRow = NewUsageInstances.Find(Ref, "Ref");
		If UseRow = Undefined Then
			UseRow = NewUsageInstances.Add();
			UseRow.Ref = Ref;
		EndIf;
		
		Instances = Row.Entries;
		If Instances>MaxInstances Then
			MaxReference = Ref;
			MaxInstances = Instances;
		EndIf;
		
		UseRow.UsageCount = Instances;
		UseRow.Code      = PossibleReferenceCode(Ref, MetadataCache);
		UseRow.Owner = PossibleReferenceOwner(Ref, MetadataCache);
		
		UseRow.NotUsed = ?(Instances = 0, NStr("en = 'not used'"), "");
	EndDo;
	
	UsageInstances.Load(NewUsageInstances);
	
	If IsUpdate Then
		If NewUsageInstances.Find(MainItem, "Ref") = Undefined Then
			MainItem = MaxReference;
		EndIf;
	Else
		MainItem = MaxReference;
	EndIf;
	
	// Refreshing headings
	Presentation = ?(MainItem=Undefined, "", MainItem.Metadata().Presentation());
	
	TitleText = StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en = 'Merging %1 items into single one'"),
		Presentation
	);
EndProcedure

// --------------------------------------------------------------------------------------------
&AtServer
Procedure StartReferenceReplacement()
	
	FullNameMethod = "CommonUse.ReplaceReferences";
	MethodParameters = New Array;
	
	ReplacementCouples = New Map;
	For Each Row In UsageInstances Do
		ReplacementCouples.Insert(Row.Ref, MainItem);
	EndDo;
	MethodParameters.Add(ReplacementCouples);
	
	ReplacementParameters = New Structure;
	ReplacementParameters.Insert("DeletionMethod", CurrentDeletionOption);
	ReplacementParameters.Insert("ConsiderBusinessLogic", True);
	
	MethodParameters.Add(ReplacementParameters);
	
	StartLongWizardAction(FullNameMethod, MethodParameters, True);
EndProcedure

&AtServer
Function ValidateStateAndHandleReferenceReplacement()
	ActionState = LongWizardActionState();
	
	If Not ActionState.Completed Then
		// Do not passing the state to the client yet
		ActionState.Result = Undefined;
		
	ElsIf ActionState.ErrorInfo <> Undefined Then
		// Completed with errors
		ActionState.Result = Undefined;
		
	ElsIf ActionState.Completed And ActionState.Result <> Undefined Then
		// Moving all errors to UnsuccessfulReplacement and getting a flag that shows whether they exist
		ActionState.Result = Not FillUnsuccessfulReplacements(ActionState.Result);
		
	EndIf;
	
	Return ActionState;
EndFunction

&AtServer
Function FillUnsuccessfulReplacements(Val ReplacementResults)
	// ReplacementResults - table with the following columns: Ref, ErrorObject, ErrorType, ErrorText.
	RootRows = UnsuccessfulReplacements.GetItems();
	RootRows.Clear();
	
	RowMap        = New Map;
	MetadataCache = New Map;
	
	For Each ResultRow In ReplacementResults Do
		Ref = ResultRow.Ref;
		
		ErrorsByReference = RowMap[Ref];
		If ErrorsByReference = Undefined Then
			TreeRow = RootRows.Add();
			TreeRow.Ref  = Ref;
			TreeRow.Data = String(Ref);
			TreeRow.Code = String( PossibleReferenceCode(Ref, MetadataCache) );
			TreeRow.Icon = -1;
			
			ErrorsByReference = TreeRow.GetItems();
			RowMap.Insert(Ref, ErrorsByReference);
		EndIf;
		
		ErrorString = ErrorsByReference.Add();
		ErrorString.Ref  = ResultRow.ErrorObject;
		ErrorString.Data = ResultRow.ErrorObjectPresentation;
		
		ErrorType = ResultRow.ErrorType;
		If ErrorType = "UnknownData" Then
			ErrorString.Reason = NStr("en = 'Data not planned to be processed are found.'");
			
		ElsIf ErrorType = "LockError" Then
			ErrorString.Reason = NStr("en = 'Another user locked the data'");
			
		ElsIf ErrorType = "DataChanged" Then
			ErrorString.Reason = NStr("en = 'Another user changed the data.'");
			
		ElsIf ErrorType = "WritingError" Then
			ErrorString.Reason = ResultRow.ErrorText;
			
		ElsIf ErrorType = "DeletionError" Then
			ErrorString.Reason = NStr("en = 'Cannot delete data.'");
			
		Else
			ErrorString.Reason = NStr("en = 'Unknown error.'");
			
		EndIf;
		
		ErrorString.DetailedReason = ResultRow.ErrorText;
	EndDo; // replacement results
	
	Return RootRows.Count() > 0;
EndFunction

// --------------------------------------------------------------------------------------------

&AtServerNoContext
Function SelectionFormNameByReference(Val Ref)
	Meta = Metadata.FindByType(TypeOf(Ref));
	Return ?(Meta = Undefined, Undefined, Meta.FullName() + ".ChoiceForm");
EndFunction

// Converts an array, value list, or collection into an array.
//
&AtServerNoContext
Function RefArrayFromSet(Val References)
	
	ParameterType = TypeOf(References);
	If References = Undefined Then
		RefArray = New Array;
		
	ElsIf ParameterType  = Type("ValueList") Then
		RefArray = References.UnloadValues();
		
	ElsIf ParameterType = Type("Array") Then
		RefArray = References;
		
	Else
		RefArray = New Array;
		For Each Item In References Do
			RefArray.Add(Item.Ref);
		EndDo;
		
	EndIf;
	
	Return RefArray;
EndFunction

// Adds an array of references
&AtServer
Procedure AddUsageInstancesRows(Val RefArray)
	LastIndex = Undefined;
	MetadataCache    = New Map;
	
	Filter = New Structure("Ref");
	For Each Ref In RefArray Do
		Filter.Ref = Ref;
		ExistingRows = UsageInstances.FindRows(Filter);
		If ExistingRows.Count() = 0 Then
			Row = UsageInstances.Add();
			Row.Ref = Ref;
			
			Row.Code  = PossibleReferenceCode(Ref, MetadataCache);
			Row.Owner = PossibleReferenceOwner(Ref, MetadataCache);
			
			Row.UsageCount = -1;
			Row.NotUsed    = NStr("en = 'Not calculated'");
		Else
			Row = ExistingRows[0];
		EndIf;
		
		LastIndex = Row.GetID();
	EndDo;
	
	If LastIndex <> Undefined Then
		Items.UsageInstances.CurrentRow = LastIndex;
	EndIf;
EndProcedure

// Returns:
//     Arbitrary - catalog code and so on if the metadata has a code,
//     Undefined - if there is no code.
//
&AtServerNoContext
Function PossibleReferenceCode(Val Ref, MetadataCache)
	Data = MetaDetailsByReference(Ref, MetadataCache);
	Return ?(Data.HasCode, Ref.Code, Undefined);
EndFunction

// Returns:
//     Arbitrary - catalog owner if it exists (by metadata), 
//     Undefined - if there is no owner.
//
&AtServerNoContext
Function PossibleReferenceOwner(Val Ref, MetadataCache)
	Data = MetaDetailsByReference(Ref, MetadataCache);
	Return ?(Data.HasOwner, Ref.Owner, Undefined);
EndFunction

// Returns the details on the catalog and so on by metadata
&AtServerNoContext
Function MetaDetailsByReference(Val Ref, MetadataCache)
	
	Meta = Ref.Metadata();
	Data = MetadataCache[Meta];
	
	If Data = Undefined Then
		Test = New Structure("CodeLength, Owners", 0, New Array);
		FillPropertyValues(Test, Meta);
		
		Data = New Structure;
		Data.Insert("HasCode", Test.CodeLength > 0);
		Data.Insert("HasOwner", Test.Owners.Count() > 0);
		
		MetadataCache[Meta] = Data;
	EndIf;
	
	Return Data;
EndFunction

// Returns a list of replaced references that are not in UnsuccessfulReplacements
&AtClient
Function DeleteProcessedItemsFromUsageInstances()
	Result = New Array;
	
	unsuccessful = New Map;
	For Each Row In UnsuccessfulReplacements.GetItems() Do
		unsuccessful.Insert(Row.Ref, True);
	EndDo;
	
	Index = UsageInstances.Count() - 1;
	While Index > 0 Do
		Ref = UsageInstances[Index].Ref;
		If Ref<>MainItem And unsuccessful[Ref] = Undefined Then
			UsageInstances.Delete(Index);
			Result.Add(Ref);
		EndIf;
		Index = Index - 1;
	EndDo;
	
	Return Result;
EndFunction

// Checks whether items can be replaced from an applied perspective
&AtServer
Function PossibleReferenceReplacementErrorText()
	
	ReferenceSet = New Array;
	ReplacementCouples   = New Map;
	For Each Row In UsageInstances Do
		ReferenceSet.Add(Row.Ref);
		ReplacementCouples.Insert(Row.Ref, MainItem);
	EndDo;
	
	// Checking one more time, maybe the set is modified.
	Control = ValidateReferencesToMerge(ReferenceSet);
	If Not IsBlankString(Control.Error) Then
		Return Control.Error;
	EndIf;
	
	// Applied test if it is defined
	
	// Determining the object manager by the reference
	ManagerModule = CommonUse.ObjectManagerByRef(MainItem);
	
	// Checking whether manager has the method
	Try
		HasMethod = (True = ManagerModule.UseItemReplacement());
	Except
		HasMethod = False;
	EndTry;
	
	Result = "";
	
	If HasMethod Then
		ReplacementParameters = New Structure("DeletionMethod", CurrentDeletionOption);
		Errors = ManagerModule.CanReplaceItems(ReplacementCouples, ReplacementParameters);
		For Each KeyValue In Errors Do
			Result = Result + Chars.LF + KeyValue.Value;
		EndDo;
	EndIf;
	
	Return TrimAll(Result);
	
EndFunction

// --------------------------------------------------------------------------------------------
// Common handler of a nonmodal continuation of cancellation with closing
&AtClient
Procedure CancellationCompletionAndFormTermination(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		// Confirming process continuation
		ExitWizardStep(AdditionalParameters.StepParameters);
		Return;
	EndIf;
	
	ExitForm();
EndProcedure

// Analog of SubstituteParametersInString for processing formatted strings
Function FormattedString(Val Template, 
	Val P1 = Undefined, Val P2 = Undefined, Val P3 = Undefined, Val P4 = Undefined, Val P5 = Undefined,
	Val P6 = Undefined, Val P7 = Undefined, Val P8 = Undefined, Val P9 = Undefined
)

	StringPart = New Array;
	AllowedTypes = New TypeDescription("String, FormattedString, Picture");
	
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
			
		ElsIf Next = "2" Then
			Value = P2;
			
		ElsIf Next = "3" Then
			Value = P3;
			
		ElsIf Next = "4" Then
			Value = P4;
			
		ElsIf Next = "5" Then
			Value = P5;
			
		ElsIf Next = "6" Then
			Value = P6;
			
		ElsIf Next = "7" Then
			Value = P7;
			
		ElsIf Next = "8" Then
			Value = P8;
			
		ElsIf Next = "9" Then
			Value = P9;
			
		ElsIf Next = "%" Then
			Value = "%";
			
		Else
			Value = Undefined;
			Position  = Position - 1;
			
		EndIf;
		
		StringPart.Add(Left(Particle, Position - 1));
		
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

Function FormattedStringHyperlink(Val Text, Val ID = Undefined)
	
	Return New FormattedString(Text, , , , ID);
	
EndFunction
 
// --------------------------------------------------------------------------------------------
// Working with wizard

&AtServer
Procedure InitWizardScenario()
	
	// 0. Searching for usage instances by parameters
	AddWizardStep(Items.SearchForUsageInstancesStep, 
			WizardStepAction("OnActivate",         "SearchForUsageInstancesStepOnActivate",
			WizardStepAction("BeforeCancelAction", "SearchForUsageInstancesStepBeforeCancelAction",
			WizardStepAction("OnIdleProcess",      "SearchForUsageInstancesStepOnIdleProcess",
		))), 
			WizardStepButtons("Next",   "", "", False, False, False, 
			WizardStepButtons("Back", "", "", False, False, False, 
			WizardStepButtons("Cancel", NStr("en = 'Abort'"), NStr("en = 'Cancel item merging'"),
		)))
	);
	
	// 1. Main item selection
	AddWizardStep(Items.MainItemSelectionStep, 
			WizardStepAction("OnActivate",         "MainItemSelectionStepOnActivate",
			WizardStepAction("BeforeNextAction",   "MainItemSelectionStepBeforeNextAction",
			WizardStepAction("BeforeCancelAction", "MainItemSelectionStepBeforeCancelAction",
		))), 
			WizardStepButtons("Next", NStr("en = 'Merge'") + " >", NStr("en = 'Start item merging'"), True, True, True,
			WizardStepButtons("Back", "", "", False, False, False, 
			WizardStepButtons("Cancel", NStr("en = 'Cancel'"),  NStr("en = 'Cancel item merging'"),
		)))
	);
	
	// 2. Waiting for process
	AddWizardStep(Items.MergingStep, 
			WizardStepAction("OnActivate",         "MergingStepOnActivate",
			WizardStepAction("BeforeCancelAction", "MergingStepBeforeCancelAction",
			WizardStepAction("OnIdleProcess",      "MergingStepOnIdleProcess",
		))), 
			WizardStepButtons("Next", "", "", False, False, False,
			WizardStepButtons("Back", "", "", False, False, False,
			WizardStepButtons("Cancel", NStr("en = 'Abort'"), NStr("en = 'Abort item merging'"),
		)))
	);
	
	// 3. Successful merging
	AddWizardStep(Items.SuccessfulEndStep, 
			WizardStepAction("OnActivate",         "SuccessfulEndStepOnActivate",
			WizardStepAction("BeforeCancelAction", "SuccessfulEndStepBeforeCancelAction",
		)), 
			WizardStepButtons("Next", "", "", False, False, False, 
			WizardStepButtons("Back", "", "", False, False, False, 
			WizardStepButtons("Cancel", NStr("en = 'Close'"), NStr("en = 'Close merging results'"), True,  True,  True,
		)))
	);
	
	// 4. Reference replacement errors
	AddWizardStep(Items.StepRepeatMerge,
			WizardStepAction("OnActivate",         "RepeatMergingStepOnActivate",
			WizardStepAction("BeforeNextAction",   "RepeatMergingStepBeforeNextAction",
			WizardStepAction("BeforeBackAction",   "RepeatMergingStepBeforeBackAction",
			WizardStepAction("BeforeCancelAction", "RepeatMergingStepBeforeCancelAction",
		)))), 
			WizardStepButtons("Next", NStr("en = 'Retry merging'") + " >", NStr("en = 'Retry merging'"),  True, True, True, 
			WizardStepButtons("Back", "<" + NStr("en = 'Back'"), NStr("en = 'Return to the main item selection'"), True, True, False,
			WizardStepButtons("Cancel", NStr("en = 'Close'"), NStr("en = 'Close merging results'"),
		)))
	);
	
	// Exit option: setting the flag that shows whether the exit confirmation page or showing a
	// pop-up window. 
	SetWizardUserParameter(ThisObject, "PopUpSuccessMessageWindow", True);
EndProcedure

// --------------------------------------------------------------------------------------------
&AtClient
Procedure SearchForUsageInstancesStepOnActivate(Val Page, Val AdditionalParameters) Export
	// Starting long processing
	StartFillingUsageInstances();
EndProcedure

&AtClient
Procedure SearchForUsageInstancesStepOnIdleProcess(Stop, Val AdditionalParameters) Export
	// Waiting for completion of the reference search
	ActionState = ValidateStateAndHandleUsageInstanceFilling();
	
	If ActionState.Completed Then
		If ActionState.ErrorInfo = Undefined Then
			// Done, proceeding to the next step
			WizardStep("Next");
		Else
			Stop = True;
			ShowMessageBox(, ActionState.ErrorInfo);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SearchForUsageInstancesStepBeforeCancelAction(Val StepParameters, Val AdditionalParameters) Export
	
	// Prompting for cancelation confirmation
	QueryText = NStr("en = 'Do you want to abort searching for usage instances and close the window?'");
	Details = New NotifyDescription("CancellationCompletionAndFormTermination", ThisObject, New Structure);
	Details.AdditionalParameters.Insert("StepParameters", StepParameters);
	
	ShowQueryBox(Details, QueryText, QuestionDialogMode.YesNo);
EndProcedure

// --------------------------------------------------------------------------------------------
&AtClient
Procedure MainItemSelectionStepOnActivate(Val Page, Val AdditionalParameters) Export
	
	GenerateMergingTooltip();
	
EndProcedure

&AtClient
Procedure MainItemSelectionStepBeforeNextAction(Val StepParameters, Val AdditionalParameters) Export
	
	// Checking whether the items can be merged from the applied point of view
	ErrorText = PossibleReferenceReplacementErrorText();
	
	If IsBlankString(ErrorText) Then
		// All replacements are valid
		ExitWizardStep(StepParameters);
		Return;
	EndIf;
	
	WarningParameters = New Structure;
	WarningParameters.Insert("Title", NStr("en = 'Cannot merge items'"));
	WarningParameters.Insert("MessageText", ErrorText);
	OpenForm("DataProcessor.ReferenceReplacement.Form.MultilineMessageBox", WarningParameters, ThisObject);
	Return;
	
EndProcedure

&AtClient
Procedure MainItemSelectionStepBeforeCancelAction(Val StepParameters, Val AdditionalParameters) Export
	// Prompting for cancelation confirmation
	QueryText = NStr("en = 'Do you want to cancel item merging and close the window?'");
	Details = New NotifyDescription("CancellationCompletionAndFormTermination", ThisObject, New Structure);
	Details.AdditionalParameters.Insert("StepParameters", StepParameters);
	
	ShowQueryBox(Details, QueryText, QuestionDialogMode.YesNo);
EndProcedure

// --------------------------------------------------------------------------------------------
&AtClient
Procedure MergingStepOnActivate(Val Page, Val AdditionalParameters) Export
	// Starting long replacement processing 
	StartReferenceReplacement();
EndProcedure

&AtClient
Procedure MergingStepOnIdleProcess(Stop, Val AdditionalParameters) Export
	// Waiting for reference replacement completion
	ActionState = ValidateStateAndHandleReferenceReplacement();
	
	If Not ActionState.Completed Then
		Return;
	EndIf;
	
	If ActionState.ErrorInfo = Undefined Then
		// Completed successfully
		If ActionState.Result = True Then
			// All items are replaced
			If True = ReadWizardUserParameter(ThisObject, "PopUpSuccessMessageWindow") Then
				ExitForm( GenerateCompletionLabel() );
			Else
				// Switching to the completion page
				WizardStep("Next");
			EndIf;
			
		Else
			// Some items are still unprocessed, reattempting merging
			GoToWizardStep(Items.StepRepeatMerge, True);
		EndIf
	Else
		// Background job has been completed with error
		Stop = True;
		ShowMessageBox(, ActionState.ErrorInfo);
		GoToWizardStep(Items.MainItemSelectionStep);
	EndIf;
	
EndProcedure

&AtClient
Procedure MergingStepBeforeCancelAction(Val StepParameters, Val AdditionalParameters) Export
	// Prompting for cancelation confirmation
	QueryText = NStr("en = 'Do you want to abort merging and close the window?'");
	Details = New NotifyDescription("CancellationCompletionAndFormTermination", ThisObject, New Structure);
	Details.AdditionalParameters.Insert("StepParameters", StepParameters);
	
	ShowQueryBox(Details, QueryText, QuestionDialogMode.YesNo);
EndProcedure

// --------------------------------------------------------------------------------------------
&AtClient
Procedure SuccessfulEndStepOnActivate(Val Page, Val AdditionalParameters) Export
	// Refreshing label 
	GenerateCompletionLabel();
	
	// Notifying successful replacement
	UpdatedItemList = New Array;
	For Each Row In UsageInstances Do
		UpdatedItemList.Add(Row.Ref);
	EndDo;
	NotifySuccessfulReplacement(UpdatedItemList);
EndProcedure

&AtClient
Procedure SuccessfulEndStepBeforeCancelAction(Val StepParameters, Val AdditionalParameters) Export
	
	// Exit. Forced form termination
	ExitForm();
	
EndProcedure

// --------------------------------------------------------------------------------------------
&AtClient
Procedure RepeatMergingStepOnActivate(Val Page, Val AdditionalParameters) Export
	// Refreshing number of failures
	GenerateUnsuccessfulReplacementLabel();
	
	// Notify the successful partial replacement
	UpdatedItemList = DeleteProcessedItemsFromUsageInstances();	// At the same time, deleting the item from the list of options
	NotifySuccessfulReplacement(UpdatedItemList);
EndProcedure

&AtClient
Procedure RepeatMergingStepBeforeNextAction(Val StepParameters, Val AdditionalParameters) Export
	// Repeating replacement
	GoToWizardStep(Items.MergingStep, True);
EndProcedure

&AtClient
Procedure RepeatMergingStepBeforeBackAction(Val StepParameters, Val AdditionalParameters) Export
	// Refilling list of items to be processed
	GoToWizardStep(Items.SearchForUsageInstancesStep, True);
EndProcedure

&AtClient
Procedure RepeatMergingStepBeforeCancelAction(Val StepParameters, Val AdditionalParameters) Export
	// Exit. Forced form termination
	ExitForm();
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// PROCEDURES AND FUNCTIONS OF STEP-BY-STEP ASSISTANT

// For embedding the wizard functional:
//
//     1) Draw a group with the wizard pages on the form.
//     2) Define three commands for Next, Back, and Cancel actions on the form. Define its
//        handlers as:
//
//         &AtClient
//         Procedure BackWizardStep(Command) 
//           WizardStep("Back");
//         EndProcedure
//
//         &AtClient
//         Procedure NextWizardStep(Command) 
//           WizardStep("Next");
//         EndProcedure
//
//         &AtClient
//         Procedure CancelWizardStep(Command)
//           WizardStep("Cancel");
//         EndProcedure
//
//     3) Add a block of step-by-step assistant methods
//
//     4) In the server script::
//          - Initialize wizard structures by calling InitWizard with the passed corresponded 
//            form items.
//
//          - Create a scenario for processing the serial calls of AddWizardStep. We recommend
//            that you use the following auxiliary functions: WizardStepAction and
//            WizardStepButtons. For example:
//
//      AddWizardStep(Items.TargetItemSelectionStep, 
//     			WizardStepAction("OnActivate",         "TargetItemSelectionStepOnActivate",
//     			WizardStepAction("BeforeNextAction",   "TargetItemSelectionStepBeforeNextAction",
//     			WizardStepAction("BeforeCancelAction", "TargetItemSelectionStepBeforeCancelAction",
//     		))), 
//     			WizardStepButtons("Next", NStr("en = 'Replace'") + " >", True, True, True,
//     			WizardStepButtons("Back", "", False, False, False, 
//     			WizardStepButtons("Cancel", NStr("en = 'Cancel'")
//     		)))
//     	);;
//
//     5) In the client script (usually during opening):
//          - Specify the wizard start page by calling SetWizardStartPage
//          - Call the start page by calling StartWizard
//

// Initializes wizard structures.
//
// Parameters:
//  PageGroup     - FormGroup - form item, group of the "page" type that contains wizard step
//                  pages.
//  NextButton    - FormButton, CommandBarButton - form item used for the Next button. 
//  BackButton    - FormButton, CommandBarButton - form item used for the Back button.
//  CancelButton  - FormButton, CommandBarButton - form item used for the Cancel button.
//
&AtServer
Procedure InitWizard(Val PageGroup, Val NextButton, Val BackButton, Val CancelButton)
	WizardSettings = New Structure;

	WizardSettings.Insert("Steps", New Array);
	WizardSettings.Insert("CurrentStepNumber", 0);
	WizardSettings.Insert("StartPage", Undefined);
	
	// Interface part IDs
	WizardSettings.Insert("PageGroup", PageGroup.Name);
	WizardSettings.Insert("NextButton",   NextButton.Name);
	WizardSettings.Insert("BackButton",   BackButton.Name);
	WizardSettings.Insert("CancelButton",  CancelButton.Name);
	
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
//  Actions - Structure - description of actions available in the current step.
//            Structure fields are:
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
//                                                             must call ExitWizardStep(StepParameters).
//                                    <AdditionalParameters> - Undefined.
//             *BeforeBackAction   - String - similar to BeforeNextAction, describes the
//                                   behavior of the Back button.
//             *BeforeCancelAction - String - similar to BeforeNextAction, describes the
//                                   behavior of the Cancel button.
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
//
// We recommend that you use the following auxiliary methods for creating parameters:
// AddWizardStep, WizardStepAction, WizardStepButton.
//
&AtServer
Procedure AddWizardStep(Val Page, Val Actions, Val Buttons)
	
	// Default preferences
	StepDetails = New Structure("OnActivate, BeforeNextAction, BeforeBackAction, BeforeCancelAction, OnIdleProcess");
	
	ButtonFields = "Enabled, Visible, DefaultButton, Tooltip";
	
	StepDetails.Insert("NextButton", New Structure(ButtonFields, True, True, True));
	StepDetails.NextButton.Insert("Title", NStr("en='Next'") + " >" );
	
	StepDetails.Insert("BackButton", New Structure(ButtonFields, True, True, False));
	StepDetails.BackButton.Insert("Title", "<" + NStr("en='Back'"));
	
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
// Returns - Structure - InternalData with extra fields.
&AtServer
Function WizardStepAction(Val ID, Val HandlerName, InternalData = Undefined)
	If InternalData = Undefined Then
		InternalData = New Structure;
	EndIf;
	InternalData.Insert(ID, HandlerName);
	Return InternalData;
EndFunction

// Auxiliary creation of a structure that describe the button.
//
// Parameters:
//  ID            - String - Button ID, can me "Next", "Back", or "Cancel", see the
//                  AddWizardStep method description for details, 
//  Title         - String - button title.
//  Tooltip       - String - button tooltip.
//  Visible    - Boolean - button representation parameter.
//  Enabled       - Boolean - button representation parameter.
//  DefaultButton - Boolean - button representation parameter.
//  InternalData  - Structure - accumulates values.
//
// Returns - Structure - InternalData with extra fields.
//
&AtServer
Function WizardStepButtons(Val ID, Val Title = "", Val ToolTip = "", Val Visible = True, Val Enabled = True, Val DefaultButton = False, Val InternalData = Undefined)
	If InternalData = Undefined Then
		InternalData = New Structure;
	EndIf;
	
	ButtonDetails = New Structure;
	ButtonDetails.Insert("Title", Title);
	ButtonDetails.Insert("ToolTip", ?(IsBlankString(ToolTip), Title, ToolTip));
	
	ButtonDetails.Insert("Enabled", Enabled);
	ButtonDetails.Insert("Visible",    Visible);
	ButtonDetails.Insert("DefaultButton", DefaultButton);
	
	InternalData.Insert(ID, ButtonDetails);
	Return InternalData;
EndFunction

// Reads the user wizard parameter
&AtClientAtServerNoContext
Function ReadWizardUserParameter(Form, Val WizardParameterName)
	
	Return Form.StepByStepWizardSettings.UserParameters[WizardParameterName];
	
EndFunction

// Sets the user wizard parameter
&AtClientAtServerNoContext
Function SetWizardUserParameter(Form, Val WizardParameterName, Val WizardParameterValue)
	
	Form.StepByStepWizardSettings.UserParameters.Insert(WizardParameterName, WizardParameterValue);
	
EndFunction

// Sets the start page for an initial wizard run.
//
// Parameters:
//     StartPage - Number, String, FormGroup - step number, page-group, or its ID.
//
&AtClient
Procedure SetWizardStartPage(Val Page)
	
	ThisObject.StepByStepWizardSettings.StartPage = WizardStepNumberByID(Page);
	
EndProcedure

// Starts the wizard from the page set with SetWizardStartPage
&AtClient
Procedure StartWizard()
	WizardSettings = ThisObject.StepByStepWizardSettings;
	
	If WizardSettings.StartPage = Undefined Then
		Raise NStr("en = 'The start page must be set before the wizard is started.'");
		
	ElsIf WizardSettings.StartPage = -1 Then
		// Warming up. Checking whether all steps have action handlers.
		PossibleActions = New Structure("OnActivate, BeforeNextAction, BeforeBackAction, BeforeCancelAction, OnIdleProcess");
		For Each StepDetails In WizardSettings.Steps Do
			For Each KeyValue In PossibleActions Do
				ActionName = KeyValue.Key;
				HandlerName = StepDetails[ActionName];
				If Not IsBlankString(HandlerName) Then
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
		Items[WizardSettings.NextButton].Visible  = False;
		Items[WizardSettings.BackButton].Visible  = False;
		Items[WizardSettings.CancelButton].Visible = False;
		
		// Deferred start
		ThisObject.StepByStepWizardSettings.CurrentStepNumber = WizardSettings.StartPage;
		ThisObject.StepByStepWizardSettings.StartPage    = -1;
		AttachIdleHandler("StartWizard", 0.1, True);
	EndIf;
EndProcedure

// Switching the wizard to the next or previous page.
//
// Parameters:
//     CommandCode - String - action ID, can be Next, Back, or Cancel.
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
		
	ElsIf Heading = -1 Then
		Action = StepDetails.BeforeBackAction;
		
	Else
		Action = StepDetails.BeforeCancelAction;
		
	EndIf;
	
	If IsBlankString(Action) Then
		ExitWizardStep(Heading);
	Else
		Notification = New NotifyDescription(Action, ThisObject);
		ExecuteNotifyProcessing(Notification, Heading);
	EndIf;
EndProcedure

// Moves to the wizard page unconditionally.
//
// Parameters:
//  StepID     - Number, String, FormGroup - number, form page-group, or its name for switching.
//  InitEvents - Boolean - flag that shows whether the events associated with the step
//               activation must be called.
//
&AtClient
Procedure GoToWizardStep(Val StepID, Val InitEvents = False)
	WizardSettings = ThisObject.StepByStepWizardSettings;
	
	NextStep = WizardStepNumberByID(StepID);
	If NextStep = Undefined Then
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
	UnconditionalCompletionWizardStep(NextStep, InitEvents);
EndProcedure

// Confirms the wizard step action and switches the page.
//
// Parameters:
//  StepParameters - Internal attribute get in the handler before the beginning of the action.
//
&AtClient
Procedure ExitWizardStep(Val StepParameters)
	WizardSettings = ThisObject.StepByStepWizardSettings;
	
	NextStep = WizardSettings.CurrentStepNumber + StepParameters;
	FinalStep = WizardSettings.Steps.UBound();
	
	If StepParameters = 0 Then
		// Cancellation confirmation - doing nothing
		Return;
		
	ElsIf StepParameters = 1 And NextStep > FinalStep Then
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
	UpdateWizardButtonProperties(WizardSettings.NextButton,  StepDetails.NextButton);
	UpdateWizardButtonProperties(WizardSettings.BackButton,  StepDetails.BackButton);
	UpdateWizardButtonProperties(WizardSettings.CancelButton, StepDetails.CancelButton);
	
	// Switched successfully
	ThisObject.StepByStepWizardSettings.CurrentStepNumber = NextStep;
	
	If InitEvents And Not IsBlankString(StepDetails.OnActivate) Then
		// Processing OnActivate of the new page and starting the idle handler
		AttachIdleHandler("WizardPageActivationHandler", 0.1, True);
		
	ElsIf Not IsBlankString(StepDetails.OnIdleProcess) Then
		// Starting the idle handler, if necessary
		AttachIdleHandler("WizardPageIdleHandler", 0.1, True);
		
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
	If Not IsBlankString(StepDetails.OnActivate) Then
		Notification = New NotifyDescription(StepDetails.OnActivate, ThisObject);
		ExecuteNotifyProcessing(Notification, Items[StepDetails.Page]);
	EndIf;
	
	// Starting idle processing, if required
	If Not IsBlankString(StepDetails.OnIdleProcess) Then
		// First run is quick
		AttachIdleHandler("WizardPageIdleHandler", 0.1, True);
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
	
	Notification = New NotifyDescription(Action, ThisObject);
	
	Stop = False;
	ExecuteNotifyProcessing(Notification, Stop);
	MustContinue = Not Stop;
	
	If MustContinue Then
		AttachIdleHandler("WizardPageIdleHandler", WizardSettings.LongActionIdleTimeout, True);
	EndIf;
	
	Return MustContinue;
EndFunction

// Starts the long wizard action.
// 
// Parameters:
//  MethodName       - String - background job method name.
//  MethodParameters - Array - method parameters for background job.
//  ReturnsResult    - Boolean - flag that shows whether the result must be returned. If True,
//                     the result storage address is added as a last call parameter.
//  MethodDetails    - String - optional method description to be displayed in the background
//                     job list.
//
&AtServer
Function StartLongWizardAction(Val MethodName, Val MethodParameters, Val ReturnsResult = False, Val MethodDetails = "")
	
	// Possible, a previous unfinished long action is executed. Canceling if any.
	CancelLongWizardAction();
	
	If ReturnsResult Then
		ThisObject.StepByStepWizardSettings.BackgroundJobResultAddress = PutToTempStorage(Undefined, UUID);
		BackgroundMethodParameters = New Array(New FixedArray(MethodParameters));
		BackgroundMethodParameters.Add(ThisObject.StepByStepWizardSettings.BackgroundJobResultAddress);
	Else
		ThisObject.StepByStepWizardSettings.BackgroundJobResultAddress = Undefined;
		BackgroundMethodParameters = MethodParameters;
	EndIf;
	
	Job = BackgroundJobs.Execute(MethodName, BackgroundMethodParameters, , MethodDetails);
	ThisObject.StepByStepWizardSettings.BackgroundJobID = Job.UUID;
EndFunction

// Gets the state of the current long action.
// 
// Returns:
//  Structure - state details with the following fields:
//               * Completed - Boolean - flag that shows whether the long action is active.
//               * ErrorInfo - ErrorInfo - contains error details if the long action job
//                 terminated abnormally.
//               * Result    - Arbitrary - if a long action job was started with the return
//                             result flag, it contains the current result value.
//
&AtServer
Function LongWizardActionState()
	WizardSettings = ThisObject.StepByStepWizardSettings;
	
	Data = New Structure("Completed, Result, ErrorInfo", True);

	If WizardSettings.BackgroundJobID = Undefined Then
		Return Data;
	EndIf;
	
	Job = BackgroundJobs.FindByUUID(WizardSettings.BackgroundJobID);
	If Job <> Undefined Then
		// All unintelligible jobs are completed, see default values
		If Job.ErrorInfo <> Undefined Then
			Data.ErrorInfo = DetailErrorDescription(Job.ErrorInfo);
		EndIf;
		Data.Completed = Job.State <> BackgroundJobState.Active;
		If Data.Completed Then
			// Current background job messages
			AccumulatedMessages = Job.GetUserMessages(True);
			If AccumulatedMessages <> Undefined Then
				For Each Message In AccumulatedMessages Do
					Message.Message();
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	
	If Not IsBlankString(WizardSettings.BackgroundJobResultAddress) Then
		Data.Result = GetFromTempStorage(WizardSettings.BackgroundJobResultAddress);
	EndIf;
	
	If Data.Completed Then
		ThisObject.StepByStepWizardSettings.BackgroundJobID = Undefined;
		ThisObject.StepByStepWizardSettings.BackgroundJobResultAddress = Undefined;
	EndIf;
	
	Return Data;
EndFunction

// Cancels the current long action
&AtServer
Procedure CancelLongWizardAction()
	WizardSettings = ThisObject.StepByStepWizardSettings;
	
	If WizardSettings.BackgroundJobID <> Undefined Then 
		Job = BackgroundJobs.FindByUUID(WizardSettings.BackgroundJobID);
		If Job <> Undefined Then
			Job.Cancel();
		EndIf;
		ThisObject.StepByStepWizardSettings.BackgroundJobID = Undefined;
	EndIf;
	
	ThisObject.StepByStepWizardSettings.BackgroundJobResultAddress = Undefined;
	
EndProcedure

#EndRegion
