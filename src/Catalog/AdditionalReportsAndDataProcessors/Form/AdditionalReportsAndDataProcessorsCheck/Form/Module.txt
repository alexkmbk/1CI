#Region FormCommandHandlers

&AtClient
Procedure GoToList(Command)
	FilterParameters = New Structure;
	FilterParameters.Insert("AdditionalReportsAndDataProcessorsCheck", True);
	
	OpenForm("Catalog.AdditionalReportsAndDataProcessors.Form.ListForm", FilterParameters);
EndProcedure

&AtClient
Procedure CloseForm(Command)
	Close();
EndProcedure

&AtClient
Procedure Checked(Command)
	MarkTaskDone();
	Close();
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure MarkTaskDone()
	
	VersionArray  = StringFunctionsClientServer.SplitStringIntoSubstringArray(Metadata.Version, ".");
	CurrentVersion = VersionArray[0] + VersionArray[1] + VersionArray[2];
	CommonSettingsStorage.Save("ToDoList", "AdditionalReportsAndDataProcessors", CurrentVersion);
	
EndProcedure

#EndRegion