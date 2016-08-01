////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
// Common use server procedures and functions for working with:
// - security profiles.
//
////////////////////////////////////////////////////////////////////////////////

#Region InternalProceduresAndFunctions

// Performs an asynchronous processing of notification of closing external resource
// permissions setup wizard form when the call is executed through an idle handler.
// Passes DialogReturnCode.OK to the idle handler.
//
// The procedure is not intended for direct call.
//
Procedure FinishExternalResourcePermissionSetup() Export
	
	ExternalResourcePermissionSetupClient.SynchronouslyFinishExternalResourcePermissionSetup(DialogReturnCode.OK);
	
EndProcedure

// Performs an asynchronous processing of notification of closing external resource
// permissions setup wizard form when the call is executed through an idle handler.
// Passes DialogReturnCode.Cancel to the idle handler.
//
// The procedure is not intended for direct call.
//
Procedure CancelExternalResourcePermissionSetup() Export
	
	ExternalResourcePermissionSetupClient.SynchronouslyFinishExternalResourcePermissionSetup(DialogReturnCode.Cancel);
	
EndProcedure

#EndRegion