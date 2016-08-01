#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Interface

// Attributes that can be changed for multiple objects at once.
Function BatchProcessingEditableAttributes() Export
	
	Result = New Array;
	Result.Add("UseForObjectForm");
	Result.Add("UseForListForm");
	Result.Add("Responsible");
	Result.Add("Publication");
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf
