#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Interface

// The object interface implementation is based on AdditionalProperties:
//
// InfobaseUserDescription - Structure, as in object module of Users catalog.

#EndRegion

////////////////////////////////////////////////////////////////////////////////
// INTERNAL VARIABLES

Var InfobaseUserProcessingParameters; // Parameters that are filled during infobase user processing.
                                      // Used in OnWrite event handler.

Var IsNew; // Shows whether new object was written.
           // Used in OnWrite event handler.

Var OldAuthorizationObject; // Authorization object value before changes.
                            // Used in OnWrite event handler.

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	IsNew = IsNew();
	
	If Not ValueIsFilled(AuthorizationObject) Then
		Raise NStr("en = 'The external user does not have associated infobase object.'");
	Else
		ErrorText = "";
		If UsersInternal.AuthorizationObjectUsed(
		         AuthorizationObject, Ref, , , ErrorText) Then
			
			Raise ErrorText;
		EndIf;
	EndIf;
	
	// Checking whether it is different authorization object.
	If IsNew Then
		OldAuthorizationObject = NULL;
	Else
		OldAuthorizationObject = CommonUse.ObjectAttributeValue(
			Ref, "AuthorizationObject");
		
		If ValueIsFilled(OldAuthorizationObject)
		   AND OldAuthorizationObject <> AuthorizationObject Then
			
			Raise NStr("en = 'Cannot associate the external user with another infobase object.'");
		EndIf;
	EndIf;
	
	UsersInternal.StartInfobaseUserProcessing(ThisObject, InfobaseUserProcessingParameters);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// Updating content of the group where the new external user belongs (provided 
  //that the group is specified).
	If AdditionalProperties.Property("NewExternalUserGroup") AND
	     ValueIsFilled(AdditionalProperties.NewExternalUserGroup) Then
		
		DataLock = New DataLock;
		LockItem = DataLock.Add("Catalog.ExternalUserGroups");
		LockItem.Mode = DataLockMode.Exclusive;
		DataLock.Lock();
		
		GroupObject = AdditionalProperties.NewExternalUserGroup.GetObject();
		GroupObject.Content.Add().ExternalUser = Ref;
		GroupObject.Write();
	EndIf;
	
	// Updating content of the "All external users" group, which is always present.
	ItemsToChange    = New Map;
	ModifiedGroups   = New Map;
	
	UsersInternal.UpdateExternalUserGroupContent(
		Catalogs.ExternalUserGroups.AllExternalUsers,
		Ref,
		ItemsToChange,
		ModifiedGroups);
	
	UsersInternal.RefreshContentUsingOfUserGroups(
		Ref, ItemsToChange, ModifiedGroups);
	
	UsersInternal.EndInfobaseUserProcessing(
		ThisObject, InfobaseUserProcessingParameters);
	
	UsersInternal.AfterUpdateExternalUserGroupContents(
		ItemsToChange,
		ModifiedGroups);
	
	If OldAuthorizationObject <> AuthorizationObject Then
		UsersInternal.AfterChangeExternalUserAuthorizationObject(
			Ref, OldAuthorizationObject, AuthorizationObject);
	EndIf;
	
	UsersInternal.AfterAddUserOrGroupChange(Ref, IsNew);
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	CommonActionsBeforeDeleteInOrdinaryModeAndOnDataExchange();
	
EndProcedure

Procedure OnCopy(ObjectToCopy)
	
	AdditionalProperties.Insert("CopyingValue", ObjectToCopy.Ref);
	
	InfobaseUserID = Undefined;
	ServiceUserID = Undefined;
	Prepared = False;
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

// For internal use only
Procedure CommonActionsBeforeDeleteInOrdinaryModeAndOnDataExchange() Export
	
	// Infobase user must be deleted, otherwise it will be included in the list of errors of the InfobaseUsers form. 
  //In addition, an attempt to log on to the infobase as this user generetes an error.
	
	InfobaseUserDescription = New Structure;
	InfobaseUserDescription.Insert("Action", "Delete");
	AdditionalProperties.Insert("InfobaseUserDescription", InfobaseUserDescription);
	
	UsersInternal.StartInfobaseUserProcessing(ThisObject, InfobaseUserProcessingParameters, True);
	UsersInternal.EndInfobaseUserProcessing(ThisObject, InfobaseUserProcessingParameters);
	
EndProcedure

#EndRegion

#EndIf