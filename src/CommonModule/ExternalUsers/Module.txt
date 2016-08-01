////////////////////////////////////////////////////////////////////////////////
// Users subsystem.
//
////////////////////////////////////////////////////////////////////////////////

#Region Interface

// Returns a flag that shows whether external users are enabled  in the application (the
// UseExternalUsers functional option value).
//
// Returns:
//  Boolean - True if external users are enabled.
//
Function UseExternalUsers() Export
	
	Return GetFunctionalOption("UseExternalUsers");
	
EndFunction

// See the function with the same name in the UsersClientServer common module.
Function CurrentExternalUser() Export
	
	Return UsersClientServer.CurrentExternalUser();
	
EndFunction

// Returns a reference to the external user authorization object retrieved from the infobase.
// Authorization object is a reference to an infobase object (for example, a counterparty or an individual) 
// that is associated an external user.
//
// Parameters:
//  ExternalUser - Undefined - current external user.
//               - CatalogRef.ExternalUsers - specified external user.
//
// Returns:
//  Ref - authorization object of a type specified in the type description of the 
//        Metadata.Catalogs.ExternalUsers.Attributes.AuthorizationObjects.Type property.
//
Function GetExternalUserAuthorizationObject(ExternalUser = Undefined) Export
	
	If ExternalUser = Undefined Then
		ExternalUser = UsersClientServer.CurrentExternalUser();
	EndIf;
	
	AuthorizationObject = CommonUse.ObjectAttributeValues(ExternalUser, "AuthorizationObject").AuthorizationObject;
	
	If ValueIsFilled(AuthorizationObject) Then
		If UsersInternal.AuthorizationObjectUsed(AuthorizationObject, ExternalUser) Then
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Database error:
				           |Authorization object %1 (%2) is associated with multiple external users.'"),
				AuthorizationObject,
				TypeOf(AuthorizationObject));
		EndIf;
	Else
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Database error:
			           |Authorization object is not set for external user %1.'"),
			ExternalUser);
	EndIf;
	
	Return AuthorizationObject;
	
EndFunction

#EndRegion
