////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
//
//////////////////////////////////////////////////////////////////////////////// 

#Region Interface

////////////////////////////////////////////////////////////////////////////////

// Search and deletion of duplicates.

// Opens the form for merging items of catalogs, charts of characteristic types, calculation
// types, and accounts.
//
// Parameters:
//  ItemsToMerge - FormTable, Array, ValueList - list of items to be merged.
//                 You can also pass any item collection with the Ref attribute.
//
Procedure MergeSelectedItems(Val ItemsToMerge) Export
	
	FormParameters = New  Structure;
	FormParameters.Insert("ReferenceSet", ReferenceSet(ItemsToMerge));
	OpenForm("DataProcessor.ReferenceReplacement.Form.ItemMerging", FormParameters); 
	
EndProcedure
 
// Opens the form for replacing references with merging.
//
// Parameters:
//  ItemsToMerge - FormTable, Array, ValueList - list of items to be replaced.
//                 You can also pass any item collection with the Ref attribute.
//
Procedure ReplaceSelected(Val ItemsToMerge) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("ReferenceSet", ReferenceSet(ItemsToMerge));
	FormParameters.Insert("OpenByScenario");
	OpenForm("DataProcessor.ReferenceReplacement.Form.ItemReplacement", FormParameters); 
	
EndProcedure
 
// Opens the report on usage instances for reference.
// Auxiliary data (such as record sets with master dimension and so on) is not included into
// the report.
//
// Parameters:
//  Items          - FormTable, Array, ValueList - list of items to be analyzed.
//                   You can also pass any item collection with the Ref attribute.
//  OpenParameters - Structure - form opening parameters. Contains the following optional
//                   fields corresponded to the OpenForm function parameters: 
//                   Owner, Uniqueness, Window, URL, OnCloseNotifyDescription, 
//                   WindowOpeningMode.
// 
Procedure ShowUsageInstances(Val Items, Val OpenParameters = Undefined) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("ReferenceSet", ReferenceSet(Items));
	
	FormOpenParameters = New Structure("Owner, Uniqueness, Window, URL, OnCloseNotifyDescription, WindowOpeningMode");
	If OpenParameters <> Undefined Then
		FillPropertyValues(FormOpenParameters, OpenParameters);
	EndIf;
		
	OpenForm("Report.SearchForReferences.Form", FormParameters,
		FormOpenParameters.Owner, FormOpenParameters.Uniqueness, FormOpenParameters.Window,  
		FormOpenParameters.URL, FormOpenParameters.OnCloseNotifyDescription, 
		FormOpenParameters.WindowOpeningMode
	); 
	
EndProcedure
 
////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for interactive work.

// Sets the application main window caption using the current user presentation, value of the 
// ApplicationPresentation constant, and default application caption.
//
// Parameters:
//   OnStart - Boolean - True if the procedure is called during the application start.
//
Procedure SetAdvancedApplicationCaption(OnStart = False) Export
	
	ClientParameters = ?(OnStart, StandardSubsystemsClientCached.ClientParametersOnStart(),
		StandardSubsystemsClientCached.ClientParameters());
		
	// CI >	
	//If ClientParameters.CanUseSeparatedData Then
	//	CaptionPresentation = ClientParameters.ApplicationPresentation;
	//	UserPresentation =  ClientParameters.UserPresentation;
	//	ConfigurationPresentation =  ClientParameters.DetailedInformation;
	//	
	//	If IsBlankString(TrimAll(CaptionPresentation)) Then
	//		If ClientParameters.Property("DataAreaPresentation") Then
	//			CaptionPattern = "%1 / %2 / %3";
	//			ApplicationPresentation = StringFunctionsClientServer.SubstituteParametersInString(CaptionPattern, 
	//				ClientParameters.DataAreaPresentation, ConfigurationPresentation, 
	//				UserPresentation);
	//		Else
	//			CaptionPattern = "%1 / %2";
	//			ApplicationPresentation = StringFunctionsClientServer.SubstituteParametersInString(CaptionPattern, 
	//				ConfigurationPresentation,  UserPresentation);
	//		EndIf;
	//	Else
	//		CaptionPattern = "%1 / %2 / %3";
	//		ApplicationPresentation = StringFunctionsClientServer.SubstituteParametersInString(CaptionPattern, 
	//			TrimAll(CaptionPresentation), UserPresentation,  ConfigurationPresentation);
	//	EndIf;
	//Else
		
		//CaptionPattern = "%1 / %2";
		//ApplicationPresentation = StringFunctionsClientServer.SubstituteParametersInString(CaptionPattern, 
		//	NStr("en = 'Separators not set'"), ClientParameters.DetailedInformation);
	//EndIf;
	ApplicationPresentation = "CI";
	 // CI <
	 
	CommonUseClientOverridable.ClientApplicationPresentationOnSet(ApplicationPresentation, OnStart);
	
	SetClientApplicationCaption(ApplicationPresentation);
	
EndProcedure
 
// Show the question form.
//
// Parameters:
//  NotifyDescriptionOnCompletion - NotifyDescription - description of the procedures to be called after the question
//                                  window is closed with following parameters: 
//                                   QuestionResult - Structure - structure with the following properties:
//                                                     Value                - user selection result: a system
//                                                                            enumeration value or a value associated
//                                                                            with the clicked button. If the dialog is
//                                                                            closed by timeout, the value is Timeout.
//                                                     DontAskAgain         - Boolean - user selection result in the
//                                                                            check box with the same name.
//                                                     AdditionalParameters - Structure.
//  QueryText                      - String - text of the question to be asked.  
//  Buttons                        - QuestionDialogMode, ValueList - can be specified a value list, where:
//                                    Value        - contains the value corresponded with the button and returned when
//                                                   the button is selected. You can pass a value of the
//                                                   DialogReturnCode enumeration or any value that can be XDTO
//                                                   serialized.
//                                    Presentation - sets the button text.
//  AdditionalParameters           - Structure - additional options, see details on QuestionToUserParameters.
//
// Returns:
//  The user selection result is passed to the method specified in the NotifyDescriptionOnCompletion parameter. 
//
Procedure ShowQuestionToUser(NotifyDescriptionOnCompletion, QuestionText, Buttons,  AdditionalParameters = Undefined) Export
	
	If AdditionalParameters <> Undefined Then
		Parameters = AdditionalParameters;
	Else	
		Parameters = QuestionToUserParameters();
	EndIf;
	
	If TypeOf(Buttons) = Type("QuestionDialogMode") Then
		If Buttons = QuestionDialogMode.YesNo Then
			ButtonsParameter = "QuestionDialogMode.YesNo";
		ElsIf Buttons =  QuestionDialogMode.YesNoCancel Then
			ButtonsParameter = "QuestionDialogMode.YesNoCancel";
		ElsIf Buttons =  QuestionDialogMode.OK Then
			ButtonsParameter = "QuestionDialogMode.OK";
		ElsIf Buttons =  QuestionDialogMode.OKCancel Then
			ButtonsParameter = "QuestionDialogMode.OKCancel";
		ElsIf Buttons =  QuestionDialogMode.RetryCancel Then
			ButtonsParameter = "QuestionDialogMode.RetryCancel";
		ElsIf Buttons =  QuestionDialogMode.AbortRetryIgnore Then
			ButtonsParameter = "QuestionDialogMode.AbortRetryIgnore";
		EndIf;
	Else
		ButtonsParameter = Buttons;
	EndIf;
	
	If TypeOf(Parameters.DefaultButton) = Type("DialogReturnCode") Then
		DefaultButtonParameter =  DialogReturnCodeInString(Parameters.DefaultButton);
	Else
		DefaultButtonParameter = Parameters.DefaultButton;
	EndIf;
	
	If TypeOf(Parameters.TimeoutButton) = Type("DialogReturnCode") Then
		TimeoutButtonParameter =  DialogReturnCodeInString(Parameters.TimeoutButton);
	Else
		TimeoutButtonParameter = Parameters.TimeoutButton;
	EndIf;
	
	Parameters.Insert("Buttons",             ButtonsParameter);
	Parameters.Insert("Timeout",             Parameters.Timeout);
	Parameters.Insert("DefaultButton",       DefaultButtonParameter);
	Parameters.Insert("Title",               Parameters.Title);
	Parameters.Insert("TimeoutButton",       TimeoutButtonParameter);
	Parameters.Insert("MessageText",         QuestionText);
	Parameters.Insert("Picture",             Parameters.Picture);
	Parameters.Insert("SuggestDontAskAgain", Parameters.SuggestDontAskAgain);
	
	OpenForm("CommonForm.Question", Parameters,,,,,NotifyDescriptionOnCompletion);
	
EndProcedure
 
// Returns a new structure with additional parameters for the ShowQuestionToUser procedure.
//
// Returns:
//  Structure - structure with the following properties:
//   * DefaultButton       - Arbitrary - defines the default button by the button type or by
//                           the value associated with it. 
//   * Timeout             - Number - period of time in seconds in which the question window
//                           waits for user to respond. 
//   * TimeoutButton       - Arbitrary - button (by button type or value associated with it) on
//                           which the timeout remaining seconds are displayed. 
//   * Title               - String - question title. 
//   * SuggestDontAskAgain - Boolean - True means the same name check box is available in the
//                           window.
//   * DoNotAskAgain       - Boolean - value set by the user in the corresponding check box.
//   * LockWholeInterface  - Boolean - True means the question window is opened locking all
//                           other opened windows include the main one.
//   * Picture             - Picture - picture to be shown in the question window.
//
Function QuestionToUserParameters() Export
	
	Parameters = New  Structure;
	Parameters.Insert("DefaultButton", Undefined);
	Parameters.Insert("Timeout", 0);
	Parameters.Insert("TimeoutButton", Undefined);
	Parameters.Insert("Title", GetClientApplicationCaption());
	Parameters.Insert("SuggestDontAskAgain", True);
	Parameters.Insert("DontAskAgain", False);
	Parameters.Insert("LockWholeInterface", False);
	Parameters.Insert("Picture", Undefined);
	Return Parameters;
	
EndFunction
	
////////////////////////////////////////////////////////////////////////////////
// Startup and exit.

// Disables the exit confirmation.
//
Procedure SkipExitConfirmation()  Export
	
	SkipExitConfirmation = True;
	
EndProcedure
 
// Performs the standard actions before the user starts working with a data area or with an
// infobase in the local mode.
//
// Is intended for calling modules of the managed or ordinary application from the BeforeStart 
// handler.
//
// Parameters:
//  CompletionNotification - NotifyDescription - is skipped if managed or ordinary application
//                           modules is called from the BeforeStart handler. In other cases,
//                           after the application started up, the notification with a
//                           parameter of the Structure type is called. The structure fields
//                           are:
//                            Cancel                            - Boolean - False if the  
//                                                                application started
//                                                                successfully, True otherwise.
//                            Restart                           - Boolean - if the application 
//                                                                must be restarted.
//                            AdditionalParametersOfCommandLine - String - for restarting.
//
Procedure BeforeStart(Val CompletionNotification = Undefined) Export
	
	If CompletionNotification <> Undefined Then
		CommonUseClientServer.ValidateParameter("StandardSubsystemsClient.BeforeStart",  
			"CompletionNotification", CompletionNotification, Type("NotifyDescription"));
	EndIf;
	
	SetSessionSeparation();
	
	Parameters = New Structure;
	
	// External parameters of the result description
	Parameters.Insert("Cancel",  False);
	Parameters.Insert("Restart", False);
	Parameters.Insert("AdditionalParametersOfCommandLine", "");
	
	// External parameters of the implementation management
	Parameters.Insert("InteractiveHandler", Undefined);   //  NotifyDescription
	Parameters.Insert("ContinuationHandler", Undefined); //  NotifyDescription
	Parameters.Insert("ContinuousExecution", True);
	Parameters.Insert("RetrievedClientParameters", New Structure);
	
	// Internal parameters
	Parameters.Insert("CompletionNotification", CompletionNotification);
	Parameters.Insert("CompletionHandler", New NotifyDescription(
		"ActionsBeforeStartCompletionHandler", ThisObject, Parameters));
	
	UpdateClientParameters(Parameters, True, CompletionNotification <> Undefined);
	ClientParameters = StandardSubsystemsClientCached.ClientParametersOnStart();
	
	Parameters.Insert("ContinuationHandler", New NotifyDescription(
		"ActionsBeforeStartAfterPlatformVersionVerification", ThisObject, Parameters));
	
	Try
		CheckPlatformVersionOnStart(Parameters);
	Except
		HandleErrorOnStartOrExit(Parameters, ErrorInfo(), "Start", True);
	EndTry;
	If BeforeStartInteractiveHandler(Parameters) Then
		Return;
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure
 
// Performs the standard actions when the user starts working with a data area or with an
// infobase in the local mode.
//
// Is intended for calling modules of the managed or ordinary application from the OnStart
// handler.
//
// Parameters:
//  CompletionNotification - NotifyDescription - is skipped if managed or ordinary application 
//                           modules is called from the OnStart handler. In other cases, after
//                           the application started up, the notification with a parameter of
//                           the Structure type is called. The structure fields are:
//                            Cancel                            - Boolean - False if the
//                                                                application started
//                                                                successfully, True otherwise.
//                            Restart                           - Boolean - if the application
//                                                                must be restarted.
//                            AdditionalParametersOfCommandLine - String - for restarting.
//  ContinuousExecution    - Boolean - For internal use only. For proceeding from the
//                           BeforeStart handler executed in the interactive processing mode.
//
Procedure OnStart(Val CompletionNotification = Undefined, ContinuousExecution = True) Export
	
	If CompletionNotification <> Undefined Then
		CommonUseClientServer.ValidateParameter("StandardSubsystemsClient.OnStart", 
			"CompletionNotification", CompletionNotification, Type("NotifyDescription"));
	EndIf;
	CommonUseClientServer.ValidateParameter("StandardSubsystemsClient.OnStart", 
		"ContinuousExecution", ContinuousExecution, Type("Boolean"));
	
	If  BeforeStartInteractiveHandlerInProgress() Then
		Return;
	EndIf;
	
	Parameters = New  Structure;
	
	// External parameters of the result description
	Parameters.Insert("Cancel",  False);
	Parameters.Insert("Restart", False);
	Parameters.Insert("AdditionalParametersOfCommandLine", "");
	
	// External parameters of the implementation management
	Parameters.Insert("InteractiveHandler", Undefined);   //  NotifyDescription
	Parameters.Insert("ContinuationHandler",   Undefined); //  NotifyDescription
	Parameters.Insert("ContinuousExecution", ContinuousExecution);
	
	// Internal parameters
	Parameters.Insert("CompletionNotification", CompletionNotification);
	Parameters.Insert("CompletionHandler", New NotifyDescription(
		"ActionsOnStartCompletionHandler", ThisObject, Parameters));
	
	// Preparing to proceed to the next procedure
	Parameters.Insert("NextHandlerNumber", 1);
	Parameters.Insert("ContinuationHandler", New NotifyDescription(
		"ActionsOnStartInInternalEventHandlers", ThisObject, Parameters));
	
	Try
		SetAdvancedApplicationCaption(True); // For the main window
		
		If Not  ProcessLaunchParameters() Then
			Parameters.Cancel =  True;
			ExecuteNotifyProcessing(Parameters.CompletionHandler);
			Return;
		EndIf;
	Except
		HandleErrorOnStartOrExit(Parameters, ErrorInfo(), "Start", True);
	EndTry;
	If  OnStartInteractiveHandler(Parameters) Then
		Return;
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure
 
// Performs the standard actions when the user logs off from a data area or exits the
// application in the local mode.
//
// Is intended for calling modules of the managed or ordinary application from the BeforeExit
// handler.
//
// Parameters:
//   Cancel                 - Boolean - Return value. A flag that shows whether the exit must
//                            be canceled, both for program or interactive cases. In the result
//                            of the interaction with the user, the application exit can be
//                            continued.
//
//  CompletionNotification - NotifyDescription - is skipped if managed or ordinary application
//                           modules is called from the BeforeExit handler. Otherwise during an
//                           application exit notification with a parameter of the Structure 
//                           type is called. The structure field is:
//                            Cancel - Boolean - False if the user exited from the application,
//                                               True the exit must be canceled.
//
Procedure BeforeExit(Cancel = False, Val  CompletionNotification = Undefined) Export
	
	If  ParametersOnApplicationStartAndExit.Property("HideDesktopOnStart") Then
		// The error related to an attempt of closing before the application has started is occurred
	#If WebClient Then
		// In the web client mode such situation can occur in the standard case (the page is
		// closed), that is why the exit is interrupted, because it can be executed forcibly but if
		// the user closed the window by accident, they must have an option to stay on the page.
		// Logging off the data area is an exception that is when "CompletionNotification <>
		// Undefined".
		If CompletionNotification = Undefined Then
			Cancel = True;
		EndIf;
	#Else
		// Not in the web client mode such situation can occur if there are errors in the nonmodal
		// start sequence.
		// That is there is no window that locks the whole interface. The application exit must be
		// continued but without standard procedures executed before the exit, because they can lead
		// to an exit error related to the unfinished startup.
	#EndIf
		Return;
	EndIf;
	
	CommonUseClientServer.ValidateParameter(
		"StandardSubsystemsClient.BeforeExit", "Cancel", Cancel, Type("Boolean"));
	
	If CompletionNotification <> Undefined Then
		CommonUseClientServer.ValidateParameter("StandardSubsystemsClient.BeforeExit", 
			"CompletionNotification", CompletionNotification, Type("NotifyDescription"));
	EndIf;
	
	If CompletionNotification = Undefined Then
		If ParametersOnApplicationStartAndExit.Property("ActionsBeforeExitMade") Then
			ParametersOnApplicationStartAndExit.Delete("ActionsBeforeExitMade");
			Return;
		EndIf;
	EndIf;
	
	// At the next application exit time the client exit parameters must be retrieved again
	If ParametersOnApplicationStartAndExit.Property("ClientParametersOnExit") Then
		ParametersOnApplicationStartAndExit.Delete("ClientParametersOnExit");
	EndIf;
	
	Parameters = New  Structure;
	
	// External parameters of the result description
	Parameters.Insert("Cancel", False);
	
	// External parameters of the implementation management
	Parameters.Insert("InteractiveHandler", Undefined); // NotifyDescription
	Parameters.Insert("ContinuationHandler", Undefined); // NotifyDescription
	Parameters.Insert("ContinuousExecution", True);
	
	// Internal parameters
	Parameters.Insert("CompletionNotification", CompletionNotification);
	Parameters.Insert("CompletionHandler", New NotifyDescription(
		"ActionsBeforeExitCompletionHandler", ThisObject, Parameters));
	
	Parameters.Insert("NextHandlerNumber", 1);
	Parameters.Insert("ContinuationHandler", New NotifyDescription(
		"ActionsBeforeExitInInternalEventHandlers", ThisObject, Parameters));
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
	If Parameters.Cancel Or Not Parameters.ContinuousExecution Then
		Cancel = True;
	EndIf;
	
EndProcedure
 
// Returns a structure of parameters required for the application for exit on the client that
// is in the following event handlers:
// - BeforeExit, 
// - OnExit.
// 
// Returns:
//   FixedStructure - structure of client run parameters during the exit.
//
Function ClientParametersOnExit() Export
	
	If Not ParametersOnApplicationStartAndExit.Property("ClientParametersOnExit") Then
		ParametersOnApplicationStartAndExit.Insert("ClientParametersOnExit",
			StandardSubsystemsServerCall.ClientParametersOnExit());
	EndIf;
	
	Return ParametersOnApplicationStartAndExit.ClientParametersOnExit;
	
EndFunction
 
#EndRegion

#Region InternalInterface

// Returns a structure parameters for showing the warnings before exit the application.
//
// Returns:
//  Structure with the following properties:
//   CheckBoxText           - String - check box text.
//   InformationText        - String - text to be shown on the top of the managed item (check
//                            box or hyperlink).
//   HyperlinkText          - String - hyperlink text.
//   ExtendedTooltip        - String - text of the tooltip to be shown to the right from the
//                            managed item (check box or hyperlink).
//   Priority               - Number - defines the relative order of the warnings in the form
//                            (highest on the top).
//   DisplaySingleWarning   - Boolean - if True, this warning is the only one warning to be
//                            shown in the warning list.
//   ActionIfMarked         - Structure with the following fields:
//                             * Form           - String    - path to the form to be opened.
//                             * FormParameters - Structure - arbitrary parameter structure of
//                                                            Form. 
//   ActionOnHyperlinkClick - Structure with the following fields:
//                             * Form                         - String - path to the form to   
//                                                              be opened when the user clicks
//                                                              the hyperlink.
//                             * FormParameters               - Structure - arbitrary parameter 
//                                                              structure for the form 
//                                                              described above.
//                             * AppliedWarningForm           - String - path to the form to be 
//                                                              opened instead of the standard 
//                                                              form if the current warning is  
//                                                              the only one in the list.
//                             * AppliedWarningFormParameters - Structure - arbitrary parameter
//                                                              structure for the form
//                                                              described above.
//
Function ExitWarning() Export
	
	ActionIfMarked = New Structure;
	ActionIfMarked.Insert("Form", "");
	ActionIfMarked.Insert("FormParameters", Undefined);
	
	ActionOnHyperlinkClick = New Structure;
	ActionOnHyperlinkClick.Insert("Form", "");
	ActionOnHyperlinkClick.Insert("FormParameters", Undefined);
	ActionOnHyperlinkClick.Insert("ApplicationWarningForm", "");
	ActionOnHyperlinkClick.Insert("ApplicationWarningFormParameters", Undefined);
	
	WarningParameters = New Structure;
	WarningParameters.Insert("CheckBoxText", "");
	WarningParameters.Insert("InformationText", "");
	WarningParameters.Insert("ExtendedTooltip", "");
	WarningParameters.Insert("HyperlinkText", "");
	WarningParameters.Insert("ActionIfMarked", ActionIfMarked);
	WarningParameters.Insert("ActionOnHyperlinkClick", ActionOnHyperlinkClick);
	WarningParameters.Insert("Priority", 0);
	WarningParameters.Insert("DisplaySingleWarning", False);
	
	Return WarningParameters;
	
EndFunction
		
// After the warning, calls the procedure with the following parameters: Result,
// AdditionalParameters.
//
// Parameters:
//  Parameters - Structure with the following property:
//                ContinuationHandler - NotifyDescription - contains a procedure with two
//                                        parameters: Result, AdditionalParameters.
//
//  WarningText - String - text of the warning to be shown.
//
Procedure ShowMessageBoxAndContinue(Parameters, WarningText) Export
	
	NotificationWithResult = Parameters.ContinuationHandler;
	
	If WarningText = Undefined Then
		ExecuteNotifyProcessing(NotificationWithResult);
		Return;
	EndIf;
		
	If Parameters.Cancel  Then
		
		Buttons = New  ValueList();
		Buttons.Add("Restart", NStr("en = 'Restart'"));
		Buttons.Add("Exit",    NStr("en = 'Exit application'"));
		
		QuestionParameters =  QuestionToUserParameters();
		QuestionParameters.DefaultButton = "Restart";
		QuestionParameters.TimeoutButton = "Restart";
		QuestionParameters.Timeout = 60;
		QuestionParameters.SuggestDontAskAgain = False;
		QuestionParameters.LockWholeInterface  = True;
		QuestionParameters.Picture = PictureLib.Warning32;
		
	Else

		Buttons = New  ValueList();
		Buttons.Add("Continue",  NStr("en = 'Continue'"));
		If Parameters.Property("Restart") Then
			Buttons.Add("Restart", NStr("en = 'Restart'"));
		EndIf;
		Buttons.Add("Exit", NStr("en = 'Exit application'"));
		
		QuestionParameters =  QuestionToUserParameters();
		QuestionParameters.DefaultButton = "Continue";
		QuestionParameters.SuggestDontAskAgain = False;
		QuestionParameters.LockWholeInterface  = True;
		QuestionParameters.Picture = PictureLib.Warning32;
		
	EndIf;
	
	ClosingNotification = New NotifyDescription("ShowMessageBoxAndContinueExit", ThisObject, Parameters);
	ShowQuestionToUser(ClosingNotification,  WarningText, Buttons,  QuestionParameters);
	
EndProcedure
 
// Shows the file selection dialog and puts the selected files to the temporary storage.
// Combines features of the BeginPutFile and PutFiles global methods. Returns the same result
// with and without the file system extension installed.
//
// Parameters:
//  ResultHandler    - NotifyDescription - description of the procedure that receives the
//                     result.
//  FormID   - UUID -  UUID of the form that initialized the file putting.
//  FileName         - String - Full path and file name to be suggested to the user at the
//                     beginning of selection.
//  DialogParameters - Structure, Undefined - see FileDialog properties in the Syntax 
//                     Assistant. Is used if the file system extension is attached.
//
// Value of the first parameter returned to ResultHandler:
//  PlacedFiles - Selection result.
//   * Undefined - The user canceled the selection.
//   * Array of TransferedFileDescription, Structure - the user selected a file.
//            ** Name    - String - full name of the selected file.
//            ** Storage - String - address in the temporary storage where the file is.
//
// Restriction:
//   For interactive selection in a dialog only.
//   Directories cannot be selected, this option is not supported in the web client mode.
//   Multiselection in the web client mode is not supported unless the file system extension is 
//   not installed.
//   Temporary storage address cannot be passed.
//
Procedure ShowFilePutting(ResultHandler,  FormID, FileName, DialogParameters) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ResultHandler", ResultHandler);
	
	If AttachFileSystemExtension() Then
		
		If DialogParameters = Undefined Then
			DialogParameters = New Structure;
		EndIf;
		If DialogParameters.Property("Mode") Then
			Mode = DialogParameters.Mode;
			If Mode =  FileDialogMode.ChooseDirectory Then
				Raise NStr("en = 'Cannot select a directory'");
			EndIf;
		Else
			Mode = FileDialogMode.Open;
		EndIf;
		
		Dialog = New FileDialog(Mode);
		Dialog.FullFileName = FileName;
		FillPropertyValues(Dialog, DialogParameters);
		
		PlacedFiles = New  Array;
		SelectionDone = PutFiles(, PlacedFiles, Dialog, True,  FormID);
		ProcessFilePuttingResult(SelectionDone, PlacedFiles, Undefined, AdditionalParameters);
		
	Else
		
		Handler = New  NotifyDescription("ProcessFilePuttingResult",  ThisObject, AdditionalParameters);
		BeginPutFile(Handler, , FileName, True, FormID);
		
	EndIf;
	
EndProcedure

// ShowFilePutting procedure execution result handler.
//
Procedure ProcessFilePuttingResult(SelectionDone, AddressOrSelectionResult, SelectedFileName, AdditionalParameters) Export
	If SelectionDone =  True Then
		If TypeOf(AddressOrSelectionResult) = Type("Array") Then
			PlacedFiles = AddressOrSelectionResult;
		Else
			FileDetails = New Structure;
			FileDetails.Insert("Location", AddressOrSelectionResult);
			FileDetails.Insert("Name",    SelectedFileName);
			PlacedFiles = New Array;
			PlacedFiles.Add(FileDetails);
		EndIf;
	Else
		PlacedFiles = Undefined;
	EndIf;
	
	ExecuteNotifyProcessing(AdditionalParameters.ResultHandler,  PlacedFiles);
EndProcedure
 
////////////////////////////////////////////////////////////////////////////////
// Result processing

// Displays the operation execution result.
//
// Is intended only for displaying the result of server processing on the client. Does not
// intended for displaying intermediate stages as dialogs and so on.
//
// See also:
//   StandardSubsystemsClientServer.NewExecutionResult()
//   StandardSubsystemsClientServer.PrepareDynamicListNotification()
//
// Parameters:
//   Form   - ManagedForm - form for which the result will be shown.
//   Result - Structure - operation execution result to be displayed.
//             * NotificationOutput      - Structure - popup notification.
//                                           ** Use     - Boolean - show notification.
//                                           ** Title   - String - notification title.
//                                           ** Text    - String - notification text.
//                                           ** Link    - String - text hyperlink.
//                                           ** Picture - Picture - notification picture.
//             * MessageOutput           - Structure - form message attached to the attribute.
//                                          ** Use                 - Boolean - show message.
//                                          ** Text                - String - message text.
//                                          ** PathToFormAttribute - String - path to the form 
//                                                                   attribute, to which the
//                                                                   message relates.
//             * WarningOutput           - Structure - warning window that locks the whole
//                                         interface.
//                                          ** Use                 - Boolean - show warning.
//                                          ** Title               - String - window title.
//                                          ** Text                - String - warning text.
//                                          ** ErrorsText          - String - optional. Texts
//                                                                   of errors that the user 
//                                                                   can look over.
//                                          ** PathToFormAttribute - String - optional. The
//                                                                   path to the form attribute
//                                                                   whose value caused the
//                                                                   error.
//             * FormNotification        - Structure, Array of Structure - see the details on
//                                         the Notify() global context method.
//                                          ** Use       - Boolean - notify form opening.
//                                          ** EventName - String - name of the event used for
//                                                         primary message identification in
//                                                         the target forms.
//                                          ** Parameter - Arbitrary - set of data used by the
//                                                         target form for updating the
//                                                         content.
//                                          ** Source    - Arbitrary - notification source, for
//                                                         example a source form.
//             * DynamicListNotification - Structure - see the details on the NotifyChanged()
//                                         global context method.
//                                          ** Use              - Boolean - Notify dynamic
//                                                                lists.
//                                          ** ReferenceOrType  - Arbitrary - reference, type,
//                                                                or an array of types to be
//                                                                updated.
//
Procedure ShowExecutionResult(Form, Result) Export
	
	If TypeOf(Result) <> Type("Structure") And TypeOf(Result) <> Type("FixedStructure") Then
		Return;
	EndIf;
	
	If Result.Property("NotificationOutput") And Result.NotificationOutput.Use Then
		Notification = Result.NotificationOutput;
		ShowUserNotification(Notification.Title, Notification.Ref, Notification.Text, Notification.Picture);
	EndIf;
	
	If Result.Property("MessageOutput") And Result.MessageOutput.Use Then
		Message = New UserMessage;
		If TypeOf(Form) = Type("ManagedForm") Then
			Message.TargetID = Form.UUID;
		EndIf;
		Message.Text = Result.MessageOutput.Text;
		Message.Field = Result.MessageOutput.PathToFormAttribute;
		Message.Message();
	EndIf;
	
	If Result.Property("WarningOutput") And Result.WarningOutput.Use  Then
		WarningOutput = Result.WarningOutput;
		If ValueIsFilled(WarningOutput.ErrorsText) Then
			Buttons = New  ValueList;
			Buttons.Add(1, NStr("en = 'Show report'"));
			If TypeOf(Form) = Type("ManagedForm") And ValueIsFilled(WarningOutput.PathToFormAttribute) Then
				Buttons.Add(2,  NStr("en = 'Go to attribute'"));
			EndIf;
			Buttons.Add(0, NStr("en = 'Continue'"));
			
			AdditionalParameters = New Structure;
			AdditionalParameters.Insert("WarningOutput", WarningOutput);
			AdditionalParameters.Insert("Form",  Form);
			Handler = New  NotifyDescription("ShowExecutionResultCompletion", ThisObject,  AdditionalParameters);
			
			ShowQueryBox(Handler, WarningOutput.Text, Buttons, , 1, WarningOutput.Title);
		Else
			ShowMessageBox(, WarningOutput.Text, , WarningOutput.Title);
		EndIf;
	EndIf;
	
	If Result.Property("FormNotification") Then
		If TypeOf(Result.FormNotification) = Type("Structure") Or TypeOf(Result.FormNotification) = Type("FixedStructure") Then
			FormNotification = Result.FormNotification;
			If FormNotification.Use Then
				Notify(FormNotification.EventName, FormNotification.Parameter, FormNotification.Source);
			EndIf;
		Else
			For Each FormNotification In Result.FormNotification Do
				If FormNotification.Use Then
					Notify(FormNotification.EventName, FormNotification.Parameter, FormNotification.Source);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	If Result.Property("DynamicListNotification")  And Result.DynamicListNotification.Use Then
		If TypeOf(Result.DynamicListNotification.ReferenceOrType) = Type("Array") Then
			For Each ReferenceOrType In Result.DynamicListNotification.ReferenceOrType Do
				NotifyChanged(ReferenceOrType);
			EndDo;
		Else
			NotifyChanged(Result.DynamicListNotification.ReferenceOrType);
		EndIf;
	EndIf;
	
EndProcedure
 
// Handles a user answer on the question about execution result showing.
//
Procedure ShowExecutionResultCompletion(Answer, Result) Export
	
	If Answer = 1 Then
		
		DocumentTitle = Result.WarningOutput.Text;
		DocumentTitle = StrReplace(DocumentTitle, Chars.LF, ";");
		If StrLen(DocumentTitle) > 75 Then
			DocumentTitle = Left(DocumentTitle, 72) + "...";
		EndIf;
		
		TextDocument = New TextDocument;
		TextDocument.SetText(Result.WarningOutput.ErrorsText);
		TextDocument.Show(DocumentTitle);
		
	ElsIf Answer = 2 Then
		
		Message = New UserMessage;
		Message.TargetID = Result.Form.UUID;
		Message.Text = Result.WarningOutput.Text;
		Message.Field = Result.WarningOutput.PathToFormAttribute;
		Message.Message();
		
	EndIf;
	
EndProcedure
 
////////////////////////////////////////////////////////////////////////////////
// Handlers of conditional calls of other subsystems

// Opens the service user password input form.
//
// Parameters:
//   ContinuationHandler - NotifyDescription - to be processed after the password is
//                           entered.
//   OwnerForm             - Undefined, ManagedForm - form that requests the password.
//   ServiceUserPassword   - String - current service user password.
//
Procedure PasswordForAuthenticationInServiceOnRequest(ContinuationHandler, OwnerForm = Undefined, ServiceUserPassword = Undefined) Export
	
	If CommonUseClient.SubsystemExists("StandardSubsystems.SaaSOperations.UsersSaaS")  Then
		
		UsersInternalSaaSOperationsClientModule = CommonUseClient.CommonModule(
			"UsersInternalSaaSClient");
		
		UsersInternalSaaSOperationsClientModule.RequestPasswordForAuthenticationInService(
			ContinuationHandler, OwnerForm, ServiceUserPassword);
	EndIf;
	
EndProcedure
 
// Modifies the notification without result to the notification with result

Function NotificationWithoutResult(NotificationWithResult) Export
	
	Return New NotifyDescription("NotifyWithEmptyResult", ThisObject,  NotificationWithResult);
	
EndFunction

#EndRegion
 
#Region InternalProceduresAndFunctions

////////////////////////////////////////////////////////////////////////////////
// BeforeStart

// For internal use only. Continues the execution of BeforeStart procedure.
Procedure ActionsBeforeStartAfterPlatformVersionVerification(NotDefined, Parameters) Export
	
	If Not ContinueActionsBeforeStart(Parameters) Then
		Return;
	EndIf;
	
	Parameters.Insert("ContinuationHandler", New NotifyDescription(
		"ActionsBeforeStartAfterReconnectToMasterNode", ThisObject, Parameters));
	
	Try
		CheckReconnectToMasterNodeRequired(Parameters);
	Except
		HandleErrorOnStartOrExit(Parameters, ErrorInfo(), "Start", True);
	EndTry;
	If BeforeStartInteractiveHandler(Parameters) Then
		Return;
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler, False);
	
EndProcedure
 
// For internal use only. Continues the execution of BeforeStart procedure.
Procedure ActionsBeforeStartAfterReconnectToMasterNode(NotDefined, Parameters) Export
	
	If Not ContinueActionsBeforeStart(Parameters) Then
		Return;
	EndIf;
	
	If CommonUseClient.SubsystemExists("StandardSubsystems.SaaSOperations") Then
		
		Parameters.Insert("ContinuationHandler", Parameters.CompletionHandler);
		Try
			SaaSOperationsClientModule =  CommonUseClient.CommonModule("SaaSOperationsClient");
			SaaSOperationsClientModule.BeforeStart(Parameters);
		Except
			HandleErrorOnStartOrExit(Parameters, ErrorInfo(), "Start", True);
		EndTry;
		If  BeforeStartInteractiveHandler(Parameters) Then
			Return;
		EndIf;
	EndIf;
	
	Parameters.Insert("ContinuationHandler", New NotifyDescription(
		"ActionsBeforeStartAfterCheckForUpdateLegality", ThisObject, Parameters));
	
	If CommonUseClient.SubsystemExists(
		   "StandardSubsystems.LegitimateSoftwareCheck") Then
		
		Try
			LegitimateSoftwareCheckClientModule =
				CommonUseClient.CommonModule("LegitimateSoftwareCheckClient");
			
			LegitimateSoftwareCheckClientModule.CheckInfobaseUpdatedLegallyOnStart(Parameters);
		Except
			HandleErrorOnStartOrExit(Parameters, ErrorInfo(), "Start", True);
		EndTry;
		If  BeforeStartInteractiveHandler(Parameters) Then
			Return;
		EndIf;
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler, False);
	
EndProcedure
 
// For internal use only. Continues the execution of BeforeStart procedure.
Procedure ActionsBeforeStartAfterCheckForUpdateLegality(NotDefined, Parameters) Export
	
	If Not ContinueActionsBeforeStart(Parameters) Then
		Return;
	EndIf;
	
	Parameters.Insert("ContinuationHandler", New NotifyDescription(
		"ActionsBeforeStartAfterRepeatImportDataExchangeMessage", ThisObject, Parameters));
	
	Try
		If CommonUseClient.SubsystemExists("StandardSubsystems.DataExchange") Then
			// Selecting whether data exchange message import must be repeated
			DataExchangeClientModule =  CommonUseClient.CommonModule("DataExchangeClient");
			DataExchangeClientModule.BeforeStart(Parameters);
		EndIf;
	Except
		HandleErrorOnStartOrExit(Parameters, ErrorInfo(), "Start", True);
	EndTry;
	If  BeforeStartInteractiveHandler(Parameters) Then
		Return;
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler, False);
	
EndProcedure
 
// For internal use only. Continues the execution of BeforeStart procedure.
Procedure ActionsBeforeStartAfterRepeatImportDataExchangeMessage(NotDefined, Parameters) Export
	
	If Not ContinueActionsBeforeStart(Parameters) Then
		Return;
	EndIf;
	
	ClientParameters = StandardSubsystemsClientCached.ClientParametersOnStart();
	If ClientParameters.CanUseSeparatedData Then
		
		Parameters.Insert("ContinuationHandler", New NotifyDescription(
			"ActionsBeforeStartAfterApplicatioParametersUpdate", ThisObject, Parameters));
	Else
		Parameters.Insert("ContinuationHandler", New NotifyDescription(
			"ActionsBeforeStartAfterOverridableProcedure", ThisObject, Parameters));
	EndIf;
	
	Try
		// - Stopping when locking the infobase for update.
		// - Preparing application run parameters.
		// - Updating shared data.
		InfobaseUpdateClient.BeforeStart(Parameters);
	Except
		HandleErrorOnStartOrExit(Parameters, ErrorInfo(), "Start", True);
	EndTry;
	
	If BeforeStartInteractiveHandler(Parameters) Then
		Return;
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure
 
 // For internal use only. Continues the execution of BeforeStart procedure.

Procedure ActionsBeforeStartAfterApplicatioParametersUpdate(NotDefined, Parameters) Export
	
	If Not ContinueActionsBeforeStart(Parameters) Then
		Return;
	EndIf;
	
	Parameters.Insert("ContinuationHandler", Parameters.CompletionHandler);
	
	If CommonUseClient.SubsystemExists(
		"StandardSubsystems.SaaSOperations.DataExchangeSaaS")  Then
		
		StandaloneModeInternalClientModule = CommonUseClient.CommonModule("StandaloneModeInternalClient");
		Try
			StandaloneModeInternalClientModule.BeforeStart(Parameters);
		Except
			HandleErrorOnStartOrExit(Parameters, ErrorInfo(), "Start", True);
		EndTry;
		If  BeforeStartInteractiveHandler(Parameters) Then
			Return;
		EndIf;
	EndIf;
	
	Try
		UsersInternalClient.BeforeStart(Parameters);
	Except
		HandleErrorOnStartOrExit(Parameters, ErrorInfo(), "Start", True);
	EndTry;
	If  BeforeStartInteractiveHandler(Parameters) Then
		Return;
	EndIf;
	
	Try
		SetAdvancedApplicationCaption(True); // For auxiliary windows
	Except
		HandleErrorOnStartOrExit(Parameters, ErrorInfo(), "Start", True);
	EndTry;
	If  BeforeStartInteractiveHandler(Parameters) Then
		Return;
	EndIf;
	
	Parameters.Insert("ContinuationHandler", New NotifyDescription(
		"ActionsBeforeStartAfterProcessingLogOnWithUnlockCode", ThisObject, Parameters));
	
	If CommonUseClient.SubsystemExists("StandardSubsystems.UserSessions") Then
		
		Try
			InfobaseConnectionsClientModule = CommonUseClient.CommonModule("InfobaseConnectionsClient");
			InfobaseConnectionsClientModule.BeforeStart(Parameters);
		Except
			HandleErrorOnStartOrExit(Parameters, ErrorInfo(), "Start", True);
		EndTry;
		If  BeforeStartInteractiveHandler(Parameters) Then
			Return;
		EndIf;
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure
 
// For internal use only. Continues the execution of BeforeStart procedure.
Procedure ActionsBeforeStartAfterProcessingLogOnWithUnlockCode(NotDefined, Parameters) Export
	
	If Not ContinueActionsBeforeStart(Parameters) Then
		Return;
	EndIf;
	
	Parameters.Insert("NextHandlerNumber", 1);
	Parameters.Insert("ContinuationHandler", New NotifyDescription(
		"ActionsBeforeStartInInternalEventHandlers", ThisObject, Parameters));
		
	Try
		InfobaseUpdateClient.UpdateInfobase(Parameters);
	Except
		HandleErrorOnStartOrExit(Parameters, ErrorInfo(), "Start", True);
	EndTry;
	
	If BeforeStartInteractiveHandler(Parameters) Then
		Return;
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure
 
// For internal use only. Continues the execution of BeforeStart procedure.
Procedure  ActionsBeforeStartInInternalEventHandlers(NotDefined, Parameters) Export
	
	If Not  ContinueActionsBeforeStart(Parameters) Then
		Return;
	EndIf;
	
	EventHandlers = CommonUseClient.InternalEventHandlers(
		"StandardSubsystems.BaseFunctionality\BeforeStart");
	
	HandlerCount =  EventHandlers.Count();
	InitialNumber = Parameters.NextHandlerNumber;
	
	For Number = InitialNumber to HandlerCount Do
		Parameters.InteractiveHandler = Undefined;
		Parameters.NextHandlerNumber = Number + 1;
		Handler = EventHandlers.Get(Number - 1);
		
		Try
			Handler.Module.BeforeStart(Parameters);
		Except
			HandleErrorOnStartOrExit(Parameters, ErrorInfo(), "Start");
		EndTry;
		If BeforeStartInteractiveHandler(Parameters) Then
			Return;
		EndIf;
	EndDo;
	
	Parameters.Insert("ContinuationHandler", New NotifyDescription(
		"ActionsBeforeStartAfterOverridableProcedure", ThisObject, Parameters));
	
	Parameters.InteractiveHandler = Undefined;
		
	Try
		CommonUseClientOverridable.BeforeStart(Parameters);
	Except
		HandleErrorOnStartOrExit(Parameters, ErrorInfo(), "Start");
	EndTry;
	If  BeforeStartInteractiveHandler(Parameters) Then
		Return;
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure
 
// For internal use only. Continues the execution of BeforeStart procedure.
Procedure ActionsBeforeStartAfterOverridableProcedure(NotDefined, Parameters) Export
	
	If Not ContinueActionsBeforeStart(Parameters) Then
		Return;
	EndIf;
	
	Parameters.Insert("ContinuationHandler", Parameters.CompletionHandler);
	
	Try
		SetInterfaceFunctionalOptionParametersOnStart();
	Except
		HandleErrorOnStartOrExit(Parameters, ErrorInfo(), "Start", True);
	EndTry;
	If  BeforeStartInteractiveHandler(Parameters) Then
		Return;
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure
 
// For internal use only. The BeforeStart procedure completion.
Procedure ActionsBeforeStartCompletionHandler(NotDefined, Parameters) Export
	
	ParametersOnApplicationStartAndExit.Delete("RetrievedClientParameters");
	
	If Parameters.CompletionNotification <> Undefined Then
		Result = New Structure;
		Result.Insert("Cancel", Parameters.Cancel);
		Result.Insert("Restart", Parameters.Restart);
		Result.Insert("AdditionalParametersOfCommandLine", Parameters.AdditionalParametersOfCommandLine);
		ExecuteNotifyProcessing(Parameters.CompletionNotification, Result);
		Return;
	EndIf;
	
	If Parameters.Cancel Then
		If Parameters.Restart <> True Then
			Terminate();
		ElsIf ValueIsFilled(Parameters.AdditionalParametersOfCommandLine) Then
			Terminate(Parameters.Restart, Parameters.AdditionalParametersOfCommandLine);
		Else
			Terminate(Parameters.Restart);
		EndIf;
		
	ElsIf Not  Parameters.ContinuousExecution Then
		If  ParametersOnApplicationStartAndExit.Property("ProcessingParameters") Then
			ParametersOnApplicationStartAndExit.Delete("ProcessingParameters");
		EndIf;
		AttachIdleHandler("OnStartIdleHandler", 0.1, True);
	EndIf;
	
EndProcedure
 
////////////////////////////////////////////////////////////////////////////////
// OnStart

// For internal use only. Continues the execution of OnStart procedure.
Procedure ActionsOnStartInInternalEventHandlers(NotDefined, Parameters) Export

	If Parameters.Cancel Then
		ExecuteNotifyProcessing(Parameters.CompletionHandler);
		Return;
	EndIf;
	
	EventHandlers = CommonUseClient.InternalEventHandlers(
		"StandardSubsystems.BaseFunctionality\OnStart");
	
	HandlerCount = EventHandlers.Count();
	InitialNumber = Parameters.NextHandlerNumber;
	
	For Number = InitialNumber to HandlerCount Do
		Parameters.NextHandlerNumber = Number + 1;
		Handler = EventHandlers.Get(Number - 1);
		
		Try
			Handler.Module.OnStart(Parameters);
		Except
			HandleErrorOnStartOrExit(Parameters, ErrorInfo(), "Start");
		EndTry;
		If  OnStartInteractiveHandler(Parameters) Then
			Return;
		EndIf;
	EndDo;
	
	// Preparing to proceed to the next procedure
	Parameters.Insert("NextHandlerNumber", 1);
	Parameters.Insert("ContinuationHandler", New NotifyDescription(
		"ActionsAfterStartInInternalEventHandlers", ThisObject, Parameters));
	
	Try
		CommonUseClientOverridable.OnStart(Parameters);
	Except
		HandleErrorOnStartOrExit(Parameters, ErrorInfo(), "Start");
	EndTry;
	If  OnStartInteractiveHandler(Parameters) Then
		Return;
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure
 
// For internal use only. Continues the execution of OnStart procedure.
Procedure ActionsAfterStartInInternalEventHandlers(NotDefined, Parameters) Export

	If Parameters.Cancel Then
		ExecuteNotifyProcessing(Parameters.CompletionHandler);
		Return;
	EndIf;
	
	EventHandlers = CommonUseClient.InternalEventHandlers(
		"StandardSubsystems.BaseFunctionality\AfterStart");
	
	HandlerCount = EventHandlers.Count();
	InitialNumber = Parameters.NextHandlerNumber;
	
	For Number = InitialNumber to HandlerCount Do
		Parameters.NextHandlerNumber = Number + 1;
		Handler = EventHandlers.Get(Number - 1);
		
		Try
			Handler.Module.AfterStart();
		Except
			HandleErrorOnStartOrExit(Parameters, ErrorInfo(), "Start");
		EndTry;
		If  OnStartInteractiveHandler(Parameters) Then
			Return;
		EndIf;
	EndDo;
	
	Parameters.Insert("ContinuationHandler", Parameters.CompletionHandler);
	Try
		CommonUseClientOverridable.AfterStart();
	Except
		HandleErrorOnStartOrExit(Parameters, ErrorInfo(), "Start");
	EndTry;
	If  OnStartInteractiveHandler(Parameters) Then
		Return;
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure
 
// For internal use only. The OnStart procedure completion.
Procedure ActionsOnStartCompletionHandler(NotDefined, Parameters) Export
	
	If Not Parameters.Cancel Then
		If  ParametersOnApplicationStartAndExit.Property("SkipClearingDesktopHiding") Then
			ParametersOnApplicationStartAndExit.Delete("SkipClearingDesktopHiding");
		EndIf;
		HideDesktopOnStart(False);
	EndIf;
	
	If Parameters.CompletionNotification <> Undefined Then
		
		Result = New Structure;
		Result.Insert("Cancel", Parameters.Cancel);
		Result.Insert("Restart", Parameters.Restart);
		Result.Insert("AdditionalParametersOfCommandLine", Parameters.AdditionalParametersOfCommandLine);
		ExecuteNotifyProcessing(Parameters.CompletionNotification, Result);
		Return;
		
	Else
		If Parameters.Cancel  Then
			If Parameters.Restart <> True Then
				Terminate();
				
			ElsIf ValueIsFilled(Parameters.AdditionalParametersOfCommandLine) Then
				Terminate(Parameters.Restart, Parameters.AdditionalParametersOfCommandLine);
			Else
				Terminate(Parameters.Restart);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure
 
// Processes the application start parameters.
//
// Returns:
//   Boolean - True if the OnStart procedure execution must be aborted.
//
Function ProcessLaunchParameters()

	If IsBlankString(LaunchParameter) Then
		Return True;
	EndIf;
	
	// The parameter can be separated with the semicolons symbol (;).
	// The first part is the main start parameter value. 
	// Existence of the additional parts is determined by the logic of the main parameter
	// processing.
	LaunchParameters = StringFunctionsClientServer.SplitStringIntoSubstringArray(LaunchParameter, ";");
	FirstParameter = Upper(LaunchParameters[0]);
	
	Cancel = False;
	EventHandlers =  CommonUseClient.InternalEventHandlers(
		"StandardSubsystems.BaseFunctionality\LaunchParametersOnProcess");
	
	For Each Handler  In EventHandlers Do
		Handler.Module.LaunchParametersOnProcess(FirstParameter, LaunchParameters, Cancel);
	EndDo;
	
	//Cancel =  CommonUseClientOverridable.ProcessLaunchParameters(
		//FirstParameter, LaunchParameters) Or Cancel;
	
	If Not Cancel Then
		CommonUseClientOverridable.LaunchParametersOnProcess(FirstParameter, LaunchParameters, Cancel);
	EndIf;
	
	Return Not  Cancel;
	
EndFunction
 
////////////////////////////////////////////////////////////////////////////////
// BeforeExit

// For internal use only. Continues the execution of BeforeExit procedure.
Procedure ActionsBeforeExitInInternalEventHandlers(NotDefined, Parameters) Export

	// CI >
	//If Parameters.Cancel Then
	//	ExecuteNotifyProcessing(Parameters.CompletionHandler);
	//	Return;
	//EndIf;
	//
	//EventHandlers = CommonUseClient.InternalEventHandlers(
	//	"StandardSubsystems.BaseFunctionality\BeforeExit");
	//
	//HandlerCount =  EventHandlers.Count();
	//InitialNumber = Parameters.NextHandlerNumber;
	//
	//For Number =  InitialNumber to HandlerCount Do
	//	Parameters.NextHandlerNumber = Number + 1;
	//	Handler = EventHandlers.Get(Number - 1);
	//	Try
	//		Handler.Module.BeforeExit(Parameters);
	//	Except
	//		HandleErrorOnStartOrExit(Parameters, ErrorInfo(), "End");
	//	EndTry;
	//	If  BeforeExitInteractiveHandler(Parameters) Then
	//		Return;
	//	EndIf;
	//EndDo;
	//
	//Parameters.Insert("ContinuationHandler", New NotifyDescription(
	//	"ActionsBeforeExitAfterInternalEventHandlers", ThisObject, Parameters));
	//
	//Try
	//	CommonUseClientOverridable.BeforeExit(Parameters);
	//Except
	//	HandleErrorOnStartOrExit(Parameters, ErrorInfo(), "End");
	//EndTry;
	//If  BeforeExitInteractiveHandler(Parameters) Then
	//	Return;
	//EndIf;
	//
	//ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	// CI <
	
EndProcedure
 
// For internal use only. Continues the execution of BeforeExit procedure.
Procedure ActionsBeforeExitAfterInternalEventHandlers(NotDefined, Parameters) Export
	
	If Parameters.Cancel  Then
		ExecuteNotifyProcessing(Parameters.CompletionHandler);
		Return;
	EndIf;
	
	// If there are messages to be written to the event log in a variable, it's time to write them
	If TypeOf(MessagesForEventLog) = Type("ValueList") And MessagesForEventLog.Count() <> 0 Then
		EventLogOperationsServerCall.WriteEventsToEventLog(MessagesForEventLog);
	EndIf;
	
	Parameters.Insert("ContinuationHandler", Parameters.CompletionHandler);
	If StandardSubsystemsClientCached.ClientParameters().CanUseSeparatedData Then
		Try 
			OpenOnExitMessageForm(Parameters);
		Except
			HandleErrorOnStartOrExit(Parameters, ErrorInfo(), "End");
		EndTry;
		If  BeforeExitInteractiveHandler(Parameters) Then
			Return;
		EndIf;
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure
  
// For internal use only. The BeforeExit procedure completion.
Procedure ActionsBeforeExitCompletionHandler(NotDefined, Parameters) Export
	
	If Parameters.CompletionNotification <> Undefined Then
		
		Result = New Structure;
		Result.Insert("Cancel",  Parameters.Cancel);
		ExecuteNotifyProcessing(Parameters.CompletionNotification, Result);
		
	ElsIf Not Parameters.Cancel And Not Parameters.ContinuousExecution Then
		
		ParametersOnApplicationStartAndExit.Insert("ActionsBeforeExitMade");
		Exit();
	EndIf;
	
EndProcedure
 
// For internal use only. The BeforeExit procedure completion.
Procedure ActionsBeforeExitAfterErrorProcessing(NotDefined,  AdditionalParameters) Export
	
	Parameters = AdditionalParameters.Parameters;
	Parameters.ContinuationHandler = AdditionalParameters.ContinuationHandler;
	
	If Parameters.Cancel Then
		Parameters.Cancel =  False;
		ExecuteNotifyProcessing(Parameters.CompletionHandler);
	Else
		ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	EndIf;
	
EndProcedure
 
////////////////////////////////////////////////////////////////////////////////
// Other procedures and functions for application start and exit

// Checks whether the current version is equal or higher than the recommended one.
// If the platform version is earlier than RecommendedPlatformVersion, a warning is shown to 
// the user. The application is terminated if Exit = True.
//
// Returns:
// Boolean - True if the current version is relevant, otherwise is - False.
//
Procedure CheckPlatformVersionOnStart(Parameters)
	
	ClientParameters =  StandardSubsystemsClientCached.ClientParametersOnStart();
	
	If Not  ClientParameters.Property("ShowDeprecatedPlatformVersion") Then
		Return;
	EndIf;
	
	Parameters.InteractiveHandler = New NotifyDescription(
		"VersionPlatformCheckOnStartInteractiveHandler", ThisObject, Parameters);
	
EndProcedure
 
// For internal use only. Continues the execution of CheckPlatformVersionOnStart procedure.
Procedure VersionPlatformCheckOnStartInteractiveHandler(Parameters, NotDefined) Export
	
	ClientParameters = StandardSubsystemsClientCached.ClientParametersOnStart();
	
	If ClientParameters.MustExit Then
		If ClientParameters.HasAccessForUpdatingPlatformVersion Then
			MessageText = NStr("en = 'Cannot log on to the application.
				|Update the 1C:Enterprise platform version.'");
		Else
			MessageText = NStr("en = 'Cannot log on to the application.
				|Contact your system administrator for 1C:Enterprise platform version update.'");
		EndIf;
	Else
		If ClientParameters.HasAccessForUpdatingPlatformVersion Then
			MessageText = 
				NStr("en='We recommend that you exit from the application and update the 1C:Enterprise platform version.
			         |Otherwise some application features could be unavailable or could have unexpected behavior.'");
		Else
			MessageText = 
				NStr("en='We recommend that you exit from the application and connect your system administrator for 1C:Enterprise platform version update.
			         |Otherwise some application features could be unavailable or could have unexpected behavior.'");
		EndIf;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("MessageText", MessageText);
	FormParameters.Insert("Exit", ClientParameters.MustExit);
	FormParameters.Insert("RecommendedPlatformVersion", ClientParameters.LowestPlatformVersion);
	FormParameters.Insert("OpenByScenario", True);
	FormParameters.Insert("SkipExit", True);
	
	Form = OpenForm("DataProcessor.NotRecommendedPlatformVersion.Form.NotRecommendedPlatformVersion", FormParameters,
		, , , , New  NotifyDescription("AfterClosingFormsDeprecatedVersionPlatforms", ThisObject, Parameters));
	
	If Form = Undefined Then
		AfterClosingFormsDeprecatedVersionPlatforms("Continue", Parameters);
	EndIf;
	
EndProcedure
 
// For internal use only. Continues the execution of CheckPlatformVersionOnStart procedure.
Procedure AfterClosingFormsDeprecatedVersionPlatforms(Result, Parameters) Export
	
	If Result <> "Continue" Then
		Parameters.Cancel = True;
	Else
		Parameters.RetrievedClientParameters.Insert("ShowDeprecatedPlatformVersion");
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure
 
// Checks whether the master node must be reconnected and starts the reconnection if it is required.
Procedure CheckReconnectToMasterNodeRequired(Parameters)
	
	ClientParameters = StandardSubsystemsClientCached.ClientParametersOnStart();
	
	If Not ClientParameters.Property("ReconnectMasterNode") Then
		Return;
	EndIf;
	
	Parameters.InteractiveHandler = New NotifyDescription(
		"MasterNodeReconnectionInteractiveHandler", ThisObject, Parameters);
	
EndProcedure
 
// For internal use only. Continues the execution of CheckReconnectToMasterNodeRequired procedure.
Procedure  MasterNodeReconnectionInteractiveHandler(Parameters, NotDefined) Export
	
	ClientParameters = StandardSubsystemsClientCached.ClientParametersOnStart();
	
	If ClientParameters.ReconnectMasterNode = False Then
		Parameters.Cancel = True;
		ShowMessageBox(
			NotificationWithoutResult(Parameters.ContinuationHandler),
			NStr("en = 'Cannot log on to the application while the connection to the master node is not established.
			           |Contact your administrator for details.'"),
			15);
		Return;
	EndIf;
	
	Form = OpenForm("CommonForm.ReconnectionToMasterNode",,,,,,
		New NotifyDescription("ReconnectionToMasterNodeFormAfterClose", ThisObject, Parameters));
	
	If Form = Undefined Then
		ReconnectionToMasterNodeFormAfterClose(New Structure("Cancel",  True), Parameters);
	EndIf;
	
EndProcedure
 
// For internal use only. Continues the execution of CheckReconnectToMasterNodeRequired procedure.
Procedure ReconnectionToMasterNodeFormAfterClose(Result, Parameters) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		Parameters.Cancel =  True;
		
	ElsIf Result.Cancel Then
		Parameters.Cancel =  True;
	Else
		Parameters.RetrievedClientParameters.Insert("ReconnectMasterNode");
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure
 
// Is called if there is a need to open the list of active users to see who is logged on to the
// system now.
// 
Procedure OpenActiveUserList(FormParameters = Undefined) Export
	
	If CommonUseClient.SubsystemExists("StandardSubsystems.UserSessions") Then
		
		FormName = "";
		InfobaseConnectionsClientModule =  CommonUseClient.CommonModule("InfobaseConnectionsClient");
		InfobaseConnectionsClientModule.ActiveUserFormOnDefine(FormName);
		OpenForm(FormName,  FormParameters);
		
	Else
		
		ShowMessageBox(,
			NStr("en = 'To open the list of active users, in the Main menu, click All functions, expand the Standard branch, and click Active users'"));
		
	EndIf;
	
EndProcedure
 
// Hides the desktop when the application starts using flag that prevents form creation on the
// desktop.
// Makes the desktop visible and updates it when possible if the desktop is hidden.
//
// Parameters:
//  Hide                - Boolean - pass False to make desktop visible if it is hidden.
//
//  AlreadyDoneAtServer - Boolean - pass True if the method was already executed in the
//                        StandardSubsystemsServerCall module and it should not be executed
//                        again here but only set the flag showing that desktop is hidden and
//                        it will be shown lately.
//
Procedure HideDesktopOnStart(Hide = True, AlreadyDoneAtServer = False) Export
	
	If Hide Then
		If Not ParametersOnApplicationStartAndExit.Property("HideDesktopOnStart") Then
			ParametersOnApplicationStartAndExit.Insert("HideDesktopOnStart");
			If Not AlreadyDoneAtServer Then
				StandardSubsystemsServerCall.HideDesktopOnStart();
			EndIf;
		EndIf;
	Else
		If ParametersOnApplicationStartAndExit.Property("HideDesktopOnStart") Then
			ParametersOnApplicationStartAndExit.Delete("HideDesktopOnStart");
			If Not AlreadyDoneAtServer Then
				StandardSubsystemsServerCall.HideDesktopOnStart(False);
			EndIf;
			CurrentActiveWindow = ActiveWindow();
			RefreshInterface();
			If CurrentActiveWindow <> Undefined Then
				CurrentActiveWindow.Activate();
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure
 
// For internal use only
Procedure NotifyWithEmptyResult(NotificationWithResult) Export
	
	ExecuteNotifyProcessing(NotificationWithResult);
	
EndProcedure

// For internal use only
Procedure  StartBeforeExitInteractiveHandler() Export
	
	If Not  ParametersOnApplicationStartAndExit.Property("ExitProcessingParameters") Then
		Return;
	EndIf;
	
	Parameters =  ParametersOnApplicationStartAndExit.ExitProcessingParameters;
	ParametersOnApplicationStartAndExit.Delete("ExitProcessingParameters");
	
	ExecuteNotifyProcessing(Parameters.InteractiveHandler,  Parameters);
	
EndProcedure
 
 // For internal use only

Procedure ExitWarningFormAfterExit(Result, AdditionalParameters) Export
	
	Parameters = AdditionalParameters.Parameters;
	
	If AdditionalParameters.FormOption = "Question" Then
		
		If Result <> Undefined And Result.DontAskAgain Then
			StandardSubsystemsServerCall.SaveExitConfirmationSettings(
				Not Result.DontAskAgain);
		EndIf;
		
		If Result = Undefined Or Result.Value <> DialogReturnCode.Yes Then
			Parameters.Cancel =  True;
		EndIf;
		
	ElsIf AdditionalParameters.FormOption = "StandardForm" Then
	
		If Result = True Or Result = Undefined Then
			Parameters.Cancel = True;
		EndIf;
		
	Else // AppliedForm
		If Result = True Or Result = Undefined Or Result = DialogReturnCode.No Then
			Parameters.Cancel = True;
		EndIf;
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure
 
////////////////////////////////////////////////////////////////////////////////
// Auxiliary procedures and functions

// Casts parameters of different types with reference set to array
Function ReferenceSet(Val ReferenceSet)
	ParameterType = TypeOf(ReferenceSet);
	
	If TypeOf(ReferenceSet) = Type("FormTable") Then
		References = New  Array;
		For Each Item In ReferenceSet.SelectedRows  Do
			RowData = ReferenceSet.RowData(Item);
			If RowData <> Undefined Then
				References.Add(RowData.Ref);
			EndIf;
		EndDo;
		
	ElsIf ParameterType = Type("ValueList") Then
		References = New  Array;
		For Each Item In ReferenceSet Do
			References.Add(Item.Value);
		EndDo;
		
	Else
		References = ReferenceSet;
		
	EndIf;
	
	Return References;
EndFunction
 
// Returns a string presentation of the DialogReturnCode type
Function DialogReturnCodeInString(Value)
	
	Result = "DialogReturnCode." + String(Value);
	
	If Value =  DialogReturnCode.Yes Then
		Result = "DialogReturnCode.Yes";
	ElsIf Value =  DialogReturnCode.No Then
		Result = "DialogReturnCode.No";
	ElsIf Value =  DialogReturnCode.OK Then
		Result = "DialogReturnCode.OK";
	ElsIf Value =  DialogReturnCode.Cancel Then
		Result = "DialogReturnCode.Cancel";
	ElsIf Value =  DialogReturnCode.Retry Then
		Result = "DialogReturnCode.Retry";
	ElsIf Value =  DialogReturnCode.Abort Then
		Result = "DialogReturnCode.Abort";
	ElsIf Value =  DialogReturnCode.Ignore Then
		Result = "DialogReturnCode.Ignore";
	EndIf;
	
	Return Result;
	
EndFunction
 
// Sets the session separation on application start.
Procedure SetSessionSeparation()

	If IsBlankString(LaunchParameter) Then
		Return;
	EndIf;
	
	LaunchParameters = StringFunctionsClientServer.SplitStringIntoSubstringArray(LaunchParameter, ";");
	LaunchParameterValue = Upper(LaunchParameters[0]);
	
	If LaunchParameterValue <> Upper("LogOnToDataArea") Then
		Return;
	EndIf;
	
	If LaunchParameters.Count() < 2 Then
		Raise
			NStr("en = 'If the LogOnToDataArea startup parameter is set, specify the separator value in the additional parameters.'");
	EndIf;
	
	Try
		SeparatorValue = Number(LaunchParameters[1]);
	Except
		Raise
			NStr("en = 'Only a number can be passed as a separator value in the LogOnToDataArea parameter.'");
	EndTry;
	
	CommonUseServerCall.SetSessionSeparation(True, SeparatorValue);
	
EndProcedure
 
 // In case of cancel, calls the exit handler. If a new client parameter is added, updates
 // client run parameters.
 // 
Function ContinueActionsBeforeStart(Parameters)
	
	If Parameters.Cancel  Then
		ExecuteNotifyProcessing(Parameters.CompletionHandler);
		Return False;
	EndIf;
	
	UpdateClientParameters(Parameters);
	
	Return True;
	
EndFunction
 
// Updates the client parameters after interactive data processing on application start.
Procedure UpdateClientParameters(Parameters, InitialCall = False, RefreshReusableValues = True)
	
	If InitialCall Then
		If TypeOf(ParametersOnApplicationStartAndExit) <> Type("Structure") Then
			ParametersOnApplicationStartAndExit =  New Structure;
		EndIf;
		
	ElsIf Parameters.CountOfReceivedClientParameters =
	          Parameters.RetrievedClientParameters.Count() Then
		Return;
	EndIf;
	
	Parameters.Insert("CountOfReceivedClientParameters",
		Parameters.RetrievedClientParameters.Count());
	
	ParametersOnApplicationStartAndExit.Insert("RetrievedClientParameters",
		Parameters.RetrievedClientParameters);
	
	If RefreshReusableValues Then
		RefreshReusableValues();
	EndIf;
	
EndProcedure
 
Function BeforeStartInteractiveHandlerInProgress()

	
	If Not  ParametersOnApplicationStartAndExit.Property("ProcessingParameters") Then
		Return False;
	EndIf;
	
	Parameters =  ParametersOnApplicationStartAndExit.ProcessingParameters;
	
	If Parameters.InteractiveHandler <> Undefined Then
		Parameters.ContinuousExecution = False;
		InteractiveHandler = Parameters.InteractiveHandler;
		Parameters.InteractiveHandler = Undefined;
		ExecuteNotifyProcessing(InteractiveHandler,  Parameters);
		ParametersOnApplicationStartAndExit.Delete("ProcessingParameters");
		Return True;
	EndIf;
	
	Return False;
	
EndFunction
 
Function BeforeStartInteractiveHandler(Parameters)
	
	If Parameters.InteractiveHandler = Undefined Then
		If Parameters.Cancel Then
			ExecuteNotifyProcessing(Parameters.CompletionHandler);
			Return True;
		EndIf;
		Return False;
	EndIf;
	
	UpdateClientParameters(Parameters);
	
	If Not Parameters.ContinuousExecution Then
		InteractiveHandler = Parameters.InteractiveHandler;
		Parameters.InteractiveHandler = Undefined;
		ExecuteNotifyProcessing(InteractiveHandler,  Parameters);
		
	ElsIf Parameters.CompletionNotification = Undefined Then
		// Was called from the BeforeStart event handler for preparing the interactive processing in
		// the OnStart event handler.
		
		ParametersOnApplicationStartAndExit.Insert("ProcessingParameters", Parameters);
		HideDesktopOnStart();
		ParametersOnApplicationStartAndExit.Insert("SkipClearingDesktopHiding");
		SetInterfaceFunctionalOptionParametersOnStart();
	Else
		// Was called from the BeforeStart procedure for starting the interactive processing
		// immediately because the procedure was called from 1C:Enterprise script 
   // (i.e. not from the BeforeStart event handler).
		If  ParametersOnApplicationStartAndExit.Property("ProcessingParameters") Then
			ParametersOnApplicationStartAndExit.Delete("ProcessingParameters");
		EndIf;
		
		Parameters.ContinuousExecution = False;
		InteractiveHandler = Parameters.InteractiveHandler;
		Parameters.InteractiveHandler = Undefined;
		ExecuteNotifyProcessing(InteractiveHandler, Parameters);
	EndIf;
	
	Return True;
	
EndFunction
 
Function OnStartInteractiveHandler(Parameters)

	
	If Parameters.InteractiveHandler = Undefined Then
		If Parameters.Cancel  Then
			ExecuteNotifyProcessing(Parameters.CompletionHandler);
			Return True;
		EndIf;
		Return False;
	EndIf;
	
	InteractiveHandler = Parameters.InteractiveHandler;
	
	Parameters.ContinuousExecution = False;
	Parameters.InteractiveHandler = Undefined;
	
	ExecuteNotifyProcessing(InteractiveHandler,  Parameters);
	
	Return True;
	
EndFunction

Function BeforeExitInteractiveHandler(Parameters)
	
	If Parameters.InteractiveHandler = Undefined Then
		If Parameters.Cancel  Then
			ExecuteNotifyProcessing(Parameters.CompletionHandler);
			Return True;
		EndIf;
		Return False;
	EndIf;
	
	If Not Parameters.ContinuousExecution Then
		InteractiveHandler = Parameters.InteractiveHandler;
		Parameters.InteractiveHandler = Undefined;
		ExecuteNotifyProcessing(InteractiveHandler, Parameters);
		
	ElsIf Parameters.CompletionNotification = Undefined Then
		// Was called from the BeforeStart event handler for preparing the interactive processing
		// through the idle handler.
		
		ParametersOnApplicationStartAndExit.Insert("ExitProcessingParameters", Parameters);
		Parameters.ContinuousExecution = False;
		AttachIdleHandler(
			"BeforeExitInteractiveHandlerIdleHandler", 0.1, True);
	Else
		// Was called from the BeforeExit procedure for starting the interactive processing
		// immediately because the procedure was called from 1C:Enterprise script 
   // (i.e. not from the BeforeExit event handler).
		
		Parameters.ContinuousExecution = False;
		InteractiveHandler = Parameters.InteractiveHandler;
		Parameters.InteractiveHandler = Undefined;
		ExecuteNotifyProcessing(InteractiveHandler,  Parameters);
	EndIf;
	
	Return True;
	
EndFunction
 
// Displays a user message form or a message.
Procedure  OpenOnExitMessageForm(Parameters)
	
// In web client and thick client (ordinary application) modes, the list of warnings is not displayed.
#If WebClient Or ThickClientOrdinaryApplication Then
	Return;
#EndIf
	
	If  SkipExitConfirmation = True Then 
		Return;
	EndIf;
	
	Warnings = New  Array;
	
	EventHandlers = CommonUseClient.InternalEventHandlers(
		"StandardSubsystems.BaseFunctionality\OnGetExitWarningList");
	
	For Each Handler  In EventHandlers Do
		Handler.Module.OnGetExitWarningList(Warnings);
	EndDo;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Parameters", Parameters);
	AdditionalParameters.Insert("FormOption", "Question");
	
	ResponseHandler = New  NotifyDescription("ExitWarningFormAfterExit",
		ThisObject, AdditionalParameters);
	
	If Warnings.Count() = 0 Then
		
		DontAskAgain =
			Not  StandardSubsystemsClientCached.ClientParameters(
				).AskConfirmationOnExit;
		
		If DontAskAgain Then
			Return;
		EndIf;
		Parameters.InteractiveHandler = New NotifyDescription(
			"AskExitConfirmation", ThisObject, ResponseHandler);
	Else
		FormParameters = New  Structure;
		FormParameters.Insert("Warnings", Warnings);
		
		FormName = "CommonForm.ExitWarnings";
		
		If Warnings.Count() = 1 Then
			If Not  IsBlankString(Warnings[0].CheckBoxText) Then 
				AdditionalParameters.Insert("FormOption", "StandardForm");
				FormOpenParameters = New Structure;
				FormOpenParameters.Insert("FormName", FormName);
				FormOpenParameters.Insert("FormParameters", FormParameters);
				FormOpenParameters.Insert("ResponseHandler", ResponseHandler);
				Parameters.InteractiveHandler = New NotifyDescription(
					"ExitWarningInteractiveHandler", ThisObject,  FormOpenParameters);
			Else
				AdditionalParameters.Insert("FormOption", "AppliedForm");
				OpenApplicationWarningForm(Parameters, ResponseHandler, Warnings[0],  FormName, FormParameters);
			EndIf;
		Else
			AdditionalParameters.Insert("FormOption", "StandardForm");
			FormOpenParameters = New Structure;
			FormOpenParameters.Insert("FormName", FormName);
			FormOpenParameters.Insert("FormParameters", FormParameters);
			FormOpenParameters.Insert("ResponseHandler", ResponseHandler);
			Parameters.InteractiveHandler = New NotifyDescription(
				"ExitWarningInteractiveHandler", ThisObject, FormOpenParameters);
		EndIf;
	EndIf;
	
EndProcedure
 
// Continues the execution of OpenOnExitMessageForm procedure.
Procedure ExitWarningInteractiveHandler(Parameters, FormOpenParameters) Export
	
	OpenForm(
		FormOpenParameters.FormName,
		FormOpenParameters.FormParameters, , , , ,
		FormOpenParameters.ResponseHandler);
	
EndProcedure
 
// Continues the execution of ShowMessageBoxAndContinue procedure.
Procedure ShowMessageBoxAndContinueExit(Result, Parameters) Export
	
	If Result <> Undefined Then
		If Result.Value = "Exit" Then
			Parameters.Cancel =  True;
		ElsIf Result.Value = "Restart" Then
			Parameters.Cancel =  True;
			Parameters.Restart = True;
		EndIf;
	EndIf;
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure
 
// Shows the exit confirmation dialog to the user.
Procedure AskExitConfirmation(Parameters, ResponseHandler) Export
	
	Buttons = New ValueList;
	Buttons.Add("DialogReturnCode.Yes",  NStr("en = 'Exit'"));
	Buttons.Add("DialogReturnCode.No", NStr("en = 'Cancel'"));
	
	QuestionParameters = QuestionToUserParameters();
	QuestionParameters.LockWholeInterface = True;
	QuestionParameters.DefaultButton = "DialogReturnCode.Yes";
	QuestionParameters.Title = NStr("en = 'Exit'");
	QuestionParameters.DontAskAgain  = False;
	
	ShowQuestionToUser(ResponseHandler, NStr("en = 'Do you want to exit the application?'"), Buttons, QuestionParameters);
	
EndProcedure
 
// Generates representation of a single question.
//
// If the UserWarning has the HyperlinkText property, IndividualOpeningForm from the structure
// of the question is opened.
// If the UserWarning has the CheckBoxText property, CommonForm.QuestionBeforeExit is opened.
//
// Parameters:
//  Parameters      - pass-through parameter of the BeforeExit procedure call chain.
//  ResponseHandler - NotifyDescription to continue once the user answered the question.
//  UserWarning     - Structure - structure of the passed warning.
//  FormName        - String - name of the common form with questions.
//  FormParameters  - Structure - parameters of the form with questions.
//
Procedure OpenApplicationWarningForm(Parameters, ResponseHandler, UserWarning, FormName, FormParameters)
	
	HyperlinkText = "";
	If Not  UserWarning.Property("HyperlinkText", HyperlinkText) Then
		Return;
	EndIf;
	If IsBlankString(HyperlinkText) Then
		Return;
	EndIf;
	
	ActionOnHyperlinkClick = Undefined;
	If Not  UserWarning.Property("ActionOnHyperlinkClick", ActionOnHyperlinkClick) Then
		Return;
	EndIf;
	
	HyperlinkAction =  UserWarning.ActionOnHyperlinkClick;
	Form = Undefined;
	
	If HyperlinkAction.Property("ApplicationWarningForm", Form) Then
		FormParameters = Undefined;
		If HyperlinkAction.Property("ApplicationWarningFormParameters", FormParameters) Then
			If TypeOf(FormParameters) = Type("Structure") Then 
				FormParameters.Insert("ExitApplication", True);
			ElsIf FormParameters = Undefined Then 
				FormParameters = New Structure;
				FormParameters.Insert("ExitApplication", True);
			EndIf;
			
			FormParameters.Insert("YesButtonTitle",  NStr("en = 'Exit'"));
			FormParameters.Insert("TitleNoButton", NStr("en = 'Cancel'"));
			
		EndIf;
		FormOpenParameters = New Structure;
		FormOpenParameters.Insert("FormName", Form);
		FormOpenParameters.Insert("FormParameters", FormParameters);
		FormOpenParameters.Insert("ResponseHandler", ResponseHandler);
		Parameters.InteractiveHandler = New NotifyDescription(
			"ExitWarningInteractiveHandler", ThisObject, FormOpenParameters);
		
	ElsIf HyperlinkAction.Property("Form", Form) Then 
		FormParameters = Undefined;
		If HyperlinkAction.Property("FormParameters", FormParameters) Then
			If TypeOf(FormParameters) = Type("Structure") Then 
				FormParameters.Insert("ExitApplication", True);
			ElsIf FormParameters = Undefined Then 
				FormParameters = New Structure;
				FormParameters.Insert("ExitApplication", True);
			EndIf;
		EndIf;
		FormOpenParameters = New Structure;
		FormOpenParameters.Insert("FormName", Form);
		FormOpenParameters.Insert("FormParameters", FormParameters);
		FormOpenParameters.Insert("ResponseHandler", ResponseHandler);
		Parameters.InteractiveHandler = New NotifyDescription(
			"ExitWarningInteractiveHandler", ThisObject,  FormOpenParameters);
		
	EndIf;
	
EndProcedure
 
Procedure  HandleErrorOnStartOrExit(Parameters, ErrorInfo, Event, Exit = False)
	
	If Event = "Start" Then
		If Exit Then
			Parameters.Cancel =  True;
			Parameters.ContinuationHandler = Parameters.CompletionHandler;
		EndIf;
	Else
		AdditionalParameters = New Structure(
			"Parameters, ContinuationHandler", Parameters, Parameters.ContinuationHandler);
		
		Parameters.ContinuationHandler = New NotifyDescription(
			"ActionsBeforeExitAfterErrorProcessing", ThisObject, AdditionalParameters);
	EndIf;
	
	ErrorDetailsBeginning = StandardSubsystemsServerCall.WriteErrorToEventLogOnStartOrExit(
		Exit, Event, DetailErrorDescription(ErrorInfo));	
	
	WarningText = ErrorDetailsBeginning  + Chars.LF
		+ NStr("en = 'Technical error details have been saved to the event log.'")
		+ Chars.LF + Chars.LF
		+ BriefErrorDescription(ErrorInfo);
	
	InteractiveHandler = New NotifyDescription(
		"ShowMessageBoxAndContinue",
		StandardSubsystemsClient.ThisObject,
		WarningText);
	
	Parameters.InteractiveHandler = InteractiveHandler;
	
EndProcedure
 
Procedure SetInterfaceFunctionalOptionParametersOnStart()
	InterfaceOptions =  StandardSubsystemsClientCached.ClientParametersOnStart().InterfaceOptions;
	If TypeOf(InterfaceOptions) = Type("FixedStructure") Then
		#If WebClient Then
			Structure = New Structure;
			CommonUseClientServer.SupplementStructure(Structure, InterfaceOptions, True);
			InterfaceOptions = Structure;
		#Else
			InterfaceOptions = New Structure(InterfaceOptions);
		#EndIf
	EndIf;
	// Parameters of the functional options are set only if they are specified
	If InterfaceOptions.Count() > 0 Then
		SetInterfaceFunctionalOptionParameters(InterfaceOptions);
	EndIf;
	
EndProcedure

#EndRegion