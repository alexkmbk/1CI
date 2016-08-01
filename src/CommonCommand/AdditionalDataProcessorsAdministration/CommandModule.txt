#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	AdditionalReportsAndDataProcessorsClient.OpenAdditionalReportAndDataProcessorCommandsForm(
		CommandParameter,
		CommandExecuteParameters,
		AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindAdditionalDataProcessor(),
		"Administration");
	
EndProcedure

#EndRegion
