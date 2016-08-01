////////////////////////////////////////////////////////////////////////////////
// Choice form for fields of Exchange plan node type.
//
//////////////////////////////////////////////////////////////////////////////// 

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skipping the initialization to guarantee that the form will be received if the SelfTest parameter is passed.
	If Parameters.Property("SelfTest") Then
		Return;
	EndIf;

	// Handling standard parameters 
	If Parameters.CloseOnChoice = False Then
		PickMode = True;
		If Parameters.Property("MultipleChoice") And Parameters.MultipleChoice = True Then
			MultipleChoice = True;
		EndIf;
	EndIf;
	
	// Preparing the list of used exchange plans
	If TypeOf(Parameters.ExchangePlansForChoice) = Type("Array") Then
		For Each Item In Parameters.ExchangePlansForChoice Do
			If TypeOf(Item) = Type("String") Then
				// Searching for the exchange plan by name
				AddUsedExchangePlan(Metadata.FindByFullName(Item));
				AddUsedExchangePlan(Metadata.FindByFullName("ExchangePlan." + Item));
				
			ElsIf TypeOf(Item) = Type("Type") Then
				// Searching for the exchange plan by type
				AddUsedExchangePlan(Metadata.FindByType(Item));
			Else
				// Searching for the exchange plan by type of the specified node 
				AddUsedExchangePlan(Metadata.FindByType(TypeOf(Item)));
			EndIf;
		EndDo;
	Else
		// All exchange plans are taking part in the choice
		For Each MetadataObject In Metadata.ExchangePlans Do
			AddUsedExchangePlan(MetadataObject);
		EndDo;
	EndIf;
	
	ExchangePlanNodes.Sort("ExchangePlanPresentation Asc");
	
	If PickMode Then
		Title = NStr("en = 'Fill exchange plan nodes'");
	EndIf;
	If MultipleChoice Then
		Items.ExchangePlanNodes.SelectionMode = TableSelectionMode.MultiRow;
	EndIf;
	
	CurrentRow = Undefined;
	Parameters.Property("CurrentRow", CurrentRow);
	
	FoundRows = ExchangePlanNodes.FindRows(New Structure("Node", CurrentRow));
	
	If FoundRows.Count() > 0 Then
		Items.ExchangePlanNodes.CurrentRow = FoundRows[0].GetID();
	EndIf;
	
EndProcedure

#EndRegion

#Region ExchangePlanNodesFormTableItemEventHandlers

&AtClient
Procedure ExchangePlanNodesChoice(Item, SelectedRow, Field, StandardProcessing)
	
	If MultipleChoice Then
		ChoiceValue = New Array;
		ChoiceValue.Add(ExchangePlanNodes.FindByID(SelectedRow).Node);
		NotifyChoice(ChoiceValue);
	Else
		NotifyChoice(ExchangePlanNodes.FindByID(SelectedRow).Node);
	EndIf;
	
EndProcedure

#EndRegion


#Region FormCommandHandlers

&AtClient
Procedure Select(Command)
	
	If MultipleChoice Then

		ChoiceValue = New Array;
		For Each SelectedRow In Items.ExchangePlanNodes.SelectedRows Do
			ChoiceValue.Add(ExchangePlanNodes.FindByID(SelectedRow).Node)
		EndDo;
		NotifyChoice(ChoiceValue);
	Else
		CurrentData = Items.ExchangePlanNodes.CurrentData;

		If CurrentData = Undefined Then
			ShowMessageBox(, NStr("en = 'Node is not selected.'"));
		Else
			NotifyChoice(CurrentData.Node);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion


#Region InternalProceduresAndFunctions

&AtServer
Procedure AddUsedExchangePlan(MetadataObject)
	
	If MetadataObject = Undefined
		or Not Metadata.ExchangePlans.Contains(MetadataObject) Then
		Return;
	EndIf;
	ExchangePlan = CommonUse.ObjectManagerByFullName(MetadataObject.FullName()).EmptyRef();
	ExchangePlanPresentation = MetadataObject.Synonym;
	
	// Filling nodes of used exchange plans 
	If Parameters.ChooseAllNodes Then
		NewRow = ExchangePlanNodes.Add();
		NewRow.ExchangePlan = ExchangePlan;
		NewRow.ExchangePlanPresentation = MetadataObject.Synonym;
		NewRow.Node = ExchangePlan;
		NewRow.NodePresentation = NStr("en = '<All Infobases>'");
	EndIf;
	
	Query = New Query;
	Query.SetParameter("ThisNode", ExchangePlans[MetadataObject.Name].ThisNode());
	Query.Text =
	"SELECT
	|	ExchangePlanTable.Ref,
	|	ExchangePlanTable.Presentation AS Presentation
	|FROM
	|	&ExchangePlanTable AS ExchangePlanTable
	|WHERE
	|	ExchangePlanTable.Ref <> &ThisNode
	|
	|ORDER BY
	|	Presentation";
	Query.Text = StrReplace(Query.Text, "&ExchangePlanTable", MetadataObject.FullName());
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		NewRow = ExchangePlanNodes.Add();
		NewRow.ExchangePlan = ExchangePlan;
		NewRow.ExchangePlanPresentation = MetadataObject.Synonym;
		NewRow.Node = Selection.Ref;
		NewRow.NodePresentation = Selection.Presentation;
	EndDo;
	
EndProcedure

#EndRegion