////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
// Implementation of application module handlers.
//
////////////////////////////////////////////////////////////////////////////////

#Region Interface

// Is executed before the user starts interactive actions with the data area or with  
// the application in the local mode.
// Corresponds to the BeforeStart handler.
//		
// Parameters:
//  Parameters - Structure - structure with the following properties:
//               Cancel                            - Boolean - return value. If it is
//                                                   set to True, the application is
//                                                   terminated.
//               Restart                           - Boolean - return value. If it is
//                                                   set to True and simultaneously
//                                                   Cancel is True, the application
//                                                   is restarted.
//               AdditionalParametersOfCommandLine - String - return value. Has a
//                                                   point when Cancel and Restart
//                                                   are True.
//               InteractiveHandler                - NotifyDescription - return
//                                                   value. To open the window that
//                                                   locks the application start,
//                                                   pass the notification
//                                                   description handler that opens
//                                                   the window.
//                                                   See the example below.
//               ContinuationHandler               - NotifyDescription - if a window 
//                                                   that locks the application start 
//                                                   is opened, the
//                                                   ContinuationHandler
//                                                   notification must be executed in
//                                                   the close handler of the window.
//                                                   See the example below.
//		
// Example. Opening a window that locks the application start:
//		
// 	If OpenWindowOnStart Then
// 		Parameters.InteractiveHandler = New NotifyDescription("OpenWindow", ThisObject);
// 	EndIf;
//		
// Procedure OpenWindow(Parameters, AdditionalParameters) Export
// 	// Showing the window, closing which leads to calling the OpenWindowCompletion
// 	// notification handler.
// 		Notification = New NotifyDescription("OpenWindowCompletion",  ThisObject, Parameters);
// 	Form = OpenForm(... ,,, ...  Notification);
// 	If Not Form.IsOpen() Then //  If OnCreateAtServer Cancel is True.
// 		ExecuteNotifyProcessing(Parameters.ContinuationHandler);
// 	EndIf;
// EndProcedure
//		
// Procedure  OpenWindowCompletion(Result, Parameters) Export
// 	...
// 	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
//		
// EndProcedure
//
Procedure BeforeStart(Parameters) Export
	
EndProcedure

// Is executed during the user starts interactive actions with the data area or with
// the application in the local mode.
// Corresponds to the OnStart handler.
//
// Parameters:
//  Parameters - Structure - structure with the following properties:
//               Cancel                            - Boolean - return value. If it is
//                                                   set to True, the application is
//                                                   terminated.
//               Restart                           - Boolean - return value. If it is
//                                                   set to True and simultaneously
//                                                   Cancel is True, the application
//                                                   is restarted.
//               AdditionalParametersOfCommandLine - String - return value. Has a
//                                                   point when Cancel and Restart
//                                                   are True.
//               InteractiveHandler                - NotifyDescription - return
//                                                   value. To open the window that
//                                                   locks the application start, pass
//                                                   the notification description 
//                                                   handler that opens the window.
//                                                   For details see the example of 
//                                                   the BeforeStart() handler.
//               ContinuationHandler               - NotifyDescription - if a window 
//                                                   that locks the application start
//                                                   is opened, the
//                                                   ContinuationHandler
//                                                   notification must be executed in
//                                                   the close handler of the window.
//                                                   For details see the example of 
//                                                   the BeforeStart() handler.
//
Procedure OnStart(Parameters) Export
	
	// _Demo start example
	//RunParameters = StandardSubsystemsClientCached.ClientParametersOnStart();
	//If RunParameters.DataSeparationEnabled And Not RunParameters.CanUseSeparatedData Then
	//	Return;
	//EndIf;
	//
	//SuggestOpenWebSiteOnStart = RunParameters.SuggestOpenWebSiteOnStart;
	//If SuggestOpenWebSiteOnStart Then
	//	Parameters.InteractiveHandler = New NotifyDescription("SuggestOpenWebSiteOnStart", _DemoStandardSubsystemsClient);
	//EndIf;
	// _Demo end example

EndProcedure

// Handles application launch parameters.
// One can expand the function implementation for processing new parameters.
//
// Parameters:
//  LaunchParameterValue - String - first launch parameter value, until the first
//                         semicolons (;) character.
//  LaunchParameters     - String - launch parameter passed to the configuration
//                         using the /C command line key.
//  Cancel               - Boolean - return value. If it is set True, the execution
//                         of the OnStart procedure is interrupted.
//
Procedure LaunchParametersOnProcess(LaunchParameterValue, LaunchParameters, Cancel) Export

EndProcedure

// Is executed before the user starts interactive actions with the data area or with
// the application in the local mode.
// Is called after the OnStart handler.
// Used for attaching the idle handlers, that must be skipped in case of interactive 
// actions before or during the system start.
//
// Interactions with users are prohibited.
//
Procedure AfterStart() Export
	
EndProcedure

// Is executed before the user logged off from the data area or exits the application
// in the local mode.
//
// Corresponds to the BeforeExit handler.
//
// Parameters:
//  Parameters - Structure - structure with the following properties:
//               Cancel                - Boolean - return value. If it is set to 
//                                       True, the application termination is 
//                                       canceled.
//               InteractiveHandler    - NotifyDescription - return value. To open  
//                                       the window that locks the application
//                                       termination, pass the notification
//                                       description handler that opens the window.
//                                       For details see the example of the 
//                                       BeforeStart() handler.
//               ContinuationHandler   - NotifyDescription - if a window that locks
//                                       the application termination is opened, the
//                                       ContinuationHandler notification must be
//                                       executed in the close handler of the window.
//                                       For details see the example of the 
//                                       BeforeStart() handler.
//
Procedure BeforeExit(Parameters) Export
	
EndProcedure

// Overrides the application caption.
//
// Parameters:
//  ApplicationPresentation - String - application caption text;
//  OnStart            - Boolean - True if the procedure is called during the
//                       application start.
Procedure ClientApplicationPresentationOnSet(ApplicationPresentation, OnStart) Export
	
EndProcedure
 
#EndRegion