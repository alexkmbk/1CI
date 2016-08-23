// Params:
// 	LogLineNumber - serial number of event
//	CommonParams - structore with common params that exist while task running
//  Action - reference to the Action catalog element
//	ActionParams - params that was set for the action only
//  ShowMessages (bool) - determine if it needed to show interactive messages  
//
Function Run(LogLineNumber, CommonParams, Action, ActionParams, ShowMessages) Export					     
	
	Var ReturnCode;
	
	RepositoryTasks.WriteLog(LogLineNumber, CommonParams.TaskRunningEventRef, Action, Enums.ActionEventTypes.Start);
	
	If Not ValueIsFilled(CommonParams.DumpConfFileFullPath) Then		
		RepositoryTasks.WriteLog(CommonParams.TaskRunningEventRef, Action, Enums.ActionEventTypes.Error, "The saving location of configuration file is undefined", ShowMessages);
		Return False; 
	EndIf; 
	
	Try
		RunApp(CommonParams.PlatformPath + " DESIGNER /F """ + CommonParams.DBDir + """ /ConfigurationRepositoryN """ + CommonParams.UserName + """ /ConfigurationRepositoryP """ + CommonParams.Password + """ /ConfigurationRepositoryDumpCfg """ + CommonParams.DumpConfFileFullPath + """ ", ,true, ReturnCode);	
	Except
		RepositoryTasks.WriteLog(LogLineNumber, CommonParams.TaskRunningEventRef, Action, Enums.ActionEventTypes.Error, "Repository dump making error:" + ErrorDescription(), ShowMessages);
		Return False; 
	EndTry; 
	
	
	If (ReturnCode <> 0) Then		
		// In case of failure, try to bind to repository first and try again
		If RepositoryTasks.BindDbToRepository(LogLineNumber, Action, CommonParams, ShowMessages) Then
			Try
				RunApp(CommonParams.PlatformPath + " DESIGNER /F """ + CommonParams.DBDir + """ /ConfigurationRepositoryN """ + CommonParams.UserName + """ /ConfigurationRepositoryP """ + CommonParams.Password + """ /ConfigurationRepositoryDumpCfg """ + CommonParams.DumpConfFileFullPath + """ ", ,true, ReturnCode);	
			Except
				RepositoryTasks.WriteLog(LogLineNumber, CommonParams.TaskRunningEventRef, Action, Enums.ActionEventTypes.Error, "Repository dump making error:" + ErrorDescription(), ShowMessages);
				Return False; 
			EndTry; 
			If (ReturnCode <> 0) Then
				RepositoryTasks.WriteLog(LogLineNumber, CommonParams.TaskRunningEventRef, Action, Enums.ActionEventTypes.Error, "Failure of making dump of the configuration from the repository: the program return " + ReturnCode, ShowMessages);	
				Return False;	
			EndIf;						
		EndIf; 
	EndIf;
	
	RepositoryTasks.WriteLog(LogLineNumber, CommonParams.TaskRunningEventRef, Action, Enums.ActionEventTypes.Success);
	
	Return true;
	
EndFunction

//
//
Function IsRepositoryDataProcessor() Export
	
	Return True; 
	
EndFunction

//
//
Function IsParamsForm() Export
	
	Return False;
	
EndFunction
