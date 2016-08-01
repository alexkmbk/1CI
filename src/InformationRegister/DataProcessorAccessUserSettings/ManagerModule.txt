#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region InternalProceduresAndFunctions

// The procedure writes the settings that define quick access to data processor.
 
Procedure RefreshDataOnAdditionalObjectWrite(AdditionalReportOrDataProcessor, QuickAccess) Export
	RecordSet = CreateRecordSet();
	RecordSet.Filter.AdditionalReportOrDataProcessor.Set(AdditionalReportOrDataProcessor);
	
	For Each TableRow In QuickAccess Do
		Record = RecordSet.Add();
		Record.AdditionalReportOrDataProcessor = AdditionalReportOrDataProcessor;
		FillPropertyValues(Record, TableRow);
		Record.Available = True;
	EndDo;
	
	RecordSet.Write(True);
EndProcedure

#EndRegion

#EndIf