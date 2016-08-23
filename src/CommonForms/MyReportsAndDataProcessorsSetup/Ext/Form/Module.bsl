
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("Autotest") Then
		Return;
	EndIf;
	
	FillPropertyValues(ThisObject, Parameters, "DataProcessorKind, AreGlobalDataProcessors, CurrentSection");
	
	FillDataProcessorTree(True, "MyCommands");
	FillDataProcessorTree(False, "CommandsSource");
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	QuestionText = NStr("en = 'The list of displayed commands is changed.
	|Do you want to save the changes?'");
	Handler = New NotifyDescription("SaveAndNotifyAboutChoice", ThisObject);
	CommonUseClient.ShowFormClosingConfirmation(Handler, Cancel, QuestionText);
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure AddCommand(Command)
	
	CurrentData = Items.CommandsSource.CurrentData;
	
	If CurrentData <> Undefined And Not IsBlankString(CurrentData.ID) Then
		AddCommandServer(CurrentData.DataProcessor, CurrentData.ID);
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteCommand(Command)
	
	CurrentData = Items.MyCommands.CurrentData;
	
	If CurrentData <> Undefined And Not IsBlankString(CurrentData.ID) Then
		DeleteCommandServer(CurrentData.DataProcessor, CurrentData.ID);
	EndIf;
	
EndProcedure

&AtClient
Procedure AddAllCommands(Command)
	
	If AreGlobalDataProcessors Then
		CommandsSourceItems = CommandsSource.GetItems();
		
		For Each RowSections In CommandsSourceItems Do
			SectionItem = FindSectionItem(MyCommands, RowSections.Section, RowSections.Description);
			CommandItems = RowSections.GetItems();
			For Each ItemCommand In CommandItems Do
				NewCommand = FindItemCommand(SectionItem.GetItems(), ItemCommand.ID);
				FillPropertyValues(NewCommand, ItemCommand);
			EndDo;
		EndDo;
	Else
		AddAllCommandsServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteAllCommands(Command)
	
	MyCommands.GetItems().Clear();
	
EndProcedure

&AtClient
Procedure OK(Command)
	WriteUserDataProcessorSet();
	NotifyChoice("MyReportsAndDataProcessorsSetupDone");
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtClient
Procedure SaveAndNotifyAboutChoice(Result, AdditionalParameters) Export
	
	WriteUserDataProcessorSet();
	NotifyChoice("MyReportsAndDataProcessorsSetupDone");
	
EndProcedure

&AtServer
Function FillDataProcessorTree(UserCommands, TreeAttributeItemName)
	
	Query = New Query;
	
	QueryText = 
	"SELECT
	|	AdditReportsAndDataProcessors.Ref AS DataProcessor,
	|	CommandsTable.Presentation AS Description,
	|	SectionsTable.Section AS Section,
	|	CommandsTable.ID AS ID
	|FROM
	|	Catalog.AdditionalReportsAndDataProcessors AS AdditReportsAndDataProcessors
	|		INNER JOIN Catalog.AdditionalReportsAndDataProcessors.Commands AS CommandsTable
	|		ON AdditReportsAndDataProcessors.Ref = CommandsTable.Ref
	|		INNER JOIN Catalog.AdditionalReportsAndDataProcessors.Sections AS SectionsTable
	|		ON AdditReportsAndDataProcessors.Ref = SectionsTable.Ref
	|		LEFT JOIN InformationRegister.DataProcessorAccessUserSettings AS QuickAccess
	|		ON AdditReportsAndDataProcessors.Ref = QuickAccess.AdditionalReportOrDataProcessor
	|			AND (QuickAccess.CommandID = CommandsTable.ID)
	|			AND (QuickAccess.User = &User)
	|WHERE
	|	AdditReportsAndDataProcessors.Kind = &DataProcessorKind
	|	AND NOT AdditReportsAndDataProcessors.DeletionMark
	|	AND AdditReportsAndDataProcessors.Publication IN(&PublicationVariants)
	|	AND QuickAccess.Available
	|TOTALS BY
	|	&TotalsBySection";
	
	If AreGlobalDataProcessors Then
		QueryText = StrReplace(QueryText, "&TotalsBySection", "Section");
	Else
		QueryText = StrReplace(QueryText, "AdditionalReportsAndDataProcessorsSections.Section AS Section,", "");
		QueryText = StrReplace(QueryText, "INNER JOIN Catalog.AdditionalReportsAndDataProcessors.Sections AS SectionsTable", "");
		QueryText = StrReplace(QueryText, "ON AdditReportsAndDataProcessors.Ref = SectionsTable.Ref", "");
		QueryText = StrReplace(QueryText, "TOTALS BY", "");
		QueryText = StrReplace(QueryText, "&TotalsBySection", "");
	EndIf;
	
	If Not UserCommands Then
		QueryText = StrReplace(QueryText, "LEFT JOIN InformationRegister.DataProcessorAccessUserSettings AS QuickAccess", "");
		QueryText = StrReplace(QueryText, "ON AdditReportsAndDataProcessors.Ref = QuickAccess.AdditionalReportOrDataProcessor", "");
		QueryText = StrReplace(QueryText, "AND (QuickAccess.CommandID = CommandsTable.ID)", "");
		QueryText = StrReplace(QueryText, "AND (QuickAccess.User = &User)", "");
		QueryText = StrReplace(QueryText, "AND QuickAccess.Available", "");
	EndIf;
	
	PublicationVariants = New Array;
	PublicationVariants.Add(Enums.AdditionalReportsAndDataProcessorsPublicationVariants.Used);
	If Users.RolesAvailable("AddEditAdditionalReportsAndDataProcessors") Then
		PublicationVariants.Add(Enums.AdditionalReportsAndDataProcessorsPublicationVariants.DebugMode);
	EndIf;
	
	Query.SetParameter("User", Users.CurrentUser());
	Query.SetParameter("PublicationVariants", PublicationVariants);
	Query.SetParameter("DataProcessorKind", DataProcessorKind);
	
	Query.Text = QueryText;
	
	If AreGlobalDataProcessors Then
		CommandTree = Query.Execute().Unload(QueryResultIteration.ByGroups);
	Else
		CommandTable = Query.Execute().Unload();
	EndIf;
	
	CommandsTree = FormAttributeToValue(TreeAttributeItemName);
	CommandsTree.Rows.Clear();
	
	OwnIndex = 0;
	Index = 0;
	
	If AreGlobalDataProcessors Then
		For Each RowSections In CommandTree.Rows Do
			UpperLevelRow = CommandsTree.Rows.Add();
			UpperLevelRow.Section = RowSections.Section;
			UpperLevelRow.Description = AdditionalReportsAndDataProcessors.SectionPresentation(RowSections.Section);
			If UpperLevelRow.Section = CurrentSection Then
				OwnIndex = Index;
			EndIf;
			For Each CommandString In RowSections.Rows Do
				CommandDescriptionRow = UpperLevelRow.Rows.Add();
				FillPropertyValues(CommandDescriptionRow, CommandString);
				Index = Index + 1;
			EndDo;
			Index = Index + 1;
		EndDo;
	Else
		For Each ItemCommand In CommandTable Do
			NewRow = CommandsTree.Rows.Add();
			FillPropertyValues(NewRow, ItemCommand);
		EndDo;
	EndIf;
	
	ValueToFormAttribute(CommandsTree, TreeAttributeItemName);
	
	Items[TreeAttributeItemName].CurrentRow = OwnIndex;
	
EndFunction

&AtServer
Procedure AddCommandServer(DataProcessor, ID)
	
	MyCommandTree = FormAttributeToValue("MyCommands");
	FoundRows = MyCommandTree.Rows.FindRows(New Structure("DataProcessor, ID", DataProcessor, ID), True);
	If FoundRows.Count() > 0 Then
		Return;
	EndIf;
	
	CommandsSourceTree = FormAttributeToValue("CommandsSource");
	FoundRows = CommandsSourceTree.Rows.FindRows(New Structure("DataProcessor, ID", DataProcessor, ID), True);
		
	If AreGlobalDataProcessors Then	
		For Each FoundRow In FoundRows Do
			SectionItem = FindSectionItem(MyCommands, FoundRow.Section, FoundRow.Parent.Description);
			NewCommand = SectionItem.GetItems().Add();
			FillPropertyValues(NewCommand, FoundRow);
		EndDo;
	Else
		NewCommand = MyCommands.GetItems().Add();
		FillPropertyValues(NewCommand, FoundRows[0]);
	EndIf;
	
EndProcedure

&AtServer
Procedure AddAllCommandsServer()
	
	ValueToFormAttribute(FormAttributeToValue("CommandsSource"), "MyCommands");
	
EndProcedure

&AtServer
Procedure DeleteCommandServer(DataProcessor, ID)
	
	MyCommandsItems = MyCommands.GetItems();
	
	If AreGlobalDataProcessors Then
		
		SectionsToDelete = New Array;
		
		For Each RowSections In MyCommandsItems Do
			CommandItems = RowSections.GetItems();
			For Each CommandString In CommandItems Do
				If CommandString.DataProcessor= DataProcessor And CommandString.ID = ID Then
					CommandItems.Delete(CommandItems.IndexOf(CommandString));
					Break;
				EndIf;
			EndDo;
			If CommandItems.Count() = 0 Then
				SectionsToDelete.Add(MyCommandsItems.IndexOf(RowSections));
			EndIf;
		EndDo;
		
		SectionsToDeleteTable = New ValueTable;
		SectionsToDeleteTable.Columns.Add("Section", New TypeDescription("Number",New NumberQualifiers(10)));
		For Each SectionToDelete In SectionsToDelete Do
			Row = SectionsToDeleteTable.Add();
			Row.Section = SectionToDelete;
		EndDo;
		SectionsToDeleteTable.GroupBy("Section");
		SectionsToDeleteTable.Sort("Section Desc");
		
		SectionsToDelete = SectionsToDeleteTable.UnloadColumn("Section");
		
		For Each SectionToDelete In SectionsToDelete Do
			MyCommandsItems.Delete(SectionToDelete);
		EndDo;
		
	Else
		
		For Each CommandString In MyCommandsItems Do
			If CommandString.DataProcessor = DataProcessor And CommandString.ID = ID Then
				MyCommandsItems.Delete(MyCommandsItems.IndexOf(CommandString));
				Break;
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function FindSectionItem(FormDataCommand, Section, Description)
	
	Result = Undefined;
	
	For Each DataItem In FormDataCommand.GetItems() Do
		If DataItem.Section = Section Then
			Result = DataItem;
			Break;
		EndIf;
	EndDo;
	
	If Result = Undefined Then
		NewSection = FormDataCommand.GetItems().Add();
		NewSection.Section = Section;
		NewSection.Description = Description;
		Result = NewSection;
	EndIf;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function FindItemCommand(FormDataTreeItemCollection, ID)
	
	Result = Undefined;
	
	For Each DataItem In FormDataTreeItemCollection Do
		If DataItem.ID = ID Then
			Result = DataItem;
			Break;
		EndIf;
	EndDo;
	
	If Result = Undefined Then
		NewSection = FormDataTreeItemCollection.Add();
		Result = NewSection;
	EndIf;
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// DataProcessorAccessUserSettings register operations

&AtServer
Procedure WriteUserDataProcessorSet()
	
	QueryText = "
			|SELECT
			|	AdditionalReportsAndDataProcessorsCommands.ID AS ID,
			|	AdditionalReportsAndDataProcessors.Ref				 AS DataProcessor
			|FROM
			|	Catalog.AdditionalReportsAndDataProcessors AS AdditionalReportsAndDataProcessors
			|	JOIN Catalog.AdditionalReportsAndDataProcessors.Commands AS AdditionalReportsAndDataProcessorsCommands
			|			ON AdditionalReportsAndDataProcessorsCommands.Ref = AdditionalReportsAndDataProcessors.Ref
			|WHERE
			|	AdditionalReportsAndDataProcessors.Kind = &DataProcessorKind";
	
	Query = New Query;
	Query.Parameters.Insert("DataProcessorKind", DataProcessorKind);
	Query.Text = QueryText;
	
	DataProcessorTable = Query.Execute().Unload();
	
	MyCommandTree = FormAttributeToValue("MyCommands");
	
	MyCommandTable = GetTable();
	
	If AreGlobalDataProcessors Then
		For Each RowSections In MyCommandTree.Rows Do
			For Each CommandString In RowSections.Rows Do
				NewRow = MyCommandTable.Add();
				FillPropertyValues(NewRow, CommandString);
			EndDo;
		EndDo;
	Else
		For Each CommandString In MyCommandTree.Rows Do
			NewRow = MyCommandTable.Add();
			FillPropertyValues(NewRow, CommandString);
		EndDo;
	EndIf;
	
	MyCommandTable.GroupBy("DataProcessor, ID");
	
 
	
	TableToCompare = DataProcessorTable.Copy();
	TableToCompare.Columns.Add("Flag", New TypeDescription("Number", New NumberQualifiers(1)));
	For Each Row In TableToCompare Do
		Row.Flag = -1;
	EndDo;
	
	For Each Row In MyCommandTable Do
		NewRow = TableToCompare.Add();
		FillPropertyValues(NewRow, Row);
		NewRow.Flag = +1;
	EndDo;
	
	TableToCompare.GroupBy("DataProcessor, ID", "Flag");
	
	RowsToExceptFromOwnedCommandList = TableToCompare.FindRows(New Structure("Flag", -1));
	RowsToAddToOwnedCommandList = TableToCompare.FindRows(New Structure("Flag", 0));
	
	BeginTransaction();
	
	Try
		AdditionalReportsAndDataProcessors.RemoveCommandsFormOwnedCommandList(RowsToExceptFromOwnedCommandList);
		AdditionalReportsAndDataProcessors.AddCommandToOwnedCommandList(RowsToAddToOwnedCommandList);
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Modified = False;
EndProcedure

&AtServerNoContext
Function GetTable()
	
	CommandTable = New ValueTable;
	CommandTable.Columns.Add("DataProcessor", New TypeDescription("CatalogRef.AdditionalReportsAndDataProcessors"));
	CommandTable.Columns.Add("ID", New TypeDescription("String"));
	
	Return CommandTable;
	
EndFunction

#EndRegion
