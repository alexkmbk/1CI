
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
 
// Skipping the initialization to guarantee that the form will be received if the Autotest parameter is passed.	
	If Parameters.Property("Autotest") Then 
		Return;
	EndIf;
	
	UseExternalUsers = GetFunctionalOption("UseExternalUsers");
	CopySettingsToRadioButton = "ToSelectedUsers";
	SettingsToCopyRadioButton = "CopyAll";
	FormOpeningMode = Parameters.FormOpeningMode;
	
	SettingsRecipientUsers = New Structure;
	If Parameters.User <> Undefined Then
		UserArray = New Array;
		UserArray.Add(Parameters.User);
		SettingsRecipientUsers.Insert("UserArray", UserArray);
		Items.ChooseUsers.Title = String(Parameters.User);
		UserCount = 1;
		PassedUserType = TypeOf(Parameters.User);
		Items.CopyToGroup.Enabled = False;
	Else
		UserRef = Users.CurrentUser();
	EndIf;
	
	If UserRef = Undefined Then
		Items.SettingsToCopyGroup.Enabled = False;
	EndIf;
	
	ClearSettingsSelectionHistory = True;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Upper(EventName) = Upper("UserSelection") Then
		SettingsRecipientUsers = New Structure("UserArray", Parameter.UsersTarget);
		
		UserCount = Parameter.UsersTarget.Count();
		If UserCount = 1 Then
			Items.ChooseUsers.Title = String(Parameter.UsersTarget[0]);
		ElsIf UserCount > 1 Then

    Raise("CHECK ON TEST");
			NumberInWords = NumberInWords(
				UserCount,
				"L=en_US",
				NStr("en = ',,,,0'"));
    Raise("CHECK ON TEST");

			SubjectAndNumberInWords = NumberInWords(
				UserCount,
				"L=en_US",
				NStr("en = 'user,users,,,0'"));
			NumberAndSubject = StrReplace(
				SubjectAndNumberInWords,
				NumberInWords,
				Format(UserCount, "NFD=0") + " ");
				
			Items.ChooseUsers.Title = NumberAndSubject;
		EndIf;
		Items.ChooseUsers.ToolTip = "";
		
	ElsIf Upper(EventName) = Upper("SelectSettings") Then
		
		SelectedSettings = New Structure;
		SelectedSettings.Insert("ReportSettings", Parameter.ReportSettings);
		SelectedSettings.Insert("Appearance", Parameter.Appearance);
		SelectedSettings.Insert("OtherSettings", Parameter.OtherSettings);
		SelectedSettings.Insert("PersonalSettings", Parameter.PersonalSettings);
		SelectedSettings.Insert("ReportOptionTable", Parameter.ReportOptionTable);
		SelectedSettings.Insert("SelectedReportOptions", Parameter.SelectedReportOptions);
		SelectedSettings.Insert("OtherUserSettings",
			Parameter.OtherUserSettings);
		
		SettingsCount = Parameter.SettingsCount;
		
		If SettingsCount = 0 Then
			TitleText = NStr("en='Select'");
		ElsIf SettingsCount = 1 Then
			SettingsItemPresentation = Parameter.SettingsPresentation[0];
			TitleText = SettingsItemPresentation;
		Else
 Raise("CHECK ON TEST");
			NumberInWords = NumberInWords(
				SettingsCount,
				"L=en_US",
				NStr("en = ',,,,0'"));
 Raise("CHECK ON TEST");
			SubjectAndNumberInWords = NumberInWords(
				SettingsCount,
				"L=en_US",
				NStr("en = settings item,settings items,,,0'"));
			TitleText = StrReplace(
				SubjectAndNumberInWords,
				NumberInWords,
				Format(SettingsCount, "NFD=0") + " ");
		EndIf;
		
		Items.SelectSettings.Title = TitleText;
		Items.SelectSettings.ToolTip = "";
		
	ElsIf Upper(EventName) = Upper("CopySettingsToActiveUsers") Then
		
		CopySettings(Parameter.Action);
		
	ElsIf Upper(EventName) = Upper("SelectSettings_DataSaved") Then
		ClearSettingsSelectionHistory = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemEventHandlers

&AtClient
Procedure UserStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	SelectedUserType  = Undefined;
	
	If UserCount <> 0 Then
		UsersToHide = New ValueList;
		UsersToHide.LoadValues(SettingsRecipientUsers.UserArray);
	EndIf;
	
	FilterParameters = New Structure(
		"HideUsersWithNoMatchingInfobaseUser, ChoiceMode, UsersToHide",
		True, True, UsersToHide);
	
	If PassedUserType = Undefined Then
		
		If UseExternalUsers Then
			UserTypeSelection = New ValueList;
			UserTypeSelection.Add("ExternalUsers", NStr("en = 'External users'"));
			UserTypeSelection.Add("Users", NStr("en = 'Users'"));
			
			Notification = New NotifyDescription("UserStartChoiceCompletion", ThisObject, FilterParameters);
			UserTypeSelection.ShowChooseItem(Notification);
			Return;
		Else
			SelectedUserType  = "Users";
		EndIf;
		
	EndIf;
	
	OpenUserSelectionForm(SelectedUserType , FilterParameters);
	
EndProcedure

&AtClient
Procedure UserStartChoiceCompletion(SelectedOption, FilterParameters) Export
	
	If SelectedOption = Undefined Then
		Return;
	EndIf;
	SelectedUserType  = SelectedOption.Value;
	
	OpenUserSelectionForm(SelectedUserType , FilterParameters);
	
EndProcedure

&AtClient
Procedure OpenUserSelectionForm(SelectedUserType , FilterParameters)
	
	If SelectedUserType  = "Users"
		OR PassedUserType = Type("CatalogRef.Users") Then
		OpenForm("Catalog.Users.Form.ListForm", FilterParameters, Items.UserRef);
	ElsIf SelectedUserType  = "ExternalUsers"
		OR PassedUserType = Type("CatalogRef.ExternalUsers") Then
		OpenForm("Catalog.ExternalUsers.Form.ListForm", FilterParameters, Items.UserRef);
	EndIf;
	UserRefOld = UserRef;
	
EndProcedure

&AtClient
Procedure UserRefOnChange(Item)
	
	If UserRef <> Undefined
		And SettingsRecipientUsers.Property("UserArray") Then
		
		For Each UserTarget In SettingsRecipientUsers.UserArray Do
		
			If UserRef = UserTarget Then
				ShowMessageBox(,NStr("en = 'Cannot copy user settings to themselves. Select another user.'"));
				UserRef = UserRefOld;
				Return;
			EndIf;
		
		EndDo;
		
	EndIf;
	
	Items.SettingsToCopyGroup.Enabled = UserRef <> Undefined;
	
	SelectedSettings = Undefined;
	SettingsCount = 0;
	Items.SelectSettings.Title = NStr("en='Select'");
	
EndProcedure

&AtClient
Procedure SelectSettings(Item)
	
	FormParameters = New Structure("User, ActionWithSettings, ClearSettingsSelectionHistory",
		UserRef, "Clone", ClearSettingsSelectionHistory);
	OpenForm("DataProcessor.ApplicationUserSettings.Form.SelectSettings", FormParameters);
	
EndProcedure

&AtClient
Procedure ChooseUsers(Item)
	
	UserType = TypeOf(UserRef);
	
	SelectedUsers = Undefined;
	SettingsRecipientUsers.Property("UserArray", SelectedUsers);
	
	FormParameters = New Structure("User, UserType, ActionType, SelectedUsers",
		UserRef, UserType, "Clone", SelectedUsers);
	OpenForm("DataProcessor.ApplicationUserSettings.Form.UsersSelection", FormParameters);
	
EndProcedure

&AtClient
Procedure CopySettingsToRadioButtonOnChange(Item)
	
	If CopySettingsToRadioButton = "ToSelectedUsers" Then
		Items.ChooseUsers.Enabled = True;
	Else
		Items.ChooseUsers.Enabled = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure SettingsToCopyRadioButtonOnChange(Item)
	
	If SettingsToCopyRadioButton = "CopyCertain" Then
		Items.SelectSettings.Enabled = True;
	Else
		Items.SelectSettings.Enabled = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Copy(Command)
	
	ClearMessages();
	
	If UserRef = Undefined Then
		CommonUseClientServer.MessageToUser(
			NStr("en = 'Select user whose settings you want to copy.'"), , "UserRef");
		Return;
	EndIf;
	
	If UserCount = 0 And CopySettingsToRadioButton <> "AllUsers" Then
		CommonUseClientServer.MessageToUser(
			NStr("en = 'Select one or several users to which you want to copy the settings.'"), , "Target");
		Return;
	EndIf;
	
	If SettingsToCopyRadioButton = "CopyCertain" And SettingsCount = 0 Then
		CommonUseClientServer.MessageToUser(
			NStr("en = 'Select settings to copy'"), , "SettingsToCopyRadioButton");
		Return;
	EndIf;
	
	// If appearance settings are copied or all settings are copied, check whether they are applicable to the target user and display the result (a message that settings are copied or a message explaining why they are not copied).
	CheckActiveUsers();
	If CheckResult = "HasActiveUsersRecipients" Then
		
		If SettingsToCopyRadioButton = "CopyAll" 
			OR (SettingsToCopyRadioButton = "CopyCertain"
			And SelectedSettings.Appearance.Count() <> 0) Then
			
			FormParameters = New Structure("Action", Command.Name);
			OpenForm("DataProcessor.ApplicationUserSettings.Form.SettingsCopyingWarning", FormParameters);
			Return;
			
		EndIf;
		
	EndIf;
	
	CopySettings(Command.Name);
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtClient
Procedure CopySettings(CommandName)
	
	Status(NStr("en = 'Сopying settings...'"));
	
	If CopySettingsToRadioButton = "ToSelectedUsers" Then
		
		ExplanationSettingsCopiedTo = UsersInternalClient.UsersExplanation(
			UserCount, SettingsRecipientUsers.UserArray[0]);
		
	Else
		ExplanationSettingsCopiedTo = NStr("en = 'all users'");
	EndIf;
	
	If SettingsToCopyRadioButton = "CopyCertain" Then
		
		Report = Undefined;
		CopySelectedSettings(Report);
		
		If Report <> Undefined Then
			QuestionText = NStr("en = 'Some report options and settings are not copied.'");
			QuestionButtons = New ValueList;
			QuestionButtons.Add("OK", NStr("en='OK'"));
			QuestionButtons.Add("ShowReport", NStr("en='View report'"));
			
			Notification = New NotifyDescription("CopySettingsShowQueryBox", ThisObject, Report);
			ShowQueryBox(Notification, QuestionText, QuestionButtons,, QuestionButtons[0].Value);
			Return;
		EndIf;
			
		If Report = Undefined Then
			
			ExplanationText = UsersInternalClient.ExplanationOnCopy(
				SettingsItemPresentation, SettingsCount, ExplanationSettingsCopiedTo);
			ShowUserNotification(NStr("en = 'Сopying settings...'"), , ExplanationText, PictureLib.Information32);
			
		EndIf;
		
	Else
		
		SettingsCopied  = CopyingAllSettings();
		If Not SettingsCopied  Then
			
			WarningText = NStr("en = 'Settings are not copied because user ""%1"" does not have any saved settings.'");
			WarningText = StringFunctionsClientServer.
				SubstituteParametersInString(WarningText, String(UserRef));
			ShowMessageBox(,WarningText);
			
			Return;
		EndIf;
			
		ExplanationText = NStr("en = 'All settings are copied to %1'");
		ExplanationText = StringFunctionsClientServer.SubstituteParametersInString(
			ExplanationText, ExplanationSettingsCopiedTo);
		ShowUserNotification(
			NStr("en = 'Сopying settings...'"), , ExplanationText, PictureLib.Information32);
	EndIf;
	
	// If this is copying settings from another user, notifying the ApplicationUserSettings form
	If FormOpeningMode = "CopyFrom" Then
		CommonUseClient.RefreshApplicationInterface();
		Notify("SettingsCopied ", True);
	EndIf;
	
	If CommandName = "CopyAndClose" Then
		Close();
	EndIf;
	
	Return;
	
EndProcedure

&AtClient
Procedure CopySettingsShowQueryBox(Answer, Report)
	
	If Answer = "OK" Then
		Return;
	Else
		Report.ShowGroups = True;
		Report.ShowGrid = False;
		Report.ShowHeaders = False;
		Report.Show();
		Return;
	EndIf;
	
EndProcedure

&AtServer
Procedure CopySelectedSettings(Report)
	
	User = DataProcessors.ApplicationUserSettings.InfobaseUserName(UserRef);
	
	If CopySettingsToRadioButton = "ToSelectedUsers" Then
		Targets = SettingsRecipientUsers.UserArray;
	ElsIf CopySettingsToRadioButton = "AllUsers" Then
		Targets = New Array;
		UserTable = New ValueTable;
		UserTable.Columns.Add("User");
		DataProcessors.ApplicationUserSettings.UsersToCopy(UserRef, UserTable,
			TypeOf(UserRef) = Type("CatalogRef.ExternalUsers"));
		
		For Each TableRow In UserTable Do
			Targets.Add(TableRow.User);
		EndDo;
		
	EndIf;
	
	NotCopiedReportSettings = New ValueTable;
	NotCopiedReportSettings.Columns.Add("User");
	NotCopiedReportSettings.Columns.Add("ReportList", New TypeDescription("ValueList"));
	
	If SelectedSettings.ReportSettings.Count() > 0 Then
		
		DataProcessors.ApplicationUserSettings.CopyReportAndPersonalSettings(ReportsUserSettingsStorage,
			User, Targets, SelectedSettings.ReportSettings, NotCopiedReportSettings);
		
		DataProcessors.ApplicationUserSettings.CopyReportOptions(
			SelectedSettings.SelectedReportOptions, SelectedSettings.ReportOptionTable, User, Targets);
	EndIf;
		
	If SelectedSettings.Appearance.Count() > 0 Then
		DataProcessors.ApplicationUserSettings.CopyAppearanceSettings(User, Targets, SelectedSettings.Appearance);
	EndIf;
	
	If SelectedSettings.OtherSettings.Count() > 0 Then
		DataProcessors.ApplicationUserSettings.CopyAppearanceSettings(User, Targets, SelectedSettings.OtherSettings);
	EndIf;
	
	If SelectedSettings.PersonalSettings.Count() > 0 Then
		DataProcessors.ApplicationUserSettings.CopyReportAndPersonalSettings(CommonSettingsStorage,
			User, Targets, SelectedSettings.PersonalSettings);
	EndIf;
		
	If SelectedSettings.OtherUserSettings.Count() > 0 Then
		
		For Each CatalogUser In Targets Do
			UserInfo = New Structure;
			UserInfo.Insert("UserRef", CatalogUser);
			UserInfo.Insert("InfobaseUserName", 
				DataProcessors.ApplicationUserSettings.InfobaseUserName(CatalogUser));
			UsersInternal.OnSaveOtherSetings(
				UserInfo, SelectedSettings.OtherUserSettings);
		EndDo;
		
	EndIf;
		
	If NotCopiedReportSettings.Count() <> 0 Then
		Report = DataProcessors.ApplicationUserSettings.CreateReportOnCopyingSettings(
			NotCopiedReportSettings);
	EndIf;
	
EndProcedure

&AtServer
Function CopyingAllSettings()
	
	User = DataProcessors.ApplicationUserSettings.InfobaseUserName(UserRef);
	
	If CopySettingsToRadioButton = "ToSelectedUsers" Then
		Targets = SettingsRecipientUsers.UserArray;
	Else
		Targets = New Array;
		UserTable = New ValueTable;
		UserTable.Columns.Add("User");
		UserTable = DataProcessors.ApplicationUserSettings.UsersToCopy(UserRef, UserTable, 
			TypeOf(UserRef) = Type("CatalogRef.ExternalUsers"));
		
		For Each TableRow In UserTable Do
			Targets.Add(TableRow.User);
		EndDo;
		
	EndIf;
	
	SettingsToCopy = New Array;
	SettingsToCopy.Add("ReportSettings");
	SettingsToCopy.Add("AppearanceSettings");
	SettingsToCopy.Add("PersonalSettings");
	SettingsToCopy.Add("Favorites");
	SettingsToCopy.Add("PrintSettings");
	SettingsToCopy.Add("OtherUserSettings");
	
	SettingsCopied  = DataProcessors.ApplicationUserSettings.
		CopyAppUserSettings(UserRef, Targets, SettingsToCopy);
		
	Return SettingsCopied ;
	
EndFunction

&AtServer
Procedure CheckActiveUsers()
	
	If SettingsRecipientUsers.Property("UserArray") Then
		UserArray = SettingsRecipientUsers.UserArray;
	EndIf;
	
	If CopySettingsToRadioButton = "AllUsers" Then
		
		UserArray = New Array;
		UserTable = New ValueTable;
		UserTable.Columns.Add("User");
		UserTable = DataProcessors.ApplicationUserSettings.UsersToCopy(UserRef, UserTable, 
			TypeOf(UserRef) = Type("CatalogRef.ExternalUsers"));
		
		For Each TableRow In UserTable Do
			UserArray.Add(TableRow.User);
		EndDo;
		
	EndIf;
	
	If UserArray.Count() = 1 
		And UserArray[0] = Users.CurrentUser() Then
		
		CheckResult = "CurrentUserRecipient";
		Return;
		
	EndIf;
		
	HasActiveUsersRecipients = False;
	Sessions = GetInfobaseSessions();
	For Each Recipient In UserArray Do
		If Recipient = Users.CurrentUser() Then
			CheckResult = "CurrentUserAmongRecipients";
			Return;
		EndIf;
		For Each Session In Sessions Do
			If Recipient.InfobaseUserID = Session.User.UUID Then
				HasActiveUsersRecipients = True;
			EndIf;
		EndDo;
	EndDo;
	
	CheckResult = ?(HasActiveUsersRecipients, "HasActiveUsersRecipients", "");
	
EndProcedure

#EndRegion
