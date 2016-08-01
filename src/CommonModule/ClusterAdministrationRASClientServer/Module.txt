////////////////////////////////////////////////////////////////////////////////

// Base functionality subsystem.
// Common client and server procedures and function for working with:
// - server cluster administration through the administration server.
//
/////////////////////////////////////////////////////////////////////////////////
 
#If Not WebClient Then

#Region InternalInterface

#Region SessionAndJobLock

// Returns the current state of the infobase session and scheduled job lock.
//
// Parameters:
// ClusterAdministrationParameters  - Structure - describes the parameters for connecting the
//                                    server cluster, for details, see
//                                    ClusterAdministrationClientServer.ClusterAdministrationParameters(),
// InfobaseAdministrationParameters - Structure - describes the parameters for connecting the
//                                    infobase, for details, see
//                                    ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters().
//
// Returns: Structure - describes the states of the session and background job lock, for
//          details, see ClusterAdministrationClientServer.SessionAndScheduleJobLockProperties().
//
Function InfobaseSessionAndJobLock(Val ClusterAdministrationParameters, Val  InfobaseAdministrationParameters) Export
	
	Return InfobaseProperties(ClusterAdministrationParameters, InfobaseAdministrationParameters,  SessionAndScheduledJobLockPropertyDictionary());
	
EndFunction
 
// Sets the state of the infobase session and scheduled job lock.
//
// Parameters:
// ClusterAdministrationParameters  - Structure - describes the parameters for connecting the
//                                    server cluster, for details, see
//                                    ClusterAdministrationClientServer.ClusterAdministrationParameters(),
// InfobaseAdministrationParameters - Structure - describes the parameters for connecting the
//                                    infobase, for details, see
//                                    ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters(),
// SessionAndJobLockProperties      - Structure - describes the states of the session and
//                                    background job lock, for details, see
//                                    ClusterAdministrationClientServer.SessionAndScheduleJobLockProperties().
//
Procedure  SetInfobaseSessionAndJobLock(Val ClusterAdministrationParameters, Val InfobaseAdministrationParameters, Val SessionAndJobLockProperties) Export
	
	SetInfobaseProperties(
		ClusterAdministrationParameters,
		InfobaseAdministrationParameters,
		SessionAndScheduledJobLockPropertyDictionary(),
		SessionAndJobLockProperties);
	
EndProcedure
 
// Checks whether administration parameters are filled correctly.
//
// Parameters:
// ClusterAdministrationParameters       - Structure - describes the parameters for connecting 
//                                         the server cluster, for details, see
//                                         ClusterAdministrationClientServer.ClusterAdministrationParameters(),
// InfobaseAdministrationParameters      - Structure - describes the parameters for connecting 
//                                         the infobase, for details,
//                                         ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters().
//                                         The parameters can be skipped if the corresponding 
//                                         fields are specified in the structure passed as the
//                                         SessionAndJobLockProperties parameter value, 
// CheckClusterAdministrationParameters  - Boolean - flag that shows whether the cluster
//                                         administration parameters must be checked,
// CheckInfobaseAdministrationParameters - Boolean - flag that shows whether the cluster
//                                         administration parameters must be checked.
//
Procedure CheckAdministrationParameters(Val ClusterAdministrationParameters, Val InfobaseAdministrationParameters  = Undefined,
	CheckInfobaseAdministrationParameters = True,
	CheckClusterAdministrationParameters = True) Export
	
	
	If CheckClusterAdministrationParameters  Or  CheckInfobaseAdministrationParameters Then
		
		ClusterID = GetCluster(ClusterAdministrationParameters);
		WorkingProcesses = GetWorkingProcesses(ClusterID,  ClusterAdministrationParameters);
		
	EndIf;
	
	If  CheckInfobaseAdministrationParameters Then
		
		Dictionary = New  Structure();
		Dictionary.Insert("SessionsLock", "sessions-deny");
		
		a = InfobaseProperties(ClusterAdministrationParameters,  InfobaseAdministrationParameters, Dictionary);
		
	EndIf;
	
EndProcedure

#EndRegion
 
#Region ScheduledJobLock

// Returns the current state of infobase scheduled job lock.
//
// Parameters:
// ClusterAdministrationParameters  - Structure - describes the parameters for connecting the
//                                    server cluster, for details, see
//                                    ClusterAdministrationClientServer.ClusterAdministrationParameters(),
// InfobaseAdministrationParameters - Structure - describes the parameters for connecting the
//                                    infobase, for details, see
//                                    ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters().
//
// Returns: Boolean.
//
Function InfobaseScheduledJobLock(Val ClusterAdministrationParameters, Val  InfobaseAdministrationParameters) Export
	
	Dictionary = New Structure("JobLock", "scheduled-jobs-deny");
	
	InfobaseProperties = InfobaseProperties(ClusterAdministrationParameters,  InfobaseAdministrationParameters, Dictionary);
	Return InfobaseProperties.JobLock;
	
EndFunction
 
// Sets the state of the infobase scheduled job lock.
//
// Parameters:
// ClusterAdministrationParameters  - Structure - describes the parameters for connecting the
//                                    server cluster, for details, see
//                                    ClusterAdministrationClientServer.ClusterAdministrationParameters(),
// InfobaseAdministrationParameters - Structure - describes the parameters for connecting the
//                                    infobase, for details, see
//                                    ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters(),
// ScheduledJobLock                 - Boolean - flag that shows whether infobase scheduled jobs
//                                    are locked.
//
Procedure LockInfobaseScheduledJobs(Val ClusterAdministrationParameters, Val InfobaseAdministrationParameters, Val ScheduledJobLock) Export
	
	Dictionary = New Structure("JobLock", "scheduled-jobs-deny");
	Properties = New Structure("JobLock", ScheduledJobLock);
	
	SetInfobaseProperties(
		ClusterAdministrationParameters,
		InfobaseAdministrationParameters,
		Dictionary,
		Properties);
	
EndProcedure

#EndRegion
 
#Region InfobaseSessions

// Returns descriptions of infobase sessions.
//
// Parameters:
//  ClusterAdministrationParameters  - Structure - describes the parameters for connecting the server cluster,
//                                     for details, see
//                                     ClusterAdministrationClientServer.ClusterAdministrationParameters(),
//  InfobaseAdministrationParameters - Structure - describes the parameters for connecting the infobase, for
//                                     details, see
//                                     ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters(),
//  Filter                           - details on the session filtering conditions whose descriptions are
//                                     required. The follow options are available:
//                                     1. Array of structures that describe session filtering conditions.
//                                        Fields of structures in the array are:
//                                         Property       - String - property name to be used in the filter.
//                                                          For valid values see the return value of the
//                                                          ClusterAdministrationClientServer.SessionProperties()
//                                                          function,
//                                         ComparisonType - value of the ComparisonType system enumeration.
//                                                          The value comparison type with the specified
//                                                          filter condition. The valid values are:
//                                                           ComparisonType.Equal,
//                                                           ComparisonType.NotEqual,
//                                                           ComparisonType.Greater (for numeric values only),
//                                                           ComparisonType.GreaterOrEqual (for numeric values only),
//                                                           ComparisonType.Less (for numeric values only),
//                                                           ComparisonType.LessOrEqual (for numeric values only),
//                                                           ComparisonType.InList,
//                                                           ComparisonType.NotInList,
//                                                           ComparisonType.Interval (for numeric values only),
//                                                           ComparisonType.IntervalIncludingBounds (for numeric values only),
//                                                           ComparisonType.IntervalIncludingLowerBound (for numeric values only),
//                                                           ComparisonType.IntervalIncludingUpperBound (for numeric values only),
//                                         Value          - Number, String, Date, Boolean, ValueList, Array,
//                                                          Structure - value, against which the corresponding
//                                                                      session properties are compared. If
//                                                                      ComparisonType.InList or
//                                                                      ComparisonType.NotInList,
//                                                                      pass ValueList or Array with a set of
//                                                                      values against which the property is
//                                                                      compared. In case of
//                                                                      ComparisonType.Interval,
//                                                                      ComparisonType.IntervalIncludingBounds,
//                                                                      ComparisonType.IntervalIncludingLowerBound,
//                                                                      or IntervalIncludingUpperBound, pass a
//                                                                      structure with the From and To fields
//                                                                      whose values are interval against
//                                                                      which the value is compared,
//                                      2. Structure (simplified), where key is a session property name (see
//                                         above), value is a value, against which comparison is executed.
//                                         When you use this description option, the comparison filter always
//                                         checks for equality.
//
// Returns: Array of Structure - describes session properties. For structure details see
//          ClusterAdministrationClientServer.SessionProperties().
//
Function InfobaseSessions(Val ClusterAdministrationParameters, Val InfobaseAdministrationParameters, Val Filter = Undefined) Export
	
	ClusterID = GetCluster(ClusterAdministrationParameters);
	InfobaseID = GetInfobase(ClusterID, ClusterAdministrationParameters,  InfobaseAdministrationParameters);
	Return GetSessions(ClusterID, ClusterAdministrationParameters,  InfobaseID, Filter);
	
EndFunction
 
// Terminates infobase sessions by filter.
//
// Parameters:
//  ClusterAdministrationParameters  - Structure - describes the parameters for connecting the server cluster, for
//                                     details, see ClusterAdministrationClientServer.ClusterAdministrationParameters(),
//  InfobaseAdministrationParameters - Structure - describes the parameters for connecting the infobase, for
//                                     details, see
//                                     ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters(),
//  Filter                           - filtering condition details of sessions to be terminated.
//                                     The following options are available:
//                                      1. Array of structures that describe session filtering conditions. Fields of
//                                         structures in the array are:
//                                          Property       - String - property name to be used in the filter. For valid
//                                                           values see the return value of the
//                                                           ClusterAdministrationClientServer.SessionProperties()
//                                                           function,
//                                          ComparisonType - value of the ComparisonType system enumeration. The value
//                                                           comparison type with the specified filter condition. Valid
//                                                           values are:
//                                                            ComparisonType.Equal,
//                                                            ComparisonType.NotEqual,
//                                                            ComparisonType.Greater (for numeric values only),
//                                                            ComparisonType.GreaterOrEqual (for numeric values only),
//                                                            ComparisonType.Less (for numeric values only),
//                                                            ComparisonType.LessOrEqual (for numeric values only),
//                                                            ComparisonType.InList,
//                                                            ComparisonType.NotInList,
//                                                            ComparisonType.Interval (for numeric values only),
//                                                            ComparisonType.IntervalIncludingBounds (for numeric values only),
//                                                            ComparisonType.IntervalIncludingLowerBound (for numeric values only),
//                                                            ComparisonType.IntervalIncludingUpperBound (for numeric values only),
//                                          Value          - Number, String, Date, Boolean, ValueList, Array,
//                                                           Structure - value, against which the corresponding
//                                                           session properties are compared. If ComparisonType.InList
//                                                           or ComparisonType.NotInList, pass ValueList or Array with
//                                                           a set of values against which the property is compared.
//                                                           In case of ComparisonType.Interval,
//                                                           ComparisonType.IntervalIncludingBounds,
//                                                           ComparisonType.IntervalIncludingLowerBound, or
//                                                           IntervalIncludingUpperBound, pass a structure with the
//                                                           From and To fields whose values are interval against which
//                                                           the value is compared,
//                                      2. Structure (simplified), where key is a session property name (see above),
//                                         value is a value, against which comparison is executed.  When you use this
//                                         description option, the comparison filter always checks for equality.
//
Procedure DeleteInfobaseSessions(Val ClusterAdministrationParameters, Val InfobaseAdministrationParameters, Val Filter = Undefined) Export
	
	Pattern = "%rac session --cluster=%cluster% --cluster-user=%?cluster-user% --cluster-pwd=%?cluster-pwd% terminate --session=%session%";
	
	Parameters = New Map();
	
	ClusterID = GetCluster(ClusterAdministrationParameters);
	Parameters.Insert("cluster", ClusterID);
	FillParametersForAuthenticationInCluster(ClusterAdministrationParameters, Parameters);
	
	InfobaseID = GetInfobase(ClusterID, ClusterAdministrationParameters,  InfobaseAdministrationParameters);
	
	Sessions = GetSessions(ClusterID, ClusterAdministrationParameters, InfobaseID, Filter, False);
	For Each Session In Sessions Do
		
		Try
			
			Parameters.Insert("session", Session.Get("session"));
			ExecuteCommand(Pattern, ClusterAdministrationParameters,  Parameters);
			
		Except
			
			// The session could already be closed when "rac session terminate" is called
			
			SessionFilter = New Structure();
			SessionFilter.Insert("Number", Session.Get("session-id"));
			
			If GetSessions(ClusterID,  ClusterAdministrationParameters,  InfobaseAdministrationParameters, SessionFilter, True).Count() > 0 Then
				Raise;
			Else
				Continue;
			EndIf;
			
		EndTry;
		
	EndDo;
	
EndProcedure

#EndRegion
 
#Region InfobaseConnection

// Returns infobase connection descriptions.
//
// Parameters:
//  ClusterAdministrationParameters  - Structure - describes the parameters for connecting the server cluster, for
//                                     details see ClusterAdministrationClientServer.ClusterAdministrationParameters(),
//  InfobaseAdministrationParameters - Structure - describes the parameters for connecting the infobase, for details,
//                                     see ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters(),
//  Filter                           - details on the connection filtering conditions whose descriptions are required.
//                                     The following options are:
//                                      1. Array of structures that describes connection filtering conditions. Fields
//                                        of structures in the array are:
//                                         Property       - String - property name to be used in the filter. Valid
//                                                          values are the return value of the
//                                                          ClusterAdministrationClientServer.ConnectionProperties()
//                                                          function,
//                                         ComparisonType - value of the ComparisonType system enumeration. The value
//                                                          comparison type with the specified filter condition. Valid
//                                                          values are:
//                                                           ComparisonType.Equal,
//                                                           ComparisonType.NotEqual,
//                                                           ComparisonType.Greater (for numeric values only),
//                                                           ComparisonType.GreaterOrEqual (for numeric values only),
//                                                           ComparisonType.Less (for numeric values only),
//                                                           ComparisonType.LessOrEqual (for numeric values only),
//                                                           ComparisonType.InList,
//                                                           ComparisonType.NotInList,
//                                                           ComparisonType.Interval (for numeric values only),
//                                                           ComparisonType.IntervalIncludingBounds (for numeric values only),
//                                                           ComparisonType.IntervalIncludingLowerBound (for numeric values only),
//                                                           ComparisonType.IntervalIncludingUpperBound (for numeric values only),
//                                         Value - Number, String, Date, Boolean, ValueList, Array, Structure - value
//                                                 against which the corresponding connection property value is
//                                                 compared. If ComparisonType.InList or
//                                                 ComparisonType.NotInList, pass ValueList or Array with a set of
//                                                 values against which the property is compared. In case of
//                                                 ComparisonType.Interval, ComparisonType.IntervalIncludingBounds,
//                                                 ComparisonType.IntervalIncludingLowerBound, or
//                                                 IntervalIncludingUpperBound, pass a structure with the From and To
//                                                 fields whose values are interval against which the value is 
//                                                 compared,
//                                      2. Structure (simplified), where key is a name of the connection property
//                                         (see above), value is a value, against which comparison is executed. When
//                                         you use this description option, the comparison filter always checks for
//                                         equality.
//
// Returns: Array of Structure - describes connection properties. For structure details see
//          ClusterAdministrationClientServer.ConnectionProperties().
//
Function InfobaseConnection(Val ClusterAdministrationParameters, Val InfobaseAdministrationParameters, Val Filter = Undefined) Export
	
	ClusterID = GetCluster(ClusterAdministrationParameters);
	InfobaseID = GetInfobase(ClusterID, ClusterAdministrationParameters,  InfobaseAdministrationParameters);
	Return GetConnections(ClusterID, ClusterAdministrationParameters, InfobaseID,  InfobaseAdministrationParameters, Filter, True);
	
EndFunction
 
// Terminates the infobase connection by filter.
//
// Parameters:
//  ClusterAdministrationParameters  - Structure - describes the parameters for connecting the server cluster, for
//                                     details, see ClusterAdministrationClientServer.ClusterAdministrationParameters(),
//  InfobaseAdministrationParameters - Structure - describes the parameters for connecting the infobase, for details,
//                                     see ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters(),
//  Filter                           - details on the filtering conditions for connections to be terminated.
//                                     The following options are available:
//                                      1. Array of structures that describe filtering conditions for the connections to
//                                         be terminated. Fields of structures in the array are:
//                                          Property       - String - property name to be used in the filter. Valid
//                                                           values are the return value of the
//                                                           ClusterAdministrationClientServer.ConnectionProperties()
//                                                           function,
//                                          ComparisonType - value of the ComparisonType system enumeration. The value
//                                                           comparison type with the specified filter condition. Valid
//                                                           values are:
//                                                            ComparisonType.Equal,
//                                                            ComparisonType.NotEqual,
//                                                            ComparisonType.Greater (for numeric values only),
//                                                            ComparisonType.GreaterOrEqual (for numeric values only),
//                                                            ComparisonType.Less (for numeric values only),
//                                                            ComparisonType.LessOrEqual (for numeric values only),
//                                                            ComparisonType.InList,
//                                                            ComparisonType.NotInList,
//                                                            ComparisonType.Interval (for numeric values only),
//                                                            ComparisonType.IntervalIncludingBounds (for numeric values only),
//                                                            ComparisonType.IntervalIncludingLowerBound (for numeric values only),
//                                                            ComparisonType.IntervalIncludingUpperBound (for numeric values only),
//                                          Value - Number, String, Date, Boolean, ValueList, Array, Structure - value
//                                                  against which the corresponding connection property value is
//                                                  compared. If ComparisonType.InList or ComparisonType.NotInList, pass
//                                                  ValueList or Array with a set of values against which the property
//                                                  is compared. In case of ComparisonType.Interval,
//                                                  ComparisonType.IntervalIncludingBounds,
//                                                  ComparisonType.IntervalIncludingLowerBound, or
//                                                  IntervalIncludingUpperBound, pass a structure with the From and To
//                                                  fields whose values are interval against which the value is
//                                                  compared,
//                                      2. Structure (simplified), where key is a name of the connection property (see
//                                         above), value is a value, against which comparison is executed.  When you use
//                                         this description option, the comparison filter always checks for equality.
//
Procedure  TerminateInfobaseConnection(Val ClusterAdministrationParameters, Val  InfobaseAdministrationParameters, Val Filter = Undefined) Export
	
	Pattern = "%rac connection --cluster=%cluster% --cluster-user=%?cluster-user% --cluster-pwd=%?cluster-pwd% disconnect --process=%process% --connection=%connection% --infobase-user=%?infobase-user% --infobase-pwd=%?infobase-pwd%";
	
	Parameters = New Structure;
	
	Parameters = New Map();
	
	ClusterID = GetCluster(ClusterAdministrationParameters);
	Parameters.Insert("cluster", ClusterID);
	FillParametersForAuthenticationInCluster(ClusterAdministrationParameters, Parameters);
	
	InfobaseID = GetInfobase(ClusterID, ClusterAdministrationParameters,  InfobaseAdministrationParameters);
	Parameters.Insert("infobase", InfobaseID);
	FillAuthenticationParametersInIB(InfobaseAdministrationParameters, Parameters);
	
	Connections = GetConnections(ClusterID, ClusterAdministrationParameters, InfobaseID,  InfobaseAdministrationParameters, Filter, False);
	For Each Connection In Connections Do
		
		Try
			
			Parameters.Insert("process", Connection.Get("process"));
			Parameters.Insert("connection", Connection.Get("connection"));
			ExecuteCommand(Pattern, ClusterAdministrationParameters, Parameters);
			
		Except
			
			// The session could already be closed when "rac connection disconnect" is called
			
			ConnectionFilter = New Structure();
			ConnectionFilter.Insert("Number",  Connection.Get("conn-id"));
			
			ConnectionDescriptions = GetConnections(
				ClusterID,
				ClusterAdministrationParameters,
				InfobaseID,
				InfobaseAdministrationParameters,
				ConnectionFilter,
				True);
			
			If ConnectionDescriptions.Count() > 0 Then
				Raise;
			Else
				Continue;
			EndIf;
			
		EndTry;
		
	EndDo;
	
EndProcedure

#EndRegion
 
#Region SecurityProfiles

// Returns the name of the infobase security profile.
//
// Parameters:
// ClusterAdministrationParameters  - Structure - describes the parameters for connecting the
//                                    server cluster, for details, see
//                                    ClusterAdministrationClientServer.ClusterAdministrationParameters(),
// InfobaseAdministrationParameters - Structure - describes the parameters for connecting the
//                                    infobase, for details, see
//                                    ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters().
//
// Returns: String - name of the security profile set for the infobase. If no security profile
//          set for the infobase an empty string is returned.
//
Function InfobaseSecurityProfile(Val ClusterAdministrationParameters, Val  InfobaseAdministrationParameters) Export
	
	Dictionary = New  Structure();
	Dictionary.Insert("ProfileName", "security-profile-name");
	
	Result = InfobaseProperties(ClusterAdministrationParameters,  InfobaseAdministrationParameters, Dictionary).ProfileName;
	If ValueIsFilled(Result) Then
		Return Result;
	Else
		Return "";
	EndIf;
	
EndFunction
 
// Returns the name of the security profile that was set as the infobase safe mode security
// profile.
//
// Parameters: 
//  ClusterAdministrationParameters - Structure - describes the parameters for connecting the
//                                    server cluster, for details, see
//                                    ClusterAdministrationClientServer.ClusterAdministrationParameters(),
// InfobaseAdministrationParameters - Structure - describes the parameters for connecting the
//                                    infobase, for details, see
//                                    ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters().
//
// Returns: String - name of the security profile set for the infobase as the safe mode
//          security profile. If no security profile set for the infobase, an empty string is
//          returned.
//
Function InfobaseSafeModeSecurityProfile(Val  ClusterAdministrationParameters, Val InfobaseAdministrationParameters)  Export
	
	Dictionary = New  Structure();
	Dictionary.Insert("ProfileName", "safe-mode-security-profile-name");
	
	Result = InfobaseProperties(ClusterAdministrationParameters,  InfobaseAdministrationParameters, Dictionary).ProfileName;
	If ValueIsFilled(Result) Then
		Return Result;
	Else
		Return "";
	EndIf;
	
EndFunction
 
// Sets the security profile for the infobase.
//
// Parameters:
//  ClusterAdministrationParameters  - Structure - describes the parameters for connecting the
//                                     server cluster, for details, see
//                                     ClusterAdministrationClientServer.ClusterAdministrationParameters(),
//  InfobaseAdministrationParameters - Structure - describes the parameters for connecting the
//                                     infobase, for details, see
//                                     ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters(),
//  ProfileName                      - String - name of the security profile. If an empty 
//                                     string is passed, the security profile is disabled for 
//                                     the infobase.
//
Procedure SetInfobaseSecurityProfile(Val ClusterAdministrationParameters, Val  InfobaseAdministrationParameters, Val ProfileName = "") Export
	
	Dictionary = New  Structure();
	Dictionary.Insert("ProfileName", "security-profile-name");
	
	Values = New  Structure();
	Values.Insert("ProfileName", ProfileName);
	
	SetInfobaseProperties(
		ClusterAdministrationParameters,
		InfobaseAdministrationParameters,
		Dictionary,
		Values);
	
EndProcedure
 
// Sets the safe mode security profile for the infobase.
//
// Parameters:
//  ClusterAdministrationParameters  - Structure - describes the parameters for connecting the
//                                     server cluster, for details, see
//                                     ClusterAdministrationClientServer.ClusterAdministrationParameters(),
//  InfobaseAdministrationParameters - Structure - describes the parameters for connecting the
//                                     infobase, for details, see
//                                     ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters(),
//  ProfileName                      - String - name of the security profile. If an empty
//                                     string is passed, the safe mode security profile is
//                                     disabled for the infobase.
//
Procedure SetInfobaseSafeModeSecurityProfile(Val  ClusterAdministrationParameters, Val InfobaseAdministrationParameters,  Val ProfileName = "") Export
	
	Dictionary = New  Structure();
	Dictionary.Insert("ProfileName", "safe-mode-security-profile-name");
	
	Values = New  Structure();
	Values.Insert("ProfileName", ProfileName);
	
	SetInfobaseProperties(
		ClusterAdministrationParameters,
		InfobaseAdministrationParameters,
		Dictionary,
		Values);

EndProcedure
 
// Checks whether the security profile exists in the server cluster.
//
// Parameters:
//  ClusterAdministrationParameters - Structure - describes the parameters for connecting
//                                    the server cluster, for details, see
//                                    ClusterAdministrationClientServer.ClusterAdministrationParameters(),
//  ProfileName                     - String - name of the security profile whose existence
//                                    is checked.
//
Function SecurityProfileExists(Val ClusterAdministrationParameters, Val ProfileName) Export
	
	Filter = New  Structure("Name", ProfileName);
	
	ClusterID = GetCluster(ClusterAdministrationParameters);
	
	SecurityProfiles =  GetSecurityProfiles(ClusterID, ClusterAdministrationParameters,  Filter);
	
	Return (SecurityProfiles.Count() = 1);
	
EndFunction
 
// Returns security profile properties.
//
// Parameters:
// ClusterAdministrationParameters - Structure - describes the parameters for connecting the server cluster, for details, see - cm. ClusterAdministrationClientServer.ClusterAdministrationParameters(),
// ProfileName - String - name of the security profile.
//
// Returns: Structure - describes the security profile, for details see - cm.
// ClusterAdministrationClientServer.SecurityProfileProperties().
//
Function SecurityProfile(Val ClusterAdministrationParameters, Val ProfileName) Export
	
	Filter = New Structure("Name", ProfileName);
	
	ClusterID = GetCluster(ClusterAdministrationParameters);
	
	SecurityProfiles = GetSecurityProfiles(ClusterID, ClusterAdministrationParameters,  Filter);
	
	If SecurityProfiles.Count() <> 1 Then
		Raise  StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'The %2 security profile is not registered in the %1 server cluster.'"),  ClusterID, ProfileName);
	EndIf;
	
	Result = SecurityProfiles[0];
	Result = ConvertAccessListUsagePropertyValues(Result);
	
	// Virtual directories
	Result.Insert("VirtualDirectories",
		GetVirtualDirectories(ClusterID, ClusterAdministrationParameters, ProfileName));
	
	// Allowed COM classes
	Result.Insert("COMClasses",
		GetAllowedCOMClasses(ClusterID, ClusterAdministrationParameters, ProfileName));
	
	// Add-ins
	Result.Insert("AddIns",
		GetAllowedAddIns(ClusterID, ClusterAdministrationParameters, ProfileName));
	
	// External modules
	Result.Insert("ExternalModules",
		GetAllowedExternalModules(ClusterID, ClusterAdministrationParameters, ProfileName));
	
	// OS applications
	Result.Insert("OSApplications",
		GetAllowedOSApplications(ClusterID, ClusterAdministrationParameters, ProfileName));
	
	// Internet resources
	Result.Insert("InternetResources",
		GetAllowedInternetResources(ClusterID, ClusterAdministrationParameters, ProfileName));
	
	Return Result;
	
EndFunction
 
// Creates a security profile by the passed description.
//
// Parameters:
//  ClusterAdministrationParameters - Structure - describes the parameters for connecting the
//                                    server cluster, for details see
//                                    ClusterAdministrationClientServer.ClusterAdministrationParameters(),
//  SecurityProfileProperties       - Structure - describes properties of a security profile
//                                    to be generated, for details see
//                                    ClusterAdministrationClientServer.SecurityProfileProperties().
//
Procedure CreateSecurityProfile(Val ClusterAdministrationParameters, Val SecurityProfileProperties) Export
	
	ProfileName = SecurityProfileProperties.Name;
	
	Filter = New Structure("Name", ProfileName);
	
	ClusterID = GetCluster(ClusterAdministrationParameters);
	
	SecurityProfiles = GetSecurityProfiles(ClusterID, ClusterAdministrationParameters, Filter);
	
	If SecurityProfiles.Count() = 1 Then
		Raise  StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'The %2 security profile has already been registered in the %1 server cluster.'"), ClusterID, ProfileName);
	EndIf;
	
	UpdateSecurityProfileProperties(ClusterAdministrationParameters, SecurityProfileProperties, False);
	
EndProcedure
 
// Sets properties of the existing security profile by the passed description.
//
// Parameters:
//  ClusterAdministrationParameters - Structure - describes the parameters for connecting the
//                                    server cluster, for details see
//                                    ClusterAdministrationClientServer.ClusterAdministrationParameters(),
//  SecurityProfileProperties       - Structure - describes properties of security profile
//                                    properties to be set, for details see
//                                    ClusterAdministrationClientServer.SecurityProfileProperties().
//
Procedure SetSecurityProfileProperties(Val ClusterAdministrationParameters, Val SecurityProfileProperties) Export
	
	ProfileName = SecurityProfileProperties.Name;
	
	Filter = New Structure("Name", ProfileName);
	
	ClusterID = GetCluster(ClusterAdministrationParameters);
	
	SecurityProfiles = GetSecurityProfiles(ClusterID, ClusterAdministrationParameters,  Filter);
	
	If SecurityProfiles.Count() <> 1 Then
		Raise  StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'The %2 security profile is not registered in the %1 server cluster.'"), ClusterID, ProfileName);
	EndIf;
	
	UpdateSecurityProfileProperties(ClusterAdministrationParameters, SecurityProfileProperties, True);
	
EndProcedure
 
// Deletes the security profile.
//
// Parameters:
//  ClusterAdministrationParameters - Structure - describes the parameters for connecting the
//                                    server cluster, for details see
//                                    ClusterAdministrationClientServer.ClusterAdministrationParameters(),
//  ProfileName                     - String - name of the security profile.
//
Procedure DeleteSecurityProfile(Val ClusterAdministrationParameters, Val ProfileName) Export
	
	Pattern = "%rac profile --cluster=%cluster% --cluster-user=%?cluster-user% --cluster-pwd=%?cluster-pwd% remove --name=%name%";
	
	ClusterID = GetCluster(ClusterAdministrationParameters);
	
	Parameters = New Map();
	
	Parameters.Insert("cluster", ClusterID);
	FillParametersForAuthenticationInCluster(ClusterAdministrationParameters, Parameters);
	Parameters.Insert("name", ProfileName);
	
	ExecuteCommand(Pattern, ClusterAdministrationParameters, Parameters);
	
EndProcedure

#EndRegion

#EndRegion
 
#Region InternalProceduresAndFunctions

// Returns server cluster descriptions.

//
// ClusterAdministrationParameters - Structure - describes the parameters for connecting the
//                                   server cluster, for details, see
//                                   ClusterAdministrationClientServer.ClusterAdministrationParameters().
// Filter                          - Structure - server cluster filter parameter.
//
// Returns: Array of Structure.
//
Function GetClusters(Val ClusterAdministrationParameters, Val Filter = Undefined)
	
	Pattern = "%rac cluster list";
	OutputThread = ExecuteCommand(Pattern, ClusterAdministrationParameters);
	Result = OutputParser(OutputThread, Undefined, Filter);
	Return Result;
	
EndFunction
 
// Returns internal cluster id servers.
//
// Parameters:
// ClusterAdministrationParameters - Structure - describes the parameters for connecting the
//                                   server cluster, for details, see
//                                   ClusterAdministrationClientServer.ClusterAdministrationParameters().
//
// Returns -  String - internal server cluster ID.
//
Function GetCluster(Val ClusterAdministrationParameters)
	
	Filter = New Structure("port", ClusterAdministrationParameters.ClusterPort);
	
	Clusters = GetClusters(ClusterAdministrationParameters,  Filter);
	
	If Clusters.Count() = 1 Then
		Return Clusters[0].Get("cluster");
	Else
		Raise  StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Server cluster with % port is not found'"),  ClusterAdministrationParameters.ClusterPort);
	EndIf;
	
EndFunction
 
// Returns descriptions of working server.
//
// Parameters:
// ClusterID                       - String - internal server cluster ID.
// ClusterAdministrationParameters - Structure - describes the parameters for connecting the
//                                   server cluster, for details, see
//                                   ClusterAdministrationClientServer.ClusterAdministrationParameters().
// Filter                          - Structure - parameters of working server filter.
//
// Returns: Array of Structure.
//
Function GetServerNames(Val ClusterID, Val  ClusterAdministrationParameters, Filter = Undefined)
	
	Pattern = "%rac server --cluster=%cluster% --cluster-user=%?cluster-user% --cluster-pwd=%?cluster-pwd% list";
	
	Parameters = New Map();
	
	Parameters.Insert("cluster",  ClusterID);
	FillParametersForAuthenticationInCluster(ClusterAdministrationParameters,  Parameters);
	
	OutputThread = ExecuteCommand(Pattern, ClusterAdministrationParameters, Parameters);
	Result = OutputParser(OutputThread, Undefined, Filter);
	Return Result;
	
EndFunction
 
// Returns infobase descriptions.
//
// Parameters:
//  ClusterID                       - String - internal server cluster ID.
//  ClusterAdministrationParameters - Structure - describes the parameters for connecting the
//                                    server cluster, for details, see
//                                    ClusterAdministrationClientServer.ClusterAdministrationParameters().
//  Filter                          - Structure - infobase filter parameters.
//
// Returns: Array of Structure.
//
Function GetInfobases(Val ClusterID, Val  ClusterAdministrationParameters, Filter = Undefined)
	
	Pattern = "%rac infobase summary --cluster=%cluster% --cluster-user=%?cluster-user% --cluster-pwd=%?cluster-pwd% list";
	
	Parameters = New Map();
	
	Parameters.Insert("cluster", ClusterID);
	FillParametersForAuthenticationInCluster(ClusterAdministrationParameters, Parameters);
	
	OutputThread = ExecuteCommand(Pattern, ClusterAdministrationParameters, Parameters);
	Result = OutputParser(OutputThread, Undefined, Filter);
	Return Result;
	
EndFunction
 
// Returns internal infobase ID.
//
// Parameters:
//  ClusterID                        - String - internal server cluster ID.
//  ClusterAdministrationParameters  - Structure - describes the parameters for connecting the
//                                     server cluster, for details, see
//                                     ClusterAdministrationClientServer.ClusterAdministrationParameters().
//  InfobaseAdministrationParameters - Structure - describes the parameters for connecting the
//                                     infobase, for details, see
//                                     ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters().
//
// Returns: String - internal server cluster ID.
//
Function GetInfobase(Val ClusterID, Val ClusterAdministrationParameters, Val InfobaseAdministrationParameters)
	
	Filter = New Structure("name", InfobaseAdministrationParameters.NameInCluster);
	
	Infobases = GetInfobases(ClusterID, ClusterAdministrationParameters, Filter);
	
	If Infobases.Count() = 1 Then
		Return Infobases[0].Get("infobase");
	Else
		Raise  StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'The %2 infobase is not registered in the %1 server cluster.'"),  ClusterID,  InfobaseAdministrationParameters.NameInCluster);
	EndIf;
	
EndFunction
 
// Returns working process descriptions.
//
// Parameters:
// ClusterID                       - String - internal server cluster ID.
// ClusterAdministrationParameters - Structure - describes the parameters for connecting the
//                                   server cluster, for details, see
//                                   ClusterAdministrationClientServer.ClusterAdministrationParameters().
// Filter                          - Structure - working process filter parameters.
//
// Returns: Array of Structure.
//
Function GetWorkingProcesses(Val ClusterID, Val ClusterAdministrationParameters, Filter = Undefined)
	
	Pattern = "%rac process --cluster=%cluster% --cluster-user=%?cluster-user% --cluster-pwd=%?cluster-pwd% list --server=%server%";
	
	Parameters = New Map();
	
	Parameters.Insert("cluster", ClusterID);
	FillParametersForAuthenticationInCluster(ClusterAdministrationParameters, Parameters);
	
	Result = New Array();
	ServerNames = GetServerNames(ClusterID, ClusterAdministrationParameters);
	For Each ServerName  In ServerNames Do
		Parameters.Insert("server", ServerName.Get("server"));
		OutputThread = ExecuteCommand(Pattern, ClusterAdministrationParameters, Parameters);
		ServerWorkingProcesses = OutputParser(OutputThread, Undefined, Filter);
		For Each  WorkingProcess In ServerWorkingProcesses Do
			If WorkingProcess.Get("running") Then
				Result.Add(WorkingProcess);
			EndIf;
		EndDo;
	EndDo;
	
	Return Result;
	
EndFunction
 
// Returns descriptions of infobase sessions.
//
// Parameters:
//  ClusterID                        - String - internal server cluster ID.
//  ClusterAdministrationParameters  - Structure - describes the parameters for connecting the server cluster, for
//                                     details, see ClusterAdministrationClientServer.ClusterAdministrationParameters().
//  InfobaseID                       - String - internal infobase ID.
//  InfobaseAdministrationParameters - Structure - describes the parameters for connecting the infobase, for details,
//                                     see ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters().
//  Filter                           - details on the session filtering conditions whose descriptions are required.
//                                      The following options are available:
//                                       1. Array of structures that describe session filtering conditions. Fields of
//                                          structures in the array are:
//                                           Property       - String - property name to be used in the filter. Valid
//                                                            values are the return value of the
//                                                            ClusterAdministrationClientServer.SessionProperties()
//                                                            function,
//                                           ComparisonType - value of the ComparisonType system enumeration. The value
//                                                            comparison type with the specified filter condition. Valid
//                                                            values are:
//                                                             ComparisonType.Equal,
//                                                             ComparisonType.NotEqual,
//                                                             ComparisonType.Greater (for numeric values only),
//                                                             ComparisonType.GreaterOrEqual (for numeric values only),
//                                                             ComparisonType.Less (for numeric values only),
//                                                             ComparisonType.LessOrEqual (for numeric values only),
//                                                             ComparisonType.InList,
//                                                             ComparisonType.NotInList,
//                                                             ComparisonType.Interval (for numeric values only),
//                                                             ComparisonType.IntervalIncludingBounds (for numeric values only),
//                                                             ComparisonType.IntervalIncludingLowerBound (for numeric values only),
//                                                             ComparisonType.IntervalIncludingUpperBound (for numeric values only),
//                                           Value          - Number, String, Date, Boolean, ValueList, Array, Structure -
//                                                            value, against which the corresponding session properties
//                                                            are compared. If ComparisonType.InList or
//                                                            ComparisonType.NotInList, pass ValueList or Array with a
//                                                            set of values against which the property is compared. In
//                                                            case of ComparisonType.Interval,
//                                                            ComparisonType.IntervalIncludingBounds,
//                                                            ComparisonType.IntervalIncludingLowerBound, or
//                                                            IntervalIncludingUpperBound, pass a structure with the
//                                                            From and To fields whose values are interval against which
//                                                            the value is compared.
//                                       2. Structure (simplified), where key is s session property name (see above),
//                                          value is a value, against which comparison is executed. When you use this
//                                          description option, the comparison filter always checks for equality.
//  UseDictionary                    - Boolean - if True, the return result is filled using the dictionary, otherwise do the dictionary is not used.
//
// Returns: Array of Structure, Array of Map - array of structures that describe the session properties (for structure
//          details see ClusterAdministrationClientServer.SessionProperties()) or an array of maps that describe the
//          session properties in the rac utility notation (when UseDictionary = False).
//
Function GetSessions(Val ClusterID, Val ClusterAdministrationParameters, Val InfobaseID, Filter = Undefined, Val UseDictionary = True) Export
	
	Pattern = "%rac session --cluster=%cluster% --cluster-user=%?cluster-user% --cluster-pwd=%?cluster-pwd% list --infobase=%infobase%";	
	
	Parameters = New Map();
	
	Parameters.Insert("cluster", ClusterID);
	FillParametersForAuthenticationInCluster(ClusterAdministrationParameters, Parameters);
	
	Parameters.Insert("infobase", InfobaseID);
	
	If UseDictionary Then
		Dictionary = DictionaryPropertiesSessions();
	Else
		Dictionary = Undefined;
		Filter = FilterToRacNotation(Filter, DictionaryPropertiesSessions());
	EndIf;
	
	OutputThread = ExecuteCommand(Pattern, ClusterAdministrationParameters, Parameters);
	Result = OutputParser(OutputThread, Dictionary, Filter);
	Return Result;
	
EndFunction
 
// Returns infobase connection descriptions.
//
// Parameters:
//  ClusterID                         - String - internal server cluster ID.
//  ClusterAdministrationParameters   - Structure - describes the parameters for connecting the server cluster, for
//                                      details, see ClusterAdministrationClientServer.ClusterAdministrationParameters().
//  InfobaseID                        - String - internal infobase ID.
//  InfobaseAdministrationParameters  - Structure - describes the parameters for connecting the infobase, for details,
//                                      see ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters().
//  Filter                            - details on the connection filtering conditions whose descriptions are required.
//                                      The following options are available:
//                                       1. Array of structures that describes connection filtering conditions. Fields of
//                                          structures in the array are:
//                                           Property       - String - property name to be used in the filter. Valid
//                                                            values are the return value of the
//                                                            ClusterAdministrationClientServer.ConnectionProperties()
//                                                            function.
//                                           ComparisonType - value of the ComparisonType system enumeration. The value
//                                                            comparison type with the specified filter condition. Valid
//                                                            values are:
//                                                             ComparisonType.Equal,
//                                                             ComparisonType.NotEqual,
//                                                             ComparisonType.Greater (for numeric values only),
//                                                             ComparisonType.GreaterOrEqual (for numeric values only),
//                                                             ComparisonType.Less (for numeric values only),
//                                                             ComparisonType.LessOrEqual (for numeric values only),
//                                                             ComparisonType.InList,
//                                                             ComparisonType.NotInList,
//                                                             ComparisonType.Interval (for numeric values only),
//                                                             ComparisonType.IntervalIncludingBounds (for numeric values only),
//                                                             ComparisonType.IntervalIncludingLowerBound (for numeric values only),
//                                                             ComparisonType.IntervalIncludingUpperBound (for numeric values only),
//                                           Value          - Number, String, Date, Boolean, ValueList, Array, Structure -
//                                                            value against which the corresponding connection property
//                                                            value is compared. If ComparisonType.InList or
//                                                            ComparisonType.NotInList, pass ValueList or Array with a
//                                                            set of values against which the property is compared. In
//                                                            case of ComparisonType.Interval,
//                                                            ComparisonType.IntervalIncludingBounds,
//                                                            ComparisonType.IntervalIncludingLowerBound, or
//                                                            IntervalIncludingUpperBound, pass a structure with the From
//                                                            and To fields whose values are interval against which the
//                                                            value is compared.
//                                       2. Structure (simplified), where key is a name of the connection property (see
//                                          above), value is a value, against which comparison is executed. When you use
//                                          this description option, the comparison filter always checks for equality.
//  UseDictionary                     - Boolean - if True, the return result is filled using the dictionary, otherwise
//                                      the dictionary is not used.
//
// Returns: Array of Structure, Array of Map - array of structures that describe the connection properties (for structure
//          details see ClusterAdministrationClientServer.ConnectionProperties()) or an array of maps that describe the
//          connection properties in the rac utility notation (when UseDictionary = False).
//
Function GetConnections(Val ClusterID, Val ClusterAdministrationParameters, Val InfobaseID, Val InfobaseAdministrationParameters, Val Filter = Undefined, Val UseDictionary = False) Export
	
	Pattern = "%rac connection --cluster=%cluster% --cluster-user=%?cluster-user% --cluster-pwd=%?cluster-pwd% list --process=%process% --infobase=%infobase% --infobase-user=%?infobase-user% --infobase-pwd=%?infobase-pwd%";
	
	Parameters = New Map();
	
	Parameters.Insert("cluster", ClusterID);
	FillParametersForAuthenticationInCluster(ClusterAdministrationParameters, Parameters);
	
	Parameters.Insert("infobase", InfobaseID);
	FillAuthenticationParametersInIB(InfobaseAdministrationParameters, Parameters);
	
	If UseDictionary Then
		Dictionary = ConnectionPropertyDictionary();
	Else
		Dictionary = Undefined;
		Filter = FilterToRacNotation(Filter, ConnectionPropertyDictionary());
	EndIf;
	
	Result = New Array();
	WorkingProcesses = GetWorkingProcesses(ClusterID, ClusterAdministrationParameters);
	
	For Each WorkingProcess In WorkingProcesses Do
		
		Parameters.Insert("process", WorkingProcess.Get("process"));
		OutputThread = ExecuteCommand(Pattern, ClusterAdministrationParameters, Parameters);
		WorkingProcessConnections = OutputParser(OutputThread, Dictionary, Filter);
		For Each Connection In WorkingProcessConnections Do
			If Not  UseDictionary Then
				Connection.Insert("process", WorkingProcess.Get("process"));
			EndIf;
			Result.Add(Connection);
		EndDo;
		
	EndDo;
	
	Return Result;
	
EndFunction
 
// Returns infobase property values.
//
// Parameters:
//  ClusterAdministrationParameters  - Structure - describes the parameters for connecting the
//                                     server cluster, for details, see
//                                     ClusterAdministrationClientServer.ClusterAdministrationParameters().
//  InfobaseAdministrationParameters - Structure - describes the parameters for connecting the
//                                     infobase, for details, see
//                                     ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters().
//  Dictionary                       - Structure - map of the property names for API and the
//                                     rac utility output thread.
//
// Returns: Structure - infobase description, generated by the passed dictionary.
//
Function InfobaseProperties(Val ClusterAdministrationParameters, Val InfobaseAdministrationParameters, Val Dictionary)
	
	Pattern = "%rac infobase --cluster=%cluster% --cluster-user=%?cluster-user% --cluster-pwd=%?cluster-pwd% info --infobase=%infobase% --infobase-user=%?infobase-user% --infobase-pwd=%?infobase-pwd%";
	
	Parameters = New Map();
	
	ClusterID = GetCluster(ClusterAdministrationParameters);
	Parameters.Insert("cluster", ClusterID);
	FillParametersForAuthenticationInCluster(ClusterAdministrationParameters, Parameters);
	
	InfobaseID =  GetInfobase(ClusterID, ClusterAdministrationParameters,  InfobaseAdministrationParameters);
	Parameters.Insert("infobase", InfobaseID);
	FillAuthenticationParametersInIB(InfobaseAdministrationParameters, Parameters);
	
	OutputThread = ExecuteCommand(Pattern, ClusterAdministrationParameters, Parameters);
	Result = OutputParser(OutputThread, Dictionary);
	Return Result[0];
	
EndFunction 

// Sets infobase property values.
//
// Parameters:
//  ClusterAdministrationParameters  - Structure - describes the parameters for connecting the
//                                     server cluster, for details, see 
//                                     ClusterAdministrationClientServer.ClusterAdministrationParameters().
//  InfobaseAdministrationParameters - Structure - describes the parameters for connecting the
//                                     infobase, for details, see 
//                                     ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters().
//  Dictionary                       - Structure - map of the property names for API and the
//                                     rac utility output thread.
//  PropertyValues                   - Structure - infobase property values to be set:
//                                      Key - property name in the API notation.
//                                      Value - value to be set for the property.
//
Procedure SetInfobaseProperties(Val ClusterAdministrationParameters, Val  InfobaseAdministrationParameters, Val Dictionary, Val PropertyValues)
	
	Pattern = "%rac infobase --cluster=%cluster% --cluster-user=%?cluster-user% --cluster-pwd=%?cluster-pwd% update --infobase=%infobase% --infobase-user=%?infobase-user% --infobase-pwd=%?infobase-pwd%";
	
	Parameters = New Map();
	
	ClusterID = GetCluster(ClusterAdministrationParameters);
	Parameters.Insert("cluster", ClusterID);
	FillParametersForAuthenticationInCluster(ClusterAdministrationParameters, Parameters);
	
	InfobaseID = GetInfobase(ClusterID, ClusterAdministrationParameters,  InfobaseAdministrationParameters);
	Parameters.Insert("infobase", InfobaseID);
	FillAuthenticationParametersInIB(InfobaseAdministrationParameters,  Parameters);
	
	FillParametersByDictionary(Dictionary, PropertyValues, Parameters, Pattern);
	
	ExecuteCommand(Pattern, ClusterAdministrationParameters,  Parameters);
	
EndProcedure
 
// Returns security profile descriptions.
//
// Parameters:
//  ClusterID                       - String - internal server cluster ID.
//  ClusterAdministrationParameters - Structure - describes the parameters for connecting the
//                                    server cluster, for details, see
//                                    ClusterAdministrationClientServer.ClusterAdministrationParameters().
//  Filter                          - Structure - security profile filter parameters.
//
// Returns: Array of Structure.
//
Function GetSecurityProfiles(Val ClusterID, Val ClusterAdministrationParameters, Val Filter = Undefined)
	
	Pattern = "%rac profile --cluster=%cluster% --cluster-user=%?cluster-user% --cluster-pwd=%?cluster-pwd% list";
	
	Parameters = New Map();
	
	Parameters.Insert("cluster", ClusterID);
	FillParametersForAuthenticationInCluster(ClusterAdministrationParameters, Parameters);
	
	OutputThread = ExecuteCommand(Pattern, ClusterAdministrationParameters, Parameters);
	Result = OutputParser(OutputThread,  SecurityProfilePropertyDictionary(), Filter);
	Return Result;
	
EndFunction
 
// Returns virtual directory descriptions.
//
// Parameters:
//  ClusterID                       - String - internal server cluster ID.
//  ClusterAdministrationParameters - Structure - describes the parameters for connecting the
//                                    server cluster, for details, see
//                                    ClusterAdministrationClientServer.ClusterAdministrationParameters().
//  ProfileName                     - String - name of the security profile.
//  Filter                          - Structure - virtual directory filter parameters.
//
// Returns: Array of Structure.
//
Function GetVirtualDirectories(Val ClusterID, Val ClusterAdministrationParameters, Val ProfileName, Val Filter = Undefined)
	
	Return GetAccessControlList(
		ClusterID,
		ClusterAdministrationParameters,
		ProfileName,
		"directory", // Do not localize this parameter
		VirtualDirectoryPropertyDictionary());
	
EndFunction
 
// Returns COM class descriptions.
//
// Parameters:
//  ClusterID                       - String - internal server cluster ID.
//  ClusterAdministrationParameters - Structure - describes the parameters for connecting the
//                                    server cluster, for details, see
//                                    ClusterAdministrationClientServer.ClusterAdministrationParameters().
//  ProfileName                     - String - name of the security profile.
//  Filter                          - Structure - COM class filter parameters.
//
// Returns: Array of Structure.
//
Function GetAllowedCOMClasses(Val ClusterID, Val ClusterAdministrationParameters, Val ProfileName, Val Filter = Undefined)
	
	Return GetAccessControlList(
		ClusterID,
		ClusterAdministrationParameters,
		ProfileName,
		"com", // Do not localize this parameter
		COMClassPropertyDictionary());
	
EndFunction
 
// Returns add-in descriptions.
//
// Parameters:
//  ClusterID                       - String - internal server cluster ID.
//  ClusterAdministrationParameters - Structure - describes the parameters for connecting the
//                                    server cluster, for details, see
//                                    ClusterAdministrationClientServer.ClusterAdministrationParameters().
//   ProfileName                    - String - name of the security profile.
//   Filter                         - Structure - add-in filter parameters.
//
// Returns: Array of Structure.
//
Function GetAllowedAddIns(Val ClusterID, Val ClusterAdministrationParameters, Val ProfileName, Val Filter = Undefined)
	
	Return GetAccessControlList(
		ClusterID,
		ClusterAdministrationParameters,
		ProfileName,
		"addin", // Do not localize this parameter
		AddInPropertyDictionary());
	
EndFunction
 
// Returns external module descriptions.
//
// Parameters:
// ClusterID                       - String - internal server cluster ID.
// ClusterAdministrationParameters - Structure - describes the parameters for connecting the
//                                   server cluster, for details, see
//                                   ClusterAdministrationClientServer.ClusterAdministrationParameters().
// ProfileName                     - String - name of the security profile.
// Filter                          - Structure - external module filter parameters.
//
// Returns: Array of Structure.
//
Function GetAllowedExternalModules(Val ClusterID, Val ClusterAdministrationParameters, Val ProfileName, Val Filter = Undefined)
	
	Return GetAccessControlList(
		ClusterID,
		ClusterAdministrationParameters,
		ProfileName,
		"module", // Do not localize this parameter
		ExternalModulePropertyDictionary());
	
EndFunction
 
// Returns OS application descriptions.
//
// Parameters:
// ClusterID                       - String - internal server cluster ID.
// ClusterAdministrationParameters - Structure - describes the parameters for connecting the
//                                   server cluster, for details, see
//                                   ClusterAdministrationClientServer.ClusterAdministrationParameters().
// ProfileName                     - String - name of the security profile.
// Filter                          - Structure - OS application filter parameters.
//
// Returns: Array of Structure.
//
Function GetAllowedOSApplications(Val ClusterID, Val ClusterAdministrationParameters, Val ProfileName, Val Filter = Undefined)
	
	Return GetAccessControlList(
		ClusterID,
		ClusterAdministrationParameters,
		ProfileName,
		"app", // Do not localize this parameter
		OSApplicationPropertyDictionary());
	
EndFunction
 
// Returns Internet resource descriptions.
//
// Parameters:
// ClusterID                       - String - internal server cluster ID.
// ClusterAdministrationParameters - Structure - describes the parameters for connecting the
//                                   server cluster, for details, see
//                                   ClusterAdministrationClientServer.ClusterAdministrationParameters().
// ProfileName                     - String - name of the security profile.
// Filter                          - Structure - Internet resource filter parameters.
//
// Returns: Array of Structure.
//
Function GetAllowedInternetResources(Val ClusterID, Val ClusterAdministrationParameters, Val ProfileName, Val Filter = Undefined)
	
	Return GetAccessControlList(
		ClusterID,
		ClusterAdministrationParameters,
		ProfileName,
		"inet", // Do not localize this parameter
		InternetResourcePropertyDictionary());
	
EndFunction
 
// Returns descriptions of access control list items.
//
// Parameters:
// ClusterID                       - String - internal server cluster ID.
// ClusterAdministrationParameters - Structure - describes the parameters for connecting the
//                                   server cluster, for details, see
// ClusterAdministrationClientServer.ClusterAdministrationParameters().
// ProfileName                     - String - name of the security profile.
// ListName                        - String - name of the access control list (acl) in the rac
//                                   utility notation.
// Dictionary                      - Structure - map of the property names in the rac utility
//                                   input thread and in the requiring description.
// Filter                          - Structure - parameters of the access control list item
//                                   filter.
//
// Returns: Array of Structure.
//
Function GetAccessControlList(Val ClusterID, Val ClusterAdministrationParameters, Val ProfileName, Val ListName, Val Dictionary, Val Filter = Undefined)
	
	Pattern = "%rac profile --cluster=%cluster% --cluster-user=%?cluster-user% --cluster-pwd=%?cluster-pwd% acl --name=%name% directory list";
	Pattern = StrReplace(Pattern, "directory", ListName);
	
	Parameters = New Map();
	
	Parameters.Insert("cluster", ClusterID);
	FillParametersForAuthenticationInCluster(ClusterAdministrationParameters, Parameters);
	
	Parameters.Insert("name", ProfileName);
	
	OutputThread = ExecuteCommand(Pattern, ClusterAdministrationParameters, Parameters);
	Result = OutputParser(OutputThread, Dictionary, Filter);
	Return Result;
	
EndFunction
 
// Updates security profile properties (including acl content and usage).
//
// Parameters:
// ClusterAdministrationParameters - Structure - describes the parameters for connecting the
//                                   server cluster, for details, see
// ClusterAdministrationClientServer.ClusterAdministrationParameters().
// SecurityProfileProperties       - Structure - describes properties of security profile
//                                   properties to be set, for details see
// ClusterAdministrationClientServer.SecurityProfileProperties().
// ClearAccessControlLists         - Boolean - flag that shows whether the current acl content 
//                                   must be cleared in advance.
//
Procedure UpdateSecurityProfileProperties(Val ClusterAdministrationParameters, Val SecurityProfileProperties, Val ClearAccessControlLists)
	
	ProfileName = SecurityProfileProperties.Name;
	
	Pattern = "%rac profile --cluster=%cluster% --cluster-user=%?cluster-user% --cluster-pwd=%?cluster-pwd% update";
	
	Parameters = New Map();
	
	ClusterID = GetCluster(ClusterAdministrationParameters);
	Parameters.Insert("cluster", ClusterID);
	
	FillParametersForAuthenticationInCluster(ClusterAdministrationParameters,  Parameters);
	FillParametersByDictionary(SecurityProfilePropertyDictionary(False),  SecurityProfileProperties, Parameters, Pattern);
	
	ExecuteCommand(Pattern, ClusterAdministrationParameters,  Parameters);
	
	UsagePropertyDictionaryForAccessControlLists = UsagePropertyDictionaryForAccessControlList();
	For Each DictionaryFragment In UsagePropertyDictionaryForAccessControlLists Do
		SetAccessControlListUsage(ClusterID, ClusterAdministrationParameters, ProfileName, DictionaryFragment.Value, Not SecurityProfileProperties[DictionaryFragment.Key]);
	EndDo;
	
	// Virtual directories
	ListName = "directory";
	CurrentDictionary =  VirtualDirectoryPropertyDictionary();
	If ClearAccessControlLists Then
		VirtualDirectoriesToDelete = GetAccessControlList(ClusterID, ClusterAdministrationParameters, ProfileName, ListName, CurrentDictionary);
		For Each VirtualDirectoryToDelete In  VirtualDirectoriesToDelete Do
			DeleteAccessControlListItem(ClusterID,  ClusterAdministrationParameters, ProfileName, ListName, VirtualDirectoryToDelete.LogicalURL);
		EndDo;
	EndIf;
	VirtualDirectoriesToCreate = SecurityProfileProperties.VirtualDirectories;
	For Each VirtualDirectoryToCreate In VirtualDirectoriesToCreate Do
		CreateAccessControlListItem(ClusterID, ClusterAdministrationParameters, ProfileName, ListName, CurrentDictionary, VirtualDirectoryToCreate);
	EndDo;
	
	// Allowed COM classes
	ListName = "com";
	CurrentDictionary = COMClassPropertyDictionary();
	If ClearAccessControlLists Then
		COMClassesToDelete = GetAccessControlList(ClusterID, ClusterAdministrationParameters,  ProfileName, ListName, CurrentDictionary);
		For Each COMClassToDelete In COMClassesToDelete Do
			DeleteAccessControlListItem(ClusterID, ClusterAdministrationParameters, ProfileName, ListName, COMClassToDelete.Name);
		EndDo;
	EndIf;
	COMClassesToCreate = SecurityProfileProperties.COMClasses;
	For Each COMClassToCreate In COMClassesToCreate Do
		CreateAccessControlListItem(ClusterID, ClusterAdministrationParameters, ProfileName, ListName, CurrentDictionary, COMClassToCreate);
	EndDo;
	
	// Add-ins
	ListName = "addin";
	CurrentDictionary = AddInPropertyDictionary();
	If ClearAccessControlLists Then
		AddInsToDelete =  GetAccessControlList(ClusterID, ClusterAdministrationParameters,  ProfileName, ListName, CurrentDictionary);
		For Each AddInToDelete In AddInsToDelete Do
			DeleteAccessControlListItem(ClusterID, ClusterAdministrationParameters, ProfileName, ListName, AddInToDelete.Name);
		EndDo;
	EndIf;
	AddInsToCreate = SecurityProfileProperties.AddIns;
	For Each  AddInToCreate In AddInsToCreate Do
		CreateAccessControlListItem(ClusterID, ClusterAdministrationParameters, ProfileName, ListName, CurrentDictionary, AddInToCreate);
	EndDo;
	
	// External modules
	ListName = "module";
	CurrentDictionary = ExternalModulePropertyDictionary();
	If ClearAccessControlLists Then
		ExternalModulesToDelete = GetAccessControlList(ClusterID, ClusterAdministrationParameters,  ProfileName, ListName, CurrentDictionary);
		For Each  ExternalModuleToDelete In ExternalModulesToDelete Do
			DeleteAccessControlListItem(ClusterID, ClusterAdministrationParameters, ProfileName, ListName, ExternalModuleToDelete.Name);
		EndDo;
	EndIf;
	ExternalModulesToCreate = SecurityProfileProperties.ExternalModules;
	For Each ExternalModuleToCreate In ExternalModulesToCreate  Do
		CreateAccessControlListItem(ClusterID, ClusterAdministrationParameters, ProfileName, ListName, CurrentDictionary, ExternalModuleToCreate);
	EndDo;
	
	// OS applications
	ListName = "app";
	CurrentDictionary = OSApplicationPropertyDictionary();
	If ClearAccessControlLists Then
		OSApplicationsToDelete =  GetAccessControlList(ClusterID, ClusterAdministrationParameters,  ProfileName, ListName, CurrentDictionary);
		For Each OSApplicationToDelete In OSApplicationsToDelete Do
			DeleteAccessControlListItem(ClusterID, ClusterAdministrationParameters, ProfileName, ListName, OSApplicationToDelete.Name);
		EndDo;
	EndIf;
	OSApplicationsToCreate = SecurityProfileProperties.OSApplications;
	For Each  OSApplicationToCreate In OSApplicationsToCreate Do
		CreateAccessControlListItem(ClusterID, ClusterAdministrationParameters, ProfileName, ListName, CurrentDictionary, OSApplicationToCreate);
	EndDo;
	
	// Internet resources
	ListName = "inet";
	CurrentDictionary = InternetResourcePropertyDictionary();
	If ClearAccessControlLists Then
		InternetResourcesToDelete = GetAccessControlList(ClusterID, ClusterAdministrationParameters, ProfileName, ListName, CurrentDictionary);
		For Each  InternetResourceToDelete In InternetResourcesToDelete Do
			DeleteAccessControlListItem(ClusterID, ClusterAdministrationParameters, ProfileName, ListName,  InternetResourceToDelete.Name);
		EndDo;
	EndIf;
	InternetResourcesToCreate = SecurityProfileProperties.InternetResources;
	For Each  InternetResourceToCreate In InternetResourcesToCreate Do
		CreateAccessControlListItem(ClusterID, ClusterAdministrationParameters, ProfileName, ListName, CurrentDictionary, InternetResourceToCreate);
	EndDo;
	
EndProcedure
 
// Sets acl usage for security profiles.
//
// Parameters:
// ClusterID                       - String - internal server cluster ID.
// ClusterAdministrationParameters - Structure - describes the parameters for connecting the
//                                   server cluster, for details, see
//                                   ClusterAdministrationClientServer.ClusterAdministrationParameters().
// ProfileName                     - String - name of the security profile.
// ListName                        - String - name of the access control list (acl) in the rac
//                                   utility notation.
// Use                             - Boolean - flag that shows whether acl is used.
//
Procedure  SetAccessControlListUsage(Val ClusterID, Val ClusterAdministrationParameters, Val ProfileName, Val ListName, Val Use)
	
	Pattern = "%rac profile --cluster=%cluster% --cluster-user=%?cluster-user% --cluster-pwd=%?cluster-pwd% acl --name=%name% directory remove --key=%key%";
	Pattern = StrReplace(Pattern, "directory", ListName);
	
	Parameters = New Map();
	
	Parameters.Insert("cluster", ClusterID);
	FillParametersForAuthenticationInCluster(ClusterAdministrationParameters, Parameters);
	Parameters.Insert("name", ProfileName);
	If Use Then
		Parameters.Insert("access", "list");
	Else
		Parameters.Insert("access", "full");
	EndIf;
	
	OutputThread = ExecuteCommand(Pattern, ClusterAdministrationParameters, Parameters);
	
EndProcedure
 
// Deletes acl item for security profiles.
//
// Parameters:
// ClusterID                       - String - internal server cluster ID.
// ClusterAdministrationParameters - Structure - describes the parameters for connecting the
//                                   server cluster, for details, see
// ClusterAdministrationClientServer.ClusterAdministrationParameters().
// ProfileName                     - String - name of the security profile.
// ListName                        - String - name of the access control list (acl) in the rac
//                                   utility notation.
// ItemKey                         - String - key property value of the acl item.
//
Procedure  DeleteAccessControlListItem(Val ClusterID, Val ClusterAdministrationParameters, Val ProfileName, Val ListName, Val ItemKey)
	
	ListKey = AccessControlListKeys()[ListName];
	
	Pattern = "%rac profile --cluster=%cluster% --cluster-user=%?cluster-user% --cluster-pwd=%?cluster-pwd% acl --name=%name% directory remove --key=%key%";
	Pattern = StrReplace(Pattern, "directory", ListName);
	Pattern = StrReplace(Pattern, "key", ListKey);
	
	Parameters = New Map();
	
	Parameters.Insert("cluster", ClusterID);
	FillParametersForAuthenticationInCluster(ClusterAdministrationParameters, Parameters);
	Parameters.Insert("name", ProfileName);
	Parameters.Insert(ListKey, ItemKey);
	
	OutputThread = ExecuteCommand(Pattern, ClusterAdministrationParameters, Parameters);
	
EndProcedure
 
// Creates acl item for security profiles.
//
// Parameters:
// ClusterID                       - String - internal server cluster ID.
// ClusterAdministrationParameters - Structure - describes the parameters for connecting the
//                                   server cluster, for details, see
//                                   ClusterAdministrationClientServer.ClusterAdministrationParameters().
// ProfileName                     - String - name of the security profile.
// ListName                        - String - name of the access control list (acl) in the rac
//                                   utility notation.
// Dictionary                      - Structure - map of the property names in the rac utility
//                                   input thread and in the requiring description.
// ItemProperties                  - Structure - property values of the access control list
//                                   item.
//
Procedure CreateAccessControlListItem(Val ClusterID, Val ClusterAdministrationParameters, Val ProfileName, Val ListName, Val Dictionary,  Val ItemProperties)
	
	Pattern = "%rac profile --cluster=%cluster% --cluster-user=%?cluster-user% --cluster-pwd=%?cluster-pwd% acl --name=%profile_name% directory update";
	Pattern = StrReplace(Pattern, "directory", ListName);
	
	Parameters = New Map();
	
	Parameters.Insert("cluster", ClusterID);
	FillParametersForAuthenticationInCluster(ClusterAdministrationParameters, Parameters);
	Parameters.Insert("profile_name", ProfileName);
	
	FillParametersByDictionary(Dictionary, ItemProperties, Parameters, Pattern);
	
	OutputThread = ExecuteCommand(Pattern, ClusterAdministrationParameters, Parameters);
	
EndProcedure
 
// Converts values of the access control list usage property values (nonstandard value format
// are used when passing the values to the rac utility: True="full", False="list").
//
// Parameters:
//  DescriptionStructure - Structure - contains the object description received from the output
//                         thread of the rac utility.
//
// Returns: Structure where "full" and "list" have been converted to True and False.
//
Function ConvertAccessListUsagePropertyValues(Val DescriptionStructure)
	
	Dictionary = UsagePropertyDictionaryForAccessControlList();
	
	Result = New Structure;
	
	For Each KeyAndValue In DescriptionStructure Do
		
		If Dictionary.Property(KeyAndValue.Key) Then
			
			If KeyAndValue.Value = "list" Then
				
				Value = False;
				
			ElsIf KeyAndValue.Value = "full" Then
				
				Value = True;
				
			EndIf;
			
			Result.Insert(KeyAndValue.Key, Value);
			
		Else
			
			Result.Insert(KeyAndValue.Key, KeyAndValue.Value);
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction
 
// Converts 1C:Enterprise script values into the notation of the console client of the
// administration server.
//
// Parameters:
//  Value - Arbitrary - value to be converted.
//
// Returns:
// String - value casted to the notation of the console client of the administration server.
//
Function AdjustValue(Val Value, Val ParameterName = "")
	
	If TypeOf(Value) = Type("Date") Then
		Return XMLString(Value);
	EndIf;
	
	If TypeOf(Value) = Type("Boolean") Then
		
		If IsBlankString(ParameterName) Then
			FormatString = "BF=off; BT=on";
		Else
			FormatString = BooleanPropertyFormatDictionary()[ParameterName];
		EndIf;
		
		Return Format(Value, FormatString);
		
	EndIf;
	
	If TypeOf(Value) = Type("Number") Then
		Return Format(Value, "NDS=,; NZ=0; NG=0; NN=1");
	EndIf;
	
	If TypeOf(Value) = Type("String") Then
		If Find(Value, """") > 0 Or Find(Value, " ") > 0 Or Find(Value, "-") > 0 Or Find(Value, "!") > 0 Then
			Return """" + StrReplace(Value, """",  """""") + """";
		EndIf;
	EndIf;
	
	Return String(Value);
	
EndFunction
 
// Converts the output thread item that contains a value into the notation of the console
// client of the administration server.
//
// Parameters:
//  OutputItem - String - output thread item that contains the value in the notation of the 
//               console client of the administration server.
//
// Returns:
//  Arbitrary - 1C:Enterprise script value.
//
Function CastOutputItem(OutputItem)
	
	If Left(OutputItem, 1) = """" Then
		OutputItem = Right(OutputItem, StrLen(OutputItem) - 1);
	EndIf;
	
	If Right(OutputItem, 1) = """" Then
		OutputItem = Left(OutputItem, StrLen(OutputItem) - 1);
	EndIf;
	
	OutputItem = StrReplace(OutputItem, """""", """");
	
	If IsBlankString(OutputItem) Then
		Return Undefined;
	EndIf;
	
	If OutputItem = "on" Or OutputItem = "yes" Then
		Return True;
	EndIf;
	
	If OutputItem = "off" Or OutputItem = "no" Then
		Return False;
	EndIf;
	
	If StringFunctionsClientServer.OnlyDigitsInString(OutputItem) Then
		Return Number(OutputItem);
	EndIf;
	
	Try
		Return XMLValue(Type("Date"), OutputItem);
	Except
		// No exception processing required.
		// Expected exception: the value cannot be converted into Date
	EndTry;
	
	Return OutputItem;
	
EndFunction 
 
// Starts the console client of the administration server for executing the command.
//
// Parameters:
//  Pattern                         - String - command line pattern (unique for each command).
//  ClusterAdministrationParameters - Structure - describes the parameters for connecting the
//                                    server cluster, for details, see
//                                    ClusterAdministrationClientServer.ClusterAdministrationParameters().
// ParameterValues                  - Structure - contains values of the parameters to be
//                                    substituted into the pattern.
//
// Returns:
//  String - standard output thread redirection result when starting the rac utility.
//
Function ExecuteCommand(Val Pattern, Val ClusterAdministrationParameters, Val ParameterValues = Undefined)
	
	#If Server Then
		
		If SafeMode()  Then
			Raise NStr("en = 'Cannot administrate cluster in the safe mode.'");
		EndIf;
		
		If CommonUseCached.DataSeparationEnabled() Then
			Raise NStr("en = 'The applied infobase in the SaaS mode cannot administer the cluster.'");
		EndIf;
		
	#EndIf
	
	SystemInfo = New SystemInfo();
	
	// Substituting path to the rac utility and the ras server address to the command line
	Client = GetAdministrationServerClient();
	ClientFile = New File(Client);
	If Not ClientFile.Exist() Then
		
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Cannot execute server cluster administration command. Reason:: The %1 file is not found.
 |
 |To administer the cluster through the administration server (ras), install the administration server client (rac) to this computer.
 |For installing rac:
 |- If your computer runs Windows, reinstall the 1C:Enterprise platform with the ""Administration of 1C:Enterprise server"" check box selected;
 |- If your computer runs Linux, install the 1c-enterprise83-server* package.'"),
			ClientFile.FullName);
		
	EndIf;
	
	If ValueIsFilled(ClusterAdministrationParameters.AdministrationServerAddress) Then
		Server = TrimAll(ClusterAdministrationParameters.AdministrationServerAddress);
		If ValueIsFilled(ClusterAdministrationParameters.AdministrationServerPort) Then
			Server = Server + ":" + AdjustValue(ClusterAdministrationParameters.AdministrationServerPort);
		Else
			Server = Server + ":1545";
		EndIf;
	Else
		Server = "";
	EndIf;
	
	CommandLine = """" +  Client + """" + StrReplace(Pattern, "%rac", Server);
	
	// Substituting parameter values to the command line
	If ValueIsFilled(ParameterValues) Then
		For Each Parameter  In ParameterValues Do
			// Filling the parameter value
			CommandLine = StrReplace(CommandLine, "%" + Parameter.Key + "%", AdjustValue(Parameter.Value, Parameter.Key));
			If ValueIsFilled(Parameter.Value) Then
				// The parameter can be optional
				CommandLine = StrReplace(CommandLine, "%?" + Parameter.Key + "%", AdjustValue(Parameter.Value, Parameter.Key));
			Else
				// If the optional parameter is not set,  cutting it out from the command line
				CommandLine = StrReplace(CommandLine, "--" +  Parameter.Key + "=%?" +  Parameter.Key + "%", "");
			EndIf;
		EndDo;
	EndIf;
	
	// Redirecting stdout and stderr
	OutputThreadFile = GetTempFileName("out");
	ErrorThreadFile = GetTempFileName("err");
	CommandLine = CommandLine + " > """ + OutputThreadFile + """ 2>""" + ErrorThreadFile + """";
	
	If (SystemInfo.PlatformType = PlatformType.Windows_x86) Or (SystemInfo.PlatformType  = PlatformType.Windows_x86_64) Then
		
		// In Windows, starting cmd.exe (for redirecting stdout and stderr)
		CommandLine = "cmd  /c" + " """ +  CommandLine + """";
		
		#If Server Then
			
			RunApp(CommandLine, PlatformExecutableFileDirectory(), True);
			
		#Else
			
			// In Windows, using Wscript.Shell to prevent cmd windows displaying
			
			Shell = New COMObject("Wscript.Shell");
			Shell.Run(CommandLine, 0, True);
			
		#EndIf
		
	Else
		
		// In case of Linux just executing the command
		
		RunApp(CommandLine, PlatformExecutableFileDirectory(),  True);
		
	EndIf;
	
	ErrorThreadReader = New TextReader(ErrorThreadFile,  GetStandardThreadEncoding());
	ErrorThread = ErrorThreadReader.Read();
	
	If ValueIsFilled(ErrorThread) Then
		
		Raise ErrorThread;
		
	Else
		
		OutputThreadReader = New TextReader(OutputThreadFile,  GetStandardThreadEncoding()); 
		OutputThread = OutputThreadReader.Read();
		If OutputThread =  Undefined Then
			OutputThread = "";
		EndIf;
		
		Return OutputThread;
		
	EndIf;
	
EndFunction
 
// Returns the directory of platform executable files.
//
// Returns:
//  String - directory of executable platform files.
//
Function PlatformExecutableFileDirectory() Export
	
	Result = BinDir();
	SlashMark = GetPathSeparator();
	
	If Not Right(Result, 1) = SlashMark Then
		Result = Result + SlashMark;
	EndIf;
	
	Return Result;
	
EndFunction
 
// Returns the path to the console client of the administration server.
//
// Returns:
// String - path to the console client of the administration server.
//
Function GetAdministrationServerClient() Export
	
	StartDirectory = PlatformExecutableFileDirectory();
	Client = StartDirectory + "rac";
	
	SysInfo = New SystemInfo();
	If (SysInfo.PlatformType = PlatformType.Windows_x86) Or (SysInfo.PlatformType = PlatformType.Windows_x86_64) Then
		Client = Client + ".exe";
	EndIf;
	
	Return Client;
	
EndFunction
 
// Returns encoding of standard output and error threads for the current operating system.
//
// Returns:
//  TextEncoding - encoding of standard output and error threads.
//
Function GetStandardThreadEncoding() Export
	
	SysInfo = New SystemInfo();
	If (SysInfo.PlatformType = PlatformType.Windows_x86) Or (SysInfo.PlatformType = PlatformType.Windows_x86_64) Then
		Encoding = TextEncoding.OEM;
	Else
		Encoding = TextEncoding.System;
	EndIf;
	
	Return Encoding;
	
EndFunction
 
// Converts redirected output thread of the console client of the administration server into
// the array of maps (array elements are  objects, map keys are property names, map values are
// property values.
//
// Parameters:
//  OutputThread - Redirect - redirected output thread.
//  Dictionary   - Structure - map dictionary for object property names.
//                 In the rac utility notation and in the API notation.
//  Filter       - Structure - object filter conditions (only for the threads of output
//                 commands that return object collections).
//
// Returns:
//  Array of Map
//
Function OutputParser(Val OutputThread, Val Dictionary, Val Filter = Undefined)
	
	Result = New Array();
	ResultItem = New Map();
	
	OutputSize = StrLineCount(OutputThread);
	For Step = 1 to OutputSize Do
		ThreadItem = StrGetLine(OutputThread, Step);
		ThreadItem = TrimAll(ThreadItem);
		SeparatorLocation = Find(ThreadItem, ":");
		If SeparatorLocation > 0 Then
			
			PropertyName = TrimAll(Left(ThreadItem, SeparatorLocation - 1));
			PropertyValue = CastOutputItem(TrimAll(Right(ThreadItem, StrLen(ThreadItem) - SeparatorLocation)));
			ResultItem.Insert(PropertyName, PropertyValue);
			
		Else
			
			If ResultItem.Count() > 0 Then
				
				OutputItemParser(ResultItem, Result, Dictionary, Filter);
				
				ResultItem = New Map();
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If ResultItem.Count() > 0 Then
		OutputItemParser(ResultItem, Result, Dictionary, Filter);
	EndIf;
	
	Return Result;
	
EndFunction
 
// Converts the item of the redirected output thread of the console client of the
// administration server into a map. Map keys are property names, map values are property
// values.
//
// Parameters:
// ResultItem - String - item of the output thread.
// Result     - Array - array where the parsed object must be added.
// Dictionary - Structure - map dictionary for object property names.
//              In the rac utility notation and in the API notation.
// Filter     - Structure - object filter conditions (only for the threads of output commands
//              that return object collections).
//
Procedure OutputItemParser(ResultItem, Result, Dictionary, Filter)
	
	If Dictionary <> Undefined Then
		Object = ParseOutputItem(ResultItem, Dictionary);
	Else
		Object = ResultItem;
	EndIf;
	
	If Filter <> Undefined And Not ClusterAdministrationClientServer.CheckFilterConditions(Object, Filter) Then
		Return;
	EndIf;
	
	Result.Add(Object);
	
EndProcedure
 
// Parses the item of the redirected output thread of the console client of the administration
// server.
//
// Parameters:
//  OutputItem - String - item of the redirected administration server client output thread.
//  Dictionary - Structure - map dictionary for object property names.
//               In the rac utility notation and in the API notation.
//
// Returns: Structure - keys are property names in the API notation, values are property values
//          from the redirected output thread.
//
Function ParseOutputItem(Val OutputItem, Val Dictionary)
	
	Result = New Structure();
	
	For Each DictionaryFragment In Dictionary Do
		
		Result.Insert(DictionaryFragment.Key, OutputItem[DictionaryFragment.Value]);
		
	EndDo;
	
	Return Result;
	
EndFunction
 
// Adds the cluster administrator authentication parameters to the ras start parameters.
//
// Parameters:
// ClusterAdministrationParameters - Structure - describes the parameters for connecting the
//                                   server cluster, for details, see 
//                                   ClusterAdministrationClientServer.ClusterAdministrationParameters().
// Parameters                      - Map - map of the rac start parameters to be generated.
//
Procedure  FillParametersForAuthenticationInCluster(Val ClusterAdministrationParameters, Parameters)
	
	Parameters.Insert("cluster-user", ClusterAdministrationParameters.ClusterAdministratorName);
	Parameters.Insert("cluster-pwd",  ClusterAdministrationParameters.ClusterAdministratorPassword);
	
EndProcedure

// Adds the infobase administrator authentication parameters to the ras start parameters.
//
// Parameters:
// InfobaseAdministrationParameters - Structure - describes the parameters for connecting the
//                                    infobase, for details, see
//                                    ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters().
// Parameters                       - Map - map of the rac start parameters to be generated.
//
Procedure  FillAuthenticationParametersInIB(Val InfobaseAdministrationParameters, Parameters)
	
	Parameters.Insert("infobase-user",  InfobaseAdministrationParameters.InfobaseAdministratorName);
	Parameters.Insert("infobase-pwd",  InfobaseAdministrationParameters.InfobaseAdministratorPassword);
	
EndProcedure
 
// Supplements the rac start parameters by the dictionary.
//
// Parameters:
// Dictionary - Structure - map dictionary for object property names in the rac notation and in 
//              the API notations.
// Source     - Structure - key is a property name in the API notation, value is a property
//              value.
// Parameters - Map - rac start parameters.
// Pattern    - String - command pattern for starting rac.
//
Procedure FillParametersByDictionary(Val Dictionary,  Val Source, Parameters, Pattern)
	
	For Each  DictionaryFragment In Dictionary Do
		
		Pattern = Pattern + " --" + DictionaryFragment.Value + "=%" + DictionaryFragment.Value + "%";
		Parameters.Insert(DictionaryFragment.Value, Source[DictionaryFragment.Key]);
		
	EndDo;
	
EndProcedure
 
// Converts the filter into the rac utility notation.
//
// Parameters:
//  Filter     - Structure, Array of Structure - filter in the API notation.
//  Dictionary - Structure - map details of the property names in the API notation and the rac
//               utility notation.
//
// Returns: Structure, Array of Structure - filter in the rac utility notation.
//
Function FilterToRacNotation(Val Filter, Val Dictionary)
	
	If Filter = Undefined Then
		Return Undefined;
	EndIf;
	
	If Dictionary = Undefined Then
		Return Filter;
	EndIf;
	
	Result = New Array();
	
	For Each Condition In Filter Do
		
		If TypeOf(Condition) = Type("KeyAndValue") Then
			
			Result.Add(New Structure("Property, ComparisonType, Value", Dictionary[Condition.Key], ComparisonType.Equal, Condition.Value));
			
		ElsIf TypeOf(Condition) = Type("Structure") Then
			
			Result.Add(New Structure("Property, ComparisonType, Value", Dictionary[Condition.Property], Condition.ComparisonType, Condition.Value));
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction
 
// Returns a map of infobase property names that describe the session lock state and scheduled 
// jobs. Is used for structures used in the API and for object descriptions in the rac output.
//
// Returns: FixedStructure:
//           Key   - String - property name in the API (See
//                   ClusterAdministrationClientServer.SessionAndScheduleJobLockProperties()),
//           Value - String - object property name.
//
Function  SessionAndScheduledJobLockPropertyDictionary()
	
	Result = New Structure();
	
	Result.Insert("SessionsLock", "sessions-deny");
	Result.Insert("StartDate", "denied-from");
	Result.Insert("EndDate", "denied-to");
	Result.Insert("Message", "denied-message");
	Result.Insert("KeyCode", "permission-code");
	Result.Insert("ScheduledJobLock", "scheduled-jobs-deny");
	
	Return New FixedStructure(Result);
	
EndFunction
 
// Returns a map of infobase session property names for structures used in the API and object 
// descriptions in the rac output.
//
// Returns: FixedStructure:
//           Key   - String - property name in the API (See
//                   ClusterAdministrationClientServer.SessionProperties()),
//           Value - String - object property name.
//
Function DictionaryPropertiesSessions()
	
	Result = New Structure();
	
	Result.Insert("Number", "session-id");
	Result.Insert("UserName", "user-name");
	Result.Insert("ClientComputerName", "host");
	Result.Insert("ClientApplicationID", "app-id");
	Result.Insert("LanguageID", "locale");
	Result.Insert("SessionCreationTime", "started-at");
	Result.Insert("LatestSessionActivityTime", "last-active-at");
	Result.Insert("DBMSLock", "blocked-by-dbms");
	Result.Insert("Lock", "blocked-by-ls");
	Result.Insert("Passed", "bytes-all");
	Result.Insert("PassedIn5Minutes", "bytes-last-5min");
	Result.Insert("ServerCalls", "calls-all");
	Result.Insert("ServerCallsIn5Minutes", "calls-last-5min");
	Result.Insert("ServerCallDurations", "duration-all");
	Result.Insert("CurrentServerCallDuration", "duration-current");
	Result.Insert("ServerCallDurationsIn5Minutes", "duration-last-5min");
	Result.Insert("ExchangedWithDBMS", "dbms-bytes-all");
	Result.Insert("ExchangedWithDBMSIn5Minutes", "dbms-bytes-last-5min");
	Result.Insert("DBMSCallDurations", "duration-all-dbms");
	Result.Insert("CurrentDBMSCallDuration", "duration-current-dbms");
	Result.Insert("DBMSCallDurationsIn5Minutes", "duration-last-3min-dbms");
	Result.Insert("DBMSConnection", "db-proc-info");
	Result.Insert("DBMSConnectionTime", "db-proc-took");
	Result.Insert("DBMSConnectionSeizeTime", "db-proc-took-at");
	
	Return New FixedStructure(Result);
	
EndFunction
 
// Returns a map of infobase connection property names for structures used in the API and
// object descriptions in the rac output.
//
// Returns: FixedStructure:
//           Key   - String - property name in the API (See
//                   ClusterAdministrationClientServer.ConnectionProperties()),
//           Value - String - object property name.
//
Function ConnectionPropertyDictionary()
	
	Result = New Structure();
	
	Result.Insert("Number", "conn-id");
	Result.Insert("UserName", "user-name");
	Result.Insert("ClientComputerName", "host");
	Result.Insert("ClientApplicationID", "app-id");
	Result.Insert("ConnectionEstablishingTime", "connected-at");
	Result.Insert("InfobaseConnectionMode", "ib-conn-mode");
	Result.Insert("DataBaseConnectionMode", "db-conn-mode");
	Result.Insert("DBMSLock", "blocked-by-dbms");
	Result.Insert("Passed", "bytes-all");
	Result.Insert("PassedIn5Minutes", "bytes-last-5min");
	Result.Insert("ServerCalls", "calls-all");
	Result.Insert("ServerCallsIn5Minutes", "calls-last-5min");
	Result.Insert("ExchangedWithDBMS", "dbms-bytes-all");
	Result.Insert("ExchangedWithDBMSIn5Minutes", "dbms-bytes-last-5min");
	Result.Insert("DBMSConnection", "db-proc-info");
	Result.Insert("DBMSTime", "db-proc-took");
	Result.Insert("DBMSConnectionSeizeTime", "db-proc-took-at");
	Result.Insert("ServerCallDurations", "duration-all");
	Result.Insert("DBMSCallDurations", "duration-all-dbms");
	Result.Insert("CurrentServerCallDuration", "duration-current");
	Result.Insert("CurrentDBMSCallDuration", "duration-current-dbms");
	Result.Insert("ServerCallDurationsIn5Minutes", "duration-last-5min");
	Result.Insert("DBMSCallDurationsIn5Minutes", "duration-last-5min-dbms");
	
	Return New FixedStructure(Result);
	
EndFunction
 
// Returns a map of security profile property names for structures used in the API and object
// descriptions in the rac output.
//
// Returns: FixedStructure:
//           Key   - String - property name in the API (See
//                   ClusterAdministrationClientServer.SecurityProfileProperties()),
//           Value - String - object property name.
//
Function SecurityProfilePropertyDictionary(Val IncludingAccessControlListUsageProperties =  True)
	
	Result = New Structure();
	
	Result.Insert("Name", "name");
	Result.Insert("Description", "descr");
	Result.Insert("SafeModeProfile", "config");
	Result.Insert("FullAccessToPrivilegedMode", "priv");
	
	If IncludingAccessControlListUsageProperties Then
		
		UsagePropertyDictionaryForAccessControlLists = UsagePropertyDictionaryForAccessControlList();
		
		For Each DictionaryFragment In UsagePropertyDictionaryForAccessControlLists Do
			Result.Insert(DictionaryFragment.Key, DictionaryFragment.Value);
		EndDo;
		
	EndIf;
	
 	Return New FixedStructure(Result);

	
EndFunction

// Returns a map of security profile property names for structures used in the API and object
// descriptions in the rac output.
//
// Returns: FixedStructure:
//          Key   - String - property name in the API (See
//                  ClusterAdministrationClientServer.SecurityProfileProperties()),
//          Value - String - object property name.
//
Function  UsagePropertyDictionaryForAccessControlList()
	
	Result = New  Structure();
	
	Result.Insert("FullFileSystemAccess", "directory");
	Result.Insert("FullCOMObjectAccess", "com");
	Result.Insert("FullAddInAccess", "addin");
	Result.Insert("FullExternalModuleAccess", "module");
	Result.Insert("FullOperatingSystemApplicationAccess", "app");
	Result.Insert("FullInternetResourceAccess", "inet");
	
	Return New FixedStructure(Result);
	
EndFunction
 
// Returns a map of virtual directory property names for structures used in the API and object
// descriptions in the rac output.
//
// Returns: FixedStructure:
//           Key   - String - property name in the API (See
//                   ClusterAdministrationClientServer.VirtualDirectoryProperties()),
//           Value - String - object property name.
//
Function VirtualDirectoryPropertyDictionary()
	
	Result = New Structure();
	
	Result.Insert("LogicalURL", "alias");
	Result.Insert("PhysicalURL", "physicalPath");
	
	Result.Insert("Description", "descr");
	
	Result.Insert("DataReading", "allowedRead");
	Result.Insert("DataWriting", "allowedWrite");
	
	Return New FixedStructure(Result);
	
EndFunction
 
// Returns a map of COM class property names for structures used in the API and object
// descriptions in the rac output.
//
// Returns: FixedStructure:
//           Key   - String - property name in the API (See
//                   ClusterAdministrationClientServer.COMClassProperties()),
//           Value - String - object property name.
//
Function COMClassPropertyDictionary()
	
	Result = New Structure();
	
	Result.Insert("Name", "name");
	Result.Insert("Description", "descr");
	
	Result.Insert("FileMoniker", "fileName");
	Result.Insert("CLSID", "id");
	Result.Insert("Computer", "host");
	
	Return New  FixedStructure(Result);
	
EndFunction
 
// Returns a map of add-in property names for structures used in the API and object
// descriptions in the rac output.
//
// Returns: FixedStructure:
//           Key   - String - property name in the API (See
//                   ClusterAdministrationClientServer.AddInProperties()),
//           Value - String - object property name.
//
Function AddInPropertyDictionary()
	
	Result = New  Structure();
	
	Result.Insert("Name", "name");
	Result.Insert("Description", "descr");
	
	Result.Insert("HashSum", "hash");
	
	Return New  FixedStructure(Result);
	
EndFunction
 
// Returns a map of external module property names for structures used in the API and object
// descriptions in the rac output.
//
// Returns: FixedStructure:
//           Key   - String - property name in the API (See
//                   ClusterAdministrationClientServer.ExternalModuleProperties()),
//           Value - String - object property name.
//
Function ExternalModulePropertyDictionary()
	
	Result = New Structure();
	
	Result.Insert("Name",  "name");
	Result.Insert("Description", "descr");
	
	Result.Insert("HashSum", "hash");
	
	Return New FixedStructure(Result);
	
EndFunction

// Returns a map of OS application property names for structures used in the API and object
// descriptions in the rac output.
//
// Returns: FixedStructure:
//           Key   - String - property name in the API (See
//                   ClusterAdministrationClientServer.OSApplicationProperties()),
//           Value - String - object property name.
//
Function OSApplicationPropertyDictionary()
	
	Result = New Structure();
	
	Result.Insert("Name",  "name");
	Result.Insert("Description", "descr");
	
	Result.Insert("CommandLinePattern", "wild");
	
	Return New FixedStructure(Result);
	
EndFunction
 
// Returns a map of Internet resource property names for structures used in the API and object
// descriptions in the rac output.
//
// Returns: FixedStructure:
//           Key   - String - property name in the API (See
//                   ClusterAdministrationClientServer.InternetResourceProperties()),
//           Value - String - object property name.
//
Function InternetResourcePropertyDictionary()
	
	Result = New Structure();
	
	Result.Insert("Name", "name");
	Result.Insert("Description", "descr");
	
	Result.Insert("Protocol", "protocol");
	Result.Insert("URL", "url");
	Result.Insert("Port", "port");
	
	Return New FixedStructure(Result);
	
EndFunction
 
// Returns names of the key acl properties (in the rac utility notation).
//
// Returns: FixedStructure:
//           Key   - String - acl name.
//           Value - String - name of the key property.
//
Function AccessControlListKeys()
	
	Result = New  Structure();
	
	Result.Insert("directory", "alias");
	Result.Insert("com", "name");
	Result.Insert("addin", "name");
	Result.Insert("module", "name");
	Result.Insert("inet", "name");
	
	Return New FixedStructure(Result);
	
EndFunction
 
// Returns the rules for formatting boolean properties according to the rac utility notation.
//
// Returns: FixedMap:
//           Key   - String - property name.
//           Value - String - format string for property values.
//
Function BooleanPropertyFormatDictionary()
	
	OnOffFormat = "BF=off; BT=on";
	YesNoFormat = "BF=no; BT=yes";
	
	Result = New Map();
	
	// Session and job lock properties
	Dictionary =  SessionAndScheduledJobLockPropertyDictionary();
	Result.Insert(Dictionary.SessionsLock, OnOffFormat);
	Result.Insert(Dictionary.ScheduledJobLock,  OnOffFormat);
	
	// Security profile properties
	Dictionary =  SecurityProfilePropertyDictionary(False);
	Result.Insert(Dictionary.SafeModeProfile, YesNoFormat);
	Result.Insert(Dictionary.FullAccessToPrivilegedMode, YesNoFormat);
	
	// Virtual directory properties
	Dictionary =  VirtualDirectoryPropertyDictionary();
	Result.Insert(Dictionary.DataReading, YesNoFormat);
	Result.Insert(Dictionary.DataWriting, YesNoFormat);
	
	Return New FixedMap(Result);
	
EndFunction

#EndRegion

#EndIf