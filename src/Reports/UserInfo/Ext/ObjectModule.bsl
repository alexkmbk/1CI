#If Server OR ThickClientOrdinaryApplication OR ExternalConnection Then

////////////////////////////////////////////////////////////////////////////////
// OBJECT EVENT HANDLERS

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	ResultDocument.Clear();
	
	TemplateComposer = New DataCompositionTemplateComposer;
	Settings = SettingsComposer.GetSettings();
	
	NonExistentInfobaseUserIDs = New Array;
	
	ExternalDataSets = New Structure;
	ExternalDataSets.Insert("InfobaseUsers", InfobaseUsers(NonExistentInfobaseUserIDs));
	ExternalDataSets.Insert("ContactInformation", ContactInformation(Settings));
	
	Settings.DataParameters.SetParameterValue(
		"NonExistentInfobaseUserIDs", NonExistentInfobaseUserIDs);
	
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, Settings, DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets, DetailsData, True);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	OutputProcessor.BeginOutput();
	ResultItem = CompositionProcessor.Next();
	While ResultItem <> Undefined Do
		OutputProcessor.OutputItem(ResultItem);
		ResultItem = CompositionProcessor.Next();
	EndDo;
	OutputProcessor.EndOutput();
	
EndProcedure

#Region InternalProceduresAndFunctions

Function InfobaseUsers(NonExistentInfobaseUserIDs)
	
	EmptyUUID = New UUID("00000000-0000-0000-0000-000000000000");
	NonExistentInfobaseUserIDs.Add(EmptyUUID);
	
	Query = New Query;
	Query.SetParameter("EmptyUUID", EmptyUUID);
	Query.Text =
	"SELECT
	|	Users.InfobaseUserID,
	|	Users.InfobaseUserProperties
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.InfobaseUserID <> &EmptyUUID
	|
	|UNION ALL
	|
	|SELECT
	|	ExternalUsers.InfobaseUserID,
	|	ExternalUsers.InfobaseUserProperties
	|FROM
	|	Catalog.ExternalUsers AS ExternalUsers
	|WHERE
	|	ExternalUsers.InfobaseUserID <> &EmptyUUID";
	
	Data = Query.Execute().Unload();
	Data.Indexes.Add("InfobaseUserID");
	Data.Columns.Add("Mapped", New TypeDescription("Boolean"));
	
	InfobaseUsersTable = InfobaseUsers.GetUsers();
	InfobaseUsersTable = New ValueTable;
	InfobaseUsersTable.Columns.Add("UUID", New TypeDescription("UUID"));
	InfobaseUsersTable.Columns.Add("Name", New TypeDescription("String",,,, New StringQualifiers(100)));
	InfobaseUsersTable.Columns.Add("CanLogOnToApplication",     New TypeDescription("Boolean"));
	InfobaseUsersTable.Columns.Add("StandardAuthentication",    New TypeDescription("Boolean"));
	InfobaseUsersTable.Columns.Add("ShowInList",                New TypeDescription("Boolean"));
	InfobaseUsersTable.Columns.Add("CannotChangePassword",      New TypeDescription("Boolean"));
	InfobaseUsersTable.Columns.Add("OpenIDAuthentication",      New TypeDescription("Boolean"));
	InfobaseUsersTable.Columns.Add("OSAuthentication",          New TypeDescription("Boolean"));
	InfobaseUsersTable.Columns.Add("OSUser",                    New TypeDescription("String",,,, New StringQualifiers(1024)));
	InfobaseUsersTable.Columns.Add("Language",                  New TypeDescription("String",,,, New StringQualifiers(100)));
	InfobaseUsersTable.Columns.Add("RunMode",                   New TypeDescription("String",,,, New StringQualifiers(100)));
	
	AllInfobaseUsers = InfobaseUsers.GetUsers();
	
	For Each IBUser In AllInfobaseUsers Do
		InfobaseUserProperties = Users.NewInfobaseUserInfo();
		Users.ReadInfobaseUser(IBUser.UUID, InfobaseUserProperties);
		NewRow = InfobaseUsersTable.Add();
		FillPropertyValues(NewRow, InfobaseUserProperties);
		Language = InfobaseUserProperties.Language;
		NewRow.Language = ?(ValueIsFilled(Language), Metadata.Languages[Language].Synonym, "");
		NewRow.CanLogOnToApplication = Users.CanLogOnToApplication(InfobaseUserProperties);
		
		Row = Data.Find(InfobaseUserProperties.UUID, "InfobaseUserID");
		If Row <> Undefined Then
			Row.Mapped = True;
			If Not NewRow.CanLogOnToApplication Then
				FillPropertyValues(NewRow,
					UsersInternal.InfobaseUserStoredProperties(Row));
			EndIf;
		EndIf;
	EndDo;
	
	Filter = New Structure("Mapped", False);
	Rows = Data.FindRows(Filter);
	For Each Row In Rows Do
		NonExistentInfobaseUserIDs.Add(Row.InfobaseUserID);
	EndDo;
	
	Return InfobaseUsersTable;
	
EndFunction

Function ContactInformation(Settings)
	
	ReferenceTypes = New Array;
	ReferenceTypes.Add(Type("CatalogRef.Users"));
	ReferenceTypes.Add(Type("CatalogRef.ExternalUsers"));
	
	Contacts = New ValueTable;
	Contacts.Columns.Add("Ref", New TypeDescription(ReferenceTypes));
	Contacts.Columns.Add("Phone", New TypeDescription("String"));
	Contacts.Columns.Add("EmailAddress", New TypeDescription("String"));
	
	If Not CommonUse.SubsystemExists("StandardSubsystems.ContactInformation") Then
		Return Contacts;
	EndIf;
	
	FillContacts = False;
	PhoneField        = New DataCompositionField("Phone");
	EmailAddressField = New DataCompositionField("EmailAddress");
	
	For Each Item In Settings.Selection.Items Do
		If TypeOf(Item) = Type("DataCompositionSelectedField")
		   And (Item.Field = PhoneField OR Item.Field = EmailAddressField)
		   And Item.Use Then
			
			FillContacts = True;
			Break;
		EndIf;
	EndDo;
	
	If Not FillContacts Then
		Return Contacts;
	EndIf;
	
	ContactInformationKinds = New Array;
	ContactInformationKinds.Add(Catalogs["ContactInformationKinds"].UserEmail);
	ContactInformationKinds.Add(Catalogs["ContactInformationKinds"].UserPhone);
	Query = New Query;
	Query.SetParameter("ContactInformationKinds", ContactInformationKinds);
	Query.Text =
	"SELECT
	|	UsersContactInformation.Ref AS Ref,
	|	UsersContactInformation.Kind,
	|	UsersContactInformation.Presentation
	|FROM
	|	Catalog.Users.ContactInformation AS UsersContactInformation
	|WHERE
	|	UsersContactInformation.Kind IN (&ContactInformationKinds)
	|
	|ORDER BY
	|	UsersContactInformation.Ref,
	|	UsersContactInformation.Type.Order,
	|	UsersContactInformation.Kind";
	
	Selection = Query.Execute().Select();
	
	CurrentRef = Undefined;
	Phones = "";
	EmailAddresses = "";
	
	While Selection.Next() Do
		If CurrentRef <> Selection.Ref Then
			If CurrentRef <> Undefined Then
				If ValueIsFilled(Phones) OR ValueIsFilled(EmailAddresses) Then
					NewRow = Contacts.Add();
					NewRow.Ref = CurrentRef;
					NewRow.Phone = Phones;
					NewRow.EmailAddress = EmailAddresses;
				EndIf;
			EndIf;
			Phones = "";
			EmailAddresses = "";
			CurrentRef = Selection.Ref;
		EndIf;
		If Selection.Kind = Catalogs["ContactInformationKinds"].UserPhone Then
			Phones = Phones + ?(ValueIsFilled(Phones), ", ", "");
			Phones = Phones + Selection.Presentation;
		EndIf;
		If Selection.Kind = Catalogs["ContactInformationKinds"].UserEmail Then
			EmailAddresses = EmailAddresses + ?(ValueIsFilled(EmailAddresses), ", ", "");
			EmailAddresses = EmailAddresses + Selection.Presentation;
		EndIf;
	EndDo;
	
	Return Contacts;
	
EndFunction

#EndRegion

#EndIf