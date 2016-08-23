
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("SelfTest") Then
		Return;
	EndIf;
	
	// Placing a title.
	If Not IsBlankString(Parameters.Title) Then
		Title = Parameters.Title;
		TitleWidth = 1.3 * StrLen(Title);
		If TitleWidth > 40 And TitleWidth < 80 Then
			Width = TitleWidth;
		EndIf;
	EndIf;
	
	If Parameters.LockWholeInterface Then
		WindowOpeningMode = FormWindowOpeningMode.LockWholeInterface;
	EndIf;
	
	// Picture 
	If Parameters.Picture.Type <> PictureType.Empty Then
		Items.Warning.Picture = Parameters.Picture;
	EndIf;
	
	// Placing a text
	If StrLineCount(Parameters.MessageText) < 15 Then
		// All lines can be displayed as text
		Items.MessageText.Title = Parameters.MessageText;
		Items.MultilineMessageText.Visible = False;
	Else
		// Multiline mode.
		Items.MessageText.Visible = False;
		MessageText = Parameters.MessageText;
	EndIf;
	
	// Placing check box
	If ValueIsFilled(Parameters.CheckBoxText) Then
		Items.DontAskAgain.Title = Parameters.CheckBoxText;
	ElsIf Not AccessRight("SaveUserData", Metadata) Or Not Parameters.SuggestDontAskAgain Then
		Items.DontAskAgain.Visible = False;
	EndIf;
	
	// Placing buttons
	AddCommandsAndButtonsOnForm(Parameters.Buttons);
	
	// Setting the default button
	SetDefaultButton(Parameters.DefaultButton);
	
	// Setting the countdown button
	SetTimeoutButton(Parameters.TimeoutButton);
	
	// Setting the countdown timer.
	TimeoutCounter = Parameters.Timeout;
	
	// Reset sizes and position of the form window.
	ResetWindowLocationAndSize();
	
	// Providing command bar visibility during the countdown
	Items.MessageText.Title = Items.MessageText.Title + Chars.LF + Chars.LF;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	// Starting countdown
	If TimeoutCounter >= 1 Then
		TimeoutCounter = TimeoutCounter + 1;
		ReturnMessageTextSize();
		ContinueCountdown();
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemEventHandlers

&AtClient
Procedure Attachable_CommandHandler(Command)
	SelectedValue = ButtonAndReturnValueMap.Get(Command.Name);
	
	ChoiceResult = New Structure;
	ChoiceResult.Insert("DontAskAgain", DontAskAgain);
	ChoiceResult.Insert("Value", DialogReturnCodeByValue(SelectedValue));
	
	Close(ChoiceResult);
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

////////////////////////////////////////////////////////////////////////////////
// Client

&AtClient
Procedure ContinueCountdown()
	TimeoutCounter = TimeoutCounter - 1;
	If TimeoutCounter <= 0 Then
		Close(New Structure("DontAskAgain, Value", False, DialogReturnCode.Timeout));
	Else
		If TimeoutButtonName <> "" Then
			NewTitle = (
				TimeoutButtonTitle
				+ " ("
				+ StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = '%1 sec. left'"),
				String(TimeoutCounter))
				+ ")");
				
			Items[TimeoutButtonName].Title = NewTitle;
		EndIf;
		AttachIdleHandler("ContinueCountdown", 1, True);
	EndIf;
EndProcedure

&AtServer
Procedure ReturnMessageTextSize()
	Items.MessageText.Title = TrimAll(Items.MessageText.Title);
EndProcedure

&AtClient
Function DialogReturnCodeByValue(Value)
	If TypeOf(Value) <> Type("String") Then
		Return Value;
	EndIf;
	
	If Value = "DialogReturnCode.Yes" Then
		Result = DialogReturnCode.Yes;
	ElsIf Value = "DialogReturnCode.No" Then
		Result = DialogReturnCode.No;
	ElsIf Value = "DialogReturnCode.OK" Then
		Result = DialogReturnCode.OK;
	ElsIf Value = "DialogReturnCode.Cancel" Then
		Result = DialogReturnCode.Cancel;
	ElsIf Value = "DialogReturnCode.Retry" Then
		Result = DialogReturnCode.Retry;
	ElsIf Value = "DialogReturnCode.Abort" Then
		Result = DialogReturnCode.Abort;
	ElsIf Value = "DialogReturnCode.Ignore" Then
		Result = DialogReturnCode.Ignore;
	Else
		Result = Value;
	EndIf;
	
	Return Result;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Server

&AtServer
Procedure AddCommandsAndButtonsOnForm(Buttons)
// Adds commands and corresponding to them buttons on the form.
//
// Parameters:
// Buttons - String, ValueList - button set. If the value is String, it must be an  
//           ID string in the following format: "QuestionDialogMode.<One of the
//           QuestionDialogMode values>", for example "QuestionDialogMode.YesNo".
//           If the value is ValueList, for each value list item:
//           Value        - value that the form returns when a button is clicked.
//           Presentation - button title.
// 
	
	If TypeOf(Buttons) = Type("String") Then
		ButtonsValueList = StandardSet(Buttons);
	Else
		ButtonsValueList = Buttons;
	EndIf;
	
	ButtonToValueMapping = New Map;
	
	Index = 0;
	
	For Each ButtonInfoItem In ButtonsValueList Do
		Index = Index + 1;
		CommandName = "Command" + String(Index);
		Command = Commands.Add(CommandName);
		Command.Action  = "Attachable_CommandHandler";
		Command.Title = ButtonInfoItem.Presentation;
		Command.ModifiesStoredData = False;
		
		Button = Items.Add(CommandName, Type("FormButton"), Items.CommandBar);
		Button.OnlyInAllActions = False;
		Button.CommandName = CommandName;
		
		ButtonToValueMapping.Insert(CommandName, ButtonInfoItem.Value);
	EndDo;
	
	ButtonAndReturnValueMap = New FixedMap(ButtonToValueMapping);
EndProcedure

&AtServer
Procedure SetDefaultButton(DefaultButton)
	If ButtonAndReturnValueMap.Count() = 0 Then
		Return;
	EndIf;
	
	For Each Item In ButtonAndReturnValueMap Do
		If Item.Value = DefaultButton Then
			Items[Item.Key].DefaultButton = True;
			Return;
		EndIf;
	EndDo;
	
	Items.CommandBar.ChildItems[0].DefaultButton = True;
EndProcedure

&AtServer
Procedure SetTimeoutButton(TimeoutButtonValue)
	If ButtonAndReturnValueMap.Count() = 0 Then
		Return;
	EndIf;
	
	For Each Item In ButtonAndReturnValueMap Do
		If Item.Value = TimeoutButtonValue Then
			TimeoutButtonName = Item.Key;
			TimeoutButtonTitle = Commands[TimeoutButtonName].Title;
			Return;
		EndIf;
	EndDo;
EndProcedure

&AtServer
Procedure ResetWindowLocationAndSize()
	UserName = InfobaseUsers.CurrentUser().Name;
	If AccessRight("SaveUserData", Metadata) Then
		SystemSettingsStorage.Delete("CommonForm.Question", "", UserName);
	EndIf;
	WindowOptionsKey = String(New UUID);
EndProcedure

&AtServerNoContext
Function StandardSet(Buttons)
	Result = New ValueList;
	
	If Buttons = "QuestionDialogMode.YesNo" Then
		Result.Add("DialogReturnCode.Yes", NStr("en = 'Yes'"));
		Result.Add("DialogReturnCode.No",  NStr("en = 'No'"));
	ElsIf Buttons = "QuestionDialogMode.YesNoCancel" Then
		Result.Add("DialogReturnCode.Yes",    NStr("en = 'Yes'"));
		Result.Add("DialogReturnCode.No",     NStr("en = 'No'"));
		Result.Add("DialogReturnCode.Cancel", NStr("en = 'Cancel'"));
	ElsIf Buttons = "QuestionDialogMode.OK" Then
		Result.Add("DialogReturnCode.OK", NStr("en = 'OK'"));
	ElsIf Buttons = "QuestionDialogMode.OKCancel" Then
		Result.Add("DialogReturnCode.OK",     NStr("en = 'OK'"));
		Result.Add("DialogReturnCode.Cancel", NStr("en = 'Cancel'"));
	ElsIf Buttons = "QuestionDialogMode.RetryCancel" Then
		Result.Add("DialogReturnCode.Retry",  NStr("en = 'Retry'"));
		Result.Add("DialogReturnCode.Cancel", NStr("en = 'Cancel'"));
	ElsIf Buttons = "QuestionDialogMode.AbortRetryIgnore" Then
		Result.Add("DialogReturnCode.Abort",  NStr("en = 'Abort'"));
		Result.Add("DialogReturnCode.Retry",  NStr("en = 'Retry'"));
		Result.Add("DialogReturnCode.Ignore", NStr("en = 'Ignore'"));
	EndIf;
	
	Return Result;
EndFunction

#EndRegion
