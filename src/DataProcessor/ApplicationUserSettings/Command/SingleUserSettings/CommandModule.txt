&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure("User", CommandParameter);
	OpenForm("DataProcessor.ApplicationUserSettings.Form.ApplicationUserSettings", FormParameters, CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);
	
EndProcedure
