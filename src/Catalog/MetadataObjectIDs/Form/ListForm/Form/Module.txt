
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skipping the initialization to guarantee that the form will be received if the SelfTest parameter is passed.
	If Parameters.Property("SelfTest") Then 
		Return;
	EndIf;
	
	If Parameters.ChoiceMode Then
		PurposeUseKey = "SelectionPick";
		WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
		Items.List.ChoiceMode = True;
		Parameters.Filter.Insert("DeletionMark", False);
		Parameters.Filter.Insert("FutureDeletionMark", False);
	EndIf;
	
	Parameters.Property("ChooseMetadataObjectGroups", ChooseMetadataObjectGroups);
	
	SetListOrderAndAppearance();
	
EndProcedure

#EndRegion

#Region ListFormTableItemEventHandlers

&AtClient
Procedure ListValueChoice(Item, Value, StandardProcessing)
	
	If Not ChooseMetadataObjectGroups
	   And Item.CurrentData <> Undefined
	   And Not ValueIsFilled(Item.CurrentData.Parent) Then
		
		StandardProcessing = False;
		
		If Item.Representation = TableRepresentation.Tree Then
			If Item.Expanded(Item.CurrentRow) Then
				Item.Collapse(Item.CurrentRow);
			Else
				Item.Expand(Item.CurrentRow);
			EndIf;
			
		ElsIf Item.Representation = TableRepresentation.HierarchicalList Then
			
			If Item.CurrentParent <> Item.CurrentRow Then
				Item.CurrentParent = Item.CurrentRow;
			Else
				CurrentRow = Item.CurrentRow;
				Item.CurrentParent = Undefined;
				Item.CurrentRow = CurrentRow;
			EndIf;
		Else
			ShowMessageBox(,
				NStr("en = 'Metadata object group cannot be selected.
				           |Select metadata object.'"));
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure SetListOrderAndAppearance()
	
	// Order
	Order = List.SettingsComposer.Settings.Order;
	Order.UserSettingID = "DefaultOrder";
	
	Order.Items.Clear();
	
	OrderItem = Order.Items.Add(Type("DataCompositionOrderItem"));
	OrderItem.Field = New DataCompositionField("DeletionMark");
	OrderItem.OrderType = DataCompositionSortDirection.Desc;
	OrderItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	OrderItem.Use = True;
	
	OrderItem = Order.Items.Add(Type("DataCompositionOrderItem"));
	OrderItem.Field = New DataCompositionField("CollectionOrder");
	OrderItem.OrderType = DataCompositionSortDirection.Asc;
	OrderItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	OrderItem.Use = True;
	
	OrderItem = Order.Items.Add(Type("DataCompositionOrderItem"));
	OrderItem.Field = New DataCompositionField("Parent");
	OrderItem.OrderType = DataCompositionSortDirection.Asc;
	OrderItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	OrderItem.Use = True;
	
	OrderItem = Order.Items.Add(Type("DataCompositionOrderItem"));
	OrderItem.Field = New DataCompositionField("Synonym");
	OrderItem.OrderType = DataCompositionSortDirection.Asc;
	OrderItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	OrderItem.Use = True;
	
	// Appearance
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value = Metadata.StyleItems.InaccessibleDataColor.Value;
	AppearanceColorItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("RoleList.FutureDeletionMark");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = True;
	DataFilterItem.Use  = True;
	
	FieldAppearanceItem = ConditionalAppearanceItem.Fields.Items.Add();
	FieldAppearanceItem.Field = New DataCompositionField("Synonym");
	FieldAppearanceItem.Use = True;
	
	FieldAppearanceItem = ConditionalAppearanceItem.Fields.Items.Add();
	FieldAppearanceItem.Field = New DataCompositionField("FullName");
	FieldAppearanceItem.Use = True;
	
EndProcedure

#EndRegion
