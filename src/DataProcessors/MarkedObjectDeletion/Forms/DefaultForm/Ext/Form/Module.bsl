&AtClient
Var HandlerParameters;

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	SetConditionalAppearance();
	If Parameters.Property("SelfTest") Then
		Return;
	EndIf;
	
	If Not Users.InfobaseUserWithFullAccess() Then
		ErrorText = NStr("en = 'Insufficient rights to perform the operation'");
		Return; // Cancel is set in OnOpen
	EndIf;
	
	If CommonUseCached.DataSeparationEnabled()
		And Not CommonUse.UseSessionSeparator() Then
		ErrorText = NStr("en = 'Log on to a data area for deleting marked objects'");
		Return; // Cancel is set in OnOpen
	EndIf;
	
	DeletionMode = "Full";
	SetDataProcessorExplanationTextOnCreateAtServer();
	VisibleEnabled(ThisObject);
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	VisibleEnabled(ThisObject);
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If ValueIsFilled(ErrorText) Then
		ShowMessageBox(, ErrorText);
		Cancel = True;
	EndIf;
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	If Items.FormPages.CurrentPage = Items.LongActionPage Then
		Cancel = True;
		DetachIdleHandler("BackgroundJobValidateAtClient");
		Handler = New NotifyDescription("BeforeCloseQuestionAnswer", ThisObject);
		QueryText = NStr("en = 'Marked objects are being deleted.
		|Do you want to abort it?'");
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Abort);
		Buttons.Add(DialogReturnCode.Ignore, NStr("en = 'Do not abort'"));
		ShowQueryBox(Handler, QueryText, Buttons, 60, DialogReturnCode.Ignore);
	EndIf;
EndProcedure

&AtClient
Procedure BeforeCloseQuestionAnswer(Answer, ExecutionParameters) Export
	If Answer = DialogReturnCode.Abort Then
		Items.FormPages.CurrentPage = Items.DeletionModeChoicePage; // For getting the question
		Close(); // Background job can be canceled in the OnClose() handler
	Else
		BackgroundJobValidateAtClient();
	EndIf;
EndProcedure

&AtClient
Procedure OnClose()
	If BackgroundJobID <> Undefined Then
		BackgroundJobCancel(BackgroundJobID);
		BackgroundJobID = Undefined;
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemEventHandlers

&AtClient
Procedure DeletionModeOnChange(Item)
	VisibleEnabled(ThisObject);
EndProcedure

&AtClient
Procedure DataProcessorExplanationURLProcessing(Item, Ref, StandardProcessing)
	StandardProcessing = False;
	FormParameters = New Structure("ApplicationNameFilter", "1CV8,1CV8C,WebClient");
	StandardSubsystemsClient.OpenActiveUserList(FormParameters);
EndProcedure

#EndRegion

#Region MarkedForDeletionItemTreeFormTableItemEventHandlers

&AtClient
Procedure MarkedForDeletionItemTreeCheckOnChange(Item)
	CurrentData = Items.MarkedForDeletionItemTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	MarkedForDeletionItemTreeSetChecknList(CurrentData, CurrentData.Check, True);
EndProcedure

&AtClient
Procedure MarkedForDeletionItemTreeChoice(Item, SelectedRow, Field, StandardProcessing)
	StandardProcessing = False;
	ShowTableObject(Item);
EndProcedure

#EndRegion

#Region NotDeletedItemsFormTableItemEventHandlers

&AtClient
Procedure NotDeletedItemsOnActivateRow(Item)
	AttachIdleHandler("ShowNotDeletedItemLinksAtClient", 0.1, True);
EndProcedure

&AtClient
Procedure NotDeletedItemsBeforeRowChange(Item, Cancel)
	Cancel = True;
	ShowTableObject(Item);
EndProcedure

&AtClient
Procedure NotDeletedItemsBeforeDelete(Item, Cancel)
	Cancel = True;
	MarkSelectedTableObjectForDeletion(Item);
EndProcedure

&AtClient
Procedure NotDeletedItemsSelection(Item, SelectedRow, Field, StandardProcessing)
	StandardProcessing = False;
	ShowTableObject(Item);
EndProcedure

&AtClient
Procedure NotDeletedItemsPresentationOpening(Item, StandardProcessing)
	StandardProcessing = False;
	ShowTableObject(Item);
EndProcedure

#EndRegion

#Region NotDeletedItemLinksFormTableItemEventHandlers

&AtClient
Procedure NotDeletedItemLinksBeforeRowChange(Item, Cancel)
	Cancel = True;
	ShowTableObject(Item);
EndProcedure

&AtClient
Procedure NotDeletedItemLinksBeforeDelete(Item, Cancel)
	Cancel = True;
	MarkSelectedTableObjectForDeletion(Item);
EndProcedure

&AtClient
Procedure NotDeletedItemLinksSelection(Item, SelectedRow, Field, StandardProcessing)
	StandardProcessing = False;
	ShowTableObject(Item);
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure NextCommand(Command)
	
	CurrentPage = Items.FormPages.CurrentPage;
	If CurrentPage = Items.DeletionModeChoicePage Then
		If DeletionMode = "Full" Then
			StartMarkedObjectDeletionAtClient(False);
		Else
			FillMarkedForDeletionItemTreeAtClient();
		EndIf;
	ElsIf CurrentPage = Items.MarkedForDeletionItemsPage Then
		StartMarkedObjectDeletionAtClient(False);
	ElsIf CurrentPage = Items.ReasonsForDeletionImpossibilityPage Then
		StartMarkedObjectDeletionAtClient(True);
	EndIf;
	
EndProcedure

&AtClient
Procedure BackCommand(Command)
	Items.FormPages.CurrentPage = Items.DeletionModeChoicePage;
	VisibleEnabled(ThisObject);
EndProcedure

&AtClient
Procedure MarkedForDeletionItemTreeCheckAll(Command)
	
	ListItems = MarkedForDeletionItemTree.GetItems();
	For Each Item In ListItems Do
		MarkedForDeletionItemTreeSetChecknList(Item, True, True);
		Parent = Item.GetParent();
		If Parent = Undefined Then
			MarkedForDeletionItemTreeCheckParent(Item)
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure MarkedForDeletionItemTreeUncheckAll(Command)
	
	ListItems = MarkedForDeletionItemTree.GetItems();
	For Each Item In ListItems Do
		MarkedForDeletionItemTreeSetChecknList(Item, False, True);
		Parent = Item.GetParent();
		If Parent = Undefined Then
			MarkedForDeletionItemTreeCheckParent(Item)
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure MarkedForDeletionItemTreeChange(Command)
	ShowTableObject(Items.MarkedForDeletionItemTree);
EndProcedure

&AtClient
Procedure MarkedForDeletionItemTreeRefresh(Command)
	FillMarkedForDeletionItemTreeAtClient();
EndProcedure

&AtClient
Procedure NotDeletedItemsReplaceWith(Command)
	ArrayOfIdentifiers = Items.NotDeletedItems.SelectedRows;
	If ArrayOfIdentifiers.Count() = 0 Then
		Return;
	EndIf;
	
	RefArray = New Array;
	For Each ID In ArrayOfIdentifiers Do
		TableRow = NotDeletedItems.FindByID(ID);
		If TypeOf(TableRow.ItemToDeleteReference) = Type("String") Then
			Continue; // Skipping groups
		EndIf;
		RefArray.Add(TableRow.ItemToDeleteReference);
	EndDo;
	
	If RefArray.Count() = 0 Then
		ShowMessageBox(, NStr("en = 'Select objects'"));
		Return;
	EndIf;
	
	StandardSubsystemsClient.ReplaceSelected(RefArray);
EndProcedure

&AtClient
Procedure NotDeletedItemsDelete(Command)
	MarkSelectedTableObjectForDeletion(Items.NotDeletedItems);
EndProcedure

&AtClient
Procedure NotDeletedItemLinksDelete(Command)
	MarkSelectedTableObjectForDeletion(Items.NotDeletedItemLinks);
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure SetConditionalAppearance()
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.NotDeletedItemLinks.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReasonsForNotDeletionPresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("NotDeletedItemLinks.Visible");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	Item.Appearance.SetParameterValue("Show", False);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Client

&AtClient
Procedure BackgroundJobValidateAtClient()
	Result = BackgroundJobGetResult();
	If Result.BackgroundJobCompleted Then
		StandardSubsystemsClient.ShowExecutionResult(ThisObject, Result);
	Else
		LongActionsClient.UpdateIdleHandlerParameters(HandlerParameters);
		AttachIdleHandler("BackgroundJobValidateAtClient", HandlerParameters.CurrentInterval, True);
	EndIf;
EndProcedure

&AtClient
Procedure FillMarkedForDeletionItemTreeAtClient()
	Status(NStr("en = 'Marked for deletion objects are being searched'"));
	FillingResult = FillMarkedForDeletionItemTree();
	If FillingResult.TypeCount = 1 Then
		ID = MarkedForDeletionItemTree.GetItems()[0].GetID();
		Items.MarkedForDeletionItemTree.Expand(ID, False);
	EndIf;
EndProcedure

&AtClient
Procedure StartMarkedObjectDeletionAtClient(Restart)
	If DeletionMode = "Full" Then
		Status(NStr("en = 'Marked objects are being searched and deleted'"));
	Else
		Status(NStr("en = 'Selected objects are being deleted'"));
	EndIf;
	
	Result = BackgroundJobStart(Restart);
	If Result.BackgroundJobRunning Then
		LongActionsClient.InitIdleHandlerParameters(HandlerParameters);
		AttachIdleHandler("BackgroundJobValidateAtClient", 1, True);
		HandlerParameters.MaxInterval = 5;
	EndIf;
	StandardSubsystemsClient.ShowExecutionResult(ThisObject, Result);
EndProcedure

&AtClient
Procedure ShowNotDeletedItemLinksAtClient()
	TreeRow = Items.NotDeletedItems.CurrentData;
	If TreeRow = Undefined Or TreeRow.PictureNumber < 1 Then
		// Selected nothing or a group
		Items.ResultDisplayingOptionPages.CurrentPage = Items.SelectNotDeletedItemsObjectPage;
		Items.ResultDisplayingOptionPagesHeader.CurrentPage = Items.SelectNotDeletedObjectPageHeader;
		ErrorText = NStr("en = 'Select an object to see why it cannot be deleted.'");
		Return;
	EndIf;
	
	// Reference to a not deleted object is selected
	Hidden = NotDeletedItemLinks.FindRows(New Structure("Visible", True));
	For Each TableRow In Hidden Do
		TableRow.Visible = False;
	EndDo;
	
	ErrorText = "";
	ShowErrorText = True;
	Shown = NotDeletedItemLinks.FindRows(New Structure("ItemToDeleteReference", TreeRow.ItemToDeleteReference));
	For Each TableRow In Shown Do
		TableRow.Visible = True;
		If TableRow.IsError Then
			ErrorText = TableRow.FoundItemReference;
		Else
			If ShowErrorText Then
				Items.NotDeletedItemLinks.CurrentRow = TableRow.GetID();
				ShowErrorText = False;
				//Break;
			EndIf;
		EndIf;
	EndDo;
	
	If ShowErrorText Then
		Items.ResultDisplayingOptionPages.CurrentPage = Items.ErrorTextPage;
		Items.ResultDisplayingOptionPagesHeader.CurrentPage = Items.ErrorTextPageHeader;
	Else
		Items.ResultDisplayingOptionPages.CurrentPage = Items.ReasonsForNotDeletionPage;
		Items.ResultDisplayingOptionPagesHeader.CurrentPage = Items.ReasonsForNotDeletionPageHeader;
		
		Template = NStr("en = '%1 is used in (%2):'");
		ShortObjectPresentation = TreeRow.Presentation;
		If StrLen(ShortObjectPresentation) > 50 Then
			ShortObjectPresentation = TrimR(Left(ShortObjectPresentation, 50)) + "...";
		EndIf;
		Items.LabelNotDeletedItemLinks.Title = StringFunctionsClientServer.SubstituteParametersInString(
			Template,
			ShortObjectPresentation,
			Format(TreeRow.ReferenceCount, "NZ=0;NG=")
		);
		Items.LabelNotDeletedItemLinks.ToolTip = StringFunctionsClientServer.SubstituteParametersInString(
			Template,
			TreeRow.Presentation,
			Format(TreeRow.ReferenceCount, "NZ=0;NG=")
		);
	EndIf;
EndProcedure

&AtClient
Procedure ShowTableObject(TableItem)
	TableRow = TableItem.CurrentData;
	If TableRow = Undefined Then
		Return;
	EndIf;
	
	Value = Undefined;
	If Not TableRow.Property("Value", Value)
		And Not TableRow.Property("FoundItemReference", Value)
		And Not TableRow.Property("ItemToDeleteReference", Value) Then
		Return;
	EndIf;
	
	If TypeOf(Value) = Type("String") Then
		If TableRow.Property("IsConstant") And TableRow.IsConstant Then
			PathToForm = Value + ".ConstantForm";
		Else
			PathToForm = Value + ".ListForm";
		EndIf;
		OpenForm(PathToForm);
	ElsIf TypeOf(Value) = Type("ValueList") Then
		ValueDetails = Value.Get(0);
		FormParameters = New Structure;
		FormParameters.Insert("Key", ValueDetails.Value);
		OpenForm(ValueDetails.Presentation + ".RecordForm", FormParameters, ThisObject);
	Else
		ShowValue(, Value);
	EndIf;
EndProcedure

&AtClient
Procedure MarkSelectedTableObjectForDeletion(TableItem)
	ArrayOfIdentifiers = TableItem.SelectedRows;
	CountSelected = ArrayOfIdentifiers.Count();
	If CountSelected = 0 Then
		Return;
	EndIf;
	TableAttribute = ThisObject[TableItem.Name];
	TableRowArray = New Array;
	ArrayOfMarkedForDeletionItemReferences = New Array;
	ArrayOfNotMarkedForDeletionItemReference = New Array;
	HasMarkedForDeletion = False;
	ValueAttributeName = "";
	Value = Undefined;
	ReferenceType = Undefined;
	HasReferenceTypeProperty = False;
	For Each ID In ArrayOfIdentifiers Do
		TableRow = TableAttribute.FindByID(ID);
		If ValueAttributeName = "" Then
			If TableRow.Property("Value") Then
				ValueAttributeName = "Value";
			ElsIf TableRow.Property("FoundItemReference") Then
				ValueAttributeName = "FoundItemReference";
			ElsIf TableRow.Property("ItemToDeleteReference") Then
				ValueAttributeName = "ItemToDeleteReference";
			Else
				Return;
			EndIf;
			HasReferenceTypeProperty = TableRow.Property("ReferenceType");
		EndIf;
		TableRow.Property(ValueAttributeName, Value);
		If TypeOf(Value) = Type("String") Then
			Continue; // Skipping groups
		ElsIf HasReferenceTypeProperty And Not TableRow["ReferenceType"] Then
			If CountSelected = 1 Then
				ShowMessageBox(, NStr("en = 'Register record can be deleted from its card'"));
				Return;
			Else
				Continue; // Skipping register records
			EndIf;
		EndIf;
		If TableRow.DeletionMark Then
			HasMarkedForDeletion = True;
			ArrayOfMarkedForDeletionItemReferences.Add(Value);
		Else
			ArrayOfNotMarkedForDeletionItemReference.Add(Value);
		EndIf;
		If TypeOf(TableAttribute) = Type("FormDataCollection") Then
			Found = TableAttribute.FindRows(New Structure(ValueAttributeName, Value));
			For Each RowByReference In Found Do
				TableRowArray.Add(RowByReference);
			EndDo;
		Else
			TableRowArray.Add(TableRow);
		EndIf;
	EndDo;
	
	RefArray = ?(HasMarkedForDeletion, ArrayOfMarkedForDeletionItemReferences, ArrayOfNotMarkedForDeletionItemReference);
	CountCanDelete = RefArray.Count();
	If CountCanDelete = 0 Then
		If CountSelected = 1 Then
			ShowMessageBox(, NStr("en = 'Select an object'"));
		Else
			ShowMessageBox(, NStr("en = 'Select objects'"));
		EndIf;
		Return;
	EndIf;
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("TableRowArray", TableRowArray);
	HandlerParameters.Insert("RefArray", RefArray);
	HandlerParameters.Insert("ValueAttributeName", ValueAttributeName);
	HandlerParameters.Insert("HasMarkedForDeletion", HasMarkedForDeletion);
	
	Handler = New NotifyDescription("MarkSelectedTableObjectForDeletionCompletion", ThisObject, HandlerParameters);
	
	If CountCanDelete = 1 Then
		If HasMarkedForDeletion Then
			QueryText = NStr("en = 'Do you want to clear the deletion mark of %1?'");
		Else
			QueryText = NStr("en = 'Do you want to mark %1 for deletion?'");
		EndIf;
		QueryText = StrReplace(QueryText, "%1", TableRowArray[0].Presentation);
	Else
		If HasMarkedForDeletion Then
			QueryText = NStr("en = 'Do you want to clear deletion marks of the selected objects (%1)?'");
		Else
			QueryText = NStr("en = 'Do you want to mark the selected objects (%1) for deletion?'");
		EndIf;
		QueryText = StrReplace(QueryText, "%1", Format(CountCanDelete, "NZ=0;NG="));
	EndIf;
	
	Buttons = New ValueList;
	Buttons.Add(DialogReturnCode.Yes);
	Buttons.Add(DialogReturnCode.No);
	
	ShowQueryBox(Handler, QueryText, Buttons, 60, DialogReturnCode.No);
EndProcedure

&AtClient
Procedure MarkSelectedTableObjectForDeletionCompletion(Answer, ExecutionParameters) Export
	If Answer <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	DeletionMark = Not ExecutionParameters.HasMarkedForDeletion;
	ServerResult = ChangeMarkDeletionObjects(ExecutionParameters.RefArray, DeletionMark);
	For Each TableRow In ExecutionParameters.TableRowArray Do
		If TableRow.DeletionMark = DeletionMark Then
			Continue;
		EndIf;
		TableRow.DeletionMark = DeletionMark;
		TableRow.PictureNumber   = TableRow.PictureNumber + ?(DeletionMark, 1, -1);
	EndDo;
	StandardSubsystemsClient.ShowExecutionResult(ThisObject, ServerResult);
EndProcedure

&AtClient
Procedure MarkedForDeletionItemTreeSetChecknList(Data, Check, CheckParent)
	
	// Setting marks of subordinate items
	RowItems = Data.GetItems();
	
	For Each Item In RowItems Do
		Item.Check = Check;
		MarkedForDeletionItemTreeSetChecknList(Item, Check, False);
	EndDo;
	
	// Checking the parent item
	Parent = Data.GetParent();
	
	If CheckParent And Parent <> Undefined Then 
		MarkedForDeletionItemTreeCheckParent(Parent);
	EndIf;
	
EndProcedure

&AtClient
Procedure MarkedForDeletionItemTreeCheckParent(Parent)
	
	ParentMark = True;
	RowItems = Parent.GetItems();
	For Each Item In RowItems Do
		If Not Item.Check Then
			ParentMark = False;
			Break;
		EndIf;
	EndDo;
	Parent.Check = ParentMark;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Client, Server

&AtClientAtServerNoContext
Procedure VisibleEnabled(Form)
	Items = Form.Items;
	CurrentPage = Items.FormPages.CurrentPage;
	
	Items.NextButton.Title = NStr("en = 'Delete'");
	Items.CloseButton.Title = NStr("en = 'Close'");
	Items.BackButton.Title = NStr("en = '< To the beginning'");
	
	If CurrentPage = Items.DeletionModeChoicePage Then
		Items.BackButton.Visible = False;
		Items.NextButton.Visible = True;
		If Form.DeletionMode <> "Full" Then
			Items.NextButton.Title = NStr("en = 'Next >'");
		EndIf;
		Items.NextButton.DefaultButton = True;
		Items.CloseButton.Title = NStr("en = 'Cancel'");
	ElsIf CurrentPage = Items.MarkedForDeletionItemsPage Then
		Items.BackButton.Visible = True;
		Items.BackButton.Title = NStr("en = '< Back'");
		Items.NextButton.Visible = True;
		Items.NextButton.Title = NStr("en = 'Delete'");
		Items.NextButton.DefaultButton = True;
	ElsIf CurrentPage = Items.LongActionPage Then
		Items.BackButton.Visible = False;
		Items.NextButton.Visible = False;
		Items.CloseButton.Title = NStr("en = 'Abort and close'");
	ElsIf CurrentPage = Items.ReasonsForDeletionImpossibilityPage Then
		Items.BackButton.Visible = True;
		Items.NextButton.Visible = True;
		Items.NextButton.Title = NStr("en = 'Retry deletion'");
		Items.NextButton.DefaultButton = True;
	ElsIf CurrentPage = Items.DeletionNotRequiredPage Then
		Items.BackButton.Visible = True;
		Items.NextButton.Visible = False;
		Items.CloseButton.DefaultButton = True;
	ElsIf CurrentPage = Items.DonePage Then
		Items.BackButton.Visible = True;
		Items.NextButton.Visible = False;
		Items.CloseButton.DefaultButton = True;
	EndIf;
	
	If CommonUseClientServer.IsWebClient() Then
		If CurrentPage = Items.ReasonsForDeletionImpossibilityPage Then
			Items.ReasonsForDeletionImpossibilityPage.Visible = True;
		Else
			Items.ReasonsForDeletionImpossibilityPage.Visible = False;
		EndIf;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function PictureNumber(ReferenceOrData, ReferenceType, Kind, DeletionMark)
	If ReferenceType Then
		If Kind = "CATALOG"
			Or Kind = "CHARTOFCHARACTERISTICTYPES" Then
			PictureNumber = 3;
		ElsIf Kind = "DOCUMENT" Then
			PictureNumber = 12;
		ElsIf Kind = "CHARTOFACCOUNTS" Then
			PictureNumber = 15;
		ElsIf Kind = "CHARTOFCALCULATIONTYPES" Then
			PictureNumber = 17;
		ElsIf Kind = "BUSINESSPROCESS" Then
			PictureNumber = 19;
		ElsIf Kind = "TASK" Then
			PictureNumber = 21;
		ElsIf Kind = "EXCHANGEPLAN" Then
			PictureNumber = 23;
		Else
			PictureNumber = -2;
		EndIf;
		If DeletionMark Then
			PictureNumber = PictureNumber + 1;
		EndIf;
	Else
		If Kind = "CONSTANT" Then
			PictureNumber = 25;
		ElsIf Kind = "INFORMATIONREGISTER" Then
			PictureNumber = 26;
		ElsIf Kind = "ACCUMULATIONREGISTER" Then
			PictureNumber = 28;
		ElsIf Kind = "ACCOUNTINGREGISTER" Then
			PictureNumber = 34;
		ElsIf Kind = "CALCULATIONREGISTER" Then
			PictureNumber = 38;
		ElsIf ReferenceOrData = Undefined Then
			PictureNumber = 11;
		Else
			PictureNumber = 8;
		EndIf;
	EndIf;
	
	Return PictureNumber;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Server call, Server

&AtServer
Function FillMarkedForDeletionItemTree()
	Result = New Structure;
	Result.Insert("TypeCount", 0);
	
	DataProcessorManager = DataProcessors.MarkedObjectDeletion;
	
	ExecutionParameters = New Structure;
	
	// Filling marked for deletion item tree
	MarkedForDeletion = MarkedForDeletionItemsFromResultPage();
	MarksSetSelectively = (MarkedForDeletion.Count() > 0);
	
	ValueTree = FormAttributeToValue("MarkedForDeletionItemTree");
	ValueTree.Rows.Clear();
	ValueTree.Columns.Add("Count");
	
	FirstLevelNodes = New Map;
	
	DataProcessorManager.InitializeParameters(ExecutionParameters);
	DataProcessorManager.GetMarkedForDeletion(ExecutionParameters);
	
	For Each ItemToDeleteReference In ExecutionParameters.MarkedForDeletion Do
		ItemBeingDeletedType = TypeOf(ItemToDeleteReference);
		ItemBeingDeletedInfo = DataProcessorManager.GenerateTypeInfo(ExecutionParameters, ItemBeingDeletedType);
		
		NodeType = FirstLevelNodes.Get(ItemBeingDeletedType);
		If NodeType = Undefined Then
			ItemBeingDeletedMetadata = ItemToDeleteReference.Metadata();
			NodeType = ValueTree.Rows.Add();
			NodeType.Value         = ItemBeingDeletedInfo.FullName;
			NodeType.Presentation  = ItemBeingDeletedInfo.ListPresentation;
			NodeType.Check         = True;
			NodeType.Count         = 0;
			NodeType.PictureNumber = -1;
			FirstLevelNodes.Insert(ItemBeingDeletedType, NodeType);
		EndIf;
		NodeType.Count = NodeType.Count + 1;
		
		ItemBeingDeletedNode = NodeType.Rows.Add();
		ItemBeingDeletedNode.Value         = ItemToDeleteReference;
		ItemBeingDeletedNode.Presentation  = String(ItemToDeleteReference);
		ItemBeingDeletedNode.Check         = True;
		ItemBeingDeletedNode.PictureNumber = PictureNumber(ItemToDeleteReference, True, ItemBeingDeletedInfo.Kind, True);
		
		If MarksSetSelectively And MarkedForDeletion.Find(ItemToDeleteReference) = Undefined Then
			ItemBeingDeletedNode.Check = False;
			NodeType.Check             = False;
		EndIf;
		
	EndDo;
	
	For Each NodeType In ValueTree.Rows Do
		NodeType.Presentation = NodeType.Presentation + " (" + NodeType.Count + ")";
	EndDo;
	
	ValueTree.Columns.Delete(ValueTree.Columns.Count);
	ValueTree.Rows.Sort("Presentation", True);
	
	ValueToFormAttribute(ValueTree, "MarkedForDeletionItemTree");
	
	Result.TypeCount = FirstLevelNodes.Count();
	
	If Result.TypeCount = 0 Then
		Items.FormPages.CurrentPage = Items.DeletionNotRequiredPage;
	Else
		Items.FormPages.CurrentPage = Items.MarkedForDeletionItemsPage;
	EndIf;
	VisibleEnabled(ThisObject);
	
	Return Result;
EndFunction

&AtServer
Function MarkedForDeletionItemsFromResultPage()
	MarkedForDeletion = New Array;
	
	ValueTree = FormAttributeToValue("NotDeletedItems");
	Found = ValueTree.Rows.FindRows(New Structure("DeletionMark", True), True);
	For Each TreeRow In Found Do
		If TypeOf(TreeRow.ItemToDeleteReference) <> Type("String")
			And MarkedForDeletion.Find(TreeRow.ItemToDeleteReference) = Undefined Then
			MarkedForDeletion.Add(TreeRow.ItemToDeleteReference);
		EndIf;
	EndDo;
	
	ValueTable = FormAttributeToValue("NotDeletedItemLinks");
	Found = ValueTable.FindRows(New Structure("DeletionMark", True));
	For Each TreeRow In Found Do
		If TypeOf(TreeRow.FoundItemReference) <> Type("String")
			And MarkedForDeletion.Find(TreeRow.FoundItemReference) = Undefined Then
			MarkedForDeletion.Add(TreeRow.FoundItemReference);
		EndIf;
	EndDo;
	
	Return MarkedForDeletion;
EndFunction

&AtServer
Function MarkedForDeletionItemsFromCheckBoxSettingPage()
	MarkedForDeletion = New Array;
	
	ValueTree = FormAttributeToValue("MarkedForDeletionItemTree");
	Found = ValueTree.Rows.FindRows(New Structure("Check", True), True);
	For Each TreeRow In Found Do
		If TypeOf(TreeRow.Value) <> Type("String") Then
			MarkedForDeletion.Add(TreeRow.Value);
		EndIf;
	EndDo;
	
	Return MarkedForDeletion;
EndFunction

&AtServer
Function BackgroundJobGetResult()
	Result = New Structure;
	Result.Insert("BackgroundJobCompleted", False);
	Result.BackgroundJobCompleted = LongActions.JobCompleted(BackgroundJobID);
	If Result.BackgroundJobCompleted Then
		StandardSubsystemsClientServer.NewExecutionResult(Result);
		BackgroundJobImportResult(Result);
	Else
		BackgroundJobReadInterimResult(Result);
	EndIf;
	Return Result;
EndFunction

&AtServer
Function BackgroundJobStart(Restart)
	Result = StandardSubsystemsClientServer.NewExecutionResult();
	Result.Insert("BackgroundJobRunning", False);
	
	// Starting background job
	DeletionParameters = New Structure;
	
	If DeletionMode = "Selective" Then
		If Restart Then
			MarkedForDeletion = MarkedForDeletionItemsFromResultPage();
		Else
			MarkedForDeletion = MarkedForDeletionItemsFromCheckBoxSettingPage();
		EndIf;
		If MarkedForDeletion.Count() = 0 Then
			Items.FormPages.CurrentPage = Items.DeletionNotRequiredPage;
			VisibleEnabled(ThisObject);
			Return Result;
		EndIf;
		DeletionParameters.Insert("MarkedForDeletion", MarkedForDeletion);
	EndIf;
	
	DeletionParameters.Insert("RecordPeriod", 1); // Seconds
	
	BackgroundJobResult = LongActions.ExecuteInBackground(
		UUID,
		"DataProcessors.MarkedObjectDeletion.DeleteMarkedObjectsInteractively",
		DeletionParameters,
		NStr("en = 'Deletion of marked objects (interactive)'"));
	
	BackgroundJobID  = BackgroundJobResult.JobID;
	BackgroundJobStorageAddress = BackgroundJobResult.StorageAddress;
	
	If BackgroundJobResult.JobCompleted Then
		BackgroundJobImportResult(Result);
		Result.BackgroundJobRunning = False;
	Else
		BackgroundJobReadInterimResult(Result);
		Items.FormPages.CurrentPage = Items.LongActionPage;
		Result.BackgroundJobRunning = True;
	EndIf;
	VisibleEnabled(ThisObject);
	
	Return Result;
EndFunction

&AtServerNoContext
Procedure BackgroundJobCancel(BackgroundJobID)
	LongActions.CancelJobExecution(BackgroundJobID);
EndProcedure

&AtServerNoContext
Function ChangeMarkDeletionObjects(RefArray, DeletionMark)
	Result = StandardSubsystemsClientServer.NewExecutionResult();
	Count = RefArray.Count();
	For Number = 1 to Count Do
		ReverseIndex = Count - Number;
		ObjectBeingChanged = RefArray[ReverseIndex].GetObject();
		If ObjectBeingChanged = Undefined Then
			RefArray.Delete(ReverseIndex);
		Else
			ObjectBeingChanged.SetDeletionMark(DeletionMark);
		EndIf;
	EndDo;
	
	StandardSubsystemsClientServer.PrepareDynamicListNotification(RefArray, Result);
	Result.NotificationOutput.Use = True;
	If DeletionMark Then
		Result.NotificationOutput.Title = NStr("en = 'Deletion mark set'");
	Else
		Result.NotificationOutput.Title = NStr("en = 'Deletion mark cleared'");
	EndIf;
	ObjectCount = RefArray.Count();
	If ObjectCount = 0 Then
		Result.NotificationOutput.Title = NStr("en = 'Object not found'");
	ElsIf ObjectCount = 1 Then
		Result.NotificationOutput.Ref = RefArray[0];
		Result.NotificationOutput.Text = String(Result.NotificationOutput.Ref);
	Else
		Result.NotificationOutput.Title = Result.NotificationOutput.Title + " (" + Format(ObjectCount, "NZ=0;NG=") + ")";
	EndIf;
	Return Result;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Server

&AtServer
Procedure SetDataProcessorExplanationTextOnCreateAtServer()
	ConnectionCount = 0;
	ThisSessionNumber = InfobaseSessionNumber();
	For Each InfobaseSession In GetInfobaseSessions() Do
		If InfobaseSession.SessionNumber = ThisSessionNumber Then
			Continue;
		EndIf;
		If InfobaseSession.ApplicationName = "1CV8" // Thick client
			Or InfobaseSession.ApplicationName = "1CV8C" // Thin client
			Or InfobaseSession.ApplicationName = "WebClient" // Web client
			Then
			ConnectionCount = ConnectionCount + 1;
		EndIf;
	EndDo;
	
	CaptionPattern = Items.DataProcessorExplanation.Title;
	If ConnectionCount = 0 Then
		Items.DataProcessorExplanation.Title = Left(CaptionPattern, Find(CaptionPattern, "<1/>") - 1);
		WindowOptionsKey = "1";
	Else
		Balance = StrReplace(CaptionPattern, "<1/>", "");
		RowArray = New Array;
		
		Position = Find(Balance, "<a");
		RowArray.Add(Left(Balance, Position - 1));
		Balance = Mid(Balance, Position);
		
		Position = Find(Balance, "</a>");
		ReferenceDefinition = Left(Balance, Position -1);
		Balance = Mid(Balance, Position + 4);
		
		Position = Find(ReferenceDefinition, """");
		ReferenceDefinition = Mid(ReferenceDefinition, Position + 1);
		
		Position = Find(ReferenceDefinition, """");
		ReferenceAddress = Left(ReferenceDefinition, Position - 1);
		HyperlinkText = Mid(ReferenceDefinition, Position + 2);
		HyperlinkText = StringFunctionsClientServer.SubstituteParametersInString(HyperlinkText, Format(ConnectionCount, "NG="));
		
		RowArray.Add(New FormattedString(HyperlinkText, , , , ReferenceAddress));
		RowArray.Add(Balance);
		
		Items.DataProcessorExplanation.Title = New FormattedString(RowArray);
		WindowOptionsKey = "2";
	EndIf;
EndProcedure

&AtServer
Procedure BackgroundJobReadInterimResult(Result)
	Progress = LongActions.ReadProgress(BackgroundJobID);
	If Progress <> Undefined Then
		BackgroundJobPercent   = Progress.Percent;
		BackgroundJobState = Progress.Text;
	EndIf;
EndProcedure

&AtServer
Procedure BackgroundJobImportResult(Result)
	// Getting the result
	ExecutionInBackgroundResult = GetFromTempStorage(BackgroundJobStorageAddress);
	If ExecutionInBackgroundResult = Undefined Then
		Return;
	EndIf;
	
	// Preparing a notification for the dynamic lists
	StandardSubsystemsClientServer.PrepareDynamicListNotification(ExecutionInBackgroundResult.DeletedItems, Result);
	
	DeletedItemsCount = ExecutionInBackgroundResult.DeletedItems.Count();
	NotDeletedItemsCount = ExecutionInBackgroundResult.NotDeletedItems.Count();
	
	NotificationText = Undefined;
	NotificationPicture = Undefined;
	
	If DeletedItemsCount = 0 And NotDeletedItemsCount = 0 Then
		Items.FormPages.CurrentPage = Items.DeletionNotRequiredPage;
	ElsIf NotDeletedItemsCount = 0 Then
		Items.FormPages.CurrentPage = Items.DonePage;
		NotificationText = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Deletion of marked objects is complete.
			|Deleted objects: %1.'"),
			Format(DeletedItemsCount, "NZ=0;NG=")
		);
		Items.DoneLabel.Title = NotificationText;
	Else
		Items.FormPages.CurrentPage = Items.ReasonsForDeletionImpossibilityPage;
		NotificationText = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Deletion of marked objects is complete.
			|Deleted objects: %1,
			|Not deleted objects: %2.'"),
			Format(DeletedItemsCount, "NZ=0;NG="),
			Format(NotDeletedItemsCount, "NZ=0;NG=")
		);
		NotificationPicture = PictureLib.Warning32;
		
		If DeletedItemsCount = 0 Then
			Items.PartialDeletionResultLabel.Title = StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Cannot delete marked for deletion objects (%1):'"),
				Format(NotDeletedItemsCount, "NZ=0;NG=")
			);
		Else
			Items.PartialDeletionResultLabel.Title = StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Deleted: %1 of %2, other objects are not deleted (%3):'"),
				Format(DeletedItemsCount, "NZ=0;NG="),
				Format(DeletedItemsCount+NotDeletedItemsCount, "NZ=0;NG="),
				Format(NotDeletedItemsCount, "NZ=0;NG=")
			);
		EndIf;
		
		Template = Items.NotDeletedItemsGroup.Title;
		Template = Left(Template, Find(Template, "("));
		Items.NotDeletedItemsGroup.Title = Template + Format(NotDeletedItemsCount, "NZ=0;NG=") + ")";
		
		FillRemainingObjectCollection(ExecutionInBackgroundResult);
		
		NotDeletedItemGroups = NotDeletedItems.GetItems();
		If NotDeletedItemGroups.Count() > 0 Then
			FirstGroupItems = NotDeletedItemGroups[0].GetItems();
			If FirstGroupItems.Count() > 0 Then
				Items.NotDeletedItems.CurrentRow = FirstGroupItems[0].GetID();
			EndIf;
		EndIf;
		
	EndIf;
	
	If NotificationText <> Undefined Then
		Result.NotificationOutput.Use     = True;
		Result.NotificationOutput.Title   = NStr("en = 'Deletion of marked objects'");
		Result.NotificationOutput.Text    = NotificationText;
		Result.NotificationOutput.Ref     = URL;
		Result.NotificationOutput.Picture = NotificationPicture;
	EndIf;
	
	DeleteFromTempStorage(BackgroundJobStorageAddress);
	BackgroundJobStorageAddress = Undefined;
	BackgroundJobID  = Undefined;
	VisibleEnabled(ThisObject);
EndProcedure

&AtServer
Procedure FillRemainingObjectCollection(ExecutionInBackgroundResult)
	
	PreventDeletion = ExecutionInBackgroundResult.PreventDeletion;
	TypeInformation = ExecutionInBackgroundResult.TypeInformation;
	
	NotDeletedItemsTree = FormAttributeToValue("NotDeletedItems");
	NotDeletedItemsTree.Rows.Clear();
	NotDeletedItemLinksTable = FormAttributeToValue("NotDeletedItemLinks");
	NotDeletedItemLinksTable.Clear();
	
	NotDeletedItemGroups = New Map;
	NotDeletedItemRows = New Map;
	
	For Each Reason In PreventDeletion Do
		NotDeletedItemRow = NotDeletedItemRows.Get(Reason.ItemToDeleteReference);
		If NotDeletedItemRow = Undefined Then
			ItemBeingDeletedInfo = TypeInformation.Get(Reason.ItemBeingDeletedType);
			If ItemBeingDeletedInfo.Technical Then
				Continue;
			EndIf;
			
			NotDeletedItemGroup = NotDeletedItemGroups.Get(Reason.ItemBeingDeletedType);
			If NotDeletedItemGroup = Undefined Then
				NotDeletedItemGroup = NotDeletedItemsTree.Rows.Add();
				NotDeletedItemGroup.PictureNumber         = -1;
				NotDeletedItemGroup.ItemToDeleteReference = ItemBeingDeletedInfo.FullName;
				NotDeletedItemGroup.Presentation          = ItemBeingDeletedInfo.ListPresentation;
				
				NotDeletedItemGroups.Insert(Reason.ItemBeingDeletedType, NotDeletedItemGroup);
			EndIf;
			
			NotDeletedItemGroup.ReferenceCount = NotDeletedItemGroup.ReferenceCount + 1;
			
			NotDeletedItemRow = NotDeletedItemGroup.Rows.Add();
			NotDeletedItemRow.ItemToDeleteReference = Reason.ItemToDeleteReference;
			NotDeletedItemRow.Presentation          = String(Reason.ItemToDeleteReference);
			NotDeletedItemRow.DeletionMark          = True;
			
			NotDeletedItemRow.PictureNumber = PictureNumber(
				NotDeletedItemRow.ItemToDeleteReference,
				True,
				ItemBeingDeletedInfo.Kind,
				NotDeletedItemRow.DeletionMark);
			
			NotDeletedItemRows.Insert(Reason.ItemToDeleteReference, NotDeletedItemRow);
		EndIf;
		
		NotDeletedItemRow.ReferenceCount = NotDeletedItemRow.ReferenceCount + 1;
		
		RowWithItemPreventingDeletion = NotDeletedItemLinksTable.Add();
		RowWithItemPreventingDeletion.ItemToDeleteReference = Reason.ItemToDeleteReference;
		RowWithItemPreventingDeletion.FoundItemReference    = Reason.FoundItemReference;
		RowWithItemPreventingDeletion.DeletionMark          = Reason.FoundDeletionMark;
		RowWithItemPreventingDeletion.IsError               = (Reason.FoundType = Type("String"));
		
		If Not RowWithItemPreventingDeletion.IsError Then
			FoundItemInformation = TypeInformation.Get(Reason.FoundType);
			
			RowWithItemPreventingDeletion.ReferenceType = FoundItemInformation.Ref;
			
			If Reason.FoundItemReference = Undefined Then // Constant
				RowWithItemPreventingDeletion.FoundItemReference = FoundItemInformation.FullName;
				RowWithItemPreventingDeletion.IsConstant = True;
				RowWithItemPreventingDeletion.Presentation = FoundItemInformation.ItemPresentation + " (" + NStr("en = 'Constant'") + ")";
			Else
				RowWithItemPreventingDeletion.Presentation = String(Reason.FoundItemReference) + " (" + FoundItemInformation.ItemPresentation + ")";
			EndIf;
			
			RowWithItemPreventingDeletion.PictureNumber = PictureNumber(
				RowWithItemPreventingDeletion.FoundItemReference,
				RowWithItemPreventingDeletion.ReferenceType,
				FoundItemInformation.Kind,
				RowWithItemPreventingDeletion.DeletionMark);
		EndIf;
	EndDo;
	
	For Each NotDeletedItemGroup In NotDeletedItemsTree.Rows Do
		NotDeletedItemGroup.Presentation = NotDeletedItemGroup.Presentation + " (" + Format(NotDeletedItemGroup.ReferenceCount, "NZ=0;NG=") + ")";
	EndDo;
	
	NotDeletedItemsTree.Rows.Sort("Presentation", True);
	NotDeletedItemLinksTable.Sort("ItemToDeleteReference, Presentation");
	
	ValueToFormAttribute(NotDeletedItemsTree,      "NotDeletedItems");
	ValueToFormAttribute(NotDeletedItemLinksTable, "NotDeletedItemLinks");
EndProcedure

#EndRegion
