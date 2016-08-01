// The following parameters are expected:
//
//     AreaToSearchForDuplicates - String - full name of the metadata table of the area selected for searching.
//     FilterAreaPresentation    - String - presentation for generating a title.
//     AppliedRuleDetails        - String, Undefined - text of the applied rules. Undefined means there are no rules.
//     SettingsAddress           - String - address of the temporary storage. The structure with the following fields 
//                                 are expected:
//                                 TakeAppliedRulesIntoAccount - Boolean - previous settings flag, the default value is True.
//                                 SearchRules     - ValueTable - setting to be edited. The following columns are
//                                                   expected:                                           
//                                                   Attribute             - String - Name of the attribute to be
//                                                                           compared.
//                                                   AttributePresentation - String - presentation of the attribute to 
//                                                                           be compared.
//                                                   Rule                  - String - selected comparison type: Equal
//                                                                           for matching by equality, Similar for 
//                                                                           matching by similarity, "" if you do not
//                                                                           want to use the rule.
//                                                   CompareOptions        - ValueList - available comparison types,
//                                                                           where the value is one of the rule options.
//
// Return value:
//     Undefined - cancel the editing.
//     String    - address of a temporary storage with new settings, specifies the structure similar to the
//                 SettingsAddress parameter.
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("SelfTest") Then
		Return;
	EndIf;
	
	Parameters.Property("AppliedRuleDetails", AppliedRuleDetails);
	AreaToSearchForDuplicates = Parameters.AreaToSearchForDuplicates;

	Title = StrReplace( NStr("en = 'Rules of searching for duplicates ""%1""'"), "%1", Parameters.FilterAreaPresentation);
	
	InitialSettings = GetFromTempStorage(Parameters.SettingsAddress);
	DeleteFromTempStorage(Parameters.SettingsAddress);
	InitialSettings.Property("TakeAppliedRulesIntoAccount", TakeAppliedRulesIntoAccount);
	
	If AppliedRuleDetails = Undefined Then
		// Rules are not defined
		Items.AppliedRestrictionGroup.Visible = False;
	Else
		Items.TakeAppliedRulesIntoAccount.Visible = CanCancelAppliedRules();
	EndIf;
	
	// Loading and adjusting rules
	SearchRules.Load(InitialSettings.SearchRules);
	For Each RuleRow In SearchRules Do
		RuleRow.Use = Not IsBlankString(RuleRow.Rule);
	EndDo;
	
	For Each Item In InitialSettings.AllCompareOptions Do
		If Not IsBlankString(Item.Value) Then
			FillPropertyValues(AllSearchRuleComparisonTypes.Add(), Item);
		EndIf;
	EndDo;
	
	SetColorsAndConditionalAppearance();
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ThisObject.RefreshDataRepresentation();
	
EndProcedure

#EndRegion

#Region FormsItemEventHandlers

&AtClient
Procedure TakeAppliedRulesIntoAccountOnChange(Item)
	
	If TakeAppliedRulesIntoAccount Then
		Return;
	EndIf;
	
	Details = New NotifyDescription("EndClearingUseAppliedRules", ThisObject);
	
	TitleText = NStr("en = 'Warning'");
	QueryText   = NStr("en = 'Attention: searching and deleting item duplicates without using supplied restrictions
	                            |can lead to mismatching of data in the application.
	                            |
	                            |Do you want to disable supplied restrictions?'");
	
	ShowQueryBox(Details, QueryText, QuestionDialogMode.YesNo,,DialogReturnCode.No, TitleText);
EndProcedure

#EndRegion

#Region SearchRulesTableEventHandlers

&AtClient
Procedure SearchRulesUseOnChange(Item)
	
	CurrentData = Items.SearchRules.CurrentData;
	
	If CurrentData.Use Then
		If IsBlankString(CurrentData.Rule) And CurrentData.CompareOptions.Count() > 0 Then
			CurrentData.Rule = CurrentData.CompareOptions[0].Value
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SearchRulesComparisonTypeStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	
	CurrentData = Items.SearchRules.CurrentData;
	ChoiceData = CurrentData.CompareOptions;
	
EndProcedure

&AtClient
Procedure SearchRulesComparisonTypeStartListChoice(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure SearchRulesComparisonTypeChoiceProcessing(Item, SelectedValue, StandardProcessing)
	StandardProcessing = False;
	
	CurrentData = Items.SearchRules.CurrentData;
	CurrentData.Use = True;
	CurrentData.Rule = SelectedValue;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Select(Command)
	
	SelectionErrorText = SelectionErrors();
	If SelectionErrorText <> Undefined Then
		ShowMessageBox(, SelectionErrorText);
		Return;
	EndIf;
	
	If Modified Then
		NotifyChoice( ChoiceResult() );
	Else
		Close();
	EndIf;
		
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtClient
Function SelectionErrors() 
	
	If AppliedRuleDetails <> Undefined And TakeAppliedRulesIntoAccount Then
		// There are applied rules and they are used. No errors.
		Return Undefined;
	EndIf;
	
	For Each RulesRow In SearchRules Do
		If RulesRow.Use Then
			// Custom rule is set. No errors.
			Return Undefined;
		EndIf;
	EndDo;
	
	Return NStr("en ='Specify at least one rule for searching for duplicates.'");
EndFunction

&AtClient
Procedure EndClearingUseAppliedRules(Val Answer, Val AdditionalParameters) Export
	If Answer = DialogReturnCode.Yes Then
		Return 
	EndIf;
	
	TakeAppliedRulesIntoAccount = True;
EndProcedure

&AtServerNoContext
Function CanCancelAppliedRules()
	
	Result = AccessRight("DataAdministration", Metadata);
	Return Result;
	
EndFunction

&AtServer
Function ChoiceResult()
	
	Result = New Structure;
	Result.Insert("TakeAppliedRulesIntoAccount", TakeAppliedRulesIntoAccount);
	
	SelectedRules = SearchRules.Unload();
	For Each RulesRow In SelectedRules  Do
		If Not RulesRow.Use Then
			RulesRow.Rule = "";
		EndIf;
	EndDo;
	SelectedRules.Columns.Delete("Use");
	
	Result.Insert("SearchRules", SelectedRules );
	
	Return PutToTempStorage(Result);
EndFunction

&AtServer
Procedure SetColorsAndConditionalAppearance()
	ConditionalAppearanceItems = ConditionalAppearance.Items;
	ConditionalAppearanceItems.Clear();
	
	ColorInaccessibleData = StyleColorOrAuto("ColorInaccessibleData", 192, 192, 192);
	
	For Each ListItem In AllSearchRuleComparisonTypes Do
		AppearanceItem = ConditionalAppearanceItems.Add();
		
		AppearanceFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		AppearanceFilter.LeftValue = New DataCompositionField("SearchRules.Rule");
		AppearanceFilter.ComparisonType = DataCompositionComparisonType.Equal;
		AppearanceFilter.RightValue = ListItem.Value;
		
		AppearanceField = AppearanceItem.Fields.Items.Add();
		AppearanceField.Field = New DataCompositionField("SearchRulesComparisonType");
		
		AppearanceItem.Appearance.SetParameterValue("Text", ListItem.Presentation);
	EndDo;
	
	// Do not use
	AppearanceItem = ConditionalAppearanceItems.Add();
	
	AppearanceFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	AppearanceFilter.LeftValue = New DataCompositionField("SearchRules.Use");
	AppearanceFilter.ComparisonType = DataCompositionComparisonType.Equal;
	AppearanceFilter.RightValue = False;
	
	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("SearchRulesComparisonType");
	
	AppearanceItem.Appearance.SetParameterValue("TextColor", ColorInaccessibleData);
EndProcedure

&AtServerNoContext
Function StyleColorOrAuto(Val Name, Val R = Undefined, G = Undefined, B = Undefined)

	StyleItem = Metadata.StyleItems.Find(Name);
	If StyleItem <> Undefined And StyleItem.Type = Metadata.ObjectProperties.StyleElementType.Color Then
		Return StyleColors[Name];
	EndIf;
	
	Return ?(R = Undefined, New Color, New Color(R, G, B));
EndFunction

#EndRegion