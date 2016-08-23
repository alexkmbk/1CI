

&AtClient
Var PermissionsReceived;

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skipping the initialization to guarantee that the form will be received if the Autotest parameter is passed.
	If Parameters.Property("Autotest") Then 
		Return;
	EndIf;
	
	If Parameters.BlockUser Then
		WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
	EndIf;
	
	If Object.Ref.IsEmpty() Then
		Object.UseForSending = True;
		Object.UseForReceiving = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	NotifyDescription = New NotifyDescription("BeforeCloseConfirmationReceived", ThisObject);
	CommonUseClient.ShowFormClosingConfirmation(NotifyDescription, Cancel);
EndProcedure
 
&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If PermissionsReceived <> True Then
		If Not CheckFilling() Then 
			Cancel = True;
			Return;
		EndIf;
		
		Query = CreateRequestToUseExternalResources();
		ClosingNotification = New NotifyDescription("GetPermitsEnd", ThisObject, WriteParameters);
		
		SafeModeClient.ApplyExternalResourceRequests(
			CommonUseClientServer.ValueInArray(Query), ThisObject, ClosingNotification);
		
		Cancel = True;
	EndIf;
	PermissionsReceived = False;
		
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	If WriteParameters.Property("WriteAndClose") Then
		Close();
	EndIf;
EndProcedure
 
&AtClient
Procedure GetPermitsEnd(Result, WriteParameters) Export
	
	Если Result = DialogReturnCode.OK Then
		PermissionsReceived = True;
		Write(WriteParameters);
	EndIf;
	
EndProcedure
 
&AtServer
Function CreateRequestToUseExternalResources()
	
	Return SafeMode.RequestToUseExternalResources(
		Permissions(), Object.Ref);
	
EndFunction

&AtServer
Function Permissions()
	
	Result = New Array;
	
	If Object.UseForSending Тогда
		Result.Add(
			SafeMode.PermissionToUseInternetResource(
				"SMTP",
				Object.OutgoingMailServer,
				Object.OutgoingMailServerPort,
				NStr("en = 'Email.'")));
	EndIf;
	
	If Object.UseForReceiving Тогда
		Result.Add(
			SafeMode.PermissionToUseInternetResource(
				Object.ProtocolForIncomingMail,
				Object.IncomingMailServer,
				Object.IncomingMailServerPort,
				NStr("en = 'Email.'")));
	EndIf;

	Return Result;
	
EndFunction

#EndRegion

#Region FormHeaderItemEventHandlers

&AtClient
Procedure ProtocolOnChange(Item)
	If Object.ProtocolForIncomingMail = "IMAP" Then
		If Left(Object.IncomingMailServer, 4) = "pop." Then
			Object.IncomingMailServer = "imap." + Mid(Object.IncomingMailServer, 5);
		EndIf
	Else
		If IsBlankString(Object.ProtocolForIncomingMail) Then
			Object.ProtocolForIncomingMail = "POP";
		EndIf;
		If Left(Object.IncomingMailServer, 5) = "imap." Then
			Object.IncomingMailServer = "pop." + Mid(Object.IncomingMailServer, 6);
		EndIf;
	EndIf;
 
	ConnectIncomingMailPort();
EndProcedure

&AtClient
Procedure IncomingMailServerOnChange(Item)
	Object.IncomingMailServer = TrimAll(Lower(Object.IncomingMailServer));
EndProcedure

&AtClient
Procedure OutgoingMailServerOnChange(Item)
	Object.OutgoingMailServer = TrimAll(Lower(Object.OutgoingMailServer));
EndProcedure

&AtClient
Procedure EmailAddressOnChange(Item)
	Object.EmailAddress = TrimAll(Object.EmailAddress);
EndProcedure

&AtClient
Procedure UseSecureConnectionForOutgoingMailOnChange(Элемент)
	ConnectOutgoingMailPort();
EndProcedure

&AtClient
Procedure UseSecureConnectionForIncomingMailOnChange(Item)
	ConnectIncomingMailPort();
EndProcedure

#EndRegion

#Region FormCommandHandlers
 
&AtClient
Procedure WriteAndClose(Command)
	
	Write(New Structure("WriteAndClose"));
	
EndProcedure

#EndRegion
 
#Region InternalProceduresAndFunctions

&AtClient
Procedure ConnectIncomingMailPort()
	If Object.ProtocolForIncomingMail = "IMAP" Then
		If Object.UseSecureConnectionForIncomingMail Then
			Object.IncomingMailServerPort = 993;
		Else
			Object.IncomingMailServerPort = 143;
		EndIf;
	Else
		If Object.UseSecureConnectionForIncomingMail Then
			Object.IncomingMailServerPort = 995;
		Else
			Object.IncomingMailServerPort = 110;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure ConnectOutgoingMailPort()
	If Object.UseSecureConnectionForOutgoingMail Then
		Object.OutgoingMailServerPort = 465;
	Else
		Object.OutgoingMailServerPort = 25;
	EndIf;
EndProcedure
 
&AtClient
Procedure BeforeCloseConfirmationReceived(QuestionResult, AdditionalParameters) Export
	Write(New Structure("WriteAndClose"));
EndProcedure

#EndRegion