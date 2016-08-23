////////////////////////////////////////////////////////////////////////////////
// Email operations subsystem
//
////////////////////////////////////////////////////////////////////////////////

#Region InternalProceduresAndFunctions

// Returns the flag showing whether an account contains a password.
//
// See the description of the EmailOperationsInternal.PasswordSpecified function.
//
Function PasswordSpecified(Account) Export
	
	Return EmailOperationsInternal.PasswordSpecified(Account);
	
EndFunction

// Validates an email account.
//
// See the description of the EmailOperationsInternal.CheckCanSendReceiveEmail procedure.
//
Procedure CheckCanSendReceiveEmail(Account, PasswordParameter, ErrorMessage, AdditionalMessage) Export
	
	EmailOperationsInternal.CheckCanSendReceiveEmail(Account, PasswordParameter, ErrorMessage, AdditionalMessage);
	
EndProcedure

// Returns True if the current user has at least one account available for sending.
Function HasAvailableAccountsForSending() Export
	Return EmailOperations.AvailableEmailAccounts(True).Count() > 0;
EndFunction

// Checks whether a user can add new accounts.
Function RightToAddAccountsAvailable() Export 
	Return AccessRight("Insert", Metadata.Catalogs.EmailAccounts);
EndFunction

#EndRegion
