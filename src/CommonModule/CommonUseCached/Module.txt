////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
// Common use server procedures and functions.
//  
////////////////////////////////////////////////////////////////////////////////

#Region Interface

// Returns a flag that shows if there are any common separators in the configuration.
//
// Returns:
//  Boolean.
//
Function IsSeparatedConfiguration() Export
	
	HasSeparators = False;
	For Each CommonAttribute In Metadata.CommonAttributes Do
		If CommonAttribute.DataSeparation = Metadata.ObjectProperties.CommonAttributeDataSeparation.Separate Then
			HasSeparators = True;
			Break;
		EndIf;
	EndDo;
	
	Return HasSeparators;
	
EndFunction

// Returns the common attribute content by the passed name.
//
// Parameters:
// Name - String - common attribute name.
//
// Returns:
//  CommonAttributeContent.
//
Function CommonAttributeContent(Val Name) Export
	
	Return Metadata.CommonAttributes[Name].Content;
	
EndFunction

// Returns a flag that shows whether the metadata object is used in common separators.
//
// Parameters:
//  MetadataObjectName - String.
//  Separator          - name of the common separator attribute. The function checks
//                       whether the metadata object is separated with this attribute.
//
// Returns:
//  Boolean.
//
Function IsSeparatedMetadataObject(Val MetadataObjectName, Val Separator) Export
	
	Return CommonUse.IsSeparatedMetadataObject(MetadataObjectName, Separator);
	
EndFunction

// Returns the name the common attribute that are the main data separator.
//
// Returns:
//  String.
//
Function MainDataSeparator() Export
	
	Result = "";
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.BaseFunctionalitySaaS") Then
		SaaSOperationsModule = CommonUse.CommonModule("SaaSOperations");
		Result = SaaSOperationsModule.MainDataSeparator();
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the name the common attribute that are the auxiliary data separator.
//
// Returns:
//  String.
//
Function AuxiliaryDataSeparator() Export
	
	Result = "";
	If CommonUse.SubsystemExists("StandardSubsystems.SaaSOperations.BaseFunctionalitySaaS") Then
		SaaSOperationsModule = CommonUse.CommonModule("SaaSOperations");
		Result = SaaSOperationsModule.AuxiliaryDataSeparator();
	EndIf;
	
	Return Result;
	
EndFunction

// Returns a data separation enable flag.
// If it is called in shared configuration it returns False.
//
Function DataSeparationEnabled() Export
	
	Return CommonUseCached.IsSeparatedConfiguration() And GetFunctionalOption("SaaSOperations");
	
EndFunction

// Returns a flag that shows if separated data can be called from this session.
// If it is called in shared configuration it returns True.
//
// Returns:
//  Boolean.
//
Function CanUseSeparatedData() Export
	
	Return Not CommonUseCached.DataSeparationEnabled() Or CommonUse.UseSessionSeparator();
	
EndFunction

// Returns XSLTransform object created from the common template with the passed
// name.
//
// Parameters:
//  CommonTemplateName - String - name of common template that contained XML transform
//                       file. Type of template is BinaryData.
//
// Returns:
//  XSLTransform - XSLTransform object with a loaded transformation.
//
Function GetXSLTransformFromCommonTemplate(Val CommonTemplateName) Export
	
	TemplateData = GetCommonTemplate(CommonTemplateName);
	TransformFileName = GetTempFileName("xsl");
	TemplateData.Write(TransformFileName);
	
	Transform = New XSLTransform;
	Transform.LoadFromFile(TransformFileName);
	
	Try
		DeleteFiles(TransformFileName);
	Except
		WriteLogEvent(NStr("en = 'Getting XSL'", CommonUseClientServer.DefaultLanguageCode()),
			EventLogLevel.Error, , , DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return Transform;
	
EndFunction

// Determines if the session was started without separators.
//
// Returns:
//  Boolean.
//
Function SessionWithoutSeparators() Export
	
	Return InfobaseUsers.CurrentUser().DataSeparation.Count() = 0;
	
EndFunction

// Returns the server platform type.
//
// Returns:
//  PlatformType; Undefined.
//
Function ServerPlatformType() Export
	
	ServerPlatformTypeString = StandardSubsystemsServerCall.ServerPlatformTypeString();
	
	If ServerPlatformTypeString = "Linux_x86" Then
		Return PlatformType.Linux_x86;
		
	ElsIf ServerPlatformTypeString = "Linux_x86_64" Then
		Return PlatformType.Linux_x86_64;
		
	ElsIf ServerPlatformTypeString = "Windows_x86" Then
		Return PlatformType.Windows_x86;
		
	ElsIf ServerPlatformTypeString = "Windows_x86_64" Then
		Return PlatformType.Windows_x86_64;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Determines the run mode for application settings panels.
//
//  Five interfaces are available in the settings panels:
//  - For the service administrator in the subscriber data area (SAS)
//  - For the subscriber administrator (SA)
//  - For the local solution administrator in the client/server mode (LCS)
//  - For the local solution administrator in the file mode (LF)
//  - For the standalone workstation administrator (SWP)
//
// The SAS and SA interfaces are split by hiding groups and items of a form for all
// roles, except FullAdministrator.
//
// The service administrator that logs on the data area should see the same settings
// as the subscriber administrator with the service settings (shared).
//
Function ApplicationRunMode() Export
	RunMode = New Structure;
	
	// User rights
	RunMode.Insert("IsApplicationAdministrator", Users.InfobaseUserWithFullAccess(,,False)); // SA, SAS, LCS, LF
	RunMode.Insert("IsFullAdministrator",   Users.InfobaseUserWithFullAccess(, True, False)); // SAS, LCS, LF
	
	// Common settings
	RunMode.Insert("SaaS", DataSeparationEnabled()); // SAS, SA
	RunMode.Insert("Local",     GetFunctionalOption("LocalMode")); // LCS, LF
	RunMode.Insert("Standalone",    GetFunctionalOption("StandaloneModeOperations")); // SWP
	RunMode.Insert("File",        False); // SAS, SA, LF
	RunMode.Insert("ClientServer", False); // SAS, SA, LCS
	
	If CommonUse.FileInfobase() Then
		RunMode.File = True;
	Else
		RunMode.ClientServer = True;
	EndIf;
	
	// Exact settings
	RunMode.Insert("ServiceAdministrator",
		RunMode.SaaS And RunMode.IsFullAdministrator); // SA
	RunMode.Insert("SubscriberAdministrator",
		RunMode.SaaS And Not RunMode.IsFullAdministrator And RunMode.IsApplicationAdministrator); // SA
	RunMode.Insert("LocalFile",
		RunMode.Local And RunMode.File); // LF
	RunMode.Insert("LocalClientServer",
		RunMode.Local And RunMode.ClientServer); // LCS
	
	// Other setting
	RunMode.Insert("IsLinuxClient", CommonUseClientServer.IsLinuxClient());
	RunMode.Insert("IsWebClient",   CommonUseClientServer.IsWebClient());
	
	Return RunMode;
EndFunction

#EndRegion

#Region InternalInterface

// Returns a list of full names of all metadata objects used in the common separator
// attribute (whose name is passed in the Separator parameter) and values of the
// object metadata properties that can be required for further processing in universal
// algorithms.
// In case of sequences and document journals the function determines whether they are 
// separated by included documents: any one from the sequence or journal.
//
// Parameters:
//  Separator - String - common attribute name.
//
// Returns:
//  FixedMap, where:
//   Key   - String - full metadata object name.
//   Value - FixedStructure, where:  
//           Name                  - String - metadata object name.
//           Separator             - String - name of the separator that separate the 
//                                   metadata object.
//           ConditionalSeparation - String - full name of the metadata object that
//                                   shows whether the metadata object data separation
//                                   is enabled.  
//
Function SeparatedMetadataObjects(Val Separator) Export
	
	Result = New Map;
	
	// I. Going over all common attributes.
	
	CommonAttributeMetadata = Metadata.CommonAttributes.Find(Separator);
	If CommonAttributeMetadata = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'The %1 common attribute is not found in the configuration.'"), Separator);
	EndIf;
	
	If CommonAttributeMetadata.DataSeparation = Metadata.ObjectProperties.CommonAttributeDataSeparation.Separate Then
		
		CommonAttributeContent = CommonUseCached.CommonAttributeContent(CommonAttributeMetadata.Name);
		
		UseCommonAttribute = Metadata.ObjectProperties.CommonAttributeUse.Use;
		AutoUseCommonAttribute = Metadata.ObjectProperties.CommonAttributeUse.Auto;
		CommonAttributeAutoUse = 
			(CommonAttributeMetadata.AutoUse = Metadata.ObjectProperties.CommonAttributeAutoUse.Use);
		
		For Each ContentItem In CommonAttributeContent Do
			
			If (CommonAttributeAutoUse And ContentItem.Use = AutoUseCommonAttribute)
				Or ContentItem.Use = UseCommonAttribute Then
				
				AdditionalData = New Structure("Name,Separator,ConditionalSeparation", ContentItem.Metadata.Name, Separator, Undefined);
				If ContentItem.ConditionalSeparation <> Undefined Then
					AdditionalData.ConditionalSeparation = ContentItem.ConditionalSeparation.FullName();
				EndIf;
				
				Result.Insert(ContentItem.Metadata.FullName(), New FixedStructure(AdditionalData));
				
				// Recalculation separation is determined by the calculation register where it belongs 
				If CommonUse.IsCalculationRegister(ContentItem.Metadata) Then
					
					Recalculations = ContentItem.Metadata.Recalculations;
					For Each Recalculation In Recalculations Do
						
						AdditionalData.Name = Recalculation.Name;
						Result.Insert(Recalculation.FullName(), New FixedStructure(AdditionalData));
						
					EndDo;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	Else
		
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Data separation is not used for the %1 common attribute.'"), Separator);
		
	EndIf; 
	
	// II. In case of sequences and document journals, determining whether they are 
	// separated by included documents.
	
	// 1) Going over sequences and checking the first included document in each of them.
	//    If a sequence include no documents it is considered as separated.
	//
	For Each SequenceMetadata In Metadata.Sequences Do
		
		AdditionalData = New Structure("Name,Separator,ConditionalSeparation", SequenceMetadata.Name, Separator, Undefined);
		
		If SequenceMetadata.Documents.Count() = 0 Then
			
			MessagePattern = NStr("en = 'The %1 sequence contains no documents.'");
			MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessagePattern, SequenceMetadata.Name);
			WriteLogEvent(NStr("en = 'Getting separated metadata objects'", 
				CommonUseClientServer.DefaultLanguageCode()), EventLogLevel.Error, 
				SequenceMetadata, , MessageText);
			
			Result.Insert(SequenceMetadata.FullName(), New FixedStructure(AdditionalData));
			
		Else
			
			For Each DocumentMetadata In SequenceMetadata.Documents Do
				
				AdditionalDataFromDocument = Result.Get(DocumentMetadata.FullName());
				
				If AdditionalDataFromDocument <> Undefined Then
					FillPropertyValues(AdditionalData, AdditionalDataFromDocument, "Separator,ConditionalSeparation");
					Result.Insert(SequenceMetadata.FullName(), New FixedStructure(AdditionalData));
				EndIf;
				
				Break;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	// 2) Going over journals and checking the first included document in each of them.
	// If a journal include no documents it is considered as separated.
	//
	For Each DocumentJournalMetadata In Metadata.DocumentJournals Do
		
		AdditionalData = New Structure("Name,Separator,ConditionalSeparation", DocumentJournalMetadata.Name, Separator, Undefined);
		
		If DocumentJournalMetadata.RegisteredDocuments.Count() = 0 Then
			
			MessagePattern = NStr("en = 'The %1 journal contains no documents.'");
			MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessagePattern, DocumentJournalMetadata.Name);
			WriteLogEvent(NStr("en = 'Getting separated metadata objects'", 
				CommonUseClientServer.DefaultLanguageCode()), EventLogLevel.Error, 
				DocumentJournalMetadata, , MessageText);
			
			Result.Insert(DocumentJournalMetadata.FullName(), New FixedStructure(AdditionalData));
			
		Else
			
			For Each DocumentMetadata In DocumentJournalMetadata.RegisteredDocuments Do
				
				AdditionalDataFromDocument = Result.Get(DocumentMetadata.FullName());
				
				If AdditionalDataFromDocument <> Undefined Then
					FillPropertyValues(AdditionalData, AdditionalDataFromDocument, "Separator,ConditionalSeparation");
					Result.Insert(DocumentJournalMetadata.FullName(), New FixedStructure(AdditionalData));
				EndIf;
				
				Break;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	Return New FixedMap(Result);
	
EndFunction

#EndRegion

#Region InternalProceduresAndFunctions

// Retrieves cache version data from the ValueStorage resource of the ProgramInterfaceCache register.
//
// Parameters:
//  ID                  - String - cache record ID.
//  DataType            - EnumRef.ProgramInterfaceCacheDataTypes.
//  ReceivingParameters - String - parameter array serialized to XML for passing into 
//                        the cache update procedure.
//  UseObsoleteData     - Boolean - flag that shows whether the procedure must wait
//                        for cache update before retrieving data if it is obsolete.
//                        * True - always use cache data, if any.
//                        * False - wait for cache update if data is obsolete.
//
// Returns:
//  Arbitrary.
//
Function GetVersionCacheData(Val ID, Val DataType, 
		Val ReceivingParameters, Val UseObsoleteData = True) Export
	
	ReceivingParameters = CommonUse.ValueFromXMLString(ReceivingParameters);
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	CacheTable.UpdateDate AS UpdateDate,
		|	CacheTable.Data AS Data,
		|	CacheTable.DataType AS DataType
		|FROM
		|	InformationRegister.ProgramInterfaceCache AS CacheTable
		|WHERE
		|	CacheTable.ID = &ID
		|	AND CacheTable.DataType = &DataType";
	Query.SetParameter("ID", ID);
	Query.SetParameter("DataType", DataType);
	
	BeginTransaction();
	Try
			// Managed lock is not set, so other sessions can change the value while this
			// transaction is active.
		Result = Query.Execute();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	RequiredUpdate = False;
	RereadDataRequired = False;
	
	If Result.IsEmpty() Then
		
		RequiredUpdate = True;
		RereadDataRequired = True;
		
	Else
		
		Selection = Result.Select();
		Selection.Next();
		If CommonUse.VersionCacheRecordObsolete(Selection) Then
			RequiredUpdate = True;
			RereadDataRequired = Not UseObsoleteData;
		EndIf;
	EndIf;
	
	If RequiredUpdate Then
		
		UpdateInCurrentSession = CommonUse.FileInfobase() Or ExclusiveMode();
		
		If UpdateInCurrentSession Then
			CommonUse.RefreshVersionCacheData(ID, DataType, ReceivingParameters);
			RereadDataRequired = True;
		Else
			JobMethodName = "CommonUse.RefreshVersionCacheData";
			JobDescription = StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Updating cache versions. Record ID: %1. Data type: %2.'"),
				ID,
				DataType);
			JobParameters = New Array;
			JobParameters.Add(ID);
			JobParameters.Add(DataType);
			JobParameters.Add(ReceivingParameters);
			
			JobFilter = New Structure;
			JobFilter.Insert("MethodName", JobMethodName);
			JobFilter.Insert("Description", JobDescription);
			JobFilter.Insert("Status", BackgroundJobState.Active);
			
			Jobs = BackgroundJobs.GetBackgroundJobs(JobFilter);
			If Jobs.Count() = 0 Then
				// Starting a new one
				BackgroundJobs.Execute(JobMethodName, JobParameters, , JobDescription);
				// The background job could immediately stops because the data is updated by
				// another background job.
				Jobs = BackgroundJobs.GetBackgroundJobs(JobFilter);
			EndIf;
		EndIf;
		
		If RereadDataRequired Then
			If Not UpdateInCurrentSession Then
				Try
					// Waiting for completion
					BackgroundJobs.WaitForCompletion(Jobs);
				Except
					For Each OriginalJob In Jobs Do
						Job = BackgroundJobs.FindByUUID(OriginalJob.UUID);
						If Job.State <> BackgroundJobState.Failed Then
							Continue;
						EndIf;
						
						If Job.ErrorInfo <> Undefined Then
							WriteLogEvent(NStr("en = 'Updating cache versions'", CommonUseClientServer.DefaultLanguageCode()),
								EventLogLevel.Error,
								,
								,
								DetailErrorDescription(Job.ErrorInfo));
							Raise(BriefErrorDescription(Job.ErrorInfo));
						Else
							WriteLogEvent(NStr("en = 'Updating cache versions'", CommonUseClientServer.DefaultLanguageCode()),
								EventLogLevel.Error,
								,
								,
								DetailErrorDescription(ErrorInfo()));
							Raise(NStr("en = 'Cannot update cache versions. Unknown job error.'"));
						EndIf;
					EndDo;
					
					Raise(NStr("en = 'Cannot update cache versions. Unknown error.'"));
				EndTry;
			EndIf;
			
			BeginTransaction();
			Try
			// Managed lock is not set, so other sessions can change the value while this
			// transaction is active.
				Result = Query.Execute();
				CommitTransaction();
			Except
				RollbackTransaction();
				Raise;
			EndTry;
			
			If Result.IsEmpty() Then
				MessagePattern = NStr("en = 'Cannot update cache versions. Data is not received.
					|Record ID: %1
					|Data type: %2'");
				MessageText = StringFunctionsClientServer.SubstituteParametersInString(
					MessagePattern, ID, DataType);
					
				Raise(MessageText);
			EndIf;
			
			Selection = Result.Select();
			Selection.Next();
		EndIf;
		
	EndIf;
		
	Return Selection.Data.Get();
	
EndFunction

// Returns the WSDefinitions object created with the passed parameters.
//
// Parameters:
//  WSDLAddress - String - wsdl location.
//  UserName    - String - user name for log on to the server.
//  Password    - String - user password.
//
// Comment: during the Definition retrieving the function uses the cache that is
// updated when the configuration version is changed. If one needs to update cached
// value before this time (for example, in debug purposes), delete the respective 
// records from the ProgramInterfaceCache information register.
//
Function WSDefinitions(Val WSDLAddress, Val UserName, Val Password) Export
	
	Return CommonUse.WSDefinitions(WSDLAddress, UserName, Password);
	
EndFunction

// Returns the WSProxy object created with the passed parameters.
//
// Parameters correspond to the WSProxy object constructor.
//
Function WSProxy(Val WSDLAddress, Val NamespaceURI, Val ServiceName,
	Val EndpointName = "", Val UserName, Val Password, Val Timeout = Undefined) Export
	
	Return CommonUse.InnerWSProxy(WSDLAddress, NamespaceURI, ServiceName, 
		EndpointName, UserName, Password, Timeout);
	
EndFunction

// Parameters applied to command interface items associated with parametric functional
// options.
Function InterfaceOptions() Export
	
	InterfaceOptions = New Structure;
	Try
		CommonUseOverridable.InterfaceFunctionalOptionParametersOnDefine(InterfaceOptions);
	Except
		ErrorInfo = ErrorInfo();
		EventName = NStr("en = 'Interface setup'", CommonUseClientServer.DefaultLanguageCode());
		ErrorText = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Cannot get interface option because of the following error:
			   |%1'"),
			DetailErrorDescription(ErrorInfo));
		WriteLogEvent(EventName, EventLogLevel.Error,,, ErrorText);
	EndTry;
	
	Return InterfaceOptions;
EndFunction

// Metadata object availability by functional options.
Function ObjectsEnabledByOption() Export
	Parameters = CommonUseCached.InterfaceOptions();
	If TypeOf(Parameters) = Type("FixedStructure") Then
		Parameters = New Structure(Parameters);
	EndIf;
	
	ObjectsEnabled = New Map;
	For Each FunctionalOption In Metadata.FunctionalOptions Do
		Value = -1;
		For Each Item In FunctionalOption.Content Do
			If Value = -1 Then
				Value = GetFunctionalOption(FunctionalOption.Name, Parameters);
			EndIf;
			If Value = True Then
				ObjectsEnabled.Insert(Item.Object, True);
			Else
				If ObjectsEnabled[Item.Object] = Undefined Then
					ObjectsEnabled.Insert(Item.Object, False);
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	Return ObjectsEnabled;
EndFunction

#EndRegion
