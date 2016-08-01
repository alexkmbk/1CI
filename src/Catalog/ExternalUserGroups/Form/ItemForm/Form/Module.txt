
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	// Skipping the initialization to guarantee that the form will be received if the Autotest parameter is passed.
	If Parameters.Property("Autotest") Then 
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		ProcessRolesInterface("FillRoles", Object.Roles);
		ProcessRolesInterface("SetUpRoleInterfaceOnFormCreate", False);
	EndIf;
	
	// Preparing auxiliary data.
	FillAuthorizationObjectTypeList();
	
	If Not ValueIsFilled(Object.Ref) Then
		
		If Object.Parent = Catalogs.ExternalUserGroups.AllExternalUsers
			Or CommonUse.ObjectAttributeValue(Object.Parent, "AllAuthorizationObjects") Then
			Object.Parent = Catalogs.ExternalUserGroups.EmptyRef();
		EndIf;
		
	EndIf;
	
	SelectAvailableGroupParticipantsTypes();
	
	SetActionsOnForm();
	
	// Making the properties always available.
	
	Items.Description.Visible        = ValueIsFilled(ActionsOnForm.ItemProperties);
	Items.Parent.Visible             = ValueIsFilled(ActionsOnForm.ItemProperties);
	Items.Comment.Visible            = ValueIsFilled(ActionsOnForm.ItemProperties);
	Items.Content.Visible            = ValueIsFilled(ActionsOnForm.GroupContent);
	Items.RoleRepresentation.Visible = ValueIsFilled(ActionsOnForm.Roles);
	
	If Object.AllAuthorizationObjects Then
		GroupMembers = "AllOfSingleType";
	ElsIf Object.AuthorizationObjectType <> Undefined Then
		GroupMembers = "SingleType";
	Else
		GroupMembers = "Any";
	EndIf;
	
	IsAllExternalUsersGroup = 
		Object.Ref = Catalogs.ExternalUserGroups.AllExternalUsers;
	
	If IsAllExternalUsersGroup Then
		Items.Description.ReadOnly        = True;
		Items.Parent.ReadOnly             = True;
		Items.Comment.ReadOnly            = True;
		Items.GroupExternalUsers.ReadOnly = True;
	EndIf;
	
	If ReadOnly
	 Or Not IsAllExternalUsersGroup
	     And ActionsOnForm.Roles          <> "Edit"
	     And ActionsOnForm.GroupContent   <> "Edit"
	     And ActionsOnForm.ItemProperties <> "Edit"
	 Or IsAllExternalUsersGroup
	   And UsersInternal.RoleEditProhibition() Then
		
		ReadOnly = True;
	EndIf;
	
	If ActionsOnForm.ItemProperties <> "Edit" Then
		Items.Description.ReadOnly = True;
		Items.Parent.ReadOnly      = True;
		Items.Comment.ReadOnly     = True;
	EndIf;
	
	If ActionsOnForm.GroupContent <> "Edit" Then
		Items.GroupExternalUsers.ReadOnly = True;
	EndIf;
	
	ProcessRolesInterface(
		"SetRolesReadOnly",
		    UsersInternal.RoleEditProhibition()
		Or ActionsOnForm.Roles <> "Edit");
	
	SetPropertyEnabled(ThisObject);
	
	FillUserStatus();
	RefreshNotValidUserList(True);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	ProcessRolesInterface("FillRoles", Object.Roles);
	ProcessRolesInterface("SetUpRoleInterfaceOnFormCreate", True);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Filling object roles from a collection.
	CurrentObject.Roles.Clear();
	For Each Row In RoleCollection Do
		CurrentObject.Roles.Add().Role = CommonUse.MetadataObjectID(
			"Role." + Row.Role);
	EndDo;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_ExternalUserGroups", New Structure, Object.Ref);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, AttributesToCheck)
	
	NoCheckAttributes = New Array;
	CheckedObjectAttributes = New Array;
	Errors = Undefined;
	
	// Checking whether roles are present in the metadata.
	CheckedObjectAttributes.Add("Roles.Role");
	
	TreeItems = Roles.GetItems();
	For Each Row In TreeItems Do
		If Row.Check And Left(Row.Synonym, 1) = "?" Then
			CommonUseClientServer.AddUserError(Errors,
				"Roles[%1].RolesSynonym",
				StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en = 'Role ""%1"" is not found in the metadata'"),
					Row.Synonym),
				"Roles",
				TreeItems.IndexOf(Row),
				StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en = 'Role ""%2"" in row #%1 is not found in the metadata'"),
					"%1", Row.Synonym));
		EndIf;
	EndDo;
	
	CommonUseClientServer.ShowErrorsToUser(Errors, Cancel);
	
	If GroupMembers = "Any" Then
		NoCheckAttributes.Add("AuthorizationObjectTypePresentation");
	EndIf;
	NoCheckAttributes.Add("Object");
	CommonUse.DeleteNoCheckAttributesFromArray(AttributesToCheck, NoCheckAttributes);
	
	CurrentObject = FormAttributeToValue("Object");
	
	CurrentObject.AdditionalProperties.Insert(
		"CheckedObjectAttributes", CheckedObjectAttributes);
	
	If Not CurrentObject.CheckFilling() Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	ProcessRolesInterface("SetUpRoleInterfaceOnLoadSettings", Settings);
	
EndProcedure

#EndRegion

#Region FormHeaderItemEventHandlers

&AtClient
Procedure ParticipantContentOnChange(Item)
	
	Object.AllAuthorizationObjects = (GroupMembers = "AllOfSingleType");
	If Object.AllAuthorizationObjects Then
		Object.Content.Clear();
	EndIf;
	
	If GroupMembers = "AllOfSingleType" Or GroupMembers = "SingleType" Then
		If Not ValueIsFilled(AuthorizationObjectTypePresentation) Then
			AuthorizationObjectTypePresentation = AuthorizationObjectTypes[0].Presentation;
			Object.AuthorizationObjectType = AuthorizationObjectTypes[0].Value;
		EndIf;
	Else
		AuthorizationObjectTypePresentation = "";
		Object.AuthorizationObjectType = Undefined;
	EndIf;
	
	SetPropertyEnabled(ThisObject);
	
EndProcedure

&AtClient
Procedure AuthorizationObjectTypePresentationOnChange(Item)
	
	If ValueIsFilled(AuthorizationObjectTypePresentation) Then
		DeleteNotTypicalExternalUsers();
	Else
		Object.AllAuthorizationObjects  = False;
		Object.AuthorizationObjectType = Undefined;
	EndIf;
	
	SetPropertyEnabled(ThisObject);
	
EndProcedure

&AtClient
Procedure AuthorizationObjectTypePresentationStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	ShowChooseFromList(
		New NotifyDescription("AuthorizationObjectTypePresentationEndChoice", ThisObject),
		AuthorizationObjectTypes,
		Item,
		AuthorizationObjectTypes.FindByValue(Object.AuthorizationObjectType));
	
EndProcedure

&AtClient
Procedure ParentOnChange(Item)
	
	Object.AllAuthorizationObjects = False;
	SelectAvailableGroupParticipantsTypes();
	
	SetPropertyEnabled(ThisObject);
	
EndProcedure

&AtClient
Procedure ParentStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	FormParameters = New Structure;
	FormParameters.Insert("ChoiceMode", True);
	FormParameters.Insert("ChooseParent");
	
	OpenForm("Catalog.ExternalUserGroups.ChoiceForm", FormParameters, Items.Parent);
	
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonUseClient.ShowCommentEditingForm(
		Item.EditText, ThisObject, "Object.Comment");
	
EndProcedure

#EndRegion

#Region RolesFormTableItemEventHandlers

////////////////////////////////////////////////////////////////////////////////
// Role interface procedures and functions

&AtClient
Procedure RolesCheckOnChange(Item)
	
	If Items.Roles.CurrentData <> Undefined Then
		ProcessRolesInterface("UpdateRoleContent");
	EndIf;
	
EndProcedure

#EndRegion

#Region ContentFormTableItemsEventHandlers

&AtClient
Procedure ContentChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	Object.Content.Clear();
	If TypeOf(SelectedValue) = Type("Array") Then
		For Each Value In SelectedValue Do
			ExternalUserSelectionProcessing(Value);
		EndDo;
	Else
		ExternalUserSelectionProcessing(SelectedValue);
	EndIf;
	
EndProcedure

&AtClient
Procedure ContentExternalUserStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	SelectPickUsers(False);
	
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
Procedure PickExternalUsers(Command)

	SelectPickUsers(True);
	
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

&AtClient
Procedure ShowSelectedRolesOnly(Command)
	
	ProcessRolesInterface("SelectedRolesOnly");
	UsersInternalClient.ExpandRoleSubsystems(ThisObject);
	
EndProcedure

&AtClient
Procedure RoleGroupingBySubsystems(Command)
	
	ProcessRolesInterface("GroupBySubsystems");
	UsersInternalClient.ExpandRoleSubsystems(ThisObject);
	
EndProcedure

&AtClient
Procedure EnableRoles(Command)
	
	ProcessRolesInterface("UpdateRoleContent", "EnableAll");
	
	UsersInternalClient.ExpandRoleSubsystems(ThisObject, False);
	
EndProcedure

&AtClient
Procedure DisableRoles(Command)
	
	ProcessRolesInterface("UpdateRoleContent", "DisableAll");
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
 

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ContentExternalUser.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Content.NotValid");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", WebColors.Gray);

EndProcedure

&AtClient
Procedure AuthorizationObjectTypePresentationEndChoice(SelectedItem, NotDefined) Export
	
	If SelectedItem <> Undefined Then
		
		Modified = True;
		Object.AuthorizationObjectType      = SelectedItem.Value;
		AuthorizationObjectTypePresentation = SelectedItem.Presentation;
		
		AuthorizationObjectTypePresentationOnChange(Items.AuthorizationObjectTypePresentation);
	EndIf;
	
EndProcedure

&AtServer
Function MoveUserToTheGroup(UserArray, NewOwnerGroup)
	
	MovedUsersArray = New Array;
	For Each UserRef In UserArray Do
		
		FilterParameters = New Structure("ExternalUser", UserRef);
		If TypeOf(UserRef) = Type("CatalogRef.ExternalUsers")
			And Object.Content.FindRows(FilterParameters).Count() = 0 Then
			Object.Content.Add().ExternalUser = UserRef;
			MovedUsersArray.Add(UserRef);
		EndIf;
		
	EndDo;
	
	Return UsersInternal.UserMessageCreation(
		MovedUsersArray, NewOwnerGroup, False);
	
EndFunction

&AtServer
Procedure SelectAvailableGroupParticipantsTypes()
	
	If ValueIsFilled(Object.Parent)
		And Object.Parent <> Catalogs.ExternalUserGroups.AllExternalUsers Then
		
		If Object.Parent.AuthorizationObjectType <> Undefined Then
			ValueFound = AuthorizationObjectTypes.FindByValue(Object.Parent.AuthorizationObjectType);
			Object.AuthorizationObjectType      = ValueFound.Value;
			AuthorizationObjectTypePresentation = ValueFound.Presentation;
			GroupMembers = Items.GroupMembers.ChoiceList.FindByValue("SingleType").Value;
			Items.UserType.Enabled = False;
		Else
			Items.UserType.Enabled = True;
			ValueFound = Items.GroupMembers.ChoiceList.FindByValue("AllOfSingleType");
			If ValueFound <> Undefined Then
				Items.GroupMembers.ChoiceList.Delete(ValueFound);
			EndIf;
			
		EndIf;
		
	Else
		
		ValueFound = Items.GroupMembers.ChoiceList.FindByValue("AllOfSingleType");
		If ValueFound = Undefined Then
			Items.GroupMembers.ChoiceList.Insert(0, "AllOfSingleType", NStr("en = 'All users of specified type'"));
		EndIf;
		Items.UserType.Enabled = True;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetActionsOnForm()
	
	ActionsOnForm = New Structure;
	
	// "", "View", "Edit".
	ActionsOnForm.Insert("Roles", "");
	
	// "", "View", "Edit".
	ActionsOnForm.Insert("GroupContent", "");
	
	// "", "View", "Edit".
	ActionsOnForm.Insert("ItemProperties", "");
	
	If Users.InfobaseUserWithFullAccess()
	 Or AccessRight("Insert", Metadata.Catalogs.Users) Then
		// Administrator.
		ActionsOnForm.Roles          = "Edit";
		ActionsOnForm.GroupContent   = "Edit";
		ActionsOnForm.ItemProperties = "Edit";
		
	ElsIf IsInRole("AddEditExternalUsers") Then
		// External user manager.
		ActionsOnForm.Roles          = "";
		ActionsOnForm.GroupContent   = "Edit";
		ActionsOnForm.ItemProperties = "Edit";
		
	Else
		// External user viewer.
		ActionsOnForm.Roles          = "";
		ActionsOnForm.GroupContent   = "View";
		ActionsOnForm.ItemProperties = "View";
	EndIf;
	
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.Users\OnDefineActionsInForm");
	
	For Each Handler In EventHandlers Do
		Handler.Module.OnDefineActionsInForm(Object.Ref, ActionsOnForm);
	EndDo;
	
	UsersOverridable.ChangeActionsOnForm(Object.Ref, ActionsOnForm);
	
	// Check actions names in a form
	If Find(", View, Edit,", ", " + ActionsOnForm.Roles + ",") = 0 Then
		ActionsOnForm.Roles = "";
	ElsIf UsersInternal.RoleEditProhibition() Then
		ActionsOnForm.Roles = "";
	EndIf;
	If Find(", View, Edit,", ", " + ActionsOnForm.GroupContent + ",") = 0 Then
		ActionsOnForm.InfobaseUserProperties = "";
	EndIf;
	If Find(", View, Edit,", ", " + ActionsOnForm.ItemProperties + ",") = 0 Then
		ActionsOnForm.ItemProperties = "";
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetPropertyEnabled(Form)
	
	Items = Form.Items;
	
	Items.Content.ReadOnly = Form.Object.AllAuthorizationObjects;
	
	CommandAvailability =
		Not Form.ReadOnly
		And Not Items.GroupExternalUsers.ReadOnly
		And Not Items.Content.ReadOnly
		And Items.Content.Enabled;
		
	Items.ContentPick.Enabled            = CommandAvailability;
	Items.ContentContextMenuPick.Enabled = CommandAvailability;
	Items.ContentAdd.Enabled             = CommandAvailability;
	Items.ContentContextMenuAdd.Enabled  = CommandAvailability;
	
	Items.AuthorizationObjectTypePresentation.Visible = 
		Not Form.IsAllExternalUsersGroup
		And ((Form.GroupMembers = "SingleType" Or Form.GroupMembers = "AllOfSingleType"));
	
EndProcedure

&AtServer
Procedure FillAuthorizationObjectTypeList()
	
	AuthorizationObjectRefTypes =
		Metadata.Catalogs.ExternalUsers.Attributes.AuthorizationObject.Type.Types();
	
	For Each AuthorizationObjectRefType In AuthorizationObjectRefTypes Do
		TypeMetadata = Metadata.FindByType(AuthorizationObjectRefType);
		
		TypeArray = New Array;
		TypeArray.Add(AuthorizationObjectRefType);
		RefTypeDescription = New TypeDescription(TypeArray);
		
		AuthorizationObjectTypes.Add(
			RefTypeDescription.AdjustValue(Undefined), TypeMetadata.Synonym);
	EndDo;
	
	FoundItem = AuthorizationObjectTypes.FindByValue(Object.AuthorizationObjectType);
	
	AuthorizationObjectTypePresentation = ?(
		FoundItem = Undefined, "", FoundItem.Presentation);
	
EndProcedure

&AtServer
Procedure DeleteNotTypicalExternalUsers()
	
	Query = New Query;
	Query.SetParameter("AuthorizationObjectType", TypeOf(Object.AuthorizationObjectType));
	Query.SetParameter(
		"SelectedExternalUsers",
		Object.Content.Unload().UnloadColumn("ExternalUser"));
	
	Query.Text =
	"SELECT
	|	ExternalUsers.Ref
	|FROM
	|	Catalog.ExternalUsers AS ExternalUsers
	|WHERE
	|	VALUETYPE(ExternalUsers.AuthorizationObject) <> &AuthorizationObjectType
	|	AND ExternalUsers.Ref IN(&SelectedExternalUsers)";
	
	BeginTransaction();
	Try
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			
			FoundRows = Object.Content.FindRows(
				New Structure("ExternalUser", Selection.Ref));
			
			For Each FoundRow In FoundRows Do
				Object.Content.Delete(Object.Content.IndexOf(FoundRow));
			EndDo;
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

&AtClient
Procedure SelectPickUsers(Pick)
	
	FormParameters = New Structure;
	FormParameters.Insert("ChoiceMode", True);
	FormParameters.Insert("CurrentRow", ?(
		Items.Content.CurrentData = Undefined,
		Undefined,
		Items.Content.CurrentData.ExternalUser));
	
	If Pick Then
		FormParameters.Insert("CloseOnChoice", False);
		FormParameters.Insert("MultipleChoice", True);
		FormParameters.Insert("ExtendedPick", True);
		FormParameters.Insert("ExtendedPickFormParameters", ExtendedPickFormParameters());
	EndIf;
	
	If Object.AuthorizationObjectType <> Undefined Then
		FormParameters.Insert("AuthorizationObjectType", Object.AuthorizationObjectType);
	EndIf;
	
	OpenForm(
		"Catalog.ExternalUsers.ChoiceForm",
		FormParameters,
		?(Pick,
			Items.Content,
			Items.ContentExternalUser));
	
EndProcedure

&AtClient
Procedure ExternalUserSelectionProcessing(SelectedValue)
	
	If TypeOf(SelectedValue) = Type("CatalogRef.ExternalUsers") Then
		Object.Content.Add().ExternalUser = SelectedValue;
	EndIf;
	
EndProcedure

&AtServer
Function ExtendedPickFormParameters()
	
	SelectedUsers = New ValueTable;
	SelectedUsers.Columns.Add("User");
	SelectedUsers.Columns.Add("PictureNumber");
	
	ExternalUsersGroupParticipants = Object.Content.Unload(, "ExternalUser");
	
	For Each Item In ExternalUsersGroupParticipants Do
		
		SelectedUsersRow = SelectedUsers.Add();
		SelectedUsersRow.User = Item.ExternalUser;
		
	EndDo;
	
	PickFormTitle = NStr("en = 'Pick external user group members'");
	ExtendedPickFormParameters = 
		New Structure("PickFormTitle, SelectedUsers, SelectionOfGroupsIsNotPossible",
		                 PickFormTitle, SelectedUsers, True);
	StorageAddress = PutToTempStorage(ExtendedPickFormParameters);
	Return StorageAddress;
	
EndFunction

&AtServer
Procedure FillUserStatus()
	
	For Each GroupContentRow In Object.Content Do
		GroupContentRow.NotValid = 
			CommonUse.ObjectAttributeValue(GroupContentRow.ExternalUser, "NotValid");
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
		Object.Content.Sort("ExternalUser Asc");
	Else
		Object.Content.Sort("ExternalUser Desc");
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
 
&AtServer
Procedure ProcessRolesInterface(Action, MainParameter = Undefined)
	
	ActionParameters = New Structure;
	ActionParameters.Insert("MainParameter",      MainParameter);
	ActionParameters.Insert("Form",               ThisObject);
	ActionParameters.Insert("RoleCollection",     RoleCollection);
	ActionParameters.Insert("UserType",           Enums.UserTypes.ExternalUser);
	ActionParameters.Insert("HideFullAccessRole", True);
	
	UsersInternal.ProcessRolesInterface(Action, ActionParameters);
	
EndProcedure

#EndRegion
