
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	Events.Filter.Items.Clear();
	Item = Events.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Item.LeftValue = New DataCompositionField("TaskRunningEvent");
	Item.ComparisonType = DataCompositionComparisonType.Equal;
	Item.Use = true;
	Item.RightValue = Object.Ref;

EndProcedure
