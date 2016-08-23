////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
// Common server procedures and function for working with:
// - server cluster program administration using the V8*.ComConnector COMobject.
//
/////////////////////////////////////////////////////////////////////////////////
 
#Region InternalInterface

#Region SessionAndJobLock
 
// Returns the current state of the infobase session and scheduled job lock.
//
// Parameters:
// ClusterAdministrationParameters  - Structure - describes the parameters for connecting the
//                                    server cluster, for description, see
//                                    ClusterAdministrationClientServer.ClusterAdministrationParameters(),
// InfobaseAdministrationParameters - Structure - describes the parameters for connecting the
//                                    infobase, for description, see
//                                     ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters().
//
// Returns: Structure - describes the states of the session and background job lock, for
//    description, see ClusterAdministrationClientServer.SessionAndScheduleJobLockProperties().
//
Function  InfobaseSessionAndJobLock(Val ClusterAdministrationParameters, Val  InfobaseAdministrationParameters) Export
	
	COMConnector = COMConnector();
	
	ServerAgentConnection = ServerAgentConnection(
		COMConnector,
		ClusterAdministrationParameters.ServerAgentAddress,
		ClusterAdministrationParameters.ServerAgentPort);
	
	Cluster = GetCluster(
		ServerAgentConnection,
		ClusterAdministrationParameters.ClusterPort,
		ClusterAdministrationParameters.ClusterAdministratorName,
		ClusterAdministrationParameters.ClusterAdministratorPassword);
	
	WorkingProcessConnection =  WorkingProcessConnection(COMConnector, ServerAgentConnection,  Cluster);
	
	Infobase = GetInfobase(
		WorkingProcessConnection,
		Cluster,
		InfobaseAdministrationParameters.NameInCluster,
		InfobaseAdministrationParameters.InfobaseAdministratorName,
		InfobaseAdministrationParameters.InfobaseAdministratorPassword);
	
	Result =  COMAdministratorObjectModelObjectDetails(
		Infobase,
		SessionAndScheduledJobLockPropertyDictionary());
	
	Return Result;
	
EndFunction
 
// Sets the state of the infobase session and scheduled job lock.
//
// Parameters:
// ClusterAdministrationParameters  - Structure - describes the parameters for connecting the
//                                    server cluster, for description, see
//                                    ClusterAdministrationClientServer.ClusterAdministrationParameters(),
// InfobaseAdministrationParameters - Structure - describes the parameters for connecting the
//                                    infobase, for description, see
//                                    ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters(),
// SessionAndJobLockProperties      - Structure - describes the states of the session and
//                                    background job lock, for description, see
//                                    ClusterAdministrationClientServer.SessionAndScheduleJobLockProperties().
//
Procedure  SetInfobaseSessionAndJobLock(Val  ClusterAdministrationParameters, Val InfobaseAdministrationParameters,  Val SessionAndJobLockProperties) Export
	
	COMConnector = COMConnector();
	
	ServerAgentConnection = ServerAgentConnection(
		COMConnector,
		ClusterAdministrationParameters.ServerAgentAddress,
		ClusterAdministrationParameters.ServerAgentPort);
	
	Cluster = GetCluster(
		ServerAgentConnection,
		ClusterAdministrationParameters.ClusterPort,
		ClusterAdministrationParameters.ClusterAdministratorName,
		ClusterAdministrationParameters.ClusterAdministratorPassword);
	
	WorkingProcessConnection = WorkingProcessConnection(COMConnector, ServerAgentConnection,  Cluster);
	
	Infobase = GetInfobase(
		WorkingProcessConnection,
		Cluster,
		InfobaseAdministrationParameters.NameInCluster,
		InfobaseAdministrationParameters.InfobaseAdministratorName,
		InfobaseAdministrationParameters.InfobaseAdministratorPassword);
	
	a = Infobase.SessionsDenied;
	
	FillCOMAdministratorObjectModelObjectPropertiesByDeclaration(
		Infobase,
		SessionAndJobLockProperties,
		SessionAndScheduledJobLockPropertyDictionary());
	
	WorkingProcessConnection.UpdateInfobase(Infobase);
	
EndProcedure
 
// Checks whether administration parameters are filled correctly.
//
// Parameters:
//  ClusterAdministrationParameters       - Structure - describes the parameters for connecting
//                                          the server cluster, for description, see
//                                          ClusterAdministrationClientServer.ClusterAdministrationParameters(),
//  InfobaseAdministrationParameters      - Structure - describes the parameters for connecting
//                                          the infobase, for description, see
//                                          ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters().
//                                          The parameters can be skipped if the corresponding
//                                          fields are specified in the structure passed as the
//                                          SessionAndJobLockProperties parameter value, 
//  CheckClusterAdministrationParameters  - Boolean - flag that shows whether the cluster
//                                          administration parameters must be checked,
//  CheckInfobaseAdministrationParameters - Boolean - flag that shows whether the infobase
//                                          administration parameters must be checked.
//
Procedure  CheckAdministrationParameters(Val ClusterAdministrationParameters, Val InfobaseAdministrationParameters  = Undefined,
	CheckInfobaseAdministrationParameters = True,
	CheckClusterAdministrationParameters =  True) Export
	
	If CheckClusterAdministrationParameters  Or  CheckInfobaseAdministrationParameters Then
		
		COMConnector = COMConnector();
	
		ServerAgentConnection =  ServerAgentConnection(
			COMConnector,
			ClusterAdministrationParameters.ServerAgentAddress,
			ClusterAdministrationParameters.ServerAgentPort);
		
		Cluster = GetCluster(
			ServerAgentConnection,
			ClusterAdministrationParameters.ClusterPort,
			ClusterAdministrationParameters.ClusterAdministratorName,
			ClusterAdministrationParameters.ClusterAdministratorPassword);
		
	EndIf;
	
	If  CheckInfobaseAdministrationParameters Then
		
		WorkingProcessConnection = WorkingProcessConnection(COMConnector, ServerAgentConnection,  Cluster);
		
		Infobase = GetInfobase(
			WorkingProcessConnection,
			Cluster,
			InfobaseAdministrationParameters.NameInCluster,
			InfobaseAdministrationParameters.InfobaseAdministratorName,
			InfobaseAdministrationParameters.InfobaseAdministratorPassword);
		
	EndIf;
	
EndProcedure

#EndRegion
 
#Region ScheduledJobLock

// Returns the current state of infobase scheduled job lock.
//
// Parameters:
// ClusterAdministrationParameters  - Structure - describes the parameters for connecting the 
//                                    server cluster, for description, see
//                                    ClusterAdministrationClientServer.ClusterAdministrationParameters(),
// InfobaseAdministrationParameters - Structure - describes the parameters for connecting the
//                                    infobase, for description, see
//                                    ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters().
//
// Returns: Boolean.
//
Function  InfobaseScheduledJobLock(Val ClusterAdministrationParameters, Val  InfobaseAdministrationParameters) Export
	
	COMConnector = COMConnector();
	
	ServerAgentConnection =  ServerAgentConnection(
		COMConnector,
		ClusterAdministrationParameters.ServerAgentAddress,
		ClusterAdministrationParameters.ServerAgentPort);
	
	Cluster = GetCluster(
		ServerAgentConnection,
		ClusterAdministrationParameters.ClusterPort,
		ClusterAdministrationParameters.ClusterAdministratorName,
		ClusterAdministrationParameters.ClusterAdministratorPassword);
	
	WorkingProcessConnection = WorkingProcessConnection(COMConnector, ServerAgentConnection,  Cluster);
	
	Infobase = GetInfobase(
		WorkingProcessConnection,
		Cluster,
		InfobaseAdministrationParameters.NameInCluster,
		InfobaseAdministrationParameters.InfobaseAdministratorName,
		InfobaseAdministrationParameters.InfobaseAdministratorPassword);
 	

	Return Infobase.ScheduledJobsDenied;
	
EndFunction
 
// Sets the state of the infobase scheduled job lock.
//
// Parameters:
// ClusterAdministrationParameters  - Structure - describes the parameters for connecting the
//                                    server cluster, for description, see
//                                    ClusterAdministrationClientServer.ClusterAdministrationParameters(),
// InfobaseAdministrationParameters - Structure - describes the parameters for connecting the
//                                    infobase, for description, see
//                                    ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters(),
// ScheduledJobLock                 - Boolean - flag that shows whether infobase scheduled jobs
//                                    are locked.
//
Procedure  LockInfobaseScheduledJobs(Val ClusterAdministrationParameters, Val InfobaseAdministrationParameters, Val ScheduledJobLock) Export
	
	COMConnector = COMConnector();
	
	ServerAgentConnection = ServerAgentConnection(
		COMConnector,
		ClusterAdministrationParameters.ServerAgentAddress,
		ClusterAdministrationParameters.ServerAgentPort);
	
	Cluster = GetCluster(
		ServerAgentConnection,
		ClusterAdministrationParameters.ClusterPort,
		ClusterAdministrationParameters.ClusterAdministratorName,
		ClusterAdministrationParameters.ClusterAdministratorPassword);
	
	WorkingProcessConnection = WorkingProcessConnection(COMConnector, ServerAgentConnection,  Cluster);
	
	Infobase = GetInfobase(
		WorkingProcessConnection,
		Cluster,
		InfobaseAdministrationParameters.NameInCluster,
		InfobaseAdministrationParameters.InfobaseAdministratorName,
		InfobaseAdministrationParameters.InfobaseAdministratorPassword);
	
	Infobase.ScheduledJobsDenied = ScheduledJobLock;
	WorkingProcessConnection.UpdateInfobase(Infobase);
	
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
Function InfobaseSessions(Val  ClusterAdministrationParameters, Val InfobaseAdministrationParameters, Val Filter = Undefined) Export
	
	COMConnector = COMConnector();
	
	ServerAgentConnection = ServerAgentConnection(
		COMConnector,
		ClusterAdministrationParameters.ServerAgentAddress,
		ClusterAdministrationParameters.ServerAgentPort);
	
	Cluster = GetCluster(
		ServerAgentConnection,
		ClusterAdministrationParameters.ClusterPort,
		ClusterAdministrationParameters.ClusterAdministratorName,
		ClusterAdministrationParameters.ClusterAdministratorPassword);
	
	InfobaseDescription = GetInfobaseDescription(
		ServerAgentConnection,
		Cluster,
		InfobaseAdministrationParameters.NameInCluster);
	
	Return GetSessions(ServerAgentConnection,  Cluster, InfobaseDescription, Filter, True);
	
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
Procedure DeleteInfobaseSessions(Val  ClusterAdministrationParameters, Val InfobaseAdministrationParameters, Val Filter = Undefined) Export
	
	COMConnector = COMConnector();
	
	ServerAgentConnection = ServerAgentConnection(
		COMConnector,
		ClusterAdministrationParameters.ServerAgentAddress,
		ClusterAdministrationParameters.ServerAgentPort);
	
	Cluster = GetCluster(
		ServerAgentConnection,
		ClusterAdministrationParameters.ClusterPort,
		ClusterAdministrationParameters.ClusterAdministratorName,
		ClusterAdministrationParameters.ClusterAdministratorPassword);
	
	InfobaseDescription =  GetInfobaseDescription(
		ServerAgentConnection,
		Cluster,
		InfobaseAdministrationParameters.NameInCluster);
	
	Sessions = GetSessions(ServerAgentConnection,  Cluster, InfobaseDescription, Filter, False);
	
	For Each Session In Sessions Do
		
		Try
			
			ServerAgentConnection.TerminateSession(Cluster, Session);
			
		Except
			
			// The session could already be closed when TerminateSession is called
			
			SessionFilter = New  Structure("Number", Session.Number);
			
			If GetSessions(ServerAgentConnection,  Cluster, InfobaseDescription, SessionFilter, False).Count() > 0  Then
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
Function InfobaseConnection(Val  ClusterAdministrationParameters, Val InfobaseAdministrationParameters,  Val Filter = Undefined) Export
	
	COMConnector = COMConnector();
	
	ServerAgentConnection =  ServerAgentConnection(
		COMConnector,
		ClusterAdministrationParameters.ServerAgentAddress,
		ClusterAdministrationParameters.ServerAgentPort);
	
	Cluster = GetCluster(
		ServerAgentConnection,
		ClusterAdministrationParameters.ClusterPort,
		ClusterAdministrationParameters.ClusterAdministratorName,
		ClusterAdministrationParameters.ClusterAdministratorPassword);
	
	Return GetConnections(
		COMConnector,
		ServerAgentConnection,
		Cluster,
		InfobaseAdministrationParameters.NameInCluster,
		InfobaseAdministrationParameters.InfobaseAdministratorName,
		InfobaseAdministrationParameters.InfobaseAdministratorPassword,
		Filter,
		True);
	
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
Procedure TerminateInfobaseConnection(Val ClusterAdministrationParameters, Val  InfobaseAdministrationParameters, Val Filter = Undefined) Export
	
	COMConnector = COMConnector();
	
	ServerAgentConnection = ServerAgentConnection(
		COMConnector,
		ClusterAdministrationParameters.ServerAgentAddress,
		ClusterAdministrationParameters.ServerAgentPort);
	
	Cluster = GetCluster(
		ServerAgentConnection,
		ClusterAdministrationParameters.ClusterPort,
		ClusterAdministrationParameters.ClusterAdministratorName,
		ClusterAdministrationParameters.ClusterAdministratorPassword);
	
	ProcessesAndConnections = GetConnections(
		COMConnector,
		ServerAgentConnection,
		Cluster,
		InfobaseAdministrationParameters.NameInCluster,
		InfobaseAdministrationParameters.InfobaseAdministratorName,
		InfobaseAdministrationParameters.InfobaseAdministratorPassword,
		Filter,
		False);
	
	For Each  ProcessAndConnection In ProcessesAndConnections Do
		
		Try
			
			ProcessAndConnection.WorkingProcessConnection.Disconnect(ProcessAndConnection.Connection);
			
		Except
			
			// The connection could already be closed when Disconnect is called
			
			ConnectionFilter = New Structure("Number", ProcessAndConnection.Connection.Number);
			
			ConnectionDescriptions = GetConnections(
				COMConnector,
				ServerAgentConnection,
				Cluster,
				InfobaseAdministrationParameters.NameInCluster,
				InfobaseAdministrationParameters.InfobaseAdministratorName,
				InfobaseAdministrationParameters.InfobaseAdministratorPassword,
				ConnectionFilter);
			
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
	
	COMConnector = COMConnector();
	
	ServerAgentConnection = ServerAgentConnection(
		COMConnector,
		ClusterAdministrationParameters.ServerAgentAddress,
		ClusterAdministrationParameters.ServerAgentPort);
	
	Cluster = GetCluster(
		ServerAgentConnection,
		ClusterAdministrationParameters.ClusterPort,
		ClusterAdministrationParameters.ClusterAdministratorName,
		ClusterAdministrationParameters.ClusterAdministratorPassword);
	
	WorkingProcessConnection = WorkingProcessConnection(COMConnector, ServerAgentConnection,  Cluster);
	
	Infobase = GetInfobase(
		WorkingProcessConnection,
		Cluster,
		InfobaseAdministrationParameters.NameInCluster,
		InfobaseAdministrationParameters.InfobaseAdministratorName,
		InfobaseAdministrationParameters.InfobaseAdministratorPassword);
	
	If ValueIsFilled(Infobase.SecurityProfileName) Then
		Result = Infobase.SecurityProfileName;
	Else
		Result = "";
	EndIf;
	
	Infobase = Undefined;
	WorkingProcessConnection = Undefined;
	Cluster = Undefined;
	ServerAgentConnection = Undefined;
	COMConnector = Undefined;
	
	Return Result;
	
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
	
	COMConnector = COMConnector();
	
	ServerAgentConnection =  ServerAgentConnection(
		COMConnector,
		ClusterAdministrationParameters.ServerAgentAddress,
		ClusterAdministrationParameters.ServerAgentPort);
	
	Cluster = GetCluster(
		ServerAgentConnection,
		ClusterAdministrationParameters.ClusterPort,
		ClusterAdministrationParameters.ClusterAdministratorName,
		ClusterAdministrationParameters.ClusterAdministratorPassword);
	
	WorkingProcessConnection =  WorkingProcessConnection(COMConnector, ServerAgentConnection,  Cluster);
	
	Infobase = GetInfobase(
		WorkingProcessConnection,
		Cluster,
		InfobaseAdministrationParameters.NameInCluster,
		InfobaseAdministrationParameters.InfobaseAdministratorName,
		InfobaseAdministrationParameters.InfobaseAdministratorPassword);
	
	If ValueIsFilled(Infobase.SafeModeSecurityProfileName) Then
		Result = Infobase.SafeModeSecurityProfileName;
	Else
		Result = "";
	EndIf;
	
	Infobase = Undefined;
	WorkingProcessConnection = Undefined;
	Cluster = Undefined;
	ServerAgentConnection = Undefined;
	COMConnector = Undefined;
	
	Return Result;
	
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
	
	COMConnector = COMConnector();
	
	ServerAgentConnection = ServerAgentConnection(
		COMConnector,
		ClusterAdministrationParameters.ServerAgentAddress,
		ClusterAdministrationParameters.ServerAgentPort);
	
	Cluster = GetCluster(
		ServerAgentConnection,
		ClusterAdministrationParameters.ClusterPort,
		ClusterAdministrationParameters.ClusterAdministratorName,
		ClusterAdministrationParameters.ClusterAdministratorPassword);
	
	WorkingProcessConnection =  WorkingProcessConnection(COMConnector, ServerAgentConnection,  Cluster);
	
	Infobase = GetInfobase(
		WorkingProcessConnection,
		Cluster,
		InfobaseAdministrationParameters.NameInCluster,
		InfobaseAdministrationParameters.InfobaseAdministratorName,
		InfobaseAdministrationParameters.ClusterAdministratorPassword);
	
	Infobase.SecurityProfileName = ProfileName;
	
	WorkingProcessConnection.UpdateInfobase(Infobase);
	
	Infobase = Undefined;
	WorkingProcessConnection = Undefined;
	Cluster = Undefined;
	ServerAgentConnection = Undefined;
	COMConnector = Undefined
	
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
Procedure SetInfobaseSafeModeSecurityProfile(Val ClusterAdministrationParameters, Val InfobaseAdministrationParameters, Val ProfileName = "") Export
	
	COMConnector = COMConnector();
	
	ServerAgentConnection = ServerAgentConnection(
		COMConnector,
		ClusterAdministrationParameters.ServerAgentAddress,
		ClusterAdministrationParameters.ServerAgentPort);
	
	Cluster = GetCluster(
		ServerAgentConnection,
		ClusterAdministrationParameters.ClusterPort,
		ClusterAdministrationParameters.ClusterAdministratorName,
		ClusterAdministrationParameters.ClusterAdministratorPassword);
	
	WorkingProcessConnection = WorkingProcessConnection(COMConnector, ServerAgentConnection,  Cluster);
	
	Infobase = GetInfobase(
		WorkingProcessConnection,
		Cluster,
		InfobaseAdministrationParameters.NameInCluster,
		InfobaseAdministrationParameters.InfobaseAdministratorName,
		InfobaseAdministrationParameters.ClusterAdministratorPassword);
	
	Infobase.SafeModeSecurityProfileName = ProfileName;
	
	WorkingProcessConnection.UpdateInfobase(Infobase);
	
	Infobase = Undefined;
	WorkingProcessConnection = Undefined;
	Cluster = Undefined;
	ServerAgentConnection = Undefined;
	COMConnector = Undefined
	
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
Function SecurityProfileExists(Val  ClusterAdministrationParameters, Val ProfileName) Export
	
	COMConnector = COMConnector();
	
	ServerAgentConnection = ServerAgentConnection(
		COMConnector,
		ClusterAdministrationParameters.ServerAgentAddress,
		ClusterAdministrationParameters.ServerAgentPort);
	
	Cluster = GetCluster(
		ServerAgentConnection,
		ClusterAdministrationParameters.ClusterPort,
		ClusterAdministrationParameters.ClusterAdministratorName,
		ClusterAdministrationParameters.ClusterAdministratorPassword);
	
	For Each SecurityProfile In ServerAgentConnection.GetSecurityProfiles(Cluster) Do
		
		If SecurityProfile.Name = ProfileName Then
			Return True;
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction
 
// Returns security profile properties.
//
// Parameters:
//  ClusterAdministrationParameters - Structure - describes the parameters for connecting the 
//                                    server cluster, for details, see
//                                    ClusterAdministrationClientServer.ClusterAdministrationParameters(),
//  ProfileName                     - String - name of the security profile.
//
// Returns: Structure - describes the security profile, for details see
//          ClusterAdministrationClientServer.SecurityProfileProperties().
//
Function SecurityProfile(Val  ClusterAdministrationParameters, Val ProfileName) Export
	
	COMConnector = COMConnector();
	
	ServerAgentConnection = ServerAgentConnection(
		COMConnector,
		ClusterAdministrationParameters.ServerAgentAddress,
		ClusterAdministrationParameters.ServerAgentPort);
	
	Cluster = GetCluster(
		ServerAgentConnection,
		ClusterAdministrationParameters.ClusterPort,
		ClusterAdministrationParameters.ClusterAdministratorName,
		ClusterAdministrationParameters.ClusterAdministratorPassword);
	
	SecurityProfile = GetSecurityProfile(ServerAgentConnection, Cluster, ProfileName);
	
	Result = COMAdministratorObjectModelObjectDetails(
		SecurityProfile,
		SecurityProfilePropertyDictionary());
	
	// Virtual directories
	Result.Insert("VirtualDirectories",
		COMAdministratorObjectModelObjectDescriptions(
			GetVirtualDirectories(ServerAgentConnection, Cluster, ProfileName),
			VirtualDirectoryPropertyDictionary()));
	
	// Allowed COM classes
	Result.Insert("COMClasses",
		COMAdministratorObjectModelObjectDescriptions(
			GetCOMClasses(ServerAgentConnection, Cluster, ProfileName),
			COMClassPropertyDictionary()));
	
	// Add-ins
	Result.Insert("AddIns",
		COMAdministratorObjectModelObjectDescriptions(
			GetAddIns(ServerAgentConnection, Cluster, ProfileName),
			AddInPropertyDictionary()));
	
	// External modules
	Result.Insert("ExternalModules",
		COMAdministratorObjectModelObjectDescriptions(
			GetExternalModules(ServerAgentConnection, Cluster, ProfileName),
			ExternalModulePropertyDictionary()));
	
	// OS applications
	Result.Insert("OSApplications",
		COMAdministratorObjectModelObjectDescriptions(
			GetOSApplications(ServerAgentConnection, Cluster, ProfileName),
			OSApplicationPropertyDictionary()));
	
	// Internet resources
	Result.Insert("InternetResources",
		COMAdministratorObjectModelObjectDescriptions(
			GetInternetResources(ServerAgentConnection, Cluster, ProfileName),
			InternetResourcePropertyDictionary()));
	
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
Procedure CreateSecurityProfile(Val  ClusterAdministrationParameters, Val SecurityProfileProperties) Export
	
	COMConnector = COMConnector();
	
	ServerAgentConnection = ServerAgentConnection(
		COMConnector,
		ClusterAdministrationParameters.ServerAgentAddress,
		ClusterAdministrationParameters.ServerAgentPort);
	
	Cluster = GetCluster(
		ServerAgentConnection,
		ClusterAdministrationParameters.ClusterPort,
		ClusterAdministrationParameters.ClusterAdministratorName,
		ClusterAdministrationParameters.ClusterAdministratorPassword);
	
	SecurityProfile =  ServerAgentConnection.CreateSecurityProfile();
	ApplySecurityProfilePropertyChanges(ServerAgentConnection,  Cluster, SecurityProfile,  SecurityProfileProperties);
	
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
	
	COMConnector = COMConnector();
	
	ServerAgentConnection =  ServerAgentConnection(
		COMConnector,
		ClusterAdministrationParameters.ServerAgentAddress,
		ClusterAdministrationParameters.ServerAgentPort);
	
	Cluster = GetCluster(
		ServerAgentConnection,
		ClusterAdministrationParameters.ClusterPort,
		ClusterAdministrationParameters.ClusterAdministratorName,
		ClusterAdministrationParameters.ClusterAdministratorPassword);
	
	SecurityProfile =  GetSecurityProfile(
		ServerAgentConnection,
		Cluster,
		SecurityProfileProperties.Name);
	
	ApplySecurityProfilePropertyChanges(ServerAgentConnection,  Cluster, SecurityProfile,  SecurityProfileProperties);
	
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
	
	COMConnector = COMConnector();
	
	ServerAgentConnection = ServerAgentConnection(
		COMConnector,
		ClusterAdministrationParameters.ServerAgentAddress,
		ClusterAdministrationParameters.ServerAgentPort);
	
	Cluster = GetCluster(
		ServerAgentConnection,
		ClusterAdministrationParameters.ClusterPort,
		ClusterAdministrationParameters.ClusterAdministratorName,
		ClusterAdministrationParameters.ClusterAdministratorPassword);
	
	SecurityProfile = GetSecurityProfile(
		ServerAgentConnection,
		Cluster,
		ProfileName);
	
	ServerAgentConnection.UnregSecurityProfile(Cluster, ProfileName);
	
EndProcedure

#EndRegion
 
#EndRegion

#Region InternalProceduresAndFunctions

// Creates the V8*.ComConnector COM object.
//
// Returns: COMObject.
//
Function COMConnector()
	
	#If Client Then
		Return New  COMObject(StandardSubsystemsClientCached.ClientParameters().COMConnectorName);
	#Else
		
		If SafeMode()  Then
			Raise NStr("en = 'Cannot administrate cluster in the safe mode.'");
		EndIf;
		
		If CommonUseCached.DataSeparationEnabled() Then
			Raise NStr("en = 'The applied infobase in the SaaS mode cannot administer the cluster.'");
		EndIf;
		
		Return New  COMObject(CommonUse.COMConnectorName());
		
	#EndIf
	
EndFunction
 
// Establishes a connection with the server agent.
//
// Parameters:
//  COMConnector       - V8*.ComConnector COM object, 
//  ServerAgentAddress - String - network address of the server address, 
//  ServerAgentPort    - Number - server agent port (usually is 1540).
//
// Returns: COMObject that implements the IV8AgentConnection interface.
//
Function ServerAgentConnection(COMConnector, Val ServerAgentAddress, Val ServerAgentPort)
	
	ServerAgentConnectionString = "tcp://" + ServerAgentAddress + ":" + Format(ServerAgentPort, "NG=0");
	ServerAgentConnection = COMConnector.ConnectAgent(ServerAgentConnectionString);
	Return ServerAgentConnection;
	
EndFunction
 
// Returns the server cluster.
//
// Parameters:
//  ServerAgentConnection        - COMObject - implements the IV8AgentClusterConnection 
//                                 interface, 
//  Port                         - Network - cluster manager port (usually is 1541), 
//  ClusterAdministratorName     - String - name of the cluster administrative account,
//  ClusterAdministratorPassword - String - password for the cluster administrative account.
//
// Returns: COMObject that implements the IClusterInfo interface.
//
Function GetCluster(ServerAgentConnection, Val ClusterPort, Val ClusterAdministratorName, Val ClusterAdministratorPassword)
	
	For Each Cluster In ServerAgentConnection.GetClusters() Do
		
		If Cluster.MainPort = ClusterPort Then
			
			ServerAgentConnection.Authenticate(Cluster, ClusterAdministratorName,  ClusterAdministratorPassword);
			
			Return Cluster;
			
		EndIf;
		
	EndDo;
	
	Raise StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en = 'The %2 cluster is not found on the %1 working server'"),
		ServerAgentConnection.ConnectionString,
		ClusterPort);
	
EndFunction
 
// Established a connection with the working process.
//
// Parameters:
//  COMConnector          - V8*.ComConnector COMObject, 
//  ServerAgentConnection - COMObject - implements the IV8AgentConnection interface,
//  Cluster               - COMObject - implements the IClusterInfo interface.
//
// Returns: COMObject that implements the IV8ServerConnection interface.
//
Function WorkingProcessConnection(COMConnector, ServerAgentConnection, Cluster)
	
	For Each WorkingProcess In ServerAgentConnection.GetWorkingProcesses(Cluster) Do
		If WorkingProcess.Running Then
			WorkingProcessConnectionString = WorkingProcess.HostName + ":" + Format(WorkingProcess.MainPort, "NG=");
			Return COMConnector.ConnectWorkingProcess(WorkingProcessConnectionString);
		EndIf;
	EndDo;
	
	Raise  StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en = 'Active working processes are not found in the %1:%2 server cluster.'"),
		Cluster.HostName,
		Format(Cluster.MainPort, "NG=0"));
	
EndFunction

// Returns the infobase description.
//
// Parameters:
//  ServerAgentConnection - COMObject - implements the IV8AgentConnection interface,
//  Cluster               - COMObject - implements the IClusterInfo interface, 
//  NameInCluster         - String - name of the infobase in the server cluster.
//
// Returns: COMObject that implements the IInfobaseShort interface.
//
Function GetInfobaseDescription(ServerAgentConnection, Cluster, Val NameInCluster)
	
	For Each  InfobaseDescription In ServerAgentConnection.GetInfobases(Cluster) Do
		
		If InfobaseDescription.Name = NameInCluster Then
			
			Return InfobaseDescription;
			
		EndIf;
		
	EndDo;
	
	Raise StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en = 'The %3 Infobase is not found in the %1:%2 server cluster.'"),
		Cluster.HostName,
		Format(Cluster.MainPort, "NG=0"),
		NameInCluster
	);
	
EndFunction
 
// Returns the infobase.
//
// Parameters:
//  WorkingProcessConnection      - COMObject - implements the IV8ServerConnection interface, 
//  Cluster                       - COMObject - implements the IClusterInfo interface, 
//  NameInCluster                 - String - name of the infobase in the server cluster, 
//  InfobaseAdministratorName     - String - infobase administrator name, 
//  InfobaseAdministratorPassword - String - infobase administrator password.
//
// Returns: COMObject that implements the IInfobaseInfo interface.
//
Function GetInfobase(WorkingProcessConnection,  Cluster, Val NameInCluster, Val InfobaseAdministratorName, Val InfobaseAdministratorPassword)
	
	WorkingProcessConnection.AddAuthentication(InfobaseAdministratorName,  InfobaseAdministratorPassword);
	
	For Each Infobase In WorkingProcessConnection.GetInfobases() Do
		
		If Infobase.Name = NameInCluster Then
			
			If Not ValueIsFilled(Infobase.DBMS) Then
				
				Raise StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en = 'Incorrect name or password of the %1 infobase in the %2:%3 server cluster (Name: %4).'"),
					NameInCluster,
					Cluster.HostName,  Cluster.MainPort,
					InfobaseAdministratorName);
				
			EndIf;
			
			Return Infobase;
			
		EndIf;
		
	EndDo;
	
	Raise  StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en = 'The %3 infobase is not found in the %1:%2 server cluster.'"),
		Cluster.HostName,
		Format(Cluster.MainPort, "NG=0"),
		NameInCluster
	);
	
EndFunction
 
// Returns the infobase sessions.
//
// Parameters:
//  ServerAgentConnection - COMObject - implements the IV8AgentConnection interface,
//  Cluster               - COMObject - implements the IClusterInfo interface, 
//  Infobase              - COMObject - that implements IInfobaseInfo interface, 
//  Filter                - details on the session filtering conditions whose descriptions are required. The following
//                          options are available:
//                          1. Array of structures that describe session filtering conditions. Fields of structures in
//                             the array are:
//                              Property       - String - property name to be used in the filter. For valid values see
//                                               the return value of the 
//                                               ClusterAdministrationClientServer.SessionProperties() function,
//                              ComparisonType - value of the ComparisonType system enumeration. The value comparison
//                                               type with the specified filter condition. Valid values are:
//                                                ComparisonType.Equal,
//                                                ComparisonType.NotEqual,
//                                                ComparisonType.Greater (for numeric values only),
//                                                ComparisonType.GreaterOrEqual (for numeric values only),
//                                                ComparisonType.Less (for numeric values only),
//                                                ComparisonType.LessOrEqual (for numeric values only),
//                                                ComparisonType.InList,
//                                                ComparisonType.NotInList,
//                                                ComparisonType.Interval (for numeric values only),
//                                                ComparisonType.IntervalIncludingBounds (for numeric values only),
//                                                ComparisonType.IntervalIncludingLowerBound (for numeric values only),
//                                                ComparisonType.IntervalIncludingUpperBound (for numeric values only),
//                              Value           - Number, String, Date, Boolean, ValueList, Array, Structure - value,
//                                                against which the corresponding session properties are compared. If
//                                                ComparisonType.InList or ComparisonType.NotInList, pass ValueList or
//                                                Array with a set of values against which the property is compared.
//                                                In case of ComparisonType.Interval,
//                                                ComparisonType.IntervalIncludingBounds,
//                                                ComparisonType.IntervalIncludingLowerBound, or
//                                                IntervalIncludingUpperBound, pass a structure with the From and To
//                                                fields whose values are interval against which the value is
//                                                compared,
//                          2. Structure (simplified), where key is a session property name (see above), value is a
//                             value, against which comparison is executed. When you use this description option, the
//                             comparison filter always checks for equality, 
//  Descriptions          - Boolean - if False is passed, the function returns an array of COM objects that implement
//                          the ISessionInfo interface, otherwise it returns Array of Structures that describe
//                          session properties (for structure fields see the return value of
//                          ClusterAdministrationClientServer.SessionProperties()).
//
// Returns: Array of COMObject or Array of Structure.
//
Function GetSessions(ServerAgentConnection, Cluster, Infobase, Val Filter = Undefined, Val Descriptions = False)
	
	Sessions = New Array;
	
	Dictionary = DictionaryPropertiesSessions();
	
	For Each Session In ServerAgentConnection.GetInfobaseSessions(Cluster, Infobase) Do
		
		SessionDescription = COMAdministratorObjectModelObjectDetails(Session, Dictionary);
		
		If ClusterAdministrationClientServer.CheckFilterConditions(SessionDescription, Filter) Then
			
			If Descriptions Then
				Sessions.Add(SessionDescription);
			Else
				Sessions.Add(Session);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return Sessions;
	
EndFunction
 
// Returns the infobase connections.
//
// Parameters:
//  COMConnector                  - V8*.ComConnector COMObject, 
//  ServerAgentConnection         - COMObject - implements the IV8AgentConnection interface,
//  Cluster                       - COMObject - implements the IClusterInfo interface, 
//  NameInCluster                 - String - name of the infobase in the server cluster, 
//  InfobaseAdministratorName     - String - infobase administrator name, 
//  InfobaseAdministratorPassword - String - infobase administrator password, 
//  Filter                        - details on the connection filtering conditions whose descriptions are required.
//                                  The following options are available:
//                                   1. Array of structures that describes connection filtering conditions. Fields of
//                                      structures in the array are:
//                                       Property       - String - property name to be used in the filter. Valid values
//                                                        are the return value of the
//                                                        ClusterAdministrationClientServer.ConnectionProperties()
//                                                        function,
//                                       ComparisonType - value of the ComparisonType system enumeration. The value
//                                                        comparison type with the specified filter condition. Valid
//                                                        values are:
//                                                         ComparisonType.Equal,
//                                                         ComparisonType.NotEqual,
//                                                         ComparisonType.Greater (for numeric values only),
//                                                         ComparisonType.GreaterOrEqual (for numeric values only),
//                                                         ComparisonType.Less (for numeric values only),
//                                                         ComparisonType.LessOrEqual (for numeric values only),
//                                                         ComparisonType.InList,
//                                                         ComparisonType.NotInList,
//                                                         ComparisonType.Interval (for numeric values only),
//                                                         ComparisonType.IntervalIncludingBounds (for numeric values only),
//                                                         ComparisonType.IntervalIncludingLowerBound (for numeric values only),
//                                                         ComparisonType.IntervalIncludingUpperBound (for numeric values only),
//                                       Value          - Number, String, Date, Boolean, ValueList, Array, Structure -
//                                                        value against which the corresponding connection property
//                                                        value is compared. If ComparisonType.InList or
//                                                        ComparisonType.NotInList, pass ValueList or Array with a set
//                                                        of values against which the property is compared. In case of
//                                                        ComparisonType.Interval,
//                                                        ComparisonType.IntervalIncludingBounds,
//                                                        ComparisonType.IntervalIncludingLowerBound, or
//                                                        IntervalIncludingUpperBound, pass a structure with the From
//                                                        and To fields whose values are interval against which the
//                                                        value is compared,
//                                   2. Structure (simplified), where key is a name of the connection property (see
//                                      above), value is a value, against which comparison is executed. When you use
//                                      this description option, the comparison filter always checks for equality,
//  Descriptions - Boolean - if False is passed, the function returns an array of COM objects that implement the
//                 IConnectionShort interface, otherwise it returns Array of structures that describe connection
//                 properties (for structure field details see the return value of
//                 ClusterAdministrationClientServer.ConnectionProperties()).
//
// Returns: Array of COMObject or Array of Structure.
//
Function GetConnections(COMConnector,  ServerAgentConnection, Cluster, Val NameInCluster, Val InfobaseAdministratorName, Val InfobaseAdministratorPassword, Val Filter = Undefined, Val Descriptions = False)
	
	Connections = New Array();
	Dictionary = ConnectionPropertyDictionary();
	
	For Each WorkingProcess In ServerAgentConnection.GetWorkingProcesses(Cluster) Do
		
		If WorkingProcess.Running Then
			
			WorkingProcessConnectionString = WorkingProcess.HostName + ":" + Format(WorkingProcess.MainPort, "NG=");
			WorkingProcessConnection =  COMConnector.ConnectWorkingProcess(WorkingProcessConnectionString);
			
			WorkingProcessConnection.AddAuthentication(InfobaseAdministratorName,  InfobaseAdministratorPassword);
			
			For Each Infobase In WorkingProcessConnection.GetInfobases() Do
				
				If Infobase.Name = NameInCluster Then
					
					For Each Connection In WorkingProcessConnection.GetInfobaseConnections(Infobase) Do
						
						ConnectionDescription = COMAdministratorObjectModelObjectDetails(Connection, Dictionary);
						
						If ClusterAdministrationClientServer.CheckFilterConditions(ConnectionDescription, Filter) Then
							
							If Descriptions Then
								Connections.Add(ConnectionDescription);
							Else
								Connections.Add(New Structure("WorkingProcessConnection, Connection",  WorkingProcessConnection, Connection));
							EndIf;
							
						EndIf;
					
					EndDo;
					
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	Return Connections;
	
EndFunction
 
// Returns the security profile.
//
// Parameters:
// ServerAgentConnection - COMObject - implements the IV8AgentConnection interface,
// Cluster               - COMObject - implements the IClusterInfo interface,
// ProfileName           - String - name of the security profile.
//
// Returns: COMObject that implements the ISecurityProfile interface.
//
Function GetSecurityProfile(ServerAgentConnection, Cluster, ProfileName)
	
	For Each SecurityProfile In ServerAgentConnection.GetSecurityProfiles(Cluster) Do
		
		If SecurityProfile.Name = ProfileName Then
			Return SecurityProfile;
		EndIf;
		
	EndDo;
	
	Raise  StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en = 'The %3 security profile is not found in the %1:%2 server cluster.'"),
		Cluster.HostName,
		Format(Cluster.MainPort, "NG=0"),
		ProfileName
	);
	
EndFunction

// Returns virtual directories allowed in the security profile.
//
// Parameters:
// ServerAgentConnection - COMObject - implements the IV8AgentConnection interface,
// Cluster               - COMObject - implements the IClusterInfo interface, 
// ProfileName           - String - name of the security profile.
//
// Returns: Array of COMObject - implements the ISecurityProfileVirtualDirectory interface.
//
Function GetVirtualDirectories(ServerAgentConnection, Cluster, ProfileName)
	
	VirtualDirectories = New Array();
	
	For Each VirtualDirectory In ServerAgentConnection.GetSecurityProfileVirtualDirectories(Cluster, ProfileName) Do
		
		VirtualDirectories.Add(VirtualDirectory);
		
	EndDo;
	
	Return VirtualDirectories;
	
EndFunction
 
// Returns COM classes allowed in the security profile.
//
// Parameters:
// ServerAgentConnection - COMObject - implements the IV8AgentConnection interface,
// Cluster               - COMObject - implements the IClusterInfo interface, 
// ProfileName           - String - name of the security profile.
//
// Returns: Array of COMObject - implements the ISecurityProfileCOMClass interface.
//
Function GetCOMClasses(ServerAgentConnection,  Cluster, ProfileName)
	
	COMClasses = New Array();
	
	For Each COMClass In ServerAgentConnection.GetSecurityProfileCOMClasses(Cluster, ProfileName) Do
		
		COMClasses.Add(COMClass);
		
	EndDo;
	
	Return COMClasses;
	
EndFunction

// Returns add-ins allowed in the security profile.
//
// Parameters:
// ServerAgentConnection - COMObject - implements the IV8AgentConnection interface,
// Cluster               - COMObject - implements the IClusterInfo interface, 
// ProfileName           - String - name of the security profile.
//
// Returns: Array of COMObject - implements the ISecurityProfileAddIn interface.
//
Function GetAddIns(ServerAgentConnection, Cluster, ProfileName)
	
	AddIns = New Array();
	
	For Each  AddIn In ServerAgentConnection.GetSecurityProfileAddIns(Cluster, ProfileName) Do
		
		AddIns.Add(AddIn);
		
	EndDo;
	
	Return AddIns;
	
EndFunction
 
// Returns external modules allowed in the security profile.
//
// Parameters:
// ServerAgentConnection - COMObject - implements the IV8AgentConnection interface,
// Cluster               - COMObject - implements the IClusterInfo interface, 
// ProfileName           - String - name of the security profile.
//
// Returns: Array of COMObject - implements the ISecurityProfileExternalModule interface.
//
Function GetExternalModules(ServerAgentConnection,  Cluster, ProfileName)
	
	ExternalModules = New Array();
	
	For Each ExternalModule  In ServerAgentConnection.GetSecurityProfileUnSafeExternalModules(Cluster, ProfileName) Do
		
		ExternalModules.Add(ExternalModule);
		
	EndDo;
	
	Return ExternalModules;
	
EndFunction
 
// Returns OS applications allowed in the security profile.
//
// Parameters:
// ServerAgentConnection - COMObject - implements the IV8AgentConnection interface,
// Cluster               - COMObject - implements the IClusterInfo interface, 
// ProfileName           - String - name of the security profile.
//
// Returns: Array of COMObject -  implements the ISecurityProfileApplication interface.
//
Function GetOSApplications(ServerAgentConnection,  Cluster, ProfileName)
	
	OSApplications = New Array();
	
	For Each OSApplication In ServerAgentConnection.GetSecurityProfileApplications(Cluster, ProfileName) Do
		
		OSApplications.Add(OSApplication);
		
	EndDo;
	
	Return OSApplications;
	
EndFunction
 
// Returns internet resources allowed in the security profile.
//
// Parameters:
// ServerAgentConnection - COMObject - implements the IV8AgentConnection interface,
// Cluster               - COMObject - implements the IClusterInfo interface, 
// ProfileName           - String - name of the security profile.
//
// Returns: Array of COMObject -  implements the ISecurityProfileInternetResource interface.
//
Function GetInternetResources(ServerAgentConnection,  Cluster, ProfileName)
	
	InternetResources = New Array();
	
	For Each InternetResource In ServerAgentConnection.GetSecurityProfileInternetResources(Cluster, ProfileName) Do
		
		InternetResources.Add(InternetResource);
		
	EndDo;
	
	Return InternetResources;
	
EndFunction

// Substitute the passed properties for the security profile ones.
//
// Parameters:
// ServerAgentConnection     - COMObject - implements the IV8AgentConnection interface,
// Cluster                   - COMObject - implements the IClusterInfo interface,
// SecurityProfile           - COMObject - implements the ISecurityProfile interface,
// SecurityProfileProperties - Structure - describes the security profile. For content see
//                             ClusterAdministrationClientServer.SecurityProfileProperties().
//
Procedure ApplySecurityProfilePropertyChanges(ServerAgentConnection,  Cluster, SecurityProfile,  SecurityProfileProperties)
	
	FillCOMAdministratorObjectModelObjectPropertiesByDeclaration(
		SecurityProfile,
		SecurityProfileProperties,
		SecurityProfilePropertyDictionary());
	
	ProfileName = SecurityProfileProperties.Name;
	
	ServerAgentConnection.RegSecurityProfile(Cluster, SecurityProfile);
	
	// Virtual directories
	VirtualDirectoriesToDelete =  GetVirtualDirectories(ServerAgentConnection,  Cluster, ProfileName);
	For Each  VirtualDirectoryToDelete In  VirtualDirectoriesToDelete Do
		ServerAgentConnection.UnregSecurityProfileVirtualDirectory(
			Cluster,
			ProfileName,
			VirtualDirectoryToDelete.Alias
		);
	EndDo;
	VirtualDirectoriesToCreate =  SecurityProfileProperties.VirtualDirectories;
	For Each  VirtualDirectoryToCreate In  VirtualDirectoriesToCreate Do
		VirtualDirectory =  ServerAgentConnection.CreateSecurityProfileVirtualDirectory();
		FillCOMAdministratorObjectModelObjectPropertiesByDeclaration(
			VirtualDirectory,
			VirtualDirectoryToCreate,
			VirtualDirectoryPropertyDictionary()
		);
		ServerAgentConnection.RegSecurityProfileVirtualDirectory(Cluster, ProfileName, VirtualDirectory);
	EndDo;
	
	// Allowed COM classes
	COMClassesToDelete = GetCOMClasses(ServerAgentConnection,  Cluster, ProfileName);
	For Each  COMClassToDelete In COMClassesToDelete Do
		ServerAgentConnection.UnregSecurityProfileCOMClass(
			Cluster,
			ProfileName,
			COMClassToDelete.Name
		);
	EndDo;
	COMClassesToCreate =  SecurityProfileProperties.COMClasses;
	For Each COMClassToCreate In COMClassesToCreate Do
		COMClass = ServerAgentConnection.CreateSecurityProfileCOMClass();
		FillCOMAdministratorObjectModelObjectPropertiesByDeclaration(
			COMClass,
			COMClassToCreate,
			COMClassPropertyDictionary()
		);
		ServerAgentConnection.RegSecurityProfileCOMClass(Cluster, ProfileName, COMClass);
	EndDo;
	
	// Add-ins
	AddInsToDelete = GetAddIns(ServerAgentConnection, Cluster, ProfileName);
	For Each  AddInToDelete In AddInsToDelete  Do
		ServerAgentConnection.UnregSecurityProfileAddIn(
			Cluster,
			ProfileName,
			AddInToDelete.Name
		);
	EndDo;
	AddInsToCreate =  SecurityProfileProperties.AddIns;
	For Each  AddInToCreate In  AddInsToCreate Do
		AddIn =  ServerAgentConnection.CreateSecurityProfileAddIn();
		FillCOMAdministratorObjectModelObjectPropertiesByDeclaration(
			AddIn,
			AddInToCreate,
			AddInPropertyDictionary()
		);
		ServerAgentConnection.RegSecurityProfileAddIn(Cluster, ProfileName, AddIn);
	EndDo;
	
	// External modules
	ExternalModulesToDelete = GetExternalModules(ServerAgentConnection, Cluster, ProfileName);
	For Each  ExternalModuleToDelete In ExternalModulesToDelete Do
		ServerAgentConnection.UnregSecurityProfileUnSafeExternalModule(
			Cluster,
			ProfileName,
			ExternalModuleToDelete.Name
		);
	EndDo;
	ExternalModulesToCreate = SecurityProfileProperties.ExternalModules;
	For Each  ExternalModuleToCreate In ExternalModulesToCreate  Do
		ExternalModule = ServerAgentConnection.CreateSecurityProfileUnSafeExternalModule();
		FillCOMAdministratorObjectModelObjectPropertiesByDeclaration(
			ExternalModule,
			ExternalModuleToCreate,
			ExternalModulePropertyDictionary()
		);
		ServerAgentConnection.RegSecurityProfileUnSafeExternalModule(Cluster, ProfileName, ExternalModule);
	EndDo;
	
	// OS applications
	OSApplicationsToDelete = GetOSApplications(ServerAgentConnection, Cluster, ProfileName);
	For Each  OSApplicationToDelete In OSApplicationsToDelete Do
		ServerAgentConnection.UnregSecurityProfileApplication(
			Cluster,
			ProfileName,
			OSApplicationToDelete.Name
		);
	EndDo;
	OSApplicationsToCreate =  SecurityProfileProperties.OSApplications;
	For Each  OSApplicationToCreate In OSApplicationsToCreate Do
		OSApplication = ServerAgentConnection.CreateSecurityProfileApplication();
		FillCOMAdministratorObjectModelObjectPropertiesByDeclaration(
			OSApplication,
			OSApplicationToCreate,
			OSApplicationPropertyDictionary()
		);
		ServerAgentConnection.RegSecurityProfileApplication(Cluster, ProfileName, OSApplication);
	EndDo;
	
	// Internet resources
	InternetResourcesToDelete =  GetInternetResources(ServerAgentConnection, Cluster, ProfileName);
	For Each  InternetResourceToDelete In InternetResourcesToDelete Do
		ServerAgentConnection.UnregSecurityProfileInternetResource(
			Cluster,
			ProfileName,
			InternetResourceToDelete.Name
		);
	EndDo;
	InternetResourcesToCreate =  SecurityProfileProperties.InternetResources;
	For Each  InternetResourceToCreate In InternetResourcesToCreate  Do
		InternetResource = ServerAgentConnection.CreateSecurityProfileInternetResource();
		FillCOMAdministratorObjectModelObjectPropertiesByDeclaration(
			InternetResource,
			InternetResourceToCreate,
			InternetResourcePropertyDictionary()
		);
		ServerAgentConnection.RegSecurityProfileInternetResource(Cluster, ProfileName, InternetResource);
	EndDo;
	
EndProcedure
 
// Generates the object description for the COM administrator object model object.
//
// Parameters:
//  Object - COMObject,
//  Dictionary - Map - contains the object property map where:
//                Key   - property name in the description, 
//                Value - object property name.
//
// Returns: Structure - description of the COM administrator object model object by the passed
//          dictionary.
//
Function COMAdministratorObjectModelObjectDetails(Val Object, Val Dictionary)
	
	Details = New Structure();
	For Each  DictionaryFragment In Dictionary Do
		If ValueIsFilled(Object[DictionaryFragment.Value]) Then
			Details.Insert(DictionaryFragment.Key, Object[DictionaryFragment.Value]);
		Else
			Details.Insert(DictionaryFragment.Key, Undefined);
		EndIf;
	EndDo;
	
	Return Details;
	
EndFunction

// Generates descriptions of COM administrator object model objects.
//
// Parameters:
// Objects    - Array of COMObject,
// Dictionary - Map - contains the object property map where:
//              Key   - property name in the description, 
//              Value - object property name.
//
// Returns: Array of Structure description of COM administrator object model objects by the
//          passed dictionary.
//
Function COMAdministratorObjectModelObjectDescriptions(Val Objects, Val Dictionary)
	
	Descriptions = New Array();
	
	For Each Object In Objects Do
		Descriptions.Add(COMAdministratorObjectModelObjectDetails(Object, Dictionary));
	EndDo;
	
	Return Descriptions;
	
EndFunction

// Fills properties of the COM administrator object model object by the properties from the
// passed description.
//
// Parameters:
// Object      - COMObject,
// Description - Structure - description used for filling object properties, 
// Dictionary  - Map - contains the object property map where:
// Key         - property name in the description, 
// Value       - object property name.
//
Procedure FillCOMAdministratorObjectModelObjectPropertiesByDeclaration(Object, Val Description, Val Dictionary)
	
	For Each DictionaryFragment In Dictionary Do
		Object[DictionaryFragment.Value] = Description[DictionaryFragment.Key];
	EndDo;
	
EndProcedure

// Returns a map of the infobase property names (that describe states of session lock and
// scheduled jobs for structures used in the API) and COM administrator object model objects.
//
// Returns: FixedStructure:
//  Key   - String - property name in the API (See
//          ClusterAdministrationClientServer.SessionAndScheduleJobLockProperties()),
//  Value - String - object property name.
//
Function SessionAndScheduledJobLockPropertyDictionary()
	
	Result = New Structure();
	
	Result.Insert("SessionsLock",     "SessionsDenied");
	Result.Insert("StartDate",        "DeniedFrom");
	Result.Insert("EndDate",          "DeniedTo"); 
	Result.Insert("Message",          "DeniedMessage");
	Result.Insert("KeyCode",          "PermissionCode");
	Result.Insert("ScheduledJobLock", "ScheduledJobsDenied");
	
	Return New FixedStructure(Result);
	
EndFunction
 
// Returns a map of the infobase session property names used in the API and COM administrator
// object model objects.
//
// Returns: FixedStructure:
//           Key   - String - property name in the API (See
//                   ClusterAdministrationClientServer.SessionProperties()),
//           Value - String - object property name.
//
Function DictionaryPropertiesSessions()
	
	Result = New  Structure();
	
	Result.Insert("Number", "SessionID");
	Result.Insert("UserName", "UserName");
	Result.Insert("ClientComputerName", "Host");
	Result.Insert("ClientApplicationID", "AppID");
	Result.Insert("LanguageID", "Locale");
	Result.Insert("SessionCreationTime", "StartedAt");
	Result.Insert("LatestSessionActivityTime", "LastActiveAt");
	Result.Insert("DBMSLock", "blockedByDBMS");
	Result.Insert("Lock", "blockedByLS");
	Result.Insert("Passed",  "bytesAll");
	Result.Insert("PassedIn5Minutes", "bytesLast5Min");
	Result.Insert("ServerCalls", "callsAll");
	Result.Insert("ServerCallsIn5Minutes", "callsLast5Min");
	Result.Insert("ServerCallDurations", "durationAll");
	Result.Insert("CurrentServerCallDuration", "durationCurrent");
	Result.Insert("ServerCallDurationsIn5Minutes", "durationLast5Min");
	Result.Insert("ExchangedWithDBMS", "dbmsBytesAll");
	Result.Insert("ExchangedWithDBMSIn5Minutes", "dbmsBytesLast5Min");
	Result.Insert("DBMSCallDurations", "durationAllDBMS");
	Result.Insert("CurrentDBMSCallDuration",  "durationCurrentDBMS");
	Result.Insert("DBMSCallDurationsIn5Minutes",  "durationLast5MinDBMS");
	Result.Insert("DBMSConnection", "dbProcInfo");
	Result.Insert("DBMSConnectionTime", "dbProcTook");
	Result.Insert("DBMSConnectionSeizeTime", "dbProcTookAt");
	
	Return New  FixedStructure(Result);
	
EndFunction
 
// Returns a map of the infobase connection property names used in the API and COM
// administrator object model objects.
//
// Returns: FixedStructure:
//           Key   - String - property name in the API (See
//                   ClusterAdministrationClientServer.ConnectionProperties()),
//           Value - String - object property name.
//
Function ConnectionPropertyDictionary()
	
	Result = New  Structure();
	
	Result.Insert("Number",  "ConnID");
	Result.Insert("UserName", "UserName");
	Result.Insert("ClientComputerName", "HostName");
	Result.Insert("ClientApplicationID", "AppID");
	Result.Insert("ConnectionEstablishingTime", "ConnectedAt");
	Result.Insert("InfobaseConnectionMode", "IBConnMode");
	Result.Insert("DataBaseConnectionMode", "dbConnMode");
	Result.Insert("DBMSLock", "blockedByDBMS");
	Result.Insert("Passed",  "bytesAll");
	Result.Insert("PassedIn5Minutes", "bytesLast5Min");
	Result.Insert("ServerCalls", "callsAll");
	Result.Insert("ServerCallsIn5Minutes", "callsLast5Min");
	Result.Insert("ExchangedWithDBMS", "dbmsBytesAll");
	Result.Insert("ExchangedWithDBMSIn5Minutes", "dbmsBytesLast5Min");
	Result.Insert("DBMSConnection", "dbProcInfo");
	Result.Insert("DBMSTime", "dbProcTook");
	Result.Insert("DBMSConnectionSeizeTime", "dbProcTookAt");
	Result.Insert("ServerCallDurations", "durationAll");
	Result.Insert("DBMSCallDurations", "durationAllDBMS");
	Result.Insert("CurrentServerCallDuration", "durationCurrent");
	Result.Insert("CurrentDBMSCallDuration",  "durationCurrentDBMS");
	Result.Insert("ServerCallDurationsIn5Minutes", "durationLast5Min");
	Result.Insert("DBMSCallDurationsIn5Minutes",  "durationLast5MinDBMS");
	
	Return New FixedStructure(Result);
	
EndFunction
 
// Returns a map of the security profile property names used in the API and COM administrator
// object model objects.
//
// Returns: FixedStructure:
//           Key   - String - property name in the API (See
//                   ClusterAdministrationClientServer.SecurityProfileProperties()),
//           Value - String - object property name.
//
Function SecurityProfilePropertyDictionary()
	
	Result = New  Structure();
	
	Result.Insert("Name",  "Name");
	Result.Insert("Description",  "Descr");
	Result.Insert("SafeModeProfile", "SafeModeProfile");
	Result.Insert("FullAccessToPrivilegedMode", "PrivilegedModeInSafeModeAllowed");
	
	Result.Insert("FullFileSystemAccess", "FileSystemFullAccess");
	Result.Insert("FullCOMObjectAccess", "COMFullAccess");
	Result.Insert("FullAddInAccess",  "AddInFullAccess");
	Result.Insert("FullExternalModuleAccess", "UnSafeExternalModuleFullAccess");
	Result.Insert("FullOperatingSystemApplicationAccess", "ExternalAppFullAccess");
	Result.Insert("FullInternetResourceAccess",  "InternetFullAccess");
	
	Return New  FixedStructure(Result);
	
EndFunction
 
// Returns a map of the virtual directory property names used in the API and COM administrator 
// object model objects.
//
// Returns: FixedStructure:
//          Key   - String - property name in the API (See
//                           ClusterAdministrationClientServer.VirtualDirectoryProperties()),
//          Value - String - object property name.
//
Function VirtualDirectoryPropertyDictionary()
	
	Result = New  Structure();
	
	Result.Insert("LogicalURL", "Alias");
	Result.Insert("PhysicalURL", "PhysicalPath");
	
	Result.Insert("Description", "Descr");
	
	Result.Insert("DataReading", "AllowedRead");
	Result.Insert("DataWriting", "AllowedWrite");
	
	Return New FixedStructure(Result);
	
EndFunction
 
// Returns a map of the COM class property names used in the API and COM administrator object
// model objects.
//
// Returns: FixedStructure:
//          Key   - String - property name in the API (See
//                  ClusterAdministrationClientServer.COMClassProperties()),
// Value - String - object property name.
//
Function COMClassPropertyDictionary()
	
	Result = New  Structure();
	
	Result.Insert("Name",  "Name");
	Result.Insert("Description",  "Descr");
	
	Result.Insert("FileMoniker", "FileName");
	Result.Insert("CLSID",  "ObjectUUID");
	Result.Insert("Computer", "ComputerName");
	
	Return New FixedStructure(Result);
	
EndFunction
 
// Returns a map of the external component property names used in the API and COM administrator
// object model objects.
//
// Returns: FixedStructure:
//          Key   - String - property name in the API (See
//                  ClusterAdministrationClientServer.AddInProperties()),
//          Value - String - object property name.
//
Function AddInPropertyDictionary()
	
	Result = New  Structure();
	
	Result.Insert("Name", "Name");
	Result.Insert("Description", "Descr");
	
	Result.Insert("HashSum", "AddInHash");
	
	Return New  FixedStructure(Result);
	
EndFunction
 
// Returns a map of the external module property names used in the API and COM administrator
// object model objects.
//
// Returns: FixedStructure:
//           Key   - String - property name in the API (See
//                   ClusterAdministrationClientServer.ExternalModuleProperties()),
//           Value - String - object property name.
//
Function ExternalModulePropertyDictionary()
	
	Result = New  Structure();
	
	Result.Insert("Name", "Name");
	Result.Insert("Description", "Descr");
	
	Result.Insert("HashSum", "ExternalModuleHash");
	
	Return New FixedStructure(Result);
	
EndFunction
 
// Returns a map of the operating system application property names used in the API and COM
// administrator object model objects.
//
// Returns: FixedStructure:
//           Key   - String - property name in the API (See
//                   ClusterAdministrationClientServer.OSApplicationProperties()),
//           Value - String - object property name.
//
Function OSApplicationPropertyDictionary()
	
	Result = New Structure();
	
	Result.Insert("Name", "Name");
	Result.Insert("Description", "Descr");
	
	Result.Insert("CommandLinePattern", "CommandMask");
	
	Return New FixedStructure(Result);
	
EndFunction
 
// Returns a map of the Internet resource property names used in the API and COM administrator
// object model objects.
//
// Returns: FixedStructure:
//           Key   - String - property name in the API (See
//                   ClusterAdministrationClientServer.InternetResourceProperties()),
//           Value - String - object property name.
//
Function InternetResourcePropertyDictionary()
	
	Result = New Structure();
	
	Result.Insert("Name", "Name");
	Result.Insert("Description", "Descr");
	
	Result.Insert("Protocol", "Protocol");
	Result.Insert("Address", "Address");
	Result.Insert("Port", "Port");
	
	Return New FixedStructure(Result);
	
EndFunction

#EndRegion