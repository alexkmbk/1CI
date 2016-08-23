////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem. 
// Support of long server actions at the web client.
//
//////////////////////////////////////////////////////////////////////////////// 

#Region InternalProceduresAndFunctions

// Gets the form that indicates progress of a time-consuming action.
//
Function LongActionForm() Export
	
	Return GetForm("CommonForm.LongAction");
	
EndFunction
 
 #EndRegion