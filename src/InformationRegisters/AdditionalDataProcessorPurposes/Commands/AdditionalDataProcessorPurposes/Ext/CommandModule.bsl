&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	Filter = New Structure("TargetObject", CommandParameter);
	FormParameters = New Structure("Filter, OpeningModeFromForm", Filter, True);
	OpenForm("InformationRegister.AdditionalDataProcessorPurposes.ListForm", FormParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);
EndProcedure
