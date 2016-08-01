#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skipping the initialization to guarantee that the form will be received if the SelfTest parameter is passed.
	If Parameters.Property("SelfTest") Then
		Return;
	EndIf;
	
	If ValueIsFilled(Parameters.JobID) Then
		TaskID = Parameters.JobID;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose()
	
 	OnCloseAtServer()
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure OnCloseAtServer()
	
	LongActions.CancelJobExecution(JobID);
	
EndProcedure

#EndRegion