#If Server OR ThickClientOrdinaryApplication OR ExternalConnection Then

#Region InternalProceduresAndFunctions

// This procedure updates all register data.
// 
// Parameters:
//  HasChanges - Boolean (return value) - True if data is changed; not set otherwise.
//
Procedure UpdateRegisterData(HasChanges = Undefined) Export
	
	SetPrivilegedMode(True);
	
	DataLock = New DataLock;
	LockItem = DataLock.Add("Catalog.Users");
	LockItem.Mode = DataLockMode.Shared;
	LockItem = DataLock.Add("Catalog.UserGroups");
	LockItem.Mode = DataLockMode.Shared;
	LockItem = DataLock.Add("Catalog.ExternalUsers");
	LockItem.Mode = DataLockMode.Shared;
	LockItem = DataLock.Add("Catalog.ExternalUserGroups");
	LockItem.Mode = DataLockMode.Shared;
	LockItem = DataLock.Add("InformationRegister.UserGroupContents");
	LockItem.Mode = DataLockMode.Exclusive;
	
	BeginTransaction();
	Try
		DataLock.Lock();
		
		// Updating user mapping
		ItemsToChange  = New Map;
		ModifiedGroups = New Map;
		
		Selection = Catalogs.UserGroups.Select();
		While Selection.Next() Do
			UsersInternal.UpdateUserGroupContents(
				Selection.Ref, , ItemsToChange, ModifiedGroups);
		EndDo;
		
		// Updating external user mapping
		Selection = Catalogs.ExternalUserGroups.Select();
		While Selection.Next() Do
			UsersInternal.UpdateExternalUserGroupContent(
				Selection.Ref, , ItemsToChange, ModifiedGroups);
		EndDo;
		
		If ItemsToChange.Count() > 0
		 Or ModifiedGroups.Count() > 0 Then
		
			HasChanges = True;
			
			UsersInternal.AfterUserGroupContentUpdate(
				ItemsToChange, ModifiedGroups);
		EndIf;
		
		UsersInternal.UpdateExternalUserRoles();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#EndIf