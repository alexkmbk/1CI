////////////////////////////////////////////////////////////////////////////////
// Infobase version update subsystem
//
////////////////////////////////////////////////////////////////////////////////

#Region Interface

// Is called by clicking a hyperlink or by double-clicking a cell 
// of a spreadsheet document that application release notes.
//
// Parameters:
//   Area - SpreadsheetDocumentRange - the document area that was clicked.
//
// See also: ShowApplicationReleaseNotes common template.
//
Procedure OnClickUpdateDetailsDocumentHyperlink(Val Area) Export
	
	// _Demo begin example
	If Area.Name = "_DemoHyperlinkSample" Then
		ShowMessageBox(,NStr("en = 'Hyperlink clicked.'"));
	EndIf;
	// _Demo end example
	
EndProcedure

#EndRegion
