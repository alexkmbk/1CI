//                          FORM OPERATIONS                                   //
//
// Additional parameters for opening the form that is used for picking users:
//
// ExtendedPick               - Boolean - if True, open the extended form for picking users. 
//                              The extended form requires the ExtendedPickFormParameters parameter.
// ExtendedPickFormParameters - String  - reference to a structure that contains extended parameters 
//                              for the form used for picking users. The structure is located 
//                              in a temporary storage.
//  Structure parameters:
//    PickFormTitle - String - the form title.
//    SelectedUsers - Array  - array of users selected before opening the form.
//
 
#Region FormEventHandlers
 
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	// Skipping the initialization to guarantee that the form will be received if the Autotest parameter is passed.
	If Parameters.Property("Autotest") Then 
		Return;
	EndIf;
 
	If Not CommonUse.OnCreateAtServer(ThisObject, Cancel, StandardProcessing) Then
		Return;
	EndIf;
 
	// Setting initial value before it is loaded from the settings.
	SelectHierarchy = True;
 
	FillSavedParameters();
 
	If Parameters.ChoiceMode Then
		PurposeUseKey = "SelectionPick";
		WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
	EndIf;
 
	// Hiding users with blank IDs if the parameter value is True.
	If Parameters.HideUsersWithNoMatchingInfobaseUser Then
		CommonUseClientServer.SetDynamicListFilterItem(
			UsersList,
			"InfobaseUserID",
			New UUID("00000000-0000-0000-0000-000000000000"),
			DataCompositionComparisonType.NotEqual);
	EndIf;
 
	// Hiding internal users.
	CommonUseClientServer.SetDynamicListFilterItem(
		UsersList, "Internal", False, , , True);
 
	// Hiding users passed to the form.
	If TypeOf(Parameters.UsersToHide) = Type("ValueList") Then
 
		DCComparisonType = DataCompositionComparisonType.NotInList;
		CommonUseClientServer.SetDynamicListFilterItem(
			UsersList,
			"Ref",
			Parameters.UsersToHide,
			DCComparisonType);
 
	EndIf;
 
	ApplyConditionalAppearanceAndHideNonValidUsers();
 
	SetUpAllUsersGroupOrder(UserGroups);
 
	StoredParameters.Insert("ExtendedPick", Parameters.ExtendedPick);
	Items.SelectedUsersAndGroups.Visible = StoredParameters.ExtendedPick;
	StoredParameters.Insert(
		"UseGroups", GetFunctionalOption("UseUserGroups"));
 
	If Not AccessRight("Insert", Metadata.Catalogs.Users) Then
		Items.CreateUser.Visible = False;
	EndIf;
 
	If Not Users.InfobaseUserWithFullAccess(, CommonUseCached.ApplicationRunMode().Local) Then
		If Items.Find("InfobaseUsers") <> Undefined Then
			Items.InfobaseUsers.Visible = False;
		EndIf;
		Items.UserInfo.Visible = False;
	EndIf;
 
	If Parameters.ChoiceMode Then
 
		If Items.Find("InfobaseUsers") <> Undefined Then
			Items.InfobaseUsers.Visible = False;
		EndIf;
		Items.UserInfo.Visible = False;
 
		// Applying a filter that excludes items marked for deletion.
		CommonUseClientServer.SetDynamicListFilterItem(
			UsersList, "DeletionMark", False, , , True,
			DataCompositionSettingsItemViewMode.Normal);
 
		Items.UsersList.ChoiceMode = True;
		Items.UserGroups.ChoiceMode = StoredParameters.UserGroupSelection;
 
		// Disabling drag-and-drop operations in user selection forms and in forms used for picking users.
		Items.UsersList.EnableStartDrag = False;
 
		If Parameters.Property("NonExistentInfobaseUserIDs") Then
			CommonUseClientServer.SetDynamicListFilterItem(
				UsersList, "InfobaseUserID",
				Parameters.NonExistentInfobaseUserIDs,
				DataCompositionComparisonType.InList, , True,
				DataCompositionSettingsItemViewMode.Inaccessible);
		EndIf;
 
		If Parameters.CloseOnChoice = False Then
			// Picking mode
			Items.UsersList.MultipleChoice = True;
 
			If StoredParameters.ExtendedPick Then
				ThisObject.WindowOptionsKey = "ExtendedUsersPick";
				ChangeExtendedPickFormParameters();
			Else
				ThisObject.WindowOptionsKey = "UserPickMode";
			EndIf;
 
			If StoredParameters.UserGroupSelection Then
				Items.UserGroups.MultipleChoice = True;
			EndIf;
		EndIf;
	Else
		Items.Comments.Visible = False;
		Items.ChooseUser.Visible = False;
		Items.ChooseGroupUsers.Visible = False;
	EndIf;
 
	StoredParameters.Insert("AllUsersGroup", Catalogs.UserGroups.AllUsers);
	StoredParameters.Insert("CurrentRow", Parameters.CurrentRow);
	ConfigureUserGroupsUseForm();
	StoredParameters.Delete("CurrentRow");
 
	CommonUseClientServer.MoveFiltersToDynamicList(ThisObject, UsersList);
EndProcedure
 
&AtClient
Procedure OnOpen(Cancel)
 
	If Parameters.ChoiceMode Then
		CurrentFormItemChangeCheck();
	EndIf;
 
EndProcedure
 
&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
 
	If Upper(EventName) = Upper("Write_UserGroups")
	   And Source = Items.UserGroups.CurrentRow Then
 
		Items.UsersList.Refresh();
 
	ElsIf Upper(EventName) = Upper("Write_ConstantsSet") Then
 
		If Upper(Source) = Upper("UseUserGroups") Then
			AttachIdleHandler("UserGroupsUseOnChange", 0.1, True);
		EndIf;
 
		AttachIdleHandler("UserGroupsUseOnChange", 0.1, True);
 
	ElsIf Upper(EventName) = Upper("ArrangeUsersInGroups") Then
 
		Items.UsersList.Refresh();
 
	EndIf;
 
EndProcedure
 
&AtServer
Procedure BeforeImportDataFromSettingsAtServer(Settings)
 
	If TypeOf(Settings["SelectHierarchy"]) = Type("Boolean") Then
		SelectHierarchy = Settings["SelectHierarchy"];
	EndIf;
 
	If Not SelectHierarchy Then
		RefreshFormContentOnGroupChange(ThisObject);
	EndIf;
 
EndProcedure
 
#EndRegion
 
#Region FormHeaderItemEventHandlers
 
&AtClient
Procedure SelectHierarchicallyOnChange(Item)
 
	RefreshFormContentOnGroupChange(ThisObject);

EndProcedure

&AtClient
Procedure FlagShowNotValidUsersOnChange(Item)
	SwitchNonValidUsersVisibility(ShowNotValidUsers);
EndProcedure

#EndRegion

#Region UserGroupsListFormTableItemsEventHandlers
 
&AtClient
Procedure UserGroupsOnActivateRow(Item)
 
	AttachIdleHandler("UserGroupsAfterActivateRow", 0.1, True);
 
EndProcedure
 
&AtClient
Procedure UserGroupsValueChoice(Item, Value, StandardProcessing)
 
	StandardProcessing = False;
 
	If Not StoredParameters.ExtendedPick Then
		NotifyChoice(Value);
	Else
		GetPicturesAndFillSelectedItemsList(Value);
	EndIf;
 
EndProcedure
 
&AtClient
Procedure UserGroupsBeforeAddRow(Item, Cancel, Clone, Parent, Group)
 
	If Not Clone Then
		Cancel = True;
		FormParameters = New Structure;
 
		If ValueIsFilled(Items.UserGroups.CurrentRow) Then
			FormParameters.Insert(
				"FillingValues",
				New Structure("Parent", Items.UserGroups.CurrentRow));
		EndIf;
 
		OpenForm(
			"Catalog.UserGroups.ObjectForm",
			FormParameters,
			Items.UserGroups);
	EndIf;

EndProcedure
 
&AtClient
Procedure UserGroupsDrag(Item, DragParameters, StandardProcessing, Row, Field)
 
	StandardProcessing = False;
 
	If SelectHierarchy Then
		ShowMessageBox(,
			NStr("en = 'To be able to drag users to groups, clear the ""Show nested group users"" check box.'"));
		Return;
	EndIf;
 
	If Items.UserGroups.CurrentRow = Row
		Or Row = Undefined Then
		Return;
	EndIf;
 
	If DragParameters.Action = DragAction.Move Then
		Move = True;
	Else
		Move = False;
	EndIf;
	
	GroupMarkedForDeletion = Items.UserGroups.RowData(Row).DeletionMark;
	UserCount = DragParameters.Value.Count();
	
	ActionExcludeUser = (StoredParameters.AllUsersGroup = Row);
	
	ActionsWithUser = ?((StoredParameters.AllUsersGroup = Items.UserGroups.CurrentRow),
		NStr("en = add"),
		?(Move, NStr("en = 'move'"), NStr("en = 'copy'")));
	
	If GroupMarkedForDeletion Then
		ActionTemplate = ?(Move, NStr("en = 'Group ""%1"" is marked for deletion. %2'"), 
			NStr("en = 'Group ""%1"" is marked for deletion. %2'"));
		ActionsWithUser = StringFunctionsClientServer.SubstituteParametersInString(
			ActionTemplate, String(Row), ActionsWithUser);
	EndIf;
	
	If UserCount = 1 Then
		
		If ActionExcludeUser Then
			QuestionTemplate = NStr("en = 'Do you want to remove user ""%2"" from group ""%4""?'");
		ElsIf Not GroupMarkedForDeletion Then
			QuestionTemplate = NStr("en = 'Do you want to %1 user ""%2"" to group ""%3""?'");
		Else
			QuestionTemplate = NStr("en = 'Do you want to %1 user ""%2"" to the group?'");
		EndIf;
		QuestionText = StringFunctionsClientServer.SubstituteParametersInString(
			QuestionTemplate, ActionsWithUser, String(DragParameters.Value[0]),
			String(Row), String(Items.UserGroups.CurrentRow));
		
	Else
		
		If ActionExcludeUser Then
			QuestionTemplate = NStr("en = 'Do you want to remove %2 user(s) from group ""%4""?'");
		ElsIf Not GroupMarkedForDeletion Then
			QuestionTemplate = NStr("en = 'Do you want to %1 %2 user(s) to group ""%3""?'");
		Else
			QuestionTemplate = NStr("en = 'Do you want to %1 %2 user(s) to the group?'");
		EndIf;
		QuestionText = StringFunctionsClientServer.SubstituteParametersInString(
			QuestionTemplate, ActionsWithUser, UserCount,
			String(Row), String(Items.UserGroups.CurrentRow));
		
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("DragParameters", DragParameters.Value);
	AdditionalParameters.Insert("Row", Row);
	AdditionalParameters.Insert("Move", Move);
	
	Notification = New NotifyDescription("UserGroupsDragAndDropCompletion", ThisObject, AdditionalParameters);
	ShowQueryBox(Notification, QuestionText, QuestionDialogMode.YesNo, 60, DialogReturnCode.Yes);
	
EndProcedure

&AtClient
Procedure UserGroupsDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	
	StandardProcessing = False;
	
EndProcedure

#EndRegion

#Region UsersListFormTableItemsEventHandlers

&AtClient
Procedure UsersListValueChoice(Item, Value, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not StoredParameters.ExtendedPick Then
		NotifyChoice(Value);
	Else
		GetPicturesAndFillSelectedItemsList(Value);
	EndIf;
	
EndProcedure

&AtClient
Procedure UsersListBeforeAddRow(Item, Cancel, Clone, Parent, Group)
	
	Cancel = True;
	
	FormParameters = New Structure;
	FormParameters.Insert("NewUserGroup", Items.UserGroups.CurrentRow);
	
	If Clone
	   And Item.CurrentData <> Undefined Then
		
		FormParameters.Insert("CopyingValue", Item.CurrentRow);
	EndIf;
	
	OpenForm("Catalog.Users.ObjectForm", FormParameters, Items.UsersList);
	
EndProcedure

&AtClient
Procedure UsersListDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	
	StandardProcessing = False;
	
EndProcedure

#EndRegion

#Region SelectedUsersAndGroupsListFormTableItemsEventHandlers

&AtClient
Procedure SelectedUsersAndGroupsListCase(Item, SelectedRow, Field, StandardProcessing)
	
	DeleteFromSelectedItems();
	SelectedUsersLastModified = True;
	
EndProcedure

&AtClient
Procedure SelectedUsersAndGroupsListBeforeAddRow(Item, Cancel, Clone, Parent, Group, Parameter)
	Cancel = True;
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure CreateUserGroup(Command)
	
	Items.UserGroups.AddRow();
	
EndProcedure

&AtClient
Procedure ShowNotValidUsers(Command)
	ShowNotValidUsers = NOT Items.ShowNotValidUsers.Check;
	SwitchNonValidUsersVisibility(ShowNotValidUsers);
EndProcedure

&AtClient
Procedure AssignGroups(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("Users", Items.UsersList.SelectedRows);
	FormParameters.Insert("ExternalUsers", False);
	
	OpenForm("CommonForm.UserGroups", FormParameters);
	
EndProcedure

&AtClient
Procedure EndAndClose(Command)
	
	If StoredParameters.ExtendedPick Then
		UserArray = ChoiceResult();
		NotifyChoice(UserArray);
		SelectedUsersLastModified = False;
		Close(UserArray);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChooseUserCommand(Command)
	
	UserArray = Items.UsersList.SelectedRows;
	GetPicturesAndFillSelectedItemsList(UserArray);
	
EndProcedure

&AtClient
Procedure CancelUserOrGroupSelection(Command)
	
	DeleteFromSelectedItems();
	
EndProcedure

&AtClient
Procedure ClearSelectedUsersAndGroupsList(Command)
	
	DeleteFromSelectedItems(True);
	
EndProcedure

&AtClient
Procedure ChooseGroup(Command)
	
	GroupArray = Items.UserGroups.SelectedRows;
	GetPicturesAndFillSelectedItemsList(GroupArray);
	
EndProcedure

&AtClient
Procedure UserInfo(Command)
	
	OpenForm(
		"Report.UserInfo.ObjectForm",
		New Structure("VariantKey", "UserInfo"),
		ThisObject,
		"UserInfo");
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure FillSavedParameters()
	
	StoredParameters = New Structure;
	StoredParameters.Insert("UserGroupSelection", Parameters.UserGroupSelection);
	
EndProcedure

&AtServer
Procedure ApplyConditionalAppearanceAndHideNonValidUsers()
	
	// Conditional appearance.
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value = Metadata.StyleItems.InaccessibleDataColor.Value;
	AppearanceColorItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("UsersList.NotValid");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = True;
	DataFilterItem.Use  = True;
	
	FieldAppearanceItem = ConditionalAppearanceItem.Fields.Items.Add();
	FieldAppearanceItem.Field = New DataCompositionField("UsersList");
	FieldAppearanceItem.Use = True;
	
	// Hiding users.
	CommonUseClientServer.SetDynamicListFilterItem(
		UsersList, "NotValid", False, , , True);
	
EndProcedure

&AtServer
Procedure SetUpAllUsersGroupOrder(List)
	
	Var Order;
	
	// Order.
	Order = List.SettingsComposer.Settings.Order;
	Order.UserSettingID = "DefaultOrder";
	
	Order.Items.Clear();
	
	OrderItem = Order.Items.Add(Type("DataCompositionOrderItem"));
	OrderItem.Field = New DataCompositionField("Predefined");
	OrderItem.OrderType = DataCompositionSortDirection.Desc;
	OrderItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	OrderItem.Use = True;
	
	OrderItem = Order.Items.Add(Type("DataCompositionOrderItem"));
	OrderItem.Field = New DataCompositionField("Description");
	OrderItem.OrderType = DataCompositionSortDirection.Asc;
	OrderItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	OrderItem.Use = True;
	
EndProcedure

&AtClient
Procedure CurrentFormItemChangeCheck()
	
	If CurrentItem.Name <> CurrentItemName Then
		CurrentFromElementOnChange();
		CurrentItemName = CurrentItem.Name;
	EndIf;
	
#If WebClient Then
	AttachIdleHandler("CurrentFormItemChangeCheck", 0.7, True);
#Else
	AttachIdleHandler("CurrentFormItemChangeCheck", 0.1, True);
#EndIf
	
EndProcedure

&AtClient
Procedure CurrentFromElementOnChange()
	
	If CurrentItem.Name = "UserGroups" Then
		Items.Comments.CurrentPage = Items.GroupComment;
		
	ElsIf CurrentItem.Name = "UsersList" Then
		Items.Comments.CurrentPage = Items.UserComment;
		
	EndIf
	
EndProcedure

&AtServer
Procedure DeleteFromSelectedItems(DeleteAll = False)
	
	If DeleteAll Then
		SelectedUsersAndGroups.Clear();
		RefreshSelectedUsersAndGroupsListTitle();
		Return;
	EndIf;
	
	ListItemsArray = Items.SelectedUsersAndGroupsList.SelectedRows;
	For Each ListItem In ListItemsArray Do
		SelectedUsersAndGroups.Delete(SelectedUsersAndGroups.FindByID(ListItem));
	EndDo;
	
	RefreshSelectedUsersAndGroupsListTitle();
	
EndProcedure

&AtClient
Procedure GetPicturesAndFillSelectedItemsList(SelectedElementsArray)
	
	SelectedItemsAndPictures = New Array;
	For Each SelectedItem In SelectedElementsArray Do
		
		If TypeOf(SelectedItem) = Type("CatalogRef.Users") Then
			PictureNumber = Items.UsersList.RowData(SelectedItem).PictureNumber;
		Else
			PictureNumber = Items.UserGroups.RowData(SelectedItem).PictureNumber;
		EndIf;
		
		SelectedItemsAndPictures.Add(
			New Structure("SelectedItem, PictureNumber", SelectedItem, PictureNumber));
	EndDo;
	
	FillSelectedUsersAndGroupsList(SelectedItemsAndPictures);
	
EndProcedure

&AtServer
Function ChoiceResult()
	
	SelectedUsersValueTable = SelectedUsersAndGroups.Unload( , "User");
	UserArray = SelectedUsersValueTable.UnloadColumn("User");
	Return UserArray;
	
EndFunction

&AtServer
Procedure ChangeExtendedPickFormParameters()
	
	// Loading the list of selected users
	If ValueIsFilled(Parameters.ExtendedPickFormParameters) Then
		ExtendedPickFormParameters = GetFromTempStorage(Parameters.ExtendedPickFormParameters);
	Else
		ExtendedPickFormParameters = Parameters;
	EndIf;
	If TypeOf(ExtendedPickFormParameters.SelectedUsers) = Type("ValueTable") Then
		SelectedUsersAndGroups.Load(ExtendedPickFormParameters.SelectedUsers);
	Else
		For Each SelectedUser In ExtendedPickFormParameters.SelectedUsers Do
			SelectedUsersAndGroups.Add().User = SelectedUser;
		EndDo;
	EndIf;
	Users.FillUserPictureNumbers(SelectedUsersAndGroups, "User", "PictureNumber");
	StoredParameters.Insert("PickFormTitle", ExtendedPickFormParameters.PickFormTitle);
	// Setting parameters of the extended form for picking users.
	Items.EndAndClose.Visible                  = True;
	Items.ChooseUserGroup.Visible              = True;
	// Setting visibility for the list of selected users.
	Items.SelectedUsersAndGroups.Visible       = True;
	If GetFunctionalOption("UseUserGroups") Then
		Items.GroupsAndUsers.Group	 			= ChildFormItemsGroup.Vertical;
		Items.GroupsAndUsers.ChildItemsWidth	= ChildFormItemsWidth.Equal;
		Items.UsersList.Height					= 5;
		Items.UserGroups.Height					= 3;
		ThisObject.Height						= 17;
		Items.ChooseGroupGroup.Visible			= True;
		// Enabling visibility for UsersList and UserGroups list titles.
		Items.UserGroups.TitleLocation          = FormItemTitleLocation.Top;
		Items.UsersList.TitleLocation           = FormItemTitleLocation.Top;
		Items.UsersList.Title                   = NStr("en = 'Users in the group'");
		If ExtendedPickFormParameters.Property("ImpossibleToPickGroup") Then
			Items.ChooseGroup.Visible			= False;
		EndIf;
	Else
		Items.CancelUserSelection.Visible		= True;
		Items.ClearSelectedItemsList.Visible	= True;
	EndIf;
	
	// Adding the number of selected users to UsersList and UserGroups list titles.
	RefreshSelectedUsersAndGroupsListTitle();
	
EndProcedure

&AtServer
Procedure RefreshSelectedUsersAndGroupsListTitle()
	
	If StoredParameters.UseGroups Then
		SelectedUsersAndGroupsTitle = NStr("en = 'Selected users and groups (%1)'");
	Else
		SelectedUsersAndGroupsTitle = NStr("en = 'Selected users (%1)'");
	EndIf;
	
	UserCount = SelectedUsersAndGroups.Count();
	If UserCount <> 0 Then
		Items.SelectedUsersAndGroupsList.Title = StringFunctionsClientServer.SubstituteParametersInString(
			SelectedUsersAndGroupsTitle, UserCount);
	Else
		
		If StoredParameters.UseGroups Then
			Items.SelectedUsersAndGroupsList.Title = NStr("en = 'Selected users and groups'");
		Else
			Items.SelectedUsersAndGroupsList.Title = NStr("en = 'Selected users'");
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillSelectedUsersAndGroupsList(SelectedItemsAndPictures)
	
	For Each ArrayRow In SelectedItemsAndPictures Do
		
		SelectedUserOrGroup = ArrayRow.SelectedItem;
		PictureNumber = ArrayRow.PictureNumber;
		
		FilterParameters = New Structure("User", SelectedUserOrGroup);
		Found = SelectedUsersAndGroups.FindRows(FilterParameters);
		If Found.Count() = 0 Then
			
			SelectedUsersRow = SelectedUsersAndGroups.Add();
			SelectedUsersRow.User = SelectedUserOrGroup;
			SelectedUsersRow.PictureNumber = PictureNumber;
			SelectedUsersLastModified = True;
			
		EndIf;
		
	EndDo;
	
	SelectedUsersAndGroups.Sort("User Asc");
	RefreshSelectedUsersAndGroupsListTitle();
	
EndProcedure

&AtClient
Procedure UserGroupsUseOnChange()
	
	ConfigureUserGroupsUseForm();
	
EndProcedure

&AtServer
Procedure ConfigureUserGroupsUseForm()
	
	If StoredParameters.Property("CurrentRow") Then
		
		If TypeOf(StoredParameters.CurrentRow) = Type("CatalogRef.UserGroups") Then
			
			If StoredParameters.UseGroups Then
				Items.UserGroups.CurrentRow = StoredParameters.CurrentRow;
			Else
				Parameters.CurrentRow = Undefined;
			EndIf;
		Else
			CurrentItem = Items.UsersList;
			Items.UserGroups.CurrentRow = Catalogs.UserGroups.AllUsers;
		EndIf;
	Else
		If Not StoredParameters.UseGroups
		   And Items.UserGroups.CurrentRow
		     <> Catalogs.UserGroups.AllUsers Then
			
			Items.UserGroups.CurrentRow = Catalogs.UserGroups.AllUsers;
		EndIf;
	EndIf;
	
	Items.ShowNestedGroupUsersGroup.Visible = StoredParameters.UseGroups;
	
	If StoredParameters.ExtendedPick Then
		Items.AssignGroups.Visible = False;
	Else
		Items.AssignGroups.Visible = StoredParameters.UseGroups;
	EndIf;
	
	Items.CreateUserGroup.Visible =
		AccessRight("Insert", Metadata.Catalogs.UserGroups)
		And StoredParameters.UseGroups;
	
	UserGroupSelection = StoredParameters.UserGroupSelection
	                        And StoredParameters.UseGroups
	                        And Parameters.ChoiceMode;
	
	If Parameters.ChoiceMode Then
		
		Items.ChooseGroupUsers.Visible = 
			?(StoredParameters.ExtendedPick, False, UserGroupSelection);
		Items.ChooseUser.DefaultButton =
			?(StoredParameters.ExtendedPick, False, Not UserGroupSelection);
		Items.ChooseUser.Visible       = Not StoredParameters.ExtendedPick;
		AutoTitle = False;
		
		If Parameters.CloseOnChoice = False Then
			// Picking mode
			
			If UserGroupSelection Then
				
				If StoredParameters.ExtendedPick Then
					Title = StoredParameters.PickFormTitle;
				Else
					Title = NStr("en = 'Pick users and groups'");
				EndIf;
				
				Items.ChooseUser.Title =
					NStr("en = 'Select users'");
				
				Items.ChooseGroupUsers.Title =
					NStr("en = 'Select groups'");
			Else
				
				If StoredParameters.ExtendedPick Then
					Title = StoredParameters.PickFormTitle;
				Else
					Title = NStr("en = 'Pick users'");
				EndIf;
				
			EndIf;
		Else
			// Selection mode.
			If UserGroupSelection Then
				
				Title = NStr("en = 'Select user or group'");
				
				Items.ChooseUser.Title = NStr("en = 'Select user'");
			Else
				Title = NStr("en = 'Select user'");
			EndIf;
		EndIf;
	EndIf;
	
	RefreshFormContentOnGroupChange(ThisObject);
	
EndProcedure

&AtClient
Procedure UserGroupsAfterActivateRow()
	
	RefreshFormContentOnGroupChange(ThisObject);
	
EndProcedure

&AtServer
Function MoveUserToNewGroup(UserArray, NewOwnerGroup, Move)
	
	If NewOwnerGroup = Undefined Then
		Return Undefined;
	EndIf;
	
	CurrentOwnerGroup = Items.UserGroups.CurrentRow;
	UserMessage = UsersInternal.MoveUserToNewGroup(
		UserArray, CurrentOwnerGroup, NewOwnerGroup, Move);
	
	Items.UsersList.Refresh();
	Items.UserGroups.Refresh();
	
	Return UserMessage;
	
EndFunction

&AtClient
Procedure UserGroupsDragAndDropCompletion(Answer, AdditionalParameters) Export
	
	If Answer = DialogReturnCode.No Then
		Cancel = True;
		Return;
	EndIf;
	
	UserMessage = MoveUserToNewGroup(
		AdditionalParameters.DragParameters,
		AdditionalParameters.Row,
		AdditionalParameters.Move);
	
	If UserMessage.Message = Undefined Then
		Return;
	EndIf;
	
	If UserMessage.HasErrors = False Then
		ShowUserNotification(
			NStr("en = 'Moving users'"), , UserMessage.Message, PictureLib.Information32);
	Else
		ShowMessageBox(,UserMessage.Message);
	EndIf;
	
	Notify("Write_ExternalUserGroups");
	
EndProcedure

&AtClient
Procedure SwitchNonValidUsersVisibility(ShowNotValid)
	
	Items.ShowNotValidUsers.Check = ShowNotValid;
	
	CommonUseClientServer.SetDynamicListFilterItem(
		UsersList, "NotValid", False, , ,
		Not ShowNotValid);
	
EndProcedure

&AtClientAtServerNoContext
Procedure RefreshFormContentOnGroupChange(Form)
	
	Items = Form.Items;
	
	If Not Form.StoredParameters.UseGroups
	 Or Items.UserGroups.CurrentRow = PredefinedValue(
	         "Catalog.UserGroups.AllUsers") Then
		
		UpdateDataCompositionParameterValue(
			Form.UsersList, "SelectHierarchy", True);
		
		UpdateDataCompositionParameterValue(
			Form.UsersList, "UserGroup", PredefinedValue(
				"Catalog.UserGroups.AllUsers"));
	Else
		
		UpdateDataCompositionParameterValue(
			Form.UsersList, "SelectHierarchy", Form.SelectHierarchy);
		
		UpdateDataCompositionParameterValue(
			Form.UsersList,
			"UserGroup",
			Items.UserGroups.CurrentRow);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateDataCompositionParameterValue(Val ParameterOwner,
                                                    Val ParameterName,
                                                    Val ParameterValue)
 
	For Each Parameter In ParameterOwner.Parameters.Items Do
		If String(Parameter.Parameter) = ParameterName Then
 
			If Parameter.Use
			   And Parameter.Value = ParameterValue Then
				Return;
			EndIf;
			Break;
 
		EndIf;
	EndDo;
 
	ParameterOwner.Parameters.SetParameterValue(ParameterName, ParameterValue);

EndProcedure

#EndRegion 