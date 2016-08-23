////////////////////////////////////////////////////////////////////////////////
//  Additional reports and data processors subsystem, 
//  procedures and functions with reusable return values.
// 
////////////////////////////////////////////////////////////////////////////////

#Region InternalProceduresAndFunctions

// Returns additional report or data processor availability options, which are available in the application.
Function AvaliablePublicationKinds() Export
	
	Result = New Array();
	
	Values = Metadata.Enums.AdditionalReportsAndDataProcessorsPublicationVariants.EnumValues;
	PublicationKindsToExclude = AdditionalReportsAndDataProcessors.UnavailablePublicationKinds();
	
	For Each Value In Values Do
		If PublicationKindsToExclude.Find(Value.Name) = Undefined Then
			Result.Add(Enums.AdditionalReportsAndDataProcessorsPublicationVariants[Value.Name]);
		EndIf;
	EndDo;
	
	Return New FixedArray(Result);
	
EndFunction

// Returns a publishing option to be used in the event of additional report or data processor conflict.
//
// Returns:
//     EnumRef.AdditionalReportsAndDataProcessorsPublicationVariants
//  
Function AllPublicationsForConflictingDataProcessors() Export
	
	KindDisabled = Enums.AdditionalReportsAndDataProcessorsPublicationVariants.Disabled;
	KindDebugMode = Enums.AdditionalReportsAndDataProcessorsPublicationVariants.DebugMode;
	
	AvaliableKinds = AvaliablePublicationKinds();
	If AvaliableKinds.Find(KindDebugMode) Then
		Return KindDebugMode;
	Else
		Return KindDisabled;
	EndIf;
	
EndFunction

// Returns the form settings for the assigned object.
Function AssignedObjectFormParameters(FullFormName, FormType = Undefined) Export
	If Not AccessRight("Read", Metadata.Catalogs.AdditionalReportsAndDataProcessors) Then
		Return "";
	EndIf;
	
	Result = New Structure("IsObjectForm, FormType, ParentRef, OutputObjectFillingSubmenu");
	
	FormMetadata = Metadata.FindByFullName(FullFormName);
	If FormMetadata = Undefined Then
		DotPosition = StrLen(FullFormName);
		While Mid(FullFormName, DotPosition, 1) <> "." Do
			DotPosition = DotPosition - 1;
		EndDo;
		ParentFullName = Left(FullFormName, DotPosition - 1);
		MetadataParent = Metadata.FindByFullName(ParentFullName);
	Else
		MetadataParent = FormMetadata.Parent();
	EndIf;
	If MetadataParent = Undefined Or TypeOf(MetadataParent) = Type("ConfigurationMetadataObject") Then
		Return "";
	EndIf;
	Result.ParentRef = CommonUse.MetadataObjectID(MetadataParent);
	
	If FormType <> Undefined Then
		If Upper(FormType) = Upper(AdditionalReportsAndDataProcessorsClientServer.ObjectFormType()) Then
			Result.IsObjectForm = True;
		ElsIf Upper(FormType) = Upper(AdditionalReportsAndDataProcessorsClientServer.ListFormType()) Then
			Result.IsObjectForm = False;
		Else
			Result.IsObjectForm = (MetadataParent.DefaultObjectForm = FormMetadata);
		EndIf;
	Else
		Result.IsObjectForm = (MetadataParent.DefaultObjectForm = FormMetadata);
	EndIf;
	
	If Result.IsObjectForm Then // Object form
		Result.FormType = AdditionalReportsAndDataProcessorsClientServer.ObjectFormType();
		ParentType = Type(StrReplace(MetadataParent.FullName(), ".", "Ref."));
		Result.OutputObjectFillingSubmenu = Metadata.CommonCommands.ObjectFilling.CommandParameterType.ContainsType(ParentType);
	Else // List form
		Result.FormType = AdditionalReportsAndDataProcessorsClientServer.ListFormType();
		Result.OutputObjectFillingSubmenu = False;
	EndIf;
	
	Return New FixedStructure(Result);
	
EndFunction

#EndRegion
