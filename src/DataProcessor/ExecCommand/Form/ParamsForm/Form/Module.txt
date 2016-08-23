&AtServer
//
//
Function GetParams()
	DataProcessorParams = new Structure;
	DataProcessorParams.Insert("Command", Command);
	DataProcessorParams.Insert("CurrentDirectory", CurrentDirectory);
	return DataProcessorParams;		
EndFunction
 
&AtClient
Procedure SaveAndClose(Command)
	
	Params = New Structure("ActionParamsUUID, DataProcessorParams", ActionParamsUUID, GetParams()); 
	NotifyChoice(Params);
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Task = ThisForm.Parameters.Task;
	ActionParamsUUID =  ThisForm.Parameters.ActionParamsUUID;
	Params = RepositoryTasks.LoadActionParams(Task, ActionParamsUUID);	
	If Params <> Undefined Then
		Value = Undefined;	
		If TypeOf(Params) <> Type("Structure") Then
			Return;
		EndIf; 
		If Params.Property("Command", Value) Then
			Command = Value;
		EndIf; 
		If Params.Property("CurrentDirectory", Value) Then
			CurrentDirectory = Value;
		EndIf; 
	EndIf; 
	
EndProcedure

&AtClient
Procedure CurrentDirectoryStartChoice(Item, ChoiceData, StandardProcessing)
	RepositoryTasksClient.DirChoice(ThisObject, "CurrentDirectory", "Choose current directory of the command"); 
EndProcedure
