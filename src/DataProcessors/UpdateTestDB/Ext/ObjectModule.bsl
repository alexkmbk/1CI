﻿// Params:
// 	LogLineNumber - serial number of event
//	CommonParams - structore with common params that exist while task running
//  Action - reference to the Action catalog element
//	ActionParams - params that was set for the action only
//  ShowMessages (bool) - determine if it needed to show interactive messages  
//
Function Run(LogLineNumber, CommonParams, Action, ActionParams, ShowMessages) Export					     
	
	Var ReturnCode;
	
	RepositoryTasks.WriteLog(LogLineNumber, CommonParams.TaskRunningEventRef, Action, Enums.ActionEventTypes.Start);
	
	Try
		RunApp(CommonParams.PlatformPath + " DESIGNER /F """ + CommonParams.TestDBDir + """ /N " + CommonParams.TestDBAdminName + ?(ValueIsFilled(CommonParams.TestDBAdminPassword), " /P " + CommonParams.TestDBAdminPassword, "")  + " /LoadCfg """ + CommonParams.DumpConfFileFullPath + """ ",,True, ReturnCode);	
	Except
		RepositoryTasks.WriteLog(LogLineNumber, CommonParams.TaskRunningEventRef, Action, Enums.ActionEventTypes.Error, "Load cf-file in test database error:" + ErrorDescription(), ShowMessages);
		Return False; 
	EndTry; 
	
	If (ReturnCode <> 0) Then		
		RepositoryTasks.WriteLog(LogLineNumber, CommonParams.TaskRunningEventRef, Action, Enums.ActionEventTypes.Error, "Load cf-file in test database error: the program return " + ReturnCode, ShowMessages);	
		Return False;	
	EndIf; 

	Try
		RunApp(CommonParams.PlatformPath + " DESIGNER /F """ + CommonParams.TestDBDir + """ /N " + CommonParams.TestDBAdminName + ?(ValueIsFilled(CommonParams.TestDBAdminPassword), " /P " + CommonParams.TestDBAdminPassword, "")  + " /UpdateDBCfg",,True, ReturnCode);	
	Except
		RepositoryTasks.WriteLog(LogLineNumber, CommonParams.TaskRunningEventRef, Action, Enums.ActionEventTypes.Error, "Update test database error:" + ErrorDescription(), ShowMessages);
		Return False; 
	EndTry; 
	
	If (ReturnCode <> 0) Then		
		RepositoryTasks.WriteLog(LogLineNumber, CommonParams.TaskRunningEventRef, Action, Enums.ActionEventTypes.Error, "Update test database error: the program return " + ReturnCode, ShowMessages);	
		Return False;	
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
