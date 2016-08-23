
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();

  // Skipping the initialization to guarantee that the form will be received if the Autotest parameter is passed.
	If Parameters.Property("Autotest") Then 
		Return;
	EndIf;
	
	If Parameters.User <> Undefined Then
		UserArray = New Array;
		UserArray.Add(Parameters.User);
		
		ExternalUsers = ?(
			TypeOf(Parameters.User) = Type("CatalogRef.ExternalUsers"), True, False);
		
		Items.FormWriteAndClose.Title = NStr("en = 'Save'");
		
		OpenFromUserCardMode = True;
	Else
		UserArray = Parameters.Users;
		ExternalUsers = Parameters.ExternalUsers;
		OpenFromUserCardMode = False;
	EndIf;
	
	UserCount = UserArray.Count();
	CommonUseClientServer.Validate(UserCount > 0, 
		NStr("en = 'No user selected.'"));
		
	UserType = Undefined;
	For Each UserFromArray In UserArray Do
		If UserType = Undefined Then
			UserType = TypeOf(UserFromArray);
		EndIf;
		UserTypeFromArray = TypeOf(UserFromArray);
		CommonUseClientServer.Validate(UserTypeFromArray = Type("CatalogRef.Users")
			OR UserTypeFromArray = Type("CatalogRef.ExternalUsers"), 
			NStr("en = 'Cannot execute the command for the specified object.'"));
		CommonUseClientServer.Validate(UserType = UserTypeFromArray, 
			NStr("en = 'The command cannot be executed for two user types simultaneously.'"));
	EndDo;		
		
	If UserCount > 1
		And Parameters.User = Undefined Then
		Title = NStr("en = 'User groups'");
		Items.GroupTreeCheck.ThreeState = True;
	EndIf;
	
	UserList = New Structure;
	UserList.Insert("UserArray", UserArray);
	UserList.Insert("UserCount", UserCount);
	FillGroupTree();
	
	If GroupTree.GetItems().Count() = 0 Then
		Items.GroupsOrWarning.CurrentPage = Items.Warning;
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If Not OpenFromUserCardMode Then
		Notification = New NotifyDescription("WriteAndCloseBeginning", ThisObject);
		CommonUseClient.ShowFormClosingConfirmation(Notification, Cancel);
	EndIf;
	
EndProcedure

#EndRegion

#Region GroupTreeTableItemEventHandlers

&AtClient
Procedure GroupTreeSelection(Item, SelectedRow, Field, StandardProcessing)
	
	StandardProcessing = False;
	ShowValue(,Item.CurrentData.Group);
	
EndProcedure

&AtClient
Procedure GroupTreeCheckOnChange(Item)
	Modified = True;
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure WriteAndClose(Command)
	WriteAndCloseBeginning();
EndProcedure

&AtClient
Procedure UncheckAll(Command)
	
	FillGroupTree(True);
	ExpandValueTree();
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GroupTreeCheck.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GroupTree.ReadOnlyGroup");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("ReadOnly", True);

EndProcedure

&AtClient
Procedure WriteAndCloseBeginning(Result = Undefined, AdditionalParameters = Undefined) Export
	
	UserNotification = New Structure;
	UserNotification.Insert("Message");
	UserNotification.Insert("HasErrors");
	UserNotification.Insert("FullMessageText");
	
	WriteChanges(UserNotification);
	
	If UserNotification.HasErrors = False Then
		If UserNotification.Message <> Undefined Then
			ShowUserNotification(
				NStr("en = 'Moving users...'"), , UserNotification.Message, PictureLib.Information32);
		EndIf;
	Else
		
		If UserNotification.FullMessageText <> Undefined Then
			Report = New TextDocument;
			Report.AddLine(UserNotification.FullMessageText);
			
			QuestionText = UserNotification.Message;
			QuestionButtons = New ValueList;
			QuestionButtons.Add("OK", NStr("en='OK'"));
			QuestionButtons.Add("ShowReport", NStr("en='Show report'"));
			Notification = New NotifyDescription("WriteAndCloseQuestionProcessing", ThisObject, Report);
			ShowQueryBox(Notification, QuestionText, QuestionButtons,, QuestionButtons[0].Value);
		Else
			Notification = New NotifyDescription("WriteAndCloseWarningProcessing", ThisObject);
			ShowMessageBox(Notification, UserNotification.Message);
		EndIf;
		
		Return;
	EndIf;
	
	Modified = False;
	WriteAndCloseCompletion();
	
EndProcedure

&AtServer
Procedure FillGroupTree(UncheckAllOnly = False)
	
	GroupTreeTarget = FormAttributeToValue("GroupTree");
	If Not UncheckAllOnly Then
		GroupTreeTarget.Rows.Clear();
	EndIf;
	
	If UncheckAllOnly Then
		
		WereChanges = False;
		Found = GroupTreeTarget.Rows.FindRows(New Structure("Mark", 1), True);
		For Each TreeRow In Found Do
			If Not TreeRow.ReadOnlyGroup Then
				TreeRow.Check = 0;
				WereChanges = True;
			EndIf;
		EndDo;
		
		Found = GroupTreeTarget.Rows.FindRows(New Structure("Mark", 2), True);
		For Each TreeRow In Found Do
			TreeRow.Check = 0;
			WereChanges = True;
		EndDo;
		
		If WereChanges Then
			Modified = True;
		EndIf;
		
		ValueToFormAttribute(GroupTreeTarget, "GroupTree");
		Return;
	EndIf;
	
	UserGroups = Undefined;
	Subgroups = New Array;
	ParentArray = New Array;
	
	If ExternalUsers Then
		EmptyGroup = Catalogs.ExternalUserGroups.EmptyRef();
		GetExternalUserGroups(UserGroups);
	Else
		EmptyGroup = Catalogs.UserGroups.EmptyRef();
		GetUserGroups(UserGroups);
	EndIf;
	
	If UserGroups.Count() <= 1 Then
		Items.GroupsOrWarning.CurrentPage = Items.Warning;
		Return;
	EndIf;
	
	GetSubgroups(UserGroups, Subgroups, EmptyGroup);
	
	If TypeOf(UserList.UserArray[0]) = Type("CatalogRef.Users") Then
		UserType = "User";
	Else
		UserType = "ExternalUser";
	EndIf;
	
	While Subgroups.Count() > 0 Do
		ParentArray.Clear();
		
		For Each CurGroup In Subgroups Do
			
			If CurGroup.Parent = EmptyGroup Then
				NewGroupRow = GroupTreeTarget.Rows.Add();
				NewGroupRow.Group = CurGroup.Ref;
				NewGroupRow.Picture = ?(UserType = "User", 3, 9);
				
				If UserList.UserCount = 1 Then
					UserIndirectlyIncludedInGroup = False;
					UserRef = UserList.UserArray[0];
					
					If UserType = "ExternalUser" Then
						UserIndirectlyIncludedInGroup = (CurGroup.AllAuthorizationObjects And 
							(TypeOf(UserRef.AuthorizationObject) = TypeOf(CurGroup.AuthorizationObjectType)));
						NewGroupRow.ReadOnlyGroup = UserIndirectlyIncludedInGroup;
					EndIf;
					
					FoundUser = CurGroup.Ref.Content.Find(UserRef, UserType);
					NewGroupRow.Check = ?(FoundUser <> Undefined OR UserIndirectlyIncludedInGroup, 1, 0);
				Else
					NewGroupRow.Check = 2;
				EndIf;
				
			Else
				GroupParent = 
					GroupTreeTarget.Rows.FindRows(New Structure("Group", CurGroup.Parent), True);
				NewSubgroupRow = GroupParent[0].Rows.Add();
				NewSubgroupRow.Group = CurGroup.Ref;
				NewSubgroupRow.Picture = ?(UserType = "User", 3, 9);
				
				If UserList.UserCount = 1 Then
					NewSubgroupRow.Check = ?(CurGroup.Ref.Content.Find(
						UserList.UserArray[0], UserType) = Undefined, 0, 1);
				Else
					NewSubgroupRow.Check = 2;
				EndIf;
				
			EndIf;
			
			ParentArray.Add(CurGroup.Ref);
		EndDo;
		Subgroups.Clear();
		
		For Each Item In ParentArray Do
			GetSubgroups(UserGroups, Subgroups, Item);
		EndDo;
		
	EndDo;
	
	GroupTreeTarget.Rows.Sort("Group Asc", True);
	ValueToFormAttribute(GroupTreeTarget, "GroupTree");
	
EndProcedure

&AtServer
Procedure GetUserGroups(UserGroups)
	
	Query = New Query;
	Query.Text = "SELECT
	|	UserGroups.Ref,
	|	UserGroups.Parent
	|FROM
	|	Catalog.UserGroups AS UserGroups
	|WHERE
	|	UserGroups.DeletionMark <> TRUE";
	
	UserGroups = Query.Execute().Unload();
	
EndProcedure

&AtServer
Procedure GetExternalUserGroups(UserGroups)
	
	Query = New Query;
	Query.Text = "SELECT
	|	ExternalUserGroups.Ref,
	|	ExternalUserGroups.Parent,
	|	ExternalUserGroups.AuthorizationObjectType,
	|	ExternalUserGroups.AllAuthorizationObjects
	|FROM
	|	Catalog.ExternalUserGroups AS ExternalUserGroups
	|WHERE
	|	ExternalUserGroups.DeletionMark <> TRUE";
	
	UserGroups = Query.Execute().Unload();
	
EndProcedure

&AtServer
Procedure GetSubgroups(UserGroups, Subgroups, GroupParent)
	
	FilterParameters = New Structure("Parent", GroupParent);
	SelectedRows = UserGroups.FindRows(FilterParameters);
	
	For Each Item In SelectedRows Do
		
		If Item.Ref = Catalogs.UserGroups.AllUsers
			OR Item.Ref = Catalogs.ExternalUserGroups.AllExternalUsers Then
			Continue;
		EndIf;
		
		Subgroups.Add(Item);
	EndDo;
	
EndProcedure

&AtServer
Procedure WriteChanges(UserNotification)
	
	UserArray = Undefined;
	UnmovedUsers = New Map;
	GroupTreeSource = GroupTree.GetItems();
	RefillGroupContent(GroupTreeSource, UserArray, UnmovedUsers);
	GenerateMessageText(UserArray, UserNotification, UnmovedUsers)
	
EndProcedure

&AtServer
Procedure RefillGroupContent(GroupTreeSource, MovedUsersArray, UnmovedUsers)
	
	UserArray = UserList.UserArray;
	If MovedUsersArray = Undefined Then
		MovedUsersArray = New Array;
	EndIf;
	
	For Each TreeRow In GroupTreeSource Do
		
		If TreeRow.Check = 1
			And Not TreeRow.ReadOnlyGroup Then
			
			For Each UserRef In UserArray Do
				
				If TypeOf(UserRef) = Type("CatalogRef.Users") Then
					UserType = "User";
				Else
					UserType = "ExternalUser";
					CanMove = UsersInternal.CanMoveUser(TreeRow.Group, UserRef);
					
					If Not CanMove Then
						
						If UnmovedUsers.Get(UserRef) = Undefined Then
							UnmovedUsers.Insert(UserRef, New Array);
							UnmovedUsers[UserRef].Add(TreeRow.Group);
						Else
							UnmovedUsers[UserRef].Add(TreeRow.Group);
						EndIf;
						
						Continue;
					EndIf;
					
				EndIf;
				
				Add = ?(TreeRow.Group.Content.Find(
					UserRef, UserType) = Undefined, True, False);
				If Add Then
					UsersInternal.AddUserToGroup(TreeRow.Group, UserRef, UserType);
					
					If MovedUsersArray.Find(UserRef) = Undefined Then
						MovedUsersArray.Add(UserRef);
					EndIf;
					
				EndIf;
				
			EndDo;
			
		ElsIf TreeRow.Check = 0
			And Not TreeRow.ReadOnlyGroup Then
			
			For Each UserRef In UserArray Do
				
				If TypeOf(UserRef) = Type("CatalogRef.Users") Then
					UserType = "User";
				Else
					UserType = "ExternalUser";
				EndIf;
				
				Delete = ?(TreeRow.Group.Content.Find(
					UserRef, UserType) <> Undefined, True, False);
				If Delete Then
					UsersInternal.DeleteUserFromGroup(TreeRow.Group, UserRef, UserType);
					
					If MovedUsersArray.Find(UserRef) = Undefined Then
						MovedUsersArray.Add(UserRef);
					EndIf;
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
		TreeRowItems = TreeRow.GetItems();
		// Recursion
		RefillGroupContent(TreeRowItems, MovedUsersArray, UnmovedUsers);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure GenerateMessageText(MovedUsersArray, UserNotification, UnmovedUsers)
	
	UserCount = MovedUsersArray.Count();
	UnmovedUsersCount = UnmovedUsers.Count();
	UserString = "";
	
	If UnmovedUsersCount > 0 Then
		
		If UnmovedUsersCount = 1 Then
			For Each UnmovedUser In UnmovedUsers Do
				Subject = String(UnmovedUser.Key);
			EndDo;
			UserMessage = NStr("en = 'Cannot include user ""%1"" in the selected  groups because they have different types or the groups have the ""All users with specified type"" parameter set.'");
		Else
			Raise("CHECK ON TEST");
     NumerationItemOptions = NStr("en = 'user,users,,,0'");
			Subject = UsersInternal.GenerateWordEnding(UnmovedUsersCount, NumerationItemOptions);
			UserMessage = NStr("en = Some users are not included in the selected groups because they have different types or the groups have the ""All users with specified type"" parameter set.'");
			For Each UnmovedUser In UnmovedUsers Do
			UserString = UserString + String(UnmovedUser.Key) + ": " + 
				StringFunctionsClientServer.StringFromSubstringArray(UnmovedUser.Value) + Chars.LF;
			EndDo;
			UserNotification.FullMessageText = NStr("en = 'The following users were not added to the selected groups:'") +
				Chars.LF + Chars.LF + UserString;
		EndIf;
		UserNotification.Message = StringFunctionsClientServer.SubstituteParametersInString(
			UserMessage, Subject);
		UserNotification.HasErrors = True;
		
		Return;
	ElsIf UserCount = 1 Then
		UserDescription = CommonUse.ObjectAttributeValue(MovedUsersArray[0], "Description");
		UserMessage = NStr("en = 'The list of groups is modified for user ""%1""'");
		UserNotification.Message = StringFunctionsClientServer.SubstituteParametersInString(
			UserMessage, UserDescription);
	ElsIf UserCount > 1 Then
		
		UserMessage = NStr("en = 'The list of groups is modified for %1'");
   RAISE("CHECK ON TEST");
		StringObject = UsersInternal.GenerateWordEnding(
			UserCount, NStr("en = 'user,users,,,0'"));
		UserNotification.Message = StringFunctionsClientServer.SubstituteParametersInString(
			UserMessage, StringObject);
		
	EndIf;
	UserNotification.HasErrors = False;
	
EndProcedure

&AtClient
Procedure ExpandValueTree()
	
	Rows = GroupTree.GetItems();
	For Each Row In Rows Do
		Items.GroupTree.Expand(Row.GetID(), True);
	EndDo;
	
EndProcedure

&AtClient
Procedure WriteAndCloseQuestionProcessing(Answer, Report) Export
	
	If Answer = "OK" Then
		Return;
	Else
		Report.Show(NStr("en = 'Users not included in groups'"));
		Return;
	EndIf;
	
	Modified = False;
	WriteAndCloseCompletion();
	
EndProcedure

&AtClient
Procedure WriteAndCloseWarningProcessing(AdditionalParameters) Export
	
	WriteAndCloseCompletion();
	
EndProcedure

&AtClient
Procedure WriteAndCloseCompletion()
	
	Notify("ArrangeUsersInGroups");
	If ExternalUsers Then
		Notify("Write_ExternalUserGroups");
	Else
		Notify("Write_UserGroups");
	EndIf;
	
	If Not OpenFromUserCardMode Then
		Close();
	Else
		FillGroupTree();
		ExpandValueTree();
	EndIf;
	
EndProcedure

#EndRegion