////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
// Client procedures and functions of common use:
// - for working with lists on forms;
// - for working with the event log;
// - for user action processing during the user works with multiline text like comments in
//   documents;
// - others.
//  
/////////////////////////////////////////////////////////////////////////////////
 
#Region Interface

////////////////////////////////////////////////////////////////////////////////
// Functions for working with lists on forms

// Checks that there is a parameter of ExpectedType in Parameter.
// Otherwise this function shows a message box and returns False.
// This situation is possible, for example, when a row that contains a group is selected in 
// a list.
//
// The function is to be used in commands that work with dynamic list items in forms.
// Usage example:
// 
//   If Not CheckCommandParameterType(Items.List.SelectedRows, Type("TaskRef.PerformerTask")) Then
//    Return;
//   EndIf;
//   ...
// 
// Parameters:
//  Parameter    - Array or reference type - command parameter.
//  ExpectedType - Type - expected parameter type.
//
// Returns:
//  Boolean - True if the parameter type is the expected type.
//
Function CheckCommandParameterType(Val Parameter, Val ExpectedType) Export
	
	If Parameter = Undefined Then
		Return False;
	EndIf;
	
	Result = True;
	
	If TypeOf(Parameter) = Type("Array") Then
		// If there is only one item in the array and a type of it is incorrect
		Result = Not (Parameter.Count() = 1 And TypeOf(Parameter[0]) <> ExpectedType);
	Else
		Result = TypeOf(Parameter) = ExpectedType;
	EndIf;
	
	If Not Result  Then
		ShowMessageBox(,NStr("en = 'Command cannot be executed for the current object.'"));
	EndIf;
	
	Return Result;
	
EndFunction
 
////////////////////////////////////////////////////////////////////////////////
// Common use client procedures

// Returns the current date in the session time zone.
//
// Returned time is close to the CurrentSessionDate() function result in the server context.
// Calculating error is related to server call execution time.
// Is intended to be used instead of the CurrentDate() function.
//
Function SessionDate()  Export
	Return CurrentDate()  + StandardSubsystemsClientCached.ClientParameters().SessionTimeOffset;
EndFunction
 
// Returns the universal session date get from the current session date.
//
// Returned time is close to the ToUniversalTime() function result in the server context.
// Calculating error is related to server call execution time.
// Is intended to be used instead of the ToUniversalTime() function.
//
Function UniversalDate() Export
	ClientParameters =  StandardSubsystemsClientCached.ClientParameters();
	SessionDate = CurrentDate() + ClientParameters.SessionTimeOffset;
	Return SessionDate +  ClientParameters.UniversalTimeCorrection;
EndFunction
 
// Suggests the user to install the file system extension in the web client.
//
// Is intended to be used at the beginning of a script that processes files.
// For example:
//
//    Notification = New NotifyDescription("PrintDocumentCompletion", ThisObject);
//    MessageText = NStr("en='Document printing requires the file system extension to be installed.'");
//    CommonUseClient.ShowFileSystemExtensionInstallationQuestion(Notification, MessageText);
//
//    Procedure PrintDocumentCompletion(ExtensionAttached, AdditionalParameters) Export
//    If ExtensionAttached Then 
//      // script that prints a document using the extension
//      // ....
//    Else
//      // script that prints a document without extension attaching
//      // ....
//    EndIf;
//
// Parameters:
//    NotifyOnCloseDescription    - NotifyDescription - description of the procedure to be
//                                  called once the form is closed. Contains the following
//                                  parameters:
//                                   ExtensionAttached    - Boolean - True if the extension has
//                                                          been attached.
//                                   AdditionalParameters - Arbitrary - parameters defined in
//                                                          OnCloseNotifyDescription.
//    SuggestionText              - String - message text. If text is not specified, the
//                                  default text is displayed.
//   CanContinueWithoutInstalling - Boolean - if True is passed, the ContinueWithoutInstalling
//                                  button is shown, if False is passed, the Cancel button is
//                                  shown.
//
Procedure  ShowFileSystemExtensionInstallationQuestion(NotifyOnCloseDescription,  SuggestionText = "", 
	CanContinueWithoutInstalling = True) Export
	
	Notification = New NotifyDescription("ShowFileSystemExtensionInstallationQuestionCompletion", ThisObject, NotifyOnCloseDescription);
#If Not WebClient Then
	// In thin and thick clients the extension is always attached
	ExecuteNotifyProcessing(Notification);
	Return;
#EndIf
	
	// If the extension is already installed, there is no need to ask about it
	ExtensionAttached =  AttachFileSystemExtension();
	If ExtensionAttached Then 
		ExecuteNotifyProcessing(Notification);
		Return;
	EndIf;
	
	FirstCallInSession = (SuggestFileSystemExtensionInstallation = Undefined);
	If FirstCallInSession Then
		SuggestFileSystemExtensionInstallation = SuggestFileSystemExtensionInstallation();
	EndIf;
	
	If CanContinueWithoutInstalling And Not SuggestFileSystemExtensionInstallation Then
		ExecuteNotifyProcessing(Notification);
		Return;
	EndIf;
	
	If Not CanContinueWithoutInstalling Or FirstCallInSession Then
		FormParameters = New Structure;
		FormParameters.Insert("SuggestionText", SuggestionText);
		FormParameters.Insert("CanContinueWithoutInstalling", CanContinueWithoutInstalling);
		OpenForm("CommonForm.FileSystemExtensionInstallationQuestion", FormParameters,,,,,Notification);
	Else
		ExecuteNotifyProcessing(Notification);
	EndIf;
	
EndProcedure
 
// Suggests the user to attach the file system extension in the web client and, in case of
// refuse, notifies about impossibility of action continuation.
//
// Is intended to be used at the beginning of a script that can process files only if the file
// system extension is attached.
// For example:
//
//    Notification = New NotifyDescription("PrintDocumentCompletion", ThisObject);
//    MessageText = NStr("en = 'Document printing requires the file system extension to be attached.'"));
//    CommonUseClient.CheckFileSystemExtensionAttached(Notification, MessageText); 
//
//    Procedure PrintDocumentCompletion(Result, AdditionalParameters) Export
//     // script that can process files only if the file system extension is attached
//     // ...
//
// Parameters:
//  OnCloseNotifyDescription - NotifyDescription - description of the procedure to be called if
//                             the extension is attached. Contains the following parameters:
//                              Result               - Boolean - always True.
//                              AdditionalParameters - Undefined.
//  SuggestionText           - String - text that suggests attaching the file system extension. 
//                             If the text is not specified, the default text is displayed.
//  WarningText              - String - warning text that notifies that the action cannot be
//                             continued. 
//                             If the text is not specified, the default text is displayed.
//
// Returns:
//  Boolean - True if the extension is attached.
//   
Procedure CheckFileSystemExtensionAttached(NotifyOnCloseDescription, Val SuggestionText = "", 
	Val WarningText = "") Export
	
	Parameters = New Structure("OnCloseNotifyDescription, WarningText", 
		NotifyOnCloseDescription,  WarningText, );
	Notification = New NotifyDescription("FileSystemExtensionAttachedCompletion", ThisObject, Parameters);
	ShowFileSystemExtensionInstallationQuestion(Notification, SuggestionText);
	
EndProcedure
 
// Returns the value of the "Suggest file system extension installation" option for the user.
//
// Returns:
//   Boolean.
//
Function SuggestFileSystemExtensionInstallation() Export
	
	SystemInfo = New SystemInfo();
	ClientID = SystemInfo.ClientID;
	Return CommonUseServerCall.CommonSettingsStorageLoad(
		"ProgramSettings/SuggestFileSystemExtensionInstallation", ClientID, True);
		
EndFunction	
	
// Registers the comcntr.dll component for the current platform version.
// If the registration is successful, the procedure suggests the user to restart the client  
// session in order to registration takes effect.
// 
// Is called before a client script that uses the COM connection manager (V83.COMConnector) and
// is initiated by interactive user actions. For example:
// 
// RegisterCOMConnector();
//   // script that uses the COM connection manager (V83.COMConnector)
//   //....
//
Procedure RegisterCOMConnector(Val RestartSession = True) Export
	
#If Not WebClient Then
	
	CommandText = "regsvr32.exe /n /i:user /s comcntr.dll";
	
	ReturnCode = Undefined;
	RunApp(CommandText, BinDir(), True, ReturnCode);
	
	If ReturnCode = Undefined Or ReturnCode  > 0 Then
		
		MessageText = NStr("en = 'Cannot register the comcntr component.'") + Chars.LF
			+ NStr("en = 'regsvr32 error code:'") + " "  + ReturnCode;
			
		If ReturnCode =  5 Then
			MessageText = MessageText + " " +  NStr("en = 'Insufficient access rights.''");
		EndIf;
		
		EventLogOperationsClient.AddMessageForEventLog(
			NStr("en = 'Registering comcntr component'", CommonUseClientServer.DefaultLanguageCode()), "Error", MessageText);
		EventLogOperationsServerCall.WriteEventsToEventLog(MessagesForEventLog);
		ShowMessageBox(,MessageText + Chars.LF +  NStr("en = 'For details see the Event log.'"));
	ElsIf RestartSession Then
		Notification = New  NotifyDescription("RegisterCOMConnectorCompletion", ThisObject);
		QueryText = NStr("en = 'Application restart is required to finish re-registration of the comcntr component.
			|Do you want to restart it now?'");
		ShowQueryBox(Notification, QueryText,  QuestionDialogMode.YesNo);
	EndIf;
	
#EndIf
	
EndProcedure
 
// Returns True if a client application is connected to the infobase through a web server.
//
Function ClientConnectedViaWebServer() Export
	
	Return Find(Upper(InfobaseConnectionString()), "WS=") =  1;
	
EndFunction

// Asks whether the user wants to continue the action that can reset made changes.
// Is intended to be used in BeforeClose event notification handlers.
//  
// Parameters:
//  SaveAndCloseNotification  - NotifyDescription - name of the procedure to be called once the 
//                              OK button is clicked.
//   Cancel                   - Boolean - return parameter, flag that shows whether the action
//                              is canceled.
//   WarningText              - String - overridable user warning text.
//  
// Example: 
//  Notification = New NotifyDescription("SelectAndClose", ThisObject);
//  CommonUseClient.ShowFormClosingConfirmation(Notification, Cancel);
//  
//  &AtClient
//  Procedure SelectAndClose (Result = Undefined, AdditionalParameters = Undefined) Export
//   // saving form data
//   //....
//  Modified = False; // do not showing one more form closure notification
//  Close(<SelectionResult>);
//  EndProcedure
//
Procedure ShowFormClosingConfirmation(SaveAndCloseNotification,  Cancel, WarningText =  "") Export
	
	Form = SaveAndCloseNotification.Module;
	If Not Form.Modified Then
		Return;
	EndIf;
	
	Cancel = True;
	
	Parameters = New  Structure();
	Parameters.Insert("SaveAndCloseNotification", SaveAndCloseNotification);
	Parameters.Insert("WarningText", WarningText);
	FormClosingConfirmationParameters =  Parameters;
	
	AttachIdleHandler("ConfirmFormClosingNow",  0.1, True);
	
EndProcedure
 
// Asks whether the user wants to continue the action that closes the form.
// Is intended to be used in BeforeClose event notification handlers.
//
// Parameters:
//  Form                                      - ManagedForm - form that calls the warning
//                                              dialog.
//  Cancel                                    - Boolean - return parameter, flag that shows
//                                              whether the action is canceled.
//  WarningText                               - String - warning text shown to the user.
//  CloseFormWithoutConfirmationAttributeName - String - name of the flag attribute that shows
//                                              whether the warning must be shown.
//  CloseNotifyDescription                    - NotifyDescription - name of the procedure that
//                                              is called once the Yes button is clicked.
//
// Example: 
//  WarningText = NStr("en = 'Do you want to close the assistant?'");
//  CommonUseClient.ShowArbitraryFormClosingConfirmation(ThisObject, Cancel, WarningText, "CloseFormWithoutConfirmation")");
//
Procedure  ShowArbitraryFormClosingConfirmation(Form, Cancel,  WarningText,
	CloseFormWithoutConfirmationAttributeName,  CloseNotifyDescription = Undefined) Export
	
	If Form[CloseFormWithoutConfirmationAttributeName] Then
		Return;
	EndIf;
	
	Cancel = True;
	
	Parameters = New Structure();
	Parameters.Insert("Form", Form);
	Parameters.Insert("WarningText", WarningText);
	Parameters.Insert("CloseFormWithoutConfirmationAttributeName", CloseFormWithoutConfirmationAttributeName);
	Parameters.Insert("CloseNotifyDescription", CloseNotifyDescription);
	FormClosingConfirmationParameters =  Parameters;
	
	AttachIdleHandler("ConfirmArbitraryFormClosingNow", 0.1, True);
	
EndProcedure
 
// Gets a style color by the style item name.
//
// Parameters:
// StyleColorName - string that contains the item name.
//
// Returns:
//  Style color.
//
Function StyleColor(StyleColorName) Export
	
	Return CommonUseClientCached.StyleColor(StyleColorName);
	
EndFunction

// Gets a style font by the style item name.
//
// Parameters:
// StyleFontName - string that contains the item name.
//
// Returns:
//  Style font.
//
Function StyleFont(StyleFontName) Export
	
	Return CommonUseClientCached.StyleFont(StyleFontName);
	
EndFunction
 
///////////////////////////////////////////////////////////////////////////////
// Procedures and functions for processing and calling optional subsystems.

// Returns True if the "functional" subsystem exists.
// Is intended for calling optional subsystems (condition call).
//
// The subsystem is referred to as "functional" if its "Include in command interface" check box 
// is cleared.
//
// Parameters:
//  FullSubsystemName - String - full name of the subsystem metadata object without
//                      "Subsystem." and with character case taken into account.
//                      For example: "StandardSubsystems.ReportOptions".
//
// Example:
//
//  If CommonUse.SubsystemExists("StandardSubsystem.ReportOptions") Then 
//    ReportOptionsModuleClient = CommonUseClient.CommonModule("ReportOptionsClient"));
//  	ReportOptionsModuleClient.<Method name>();
//  EndIf;
//
// Returns:
//  Boolean.
//
Function SubsystemExists(FullSubsystemName) Export
	
	SubsystemNames =  StandardSubsystemsClientCached.ClientParametersOnStart().SubsystemNames;
	Return SubsystemNames.Get(FullSubsystemName) <> Undefined;
	
EndFunction
 
// Returns a reference to the common module by the name.
//
// Parameters:
//   Name - String - common module name, for example: CommonUse, CommonUseClient.
//
// Returns:
//  CommonModule.
//
Function CommonModule(Name) Export
	
	Module = Eval(Name);
	
#If Not WebClient Then
	If TypeOf(Module) <> Type("CommonModule") Then
		Raise  StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'The %1 common module is not found.'"), Name);
	EndIf;
#EndIf
	
	Return Module;
	
EndFunction
 
////////////////////////////////////////////////////////////////////////////////
// Functions for processing actions the user does when editing a multiline text, for example, a
// comment in a document.

// Opens the form of arbitrary multiline text editing.
//	
// Parameters:
//  ClosingNotification - NotifyDescription - contains the description of the procedure to be
//                        called once the text entering form is closed. Contains the same
//                        parameters as the ShowInputString method.
//   MultilineText      - String - arbitrary text to be edited;
//   Title              - String - text to be displayed in the form title.
//	
// Example:
//	
//   Notification = New NotifyDescription("CommentEndEntering, ThisObject);
//   CommonUseClient.FormMultilineTextEditingShow(Notification, Item.EditingText);
//	
//   &AtClient
//   Procedure CommentEndInput(Val EnteredText, Val AdditionalParameters) Export 
//    If EnteredText = Undefined Then
//     ReturnВозврат;
//   	EndIf;	
//	
//     Object.MultilineComment = EnteredTextт;
//     Modified = True;
//    EndProcedure
//
Procedure  ShowMultilineTextEditingForm(Val ClosingNotification, 
	Val MultilineText, Val Title = Undefined) Export
	
	If Title = Undefined Then
		ShowInputString(ClosingNotification, MultilineText,,, True);
	Else
		ShowInputString(ClosingNotification, MultilineText, Title,, True);
	EndIf;
	
EndProcedure
 
// Opens the multiline comment editing form.
//
// Parameters:
//  MultilineText   - String - arbitrary text to be edited.
//  OwnerForm       - ManagedFormма - form, in which field the comment is entered.
//  AttributeNameта - String - name of the form attribute where the entered comment is input. 
//  Title           - String - text to be displayed in the form title. The default value is
//                    "Comment".
//
// Usage example:
//  CommonUseClient.ShowCommentEditingForm(Item.EditingText, ThisObject, "Object.Comment");
//
Procedure ShowCommentEditingForm(Val MultilineText, Val OwnerForm, Val AttributeName, 
	Val Title = Undefined) Export
	
	AdditionalParameters = New Structure("FormOwner.AttributeName", OwnerForm, AttributeName);
	Notification = New  NotifyDescription("CommentEndEntering",  ThisObject, AdditionalParameters);
	FormTitle = ?(Title <> Undefined, Title, NStr("en='Comment'"));
	ShowMultilineTextEditingForm(Notification, MultilineText, FormTitle);
	
EndProcedure

#EndRegion

#Region InternalInterface
 
//////////////////////////////////////////////////////////////////////////////
// Getting client event handlers.

// Returns the handlers of the specified client event.
//
// Parameters:
//  Event - String - for example StandardSubsystems.BaseFunctionality\OnStart.
//
// Returns:
//  FixedArray with values of the FixedStructure type with the following properties:
//     * Version - String - handler version, for example "2.1.3.4". An empty string is
//                  returned if the version is not specified.
//     * Module  - CommonModule - common server module.
// 
 
Function EventHandlers(Event) Export
	
	Return StandardSubsystemsClientCached.ClientEventHandlers(Event, False);
	
EndFunction
 
// Returns handlers of the specified internal client event.
//
// Parameters:
//  Event - String - for example StandardSubsystems.BaseFunctionality\ActiveUserFormOnDefine.
//
// Returns:
//  FixedArray with values of the FixedStructure type with the following properties:
//     * Version - String - handler version, for example "2.1.3.4". An empty string is
//                 returned if the version is not specified.
//     * Module  - CommonModule - common server module.
// 
Function InternalEventHandlers(Event) Export
	
	Return StandardSubsystemsClientCached.ClientEventHandlers(Event, True);
	
EndFunction
 
// Updates the application interface keeping the current active window.
//
Procedure RefreshApplicationInterface() Export
	
	CurrentActiveWindow = ActiveWindow();
	RefreshInterface();
	If CurrentActiveWindow <> Undefined Then
		CurrentActiveWindow.Activate();
	EndIf;
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

Procedure ShowFileSystemExtensionInstallationQuestionCompletion(Action, ClosingNotification) Export
	
#If WebClient Then
	If Action = "NoLongerPrompt" Then
		SystemInfo = New SystemInfo();
		ClientID = SystemInfo.ClientID;
		SuggestFileSystemExtensionInstallation = False;
		CommonUseServerCall.CommonSettingsStorageSave(
			"ProgramSettings/SuggestFileSystemExtensionInstallation", ClientID,
			SuggestFileSystemExtensionInstallation);
	EndIf;
#EndIf
	
	ExecuteNotifyProcessing(ClosingNotification,  AttachFileSystemExtension());
	
EndProcedure	

Procedure FileSystemExtensionAttachedCompletion(Action, Parameters) Export
	
	MessageText = "";
	If AttachFileSystemExtension() Then
		ExecuteNotifyProcessing(Parameters.OnCloseNotifyDescription);
		Return;
	EndIf;
	
	If IsBlankString(Parameters.WarningText) Then
		MessageText = NStr("en = 'The action cannot be performed because the 1C:Enterprise web client extension is not installed.'")
	Else
		MessageText = Parameters.WarningText;
	EndIf;
	ShowMessageBox(, MessageText);
	
EndProcedure

Procedure CommentEndEntering(Val EnteredText, Val AdditionalParameters) Export
	
	If EnteredText = Undefined Then
		Return;
	EndIf;	
	
	FormAttribute = AdditionalParameters.OwnerForm;
	
	PathToFormAttribute = StringFunctionsClientServer.SplitStringIntoSubstringArray(AdditionalParameters.AttributeName, ".");
	// If the type of the attribute is "Object.Comment" and so on
	If PathToFormAttribute.Count() > 1 Then
		For Index = 0 to PathToFormAttribute.Count() - 2 Do 
			FormAttribute = FormAttribute[PathToFormAttribute[Index]];
		EndDo;
	EndIf;	
	
	FormAttribute[PathToFormAttribute[PathToFormAttribute.Count() - 1]] = EnteredText;
	AdditionalParameters.OwnerForm.Modified = True;
	
EndProcedure

Procedure RegisterCOMConnectorCompletion(Answer, Parameters) Export
	
	If Answer = DialogReturnCode.Yes Then
		SkipExitConfirmation = True;
		Exit(True, True);
	EndIf;

EndProcedure

Procedure ConfirmFormClosing() Export
	
	Parameters = FormClosingConfirmationParameters;
	If Parameters = Undefined Then
		Return;
	EndIf;
	FormClosingConfirmationParameters = Undefined;
	
	Notification = New NotifyDescription("ConfirmFormClosingCompletion", ThisObject, Parameters);
	If IsBlankString(Parameters.WarningText) Then
		QueryText = NStr("en = 'Data was changed. Do you want to save the changes?'");
	Else
		QueryText = Parameters.WarningText;
	EndIf;
	
	ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNoCancel,  ,
		DialogReturnCode.No);
	
EndProcedure

Procedure ConfirmFormClosingCompletion(Answer, Parameters) Export
	
	If Answer = DialogReturnCode.Yes Then
		ExecuteNotifyProcessing(Parameters.SaveAndCloseNotification);
	ElsIf Answer = DialogReturnCode.No Then
		Form = Parameters.SaveAndCloseNotification.Module;
		Form.Modified = False;
		Form.Close();
	Else
		Form = Parameters.SaveAndCloseNotification.Module;
		Form.Modified = True;
	EndIf;
	
EndProcedure

Procedure ConfirmArbitraryFormClosing() Export
	
	Parameters =  FormClosingConfirmationParameters;
	If Parameters = Undefined Then
		Return;
	EndIf;
	FormClosingConfirmationParameters = Undefined;
	QuestionMode = QuestionDialogMode.YesNo;
	
	Notification = New NotifyDescription("ConfirmArbitraryFormClosingCompletion", ThisObject, Parameters);
	
	ShowQueryBox(Notification, Parameters.WarningText, QuestionMode);
	
EndProcedure

Procedure  ConfirmArbitraryFormClosingCompletion(Answer, Parameters) Export
	
	Form = Parameters.Form;
	If Answer =  DialogReturnCode.Yes
		Or Answer = DialogReturnCode.OK Then
		Form[Parameters.CloseFormWithoutConfirmationAttributeName] = True;
		If Parameters.CloseNotifyDescription <> Undefined Then
			ExecuteNotifyProcessing(Parameters.CloseNotifyDescription);
		EndIf;
		Form.Close();
	Else
		Form[Parameters.CloseFormWithoutConfirmationAttributeName] = False;
	EndIf;
	
EndProcedure

#EndRegion