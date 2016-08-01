	
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	// Skipping the initialization to guarantee that the form will be received if the Autotest parameter is passed.
	If Parameters.Property("Autotest") Then 
		Return;
	EndIf;
	
	If Object.Ref = Catalogs.UserGroups.EmptyRef()
	   And Object.Parent = Catalogs.UserGroups.AllUsers Then
		
		Object.Parent = Catalogs.UserGroups.EmptyRef();
	EndIf;
	
	If Object.Ref = Catalogs.UserGroups.AllUsers Then
		ReadOnly = True;
	EndIf;
	
	FillUsersStatus();
	
	RefreshNotValidUserList(True);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_UserGroups", New Structure, Object.Ref);
	
EndProcedure

#EndRegion

#Region FormHeaderItemEventHandlers

&AtClient
Procedure ParentStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	FormParameters = New Structure;
	FormParameters.Insert("ChoiceMode", True);
	FormParameters.Insert("ChooseParent");
	
	OpenForm("Catalog.UserGroups.ChoiceForm", FormParameters, Items.Parent);
	
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonUseClient.ShowCommentEditingForm(
		Item.EditText, ThisObject, "Object.Comment");
	
EndProcedure

#EndRegion

#Region ContentFormTableItemsEventHandlers

&AtClient
Procedure ContentChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	Object.Content.Clear();
	If TypeOf(SelectedValue) = Type("Array") Then
		
		For Each Value In SelectedValue Do
			UserSelectionProcessing(Value);
		EndDo;
		
	Else
		UserSelectionProcessing(SelectedValue);
	EndIf;
	
EndProcedure

&AtClient
Procedure ContentDrag(Item, DragParameters, StandardProcessing, Row, Field)
	
	StandardProcessing = False;
	UserMessage = MoveUserToTheGroup(DragParameters.Value, Object.Ref);
	If UserMessage <> Undefined Then
		ShowUserNotification(
			NStr("en = 'Moving users'"), , UserMessage, PictureLib.Information32);
	EndIf;
		
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure PickUsers(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("ChoiceMode", True);
	FormParameters.Insert("CloseOnChoice", False);
	FormParameters.Insert("MultipleChoice", True);
	FormParameters.Insert("ExtendedPick", True);
	FormParameters.Insert("ExtendedPickFormParameters", ExtendedPickFormParameters());
	
	OpenForm("Catalog.Users.ChoiceForm", FormParameters, Items.Content);

EndProcedure

&AtClient
Procedure ShowNotValidUsers(Command)
	
	RefreshNotValidUserList(False);
	
EndProcedure

&AtClient
Procedure SortAsc(Command)
	ContentSortRows("Ascending");
EndProcedure

&AtClient
Procedure SortDesc(Command)
	ContentSortRows("Descending");
EndProcedure

&AtClient
Procedure MoveUp(Command)
	ContentMoveRow("Up");
EndProcedure

&AtClient
Procedure MoveDown(Command)
	ContentMoveRow("Down");
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.User.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Content.NotValid");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", WebColors.Gray);

EndProcedure

&AtClient
Procedure UserSelectionProcessing(SelectedValue)
	
	If TypeOf(SelectedValue) = Type("CatalogRef.Users") Then
		Object.Content.Add().User = SelectedValue;
	EndIf;
	
EndProcedure

&AtServer
Function MoveUserToTheGroup(UserArray, NewOwnerGroup)
	
	MovedUsersArray = New Array;
	For Each UserRef In UserArray Do
		
		FilterParameters = New Structure("User", UserRef);
		If TypeOf(UserRef) = Type("CatalogRef.Users")
			And Object.Content.FindRows(FilterParameters).Count() = 0 Then
			Object.Content.Add().User = UserRef;
			MovedUsersArray.Add(UserRef);
		EndIf;
		
	EndDo;
	
	Return UsersInternal.UserMessageCreation(
		MovedUsersArray, NewOwnerGroup, False);
	
EndFunction

&AtServer
Function ExtendedPickFormParameters()
	
	SelectedUsers = New ValueTable;
	SelectedUsers.Columns.Add("User");
	SelectedUsers.Columns.Add("PictureNumber");
	
	GroupMembers = Object.Content.Unload(, "User");
	
	For Each Item In GroupMembers Do
		
		RowSelectedUsers = SelectedUsers.Add();
		RowSelectedUsers.User = Item.User;
		
	EndDo;
	
	PickFormTitle = NStr("en = 'Pick user group members'");
	ExtendedPickFormParameters = 
		New Structure("PickFormTitle, SelectedUsers, SelectionOfGroupsIsNotPossible",
		                 PickFormTitle, SelectedUsers, True);
	StorageAddress = PutToTempStorage(ExtendedPickFormParameters);
	Return StorageAddress;
	
EndFunction

&AtServer
Procedure FillUsersStatus()
	
	For Each GroupContentRow In Object.Content Do
		GroupContentRow.NotValid = 
			CommonUse.ObjectAttributeValue(GroupContentRow.User, "NotValid");
	EndDo;
	
EndProcedure

&AtServer
Procedure RefreshNotValidUserList(BeforeOpenForm)
	
	Items.ShowNotValidUsers.Check = ?(BeforeOpenForm, False,
		Not Items.ShowNotValidUsers.Check);
	
	Filter = New Structure;
	
	If Not Items.ShowNotValidUsers.Check Then
		Filter.Insert("NotValid", False);
		Items.Content.RowFilter = New FixedStructure(Filter);
	Else
		Items.Content.RowFilter = New FixedStructure();
	EndIf;
	
EndProcedure

&AtServer
Procedure ContentSortRows(OrderType)
	
	If Not Items.ShowNotValidUsers.Check Then
		Items.Content.RowFilter = New FixedStructure();
	EndIf;
	
	If OrderType = "Ascending" Then
		Object.Content.Sort("User Asc");
	Else
		Object.Content.Sort("User Desc");
	EndIf;
	
	If Not Items.ShowNotValidUsers.Check Then
		Filter = New Structure;
		Filter.Insert("NotValid", False);
		Items.Content.RowFilter = New FixedStructure(Filter);
	EndIf;
	
EndProcedure

&AtServer
Procedure ContentMoveRow(MovementDirection)
	
	Row = Object.Content.FindByID(Items.Content.CurrentRow);
	If Row = Undefined Then
		Return;
	EndIf;
	
	CurrentRowIndex = Row.LineNumber - 1;
	Move = 0;
	
	While True Do
		Move = Move + ?(MovementDirection = "Up", -1, 1);
		
		If CurrentRowIndex + Move < 0
		Or CurrentRowIndex + Move >= Object.Content.Count() Then
			Return;
		EndIf;
		
		If Items.ShowNotValidUsers.Check
		 Or Object.Content[CurrentRowIndex + Move].NotValid = False Then
			Break;
		EndIf;
	EndDo;
	
	Object.Content.Move(CurrentRowIndex, Move);
	Items.Content.Refresh();
	
EndProcedure

#EndRegion
