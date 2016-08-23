#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region InternalProceduresAndFunctions

// Collects catalog data by metadata object references and updates register data.
//
Procedure UpdateDataByMetadataObjectReferences(MetadataObjectReferences) Export
	Query = NewRegisterDataUpdateQuery(MetadataObjectReferences);
	
	ReferenceSelection = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	While ReferenceSelection.Next() Do
		RecordSelection = ReferenceSelection.Select();
		While RecordSelection.Next() Do
			RecordManager = CreateRecordManager();
			FillPropertyValues(RecordManager, RecordSelection);
			RecordManager.Write(True);
		EndDo;
		
		// Registering used references for further clearing of the register from unused references.
		MetadataObjectReferences.Delete(MetadataObjectReferences.Find(ReferenceSelection.TargetObject));
	EndDo;
	
	// Clearing register from unused references.
	For Each TargetObject In MetadataObjectReferences Do
		RecordSet = CreateRecordSet();
		RecordSet.Filter.TargetObject.Set(TargetObject);
		RecordSet.Write(True);
	EndDo;
EndProcedure

// Overwriting all register data.
//
Procedure Refresh(InfobaseUpdateMode = False) Export
	
	Query = NewRegisterDataUpdateQuery(Undefined);
	ReferenceSelection = Query.Execute().Select(QueryResultIteration.ByGroups);
	RecordSet = CreateRecordSet();
	While ReferenceSelection.Next() Do
		RecordSelection = ReferenceSelection.Select();
		While RecordSelection.Next() Do
			FillPropertyValues(RecordSet.Add(), RecordSelection);
		EndDo;
	EndDo;
	
	If InfobaseUpdateMode Then
		InfobaseUpdate.WriteData(RecordSet);
	Else
		RecordSet.Write();
	EndIf;
	
EndProcedure

// Returns a query text, which is used to update register data.
//
Function NewRegisterDataUpdateQuery(MetadataObjectReferences)
	
	Query = New Query;
	
	QueryText =
	"SELECT DISTINCT
	|	AdditionalReportsAndDataProcessorsPurpose.TargetObject AS TargetObject,
	|	CASE
	|		WHEN AdditionalReportsAndDataProcessorsPurpose.Ref.Kind = &KindObjectFilling
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS UseObjectFilling,
	|	CASE
	|		WHEN AdditionalReportsAndDataProcessorsPurpose.Ref.Kind = &ReportKind
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS UseReports,
	|	CASE
	|		WHEN AdditionalReportsAndDataProcessorsPurpose.Ref.Kind = &KindPrintForm
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS UsePrintForms,
	|	CASE
	|		WHEN AdditionalReportsAndDataProcessorsPurpose.Ref.Kind = &KindRelatedObjectCreating
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS UseRelatedObjectCreation,
	|	AdditionalReportsAndDataProcessorsPurpose.Ref.UseForObjectForm,
	|	AdditionalReportsAndDataProcessorsPurpose.Ref.UseForListForm
	|INTO ttPrimaryData
	|FROM
	|	Catalog.AdditionalReportsAndDataProcessors.Purpose AS AdditionalReportsAndDataProcessorsPurpose
	|WHERE
	|	AdditionalReportsAndDataProcessorsPurpose.TargetObject IN(&MetadataObjectReferences)
	|	AND AdditionalReportsAndDataProcessorsPurpose.Ref.Publication <> &PublicationNotEqual
	|	AND AdditionalReportsAndDataProcessorsPurpose.Ref.DeletionMark = FALSE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ObjectForms.TargetObject,
	|	FALSE AS UseObjectFilling,
	|	ObjectForms.UseReports,
	|	ObjectForms.UsePrintForms,
	|	ObjectForms.UseRelatedObjectCreation,
	|	&ObjectFormType AS FormType
	|INTO ttResult
	|FROM
	|	ttPrimaryData AS ObjectForms
	|WHERE
	|	ObjectForms.UseForObjectForm = TRUE
	|
	|UNION ALL
	|
	|SELECT
	|	DisabledObjectForms.TargetObject,
	|	FALSE,
	|	FALSE,
	|	FALSE,
	|	FALSE,
	|	&ObjectFormType
	|FROM
	|	ttPrimaryData AS DisabledObjectForms
	|WHERE
	|	DisabledObjectForms.UseForObjectForm = FALSE
	|
	|UNION ALL
	|
	|SELECT
	|	ListForms.TargetObject,
	|	ListForms.UseObjectFilling,
	|	ListForms.UseReports,
	|	ListForms.UsePrintForms,
	|	ListForms.UseRelatedObjectCreation,
	|	&ListFormType
	|FROM
	|	ttPrimaryData AS ListForms
	|WHERE
	|	ListForms.UseForListForm = TRUE
	|
	|UNION ALL
	|
	|SELECT
	|	DisabledListForms.TargetObject,
	|	FALSE,
	|	FALSE,
	|	FALSE,
	|	FALSE,
	|	&ListFormType
	|FROM
	|	ttPrimaryData AS DisabledListForms
	|WHERE
	|	DisabledListForms.UseForListForm = FALSE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	tabResult.TargetObject AS TargetObject,
	|	tabResult.FormType,
	|	MAX(tabResult.UseObjectFilling) AS UseObjectFilling,
	|	MAX(tabResult.UseReports) AS UseReports,
	|	MAX(tabResult.UsePrintForms) AS UsePrintForms,
	|	MAX(tabResult.UseRelatedObjectCreation) AS UseRelatedObjectCreation
	|FROM
	|	ttResult AS tabResult
	|
	|GROUP BY
	|	tabResult.TargetObject,
	|	tabResult.FormType
	|TOTALS BY
	|	TargetObject";
	
	If MetadataObjectReferences = Undefined Then
		QueryText = StrReplace(
			QueryText,
			"AdditionalReportsAndDataProcessorsPurpose.TargetObject IN(&MetadataObjectReferences)
 			| AND ",
			"");
	Else
		Query.SetParameter("MetadataObjectReferences", MetadataObjectReferences);
	EndIf;
	
	Query.SetParameter("PublicationNotEqual",       Enums.AdditionalReportsAndDataProcessorsPublicationVariants.Disabled);
	Query.SetParameter("KindObjectFilling",         Enums.AdditionalReportAndDataProcessorKinds.ObjectFilling);
	Query.SetParameter("ReportKind",                Enums.AdditionalReportAndDataProcessorKinds.Report);
	Query.SetParameter("KindPrintForm",             Enums.AdditionalReportAndDataProcessorKinds.PrintForm);
	Query.SetParameter("KindRelatedObjectCreating", Enums.AdditionalReportAndDataProcessorKinds.RelatedObjectCreation);
	Query.SetParameter("ListFormType",   AdditionalReportsAndDataProcessorsClientServer.ListFormType());
	Query.SetParameter("ObjectFormType", AdditionalReportsAndDataProcessorsClientServer.ObjectFormType());
	Query.Text = QueryText;
	
	Return Query;

#EndRegion
EndFunction
#EndIf
