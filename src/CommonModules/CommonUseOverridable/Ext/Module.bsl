////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
//  
////////////////////////////////////////////////////////////////////////////////

#Region Interface

// Returns a map of session parameter names and handlers for their initialization.
//
// Use the following pattern to set session parameter handlers:
// Handlers.Insert("<SessionParameterName>|<SessionParameterNamePrefix*>", "Handler");
//
// Note. The asterisk sigh (*) is used at the end of the session parameter name and
//       means that a single handler is called for initializing all session
//       parameters with the names beginning with SessionParameterNamePrefix.
//
Procedure SessionParameterSettingHandlersOnAdd(Handlers) Export
	
EndProcedure

// Metadata objects whose content must be skipped in the application business logic.
//
// Example:
//  The Object versioning subsystem and the Properties subsystem are configured for
//  Invoice documents. There can be references to this document in the infobase (in 
//  other documents, registers, and other objects). 
//  Some of them are important for business logic (like register records) and must be
//  shown to user. Other part is "technical" references, referred to the Object
//  versioning subsystem and the Properties subsystem. Such technical references must
//  be filtered. For example, such case occurs when references to objects are being 
//  searched or in the Object attribute edit prohibition subsystem.
//  The list of technical objects must be specified in this procedure.
// 
// Important:
//  To prevent the infobase from empty "bad" references, we recommend that you
//  include a procedure for clearing the specified metadata objects.
//  For information register dimensions select the Master check box, this deletes the
//  register record data once the respective reference specified in a dimension is
//  deleted.
//  For other attributes of the objects being deleted, use the BeforeDelete
//  subscription event of all metadata objects types that can be recorded to the
//  attributes of the specified metadata objects. The handler must find the
//  "technical" objects that contain the reference in the attributes and select the 
//  way of reference clearing: clear the attribute value, delete the row, or delete 
//  the whole object.
//
// Parameters:
//  RefSearchExclusions - Array - metadata objects or their attributes, whose content 
//                        must be skipped in the application business logic.
//                         * MetadataObject - metadata object or its attribute.
//                         * String - full name of the metadata object or its attribute.
//
// Examples:
//  RefSearchExclusions.Add(Metadata.InformationRegisters.ObjectVersions);
//  RefSearchExclusions.Add(Metadata.InformationRegisters.ObjectVersions.Attributes.VersionAuthor);
//  RefSearchExclusions.Add("InformationRegister.ObjectVersions");
//
Procedure OnAddReferenceSearchException(RefSearchExclusions) Export
	
EndProcedure

// Sets the subject description text.
// 
// Parameters:
//  SubjectRef   - AnyRef - reference type object.
//  Presentation - String - object text description to be set.
Procedure SetSubjectPresentation(SubjectRef, Presentation) Export
	
EndProcedure

// Redefines renaming of the metadata objects that cannot be found automatically by
// type but whose references must be saved in the infobase (for example, subsystems
// and roles).
//
// Parameters:
//  Result - ValueTable - table to be passed as a parameter to the AddRenaming 
//           procedure of the CommonUse common module.
//
// Example:
// CommonUse.AddRenaming(Result, "2.2.1.7",
// 	"Role.UseDS", "Role.UseDigitalSignature", "StandardSubsystems");
//
Procedure RenamedMetadataObjectsOnAdd(Total) Export
	
	// _Demo begin example
	//_DemoStandardSubsystems.RenamedMetadataObjectsOnAdd(Total);
	// _Demo end example
	
EndProcedure

// Returns a structure of parameters required for starting the client script during the 
// application startup, namely in the following event handlers:
// - BeforeStart,
// - OnStart.
//
// Important: when starting the application, do not use cache reset commands of modules 
// that reuse return values because this can lead to unpredictable errors and unneeded 
// service calls. 
//
// Parameters:
//  Parameters - Structure - (return value) startup client run parameter structure.
//
// Implementation example:
//  You can use the following template to set up client run parameters:
//  Parameters.Insert(<ParameterName>, <script that gets parameter values>);
//
Procedure ClientParametersOnStart(Parameters) Export
	
	// _Demo begin example
	SuggestOpenWebSiteOnStart = CommonUse.CommonSettingsStorageLoad(
		"UserCommonSettings", 
		"SuggestOpenWebSiteOnStart",
		False);
	Parameters.Insert("SuggestOpenWebSiteOnStart", SuggestOpenWebSiteOnStart);	
	// _Demo end example
	
EndProcedure

// Returns the structure of parameters required for configuration client script
// execution. 
//
// Parameters:
//   Parameters - Structure - (return value) client run parameter structure.
//
// Implementation example:
//  You can use the following template to set up client run parameters:
//  Parameters.Insert(<ParameterName>, <script that gets parameter values>);
//
Procedure ClientParameters(Parameters) Export
	
EndProcedure

// Returns the structure of parameters required for executing the configuration client
// script during exiting the application, namely in the following event handlers:
// - BeforeExit, 
// - OnExit.
//
// Parameters:
//  Parameters - Structure - (return value) exit client run parameter structure.
//
// Implementation example:
//  You can use the following template to set up client run parameters:
//  Parameters.Insert(<ParameterName>, <script that gets parameter values>);
//
Procedure ClientParametersOnExit(Parameters) Export
	
EndProcedure

// Is intended for setting up subsystem parameters.
//
// Parameters:
//  CommonParameters - Structure - structure with the following properties:
//                     * PersonalSettingsFormName        - String - name of the form intended for editing personal
//                                                         settings.
//                                                         In the previous versions this form was defined in
//                                                         CommonUseOverridable.PersonalSettingsFormName.
//                     * LowestPlatformVersion           - String - full number of the lowest platform version required
//                                                         for starting the application. For example: "8.3.4.365".
//                                                         Previously was defined in 
//                                                         CommonUseOverridable.GetMinRequiredPlatformVersion.
//                     * MustExit                        - Boolean - default value is False.
//                     * AskConfirmationOnExit           - Boolean - default value is True. If False is passed, the
//                                                         application does not prompt the user for exit confirmation if
//                                                         it is not set in the user application settings.
//                     * DisableMetadataObjectIDsCatalog - Boolean - disables the MetadataObjectIDs catalog filling and
//                                                         the procedure of importing/exporting catalog items in the DIB
//                                                         nodes.
//                                                         For partial embedding certain library functions into the
//                                                         configuration without enabling support.
//
Procedure BaseFunctionalityCommonParametersOnDefine(CommonParameters) Export
	
	// _Demo begin example
	//_DemoStandardSubsystems.BaseFunctionalityCommonParametersOnDefine(CommonParameters);
	// _Demo the end example
	
EndProcedure

// Fills data exchange message placement settings or performs a custom metadata
// objects ID import from the master node.
//
// Parameters:
//  StandardProcessing - Boolean, default value is True, if False is passed, the
//                       standard metadata object ID import using the DataExchange 
//                       subsystem mechanism is skipped (the same behavior appears if
//                       the application does not include the DataExchange subsystem).
//
Procedure MetadataObjectIDsInSubordinateDIBNodeBeforeImport(StandardProcessing) Export
	
	// _Demo begin example
	If CommonUse.SubsystemExists("StandardSubsystems.DataExchange") Then
		If GetFunctionalOption("UseDataSynchronization") <> True Then
			// Converting exchange transport settings, as is.
			// Enabling the data synchronization.
		EndIf;
	Else
		StandardProcessing = False;
		// Importing metadata object IDs from the exchange messages.
	EndIf;
	// _Demo end example
	
EndProcedure

// Fills a structure with arrays of supported versions of all subsystems to be 
// versioned. The procedure uses subsystem names as keys.
// Provides functionality of the InterfaceVersion web service.
// At the embedding stage you have to change the procedure body so that it returns
// actual version sets (see the following example).
//
// Parameters:
// SupportedVersionStructure - structure with the following parameters: 
//                            * Keys   - subsystem names. 
//                            * Values - arrays of supported version descriptions.
//
// Example:
//
// // FileTransferService
// VersionArray = New Array;
// VersionArray.Add("1.0.1.1");	
// VersionArray.Add("1.0.2.1"); 
// SupportedVersionStructure.Insert("FileTransferService", VersionArray);
// // End FileTransferService
//
Procedure SupportedInterfaceVersionsOnDefine(SupportedVersionStructure) Export
	
EndProcedure

// Parameters of the functional options that affect the interface and the desktop.
// For example, if the functional option values are stored in resources of an
// information register, the functional option parameters can define filters by
// register dimensions that are taken into account during reading values of this
// functional option.
//
// Parameters:
//   InterfaceOptions - Structure - parameter values of functional options that are 
//                      set for the command interface.
//                      The structure item key defines the parameter name and the
//                      value defines the current parameter value.
//
// See also the following global context methods:
//   - GetInterfaceFunctionalOption(),
//   - SetInterfaceFunctionalOptionParameters(),
//   - GetInterfaceFunctionalOptionParameters().
//
Procedure InterfaceFunctionalOptionParametersOnDefine(InterfaceOptions) Export
	
EndProcedure
 
#EndRegion