#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure OnWrite(Cancel)
	
	If Not Value Then
		
		DataProcessors.ExternalResourcePermissionSetup.ClearPermissions();
		
	EndIf;
	
EndProcedure

#EndIf