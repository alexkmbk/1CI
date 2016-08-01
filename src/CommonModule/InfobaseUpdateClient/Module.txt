////////////////////////////////////////////////////////////////////////////////
// Infobase update subsystem 
// Client procedures and functions for interactive infobase update
//
//////////////////////////////////////////////////////////////////////////////
#Region InternalProceduresAndFunctions

// See the description of OnClientStart parameter of
// ExecuteInfobaseUpdate function in the InfobaseUpdate module.
//
Procedure UpdateInfobase(Parameters) Export
	
	ClientParameters = StandardSubsystemsClientCached.ClientParametersOnStart();
	If Not ClientParameters.CanUseSeparatedData Then
		CloseUpdateProgressIndicationFormIfOpen(Parameters);
		Return;
	EndIf;
	
	If ClientParameters.Property("InfobaseUpdateRequired") Then
		Parameters.InteractiveHandler = New NotifyDescription(
			"StartInfobaseUpdate", ThisObject);
	Else
		If ClientParameters.Property("LoadDataExchangeMessage") Then
			Restart = False;
			InfobaseUpdateServerCall.ExecuteInfobaseUpdate(, True, Restart);
			If Restart Then
				Parameters.Cancel = True;
				Parameters.Restart = True;
			EndIf;
		EndIf;
		CloseUpdateProgressIndicationFormIfOpen(Parameters);
	EndIf;
	
EndProcedure

// For the InfobaseUpdate procedure. 
Procedure CloseUpdateProgressIndicationFormIfOpen(Parameters)
	
	If Parameters.Property("InfobaseUpdateProgressIndicatorForm") Then
		If Parameters.InfobaseUpdateProgressIndicatorForm.IsOpen() Then
			Parameters.InfobaseUpdateProgressIndicatorForm.StartClosing();
		EndIf;
		Parameters.Delete("InfobaseUpdateProgressIndicatorForm");
	EndIf;
	
EndProcedure

// For internal use only. Continues the execution of InfobaseUpdate procedure.
Procedure StartInfobaseUpdate(Parameters, ContinuationHandler) Export
	
	If Parameters.Property("InfobaseUpdateProgressIndicatorForm") Then
		Form = Parameters.InfobaseUpdateProgressIndicatorForm;
	Else
		FormName = "DataProcessor.InfobaseUpdate.Form.InfobaseUpdateProgressIndicator";
		
		Form = OpenForm(FormName,,,,,, New NotifyDescription(
			"AfterInfobaseUpdateProgressIndicatorFormClose", ThisObject, Parameters));
		
		Parameters.Insert("InfobaseUpdateProgressIndicatorForm", Form);
	EndIf;
	
	Form.UpdateInfobase();
	
EndProcedure

// For internal use only. Continues the execution of BeforeApplicationStart procedure.
Procedure ImportUpdateApplicationParameters(Parameters, NotDefined) Export
	FormName = "DataProcessor.InfobaseUpdate.Form.InfobaseUpdateProgressIndicator";
	
	Form = OpenForm(FormName,,,,,, New NotifyDescription(
		"AfterInfobaseUpdateProgressIndicatorFormClose", ThisObject, Parameters));
	
	Parameters.Insert("InfobaseUpdateProgressIndicatorForm", Form);
	
	Form.ImportUpdateApplicationParameters(Parameters);
	
EndProcedure

// For internal use only. Continues the execution of InfobaseUpdate procedure.
Procedure AfterInfobaseUpdateProgressIndicatorFormClose(Result, Parameters) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		Result = New Structure("Cancel, Restart", True, False);
	EndIf;
	
	If Result.Cancel Then
		Parameters.Cancel = True;
		If Result.Restart Then
			Parameters.Restart = True;
		EndIf;
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure

// If there are update details that were not shown and the user did not disable showing details, opens the ApplicationReleaseNotes form.
//
Procedure ShowUpdateDetails()
	
	ClientParameters = StandardSubsystemsClientCached.ClientParametersOnStart();
	If ClientParameters.ShowApplicationReleaseNotes Then
		
		FormParameters = New Structure;
		FormParameters.Insert("ShowOnlyChanges", True);
		
		OpenForm("CommonForm.ApplicationReleaseNotes", FormParameters);
	EndIf;
	
EndProcedure

// Notifies the user that the deferred data processing is not executed.
//
Procedure NotifyDeferredHandlersNotExecuted() Export
	
	ShowUserNotification(
		NStr("en = 'The application functionality is temporary limited'"),
		DataProcessorURL(),
		NStr("en = 'Migration to the new version is still in progress'"),
		PictureLib.Warning32);
	
EndProcedure

// Returns the URL of InfobaseUpdate data processor.
//
Function DataProcessorURL()
	Return "e1cib/app/DataProcessor.InfobaseUpdate";
EndFunction

// The procedure is executed when a user accesses a data area interactively or starts the application in the local mode.

// It is called after OnStart handler execution.
// Attaches the idle handlers that are only required after OnStart.
// 
Procedure AfterStart() Export
	
	ClientParameters = StandardSubsystemsClientCached.ClientParametersOnStart();
	
	If ClientParameters.Property("ShowMessageAboutErrorHandlers")
		OR ClientParameters.Property("ShowNotExecutedHandlersNotification") Then
		AttachIdleHandler("CheckDeferredUpdateStatus", 2, True);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// SL event handlers

// The procedure is called before a user accesses a data area interactively.
// Corresponds to BeforeStart events described in the application modules. 
//
Procedure BeforeStart(Parameters) Export
	
	ClientParameters = StandardSubsystemsClientCached.ClientParametersOnStart();
	
	If ClientParameters.Property("InfobaseLockedForUpdate") Then
		Parameters.Cancel = True;
		Parameters.InteractiveHandler = New NotifyDescription(
			"ShowMessageBoxAndContinue",
			StandardSubsystemsClient.ThisObject,
			ClientParameters.InfobaseLockedForUpdate);
		
	ElsIf ClientParameters.Property("ApplicationParametersUpdateRequired") Then
		Parameters.InteractiveHandler = New NotifyDescription(
			"ImportUpdateApplicationParameters", ThisObject, Parameters);
		
	ElsIf Find(Lower(LaunchParameter), Lower("RegisterFullMOIDChangeForSubordinateDIBNodes")) > 0 Then
		Parameters.Cancel = True;
		Parameters.InteractiveHandler = New NotifyDescription(
			"ShowMessageBoxAndContinue",
			StandardSubsystemsClient.ThisObject,
			NStr("en = 'RegisterFullMOIDChangeForSubordinateDIBNodes startup parameter can be used only with the StartInfobaseUpdate paremeter.'"));
	EndIf;
	
EndProcedure

// The procedure is called before a user accesses a data area interactively.
// Corresponds to OnStart events described in the application modules.
//
Procedure OnStart(Parameters) Export
	
	ClientParameters = StandardSubsystemsClientCached.ClientParametersOnStart();
	If Not ClientParameters.CanUseSeparatedData Then
		Return;
	EndIf;
	
	ShowUpdateDetails();
	
EndProcedure

#EndRegion
