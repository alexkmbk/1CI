&AtServer
Procedure SetFilter(Task) Export 
		List.Filter.Items.Clear();
		Item = List.Filter.Items.Add(Type("DataCompositionFilterItem"));
		Item.LeftValue = New DataCompositionField("Task");
		Item.ComparisonType = DataCompositionComparisonType.Equal;
		Item.Use = true;
		Item.RightValue = Task;	
EndProcedure
 
 
&AtClient
Procedure ListSelection(Item, SelectedRow, Field, StandardProcessing)
	ShowValue(,Item.CurrentData.Ref);
EndProcedure
