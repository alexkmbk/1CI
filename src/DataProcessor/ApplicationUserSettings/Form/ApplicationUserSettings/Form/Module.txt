
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skipping the initialization to guarantee that the form will be received if the Autotest parameter is passed.
	If Parameters.Property("Autotest") Then 
		Return;
	EndIf;
	
	CurrentUserRef = Users.CurrentUser();
	CurrentInfobaseUser = DataProcessors.ApplicationUserSettings.InfobaseUserName(CurrentUserRef);
	
	If Parameters.User <> Undefined Then
		
		InfobaseUserID = CommonUse.ObjectAttributeValue(Parameters.User, "InfobaseUserID");
		SetPrivilegedMode(True);
		IBUser = InfobaseUsers.FindByUUID(InfobaseUserID);
		SetPrivilegedMode(False);
		If IBUser = Undefined Then
			Items.ReportOrWarning.CurrentPage = Items.ShowWarning;
			Return;
		EndIf;
		
		UserRef = Parameters.User;
		Items.UserRef.Visible = False;
		Title = NStr("en = 'User settings'");
		InfobaseUser = DataProcessors.ApplicationUserSettings.InfobaseUserName(UserRef);
	Else
		UserRef = Users.CurrentUser();
		InfobaseUser = DataProcessors.ApplicationUserSettings.InfobaseUserName(UserRef);
	EndIf;
	
	UseExternalUsers = GetFunctionalOption("UseExternalUsers");
	
	PersonalSettingsFormName = CommonUse.CommonBaseFunctionalityParameters(
		).PersonalSettingsFormName;
	
	SelectedSettingsPage = Items.SettingsKinds.CurrentPage.Name;
	FillSettingsLists();
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	SearchChoiceList = Settings.Get("SearchChoiceList");
	If TypeOf(SearchChoiceList) = Type("Array") Then
		Items.Search.ChoiceList.LoadValues(SearchChoiceList);
	EndIf;
	Search = "";
	
EndProcedure

&AtServer
Procedure OnSaveDataInSettingsAtServer(Settings)
	
	Settings.Insert("SearchChoiceList", Items.Search.ChoiceList.UnloadValues());
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	NotificationProcessingParameters = New Structure("EventName, Parameter", EventName, Parameter);
	AttachIdleHandler("Attachable_ExecuteNotifyProcessing", 0.1, True);
	
EndProcedure

&AtClient
Procedure UserRefOnChange(Item)
	
	If IsBlankString(Item.SelectedText) Then
		Return;
	EndIf;
	GetUserNameAndRefresh();
	
	ExpandValueTree();
	
EndProcedure

#EndRegion

#Region FormHeaderItemEventHandlers

&AtClient
Procedure OnCurrentPageChange(Item, CurrentPage)
	
	SelectedSettingsPage = CurrentPage.Name;
	
EndProcedure

&AtClient
Procedure SearchOnChange(Item)
	
	If ValueIsFilled(Search) Then
		ChoiceList = Items.Search.ChoiceList;
		ListItem = ChoiceList.FindByValue(Search);
		If ListItem = Undefined Then
			ChoiceList.Insert(0, Search);
			If ChoiceList.Count() > 10 Then
				ChoiceList.Delete(10);
			EndIf;
		Else
			Index = ChoiceList.IndexOf(ListItem);
			If Index <> 0 Then
				ChoiceList.Move(Index, -Index);
			EndIf;
		EndIf;
		CurrentItem = Items.Search;
	EndIf;
	
	FillSettingsLists();
	ExpandValueTree();
	
EndProcedure

&AtClient
Procedure UserRefStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	FilterParameters = New Structure("HideUsersWithNoMatchingInfobaseUser, ChoiceMode", True, True);
	
	If UseExternalUsers Then
		UserTypeSelection = New ValueList;
		UserTypeSelection.Add("ExternalUsers", NStr("en = 'External users'"));
		UserTypeSelection.Add("Users", NStr("en = 'Users'"));
		
		Notification = New NotifyDescription("UserRefStartChoiceCompletion", ThisObject, FilterParameters);
		UserTypeSelection.ShowChooseItem(Notification);
	Else
		OpenForm("Catalog.Users.Form.ListForm", FilterParameters, Items.UserRef);
	EndIf;
	
EndProcedure

&AtClient
Procedure UserRefStartChoiceCompletion(SelectedOption, FilterParameters) Export
	
	If SelectedOption = Undefined Then
		Return;
	EndIf;
	
	If SelectedOption.Value = "Users" Then
		OpenForm("Catalog.Users.Form.ListForm", FilterParameters, Items.UserRef);
	ElsIf SelectedOption.Value = "ExternalUsers" Then
		OpenForm("Catalog.ExternalUsers.Form.ListForm", FilterParameters, Items.UserRef);
	EndIf;
	
EndProcedure

&AtClient
Procedure ReportAndAppearanceSettingsBeforeAddRow(Item, Cancel, Clone, Parent, Group)
	
	If Not Clone Then
		Cancel = True;
		Return;
	EndIf;
	
	CopySettings();
	
EndProcedure

&AtClient
Procedure SettingsBeforeDelete(Item, Cancel)
	
	Cancel = True;
	QuestionText = NStr("en = 'Clear the selected settings?'");
	Notification = New NotifyDescription("SettingsBeforeDeleteCompletion", ThisObject, Item);
	ShowQueryBox(Notification, QuestionText, QuestionDialogMode.YesNo,, DialogReturnCode.Yes);
	
EndProcedure

&AtClient
Procedure SettingsTreeChoice(Item, SelectedRow, Field, StandardProcessing)
	
	StandardProcessing = False;
	UsersInternalClient.OpenReportOrForm(
		CurrentItem, InfobaseUser, CurrentInfobaseUser, PersonalSettingsFormName);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Refresh(Command)
	
	FillSettingsLists();
	ExpandValueTree();
	
EndProcedure

&AtClient
Procedure CopyToOthers(Command)
	
	CopySettings();
	
EndProcedure

&AtClient
Procedure CopyAllSettings(Command)
	
	UserType = TypeOf(UserRef);
	SettingsToCopy.Clear();
	SettingsToCopy.Add("ReportSettings", NStr("en='Report settings'"));
	SettingsToCopy.Add("AppearanceSettings", NStr("en='Appearance settings'"));
	SettingsToCopy.Add("FormData", NStr("en='Form data'"));
	SettingsToCopy.Add("PersonalSettings", NStr("en='Personal settings'"));
	SettingsToCopy.Add("Favorites", NStr("en='Favorites'"));
	SettingsToCopy.Add("PrintSettings", NStr("en='Print settings'"));
	SettingsToCopy.Add(
		"OtherUserSettings", NStr("en='Additional  report and data processor settings'"));
	
	FormParameters = New Structure("User, UserType, ActionType", 
										UserRef, UserType, "CopyAll");
	OpenForm("DataProcessor.ApplicationUserSettings.Form.UsersSelection", FormParameters);
	
EndProcedure

&AtClient
Procedure CopyReportSettings(Command)
	
	UserType = TypeOf(UserRef);
	SettingsToCopy.Clear();
	SettingsToCopy.Add("ReportSettings", NStr("en='Report settings'"));
	
	FormParameters = New Structure("User, UserType, ActionType", 
										UserRef, UserType, "CopyAll");
	OpenForm("DataProcessor.ApplicationUserSettings.Form.UsersSelection", FormParameters);
	
EndProcedure

&AtClient
Procedure CopyAppearanceSettings(Command)
	
	UserType = TypeOf(UserRef);
	SettingsToCopy.Clear();
	SettingsToCopy.Add("AppearanceSettings", NStr("en='Appearance settings'"));
	
	FormParameters = New Structure("User, UserType, ActionType", 
										UserRef, UserType, "CopyAll");
	OpenForm("DataProcessor.ApplicationUserSettings.Form.UsersSelection", FormParameters);
	
EndProcedure

&AtClient
Procedure CopyReportSettingsAndAppearance(Command)
	
	UserType = TypeOf(UserRef);
	SettingsToCopy.Clear();
	SettingsToCopy.Add("ReportSettings", NStr("en='Report settings'"));
	SettingsToCopy.Add("AppearanceSettings", NStr("en='Appearance settings'"));
	
	FormParameters = New Structure("User, UserType, ActionType", 
										UserRef, UserType, "CopyAll");
	OpenForm("DataProcessor.ApplicationUserSettings.Form.UsersSelection", FormParameters);
	
EndProcedure

&AtClient
Procedure Clear(Command)
	
	SettingsTree = SelectedSettingsPageFormTable();
	SelectedRows = SettingsTree.SelectedRows;
	If SelectedRows.Count() = 0 Then
		
		ShowMessageBox(,NStr("en = 'Select the settings that you want to delete.'"));
		Return;
		
	EndIf;
	
	Notification = New NotifyDescription("ClearCompletion", ThisObject, SettingsTree);
	QuestionText = NStr("en = 'Clear  selected settings?'");
	ShowQueryBox(Notification, QuestionText, QuestionDialogMode.YesNo,, DialogReturnCode.Yes);
	
EndProcedure

&AtClient
Procedure ClearSettingsForSelectedUser(Command)
	
	SettingsTree = SelectedSettingsPageFormTable();
	SelectedRows = SettingsTree.SelectedRows;
	If SelectedRows.Count() = 0 Then
		
		ShowMessageBox(,NStr("en = 'Select the settings that you want to delete.'"));
		Return;
		
	EndIf;
	
	QuestionText = NStr("en = 'Clear the selected settings? 
   |This will open the dialog box where you can select users whose settings you want cleared.'");
	Notification = New NotifyDescription("ClearSettingsForSelectedUsersCompletion", ThisObject);
	ShowQueryBox(Notification, QuestionText, QuestionDialogMode.YesNo,, DialogReturnCode.Yes);
	
EndProcedure

&AtClient
Procedure ClearAllSettings(Command)
	
	QuestionText = NStr("en = 'Clear all settings for user %1?'");
	QuestionText = StringFunctionsClientServer.SubstituteParametersInString(QuestionText, UserRef);
	QuestionButtons = New ValueList;
	QuestionButtons.Add("Clear", NStr("en='Clear'"));
	QuestionButtons.Add("Cancel", NStr("en='Cancel'"));
	
	Notification = New NotifyDescription("ClearAllSettingsCompletion", ThisObject);
	ShowQueryBox(Notification, QuestionText, QuestionButtons,, QuestionButtons[1].Value);
	
EndProcedure

&AtClient
Procedure ClearReportAndAppearenceSettings(Command)
	
	QuestionText = NStr("en = 'Clear all appearance and report settings for user %1?'");
	QuestionText = StringFunctionsClientServer.SubstituteParametersInString(QuestionText, UserRef);
	QuestionButtons = New ValueList;
	QuestionButtons.Add("Clear", NStr("en='Clear'"));
	QuestionButtons.Add("Cancel", NStr("en='Cancel'"));
	
	Notification = New NotifyDescription("ClearReportAndAppearanceSettingsCompletion", ThisObject);
	ShowQueryBox(Notification, QuestionText, QuestionButtons,, QuestionButtons[1].Value);
	
EndProcedure

&AtClient
Procedure OpenSettingsItem(Command)
	
	UsersInternalClient.OpenReportOrForm(
		CurrentItem, InfobaseUser, CurrentInfobaseUser, PersonalSettingsFormName);
	
EndProcedure

&AtClient
Procedure ClearAllUserSettings(Command)
	
	QuestionText = NStr("en = 'This will clear all user settings. 
|Do you want to continue?'");
	QuestionText = StringFunctionsClientServer.SubstituteParametersInString(QuestionText, UserRef);
	QuestionButtons = New ValueList;
	QuestionButtons.Add("ClearAll", NStr("en='Clear all'"));
	QuestionButtons.Add("Cancel", NStr("en='Cancel'"));
	
	Notification = New NotifyDescription("ClearAllUserSettingsCompletion", ThisObject);
	ShowQueryBox(Notification, QuestionText, QuestionButtons,, QuestionButtons[1].Value);
	
EndProcedure

&AtClient
Procedure CopyFrom(Command)
	
	FormParameters = New Structure("User, FormOpeningMode", UserRef, "CopyFrom");
	OpenForm("DataProcessor.ApplicationUserSettings.Form.CopyAppUserSettings", FormParameters);
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for displaying lists of settings

&AtServer
Procedure FillSettingsLists()
	
	DataProcessors.ApplicationUserSettings.FillSettingsLists(ThisObject);
	CalculateSettingsCount();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for calculating the number of settings items

&AtServer
Procedure CalculateSettingsCount()
	
	SettingsList = ReportSettings.GetItems();
	
	SettingsCount = SettingsInTreeCount(SettingsList);
	
	If SettingsCount <> 0 Then
		Items.ReportSettingsPage.Title = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='Report settings (%1)'"), SettingsCount);
	Else
		Items.ReportSettingsPage.Title = NStr("en='Report settings'");
	EndIf;
	
	ReportSettingsCount = SettingsCount;
	SettingsList = Appearance.GetItems();
	SettingsCount = SettingsInTreeCount(SettingsList);
	
	If SettingsCount <> 0 Then
		Items.AppearancePage.Title = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='Appearance settings (%1)'"), SettingsCount);
	Else
		Items.AppearancePage.Title = NStr("en='Appearance settings'");
	EndIf;
	
	SettingsCountExternalType = SettingsCount;
	SettingsList = OtherSettings.GetItems();
	SettingsCount = SettingsInTreeCount(SettingsList);
	
	If SettingsCount <> 0 Then
		Items.OtherSettingsPage.Title = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='Other settings (%1)'"), SettingsCount);
	Else
		Items.OtherSettingsPage.Title = NStr("en='Other settings'");
	EndIf;
	
	OtherSettingsCount = SettingsCount;
	SettingsTotal = OtherSettingsCount + ReportSettingsCount;
	
EndProcedure

&AtServer
Function SettingsInTreeCount(SettingsList)
	
	SettingsCount = 0;
	For Each Settings In SettingsList Do
		
		SubordinateSettingsCount = Settings.GetItems().Count();
		If SubordinateSettingsCount = 0 Then
			SettingsCount = SettingsCount + 1;
		Else
			SettingsCount = SettingsCount + SubordinateSettingsCount;
		EndIf;
		
	EndDo;
	
	Return SettingsCount;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for copying, deleting and clearing settings

&AtServer
Procedure CopyAtServer(UsersTarget, ReportPersonalizationCount, Report)
	
	Result = SelectedSettings();
	SelectedReportOptionsTable = New ValueTable;
	SelectedReportOptionsTable.Columns.Add("Presentation");
	SelectedReportOptionsTable.Columns.Add("StandardProcessing");
	
	If SelectedSettingsPage = "ReportSettingsPage" Then
		
		For Each Settings In Result.SettingsArray Do
			
			For Each Item In Settings Do
				
				If Item.Check Then
					ReportPersonalizationCount = ReportPersonalizationCount + 1;
					ReportKey = StringFunctionsClientServer.SplitStringIntoSubstringArray(Item.Value, "/");
					FilterParameter = New Structure("ObjectKey", ReportKey[0]);
					RowArray = UserReportOptionTable.FindRows(FilterParameter);
					If RowArray.Count() <> 0 Then
						TableRow = SelectedReportOptionsTable.Add();
						TableRow.Presentation = RowArray[0].Presentation;
						TableRow.StandardProcessing = True;
					EndIf;
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
		NotCopiedReportSettings = New ValueTable;
		NotCopiedReportSettings.Columns.Add("User");
		NotCopiedReportSettings.Columns.Add("ReportList", New TypeDescription("ValueList"));
		
		DataProcessors.ApplicationUserSettings.CopyReportAndPersonalSettings(ReportsUserSettingsStorage,
			InfobaseUser, UsersTarget, Result.SettingsArray, NotCopiedReportSettings);
		// Copying report options
		DataProcessors.ApplicationUserSettings.CopyReportOptions(Result.ReportOptionArray,
			UserReportOptionTable, InfobaseUser, UsersTarget);
			
		If NotCopiedReportSettings.Count() <> 0
			OR UserReportOptionTable.Count() <> 0 Then
			Report = DataProcessors.ApplicationUserSettings.CreateReportOnCopyingSettings(
				NotCopiedReportSettings, SelectedReportOptionsTable);
		EndIf;
		
	ElsIf SelectedSettingsPage = "AppearancePage" Then
		DataProcessors.ApplicationUserSettings.CopyAppearanceSettings(InfobaseUser, UsersTarget, Result.SettingsArray);
	Else
		
		If Result.PersonalSettingsArray.Count() <> 0 Then
			DataProcessors.ApplicationUserSettings.CopyReportAndPersonalSettings(CommonSettingsStorage,
				InfobaseUser, UsersTarget, Result.PersonalSettingsArray);
		EndIf;
			
		If Result.UserSettingsArray.Count() <> 0 Then
			For Each OtherUserSettings In Result.UserSettingsArray Do
				For Each UserTarget In UsersTarget Do
					UserInfo = New Structure;
					UserInfo.Insert("UserRef", UserTarget);
					UserInfo.Insert("InfobaseUserName",
						DataProcessors.ApplicationUserSettings.InfobaseUserName(UserTarget));
					
					UsersInternal.OnSaveOtherSetings(
						UserInfo, OtherUserSettings);
				EndDo;
			EndDo;
		EndIf;
		
		DataProcessors.ApplicationUserSettings.CopyAppearanceSettings(
			InfobaseUser, UsersTarget, Result.SettingsArray);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CopyAllSettingsOnServer(User, UsersTarget, SettingsArray, Report)
	
	NotCopiedReportSettings = New ValueTable;
	NotCopiedReportSettings.Columns.Add("User");
	NotCopiedReportSettings.Columns.Add("ReportList", New TypeDescription("ValueList"));
	DataProcessors.ApplicationUserSettings.CopyAppUserSettings(
		UserRef, UsersTarget, SettingsArray, NotCopiedReportSettings);
		
	If NotCopiedReportSettings.Count() <> 0
		OR UserReportOptionTable.Count() <> 0 Then
		Report = DataProcessors.ApplicationUserSettings.CreateReportOnCopyingSettings(
			NotCopiedReportSettings, UserReportOptionTable);
	EndIf;
	
EndProcedure

&AtServer
Procedure ClearOnServer(Users = Undefined, ToSelectedUsers = False)
	
	Result = SelectedSettings();
	StorageName = StorageSettingsForSelectedPage();
	
	If ToSelectedUsers Then
		
		DataProcessors.ApplicationUserSettings.DeleteSettingsForSelectedUsers(Users, Result.SettingsArray, StorageName);
		If Result.PersonalSettingsArray.Count() <> 0 Then
			DataProcessors.ApplicationUserSettings.DeleteSettingsForSelectedUsers(Users,
				Result.PersonalSettingsArray, "CommonSettingsStorage");
		EndIf;
		
		Return;
	EndIf;
	
	// Clearing settings
	DataProcessors.ApplicationUserSettings.DeleteSelectedSettings(InfobaseUser, Result.SettingsArray, StorageName);
	If Result.PersonalSettingsArray.Count() <> 0 Then
		DataProcessors.ApplicationUserSettings.DeleteSelectedSettings(
			InfobaseUser, Result.PersonalSettingsArray, "CommonSettingsStorage");
	EndIf;
	
	If Result.UserSettingsArray.Count() <> 0 Then
		For Each OtherUserSettings In Result.UserSettingsArray Do
			UserInfo = New Structure;
			UserInfo.Insert("UserRef", UserRef);
			UserInfo.Insert("InfobaseUserName", InfobaseUser);
			UsersInternal.OnDeleteOtherSettings(
				UserInfo, OtherUserSettings);
		EndDo;
	EndIf;
	
	// Clearing report options 
	If SelectedSettingsPage = "ReportSettingsPage" Then
		
		DataProcessors.ApplicationUserSettings.DeleteReportOptions(
			Result.ReportOptionArray, UserReportOptionTable, InfobaseUser);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ClearAllSettingsOnServer(SettingsToClear)
	
	UserArray = New Array;
	UserArray.Add(UserRef);
	DataProcessors.ApplicationUserSettings.DeleteAppUserSettings(
		SettingsToClear, UserArray, UserReportOptionTable);
	
	FillSettingsLists();
	
EndProcedure

&AtServer
Procedure ClearAllUserSettingsOnServer()
	
	SettingsToClear = New Array;
	SettingsToClear.Add("ReportSettings");
	SettingsToClear.Add("AppearanceSettings");
	SettingsToClear.Add("PersonalSettings");
	SettingsToClear.Add("FormData");
	SettingsToClear.Add("Favorites");
	SettingsToClear.Add("PrintSettings");
	
	UserArray = New Array;
	UserTable = New ValueTable;
	UserTable.Columns.Add("User");
	UserTable = DataProcessors.ApplicationUserSettings.UsersToCopy("", UserTable, UseExternalUsers);
	
	For Each TableRow In UserTable Do
		UserArray.Add(TableRow.User);
	EndDo;
	
	DataProcessors.ApplicationUserSettings.DeleteAppUserSettings(SettingsToClear, UserArray, UserReportOptionTable);
	
EndProcedure

&AtClient
Procedure DeleteSettingsFromValueTree(SelectedRows)
	
	For Each SelectedRow In SelectedRows Do
		
		If SelectedSettingsPage = "ReportSettingsPage" Then
			DeleteSettingsRow(ReportSettings, SelectedRow);
		ElsIf SelectedSettingsPage = "AppearancePage" Then
			DeleteSettingsRow(Appearance, SelectedRow);
		Else
			DeleteSettingsRow(OtherSettings, SelectedRow);
		EndIf;
		
	EndDo;
	
	CalculateSettingsCount();
EndProcedure

&AtClient
Procedure ClearCompletion(Answer, SettingsTree) Export
	
	If Answer = DialogReturnCode.No Then
		Return;
	EndIf;
	
	SelectedRows = SettingsTree.SelectedRows;
	SettingsCount = CopiedOrDeletedSettingsCount(SettingsTree);
	
	ClearOnServer();
	CommonUseClient.RefreshApplicationInterface();
	
	If SettingsCount = 1 Then
		
		SettingName = SettingsTree.CurrentData.Settings;
		If StrLen(SettingName) > 24 Then
			SettingName = Left(SettingName, 24) + "...";
		EndIf;
		
	EndIf;
	
	DeleteSettingsFromValueTree(SelectedRows);
	
	NotifyAboutDeletion(SettingsCount, SettingName);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Auxiliary procedures and functions

&AtClient
Procedure Attachable_ExecuteNotifyProcessing()
	
	EventName = NotificationProcessingParameters.EventName;
	Parameter   = NotificationProcessingParameters.Parameter;
	
	If Upper(EventName) = Upper("UserSelection") Then
		
		UsersTarget = Parameter.UsersTarget;
		UserCount = UsersTarget.Count();
		
		ExplanationSettingsCopiedTo = UsersInternalClient.UsersExplanation(
			UserCount, UsersTarget[0]);
		
		If Parameter.CopyAll Then
			
			SettingsArray = New Array;
			SettingsNames = "";
			For Each Settings In SettingsToCopy Do 
				
				SettingsNames = SettingsNames + Lower(Settings.Presentation) + ", ";
				SettingsArray.Add(Settings.Value);
				
			EndDo;
				
			SettingsNames = Left(SettingsNames, StrLen(SettingsNames)-2);
			
			If SettingsArray.Count() = 7 Then
				ExplanationText = StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en = 'All settings are copied to %1'"), ExplanationSettingsCopiedTo);
			Else
				ExplanationText = StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en = '%1 copied to %2'"), SettingsNames, ExplanationSettingsCopiedTo);
			EndIf;
				
			Status(NStr("en = 'Сopying settings...'"));
			
			Report = Undefined;
			CopyAllSettingsOnServer(InfobaseUser, UsersTarget, SettingsArray, Report);
			
			If Report <> Undefined Then
				QuestionText = NStr("en = 'Some report options and settings are not copied.'");
				QuestionButtons = New ValueList;
				QuestionButtons.Add("OK", NStr("en='OK'"));
				QuestionButtons.Add("ShowReport", NStr("en='View report'"));
				
				Notification = New NotifyDescription("NotificationProcessingShowQueryBox", ThisObject, Report);
				ShowQueryBox(Notification, QuestionText, QuestionButtons,, QuestionButtons[0].Value);
				
				Return;
			EndIf;
				
			ShowUserNotification(
				NStr("en = 'Сopying settings'"), , ExplanationText, PictureLib.Information32);
			
			Return;
		EndIf;
		
		If Parameter.SettingsClearing Then
			
			SettingsTree = SelectedSettingsPageFormTable();
			SettingsCount = CopiedOrDeletedSettingsCount(SettingsTree);
			
			ClearOnServer(UsersTarget, True);
			
			If SettingsCount = 1 Then
				
				SettingName = SettingsTree.CurrentData.Settings;
				If StrLen(SettingName) > 24 Then
					SettingName = Left(SettingName, 24) + "...";
				EndIf;
				
			EndIf;
			
			UserCount = Parameter.UsersTarget.Count();
			NotifyAboutDeletion(SettingsCount, SettingName, UserCount);
			
			Return;
		EndIf;
		
		SettingsTree = SelectedSettingsPageFormTable();
		SettingsCount = CopiedOrDeletedSettingsCount(SettingsTree);
		
		ReportPersonalizationCount = 0;
		Report = Undefined;
		CopyAtServer(UsersTarget, ReportPersonalizationCount, Report);
		
		If Report <> Undefined Then
			QuestionText = NStr("en = 'Some report options and settings are not copied.'");
			QuestionButtons = New ValueList;
			QuestionButtons.Add("OK", NStr("en='OK'"));
			QuestionButtons.Add("ShowReport", NStr("en='View report'"));
			
			Notification = New NotifyDescription("NotificationProcessingShowQueryBox", ThisObject, Report);
			ShowQueryBox(Notification, QuestionText, QuestionButtons,, QuestionButtons[0].Value);
			
			Return;
		Else
			
			If SettingsCount = 1 Then
				SettingsItemPresentation = SettingsTree.CurrentData.Settings;
			EndIf;
			
			ExplanationText = UsersInternalClient.ExplanationOnCopy(
				SettingsItemPresentation, SettingsCount, ExplanationSettingsCopiedTo);
			ShowUserNotification(
				NStr("en = 'Сopying settings'"), , ExplanationText, PictureLib.Information32);
			
		EndIf;
		
	ElsIf Upper(EventName) = Upper("SettingsCopied") Then
		FillSettingsLists();
		ExpandValueTree();
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearSettingsForSelectedUsersCompletion(Answer, AdditionalParameters) Export
	
	If Answer = DialogReturnCode.No Then
		Return;
	EndIf;
	
	UserType = TypeOf(UserRef);
	FormParameters = New Structure("User, UserType, ActionType",
		UserRef, UserType, "Clearing");
	OpenForm("DataProcessor.ApplicationUserSettings.Form.UsersSelection", FormParameters);
	
EndProcedure

&AtClient
Procedure ClearAllUserSettingsCompletion(Answer, AdditionalParameters) Export
	
	If Answer = "Cancel" Then
		Return;
	EndIf;
	
	ClearAllUserSettingsOnServer();
	CommonUseClient.RefreshApplicationInterface();
	
	ShowUserNotification(NStr("en = 'Clearing settings'"), ,
		NStr("en='All settings of all users cleared'"), PictureLib.Information32);
	
EndProcedure

&AtClient
Procedure ClearAllSettingsCompletion(Answer, AdditionalParameters) Export
	
	If Answer = "Cancel" Then
		Return;
	EndIf;
	
	SettingsToClear = New Array;
	SettingsToClear.Add("ReportSettings");
	SettingsToClear.Add("AppearanceSettings");
	SettingsToClear.Add("FormData");
	SettingsToClear.Add("PersonalSettings");
	SettingsToClear.Add("Favorites");
	SettingsToClear.Add("PrintSettings");
	SettingsToClear.Add("OtherUserSettings");
	
	ClearAllSettingsOnServer(SettingsToClear);
	CommonUseClient.RefreshApplicationInterface();
	
	ExplanationText = NStr("en = 'All settings of user %1 are cleared'");
	ExplanationText = StringFunctionsClientServer.SubstituteParametersInString(ExplanationText, UserRef);
	ShowUserNotification(
		NStr("en = 'Clearing settings'"), , ExplanationText, PictureLib.Information32);
	
EndProcedure

&AtClient
Procedure ClearReportAndAppearanceSettingsCompletion(Answer, AdditionalParameters) Export
	
	If Answer = "Cancel" Then
		Return;
	EndIf;
	
	SettingsToClear = New Array;
	SettingsToClear.Add("ReportSettings");
	SettingsToClear.Add("AppearanceSettings");
	SettingsToClear.Add("FormData");
	
	ClearAllSettingsOnServer(SettingsToClear);
	CommonUseClient.RefreshApplicationInterface();
	
	ExplanationText = NStr("en = 'All appearance and report settings of user %1 are cleared'");
	ExplanationText = StringFunctionsClientServer.SubstituteParametersInString(ExplanationText, UserRef);
	ShowUserNotification(
		NStr("en = 'Clearing settings'"), , ExplanationText, PictureLib.Information32);
	
EndProcedure

&AtClient
Procedure SettingsBeforeDeleteCompletion(Answer, Item) Export
	
	If Answer = DialogReturnCode.No Then
		Return;
	EndIf;
	
	ClearOnServer();
	CommonUseClient.RefreshApplicationInterface();
	
	SelectedRows = Item.SelectedRows;
	SettingsCount = CopiedOrDeletedSettingsCount(Item);
	
	If SettingsCount = 1 Then
		
		SettingsTree = SelectedSettingsPageFormTable();
		SettingName = SettingsTree.CurrentData.Settings;
		
		If StrLen(SettingName) > 24 Then
			SettingName = Left(SettingName, 24) + "...";
		EndIf;
		
	EndIf;
	
	DeleteSettingsFromValueTree(SelectedRows);
	
	NotifyAboutDeletion(SettingsCount, SettingName);
	
EndProcedure

&AtClient
Procedure NotificationProcessingShowQueryBox(Answer, Report) Export
	
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

&AtClient
Procedure ExpandValueTree()
	
	Rows = ReportSettings.GetItems();
	For Each Row In Rows Do
		Items.ReportSettingsTree.Expand(Row.GetID(), True);
	EndDo;
	
	Rows = Appearance.GetItems();
	For Each Row In Rows Do
		Items.Appearance.Expand(Row.GetID(), True);
	EndDo;
	
EndProcedure

&AtClient
Function SelectedSettingsPageFormTable()
	
	If SelectedSettingsPage = "ReportSettingsPage" Then
		Return Items.ReportSettingsTree;
	ElsIf SelectedSettingsPage = "AppearancePage" Then
		Return Items.Appearance;
	Else
		Return Items.OtherSettings;
	EndIf;
	
EndFunction

&AtClient
Function CopiedOrDeletedSettingsCount(SettingsTree)
	
	SelectedRows = SettingsTree.SelectedRows;
	// Writing the array of selected rows to a value list in order to sort the selected rows
	SelectedRowsList = New ValueList;
	For Each Item In SelectedRows Do
		SelectedRowsList.Add(Item);
	EndDo;
	
	SelectedRowsList.SortByValue();
	If SelectedSettingsPage = "ReportSettingsPage" Then
		CurrentValueTree= ReportSettings;
	ElsIf SelectedSettingsPage = "AppearancePage" Then
		CurrentValueTree= Appearance;
	Else
		CurrentValueTree= OtherSettings;
	EndIf;
	
	SettingsCount = 0;
	For Each SelectedRow In SelectedRowsList Do
		TreeItem = CurrentValueTree.FindByID(SelectedRow.Value);
		SubordinateItemsCount = TreeItem.GetItems().Count();
		ItemParent = TreeItem.GetParent();
		
		If SubordinateItemsCount <> 0 Then
			SettingsCount = SettingsCount + SubordinateItemsCount;
			TopLevelItem = TreeItem;
		ElsIf SubordinateItemsCount = 0
			And ItemParent = Undefined Then
			SettingsCount = SettingsCount + 1;
		Else
			
			If ItemParent <> TopLevelItem Then
				SettingsCount = SettingsCount + 1;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return SettingsCount;
EndFunction

&AtClient
Procedure DeleteSettingsRow(SettingsTree, SelectedRow)
	
	SettingsItem = SettingsTree.FindByID(SelectedRow);
	If SettingsItem = Undefined Then
		Return;
	EndIf;
	
	SettingsItemParent = SettingsItem.GetParent();
	If SettingsItemParent <> Undefined Then
		
		SubordinateRowsCount = SettingsItemParent.GetItems().Count();
		If SubordinateRowsCount = 1 Then
			
			If SettingsItemParent.Type <> "PersonalOption" Then
				SettingsTree.GetItems().Delete(SettingsItemParent);
			EndIf;
			
		Else
			SettingsItemParent.GetItems().Delete(SettingsItem);
		EndIf;
		
	Else
		SettingsTree.GetItems().Delete(SettingsItem);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotifyAboutDeletion(SettingsCount, SettingName = Undefined, UserCount = Undefined)
	
	SubjectInWords = UsersInternalClient.SettingsCountString(SettingsCount);
	If SettingsCount = 1
		And UserCount = Undefined Then
		ExplanationText = NStr("en = '%1 cleared for user %2'");
		ExplanationText = StringFunctionsClientServer.SubstituteParametersInString(
			ExplanationText, SettingName, String(UserRef));
	ElsIf UserCount = Undefined Then
		ExplanationText = NStr("en = '%1 cleared for user %2'");
		ExplanationText = StringFunctionsClientServer.SubstituteParametersInString(
			ExplanationText, SubjectInWords, String(UserRef));
	EndIf;
	
	ExplanationClearSettingsFor = UsersInternalClient.UsersExplanation(
		UserCount, String(UserRef));
	
	If UserCount <> Undefined Then
		
		If SettingsCount = 1 Then
			ExplanationText = NStr("en = '%1 cleared for %2'");
			ExplanationText = StringFunctionsClientServer.SubstituteParametersInString(
				ExplanationText, SettingName, ExplanationClearSettingsFor);
		Else
			ExplanationText = NStr("en = '%1 cleared for %2'");
			ExplanationText = StringFunctionsClientServer.SubstituteParametersInString(
				ExplanationText, SubjectInWords, ExplanationClearSettingsFor);
		EndIf;
		
	EndIf;
	
	ShowUserNotification(
		NStr("en = 'Clearing settings'"), , ExplanationText, PictureLib.Information32);
	
EndProcedure

&AtClient
Procedure CopySettings()
	
	SettingsTree = SelectedSettingsPageFormTable();
	If SettingsTree.SelectedRows.Count() = 0 Then
		ShowMessageBox(,NStr("en = 'Select the settings you want to copy.'"));
		Return;
	ElsIf SettingsTree.SelectedRows.Count() = 1 Then
		
		If SettingsTree.CurrentData.Type = "PersonalOption" Then
			ShowMessageBox(,NStr("en = 'Cannot copy user-defined report option.
			|If you want to make the user-defined report option available to other users, clear the ""Available to author only"" check box and then save the report option.'"));
			Return;
		ElsIf SettingsTree.CurrentData.Type = "SettingsItemPersonal" Then
			ShowMessageBox(,NStr("en = 'Cannot copy user-defined report option settings item.
			|Copying user-defined settings is not allowed.'"));
			Return;
		EndIf;
		
	EndIf;
	
	UserType = TypeOf(UserRef);
	FormParameters = New Structure("User, UserType, ActionType", 
										UserRef, UserType, "");
	OpenForm("DataProcessor.ApplicationUserSettings.Form.UsersSelection", FormParameters);
	
EndProcedure

&AtServer
Procedure GetUserNameAndRefresh()
	
	InfobaseUser = DataProcessors.ApplicationUserSettings.InfobaseUserName(UserRef);
	FillSettingsLists();
	
EndProcedure

&AtServer
Function SettingsTreeForSelectedPage()
	
	If SelectedSettingsPage = "ReportSettingsPage" Then
		Return ReportSettings;
	ElsIf SelectedSettingsPage = "AppearancePage" Then
		Return Appearance;
	Else
		Return OtherSettings;
	EndIf;
	
EndFunction

&AtServer
Function StorageSettingsForSelectedPage()
	
	If SelectedSettingsPage = "ReportSettingsPage" Then
		Return "ReportsUserSettingsStorage";
	ElsIf SelectedSettingsPage = "AppearancePage"
		OR SelectedSettingsPage = "OtherSettingsPage" Then
		Return "SystemSettingsStorage";
	EndIf;
	
EndFunction

&AtServer
Function SelectedSettingsItems()
	
	If SelectedSettingsPage = "ReportSettingsPage" Then
		Return Items.ReportSettingsTree.SelectedRows;
	ElsIf SelectedSettingsPage = "AppearancePage" Then
		Return Items.Appearance.SelectedRows;
	Else
		Return Items.OtherSettings.SelectedRows;
	EndIf;
	
EndFunction

&AtServer
Function SelectedSettings()
	
	SettingsTree = SettingsTreeForSelectedPage();
	SettingsArray = New Array;
	PersonalSettingsArray = New Array;
	ReportOptionArray = New Array;
	UserSettingsArray = New Array;
	CurrentReportOption = Undefined;
	
	SelectedItems = SelectedSettingsItems();
	
	For Each SelectedItem In SelectedItems Do
		SelectedSetting = SettingsTree.FindByID(SelectedItem);
		
		// Filling the array of personal settings
		If SelectedSetting.Type = "PersonalSettings" Then
			PersonalSettingsArray.Add(SelectedSetting.Keys);
			Continue;
		EndIf;
		
		// Filling the array of other user settings
		If SelectedSetting.Type = "OtherUserSettingsItem" Then
			OtherUserSettings = New Structure;
			OtherUserSettings.Insert("SettingID", SelectedSetting.RowType);
			OtherUserSettings.Insert("SettingValue", SelectedSetting.Keys);
			UserSettingsArray.Add(OtherUserSettings);
			Continue;
		EndIf;
		
		// Marking personal settings in the list of keys
		If SelectedSetting.Type = "PersonalOption" Then
			
			For Each Item In SelectedSetting.Keys Do
				Item.Check = True;
			EndDo;
			CurrentReportOption = SelectedSetting.Keys.Copy();
			// Filling the array of user-defined report options
			ReportOptionArray.Add(SelectedSetting.Keys);
			
		ElsIf SelectedSetting.Type = "StandardOptionPersonal" Then
			ReportOptionArray.Add(SelectedSetting.Keys);
		EndIf;
		
		If SelectedSetting.Type = "SettingsItemPersonal" Then
			
			If CurrentReportOption <> Undefined
				And CurrentReportOption.FindByValue(SelectedSetting.Keys[0].Value) <> Undefined Then
				Continue;
			Else
				SelectedSetting.Keys[0].Check = True;
				SettingsArray.Add(SelectedSetting.Keys);
				Continue;
			EndIf;
			
		EndIf;
		
		SettingsArray.Add(SelectedSetting.Keys);
		
	EndDo;
	
	Return New Structure("SettingsArray, PersonalSettingsArray, ReportOptionArray, UserSettingsArray",
			SettingsArray, PersonalSettingsArray, ReportOptionArray, UserSettingsArray);
EndFunction

#EndRegion
