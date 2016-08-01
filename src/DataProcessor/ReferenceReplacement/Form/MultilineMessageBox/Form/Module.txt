
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("SelfTest") Then
		Return;
	EndIf;
	
	// Placing the title
	If Not IsBlankString(Parameters.Title) Then
		Title = Parameters.Title;
		TitleWidth = 1.3 * StrLen(Title);
		If TitleWidth > 40 And TitleWidth < 80 Then
			Width = TitleWidth;
		EndIf;
	EndIf;
	
	// Placing the text
	If StrLineCount(Parameters.MessageText) < 15 Then
		// All lines can be displayed
		Items.MessageText.Title = Parameters.MessageText;
		Items.MultilineMessageText.Visible = False;
	Else
		// Multiline mode
		Items.MessageText.Visible = False;
		MessageText = Parameters.MessageText;
	EndIf;
	
	// Resetting size and position of the form window
	WindowOptionsKey = New UUID;
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OKCommand(Command)
	Close();
EndProcedure

#EndRegion
