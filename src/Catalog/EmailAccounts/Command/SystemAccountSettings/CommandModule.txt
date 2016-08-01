 
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FullFormName = "Catalog.EmailAccounts.ObjectForm";
	
	FormParameters = New Structure("Key", PredefinedValue("Catalog.EmailAccounts.SystemEmailAccount"));
	
	FormOwner = CommandExecuteParameters.Source;
	FormUniqueness = CommandExecuteParameters.Uniqueness;
	
	#If WebClient Then
	FormWindow = CommandExecuteParameters.Window;
	#Else
	FormWindow = CommandExecuteParameters.Source;
	#EndIf
	
	OpenForm(FullFormName, FormParameters, FormOwner, FormUniqueness, FormWindow);
	
EndProcedure