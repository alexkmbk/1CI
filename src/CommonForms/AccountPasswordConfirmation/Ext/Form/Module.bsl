//------------------------------------------------------------------------------
// PARAMETERS PASSED TO THE FORM
//
// Account*  - CatalogRef.EmailAccounts
//
// RETURNS
//
// Undefined - if the user refused to enter the password.
// Structure - 
//           State key, boolean - true or false depending on the call success.
//           Password key, string - if the True state contains a password.
//           ErrorMessage key - if the True state contains an error message.
//
//------------------------------------------------------------------------------
// HOW THE FORM WORKS
//
//   If the passed account list contains more than one item, the email account to
// be a sender is chosen from the list on the form.
//
//------------------------------------------------------------------------------

#Region FormEventHandlers
 
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skipping the initialization to guarantee that the form will be received if the SelfTest parameter is passed.
	If Parameters.Property("SelfTest") Then
		Return;
	EndIf;
		
	Parameters.Property("CheckCanSendReceiveEmailMessage", CheckCanSendReceiveEmailMessage);
 
	If Parameters.Account.IsEmpty() Then
		Cancel = True;
		Return;
	EndIf;
	
	Account = Parameters.Account;
	Result = LoadPassword();
	
	If ValueIsFilled(Result) Then
		Password = Result;
		PasswordConfirmation = Result;
		SavePassword = True;
	Else
		Password = "";
		PasswordConfirmation = "";
		SavePassword = False;
	EndIf;
	
	If Not AccessRight("SaveUserData", Metadata) Then
		Items.SavePassword.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers
&AtClient
Procedure SavePasswordAndContinueExecute()
	
	If Password <> PasswordConfirmation Then
		CommonUseClientServer.MessageToUser(
			NStr("en = 'The password and password confirmation do not match'"), , "Password");
		Return;
	EndIf;
	
	If SavePassword Then
		SavePassword(Password);
	Else
		SavePassword(Undefined);
	EndIf;
	
	
	If CheckCanSendReceiveEmailMessage Then
		NotifyDescription = New NotifyDescription("SavePasswordAndContinueExecuteEnd", ThisObject, Password);		
		EmailOperationsClient.CheckCanSendReceiveEmail(NotifyDescription, Account, Password);
		Return;
	EndIf;
	
	SavePasswordAndContinueExecuteEnd(Password);
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions


&AtServer
Procedure SavePassword(Value)
	
	CommonUse.CommonSettingsStorageSave(
		"AccountPasswordConfirmationForm",
		Account,
		Value);
	
EndProcedure

&AtServer
Function LoadPassword()
	
	Return CommonUse.CommonSettingsStorageLoad("AccountPasswordConfirmationForm", Account);
	
EndFunction

&AtClient
Procedure SavePasswordAndContinueExecuteEnd(Password) Export
	
	NotifyChoice(Password);
	
EndProcedure

#EndRegion
