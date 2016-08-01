#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region InternalProceduresAndFunctions

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for getting form settings.

// Gets a form settings list for the specified user.
// 
// Parameters: 
//   UserName - String - name of the infobase user whose
//                       form settings are retrieved.
// 
// Returns:
//   ValueList - list of forms where the user has settings.
//
Function AllFormSettings(UserName) Export
	
	FormList = MetadataObjectForms();
	
	// Adding standard forms to the list
	FormList.Add("ExternalDataProcessor.StandardEventLog.Form.EventsJournal", 
		NStr("en='Standard.Event log'") , False, PictureLib.Form);
	FormList.Add("ExternalDataProcessor.StandardEventLog.Form.EventForm", 
		NStr("en='Standard.Event log, Event'") , False, PictureLib.Form);
	FormList.Add("ExternalDataProcessor.StandardEventLog.Form.EventsJournalFilter", 
		NStr("en='Standard.Event log, Event filter settings'") , False, PictureLib.Form);
	FormList.Add("ExternalDataProcessor.StandardFindByRef.Form.MainForm", 
		NStr("en='Standard.Find references to objects'") , False, PictureLib.Form);
	FormList.Add("ExternalDataProcessor.StandardFullTextSearchManagement.Form.MainForm", 
		NStr("en='Standard.Manage Full Text Search'") , False, PictureLib.Form);
	FormList.Add("ExternalDataProcessor.StandardDocumentsPosting.Form.MainForm", 
		NStr("en='Standard.Document Posting'") , False, PictureLib.Form);
	FormList.Add("ExternalDataProcessor.StandardDeleteMarkedObjects.Form.Form", 
		NStr("en='Standard.Delete Marked Objects'") , False, PictureLib.Form);
	FormList.Add("ExternalDataProcessor.StandardExternalDataSourceManagement.Form.Form", 
		NStr("en='Standard.Management of external data sources'") , False, PictureLib.Form);
	FormList.Add("ExternalDataProcessor.StandardTotalsManagement.Form.MainForm", 
		NStr("en='Standard.Totals management'") , False, PictureLib.Form);
	FormList.Add("ExternalDataProcessor.StandardActiveUsers.Form.ActiveUsersListForm", 
		NStr("en='Standard.Active users'") , False, PictureLib.Form);
		
	Return FormSettingsList(FormList, UserName);
	
EndFunction

// Gets the list of configuration forms and fills the following fields:
// Value        - form name that serves as a unique ID.
// Presentation - form synonym.
// Picture      - picture that matches the related object. 
//
// Returns:
// ValueList - list of all metadata object forms.
//
Function MetadataObjectForms()
	
	FormList = New ValueList;
	
	For Each Form In Metadata.CommonForms Do
		FormList.Add("CommonForm." + Form.Name, Form.Synonym, False, PictureLib.Form);
	EndDo;

	StandardFormNames = New ValueList;
	StandardFormNames.Add("Form");
	GetMetadataObjectFormList(Metadata.FilterCriteria, "FilterCriterion", NStr("en='Filter criterion'"),
		StandardFormNames, PictureLib.FilterCriterion, FormList);
		
	StandardFormNames = New ValueList;
	GetMetadataObjectFormList(Metadata.SettingsStorages, "SettingsStorage", NStr("en='Settings storage'"),
		StandardFormNames, PictureLib.SettingsStorage, FormList);
	
	StandardFormNames = New ValueList;
	StandardFormNames.Add("ObjectForm");
	StandardFormNames.Add("FolderForm");
	StandardFormNames.Add("ListForm");
	StandardFormNames.Add("ChoiceForm");
	StandardFormNames.Add("FolderChoiceForm");
	GetMetadataObjectFormList(Metadata.Catalogs, "Catalog", NStr("en='Catalog'"),
		StandardFormNames, PictureLib.Catalog, FormList);
	
	StandardFormNames = New ValueList;
	StandardFormNames.Add("ObjectForm");
	StandardFormNames.Add("ListForm");
	StandardFormNames.Add("ChoiceForm");
	GetMetadataObjectFormList(Metadata.Documents, "Document", NStr("en='Document'"),
		StandardFormNames, PictureLib.Document, FormList);
	
	StandardFormNames = New ValueList;
	StandardFormNames.Add("Form");
	GetMetadataObjectFormList(Metadata.DocumentJournals, "DocumentJournal", NStr("en='Document journal'"),
		StandardFormNames, PictureLib.DocumentJournal, FormList);
	
	StandardFormNames = New ValueList;
	StandardFormNames.Add("ListForm");
	StandardFormNames.Add("ChoiceForm");
	GetMetadataObjectFormList(Metadata.Enums, "Enum", NStr("en='Enumeration'"),
		StandardFormNames, PictureLib.Enum, FormList);
	
	StandardFormNames = New ValueList;
	StandardFormNames.Add("Form");
	StandardFormNames.Add("SettingsForm");
	StandardFormNames.Add("VariantForm");
	GetMetadataObjectFormList(Metadata.Reports, "Report", NStr("en='Report'"),
		StandardFormNames, PictureLib.Report, FormList);
	
	StandardFormNames = New ValueList;
	StandardFormNames.Add("Form");
	GetMetadataObjectFormList(Metadata.DataProcessors, "DataProcessor", NStr("en='Data processor'"),
		StandardFormNames, PictureLib.DataProcessor, FormList);
	
	StandardFormNames = New ValueList;
	StandardFormNames.Add("ObjectForm");
	StandardFormNames.Add("FolderForm");
	StandardFormNames.Add("ListForm");
	StandardFormNames.Add("ChoiceForm");
	StandardFormNames.Add("FolderChoiceForm");
	GetMetadataObjectFormList(Metadata.ChartsOfCharacteristicTypes, "ChartOfCharacteristicTypes", NStr("en='Chart of characteristic types'"),
		StandardFormNames, PictureLib.ChartOfCharacteristicTypes, FormList);
	
	StandardFormNames = New ValueList;
	StandardFormNames.Add("ObjectForm");
	StandardFormNames.Add("ListForm");
	StandardFormNames.Add("ChoiceForm");
	GetMetadataObjectFormList(Metadata.ChartsOfAccounts, "ChartOfAccounts", NStr("en='Chart of accounts'"),
		StandardFormNames, PictureLib.ChartOfAccounts, FormList);
	
	StandardFormNames = New ValueList;
	StandardFormNames.Add("ObjectForm");
	StandardFormNames.Add("ListForm");
	StandardFormNames.Add("ChoiceForm");
	GetMetadataObjectFormList(Metadata.ChartsOfCalculationTypes, "ChartOfCalculationTypes", NStr("en='Chart of calculation types'"),
		StandardFormNames, PictureLib.ChartOfCalculationTypes, FormList);
	
	StandardFormNames = New ValueList;
	StandardFormNames.Add("RecordForm");
	StandardFormNames.Add("ListForm");
	GetMetadataObjectFormList(Metadata.InformationRegisters, "InformationRegister", NStr("en='Information register'"),
		StandardFormNames, PictureLib.InformationRegister, FormList);
	
	StandardFormNames = New ValueList;
	StandardFormNames.Add("ListForm");
	GetMetadataObjectFormList(Metadata.AccumulationRegisters, "AccumulationRegister", NStr("en='Accumulation register'"),
		StandardFormNames, PictureLib.AccumulationRegister, FormList);
	
	StandardFormNames = New ValueList;
	StandardFormNames.Add("ListForm");
	GetMetadataObjectFormList(Metadata.AccountingRegisters, "AccountingRegister", NStr("en='Accounting register'"),
		StandardFormNames, PictureLib.AccountingRegister, FormList);
	
	StandardFormNames = New ValueList;
	StandardFormNames.Add("ListForm");
	GetMetadataObjectFormList(Metadata.CalculationRegisters, "CalculationRegister", NStr("en='Calculation register'"),
		StandardFormNames, PictureLib.CalculationRegister, FormList);
	
	StandardFormNames = New ValueList;
	StandardFormNames.Add("ObjectForm");
	StandardFormNames.Add("ListForm");
	StandardFormNames.Add("ChoiceForm");
	GetMetadataObjectFormList(Metadata.BusinessProcesses, "BusinessProcess", NStr("en='Business process'"),
		StandardFormNames, PictureLib.BusinessProcess, FormList);
	
	StandardFormNames = New ValueList;
	StandardFormNames.Add("ObjectForm");
	StandardFormNames.Add("ListForm");
	StandardFormNames.Add("ChoiceForm");
	GetMetadataObjectFormList(Metadata.Tasks, "Task", NStr("en='Task'"),
		StandardFormNames, PictureLib.Task, FormList);
	
	StandardFormNames = New ValueList;
	StandardFormNames.Add("RecordForm");
	StandardFormNames.Add("ListForm");
	GetMetadataObjectFormList(Metadata.ExternalDataSources, "ExternalDataSource", NStr("en='External data source'"),
		StandardFormNames, PictureLib.ExternalDataSourceTable, FormList);

	Return FormList;
EndFunction

// Returns a settings list for the forms specified in the FormList parameter and for the user specified in the UserName parameter. 
//
Function FormSettingsList(FormList, UserName)
	
	Result = New ValueList;
	Settings = ReadSettingsFromStorage(SystemSettingsStorage, UserName);
	FormSettingsArray = PredefinedSettings();
	For Each Item In FormList Do
		
		For Each FormSettingsItem In FormSettingsArray Do
		
			SearchSettings = Settings.Find(Item.Value + FormSettingsItem);
			If SearchSettings <> Undefined Then
				Result.Add(Item.Value, Item.Presentation, Item.Check, Item.Picture);
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Return Result;
	
EndFunction

Procedure GetMetadataObjectFormList(MetadataObjectList, MetadataObjectType,
	MetadataObjectPresentation, StandardFormNames, Picture, FormList)
	
	For Each Object In MetadataObjectList Do
		
		If MetadataObjectType = "ExternalDataSource" Then
			GetExternalDataSourceFormList(Object, MetadataObjectType, MetadataObjectPresentation, Picture, FormList);
			Continue;
		EndIf;
		
		NamePrefix = MetadataObjectType + "." + Object.Name;
		PresentationPrefix = Object.Synonym + ".";
		
		For Each Form In Object.Forms Do
			FormPresentationAndMark = FormPresentation(Object, Form, MetadataObjectType);
			FormPresentation = FormPresentationAndMark.FormName;
			Check = FormPresentationAndMark.CanOpenForm;
			FormList.Add(NamePrefix + ".Form." + Form.Name, PresentationPrefix + FormPresentation, Check, Picture);
		EndDo;
		
		For Each StandardFormName In StandardFormNames Do
			
			If Object["Default" + StandardFormName] = Undefined Then
				FormPresentationAndMark = AutogeneratedFormPresentation(Object, StandardFormName.Value, MetadataObjectType);
				FormPresentation = FormPresentationAndMark.FormName;
				Check = FormPresentationAndMark.CanOpenForm;
				FormList.Add(NamePrefix + "." + StandardFormName.Value, PresentationPrefix + FormPresentation, Check, Picture);
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure GetExternalDataSourceFormList(Object, MetadataObjectType, 
	MetadataObjectPresentation, Picture, FormList)
	
	For Each Table In Object.Tables Do
		
		NamePrefix = MetadataObjectType + "." + Object.Name + ".Table.";
		PresentationPrefix = Table.Synonym + ".";
		
		For Each Form In Table.Forms Do
			FormPresentation = FormPresentation(Table, Form, MetadataObjectType).FormName;
			FormList.Add(NamePrefix + Table.Name + ".Form." + Form.Name, PresentationPrefix + FormPresentation, False, Picture);
		EndDo;
		
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for copying and deleting all user settings.

// Deletes user settings from the storage.
//
// Parameters:
// SettingsToClear - Array - types of settings to be cleared.
//                   For example, ReportSettings or AppearanceSettings.
// Sources         - Array - array of users whose settings are cleared.
//                   Array element type is Catalog.UserRef.
//
Procedure DeleteAppUserSettings(SettingsToClear, Sources, UserReportOptionTable = Undefined) Export
	
	SettingsItemStorageMap = New Map;
	SettingsItemStorageMap.Insert("ReportSettings", ReportsUserSettingsStorage);
	SettingsItemStorageMap.Insert("AppearanceSettings", SystemSettingsStorage);
	SettingsItemStorageMap.Insert("FormData", FormDataSettingsStorage);
	SettingsItemStorageMap.Insert("PersonalSettings", CommonSettingsStorage);
	SettingsItemStorageMap.Insert("Favorites", SystemSettingsStorage);
	SettingsItemStorageMap.Insert("PrintSettings", SystemSettingsStorage);
	
	For Each SettingsItemToClear In SettingsToClear Do
		SettingsManager = SettingsItemStorageMap[SettingsItemToClear];
		
		For Each Source In Sources Do
			
			If SettingsItemToClear = "OtherUserSettings" Then
				// Getting user settings
				UserInfo = New Structure;
				UserInfo.Insert("UserRef", Source);
				UserInfo.Insert("InfobaseUserName", InfobaseUserName(Source));
				OtherAppUserSettings = New Structure;
				UsersInternal.OnGetOtherSettings(UserInfo, OtherAppUserSettings);
				Keys = New ValueList;
				OtherSettingsArray = New Array;
				If OtherAppUserSettings.Count() <> 0 Then
					
					For Each OtherSetting In OtherAppUserSettings Do
						OtherSettingsStructure = New Structure;
						If OtherSetting.Key = "QuickAccessSettingsItem" Then
							SettingsList = OtherSetting.Value.SettingsList;
							For Each Item In SettingsList Do
								Keys.Add(Item.Object, Item.ID);
							EndDo;
							OtherSettingsStructure.Insert("SettingID", "QuickAccessSettingsItem");
							OtherSettingsStructure.Insert("SettingValue", Keys);
						Else
							OtherSettingsStructure.Insert("SettingID", OtherSetting.Key);
							OtherSettingsStructure.Insert("SettingValue", OtherSetting.Value.SettingsList);
						EndIf;
						
						UsersInternal.OnDeleteOtherSettings(UserInfo, OtherSettingsStructure);
					EndDo;
					
				EndIf;
				
				Continue;
			EndIf;
			
			Source = InfobaseUserName(Source);
			
			If SettingsItemToClear = "ReportSettings" Then
				
				If UserReportOptionTable = Undefined Then
					UserReportOptionTable = UserReportOptions(Source);
				EndIf;
				
				For Each ReportOption In UserReportOptionTable Do
					
					StandardProcessing = True;
					UsersInternal.OnDeleteUserReportOptions(ReportOption, Source, StandardProcessing);
					If StandardProcessing Then
						ReportsVariantsStorage.Delete(ReportOption.ObjectKey, ReportOption.VariantKey, Source);
					EndIf;
					
				EndDo;
				
			EndIf;
			
			SettingsFromStorage = SettingsList(Source, SettingsManager, SettingsItemToClear);
			DeleteSettings(SettingsManager, SettingsFromStorage, Source);
			
			UsersInternal.SetInitialSettings(Source);
			
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure DeleteSettings(SettingsManager, SettingsFromStorage, UserName)
	
	For Each SettingsItem In SettingsFromStorage Do
		ObjectKey = SettingsItem.ObjectKey;
		SettingsKey = SettingsItem.SettingsKey;
		SettingsManager.Delete(ObjectKey, SettingsKey, UserName);
	EndDo;
	
EndProcedure

Function CopyAppUserSettings(UserSourceRef, UsersTarget, SettingsToCopy,
										NotCopiedReportSettings = Undefined) Export
	
	SettingsItemStorageMap = New Map;
	SettingsItemStorageMap.Insert("ReportSettings", ReportsUserSettingsStorage);
	SettingsItemStorageMap.Insert("AppearanceSettings", SystemSettingsStorage);
	SettingsItemStorageMap.Insert("FormData", FormDataSettingsStorage);
	SettingsItemStorageMap.Insert("PersonalSettings", CommonSettingsStorage);
	SettingsItemStorageMap.Insert("Favorites", SystemSettingsStorage);
	SettingsItemStorageMap.Insert("PrintSettings", SystemSettingsStorage);
	SettingsItemStorageMap.Insert("ReportOptions", ReportsVariantsStorage);
	HasSettings = False;
	ReportOptionTable = Undefined;
	UserSource = InfobaseUserName(UserSourceRef);
	
	// Getting user settings
	UserInfo = New Structure;
	UserInfo.Insert("UserRef", UserSourceRef);
	UserInfo.Insert("InfobaseUserName", UserSource);
	OtherAppUserSettings = New Structure;
	UsersInternal.OnGetOtherSettings(UserInfo, OtherAppUserSettings);
	Keys = New ValueList;
	OtherSettingsArray = New Array;
	If OtherAppUserSettings.Count() <> 0 Then
		
		For Each OtherSetting In OtherAppUserSettings Do
			OtherSettingsStructure = New Structure;
			If OtherSetting.Key = "QuickAccessSettingsItem" Then
				SettingsList = OtherSetting.Value.SettingsList;
				For Each Item In SettingsList Do
					Keys.Add(Item.Object, Item.ID);
				EndDo;
				OtherSettingsStructure.Insert("SettingID", "QuickAccessSettingsItem");
				OtherSettingsStructure.Insert("SettingValue", Keys);
			Else
				OtherSettingsStructure.Insert("SettingID", OtherSetting.Key);
				OtherSettingsStructure.Insert("SettingValue", OtherSetting.Value.SettingsList);
			EndIf;
			OtherSettingsArray.Add(OtherSettingsStructure);
		EndDo;
		
	EndIf;
	
	For Each SettingsItemToCopy In SettingsToCopy Do
		SettingsManager = SettingsItemStorageMap[SettingsItemToCopy];
		
		If SettingsItemToCopy = "OtherUserSettings" Then
			For Each UserTarget In UsersTarget Do
				UserInfo = New Structure;
				UserInfo.Insert("UserRef", UserTarget);
				UserInfo.Insert("InfobaseUserName", InfobaseUserName(UserTarget));
				For Each ArrayElement In OtherSettingsArray Do
					UsersInternal.OnSaveOtherSetings(UserInfo, ArrayElement);
				EndDo;
			EndDo;
			Continue;
		EndIf;
		
		If SettingsItemToCopy = "ReportSettings" Then
			
			If TypeOf(SettingsItemStorageMap["ReportOptions"]) = Type("StandardSettingsStorageManager") Then
				ReportOptionTable = UserReportOptions(UserSource);
				ReportOptionKeyAndTypeTable = GetReportOptionKeys(ReportOptionTable);
				SettingsToCopy.Add("ReportOptions");
			EndIf;
			
		EndIf;
		
		SettingsFromStorage = SettingsList(
			UserSource, SettingsManager, SettingsItemToCopy, ReportOptionKeyAndTypeTable, True);
		
		If SettingsFromStorage.Count() <> 0 Then
			HasSettings = True;
		EndIf;
		
		For Each UserTarget In UsersTarget Do
			CopySettings(
				SettingsManager, SettingsFromStorage, UserSource, UserTarget, NotCopiedReportSettings);
			ReportOptionTable = Undefined;
		EndDo;
		
	EndDo;
	
	Return HasSettings;
	
EndFunction

Function SettingsList(UserName, SettingsManager, 
						SettingsItemToCopy, ReportOptionKeyAndTypeTable = Undefined, ForCopying = False)
	
	GetFavorites = False;
	GetPrintSettings = False;
	If SettingsItemToCopy = "Favorites" Then
		GetFavorites = True;
	EndIf;
	
	If SettingsItemToCopy = "PrintSettings" Then
		GetPrintSettings = True;
	EndIf;
	
	SettingsTable = New ValueTable;
	SettingsTable.Columns.Add("ObjectKey");
	SettingsTable.Columns.Add("SettingsKey");
	
	Filter = New Structure;
	Filter.Insert("User", UserName);
	
	SettingsSelection = SettingsManager.Select(Filter);
	
	Ignore = False;
	While NextSettingsItem(SettingsSelection, Ignore) Do
		
		If Ignore Then
			Continue;
		EndIf;
		
		If Not GetFavorites
			And Find(SettingsSelection.ObjectKey, "UserWorkFavorites") <> 0 Then
			Continue;
		ElsIf GetFavorites Then
			
			If Find(SettingsSelection.ObjectKey, "UserWorkFavorites") = 0 Then
				Continue;
			ElsIf Find(SettingsSelection.ObjectKey, "UserWorkFavorites") <> 0 Then
				AddRowToValueTable(SettingsTable, SettingsSelection);
				Continue;
			EndIf;
			
		EndIf;
		
		If Not GetPrintSettings
			And Find(SettingsSelection.ObjectKey, "SpreadsheetDocumentPrintSettings") <> 0 Then
			Continue;
		ElsIf GetPrintSettings Then
			
			If Find(SettingsSelection.ObjectKey, "SpreadsheetDocumentPrintSettings") = 0 Then
				Continue;
			ElsIf Find(SettingsSelection.ObjectKey, "SpreadsheetDocumentPrintSettings") <> 0 Then
				AddRowToValueTable(SettingsTable, SettingsSelection);
				Continue;
			EndIf;
			
		EndIf;
		
		If ReportOptionKeyAndTypeTable <> Undefined Then
			
			FoundReportOption = ReportOptionKeyAndTypeTable.Find(SettingsSelection.ObjectKey, "VariantKey");
			If FoundReportOption <> Undefined Then
				
				If Not FoundReportOption.Check Then
					Continue;
				EndIf;
				
			EndIf;
			
		EndIf;
		
		If ForCopying And SkipSettingsItem(SettingsSelection.ObjectKey, SettingsSelection.SettingsKey) Then
			Continue;
		EndIf;
		
		AddRowToValueTable(SettingsTable, SettingsSelection);
	EndDo;
	
	Return SettingsTable;
	
EndFunction

Function NextSettingsItem(SettingsSelection, Ignore)
	
	Try 
		Ignore = False;
		Return SettingsSelection.Next();
	Except
		Ignore = True;
		Return True;
	EndTry;
	
EndFunction

Procedure CopySettings(SettingsManager, SettingsTable, UserSource,
								UserTarget, NotCopiedReportSettings)
	
	TargetInfobaseUser = InfobaseUserName(UserTarget);
	CurrentUser = Undefined;
	For Each SettingsItem In SettingsTable Do
		
		ObjectKey = SettingsItem.ObjectKey;
		SettingsKey = SettingsItem.SettingsKey;
		
		If SettingsManager = ReportsUserSettingsStorage
			Or SettingsManager = ReportsVariantsStorage Then
			
			AvailableReportArray = ReportsAvailableToUser(TargetInfobaseUser);
			ReportKey = StringFunctionsClientServer.SplitStringIntoSubstringArray(ObjectKey, "/");
			If AvailableReportArray.Find(ReportKey[0]) = Undefined Then
				
				If SettingsManager = ReportsUserSettingsStorage
					And NotCopiedReportSettings <> Undefined Then
					
					If CurrentUser = Undefined Then
						TableRow = NotCopiedReportSettings.Add();
						TableRow.User = UserTarget.Description;
						CurrentUser = UserTarget.Description;
					EndIf;
					
					If TableRow.ReportList.FindByValue(ReportKey[0]) = Undefined Then
						TableRow.ReportList.Add(ReportKey[0]);
					EndIf;
					
				EndIf;
				
				Continue;
			EndIf;
			
		EndIf;
		
		Try
			Value = SettingsManager.Load(ObjectKey, SettingsKey, , UserSource);
		Except
			Continue;
		EndTry;
		SettingsDescription = SettingsManager.GetDescription(ObjectKey, SettingsKey, UserSource);
		SettingsManager.Save(ObjectKey, SettingsKey, Value,
			SettingsDescription, TargetInfobaseUser);
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for copying and deleting selected user settings.

// Copies user report settings.
// 
// Parameters:
// UserSource          - String – source user for copying the settings.
// UsersTarget         - Array with elements of the UserRef type  
//                     - target users for copying the settings.
// SettingsToCopyArray - Array with elements of the ValueList type 
//                     - contains selected settings keys.
//
Procedure CopyReportAndPersonalSettings(SettingsManager, UserSource,
		UsersTarget, SettingsToCopyArray, NotCopiedReportSettings = Undefined) Export
	
	For Each UserTarget In UsersTarget Do
		CurrentUser = Undefined;
		
		For Each Element In SettingsToCopyArray Do
				
			For Each SettingsItem In Element Do
				
				SettingsKey = SettingsItem.Presentation;
				ObjectKey = SettingsItem.Value;
				If SkipSettingsItem(ObjectKey, SettingsKey) Then
					Continue;
				EndIf;
				Settings = SettingsManager.Load(ObjectKey, SettingsKey, , UserSource);
				SettingDetails = SettingsManager.GetDescription(ObjectKey, SettingsKey, UserSource);
				
				If Settings <> Undefined Then
					
					TargetInfobaseUser = DataProcessors.ApplicationUserSettings.InfobaseUserName(UserTarget);
					
					If SettingsManager = ReportsUserSettingsStorage Then
						AvailableReportArray = ReportsAvailableToUser(TargetInfobaseUser);
						ReportKey = StringFunctionsClientServer.SplitStringIntoSubstringArray(ObjectKey, "/");
						
						If AvailableReportArray.Find(ReportKey[0]) = Undefined Then
							
							If CurrentUser = Undefined Then
								TableRow = NotCopiedReportSettings.Add();
								TableRow.User = UserTarget.Description;
								CurrentUser = UserTarget.Description;
							EndIf;
							
							If TableRow.ReportList.FindByValue(ReportKey[0]) = Undefined Then
								TableRow.ReportList.Add(ReportKey[0]);
							EndIf;
								
							Continue;
						EndIf;
						
					EndIf;
					
					SettingsManager.Save(ObjectKey, SettingsKey, Settings, SettingDetails, TargetInfobaseUser);
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Copies appearance settings. 
// 
// Parameters:
//  UserSource          - String – source user for copying the settings.
//  UsersTarget         - Array with elements of the UserRef type 
//                      - target users for copying the settings.
//  SettingsToCopyArray - Array with elements of the ValueList type 
//                      - contains selected settings keys.
//
Procedure CopyAppearanceSettings(UserSource, UsersTarget, SettingsToCopyArray) Export
	FormSettingsArray = PredefinedSettings();
	
	For Each Element In SettingsToCopyArray Do
		
		For Each SettingsItem In Element Do
			SettingsKey = SettingsItem.Presentation;
			ObjectKey = SettingsItem.Value;
			
			If SettingsKey = "Interface"
				Or SettingsKey = "Other" Then
				CopyDesktopSettings(ObjectKey, UserSource, UsersTarget);
				Continue;
			EndIf;
			
			For Each Element In FormSettingsArray Do
				Settings = SystemSettingsStorage.Load(ObjectKey + Element, SettingsKey, , UserSource);
				
				If Settings <> Undefined Then
					
					For Each UserTarget In UsersTarget Do
						TargetInfobaseUser = DataProcessors.ApplicationUserSettings.InfobaseUserName(UserTarget);
						SystemSettingsStorage.Save(ObjectKey + Element, SettingsKey, Settings, , TargetInfobaseUser);
					EndDo;
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure CopyDesktopSettings(ObjectKey, UserSource, UsersTarget)
	
	Settings = SystemSettingsStorage.Load(ObjectKey, "", , UserSource);
	If Settings <> Undefined Then
		
		For Each UserTarget In UsersTarget Do
			TargetInfobaseUser = DataProcessors.ApplicationUserSettings.InfobaseUserName(UserTarget);
			SystemSettingsStorage.Save(ObjectKey, "", Settings, , TargetInfobaseUser);
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure DeleteSettingsForSelectedUsers(Users, SettingsForDeletionArray, StorageName) Export
	
	For Each User In Users Do
		User = DataProcessors.ApplicationUserSettings.InfobaseUserName(User);
		DeleteSelectedSettings(User, SettingsForDeletionArray, StorageName);
	EndDo;
	
EndProcedure

// Deletes selected settings. 
// 
// Parameter:
//  User                     - String - name of the infobase user 
//                             whose settings are deleted.
//  SettingsForDeletionArray - Array with elements of the ValueList type 
//                           - contains selected settings keys.
//  StorageName              - String - settings storage name.
//
Procedure DeleteSelectedSettings(UserName, SettingsForDeletionArray, StorageName) Export
	
	SettingsManager = SettingsStorageByName(StorageName);
	If StorageName = "ReportsUserSettingsStorage" Or StorageName = "CommonSettingsStorage" Then
		
		For Each Element In SettingsForDeletionArray Do
			
			For Each Settings In Element Do
				SettingsManager.Delete(Settings.Value, Settings.Presentation, UserName);
			EndDo;
			
		EndDo;
		
	ElsIf StorageName = "SystemSettingsStorage" Then
		
		SetInitialSettings = False;
		FormSettingsArray = PredefinedSettings();
		
		For Each Element In SettingsForDeletionArray Do
			
			For Each SettingsItem In Element Do
				
				If SettingsItem.Presentation = "Interface" Or SettingsItem.Presentation = "Other" Then
					
					SettingsManager.Delete(SettingsItem.Value, , UserName);
					
					If SettingsItem.Value = "Common/ClientSettings" 
						Or SettingsItem.Value = "Common/SectionsPanel/CommandInterfaceSettings" 
						Or SettingsItem.Value = "Common/ClientApplicationInterfaceSettings" Then
						
						SetInitialSettings = True;
						
					EndIf;
					
				Else
					
					For Each FormItem In FormSettingsArray Do
						SettingsManager.Delete(SettingsItem.Value + FormItem, SettingsItem.Presentation, UserName);
					EndDo;
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
		If SetInitialSettings Then
			UsersInternal.SetInitialSettings(UserName);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure DeleteReportOptions(ReportOptionArray, UserReportOptionTable, InfobaseUser) Export
	
	For Each Settings In ReportOptionArray Do
		
		ObjectKey = StringFunctionsClientServer.SplitStringIntoSubstringArray(Settings[0].Value, "/");
		ReportKey = ObjectKey[0];
		VariantKey = ObjectKey[1];
		
		FilterParameters = New Structure("VariantKey", VariantKey);
		FoundReportOption = UserReportOptionTable.FindRows(FilterParameters);
		
		If FoundReportOption.Count() = 0 Then
			Continue;
		EndIf;
		
		StandardProcessing = True;
		UsersInternal.OnDeleteUserReportOptions(FoundReportOption[0], InfobaseUser, StandardProcessing);
		If StandardProcessing Then
			ReportsVariantsStorage.Delete(ReportKey, VariantKey, InfobaseUser);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure CopyReportOptions(ReportOptionArray, UserReportOptionTable,
										InfobaseUser, RecipientUsers) Export
		
		If TypeOf(InfobaseUser) <> Type("String") Then
			InfobaseUser = InfobaseUserName(InfobaseUser);
		EndIf;
		
		For Each SettingsElement In ReportOptionArray Do
		
		ObjectKey = StringFunctionsClientServer.SplitStringIntoSubstringArray(SettingsElement[0].Value, "/");
		ReportKey = ObjectKey[0];
		VariantKey = ObjectKey[1];
		
		FilterParameters = New Structure("VariantKey", VariantKey);
		FoundReportOption = UserReportOptionTable.FindRows(FilterParameters);
		
		If FoundReportOption[0].StandardProcessing Then
			
			Try
			Value = ReportsVariantsStorage.Load(ReportKey, VariantKey, , InfobaseUser);
			Except
				Continue;
			EndTry;
			SettingDetails = ReportsVariantsStorage.GetDescription(ReportKey, VariantKey, InfobaseUser);
			
			For Each SettingsRecipient In RecipientUsers Do
				SettingsRecipient = InfobaseUserName(SettingsRecipient);
				ReportsVariantsStorage.Save(ReportKey, VariantKey, Value, SettingDetails, SettingsRecipient);
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for getting the list of users and user groups.

// Gets a list of users from the Users catalog and filters out invalid users,
// shared users (if data separation mode is set), and users with empty IDs.
// 
// Parameters:
//  UserSource   - CatalogRef - user to be removed from the resulting user table. 
//  UserTable    - ValueTable - table for storing the selected users.
//  ExternalUser - Boolean - if True, users are selected from the ExternalUsers catalog.
//  Clearing     - Boolean.
//
Function UsersToCopy(UserSource, UserTable, ExternalUser, Clearing = False) Export
	
	UserList = ?(ExternalUser, AllExternalUsersList(UserSource),
		AllUsersList(UserSource, Clearing));
	For Each UserRef In UserList Do
		UserTableRow = UserTable.Add();
		UserTableRow.User = UserRef.User;
	EndDo;
	UserTable.Sort("User Asc");
	
	Return UserTable;
	
EndFunction

Function AllUsersList(UserSource, Clearing)
	
	SetPrivilegedMode(True);
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Users.Ref AS User
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	NOT Users.NotValid"
	+ ?(Clearing And Not CommonUseCached.DataSeparationEnabled(),"", Chars.LF + "	AND NOT Users.Internal")
	+ ?(Clearing,"", Chars.LF + "	AND NOT Users.DeletionMark") + Chars.LF +
	"	AND Users.Ref <>
	|	&UserSource And Users.InfobaseUserID <> &InfobaseUserIDIsEmpty";
	Query.Parameters.Insert("UserSource", UserSource);
	Query.Parameters.Insert("InfobaseUserIDIsEmpty", New UUID("00000000-0000-0000-0000-000000000000"));
	
	BeginTransaction();
	Try
		QueryResult = Query.Execute().Unload();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return QueryResult;
	
EndFunction

Function AllExternalUsersList(UserSource)
	
	SetPrivilegedMode(True);
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Users.Ref AS User
	|FROM
	|	Catalog.ExternalUsers AS Users
	|WHERE
	|	NOT Users.NotValid
	|	AND Not Users.DeletionMark
	|	AND Users.Ref <> &UserSource
	|	AND Users.InfobaseUserID <> &InfobaseUserIDIsEmpty";
	Query.Parameters.Insert("UserSource", UserSource);
	Query.Parameters.Insert("InfobaseUserIDIsEmpty", New UUID("00000000-0000-0000-0000-000000000000"));
	
	BeginTransaction();
	Try
		QueryResult = Query.Execute().Unload();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return QueryResult;
	
EndFunction

// Generates a value tree of user groups.
// 
// Parameters:
//  GroupTree    - ValueTree - tree filled with user groups.
//  
//  ExternalUser - Boolean - if True, users are selected from the ExternalUsers catalog.
Procedure FillGroupTree(GroupTree, ExternalUser) Export
	
	GroupsArray = New Array;
	ParentGroupArray = New Array;
	GroupListAndFullContent = UserGroups(ExternalUser);
	UserGroupList = GroupListAndFullContent.UserGroupList;
	GroupsAndContentTable = GroupListAndFullContent.GroupsAndContentTable;
	
	If ExternalUser Then
		EmptyGroup = Catalogs.ExternalUserGroups.EmptyRef();
	Else
		EmptyGroup = Catalogs.UserGroups.EmptyRef();
	EndIf;
	
	GenerateFilter(UserGroupList, EmptyGroup, GroupsArray);
	
	While GroupsArray.Count() > 0 Do
		ParentGroupArray.Clear();
		
		For Each Group In GroupsArray Do
			
			If Group.Parent = EmptyGroup Then
				NewGroupRow = GroupTree.Rows.Add();
				NewGroupRow.Group = Group.Ref;
				GroupContent = UserGroupContent(Group.Ref, ExternalUser);
				FullGroupContent = UserGroupFullContent(GroupsAndContentTable, Group.Ref);
				NewGroupRow.Content = GroupContent;
				NewGroupRow.FullContent = FullGroupContent;
				NewGroupRow.Picture = 3;
			Else
				GroupParent = GroupTree.Rows.FindRows(New Structure("Group", Group.Parent), True);
				NewSubgroupRow = GroupParent[0].Rows.Add();
				NewSubgroupRow.Group = Group.Ref;
				GroupContent = UserGroupContent(Group.Ref, ExternalUser);
				FullGroupContent = UserGroupFullContent(GroupsAndContentTable, Group.Ref);
				NewSubgroupRow.Content = GroupContent;
				NewSubgroupRow.FullContent = FullGroupContent;
				NewSubgroupRow.Picture = 3;
			EndIf;
			
			ParentGroupArray.Add(Group.Ref);
		EndDo;
		GroupsArray.Clear();
		
		For Each Element In ParentGroupArray Do
			GenerateFilter(UserGroupList, Element, GroupsArray);
		EndDo;
		
	EndDo;
	
EndProcedure

Function UserGroups(ExternalUser)
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	UserGroupsCatalog.Ref AS Ref,
	|	UserGroupsCatalog.Parent AS Parent
	|FROM
	|	Catalog.UserGroups AS UserGroupsCatalog";
	If ExternalUser Then 
		Query.Text = StrReplace(Query.Text, "Catalog.UserGroups", "Catalog.ExternalUserGroups");
	EndIf;
	
	UserGroupList = Query.Execute().Unload();
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	UserGroupContents.UserGroup AS UserGroup,
	|	UserGroupContents.User AS User
	|FROM
	|	InformationRegister.UserGroupContents AS UserGroupContents
	|
	|ORDER BY
	|	UserGroup";
	
	UserGroupContent = Query.Execute().Unload();
	
	GroupsAndContentTable = UserGroupsFullContent(UserGroupContent);
	
	Return New Structure("UserGroupList, GroupsAndContentTable",
							UserGroupList, GroupsAndContentTable);
EndFunction

Function UserGroupsFullContent(UserGroupContent)
	
	GroupsAndContentTable = New ValueTable;
	GroupsAndContentTable.Columns.Add("Group");
	GroupsAndContentTable.Columns.Add("Content");
	GroupContent = New ValueList;
	CurrentGroup = Undefined;
	
	For Each ContentRow In UserGroupContent Do
		
		If TypeOf(ContentRow.UserGroup) = Type("CatalogRef.UserGroups")
			Or TypeOf(ContentRow.UserGroup) = Type("CatalogRef.ExternalUserGroups") Then
			
			If CurrentGroup <> ContentRow.UserGroup 
				And Not CurrentGroup = Undefined Then
				GroupsAndContentTableRow = GroupsAndContentTable.Add();
				GroupsAndContentTableRow.Group = CurrentGroup;
				GroupsAndContentTableRow.Content = GroupContent.Copy();
				GroupContent.Clear();
			EndIf;
			GroupContent.Add(ContentRow.User);
			
		CurrentGroup = ContentRow.UserGroup;
		EndIf;
		
	EndDo;
	
	GroupsAndContentTableRow = GroupsAndContentTable.Add();
	GroupsAndContentTableRow.Group = CurrentGroup;
	GroupsAndContentTableRow.Content = GroupContent.Copy();
	
	Return GroupsAndContentTable;
EndFunction

Function UserGroupContent(GroupRef, ExternalUser)
	
	GroupContent = New ValueList;
	For Each Item In GroupRef.Content Do
		
		If ExternalUser Then
			GroupContent.Add(Item.ExternalUser);
		Else
			GroupContent.Add(Item.User);
		EndIf;
		
	EndDo;
	
	Return GroupContent;
EndFunction

Function UserGroupFullContent(GroupsAndContentTable, GroupRef)
	
	FullGroupContent = GroupsAndContentTable.FindRows(New Structure("Group", GroupRef));
	If FullGroupContent.Count() <> 0 Then
		Return FullGroupContent[0].Content;
	EndIf;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Auxiliary procedures and functions

// Generates an array of reports that are available to the specified user.
//
// Parameters:
//  InfobaseUser - String - name of the infobase user whose 
//                 report access rights are checked.
//
// Returns:
//   Result - Array - keys of reports that are available to the specified user.
//
Function ReportsAvailableToUser(UserTarget)
	Result = New Array;
	
	InfobaseUser = InfobaseUsers.FindByName(UserTarget);
	For Each ReportMetadata In Metadata.Reports Do
		
		If AccessRight("View", ReportMetadata, InfobaseUser) Then
			Result.Add("Report." + ReportMetadata.Name);
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Gets a name of the infobase user by catalog reference.
// Parameters:
//  UserRef - CatalogRef - user whose infobase user name is retrieved.
//
// Returns:
//  String - infobase user name, or Undefined if the infobase user is not found.
// 
Function InfobaseUserName(UserRef) Export
	
	SetPrivilegedMode(True);
	InfobaseUserID = CommonUse.ObjectAttributeValue(UserRef, "InfobaseUserID");
	IBUser = InfobaseUsers.FindByUUID(InfobaseUserID);
	
	If IBUser <> Undefined Then
		Return IBUser.Name;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

Function PredefinedSettings()
	
	TaxiInterface = (ClientApplicationInterfaceCurrentVariant() = ClientApplicationInterfaceVariant.Taxi);
	
	FormSettingsArray = New Array;
	FormSettingsArray.Add("/FormSettings");
	If TaxiInterface Then
		FormSettingsArray.Add("Taxi/WindowSettings");
		FormSettingsArray.Add("Taxi/WebClientWindowSettings");
	Else
		FormSettingsArray.Add("/WindowSettings");
		FormSettingsArray.Add("/WebClientWindowSettings");
	EndIf;
	FormSettingsArray.Add("/CurrentData");
	FormSettingsArray.Add("/CurrentUserSettings");
	
	Return FormSettingsArray;
EndFunction

Function FormPresentation(Object, Form, MetadataObjectType)
	
	CanOpenForm = False;
	
	If MetadataObjectType = "FilterCriterion"
		Or MetadataObjectType = "DocumentJournal" Then
		
		If Form = Object.DefaultForm Then
			FormName = ListFormPresentation(Object);
			CanOpenForm = True;
		Else 
			FormName = Form.Synonym;
		EndIf;
		
	ElsIf MetadataObjectType = "AccumulationRegister"
		Or MetadataObjectType = "AccountingRegister"
		Or MetadataObjectType = "CalculationRegister" Then
		
		If Form = Object.DefaultListForm Then
			FormName = ListFormPresentation(Object);
			CanOpenForm = True;
		Else 
			FormName = Form.Synonym;
		EndIf;
		
	ElsIf MetadataObjectType = "InformationRegister" Then
		
		If Form = Object.DefaultRecordForm Then
			
			If Not IsBlankString(Object.ExtendedRecordPresentation) Then
				FormName = Object.ExtendedRecordPresentation;
			ElsIf Not IsBlankString(Object.RecordPresentation) Then
				FormName = Object.RecordPresentation;
			Else
				FormName = Object.Presentation();
			EndIf;
			
		ElsIf Form = Object.DefaultListForm Then
			FormName = ListFormPresentation(Object);
			CanOpenForm = True;
		Else 
			FormName = Form.Synonym;
		EndIf;
		
	ElsIf MetadataObjectType = "Report"
		Or MetadataObjectType = "DataProcessor" Then
		
		If Form = Object.DefaultForm Then
			If Not IsBlankString(Object.ExtendedPresentation) Then
				FormName = Object.ExtendedPresentation;
			Else
				FormName = Object.Presentation();
			EndIf;
			CanOpenForm = True;
		Else
			FormName = Form.Synonym;
		EndIf;
		
	ElsIf MetadataObjectType = "SettingsStorage" Then
		FormName = Form.Synonym;
	ElsIf MetadataObjectType = "Enum" Then
		
		If Form = Object.DefaultListForm
			Or Form = Object.DefaultChoiceForm Then
			FormName = ListFormPresentation(Object);
			CanOpenForm = ?(Form = Object.DefaultListForm, True, False);
		Else
			FormName = Form.Synonym;
		EndIf;
		
	ElsIf MetadataObjectType = "Catalog"
		Or MetadataObjectType = "ChartOfCharacteristicTypes" Then
		
		If Form = Object.DefaultListForm
			Or Form = Object.DefaultChoiceForm
			Or Form = Object.DefaultFolderForm 
			Or Form = Object.DefaultFolderChoiceForm Then
			
			FormName = ListFormPresentation(Object);
			AddFormTypeToPresentation(Object, Form, FormName);
			CanOpenForm = ?(Form = Object.DefaultListForm, True, False);
			
		ElsIf Form = Object.DefaultObjectForm Then
			FormName = ObjectFormPresentation(Object);
		Else
			FormName = Form.Synonym;
		EndIf;
		
	ElsIf MetadataObjectType = "ExternalDataSource" Then
		
		If Form = Object.DefaultListForm Then
			FormName = ListFormPresentation(Object);
			CanOpenForm = True;
		ElsIf Form = Object.DefaultRecordForm Then
			
			If Not IsBlankString(Object.ExtendedRecordPresentation) Then
				FormName = Object.ExtendedRecordPresentation ;
			ElsIf Not IsBlankString(Object.RecordPresentation) Then
				FormName = Object.RecordPresentation;
			Else
				FormName = Object.Presentation();
			EndIf;
			
		ElsIf Form = Object.DefaultObjectForm Then
			ObjectFormPresentation(Object);
		Else
			FormName = Form.Synonym;
		EndIf;
		
	Else // Getting form presentation for Document, Chart of accounts, Chart of calculation types, Business process, and Task
		
		If Form = Object.DefaultListForm
			Or Form = Object.DefaultChoiceForm Then
			FormName = ListFormPresentation(Object);
			CanOpenForm = ?(Form = Object.DefaultListForm, True, False);
		ElsIf Form = Object.DefaultObjectForm Then
			FormName = ObjectFormPresentation(Object);
		Else
			FormName = Form.Synonym;
		EndIf;
		
	EndIf;
	
	Return New Structure("FormName, CanOpenForm", FormName, CanOpenForm);
	
EndFunction

Function AutogeneratedFormPresentation(Object, Form, MetadataObjectType)
	
	CanOpenForm = False;
	
	If MetadataObjectType = "FilterCriterion"
		Or MetadataObjectType = "DocumentJournal" Then
		
		FormName = ListFormPresentation(Object);
		CanOpenForm = True;
		
	ElsIf MetadataObjectType = "AccumulationRegister"
		Or MetadataObjectType = "AccountingRegister"
		Or MetadataObjectType = "CalculationRegister" Then
		
		FormName = ListFormPresentation(Object);
		CanOpenForm = True;
		
	ElsIf MetadataObjectType = "InformationRegister" Then
		
		If Form = "RecordForm" Then
			
			If Not IsBlankString(Object.ExtendedRecordPresentation) Then
				FormName = Object.ExtendedRecordPresentation;
			ElsIf Not IsBlankString(Object.RecordPresentation) Then
				FormName = Object.RecordPresentation;
			Else
				FormName = Object.Presentation();
			EndIf;
			
		ElsIf Form = "ListForm" Then
			FormName = ListFormPresentation(Object);
			CanOpenForm = True;
		EndIf;
		
	ElsIf MetadataObjectType = "Report"
		Or MetadataObjectType = "DataProcessor" Then
		
		If Not IsBlankString(Object.ExtendedPresentation) Then
			FormName = Object.ExtendedPresentation;
		Else
			FormName = Object.Presentation();
		EndIf;
		CanOpenForm = True;
		
	ElsIf MetadataObjectType = "Enum" Then
		
		FormName = ListFormPresentation(Object);
		CanOpenForm = ?(Form = "ListForm", True, False);
		
	ElsIf MetadataObjectType = "Catalog"
		Or MetadataObjectType = "ChartOfCharacteristicTypes" Then
		
		If Form = "ListForm"
			Or Form = "ChoiceForm"
			Or Form = "FolderForm" 
			Or Form = "FolderChoiceForm" Then
			FormName = ListFormPresentation(Object);
			AddFormTypeToAutogeneratedFormPresentation(Object, Form, FormName);
			CanOpenForm = ?(Form = "ListForm", True, False);
		ElsIf Form = "ObjectForm" Then
			FormName = ObjectFormPresentation(Object);
		EndIf;
		
	ElsIf MetadataObjectType = "ExternalDataSource" Then
		
		If Form = "ListForm" Then
			FormName = ListFormPresentation(Object);
			CanOpenForm = True;
		ElsIf Form = "RecordForm" Then
			If Not IsBlankString(Object.ExtendedRecordPresentation) Then
				FormName = Object.ExtendedRecordPresentation ;
			ElsIf Not IsBlankString(Object.RecordPresentation) Then
				FormName = Object.RecordPresentation;
			Else
				FormName = Object.Presentation();
			EndIf;
		ElsIf Form = "ObjectForm" Then
			ObjectFormPresentation(Object);
		EndIf;
		
	Else // Getting form presentation for Document, Chart of accounts, Chart of calculation types, Business process, and Task
		
		If Form = "ListForm"
			Or Form = "ChoiceForm" Then
			FormName = ListFormPresentation(Object);
			CanOpenForm = ?(Form = "ListForm", True, False);
		ElsIf Form = "ObjectForm" Then
			FormName = ObjectFormPresentation(Object);
		EndIf;
		
	EndIf;
	
	Return New Structure("FormName, CanOpenForm", FormName, CanOpenForm);
	
EndFunction

Function ListFormPresentation(Object)
	
	If Not IsBlankString(Object.ExtendedListPresentation) Then
		FormName = Object.ExtendedListPresentation;
	ElsIf Not IsBlankString(Object.ListPresentation) Then
		FormName = Object.ListPresentation;
	Else
		FormName = Object.Presentation();
	EndIf;
	
	Return FormName;
EndFunction

Function ObjectFormPresentation(Object)
	
	If Not IsBlankString(Object.ExtendedObjectPresentation) Then
		FormName = Object.ExtendedObjectPresentation;
	ElsIf Not IsBlankString(Object.ObjectPresentation) Then
		FormName = Object.ObjectPresentation;
	Else
		FormName = Object.Presentation();
	EndIf;;
	
	Return FormName;
EndFunction

Procedure AddFormTypeToPresentation(Object, Form, FormName)
	
	If Form = Object.DefaultListForm Then
		FormName = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='%1 (list)'"), FormName);
	ElsIf Form = Object.DefaultChoiceForm Then
		FormName = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='%1 (choice)'"), FormName);
	ElsIf Form = Object.DefaultFolderForm Then
		FormName = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='%1 (group)'"), FormName);
	EndIf;
	
EndProcedure

Procedure AddFormTypeToAutogeneratedFormPresentation(Object, Form, FormName)
	
	If Form = "ListForm" Then
		FormName = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='%1 (list)'"), FormName);
	ElsIf Form = "ChoiceForm" Then
		FormName = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='%1 (choice)'"), FormName);
	ElsIf Form = "FolderChoiceForm" Then
		FormName = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='%1 (group)'"), FormName);
	EndIf;
	
EndProcedure

Procedure AddRowToValueTable(SettingsTable, SettingsSelection)
	
	If Find(SettingsSelection.ObjectKey, "ExternalReport.") <> 0 Then
		Return;
	EndIf;
	
	NewRow = SettingsTable.Add();
	NewRow.ObjectKey = SettingsSelection.ObjectKey;
	NewRow.SettingsKey = SettingsSelection.SettingsKey;
	
EndProcedure

Function ReportOptionPresentation(SettingsItemKey, ReportOptionName)
	
	ReportName = StringFunctionsClientServer.SplitStringIntoSubstringArray(ReportOptionName[0], ".");
	Report = Metadata.Reports.Find(ReportName[1]);
	
	If Report = Undefined Then
		Return Undefined;
	EndIf;
	
	VariantsStorage = Report.VariantsStorage;
	
	If VariantsStorage = Undefined Then
		VariantsStorage = Metadata.ReportsVariantsStorage;
	EndIf;
	
	If VariantsStorage = Undefined Then
		VariantsStorage = ReportsVariantsStorage;
	Else
		VariantsStorage = SettingsStorages[VariantsStorage.Name];
	EndIf;
	
	If ReportOptionName.Count() = 1 Then
		OptionID = ReportName[1];
	Else
		OptionID = ReportOptionName[1];
	EndIf;
	
	ReportOptionPresentation = VariantsStorage.GetDescription(ReportOptionName[0], OptionID);
	
	If ReportOptionPresentation <> Undefined
		Then
		Return ReportOptionPresentation.Presentation;
	Else
		Return ReportName[1];
	EndIf;
	
EndFunction

Function ReadSettingsFromStorage(SettingsManager, User)
	
	Settings = New ValueTable;
	Settings.Columns.Add("ObjectKey");
	Settings.Columns.Add("SettingsKey");
	Settings.Columns.Add("Presentation");
	
	Filter = New Structure;
	Filter.Insert("User", User);
	
	Ignore = False;
	SettingsSelection = SettingsManager.Select(Filter);
	While NextSettingsItem(SettingsSelection, Ignore) Do
		
		If Ignore Then
			Continue;
		EndIf;
		
		NewRow = Settings.Add();
		NewRow.ObjectKey = SettingsSelection.ObjectKey;
		NewRow.SettingsKey = SettingsSelection.SettingsKey;
		NewRow.Presentation = SettingsSelection.Presentation;
		
	EndDo;
	
	Return Settings;
	
EndFunction

Function UserReportOptions(InfobaseUser)
	
	ReportOptionTable = New ValueTable;
	ReportOptionTable.Columns.Add("ObjectKey");
	ReportOptionTable.Columns.Add("VariantKey");
	ReportOptionTable.Columns.Add("Presentation");
	ReportOptionTable.Columns.Add("StandardProcessing"); 
	
	For Each ReportMetadata In Metadata.Reports Do
		
		StandardProcessing = True;
		UsersInternal.OnReceiveUserReportOptions(ReportMetadata, InfobaseUser, ReportOptionTable, StandardProcessing);
		If StandardProcessing Then
			ReportOptions = ReportsVariantsStorage.GetList("Report." + ReportMetadata.Name, InfobaseUser);
			For Each ReportOption In ReportOptions Do
				ReportOptionRow = ReportOptionTable.Add();
				ReportOptionRow.ObjectKey = "Report." + ReportMetadata.Name;
				ReportOptionRow.VariantKey = ReportOption.Value;
				ReportOptionRow.Presentation = ReportOption.Presentation;
				ReportOptionRow.StandardProcessing = True;
			EndDo;
		EndIf;
		
	EndDo;
	
	Return ReportOptionTable;
	
EndFunction

Function UserSettingsKeys()
	
	KeyArray = New Array;
	KeyArray.Add("CurrentVariantKey");
	KeyArray.Add("CurrentUserSettingsKey");
	KeyArray.Add("CurrentUserSettings");
	KeyArray.Add("CurrentDataSettingsKey");
	KeyArray.Add("ClientSettings");
	KeyArray.Add("AddInSettings");
	KeyArray.Add("HelpSettings");
	KeyArray.Add("ComparisonSettings");
	KeyArray.Add("TableSearchParameters");
	
	Return KeyArray;
EndFunction

Function SettingsStorageByName(StorageName)
	
	If StorageName = "ReportsUserSettingsStorage" Then
		Return ReportsUserSettingsStorage;
	ElsIf StorageName = "CommonSettingsStorage" Then
		Return CommonSettingsStorage;
	Else
		Return SystemSettingsStorage;
	EndIf;
	
EndFunction

Procedure GenerateFilter(UserGroupList, GroupRef, GroupsArray)
	
	FilterParameters = New Structure("Parent", GroupRef);
	SelectedRows = UserGroupList.FindRows(FilterParameters);
	
	For Each Item In SelectedRows Do 
		GroupsArray.Add(Item);
	EndDo;
	
EndProcedure

Function GetReportOptionKeys(ReportOptionTable)
	
	ReportOptionKeyAndTypeTable = New ValueTable;
	ReportOptionKeyAndTypeTable.Columns.Add("VariantKey");
	ReportOptionKeyAndTypeTable.Columns.Add("Mark");
	For Each TableRow In ReportOptionTable Do
		ValueTableRow = ReportOptionKeyAndTypeTable.Add();
		ValueTableRow.VariantKey = TableRow.ObjectKey + "/" + TableRow.VariantKey;
		ValueTableRow.Check = TableRow.StandardProcessing;
	EndDo;
	
	Return ReportOptionKeyAndTypeTable;
EndFunction

Function CreateReportOnCopyingSettings(NotCopiedReportSettings,
										UserReportOptionTable = Undefined) Export
	
	Spreadsheet = New SpreadsheetDocument;
	TabTemplate = DataProcessors.ApplicationUserSettings.GetTemplate("ReportTemplate");
	
	ReportIsNotEmpty = False;
	If UserReportOptionTable <> Undefined
		And UserReportOptionTable.Count() <> 0 Then
		AreaTitle = TabTemplate.GetArea("Title");
		AreaTitle.Parameters.Details = NStr("en = '
			|Cannot copy user-defined report options.
			|If you want to make a user-defined report option
			|available to other users, clear the ""Available to author only"" check box and then save the report option.
			|List of skipped report options:'");
		Spreadsheet.Put(AreaTitle);
		
		Spreadsheet.Put(TabTemplate.GetArea("IsBlankString"));
		
		AreaContent = TabTemplate.GetArea("ReportContent");
		
		For Each TableRow In UserReportOptionTable Do
			
			If Not TableRow.StandardProcessing Then
				AreaContent.Parameters.Name = TableRow.Presentation;
				Spreadsheet.Put(AreaContent);
			EndIf;
			
		EndDo;
		
		ReportIsNotEmpty = True;
	EndIf;
	
	If NotCopiedReportSettings.Count() <> 0 Then
		AreaTitle = TabTemplate.GetArea("Title");
		AreaTitle.Parameters.Details = NStr("en = '
			|The following users have insufficient report access rights:'");
		Spreadsheet.Put(AreaTitle);
		
		AreaContent = TabTemplate.GetArea("ReportContent");
		
		For Each TableRow In NotCopiedReportSettings Do
			Spreadsheet.Put(TabTemplate.GetArea("IsBlankString"));
			AreaContent.Parameters.Name = TableRow.User + ":";
			Spreadsheet.Put(AreaContent);
			For Each ReportName In TableRow.ReportList Do
				AreaContent.Parameters.Name = ReportName.Value;
				Spreadsheet.Put(AreaContent);
			EndDo;
			
		EndDo;
		
	ReportIsNotEmpty = True;
	EndIf;
	
	If ReportIsNotEmpty Then
		Report = New SpreadsheetDocument;
		Report.Put(Spreadsheet);
		
		Return Report;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

Function SkipSettingsItem(ObjectKey, SettingsKey)
	
	ExceptionsByObjectKey = New Array;
	ExceptionsBySettingsKey = New Array;
	
	// Exceptions. Settings that cannot be copied.
	ExceptionsByObjectKey.Add("LocalFileCache");
	ExceptionsBySettingsKey.Add("PathToLocalFileCache");
	
	If ExceptionsByObjectKey.Find(ObjectKey) <> Undefined
		And ExceptionsBySettingsKey.Find(SettingsKey) <> Undefined Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for ApplicationUserSettings and SelectSettings forms.

Procedure FillSettingsLists(Form) Export
	
	FillReportSettingsList(Form);
	FillAppearanceSettingsList(Form);
	FillOtherSettingsList(Form);
	
EndProcedure

Procedure FillReportSettingsList(Form)
	
	FormName = StringFunctionsClientServer.SplitStringIntoSubstringArray(Form.FormName, ".");
	Form.ReportSettings.GetItems().Clear();
	ReportSettingsTree = Form.FormAttributeToValue("ReportSettings");
	ReportOptionTable = UserReportOptions(Form.InfobaseUser);
	UserReportOptions = Form.FormAttributeToValue("UserReportOptionTable");
	UserReportOptions.Clear();
	UserReportOptions = ReportOptionTable.Copy();
	
	Settings = ReadSettingsFromStorage(
		ReportsUserSettingsStorage, Form.InfobaseUser);
	
	CurrentObject = Undefined;
	
	For Each SettingsItem In Settings Do
		SettingsObject = SettingsItem.ObjectKey;
		SettingsItemKey = SettingsItem.SettingsKey;
		SettingName = SettingsItem.Presentation;
		
		ReportOptionName = StringFunctionsClientServer.SplitStringIntoSubstringArray(SettingsObject, "/");
		ReportOptionPresentation = ReportOptionPresentation(SettingsItemKey, ReportOptionName);
		
		// If the report or report option is deleted but its setting is not deleted, do not display it to user
		If ReportOptionPresentation = "" Then
			Continue;
		EndIf;
		
		// Checking whether the report option is a user-defined one
		FoundReportOption = ReportOptionTable.Find(ReportOptionName[1], "VariantKey");
		// If the settings selection form is opened, hide the settings that cannot be copied
		If FormName[3] = "SelectSettings"
			And FoundReportOption <> Undefined
			And Not FoundReportOption.StandardProcessing Then
			Continue;
		EndIf;
		
		If ReportOptionPresentation = Undefined Then
			Continue;
		EndIf;
		
		If Not IsBlankString(Form.Search) Then
			If Find(Upper(ReportOptionPresentation), Upper(Form.Search)) = 0
				And Find(Upper(SettingName), Upper(Form.Search)) = 0 Then
				Continue;
			EndIf;
		EndIf;
		
		// Filling a report option row
		If CurrentObject <> ReportOptionPresentation Then
			NewRowReportOption = ReportSettingsTree.Rows.Add();
			NewRowReportOption.Settings = ReportOptionPresentation;
			NewRowReportOption.Picture = PictureLib.Report;
			NewRowReportOption.Type =
				?(FoundReportOption <> Undefined, 
					?(Not FoundReportOption.StandardProcessing, "PersonalOption", "StandardOptionPersonal"), "StandardReportOption");
			NewRowReportOption.RowType = "Report" + ReportOptionPresentation;
		EndIf;
		// Filling a setting string
		NewRowSettingsItem = NewRowReportOption.Rows.Add();
		NewRowSettingsItem.Settings = ?(Not IsBlankString(SettingName), SettingName, ReportOptionPresentation);
		NewRowSettingsItem.Picture = PictureLib.Form;
		NewRowSettingsItem.Type = 
			?(FoundReportOption <> Undefined,
				?(Not FoundReportOption.StandardProcessing, "SettingsItemPersonal", "StandardSettingsItemPersonal"), "StandardReportSettings");
		NewRowSettingsItem.RowType = ReportOptionPresentation + SettingName;
		NewRowSettingsItem.Keys.Add(SettingsObject, SettingsItemKey);
		// Filling object key and settings item key for a report option
		NewRowReportOption.Keys.Add(SettingsObject, SettingsItemKey);
		
		CurrentObject = ReportOptionPresentation;
		
		// Deleting reports that have settings from the list of user-defined report options
		If FoundReportOption <> Undefined Then
			ReportOptionTable.Delete(FoundReportOption);
		EndIf;
		
	EndDo;
	
	For Each ReportOption In ReportOptionTable Do
		
		If FormName[3] = "SelectSettings"
			And Form.SettingsOperations = "Copy"
			And Not ReportOption.StandardProcessing Then
			Continue;
		EndIf;
		
		If Not IsBlankString(Form.Search) Then
			
			If Find(Upper(ReportOption.Presentation), Upper(Form.Search)) = 0 Then
				Continue;
			EndIf;
			
		EndIf;
		
		NewRowReportOption = ReportSettingsTree.Rows.Add();
		NewRowReportOption.Settings = ReportOption.Presentation;
		NewRowReportOption.Picture = PictureLib.Report;
		NewRowReportOption.Keys.Add(ReportOption.ObjectKey + "/" + ReportOption.VariantKey);
		NewRowReportOption.Type = ?(Not ReportOption.StandardProcessing, "PersonalOption", "StandardOptionPersonal");
		NewRowReportOption.RowType = "Report" + ReportOption.Presentation;
		
	EndDo;
	
	ReportSettingsTree.Rows.Sort("Settings Asc", True);
	Form.ValueToFormAttribute(ReportSettingsTree, "ReportSettings");
	Form.ValueToFormAttribute(UserReportOptions, "UserReportOptionTable");
	
EndProcedure

Procedure AddDesktopAndCommandInterfaceSettings(Form, SettingsTree)
	
	If Not IsBlankString(Form.Search) Then
		If Find(Upper(NStr("en='Desktop and command interface'")), Upper(Form.Search)) = 0 Then
			Return;
		EndIf;
	EndIf;
	
	Settings = ReadSettingsFromStorage(SystemSettingsStorage, Form.InfobaseUser);
	DesktopSettingsKeys = New ValueList;
	InterfaceSettingsKeys = New ValueList;
	AllSettingsKeys = New ValueList; 
	
	For Each Settings In Settings Do
		SettingName = StringFunctionsClientServer.SplitStringIntoSubstringArray(Settings.ObjectKey, "/");
		SettingsItemNamePart = StringFunctionsClientServer.SplitStringIntoSubstringArray(SettingName[0], ".");
		If SettingsItemNamePart[0] = "Subsystem" Then
			
			InterfaceSettingsKeys.Add(Settings.ObjectKey, "Interface");
			AllSettingsKeys.Add(Settings.ObjectKey, "Interface");
			
		ElsIf SettingName[0] = "Common" Then
			
			If SettingName[1] = "SectionsPanel"
				Or SettingName[1] = "ActionsPanel" 
				Or SettingName[1] = "ClientSettings" 
				Or SettingName[1] = "ClientApplicationInterfaceSettings" Then
				InterfaceSettingsKeys.Add(Settings.ObjectKey, "Interface");
				AllSettingsKeys.Add(Settings.ObjectKey, "Interface");
			ElsIf SettingName[1] = "DesktopSettings" Then
				DesktopSettingsKeys.Add(Settings.ObjectKey, "Interface");
				AllSettingsKeys.Add(Settings.ObjectKey, "Interface");
			EndIf;
			
		ElsIf SettingName[0] = "Desktop" Then
			
			If SettingName[1] = "WindowSettings" Then
				DesktopSettingsKeys.Add(Settings.ObjectKey, "Interface");
				AllSettingsKeys.Add(Settings.ObjectKey, "Interface");
			Else
				InterfaceSettingsKeys.Add(Settings.ObjectKey, "Interface");
				AllSettingsKeys.Add(Settings.ObjectKey, "Interface");
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If AllSettingsKeys.Count() > 0 Then
		// Adding top-level groups for desktop settings and command-interface settings
		NewInterfaceRow = SettingsTree.Rows.Add();
		NewInterfaceRow.Settings = NStr("en='Desktop and command interface'");
		NewInterfaceRow.Picture = PictureLib.Picture;
		NewInterfaceRow.RowType = NStr("en='Desktop and command interface'");
		NewInterfaceRow.Type = "AppearanceSettings";
		NewInterfaceRow.Keys = AllSettingsKeys.Copy();
	EndIf;
	
	If DesktopSettingsKeys.Count() > 0 Then
		// Creating a desktop settings row
		NewSubordinateInterfaceRow = NewInterfaceRow.Rows.Add();
		NewSubordinateInterfaceRow.Settings = NStr("en='Desktop'");
		NewSubordinateInterfaceRow.Picture = PictureLib.Picture;
		NewSubordinateInterfaceRow.RowType = "DesktopSettings";
		NewSubordinateInterfaceRow.Type = "AppearanceSettings";
		NewSubordinateInterfaceRow.Keys = DesktopSettingsKeys.Copy();
	EndIf;
	
	If InterfaceSettingsKeys.Count() > 0 Then
		// Creating a command interface settings row
		NewSubordinateInterfaceRow = NewInterfaceRow.Rows.Add();
		NewSubordinateInterfaceRow.Settings = NStr("en='Command interface'");
		NewSubordinateInterfaceRow.Picture = PictureLib.Picture;
		NewSubordinateInterfaceRow.RowType = "CommandInterfaceSettings";
		NewSubordinateInterfaceRow.Type = "AppearanceSettings";
		NewSubordinateInterfaceRow.Keys = InterfaceSettingsKeys.Copy();
	EndIf;
	
EndProcedure

Procedure FillAppearanceSettingsList(Form)
	
	Form.Appearance.GetItems().Clear();
	AppearanceSettings = Form.FormAttributeToValue("Appearance");
	
	CurrentObject = Undefined;
	FormSettings = AllFormSettings(Form.InfobaseUser);
	
	For Each FormSettingsItem In FormSettings Do
		MetadataObjectName = StringFunctionsClientServer.SplitStringIntoSubstringArray(FormSettingsItem.Value, ".");
		MetadataObjectPresentation = StringFunctionsClientServer.SplitStringIntoSubstringArray(FormSettingsItem.Presentation, ".");
		
		If Not IsBlankString(Form.Search) Then
			
			If Find(Upper(FormSettingsItem.Presentation), Upper(Form.Search)) = 0 Then
				Continue;
			EndIf;
			
		EndIf;

		If MetadataObjectName[0] = "CommonForm" Then
			NewRowCommonForm = AppearanceSettings.Rows.Add();
			NewRowCommonForm.Settings = FormSettingsItem.Presentation;
			NewRowCommonForm.Picture = PictureLib.Form;
			NewRowCommonForm.Keys.Add(FormSettingsItem.Value, "");
			NewRowCommonForm.Type = "AppearanceSettings";
			NewRowCommonForm.RowType = "CommonForm" + MetadataObjectName[1];
		ElsIf MetadataObjectName[0] = "SettingsStorage" Then
			NewRowSettingsStorage = AppearanceSettings.Rows.Add();
			NewRowSettingsStorage.Settings = FormSettingsItem.Presentation;
			NewRowSettingsStorage.Picture = PictureLib.Form;
			NewRowSettingsStorage.Keys.Add(FormSettingsItem.Value, "");
			NewRowSettingsStorage.RowType = "SettingsStorage" + MetadataObjectName[2];
			NewRowSettingsStorage.Type = "AppearanceSettings";
		ElsIf MetadataObjectPresentation[0] = NStr("en = 'Standard'") Then
			
			// Settings tree group
			If CurrentObject <> MetadataObjectPresentation[0] Then
				NewRowMetadataObject = AppearanceSettings.Rows.Add();
				NewRowMetadataObject.Settings = MetadataObjectPresentation[0];
				NewRowMetadataObject.Picture = FormSettingsItem.Picture;
				NewRowMetadataObject.RowType = "Object" + MetadataObjectName[1];
				NewRowMetadataObject.Type = "AppearanceSettings";
			EndIf;
			
			// Settings tree element
			NewRowFormAppearance = NewRowMetadataObject.Rows.Add();
			NewRowFormAppearance.Settings = MetadataObjectPresentation[1];
			NewRowFormAppearance.Picture = PictureLib.Form;
			NewRowFormAppearance.RowType = MetadataObjectName[1] + MetadataObjectName[2];
			NewRowFormAppearance.Type = "AppearanceSettings";
			NewRowFormAppearance.Keys.Add(FormSettingsItem.Value, "", FormSettingsItem.Check);
			NewRowMetadataObject.Keys.Add(FormSettingsItem.Value, "", FormSettingsItem.Check);
			
			CurrentObject = MetadataObjectPresentation[0];
			
		Else
			
			// Settings tree group
			If CurrentObject <> MetadataObjectName[1] Then
				NewRowMetadataObject = AppearanceSettings.Rows.Add();
				NewRowMetadataObject.Settings = MetadataObjectPresentation[0];
				NewRowMetadataObject.Picture = FormSettingsItem.Picture;
				NewRowMetadataObject.RowType = "Object" + MetadataObjectName[1];
				NewRowMetadataObject.Type = "AppearanceSettings";
			EndIf;
			
			// Settings tree element
			If MetadataObjectName.Count() = 3 Then
				FormName = MetadataObjectName[2];
			Else
				FormName = MetadataObjectName[3];
			EndIf;
			
			NewRowFormAppearance = NewRowMetadataObject.Rows.Add();
			NewRowFormAppearance.Settings = MetadataObjectPresentation[1];
			NewRowFormAppearance.Picture = PictureLib.Form;
			NewRowFormAppearance.RowType = MetadataObjectName[1] + FormName;
			NewRowFormAppearance.Type = "AppearanceSettings";
			NewRowFormAppearance.Keys.Add(FormSettingsItem.Value, "", FormSettingsItem.Check);
			NewRowMetadataObject.Keys.Add(FormSettingsItem.Value, "", FormSettingsItem.Check);
			
			CurrentObject = MetadataObjectName[1];
		EndIf;
		
	EndDo;
	
	AddDesktopAndCommandInterfaceSettings(Form, AppearanceSettings);
	
	AppearanceSettings.Rows.Sort("Settings Asc", True);
	DesktopAndCommandInterface = AppearanceSettings.Rows.Find(NStr("en='Desktop and command interface'"), "Settings");
	
	If DesktopAndCommandInterface <> Undefined Then
		LineIndex = AppearanceSettings.Rows.IndexOf(DesktopAndCommandInterface);
		AppearanceSettings.Rows.Move(LineIndex, -LineIndex);
	EndIf;
	
	Form.ValueToFormAttribute(AppearanceSettings, "Appearance");
	
EndProcedure

Procedure FillOtherSettingsList(Form)
	
	Form.OtherSettings.GetItems().Clear();
	OtherSettingsTree = Form.FormAttributeToValue("OtherSettings");
	Settings = ReadSettingsFromStorage(CommonSettingsStorage, Form.InfobaseUser);
	Keys = New ValueList;
	OtherKeys = New ValueList;
	
	// Filling personal settings
	For Each SettingsItem In Settings Do
		Keys.Add(SettingsItem.ObjectKey, SettingsItem.SettingsKey);
	EndDo;
	
	DisplaySettingsItem = True;
	If Keys.Count() > 0 Then
		
		If Not IsBlankString(Form.Search) Then
			If Find(Upper(NStr("en='Personal settings'")), Upper(Form.Search)) = 0 Then
				DisplaySettingsItem = False;
			EndIf;
		EndIf;
		
		If DisplaySettingsItem Then
			Settings = NStr("en='Personal settings'");
			SettingType = "PersonalSettings";
			Picture = PictureLib.UserState02;
			AddTreeRow(OtherSettingsTree, Settings, Picture, Keys, SettingType);
		EndIf;
		
	EndIf;
	
	// Filling print settings and favorites settings
	Settings = ReadSettingsFromStorage(SystemSettingsStorage, Form.InfobaseUser);
	
	Keys.Clear();
	HasFavorites = False;
	HasPrintSettings = False;
	KeyEnds = UserSettingsKeys();
	For Each SettingsItem In Settings Do
		
		SettingName = StringFunctionsClientServer.SplitStringIntoSubstringArray(SettingsItem.ObjectKey, "/");
		If SettingName.Count() = 1 Then
			Continue;
		EndIf;
		
		If KeyEnds.Find(SettingName[1]) <> Undefined Then
			OtherKeys.Add(SettingsItem.ObjectKey, "Other");
		EndIf;
		
		If SettingName[1] = "UserWorkFavorites" Then
			HasFavorites = True;
		ElsIf SettingName[1] = "SpreadsheetDocumentPrintSettings" Then
			Keys.Add(SettingsItem.ObjectKey, "Other");
			HasPrintSettings = True;
		EndIf;
		
	EndDo;
	
	// Adding print settings tree row
	DisplaySettingsItem = True;
	If Not IsBlankString(Form.Search) Then
		
		If Find(Upper(NStr("en='Spreadsheet document print settings'")), Upper(Form.Search)) = 0 Then
			DisplaySettingsItem = False;
		EndIf;
		
	EndIf;
	
	If HasPrintSettings
		And DisplaySettingsItem Then
		Settings = NStr("en='Spreadsheet document print settings'");
		Picture = PictureLib.Print;
		SettingType = "OtherSetting";
		AddTreeRow(OtherSettingsTree, Settings, Picture, Keys, SettingType);
	EndIf;
	
	// Adding favorites tree row
	DisplaySettingsItem = True;
	If Not IsBlankString(Form.Search) Then
		
		If Find(Upper(NStr("en='Favorites'")), Upper(Form.Search)) = 0 Then
			DisplaySettingsItem = False;
		EndIf;
		
	EndIf;
	
	If HasFavorites
		And DisplaySettingsItem Then
		
		Settings = NStr("en='Favorites'");
		Picture = PictureLib.AddToFavorites;
		Keys.Clear();
		Keys.Add("Common/UserWorkFavorites", "Other");
		SettingType = "OtherSetting";
		AddTreeRow(OtherSettingsTree, Settings, Picture, Keys, SettingType);
		
	EndIf;
	
	// Adding other settings supported by the configuration
	OtherSettings = New Structure;
	UserInfo = New Structure;
	UserInfo.Insert("UserRef", Form.UserRef);
	UserInfo.Insert("InfobaseUserName", Form.InfobaseUser);
	
	UsersInternal.OnGetOtherSettings(UserInfo, OtherSettings);
	Keys = New ValueList;
	
	If OtherSettings <> Undefined Then
		
		For Each OtherSetting In OtherSettings Do
			
			Result = OtherSetting.Value;
			If Result.SettingsList.Count() <> 0 Then
				
				DisplaySettingsItem = True;
				If Not IsBlankString(Form.Search) Then
					
					If Find(Upper(Result.SettingName), Upper(Form.Search)) = 0 Then
						DisplaySettingsItem = False;
					EndIf;
					
				EndIf;
				
				If DisplaySettingsItem Then
					
					If OtherSetting.Key = "QuickAccessSettingsItem" Then
						For Each Item In Result.SettingsList Do
							SettingValue = Item[0];
							SettingID = Item[1];
							Keys.Add(SettingValue, SettingID);
						EndDo;
					Else
						Keys = Result.SettingsList.Copy();
					EndIf;
					
					Settings = Result.SettingName;
					If Result.SettingPicture = "" Then
						Picture = PictureLib.OtherUserSettings;
					Else
						Picture = Result.SettingPicture;
					EndIf;
					Type = "OtherUserSettingsItem";
					SettingType = OtherSetting.Key;
					AddTreeRow(OtherSettingsTree, Settings, Picture, Keys, Type, SettingType);
					Keys.Clear();
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	// Other settings that are not included in other sections
	DisplaySettingsItem = True;
	If Not IsBlankString(Form.Search) Then
		
		If Find(Upper(NStr("en='Other settings'")), Upper(Form.Search)) = 0 Then
			DisplaySettingsItem = False;
		EndIf;
		
	EndIf;
	
	If OtherKeys.Count() <> 0
		And DisplaySettingsItem Then
		Settings = NStr("en='Other settings'");
		Picture = PictureLib.OtherUserSettings;
		SettingType = "OtherSetting";
		AddTreeRow(OtherSettingsTree, Settings, Picture, OtherKeys, SettingType);
	EndIf;
	
	Form.ValueToFormAttribute(OtherSettingsTree, "OtherSettings");
	
EndProcedure

Procedure AddTreeRow(ValueTree, Settings, Picture, Keys, Type = "", RowType = "")
	
	NewRow = ValueTree.Rows.Add();
	NewRow.Settings = Settings;
	NewRow.Picture = Picture;
	NewRow.Type = Type;
	NewRow.RowType = ?(RowType <> "", RowType, Type);
	NewRow.Keys = Keys.Copy();
	
EndProcedure

#EndRegion

#EndIf