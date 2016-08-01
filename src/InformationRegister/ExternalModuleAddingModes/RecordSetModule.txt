#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure OnWrite(Cancel, Replacing)
	
	SafeModeInternal.InternalDataOnWrite(ThisObject);
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

#EndIf