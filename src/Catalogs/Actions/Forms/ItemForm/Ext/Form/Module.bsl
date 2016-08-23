&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.PathToInternaldataProcessor.Visible = Object.IsInternal;
	Items.DataProcessor.Visible = not Object.IsInternal;
	
EndProcedure

&AtClient
Procedure IsInternalOnChange(Item)
	
	Items.PathToInternaldataProcessor.Visible = Object.IsInternal;
	Items.DataProcessor.Visible = not Object.IsInternal;

EndProcedure
 
&AtClient 
//
//
Procedure ItemChoose(Item, Params) Export 
	If Item <> Undefined Then
		Object.InternaldataProcessor = Item.Value;	
	EndIf; 	
EndProcedure
 
&AtClient
Procedure PathToInternaldataProcessorStartChoice(Item, ChoiceData, StandardProcessing)
 	
	List = RepositoryTasks.GetInternalDataProcessors();
	ND = new NotifyDescription("ItemChoose",ThisObject);
	List.ShowChooseItem(ND);
		
EndProcedure

