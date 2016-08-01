
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("Autotest") Then // Skipping the initialization to guarantee that the form will be received if the Autotest parameter is passed.
		Return;
	EndIf;
	
	User = Parameters.User;
	ServiceUserPassword = Parameters.ServiceUserPassword;
	OldEmail = Parameters.OldEmail;
	
EndProcedure

&AtServer
Procedure CreateRequestToChangeEmail()
	
	UsersInternal.OnCreateRequestToChangeEmail(NewEmail, User, ServiceUserPassword);
	
EndProcedure

&AtClient
Procedure ChangeEmailAddress(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	QuestionText = "";
	If Not ValueIsFilled(OldEmail) Then
		QuestionText =
			NStr("en = 'Email address of service user changed.
			           |The owners and administrators of the subscriber will no longer be able to modify the user parameters.'")
			+ Chars.LF
			+ Chars.LF;
	EndIf;
	QuestionText = QuestionText + NStr("en = 'Do you want to change the email address?'");
	
	ShowQueryBox(
		New NotifyDescription("ChangeEmailAddressEnd", ThisObject),
		QuestionText,
		QuestionDialogMode.YesNoCancel);
	
EndProcedure

&AtClient
Procedure ChangeEmailAddressEnd(Answer, NotDefined) Export
	
	If Answer = DialogReturnCode.Yes Then
		
		CreateRequestToChangeEmail();
		
		ShowMessageBox(
			New NotifyDescription("Close", ThisObject),
			NStr("en = 'A confirmation request message has been sent to the specified email address.
			           |The email address will be changed after the user confirmation.'"));
		
	ElsIf Answer = DialogReturnCode.No Then
		Close();
	EndIf;
	
EndProcedure
