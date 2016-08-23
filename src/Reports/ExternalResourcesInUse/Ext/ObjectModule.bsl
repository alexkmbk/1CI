#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ObjectEventHandlers

// Defines settings of the "Report options" subsystem common report form.
//
// Parameters:
//   Form      - ManagedForm - report form.
//   OptionKey - String - predefined report option name or UUID of a custom one.
//   Settings  - Structure - see the return value of 
//               ReportFunctionsClientServer.GetDefaultReportSettings().
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.GenerateDirectly = True;
	Settings.ShowSelectedCellsAmount = False;
	
EndProcedure

// Is called when the report is created with the ComposeResult() method.
//
// Parameters:
//  ResultDocument     - SpreadsheetDocument - document where the result is output.
//  DetailsData        - Arbitrary - details data must be passed to this parameter.
//  StandardProcessing - Boolean - flag that shows whether the standard (system) 
//                       event processing is performed.
//
Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	ResultDocument.Clear();
	
	BeginTransaction();
	
	Constants.UseSecurityProfiles.Set(True);
	Constants.AutomaticallySetUpPermissionsInSecurityProfiles.Set(True);
	
	DataProcessors.ExternalResourcePermissionSetup.ClearPermissions();
	
	PermissionRequests = SafeModeInternal.RequestsToUpdateConfigurationPermissions();
	
	AdministrationOperations = DataProcessors.ExternalResourcePermissionSetup.AdministrationActionsInRequests(PermissionRequests);
	Delta = DataProcessors.ExternalResourcePermissionSetup.ExternalResourcePermissionChangeDelta(PermissionRequests);
	
	RollbackTransaction();
	
	Reports.ExternalResourcesInUse.FillExternalResourceRequestResultPresentation(
		ResultDocument, AdministrationOperations, Delta, True);
	
EndProcedure

#EndRegion

#EndIf
