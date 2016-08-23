//------------------------------------------------------------------------------
// SPECIFICATION OF THE PARAMETERS PASSED TO THE FORM
//
//	Account	- ValueList, RefCatalog.EmailAccounts, Undefined
//						If the type is a list of values,
//						presentation is an account name, and value is a reference to the account.
//						If this parameter is not filled, accounts available to the current user are suggested.
//
//	Recipients - ValueList, String.
//						If the type is a list of values,
//						presentation is a recipient name, and value is an email address.
//						If the type is String, it is a list of email addresses
//						that must have valid format*.
//
//	Attachments - ValueList, where 
//						presentation - String - attachment name,
//						value        - BinaryData - attachment binary data,
//									- String - file address in a temporary storage,
//									- String - file path on the client.
//
//	DeleteFilesAfterSending - Boolean - delete files in the local file system
//	after successful sending.
//
//	Subject - String - email subject.
//	Body - String - email body.
//	ReplyTo - String - reply address.
//
// Use
//
// *valid email address format:
// Z = ([User Name] [<]User@MailServer[>][;]), String = Z[Z]..
//
// RETURNS
//
// Undefined
//
// Boolean - True if the message is sent,
//           False if the message is not sent.
//
//------------------------------------------------------------------------------
// SPECIFICATION OF FORM OPERATIONS
//
// If the passed list of accounts contains multiple entries, the form suggests
// selecting an account for sending email. Selecting an arbitrary account
// (the one that is not passed to the form) is not allowed.
//
// If no accounts are passed to the form, the form suggests selecting an account 
// from the list of accounts available to the user, and the account form item displays 
// the account selection button.
//
// If attachment files are available on 1С:Enterprise server, do not use binary data as the parameter.
// Instead, use a reference to the data in a temporary storage.
//
//------------------------------------------------------------------------------

&AtClient
Var NormalizedPostalAddress;

#Region FormEventHandlers

// Fills form fields forms according to the parameters passed to the form.
//
// The following parameters can be passed to the form:
// Account* - CatalogRef.EmailAccounts, list -
//               reference to the account used to send messages, or a list of accounts (for selection).
// Attachments - Map - email attachments, where key is the file name, and value is the file binary data.
// Subject - String - email subject.
// Body - String - email body.
// Recipients - Map/String - message recipients.
//                 If the type is Map, 
//                    key   - String - recipient name.
//                    value - String - email address in addr@server format.
//
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
 // Skipping the initialization to guarantee that the form will be received if the Autotest parameter is passed.
	If Parameters.Property("AutoTest") Then
		Return;
	EndIf;
	
	EmailSubject = Parameters.Subject;
	EmailBody = Parameters.Body;
	ReplyTo = Parameters.ReplyTo;
 	
	If TypeOf(Parameters.Attachments) = Type("ValueList") Or TypeOf(Parameters.Attachments) = Type("Array") Then
		For Each Attachment In Parameters.Attachments Do
			AttachmentDetails = Attachments.Add();
			If TypeOf(Parameters.Attachments) = Type("ValueList") Then
				AttachmentDetails.Presentation = Attachment.Presentation;
				If TypeOf(Attachment.Value) = Type("BinaryData") Then
					AttachmentDetails.AddressInTempStorage = PutToTempStorage(Attachment.Value, UUID);
				Else
					If IsTempStorageURL(Attachment.Value) Then
						AttachmentDetails.AddressInTempStorage = PutToTempStorage(GetFromTempStorage(Attachment.Value), UUID);
					Else
						AttachmentDetails.PathToFile = Attachment.Value;
					EndIf;
				EndIf;
			Else // TypeOf (Parameters.Attachments) = "structure array"
				FillPropertyValues(AttachmentDetails, Attachment);
				If Not IsBlankString(AttachmentDetails.AddressInTempStorage) Then
					AttachmentDetails.AddressInTempStorage = PutToTempStorage(
						GetFromTempStorage(AttachmentDetails.AddressInTempStorage), UUID);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	// Processing complex form parameters (parameters having composite type)
	// Account, Recipients
	
	If NOT ValueIsFilled(Parameters.Account) Then
		// Account is not passed, selecting the first available account
		AvailableEmailAccounts = EmailOperations.AvailableEmailAccounts(True);
		If AvailableEmailAccounts.Count() = 0 Then
			MessageText = NStr("en = 'No available email accounts are found, contact the system administrator.'");
			CommonUseClientServer.MessageToUser(MessageText,,,,Cancel);
			Return;
		EndIf;
		Account = AvailableEmailAccounts[0].Ref;
		PasswordSpecified = ValueIsFilled(Account.Password);
		Items.Account.ChoiceButton = True;
	ElsIf TypeOf(Parameters.Account) = Type("CatalogRef.EmailAccounts") Then
		Account = Parameters.Account;
		PasswordSpecified = ValueIsFilled(Account.Password);
		AccountSpecified = True;
	ElsIf TypeOf(Parameters.Account) = Type("ValueList") Then
		EmailAccountList = Parameters.Account;
		
		If EmailAccountList.Count() = 0 Then
			MessageText = NStr("en = 'Accounts for sending mail are not specified, contact the system administrator.'");
			CommonUseClientServer.MessageToUser(MessageText,,,, Cancel);
			Return;
		EndIf;
		
		PasswordIsSetMac = New Array;
		
		For Each ItemAccount In EmailAccountList Do
			Items.Account.ChoiceList.Add(
										ItemAccount.Value,
										ItemAccount.Presentation);
			If ItemAccount.Value.UseForReceiving Then
				ReplyToByEmailAccounts.Add(ItemAccount.Value,
														GetEmailAddressByAccount(ItemAccount.Value));
			EndIf;
			If ValueIsFilled(ItemAccount.Value.Password) Then
				PasswordIsSetMac.Add(ItemAccount.Value);
			EndIf;
		EndDo;
		PasswordSpecified = New FixedArray(PasswordIsSetMac);
		Items.Account.ChoiceList.SortByPresentation();
		Account = EmailAccountList[0].Value;
		
		// Selecting accounts from the passed account list
   Items.Account.DropListButton = True;
		
		AccountSpecified = True;
		
		If Items.Account.ChoiceList.Count() <= 1 Then
			Items.Account.Visible = False;
		EndIf;
	EndIf;
	
	If TypeOf(Parameters.Recipient) = Type("ValueList") Then
		RecipientEmailAddress = "";
		For Each EmailItem In Parameters.Recipients Do
			If ValueIsFilled(EmailItem.Presentation) Then
				RecipientEmailAddress = RecipientEmailAddress
										+ EmailItem.Presentation
										+ " <"
										+ EmailItem.Value
										+ ">; "
			Else
				RecipientEmailAddress = RecipientEmailAddress 
										+ EmailItem.Value
										+ "; ";
			EndIf;
		EndDo;
	ElsIf TypeOf(Parameters.Recipient) = Type("String") Then
		RecipientEmailAddress = Parameters.Recipient;
	ElsIf TypeOf(Parameters.Recipient) = Type("Array") Then
		For Each RecipientStructure In Parameters.Recipients Do
			AddressArray = StringFunctionsClientServer.SplitStringIntoSubstringArray(RecipientStructure.Address, ";");
			For Each Address In AddressArray Do
				If IsBlankString(Address) Then 
					Continue;
				EndIf;
				RecipientEmailAddress = RecipientEmailAddress + RecipientStructure.Presentation + " <" + TrimAll(Address) + ">;";
			EndDo;
		EndDo;
	EndIf;
	
	// Getting the list of addresses that the user previously used
	ReplyToList = CommonUse.CommonSettingsStorageLoad(
		"EditNewEmailMessage", 
		"ReplyToList");
	
	If ReplyToList <> Undefined And ReplyToList.Count() > 0 Then
		For Each ReplyToItem In ReplyToList Do
			Items.ReplyTo.ChoiceList.Add(ReplyToItem.Value, ReplyToItem.Presentation);
		EndDo;
		
		Items.ReplyTo.DropListButton = True;
	EndIf;
	
	If ValueIsFilled(ReplyTo) Then
		AutomaticReplyAddressSubstitution = False;
	Else
		If Account.UseForReceiving Then
			// Setting default email address
			If ValueIsFilled(Account.UserName) Then
				ReplyTo = Account.UserName + " <" + Account.EmailAddress + ">";
			Else
				ReplyTo = Account.EmailAddress;
			EndIf;
		EndIf;
		
		AutomaticReplyAddressSubstitution = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ImportAttachmentsFromFiles();
	RefreshAttachmentPresentation();
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	
	If Upper(ChoiceSource.FormName) = Upper("CommonForm.AccountPasswordConfirmation") Then
		
		ContinueSendingEmailWithPassword(SelectedValue);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemEventHandlers

&AtClient
Procedure AccountStartChoice(Item, ChoiceData, StandardProcessing)
	
	If AccountSpecified Then
	
		// If the account is passed as a parameter, selecting another account is not allowed
		StandardProcessing = False;
	EndIf;
	
EndProcedure


// Fills the reply address if the flag governing the autofilling of the reply address is set.
//
&AtClient
Procedure AccountChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	If AutomaticReplyAddressSubstitution Then
		If ReplyToByEmailAccounts.FindByValue(SelectedValue) <> Undefined Then
			ReplyTo = ReplyToByEmailAccounts.FindByValue(SelectedValue).Presentation;
		Else
			ReplyTo = GetEmailAddressByAccount(SelectedValue);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region AttachmentsFormTableItemEventHandlers

// Removes an attachment from the list and also calls the function 
// that updates the table of attachment presentations.
//
&AtClient
Procedure AttachmentsBeforeDelete(Item, Cancel)
	
	AttachmentDescription = Item.CurrentData[Item.CurrentItem.Name];
	
	For Each Attachment In Attachments Do
		If Attachment.Presentation = AttachmentDescription Then
			Attachments.Delete(Attachment);
		EndIf;
	EndDo;
	
	RefreshAttachmentPresentation();
	
EndProcedure

&AtClient
Procedure AttachmentsBeforeAddRow(Item, Cancel, Clone, Parent, Group)
	
	Cancel = True;
	AddingFileToAttachments();
	
EndProcedure

&AtClient
Procedure AttachmentsChoice(Item, SelectedRow, Field, StandardProcessing)
	
	OpenAttachment();
	
EndProcedure

&AtClient
Procedure AttachmentsDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure AttachmentsDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
 
	If TypeOf(DragParameters.Value) = Type("File") Then
		NotifyDescription = New NotifyDescription("AttachmentsDragCompletion", ThisObject, New Structure("Name", DragParameters.Value.Name));
		BeginPutFile(NotifyDescription, , DragParameters.Value.FullName, False);
	EndIf;
	
EndProcedure

&AtClient
Procedure ReplyToTextEditEnd(Item, Text, ChoiceData, StandardProcessing)
	
	If AutomaticReplyAddressSubstitution Then
		If Not ValueIsFilled(ReplyTo)
		 Or Not ValueIsFilled(Text) Then
			AutomaticReplyAddressSubstitution = False;
		Else
			AddressMap1 = CommonUseClientServer.SplitStringWithEmailAddresses(ReplyTo);
			Try
				AddressMap2 = CommonUseClientServer.SplitStringWithEmailAddresses(Text);
			Except
				ErrorMessage = BriefErrorDescription(ErrorInfo());
				CommonUseClientServer.MessageToUser(ErrorMessage, , "ReplyTo");
				StandardProcessing = False;
				Return;
			EndTry;
				
			If Not EmailAddressesEqual(AddressMap1, AddressMap2) Then
				AutomaticReplyAddressSubstitution = False;
			EndIf;
		EndIf;
	EndIf;
	
	ReplyTo = GetNormalizedEmailInFormat(Text);
	
EndProcedure

// Removes the flag governing the autofilling of the reply address.
//
&AtClient
Procedure ReplyToChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	AutomaticReplyAddressSubstitution = False;
	
EndProcedure

&AtClient
Procedure ReplyToClearing(Item, StandardProcessing)

	StandardProcessing = False;
	UpdateReplyToAddressInStoredList(ReplyTo, False);
	
	For Each ReplyToItem In Items.ReplyTo.ChoiceList Do
		If ReplyToItem.Value = ReplyTo
		   And ReplyToItem.Presentation = ReplyTo Then
			Items.ReplyTo.ChoiceList.Delete(ReplyToItem);
		EndIf;
	EndDo;
	
	ReplyTo = "";
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OpenFile(Command)
	OpenAttachment();
EndProcedure

&AtClient
Procedure SendEmail()
	
	ClearMessages();
	
	Try
		NormalizedPostalAddress = CommonUseClientServer.SplitStringWithEmailAddresses(RecipientEmailAddress);
	Except
		CommonUseClientServer.MessageToUser(
				BriefErrorDescription(ErrorInfo()), ,
				RecipientEmailAddress);
		Return;
	EndTry;
	
	If ValueIsFilled(ReplyTo) Then
		Try
			CommonUseClientServer.SplitStringWithEmailAddresses(ReplyTo);
		Except
			CommonUseClientServer.MessageToUser(
					BriefErrorDescription(ErrorInfo()), ,
					"ReplyTo");
			Return;
		EndTry;
	EndIf;
	
	If ((TypeOf(PasswordSpecified) = Type("Boolean") And Not PasswordSpecified)
		Or  (TypeOf(PasswordSpecified) = Type("FixedArray") And PasswordSpecified.Find(Account) = Undefined)) Then
		FormParameters = New Structure;
		FormParameters.Insert("Account", Account);
		OpenForm("CommonForm.AccountPasswordConfirmation", FormParameters, ThisObject);
	Else
		ContinueSendingEmailWithPassword();
	EndIf;
	
EndProcedure

&AtClient
Procedure AttachFileExecute()
	
	AddingFileToAttachments();
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

////////////////////////////////////////////////////////////////////////////////
// FORM AND FORM ITEM EVENT HANDLER SECTION
//

&AtServerNoContext
Function SendEmailMessage(Val Account, Val EmailParameters)
	
	Return EmailOperations.SendEmailMessage(Account, EmailParameters);
	
EndFunction

&AtServerNoContext
Function GetEmailAddressByAccount(Val Account)
	
	Return TrimAll(Account.UserName)
			+ ? (IsBlankString(TrimAll(Account.UserName)),
					Account.EmailAddress,
					" <" + Account.EmailAddress + ">");
	
EndFunction

&AtClient
Procedure OpenAttachment()
	
	SelectedAttachment = SelectedAttachment();
	If SelectedAttachment = Undefined Then
		Return;
	EndIf;
	
	#If WebClient Then
		GetFile(SelectedAttachment.AddressInTempStorage, , True);
	#Else
		TempFolderName = GetTempFileName();
		CreateDirectory(TempFolderName);
		
		TempFileName = CommonUseClientServer.AddFinalPathSeparator(TempFolderName) + SelectedAttachment.Presentation;
		
		BinaryData = GetFromTempStorage(SelectedAttachment.AddressInTempStorage);
		BinaryData.Write(TempFileName);
		
		File = New File(TempFileName);
		File.SetReadOnly(True);
		If File.Extension = ".mxl" Then
			SpreadsheetDocument = GetSpreadsheetDocumentByBinaryData(SelectedAttachment.AddressInTempStorage);
			OpenParameters = New Structure;
			OpenParameters.Insert("DocumentName", SelectedAttachment.Presentation);
			OpenParameters.Insert("SpreadsheetDocument", SpreadsheetDocument);
			OpenParameters.Insert("PathToFile", TempFileName);
			OpenForm("CommonForm.SpreadsheetDocumentEditing", OpenParameters, ThisObject);
		Else
			RunApp(TempFileName);
		EndIf;
	#EndIf
	
EndProcedure

&AtClient
Function SelectedAttachment()
	
	Result = Undefined;
	If Items.Attachments.CurrentData <> Undefined Then
		AttachmentDescription = Items.Attachments.CurrentData[Items.Attachments.CurrentItem.Name];
		For Each Attachment In Attachments Do
			If Attachment.Presentation = AttachmentDescription Then
				Result = Attachment;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function GetSpreadsheetDocumentByBinaryData(Val BinaryData)
	
	If TypeOf(BinaryData) = Type("String") Then
		// Binary data address in temporary storage is passed
		BinaryData = GetFromTempStorage(BinaryData);
	EndIf;
	
	FileName = GetTempFileName("mxl");
	BinaryData.Write(FileName);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.Read(FileName);
	
	Try
		DeleteFiles(FileName);
	Except
		WriteLogEvent(NStr("en = 'Getting spreadsheet document'", CommonUseClientServer.DefaultLanguageCode()), EventLogLevel.Error, , , 
			DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return SpreadsheetDocument;
	
EndFunction

&AtClient
Procedure AddingFileToAttachments()
	
	Var PlacedFiles;
	
	If AttachFileSystemExtension() Then
		PlacedFiles = New Array;
		If PutFiles(, PlacedFiles, "", True, ) Then
			AddFilesToList(PlacedFiles);
			RefreshAttachmentPresentation();
		EndIf;
	Else
		ShowMessageBox(,NStr("en = 'Adding files in the web client is only supported if you have the file system extension installed.'"));
	EndIf;
	
EndProcedure

&AtServer
Procedure AddFilesToList(PlacedFiles)
	
	For Each FileDetails In PlacedFiles Do
		File = New File(FileDetails.Name);
		Attachment = Attachments.Add();
		Attachment.Presentation = File.Name;
		Attachment.AddressInTempStorage = PutToTempStorage(GetFromTempStorage(FileDetails.Location), UUID);
	EndDo;
	
EndProcedure

&AtClient
Procedure RefreshAttachmentPresentation()
	
	AttachmentPresentation.Clear();
	
	Index = 0;
	
	For Each Attachment In Attachments Do
		If Index = 0 Then
			PresentationRow = AttachmentPresentation.Add();
		EndIf;
		
		PresentationRow["Attachment" + String(Index + 1)] = Attachment.Presentation;
		
		Index = Index + 1;
		If Index = 2 Then
			Index = 0;
		EndIf;
	EndDo;
	
EndProcedure

// Checks whether sending email is possible. If it is possible, generates the sending parameters.
//
&AtClient
Function GenerateEmailParameters(Val Password = Undefined)
	
	EmailParameters = New Structure;
	
	If ValueIsFilled(Password) Then
		EmailParameters.Insert("Password", Password);
	EndIf;
	
	If ValueIsFilled(NormalizedPostalAddress) Then
		EmailParameters.Insert("Recipient", NormalizedPostalAddress);
	EndIf;
	
	If ValueIsFilled(ReplyTo) Then
		EmailParameters.Insert("ReplyTo", ReplyTo);
	EndIf;
	
	If ValueIsFilled(EmailSubject) Then
		EmailParameters.Insert("Subject", EmailSubject);
	EndIf;
	
	If ValueIsFilled(EmailBody) Then
		EmailParameters.Insert("Body", EmailBody);
	EndIf;
	
	EmailParameters.Insert("Attachments", Attachments());
	
	Return EmailParameters;
	
EndFunction

&AtClient
Function Attachments()
	
	Result = New Array;
	For Each Attachment In Attachments Do
		AttachmentDetails = New Structure;
		AttachmentDetails.Insert("Presentation", Attachment.Presentation);
		AttachmentDetails.Insert("AddressInTempStorage", Attachment.AddressInTempStorage);
		AttachmentDetails.Insert("Encoding", Attachment.Encoding);
		Result.Add(AttachmentDetails);
	EndDo;
	
	Return Result;
	
EndFunction

// Adds the reply address to the list of stored values.
//
&AtServerNoContext
Function SaveReplyTo(Val ReplyTo)
	
	UpdateReplyToAddressInStoredList(ReplyTo);
	
EndFunction

// Adds the reply address to the list of stored values
//
&AtServerNoContext
Function UpdateReplyToAddressInStoredList(Val ReplyTo,
                                                   Val AddAddressToList = True)
	
	// Getting the list of addresses that the user previously used
	ReplyToList = CommonUse.CommonSettingsStorageLoad(
		"EditNewEmailMessage",
		"ReplyToList");
	
	If ReplyToList = Undefined Then
		ReplyToList = New ValueList();
	EndIf;
	
	For Each ItemReplyTo In ReplyToList Do
		If ItemReplyTo.Value = ReplyTo
		   And ItemReplyTo.Presentation = ReplyTo Then
			ReplyToList.Delete(ItemReplyTo);
		EndIf;
	EndDo;
	
	If AddAddressToList
	   And ValueIsFilled(ReplyTo) Then
		ReplyToList.Insert(0, ReplyTo, ReplyTo);
	EndIf;
	
	CommonUse.CommonSettingsStorageSave(
		"EditNewEmailMessage",
		"ReplyToList",
		ReplyToList);
	
EndFunction

// Compares two email addresses.
// Parameters:
//   AddressMap1 - String - first email address.
//   AddressMap2 - String - second e-mail address.
// Returns:
//   True if the addresses are identical, False otherwise.
//
&AtClient
Function EmailAddressesEqual(AddressMap1, AddressMap2)
	
	If AddressMap1.Count() <> 1
	 Or AddressMap2.Count() <> 1 Then
		Return False;
	EndIf;
	
	If AddressMap1[0].Presentation = AddressMap2[0].Presentation
	   And AddressMap1[0].Address         = AddressMap2[0].Address Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

&AtClient
Function GetNormalizedEmailInFormat(Text)
	
	MailAddress = "";
	
	AddressArray = CommonUseClientServer.SplitStringWithEmailAddresses(Text);
	
	For Each ItemAddress In AddressArray Do
		If ValueIsFilled(ItemAddress.Presentation) Then
			MailAddress = MailAddress + ItemAddress.Presentation
							+ ? (IsBlankString(TrimAll(ItemAddress.Address)), "", " <" + ItemAddress.Address + ">");
		Else
			MailAddress = MailAddress + ItemAddress.Address + ";";
		EndIf;
	EndDo;
		
	Return MailAddress;
	
EndFunction

&AtClient
Procedure ContinueSendingEmailWithPassword(Password = Undefined)
	
	EmailParameters = GenerateEmailParameters(Password);
	
	If EmailParameters = Undefined Then
		CommonUseClientServer.MessageToUser(NStr("en = 'Error generating email message parameters'"));
		Return;
	EndIf;
	
	Try
		SendEmailMessage(Account, EmailParameters);
	Except
		CommonUseClientServer.MessageToUser(BriefErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	SaveReplyTo(ReplyTo);
	
	NotifyDescription = New NotifyDescription("ContinueSendingEmailWithPasswordCompletion", ThisObject);
	ShowMessageBox(NotifyDescription, NStr("en = 'The message is sent'"));
	
EndProcedure

&AtClient
Procedure ContinueSendingEmailWithPasswordCompletion(AdditionalParameters) Export
	Close();
EndProcedure

&AtClient
Procedure AttachmentsDragCompletion(Result, TempStorageAddress, SelectedFileName, AdditionalParameters) Export
	
	Files = New Array;
	PassedFile = New TransferableFileDescription(AdditionalParameters.Name, TempStorageAddress);
	Files.Add(PassedFile);
	AddFilesToList(Files);
	RefreshAttachmentPresentation();
	
EndProcedure

&AtClient
Procedure ImportAttachmentsFromFiles()
	
	For Each Attachment In Attachments Do
		If Not IsBlankString(Attachment.PathToFile) Then
			BinaryData = New BinaryData(Attachment.PathToFile);
			Attachment.AddressInTempStorage = PutToTempStorage(BinaryData, UUID);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion