////////////////////////////////////////////////////////////////////////////////
//                          FORM OPERATIONS                                   //
//
// Additional parameters for opening the form that is used for picking users:
//
// ExtendedPick               - Boolean - if True, open the extended form for picking users. 
//                              The extended form requires the ExtendedPickFormParameters parameter.
// ExtendedPickFormParameters - String - reference to a structure that contains extended parameters 
//                              for the form used for picking users. The structure is
//                              located in a temporary storage.
//  Structure parameters:
//    PickFormTitle - String - the form title.
//    SelectedUsers - Array - array of users selected before opening the form.
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	// Skipping the initialization to guarantee that the form will be received if the Autotest parameter is passed
	If Parameters.Property("Autotest") Then 
		Return;
	EndIf;
	
	// Setting initial value before it is loaded from the settings
	SelectHierarchy = True;
	
	FillSavedParameters();
	FillDynamicListParameters();
	
	If Parameters.ChoiceMode Then
		PurposeUseKey = "SelectionPick";
		WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
	EndIf;
	
	// Hiding users with blank IDs if the parameter value is True
	If Parameters.HideUsersWithNoMatchingInfobaseUser Then
		CommonUseClientServer.SetDynamicListFilterItem(
			ExternalUsersList,
			"InfobaseUserID",
			New UUID("00000000-0000-0000-0000-000000000000"),
			DataCompositionComparisonType.NotEqual);
	EndIf;
	
	// Hiding users passed to the form
	If TypeOf(Parameters.UsersToHide) = Type("ValueList") Then
		
		DCComparisonType = DataCompositionComparisonType.NotInList;
		CommonUseClientServer.SetDynamicListFilterItem(
			ExternalUsersList,
			"Ref",
			Parameters.UsersToHide,
			DCComparisonType);
	EndIf;
	
	SetUpAllExternalUsersGroupOrder(ExternalUserGroups);
	ApplyConditionalAppearanceAndHideNonValidExternalUsers();
	
	StoredParameters.Insert("ExtendedPick", Parameters.ExtendedPick);
	Items.SelectedUsersAndGroups.Visible = StoredParameters.ExtendedPick;
	StoredParameters.Insert(
		"UseGroups", GetFunctionalOption("UseUserGroups"));
	
	If Not AccessRight("Insert", Metadata.Catalogs.ExternalUsers) Then
		Items.CreateExternalUser.Visible = False;
	EndIf;
	
	If Not Users.InfobaseUserWithFullAccess(, CommonUseCached.ApplicationRunMode().Local) Then
		If Items.Find("InfobaseUsers") <> Undefined Then
			Items.InfobaseUsers.Visible = False;
		EndIf;
		Items.ExternalUserInfo.Visible = False;
	EndIf;
	
	If Parameters.ChoiceMode Then
		
		If Items.Find("InfobaseUsers") <> Undefined Then
			Items.InfobaseUsers.Visible = False;
		EndIf;
		Items.ExternalUserInfo.Visible = False;
		
		// Applying a filter that excludes items marked for deletion
		CommonUseClientServer.SetDynamicListFilterItem(
			ExternalUsersList, "DeletionMark", False, , , True,
			DataCompositionSettingsItemViewMode.Normal);
		
		Items.ExternalUsersList.ChoiceMode = True;
		Items.ExternalUserGroups.ChoiceMode =
			StoredParameters.ExternalUserGroupSelection;
		
		// Disabling drag-and-drop operations in user selection forms and in forms used for picking users
		Items.ExternalUsersList.EnableStartDrag = False;
		
		If Parameters.Property("NonExistentInfobaseUserIDs") Then
			CommonUseClientServer.SetDynamicListFilterItem(
				ExternalUsersList, "InfobaseUserID",
				Parameters.NonExistentInfobaseUserIDs,
				DataCompositionComparisonType.InList, , True,
				DataCompositionSettingsItemViewMode.Inaccessible);
		EndIf;
		
		If Parameters.CloseOnChoice = False Then
			// Picking mode
			Items.ExternalUsersList.MultipleChoice = True;
			
			If StoredParameters.ExtendedPick Then
				ThisObject.WindowOptionsKey = "ExternalUsersExtendedPick";
				ChangeExtendedPickFormParameters();
			Else
				ThisObject.WindowOptionsKey = "ExternalUserPickMode";
			EndIf;
			
			If StoredParameters.ExternalUserGroupSelection Then
				Items.ExternalUserGroups.MultipleChoice = True;
			EndIf;
		EndIf;
	Else
		Items.Comments.Visible = False;
		Items.ChooseExternalUser.Visible = False;
		Items.ChooseExternalUserGroup.Visible = False;
	EndIf;
	
	StoredParameters.Insert("AllUsersGroup", Catalogs.ExternalUserGroups.AllExternalUsers);
	StoredParameters.Insert("CurrentRow", Parameters.CurrentRow);
	ConfigureUserGroupsUseForm();
	StoredParameters.Delete("CurrentRow");
	
	CommonUseClientServer.MoveFiltersToDynamicList(ThisObject, ExternalUsersList);
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Parameters.ChoiceMode Then
		CurrentFormItemChangeCheck();
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Upper(EventName) = Upper("Write_ExternalUserGroups")
	   And Source = Items.ExternalUserGroups.CurrentRow Then
		
		Items.ExternalUserGroups.Refresh();
		Items.ExternalUsersList.Refresh();
		RefreshFormContentOnGroupChange(ThisObject);
		
	ElsIf Upper(EventName) = Upper("Write_ConstantsSet") Then
		
		If Upper(Source) = Upper("UseUserGroups") Then
			AttachIdleHandler("UserGroupsUseOnChange", 0.1, True);
		EndIf;
		
	ElsIf Upper(EventName) = Upper("ArrangeUsersInGroups") Then
		
		Items.ExternalUsersList.Refresh();
		
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

#Region ExternalUserGroupsFormTableItemsEventHandlers

&AtClient
Procedure ExternalUserGroupsOnActivateRow(Item)
	
	RefreshFormContentOnGroupChange(ThisObject);
	
EndProcedure

&AtClient
Procedure ExternalUserGroupsValueChoice(Item, Value, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not StoredParameters.ExtendedPick Then
		NotifyChoice(Value);
	Else
		
		GetPicturesAndFillSelectedItemsList(Value);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExternalUserGroupsBeforeAddRow(Item, Cancel, Clone, Parent, Group)
	
	If Not Clone Then
		Cancel = True;
		FormParameters = New Structure;
		
		If ValueIsFilled(Items.ExternalUserGroups.CurrentRow) Then
			
			FormParameters.Insert(
				"FillingValues",
				New Structure("Parent", Items.ExternalUserGroups.CurrentRow));
		EndIf;
		
		OpenForm(
			"Catalog.ExternalUserGroups.ObjectForm",
			FormParameters,
			Items.ExternalUserGroups);
	EndIf;
	
EndProcedure

&AtClient
Procedure ExternalUserGroupsDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure ExternalUserGroupsDrag(Item, DragParameters, StandardProcessing, Row, Field)
	
	StandardProcessing = False;
	
	If SelectHierarchy Then
		ShowMessageBox(,NStr("en = To be able to drag users to groups, clear the ""Show nested group users"" check box.'"));
		Return;
	EndIf;
	
	If Items.ExternalUserGroups.CurrentRow = Row
		Or Row = Undefined Then
		Return;
	EndIf;
	
	If DragParameters.Action = DragAction.Move Then
		Move = True;
	Else
		Move = False;
	EndIf;
	
	GroupCurrentRow = Items.ExternalUserGroups.CurrentRow;
	GroupWithAllAuthorizationObjectsType = 
		Items.ExternalUserGroups.RowData(GroupCurrentRow).AllAuthorizationObjects;
	
	If Row = StoredParameters.AllUsersGroup
		And GroupWithAllAuthorizationObjectsType Then
		UserMessage = New Structure("Message, HasErrors, Users",
			NStr("en = 'You cannot remove users from groups of the ""All users with specified type"" type.'"),
			True,
			Undefined);
	Else
		GroupMarkedForDeletion = Items.ExternalUserGroups.RowData(Row).DeletionMark;
		
		UserCount = DragParameters.Value.Count();
		
		ActionExcludeUser = (StoredParameters.AllUsersGroup = Row);
		
		ActionsWithUser = 
			?((StoredParameters.AllUsersGroup = GroupCurrentRow) OR GroupWithAllAuthorizationObjectsType,
			NStr("en = 'add'"),
			?(Move, NStr("en = 'move'"), NStr("en = 'copy'")));
		
		If GroupMarkedForDeletion Then
			ActionTemplate = ?(Move, NStr("en = 'Group ""%1"" is marked for deletion. %2'"), 
				NStr("en = 'Group ""%1"" is marked for deletion. %2'"));
			ActionsWithUser = StringFunctionsClientServer.SubstituteParametersInString(
				ActionTemplate, String(Row), ActionsWithUser);
		EndIf;
		
		If UserCount = 1 Then
			
			If ActionExcludeUser Then
				QuestionTemplate = NStr("en = 'Do you want to remove user %2 from group %4?'");
			ElsIf Not GroupMarkedForDeletion Then
				QuestionTemplate = NStr("en = 'Do you want to %1 user ""%2"" to group ""%3""?'");
			Else
				QuestionTemplate = NStr("en = 'Do you want to %1 user ""%2"" to the group?'");
			EndIf;
			QuestionText = StringFunctionsClientServer.SubstituteParametersInString(
				QuestionTemplate, ActionsWithUser, String(DragParameters.Value[0]),
				String(Row), String(Items.ExternalUserGroups.CurrentRow));
			
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
				String(Row), String(Items.ExternalUserGroups.CurrentRow));
			
		EndIf;
		
		AdditionalParameters = New Structure("DragParameters, Row, Move",
			DragParameters.Value, Row, Move);
		Notification = New NotifyDescription("ExternalUserGroupsDragQuestionProcessing", ThisObject, AdditionalParameters);
		ShowQueryBox(Notification, QuestionText, QuestionDialogMode.YesNo, 60, DialogReturnCode.Yes);
		Return;
		
	EndIf;
	
	ExternalUserGroupsDragCompletion(UserMessage);
	
EndProcedure

#EndRegion

#Region ExternalUsersFormTableItemsEventHandlers

&AtClient
Procedure ExternalUsersListValueChoice(Item, Value, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not StoredParameters.ExtendedPick Then
		NotifyChoice(Value);
	Else
		GetPicturesAndFillSelectedItemsList(Value);
	EndIf;
	
EndProcedure

&AtClient
Procedure ExternalUsersListBeforeAddRow(Item, Cancel, Clone, Parent, Group)
	
	Cancel = True;
	
	FormParameters = New Structure(
		"NewExternalUserGroup", Items.ExternalUserGroups.CurrentRow);
	
	If ValueIsFilled(StoredParameters.AuthorizationObjectFilter) Then
		
		FormParameters.Insert(
			"NewExternalUserAuthorizationObject",
			StoredParameters.AuthorizationObjectFilter);
	EndIf;
	
	If Clone And Item.CurrentData <> Undefined Then
		FormParameters.Insert("CopyingValue", Item.CurrentRow);
	EndIf;
	
	OpenForm(
		"Catalog.ExternalUsers.ObjectForm",
		FormParameters,
		Items.ExternalUsersList);
	
EndProcedure

&AtClient
Procedure ExternalUsersListDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	
	StandardProcessing = False;
	
EndProcedure

#EndRegion

#Region SelectedUsersAndGroupsListFormTableItemsEventHandlers

&AtClient
Procedure SelectedUsersAndGroupsListCase(Item, SelectedRow, Field, StandardProcessing)
	
	DeleteFromSelectedItems();
	ThisObject.Modified = True;
	
EndProcedure

&AtClient
Procedure SelectedUsersAndGroupsListBeforeAddRow(Item, Cancel, Clone, Parent, Group, Parameter)
	Cancel = True;
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure CreateExternalUserGroup(Command)
	
	Items.ExternalUserGroups.AddRow();
	
EndProcedure

&AtClient
Procedure ShowNotValidUsers(Command)
	ShowNotValidUsers = Not Items.ShowNotValidUsers.Check;
	SwitchNonValidUsersVisibility(ShowNotValidUsers);
EndProcedure

&AtClient
Procedure AssignGroups(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("Users", Items.ExternalUsersList.SelectedRows);
	FormParameters.Insert("ExternalUsers", True);
	
	OpenForm("CommonForm.UserGroups", FormParameters);
	
EndProcedure

&AtClient
Procedure EndAndClose(Command)
	
	If StoredParameters.ExtendedPick Then
		UserArray = ChoiceResult();
		NotifyChoice(UserArray);
		ThisObject.Modified = False;
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure ChooseUserCommand(Command)
	
	UserArray = Items.ExternalUsersList.SelectedRows;
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
	
	GroupArray = Items.ExternalUserGroups.SelectedRows;
	GetPicturesAndFillSelectedItemsList(GroupArray);
	
EndProcedure

&AtClient
Procedure ExternalUserInfo(Command)
	
	OpenForm(
		"Report.UserInfo.ObjectForm",
		New Structure("VariantKey", "ExternalUserInfo"),
		ThisObject,
		"ExternalUserInfo");
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure FillSavedParameters()
	
	StoredParameters = New Structure;
	StoredParameters.Insert("ExternalUserGroupSelection", Parameters.ExternalUserGroupSelection);
	
	If Parameters.Filter.Property("AuthorizationObject") Then
		StoredParameters.Insert("AuthorizationObjectFilter", Parameters.Filter.AuthorizationObject);
	Else
		StoredParameters.Insert("AuthorizationObjectFilter", Undefined);
	EndIf;
	
	// Preparing authorization object type presentations.
	StoredParameters.Insert("AuthorizationObjectTypePresentation", New ValueList);
	AuthorizationObjectTypes = Metadata.Catalogs.ExternalUsers.Attributes.AuthorizationObject.Type.Types();
	
	For Each CurrentAuthorizationObjectType In AuthorizationObjectTypes Do
		If Not CommonUse.IsReference(CurrentAuthorizationObjectType) Then
			Continue;
		EndIf;
		TypeArray = New Array;
		TypeArray.Add(CurrentAuthorizationObjectType);
		TypeDescription = New TypeDescription(TypeArray);
		
		StoredParameters.AuthorizationObjectTypePresentation.Add(
			TypeDescription.AdjustValue(Undefined),
			Metadata.FindByType(CurrentAuthorizationObjectType).Synonym);
	EndDo;
	
EndProcedure

&AtServer
Procedure FillDynamicListParameters()
	
	AuthorizationObjectType = Undefined;
	Parameters.Property("AuthorizationObjectType", AuthorizationObjectType);
	
	UpdateDataCompositionParameterValue(
		ExternalUserGroups,
		"AnyAuthorizationObjectType",
		AuthorizationObjectType = Undefined);
	
	UpdateDataCompositionParameterValue(
		ExternalUserGroups,
		"AuthorizationObjectType",
		TypeOf(AuthorizationObjectType));
	
	UpdateDataCompositionParameterValue(
		ExternalUsersList,
		"AnyAuthorizationObjectType",
		AuthorizationObjectType = Undefined);
	
	UpdateDataCompositionParameterValue(
		ExternalUsersList,
		"AuthorizationObjectType",
		TypeOf(AuthorizationObjectType));
	
EndProcedure

&AtServer
Procedure SetUpAllExternalUsersGroupOrder(List)
	
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

&AtServer
Procedure ApplyConditionalAppearanceAndHideNonValidExternalUsers()
	
	// Conditional appearance.
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value = Metadata.StyleItems.InaccessibleDataColor.Value;
	AppearanceColorItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("ExternalUsersList.NotValid");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = True;
	DataFilterItem.Use  = True;
	
	FieldAppearanceItem = ConditionalAppearanceItem.Fields.Items.Add();
	FieldAppearanceItem.Field = New DataCompositionField("ExternalUsersList");
	FieldAppearanceItem.Use = True;
	
	// Hiding users.
	CommonUseClientServer.SetDynamicListFilterItem(
		ExternalUsersList, "NotValid", False, , , True);
	
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
	
	If CurrentItem.Name = "ExternalUserGroups" Then
		Items.Comments.CurrentPage = Items.GroupComment;
		
	ElsIf CurrentItem.Name = "ExternalUsersList" Then
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
Procedure GetPicturesAndFillSelectedItemsList(SelectedItemsArray)
	
	SelectedItemsAndPictures = New Array;
	For Each SelectedItem In SelectedItemsArray Do
		
		If TypeOf(SelectedItem) = Type("CatalogRef.ExternalUsers") Then
			PictureNumber = Items.ExternalUsersList.RowData(SelectedItem).PictureNumber;
		Else
			PictureNumber = Items.ExternalUserGroups.RowData(SelectedItem).PictureNumber;
		EndIf;
		
		SelectedItemsAndPictures.Add(
			New Structure("SelectedItem, PictureNumber", SelectedItem, PictureNumber));
	EndDo;
	
	FillSelectedUsersAndGroupsList(SelectedItemsAndPictures);
	
EndProcedure

&AtServer
Function ChoiceResult()
	
	SelectedUsersValueTable = SelectedUsersAndGroups.Unload( ,"User");
	UserArray = SelectedUsersValueTable.UnloadColumn("User");
	Return UserArray;
	
EndFunction

&AtServer
Procedure ChangeExtendedPickFormParameters()
	
	// Loading the list of selected users
	ExtendedPickFormParameters = GetFromTempStorage(Parameters.ExtendedPickFormParameters);
	SelectedUsersAndGroups.Load(ExtendedPickFormParameters.SelectedUsers);
	StoredParameters.Insert("PickFormTitle", ExtendedPickFormParameters.PickFormTitle);
	Users.FillUserPictureNumbers(SelectedUsersAndGroups, "User", "PictureNumber");
	// Setting parameters of the extended form for picking users.
	Items.EndAndClose.Visible            = True;
	Items.ChooseUserGroup.Visible        = True;
	// Setting visibility for the list of selected users.
	Items.SelectedUsersAndGroups.Visible = True;
	If GetFunctionalOption("UseUserGroups") Then
		Items.GroupsAndUsers.Group				= ChildFormItemsGroup.Vertical;
		Items.GroupsAndUsers.ChildItemsWidth	= ChildFormItemsWidth.Equal;
		Items.ExternalUsersList.Height			= 5;
		Items.ExternalUserGroups.Height			= 3;
		ThisObject.Height						= 17;
		Items.ChooseGroupGroup.Visible			= True;
		// Enabling visibility for UsersList and UserGroups list titles.
		Items.ExternalUserGroups.TitleLocation	= FormItemTitleLocation.Top;
		Items.ExternalUsersList.TitleLocation	= FormItemTitleLocation.Top;
		Items.ExternalUsersList.Title			= NStr("en = 'Users in the group'");
		If ExtendedPickFormParameters.Property("ImpossibleToPickGroup") Then
			Items.ChooseGroup.Visible			= False;
		EndIf;
	Else
		Items.CancelUserSelection.Visible   = True;
		Items.ClearSelectedItemList.Visible = True;
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
			ThisObject.Modified = True;
			
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
		
		If TypeOf(Parameters.CurrentRow) = Type("CatalogRef.ExternalUserGroups") Then
			
			If StoredParameters.UseGroups Then
				Items.ExternalUserGroups.CurrentRow = StoredParameters.CurrentRow;
			Else
				Parameters.CurrentRow = Undefined;
			EndIf;
		Else
			CurrentItem = Items.ExternalUsersList;
			
			Items.ExternalUserGroups.CurrentRow =
				Catalogs.ExternalUserGroups.AllExternalUsers;
		EndIf;
	Else
		If Not StoredParameters.UseGroups
		   And Items.ExternalUserGroups.CurrentRow
		     <> Catalogs.UserGroups.AllUsers Then
			
			Items.ExternalUserGroups.CurrentRow =
				Catalogs.UserGroups.AllUsers;
		EndIf;
	EndIf;
	
	Items.ShowChildGroupExternalUsersGroup.Visible =
		StoredParameters.UseGroups;
	
	If StoredParameters.ExtendedPick Then
		Items.AssignGroups.Visible = False;
	Else
		Items.AssignGroups.Visible = StoredParameters.UseGroups;
	EndIf;
	
	Items.CreateExternalUserGroup.Visible =
		AccessRight("Insert", Metadata.Catalogs.ExternalUserGroups)
		And StoredParameters.UseGroups;
	
	ExternalUserGroupSelection = StoredParameters.ExternalUserGroupSelection
	                               And StoredParameters.UseGroups
	                               And Parameters.ChoiceMode;
	
	If Parameters.ChoiceMode Then
		
		Items.ChooseExternalUserGroup.Visible = 
			?(StoredParameters.ExtendedPick, False, ExternalUserGroupSelection);
		Items.ChooseExternalUser.DefaultButton   =
			?(StoredParameters.ExtendedPick, False, Not ExternalUserGroupSelection);
		Items.ChooseExternalUser.Visible      = Not StoredParameters.ExtendedPick;
		
		AutoTitle = False;
		
		If Parameters.CloseOnChoice = False Then
			// Picking mode
			
			If ExternalUserGroupSelection Then
				
				If StoredParameters.ExtendedPick Then
					Title = StoredParameters.PickFormTitle;
				Else
					Title = NStr("en = 'Pick external users and groups'");
				EndIf;
				
				Items.ChooseExternalUser.Title =
					NStr("en = 'Select external users'");
				
				Items.ChooseExternalUserGroup.Title =
					NStr("en = 'Select groups'");
				
			Else
				If StoredParameters.ExtendedPick Then
					Title = StoredParameters.PickFormTitle;
				Else
					Title = NStr("en = 'Pick external users'");
				EndIf;
			EndIf;
		Else
			// Selection mode.
			If ExternalUserGroupSelection Then
				Title = NStr("en = 'Select external user or group'");
				
				Items.ChooseExternalUser.Title = NStr("en = 'Select external user'");
			Else
				Title = NStr("en = 'Select external user'");
			EndIf;
		EndIf;
	EndIf;
	
	RefreshFormContentOnGroupChange(ThisObject);
	
EndProcedure

&AtServer
Function MoveUserToNewGroup(UserArray, NewOwnerGroup, Move)
	
	If NewOwnerGroup = Undefined Then
		Return Undefined;
	EndIf;
	
	CurrentOwnerGroup = Items.ExternalUserGroups.CurrentRow;
	UserMessage = UsersInternal.MoveUserToNewGroup(
		UserArray, CurrentOwnerGroup, NewOwnerGroup, Move);
	
	Items.ExternalUsersList.Refresh();
	Items.ExternalUserGroups.Refresh();
	
	Return UserMessage;
	
EndFunction

&AtClient
Procedure SwitchNonValidUsersVisibility(ShowNotValid)
	
	Items.ShowNotValidUsers.Check = ShowNotValid;
	
	CommonUseClientServer.SetDynamicListFilterItem(
		ExternalUsersList, "NotValid", False, , ,
		NOT ShowNotValid);
	
EndProcedure

&AtClientAtServerNoContext
Procedure RefreshFormContentOnGroupChange(Form)
	
	Items = Form.Items;
	
	If Not Form.StoredParameters.UseGroups
	 Or Items.ExternalUserGroups.CurrentRow = PredefinedValue(
	         "Catalog.ExternalUserGroups.AllExternalUsers") Then
		
		UpdateDataCompositionParameterValue(
			Form.ExternalUsersList, "SelectHierarchy", True);
		
		UpdateDataCompositionParameterValue(
			Form.ExternalUsersList,
			"ExternalUserGroup",
			PredefinedValue("Catalog.ExternalUserGroups.AllExternalUsers"));
	Else
	#If Server Then
		If ValueIsFilled(Items.ExternalUserGroups.CurrentRow) Then
			CurrentData = CommonUse.ObjectAttributeValues(
				Items.ExternalUserGroups.CurrentRow, "AllAuthorizationObjects");
		Else
			CurrentData = Undefined;
		EndIf;
	#Else
		CurrentData = Items.ExternalUserGroups.CurrentData;
	#EndIf
		
		If CurrentData <> Undefined
		   And CurrentData.AllAuthorizationObjects Then
			
			AuthorizationObjectTypePresentationItem =
				Form.StoredParameters.AuthorizationObjectTypePresentation.FindByValue(
					CurrentData.AuthorizationObjectType);
				
			UpdateDataCompositionParameterValue(
				Form.ExternalUsersList, "SelectHierarchy", True);
		Else
			UpdateDataCompositionParameterValue(
				Form.ExternalUsersList, "SelectHierarchy", Form.SelectHierarchy);
		EndIf;
		
		UpdateDataCompositionParameterValue(
			Form.ExternalUsersList,
			"ExternalUserGroup",
			Items.ExternalUserGroups.CurrentRow);
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

////////////////////////////////////////////////////////////////////////////////
// Dragging users

&AtClient
Procedure ExternalUserGroupsDragQuestionProcessing(Answer, AdditionalParameters) Export
	
	If Answer = DialogReturnCode.No Then
		Return;
	EndIf;
	
	UserMessage = MoveUserToNewGroup(
		AdditionalParameters.DragParameters, AdditionalParameters.Row, AdditionalParameters.Move);
	ExternalUserGroupsDragCompletion(UserMessage);
	
EndProcedure

&AtClient
Procedure ExternalUserGroupsDragCompletion(UserMessage)
	
	If UserMessage.Message = Undefined Then
		Return;
	EndIf;
	
	Notify("Write_ExternalUserGroups");
	
	If UserMessage.HasErrors = False Then
		ShowUserNotification(
			NStr("en = 'Moving users'"), , UserMessage.Message, PictureLib.Information32);
	Else
		
		If UserMessage.Users <> Undefined Then
			Report = NStr("en = 'The following users were not added to the selected group:'");
			Report = Report + Chars.LF + UserMessage.Users;
			
			QuestionText = UserMessage.Message;
			
			Result = StandardSubsystemsClientServer.NewExecutionResult();
			WarningOutput = Result.WarningOutput;
			WarningOutput.Use = True;
			WarningOutput.Text = QuestionText;
			WarningOutput.ErrorsText = Report;
			StandardSubsystemsClient.ShowExecutionResult(ThisObject, Result);
		Else
			ShowMessageBox(,UserMessage.Message);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion
