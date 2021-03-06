﻿
Function RepositoryCodeTaskCodeRunTask(Request)
	
	Try
		RepositoryCode = Number(Request.URLParameters["RepositoryCode"]);	
	Except
	    Response = New HTTPServiceResponse(400);
	EndTry; 
	
	Try
		TaskCode = Number(Request.URLParameters["TaskCode"]);	
	Except
	    Response = New HTTPServiceResponse(400);
	EndTry; 
	
	If RepositoryTasks.RunTaskByCode(RepositoryCode, TaskCode) Then
		Response = New HTTPServiceResponse(200);
	Else
		Response = New HTTPServiceResponse(500);
	EndIf; ;
	
	Return Response;
	
EndFunction
