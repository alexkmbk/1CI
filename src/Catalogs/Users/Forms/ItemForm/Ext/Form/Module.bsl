 
#Region FormEventHandlers
 
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
 
	SetConditionalAppearance();
	// Skipping the initialization to guarantee that the form will be received if the Autotest parameter is passed.
	If Parameters.Property("Autotest") Then 		
		Return;
	EndIf;
	
	If CommonUseCached.DataSeparationEnabled() Then
 
		CanChangeUsers = Undefined;
		UsersInternal.OnDefineCanChangeUsers(CanChangeUsers);
		
		If Not CanChangeUsers Then
			If Object.Ref.IsEmpty() Then
				Raise
					NStr("en = 'You cannot add new users in the demo mode.'");
			EndIf;
			ReadOnly = True;
		EndIf;
		
		Items.InfobaseUserShowInList.Visible             = False;
		Items.InfobaseUserOpenIDAuthentication.Visible   = False;
		Items.InfobaseUserStandardAuthentication.Visible = False;
		Items.InfobaseUserCannotChangePassword.Visible   = False;
		Items.OSAuthenticationProperties.Visible         = False;
		Items.InfobaseUserRunMode.Visible                = False;
	EndIf;
	
	If UsersInternal.IsTrainingPlatform() Then
		Items.OSAuthenticationProperties.ReadOnly = True;
	EndIf;
	
	// Filling auxiliary data
	
	// Filling run mode choice list
	For Each RunMode In ClientRunMode Do
		ValueFullName = GetPredefinedValueFullName(RunMode);
		EnumValueName = Mid(ValueFullName, Find(ValueFullName, ".") + 1);
		Items.InfobaseUserRunMode.ChoiceList.Add(EnumValueName, String(RunMode));
	EndDo;
	Items.InfobaseUserRunMode.ChoiceList.SortByPresentation();
	
	// Filling language choice list
	If Metadata.Languages.Count() < 2 Then
		Items.InfobaseUserLanguage.Visible = False;
	Else
		For Each LanguageMetadata In Metadata.Languages Do
			Items.InfobaseUserLanguage.ChoiceList.Add(
				LanguageMetadata.Name, LanguageMetadata.Synonym);
		EndDo;
	EndIf;
	
	AccessLevel = UsersInternal.UserPropertyAccessLevel(Object);
	
	// Preparing for execution of interactive actions according to the form opening scenarios
	SetPrivilegedMode(True);
	
	If Not ValueIsFilled(Object.Ref) Then
		// Adding a new item
		If Parameters.NewUserGroup <> Catalogs.UserGroups.AllUsers Then
			NewUserGroup = Parameters.NewUserGroup;
		EndIf;
		
		If ValueIsFilled(Parameters.CopyingValue) Then
			// Copying the item
			CopyingValue = Parameters.CopyingValue;
			Object.Description = "";
			
			If Users.InfobaseUserWithFullAccess(CopyingValue, True, False) Then
				InfobaseUserCopyingAllowed = AccessLevel.FullAdministrator;
			ElsIf Users.InfobaseUserWithFullAccess(CopyingValue, False, False) Then
				InfobaseUserCopyingAllowed = AccessLevel.FullAccess;
			Else
				InfobaseUserCopyingAllowed = True;
			EndIf;
			
			If InfobaseUserCopyingAllowed Then
				ReadInfobaseUser(
					ValueIsFilled(CopyingValue.InfobaseUserID));
			Else
				ReadInfobaseUser();
			EndIf;
			
			If Not AccessLevel.FullAccess Then
				CanLogOnToApplication = False;
				CanLogOnToApplicationDirectChangeValue = False;
			EndIf;
		Else
			// Adding an item
			
			// Reading initial infobase user property values
			ReadInfobaseUser();
			
			If Not ValueIsFilled(Parameters.InfobaseUserID) Then
				InfobaseUserStandardAuthentication = True;
				
				If CommonUseCached.DataSeparationEnabled() Then
					InfobaseUserShowInList = False;
					InfobaseUserOpenIDAuthentication = True;
				EndIf;
				
				If AccessLevel.FullAccess Then
					CanLogOnToApplication = True;
					CanLogOnToApplicationDirectChangeValue = True;
				EndIf;
			EndIf;
		EndIf;
	Else
		// Opening the existing item
		ReadInfobaseUser();
	EndIf;
	
	SetPrivilegedMode(False);
	
	ProcessRolesInterface("SetUpRoleInterfaceOnFormCreate", InfobaseUserExists);
	InitialInfobaseUserDescription = InitialInfobaseUserDescription();
	SynchronizationWithServiceRequired = Object.Ref.IsEmpty();
	
	If CommonUse.SubsystemExists("StandardSubsystems.ContactInformation") Then
		ContactInformationManagementModule = CommonUse.CommonModule("ContactInformationManagement");
		ContactInformationManagementModule.OnCreateAtServer(ThisObject, Object, "ContactInformation");
		OverrideContactInformationEditingInSaaS();
	EndIf;
	
	GeneralFormSetup(True);
	
EndProcedure
 
&AtClient
Procedure OnOpen(Cancel)
	
	#If WebClient Then
	Items.InfobaseUserOSUser.ChoiceButton = False;
	#EndIf
	
EndProcedure
 
&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	If CommonUse.SubsystemExists("StandardSubsystems.ContactInformation") Then
		ContactInformationManagementModule = CommonUse.CommonModule("ContactInformationManagement");
		ContactInformationManagementModule.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	
	GeneralFormSetup();
	
EndProcedure
 
&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	ClearMessages();
	
	If CanLogOnToApplication Then
		QuestionTitle = NStr("en = 'Save infobase user'");
		
		If ActionsOnForm.Roles = "Edit"
		   And InfobaseUserRoles.Count() = 0 Then
			
			If Not WriteParameters.Property("WithEmptyRoleList") Then
				Cancel = True;
				ShowQueryBox(
					New NotifyDescription("QuestionAboutWritingWithEmptyRoleListAfterAnswer", ThisObject, WriteParameters),
					NStr("en = 'No roles are set for the infobase user. Do you want to continue?'"),
					QuestionDialogMode.YesNo,
					,
					,
					QuestionTitle);
				Return;
			EndIf;
		EndIf;
		
		// Processing the saving of the first administrator
		If Not WriteParameters.Property("WithFirstAdministratorAdding") Then
			QuestionText = "";
			If CreateFirstAdministratorRequired(QuestionText) Then
				Cancel = True;
				ShowQueryBox(
					New NotifyDescription("FirstAdministratorAfterAddingConfirmation", ThisObject, WriteParameters),
					QuestionText, QuestionDialogMode.YesNo, , , QuestionTitle);
				Return;
			EndIf;
		EndIf;
	EndIf;
	
	If StandardSubsystemsClientCached.ClientParameters().DataSeparationEnabled
		And SynchronizationWithServiceRequired
		And ServiceUserPassword = Undefined Then
		
		Cancel = True;
		StandardSubsystemsClient.PasswordForAuthenticationInServiceOnRequest(
			New NotifyDescription("AfterPasswordForAuthenticationInServiceRequestBeforeWrite", ThisObject, WriteParameters),
			ThisObject,
			ServiceUserPassword);
		Return;
	EndIf;
	
EndProcedure
 
&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CurrentObject.AdditionalProperties.Insert("CopyingValue", CopyingValue);
	
	CurrentObject.AdditionalProperties.Insert("ServiceUserPassword", ServiceUserPassword);
	CurrentObject.AdditionalProperties.Insert("SynchronizeWithService", SynchronizationWithServiceRequired);
	
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
			CurrentObject.Ref, "Description, DeletionMark"));
	EndIf;
	
	CurrentObject.AdditionalProperties.Insert("NewUserGroup", NewUserGroup);
	
	If CommonUse.SubsystemExists("StandardSubsystems.ContactInformation") Then
		ContactInformationManagementModule = CommonUse.CommonModule("ContactInformationManagement");
		If Not Cancel And ActionsOnForm.ContactInformation = "Edit" Then
			ContactInformationManagementModule.BeforeWriteAtServer(ThisObject, CurrentObject);
		EndIf;
	EndIf;
	
EndProcedure
 
&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	SynchronizationWithServiceRequired = False;
	
	If InfobaseUserWriteRequired(ThisObject) Then
		WriteParameters.Insert(
			CurrentObject.AdditionalProperties.InfobaseUserDescription.ActionResult);
	EndIf;
	
	GeneralFormSetup(, WriteParameters);
	
EndProcedure
 
&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_Users", New Structure, Object.Ref);
	
	If WriteParameters.Property("InfobaseUserAdded") Then
		Notify("InfobaseUserAdded", WriteParameters.InfobaseUserAdded, ThisObject);
		
	ElsIf WriteParameters.Property("InfobaseUserChanged") Then
		Notify("InfobaseUserChanged", WriteParameters.InfobaseUserChanged, ThisObject);
		
	ElsIf WriteParameters.Property("InfobaseUserDeleted") Then
		Notify("InfobaseUserDeleted", WriteParameters.InfobaseUserDeleted, ThisObject);
		
	ElsIf WriteParameters.Property("MappingToNonExistentInfobaseUserCleared") Then
		Notify(
			"MappingToNonExistentInfobaseUserCleared",
			WriteParameters.MappingToNonExistentInfobaseUserCleared,
			ThisObject);
	EndIf;
	
	If ValueIsFilled(NewUserGroup) Then
		
		NotifyChanged(NewUserGroup);
		Notify("Write_UserGroups", New Structure, NewUserGroup);
		NewUserGroup = Undefined;
	EndIf;
	
EndProcedure
 
&AtServer
Procedure FillCheckProcessingAtServer(Cancel, AttributesToCheck)
	
	If InfobaseUserWriteRequired(ThisObject) Then
		InfobaseUserDescription = InfobaseUserDescription();
		InfobaseUserDescription.Insert("InfobaseUserID", Object.InfobaseUserID);
		UsersInternal.CheckInfobaseUserDescription(InfobaseUserDescription, Cancel);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.ContactInformation") Then
		ContactInformationManagementModule = CommonUse.CommonModule("ContactInformationManagement");
		ContactInformationManagementModule.FillCheckProcessingAtServer(ThisObject, Object, Cancel);
	EndIf;
	
EndProcedure
 
&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	ProcessRolesInterface("SetUpRoleInterfaceOnLoadSettings", Settings);
	
EndProcedure
 
#EndRegion
 
#Region FormHeaderItemEventHandlers
 
&AtClient
Procedure FillFromInfobaseUser(Command)
	
	FillFieldsByInfobaseUserAtServer();
	
EndProcedure
 
&AtClient
Procedure DescriptionOnChange(Item)
	
	UpdateLogonName(ThisObject, True);
	
	SetSynchronizationWithServiceNecessity(ThisObject);
	
EndProcedure
 
&AtClient
Procedure NotValidOnChange(Item)
	
	If Object.NotValid Then
		CanLogOnToApplication = False;
	Else
		CanLogOnToApplication = CanLogOnToApplicationDirectChangeValue
			And (InfobaseUserOpenIDAuthentication
			   Or InfobaseUserStandardAuthentication
			   Or InfobaseUserOSAuthentication);
	EndIf;
	
	SetPropertyEnabled(ThisObject);
	
	SetSynchronizationWithServiceNecessity(ThisObject);
	
EndProcedure
 
&AtClient
Procedure CanLogOnToApplicationOnChange(Item)
	
	If Object.DeletionMark And CanLogOnToApplication Then
		CanLogOnToApplication = False;
		ShowMessageBox(,
			NStr("en = 'To allow access to the infobase, remove the deletion mark from the user.'"));
		Return;
	EndIf;
	
	UpdateLogonName(ThisObject);
	
	If CanLogOnToApplication
	   And Not InfobaseUserOpenIDAuthentication
	   And Not InfobaseUserStandardAuthentication
	   And Not InfobaseUserOSAuthentication Then
	
		InfobaseUserStandardAuthentication = True;
	EndIf;
	
	SetPropertyEnabled(ThisObject);
	
	SetSynchronizationWithServiceNecessity(ThisObject);
	
	If Not AccessLevel.FullAccess
	   And AccessLevel.ListManagement
	   And Not CanLogOnToApplication Then
		
		ShowMessageBox(,
			NStr("en = 'Once you save the changes, only administrator can allow logging on to the application.'"));
	EndIf;
	
	CanLogOnToApplicationDirectChangeValue = CanLogOnToApplication;
	
EndProcedure
 
&AtClient
Procedure InfobaseUserStandardAuthenticationOnChange(Item)
	
	AuthenticationOnChange();
	
EndProcedure
 
&AtClient
Procedure PasswordOnChange(Item)
	
	InfobaseUserPassword = Password;
	
	SetPropertyEnabled(ThisObject);
	
	SetSynchronizationWithServiceNecessity(ThisObject);
	
EndProcedure
 
&AtClient
Procedure InfobaseUserShowInListOnChange(Item)
	
	SetPropertyEnabled(ThisObject);
	
EndProcedure
 
&AtClient
Procedure InfobaseUserCannotChangePasswordOnChange(Item)
	
	SetPropertyEnabled(ThisObject);
	
EndProcedure
 
&AtClient
Procedure InfobaseUserOpenIDAuthenticationOnChange(Item)
	
	AuthenticationOnChange();
	
EndProcedure
 
&AtClient
Procedure InfobaseUserOSAuthenticationOnChange(Item)
	
	AuthenticationOnChange();
	
EndProcedure
 
&AtClient
Procedure InfobaseUserOSUserOnChange(Item)
	
	SetPropertyEnabled(ThisObject);
	
EndProcedure
 
&AtClient
Procedure InfobaseUserOSUserStartChoice(Item, ChoiceData, StandardProcessing)
	
	#If Not WebClient Then
		OpenForm("Catalog.Users.Form.OSUserSelectionForm", , Item);
	#EndIf
	
EndProcedure
 
&AtClient
Procedure InfobaseUserNameOnChange(Item)
	
	SetPropertyEnabled(ThisObject);
	
	SetSynchronizationWithServiceNecessity(ThisObject);
	
EndProcedure
 
&AtClient
Procedure InfobaseUserLanguageOnChange(Item)
	
	SetPropertyEnabled(ThisObject);
	
	SetSynchronizationWithServiceNecessity(ThisObject);
	
EndProcedure
 
&AtClient
Procedure InfobaseUserRunModeOnChange(Item)
	
	SetPropertyEnabled(ThisObject);
	
EndProcedure
 
&AtClient
Procedure InfobaseUserRunModeClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure
 
&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonUseClient.ShowCommentEditingForm(
		Item.EditText, ThisObject, "Object.Comment");
	
EndProcedure
 
////////////////////////////////////////////////////////////////////////////////
// Contact information support
 
&AtClient
Procedure Attachable_EmailOnChange(Item)
	
	ContactInformationManagementModuleClient =
		CommonUseClient.CommonModule("ContactInformationManagementClient");
		
	ContactInformationManagementModuleClient.PresentationOnChange(ThisObject, Item);
	
	If Not Object.Ref.IsEmpty() Then
		Return;
	EndIf;
	
	CITable = ThisObject.ContactInformationAdditionalAttributeInfo;
	
	RowEmail = CITable.FindRows(New Structure("Kind",
		ContactInformationKindUserEmail()))[0];
	
	If ValueIsFilled(ThisObject[RowEmail.AttributeName]) Then
		Password = "" + New UUID + "qQ";
		PasswordConfirmation = Password;
		InfobaseUserPassword = Password;
	EndIf;
	SetPropertyEnabled(ThisObject);
	
EndProcedure
 
&AtClient
Procedure Attachable_PhoneOnChange(Item)
	
	ContactInformationManagementModuleClient =
		CommonUseClient.CommonModule("ContactInformationManagementClient");
	
	ContactInformationManagementModuleClient.PresentationOnChange(ThisObject, Item);
	
	SetSynchronizationWithServiceNecessity(ThisObject);
	
EndProcedure
 
&AtClient
Procedure Attachable_EmailStartChoice(Item)
	
	If StandardSubsystemsClientCached.ClientParameters().DataSeparationEnabled
	   And ServiceUserPassword = Undefined Then
	
		StandardSubsystemsClient.PasswordForAuthenticationInServiceOnRequest(
			New NotifyDescription("Attachable_EmailStartChoiceEnd", ThisObject),
			ThisObject,
			ServiceUserPassword);
	Else
		Attachable_EmailStartChoiceEnd("", Undefined);
	EndIf;
	
EndProcedure
 
&AtClient
Procedure Attachable_EmailStartChoiceEnd(SaaSUserNewPassword, NotDefined) Export
	
	If SaaSUserNewPassword = Undefined Then
		Return;
	EndIf;
	
	ServiceUserPassword = SaaSUserNewPassword;
	
	CITable = ThisObject.ContactInformationAdditionalAttributeInfo;
	
	Filter = New Structure("Kind", ContactInformationKindUserEmail());
	
	RowEmail = CITable.FindRows(Filter)[0];
	
	FormParameters = New Structure;
	FormParameters.Insert("ServiceUserPassword", ServiceUserPassword);
	FormParameters.Insert("OldEmail",  ThisObject[RowEmail.AttributeName]);
	FormParameters.Insert("User", Object.Ref);
	
	Try
		
		OpenForm("Catalog.Users.Form.EmailAddressChange", FormParameters, ThisObject);
		
	Except
		
		ServiceUserPassword = Undefined;
		Raise;
		
	EndTry;
	
EndProcedure
 
&AtClient
Procedure Attachable_ContactInformationOnChange(Item)
	
	ContactInformationManagementModuleClient =
		CommonUseClient.CommonModule("ContactInformationManagementClient");
	
	ContactInformationManagementModuleClient.PresentationOnChange(ThisObject, Item);
	
EndProcedure
 
&AtClient
Procedure Attachable_ContactInformationStartChoice(Item, ChoiceData, StandardProcessing)
	
	ContactInformationManagementModuleClient =
		CommonUseClient.CommonModule("ContactInformationManagementClient");
	
	Result = ContactInformationManagementModuleClient.PresentationStartChoice(
		ThisObject, Item, , StandardProcessing);
	
	RefreshContactInformation(Result);
	
EndProcedure
 
&AtClient
Procedure Attachable_ContactInformationClearing(Item, StandardProcessing)
	
	ContactInformationManagementModuleClient =
		CommonUseClient.CommonModule("ContactInformationManagementClient");
	
	Result = ContactInformationManagementModuleClient.PresentationClearing(
		ThisObject, Item.Name);
	
	RefreshContactInformation(Result);
	
EndProcedure
 
&AtClient
Procedure Attachable_ContactInformationExecuteCommand(Command)
	
	ContactInformationManagementModuleClient =
		CommonUseClient.CommonModule("ContactInformationManagementClient");
	
	Result = ContactInformationManagementModuleClient.AttachableCommand(
		ThisObject, Command.Name);
	
	RefreshContactInformation(Result);
	
	ContactInformationManagementModuleClient.OpenAddressInputForm(ThisObject, Result);
	
EndProcedure
 
#EndRegion
 
#Region RolesFormTableItemEventHandlers
 
////////////////////////////////////////////////////////////////////////////////
// Role interface procedures and functions
 
&AtClient
Procedure RolesCheckOnChange(Item)
	
	If Items.Roles.CurrentData <> Undefined Then
		ProcessRolesInterface("UpdateRoleContent");
		
		If Items.Roles.CurrentData <> Undefined 
		   And Items.Roles.CurrentData.Name = "FullAccess" Then
			SetSynchronizationWithServiceNecessity(ThisObject);
		EndIf;
	EndIf;
	
EndProcedure
 
#EndRegion
 
#Region FormCommandHandlers
 
 
 
 
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
 
&AtServer
Procedure SetConditionalAppearance()
 
	ConditionalAppearance.Items.Clear();
 
 
 
	Item = ConditionalAppearance.Items.Add();
 
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RolesCheck.Name);
 
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
 
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Roles.Name");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = NStr("en = 'FullAccess'");
 
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdministrativeAccessChangeProhibition");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
 
	Item.Appearance.SetParameterValue("Enabled", False);
 
	
 
	Item = ConditionalAppearance.Items.Add();
 
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RolesCheck.Name);
 
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RolesSynonym.Name);
 
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
 
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Roles.Name");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = NStr("en = 'FullAccess'");
 
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdministrativeAccessChangeProhibition");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
 
	Item.Appearance.SetParameterValue("BackColor", StyleColors.InaccessibleDataColor);
 
EndProcedure
 
&AtServer
Procedure GeneralFormSetup(OnCreateAtServer = False, WriteParameters = Undefined)
	
	If InitialInfobaseUserDescription = Undefined Then
		Return; // OnReadAtServer before OnCreateAtServer
	EndIf;
	
	If Not OnCreateAtServer Then
		ReadInfobaseUser();
	EndIf;
	
	AccessLevel = UsersInternal.UserPropertyAccessLevel(Object);
	
	SetActionsOnForm();
	
	FindUserAndInfobaseUserInconsistencies(WriteParameters);
	
	ProcessRolesInterface(
		"SetRolesReadOnly",
		    UsersInternal.RoleEditProhibition()
		Or ActionsOnForm.Roles <> "Edit"
		Or Not AccessLevel.LogonSettings);
	
	If CommonUseCached.DataSeparationEnabled() Then
		ActionsWithSaaSUser = Undefined;
		UsersInternal.OnReceiveActionsWithSaaSUser(
			ActionsWithSaaSUser, Object.Ref);
	EndIf;
	
	// Setting visibility
	Items.ContactInformation.Visible     = ValueIsFilled(ActionsOnForm.ContactInformation);
	Items.InfobaseUserProperties.Visible = ValueIsFilled(ActionsOnForm.InfobaseUserProperties);
	
	OutputRoleList = ValueIsFilled(ActionsOnForm.Roles);
	Items.RoleRepresentation.Visible = OutputRoleList;
	Items.PlatformAuthenticationProperties.Representation =
		?(OutputRoleList, UsualGroupRepresentation.None, UsualGroupRepresentation.NormalSeparation);
	
	Items.CheckSettingsAfterLogOnRecommendation.Visible =
		AccessLevel.FullAccess And Object.Prepared And Not CanLogOnToApplicationOnRead;
	
	// Setting the read-only parameter
	If Object.Internal Then
		ReadOnly = True;
	EndIf;
	
	ReadOnly = ReadOnly
		Or ActionsOnForm.Roles                     <> "Edit"
		  And ActionsOnForm.ItemProperties         <> "Edit"
		  And ActionsOnForm.ContactInformation     <> "Edit"
		  And ActionsOnForm.InfobaseUserProperties <> "Edit";
	
	Items.Description.ReadOnly =
		Not (ActionsOnForm.ItemProperties = "Edit" And AccessLevel.ListManagement);
	
	Items.NotValid.ReadOnly = Items.Description.ReadOnly;
	
	Items.MainProperties.ReadOnly =
		Not (  ActionsOnForm.InfobaseUserProperties = "Edit"
		    And (AccessLevel.ListManagement Or AccessLevel.ChangeCurrent));
	
	Items.InfobaseUserName1.ReadOnly                  = Not AccessLevel.LogonSettings;
	Items.InfobaseUserName2.ReadOnly                  = Not AccessLevel.LogonSettings;
	Items.InfobaseUserStandardAuthentication.ReadOnly = Not AccessLevel.LogonSettings;
	Items.InfobaseUserOpenIDAuthentication.ReadOnly   = Not AccessLevel.LogonSettings;
	Items.InfobaseUserOSAuthentication.ReadOnly       = Not AccessLevel.LogonSettings;
	Items.InfobaseUserOSUser.ReadOnly                 = Not AccessLevel.LogonSettings;
	
	Items.InfobaseUserShowInList.ReadOnly           = Not AccessLevel.ListManagement;
	Items.InfobaseUserCannotChangePassword.ReadOnly = Not AccessLevel.ListManagement;
	Items.InfobaseUserRunMode.ReadOnly              = Not AccessLevel.ListManagement;
	
	Items.Comment.ReadOnly =
		Not (ActionsOnForm.ItemProperties = "Edit" And AccessLevel.ListManagement);
	
	SetPropertyEnabled(ThisObject);
	
EndProcedure
 
// The BeforeWrite event handler continued
&AtClient
Procedure AfterPasswordForAuthenticationInServiceRequestBeforeWrite(SaaSUserNewPassword, WriteParameters) Export
	
	If SaaSUserNewPassword = Undefined Then
		Return;
	EndIf;
	
	ServiceUserPassword = SaaSUserNewPassword;
	
	Try
		
		Write(WriteParameters);
		
	Except
		
		ServiceUserPassword = Undefined;
		Raise;
		
	EndTry;
	
EndProcedure
 
&AtClientAtServerNoContext
Procedure UpdateLogonName(Form, OnChangeDescription = False)
	
	Items = Form.Items;
	Object   = Form.Object;
	
	If Form.InfobaseUserExists Then
		Return;
	EndIf;
	
	ShortName = UsersInternalClientServer.GetInfobaseUserShortName(Form.Object.Description);
	
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
	
	SetPropertyEnabled(ThisObject);
	
	If Not InfobaseUserOpenIDAuthentication
	   And Not InfobaseUserStandardAuthentication
	   And Not InfobaseUserOSAuthentication Then
	
		CanLogOnToApplication = False;
		
	ElsIf Not CanLogOnToApplication Then
		CanLogOnToApplication = CanLogOnToApplicationDirectChangeValue;
	EndIf;
	
EndProcedure
 
&AtServer
Procedure SetActionsOnForm()
	
	ActionsOnForm = New Structure;
	
	// "", "View", "Edit"
	ActionsOnForm.Insert("Roles", "");
	
	// "", "View", "Edit"
	ActionsOnForm.Insert("ContactInformation", "View");
	
	// "", "ViewAll", "Edit"
	ActionsOnForm.Insert("InfobaseUserProperties", "");
	
	// "", "View", "Edit"
	ActionsOnForm.Insert("ItemProperties", "View");
	
	If Not AccessLevel.FullAdministrator
	   And AccessLevel.FullAccess
	   And Users.InfobaseUserWithFullAccess(Object.Ref, True) Then
		
		// System administrator is read-only
		ActionsOnForm.Roles                   = "View";
		ActionsOnForm.InfobaseUserProperties  = "View";
	
	ElsIf AccessLevel.FullAdministrator
	      Or AccessLevel.FullAccess Then
		
		ActionsOnForm.Roles                  = "Edit";
		ActionsOnForm.ContactInformation     = "Edit";
		ActionsOnForm.InfobaseUserProperties = "Edit";
		ActionsOnForm.ItemProperties         = "Edit";
	Else
		If AccessLevel.ChangeCurrent Then
			ActionsOnForm.InfobaseUserProperties = "Edit";
			ActionsOnForm.ContactInformation     = "Edit";
		EndIf;
		
		If AccessLevel.ListManagement Then
			// User list and user group list manager.
			// Typically this is a person who executes employment, transfer, and 
     // reassignment orders, as well as division, department, and work group 
     // creation orders.
			ActionsOnForm.InfobaseUserProperties = "Edit";
			ActionsOnForm.ContactInformation     = "Edit";
			ActionsOnForm.ItemProperties         = "Edit";
			
			If AccessLevel.LogonSettings Then
				ActionsOnForm.Roles = "Edit";
			EndIf;
			If Users.InfobaseUserWithFullAccess(Object.Ref) Then
				ActionsOnForm.Roles = "View";
			EndIf;
		EndIf;
	EndIf;
	
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.Users\OnDefineActionsInForm");
	
	For Each Handler In EventHandlers Do
		Handler.Module.OnDefineActionsInForm(Object.Ref, ActionsOnForm);
	EndDo;
	
	UsersOverridable.ChangeActionsOnForm(Object.Ref, ActionsOnForm);
	
	// Checking action names in the form
	If Find(", View, Edit,", ", " + ActionsOnForm.Roles + ",") = 0 Then
		ActionsOnForm.Roles = "";
		
	ElsIf ActionsOnForm.Roles = "Edit"
	        And UsersInternal.RoleEditProhibition() Then
		
		ActionsOnForm.Roles = "View";
	EndIf;
	
	If Find(", View, Edit,", ", " + ActionsOnForm.ContactInformation + ",") = 0 Then
		ActionsOnForm.ContactInformation = "";
	EndIf;
	
	If Find(", View, ViewAll, Edit, EditOwn, EditAll,",
	           ", " + ActionsOnForm.InfobaseUserProperties + ",") = 0 Then
		
		ActionsOnForm.InfobaseUserProperties = "";
		
	Else // Backward compatibility support
		If Find(ActionsOnForm.InfobaseUserProperties, "View") Then
			ActionsOnForm.InfobaseUserProperties = "View";
			
		ElsIf Find(ActionsOnForm.InfobaseUserProperties, "Edit") Then
			ActionsOnForm.InfobaseUserProperties = "Edit";
		EndIf;
	EndIf;
	
	If Find(", View, Edit,", ", " + ActionsOnForm.ItemProperties + ",") = 0 Then
		ActionsOnForm.ItemProperties = "";
	EndIf;
	
	If Object.Internal Then
		If ActionsOnForm.Roles = "Edit" Then
			ActionsOnForm.Roles = "View";
		EndIf;
		
		If ActionsOnForm.ContactInformation = "Edit" Then
			ActionsOnForm.ContactInformation = "View";
		EndIf;
		
		If ActionsOnForm.InfobaseUserProperties = "Edit" Then
			ActionsOnForm.InfobaseUserProperties = "View";
		EndIf;
		
		If ActionsOnForm.ItemProperties = "Edit" Then
			ActionsOnForm.ItemProperties = "View";
		EndIf;
	EndIf;
	
EndProcedure
 
&AtServer
Function InfobaseUserDescription(ToCheckFirstAdministrator = False)
	
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
			Result.Insert("Language",   InfobaseUserLanguage);
		EndIf;
		
		If AccessLevel.ListManagement Then
			Result.Insert("CanLogOnToApplication", CanLogOnToApplication);
			Result.Insert("ShowInList",            InfobaseUserShowInList);
			Result.Insert("CannotChangePassword",  InfobaseUserCannotChangePassword);
			Result.Insert("Language",              InfobaseUserLanguage);
			Result.Insert("RunMode",               InfobaseUserRunMode);
			
			If ActionsOnForm.ItemProperties = "Edit" Then
				Result.Insert("FullName", InfobaseUserFullName);
			EndIf;
		EndIf;
		
		If AccessLevel.LogonSettings Then
			Result.Insert("StandardAuthentication", InfobaseUserStandardAuthentication);
			Result.Insert("Name",                   InfobaseUserName);
			Result.Insert("Password",               InfobaseUserPassword);
			Result.Insert("OpenIDAuthentication",   InfobaseUserOpenIDAuthentication);
			Result.Insert("OSAuthentication",       InfobaseUserOSAuthentication);
			Result.Insert("OSUser",                 InfobaseUserOSUser);
		EndIf;
	EndIf;
	Result.Insert("PasswordConfirmation", PasswordConfirmation);
	
	If Not ToCheckFirstAdministrator
	   And UsersInternal.CreateFirstAdministratorRequired(Result) Then
		
		AdministratorRoles = New Array;
		AdministratorRoles.Add("FullAccess");
		
		FullAdministratorRoleName = Users.FullAdministratorRole().Name;
		If AdministratorRoles.Find(FullAdministratorRoleName) = Undefined Then
			AdministratorRoles.Add(FullAdministratorRoleName);
		EndIf;
		Result.Insert("Roles", AdministratorRoles);
	
	ElsIf AccessLevel.LogonSettings
	        And Not UsersInternal.RoleEditProhibition() Then
		
		CurrentRoles = InfobaseUserRoles.Unload(, "Role").UnloadColumn("Role");
		Result.Insert("Roles", CurrentRoles);
	EndIf;
	
	Return Result;
	
EndFunction
 
&AtServer
Function CreateFirstAdministratorRequired(QuestionText = Undefined)
	
	Return UsersInternal.CreateFirstAdministratorRequired(
		InfobaseUserDescription(True),
		QuestionText);
	
EndFunction
 
&AtClientAtServerNoContext
Procedure SetSynchronizationWithServiceNecessity(Form)
	
	Form.SynchronizationWithServiceRequired = True;
	
EndProcedure
 
&AtClient
Procedure QuestionAboutWritingWithEmptyRoleListAfterAnswer(Answer, WriteParameters) Export
	
	If Answer = DialogReturnCode.Yes Then
		WriteParameters.Insert("WithEmptyRoleList");
		Write(WriteParameters);
	EndIf;
	
EndProcedure
 
&AtClient
Procedure FirstAdministratorAfterAddingConfirmation(Answer, WriteParameters) Export
	
	If Answer <> DialogReturnCode.No Then
		WriteParameters.Insert("WithFirstAdministratorAdding");
		Write(WriteParameters);
	EndIf;
	
EndProcedure
 
////////////////////////////////////////////////////////////////////////////////
// Contact information support
 
&AtServer
Function RefreshContactInformation(Result = Undefined)
	
	ContactInformationManagementModuleServer =
		CommonUse.CommonModule("ContactInformationManagement");
	
	Return ContactInformationManagementModuleServer.UpdateContactInformation(
		ThisObject, Object, Result);
	
EndFunction
 
&AtServer
Procedure OverrideContactInformationEditingInSaaS()
	
	If Not CommonUseCached.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	ContactInformation = ThisObject.ContactInformationAdditionalAttributeInfo;
	
	RowEmail = ContactInformation.FindRows(New Structure("Kind", Catalogs["ContactInformationKinds"].UserEmail))[0];
	ItemEmail = Items[RowEmail.AttributeName];
	ItemEmail.SetAction("OnChange", "Attachable_EmailOnChange");
	
	ItemEmail.ChoiceButton = True;
	ItemEmail.SetAction("StartChoice", "Attachable_EmailStartChoice");
	
	PhoneRow= ContactInformation.FindRows(New Structure("Kind", Catalogs["ContactInformationKinds"].UserPhone))[0];
	PhoneItem= Items[PhoneRow.AttributeName];
	PhoneItem.SetAction("OnChange", "Attachable_PhoneOnChange");
	
EndProcedure
 
&AtClientAtServerNoContext
Function ContactInformationKindUserEmail()
	
	PredefinedValueName = "Catalog." + "ContactInformationKinds" + ".UserEmail";
	
	Return PredefinedValue(PredefinedValueName);
	
EndFunction
 
////////////////////////////////////////////////////////////////////////////////
// Processing infobase user
 
&AtServer
Function InitialInfobaseUserDescription()
	
	SetPrivilegedMode(True);
	
	InfobaseUserDescription = Users.NewInfobaseUserInfo();
	
	If Not ValueIsFilled(Object.Ref) Then
		If CommonUseCached.DataSeparationEnabled() Then
			InfobaseUserDescription.ShowInList = False;
		Else
			InfobaseUserDescription.ShowInList =
				Not Constants.UseExternalUsers.Get();
		EndIf;
		InfobaseUserDescription.StandardAuthentication = True;
	EndIf;
	InfobaseUserDescription.Roles = New Array;
	
	Return InfobaseUserDescription;
	
EndFunction
 
&AtServer
Procedure ReadInfobaseUser(OnCopyItem = False)
	
	SetPrivilegedMode(True);
	
	Password             = "";
	PasswordConfirmation = "";
	ReadProperties       = Undefined;
	InfobaseUserDescription  = InitialInfobaseUserDescription();
	InfobaseUserExists   = False;
	InfobaseUserMain     = False;
	CanLogOnToApplication = False;
	CanLogOnToApplicationDirectChangeValue = False;
	
	If OnCopyItem Then
		
		If Users.ReadInfobaseUser(
		         Parameters.CopyingValue.InfobaseUserID,
		         ReadProperties) Then
			
			// Mapping infobase user to user from catalog
			If Users.CanLogOnToApplication(ReadProperties) Then
				CanLogOnToApplication = True;
				CanLogOnToApplicationDirectChangeValue = True;
			EndIf;
			
			// Copying infobase user properties and roles
			FillPropertyValues(
				InfobaseUserDescription,
				ReadProperties,
				"CannotChangePassword, ShowInList, RunMode, RunMode" + ?(Not Items.InfobaseUserLanguage.Visible, "", ", Language") + ?(UsersInternal.RoleEditProhibition(), "", ", Roles"));
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
					Object.Description = ReadProperties.FullName;
					Modified = True;
				EndIf;
			EndIf;
		EndIf;
		
		If InfobaseUserExists Then
			
			If Users.CanLogOnToApplication(ReadProperties) Then
				CanLogOnToApplication = True;
				CanLogOnToApplicationDirectChangeValue = True;
			EndIf;
			
			FillPropertyValues(
				InfobaseUserDescription,
				ReadProperties,
				"Name, FullName, OpenIDAuthentication, StandardAuthentication, ShowInList, CannotChangePassword, OSAuthentication, OSUser, RunMode" + ?(Not Items.InfobaseUserLanguage.Visible, "", ", Language") + ?(UsersInternal.RoleEditProhibition(), "", ", Roles"));
			
			If ReadProperties.PasswordIsSet Then
				Password              = "**********";
				PasswordConfirmation  = "**********";
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
		InfobaseUserOSAuthentication       = StoredProperties.OSAuthentication;
	EndIf;
	
	ProcessRolesInterface("FillRoles", InfobaseUserDescription.Roles);
	
	CanLogOnToApplicationOnRead = CanLogOnToApplication;
	
EndProcedure
 
&AtServer
Procedure FindUserAndInfobaseUserInconsistencies(WriteParameters = Undefined)
	
	// Checking whether the FullName infobase user property matches the Description user attribute
	
	ShowMismatch = True;
	ShowDifferenceResolvingCommands = False;
	
	If Not InfobaseUserExists Then
		ShowMismatch = False;
		
	ElsIf Not ValueIsFilled(Object.Ref) Then
		Object.Description = InfobaseUserFullName;
		ShowMismatch = False;
		
	ElsIf AccessLevel.ListManagement Then
		
		PropertiesClarification = New Array;
		
		If InfobaseUserFullName <> Object.Description Then
			ShowDifferenceResolvingCommands =
				    ShowDifferenceResolvingCommands
				Or ActionsOnForm.ItemProperties = "Edit";
			
			PropertiesClarification.Insert(0, StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Full name: ""%1""'"), InfobaseUserFullName));
		EndIf;
		
		If PropertiesClarification.Count() > 0 Then
			PropertyClarificationString = "";
			CurrentString = "";
			For Each PropertyClarification In PropertiesClarification Do
				If StrLen(CurrentString + PropertyClarification) > 90 Then
					PropertyClarificationString = PropertyClarificationString + TrimR(CurrentString) + ", " + Chars.LF;
					CurrentString = "";
				EndIf;
				CurrentString = CurrentString + ?(ValueIsFilled(CurrentString), ", ", "") + PropertyClarification;
			EndDo;
			If ValueIsFilled(CurrentString) Then
				PropertyClarificationString = PropertyClarificationString + CurrentString;
			EndIf;
			Items.PropertiesMismatchNote.Title =
				StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en = 'The following infobase user properties do not match the properties specified in the form:
					           |%1.'"), PropertyClarificationString)
				+ Chars.LF
				+ ?(ShowDifferenceResolvingCommands,
					NStr("en = 'To overwrite the properties, click Save.'"),
					NStr("en = 'If you want to overwrite the properties, contact your system administrator.'"));
		Else
			ShowMismatch = False;
		EndIf;
	Else
		ShowMismatch = False;
	EndIf;
	
	Items.PropertiesMismatchProcessing.Visible        = ShowMismatch;
	Items.ResolveDifferencesCommandProperties.Visible = ShowDifferenceResolvingCommands;
	
	// Checking whether an infobase user that does not exist is mapped to a user from the catalog
	HasNewMappingToNonExistentInfobaseUser
		= Not InfobaseUserExists
		And ValueIsFilled(Object.InfobaseUserID);
	
	If WriteParameters <> Undefined
	   And HasMappingToNonExistentInfobaseUser
	   And Not HasNewMappingToNonExistentInfobaseUser Then
		
		WriteParameters.Insert("MappingToNonExistentInfobaseUserCleared", Object.Ref);
	EndIf;
	HasMappingToNonExistentInfobaseUser = HasNewMappingToNonExistentInfobaseUser;
	
	If AccessLevel.ListManagement Then
		Items.MappingMismatchProcessing.Visible = HasMappingToNonExistentInfobaseUser;
	Else
		// Mapping cannot be changed
		Items.MappingMismatchProcessing.Visible = False;
	EndIf;
	
EndProcedure
 
&AtServer
Procedure FillFieldsByInfobaseUserAtServer()
	
	If AccessLevel.ListManagement
	   And ActionsOnForm.ItemProperties = "Edit" Then
		
		Object.Description = InfobaseUserFullName;
	EndIf;
	
	FindUserAndInfobaseUserInconsistencies();
	
	SetPropertyEnabled(ThisObject);
	
	SetSynchronizationWithServiceNecessity(ThisObject);
	
EndProcedure
 
////////////////////////////////////////////////////////////////////////////////
// Initial filling, fill check, availability of properties
 
&AtClientAtServerNoContext
Procedure SetPropertyEnabled(Form)
	
	Items         = Form.Items;
	Object        = Form.Object;
	ActionsOnForm = Form.ActionsOnForm;
	AccessLevel   = Form.AccessLevel;
	ActionsWithSaaSUser = Form.ActionsWithSaaSUser;
	
	// Specifying whether changing form items is allowed
	Items.CanLogOnToApplication.ReadOnly =
		Not (  Items.MainProperties.ReadOnly = False
		    And (    AccessLevel.FullAccess
		       Or AccessLevel.ListManagement And Form.CanLogOnToApplicationOnRead));
	
	Items.Password.ReadOnly =
		Not (    AccessLevel.LogonSettings
		    Or AccessLevel.ChangeCurrent
		      And Not Form.InfobaseUserCannotChangePassword);
	
	Items.PasswordConfirmation.ReadOnly = Items.Password.ReadOnly;
	
	// Specifying whether filling is necessary
	If InfobaseUserWriteRequired(Form, False) Then
		NewPage = Items.NameWithMarkIncomplete;
	Else
		NewPage = Items.NameWithoutMarkIncomplete;
	EndIf;
	
	If Items.NameMarkIncompleteSwitch.CurrentPage <> NewPage Then
		Items.NameMarkIncompleteSwitch.CurrentPage = NewPage;
	EndIf;
	UpdateLogonName(Form);
	
	// Specifying whether related items are available
	Items.CanLogOnToApplication.Enabled = Not Object.NotValid;
	Items.MainProperties.Enabled        = Not Object.NotValid;
	
	Items.Password.Enabled              = Form.InfobaseUserStandardAuthentication;
	Items.PasswordConfirmation.Enabled  = Form.InfobaseUserStandardAuthentication;
	
	Items.InfobaseUserCannotChangePassword.Enabled
		= Form.InfobaseUserStandardAuthentication;
	
	Items.InfobaseUserShowInList.Enabled
		= Form.InfobaseUserStandardAuthentication;
	
	Items.InfobaseUserOSUser.Enabled = Form.InfobaseUserOSAuthentication;
	
	// Adjusting SaaS settings
	If ActionsWithSaaSUser <> Undefined Then
		
		// Availability of contact information editing
		CIActions = ActionsWithSaaSUser.ContactInformation;
		
		For Each CIRow In Form.ContactInformationAdditionalAttributeInfo Do
			CITypeActions = CIActions.Get(CIRow.Kind);
			If CITypeActions = Undefined Then
				// Service manager cannot manage the availability of editing this kind of contact information
				Continue;
			EndIf;
			
			CIItem = Items[CIRow.AttributeName];
			
			If CIRow.Kind = ContactInformationKindUserEmail() Then
				
				CIItem.ReadOnly = Not Object.Ref.IsEmpty();
				
				CIItem.ChoiceButton = Not Object.Ref.IsEmpty()
					And CITypeActions.Change;
					
				EmailFilled = ValueIsFilled(Form[CIRow.AttributeName]);
			Else
				CIItem.ReadOnly = CIItem.ReadOnly
					Or Not CITypeActions.Change;
			EndIf;
		EndDo;
		
		If Object.Ref.IsEmpty() And EmailFilled Then
			PasswordCanBeChanged = False;
		Else
			PasswordCanBeChanged = ActionsWithSaaSUser.ChangePassword;
		EndIf;
		
		Items.Password.ReadOnly = Items.Password.ReadOnly
			Or Not PasswordCanBeChanged;
			
		Items.PasswordConfirmation.ReadOnly = Items.PasswordConfirmation.ReadOnly
			Or Not PasswordCanBeChanged;
		
		Items.InfobaseUserName1.ReadOnly = Items.InfobaseUserName1.ReadOnly
			Or Not ActionsWithSaaSUser.ChangeName;
			
		Items.InfobaseUserName2.ReadOnly = Items.InfobaseUserName2.ReadOnly
			Or Not ActionsWithSaaSUser.ChangeName;
			
		Items.Description.ReadOnly = Items.Description.ReadOnly 
			Or Not ActionsWithSaaSUser.ChangeFullName;
			
		Items.CanLogOnToApplication.Enabled = Items.CanLogOnToApplication.Enabled
			And ActionsWithSaaSUser.ChangeAccess;
			
		Items.NotValid.Enabled = Items.NotValid.Enabled
			And ActionsWithSaaSUser.ChangeAccess;
			
		Form.AdministrativeAccessChangeProhibition =
			Not ActionsWithSaaSUser.ChangeAdmininstrativeAccess;
	EndIf;
	
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
			Form.Object.Description);
		
		If Form.InfobaseUserName = ShortName Then
			CurrentName = ShortName;
		EndIf;
	EndIf;
	
	If Form.InfobaseUserExists
	 Or Form.CanLogOnToApplication
	 Or Form.InfobaseUserName                   <> CurrentName
	 Or Form.InfobaseUserStandardAuthentication <> Template.StandardAuthentication
	 Or Form.InfobaseUserShowInList             <> Template.ShowInList
	 Or Form.InfobaseUserCannotChangePassword   <> Template.CannotChangePassword
	 Or Form.Password <> ""
	 Or Form.PasswordConfirmation             <> ""
	 Or Form.InfobaseUserOSAuthentication     <> Template.OSAuthentication
	 Or Form.InfobaseUserOSUser               <> ""
	 Or Form.InfobaseUserOpenIDAuthentication <> Template.OpenIDAuthentication
	 Or Form.InfobaseUserRunMode              <> Template.RunMode
	 Or Form.InfobaseUserLanguage             <> Template.Language
	 Or Form.InfobaseUserRoles.Count() <> 0 Then
		
		Return True;
	EndIf;
	
	Return False;
	
EndFunction
 
 
 
 
&AtServer
Procedure ProcessRolesInterface(Action, MainParameter = Undefined)
	
	ActionParameters = New Structure;
	ActionParameters.Insert("MainParameter",  MainParameter);
	ActionParameters.Insert("Form",           ThisObject);
	ActionParameters.Insert("RoleCollection", InfobaseUserRoles);
	ActionParameters.Insert("AdministrativeAccessChangeProhibition",
		AdministrativeAccessChangeProhibition);
	
	UserType = ?(CommonUseCached.DataSeparationEnabled(),
		Enums.UserTypes.DataAreaUser,
		Enums.UserTypes.LocalApplicationUser);
	ActionParameters.Insert("UserType", UserType);
	
	AdministrativeAccessSet = InfobaseUserRoles.FindRows(
		New Structure("Role", "FullAccess")).Count() > 0;
	
	UsersInternal.ProcessRolesInterface(Action, ActionParameters);
	
	MappingToNonExistentInfobaseUserCleared = InfobaseUserRoles.FindRows(
		New Structure("Role", "FullAccess")).Count() > 0;
	
	If MappingToNonExistentInfobaseUserCleared <> AdministrativeAccessSet Then
		SetSynchronizationWithServiceNecessity(ThisObject);
	EndIf;
	
EndProcedure
 
#EndRegion