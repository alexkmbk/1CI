////////////////////////////////////////////////////////////////////////////////
// Email operations subsystem.
//
////////////////////////////////////////////////////////////////////////////////

#Region Interface

// Function for sending messages. Checks validity of the account filling and 
// calls the function that implements email sending.
//
// see the SendMessage function parameters 
//
// Note: the EmailParameters.Attachments parameter can contain binary data instead 
// of addresses in temporary storage where this data is stored.

//
Function SendEmailMessage(Val Account,
	                        Val EmailParameters,
	                        Val Connection = Undefined) Export
	
	If TypeOf(Account) <> Type("CatalogRef.EmailAccounts")
		Or Not ValueIsFilled(Account) Тогда
		Raise NStr("en = 'Account is not filled or filled incorrectly.'");
	EndIf;
 
	If EmailParameters = Undefined Then
		Raise NStr("en = 'Sending parameters are not set.'");
	EndIf;
 
	RecipientType = ?(EmailParameters.Property("Recipient"), TypeOf(EmailParameters.Recipient), Undefined);
	CcType = ?(EmailParameters.Property("Cc"), TypeOf(EmailParameters.Cc), Undefined);
	BccType = ?(EmailParameters.Property("Bcc"), TypeOf(EmailParameters.Bcc), Undefined);
	
	If RecipientType = Undefined And CcType = Undefined And BccType = Undefined Then
		Raise NStr("en = 'No recipient is specified.'");
	EndIf;
 
	If RecipientType = Type("String") Then
		EmailParameters.Recipient = CommonUseClientServer.SplitStringWithEmailAddresses(EmailParameters.Recipient);
	ElsIf RecipientType <> Type("Array") Then
		EmailParameters.Insert("Recipient", New Array);
	EndIf;
 
	If CcType = Type("String") Then
		EmailParameters.Cc = CommonUseClientServer.SplitStringWithEmailAddresses(EmailParameters.Cc);
	ElsIf CcType <> Type("Array") Then
		EmailParameters.Insert("Cc", New Array);
	EndIf;
 
	If BccType = Type("String") Then
		EmailParameters.Bcc = CommonUseClientServer.SplitStringWithEmailAddresses(EmailParameters.Bcc);
	ElsIf BccType <> Type("Array") Then
		EmailParameters.Insert("Bcc", New Array);
	EndIf;
 
	If EmailParameters.Property("ReplyTo") And TypeOf(EmailParameters.ReplyTo) = Type("String") Then
		EmailParameters.ReplyTo = CommonUseClientServer.SplitStringWithEmailAddresses(EmailParameters.ReplyTo);
	EndIf;

	If EmailParameters.Property("Attachments") Then
		If TypeOf(EmailParameters.Attachments) = Type("Map") Then
			For Each Attachment In EmailParameters.Attachments Do
				DataAttachments = Attachment.Value;
				If EmailOperationsInternal.ConvertAttachmentForEmailing(DataAttachments) Then
					EmailParameters.Attachments.Insert(Attachment.Key, DataAttachments);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
 
	Return EmailOperationsInternal.SendMessage(Account, EmailParameters, Connection);
	
EndFunction
 
// Function for downloading messages. Checks correctness of the filled account and 
// call the function that implements the mechanics of downloading messages.
// 
// see parameters to the function in the DownloadMessages function.
//
Function DownloadEmailMessages(Val Account,
                                   Val DownloadParameters = Undefined) Export
 
	UseForReceiving = CommonUse.ObjectAttributeValue(Account, "UseForReceiving");
	If Not UseForReceiving Then
		Raise NStr("en = 'The account is not intended for getting messages.'");
	EndIf;
	
	If DownloadParameters = Undefined Then
		DownloadParameters = New Structure;
	EndIf;
	
	Result = EmailOperationsInternal.DownloadMessages(Account, DownloadParameters);
	
	Return Result;
	
EndFunction
 
// Get available email accounts 
// Parameters:
// ForSending - Boolean - If True, only records that allow sending emails
//                        are selected
// ForReceiving - Boolean - If True, only records that allow receiving emails 
//                          are selected
// IncludingSystemEmailAccount - Boolean - enable the system account, if available
//
// Returns:
// AvailableEmailAccounts - ValueTable - With columns:
//    Ref     - CatalogRef.EmailAccounts - Ref to account
//    Name    - String - Account name
//    Address - String - Email address
//
Function AvailableEmailAccounts(Val ForSending = Undefined,
										Val ForReceiving = Undefined,
										Val IncludingSystemEmailAccount = True) Export
	
	If Not AccessRight("Read", Metadata.Catalogs.EmailAccounts) Then
		Return New ValueTable;
	EndIf;
 
	QueryText = 
	"SELECT ALLOWED
	|	EmailAccounts.Ref AS Ref,
	|	EmailAccounts.Description AS Description,
	|	EmailAccounts.EmailAddress AS Address
	|FROM
	|	Catalog.EmailAccounts AS EmailAccounts
	|WHERE
	|	EmailAccounts.DeletionMark = FALSE
	|	AND CASE
	|			WHEN &ForSending = UNDEFINED
	|				THEN TRUE
	|			ELSE EmailAccounts.UseForSending = &ForSending
	|		END
	|	AND CASE
	|			WHEN &ForReceiving = UNDEFINED
	|				THEN TRUE
	|			ELSE EmailAccounts.UseForReceiving = &ForReceiving
	|		END
	|	AND CASE
	|			WHEN &IncludingSystemEmailAccount
	|				THEN TRUE
	|			ELSE EmailAccounts.Ref <> VALUE(Catalog.EmailAccounts.SystemEmailAccount)
	|		END";
 
	Query = New Query;
	Query.Text = QueryText;
	Query.Parameters.Insert("ForSending", ForSending);
	Query.Parameters.Insert("ForReceiving", ForReceiving);
	Query.Parameters.Insert("IncludingSystemEmailAccount", IncludingSystemEmailAccount);
	
	Return Query.Execute().Unload();
	
EndFunction
 
// Gets the reference to the account by the account purpose time.
//
// Returns:
//  CatalogRef.EmailAccounts - reference to an account.
//
Function SystemAccount() Export
	
	Return Catalogs.EmailAccounts.SystemEmailAccount;
	
EndFunction

// Checks that the system account is available (can be used).
//
Function CheckSystemAccountAvailable() Export
	
	Return EmailOperationsInternal.CheckSystemAccountAvailable();
	
EndFunction
 
// Returns True, if there is at least one configured email account for sending email.
Function CanSendEmails() Export
	Return AvailableEmailAccounts(True).Count() > 0 
		Or AccessRight("Update", Metadata.Catalogs.EmailAccounts);
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Obsolete procedures and functions

// Obsolete. You should use SendEmailMessage
//
// Sends the email message.
//
// Parameters:
//  Account         - CatalogRef.EmailAccounts - email account reference.
//  EmailParameters - Structure - Contains all required message details:
//    Recipient*    - Array of structures, string - message recipient's address.
//                    Address - string - email address.
//                    Presentation - string - recipient's name.
//    Subject*      - string - message subject.
//    Body*         - string - message body (ANSI text).
//    Attachments   - map
//                    key - AttachmentDescription - string - attachment description.
//                    value - BinaryData - attachment data.
//
//  Additional structure keys that can be used:
//    ReplyTo       - map - see Recipient for details.
//    Password      - string - account password.
//    TextType      - String / Enum.EmailTextTypes - determines the
//                    transferred text type. It can take the following values:
//                    HTML - EmailTextTypes.HTML - HTML formatted text.
//                    PlainText - EmailTextTypes.PlainText - plain text. It is
//                    displayed "as is" (the default value).
//                    RichText - EmailTextTypes.RichText - rich text.
//
//    Note: Parameters marked with * are mandatory, i.e., these functions are treated 
//          as filled by the time when work begins.
//
// Returns:
// String - ID of the sent email message on the SMTP server.
//
// NOTE: the function can raise an exception, which must be processed.
//
Function SendMessage(Val Account, Val EmailParameters) Export
	
	Return SendEmailMessage(Account, EmailParameters);
	
EndFunction

// Obsolete. You should use AvailableAccounts.
Function GetAvailableAccounts(Val ForSending = Undefined,
										Val ForReceiving = Undefined,
										Val ActivateSystemAccount = True) Export
	
	Return AvailableEmailAccounts(ForSending, ForReceiving, ActivateSystemAccount);
	
EndFunction

// Obsolete. You should use SystemAccount.
Function GetSystemAccount() Export
	
	Return SystemAccount();
	
EndFunction

#EndRegion
