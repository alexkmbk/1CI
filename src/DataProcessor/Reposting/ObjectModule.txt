Function ReadOutFile(LogLineNumber, Path, CommonParams, Action, StorageAddress)
	
	If Not Tasks.FileExists(Path) Then
		Return True;
	EndIf; 
	
	Read = New TextReader(Path);
	
	WereErrors = True;
	
	While True Do
		Line = Read.ReadLine();
		If Line = Undefined Then
			break;
		EndIf; 
		If Line = "start" Then
			RepositoryTasks.WriteLog(LogLineNumber, CommonParams.TaskRunningEventRef, Action, Enums.ActionEventTypes.DetailedInfo,"reposting has been started in the test DB.");	
		EndIf; 
		
		If Left(Line, 6) = "error:" Then
			RepositoryTasks.WriteLog(LogLineNumber, CommonParams.TaskRunningEventRef, Action, Enums.ActionEventTypes.Error,Mid(Line,7), StorageAddress);	
			WereErrors = True;
		EndIf; 
		
		
		If Left(Line, 5) = "info:" Then
			RepositoryTasks.WriteLog(LogLineNumber, CommonParams.TaskRunningEventRef, Action, Enums.ActionEventTypes.DetailedInfo,Mid(Line,6), StorageAddress);	
		EndIf; 
		
		If Line = "done" Then
			RepositoryTasks.WriteLog(LogLineNumber, CommonParams.TaskRunningEventRef, Action, Enums.ActionEventTypes.DetailedInfo,"reposting has been done in the test DB.");	
			return Not WereErrors;
		EndIf; 

	EndDo; 	
	
	Return Not WereErrors;
	
EndFunction
 

// Params:
// 	LogLineNumber - serial number of event
//	CommonParams - structore with common params that exist while task running
//  Action - reference to the Action catalog element
//	ActionParams - params that was set for the action only
//  ShowMessages (bool) - determine if it needed to show interactive messages  
//
Function Run(LogLineNumber, CommonParams, Action, ActionParams, StorageAddress) Export					     
	
	Var ReturnCode;
	
	RepositoryTasks.WriteLog(LogLineNumber, CommonParams.TaskRunningEventRef, Action, Enums.ActionEventTypes.Start);
	
	WereErrors = False;
	
	CountReposted = 0;
	
	UUID = New UUID();
	
	Dir = CommonParams.WorkingDir + UUID + "\";
	
	If Not Tasks.FileExists(Dir) Then
		CreateDirectory(Dir);
	EndIf; 
	
	ExternalDataProxessorPath = Dir + "Reposting.epf";
	
	GetTemplate("RepostingExternalDataProcessor").Write(ExternalDataProxessorPath); 
	
	Try
		RunApp(CommonParams.PlatformPath + " ENTERPRISE /F """ + CommonParams.TestDBDir + """ /N " + CommonParams.TestDBAdminName + ?(ValueIsFilled(CommonParams.TestDBAdminPassword), " /P " + CommonParams.TestDBAdminPassword, "")  + " /Execute """ + ExternalDataProxessorPath + """ /C""" + Dir + """",,True, ReturnCode);	
	Except
		If Tasks.FileExists(Dir + "\out.txt") Then
	Result = ReadOutFile(LogLineNumber, Dir + "\out.txt", CommonParams, Action, StorageAddress);
		EndIf; 
		RepositoryTasks.WriteLog(LogLineNumber, CommonParams.TaskRunningEventRef, Action, Enums.ActionEventTypes.Error, "Reposting error:" + ErrorDescription(), StorageAddress);
		If RepositoryTasks.FileExists(Dir + "\out.txt") Then
			DeleteFiles(Dir);
		EndIf;		
		Return False; 
	EndTry; 
	
	
	If (ReturnCode <> 0) Then		
		If RepositoryTasks.FileExists(Dir + "\out.txt") Then
			Result = ReadOutFile(LogLineNumber, Dir + "\out.txt", CommonParams, Action, StorageAddress);
		EndIf; 
		RepositoryTasks.WriteLog(LogLineNumber, CommonParams.TaskRunningEventRef, Action, Enums.ActionEventTypes.Error, "Reposting error: the program return " + ReturnCode, StorageAddress);
		If RepositoryTasks.FileExists(Dir + "\out.txt") Then
			DeleteFiles(Dir);
		EndIf;
		Return False; 
	EndIf;
	
	
	Result = ReadOutFile(LogLineNumber, Dir + "\out.txt", CommonParams, Action, StorageAddress);
	
	If Result = False Then
		RepositoryTasks.WriteLog(LogLineNumber, CommonParams.TaskRunningEventRef, Action, Enums.ActionEventTypes.Error);
		If RepositoryTasks.FileExists(Dir + "\out.txt") Then
			DeleteFiles(Dir);
		EndIf;		
		Return False;
	EndIf; 	
	
	RepositoryTasks.WriteLog(LogLineNumber, CommonParams.TaskRunningEventRef, Action, Enums.ActionEventTypes.Success);
	If RepositoryTasks.FileExists(Dir + "\out.txt") Then
		DeleteFiles(Dir);
	EndIf;
	
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
