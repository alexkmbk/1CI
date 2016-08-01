////////////////////////////////////////////////////////////////////////////////
// Users subsystem.
//
////////////////////////////////////////////////////////////////////////////////

#Region Interface

////////////////////////////////////////////////////////////////////////////////
// Main procedures and functions.

// See the function with the same name in the UsersClientServer common module.
Function AuthorizedUser() Export
	
	Return UsersClientServer.AuthorizedUser();
	
EndFunction

// See the function with the same name in the UsersClientServer common module.
Function CurrentUser() Export
	
	Return UsersClientServer.CurrentUser();
	
EndFunction

// Checks whether the current user or the specified user has full access rights.
//  
// A user has full access rights if:
// a) the infobase user list is not empty and the user has the FullAccess
// role and the administrative role
// (provided that CheckSystemAdministrationRights is True), 
// b) the infobase user list is empty and the default role is either not specified or FullAccess.
// 
// Parameters:
//  User - Undefined - check the the current infobase user.
//       - CatalogRef.Users, CatalogRef.ExternalUsers - search for infobase
//        user by UUID that is stored in the InfobaseUserID attribute.
//        Returns False if the infobase user is not found.
//       - InfobaseUser - checks the infobase user that is passed to the function.
// 
//  CheckSystemAdministrationRights - Boolean - if True, checks whether the
//         user has the administrative role.
// 
//  ForPrivilegedMode - Boolean - if True, for the current user the function returns True (provided that privileged mode is set).
// 
// Returns:
//  Boolean - if True, the user has full access rights.
//
Function InfobaseUserWithFullAccess(User = Undefined,
                                    CheckSystemAdministrationRights = False,
                                    ForPrivilegedMode = True) Export
	
	PrivilegedModeSet = PrivilegedMode();
	
	SetPrivilegedMode(True);
	Properties = CheckedInfobaseUserProperties(User);
	IBUser = Properties.IBUser;
	
	CheckFullAccessRole = Not CheckSystemAdministrationRights;
	CheckSystemAdministratorRole = CheckSystemAdministrationRights;
	
	If IBUser = Undefined Then
		Return False;
	ElsIf Not Properties.IsCurrentInfobaseUser Then
		// Checking roles for the saved infobase user if the user to be checked
   // is not the current one.
		If CheckFullAccessRole
		   And Not IBUser.Roles.Contains(Metadata.Roles.FullAccess) Then
			Return False;
		EndIf;
		If CheckSystemAdministratorRole
		   And Not IBUser.Roles.Contains(FullAdministratorRole(True)) Then
			Return False;
		EndIf;
		Return True;
	Else
		If ForPrivilegedMode And PrivilegedModeSet Then
			Return True;
		EndIf;
		
		If StandardSubsystemsCached.PrivilegedModeSetOnStart() Then
			// User has full access rights if the client application runs withthe
     // UsePrivilegedMode parameter (provided that privileged mode is set).
			Return True;
		EndIf;
		
		If Not ValueIsFilled(IBUser.Name) And Metadata.DefaultRoles.Count() = 0 Then
			// If the default roles collection is empty and the user is not specified, the user has full access rights (as in the privileged mode).
			Return True;
		EndIf;
		
		If Not ValueIsFilled(IBUser.Name)
		   And PrivilegedModeSet
		   And AccessRight("Administration", Metadata, IBUser) Then
			// If the user is not specified and has the Administration right and privileged mode is set, the user has full access rights.
			Return True;
		EndIf;
		
		// Checking roles of the current infobase user (the current session
   //roles are checked instead of the user roles that are saved to the Infobase).
		If CheckFullAccessRole
		   And Not IsInRole(Metadata.Roles.FullAccess) Then
			Return False;
		EndIf;
		If CheckSystemAdministratorRole
		   And Not IsInRole(FullAdministratorRole(True)) Then
			Return False;
		EndIf;
		Return True;
	EndIf;
	
EndFunction

// Returns True if at least one of the specified roles is available for the
// user, or the user has full access rights.
//
// Parameters:
//  RoleNames          - String - names of roles whose availability is
//                       checked, separated by commas.
//
//  User               - Undefined - check the the current infobase user.
//                     - CatalogRef.Users, CatalogRef.ExternalUsers - search
//                       for infobase user by UUID that is stored in the 
//                       InfobaseUserID attribute. Returns False if the
//                       infobase user is not found.
//                     - InfobaseUser - checks the infobase user that is
//                       passed to the function.
//
//  ForPrivilegedMode - Boolean - if True, for the current user the function
//                      returns True (provided that privileged mode is set).
//
// Returns:
//  Boolean - True if at least one of the roles is available or the
//            InfobaseUserWithFullAccess(User) function returns True.
//
Function RolesAvailable(RoleNames,
                     User = Undefined,
                     ForPrivilegedMode = True) Export
	
	If InfobaseUserWithFullAccess(User, , ForPrivilegedMode) Then
		Return True;
	EndIf;
	
	SetPrivilegedMode(True);
	Properties = CheckedInfobaseUserProperties(User);
	IBUser = Properties.IBUser;
	
	If IBUser = Undefined Then
		Return False;
	EndIf;
	
	RoleNameArray = StringFunctionsClientServer.SplitStringIntoSubstringArray(RoleNames);
	For Each RoleName In RoleNameArray Do
		
		If Properties.IsCurrentInfobaseUser Then
			If IsInRole(TrimAll(RoleName)) Then
				Return True;
			EndIf;
		Else
			If IBUser.Roles.Contains(Metadata.Roles.Find(TrimAll(RoleName))) Then
				Return True;
			EndIf;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// Checks whether an infobase user has at least one authentication kind.
//
// Parameters:
//  InfobaseUserDescription - UUID - infobase user UUID.
//                      - Structure - contains 3 authentication properties:
//                             * StandardAuthentication - Boolean
//                             * OSAuthentication       - Boolean
//                             * OpenIDAuthentication   - Boolean
//                       - InfobaseUser
//                       - CatalogRef.Users
//                       - CatalogRef.ExternalUsers
//
// Returns:
//  Boolean - True if at least one authentication property value is True.
//
Function CanLogOnToApplication(InfobaseUserDescription) Export
	
	SetPrivilegedMode(True);
	
	UUID = Undefined;
	
	If TypeOf(InfobaseUserDescription) = Type("CatalogRef.Users")
	 Or TypeOf(InfobaseUserDescription) = Type("CatalogRef.ExternalUsers") Then
		
		UUID = CommonUse.ObjectAttributeValue(
			InfobaseUserDescription, "InfobaseUserID");
		
		If TypeOf(InfobaseUserDescription) <> Type("UUID") Then
			Return False;
		EndIf;
		
	ElsIf TypeOf(InfobaseUserDescription) = Type("UUID") Then
		UUID = InfobaseUserDescription;
	EndIf;
	
	If UUID <> Undefined Then
		IBUser = InfobaseUsers.FindByUUID(UUID);
		
		If IBUser = Undefined Then
			Return False;
		EndIf;
	Else
		IBUser = InfobaseUserDescription;
	EndIf;
	
	Return IBUser.StandardAuthentication
		Or IBUser.OSAuthentication
		Or IBUser.OpenIDAuthentication;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions used in managed forms

// Returns a list of users, user groups, external users, and external user groups that are not marked for deletion.
//  Used in TextEditEnd and AutoComplete event handlers.
//
// Parameters:
//  Text                  - String - characters entered by the user.
//
//  IncludeGroups         - Boolean - if True, user groups and external user
//                          group also be included in the function result.
//                          This parameter is ignored if the UseUserGroups
//                          functional option is disabled.
//
//  IncludingExternalUsers - Undefined, Boolean - if Undefined, the
//                           ExternalUsers.UseExternalUsers() function
//                           result is used.
//
//  NoUsers                - Boolean - if True, items of the Users catalog
//                           are excluded from the function result.
//
Function GenerateUserSelectionData(Val Text,
                                             Val IncludeGroups = True,
                                             Val IncludingExternalUsers = Undefined,
                                             Val NoUsers = False) Export
	
	IncludeGroups = IncludeGroups And GetFunctionalOption("UseUserGroups");
	
	Query = New Query;
	Query.SetParameter("Text", Text + "%");
	Query.SetParameter("IncludeGroups", IncludeGroups);
	Query.Text = 
	"SELECT ALLOWED
	|	VALUE(Catalog.Users.EmptyRef) AS Ref,
	|	"""" AS Description,
	|	-1 AS PictureNumber
	|WHERE
	|	FALSE";
	
	If Not NoUsers Then
		Query.Text = Query.Text + " UNION ALL " +
		"SELECT
		|	Users.Ref,
		|	Users.Description,
		|	1 AS PictureNumber
		|FROM
		|	Catalog.Users AS Users
		|WHERE
		|	NOT Users.DeletionMark
		|	AND Users.Description LIKE &Text
		|	AND Users.NotValid = FALSE
		|	AND Users.Internal = FALSE
		|
		|UNION ALL
		|
		|SELECT
		|	UserGroups.Ref,
		|	UserGroups.Description,
		|	3
		|FROM
		|	Catalog.UserGroups AS UserGroups
		|WHERE
		|	&IncludeGroups
		|	AND NOT UserGroups.DeletionMark
		|	AND UserGroups.Description LIKE &Text";
	EndIf;
	
	If TypeOf(IncludingExternalUsers) <> Type("Boolean") Then
		IncludingExternalUsers = ExternalUsers.UseExternalUsers();
	EndIf;
	IncludingExternalUsers = IncludingExternalUsers
	                            And AccessRight("Read", Metadata.Catalogs.ExternalUsers);
	
	If IncludingExternalUsers Then
		Query.Text = Query.Text + " UNION ALL " +
		"SELECT
		|	ExternalUsers.Ref,
		|	ExternalUsers.Description,
		|	7 AS PictureNumber
		|FROM
		|	Catalog.ExternalUsers AS ExternalUsers
		|WHERE
		|	(NOT ExternalUsers.DeletionMark)
		|	AND ExternalUsers.Description LIKE &Text
		|	AND ExternalUsers.NotValid = FALSE
		|
		|UNION ALL
		|
		|SELECT
		|	ExternalUserGroups.Ref,
		|	ExternalUserGroups.Description,
		|	9
		|FROM
		|	Catalog.ExternalUserGroups AS ExternalUserGroups
		|WHERE
		|	&IncludeGroups
		|	AND (NOT ExternalUserGroups.DeletionMark)
		|	AND ExternalUserGroups.Description LIKE &Text";
	EndIf;
	
	Selection = Query.Execute().Select();
	
	ChoiceData = New ValueList;
	
	While Selection.Next() Do
		ChoiceData.Add(Selection.Ref, Selection.Description, , PictureLib["UserState" + Format(Selection.PictureNumber + 1, "ND=2; NLZ=; NG=")]);
	EndDo;
	
	Return ChoiceData;
	
EndFunction

// The FillUserPictureNumbers procedure fills picture numbers of users, user groups, external users, and external user groups.
// 
// Parameters:
//  Table                  - FormDataCollection, FormDataTree - the list to
//                           be filled.
//  UserFieldName          - String - name of the field that contains a
//                           reference to user, user group, external user,
//                           or external user group.
//  PictureNumberFieldName - String - name of the field containing the
//                           picture number.
//  RowID                  - Undefined, Number - row ID (not a serial
//                           number). If it is Undefined, picture numbers
//                           are filled for all rows.
//
Procedure FillUserPictureNumbers(Val Table,
                                               Val UserFieldName,
                                               Val PictureNumberFieldName,
                                               Val RowID = Undefined,
                                               Val ProcessSecondAndThirdLevelHierarchy = False) Export
	
	SetPrivilegedMode(True);
	
	If RowID = Undefined Then
		RowArray = Undefined;
		
	ElsIf TypeOf(RowID) = Type("Array") Then
		RowArray = New Array;
		For Each ID In RowID Do
			RowArray.Add(Table.FindByID(ID));
		EndDo;
	Else
		RowArray = New Array;
		RowArray.Add(Table.FindByID(RowID));
	EndIf;
	
	If TypeOf(Table) = Type("FormDataTree") Then
		If RowArray = Undefined Then
			RowArray = Table.GetItems();
		EndIf;
		UserTable = New ValueTable;
		UserTable.Columns.Add(UserFieldName, Metadata.InformationRegisters.UserGroupContents.Dimensions.UserGroup.Type);
		For Each Row In RowArray Do
			UserTable.Add()[UserFieldName] = Row[UserFieldName];
			If ProcessSecondAndThirdLevelHierarchy Then
				For Each Row2 In Row.GetItems() Do
					UserTable.Add()[UserFieldName] = Row2[UserFieldName];
					For Each Row3 In Row2.GetItems() Do
						UserTable.Add()[UserFieldName] = Row3[UserFieldName];
					EndDo;
				EndDo;
			EndIf;
		EndDo;
	ElsIf TypeOf(Table) = Type("FormDataCollection") Then
		If RowArray = Undefined Then
			RowArray = Table;
		EndIf;
		UserTable = New ValueTable;
		UserTable.Columns.Add(UserFieldName, Metadata.InformationRegisters.UserGroupContents.Dimensions.UserGroup.Type);
		For Each Row In RowArray Do
			UserTable.Add()[UserFieldName] = Row[UserFieldName];
		EndDo;
	Else
		If RowArray = Undefined Then
			RowArray = Table;
		EndIf;
		UserTable = Table.Unload(RowArray, UserFieldName);
	EndIf;
	
	Query = New Query(StrReplace(
	"SELECT DISTINCT
	|	Users.UserFieldName AS User
	|INTO Users
	|FROM
	|	&Users AS Users
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Users.User,
	|	CASE
	|		WHEN Users.User = UNDEFINED
	|			THEN -1
	|		WHEN VALUETYPE(Users.User) = TYPE(Catalog.Users)
	|			THEN CASE
	|					WHEN CAST(Users.User AS Catalog.Users).DeletionMark
	|						THEN 0
	|					ELSE 1
	|				END
	|		WHEN VALUETYPE(Users.User) = TYPE(Catalog.UserGroups)
	|			THEN CASE
	|					WHEN CAST(Users.User AS Catalog.UserGroups).DeletionMark
	|						THEN 2
	|					ELSE 3
	|				END
	|		WHEN VALUETYPE(Users.User) = TYPE(Catalog.ExternalUsers)
	|			THEN CASE
	|					WHEN CAST(Users.User AS Catalog.ExternalUsers).DeletionMark
	|						THEN 6
	|					ELSE 7
	|				END
	|		WHEN VALUETYPE(Users.User) = TYPE(Catalog.ExternalUserGroups)
	|			THEN CASE
	|					WHEN CAST(Users.User AS Catalog.ExternalUserGroups).DeletionMark
	|						THEN 8
	|					ELSE 9
	|				END
	|		ELSE -2
	|	END AS PictureNumber
	|FROM
	|	Users AS Users", "UserFieldName", UserFieldName));
	Query.SetParameter("Users", UserTable);
	PictureNumbers = Query.Execute().Unload();
	
	For Each Row In RowArray Do
		FoundRow = PictureNumbers.Find(Row[UserFieldName], "User");
		Row[PictureNumberFieldName] = ?(FoundRow = Undefined, -2, FoundRow.PictureNumber);
		If ProcessSecondAndThirdLevelHierarchy Then
			For Each Row2 In Row.GetItems() Do
				FoundRow = PictureNumbers.Find(Row2[UserFieldName], "User");
				Row2[PictureNumberFieldName] = ?(FoundRow = Undefined, -2, FoundRow.PictureNumber);
				For Each Row3 In Row2.GetItems() Do
					FoundRow = PictureNumbers.Find(Row3[UserFieldName], "User");
					Row3[PictureNumberFieldName] = ?(FoundRow = Undefined, -2, FoundRow.PictureNumber);
				EndDo;
			EndDo;
		EndIf;
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions used for infobase update

// The procedure is used for infobase update and initial filling. It does one of the following:
// 1) Creates the first administrator and maps it to a new user or an
//    existing item of the Users catalog.
// 2) Maps the administrator that is specified in the InfobaseUser
//    parameter to a new user or an existing Users catalog item.
//
// Parameters:
//  IBUser - InfobaseUser - used for mapping an existing administrator to a
//           new user or an existing Users catalog item.
//
// Returns:
//  Undefined        - a User catalog item that is mapped to the infobase
//                     user with administrative rights already exists.
//  CatalogRef.Users - a User catalog item that is mapped to the first
//                     administrator or the administrator specified in the
//                     InfobaseUser parameter.
//
Function CreateAdministrator(IBUser = Undefined) Export
	
	SetPrivilegedMode(True);
	
	// Adding administrator (system administrator, full access).
	If IBUser = Undefined Then
		
		If CommonUseCached.DataSeparationEnabled() Then
			Return Undefined;
		EndIf;
		
		// If a user with administrative rights exists, there is no need to create another administrator.
		IBUser = Undefined;
	
		CurInfobaseUsers = InfobaseUsers.GetUsers();
		For Each CurrentInfobaseUser In CurInfobaseUsers Do
			If InfobaseUserWithFullAccess(CurrentInfobaseUser,, False) Then
				Return Undefined;
			EndIf;
		EndDo;
		
		If IBUser = Undefined Then
			IBUser = InfobaseUsers.CreateUser();
			IBUser.Name     = "Administrator";
			IBUser.FullName = IBUser.Name;
			IBUser.Roles.Clear();
			IBUser.Roles.Add(Metadata.Roles.FullAccess);
			
			If Not CommonUseCached.DataSeparationEnabled() Then
				FullAdministratorRole = FullAdministratorRole();
				
				If Not IBUser.Roles.Contains(FullAdministratorRole) Then
					IBUser.Roles.Add(FullAdministratorRole);
				EndIf;
			EndIf;
			IBUser.Write();
		EndIf;
	Else
		If Not IBUser.Roles.Contains(Metadata.Roles.FullAccess)
		 Or Not IBUser.Roles.Contains(Users.FullAdministratorRole()) Then
		
			Return Undefined;
		EndIf;
		
		FindAmbiguousInfobaseUsers(, IBUser.UUID);
	EndIf;
	
	If UsersInternal.UserByIDExists(
	         IBUser.UUID) Then
		
		User = Catalogs.Users.FindByAttribute(
			"InfobaseUserID", IBUser.UUID);
		
		// If the administrator is mapped to an external user, it is an error and clearing the mapping is required.
		If Not ValueIsFilled(User) Then
			
			ExternalUser = Catalogs.ExternalUsers.FindByAttribute(
				"InfobaseUserID", IBUser.UUID);
			
			ExternalUserObject = ExternalUser.GetObject();
			ExternalUserObject.InfobaseUserID = Undefined;
			ExternalUserObject.DataExchange.Load = True;
			ExternalUserObject.Write();
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(User) Then
		User = Catalogs.Users.FindByDescription(IBUser.FullName);
		
		If ValueIsFilled(User)
		   And ValueIsFilled(User.InfobaseUserID)
		   And User.InfobaseUserID <> IBUser.UUID
		   And InfobaseUsers.FindByUUID(
		         User.InfobaseUserID) <> Undefined Then
			
			User = Undefined;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(User) Then
		User = Catalogs.Users.CreateItem();
		UserCreated = True;
	Else
		User = User.GetObject();
		UserCreated = False;
	EndIf;
	
	User.Description = IBUser.FullName;
	
	InfobaseUserDescription = New Structure;
	InfobaseUserDescription.Insert("Action", "Write");
	InfobaseUserDescription.Insert(
		"UUID", IBUser.UUID);
	
	User.AdditionalProperties.Insert(
		"InfobaseUserDescription", InfobaseUserDescription);
	
	User.Write();
	
	Return User.Ref;
	
EndFunction

// Sets the UseUserGroups constant value to True if at least one user group exists in the catalog.
//
// The procedure is used during infobase update.
//
Procedure IfUserGroupsExistSetUse() Export
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT
	|	TRUE AS TrueValue
	|FROM
	|	Catalog.UserGroups AS UserGroups
	|WHERE
	|	UserGroups.Ref <> VALUE(Catalog.UserGroups.AllUsers)
	|
	|UNION ALL
	|
	|SELECT
	|	TRUE
	|FROM
	|	Catalog.ExternalUserGroups AS ExternalUserGroups
	|WHERE
	|	ExternalUserGroups.Ref <> VALUE(Catalog.ExternalUserGroups.AllExternalUsers)");
	
	If Not Query.Execute().IsEmpty() Then
		Constants.UseUserGroups.Set(True);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for infobase user operations

// Returns the full name of the user that is not specified (to be displayed in the user interface).
Function UnspecifiedUserFullName() Export
	
	Return NStr("en = '<Not specified>'");
	
EndFunction

// Checks whether the infobase user is mapped to an item of the Users catalog or the ExternalUsers catalog.
// 
// Parameters:
//  IBUser   - String - infobase user name.
//           - UUID - infobase user UUID.
//           - InfobaseUser -
//
//  Account  - InfobaseUser - (return value).
//
// Returns:
//  Boolean  - True if the infobase user exists and its ID is used 
//             either in the Users catalog or in the ExternalUsers catalog.
//
Function InfobaseUserIsOccupied(IBUser, Account = Undefined) Export
	
	SetPrivilegedMode(True);
	
	If TypeOf(IBUser) = Type("String") Then
		Account = InfobaseUsers.FindByName(IBUser);
		
	ElsIf TypeOf(IBUser) = Type("UUID") Then
		Account = InfobaseUsers.FindByUUID(IBUser);
	Else
		Account = IBUser;
	EndIf;
	
	If Account = Undefined Then
		Return False;
	EndIf;
	
	Return UsersInternal.UserByIDExists(
		Account.UUID);
	
EndFunction

// Returns an empty structure that describes infobase user properties.
//
// Returns:
//  Structure - with the following properties:
//   * UUID                   - UUID
//   * Name                   - String
//   * FullName               - String
//
//   * OpenIDAuthentication   - Boolean
//
//   * StandardAuthentication - Boolean
//   * ShowInList             - Boolean
//   * Password               - Undefined
//   * StoredPasswordValue    - Undefined
//   * PasswordIsSet          - Boolean
//   * CannotChangePassword   - Boolean
//
//   * OSAuthentication       - Boolean
//   * OSUser                 - String - this structure item is ignored in
//                              the training version of the platform.
//
//   * DefaultInterface       - Undefined
//                            - String - interface name from the
//                              Metadata.Interfaces collection.
//
//   * RunMode                - Undefined
//                            - String - values: "Auto", 
//                              "OrdinaryApplication", "ManagedApplication".
//   * Language               - Undefined
//                            - String - language name from the
//                              Metadata.Languages collection.
//
//   * Role                   - Undefined -
//                            - Array - values of the following type:
//                                * String - role names from the
//                                  Metadata.Roles collection.
//
Function NewInfobaseUserInfo() Export
	
	// Preparing the data structure for storing the return value
	Properties = New Structure;
	
	Properties.Insert("UUID",
		New UUID("00000000-0000-0000-0000-000000000000"));
	
	Properties.Insert("Name",                   "");
	Properties.Insert("FullName",               "");
	Properties.Insert("OpenIDAuthentication",   False);
	Properties.Insert("StandardAuthentication", False);
	Properties.Insert("ShowInList",             False);
	Properties.Insert("OldPassword",            Undefined);
	Properties.Insert("Password",               Undefined);
	Properties.Insert("StoredPasswordValue",    Undefined);
	Properties.Insert("PasswordIsSet",          False);
	Properties.Insert("CannotChangePassword",   False);
	Properties.Insert("OSAuthentication",       False);
	Properties.Insert("OSUser",                 "");
	
	Properties.Insert("DefaultInterface",
		?(Metadata.DefaultInterface = Undefined, "", Metadata.DefaultInterface.Name));
	
	Properties.Insert("RunMode",               "Auto");
	
	Properties.Insert("Language",
		?(Metadata.DefaultLanguage = Undefined, "", Metadata.DefaultLanguage.Name));
	
	Properties.Insert("Roles",                 Undefined);
	
	Return Properties;
	
EndFunction

// Gets infobase user properties for the infobase user found by string ID or UUID.
//
// Parameters:
//  ID               - Undefined, String, UUID - user ID.
//  Properties       - Structure - see the list of properties in the
//                     NewInfobaseUserInfo() function.
//  ErrorDescription - String - contains error details if the user cannot be read.
//
// Returns:
//  Boolean - if True, the user is read, otherwise see ErrorDescription.
//
Function ReadInfobaseUser(Val ID,
                                Properties = Undefined,
                                ErrorDescription = "",
                                IBUser = Undefined) Export
	
	Properties = NewInfobaseUserInfo();
	
	Properties.Roles = New Array;
	
	If TypeOf(ID) = Type("UUID") Then
		
		If CommonUseCached.DataSeparationEnabled()
		   And CommonUseCached.SessionWithoutSeparators()
		   And CommonUseCached.CanUseSeparatedData()
		   And ID = InfobaseUsers.CurrentUser().UUID Then
			
			IBUser = InfobaseUsers.CurrentUser();
		Else
			IBUser = InfobaseUsers.FindByUUID(ID);
		EndIf;
		
	ElsIf TypeOf(ID) = Type("String") Then
		IBUser = InfobaseUsers.FindByName(ID);
	Else
		IBUser = Undefined;
	EndIf;
	
	If IBUser = Undefined Then
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Infobase user %1 is not found.'"), ID);
		Return False;
	EndIf;
	
	CopyInfobaseUserProperties(Properties, IBUser);
	
	Return True;
	
EndFunction

// Overwrites properties of the infobase user that is found by string ID or
// UUID, or creates a new infobase user (if an attempt to create an existing
// user is made, the function raises an exception).
//
// Parameters:
//  ID                 - String, UUID - user ID.
//
//  PropertiesToUpdate - Structure - see the list of properties in the
//                       NewInfobaseUserInfo() function.
//                       If this property is not set, the read value or the 
//                       initial value is used instead.
//                       The following structure properties are used in an 
//                       unusual way:
//      * UUID         - Undefined - return value, it is set after the 
//                       infobase user is written.
//      * OldPassword  - Undefined, String - if the specified
//                       password does not match the existing
//                       one, an exception is raised. 
//
//  CreateNew         - False  - no further actions.
//                    - Undefined, True - creates а new infobase user if
//                      IBUser is not found by the specified ID.
//                      If the parameter value is True and the infobase user
//                      is found by the specified ID, an exception is raised.
//
//  ErrorDescription - String - contains error details if the user cannot be read.
//
// Returns:
//  Boolean - if True, the user is written, otherwise see ErrorDescription.
//
Function WriteInfobaseUser(Val ID,
                               Val PropertiesToUpdate,
                               Val CreateNew = False,
                               ErrorDescription = "",
                               IBUser = Undefined) Export
	
	IBUser = Undefined;
	OldProperties = Undefined;
	
	PreliminaryRead = ReadInfobaseUser(
		ID, OldProperties, ErrorDescription, IBUser);
	
	If Not PreliminaryRead Then
		
		If CreateNew = Undefined Or CreateNew = True Then
			IBUser = InfobaseUsers.CreateUser();
		Else
			Return False;
		EndIf;
	ElsIf CreateNew = True Then
		ErrorDescription = ErrorDetailsOnWriteInfobaseUser(
			NStr("en = 'Cannot create infobase user %1 because it already exists.'"),
			OldProperties.Name,
			OldProperties.UUID);
		Return False;
	Else
		If PropertiesToUpdate.Property("OldPassword")
		   And TypeOf(PropertiesToUpdate.OldPassword) = Type("String") Then
			
			OldPasswordSame = False;
			
			UsersInternal.StoredStringPasswordValue(
				PropertiesToUpdate.OldPassword,
				OldProperties.UUID,
				OldPasswordSame);
			
			If NOT OldPasswordSame Then
				ErrorDescription = ErrorDetailsOnWriteInfobaseUser(
					NStr("en = 'Cannot write infobase user %1 because you specified an incorrect old password.'"),
					OldProperties.Name,
					OldProperties.UUID);
				Return False;
			EndIf;
		EndIf;
	EndIf;
	
	// Preparing new property values.
	NewProperties = CommonUseClientServer.CopyStructure(OldProperties);
	
	For Each KeyAndValue In NewProperties Do
		
		If PropertiesToUpdate.Property(KeyAndValue.Key)
		   And PropertiesToUpdate[KeyAndValue.Key] <> Undefined Then
		
			NewProperties[KeyAndValue.Key] = PropertiesToUpdate[KeyAndValue.Key];
		EndIf;
	EndDo;
	
	CopyInfobaseUserProperties(IBUser, NewProperties);
	
	If CommonUseCached.DataSeparationEnabled() Then
		IBUser.ShowInList = False;
	EndIf;
	
	// Attempting to write a new or modified infobase user.
	Try
		UsersInternal.WriteInfobaseUser(IBUser);
	Except
		ErrorDescription = ErrorDetailsOnWriteInfobaseUser(
			NStr("en = 'Cannot write user %1 to the infobase:
			           |
			           |%2.'"),
			IBUser.Name,
			?(PreliminaryRead, OldProperties.UUID, Undefined),
			ErrorInfo());
		Return False;
	EndTry;
	
	If ValueIsFilled(OldProperties.Name)
	   And OldProperties.Name <> NewProperties.Name Then
		// Copying settings.
		UsersInternal.CopyUserSettings(
			OldProperties.Name, NewProperties.Name, True);
	EndIf;
	
	UsersOverridable.OnWriteInfobaseUser(OldProperties, NewProperties);
	
	If CreateNew = Undefined Or CreateNew = True Then
		UsersInternal.SetInitialSettings(NewProperties.Name);
	EndIf;
	
	PropertiesToUpdate.Insert("UUID", IBUser.UUID);
	Return True;
	
EndFunction

// Deletes the specified infobase user.
//
// Parameters:
//  ID               - String - infobase user name.
//                   - UUID - infobase user UUID.
//
//  ErrorDescription - String - (return value) if user deletion is
//                     unsuccessful, contains the error details.
//
// Returns:
//  Boolean - if True, the user is deleted, otherwise see ErrorDescription.
//
Function DeleteInfobaseUser(Val ID,
                              ErrorDescription = "",
                              IBUser = Undefined) Export
	
	IBUser     = Undefined;
	Properties = Undefined;
	
	If Not ReadInfobaseUser(ID, Properties, ErrorDescription, IBUser) Then
		Return False;
	Else
		Try
			
			Handlers = CommonUse.InternalEventHandlers("StandardSubsystems.Users\BeforeWriteInfobaseUser");
			For Each Handler In Handlers Do
				Handler.Module.BeforeWriteInfobaseUser(IBUser.UUID);
			EndDo;
			
			IBUser.Delete();
			
		Except
			ErrorDescription = ErrorDetailsOnWriteInfobaseUser(
				NStr("en = 'Cannot delete infobase user %1:
				           |
				           |%2.'"),
				IBUser.Name,
				IBUser.UUID,
				ErrorInfo());
			Return False;
		EndTry;
	EndIf;
	
	UsersOverridable.AfterInfobaseUserDelete(Properties);
	
	Return True;
	
EndFunction

// Copies infobase user properties and performs conversion to/from string ID
// for the following properties: default interface, language, run mode, and roles.
// 
//  Properties that do not exist in the source or in the target are not copied.
// 
//  The Password and StoredPasswordValue properties are not copied if they
//  have Undefined values in the source.
// 
//  If Target type is InfobaseUser, the OSAuthentication,
//  StandardAuthentication, OpenIDAuthentication, and OSUser properties are
//  not copied if the values in the source and the target are equal.
// 
//  The UUID, PasswordIsSet, and OldPassword properties are not copied if
//  Target type is InfobaseUser.
// 
//  The conversion is performed if the Source type or the Target type is InfobaseUser.
// 
// Parameters:
//  Target             - Structure, InfobaseUser, FormDataCollection - 
//                       property subset returned by the 
//                       InfobaseUserDescription() function.
// 
//  Source             - Structure, InfobaseUser, FormDataCollection - same
//                       as Target, but types are reversed: when the
//                       Target type is structure, the Source type is not structure.
// 
//  CopiedProperties    - String - list of properties to copy, separated by
//                        commas (without a prefix).
//  PropertiesToExclude - String - list of properties that should not be
//                        copied (without a prefix), separated by commas.
//  PropertyPrefix      - String - initial name for Source or Target if its 
//                        type is NOT structure.
//
Procedure CopyInfobaseUserProperties(Target,
                                            Source,
                                            CopiedProperties = "",
                                            PropertiesToExclude = "",
                                            PropertyPrefix = "") Export
	
	AllProperties = NewInfobaseUserInfo();
	
	If ValueIsFilled(CopiedProperties) Then
		CopiedPropertiesStructure = New Structure(CopiedProperties);
	Else
		CopiedPropertiesStructure = AllProperties;
	EndIf;
	
	If ValueIsFilled(PropertiesToExclude) Then
		ExcludedPropertiesStructure = New Structure(PropertiesToExclude);
	Else
		ExcludedPropertiesStructure = New Structure;
	EndIf;
	
	If UsersInternal.IsTrainingPlatform() Then
		ExcludedPropertiesStructure.Insert("OSAuthentication");
		ExcludedPropertiesStructure.Insert("OSUser");
	EndIf;
	
	PasswordIsSet = False;
	
	For Each KeyAndValue In AllProperties Do
		Property = KeyAndValue.Key;
		
		If Not CopiedPropertiesStructure.Property(Property)
		 Or ExcludedPropertiesStructure.Property(Property) Then
		
			Continue;
		EndIf;
		
		If TypeOf(Source) = Type("InfobaseUser") Then
			
			If Property = "Password"
			 Or Property = "OldPassword" Then
				
				PropertyValue = Undefined;
				
			ElsIf Property = "DefaultInterface" Then
				PropertyValue = ?(Source.DefaultInterface = Undefined,
				                     "",
				                     Source.DefaultInterface.Name);
			
			ElsIf Property = "RunMode" Then
				ValueFullName = GetPredefinedValueFullName(Source.RunMode);
				PropertyValue = Mid(ValueFullName, Find(ValueFullName, ".") + 1);
				
			ElsIf Property = "Language" Then
				PropertyValue = ?(Source.Language = Undefined,
				                     "",
				                     Source.Language.Name);
				
			ElsIf Property = "Roles" Then
				
				TempStructure = New Structure("Roles", New ValueTable);
				FillPropertyValues(TempStructure, Target);
				If TypeOf(TempStructure.Roles) = Type("ValueTable") Then
					Continue;
				ElsIf TempStructure.Roles = Undefined Then
					Target.Roles = New Array;
				Else
					Target.Roles.Clear();
				EndIf;
				
				For Each Role In Source.Roles Do
					Target.Roles.Add(Role.Name);
				EndDo;
				
				Continue;
			Else
				PropertyValue = Source[Property];
			EndIf;
			
			PropertyFullName = PropertyPrefix + Property;
			TempStructure = New Structure(PropertyFullName, PropertyValue);
			FillPropertyValues(Target, TempStructure);
		Else
			If TypeOf(Source) = Type("Structure") Then
				If Source.Property(Property) Then
					PropertyValue = Source[Property];
				Else
					Continue;
				EndIf;
			Else
				PropertyFullName = PropertyPrefix + Property;
				TempStructure = New Structure(PropertyFullName, New ValueTable);
				FillPropertyValues(TempStructure, Source);
				PropertyValue = TempStructure[PropertyFullName];
				If TypeOf(PropertyValue) = Type("ValueTable") Then
					Continue;
				EndIf;
			EndIf;
			
			If TypeOf(Target) = Type("InfobaseUser") Then
			
				If Property = "UUID"
				 Or Property = "OldPassword"
				 Or Property = "PasswordIsSet" Then
					
					Continue;
					
				ElsIf Property = "OpenIDAuthentication"
				      Or Property = "StandardAuthentication"
				      Or Property = "OSAuthentication"
				      Or Property = "OSUser" Then
					
					If Target[Property] <> PropertyValue Then
						Target[Property] = PropertyValue;
					EndIf;
					
				ElsIf Property = "Password" Then
					If PropertyValue <> Undefined Then
						Target.Password = PropertyValue;
						PasswordIsSet = True;
					EndIf;
					
				ElsIf Property = "StoredPasswordValue" Then
					If PropertyValue <> Undefined
					   And Not PasswordIsSet Then
						Target.StoredPasswordValue = PropertyValue;
					EndIf;
					
				ElsIf Property = "DefaultInterface" Then
					If TypeOf(PropertyValue) = Type("String") Then
						Target.DefaultInterface = Metadata.Interfaces.Find(PropertyValue);
					Else
						Target.DefaultInterface = Undefined;
					EndIf;
				
				ElsIf Property = "RunMode" Then
					If PropertyValue = "Auto"
					 Or PropertyValue = "OrdinaryApplication"
					 Or PropertyValue = "ManagedApplication" Then
						
						Target.RunMode = ClientRunMode[PropertyValue];
					Else
						Target.RunMode = ClientRunMode.Auto;
					EndIf;
					
				ElsIf Property = "Language" Then
					If TypeOf(PropertyValue) = Type("String") Then
						Target.Language = Metadata.Languages.Find(PropertyValue);
					Else
						Target.Language = Undefined;
					EndIf;
					
				ElsIf Property = "Roles" Then
					Target.Roles.Clear();
					If PropertyValue <> Undefined Then
						For Each RoleName In PropertyValue Do
							Role = Metadata.Roles.Find(RoleName);
							If Role <> Undefined Then
								Target.Roles.Add(Role);
							EndIf;
						EndDo;
					EndIf;
				Else
					If Property = "Name"
					   And Target[Property] <> PropertyValue Then
					
						If StrLen(PropertyValue) > 64 Then
							Raise StringFunctionsClientServer.SubstituteParametersInString(
								NStr("en = 'Error writing infobase user. The user name (which is used for logging on to the infobase): %1 exceeds 64 characters.'"),
								PropertyValue);
							
						ElsIf Find(PropertyValue, ":") > 0 Then
							Raise StringFunctionsClientServer.SubstituteParametersInString(
								NStr("en = 'Error writing infobase user. The user name (which is used for logging on to the infobase): %1 contains an illegal character "":"".'"),
								PropertyValue);
						EndIf;
					EndIf;
					Target[Property] = Source[Property];
				EndIf;
			Else
				If Property = "Roles" Then
					
					TempStructure = New Structure("Roles", New ValueTable);
					FillPropertyValues(TempStructure, Target);
					If TypeOf(TempStructure.Roles) = Type("ValueTable") Then
						Continue;
					ElsIf TempStructure.Roles = Undefined Then
						Target.Roles = New Array;
					Else
						Target.Roles.Clear();
					EndIf;
					
					If Source.Roles <> Undefined Then
						For Each Role In Source.Roles Do
							Target.Roles.Add(Role.Name);
						EndDo;
					EndIf;
					Continue;
					
				ElsIf TypeOf(Source) = Type("Structure") Then
					PropertyFullName = PropertyPrefix + Property;
				Else
					PropertyFullName = Property;
				EndIf;
				TempStructure = New Structure(PropertyFullName, PropertyValue);
				FillPropertyValues(Target, TempStructure);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Returns an item of the Users catalog that is mapped to the specified
// infobase user.
//  Searching for the user requires administrative rights. If the current
//  user has no administrative rights, only searching for the Users catalog
//  item mapped to the current user is allowed.
// 
// Parameters:
//  NameLogon - String - infobase user name (which is used for logging on
//  to the infobase).
//
// Returns:
//  CatalogRef.Users          - if user is found.
//  Catalogs.Users.EmptyRef() - if infobase user is found.
//  Undefined                 - if infobase user is not found.
//
Function FindByName(Val NameLogon) Export
	
	IBUser = InfobaseUsers.FindByName(NameLogon);
	
	If IBUser = Undefined Then
		Return Undefined;
	Else
		FindAmbiguousInfobaseUsers(, IBUser.UUID);
		
		Return Catalogs.Users.FindByAttribute(
			"InfobaseUserID",
			IBUser.UUID);
	EndIf;
	
EndFunction

// Returns the role that grants administrative rights.
//
// Parameters:
//  ForCheck - Boolean - return the role used for checking (not for
//             setting).
//             For base versions, the role used for setting is
//             SystemAdministrator, while the role used for checking can be
//             FullAccess with the Administration right.
//
// Returns:
//  MetadataObject - Role.
//
Function FullAdministratorRole(ForCheck = False) Export
	
	FullAdministratorRole = Metadata.Roles.FullAdministrator;
	
	If ForCheck
	   And AccessRight("Administration", Metadata, Metadata.Roles.FullAccess)
	   And StandardSubsystemsServer.IsBaseConfigurationVersion() Then
	
		FullAdministratorRole = Metadata.Roles.FullAccess;
	EndIf;
	
	Return FullAdministratorRole;
	
EndFunction

// Searches for infobase user IDs that are used more than once and either
// raises an exception or returns the list of found infobase users.
//
// Parameters:
//  User         - Undefined - search in all users and external users.
//               - CatalogRef.Users, CatalogRef.ExternalUsers - search
//                 in the specified catalog only.
//
//  UUID          - Undefined - check all infobase user IDs.
//                - UUID - check the specified ID only.
//
//  FoundIDs      - Undefined - if errors are found, raise an exception.
//                - Map - if errors are found, fill the map passed to the procedure:
//                   * Key   - ambiguous infobase user ID.
//                   * Value - an array containing users and external users.
//
//  ServiceUserID - Boolean - if False, check InfobaseUserID, otherwise
//                  check SaaSUserID.
//
Procedure FindAmbiguousInfobaseUsers(Val User = Undefined,
                                            Val UUID = Undefined,
                                            Val FoundIDs = Undefined,
                                            Val ServiceUserID = False) Export
	
	SetPrivilegedMode(True);
	
	If TypeOf(UUID) <> Type("UUID") Then
		UUID =
			New UUID("00000000-0000-0000-0000-000000000000");
	EndIf;
	
	Query = New Query;
	Query.SetParameter("User", User);
	Query.SetParameter("UUID", UUID);
	
	Query.SetParameter("EmptyUUID",
		New UUID("00000000-0000-0000-0000-000000000000"));
	
	Query.Text =
	"SELECT
	|	UserIDs.InfobaseUserID AS AmbiguousID,
	|	UserIDs.User
	|FROM
	|	(SELECT
	|		Users.InfobaseUserID,
	|		Users.Ref AS User
	|	FROM
	|		Catalog.Users AS Users
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ExternalUsers.InfobaseUserID,
	|		ExternalUsers.Ref
	|	FROM
	|		Catalog.ExternalUsers AS ExternalUsers) AS UserIDs
	|WHERE
	|	UserIDs.InfobaseUserID IN
	|			(SELECT
	|				UserIDs.InfobaseUserID
	|			FROM
	|				(SELECT
	|					Users.InfobaseUserID,
	|					Users.Ref AS User
	|				FROM
	|					Catalog.Users AS Users
	|				WHERE
	|					Users.InfobaseUserID <> &EmptyUUID
	|					AND NOT(&User <> UNDEFINED
	|							AND Users.Ref <> &User)
	|					AND NOT(&UUID <> &EmptyUUID
	|							AND Users.InfobaseUserID <> &UUID)
	|		
	|				UNION ALL
	|		
	|				SELECT
	|					ExternalUsers.InfobaseUserID,
	|					ExternalUsers.Ref
	|				FROM
	|					Catalog.ExternalUsers AS ExternalUsers
	|				WHERE
	|					ExternalUsers.InfobaseUserID <> &EmptyUUID
	|					AND NOT(&User <> UNDEFINED
	|							AND ExternalUsers.Ref <> &User)
	|					AND NOT(&UUID <> &EmptyUUID
	|							AND ExternalUsers.InfobaseUserID <> &UUID)
	|				) AS UserIDs
	|			GROUP BY
	|						UserIDs.InfobaseUserID
	|			HAVING
	|				COUNT(UserIDs.User) > 1)
	|
	|ORDER BY
	|	UserIDs.InfobaseUserID";
	
	If ServiceUserID Then
		Query.Text = StrReplace(Query.Text,
			"InfobaseUserID",
			"ServiceUserID");
	EndIf;
	
	Data = Query.Execute().Unload();
	
	If Data.Count() = 0 Then
		Return;
	EndIf;
	
	ErrorDescription = NStr("en = 'Database error:'") + Chars.LF;
	CurrentAmbiguousID = Undefined;
	
	For Each Row In Data Do
		
		NewUUID = False;
		If Row.AmbiguousID <> CurrentAmbiguousID Then
			NewUUID = True;
			CurrentAmbiguousID = Row.AmbiguousID;
			If TypeOf(FoundIDs) = Type("Map") Then
				CurrentUsers = New Array;
				FoundIDs.Insert(CurrentAmbiguousID, CurrentUsers);
			Else
				CurrentInfobaseUser = InfobaseUsers.CurrentUser();
				
				If CurrentInfobaseUser.UUID <> CurrentAmbiguousID Then
					CurrentInfobaseUser =
						InfobaseUsers.FindByUUID(
							CurrentAmbiguousID);
				EndIf;
				
				If CurrentInfobaseUser = Undefined Then
					NameLogon = NStr("en = '<not found>'");
				Else
					NameLogon = CurrentInfobaseUser.Name;
				EndIf;
				
				ErrorDescription = ErrorDescription
					+ StringFunctionsClientServer.SubstituteParametersInString(
						?(ServiceUserID,
						NStr("en = 'Multiple items of the Users catalog match the SaaS user ID %2'"),
						NStr("en = 'Multiple items of the Users catalog match the infobase user %1 with ID %2'") ),
						NameLogon,
						CurrentAmbiguousID);
			EndIf;
		EndIf;
		
		If TypeOf(FoundIDs) = Type("Map") Then
			CurrentUsers.Add(Row.User);
		Else
			If NOT NewUUID Then
				ErrorDescription = ErrorDescription + ",";
			EndIf;
			ErrorDescription = ErrorDescription
				+ StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en = '
					           |	%1 with reference ID %2'"),
					Row.User,
					Row.User.UUID());
		EndIf;
	EndDo;
	
	If TypeOf(FoundIDs) <> Type("Map") Then
		ErrorDescription = ErrorDescription + "." + Chars.LF;
		Raise ErrorDescription;
	EndIf;
	
EndProcedure

// Returns the stored value of the password passed to the function.
//
// Parameters:
//  Password - String - password whose stored value is retrieved.
//
// Returns:
//  String - stored password value.
//
Function StoredPasswordStringValue(Val Password) Export
	
	Return UsersInternal.StoredStringPasswordValue(Password);
	
EndFunction

#EndRegion

#Region InternalProceduresAndFunctions

////////////////////////////////////////////////////////////////////////////////
// AUXILIARY PROCEDURES AND FUNCTIONS

// Generates a brief error description for displaying to users and also
// writes error details to the event log if WriteToLog is True.
//
// Parameters:
//  ErrorPattern   - Template that contains parameter %1 for infobase
//                   user presentation and parameter %2 for error details.
//
//  NameLogon      - Infobase user name for logging on to the application.
//
//  InfobaseUserID - Undefined, UUID.
//
//  ErrorInfo      - ErrorInfo.
//
//  WriteToLog     - Boolean. If True, error details are written to the 
//                   event log.
//
// Returns:
//  String - error details for displaying to users.
//
Function ErrorDetailsOnWriteInfobaseUser(ErrorPattern,
                                              NameLogon,
                                              InfobaseUserID,
                                              ErrorInfo = Undefined,
                                              WriteToLog = True)
	
	If WriteToLog Then
		WriteLogEvent(
			NStr("en = 'Users.Error writing infobase user'",
			     CommonUseClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,
			,
			,
			StringFunctionsClientServer.SubstituteParametersInString(
				ErrorPattern,
				"""" + NameLogon + """ ("
				+ ?(ValueIsFilled(InfobaseUserID),
					NStr("en = 'New user'"),
					String(InfobaseUserID))
				+ ")",
				?(ErrorInfo = Undefined,
				  "",
				  DetailErrorDescription(ErrorInfo))));
	EndIf;
	
	Return StringFunctionsClientServer.SubstituteParametersInString(
		ErrorPattern,
		"""" + NameLogon + """",
		?(ErrorInfo = Undefined,
		  "",
		  BriefErrorDescription(ErrorInfo)));
	
EndFunction

// For the InfobaseUserWithFullAccess() function and the RolesAvailable() function

Function CheckedInfobaseUserProperties(User)
	
	Properties = New Structure;
	Properties.Insert("CurrentInfobaseUser", InfobaseUsers.CurrentUser());
	Properties.Insert("IBUser", Undefined);
	
	If TypeOf(User) = Type("InfobaseUser") Then
		Properties.Insert("IBUser", User);
		
	ElsIf User = Undefined Or User = AuthorizedUser() Then
		Properties.Insert("IBUser", Properties.CurrentInfobaseUser);
	Else
		// User passed to the function is not the current user.
		If ValueIsFilled(User) Then
			Properties.Insert("IBUser", InfobaseUsers.FindByUUID(
				CommonUse.ObjectAttributeValue(User, "InfobaseUserID")));
		EndIf;
	EndIf;
	
	If Properties.IBUser <> Undefined Then
		Properties.Insert("IsCurrentInfobaseUser",
			Properties.IBUser.UUID
				= Properties.CurrentInfobaseUser.UUID);
	EndIf;
	
	Return Properties;
	
EndFunction

#EndRegion
