////////////////////////////////////////////////////////////////////////////////
// Additional reports and data processors subsystem, procedures and functions 
// for scheduled job management.
// 
////////////////////////////////////////////////////////////////////////////////

#Region Interface

// Creates a scheduled job in the infobase.
//
// Parameters:
//   Description - String, the scheduled job description.
//
// Returns: ScheduledJob.
//
Function CreateNewJob(Val Description) Export
	
	If CommonUseCached.DataSeparationEnabled() And
			CommonUse.SubsystemExists("CloudTechnology.SaaSOperations.AdditionalReportsAndDataProcessorsSaaS") Then
		ModuleAdditionalReportsAndDataProcessorsScheduledJobsSaaS = CommonUse.CommonModule("AdditionalReportsAndDataProcessorsScheduledJobsSaaS");
		Return ModuleAdditionalReportsAndDataProcessorsScheduledJobsSaaS.CreateNewJob();
	EndIf;
	
	Job = ScheduledJobs.CreateScheduledJob("StartingAdditionalDataProcessors");
	Job.Use = False;
	Job.Description  = Description;
	Job.Write();
	
	Return Job;
	
EndFunction

// Returns scheduled job ID (for storing to the Infobase).
//
// Job - ScheduledJob.
//
// Returns: UUID.
//
Function GetJobID(Val Job) Export
	
	If CommonUseCached.DataSeparationEnabled() And 
			CommonUse.SubsystemExists("CloudTechnology.SaaSOperations.AdditionalReportsAndDataProcessorsSaaS") Then
		ModuleAdditionalReportsAndDataProcessorsScheduledJobsSaaS = CommonUse.CommonModule("AdditionalReportsAndDataProcessorsScheduledJobsSaaS");
		Return ModuleAdditionalReportsAndDataProcessorsScheduledJobsSaaS.GetJobID(Job);
	EndIf;
	
	Return Job.UUID;
	
EndFunction

// Sets scheduled job parameters.
//
// Parameters:
//   Job - ScheduledJob.
//   Use - Boolean, flag that shows whether the scheduled job is used.
//   Description - String, the scheduled job description. 
//   Parameters  - Array (custom), scheduled job parameters. 
//   Schedule    - JobShedule.
//
Procedure SetJobParameters(Job, Use, Description, Parameters, Schedule) Export
	
	If CommonUseCached.DataSeparationEnabled() And
			CommonUse.SubsystemExists("CloudTechnology.SaaSOperations.AdditionalReportsAndDataProcessorsSaaS") Then
		ModuleAdditionalReportsAndDataProcessorsScheduledJobsSaaS = CommonUse.CommonModule("AdditionalReportsAndDataProcessorsScheduledJobsSaaS");
		ModuleAdditionalReportsAndDataProcessorsScheduledJobsSaaS.SetJobParameters(Job, Use, Parameters, Schedule);
		Return;
	EndIf;
	
	Job.Use         = Use;
	Job.Description = Description;
	Job.Parameters  = Parameters;
	Job.Schedule    = Schedule;
	
	Job.Write();
	
EndProcedure

// Returns scheduled job parameters.
//
// Parameters:
//   Job - ScheduledJob.
//
// Returns: Structure with the following keys:
//   Use         - Boolean, flag that shows whether the scheduled job is used. 
//   Description - String, the scheduled job description.
//   Parameters  - Array (custom), scheduled job parameters.
//   Schedule    - JobShedule.
//
Function GetJobParameters(Val Job) Export
	
	If CommonUseCached.DataSeparationEnabled() And
			CommonUse.SubsystemExists("CloudTechnology.SaaSOperations.AdditionalReportsAndDataProcessorsSaaS") Then
		ModuleAdditionalReportsAndDataProcessorsScheduledJobsSaaS = CommonUse.CommonModule("AdditionalReportsAndDataProcessorsScheduledJobsSaaS");
		Return ModuleAdditionalReportsAndDataProcessorsScheduledJobsSaaS.GetJobParameters(Job);
	EndIf;
	
	Result = New Structure();
	Result.Insert("Use",         Job.Use);
	Result.Insert("Description", Job.Description);
	Result.Insert("Parameters",  Job.Parameters);
	Result.Insert("Schedule",    Job.Schedule);
	
	Return Result;
	
EndFunction

// Searches for job by ID (presumably stored in the Infobase).
//
// Parameters: ID - UUID.
//
// Returns: ScheduledJob.
//
Function FindJob(Val ID) Export
	
	If CommonUseCached.DataSeparationEnabled()
			And CommonUse.SubsystemExists("CloudTechnology.SaaSOperations.AdditionalReportsAndDataProcessorsSaaS") Then
		ModuleAdditionalReportsAndDataProcessorsScheduledJobsSaaS = CommonUse.CommonModule("AdditionalReportsAndDataProcessorsScheduledJobsSaaS");
		Return ModuleAdditionalReportsAndDataProcessorsScheduledJobsSaaS.FindJob(ID);
	EndIf;
	
	If Not ValueIsFilled(ID) Then
		Return Undefined;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Job = ScheduledJobs.FindByUUID(ID);
	
	Return Job;
	
EndFunction

// Deletes a scheduled job from the infobase.
//
// Parameters:
// Job - ScheduledJob.
//
Procedure DeleteJob(Val Job) Export
	
	If CommonUseCached.DataSeparationEnabled() And
			CommonUse.SubsystemExists("CloudTechnology.SaaSOperations.AdditionalReportsAndDataProcessorsSaaS") Then
		ModuleAdditionalReportsAndDataProcessorsScheduledJobsSaaS = CommonUse.CommonModule("AdditionalReportsAndDataProcessorsScheduledJobsSaaS");
		ModuleAdditionalReportsAndDataProcessorsScheduledJobsSaaS.DeleteJob(Job);
		Return;
	EndIf;
	
	If TypeOf(Job) = Type("ScheduledJob") Then
		Job.Delete();
	EndIf;
	
EndProcedure

#EndRegion
