
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("Autotest") Then
		Return;
	EndIf;
	
	// Filling the table of available sections
	
	UsedSections = New Array;
	If Parameters.DataProcessorKind = Enums.AdditionalReportAndDataProcessorKinds.AdditionalDataProcessor Then
		UsedSections = AdditionalReportsAndDataProcessors.AdditionalDataProcessorSections();
	Else
		UsedSections = AdditionalReportsAndDataProcessors.AdditionalReportSections();
	EndIf;
	
	Desktop = AdditionalReportsAndDataProcessorsClientServer.DesktopID();
	
	For Each Section In UsedSections Do
		NewRow = Sections.Add();
		If Section = Desktop Then
			NewRow.Section = Catalogs.MetadataObjectIDs.EmptyRef();
		Else
			NewRow.Section = CommonUse.MetadataObjectID(Section);
		EndIf;
		NewRow.Presentation = AdditionalReportsAndDataProcessors.SectionPresentation(NewRow.Section);
	EndDo;
	
	Sections.Sort("Presentation Asc");
	
	// Enabling sections
	
	For Each ListItem In Parameters.Sections Do
		FoundRow = Sections.FindRows(New Structure("Section", ListItem.Value));
		If FoundRow.Count() = 1 Then
			FoundRow[0].Used = True;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OK(Command)
	
	ChoiceResult = New ValueList;
	
	For Each SectionItem In Sections Do
		If SectionItem.Used Then
			ChoiceResult.Add(SectionItem.Section);
		EndIf;
	EndDo;
	
	NotifyChoice(ChoiceResult);
	
EndProcedure

#EndRegion
