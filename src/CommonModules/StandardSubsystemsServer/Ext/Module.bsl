////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
//  
////////////////////////////////////////////////////////////////////////////////

#Region Interface

///////////////////////////////////////////////////////////////////////////////
// Initializing session parameters

// To be called from the SessionParametersSetting session module handler.
//
// Parameters:
//  SessionParameterNames - Array, Undefined - names of the session parameters to be
//                          initialized.
//
//  Returns an array of names of the specified session parameters
//
Function SessionParametersSetting(SessionParameterNames) Export
	
	// Session parameters, whose initialization required retrieving the same data, must be
	// initialized in one group. To avoid reinitialization, names of the specified session
	// parameters are saved in the SpecifiedParameters array.
	SpecifiedParameters = New Array;
	
	If SessionParameterNames = Undefined Then
		SessionParameters.ClientParametersOnServer = New FixedMap(New Map);
		
		// When establishing the connections with the infobase before calling all other handlers
		BeforeApplicationStart();
		Return SpecifiedParameters;
	EndIf;
	
	// Initializing session parameters required before the moment when application run parameters
	// are updated.
	If SessionParameterNames.Find("ClientParametersOnServer") <> Undefined Then
		SessionParameters.ClientParametersOnServer = New FixedMap(New Map);
		SpecifiedParameters.Add("ClientParametersOnServer");
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.DataExchange") Then
		DataExchangeServerModule = CommonUse.CommonModule("DataExchangeServer");
		Handlers = New Map;
		DataExchangeServerModule.SessionParameterSettingHandlersOnAdd(Handlers);
		ExecuteSessionParameterSettingHandlers(SessionParameterNames, Handlers, SpecifiedParameters);
	EndIf;
	
	UnspecifiedParameters = CommonUseClientServer.ReduceArray(SessionParameterNames, SpecifiedParameters);
	If UnspecifiedParameters.Count() = 0 Then
		Return SpecifiedParameters;
	EndIf;
	
	// Initializing all the rest of the session parameters (when internal events are called the
	// application run parameters are already updated).
	Handlers = New Map;
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.BaseFunctionality\SessionParameterSettingHandlersOnAdd");
	
	For Each Handler In EventHandlers Do
		Handler.Module.SessionParameterSettingHandlersOnAdd(Handlers);
	EndDo;
	
	//PARTIALLY_DELETED
	//CustomHandlers = CommonUseOverridable.SessionParameterSettingHandlersOnAdd();
	//For Each Record In CustomHandlers Do
	//	Handlers.Insert(Record.Key, Record.Value);
	//EndDo;
	
	CustomHandlers = New Map;
	CommonUseOverridable.SessionParameterSettingHandlersOnAdd(CustomHandlers);
	For Each Record In CustomHandlers Do
		Handlers.Insert(Record.Key, Record.Value);
	EndDo;
	
	ExecuteSessionParameterSettingHandlers(SessionParameterNames, Handlers, SpecifiedParameters);
	Return SpecifiedParameters;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Additional procedures and functions.

// Returns a flag that shows whether the configuration is a base one.
//
// Returns:
//   Boolean - True if the configuration is a base one.
//
Function IsBaseConfigurationVersion() Export
	
	Return Find(Upper(Metadata.Name), "BASE") > 0;
	
EndFunction

// Updates metadata property caches, which speed up session startup and infobase update, 
// especially in the service mode.
// They are updated before the infobase update.
//
// To be used in other libraries and configurations.
//
Procedure UpdateAllApplicationParameters(FindChanges = False,
                                              HasChanges = Undefined,
                                              ExclusiveModeSettingError = Undefined,
                                              InBackground = False) Export
	
	HasChanges  = False;
	CheckOnly = False;
	DisableExclusiveMode = False;
	
	If FindChanges Then
		CheckOnly = True;
		
	ElsIf Not ExclusiveMode() Then
		Try
			SetExclusiveMode(True);
			DisableExclusiveMode = True;
		Except
			DisableExclusiveMode = False;
			CheckOnly = True;
		EndTry;
	EndIf;
	
	WithoutChanges = New Structure;
	Try
		ValidateUpdateAllApplicationParameters(HasChanges, CheckOnly, WithoutChanges, InBackground);
	Except
		If DisableExclusiveMode Then
			SetExclusiveMode(False);
		EndIf;
		Raise;
	EndTry;
	
	If DisableExclusiveMode Then
		SetExclusiveMode(False);
	EndIf;
	
	If Not FindChanges And CheckOnly Then
		If HasChanges Then
			Try
				SetExclusiveMode(True);
			Except
				ErrorText =
					NStr("en = 'The infobase cannot be updated:
					           |- The exclusive mode cannot be set;
					           |- The configuration version does not provide an option to be updated without exclusive mode set.'");
				
				If ExclusiveModeSettingError = Undefined Then
					Raise ErrorText;
				Else
					ExclusiveModeSettingError = ErrorText;
					Return;
				EndIf;
			EndTry;
			Try
				UpdateAllApplicationParameters(HasChanges, False);
			Except
				SetExclusiveMode(False);
				Raise;
			EndTry;
			SetExclusiveMode(False);
		Else
			// Exclusive mode is not required
			ValidateUpdateAllApplicationParameters(HasChanges, False, WithoutChanges, InBackground);
		EndIf;
	EndIf;
	
EndProcedure


////////////////////////////////////////////////////////////////////////////////
// Infobase and server cluster administration parameters

// Retrieves the infobase and server cluster administration parameters.
// Passwords are not retrieved.
// Returns:
//  Structure - Contains properties of two structures:
//               ClusterAdministrationClientServer.ClusterAdministrationParameters() and
//               ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters().
//
Function AdministrationParameters() Export
	
	If CommonUseCached.DataSeparationEnabled() And CommonUseCached.CanUseSeparatedData() Then
		
		If Not Users.InfobaseUserWithFullAccess() Then
			Raise NStr("en ='Insufficient rights to perform the operation'");
		EndIf;
		
	Else
		
		If Not Users.InfobaseUserWithFullAccess(, True) Then
			Raise NStr("en ='Insufficient rights to perform the operation'");
		EndIf;
		
	EndIf;
	
	SetPrivilegedMode(True);
	InfobaseAdministrationParameters = Constants.InfobaseAdministrationParameters.Get().Get();
	If InfobaseAdministrationParameters = Undefined Then
		InfobaseAdministrationParameters = DefaultAdministrationParameters();
	EndIf;
	
	If Not CommonUse.FileInfobase() Then
		ReadParametersFromConnectionString(InfobaseAdministrationParameters);
	EndIf;
	
	Return InfobaseAdministrationParameters;
	
EndFunction

// Retrieves the infobase and server cluster administration parameters.
// Parameters:
//  InfobaseAdministrationParameters - Structure - see return value of the
//                                     AdministrationParameters() procedure.
// 
Procedure SetAdministrationParameters(InfobaseAdministrationParameters) Export
	
	InfobaseAdministrationParameters.ClusterAdministratorPassword = "";
	InfobaseAdministrationParameters.InfobaseAdministratorPassword = "";
	Constants.InfobaseAdministrationParameters.Set(New ValueStorage(InfobaseAdministrationParameters));
	
EndProcedure

#EndRegion

#Region InternalInterface

////////////////////////////////////////////////////////////////////////////////
// Processing internal interface events.
// Can be used in the library and separately from other libraries only.

// Redefines events that can be supplied with extra handlers using the
// InternalEventHandlersOnAdd procedure.
//
// Parameters:
//  ClientEvents - Array - list of String type values - full event name.
//  ServerEvents - Array - list of String type values - full event name.
//
// We recommend that you call the same procedure in the common library module to make a support
// process easier.
//
// Example of using in a common library module:
//
// // Overrides the standard warning with opening an arbitrary form of active users.
// //  Parameters:
// //   FormName - String (return value).
// //  Syntax:
// //   Procedure ActiveUserFormOnOpen(FormName) Export 
// //  
// ServerEvents.Add("StandardSubsystems.BaseFunctionality\ActiveUserFormOnDefine");
//
// You may copy the comment when creating a new handler.
// The Syntax section: is used for creating a new handler procedure.
//
Procedure OnAddInternalEvent(ClientEvents, ServerEvents) Export
	
	// SERVER EVENTS.
	
	BaseFunctionalityInternalEventsOnAdd(ClientEvents, ServerEvents);
	SafeModeInternal.OnAddInternalEvent(ClientEvents, ServerEvents);
	DataProcessors.MarkedObjectDeletion.OnAddInternalEvent(ClientEvents, ServerEvents);
	
	If CommonUse.SubsystemExists("StandardSubsystems.BusinessProcessesAndTasks") Then
		BusinessProcessesAndTasksServerModule = CommonUse.CommonModule("BusinessProcessesAndTasksServer");
		BusinessProcessesAndTasksServerModule.OnAddInternalEvent(ClientEvents, ServerEvents);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.ReportOptions") Then
		ReportOptionsModule = CommonUse.CommonModule("ReportOptions");
		ReportOptionsModule.OnAddInternalEvent(ClientEvents, ServerEvents);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
		ReportOptionsModule = CommonUse.CommonModule("AdditionalReportsAndDataProcessors");
		ReportOptionsModule.OnAddInternalEvent(ClientEvents, ServerEvents);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.UserSessions") Then
		InfobaseConnectionsModule = CommonUse.CommonModule("InfobaseConnections");
		InfobaseConnectionsModule.OnAddInternalEvent(ClientEvents, ServerEvents);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.CalendarSchedules") Then
		CalendarSchedulesModule = CommonUse.CommonModule("CalendarSchedules");
		CalendarSchedulesModule.OnAddInternalEvent(ClientEvents, ServerEvents);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.UserReminders") Then
		UserRemindersInternalModule = CommonUse.CommonModule("UserRemindersInternal");
		UserRemindersInternalModule.OnAddInternalEvent(ClientEvents, ServerEvents);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.DataExchange") Then
		DataExchangeServerModule = CommonUse.CommonModule("DataExchangeServer");
		DataExchangeServerModule.OnAddInternalEvent(ClientEvents, ServerEvents);
	EndIf;
	
	InfobaseUpdateInternal.OnAddInternalEvent(ClientEvents, ServerEvents);
	
	UsersInternal.OnAddInternalEvent(ClientEvents, ServerEvents);
	
	If CommonUse.SubsystemExists("StandardSubsystems.AttachedFiles") Then
		AttachedFilesInternalModule = CommonUse.CommonModule("AttachedFilesInternal");
		AttachedFilesInternalModule.OnAddInternalEvent(ClientEvents, ServerEvents);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations") Then
		SaaSOperationsModule = CommonUse.CommonModule("SaaSOperations");
		SaaSOperationsModule.OnAddInternalEvent(ClientEvents, ServerEvents);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS") Then
		StandaloneModeInternalModule = CommonUse.CommonModule("StandaloneModeInternal");
		StandaloneModeInternalModule.OnAddInternalEvent(ClientEvents, ServerEvents);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.MessageExchange") Then
		MessageExchangeModule = CommonUse.CommonModule("MessageExchange");
		MessageExchangeModule.OnAddInternalEvent(ClientEvents, ServerEvents);
		MessageInterfacesSaaSModule = CommonUse.CommonModule("MessageInterfacesSaaS");
		MessageInterfacesSaaSModule.OnAddInternalEvent(ClientEvents, ServerEvents);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.JobQueue") Then
		JobQueueInternalModule = CommonUse.CommonModule("JobQueueInternal");
		JobQueueInternalModule.OnAddInternalEvent(ClientEvents, ServerEvents);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.SuppliedData") Then
		SuppliedDataModule = CommonUse.CommonModule("SuppliedData");
		SuppliedDataModule.OnAddInternalEvent(ClientEvents, ServerEvents);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.ToDoList") Then
		ToDoListInternalModule = CommonUse.CommonModule("ToDoListInternal");
		ToDoListInternalModule.OnAddInternalEvent(ClientEvents, ServerEvents);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.AccessManagement") Then
		AccessManagementInternalModule = CommonUse.CommonModule("AccessManagementInternal");
		AccessManagementInternalModule.OnAddInternalEvent(ClientEvents, ServerEvents);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.FileFunctions") Then
		FileFunctionsInternalModule = CommonUse.CommonModule("FileFunctionsInternal");
		FileFunctionsInternalModule.OnAddInternalEvent(ClientEvents, ServerEvents);
	EndIf;
	
EndProcedure

// Redefines handlers of the internal events declared through the OnAddInternalEvent procedure.
//
// Parameters:
//  ClientHandlers - Map - handler list:
//                           * Key   - String - full event name.
//                           * Value - Array - array of handler common client module names.
//
//  ServerHandlers  - Map - handler list:
//                           * Key   - String - full event name.
//                           * Value - Array - array of handler common server module names.
//
// We recommend that you call the same procedure in the common library module to make a support
// process easier.
//
// Example of using in a common library module:
//
// ServerHandlers["StandardSubsystems.BaseFunctionality\ActiveUserFormOnDefine"].Add(InfobaseConnections);
//
Procedure InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers) Export
	
	InternalEventHandlersBaseFunctionalityOnAdd(ClientHandlers, ServerHandlers);
	SafeModeInternal.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers); 
	
	If CommonUse.SubsystemExists("StandardSubsystems.AddressClassifier") Then
		AddressClassifierModule = CommonUse.CommonModule("AddressClassifier");
		AddressClassifierModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.EventLogStatistics") Then
		EventLogStatisticsInternalModule = CommonUse.CommonModule("EventLogStatisticsInternal");
		EventLogStatisticsInternalModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.Questioning") Then
		QuestioningModule = CommonUse.CommonModule("Questioning");
		QuestioningModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.Banks") Then
		BankOperationsModule = CommonUse.CommonModule("BankOperations");
		BankOperationsModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.BusinessProcessesAndTasks") Then
		BusinessProcessesAndTasksServerModule = CommonUse.CommonModule("BusinessProcessesAndTasksServer");
		BusinessProcessesAndTasksServerModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.Currencies") Then
		CurrencyRateOperationsModule = CommonUse.CommonModule("CurrencyRateOperations");
		CurrencyRateOperationsModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.ReportOptions") Then
		ReportOptionsModule = CommonUse.CommonModule("ReportOptions");
		ReportOptionsModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.Interactions") Then
		InteractionsModule = CommonUse.CommonModule("Interactions");
		InteractionsModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
		EmailManagementModule = CommonUse.CommonModule("EmailManagement");
		EmailManagementModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.ObjectVersioning") Then
		ObjectVersioningModule = CommonUse.CommonModule("ObjectVersioning");
		ObjectVersioningModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.WorkSchedules") Then
		WorkSchedulesModule = CommonUse.CommonModule("WorkSchedules");
		WorkSchedulesModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.EditProhibitionDates") Then
		EditProhibitionDatesInternalModule = CommonUse.CommonModule("EditProhibitionDatesService");
		EditProhibitionDatesInternalModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
		AdditionalReportsAndDataProcessorsModule = CommonUse.CommonModule("AdditionalReportsAndDataProcessors");
		AdditionalReportsAndDataProcessorsModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
		AdditionalReportsAndDataProcessorsSafeModeInternalModule = CommonUse.CommonModule("AdditionalReportsAndDataProcessorsSafeModeInternal");
		AdditionalReportsAndDataProcessorsSafeModeInternalModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.UserSessions") Then
		InfobaseConnectionsModule = CommonUse.CommonModule("InfobaseConnections");
		InfobaseConnectionsModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.UserNotes") Then
		UserNotesInternalModule = CommonUse.CommonModule("UserNotesInternal");
		UserNotesInternalModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.InformationOnStart") Then
		InformationOnStartModule = CommonUse.CommonModule("InformationOnStart");
		InformationOnStartModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.CalendarSchedules") Then
		CalendarSchedulesModule = CommonUse.CommonModule("CalendarSchedules");
		CalendarSchedulesModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.ContactInformation") Then
		ContactInformationManagementModule = CommonUse.CommonModule("ContactInformationManagement");
		ContactInformationManagementModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.DynamicConfigurationUpdateControl") Then
		ContactInformationManagementModule = CommonUse.CommonModule("DynamicConfigurationUpdateControlInternal");
		ContactInformationManagementModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.UserReminders") Then
		UserRemindersInternalModule = CommonUse.CommonModule("UserRemindersInternal");
		UserRemindersInternalModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.InfobaseVersionUpdate") Then
		InfobaseUpdateModule = CommonUse.CommonModule("InfobaseUpdateInternal");
		InfobaseUpdateModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.DataExchange") Then
		DataExchangeServerModule = CommonUse.CommonModule("DataExchangeServer");
		DataExchangeServerModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.ConfigurationUpdate") Then
		ConfigurationUpdateModule = CommonUse.CommonModule("ConfigurationUpdate");
		ConfigurationUpdateModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.Companies") Then
		CompaniesInternalModule = CommonUse.CommonModule("CompaniesInternal");
		CompaniesInternalModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.SendSMS") Then
		CompaniesInternalModule = CommonUse.CommonModule("SendSMS");
		CompaniesInternalModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.PerformanceMonitor") Then
		PerformanceMonitorInternalModule = CommonUse.CommonModule("PerformanceMonitorInternal");
		PerformanceMonitorInternalModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.Print") Then
		PrintManagementModule = CommonUse.CommonModule("PrintManagement");
		PrintManagementModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.FullTextSearch") Then
		FullTextSearchServerModule = CommonUse.CommonModule("FullTextSearchServer");
		FullTextSearchServerModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		GetFilesFromInternetInternalModule = CommonUse.CommonModule("GetFilesFromInternetInternal");
		GetFilesFromInternetInternalModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.Users") Then
		UsersInternalModule = CommonUse.CommonModule("UsersInternal");
		UsersInternalModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.AttachedFiles") Then
		AttachedFilesInternalModule = CommonUse.CommonModule("AttachedFilesInternal");
		AttachedFilesInternalModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations") Then
		SaasOperationsModule = CommonUse.CommonModule("SaaSOperations");
		SaasOperationsModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.AddressClassifierSaaS") Then
		AddressClassifierInternalSaaSModule = CommonUse.CommonModule("AddressClassifierInternalSaaS");
		AddressClassifierInternalSaaSModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.BanksSaaS") Then
		BanksInternalSaaSModule = CommonUse.CommonModule("BanksInternalSaaS");
		BanksInternalSaaSModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.CurrenciesSaaS") Then
		CurrencyRatesInternalSaaSModule = CommonUse.CommonModule("CurrencyRatesInternalSaaS");
		CurrencyRatesInternalSaaSModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.CalendarSchedulesSaaS") Then
		CalendarSchedulesInternalSaaSModule = CommonUse.CommonModule("CalendarSchedulesInternalSaaS");
		CalendarSchedulesInternalSaaSModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS") Then
		DataExchangeSaaSModule = CommonUse.CommonModule("DataExchangeSaaS");
		DataExchangeSaaSModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.MessageExchange") Then
		MessageExchangeModule = CommonUse.CommonModule("MessageExchange");
		MessageExchangeModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
		MessageInterfacesSaaSModule = CommonUse.CommonModule("MessageInterfacesSaaS");
		MessageInterfacesSaaSModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.InfobaseVersionUpdateSaaS") Then
		InfobaseUpdateInternalSaaSModule = CommonUse.CommonModule("InfobaseUpdateInternalSaaS");
		InfobaseUpdateInternalSaaSModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.JobQueue") Then
		
		JobQueueInternalModule = CommonUse.CommonModule("JobQueueInternal");
		JobQueueInternalModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
		
		If CommonUseCached.IsSeparatedConfiguration() Then
			JobQueueInternalDataSeparationModule = CommonUse.CommonModule("JobQueueInternalDataSeparation");
			JobQueueInternalDataSeparationModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
		EndIf;
		
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.SuppliedData") Then
		SuppliedDataModule = CommonUse.CommonModule("SuppliedData");
		SuppliedDataModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.DataAreaBackup") Then
		DataAreaBackupModule = CommonUse.CommonModule("DataAreaBackup");
		DataAreaBackupModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.RemoteAdministration") Then
		RemoteAdministrationInternalModule = CommonUse.CommonModule("RemoteAdministrationInternal");
		RemoteAdministrationInternalModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.AccessManagementSaaS") Then
		AccessManagementInternalSaaSModule = CommonUse.CommonModule("AccessManagementInternalSaaS");
		AccessManagementInternalSaaSModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.FileFunctionsSaaS") Then
		FileFunctionsInternalSaaSModule = CommonUse.CommonModule("FileFunctionsInternalSaaS");
		FileFunctionsInternalSaaSModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.EmailOperations") Then
		EmailOperationsModule = CommonUse.CommonModule("EmailOperationsInternal");
		EmailOperationsModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.FileOperations") Then
		FileOperationsInternalModule = CommonUse.CommonModule("FileOperationsInternal");
		FileOperationsInternalModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.ReportMailing") Then
		ReportMailingModule = CommonUse.CommonModule("ReportMailing");
		ReportMailingModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.ScheduledJobs") Then
		ScheduledJobsInternalModule = CommonUse.CommonModule("ScheduledJobsInternal");
		ScheduledJobsInternalModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.InfobaseBackup") Then
		InfobaseBackupServerModule = CommonUse.CommonModule("InfobaseBackupServer");
		InfobaseBackupServerModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.Properties") Then
		PropertyManagementInternalModule = CommonUse.CommonModule("PropertyManagementInternal");
		PropertyManagementInternalModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.AccessManagement") Then
		AccessManagementInternalModule = CommonUse.CommonModule("AccessManagementInternal");
		AccessManagementInternalModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.TotalsAndAggregatesManagement") Then
		TotalsAndAggregatesManagementIntenalModule = CommonUse.CommonModule("TotalsAndAggregatesManagementIntenal");
		TotalsAndAggregatesManagementIntenalModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.FileFunctions") Then
		FileFunctionsInternalModule = CommonUse.CommonModule("FileFunctionsInternal");
		FileFunctionsInternalModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		DigitalSignatureModule = CommonUse.CommonModule("DigitalSignature");
		DigitalSignatureModule.InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers);
	EndIf;
	
EndProcedure

// Retrieves the infobase ID.
// Sets the ID if it is not defined.
// The InfobaseID constant cannot be included in the exchange plan contents and must have the
// same value in each infobase.
//
Function InfobaseID() Export
	
	InfobaseID = Constants.InfobaseID.Get();
	
	If IsBlankString(InfobaseID) Then
		
		InfobaseID = New UUID();
		Constants.InfobaseID.Set(String(InfobaseID));
		
	EndIf;
	
	Return InfobaseID;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Additional base functionality for analyzing client parameters on the server

// Returns a fixed map that contains some client parameters:
//  LaunchParameter - String, InfobaseConnectionString - String - connection string, get on
//                    the client.
//
// Returns an empty fixed map, if CurrentRunMode() = Undefined.
//
Function ClientParametersOnServer() Export
	
	SetPrivilegedMode(True);
	ClientParameters = SessionParameters.ClientParametersOnServer;
	SetPrivilegedMode(False);
	
	If ClientParameters.Count() = 0
	   And CurrentRunMode() <> Undefined Then
		
		Raise NStr("en = 'The client parameters on server are not filled.'");
	EndIf;
	
	Return ClientParameters;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Procedure for setting/upgrading/retrieving application parameters (caches).

// Returns application parameters to be used (fixed data), that are, for example, cache.
//
// Parameters:
//  ConstantName - String - constant name (application parameter group name).
//
Function ApplicationParameters(ConstantName) Export
	
	Return StandardSubsystemsCached.ApplicationParameters(ConstantName);
	
EndFunction


// Checks application parameters to be used (fixed data), that are, for example, cache.
//
// Parameters:
//  ConstantName   - String - constant name (application parameter group name).
//  ParameterNames - String - list of parameters to be in the constant.
//                   Is required when retrieving updated data through the *Cached module for
//                   locking retrieving if there are group parameters (constants) that are not
//                   updated.
//                   Does not required when retrieving data for update.
//  Cancel          - Undefined - raise an exception if the parameters are not updated.
//                  - Boolean - return value - do not raise an exception but set to True if
//                    the parameters are not updated.
//
Procedure CheckIfApplicationParametersUpdated(ConstantName, ParameterNames = "", Cancel = Undefined) Export
	
	If ParameterNames <> "" Then
		UpdateRequired = False;
		
		If CommonUseCached.DataSeparationEnabled() Then
			UpdateRequired =
				InfobaseUpdateInternal.SharedInfobaseDataUpdateRequired();
		Else
			UpdateRequired =
				InfobaseUpdate.InfobaseUpdateRequired();
		EndIf;
		
		If UpdateRequired Then
			
			SetPrivilegedMode(True);
			AllUpdatedParameters = SessionParameters.ClientParametersOnServer.Get(
				"AllUpdatedApplicationParameters");
			SetPrivilegedMode(False);
			
			If AllUpdatedParameters <> Undefined Then
				If AllUpdatedParameters.Get("*") <> Undefined Then
					UpdateRequired = False;
				Else
					UpdatedParameters = AllUpdatedParameters.Get(ConstantName);
					If UpdatedParameters <> Undefined Then
						UpdateRequired = False;
						RequiredParameters = New Structure(ParameterNames);
						For Each KeyAndValue In RequiredParameters Do
							If UpdatedParameters.Get(KeyAndValue.Key) = Undefined Then
								UpdateRequired = True;
								Break;
							EndIf;
						EndDo;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		
		If UpdateRequired Then
			If Cancel <> Undefined Then
				Cancel = True;
				Return;
			EndIf;
			If CurrentRunMode() = Undefined Then
				Raise
					NStr("en = 'The application is being updated. Cannot log on to the application now.'");
			Else
				Raise
					NStr("en = 'Invalid access to not updated application parameters (for example, to session parameters):
					           |- if data is accessed from a form on the start page (desktop), make sure it has the CommonUse.OnCreateAtServer procedure call;
					           |  - otherwise move applied script call to procedures that are executed after application parameter update.'");
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

// Returns application parameter changes according to the current configuration version and
// the current infobase version.
//
// Parameters:
//  Parameters    - value extracted from the constant whose name was passed to the
//                  AddApplicationParameterChanges procedure.
//
//  ParameterName - String - passed as the ParameterName parameter to the AddParameterChanges 
//                  procedure.
//
// Returns:
//  Undefined - means everything changed. Is returned in case of initial infobase or data area
//              filling.
//  Array     - contains values of the changes. Can contain several elements, for example, when
//              data area has not been updated for a long time.
//
Function ApplicationParameterChanges(Parameters, ParameterName) Export
	
	LastChanges = Parameters["ParameterChanges" + ParameterName].Get();
	
	Version = Metadata.Version;
	NextVersion = NextVersion(Version);
	
	If CommonUseCached.DataSeparationEnabled()
	   And Not CommonUseCached.CanUseSeparatedData() Then
		
		// The area update plan is created only for areas whose versions are not lower then the
		// version of shared data. For other areas, all update handlers are executed.
		
		// Version of shared (common) data.
		InfobaseVersion = InfobaseUpdateInternal.InfobaseVersion(Metadata.Name, True);
	Else
		InfobaseVersion = InfobaseUpdateInternal.InfobaseVersion(Metadata.Name);
	EndIf;
	
	
	// In case of initial filling, application parameter changes are not defined.
	If CommonUseClientServer.CompareVersions(InfobaseVersion, "0.0.0.0") = 0 Then
		Return Undefined;
	EndIf;
	
	
	UpdateOutsideInfobaseUpdate = CommonUseClientServer.CompareVersions(InfobaseVersion, Version) = 0;
	
	 //Do not updating to the higher versions except when updating outside the infobase update,
	 //which is when the infobase version equals the configuration version.
	 //In this case the changes to the next version are selected in addition.
	
	Index = LastChanges.Count()-1;
	While Index >=0 Do
		RevisionVersion = LastChanges[Index].ConfigurationVersion;
		
		If CommonUseClientServer.CompareVersions(InfobaseVersion, RevisionVersion) >= 0
		   And Not (  UpdateOutsideInfobaseUpdate
		         And CommonUseClientServer.CompareVersions(NextVersion, RevisionVersion) = 0) Then
			
			LastChanges.Delete(Index);
		EndIf;
		Index = Index - 1;
	EndDo;
	
	Return LastChanges.UnloadColumn("Changes");
	
EndFunction

// Sets auxiliary data for application run, stored in shared constants.
//
// Parameters:
//  ConstantName   - String - name of the shared constant that store the parameter value.
//  ParameterName  - String - name of the parameter to be set (without the ParameterChanges prefix).
//  ParameterValue - Fixed data to be set as the parameter values.
//
Procedure SetApplicationParameter(ConstantName, ParameterName, ParameterValue) Export
	
	DataLock = New DataLock;
	LockItem = DataLock.Add("Constant." + ConstantName);
	LockItem.Mode = DataLockMode.Exclusive;
	
	BeginTransaction();
	Try
		DataLock.Lock();
		
		Parameters = Constants[ConstantName].Get().Get();
		If TypeOf(Parameters) <> Type("Structure") Then
			Parameters = New Structure;
		EndIf;
		
		Parameters.Insert(ParameterName, ParameterValue);
		
		ValueManager = Constants[ConstantName].CreateValueManager();
		ValueManager.DataExchange.Load = True;
		ValueManager.DataExchange.Recipients.AutoFill = False;
		ValueManager.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
		ValueManager.Value = New ValueStorage(Parameters);
		ValueManager.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	RefreshReusableValues();
	
EndProcedure


// Adds changes of the auxiliary data for application run, stored in shared constants.
//
// Parameters:
//  ConstantName     - String - name of the shared constant that store the parameter value.
//  ParameterName    - String - name of the parameter to be set.
//  ParameterChanges - fixed data to be registered as parameter changes.
//                     Changes are not added if the value of ParameterChange is not filled.
//
//  Note: in case of initial infobase or shared data filling, parameter changes are not added.
//
Procedure AddApplicationParameterChanges(ConstantName, ParameterName, Val ParameterChanges) Export
	
	// Retrieving the infobase or shared data version.
	InfobaseVersion = InfobaseUpdateInternal.InfobaseVersion(Metadata.Name);
	
	 //In case of initial filling, parameter changes are not added.
	If CommonUseClientServer.CompareVersions(InfobaseVersion, "0.0.0.0") = 0 Then
		ParameterChanges = Undefined;
	EndIf;
	
	DataLock = New DataLock;
	LockItem = DataLock.Add("Constant." + ConstantName);
	LockItem.Mode = DataLockMode.Exclusive;
	
	BeginTransaction();
	Try
		DataLock.Lock();
		
		UpdateChangeContent = False;
		Parameters = StandardSubsystemsCached.ApplicationParameters(ConstantName);
		
		ChangeStoringParameterName = "ParameterChanges" + ParameterName;
		
		If Parameters.Property(ChangeStoringParameterName) Then
			LastChanges = Parameters[ChangeStoringParameterName].Get();
			
			If TypeOf(LastChanges)          <> Type("ValueTable")
			 Or LastChanges.Columns.Count() <> 2
			 Or LastChanges.Columns[0].Name <> "ConfigurationVersion"
			 Or LastChanges.Columns[1].Name <> "Changes" Then
				
				LastChanges = Undefined;
			EndIf;
		Else
			LastChanges = Undefined;
		EndIf;
		
		If LastChanges = Undefined Then
			UpdateChangeContent = True;
			LastChanges = New ValueTable;
			LastChanges.Columns.Add("ConfigurationVersion");
			LastChanges.Columns.Add("Changes");
		EndIf;
		
		If ValueIsFilled(ParameterChanges) Then
			
			// If there is an update outside the infobase update, add the changes to the next version
			// to keep these changes when updating the infobase.
			Version = Metadata.Version;
			
			UpdateOutsideInfobaseUpdate =
				CommonUseClientServer.CompareVersions(InfobaseVersion , Version) = 0;
			
			If UpdateOutsideInfobaseUpdate Then
				Version = NextVersion(Version);
			EndIf;
			
			UpdateChangeContent = True;
			Row = LastChanges.Add();
			Row.Changes              = ParameterChanges;
			Row.ConfigurationVersion = Version;
		EndIf;
		
		EarliestInfobaseVersion = InfobaseUpdateInternalCached.EarliestInfobaseVersion();
		
		// Deleting changes for infobase versions earlier than minimum one instead of versions
		// earlier or equal to the minimum one, to provide a feature to update outside the infobase
		// update.
		Index = LastChanges.Count()-1;
		While Index >=0 Do
			RevisionVersion = LastChanges[Index].ConfigurationVersion;
			
			If CommonUseClientServer.CompareVersions(EarliestInfobaseVersion, RevisionVersion) > 0 Then
				LastChanges.Delete(Index);
				UpdateChangeContent = True;
			EndIf;
			Index = Index - 1;
		EndDo;
		
		If UpdateChangeContent Then
			SetApplicationParameter(
				ConstantName,
				ChangeStoringParameterName,
				New ValueStorage(LastChanges));
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Registers application parameter update completion, to make them usable in the session of
// their update.
// 
Procedure ConfirmApplicationParametersUpdate(ConstantName, ParameterName) Export
	
	SetPrivilegedMode(True);
	
	SetPrivilegedMode(True);
	ClientParametersOnServer = New Map(SessionParameters.ClientParametersOnServer);
	
	AllUpdatedParameters = ClientParametersOnServer.Get("AllUpdatedApplicationParameters");
	If AllUpdatedParameters = Undefined Then
		AllUpdatedParameters = New Map;
		UpdatedParameters = New Map;
	Else
		UpdatedParameters = AllUpdatedParameters.Get(ConstantName);
		AllUpdatedParameters = New Map(AllUpdatedParameters);
		If UpdatedParameters = Undefined Then
			UpdatedParameters = New Map;
		Else
			UpdatedParameters = New Map(UpdatedParameters);
		EndIf;
	EndIf;
	UpdatedParameters.Insert(ParameterName, True);
	AllUpdatedParameters.Insert(ConstantName, New FixedMap(UpdatedParameters));
	
	ClientParametersOnServer.Insert("AllUpdatedApplicationParameters",
		New FixedMap(AllUpdatedParameters));
	
	SessionParameters.ClientParametersOnServer = New FixedMap(ClientParametersOnServer);
	
EndProcedure


// Deletes auxiliary data for application run, stored in shared constants.
//
// Parameters:
//  ConstantName  - String - name of the shared constant that store the parameter value.
//  ParameterName - String - name of the parameter to be set (without the ParameterChanges prefix).
//
Procedure DeleteApplicationParameter(ConstantName, ParameterName) Export
	
	DataLock = New DataLock;
	LockItem = DataLock.Add("Constant." + ConstantName);
	LockItem.Mode = DataLockMode.Exclusive;
	
	Write = False;
	
	BeginTransaction();
	Try
		DataLock.Lock();
		
		Parameters = Constants[ConstantName].Get().Get();
		If TypeOf(Parameters) <> Type("Structure") Then
			Return;
		EndIf;
		
		If Parameters.Property(ParameterName) Then
			Parameters.Delete(ParameterName);
			Write = True;
		EndIf;
		
		ChangeStoringParameterName = "ParameterChanges" + ParameterName;
		
		If Parameters.Property(ChangeStoringParameterName) Then
			Parameters.Delete(ChangeStoringParameterName);
			Write = True;
		EndIf;
		
		If Write Then
			ValueManager = Constants[ConstantName].CreateValueManager();
			ValueManager.DataExchange.Load = True;
			ValueManager.DataExchange.Recipients.AutoFill = False;
			ValueManager.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
			ValueManager.Value = New ValueStorage(Parameters);
			ValueManager.Write();
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If Write Then
		RefreshReusableValues();
	EndIf;
	
EndProcedure


////////////////////////////////////////////////////////////////////////////////
// Additional base functionality for data exchange

// Validates the exchange plan content. Checks whether mandatory objects are included and
// exception objects are excluded.
//
// Parameters:
//  ExchangePlanName - String, ExchangePlanRef - exchange plan name or reference to the
//                     exchange plan node to be validated.
//
Procedure ValidateExchangePlanContent(Val ExchangePlanName) Export
	
	If TypeOf(ExchangePlanName) <> Type("String") Then
		ExchangePlanName = ExchangePlanName.Metadata().Name;
	EndIf;
	
	DistributedInfobase = Metadata.ExchangePlans[ExchangePlanName].DistributedInfobase;
	ExchangePlanContent = Metadata.ExchangePlans[ExchangePlanName].Content;
	
	Include = New Array;
	Exclude = New Array;
	DisableAutoRecord = New Array;
	
	// Retrieving the list of the mandatory objects and the objects to be excluded
	MandatoryObjects = New Array;
	ExceptionObjects = New Array;
	InitialImageObjects = New Array;
	
	// Retrieving mandatory objects
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.BaseFunctionality\OnGetMandatoryExchangePlanObjects");
	For Each Handler In EventHandlers Do
		
		DistributedInfobaseFlag = DistributedInfobase;
		
		Handler.Module.OnGetMandatoryExchangePlanObjects(MandatoryObjects, DistributedInfobaseFlag);
	EndDo;
	
	// Retrieving objects to be excluded
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.BaseFunctionality\ExchangePlanObjectsToExcludeOnGet");
	For Each Handler In EventHandlers Do
		
		DistributedInfobaseFlag = DistributedInfobase;
		
		Handler.Module.ExchangePlanObjectsToExcludeOnGet(ExceptionObjects, DistributedInfobaseFlag);
	EndDo;
	
	If DistributedInfobaseFlag Then
		
		// Retrieving initial image objects
		EventHandlers = CommonUse.InternalEventHandlers(
			"StandardSubsystems.BaseFunctionality\OnGetExchangePlanInitialImageObjects");
		For Each Handler In EventHandlers Do
			
			Handler.Module.OnGetExchangePlanInitialImageObjects(InitialImageObjects);
			
		EndDo;
		
		For Each Object In InitialImageObjects Do
			
			MandatoryObjects.Add(Object);
			
		EndDo;
		
	EndIf;
	
	// Validating the list of mandatory objects for the exchange plan content
	For Each Object In MandatoryObjects Do
		
		If ExchangePlanContent.Find(Object) = Undefined Then
			
			Include.Add(Object);
			
		EndIf;
		
	EndDo;
	
	// Validating the list of objects to be excluded from the exchange plan content
	For Each Object In ExceptionObjects Do
		
		If ExchangePlanContent.Find(Object) <> Undefined Then
			
			Exclude.Add(Object);
			
		EndIf;
		
	EndDo;
	
	// Checking the AutoRecord property. AutoRecord of all initial image objects must be disabled.
	For Each ContentItem In ExchangePlanContent Do
		
		If InitialImageObjects.Find(ContentItem.Metadata) <> Undefined
			And ContentItem.AutoRecord <> AutoChangeRecord.Deny Then
			
			DisableAutoRecord.Add(ContentItem.Metadata);
			
		EndIf;
		
	EndDo;
	
	// Generating and displaying an exception text if necessary
	If Include.Count() <> 0
		Or Exclude.Count() <> 0
		Or DisableAutoRecord.Count() <> 0 Then
		
		If Include.Count() <> 0 Then
			
			ExceptionDetails1 = StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'The following metadata objects must be included in the %1 exchange plan content: %2'"),
				ExchangePlanName,
				StringFunctionsClientServer.StringFromSubstringArray(MetadataObjectPresentation(Include), ","));
			
		EndIf;
		
		If Exclude.Count() <> 0 Then
			
			ExceptionDetails2 = StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'The following metadata objects must NOT be included in the %1 exchange plan content: %2'"),
				ExchangePlanName,
				StringFunctionsClientServer.StringFromSubstringArray(MetadataObjectPresentation(Exclude), ","));
			
		EndIf;
		
		If DisableAutoRecord.Count() <> 0 Then
			
			ExceptionDetails3 = StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Objects with AutoRecord enabled must not be included in the %1 exchange plan content.
				|The following metadata object AutoRecort property must be disabled: %2'"),
				ExchangePlanName,
				StringFunctionsClientServer.StringFromSubstringArray(MetadataObjectPresentation(DisableAutoRecord), ","));
			
		EndIf;
		
		ExceptionDetails = "[ExceptionDetails1]
		|
		|[ExceptionDetails2]
		|
		|[ExceptionDetails3]";
		
		ExceptionDetails = StrReplace(ExceptionDetails, "[ExceptionDetails1]", ExceptionDetails1);
		ExceptionDetails = StrReplace(ExceptionDetails, "[ExceptionDetails2]", ExceptionDetails2);
		ExceptionDetails = StrReplace(ExceptionDetails, "[ExceptionDetails3]", ExceptionDetails3);
		
		Raise TrimAll(ExceptionDetails);
		
	EndIf;
	
EndProcedure

// Determines whether the passed object is an initial image object of the subordinate DIB node.
// 
// Parameters:
//  Object - MetadataObject - object to be validated.
// 
//  Returns:
//   Boolean - True if the object is used in DIB only when creating an initial image of a
//             subordinate node.
// 
Function IsDIBModeInitialImageObject(Val Object) Export
	
	Return StandardSubsystemsCached.InitialImageObjects(
		).Get(Object.FullName()) <> Undefined;
	
EndFunction


// Records changes of the object for all exchange plan nodes.
// The separated configurations must meet the following conditions:
//  - exchange plan must be shared;
//  - object to be registered must be shared.
//
// Parameters:
//  Object          - Data object (CatalogObject, DocumentObject and so on) - Object to be 
//                    registered. The object must be shared, otherwise an exception is raised.
//
// ExchangePlanName - String - Name of the exchange plan where the object is registered in all
//                    nodes. The exchange plan must be shared, otherwise an exception is
//                    raised.
//
Procedure RecordObjectChangesInAllNodes(Val Object, Val ExchangePlanName) Export
	
	If Metadata.ExchangePlans[ExchangePlanName].Content.Find(Object.Metadata()) = Undefined Then
		Return;
	EndIf;
	
	If CommonUseCached.DataSeparationEnabled() Then
		
		If CommonUseCached.CanUseSeparatedData() Then
			Raise NStr("en = 'Attempt to record shared data changes in the separated mode.'");
		EndIf;
		
		If Not CommonUseCached.IsSeparatedMetadataObject("ExchangePlan." + ExchangePlanName,
				CommonUseCached.MainDataSeparator())
			Then
			Raise NStr("en = 'Change registration for shared exchange plans does not supported.'");
		EndIf;
		
		If CommonUseCached.IsSeparatedMetadataObject(Object.Metadata().FullName(),
				CommonUseCached.MainDataSeparator())
			Then
			Raise NStr("en = 'Separated data change registration does not supported.'");
		EndIf;
		
		QueryText =
		"SELECT
		|	ExchangePlan.Ref AS Recipient
		|FROM
		|	ExchangePlan.[ExchangePlanName] AS ExchangePlan
		|WHERE
		|	ExchangePlan.RegisterChanges
		|	And Not ExchangePlan.DeletionMark";
		
		QueryText = StrReplace(QueryText, "[ExchangePlanName]", ExchangePlanName);
		
		Query = New Query;
		Query.Text = QueryText;
		
		Recipients = Query.Execute().Unload().UnloadColumn("Recipient");
		
		For Each Recipient In Recipients Do
			
			Object.DataExchange.Recipients.Add(Recipient);
			
		EndDo;
		
	Else
		
		QueryText =
		"SELECT
		|	ExchangePlan.Ref AS Recipient
		|FROM
		|	ExchangePlan.[ExchangePlanName] AS ExchangePlan
		|WHERE
		|	ExchangePlan.Ref <> &ThisNode
		|	And Not ExchangePlan.DeletionMark";
		
		QueryText = StrReplace(QueryText, "[ExchangePlanName]", ExchangePlanName);
		
		Query = New Query;
		Query.SetParameter("ThisNode", ExchangePlans[ExchangePlanName].ThisNode());
		Query.Text = QueryText;
		
		Recipients = Query.Execute().Unload().UnloadColumn("Recipient");
		
		For Each Recipient In Recipients Do
			
			Object.DataExchange.Recipients .Add(Recipient);
			
		EndDo;
		
	EndIf;
	
EndProcedure


////////////////////////////////////////////////////////////////////////////////
// Handlers of exchange data sending and receiving in a DIB

// Handler of the same name event, which occurs when exchanging data in a distributed infobase.
//
// Parameters:
// see the OnSendDataToSlave() event handler description in the syntax assistant.
// 
Procedure OnSendDataToSlave(DataItem, ItemSend, Val InitialImageCreating, Val Recipient = Undefined) Export
	
	IgnoreInitialImageObjectSending(DataItem, ItemSend, InitialImageCreating);
	
	If ItemSend = DataItemSend.Ignore Then
		Return;
	EndIf;
	
	// Metadata object IDs are sent in another exchange message section.
	IgnoreMetadataObjectIDSending(DataItem, ItemSend, InitialImageCreating);
	
	If ItemSend = DataItemSend.Ignore Then
		Return;
	EndIf;
	
	// Adding data exchange subsystem script first.
	If CommonUse.SubsystemExists("StandardSubsystems.DataExchange") Then
		DataExchangeEventsModule = CommonUse.CommonModule("DataExchangeEvents");
		DataExchangeEventsModule.DataOnSendToRecipient(DataItem, ItemSend, InitialImageCreating, Recipient, False);
		
		If ItemSend = DataItemSend.Ignore Then
			Return;
		EndIf;
	EndIf;
	
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.BaseFunctionality\OnSendDataToSlave");
	
	For Each Handler In EventHandlers Do
		Handler.Module.OnSendDataToSlave(
			DataItem, ItemSend, InitialImageCreating, Recipient);
		If ItemSend = DataItemSend.Ignore Then
			Return;
		EndIf;
	EndDo;
	
	// Adding data exchange subsystem script last in the SaaS model.
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS") Then
		DataExchangeSaaSModule = CommonUse.CommonModule("DataExchangeSaaS");
		DataExchangeSaaSModule.OnSendDataToSlave(DataItem, ItemSend, InitialImageCreating, Recipient);
		
		If ItemSend = DataItemSend.Ignore Then
			Return;
		EndIf;
	EndIf;
	
EndProcedure


// Handler of the same name event, which occurs when exchanging data in a distributed infobase.
//
// Parameters:
//  see OnSendDataToMaster() event handler description in the syntax assistant.
// 
Procedure OnSendDataToMaster(DataItem, ItemSend, Val Recipient = Undefined) Export
	
	IgnoreInitialImageObjectSending(DataItem, ItemSend);
	
	If ItemSend = DataItemSend.Ignore Then
		Return;
	EndIf;
	
	// Metadata object IDs are sent in another exchange message section.
	IgnoreMetadataObjectIDSending(DataItem, ItemSend);
	
	If ItemSend = DataItemSend.Ignore Then
		Return;
	EndIf;
	
	// Adding data exchange subsystem script first.
	// Do not calling the handler when sending data to the master node because restrictions of the
	// «bottom-up» migration in DIB do not provided by default.
	
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.BaseFunctionality\OnSendDataToMaster");
	
	For Each Handler In EventHandlers Do
		Handler.Module.OnSendDataToMaster(DataItem, ItemSend, Recipient);
		If ItemSend = DataItemSend.Ignore Then
			Return;
		EndIf;
	EndDo;
	
EndProcedure

// Handler of the same name event, which occurs when exchanging data in a distributed infobase.
//
// Parameters:
//  see the OnReceiveDataFromSlave() event handler description in the syntax assistant.
// 
Procedure OnReceiveDataFromSlave(DataItem, ItemReceive, SendBack, Val Sender = Undefined) Export
	
	IgnoreInitialImageObjectGetting(DataItem, ItemReceive);
	
	If ItemReceive = DataItemReceive.Ignore Then
		Return;
	EndIf;
	
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.BaseFunctionality\OnReceiveDataFromSlave");
	
	For Each Handler In EventHandlers Do
		Handler.Module.OnReceiveDataFromSlave(
			DataItem, ItemReceive, SendBack, Sender);
		If ItemReceive = DataItemReceive.Ignore Then
			Return;
		EndIf;
	EndDo;
	
	// Adding data exchange subsystem script last.
	If CommonUse.SubsystemExists("StandardSubsystems.DataExchange") Then
		DataExchangeEventsModule = CommonUse.CommonModule("DataExchangeEvents");
		DataExchangeEventsModule.OnReceiveDataFromSlaveInEnd(DataItem, ItemReceive, Sender );
	EndIf;
	
EndProcedure

// Handler of the same name event, which occurs when exchanging data in a distributed infobase.
//
// Parameters:
//  see the OnReceiveDataFromMaster() event handler description in the syntax assistant.
// 
Procedure OnReceiveDataFromMaster(DataItem, ItemReceive, SendBack, Val From = Undefined) Export
	
	IgnoreInitialImageObjectGetting(DataItem, ItemReceive);
	
	If ItemReceive = DataItemReceive.Ignore Then
		Return;
	EndIf;
	
	// Adding data exchange subsystem script first.
	If CommonUse.SubsystemExists("StandardSubsystems.DataExchange") Then
		DataExchangeEventsModule = CommonUse.CommonModule("DataExchangeEvents");
		DataExchangeEventsModule.OnReceiveDataFromMasterInBeginning(DataItem, ItemReceive, SendBack, From);
		
		If ItemReceive = DataItemReceive.Ignore Then
			Return;
		EndIf;
		
	EndIf;
	
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.BaseFunctionality\OnReceiveDataFromMaster");
	
	For Each Handler In EventHandlers Do
		Handler.Module.OnReceiveDataFromMaster(
			DataItem, ItemReceive, SendBack, From);
		If ItemReceive = DataItemReceive.Ignore Then
			Return;
		EndIf;
	EndDo;
	
	// Adding data exchange subsystem script last.
	If CommonUse.SubsystemExists("StandardSubsystems.DataExchange")
		And Not InitialImageCreating(DataItem) Then
		
		DataExchangeEventsModule = CommonUse.CommonModule("DataExchangeEvents");
		DataExchangeEventsModule.OnReceiveDataFromMasterInEnd(DataItem, ItemReceive, From);
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Base functionality internal event handlers

// Fills renaming of metadata objects that cannot be automatically found by type but whose
// references must be saved in the database (for example: subsystem, roles).
//
// For details see CommonUse.AddRenaming.
//
Procedure RenamedMetadataObjectsOnAdd(Total) Export
	
	If CommonUse.SubsystemExists("StandardSubsystems.ProgramSettings") Then
		SLAdministrationPanelDataProcessorModule = CommonUse.CommonModule("DataProcessors.SLAdministrationPanel");
		SLAdministrationPanelDataProcessorModule.RenamedMetadataObjectsOnAdd(Total);
	EndIf;
	
EndProcedure

// Fills a structure of parameters required for running the application on a client.
//
// Parameters:
//   Parameters - Structure - parameter structure.
//
Procedure StandardSubsystemClientLogicParametersOnAdd(Parameters) Export
	
	AddClientParameters(Parameters);
	
EndProcedure

// Fills an array of shared data types for which reference mapping is supported when importing
// data to another infobase.
//
// Parameters:
//  Types - Array of MetadataObject
//
Procedure OnFillCommonDataTypesSupportingRefMappingOnExport(Types) Export
	
	Types.Add(Metadata.Catalogs.MetadataObjectIDs);
	
EndProcedure

// Is used for retrieving metadata objects mandatory for the exchange plan.
// If there are objects in the subsystem, mandatory to be included in the exchange plan
// content, add these metadata objects to the Objects parameter.
//
// Parameters:
//  Objects             - Array - list of metadata objects to be included in the exchange plan
//                        content.
//  DistributedInfobase - Boolean - (read only) flag that shows whether objects for a DIB
//                        exchange plan are retrieved.
//                            True - list of DIB exchange plan objects is retrieved.
//                            False - list of non-DIB exchange plan objects is retrieved.
//
Procedure OnGetMandatoryExchangePlanObjects(Objects, Val DistributedInfobase) Export
	
	If DistributedInfobase Then
		
		Objects.Add(Metadata.Catalogs.MetadataObjectIDs);
		
	EndIf;
	
EndProcedure

// The procedure is used when getting metadata objects that must not be included in the exchange plan content.
// If there are objects in the subsystem, not to be included in the exchange plan content, add
// these metadata objects to the Objects parameter.
//
// Parameters:
//  Objects             - Array - list of metadata objects not to be included in the exchange
//                        plan content.
//  DistributedInfobase - Boolean - (read only) flag that shows whether objects for a DIB
//                        exchange plan are retrieved.
//                         True  - list of the objects to be excluded from a DIB exchange plan
//                                 is retrieved;
//                         False - list for an infobase that is not a DIB is retrieved.
//
Procedure ExchangePlanObjectsToExcludeOnGet(Objects, Val DistributedInfobase) Export
	
	If DistributedInfobase Then
		
		Objects.Add(Metadata.Constants.SystemTitle);
		Objects.Add(Metadata.Constants.UseSeparationByDataAreas);
		Objects.Add(Metadata.Constants.DontUseSeparationByDataAreas);
		Objects.Add(Metadata.Constants.IsStandaloneWorkstation);
		
		Objects.Add(Metadata.InformationRegisters.ProgramInterfaceCache);
		
	EndIf;
	
EndProcedure

// Is used for retrieving metadata objects to be included in the exchange plan content but do
// NOT included in the change record event subscription content of this exchange plan.
// These metadata objects are used only when creating initial image of a subordinate node and 
// do not migrate when exchanging.
// If there are objects in the subsystem, used only for creating initial image of a subordinate
// node, add these metadata objects to the Objects parameter.
//
// Parameters:
//  Objects - Array - configuration metadata object list.
//
Procedure OnGetExchangePlanInitialImageObjects(Objects) Export
	
	Objects.Add(Metadata.Constants.InternalEventParameters);
	
EndProcedure

// Contains settings of report option placement on the report panel.
//
// Parameters:
//   Settings - Collection - is used to set report settings and options. See ReportOptions.ConfigurationReportOptionSettingsTree();
//
// Details:
//   See ReportOptionsOverridable.SetupReportOptions().
//
Procedure ReportOptionsOnSetup(Settings) Export
	ReportOptionsModule = CommonUse.CommonModule("ReportOptions");
	ReportOptionsModule.SetupReportInManagerModule(Settings, Metadata.Reports.SearchForReferences);
EndProcedure

// Fills a list of requests for external permissions to be necessarily granted when creating
// infobase or updating the application.
//
// Parameters:
//  PermissionRequests - Array - list of values that the SafeMode.ExternalResourceRequest()
//                       function returns.
//
Procedure OnFillPermissionsToAccessExternalResources(PermissionRequests) Export
	
	Permissions = New Array();
	
	Permissions.Add(SafeMode.PermissionToUseTempDirectory(True, True,
		NStr("en = 'For application run.'"))); 
	Permissions.Add(SafeMode.PermissionToUsePrivilegedMode());

	PermissionRequests.Add(
		SafeMode.RequestToUseExternalResources(Permissions));
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Additional functions for handling types.

// Returns the reference type or the record key type of the specified metadata object.
// 
// Parameters:
//  MetadataObject - MetadataObject - register or object of reference type.
// 
//  Returns:
//   Type.
//
Function MetadataObjectReferenceOrMetadataObjectRecordKeyType(MetadataObject) Export
	
	If CommonUse.IsRegister(MetadataObject) Then
		
		If CommonUse.IsInformationRegister(MetadataObject) Then
			RegisterType = "InformationRegister";
			
		ElsIf CommonUse.IsAccumulationRegister(MetadataObject) Then
			RegisterType = "AccumulationRegister";
			
		ElsIf CommonUse.IsAccountingRegister(MetadataObject) Then
			RegisterType = "AccountingRegister";
			
		ElsIf CommonUse.IsCalculationRegister(MetadataObject) Then
			RegisterType = "CalculationRegister";
		EndIf;
		Type = Type(RegisterType + "RecordKey." + MetadataObject.Name);
	Else
		Manager = CommonUse.ObjectManagerByFullName(MetadataObject.FullName());
		Type = TypeOf(Manager.EmptyRef());
	EndIf;
	
	Return Type;
	
EndFunction


// Returns the object type or the record set type of the specified metadata object.
// 
// Parameters:
//  MetadataObject - MetadataObject - register or object of reference type.
// 
//  Returns:
//   Type.
//
Function MetadataObjectOrMetadataObjectRecordSetType(MetadataObject) Export
	
	If CommonUse.IsRegister(MetadataObject) Then
		
		If CommonUse.IsInformationRegister(MetadataObject) Then
			RegisterType = "InformationRegister";
			
		ElsIf CommonUse.IsAccumulationRegister(MetadataObject) Then
			RegisterType = "AccumulationRegister";
			
		ElsIf CommonUse.IsAccountingRegister(MetadataObject) Then
			RegisterType = "AccountingRegister";
			
		ElsIf CommonUse.IsCalculationRegister(MetadataObject) Then
			RegisterType = "CalculationRegister";
		EndIf;
		Type = Type(RegisterType + "RecordSet." + MetadataObject.Name);
	Else
		Manager = CommonUse.ObjectManagerByFullName(MetadataObject.FullName());
		ObjectKind = CommonUse.ObjectKindByType(TypeOf(Manager.EmptyRef()));
		Type = Type(ObjectKind + "Object." + MetadataObject.Name);
	EndIf;
	
	Return Type;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Procedure and function for handling forms

// Sets the font size for form group titles so they are correctly displayed in the 8.2 interface.
//
// Parameters:
//  Form       - ManagedForm - Form where title fonts are changed;
//  GroupNames - String - List of the form group names separated with commas.
//
Procedure SetGroupTitleRepresentation(Form, GroupNames = "") Export
	
	If ClientApplicationInterfaceCurrentVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		BoldFont = New Font(,, True);
		If Not ValueIsFilled(GroupNames) Then 
			For Each Item In Form.Items Do 
				If Type(Item) = Type("FormGroup") And
					Item.Type = FormGroupType.UsualGroup And
					Item.ShowTitle = True And ( 
					Item.Representation = UsualGroupRepresentation.NormalSeparation Or 
					Item.Representation = UsualGroupRepresentation.None ) Then 
						Item.TitleFont = BoldFont;
				EndIf;
			EndDo;
		Else
			TitleArray = StringFunctionsClientServer.SplitStringIntoSubstringArray(GroupNames,,, True);
			For Each TitleName In TitleArray Do
				Item = Form.Items[TitleName];
				If Item.Representation = UsualGroupRepresentation.NormalSeparation Or Item.Representation = UsualGroupRepresentation.None Then 
					Item.TitleFont = BoldFont;
				EndIf;
			EndDo;
		EndIf;
	EndIf;

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Other procedures and functions.

// Returns names of the predefined data for the specified metadata object. Can be required when
// updating the infobase.
//
// Parameters:
//  FullName - String - full name of a metadata object that can contain predefined items.
//
// Returns:
//  FixedArray.
//
Function PredefinedDataNames(FullName) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	CurrentTable.Ref AS Ref,
	|	CurrentTable.PredefinedDataName AS PredefinedDataName
	|FROM
	|	&CurrentTable AS CurrentTable
	|Where
	|	CurrentTable.Predefined = TRUE";
	
	Query.Text = StrReplace(Query.Text, "&CurrentTable", FullName);
	
	PredefinedDataNames = New ValueList;
	
	LogOnToDataArea = CommonUseCached.DataSeparationEnabled()
		And Not CommonUseCached.CanUseSeparatedData() 
		And CommonUseCached.IsSeparatedMetadataObject(FullName, CommonUseCached.MainDataSeparator());
		
	If LogOnToDataArea Then
		LogOnToZeroArea(True);
	EndIf;
	
	Try
		Selection = Query.Execute().Select();
	Except
		If LogOnToDataArea Then
			LogOnToZeroArea(False);
		EndIf;
		Raise;
	EndTry;
		
	While Selection.Next() Do
		PredefinedDataName = Selection.PredefinedDataName;
		If ValueIsFilled(PredefinedDataName) Then
			PredefinedDataNames.Add(PredefinedDataName);
		EndIf;
	EndDo;
		
	If LogOnToDataArea Then
		LogOnToZeroArea(False);
	EndIf;
	
	PredefinedDataNames.SortByValue();
	Return New FixedArray(PredefinedDataNames.UnloadValues());
	
EndFunction

// Returns additional details when application parameter problem occurs.
Function ApplicationRunParameterErrorClarificationForDeveloper() Export
	
	Return Chars.LF + Chars.LF +
		NStr("en = 'Information for developers: Perhaps auxiliary data that affects the application must be updated. To update the data, you can:
		           |- use the ""Developer tools: Auxiliary data update"" external data processor,
		           |- start the application with the 1C:Enterprise 8 command line parameter:
		           |  ""/С StartInfobaseUpdate"",
		           |- increase the configuration version number, so infobase data update handlers
		           |  will be executed during the next infobase startup.'");
	
EndFunction

#EndRegion

#Region InternalProceduresAndFunctions

// Returns the Subsystems Library version number.
//
Function LibVersion() Export
	
	Return StandardSubsystemsCached.SubsystemDescriptions().ByNames["StandardSubsystems"].Version;
	
EndFunction

// Returns a parameter structure required for this subsystem client script execution when the
// application starts, that is in following event handlers:
// - BeforeStart, 
// - OnStart.
//
// Important: when starting the application, do not use cache reset commands of modules that
// reuse return values because this can lead to unpredictable errors and unneeded server calls
//
// Parameters:
//   Parameters - Structure - parameter structure.
//
// Returns:
//   Boolean - False if further parameters filling must be aborted.
//
Function AddClientParametersOnStart(Parameters) Export
	
	// Mandatory parameters to continue application running.
	Parameters.Insert("DataSeparationEnabled", CommonUseCached.DataSeparationEnabled());
	
	Parameters.Insert("CanUseSeparatedData", 
		CommonUseCached.CanUseSeparatedData());
	
	Parameters.Insert("IsSeparatedConfiguration", CommonUseCached.IsSeparatedConfiguration());
	Parameters.Insert("HasAccessForUpdatingPlatformVersion", Users.InfobaseUserWithFullAccess(,True));
	
	Parameters.Insert("SubsystemNames", StandardSubsystemsCached.SubsystemNames());
	
	CommonParameters = CommonUse.CommonBaseFunctionalityParameters();
	Parameters.Insert("LowestPlatformVersion", CommonParameters.LowestPlatformVersion);
	Parameters.Insert("MustExit",            CommonParameters.MustExit);
	
	If Parameters.RetrievedClientParameters <> Undefined
	   And Parameters.RetrievedClientParameters.Count() = 0 Then
	
		SetPrivilegedMode(True);
		ClientLaunchParameter = SessionParameters.ClientParametersOnServer.Get("LaunchParameter");
		If Find(Lower(ClientLaunchParameter), Lower("StartInfobaseUpdate")) > 0 Then
			SetInfobaseUpdateStartup(True);
		EndIf;
		SetPrivilegedMode(False);
	EndIf;
	
	If Parameters.RetrievedClientParameters <> Undefined Then
		Parameters.Insert("InterfaceOptions", CommonUseCached.InterfaceOptions());
	EndIf;
	
	If Parameters.RetrievedClientParameters <> Undefined
	   And Not Parameters.RetrievedClientParameters.Property("ShowDeprecatedPlatformVersion")
	   And ShowDeprecatedPlatformVersion(Parameters) Then
		
		Parameters.Insert("ShowDeprecatedPlatformVersion");
		StandardSubsystemsServerCall.HideDesktopOnStart();
		Return False;
	EndIf;
	

	// Checking whether the application run will be continued.
	ErrorDescription = InfobaseUpdateInternal.InfobaseLockedForUpdate();
	If ValueIsFilled(ErrorDescription) Then
		Parameters.Insert("InfobaseLockedForUpdate", ErrorDescription);
		// Application will be closed.
		Return False;
	EndIf;
	
	
	SetPrivilegedMode(True);
	If Parameters.RetrievedClientParameters <> Undefined
	   And Not Parameters.RetrievedClientParameters.Property("ReconnectMasterNode")
	   And Not CommonUseCached.DataSeparationEnabled()
	   And ExchangePlans.MasterNode() = Undefined
	   And ValueIsFilled(Constants.MasterNode.Get()) Then
		
		SetPrivilegedMode(False);
		Parameters.Insert("ReconnectMasterNode", Users.InfobaseUserWithFullAccess());
		StandardSubsystemsServerCall.HideDesktopOnStart();
		Return False;
	EndIf;
	SetPrivilegedMode(False);
	
	If Parameters.RetrievedClientParameters <> Undefined
	   And Not (Parameters.DataSeparationEnabled And Not Parameters.CanUseSeparatedData)
	   And CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations") Then
		
		SaasOperationsModule = CommonUse.CommonModule("SaaSOperations");
		ErrorDescription = "";
		SaasOperationsModule.LockDataAreaOnStartOnCheck(ErrorDescription);
		If ValueIsFilled(ErrorDescription) Then
			Parameters.Insert("DataAreaLocked", ErrorDescription);
			// Application will be closed.
			Return False;
		EndIf;
	EndIf;
	

	If InfobaseUpdateInternal.MustCheckLegitimateSoftware() Then
		Parameters.Insert("CheckLegitimateSoftware");
	EndIf;
	

	If Parameters.RetrievedClientParameters <> Undefined
	   And Not Parameters.RetrievedClientParameters.Property("RetryDataExchangeMessageImportBeforeStart")
	   And CommonUse.IsSubordinateDIBNode()
	   And CommonUse.SubsystemExists("StandardSubsystems.DataExchange") Then
		
		DataExchangeServerCallModule = CommonUse.CommonModule("DataExchangeServerCall");
		If DataExchangeServerCallModule.RetryDataExchangeMessageImportBeforeStart() Then
			Parameters.Insert("RetryDataExchangeMessageImportBeforeStart");
			Try
				Parameters.Insert("ClientEventsHandlers", StandardSubsystemsCached.ProgramEventParameters(
					).EventHandlers.AtClient);
			Except
				// In case of the initial start, an exception is raised.
				// During the second call, parameters of internal events are updated in the
				// DataResynchronizationBeforeStart form, to support data synchronization connection
				// parameter setup (also for security profile features).
			EndTry;
			Return False;
		EndIf;
	EndIf;
	
	// Checking whether preliminary application parameter update is required.
	If Parameters.RetrievedClientParameters <> Undefined
	   And Not Parameters.RetrievedClientParameters.Property("ApplicationParametersUpdateRequired") Then
		
		If ApplicationParametersUpdateRequired() Then
			// Preliminary update will be executed.
			Parameters.Insert("ApplicationParametersUpdateRequired");
			Parameters.Insert("FileInfobase", CommonUse.FileInfobase());
			Return False;
		Else
			ConfirmApplicationParametersUpdate("*", "");
		EndIf;
	EndIf;
	
	// Mandatory parameters for all modes.
	Parameters.Insert("ClientEventsHandlers", StandardSubsystemsCached.ProgramEventParameters(
		).EventHandlers.AtClient);
	
	Parameters.Insert("DetailedInformation", Metadata.DetailedInformation);
	
	If InfobaseUpdateInternal.SharedInfobaseDataUpdateRequired() Then
		Parameters.Insert("SharedInfobaseDataUpdateRequired");
	EndIf;
	Parameters.Insert("InterfaceOptions", CommonUseCached.InterfaceOptions());
	
	SafeModeInternal.AddClientParametersOnStart(Parameters);
	
	If Parameters.DataSeparationEnabled And Not Parameters.CanUseSeparatedData Then
		Return False;
	EndIf;
	
	// Parameters for running the application in the local mode or in the session with separator
	// values set in the SaaS model.
	If InfobaseUpdate.InfobaseUpdateRequired() Then
		Parameters.Insert("InfobaseUpdateRequired");
		StandardSubsystemsServerCall.HideDesktopOnStart();
	EndIf;
	
	If Not Parameters.DataSeparationEnabled
		And CommonUse.SubsystemExists("StandardSubsystems.DataExchange") Then
		
		DataExchangeServerModule = CommonUse.CommonModule("DataExchangeServer");
		If DataExchangeServerModule.LoadDataExchangeMessage() Then
			Parameters.Insert("LoadDataExchangeMessage");
		EndIf;
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS") Then
		StandaloneModeInternalModule = CommonUse.CommonModule("StandaloneModeInternal");
		If StandaloneModeInternalModule.ContinueSettingUpStandaloneWorkstation(Parameters) Then
			Return False;
		EndIf;
	EndIf;
	
	AuthorizationError = UsersInternal.AuthenticateCurrentUser(True);
	If AuthorizationError <> "" Then
		Parameters.Insert("AuthorizationError", AuthorizationError);
		Return False;
	EndIf;
	
	AddCommonClientParameters(Parameters);
	
	Return True;
	
EndFunction

// Sets the infobase update start state.
// Privileged mode required.
//
// Parameters:
//  Started - Boolean - True to set the state, False to clear it.
//
Procedure SetInfobaseUpdateStartup(Started) Export
	
	CurrentParameters = New Map(SessionParameters.ClientParametersOnServer);
	
	If Started = True Then
		CurrentParameters.Insert("StartInfobaseUpdate", True);
		
	ElsIf CurrentParameters.Get("StartInfobaseUpdate") <> Undefined Then
		CurrentParameters.Delete("StartInfobaseUpdate");
	EndIf;
	
	SessionParameters.ClientParametersOnServer = New FixedMap(CurrentParameters);
	
EndProcedure


// Fills a parameter structure required for this subsystem client script execution. 
//
// Parameters:
//   Parameters - Structure - parameter structure.
//
Procedure AddClientParameters(Parameters) Export
	
	Parameters.Insert("SubsystemNames", StandardSubsystemsCached.SubsystemNames());
	Parameters.Insert("CanUseSeparatedData",
		CommonUseCached.CanUseSeparatedData());
	Parameters.Insert("DataSeparationEnabled", CommonUseCached.DataSeparationEnabled());
	
	Parameters.Insert("InterfaceOptions", CommonUseCached.InterfaceOptions());
	
	AddCommonClientParameters(Parameters);
	
	Parameters.Insert("ConfigurationName",    Metadata.Name);
	Parameters.Insert("ConfigurationSynonym", Metadata.Synonym);
	Parameters.Insert("ConfigurationVersion", Metadata.Version);
	Parameters.Insert("DetailedInformation",  Metadata.DetailedInformation);
	Parameters.Insert("DefaultLanguageCode",  Metadata.DefaultLanguage.LanguageCode);
	
	Parameters.Insert("AskConfirmationOnExit",
		AskConfirmationOnExit());
	
	// Parameters for external user connections
	Parameters.Insert("UserInfo", GetUserInfo());
	Parameters.Insert("COMConnectorName", CommonUse.COMConnectorName());
	
	SessionDate = CurrentSessionDate();
	UniversalSessionDate = ToUniversalTime(SessionDate, SessionTimeZone());
	Parameters.Insert("SessionTimeOffset", SessionDate); // saving server time, further it will be
	                                                     // replaced its difference with the
	                                                     // client time.
	Parameters.Insert("UniversalTimeCorrection", UniversalSessionDate - SessionDate);
	
	SafeModeInternal.AddClientParameters(Parameters);
	
EndProcedure

// Fills a structure parameters required for client script execution when starting the
// application and during its further running. 
//
// Parameters:
//   Parameters - Structure - parameter structure.
//
Procedure AddCommonClientParameters(Parameters) 
	
	If Not Parameters.DataSeparationEnabled Or Parameters.CanUseSeparatedData Then
		
		SetPrivilegedMode(True);
		Parameters.Insert("AuthorizedUser", Users.AuthorizedUser());
		Parameters.Insert("UserPresentation", String(Parameters.AuthorizedUser));
		Parameters.Insert("ApplicationPresentation", TrimAll(Constants.SystemTitle.Get()));
		SetPrivilegedMode(False);
		
	EndIf;
	
	Parameters.Insert("IsMasterNode", Not CommonUse.IsSubordinateDIBNode());
	Parameters.Insert("FileInfobase", CommonUse.FileInfobase());
	
	Parameters.Insert("DIBNodeConfigurationUpdateRequired",
		CommonUse.DIBSubordinateNodeConfigurationUpdateRequired());
	
	Parameters.Insert("IsBaseConfigurationVersion", IsBaseConfigurationVersion());
	
EndProcedure


// Returns an array of versions supported by the SubsystemName subsystem..
//
// Parameters:
// SubsystemName - String - Subsystem name.
//
// Returns:
//  Array - list of String type values.
//
Function SupportedVersions(SubsystemName) Export
	
	VersionArray = Undefined;
	SupportedVersionStructure = New Structure;
	
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.BaseFunctionality\SupportedInterfaceVersionsOnDefine");
	
	For Each Handler In EventHandlers Do
		Handler.Module.SupportedInterfaceVersionsOnDefine(SupportedVersionStructure);
	EndDo;
	
	SupportedVersionStructure.Property(SubsystemName, VersionArray);
	
	If VersionArray = Undefined Then
		Return CommonUse.ValueToXMLString(New Array);
	Else
		Return CommonUse.ValueToXMLString(VersionArray);
	EndIf;
	
EndFunction


// Returns a map of event names and arrays of their handlers.
// 
// Returns:
//  Structure - details on the event handlers:
//               * AtClient - Map -
//                             ** Key   - String - full event name,
//                             ** Value - Array - list of structures with the following
//                                        properties:
//                                         *** Version - String - handler version (empty if not
//                                                       specified),
//                                         *** Module  - String - name of the module, where the
//                                                       handler is.
//               * AtServer - Map -
//                             ** Key   - String - full event name,
//                             ** Value - Array - list of structures with the following
//                                properties:
//                                         *** Version - String - handler version (empty if not
//                                                       specified),
//                                         *** Module  - String - name of the module, where the
//                                                       handler is.
//
Function EventHandlers() Export
	
	SubsystemDescriptions = StandardSubsystemsCached.SubsystemDescriptions();
	
	// Defining all available application events.
	ClientEvents = New Array;
	ServerEvents  = New Array;
	ClientServiceEvents = New Array;
	ServerInternalEvents  = New Array;
	
	For Each Subsystem In SubsystemDescriptions.order Do
		Details = SubsystemDescriptions.ByNames[Subsystem];
		
		If Not Details.AddEvents
		   And Not Details.AddInternalEvents Then
			
			Continue;
		EndIf;
		
		Module = CommonUse.CommonModule(
			Details.MainServerModule);
		
		If Details.Name = "StandardSubsystems" Then
			Module = StandardSubsystemsServer;
		EndIf;
		
		If Details.AddEvents Then
			Module.EventOnAnn(ClientEvents, ServerEvents);
		EndIf;
		
		If Details.AddInternalEvents Then
			Module.OnAddInternalEvent(ClientServiceEvents, ServerInternalEvents);
		EndIf;
	EndDo;
	
	CheckEventNameForUniqueness(ClientEvents);
	CheckEventNameForUniqueness(ServerEvents);
	CheckEventNameForUniqueness(ClientServiceEvents);
	CheckEventNameForUniqueness(ServerInternalEvents);
	
	// Preparing new arrays for adding handlers.
	ClientEventHandlersBySubsystems = New Map;
	ServerEventHandlersBySubsystems  = New Map;
	ClientInternalEventHandlersBySubsystems = New Map;
	ServerInternalEventHandlersBySubsystems  = New Map;
	
	MandatoryClientEvents = New Map;
	MandatoryServerEvents  = New Map;
	MandatoryClientInternalEvents = New Map;
	MandatoryServerInternalEvents  = New Map;
	
	For Each Subsystem In SubsystemDescriptions.order Do
		
		ClientEventHandlersBySubsystems.Insert(Subsystem,
			EventHandlerTemplate(ClientEvents, MandatoryClientEvents));
		
		ServerEventHandlersBySubsystems.Insert(Subsystem,
			EventHandlerTemplate(ServerEvents, MandatoryServerEvents));
		
		ClientInternalEventHandlersBySubsystems.Insert(Subsystem,
			EventHandlerTemplate(ClientServiceEvents, MandatoryClientInternalEvents));
		
		ServerInternalEventHandlersBySubsystems.Insert(Subsystem,
			EventHandlerTemplate(ServerInternalEvents, MandatoryServerInternalEvents));
		
	EndDo;
	
	// Adding all handlers for the required application events.
	For Each Subsystem In SubsystemDescriptions.order Do
		Details = SubsystemDescriptions.ByNames[Subsystem];
		
		If Not Details.AddEventHandlers
		   And Not Details.AddInternalEventHandlers Then
			
			Continue;
		EndIf;
		
		Module = CommonUse.CommonModule(
			Details.MainServerModule);
		
		If Details.Name = "StandardSubsystems" Then
			Module = StandardSubsystemsServer;
		EndIf;
		
		If Details.AddEventHandlers Then
			Module.EventHandlersOnAdd(
				ClientEventHandlersBySubsystems[Subsystem],
				ServerEventHandlersBySubsystems[Subsystem]);
		EndIf;
		
		If Details.AddInternalEventHandlers Then
			Module.InternalEventHandlersOnAdd(
				ClientInternalEventHandlersBySubsystems[Subsystem],
				ServerInternalEventHandlersBySubsystems[Subsystem]);
		EndIf;
	EndDo;
	
	// Verifying mandatory events.
	MandatoryEventsWithoutHandlers = New Array;
	
	AddMandatoryEventsWithoutHandlers(MandatoryEventsWithoutHandlers,
		MandatoryClientEvents, ClientEventHandlersBySubsystems);
	
	AddMandatoryEventsWithoutHandlers(MandatoryEventsWithoutHandlers,
		MandatoryServerEvents, ServerEventHandlersBySubsystems);
	
	AddMandatoryEventsWithoutHandlers(MandatoryEventsWithoutHandlers,
		MandatoryClientInternalEvents, ClientInternalEventHandlersBySubsystems);
	
	AddMandatoryEventsWithoutHandlers(MandatoryEventsWithoutHandlers,
		MandatoryServerInternalEvents, ServerInternalEventHandlersBySubsystems);
	
	If MandatoryEventsWithoutHandlers.Count() > 0 Then
		EventName  = NStr("en = 'Events handlers'", CommonUseClientServer.DefaultLanguageCode());
		
		Comment = NStr("en = 'Handlers for the following mandatory events are not defined:'")
			+ Chars.LF + StringFunctionsClientServer.StringFromSubstringArray(MandatoryEventsWithoutHandlers, Chars.LF);
		
		WriteLogEvent(EventName, EventLogLevel.Error,,, Comment);
		Raise NStr("en = 'Handlers for mandatory events are not defined.
		                             |See details in the event log.'");
	EndIf;
	
	// Formatting application event handler descriptions.
	AllEventHandlers = New Structure;
	AllEventHandlers.Insert("AtClient", New Structure);
	AllEventHandlers.Insert("AtServer", New Structure);
	
	AllEventHandlers.AtClient.Insert("EventHandlers", StandardEventHandlerDescription(
		SubsystemDescriptions, ClientEventHandlersBySubsystems));
	
	AllEventHandlers.AtServer.Insert("EventHandlers", StandardEventHandlerDescription(
		SubsystemDescriptions, ServerEventHandlersBySubsystems));
	
	AllEventHandlers.AtClient.Insert("InternalEventHandlers", StandardEventHandlerDescription(
		SubsystemDescriptions, ClientInternalEventHandlersBySubsystems));
	
	AllEventHandlers.AtServer.Insert("InternalEventHandlers", StandardEventHandlerDescription(
		SubsystemDescriptions, ServerInternalEventHandlersBySubsystems));
	
	Return New FixedStructure(AllEventHandlers);
	
EndFunction

// For internal use only.
Function ApplicationParametersUpdateRequired(ExecuteImport = True) Export
	
	If CommonUseCached.DataSeparationEnabled() Then
		// Updating in SaaS.
		If Not CommonUseCached.CanUseSeparatedData()
			And InfobaseUpdateInternal.SharedInfobaseDataUpdateRequired() Then
			
			Return True;
		EndIf;
	Else
		// Updating in the local mode.
		If InfobaseUpdate.InfobaseUpdateRequired() Then
			Return True;
		EndIf;
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.DataExchange") Then
		DataExchangeServerModule = CommonUse.CommonModule("DataExchangeServer");
		
		// When starting the created initial image of a subordinate DIB node, no import is required
		// but the update must be executed.
		If DataExchangeServerModule.SubordinateDIBNodeSetup() Then
			ExecuteImport = False;
			Return True;
		EndIf;
	EndIf;
	
	// When updating from any previous version without embedded SL or with SL 2.1.1 (and
	// earlier), which does not have application parameters.
	Try
		UsersInternalCached.Parameters();
	Except
		ExecuteImport = False;
		Return True;
	EndTry;
	
	Return False;
	
EndFunction

// For internal use only.
Procedure ImportUpdateApplicationParameters(ExclusiveModeSettingError = Undefined, InBackground = False) Export
	
	ExecuteImport = True;
	
	If Not ApplicationParametersUpdateRequired(ExecuteImport) Then
		Return;
	EndIf;
	
	If CommonUseCached.DataSeparationEnabled()
	   And CommonUseCached.CanUseSeparatedData() Then
		Raise
			NStr("en = 'Application parameters cannot be updated in the separated SaaS mode.'");
	EndIf;
	
	If StandardSubsystemsCached.DisableMetadataObjectIDsCatalog() Then
		ExecuteImport = False;
	EndIf;
	
	SetPrivilegedMode(True);
	DisableExclusiveMode = False;
	Try
		If ExecuteImport
		   And CommonUse.IsSubordinateDIBNode() Then
			// There are a DIB data exchange and an update in the subordinate node.
			
			// Preupdating a cache of internal events.
			Constants.InternalEventParameters.CreateValueManager().Update();
			
			StandardProcessing = True;
			CommonUseOverridable.MetadataObjectIDsInSubordinateDIBNodeBeforeImport(
				StandardProcessing);
			
			If StandardProcessing = True
			   And CommonUse.SubsystemExists("StandardSubsystems.DataExchange") Then
				
				If Not ExclusiveMode() Then
					Try
						SetExclusiveMode(True);
						DisableExclusiveMode = True;
					Except
						If ExclusiveModeSettingError <> Undefined Then
							ExclusiveModeSettingError =
								NStr("en = 'The infobase cannot be updated:
								           |- The exclusive mode cannot be set.
								           |- The configuration version does not support update without exclusive mode set.'");
						EndIf;
						Raise ExclusiveModeSettingError;
					EndTry;
				EndIf;
				
				// Importing metadata object IDs from the master node.
				DataExchangeServerModule = CommonUse.CommonModule("DataExchangeServer");
				DataExchangeServerModule.MetadataObjectIDsInSubordinateDIBNodeBeforeCheck();
			EndIf;
			
			If InBackground Then
				CommonUseClientServer.MessageToUser("ProgressStepIncrement=5");
			EndIf;
			
			// Checking metadata object ID import from the master node.
			ListOfCriticalChanges = "";
			Try
				Catalogs.MetadataObjectIDs.UpdateData(, , True, , ListOfCriticalChanges);
			Except
				If CommonUse.SubsystemExists("StandardSubsystems.DataExchange") Then
					// Clearing the exchange messages cache.
					DataExchangeServerModule.MetadataObjectIDsInSubordinateDIBNodeOnCheckError();
				EndIf;
				
				Raise;
			EndTry;
			
			If ValueIsFilled(ListOfCriticalChanges) Then
				
				WriteLogEvent(
					NStr("en = 'Metadata object IDs.Critical changes must be imported'",
						CommonUseClientServer.DefaultLanguageCode()),
					EventLogLevel.Error,
					,
					,
					ListOfCriticalChanges);
				
				If CommonUse.SubsystemExists("StandardSubsystems.DataExchange") Then
					// Clearing the exchange message cache, raising an exceptions with recommending actions.
					DataExchangeServerModule.MetadataObjectIDsInSubordinateDIBNodeOnCheckError(True);
				EndIf;
				
				ErrorText =
					NStr("en = 'The Metadata object IDs catalog changes are not imported from the master node:
					           |It is found out that critical changes must be imported (see details in the event log, in the ""Metadata object IDs.Critical changes must be imported""event).'");
				
				Raise ErrorText;
			EndIf;
			If InBackground Then
				CommonUseClientServer.MessageToUser("ProgressStepIncrement=10");
			EndIf;
		EndIf;
		
		// No DIB data exchange
		// or master infobase node update
		// or initial subordinate node update
		// or update after importing the Metadata object IDs catalog from the master node.
		UpdateAllApplicationParameters( , , ExclusiveModeSettingError, InBackground);
	Except
		If DisableExclusiveMode Then
			SetExclusiveMode(False);
		EndIf;
		Raise;
	EndTry;
	
EndProcedure

// For internal use only.
Procedure ImportUpdateApplicationParametersInBackground(ExecutionParameters, StorageAddress, InBackground = True) Export
	
	If ExecutionParameters.Property("ClientParametersOnServer") Then
		SessionParameters.ClientParametersOnServer = ExecutionParameters.ClientParametersOnServer;
	EndIf;
	
	ExecutionResult = New Structure;
	ExecutionResult.Insert("BriefErrorMessage",    Undefined);
	ExecutionResult.Insert("DetailedErrorMessage", Undefined);
	
	ExclusiveModeSettingError = "";
	Try
		ImportUpdateApplicationParameters(ExclusiveModeSettingError, InBackground);
	Except
		ErrorInfo = ErrorInfo();
		ExecutionResult.BriefErrorMessage    = BriefErrorDescription(ErrorInfo);
		ExecutionResult.DetailedErrorMessage = DetailErrorDescription(ErrorInfo);
	EndTry;
	
	If ErrorInfo = Undefined
	   And ValueIsFilled(ExclusiveModeSettingError)
	   And CommonUse.FileInfobase() Then
		
		ClientLaunchParameter = SessionParameters.ClientParametersOnServer.Get("LaunchParameter");
		If Find(ClientLaunchParameter, "ScheduledJobsDisabled") = 0 Then
			ExclusiveModeSettingError = "LockScheduledJobExecution";
		EndIf;
	EndIf;
	
	ExecutionResult.Insert("ExclusiveModeSettingError", ExclusiveModeSettingError);
	
	If Not ValueIsFilled(ExecutionResult.BriefErrorMessage)
	   And ValueIsFilled(ExclusiveModeSettingError)
	   And ExclusiveModeSettingError <> "LockScheduledJobExecution" Then
		
		ExecutionResult.BriefErrorMessage    = ExclusiveModeSettingError;
		ExecutionResult.DetailedErrorMessage = ExclusiveModeSettingError;
	EndIf;
	
	If ExecutionParameters.Property("ClientParametersOnServer") Then
		ExecutionResult.Insert("ClientParametersOnServer", SessionParameters.ClientParametersOnServer);
	EndIf;
	
	PutToTempStorage(ExecutionResult, StorageAddress);
	
EndProcedure

// Returns a map of names and server modules.
Function ServerModuleNames() Export
	
	ServerModules = New Map;
	FileInfobase = CommonUse.FileInfobase();
	
	For Each CommonModule In Metadata.CommonModules Do
		If CommonModule.Global Then
			Continue;
		EndIf;
		
		If CommonModule.Server
	#If ThickClientManagedApplication Or ThickClientOrdinaryApplication Or ExternalConnection Then
		 Or FileInfobase
	#EndIf
		Then
			ServerModules.Insert(Eval(CommonModule.Name), CommonModule.Name);
		EndIf;
	EndDo;
	
	Return New FixedMap(ServerModules);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Updating the MetadataObjectIDs catalog

// For internal use only.
Function ExchangePlansManager() Export
	
	Return ExchangePlans;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Infobase update

// Adds the update handlers required by the subsystem.
//
// Parameters:
//  Handlers - ValueTable - see Details on the NewUpdateHandlerTable() function of the
//             InfobaseUpdate common module.
// 
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version = "*";
	Handler.Procedure = "StandardSubsystemsServer.SetConstantDontUseSeparationByDataAreas";
	Handler.Priority = 99;
	Handler.SharedData = True;
	Handler.ExclusiveMode = True;
	
	Handler = Handlers.Add();
	Handler.Version = "*";
	Handler.Procedure = "StandardSubsystemsServer.MarkVersionCacheRecordsObsolete";
	Handler.Priority = 99;
	Handler.SharedData = True;
	Handler.ExclusiveMode = False;
	
	Handler = Handlers.Add();
	Handler.Version = "*";
	Handler.Procedure = "StandardSubsystemsServer.CreateSharedPredefinedItems";
	Handler.Priority = 99;
	Handler.SharedData = True;
	Handler.ExclusiveMode = False; 
		
EndProcedure

// Sets the correct value of the DontUseSeparationByDataAreas constant
//
Procedure SetConstantDontUseSeparationByDataAreas(Parameters) Export
	
	SetPrivilegedMode(True);
	
	NewValues = New Map;
	
	If Constants.UseSeparationByDataAreas.Get() Then
		
		NewValues.Insert("DontUseSeparationByDataAreas", False);
		NewValues.Insert("IsStandaloneWorkstation", False)
		
	ElsIf Constants.IsStandaloneWorkstation.Get() Then
		
		NewValues.Insert("DontUseSeparationByDataAreas", False);
		
	Else
		
		NewValues.Insert("DontUseSeparationByDataAreas", True);
		
	EndIf;
	
	For Each KeyAndValues In NewValues Do
		
		If Constants[KeyAndValues.Key].Get() <> KeyAndValues.Value Then
			
			If Not Parameters.ExclusiveMode Then
				Parameters.ExclusiveMode = True;
				Return; // Must be changed
			EndIf;
			
			Constants[KeyAndValues.Key].Set(KeyAndValues.Value);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Clears update date for each version cache record, so all version cache records become out-of-date.
// 
Procedure MarkVersionCacheRecordsObsolete() Export
	
	BeginTransaction();
	
	RecordSet = InformationRegisters.ProgramInterfaceCache.CreateRecordSet();
	
	DataLock = New DataLock;
	DataLock.Add("InformationRegister.ProgramInterfaceCache");
	DataLock.Lock();
	
	RecordSet.Read();
	For Each Record In RecordSet Do
		Record.UpdateDate = Undefined;
	EndDo;
	
	InfobaseUpdate.WriteData(RecordSet);
	CommitTransaction();
	
EndProcedure


// Shared metadata object predefined item creation/update handler.
// 
Procedure CreateSharedPredefinedItems() Export
	
	SetPrivilegedMode(True);
	
	If Not CommonUseCached.IsSeparatedConfiguration() Then
		// There are no required actions for configurations without data separation.
		Return;
	EndIf;
	
	If CommonUseCached.DataSeparationEnabled() Then
		
		If CommonUseCached.CanUseSeparatedData() Then
			// In the separated session, the actions are not available and does not required.
			Return;
			
		EndIf;
		
	Else
		
		// There are no required actions when the data separation is disabled.
		Return;
		
	EndIf;
	
	If Not CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.BaseFunctionalitySaaS") Then
		// The actions do not support arbitrary separation methods.
		Return;
	EndIf;
	
	MainSeparator      = CommonUseCached.MainDataSeparator();
	AuxiliarySeparator = CommonUseCached.AuxiliaryDataSeparator();
	
	MetadataCollection = New Array;
	MetadataCollection.Add(Metadata.Catalogs);
	MetadataCollection.Add(Metadata.ChartsOfCharacteristicTypes);
	MetadataCollection.Add(Metadata.ChartsOfAccounts);
	MetadataCollection.Add(Metadata.ChartsOfCalculationTypes);
	
	For Each Collection In MetadataCollection Do
		For Each MetadataObject In Collection Do
			FullName = MetadataObject.FullName();
			If Not CommonUseCached.IsSeparatedMetadataObject(FullName, MainSeparator)
			   And Not CommonUseCached.IsSeparatedMetadataObject(FullName, AuxiliarySeparator) Then
				
				ObjectManager = CommonUse.ObjectManagerByFullName(FullName);
				ObjectManager.Select().Next();
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Exit confirmation

// Reads exit confirmation settings item for the current user.
// 
// Returns:
//   Boolean - value of the settings item.
// 
Function AskConfirmationOnExit() Export
	Result = CommonUse.CommonSettingsStorageLoad("UserCommonSettings", "AskConfirmationOnExit");
	
	If Result = Undefined Then
		
		Result = CommonUse.CommonBaseFunctionalityParameters(
			).AskConfirmationOnExit;
		
		StandardSubsystemsServerCall.SaveExitConfirmationSettings(Result);
	EndIf;
	
	Return Result;
EndFunction


////////////////////////////////////////////////////////////////////////////////
// Event subscription handlers

// Predefined item BeforeWrite event handler
Procedure DenySelectingPredefinedItemDeletionMarkBeforeWrite(Source, Cancel) Export
	
	If Source.DataExchange.Load
	 Or Source.PredefinedDataName = ""
	 Or Source.DeletionMark <> True Then
		Return;
	EndIf;
	
	If Source.IsNew() Then
		Raise
			NStr("en = 'A predefined item marked for deletion cannot be created.'");
	Else
		OldProperties = CommonUse.ObjectAttributeValues(
			Source.Ref, "DeletionMark, PredefinedDataName");
		
		If OldProperties.PredefinedDataName <> ""
		   And OldProperties.DeletionMark <> True Then
			
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'A predefined item cannot be marked for deletion:
				           |""%1"".'"),
				String(Source.Ref));
			
		ElsIf OldProperties.PredefinedDataName = ""
		        And OldProperties.DeletionMark = True Then
			
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'A predefined item marked for deletion cannot be linked to a name:
				           |""%1"".'"),
				String(Source.Ref));
		EndIf;
	EndIf;
	
EndProcedure

// Predefined item BeforeDelete event handler
Procedure DenyPredefinedItemDeletionBeforeDelete(Source, Cancel) Export
	
	If Source.DataExchange.Load
	 Or Source.PredefinedDataName = "" Then
		Return;
	EndIf;
	
	Raise StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en = 'A predefined item cannot be deleted
		           |""%1"".'"),
		String(Source.Ref));
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// DIB exchange plan event subscription processing

// Handler of the same name event, which occurs when exchanging data in a distributed infobase.
//
// Parameters:
// see the OnSendDataToSlave() event handler description in the syntax assistant.
// 
Procedure OnSendDataToSlaveEvent(Source, DataItem, ItemSend, InitialImageCreating) Export
	
	OnSendDataToSlave(DataItem, ItemSend, InitialImageCreating, Source);
	
EndProcedure

// Handler of the same name event, which occurs when exchanging data in a distributed infobase.
//
// Parameters:
// see the OnSendDataToMaster() event handler description in the syntax assistant.
// 
Procedure OnSendDataToMasterEvent(Source, DataItem, ItemSend) Export
	
	OnSendDataToMaster(DataItem, ItemSend, Source);
	
EndProcedure

// Handler of the same name event, which occurs when exchanging data in a distributed infobase.
//
// Parameters:
// see the OnReceiveDataFromSlave() event handler description in the syntax assistant.
// 
Procedure OnReceiveDataFromSubordinateEvent(Source, DataItem, ItemReceive, SendBack) Export
	
	OnReceiveDataFromSlave(DataItem, ItemReceive, SendBack, Source);
	
EndProcedure

// Handler of the same name event, which occurs when exchanging data in a distributed infobase.
//
// Parameters:
// see the OnReceiveDataFromMaster() event handler description in the syntax assistant.
// 
Procedure OnReceiveDataFromMasterEvent(Source, DataItem, ItemReceive, SendBack) Export
	
	OnReceiveDataFromMaster(DataItem, ItemReceive, SendBack, Source);
	
EndProcedure

// WriteBefore event subscription handler for ExchangePlanObject.
// Is used for calling the DataAfterReceive event handler when exchanging in DIB.
//
Procedure DataAfterReceive(Source, Cancel) Export
	
	If Source.AdditionalProperties.Property("Load") Then
		Return;
	EndIf;
	
	If Source.Metadata().DistributedInfobase Then
		
		If Source.ReceivedNo <> CommonUse.ObjectAttributeValue(Source.Ref, "ReceivedNo") Then
			
			If ExchangePlans.MasterNode() = Source.Ref Then
				
				EventHandlers = CommonUse.InternalEventHandlers(
					"StandardSubsystems.BaseFunctionality\DataFromMasterAfterReceive");
				
				For Each Handler In EventHandlers Do
					Handler.Module.DataFromMasterAfterReceive(Source, Cancel);
				EndDo;
				
			Else
				EventHandlers = CommonUse.InternalEventHandlers(
					"StandardSubsystems.BaseFunctionality\DataFromSubordinateAfterReceive");
				
				For Each Handler In EventHandlers Do
					Handler.Module.DataFromSubordinateAfterReceive(Source, Cancel);
				EndDo;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// WriteBefore event subscription handler for ExchangePlanObject.
// Is used for calling the DataAfterSend event handler when exchanging in DIB.
//
Procedure DataAfterSend(Source, Cancel) Export
	
	If Source.AdditionalProperties.Property("Load") Then
		Return;
	EndIf;
	
	If Source.Metadata().DistributedInfobase Then
		
		If Source.SentNo <> CommonUse.ObjectAttributeValue(Source.Ref, "SentNo") Then
			
			If ExchangePlans.MasterNode() = Source.Ref Then
				
				EventHandlers = CommonUse.InternalEventHandlers(
					"StandardSubsystems.BaseFunctionality\DataToMasterAfterSend");
				
				For Each Handler In EventHandlers Do
					Handler.Module.DataToMasterAfterSend(Source, Cancel);
				EndDo;
				
			Else
				
				EventHandlers = CommonUse.InternalEventHandlers(
					"StandardSubsystems.BaseFunctionality\DataToSubordinateAfterSend");
				
				For Each Handler In EventHandlers Do
					Handler.Module.DataToSubordinateAfterSend(Source, Cancel);
				EndDo;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Scheduled job for deleting marked objects

// Scheduled job entry point.
//
Procedure MarkedObjectDeletionOnSchedule() Export
	
	CommonUse.ScheduledJobOnStart();
	
	DataProcessors.MarkedObjectDeletion.DeleteMarkedObjectsUsingScheduledJob();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// AUXILIARY PROCEDURES AND FUNCTIONS

Procedure BeforeApplicationStart()
	
	// Privileged mode (set by the platform).
	
	// Checking the default programming language set in the configuration.
	If Metadata.ScriptVariant <> Metadata.ObjectProperties.ScriptVariant.English Then
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'The %1 script language is not supported.
			           |Use the %2 language.'"),
			Metadata.ScriptVariant,
			Metadata.ObjectProperties.ScriptVariant.English);
	EndIf;
		
	// Checking settings of compatibility between the configuration and the platform version.
	SystemInfo = New SystemInfo;
	If CommonUseClientServer.CompareVersions(SystemInfo.AppVersion, "8.3.4.365") < 0 Then
		Raise NStr("en = 'Use the 1C:Enterprise 8.3.4.365 or later platform to start the application.'");
	EndIf;
	
	Modes = Metadata.ObjectProperties.CompatibilityMode;
	CurrentMode = Metadata.CompatibilityMode;
	
	If CurrentMode = Modes.DontUse Then
		IllegalMode = "";
	ElsIf CurrentMode = Modes.Version8_1 Then
		IllegalMode = "8.1"
	ElsIf CurrentMode = Modes.Version8_2_13 Then
		IllegalMode = "8.2.13"
	ElsIf CurrentMode = Modes.Version8_2_16 Then
		IllegalMode = "8.2.16";
	ElsIf CurrentMode = Modes.Version8_3_1 Then
		IllegalMode = "8.3.1";
	ElsIf CurrentMode = Modes.Version8_3_2 Then
		IllegalMode = "8.3.2";
	ElsIf CurrentMode = Modes.Version8_3_3 Then
		IllegalMode = "8.3.3";
	Else
		IllegalMode = "";
	EndIf;
	
	If ValueIsFilled(IllegalMode) Then
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'The configuration compatibility mode (with 1C:Enterprise %1) is not supported.
			           |To start, set the compatibility with 1C:Enterprise 8.3.4 or ""None"".'"),
			IllegalMode);
	EndIf;
	
	// Checking whether the configuration version is filled.
	If IsBlankString(Metadata.Version) Then
		Raise NStr("en = 'The Version configuration property is not filled.'");
	Else
		Try
			ZeroVersion = CommonUseClientServer.CompareVersions(Metadata.Version, "0.0.0.0") = 0;
		Except
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'The Version configuration property is filled incorrectly: ""%1"".
				           |The correct format example: ""2.1.3.70"".'"),
				Metadata.Version);
		EndTry;
		If ZeroVersion Then
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'The Version configuration property is filled incorrectly: ""%1"".
				           |Version cannot equal zero.'"),
				Metadata.Version);
		EndIf;
	EndIf;
	
	If Metadata.DefaultRoles.Count() <> 2
	 Or Not Metadata.DefaultRoles.Contains(Metadata.Roles.FullAdministrator)
	 Or Not Metadata.DefaultRoles.Contains(Metadata.Roles.FullAccess) Then
		Raise
			NStr("en = 'The DefaultRoles configuration property does not include the specified FullAdministrator and FullAccess standard roles or includes excess roles.'");
	EndIf;
	
	If Not ValueIsFilled(InfobaseUsers.CurrentUser().Name)
	   And (Not CommonUseCached.DataSeparationEnabled()
	      Or Not CommonUseCached.CanUseSeparatedData())
		  // CI >
	   //And InfobaseUpdateInternal.InfobaseVersion("StandardSubsystems",
	   //    CommonUseCached.DataSeparationEnabled()) = "0.0.0.0" 
		   // CI <
		   Then
		
		UsersInternal.SetInitialSettings("");
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations") Then
		SaasOperationsModule = CommonUse.CommonModule("SaaSOperations");
		SaasOperationsModule.EnablingDataSeparationSafeModeOnCheck();
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.DataAreaBackup") Then
		// Setting flag that shows whether users are active in the area
		DataAreaBackupModule = CommonUse.CommonModule("DataAreaBackup");
		DataAreaBackupModule.SetUserActivityInAreaFlag();
	EndIf;
	
EndProcedure

Procedure ExecuteSessionParameterSettingHandlers(SessionParameterNames, Handlers, SpecifiedParameters)
	
	Var MessageText;
	
	SafeMode.CanExecuteSessionParameterSettingHandlers();
	
	// An array of session parameters keys set with an initial word in the session parameter name
	// and asterisk sing (*).
	SessionParameterKeys = New Array;
	
	For Each Record In Handlers Do
		If Find(Record.Key, "*") > 0 Then
			ParameterKey = TrimAll(Record.Key);
			SessionParameterKeys.Add(Left(ParameterKey, StrLen(ParameterKey)-1));
		EndIf;
	EndDo;
	
	For Each ParameterName In SessionParameterNames Do
		If SpecifiedParameters.Find(ParameterName) <> Undefined Then
			Continue;
		EndIf;
		Handler = Handlers.Get(ParameterName);
		If Handler <> Undefined Then
			
			HandlerParameters = New Array();
			HandlerParameters.Add(ParameterName);
			HandlerParameters.Add(SpecifiedParameters);
			SafeMode.ExecuteConfigurationMethod(Handler, HandlerParameters);
			Continue;
			
		EndIf;
		For Each ParameterKeyName In SessionParameterKeys Do
			If Left(ParameterName, StrLen(ParameterKeyName)) = ParameterKeyName Then
				
				Handler = Handlers.Get(ParameterKeyName+"*");
				HandlerParameters = New Array();
				HandlerParameters.Add(ParameterName);
				HandlerParameters.Add(SpecifiedParameters);
				SafeMode.ExecuteConfigurationMethod(Handler, HandlerParameters);
				
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

Function GetUserInfo()
	
	// Determining the actual user name even if it has been changed in the current session;
	// For example, to connect to the current infobase through an external connection from this session;
	// In all other cases, it is enough to get InfobaseUsers.CurrentUser()
	CurrentUser = InfobaseUsers.FindByUUID(
		InfobaseUsers.CurrentUser().UUID);
	
	If CurrentUser = Undefined Then
		CurrentUser = InfobaseUsers.CurrentUser();
	EndIf;
	
	Information = New Structure;
	Information.Insert("Name",                   CurrentUser.Name);
	Information.Insert("FullName",               CurrentUser.FullName);
	Information.Insert("PasswordIsSet",          CurrentUser.PasswordIsSet);
	Information.Insert("OpenIDAuthentication",   CurrentUser.OpenIDAuthentication);
	Information.Insert("StandardAuthentication", CurrentUser.StandardAuthentication);
	Information.Insert("OSAuthentication",       CurrentUser.OSAuthentication);
	
	Return Information;
	
EndFunction

Function MetadataObjectPresentation(Objects)
	
	Result = New Array;
	
	For Each Object In Objects Do
		
		Result.Add(Object.FullName());
		
	EndDo;
	
	Return Result;
EndFunction

Procedure IgnoreMetadataObjectIDSending(DataItem, ItemSend, Val InitialImageCreating = False)
	
	If Not InitialImageCreating
		And MetadataObject(DataItem) = Metadata.Catalogs.MetadataObjectIDs Then
		
		ItemSend = DataItemSend.Ignore;
		
	EndIf;
	
EndProcedure

Procedure IgnoreInitialImageObjectSending(DataItem, ItemSend, Val InitialImageCreating = False)
	
	If Not InitialImageCreating
		And IsDIBModeInitialImageObject(MetadataObject(DataItem))
		And Not IsPredefinedItem(DataItem) Then
		
		ItemSend = DataItemSend.Ignore;
		
	EndIf;
	
EndProcedure

Function IgnoreInitialImageObjectGetting(DataItem, ItemReceive)
	
	If Not InitialImageCreating(DataItem)
		And IsDIBModeInitialImageObject(MetadataObject(DataItem)) Then
		
		ItemReceive = DataItemReceive.Ignore;
		
	EndIf;
	
EndFunction

Function MetadataObject(Val DataItem)
	
	Return ?(TypeOf(DataItem) = Type("ObjectDeletion"), DataItem.Ref.Metadata(), DataItem.Metadata());
	
EndFunction

Function InitialImageCreating(Val DataItem)
	
	Return ?(TypeOf(DataItem) = Type("ObjectDeletion"), False, DataItem.AdditionalProperties.Property("InitialImageCreating"));
	
EndFunction


Function ShowDeprecatedPlatformVersion(Parameters)
	
	If Parameters.DataSeparationEnabled Then
		Return False;
	EndIf;
	
	// Checking whether the user is not an external one.
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("InfobaseUserID",
		InfobaseUsers.CurrentUser().UUID);
	
	Query.Text = 
	"SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	Catalog.ExternalUsers AS ExternalUsers
	|Where
	|	ExternalUsers.InfobaseUserID = &InfobaseUserID";
	
	If Not Query.Execute().IsEmpty() Then
		Return False;
	EndIf;
	
	SystemInfo = New SystemInfo;
	Return CommonUseClientServer.CompareVersions(SystemInfo.AppVersion,
		Parameters.LowestPlatformVersion) < 0;
	
EndFunction

Function IsPredefinedItem(DataItem)
	
	IsPredefined = False;
	BaseTypeName = CommonUse.BaseTypeNameByMetadataObject(DataItem.Metadata());
	
	If BaseTypeName = CommonUse.TypeNameCatalogs()
		Or BaseTypeName = CommonUse.TypeNameChartsOfCharacteristicTypes()
		Or BaseTypeName = CommonUse.TypeNameChartsOfAccounts()
		Or BaseTypeName = CommonUse.TypeNameChartsOfCalculationTypes() Then
		
		If DataItem.Predefined Then
			
			IsPredefined = True;
			
		EndIf;
		
	EndIf;
	
	Return IsPredefined;
	
EndFunction

Function DefaultAdministrationParameters()
	
	ClusterAdministrationParameters = ClusterAdministrationClientServer.ClusterAdministrationParameters();
	InfobaseAdministrationParameters = ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters();
	
	// Combining parameter structures
	AdministrationParameterStructure = ClusterAdministrationParameters;
	For Each Item In InfobaseAdministrationParameters Do
		AdministrationParameterStructure.Insert(Item.Key, Item.Value);
	EndDo;
	
	Return AdministrationParameterStructure;
	
EndFunction

Procedure ReadParametersFromConnectionString(AdministrationParameterStructure)
	
	ConnectionStringSubstrings = StringFunctionsClientServer.SplitStringIntoSubstringArray(
		InfobaseConnectionString(), ";");
	
	ServerNameString = StringFunctionsClientServer.RemoveDoubleQuotationMarks(Mid(ConnectionStringSubstrings[0], 7));
	AdministrationParameterStructure.NameInCluster = StringFunctionsClientServer.RemoveDoubleQuotationMarks(Mid(ConnectionStringSubstrings[1], 6));
	
	ClusterServerList = StringFunctionsClientServer.SplitStringIntoSubstringArray(ServerNameString, ",");
	
	ServerName = ClusterServerList[0];
	PortSeparator = Find(ServerName, ":");
	If PortSeparator > 0 Then
		ServerAgentAddress = Mid(ServerName, 1, PortSeparator - 1);
		ClusterPort = Number(Mid(ServerName, PortSeparator + 1));
		If AdministrationParameterStructure.ClusterPort = 1541 Then
			AdministrationParameterStructure.ClusterPort = ClusterPort;
		EndIf;
	Else
		ServerAgentAddress = ServerName;
	EndIf;
	
	AdministrationParameterStructure.ServerAgentAddress = ServerAgentAddress;
	
EndProcedure

// A temporary analog of SaaSOperations.SetSessionSeparation.
// For internal use.
//
Procedure LogOnToZeroArea(Val Use = Undefined) 
	
	If Not CommonUseCached.SessionWithoutSeparators() Then
		Raise(NStr("en = 'Changing separation settings is only allowed from sessions started without separation'"));
	EndIf;
	
	SetPrivilegedMode(True);
	
	If Use <> Undefined Then
		SessionParameters.UseDataArea = Use;
	EndIf;
	
	SessionParameters.DataAreaValue = 0;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Declaring events, for which handlers can be added.

// Declares BaseFunctionality subsystem internal events:
//
// Client events:
//   BeforeStart,
//   OnStart,
//   LaunchParametersOnProcess,
//   BeforeExit,
//   OnGetExitWarningList.
//
// Server events:
//   SessionParameterSettingHandlersOnAdd,
//   OnAddReferenceSearchException,
//   SubjectPresentationOnDefine,
//   RenamedMetadataObjectsOnAdd,
//   OnAddClientParametersOnStart,
//   ClientParametersOnAdd,
//   ClientParametersOnAddOnExit,
//   OnEnableSeparationByDataAreas,
//   OnSendDataToSlave,
//   OnSendDataToMaster,
//   OnReceiveDataFromSlave,
//   OnReceiveDataFromMaster,
//   DataFromSubordinateAfterReceive,
//   DataFromMasterAfterReceive,
//   DataToMasterAfterSend,
//   DataToSubordinateAfterSend,
//   SupportedInterfaceVersionsOnDefine.
//
Procedure BaseFunctionalityInternalEventsOnAdd(ClientEvents, ServerEvents) Export
	
	// CLIENT EVENTS.
	
	// Is executed before a user starts interactive work with a data area or in the local mode.
	// Corresponds with the BeforeStart application module events.
	//
	// See parameter details in the CommonUseClientOverridable module.
	//
	// Syntax:
	// Procedure BeforeStart(Parameters) Export
	//
	// (Same as CommonUseClientOverridable.BeforeStart).
	ClientEvents.Add(
		"StandardSubsystems.BaseFunctionality\BeforeStart");
	
	// Is executed when a user starts interactive work with a data area or in the local mode.
	// Corresponds to OnStart events described in the application modules.
	//
	// See parameter details in the CommonUseClientOverridable module.
	//
	// Syntax:
	// Procedure OnStart(Parameters) Export
	//
	// (Same as CommonUseClientOverridable.OnStart).
	ClientEvents.Add(
		"StandardSubsystems.BaseFunctionality\OnStart");
	
	// Is executed when a user starts interactive work with a data area or in the local mode.
	// Is called when OnStart actions have been completed.
	// Is used for attaching idle handlers that should not be called in case of interactive
	// actions before or when the system starts.
	//
	// See parameter details in the CommonUseClientOverridable module.
	//
	// Syntax:
	// Procedure AfterStart() Export
	//
	// (Same as CommonUseClientOverridable.OnStart).
	ClientEvents.Add(
		"StandardSubsystems.BaseFunctionality\AfterStart");
	
	// Is called when a user works interactively with a data area or in the local mode.
	//
	// Parameters:
	//  FirstParameter   - String - first value of the start parameter, before the first semicolon
	//                     (;), in the upper case.
	//  LaunchParameters - Array - array of strings separated with semicolons (;) in the start
	//                     parameter, passed to the configuration using the /C command line key.
	//  Cancel           - Boolean (return value) - True means the OnStart event handler will be aborted.
	//
	// Syntax:
	// Procedure LaunchParametersOnProcess(FirstParameter, LaunchParameters, Cancel) Export
	//
	// (Same as CommonUseClientOverridable.LaunchParametersOnProcess).
	ClientEvents.Add(
		"StandardSubsystems.BaseFunctionality\LaunchParametersOnProcess");
	
	// Is called before a user interactively logs off from a data area or exits the application in
	// the local mode.
	// Corresponds with the BeforeExit application module events.
	//
	// See parameter details in the CommonUseClientOverridable module.
	//
	// Syntax:
	// Procedure BeforeExit(Parameters) Export
	//
	// (Same as CommonUseClientOverridable.BeforeExit).
	ClientEvents.Add(
		"StandardSubsystems.BaseFunctionality\BeforeExit");
	
	// Redefines a list of warnings to user before exiting the application.
	//
	// Parameters:
	//  Warnings - Array - you can add items of the Structure type to the array. See the structure
	// properties in StandardSubsystemsClient.ExitWarning.
	//
	// Syntax:
	// Procedure OnGetExitWarningList(Warnings) Export
	//
	ClientEvents.Add(
		"StandardSubsystems.BaseFunctionality\OnGetExitWarningList");
	

	// SERVER EVENTS.
	
	// Redefines session parameter setting handlers.
	//
	// Parameters:
	//  Handlers - Map, where
	//              Key   - String - <SessionParameterName> Or <SessionParameterNamePrefix*>.
	//              Value - String - full handler name.
	//
	//  Comment. The asterisk sing (*) is used at the end of the session parameters name and means
	// that one handler is called to initialize all session parameters whose name starts with the
	// word SessionParameterNamePrefix
	//
	// Use the following pattern to set session parameter handlers:
	// Handlers.Insert("<SessionParameterName>|<SessionParameterNamePrefix*>", "Handler");
	//
	// Syntax:
	// Procedure SessionParameterSettingHandlersOnAdd(Handlers) Export
	//
	// (Same as CommonUseOverridable.SessionParameterSettingHandlersOnAdd).
	ServerEvents.Add(
		"StandardSubsystems.BaseFunctionality\SessionParameterSettingHandlersOnAdd");
	
	// Redefines a list of metadata objects whose content should not be takes into account in the
	// application business logic.
	//
	// Example:
	//  The Object versioning subsystem and the Properties subsystem are configured for
	//  Invoice documents. There can be references to this document in the infobase (in 
	//  other documents, registers, and other objects). 
	//  Some of them are important for business logic (like register records) and must be
	//  shown to user. Other part is "technical" references, referred to the Object
	//  versioning subsystem and the Properties subsystem. Such technical references must
	//  be filtered. For example, such case occurs when references to objects are being 
	//  searched or in the Object attribute edit prohibition subsystem.
	//  The list of technical objects must be specified in this procedure.
	// 
	// Important:
	//  To prevent the infobase from empty "bad" references, we recommend that you
	//  include a procedure for clearing the specified metadata objects.
	//  For information register dimensions select the Master check box, this deletes the
	//  register record data once the respective reference specified in a dimension is
	//  deleted.
	//  For other attributes of the objects being deleted, use the BeforeDelete
	//  subscription event of all metadata objects types that can be recorded to the
	//  attributes of the specified metadata objects. The handler must find the
	//  "technical" objects that contain the reference in the attributes and select the 
	//  way of reference clearing: clear the attribute value, delete the row, or delete 
	//  the whole object.
	//
	// Parameters:
	//  RefSearchExclusions - Array - metadata objects or their attributes, whose content 
	//                        must be skipped in the application business logic.
	//                        * MetadataObject - metadata object or its attribute.
	//                        * String - full name of the metadata object or its attribute.
	//
	// Examples:
	//  RefSearchExclusions.Add(Metadata.InformationRegisters.ObjectVersions);
	//  RefSearchExclusions.Add(Metadata.InformationRegisters.ObjectVersions.Attributes.VersionAuthor);
	//  RefSearchExclusions.Add("InformationRegister.ObjectVersions");
	//
	//
	// Syntax:
	// Procedure OnAddReferenceSearchException(Exceptions) Export
	//
	// (Same as CommonUseOverridable.OnAddReferenceSearchException).
	ServerEvents.Add(
		"StandardSubsystems.BaseFunctionality\OnAddReferenceSearchException");
	
	// Redefines the subject description text.
	//
	// Parameters:
	//  SubjectRef   - AnyRef - reference type object.
	//  Presentation - String - object text description to be set.
	//
	// Syntax:
	// Procedure SubjectPresentationOnDefine(SubjectRef, Presentation) Export
	//
	// (Same as CommonUseOverridable.SetSubjectPresentation).
	ServerEvents.Add(
		"StandardSubsystems.BaseFunctionality\SubjectPresentationOnDefine");
	
	// Redefines renaming of metadata objects that cannot be automatically found by type but whose
	// references are required to be saved in the database (for example: subsystems, roles).
	//
	// For details, see comments to CommonUse.AddRenaming.
	//
	// Syntax:
	// Procedure RenamedMetadataObjectsOnAdd(Total) Export
	//
	ServerEvents.Add(
		"StandardSubsystems.BaseFunctionality\RenamedMetadataObjectsOnAdd");
	
	// Redefines a structure of parameters required for running the client script during the 
	// application startup, namely in the following event handlers:
	// - BeforeStart,
	// - OnStart.
	//
	// Important: when running the application, do not use cache reset commands of modules 
	// that reuse return values because this can lead to unpredictable errors and unneeded 
	// service calls. 
	//
	// Parameters:
	//  Parameters - Structure - (return value) startup client run parameter structure.
	//                 Key   - Parameter name.
	//                 Value - parameter value.
	//
	// Implementation example:
	//  Parameters.Insert(<ParameterName>, <script that gets parameter values>);
	//
	// Syntax:
	// Procedure OnAddClientParametersOnStart(Parameters) Export
	//
	// (Same as CommonUseOverridable.ClientParametersOnStart).
	ServerEvents.Add(
		"StandardSubsystems.BaseFunctionality\OnAddClientParametersOnStart");
	
	// Returns the structure of parameters required for configuration client script
	// execution. 
	//
	// Parameters:
	//   Parameters - Structure - (return value) client run parameter structure.
	//                 Key   - parameter name.
	//                 Value - parameter value.
	//
	// Implementation example:
	//  Parameters.Insert(<ParameterName>, <script that gets parameter values>);
	//
	// Syntax:
	// Procedure ClientParametersOnAdd(Parameters) Export
	//
	// (Same as CommonUseOverridable.ClientParameters).
	ServerEvents.Add(
		"StandardSubsystems.BaseFunctionality\ClientParametersOnAdd");
	
	// Redefines the structure of parameters required for executing the configuration client
	// script during exiting the application, namely in the following event handlers:
	// - BeforeExit, 
	// - OnExit.
	//
	// Parameters:
	//  Parameters - Structure - (return value) exit client run parameter structure.
	//                 Key   - parameter name.
	//                 Value - parameter value.
	//
	// Implementation example:
	//  Parameters.Insert(<ParameterName>, <script that gets parameter values>);
	//
	// Syntax:
	// Procedure ClientParametersOnAddOnExit(Parameters) Export
	//
	// (Same as CommonUseOverridable.ClientParametersOnExit).
	ServerEvents.Add(
		"StandardSubsystems.BaseFunctionality\ClientParametersOnAddOnExit");
	
	// Is called when enabling separation by data areas.
	//
	ServerEvents.Add(
		"StandardSubsystems.BaseFunctionality\OnEnableSeparationByDataAreas");
	
	// Is called when importing predefined item references while importing important data.
	// Allows executing actions to fix or register details on not unique predefined items.
	// Also allows you to cancel the import if the uniqueness problem cannot be solved.
	//
	// Parameters:
	//   Object              - CatalogObject, ChartOfCharacteristicTypesObject,
	//                         ChartOfAccountsObject, ChartOfCalculationTypesObject -
	//                         written predefined item object that led to a uniqueness problem.
	//   WriteToLog          - Boolean - return value. Set to False to add the uniqueness problem
	//                         details to the event log in a common message. Set it to False if
	//                         the uniqueness problem has been fixed automatically.
	//   Cancel              - Boolean - return value. Set to True to raise an exception with
	//                         cancellation details.
	//   CancellationDetails - String - return value. If Cancel is set in True, the description is
	//                         added to the list of the reasons that block the import
	//                         continuation.
	//
	// Syntax:
	// Procedure NotUniquePredefinedItemFound(Object, WriteToLog, Cancel, CancellationDetails) Export
	//
	ServerEvents.Add("StandardSubsystems.BaseFunctionality\NotUniquePredefinedItemFound");
	
	// Handler of the same name event, which occurs when exchanging data in a distributed infobase.
	//
	// Parameters:
	// Cee the OnSendDataToSlave() event handler description in the syntax assistant.
	//
	// Syntax:
	// Procedure OnSendDataToSlave(DataItem, ItemSend, InitialImageCreating, Recipient) Export
	//
	ServerEvents.Add("StandardSubsystems.BaseFunctionality\OnSendDataToSlave");
	
	// Handler of the same name event, which occurs when exchanging data in a distributed infobase.
	//
	// Parameters:
	// see the OnSendDataToMaster() event handler description in the syntax assistant.
	//
	// Syntax:
	// Procedure OnSendDataToMaster(DataItem, ItemSend, Recipient) Export
	//
	ServerEvents.Add("StandardSubsystems.BaseFunctionality\OnSendDataToMaster");
	
	// Handler of the same name event, which occurs when exchanging data in a distributed infobase.
	//
	// Parameters:
	// see the OnReceiveDataFromSlave() event handler description in the syntax assistant.
	//
	// Syntax:
	// Procedure OnReceiveDataFromSlave(DataItem, ItemReceive, SendBack, From) Export
	//
	ServerEvents.Add("StandardSubsystems.BaseFunctionality\OnReceiveDataFromSlave");
	
	
	// Handler of the same name event, which occurs when exchanging data in a distributed infobase.
	// 
	// Parameters:
	// See the OnReceiveDataFromMaster() event handler description in the syntax assistant.
	// 
	// Syntax:
	// Procedure OnReceiveDataFromMaster(DataItem, ItemReceive, SendBack, From) Export
	//
	ServerEvents.Add("StandardSubsystems.BaseFunctionality\OnReceiveDataFromMaster");
	
	// Handler of the event that occurs after data get to the master node from the subordinate
	// node of a DIB.
	// Is called when the exchange message is read, all data from the exchange message is read and
	// written to the infobase.
	// 
	//  Parameters:
	//   Sender - ExchangePlanObject - exchange plan node object that sent the data.
	//   Cancel - Boolean - Cancellation flag. If True, the message is deemed not received. Also
	//            the data import transaction is rolled back if all data was imported in on 
	//            transaction, or the last data import transaction is rolled back if the data was
	//            imported in portions.
	//
	// Syntax:
	// Procedure DataFromSubordinateAfterReceive(Source = Undefined, DataItem, ItemReceive, SendBack) Export
	//
	ServerEvents.Add("StandardSubsystems.BaseFunctionality\DataFromSubordinateAfterReceive");
	
	// Handler of the event that occurs after data get to the subordinate node from the master
	// node of a DIB.
	// Is called when the exchange message is read, all data from the exchange message is read and
	// written to the infobase.
	// 
	//  Parameters:
	//   Sender - ExchangePlanObject - exchange plan node object that sent the data.
	//   Cancel - Boolean - Cancellation flag. If True, the message is deemed not received. Also
	//            the data import transaction is rolled back if all data was imported in on 
	//            transaction, or the last data import transaction is rolled back if the data was
	//            imported in portions.
	//
	// Syntax:
	// Procedure DataFromMasterAfterReceive(From, Cancel) Export
	//
	ServerEvents.Add("StandardSubsystems.BaseFunctionality\DataFromMasterAfterReceive");
	
	// Handler of the event that occurs after data sending to the subordinate node from the master
	// node of a DIB.
	// Is called when the exchange message is written, when all registered data changes are
	// exported to an exchange message.
	// 
	//  Parameters:
	//   Recipient - ExchangePlanObject. exchange plan node object, for which the message is
	//               generated.
	//   Cancel    - Boolean. Cancellation flag. If True, the message is deemed not generated and
	//               sent.
	//
	// Syntax:
	// Procedure DataToMasterAfterSend(Recipient, Cancel) Export
	//
	ServerEvents.Add("StandardSubsystems.BaseFunctionality\DataToMasterAfterSend");
	
	// Handler of the event that occurs after data sending to the master node from the subordinate
	// node of a DIB.
	// Is called when the exchange message is written, when all registered data changes are
	// exported to an exchange message.
	// 
	//  Parameters:
	//   Recipient - ExchangePlanObject. exchange plan node object, for which the message is
	//               generated.
	//   Cancel    - Boolean. Cancellation flag. If True, the message is deemed not generated and
	//               sent.
	//
	// Syntax:
	// Procedure DataToSubordinateAfterSend(Recipient, Cancel) Export
	//
	ServerEvents.Add("StandardSubsystems.BaseFunctionality\DataToSubordinateAfterSend");
	
	// Fills a structure with arrays of supported versions of all subsystems to be 
	// versioned. The procedure uses subsystem names as keys.
	// Provides functionality of the InterfaceVersion web service.
	// At the embedding stage you have to change the procedure body so that it returns
	// actual version sets (see the following example).
	//
	// Parameters:
	// SupportedVersionStructure - structure with the following parameters: 
	//                            * Keys   - subsystem names. 
	//                            * Values - arrays of supported version descriptions.
	//
	// Example:
	//
	// // FileTransferService
	// VersionArray = New Array;
	// VersionArray.Add("1.0.1.1");	
	// VersionArray.Add("1.0.2.1"); 
	// SupportedVersionStructure.Insert("FileTransferService", VersionArray);
	// // End FileTransferService
	//
	//
	// Syntax:
	// Procedure SupportedInterfaceVersionsOnDefine(Val SupportedVersionStructure) Export
	//
	ServerEvents.Add("StandardSubsystems.BaseFunctionality\SupportedInterfaceVersionsOnDefine");

	
	// Fills a structure of parameters required for client script execution when exiting the
	// application, that is in the following handlers:
	// - BeforeExit,
	// - OnExit.
	//
	// Parameters:
	//   Parameters   - Structure - parameter structure.
	//
	// Syntax:
	// Procedure StandardSubsystemClientLogicParametersOnAddOnExit(Parameters) Export
	//
	ServerEvents.Add("StandardSubsystems.BaseFunctionality\StandardSubsystemClientLogicParametersOnAddOnExit");
	
	// Fills a structure of parameters required for client script execution when starting the
	//  application, that is that is in following event handlers:
	//  - BeforeStart, 
	//  - OnStart.
	//
	// Important: when starting the application, do not use cache reset commands of modules that
	// reuse return values because this can lead to unpredictable errors and unneeded server calls.
	//
	// Parameters:
	//   Parameters - Structure - parameter structure.
	//
	// Returns:
	//   Boolean - False if further parameters filling must be aborted.
	//
	// Syntax:
	// Procedure OnAddStandardSubsystemClientLogicParametersOnStart(Parameters) Export
	//
	ServerEvents.Add("StandardSubsystems.BaseFunctionality\OnAddStandardSubsystemClientLogicParametersOnStart");
	
	// Fills a structure of parameters required for running the application on a client.
	//
	// Parameters:
	//   Parameters - Structure - parameter structure.
	//
	// Syntax:
	// Procedure StandardSubsystemClientLogicParametersOnAdd(Parameters) Export
	//
	ServerEvents.Add("StandardSubsystems.BaseFunctionality\StandardSubsystemClientLogicParametersOnAdd");
	
	// Is used for retrieving metadata objects mandatory for the exchange plan.
	// If there are objects in the subsystem, mandatory to be included in the exchange plan
	// content, add these metadata objects to the Objects parameter.
	//
	// Parameters:
	//  Objects             - Array - list of metadata objects to be included in the exchange plan
	//                        content.
	//  DistributedInfobase - Boolean - (read only) flag that shows whether objects for a DIB
	//                        exchange plan are retrieved.
 // True - list of DIB exchange plan objects is retrieved.
 // False - list of non-DIB exchange plan objects is retrieved.
	//
	ServerEvents.Add("StandardSubsystems.BaseFunctionality\OnGetMandatoryExchangePlanObjects");
	
	// The procedure is used when getting metadata objects that must not be included in the exchange plan content.
	// If there are objects in the subsystem, not to be included in the exchange plan content, add
	// these metadata objects to the Objects parameter.
	//
	// Parameters:
	//  Objects             - Array - list of metadata objects not to be included in the exchange
	//                        plan content.
	//  DistributedInfobase - Boolean - (read only) flag that shows whether objects for a DIB
	//                        exchange plan are retrieved.
	//                         True  - list of the objects to be excluded from a DIB exchange plan
	//                                 is retrieved;
	//                         False - list for an infobase that is not a DIB is retrieved.
	//
	ServerEvents.Add("StandardSubsystems.BaseFunctionality\ExchangePlanObjectsToExcludeOnGet");
	
	// Is used for retrieving metadata objects to be included in the exchange plan content but do
	// NOT included in the change record event subscription content of this exchange plan.
	// These metadata objects are used only when creating initial image of a subordinate node and 
	// do not migrate when exchanging.
	// If there are objects in the subsystem, used only for creating initial image of a 	
	// subordinate node, add these metadata objects to the Objects parameter.
	//
	// Parameters:
	//  Objects - Array - configuration metadata object list.
	//
	ServerEvents.Add("StandardSubsystems.BaseFunctionality\OnGetExchangePlanInitialImageObjects");
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Adding event handlers

// Redefines BaseFunctionality subsystem handlers.
Procedure InternalEventHandlersBaseFunctionalityOnAdd(ClientHandlers, ServerHandlers) Export
	
	// SERVER HANDLERS.
	
	ServerHandlers[
		"StandardSubsystems.BaseFunctionality\StandardSubsystemClientLogicParametersOnAdd"].Add(
		"StandardSubsystemsServer");
		
	ServerHandlers["StandardSubsystems.InfobaseVersionUpdate\OnAddUpdateHandlers"].Add(
		"StandardSubsystemsServer");
		
	ServerHandlers["StandardSubsystems.BaseFunctionality\OnGetMandatoryExchangePlanObjects"].Add(
		"StandardSubsystemsServer");
	
	ServerHandlers["StandardSubsystems.BaseFunctionality\ExchangePlanObjectsToExcludeOnGet"].Add(
		"StandardSubsystemsServer");
	
	ServerHandlers["StandardSubsystems.BaseFunctionality\OnGetExchangePlanInitialImageObjects"].Add(
		"StandardSubsystemsServer");
	
	ServerHandlers["StandardSubsystems.BaseFunctionality\RenamedMetadataObjectsOnAdd"].Add(
		"StandardSubsystemsServer");
	
	ServerHandlers["StandardSubsystems.BaseFunctionality\OnFillPermissionsToAccessExternalResources"].Add(
		"StandardSubsystemsServer");
	//PARTIALLY_DELETED
	//ServerHandlers["StandardSubsystems.ReportOptions\ReportOptionsOnSetup"].Add(
		//"StandardSubsystemsServer");
	
	If CommonUse.SubsystemExists("CloudTechnology.DataImportExport") Then
		ServerHandlers[
			"CloudTechnology.DataImportExport\OnFillCommonDataTypesSupportingRefMappingOnExport"].Add(
				"StandardSubsystemsServer");
	EndIf;
	
EndProcedure


////////////////////////////////////////////////////////////////////////////////
// For the EventHandlers function

Procedure CheckEventNameForUniqueness(Events)
	
	AllEvents    = New Map;
	
	For Each Event In Events Do
		
		If AllEvents.Get(Event) = Undefined Then
			AllEvents.Insert(Event, True);
		Else
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Cannot prepare the list of events.
				           |
				           |The %1 event is already added.'"),
				Event);
		EndIf;
		
	EndDo;
	
EndProcedure

Function EventHandlerTemplate(Events, MandatoryEvents)
	
	EventHandlers  = New Map;
	
	For Each Event In Events Do
		
		If TypeOf(Event) = Type("String") Then // Event name as a string.
			EventHandlers.Insert(Event, New Array);
			
		Else// Event details as a structure - see CommonUse.NewEvent().
			EventHandlers.Insert(Event.Name, New Array);
			If Event.Required Then
				If MandatoryEvents.Get(Event.Name) = Undefined Then
					MandatoryEvents.Insert(Event.Name, True);
				EndIf;
			EndIf;
		EndIf;
		
	EndDo;
	
	Return EventHandlers;
	
EndFunction

Procedure AddMandatoryEventsWithoutHandlers(MandatoryEventsWithoutHandlers,
                                                     MandatoryEvents,
                                                     EventHandlersBySubsystems)
	
	For Each MandatoryEvent In MandatoryEvents Do
		
		HandlerFound = False;
		For Each EventHandlersSubsystems In EventHandlersBySubsystems Do
			
			If EventHandlersSubsystems.Value.Get(MandatoryEvent.Key).Count() <> 0 Then
				HandlerFound = True;
				Break;
			EndIf;
			
		EndDo;
		
		If Not HandlerFound Then
			MandatoryEventsWithoutHandlers.Add(MandatoryEvent.Key);
		EndIf;
	EndDo;
	
EndProcedure

Function StandardEventHandlerDescription(SubsystemDescriptions, EventHandlersBySubsystems)
	
	EventHandlers  = New Map;
	HandlerModules = New Map;
	HandlerEvents  = New Map;
	
	For Each Subsystem In SubsystemDescriptions.order Do
		EventHandlersSubsystems = EventHandlersBySubsystems[Subsystem];
		
		For Each KeyAndValue In EventHandlersSubsystems Do
			Event               = KeyAndValue.Key;
			HandlerDescriptions = KeyAndValue.Value;
			
			Handlers = EventHandlers[Event];
			If Handlers = Undefined Then
				Handlers = New Array;
				EventHandlers.Insert(Event, Handlers);
				HandlerModules.Insert(Event, New Map);
			EndIf;
			
			For Each HandlerDetails In HandlerDescriptions Do
				If TypeOf(HandlerDetails) = Type("Structure") Then
					Handler = HandlerDetails;
				Else
					Handler = New Structure;
					Handler.Insert("Module", HandlerDetails);
				EndIf;
				If Not Handler.Property("Version") Then
					Handler.Insert("Version", "");
				EndIf;
				Handler.Insert("Subsystem", Subsystem);
				
				// Validating the full event handler procedure module name.
				If TypeOf(Handler.Module) <> Type("String")
				 Or Not ValueIsFilled(Handler.Module) Then
					
					Raise StringFunctionsClientServer.SubstituteParametersInString(
						NStr("en = 'Cannot prepare handlers of
						           |the %1 event.
						           |
						           |Invalid module name: ""%2"".'"),
						Event,
						Handler.Module);
				EndIf;
				
				// One module can be specified for one event only.
				If HandlerModules[Event].Get(Handler.Module) = Undefined Then
					HandlerModules[Event].Insert(Handler.Module, True);
				Else
					Raise StringFunctionsClientServer.SubstituteParametersInString(
						NStr("en = 'Cannot prepare handlers of the
						           |""%1"". Module""%2"" module is already added.'"),
						Event,
						Handler.Module);
				EndIf;
				Handlers.Add(New FixedStructure(Handler));
				
				// One handler can be specified for events only once.
				ProcedureName = Mid(Event, Find(Event, "\") + 1);
				HandlerName = Handler.Module + "." + ProcedureName;
				
				If HandlerEvents[HandlerName] = Undefined Then
					HandlerEvents.Insert(HandlerName, Event);
				Else
					Raise StringFunctionsClientServer.SubstituteParametersInString(
						NStr("en = 'Cannot prepare handlers of the %1 event.
						           |The %2 handler is already added for
						           |the %3 event.'"),
						Event,
						HandlerName,
						EventHandlers[HandlerName]);
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
	// Handler array fixation.
	For Each KeyAndValue In EventHandlers Do
		EventHandlers[KeyAndValue.Key] = New FixedArray(KeyAndValue.Value);
	EndDo;
	
	Return New FixedMap(EventHandlers);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// For the UpdateAllApplicationParameters function

Procedure ValidateUpdateAllApplicationParameters(HasChanges, CheckOnly, WithoutChanges = Undefined, InBackground = False)
	
	If TypeOf(WithoutChanges) <> Type("Structure") Then
		WithoutChanges = New Structure;
	EndIf;
	
	If Not WithoutChanges.Property("BaseFunctionalityInternalEvents") Then
		HasCurrentChanges = False;
		Constants.InternalEventParameters.CreateValueManager().Update(HasCurrentChanges, CheckOnly);
		If HasCurrentChanges Then
			HasChanges = True;
			If CheckOnly Then
				Return;
			EndIf;
		Else
			WithoutChanges.Insert("BaseFunctionalityInternalEvents");
		EndIf;
		If InBackground Then
			CommonUseClientServer.MessageToUser("ProgressStepIncrement=20");
		EndIf;
	EndIf;
	
	If Not WithoutChanges.Property("BaseFunctionalityMetadataObjectIDs") Then
		
		If StandardSubsystemsCached.DisableMetadataObjectIDsCatalog() Then
			WithoutChanges.Insert("BaseFunctionalityMetadataObjectIDs");
		Else
			HasCurrentChanges = False;
			If CheckOnly Then
				// Validating critical changes only: metadata object adding, deletion, and renaming.
				Catalogs.MetadataObjectIDs.UpdateData(, HasCurrentChanges, CheckOnly, HasCurrentChanges);
			Else
				Catalogs.MetadataObjectIDs.UpdateData(HasCurrentChanges);
			EndIf;
			If HasCurrentChanges Then
				HasChanges = True;
				If CheckOnly Then
					Return;
				EndIf;
			Else
				WithoutChanges.Insert("BaseFunctionalityMetadataObjectIDs");
			EndIf;
		EndIf;
		If InBackground Then
			CommonUseClientServer.MessageToUser("ProgressStepIncrement=50");
		EndIf;
	EndIf;
	
	If Not WithoutChanges.Property("UsersRunParameters") Then
		
		HasCurrentChanges = False;
		UsersInternal.UpdateUserSessionParameters(HasCurrentChanges, CheckOnly);
		If HasCurrentChanges Then
			HasChanges = True;
			If CheckOnly Then
				Return;
			EndIf;
		Else
			WithoutChanges.Insert("UsersRunParameters");
		EndIf;
		If InBackground Then
			CommonUseClientServer.MessageToUser("ProgressStepIncrement=80");
		EndIf;
	EndIf;
	
	If Not WithoutChanges.Property("AccessManagementAccessRestrictionParameters") Then
		
		If Not CommonUse.SubsystemExists("StandardSubsystems.AccessManagement") Then
			WithoutChanges.Insert("AccessManagementAccessRestrictionParameters");
		Else
			AccessManagementInternalModule = CommonUse.CommonModule("AccessManagementInternal");
			
			HasCurrentChanges = False;
			AccessManagementInternalModule.UpdateAccessRestrictionParameters(HasCurrentChanges, CheckOnly);
			If HasCurrentChanges Then
				HasChanges = True;
				If CheckOnly Then
					Return;
				EndIf;
			Else
				WithoutChanges.Insert("AccessManagementAccessRestrictionParameters");
			EndIf;
		EndIf;
		If InBackground Then
			CommonUseClientServer.MessageToUser("ProgressStepIncrement=100");
		EndIf;
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// For the ApplicationParameterChanges function

Function NextVersion(Version)
	
	Array = StringFunctionsClientServer.SplitStringIntoSubstringArray(Version, ".");
	
	Return CommonUseClientServer.ConfigurationVersionWithoutAssemblyNumber(
		Version) + "." + Format(Number(Array[3]) + 1, "NG=");
	
EndFunction

#EndRegion