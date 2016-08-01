#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Interface
 
// Fills a new account with default values.
//
Procedure FillObjectWithDefaultValues() Export
	
	UserName = NStr("en = '1C:Enterprise'");
	UseForReceiving = False;
	UseForSending = True;
	KeepMessageCopiesAtServer = False;
	KeepMessagesOnServerPeriod = 0;
	Timeout = 30;
	IncomingMailServerPort = 110;
	OutgoingMailServerPort = 25;
	ProtocolForIncomingMail = "POP";
	
EndProcedure
 
////////////////////////////////////////////////////////////////////////////////
// EVENT HANDLERS 

Procedure FillingProcessing(FillingData, StandardProcessing)
	
	FillObjectWithDefaultValues();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, AttributesToCheck)
	
	If Not UseForSending And Not UseForReceiving Then
		AttributesToCheck.Clear();
		AttributesToCheck.Add("Description");
		Return;
	EndIf;
	
	NoncheckableAttributeArray = New Array;
	
	If Not UseForSending Then
		NoncheckableAttributeArray.Add("OutgoingMailServer");
	EndIf;
	
	If Not UseForReceiving Then
		NoncheckableAttributeArray.Add("IncomingMailServer");
	EndIf;
		
	If Not IsBlankString(EmailAddress) 
	   And Not CommonUseClientServer.EmailAddressMeetsRequirements(EmailAddress, True) Then
		CommonUseClientServer.MessageToUser(
			NStr("en = 'Postal address filled in incorrectly.'"), ThisObject, "EmailAddress");
		NoncheckableAttributeArray.Add("EmailAddress");
		Cancel = True;
	EndIf;
	
	CommonUse.DeleteNoCheckAttributesFromArray(AttributesToCheck, NoncheckableAttributeArray);
	
EndProcedure

#EndRegion

#EndIf
