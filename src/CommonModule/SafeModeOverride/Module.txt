////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
//
////////////////////////////////////////////////////////////////////////////////

#Region Interface

// Is called when verification whether security profiles can be used is performed.
//
// Parameters:
//  Cancel - Boolean - if the applied solution is not adapted to use security
//           profiles, set this return parameter to True.
//
Procedure CanUseSecurityProfilesOnCheck(Cancel) Export
	
	
	
EndProcedure

// Is called once security profiles for the infobase is enabled.
//
Procedure SecurityProfilesOnEnable() Export
	
	
	
EndProcedure

// Fills the list of requests for external permissions that must be provided the
// Infobase is being created or the application is being updated.
//
// Parameters:
//  PermissionRequests - Array - returned by SafeMode.RequestToUseExternalResources().
//
Procedure OnFillPermissionsToAccessExternalResources(PermissionRequests) Export
	
	
	
EndProcedure

#EndRegion