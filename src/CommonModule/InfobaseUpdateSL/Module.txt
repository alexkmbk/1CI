////////////////////////////////////////////////////////////////////////////////
// Subsystems library (SL) infobase update.
//
////////////////////////////////////////////////////////////////////////////////

#Region Interface

////////////////////////////////////////////////////////////////////////////////
// Additional information about the library or configuration.

// Fills the general information about the library or base configuration.
// The library that has the same name as the base configuration name in the metadata is considered base configuration.
// 
// Parameters:
//  Details - Structure - additional information about the library:
//
//   * Name               - String - library name, for example, "StandardSubsystems".
//   * Version            - String - version in the 4-digit format, for example, "2.1.3.1".
//
//   * RequiredSubSystems - Array - names of the other libraries (String) that the current library depends on.
//                                  Update handlers of such libraries should be
//                                  called earlier than update handlers of the current library.
//                                  If they have cyclic dependencies or, on the contrary,
//                                  no dependencies, the update handlers call order is
//                                  determined by the order of added modules in the
//                                  OnAddSubsystems procedure of the
//                                  ConfigurationSubsystemsOverridable common module.
//
Procedure OnAddSubsystem(Details) Export
	
	Details.Name    = "StandardSubsystems";
	Details.Version = "2.2.4.1";
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Infobase update handlers.

// Adds infobase data update handlers for all supported versions of the library or configuration to the list.
// The procedure is called before the beginning of infobase data update to build the update plan.
//
//  Handlers - ValueTable - fields description,
//                see the InfobaseUpdate.NewUpdateHandlerTable procedure.
//
// Example of adding the handler procedure to the list:
//  Handler = Handlers.Add();
//  Handler.Version       = "1.1.0.0";
//  Handler.Procedure     = "InfobaseUpdate. MigrateToVervion_1_1_0_0";
//  Handler.ExecutionMode = "Exclusive";
//
Procedure OnAddUpdateHandlers(Handlers) Export
	
	// Handlers of this event for SL subsystems are added inside a subscription to the following internal event:
	// "StandardSubsystems.InfobaseVersionUpdate\OnAddUpdateHandlers".
	//
	// Procedures for handling this event in all SL subsystems have the same name
	// as this procedure but they are located in respective subsystems.
	// To find the procedures, you can perform global search by procedure name.
	// To find the modules that store the procedures, you can search by event name.
	
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.InfobaseVersionUpdate\OnAddUpdateHandlers");
	
	For Each Handler In EventHandlers Do
		If Handler.Subsystem <> "StandardSubsystems" Then
			Continue;
		EndIf;
		Handler.Module.OnAddUpdateHandlers(Handlers);
	EndDo;
	
EndProcedure

// The procedure is called before the infobase data update handler procedures.
//
Procedure InfobaseBeforeUpdate() Export
	
	// Handlers of this event for SL subsystems are added inside a subscription to the following internal event:
	// "StandardSubsystems.InfobaseVersionUpdate\BeforeInfobaseUpdate".
	//
	// Procedures for handling this event in all SL subsystems have the same name
	// as this procedure but they are located in respective subsystems.
	// To find the procedures, you can perform global search by procedure name.
	// To find the modules that store the procedures, you can search by event name.
	
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.InfobaseVersionUpdate\InfobaseBeforeUpdate");
	
	For Each Handler In EventHandlers Do
		If Handler.Subsystem <> "StandardSubsystems" Then
			Continue;
		EndIf;
		Handler.Module.InfobaseBeforeUpdate();
	EndDo;
	
EndProcedure

// The procedure is called after the infobase data is updated.
//		
// Parameters:
//   PreviousVersion   - String - version before update. It contains "0.0.0.0" for an empty infobase.
//   CurrentVersion    - String - version after update.
//   ExecutedHandlers  - ValueTree - the list of executed handlers grouped by version number.
//   ShowUpdateDetails - Boolean - if True, the update description form is displayed. The
//                       default value is True. It is the return value.
//   ExclusiveMode     - Boolean - flag specifying whether the update was performed in exclusive mode.
//		
// Example of iteration through executed update handlers:
//		
// For Each Version In ExecutedHandlers.Rows Do
//		
// 	If Version.Version = "*" Then 
//  // Handler that is executed with each version change.
// 	Else 
//  // Handler that is executed for a certain version.
// 	EndIf;
//		
// 	For Each Handler In Version.Rows Do 
// 		...
// 	EndDo;
//		
// EndDo;
//
Procedure AfterInfobaseUpdate(Val PreviousVersion, Val CurrentVersion,
		Val ExecutedHandlers, ShowUpdateDetails, ExclusiveMode) Export
	
	// Calling handlers of the AfterInfobseUpdate internal event.
	// To find the handlers, you can use global search by event name.
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.InfobaseVersionUpdate\AfterInfobaseUpdate");
	
	For Each Handler In EventHandlers Do
		If Handler.Subsystem <> "StandardSubsystems" Then
			Continue;
		EndIf;
		Handler.Module.AfterInfobaseUpdate(PreviousVersion, CurrentVersion,
			ExecutedHandlers, ShowUpdateDetails, ExclusiveMode);
	EndDo;
	
EndProcedure

// Called when preparing the spreadsheet document with the application update list.
//
// Parameters:
//   Template - SpreadsheetDocument - The list of updates in all libraries and configuration.
//              Template can be supplemented or replaced.
//              See also the UpdateDetails common template.
//
Procedure OnPrepareUpdateDetailsTemplate(Val Template) Export
	
EndProcedure

#EndRegion
