#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	// Skipping the initialization to guarantee that the form will be received if the SelfTest parameter is passed.
	If Parameters.Property("SelfTest") Then
		Return;
	EndIf;
	
	ListToEdit = Parameters.ListToEdit;
	ParametersToSelect = Parameters.ParametersToSelect;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetEditorParameters(ListToEdit, ParametersToSelect);
	
EndProcedure

#EndRegion


#Region FormHeaderItemEventHandlers

&AtClient
Procedure CheckOnChange(Item)
	SelectTreeItem(Items.List.CurrentData, Items.List.CurrentData.Check);
EndProcedure

#EndRegion


#Region FormCommandHandlers

&AtClient
Procedure ChooseFilterContent(Command)
	
	Notify("EventLogFilterItemValueChoice",
	 GetEditedList(),
	 FormOwner);
	Close();
	
EndProcedure

&AtClient
Procedure CheckAll(Command)
	SetMarks(True);
EndProcedure

&AtClient
Procedure UncheckAll(Command)
	SetMarks(False);
EndProcedure
 

#EndRegion

#Region InternalProceduresAndFunctions

&AtClient
Procedure SetEditorParameters(ListToEdit, ParametersToSelect)
	FilterParameterStructure = GetEventLogFilterValuesByColumn(ParametersToSelect);
	FilterValues = FilterParameterStructure[ParametersToSelect];
 
	// Getting a list of event presentations
	If ParametersToSelect = "Event" Then
		
		For Each MapItem In FilterValues Do
			EventPresentationString = EventPresentations.Add();
			EventPresentationString.Presentation = MapItem.Value;
		EndDo;
		
	EndIf;
	
	If TypeOf(FilterValues) = Type("Array") Then
		ListItems = List.GetItems();
		For Each ArrayElement In FilterValues Do
			NewItem = ListItems.Add();
			NewItem.Check = False;
			NewItem.Value = ArrayElement;
			NewItem.Presentation = ArrayElement;
		EndDo;
	ElsIf TypeOf(FilterValues) = Type("Map") Then
		
		If ParametersToSelect = "Event" Or
			 ParametersToSelect = "Metadata" Then  
			// Getting as a tree
			For Each MapItem In FilterValues Do
				EventFilterParameters = New Structure("Presentation", MapItem.Value);
				
				If MapItem.Key = MapItem.Value
					And EventPresentations.FindRows(EventFilterParameters).Count() > 1 Then
					AppliedSolutionEvents.Add(MapItem.Key, MapItem.Value);
					Continue;
				EndIf;
				
				NewItem = GetTreeBranch(MapItem.Value);
				NewItem.Check = False;
				NewItem.Value = MapItem.Key;
				NewItem.FullPresentation = MapItem.Value;
			EndDo;
			
		Else 
			// Getting as a flat list
			ListItems = List.GetItems();
			For Each MapItem In FilterValues Do
				NewItem = ListItems.Add();
				NewItem.Check = False;
				NewItem.Value = MapItem.Key;
				
				If ParametersToSelect = "User" Then
					// In this case the user name serves as a key 
					NewItem.Value = MapItem.Value;
					NewItem.Presentation = MapItem.Value;
					NewItem.FullPresentation = MapItem.Value;
					
					If NewItem.Value = "" Then
						// In case of default user
						NewItem.Value = "";
						NewItem.FullPresentation = UnspecifiedUserFullName();
						NewItem.Presentation = UnspecifiedUserFullName();
					Else
						// In case of internal user
						InternalUserPresentation = InternalUserFullName(MapItem.Key);
						If Not IsBlankString(InternalUserPresentation) Then
							
							NewItem.FullPresentation = InternalUserPresentation;
							NewItem.Presentation = InternalUserPresentation;
							
						EndIf;
					EndIf;
					
				Else
					NewItem.Presentation = MapItem.Value;
					NewItem.FullPresentation = MapItem.Value;
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	// Selecting marks of tree items that are mapped to ListToEdit items
	SelectFoundItems(List.GetItems(), ListToEdit);
	
	// Finding child items in the list. If there are no such items,
	// switching the control in a list mode.
	IsTree = False;
	For Each TreeItem In List.GetItems() Do
		If TreeItem.GetItems().Count() > 0 Then 
			IsTree = True;
			Break;
		EndIf;
	EndDo;
	If Not IsTree Then
		Items.List.Representation = TableRepresentation.List;
	EndIf;
	
 	OrderTreeItems();	
	
EndProcedure

&AtClient
Function GetEditedList()
	
	ListToEdit = New ValueList;
	
	ListToEdit.Clear();
	HasNotSelected = False;
	GetSubtreeList(ListToEdit, List.GetItems(), HasNotSelected);
	AddAppliedSolutionEvents();
	
	Return ListToEdit;
	
EndFunction
 
 &AtClient

Procedure AddAppliedSolutionEvents()
	
	For Each Event In AppliedSolutionEvents Do
		ListToEdit.Add(Event.Value, Event.Presentation);
	EndDo;
	
EndProcedure

&AtClient
Function GetTreeBranch(Presentation)
	PathStrings = SplitStringByDots(Presentation);
	If PathStrings.Count() = 1 Then
		TreeItems = List.GetItems();
		BranchName = PathStrings[0];
	Else
		// Assembling a path to parent branch by path fragments
		ParentPathPresentation = "";
		For Cnt = 0 to PathStrings.Count() - 2 Do
			If Not IsBlankString(ParentPathPresentation) Then
				ParentPathPresentation = ParentPathPresentation + ".";
			EndIf;
			ParentPathPresentation = ParentPathPresentation + PathStrings[Cnt];
		EndDo;
		TreeItems = GetTreeBranch(ParentPathPresentation).GetItems();
		BranchName = PathStrings[PathStrings.Count() - 1];
	EndIf;
	
	For Each TreeItem In TreeItems Do
		If TreeItem.Presentation = BranchName 
			And TreeItem.GetItems().Count() > 0 Then
			Return TreeItem;
		EndIf;
	EndDo;
	// The tree item is not found, it have to be created 
	TreeItem = TreeItems.Add();
	TreeItem.Presentation = BranchName;
	TreeItem.Check = False;
	Return TreeItem;
EndFunction

// Splits a string into an Array of String using dot(.) as a separator
&AtClient
Function SplitStringByDots(Val Presentation)
	Fragments = New Array;
	While True Do
		Presentation = TrimAll(Presentation);
		DotPosition = Find(Presentation, ".");
		If DotPosition > 0 Then
			Fragment = TrimAll(Left(Presentation, DotPosition - 1));
			Fragments.Add(Fragment);
			Presentation = Mid(Presentation, DotPosition + 1);
		Else
			Fragments.Add(TrimAll(Presentation));
			Break;
		EndIf;
	EndDo;
	Return Fragments;
EndFunction

&AtServer
Function GetEventLogFilterValuesByColumn(ParametersToSelect)
	Return GetEventLogFilterValues(ParametersToSelect);
EndFunction

&AtClient
Procedure GetSubtreeList(ListToEdit, TreeItems, HasNotSelected)
	For Each TreeItem In TreeItems Do
		If TreeItem.GetItems().Count() <> 0 Then
			GetSubtreeList(ListToEdit, TreeItem.GetItems(), HasNotSelected);
		Else
			If TreeItem.Check Then
				NewListItem = ListToEdit.Add();
				NewListItem.Value = TreeItem.Value;
				NewListItem.Presentation = TreeItem.FullPresentation;
			Else
				HasNotSelected = True;
			EndIf;
		EndIf;
	EndDo;
EndProcedure

&AtClient
Procedure SelectFoundItems(TreeItems, ListToEdit)
 	For Each TreeItem  In TreeItems Do
		
		If TreeItem.GetItems().Count() <> 0 Then 
			SelectFoundItems(TreeItem.GetItems(), ListToEdit);
		Else
			
			For Each  ListItem In ListToEdit Do
				
				If TreeItem.FullPresentation =  ListItem.Presentation Then
					SelectTreeItem(TreeItem, True);
					Break;
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure
 
&AtClient
Procedure SelectTreeItem(TreeItem, Check, CheckParentState = True)
	TreeItem.Check = Check;
	// Selecting marks of all child items of tree 
	For Each TreeChildItem In TreeItem.GetItems() Do
		SelectTreeItem(TreeChildItem, Check, False);
	EndDo;
	// Checking if parent item state should be changed.
	If CheckParentState Then
		CheckBranchMarked(TreeItem.GetParent());
	EndIf;
EndProcedure

&AtClient
Procedure CheckBranchMarked(Branch)
	If Branch = Undefined Then 
		Return;
	EndIf;
	ChildBranches = Branch.GetItems();
	If ChildBranches.Count() = 0 Then
		Return;
	EndIf;
	
	HasTrue = False;
	HasFalse = False;
	For Each ChildBranche In ChildBranches Do
		If ChildBranche .Check Then
			HasTrue = True;
			If HasFalse Then
				Break;
			EndIf;
		Else
			HasFalse = True;
			If HasTrue Then
				Break;
			EndIf;
		EndIf;
	EndDo;
	
	If HasTrue Then
		If HasFalse Then
			// There are branches with both selected and cleared marks. If necessary, 
			// clearing the mark of the current item and then checking the parent.
			If Branch.Check Then
				Branch.Check = False;
				CheckBranchMarked(Branch.GetParent());
			EndIf;
		Else
			// All child branch marks are selected
			If Not Branch.Check Then
				Branch.Check = True;
				CheckBranchMarked(Branch.GetParent());
			EndIf;
		EndIf;
	Else
		// All child branch marks are cleared
		If Branch.Check Then
			Branch.Check = False;
			CheckBranchMarked(Branch.GetParent());
		EndIf;
	EndIf;
EndProcedure

&AtClient
Function AssemblePresentation(TreeItem)
	If TreeItem = Undefined Then 
		Return "";
	EndIf;
	If TreeItem.GetParent() = Undefined Then
		Return TreeItem.Presentation;
	EndIf;
	Return AssemblePresentation(TreeItem.GetParent()) + "." + TreeItem.Presentation;
EndFunction

&AtClient
Procedure SetMarks(Value)
	For Each TreeItem In List.GetItems() Do
		SelectTreeItem(TreeItem, Value, False);
	EndDo;
EndProcedure


 &AtServer

Procedure OrderTreeItems()
	
	ListTree = FormAttributeToValue("List");
	ListTree.Strings.Sort("Presentation Asc", True);
	ValueToFormAttribute(ListTree, "List");
	
EndProcedure

&AtServerNoContext
Function UnspecifiedUserFullName()
	
	Return Users.UnspecifiedUserFullName();
	
EndFunction

&AtServerNoContext
Function InternalUserFullName(InfobaseUserID)
	
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations") Then
		
		SaaSOperationsModule = CommonUse.CommonModule("SaaSOperations");
		Return SaaSOperationsModule.InfobaseUserAlias(InfobaseUserID);
		
	EndIf;
	
EndFunction

#EndRegion