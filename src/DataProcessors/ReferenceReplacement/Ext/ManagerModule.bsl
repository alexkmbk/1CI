#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region InternalInterface

// Returns:
//     String - name of the event intended for notifying replacement
//
Function ReplacementNotificationEvent() Export
	Return "LinksReplaced";
EndFunction

#EndRegion

#EndIf