////////////////////////////////////////////////////////////////////////////////
// Users subsystem.
//
////////////////////////////////////////////////////////////////////////////////

#Region InternalProceduresAndFunctions

// Generates the user name based on the full name.
Function GetInfobaseUserShortName(Val FullName) Export
	
	Separators = New Array;
	Separators.Add(" ");
	Separators.Add(".");
	
	ShortName = "";
	For Counter = 1 To 3 Do
		
		If Counter <> 1 Then
			ShortName = ShortName + Upper(Left(FullName, 1));
		EndIf;
		
		SeparatorPosition = 0;
		For Each Separator In Separators Do
			CurrentSeparatorPosition = Find(FullName, Separator);
			If CurrentSeparatorPosition > 0
			   AND ( SeparatorPosition = 0
			      OR SeparatorPosition > CurrentSeparatorPosition ) Then
				SeparatorPosition = CurrentSeparatorPosition;
			EndIf;
		EndDo;
		
		If SeparatorPosition = 0 Then
			If Counter = 1 Then
				ShortName = FullName;
			EndIf;
			Break;
		EndIf;
		
		If Counter = 1 Then
			ShortName = Left(FullName, SeparatorPosition - 1);
		EndIf;
		
		FullName = Right(FullName, StrLen(FullName) - SeparatorPosition);
		While Separators.Find(Left(FullName, 1)) <> Undefined Do
			FullName = Mid(FullName, 2);
		EndDo;
	EndDo;
	
	Return ShortName;
	
EndFunction

#EndRegion
