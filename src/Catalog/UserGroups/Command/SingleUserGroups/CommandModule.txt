&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure;
	FormParameters.Insert("User", CommandParameter);
	
	OpenForm("CommonForm.UserGroups",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	
EndProcedure
