#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure OnWrite(Cancel)
	
	If Value Then
		
		SafeModeInternal.SecurityProfilesOnEnable();
		
	EndIf;
	
EndProcedure

#EndIf
