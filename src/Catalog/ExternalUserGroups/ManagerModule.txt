#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Interface

// Returns a list of attributes that are excluded from the scope of the batch object
// modification data processor.
// 
Function AttributesToSkipOnGroupProcessing() Export
	
	AttributesToSkip = New Array;
	AttributesToSkip.Add("AuthorizationObjectType");
	AttributesToSkip.Add("AllAuthorizationObjects");
 
	
	Return AttributesToSkip;
	
EndFunction

#EndRegion

#EndIf
