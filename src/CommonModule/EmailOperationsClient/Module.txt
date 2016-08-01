////////////////////////////////////////////////////////////////////////////////
// Email operations subsystem.
//
////////////////////////////////////////////////////////////////////////////////

#Region Interface

// Opens a message creation form.
//  
// Parameters:
//  SendingParameters - Structure - parameters for filling the sending form for that message (all optional):
//    * From - CatalogRef.EmailAccounts - account used to send the email message.
//                  - ValueList - list of accounts available for selection in the form:
//                      ** Presentation - String - account description.
//                      ** Value - CatalogRef.EmailAccounts - account.
//    
//    * Recipient - list of email addresses.
//        - String - list of addresses in the following format:
//            [RecipientPresentation1] <Address1>; [[RecipientPresentation2] <Адрес2>; ...]
//        - ValueList - list of addresses:
//            ** Presentation - String - recipient presentation.
//            ** Value - String - email address.
//    
//    * Subject - String - message subject.
//    
//    * Text - String - message body.
//    
//    * Attachments - Array - attached files (described as structures):
//        ** Structure - attachment description:
//             *** Presentation - String - attachment file name.
//             *** AddressInTempStorage - String - address of the attached binary data in a temporary storage.
//             *** Encoding - String - attachment encoding (used if it is different from the message encoding).
//    
//    * DeleteFilesAfterSending - Boolean - delete temporary files after sending the message.
//  
//  FormClosingNotification - NotifyDescription - procedure to be executed after closing
//                                                the message sending form.
//
Procedure CreateNewEmailMessage(SendingParameters = Undefined, FormClosingNotification = Undefined) Export
	
	If SendingParameters = Undefined Then
		SendingParameters = New Structure;
	EndIf;
	SendingParameters.Insert("FormClosingNotification", FormClosingNotification);
	
	NotifyDescription = New NotifyDescription("CreateNewEmailMessageAccountChecked", ThisObject, SendingParameters);
	CheckAccountForSendingEmailExists(NotifyDescription);
	
EndProcedure
 
// If a user has no account for sending email, starts the account setup wizard or displays a notification 
// that email cannot be sent, depending on the user rights.
// The procedure is intended for scenarios that require account setup before requesting 
// additional sending parameters.

//
// Parameters:
//   ResultHandler - NotifyDescription - procedure to be executed after the check is completed.
//
Procedure CheckAccountForSendingEmailExists(ResultHandler) Export
	If EmailOperationsServerCall.HasAvailableAccountsForSending() Then
		ExecuteNotifyProcessing(ResultHandler, True);
	Else
		If EmailOperationsServerCall.RightToAddAccountsAvailable() Then
			OpenForm("Catalog.EmailAccounts.Form.AccountSetupWizard", 
				New Structure("ContextMode", True), , , , , ResultHandler);
		Else	
			MessageText = NStr("en = 'To send the message, first set up an email account.'");
			ShowMessageBox(ResultHandler, MessageText);
		EndIf;
	EndIf;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// OBSOLETE PROCEDURES AND FUNCTIONS

// Obsolete. Use CreateNewEmailMessage instead.
//
// Client interface function used for simplified call of a new email message edit form.
// Parameters:
//   From*       - ValueList, CatalogRef.EmailAccounts - account used to send the email message.
//                   If the type is a value list,
//                   then presentation is the account name, and value is reference to the account.
//
//   Recipient   - ValueList, String:
//                   if the type a value list, then the presentation is recipient's name
//                                                      and value is the email address.
//                   If the type is a string, it contains a list of valid email addresses.*
//
//   Subject     - String - message subject.
//   Text        - String - message body.
//
//   Attachments - ValueList:
//                   presentation - String - attachment name.
//                   value        - BinaryData - attachment's binary data.
//                                - String - address of the file in a temporary storage
//                                - String - path to the file on client.
//
//   DeleteFilesAfterSending - Boolean - delete temporary files after sending the message.
//   SaveEmailMessage        - Boolean - flag specifying whether the message must be saved 
//                                       (used only if Interactions subsystem is embedded).
//
Procedure OpenEmailMessageSendForm(Val From = Undefined, Val Recipient = Undefined, Val Subject = "",
	Val Text = "", Val Attachments = Undefined, Val DeleteFilesAfterSending = False, Val SaveEmailMessage = True) Export
 
	SendingParameters = New Structure;
	SendingParameters.Insert("From", From);
	SendingParameters.Insert("Recipient", Recipient);
	SendingParameters.Insert("Subject", Subject);
	SendingParameters.Insert("Text", Text);
	SendingParameters.Insert("Attachments", Attachments);
	SendingParameters.Insert("DeleteFilesAfterSending", DeleteFilesAfterSending);
	SendingParameters.Insert("SaveEmailMessage", SaveEmailMessage);
	
	CreateNewEmailMessage(SendingParameters);
	
EndProcedure

#EndRegion
 
#Region InternalProceduresAndFunctions

// Continues the CreateNewEmailMessage procedure.
Procedure CreateNewEmailMessageAccountChecked(AccountConfigured, SendingParameters) Export
	Var From, Recipient, Attachments, Subject, Text, DeleteFilesAfterSending;
	
	If AccountConfigured <> True Then
		Возврат;
	КонецЕсли;
	
	SendingParameters.Property("From", From);
	SendingParameters.Property("Recipient", Recipient);
	SendingParameters.Property("Subject", Subject);
	SendingParameters.Property("Text", Text);
	SendingParameters.Property("Attachments", Attachments);
	SendingParameters.Property("DeleteFilesAfterSending", DeleteFilesAfterSending);
	
	FormClosingNotification = SendingParameters.FormClosingNotification;
 
	If CommonUseClient.SubsystemExists("StandardSubsystems.Interactions") 
		AND StandardSubsystemsClientCached.ClientParameters().UseEmailClient Then
			ClientInteractionsModule = CommonUseClient.CommonModule("InteractionsClient");
			ClientInteractionsModule.OpenEmailMessageSendForm(From,
				Recipient, Subject, Text, Attachments, FormClosingNotification);
	Else
		OpenSimpleSendEmailMessageForm(From, Recipient,
			Subject,Text, Attachments, DeleteFilesAfterSending, FormClosingNotification);
	EndIf;
	
EndProcedure

// The interface client function that supports simplified call of the new message
// edit form. Messages are not saved in the infobase when sending them
// through the simple message form.
//
// See the CreateNewEmailMessage function for details.
//
Procedure OpenSimpleSendEmailMessageForm(From,
			Recipient, Subject, Text, FileList, DeleteFilesAfterSending, CloseNotificationDetails)
	
	EmailParameters = New Structure;
	
	EmailParameters.Insert("Account", From);
	EmailParameters.Insert("Recipient", Recipient);
	EmailParameters.Insert("Subject", Subject);
	EmailParameters.Insert("Body", Text);
	EmailParameters.Insert("Attachments", FileList);
	EmailParameters.Insert("DeleteFilesAfterSending", DeleteFilesAfterSending);
	
	OpenForm("CommonForm.SendMessage", EmailParameters, , , , , CloseNotificationDetails);
EndProcedure

// Performs account check.
//
// Parameters:
//   Account - CatalogRef.EmailAccounts - account to be checked.
//
Procedure CheckAccount(Val Account) Export
	
	ClearMessages();
	
	Status(NStr("en = Checking account'"),,NStr("en = Checking the account. Please wait...'"));
	
	If EmailOperationsServerCall.PasswordSpecified(Account) Then
		CheckCanSendReceiveEmail(Undefined, Account, Undefined);
	Else
		FormParameters = New Structure;
		FormParameters.Insert("Account", Account);
		FormParameters.Insert("CheckCanSendReceiveEmailMessage", True);
		OpenForm("CommonForm.AccountPasswordConfirmation", FormParameters);
	EndIf;
	
EndProcedure

// Validates an email account.
//
// See the description of the EmailOperationsInternal.CheckCanSendReceiveEmailMessage procedure.
//
Procedure CheckCanSendReceiveEmail(ResultHandler, Account, PasswordParameter) Export
	
	ErrorMessage = "";
	AdditionalMessage = "";
	EmailOperationsServerCall.CheckCanSendReceiveEmail(Account, PasswordParameter, ErrorMessage, AdditionalMessage);
	
	If ValueIsFilled(ErrorMessage) Then
		ShowMessageBox(ResultHandler, StringFunctionsClientServer.SubstituteParametersInString(
						NStr("en = 'Account validation errors:
								   |%1'"), ErrorMessage ),,
						NStr("en = 'Account verification'"));
	Else
		ShowMessageBox(,StringFunctionsClientServer.SubstituteParametersInString(
						NStr("en = 'Account validation completed. %1'"),
						AdditionalMessage ),,
						NStr("en = 'Account verification'"));
	EndIf;
	
EndProcedure
 
#EndRegion