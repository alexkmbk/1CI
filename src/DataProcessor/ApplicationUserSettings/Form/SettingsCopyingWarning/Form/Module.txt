
#Region FormHeaderItemEventHandlers

&AtClient
Procedure ActiveUserListClick(Item)
	
	StandardSubsystemsClient.OpenActiveUserList();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Copy(Command)
	
	If Parameters.Action <> "CopyAndClose" Then
		Close();
	EndIf;
	
	Result = New Structure("Action", Parameters.Action);
	Notify("CopySettingsToActiveUsers", Result);
	
EndProcedure

#EndRegion
