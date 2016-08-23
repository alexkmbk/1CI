////////////////////////////////////////////////////////////////////////////////
// Infobase version update subsystem.
//
////////////////////////////////////////////////////////////////////////////////

#Region InternalProceduresAndFunctions

// Checks deferred update status. If the update has been completed 
// with errors, notifies user and administrator.
//
Procedure CheckDeferredUpdateStatus() Export
	
	ClientParameters = StandardSubsystemsClientCached.ClientParametersOnStart();
	
	If ClientParameters.Property("ShowMessageAboutErrorHandlers") Then
		OpenForm("DataProcessor.InfobaseUpdate.Form.DeferredInfobaseUpdateProgressIndicator");
	Else
		InfobaseUpdateClient.NotifyDeferredHandlersNotExecuted();
	EndIf;
	
EndProcedure

#EndRegion
