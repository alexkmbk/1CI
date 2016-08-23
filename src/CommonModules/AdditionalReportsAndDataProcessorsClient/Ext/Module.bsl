////////////////////////////////////////////////////////////////////////////////
// Additional reports and data processors subsystem.
// 
////////////////////////////////////////////////////////////////////////////////

#Region Interface

// Opens a form with available commands.
//
// Parameters:
//   CommandParameter         - It is passed "As is" from the handler of the command that calls this procedure.
//   CommandExecuteParameters - It is passed "As is" from the handler of the command that calls this procedure.
//   Kind                     - String - Data processor type that can be obtained from 
//                              AdditionalReportsAndDataProcessorsClientServer.DataProcessorKind<...>() function series.
//   SectionName              - String - Name of the interface section where the command is called.
//
Procedure OpenAdditionalReportAndDataProcessorCommandsForm(CommandParameter, CommandExecuteParameters, Kind, SectionName = "") Export
	
	TargetObjects = New ValueList;
	If TypeOf(CommandParameter) = Type("Array") Then // assignable data processor
		TargetObjects.LoadValues(CommandParameter);
	EndIf;
	
	Parameters = New Structure("TargetObjects, Kind, SectionName, WindowOpeningMode");
	Parameters.TargetObjects = TargetObjects;
	Parameters.Kind = Kind;
	Parameters.SectionName = SectionName;
	Parameters.WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
	
	If TypeOf(CommandExecuteParameters.Source) = Type("ManagedForm") Then // assignable data processor
		Parameters.Insert("FormName", CommandExecuteParameters.Source.FormName);
	EndIf;
	
	OpenForm(
		"CommonForm.AdditionalReportsAndDataProcessors", 
		Parameters,
		CommandExecuteParameters.Source);
	
EndProcedure

// Opens an additional report form with the specified report option.
//
// Parameters:
//   Ref        - CatalogRef.AdditionalReportsAndDataProcessors - additional report reference.
//   VariantKey - String - additional report option name.
//
Procedure OpenAdditionalReportOption(Ref, VariantKey) Export
	
	If TypeOf(Ref) <> Type("CatalogRef.AdditionalReportsAndDataProcessors") Then
		Return;
	EndIf;
	
	ReportName = AdditionalReportsAndDataProcessorsServerCall.AttachExternalDataProcessor(Ref);
	OpenParameters = New Structure("VariantKey", VariantKey);
	Uniqueness = "ExternalReport." + ReportName + "/VariantKey." + VariantKey;
	OpenForm("ExternalReport." + ReportName + ".Form", OpenParameters, Undefined, Uniqueness);
	
EndProcedure

// Starts a long action to run a command from an external report or data processor form.
//
// Parameters:
//   CommandID         - String - Command name as it is specified in ExternalDataProcessorInfo() function in the object module.
//   CommandParameters - Structure - command execution parameters. 
//     Mandatory parameters:
//       * AdditionalDataProcessorRef - CatalogRef.AdditionalReportsAndDataProcessors -
//                                    it is passed "As is" from the form parameters.
//     Optional parameters:
//       * AccompanyingText - String - long action text.
//       * Title            - String - long action title.
//       * TargetObjects   - Array - references to objects the command is executed for.
//                            It is used for assigned additional data processors.
//       * ExecutionResult  - Structure - see StandardSubsystemsClientServer.NewExecutionResult().
//     Internal parameters reserved by subsystem:
//       * CommandID        - String - name of the command that is executed.
//     The procedure can have custom parameters used in the command handler in addition to the mandatory parameters.
//     It is recommended that you add a prefix, such as "Context...", to custom parameter names 
//     to avoid exact matches with names introduced by Subsystems Library.
//   Form - ManagedForm - form that receives the result.
//
// Important:
//   The result is returned in ChoiceProcessing() handler.
//   Use the LongActionFormName() function for initial identification.
//   Note that background jobs are only available in client/server mode.
//   See the usage examples in the additional data processor in the demo infobase.
//
// Returns:
//   ExecutionResult - Structure - see StandardSubsystemsClientServer.NewExecutionResult().
//
// Command handler example:
//&AtClient
//Procedure CommandHandler(Command) 
//	CommandID = Command.Name;
//	CommandParameters = New Structure("AdditionalDataProcessorRef, AccompanyingText");
//	CommandParameters.AdditionalDataProcessorRef = ObjectRef;
//	CommandParameters.AccompanyingText = NStr("en = 'Command execution in progress...'");
//	State(CommandParameters.AccompanyingText);
//	If StandardSubsystemsServerCall.ClientParameters().FileInfobase Then
//		ExecutionResult = ExecuteCommandDirectly(CommandID, CommandParameters);
//		AdditionalReportsAndDataProcessorsClient.ShowCommandExecutionResult(ThisObject, ExecutionResult);
//	Else
//		AdditionalReportsAndDataProcessorsClient.ExecuteCommandInBackground(CommandID, CommandParameters, ThisObject);
//	EndIf;
//EndProcedure
//
// Example of direct command execution:
//&AtServer
//Function ExecuteCommandDirectly(CommandID, CommandParameters) 
//Return AdditionalReportsAndDataProcessors.RunCommandFromExternalObjectForm(CommandID, CommandParameters, ThisObject);
//EndFunction
//
// Selection handler example:
//&AtClient
//Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
//	If ChoiceSource.FormName = AdditionalReportsAndDataProcessorsClient.LongActionFormName() Then
//		AdditionalReportsAndDataProcessorsClient.ShowCommandExecutionResult(ThisObject, SelectedValue);
//	EndIf;
//EndProcedure
//
// Example of getting additional data processor reference:
//&AtServer
//Procedure OnCreateAtServer(Cancel, StandardProcessing) 
// ObjectRef = Parameters.AdditionalDataProcessorRef;
//EndProcedure
//
Procedure ExecuteCommandInBackground(CommandID, CommandParameters, Form) Export
	
	AdditionalDataProcessorRef = Undefined;
	CommandParameters.Property("AdditionalDataProcessorRef", AdditionalDataProcessorRef);
	IncorrectType = TypeOf(AdditionalDataProcessorRef) <> Type("CatalogRef.AdditionalReportsAndDataProcessors");
	If IncorrectType Or AdditionalDataProcessorRef = PredefinedValue("Catalog.AdditionalReportsAndDataProcessors.EmptyRef") Then
		
		ErrorText = NStr("en = 'Invalid AdditionalDataProcessorRef parameter value.'") + Chars.LF;
		If IncorrectType Then
			ErrorText = ErrorText + StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Passed type: %1, expected type: %2.'"),
				String(TypeOf(AdditionalDataProcessorRef)),
				String(Type("CatalogRef.AdditionalReportsAndDataProcessors")));
		Else
			ErrorText = ErrorText + NStr("en = 'The passed reference is empty. Probably the data processor was opened from the ""All functions"" menu.'");
		EndIf;
		
		Raise ErrorText;
		
	EndIf;
	
	CommandParameters.Insert("CommandID", CommandID);
	
	FormParameters = New Structure("BackgroundJobStartupParameters", CommandParameters);
	
	OpenForm(LongActionFormName(), FormParameters, Form);
	
EndProcedure

// Returns the form name that can be used for identification of a long action execution result.
//
// Returns:
//   String - See ExecuteCommandInBackground().
//
Function LongActionFormName() Export
	
	Return "CommonForm.LongAdditionalReportAndDataProcessorAction";
	
EndFunction

// Executes an assignable command on the client using only out-of-context server calls.
// Returns False if a server call is required to execute the command.
//
// Parameters:
//   Form     - ManagedForm - form where the command is called.
//   ItemName - String - name of the form command that is executed.
//
// Returns:
//   Boolean - Execution method.
//       True - Data processor command is executed out of the context.
//       False - A server call is required to execute the command.
//
Function ExecuteAssignableCommandAtClient(Form, ItemName) Export
	ClearMessages();
	
	Found = Form.AdditionalDataProcessorCommands.FindRows(New Structure("ItemName", ItemName));
	If Found.Count() = 0 Then
		Raise NStr("en = 'The command is not found'");
	EndIf;
	
	CommandToExecute = Found[0];
	
	If CommandToExecute.RunningVariant = PredefinedValue("Enum.AdditionalDataProcessorCallMethods.FormFilling") Then
		Return False; //  A server call is required to execute the command
	EndIf;
	
	Object = Form.Object;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form",  Form);
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("CommandToExecute", CommandToExecute);
	
	If Object.Ref.IsEmpty() Or Form.Modified Then
		QuestionText = StrReplace(
			NStr("en = 'You have to save the data prior to execution ""%1"" command.'"),
			"%1",
			CommandToExecute.Presentation);
		
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("en = 'Save and continue'"));
		Buttons.Add(DialogReturnCode.Cancel);
		
		Handler = New NotifyDescription("ExecuteSpecifiedCommandAtClientCompletion", ThisObject, AdditionalParameters);
		ShowQueryBox(Handler, QuestionText, Buttons, 60, DialogReturnCode.Yes);
	Else
		ExecuteSpecifiedCommandAtClientCompletion(-1, AdditionalParameters);
	EndIf;
	
	Return True; // The command can be executed in client context only
EndFunction

// Displays command execution result.
//
// Parameters:
//   Form            - ManagedForm - form where the result is displayed
//   ExecutionResult - Structure - see StandardSubsystemsClient.ShowExecutionResult().
//
Procedure ShowCommandExecutionResult(Form, ExecutionResult) Export
	
	StandardSubsystemsClient.ShowExecutionResult(Form, ExecutionResult);
	
EndProcedure

// 1CI >

Procedure AttachingFileSystemExtensionResult(Connected, Params) Export
	
	ResultHandler = Params.ResultHandler;
	FormID =  Params.FormID;
	FileName = Params.FileName;
	DialogParameters = Params.DialogParameters;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ResultHandler", ResultHandler);
	
	If Connected Then
		
	//	If DialogParameters = Undefined Then
	//		DialogParameters = New Structure;
	//	EndIf;
	//	If DialogParameters.Property("Mode") Then
	//		Mode = DialogParameters.Mode;
	//		If Mode = FileDialogMode.ChooseDirectory Then
	//			Raise NStr("en = 'Directory selection is not supported.'");
	//		EndIf;
	//	Else
	//		Mode = FileDialogMode.Open;
	//	EndIf;
	//	
	//	Dialog = New FileDialog(Mode);
	//	Dialog.FullFileName = FileName;
	//	FillPropertyValues(Dialog, DialogParameters);
	//	
	//	PlacedFiles = New Array;
	//	If FormID <> Undefined Then
	//		SelectionDone = PutFiles(, PlacedFiles, Dialog, True, FormID);
	//	Else
	//		SelectionDone = PutFiles(, PlacedFiles, Dialog, True);
	//	EndIf;
	//	ProcessFilePuttingResult(SelectionDone, PlacedFiles, Undefined, AdditionalParameters);
	//	
	//Else	
		
		Handler = New NotifyDescription("ProcessFilePuttingResult", ThisObject, AdditionalParameters);
		BeginPutFile(Handler, , FileName, True, FormID);
		
	EndIf;	
	
EndProcedure 

// 1CI <

// Displays a file selection dialog and puts the selected files to a temporary storage.
// This method incorporates the functionality of both BeginPuttingFiles and PutFiles global methods, and 
// its return value is not affected by availability of the file system extension.
//
// Parameters:
//   ResultHandler    - NotifyDescription - the procedure where the result is passed.
//   FormID   - UUID - UUID of form used to put the files.
//   FileName         - String - default file name and path in the selection dialog box.
//   DialogParameters - Structure, Undefined - see FileSelectionDialog properties in Syntax Assistant.
//                      It is used if the file system extension is available.
//
// Value of the first parameter returned to ResultHandler:
//   PlacedFiles - Selection result.
//       * - Undefined - user canceled the selection.
//       * - Array of TransferredFileDescription, Structure - user selected a file.
//           ** Name    - String - full name of the selected file.
//           ** Storage - String - file address in a storage.
//
// Restrictions:
//   This procedure is used only for interactive selection in dialogs.
//   Directories cannot be selected because this option is not supported in the web client.
//   Multiple selection in the web client is only supported if the file system extension is available.
//   Putting files to a temporary storage is not supported.
//
Procedure ShowFilePutting(ResultHandler, FormID, FileName, DialogParameters) Export
		
	// 1CI >
	
	//AdditionalParameters = New Structure;
	//AdditionalParameters.Insert("ResultHandler", ResultHandler);

	Params = New Structure("ResultHandler, FormID, FileName, DialogParameters", ResultHandler, FormID, FileName, DialogParameters); 
	ND = New NotifyDescription("AttachingFileSystemExtensionResult", ThisObject, Params);
	BeginAttachingFileSystemExtension(ND);
	
	//If AttachFileSystemExtension() Then
	//	
	//	If DialogParameters = Undefined Then
	//		DialogParameters = New Structure;
	//	EndIf;
	//	If DialogParameters.Property("Mode") Then
	//		Mode = DialogParameters.Mode;
	//		If Mode = FileDialogMode.ChooseDirectory Then
	//			Raise NStr("en = 'Directory selection is not supported.'");
	//		EndIf;
	//	Else
	//		Mode = FileDialogMode.Open;
	//	EndIf;
	//	
	//	Dialog = New FileDialog(Mode);
	//	Dialog.FullFileName = FileName;
	//	FillPropertyValues(Dialog, DialogParameters);
	//	
	//	PlacedFiles = New Array;
	//	If FormID <> Undefined Then
	//		SelectionDone = PutFiles(, PlacedFiles, Dialog, True, FormID);
	//	Else
	//		SelectionDone = PutFiles(, PlacedFiles, Dialog, True);
	//	EndIf;
	//	ProcessFilePuttingResult(SelectionDone, PlacedFiles, Undefined, AdditionalParameters);
	//	
	//Else
	//	
	//	Handler = New NotifyDescription("ProcessFilePuttingResult", ThisObject, AdditionalParameters);
	//	BeginPutFile(Handler, , FileName, True, FormID);
	//	
	//EndIf;
	
	// 1CI <
	
EndProcedure

#EndRegion

#Region InternalInterface

////////////////////////////////////////////////////////////////////////////////
// Handlers of conditional method calls.

// Opens the form for picking additional reports.
//
// Parameters:
//   FormItem - Arbitrary - form item used to pick the items.
//
// Usage instances:
//   Catalog.ReportMailings.Form.ItemForm.AddAdditionalReport().
//
Procedure ReportMailingPickAdditionalReport(FormItem) Export
	
	AdditionalReport = PredefinedValue("Enum.AdditionalReportAndDataProcessorKinds.AdditionalReport");
	Report           = PredefinedValue("Enum.AdditionalReportAndDataProcessorKinds.Report");
	
	FilterByType = New ValueList;
	FilterByType.Add(AdditionalReport, AdditionalReport);
	FilterByType.Add(Report, Report);
	
	ChoiceFormParameters = New Structure;
	ChoiceFormParameters.Insert("WindowOpeningMode", FormWindowOpeningMode.Independent);
	ChoiceFormParameters.Insert("ChoiceMode",        True);
	ChoiceFormParameters.Insert("CloseOnChoice",     False);
	ChoiceFormParameters.Insert("Multiselect",       True);
	ChoiceFormParameters.Insert("Filter",            New Structure("Kind", FilterByType));
	
	OpenForm("Catalog.AdditionalReportsAndDataProcessors.ChoiceForm", ChoiceFormParameters, FormItem);
	
EndProcedure

// External print command handler.
//
// Parameters:
//  CommandParameters - Structure - structure containing a command table row, 
//                      see AdditionalReportsAndDataProcessors.OnGetPrintCommand(). 
//  Form              - ManagedForm - form where the command is executed.
//
Function ExecuteAssignedPrintCommand(CommandToExecute, Form) Export
	
	// Moving additional parameters passed by this subsystem to the root structure.
	For Each KeyAndValue In CommandToExecute.AdditionalParameters Do
		CommandToExecute.Insert(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	// Writing fixed parameters.
	CommandToExecute.Insert("IsReport", False);
	CommandToExecute.Insert("Kind", PredefinedValue("Enum.AdditionalReportAndDataProcessorKinds.PrintForm"));
	
	// Starting the data processor method that corresponds to the command context.
	RunningVariant = CommandToExecute.RunningVariant;
	If RunningVariant = PredefinedValue("Enum.AdditionalDataProcessorCallMethods.FormOpening") Then
		OpenDataProcessorForm(CommandToExecute, Form, CommandToExecute.PrintObjects);
	ElsIf RunningVariant = PredefinedValue("Enum.AdditionalDataProcessorCallMethods.ClientMethodCall") Then
		ExecuteDataProcessorClientMethod(CommandToExecute, Form, CommandToExecute.PrintObjects);
	Else
		OpenPrintForm(CommandToExecute, Form, CommandToExecute.PrintObjects);
	EndIf;
	
EndFunction

#EndRegion

#Region InternalProceduresAndFunctions

// Displays a notification before command execution.
Procedure ShowNotificationOnCommandExecution(CommandToExecute) Export
	If CommandToExecute.ShowNotification Then
		ShowUserNotification(NStr("en = 'Executing command...'"), , CommandToExecute.Presentation);
	EndIf;
EndProcedure

// Opens a data processor form.
Procedure OpenDataProcessorForm(CommandToExecute, Form, TargetObjects) Export
	ProcessingParameters = New Structure("CommandID, AdditionalDataProcessorRef, FormName, SessionKey");
	ProcessingParameters.CommandID                  = CommandToExecute.ID;
	ProcessingParameters.AdditionalDataProcessorRef = CommandToExecute.Ref;
	ProcessingParameters.FormName                   = ?(Form = Undefined, Undefined, Form.FormName);
	ProcessingParameters.SessionKey                 = CommandToExecute.Ref.UUID();
	
	If TypeOf(TargetObjects) = Type("Array") Then
		ProcessingParameters.Insert("TargetObjects", TargetObjects);
	EndIf;
	
	#If ThickClientOrdinaryApplication Then
		ExternalDataProcessor = AdditionalReportsAndDataProcessorsServerCall.GetExternalDataProcessorsObject(CommandToExecute.Ref);
		DataProcessorForm = ExternalDataProcessor.GetForm(, Form);
		If DataProcessorForm = Undefined Then
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'The main form is not specified for ""%1"" report or data processor,
				|or the main form is not intended for opening in ordinary applications.
				|The ""%2"" command cannot be executed.'"),
				String(CommandToExecute.Ref),
				CommandToExecute.Presentation);
		EndIf;
		DataProcessorForm.Open();
		DataProcessorForm = Undefined;
	#Else
		DataProcessorName = AdditionalReportsAndDataProcessorsServerCall.AttachExternalDataProcessor(CommandToExecute.Ref);
		If CommandToExecute.IsReport Then
			OpenForm("ExternalReport."+ DataProcessorName +".Form", ProcessingParameters, Form);
		Else
			OpenForm("ExternalDataProcessor."+ DataProcessorName +".Form", ProcessingParameters, Form);
		EndIf;
	#EndIf
EndProcedure

// Executes a client data processor method.
Procedure ExecuteDataProcessorClientMethod(CommandToExecute, Form, TargetObjects) Export
	
	ShowNotificationOnCommandExecution(CommandToExecute);
	
	ProcessingParameters = New Structure("CommandID, AdditionalDataProcessorRef, FormName");
	ProcessingParameters.CommandID                  = CommandToExecute.ID;
	ProcessingParameters.AdditionalDataProcessorRef = CommandToExecute.Ref;
	ProcessingParameters.FormName                   = ?(Form = Undefined, Undefined, Form.FormName);;
	
	If TypeOf(TargetObjects) = Type("Array") Then
		ProcessingParameters.Insert("TargetObjects", TargetObjects);
	EndIf;
	
	#If ThickClientOrdinaryApplication Then
		ExternalDataProcessor = AdditionalReportsAndDataProcessorsServerCall.GetExternalDataProcessorsObject(CommandToExecute.Ref);
		DataProcessorForm = ExternalDataProcessor.GetForm(, Form);
		If DataProcessorForm = Undefined Then
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'The main form is not specified for ""%1"" report or data processor,
				|or the main form is not intended for opening in ordinary applications.
				|The ""%2"" command cannot be executed.'"),
				String(CommandToExecute.Ref),
				CommandToExecute.Presentation);
		EndIf;
	#Else
		DataProcessorName = AdditionalReportsAndDataProcessorsServerCall.AttachExternalDataProcessor(CommandToExecute.Ref);
		If CommandToExecute.IsReport Then
			DataProcessorForm = GetForm("ExternalReport."+ DataProcessorName +".Form", ProcessingParameters, Form);
		Else
			DataProcessorForm = GetForm("ExternalDataProcessor."+ DataProcessorName +".Form", ProcessingParameters, Form);
		EndIf;
	#EndIf
	
	If CommandToExecute.Kind = PredefinedValue("Enum.AdditionalReportAndDataProcessorKinds.AdditionalDataProcessor")
		Or CommandToExecute.Kind = PredefinedValue("Enum.AdditionalReportAndDataProcessorKinds.AdditionalReport") Then
		
		DataProcessorForm.ExecuteCommand(CommandToExecute.ID);
		
	ElsIf CommandToExecute.Kind = PredefinedValue("Enum.AdditionalReportAndDataProcessorKinds.RelatedObjectCreation") Then
		
		CreatedObjects = New Array;
		
		DataProcessorForm.ExecuteCommand(CommandToExecute.ID, TargetObjects, CreatedObjects);
		
		CreatedObjectTypes = New Array;
		
		For Each CreatedObject In CreatedObjects Do
			Type = TypeOf(CreatedObject);
			If CreatedObjectTypes.Find(Type) = Undefined Then
				CreatedObjectTypes.Add(Type);
			EndIf;
		EndDo;
		
		For Each Type In CreatedObjectTypes Do
			NotifyChanged(Type);
		EndDo;
		
	ElsIf CommandToExecute.Kind = PredefinedValue("Enum.AdditionalReportAndDataProcessorKinds.PrintForm") Then
		
		DataProcessorForm.Print(CommandToExecute.ID, TargetObjects);
		
	ElsIf CommandToExecute.Kind = PredefinedValue("Enum.AdditionalReportAndDataProcessorKinds.ObjectFilling") Then
		
		DataProcessorForm.ExecuteCommand(CommandToExecute.ID, TargetObjects);
		
		ModifiedObjectTypes = New Array;
		
		For Each ModifiedObject In TargetObjects Do
			Type = TypeOf(ModifiedObject);
			If ModifiedObjectTypes.Find(Type) = Undefined Then
				ModifiedObjectTypes.Add(Type);
			EndIf;
		EndDo;
		
		For Each Type In ModifiedObjectTypes Do
			NotifyChanged(Type);
		EndDo;
		
	ElsIf CommandToExecute.Kind = PredefinedValue("Enum.AdditionalReportAndDataProcessorKinds.Report") Then
		
		DataProcessorForm.ExecuteCommand(CommandToExecute.ID, TargetObjects);
		
	EndIf;
	
	DataProcessorForm = Undefined;
	
EndProcedure

// Generates a spreadsheet document in a form of the Print subsystem
Procedure OpenPrintForm(CommandToExecute, Form, TargetObjects) Export
	
	// 1CI >
	
	//StandardProcessing = True;
	//AdditionalReportsAndDataProcessorsClientOverridable.BeforeExecuteExternalPrintFormPrintCommand(TargetObjects, StandardProcessing);
	//
	//Parameters = New Structure;
	//Parameters.Insert("CommandToExecute", CommandToExecute);
	//Parameters.Insert("Form", Form);
	//If StandardProcessing Then
	//	NotifyDescription = New NotifyDescription("OpenPrintFormCompletion", ThisObject, Parameters);
	//	PrintManagementClient.CheckDocumentsPosted(NotifyDescription, TargetObjects, Form);
	//Else
	//	OpenPrintFormCompletion(TargetObjects, Parameters);
	//EndIf;
	
	// 1CI <
	
EndProcedure

// Continues the execution of OpenPrintForm procedure.
Procedure OpenPrintFormCompletion(TargetObjects, AdditionalParameters) Export
	
	CommandToExecute = AdditionalParameters.CommandToExecute;
	Form = AdditionalParameters.Form;
	
	SourceParameters = New Structure;
	SourceParameters.Insert("CommandID",      CommandToExecute.ID);
	SourceParameters.Insert("TargetObjects", TargetObjects);
	
	OpenParameters = New Structure;
	OpenParameters.Insert("DataSource",       CommandToExecute.Ref);
	OpenParameters.Insert("SourceParameters", SourceParameters);
	
	OpenForm("CommonForm.PrintDocuments", OpenParameters, Form);
	
EndProcedure

// Continues the execution of an assigned command on the client.
Procedure ExecuteSpecifiedCommandAtClientCompletion(Answer, AdditionalParameters) Export
	Form = AdditionalParameters.Form;
	If Answer = DialogReturnCode.Yes Then
		If Not Form.Write() Then
			Return;
		EndIf;
	ElsIf Answer <> -1 Then
		Return;
	EndIf;
	
	CommandToExecute = AdditionalParameters.CommandToExecute;
	Object = AdditionalParameters.Object;
	
	ServerCallParameters = New Structure;
	ServerCallParameters.Insert("CommandID",                  CommandToExecute.ID);
	ServerCallParameters.Insert("AdditionalDataProcessorRef", CommandToExecute.Ref);
	ServerCallParameters.Insert("TargetObjects",             New Array);
	ServerCallParameters.Insert("FormName",                   Form.FormName);
	ServerCallParameters.TargetObjects.Add(Object.Ref);
	
	ShowNotificationOnCommandExecution(CommandToExecute);
	
	// Getting details on the execution result is only supported for server methods.
	// When a form is opened or a client method is called, the execution result is displayed by the data processor.
	If CommandToExecute.RunningVariant = PredefinedValue("Enum.AdditionalDataProcessorCallMethods.FormOpening") Then
		
		ExternalObjectName = AdditionalReportsAndDataProcessorsServerCall.AttachExternalDataProcessor(CommandToExecute.Ref);
		If CommandToExecute.IsReport Then
			OpenForm("ExternalReport."+ ExternalObjectName +".Form", ServerCallParameters, Form);
		Else
			OpenForm("ExternalDataProcessor."+ ExternalObjectName +".Form", ServerCallParameters, Form);
		EndIf;
		
	ElsIf CommandToExecute.RunningVariant = PredefinedValue("Enum.AdditionalDataProcessorCallMethods.ClientMethodCall") Then
		
		ExternalObjectName = AdditionalReportsAndDataProcessorsServerCall.AttachExternalDataProcessor(CommandToExecute.Ref);
		If CommandToExecute.IsReport Then
			ExternalObjectForm = GetForm("ExternalReport."+ ExternalObjectName +".Form", ServerCallParameters, Form);
		Else
			ExternalObjectForm = GetForm("ExternalDataProcessor."+ ExternalObjectName +".Form", ServerCallParameters, Form);
		EndIf;
		ExternalObjectForm.ExecuteCommand(ServerCallParameters.CommandID, ServerCallParameters.TargetObjects);
		
	ElsIf CommandToExecute.RunningVariant = PredefinedValue("Enum.AdditionalDataProcessorCallMethods.ServerMethodCall")
		Or CommandToExecute.RunningVariant = PredefinedValue("Enum.AdditionalDataProcessorCallMethods.ScenarioInSafeMode") Then
		
		ServerCallParameters.Insert("ExecutionResult", StandardSubsystemsClientServer.NewExecutionResult());
		AdditionalReportsAndDataProcessorsServerCall.ExecuteCommand(ServerCallParameters, Undefined);
		Form.Read();
		ShowCommandExecutionResult(Form, ServerCallParameters.ExecutionResult);
		
	EndIf;
EndProcedure

// This procedure is used for editing text in table attributes.
Procedure EditMultilineText(FormOrHandler, EditText, AttributeOwner, AttributeName, Val Title = "") Export
	
	If IsBlankString(Title) Then
		Title = NStr("en = 'Comment'");
	EndIf;
	
	SourceParameters = New Structure;
	SourceParameters.Insert("FormOrHandler",  FormOrHandler);
	SourceParameters.Insert("AttributeOwner", AttributeOwner);
	SourceParameters.Insert("AttributeName",  AttributeName);
	Handler = New NotifyDescription("EditMultilineTextCompletion", ThisObject, SourceParameters);
	
	ShowInputString(Handler, EditText, Title, , True);
	
EndProcedure

// Displays the extension installation dialog and exports additional report or data processor data.
Procedure ExportToFile(ExportParameters) Export
	MessageText = NStr("en = 'It is recommended that you install the file system extension before exporting the external report or data processor to a file.'");
	Handler = New NotifyDescription("ExportToFileCompletion", ThisObject, ExportParameters);
	CommonUseClient.ShowFileSystemExtensionInstallationQuestion(Handler, MessageText);
EndProcedure

// Displays a notification dialog box and then, once the dialog box is closed, calls the handler and passes the user input to that handler.
Procedure ReturnResultAfterShowWarning(WarningText, Handler, Result) Export
	HandlerParameters = New Structure;
	HandlerParameters.Insert("Handler", PrepareHandlerForDialog(Handler));
	HandlerParameters.Insert("Result", Result);
	Handler = New NotifyDescription("ReturnResultAfterCloseSimpleDialog", ThisObject, HandlerParameters);
	ShowMessageBox(Handler, WarningText);
EndProcedure

// Continues the execution of ReturnResultAfterShowWarning procedure.
Procedure ReturnResultAfterCloseSimpleDialog(HandlerParameters) Export
	If TypeOf(HandlerParameters.Handler) = Type("NotifyDescription") Then
		ExecuteNotifyProcessing(HandlerParameters.Handler, HandlerParameters.Result);
	EndIf;
EndProcedure

// Prepares a handler for an asynchronous dialog.
Function PrepareHandlerForDialog(HandlerOrStructure) Export
	
	If TypeOf(HandlerOrStructure) = Type("Structure") Then
		// Recursive registration of all caller script handlers.
		If HandlerOrStructure.Property("ResultHandler") Then
			HandlerOrStructure.ResultHandler = PrepareHandlerForDialog(HandlerOrStructure.ResultHandler);
		EndIf;
		If HandlerOrStructure.Property("AsynchronousDialog") Then
			// Registration of the opened dialog.
			HandlerOrStructure.AsynchronousDialog.IsOpen = True;
			// Handler creation (and fixing the entire parameter structure).
			Handler = New NotifyDescription(
				HandlerOrStructure.AsynchronousDialog.ProcedureName,
				HandlerOrStructure.AsynchronousDialog.Module,
				HandlerOrStructure);
		Else
			Handler = Undefined;
		EndIf;
	Else
		Handler = HandlerOrStructure;
	EndIf;
	
	Return Handler;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Internal asynchronous dialog handlers..

// ShowFilePutting procedure execution result handler.
Procedure ProcessFilePuttingResult(SelectionDone, AddressOrSelectionResult, SelectedFileName, AdditionalParameters) Export
	
	If TypeOf(AdditionalParameters.ResultHandler) = Type("NotifyDescription") Then
		
		If SelectionDone = True Then
			If TypeOf(AddressOrSelectionResult) = Type("Array") Then
				ChoiceResult = AddressOrSelectionResult;
			Else
				ChoiceResult = New Array;
				ResultItem = New Structure;
				ResultItem.Insert("Location", AddressOrSelectionResult);
				ResultItem.Insert("Name",     SelectedFileName);
				ChoiceResult.Add(ResultItem);
			EndIf;
		Else
			ChoiceResult = Undefined;
		EndIf;
		
		ExecuteNotifyProcessing(AdditionalParameters.ResultHandler, ChoiceResult);
		
	EndIf;
	
EndProcedure

// EditMultilineText procedure execution result handler.
Procedure EditMultilineTextCompletion(Text, SourceParameters) Export
	
	If TypeOf(SourceParameters.FormOrHandler) = Type("ManagedForm") Then
		Form      = SourceParameters.FormOrHandler;
		Handler = Undefined;
	Else
		Form      = Undefined;
		Handler = SourceParameters.FormOrHandler;
	EndIf;
	
	If Text <> Undefined Then
		
		If TypeOf(SourceParameters.AttributeOwner) = Type("FormDataTreeItem")
			Or TypeOf(SourceParameters.AttributeOwner) = Type("FormDataCollectionItem") Then
			FillPropertyValues(SourceParameters.AttributeOwner, New Structure(SourceParameters.AttributeName, Text));
		Else
			SourceParameters.AttributeOwner[SourceParameters.AttributeName] = Text;
		EndIf;
		
		If Form <> Undefined Then
			If Not Form.Modified Then
				Form.Modified = True;
			EndIf;
		EndIf;
		
	EndIf;
	
	If Handler <> Undefined Then
		ExecuteNotifyProcessing(Handler, Text);
	EndIf;
	
EndProcedure

// ExportToFile procedure execution result handler.
Procedure ExportToFileCompletion(Result, ExportParameters) Export
	Var Address;
	
	ExportParameters.Property("DataProcessorDataAddress", Address);
	If Not ValueIsFilled(Address) Then
		Address = AdditionalReportsAndDataProcessorsServerCall.PutToStorage(ExportParameters.Ref, Undefined);
	EndIf;
	
	If Not AttachFileSystemExtension() Then
		GetFile(Address, ExportParameters.FileName, True);
		Return;
	EndIf;
	
	SaveFileDialog = New FileDialog(FileDialogMode.Save);
	SaveFileDialog.FullFileName = ExportParameters.FileName;
	SaveFileDialog.Filter = AdditionalReportsAndDataProcessorsClientServer.SelectingAndSavingDialogFilter();
	SaveFileDialog.FilterIndex = ?(ExportParameters.IsReport, 1, 2);
	SaveFileDialog.Multiselect = False;
	SaveFileDialog.Title = NStr("en = 'Select file'");
	
	If SaveFileDialog.Choose() Then
		FilesToBeObtained = New Array;
		FilesToBeObtained.Add(New TransferableFileDescription(, Address));
		GetFiles(FilesToBeObtained, , SaveFileDialog.FullFileName, False);
	EndIf;
EndProcedure

#EndRegion
