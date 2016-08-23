#If Server Or ThickClientOrdinaryApplication Or ExternalConnection  Then 

Procedure BeforeWrite(Cancel)
	
	AdditionalProperties.Insert("CurrentValue", Constants.UseSeparationByDataAreas.Get());
	
EndProcedure

Procedure OnWrite(Cancel)
	
 // The follow constants are mutually exclusive, are used in a separate functional options.
	//
	// Constant.IsStandaloneWorkstation      -> FO.StandaloneModeOperations
	// Constant.DontUseSeparationByDataAreas -> FO.LocalMode
	// Constant.UseSeparationByDataAreas     -> FO.SaaSOperations
	//
	// The constant names a saved to provide backward compatibility.
	
	If Value Then
		
		Constants.DontUseSeparationByDataAreas.Set(False);
		Constants.IsStandaloneWorkstation.Set(False);
		
	ElsIf Constants.IsStandaloneWorkstation.Get() Then
		
		Constants.DontUseSeparationByDataAreas.Set(False);
		
	Else
		
		Constants.DontUseSeparationByDataAreas.Set(True);
		
	EndIf;
	
	If AdditionalProperties.CurrentValue <> Value  Then
		RefreshReusableValues();
		If Value Then
			EventHandlers = CommonUse.InternalEventHandlers(
				"StandardSubsystems.BaseFunctionality\OnEnableSeparationByDataAreas");
			
			For Each Handler  In EventHandlers Do
				Handler.Module.OnEnableSeparationByDataAreas();
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

#EndIf 