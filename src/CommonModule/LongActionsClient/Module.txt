////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
// Support of long server actions at the web client.
//
//////////////////////////////////////////////////////////////////////////////// 

#Region Interface

// Fills the parameter structure with default values.
// 
// Parameters:
// IdleHandlerParameters - Structure - procedure fills this structure with default values. 
//
// 
Procedure InitIdleHandlerParameters(IdleHandlerParameters) Export
	
	IdleHandlerParameters = New Structure(
		"MinInterval,MaxInterval,CurrentInterval,IntervalIncreaseCoefficient", 1, 15, 1, 1.4);
	
EndProcedure

// Fills the parameter structure with new calculated values.
// 
// Parameters:
// IdleHandlerParameters - Structure - procedure fills this structure with calculated values.
//
// 
Procedure UpdateIdleHandlerParameters(IdleHandlerParameters) Export
	
	IdleHandlerParameters.CurrentInterval = IdleHandlerParameters.CurrentInterval * IdleHandlerParameters.IntervalIncreaseCoefficient;
	If IdleHandlerParameters.CurrentInterval > IdleHandlerParameters.MaxInterval Then
		IdleHandlerParameters.CurrentInterval = IdleHandlerParameters.MaxInterval;
	EndIf;
		
EndProcedure
 


////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for working with the long action form. 

// Opens the long operation progress bar form.
// 
// Parameters:
// FormOwner - ManagedForm - the form from which the long action form is opened. 
// TaskID - UUID - scheduled job ID.
//
// Returns:
// ManagedForm - opened form reference.
//
Function OpenLongActionForm(Val FormOwner, Val TaskID) Export
	
	LongActionForm = LongActionsClientCached.LongActionForm();
	If LongActionForm.IsOpen() Then
		LongActionForm = OpenForm(
			"CommonForm.LongAction",
			New Structure("TaskID", TaskID), 
			FormOwner);
	Else
		LongActionForm.FormOwner = FormOwner;
		LongActionForm.TaskID    = TaskID;
		LongActionForm.Open();
	EndIf;
	
	Return LongActionForm;
	
EndFunction

// Closes the long action progress bar form.
// 
// Parameters:
// LongActionForm - ManagedForm - long action progress bar form reference.
// 
Procedure CloseLongActionForm(LongActionForm) Export
	
	If TypeOf(LongActionForm) = Type("ManagedForm") Then
		If LongActionForm.IsOpen() Then
			LongActionForm.Close();
		EndIf;
	EndIf;
	LongActionForm = Undefined;
	
EndProcedure
 
#EndRegion