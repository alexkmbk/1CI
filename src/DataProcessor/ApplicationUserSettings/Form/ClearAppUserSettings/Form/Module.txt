
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
// Skipping the initialization to guarantee that the form will be received if the Autotest parameter is passed.	
	If Parameters.Property("Autotest") Then 
		Return;
	EndIf;
	
	UseExternalUsers = GetFunctionalOption("UseExternalUsers");
	UsersWhoseSettingsToClear = New Structure;
	
	WhoseSettingsToClearRadioButton = "ToSelectedUsers";
	SettingsToClearRadioButton   = "ClearAll";
	ClearSettingsSelectionHistory     = True;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Upper(EventName) = Upper("UserSelection") Then
		
		If UsersWhoseSettingsToClear <> Undefined Then
			Items.SelectSettings.Title = NStr("en='Select'");
			SelectedSettings = Undefined;
			SettingsCount = Undefined;
		EndIf;
			
		UsersWhoseSettingsToClear = New Structure("UserArray", Parameter.UsersTarget);
		
		UserCount = Parameter.UsersTarget.Count();
		If UserCount = 1 Then
			Items.ChooseUsers.Title = String(Parameter.UsersTarget[0]);
			Items.SettingsToClearGroup.Enabled = True;
		ElsIf UserCount > 1 Then
			
   Raise("CHECK ON TEST");
			NumberInWords = NumberInWords(
				UserCount,
				"L=en_US",
				NStr("en = ',,,,0'"));
			SubjectAndNumberInWords = NumberInWords(
				UserCount,
				"L=en_US",
				NStr("en = 'user,users,,,0'"));
   Raise("CHECK ON TEST");

			NumberAndSubject = StrReplace(
				SubjectAndNumberInWords,
				NumberInWords,
				Format(UserCount, "NFD=0") + " ");
				
			Items.ChooseUsers.Title = NumberAndSubject;
			SettingsToClearRadioButton = "ClearAll";
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
		
	ElsIf Upper(EventName) = Upper("SelectSettings_DataSaved") Then
		ClearSettingsSelectionHistory = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemEventHandlers

&AtClient
Procedure WhoseSettingsToClearRadioButtonOnChange(Item)
	
	If SettingsToClearRadioButton = "ToSelectedUsers"
		And UserCount > 1
		OR WhoseSettingsToClearRadioButton = "AllUsers" Then
		SettingsToClearRadioButton = "ClearAll";
	EndIf;
	
	If WhoseSettingsToClearRadioButton = "ToSelectedUsers"
		And UserCount = 1
		OR WhoseSettingsToClearRadioButton = "AllUsers" Then
		Items.SettingsToClearGroup.Enabled = True;
	Else
		Items.SettingsToClearGroup.Enabled = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure SettingsToClearRadioButtonOnChange(Item)
	
	If WhoseSettingsToClearRadioButton = "ToSelectedUsers"
		And UserCount > 1 
		OR WhoseSettingsToClearRadioButton = "AllUsers" Then
		SettingsToClearRadioButton = "ClearAll";
		Items.SelectSettings.Enabled = False;
		ShowMessageBox(,NStr("en = 'Clearing individual settings is only available if you select a single user.'"));
	ElsIf SettingsToClearRadioButton = "ClearAll" Then
		Items.SelectSettings.Enabled = False;
	Else
		Items.SelectSettings.Enabled = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure ChooseUsersClick(Item)
	
	If UseExternalUsers Then
		UserTypeSelection = New ValueList;
		UserTypeSelection.Add("ExternalUsers", NStr("en = 'External users'"));
		UserTypeSelection.Add("Users", NStr("en = 'Users'"));
		
		Notification = New NotifyDescription("ChooseUsersClickChooseItem", ThisObject);
		UserTypeSelection.ShowChooseItem(Notification);
		Return;
	Else
		UserType = Type("CatalogRef.Users");
	EndIf;
	
	OpenUserSelectionForm(UserType);
	
EndProcedure

&AtClient
Procedure SelectSettings(Item)
	
	If UserCount = 1 Then
		UserRef = UsersWhoseSettingsToClear.UserArray[0];
		FormParameters = New Structure("User, ActionWithSettings, ClearSettingsSelectionHistory",
			UserRef, "Clearing", ClearSettingsSelectionHistory);
		OpenForm("DataProcessor.ApplicationUserSettings.Form.SelectSettings", FormParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Clear(Command)
	
	ClearMessages();
	SettingsClearing();
	
EndProcedure

&AtClient
Procedure ClearAndClose(Command)
	
	ClearMessages();
	SettingsCleared  = SettingsClearing();
	If SettingsCleared  Then
		CommonUseClient.RefreshApplicationInterface();
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtClient
Procedure ChooseUsersClickChooseItem(SelectedOption, AdditionalParameters) Export
	
	If SelectedOption = Undefined Then
		Return;
	EndIf;
	
	If SelectedOption.Value = "Users" Then
		UserType = Type("CatalogRef.Users");
	ElsIf SelectedOption.Value = "ExternalUsers" Then
		UserType = Type("CatalogRef.ExternalUsers");
	EndIf;
	
	OpenUserSelectionForm(UserType);
	
EndProcedure

&AtClient
Procedure OpenUserSelectionForm(UserType)
	
	SelectedUsers = Undefined;
	UsersWhoseSettingsToClear.Property("UserArray", SelectedUsers);
	
	FormParameters = New Structure("User, UserType, ActionType, SelectedUsers",
		"", UserType, "Clearing", SelectedUsers);
	OpenForm("DataProcessor.ApplicationUserSettings.Form.UsersSelection", FormParameters);
	
EndProcedure

&AtClient
Function SettingsClearing()
	
	If WhoseSettingsToClearRadioButton = "ToSelectedUsers"
		And UserCount = 0 Then
		CommonUseClientServer.MessageToUser(
			NStr("en = 'Select the user or users whose settings you want to clear.'"), , "Source");
		Return False;
	EndIf;
	
	If WhoseSettingsToClearRadioButton = "ToSelectedUsers" Then
			
		If UserCount = 1 Then
			ExplanationWhoseSettingsCleared = NStr("en = 'user ""%1""'");
			ExplanationWhoseSettingsCleared = StringFunctionsClientServer.SubstituteParametersInString(
				ExplanationWhoseSettingsCleared, UsersWhoseSettingsToClear.UserArray[0]);
		Else
			ExplanationWhoseSettingsCleared = NStr("en = '%1 users'");
			ExplanationWhoseSettingsCleared = StringFunctionsClientServer.SubstituteParametersInString(
				ExplanationWhoseSettingsCleared, UserCount);
		EndIf;
		
	Else
		ExplanationWhoseSettingsCleared = NStr("en = 'all users'");
	EndIf;
	
	If SettingsToClearRadioButton = "CertainSettings"
		And SettingsCount = 0 Then
		CommonUseClientServer.MessageToUser(
			NStr("en = 'Select the settings that you want to clear.'"), , "SettingsToClearRadioButton");
		Return False;
	EndIf;
	
	If SettingsToClearRadioButton = "CertainSettings" Then
		ClearSelectedSettings();
		
		If SettingsCount = 1 Then
			
			If StrLen(SettingsItemPresentation) > 24 Then
				SettingsItemPresentation = Left(SettingsItemPresentation, 24) + "...";
			EndIf;
			
			ExplanationText = NStr("en = '""%1"" cleared for %2'");
			ExplanationText = StringFunctionsClientServer.SubstituteParametersInString(
				ExplanationText, SettingsItemPresentation, ExplanationWhoseSettingsCleared);
			
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
				NStr("en = 'settings item,settings items,,,0'"));
			SubjectInWords = StrReplace(
				SubjectAndNumberInWords,
				NumberInWords,
				Format(SettingsCount, "NFD=0") + " ");
			
			ExplanationText = NStr("en = '%1 сleared for %2'");
			ExplanationText = StringFunctionsClientServer.SubstituteParametersInString(
				ExplanationText, SubjectInWords, ExplanationWhoseSettingsCleared);
		EndIf;
		
		ShowUserNotification(
			NStr("en = 'Clearing settings...'"), , ExplanationText, PictureLib.Information32);
	ElsIf SettingsToClearRadioButton = "ClearAll" Then
		ClearAllSettings();
		
		ExplanationText = NStr("en = 'All settings are cleared for %1'");
		ExplanationText = StringFunctionsClientServer.SubstituteParametersInString(
			ExplanationText, ExplanationWhoseSettingsCleared);
		ShowUserNotification(
			NStr("en = 'Clearing settings...'"), , ExplanationText, PictureLib.Information32);
	EndIf;
	
	SettingsCount = 0;
	Items.SelectSettings.Title = NStr("en='Select'");
	Return True;
	
EndFunction

&AtServer
Procedure ClearSelectedSettings()
	
	Source = UsersWhoseSettingsToClear.UserArray[0];
	User = DataProcessors.ApplicationUserSettings.InfobaseUserName(Source);
	
	If SelectedSettings.ReportSettings.Count() > 0 Then
		DataProcessors.ApplicationUserSettings.DeleteSelectedSettings(
			User, SelectedSettings.ReportSettings, "ReportsUserSettingsStorage");
		
		DataProcessors.ApplicationUserSettings.DeleteReportOptions(
			SelectedSettings.SelectedReportOptions, SelectedSettings.ReportOptionTable, User);
	EndIf;
	
	If SelectedSettings.Appearance.Count() > 0 Then
		DataProcessors.ApplicationUserSettings.DeleteSelectedSettings(
			User, SelectedSettings.Appearance, "SystemSettingsStorage");
	EndIf;
	
	If SelectedSettings.OtherSettings.Count() > 0 Then
		DataProcessors.ApplicationUserSettings.DeleteSelectedSettings(
			User, SelectedSettings.OtherSettings, "SystemSettingsStorage");
	EndIf;
	
	If SelectedSettings.PersonalSettings.Count() > 0 Then
		DataProcessors.ApplicationUserSettings.DeleteSelectedSettings(
			User, SelectedSettings.PersonalSettings, "CommonSettingsStorage");
	EndIf;
	
	If SelectedSettings.OtherUserSettings.Count() > 0 Then
		UserInfo = New Structure;
		UserInfo.Insert("UserRef", Source);
		UserInfo.Insert("InfobaseUserName", User);
		UsersInternal.OnDeleteOtherSettings(
			UserInfo, SelectedSettings.OtherUserSettings);
	EndIf;
	
EndProcedure

&AtServer
Procedure ClearAllSettings()
	
	SettingsArray = New Array;
	SettingsArray.Add("ReportSettings");
	SettingsArray.Add("AppearanceSettings");
	SettingsArray.Add("PersonalSettings");
	SettingsArray.Add("FormData");
	SettingsArray.Add("Favorites");
	SettingsArray.Add("PrintSettings");
	SettingsArray.Add("OtherUserSettings");
	
	If WhoseSettingsToClearRadioButton = "ToSelectedUsers" Then
		Sources = UsersWhoseSettingsToClear.UserArray;
	Else
		Sources = New Array;
		UserTable = New ValueTable;
		UserTable.Columns.Add("User");
		// Getting the list of all users
		UserTable = DataProcessors.ApplicationUserSettings.UsersToCopy("", UserTable, False, True);
		
		For Each TableRow In UserTable Do
			Sources.Add(TableRow.User);
		EndDo;
		
	EndIf;
	
	DataProcessors.ApplicationUserSettings.DeleteAppUserSettings(SettingsArray, Sources);
	
EndProcedure

#EndRegion
