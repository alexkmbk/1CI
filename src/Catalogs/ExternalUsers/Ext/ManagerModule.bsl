#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Interface

// Returns a list of attributes that are excluded from the scope of the batch object
// modification data processor.
// 
Function AttributesToSkipOnGroupProcessing() Export
	
	AttributesToSkip = New Array;
	AttributesToSkip.Add("AuthorizationObject");
	AttributesToSkip.Add("SetRolesDirectly");
	AttributesToSkip.Add("InfobaseUserID");
	AttributesToSkip.Add("ServiceUserID");
	AttributesToSkip.Add("InfobaseUserProperties"); 
	
	Return AttributesToSkip;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Import data import from file

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
	
	If Not Parameters.Filter.Property("NotValid") Then
		Parameters.Filter.Insert("NotValid", False);
	EndIf;
	
EndProcedure

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInfo, StandardProcessing)
	
	If FormType = "ObjectForm" And Parameters.Property("AuthorizationObject") Then
		
		StandardProcessing = False;
		SelectedForm = "ItemForm";
		
		FoundExternalUser = Undefined;
		CanAddExternalUser = False;
		
		AuthorizationObjectUsed = UsersInternalServerCall.AuthorizationObjectUsed(
			Parameters.AuthorizationObject,
			,
			FoundExternalUser,
			CanAddExternalUser);
		
		If AuthorizationObjectUsed Then
			Parameters.Insert("Key", FoundExternalUser);
			
		ElsIf CanAddExternalUser Then
			
			Parameters.Insert(
				"NewExternalUserAuthorizationObject", Parameters.AuthorizationObject);
		Else
			ErrorAsWarningDescription =
				NStr("en = 'The right to log on to the application is not granted.'");
				
			Raise ErrorAsWarningDescription;
		EndIf;
		
		Parameters.Delete("AuthorizationObject");
	EndIf;
	
EndProcedure

#EndRegion
