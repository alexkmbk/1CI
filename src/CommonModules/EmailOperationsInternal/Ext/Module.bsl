////////////////////////////////////////////////////////////////
// Email operations subsystem
//
////////////////////////////////////////////////////////////////////////////////

#Region InternalProceduresAndFunctions

// See the description of this procedure in the StandardSubsystemsServer module.
Procedure InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers) Export
	
	// SERVER HANDLERS.
	
	ServerHandlers["StandardSubsystems.InfobaseVersionUpdate\OnAddUpdateHandlers"].Add(
		"EmailOperationsInternal");
		
	If CommonUse.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ServerHandlers["StandardSubsystems.AccessManagement\OnFillMetadataObjectAccessRestrictionKinds"].Add(
			"EmailOperationsInternal");
	
		ServerHandlers["StandardSubsystems.AccessManagement\OnFillAccessKinds"].Add(
			"EmailOperationsInternal");
	EndIf;
	
	ServerHandlers["StandardSubsystems.BaseFunctionality\OnReceiveDataFromSlave"].Add(
		"EmailOperationsInternal");
	
	ServerHandlers["StandardSubsystems.BaseFunctionality\OnReceiveDataFromMaster"].Add(
		"EmailOperationsInternal");
	
	ServerHandlers["StandardSubsystems.BaseFunctionality\OnFillPermissionsToAccessExternalResources"].Add(
		"EmailOperationsInternal");
	
EndProcedure

// Fills a list of requests for external permissions that must be granted when an
// infobase is created or updated.
//
// Parameters:
//  PermissionRequests - Array - list
//                      of values returned by SafeMode.RequestToUseExternalResources() method.
//
Procedure OnFillPermissionsToAccessExternalResources(PermissionRequests) Export

	If CommonUseCached.DataSeparationEnabled() And Not CommonUse.UseSessionSeparator() Then
		Return;
	EndIf;
	
	AccountPermissions = Catalogs.EmailAccounts.AccountPermissions();
	For Each PermissionDetails In AccountPermissions Do
		PermissionRequests.Add(
			SafeMode.RequestToUseExternalResources(PermissionDetails.Value, PermissionDetails.Key));
	EndDo;

EndProcedure

// Converts internal attachment formats to binary data format.
//
Function ConvertAttachmentForEmailing(Attachment) Export
	If TypeOf(Attachment) = Type("String") And IsTempStorageURL(Attachment) Then
		Attachment = GetFromTempStorage(Attachment);
		ConvertAttachmentForEmailing(Attachment);
		Return True;
	ElsIf TypeOf(Attachment) = Type("Picture") Then
		Attachment = Attachment.GetBinaryData();
		Return True;
	ElsIf TypeOf(Attachment) = Type("File") And Attachment.Exist() And Attachment.IsFile() Then
		Attachment = New BinaryData(Attachment.FullName);
		Return True;
	EndIf;
	Return False;
EndFunction

// Checks whether the predefined system account is available for use.
//
Function CheckSystemAccountAvailable() Export
	
	If Not AccessRight("Read", Metadata.Catalogs.EmailAccounts) Then
		Return False;
	EndIf;
	
	QueryText =
		"SELECT ALLOWED
		|	EmailAccounts.Ref AS Ref
		|FROM
		|	Catalog.EmailAccounts AS EmailAccounts
		|WHERE
		|	EmailAccounts.Ref = &Ref";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.Parameters.Insert("Ref", EmailOperations.SystemAccount());
	If Query.Execute().IsEmpty() Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Sending function: direct implementation of email message sending mechanism
//
// Implements the functionality of sending email messages.
//
// Parameters:
//  Account           - CatalogRef.EmailAccounts - reference to an email account.
//  MessageParameters - Structure - contains all required message data.
//                      Contains the following keys:
//        Recipient*  - Array of structures, String - email address of the recipient.
//                      Address      - String – email address.
//                      Presentation - String - recipient's name.
//        Cc          - Array of structures, String - email addresses of additional message recipients. 
//                      Used to generate the CC field of email messages. 
//                      If this is a structure array, each structure has the following format:
//                      Address      - String - email address (mandatory).
//                      Presentation - String - recipient's name.
//        Bcc         - Array of structures, String - email addresses of hidden copy recipients. 
//                      Used to generate the Bcc field of email messages. 
//                      If this is a structure array, each structure has the following format:
//                      Address      - String - email address (mandatory).
//                      Presentation - String - recipient's name.
//
//        Subject*    - String – message subject.
//        Body*       - message body (plain text, win1251 encoded).
//        Importance  - InternetMailMessageImportance.
//        Attachments - Map:
//                      key   - AttachmentDescription - String – attachment name.
//                      value - BinaryData, Structure - either attachment binary data
//                               or a structure with the following properties:
//                               BinaryData – BinaryData - attachment binary data.
//                               ID         - String - attachment ID, used to store images 
//                                                     displayed in the message body.
//
// Optional additional structure keys:
//    ReplyTo  - Map - has the same fields as the Recipient parameter.
//    Password - String – account password.
//    BasisIDs - String - IDs of message basis objects.
//    ProcessTexts           - Boolean – shows whether message text processing is required when sending.
//    RequestDeliveryReceipt - Boolean – shows whether a delivery notification is required.
//    RequestReadReceipt     - Boolean – shows whether a read notification is required. 
//    TextType   - String / Enum.EmailMessageTextTypes/EmailMessageTextType - specifies
//                 the type of the passed text values:
//                 HTML/EmailTextTypes.HTML - message text in HTML format.
//                 PlainText/EmailMessageTextTypes.PlainText – message text in plain text format.
//                 Displayed "as is" (default value).
//                 RichText/EmailMessageTextKinds.RichText - message text in rich text format.
//
//    Note: The message parameters marked with asterisk (*) are mandatory.
//          At the moment of function call they must be filled.
// Connection - InternetMail - an existing connection to a mail server. 
//                             If it is not specified, the connection is established in the function body.
//
// Returns:
//   String - message ID at the SMTP server.
//
// Note: the function can raise an exception, which must be processed.
//
Function SendMessage(Val Account,
	                       Val EmailParameters,
	                       Connection = Undefined) Export
	
	// Declaring variables before the first use of MessageParameters structure properties.
	// The variables store the values passed in the function parameters.
	Var Recipient, Subject, Body, Attachments, ReplyTo, TextType, Cc, Bcc, Password;
	
	If Not EmailParameters.Property("Subject", Subject) Then
		Subject = "";
	EndIf;
	
	If Not EmailParameters.Property("Body", Body) Then
		Body = "";
	EndIf;
	
	Recipient = EmailParameters.Recipient;
	
	If TypeOf(Recipient) = Type("String") Then
		Recipient = CommonUseClientServer.SplitStringWithEmailAddresses(Recipient);
	EndIf;
	
	EmailParameters.Property("Attachments", Attachments);
	
	CurEmail = New InternetMailMessage;
	CurEmail.Subject = Subject;
	
	// Generating recipient address
	For Each RecipientEmailAddress In Recipient Do
		Recipient = CurEmail.To.Add(RecipientEmailAddress.Address);
		Recipient.DisplayName = RecipientEmailAddress.Presentation;
	EndDo;
	
	If EmailParameters.Property("Cc", Cc) Then
		// Generating recipient addresses for the Cc field
		For Each CcRecipientEmailAddress In Cc Do
			Recipient = CurEmail.Cc.Add(CcRecipientEmailAddress.Address);
			Recipient.DisplayName = CcRecipientEmailAddress.Presentation;
		EndDo;
	EndIf;
	
	If EmailParameters.Property("Bcc", Bcc) Then
		// Generating recipient addresses for the Bcc field
		For Each BccRecipientEmailAddress In Bcc Do
			Recipient = CurEmail.Bcc.Add(BccRecipientEmailAddress.Address);
			Recipient.DisplayName = BccRecipientEmailAddress.Presentation;
		EndDo;
	EndIf;
	
	// Generating reply address, if required
	If EmailParameters.Property("ReplyTo", ReplyTo) Then
		For Each ReplyToEmailAddress In ReplyTo Do
			ReplyToEmail = CurEmail.ReplyTo.Add(ReplyToEmailAddress.Address);
			ReplyToEmail.DisplayName = ReplyToEmailAddress.Presentation;
		EndDo;
	EndIf;
	
	// Getting sender details
	SenderAttributes = CommonUse.ObjectAttributeValues(Account, "UserName,EmailAddress");
	
	// Adding the sender name to the message
	CurEmail.SenderName       = SenderAttributes.UserName;
	CurEmail.From.DisplayName = SenderAttributes.UserName;
	CurEmail.From.Address     = SenderAttributes.EmailAddress;
	
	// Adding attachments to the message
	If Attachments <> Undefined Then
		For Each Attachment In Attachments Do
			If TypeOf(Attachment) = Type("Structure") Then
				NewAttachment = CurEmail.Attachments.Add(GetFromTempStorage(Attachment.AddressInTempStorage), Attachment.Presentation);
				If Not IsBlankString(Attachment.Encoding) Then
					NewAttachment.Encoding = Attachment.Encoding;
				EndIf;
			Else // For backward compatibility with version 2.2.1
				If TypeOf(Attachment.Value) = Type("Structure") Then
					NewAttachment = CurEmail.Attachments.Add(Attachment.Value.BinaryData, Attachment.Key);
					NewAttachment.ID = Attachment.Value.ID;
					If Attachment.Value.Property("Encoding") Then
						NewAttachment.Encoding = Attachment.Value.Encoding;
					EndIf;
				Else
					CurEmail.Attachments.Add(Attachment.Value, Attachment.Key);
				EndIf;
			EndIf;
		EndDo;
	EndIf;

	// Setting the BasisIDs string
	If EmailParameters.Property("BasisIDs") Then
		CurEmail.SetField("References", EmailParameters.BasisIDs);
	EndIf;
	
	// Adding text
	Text = CurEmail.Texts.Add(Body);
	If EmailParameters.Property("TextType", TextType) Then
		If TypeOf(TextType) = Type("String") Then
			If      TextType = "HTML" Then
				Text.TextType = InternetMailTextType.HTML;
			ElsIf TextType = "RichText" Then
				Text.TextType = InternetMailTextType.RichText;
			Else
				Text.TextType = InternetMailTextType.PlainText;
			EndIf;
		ElsIf TypeOf(TextType) = Type("EnumRef.EmailTextTypes") Then
			If      TextType = Enums.EmailTextTypes.HTML
				  Or TextType = Enums.EmailTextTypes.HTMLWithPictures Then
				Text.TextType = InternetMailTextType.HTML;
			ElsIf TextType = Enums.EmailTextTypes.RichText Then
				Text.TextType = InternetMailTextType.RichText;
			Else
				Text.TextType = InternetMailTextType.PlainText;
			EndIf;
		Else
			Text.TextType = TextType;
		EndIf;
	Else
		Text.TextType = InternetMailTextType.PlainText;
	EndIf;

	// Setting importance
	Importance = Undefined;
	If EmailParameters.Property("Importance", Importance) Then
		CurEmail.Importance = Importance;
	EndIf;
	
	// Setting encoding
	Encoding = Undefined;
	If EmailParameters.Property("Encoding", Encoding) Then
		CurEmail.Encoding = Encoding;
	EndIf;

	If EmailParameters.Property("ProcessTexts") And Not EmailParameters.ProcessTexts Then
		ProcessMessageText =  InternetMailTextProcessing.DontProcess;
	Else
		ProcessMessageText =  InternetMailTextProcessing.Process;
	EndIf;
	
	If EmailParameters.Property("RequestDeliveryReceipt") Then
		CurEmail.RequestDeliveryReceipt = EmailParameters.RequestDeliveryReceipt;
		CurEmail.DeliveryReceiptAddresses.Add(SenderAttributes.EmailAddress);
	EndIf;
	
	If EmailParameters.Property("RequestReadReceipt") Then
		CurEmail.RequestReadReceipt = EmailParameters.RequestReadReceipt;
		CurEmail.ReadReceiptAddresses.Add(SenderAttributes.EmailAddress);
	EndIf;
	
	If TypeOf(Connection) <> Type("InternetMail") Then
		EmailParameters.Property("Password", Password);
		Profile = InternetMailProfile(Account);
		Connection = New InternetMail;
		Connection.Logon(Profile);
	EndIf;

	Connection.Send(CurEmail, ProcessMessageText);
	
	Return CurEmail.MessageID;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Mail receiving function - direct implementation of receiving an email message.
//
// Implements the functionality of downloading incoming messages for the specified account 
// from the mail server.

//
// Parameters:
//  Account - CatalogRef.EmailAccounts - reference to an email account.
//
//  ImportParameters - Structure with the following fields:
//    Column (key)     - Array - array of string column names. 
//                               The column names must match the fields of the InternetMailMessage object. 
//    TestMode (key)   - Boolean - if True, the call is made in the account testing mode:
//                               messages are selected but not included in the return values.
//                               The test mode is disabled by default.
//    GetHeaders (key) - Boolean - if True, the returned set only includes message headers.
//    HeadersIDs       - Array - headers or message IDs used to get the full messages.
//    CastMessagesToType - Boolean - return a set of received email messages as a value table 
//                               with simple types. The default value is True.
//
//    Password (key)   - String - password for POP3 access.
//
// Returns:
//   MessageSet* - table of values containing an adapted version of the server message list.
//                 Default value table columns:
//                   Importance, Attachments**, PostingDate, DateReceived, Header, SenderName, UID, 
//                   Copies, ReplyTo, Sender, Recipients, Size, Texts, Encoding, 
//                   NonASCIICharacterEncodingType, Partial. Filled if status is True.
//
// Notes:
//   *  In the test mode, this parameter is ignored during the return value generation.
//   ** If any of the attachments are email messages, they are not returned, 
//      but their attachments and texts are returned (as binary data, recursively).
//
Function DownloadMessages(Val Account,
                           Val ImportParameters = Undefined) Export
	
	// Used to check whether logon to the mailbox can be performed
	Var TestMode;
	
	// Receive only message headers
	Var GetHeaders;
	
	// Convert messages to simple type
	Var CastMessagesToType;
	
	// Headers or IDs of messages whose full texts are to be retrieved
	Var HeadersIDs;
	
	If ImportParameters.Property("TestMode") Then
		TestMode = ImportParameters.TestMode;
	Else
		TestMode = False;
	EndIf;
	
	If ImportParameters.Property("GetHeaders") Then
		GetHeaders = ImportParameters.GetHeaders;
	Else
		GetHeaders = False;
	EndIf;
	
	Profile = InternetMailProfile(Account, True);
	
	If ImportParameters.Property("HeadersIDs") Then
		HeadersIDs = ImportParameters.HeadersIDs;
	Else
		HeadersIDs = New Array;
	EndIf;
	
	MessageSetToDelete = New Array;
	
	Connection = New InternetMail;
	
	Protocol = InternetMailProtocol.POP3;
	If CommonUse.ObjectAttributeValue(Account, "ProtocolForIncomingMail") = "IMAP" Then
		Protocol = InternetMailProtocol.IMAP;
	EndIf;
	
	Connection.Logon(Profile, Protocol);
	
	If TestMode Or GetHeaders Then
		
		MessageSet = Connection.GetHeaders();
		
	Else
		TransportSettings = CommonUse.ObjectAttributeValues(Account, "KeepMessageCopiesAtServer,KeepMessagesOnServerPeriod");
		If TransportSettings.KeepMessageCopiesAtServer Then
			
			If HeadersIDs.Count() =0
			   And TransportSettings.KeepMessagesOnServerPeriod > 0 Then
				
				Headings = Connection.GetHeaders();
				
				MessageSetToDelete = New Array;
				
				For Each ItemHeader In Headings Do
					CurrentDate = CurrentSessionDate();
					DateDifference = (CurrentDate - ItemHeader.PostingDate) / (3600*24);
					If DateDifference >= TransportSettings.KeepMessagesOnServerPeriod Then
						MessageSetToDelete.Add(ItemHeader);
					EndIf;
				EndDo;
				
			EndIf;
			
			AutomaticallyDeleteMessagesOnChoiceFromServer = False;
			
		Else
			
			AutomaticallyDeleteMessagesOnChoiceFromServer = True;
			
		EndIf;
		
		MessageSet = Connection.Get(AutomaticallyDeleteMessagesOnChoiceFromServer, HeadersIDs);
		
		If MessageSetToDelete.Count() > 0 Then
			Connection.DeleteMessages(MessageSetToDelete);
		EndIf;
		
	EndIf;
	
	Connection.Logoff();
	
	If TestMode Then
		Return True;
	EndIf;
	
	If ImportParameters.Property("CastMessagesToType") Then
		CastMessagesToType = ImportParameters.CastMessagesToType;
	Else
		CastMessagesToType = True;
	EndIf;
	
	If CastMessagesToType Then
		If ImportParameters.Property("Columns") Then
			MessageSet = GetAdaptedMessageSet(MessageSet, ImportParameters.Columns);
		Else
			MessageSet = GetAdaptedMessageSet(MessageSet);
		EndIf;
	EndIf;
	
	Return MessageSet;
	
EndFunction

// Connects to a mail server.
// Parameters:
//   Profile - InternetMailProfile - email account profile used to establish connection.
//
// Returns:
//   Connection (InternetMail type).
//
Function ConnectToMailServer(Profile) Export
	
	Connection = New InternetMail;
	Connection.Logon(Profile);
	
	Return Connection;
	
EndFunction

// Creates the profile of the passed account for connection to the mail server.
//
// Parameters:
//  Account - CatalogRef.EmailAccounts - account.
//
// Returns:
//  InternetMailProfile - account profile.
//  Undefined - cannot get the account by reference.
//
Function InternetMailProfile(Account, ForReceiving = False) Export
	
	QueryText =
	"SELECT ALLOWED
	|	EmailAccounts.IncomingMailServer AS IMAPServerAddress,
	|	EmailAccounts.IncomingMailServerPort AS IMAPPort,
	|	EmailAccounts.UseSecureConnectionForIncomingMail AS IMAPUseSSL,
	|	EmailAccounts.User AS IMAPUser,
	|	EmailAccounts.Password AS IMAPPassword,
	|	EmailAccounts.UseSafeLogonToIncomingMailServer AS IMAPSecureAuthenticationOnly,
	|	EmailAccounts.IncomingMailServer AS POP3ServerAddress,
	|	EmailAccounts.IncomingMailServerPort AS POP3Port,
	|	EmailAccounts.UseSecureConnectionForIncomingMail AS POP3UseSSL,
	|	EmailAccounts.User AS User,
	|	EmailAccounts.Password AS Password,
	|	EmailAccounts.UseSafeLogonToIncomingMailServer AS POP3SecureAuthenticationOnly,
	|	EmailAccounts.OutgoingMailServer AS SMTPServerAddress,
	|	EmailAccounts.OutgoingMailServerPort AS SMTPPort,
	|	EmailAccounts.UseSecureConnectionForOutgoingMail AS SMTPUseSSL,
	|	EmailAccounts.LogonBeforeSending AS POP3BeforeSMTP,
	|	EmailAccounts.SMTPUser AS SMTPUser,
	|	EmailAccounts.SMTPPassword AS SMTPPassword,
	|	EmailAccounts.UseSafeLogonToOutgoingMailServer AS SMTPSecureAuthenticationOnly,
	|	EmailAccounts.Timeout AS Timeout,
	|	EmailAccounts.ProtocolForIncomingMail AS Protocol
	|FROM
	|	Catalog.EmailAccounts AS EmailAccounts
	|WHERE
	|	EmailAccounts.Ref = &Ref";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Account);
	Selection = Query.Execute().Select();
	
	Result = Undefined;
	If Selection.Next() Then
		IMAPPropertyList = "IMAPServerAddress,IMAPPort,IMAPUseSSL,IMAPUser,IMAPPassword,IMAPSecureAuthenticationOnly";
		POP3PropertyList = "POP3ServerAddress,POP3Port,POP3UseSSL,User,Password,POP3SecureAuthenticationOnly";
		SMTPPropertyList = "SMTPServerAddress,SMTPPort,SMTPUseSSL,POP3BeforeSMTP,SMTPUser,SMTPPassword,SMTPSecureAuthenticationOnly";
		
		RequiredProperties = Undefined;
		PropertiesToExclude = Undefined;
		
		If ForReceiving Then
			If Selection.Protocol = "IMAP" Then
				RequiredProperties = IMAPPropertyList;
			Else
				RequiredProperties = POP3PropertyList;
			EndIf;
		Else
			RequiredProperties = SMTPPropertyList;
		EndIf;
		RequiredProperties = RequiredProperties + ",Timeout";
		
		If Selection.POP3BeforeSMTP Then
			RequiredProperties = Undefined;
			PropertiesToExclude = IMAPPropertyList;
		EndIf;
		
		Result = New InternetMailProfile;
		FillPropertyValues(Result, Selection, RequiredProperties, PropertiesToExclude);
	EndIf;
	
	Return Result;
	
EndFunction

// Writes a set of messages adapted by the passed columns.
// Column values whose types are not supported on the client are converted to String type.
//
Function GetAdaptedMessageSet(Val MessageSet, Val Columns = Undefined)
	
	Result = CreateAdaptedEmailMessageDetails(Columns);
	
	For Each MailMessage In MessageSet Do
		NewRow = Result.Add();
		
		For Each ColumnDescription In Columns Do
			
			Value = MailMessage[ColumnDescription];
			
			If TypeOf(Value) = Type("String") Then
				Value = CommonUseClientServer.DeleteDisallowedXMLCharacters(Value);
			EndIf;
			
			If TypeOf(Value) = Type("InternetMailAddresses") Then
				value_result = "";
				For Each NextAddress  In Value Do
					value_tm =  NextAddress.Address;
					If ValueIsFilled(NextAddress.DisplayName) Then
						value_tm = NextAddress.DisplayName + " <" + value_tm + ">";
					EndIf;
					If ValueIsFilled(value_tm) Then
						value_tm = value_tm + ";"
					EndIf;
					value_result = value_result + value_tm;
				EndDo;
				
				If ValueIsFilled(value_result) Then
					value_result = Mid(value_result, 1, StrLen(value_result)-2)
				EndIf;
				
				value = value_result;
			EndIf;
			
			If TypeOf(Value) = Type("InternetMailAddress") Then
				value_tm =  Value.Address;
				If ValueIsFilled(Value.DisplayName) Then
					value_tm = Value.DisplayName + " <" + value_tm + ">";
				EndIf;
				value = value_tm;
			EndIf;
			
			If TypeOf(Value) = Type("InternetMailMessageImportance") Then
				value = String(Value);
			EndIf;
			
			If TypeOf(Value) = Type("InternetMailMessageNonASCIISymbolsEncodingMode") Then
				value = String(Value);
			EndIf;
			
			If TypeOf(Value) = Type("InternetMailAttachments") Then
				value_map = New Map;
			
				For Each NextAttachment In Value Do
					AttachmentName = NextAttachment.Name;
					If TypeOf(NextAttachment.Data) = Type("BinaryData") Then
						value_map.Insert(AttachmentName, NextAttachment.Data);
					Else
						FillNestedAttachments(value_map, AttachmentName, NextAttachment.Data);
					EndIf;
				EndDo;
				
				value = value_map;
			EndIf;
			
			If TypeOf(Value) = Type("InternetMailTexts") Then
				value_array= New Array;
				For Each NextText In Value Do
					value_map = New Map;
					
					value_map.Insert("Data", NextText.Data);
					value_map.Insert("Encoding", NextText.Encoding);
					value_map.Insert("Text", CommonUseClientServer.DeleteDisallowedXMLCharacters(NextText.Text));
					value_map.Insert("TextType", String(NextText.TextType));
					
					value_array.Add(value_map);
				EndDo;
				value = value_array;
			EndIf;
			
			NewRow[ColumnDescription] = Value;
		EndDo;
	EndDo;
	
	Return Result;
	
EndFunction

Procedure FillNestedAttachments(Attachments, AttachmentName, InternetMailMessage)
	
	For Each InternetMailAttachment In InternetMailMessage.Attachments Do
		AttachmentName = InternetMailAttachment.Name;
		If TypeOf(InternetMailAttachment.Data) = Type("BinaryData") Then
			Attachments.Insert(AttachmentName, InternetMailAttachment.Data);
		Else
			FillNestedAttachments(Attachments, AttachmentName, InternetMailAttachment.Data);
		EndIf;
	EndDo;
	
	Index = 0;
	
	For Each InternetMailTexts In InternetMailMessage.Texts Do
		
		If      InternetMailTexts.TextType = InternetMailTextType.HTML Then
			Extension = "html";
		ElsIf InternetMailTexts.TextType = InternetMailTextType.PlainText Then
			Extension = "txt";
		Else
			Extension = "rtf";
		EndIf;
		AttachmentsTextName = "";
		While AttachmentsTextName = "" Or Attachments.Get(AttachmentsTextName) <> Undefined Do
			Index = Index + 1;
			AttachmentsTextName = StringFunctionsClientServer.SubstituteParametersInString("%1 - (%2).%3", AttachmentName, Index, Extension);
		EndDo;
		Attachments.Insert(AttachmentsTextName, InternetMailTexts.Data);
	EndDo;
	
EndProcedure

// Prepares a table for storing messages retrieved from the mail server.
// 
// Parameters:
//   Columns - String - list of message fields (comma-separated) to be written to the table. 
//                      The parameter changes the type to Array.
// Returns:
//   ValueTable - empty value table with columns.
//
Function CreateAdaptedEmailMessageDetails(Columns = Undefined)
	
	If Columns <> Undefined
	   And TypeOf(Columns) = Type("String") Then
		Columns = StringFunctionsClientServer.SplitStringIntoSubstringArray(Columns, ",");
		For Index = 0 To Columns.Count()-1 Do
			Columns[Index] = TrimAll(Columns[Index]);
		EndDo;
	EndIf;
	
	DefaultColumnArray = New Array;
	DefaultColumnArray.Add("Importance");
	DefaultColumnArray.Add("Attachments");
	DefaultColumnArray.Add("PostingDate");
	DefaultColumnArray.Add("DateReceived");
	DefaultColumnArray.Add("Header");
	DefaultColumnArray.Add("SenderName");
	DefaultColumnArray.Add("UID");
	DefaultColumnArray.Add("Cc");
	DefaultColumnArray.Add("ReplyTo");
	DefaultColumnArray.Add("From");
	DefaultColumnArray.Add("To");
	DefaultColumnArray.Add("Size");
	DefaultColumnArray.Add("Subject");
	DefaultColumnArray.Add("Texts");
	DefaultColumnArray.Add("Encoding");
	DefaultColumnArray.Add("NonASCIICharactersEncodingMode");
	DefaultColumnArray.Add("Partial");
	
	If Columns = Undefined Then
		Columns = DefaultColumnArray;
	EndIf;
	
	Result = New ValueTable;
	
	For Each ColumnDescription In Columns Do
		Result.Columns.Add(ColumnDescription);
	EndDo;
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Initial infobase filling and updating

// Adds update handlers that are required by the subsystem.
//
// Parameters:
//   Handlers - ValueTable - see the description of the NewUpdateHandlerTable function 
//                           in the InfobaseUpdate common module.
// 
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.InitialFilling = True;
	Handler.Procedure = "EmailOperationsInternal.FillSystemAccount";
	//PARTIALLY_DELETED
	//Handler = Handlers.Add();
	//Handler.Procedure = "EmailOperationsInternal.FillNewAccountAttributes";
	//Handler.Version = "2.2.2.5";
	
EndProcedure

// Fills a system account with default values.
//
Procedure FillSystemAccount() Export
	
	Account = EmailOperations.SystemAccount().GetObject();
	Account.FillObjectWithDefaultValues();
	InfobaseUpdate.WriteData(Account);
	
EndProcedure

// Fills new attributes of the EmailAccounts catalog.
Procedure FillNewAccountAttributes() Export
	
	QueryText = 
	"SELECT
	|	""POP"" AS ProtocolForIncomingMail,
	|	CASE
	|		WHEN EmailAccounts.SMTPAuthentication = VALUE(Enum.SMTPAuthenticationVariants.POP3BeforeSMTP)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS LogonBeforeSending,
	|	CASE
	|		WHEN EmailAccounts.POP3AuthenticationMode <> VALUE(Enum.POP3AuthenticationModes.Ordinary)
	|				AND EmailAccounts.POP3AuthenticationMode <> VALUE(Enum.POP3AuthenticationModes.EmptyRef)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS UseSafeLogonToIncomingMailServer,
	|	CASE
	|		WHEN EmailAccounts.SMTPAuthenticationMode = VALUE(Enum.SMTPAuthenticationModes.CramMD5)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS UseSafeLogonToOutgoingMailServer,
	|	EmailAccounts.Ref AS Ref
	|FROM
	|	Catalog.EmailAccounts AS EmailAccounts
	|WHERE
	|	EmailAccounts.DeletionMark = False";
	
	Query = New Query(QueryText);
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Account = Selection.Ref.GetObject();
		FillPropertyValues(Account, Selection, , "Ref");
		InfobaseUpdate.WriteData(Account);
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
//
// Account check
//

// Returns the flag showing whether an account has a password.
//
Function PasswordSpecified(Account) Export
	
	Return ValueIsFilled(CommonUse.ObjectAttributeValue(Account, "Password"));
	
EndFunction

// Internal function, used for checking email accounts.
//
Procedure CheckCanSendReceiveEmail(Account, PasswordParameter, ErrorMessage, AdditionalMessage) Export
	
	AccountSettings = CommonUse.ObjectAttributeValues(Account, "UseForSending,UseForReceiving");
	
	ErrorMessage = "";
	AdditionalMessage = "";
	
	If AccountSettings.UseForSending Then
		Try
			CheckIfCanSendTestEmail(Account, PasswordParameter);
		Except
			ErrorMessage = StringFunctionsClientServer.SubstituteParametersInString(
									NStr("en = 'Error sending email message: %1'"),
									BriefErrorDescription(ErrorInfo()) );
		EndTry;
		If Not AccountSettings.UseForReceiving Then
			AdditionalMessage = Chars.LF + NStr("en = '(Email message sending check is performed.)'");
		EndIf;
	EndIf;
	
	If AccountSettings.UseForReceiving Then
		Try
			TestIncomingMailServerConnection(Account, PasswordParameter);
		Except
			If ValueIsFilled(ErrorMessage) Then
				ErrorMessage = ErrorMessage + Chars.LF;
			EndIf;
			
			ErrorMessage = ErrorMessage
								+ StringFunctionsClientServer.SubstituteParametersInString(
										NStr("en = 'Error accessing incoming mail server: %1'"),
										BriefErrorDescription(ErrorInfo()) );
		EndTry;
		If Not AccountSettings.UseForSending Then
			AdditionalMessage = Chars.LF + NStr("en = '(Email message receiving check is performed.)'");
		EndIf;
	EndIf;
	
EndProcedure

// Checks whether an email message can be sent from a specific account.
//
// Parameters:
//   Account - CatalogRef.EmailAccounts - account to be checked.
//
// Returns:
//   Structure:
//     Status (key) - Boolean - True in case of successful logon to POP3 server.
//                              False in case of POP3 server logon error.
//     ErrorMessage (key) - String - if Status is False, contains an error message.
//
Procedure CheckIfCanSendTestEmail(Val Account, Val Password = Undefined)
	
	EmailParameters = New Structure;
	
	EmailParameters.Insert("Subject", NStr("en = 'Test message from 1C:Enterprise'"));
	EmailParameters.Insert("Body", NStr("en = 'This message is sent via 1C:Enterprise email subsystem'"));
	EmailParameters.Insert("Recipient", CommonUse.ObjectAttributeValue(Account, "EmailAddress"));
	If Password <> Undefined Then
		EmailParameters.Insert("Password", Password);
	EndIf;
	
	Try
		EmailOperations.SendEmailMessage(Account, EmailParameters);
	Except
		WriteLogEvent(EventLogMessageText(), EventLogLevel.Error,,
			Account, DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
EndProcedure

// Checks whether an email message can be received using a specific account.
//
// Parameters:
//   Account - CatalogRef.EmailAccounts - account to be checked.
//
// Returns:
//   Structure:
//     Status (key) - Boolean - True in case of successful logon to POP3 server.
//                              False in case of POP3 server logon error.
//     ErrorMessage (key) - String - if Status is False, contains an error message.
//
Procedure TestIncomingMailServerConnection(Val Account, Val Password = Undefined)
	
	ImportParameters = New Structure("TestMode", True);
	
	If Password <> Undefined Then
		ImportParameters.Insert("Password", Password);
	EndIf;
	
	Try
		EmailOperations.DownloadEmailMessages(Account, ImportParameters);
	Except
		WriteLogEvent(EventLogMessageText(), EventLogLevel.Error,,
			Account, DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
EndProcedure

Function EventLogMessageText()
	Return NStr("en = 'Email account validation'", CommonUseClientServer.DefaultLanguageCode());
EndFunction

// DIB 

// Handler for the event of the same name that occurs during data exchange in a distributed infobase.
//
// Parameters:
// see the OnReceiveDataFromSlave() event handler description in the Syntax Assistant.
// 
Procedure OnReceiveDataFromSlave(DataItem, ItemReceive, SendBack, From) Export
	
	OnDataGet(DataItem, ItemReceive, SendBack, From);
	
EndProcedure

// Handler for the event of the same name that occurs during data exchange in a distributed infobase.
//
// Parameters:
// see OnReceiveDataFromMaster() event handler description in the Syntax Assistant.
// 
Procedure OnReceiveDataFromMaster(DataItem, ItemReceive, SendBack, From) Export
	
	OnDataGet(DataItem, ItemReceive, SendBack, From);
	
EndProcedure

// Handler for OnReceiveDataFromMaster and OnReceiveDataFromSlave events that occur during data exchange 
// in a distributed infobase.
//
// Parameters:
//   see the descriptions of the relevant event handlers in the Syntax Assistant.
// 
Procedure OnDataGet(DataItem, ItemReceive, SendBack, From)
	
	If TypeOf(DataItem) = Type("CatalogObject.EmailAccounts") Then
		If DataItem.IsNew() Then
			DataItem.UseForReceiving = False;
			DataItem.UseForSending = False;
		Else
			DataItem.UseForReceiving = CommonUse.ObjectAttributeValue(DataItem.Ref, "UseForReceiving");
			DataItem.UseForSending = CommonUse.ObjectAttributeValue(DataItem.Ref, "UseForSending");
		EndIf;
	EndIf;
	
EndProcedure

// Access management

// Fills the list of access kinds that are used to set metadata object right restrictions.
// If the list of access kinds is not filled, the Access rights report displays incorrect data.
//
// Only access kinds that are explicitly used in access restriction templates must be filled,
// while access kinds used in access value sets can alternately be obtained from the current
// state of the AccessValueSets information register.
//
// To generate the procedure script automatically, it is recommended that you use 
// the developer tools from the Access management subsystem.
//
// Parameters:
//  Description  - String, multiline string of the following format:
//                 <Table>.<Right>.<AccessKind>[.Table object] 
//                 For example,
//                   Document.GoodsReceipt.Read.Companies 
//                   Document.GoodsReceipt.Read.Counterparties
//                   Document.GoodsReceipt.Update.Companies
//                   Document.GoodsReceipt.Update.Counterparties
//                   Document.EmailMessages.Read.Object.Document.EmailMessages 
//                   Document.EmailMessages.Update.Object.Document.EmailMessages
//                   Document.Files.Read.Object.Catalog.FileFolders 
//                   Document.Files.Read.Object.Document.EmailMessage
//                   Document.Files.Update.Object.Catalog.FileFolders 
//                   Document.Files.Update.Object.Document.EmailMessage 
//                 The Object access kind is predefined as a literal. 
//                 It is not included in the predefined items of ChartsOfCharacteristicTypes.AccessKinds.
//                 This access kind is used in access restriction templates as a reference 
//                 to another object used to apply a restriction to a table.
//                 If Object access kind is specified, table types that are used in the access kind 
//                 must be specified too (in other words, you have to list the types that match 
//                 the access restriction template field that describes the Object access kind).
//                 The list of types for the Object access kinds should only include the field types 
//                 available for the InformationRegisters.AccessValueSets.Object field, 
//                 other types are not needed.
// 
Procedure OnFillMetadataObjectAccessRestrictionKinds(Description) Export
	
	If Not CommonUse.SubsystemExists("StandardSubsystems.AccessManagement") Then
		Return;
	EndIf;
	
	AccessManagementInternalModule = CommonUse.CommonModule("AccessManagementInternal");
	
	If AccessManagementInternalModule.AccessKindExists("EmailAccounts") Then
		
		Description = Description +
		"Catalog.EmailAccounts.Read.EmailAccounts";
		
	EndIf;
	
EndProcedure

// Fills access kinds that are used in access restrictions.
// Users and ExternalUsers access kinds are already filled.
// They can be deleted if they are not used in access restrictions.
//
// Parameters:
//   AccessKinds - ValueTable with the following fields:
//   - Name                - String - name used in the descriptions of supplied access group 
//                           profiles and in RLS texts.

//  - Presentation         - String - access kind presentation in profiles and access groups.
//  - ValueType            - Type - access value reference type.       
//                           For example, Type("CatalogRef.ProductsAndServices").
//  - ValueGroupType       - Type - access value group reference type. 
//                           For example, Type("CatalogRef.ProductAndServiceAccessGroups").
//  - MultipleValueGroups - Boolean - if True, multiple value groups (product and service access groups) 
//                           can be selected for a single access value (ProductsAndServices).
//
Procedure OnFillAccessKinds(AccessKinds) Export
	
	AccessKind = AccessKinds.Add();
	AccessKind.Name = "EmailAccounts";
	AccessKind.Presentation = NStr("en = 'Email accounts'");
	AccessKind.ValueType   = Type("CatalogRef.EmailAccounts");
	
EndProcedure

#EndRegion
