#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("SelfTest") Then
		Return;
	EndIf;
	
	Raise NStr("en='The data processor cannot be opened manually.'");
	
EndProcedure

#EndRegion
