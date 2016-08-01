////////////////////////////////////////////////////////////////////////////////
// Users subsystem.
//
////////////////////////////////////////////////////////////////////////////////

#Region InternalProceduresAndFunctions

// Checks whether the infobase object is used as the authorization object of any external user
// except the specified external user (provided that the external user is specified).
// 
Function AuthorizationObjectUsed(Val AuthorizationObjectRef,
                                      Val CurrentExternalUserRef = Undefined,
                                      FoundExternalUser = Undefined,
                                      CanAddExternalUser = False,
                                      ErrorText = "") Export
	
	Return UsersInternal.AuthorizationObjectUsed(
				AuthorizationObjectRef,
				CurrentExternalUserRef,
				FoundExternalUser,
				CanAddExternalUser,
				ErrorText);
	
EndFunction

#EndRegion
