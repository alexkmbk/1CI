////////////////////////////////////////////////////////////////////////////////
// Users subsystem.
//
////////////////////////////////////////////////////////////////////////////////

#Region InternalProceduresAndFunctions

// Returns saved parameters used by the subsystem.
Function Parameters() Export
	
	SetPrivilegedMode(True);
	SavedParameters = StandardSubsystemsServer.ApplicationParameters(
		"UserSessionParameters");
	SetPrivilegedMode(False);
	
	StandardSubsystemsServer.CheckIfApplicationParametersUpdated(
		"UserSessionParameters",
		"InaccessibleRolesByUserTypes,
    |AllRoles");
	
	ParameterPresentation = "";
	
	If Not SavedParameters.Property("InaccessibleRolesByUserTypes") Then
		ParameterPresentation = NStr("en = 'Inaccessible roles'");
		
	ElsIf Not SavedParameters.Property("AllRoles") Then
		ParameterPresentation = NStr("en = 'All roles'");
		
	EndIf;
	
	If ValueIsFilled(ParameterPresentation) Then
		
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Infobase update error.
			           |The following parameter is not set:
			           |""%1"".'")
			+ StandardSubsystemsServer.ApplicationRunParameterErrorClarificationForDeveloper(),
			ParameterPresentation);
	EndIf;
	
	Return SavedParameters;
	
EndFunction

// Returns a tree of roles (with the option to group roles by subsystem).
//  If a role is not included in any subsystem, it is added to the root.
// 
// Parameters:
//  BySubsystems - Boolean if False all roles are added to the root.
// 
// Returns:
//  ValueTree with columns:
//    IsRole  - Boolean 
//    Name    - String - role or subsystem name 
//    Synonym - String - role or subsystem synonym
//
Function RoleTree(BySubsystems = True, Val UserType = Undefined) Export
	
	If UserType = Undefined Then
		UserType = ?(CommonUseCached.DataSeparationEnabled(), 
			Enums.UserTypes.DataAreaUser, 
			Enums.UserTypes.LocalApplicationUser);
	EndIf;
	
	Tree = New ValueTree;
	Tree.Columns.Add("IsRole",  New TypeDescription("Boolean"));
	Tree.Columns.Add("Name",    New TypeDescription("String"));
	Tree.Columns.Add("Synonym", New TypeDescription("String", , 
New StringQualifiers(1000)));
	
	If BySubsystems Then
		FillSubsystemsAndRoles(Tree.Rows, , UserType);
	EndIf;
	
	InaccessibleRoles = UsersInternal.InaccessibleRolesByUserType(UserType);
	
	// Adding roles that are not found
	For Each Role In Metadata.Roles Do
		
		If InaccessibleRoles.Get(Role.Name) <> Undefined
			OR Upper(Left(Role.Name, StrLen("Delete"))) = Upper("Delete") Then
			
			Continue;
		EndIf;
		
		If Tree.Rows.FindRows(New Structure("IsRole, Name", True, Role.Name), True).Count() = 0 Then
			TreeRow = Tree.Rows.Add();
			TreeRow.IsRole       = True;
			TreeRow.Name         = Role.Name;
			TreeRow.Synonym      = ?(ValueIsFilled(Role.Synonym), Role.Synonym, Role.Name);
		EndIf;
	EndDo;
	
	Tree.Rows.Sort("IsRole Desc, Synonym Asc", True);
	
	Return Tree;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Auxiliary procedures and functions

Procedure FillSubsystemsAndRoles(TreeRowCollection,
                                   Subsystems = Undefined,
                                   UserType)
	
	InaccessibleRoles = UsersInternal.InaccessibleRolesByUserType(UserType);
	
	If Subsystems = Undefined Then
		Subsystems = Metadata.Subsystems;
	EndIf;
	
	For Each Subsystem In Subsystems Do
		
		SubsystemDetails = TreeRowCollection.Add();
		SubsystemDetails.Name           = Subsystem.Name;
		SubsystemDetails.Synonym       = ?(ValueIsFilled(Subsystem.Synonym), Subsystem.Synonym, Subsystem.Name);
		
		FillSubsystemsAndRoles(SubsystemDetails.Rows, Subsystem.Subsystems, UserType);
		
		For Each Role In Metadata.Roles Do
			If InaccessibleRoles.Get(Role) <> Undefined
				OR Upper(Left(Role.Name, StrLen("Delete"))) = Upper("Delete") Then
				
				Continue;
			EndIf;
			
			If Subsystem.Content.Contains(Role) Then
				RoleDetails = SubsystemDetails.Rows.Add();
				RoleDetails.IsRole       = True;
				RoleDetails.Name         = Role.Name;
				RoleDetails.Synonym      = ?(ValueIsFilled(Role.Synonym), Role.Synonym, Role.Name);
			EndIf;
		EndDo;
		
		If SubsystemDetails.Rows.FindRows(New Structure("IsRole", True), True).Count() = 0 Then
			TreeRowCollection.Delete(SubsystemDetails);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion
