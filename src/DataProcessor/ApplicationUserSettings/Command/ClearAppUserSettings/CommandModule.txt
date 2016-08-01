
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpenForm("DataProcessor.ApplicationUserSettings.Form.ClearAppUserSettings", , CommandExecuteParameters.Source,
			CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);
	
EndProcedure
