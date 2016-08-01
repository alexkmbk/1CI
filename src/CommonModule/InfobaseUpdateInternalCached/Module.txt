////////////////////////////////////////////////////////////////////////////////
// Infobase version update subsystem.
//
////////////////////////////////////////////////////////////////////////////////

#Region InternalProceduresAndFunctions

// Checks if the infobase update is required when changing the configuration version.
//
Function InfobaseUpdateRequired() Export
	
	If InfobaseUpdateInternal.UpdateRequired(
			Metadata.Version, InfobaseUpdateInternal.InfobaseVersion(Metadata.Name)) Then
		Return True;
	EndIf;
	
	SetPrivilegedMode(True);
	Run = SessionParameters.ClientParametersOnServer.Get("StartInfobaseUpdate");
	SetPrivilegedMode(False);
	
	If Run <> Undefined And InfobaseUpdateInternal.CanUpdateInfobase() Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// For internal use only
Function EarliestInfobaseVersion() Export
	
	If CommonUseCached.DataSeparationEnabled() Then
		
		InfobaseUpdateInternalSaaSModule = CommonUse.CommonModule(
			"InfobaseUpdateInternalSaaS");
		
		EarliestDataAreaVersion = InfobaseUpdateInternalSaaSModule.EarliestDataAreaVersion();
	Else
		EarliestDataAreaVersion = Undefined;
	EndIf;
	
	InfobaseVersion = InfobaseUpdateInternal.InfobaseVersion(Metadata.Name);
	
	If EarliestDataAreaVersion = Undefined Then
		EarliestInfobaseVersion = InfobaseVersion;
	Else
		If CommonUseClientServer.CompareVersions(InfobaseVersion, EarliestDataAreaVersion) > 0 Then
			EarliestInfobaseVersion = EarliestDataAreaVersion;
		Else
			EarliestInfobaseVersion = InfobaseVersion;
		EndIf;
	EndIf;
	
	Return EarliestInfobaseVersion;
	
EndFunction

#EndRegion
