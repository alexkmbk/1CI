////////////////////////////////////////////////////////////////////////////////
// Users subsystem.
//
////////////////////////////////////////////////////////////////////////////////

#Region Interface

// Overrides the standard method of assigning roles to infobase users.
//
// Parameters:
//  Prohibition - Boolean - if True, prohibits role modification for veryone (including administrator).
//
Procedure ChangeRoleEditProhibition(Prohibition) Export
	
EndProcedure

// Overrides behavior of the following forms: user form, external user form, and external user group form.
//
// Parameters:
//  Ref - CatalogRef.Users,
//        CatalogRef.ExternalUsers,
//        CatalogRef.ExternalUserGroups - reference to user, external user or external user group.
//                                        It is used when the form is created.
//
//  ActionsOnForm - Structure - with the following properties:
//         * Roles                  - String - "", "View", "Edit".
//         * ContactInformation     - String - "", "View", "Edit".
//         * InfobaseUserProperties - String - "", "View", "Edit".
//         * ItemProperties         - String - "", "View", "Edit".
//           
//  ContactInformation and InfobaseUserProperties do not exist for external user groups.
//
Procedure ChangeActionsOnForm(Val Ref, Val ActionsOnForm) Export
	
EndProcedure

// Extends the definition of the operation performed when writing a user to the infobase.
//  The procedure is called from the WriteInfobaseUser() procedure if the user was modified.
//
// Parameters:
//  OldProperties - Structure - see parameters returned by the Users.ReadInfobaseUser() function.
//  NewProperties - Structure - see parameters returned by the Users.WriteInfobaseUser() function.
//
Procedure OnWriteInfobaseUser(Val OldProperties, Val NewProperties) Export
	
EndProcedure

// Extends the definition of the operation performed after deleting an infobase user.
//  The procedure is called from the DeleteInfobaseUser() procedure if the user has been deleted.
//
// Parameters:
//  OldProperties - Structure - see parameters returned by the Users.ReadInfobaseUser() function.
//
Procedure AfterInfobaseUserDelete(Val OldProperties) Export
	
EndProcedure

// Overrides interface settings for new users.
//
// Parameters:
//  InitialSettings - Structure - default settings:
//   * ClientSettings    - ClientSettings - client application settings.
//   * InterfaceSettings - CommandInterfaceSettings - command interface settings (for
//                         selections panel, navigation panel, and actions panel).
//   * TaxiSettings      - ClientApplicationInterfaceSettings - client application interface
//                         settings (panel contents and positions).
//
Procedure OnSetInitialSettings(InitialSettings) Export
	
	// _Demo begin example
	InitialSettings.InterfaceSettings.SectionsPanelRepresentation = SectionsPanelRepresentation.PictureAndText;
	// _Demo end example
	
EndProcedure

// Extends the list of settings on the "Other" tab of AppUserSettings data processor for the user passed to the procedure.
//
// Parameters:
//  UserInfo - Structure - a string presentation and a reference presentation of the user.
//       * UserRef          - CatalogRef.Users - user whose settings are retrieved.
//       * InfobaseUserName - String - infobase user whose settings are retrieved.
//  Settings - Structure - other user settings.
//       * Key  - String - string ID of the setting. It is used for copying and clearing the setting.
//       * Value - Structure - setting details.
//              ** SettingName    - String - name to be displayed in the settings tree.
//              ** SettingPicture - Picture - picture to be displayed in the settings tree.
//              ** SettingsList   - ValueList - list of retrieved settings.
//
Procedure OnGetOtherSettings(UserInfo, Settings) Export
	
	// _Demo begin example
	
	// Getting the value of the AskConfirmationOnExit setting.
	SettingValue = CommonUse.CommonSettingsStorageLoad(
		"UserCommonSettings", "AskConfirmationOnExit",,,
			UserInfo.InfobaseUserName);
	If SettingValue <> Undefined Then
		
		ValueListSettings = New ValueList;
		ValueListSettings.Add(SettingValue);
		
		SettingDetails    = New Structure;
		SettingDetails.Insert("SettingName", NStr("en = 'Confirmation on exit'"));
		SettingDetails.Insert("SettingPicture", "");
		SettingDetails.Insert("SettingsList", ValueListSettings);
		
		Settings.Insert("AskConfirmationOnClose", SettingDetails);
	EndIf;
	
	// _Demo end example
	
EndProcedure

// Saves settings for the user passed to the procedure.
//
// Parameters:
//  Settings - ValueList - list of settings values to be saved.
//  UserInfo - Structure - a string presentation and a reference presentation of the user.
//       * UserRef          - CatalogRef.Users - user whose settings are saved.
//       * InfobaseUserName - String - infobase user whose settings are saved.
//
Procedure OnSaveOtherSetings(UserInfo, Settings) Export
	
	// _Demo begin example
	
	If Settings.SettingID = "AskConfirmationOnClose" Then
		SettingValue = Settings.SettingValue[0];
		CommonUse.CommonSettingsStorageSave(
			"UserCommonSettings", "AskConfirmationOnExit",
			SettingValue.Value,, UserInfo.InfobaseUserName);
	EndIf;
	
	// _Demo end example
	
EndProcedure

// Clears settings for the user passed to the procedure.
//
// Parameters:
//  Settings - ValueList - list of settings values to be cleared. 
//  UserInfo - Structure - a string presentation and a reference presentation of the user.
//       * UserRef          - CatalogRef.Users - user whose settings are cleared.
//       * InfobaseUserName - String - infobase user whose settings are cleared.
//
Procedure OnDeleteOtherSettings(UserInfo, Settings) Export
	
	// _Demo begin example
	
	If Settings.SettingID = "AskConfirmationOnClose" Then
		CommonUse.CommonSettingsStorageDelete(
			"UserCommonSettings", "AskConfirmationOnExit",
			UserInfo.InfobaseUserName);
	EndIf;
	
	// _Demo end example
	
EndProcedure

#EndRegion
