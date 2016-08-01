#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

////////////////////////////////////////////////////////////////////////////////
// INTERNAL VARIABLES

Var OldParent; // Value of the group parent before changes, 
               // to be used in OnWrite event handler.

Var ExternalUserGroupsOldContent; // External user group content (list of users) before changes, 
                                  //to be used in OnWrite event handler.

Var ExternalUserGroupOldRolesContent; // External user group roles content (list of roles) before changes,
                                      //to be used in OnWrite event handler.

Var OldValueAllAuthorizationObjects; // AllAuthorizationObjects attribute value before changes, 
                                     //to be used in OnWrite event handler.

Var IsNew; // Shows whether a new object is being written.
           // Used in OnWrite event handler.

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, AttributesToCheck)
	
	If AdditionalProperties.Property("CheckedObjectAttributes") Then
		CheckedObjectAttributes = AdditionalProperties.CheckedObjectAttributes;
	Else
		CheckedObjectAttributes = New Array;
	EndIf;
	
	Errors = Undefined;
	
	// Checking the parent.
	If Parent = Catalogs.ExternalUserGroups.AllExternalUsers Then
		CommonUseClientServer.AddUserError(Errors,
			"Object.Parent",
			NStr("en = '""All external users"" predefined group cannot be used as a parent.'"));
	EndIf;
	
	// Checking whether blank or duplicate external users are present
	CheckedObjectAttributes.Add("Content.ExternalUser");
	
	For Each CurrentRow In Content Do
		LineNumber = Content.IndexOf(CurrentRow);
		
		// Checking whether value is filled
		If Not ValueIsFilled(CurrentRow.ExternalUser) Then
			CommonUseClientServer.AddUserError(Errors,
				"Object.Content[%1].ExternalUser",
				NStr("en = 'External user name is not specified.'"),
				"Object.Content",
				LineNumber,
				NStr("en = 'External user is not specified in row #%1.'"));
			Continue;
		EndIf;
		
		// Checking whether duplicate values are present
		FoundValues = Content.FindRows(New Structure("ExternalUser", CurrentRow.ExternalUser));
		If FoundValues.Count() > 1 Then
			CommonUseClientServer.AddUserError(Errors,
				"Object.Content[%1].ExternalUser",
				NStr("en = 'Duplicate user.'"),
				"Object.Content",
				LineNumber,
				NStr("en = 'Duplicate user in row #%1.'"));
		EndIf;
	EndDo;
	
	CommonUseClientServer.ShowErrorsToUser(Errors, Cancel);
	
	CommonUse.DeleteNoCheckAttributesFromArray(AttributesToCheck, CheckedObjectAttributes);
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not UsersInternal.RoleEditProhibition() Then
		QueryResult = CommonUse.ObjectAttributeValue(Ref, "Roles");
		If TypeOf(QueryResult) = Type("QueryResult") Then
			ExternalUserGroupOldRolesContent = QueryResult.Unload();
		Else
			ExternalUserGroupOldRolesContent = Roles.Unload(New Array);
		EndIf;
	EndIf;
	
	IsNew = IsNew();
	
	If Ref = Catalogs.ExternalUserGroups.AllExternalUsers Then
		
		AuthorizationObjectType = Undefined;
		AllAuthorizationObjects = False;
		
		If Not Parent.IsEmpty() Then
			Raise
				NStr("en = '""All external users"" predefined group must be the root one.'");
		EndIf;
		If Content.Count() > 0 Then
			Raise
				NStr("en = 'Adding users to ""All external users"" group is not supported.'");
		EndIf;
	Else
		If Parent = Catalogs.ExternalUserGroups.AllExternalUsers Then
			Raise
				NStr("en = '""All external users"" predefined group cannot be used as a parent.'");
		ElsIf Parent.AllAuthorizationObjects Then
			Raise
				NStr("en = 'A group with ""All users with specified type"" type cannot be used as a parent.'");
		EndIf;
		
		If AuthorizationObjectType = Undefined Then
			AllAuthorizationObjects = False;
			
		ElsIf AllAuthorizationObjects
		        And ValueIsFilled(Parent) Then
			
			Raise
				NStr("en = 'An external user group that contains all infobase objects with the specified type 
                  |must be the root one.'");
		EndIf;
		
		// Checking whether the group of all authorization objects with the specified type is unique.
		If AllAuthorizationObjects Then
			
			Query = New Query;
			Query.SetParameter("Ref", Ref);
			Query.SetParameter("AuthorizationObjectType", AuthorizationObjectType);
			Query.Text =
			"SELECT
			|	PRESENTATION(ExternalUserGroups.Ref) AS RefPresentation
			|FROM
			|	Catalog.ExternalUserGroups AS ExternalUserGroups
			|WHERE
			|	ExternalUserGroups.Ref <> &Ref
			|	AND ExternalUserGroups.AuthorizationObjectType = &AuthorizationObjectType
			|	AND ExternalUserGroups.AllAuthorizationObjects";
			
			QueryResult = Query.Execute();
			If Not QueryResult.IsEmpty() Then
			
				Selection = QueryResult.Select();
				Selection.Next();
				Raise StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en = External user group ""%1"" for all infobase objects with ""%2"" type in not unique.'"),
					Selection.RefPresentation,
					AuthorizationObjectType.Metadata().Synonym);
			EndIf;
		EndIf;
		
		// Checking whether authorization object type is equal to the parent type 
   // (Undefined parent type is okay).

		If ValueIsFilled(Parent) Then
			
			ParentAuthorizationObjectType = CommonUse.ObjectAttributeValue(
				Parent, "AuthorizationObjectType");
			
			If ParentAuthorizationObjectType <> Undefined
			   And ParentAuthorizationObjectType <> AuthorizationObjectType Then
				
				Raise StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en = Infobase object type of the subordinate external user group must be ""%1"", 
                   |as in ""%2"" parent group.'"),
					ParentAuthorizationObjectType.Metadata().Synonym,
					Parent);
			EndIf;
		EndIf;
		
		// Checking whether external user group has subordinate groups 
   //(if its member type is set to "All users with specified type").
		If AllAuthorizationObjects
			And ValueIsFilled(Ref) Then
			Query = New Query;
			Query.SetParameter("Ref", Ref);
			Query.Text =
			"SELECT
			|	PRESENTATION(ExternalUserGroups.Ref) AS RefPresentation
			|FROM
			|	Catalog.ExternalUserGroups AS ExternalUserGroups
			|WHERE
			|	ExternalUserGroups.Parent = &Ref";
			
			QueryResult = Query.Execute();
			If Not QueryResult.IsEmpty() Then
				Raise StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en = Cannot change member type for ""%1"" external users group
                   |because it has a subordinate external user group"),
					Description);
			EndIf;
			
		EndIf;
		
		// Checking whether no subordinate items with another type are available
   // before changing authorization object type (so that type can be cleared).
		If AuthorizationObjectType <> Undefined
		   And ValueIsFilled(Ref) Then
			
			Query = New Query;
			Query.SetParameter("Ref", Ref);
			Query.SetParameter("AuthorizationObjectType", AuthorizationObjectType);
			Query.Text =
			"SELECT
			|	PRESENTATION(ExternalUserGroups.Ref) AS RefPresentation,
			|	ExternalUserGroups.AuthorizationObjectType
			|FROM
			|	Catalog.ExternalUserGroups AS ExternalUserGroups
			|WHERE
			|	ExternalUserGroups.Parent = &Ref
			|	AND ExternalUserGroups.AuthorizationObjectType <> &AuthorizationObjectType";
			
			QueryResult = Query.Execute();
			If Not QueryResult.IsEmpty() Then
				
				Selection = QueryResult.Select();
				Selection.Next();
				
				If Selection.AuthorizationObjectType = Undefined Then
					OtherAuthorizationObjectTypePresentation = NStr("en = '<Any type>'");
				Else
					OtherAuthorizationObjectTypePresentation =
						Selection.AuthorizationObjectType.Metadata().Synonym;
				EndIf;
				Raise StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en = 'Cannot change infobase object type for ""%1"" external user group
                   |because it has the ""%2"" subordinate group with a different infobase object type ""%3"".'"),
					Description,
					Selection.RefPresentation,
					OtherAuthorizationObjectTypePresentation);
			EndIf;
		EndIf;
		
		OldValues = CommonUse.ObjectAttributeValues(
			Ref, "AllAuthorizationObjects, Parent");
		
		OldParent                       = OldValues.Parent;
		OldValueAllAuthorizationObjects = OldValues.AllAuthorizationObjects;
		
		If ValueIsFilled(Ref)
		   And Ref <> Catalogs.ExternalUserGroups.AllExternalUsers Then
			
			QueryResult = CommonUse.ObjectAttributeValue(Ref, "Content");
			If TypeOf(QueryResult) = Type("QueryResult") Then
				ExternalUserGroupsOldContent = QueryResult.Unload();
			Else
				ExternalUserGroupsOldContent = Content.Unload(New Array);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If UsersInternal.RoleEditProhibition() Then
		IsExternalUserGroupRoleContentChanged = False;
		
	Else
		IsExternalUserGroupRoleContentChanged =
			UsersInternal.ColumnValueDifferences(
				"Role",
				Roles.Unload(),
				ExternalUserGroupOldRolesContent).Count() <> 0;
	EndIf;
	
	ItemsToChange= New Map;
	ModifiedGroups   = New Map;
	
	If Ref <> Catalogs.ExternalUserGroups.AllExternalUsers Then
		
		If AllAuthorizationObjects
		 Or OldValueAllAuthorizationObjects = True Then
			
			UsersInternal.UpdateExternalUserGroupContent(
				Ref, , ItemsToChange, ModifiedGroups);
		Else
			UpdateContent = UsersInternal.ColumnValueDifferences(
				"ExternalUser",
				Content.Unload(),
				ExternalUserGroupsOldContent);
			
			UsersInternal.UpdateExternalUserGroupContent(
				Ref, UpdateContent, ItemsToChange, ModifiedGroups);
			
			If OldParent <> Parent Then
				
				If ValueIsFilled(Parent) Then
					UsersInternal.UpdateExternalUserGroupContent(
						Parent, , ItemsToChange, ModifiedGroups);
				EndIf;
				
				If ValueIsFilled(OldParent) Then
					UsersInternal.UpdateExternalUserGroupContent(
						OldParent, , ItemsToChange, ModifiedGroups);
				EndIf;
			EndIf;
		EndIf;
		
		UsersInternal.RefreshContentUsingOfUserGroups(
			Ref, ItemsToChange, ModifiedGroups);
	EndIf;
	
	If IsExternalUserGroupRoleContentChanged Then
		UsersInternal.UpdateExternalUserRoles(Ref);
	EndIf;
	
	UsersInternal.AfterUpdateExternalUserGroupContents(
		ItemsToChange, ModifiedGroups);
	
	UsersInternal.AfterAddUserOrGroupChange(Ref, IsNew);
	
EndProcedure

#EndRegion

#EndIf