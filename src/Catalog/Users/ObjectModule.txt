#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Interface

// The object interface implementation is based on AdditionalProperties:
//
// InfobaseUserDescription - Structure with the following properties:
//   Action - String - "Write" or "Delete".
//      1. If Action = "Delete", other properties are ignored. 
//      If InfobaseUser is not found by the value of InfobaseUserID attribute, 
//      deletion is also considered successful.
//      2. If Action = "Write", the infobase user is created or updated 
//      according to the specified properties.
//
//   CanLogOnToApplication - Undefined - this value is calculated automatically:
//                           If user access to the infobase is denied, it remains denied. 
//                           Otherwise grant access based on the StandardAuthentication, 
//                           OSAuthentication and OpenIDAuthentication values 
//                           (if all these values are set to False, access is denied).
//                         - Boolean - if True, grant access based on the 
//                                     StandardAuthentication, 
//                                     OSAuthentication and OpenIDAuthentication values;
//                                   - if False, deny user access to infobase.
//                                   - property is not specified - grant access based on the 
//                                     StandardAuthentication, OSAuthentication, and
//                                     OpenIDAuthentication values (to support backward
//                                     compatibility).
//
//   StandardAuthentication, OSAuthentication, OpenIDAuthentication - set authentication type values. 
//   These values take effect if the CanLogOnToApplication property is set to True.
// 
//   Other properties.
//      The content of other properties is specified similarly to the property content of the UpdatedProperties parameter 
//      in the Users.WriteInfobaseUser() procedure, except for the FullName property which is set based on Description.
//
//      To map an independent infobase user to a user from a catalog that is not yet mapped to another infobase user, insert the UUID property. 
//      If you specify the ID of the infobase user that is mapped to the current user, nothing changes.
//
//   The InfobaseUserID object attribute is automatically update when "Write" or "Delete" actions is executed. 
//   Do not change this attribute manually.
//
//   The following properties are inserted to the structure (or updated in the structure) once the action is executed:
//   - ActionResult - Row containing one of the following values:
//       "InfobaseUserAdded", "InfobaseUserChanged", "InfobaseUserDeleted", "MappingToNonExistentInfobaseUserCleared", "InfobaseUserDeletingIsNotNecessary".
//   - ID - infobase user UUID.

#EndRegion

////////////////////////////////////////////////////////////////////////////////
// INTERNAL VARIABLES

Var InfobaseUserProcessingParameters; // Parameters that are filled during infobase user processing.
                                      // Used in OnWrite event handler.

Var IsNew; // Shows whether a new object is being written.
           // Used in OnWrite event handler.

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	IsNew = IsNew();
	
	UsersInternal.StartInfobaseUserProcessing(ThisObject, InfobaseUserProcessingParameters);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If AdditionalProperties.Property("NewUserGroup")
		AND ValueIsFilled(AdditionalProperties.NewUserGroup) Then
		
		DataLock = New DataLock;
		LockItem = DataLock.Add("Catalog.UserGroups");
		LockItem.Mode = DataLockMode.Exclusive;
		DataLock.Lock();
		
		GroupObject = AdditionalProperties.NewUserGroup.GetObject();
		GroupObject.Content.Add().User = Ref;
		GroupObject.Write();
	EndIf;
	
	// Update the content of the "All users" group. This group is always update automatically.
	ItemsToChange    = New Map;
	ModifiedGroups   = New Map;
	
	UsersInternal.UpdateUserGroupContents(
		Catalogs.UserGroups.AllUsers, Ref, ItemsToChange, ModifiedGroups);
	
	UsersInternal.RefreshContentUsingOfUserGroups(
		Ref, ItemsToChange, ModifiedGroups);
	
	UsersInternal.EndInfobaseUserProcessing(
		ThisObject, InfobaseUserProcessingParameters);
	
	UsersInternal.AfterUserGroupContentUpdate(
		ItemsToChange, ModifiedGroups);
	
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
	
	// Infobase user must be deleted, otherwise it will be included in the list of errors of the InfobaseUsers form. In addition, an attempt to log on to the infobase as this user will generate an error.
	
	InfobaseUserDescription = New Structure;
	InfobaseUserDescription.Insert("Action", "Delete");
	AdditionalProperties.Insert("InfobaseUserDescription", InfobaseUserDescription);
	
	UsersInternal.StartInfobaseUserProcessing(ThisObject, InfobaseUserProcessingParameters, True);
	UsersInternal.EndInfobaseUserProcessing(ThisObject, InfobaseUserProcessingParameters);
	
EndProcedure

#EndRegion

#EndIf
