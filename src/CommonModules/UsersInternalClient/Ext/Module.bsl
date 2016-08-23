////////////////////////////////////////////////////////////////////////////////
// Users subsystem.
//
////////////////////////////////////////////////////////////////////////////////

#Region InternalInterface

////////////////////////////////////////////////////////////////////////////////
// For role interface in managed forms.

// For internal use only.
//
Procedure ExpandRoleSubsystems(Form, Unconditionally = True) Export
	
	Items = Form.Items;
	
	If Not Unconditionally
	   And Not Items.RolesShowSelectedRolesOnly.Check Then
		
		Return;
	EndIf;
	
	// Expand all.
	For Each Row In Form.Roles.GetItems() Do
		Items.Roles.Expand(Row.GetID(), True);
	EndDo;
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

// Checks user authorization result and generates an error message.
Procedure BeforeStart(Parameters) Export
	
	ClientParameters = StandardSubsystemsClientCached.ClientParametersOnStart();
	
	If Not ClientParameters.Property("AuthorizationError") Then
		Return;
	EndIf;
	
	Parameters.Cancel = True;
	Parameters.InteractiveHandler = New NotifyDescription(
		"OnCheckUserAuthorizationInteractiveHandler", ThisObject);
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// Notification handlers.

// Notifies about a user authentication error.
Procedure OnCheckUserAuthorizationInteractiveHandler(Parameters, NotDefined) Export
	
	ClientParameters = StandardSubsystemsClientCached.ClientParametersOnStart();
	
	StandardSubsystemsClient.ShowMessageBoxAndContinue(
		Parameters, ClientParameters.AuthorizationError);
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// Procedures and functions for AppUserSettings data processor.

// Opens the report or form that is passed to it.
//
// Parameters:
//  CurrentItem              - FormTable - selected row of value tree.
//  User                     - String - infobase user name,
//  CurrentUser              - String - infobase user name. 
//  If the procedure opens a form, this value must match 
//  the value of the "User" parameter.
//  PersonalSettingsFormName - String - path for opening the personal
//  settings form in the following format: CommonForm.FormName
Procedure OpenReportOrForm(CurrentItem, User, CurrentUser, PersonalSettingsFormName) Export
	
	ValueTreeItem = CurrentItem;
	If ValueTreeItem.CurrentData = Undefined Then
		Return;
	EndIf;
	
	If User <> CurrentUser Then
		WarningText = NStr("en = 'To view the settings of another user run the application using their account and open the appropriate report or form.'");
		ShowMessageBox(,WarningText);
		Return;
	EndIf;
	
	If ValueTreeItem.Name = "ReportSettingsTree" Then
		
		ObjectKey = ValueTreeItem.CurrentData.Keys[0].Value;
		ObjectKeyRowArray = StringFunctionsClientServer.SplitStringIntoSubstringArray(ObjectKey, "/");
		VariantKey = ObjectKeyRowArray[1];
		ReportParameters = New Structure("VariantKey, UserSettingsKey", VariantKey, "");
		
		If ValueTreeItem.CurrentData.Type = "ReportSettings" Then
			UserSettingsKey = ValueTreeItem.CurrentData.Keys[0].Presentation;
			ReportParameters.Insert("UserSettingsKey", UserSettingsKey);
		EndIf;
		
		OpenForm(ObjectKeyRowArray[0] + ".Form", ReportParameters);
		Return;
		
	ElsIf ValueTreeItem.Name = "Appearance" Then
		
		For Each ObjectKey In ValueTreeItem.CurrentData.Keys Do
			
			If ObjectKey.Check = True Then
				
				OpenForm(ObjectKey.Value);
				Return;
			Else
				ItemParent = ValueTreeItem.CurrentData.GetParent();
				
				If ValueTreeItem.CurrentData.RowType = "DesktopSettings" Then
					ShowMessageBox(,NStr("en = 'To view the desktop settings, go to the ""Desktop"" section in the application command interface.'"));
					Return;
				EndIf;
				
				If ValueTreeItem.CurrentData.RowType = "CommandInterfaceSettings" Then
					ShowMessageBox(,NStr("en = 'To view command interface settings, select a command interface section.'"));
					Return;
				EndIf;
				
				If ItemParent <> Undefined Then
					WarningText = NStr("en = 'To view this setting, open a %1 and then go to form %2.'");
					WarningText = StringFunctionsClientServer.SubstituteParametersInString(WarningText,
						ItemParent.Settings, ValueTreeItem.CurrentData.Settings);
					ShowMessageBox(,WarningText);
					Return;
				EndIf;
				
			EndIf;
			
		EndDo;
		
		ShowMessageBox(,NStr("en = 'Cannot view the setting.'"));
		Return;
		
	ElsIf ValueTreeItem.Name = "OtherSettings" Then
		
		If ValueTreeItem.CurrentData.Type = "PersonalSettings"
			AND PersonalSettingsFormName <> "" Then
			OpenForm(PersonalSettingsFormName);
			Return;
		EndIf;
		
		ShowMessageBox(,NStr("en = 'Cannot view the setting.'"));
		Return;
		
	EndIf;
	
	ShowMessageBox(,NStr("en = 'Select the setting to view.'"));
	
EndProcedure

// Generates the ending for the "setting" word.
//
// Parameters:
//  SettingsCount - Number - number of settings.
//
// Returns:
//  String - a string like "xx settings" with the right ending.
//
Function SettingsCountString(SettingsCount) Export
	
	NumberInWords = NumberInWords(
		SettingsCount,
		"L=en_US",
		NStr("en = ',,,,,,,,0'"));
	SubjectAndNumberInWords = NumberInWords(
		SettingsCount,
		"L=en_US",
		NStr("en = 'setting,settings,settings,,,,,,0'"));
	SubjectInWords = StrReplace(
		SubjectAndNumberInWords,
		NumberInWords,
		Format(SettingsCount, "NFD=0") + " ");
		
	Return SubjectInWords;
EndFunction

// Generates a message to display after settings are copied
//
// Parameters:
//  SettingsItemPresentation    - String - setting name. It is used when 
//  a single setting is copied.
//  SettingsCount               - Number - number of settings. It is used
//  when multiple settings are copied.
//  ExplanationSettingsCopiedTo - String - target user.
//
// Returns:
//  String - a string to display after settings are copied.
//
Function ExplanationOnCopy(SettingsItemPresentation, SettingsCount, ExplanationSettingsCopiedTo) Export
	
	If SettingsCount = 1 Then
		
		If StrLen(SettingsItemPresentation) > 24 Then
			SettingsItemPresentation = Left(SettingsItemPresentation, 24) + "...";
		EndIf;
		
		ExplanationText = NStr("en = '""%1"" copied to %2'");
		ExplanationText = StringFunctionsClientServer.SubstituteParametersInString(
			ExplanationText, SettingsItemPresentation, ExplanationSettingsCopiedTo);
	Else
		SubjectInWords = SettingsCountString(SettingsCount);
		ExplanationText = NStr("en = '%1 copied to %2'");
		ExplanationText = StringFunctionsClientServer.SubstituteParametersInString(
			ExplanationText, SubjectInWords, ExplanationSettingsCopiedTo);
	EndIf;
	
	Return ExplanationText;
EndFunction

// Generates a string that describes the target users.
//
// Parameters:
//  UserCount - Number - used if the number of users is more then 1.
//  User      - String - username. It is used if the number of users is 1.
//
// Returns:
//  String - a string that describes the target users.
//
Function UsersExplanation(UserCount, User) Export
	
	If UserCount = 1 Then
		ExplanationSettingsCopiedTo = NStr("en = 'user ""%1""'");
		ExplanationSettingsCopiedTo = StringFunctionsClientServer.SubstituteParametersInString(
			ExplanationSettingsCopiedTo, User);
	Else
		ExplanationSettingsCopiedTo = NStr("en = '%1 users'");
		ExplanationSettingsCopiedTo = StringFunctionsClientServer.SubstituteParametersInString(
			ExplanationSettingsCopiedTo, UserCount);
	EndIf;
	
	Return ExplanationSettingsCopiedTo;
EndFunction

#EndRegion
