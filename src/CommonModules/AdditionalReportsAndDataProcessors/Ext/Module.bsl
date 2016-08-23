////////////////////////////////////////////////////////////////////////////////
// Additional reports and data processors subsystem
//
////////////////////////////////////////////////////////////////////////////////

#Region Interface

// Attaches an external report (data processor) and returns the name used.
//   Once a report (data processor) is attached, it is registered in the application under a name 
//   that can be further used to create an object or open a report (data processor) form.
//
// Parameters:
//   Ref - CatalogRef.AdditionalReportsAndDataProcessors - Attachable data processor.
//
// Returns: 
//   * String    - name of the attached report (data processor).
//   * Undefined - used if an invalid reference is passed.
//
// Important:
//   The UseAdditionalReportsAndDataProcessors functional option check must be performed in a caller script.
//
Function AttachExternalDataProcessor(Ref) Export
	
	StandardProcessing = True;
	Result = Undefined;
	
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.AdditionalReportsAndDataProcessors\OnAttachExternalDataProcessor");
	
	For Each Handler In EventHandlers Do
		
		Handler.Module.OnAttachExternalDataProcessor(Ref, StandardProcessing, Result);
		
		If Not StandardProcessing Then
			Return Result;
		EndIf;
		
	EndDo;
	
	// Validating the passed parameters
	If TypeOf(Ref) <> Type("CatalogRef.AdditionalReportsAndDataProcessors") 
		Or Ref = Catalogs.AdditionalReportsAndDataProcessors.EmptyRef() Then
		Return Undefined;
	EndIf;
	
	// Attaching
	#If ThickClientOrdinaryApplication Then
		DataProcessorName = GetTempFileName();
		DataProcessorStorage = CommonUse.ObjectAttributeValue(Ref, "DataProcessorStorage");
		BinaryData = DataProcessorStorage.Get();
		BinaryData.Write(DataProcessorName);
		Return DataProcessorName;
	#EndIf
	
	Kind = CommonUse.ObjectAttributeValue(Ref, "Kind");
	If Kind = Enums.AdditionalReportAndDataProcessorKinds.Report
		Or Kind = Enums.AdditionalReportAndDataProcessorKinds.AdditionalReport Then
		Manager = ExternalReports;
	Else
		Manager = ExternalDataProcessors;
	EndIf;
	
	LaunchParameters = CommonUse.ObjectAttributeValues(Ref, "SafeMode, DataProcessorStorage");
	AddressInTempStorage = PutToTempStorage(LaunchParameters.DataProcessorStorage.Get());
	
	If GetFunctionalOption("UseSecurityProfiles") Then
		
		SafeMode = SafeModeInternal.ExternalModuleAttachingMode(Ref);
		
		If SafeMode = Undefined Then
			SafeMode = True;
		EndIf;
		
	Else
		
		PermissionsQuery = New Query(
			"SELECT TOP 1
			|	AdditionalReportAndDataProcessorPermissions.LineNumber,
			|	AdditionalReportAndDataProcessorPermissions.PermissionKind
			|FROM
			|	Catalog.AdditionalReportsAndDataProcessors.Permissions AS AdditionalReportAndDataProcessorPermissions
			|WHERE
			|	AdditionalReportAndDataProcessorPermissions.Ref = &Ref");
		PermissionsQuery.SetParameter("Ref", Ref);
		HasPermissions = Not PermissionsQuery.Execute().IsEmpty();
		
		CompatibilityMode = CommonUse.ObjectAttributeValue(Ref, "PermissionCompatibilityMode");
		If CompatibilityMode = Enums.AdditionalReportsAndDataProcessorsPermissionCompatibilityModes.Version_2_2_2 Then
			SafeModeFalg = Not HasPermissions;
		Else
			SafeModeFalg = LaunchParameters.SafeMode;
		EndIf;
		
	EndIf;
	
	WriteComment(Ref, NStr("en = 'Connection, SafeMode = ""%1"".'"), SafeModeFalg);
	
	DataProcessorName = Manager.Connect(AddressInTempStorage, , SafeModeFalg);
	
	Return DataProcessorName;
	
EndFunction

// Returns an external report or data processor object.
//
// Parameters:
//   Ref - CatalogRef.AdditionalReportsAndDataProcessors - attachable report or data processor.
//
// Returns: 
//   * ExternalDataProcessorObject - attached data processor object.
//   * ExternalReportObject        - attached report object.
//   * Undefined                   - used if an invalid reference is passed.
//
// Important:
//   The UseAdditionalReportsAndDataProcessors functional option check must be performed in a caller script.
//
Function GetExternalDataProcessorsObject(Ref) Export
	
	StandardProcessing = True;
	Result = Undefined;
	
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.AdditionalReportsAndDataProcessors\OnCreateExternalDataProcessor");
	
	For Each Handler In EventHandlers Do
		
		Handler.Module.OnCreateExternalDataProcessor(Ref, StandardProcessing, Result);
		
		If Not StandardProcessing Then
			Return Result;
		EndIf;
		
	EndDo;
	
	// Attaching
	DataProcessorName = AttachExternalDataProcessor(Ref);
	
	// Validating the passed parameters
	If DataProcessorName = Undefined Then
		Return Undefined;
	EndIf;
	
	// Getting an object instance
	If Ref.Kind = Enums.AdditionalReportAndDataProcessorKinds.Report
		Or Ref.Kind = Enums.AdditionalReportAndDataProcessorKinds.AdditionalReport Then
		Manager = ExternalReports;
	Else
		Manager = ExternalDataProcessors;
	EndIf;
	
	Return Manager.Create(DataProcessorName);
	
EndFunction

// Setting parameters for functional options of the form
//   (required to generate the form command interface)
//
// Parameters:
//   Form     - ManagedForm
//   FormType - String - Optional. ListForm is used for list forms, and ObjectForm for item forms.
//                       See also ListFormType() and ObjectFormType() functions in the 
//                       AdditionalReportsAndDataProcessorsClientServer common module.
//
Procedure OnCreateAtServer(Form, FormType = Undefined) Export
	If Not GetFunctionalOption("UseAdditionalReportsAndDataProcessors") Then
		Return;
	EndIf;
	
	// Setting form parameters for commands used to call additional reports or data processors
	Parameters = AdditionalReportsAndDataProcessorsCached.AssignedObjectFormParameters(Form.FormName, FormType);
	If TypeOf(Parameters) <> Type("FixedStructure") Then
		Return;
	EndIf;
	
	FunctionalOptionParameters = New Structure;
	FunctionalOptionParameters.Insert("AdditionalReportsAndDataProcessorsTargetObject", Parameters.ParentRef);
	FunctionalOptionParameters.Insert("AdditionalReportsAndDataProcessorsFormType",         ?(FormType = Undefined, Parameters.FormType, FormType));
	
	Form.SetFormFunctionalOptionParameters(FunctionalOptionParameters);
	
	If Parameters.OutputObjectFillingSubmenu Then
		CreateFillingCommandsSubmenu(Form, Parameters);
	EndIf;
	
EndProcedure

// Generates a print form based on external source.
//
// Parameters:
//   Ref (CatalogRef.AdditionalReportsAndDataProcessors) - external data processor.
//   SourceParameters - Structure:
//       * CommandID - String - Template list (comma-separated).
//       * TargetObjects (Array).
//   PrintFormCollection - ValueTable  - see Print() procedure description available in the documentation.
//   PrintObjects        - (ValueList) - see Print() procedure description available in the documentation.
//   OutputParameters    - Structure   - see Print() procedure description available in the documentation.
//
Procedure PrintByExternalSource(Ref, SourceParameters, PrintFormCollection,
	PrintObjects, OutputParameters) Export
	
	// CI >
	//If Not GetFunctionalOption("UseAdditionalReportsAndDataProcessors") Then
	//	Return;
	//EndIf;
	//
	//PrintFormCollection = PrintManagement.PreparePrintFormCollection(SourceParameters.CommandID);
	//
	//OutputParameters = PrintManagement.PrepareOutputParametersStructure();
	//
	//PrintObjects = New ValueList;
	//
	//ExternalDataProcessorObject = GetExternalDataProcessorsObject(Ref);
	//
	//If ExternalDataProcessorObject = Undefined Then
	//	Raise StringFunctionsClientServer.SubstituteParametersInString(
	//		NStr("en = 'External data processor ""%1"" (type %2) is not supported by the Additional reports and data processors subsystem'"),
	//		String(Ref),
	//		String(TypeOf(Ref)));
	//EndIf;
	//
	//ExternalDataProcessorObject.Print(
	//	SourceParameters.TargetObjects,
	//	PrintFormCollection,
	//	PrintObjects,
	//	OutputParameters);
	//
	//// Checking if all templates are generated
	//For Each Str In PrintFormCollection Do
	//	If Str.SpreadsheetDocument = Undefined Then
	//		ErrorMessageText = StringFunctionsClientServer.SubstituteParametersInString(
	//			NStr("en = 'Spreadsheet document is not generated in the print handler for: %1'"),
	//			Str.TemplateName);
	//		Raise(ErrorMessageText);
	//	EndIf;
	//	
	//	Str.SpreadsheetDocument.Copies = Str.Copies;
	//EndDo;
// CI <
EndProcedure

// Generates a template for external report or data processor information structure, 
// to be filled at a later time.
//
// Parameters:
//   SLVersion - String - Version of the standard subsystem library expected by the external object mechanisms.
//                        For details, see StandardSubsystemsServer.LibraryVersion().
//
// Returns: 
//   RegistrationParameters - Structure - External object parameters.
//       * Kind - String - External object kind. Corresponds to the Kind attribute 
//           (EnumRef.AdditionalReportAndDataProcessorKinds).
//           You can determine the kind by using the Kind* functions located 
//           in the AdditionalReportsAndDataProcessorsClientServer common module, or specify it explicitly:
//           ** "PrintForm"
//           ** "ObjectFilling"
//           ** "RelatedObjectCreation"
//           ** "Report"
//           ** "AdditionalDataProcessor"
//           ** "AdditionalReport"
//       * Version - String - Object version.
//           Conforms to "<senior number>.<junior number>" format.
//       * Purpose - Array of strings - Optional. Names of configuration objects for which this object is intended.
//           Conforms to "<MetadataObjectClassName>.[*|<MetadataObjectName>]" format. 
//       * Description - String - Optional. Presentation for administrator (catalog item name).
//           If empty, presentation of metadata object of the external object is used.
//       * SafeMode - Boolean - Optional. Flag specifying whether the external data processor is attached in safe mode.
//           True by default (data processor runs in safe mode).
//           For details, see ExternalReportsManager.Connect and ExternalDataProcessorsManager.Connect help sections.
//       * Information - String - Optional. Brief information on external object.
//           This parameter should be used by the administrator to enter a description of the external object functionality.
//           If empty, a comment from the metadata object of the external object is used.
//       * SLVersion - String - Optional. Library version expected by the external object mechanisms.
//           For details, see StandardSubsystemsServer.LibVersion().
//       * Commands - ValueTable - Optional for reports. Table of commands provided by the external object.
//           Column types correspond to the types found in the Commands tabular section of the AdditionalReportsAndDataProcessors catalog.
//           ** ID - String - Command name. For print forms, a template list is used.
//           ** Use - String - Command type. Corresponds to the RunningVariant attribute (EnumRef.AdditionalDataProcessorCallMethods).
//               *** "ClientMethodCall"
//               *** "ServerMethodCall"
//               *** "FormFilling"
//               *** "FormOpening"
//               *** "ScenarioInSafeMode"
//           ** Presentation - String - Command presentation for the end user.
//           ** ShowNotification - Boolean - if True, a standard notification is displayed at command start.
//               Not available for "FormOpening" commands.
//           ** Modifier - String - Auxiliary modifier command.
//               *** "PrintMXL" is used for print forms based on MXL templates.
//           ** Hide - Boolean - if True, the command must be hidden from the item form.
//       * Permissions - Array of XDTODataObject {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}PermissionBase -
//           Optional. Arrays of permissions granted to the additional report (data processor)
//           while running in safe mode.
//
Function ExternalDataProcessorInfo(SLVersion = "") Export
	RegistrationParameters = New Structure;
	
	RegistrationParameters.Insert("Kind", "");
	RegistrationParameters.Insert("Version", "0.0");
	RegistrationParameters.Insert("Purpose", New Array);
	RegistrationParameters.Insert("Description", Undefined);
	RegistrationParameters.Insert("SafeMode", True);
	RegistrationParameters.Insert("Information", Undefined);
	RegistrationParameters.Insert("SLVersion", SLVersion);
	
	TabularSectionAttributes = Metadata.Catalogs.AdditionalReportsAndDataProcessors.TabularSections.Commands.Attributes;
	
	CommandTable = New ValueTable;
	CommandTable.Columns.Add("Presentation", TabularSectionAttributes.Presentation.Type);
	CommandTable.Columns.Add("ID", TabularSectionAttributes.ID.Type);
	CommandTable.Columns.Add("Use", New TypeDescription("String"));
	CommandTable.Columns.Add("ShowNotification", TabularSectionAttributes.ShowNotification.Type);
	CommandTable.Columns.Add("Modifier", TabularSectionAttributes.Modifier.Type);
	CommandTable.Columns.Add("Hide",      TabularSectionAttributes.Hide.Type);
	
	RegistrationParameters.Insert("Commands", CommandTable);
	RegistrationParameters.Insert("Permissions", New Array);
	
	Return RegistrationParameters;
EndFunction

// Executes an assignable command in context from the target object form.
//
// Parameters:
//   Form            - ManagedForm - form where the command is called.
//   ItemName        - String - name of the form command that is executed.
//   ExecutionResult - Structure - see StandardSubsystemsClientServer.NewExecutionResult().
//
// Description:
//   Intended to be called by the subsystem script from the item form of an assignable object (catalog, document, etc).
//
// Important:
//   The UseAdditionalReportsAndDataProcessors functional option check must be performed in a caller script.
//
Procedure ExecuteAssignableCommandAtServer(Form, ItemName, ExecutionResult) Export
	
	Found = Form.AdditionalDataProcessorCommands.FindRows(New Structure("ItemName", ItemName));
	If Found.Count() = 0 Then
		Raise NStr("en = 'Command is not found'");
	EndIf;
	
	TableRow = Found[0];
	
	ExternalObject = GetExternalDataProcessorsObject(TableRow.Ref);
	CommandID = TableRow.ID;
	
	CommandParameters = New Structure;
	CommandParameters.Insert("ThisForm", Form);
	
	ExecutionResult = ExecuteExternalObjectCommand(ExternalObject, CommandID, CommandParameters, Undefined);
	
EndProcedure

// Executes a data processor command and returns the result.
//
// Parameters:
//   CommandParameters - Structure - command execution parameters.
//       * AdditionalDataProcessorRef - CatalogRef.AdditionalReportsAndDataProcessors - catalog item.
//       * CommandID       - String - name of the command that is executed.
//       * TargetObjects   - Array - references to objects used by the data processor. Mandatory for assignable data processors.
//       * ExecutionResult - Structure - optional. Complementary to the return value.
//          See StandardSubsystemsClientServer.NewExecutionResult().
//   ResultAddress - String - optional. Address of a temporary storage where the execution result will be stored.
//
// Returns:
//   * Structure - execution result, to be passed to the client.
//   * Undefined - if ResultAddress is passed.
//
// Important:
//   The UseAdditionalReportsAndDataProcessors functional option check must be performed in a caller script.
//
Function ExecuteCommand(CommandParameters, ResultAddress = Undefined) Export
	
	ExternalObject = GetExternalDataProcessorsObject(CommandParameters.AdditionalDataProcessorRef);
	CommandID = CommandParameters.CommandID;
	
	ExecutionResult = ExecuteExternalObjectCommand(ExternalObject, CommandID, CommandParameters, ResultAddress);
	
	Return ExecutionResult;
	
EndFunction

// Executes a data processor command directly from the external object form, and returns the execution result.
//   Usage example - see AdditionalReportsAndDataProcessorsClient.ExecuteCommandInBackground().
//
// Parameters:
//   CommandID - String - command name as it is specified in ExternalDataProcessorInfo() function in the object module.
//   CommandParameters - Structure - command execution parameters.
//      See AdditionalReportsAndDataProcessorsClient.ExecuteCommandInBackground().
//   Form - ManagedForm - form used to return the result.
//
// Returns:
//   ExecutionResult - Structure - see StandardSubsystemsClientServer.NewExecutionResult().
//
// Important:
//   The UseAdditionalReportsAndDataProcessors functional option check must be performed  in a caller script.
//
Function ExecuteCommandFromExternalObjectForm(CommandID, CommandParameters, Form) Export
	
	ExternalObject = Form.FormAttributeToValue("Object");
	
	ExecutionResult = ExecuteExternalObjectCommand(ExternalObject, CommandID, CommandParameters, Undefined);
	
	Return ExecutionResult;
	
EndFunction

// Generates a list of sections where the additional report calling command is available.
//
// Returns: 
//   Array of MetadataObject: Subsystem - metadata for the sections where the additional report command list is displayed.
//
Function AdditionalReportSections() Export
	MetadataSections = New Array;
	
	AdditionalReportsAndDataProcessorsOverridable.GetSectionsWithAdditionalReports(MetadataSections);
	
	If CommonUse.SubsystemExists("StandardSubsystems.ProgramSettings") Then
		SLAdministrationPanelDataProcessorModule = CommonUse.CommonModule("DataProcessors.SLAdministrationPanel");
		SLAdministrationPanelDataProcessorModule.OnDetermineSectionsWithAdditionalReports(MetadataSections);
	EndIf;
	
	Return MetadataSections;
EndFunction

// Generates a list of sections where the additional data processor calling command is available.
//
// Returns: 
//   Array of MetadataObject: Subsystem - metadata for the sections where the additional data processor command list is displayed.
//
Function AdditionalDataProcessorSections() Export
	MetadataSections = New Array;
	
	AdditionalReportsAndDataProcessorsOverridable.GetSectionsWithAdditionalDataProcessors(MetadataSections);
	
	If CommonUse.SubsystemExists("StandardSubsystems.ProgramSettings") Then
		SLAdministrationPanelDataProcessorModule = CommonUse.CommonModule("DataProcessors.SLAdministrationPanel");
		SLAdministrationPanelDataProcessorModule.OnDetermineSectionsWithAdditionalDataProcessors(MetadataSections);
	EndIf;
	
	Return MetadataSections;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Procedures used for data exchange

// Redefines standard behavior during data import.
//   ScheduledJobGUID attribute of the Commands tabular section cannot be transferred, 
//   because it is related to a scheduled job of the current infobase.
//
Procedure OnGetAdditionalDataProcessor(DataItem, ItemReceive) Export
	
	If ItemReceive = DataItemReceive.Ignore Then
		
		// No overriding for standard processing
		
	ElsIf TypeOf(DataItem) = Type("CatalogObject.AdditionalReportsAndDataProcessors")
		And DataItem.Kind = Enums.AdditionalReportAndDataProcessorKinds.AdditionalDataProcessor Then
		
		// Table of unique scheduled job IDs
		QueryText =
		"SELECT
		|	Commands.Ref AS Ref,
		|	Commands.ID AS ID,
		|	Commands.ScheduledJobGUID AS ScheduledJobGUID
		|FROM
		|	Catalog.AdditionalReportsAndDataProcessors.Commands AS Commands
		|WHERE
		|	Commands.Ref = &Ref";
		
		Query = New Query(QueryText);
		Query.Parameters.Insert("Ref", DataItem.Ref);
		
		ScheduledJobIDs = Query.Execute().Unload();
		
		// Filling the command table with the scheduled job IDs based on the current database data
		For Each StringCommand In DataItem.Commands Do
			Found = ScheduledJobIDs.FindRows(New Structure("ID", StringCommand.ID));
			If Found.Count() = 0 Then
				StringCommand.ScheduledJobGUID = New UUID("00000000-0000-0000-0000-000000000000");
			Else
				StringCommand.ScheduledJobGUID = Found[0].ScheduledJobGUID;
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region InternalInterface

// Declares internal events of AdditionalReportsAndDataProcessors subsystem:
//
// Server events:
//   OnUpdateBusinessCalendars.
//
// See the description of this procedure in the StandardSubsystemsServer module.
Procedure OnAddInternalEvent(ClientEvents, ServerEvents) Export
	
	// SERVER EVENTS
	
	// Call to determine whether the current user has right
	// to add an additional report or data processor to a data area.
	//
	// Parameters:
	//  AdditionalDataProcessor - CatalogObject.AdditionalReportsAndDataProcessors, catalog item written by user.
	//  Result - Boolean - flag specifying whether the user has this right. 
	//  StandardProcessing - Boolean - flag specifying whether standard processing is used to validate rights.
	//
	// Syntax:
	// Procedure OnCheckAddRight(Val AdditionalDataProcessor, Result, StandardProcessing) Export
	//
	ServerEvents.Add("StandardSubsystems.AdditionalReportsAndDataProcessors\OnCheckAddRight");
	
	// Called to check whether an additional report or data processor can be imported from file
	//
	// Parameters:
	//  AdditionalDataProcessor - CatalogRef.AdditionalReportsAndDataProcessors.
	//  Result - Boolean - flag specifying whether additional reports or data processors can be imported from file.
	//  StandardProcessing - Boolean - flag specifying whether standard processing is used to check 
 //                        if an additional report or data processor can be imported from file.
	//
	// Syntax:
	// Procedure OnCheckCanImportDataProcessorFromFile(Val AdditionalDataProcessor, Result, StandardProcessing) Export
	//
	ServerEvents.Add("StandardSubsystems.AdditionalReportsAndDataProcessors\OnCheckCanImportDataProcessorFromFile");
	
	// Called to check whether an additional report or data processor can be exported to file.
	//
	// Parameters:
	//  AdditionalDataProcessor - CatalogRef.AdditionalReportsAndDataProcessors,
	//  Result - Boolean - flag specifying whether additional reports or data processors can be exported to file. 
	//  StandardProcessing - Boolean - flag specifying whether standard processing is used 
	//    to check if an additional report or data processor can be exported to file.
	//
	// Syntax:
	// Procedure OnCheckCanExportDataProcessorToFile(Val AdditionalDataProcessor, Result, StandardProcessing) Export
	//
	ServerEvents.Add("StandardSubsystems.AdditionalReportsAndDataProcessors\OnCheckCanExportDataProcessorToFile");
	
	// Called to check if extended information on additional reports and data processors must be displayed to user.
	//
	// Parameters:
	//  AdditionalDataProcessor - CatalogRef.AdditionalReportsAndDataProcessors,
	//  Result - Boolean - flag specifying whether extended
	//    information on additional reports and data processors must be displayed to user.
	//  StandardProcessing - Boolean - flag specifying whether standard processing is used to check 
	//    if extended information on additional reports and data processors must be displayed to user.
	//
	// Syntax:
	// Procedure OnCheckExtendedInformationDisplayingRequired(Val AdditionalDataProcessor, Result, StandardProcessing) Export
	//
	ServerEvents.Add("StandardSubsystems.AdditionalReportsAndDataProcessors\OnCheckExtendedInformationDisplayingRequired");
	
	// Fills additional report or data processor publication kinds that cannot be used in the current infobase model.
	//
	// Parameters:
	//  UnavailablePublicationKinds - Array of strings.
	//
	// Syntax:
	// Procedure OnFillUnavailablePublicationKinds(Val UnavailablePublicationKinds) Export
	//
	ServerEvents.Add("StandardSubsystems.AdditionalReportsAndDataProcessors\OnFillUnavailablePublicationKinds");

	// Called from the BeforeWrite event of AdditionalReportsAndDataProcessors catalog. 
	// Validates changes to the catalog item attributes for additional data processors 
	// retrieved from the service manager's additional data processors catalog.
	//
	// Parameters:
	//  Source - CatalogObject.AdditionalReportsAndDataProcessor, Cancel - Boolean - flag specifying 
    // whether catalog item write action must be cancelled.
	//
	// Syntax:
	// Procedure BeforeWriteAdditionalDataProcessor(Val Source, Cancel) Export
	//
	ServerEvents.Add("StandardSubsystems.AdditionalReportsAndDataProcessors\BeforeWriteAdditionalDataProcessor");
		
	// Called from the BeforeDelete event of AdditionalReportsAndDataProcessors catalog.
	//
	// Parameters:
	//  Source - CatalogObject.AdditionalReportsAndDataProcessors, Cancel - Boolean - flag specifying whether catalog item delete action must be cancelled.
	//
	// Syntax:
	// Procedure BeforeDeleteAdditionalDataProcessor(Val Source, Cancel) Export
	//
	ServerEvents.Add("StandardSubsystems.AdditionalReportsAndDataProcessors\BeforeDeleteAdditionalDataProcessor");
	
	// Called to get registration data for a new additional report or data processor.
	//
	// Parameters:
	//  Object - CatalogObject.AdditionalReportsAndDataProcessors.
	//  RegistrationData - Structure - identical to the structure returned by the ExternalDataProcessorInfo() export function. 
	//  StandardProcessing - Boolean.
	//
	// Syntax:
	// Procedure OnGetRegistrationData(Val Object, RegistrationData, StandardProcessing) Export
	//
	ServerEvents.Add("StandardSubsystems.AdditionalReportsAndDataProcessors\OnGetRegistrationData");
	
	// Called to attach an external data processor.
	//
	// Parameters:
	//  Ref - CatalogRef.AdditionalReportsAndDataProcessors, StandardProcessing - Boolean - flag specifying whether standard processing is required to attach an external data processor. 
	//  Result - String - name of attached external report or data processor (provided that the StandardProcessing parameter is set to False in the handler).
	//
	// Syntax:
	// Procedure OnAttachExternalDataProcessor(Val Ref, StandardProcessing, Result) Export
	//
	ServerEvents.Add("StandardSubsystems.AdditionalReportsAndDataProcessors\OnAttachExternalDataProcessor");
	
	// Called to create an external data processor object.
	//
	// Parameters:
	//  Ref - CatalogRef.AdditionalReportsAndDataProcessors, StandardProcessing - Boolean - flag specifying whether standard processing is required to attach an external data processor. 
	//  Result - ExternalDataProcessorObject, ExternalReportObject - object of attached external report or data processor (provided that the StandardProcessing parameter is set to False in the handler).
	//
	// Syntax:
	// Procedure OnCreateExternalDataProcessor(Val Ref, StandardProcessing, Result) Export
	//
	ServerEvents.Add("StandardSubsystems.AdditionalReportsAndDataProcessors\OnCreateExternalDataProcessor");
	
	// Called to get permissions for a safe mode session.
	//
	// Parameters:
	//  SessionKey - UUID.
	//  PermissionDetailList - ValueTable:
	//    * PermissionKind - String.
	//    * Parameters     - ValueStorage.
	//  StandardProcessing - Boolean - flag specifying whether standard processing is required.
	//
	// Syntax:
	// Procedure OnGetSafeModeExtentionSessionPermissions(Val SessionKey, PermissionDetailList, StandardProcessing) Export
	//
	ServerEvents.Add("StandardSubsystems.AdditionalReportsAndDataProcessors\OnGetSafeModeExtentionSessionPermissions");
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Adds handlers of internal events (subscriptions).

// See the description of this procedure in the StandardSubsystemsServer module.
Procedure InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers) Export
	
	// SERVER HANDLERS
	
	ServerHandlers["StandardSubsystems.InfobaseVersionUpdate\OnAddUpdateHandlers"].Add(
		"AdditionalReportsAndDataProcessors");
	
	ServerHandlers["StandardSubsystems.BaseFunctionality\OnReceiveDataFromSlave"].Add(
		"AdditionalReportsAndDataProcessors");
	
	ServerHandlers["StandardSubsystems.BaseFunctionality\OnReceiveDataFromMaster"].Add(
		"AdditionalReportsAndDataProcessors");
	
	If CommonUse.SubsystemExists("StandardSubsystems.ToDoList") Then
		ServerHandlers["StandardSubsystems.ToDoList\OnFillToDoList"].Add(
			"AdditionalReportsAndDataProcessors");
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Internal event handlers

// Adds update handlers that are required by the subsystem.
//
// Parameters:
//  Handlers - ValueTable - See InfobaseUpdate.NewUpdateHandlerTable().
//
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version = "1.0.7.1";
	Handler.Procedure = "AdditionalReportsAndDataProcessors.UpdateDataProcessorUserAccessSettings";
	
	Handler = Handlers.Add();
	Handler.Version = "2.0.1.4";
	Handler.Procedure = "AdditionalReportsAndDataProcessors.FillObjectNames";
	
	Handler = Handlers.Add();
	Handler.Version = "2.1.3.2";
	Handler.Procedure = "AdditionalReportsAndDataProcessors.ReplaceMetadataObjectNamesWithReferences";
	
	If Not CommonUseCached.DataSeparationEnabled() Then
		Handler = Handlers.Add();
		Handler.ExecuteInMandatoryGroup = True;
		Handler.SharedData                  = True;
		Handler.HandlerManagement      = False;
		Handler.ExclusiveMode             = True;
		Handler.Version    = "2.1.3.22";
		Handler.Procedure = "AdditionalReportsAndDataProcessors.EnableFunctionalOption";
	EndIf;
	
	Handler = Handlers.Add();
	Handler.Version = "2.2.2.25";
	Handler.Procedure = "AdditionalReportsAndDataProcessors.FillPermissionCompatibilityMode";
	
EndProcedure

// This procedure is a handler for an event of the same name that occurs during data exchange in a distributed infobase. For more details, see description of the OnReceiveDataFromSlave() event handler in Syntax Assistant.
//
Procedure OnReceiveDataFromSlave(DataItem, ItemReceive, SendBack, Sender) Export
	
	OnGetAdditionalDataProcessor(DataItem, ItemReceive);
	
EndProcedure

// This procedure is a handler for an event of the same name that occurs during data exchange in a distributed infobase. For more details, see description of the OnReceiveDataFromMaster() event handler in Syntax Assistant.
//
Procedure OnReceiveDataFromMaster(DataItem, ItemReceive, SendBack, Sender) Export
	
	OnGetAdditionalDataProcessor(DataItem, ItemReceive);
	
EndProcedure

// Fills a user's to-do list.
//
// Parameters:
//  ToDoList - ValueTable - value table with the following columns:
//    * ID             - String - internal user task ID used by the To-do list algorithm.
//    * HasUserTasks   - Boolean - if True, the user task is displayed in the user's to-do list.
//    * Important      - Boolean - If True, the user task is outlined in red.
//    * Presentation   - String - user task presentation displayed to the user.
//    * Count          - Number  - quantitative indicator of the user task, 
//                       displayed in the title of the user task.
//    * Form           - String - full path to the form that is displayed by a click on the task hyperlink in the To-do list panel.
//    * FormParameters - Structure - parameters for opening the indicator form.
//    * Owner          - String, metadata object - string ID of the user task that is the owner of the current user task, or a subsystem metadata object.
//    * Hint           - String - hint text
//
Procedure OnFillToDoList(ToDoList) Export
	
	// Local (as opposed to cloud-based)
	If CommonUseCached.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	// Has rights to access catalog data
	If Not AccessRight("Edit", Metadata.Catalogs.AdditionalReportsAndDataProcessors) Then
		Return;
	EndIf;
	
	// Administration section is available
	Subsystem = Metadata.Subsystems.Find("Administration");
	If Subsystem = Undefined
		Or Not AccessRight("View", Subsystem)
		Or Not CommonUse.MetadataObjectEnabledByFunctionalOptions(Subsystem) Then
		Return;
	EndIf;
	
	OutputUserTask = True;
	VersionChecked = CommonSettingsStorage.Load("ToDoList", "AdditionalReportsAndDataProcessors");
	If VersionChecked <> Undefined Then
		VersionArray  = StringFunctionsClientServer.SplitStringIntoSubstringArray(Metadata.Version, ".");
		CurrentVersion = VersionArray[0] + VersionArray[1] + VersionArray[2];
		If VersionChecked = CurrentVersion Then
			OutputUserTask = False; // Additional reports and data processors were checked on the current version.
		EndIf;
	EndIf;
	
	AdditionalReportsAndDataProcessorsCount = AdditionalReportsAndDataProcessorsCount();
	
	UserTask = ToDoList.Add();
	UserTask.ID           = "AdditionalReportsAndDataProcessors";
	UserTask.HasUserTasks = OutputUserTask And AdditionalReportsAndDataProcessorsCount > 0;
	UserTask.Presentation = NStr("en = 'Additional reports and data processors'");
	UserTask.Quantity     = AdditionalReportsAndDataProcessorsCount;
	UserTask.Form         = "Catalog.AdditionalReportsAndDataProcessors.Form.AdditionalReportsAndDataProcessorsCheck";
	UserTask.Owner        = "ValidateCompatibilityWithCurrentVersion";
	
	// Checking for a user task group. If the group is missing, adding it.
	UserTaskGroup = ToDoList.Find("ValidateCompatibilityWithCurrentVersion", "ID");
	If UserTaskGroup = Undefined Then
		UserTaskGroup = ToDoList.Add();
		UserTaskGroup.ID = "ValidateCompatibilityWithCurrentVersion";
		UserTaskGroup.HasUserTasks      = UserTask.HasUserTasks;
		UserTaskGroup.Presentation = NStr("en = 'Check compatibility'");
		If UserTask.HasUserTasks Then
			UserTaskGroup.Quantity = UserTask.Quantity;
		EndIf;
		UserTaskGroup.Owner = Subsystem;
	Else
		If Not UserTaskGroup.HasUserTasks Then
			UserTaskGroup.HasUserTasks = UserTask.HasUserTasks;
		EndIf;
		
		If UserTask.HasUserTasks Then
			UserTaskGroup.Quantity = UserTaskGroup.Quantity + UserTask.Quantity;
		EndIf;
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Handlers of conditional calls

// Gets an additional report reference, provided that the report is connected to the Report options subsystem storage.
//
// Parameters:
//   InformationReport - Structure - see ReportOptions.GenerateReportInformationByFullName().
//
Procedure OnDetermineTypeAndReferenceIfReportIsAuxiliary(InformationReport) Export
	If Not GetFunctionalOption("UseAdditionalReportsAndDataProcessors") Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT TOP 1
	|	Table.Ref
	|FROM
	|	Catalog.AdditionalReportsAndDataProcessors AS Table
	|WHERE
	|	Table.ObjectName = &ObjectName
	|	AND Table.DeletionMark = FALSE
	|	AND Table.Kind = &KindAdditionalReport
	|	AND Table.UseOptionStorage = TRUE
	|	AND Table.Publication = &PublicationUsed";
	
	Query = New Query;
	Query.SetParameter("ObjectName", InformationReport.ReportName);
	Query.SetParameter("KindAdditionalReport", Enums.AdditionalReportAndDataProcessorKinds.AdditionalReport);
	Query.SetParameter("PublicationUsed", Enums.AdditionalReportsAndDataProcessorsPublicationVariants.Used);
	If InformationReport.AllReportsAttached Then
		QueryText = StrReplace(QueryText, "AND Table.UseOptionStorage = TRUE", "");
	EndIf;
	Query.Text = QueryText;
	
	SetPrivilegedMode(True); // Required to ensure integrity of the generated data. Access rights will be applied during the data usage phase.
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		InformationReport.Report = Selection.Ref;
		InformationReport.Insert("ReportIsAuxiliary");
	EndIf;
	
EndProcedure

// Supplements the array with references to additional reports the current user can access.
//
// Parameters:
//   Result - Array of <see Catalogs.ReportOptions.Attributes.Report> -
//       References to reports the current user can access.
//
// Usage instances:
//   ReportOptions.CurrentUserReports().
//
Procedure OnAddAdditionalReportsAvailableForCurrentUser(AvailableReports) Export
	If Not GetFunctionalOption("UseAdditionalReportsAndDataProcessors") Then
		Return;
	EndIf;
	If Not AccessRight("Read", Metadata.Catalogs.AdditionalReportsAndDataProcessors) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED DISTINCT
	|	Table.Ref
	|FROM
	|	Catalog.AdditionalReportsAndDataProcessors AS Table
	|WHERE
	|	Table.UseOptionStorage
	|	AND Table.Kind = &KindAdditionalReport
	|	AND Not Table.Ref IN (&AvailableReports)";
	
	Query.SetParameter("AvailableReports", AvailableReports);
	Query.SetParameter("KindAdditionalReport", Enums.AdditionalReportAndDataProcessorKinds.AdditionalReport);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		AvailableReports.Add(Selection.Ref);
	EndDo;
	
EndProcedure

// Attaches a report from the Additional reports and data processors subsystem.
//   Exception handling is performed by the control script.
//
// Parameters:
//   Ref - CatalogRef.AdditionalReportsAndDataProcessors - Report to be initialized. 
//   ReportParameters - Structure - Parameter set obtained during report validation and attachment. 
//       See ReportMailing.InitReport().
//   Result - Boolean, Undefined - Result:
//       True      - additional report is attached successfully. 
//       False     - failed to attach additional report. 
//       Undefined - the additional reports subsystem is unavailable.
//
// Usage instances:
//   ReportOptions.AttachReportObject().
//   ReportMailing.InitReport().
//
Procedure OnAttachAdditionalReport(Ref, ReportParameters, Result) Export
	If Not GetFunctionalOption("UseAdditionalReportsAndDataProcessors") Then
		ReportParameters.Errors = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Item %1 is not attached, because subsystem %2 is disabled in the application settings.
			|To have the subsystem enabled, please contact the application administrator.'"),
			"'"+ String(Ref) +"'",
			AdditionalReportsAndDataProcessorsClientServer.SubsystemDescription("en"));
		Return;
	EndIf;
	
	Kind = CommonUse.ObjectAttributeValue(Ref, "Kind");
	If Kind = Enums.AdditionalReportAndDataProcessorKinds.Report
		Or Kind = Enums.AdditionalReportAndDataProcessorKinds.AdditionalReport Then
		
		ReportParameters.Name = AttachExternalDataProcessor(Ref);
		ReportParameters.Object = ExternalReports.Create(ReportParameters.Name);
		ReportParameters.Metadata = ReportParameters.Object.Metadata();
		
		Result = True;
		
	Else
		
		ReportParameters.Errors = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Item %1 is not an additional report'"), 
			"'"+ String(Ref) +"'");
		
		Result = False;
		
	EndIf;
	
EndProcedure

// Adds external print forms to the print command list.
//
// Parameters:
//   PrintCommands - ValueTable - see PrintManagement.CreatePrintCommandCollection().
//   FormName      - String     - full name of a form whose print command list is requested.
//
// Usage instances:
//   PrintManagement.FormPrintCommands().
//
Procedure OnReceivePrintCommands(PrintCommands, FormName) Export
	If Not GetFunctionalOption("UseAdditionalReportsAndDataProcessors") Then
		Return;
	EndIf;
	If Not AccessRight("Read", Metadata.Catalogs.AdditionalReportsAndDataProcessors) Then
		Return;
	EndIf;
	
	FormMetadata = Metadata.FindByFullName(FormName);
	If FormMetadata = Undefined Then
		Return;
	EndIf;
	
	MetadataObjectFullName = FormMetadata.Parent().FullName();
	Request = NewQueryByAvailableCommands(Enums.AdditionalReportAndDataProcessorKinds.PrintForm, MetadataObjectFullName);
	CommandTable = Request.Execute().Unload();
	
	If CommandTable.Count() = 0 Then
		Return;
	EndIf;
	
	For Each TableRow In CommandTable Do
		PrintCommand = PrintCommands.Add();
		
		// Mandatory parameters
		FillPropertyValues(PrintCommand, TableRow, "ID, Presentation");
		// Parameters used as subsystem identifiers
		PrintCommand.PrintManager = "StandardSubsystems.AdditionalReportsAndDataProcessors";
		
		// Additional parameters
		PrintCommand.AdditionalParameters = New Structure("Ref, Modifier, RunningVariant, ShowNotification");
		FillPropertyValues(PrintCommand.AdditionalParameters, TableRow);
	EndDo;
	
EndProcedure

// Fills a print form list from external sources.
//
// Parameters:
//   ExternalPrintForms - ValueList - Print forms:
//       Value        - String - Print form ID.
//       Presentation - String - Print form name.
//   MetadataObjectFullName - String - Full name of a metadata object whose print command list is requested.
//
// Usage instances:
//   PrintManagement.OnReceiveExternalPrintFormList().
//
Procedure OnReceiveExternalPrintFormList(ExternalPrintForms, MetadataObjectFullName) Export
	If Not GetFunctionalOption("UseAdditionalReportsAndDataProcessors") Then
		Return;
	EndIf;
	If Not AccessRight("Read", Metadata.Catalogs.AdditionalReportsAndDataProcessors) Then
		Return;
	EndIf;
	
	Request = NewQueryByAvailableCommands(Enums.AdditionalReportAndDataProcessorKinds.PrintForm, MetadataObjectFullName);
	
	CommandTable = Request.Execute().Unload();
	
	For Each Command In CommandTable Do
		If Find(Command.ID, ",") = 0 Then // ignoring batches
			ExternalPrintForms.Add(Command.ID, Command.Presentation);
		EndIf;
	EndDo;
	
EndProcedure

// Returns the reference to an external print form object.
//
// Usage instances:
//   PrintManagement.OnReceiveExternalPrintForm().
//
Procedure OnReceiveExternalPrintForm(ID, MetadataObjectFullName, ExternalPrintFormRef) Export
	If Not GetFunctionalOption("UseAdditionalReportsAndDataProcessors") Then
		Return;
	EndIf;
	If Not AccessRight("Read", Metadata.Catalogs.AdditionalReportsAndDataProcessors) Then
		Return;
	EndIf;
	
	Request = NewQueryByAvailableCommands(Enums.AdditionalReportAndDataProcessorKinds.PrintForm, MetadataObjectFullName);
	
	CommandTable = Request.Execute().Unload();
	
	Command = CommandTable.Find(ID, "ID");
	If Command <> Undefined Then 
		ExternalPrintFormRef = Command.Ref;
	EndIf;
	
EndProcedure

// Gets additional report and data processor settings for a specified user.
//
// Parameters:
//   UserRef  - CatalogRef.Users - user that requires the settings.
//   Settings - Structure - other user settings.
//       * SettingName    - String    - name to be displayed in the data processor settings tree.
//       * SettingPicture - Picture   - picture to be displayed in the data processor settings tree.
//       * SettingsList   - ValueList - list of retrieved settings.
//
// Usage instances:
//   UsersInternal.OnReceiveOtherUserSettings().
//
Procedure GetAdditionalReportAndDataProcessorSettings(UserRef, Settings) Export
	If Not GetFunctionalOption("UseAdditionalReportsAndDataProcessors") Then
		Return;
	EndIf;
	
	// Settings string name to be displayed in the data processor settings tree
	SettingName = NStr("en='Quick access settings for additional reports and data processors'");
	
	// Settings string picture
	SettingPicture = "";
	
	// List of additional reports and data processors the user can quickly access
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DataProcessorAccessUserSettings.AdditionalReportOrDataProcessor AS Object,
	|	DataProcessorAccessUserSettings.CommandID AS ID,
	|	DataProcessorAccessUserSettings.User AS User
	|FROM
	|	InformationRegister.DataProcessorAccessUserSettings AS DataProcessorAccessUserSettings
	|WHERE
	|	User = &User";
	
	Query.Parameters.Insert("User", UserRef);
	
	RequestResult = Query.Execute().Unload();
	
	Settings = New Structure;
	Settings.Insert("SettingName", SettingName);
	Settings.Insert("SettingPicture", SettingPicture);
	Settings.Insert("SettingsList", RequestResult);
	
EndProcedure

// Saves additional report and data processor commands for the specified users.
//
// Parameters:
//   Settings - ValueList - List of keys for saved settings.
//   RecipientUsers - Array of CatalogRef.Users - list of users to receive the settings.
//
// Usage instances:
//   UsersInternal.OnSaveOtherUserSettings().
//
Procedure AddCommandsToQuickAccessList(Settings, UserTarget) Export
	
	If Not GetFunctionalOption("UseAdditionalReportsAndDataProcessors") Then
		Return;
	EndIf;
	
	For Each StringItem In Settings Do
		
		Record = InformationRegisters.DataProcessorAccessUserSettings.CreateRecordManager();
		
		Record.AdditionalReportOrDataProcessor  = StringItem.Value;
		Record.CommandID             = StringItem.Presentation;
		Record.User                     = UserTarget;
		Record.Available                         = True;
		
		Record.Write(True);
		
	EndDo;
	
EndProcedure

// Clears additional report and data processor commands for the specified user.
//
// Parameters:
//   KeyList     - ValueList - List of keys for cleared settings.
//   UserToClear - CatalogRef.Users - User to clear the settings.
//
// Usage instances:
//   UsersInternal.OnDeleteOtherUserSettings().
//
Procedure DeleteCommandsFromQuickAccessList(KeyList, UserToClear) Export
	If Not GetFunctionalOption("UseAdditionalReportsAndDataProcessors") Then
		Return;
	EndIf;
	
	For Each StringItem In KeyList Do
		
		Record = InformationRegisters.DataProcessorAccessUserSettings.CreateRecordManager();
		
		Record.AdditionalReportOrDataProcessor  = StringItem.Value;
		Record.CommandID             = StringItem.Presentation;
		Record.User                     = UserToClear;
		
		Record.Read();
		
		Record.Delete();
		
	EndDo;
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

////////////////////////////////////////////////////////////////////////////////
// Infobase update

// [1.0.7.1] Procedure used to update the records on additional data processor availability
Procedure UpdateDataProcessorUserAccessSettings() Export
	
	UsersWithAdditionalDataProcessors = GetArrayOfUsersWithAccessToAddtionalDataProcessors();
	
	RecordTable = GetRecordTable(UsersWithAdditionalDataProcessors);
	
	For Each User In UsersWithAdditionalDataProcessors Do
		RecordSet = InformationRegisters.DataProcessorAccessUserSettings.CreateRecordSet();
		RecordSet.Filter.User.Set(User);
		QuickAccessRecords = RecordTable.FindRows(New Structure("User,Available", User, True));
		For Each QuickAccessRecord In QuickAccessRecords Do
			NewRecord = RecordSet.Add();
			NewRecord.AdditionalReportOrDataProcessor = QuickAccessRecord.Processing;
			NewRecord.CommandID			= QuickAccessRecord.ID;
			NewRecord.User					= User;
			NewRecord.Available						= True;
		EndDo;
		InfobaseUpdate.WriteData(RecordSet);
	EndDo;
	
EndProcedure

// [2.0.1.4] Filling the ObjectName attribute (name used to register the object in the application).
//   For objects with the Use publication option, additional check for Object name uniqueness is performed. If any reports (data processors) with duplicate Object names for all items except the first one are found, Publication option is changed from Use to Debug mode.
//
Procedure FillObjectNames() Export
	QueryText =
	"SELECT
	|	AdditionalReports.Ref,
	|	AdditionalReports.ObjectName,
	|	AdditionalReports.DataProcessorStorage,
	|	CASE
	|		WHEN AdditionalReports.Kind IN (&AdditionalReportKinds)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS IsReport,
	|	CASE
	|		WHEN AdditionalReports.Publication = VALUE(Enum.AdditionalReportsAndDataProcessorsPublicationVariants.Used)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS InPublication,
	|	CASE
	|		WHEN AdditionalReports.ObjectName = """"
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS FillObjectNameRequired
	|FROM
	|	Catalog.AdditionalReportsAndDataProcessors AS AdditionalReports
	|WHERE
	|	AdditionalReports.IsFolder = FALSE
	|	AND Not AdditionalReports.DataProcessorStorage IS NULL ";
	
	AdditionalReportKinds = New Array;
	AdditionalReportKinds.Add(Enums.AdditionalReportAndDataProcessorKinds.Report);
	AdditionalReportKinds.Add(Enums.AdditionalReportAndDataProcessorKinds.AdditionalReport);
	
	Query = New Query;
	Query.SetParameter("AdditionalReportKinds", AdditionalReportKinds);
	Query.Text = QueryText;
	
	AllAdditionalReports = Query.Execute().Unload();
	
	SearchForDuplicates = New Structure("ObjectName, IsReport, InPublication");
	SearchForDuplicates.InPublication = True;
	
	// Additional reports and data processors that require filling the object name
	AdditionalReportsToFill = AllAdditionalReports.FindRows(New Structure("FillObjectNameRequired", True));
	For Each TableRow In AdditionalReportsToFill Do
		
		// Moving the report (data processor) binary data to temporary storage
		AddressInTempStorage = PutToTempStorage(TableRow.DataProcessorStorage.Get());
		
		// Defining the manager
		Manager = ?(TableRow.IsReport, ExternalReports, ExternalDataProcessors);
		
		// Getting an object instance
		Object = TableRow.Ref.GetObject();
		
		// Setting object name
		Object.ObjectName = TrimAll(Manager.Connect(AddressInTempStorage, , True));
		
		// If the report (data processor) name is already in use by another published report (data processor), 
		// this object is a duplicate; it is necessary to set its publication option to Debug mode (or disable it).
		If TableRow.InPublication Then
			SearchForDuplicates.ObjectName = Object.ObjectName;
			SearchForDuplicates.IsReport   = TableRow.IsReport;
			If AllAdditionalReports.FindRows(SearchForDuplicates).Count() > 0 Then
				Object.Publication = AdditionalReportsAndDataProcessorsCached.AllPublicationsForConflictingDataProcessors();
			EndIf;
		EndIf;
		
		// Recording the used object name in the duplicate control table
		TableRow.ObjectName = Object.ObjectName;
		
		// Writing object
		InfobaseUpdate.WriteData(Object);
	EndDo;
	
EndProcedure

// Replaces desktop names with references from the MetadataObjectIDs catalog.
//
// Parameters:
//   SectionNamesAndIDs - Map:
//       * Key - String - Desktop (command) name previously used in the procedures:
//             AdditionalReportsAndDataProcessorsOverridable.GetCommonCommandsForAdditionalDataProcessors();
//             AdditionalReportsAndDataProcessorsOverridable.GetCommonCommandsForAdditionalReports().
//       * Value - MetadataObject: Subsystem - Command interface section (level-one subsystem) where this desktop (command) is located.
//
Procedure ReplaceSectionNamesWithIDs(SectionNamesAndIDs) Export
	DesktopID = AdditionalReportsAndDataProcessorsClientServer.DesktopID();
	
	SectionNameArray = New Array;
	For Each KeyAndValue In SectionNamesAndIDs Do
		If KeyAndValue.Value = DesktopID Then
			SectionNamesAndIDs.Insert(KeyAndValue.Key, Catalogs.MetadataObjectIDs.EmptyRef());
		Else
			SectionNamesAndIDs.Insert(KeyAndValue.Key, CommonUse.MetadataObjectID(KeyAndValue.Value));
		EndIf;
		SectionNameArray.Add(KeyAndValue.Key);
	EndDo; 
	
	QueryText =
	"SELECT DISTINCT
	|	TSSections.Ref
	|FROM
	|	Catalog.AdditionalReportsAndDataProcessors.Sections AS TSSections
	|WHERE
	|	TSSections.DELETE IN (&SectionNameArray)";
	
	Query = New Query;
	Query.SetParameter("SectionNameArray", SectionNameArray);
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		// Getting an object instance
		Object = Selection.Ref.GetObject();
		
		For Each SectionRow In Object.Sections Do
			IOM = SectionNamesAndIDs.Get(SectionRow.DELETE);
			If IOM = Undefined Then
				Continue;
			EndIf;
			SectionRow.Section = IOM;
			SectionRow.DELETE = "";
		EndDo; 
		
		// Writing object
		InfobaseUpdate.WriteData(Object);
	EndDo;
EndProcedure

// [2.1.3.2) Replacing the target object name with references from the MetadataObjectIDs catalog.
Procedure ReplaceMetadataObjectNamesWithReferences() Export
	
	BeginTransaction();
	
	QueryText =
	"SELECT
	|	PurposeTable.Ref AS CatalogRef,
	|	PurposeTable.LineNumber AS LineNumber,
	|	MOIDCatalog.Ref AS TargetObject
	|FROM
	|	Catalog.AdditionalReportsAndDataProcessors.Purpose AS PurposeTable
	|		LEFT JOIN Catalog.MetadataObjectIDs AS MOIDCatalog
	|		ON PurposeTable.DELETE = MOIDCatalog.FullName
	|TOTALS BY
	|	CatalogRef";
	
	Query = New Query;
	Query.Text = QueryText;
	
	ReferenceSelection = Query.Execute().Select(QueryResultIteration.ByGroups);
	While ReferenceSelection.Next() Do
		CatalogObject = ReferenceSelection.CatalogRef.GetObject();
		RowToDeleteArray = New Array;
		RowSelection = ReferenceSelection.Select();
		While RowSelection.Next() Do
			TabularSectionRow = CatalogObject.Purpose.Get(RowSelection.LineNumber - 1);
			TabularSectionRow.TargetObject = RowSelection.TargetObject;
			If ValueIsFilled(TabularSectionRow.TargetObject) Then
				TabularSectionRow.DELETE = "";
			Else
				RowToDeleteArray.Add(TabularSectionRow);
			EndIf;
		EndDo;
		For Each TabularSectionRow In RowToDeleteArray Do
			CatalogObject.Purpose.Delete(TabularSectionRow);
		EndDo;
		InfobaseUpdate.WriteData(CatalogObject);
	EndDo;
	
	InformationRegisters.AdditionalDataProcessorPurposes.Refresh(True);
	
	CommitTransaction();
	
EndProcedure

// [2.1.3.22] Enabling the UseAdditionalReportsAndDataProcessors functional option for local mode.
Procedure EnableFunctionalOption() Export
	
	If CommonUseCached.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	Constants.UseAdditionalReportsAndDataProcessors.Set(True);
	
EndProcedure

// [2.2.2.25] Procedure sets the PermissionCompatibilityMode attribute value
// for the AdditionalReportsAndDataProcessors catalog items.
//
Procedure FillPermissionCompatibilityMode() Export
	
	BeginTransaction();
	
	Try
		
		DataLock = New DataLock();
		DataLock.Add("Catalog.AdditionalReportsAndDataProcessors");
		DataLock.Lock();
		
		Selection = Catalogs.AdditionalReportsAndDataProcessors.Select();
		While Selection.Next() Do
			
			If Not Selection.IsFolder And Not ValueIsFilled(Selection.PermissionCompatibilityMode) Then
				
				LockDataForEdit(Selection.Ref);
				
				Object = Selection.GetObject();
				
				Try
					
					ObjectToProcess = GetExternalDataProcessorsObject(Selection.Ref);
					RegistrationData = ObjectToProcess.ExternalDataProcessorInfo();
					
					If RegistrationData.Property("SLVersion") Then
						If CommonUseClientServer.CompareVersions(RegistrationData.SLVersion, "2.2.2.0") > 0 Then
							CompatibilityMode = Enums.AdditionalReportsAndDataProcessorsPermissionCompatibilityModes.Version_2_2_2;
						Else
							CompatibilityMode = Enums.AdditionalReportsAndDataProcessorsPermissionCompatibilityModes.Version_2_1_3;
						EndIf;
					Else
						CompatibilityMode = Enums.AdditionalReportsAndDataProcessorsPermissionCompatibilityModes.Version_2_1_3;
					EndIf;
					
					Publication = Object.Publication;
					
				Except
					
					// When a data processor cannot be attached - switching to permission compatibility with SL 2.1.3, enabling a temporary lock
					ErrorText = """" + Object.Description + """:"
						+ Chars.LF + NStr("en = 'Cannot determine the permissions compatibility mode for this reason:'")
						+ Chars.LF + DetailErrorDescription(ErrorInfo())
						+ Chars.LF
						+ Chars.LF + NStr("en = 'The object is locked in version 2 compatibility mode1.3.'");
					WriteWarning(Object.Ref, ErrorText);
					CompatibilityMode = Enums.AdditionalReportsAndDataProcessorsPermissionCompatibilityModes.Version_2_1_3;
					Publication = Enums.AdditionalReportsAndDataProcessorsPublicationVariants.Disabled;
					
				EndTry;
				
				Object.PermissionCompatibilityMode = CompatibilityMode;
				Object.Publication = Publication;
				InfobaseUpdate.WriteData(Object);
			EndIf;
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Scheduled jobs

// StartingDataProcessors scheduled job instance handler.
//   Starts a global data processor handler for the scheduled job, using the specified command ID.
//
// Parameters
//   ExternalDataProcessor - CatalogRef.AdditionalReportsAndDataProcessors - reference to the running data processor.
//   CommandID             - String - command ID.
//
Procedure ExecuteDataProcessorByScheduledJob(ExternalDataProcessor, CommandID) Export
	
	CommonUse.ScheduledJobOnStart();
	
	// Writing to the event log
	WriteInformation(ExternalDataProcessor, NStr("en = 'Command %1: Start.'"), CommandID);
	
	// Executing the command
	Try
		ExecuteCommand(New Structure("AdditionalDataProcessorRef, CommandID", ExternalDataProcessor, CommandID), Undefined);
	Except
		WriteError(
			ExternalDataProcessor,
			NStr("en = 'Command: %1. Runtime error:%2'"),
			CommandID,
			Chars.LF + DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	// Writing to the event log
	WriteInformation(ExternalDataProcessor, NStr("en = 'Command %1: End.'"), CommandID);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Export internal procedures and functions

// Generates a new query used to get a command table for additional reports or data processors
//
// Parameters:
//   DataProcessorKind - EnumRef.AdditionalReportAndDataProcessorKinds - data processor kind.
//   FullNameOrParentOrSectionReference - CatalogRef.MetadataObjectIDs, String -
//       metadata object (Ref or FullName).
//       For assignable data processors, catalog or document is used.
//       For global data processors, subsystem is used.
//   IsObjectForm - Boolean - optional.
//       If True, an object form is used.
//       If False, a list form  is used.
//
// Returns: 
//   ValueTable - Additional report or data processor commands.
//       * Ref - CatalogRef.AdditionalReportsAndDataProcessors - reference to an additional report or data processor.
//       * ID - String - command ID set by the additional object developer.
//       * RunningVariant - EnumRef.AdditionalDataProcessorCallMethods -
//           method of calling the additional object command.
//       * Presentation - String - command name as displayed in user interface.
//       * ShowNotification - Boolean - notify user upon command completion.
//       * Modifier - String - command modifier.
//
Function NewQueryByAvailableCommands(DataProcessorKind, FullNameOrParentOrSectionReference, IsObjectForm = Undefined) Export
	AreGlobalDataProcessors = (
		DataProcessorKind = Enums.AdditionalReportAndDataProcessorKinds.AdditionalReport
		Or DataProcessorKind = Enums.AdditionalReportAndDataProcessorKinds.AdditionalDataProcessor);
	
	If TypeOf(FullNameOrParentOrSectionReference) = Type("CatalogRef.MetadataObjectIDs") Then
		ParentOrSectionReference = FullNameOrParentOrSectionReference;
	Else
		ParentOrSectionReference = CommonUse.MetadataObjectID(FullNameOrParentOrSectionReference);
	EndIf;
	
	Query = New Query;
	
	// Calls used for global and for assignable data processors are fundamentally different
	If AreGlobalDataProcessors Then
		QueryText =
		"SELECT DISTINCT
		|	QuickAccess.AdditionalReportOrDataProcessor AS Ref,
		|	QuickAccess.CommandID
		|INTO QuickAccessTempTable
		|FROM
		|	InformationRegister.DataProcessorAccessUserSettings AS QuickAccess
		|WHERE
		|	QuickAccess.User = &CurrentUser
		|	AND QuickAccess.Available = TRUE
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	QuickAccessTable.Ref,
		|	QuickAccessTable.CommandID
		|INTO ReferencesAndCommandsTempTable
		|FROM
		|	QuickAccessTempTable AS QuickAccessTable
		|		INNER JOIN Catalog.AdditionalReportsAndDataProcessors AS AdditReportsAndDataProcessors
		|		ON QuickAccessTable.Ref = AdditReportsAndDataProcessors.Ref
		|			AND (AdditReportsAndDataProcessors.DeletionMark = FALSE)
		|			AND (AdditReportsAndDataProcessors.Kind = &Kind)
		|			AND (AdditReportsAndDataProcessors.Publication = &Publication)
		|		INNER JOIN Catalog.AdditionalReportsAndDataProcessors.Sections AS SectionsTable
		|		ON QuickAccessTable.Ref = SectionsTable.Ref
		|			AND (SectionsTable.Section = &SectionRef)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CommandsTable.Ref,
		|	CommandsTable.ID,
		|	CommandsTable.RunningVariant,
		|	CommandsTable.Presentation AS Presentation,
		|	CommandsTable.ShowNotification,
		|	CommandsTable.Modifier
		|FROM
		|	ReferencesAndCommandsTempTable AS ReferencesAndCommandsTable
		|		INNER JOIN Catalog.AdditionalReportsAndDataProcessors.Commands AS CommandsTable
		|		ON ReferencesAndCommandsTable.Ref = CommandsTable.Ref
		|			AND ReferencesAndCommandsTable.CommandID = CommandsTable.ID
		|			AND (CommandsTable.Hide = FALSE)
		|
		|ORDER BY
		|	Presentation";
		
		Query.SetParameter("SectionRef", ParentOrSectionReference);
		
	Else
		
		QueryText =
		"SELECT DISTINCT
		|	PurposeTable.Ref
		|INTO vtRefs
		|FROM
		|	Catalog.AdditionalReportsAndDataProcessors.Purpose AS PurposeTable
		|		INNER JOIN Catalog.AdditionalReportsAndDataProcessors AS AdditReportsAndDataProcessors
		|		ON (PurposeTable.TargetObject = &ParentRef)
		|			AND PurposeTable.Ref = AdditReportsAndDataProcessors.Ref
		|			AND (AdditReportsAndDataProcessors.DeletionMark = FALSE)
		|			AND (AdditReportsAndDataProcessors.Kind = &Kind)
		|			AND (AdditReportsAndDataProcessors.Publication = &Publication)
		|			AND (AdditReportsAndDataProcessors.UseForListForm = TRUE)
		|			AND (AdditReportsAndDataProcessors.UseForObjectForm = TRUE)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CommandsTable.Ref,
		|	CommandsTable.ID,
		|	CommandsTable.RunningVariant,
		|	CommandsTable.Presentation AS Presentation,
		|	CommandsTable.ShowNotification,
		|	CommandsTable.Modifier
		|FROM
		|	vtRefs AS ReferencesTable
		|		INNER JOIN Catalog.AdditionalReportsAndDataProcessors.Commands AS CommandsTable
		|		ON ReferencesTable.Ref = CommandsTable.Ref
		|			AND (CommandsTable.Hide = FALSE)
		|
		|ORDER BY
		|	Presentation";
		
		Query.SetParameter("ParentRef", ParentOrSectionReference);
		
		// Disabling filters by list and object form
		If IsObjectForm <> True Then
			QueryText = StrReplace(QueryText, "AND (AdditReportsAndDataProcessors.UseForObjectForm = TRUE)", "");
		EndIf;
		If IsObjectForm <> False Then
			QueryText = StrReplace(QueryText, "AND (AdditReportsAndDataProcessors.UseForListForm = TRUE)", "");
		EndIf;
	EndIf;
	
	Query.SetParameter("Kind", DataProcessorKind);
	If Users.RolesAvailable("AddEditAdditionalReportsAndDataProcessors") Then
		QueryText = StrReplace(QueryText, "Publication = &Publication", "Publication <> &Publication");
		Query.SetParameter("Publication", Enums.AdditionalReportsAndDataProcessorsPublicationVariants.Disabled);
	Else
		Query.SetParameter("Publication", Enums.AdditionalReportsAndDataProcessorsPublicationVariants.Used);
	EndIf;
	Query.SetParameter("CurrentUser", Users.CurrentUser());
	Query.Text = QueryText;
	
	Return Query;
EndFunction

// Determines a list of metadata objects to which an assignable data processor of the specified kind can be applied.
//
// Parameters:
//   Kind - EnumRef.AdditionalReportAndDataProcessorKinds - external data processor kind.
//
// Returns: 
//   Undefined - if invalid Kind is passed.
//   ValueTable - metadata object description.
//       * MetadataObjectFullName - String - full name of a metadata object (example: Catalog.Currencies).
//       * TargetObject - CatalogRef.MetadataObjectIDs - metadata object reference.
//       * MetadataObjectKind - String - metadata object kind.
//       * Presentation - String - metadata object presentation.
//       * FullPresentation - String - presentation of metadata object name and kind.
//
Function AssignableMetadataObjectByExternalObjectKind(Kind) Export
	Purpose = New ValueTable;
	Purpose.Columns.Add("MetadataObject");
	Purpose.Columns.Add("MetadataObjectFullName", New TypeDescription("String"));
	Purpose.Columns.Add("TargetObject", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	Purpose.Columns.Add("MetadataObjectKind", New TypeDescription("String"));
	Purpose.Columns.Add("Presentation", New TypeDescription("String"));
	Purpose.Columns.Add("FullPresentation", New TypeDescription("String"));
	
	TypeOrMetadataArray = New Array;
	
	If Kind = Enums.AdditionalReportAndDataProcessorKinds.ObjectFilling Then
		
		TypeOrMetadataArray = Metadata.CommonCommands.ObjectFilling.CommandParameterType.Types();
		
	ElsIf Kind = Enums.AdditionalReportAndDataProcessorKinds.Report Then
		
		TypeOrMetadataArray = Metadata.CommonCommands.ObjectReports.CommandParameterType.Types();
		
	ElsIf Kind = Enums.AdditionalReportAndDataProcessorKinds.PrintForm Then
		
		TypeOrMetadataArray = Metadata.CommonCommands.AdditionalObjectPrintForms.CommandParameterType.Types();
		
	ElsIf Kind = Enums.AdditionalReportAndDataProcessorKinds.RelatedObjectCreation Then
		
		TypeOrMetadataArray = Metadata.CommonCommands.RelatedObjectCreation.CommandParameterType.Types();
		
	ElsIf Kind = Enums.AdditionalReportAndDataProcessorKinds.AdditionalDataProcessor Then
		
		TypeOrMetadataArray = AdditionalDataProcessorSections();
		
	ElsIf Kind = Enums.AdditionalReportAndDataProcessorKinds.AdditionalReport Then
		
		TypeOrMetadataArray = AdditionalReportSections();
		
	Else
		
		Return Undefined;
		
	EndIf;
	
	For Each TypeOrMetadata In TypeOrMetadataArray Do
		If TypeOf(TypeOrMetadata) = Type("Type") Then
			MetadataObject = Metadata.FindByType(TypeOrMetadata);
			If MetadataObject = Undefined Then
				Continue;
			EndIf;
		Else
			MetadataObject = TypeOrMetadata;
		EndIf;
		
		NewPurpose = Purpose.Add();
		
		If MetadataObject = AdditionalReportsAndDataProcessorsClientServer.DesktopID() Then
			NewPurpose.MetadataObjectFullName = AdditionalReportsAndDataProcessorsClientServer.DesktopID();
			NewPurpose.TargetObject = Catalogs.MetadataObjectIDs.EmptyRef();
			NewPurpose.MetadataObjectKind = "Subsystem";
			NewPurpose.Presentation = NStr("en = 'Desktop'");
		Else
			NewPurpose.MetadataObjectFullName = MetadataObject.FullName();
			NewPurpose.TargetObject = CommonUse.MetadataObjectID(MetadataObject);
			NewPurpose.MetadataObjectKind = Left(NewPurpose.MetadataObjectFullName, Find(NewPurpose.MetadataObjectFullName, ".") - 1);
			NewPurpose.Presentation = MetadataObject.Presentation();
		EndIf;
		
		NewPurpose.FullPresentation = NewPurpose.Presentation + " (" + NewPurpose.MetadataObjectKind + ")";
	EndDo;
	
	Return Purpose;
EndFunction

// Returns True when the specified additional report (data processor) kind is global.
//
// Parameters:
//   Kind - EnumRef.AdditionalReportAndDataProcessorKinds - external data processor kind.
//
// Returns: 
//    True, if the data processor is global.
//    False, if the data processor is assignable.
//
Function IsGlobalDataProcessor(Kind) Export
	
	Return Kind = Enums.AdditionalReportAndDataProcessorKinds.AdditionalDataProcessor
		Or Kind = Enums.AdditionalReportAndDataProcessorKinds.AdditionalReport;
	
EndFunction

// Transforms an additional report (data processor) kind from string constant to an enumeration reference.
//
// Parameters:
//   StringPresentation - String - string presentation of the kind.
//
// Returns: 
//   EnumRef.AdditionalReportAndDataProcessorKinds - kind reference.
//
Function GetDataProcessorKindByKindStringPresentation(StringPresentation) Export
	
	If StringPresentation = AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindObjectFilling() Then
		Return Enums.AdditionalReportAndDataProcessorKinds.ObjectFilling;
	ElsIf StringPresentation = AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindReport() Then
		Return Enums.AdditionalReportAndDataProcessorKinds.Report;
	ElsIf StringPresentation = AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindPrintForm() Then
		Return Enums.AdditionalReportAndDataProcessorKinds.PrintForm;
	ElsIf StringPresentation = AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindRelatedObjectCreation() Then
		Return Enums.AdditionalReportAndDataProcessorKinds.RelatedObjectCreation;
	ElsIf StringPresentation = AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindAdditionalDataProcessor() Then
		Return Enums.AdditionalReportAndDataProcessorKinds.AdditionalDataProcessor;
	ElsIf StringPresentation = AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindAdditionalReport() Then
		Return Enums.AdditionalReportAndDataProcessorKinds.AdditionalReport;
	EndIf;
	
EndFunction

// Transforms an additional report (data processor) kind from an enumeration reference to a string constant.
Function KindToString(KindReference) Export
	
	If KindReference = Enums.AdditionalReportAndDataProcessorKinds.ObjectFilling Then
		Return AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindObjectFilling();
		
	ElsIf KindReference = Enums.AdditionalReportAndDataProcessorKinds.Report Then
		Return AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindReport();
		
	ElsIf KindReference = Enums.AdditionalReportAndDataProcessorKinds.PrintForm Then
		Return AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindPrintForm();
		
	ElsIf KindReference = Enums.AdditionalReportAndDataProcessorKinds.RelatedObjectCreation Then
		Return AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindRelatedObjectCreation();
		
	ElsIf KindReference = Enums.AdditionalReportAndDataProcessorKinds.AdditionalDataProcessor Then
		Return AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindAdditionalDataProcessor();
		
	ElsIf KindReference = Enums.AdditionalReportAndDataProcessorKinds.AdditionalReport Then
		Return AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindAdditionalReport();
		
	Else
		Return "";
	EndIf;
	
EndFunction

// Returns a command desktop name.
Function SectionPresentation(Section) Export
	If Section = AdditionalReportsAndDataProcessorsClientServer.DesktopID()
		Or Section = Catalogs.MetadataObjectIDs.EmptyRef() Then
		Return NStr("en = 'Desktop'");
	EndIf;
	
	If TypeOf(Section) = Type("CatalogRef.MetadataObjectIDs") Then
		SectionPresentation = Section.Synonym;
	ElsIf TypeOf(Section) = Type("MetadataObject") Then
		SectionPresentation = Section.Presentation();
	Else
		SectionPresentation = Metadata.Subsystems.Find(Section).Presentation();
	EndIf;
	
	Return StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en = 'Section ""%1""'"), 
		SectionPresentation);
EndFunction

// Function used to add additional data processor commands to a personal command list.
Procedure AddCommandToOwnedCommandList(CommandArray) Export
	
	For Each StringItem In CommandArray Do
		Record = InformationRegisters.DataProcessorAccessUserSettings.CreateRecordManager();
		
		Record.AdditionalReportOrDataProcessor  = StringItem.DataProcessor;
		Record.CommandID                        = StringItem.ID;
		Record.User                             = Users.CurrentUser();
		Record.Available                        = True;
		
		Record.Write(True);
	EndDo;
	
EndProcedure

// Function used to remove additional data processor commands from a personal command list.
Procedure RemoveCommandsFormOwnedCommandList(CommandArray) Export
	
	For Each StringItem In CommandArray Do
		
		Record = InformationRegisters.DataProcessorAccessUserSettings.CreateRecordManager();
		
		Record.AdditionalReportOrDataProcessor  = StringItem.DataProcessor;
		Record.CommandID                        = StringItem.ID;
		Record.User                             = Users.CurrentUser();
		
		Record.Read();
		
		Record.Delete();
		
	EndDo;
	
EndProcedure

// Checks whether integration with the report option storage subsystem is enabled.
Function IntegrationWithReportOptionsUsed() Export
	Return Metadata.SettingsStorages.Find("ReportVariantsStorage") <> Undefined;
EndFunction

// Verifies right to add additional reports and data processors.
Function AddRight(Val AdditionalDataProcessor = Undefined) Export
	
	Result = False;
	StandardProcessing = True;
	
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.AdditionalReportsAndDataProcessors\OnCheckAddRight");
	
	For Each Handler In EventHandlers Do
		Handler.Module.OnCheckAddRight(AdditionalDataProcessor, Result, StandardProcessing);
		
		If Not StandardProcessing Then
			Return Result;
		EndIf;
		
	EndDo;
	
	If StandardProcessing Then
		
		If CommonUseCached.DataSeparationEnabled() And CommonUse.UseSessionSeparator() Then
			Result = Users.InfobaseUserWithFullAccess(, True);
		Else
			Result = Users.RolesAvailable("AddEditAdditionalReportsAndDataProcessors");
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Checks whether an additional report or data processor can be exported to file.
//
// Parameters:
//   Processing - CatalogRef.AdditionalReportsAndDataProcessors.
//
// Returns:
//   Boolean.
//
Function CanExportDataProcessorToFile(Val Processing) Export
	
	Result = False;
	StandardProcessing = True;
	
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.AdditionalReportsAndDataProcessors\OnCheckCanExportDataProcessorToFile");
	
	For Each Handler In EventHandlers Do
		Handler.Module.OnCheckCanExportDataProcessorToFile(Processing, Result, StandardProcessing);
		
		If Not StandardProcessing Then
			Return Result;
		EndIf;
		
	EndDo;
	
	If StandardProcessing Then
		Return True;
	EndIf;
	
EndFunction

// Checks whether an additional data processor can be imported from file.
//
// Parameters:
//   Processing - CatalogRef.AdditionalReportsAndDataProcessors.
//
// Returns:
//   Boolean.
//
Function CanImportDataProcessorFromFile(Val Processing) Export
	
	Result = False;
	StandardProcessing = True;
	
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.AdditionalReportsAndDataProcessors\OnCheckCanImportDataProcessorFromFile");
	
	For Each Handler In EventHandlers Do
		Handler.Module.OnCheckCanImportDataProcessorFromFile(Processing, Result, StandardProcessing);
		
		If Not StandardProcessing Then
			Return Result;
		EndIf;
		
	EndDo;
	
	If StandardProcessing Then
		Return True;
	EndIf;
	
EndFunction

// Returns a flag specifying whether extended information on additional reports and data processors must be displayed to user.
//
// Parameters:
//   Processing - CatalogRef.AdditionalReportsAndDataProcessors.
//
// Returns:
//   Boolean.
//
Function ShowExtendedInformation(Val Processing) Export
	
	Return True;
	
EndFunction

// Publication kinds unavailable for use in the current application mode.
Function UnavailablePublicationKinds() Export
	
	Result = New Array;
	
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.AdditionalReportsAndDataProcessors\OnFillUnavailablePublicationKinds");
	
	For Each Handler In EventHandlers Do
		Handler.Module.OnFillUnavailablePublicationKinds(Result);
	EndDo;
	
	Return Result;
	
EndFunction

// The procedure is called from the BeforeWrite event of AdditionalReportsAndDataProcessors catalog. 
// Validates changes to the catalog item attributes for additional data processors 
// retrieved from the service manager's additional data processors catalog.
//
// Parameters:
//   Source - CatalogObject.AdditionalReportsAndDataProcessors.
//   Cancel - Boolean - flag specifying whether catalog item write action must be cancelled.
//
Procedure BeforeWriteAdditionalDataProcessor(Source, Cancel) Export
	
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.AdditionalReportsAndDataProcessors\BeforeWriteAdditionalDataProcessor");
	
	For Each Handler In EventHandlers Do
		
		Handler.Module.BeforeWriteAdditionalDataProcessor(Source, Cancel);
		
	EndDo;
	
EndProcedure

// The procedure is called from the BeforeDelete event of AdditionalReportsAndDataProcessors catalog.
//
// Parameters:
//  Source - CatalogObject.AdditionalReportsAndDataProcessors.
//  Cancel - Boolean - flag specifying whether catalog item delete action must be cancelled.
//
Procedure BeforeDeleteAdditionalDataProcessor(Source, Cancel) Export
	
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.AdditionalReportsAndDataProcessors\BeforeDeleteAdditionalDataProcessor");
	
	For Each Handler In EventHandlers Do
		
		Handler.Module.BeforeDeleteAdditionalDataProcessor(Source, Cancel);
		
	EndDo;
	
EndProcedure

// Writing an error to event log dedicated to the additional report (data processor)
Procedure WriteError(Ref, MessageText, Attribute1 = Undefined, Attribute2 = Undefined, Attribute3 = Undefined) Export
	Level = EventLogLevel.Error;
	WriteToLog(Level, Ref, MessageText, Attribute1, Attribute2, Attribute3);
EndProcedure

// Writing a warning to event log dedicated to the additional report (data processor)
Procedure WriteWarning(Ref, MessageText, Attribute1 = Undefined, Attribute2 = Undefined, Attribute3 = Undefined) Export
	Level = EventLogLevel.Warning;
	WriteToLog(Level, Ref, MessageText, Attribute1, Attribute2, Attribute3);
EndProcedure

// Writing information to event log dedicated to the additional report (data processor)
Procedure WriteInformation(Ref, MessageText, Attribute1 = Undefined, Attribute2 = Undefined, Attribute3 = Undefined) Export
	Level = EventLogLevel.Information;
	WriteToLog(Level, Ref, MessageText, Attribute1, Attribute2, Attribute3);
EndProcedure

// Writing a comment to event log dedicated to the additional report (data processor)
Procedure WriteComment(Ref, MessageText, Attribute1 = Undefined, Attribute2 = Undefined, Attribute3 = Undefined) Export
	Level = EventLogLevel.Note;
	WriteToLog(Level, Ref, MessageText, Attribute1, Attribute2, Attribute3);
EndProcedure

// Writing an event to event log dedicated to the additional report (data processor)
Procedure WriteToLog(Level, Ref, MessageText, Attribute1, Attribute2, Attribute3)
	WriteLogEvent(
		AdditionalReportsAndDataProcessorsClientServer.SubsystemDescription(Undefined),
		Level,
		Metadata.Catalogs.AdditionalReportsAndDataProcessors,
		Ref,
		StringFunctionsClientServer.SubstituteParametersInString(
			MessageText,
			String(Attribute1),
			String(Attribute2),
			String(Attribute3)));
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Local internal procedures and functions

// Displays the filling commands in object forms.
Procedure CreateFillingCommandsSubmenu(Form, Parameters)
	
	QueryText =
	"SELECT DISTINCT
	|	AdditionalReportsAndDataProcessorsPurpose.Ref
	|INTO vtRefs
	|FROM
	|	Catalog.AdditionalReportsAndDataProcessors.Purpose AS AdditionalReportsAndDataProcessorsPurpose
	|WHERE
	|	AdditionalReportsAndDataProcessorsPurpose.TargetObject = &TargetObject
	|	AND AdditionalReportsAndDataProcessorsPurpose.Ref.Kind = &Kind
	|	AND AdditionalReportsAndDataProcessorsPurpose.Ref.UseForObjectForm = TRUE
	|	AND AdditionalReportsAndDataProcessorsPurpose.Ref.Publication = &Publication
	|	AND AdditionalReportsAndDataProcessorsPurpose.Ref.DeletionMark = FALSE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AdditionalReportsAndDataProcessorsCommands.Ref,
	|	AdditionalReportsAndDataProcessorsCommands.ID,
	|	AdditionalReportsAndDataProcessorsCommands.RunningVariant,
	|	AdditionalReportsAndDataProcessorsCommands.Presentation AS Presentation,
	|	AdditionalReportsAndDataProcessorsCommands.ShowNotification,
	|	AdditionalReportsAndDataProcessorsCommands.Modifier,
	|	AdditionalReportsAndDataProcessorsCommands.Ref.Kind
	|FROM
	|	vtRefs AS vtRefs
	|		INNER JOIN Catalog.AdditionalReportsAndDataProcessors.Commands AS AdditionalReportsAndDataProcessorsCommands
	|		ON vtRefs.Ref = AdditionalReportsAndDataProcessorsCommands.Ref
	|
	|ORDER BY
	|	Presentation";
	
	Query = New Query;
	Query.SetParameter("TargetObject", Parameters.ParentRef);
	Query.SetParameter("Kind", Enums.AdditionalReportAndDataProcessorKinds.ObjectFilling);
	Query.SetParameter("RunningVariant", Enums.AdditionalDataProcessorCallMethods.FormFilling);
	If Users.RolesAvailable("AddEditAdditionalReportsAndDataProcessors") Then
		QueryText = StrReplace(QueryText, "Publication = &Publication", "Publication <> &Publication");
		Query.SetParameter("Publication", Enums.AdditionalReportsAndDataProcessorsPublicationVariants.Disabled);
	Else
		Query.SetParameter("Publication", Enums.AdditionalReportsAndDataProcessorsPublicationVariants.Used);
	EndIf;
	Query.Text = QueryText;
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	// Determining a group to add the commands to
	Items = Form.Items;
	
	PredefinedCommands = New Array;
	Submenu = Items.Find("AdditionalFillingDataProcessorsSubmenu");
	If Submenu = Undefined Then
		CommandBar = Items.Find("CommandBar");
		If CommandBar = Undefined Then
			CommandBar = Form.CommandBar;
		EndIf;
		Submenu = Items.Insert("AdditionalFillingDataProcessorsSubmenu", Type("FormGroup"), CommandBar);
	Else
		For Each Item In Submenu.ChildItems Do
			PredefinedCommands.Add(Item);
		EndDo;
	EndIf;
	Submenu.Title = NStr("en = 'Fill'");
	Submenu.Type = FormGroupType.Popup;
	Submenu.Picture = PictureLib.FillForm;
	Submenu.Representation = ButtonRepresentation.PictureAndText;
	
	// Attributes
	AttributesToBeAdded = New Array;
	
	TableName = "AdditionalDataProcessorCommands";
	AttributesToBeAdded.Add(New FormAttribute(TableName, New TypeDescription("ValueTable")));
	AttributesToBeAdded.Add(New FormAttribute("Ref", New TypeDescription("CatalogRef.AdditionalReportsAndDataProcessors"), TableName));
	AttributesToBeAdded.Add(New FormAttribute("RunningVariant", New TypeDescription("EnumRef.AdditionalDataProcessorCallMethods"), TableName));
	AttributesToBeAdded.Add(New FormAttribute("ItemName", New TypeDescription("String"), TableName));
	AttributesToBeAdded.Add(New FormAttribute("ShowNotification", New TypeDescription("Boolean"), TableName));
	AttributesToBeAdded.Add(New FormAttribute("Presentation", New TypeDescription("String"), TableName));
	AttributesToBeAdded.Add(New FormAttribute("ID", New TypeDescription("String"), TableName));
	AttributesToBeAdded.Add(New FormAttribute("IsReport", New TypeDescription("Boolean"), TableName));
	
	Form.ChangeAttributes(AttributesToBeAdded);
	
	// Adding commands and command items
	ItemNumber = 0;
	
	Selection = Result.Select();
	While Selection.Next() Do
		ItemNumber = ItemNumber + 1;
		ItemName = "AdditionalDataProcessorCommand" + Format(ItemNumber, "NG=");
		
		TableRow = Form.AdditionalDataProcessorCommands.Add();
		FillPropertyValues(TableRow, Selection);
		TableRow.ItemName = ItemName;
		
		Command = Form.Commands.Add(ItemName);
		Command.Action  = "Attachable_ExecuteAssignableCommand";
		Command.Title = TableRow.Presentation;
		
		Item = Form.Items.Add(ItemName, Type("FormButton"), Submenu);
		Item.CommandName = ItemName;
		Item.OnlyInAllActions = False;
	EndDo;
	
	For Each Item In PredefinedCommands Do
		Items.Move(Item, Submenu);
	EndDo;
	
EndProcedure

// For internal use
Function GetRecordTable(UsersWithAdditionalDataProcessors)
	
	QueryText =
	"SELECT
	|	AdditionalReportsAndDataProcessors.Ref AS Processing,
	|	AdditionalReportAndDataProcessorCommands.ID AS ID
	|FROM
	|	Catalog.AdditionalReportsAndDataProcessors AS AdditionalReportsAndDataProcessors
	|		INNER JOIN Catalog.AdditionalReportsAndDataProcessors.Commands AS AdditionalReportAndDataProcessorCommands
	|		ON (AdditionalReportAndDataProcessorCommands.Ref = AdditionalReportsAndDataProcessors.Ref)";
	
	Query = New Query;
	Query.Text = QueryText;
	DataProcessorsWithCommands = Query.Execute().Unload();
	
	RecordTable = New ValueTable;
	RecordTable.Columns.Add("Processing",     New TypeDescription("CatalogRef.AdditionalReportsAndDataProcessors"));
	RecordTable.Columns.Add("ID", New TypeDescription("String"));
	RecordTable.Columns.Add("User",  New TypeDescription("CatalogRef.Users"));
	RecordTable.Columns.Add("Available",      New TypeDescription("Boolean"));
	
	For Each DataProcessorCommand In DataProcessorsWithCommands Do
		For Each User In UsersWithAdditionalDataProcessors Do
			NewRow = RecordTable.Add();
			NewRow.Processing     = DataProcessorCommand.Processing;
			NewRow.ID = DataProcessorCommand.ID;
			NewRow.User  = User;
			NewRow.Available   = True;
		EndDo;
	EndDo;
	
	QueryText =
	"SELECT
	|	AdditionalReportsAndDataProcessors.Ref AS Processing,
	|	AdditionalReportAndDataProcessorCommands.ID AS ID,
	|	Users.Ref AS User,
	|	DataProcessorAccessUserSettings.Available AS Available
	|FROM
	|	Catalog.AdditionalReportsAndDataProcessors AS AdditionalReportsAndDataProcessors
	|		INNER JOIN Catalog.AdditionalReportsAndDataProcessors.Commands AS AdditionalReportAndDataProcessorCommands
	|		ON (AdditionalReportAndDataProcessorCommands.Ref = AdditionalReportsAndDataProcessors.Ref)
	|		INNER JOIN InformationRegister.DataProcessorAccessUserSettings AS DataProcessorAccessUserSettings
	|		ON (DataProcessorAccessUserSettings.AdditionalReportOrDataProcessor = AdditionalReportsAndDataProcessors.Ref)
	|			AND (DataProcessorAccessUserSettings.CommandID = AdditionalReportAndDataProcessorCommands.ID)
	|		INNER JOIN Catalog.Users AS Users
	|		ON (Users.Ref = DataProcessorAccessUserSettings.User)";
	
	Query = New Query;
	Query.Text = QueryText;
	PersonalAccessExceptions = Query.Execute().Unload();
	
	StringSearch = New Structure("DataProcessor, ID, User");
	For Each PersonalAccessException In PersonalAccessExceptions Do
		FillPropertyValues(StringSearch, PersonalAccessException);
		Found = RecordTable.FindRows(StringSearch);
		For Each TableRow In Found Do
			TableRow.Available = Not PersonalAccessException.Available; // Inverting access exception
		EndDo; 
	EndDo;
	
	Return RecordTable;
	
EndFunction

// For internal use
Function GetArrayOfUsersWithAccessToAddtionalDataProcessors()
	
	Result = New Array;
	
	RolesToCheck = "UseAdditionalReportsAndDataProcessors, AddEditAdditionalReportsAndDataProcessors";
	
	Query = New Query("SELECT Ref FROM Catalog.Users");
	AllUsers = Query.Execute().Unload().UnloadColumn("Ref");
	
	For Each User In AllUsers Do
		If Users.RolesAvailable(RolesToCheck, User, False) Then
			Result.Add(User);
		EndIf;
	EndDo;
	
	QueryText =
	"SELECT DISTINCT
	|	AccessSettings.User
	|FROM
	|	InformationRegister.DataProcessorAccessUserSettings AS AccessSettings
	|WHERE
	|	Not AccessSettings.User IN (&UsersAddedEarlier)";
	
	Query = New Query(QueryText);
	Query.Parameters.Insert("UsersAddedEarlier", Result);
	UsersInRegister = Query.Execute().Unload().UnloadColumn("User");
	
	For Each User In UsersInRegister Do
		Result.Add(User);
	EndDo;
	
	Return Result;
	
EndFunction

// For internal use
Procedure ExecuteAdditionalReportOrDataProcessorCommand(ExternalObject, Val CommandID, CommandParameters, Val ScenarioInSafeMode = False)
	
	If ScenarioInSafeMode Then
		
		ExecuteScenarioInSafeMode(ExternalObject, CommandParameters);
		
	Else
		
		If CommandParameters = Undefined Then
			
			ExternalObject.ExecuteCommand(CommandID);
			
		Else
			
			ExternalObject.ExecuteCommand(CommandID, CommandParameters);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// For internal use
Procedure ExecuteAssignableAdditionalReportOrDataProcessorCommand(ExternalObject, Val CommandID, CommandParameters, TargetObjects, Val ScenarioInSafeMode = False)
	
	If ScenarioInSafeMode Then
		
		ExecuteScenarioInSafeMode(ExternalObject, CommandParameters, TargetObjects);
		
	Else
		
		If CommandParameters = Undefined Then
			ExternalObject.ExecuteCommand(CommandID, TargetObjects);
		Else
			ExternalObject.ExecuteCommand(CommandID, TargetObjects, CommandParameters);
		EndIf;
		
	EndIf;
	
EndProcedure

// For internal use
Procedure ExecuteRelatedObjectCreationCommand(ExternalObject, Val CommandID, CommandParameters, TargetObjects, ModifiedObjects, Val ScenarioInSafeMode = False)
	
	If ScenarioInSafeMode Then
		
		CommandParameters.Insert("ModifiedObjects", ModifiedObjects);
		
		ExecuteScenarioInSafeMode(ExternalObject, CommandParameters, TargetObjects);
		
	Else
		
		If CommandParameters = Undefined Then
			ExternalObject.ExecuteCommand(CommandID, TargetObjects, ModifiedObjects);
		Else
			ExternalObject.ExecuteCommand(CommandID, TargetObjects, ModifiedObjects, CommandParameters);
		EndIf;
		
	EndIf;
	
EndProcedure

// For internal use
Procedure ExecutePrintFormCreationCommand(ExternalObject, Val CommandID, CommandParameters, TargetObjects, Val ScenarioInSafeMode = False)
	
	If ScenarioInSafeMode Then
		
		ExecuteScenarioInSafeMode(ExternalObject, CommandParameters, TargetObjects);
		
	Else
		
		If CommandParameters = Undefined Then
			ExternalObject.Print(CommandID, TargetObjects);
		Else
			ExternalObject.Print(CommandID, TargetObjects, CommandParameters);
		EndIf;
		
	EndIf;
	
EndProcedure

// Executes an additional report (data processor) command for an object.
Function ExecuteExternalObjectCommand(ExternalObject, CommandID, CommandParameters, ResultAddress)
	
	ExternalObjectInformation = ExternalObject.ExternalDataProcessorInfo();
	
	DataProcessorKind = GetDataProcessorKindByKindStringPresentation(ExternalObjectInformation.Kind);
	
	PassParameters = (
		ExternalObjectInformation.Property("SLVersion")
		And CommonUseClientServer.CompareVersions(ExternalObjectInformation.SLVersion, "1.2.1.4") >= 0);
	
	If Not CommandParameters.Property("ExecutionResult") Or TypeOf(CommandParameters.ExecutionResult) <> Type("Structure") Then
		CommandParameters.Insert("ExecutionResult", StandardSubsystemsClientServer.NewExecutionResult());
	EndIf;
	
	CommandDescription = ExternalObjectInformation.Commands.Find(CommandID, "ID");
	If CommandDescription = Undefined Then
		
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Command %1 is not found.'"), CommandID);
		
	EndIf;
	IsScenarioInSafeMode = (CommandDescription.Use = "ScenarioInSafeMode");
	
	ModifiedObjects = Undefined;
	
	If DataProcessorKind = Enums.AdditionalReportAndDataProcessorKinds.AdditionalDataProcessor
		Or DataProcessorKind = Enums.AdditionalReportAndDataProcessorKinds.AdditionalReport Then
		
		ExecuteAdditionalReportOrDataProcessorCommand(
			ExternalObject, CommandID,
			?(PassParameters, CommandParameters, Undefined),
			IsScenarioInSafeMode);
		
	ElsIf DataProcessorKind = Enums.AdditionalReportAndDataProcessorKinds.RelatedObjectCreation Then
		
		ModifiedObjects = New Array;
		ExecuteRelatedObjectCreationCommand(
			ExternalObject, CommandID,
			?(PassParameters, CommandParameters, Undefined),
			CommandParameters.TargetObjects,
			ModifiedObjects,
			IsScenarioInSafeMode);
		
	ElsIf DataProcessorKind = Enums.AdditionalReportAndDataProcessorKinds.ObjectFilling
		Or DataProcessorKind = Enums.AdditionalReportAndDataProcessorKinds.Report
		Or DataProcessorKind = Enums.AdditionalReportAndDataProcessorKinds.PrintForm Then
		
		TargetObjects = Undefined;
		CommandParameters.Property("TargetObjects", TargetObjects);
		
		If DataProcessorKind = Enums.AdditionalReportAndDataProcessorKinds.PrintForm Then
			
			// Only arbitrary printing here. MXL printing is performed through the Print subsystem.
			ExecutePrintFormCreationCommand(
				ExternalObject, CommandID,
				?(PassParameters, CommandParameters, Undefined),
				TargetObjects,
				IsScenarioInSafeMode);
			
		Else
			
			ExecuteAssignableAdditionalReportOrDataProcessorCommand(
				ExternalObject, CommandID,
				?(PassParameters, CommandParameters, Undefined),
				TargetObjects,
				IsScenarioInSafeMode);
			
			If DataProcessorKind = Enums.AdditionalReportAndDataProcessorKinds.ObjectFilling Then
				ModifiedObjects = TargetObjects;
			EndIf;
		EndIf;
		
	EndIf;
	
	StandardSubsystemsClientServer.PrepareDynamicListNotification(ModifiedObjects, CommandParameters.ExecutionResult);
	
	If TypeOf(ResultAddress) = Type("String") And IsTempStorageURL(ResultAddress) Then
		PutToTempStorage(CommandParameters.ExecutionResult, ResultAddress);
		Return Undefined;
	EndIf;
	
	Return CommandParameters.ExecutionResult;
	
EndFunction

// For internal use
Procedure ExecuteScenarioInSafeMode(ExternalObject, CommandParameters, TargetObjects = Undefined)
	
	SafeModeExtension = AdditionalReportsAndDataProcessorsSafeModeInternal;
	
	ExternalObject = GetExternalDataProcessorsObject(CommandParameters.AdditionalDataProcessorRef);
	CommandID = CommandParameters.CommandID;
	
	Scenario = ExternalObject.GenerateScenario(CommandID, CommandParameters);
	SessionKey = AdditionalReportsAndDataProcessorsSafeModeInternal.GenerateSafeModeExtensionSessionKey(
		CommandParameters.AdditionalDataProcessorRef);
	
	SafeModeExtension.ExecuteSafeModeScenario(
		SessionKey, Scenario, ExternalObject, CommandParameters, Undefined, TargetObjects);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Other

// For internal use
Function RegisterDataProcessor(Val Object, Val RegistrationParameters) Export
	
	KindAdditionalDataProcessor = Enums.AdditionalReportAndDataProcessorKinds.AdditionalDataProcessor;
	KindAdditionalReport     = Enums.AdditionalReportAndDataProcessorKinds.AdditionalReport;
	ReportKind                   = Enums.AdditionalReportAndDataProcessorKinds.Report;
	
	// Gets a data processor file from temporary storage, attempts to create an external 
	// data processor (report) object, gets information from the external data processor (report) object.
	
	If RegistrationParameters.DisableConflicts Then
		For Each ListItem In RegistrationParameters.Conflicting Do
			ConflictingObject = ListItem.Value.GetObject();
			ConflictingObject.Publication = AdditionalReportsAndDataProcessorsCached.AllPublicationsForConflictingDataProcessors();
			ConflictingObject.Write();
		EndDo;
	ElsIf RegistrationParameters.DisablePublication Then 
		Object.Publication = AdditionalReportsAndDataProcessorsCached.AllPublicationsForConflictingDataProcessors();
	EndIf;
	
	Result = New Structure("ObjectName, StandardObjectName, Success, ObjectNameUsed, Conflicting, BriefErrorDescription");
	Result.ObjectNameUsed = False;
	Result.Success = False;
	If Object.IsNew() Then
		Result.StandardObjectName = Object.ObjectName;
	Else
		Result.StandardObjectName = CommonUse.ObjectAttributeValue(Object.Ref, "ObjectName");
	EndIf;
	
	Try
		RegistrationData = GetRegistrationData(Object, RegistrationParameters, Result);
		If RegistrationData = Undefined Then
			Return Result;
		EndIf;
	Except
		Result.BriefErrorDescription = BriefErrorDescription(ErrorInfo());
		Return Result;
	EndTry;
	// When an additional report is added, the name used to register the report in the application must be checked for uniqueness
	If Object.Publication = Enums.AdditionalReportsAndDataProcessorsPublicationVariants.Used Then
		// Checking the name
		QueryText =
		"SELECT
		|	CatalogTable.Ref,
		|	CatalogTable.Presentation
		|FROM
		|	Catalog.AdditionalReportsAndDataProcessors AS CatalogTable
		|WHERE
		|	CatalogTable.ObjectName = &ObjectName
		|	AND &AdditReportCondition
		|	AND CatalogTable.Publication = VALUE(Enum.AdditionalReportsAndDataProcessorsPublicationVariants.Used)
		|	AND CatalogTable.DeletionMark = FALSE
		|	AND CatalogTable.Ref <> &Ref";
		
		AdditionalReportKinds = New Array;
		AdditionalReportKinds.Add(KindAdditionalReport);
		AdditionalReportKinds.Add(ReportKind);
		
		Query = New Query;
		Query.SetParameter("ObjectName",     Result.ObjectName);
		Query.SetParameter("AdditionalReportKinds", AdditionalReportKinds);
		Query.SetParameter("Ref", Object.Ref);
		
		If RegistrationParameters.IsReport Then
			QueryText = StrReplace(QueryText, "&AdditReportCondition", "CatalogTable.Kind IN (&AdditionalReportKinds)");
		Else
			QueryText = StrReplace(QueryText, "&AdditReportCondition", "NOT CatalogTable.Kind IN (&AdditionalReportKinds)");
		EndIf;
		
		Query.Text = QueryText;
		
		SetPrivilegedMode(True);
		Conflicting = Query.Execute().Unload();
		SetPrivilegedMode(False);
		
		If Conflicting.Count() > 0 Then
			Result.ObjectNameUsed = True;
			Result.Conflicting = New ValueList;
			For Each TableRow In Conflicting Do
				Result.Conflicting.Add(TableRow.Ref, TableRow.Presentation);
			EndDo; 
			Return Result;
		EndIf;
	EndIf;
	
	If RegistrationData.SafeMode
		Or Users.InfobaseUserWithFullAccess(, True) Then
		// Doing nothing
	Else
		Result.BriefErrorDescription = NStr("en = 'Administrative rights are required to attach a data processor that runs in unsafe mode.'");
		Return Result;
	EndIf;
	
	If Not Object.IsNew() And RegistrationData.Kind <> Object.Kind Then
		Result.BriefErrorDescription = NStr("en = 'Cannot change the additional report (data processor) kind.'");
		Return Result;
	ElsIf RegistrationParameters.IsReport <> (RegistrationData.Kind = KindAdditionalReport Or RegistrationData.Kind = ReportKind) Then
		Result.BriefErrorDescription = NStr("en = 'Data processor kind specified in the external data processor information does not match the extension.'");
		Return Result;
	EndIf;
	
	Object.Description    = RegistrationData.Description;
	Object.Version        = RegistrationData.Version;
	
	If RegistrationData.Property("SLVersion") Then
		If CommonUseClientServer.CompareVersions(RegistrationData.SLVersion, "2.2.2.0") > 0 Then
			Object.PermissionCompatibilityMode = Enums.AdditionalReportsAndDataProcessorsPermissionCompatibilityModes.Version_2_2_2;
		Else
			Object.PermissionCompatibilityMode = Enums.AdditionalReportsAndDataProcessorsPermissionCompatibilityModes.Version_2_1_3;
		EndIf;
	Else
		Object.PermissionCompatibilityMode = Enums.AdditionalReportsAndDataProcessorsPermissionCompatibilityModes.Version_2_1_3;
	EndIf;
	
	If RegistrationData.Property("SafeMode") Then
		Object.SafeMode = RegistrationData.SafeMode;
	EndIf;
	
	Object.Information     = RegistrationData.Information;
	Object.FileName        = RegistrationParameters.FileName;
	Object.ObjectName      = Result.ObjectName;
	
	Object.UseOptionStorage = False;
	If (RegistrationData.Kind = KindAdditionalReport) Or (RegistrationData.Kind = ReportKind) Then
		If RegistrationData.VariantsStorage = "ReportVariantsStorage"
			Or (Metadata.ReportsVariantsStorage <> Undefined
				And Metadata.ReportsVariantsStorage.Name = "ReportVariantsStorage") Then
			Object.UseOptionStorage = True;
		EndIf;
	EndIf;
	
	// A different data processor is imported (object name or data processor kind was changed)
	If Object.IsNew() Or Object.ObjectName <> Result.ObjectName Or Object.Kind <> RegistrationData.Kind Then
		Object.Purpose.Clear();
		Object.Sections.Clear();
		Object.Kind = RegistrationData.Kind;
	EndIf;
	
	// If assignment is empty, copying assignment data from the data processor
	If Object.Purpose.Count() = 0
		And Object.Kind <> KindAdditionalReport
		And Object.Kind <> KindAdditionalDataProcessor Then
		
		If RegistrationData.Property("Purpose") Then
			AssignableMetadataObjects = AssignableMetadataObjectByExternalObjectKind(Object.Kind);
			
			For Each MetadataObjectFullName In RegistrationData.Purpose Do
				DotPosition = Find(MetadataObjectFullName, ".");
				If Mid(MetadataObjectFullName, DotPosition + 1) = "*" Then
					Search = New Structure("MetadataObjectKind", Left(MetadataObjectFullName, DotPosition - 1));
				Else
					Search = New Structure("MetadataObjectFullName", MetadataObjectFullName);
				EndIf;
				
				Found = AssignableMetadataObjects.FindRows(Search);
				For Each TableRow In Found Do
					PurposeRow = Object.Purpose.Add();
					PurposeRow.TargetObject = TableRow.TargetObject;
				EndDo;
			EndDo;
		EndIf;
		
		Object.Purpose.GroupBy("TargetObject", "");
		
	EndIf;
	
	Object.Commands.Clear();
	
	// Initializing commands
	
	For Each CommandDescription In RegistrationData.Commands Do
		
		If Not ValueIsFilled(CommandDescription.RunningVariant) Then
			CommonUseClientServer.MessageToUser(
				StrReplace(NStr("en = 'Start method is not specified for command %1.'"), "%1", CommandDescription.Presentation));
		EndIf;
		
		Command = Object.Commands.Add();
		FillPropertyValues(Command, CommandDescription);
		
	EndDo;
	
	// Reading permissions required by the additional data processor
	Object.Permissions.Clear();
	Permissions = Undefined;
	If RegistrationData.Property("Permissions", Permissions) Then
		
		For Each Permission In Permissions Do
			
			XDTOType = Permission.Type();
			
			TSRow = Object.Permissions.Add();
			TSRow.PermissionKind = XDTOType.Name;
			
			Parameters = New Structure();
			
			For Each XDTOProperty In XDTOType.Properties Do
				
				Container = Permission.GetXDTO(XDTOProperty.Name);
				
				If Container <> Undefined Then
					Parameters.Insert(XDTOProperty.Name, Container.Value);
				Else
					Parameters.Insert(XDTOProperty.Name);
				EndIf;
				
			EndDo;
			
			TSRow.Parameters = New ValueStorage(Parameters);
			
		EndDo;
		
	EndIf;
	
	Object.Responsible = Users.CurrentUser();
	
	Result.Success = True;
	
	Return Result;
	
EndFunction

// For internal use
Function GetRegistrationData(Val Object, Val RegistrationParameters, Val RegistrationResult)
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.AdditionalReportsAndDataProcessors\OnGetRegistrationData");
	
	RegistrationData = New Structure;
	
	StandardProcessing = True;
	
	For Each Handler In EventHandlers Do
		Handler.Module.OnGetRegistrationData(Object, RegistrationData, StandardProcessing);
	EndDo;
	
	If StandardProcessing Then
		OnGetRegistrationData(Object, RegistrationData, RegistrationParameters, RegistrationResult);
	EndIf;
	
	Return RegistrationData;
EndFunction

// For internal use
Procedure OnGetRegistrationData(Object, RegistrationData, RegistrationParameters, RegistrationResult)
	
	// Connecting, getting a name to be used when attaching the object
	Manager = ?(RegistrationParameters.IsReport, ExternalReports, ExternalDataProcessors);
	
	#If ThickClientOrdinaryApplication Then
		RegistrationResult.ObjectName = GetTempFileName();
		BinaryData = GetFromTempStorage(RegistrationParameters.DataProcessorDataAddress);
		BinaryData.Write(RegistrationResult.ObjectName);
	#Else
		RegistrationResult.ObjectName = TrimAll(Manager.Connect(RegistrationParameters.DataProcessorDataAddress, , True));
	#EndIf
	
	Try
		// Getting external data processor information
		ExternalObject = Manager.Create(RegistrationResult.ObjectName);
		ExternalObjectMetadata = ExternalObject.Metadata();
		
		ExternalDataProcessorInfo = ExternalObject.ExternalDataProcessorInfo();
		CommonUseClientServer.SupplementStructure(RegistrationData, ExternalDataProcessorInfo, True);
	Except
		If RegistrationParameters.IsReport Then
			ErrorText = NStr("en='Cannot attach an additional report from file.
			|It is probably incompatible with this application version.'");
		Else
			ErrorText = NStr("en='Cannot attach an additional data processor from file.
			|It is probably incompatible with this application version.'");
		EndIf;
		ErrorText = ErrorText + Chars.LF + Chars.LF + NStr("en = 'Technical information:'") + Chars.LF;
		WriteError(Object.Ref, ErrorText + DetailErrorDescription(ErrorInfo()));
		Raise ErrorText + BriefErrorDescription(ErrorInfo());
	EndTry;
	
	If RegistrationData.Description = Undefined Or RegistrationData.Information = Undefined Then
		If RegistrationData.Description = Undefined Then
			RegistrationData.Description = ExternalObjectMetadata.Presentation();
		EndIf;
		If RegistrationData.Information = Undefined Then
			RegistrationData.Information = ExternalObjectMetadata.Comment;
		EndIf;
	EndIf;
	
	If TypeOf(RegistrationData.Kind) <> Type("EnumRef.AdditionalReportAndDataProcessorKinds") Then
		RegistrationData.Kind = Enums.AdditionalReportAndDataProcessorKinds[RegistrationData.Kind];
	EndIf;
	
	RegistrationData.Insert("VariantsStorage");
	If RegistrationData.Kind = Enums.AdditionalReportAndDataProcessorKinds.AdditionalReport Then
		If ExternalObjectMetadata.VariantsStorage <> Undefined Then
			RegistrationData.VariantsStorage = ExternalObjectMetadata.VariantsStorage.Name;
		EndIf;
	EndIf;
	
	RegistrationData.Commands.Columns.Add("RunningVariant");
	
	For Each CommandDescription In RegistrationData.Commands Do
		CommandDescription.RunningVariant = Enums.AdditionalDataProcessorCallMethods[CommandDescription.Use];
	EndDo;
	
	#If ThickClientOrdinaryApplication Then
		RegistrationResult.ObjectName = ExternalObjectMetadata.Name;
	#EndIf
EndProcedure

// For internal use only
//
Function AdditionalReportsAndDataProcessorsCount() Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	AdditionalReportsAndDataProcessors.Description
	|FROM
	|	Catalog.AdditionalReportsAndDataProcessors AS AdditionalReportsAndDataProcessors";
	
	Result = Query.Execute().Unload();
	Return Result.Count();
	
EndFunction

#EndRegion