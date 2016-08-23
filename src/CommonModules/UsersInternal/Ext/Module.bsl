/////////////////////////////////////////////////////////////////////////////
// Users subsystem.
//
/////////////////////////////////////////////////////////////////////////////

#Region InternalInterface

/////////////////////////////////////////////////////////////////////////////
// Declarations of internal events (SL handlers can be attached to these events).
//
// Declares internal events of the Users subsystem:
//
// Server events:
//   OnDefineQuestionTextBeforeWriteFirstAdministrator,
//   OnWriteAdministrator.
//
// See the description of this procedure in the StandardSubsystemsServer module.
//
Procedure OnAddInternalEvent(ClientEvents, ServerEvents) Export
	
	// SERVER EVENTS
	
	// Overrides the standard method of assigning roles to infobase users.
	//
	// Parameters:
	//  Prohibition - Boolean - if True, prohibits role modification  
	//                          for everyone (including administrator).
	//
	// Syntax:
	// Procedure OnDefineRoleEditProhibition(Prohibition) Export
	//
	// (same as UsersOverridable.ChangeRoleEditProhibition).
	ServerEvents.Add("StandardSubsystems.Users\OnDefineRoleEditProhibition");
	
	// Overrides the behavior of user form, external user form,
	// and external user group form.
	//
	// Parameters:
	//  Ref           - CatalogRef.Users, CatalogRef.ExternalUsers, CatalogRef.ExternalUserGroups                
	//                - reference to the user, external user, or external user group
	//                  at the time of form creation.
	//  ActionsOnForm - Structure of String values:
	//           Roles                  = "", "View", "Edit".
	//           ContactInformation     = "", "View", "Edit".
	//           InfobaseUserProperties = "", "ViewAll", "EditAll", "EditOwn". 
	//           ItemProperties         = "", "View", "Edit".
	//           
	//           ContactInformation and InfobaseUserProperties do not exist for external user groups.
	//
	// Syntax:
	// Procedure OnDefineActionsInForm(Ref, ActionsInForm) Export
	//
	// (same as UsersOverridable.ChangeActionsOnForm).
	ServerEvents.Add("StandardSubsystems.Users\OnDefineActionsInForm");
	
	// Overrides the text of the question that is asked before writing the first administrator.
	// The procedure is called from the BeforeWrite handler in the user form.
	// The procedure is called if RoleEditProhibition() is set 
	// and the number of infobase users is zero.
	// 
	// Syntax:
	// Procedure OnDefineQuestionTextBeforeWriteFirstAdministrator(QuestionText) Export
	//
	ServerEvents.Add(
		"StandardSubsystems.Users\OnDefineQuestionTextBeforeWriteFirstAdministrator");
	
	// Redefines actions performed when a user is written with an infobase user
	// with FullAccess role.
	// 
	// Parameters:
	//  User - CatalogRef.Users - object cannot be changed.
	//
	// Syntax:
	// Procedure OnWriteAdministrator(User) Export
	//
	ServerEvents.Add("StandardSubsystems.Users\OnWriteAdministrator");
	
	// The procedure is called when creating a Users catalog item, when a user logs on interactively.
	//
	// Parameters:
	//  NewUser - CatalogObject.Users.
	//
	// Syntax:
	// Procedure OnCreateUserAtLogonTime(NewUser) Export
	ServerEvents.Add("StandardSubsystems.Users\OnCreateUserAtLogonTime");
	
	// The procedure is called during the authorization of a new infobase user.
	//
	// Parameters:
	//  InfobaseUser       - InfobaseUser - current infobase user.
	//  StandardProcessing - Boolean – the value can be set in the handler.  
	//                                 If False, standard processing
//                                   of new infobase user authorization is not executed.
	//
	// Syntax:
	// Procedure OnAuthorizeNewInfobaseUser(InfobaseUser, StandardProcessing) Export
	ServerEvents.Add("StandardSubsystems.Users\OnAuthorizeNewInfobaseUser");
	
	// The procedure is called at the start of infobase user processing.
	//
	// Parameters:
	//  ProcessingParameters - Structure - see comment for StartInfobaseUserProcessing()  procedure.
	//  InfobaseUserDescription  - Structure - see comment for StartInfobaseUserProcessing() procedure.
	//
	// Syntax:
	// Procedure OnStartInfobaseUserProcessing(ProcessingParameters, InfobaseUserDescription);
	ServerEvents.Add("StandardSubsystems.Users\OnStartInfobaseUserProcessing");
	
	// The procedure is called before writing an infobase user.
	//
	// Parameters:
	//  InfobaseUserID - ID.
	//
	// Syntax:
	// Procedure BeforeWriteInfobaseUser(InfobaseUserID) Export.
	ServerEvents.Add("StandardSubsystems.Users\BeforeWriteInfobaseUser");
	
EndProcedure

// See the description of this procedure in the StandardSubsystemsServer module.
Procedure InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers) Export
	
	// SERVER HANDLERS
	
	//These handlers were moved from AccessManagement and must be deleted in next releases
	//begin
	
	ServerHandlers["StandardSubsystems.Users\OnDefineActionsInForm"].Add(
		"UsersInternal");
		
	ServerHandlers["StandardSubsystems.Users\OnDefineRoleEditProhibition"].Add(
		"UsersInternal");	
		
	//end
	
	ServerHandlers["StandardSubsystems.InfobaseVersionUpdate\OnAddUpdateHandlers"].Add(
		"UsersInternal");
	ServerHandlers["StandardSubsystems.BaseFunctionality\SessionParameterSettingHandlersOnAdd"].Add(
		"UsersInternal");
	
	ServerHandlers["StandardSubsystems.BaseFunctionality\ClientParametersOnAdd"].Add(
		"UsersInternal");
	
	ServerHandlers["StandardSubsystems.BaseFunctionality\OnAddReferenceSearchException"].Add(
		"UsersInternal");
	
	ServerHandlers["StandardSubsystems.BaseFunctionality\OnSendDataToSlave"].Add(
		"UsersInternal");
	
	ServerHandlers["StandardSubsystems.BaseFunctionality\OnSendDataToMaster"].Add(
		"UsersInternal");
	
	ServerHandlers["StandardSubsystems.BaseFunctionality\OnReceiveDataFromSlave"].Add(
		"UsersInternal");
	
	ServerHandlers["StandardSubsystems.BaseFunctionality\OnReceiveDataFromMaster"].Add(
		"UsersInternal");
	
	ServerHandlers["StandardSubsystems.BaseFunctionality\DataFromSubordinateAfterReceive"].Add(
		"UsersInternal");
	
	ServerHandlers["StandardSubsystems.BaseFunctionality\DataFromMasterAfterReceive"].Add(
		"UsersInternal");
	
	ServerHandlers["StandardSubsystems.BaseFunctionality\OnGetMandatoryExchangePlanObjects"].Add(
		"UsersInternal");
	
	ServerHandlers["StandardSubsystems.BaseFunctionality\ExchangePlanObjectsToExcludeOnGet"].Add(
		"UsersInternal");
		
	ServerHandlers["StandardSubsystems.BaseFunctionality\OnGetExchangePlanInitialImageObjects"].Add(
		"UsersInternal");
	
	If CommonUse.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ServerHandlers["StandardSubsystems.AccessManagement\OnFillMetadataObjectAccessRestrictionKinds"].Add(
			"UsersInternal");
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.ReportOptions") Then
		ServerHandlers["StandardSubsystems.ReportOptions\ReportOptionsOnSetup"].Add(
			"UsersInternal");
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// Main procedures and functions.

// Fills the CurrentUser or CurrentExternalUser session parameter with user 
// that matches the current session infobase user.
// 
//  If the user is not found in the catalog and administrative rights are granted,
//  a new user is created in the catalog. If administrative rights are denied, an exception is thrown.
// 
Procedure SessionParametersSetting(Val ParameterName, SpecifiedParameters) Export
	
	If ParameterName <> "CurrentUser"
	   And ParameterName <> "CurrentExternalUser"
	   And ParameterName <> "AuthorizedUser" Then
		
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If Not CommonUseCached.CanUseSeparatedData() Then
		Raise
			NStr("en = 'Cannot retrieve CurrentUser session parameter
			           |in a session that does not have all separators specified.'");
	EndIf;
	
	BeginTransaction();
	Try
		UserNotFound = False;
		CreateUser   = False;
		RefNew       = Undefined;
		Internal     = False;
		
		CurrentUser         = Undefined;
		CurrentExternalUser = Undefined;
		
		CurrentInfobaseUser = InfobaseUsers.CurrentUser();
		
		If IsBlankString(CurrentInfobaseUser.Name) Then
			
			CurrentExternalUser = Catalogs.ExternalUsers.EmptyRef();
			
			UnspecifiedUserProperties = UnspecifiedUserProperties();
			
			UserName     = UnspecifiedUserProperties.FullName;
			UserFullName = UnspecifiedUserProperties.FullName;
			RefNew       = UnspecifiedUserProperties.StandardRef;
			
			If UnspecifiedUserProperties.Ref = Undefined Then
				UserNotFound   = True;
				CreateUser     = True;
				Internal       = True;
				InfobaseUserID = "";
			Else
				CurrentUser = UnspecifiedUserProperties.Ref;
			EndIf;
		Else
			UserName       = CurrentInfobaseUser.Name;
			InfobaseUserID = CurrentInfobaseUser.UUID;
			
			Users.FindAmbiguousInfobaseUsers(, InfobaseUserID);
			
			Query = New Query;
			Query.Parameters.Insert("InfobaseUserID", InfobaseUserID);
			
			Query.Text =
			"SELECT TOP 1
			|	Users.Ref AS Ref
			|FROM
			|	Catalog.Users AS Users
			|WHERE
			|	Users.InfobaseUserID = &InfobaseUserID";
			UsersResult = Query.Execute();
			
			Query.Text =
			"SELECT TOP 1
			|	ExternalUsers.Ref AS Ref
			|FROM
			|	Catalog.ExternalUsers AS ExternalUsers
			|WHERE
			|	ExternalUsers.InfobaseUserID = &InfobaseUserID";
			ResultExternalUsers = Query.Execute();
			
			If Not ResultExternalUsers.IsEmpty() Then
				
				Selection = ResultExternalUsers.Select();
				Selection.Next();
				CurrentUser         = Catalogs.Users.EmptyRef();
				CurrentExternalUser = Selection.Ref;
				
				If Not ExternalUsers.UseExternalUsers() Then
				
					ErrorMessageText = NStr("en = 'External users are disabled.'");
					Raise ErrorMessageText;
				EndIf;
			Else
				CurrentExternalUser = Catalogs.ExternalUsers.EmptyRef();
				
				If UsersResult.IsEmpty() Then
					If Users.InfobaseUserWithFullAccess( , CommonUseCached.ApplicationRunMode().Local, False) Then
						
						InfobaseUserID    = CurrentInfobaseUser.UUID;
						
						UserFullName      = CurrentInfobaseUser.FullName;
						UserByDescription = UserRefByFullDescription(UserFullName);
						
						If UserByDescription = Undefined Then
							UserNotFound = True;
							CreateUser  = True;
						Else
							CurrentUser = UserByDescription;
						EndIf;
					Else
						UserNotFound = True;
					EndIf;
				Else
					Selection = UsersResult.Select();
					Selection.Next();
					CurrentUser = Selection.Ref;
				EndIf;
			EndIf;
		EndIf;
		
		If CreateUser Then
			
			BeginTransaction();
			Try
				
				If RefNew = Undefined Then
					RefNew = Catalogs.Users.GetRef();
				EndIf;
				
				CurrentUser = RefNew;
				
				NewUser = Catalogs.Users.CreateItem();
				NewUser.Internal    = Internal;
				NewUser.Description = UserFullName;
				NewUser.SetNewObjectRef(RefNew);
				
				If ValueIsFilled(InfobaseUserID) Then
					
					InfobaseUserDescription = New Structure;
					InfobaseUserDescription.Insert("Action", "Write");
					InfobaseUserDescription.Insert("UUID", InfobaseUserID);
					
					NewUser.AdditionalProperties.Insert(
						"InfobaseUserDescription", InfobaseUserDescription);
				EndIf;
				
				Handlers = CommonUse.InternalEventHandlers("StandardSubsystems.Users\OnCreateUserAtLogonTime");
				For Each Handler In Handlers Do
					Handler.Module.OnCreateUserAtLogonTime(NewUser);
				EndDo;
				
				NewUser.Write();
				
				CommitTransaction();
			Except
				RollbackTransaction();
				
				ErrorMessageText = StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en = 'Authorization failed. The application is stopped.
					           |User %1 is not found in the Users catalog.
					           |
					           |The following error occurred when adding the user to the catalog: 
					           |""%2"".
					           |
					           |Contact the application administrator.'"),
					UserName,
					BriefErrorDescription(ErrorInfo()) );
				
				Raise ErrorMessageText;
			EndTry;
			
		ElsIf UserNotFound Then
			Raise UserNotFoundInCatalogMessageText(UserName);
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If CurrentUser = Undefined
	 Or CurrentExternalUser = Undefined Then
		
		ErrorMessageText = UserNotFoundInCatalogMessageText(UserName) +
			NStr("en = '
			           |Internal error occurred while searching for the user.'");
		Raise ErrorMessageText;
	EndIf;
	
	SessionParameters.CurrentUser        = CurrentUser;
	SessionParameters.CurrentExternalUser = CurrentExternalUser;
	
	SessionParameters.AuthorizedUser = ?(ValueIsFilled(CurrentUser),
		CurrentUser, CurrentExternalUser);
	
	SpecifiedParameters.Add("CurrentUser");
	SpecifiedParameters.Add("CurrentExternalUser");
	SpecifiedParameters.Add("AuthorizedUser");
	
EndProcedure
 

// The procedure is called during application startup to check whether authorization is possible 
// and to call the filling of CurrentUser and CurrentExternalUser session parameter values.
// The function is also called upon entering a data area.
//
// Returns:
//  String – empty String    - successful authorization.
//           nonempty String - error description.
//                             1C:Enterprise should be
//                             stopped at application startup.
//
Function AuthenticateCurrentUser(OnStart = False) Export
	
	If Not OnStart Then
		RefreshReusableValues();
	EndIf;
	
	SetPrivilegedMode(True);
	
	CurrentInfobaseUser = InfobaseUsers.CurrentUser();
	CheckUserRights(CurrentInfobaseUser, "OnStart");
	
	If IsBlankString(CurrentInfobaseUser.Name) Then
		// Authorizing the default user
		Return "";
	EndIf;
	
	Handlers = CommonUse.InternalEventHandlers("StandardSubsystems.Users\OnAuthorizeNewInfobaseUser");
	StandardProcessing = True;
	For Each Handler In Handlers Do
		Handler.Module.OnAuthorizeNewInfobaseUser(CurrentInfobaseUser, StandardProcessing);
	EndDo;
	
	If Not StandardProcessing Then
		Return "";
	EndIf;
	
	FoundUser = Undefined;
	If UserByIDExists(
	       CurrentInfobaseUser.UUID, , FoundUser) Then
		// InfobaseUser is found in the catalog
		
		If OnStart
		   And Users.InfobaseUserWithFullAccess(CurrentInfobaseUser, CommonUseCached.ApplicationRunMode().Local, False) Then
			
			OnAuthorizeAdministratorOnStart(FoundUser);
		EndIf;
		
		Return "";
	EndIf;
	
	// Creating Administrator or informing that authorization failed
	ErrorMessageText = "";
	CreateAdministratorRequired = False;
	
	_InfobaseUsers = InfobaseUsers.GetUsers();
	
	If _InfobaseUsers.Count() = 1 Or Users.InfobaseUserWithFullAccess(, True, False) Then
		// Authorizing user with administrative privileges, which is created earlier in Designer.
		CreateAdministratorRequired = True;
	Else
		// Authorizing user without administrative privileges, which is created earlier in Designer.
		ErrorMessageText = UserNotFoundInCatalogMessageText(CurrentInfobaseUser.Name);
	EndIf;
	
	If CreateAdministratorRequired Then
		
		If IsInRole(Metadata.Roles.FullAccess)
			And (IsInRole(Users.FullAdministratorRole(True))
			   Or CommonUseCached.DataSeparationEnabled() ) Then
			
			User = Users.CreateAdministrator(CurrentInfobaseUser);
			
			Comment =
				NStr("en = 'Starting the application on behalf of user with ""Full access"" role,
				           |which is not in the list of registered users.
				           |Cannot start the application on behalf of the administrator because it is not in the list of registered users.

				           |The user is automatically registered in the user list.
				           |
				           |Use the Users catalog to add users and set up their rights.
				           |Do not use Designer for this purpose.'");
			
			AfterWriteAdministratorOnAuthorization(Comment);
			
			WriteLogEvent(
				NStr("en = 'Users.Administrator is registered in the Users catalog'",
				     CommonUseClientServer.DefaultLanguageCode()),
				EventLogLevel.Warning,
				Metadata.Catalogs.Users,
				User,
				Comment);
		Else
			ErrorMessageText =
				NStr("en = 'Cannot start the application on behalf of the user with administrative rights
				           |because it is not in the list of registered users.
				           |
				           |Use the Users catalog to add users and set up their rights.
				           |Do not use Designer for this purpose.'");
		EndIf;
	EndIf;
	
	Return ErrorMessageText;
	
EndFunction

// Specifies that a nonstandard method of setting infobase user roles is used.
//
Function RoleEditProhibition() Export
	
	Prohibition = False;
	
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.Users\OnDefineRoleEditProhibition");
	
	For Each Handler In EventHandlers Do
		Handler.Module.OnDefineRoleEditProhibition(Prohibition);
	EndDo;
	
	UsersOverridable.ChangeRoleEditProhibition(Prohibition);
	
	Return Prohibition = True;
	
EndFunction

// Sets initial settings for an infobase user.
//
// Parameters:
//  UserName - String - infobase user name.
//
Procedure SetInitialSettings(Val UserName) Export
	
	SystemInfo = New SystemInfo;
	
	CurrentMode = Metadata.InterfaceCompatibilityMode;
	Taxi = (CurrentMode = Metadata.ObjectProperties.InterfaceCompatibilityMode.Taxi
		Or CurrentMode = Metadata.ObjectProperties.InterfaceCompatibilityMode.TaxiEnableVersion8_2);
	
	ClientSettings = New ClientSettings;
	ClientSettings.ShowNavigationAndActionsPanels = False;
	ClientSettings.ShowSectionsPanel = True;
	ClientSettings.ApplicationFormsOpenningMode = ApplicationFormsOpenningMode.Tabs;
	
	TaxiSettings = Undefined;
	InterfaceSettings = New CommandInterfaceSettings;
	
	If Taxi Then
		
		InterfaceSettings.SectionsPanelRepresentation = SectionsPanelRepresentation.PictureAndText;
		
		TaxiSettings = New ClientApplicationInterfaceSettings;
  		ContentSettings = New ClientApplicationInterfaceContentSettings;
		LeftGroup = New ClientApplicationInterfaceContentSettingsGroup;
		LeftGroup.Add(New ClientApplicationInterfaceContentSettingsItem("ToolsPanel"));
		LeftGroup.Add(New ClientApplicationInterfaceContentSettingsItem("SectionsPanel"));
  		ContentSettings.Left.Add(LeftGroup);
  		TaxiSettings.SetContent(ContentSettings);
		
	Else
		InterfaceSettings.SectionsPanelRepresentation = SectionsPanelRepresentation.Text;
	EndIf;
	
	InitialSettings = New Structure("ClientSettings,InterfaceSettings,TaxiSettings", 
		ClientSettings, InterfaceSettings, TaxiSettings);
	UsersOverridable.OnSetInitialSettings(InitialSettings);
	
	If InitialSettings.ClientSettings <> Undefined Then
		SystemSettingsStorage.Save("Common/ClientSettings", "",
			InitialSettings.ClientSettings, , UserName);
	EndIf;
	
	If InitialSettings.InterfaceSettings <> Undefined Then
		SystemSettingsStorage.Save("Common/SectionsPanel/CommandInterfaceSettings", "",
			InitialSettings.InterfaceSettings, , UserName);
	EndIf;
		
	If InitialSettings.TaxiSettings <> Undefined Then
		SystemSettingsStorage.Save("Common/ClientApplicationInterfaceSettings", "",
			InitialSettings.TaxiSettings, , UserName);
	EndIf;
		
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// The procedure processes the role interface in a managed form.

// For internal use only.
//
Procedure ProcessRolesInterface(Action, Parameters) Export
	
	If Action = "SetRolesReadOnly" Then
		SetRolesReadOnly(Parameters);
		
	ElsIf Action = "SetUpRoleInterfaceOnLoadSettings" Then
		SetUpRoleInterfaceOnLoadSettings(Parameters);
		
	ElsIf Action = "SetUpRoleInterfaceOnFormCreate" Then
		SetUpRoleInterfaceOnFormCreate(Parameters);
		
	ElsIf Action = "SelectedRolesOnly" Then
		SelectedRolesOnly(Parameters);
		
	ElsIf Action = "GroupBySubsystems" Then
		GroupBySubsystems(Parameters);
		
	ElsIf Action = "RefreshRoleTree" Then
		RefreshRoleTree(Parameters);
		
	ElsIf Action = "UpdateRoleContent" Then
		UpdateRoleContent(Parameters);
		
	ElsIf Action = "FillRoles" Then
		FillRoles(Parameters);
	Else
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'UsersInternal.ProcessRolesInterface() procedure error.
			           |Invalid value of Action parameter: %1.'"),
			Action);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for common use.

// Returns a value table with all configuration role names.
// 
// Parameters:
// 
// Returns:
//  FixedStructure with the following properties:
//      Array      - FixedArray - role names.
//      Map        - FixedMap between role names and the True value.
//      ValueTable - ValueTable with the following columns:
//                   Name - String - role name.
//
Function AllRoles() Export
	
	Return UsersInternalCached.Parameters().AllRoles;
	
EndFunction

// Returns roles that are not available to the specified user type.
//
// Parameters:
//  UserType - EnumRef.UserTypes.
//
// Returns:
//  FixedMap: Key   - role name.
//            Value - True.
//
Function InaccessibleRolesByUserType(UserType) Export
	
	// In the local mode the system administrator does not have any restrictions.
	If UserType = Enums.UserTypes.LocalApplicationUser 
		And Users.InfobaseUserWithFullAccess(, True, False) Then
		Return New FixedMap(New Map());
	EndIf;
	
	InaccessibleRoles = UsersInternalCached.Parameters().InaccessibleRolesByUserTypes;
	Return InaccessibleRoles.Get(UserType);
	
EndFunction

// Checks whether the application is running on the training platform,
// which has limitations (for example, the OSUser property is not available).
//
Function IsTrainingPlatform() Export
	
	SetPrivilegedMode(True);
	
	CurrentUser = InfobaseUsers.CurrentUser();
	
	Try
		OSUser = CurrentUser.OSUser;
	Except
		CurrentUser = Undefined;
	EndTry;
	
	Return CurrentUser = Undefined;
	
EndFunction

// At the first start of a subordinate node clears the infobase user IDs
// copied during the creation of an initial image.
//
Procedure ClearNonExistentInfobaseUserIDs() Export
	
	If CommonUseCached.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	EmptyUUID = New UUID("00000000-0000-0000-0000-000000000000");
	
	Query = New Query;
	Query.SetParameter("EmptyUUID", EmptyUUID);
	
	Query.Text =
	"SELECT
	|	Users.Ref AS Ref,
	|	Users.InfobaseUserID
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.InfobaseUserID <> &EmptyUUID
	|
	|UNION ALL
	|
	|SELECT
	|	ExternalUsers.Ref,
	|	ExternalUsers.InfobaseUserID
	|FROM
	|	Catalog.Users AS ExternalUsers
	|WHERE
	|	ExternalUsers.InfobaseUserID <> &EmptyUUID";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		InfobaseUser = InfobaseUsers.FindByUUID(
			Selection.InfobaseUserID);
		
		If InfobaseUser <> Undefined Then
			Continue;
		EndIf;
		
		CurrentObject = Selection.Ref.GetObject();
		CurrentObject.InfobaseUserID = EmptyUUID;
		InfobaseUpdate.WriteData(CurrentObject);
	EndDo;
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

////////////////////////////////////////////////////////////////////////////////
// SL event handlers.

// This procedure is obsolete
// 
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version = "2.1.3.16";
	Handler.InitialFilling = True;
	Handler.Procedure = "UsersInternal.UpdateUserPredefinedContactInformationKinds"

EndProcedure

// Returns the mapping between session parameter names and their initialization handlers.
//
Procedure SessionParameterSettingHandlersOnAdd(Handlers) Export
	
	Handlers.Insert("CurrentUser",         "UsersInternal.SessionParametersSetting");
	Handlers.Insert("CurrentExternalUser", "UsersInternal.SessionParametersSetting");
	
EndProcedure

// Adds parameters to the structure of parameters that are required by the client configuration script.
//
// Parameters:
//   Parameters - Structure where you can add client parameters during application startup:
//                Key   - parameter name.
//                Value - parameter value.
//
// Usage example:
//   Parameters.Insert(<ParameterName>, <Script that gets parameter value>);
//
Procedure ClientParametersOnAdd(Parameters) Export
	
	Parameters.Insert("InfobaseUserWithFullAccess", Users.InfobaseUserWithFullAccess());
	
EndProcedure

// Fills the array with the list of names of metadata objects that might include references to
// other metadata objects, but these references are ignored in the business logic of the
// application.
//
// Parameters:
//  Array - array of strings, for example, "InformationRegister.ObjectVersions".
//
Procedure OnAddReferenceSearchException(Array) Export
	
	Array.Add(Metadata.InformationRegisters.UserGroupContents.FullName());
	
EndProcedure

// Handler of the event that has the same name, which occurs during data exchange in a distributed infobase.
//
// Parameters:
// See OnSendDataToSlave() event handler description in the Syntax Assistant.
// 
Procedure OnSendDataToSlave(DataItem, ItemSend, InitialImageCreating, Recipient) Export
	
	OnSendData(DataItem, ItemSend, True);
	
EndProcedure

// Handler of the event that has the same name, which occurs during data exchange in a distributed infobase.
//
// Parameters:
// See OnSendDataToMaster() event handler description in the Syntax Assistant.
// 
Procedure OnSendDataToMaster(DataItem, ItemSend, Recipient) Export
	
	OnSendData(DataItem, ItemSend, False);
	
EndProcedure

// Handler of the event that has the same name, which occurs during data exchange in a distributed infobase.
//
// Parameters:
// See OnReceiveDataFromSlave() event handler description in the Syntax Assistant.
// 
Procedure OnReceiveDataFromSlave(DataItem, ItemReceive, SendBack, From) Export
	
	OnDataGet(DataItem, ItemReceive, SendBack, True);
	
EndProcedure

// Handler of the event that has the same name, which occurs during data exchange in a distributed infobase.
//
// Parameters:
// See OnReceiveDataFromMaster() event handler description in the Syntax Assistant.
// 
Procedure OnReceiveDataFromMaster(DataItem, ItemReceive, SendBack, From) Export
	
	OnDataGet(DataItem, ItemReceive, SendBack, False);
	
EndProcedure

// Handler of the event that occurs in the master mode after receiving data from a subordinate DIB node.
// The procedure is called after the exchange message is read, when all data from the exchange message is read and written to the infobase.
// 
//  Parameters:
// From - ExchangePlanObject - Exchange plan node object that sent the data.
// Cancel - Boolean - if True, the message is not considered received.
// Also the data import transaction is rolled back (if all data was imported
// in a single transaction), or the last data import transaction 
// is rolled back (if the data was imported in portions).
//
Procedure DataFromSubordinateAfterReceive(From, Cancel) Export
	
	DataAfterReceive(From, Cancel, True);
	
EndProcedure

// Handler of the event that occurs in the subordinate node after receiving data from the master DIB node.
// The procedure is called after the exchange message is read, when all data from the exchange message is read and written to the infobase.
// 
//  Parameters:
// From - ExchangePlanObject - Exchange plan node object that sent the data.
// Cancel - Boolean - if True, the message is not considered received.
// Also the data import transaction is rolled back (if all data was imported
// in a single transaction), or the last data import transaction 
// is rolled back (if the data was imported in portions).
//
Procedure DataFromMasterAfterReceive(From, Cancel) Export
	
	DataAfterReceive(From, Cancel, False);
	
EndProcedure

// The procedure is used when getting metadata objects that are mandatory for the exchange plan.
// If the subsystem includes metadata objects that must be included in the
// exchange plan content, add these metadata objects to the Objects parameter.
//
// Parameters:
// Objects - Array - the array of configuration metadata objects that must be included in the exchange plan content.
// DistributedInfobase (read only) - Boolean - flag that shows whether DIB exchange plan objects are retrieved:
//                                   True  - list of DIB exchange plan objects is retrieved.
//                                   False - list of non-DIB exchange plan objects is retrieved.
//
Procedure OnGetMandatoryExchangePlanObjects(Objects, Val DistributedInfobase) Export
	
	If DistributedInfobase Then
		
		Objects.Add(Metadata.Constants.UserSessionParameters);
		
	EndIf;
	
EndProcedure

// The procedure is used when getting metadata objects that must not be included in the exchange plan content.
// If the subsystem includes metadata objects that must not be included in
// the exchange plan content, add these metadata objects to the Objects parameter.
//
// Parameters:
// Objects - Array - the array of configuration metadata objects that should not be included in the exchange plan content.
// DistributedInfobase (read only) - Boolean - flag that shows whether DIB exchange plan objects are retrieved:
//                                   True -  list of DIB exchange plan objects is retrieved.
//                                   False - list of non-DIB exchange plan objects is retrieved.
//
Procedure ExchangePlanObjectsToExcludeOnGet(Objects, Val DistributedInfobase) Export
	
EndProcedure

// The procedure is used for getting metadata objects that must be included in the exchange plan content 
// but NOT included in the change record event subscriptions of this exchange plan.
// These metadata objects are used only when creating the initial image of 
// a subordinate node and are not transferred during the exchange.
// If the subsystem includes metadata objects used only for creating the initial image
// of a subordinate node, add these metadata objects to the Objects parameter.
//
// Parameters:
// Objects - Array - metadata object array.
//
Procedure OnGetExchangePlanInitialImageObjects(Objects) Export
	
	Objects.Add(Metadata.Constants.UserSessionParameters);
	
EndProcedure

// Event handlers of "Access management" subsystem.
//

// Fills the list of access kinds that are used to set metadata object right restrictions.
// If the list of access kinds is not filled, the Access rights report displays incorrect data.
//
// Only access kinds that are explicitly used in access restriction templates must be filled,
// while access kinds used in access value sets can alternately be obtained from the current
// state of the AccessValueSets information register.
//
// To generate the procedure script automatically, it is recommended that you use the developer
// tools from the Access management subsystem.
//
// Parameters:
//  Details     - String, multiline string of following format:
//                 <Table>.<Right>.<AccessKind>[.Table object]
//                 Example: Document.GoodsReceipt.Read.Companies
//                          Document.GoodsReceipt.Read.Counterparties
//                          Document.GoodsReceipt.Update.Companies 
//                          Document.GoodsReceipt.Update.Counterparties
//                          Document.EmailMessages.Read.Object.Document.EmailMessages
//                          Document.EmailMessages.Update.Object.Document.EmailMessages
//                          Document.Files.Read.Object.Catalog.FileFolders
//                          Document.Files.Read.Object.Document.EmailMessage
//                          Document.Files.Update.Object.Catalog.FileFolders
//                          Document.Files.Update.Object.Document.EmailMessage.
//                 The Object access kind is predefined as a literal.
//                 This access kind is used in access restriction templates
//                 as a reference to another object that is used for applying restrictions to the current table item.            
//                 If Object access kind is specified, table types that are used in the access
//                 kind must be specified too (in other words, you have to list the types that
//                 match the access restriction template field that describes the Object access
//                 kind).
//                 The list of types for the Object access kind should only include
//                 the types available for the InformationRegisters.AccessValueSets.Object field.
//                 
// 
Procedure OnFillMetadataObjectAccessRestrictionKinds(Details) Export
	
	Details = Details + 
	"
	|Catalog.ExternalUsers.Read.ExternalUsers
	|Catalog.ExternalUsers.Update.ExternalUsers
	|Catalog.ExternalUserGroups.Read.ExternalUsers
	|Catalog.UserGroups.Read.Users
	|Catalog.Users.Read.Users
	|Catalog.Users.Update.Users
	|InformationRegister.UserGroupContents.Read.ExternalUsers
	|InformationRegister.UserGroupContents.Read.Users
	|";
	
EndProcedure

// Event handlers of "Report options" subsystem.

// Contains the settings of report option placement in the report panel.
//   
// Parameters:
//   Settings - Collection - used to describe report settings and report options.
//              See the description of ReportOptions.ConfigurationReportOptionSettingsTree().
//   
// Description:
//   This procedure must specify how predefined report
//   options are registered and displayed in the report panel.
//   
// Auxiliary methods:
//   ReportSettings = ReportOptions.ReportDetails(Settings, Metadata.Reports.<ReportName>);
//   OptionSettings = ReportOptions.OptionDetails(Settings, ReportSettings, "<OptionName>");
//   
//   The functions get report settings and report option settings that have the following structure:
//       Enabled - Boolean - if False, the report option is not registered
//                           in the subsystem. It is used for deletion of 
//                           auxiliary and context-dependent report options from all interfaces.         
//                           These report options can still be open in the report form, provided that
//                           it is opened with parameters from 1C:Enterprise script
//                           (see Help for "Managed form extension for reports.VariantKey").
//       DefaultVisibility - Boolean - if False, the report option is hidden from the report panel by default.          
//                                     The user can enable it in the report panel settings 
//                                     or open it from the "All reports" form.
//       Details - String - Additional information about the report option.
//                          It is displayed as a tooltip in the report panel.
//                          It explains the report option purpose to the
//                          user and should not duplicate the name of the report option.
//       Location - Map – Settings that describe report option availability in sections.
//           Key   - MetadataObject: Subsystem - Subsystem where a report or a report option is available.
//           Value - String - Optional. Position in the subsystem interface.
//               ""          - Show report in its group in regular font.
//               "Important" - Show report in its group in bold.
//               "SeeAlso"   - Show report in the See also group.
//       FunctionalOptions - Array with elements of the String type -
//                           Names of report option functional options.
//   
// Example:
//   
//  (1) Add report option to a subsystem.
// Option = ReportOptions.OptionDetails(Settings, Metadata.Reports.ReportName, "OptionName1");
// Option.Location.Insert(Metadata.Subsystems.SectionName.Subsystems.SubsystemName);
//   
//  (2) Disable report option.
// Option = ReportOptions.OptionDetails(Settings, Metadata.Reports.ReportName, "OptionName1");
// Option.Enabled = False;
//   
//  (3) Disable all report options except the specified report option.
// Report = ReportOptions.ReportDetails(Settings, Metadata.Reports.ReportName);
// Report.Enabled = False;
// Option = ReportOptions.OptionDetails(Settings, Report, "OptionName");
// Option.Enabled = True;
//   
//  (4) 4.1 and 4.2 have the same result:
//  (4.1)
// Report = ReportOptions.ReportDetails(Settings, Metadata.Reports.ReportName);
// Option = ReportOptions.OptionDetails(Settings, Report, "OptionName1");
// Option.Location.Delete(Metadata.Subsystems.SectionName.Subsystems.SubsystemName);
// Option = ReportOptions.OptionDetails(Settings, Report, "OptionName2");
// Option.Location.Delete(Metadata.Subsystems.SectionName.Subsystems.SubsystemName);
// Option = ReportOptions.OptionDetails(Settings, Report, "OptionName3");
// Option.Location.Delete(Metadata.Subsystems.SectionName.Subsystems.SubsystemName);
//   
//  (4.2)
// Report = ReportOptions.ReportDetails(Settings, Metadata.Reports.ReportName);
// Report.Location.Delete(Metadata.Subsystems.SectionName.Subsystems.SubsystemName);
// ReportOptions.OptionDetails(Settings, Report, "OptionName1");
// ReportOptions.OptionDetails(Settings, Report, "OptionName2");
// ReportOptions.OptionDetails(Settings, Report, "OptionName3");
// Report.Location.Insert(Metadata.Subsystems.SectionName.Subsystems.SubsystemName);
//   
// Important:
//   A report serves as a container for report options.
//     You can change the settings of all report options by modifying the report settings.
//     If report option settings are retrieved explicitly,
//     they become independent (they no longer inherit settings changes from the report). See examples 3 and 4.
//   
//   Initial report availability in the subsystems is read
//   from the metadata, duplicating this in the script is not required.
//   
//   Report option functional options are combined with report functional options 
//   according to the following rules:
//   (ReportFunctionalOption1 OR ReportFunctionalOption2) AND OptionFunctionalOption3 OR OptionFunctionalOption4).
//   Report functional options are not retrieved from the metadata,
//   they are applied when a user accesses a subsystem.
//   Functional options can be added from ReportDetails. Such functional options are also combined according
//   to the rules described above, but they only have effect for the predefined report options.
//   Only report functional options are in effect for user report options,
//   they can be disabled only by disabling the entire report.
//
Procedure ReportOptionsOnSetup(Settings) Export
	ReportOptionsModule = CommonUse.CommonModule("ReportOptions");
	ReportOptionsModule.SetupReportInManagerModule(Settings, Metadata.Reports.UserInfo);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Event subscription handlers.
//

// Runs external user presentation update when its authorization object presentation is changed.
//
//  The following authorization object types must be included in the event subscription:
// Metadata.Catalogs.ExternalUsers.Attributes.AuthorizationObject.Type.
// Example: Catalog.Individuals, Catalog.Counterparties.
//
Procedure UpdateExternalUserPresentationOnWrite(Val Object, Cancel) Export
	
	If Object.DataExchange.Load Then
		Return;
	EndIf;
	
	If TypeOf(Object.Ref) = Type("CatalogRef.ExternalUsers") Then
		Return;
	EndIf;
	
	UpdateExternalUserPresentation(Object.Ref);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for user operations.
//

// Returns the stored value of user password.
//
// Parameters:
//  Password       - String - password whose stored value is retrieved.
//  InfobaseUserID - UUID - infobase user whose stored password value is compared with
//                          the retrieved value. The comparison result is stored to the Identical parameter.
//  Identical      - Boolean (return value) - see comment to InfobaseUserID parameter.
//                                
// Returns:
//  String - stored  password.
//
Function StoredStringPasswordValue(Val Password,
                                   Val InfobaseUserID = Undefined,
                                   Identical = False) Export
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		TempInfobaseUser = InfobaseUsers.CreateUser();
		TempInfobaseUser.StandardAuthentication = True;
		TempInfobaseUser.Password = Password;
		
		TempInfobaseUser.Name = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Temporary user (%1)'"),
			New UUID);
		
		TempInfobaseUser.Write();
		
		TempInfobaseUser = InfobaseUsers.FindByUUID(
			TempInfobaseUser.UUID);
		
		StoredPasswordValue = TempInfobaseUser.StoredPasswordValue;
		RollbackTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If TypeOf(InfobaseUserID) = Type("UUID") Then
		
		InfobaseUser = InfobaseUsers.FindByUUID(
			InfobaseUserID);
		
		If TypeOf(InfobaseUser) = Type("InfobaseUser") Then
			Identical = (StoredPasswordValue = InfobaseUser.StoredPasswordValue);
		EndIf;
	EndIf;
	
	Return StoredPasswordValue;
	
EndFunction

// Returns the current access level for changing infobase user properties.
// 
// Parameters:
//  ObjectDescription - CatalogObject.Users
//                    - CatalogObject.ExternalUsers
//                    - FormDataStructure - created from the objects listed above.
//
//  ProcessingParameters - if Undefined, get data from object description, 
//                         otherwise get data from processing parameters.
//
// Returns:
//  Structure with the following properties:
//   FullAdministrator - Boolean - any action on any user or its infobase user.
//   FullAccess        - Boolean - the same rights as for FullAdministrator, except the FullAdministrator right.
//   ListManagement    - adding and changing users:
//                            - for new users without the logon right any property
//                              can be specified, except for granting the logon right.
//                            - for users with the logon right, any property
//                              can be specified, except granting the logon right
//                              and changing authentication settings (see below).
//   LogonSettings     - Boolean – changing infobase user properties: Name, OSUser, properties of 
//                                 OpenIDAuthentication, StandardAuthentication, and OSAuthentication catalog items,
//                                and Roles (if role editing is not prohibited at the development stage).
//   ChangeCurrent     - changing current user Password and Language.
//   AccessDenied      - the access levels listed above are not available.
//
Function UserPropertyAccessLevel(ObjectDescription, ProcessingParameters = Undefined) Export
	
	AccessLevel = New Structure;
	
	// Full administrator (all data)
	AccessLevel.Insert("FullAdministrator", Users.InfobaseUserWithFullAccess(, True));
	
	// Full access user (business data)
	AccessLevel.Insert("FullAccess", Users.InfobaseUserWithFullAccess());
	
	If TypeOf(ObjectDescription.Ref) = Type("CatalogRef.Users") Then
	  // Person responsible for the user list
		AccessLevel.Insert("ListManagement",
			AccessRight("Insert", Metadata.Catalogs.Users)
			And (AccessLevel.FullAccess
			   Or Not Users.InfobaseUserWithFullAccess(ObjectDescription.Ref)));
		// User of the current infobase user
		AccessLevel.Insert("ChangeCurrent",
			AccessLevel.FullAccess
			Or AccessRight("Update", Metadata.Catalogs.Users)
			  And ObjectDescription.Ref = Users.AuthorizedUser());
		
	ElsIf TypeOf(ObjectDescription.Ref) = Type("CatalogRef.ExternalUsers") Then
		// Person responsible for the external user list
		AccessLevel.Insert("ListManagement",
			AccessRight("Insert", Metadata.Catalogs.ExternalUsers)
			And (AccessLevel.FullAccess
			   Or Not Users.InfobaseUserWithFullAccess(ObjectDescription.Ref)));
		// External user of the current infobase user
		AccessLevel.Insert("ChangeCurrent",
			AccessLevel.FullAccess
			Or AccessRight("Update", Metadata.Catalogs.ExternalUsers)
			  And ObjectDescription.Ref = Users.AuthorizedUser());
	EndIf;
	
	If ProcessingParameters = Undefined Then
		SetPrivilegedMode(True);
		If ValueIsFilled(ObjectDescription.InfobaseUserID) Then
			InfobaseUser = InfobaseUsers.FindByUUID(
				ObjectDescription.InfobaseUserID);
		Else
			InfobaseUser = Undefined;
		EndIf;
		UserWithoutLogonSettingsOrPrepared =
			    InfobaseUser = Undefined
			Or ObjectDescription.Prepared
			    And Not Users.CanLogOnToApplication(InfobaseUser);
		SetPrivilegedMode(False);
	Else
		UserWithoutLogonSettingsOrPrepared =
			    Not ProcessingParameters.OldInfobaseUserExists
			Or ProcessingParameters.OldUser.Prepared
			    And Not Users.CanLogOnToApplication(ProcessingParameters.OldInfobaseUserDescription);
	EndIf;
	
	// Full access user (business data)
	AccessLevel.Insert("LogonSettings",
		    AccessLevel.FullAdministrator
		Or AccessLevel.FullAccess
		Or AccessLevel.ListManagement
		  And UserWithoutLogonSettingsOrPrepared);
	
	AccessLevel.Insert("AccessDenied",
		  Not AccessLevel.FullAdministrator
		And Not AccessLevel.FullAccess
		And Not AccessLevel.ListManagement
		And Not AccessLevel.ChangeCurrent
		And Not AccessLevel.LogonSettings);
	
	Return AccessLevel;
	
EndFunction

// The procedure is called in BeforeWrite handler of User or ExternalUser catalog.
Procedure StartInfobaseUserProcessing(UserObject,
                                      ProcessingParameters,
                                      DeletingUserFromCatalog = False) Export
	
	ProcessingParameters = New Structure;
	AdditionalProperties = UserObject.AdditionalProperties;
	
	ProcessingParameters.Insert("DeletingUserFromCatalog", DeletingUserFromCatalog);
	ProcessingParameters.Insert("InsufficientRightsMessageText",
		NStr("en = 'Insufficient rights to change infobase user.'"));
	
	If AdditionalProperties.Property("CopyingValue")
	   And ValueIsFilled(AdditionalProperties.CopyingValue)
	   And TypeOf(AdditionalProperties.CopyingValue) = TypeOf(UserObject.Ref) Then
		
		ProcessingParameters.Insert("CopyingValue", AdditionalProperties.CopyingValue);
	EndIf;
	
	// Catalog attributes that are set automatically (checking that they are not changed)
	AutoAttributes = New Structure;
	AutoAttributes.Insert("InfobaseUserID");
	AutoAttributes.Insert("InfobaseUserProperties");
	ProcessingParameters.Insert("AutoAttributes", AutoAttributes);
	// Catalog attributes that cannot be changed in event subscriptions (checking initial values)
	AttributesToLock = New Structure;
	AttributesToLock.Insert("Internal", False); // Value for external user
	AttributesToLock.Insert("DeletionMark");
	AttributesToLock.Insert("NotValid");
	AttributesToLock.Insert("Prepared");
	ProcessingParameters.Insert("AttributesToLock", AttributesToLock);
	
	RememberUserProperties(UserObject, ProcessingParameters);
	
	AccessLevel = UserPropertyAccessLevel(UserObject, ProcessingParameters);
	ProcessingParameters.Insert("AccessLevel", AccessLevel);
	
	// BeforeStartInfobaseUserProcessing (for SaaS support).
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations") Then
		UsersInternalSaaSModule = CommonUse.CommonModule("UsersInternalSaaS");
		UsersInternalSaaSModule.BeforeStartInfobaseUserProcessing(UserObject, ProcessingParameters);
	EndIf;
	
	If ProcessingParameters.OldUser.Prepared <> UserObject.Prepared
	   And Not AccessLevel.FullAccess Then
		
		Raise ProcessingParameters.InsufficientRightsMessageText;
	EndIf;
	
	// Support of interactive deletion mark and batch modification of DeletionMark and NotValid attributes
	If ProcessingParameters.OldInfobaseUserExists
	   And Users.CanLogOnToApplication(ProcessingParameters.OldInfobaseUserDescription)
	   And Not AdditionalProperties.Property("InfobaseUserDescription")
	   And (  ProcessingParameters.OldUser.DeletionMark = False
	      And UserObject.DeletionMark = True
	    Or ProcessingParameters.OldUser.NotValid = False
	      And UserObject.NotValid  = True) Then
		
		AdditionalProperties.Insert("InfobaseUserDescription", New Structure);
		AdditionalProperties.InfobaseUserDescription.Insert("Action", "Write");
		AdditionalProperties.InfobaseUserDescription.Insert("CanLogOnToApplication", False);
	EndIf;
	
	If Not AdditionalProperties.Property("InfobaseUserDescription") Then
		If AccessLevel.ListManagement
		   And Not ProcessingParameters.OldInfobaseUserExists
		   And ValueIsFilled(UserObject.InfobaseUserID) Then
			// Clearing infobase user ID
			UserObject.InfobaseUserID = Undefined;
			ProcessingParameters.AutoAttributes.InfobaseUserID =
				UserObject.InfobaseUserID;
		EndIf;
		Return;
	EndIf;
	InfobaseUserDescription = AdditionalProperties.InfobaseUserDescription;
	
	If Not InfobaseUserDescription.Property("Action") Then
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Error writing user %1.
			           |The Action property is not specified in the InfobaseUserDescription parameter.'"),
			UserObject.Ref);
	EndIf;
	
	If InfobaseUserDescription.Action <> "Write"
	   And InfobaseUserDescription.Action <> "Delete" Then
		
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Error writing user %1.
			           |The Action property of the InfobaseUserDescription parameter
			           |contains an invalid value: %2.'"),
			UserObject.Ref,
			InfobaseUserDescription.Action);
	EndIf;
	ProcessingParameters.Insert("Action", InfobaseUserDescription.Action);
	
	Handlers = CommonUse.InternalEventHandlers("StandardSubsystems.Users\OnStartInfobaseUserProcessing");
	For Each Handler In Handlers Do
		Handler.Module.OnStartInfobaseUserProcessing(ProcessingParameters, InfobaseUserDescription);
	EndDo;
	
	If Not ProcessingParameters.Property("Action") Then
		Return;
	EndIf;
	
	If AccessLevel.AccessDenied Then
		Raise ProcessingParameters.InsufficientRightsMessageText;
	EndIf;
	
	If InfobaseUserDescription.Action = "Delete" Then
		
		If    ProcessingParameters.OldInfobaseUserExists And Not AccessLevel.FullAdministrator
		 Or Not ProcessingParameters.OldInfobaseUserExists And Not AccessLevel.FullAccess Then
			
			Raise ProcessingParameters.InsufficientRightsMessageText;
		EndIf;
		
	ElsIf Not AccessLevel.ListManagement Then // Action = "Write"
		
		If Not AccessLevel.ChangeCurrent
		 Or Not ProcessingParameters.OldInfobaseUserCurrent Then
			
			Raise ProcessingParameters.InsufficientRightsMessageText;
		EndIf;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If InfobaseUserDescription.Action = "Write"
	   And InfobaseUserDescription.Property("UUID")
	   And ValueIsFilled(InfobaseUserDescription.UUID)
	   And InfobaseUserDescription.UUID
	     <> ProcessingParameters.OldUser.InfobaseUserID Then
		
		ProcessingParameters.Insert("InfobaseUserSetting");
		
		If ProcessingParameters.OldInfobaseUserExists Then
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Error writing user %1.
				           |Cannot map the infobase user to the user from the catalog
				           |as the catalog user is mapped to another infobase user.'"),
				UserObject.Description);
		EndIf;
		
		FoundUser = Undefined;
		
		If UserByIDExists(
			InfobaseUserDescription.UUID,
			UserObject.Ref,
			FoundUser) Then
			
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Error writing user %1.
				           |Cannot map the infobase user to the user from the catalog
				           |as the infobase user is mapped to another user
				           |from the %2 catalog.'"),
				FoundUser,
				UserObject.Description);
		EndIf;
		
		If Not AccessLevel.FullAccess Then
			Raise ProcessingParameters.InsufficientRightsMessageText;
		EndIf;
	EndIf;
	
	If InfobaseUserDescription.Action = "Write" Then
		
		// Checking if user can change users with full access
		If ProcessingParameters.OldInfobaseUserExists Then
			
			If Not ProcessingParameters.OldInfobaseUserDescription.Roles.Find("FullAdministrator") = Undefined
			   And Not AccessLevel.FullAdministrator
			 Or Not ProcessingParameters.OldInfobaseUserDescription.Roles.Find("FullAccess") = Undefined
			   And Not AccessLevel.FullAccess Then
				
				Raise ProcessingParameters.InsufficientRightsMessageText;
			EndIf;
		EndIf;
		
		// Checking if unavailable properties can be changed
		ValidProperties = New Structure;
		ValidProperties.Insert("UUID"); // Checked above
		
		If AccessLevel.ChangeCurrent Then
			ValidProperties.Insert("Password");
			ValidProperties.Insert("Language");
		EndIf;
		
		If AccessLevel.ListManagement Then
			ValidProperties.Insert("FullName");
			ValidProperties.Insert("ShowInList");
			ValidProperties.Insert("CannotChangePassword");
			ValidProperties.Insert("Language");
			ValidProperties.Insert("RunMode");
		EndIf;
		
		If AccessLevel.LogonSettings Then
			ValidProperties.Insert("Name");
			ValidProperties.Insert("StandardAuthentication");
			ValidProperties.Insert("Password");
			ValidProperties.Insert("OSAuthentication");
			ValidProperties.Insert("OSUser");
			ValidProperties.Insert("OpenIDAuthentication");
			ValidProperties.Insert("Roles");
		EndIf;
		
		If Not AccessLevel.FullAccess Then
			AllProperties = Users.NewInfobaseUserInfo();
			
			For Each KeyAndValue In InfobaseUserDescription Do
				
				If AllProperties.Property(KeyAndValue.Key)
				   And Not ValidProperties.Property(KeyAndValue.Key) Then
					
					Raise ProcessingParameters.InsufficientRightsMessageText;
				EndIf;
			EndDo;
		EndIf;
		
		WriteInfobaseUserInternal(UserObject, ProcessingParameters);
	Else
		DeleteInfobaseUser(UserObject, ProcessingParameters);
	EndIf;
	
	// Updating value of the attribute that is checked during the writing
	ProcessingParameters.AutoAttributes.InfobaseUserID =
		UserObject.InfobaseUserID;
	
	NewInfobaseUserDescription = Undefined;
	If Users.ReadInfobaseUser(
	         UserObject.InfobaseUserID,
	         NewInfobaseUserDescription) Then
		
		ProcessingParameters.Insert("NewInfobaseUserExists", True);
		ProcessingParameters.Insert("NewInfobaseUserDescription", NewInfobaseUserDescription);
		
		// Checking if user can change users with full access
		If ProcessingParameters.OldInfobaseUserExists Then
			
			If Not ProcessingParameters.NewInfobaseUserDescription.Roles.Find("FullAdministrator") = Undefined
			   And Not AccessLevel.FullAdministrator
			 Or Not ProcessingParameters.NewInfobaseUserDescription.Roles.Find("FullAccess") = Undefined
			   And Not AccessLevel.FullAccess Then
				
				Raise ProcessingParameters.InsufficientRightsMessageText;
			EndIf;
		EndIf;
	Else
		ProcessingParameters.Insert("NewInfobaseUserExists", False);
	EndIf;
	
	// AfterStartInfobaseUserProcessing (SaaS support)
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations") Then
		UsersInternalSaaSModule = CommonUse.CommonModule("UsersInternalSaaS");
		UsersInternalSaaSModule.AfterStartInfobaseUserProcessing(UserObject, ProcessingParameters);
	EndIf;
	
EndProcedure

// The procedure is called in the OnWrite handler in User or ExternalUser catalog.
//
Procedure EndInfobaseUserProcessing(UserObject, ProcessingParameters) Export
	
	CheckUserAttributeChanges(UserObject, ProcessingParameters);
	
	// BeforeCompleteInfobaseUserProcessing (SaaS support)
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations") Then
		UsersInternalSaaSModule = CommonUse.CommonModule("UsersInternalSaaS");
		UsersInternalSaaSModule.BeforeCompleteInfobaseUserProcessing(UserObject, ProcessingParameters);
	EndIf;
	
	If Not ProcessingParameters.Property("Action") Then
		Return;
	EndIf;
	
	If ProcessingParameters.Property("AdministratorWriting") Then
		EventHandlers = CommonUse.InternalEventHandlers(
			"StandardSubsystems.Users\OnWriteAdministrator");
		
		SetPrivilegedMode(True);
		For Each Handler In EventHandlers Do
			Handler.Module.OnWriteAdministrator(UserObject.Ref);
		EndDo;
		SetPrivilegedMode(False);
	EndIf;
	
	UpdateRoles = True;
	
	// OnCompleteInfobaseUserProcessing (SaaS support)
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations") Then
		UsersInternalSaaSModule = CommonUse.CommonModule("UsersInternalSaaS");
		UsersInternalSaaSModule.OnCompleteInfobaseUserProcessing(
			UserObject, ProcessingParameters, UpdateRoles);
	EndIf;
	
	If ProcessingParameters.Property("InfobaseUserSetting") And UpdateRoles Then
		ServiceUserPassword = Undefined;
		If UserObject.AdditionalProperties.Property("ServiceUserPassword") Then
			ServiceUserPassword = UserObject.AdditionalProperties.ServiceUserPassword;
		EndIf;
		
		AfterSetInfobaseUser(UserObject.Ref, ServiceUserPassword);
	EndIf;
	
	CopyInfobaseUserSettings(UserObject, ProcessingParameters);
	
EndProcedure

// The procedure is called when processing the InfobaseUserProperties user property in a catalog.
// 
// Parameters:
//  UserDetails           - CatalogObject.Users, CatalogObject.ExternalUsers, 
//                          FormDataStructure, contains InfobaseUserProperties property.
//                        - CatalogRef.Users, CatalogRef.ExternalUsers -
//                          reference to object whose InfobaseUserProperties property is read.
//  CanLogOnToApplication - Boolean - if False but the stored value is True,
//                          the values of authentication properties are all False, as they are disabled in Designer.
//
// Returns:
//  Structure.
//
Function InfobaseUserStoredProperties(UserDetails, CanLogOnToApplication = False) Export
	
	Properties = New Structure;
	Properties.Insert("CanLogOnToApplication",  False);
	Properties.Insert("StandardAuthentication", False);
	Properties.Insert("OpenIDAuthentication",   False);
	Properties.Insert("OSAuthentication",       False);
	
	If TypeOf(UserDetails) = Type("CatalogRef.Users")
	 Or TypeOf(UserDetails) = Type("CatalogRef.ExternalUsers") Then
		
		PropertyStorage = CommonUse.ObjectAttributeValue(
			UserDetails, "InfobaseUserProperties");
	Else
		PropertyStorage = UserDetails.InfobaseUserProperties;
	EndIf;
	
	If TypeOf(PropertyStorage) <> Type("ValueStorage") Then
		Return Properties;
	EndIf;
	
	SavedProperties = PropertyStorage.Get();
	
	If TypeOf(SavedProperties) <> Type("Structure") Then
		Return Properties;
	EndIf;
	
	For Each KeyAndValue In Properties Do
		If SavedProperties.Property(KeyAndValue.Key)
		   And TypeOf(SavedProperties[KeyAndValue.Key]) = Type("Boolean") Then
			
			Properties[KeyAndValue.Key] = SavedProperties[KeyAndValue.Key];
		EndIf;
	EndDo;
	
	If Properties.CanLogOnToApplication And Not CanLogOnToApplication Then
		Properties.Insert("StandardAuthentication", False);
		Properties.Insert("OpenIDAuthentication",      False);
		Properties.Insert("OSAuthentication",          False);
	EndIf;
	
	Return Properties;
	
EndFunction
 

// The function cannot be called from background jobs with empty user.
//
Function CreateFirstAdministratorRequired(Val InfobaseUserDescription,
                                              Text = Undefined) Export
	
	If CommonUseCached.DataSeparationEnabled()
		And CommonUseCached.CanUseSeparatedData() Then
		
		Return False;
	EndIf;
	
	SetPrivilegedMode(True);
	CurrentInfobaseUser = InfobaseUsers.CurrentUser();
	
	If Not ValueIsFilled(CurrentInfobaseUser.Name)
	   And InfobaseUsers.GetUsers().Count() = 0 Then
		
		If TypeOf(InfobaseUserDescription) = Type("Structure") Then
			// Checking before writing user or infobase user without administrative privileges.
			
			If InfobaseUserDescription.Property("Roles") Then
				Roles = InfobaseUserDescription.Roles;
			Else
				Roles = New Array;
			EndIf;
			
			If RoleEditProhibition()
				//must be deleted in next releases
				//begin
				Or Roles = Undefined 
				//end
				Or Roles.Find("FullAccess") = Undefined
				Or Roles.Find(Users.FullAdministratorRole().Name) = Undefined Then
				
				// Preparing text of the question that is displayed when writing the first administrator.
				Text = NStr("en = 'This is the first user in the application user list,
				                   |so it is automatically assigned the ""Full access"" role.
				                   |Do you want to continue?'");
				
				If Not RoleEditProhibition() Then
					Return True;
				EndIf;
				
				EventHandlers = CommonUse.InternalEventHandlers(
					"StandardSubsystems.Users\OnDefineQuestionTextBeforeWriteFirstAdministrator");
				
				For Each Handler In EventHandlers Do
					Handler.Module.OnDefineQuestionTextBeforeWriteFirstAdministrator(Text);
				EndDo;
				
				Return True;
			EndIf;
		Else
			// Checking user rights before writing an external user
			Text = NStr("en = 'The first infobase user must have full access.
			                   |An external user cannot have full access.
			                   |First create the Administrator in the Users catalog.'");
			Return True;
		EndIf;
	EndIf;
	
	Return False;
	
EndFunction

// Returns user properties for an infobase user with empty name.
//
Function UnspecifiedUserProperties() Export
	
	SetPrivilegedMode(True);
	
	Properties = New Structure;
	
	// Reference to found catalog object that matches an unspecified user.
	Properties.Insert("Ref", Undefined);
	
	// Reference that is used for search and creation 
	// of unspecified user in the Users catalog.
	Properties.Insert("StandardRef", Catalogs.Users.GetRef(
		New UUID("aa00559e-ad84-4494-88fd-f0826edc46f0")));
	
	// Full name that is set in the Users catalog item 
	// when creating an unspecified user.
	Properties.Insert("FullName", Users.UnspecifiedUserFullName());
	
 // Full name that is used to search for an unspecified user
 // using the old method. Is used to support old versions of unspecified user. 
 // This name does not required changing.
	Properties.Insert("FullNameForSearch", NStr("en = '<Not specified>'"));
	
	// Searching for infobase user by UUID.
	Query = New Query;
	Query.SetParameter("Ref", Properties.StandardRef);
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.Ref = &Ref";
	
	BeginTransaction();
	Try
		If Query.Execute().IsEmpty() Then
			Query.SetParameter("FullName", Properties.FullNameForSearch);
			Query.Text =
			"SELECT TOP 1
			|	Users.Ref
			|FROM
			|	Catalog.Users AS Users
			|WHERE
			|	Users.Description = &FullName";
			Result = Query.Execute();
			
			If Not Result.IsEmpty() Then
				Selection = Result.Select();
				Selection.Next();
				Properties.Ref = Selection.Ref;
			EndIf;
		Else
			Properties.Ref = Properties.StandardRef;
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return Properties;
	
EndFunction

// Creates a user with <Not specified> description.
//
// Returns:
//  CatalogRef.Users
// 
Function CreateUnspecifiedUser() Export
	
	UnspecifiedUserProperties = UnspecifiedUserProperties();
	
	If CommonUse.RefExists(UnspecifiedUserProperties.StandardRef) Then
		
		Return UnspecifiedUserProperties.StandardRef;
		
	Else
		
		NewUser = Catalogs.Users.CreateItem();
		NewUser.Internal = True;
		NewUser.Description = UnspecifiedUserProperties.FullName;
		NewUser.SetNewObjectRef(UnspecifiedUserProperties.StandardRef);
		NewUser.DataExchange.Load = True;
		NewUser.Write();
		
		Return NewUser.Ref;
		
	EndIf;
	
EndFunction

// Checks whether the infobase user description structure is filled correctly.
// If errors are found, sets the Cancel parameter to True and sends error messages.
//
// Parameters:
//  InfobaseUserDescription - Structure - infobase user description.
//  Cancel                  - Boolean - operation cancellation flag.
//                                      It is set if errors are found.
//
// Returns:
//  Boolean - if True, errors are not found.
//
Function CheckInfobaseUserDescription(Val InfobaseUserDescription, Cancel) Export
	
	If InfobaseUserDescription.Property("Name") Then
		Name = InfobaseUserDescription.Name;
		
		If IsBlankString(Name) Then
 
			CommonUseClientServer.MessageToUser(
				NStr("en = 'Name (the logon name) is not filled.'"),
				,
				"Name",
				,
				Cancel);
			
		ElsIf StrLen(Name) > 64 Then
			// The settings storage uses only the first 64 characters of the infobase user name.
			CommonUseClientServer.MessageToUser(
				NStr("en = 'Name (the logon name) exceeds 64 characters.'"),
				,
				"Name",
				,
				Cancel);
			
		ElsIf Find(Name, ":") > 0 Then
     // Web authentication uses the ":" character 
			// as a separator between a user name and a password.
			CommonUseClientServer.MessageToUser(
				NStr("en = 'Name (the logon name) contains an illegal character "":"".'"),
				,
				"Name",
				,
				Cancel);
				
		Else
			SetPrivilegedMode(True);
			InfobaseUser = InfobaseUsers.FindByName(Name);
			SetPrivilegedMode(False);
			
			If InfobaseUser <> Undefined
			   And InfobaseUser.UUID
			     <> InfobaseUserDescription.InfobaseUserID Then
				
				FoundUser = Undefined;
				UserByIDExists(
					InfobaseUser.UUID, , FoundUser);
				
				If FoundUser = Undefined
				 Or Not Users.InfobaseUserWithFullAccess() Then
					
					ErrorText = NStr("en = 'Name (the logon name) is not unique.'");
				Else
					ErrorText = StringFunctionsClientServer.SubstituteParametersInString(
						NStr("en = 'Name (the logon name) is not unique. It belongs to user %1.'"),
						String(FoundUser));
				EndIf;
				
				CommonUseClientServer.MessageToUser(
					ErrorText, , "Name", , Cancel);
			EndIf;
		EndIf;
	EndIf;
	
	If InfobaseUserDescription.Property("Password") Then
		
		If InfobaseUserDescription.Password <> Undefined
			And InfobaseUserDescription.Password
			  <> InfobaseUserDescription.PasswordConfirmation Then
			
			CommonUseClientServer.MessageToUser(
				NStr("en = 'Password and password confirmation do not match.'"),
				,
				"Password",
				,
				Cancel);
		EndIf;
		
	EndIf;
	
	If InfobaseUserDescription.Property("OSUser") Then
		
		If Not IsBlankString(InfobaseUserDescription.OSUser)
		   And Not IsTrainingPlatform() Then
			
			SetPrivilegedMode(True);
			Try
				InfobaseUser = InfobaseUsers.CreateUser();
				InfobaseUser.OSUser = InfobaseUserDescription.OSUser;
			Except
				CommonUseClientServer.MessageToUser(
					NStr("en = 'The OS user name must have the following format:
					           |\\DomainName\UserName.'"),
					,
					"OSUser",
					,
					Cancel);
			EndTry;
			SetPrivilegedMode(False);
		EndIf;
		
	EndIf;
	
	Return Not Cancel;
	
EndFunction

// Writes the specified infobase user according to the data separation mode.
// If data separation mode is enabled, user rights are checked before writing the user.
//
// Parameters:
//  InfobaseUser - InfobaseUser - object that is written.
//
Procedure WriteInfobaseUser(InfobaseUser) Export
	
	Handlers = CommonUse.InternalEventHandlers("StandardSubsystems.Users\BeforeWriteInfobaseUser");
	For Each Handler In Handlers Do
		Handler.Module.BeforeWriteInfobaseUser(InfobaseUser.UUID);
	EndDo;
	
	CheckUserRights(InfobaseUser, "OnWrite");
	
	InfobaseUpdateInternal.SetDisplayNewUserDescriptionsFlag(InfobaseUser.Name);
	
	InfobaseUser.Write();

EndProcedure

// Checks whether an infobase user exists.
//
// Parameters:
//  ID  - String - infobase user name,
//        UUID - infobase user ID.
//
// Returns:
//  Boolean.
//
Function InfobaseUserExists(Val ID) Export
	
	SetPrivilegedMode(True);
	
	If TypeOf(ID) = Type("UUID") Then
		InfobaseUser = InfobaseUsers.FindByUUID(ID);
	Else
		InfobaseUser = InfobaseUsers.FindByName(ID);
	EndIf;
	
	If InfobaseUser = Undefined Then
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction

// Defines if the item with the specified infobase user UUID exists
// in the Users or ExternalUsers catalog.
// This function is used to verify that InfobaseUser matches
// a single item from Users or ExternalUsers catalog.
//
// Parameters:
//  UUID - infobase user ID.
//
//  RefToCurrent - CatalogRef.Users, CatalogRef.ExternalUsers
//               - remove the specified reference from the search.                      
//                 Undefined - search among all catalog items.
//
//  FoundUser (return value):
//             Undefined - user does not exist.
//             CatalogRef.Users,
//             CatalogRef.ExternalUsers - user is found.
//
//  ServiceUserID - Boolean:
//                  False - check InfobaseUserID.
//                  True  - check ServiceUserID.
//
// Returns:
//  Boolean.
//
Function UserByIDExists(UUID,
                        RefToCurrent = Undefined,
                        FoundUser = Undefined,
                        ServiceUserID = False) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("RefToCurrent", RefToCurrent);
	Query.SetParameter("UUID", UUID);
	Query.Text = 
	"SELECT
	|	Users.Ref AS User
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.InfobaseUserID = &UUID
	|	AND Users.Ref <> &RefToCurrent
	|
	|UNION ALL
	|
	|SELECT
	|	ExternalUsers.Ref
	|FROM
	|	Catalog.ExternalUsers AS ExternalUsers
	|WHERE
	|	ExternalUsers.InfobaseUserID = &UUID
	|	AND ExternalUsers.Ref <> &RefToCurrent";
	
	Result = False;
	FoundUser = Undefined;
	
	BeginTransaction();
	Try
		QueryResult = Query.Execute();
		
		If Not QueryResult.IsEmpty() Then
			Selection = QueryResult.Select();
			Selection.Next();
			FoundUser = Selection.User;
			Result = True;
			Users.FindAmbiguousInfobaseUsers(, UUID);
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return Result;
	
EndFunction

// Updates the content of user groups based on the hierarchy
// from the "User group content" information register.
// The register data is used in the user list form and in the user selection form.
// The register data can be used to increase query performance because this
// does not require hierarchy operations.
//
// Parameters:
//  UserGroup - CatalogRef.UserGroups.
//
//  User - Undefined                                        - for all users.
//       - Array with elements of the CatalogRef.Users type - for the specified users.
//       - CatalogRef.Users                                 - for the specified user.
//
//  ItemsToChange  - Undefined - no actions.
//                 - Array (return value) - array of users that have changes.                      
//  ModifiedGroups - Undefined - no actions.
//                 - Array (return value) - array of user groups that have changes.
//                      
//
Procedure UpdateUserGroupContents(Val UserGroup,
                                 Val User       = Undefined,
                                 Val ItemsToChange = Undefined,
                                 Val ModifiedGroups   = Undefined) Export
	
	If Not ValueIsFilled(UserGroup) Then
		Return;
	EndIf;
	
	If TypeOf(User) = Type("Array") And User.Count() = 0 Then
		Return;
	EndIf;
	
	If ItemsToChange = Undefined Then
		CurrentItemsToChange = New Map;
	Else
		CurrentItemsToChange = ItemsToChange;
	EndIf;
	
	If ModifiedGroups = Undefined Then
		CurrentModifiedGroups = New Map;
	Else
		CurrentModifiedGroups = ModifiedGroups;
	EndIf;
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		If UserGroup = Catalogs.UserGroups.AllUsers Then
			
			UpdateAllUsersGroupContent(
				User, , CurrentItemsToChange, CurrentModifiedGroups);
		Else
			UpdateHierarchicalUserGroupContents(
				UserGroup,
				User,
				CurrentItemsToChange,
				CurrentModifiedGroups);
		EndIf;
		
		If ItemsToChange = Undefined
		   And ModifiedGroups   = Undefined Then
			
			AfterUserGroupContentUpdate(
				CurrentItemsToChange, CurrentModifiedGroups);
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Updates the Used resource when DeletionMark or NotValid attribute is changed.
//
// Parameters:
//  UserOrGroup    - CatalogRef.Users, CatalogRef.ExternalUsers,
//                 - CatalogRef.UserGroups, CatalogRef.ExternalUserGroups. 
//  ItemsToChange  - Array (return value) - array of users or external users that have changes.
//
//  ModifiedGroups - Array (return value) - array of user groups or external user group that have changes.
//
Procedure RefreshContentUsingOfUserGroups(Val UserOrGroup,
                                          Val ItemsToChange,
                                          Val ModifiedGroups) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("UserOrGroup", UserOrGroup);
	Query.Text =
	"SELECT
	|	UserGroupContents.UserGroup,
	|	UserGroupContents.User,
	|	CASE
	|		WHEN UserGroupContents.UserGroup.DeletionMark
	|			THEN FALSE
	|		WHEN UserGroupContents.User.DeletionMark
	|			THEN FALSE
	|		WHEN UserGroupContents.User.NotValid
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS Used
	|FROM
	|	InformationRegister.UserGroupContents AS UserGroupContents
	|WHERE
	|	&Filter
	|	AND CASE
	|			WHEN UserGroupContents.UserGroup.DeletionMark
	|				THEN FALSE
	|			WHEN UserGroupContents.User.DeletionMark
	|				THEN FALSE
	|			WHEN UserGroupContents.User.NotValid
	|				THEN FALSE
	|			ELSE TRUE
	|		END <> UserGroupContents.Used";
	
	If TypeOf(UserOrGroup) = Type("CatalogRef.Users")
	 Or TypeOf(UserOrGroup) = Type("CatalogRef.ExternalUsers") Then
		
		Query.Text = StrReplace(Query.Text, "&Filter",
			"UserGroupContents.User = &UserOrGroup");
	Else
		Query.Text = StrReplace(Query.Text, "&Filter",
			"UserGroupContents.UserGroup = &UserOrGroup");
	EndIf;
	
	RecordSet = InformationRegisters.UserGroupContents.CreateRecordSet();
	Write = RecordSet.Add();
	
	BeginTransaction();
	Try
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			
			RecordSet.Filter.UserGroup.Set(Selection.UserGroup);
			RecordSet.Filter.User.Set(Selection.User);
			
			Write.UserGroup = Selection.UserGroup;
			Write.User        = Selection.User;
			Write.Used        = Selection.Used;
			
			RecordSet.Write();
			
			ModifiedGroups.Insert(Selection.UserGroup);
			ItemsToChange.Insert(Selection.User);
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// For internal use only.
//
Procedure AfterUserGroupContentUpdate(ItemsToChange, ModifiedGroups) Export
	
	If ItemsToChange.Count() = 0 Then
		Return;
	EndIf;
	
	ItemsToChangeArray = New Array;
	
	For Each KeyAndValue In ItemsToChange Do
		ItemsToChangeArray.Add(KeyAndValue.Key);
	EndDo;
	
	ModifiedGroupsArray = New Array;
	For Each KeyAndValue In ModifiedGroups Do
		ModifiedGroupsArray.Add(KeyAndValue.Key);
	EndDo;
	
	AfterUpdateUserGroupContentsOverridable(ItemsToChangeArray, ModifiedGroupsArray);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for external user operations.

// Updates the content of external user groups based on the
// hierarchy from the "User group content" information register.
// The register data is used in the external user list form and the external user selection form.
// The register data can be used to increase query performance
// because this does not require hierarchy operations.
//
// Parameters:
//  ExternalUserGroup - CatalogRef.ExternalUserGroups - if AllExternalUsers group
//                      is specified, all automatic groups are updated
//                      according to the authorization object types.
//  ExternalUser      - Undefined                - for all external users.
//                    - Array with elements of the CatalogRef.ExternalUsers type
//                                               - for the specified external users.
//                    - CatalogRef.ExternalUsers - for the specified external user.
//  ItemsToChange  - Undefined - no actions.
//                 - Array (return value) - array of external users that have changes.
//  ModifiedGroups - Undefined - no actions.
//                 - Array (return value) - array of external user groups
//                   that have changes.
//
Procedure UpdateExternalUserGroupContent(Val ExternalUserGroup,
                                         Val ExternalUser = Undefined,
                                         Val ItemsToChange  = Undefined,
                                         Val ModifiedGroups    = Undefined) Export
	
	If Not ValueIsFilled(ExternalUserGroup) Then
		Return;
	EndIf;
	
	If TypeOf(ExternalUser) = Type("Array") And ExternalUser.Count() = 0 Then
		Return;
	EndIf;
	
	If ItemsToChange = Undefined Then
		CurrentItemsToChange = New Map;
	Else
		CurrentItemsToChange = ItemsToChange;
	EndIf;
	
	If ModifiedGroups = Undefined Then
		CurrentModifiedGroups = New Map;
	Else
		CurrentModifiedGroups = ModifiedGroups;
	EndIf;
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		If ExternalUserGroup = Catalogs.ExternalUserGroups.AllExternalUsers Then
			
			UpdateAllUsersGroupContent(
				ExternalUser, True, CurrentItemsToChange, CurrentModifiedGroups);
			
			UpdateGroupContentByAuthorizationObjectType(
				, ExternalUser, CurrentItemsToChange, CurrentModifiedGroups);
			
		ElsIf CommonUse.ObjectAttributeValue(
		            ExternalUserGroup, "AllAuthorizationObjects") = True Then
			
			UpdateGroupContentByAuthorizationObjectType(
				ExternalUserGroup,
				ExternalUser,
				CurrentItemsToChange,
				CurrentModifiedGroups);
		Else
			UpdateHierarchicalUserGroupContents(
				ExternalUserGroup,
				ExternalUser,
				CurrentItemsToChange,
				CurrentModifiedGroups);
		EndIf;
		
		If ItemsToChange = Undefined
		   And ModifiedGroups    = Undefined Then
			
			AfterUpdateExternalUserGroupContents(
				CurrentItemsToChange, CurrentModifiedGroups);
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// For internal use only.
//
Procedure AfterUpdateExternalUserGroupContents(ItemsToChange, ModifiedGroups) Export
	
	If ItemsToChange.Count() = 0 Then
		Return;
	EndIf;
	
	ItemsToChangeArray = New Array;
	For Each KeyAndValue In ItemsToChange Do
		ItemsToChangeArray.Add(KeyAndValue.Key);
	EndDo;
	
	UpdateExternalUserRoles(ItemsToChangeArray);
	
	ModifiedGroupsArray = New Array;
	For Each KeyAndValue In ModifiedGroups Do
		ModifiedGroupsArray.Add(KeyAndValue.Key);
	EndDo;
	
	AfterUpdateUserGroupContentsOverridable(ItemsToChangeArray, ModifiedGroupsArray);
	
EndProcedure

// Updates the list of roles for infobase users that match external users.
// Roles of external users are defined by their external user groups,
// except external users whose roles are specified directly.
// The procedure is required only for resolving role editing. 
// For example, if the "Access management" subsystem is included in the configuration,
// this procedure is not required.
// 
// Parameters:
//  ExternalUserArray - Undefined - all external users,
//                      CatalogRef.ExternalUserGroup,
//                      Array with elements of the CatalogRef.ExternalUsers type.
//
Procedure UpdateExternalUserRoles(Val ExternalUserArray = Undefined) Export
	
	If RoleEditProhibition() Then
		// Roles are set using another algorithm, for example, the algorithm from AccessManagement subsystem
		Return;
	EndIf;
	
	If TypeOf(ExternalUserArray) = Type("Array")
	   And ExternalUserArray.Count() = 0 Then
		
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		If TypeOf(ExternalUserArray) <> Type("Array") Then
			
			If ExternalUserArray = Undefined Then
				ExternalUserGroup = Catalogs.ExternalUserGroups.AllExternalUsers;
			Else
				ExternalUserGroup = ExternalUserArray;
			EndIf;
			
			Query = New Query;
			Query.SetParameter("ExternalUserGroup", ExternalUserGroup);
			Query.Text =
			"SELECT
			|	UserGroupContents.User
			|FROM
			|	InformationRegister.UserGroupContents AS UserGroupContents
			|WHERE
			|	UserGroupContents.UserGroup = &ExternalUserGroup";
			
			ExternalUserArray = Query.Execute().Unload().UnloadColumn("User");
		EndIf;
		
		Users.FindAmbiguousInfobaseUsers();
		
		InfobaseUserIDs = New Map;
		
		Query = New Query;
		Query.SetParameter("ExternalUsers", ExternalUserArray);
		Query.Text =
		"SELECT
		|	ExternalUsers.Ref AS ExternalUser,
		|	ExternalUsers.InfobaseUserID
		|FROM
		|	Catalog.ExternalUsers AS ExternalUsers
		|WHERE
		|	ExternalUsers.Ref IN(&ExternalUsers)
		|	AND (Not ExternalUsers.SetRolesDirectly)";
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			InfobaseUserIDs.Insert(
				Selection.ExternalUser, Selection.InfobaseUserID);
		EndDo;
		
		// Preparing a table of external user old roles
		OldExternalUserRoles = New ValueTable;
		
		OldExternalUserRoles.Columns.Add(
			"ExternalUser", New TypeDescription("CatalogRef.ExternalUsers"));
		
		OldExternalUserRoles.Columns.Add(
			"Role", New TypeDescription("String", , New StringQualifiers(200)));
		
		CurrentNumber = ExternalUserArray.Count() - 1;
		While CurrentNumber >= 0 Do
			
			// Checking if user processing is required
			InfobaseUser = Undefined;
			InfobaseUserID = InfobaseUserIDs[ExternalUserArray[CurrentNumber]];
			If InfobaseUserID <> Undefined Then
				
				InfobaseUser = InfobaseUsers.FindByUUID(
					InfobaseUserID);
			EndIf;
			
			If InfobaseUser = Undefined
			 Or IsBlankString(InfobaseUser.Name) Then
				
				ExternalUserArray.Delete(CurrentNumber);
			Else
				For Each Role In InfobaseUser.Roles Do
					OldExternalUserRole = OldExternalUserRoles.Add();
					OldExternalUserRole.ExternalUser = ExternalUserArray[CurrentNumber];
					OldExternalUserRole.Role = Role.Name;
				EndDo;
			EndIf;
			CurrentNumber = CurrentNumber - 1;
		EndDo;
		
		// Preparing a list of roles that are missing from the metadata and need to be reset
		Query = New Query;
		Query.TempTablesManager = New TempTablesManager;
		Query.SetParameter("ExternalUsers", ExternalUserArray);
		Query.SetParameter("AllRoles", AllRoles().Table);
		Query.SetParameter("OldExternalUserRoles", OldExternalUserRoles);
		Query.SetParameter("UseExternalUsers",
			GetFunctionalOption("UseExternalUsers"));
		Query.Text =
		"SELECT
		|	OldExternalUserRoles.ExternalUser,
		|	OldExternalUserRoles.Role
		|INTO OldExternalUserRoles
		|FROM
		|	&OldExternalUserRoles AS OldExternalUserRoles
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AllRoles.Name
		|INTO AllRoles
		|FROM
		|	&AllRoles AS AllRoles
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	UserGroupContents.UserGroup AS ExternalUserGroup,
		|	UserGroupContents.User AS ExternalUser,
		|	Roles.Role.Name AS Role
		|INTO AllNewExternalUserRoles
		|FROM
		|	Catalog.ExternalUserGroups.Roles AS Roles
		|		INNER JOIN InformationRegister.UserGroupContents AS UserGroupContents
		|		ON (UserGroupContents.User IN (&ExternalUsers))
		|			AND (UserGroupContents.UserGroup = Roles.Ref)
		|			AND (&UseExternalUsers = TRUE)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	AllNewExternalUserRoles.ExternalUser,
		|	AllNewExternalUserRoles.Role
		|INTO NewExternalUserRoles
		|FROM
		|	AllNewExternalUserRoles AS AllNewExternalUserRoles
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OldExternalUserRoles.ExternalUser
		|INTO ModifiedExternalUsers
		|FROM
		|	OldExternalUserRoles AS OldExternalUserRoles
		|		LEFT JOIN NewExternalUserRoles AS NewExternalUserRoles
		|		ON (NewExternalUserRoles.ExternalUser = OldExternalUserRoles.ExternalUser)
		|			AND (NewExternalUserRoles.Role = OldExternalUserRoles.Role)
		|WHERE
		|	NewExternalUserRoles.Role IS NULL 
		|
		|UNION
		|
		|SELECT
		|	NewExternalUserRoles.ExternalUser
		|FROM
		|	NewExternalUserRoles AS NewExternalUserRoles
		|		LEFT JOIN OldExternalUserRoles AS OldExternalUserRoles
		|		ON NewExternalUserRoles.ExternalUser = OldExternalUserRoles.ExternalUser
		|			AND NewExternalUserRoles.Role = OldExternalUserRoles.Role
		|WHERE
		|	OldExternalUserRoles.Role IS NULL 
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AllNewExternalUserRoles.ExternalUserGroup,
		|	AllNewExternalUserRoles.ExternalUser,
		|	AllNewExternalUserRoles.Role
		|FROM
		|	AllNewExternalUserRoles AS AllNewExternalUserRoles
		|WHERE
		|	Not TRUE IN
		|				(SELECT TOP 1
		|					TRUE AS TrueValue
		|				FROM
		|					AllRoles AS AllRoles
		|				WHERE
		|					AllRoles.Name = AllNewExternalUserRoles.Role)";
		
		// Registering role name errors in access group profiles
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			
			MessageText = StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en= 'External role user update error.
                 |Updating user: %1.
                 |The ""%2"" role of the ""%3"" external user group
				           |is not found in the metadata.'"),
				TrimAll(Selection.ExternalUser.Description),
				Selection.Role,
				String(Selection.ExternalUserGroup));
			
			WriteLogEvent(
				NStr("en = 'Users.Role is not found in the metadata.'",
				     CommonUseClientServer.DefaultLanguageCode()),
				EventLogLevel.Error,
				,
				,
				MessageText,
				EventLogEntryTransactionMode.Transactional);
		EndDo;
		
		// Updating infobase user roles
		Query.Text =
		"SELECT
		|	ChangedExternalUsersAndRoles.ExternalUser,
		|	ChangedExternalUsersAndRoles.Role
		|FROM
		|	(SELECT
		|		NewExternalUserRoles.ExternalUser AS ExternalUser,
		|		NewExternalUserRoles.Role AS Role
		|	FROM
		|		NewExternalUserRoles AS NewExternalUserRoles
		|	WHERE
		|		NewExternalUserRoles.ExternalUser IN
		|				(SELECT
		|					ModifiedExternalUsers.ExternalUser
		|				FROM
		|					ModifiedExternalUsers AS ModifiedExternalUsers)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ExternalUsers.Ref,
		|		""""
		|	FROM
		|		Catalog.ExternalUsers AS ExternalUsers
		|	WHERE
		|		ExternalUsers.Ref IN
		|				(SELECT
		|					ModifiedExternalUsers.ExternalUser
		|				FROM
		|					ModifiedExternalUsers AS ModifiedExternalUsers)) AS ChangedExternalUsersAndRoles
		|
		|ORDER BY
		|	ChangedExternalUsersAndRoles.ExternalUser,
		|	ChangedExternalUsersAndRoles.Role";
		Selection = Query.Execute().Select();
		
		InfobaseUser = Undefined;
		While Selection.Next() Do
			If ValueIsFilled(Selection.Role) Then
				InfobaseUser.Roles.Add(Metadata.Roles[Selection.Role]);
				Continue;
			EndIf;
			If InfobaseUser <> Undefined Then
				InfobaseUser.Write();
			EndIf;
			
			InfobaseUser = InfobaseUsers.FindByUUID(
				InfobaseUserIDs[Selection.ExternalUser]);
			
			InfobaseUser.Roles.Clear();
		EndDo;
		If InfobaseUser <> Undefined Then
			InfobaseUser.Write();
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure
 
// Checks that the infobase object is used as the authorization object 
// of any external user except the specified external user (if it is specified).
//
Function AuthorizationObjectUsed(Val AuthorizationObjectRef,
                                 Val CurrentExternalUserRef = Undefined,
                                 FoundExternalUser = Undefined,
                                 CanAddExternalUser = False,
                                 ErrorText = "") Export
	
	ErrorText = NStr("en = 'The infobase object is already assigned
	                        |to another external user.'");
	
	CanAddExternalUser = AccessRight(
		"Insert", Metadata.Catalogs.ExternalUsers);
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	
	Query.SetParameter(
		"CurrentExternalUserRef", CurrentExternalUserRef);
		
	Query.SetParameter("AuthorizationObjectRef", AuthorizationObjectRef);
	
	Query.Text =
	"SELECT TOP 1
	|	ExternalUsers.Ref
	|FROM
	|	Catalog.ExternalUsers AS ExternalUsers
	|WHERE
	|	ExternalUsers.AuthorizationObject = &AuthorizationObjectRef
	|	AND ExternalUsers.Ref <> &CurrentExternalUserRef";
	
	BeginTransaction();
	Try
		Table = Query.Execute().Unload();
		If Table.Count() > 0 Then
			FoundExternalUser = Table[0].Ref;
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return Table.Count() > 0;
	
EndFunction

// Updates the external user when the presentation of its authorization object is changed.
//
Procedure UpdateExternalUserPresentation(AuthorizationObjectRef) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT TOP 1
	|	ExternalUsers.Ref
	|FROM
	|	Catalog.ExternalUsers AS ExternalUsers
	|WHERE
	|	ExternalUsers.AuthorizationObject = &AuthorizationObjectRef
	|	AND ExternalUsers.Description <> &NewAuthorizationObjectPresentation");
	Query.SetParameter("AuthorizationObjectRef", AuthorizationObjectRef);
	Query.SetParameter("NewAuthorizationObjectPresentation", String(AuthorizationObjectRef));
	
	BeginTransaction();
	Try
		QueryResult = Query.Execute();
		
		If Not QueryResult.IsEmpty() Then
			Selection = QueryResult.Select();
			Selection.Next();
			
			ExternalUserObject = Selection.Ref.GetObject();
			ExternalUserObject.Description = String(AuthorizationObjectRef);
			ExternalUserObject.Write();
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Operations with infobase user settings.

// Copies settings from a source user to a target user.
// If the value of the Move parameter is True, the source user settings are removed.
//
// Parameters:
// UserNameSource   - String – source infobase user for copying settings.
// UserNameTarget   - String – target infobase user for copying settings.
// Move             - Boolean - if True, settings are moved from one
//                    user to another, if False, they are copied.
//
Procedure CopyUserSettings(UserNameSource, UserNameTarget, Move = False) Export
	
	// Moving user report settings
	CopySettings(ReportsUserSettingsStorage, UserNameSource, UserNameTarget, Move);
	// Moving appearance settings
	CopySettings(SystemSettingsStorage,UserNameSource, UserNameTarget, Move);
	// Moving custom user settings
	CopySettings(CommonSettingsStorage, UserNameSource, UserNameTarget, Move);
	// Moving form data settings
	CopySettings(FormDataSettingsStorage, UserNameSource, UserNameTarget, Move);
	// Moving settings of quick access to additional reports and data processors
	If Not Move Then
		CopyOtherUserSettings(UserNameSource, UserNameTarget);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for moving users between groups.

// Moves a user from one group to another.
//
// Parameters:
//  UserArray   - Array - users that are copied to another group.
//  SourceGroup - CatalogRef.UserGroups - source group.
//  TargetGroup - CatalogRef.UserGroups - target group.                        
//  Move        - Boolean - if True, the users are removed from the source group.
//
// ReturnValue:
//  String - Message about the result of moving.
//
Function MoveUserToNewGroup(UserArray, SourceGroup,
												       TargetGroup, Move) Export
	
	If TargetGroup = Undefined
		Or TargetGroup = SourceGroup Then
		Return Undefined;
	EndIf;
	MovedUsersArray = New Array;
	NotMovedUserArray = New Array;
	
	For Each UserRef In UserArray Do
		
		If TypeOf(UserRef) <> Type("CatalogRef.Users")
			And TypeOf(UserRef) <> Type("CatalogRef.ExternalUsers") Then
			Continue;
		EndIf;
		
		If Not CanMoveUser(TargetGroup, UserRef) Then
			NotMovedUserArray.Add(UserRef);
			Continue;
		EndIf;
		
		If TypeOf(UserRef) = Type("CatalogRef.Users") Then
			ContentColumnName = "User";
		Else
			ContentColumnName = "ExternalUser";
		EndIf;
		
		// If the user being moved is not included in the target group, moving that user
		If TargetGroup = Catalogs.UserGroups.AllUsers
			Or TargetGroup = Catalogs.ExternalUserGroups.AllExternalUsers Then
			
			If Move Then
				DeleteUserFromGroup(SourceGroup, UserRef, ContentColumnName);
			EndIf;
			MovedUsersArray.Add(UserRef);
			
		ElsIf TargetGroup.Content.Find(UserRef, ContentColumnName) = Undefined Then
			
			AddUserToGroup(TargetGroup, UserRef, ContentColumnName);
			
			// Removing the user from the source group
			If Move Then
				DeleteUserFromGroup(SourceGroup, UserRef, ContentColumnName);
			EndIf;
			
			MovedUsersArray.Add(UserRef);
		EndIf;
		
	EndDo;
	
	UserMessage = UserMessageCreation(
		MovedUsersArray, TargetGroup, Move, NotMovedUserArray, SourceGroup);
	
	If MovedUsersArray.Count() = 0 And NotMovedUserArray.Count() = 0 Then
		If UserArray.Count() = 1 Then
			MessageText = NStr("en = 'User %1 is already included in the ""%2"" group.'");
			UserToMoveName = CommonUse.ObjectAttributeValue(UserArray[0], "Description");
		Else
			MessageText = NStr("en = 'All selected users are already included in the ""%2"" group.'");
			UserToMoveName = "";
		EndIf;
		GroupDescription = CommonUse.ObjectAttributeValue(TargetGroup, "Description");
		UserMessage.Message = StringFunctionsClientServer.SubstituteParametersInString(
			MessageText, UserToMoveName, GroupDescription);
		UserMessage.HasErrors = True;
		Return UserMessage;
	EndIf;
	
	Return UserMessage;
	
EndFunction

// Checks if an external user can be included in a group.
//
// Parameters:
//  GroupsTarget - CatalogRef.UserGroups – user group.                       
//  UserRef        - CatalogRef.User - user.                       
//
// Returns:
//  Boolean        - if False, user cannot be added to the group.
//
Function CanMoveUser(TargetGroup, UserRef) Export
	
	If TypeOf(UserRef) = Type("CatalogRef.ExternalUsers") Then
		
		If TypeOf(TargetGroup.AuthorizationObjectType) <> Type("Undefined")
			And TypeOf(UserRef.AuthorizationObject) <> TypeOf(TargetGroup.AuthorizationObjectType)
			Or TargetGroup.AllAuthorizationObjects Then
			Return False;
		EndIf;
		
	EndIf;
	
	Return True;
	
EndFunction

// Adds a user to a group.
//
// Parameters:
//  TargetGroup - CatalogRef.UserGroups - user group.                     
//  UserRef     - CatalogRef.User - user.                      
//  UserType    - String - ExternalUser or User.
//
Procedure AddUserToGroup(TargetGroup, UserRef, UserType) Export
	
	BeginTransaction();
	Try
		
		TargetGroupObject = TargetGroup.GetObject();
		ContentRow = TargetGroupObject.Content.Add();
		If UserType = "ExternalUser" Then
			ContentRow.ExternalUser = UserRef;
		Else
			ContentRow.User = UserRef;
		EndIf;
		
		TargetGroupObject.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Removes a user from a group.
//
// Parameters:
//  TargetGroup - CatalogRef.UserGroups – user group.                      
//  UserRef     - CatalogRef.User - user.                      
//  UserType    - String - ExternalUser or User.
//
Procedure DeleteUserFromGroup(OwnerGroup, UserRef, UserType) Export
	
	BeginTransaction();
	Try
		
		OwnerGroupObject = OwnerGroup.GetObject();
		If OwnerGroupObject.Content.Count() <> 0 Then
			OwnerGroupObject.Content.Delete(OwnerGroupObject.Content.Find(UserRef, UserType));
			OwnerGroupObject.Write();
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Generates an ending for the specified number of items.
//
// Parameters:
//  NumberToConvert - Number - number used as a basis for ending generation.                               
//
Function GenerateWordEnding(NumberToConvert, NumerationItemOptions = Undefined) Export
	Raise("CHECK ON TEST");
	If NumerationItemOptions = Undefined Then
		NumerationItemOptions = NStr("en = 'user,users,,,0'");
	EndIf;
	Raise("CHECK ON TEST");
	NumberInWords = NumberInWords(
		NumberToConvert,
		"L=en_US",
		NStr("en = ',,,,0'"));
	SubjectAndNumberInWords = NumberInWords(
		NumberToConvert,
		"L=en_US",
		NumerationItemOptions);
	SubjectInWords = StrReplace(
		SubjectAndNumberInWords,
		NumberInWords,
		Format(NumberToConvert, "NFD=0") + " ");
		
	Return SubjectInWords;
EndFunction

// Generates a message about the result of moving a user.
//
// Parameters:
//  UserArray   - Array - users that are copied to another group.
//  SourceGroup - CatalogRef.UserGroups - source group.                        
//  TargetGroup - CatalogRef.UserGroups - target group.                        
//  Move        - Boolean - if True, the users are removed from the source group.
//
// ReturnValue:
//  String - User message.
//
Function UserMessageCreation(UserArray, TargetGroup,
											           Move, NotMovedUserArray, SourceGroup = Undefined) Export
	
	UserCount = UserArray.Count();
	GroupDescription = CommonUse.ObjectAttributeValue(TargetGroup, "Description");
	UserMessage = Undefined;
	UnmovedUsersCount = NotMovedUserArray.Count();
	
	UserNotification = New Structure;
	UserNotification.Insert("Message");
	UserNotification.Insert("HasErrors");
	UserNotification.Insert("Users");
	
	If UnmovedUsersCount > 0 Then
		
		If UnmovedUsersCount = 1 Then
			Subject = CommonUse.ObjectAttributeValue(NotMovedUserArray[0], "Description");
			UserTypeMatchesGroup = (TypeOf(NotMovedUserArray[0].AuthorizationObject) = 
												TypeOf(TargetGroup.AuthorizationObjectType));
			UserNotification.Users = Undefined;
			UserMessage = NStr("en = 'User %1 cannot be included in the ""%2"" group,'");
			UserMessage = UserMessage + Chars.LF + 
									?(Not UserTypeMatchesGroup, 
									NStr("en = 'because the group only includes %3.'"),
									NStr("en = 'because the group has the ""All users with specified type"" property.'"));
		Else
			Subject = "";
			UserNotification.Users = StringFunctionsClientServer.StringFromSubstringArray(NotMovedUserArray, Chars.LF);
			UserMessage = NStr("en = 'Some users cannot be included in the
									               |""%2"" group because the group only includes %3 or
									               |has the ""All users with specified type"" property.'");
		EndIf;
		
		AuthorizationObjectTypePresentationItem = Metadata.FindByType(TypeOf(TargetGroup.AuthorizationObjectType)).Synonym;
		
		GroupDescription = CommonUse.ObjectAttributeValue(TargetGroup, "Description");
		UserMessage = StringFunctionsClientServer.SubstituteParametersInString(
			UserMessage, Subject, GroupDescription, Lower(AuthorizationObjectTypePresentationItem));
		
		UserNotification.Message = UserMessage;
		UserNotification.HasErrors = True;
		
		Return UserNotification;
		
	ElsIf UserCount = 1 Then
		
		StringObject = CommonUse.ObjectAttributeValue(UserArray[0], "Description");
		If TargetGroup = Catalogs.UserGroups.AllUsers
			Or TargetGroup = Catalogs.ExternalUserGroups.AllExternalUsers Then
			StringAction = NStr("en = 'removed from the'");
			GroupDescription = CommonUse.ObjectAttributeValue(SourceGroup, "Description");
		ElsIf Move Then
			StringAction = NStr("en = 'moved to the '");
		Else
			StringAction = NStr("en = 'added to the'");
		EndIf;
		
		UserMessage = NStr("en = '""%1"" %2 ""%3"" group'");
	ElsIf UserCount > 1 Then
		
		StringObject = GenerateWordEnding(UserCount);
		If TargetGroup = Catalogs.UserGroups.AllUsers Then
			StringAction = NStr("en = 'removed from the'");
			GroupDescription = CommonUse.ObjectAttributeValue(SourceGroup, "Description");
		ElsIf Move Then
			StringAction = NStr("en = 'moved to the'");
		Else
			StringAction = NStr("en = 'added to the'");
		EndIf;
		UserMessage = NStr("en = '%1 %2 ""%3"" group'");
	EndIf;
	
	If UserMessage <> Undefined Then
		UserMessage = StringFunctionsClientServer.SubstituteParametersInString(
			UserMessage, StringObject, StringAction, GroupDescription);
	EndIf;
	
	UserNotification.Message = UserMessage;
	UserNotification.HasErrors = False;
	
	Return UserNotification;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Universal procedures and functions.

// Returns nonmatching values in a value table column.
//
// Parameters:
// ColumnName - String – column name.
//  Table1     - ValueTable.
//  Table2     - ValueTable.
//
// Returns:
//  Array of values that are only present in that column in a single table.
// 
Function ColumnValueDifferences(ColumnName, Table1, Table2) Export
	
	If TypeOf(Table1) <> Type("ValueTable")
	   And TypeOf(Table2) <> Type("ValueTable") Then
		
		Return New Array;
	EndIf;
	
	If TypeOf(Table1) <> Type("ValueTable") Then
		Return Table2.UnloadColumn(ColumnName);
	EndIf;
	
	If TypeOf(Table2) <> Type("ValueTable") Then
		Return Table1.UnloadColumn(ColumnName);
	EndIf;
	
	Table11 = Table1.Copy(, ColumnName);
	Table11.GroupBy(ColumnName);
	
	Table22 = Table2.Copy(, ColumnName);
	Table22.GroupBy(ColumnName);
	
	For Each Row In Table22 Do
		NewRow = Table11.Add();
		NewRow[ColumnName] = Row[ColumnName];
	EndDo;
	
	Table11.Columns.Add("Flag");
	Table11.FillValues(1, "Flag");
	
	Table11.GroupBy(ColumnName, "Flag");
	
	Filter = New Structure("Flag", 1);
	Table = Table11.Copy(Table11.FindRows(Filter));
	
	Return Table.UnloadColumn(ColumnName);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Infobase update.

// Updates auxiliary data that depends only on configuration.
// Writes data changes in configuration versions (if the changes are available)
// to use them to update other auxiliary data,
// for example, in the UpdateAuxiliaryDataOnInfobaseUpdate handler.
//
Procedure UpdateUserSessionParameters(HasChanges = Undefined, CheckOnly = False) Export
	
	SetPrivilegedMode(True);
	
	If CheckOnly Or ExclusiveMode() Then
		DisableExclusiveMode = False;
	Else
		DisableExclusiveMode = True;
		SetExclusiveMode(True);
	EndIf;
	
	DataLock = New DataLock;
	LockItem = DataLock.Add("Constant.UserSessionParameters");
	LockItem.Mode = DataLockMode.Exclusive;
	
	BeginTransaction();
	Try
		DataLock.Lock();
		
		Constants.UserSessionParameters.CreateValueManager().UpdateCommonParameters(HasChanges, CheckOnly);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		If DisableExclusiveMode Then
			SetExclusiveMode(False);
		EndIf;
		Raise;
	EndTry;
	
	If DisableExclusiveMode Then
		SetExclusiveMode(False);
	EndIf;
	
EndProcedure

Procedure UpdateUserPredefinedContactInformationKinds() Export
	
	If Not CommonUse.SubsystemExists("StandardSubsystems.ContactInformation") Then
	    Return;
	EndIf;
	
	ContactInformationManagementModule = CommonUse.CommonModule("ContactInformationManagement");
	
	ContactInformationManagementModule.RefreshContactInformationKind(
	    Catalogs["ContactInformationKinds"].UserEmail,
	    Enums["ContactInformationTypes"].EmailAddress,
	    NStr("en='User email address'"), True, False, False, 1, True);
	
	ContactInformationManagementModule.RefreshContactInformationKind(
	    Catalogs["ContactInformationKinds"].UserPhone,
	    Enums["ContactInformationTypes"].Phone,
	    NStr("en='User contact phone number'"), True, False, False, 2, True);

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Handlers of other subsystem conditional calls.

// Overrides comment text during the authorization of the infobase user
// that is created in Designer and has administrative rights.
// The procedure is called from Users.AuthenticateCurrentUser().
// The comment is written to the event log.
// 
// Parameters:
//  Comment  - String - initial value is specified.
//
Procedure AfterWriteAdministratorOnAuthorization(Comment) Export
	
	If CommonUse.SubsystemExists("StandardSubsystems.AccessManagement") Then
		AccessManagementInternalModule = CommonUse.CommonModule("AccessManagementInternal");
		AccessManagementInternalModule.AfterWriteAdministratorOnAuthorization(Comment);
	EndIf;
	
EndProcedure
 

// Overrides the action that is performed during the authorization of local infobase administrator
// or data area administrator.
//
Procedure OnAuthorizeAdministratorOnStart(IRegUserInfo) Export
	
	If CommonUse.SubsystemExists("StandardSubsystems.AccessManagement") Then
		AccessManagementInternalModule = CommonUse.CommonModule("AccessManagementInternal");
		AccessManagementInternalModule.OnAuthorizeAdministratorOnStart(IRegUserInfo);
	EndIf;
	
EndProcedure
 

// Generates a request for changing SaaS user email address.
//
// Parameters:
//  NewEmail            - String - new email address of the user.
//  User                - CatalogRef.Users - user whose email address is changed.                                                            
//  ServiceUserPassword - String - user password for Service Manager.
//
Procedure OnCreateRequestToChangeEmail(Val NewEmail, Val User, Val ServiceUserPassword) Export
	
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.UsersSaaS") Then
		UsersInternalSaaSModule = CommonUse.CommonModule("UsersInternalSaaS");
		UsersInternalSaaSModule.CreateRequestToChangeEmail(NewEmail, User, ServiceUserPassword);
	EndIf;
	
EndProcedure
 

// Returns the actions with the specified SaaS user available to the current user.
//
//Parameters:
//  User - CatalogRef.Users - user for retrieving available actions. 
//                            If this parameter is not specified, available actions
//                            for the current user are retrieved.
//  ServiceUserPassword - String - SaaS password of the current user.  
//  
Procedure OnReceiveActionsWithSaaSUser(AvailableAction, Val User = Undefined) Export
	
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.UsersSaaS") Then
		UsersInternalSaaSModule = CommonUse.CommonModule("UsersInternalSaaS");
		AvailableAction = UsersInternalSaaSModule.GetActionsWithSaaSUser(User);
	EndIf;
	
EndProcedure
 

// Handlers of writing users and user groups.

// Redefines the actions that are required after completing the update of 
// relations in UserGroupContents register.
//
// Parameters:
//  ItemsToChange  - Array of values of the following types:
//                       - CatalogRef.Users.
//                       - CatalogRef.ExternalUsers.
//                       Users that are included in group content update.
//
//  ModifiedGroups – Array of values of the following types:
//                       - CatalogRef.UserGroups.
//                       - CatalogRef.ExternalUserGroups.
//                       Groups whose content is changed.
//
Procedure AfterUpdateUserGroupContentsOverridable(ItemsToChange, ModifiedGroups) Export
	
	If CommonUse.SubsystemExists("StandardSubsystems.AccessManagement") Then
		AccessManagementInternalModule = CommonUse.CommonModule("AccessManagementInternal");
		AccessManagementInternalModule.AfterUserGroupContentUpdate(ItemsToChange, ModifiedGroups);
		
		AccessManagementModule = CommonUse.CommonModule("AccessManagement");
		AccessManagementModule.UpdateUserRoles(ItemsToChange);
	EndIf;
	
EndProcedure
 

// Redefines the actions that are required after changing an external user authorization object.
// 
// Parameters:
//  ExternalUser           - CatalogRef.ExternalUsers.
//  OldAuthorizationObject - NULL - when adding an external user.
//                           For example, CatalogRef.Individuals.
//  NewAuthorizationObject - For example, CatalogRef.Individuals.
//
Procedure AfterChangeExternalUserAuthorizationObject(ExternalUser,
                                                      OldAuthorizationObject = Undefined,
                                                      NewAuthorizationObject) Export
	
	If CommonUse.SubsystemExists("StandardSubsystems.AccessManagement") Then
		AccessManagementInternalModule = CommonUse.CommonModule("AccessManagementInternal");
		AccessManagementInternalModule.AfterChangeExternalUserAuthorizationObject(
			ExternalUser, OldAuthorizationObject, NewAuthorizationObject);
	EndIf;
	
EndProcedure
 

// Redefines the actions that are required after adding or modifying a user,
// user group, external user, or external user group.
//
// Parameters:
//  Ref   - CatalogRef.Users.
//        - CatalogRef.UserGroups.
//        - CatalogRef.ExternalUsers.
//        - CatalogRef.ExternalUserGroups.
//  IsNew - Boolean - if True, the object is added, otherwise it is changed.
//
Procedure AfterAddUserOrGroupChange(Ref, IsNew) Export
	
	If CommonUse.SubsystemExists("StandardSubsystems.AccessManagement") Then
		AccessManagementInternalModule = CommonUse.CommonModule("AccessManagementInternal");
		AccessManagementInternalModule.AfterAddUserOrGroupChange(Ref, IsNew);
	EndIf;
	
EndProcedure
 

// Redefines the actions that are required after assigning an infobase user
// to a user or external user (when filling the InfobaseUserID attribute).
// 
// For example, these actions can include the update of roles.
// 
// Parameters:
//  Ref - CatalogRef.Users.
//      - CatalogRef.ExternalUsers.
//
Procedure AfterSetInfobaseUser(Ref, ServiceUserPassword) Export
	
	If CommonUse.SubsystemExists("StandardSubsystems.AccessManagement") Then
		AccessManagementModule = CommonUse.CommonModule("AccessManagement");
		AccessManagementModule.UpdateUserRoles(Ref, ServiceUserPassword);
	EndIf;
	
EndProcedure
 

// This procedure is used for SaaS mode support.

// Returns a flag that shows whether user modification is available.
//
// Returns:
// Boolean - True if user modification is available, False otherwise.
//
Procedure OnDefineCanChangeUsers(CanChangeUsers) Export
	
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.UsersSaaS") Then
		UsersInternalSaaSModule = CommonUse.CommonModule("UsersInternalSaaS");
		CanChangeUsers = UsersInternalSaaSModule.CanChangeUsers();
	Else
		CanChangeUsers = True;
	EndIf;
	
EndProcedure
 

// User settings of report options.

// Gets the specified report options and their presentations.
//
// Parameters:
//  ReportMetadata       - Metadata object - report for retrieving options.
//  InfobaseUser         - String - infobase user name.
//  ReportOptionsDetails - ValueTable - table for storing report option data:
//                           ObjectKey          - String - report key in "Report.ReportName" format.
//                           VariantKey          - String - report option key.
//                           Presentation       - String - report option presentation.
//                           StandardProcessing - Boolean - if True, the report option is stored in the standard storage.
//  StandardProcessing   - Boolean - if True, the report option is stored in the standard storage.
//
Procedure OnReceiveUserReportOptions(ReportMetadata, InfobaseUser, ReportOptionsDetails, StandardProcessing) Export
	
	If CommonUse.SubsystemExists("StandardSubsystems.ReportOptions") Then
		ReportOptionsModule = CommonUse.CommonModule("ReportOptions");
		ReportOptionsModule.UserReportOptions(ReportMetadata, InfobaseUser,
			ReportOptionsDetails, StandardProcessing);
	EndIf;
	
EndProcedure
 

// Deletes the specified report option from the report option storage.
//
// Parameters:
//  ReportOptionsDetails - ValueTable - table that contains report option data.
//                           ObjectKey          - String - report key in "Report.ReportName" format.
//                           VariantKey          - String - report option key.
//                           Presentation       - String - report option presentation.
//                           StandardProcessing - Boolean - if True, the report option is stored in the standard storage.
//  InfobaseUser         - String – name of the infobase user whose report option is cleared.
//  StandardProcessing   - Boolean - if True, the report option is stored in the standard storage.
//
Procedure OnDeleteUserReportOptions(ReportOptionDetails, InfobaseUser, StandardProcessing) Export
	
	If CommonUse.SubsystemExists("StandardSubsystems.ReportOptions") Then
		ReportOptionsModule = CommonUse.CommonModule("ReportOptions");
		ReportOptionsModule.DeleteUserReportOption(ReportOptionDetails,
			InfobaseUser, StandardProcessing);
	EndIf;
	
EndProcedure
 

// Other user settings.

// Extends the list of settings on the "Other" tab of AppUserSettings data processor 
// for the user passed to the procedure.
//
// Parameters:
//  UserInfo - Structure - string presentation and reference presentation of the user.
//               UserRef          - CatalogRef.Users - user.
//               InfobaseUserName - String - infobase user. 
//  Settings - Structure - other user settings.
//               Key   - String - string ID of a settings item that is used for copying and clearing the settings item.                           
//               Value - Structure - settings data.
//                         SettingsItemName     - String - name to be displayed 
//                                                        in the settings tree.
//                         SettingsItemPicture - Picture - picture to be displayed 
//                                                         in the settings tree.
//                         SettingsList        - ValueList - list of retrieved settings.
//
Procedure OnGetOtherSettings(UserInfo, OtherSettings) Export
	
	// Adding additional report and data processor settings
	If CommonUse.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
		Settings = Undefined;
		AdditionalReportsAndDataProcessorsModule = CommonUse.CommonModule("AdditionalReportsAndDataProcessors");
		AdditionalReportsAndDataProcessorsModule.GetAdditionalReportAndDataProcessorSettings(UserInfo.UserRef, Settings);
		
		If Settings <> Undefined Then
			OtherSettings.Insert("QuickAccessSettingsItem", Settings);
		EndIf;
	EndIf;
	
	UsersOverridable.OnGetOtherSettings(UserInfo, OtherSettings);
	
EndProcedure

// Saves settings of the specified user.
//
// Parameters:
//  Settings - ValueList - value list of settings to be saved. 
//  UserInfo - Structure - string presentation and reference presentation of the user.
//               UserRef          - CatalogRef.Users - target user for copying the settings.
//               InfobaseUserName - String - target infobase user 
//                                           for copying the settings.
//
Procedure OnSaveOtherSetings(UserInfo, Settings) Export
	
	If Settings.SettingID = "QuickAccessSettingsItem" Then
		If CommonUse.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
			AdditionalReportsAndDataProcessorsModule = CommonUse.CommonModule("AdditionalReportsAndDataProcessors");
			AdditionalReportsAndDataProcessorsModule.AddCommandsToQuickAccessList(Settings.SettingValue, UserInfo.UserRef);
		EndIf;
	EndIf;
	
	UsersOverridable.OnSaveOtherSetings(UserInfo, Settings);
	
EndProcedure
 

// Clears settings of the specified user.
//
// Parameters:
//  Settings - ValueList - value list of setting to be cleared.
//  UserInfo - Structure - string presentation and reference presentation of the user.
//               UserRef          - CatalogRef.Users - user whose settings are cleared.
//               InfobaseUserName - String - infobase user
//                                           whose settings are cleared.
//
Procedure OnDeleteOtherSettings(UserInfo, Settings) Export
	
	If Settings.SettingID = "QuickAccessSettingsItem" Then
		If CommonUse.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
			AdditionalReportsAndDataProcessorsModule = CommonUse.CommonModule("AdditionalReportsAndDataProcessors");
			AdditionalReportsAndDataProcessorsModule.DeleteCommandsFromQuickAccessList(Settings.SettingValue, UserInfo.UserRef);
		EndIf;
	EndIf;
	
	UsersOverridable.OnDeleteOtherSettings(UserInfo, Settings);
	
EndProcedure
 

////////////////////////////////////////////////////////////////////////////////
// AUXILIARY PROCEDURES AND FUNCTIONS

Function UserNotFoundInCatalogMessageText(UserName)
	
	If ExternalUsers.UseExternalUsers() Then
		ErrorMessageText = NStr("en = 'Authorization failed. The application is stopped.
		                              |
		                              |User %1 is not found 
		                              |in Users and ExternalUsers catalogs.
		                              |
		                              |Contact the application administrator.'");
	Else
		ErrorMessageText = NStr("en = 'Authorization failed. The application is stopped.
		                              |
		                              |User %1 is not found in the Users catalog.
		                              |
		                              |Contact the application administrator.'");
	EndIf;
	
	ErrorMessageText = StringFunctionsClientServer.SubstituteParametersInString(ErrorMessageText, UserName);
	
	Return ErrorMessageText;
	
EndFunction

Function UserRefByFullDescription(FullName)
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Users.Ref AS Ref,
	|	Users.InfobaseUserID
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.Description = &FullName";
	
	Query.SetParameter("FullName", FullName);
	
	Result = Undefined;
	
	BeginTransaction();
	Try
		QueryResult = Query.Execute();
		If Not QueryResult.IsEmpty() Then
			
			Selection = QueryResult.Select();
			Selection.Next();
			
			If Not Users.InfobaseUserIsOccupied(Selection.InfobaseUserID) Then
				Result = Selection.Ref;
			EndIf;
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return Undefined;
	
EndFunction
 

// The function is used in the following procedures: UpdateUserGroupContents and 
// UpdateExternalUserGroupContent.
//
// Parameters:
//  Table - full metadata object name.
//
// Returns:
//  ValueTable - Ref, Parent.
//
Function ReferencesInParentHierarchy(Table)
	
	// Preparing parent group content
	Query = New Query(
	"SELECT
	|	ParentsReferences.Ref AS Ref,
	|	ParentsReferences.Parent AS Parent
	|FROM
	|	" + Table + " AS ParentsReferences");
	ParentsReferences = Query.Execute().Unload();
	ParentsReferences.Indexes.Add("Parent");
	ReferencesInParentHierarchy = ParentsReferences.Copy(New Array);
	
	For Each ReferenceDetails In ParentsReferences Do
		NewRow = ReferencesInParentHierarchy.Add();
		NewRow.Parent = ReferenceDetails.Ref;
		NewRow.Ref    = ReferenceDetails.Ref;
		
		FillReferenceInParentHierarchy(ReferenceDetails.Ref, ReferenceDetails.Ref, ParentsReferences, ReferencesInParentHierarchy);
	EndDo;
	
	Return ReferencesInParentHierarchy;
	
EndFunction
 

Procedure FillReferenceInParentHierarchy(Val Parent, Val CurrentParent, Val ParentsReferences, Val ReferencesInParentHierarchy)
	
	ParentReferences = ParentsReferences.FindRows(New Structure("Parent", CurrentParent));
	
	For Each ReferenceDetails In ParentReferences Do
		NewRow = ReferencesInParentHierarchy.Add();
		NewRow.Parent = Parent;
		NewRow.Ref    = ReferenceDetails.Ref;
		
		FillReferenceInParentHierarchy(Parent, ReferenceDetails.Ref, ParentsReferences, ReferencesInParentHierarchy);
	EndDo;
	
EndProcedure
 

// The function is used in the following procedures: UpdateUserGroupContents and
// UpdateExternalUserGroupContent.
//
Procedure UpdateAllUsersGroupContent(User,
                                     UpdateExternalUserGroup = False,
                                     ItemsToChange = Undefined,
                                     ModifiedGroups   = Undefined)
	
	If UpdateExternalUserGroup Then
		AllUsersGroup = Catalogs.ExternalUserGroups.AllExternalUsers;
	Else
		AllUsersGroup = Catalogs.UserGroups.AllUsers;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("AllUsersGroup", AllUsersGroup);
	
	Query.Text =
	"SELECT
	|	Users.Ref AS Ref,
	|	CASE
	|		WHEN Users.DeletionMark
	|			THEN FALSE
	|		WHEN Users.NotValid
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS Used
	|INTO Users
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	&UserFilter
	|
	|INDEX BY
	|	Users.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&AllUsersGroup AS UserGroup,
	|	Users.Ref AS User,
	|	Users.Used
	|FROM
	|	Users AS Users
	|		LEFT JOIN InformationRegister.UserGroupContents AS UserGroupContents
	|		ON (UserGroupContents.UserGroup = &AllUsersGroup)
	|			AND (UserGroupContents.User = Users.Ref)
	|			AND (UserGroupContents.Used = Users.Used)
	|WHERE
	|	UserGroupContents.User IS NULL 
	|
	|UNION ALL
	|
	|SELECT
	|	Users.Ref,
	|	Users.Ref,
	|	Users.Used
	|FROM
	|	Users AS Users
	|		LEFT JOIN InformationRegister.UserGroupContents AS UserGroupContents
	|		ON (UserGroupContents.UserGroup = Users.Ref)
	|			AND (UserGroupContents.User = Users.Ref)
	|			AND (UserGroupContents.Used = Users.Used)
	|WHERE
	|	UserGroupContents.User IS NULL ";
	
	If UpdateExternalUserGroup Then
		Query.Text = StrReplace(Query.Text, "Catalog.Users", "Catalog.ExternalUsers");
	EndIf;
	
	If User = Undefined Then
		Query.Text = StrReplace(Query.Text, "&UserFilter", "TRUE");
	Else
		Query.SetParameter("User", User);
		Query.Text = StrReplace(
		  Query.Text, "&UserFilter", "Users.Ref In (&User)");
	EndIf;
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		RecordSet = InformationRegisters.UserGroupContents.CreateRecordSet();
		Write = RecordSet.Add();
		Selection = QueryResult.Select();
		
		While Selection.Next() Do
			RecordSet.Filter.UserGroup.Set(Selection.UserGroup);
			RecordSet.Filter.User.Set(Selection.User);
			FillPropertyValues(Write, Selection);
			RecordSet.Write(); // Adding missing records about relations
			
			If ItemsToChange <> Undefined Then
				ItemsToChange.Insert(Selection.User);
			EndIf;
		EndDo;
		
		If ModifiedGroups <> Undefined Then
			ModifiedGroups.Insert(AllUsersGroup);
		EndIf;
	EndIf;
	
EndProcedure
 

// The procedure is used in the UpdateExternalUserGroupContent procedure.
Procedure UpdateGroupContentByAuthorizationObjectType(ExternalUserGroup = Undefined,
                                                      ExternalUser,
                                                      ItemsToChange = Undefined,
                                                      ModifiedGroups   = Undefined)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ExternalUserGroups.Ref AS UserGroup,
	|	ExternalUsers.Ref AS User,
	|	CASE
	|		WHEN ExternalUserGroups.DeletionMark
	|			THEN FALSE
	|		WHEN ExternalUsers.DeletionMark
	|			THEN FALSE
	|		WHEN ExternalUsers.NotValid
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS Used
	|INTO NewContent
	|FROM
	|	Catalog.ExternalUsers AS ExternalUsers
	|		INNER JOIN Catalog.ExternalUserGroups AS ExternalUserGroups
	|		ON (ExternalUserGroups.AllAuthorizationObjects = TRUE)
	|			AND (&FilterExternalUserGroups1)
	|			AND (VALUETYPE(ExternalUsers.AuthorizationObject) = VALUETYPE(ExternalUserGroups.AuthorizationObjectType))
	|			AND (&ExternalUserFilter1)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UserGroupContents.UserGroup,
	|	UserGroupContents.User
	|FROM
	|	InformationRegister.UserGroupContents AS UserGroupContents
	|		LEFT JOIN NewContent AS NewContent
	|		ON UserGroupContents.UserGroup = NewContent.UserGroup
	|			AND UserGroupContents.User = NewContent.User
	|WHERE
	|	VALUETYPE(UserGroupContents.UserGroup) = TYPE(Catalog.ExternalUserGroups)
	|	AND CAST(UserGroupContents.UserGroup AS Catalog.ExternalUserGroups).AllAuthorizationObjects = TRUE
	|	AND &FilterExternalUserGroups2
	|	AND &ExternalUserFilter2
	|	AND NewContent.User IS NULL 
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NewContent.UserGroup,
	|	NewContent.User,
	|	NewContent.Used
	|FROM
	|	NewContent AS NewContent
	|		LEFT JOIN InformationRegister.UserGroupContents AS UserGroupContents
	|		ON (UserGroupContents.UserGroup = NewContent.UserGroup)
	|			AND (UserGroupContents.User = NewContent.User)
	|			AND (UserGroupContents.Used = NewContent.Used)
	|WHERE
	|	UserGroupContents.User IS NULL ";
	
	If ExternalUserGroup = Undefined Then
		Query.Text = StrReplace(Query.Text, "&FilterExternalUserGroups1", "TRUE");
		Query.Text = StrReplace(Query.Text, "&FilterExternalUserGroups2", "TRUE");
	Else
		Query.SetParameter("ExternalUserGroup", ExternalUserGroup);
		Query.Text = StrReplace(
			Query.Text,
			"&FilterExternalUserGroups1",
			"ExternalUserGroups.Ref IN (&ExternalUserGroup)");
		Query.Text = StrReplace(
			Query.Text,
			"&FilterExternalUserGroups2",
			"UserGroupContents.UserGroup IN (&ExternalUserGroup)");
	EndIf;
	
	If ExternalUser = Undefined Then
		Query.Text = StrReplace(Query.Text, "&ExternalUserFilter1", "TRUE");
		Query.Text = StrReplace(Query.Text, "&ExternalUserFilter2", "TRUE");
	Else
		Query.SetParameter("ExternalUser", ExternalUser);
		Query.Text = StrReplace(
			Query.Text,
			"&ExternalUserFilter1",
			"ExternalUsers.Ref In (&ExternalUser)");
		Query.Text = StrReplace(
			Query.Text,
			"&ExternalUserFilter2",
			"UserGroupContents.User IN (&ExternalUser)");
	EndIf;
	
	QueryResults = Query.ExecuteBatch();
	
	If Not QueryResults[1].IsEmpty() Then
		RecordSet = InformationRegisters.UserGroupContents.CreateRecordSet();
		Selection = QueryResults[1].Select();
		
		While Selection.Next() Do
			RecordSet.Filter.UserGroup.Set(Selection.UserGroup);
			RecordSet.Filter.User.Set(Selection.User);
			RecordSet.Write(); // Deleting unnecessary records about relations
			
			If ItemsToChange <> Undefined Then
				ItemsToChange.Insert(Selection.User);
			EndIf;
			
			If ModifiedGroups <> Undefined
			   And TypeOf(Selection.UserGroup)
			     = Type("CatalogRef.ExternalUserGroups") Then
				
				ModifiedGroups.Insert(Selection.UserGroup);
			EndIf;
		EndDo;
	EndIf;
	
	If Not QueryResults[2].IsEmpty() Then
		RecordSet = InformationRegisters.UserGroupContents.CreateRecordSet();
		Write = RecordSet.Add();
		Selection = QueryResults[2].Select();
		
		While Selection.Next() Do
			RecordSet.Filter.UserGroup.Set(Selection.UserGroup);
			RecordSet.Filter.User.Set(Selection.User);
			FillPropertyValues(Write, Selection);
			RecordSet.Write(); // Adding missing records about relations
			
			If ItemsToChange <> Undefined Then
				ItemsToChange.Insert(Selection.User);
			EndIf;
			
			If ModifiedGroups <> Undefined
			   And TypeOf(Selection.UserGroup)
			     = Type("CatalogRef.ExternalUserGroups") Then
				
				ModifiedGroups.Insert(Selection.UserGroup);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

// The procedure is used in the following procedures: UpdateUserGroupContents and
// UpdateExternalUserGroupContent.
//
Procedure UpdateHierarchicalUserGroupContents(UserGroup,
                                             User,
                                             ItemsToChange = Undefined,
                                             ModifiedGroups   = Undefined)
	
	UpdateExternalUserGroups =
		TypeOf(UserGroup) <> Type("CatalogRef.UserGroups");
	
	// Preparing user groups in parent hierarchy.
	Query = New Query;
	Query.Text =
	"SELECT
	|	ReferencesInParentHierarchy.Parent,
	|	ReferencesInParentHierarchy.Ref
	|INTO ReferencesInParentHierarchy
	|FROM
	|	&ReferencesInParentHierarchy AS ReferencesInParentHierarchy";
	
	Query.SetParameter("ReferencesInParentHierarchy", ReferencesInParentHierarchy(
		?(UpdateExternalUserGroups,
		  "Catalog.ExternalUserGroups",
		  "Catalog.UserGroups") ));
	
	Query.TempTablesManager = New TempTablesManager;
	Query.Execute();
	
	// Preparing a query for the loop
	Query.Text =
	"SELECT
	|	UserGroupContents.User,
	|	UserGroupContents.Used
	|INTO UserGroupContents
	|FROM
	|	InformationRegister.UserGroupContents AS UserGroupContents
	|WHERE
	|	&UserFilterInRegister
	|	AND UserGroupContents.UserGroup = &UserGroup
	|
	|INDEX BY
	|	UserGroupContents.User,
	|	UserGroupContents.Used
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	UserGroupContent.User AS User,
	|	CASE
	|		WHEN UserGroupContent.Ref.DeletionMark
	|			THEN FALSE
	|		WHEN UserGroupContent.User.DeletionMark
	|			THEN FALSE
	|		WHEN UserGroupContent.User.NotValid
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS Used
	|INTO UserGroupNewContents
	|FROM
	|	Catalog.UserGroups.Content AS UserGroupContent
	|		INNER JOIN ReferencesInParentHierarchy AS ReferencesInParentHierarchy
	|		ON (ReferencesInParentHierarchy.Ref = UserGroupContent.Ref)
	|			AND (ReferencesInParentHierarchy.Parent = &UserGroup)
	|			AND (&FilterUserInCatalog)
	|
	|INDEX BY
	|	User,
	|	Used
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	UserGroupContents.User
	|FROM
	|	UserGroupContents AS UserGroupContents
	|		LEFT JOIN UserGroupNewContents AS UserGroupNewContents
	|		ON UserGroupContents.User = UserGroupNewContents.User
	|WHERE
	|	UserGroupNewContents.User IS NULL 
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	&UserGroup AS UserGroup,
	|	UserGroupNewContents.User,
	|	UserGroupNewContents.Used
	|FROM
	|	UserGroupNewContents AS UserGroupNewContents
	|		LEFT JOIN UserGroupContents AS UserGroupContents
	|		ON (UserGroupContents.User = UserGroupNewContents.User)
	|			AND (UserGroupContents.Used = UserGroupNewContents.Used)
	|WHERE
	|	UserGroupContents.User IS NULL 
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UserGroups.Parent AS Parent
	|FROM
	|	Catalog.UserGroups AS UserGroups
	|WHERE
	|	UserGroups.Ref = &UserGroup
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP UserGroupContents
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP UserGroupNewContents";
	
	If User = Undefined Then
		UserFilterInRegister = "TRUE";
		FilterUserInCatalog  = "TRUE";
	Else
		Query.SetParameter("User", User);
		UserFilterInRegister = "UserGroupContents.User (&User)";
		FilterUserInCatalog  = "UserGroupContent.User IN (&User)";
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&UserFilterInRegister", UserFilterInRegister);
	Query.Text = StrReplace(Query.Text, "&FilterUserInCatalog", FilterUserInCatalog);
	
	If UpdateExternalUserGroups Then
		
		Query.Text = StrReplace(
			Query.Text,
			"Catalog.UserGroups",
			"Catalog.ExternalUserGroups");
		
		Query.Text = StrReplace(
			Query.Text,
			"UserGroupContent.User",
			"UserGroupContent.ExternalUser");
	EndIf;
	
	// Actions for current user group and parent groups
	While ValueIsFilled(UserGroup) Do
		
		Query.SetParameter("UserGroup", UserGroup);
		
		QueryResults = Query.ExecuteBatch();
		
		If Not QueryResults[2].IsEmpty() Then
			RecordSet = InformationRegisters.UserGroupContents.CreateRecordSet();
			Selection = QueryResults[2].Select();
			
			While Selection.Next() Do
				RecordSet.Filter.User.Set(Selection.User);
				RecordSet.Filter.UserGroup.Set(UserGroup);
				RecordSet.Write(); // Deleting unnecessary records about relations
				
				If ItemsToChange <> Undefined Then
					ItemsToChange.Insert(Selection.User);
				EndIf;
				
				If ModifiedGroups <> Undefined Then
					ModifiedGroups.Insert(UserGroup);
				EndIf;
			EndDo;
		EndIf;
		
		If Not QueryResults[3].IsEmpty() Then
			RecordSet = InformationRegisters.UserGroupContents.CreateRecordSet();
			Write = RecordSet.Add();
			Selection = QueryResults[3].Select();
			
			While Selection.Next() Do
				RecordSet.Filter.User.Set(Selection.User);
				RecordSet.Filter.UserGroup.Set(Selection.UserGroup);
				FillPropertyValues(Write, Selection);
				RecordSet.Write(); // Adding missing records about relations
				
				If ItemsToChange <> Undefined Then
					ItemsToChange.Insert(Selection.User);
				EndIf;
				
				If ModifiedGroups <> Undefined Then
					ModifiedGroups.Insert(Selection.UserGroup);
				EndIf;
			EndDo;
		EndIf;
		
		If Not QueryResults[4].IsEmpty() Then
			Selection = QueryResults[4].Select();
			Selection.Next();
			UserGroup = Selection.Parent;
		Else
			UserGroup = Undefined;
		EndIf;
	EndDo;
	
EndProcedure

// Checks the rights of the specified infobase user.
//
// Parameters:
//  InfobaseUser - InfobaseUser.
//  CheckMode    - String - OnWrite or OnStart.
//
Procedure CheckUserRights(InfobaseUser, CheckMode)
	
	DataSeparationEnabled = CommonUseCached.DataSeparationEnabled();
	If DataSeparationEnabled And InfobaseUser.DataSeparation.Count() = 0 Then
		Return; // Unseparated users should not be checked in SaaS
	EndIf;
	
	If Not DataSeparationEnabled And CheckMode = "OnStart" Then
		Return; // Checking rights in local mode is not required
	EndIf;
	
	UserTypes = ?(DataSeparationEnabled,
		Enums.UserTypes.DataAreaUser,
		Enums.UserTypes.LocalApplicationUser);
		
	InaccessibleRoles = InaccessibleRolesByUserType(UserTypes);
	If InaccessibleRoles.Count() = 0 Then
		Return;
	EndIf;
	
	RolesToCheck = New ValueTable;
	RolesToCheck.Columns.Add("Role", New TypeDescription("MetadataObject"));
	RolesToCheck.Columns.Add("IsRoleToDelete", New TypeDescription("Boolean"));
	For Each Role In InfobaseUser.Roles Do
		RolesToCheck.Add().Role = Role;
	EndDo;
	RolesToCheck.Indexes.Add("Role");
	
	If CheckMode = "OnWrite" And Not DataSeparationEnabled Then
		FormerInfobaseUser = InfobaseUsers.FindByUUID(
			InfobaseUser.UUID);
		
		If FormerInfobaseUser <> Undefined Then
			For Each Role In FormerInfobaseUser.Roles Do
				String = RolesToCheck.Find(Role, "Role");
				If String <> Undefined Then
					RolesToCheck.Delete(String);
				ElsIf DataSeparationEnabled Then
					NewRow = RolesToCheck.Add();
					NewRow.Role = Role;
					NewRow.IsRoleToDelete = True;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	FoundInaccessibleRoles = New ValueTable;
	FoundInaccessibleRoles.Columns.Add("Role", New TypeDescription("MetadataObject"));
	FoundInaccessibleRoles.Columns.Add("IsRoleToDelete", New TypeDescription("Boolean"));
	
	For Each RoleDetails In RolesToCheck Do
		Role = RoleDetails.Role;
		RoleName = Role.Name;
		
		InaccessibleRoleProperties = InaccessibleRoles.Get(RoleName);
		If InaccessibleRoleProperties = Undefined Then
			Continue;
		EndIf;
		FillPropertyValues(FoundInaccessibleRoles.Add(), RoleDetails);
		
		If InaccessibleRoleProperties.Property("ChangeableSharedData") Then
			Write = New XMLWriter;
			Write.SetString();
			XDTOSerializer.WriteXML(Write, InaccessibleRoleProperties.ChangeableSharedData);
			TableString = Write.Close();
			
			If RoleDetails.IsRoleToDelete Then
				MessageText = StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en = 'Attempting to change role content
					           |for user: %1 
					           |role: %2 
					           |that grants the right to change common data: %3.'"),
					InfobaseUser.FullName,
					Role.Presentation(),
					TableString);
			Else
				MessageText = StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en = 'Attempting to assign an invalid role
					           |to user: %1 
					           |role: %2
					           |that grants the right to change common data: %3.'"),
					InfobaseUser.FullName,
					Role.Presentation(),
					TableString);
			EndIf;
			
			EventName = NStr("en = 'Users.Error setting roles for the infobase user'",
			     CommonUseClientServer.DefaultLanguageCode());
			WriteLogEvent(EventName, EventLogLevel.Error,, InfobaseUser, MessageText);
		EndIf;
		
		If InaccessibleRoleProperties.Property("Rights") Then
			
			EventName = NStr("en = 'Users.Error setting roles for the infobase user'",
			     CommonUseClientServer.DefaultLanguageCode());
			
			For Each Right In InaccessibleRoleProperties.Rights Do
				
				If RoleDetails.IsRoleToDelete Then
					MessageText = StringFunctionsClientServer.SubstituteParametersInString(
						NStr("en = 'Attempting to change role content for user: %1
						           |with role: %2 
						           |that grants the right: %3.'"),
						String(InfobaseUser),
						Role.Presentation(),
						Right);
				Else
					MessageText = StringFunctionsClientServer.SubstituteParametersInString(
						NStr("en = 'Attempting to assign an invalid role to user: %1
						           |role: %2
						           |that grants the right: %3.'"),
						String(InfobaseUser),
						Role.Presentation(),
						Right);
				EndIf;
				WriteLogEvent(EventName, EventLogLevel.Error,, InfobaseUser, MessageText);
				
			EndDo;
		EndIf;
	EndDo;
	
	If FoundInaccessibleRoles.Count() = 0 Then
		Return;
	EndIf;
	
	Filter = New Structure("IsRoleToDelete", True);
	RolesToDelete = FoundInaccessibleRoles.FindRows(Filter);
	
	Filter = New Structure("IsRoleToDelete", False);
	RolesToAdd = FoundInaccessibleRoles.FindRows(Filter);
	
	If RolesToDelete.Count() = 1 Then
		DeletionMessageText = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Cannot remove unavailable role for user %1.'"),
			InfobaseUser.FullName);
	ElsIf RolesToDelete.Count() > 1 Then
		DeletionMessageText = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Cannot remove unavailable roles for user %1.'"),
			InfobaseUser.FullName);
	EndIf;
	
	If RolesToAdd.Count() = 1 Then
		AddingMessageText = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'The ""%2"" role cannot be added for user %1.'"),
			InfobaseUser.FullName,
			RolesToAdd[0].Role.Presentation());
		
	ElsIf RolesToAdd.Count() > 1 Then
		Roles = "";
		For Each RoleDetails In RolesToAdd Do
			Roles = Roles + "
			|" + RoleDetails.Role.Presentation();
		EndDo;
		AddingMessageText = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'The following roles cannot be added for user %1: %2.'"),
			InfobaseUser.FullName,
			Roles);
	EndIf;
	
	If ValueIsFilled(DeletionMessageText) Then
		MessageText = DeletionMessageText + Chars.LF + AddingMessageText;
	Else
		MessageText = AddingMessageText;
	EndIf;
	
	Raise MessageText;
	
EndProcedure

Function SettingsList(InfobaseUserName, SettingsManager)
	
	SettingsTable = New ValueTable;
	SettingsTable.Columns.Add("ObjectKey");
	SettingsTable.Columns.Add("SettingsKey");
	
	Filter = New Structure;
	Filter.Insert("User", InfobaseUserName);
	
	SettingsSelection = SettingsManager.Select(Filter);
	Ignore = False;
	While NextSettingsItem(SettingsSelection, Ignore) Do
		
		If Ignore Then
			Continue;
		EndIf;
		
		NewRow = SettingsTable.Add();
		NewRow.ObjectKey = SettingsSelection.ObjectKey;
		NewRow.SettingsKey = SettingsSelection.SettingsKey;
	EndDo;
	
	Return SettingsTable;
	
EndFunction

Function NextSettingsItem(SettingsSelection, Ignore) 
	
	Try 
		Ignore = False;
		Return SettingsSelection.Next();
	Except
		Ignore = True;
		Return True;
	EndTry;
	
EndFunction

Procedure CopySettings(SettingsManager, UserNameSource, UserNameTarget, Move)
	
	SettingsTable = SettingsList(UserNameSource, SettingsManager);
	
	For Each Settings In SettingsTable Do
		ObjectKey = Settings.ObjectKey;
		SettingsKey = Settings.SettingsKey;
		Value = SettingsManager.Load(ObjectKey, SettingsKey, , UserNameSource);
		SettingsDescription = SettingsManager.GetDescription(ObjectKey, SettingsKey, UserNameSource);
		SettingsManager.Save(ObjectKey, SettingsKey, Value,
			SettingsDescription, UserNameTarget);
		If Move Then
			SettingsManager.Delete(ObjectKey, SettingsKey, UserNameSource);
		EndIf;
	EndDo;
	
EndProcedure

Procedure CopyOtherUserSettings(UserNameSource, UserNameTarget)
	
	UserSourceRef = Users.FindByName(UserNameSource);
	TargetUserRef = Users.FindByName(UserNameTarget);
	UserSourceInfo = New Structure;
	UserSourceInfo.Insert("UserRef", UserSourceRef);
	UserSourceInfo.Insert("InfobaseUserName", UserNameSource);
	
	TargetUserInfo = New Structure;
	TargetUserInfo.Insert("UserRef", TargetUserRef);
	TargetUserInfo.Insert("InfobaseUserName", UserNameTarget);
	
	// Getting other settings
	OtherAppUserSettings = New Structure;
	OnGetOtherSettings(UserSourceInfo, OtherAppUserSettings);
	Keys = New ValueList;
	OtherSettingsArray = New Array;
	If OtherAppUserSettings.Count() <> 0 Then
		
		For Each OtherSetting In OtherAppUserSettings Do
			OtherSettingsStructure = New Structure;
			If OtherSetting.Key = "QuickAccessSettingsItem" Then
				SettingsList = OtherSetting.Value.SettingsList;
				For Each Item In SettingsList Do
					Keys.Add(Item.Object, Item.ID);
				EndDo;
				OtherSettingsStructure.Insert("SettingID",   "QuickAccessSettingsItem");
				OtherSettingsStructure.Insert("SettingValue", Keys);
			Else
				OtherSettingsStructure.Insert("SettingID",    OtherSetting.Key);
				OtherSettingsStructure.Insert("SettingValue", OtherSetting.Value.SettingsList);
			EndIf;
			OnSaveOtherSetings(TargetUserInfo, OtherSettingsStructure);
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure CopyInfobaseUserSettings(UserObject, ProcessingParameters)
	
	If Not ProcessingParameters.Property("CopyingValue")
	 Or Not ProcessingParameters.NewInfobaseUserExists Then
		
		Return;
	EndIf;
	
	NewInfobaseUserName = ProcessingParameters.NewInfobaseUserDescription.Name;
	
	InfobaseUserToCopyID = CommonUse.ObjectAttributeValue(
		ProcessingParameters.CopyingValue, "InfobaseUserID");
	
	If Not ValueIsFilled(InfobaseUserToCopyID) Then
		Return;
	EndIf;
	
	InfobaseUserToCopyDescription = Undefined;
	SetPrivilegedMode(True);
	If Not Users.ReadInfobaseUser(
	         InfobaseUserToCopyID,
	         InfobaseUserToCopyDescription) Then
		Return;
	EndIf;
	SetPrivilegedMode(False);
	
	NameOfInfobaseUserToCopy = InfobaseUserToCopyDescription.Name;
	
	// Copying settings
	CopyUserSettings(NameOfInfobaseUserToCopy, NewInfobaseUserName, False);
	
EndProcedure
 

////////////////////////////////////////////////////////////////////////////////
// Procedures used for data exchange.

// Overrides default behavior during data export.
// InfobaseUserID attribute is not moved.
//
Procedure OnSendData(DataItem, ItemSend, Subordinate)
	
	If ItemSend = DataItemSend.Delete
	 Or ItemSend = DataItemSend.Ignore Then
		
		// Standard processing cannot be overridden
		
	ElsIf TypeOf(DataItem) = Type("CatalogObject.Users")
	      Or TypeOf(DataItem) = Type("CatalogObject.ExternalUsers") Then
		
		DataItem.InfobaseUserID =
			New UUID("00000000-0000-0000-0000-000000000000");
		
		DataItem.Prepared = False;
		DataItem.InfobaseUserProperties = New ValueStorage(Undefined);
	EndIf;
	
EndProcedure
 
// Redefines standard behavior during data import.
// InfobaseUserID attribute is not moved because it always belongs 
// to a user of the current infobase or is not filled.
//
Procedure OnDataGet(DataItem, ItemReceive, SendBack, FromSubordinate)
	
	If ItemReceive = DataItemReceive.Ignore Then
		
		// Standard processing cannot be overridden
		
	ElsIf TypeOf(DataItem) = Type("ConstantValueManager.UseUserGroups")
	      Or TypeOf(DataItem) = Type("ConstantValueManager.UseExternalUsers")
	      Or TypeOf(DataItem) = Type("CatalogObject.Users")
	      Or TypeOf(DataItem) = Type("CatalogObject.UserGroups")
	      Or TypeOf(DataItem) = Type("CatalogObject.ExternalUsers")
	      Or TypeOf(DataItem) = Type("CatalogObject.ExternalUserGroups")
	      Or TypeOf(DataItem) = Type("InformationRegisterRecordSet.UserGroupContents") Then
		
		If FromSubordinate And CommonUseCached.DataSeparationEnabled() Then
			
			// Getting data from a standalone workstation is ignored.
			// Data is sent back to a standalone workstation to establish data mapping between the nodes.
			SendBack = True;
			ItemReceive = DataItemReceive.Ignore;
			
		ElsIf TypeOf(DataItem) = Type("CatalogObject.Users")
		      Or TypeOf(DataItem) = Type("CatalogObject.ExternalUsers") Then
			
			ListOfProperties =
			"InfobaseUserID,
			|Prepared,
			|InfobaseUserProperties";
			
			FillPropertyValues(DataItem, CommonUse.ObjectAttributeValues(
				DataItem.Ref, ListOfProperties));
			
		ElsIf TypeOf(DataItem) = Type("ObjectDeletion") Then
			
			If TypeOf(DataItem.Ref) = Type("CatalogRef.Users")
			 Or TypeOf(DataItem.Ref) = Type("CatalogRef.ExternalUsers") Then
				
				ObjectReceived = False;
				Try
					Object = DataItem.Ref.GetObject();
				Except
					ObjectReceived = True;
				EndTry;
				
				If ObjectReceived Then
					Object.CommonActionsBeforeDeleteInOrdinaryModeAndOnDataExchange();
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure
 

// Overrides behavior after receiving data in a distributed infobase.
//
Procedure DataAfterReceive(From, Cancel, FromSubordinate)
	
	UpdateExternalUserRoles();
	
EndProcedure
 

////////////////////////////////////////////////////////////////////////////////
// For procedure StartInfobaseUserProcessing.
//

Procedure RememberUserProperties(UserObject, ProcessingParameters)
	
	Fields =
	"Ref,
	|InfobaseUserID,
	|ServiceUserID,
	|InfobaseUserProperties,
	|Prepared,
	|DeletionMark,
	|NotValid";
	
	If TypeOf(UserObject) = Type("CatalogObject.Users") Then
		Fields = Fields + ", Internal";
	EndIf;
	
	OldUser = CommonUse.ObjectAttributeValues(UserObject.Ref, Fields);
	
	If TypeOf(UserObject) <> Type("CatalogObject.Users") Then
		OldUser.Insert("Internal", False);
	EndIf;
	
	If UserObject.IsNew() Or UserObject.Ref <> OldUser.Ref Then
		OldUser.InfobaseUserID =
			New UUID("00000000-0000-0000-0000-000000000000");
		OldUser.ServiceUserID =
			New UUID("00000000-0000-0000-0000-000000000000");
		OldUser.InfobaseUserProperties = New ValueStorage(Undefined);
		OldUser.Prepared               = False;
		OldUser.DeletionMark           = False;
		OldUser.NotValid               = False;
	EndIf;
	ProcessingParameters.Insert("OldUser", OldUser);
	
	// Properties of old infobase user (if it is available)
	SetPrivilegedMode(True);
	
	OldInfobaseUserDescription = Undefined;
	ProcessingParameters.Insert("OldInfobaseUserExists", Users.ReadInfobaseUser(
		OldUser.InfobaseUserID, OldInfobaseUserDescription));
	
	ProcessingParameters.Insert("OldInfobaseUserCurrent", False);
	
	If ProcessingParameters.OldInfobaseUserExists Then
		ProcessingParameters.Insert("OldInfobaseUserDescription", OldInfobaseUserDescription);
		
		If OldInfobaseUserDescription.UUID =
				InfobaseUsers.CurrentUser().UUID Then
		
			ProcessingParameters.Insert("OldInfobaseUserCurrent", True);
		EndIf;
	EndIf;
	SetPrivilegedMode(False);
	
	// Initial filling of auto attribute field values with old user values
	FillPropertyValues(ProcessingParameters.AutoAttributes, OldUser);
	
	// Initial filling of locked attribute fields with new user values
	FillPropertyValues(ProcessingParameters.AttributesToLock, UserObject);
	
EndProcedure

Procedure WriteInfobaseUserInternal(UserObject, ProcessingParameters)
	
	AdditionalProperties     = UserObject.AdditionalProperties;
	InfobaseUserDescription  = AdditionalProperties.InfobaseUserDescription;
	OldUser                  = ProcessingParameters.OldUser;
	AutoAttributes           = ProcessingParameters.AutoAttributes;
	
	If InfobaseUserDescription.Count() = 0 Then
		Return;
	EndIf;
	
	CreateNewInfobaseUser = False;
	
	If InfobaseUserDescription.Property("UUID")
	   And ValueIsFilled(InfobaseUserDescription.UUID)
	   And InfobaseUserDescription.UUID
	     <> ProcessingParameters.OldUser.InfobaseUserID Then
		
		InfobaseUserID = InfobaseUserDescription.UUID;
		
	ElsIf ValueIsFilled(OldUser.InfobaseUserID) Then
		InfobaseUserID = OldUser.InfobaseUserID;
		CreateNewInfobaseUser = Not ProcessingParameters.OldInfobaseUserExists;
	Else
		InfobaseUserID = Undefined;
		CreateNewInfobaseUser = True;
	EndIf;
	
	// Filling automatic properties for infobase user
	If InfobaseUserDescription.Property("FullName") Then
		InfobaseUserDescription.Insert("FullName", UserObject.Description);
	EndIf;
	
	StoredProperties = InfobaseUserStoredProperties(UserObject);
	If ProcessingParameters.OldInfobaseUserExists Then
		OldAuthentication = ProcessingParameters.OldInfobaseUserDescription;
		If Users.CanLogOnToApplication(OldAuthentication) Then
			StoredProperties.StandardAuthentication = OldAuthentication.StandardAuthentication;
			StoredProperties.OpenIDAuthentication   = OldAuthentication.OpenIDAuthentication;
			StoredProperties.OSAuthentication       = OldAuthentication.OSAuthentication;
			UserObject.InfobaseUserProperties       = New ValueStorage(StoredProperties);
			AutoAttributes.InfobaseUserProperties   = UserObject.InfobaseUserProperties;
		EndIf;
	Else
		OldAuthentication = New Structure;
		OldAuthentication.Insert("StandardAuthentication", False);
		OldAuthentication.Insert("OSAuthentication",       False);
		OldAuthentication.Insert("OpenIDAuthentication",   False);
		StoredProperties.StandardAuthentication = False;
		StoredProperties.OpenIDAuthentication   = False;
		StoredProperties.OSAuthentication       = False;
		UserObject.InfobaseUserProperties       = New ValueStorage(StoredProperties);
		AutoAttributes.InfobaseUserProperties   = UserObject.InfobaseUserProperties;
	EndIf;
	
	If InfobaseUserDescription.Property("StandardAuthentication") Then
		StoredProperties.StandardAuthentication = InfobaseUserDescription.StandardAuthentication;
		UserObject.InfobaseUserProperties       = New ValueStorage(StoredProperties);
		AutoAttributes.InfobaseUserProperties   = UserObject.InfobaseUserProperties;
	EndIf;
	
	If InfobaseUserDescription.Property("OSAuthentication") Then
		StoredProperties.OSAuthentication     = InfobaseUserDescription.OSAuthentication;
		UserObject.InfobaseUserProperties     = New ValueStorage(StoredProperties);
		AutoAttributes.InfobaseUserProperties = UserObject.InfobaseUserProperties;
	EndIf;
	
	If InfobaseUserDescription.Property("OpenIDAuthentication") Then
		StoredProperties.OpenIDAuthentication = InfobaseUserDescription.OpenIDAuthentication;
		UserObject.InfobaseUserProperties     = New ValueStorage(StoredProperties);
		AutoAttributes.InfobaseUserProperties = UserObject.InfobaseUserProperties;
	EndIf;
	
	SetStoredAuthentication = Undefined;
	If InfobaseUserDescription.Property("CanLogOnToApplication") Then
		SetStoredAuthentication = InfobaseUserDescription.CanLogOnToApplication = True;
	
	ElsIf InfobaseUserDescription.Property("StandardAuthentication")
	        And InfobaseUserDescription.StandardAuthentication = True
	      Or InfobaseUserDescription.Property("OSAuthentication")
	        And InfobaseUserDescription.OSAuthentication = True
	      Or InfobaseUserDescription.Property("OpenIDAuthentication")
	        And InfobaseUserDescription.OpenIDAuthentication = True Then
		
		SetStoredAuthentication = True;
	EndIf;
	
	If SetStoredAuthentication = Undefined Then
		NewAuthentication = OldAuthentication;
	Else
		If SetStoredAuthentication Then
			InfobaseUserDescription.Insert("StandardAuthentication", StoredProperties.StandardAuthentication);
			InfobaseUserDescription.Insert("OpenIDAuthentication",   StoredProperties.OpenIDAuthentication);
			InfobaseUserDescription.Insert("OSAuthentication",       StoredProperties.OSAuthentication);
		Else
			InfobaseUserDescription.Insert("StandardAuthentication", False);
			InfobaseUserDescription.Insert("OSAuthentication",          False);
			InfobaseUserDescription.Insert("OpenIDAuthentication",      False);
		EndIf;
		NewAuthentication = InfobaseUserDescription;
	EndIf;
	
	If StoredProperties.CanLogOnToApplication <> Users.CanLogOnToApplication(NewAuthentication) Then
		StoredProperties.CanLogOnToApplication = Users.CanLogOnToApplication(NewAuthentication);
		UserObject.InfobaseUserProperties      = New ValueStorage(StoredProperties);
		AutoAttributes.InfobaseUserProperties  = UserObject.InfobaseUserProperties;
	EndIf;
	
	// Checking if logon rights are modified
	If Not ProcessingParameters.AccessLevel.FullAccess
	   And (Users.CanLogOnToApplication(OldAuthentication)
	      <> Users.CanLogOnToApplication(NewAuthentication)
	      Or Users.CanLogOnToApplication(OldAuthentication)
	        And OldAuthentication.StandardAuthentication <> NewAuthentication.StandardAuthentication
	        And OldAuthentication.OSAuthentication       <> NewAuthentication.OSAuthentication
	        And OldAuthentication.OpenIDAuthentication   <> NewAuthentication.OpenIDAuthentication)
	   And Not (ProcessingParameters.AccessLevel.ListManagement
	         And Users.CanLogOnToApplication(NewAuthentication) = False) Then
		
		Raise ProcessingParameters.InsufficientRightsMessageText;
	EndIf;
	
	// Trying to write an infobase user
	ErrorDescription = "";
	InfobaseUser = Undefined;
	If Not Users.WriteInfobaseUser(
	         InfobaseUserID,
	         InfobaseUserDescription,
	         CreateNewInfobaseUser,
	         ErrorDescription,
	         InfobaseUser) Then
		
		Raise ErrorDescription;
	EndIf;
	
	If InfobaseUser.Roles.Contains(Metadata.Roles.FullAccess) Then
		ProcessingParameters.Insert("AdministratorWriting");
	EndIf;
	
	If CreateNewInfobaseUser Then
		InfobaseUserDescription.Insert("ActionResult", "InfobaseUserAdded");
		InfobaseUserID = InfobaseUserDescription.UUID;
		ProcessingParameters.Insert("InfobaseUserSetting");
		
		If ProcessingParameters.AccessLevel.ListManagement
		   And Not Users.CanLogOnToApplication(InfobaseUser) Then
			
			UserObject.Prepared = True;
			ProcessingParameters.AttributesToLock.Prepared = True;
		EndIf;
	Else
		InfobaseUserDescription.Insert("ActionResult", "InfobaseUserChanged");
		
		If Users.CanLogOnToApplication(InfobaseUser) Then
			UserObject.Prepared = False;
			ProcessingParameters.AttributesToLock.Prepared = False;
		EndIf;
	EndIf;
	
	UserObject.InfobaseUserID = InfobaseUserID;
	
	InfobaseUserDescription.Insert("UUID", InfobaseUserID);
	
EndProcedure

Function DeleteInfobaseUser(UserObject, ProcessingParameters)
	
	InfobaseUserDescription = UserObject.AdditionalProperties.InfobaseUserDescription;
	OldUser             = ProcessingParameters.OldUser;
	
	// Clearing infobase user ID
	UserObject.InfobaseUserID = Undefined;
	
	If ProcessingParameters.OldInfobaseUserExists Then
		
		SetPrivilegedMode(True);
		
		ErrorDescription = "";
		InfobaseUser = Undefined;
		If Users.DeleteInfobaseUser(
		         OldUser.InfobaseUserID,
		         ErrorDescription,
		         InfobaseUser) Then
			
			// Setting ID for the infobase user to be removed by the Delete operation
			InfobaseUserDescription.Insert("UUID",
				OldUser.InfobaseUserID);
			
			InfobaseUserDescription.Insert("ActionResult", "InfobaseUserDeleted");
		Else
			Raise ErrorDescription;
		EndIf;
		
	ElsIf ValueIsFilled(OldUser.InfobaseUserID) Then
		
		InfobaseUserDescription.Insert(
			"ActionResult", "MappingToNonExistentInfobaseUserCleared");
	Else
		InfobaseUserDescription.Insert(
			"ActionResult", "InfobaseUserDeletionNotRequired");
	EndIf;
	
EndFunction
 

////////////////////////////////////////////////////////////////////////////////
// For procedure EndInfobaseUserProcessing.
// 

Procedure CheckUserAttributeChanges(UserObject, ProcessingParameters)
	
	OldUser          = ProcessingParameters.OldUser;
	AutoAttributes   = ProcessingParameters.AutoAttributes;
	AttributesToLock = ProcessingParameters.AttributesToLock;
	
	If TypeOf(UserObject) = Type("CatalogObject.Users")
	   And AttributesToLock.Internal <> UserObject.Internal Then
		
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Error writing user %1.
			           |The Internal attribute cannot be changed in event subscriptions.'"),
			UserObject.Ref);
	EndIf;
	
	If AttributesToLock.Prepared <> UserObject.Prepared Then
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Error writing user %1.
			           |The Prepared attribute cannot be changed in event subscriptions.'"),
			UserObject.Ref);
	EndIf;
	
	If AutoAttributes.InfobaseUserID <> UserObject.InfobaseUserID Then
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Error writing user %1.
			           |The InfobaseUserID attribute cannot be changed.
			           |This attribute is updated automatically.'"),
			UserObject.Ref);
	EndIf;
	
	If Not CommonUse.IsEqualData(AutoAttributes.InfobaseUserProperties,
				UserObject.InfobaseUserProperties) Then
		
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Error writing user %1.
			           |The InfobaseUserProperties attribute cannot be changed.
			           |This attribute is updated automatically.'"),
			UserObject.Ref);
	EndIf;
	
	SetPrivilegedMode(True);
	
	If OldUser.DeletionMark = False
	   And UserObject.DeletionMark = True
	   And Users.CanLogOnToApplication(UserObject.InfobaseUserID) Then
		
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Error writing user %1.
			           |A user with ""Access to infobase allowed"" option selected cannot be marked for deletion.'"),
			UserObject.Ref);
	EndIf;
	
	If OldUser.NotValid = False
	   And UserObject.NotValid = True
	   And Users.CanLogOnToApplication(UserObject.InfobaseUserID) Then
		
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Error writing user %1.
			           |A user with ""Access to infobase allowed"" option selected cannot be marked invalid.'"),
			UserObject.Ref);
	EndIf;
	
	If OldUser.Prepared        = False
	   And UserObject.Prepared = True
	   And Users.CanLogOnToApplication(UserObject.InfobaseUserID) Then
		
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Error writing user %1.
			           |A user with ""Access to infobase allowed"" option cannot be marked prepared.'"),
			UserObject.Ref);
	EndIf;
	
EndProcedure
 

////////////////////////////////////////////////////////////////////////////////
// For ProcessRolesInterface procedure.
//

Procedure FillRoles(Parameters)
	
	ReadRoles = Parameters.MainParameter;
	RoleCollection  = Parameters.RoleCollection;
	
	RoleCollection.Clear();
	
	If TypeOf(ReadRoles) = Type("Array") Then
		For Each Role In ReadRoles Do
			If TypeOf(Role) = Type("CatalogRef.MetadataObjectIDs") Then
				If ValueIsFilled(Role) Then
					RoleName = CommonUse.ObjectAttributeValue(Role, "Name");
					RoleCollection.Add().Role = TrimAll(
						?(Left(RoleName, 1) = "?", Mid(RoleName, 2), RoleName));
				EndIf;
			Else
				RoleCollection.Add().Role = Role;
			EndIf;
		EndDo;
	Else
		For Each Row In ReadRoles Do
			If TypeOf(Row.Role) = Type("CatalogRef.MetadataObjectIDs") Then
				If ValueIsFilled(Row.Role) Then
					RoleName = CommonUse.ObjectAttributeValue(Row.Role, "Name");
					RoleCollection.Add().Role = TrimAll(
						?(Left(RoleName, 1) = "?", Mid(RoleName, 2), RoleName));
				EndIf;
			Else
				RoleCollection.Add().Role = Row.Role;
			EndIf;
		EndDo;
	EndIf;
	
	RefreshRoleTree(Parameters);
	
EndProcedure

Procedure SetUpRoleInterfaceOnFormCreate(Parameters)
	
	Form    = Parameters.Form;
	Items = Form.Items;
	
	// Setting initial values before importing data from the settings
	// on the server for the case where data is not written and is not being loaded.
	Form.ShowRoleSubsystems = False;
	Items.RolesShowRoleSubsystems.Check = False;
	
	// Showing all roles for a new user, or selected roles for an existing user.
	If Items.Find("RolesShowSelectedRolesOnly") <> Undefined Then
		Items.RolesShowSelectedRolesOnly.Check = Parameters.MainParameter;
	EndIf;
	
	RefreshRoleTree(Parameters);
	
EndProcedure

Procedure SetUpRoleInterfaceOnLoadSettings(Parameters)
	
	Settings = Parameters.MainParameter;
	Form     = Parameters.Form;
	Items    = Form.Items;
	
	ShowRoleSubsystems = Form.ShowRoleSubsystems;
	
	If Settings["ShowRoleSubsystems"] = False Then
		Form.ShowRoleSubsystems = False;
		Items.RolesShowRoleSubsystems.Check = False;
	Else
		Form.ShowRoleSubsystems = True;
		Items.RolesShowRoleSubsystems.Check = True;
	EndIf;
	
	If ShowRoleSubsystems <> Form.ShowRoleSubsystems Then
		RefreshRoleTree(Parameters);
	EndIf;
	
EndProcedure

Procedure SetRolesReadOnly(Parameters)
	
	Items            = Parameters.Form.Items;
	RolesReadOnly    = Parameters.MainParameter;
	
	If RolesReadOnly <> Undefined Then
		
		Items.Roles.ReadOnly          =    RolesReadOnly;
		
		If Items.Find("RolesCheckAll") <> Undefined Then
			Items.RolesCheckAll.Enabled = Not RolesReadOnly;
		EndIf;
		If Items.Find("RolesUncheckAll") <> Undefined Then
			Items.RolesUncheckAll.Enabled = Not RolesReadOnly;
		EndIf;
	EndIf;
	
EndProcedure

Procedure SelectedRolesOnly(Parameters)
	
	Parameters.Form.Items.RolesShowSelectedRolesOnly.Check =
		Not Parameters.Form.Items.RolesShowSelectedRolesOnly.Check;
	
	RefreshRoleTree(Parameters);
	
EndProcedure

Procedure GroupBySubsystems(Parameters)
	
	Parameters.Form.ShowRoleSubsystems = Not Parameters.Form.ShowRoleSubsystems;
	Parameters.Form.Items.RolesShowRoleSubsystems.Check = Parameters.Form.ShowRoleSubsystems;
	
	RefreshRoleTree(Parameters);
	
EndProcedure

Procedure RefreshRoleTree(Parameters)
	
	Form           = Parameters.Form;
	Items          = Form.Items;
	Roles          = Form.Roles;
	UserType       = Parameters.UserType;
	RoleCollection = Parameters.RoleCollection;
	
	HideFullAccessRole = Parameters.Property("HideFullAccessRole")
	                      And Parameters.HideFullAccessRole = True;
	
	If Items.Find("RolesShowSelectedRolesOnly") <> Undefined Then
		If Not Items.RolesShowSelectedRolesOnly.Enabled Then
			Items.RolesShowSelectedRolesOnly.Check = True;
		EndIf;
		ShowSelectedRolesOnly = Items.RolesShowSelectedRolesOnly.Check;
	Else
		ShowSelectedRolesOnly = True;
	EndIf;
	
	ShowRoleSubsystems = Parameters.Form.ShowRoleSubsystems;
	
	// Remembering the current row
	CurrentSubsystem = "";
	CurrentRole      = "";
	
	If Items.Roles.CurrentRow <> Undefined Then
		CurrentData = Roles.FindByID(Items.Roles.CurrentRow);
		
		If CurrentData = Undefined Then
			Items.Roles.CurrentRow = Undefined;
			
		ElsIf CurrentData.IsRole Then
			CurrentSubsystem = ?(CurrentData.GetParent() = Undefined, "", CurrentData.GetParent().Name);
			CurrentRole      = CurrentData.Name;
		Else
			CurrentSubsystem = CurrentData.Name;
			CurrentRole      = "";
		EndIf;
	EndIf;
	
	RoleTree = UsersInternalCached.RoleTree(
		ShowRoleSubsystems, UserType).Copy();
	
	AddNonExistentRoleNames(Parameters, RoleTree);
	
	RoleTree.Columns.Add("Check",          New TypeDescription("Boolean"));
	RoleTree.Columns.Add("PictureNumber", New TypeDescription("Number"));
	PrepareRoleTree(RoleTree.Rows, HideFullAccessRole, ShowSelectedRolesOnly, Parameters.RoleCollection);
	
	Parameters.Form.ValueToFormAttribute(RoleTree, "Roles");
	
	Items.Roles.Representation = ?(RoleTree.Rows.Find(False, "IsRole") = Undefined, TableRepresentation.List, TableRepresentation.Tree);
	
	// Restoring the current row
	FoundRows = RoleTree.Rows.FindRows(New Structure("IsRole, Name", False, CurrentSubsystem), True);
	If FoundRows.Count() <> 0 Then
		SubsystemDetails = FoundRows[0];
		SubsystemIndex = ?(SubsystemDetails.Parent = Undefined, RoleTree.Rows, SubsystemDetails.Parent.Rows).IndexOf(SubsystemDetails);
		SubsystemRow = FormDataTreeItemCollection(Roles, SubsystemDetails).Get(SubsystemIndex);
		If ValueIsFilled(CurrentRole) Then
			FoundRows = SubsystemDetails.Rows.FindRows(New Structure("IsRole, Name", True, CurrentRole));
			If FoundRows.Count() <> 0 Then
				RoleDetails = FoundRows[0];
				Items.Roles.CurrentRow = SubsystemRow.GetItems().Get(SubsystemDetails.Rows.IndexOf(RoleDetails)).GetID();
			Else
				Items.Roles.CurrentRow = SubsystemRow.GetID();
			EndIf;
		Else
			Items.Roles.CurrentRow = SubsystemRow.GetID();
		EndIf;
	Else
		FoundRows = RoleTree.Rows.FindRows(New Structure("IsRole, Name", True, CurrentRole), True);
		If FoundRows.Count() <> 0 Then
			RoleDetails = FoundRows[0];
			RoleIndex = ?(RoleDetails.Parent = Undefined, RoleTree.Rows, RoleDetails.Parent.Rows).IndexOf(RoleDetails);
			RoleRow = FormDataTreeItemCollection(Roles, RoleDetails).Get(RoleIndex);
			Items.Roles.CurrentRow = RoleRow.GetID();
		EndIf;
	EndIf;
	
EndProcedure

Procedure AddNonExistentRoleNames(Parameters, RoleTree)
	
	RoleCollection  = Parameters.RoleCollection;
	
	// Adding nonexistent roles
	For Each Row In RoleCollection Do
		Filter = New Structure("IsRole, Name", True, Row.Role);
		If RoleTree.Rows.FindRows(Filter, True).Count() = 0 Then
			TreeRow = RoleTree.Rows.Insert(0);
			TreeRow.IsRole  = True;
			TreeRow.Name    = Row.Role;
			TreeRow.Synonym = "? " + Row.Role;
		EndIf;
	EndDo;
	
EndProcedure

Procedure PrepareRoleTree(Val Collection, Val HideFullAccessRole, Val ShowSelectedRolesOnly, RoleCollection)
	
	Index = Collection.Count()-1;
	
	While Index >= 0 Do
		Row = Collection[Index];
		
		PrepareRoleTree(Row.Rows, HideFullAccessRole, ShowSelectedRolesOnly, RoleCollection);
		
		If Row.IsRole Then
			If HideFullAccessRole
			   And (    Upper(Row.Name) = Upper("FullAccess")
			      Or Upper(Row.Name) = Upper("FullAdministrator")) Then
				Collection.Delete(Index);
			Else
				Row.PictureNumber = 7;
				Row.Check = RoleCollection.FindRows(
					New Structure("Role", Row.Name)).Count() > 0;
				
				If ShowSelectedRolesOnly And Not Row.Check Then
					Collection.Delete(Index);
				EndIf;
			EndIf;
		Else
			If Row.Rows.Count() = 0 Then
				Collection.Delete(Index);
			Else
				Row.PictureNumber = 6;
				Row.Check = Row.Rows.FindRows(
					New Structure("Check", False)).Count() = 0;
			EndIf;
		EndIf;
		
		Index = Index-1;
	EndDo;
	
EndProcedure

Function FormDataTreeItemCollection(Val FormDataTree, Val ValueTreeRow)
	
	If ValueTreeRow.Parent = Undefined Then
		FormDataTreeItemCollection = FormDataTree.GetItems();
	Else
		ParentIndex = ?(ValueTreeRow.Parent.Parent = Undefined, ValueTreeRow.Owner().Rows, ValueTreeRow.Parent.Parent.Rows).IndexOf(ValueTreeRow.Parent);
		FormDataTreeItemCollection = FormDataTreeItemCollection(FormDataTree, ValueTreeRow.Parent).Get(ParentIndex).GetItems();
	EndIf;
	
	Return FormDataTreeItemCollection;
	
EndFunction

Procedure UpdateRoleContent(Parameters)
	
	Roles                 = Parameters.Form.Roles;
	ShowSelectedRolesOnly = Parameters.Form.Items.RolesShowSelectedRolesOnly.Check;
	UserType              = Parameters.UserType;
	
	AllRoles          = AllRoles().Array;
	InaccessibleRoles = InaccessibleRolesByUserType(UserType);
	
	If Parameters.MainParameter = "EnableAll" Then
		RowID = Undefined;
		Add   = True;
		
	ElsIf Parameters.MainParameter = "DisableAll" Then
		RowID = Undefined;
		Add   = False;
	Else
		RowID = Parameters.Form.Items.Roles.CurrentRow;
	EndIf;
	
	If RowID = Undefined Then
		
		AdministrativeAccessSet = Parameters.RoleCollection.FindRows(
			New Structure("Role", "FullAccess")).Count() > 0;
		
		// Processing all
		RoleCollection = Parameters.RoleCollection;
		RoleCollection.Clear();
		If Add Then
			For Each Role In AllRoles Do
				
				If InaccessibleRoles.Get(Role) = Undefined
				   And Upper(Left(Role, StrLen("Delete"))) <> Upper("Delete")
				   And Role <> "FullAccess"
				   And Role <> "FullAdministrator" Then
					
					RoleCollection.Add().Role = Role;
				EndIf;
			EndDo;
		EndIf;
		
		If Parameters.Property("AdministrativeAccessChangeProhibition")
			And Parameters.AdministrativeAccessChangeProhibition Then
			
			AdministrativeAccessSet = Parameters.RoleCollection.FindRows(
				New Structure("Role", "FullAccess")).Count() > 0;
			
			If AdministrativeAccessSet And Not AdministrativeAccessSet Then
				Parameters.RoleCollection.FindRows(New Structure("Role", "FullAccess")).Delete(0);
			ElsIf AdministrativeAccessSet And Not AdministrativeAccessSet Then
				RoleCollection.Add().Role = "FullAccess";
			EndIf;
		EndIf;
		
		If ShowSelectedRolesOnly Then
			If RoleCollection.Count() > 0 Then
				RefreshRoleTree(Parameters);
			Else
				Roles.GetItems().Clear();
			EndIf;
			// Return
			Return;
			// Return
		EndIf;
	Else
		CurrentData = Roles.FindByID(RowID);
		If CurrentData.IsRole Then
			AddDeleteRole(Parameters, CurrentData.Name, CurrentData.Check);
		Else
			AddDeleteSubsystemRoles(Parameters, CurrentData.GetItems(), CurrentData.Check);
		EndIf;
	EndIf;
	
	RefreshSelectedRoleMarks(Parameters, Roles.GetItems());
	
	Modified = True;
	
EndProcedure
 

Procedure AddDeleteRole(Parameters, Val Role, Val Add)
	
	FoundRoles = Parameters.RoleCollection.FindRows(New Structure("Role", Role));
	
	If Add Then
		If FoundRoles.Count() = 0 Then
			Parameters.RoleCollection.Add().Role = Role;
		EndIf;
	Else
		If FoundRoles.Count() > 0 Then
			Parameters.RoleCollection.Delete(FoundRoles[0]);
		EndIf;
	EndIf;
	
EndProcedure
 

Procedure AddDeleteSubsystemRoles(Parameters, Val Collection, Val Add)
	
	For Each Row In Collection Do
		If Row.IsRole Then
			AddDeleteRole(Parameters, Row.Name, Add);
		Else
			AddDeleteSubsystemRoles(Parameters, Row.GetItems(), Add);
		EndIf;
	EndDo;
	
EndProcedure

Procedure RefreshSelectedRoleMarks(Parameters, Val Collection)
	
	ShowSelectedRolesOnly = Parameters.Form.Items.RolesShowSelectedRolesOnly.Check;
	
	Index = Collection.Count()-1;
	
	While Index >= 0 Do
		Row = Collection[Index];
		
		If Row.IsRole Then
			Row.Check = Parameters.RoleCollection.FindRows(New Structure("Role", Row.Name)).Count() > 0;
			If ShowSelectedRolesOnly And Not Row.Check Then
				Collection.Delete(Index);
			EndIf;
		Else
			RefreshSelectedRoleMarks(Parameters, Row.GetItems());
			If Row.GetItems().Count() = 0 Then
				Collection.Delete(Index);
			Else
				Row.Check = True;
				For Each Item In Row.GetItems() Do
					If Not Item.Check Then
						Row.Check = False;
						Break;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		
		Index = Index-1;
	EndDo;
	
EndProcedure

//These handlers were moved from AccessManagement and must be deleted in next releases
//begin

Procedure OnDefineRoleEditProhibition(Prohibition) Export
	
	//Prohibition = True;
	
EndProcedure

Procedure OnDefineActionsInForm(Ref, ActionsOnForm) Export
	
	//ActionsOnForm.Roles = "";
	
EndProcedure

//end

#EndRegion