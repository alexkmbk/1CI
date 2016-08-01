&AtClient
Var RefreshInterface;

&AtClient
Var IdleHandlerParameters;

&AtClient
Var LongActionForm;

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("SelfTest") Then
		Return;
	EndIf;
	
	// Values of form attributes 
	RunMode = CommonUseCached.ApplicationRunMode();
	RunMode = New FixedStructure(RunMode);
	
	If Not SafeModeInternal.CanUseSecurityProfiles() Then
		Raise NStr("en = 'Security profiles cannot be used in this applied solution.'");
	EndIf;
	
	If Not SafeModeInternal.CanSetUpSecurityProfiles() Then
		Raise NStr("en = 'Security profiles cannot be set up.'");
	EndIf;
	
	If Not RunMode.IsFullAdministrator Then
		Raise NStr("en = 'Insufficient rights.'");
	EndIf;
	
	// Visibility settings on startup
	ReadProfileSecurityUsageMode();
	
	// Updating item statuses
	SetEnabled();
	
EndProcedure

&AtClient
Procedure OnClose()
	RefreshApplicationInterface();
EndProcedure

#EndRegion

#Region FormHeaderItemEventHandlers

&AtClient
Procedure ProfileSecurityUsageModeOnChange(Item)
	
	Try
		
		StartApplyingSecurityProfileSettings(ThisObject.UUID);
		
		PreviousMode = CurrentSecurityProfileUsageMode();
		NewMode = ProfileSecurityUsageMode;
		
		If (PreviousMode <> NewMode) Then
			
			If (PreviousMode = 2 Or NewMode = 2) Then
				
				ClosingNotification = New NotifyDescription("SecurityProfileCustomizationWizardAfterClose", ThisObject, True);
				
				If NewMode = 2 Then
					
					ExternalResourcePermissionSetupClient.StartEnablingSecurityProfileUsage(ThisObject, ClosingNotification);
					
				Else
					
					ExternalResourcePermissionSetupClient.StartDisablingSecurityProfileUsage(ThisObject, ClosingNotification);
					
				EndIf;
				
			Else
				
				EndApplyingSecurityProfileSettings();
				SetEnabled("ProfileSecurityUsageMode");
				
			EndIf;
			
		EndIf;
		
	Except
		
		ReadProfileSecurityUsageMode();
		Raise;
		
	EndTry;
	
EndProcedure

&AtClient
Procedure InfobaseSecurityProfileOnChange(Item)
	Attachable_AttributeOnChange(Item);
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure RequiredPermissions(Command)
	
	ReportParameters = New Structure();
	ReportParameters.Insert("GenerateOnOpen", True);
	
	OpenForm(
		"Report.ExternalResourcesInUse.ObjectForm",
		ReportParameters);
	
EndProcedure

&AtClient
Procedure RestoreSecurityProfiles(Command)
	
	Try
		
		StartApplyingSecurityProfileSettings(ThisObject.UUID);
		ClosingNotification = New NotifyDescription("SecurityProfileCustomizationWizardAfterClose", ThisObject, True);
		ExternalResourcePermissionSetupClient.StartRestoringSecurityProfiles(ThisObject, ClosingNotification);
		
	Except
		
		ReadProfileSecurityUsageMode();
		Raise;
		
	EndTry;
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

////////////////////////////////////////////////////////////////////////////////
// Client

&AtClient
Procedure SecurityProfileCustomizationWizardAfterClose(Result, ClientApplicationRestartRequired) Export
	
	If Result = DialogReturnCode.OK Then
		EndApplyingSecurityProfileSettings();
	EndIf;
	
	ReadProfileSecurityUsageMode();
	
	If Result = DialogReturnCode.OK And ClientApplicationRestartRequired Then
		Terminate(True);
	EndIf;
	
EndProcedure

&AtServer
Procedure ReadProfileSecurityUsageMode()
	
	ProfileSecurityUsageMode = CurrentSecurityProfileUsageMode();
	SetEnabled("ProfileSecurityUsageMode");
	
EndProcedure

&AtServer
Function CurrentSecurityProfileUsageMode()
	
	If SafeModeInternal.CanUseSecurityProfiles() And GetFunctionalOption("UseSecurityProfiles") Then
		
		If Constants.AutomaticallySetUpPermissionsInSecurityProfiles.Get() Then
			
			Result = 2; // From the current infobase
			
		Else
			
			Result = 1; // Through the cluster console
			
		EndIf;
		
	Else
		
		Result = 0; // Not used
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Procedure StartApplyingSecurityProfileSettings(Val UUID)
	
	If Not SafeModeInternal.CanUseSecurityProfiles() Then
		Raise NStr("en = 'Automatic permission request cannot be enabled.'");
	EndIf;
	
	SetExclusiveMode(True);
	
EndProcedure

&AtServer
Procedure EndApplyingSecurityProfileSettings()
	
	If ProfileSecurityUsageMode = 0 Then
		
		Constants.UseSecurityProfiles.Set(False);
		Constants.AutomaticallySetUpPermissionsInSecurityProfiles.Set(False);
		Constants.InfobaseSecurityProfile.Set("");
		
	ElsIf ProfileSecurityUsageMode = 1 Then
		
		Constants.UseSecurityProfiles.Set(True);
		Constants.AutomaticallySetUpPermissionsInSecurityProfiles.Set(False);
		
	ElsIf ProfileSecurityUsageMode = 2 Then
		
		Constants.UseSecurityProfiles.Set(True);
		Constants.AutomaticallySetUpPermissionsInSecurityProfiles.Set(True);
		
	EndIf;
	
	If ExclusiveMode() Then
		SetExclusiveMode(False);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_AttributeOnChange(Item, UpdateInterface = True)
	
	Result = AttributeOnChangeServer(Item.Name);
	
	RefreshReusableValues();
	
	If UpdateInterface Then
		#If Not WebClient Then
		AttachIdleHandler("RefreshApplicationInterface", 1, True);
		RefreshInterface = True;
		#EndIf
	EndIf;
	
	StandardSubsystemsClient.ShowExecutionResult(ThisObject, Result);
	
EndProcedure

&AtClient
Procedure RefreshApplicationInterface()
	
	#If Not WebClient Then
	If RefreshInterface = True Then
		RefreshInterface = False;
		RefreshInterface();
	EndIf;
	#EndIf
	
EndProcedure

&AtServer
Function AttributeOnChangeServer(ItemName)
	
	Result = New Structure;
	
	DataPathAttribute = Items[ItemName].DataPath;
	
	SaveAttributeValue(DataPathAttribute, Result);
	
	SetEnabled(DataPathAttribute);
	
	RefreshReusableValues();
	
	Return Result;
	
EndFunction

&AtServer
Procedure SaveAttributeValue(DataPathAttribute, Result)
	
	// Saving values of the attributes that are not corresponded to the constants directly (one-to-one)
	If DataPathAttribute = "" Then
		Return;
	EndIf;
	
	// Determining the constant name.
	ConstantName = "";
	If Lower(Left(DataPathAttribute, 14)) = Lower("ConstantsSet.") Then
		// If the path to attribute data is specified through ConstantsSet.
		ConstantName = Mid(DataPathAttribute, 15);
	EndIf;
	
	// Saving the constant value.
	If ConstantName <> "" Then
		ConstantManager = Constants[ConstantName];
		ConstantValue = ConstantsSet[ConstantName];
		
		If ConstantManager.Get() <> ConstantValue Then
			ConstantManager.Set(ConstantValue);
		EndIf;
		
		StandardSubsystemsClientServer.ExecutionResultAddOpenFormNotification(Result, "Write_ConstantsSet", New Structure, ConstantName);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetEnabled(DataPathAttribute = "")
	
	If UsageMode.IsFullAdministrator Then
		
		If DataPathAttribute = "ProfileSecurityUsageMode" Or DataPathAttribute = "" Then
			
			Items.SecurityProfileGroupColumnRight.Enabled = ProfileSecurityUsageMode > 0;
			
			Items.InfobaseSecurityProfile.ReadOnly = (ProfileSecurityUsageMode = 2);
			Items.SecurityProfileRestorationGroup.Enabled = (ProfileSecurityUsageMode = 2);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion
