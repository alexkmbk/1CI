#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Interface

// Returns a list of attributes that are excluded from the scope of the batch object
// modification data processor.
// 
Function AttributesToSkipOnGroupProcessing() Export
	
	AttributesToSkip = New Array;
	AttributesToSkip.Add("Internal");
	AttributesToSkip.Add("InfobaseUserID");
	AttributesToSkip.Add("ServiceUserID");
	AttributesToSkip.Add("InfobaseUserProperties");
	
	Return AttributesToSkip;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Import data from file

// Prohibits importing data to the catalog from the "Import data from file" subsystem.
// Batch data import to that catalog is potentially insecure.
// 
Function UseDataImportFromFile() Export
	Return False;
EndFunction

#EndRegion

#EndIf

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If NOT Parameters.Filter.Property("NotValid") Then
		Parameters.Filter.Insert("NotValid", False);
	EndIf;
	
	If NOT Parameters.Filter.Property("Internal") Then
		Parameters.Filter.Insert("Internal", False);
	EndIf;
	
EndProcedure

#EndRegion
