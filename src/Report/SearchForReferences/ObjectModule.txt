#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	StandardProcessing = False;
	
	// Recreating the title by the reference set
	Settings = SettingsComposer.GetSettings();
	ReferenceSet = Settings.DataParameters.FindParameterValue( New DataCompositionParameter("ReferenceSet") );
	If ReferenceSet <> Undefined Then
		ReferenceSet = ReferenceSet.Value;
	EndIf;
	Title = TitleByReferenceSet(ReferenceSet);
	SettingsComposer.FixedSettings.OutputParameters.SetParameterValue("Title", Title);
	
	CompositionProcessor = CompositionProcessor(DetailsData);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	OutputProcessor.Output(CompositionProcessor);
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

Function CompositionProcessor(DetailsData = Undefined, GeneratorType = "DataCompositionTemplateGenerator")
	
	Settings = SettingsComposer.GetSettings();
	
	// Reference list from parameters
	ParameterValue = Settings.DataParameters.FindParameterValue( New DataCompositionParameter("ReferenceSet") ).Value;
	ValueType = TypeOf(ParameterValue);
	If ValueType = Type("ValueList") Then
		RefArray = ParameterValue.UnloadValues();
	ElsIf ValueType = Type("Array") Then
		RefArray = ParameterValue;
	Else
		RefArray = New Array;
		If ParameterValue <>Undefined Then
			RefArray.Add(ParameterValue);
		EndIf;
	EndIf;
	
	// Output parameters from fixed parameters
	For Each OutputParameter In SettingsComposer.FixedSettings.OutputParameters.Items Do
		If OutputParameter.Use Then
			Item = Settings.OutputParameters.FindParameterValue(OutputParameter.Parameter);
			If Item <> Undefined Then
				Item.Use  = True;
				Item.Value = OutputParameter.Value;
			EndIf;
		EndIf;
	EndDo;
	
	// Data source tables
	UsageInstances = CommonUse.UsageInstances(RefArray);
	
	// Checking whether we have all references 
	For Each Ref In RefArray Do
		If UsageInstances.Find(Ref, "Ref") = Undefined Then
			Advanced = UsageInstances.Add();
			Advanced.Ref = Ref;
			Advanced.AuxiliaryData = True;
		EndIf;
	EndDo;
		
	ExternalData = New Structure;
	ExternalData.Insert("UsageInstances", UsageInstances);
	
	// Performing
	TemplateComposer = New DataCompositionTemplateComposer;
	Template = TemplateComposer.Execute(DataCompositionSchema, Settings, DetailsData, , Type(GeneratorType));
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(Template, ExternalData, DetailsData);
	
	Return CompositionProcessor;
EndFunction

Function TitleByReferenceSet(Val ReferenceSet)
	Result = Undefined;
	
	If TypeOf(ReferenceSet) = Type("ValueList") Then
		ReferenceTotal = ReferenceSet.Count() - 1;
		If ReferenceTotal >= 0 Then
		
			EqualType = True;
			FirstRefType = TypeOf(ReferenceSet[0].Value);
			For Position = 0 to ReferenceTotal Do
				If TypeOf(ReferenceSet[Position].Value) <> FirstRefType Then
					EqualType = False;
					Break;
				EndIf;
			EndDo;
			
			If EqualType Then
				Result = StrReplace(NStr("en = 'Reference used at %1'"), "%1", 
					ReferenceSet[0].Value.Metadata().Presentation() );
			EndIf;
		EndIf;
	EndIf;
	
	If Result = Undefined Then
		Result = NStr("en = 'Items used at '");
	EndIf;
	
	Return Result;
EndFunction

#EndRegion

#EndIf