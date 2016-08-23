#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Var IsGlobalDataProcessor;

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, AttributesToCheck)
	If IsFolder Then
		Return;
	EndIf;
	
	ItemCheck = True;
	If AdditionalProperties.Property("ListCheck") Then
		ItemCheck = False;
	EndIf;
	
	If Not AdditionalReportsAndDataProcessors.IsGlobalDataProcessor(Kind) Then
		If Not UseForObjectForm And Not UseForListForm 
			And Publication <> Enums.AdditionalReportsAndDataProcessorsPublicationVariants.Disabled Then
			CommonUseClientServer.MessageToUser(
				NStr("en = 'Make the report or data processor unavailable or select at least one of its forms.'")
				,
				,
				,
				"Object.UseForObjectForm",
				Cancel);
		EndIf;
	EndIf;
	
	// When an additional report is added, the name used to register the report in the application must be checked for uniqueness.
	If Publication = Enums.AdditionalReportsAndDataProcessorsPublicationVariants.Used Then
		
		// Checking the name
		QueryText =
		"SELECT TOP 1
		|	1
		|FROM
		|	Catalog.AdditionalReportsAndDataProcessors AS AdditionalReports
		|WHERE
		|	AdditionalReports.ObjectName = &ObjectName
		|	AND &AdditReportCondition
		|	AND AdditionalReports.Publication = VALUE(Enum.AdditionalReportsAndDataProcessorsPublicationVariants.Used)
		|	AND AdditionalReports.DeletionMark = FALSE
		|	AND AdditionalReports.Ref <> &Ref";
		
		AdditionalReportKinds = New Array;
		AdditionalReportKinds.Add(Enums.AdditionalReportAndDataProcessorKinds.AdditionalReport);
		AdditionalReportKinds.Add(Enums.AdditionalReportAndDataProcessorKinds.Report);
		
		If AdditionalReportKinds.Find(Kind) <> Undefined Then
			QueryText = StrReplace(QueryText, "&AdditReportCondition", "AdditionalReports.Kind IN (&AdditionalReportKinds)");
		Else
			QueryText = StrReplace(QueryText, "&AdditReportCondition", "Not AdditionalReports.Kind IN (&AdditionalReportKinds)");
		EndIf;
		
		Query = New Query;
		Query.SetParameter("ObjectName",            ObjectName);
		Query.SetParameter("AdditionalReportKinds", AdditionalReportKinds);
		Query.SetParameter("Ref",                   Ref);
		Query.Text = QueryText;
		
		SetPrivilegedMode(True);
		Conflicting = Query.Execute().Unload();
		SetPrivilegedMode(False);
		
		If Conflicting.Count() > 0 Then
			Cancel = True;
			If ItemCheck Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en = 'The report or data processor name ""%1"" is not unique. 
					|
					|To continue, change the publication kind ""%2"" to ""%3"" or ""%4"".'"),
					ObjectName,
					String(Enums.AdditionalReportsAndDataProcessorsPublicationVariants.Used),
					String(Enums.AdditionalReportsAndDataProcessorsPublicationVariants.DebugMode),
					String(Enums.AdditionalReportsAndDataProcessorsPublicationVariants.Disabled)
				);
			Else
				ErrorText = StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en = 'The report or data processor name ""%1"" is not unique. Report or data processor ""%2"" also has that name.'"),
					ObjectName,
					CommonUse.ObjectAttributeValue(ThisObject.Ref, "Description")
				);
			EndIf;
			CommonUseClientServer.MessageToUser(ErrorText, , "Object.Publication");
		EndIf;
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	If IsFolder Then
		Return;
	EndIf;
	
	// Calling the handler directly before writing the object to the infobase.
	AdditionalReportsAndDataProcessors.BeforeWriteAdditionalDataProcessor(ThisObject, Cancel);
	
	If IsNew() And Not AdditionalReportsAndDataProcessors.AddRight(ThisObject) Then
		Raise NStr("en = 'Insufficient access rights for adding additional reports or data processors.'");
	EndIf;
	
	// Preliminary checks
	If Not IsNew() And Kind <> CommonUse.ObjectAttributeValue(Ref, "Kind") Then
		CommonUseClientServer.MessageToUser(
			NStr("en = 'Cannot change the kind of existing additional report or data processor.'"),,,,
			Cancel);
		Return;
	EndIf;
	
	// Dependence of attributes on the deletion mark.
	If DeletionMark Then
		Publication = Enums.AdditionalReportsAndDataProcessorsPublicationVariants.Disabled;
	EndIf;
	
	// Cache of standard checks
	AdditionalProperties.Insert("PublicationUsed", Publication = Enums.AdditionalReportsAndDataProcessorsPublicationVariants.Used);
	
	If IsGlobalDataProcessor() Then
		If ScheduleSetupRight() Then
			BeforeWriteGlobalDataProcessors(Cancel);
		EndIf;
		Purpose.Clear();
	Else
		BeforeWriteAssignableDataProcessor(Cancel);
		Sections.Clear();
	EndIf;
	
EndProcedure
// The handler is called directly after writing an object to the infobase.
Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	If IsFolder Then
		Return;
	EndIf;
	
	QuickAccess = Undefined;
	If AdditionalProperties.Property("QuickAccess", QuickAccess) Then
		InformationRegisters.DataProcessorAccessUserSettings.RefreshDataOnAdditionalObjectWrite(Ref, QuickAccess);
	EndIf;
	
	If IsGlobalDataProcessor() Then
		If ScheduleSetupRight() Then
			OnWriteGlobalDataProcessor(Cancel);
		EndIf;
	Else
		OnWriteAssignableDataProcessors(Cancel);
	EndIf;
	
	If Kind = Enums.AdditionalReportAndDataProcessorKinds.AdditionalReport Then
		OnWriteGlobalReport(Cancel);
	EndIf;
	
EndProcedure
// The handler is called directly after deleting an object from the infobase.
Procedure BeforeDelete(Cancel)
	
	AdditionalReportsAndDataProcessors.BeforeDeleteAdditionalDataProcessor(ThisObject, Cancel);
	
	If DataExchange.Load Then
		Return;
	EndIf;
	If IsFolder Then
		Return;
	EndIf;
	
	If AdditionalReportsAndDataProcessors.IsGlobalDataProcessor(Kind) Then
		BeforeDeleteGlobalDataProcessor(Cancel);
	EndIf;
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

Function IsGlobalDataProcessor()
	
	If IsGlobalDataProcessor = Undefined Then
		IsGlobalDataProcessor = AdditionalReportsAndDataProcessors.IsGlobalDataProcessor(Kind);
	EndIf;
	
	Return IsGlobalDataProcessor;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Global data processors.

Procedure BeforeWriteGlobalDataProcessors(Cancel)
	If Cancel Or Not AdditionalProperties.Property("ActualCommands") Then
		Return;
	EndIf;
	
	CommandTable = AdditionalProperties.ActualCommands;
	
	JobsToUpdate = New Map;
	
	PublicationEnabled = (Publication <> Enums.AdditionalReportsAndDataProcessorsPublicationVariants.Disabled);
	
	// Scheduled jobs must be changed in the privileged mode.
	SetPrivilegedMode(True);
	
	// Clearing jobs whose commands are deleted from the table.
	If Not IsNew() Then
		For Each ObsoleteCommand In Ref.Commands Do
			If ValueIsFilled(ObsoleteCommand.ScheduledJobGUID)
				And CommandTable.Find(ObsoleteCommand.ScheduledJobGUID, "ScheduledJobGUID") = Undefined Then
				
				Job = AdditionalReportsAndDataProcessorsScheduledJobs.FindJob(ObsoleteCommand.ScheduledJobGUID);
				If Job <> Undefined Then
					AdditionalReportsAndDataProcessorsScheduledJobs.DeleteJob(Job);
				EndIf;
				
			EndIf;
		EndDo;
	EndIf;
	
	// Updating the set of scheduled jobs before writing their IDs to the tabular section.
	For Each ActualCommand In CommandTable Do
		
		Command = Commands.Find(ActualCommand.ID, "ID");
		
		If PublicationEnabled And ActualCommand.ScheduledJobSchedule.Count() > 0 Then
			Schedule    = ActualCommand.ScheduledJobSchedule[0].Value;
			Use         = ActualCommand.ScheduledJobUse And ScheduleSpecified(Schedule);
		Else
			Schedule = Undefined;
			Use      = False;
		EndIf;
		
		Job = AdditionalReportsAndDataProcessorsScheduledJobs.FindJob(ActualCommand.ScheduledJobGUID);
		
		If Job = Undefined Then // Job not found
			
			If Use Then
				
				Job = AdditionalReportsAndDataProcessorsScheduledJobs.CreateNewJob(
					JobsPresentation(ActualCommand));
				
				JobsToUpdate.Insert(ActualCommand, Job);
				
				// Creating and registering a scheduled job
				Command.ScheduledJobGUID = 
					AdditionalReportsAndDataProcessorsScheduledJobs.GetJobID(
						Job);
				
			Else
				// No action required
			EndIf;
			
		Else // Job found
			
			If Use Then
				// Registering the scheduled jobs
				JobsToUpdate.Insert(ActualCommand, Job);
			Else
				// Deleting the scheduled job
				AdditionalReportsAndDataProcessorsScheduledJobs.DeleteJob(Job);
				Command.ScheduledJobGUID = New UUID("00000000-0000-0000-0000-000000000000");
			EndIf;
			
		EndIf;
		
	EndDo;
	
	AdditionalProperties.Insert("JobsToUpdate", JobsToUpdate);
	
EndProcedure

Procedure OnWriteGlobalDataProcessor(Cancel)
	
	If Cancel Or Not AdditionalProperties.Property("ActualCommands") Then
		Return;
	EndIf;
	
	PublicationEnabled = (Publication <> Enums.AdditionalReportsAndDataProcessorsPublicationVariants.Disabled);
	
	// Scheduled jobs must be changed in the privileged mode.
	SetPrivilegedMode(True);
	
	For Each KeyAndValue In AdditionalProperties.JobsToUpdate Do
		
		Command = KeyAndValue.Key;
		Job     = KeyAndValue.Value;
		
		If PublicationEnabled And Command.ScheduledJobSchedule.Count() > 0 Then
			Schedule = Command.ScheduledJobSchedule[0].Value;
			Use      = Command.ScheduledJobUse And ScheduleSpecified(Schedule);
		Else
			Schedule = Undefined;
			Use      = False;
		EndIf;
		
		JobParameters = New Array;
		JobParameters.Add(Ref);
		JobParameters.Add(Command.ID);
		
		AdditionalReportsAndDataProcessorsScheduledJobs.SetJobParameters(
			Job,
			Use,
			Left(JobsPresentation(Command), 120),
			JobParameters,
			Schedule);
		
	EndDo;
	
EndProcedure

Procedure BeforeDeleteGlobalDataProcessor(Cancel)
	
	// Scheduled jobs must be changed in the privileged mode.
	SetPrivilegedMode(True);
	
	For Each Command In Commands Do
		
		Job = AdditionalReportsAndDataProcessorsScheduledJobs.FindJob(
			Command.ScheduledJobGUID);
			
		If Job <> Undefined Then
			AdditionalReportsAndDataProcessorsScheduledJobs.DeleteJob(Job);
		EndIf;
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Scheduled job operations.
 
// Checking whether a user has rights to schedule the execution of additional reports and data processors.
Function ScheduleSetupRight()
	
	Return Users.RolesAvailable("AddEditAdditionalReportsAndDataProcessors");
EndFunction

Function JobsPresentation(Command)
	// '%1: %2 / Command: %3'
	Return (
		TrimAll(Kind)
		+ ": "
		+ TrimAll(Description)
		+ " / "
		+ NStr("en = 'Command'")
		+ ": "
		+ TrimAll(Command.Presentation));
EndFunction

Function ScheduleSpecified(Schedule)
	
	Return String(Schedule) <> String(New JobSchedule);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Assignable data processors.

Procedure BeforeWriteAssignableDataProcessor(Cancel)
	PurposeTable = Purpose.Unload();
	PurposeTable.GroupBy("TargetObject");
	Purpose.Load(PurposeTable);
	
	PurposeRegisterUpdate = New Structure("RefArray");
	
	MetadataObjectReferences = PurposeTable.UnloadColumn("TargetObject");
	
	If Not IsNew() Then
		For Each TableRow In Ref.Purpose Do
			If MetadataObjectReferences.Find(TableRow.TargetObject) = Undefined Then
				MetadataObjectReferences.Add(TableRow.TargetObject);
			EndIf;
		EndDo;
	EndIf;
	
	AdditionalProperties.Insert("MetadataObjectReferences", MetadataObjectReferences);
EndProcedure

Procedure OnWriteAssignableDataProcessors(Cancel)
	If Cancel Or Not AdditionalProperties.Property("MetadataObjectReferences") Then
		Return;
	EndIf;
	
	InformationRegisters.AdditionalDataProcessorPurposes.UpdateDataByMetadataObjectReferences(AdditionalProperties.MetadataObjectReferences);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Global reports.

Procedure OnWriteGlobalReport(Cancel)
	
	If CommonUse.SubsystemExists("StandardSubsystems.ReportOptions") Then
		
		Try
			If IsNew() Then
				ExternalObject = ExternalReports.Create(ObjectName);
			Else
				ExternalObject = AdditionalReportsAndDataProcessors.GetExternalDataProcessorsObject(Ref);
			EndIf;
		Except
			ErrorText = NStr("en = 'Attaching error:'") + Chars.LF + DetailErrorDescription(ErrorInfo());
			AdditionalReportsAndDataProcessors.WriteError(Ref, ErrorText);
			AdditionalProperties.Insert("AttachingError", ErrorText);
			Return;
		EndTry;
		
		ReportOptionsModule = CommonUse.CommonModule("ReportOptions");
		ReportOptionsModule.OnWriteAdditionalReport(ThisObject, Cancel, ExternalObject);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
