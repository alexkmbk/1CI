////////////////////////////////////////////////////////////////////////////////
// Infobase version update subsystem
// Server procedures and functions related to infobase update in the scenario where the configuration version is changed.

//
////////////////////////////////////////////////////////////////////////////////

#Region Interface

// See the description of the same function in the InfobaseUpdate module.
//
// For use in other libraries and configurations.
//
Function ExecuteInfobaseUpdate(ExceptionWhenCannotLockInfobase = True,
	AtStartClientApplication = False, Restart = False) Export
	
	Return InfobaseUpdateInternal.ExecuteInfobaseUpdate(
		ExceptionWhenCannotLockInfobase, AtStartClientApplication, Restart);
	
EndFunction

#EndRegion

#Region InternalInterface

// Unlocks file infobase.
Procedure UnlockFileInfobase() Export
	
	InfobaseUpdateInternal.OnUnlockFileInfobase();
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

// Writes the duration of the main update cycle to a constant.
//
Procedure WriteUpdateExecutionTime(UpdateStartTime, UpdateEndTime) Export
	
	If CommonUseCached.DataSeparationEnabled() And Not CommonUseCached.CanUseSeparatedData() Then
		Return;
	EndIf;
	
	UpdateDetails = InfobaseUpdateInternal.InfobaseUpdateDetails();
	UpdateDetails.UpdateStartTime = UpdateStartTime;
	UpdateDetails.UpdateEndTime = UpdateEndTime;
	
	TimeInSeconds = UpdateEndTime - UpdateStartTime;
	
	Hours = Int(TimeInSeconds/3600);
	Minutes = Int((TimeInSeconds - Hours * 3600) / 60);
	Seconds = TimeInSeconds - Hours * 3600 - Minutes * 60;
	
	DurationHours = ?(Hours = 0, "",
		StringFunctionsClientServer.SubstituteParametersInString(NStr("en = '%1 h'"), Hours));
	DurationMinutes = ?(Minutes = 0, "",
		StringFunctionsClientServer.SubstituteParametersInString(NStr("en = '%1 min'"), Minutes));
	DurationSeconds = ?(Seconds = 0, "",
		StringFunctionsClientServer.SubstituteParametersInString(NStr("en = '%1 sec'"), Seconds));
	UpdateDuration = DurationHours + " " + DurationMinutes + " " + DurationSeconds;
	UpdateDetails.UpdateDuration = TrimAll(UpdateDuration);
	
	InfobaseUpdateInternal.WriteInfobaseUpdateDetails(UpdateDetails);
	
EndProcedure

#EndRegion
