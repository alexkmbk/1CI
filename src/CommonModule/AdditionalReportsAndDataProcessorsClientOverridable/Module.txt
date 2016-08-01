////////////////////////////////////////////////////////////////////////////////
// Additional reports and data processors subsystem
// 
////////////////////////////////////////////////////////////////////////////////

#Region Interface
 
// Executes additional operations before the print form generation.
//
// Parameters:
//  PrintedObjects     - Array   - references to objects for which the print
//                                 command is executed.
//  StandardProcessing - Boolean - shows whether a check if the documents to be
//                                 printed are posted is performed. If False, the
//                                 check is not performed.
//
Procedure BeforeExecuteExternalPrintFormPrintCommand(PrintedObjects, StandardProcessing) Export
	// _Demo begin example 
	//If TypeOf(PrintedObjects[0]) = Type("DocumentRef._DemoCustomerInvoice") Then
	//	StandardProcessing = False;
	//EndIf;
	// _Demo end example
EndProcedure

#EndRegion
