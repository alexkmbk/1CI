////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
//
////////////////////////////////////////////////////////////////////////////////
 
#Region Interface

// Splits the string into several strings by the separator. The separator can be any length.
//
// Parameters:
// String                - String - text with separators;
// Separator             - String - separator, at least 1 character;
// SkipEmptyStrings      - Boolean - flag that shows whether empty strings should be included
//                         in a result;
//                         If this parameter is not set, the function executes in compatibility
//                         with its earlier version mode:
//                          - if space is used as a separator, empty strings are not included  
//                            in the result, for other separators empty strings are included in
//                            the result.
//                          - if String parameter does not contain significant characters (or 
//                            it is an empty string) and space is used as a separator, the 
//                            function returns an array with a single empty string value ("").
//                          - if String parameter does not contain significant characters (or
//                            it is an empty string) and any character except space is used as
//                            a separator, the function returns an empty array.
// TrimNonprintableChars - Boolean - flag that shows whether nonprintable characters in the 
//                         beginning and in the end of the found substrings are trimmed.
//
// Returns:
//  Array - array of String.
//
// Examples:
//  SplitStringIntoSubstringArray(",One,,Two,", ",")      - returns an array of 5 elements, 
//                                                          three of them are empty strings;
//  SplitStringIntoSubstringArray(",One,Two,", ",", True) - returns an array of 2 elements;
//  SplitStringIntoSubstringArray(" one   two  ", " ")    - returns an array of 2 elements;
//  SplitStringIntoSubstringArray("")                     - returns an empty array;
//  SplitStringIntoSubstringArray("",,False)              - returns an array with an empty
//                                                          string ("");
//  SplitStringIntoSubstringArray("", " ")                - returns an array with an empty
//                                                          string ("");
//
Function SplitStringIntoSubstringArray(Val String, Val Separator = ",", Val SkipEmptyStrings = Undefined, TrimNonprintableChars = False) Export
	
	Result = New Array;
	
	// for backward compatibility
	If SkipEmptyStrings = Undefined Then
		SkipEmptyStrings = ?(Separator = " ", True, False);
		If IsBlankString(String) Then 
			If Separator = " " Then
				Result.Add("");
			EndIf;
			Return Result;
		EndIf;
	EndIf;
		
	Position = Find(String, Separator);
	While Position > 0 Do
		Substring = Left(String, Position - 1);
		If Not SkipEmptyStrings Or Not IsBlankString(Substring) Then
 			If TrimNonprintableChars Then
				Result.Add(TrimAll(Substring));
			Else
				Result.Add(Substring);
			EndIf;
		EndIf;
		String = Mid(String, Position + StrLen(Separator));
		Position = Find(String, Separator);
	EndDo;
	
	If Not SkipEmptyStrings Or Not IsBlankString(String) Then
 	If TrimNonprintableChars Then

			Result.Add(TrimAll(String));
		Else
			Result.Add(String);
		EndIf;
	EndIf;	
	Return Result;
	
EndFunction 

// Merges strings from the array into a string with separators.
//
// Parameters:
// Array                 - Array - array of String to be merged into a single string;
// Separator             - String - any character set that will be used as a separator.
// TrimNonprintableChars - Boolean - flag that shows whether nonprintable characters in the 
//                         beginning and in the end of the substrings are trimmed.
//
// Returns:
//  String - string with separators.
//
Function StringFromSubstringArray(Array, Separator = ",", TrimNonprintableChars = False) Export
	
	Result = "";
	
	For Index = 0 to Array.UBound() Do
		Substring = Array[Index];
		
		If TrimNonprintableChars Then
			Substring = TrimAll(Substring);
		EndIf;
		
		If TypeOf(Substring) <> Type("String") Then
			Substring = String(Substring);
		EndIf;
		
		If Index > 0 Then
			Result = Result + Separator;
		EndIf;
		
		Result = Result + Substring;
	EndDo;
	
	Return Result;
	
EndFunction
 
// Determines whether the character is a separator.
//
// Parameters:
// CharCode - Number - character code;
// WordSeparators - String - separator characters.
//
// Returns:
// Boolean - True if the character is a separator.
//
Function IsWordSeparator(CharCode, WordSeparators = Undefined) Export
	
 	If WordSeparators <> Undefined Then

		Return Find(WordSeparators,  Char(CharCode)) >  0;
	 EndIf;
		
		Ranges = New Array;
		Ranges.Add(New Structure("Min,Max", 48, 57)); 		// numerals
		Ranges.Add(New Structure("Min,Max", 65, 90)); 		// capital Roman characters
		Ranges.Add(New Structure("Min,Max", 97, 122));   // lowercase Roman characters
		Ranges.Add(New Structure("Min,Max", 95, 95)); 		// the underscore character (_)
		
		For Each Range In Ranges Do
			If CharCode >= Range.Min And CharCode <= Range.Max Then
				Return False;
			EndIf;
		EndDo;
		
		Return True;
	
EndFunction

// Splits the string into several strings using a specified separator set.
// If the WordSeparators parameter is not specified, any of the characters that are not Roman  
// characters, numeric characters, or the underscore character (_) are considered separators.
//
// Parameters:
// String         - String - string to be split into words.
// WordSeparators - String - string containing separator characters.
//
// Returns:
//  Array of values whose elements are obtained by splitting the string.
//
// Example:
//  SplitStringIntoWordArray("one-@#two2_!three") returns an array of values: "one", "two2_", "three";
//  SplitStringIntoWordArray("one-@#two2_!three", "#@!_") returns an array of values: "one-", "two2", "three".
//
Function SplitStringIntoWordArray(Val String, WordSeparators = Undefined) Export
	
	Words = New Array;
	
	TextSize = StrLen(String);
	WordStart = 1;
	For Position = 1 to TextSize Do
		CharCode = CharCode(String, Position);
		If IsWordSeparator(CharCode, WordSeparators) Then
			If Position <> WordStart Then
				Words.Add(Mid(String, WordStart, Position - WordStart));
			EndIf;
			WordStart = Position + 1;
		EndIf;
	EndDo;
	
	If Position <> WordStart Then
		Words.Add(Mid(String, WordStart, Position - WordStart));
	EndIf;
	
	Return Words;
	
EndFunction

// Substitutes the parameters in the string. The maximum number of the parameters is 9.
// Parameters in the string are specified as %<parameter number>. Parameter numbering starts
// with 1.
//
// Parameters:
// SubstitutionString – String – string pattern that includes parameters in the following
//                      format: %ParameterName;
// Parameter<n>       - String - parameter to be substituted.
//
// Returns:
//  String – string with substituted parameters.
//
// Example:
//  SubstituteParametersInString(NStr("en='%1 went to %2'"), "John", "a zoo") = "John went to a zoo".
//
Function SubstituteParametersInString(Val SubstitutionString,
	Val Parameter1,	Val Parameter2 = Undefined, Val Parameter3 = Undefined,
	Val Parameter4 = Undefined, Val Parameter5 = Undefined, Val Parameter6 = Undefined,
	Val Parameter7 = Undefined, Val Parameter8 = Undefined, Val Parameter9 = Undefined) Export	
 
 	UseAlternativeAlgorithm = 

		Find(Parameter1, "%")
		Or Find(Parameter2, "%")
		Or Find(Parameter3, "%")
		Or Find(Parameter4, "%")
		Or Find(Parameter5, "%")
		Or Find(Parameter6, "%")
		Or Find(Parameter7, "%")
		Or Find(Parameter8, "%")
		Or Find(Parameter9, "%");
		
	If UseAlternativeAlgorithm Then
		SubstitutionString = SubstituteParametersInStringAlternativeAlgorithm(SubstitutionString, Parameter1,
			Parameter2, Parameter3,  Parameter4, Parameter5,  Parameter6, Parameter7,  Parameter8, Parameter9);
	Else
		SubstitutionString = StrReplace(SubstitutionString, "%1",  Parameter1);
		SubstitutionString = StrReplace(SubstitutionString, "%2",  Parameter2);
		SubstitutionString = StrReplace(SubstitutionString, "%3",  Parameter3);
		SubstitutionString = StrReplace(SubstitutionString, "%4",  Parameter4);
		SubstitutionString = StrReplace(SubstitutionString, "%5",  Parameter5);
		SubstitutionString = StrReplace(SubstitutionString, "%6",  Parameter6);
		SubstitutionString = StrReplace(SubstitutionString, "%7",  Parameter7);
		SubstitutionString = StrReplace(SubstitutionString, "%8",  Parameter8);
		SubstitutionString = StrReplace(SubstitutionString, "%9",  Parameter9);
	EndIf;
	
	Return SubstitutionString;	
	
EndFunction

// Substitutes the parameters in the string. The number of the parameters in the string is
// unlimited.
// Parameters in the string are specified as %<parameter number>. Parameter numbering 
// starts with 1.
//
// Parameters:
// SubstitutionString – String – string pattern that includes parameters in the following
//                      format: %ParameterNumber;
// ParameterArray     - Array - array of strings that corresponds to the parameters in the
//                      substitution string.
//
// Returns:
//  String – string with substituted parameters.
//
// Example:
//  ParameterArray = New Array;
//  ParameterArray = ParameterArray.Add("John");
//  ParameterArray = ParameterArray.Add("a zoo");
//
// String = SubstituteParametersInString(NStr("en='%1 went to %2'"), ParameterArray);
//
Function SubstituteParametersInStringFromArray(Val SubstitutionString, Val ParameterArray) Export
	
	ResultString = SubstitutionString;
	
	Index = ParameterArray.Count();
	While Index > 0 Do
		Value = ParameterArray[Index - 1];
		If Not IsBlankString(Value) Then
			ResultString = StrReplace(ResultString, "%" + Format(Index, "NG="), Value);
		EndIf;
		Index = Index - 1;
	EndDo;
	
	Return ResultString;
	
EndFunction

// Substitutes parameter values for their names in the string pattern. Parameters in the string
// are enclosed in square brackets.
//
// Parameters:
//
// StringPattern  - String - string where values is substituted;
// ValuesToInsert - Structure - value structure where keys are parameter names without reserved 
//                  characters and values are values to be substituted.
//
// Returns:
// String - string with substituted values.
//
// Example:
// SubstituteParametersInStringByName("Hello, [Name] [Surname].", New Structure("Surname,Name", "Doe", "John"));
// Returns: "Hello, John Doe".
//
Function SubstituteParametersInStringByName(Val StringPattern, ValuesToInsert) Export
	Result = StringPattern;
	For Each Parameter In ValuesToInsert Do
		Result = StrReplace(Result, "[" + Parameter.Key + "]", Parameter.Value);
	EndDo;
	Return Result;
EndFunction

// Gets parameter values from the string.
//
// Parameters:
// ParameterString - String - string that contains parameters, each of them is a substring
//                   in the following format: <Parameter name>=<Value>.
//                   Substrings are separated from each other by the semicolon character (;).
//                   If the value contains the space character, it must be enclosed in double 
//                   quotation marks (").
// Example:
// "File=""c:\Infobases\Trade""; Usr=""CEO"";"
//
// Returns:
// Structure - parameter structure, where keys are parameter names, and values are parameter 
//             values.
//
Function GetParametersFromString(Val ParameterString) Export
	
	Result = New Structure;
	
	DoubleQuoteChar = Char(34); // (")
	
	SubstringArray = SplitStringIntoSubstringArray(ParameterString, ";");
	
	For Each CurParameterString In SubstringArray Do
		
		FirstEqualSignPosition = Find(CurParameterString, "=");
		
		// Getting parameter name
		ParameterName = TrimAll(Left(CurParameterString, FirstEqualSignPosition - 1));
		
		// Getting parameter value
		ParameterValue = TrimAll(Mid(CurParameterString, FirstEqualSignPosition + 1));
		
		If Left(ParameterValue, 1) = DoubleQuoteChar
			And Right(ParameterValue, 1) = DoubleQuoteChar Then
			
			ParameterValue = Mid(ParameterValue, 2, StrLen(ParameterValue) - 2);
			
		EndIf;
		
	 	If Not IsBlankString(ParameterName) Then

			
			Result.Insert(ParameterName, ParameterValue);
			

		EndIf;
	EndDo;
	
	Return Result;
EndFunction
	
// Checks whether the string contains numeric characters only.
//
// Parameters:
// CheckString           - String - string to be checked.
// IncludingLeadingZeros - Boolean - flag that shows whether the string to be checked can
//                         contain leading zeros. If it is True, leading zeroes are skipped.
// IncludingSpaces       - Boolean - flag that shows whether the string to be checked can
//                         contain spaces. If it is True, spaces are ignored.
//
// Returns:
//  Boolean - True if the string contains numeric characters only or is empty. False if the
//            string contains other characters.
//
Function OnlyDigitsInString(Val CheckString, Val IncludingLeadingZeros = True, Val IncludingSpaces = True) Export
	
	If TypeOf(CheckString) <> Type("String") Then
		Return False;
	EndIf;
	
 	If Not IncludingSpaces Then

		CheckString = StrReplace(CheckString, "  ", "");
	EndIf;
		
	If IsBlankString(CheckString) Then
		Return True;
	EndIf;
	
 	If Not IncludingLeadingZeros Then

		Position = 1;
		// If an out-of-border symbol is taken, an empty string is returned
		While Mid(CheckString, Position, 1) = "0" Do
			Position = Position +  1;

		EndDo;
		CheckString = Mid(CheckString, Position);
	EndIf;
	
	// If the source string contains digits only, the result string after the replacement is empty.
	// The string cannot be checked with IsBlankString because it can contain space characters.
	Return StrLen(
		StrReplace( StrReplace( StrReplace( StrReplace( StrReplace(
		StrReplace( StrReplace( StrReplace( StrReplace( StrReplace( 
			CheckString, "0", ""), "1", ""), "2", ""), "3", ""), "4", ""), "5", ""), "6", ""), "7", ""), "8", ""), "9", "")
	) = 0;	
EndFunction

// Checks whether the string contains Roman characters only.
//
// Parameters:
// WithWordSeparators - Boolean - flag that shows whether the string to be checked can include
//                      word separators. Available word separators are defined in the
//                      IsWordSeparator function;
// AllowedChars       - string to be checked.
//
// Returns:
//  Boolean - True if string contains only Roman characters or is empty, otherwise is False.
//
Function OnlyLatinInString(Val CheckString, Val WithWordSeparators = True, AllowedChars = "") Export
	
	If TypeOf(CheckString) <> Type("String") Then
		Return False;
	EndIf;
	
	If Not ValueIsFilled(CheckString) Then
		Return True;
	EndIf;
	
	ValidCharCodes = New Array;
	
	For a = 1 to StrLen(AllowedChars) Do
		ValidCharCodes.Add(CharCode(Mid(AllowedChars, a, 1)));
	EndDo;
	
	For a = 1 to StrLen(CheckString) Do
		CharCode = CharCode(Mid(CheckString, a, 1));
		If ((CharCode < 65) Or (CharCode > 90 And CharCode < 97) Or (CharCode > 122))
			And (ValidCharCodes.Find(CharCode) = Undefined) 
			And Not (Not WithWordSeparators And IsWordSeparator(CharCode)) Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

// Deletes double quotation marks from the beginning and the end of the string, if any.
//
// Parameters:
//  String - source string;
//
// Returns:
//  String - string without double quotation marks.
//
Function RemoveDoubleQuotationMarks(Val String) Export
	
	While Left(String, 1) = """" Do
		String = Mid(String, 2); 
	EndDo; 
	
	While Right(String, 1) = """" Do
		String = Left(String, StrLen(String) - 1);
	EndDo;
	
	Return String;
	
EndFunction 

// Deletes the specified number of characters from the end of the string.
//
// Parameters:
// Text       - String - string where the last characters is deleted;
// CharsCount - Number - the number of characters to be deleted.
//
Procedure DeleteLastCharsInString(Text, CharsCount) Export
	
	Text = Left(Text, StrLen(Text) - CharsCount);
	
EndProcedure 

// Searches for a character, starts from the end of the string.
//
// Parameters:
// String - String - string where search is performed;
// Char   - String - character or a group of characters to be found. 
//
// Returns:
// Number - character position in the string. 
//          If the string does not contain the specified character, the function returns 0.
//
Function FindCharFromEnd(Val String, Val Char) Export
	
	For Position = -StrLen(String) to -1 Do
		If Mid(String, -Position, StrLen(Char)) = Char Then
			Return -Position;
		EndIf;
	EndDo;
	
	Return 0;
		
EndFunction

// Checks whether a string is a UUID.
// UUID is a string in the following format:
// XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX, where X = [0..9,a..f].
//
// Parameters:
// String - String - string to be checked.
//
// Returns:
// Boolean - True if the passed string is a UUID.
Function IsUUID(Val String) Export
	
	Pattern = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX";
	
	If StrLen(Pattern) <> StrLen(String) Then
		Return False;
	EndIf;
	For Position = 1 to StrLen(String) Do
 		If CharCode(Pattern, Position) = 88 // X
			And ((CharCode(String, Position) < 48 Or CharCode(String, Position) > 57)  // 0..9
			And (CharCode(String, Position) < 97 Or CharCode(String, Position) > 102)  // a..f
			And (CharCode(String, Position) < 65 Or CharCode(String, Position) > 70))  // A..F
			Or CharCode(Pattern, Position) = 45 And CharCode(String, Position) <> 45 Then // -
			Return False;
		EndIf;
	EndDo;
	
	Return True;

EndFunction

// Generates a string of the specified length filled with the specified character.
//
// Parameters:
// Char         - String - character used for filling.
// StringLength - Number - required length of the resulting string.
//
// Returns:
// String - string filled with the specified character.
//
Function GenerateCharacterString(Val Char, Val StringLength) Export
	
	Result = "";
	For Counter = 1 to StringLength Do
		Result = Result + Char;
	EndDo;
	
	Return Result;
	
EndFunction

// Supplements the string to a specified length with characters on the left or on the right and 
// returns it.
// Insignificant characters on the left and on the right are deleted. By default, the function
// supplements a string with 0 (zero) characters on the left.
//
// Parameters:
//  String       - String - source string to be supplemented with characters;
//  StringLength - Number - required string length;
//  Char         - String - character used for supplementing the string;
//  Mode         - String - Left or Right - indicates whether the string is supplemented on the
//                 left or on the right.
// 
// Returns:
//  String - string supplemented with characters.
//
// Example 1:
//  String = "1234"; StringLength = 10; Char = "0"; Mode = "Left"
//  Returns: "0000001234"
//
// Example 2:
//  String = " 1234 "; StringLength = 10; Char = "#"; Mode = "Right"
//  Returns: "1234######"
//
Function SupplementString(Val String, Val StringLength, Val Char = "0", Val Mode = "Left") Export
	

	// The parameter must be a single character.
	Char = Left(Char, 1);
	
	// Deleting spaces on the left and on the right of the string
	String = TrimAll(String);
	
	CharToAddCount = StringLength - StrLen(String);
	
	If CharToAddCount > 0 Then
		
		StringToAdd = GenerateCharacterString(Char, CharToAddCount);
		
		If Upper(Mode) = "LEFT" Then
			
			String = StringToAdd + String;
			
		ElsIf Upper(Mode) = "RIGHT" Then
			
			String = String + StringToAdd;
			
		EndIf;
		
	EndIf;
	
	Return String;
	
EndFunction

// Deletes repeating characters on the left or on the right of the string.
//
// Parameters:
//  String - String - source string where repeating characters is deleted;
//  Char   - String - character to be deleted;
//  Mode   - String - Left or Right - indicates whether characters are deleted on the left or
//           on the right.
// Returns:
//  String - truncated string.
//
Function DeleteDuplicatedChars(Val String, Val Char, Val Mode = "Left") Export
	
	If Upper(Mode) = "LEFT" Then
		
		While Left(String, 1)= Char Do
			
			String = Mid(String, 2);
			
		EndDo;
		
	ElsIf Upper(Mode) = "RIGHT" Then
		
		While Right(String, 1)= Char Do
			
			String = Left(String, StrLen(String) - 1);
			
		EndDo;
		
	EndIf;
	
	Return String;
EndFunction

// Replaces characters in the string.
//
// Parameters:
// CharsToReplace   - String - string of characters to be replaced;
// String           - String - source string;
// ReplacementChars - String - string of characters for replacing CharsToReplace characters.
// 
// Returns:
// String - string with characters replaced.
//
// Note: The function is intended for simple replacement scenarios, for example, for replacing
// the Ä character with the A character.
// The function processes the passed string sequentially, therefore:
// ReplaceOneCharsWithAnother("pd", "spider", "np") returns "sniper",
// ReplaceOneCharsWithAnother("dr", "spider", "rd") does not return "spired".
//
Function ReplaceCharsWithAnother(CharsToReplace, String, ReplacementChars) Export
	
	Result = String;
	
	For CharacterNumber = 1 to StrLen(CharsToReplace) Do
		Result = StrReplace(Result, Mid(CharsToReplace, CharacterNumber, 1), Mid(ReplacementChars, CharacterNumber, 1));
	EndDo;
	
	Return Result;
	
EndFunction

// Converting the Arabic number into a Roman one.
//
// Parameters:
// ArabicNumber	- integer from 0 to 999;
//
// Returns:
// String - number in Roman notation.
//
// Example:
// ConvertNumberIntoRomanNotation(17) = "XVII".
//
Function ConvertNumberIntoRomanNotation(ArabicNumber) Export
	
	RomanNumber	= "";
	ArabicNumber	= SupplementString(ArabicNumber, 3);

	c1 = "I"; c5 = "V"; c10 = "X"; c50 = "L"; c100 ="C"; c500 = "D"; c1000 = "M";

	Units	= Number(Mid(ArabicNumber, 3, 1));
	Tens	= Number(Mid(ArabicNumber, 2, 1));
	Hundreds	= Number(Mid(ArabicNumber, 1, 1));
	
	RomanNumber = RomanNumber + ConvertDigitIntoRomanNotation(Hundreds, c100, c500, c1000);
	RomanNumber = RomanNumber + ConvertDigitIntoRomanNotation(Tens, c10, c50, c100);
	RomanNumber = RomanNumber + ConvertDigitIntoRomanNotation(Units, c1, c5, c10);
	
	Return RomanNumber;
	
EndFunction 

// Converts the Roman number into an Arabic one.
//
// Parameters:
// RomanNumber - String - number in Roman notation;
//
// Returns:
// Number in Arabic notation.
//
// Example:
// ConvertNumberIntoArabNotation("XVII") = 17.
//
Function ConvertNumberIntoArabNotation(RomanNumber) Export
	
	ArabicNumber=0;
	
	c1 = "I"; c5 = "V"; c10 = "X"; c50 = "L"; c100 ="C"; c500 = "D"; c1000 = "M";
	
	RomanNumber = TrimAll(RomanNumber);
	CharsCount = StrLen(RomanNumber);
	
	For Cnt=1 to CharsCount Do
		If Mid(RomanNumber,Cnt,1) = c1000 Then
			ArabicNumber = ArabicNumber+1000;
		ElsIf Mid(RomanNumber,Cnt,1) = c500 Then
			ArabicNumber = ArabicNumber+500;
		ElsIf Mid(RomanNumber,Cnt,1) = c100 Then
			If (Cnt < CharsCount) And ((Mid(RomanNumber,Cnt+1,1) = c500) Or (Mid(RomanNumber,Cnt+1,1) = c1000)) Then
				ArabicNumber = ArabicNumber-100;
			Else
				ArabicNumber = ArabicNumber+100;
			EndIf;
		ElsIf Mid(RomanNumber,Cnt,1) = c50 Then
			ArabicNumber = ArabicNumber+50;
		ElsIf Mid(RomanNumber,Cnt,1) = c10 Then
			If (Cnt < CharsCount) And ((Mid(RomanNumber,Cnt+1,1) = c50) Or (Mid(RomanNumber,Cnt+1,1) = c100)) Then
				ArabicNumber = ArabicNumber-10;
			Else
				ArabicNumber = ArabicNumber+10;
			EndIf;
		ElsIf Mid(RomanNumber,Cnt,1) = c5 Then
			ArabicNumber = ArabicNumber+5;
		ElsIf Mid(RomanNumber,Cnt,1) = c1 Then
			If (Cnt < CharsCount) And ((Mid(RomanNumber,Cnt+1,1) = c5) Or (Mid(RomanNumber,Cnt+1,1) = c10)) Then
				ArabicNumber = ArabicNumber-1;
			Else
				ArabicNumber = ArabicNumber+1;
			EndIf;
		EndIf;
	EndDo;
	
	Return ArabicNumber;
	
EndFunction 

// Returns a text presentation of the number with a unit of measurement in the correct form
// (singular or plural).
//
// Parameters:
//  Number                        - Number - any integer number.
//  UnitOfMeasureInWordParameters - String - different spelling of a unit of measurement, 
//                                  separated by comma.
//
// Returns:
//  String - text presentation of the unit of measurement and a number written in digits.
//
// Examples:
//  NumberInDigitsUnitOfMeasurementInWords(23, "Hour,Hours") = "23 Hours";
//  NumberInDigitsUnitOfMeasurementInWords(1, "Minute,Minutes") = "1 Minute".
//
Function NumberInDigitsUnitOfMeasurementInWords(Val Number, Val UnitOfMeasureInWordParameters) Export

	Result = Format(Number,"NZ=0");
	
	PresentationArray = New Array;
	
	Position = Find(UnitOfMeasureInWordParameters, ",");
	While Position > 0 Do
		Value = TrimAll(Left(UnitOfMeasureInWordParameters, Position-1));
		UnitOfMeasureInWordParameters = Mid(UnitOfMeasureInWordParameters, Position + 1);
		PresentationArray.Add(Value);
		Position = Find(UnitOfMeasureInWordParameters, ",");
	EndDo;
	
	If StrLen(UnitOfMeasureInWordParameters) > 0 Then
		Value = TrimAll(UnitOfMeasureInWordParameters);
		PresentationArray.Add(Value);
	EndIf;	
	
	If Number = 1 Then
		Result = Result + " " + PresentationArray[0];
	ElsIf Number > 1 Then
		Result = Result + " " + PresentationArray[1];
	EndIf;
	
	Return Result;	
			
EndFunction

// Deletes HTML tags from the text and returns the unformatted text. 
//
// Parameters:
//  SourceText - String - HTML formatted text.
//
// Returns:
//  String - free of tags, scripts, and headers text.
//
Function ExtractTextFromHTML(Val SourceText) Export
	Result = "";
	
	Text = Lower(SourceText);
	
	// Removing everything except body
	Position = Find(Text, "<body");
	If Position > 0 Then
		Text = Mid(Text, Position + 5);
		SourceText = Mid(SourceText, Position + 5);
		Position = Find(Text, ">");
		If Position > 0 Then
			Text = Mid(Text, Position + 1);
			SourceText = Mid(SourceText, Position + 1);
		EndIf;
	EndIf;
	
	Position = Find(Text, "</body>");
	If Position > 0 Then
		Text = Left(Text, Position - 1);
		SourceText = Left(SourceText, Position - 1);
	EndIf;
	
	// Removing scripts
	Position = Find(Text, "<script");
	While Position > 0 Do
		ClosingTagPosition = Find(Text, "</script>");
		If ClosingTagPosition = 0 Then
			// Closing tag is not found, removing the remaining text.
			ClosingTagPosition = StrLen(Text);
		EndIf;
		Text = Left(Text, Position - 1) + Mid(Text, ClosingTagPosition + 9);
		SourceText = Left(SourceText, Position - 1) + Mid(SourceText, ClosingTagPosition + 9);
		Position = Find(Text, "<script");
	EndDo;
	
	// Removing styles
	Position = Find(Text, "<style");
	While Position > 0 Do
		ClosingTagPosition = Find(Text, "</style>");
		If ClosingTagPosition = 0 Then
			// Closing tag is not found, removing the remaining text.
			ClosingTagPosition = StrLen(Text);
		EndIf;
		Text = Left(Text, Position - 1) + Mid(Text, ClosingTagPosition + 8);
		SourceText = Left(SourceText, Position - 1) + Mid(SourceText, ClosingTagPosition + 8);
		Position = Find(Text, "<style");
	EndDo;
	
	// Removing all tags	
	Position = Find(Text, "<");
	While Position > 0 Do
		Result = Result + Left(SourceText, Position-1);
		Text = Mid(Text, Position + 1);
		SourceText = Mid(SourceText, Position + 1);
		Position = Find(Text, ">");
		If Position > 0 Then
			Text = Mid(Text, Position + 1);
			SourceText = Mid(SourceText, Position + 1);
		EndIf;
		Position = Find(Text, "<");
	EndDo;
	Result = Result + SourceText;
	
	Return TrimAll(Result);
EndFunction

#EndRegion

#Region InternalProceduresAndFunctions

// Converting the Arabic numerals into a Roman ones. 
//
// Parameters
//  Digit                         - Number - numeral from 0 to 9;
//  RomanOne, RomanFive, RomanTen - String - characters representing Roman numerals.
//
// Returns
// String - characters in the Roman notation.
//
// Example: 
// ConvertDigitIntoRomanNotation(7,"I","V","X") = "VII".
//
Function ConvertDigitIntoRomanNotation(Digit, RomanOne, RomanFive, RomanTen)
	
	RomanDigit="";
	If Digit = 1 Then
		RomanDigit = RomanOne;
	ElsIf Digit = 2 Then
		RomanDigit = RomanOne + RomanOne;
	ElsIf Digit = 3 Then
		RomanDigit = RomanOne + RomanOne + RomanOne;
	ElsIf Digit = 4 Then
		RomanDigit = RomanOne + RomanFive;
	ElsIf Digit = 5 Then
		RomanDigit = RomanFive;
	ElsIf Digit = 6 Then
		RomanDigit = RomanFive + RomanOne;
	ElsIf Digit = 7 Then
		RomanDigit = RomanFive + RomanOne + RomanOne;
	ElsIf Digit = 8 Then
		RomanDigit = RomanFive + RomanOne + RomanOne + RomanOne;
	ElsIf Digit = 9 Then
		RomanDigit = RomanOne + RomanTen;
	EndIf;
	Return RomanDigit;
	
EndFunction

// Substitutes parameters in the string for %1, %2, and so on.
Function SubstituteParametersInStringAlternativeAlgorithm(Val SubstitutionString,
	Val Parameter1, Val Parameter2 = Undefined, Val Parameter3 = Undefined,
	Val Parameter4 = Undefined, Val Parameter5 = Undefined, Val Parameter6 = Undefined,
	Val Parameter7 = Undefined, Val Parameter8 = Undefined, Val Parameter9 = Undefined)
	
	Result = "";
	Position = Find(SubstitutionString, "%");
	While Position > 0 Do 
		Result = Result + Left(SubstitutionString, Position - 1);
		CharAfterPercent = Mid(SubstitutionString, Position + 1, 1);
		ParameterToSubstitute = "";
		If CharAfterPercent = "1" Then
			ParameterToSubstitute =  Parameter1;
		ElsIf CharAfterPercent = "2" Then
			ParameterToSubstitute =  Parameter2;
		ElsIf CharAfterPercent = "3" Then
			ParameterToSubstitute =  Parameter3;
		ElsIf CharAfterPercent = "4" Then
			ParameterToSubstitute =  Parameter4;
		ElsIf CharAfterPercent = "5" Then
			ParameterToSubstitute =  Parameter5;
		ElsIf CharAfterPercent = "6" Then
			ParameterToSubstitute =  Parameter6;
		ElsIf CharAfterPercent = "7" Then
			ParameterToSubstitute =  Parameter7
		ElsIf CharAfterPercent = "8" Then
			ParameterToSubstitute =  Parameter8;
		ElsIf CharAfterPercent = "9" Then
			ParameterToSubstitute =  Parameter9;
		EndIf;
		If ParameterToSubstitute = "" Then
			Result = Result + "%";
			SubstitutionString = Mid(SubstitutionString, Position + 1);
		Else
			Result = Result + ParameterToSubstitute;
			SubstitutionString = Mid(SubstitutionString, Position + 2);
		EndIf;
		Position = Find(SubstitutionString, "%");
	EndDo;
	Result = Result + SubstitutionString;
	
	Return Result;
EndFunction
 
#EndRegion