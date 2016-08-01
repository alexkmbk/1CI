// The following parameter is expected:
//
//     ReferenceSet - Array, ValueList - item set to be analyzed when the form
//                    is opening. It can be a collection of items with the
//                    Ref field. If there are items in the set, the report is
//                    generated automatically once the form is opened.
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("SelfTest") Then
		Return;
	EndIf;
	
	InitializeUserReportSettings(Parameters);
	
	// Passing to the form
	Parameters.UserSettings = Report.SettingsComposer.UserSettings;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	Representation = Items.Result.StatePresentation;
	Representation.Visible            = True;
	Representation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
	Representation.Picture            = PictureLib.LongAction48;
	Representation.Text               = NStr("en = 'The report is being generated...'");
	
	AttachIdleHandler("StartGeterating", 0.1, True);
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Generate(Command)
	
	StartGeterating();
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtClient
Procedure StartGeterating()
	
	ComposeResult(ResultCompositionMode.Background);
	
EndProcedure

// Initializes user settings of the composer by the passed parameters.
//
&AtServer
Procedure InitializeUserReportSettings(Val DataParameters)
	NewParameters = New Map;
	
	// ReferenceSet
	ReferenceSet = New ValueList;
	If DataParameters.Property("ReferenceSet") Then
		CurrentParameter = DataParameters.ReferenceSet;
		
		ParameterType = TypeOf(CurrentParameter);
		If ParameterType = Type("Array") Then
			ReferenceSet.LoadValues(CurrentParameter);
			
		ElsIf ParameterType = Type("ValueList") Then
			ReferenceSet.LoadValues(CurrentParameter.UnloadValues());
			
		Else
			IsOrdinalType = False;
			Try
				// Ordinal type
				For Each Item In CurrentParameter Do
					IsOrdinalType = True;
					Break;
				EndDo;
			Except
				IsOrdinalType = False;
			EndTry;
			
			If IsOrdinalType Then
				For Each Item In CurrentParameter Do
					ReferenceSet.Add(Item.Ref);
				EndDo;
			EndIf;
		EndIf;
		
		NewParameters.Insert(New DataCompositionParameter("ReferenceSet"), ReferenceSet);
	EndIf;
	
	// Passing to user fields
	For Each Item In Report.SettingsComposer.UserSettings.Items Do
		Value = NewParameters[Item.Parameter];
		If Value<>Undefined Then
			Item.Use   = True;
			Item.Value = Value;
		EndIf;
	EndDo;
EndProcedure

#EndRegion
