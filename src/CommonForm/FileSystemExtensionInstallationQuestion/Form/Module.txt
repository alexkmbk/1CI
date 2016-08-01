
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
  // Skipping the initialization to guarantee that the form will be received if the SelfTest parameter is passed.
	If Parameters.Property("SelfTest") Then 
		Return;
	EndIf;
	
	If Not IsBlankString(Parameters.SuggestionText) Then
		Items.CommentDecoration.Title = Parameters.SuggestionText
			+ Chars.LF
			+ NStr("en = 'Do you want to install the extension?'");
		
	ElsIf Not Parameters.CanContinueWithoutInstalling Then
		Items.CommentDecoration.Title =
			NStr("en = 'The action you want to be performed requires the 1C:Enterprise web client extension to be installed .
			           |Do you want to install the extension?'");
	EndIf;
	
	If Not Parameters.CanContinueWithoutInstalling Then
		Items.ContinueWithoutInstalling.Title = NStr("en = 'Cancel'");
		Items.NoLongerPrompt.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure InstallAndContinue(Command)
	
	Notification = New NotifyDescription("InstallAndContinueCompletion", ThisObject);
	BeginInstallFileSystemExtension(Notification);
	
EndProcedure

&AtClient
Procedure ContinueWithoutInstalling(Command)
	Close("ContinueWithoutInstalling");
EndProcedure

&AtClient
Procedure NoLongerPrompt(Command)
	Close("NoLongerPrompt");
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtClient
Procedure InstallAndContinueCompletion(Parameters) Export
	
	Close(?(AttachFileSystemExtension(), "NoLongerPrompt", "ContinueWithoutInstalling"));
	
EndProcedure

#EndRegion
