
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure;
	FormParameters.Insert("AuthorizationObject", CommandParameter);
	
	Try
		OpenForm(
			"Catalog.ExternalUsers.ObjectForm",
			FormParameters,
			CommandExecuteParameters.Source,
			CommandExecuteParameters.Uniqueness,
			CommandExecuteParameters.Window);
	Except
		ErrorInfo = ErrorInfo();
		If Find(DetailErrorDescription(ErrorInfo),
		         "Raise ErrorAsWarningDescription") > 0 Then
			
			ShowMessageBox(, BriefErrorDescription(ErrorInfo));
		Else
			Raise;
		EndIf;
	EndTry;
	
EndProcedure
