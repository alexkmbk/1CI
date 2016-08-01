#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Var ValueChanged;

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	ValueChanged = Value <> Constants.UseExternalUsers.Get();
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If ValueChanged Then
		UsersInternal.UpdateExternalUserRoles();
		If CommonUse.SubsystemExists("StandardSubsystems.AccessManagement") Then
			AccessManagementModule = CommonUse.CommonModule("AccessManagement");
			AccessManagementModule.UpdateUserRoles(Type("CatalogRef.ExternalUsers"));
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
