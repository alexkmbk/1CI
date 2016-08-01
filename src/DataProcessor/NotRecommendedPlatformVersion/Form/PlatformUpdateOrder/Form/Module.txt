
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skipping the initialization to guarantee that the form will be received if the SelfTest parameter is passed.	
	If Parameters.Property("SelfTest") Then 
		Return;
	EndIf;
	
	FileInfobase = CommonUse.FileInfobase();
	If FileInfobase Then
		UpdateOrderTemplate = DataProcessors.NotRecommendedPlatformVersion.GetTemplate("FileInfobaseUpdateOrder");
	Else
		UpdateOrderTemplate = DataProcessors.NotRecommendedPlatformVersion.GetTemplate("ClientServerInfobaseUpdateOrder");
	EndIf;
	
	ApplicationUpdateOrder = UpdateOrderTemplate.GetText();
	
EndProcedure

#EndRegion

#Region FormHeaderItemEventHandlers

&AtClient
Procedure ApplicationUpdateOrderOnClick(Item, EventData, StandardProcessing)
	If EventData.Href <> Undefined Then
		StandardProcessing = False;
		GotoURL(EventData.Href);
	EndIf;
EndProcedure

&AtClient
Procedure InstructionPrint(Command)
	Items.ApplicationUpdateOrder.Document.execCommand("Print");
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtClient
Procedure ApplicationUpdateOrderDocumentGenerated(Item)
	// Print command visibility
	If Not Item.Document.queryCommandSupported("Print") Then
		Items.InstructionPrint.Visible = False;
	EndIf;
EndProcedure

#EndRegion