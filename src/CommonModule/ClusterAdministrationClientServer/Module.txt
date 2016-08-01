////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
// Common client and server procedures and function for working with:
//  - Program interface for administrating the server cluster.
//
////////////////////////////////////////////////////////////////////////////////

#Region Interface

#Region ProgramInterfaceParameterConstructors

// Constructor of a structure that defines the connection parameters of the server cluster 
// being administrated.
//
// Returns: Structure with the following fields:
//  ConnectionType               - String - allowed values are:
//                                  "COM" - when connecting the server agent using the
//                                          V8*.ComConnector COM object,
//                                  "RAS" - when connecting the administration server (ras) 
//                                          using the console client of the administration
//                                          server (rac),
//  ServerAgentAddress           - String - server agent network address (only when
//                                 ConnectionType = "COM"), 
//  ServerAgentPort              - Number - network port of the server agent (only when
//                                 ConnectionType = "COM"), usually is 1540,
//  AdministrationServerAddress  - String - ras administration server network address (only 
//                                 when ConnectionType = "RAS"), 
//  AdministrationServerPort     - Number - network port of the ras administration server (only 
//                                 when ConnectionType = "RAS"), usually is 1545,
//  ClusterPort                  - Number - network port of the manager of the cluster being
//                                 administrated, usually is 1541,
//  ClusterAdministratorName     - String - cluster administrator account name (if the list of
//                                 administrators is not specified for the cluster, an empty
//                                 string is used),
//  ClusterAdministratorPassword - String - cluster administrator account password (if the list
//                                 of administrators is not specified for the cluster  or the
//                                 administrator account password is not set, an empty string 
//                                 is used).
//
Function ClusterAdministrationParameters() Export
	
	Result = New Structure();
	
	Result.Insert("ConnectionType", "COM"); // COM or RAS
	
	// For COM only
	Result.Insert("ServerAgentAddress", "");
	Result.Insert("ServerAgentPort", 1540);
	
	// For RAS only
	Result.Insert("AdministrationServerAddress", "");
	Result.Insert("AdministrationServerPort", 1545);
	
	Result.Insert("ClusterPort", 1541);
	Result.Insert("ClusterAdministratorName", "");
	Result.Insert("ClusterAdministratorPassword", "");
	
	Return Result;
	
EndFunction

// Constructor of a structure that defines the cluster infobase connection parameters being
// administered.
//
// Returns: Structure with the following fields:
//  NameInCluster                 - String - name of the infobase being administered in the
//                                  server cluster,
//  InfobaseAdministratorName     - String - name of the infobase user with administrative
//                                  rights (if the list of infobase users is not set, an empty
//                                  string is used),
//  InfobaseAdministratorPassword - String - password of the infobase user with administrative
//                                  rights (if the list of infobase users is not set or the
//                                  infobase user password is not set, an empty string is
//                                  used).
//
Function ClusterInfobaseAdministrationParameters() Export
	
	Result = New Structure();
	
	Result.Insert("NameInCluster", "");
	Result.Insert("InfobaseAdministratorName", "");
	Result.Insert("InfobaseAdministratorPassword", "");
	
	Return Result;
	
EndFunction

// Checks whether administration parameters are filled correctly.
//
// Parameters:
//  ClusterAdministrationParameters      - Structure - describes the server cluster connection
//                                         parameters, for details see
//                                         ClusterAdministrationClientServer.ClusterAdministrationParameters(),
// InfobaseAdministrationParameters      - Structure - describes the infobase connection
//                                         parameters, for details see
//                                         ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters().
//                                         The parameter can be skipped if the same fields have
//                                         been filled in the structure passed as the
//                                         ClusterAdministrationParameters parameter value,
// CheckClusterAdministrationParameters  - Boolean - flag that shows whether cluster
//                                         administration parameters must be checked,
// CheckInfobaseAdministrationParameters - Boolean - flag that shows whether infobase 
//                                         administration parameters must be checked.
//
Procedure CheckAdministrationParameters(Val ClusterAdministrationParameters, Val InfobaseAdministrationParameters = Undefined,
	CheckClusterAdministrationParameters = True,
	CheckInfobaseAdministrationParameters = True) Export
	
	If InfobaseAdministrationParameters = Undefined Then
		InfobaseAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	AdministrationManager.CheckAdministrationParameters(ClusterAdministrationParameters, InfobaseAdministrationParameters, CheckInfobaseAdministrationParameters, CheckClusterAdministrationParameters);
	
EndProcedure

#EndRegion

#Region SessionAndScheduledJobLock

// Constructor of a structure that defines infobase session and scheduled job lock properties.
//
// Returns: Structure with the following fields:
//  SessionsLock    - Boolean - flag that shows whether new infobase sessions are locked,
//  StartDate       - Date (Date and time) - time since which all new infobase sessions are
//                    prohibited,
//  EndDate         - Date (Date and time) - time since which all new infobase sessions are
//                    allowed,
//  Message         - String - message to be sent to user when a new session is being
//                    established with the locked Infobase,
// KeyCode          - String - pass code to connect to the locked infobase, 
// ScheduledJobLock - Boolean - flag that shows whether infobase scheduled jobs must be locked.
//
Function SessionAndScheduleJobLockProperties() Export
	
	Result = New Structure();
	
	Result.Insert("SessionsLock");
	Result.Insert("StartDate");
	Result.Insert("EndDate");
	Result.Insert("Message");
	Result.Insert("KeyCode");
	Result.Insert("ScheduledJobLock");
	
	Return Result;
	
EndFunction

// Returns the current state of the infobase session and scheduled job lock.
//
// Parameters:
//  ClusterAdministrationParameters - Structure - describes the server cluster connection
//                                    parameters, for details see
//                                    ClusterAdministrationClientServer.ClusterAdministrationParameters(),
// InfobaseAdministrationParameters - Structure - describes the infobase connection parameters,
//                                    for details see
//                                    ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters().
//                                    The parameter can be skipped if the same fields have been
//                                    filled in the structure passed as the
//                                    ClusterAdministrationParameters parameter value.
//
// Returns: Structure - describes the state of session and scheduled job lock, for details see
//          ClusterAdministrationClientServer.SessionAndScheduleJobLockProperties().
//
Function InfobaseSessionAndJobLock(Val ClusterAdministrationParameters, Val InfobaseAdministrationParameters = Undefined) Export
	
	If InfobaseAdministrationParameters = Undefined Then
		InfobaseAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Result = AdministrationManager.InfobaseSessionAndJobLock(
		ClusterAdministrationParameters,
		InfobaseAdministrationParameters);
	
	If Result.StartDate = BlankDate() Then
		Result.StartDate = Undefined;
	EndIf;
	
	If Result.EndDate = BlankDate() Then
		Result.EndDate = Undefined;
	EndIf;
	
	If Not ValueIsFilled(Result.KeyCode) Then
		Result.KeyCode = "";
	EndIf;
	
	If Not ValueIsFilled(Result.KeyCode) Then
		Result.KeyCode = "";
	EndIf;
	
	Return Result;
	
EndFunction

// Sets the state of the infobase session and scheduled job lock.
//
// Parameters:
//  ClusterAdministrationParameters  - Structure - describes the server cluster connection
//                                     parameters, for details see
//                                    ClusterAdministrationClientServer.ClusterAdministrationParameters(),
//  InfobaseAdministrationParameters - Structure - describes the infobase connection 
//                                     parameters, for details see
//                                    ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters(),
//                                     The parameter can be skipped if the same fields have 
//                                     been filled in the structure passed as the
//                                     ClusterAdministrationParameters parameter value.
//  SessionAndJobLockProperties      - Structure - describes the state of the session and 
//                                     scheduled job lock, for details see 
//                                     ClusterAdministrationClientServer.SessionAndScheduleJobLockProperties().
//
Procedure SetInfobaseSessionAndJobLock(Val ClusterAdministrationParameters, Val InfobaseAdministrationParameters, Val SessionAndJobLockProperties) Export
	
	If InfobaseAdministrationParameters = Undefined Then
		InfobaseAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	LockBeingSet = New Structure();
	For Each Property In SessionAndJobLockProperties Do
		LockBeingSet.Insert(Property.Key, Property.Value);
	EndDo;
	
	If LockBeingSet.StartDate = Undefined Then
		LockBeingSet.StartDate = BlankDate();
	EndIf;
	If LockBeingSet.EndDate = Undefined Then
		LockBeingSet.EndDate = BlankDate();
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	AdministrationManager.SetInfobaseSessionAndJobLock(
		ClusterAdministrationParameters,
		InfobaseAdministrationParameters,
		LockBeingSet);
	
EndProcedure

// Unlocks infobase sessions and scheduled jobs.
//
// Parameters:
//  ClusterAdministrationParameters  - Structure - describes the server cluster connection
//                                     parameters, for details see
//                                     ClusterAdministrationClientServer.ClusterAdministrationParameters(),
//  InfobaseAdministrationParameters - Structure - describes the infobase connection 
//                                     parameters, for details see
//                                     ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters(),
//                                     The parameter can be skipped if the same fields have 
//                                     been filled in the structure passed as the
//                                     ClusterAdministrationParameters parameter value.
//
Procedure UnlockInfobaseSessionsAndJobs(Val ClusterAdministrationParameters, Val InfobaseAdministrationParameters = Undefined) Export
	
	If InfobaseAdministrationParameters = Undefined Then
		InfobaseAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	LockProperties = SessionAndScheduleJobLockProperties();
	LockProperties.SessionsLock = False;
	LockProperties.StartDate = Undefined;
	LockProperties.EndDate = Undefined;
	LockProperties.Message = "";
	LockProperties.KeyCode = "";
	LockProperties.ScheduledJobLock = False;
	
	SetInfobaseSessionAndJobLock(
		ClusterAdministrationParameters,
		InfobaseAdministrationParameters,
		LockProperties);
	
EndProcedure

#EndRegion

#Region ScheduledJobLock

// Returns the current state of infobase scheduled job lock.
//
// Parameters:
//  ClusterAdministrationParameters - Structure - describes the server cluster connection
//                                    parameters, for details see
//                                    ClusterAdministrationClientServer.ClusterAdministrationParameters(),
// InfobaseAdministrationParameters - Structure - describes the infobase connection parameters,
//                                    for details see
//                                    ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters().
//                                    The parameter can be skipped if the same fields have been
//                                    filled in the structure passed as the
//                                    ClusterAdministrationParameters parameter value.
//
// Returns: Boolean.
//
Function InfobaseScheduledJobLock(Val ClusterAdministrationParameters, Val InfobaseAdministrationParameters = Undefined) Export
	
	If InfobaseAdministrationParameters = Undefined Then
		InfobaseAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Result = AdministrationManager.InfobaseScheduledJobLock(
		ClusterAdministrationParameters,
		InfobaseAdministrationParameters);
	
	Return Result;
	
EndFunction

// Sets the state of the infobase scheduled job lock.
//
// Parameters:
//  ClusterAdministrationParameters  - Structure - describes the server cluster connection
//                                     parameters, for details see
//                                        ClusterAdministrationClientServer.ClusterAdministrationParameters(),
//  InfobaseAdministrationParameters - Structure - describes the infobase connection
//                                     parameters, for details see
//                                     ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters(),
//                                     The parameter can be skipped if the same fields have
//                                     been filled in the structure passed as the
//                                     ClusterAdministrationParameters parameter value.
//  ScheduledJobLock                 - Boolean - flag that shows whether infobase scheduled
//                                     jobs are locked.
//
Procedure LockInfobaseScheduledJobs(Val ClusterAdministrationParameters, Val InfobaseAdministrationParameters, Val ScheduledJobLock) Export
	
	If InfobaseAdministrationParameters = Undefined Then
		InfobaseAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	AdministrationManager.LockInfobaseScheduledJobs(
		ClusterAdministrationParameters,
		InfobaseAdministrationParameters,
		ScheduledJobLock);
	
EndProcedure

#EndRegion

#Region InfobaseSessions

// Constructor of a structure that defines infobase session properties.
//
// Returns: Structure with the following fields:
//  Number                        - Number - number of the session. Is unique among all
//                                  infobase sessions,
//  UserName                      - String - name of the authenticated infobase user,
//  ClientComputerName            - String - name of network address of the computer that
//                                  established the session with the Infobase,
//  ClientApplicationID           - String - ID of the application that established the
//                                  session. For allowed values see the description of the 
//                                  ApplicationPresentation() global context function
//  LanguageID                    - String - interface language ID,
//  SessionCreationTime           - Date (Date and time) - time when the session was 
//                                  established,
//  LatestSessionActivityTime     - Date (Date and time) - moment when the session was active
//                                  for the last time,
//  Lock                          - Number - number of a session that caused managed
//                                  transactional lock waiting if the session sets managed
//                                  transactional locks and waits for locks set by another
//                                  session to be disabled (otherwise is 0),
//  DBMSLock                      - Number - number of a session that caused transactional lock
//                                  waiting if the session performs a DBMS call and waits for a
//                                  transactional lock set by another session to be disabled
//                                  (otherwise the value is 0),
//  Passed                        - Number - volume of data passed between the 1C:Enterprise
//                                  server and the current session client application since the
//                                  session start (in bytes),
//  PassedIn5Minutes              - Number - volume of data passed between the 1C:Enterprise
//                                  server and the current session client application in the
//                                  last 5 minutes (in bytes),
//  ServerCalls                   - Number - number of the 1c:Enterpraise server calls made on
//                                  behalf of the current session since the session started,
//  ServerCallsIn5Minutes         - Number - number of the 1C:Enterpraise server calls made on
//                                  behalf of the current session in the last 5 minutes,
//  ServerCallDurations           - Number - execution time of 1C:Enterprise server calls on
//                                  behalf of the current session since the session start (in
//                                  milliseconds),   
//  CurrentServerCallDuration     - Number - time interval (in milliseconds) since the access
//                                  start if the session executes the 1C:Enterprise call
//                                  (otherwise the value is 0),
//  ServerCallDurationsIn5Minutes - Number - execution time of 1C:Enterprise server calls on
//                                  behalf of the current session in the last 5 minutes (in
//                                  milliseconds),
//  ExchangedWithDBMS             - Number - volume of data passed and received from DBMS on
//                                  behalf of the current session since the session start (in
//                                  bytes),
//  ExchangedWithDBMSIn5Minutes   - Number - volume of data passed and received from DBMS on
//                                  behalf of the current session in the last 5 minutes (in
//                                  bytes),
//  DBMSCallDurations             - Number - total time spent on executing DBMS queries made on
//                                  behalf of the current session since the session start (in
//                                  milliseconds),
//  CurrentDBMSCallDuration       - Number - time interval (in milliseconds) since the query
//                                  execution start if the session executes the DBMS call
//                                  (otherwise the value is 0),
//  DBMSCallDurationsIn5Minutes   - Number - total time spent on executing DBMS queries made on
//                                  behalf of the current session in the last 5 minutes (in
//                                  milliseconds).
//  DBMSConnection                - String - DBMS connection number in the terms of DBMS if  
//                                  when the session list is retrieved, the DBMS query is 
//                                  executed, a transaction is opened, or temporary tables are 
//                                  defined (DBMS connection is seized). If the BDMS session is 
//                                  not seized, the value is an empty string,
//  DBMSConnectionTime            - Number - DBMS connection time (is counted once the  
//                                  connection is seized in milliseconds). If the BDMS session  
//                                  is not seized, the value is 0,
//  DBMSConnectionSeizeTime       - Date (Date and time) - last time when the connection to the 
//                                  DBMS was seized by another session.
//
Function SessionProperties() Export
	
	Result = New Structure();
	
	Result.Insert("Number");
	Result.Insert("UserName");
	Result.Insert("ClientComputerName");
	Result.Insert("ClientApplicationID");
	Result.Insert("LanguageID");
	Result.Insert("SessionCreationTime");
	Result.Insert("LatestSessionActivityTime");
	Result.Insert("Lock");
	Result.Insert("DBMSLock");
	Result.Insert("Passed");
	Result.Insert("PassedIn5Minutes");
	Result.Insert("ServerCalls");
	Result.Insert("ServerCallsIn5Minutes");
	Result.Insert("ServerCallDurations");
	Result.Insert("CurrentServerCallDuration");
	Result.Insert("ServerCallDurationsIn5Minutes");
	Result.Insert("ExchangedWithDBMS");
	Result.Insert("ExchangedWithDBMSIn5Minutes");
	Result.Insert("DBMSCallDurations");
	Result.Insert("CurrentDBMSCallDuration");
	Result.Insert("DBMSCallDurationsIn5Minutes");
	Result.Insert("DBMSConnection");
	Result.Insert("DBMSConnectionTime");
	Result.Insert("DBMSConnectionSeizeTime");
	
	Return Result;
	
EndFunction

// Returns descriptions of infobase sessions.
//
// Parameters:
//  ClusterAdministrationParameters - Structure - describes the server cluster connection parameters, for details see
//                                    ClusterAdministrationClientServer.ClusterAdministrationParameters(),
// InfobaseAdministrationParameters - Structure - describes the infobase connection parameters for details see
//                                    ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters(),
//                                    The parameter can be skipped if the same fields have been filled in the structure
//                                    passed as the ClusterAdministrationParameters parameter value.
//  Filter                          - Details on the session filtering conditions whose descriptions are required.
//                                    Following options are available:
//                                    1. Array of structures that describe session filtering conditions. Fields of
//                                       structures in the array are:
//                                        Property       - String - property name to be used in the filter. For valid
//                                                         values see return value of the
//                                                         ClusterAdministrationClientServer.SessionProperties()
//                                                         function,
//                                        ComparisonType - value of the ComparisonType system enumeration. Value
//                                                         comparison type with the specified filter condition.
//                                                         The valid values are:
//                                                          ComparisonType.Equal,
//                                                          ComparisonType.NotEqual,
//                                                          ComparisonType.Greater (for numeric values only),
//                                                          ComparisonType.GreaterOrEqual (for numeric values only),
//                                                          ComparisonType.Less (for numeric values only),
//                                                          ComparisonType.LessOrEqual (for numeric values only),
//                                                          ComparisonType.InList,
//                                                          ComparisonType.NotInList,
//                                                          ComparisonType.Interval (for numeric values only),
//                                                          ComparisonType.IntervalIncludingBounds (for numeric values only),
//                                                          ComparisonType.IntervalIncludingLowerBound (for numeric values only),
//                                                          ComparisonType.IntervalIncludingUpperBound (for numeric values only),
//                                                          Value - Number, String, Date, Boolean, ValueList, Array,
//                                                                  Structure - value against which the corresponding
//                                                                  session property value is compared. If
//                                                                  ComparisonType.InList or ComparisonType.NotInList,
//                                                                  pass ValueList or Array with a set of values again
//                                                                  which the property is compared. In case of
//                                                                  ComparisonType.Interval,
//                                                                  ComparisonType.IntervalIncludingBounds,
//                                                                  ComparisonType.IntervalIncludingLowerBound, or
//                                                                  IntervalIncludingUpperBound, pass a structure with
//                                                                  the From and To fields whose values are interval
//                                                                  against which the value is compared,
//                                    2. Structure (simplified), where key is the session property name (see above),
//                                       value is the value used for comparison. When you use this description option,
//                                       the comparison filter always checks for equality.
//
// Returns: Array of Structure - describes session properties. For Structure details see
//          ClusterAdministrationClientServer.SessionProperties().
//
Function InfobaseSessions(Val ClusterAdministrationParameters, Val InfobaseAdministrationParameters = Undefined, Val Filter = Undefined) Export
	
	If InfobaseAdministrationParameters = Undefined Then
		InfobaseAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.InfobaseSessions(
		ClusterAdministrationParameters,
		InfobaseAdministrationParameters,
		Filter);
	
EndFunction

// Terminates infobase sessions by filter.
//
// Parameters:
//  ClusterAdministrationParameters - Structure - describes the server cluster connection parameters, for details see
//                                    ClusterAdministrationClientServer.ClusterAdministrationParameters(),
//  InfobaseAdministrationParameters - Structure - describes the infobase connection parameters, for details see
//                                    ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters(),
//                                    The parameter can be skipped if the same fields have been filled in the structure
//                                    passed as the
//                                    ClusterAdministrationParameters parameter value.
//  Filter                          - filtering condition details of sessions to be terminated.
//                                    Following options are available:
//                                    1. Array of structures that describe session filtering conditions.
//                                       Fields of structures in the array are:
//                                        Property       - String - property name to be used in the filter. For valid
//                                                         values see the return value of the
//                                                         ClusterAdministrationClientServer.SessionProperties()
//                                                         function,
//                                        ComparisonType - value of the ComparisonType system enumeration. The value
//                                                         comparison type with the specified filter condition.
//                                                         The valid values are:
//                                                          ComparisonType.Equal,
//                                                          ComparisonType.NotEqual,
//                                                          ComparisonType.Greater (for numeric values only),
//                                                          ComparisonType.GreaterOrEqual (for numeric values only),
//                                                          ComparisonType.Less (for numeric values only),
//                                                          ComparisonType.LessOrEqual (for numeric values only),
//                                                          ComparisonType.InList,
//                                                          ComparisonType.NotInList,
//                                                          ComparisonType.Interval (for numeric values only),
//                                                          ComparisonType.IntervalIncludingBounds (for numeric values only),
//                                                          ComparisonType.IntervalIncludingLowerBound (for numeric values only),
//                                                          ComparisonType.IntervalIncludingUpperBound (for numeric values only),
//                                        Value           - Number, String, Date, Boolean, ValueList, Array, Structure -
//                                                          value against which the corresponding session property value
//                                                          is compared. If ComparisonType.InList or
//                                                          ComparisonType.NotInList, pass ValueList or Array with a set
//                                                          of values against which the property is compared. In case of
//                                                          ComparisonType.Interval,
//                                                          ComparisonType.IntervalIncludingBounds,
//                                                          ComparisonType.IntervalIncludingLowerBound, or
//                                                          IntervalIncludingUpperBound, pass a structure with the From
//                                                          and To fields whose values are interval against which the
//                                                          value is compared,
//                                    2. Structure (simplified), where key is a session property name (see above), value
//                                       is a value used for comparison. When you use this description option, the
//                                       comparison filter always checks for equality.
//
Procedure DeleteInfobaseSessions(Val ClusterAdministrationParameters, Val InfobaseAdministrationParameters = Undefined, Val Filter = Undefined) Export
	
	If InfobaseAdministrationParameters = Undefined Then
		InfobaseAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	AdministrationManager.DeleteInfobaseSessions(
		ClusterAdministrationParameters,
		InfobaseAdministrationParameters,
		Filter);
	
EndProcedure

#EndRegion

#Region InfobaseConnection

// Constructor of a structure that defines infobase connection properties.
//
// Returns: Structure with the following fields:
//  Number                        - Number - infobase connection number,
//  UserName                      - String - name of the 1C:Enterprise user, connected to the
//                                  Infobase,
//  ClientComputerName            - String - name of the computer that established the connection
//  ClientApplicationID           - String - ID of the application that established the connection.
//                                  For allowed values see the description of the ApplicationPresentation() global context function,
//  ConnectionEstablishingTime    - Date (Date and time) - time when connection was established,
//  InfobaseConnectionMode        - Number - infobase connection mode (0 - shared, 1 - exclusive),
//  DatabaseConnectionMode        - Number - database connection mode (0 - connection is not
//                                  established, 1 - shared, 2 - exclusive),
//  DBMSLock                      - Number - ID of the connection that locks the current connection
//                                  in the DBMS,
//  Passed                        - Number - volume of data that the connection sent and
//                                  received,
//  PassedIn5Minutes              - Number - volume of data that the connection sent and
//                                  received in the last 5 minutes,
//  ServerCalls                   - Number - number of server calls,
//  ServerCallsIn5Minutes         - Number - number of server calls of the connection in the
//                                  last 5 minutes,
//  ExchangedWithDBMS             - Number - volume of data passed between the 1C:Enterprise 
//                                  server and the database server since the connection was
//                                  established,
//  ExchangedWithDBMSIn5Minutes   - Number - volume of data passed between the 1C:Enterprise
//                                  server and the database server in the last 5 minutes,
//  DBMSConnection                - String - DBMS connection process ID (if the connection
//                                  performed a DBMS server call before the list is retrieved,
//                                  otherwise - value is an empty string). The ID is returned
//                                  in the DBMS server terms.
//  DBMSTime                      - Number - duration in seconds of the DBMS server call (if
//                                  the connection performed a DBMS server call before the list 
//                                  is retrieved, otherwise is 0),
//  DBMSConnectionSeizeTime       - Date (Date and time) - last time when the DBMS server
//                                  connection was seized, 
//  ServerCallDurations           - Number - total duration of all server calls of the
//                                  connection,
//  DBMSCallDurations             - Number - duration of the DBMS calls that the connection
//                                  initialized,
//  CurrentServerCallDuration     - Number - duration of the current server call,
//  CurrentDBMSCallDuration       - Number - duration of the current DBMS server call,
//  ServerCallDurationsIn5Minutes - Number - duration of server calls in the last 5 minutes,
//  DBMSCallDurationsIn5Minutes   - Number - duration of DBMS connection calls in the last 5 
//                                  minutes.
//
Function ConnectionProperties() Export
	
	Result = New Structure();
	
	Result.Insert("Number");
	Result.Insert("UserName");
	Result.Insert("ClientComputerName");
	Result.Insert("ClientApplicationID");
	Result.Insert("ConnectionEstablishingTime");
	Result.Insert("InfobaseConnectionMode");
	Result.Insert("DataBaseConnectionMode");
	Result.Insert("DBMSLock");
	Result.Insert("Passed");
	Result.Insert("PassedIn5Minutes");
	Result.Insert("ServerCalls");
	Result.Insert("ServerCallsIn5Minutes");
	Result.Insert("ExchangedWithDBMS");
	Result.Insert("ExchangedWithDBMSIn5Minutes");
	Result.Insert("DBMSConnection");
	Result.Insert("DBMSTime");
	Result.Insert("DBMSConnectionSeizeTime");
	Result.Insert("ServerCallDurations");
	Result.Insert("DBMSCallDurations");
	Result.Insert("CurrentServerCallDuration");
	Result.Insert("CurrentDBMSCallDuration");
	Result.Insert("ServerCallDurationsIn5Minutes");
	Result.Insert("DBMSCallDurationsIn5Minutes");
	
	Return Result;
	
EndFunction

// Returns infobase connection descriptions.
//
// Parameters:
//  ClusterAdministrationParameters  - Structure - describes the server cluster connection parameters, for details see
//                                     ClusterAdministrationClientServer.ClusterAdministrationParameters(),
//  InfobaseAdministrationParameters - Structure - describes the infobase connection parameters, for details see
//                                     ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters(),
//                                     The parameter can be skipped if the same fields have been filled in the structure
//                                     passed as the ClusterAdministrationParameters parameter value.
//  Filter                           - details on the connection filtering conditions whose descriptions are required.
//                                     Following options are available:
//                                      1. Array of structures that describes connection filtering conditions. Fields of
//                                         structures in the array are:
//                                          Property       - String - property name to be used in the filter. For valid
//                                                           values see the return value of the
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
//                                          Value           - Number, String, Date, Boolean, ValueList, Array, Structure -
//                                                            value against which the corresponding connection property
//                                                            value is compared. If ComparisonType.InList or 
//                                                            ComparisonType.NotInList, pass ValueList or Array with a
//                                                            set of values against which the property is compared. In
//                                                            case of ComparisonType.Interval,
//                                                            ComparisonType.IntervalIncludingBounds,
//                                                            ComparisonType.IntervalIncludingLowerBound, or
//                                                            IntervalIncludingUpperBound, pass a structure with the
//                                                            From and To fields whose values are interval against which
//                                                            the value is compared,
//                                      2. Structure (simplified), where key is a name of the connection property (see
//                                         above), value is a value used for comparison. When you use this description
//                                         option, the comparison filter always checks for equality.
//
// Returns: Array of Structure - describes connection properties. For structure details see
//          ClusterAdministrationClientServer.ConnectionProperties().
//
Function InfobaseConnection(Val ClusterAdministrationParameters, Val InfobaseAdministrationParameters = Undefined, Val Filter = Undefined) Export
	
	If InfobaseAdministrationParameters = Undefined Then
		InfobaseAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.InfobaseConnection(
		ClusterAdministrationParameters,
		InfobaseAdministrationParameters,
		Filter);
	
EndFunction

// Terminates the infobase connection by filter.
//
// Parameters:
//  ClusterAdministrationParameters  - Structure - describes the server cluster connection parameters, for details see
//                                     ClusterAdministrationClientServer.ClusterAdministrationParameters(),
//  InfobaseAdministrationParameters - Structure - describes the infobase connection parameters, for details see
//                                     ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters(),
//                                     The parameter can be skipped if the same fields have been filled in the structure
//                                     passed as the ClusterAdministrationParameters parameter value.
//  Filter                           - details on the filtering conditions for connections to be terminated.
//                                     Following options are available:
//                                      1. Array of structures that describe filtering conditions for the connections to
//                                         be terminated. Fields of structures in the array are:
//                                          Property        - String - property name to be used in the filter. For valid
//                                                            values see the return value of the
//                                                            ClusterAdministrationClientServer.ConnectionProperties()
//                                                            function,
//                                          ComparisonType  - value of the ComparisonType system enumeration. The value
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
//                                          Value            - Number, String, Date, Boolean, ValueList, Array, Structure -
//                                                             value against which the corresponding connection property
//                                                             value is compared. If ComparisonType.InList or
//                                                             ComparisonType.NotInList, pass ValueList or Array with a
//                                                             set of values against which the property is compared. In
//                                                             case of ComparisonType.Interval,
//                                                             ComparisonType.IntervalIncludingBounds,
//                                                             ComparisonType.IntervalIncludingLowerBound, or
//                                                             IntervalIncludingUpperBound, pass a structure with the
//                                                             From and To fields whose values are interval against
//                                                             which the value is compared,
//                                      2. Structure (simplified), where key is a name of the connection property (see
//                                         above), value is a value used for comparison. When you use this description
//                                         option, the comparison filter always checks for equality.
//
Procedure TerminateInfobaseConnection(Val ClusterAdministrationParameters, Val InfobaseAdministrationParameters = Undefined, Val Filter = Undefined) Export
	
	If InfobaseAdministrationParameters = Undefined Then
		InfobaseAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	AdministrationManager.TerminateInfobaseConnection(
		ClusterAdministrationParameters,
		InfobaseAdministrationParameters,
		Filter);
	
EndProcedure

#EndRegion

#Region SecurityProfiles

// Returns the name of the infobase security profile.
//
// Parameters:
//  ClusterAdministrationParameters - Structure - describes the server cluster connection
//                                    parameters, for details see
//                                    ClusterAdministrationClientServer.ClusterAdministrationParameters(),
//  InfobaseAdministrationParameters - Structure - describes the infobase connection parameters,
//                                     for details see
//                                     ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters().
//                                     The parameter can be skipped if the same fields have been
//                                     filled in the structure passed as the
//                                     ClusterAdministrationParameters parameter value.
//
// Returns: String - name of the security profile set for the infobase. If the infobase security
//          profile is not set, an empty string is returned.
//
Function InfobaseSecurityProfile(Val ClusterAdministrationParameters, Val InfobaseAdministrationParameters = Undefined) Export
	
	If InfobaseAdministrationParameters = Undefined Then
		InfobaseAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.InfobaseSecurityProfile(
		ClusterAdministrationParameters,
		InfobaseAdministrationParameters);
	
EndFunction

// Returns the name of the security profile that was set as the infobase safe mode security profile.
//
// Parameters:
//  ClusterAdministrationParameters  - Structure - describes the server cluster connection
//                                     parameters, for details see
//                                     ClusterAdministrationClientServer.ClusterAdministrationParameters(),
//  InfobaseAdministrationParameters - Structure - describes the infobase connection parameters,
//                                     for details see
//                                     ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters().
//                                     The parameter can be skipped if the same fields have been
//                                     filled in the structure passed as the
//                                     ClusterAdministrationParameters parameter value.
//
// Returns: String - name of the security profile set for the infobase as the safe mode security profile. If no security profile set for the infobase - an empty string is returned.
//
Function InfobaseSafeModeSecurityProfile(Val ClusterAdministrationParameters, Val InfobaseAdministrationParameters = Undefined) Export
	
	If InfobaseAdministrationParameters = Undefined Then
		InfobaseAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.InfobaseSafeModeSecurityProfile(
		ClusterAdministrationParameters,
		InfobaseAdministrationParameters);
	
EndFunction

// Sets the security profile for the infobase.
//
// Parameters:
//  ClusterAdministrationParameters  - Structure - describes the server cluster connection
//                                     parameters, for details see
//                                     ClusterAdministrationClientServer.ClusterAdministrationParameters(),
//  InfobaseAdministrationParameters - Structure - describes the infobase connection parameters,
//                                     for details see
//                                     ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters(),
//                                     The parameter can be skipped if the same fields have been
//                                     filled in the structure passed as the
//                                     ClusterAdministrationParameters parameter value.
//  ProfileName                      - String - name of the security profile. If an empty string is
//                                     passed, the security profile is disabled for the infobase.
//
Procedure SetInfobaseSecurityProfile(Val ClusterAdministrationParameters, Val InfobaseAdministrationParameters = Undefined, Val ProfileName = "") Export
	
	If InfobaseAdministrationParameters = Undefined Then
		InfobaseAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	AdministrationManager.SetInfobaseSecurityProfile(
		ClusterAdministrationParameters,
		InfobaseAdministrationParameters,
		ProfileName);
	
EndProcedure

// Sets the safe mode security profile for the infobase.
//
// Parameters:
//  ClusterAdministrationParameters  - Structure - describes the server cluster connection
//                                     parameters, for details see
//                                     ClusterAdministrationClientServer.ClusterAdministrationParameters(),
//  InfobaseAdministrationParameters - Structure - describes the infobase connection parameters,
//                                     for details see
//                                     ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters(),
//                                     The parameter can be skipped if the same fields have been
//                                     filled in the structure passed as the
//                                     ClusterAdministrationParameters parameter value.
//  ProfileName                      - String - name of the security profile. If an empty string is
//                                     passed, the safe mode security profile must be disabled for
//                                     the infobase.
//
Procedure SetInfobaseSafeModeSecurityProfile(Val ClusterAdministrationParameters, Val InfobaseAdministrationParameters = Undefined, Val ProfileName = "") Export
	
	If InfobaseAdministrationParameters = Undefined Then
		InfobaseAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	AdministrationManager.SetInfobaseSafeModeSecurityProfile(
		ClusterAdministrationParameters,
		InfobaseAdministrationParameters,
		ProfileName);
	
EndProcedure

// Checks whether the security profile exists in the server cluster.
//
// Parameters:
//  ClusterAdministrationParameters - Structure - describes the server cluster connection
//                                    parameters, for details see
//                                    ClusterAdministrationClientServer.ClusterAdministrationParameters(),
//  ProfileName                     - String - name of the security profile whose existence is 
//                                    checked.
//
Function SecurityProfileExists(Val ClusterAdministrationParameters, Val ProfileName) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.SecurityProfileExists(
		ClusterAdministrationParameters,
		ProfileName);
	
EndFunction

// Constructor of the structure that defines security profile properties.
//
// Returns: Structure with the following fields:
//  Name                                 - String - security profile name,
//  Details                              - String - security profile description, 
//  SafeModeProfile                      - Boolean - flag that shows whether the security profile
//                                         can be used as a security profile of the safe mode (both
//                                         when the profile is specified for the infobase and when
//                                         the SetSafeMode(<Profile name>) is called from the
//                                         applied solution script),
//  FullAccessToPrivilegedMode           - Boolean - flag that shows whether the privileged mode
//                                         can be set from the safe mode of the security profile,
//  FullFileSystemAccess                 - Boolean - defines whether there are file system access
//                                         restrictions. If the value is False, infobase users can
//                                         access only file system directories specified in the
//                                         VirtualDirectories property,
//  FullCOMObjectAccess                  - Boolean - flag that shows whether there are COM object
//                                         access restrictions. If the value is False, infobase
//                                         users can access only COM classes specified in the
//                                         COMClasses property,
//  FullAddInAccess                      - Boolean - flag that shows whether there are external
//                                         component access restrictions. If the value is False,
//                                         infobase users can access only add-ins
//                                         specified in the AddIns property,
//  FullExternalModuleAccess             - Boolean - flag that shows whether there are external
//                                         module (external reports and data processors, 
//                                         Execute() and Eval() calls in the unsafe mode) 
//                                         access restrictions.
//                                         If the value is False, infobase users can use in the
//                                         unsafe mode only external modules specified in the ExternalModules property,
//  FullOperatingSystemApplicationAccess - Boolean - flag that shows whether there are operating
//                                         system application access restrictions. If the value is
//                                         False, infobase users can use operating system
//                                         applications specified in the OSApplications property,
//  FullInternetResourceAccess           - Boolean - flag that shows whether there are Internet 
//                                         resources access restrictions.
//                                         If the value is False, infobase users can use internet
//                                         resources specified in the InternetResources property,
//  VirtualDirectories                   - Array of Structure - array of structures that describe
//                                         virtual directories that infobase users can access if
//                                         FullFileSystemAccess = False. For structure field
//                                         details see
//                                         ClusterAdministrationClientServer.VirtualDirectoryProperties(),
//  COMClasses                           - Array of Structure - array of structures that describe
//                                         COM classes that infobase users can access if
//                                         FullCOMObjectAccess = False. For structure field details
//                                         see
//                                         ClusterAdministrationClientServer.COMClassProperties(),
//  AddIns                               - Array of Structure - array of structures that describe
//                                         add-ins that infobase users can access if
//                                         FullAddInAccess = False. For structure field
//                                         details see
//                                         ClusterAdministrationClientServer.AddInProperties(),
//  ExternalModules                      - Array of Structure - array of structures that describe
//                                         external modules that infobase users can access if
//                                         FullExternalModuleAccess = False. For structure field
//                                         details see
//                                         ClusterAdministrationClientServer.ExternalModuleProperties(),
//  OSApplications                       - Array of Structure - array of structures that describe
//                                         operating system operating system that infobase users
//                                         can access if
//                                         FullOperatingSystemApplicationAccess = False. For
//                                         structure field details see
//                                         ClusterAdministrationClientServer.OSApplicationProperties(),
//  InternetResources                    - Array of Structure - array of structures that describe
//                                         Internet resources that infobase users can access if
//                                         FullInternetResourceAccess = False. For structure field
//                                         details see ClusterAdministrationClientServer.InternetResourceProperties().
//
Function SecurityProfileProperties() Export
	
	Result = New Structure();
	
	Result.Insert("Name", "");
	Result.Insert("Details", "");
	Result.Insert("SafeModeProfile", False);
	Result.Insert("FullAccessToPrivilegedMode", False);
	
	Result.Insert("FullFileSystemAccess", False);
	Result.Insert("FullCOMObjectAccess", False);
	Result.Insert("FullAddInAccess", False);
	Result.Insert("FullExternalModuleAccess", False);
	Result.Insert("FullOperatingSystemApplicationAccess", False);
	Result.Insert("FullInternetResourceAccess", False);
	
	Result.Insert("VirtualDirectories", New Array());
	Result.Insert("COMClasses", New Array());
	Result.Insert("AddIns", New Array());
	Result.Insert("ExternalModules", New Array());
	Result.Insert("OSApplications", New Array());
	Result.Insert("InternetResources", New Array());
	
	Return Result;
	
EndFunction

// Constructor of a structure that describe virtual directory properties.
//
// Returns: Structure with the following fields:
//           LogicalURL    - String - logical directory URL,
//           PhysicalURL   - String - physical URL of the directory on the server where data of 
//                           the virtual catalog is placed.
//           Details       - String - virtual directory description.
//           DataReading   - Boolean - flag that shows whether data can be read from the 
//                           virtual directory,
//           DataWriting   - Boolean - flag that shows whether data can be written to the 
//                           virtual directory.
//
Function VirtualDirectoryProperties() Export
	
	Result = New Structure();
	
	Result.Insert("LogicalURL");
	Result.Insert("PhysicalURL");
	
	Result.Insert("Details");
	
	Result.Insert("DataReading");
	Result.Insert("DataWriting");
	
	Return Result;
	
EndFunction

// Constructor of a structure that describes COM class properties.
//
// Returns: Structure with the following fields:
//           Name        - String - COM class name used as a key when searching,
//           Details     - String - COM class description,
//           FileMoniker - String - name of file used for creating the object using the
//                         GetCOMObject global context method with an empty value of the second
//                         parameter,
//           CLSID       - String - COM class ID presentation in the Windows registry format without
//                         braces, to be used for creating a COM class object, 
//           Computer    - String - name of the computer where the COM object can be created.
//
Function COMClassProperties() Export
	
	Result = New Structure();
	
	Result.Insert("Name");
	Result.Insert("Details");
	
	Result.Insert("FileMoniker");
	Result.Insert("CLSID");
	Result.Insert("Computer");
	
	Return Result;
	
EndFunction

// Constructor of the structure that describes the external component properties.
//
// Returns: Structure with the following fields:
//           Name    - String - name of the external component. Is used as the key for
//                     searching,
//           Details - String - external component description,
//           HashSum - String - checksum of the allowed external module calculated with the
//           SHA-1 algorithm and transformed into a base64 string.
//
Function AddInProperties() Export
	
	Result = New Structure();
	
	Result.Insert("Name");
	Result.Insert("Details");
	
	Result.Insert("HashSum");
	
	Return Result;
	
EndFunction

// Constructor of the structure that describes external module properties.
//
// Returns: Structure with the following fields:
//           Name    - String - name of the external module. Is used as the key for searching,
//           Details - String - external module description,
//           HashSum - String - checksum of the allowed external module calculated with the 
//                     SHA-1 algorithm and transformed into a base64 string.
//
Function ExternalModuleProperties() Export
	
	Result = New Structure();
	
	Result.Insert("Name");
	Result.Insert("Details");
	
	Result.Insert("HashSum");
	
	Return Result;
	
EndFunction

// Constructor of a structure that defines operating system application properties.
//
// Returns: Structure with the following fields:
//           Name               - String - name of the operating system application. Is used as
//                                the key for searching,
//           Details            - String - operating system application description,
//           CommandLinePattern - String - application command line pattern (consists of
//                                pattern words separated by spaces).
//
Function OSApplicationProperties() Export
	
	Result = New Structure();
	
	Result.Insert("Name");
	Result.Insert("Details");
	
	Result.Insert("CommandLinePattern");
	
	Return Result;
	
EndFunction

// Constructor of a structure that describes the Internet resource.
//
// Returns: Structure with the following fields:
//           Name     - String - name of the Internet resource. Is used as the key for
//                      searching,
//           Details  - String - InternetResource description,
//           Protocol - String - allowed network protocol. Allowed values are:
//                       HTTP,
//                       HTTPS,
//                       FTP,
//                       FTPS,
//                       POP3,
//                       SMTP,
//                       IMAP,
//           Address  - String - URL without schemа and port,
//           Port     - Number - Internet resource port.
//
Function InternetResourceProperties() Export
	
	Result = New Structure();
	
	Result.Insert("Name");
	Result.Insert("Details");
	
	Result.Insert("Protocol");
	Result.Insert("Address");
	Result.Insert("Port");
	
	Return Result;
	
EndFunction

// Returns security profile properties.
//
// Parameters:
//  ClusterAdministrationParameters - Structure - describes the server cluster connection
//                                    parameters, for details see
//                                    ClusterAdministrationClientServer.ClusterAdministrationParameters(),
// ProfileName                      - String - name of the security profile.
//
// Returns: Structure - describes the security profile, for details see
//                      ClusterAdministrationClientServer.SecurityProfileProperties().
//
Function SecurityProfile(Val ClusterAdministrationParameters, Val ProfileName) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.SecurityProfile(
		ClusterAdministrationParameters,
		ProfileName);
	
EndFunction

// Creates a security profile by the passed description.
//
// Parameters:
//  ClusterAdministrationParameters - Structure - describes the server cluster connection
//                                    parameters, for details see 
//                                    ClusterAdministrationClientServer.ClusterAdministrationParameters(),
// SecurityProfileProperties        - Structure - describes properties of a security profile to
//                                    be generated, for details see
//                                    ClusterAdministrationClientServer.SecurityProfileProperties().
//
Procedure CreateSecurityProfile(Val ClusterAdministrationParameters, Val SecurityProfileProperties) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	AdministrationManager.CreateSecurityProfile(
		ClusterAdministrationParameters,
		SecurityProfileProperties);
	
EndProcedure

// Sets properties of the existing security profile by the passed description.
//
// Parameters:
//  ClusterAdministrationParameters - Structure - describes the server cluster connection
//                                    parameters, for details see
//                                    ClusterAdministrationClientServer.ClusterAdministrationParameters(),
// SecurityProfileProperties        - Structure - describes properties of security profile
//                                    properties to be set, for details see
//                                    ClusterAdministrationClientServer.SecurityProfileProperties().
//
Procedure SetSecurityProfileProperties(Val ClusterAdministrationParameters, Val SecurityProfileProperties)  Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	AdministrationManager.SetSecurityProfileProperties(
		ClusterAdministrationParameters,
		SecurityProfileProperties);
	
EndProcedure

// Deletes the security profile.
//
// Parameters:
//  ClusterAdministrationParameters - Structure - describes the server cluster connection
//                                    parameters, for details see
//                                    ClusterAdministrationClientServer.ClusterAdministrationParameters(),
// ProfileName                      - String - name of the security profile.
//
Procedure DeleteSecurityProfile(Val ClusterAdministrationParameters, Val ProfileName) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	AdministrationManager.DeleteSecurityProfile(
		ClusterAdministrationParameters,
		ProfileName);
	
EndProcedure

#EndRegion

#EndRegion

#Region InternalProceduresAndFunctions

// Checks whether object properties meet the requirements specified in the filter.
//
// Parameters:
//  ObjectBeingValidated - Structure with the following fields:
//    Key    - name of the property whose value is compared with the filter,
//    Value  - property value to be compared with the filter,
//    Filter - details on object filtering conditions.
//             The following options are available:
//              1. Array of structures that describe the filter conditions. Fields of structures in the array
//                 are:
//                  Property       - String - name of a property to be used as a filter,
//                  ComparisonType - value of the ComparisonType system enumeration. The value comparison
//                                   type with the specified filter condition. Valid values are:
//                                    ComparisonType.Equal,
//                                    ComparisonType.NotEqual,
//                                    ComparisonType.Greater (for numeric values only),
//                                    ComparisonType.GreaterOrEqual (for numeric values only),
//                                    ComparisonType.Less (for numeric values only),
//                                    ComparisonType.LessOrEqual (for numeric values only),
//                                    ComparisonType.InList,
//                                    ComparisonType.NotInList,
//                                    ComparisonType.Interval (for numeric values only),
//                                    ComparisonType.IntervalIncludingBounds (for numeric values only),
//                                    ComparisonType.IntervalIncludingLowerBound (for numeric values only),
//                                    ComparisonType.IntervalIncludingUpperBound (for numeric values only),
//                  Value - Number, String, Date, Boolean, ValueList, Array, Structure - value against which the
//                          property value is compared. If ComparisonType.InList or ComparisonType.NotInList, pass
//                          ValueList or Array with a set of values against which the property is compared. In case of
//                          ComparisonType.Interval, ComparisonType.IntervalIncludingBounds,
//                          ComparisonType.IntervalIncludingLowerBound, or IntervalIncludingUpperBound, pass a
//                          structure with the From and To fields whose values are interval against which the value is
//                          compared,
//              2. Structure (simplified), where key is a property name (see above), value is a value used for
//                 comparison. When you use this description option, the comparison filter always checks for equality.
//
// Returns: Boolean - True if the object property values are meet the requirements specified in the filter, 
//                    False if the values do not meet the requirements.
//
Function CheckFilterConditions(Val ObjectBeingValidated, Val Filter = Undefined) Export
	
	If Filter = Undefined Or Filter.Count() = 0 Then
		Return True;
	EndIf;
	
	ConditionsCompleted = 0;
	
	For Each Where In Filter Do
		
		If TypeOf(Where) = Type("Structure") Then
			
			Field = Where.Property;
			RequiredValue = Where.Value;
			ValueComparisonType = Where.ComparisonType;
			
		ElsIf TypeOf(Where) = Type("KeyAndValue") Then
			
			Field = Where.Key;
			RequiredValue = Where.Value;
			ValueComparisonType = ComparisonType.Equal;
			
		Else
			
			Raise NStr("en = 'Filter is set incorrectly'");
			
		EndIf;
		
		ValidatedValue = ObjectBeingValidated[Field];
		ConditionCompleted = CheckFilterCondition(ValidatedValue, ValueComparisonType, RequiredValue);
		
		If ConditionCompleted Then
			ConditionsCompleted = ConditionsCompleted + 1;
		Else
			Break;
		EndIf;
		
	EndDo;
	
	Return ConditionsCompleted = Filter.Count();
	
EndFunction

// Checks whether values meet the requirements specified in the filter.
//
// Parameters:
//  ValidatedValue      - Number, String, Date, Boolean - value to be compared with the condition,
//  ValueComparisonType - value of the ComparisonType system enumeration. The value comparison
//                        type with the specified filter condition. Valid values are:
//                         ComparisonType.Equal,
//                         ComparisonType.NotEqual,
//                         ComparisonType.Greater (for numeric values only),
//                         ComparisonType.GreaterOrEqual (for numeric values only),
//                         ComparisonType.Less (for numeric values only),
//                         ComparisonType.LessOrEqual (for numeric values only),
//                         ComparisonType.InList,
//                         ComparisonType.NotInList,
//                         ComparisonType.Interval (for numeric values only),
//                         ComparisonType.IntervalIncludingBounds (for numeric values only),
//                         ComparisonType.IntervalIncludingLowerBound (for numeric values only),
//                         ComparisonType.IntervalIncludingUpperBound (for numeric values only),
// Value                 - Number, String, Date, Boolean, ValueList, Array, Structure - value
//                         against which the value to be checked is compared. If
//                         ComparisonType.InList or ComparisonType.NotInList, pass ValueList or
//                         Array with a set of values against which the property is compared. In
//                         case of ComparisonType.Interval, ComparisonType.IntervalIncludingBounds,
//                         ComparisonType.IntervalIncludingLowerBound, or
//                         IntervalIncludingUpperBound, pass a structure with the From and To
//                         fields whose values are interval against which the value is compared.
//
// Returns: Boolean - True if the value meets conditions, otherwise is False.
//
Function CheckFilterCondition(Val ValidatedValue, Val ValueComparisonType, Val Value)
	
	If ValueComparisonType = ComparisonType.Equal Then
		
		Return ValidatedValue = Value;
		
	ElsIf ValueComparisonType = ComparisonType.NotEqual Then
		
		Return ValidatedValue <> Value;
		
	ElsIf ValueComparisonType = ComparisonType.Greater Then
		
		Return ValidatedValue > Value;
		
	ElsIf ValueComparisonType = ComparisonType.GreaterOrEqual Then
		
		Return ValidatedValue >= Value;
		
	ElsIf ValueComparisonType = ComparisonType.Less Then
		
		Return ValidatedValue < Value;
		
	ElsIf ValueComparisonType = ComparisonType.LessOrEqual Then
		
		Return ValidatedValue <= Value;
		
	ElsIf ValueComparisonType = ComparisonType.InList Then
		
		If TypeOf(Value) = Type("ValueList") Then
			
			Return Value.FindByValue(ValidatedValue) <> Undefined;
			
		ElsIf TypeOf(Value) = Type("Array") Then
			
			Return Value.Find(ValidatedValue) <> Undefined;
			
		EndIf;
		
	ElsIf ValueComparisonType = ComparisonType.NotInList Then
		
		If TypeOf(Value) = Type("ValueList") Then
			
			Return Value.FindByValue(ValidatedValue) = Undefined;
			
		ElsIf TypeOf(Value) = Type("Array") Then
			
			Return Value.Find(ValidatedValue) = Undefined;
			
		EndIf;
		
	ElsIf ValueComparisonType = ComparisonType.Interval Then
		
		Return ValidatedValue > Value.From And ValidatedValue < Value.To;
		
	ElsIf ValueComparisonType = ComparisonType.IntervalIncludingBounds Then
		
		Return ValidatedValue >= Value.From And ValidatedValue <= Value.To;
		
	ElsIf ValueComparisonType = ComparisonType.IntervalIncludingLowerBound Then
		
		Return ValidatedValue >= Value.From And ValidatedValue < Value.To;
		
	ElsIf ValueComparisonType = ComparisonType.IntervalIncludingUpperBound Then
		
		Return ValidatedValue > Value.From And ValidatedValue <= Value.To;
		
	EndIf;
	
EndFunction

// Returns the common module that implements a program interface for administrating the server
// cluster that corresponds the server cluster connection type.
//
// Parameters:
//  ClusterAdministrationParameters - Structure - describes the server cluster connection
//                                    parameters, for details see
//                                    ClusterAdministrationClientServer.ClusterAdministrationParameters().
//
// Returns: CommonModule.
//
Function AdministrationManager(Val AdministrationParameters)
	
	If AdministrationParameters.ConnectionType = "COM" Then
		
		Return ClusterAdministrationCOMClientServer;
		
	ElsIf AdministrationParameters.ConnectionType = "RAS" Then
		
		Return ClusterAdministrationRASClientServer;
		
	Else
		
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Unknown connection type: %1.'"), AdministrationParameters.ConnectionType);
		
	EndIf;
	
EndFunction

// Returns the date that is an empty date in the server cluster registry.
//
// Returns: Date (Date and time).
//
Function BlankDate()
	
	Return Date('00010101');
	
EndFunction

#EndRegion