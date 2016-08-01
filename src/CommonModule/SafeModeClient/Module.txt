////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
// Common use server procedures and functions for working with:
// - security profiles.
//
////////////////////////////////////////////////////////////////////////////////

#Region Interface

// Applies saved in the infobase requests for external resource usage.
//
// Parameters:
//  IDs                 - Array (UUID) - IDs of requests to be applied.
//  OwnerForm           - ManagedForm - form to be locked while the procedure is
//                        executed.
//  ClosingNotification - NotifyDescription - to be raised once the permissions are
//                        granted.
//
Procedure ApplyExternalResourceRequests(Val IDs, OwnerForm, ClosingNotification) Export
	
	StandardProcessing = True;
	
	EventHandlers = CommonUseClient.InternalEventHandlers(
		"StandardSubsystems.BaseFunctionality\ExternalResourceRequestsOnProcess");
	
	For Each Handler In EventHandlers Do
		
		Handler.Module.ExternalResourceRequestsOnProcess(IDs, OwnerForm, ClosingNotification, StandardProcessing);
		
		If Not StandardProcessing Then
			Break;
		EndIf;
		
	EndDo;
	
	If StandardProcessing Then
		
		ExternalResourcePermissionSetupClient.StartInitializingRequestForPermissionToUseExternalResources(
			IDs, OwnerForm, ClosingNotification);
		
	EndIf;
	
EndProcedure

// Opens the security profile setup dialog for the current infobase.
//
Procedure OpenSecurityProfileSetupDialog() Export
	
	OpenForm(
		"DataProcessor.ExternalResourcePermissionSetup.Form.SecurityProfileSetup",
		,
		,
		"DataProcessor.ExternalResourcePermissionSetup.Form.SecurityProfileSetup",
		,
		,
		,
		FormWindowOpeningMode.Independent);
	
EndProcedure

#EndRegion
