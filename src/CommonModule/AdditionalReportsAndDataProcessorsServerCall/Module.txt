////////////////////////////////////////////////////////////////////////////////
// Additional reports and data processors subsystem
// 
////////////////////////////////////////////////////////////////////////////////

#Region Interface

// Attaches an external report and data processor.
//   For details, see AdditionalReportsAndDataProcessors.AttachExternalDataProcessor().
//
Function AttachExternalDataProcessor(Ref) Export
	
	Return AdditionalReportsAndDataProcessors.AttachExternalDataProcessor(Ref);
	
EndFunction

// Creates and returns an instance of an external report or data processor.
//   For details, see AdditionalReportsAndDataProcessors.GetExternalDataProcessorsObject().
//
Function GetExternalDataProcessorsObject(Ref) Export
	
	Return AdditionalReportsAndDataProcessors.GetExternalDataProcessorsObject(Ref);
	
EndFunction

#EndRegion

#Region InternalProceduresAndFunctions

// Executes a data processor command and puts the result to a temporary storage.
//   For details, see AdditionalReportsAndDataProcessors.ExecuteCommand().
//
Function ExecuteCommand(CommandParameters, ResultAddress = Undefined) Export
	
	Return AdditionalReportsAndDataProcessors.ExecuteCommand(CommandParameters, ResultAddress);
	
EndFunction

// Puts binary data of an additional report or data processor to a temporary storage.
Function PutToStorage(Ref, FormID) Export
	If TypeOf(Ref) <> Type("CatalogRef.AdditionalReportsAndDataProcessors") 
		Or Ref = Catalogs.AdditionalReportsAndDataProcessors.EmptyRef() Then
		Return Undefined;
	EndIf;
	If Not AdditionalReportsAndDataProcessors.CanExportDataProcessorToFile(Ref) Then
		Raise NStr("en = 'Insufficient rights to export additional report or data processor files.'");
	EndIf;
	
	DataProcessorStorage = CommonUse.ObjectAttributeValue(Ref, "DataProcessorStorage");
	
	Return PutToTempStorage(DataProcessorStorage.Get(), FormID);
EndFunction

#EndRegion
