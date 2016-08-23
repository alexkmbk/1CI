&AtServer
//
//
Function GetParams()
	DataProcessorParams = new Structure;
	DataProcessorParams.Insert("Recipients", Recipients.Unload().UnloadColumn("Email"));
	DataProcessorParams.Insert("MessageTemplate", MessageTemplate);	
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
		If Params.Property("Recipients", Value) Then
			For Each Item In Value Do
				Newl = Recipients.Add();
				Newl.Email = Item;
			EndDo; 
		EndIf; 
		If Params.Property("MessageTemplate", Value) Then
			MessageTemplate = Value;
		EndIf; 		
	EndIf; 
	
EndProcedure
