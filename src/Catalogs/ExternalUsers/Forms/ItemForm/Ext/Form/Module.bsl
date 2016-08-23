 
#Region FormEventHandlers
 
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	// Skipping the initialization to guarantee that the form will be received if the Autotest parameter is passed.
	If Parameters.Property("Autotest") Then 
		Return;
	EndIf;
	
	// Filling auxiliary data.
	
	RoleEditProhibition = UsersInternal.RoleEditProhibition();
	
	// Filling language choice list.
	If Metadata.Languages.Count() < 2 Then
		Items.InfobaseUserLanguage.Visible = False;
	Else
		For Each LanguageMetadata In Metadata.Languages Do
			Items.InfobaseUserLanguage.ChoiceList.Add(
				LanguageMetadata.Name, LanguageMetadata.Synonym);
		EndDo;
	EndIf;
	
	// Preparing for execution of interactive actions according to the form opening scenarios.
	AccessLevel = UsersInternal.UserPropertyAccessLevel(Object);
	
	SetPrivilegedMode(True);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		// Adding a new item.
		If Parameters.NewExternalUserGroup
		         <> Catalogs.ExternalUserGroups.AllExternalUsers Then
			
			NewExternalUserGroup = Parameters.NewExternalUserGroup;
		EndIf;
		
		If ValueIsFilled(Parameters.CopyingValue) Then
			// Copying the item.
			CopyingValue = Parameters.CopyingValue;
			Object.AuthorizationObject = Undefined;
			Object.Description         = "";
 
			
			If Users.InfobaseUserWithFullAccess(CopyingValue, True, False) Then
				InfobaseUserCopyingAllowed = AccessLevel.FullAdministrator;
			ElsIf Users.InfobaseUserWithFullAccess(CopyingValue, False, False) Then
				InfobaseUserCopyingAllowed = AccessLevel.FullAccess;
			Else
				InfobaseUserCopyingAllowed = True;
			EndIf;
			
			If InfobaseUserCopyingAllowed Then
				ReadInfobaseUser(ValueIsFilled(
					Parameters.CopyingValue.InfobaseUserID));
			Else
				ReadInfobaseUser();
			EndIf;
			If Not AccessLevel.FullAccess Then
				CanLogOnToApplication = False;
				CanLogOnToApplicationDirectChangeValue = False;
			EndIf;
		Else
			// Adding an item.
			If Parameters.Property("NewExternalUserAuthorizationObject") Then
				
				Object.AuthorizationObject = Parameters.NewExternalUserAuthorizationObject;
				AuthorizationObjectSetOnOpen = ValueIsFilled(Object.AuthorizationObject);
				AuthorizationObjectOnChangeAtClientAtServer(ThisObject, Object);
				
			ElsIf ValueIsFilled(NewExternalUserGroup) Then
				
				AuthorizationObjectType = CommonUse.ObjectAttributeValue(
					NewExternalUserGroup, "AuthorizationObjectType");
				
				Object.AuthorizationObject = AuthorizationObjectType;
				Items.AuthorizationObject.ChooseType = AuthorizationObjectType = Undefined;
			EndIf;
			
			// Reading initial infobase user property values.
			ReadInfobaseUser();
			
			If Not ValueIsFilled(Parameters.InfobaseUserID) Then
				InfobaseUserStandardAuthentication = True;
				
				If AccessLevel.FullAccess Then
					CanLogOnToApplication = True;
					CanLogOnToApplicationDirectChangeValue = True;
				EndIf;
			EndIf;
		EndIf;
		
		If AccessLevel.FullAccess
		   And Object.AuthorizationObject <> Undefined Then
			
			InfobaseUserName = UsersInternalClientServer.GetInfobaseUserShortName(
				CurrentAuthorizationObjectPresentation);
			
			InfobaseUserFullName = Object.Description;
		EndIf;
	Else
		// Opening the existing item.
		ReadInfobaseUser();
	EndIf;
	
	SetPrivilegedMode(False);
	
	ProcessRolesInterface("SetUpRoleInterfaceOnFormCreate", True);
	InitialInfobaseUserDescription = InitialInfobaseUserDescription();
	
	FormCommonSetting(True);
	
EndProcedure
 
&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	FormCommonSetting();
	
	CurrentAuthorizationObjectPresentation = String(Object.AuthorizationObject);
	
EndProcedure
 
&AtServer
Procedure FormCommonSetting(OnCreateAtServer = False, WriteParameters = Undefined)
	
	If InitialInfobaseUserDescription = Undefined Then
		Return; // OnReadAtServer before OnCreateAtServer.
	EndIf;
	
	If Not OnCreateAtServer Then
		ReadInfobaseUser();
	EndIf;
	
	AccessLevel = UsersInternal.UserPropertyAccessLevel(Object);
	
	SetActionsOnForm();
	
	FindUserAndInfobaseUserInconsistencies(WriteParameters);
	
	// Making the properties always available.
	Items.InfobaseUserProperties.Visible =
		ValueIsFilled(ActionsOnForm.InfobaseUserProperties);
	
	Items.RoleRepresentation.Visible =
		ValueIsFilled(ActionsOnForm.Roles);
	
	Items.SetRolesDirectly.Visible =
		ValueIsFilled(ActionsOnForm.Roles) And Not UsersInternal.RoleEditProhibition();
	
	UpdateDisplayedUserType();
	
	ReadOnly = ReadOnly
		Or ActionsOnForm.Roles                     <> "Edit"
		  And ActionsOnForm.ItemProperties         <> "Edit"
		  And ActionsOnForm.InfobaseUserProperties <> "Edit";
	
	Items.CheckSettingsAfterLogOnRecommendation.Visible =
		AccessLevel.FullAccess And Object.Prepared And Not CanLogOnToApplicationOnRead;
	
	SetPropertyEnabled();
	
EndProcedure
 
&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	ClearMessages();
	
	If ActionsOnForm.Roles = "Edit"
	   And Object.SetRolesDirectly
	   And InfobaseUserRoles.Count() = 0 Then
		
		If Not WriteParameters.Property("WithEmptyRoleList") Then
			Cancel = True;
			ShowQueryBox(
				New NotifyDescription("AfterAnswerQuestionAboutWritingWithEmptyRoleList", ThisObject, WriteParameters),
				NStr("en = 'No roles are set for the infobase user. Do you want to continue?'"),
				QuestionDialogMode.YesNo,
				,
				,
				NStr("en = 'Save infobase user'"));
			Return;
		EndIf;
	EndIf;
	
EndProcedure
 
&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CurrentObject.AdditionalProperties.Insert("CopyingValue", CopyingValue);
	
	UpdateDisplayedUserType();
	// Updating external user description.
	SetPrivilegedMode(True);
	CurrentAuthorizationObjectPresentation = String(CurrentObject.AuthorizationObject);
	SetPrivilegedMode(False); 
	Object.Description        = CurrentAuthorizationObjectPresentation;
	CurrentObject.Description = CurrentAuthorizationObjectPresentation;
	
	If InfobaseUserWriteRequired(ThisObject) Then
		InfobaseUserDescription = InfobaseUserDescription();
		InfobaseUserDescription.Delete("PasswordConfirmation");
		
		If ValueIsFilled(Object.InfobaseUserID) Then
			InfobaseUserDescription.Insert("UUID", Object.InfobaseUserID);
		EndIf;
		InfobaseUserDescription.Insert("Action", "Write");
		
		CurrentObject.AdditionalProperties.Insert("InfobaseUserDescription", InfobaseUserDescription);
	EndIf;
	
	If ActionsOnForm.ItemProperties <> "Edit" Then
		FillPropertyValues(CurrentObject, CommonUse.ObjectAttributeValues(
			CurrentObject.Ref, "DeletionMark"));
	EndIf;
	
	CurrentObject.AdditionalProperties.Insert(
		"NewExternalUserGroup", NewExternalUserGroup);
	
	SetPrivilegedMode(True);
	
EndProcedure
 
&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	If InfobaseUserWriteRequired(ThisObject) Then
		WriteParameters.Insert(
			CurrentObject.AdditionalProperties.InfobaseUserDescription.ActionResult);
	EndIf;
	
	FormCommonSetting(, WriteParameters);
	
EndProcedure
 
&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_ExternalUsers", New Structure, Object.Ref);
	
	If WriteParameters.Property("InfobaseUserAdded") Then
		Notify("InfobaseUserAdded", WriteParameters.InfobaseUserAdded, ThisObject);
		
	ElsIf WriteParameters.Property("InfobaseUserChanged") Then
		Notify("InfobaseUserChanged", WriteParameters.InfobaseUserChanged, ThisObject);
		
	ElsIf WriteParameters.Property("InfobaseUserDeleted") Then
		Notify("InfobaseUserDeleted", WriteParameters.InfobaseUserDeleted, ThisObject);
		
	ElsIf WriteParameters.Property("MappingToNonExistentInfobaseUserCleared") Then
		
		Notify(
			"MappingToNonExistentInfobaseUserCleared",
			WriteParameters.MappingToNonExistentInfobaseUserCleared, ThisObject);
	EndIf;
	
	If ValueIsFilled(NewExternalUserGroup) Then
		NotifyChanged(NewExternalUserGroup);
		
		Notify(
			"Write_ExternalUserGroups",
			New Structure,
			NewExternalUserGroup);
		
		NewExternalUserGroup = Undefined;
	EndIf;
	
	SetPropertyEnabled();
	
	UsersInternalClient.ExpandRoleSubsystems(ThisObject);
	
EndProcedure
 
&AtServer
Procedure FillCheckProcessingAtServer(Cancel, AttributesToCheck)
	
	ErrorText = "";
	If UsersInternal.AuthorizationObjectUsed(
	         Object.AuthorizationObject, Object.Ref, , , ErrorText) Then
		
		CommonUseClientServer.MessageToUser(
			ErrorText, , "Object.AuthorizationObject", , Cancel);
	EndIf;
	
	If InfobaseUserWriteRequired(ThisObject) Then
		InfobaseUserDescription = InfobaseUserDescription();
		InfobaseUserDescription.Insert("InfobaseUserID", Object.InfobaseUserID);
		UsersInternal.CheckInfobaseUserDescription(InfobaseUserDescription, Cancel);
		
		MessageText = "";
		If UsersInternal.CreateFirstAdministratorRequired(, MessageText) Then
			CommonUseClientServer.MessageToUser(
				MessageText, , "CanLogOnToApplication", , Cancel);
		EndIf;
	EndIf;
	
EndProcedure
 
&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	ProcessRolesInterface("SetUpRoleInterfaceOnLoadSettings", Settings);
	
EndProcedure
 
#EndRegion
 
#Region FormHeaderItemEventHandlers
 
&AtClient
Procedure AuthorizationObjectOnChange(Item)
	
	AuthorizationObjectOnChangeAtClientAtServer(ThisObject, Object);
	
EndProcedure
 
&AtClient
Procedure NotValidOnChange(Item)
	
	If Object.NotValid Then
		CanLogOnToApplication = False;
	Else
		CanLogOnToApplication = CanLogOnToApplicationDirectChangeValue
			And (InfobaseUserOpenIDAuthentication
			   Or InfobaseUserStandardAuthentication);
	EndIf;
	
	SetPropertyEnabled();
	
EndProcedure
 
&AtClient
Procedure CanLogOnToApplicationOnChange(Item)
	
	If Object.DeletionMark And CanLogOnToApplication Then
		CanLogOnToApplication = False;
		ShowMessageBox(,
			NStr("en = 'To allow access to the infobase, remove the deletion mark from the external user.'"));
		Return;
	EndIf;
	
	UpdateLogonName(ThisObject);
	
	If CanLogOnToApplication
	   And Not InfobaseUserOpenIDAuthentication
	   And Not InfobaseUserStandardAuthentication Then
	
		InfobaseUserStandardAuthentication = True;
	EndIf;
	
	SetPropertyEnabled();
	
	If Not AccessLevel.FullAccess
	   And AccessLevel.ListManagement
	   And Not CanLogOnToApplication Then
		
		ShowMessageBox(,
			NStr("en = 'Once you save the changes, only administrator can allow logging on to the application.'"));
	EndIf;
	
	CanLogOnToApplicationDirectChangeValue = CanLogOnToApplication;
	
EndProcedure
 
&AtClient
Procedure InfobaseUserNameOnChange(Item)
	
	SetPropertyEnabled();
	
EndProcedure
 
&AtClient
Procedure InfobaseUserStandardAuthenticationOnChange(Item)
	
	AuthenticationOnChange();
	
EndProcedure
 
&AtClient
Procedure PasswordOnChange(Item)
	
	SetPropertyEnabled();
	
	InfobaseUserPassword = Password;
	
EndProcedure
 
&AtClient
Procedure InfobaseUserCannotChangePasswordOnChange(Item)
	
	SetPropertyEnabled();
	
EndProcedure
 
&AtClient
Procedure InfobaseUserOpenIDAuthenticationOnChange(Item)
	
	AuthenticationOnChange();
	
EndProcedure
 
&AtClient
Procedure SetRolesDirectlyOnChange(Item)
	
	If Not Object.SetRolesDirectly Then
		ReadInfobaseUserRoles();
		UsersInternalClient.ExpandRoleSubsystems(ThisObject);
	EndIf;
	
	SetPropertyEnabled();
	
EndProcedure
 
&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonUseClient.ShowCommentEditingForm(
		Item.EditText, ThisObject, "Object.Comment");
	
EndProcedure
 
#EndRegion
 
#Region RolesFormTableItemEventHandlers
 
////////////////////////////////////////////////////////////////////////////////
//Role interface procedures and functions
 
 
&AtClient
Procedure RolesCheckOnChange(Item)
	
	If Items.Roles.CurrentData <> Undefined Then
		ProcessRolesInterface("UpdateRoleContent");
	EndIf;
	
EndProcedure
 
#EndRegion
 
#Region FormCommandHandlers
 
////////////////////////////////////////////////////////////////////////////////
//Role interface procedures and functions
 
 
&AtClient
Procedure ShowSelectedRolesOnly(Command)
	
	ProcessRolesInterface("SelectedRolesOnly");
	UsersInternalClient.ExpandRoleSubsystems(ThisObject);
	
EndProcedure
 
&AtClient
Procedure RoleGroupingBySubsystems(Command)
	
	ProcessRolesInterface("GroupBySubsystems");
	UsersInternalClient.ExpandRoleSubsystems(ThisObject);
	
EndProcedure
 
&AtClient
Procedure EnableRoles(Command)
	
	ProcessRolesInterface("UpdateRoleContent", "EnableAll");
	
	UsersInternalClient.ExpandRoleSubsystems(ThisObject, False);
	
EndProcedure
 
&AtClient
Procedure DisableRoles(Command)
	
	ProcessRolesInterface("UpdateRoleContent", "DisableAll");
	
EndProcedure
 
#EndRegion
 
#Region InternalProceduresAndFunctions
 
&AtClientAtServerNoContext
Procedure UpdateLogonName(Form, OnChangeDescription = False)
	
	Items  = Form.Items;
	Object = Form.Object;
	
	If Form.InfobaseUserExists Then
		Return;
	EndIf;
	
	ShortName = UsersInternalClientServer.GetInfobaseUserShortName(
		Form.CurrentAuthorizationObjectPresentation);
	
	If Items.NameMarkIncompleteSwitch.CurrentPage = Items.NameWithoutMarkIncomplete Then
		If Form.InfobaseUserName = ShortName Then
			Form.InfobaseUserName = "";
		EndIf;
	Else
		
		If OnChangeDescription
		 Or Not ValueIsFilled(Form.InfobaseUserName) Then
			
			Form.InfobaseUserName = ShortName;
		EndIf;
	EndIf;
	
EndProcedure
 
&AtClient
Procedure AuthenticationOnChange()
	
	SetPropertyEnabled();
	
	If Not InfobaseUserOpenIDAuthentication
	   And Not InfobaseUserStandardAuthentication Then
	
		CanLogOnToApplication = False;
		
	ElsIf Not CanLogOnToApplication Then
		CanLogOnToApplication = CanLogOnToApplicationDirectChangeValue;
	EndIf;
	
EndProcedure
 
&AtServer
Procedure SetActionsOnForm()
	
	ActionsOnForm = New Structure;
	
	// "", "View", "Edit".
	ActionsOnForm.Insert("Roles", "");
	
	// "", "View", "Edit".
	ActionsOnForm.Insert("InfobaseUserProperties", "");
	
	// "", "View", "Edit".
	ActionsOnForm.Insert("ItemProperties", "View");
	
	If AccessLevel.ChangeCurrent Or AccessLevel.ListManagement Then
		ActionsOnForm.InfobaseUserProperties = "Edit";
	EndIf;
	
	If AccessLevel.ListManagement Then
		ActionsOnForm.ItemProperties = "Edit";
	EndIf;
	
	If AccessLevel.FullAccess Then
		ActionsOnForm.Roles = "Edit";
	EndIf;
	
	If Not ValueIsFilled(Object.Ref)
	   And Not ValueIsFilled(Object.AuthorizationObject) Then
		
		ActionsOnForm.ItemProperties = "Edit";
	EndIf;
	
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.Users\ActionsInFormOnDefine");
	
	For Each Handler In EventHandlers Do
		Handler.Module.ActionsInFormOnDefine(Object.Ref, ActionsOnForm);
	EndDo;
	
	UsersOverridable.ChangeActionsOnForm(Object.Ref, ActionsOnForm);
	
	// Checking action names in the form.
	If Find(", View, Edit,", ", " + ActionsOnForm.Roles + ",") = 0 Then
		ActionsOnForm.Roles = "";
		
	ElsIf ActionsOnForm.Roles = "Edit"
	        And UsersInternal.RoleEditProhibition() Then
		
		ActionsOnForm.Roles = "View";
	EndIf;
	
	If Find(", View, ViewAll, Edit, EditOwn, EditAll,",
	           ", " + ActionsOnForm.InfobaseUserProperties + ",") = 0 Then
		
		ActionsOnForm.InfobaseUserProperties = "";
		
	Else // Backward compatibility support.
		If Find(ActionsOnForm.InfobaseUserProperties, "View") Then
			ActionsOnForm.InfobaseUserProperties = "View";
			
		ElsIf Find(ActionsOnForm.InfobaseUserProperties, "Edit") Then
			ActionsOnForm.InfobaseUserProperties = "Edit";
		EndIf;
	EndIf;
	
	If Find(", View, Edit,", ", " + ActionsOnForm.ItemProperties + ",") = 0 Then
		ActionsOnForm.ItemProperties = "";
	EndIf;
	
EndProcedure
 
&AtServer
Function InfobaseUserDescription()
	
	If AccessLevel.ListManagement
	   And ActionsOnForm.ItemProperties = "Edit" Then
		
		InfobaseUserFullName = Object.Description;
	EndIf;
	
	If AccessLevel.FullAdministrator
	 Or AccessLevel.FullAccess Then
		
		Result = Users.NewInfobaseUserInfo();
		Users.CopyInfobaseUserProperties(
			Result,
			ThisObject,
			,
			"UUID, Roles",
			"InfobaseUser");
		
		Result.Insert("CanLogOnToApplication", CanLogOnToApplication);
		
	Else
		Result = New Structure;
		
		If AccessLevel.ChangeCurrent Then
			Result.Insert("Password", InfobaseUserPassword);
			Result.Insert("Language", InfobaseUserLanguage);
		EndIf;
		
		If AccessLevel.ListManagement Then
			Result.Insert("CanLogOnToApplication",  CanLogOnToApplication);
			Result.Insert("CannotChangePassword",   InfobaseUserCannotChangePassword);
			Result.Insert("Language",               InfobaseUserLanguage);
			Result.Insert("FullName",               InfobaseUserFullName);
		EndIf;
		
		If AccessLevel.LogonSettings Then
			Result.Insert("StandardAuthentication", InfobaseUserStandardAuthentication);
			Result.Insert("Name",                   InfobaseUserName);
			Result.Insert("Password",               InfobaseUserPassword);
			Result.Insert("OpenIDAuthentication",   InfobaseUserOpenIDAuthentication);
		EndIf;
	EndIf;
	Result.Insert("PasswordConfirmation", PasswordConfirmation);
	
	If AccessLevel.LogonSettings
	   And Not UsersInternal.RoleEditProhibition()
	   And Object.SetRolesDirectly Then
		
		CurrentRoles = InfobaseUserRoles.Unload(, "Role").UnloadColumn("Role");
		Result.Insert("Roles", CurrentRoles);
	EndIf;
	
	If AccessLevel.ListManagement Then
		Result.Insert("ShowInList", False);
		Result.Insert("RunMode", "Auto");
	EndIf;
	
	If AccessLevel.FullAccess Then
		Result.Insert("OSAuthentication", False);
		Result.Insert("OSUser", "");
	EndIf;
	
	Return Result;
	
EndFunction
 
&AtClientAtServerNoContext
Procedure AuthorizationObjectOnChangeAtClientAtServer(Form, Object)
	
	If Object.AuthorizationObject = Undefined Then
		Object.AuthorizationObject = Form.AuthorizationObjectType;
	EndIf;
	
	If Form.CurrentAuthorizationObjectPresentation <> String(Object.AuthorizationObject) Then
		Form.CurrentAuthorizationObjectPresentation = String(Object.AuthorizationObject);
		UpdateLogonName(Form, True);
	EndIf;
	
EndProcedure
 
&AtServer
Procedure UpdateDisplayedUserType()
	
	If Object.AuthorizationObject <> Undefined Then
		Items.AuthorizationObject.Title = Metadata.FindByType(TypeOf(Object.AuthorizationObject)).ObjectPresentation;
	EndIf;
	
EndProcedure
 
&AtClient
Procedure AfterAnswerQuestionAboutWritingWithEmptyRoleList(Answer, WriteParameters) Export
	
	If Answer = DialogReturnCode.Yes Then
		WriteParameters.Insert("WithEmptyRoleList");
		Write(WriteParameters);
	EndIf;
	
EndProcedure
 
////////////////////////////////////////////////////////////////////////////////
// Processing infobase user.
 
&AtServer
Procedure ReadInfobaseUserRoles()
	
	InfobaseUserProperties = Undefined;
	
	Users.ReadInfobaseUser(
		Object.InfobaseUserID, InfobaseUserProperties);
	
	ProcessRolesInterface("FillRoles", InfobaseUserProperties.Roles);
	
EndProcedure
 
&AtServer
Function InitialInfobaseUserDescription()
	
	InfobaseUserDescription = Users.NewInfobaseUserInfo();
	
	If Not ValueIsFilled(Object.Ref) Then
		InfobaseUserDescription.ShowInList = False;
		InfobaseUserDescription.StandardAuthentication = True;
	EndIf;
	InfobaseUserDescription.Roles = New Array;
	
	Return InfobaseUserDescription;
	
EndFunction
 
&AtServer
Procedure ReadInfobaseUser(OnCopyItem = False)
	
	SetPrivilegedMode(True);
	
	Password              = "";
	PasswordConfirmation  = "";
	ReadProperties        = Undefined;
	InfobaseUserDescription   = InitialInfobaseUserDescription();
	InfobaseUserExists    = False;
	InfobaseUserMain      = False;
	CanLogOnToApplication = False;
	CanLogOnToApplicationDirectChangeValue = False;
	
	If OnCopyItem Then
		
		If Users.ReadInfobaseUser(
		         Parameters.CopyingValue.InfobaseUserID,
		         ReadProperties) Then
			
			// Mapping infobase user to user from catalog.
			If Users.CanLogOnToApplication(ReadProperties) Then
				CanLogOnToApplication = True;
				CanLogOnToApplicationDirectChangeValue = True;
			EndIf;
			
			// Copying infobase user properties and roles.
			FillPropertyValues(
				InfobaseUserDescription,
				ReadProperties,
				"CannotChangePassword, RunMode" + ?(Not Items.InfobaseUserLanguage.Visible, "", ", Language") + ?(UsersInternal.RoleEditProhibition(), "", ", Roles"));
		EndIf;
		Object.InfobaseUserID = Undefined;
	Else
		If Users.ReadInfobaseUser(
		       Object.InfobaseUserID, ReadProperties) Then
		
			InfobaseUserExists = True;
			InfobaseUserMain = True;
			
		ElsIf Parameters.Property("InfobaseUserID")
		        And ValueIsFilled(Parameters.InfobaseUserID) Then
			
			Object.InfobaseUserID = Parameters.InfobaseUserID;
			
			If Users.ReadInfobaseUser(
			       Object.InfobaseUserID, ReadProperties) Then
				
				InfobaseUserExists = True;
				If Object.Description <> ReadProperties.FullName Then
					ReadProperties.FullName = Object.Description;
					Modified = True;
				EndIf;
				If ReadProperties.OSAuthentication Then
					ReadProperties.OSAuthentication = False;
					Modified = True;
				EndIf;
				If ValueIsFilled(ReadProperties.OSUser) Then
					ReadProperties.OSUser = "";
					Modified = True;
				EndIf;
			EndIf;
		EndIf;
		
		If InfobaseUserExists Then
			
			If Not Items.InfobaseUserLanguage.Visible Then
				ReadProperties.Language = InfobaseUserDescription.Language;
			EndIf;
			
			If Users.CanLogOnToApplication(ReadProperties) Then
				CanLogOnToApplication = True;
				CanLogOnToApplicationDirectChangeValue = True;
			EndIf;
			
			FillPropertyValues(
				InfobaseUserDescription,
				ReadProperties,
				"Name, FullName, OpenIDAuthentication, StandardAuthentication, ShowInList, CannotChangePassword, OSAuthentication, OSUser, RunMode, RunMode" + ?(Not Items.InfobaseUserLanguage.Visible, "", ", Language") + ?(UsersInternal.RoleEditProhibition(), "", ", Roles"));
			
			If ReadProperties.PasswordIsSet Then
				Password             = "**********";
				PasswordConfirmation = "**********";
			EndIf;
		EndIf;
	EndIf;
	
	Users.CopyInfobaseUserProperties(
		ThisObject,
		InfobaseUserDescription,
		,
		"UUID, Roles",
		"InfobaseUser");
	
	If InfobaseUserMain And Not CanLogOnToApplication Then
		StoredProperties = UsersInternal.InfobaseUserStoredProperties(Object.Ref);
		InfobaseUserOpenIDAuthentication   = StoredProperties.OpenIDAuthentication;
		InfobaseUserStandardAuthentication = StoredProperties.StandardAuthentication;
	EndIf;
	
	ProcessRolesInterface("FillRoles", InfobaseUserDescription.Roles);
	
	CanLogOnToApplicationOnRead = CanLogOnToApplication;
	
EndProcedure
 
&AtServer
Procedure FindUserAndInfobaseUserInconsistencies(WriteParameters = Undefined)
	
	// Checking whether the FullName infobase user property matches the Description external user attribute
  // Also checking the default property values.
	
	ShowMismatch = True;
	ShowDifferenceResolvingCommands = False;
	
	If Not InfobaseUserExists Then
		ShowMismatch = False;
		
	ElsIf Not ValueIsFilled(Object.Ref) Then
		InfobaseUserFullName = Object.Description;
		ShowMismatch = False;
		
	ElsIf AccessLevel.ListManagement Then
		
		PropertiesClarification = New Array;
		HasDifferencesDisposableWithoutAdministrator = False;
		
		If InfobaseUserOSAuthentication <> False Then
			PropertiesClarification.Add(NStr("en = 'OS authentication (enabled)'"));
		EndIf;
		
		If ValueIsFilled(PropertiesClarification) Then
			ShowDifferenceResolvingCommands =
				  AccessLevel.LogonSettings
				And ActionsOnForm.InfobaseUserProperties = "Edit";
		EndIf;
		
		If InfobaseUserFullName <> Object.Description Then
			HasDifferencesDisposableWithoutAdministrator = True;
			
			FullNameClarification = StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Full name: ""%1""'"), InfobaseUserFullName);
			
			PropertiesClarification.Insert(0, StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Full name: ""%1""'"), InfobaseUserFullName));
		EndIf;
		
		If InfobaseUserOSUser <> "" Then
			PropertiesClarification.Add(NStr("en = 'OS user (specified)'"));
		EndIf;
		
		If InfobaseUserShowInList Then
			HasDifferencesDisposableWithoutAdministrator = True;
			PropertiesClarification.Add(NStr("en = 'Show in selection list (enabled)'"));
		EndIf;
		
		If InfobaseUserRunMode <> "Auto" Then
			HasDifferencesDisposableWithoutAdministrator = True;
			PropertiesClarification.Add(NStr("en = 'Run mode (not Auto)'"));
		EndIf;
		
		If PropertiesClarification.Count() > 0 Then
			RowPropertiesClarification = "";
			CurrentRow = "";
			For Each PropertyClarification In PropertiesClarification Do
				If StrLen(CurrentRow + PropertyClarification) > 90 Then
					RowPropertiesClarification = RowPropertiesClarification + TrimR(CurrentRow) + ", " + Chars.LF;
					CurrentRow = "";
				EndIf;
				CurrentRow = CurrentRow + ?(ValueIsFilled(CurrentRow), ", ", "") + PropertyClarification;
			EndDo;
			If ValueIsFilled(CurrentRow) Then
				RowPropertiesClarification = RowPropertiesClarification + CurrentRow;
			EndIf;
			Items.PropertiesMismatchNote.Title =
				StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en = 'The following infobase user properties do not match the properties specified in the form:
					           |%1.'"), RowPropertiesClarification)
				+ Chars.LF
				+ ?(ShowDifferenceResolvingCommands Or HasDifferencesDisposableWithoutAdministrator,
					NStr("en = 'To overwrite the properties, click Save.'"),
					NStr("en = 'If you want to overwrite the properties, contact your system administrator.'"));
		Else
			ShowMismatch = False;
		EndIf;
	Else
		ShowMismatch = False;
	EndIf;
	
	Items.PropertiesMismatchProcessing.Visible = ShowMismatch;
	
	// Checking whether an infobase user that does not exist is mapped to a user from the catalog.
	HasNewMappingToNonExistentInfobaseUser =
		Not InfobaseUserExists And ValueIsFilled(Object.InfobaseUserID);
	
	If WriteParameters <> Undefined
	   And HasMappingToNonExistentInfobaseUser
	   And Not HasNewMappingToNonExistentInfobaseUser Then
		
		WriteParameters.Insert("MappingToNonExistentInfobaseUserCleared", Object.Ref);
	EndIf;
	HasMappingToNonExistentInfobaseUser = HasNewMappingToNonExistentInfobaseUser;
	
	If AccessLevel.ListManagement Then
		Items.MappingMismatchProcessing.Visible = HasMappingToNonExistentInfobaseUser;
	Else
		// Mapping cannot be changed.
		Items.MappingMismatchProcessing.Visible = False;
	EndIf;
	
EndProcedure
 
////////////////////////////////////////////////////////////////////////////////
// Initial filling, fill check, availability of properties
 
&AtServer
Procedure SetPropertyEnabled()
	
	// Specify whether making changes is allowed.
	Items.AuthorizationObject.ReadOnly
		=   ActionsOnForm.ItemProperties <> "Edit"
		Or AuthorizationObjectSetOnOpen
		Or   ValueIsFilled(Object.Ref)
		    And ValueIsFilled(Object.AuthorizationObject);
	
	Items.NotValid.ReadOnly =
		Not (ActionsOnForm.ItemProperties = "Edit" And AccessLevel.ListManagement);
	
	Items.MainProperties.ReadOnly =
		Not (  ActionsOnForm.InfobaseUserProperties = "Edit"
		    And (AccessLevel.ListManagement Or AccessLevel.ChangeCurrent));
	
	Items.CanLogOnToApplication.ReadOnly =
		Not (  Items.MainProperties.ReadOnly = False
		    And (    AccessLevel.FullAccess
		       Or AccessLevel.ListManagement And CanLogOnToApplicationOnRead));
	
	Items.InfobaseUserName1.ReadOnly                  = Not AccessLevel.LogonSettings;
	Items.InfobaseUserName2.ReadOnly                  = Not AccessLevel.LogonSettings;
	Items.InfobaseUserStandardAuthentication.ReadOnly = Not AccessLevel.LogonSettings;
	Items.InfobaseUserOpenIDAuthentication.ReadOnly   = Not AccessLevel.LogonSettings;
	Items.SetRolesDirectly.ReadOnly                   = Not AccessLevel.LogonSettings;
	
	Items.InfobaseUserCannotChangePassword.ReadOnly = Not AccessLevel.ListManagement;
	
	Items.Password.ReadOnly =
		Not (    AccessLevel.LogonSettings
		    Or AccessLevel.ChangeCurrent
		      And Not InfobaseUserCannotChangePassword);
	
	Items.PasswordConfirmation.ReadOnly = Items.Password.ReadOnly;
	
	ProcessRolesInterface(
		"SetRolesReadOnly",
		    RoleEditProhibition
		Or ActionsOnForm.Roles <> "Edit"
		Or Not Object.SetRolesDirectly
		Or Not AccessLevel.LogonSettings);
	
	Items.Comment.ReadOnly =
		Not (ActionsOnForm.ItemProperties = "Edit" And AccessLevel.ListManagement);
	
	// Specifying whether filling is necessary.
	If InfobaseUserWriteRequired(ThisObject, False) Then
		NewPage = Items.NameWithMarkIncomplete;
	Else
		NewPage = Items.NameWithoutMarkIncomplete;
	EndIf;
	
	If Items.NameMarkIncompleteSwitch.CurrentPage <> NewPage Then
		Items.NameMarkIncompleteSwitch.CurrentPage = NewPage;
	EndIf;
	UpdateLogonName(ThisObject);
	
	// Specifying whether related items are available.
	Items.CanLogOnToApplication.Enabled = Not Object.NotValid;
	Items.MainProperties.Enabled        = Not Object.NotValid;
	Items.EditOrViewRoles.Enabled       = Not Object.NotValid;
	
	Items.Password.Enabled              = InfobaseUserStandardAuthentication;
	Items.PasswordConfirmation.Enabled  = InfobaseUserStandardAuthentication;
	
	Items.InfobaseUserCannotChangePassword.Enabled
		= InfobaseUserStandardAuthentication;
	
EndProcedure
 
&AtClientAtServerNoContext
Function InfobaseUserWriteRequired(Form, UseStandartName = True)
	
	If Form.ActionsOnForm.InfobaseUserProperties <> "Edit" Then
		Return False;
	EndIf;
	
	Template = Form.InitialInfobaseUserDescription;
	
	CurrentName = "";
	If Not UseStandartName Then
		ShortName = UsersInternalClientServer.GetInfobaseUserShortName(
			Form.CurrentAuthorizationObjectPresentation);
		
		If Form.InfobaseUserName = ShortName Then
			CurrentName = ShortName;
		EndIf;
	EndIf;
	
	If Form.InfobaseUserExists
	 Or Form.CanLogOnToApplication
	 Or Form.InfobaseUserName                   <> CurrentName
	 Or Form.InfobaseUserStandardAuthentication <> Template.StandardAuthentication
	 Or Form.InfobaseUserCannotChangePassword   <> Template.CannotChangePassword
	 Or Form.Password <> ""
	 Or Form.PasswordConfirmation <> ""
	 Or Form.InfobaseUserOpenIDAuthentication <> Template.OpenIDAuthentication
	 Or Form.Language                         <> Template.Language
	 Or Form.InfobaseUserRoles.Count() <> 0 Then
		
		Return True;
	EndIf;
	
	Return False;
	
EndFunction
 
////////////////////////////////////////////////////////////////////////////////
// Role interface procedures and functions.
 
&AtServer
Procedure ProcessRolesInterface(Action, MainParameter = Undefined)
	
	ActionParameters = New Structure;
	ActionParameters.Insert("MainParameter",      MainParameter);
	ActionParameters.Insert("Form",               ThisObject);
	ActionParameters.Insert("RoleCollection",     InfobaseUserRoles);
	ActionParameters.Insert("UserType",           Enums.UserTypes.ExternalUser);
	ActionParameters.Insert("HideFullAccessRole", True);
	
	UsersInternal.ProcessRolesInterface(Action, ActionParameters);
	
EndProcedure
 
#EndRegion