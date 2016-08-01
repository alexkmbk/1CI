////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
// Common use client procedures and functions.
//
////////////////////////////////////////////////////////////////////////////////

#Region Interface

// Returns True if this is the Mac OS web client.
Function IsMacOSWebClient() Export
	
#If Not WebClient Then
	Return False; // This script works only in web client mode		
#EndIf
	
	SystemInfo = New SystemInfo;
	If Find(SystemInfo.UserAgentInformation, "Macintosh") <> 0 Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// Returns a client platform type.
Function ClientPlatformType() Export
	SystemInfo = New SystemInfo;
	Return SystemInfo.PlatformType;
EndFunction
 
 #EndRegion


#Region InternalProceduresAndFunctions

// Retrieves the style color by the style item name.
//
// Parameters:
//  StyleColorName - String - style item name.
//
// Returns:
//  Color.
//
Function StyleColor(StyleColorName) Export
	
	Return CommonUseServerCall.StyleColor(StyleColorName);
	
EndFunction

// Retrieves the style font by the style item name.
//
// Parameters:
// StyleFontName - String - style font name.
//
// Returns:
//  Font.
//
Function StyleFont(StyleFontName) Export
	
	Return CommonUseServerCall.StyleFont(StyleFontName);
	
EndFunction

#EndRegion