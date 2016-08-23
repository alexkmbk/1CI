
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
// Skipping the initialization to guarantee that the form will be received if the Autotest parameter is passed.
	If Parameters.Property("Autotest") Then 
		Return;
	EndIf;
	
	UserRef = Parameters.User;
	SettingsOperations = Parameters.SettingsOperations;
	InfobaseUser = DataProcessors.ApplicationUserSettings.InfobaseUserName(UserRef);
	CurrentUserRef = Users.CurrentUser();
	CurrentUser = DataProcessors.ApplicationUserSettings.InfobaseUserName(CurrentUserRef);
	
	SelectedSettingsPage = Items.SettingsKinds.CurrentPage.Name;
	
	PersonalSettingsFormName = CommonUse.CommonBaseFunctionalityParameters(
		).PersonalSettingsFormName;
	
	FillSettingsLists(False);
	
EndProcedure

&AtClient
Procedure OnClose()
	
	If DataInSettingsStorageSaved Then
		Notify("SelectSettings_DataSaved");
	EndIf;
	
EndProcedure

&AtServer
Procedure OnSaveDataInSettingsAtServer(Settings)
	
	Settings.Insert("SearchChoiceList", Items.Search.ChoiceList.UnloadValues());
	
	Settings.Delete("Appearance");
	Settings.Delete("ReportSettings");
	Settings.Delete("OtherSettings");
	
	ReportSettingsTree = FormAttributeToValue("ReportSettings");
	AppearanceTree = FormAttributeToValue("Appearance");
	OtherSettingsTree = FormAttributeToValue("OtherSettings");
	
	MarkedReportSettings = MarkedSettings(ReportSettingsTree);
	MarkedAppearanceSettings = MarkedSettings(AppearanceTree);
	MarkedOtherSettings = MarkedSettings(OtherSettingsTree);
	
	Settings.Insert("MarkedReportSettings", MarkedReportSettings);
	Settings.Insert("MarkedAppearanceSettings", MarkedAppearanceSettings);
	Settings.Insert("MarkedOtherSettings", MarkedOtherSettings);
	
	DataInSettingsStorageSaved = True;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If Parameters.ClearSettingsSelectionHistory Then
		Settings.Clear();
		Return;
	EndIf;
	
	SearchChoiceList = Settings.Get("SearchChoiceList");
	If TypeOf(SearchChoiceList) = Type("Array") Then
		Items.Search.ChoiceList.LoadValues(SearchChoiceList);
	EndIf;
	Search = "";
	
	MarkedReportSettings = Settings.Get("MarkedReportSettings");
	MarkedAppearanceSettings = Settings.Get("MarkedAppearanceSettings");
	MarkedOtherSettings = Settings.Get("MarkedOtherSettings");
	
	ImportMarkValues(ReportSettings, MarkedReportSettings, "ReportSettings");
	ImportMarkValues(Appearance, MarkedAppearanceSettings, "Appearance");
	ImportMarkValues(OtherSettings, MarkedOtherSettings, "OtherSettings");
	
EndProcedure

#EndRegion

#Region FormHeaderItemEventHandlers

&AtClient
Procedure OnCurrentPageChange(Item, CurrentPage)
	
	SelectedSettingsPage = CurrentPage.Name;
	
EndProcedure

&AtClient
Procedure SearchOnChange(Item)
	
	If ValueIsFilled(Search) Then
		ChoiceList = Items.Search.ChoiceList;
		ListItem = ChoiceList.FindByValue(Search);
		If ListItem = Undefined Then
			ChoiceList.Insert(0, Search);
			If ChoiceList.Count() > 10 Then
				ChoiceList.Delete(10);
			EndIf;
		Else
			Index = ChoiceList.IndexOf(ListItem);
			If Index <> 0 Then
				ChoiceList.Move(Index, -Index);
			EndIf;
		EndIf;
		CurrentItem = Items.Search;
	EndIf;
	
	FillSettingsLists(True);
	ExpandValueTree();
	
EndProcedure

&AtClient
Procedure SettingsTreeChoice(Item, SelectedRow, Field, StandardProcessing)
	
	StandardProcessing = False;
	UsersInternalClient.OpenReportOrForm(
		CurrentItem, InfobaseUser, CurrentUser, PersonalSettingsFormName);
	
EndProcedure

&AtClient
Procedure CheckOnChange(Item)
	
	ChangeMark(Item);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Refresh(Command)
	
	FillSettingsLists(False);
	ExpandValueTree();
	
EndProcedure

&AtClient
Procedure OpenSettingsItem(Command)
	
	UsersInternalClient.OpenReportOrForm(
		CurrentItem, InfobaseUser, CurrentUser, PersonalSettingsFormName);
	
EndProcedure

&AtClient
Procedure MarkAll(Command)
	
	If SelectedSettingsPage = "ReportSettingsPage" Then
		SettingsTree = ReportSettings.GetItems();
		MarkTreeItems(SettingsTree, True);
	ElsIf SelectedSettingsPage = "AppearancePage" Then
		SettingsTree = Appearance.GetItems();
		MarkTreeItems(SettingsTree, True);
	Else
		SettingsTree = OtherSettings.GetItems();
		MarkTreeItems(SettingsTree, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearAllMarks(Command)
	
	If SelectedSettingsPage = "ReportSettingsPage" Then
		SettingsTree = ReportSettings.GetItems();
		MarkTreeItems(SettingsTree, False);
	ElsIf SelectedSettingsPage = "AppearancePage" Then
		SettingsTree = Appearance.GetItems();
		MarkTreeItems(SettingsTree, False);
	Else
		SettingsTree = OtherSettings.GetItems();
		MarkTreeItems(SettingsTree, False);
	EndIf;
	
EndProcedure

&AtClient
Procedure Select(Command)
	
	Result = New Structure();
	SelectedReportSettings = SelectedSettings(ReportSettings);
	SelectedAppearanceSettings = SelectedSettings(Appearance);
	OtherSettingsStructure = SelectedSettings(OtherSettings);
	SettingsCount = SelectedReportSettings.SettingsCount +
		SelectedAppearanceSettings.SettingsCount + OtherSettingsStructure.SettingsCount;
		
	If SelectedReportSettings.SettingsCount = 1 Then
		SettingsPresentation = SelectedReportSettings.SettingsPresentation;
	ElsIf SelectedAppearanceSettings.SettingsCount = 1 Then
		SettingsPresentation = SelectedAppearanceSettings.SettingsPresentation;
	ElsIf  OtherSettingsStructure.SettingsCount = 1 Then
		SettingsPresentation = OtherSettingsStructure.SettingsPresentation;
	EndIf;
	
	Result.Insert("ReportSettings", SelectedReportSettings.SettingsArray);
	Result.Insert("Appearance", SelectedAppearanceSettings.SettingsArray);
	Result.Insert("OtherSettings", OtherSettingsStructure.SettingsArray);
	Result.Insert("SettingsPresentation", SettingsPresentation);
	Result.Insert("PersonalSettings", OtherSettingsStructure.PersonalSettingsArray);
	Result.Insert("SettingsCount", SettingsCount);
	Result.Insert("ReportOptionTable", UserReportOptionTable);
	Result.Insert("SelectedReportOptions", SelectedReportSettings.ReportOptions);
	Result.Insert("OtherUserSettings",
		OtherSettingsStructure.OtherUserSettings);
	
	Notify("SelectSettings", Result);
	Close();
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions related to displaying settings to user

&AtServer
Procedure FillSettingsLists(SettingsSearch)
	
	If SettingsSearch Then
		
		MarkedTreeItems();
		
	EndIf;
	
	DataProcessors.ApplicationUserSettings.FillSettingsLists(ThisObject);
	
	If SettingsSearch Then
		
		ImportMarkValues(ReportSettings, AllSelectedSettings.MarkedReportSettings, "ReportSettings");
		ImportMarkValues(Appearance, AllSelectedSettings.MarkedAppearanceSettings, "Appearance");
		ImportMarkValues(OtherSettings, AllSelectedSettings.MarkedOtherSettings, "OtherSettings");
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Auxiliary procedures and functions

&AtClient
Procedure ChangeMark(Item)
	
	MarkedItem = Item.Parent.Parent.CurrentData;
	MarkValue = MarkedItem.Check;
	
	If MarkValue = 2 Then
		MarkValue = 0;
		MarkedItem.Check = MarkValue;
	EndIf;
	
	ItemParent = MarkedItem.GetParent();
	ChildItems = MarkedItem.GetItems();
	SettingsCount = 0;
	
	If ItemParent = Undefined Then
		
		For Each ChildItem In ChildItems Do
			
			If ChildItem.Check <> MarkValue Then
				SettingsCount = SettingsCount + 1
			EndIf;
			
			ChildItem.Check = MarkValue;
		EndDo;
		
		If ChildItems.Count() = 0 Then
			SettingsCount = SettingsCount + 1;
		EndIf;
		
	Else
		CheckChildItemMarksAndMarkParent(ItemParent, MarkValue);
		SettingsCount = SettingsCount + 1;
	EndIf;
	
	SettingsCount = ?(MarkValue, SettingsCount, -SettingsCount);
	// Updating settings page title
	RefreshPageTitle(SettingsCount);
	
EndProcedure

&AtClient
Procedure RefreshPageTitle(SettingsCount)
	
	If SelectedSettingsPage = "ReportSettingsPage" Then
		
		ReportSettingsCount = ReportSettingsCount + SettingsCount;
		TitleText = ?(ReportSettingsCount = 0, NStr("en='Report settings'"), NStr("en='Report settings (%1)'"));
		
		Items.ReportSettingsPage.Title = StringFunctionsClientServer.SubstituteParametersInString(
			TitleText, ReportSettingsCount);
		
	ElsIf SelectedSettingsPage = "AppearancePage" Then
		
		SettingsCountExternalType = SettingsCountExternalType + SettingsCount;
		TitleText = ?(SettingsCountExternalType = 0, NStr("en='Appearance'"), NStr("en='Appearance settings (%1)'"));
		
		Items.AppearancePage.Title = StringFunctionsClientServer.SubstituteParametersInString(
			TitleText, SettingsCountExternalType);
		
	ElsIf SelectedSettingsPage = "OtherSettingsPage" Then
		
		OtherSettingsCount = OtherSettingsCount + SettingsCount;
		TitleText = ?(OtherSettingsCount = 0, NStr("en='Other settings'"), NStr("en='Other settings (%1)'"));
		
		Items.OtherSettingsPage.Title = StringFunctionsClientServer.SubstituteParametersInString(
			TitleText, OtherSettingsCount);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckChildItemMarksAndMarkParent(TreeItem, MarkValue)
	
	UnmarkedItemsExist = False;
	HasSelected = False;
	
	ChildItems = TreeItem.GetItems();
	If ChildItems = Undefined Then
		TreeItem.Check = MarkValue;
	Else
		
		For Each ChildItem In ChildItems Do
			
			If ChildItem.Check = 0 Then
				UnmarkedItemsExist = True;
			ElsIf ChildItem.Check = 1 Then
				HasSelected = True;
			EndIf;
			
		EndDo;
		
		If UnmarkedItemsExist 
			And HasSelected Then
			TreeItem.Check = 2;
		ElsIf HasSelected Then
			TreeItem.Check = 1;
		Else
			TreeItem.Check = 0;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MarkTreeItems(SettingsTree, MarkValue)
	
	SettingsCount = 0;
	For Each TreeItem In SettingsTree Do
		ChildItems = TreeItem.GetItems();
		
		For Each ChildItem In ChildItems Do
			
			ChildItem.Check = MarkValue;
			SettingsCount = SettingsCount + 1;
			
		EndDo;
		
		If ChildItems.Count() = 0 Then
			SettingsCount = SettingsCount + 1;
		EndIf;
		
		TreeItem.Check = MarkValue;
	EndDo;
	
	SettingsCount = ?(MarkValue, SettingsCount, 0);
	
	If SelectedSettingsPage = "ReportSettingsPage" Then
		ReportSettingsCount = SettingsCount;
	ElsIf SelectedSettingsPage = "AppearancePage" Then
		SettingsCountExternalType = SettingsCount;
	ElsIf SelectedSettingsPage = "OtherSettingsPage" Then
		OtherSettingsCount = SettingsCount;
	EndIf;
	
	RefreshPageTitle(0);
	
EndProcedure

&AtClient
Function SelectedSettings(SettingsTree)
	
	SettingsArray = New Array;
	PersonalSettingsArray = New Array;
	SettingsPresentation = New Array;
	ReportOptionArray = New Array;
	OtherUserSettings = New Structure;
	SettingsCount = 0;
	
	For Each Settings In SettingsTree.GetItems() Do
		
		If Settings.Check = 1 Then
			
			If Settings.Type = "PersonalSettings" Then
				PersonalSettingsArray.Add(Settings.Keys);
			ElsIf Settings.Type = "OtherUserSettingsItem" Then
				OtherUserSettings.Insert("SettingID", Settings.RowType);
				OtherUserSettings.Insert("SettingValue", Settings.Keys);
			Else
				SettingsArray.Add(Settings.Keys);
				
				If Settings.Type = "PersonalOption" Then
					ReportOptionArray.Add(Settings.Keys);
				EndIf;
				
			EndIf;
			ChildItemCount = Settings.GetItems().Count();
			SettingsCount = SettingsCount + ?(ChildItemCount=0,1,ChildItemCount);
			
			If ChildItemCount = 1 Then
				
				ChildSettingsItem = Settings.GetItems()[0];
				SettingsPresentation.Add(Settings.Settings + " - " + ChildSettingsItem.Settings);
				
			ElsIf ChildItemCount = 0 Then
				SettingsPresentation.Add(Settings.Settings);
			EndIf;
			
		Else
			ChildSettings= Settings.GetItems();
			
			For Each ChildSettingsItem In ChildSettings Do
				
				If ChildSettingsItem .Check = 1 Then
					SettingsArray.Add(ChildSettingsItem .Keys);
					SettingsPresentation.Add(Settings.Settings + " - " + ChildSettingsItem .Settings);
					SettingsCount = SettingsCount + 1;
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	SettingsStructure = New Structure;
	
	SettingsStructure.Insert("SettingsArray", SettingsArray);
	SettingsStructure.Insert("PersonalSettingsArray", PersonalSettingsArray);
	SettingsStructure.Insert("OtherUserSettings", OtherUserSettings);
	SettingsStructure.Insert("ReportOptions", ReportOptionArray);
	SettingsStructure.Insert("SettingsPresentation", SettingsPresentation);
	SettingsStructure.Insert("SettingsCount", SettingsCount);
	
	Return SettingsStructure;
	
EndFunction

&AtClient
Procedure ExpandValueTree()
	
	Rows = ReportSettings.GetItems();
	For Each Row In Rows Do 
		Items.ReportSettingsTree.Expand(Row.GetID(), True);
	EndDo;
	
	Rows = Appearance.GetItems();
	For Each Row In Rows Do 
		Items.Appearance.Expand(Row.GetID(), True);
	EndDo;
	
EndProcedure

&AtServer
Function MarkedTreeItems()
	
	ReportSettingsTree = FormAttributeToValue("ReportSettings");
	AppearanceTree = FormAttributeToValue("Appearance");
	OtherSettingsTree = FormAttributeToValue("OtherSettings");
	
	MarkedReportSettings = MarkedSettings(ReportSettingsTree);
	MarkedAppearanceSettings = MarkedSettings(AppearanceTree);
	MarkedOtherSettings = MarkedSettings(OtherSettingsTree);
	
	If AllSelectedSettings = Undefined Then
		
		AllSelectedSettings = New Structure;
		AllSelectedSettings.Insert("MarkedReportSettings", MarkedReportSettings);
		AllSelectedSettings.Insert("MarkedAppearanceSettings", MarkedAppearanceSettings);
		AllSelectedSettings.Insert("MarkedOtherSettings", MarkedOtherSettings);
		
	Else
		
		AllSelectedSettings.MarkedReportSettings = 
			SettingsMarkedAfterComparison(MarkedReportSettings, ReportSettingsTree, "ReportSettings");
		AllSelectedSettings.MarkedAppearanceSettings = 
			SettingsMarkedAfterComparison(MarkedAppearanceSettings, AppearanceTree, "Appearance");
		AllSelectedSettings.MarkedOtherSettings = 
			SettingsMarkedAfterComparison(MarkedOtherSettings, OtherSettingsTree, "OtherSettings");
		
	EndIf;
	
EndFunction

&AtServer
Function MarkedSettings(SettingsTree)
	
	MarkedItemList= New ValueList;
	MarkedItemFilter = New Structure("Mark", 1);
	UndefinedItemFilter = New Structure("Mark", 2);
	
	MarkedArray = SettingsTree.Rows.FindRows(MarkedItemFilter, True);
	For Each ArrayRow In MarkedArray Do
		MarkedItemList.Add(ArrayRow.RowType, , True);
	EndDo;
	
	UndefinedItemArray = SettingsTree.Rows.FindRows(UndefinedItemFilter, True);
	For Each ArrayRow In UndefinedItemArray Do
		MarkedItemList.Add(ArrayRow.RowType);
	EndDo;
	
	Return MarkedItemList;
	
EndFunction

&AtServer
Function SettingsMarkedAfterComparison(MarkedSettings, SettingsTree, SettingsType)
	
	If SettingsType = "ReportSettings" Then
		SourceMarkedItemList= AllSelectedSettings.MarkedReportSettings;
	ElsIf SettingsType = "Appearance" Then
		SourceMarkedItemList= AllSelectedSettings.MarkedAppearanceSettings;
	ElsIf SettingsType = "OtherSettings" Then
		SourceMarkedItemList= AllSelectedSettings.MarkedOtherSettings;
	EndIf;
	
	For Each Item In SourceMarkedItemList Do
		
		FoundSetting = MarkedSettings.FindByValue(Item.Value);
		If FoundSetting = Undefined Then
			
			FilterParameters = New Structure("RowType", Item.Value);
			FoundSettingInTree = SettingsTree.Rows.FindRows(FilterParameters, True);
			If FoundSettingInTree.Count() = 0 Then
				MarkedSettings.Add(Item.Value, , Item.Check);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return MarkedSettings;
EndFunction

&AtServer
Procedure ImportMarkValues(ValueTree, MarkedSettings, SettingsKind)
	
	If MarkedSettings = Undefined Then
		Return;
	EndIf;
	MarkedItemCount = 0;
	
	For Each MarkedSettingsRow In MarkedSettings Do
		
		MarkedSetting = MarkedSettingsRow.Value;
		
		For Each TreeRow In ValueTree.GetItems() Do
			
			ChildItems = TreeRow.GetItems();
			
			If TreeRow.RowType = MarkedSetting Then
				
				If MarkedSettingsRow.Check Then
					TreeRow.Check = 1;
					
					If ChildItems.Count() = 0 Then
						MarkedItemCount = MarkedItemCount + 1;
					EndIf;
					
				Else
					TreeRow.Check = 2;
				EndIf;
				
			Else
				
				For Each ChildItem In ChildItems Do
					
					If ChildItem.RowType = MarkedSetting Then
						ChildItem.Check = 1;
						MarkedItemCount = MarkedItemCount + 1;
					EndIf;
					
				EndDo;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	If MarkedItemCount > 0 Then
		
		If SettingsKind = "ReportSettings" Then
			ReportSettingsCount = MarkedItemCount;
			Items.ReportSettingsPage.Title = StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en='Report settings (%1)'"), MarkedItemCount);
		ElsIf SettingsKind = "Appearance" Then
			SettingsCountExternalType = MarkedItemCount;
			Items.AppearancePage.Title = StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en='Appearance settings (%1)'"), MarkedItemCount);
		ElsIf SettingsKind = "OtherSettings" Then
			OtherSettingsCount = MarkedItemCount;
			Items.OtherSettingsPage.Title = StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en='Other settings (%1)'"), MarkedItemCount);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion
