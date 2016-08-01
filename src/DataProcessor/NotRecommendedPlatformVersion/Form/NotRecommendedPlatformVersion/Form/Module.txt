
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	// Skipping the initialization to guarantee that the form will be received if the SelfTest parameter is passed.	
	If Parameters.Property("SelfTest") Then 
		Return;
	EndIf;
	
	If Not Parameters.Property("OpenByScenario") Then
		Raise NStr("en='The data processor cannot be opened manually.'");
	EndIf;
	
	SkipExit = Parameters.SkipExit;
	
	Items.MessageText.Title = Parameters.MessageText;
	Items.RecommendedPlatformVersion.Title = Parameters.RecommendedPlatformVersion;
	SystemInfo = New SystemInfo;
	
	Items.Version.Title = StringFunctionsClientServer.SubstituteParametersInString(
		Items.Version.Title, SystemInfo.AppVersion);
	
	If Parameters.Exit Then
		Items.QueryText.Visible = False;
		Items.FormNo.Visible    = False;
		Title = NStr("en = 'The 1C:Enterprise platform must be updated'");
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose()
	
	If Not ActionDefined Then
		ActionDefined = True;
		
		If Not SkipExit Then
			Terminate();
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemEventHandlers

&AtClient
Procedure HyperlinkTextClick(Item)
	
	OpenForm("DataProcessor.NotRecommendedPlatformVersion.Form.PlatformUpdateOrder",,ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ContinueWork(Command)
	
	ActionDefined = True;
	Close("Continue");
	
EndProcedure

&AtClient
Procedure ExitApp(Command)
	
	ActionDefined = True;
	If Not SkipExit Then
		Terminate();
	EndIf;
	Close();
	
EndProcedure

#EndRegion
