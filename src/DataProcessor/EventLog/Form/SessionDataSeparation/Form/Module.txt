#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	// Skipping the initialization to guarantee that the form will be received if the SelfTest parameter is passed.
	If Parameters.Property("SelfTest") Then 
		Return;
	EndIf;
	
	SetFilter = Parameters.SetFilter;
	DataSeparationMap = New Map;
	If SetFilter.Count() > 0 Then
		
		For Each SessionSeparator In SetFilter Do
			DataSeparationArray = StringFunctionsClientServer.SplitStringIntoSubstringArray(SessionSeparator.Value, "=");
			DataSeparationMap.Insert(DataSeparationArray[0], DataSeparationArray[1]);
		EndDo;
		
	EndIf;
	
	For Each CommonAttribute In Metadata.CommonAttributes Do
		TableRow = SessionDataSeparation.Add();
		TableRow.Separator = CommonAttribute.Name;
		TableRow.SeparatorPresentation = CommonAttribute.Synonym;
		SeparatorValue = DataSeparationMap[CommonAttribute.Name];
		If SeparatorValue <> Undefined Then
			TableRow.Check = True;
			TableRow.SeparatorValue = DataSeparationMap[CommonAttribute.Name];
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OKCommand(Command)
	Result = New ValueList;
	For Each TableRow In SessionDataSeparation Do
		If TableRow.Check Then
			SeparatorValue = TableRow.Separator + "=" + TableRow.SeparatorValue;
			SeparatorPresentation = TableRow.SeparatorPresentation + " = " + TableRow.SeparatorValue;
			Result.Add(SeparatorValue, SeparatorPresentation);
		EndIf;
	EndDo;
	
	Notify("EventLogFilterItemValueChoice",
		Result,
		FormOwner);
	
	Close();
EndProcedure

&AtClient
Procedure CheckAll(Command)
	For Each ListItem In SessionDataSeparation Do
		ListItem.Check = True;
	EndDo;
EndProcedure

&AtClient
Procedure UncheckAll(Command)
	For Each ListItem In SessionDataSeparation Do
		ListItem.Check = False;
	EndDo;
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	Close();
EndProcedure

#EndRegion