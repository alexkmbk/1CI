// The following parameter is expected:
//
//     AreaToSearchForDuplicates - String - full metadata table name of the area
//                                 selected for search. 
//
// Returns:
//
//     Undefined - to cancel editing.
//     String    - address of the temporary storage with new composer settings. 
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("SelfTest") Then
		Return;
	EndIf;
	
	Parameters.Property("AreaToSearchForDuplicates", DefaultArea);
	
	InitializeAreasToSearchForDuplicatesList();
EndProcedure

#EndRegion

#Region FormHeaderItemEventHandlers

&AtClient
Procedure AreasToSearchForDuplicatesSelection(Item, SelectedRow, Field, StandardProcessing)
	
	MakeSelection(SelectedRow);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Select(Command)
	
	MakeSelection(Items.AreasToSearchForDuplicates.CurrentRow);
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtClient
Procedure MakeSelection(Val RowID)
	
	Item = AreasToSearchForDuplicates.FindByID(RowID);
	If Item = Undefined Then
		Return;
		
	ElsIf Item.Value = DefaultArea Then
		// No changes
		Close();
		Return;
		
	EndIf;
	
	NotifyChoice(Item.Value);
EndProcedure

&AtServer
Procedure InitializeAreasToSearchForDuplicatesList()
	
	DataProcessorObject = FormAttributeToValue("Object");
	DataProcessorObject.AreasToSearchForDuplicates(AreasToSearchForDuplicates);
	
	AreasToSearchForDuplicates.SortByPresentation();
	Item = AreasToSearchForDuplicates.FindByValue(DefaultArea);
	If Item<>Undefined Then
		Items.AreasToSearchForDuplicates.CurrentRow = Item.GetID();
	EndIf;
	
EndProcedure


#EndRegion