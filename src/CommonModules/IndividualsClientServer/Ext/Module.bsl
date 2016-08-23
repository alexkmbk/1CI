////////////////////////////////////////////////////////////////////////////////
// Individuals subsystem
//
////////////////////////////////////////////////////////////////////////////////

#Region Interface

// Splits the full name into a name, middle name, and last name and saves them to a
// structure. 
//
// Parameters:
//  Full name - String - full name where the first word is a name, the last one is a 
//                       last name, all other words are middle name.
//
// Returns:
//  FullNameStructure - Structure with the following fields: 
//                      Name, MiddleName, LastName.
//
Function FullName(Val FullName) Export
	
	FullNameStructure = New Structure("Name, MiddleName, LastName");
	
	SubstringArray = StringFunctionsClientServer.SplitStringIntoSubstringArray(FullName, " ");
	
	If SubstringArray.Count() = 1 Then
		FullNameStructure.Insert("LastName", SubstringArray[0]);
		If SubstringArray.Count() = 2 Then
     FullNameStructure.Insert("LastName", SubstringArray[1]);
			FullNameStructure.Insert("Name", SubstringArray[0]);
		EndIf;
		If SubstringArray.Count() > 2 Then
     FullNameStructure.Insert("LastName", SubstringArray[SubstringArray.Count()-1]);
			FullNameStructure.Insert("Name", SubstringArray[0]);
			MiddleName = "";
			For Step = 2 to SubstringArray.Count()-2 Do
				MiddleName = MiddleName + SubstringArray[Step] + " ";
			EndDo;
			StringFunctionsClientServer.DeleteLastCharsInString(MiddleName, 1);
			FullNameStructure.Insert("MiddleName", MiddleName);
		EndIf;
	EndIf;
	
	Return FullNameStructure;
	
EndFunction

// Generates the initials and last name by the full name passed as one string or in 
// the separate parameters.
//
// Parameters
//  FullNameString - String.
//  Name           - individual name.
//  MiddleName     - individual middle name.
//  LastName       - individual last name.
//
// Returns  
//  String - initials and last name in one string. 
//  Calculated parts are written to Name, MiddleName, and LastName.
//
// Example:
//  Result = IndividualShortName("Howard Joel Wolowitz"); // Result = "H.J.Wolowitz"
//
Function IndividualShortName(FullNameString = "", Name = " ", MiddleName = " ", LastName = " ") Export

	ObjectType = TypeOf(FullNameString);
	If ObjectType = Type("String") Then
		FullName = StringFunctionsClientServer.SplitStringIntoSubstringArray(TrimAll(FullNameString), " ");
		
	Else
		// Using separate parameters
		Return ?(Not IsBlankString(LastName), 
		          ?(Not IsBlankString(Name), Left(Name,1) + ". " + ?(Not IsBlankString(MiddleName), Left(MiddleName,1) + ". ", "") + LastName, LastName),
		          "");
	EndIf;
 
	Name       = "";
	MiddleName = "";
	LastName   = "";
	
	SubstringCount = FullName.Count();
	If SubstringCount = 1 Then
		LastName = FullName[0];
		If SubstringCount  = 2 Then
     LastName = FullName[1];
			Name = FullName[0];
		EndIf;
		If SubstringCount > 2 Then
     LastName = FullName[SubstringCount-1];
			Name = FullName[0];
			For Step = 2 to SubstringCount-2 Do
				MiddleName = MiddleName + FullName[Step] + " ";
			EndDo;
			StringFunctionsClientServer.DeleteLastCharsInString(MiddleName, 1);
		EndIf;
	EndIf;
		
		Return ?(Not IsBlankString(LastName), 
		 ?(Not IsBlankString(Name), Left(Name,1) + ". " + ?(Not IsBlankString(MiddleName), Left(MiddleName,1) + ". ", "") + LastName, LastName),
		 "")
	
EndFunction

// Verifies the full name.
// The full name can be written using Roman alphabet only.
//
// Parameters:
// 	StringParameter - String - full name.
//
// Returns:
// 	True - full name contains Roman characters only, otherwise is False.
//
Function FullNameWrittenCorrectly(Val StringParameter) Export
	
	AllowedChars = "-";
	
	//Return StringFunctionsClientServer.OnlyRomanInString(StringParameter, False, AllowedChars);
	Return StringFunctionsClientServer.OnlyLatinInString(StringParameter, False, AllowedChars);
	
EndFunction

#EndRegion
