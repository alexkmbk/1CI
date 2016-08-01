////////////////////////////////////////////////////////////////////////////////
// Users subsystem.
//
////////////////////////////////////////////////////////////////////////////////

#Region Interface

// Returns the current user or the current external user, depending on which one is logged on.
//  It is recommended that you use the function in a script fragment that supports both logon options.
//
// Returns:
//  CatalogRef.Users CatalogRef.ExternalUsers
// 
Function AuthorizedUser() Export
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	SetPrivilegedMode(True);
	
	Return ?(ValueIsFilled(SessionParameters.CurrentUser),
	          SessionParameters.CurrentUser,
	          SessionParameters.CurrentExternalUser);
#Else
	Return StandardSubsystemsClientCached.ClientParametersOnStart().AuthorizedUser;
#EndIf
	
EndFunction

// Returns the current user.
//  It is recommended that you use the function in a script fragment that does not support external users.
//
//  If the current user is external, an exception is raised.
//
// Returns:
//  CatalogRef.Users
//
Function CurrentUser() Export
	
	AuthorizedUser = AuthorizedUser();
	
	If TypeOf(AuthorizedUser) <> Type("CatalogRef.Users") Then
		Raise
			NStr("en = 'Cannot get the current user in the external user session.'");
	EndIf;
	
	Return AuthorizedUser;
	
EndFunction

// Returns the current external user.
//  It is recommended that you use the function in a script fragment that supports external users only.
//
//  If the current user is not external, an exception is raised.
//
// Returns:
//  CatalogRef.ExternalUsers
//
Function CurrentExternalUser() Export
	
	AuthorizedUser = AuthorizedUser();
	
	If TypeOf(AuthorizedUser) <> Type("CatalogRef.ExternalUsers") Then
		Raise
			NStr("en = 'Cannot get the current external user in the user session.'");
	EndIf;
	
	Return AuthorizedUser;
	
EndFunction

// Returns True if the current user is external.
//
// Returns:
//  Boolean - True if the current user is external.
//
Function IsExternalUserSession() Export
	
	Return TypeOf(AuthorizedUser())
	      = Type("CatalogRef.ExternalUsers");
	
EndFunction

#EndRegion
