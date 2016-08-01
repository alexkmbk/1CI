////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
//
////////////////////////////////////////////////////////////////////////////////

#Region InternalProceduresAndFunctions

// Prompts user to confirm an action that can result data change loss.
//
Procedure ConfirmFormClosingNow() Export
	
	CommonUseClient.ConfirmFormClosing();
	
EndProcedure

// Prompts user to confirm forms closing.
//
Procedure ConfirmArbitraryFormClosingNow() Export
	
	CommonUseClient.ConfirmArbitraryFormClosing();
	
EndProcedure

#EndRegion
