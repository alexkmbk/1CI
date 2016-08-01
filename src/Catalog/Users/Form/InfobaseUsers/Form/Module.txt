
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	// Skipping the initialization to guarantee that the form will be received if the Autotest parameter is passed.
	If Parameters.Property("Autotest") Then 		Return;
	EndIf;
	
	If Not Users.InfobaseUserWithFullAccess(, CommonUseCached.ApplicationRunMode().Local) Then
		Raise NStr("en = 'Insufficient rights to open infobase user list.'");
	EndIf;
	
	Users.FindAmbiguousInfobaseUsers();
	
	UserTypes.Add(Type("CatalogRef.Users"));
	If GetFunctionalOption("UseExternalUsers") Then
		UserTypes.Add(Type("CatalogRef.ExternalUsers"));
	EndIf;
	
	ShowOnlyProcessedInDesignerItems = True;
	
	FillInfobaseUsers();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "InfobaseUserAdded"
	 Or EventName = "InfobaseUserChanged"
	 Or EventName = "InfobaseUserDeleted"
	 Or EventName = "MappingToNonExistentInfobaseUserCleared" Then
		
		FillInfobaseUsers();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemEventHandlers

&AtClient
Procedure ShowOnlyProcessedInDesignerItemsOnChange(Item)
	
	FillInfobaseUsers();
	
EndProcedure

#EndRegion

#Region InfobaseUsersFormTableElementsEventHandlers

&AtClient
Procedure InfobaseUsersOnActivateRow(Item)
	
	CurrentData = Items.InfbaseUsers.CurrentData;
	
	If CurrentData = Undefined Then
		CanDelete     = False;
		CanMap = False;
		CanGoToUser  = False;
		CanClearMapping = False;
	Else
		CanDelete     = Not ValueIsFilled(CurrentData.Ref);
		CanMap = Not ValueIsFilled(CurrentData.Ref);
		CanGoToUser  = ValueIsFilled(CurrentData.Ref);
		CanClearMapping = ValueIsFilled(CurrentData.Ref);
	EndIf;
	
	Items.InfobaseUsersDelete.Enabled              = CanDelete;
	
	Items.InfobaseUsersGoToUser.Enabled            = CanGoToUser;
	Items.InfobaseUsersContextMenuGoToUser.Enabled = CanGoToUser;
	
	Items.InfobaseUsersMap.Enabled                 = CanMap;
	Items.InfobaseUsersMapWithNewItem.Enabled      = CanMap;
	
	Items.InfobaseUsersClearMapping.Enabled        = CanClearMapping;
	
EndProcedure

&AtClient
Procedure InfobaseUsersBeforeDelete(Item, Cancel)
	
	Cancel = True;
	
	If Not ValueIsFilled(Items.InfbaseUsers.CurrentData.Ref) Then
		DeleteCurrentInfobaseUser(True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Refresh(Command)
	
	FillInfobaseUsers();
	
EndProcedure

&AtClient
Procedure Map(Command)
	
	MapInfobaseUser();
	
EndProcedure

&AtClient
Procedure MapWithNewItem(Command)
	
	MapInfobaseUser(True);
	
EndProcedure

&AtClient
Procedure GoToUser(Command)
	
	OpenUserByRef();
	
EndProcedure

&AtClient
Procedure ClearMapping(Command)
	
	If Items.InfbaseUsers.CurrentData = Undefined Then
		Return;
	EndIf;
	
	Buttons = New ValueList;
	Buttons.Add("ClearMapping", NStr("en = 'Clear mapping'"));
	Buttons.Add("KeepMapping", NStr("en = 'Keep mapping'"));
	
	ShowQueryBox(
		New NotifyDescription("ClearMappingContinue", ThisObject),
		NStr("en = 'Clearing the mapping between the infobase user and the user from catalog.
		           |
		           |The clearing is rarely necessary. It is only needed if the mapping was set incorrectly, 
              |(for example, it was set durring infobase update). 
              |We recommend that you do not clear mapping for any other reason.'"),
		Buttons,
		,
		"KeepMapping");
		
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();



	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FullName.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Name.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StandardAuthentication.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OSAuthentication.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OSUser.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OpenIDAuthentication.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InfobaseUsers.AddedInDesigner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);

 

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FullName.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Name.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StandardAuthentication.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OSAuthentication.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OSUser.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OpenIDAuthentication.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InfobaseUsers.ModifiedInDesigner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InfobaseUsers.DeletedInDesigner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleDataColor);

 

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Name.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StandardAuthentication.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OSAuthentication.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OpenIDAuthentication.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InfobaseUsers.DeletedInDesigner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Text", NStr("en = '<No data>'"));
	Item.Appearance.SetParameterValue("Format", "L=en; BF=None; BT=Yes");

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OSAuthentication.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InfobaseUsers.OSUser");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Format", "L=en; BF=; BT=Yes");

EndProcedure

&AtServer
Procedure FillInfobaseUsers()
	
	EmptyUUID = New UUID("00000000-0000-0000-0000-000000000000");
	
	If Items.InfbaseUsers.CurrentRow <> Undefined Then
		Row = InfbaseUsers.FindByID(Items.InfbaseUsers.CurrentRow);
	Else
		Row = Undefined;
	EndIf;
	
	CurrentInfobaseUserID =
		?(Row = Undefined, EmptyUUID, Row.InfobaseUserID);
	
	InfbaseUsers.Clear();
	NonExistentInfobaseUserIDs.Clear();
	NonExistentInfobaseUserIDs.Add(EmptyUUID);
	
	Query = New Query;
	Query.SetParameter("EmptyUUID", EmptyUUID);
	Query.Text =
	"SELECT
	|	Users.Ref AS Ref,
	|	Users.Description AS FullName,
	|	Users.InfobaseUserID,
	|	FALSE AS IsExternalUser
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.InfobaseUserID <> &EmptyUUID
	|
	|UNION ALL
	|
	|SELECT
	|	ExternalUsers.Ref,
	|	ExternalUsers.Description,
	|	ExternalUsers.InfobaseUserID,
	|	TRUE
	|FROM
	|	Catalog.ExternalUsers AS ExternalUsers
	|WHERE
	|	ExternalUsers.InfobaseUserID <> &EmptyUUID";
	
	Data = Query.Execute().Unload();
	Data.Indexes.Add("InfobaseUserID");
	Data.Columns.Add("Mapped", New TypeDescription("Boolean"));
	
	IBUsers = InfobaseUsers.GetUsers();
	
	For Each IBUser In IBUsers Do
		InfobaseUserProperties = Users.NewInfobaseUserInfo();
		Users.ReadInfobaseUser(IBUser.UUID, InfobaseUserProperties);
		
		ModifiedInDesigner = False;
		Row = Data.Find(InfobaseUserProperties.UUID, "InfobaseUserID");
		
		If Row <> Undefined Then
			Row.Mapped = True;
			If Row.FullName <> InfobaseUserProperties.FullName Then
				ModifiedInDesigner = True;
			EndIf;
		EndIf;
		
		If ShowOnlyProcessedInDesignerItems
		   And Row <> Undefined
		   And Not ModifiedInDesigner Then
			
			Continue;
		EndIf;
		
		NewRow = InfbaseUsers.Add();
		NewRow.FullName               = InfobaseUserProperties.FullName;
		NewRow.Name                   = InfobaseUserProperties.Name;
		NewRow.StandardAuthentication = InfobaseUserProperties.StandardAuthentication;
		NewRow.OSAuthentication       = InfobaseUserProperties.OSAuthentication;
		NewRow.InfobaseUserID         = InfobaseUserProperties.UUID;
		NewRow.OSUser                 = InfobaseUserProperties.OSUser;
		NewRow.OpenIDAuthentication   = InfobaseUserProperties.OpenIDAuthentication;
		
		If Row = Undefined Then
			// Infobase user is not in the catalog.
			NewRow.AddedInDesigner = True;
		Else
			NewRow.Ref                    = Row.Ref;
			NewRow.MappedToExternalUser = Row.IsExternalUser;
			
			NewRow.ModifiedInDesigner = ModifiedInDesigner;
		EndIf;
		
	EndDo;
	
	Filter = New Structure("Mapped", False);
	Rows = Data.FindRows(Filter);
	For Each Row In Rows Do
		NewRow = InfbaseUsers.Add();
		NewRow.FullName               = Row.FullName;
		NewRow.Ref                    = Row.Ref;
		NewRow.MappedToExternalUser = Row.IsExternalUser;
		NewRow.DeletedInDesigner      = True;
		NonExistentInfobaseUserIDs.Add(Row.InfobaseUserID);
	EndDo;
	
	Filter = New Structure("InfobaseUserID", CurrentInfobaseUserID);
	Rows = InfbaseUsers.FindRows(Filter);
	If Rows.Count() > 0 Then
		Items.InfbaseUsers.CurrentRow = Rows[0].GetID();
	EndIf;
	
EndProcedure

&AtServer
Procedure DeleteInfobaseUser(InfobaseUserID, Cancel)
	
	ErrorDescription = "";
	If Not Users.DeleteInfobaseUser(InfobaseUserID, ErrorDescription) Then
		CommonUseClientServer.MessageToUser(ErrorDescription, , , , Cancel);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenUserByRef()
	
	CurrentData = Items.InfbaseUsers.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(CurrentData.Ref) Then
		OpenForm(
			?(CurrentData.MappedToExternalUser,
				"Catalog.ExternalUsers.ObjectForm",
				"Catalog.Users.ObjectForm"),
			New Structure("Key", CurrentData.Ref));
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteCurrentInfobaseUser(DeleteRow = False)
	
	ShowQueryBox(
		New NotifyDescription("DeleteCurrentInfobaseUserEnd", ThisObject, DeleteRow),
		NStr("en = 'Do you want to delete the infobase user?'"),
		QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure DeleteCurrentInfobaseUserEnd(Answer, DeleteRow) Export
	
	If Answer = DialogReturnCode.Yes Then
		Cancel = False;
		DeleteInfobaseUser(
			Items.InfbaseUsers.CurrentData.InfobaseUserID, Cancel);
		
		If Not Cancel And DeleteRow Then
			InfbaseUsers.Delete(Items.InfbaseUsers.CurrentData);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure MapInfobaseUser(WithNew = False)
	
	If UserTypes.Count() > 1 Then
		UserTypes.ShowChooseItem(
			New NotifyDescription("MapInfobaseUserForItemType", ThisObject, WithNew),
			NStr("en = 'Select data type'"),
			UserTypes[0]);
	Else
		MapInfobaseUserForItemType(UserTypes[0], WithNew);
	EndIf;
	
EndProcedure

&AtClient
Procedure MapInfobaseUserForItemType(ListItem, WithNew) Export
	
	If ListItem = Undefined Then
		Return;
	EndIf;
	
	CatalogName = ?(ListItem.Value = Type("CatalogRef.Users"), "Users", "ExternalUsers");
	
	If Not WithNew Then
		FormParameters = New Structure;
		FormParameters.Insert("ChoiceMode", True);
		FormParameters.Insert("NonExistentInfobaseUserIDs", NonExistentInfobaseUserIDs);
		
		OpenForm("Catalog." + CatalogName + ".ChoiceForm", FormParameters,,,,,
			New NotifyDescription("MapInfobaseUserToElement", ThisObject, CatalogName));
	Else
		MapInfobaseUserToElement("New", CatalogName);
	EndIf;
	
EndProcedure

&AtClient
Procedure MapInfobaseUserToElement(Item, CatalogName) Export
	
	If Not ValueIsFilled(Item) And Item <> "New" Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	
	If Item <> "New" Then
		FormParameters.Insert("Key", Item);
	EndIf;
	
	FormParameters.Insert("InfobaseUserID",
		Items.InfbaseUsers.CurrentData.InfobaseUserID);
	
	OpenForm("Catalog." + CatalogName + ".ObjectForm", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure ClearMappingContinue(Answer, NotDefined) Export
	
	If Answer = "ClearMapping" Then
		ClearMappingAtServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure ClearMappingAtServer()
	
	CurrentRow = InfbaseUsers.FindByID(
	Items.InfbaseUsers.CurrentRow);
	
	Object = CurrentRow.Ref.GetObject();
	Object.InfobaseUserID = Undefined;
	Object.DataExchange.Load = True;
	Object.Write();
	
	FillInfobaseUsers();
	
EndProcedure

#EndRegion
