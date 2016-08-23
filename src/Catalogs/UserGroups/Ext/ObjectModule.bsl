#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

////////////////////////////////////////////////////////////////////////////////
// INTERNAL VARIABLES

Var OldParent; // Value of the group parent before changes, to be used in OnWrite event handler.

Var OldContentUserGroups; // User group content (list of users) before changes, to be used in OnWrite event handler.

Var IsNew; // Shows whether new object was written.
           // Used in OnWrite event handler.

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, AttributesToCheck)
	
	CheckedObjectAttributes = New Array;
	Errors = Undefined;
	
	// Checking the parent.
	If Parent = Catalogs.UserGroups.AllUsers Then
		CommonUseClientServer.AddUserError(Errors,
			"Object.Parent",
			NStr("en = '""All users"" predefined group cannot be used as a parent.'"));
	EndIf;
	
	// Checking whether blank or duplicate users are present
	CheckedObjectAttributes.Add("Content.User");
	
	For Each CurrentRow In Content Do;
		LineNumber = Content.IndexOf(CurrentRow);
		
		// Checking whether value is filled
		If Not ValueIsFilled(CurrentRow.User) Then
			CommonUseClientServer.AddUserError(Errors,
				"Object.Content[%1].User",
				NStr("en = 'User name is not specified.'"),
				"Object.Content",
				LineNumber,
				NStr("en = 'User name is not specified in row #%1.'"));
			Continue;
		EndIf;
		
		// Checking whether duplicate values are present
		FoundValues = Content.FindRows(New Structure("User", CurrentRow.User));
		If FoundValues.Count() > 1 Then
			CommonUseClientServer.AddUserError(Errors,
				"Object.Content[%1].User",
				NStr("en = 'Duplicate user.'"),
				"Object.Content",
				LineNumber,
				NStr("en = 'Duplicate user in row #%1.'"));
		EndIf;
	EndDo;
	
	CommonUseClientServer.ShowErrorsToUser(Errors, Cancel);
	
	CommonUse.DeleteNoCheckAttributesFromArray(AttributesToCheck, CheckedObjectAttributes);
	
EndProcedure

// Blocking invalid operation with "All users" predefined group.
Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	IsNew = IsNew();
	
	If Ref = Catalogs.UserGroups.AllUsers Then
		If NOT Parent.IsEmpty() Then
			Raise
				NStr("en = '""All users"" predefined group must be the root one.'");
		EndIf;
		If Content.Count() > 0 Then
			Raise
				NStr("en = 'Adding users to ""All users"" group is not supported.'");
		EndIf;
	Else
		If Parent = Catalogs.UserGroups.AllUsers Then
			Raise
				NStr("en = '""All users"" predefined group cannot be used as a parent.'");
		EndIf;
		
		OldParent = ?(
			Ref.IsEmpty(),
			Undefined,
			CommonUse.ObjectAttributeValue(Ref, "Parent"));
			
		If ValueIsFilled(Ref)
		   AND Ref <> Catalogs.UserGroups.AllUsers Then
			
			OldContentUserGroups =
				CommonUse.ObjectAttributeValue(Ref, "Content").Unload();
		EndIf;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	ItemsToChange    = New Map;
	ModifiedGroups   = New Map;
	
	If Ref <> Catalogs.UserGroups.AllUsers Then
		
		UpdateContent = UsersInternal.ColumnValueDifferences(
			"User",
			Content.Unload(),
			OldContentUserGroups);
		
		UsersInternal.UpdateUserGroupContents(
			Ref, UpdateContent, ItemsToChange, ModifiedGroups);
		
		If OldParent <> Parent Then
			
			If ValueIsFilled(Parent) Then
				UsersInternal.UpdateUserGroupContents(
					Parent, , ItemsToChange, ModifiedGroups);
			EndIf;
			
			If ValueIsFilled(OldParent) Then
				UsersInternal.UpdateUserGroupContents(
					OldParent, , ItemsToChange, ModifiedGroups);
			EndIf;
		EndIf;
		
		UsersInternal.RefreshContentUsingOfUserGroups(
			Ref, ItemsToChange, ModifiedGroups);
	EndIf;
	
	UsersInternal.AfterUserGroupContentUpdate(
		ItemsToChange, ModifiedGroups);
	
	UsersInternal.AfterAddUserOrGroupChange(Ref, IsNew);
	
EndProcedure

#EndRegion

#EndIf