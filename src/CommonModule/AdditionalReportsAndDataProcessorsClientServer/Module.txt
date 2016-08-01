////////////////////////////////////////////////////////////////////////////////
// Additional reports and data processors subsystem
// 
////////////////////////////////////////////////////////////////////////////////

#Region Interface

////////////////////////////////////////////////////////////////////////////////
// Names of object kinds.

// Print form.
Function DataProcessorKindPrintForm() Export
	
	Return "PrintForm"; // Do not localize this parameter
	
EndFunction

// Filling an object.
Function DataProcessorKindObjectFilling() Export
	
	Return "ObjectFilling"; // Do not localize this parameter
	
EndFunction

// Creation of related objects.
Function DataProcessorKindRelatedObjectCreation() Export
	
	Return "RelatedObjectCreation"; // Do not localize this parameter
	
EndFunction

// Assigned report.
Function DataProcessorKindReport() Export
	
	Return "Report"; // Do not localize this parameter
	
EndFunction

// Additional data processor.
Function DataProcessorKindAdditionalDataProcessor() Export
	
	Return "AdditionalDataProcessor"; // Do not localize this parameter
	
EndFunction

// Additional report.
Function DataProcessorKindAdditionalReport() Export
	
	Return "AdditionalReport"; // Do not localize this parameter
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Names of object kinds.

// Call a client method.
Function CommandTypeClientMethodCall() Export
	
	Return "ClientMethodCall"; // Do not localize this parameter
	
EndFunction

// Call a server method.
Function CommandTypeServerMethodCall() Export
	
	Return "ServerMethodCall"; // Do not localize this parameter
	
EndFunction

// Open a form.
Function CommandTypeOpenForm() Export
	
	Return "FormOpening"; // Do not localize this parameter
	
EndFunction

// Fill a form.
Function CommandTypeFormFilling() Export
	
	Return "FormFilling"; // Do not localize this parameter
	
EndFunction

// Safe mode scenario.
Function CommandTypeScenarioInSafeMode() Export
	
	Return "ScenarioInSafeMode"; // Do not localize this parameter
	
EndFunction

// Import data from a file.
Function CommandTypeDataImportFromFile() Export
	
	Return "DataImportFromFile"; // Do not localize this parameter
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Object type names, which are used for assigned object setup.

// List form ID.
Function ListFormType() Export
	
	Return "ListForm"; // Do not localize this parameter
	
EndFunction

// Object form ID.
Function ObjectFormType() Export
	
	Return "ObjectForm"; // Do not localize this parameter
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Other procedures and functions.

// File filter for dialog boxes used to open or save additional reports or data processors..
Function SelectingAndSavingDialogFilter() Export
	
	Filter = NStr("en = 'External reports and data processors (*.%1, *.%2)|*.%1;*.%2|External reports (*.%1)|*.%1|External data processors (*.%2)|*.%2'");
	Filter = StringFunctionsClientServer.SubstituteParametersInString(Filter, "erf", "epf");
	Return Filter;
	
EndFunction

// Desktop ID
Function DesktopID() Export
	
	Return "Desktop"; // Do not localize this parameter
	
EndFunction

// Subsystem description
Function SubsystemDescription(LanguageCode) Export
	
	Return NStr("en = 'Additional reports and data processors'", ?(LanguageCode = Undefined, CommonUseClientServer.DefaultLanguageCode(), LanguageCode));
	
EndFunction

#EndRegion
