////////////////////////////////////////////////////////////////////////////////
// EVENT HANDLERS

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpenForm("Catalog.EmailAccounts.ObjectForm", 
						New Structure("Key, BlockUser", Account(), True),
		
CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	
EndProcedure

#Region InternalProceduresAndFunctions

&AtServer
Function Account()
	
	Return EmailOperations.SystemAccount();
	
EndFunction

#EndRegion