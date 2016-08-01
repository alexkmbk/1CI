////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
//  
////////////////////////////////////////////////////////////////////////////////

#Region InternalProceduresAndFunctions

// Retrieves saved parameters that the subsystem uses.
Function ProgramEventParameters() Export
	
	SetPrivilegedMode(True);
	SavedParameters = StandardSubsystemsServer.ApplicationParameters(
		"InternalEventParameters");
	SetPrivilegedMode(False);
	
	StandardSubsystemsServer.CheckIfApplicationParametersUpdated(
		"InternalEventParameters",
		"EventHandlers");
	
	If Not SavedParameters.Property("EventHandlers") Then
		StandardSubsystemsServerCall.EventHandlersGettingOnError();
	EndIf;
	
	SetPrivilegedMode(True);
	SavedParameters = StandardSubsystemsServer.ApplicationParameters(
		"InternalEventParameters");
	SetPrivilegedMode(False);
	
	ParameterPresentation = "";
	
	If Not SavedParameters.Property("EventHandlers") Then
		ParameterPresentation = NStr("en = 'Event handlers'");
	EndIf;
	
	If ValueIsFilled(ParameterPresentation) Then
		
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Cannot update the infobase.
			           |The following internal event parameter is not filled:
			           |%1.'")
			+ StandardSubsystemsServer.ApplicationRunParameterErrorClarificationForDeveloper(),
			ParameterPresentation);
	EndIf;
	
	Return SavedParameters;
	
EndFunction

// Returns descriptions of all configuration libraries, including the configuration
// itself.
//
Function SubsystemDescriptions() Export
	
	SubsystemModules = New Array;
	SubsystemModules.Add("InfobaseUpdateSL");
	
	ConfigurationSubsystemsOverridable.SubsystemsOnAdd(SubsystemModules);
	
	ConfigurationDetailsFound = False;
	SubsystemDescriptions = New Structure;
	SubsystemDescriptions.Insert("Order",   New Array);
	SubsystemDescriptions.Insert("ByNames", New Map);
	
	AllRequiredSubsystems = New Map;
	
	For Each ModuleName In SubsystemModules Do
		
		Details = NewSubsystemDetails();
		Module = CommonUse.CommonModule(ModuleName);
		Module.OnAddSubsystem(Details);
		
		If Details.Name = "StandardSubsystems" Then
			// <PROPERTIES FOR SUBSYSTEMS LIBRARY ONLY>
			Details.AddInternalEvents        = True;
			Details.AddInternalEventHandlers = True;
		EndIf;
		
		CommonUseClientServer.Validate(SubsystemDescriptions.ByNames.Get(Details.Name) = Undefined,
			StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Cannot prepare subsystem descriptions:
				           |in the subsystem description (see the %1.OnAddSubsystem procedure)
				           |the name of the %2 subsystem is specified, which is already registered.'"),
				ModuleName, Details.Name));
		
		If Details.Name = Metadata.Name Then
			ConfigurationDetailsFound = True;
			Details.Insert("IsConfiguration", True);
		Else
			Details.Insert("IsConfiguration", False);
		EndIf;
		
		Details.Insert("MainServerModule", ModuleName);
		
		SubsystemDescriptions.ByNames.Insert(Details.Name, Details);
		// Setting up the subsystem order according to the adding order of main modules.
		SubsystemDescriptions.Order.Add(Details.Name);
		// Collecting all required subsystems.
		For Each RequiredSubsystem In Details.RequiredSubsystems Do
			If AllRequiredSubsystems.Get(RequiredSubsystem) = Undefined Then
				AllRequiredSubsystems.Insert(RequiredSubsystem, New Array);
			EndIf;
			AllRequiredSubsystems[RequiredSubsystem].Add(Details.Name);
		EndDo;
	EndDo;
	
	// Verifying the main configuration description.
	If ConfigurationDetailsFound Then
		Details = SubsystemDescriptions.ByNames[Metadata.Name];
		
		CommonUseClientServer.Validate(Details.Version = Metadata.Version,
			StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Cannot prepare subsystem descriptions:
				           |the %1 configuration version (%2) (See %3.OnAddSubsystem procedure)
				           |does not match metadata configuration version (%4).'"),
				Details.Name,
				Details.Version,
				Details.MainServerModule,
				Metadata.Version));
	Else
		Details = NewSubsystemDetails();
		Details.Insert("Name",    Metadata.Name);
		Details.Insert("Version", Metadata.Version);
		Details.Insert("IsConfiguration", True);
		SubsystemDescriptions.ByNames.Insert(Details.Name, Details);
		SubsystemDescriptions.Order.Add(Details.Name);
	EndIf;
	
	// Checking whether all required subsystems are presented.
	For Each KeyAndValue In AllRequiredSubsystems Do
		If SubsystemDescriptions.ByNames.Get(KeyAndValue.Key) = Undefined Then
			DependentSubsystems = "";
			For Each DependentSubsystem In KeyAndValue.Value Do
				DependentSubsystems = Chars.LF + DependentSubsystem;
			EndDo;
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Cannot prepare subsystem descriptions:
				           |the %1 subsystem required for the %2 subsystem is not found.'"),
				KeyAndValue.Key,
				DependentSubsystems);
		EndIf;
	EndDo;
	
	// Setting up the subsystem order according to dependencies.
	For Each KeyAndValue In SubsystemDescriptions.ByNames Do
		Name = KeyAndValue.Key;
		Order = SubsystemDescriptions.Order.Find(Name);
		For Each RequiredSubsystem In KeyAndValue.Value.RequiredSubsystems Do
			RequiredSubsystemOrder = SubsystemDescriptions.Order.Find(RequiredSubsystem);
			If Order < RequiredSubsystemOrder Then
				Interdependency = SubsystemDescriptions.ByNames[RequiredSubsystem
					].RequiredSubsystems.Find(Name) <> Undefined;
				If Interdependency Then
					NewOrder = RequiredSubsystemOrder;
				Else
					NewOrder = RequiredSubsystemOrder + 1;
				EndIf;
				If Order <> NewOrder Then
					SubsystemDescriptions.Order.Insert(NewOrder, Name);
					SubsystemDescriptions.Order.Delete(Order);
					Order = NewOrder - 1;
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	// Moving the configuration description to the end of the array.
	Index = SubsystemDescriptions.Order.Find(Metadata.Name);
	If SubsystemDescriptions.Order.Count() > Index + 1 Then
		SubsystemDescriptions.Order.Delete(Index);
		SubsystemDescriptions.Order.Add(Metadata.Name);
	EndIf;
	
	For Each KeyAndValue In SubsystemDescriptions.ByNames Do
		
		KeyAndValue.Value.RequiredSubsystems =
			New FixedArray(KeyAndValue.Value.RequiredSubsystems);
		
		SubsystemDescriptions.ByNames[KeyAndValue.Key] =
			New FixedStructure(KeyAndValue.Value);
	EndDo;
	
	SubsystemDescriptions.Order  = New FixedArray(SubsystemDescriptions.Order);
	SubsystemDescriptions.ByNames = New FixedMap(SubsystemDescriptions.ByNames);
	
	Return New FixedStructure(SubsystemDescriptions);
	
EndFunction

// Returns the array of server event handler descriptions.
Function ServerEventHandlers(Event, Internal = False) Export
	
	PreparedHandlers = PreparedServerEventHandlers(Event, Internal);
	
	If PreparedHandlers = Undefined Then
		// Cache autoupdate. Cached values must be updated.
		StandardSubsystemsServerCall.EventHandlersGettingOnError();
		RefreshReusableValues();
		// Reattempting to get event handlers.
		PreparedHandlers = PreparedServerEventHandlers(Event, Internal, False);
	EndIf;
	
	Return PreparedHandlers;
	
EndFunction

// Returns a map of "functional" subsystem names and the True values.
// The subsystem is a "functional" one if its "Include in command interface" check box 
// is cleared.
//
Function SubsystemNames() Export
	
	Names = New Map;
	InsertSubordinateSubsystemNames(Names, Metadata);
	
	Return New FixedMap(Names);
	
EndFunction

// Returns a list of metadata objects that are used in DIB only during creation of 
// subordinate node initial image. The list of objects is generated for all subsystems
// with StandardSubsystems.BaseFunctionality\OnGetExchangePlanInitialImageObjects
// event defined.
//
// Returns:
//  FixedMap, where Key is metadata object and Value is True.
//
Function InitialImageObjects() Export
	
	Result = New Map;
	
	Objects = New Array;
	
	// Getting objects of the initial image
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.BaseFunctionality\OnGetExchangePlanInitialImageObjects");
	For Each Handler In EventHandlers Do
		
		Handler.Module.OnGetExchangePlanInitialImageObjects(Objects);
		
	EndDo;
	
	For Each Object In Objects Do
		
		Result.Insert(Object.FullName(), True);
		
	EndDo;
	
	Return New FixedMap(Result);
	
EndFunction

// Returns the list of DIB exchange plans.
// If the applied solution runs in SaaS mode, the list of separated DIB exchange plans 
// is returned.
//
Function DIBExchangePlans() Export
	
	Result = New Array;
	
	If CommonUseCached.DataSeparationEnabled() Then
		
		For Each ExchangePlan In Metadata.ExchangePlans Do
			
			If ExchangePlan.DistributedInfobase
				And CommonUseCached.IsSeparatedMetadataObject(ExchangePlan.FullName(),
					CommonUseCached.MainDataSeparator())
				Then
				
				Result.Add(ExchangePlan.Name);
				
			EndIf;
			
		EndDo;
		
	Else
		
		For Each ExchangePlan In Metadata.ExchangePlans Do
			
			If ExchangePlan.DistributedInfobase Then
				
				Result.Add(ExchangePlan.Name);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the map of predefined value names and their references.
// 
// Parameters:
//  MetadataObjectFullName - String, for example, "Catalog.ProductKinds",
//                           Only the follow tables with predefined items are
//                           supported:
//                               - Catalogs.
//                               - Plans of characteristic types.
//                               - Plans of accounts.
//                               - Plans of calculation types.
// 
// Returns:
//  Map, where
//   Key   - Strings - predefined item name,
//   Value - predefined item reference.
//
Function ReferencesByPredefinedItemNames(MetadataObjectFullName) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	CurrentTable.Ref AS Ref,
	|	CurrentTable.PredefinedDataName AS PredefinedDataName
	|FROM
	|	&CurrentTable AS CurrentTable
	|WHERE
	|	CurrentTable.Predefined = TRUE";
	
	Query.Text = StrReplace(Query.Text, "&CurrentTable", MetadataObjectFullName);
	
	Selection = Query.Execute().Select();
	
	PredefinedValues = New Map;
	
	While Selection.Next() Do
		PredefinedName = Selection.PredefinedDataName;
		PredefinedValues.Insert(PredefinedName, Selection.Ref);
	EndDo;
	
	Return PredefinedValues;
	
EndFunction

// Returns True if privilege mode was set during the application startup using the 
// UsePrivilegedMode parameter.
//
// Supports only client application startup (external connections are not supported).
//
Function PrivilegedModeSetOnStart() Export
	
	SetPrivilegedMode(True);
	
	Return SessionParameters.ClientParametersOnServer.Get(
		"PrivilegedModeSetOnStart") = True;
	
EndFunction

// For internal use only.
Function ApplicationParameters(ConstantName) Export
	
	Parameters = Constants[ConstantName].Get().Get();
	
	If TypeOf(Parameters) <> Type("Structure") Then
		Parameters = New Structure;
	EndIf;
	
	Return New FixedStructure(Parameters);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Getting ID by metadata object and vice versa.

// For internal use only
Function MetadataObjectID(MetadataObjectFullName) Export
	
	StandardSubsystemsCached.CatalogMetadataObjectIDsUsageCheck(True);
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("FullName", MetadataObjectFullName);
	Query.Text =
	"SELECT
	|	IDs.Ref AS Ref,
	|	IDs.MetadataObjectKey,
	|	IDs.FullName
	|FROM
	|	Catalog.MetadataObjectIDs AS IDs
	|WHERE
	|	IDs.FullName = &FullName
	|	AND NOT IDs.DeletionMark";
	
	Data = Query.Execute().Unload();
	If Data.Count() = 0 Then
		// If the ID is not found by full name, perhaps full name is set with error
		If Metadata.FindByFullName(MetadataObjectFullName) = Undefined Then
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Cannot execute the CommonUse.MetadataObjectID() function.
				           |
				           |The metadata object is not found by full name:
				           |%1.'"),
				MetadataObjectFullName);
		EndIf;
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Cannot execute the CommonUse.MetadataObjectID() function.
			           |
			           |No ID was found in the Metadata object IDs catalog
			           |for the metadata object named %1.'")
			+ StandardSubsystemsServer.ApplicationRunParameterErrorClarificationForDeveloper(),
			MetadataObjectFullName);
	ElsIf Data.Count() > 1 Then
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Cannot execute the CommonUse.MetadataObjectID() function.
			           |
			           |Several IDs were found in the Metadata object IDs catalog
			           |for the metadata object named %1.'")
			+ StandardSubsystemsServer.ApplicationRunParameterErrorClarificationForDeveloper(),
			MetadataObjectFullName);
	EndIf;
	
	// Checking whether the metadata object key corresponds to the full metadata object name
	CheckResult = Catalogs.MetadataObjectIDs.MetadataObjectKeyCorrespondsFullName(Data[0]);
	If CheckResult.NotCorresponds Then
		If CheckResult.MetadataObject = Undefined Then
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Cannot execute the CommonUse.MetadataObjectID() function.
				           |
				           |The ID corresponding to the deleted metadata object was found in the 
				           |Metadata object IDs catalog for the object named %1.'")
			+ StandardSubsystemsServer.ApplicationRunParameterErrorClarificationForDeveloper(),
				MetadataObjectFullName);
		Else
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Cannot execute the CommonUse.MetadataObjectID() function.
				           |
          				 |The ID corresponding to the %2 metadata object was found in the 
			          	 |Metadata object IDs catalog for the object named %1.'")
			+ StandardSubsystemsServer.ApplicationRunParameterErrorClarificationForDeveloper(),
				MetadataObjectFullName,
				CheckResult.MetadataObject);
		EndIf;
	EndIf;
	
	Return Data[0].Ref;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Processing the MetadataObjectIDs catalog

// For internal use only.
Function DisableMetadataObjectIDsCatalog() Export
	
	Use = Not CommonUse.CommonBaseFunctionalityParameters(
		).DisableMetadataObjectIDsCatalog;
	
	If Use Then
		Return False;
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.ReportOptions")
	 Or CommonUse.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors")
	 Or CommonUse.SubsystemExists("StandardSubsystems.ReportMailing")
	 Or CommonUse.SubsystemExists("StandardSubsystems.AccessManagement") Then
		
		Raise
			NStr("en = 'The Metadata objects IDs catalog cannot be disabled,
			           |if at least one of the following subsystems is used:
			           |- ReportOptions, 
			           |- AdditionalReportsAndDataProcessors, 
			           |- ReportMailing, 
			           |- AccessManagement.'");
	EndIf;
	
	Return True;
	
EndFunction

// For internal use only.
Function CatalogMetadataObjectIDsUsageCheck(CheckForUpdates = False) Export
	
	Catalogs.MetadataObjectIDs.CheckForUsage();
	
	If CheckForUpdates Then
		Catalogs.MetadataObjectIDs.DataUpdated(True);
	EndIf;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Updating the MetadataObjectIDs catalog

// For internal use only.
Function TableOfRenamingForCurrentVersion() Export
	
	Return Catalogs.MetadataObjectIDs.TableOfRenamingForCurrentVersion();
	
EndFunction

// For internal use only.
Function MetadataObjectCollectionProperties() Export
	
	Return Catalogs.MetadataObjectIDs.MetadataObjectCollectionProperties();
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Processing predefined data

// Retrieves the predefined item reference by its full name.
//  See CommonUseClientServer.PredefinedItem() for details.
//
Function PredefinedItem(Val PredefinedItemFullName) Export
	
	PredefinedName = Upper(PredefinedItemFullName);
	
	Dot = Find(PredefinedName, ".");
	CollectionName = Left(PredefinedName, Dot - 1);
	PredefinedName = Mid(PredefinedName, Dot + 1);
	
	Dot = Find(PredefinedName, ".");
	TableName = Left(PredefinedName, Dot - 1);
	PredefinedName = Mid(PredefinedName, Dot + 1);
	
	QueryText = "SELECT ALLOWED TOP 1 Ref FROM &FullTableName WHERE PredefinedDataName = &PredefinedName";
	QueryText = StrReplace(QueryText, "&FullTableName", CollectionName + "." + TableName);
	
	Query = New Query(QueryText);
	Query.SetParameter("PredefinedName", PredefinedName);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return Undefined;
	Else
		Return Result.Unload()[0].Ref;
	EndIf;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// AUXILIARY PROCEDURES AND FUNCTIONS

Function NewSubsystemDetails()
	
	Details = New Structure;
	Details.Insert("Name",    "");
	Details.Insert("Version", "");
	Details.Insert("RequiredSubsystems", New Array);
	
	// The property is set automatically.
	Details.Insert("IsConfiguration", False);
	
	// Name of the main library module.
	// Can has an empty value in case of configuration.
	Details.Insert("MainServerModule", "");
	
	//  <PROPERTIES ONLY FOR SUBSYSTEMS LIBRARY>
	
	Details.Insert("AddEvents",        False);
	Details.Insert("AddEventHandlers", False);
	
	//  AddInternalEvents        - Boolean - if it is True, the  
	//                             OnAddInternalEvent(ClientEvents,ServerEvents)  
	//                             standard procedure of the main library module is
	//                             called.
	// 
	//  AddInternalEventHandlers - Boolean - if it is True, the
	//                             InternalEventHandlersOnAdd(ClientHandlers,ServerHandlers)  
	//                             standard procedure of the main library module is
	//                             called.
	
	Details.Insert("AddInternalEvents",        False);
	Details.Insert("AddInternalEventHandlers", False);
	
	Return Details;
	
EndFunction

Procedure InsertSubordinateSubsystemNames(Names, ParentSubsystem, All = False, ParentSubsystemName = "")
	
	For Each CurrentSubsystem In ParentSubsystem.Subsystems Do
		
		If CurrentSubsystem.IncludeInCommandInterface And Not All Then
			Continue;
		EndIf;
		
		CurrentSubsystemName = ParentSubsystemName + CurrentSubsystem.Name;
		Names.Insert(CurrentSubsystemName, True);
		
		If CurrentSubsystem.Subsystems.Count() = 0 Then
			Continue;
		EndIf;
		
		InsertSubordinateSubsystemNames(Names, CurrentSubsystem, All, CurrentSubsystemName + ".");
	EndDo;
	
EndProcedure

Function PreparedServerEventHandlers(Event, Internal = False, FirstTry = True)
	
	Parameters = StandardSubsystemsCached.ProgramEventParameters(
		).EventHandlers.AtServer;
	
	If Internal Then
		Handlers = Parameters.InternalEventHandlers.Get(Event);
	Else
		Handlers = Parameters.EventHandlers.Get(Event);
	EndIf;
	
	If FirstTry And Handlers = Undefined Then
		Return Undefined;
	EndIf;
	
	If Handlers = Undefined Then
		If Internal Then
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'The %1 server internal event is not found.'"), Event);
		Else
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'The %1 server event is not found.'"), Event);
		EndIf;
	EndIf;
	
	Array = New Array;
	
	For Each Handler In Handlers Do
		Item = New Structure;
		Module = Undefined;
		If FirstTry Then
			Try
				Module = CommonUse.CommonModule(Handler.Module);
			Except
				Return Undefined;
			EndTry;
		Else
			Module = CommonUse.CommonModule(Handler.Module);
		EndIf;
		Item.Insert("Module",    Module);
		Item.Insert("Version",   Handler.Version);
		Item.Insert("Subsystem", Handler.Subsystem);
		Array.Add(New FixedStructure(Item));
	EndDo;
	
	Return New FixedArray(Array);
	
EndFunction

#EndRegion
