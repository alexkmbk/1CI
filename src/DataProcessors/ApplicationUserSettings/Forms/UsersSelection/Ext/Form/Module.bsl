
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
 
	// Skipping the initialization to guarantee that the form will be received if the Autotest parameter is passed.
	If Parameters.Property("Autotest") Then 
		Return;
	EndIf;
	
	If Parameters.UserType = Type("CatalogRef.ExternalUsers") Then
		AllUsersGroup = Catalogs.ExternalUserGroups.AllExternalUsers;
	Else
		AllUsersGroup = Catalogs.UserGroups.AllUsers;
	EndIf;
	
	WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
	UseGroups = GetFunctionalOption("UseUserGroups");
	UserSource = Parameters.User;
	UserType = Parameters.UserType;
	FillUserList(UserType, UseGroups);
	
	CopyAll = (Parameters.ActionType = "CopyAll");
	SettingsClearing = (Parameters.ActionType = "Clearing");
	If SettingsClearing Then
		Title = NStr("en='Select users to clear settings'");
		Items.Label.Title = NStr("en='Select users whose settings you want to clear'");
	EndIf;
	
	If Parameters.Property("SelectedUsers") Then
		MarkPassedUsers = True;
		
		If Parameters.SelectedUsers <> Undefined Then
			
			For Each SelectedUser In Parameters.SelectedUsers Do
				MarkUser(SelectedUser);
			EndDo;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnSaveDataInSettingsAtServer(Settings)
	
	Settings.Delete("AllUsersList");
	
	// If the form is opened from the "Clear application user settings" form or from the "Copy application user settings" form, do not save the settings.
	If MarkPassedUsers Then
		Return;
	EndIf;
	
	FilterParameters = New Structure("Mark", True);
	MarkedUsersList = New ValueList;
	MarkedUsersArray  = AllUsersList.FindRows(FilterParameters);
	
	For Each ArrayRow In MarkedUsersArray  Do
		MarkedUsersList.Add(ArrayRow.User);
	EndDo;
	
	Settings.Insert("MarkedUsers", MarkedUsersList);
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	// If the form is opened from the "Application user settings clearing" form or from the "Application user settings copying" form, do not load the settings
	If MarkPassedUsers Then
		Settings.Delete("AllUsersList");
		Settings.Delete("MarkedUsers");
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	MarkedUsers = Settings.Get("MarkedUsers");
	
	If MarkedUsers = Undefined Then
		Return;
	EndIf;
	
	For Each MarkedUserRow In MarkedUsers Do
		
		UserRef = MarkedUserRow.Value;
		MarkUser(UserRef);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateGroupTitlesOnToggleCheckBox();
	
EndProcedure

#EndRegion

#Region FormHeaderItemEventHandlers

&AtClient
Procedure UserGroupsOnActivateRow(Item)
	
	SelectedGroup = Item.CurrentData;
	If SelectedGroup = Undefined Then
		Return;
	EndIf;
	
	ApplyGroupFilter(SelectedGroup);
	If UseGroups Then
		Items.ShowNestedGroupUsersGroup.CurrentPage = Items.SetPropertyGroup;
	Else
		Items.ShowNestedGroupUsersGroup.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure UserListChoice(Item, SelectedRow, Field, StandardProcessing)
	
	StandardProcessing = False;
	ShowValue(,Item.CurrentData.User);
	
EndProcedure

&AtClient
Procedure UserGroupsSelection(Item, SelectedRow, Field, StandardProcessing)
	
	ShowValue(,Item.CurrentData.Group);
	
EndProcedure

&AtClient
Procedure ShowNestedGroupUsersOnChange(Item)
	
	SelectedUserGroup = Items.UserGroups.CurrentData;
	ApplyGroupFilter(SelectedUserGroup);
	
	// Updating group titles
	ClearGroupTitles();
	UpdateGroupTitlesOnToggleCheckBox();
	
EndProcedure

&AtClient
Procedure UsersCheckBoxOnChange(Item)
	
	UserListRow  = Item.Parent.Parent.CurrentData;
	UserListRow .Check = Not UserListRow .Check;
	ChangeMark(UserListRow , Not UserListRow .Check);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Select(Command)
	
	UsersTarget = New Array;
	For Each Item In UserList Do
		
		If Item.Check Then
			UsersTarget.Add(Item.User);
		EndIf;
		
	EndDo;
	
	If UsersTarget.Count() = 0 Then
		ShowMessageBox(,NStr("en = 'Select one or several users.'"));
		Return;
	EndIf;
	
	Result = New Structure("UsersTarget, CopyAll, SettingsClearing", 
		UsersTarget, CopyAll, SettingsClearing);
	Notify("UserSelection", Result);
	Close();
	
EndProcedure

&AtClient
Procedure MarkAll(Command)
	
	For Each UserListRow In UserList Do
		ChangeMark(UserListRow , True);
	EndDo;
	
EndProcedure

&AtClient
Procedure MarkSelectedItems(Command)
	
	SelectedItems = Items.UserList.SelectedRows;
	
	If SelectedItems.Count() = 0 Then
		Return;
	EndIf;
	
	For Each Item In SelectedItems Do
		UserListRow  = UserList.FindByID(Item);
		ChangeMark(UserListRow , True);
	EndDo;
	
EndProcedure

&AtClient
Procedure ClearAllMarks(Command)
	
	For Each UserListRow  In UserList Do
		ChangeMark(UserListRow , False);
	EndDo;
EndProcedure

&AtClient
Procedure ClearMarkForSelectedItems(Command)
	
	SelectedItems = Items.UserList.SelectedRows;
	
	If SelectedItems.Count() = 0 Then
		Return;
	EndIf;
	
	For Each Item In SelectedItems Do
		UserListRow  = UserList.FindByID(Item);
		ChangeMark(UserListRow , False);
	EndDo;
	
EndProcedure

&AtClient
Procedure ModifyUserOrGroup(Command)
	
	CurrentValue = CurrentItem.CurrentData;
	
	If TypeOf(CurrentValue) = Type("FormDataCollectionItem") Then
		
		ShowValue(,CurrentValue.User);
		
	ElsIf TypeOf(CurrentValue) = Type("FormDataTreeItem") Then
		
		ShowValue(,CurrentValue.Group);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ActiveUsers(Command)
	
	StandardSubsystemsClient.OpenActiveUserList();
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UserGroupsGroup.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UserGroups.UserMarkCount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , True, False, False, False, ));
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("UserGroups.GroupDescriptionAndUserMarkCount"));

EndProcedure

&AtServer
Procedure MarkUser(UserRef)
	
	For Each AllUsersListRow In AllUsersList Do
		
		If AllUsersListRow.User = UserRef Then
			AllUsersListRow.Check = True;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure UpdateGroupTitlesOnToggleCheckBox()
	
	For Each UserGroup In UserGroups.GetItems() Do
		
		For Each UserListRow  In AllUsersList Do
			
			If UserListRow .Check Then
				MarkValue = True;
				UserListRow .Check = False;
				UpdateGroupTitle(ThisObject, UserGroup, UserListRow , MarkValue);
				UserListRow .Check = True;
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ClearGroupTitles()
	
	For Each UserGroup In UserGroups.GetItems() Do
		ClearGroupTitle(UserGroup);
	EndDo;
	
EndProcedure

&AtClient
Procedure ClearGroupTitle(UserGroup)
	
	UserGroup.UserMarkCount = 0;
	Subgroups = UserGroup.GetItems();
	
	For Each Subgroup In Subgroups Do
	
		ClearGroupTitle(Subgroup);
	
	EndDo;
	
EndProcedure

&AtClient
Procedure ChangeMark(UserListRow , MarkValue)
	
	If UseGroups Then
		
		UpdateGroupTitles(ThisObject, UserListRow , MarkValue);
		
		UserListRow .Check = MarkValue;
		Filter = New Structure("User", UserListRow .User); 
		FoundUsers = AllUsersList.FindRows(Filter);
		For Each FoundUser In FoundUsers Do
			FoundUser.Check = MarkValue;
		EndDo;
	Else
		UserListRow .Check = MarkValue;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateGroupTitles(Form, UserListRow , MarkValue)
	
	For Each UserGroup In Form.UserGroups.GetItems() Do
		
		UpdateGroupTitle(Form, UserGroup, UserListRow , MarkValue);
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateGroupTitle(Form, UserGroup, UserListRow , MarkValue)
	
	UserRef = UserListRow .User;
	If Form.ShowNestedGroupUsers 
		OR Form.AllUsersGroup = UserGroup.Group Then
		Content = UserGroup.FullContent;
	Else
		Content = UserGroup.Content;
	EndIf;
	MarkedUser = Content.FindByValue(UserRef);
	
	If MarkedUser <> Undefined And MarkValue <> UserListRow .Check Then
		UserMarkCount = UserGroup.UserMarkCount;
		UserGroup.UserMarkCount = ?(MarkValue, UserMarkCount + 1, UserMarkCount - 1);
		UserGroup.GroupDescriptionAndUserMarkCount = 
			StringFunctionsClientServer.SubstituteParametersInString(NStr("en='%1 (%2)'"),
			String(UserGroup.Group), UserGroup.UserMarkCount);
	EndIf;
	
	// Update the titles of all subgroups recursively
	Subgroups = UserGroup.GetItems();
	For Each SubGroup In Subgroups Do
		UpdateGroupTitle(Form, SubGroup, UserListRow , MarkValue);
	EndDo;
	
EndProcedure

&AtClient
Procedure ApplyGroupFilter(CurrentGroup)
	
	UserList.Clear();
	If CurrentGroup = Undefined Then
		Return;
	EndIf;
	
	If ShowNestedGroupUsers Then
		GroupContent = CurrentGroup.FullContent;
	Else
		GroupContent = CurrentGroup.Content;
	EndIf;
	For Each Item In AllUsersList Do
		
		If GroupContent.FindByValue(Item.User) <> Undefined
			OR AllUsersGroup = CurrentGroup.Group Then
			RowUserList = UserList.Add();
			RowUserList.User = Item.User;
			RowUserList.Check = Item.Check;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillUserList(UserType, UseGroups);
	
	GroupTree = FormAttributeToValue("UserGroups");
	AllUsersListTable = FormAttributeToValue("AllUsersList");
	UserListTable = FormAttributeToValue("UserList");
	
	If UserType = Type("CatalogRef.ExternalUsers") Then
		ExternalUser = True;
	Else
		ExternalUser = False;
	EndIf;
	
	If UseGroups Then
		DataProcessors.ApplicationUserSettings.FillGroupTree(GroupTree, ExternalUser);
		AllUsersListTable = DataProcessors.ApplicationUserSettings.UsersToCopy(
			UserSource, AllUsersListTable, ExternalUser);
	Else
		UserListTable = DataProcessors.ApplicationUserSettings.UsersToCopy(
			UserSource, UserListTable, ExternalUser);
	EndIf;
	
	GroupTree.Rows.Sort("Group Asc");
	RowToMove  = GroupTree.Rows.Find(AllUsersGroup, "Group");
	
	If RowToMove  <> Undefined Then
		LineIndex = GroupTree.Rows.IndexOf(RowToMove );
		GroupTree.Rows.Move(LineIndex, -LineIndex);
	EndIf;
	
	ValueToFormAttribute(GroupTree, "UserGroups");
	ValueToFormAttribute(UserListTable, "UserList");
	ValueToFormAttribute(AllUsersListTable, "AllUsersList");
	
EndProcedure

#EndRegion
