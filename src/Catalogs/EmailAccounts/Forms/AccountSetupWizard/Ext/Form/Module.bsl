
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
 // Skipping the initialization to guarantee that the form will be received if the Autotest parameter is passed.
	If Parameters.Property("Autotest") Then 
		Return;
	EndIf;
	
	Items.GotoSettingsButton.Visible = False;
	UseSecurityProfiles = GetFunctionalOption("UseSecurityProfiles");
	Items.SettingMethod.Visible = Not UseSecurityProfiles;
	If UseSecurityProfiles Then
		SettingMethod = "Manually";
	Else
		SettingMethod = "Automatically";
	EndIf;
	
	ContextMode = Parameters.ContextMode;
	Items.UseAccount.Visible = Not ContextMode;
	Items.AccountSettingsTitle.Title = ?(ContextMode,
		NStr("en = 'To be able to send email, configure the email account'"),
		NStr("en = 'Enter account parameters'"));
		
	If Not ContextMode Then
		Title = NStr("en = 'Create email account'");
	Else
		Title = NStr("en = 'Set up email account'");
	EndIf;
	
	UseForReceiving = Not ContextMode;
	UseForSending = True;
	Items.Pages.CurrentPage = Items.AccountSettings;
	
	WindowOptionsKey = ?(ContextMode, "ContextMode", "NoContextMode");
	
	NewAccountRef = Catalogs.EmailAccounts.GetRef();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	SetCurrentPageItems()
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If FormClosingConfirmationRequired Then
		Cancel = True;
		AttachIdleHandler("ShowQueryBoxBeforeCloseForm", 0.1, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemEventHandlers

&AtClient
Procedure PasswordOnChange(Item)
	PasswordForSendingEmails = PasswordForReceivingEmails;
EndProcedure

&AtClient
Procedure KeepEmailCopiesOnServerOnChange(Item)
	RefreshDaysBeforeDeleteEnabled();
EndProcedure

&AtClient
Procedure EmailAddressOnChange(Item)
	SettingsFilled = False;
	FormClosingConfirmationRequired = True;
EndProcedure

&AtClient
Procedure EmailSenderNameOnChange(Item)
	FormClosingConfirmationRequired = True;
EndProcedure

&AtClient
Procedure SetupMethodOnChange(Item)
	SetCurrentPageItems();
EndProcedure

#EndRegion

#Region FormTableNameFormTableItemEventHandlers

#EndRegion

#Region FormCommandHandlers

&AtClient

Procedure Next(Command)
	
	GotoNextPage();
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	CurrentPage = Items.Pages.CurrentPage;
	
	PreviousPage = Undefined;
	If CurrentPage = Items.OutgoingMailServerSetup Then
		PreviousPage = Items.AccountSettings;
	ElsIf CurrentPage = Items.IncomingMailServerSetup Then
		If UseForSending Then
			PreviousPage = Items.OutgoingMailServerSetup;
		Else
			PreviousPage = Items.AccountSettings;
		EndIf;
	ElsIf CurrentPage = Items.AdditionalSettings Then
		If UseForReceiving Or LogonBeforeSending Then
			PreviousPage = Items.IncomingMailServerSetup;
		ElsIf UseForSending Then
			PreviousPage = Items.OutgoingMailServerSetup;
		Else
			PreviousPage = Items.AccountSettings;
		EndIf;
	ElsIf CurrentPage = Items.CheckingAccountSettings Then
		PreviousPage = Items.AccountSettings;
	EndIf;
	
	If PreviousPage <> Undefined Then
		Items.Pages.CurrentPage = PreviousPage;
	EndIf;
	
	SetCurrentPageItems()
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtClient
Procedure ShowQueryBoxBeforeCloseForm()
	QuestionText = NStr("en = 'The form contains unsaved data. Do you want to close the form?'");
	NotifyDescription = New NotifyDescription("CloseFormConfirmed", ThisObject);
	Buttons = New ValueList;
	Buttons.Add("Close", NStr("en = 'Close'"));
	Buttons.Add(DialogReturnCode.Cancel, NStr("en = 'Do not close'"));
	ShowQueryBox(NotifyDescription, NStr("en = 'The form contains unsaved data. Do you want to close the form?'"), Buttons,,		
		DialogReturnCode.Cancel, NStr("en = 'Account setup'"));
EndProcedure
	
&AtClient
Procedure CloseFormConfirmed(QuestionResult, AdditionalParameters = Undefined) Export
	
	If QuestionResult = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	FormClosingConfirmationRequired = False;
	Close(False);
	
EndProcedure

&AtClient
Procedure GotoNextPage()
	
	Cancel = False;
	CurrentPage = Items.Pages.CurrentPage;
	
	NextPage = Undefined;
	If CurrentPage = Items.AccountSettings Then
		CheckFillingOnAccountSettingsPage(Cancel);
		If Not Cancel And Not SettingsFilled Then
			FillAccountSettings();
		EndIf;
		If SettingMethod = "Automatically" Or CheckingCompletedWithErrors Then
			NextPage = Items.CheckingAccountSettings;
		Else
			If UseForSending Then
				NextPage = Items.OutgoingMailServerSetup;
			ElsIf UseForReceiving Then
				NextPage = Items.IncomingMailServerSetup;
			Else
				NextPage = Items.AdditionalSettings;
			EndIf;
		EndIf;
	ElsIf CurrentPage = Items.OutgoingMailServerSetup Then
		If Not ContextMode Or LogonBeforeSending Then
			NextPage = Items.IncomingMailServerSetup;
		Else
			NextPage = Items.AdditionalSettings;
		EndIf;
	ElsIf CurrentPage = Items.IncomingMailServerSetup Then
		NextPage = Items.AdditionalSettings;
	ElsIf CurrentPage = Items.AdditionalSettings Then
		NextPage = Items.CheckingAccountSettings;
	ElsIf CurrentPage = Items.CheckingAccountSettings Then
		If CheckingCompletedWithErrors Then
			NextPage = Items.AccountSettings;
		Else
			NextPage = Items.AccountConfigured;
		EndIf;
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	If NextPage = Undefined Then
		Close(True);
	Else
		Items.Pages.CurrentPage = NextPage;
		SetCurrentPageItems();
	EndIf;
	
	If Items.Pages.CurrentPage = Items.CheckingAccountSettings Then
		If SettingMethod = "Automatically" Then
			AttachIdleHandler("SetUpConnectionParametersAutomatically", 0.1, True);
		Else
			AttachIdleHandler("CheckSettings", 0.1, True);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckSettings()
	Request = CreateRequestForUseExternalResources();
	ClosingNotification = New NotifyDescription("CheckSettingsPermissionRequestExecuted", ThisObject);
	
	SafeModeClient.ApplyExternalResourceRequests(
		CommonUseClientServer.ValueInArray(Request), ThisObject, ClosingNotification);
EndProcedure

&AtClient
Procedure CheckSettingsPermissionRequestExecuted(RequestResult, AdditionalParameters) Export
	If Not RequestResult = DialogReturnCode.OK Then
		Return;
	EndIf;
	
	ValidateAccountSettings();
	If ValueIsFilled(AccountRef) Then 
		NotifyChanged(TypeOf(AccountRef));
	EndIf;
	GotoNextPage();
EndProcedure

&AtServer
Function CreateRequestForUseExternalResources()
	
	Return SafeMode.RequestToUseExternalResources(
		Permissions(), NewAccountRef);
	
EndFunction

&AtServer
Function Permissions()
	
	Result = New Array;
	
	If UseForSending Then
		Result.Add(
			SafeMode.PermissionToUseInternetResource(
				"SMTP",
				OutgoingMailServer,
				OutgoingMailServerPort,
				NStr("en = 'Email.'")));
	EndIf;
	
	If UseForReceiving Then
		Result.Add(
			SafeMode.PermissionToUseInternetResource(
				Protocol,
				IncomingMailServer,
				IncomingMailServerPort,
				NStr("en = 'Email.'")));
	EndIf;
	
	Return Result;
	
EndFunction


&AtClient
Procedure CheckFillingOnAccountSettingsPage(Cancel)
	
	If IsBlankString(EmailAddress) Then
		CommonUseClientServer.MessageToUser(NStr("en = 'Enter email address'"), , "EmailAddress", , Cancel);
	ElsIf Not CommonUseClientServer.EmailAddressMeetsRequirements(EmailAddress, True) Then
		CommonUseClientServer.MessageToUser(NStr("en = 'Invalid email address'"), , "EmailAddress", , Cancel);
	EndIf;
	
	If IsBlankString(PasswordForReceivingEmails) Then
		CommonUseClientServer.MessageToUser(NStr("en = 'Enter the password'"), , "PasswordForReceivingEmails", , Cancel);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetCurrentPageItems()
	
	CurrentPage = Items.Pages.CurrentPage;
	
	// NextButton
	If CurrentPage = Items.AccountConfigured Then
		If ContextMode Then
			ButtonTitleNext = NStr("en = 'Continue'");
		Else
			ButtonTitleNext = NStr("en = 'Close'");
		EndIf;
	Else
		If CurrentPage = Items.AccountSettings
			And CheckingCompletedWithErrors Then
				ButtonTitleNext = NStr("en = 'Retry'");
		ElsIf CurrentPage = Items.AccountSettings
			And SettingMethod = "Automatically" Then
			If ContextMode Then
				ButtonTitleNext = NStr("en = 'Set up'");
			Else
				ButtonTitleNext = NStr("en = 'Create'");
			EndIf;
		Else
			ButtonTitleNext = NStr("en = 'Next >'");
		EndIf;
	EndIf;
	Items.NextButton.Title = ButtonTitleNext;
	Items.NextButton.Enabled = CurrentPage <> Items.CheckingAccountSettings;
	Items.NextButton.Visible = CurrentPage <> Items.CheckingAccountSettings;
	
	// BackButton
	Items.BackButton.Visible = CurrentPage <> Items.AccountSettings
		And CurrentPage <> Items.AccountConfigured
		And CurrentPage <> Items.CheckingAccountSettings;
	
	// CancelButton
	Items.CancelButton.Visible = CurrentPage <> Items.AccountConfigured;
	
	// GotoSettingsButton
	Items.GotoSettingsButton.Visible = Not UseSecurityProfiles And (CurrentPage = Items.AccountSettings
		And CheckingCompletedWithErrors Or Not ContextMode And CurrentPage = Items.AccountConfigured);
		
	If Not ContextMode And CurrentPage = Items.AccountConfigured Then
		Items.GotoSettingsButton.Title = NStr("en = 'Go to account'");
	Else
		Items.GotoSettingsButton.Title = NStr("en = 'Set up connection parameters manually'");
	EndIf;
	
	If CurrentPage = Items.AccountSettings Then
		Items.CannotLogOnPictureAndLabel.Visible = CheckingCompletedWithErrors;
		Items.SettingMethod.Visible = Not CheckingCompletedWithErrors And Not UseSecurityProfiles;
	EndIf;
	
	If CurrentPage = Items.IncomingMailServerSetup Then
		RefreshDaysBeforeDeleteEnabled()
	EndIf;
	
	If CurrentPage = Items.AccountConfigured Then
		Items.LabelAccountConfigured.Title = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Setup of %1 account completed.'"), EmailAddress);
	EndIf;
	
EndProcedure

&AtClient
Procedure RefreshDaysBeforeDeleteEnabled()
	Items.DeleteEmailsFromServerAfter.Enabled = KeepEmailCopiesOnServer;
	Items.DaysLabel.Enabled = Items.DeleteEmailsFromServerAfter.Enabled;
EndProcedure

&AtClient
Procedure GotoSettings(Command)
	CurrentPage = Items.Pages.CurrentPage;
	If Not ContextMode And CurrentPage = Items.AccountConfigured Then
		ShowValue(,AccountRef);
		Close(True);
	Else
		If SettingMethod = "Automatically" Then
			SettingMethod = "Manually";
		EndIf;
		Items.Pages.CurrentPage = Items.OutgoingMailServerSetup;
		SetCurrentPageItems();
	EndIf;
EndProcedure

&AtClient
Procedure FillAccountSettings()
	FillPropertyValues(ThisObject, DefaultSettings(EmailAddress, PasswordForReceivingEmails));
	SettingsFilled = True;
EndProcedure

&AtClientAtServerNoContext
Function DefaultSettings(EmailAddress, Password)
	
	Position = Find(EmailAddress, "@");
	ServerNameInAccount = Mid(EmailAddress, Position + 1);
	
	Settings = New Structure;
	
	Settings.Insert("AccountName", EmailAddress);
	
	Settings.Insert("UserNameForReceivingEmails", EmailAddress);
	Settings.Insert("UserNameForSendingEmails", EmailAddress);
	
	Settings.Insert("PasswordForSendingEmails", Password);
	Settings.Insert("PasswordForReceivingEmails", Password);
	
	Settings.Insert("Protocol", "POP");
	Settings.Insert("IncomingMailServer", "pop." + ServerNameInAccount);
	Settings.Insert("IncomingMailServerPort", 995);
	Settings.Insert("UseSecureConnectionForIncomingMail", True);
	Settings.Insert("UseSafeLogonToIncomingMailServer", False);
	
	Settings.Insert("OutgoingMailServer", "smtp." + ServerNameInAccount);
	Settings.Insert("OutgoingMailServerPort", 465);
	Settings.Insert("UseSecureConnectionForOutgoingMail", True);
	Settings.Insert("UseSafeLogonToOutgoingMailServer", False);
	
	Settings.Insert("ServerTimeout", 30);
	Settings.Insert("KeepEmailCopiesOnServer", False);
	Settings.Insert("DeleteEmailsFromServerAfter", 10);
	
	Return Settings;
EndFunction

&AtServer
Function TestConnectionToIncomingMailServer()
	
	Profile = InternetMailProfile(True);
	InternetMail = New InternetMail;
	
	ProtocolToUse = InternetMailProtocol.POP3;	If Protocol = "IMAP" Then
		ProtocolToUse = InternetMailProtocol.IMAP;
	EndIf;
	
	ErrorText = "";
	Try
		InternetMail.Logon(Profile, ProtocolToUse);
		InternetMail.GetHeaders();
	Except
		ErrorText = BriefErrorDescription(ErrorInfo());
	EndTry;
	
	InternetMail.Logoff();
	
	Return ErrorText;
	
EndFunction

&AtServer
Function TestConnectionToOutgoingMailServer()
	
	EmailParameters = New Structure;
	
	Subject = NStr("en = 'Test message from 1C:Enterprise'");
	Body = NStr("en = 'This message is sent via 1C:Enterprise email subsystem'");
	
	CurEmail = New InternetMailMessage;
	CurEmail.Subject = Subject;
	
	Recipient = CurEmail.To.Add(EmailAddress);
	Recipient.DisplayName = EmailSenderName;
	
	CurEmail.SenderName = EmailSenderName;
	CurEmail.From.DisplayName = EmailSenderName;
	CurEmail.From.Address = EmailAddress;
	
	Text = CurEmail.Texts.Add(Body);
	Text.TextType = InternetMailTextType.PlainText;

	Profile = InternetMailProfile();
	InternetMail = New InternetMail;
	
	ErrorText = "";
	Try
		InternetMail.Logon(Profile);
		InternetMail.Send(CurEmail);
	Except
		ErrorText = BriefErrorDescription(ErrorInfo());
	EndTry;
	
	InternetMail.Logoff();
	
	Return ErrorText;
	
EndFunction

&AtServer
Procedure ValidateAccountSettings()
	
	CheckingCompletedWithErrors = False;
	
	IncomingMailServerMessage = "";
	If UseForReceiving Then
		IncomingMailServerMessage = TestConnectionToIncomingMailServer();
	EndIf;
	
	OutgoingMailServerMessage = "";
	If UseForSending Then
		OutgoingMailServerMessage = TestConnectionToOutgoingMailServer();
	EndIf;
	
	If Not IsBlankString(OutgoingMailServerMessage) Then
		ErrorText = NStr("en = 'Cannot connect to the outgoing email server:'" + Chars.LF)			+ OutgoingMailServerMessage + Chars.LF;
	EndIf;
	
	If Not IsBlankString(IncomingMailServerMessage) Then
		ErrorText = ErrorText
			+ NStr("en = 'Cannot connect to the incoming email server:'" + Chars.LF)
			+ IncomingMailServerMessage;
	EndIf;
	
	ErrorMessages = TrimAll(ErrorText);
			
	If Not IsBlankString(ErrorText) Then
		CheckingCompletedWithErrors = True;
	Else
		CreateAccount();
	EndIf;
	
EndProcedure

&AtServer
Procedure CreateAccount()
	If ContextMode And IsBlankString(CommonUse.ObjectAttributeValue(Catalogs.EmailAccounts.SystemEmailAccount, "EmailAddress")) Then
		Account = Catalogs.EmailAccounts.SystemEmailAccount.GetObject();
	Else
		Account = Catalogs.EmailAccounts.CreateItem();
		Account.SetNewObjectRef(NewAccountRef);
	EndIf;
	FillPropertyValues(Account, ThisObject);
	Account.UserName = EmailSenderName;
	Account.User = UserNameForReceivingEmails;
	Account.Password = PasswordForReceivingEmails;
	Account.SMTPUser = UserNameForSendingEmails;
	Account.SMTPPassword = PasswordForSendingEmails;
	Account.Timeout = ServerTimeout;
	Account.KeepMessageCopiesAtServer = KeepEmailCopiesOnServer;
	Account.KeepMessagesOnServerPeriod = DeleteEmailsFromServerAfter;
	Account.ProtocolForIncomingMail = Protocol;
	Account.Description = AccountName;
	Account.Write();
	AccountRef = Account.Ref;
	FormClosingConfirmationRequired = False;
EndProcedure

&AtServer
Function InternetMailProfile(ForReceiving = False)
	
	Profile = New InternetMailProfile;
	If ForReceiving Or LogonBeforeSending Then
		If Protocol = "IMAP" Then
			Profile.IMAPServerAddress = IncomingMailServer;
			Profile.IMAPUseSSL = UseSecureConnectionForIncomingMail;
			Profile.IMAPPassword = PasswordForReceivingEmails;
			Profile.IMAPUser = UserNameForReceivingEmails;
			Profile.IMAPPort = IncomingMailServerPort;
			Profile.IMAPSecureAuthenticationOnly = UseSafeLogonToIncomingMailServer;
		Else
			Profile.POP3ServerAddress = IncomingMailServer;
			Profile.POP3UseSSL = UseSecureConnectionForIncomingMail;
			Profile.Password = PasswordForReceivingEmails;
			Profile.User = UserNameForReceivingEmails;
			Profile.POP3Port = IncomingMailServerPort;
			Profile.POP3SecureAuthenticationOnly = UseSafeLogonToIncomingMailServer;
		EndIf;
	EndIf;
	
	If Not ForReceiving Then
		Profile.POP3BeforeSMTP = LogonBeforeSending;
		Profile.SMTPServerAddress = OutgoingMailServer;
		Profile.SMTPUseSSL = UseSecureConnectionForOutgoingMail;
		Profile.SMTPPassword = PasswordForSendingEmails;
		Profile.SMTPUser = UserNameForSendingEmails;
		Profile.SMTPPort = OutgoingMailServerPort;
		Profile.SMTPSecureAuthenticationOnly = UseSafeLogonToOutgoingMailServer;
	EndIf;
	
	Profile.Timeout = ServerTimeout;
	
	Return Profile;
	
EndFunction

&AtServer
Function UsernameOptions()
	
	Position = Find(EmailAddress, "@");
	UserNameInAccount = Left(EmailAddress, Position - 1);
	
	Result = New Array;
	Result.Add(EmailAddress);
	Result.Add(UserNameInAccount);
	
	Return Result;
	
EndFunction

&AtServer
Function IMAPServerConnectionSettingsOptions()
	
	Position = Find(EmailAddress, "@");
	UserNameInAccount = Left(EmailAddress, Position - 1);
	ServerNameInAccount = Mid(EmailAddress, Position + 1);
	
	Result = New ValueTable;
	Result.Columns.Add("IncomingMailServer");
	Result.Columns.Add("IncomingMailServerPort");
	Result.Columns.Add("UseSecureConnectionForIncomingMail");
	
	// Standard settings suitable for popular email services, such as Gmail.
	// Server name with the "imap." prefix, secure connection
	SettingsMode = Result.Add();
	SettingsMode.IncomingMailServer = "imap." + ServerNameInAccount;
	SettingsMode.IncomingMailServerPort = 993;
	SettingsMode.UseSecureConnectionForIncomingMail = True;
	
	// Server name with the "mail." prefix, secure connection
	SettingsMode = Result.Add();
	SettingsMode.IncomingMailServer = "mail." + ServerNameInAccount;
	SettingsMode.IncomingMailServerPort = 993;
	SettingsMode.UseSecureConnectionForIncomingMail = True;
	
	// Server name without the "imap." prefix, secure connection
	SettingsMode = Result.Add();
	SettingsMode.IncomingMailServer = ServerNameInAccount;
	SettingsMode.IncomingMailServerPort = 993;
	SettingsMode.UseSecureConnectionForIncomingMail = True;
	
	// Server name with the "imap." prefix, insecure connection
	SettingsMode = Result.Add();
	SettingsMode.IncomingMailServer = "imap." + ServerNameInAccount;
	SettingsMode.IncomingMailServerPort = 143;
	SettingsMode.UseSecureConnectionForIncomingMail = False;
	
	// server name with the "mail." prefix, insecure connection
	SettingsMode = Result.Add();
	SettingsMode.IncomingMailServer = "mail." + ServerNameInAccount;
	SettingsMode.IncomingMailServerPort = 143;
	SettingsMode.UseSecureConnectionForIncomingMail = False;
	
	// server name without the "imap." prefix, insecure connection
	SettingsMode = Result.Add();
	SettingsMode.IncomingMailServer = ServerNameInAccount;
	SettingsMode.IncomingMailServerPort = 143;
	SettingsMode.UseSecureConnectionForIncomingMail = False;
	
	Return Result;
	
EndFunction

&AtServer
Function POPServerConnectionSettingsOptions()
	
	Position = Find(EmailAddress, "@");
	ServerNameInAccount = Mid(EmailAddress, Position + 1);
	
	Result = New ValueTable;
	Result.Columns.Add("IncomingMailServer");
	Result.Columns.Add("IncomingMailServerPort");
	Result.Columns.Add("UseSecureConnectionForIncomingMail");
	
	// Standard settings suitable for popular email services, such as Gmail. 
	// Server name with the "pop." prefix, secure connection
	SettingsMode = Result.Add();
	SettingsMode.IncomingMailServer = "pop." + ServerNameInAccount;
	SettingsMode.IncomingMailServerPort = 995;
	SettingsMode.UseSecureConnectionForIncomingMail = True;
	
	// Server name with the "pop3." prefix, secure connection
	SettingsMode = Result.Add();
	SettingsMode.IncomingMailServer = "pop3." + ServerNameInAccount;
	SettingsMode.IncomingMailServerPort = 995;
	SettingsMode.UseSecureConnectionForIncomingMail = True;
	
	// Server name with the "mail." prefix, secure connection
	SettingsMode = Result.Add();
	SettingsMode.IncomingMailServer = "mail." + ServerNameInAccount;
	SettingsMode.IncomingMailServerPort = 995;
	SettingsMode.UseSecureConnectionForIncomingMail = True;
	
	// Server name without prefixes, secure connection
	SettingsMode = Result.Add();
	SettingsMode.IncomingMailServer = ServerNameInAccount;
	SettingsMode.IncomingMailServerPort = 995;
	SettingsMode.UseSecureConnectionForIncomingMail = True;
	
	// Server name with the "pop." prefix, insecure connection
	SettingsMode = Result.Add();
	SettingsMode.IncomingMailServer = "pop." + ServerNameInAccount;
	SettingsMode.IncomingMailServerPort = 110;
	SettingsMode.UseSecureConnectionForIncomingMail = False;
	
	// Server name with the "pop3." prefix, insecure connection
	SettingsMode = Result.Add();
	SettingsMode.IncomingMailServer = "pop3." + ServerNameInAccount;
	SettingsMode.IncomingMailServerPort = 110;
	SettingsMode.UseSecureConnectionForIncomingMail = False;
	
	// Server name with the "mail." prefix, insecure connection
	SettingsMode = Result.Add();
	SettingsMode.IncomingMailServer = "mail." + ServerNameInAccount;
	SettingsMode.IncomingMailServerPort = 110;
	SettingsMode.UseSecureConnectionForIncomingMail = False;
	
	// Server name without prefixes, secure connection
	SettingsMode = Result.Add();
	SettingsMode.IncomingMailServer = ServerNameInAccount;
	SettingsMode.IncomingMailServerPort = 110;
	SettingsMode.UseSecureConnectionForIncomingMail = False;
	
	Return Result;
	
EndFunction

&AtServer
Function SMTPServerConnectionSettingsOptions()
	
	Position = Find(EmailAddress, "@");
	ServerNameInAccount = Mid(EmailAddress, Position + 1);
	
	Result = New ValueTable;
	Result.Columns.Add("OutgoingMailServer");
	Result.Columns.Add("OutgoingMailServerPort");
	Result.Columns.Add("UseSecureConnectionForOutgoingMail");
	
	// Standard settings suitable for popular email services, such as Gmail.
	// Server name with the "smtp." prefix, secure connection, port 465
		SettingsMode = Result.Add();
	SettingsMode.OutgoingMailServer = "smtp." + ServerNameInAccount;
	SettingsMode.OutgoingMailServerPort = 465;
	SettingsMode.UseSecureConnectionForOutgoingMail = True;
	
	// Server name with the "mail." prefix, secure connection, port 465
	SettingsMode = Result.Add();
	SettingsMode.OutgoingMailServer = "mail." + ServerNameInAccount;
	SettingsMode.OutgoingMailServerPort = 465;
	SettingsMode.UseSecureConnectionForOutgoingMail = True;
	
	// Server name without prefixes, secure connection, port 465
	SettingsMode = Result.Add();
	SettingsMode.OutgoingMailServer = ServerNameInAccount;
	SettingsMode.OutgoingMailServerPort = 465;
	SettingsMode.UseSecureConnectionForOutgoingMail = True;
	
	// Server name with the "smtp." prefix, secure connection, port 587
	SettingsMode = Result.Add();
	SettingsMode.OutgoingMailServer = "smtp." + ServerNameInAccount;
	SettingsMode.OutgoingMailServerPort = 587;
	SettingsMode.UseSecureConnectionForOutgoingMail = True;
	
	// Server name with the "mail." prefix, secure connection, port 587
	SettingsMode = Result.Add();
	SettingsMode.OutgoingMailServer = "mail." + ServerNameInAccount;
	SettingsMode.OutgoingMailServerPort = 587;
	SettingsMode.UseSecureConnectionForOutgoingMail = True;
	
	// Server name without prefixes, secure connection, port 587
	SettingsMode = Result.Add();
	SettingsMode.OutgoingMailServer = ServerNameInAccount;
	SettingsMode.OutgoingMailServerPort = 587;
	SettingsMode.UseSecureConnectionForOutgoingMail = True;
	
	// Server name with the "smtp." prefix, insecure connection
	SettingsMode = Result.Add();
	SettingsMode.OutgoingMailServer = "smtp." + ServerNameInAccount;
	SettingsMode.OutgoingMailServerPort = 25;
	SettingsMode.UseSecureConnectionForOutgoingMail = False;
	
	// Server name with the "mail." prefix, insecure connection
	SettingsMode = Result.Add();
	SettingsMode.OutgoingMailServer = "mail." + ServerNameInAccount;
	SettingsMode.OutgoingMailServerPort = 25;
	SettingsMode.UseSecureConnectionForOutgoingMail = False;
	
	// Server name without prefixes, insecure connection
	SettingsMode = Result.Add();
	SettingsMode.OutgoingMailServer = ServerNameInAccount;
	SettingsMode.OutgoingMailServerPort = 25;
	SettingsMode.UseSecureConnectionForOutgoingMail = False;
	
	Return Result;
	
EndFunction

&AtServer
Function PickAccountSettings()
	
	FoundIncomingMailServerSettings = False;
	FoundOutgoingMailServerSettings = False;
	
	FillPropertyValues(ThisObject, DefaultSettings(EmailAddress, PasswordForReceivingEmails));
	
	If UseForReceiving Then
		Connected = False;
		AuthenticationError = False;
		ConnectionSettingsOption = Undefined;
		
		// Searching for IMAP settings
		Protocol = "IMAP";
		For Each UserName In UsernameOptions() Do
			UserNameForReceivingEmails = UserName;
			If AuthenticationError Then
				ErrorMessage = TestConnectionToIncomingMailServer();
				Connected = IsBlankString(ErrorMessage);
			Else
				For Each ConnectionSettingsOption In IMAPServerConnectionSettingsOptions() Do
					FillPropertyValues(ThisObject, ConnectionSettingsOption);
					ErrorMessage = TestConnectionToIncomingMailServer();
					Connected = IsBlankString(ErrorMessage);
					AuthenticationError = Find(ErrorMessage, "authenticat") > 0;
					If Connected Or AuthenticationError Then
						Break;
					EndIf;
				EndDo;
			EndIf;
			If Connected Or Not AuthenticationError Then
				Break;
			EndIf;
		EndDo;
		
		FoundIncomingMailServerSettings = Connected;
		
		If Not FoundIncomingMailServerSettings Then
			// Searching for POP settings
			Connected = False;
			AuthenticationError = False;
			ConnectionSettingsOption = Undefined;
			
			Protocol = "POP";
			For Each UserName In UsernameOptions() Do
				UserNameForReceivingEmails = UserName;
				If AuthenticationError Then
					ErrorMessage = TestConnectionToIncomingMailServer();
					Connected = IsBlankString(ErrorMessage);
				Else
					For Each ConnectionSettingsOption In POPServerConnectionSettingsOptions() Do
						FillPropertyValues(ThisObject, ConnectionSettingsOption);
						ErrorMessage = TestConnectionToIncomingMailServer();
						Connected = IsBlankString(ErrorMessage);
						AuthenticationError = Find(ErrorMessage, "authenticat") > 0;
						If Connected Or AuthenticationError Then
							Break;
						EndIf;
					EndDo;
				EndIf;
				If Connected Or Not AuthenticationError Then
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	If UseForSending Then
		// Searching for SMTP settings
		Connected = False;
		AuthenticationError = False;
		ConnectionSettingsOption = Undefined;
		
		For Each UserName In UsernameOptions() Do
			UserNameForSendingEmails = UserName;
			If AuthenticationError Then
				ErrorMessage = TestConnectionToOutgoingMailServer();
				Connected = IsBlankString(ErrorMessage);
			Else
				For Each ConnectionSettingsOption In SMTPServerConnectionSettingsOptions() Do
					FillPropertyValues(ThisObject, ConnectionSettingsOption);
					ErrorMessage = TestConnectionToOutgoingMailServer();
					Connected = IsBlankString(ErrorMessage);
					AuthenticationError = Find(ErrorMessage, "authenticat") > 0;
					If Connected Or AuthenticationError Then
						Break;
					EndIf;
				EndDo;
			EndIf;
			If Connected Or Not AuthenticationError Then
				Break;
			EndIf;
		EndDo;
		
		FoundOutgoingMailServerSettings = Connected ;
	EndIf;
	
	Return (Not UseForSending Or FoundOutgoingMailServerSettings)
		And (Not UseForReceiving Or FoundIncomingMailServerSettings);
	
EndFunction

&AtClient
Procedure SetUpConnectionParametersAutomatically()
	PickSettingsAndCreateAccount();
	
	If ValueIsFilled(AccountRef) Then 
		NotifyChanged(TypeOf(AccountRef));
	EndIf;
	
	GotoNextPage();
EndProcedure

&AtServer

Procedure PickSettingsAndCreateAccount()
	CheckingCompletedWithErrors = Not PickAccountSettings();
	If Not CheckingCompletedWithErrors Then
		CreateAccount();
	Else
		ErrorMessages = NStr("en = 'Cannot determine connection settings automatically. 
			|Configure the connection parameters manually.'");
			
		// Applying default settings
		FillPropertyValues(ThisObject, DefaultSettings(EmailAddress, PasswordForReceivingEmails));
	EndIf;
EndProcedure

#EndRegion