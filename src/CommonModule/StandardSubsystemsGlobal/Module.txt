////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
//
////////////////////////////////////////////////////////////////////////////////

#Region InternalProceduresAndFunctions

// Continues exiting the application in interaction with a user when Cancel is set to True.
//
Procedure BeforeExitInteractiveHandlerIdleHandler() Export
	
	StandardSubsystemsClient.StartBeforeExitInteractiveHandler();
	
EndProcedure

// Continues starting the application in interaction with a user.
Procedure OnStartIdleHandler() Export
	
	StandardSubsystemsClient.OnStart(, False);
	
EndProcedure

#EndRegion
