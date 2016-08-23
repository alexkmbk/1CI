////////////////////////////////////////////////////////////////////////////////
// Infobase version update subsystem
//
////////////////////////////////////////////////////////////////////////////////

#Region Interface

// Called prior to the infobase data update handlers.
//
Procedure InfobaseBeforeUpdate() Export
	
EndProcedure

// Called after infobase data update.
// 
// Parameters:
//   PreviousInfobaseVersion      - String - infobase version before update, 
//                                  or "0.0.0.0" for an empty infobase.
//   CurrentInfobaseVersion       - String - infobase version after update.
//   ExecutedHandlers - ValueTree - The list of executed handlers grouped by 
//                                  version number.
//  Iteration through completed handlers:
// 	For Each Version In CompletedHandlers.Rows Do
//	
// 	 If Version.Version = "*" Then
// 		  a group of handlers that are always executed	
// 	 Else 
// 		  a group of handlers that are executed for a specific version 
//	  EndIf;
//
// 		For Each Handler In Version.Rows Do 
// 			...
// 		EndDo;
//	
// 	EndDo;
//
//   ShowUpdateDetails - Boolean - if True, the update details form is displayed.
//   ExclusiveMode     - Boolean - flag specifying whether the update was performed in exclusive mode.
//                                 True if the update was performed in exclusive mode.
// 
Procedure AfterInfobaseUpdate(Val PreviousInfobaseVersion, Val CurrentInfobaseVersion,
	Val ExecutedHandlers, ShowUpdateDetails, ExclusiveMode) Export
	
EndProcedure

// Called when preparing a spreadsheet document with the application update details.
//   
// Parameters:
//   Template - SpreadsheetDocument - update details.
//   
// See also: ApplicationReleaseNotes common template.
//
Procedure OnPrepareUpdateDetailsTemplate(Val Template) Export
	
EndProcedure

// Called to get the list of the update handlers that should not be executed.
// You can only disable (detach) update handlers with "*" version number.
//
// Example of adding a detachable handler to the list:
//   NewException = Add DetachableHandlers.Add();
//   NewException.LibraryID = "StandardSubsystems";
//   NewExсeption.Version = "*";
//   NewException.Procedure = "ReportOptions.Update";
//
// Version - version number of the configuration where you want to disable the handler execution.
//
Procedure AddDetachableUpdateHandlers(DetachableHandlers) Export
	
EndProcedure

// Overrides the hint text that indicates the path to the "Application change log" form.
//
// Parameters:
//  HintText - String, hint text.
//
Procedure GetApplicationUpdateResultDetailsText(HintText) Export
	
EndProcedure

// Obsolete. Use OnAddSubsystems procedure of ConfigurationSubsystemsOverridable common module instead.
//
// The procedure is called prior to infobase data update.
// Returns the list of infobase update handlers for all supported infobase versions.
//
// Example of adding a handler procedure to the list:
//    Handler = Handlers.Add();
//    Handler.Version = "1.1.0.0";
//    Handler.Procedure = "InfobaseUpdate.GoToVersion_1_1_0_0";
//
// Returns:
//   ValueTable - column content, see in InfobaseUpdate.NewUpdateHandlerTable.
//
Function UpdateHandlers() Export
	
	Handlers = InfobaseUpdate.NewUpdateHandlerTable();
	
	// Attaching configuration update handlers
	
	Return Handlers;
	
EndFunction

#EndRegion
