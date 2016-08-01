////////////////////////////////////////////////////////////////////////////////
// Additional reports and data processors subsystem, safe mode extension.
// Procedures and functions with reusable return values.
// 
////////////////////////////////////////////////////////////////////////////////

#Region Interface

// Returns an array of methods that can be executed in safe mode.
//
// Returns: Array.
//
Function GetAllowedMethods() Export
	
	Result = New Array();
	
	// AdditionalReportsAndDataProcessorsSafeMode
	Result.Add("AdditionalReportsAndDataProcessorsSafeMode.ReadingXMLFromBinaryData");
	Result.Add("AdditionalReportsAndDataProcessorsSafeMode.WritingXMLToBinaryData");
	Result.Add("AdditionalReportsAndDataProcessorsSafeMode.ReadingHTMLFromBinaryData");
	Result.Add("AdditionalReportsAndDataProcessorsSafeMode.WritingHTMLToBinaryData");
	Result.Add("AdditionalReportsAndDataProcessorsSafeMode.ReadingFastInfosetFromBinaryData");
	Result.Add("AdditionalReportsAndDataProcessorsSafeMode.WritingFastInfosetToBinaryData");
	Result.Add("AdditionalReportsAndDataProcessorsSafeMode.CreateComObject");
	Result.Add("AdditionalReportsAndDataProcessorsSafeMode.AttachAddInFromConfigurationGeneralTemplate");
	Result.Add("AdditionalReportsAndDataProcessorsSafeMode.AttachAddInFromConfigurationTemplate");
	Result.Add("AdditionalReportsAndDataProcessorsSafeMode.GetFileFromExternalObject");
	Result.Add("AdditionalReportsAndDataProcessorsSafeMode.TransferFileToExternalObject");
	Result.Add("AdditionalReportsAndDataProcessorsSafeMode.GetFileFromInternet");
	Result.Add("AdditionalReportsAndDataProcessorsSafeMode.UploadFileToInternet");
	Result.Add("AdditionalReportsAndDataProcessorsSafeMode.WSLink");
	Result.Add("AdditionalReportsAndDataProcessorsSafeMode.DocumentPosting");
	// End AdditionalReportsAndDataProcessorsSafeMode
	
	// AdditionalReportsAndDataProcessorsSafeModeServerCall
	Result.Add("AdditionalReportsAndDataProcessorsSafeModeServerCall.TextDocumentFromBinaryData");
	Result.Add("AdditionalReportsAndDataProcessorsSafeModeServerCall.TextDocumentToBinaryData");
	Result.Add("AdditionalReportsAndDataProcessorsSafeModeServerCall.SpreadsheetDocumentFromBinaryData");
	Result.Add("AdditionalReportsAndDataProcessorsSafeModeServerCall.SpreadsheetDocumentToBinaryData");
	Result.Add("AdditionalReportsAndDataProcessorsSafeModeServerCall.FormattedDocumentToBinaryData");
	Result.Add("AdditionalReportsAndDataProcessorsSafeModeServerCall.StringFromBinaryData");
	Result.Add("AdditionalReportsAndDataProcessorsSafeModeServerCall.StringToBinaryData");
	Result.Add("AdditionalReportsAndDataProcessorsSafeModeServerCall.UnpackArchive");
	Result.Add("AdditionalReportsAndDataProcessorsSafeModeServerCall.PackFilesToArchive");
	Result.Add("AdditionalReportsAndDataProcessorsSafeModeServerCall.ExecuteScenarioInSafeMode");
	// End AdditionalReportsAndDataProcessorsSafeModeServerCall
	
	Return New FixedArray(Result);
	
EndFunction

// Returns a dictionary of synonyms and parameters of additional report and data processor permission types (for displaying in the user interface).
//
// Returns:
//   FixedMap:
//       Key   - XDTOType that is mapped to the permission type.
//       Value - Structure with the following keys:
//            Presentation - String, brief description of permission type. 
//            Details      - String, detailed description of permission type. 
//            Consequences - String.
//            Parameters   - ValueTable with the following columns:
//               Name    - String, name of the permission type  that matches XDTOType. 
//               Details - String, description of permissions that take effect 
//                         if the parameter value is specified.
 
//               AnyValueDetails - String, description of permissions that take effect 
//                         if the parameter value is not specified.
//         
Function Dictionary() Export
	
	Result = New Map();
	
	// {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}GetFileFromInternet
	
	Presentation = NStr("en = 'Receive data from the Internet'");
	Details = NStr("en = 'Additional report or data processor is allowed to receive data from the Internet.'");
	
	Parameters = ParameterTable();
	AddParameter(Parameters, "Host", NStr("en = 'from server: %1'"), NStr("en = 'from any server'"));
	AddParameter(Parameters, "Protocol", NStr("en = 'using protocol: %1'"), NStr("en = 'using any protocol'"));
	AddParameter(Parameters, "Port", NStr("en = 'through port: %1'"), NStr("en = 'through any port'"));
	
	Result.Insert(
		AdditionalReportsAndDataProcessorsSafeModeInterface.DataReceivingFromInternetType(),
		New Structure(
			"Presentation,Details,Parameters",
			Presentation,
			Details,
			Parameters));
	
	// End {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}GetFileFromInternet
	
	// {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}SendFileToInternet
	
	Presentation = NStr("en = 'Send data to the Internet'");
	Details = NStr("en = 'Additional report or data processor is allowed to send data to the Internet'");
	Consequences = NStr("en = 'Attention! Additional reports or data processors can perform operations not authorized explicitly by infobase administrator, which might include sending data to the Internet.
                        |
                        |Use the additional report or data processor only if you trust its vendor, and also set appropriate restrictions (server, protocol and port) to the data processor permissions.'");
	
	Parameters = ParameterTable();
	AddParameter(Parameters, "Host", NStr("en = 'to server: %1'"), NStr("en = 'to any server'"));
	AddParameter(Parameters, "Protocol", NStr("en = 'using protocol: %1'"), NStr("en = 'using any protocol'"));
	AddParameter(Parameters, "Port", NStr("en = 'through port: %1'"), NStr("en = 'through any port'"));
	
	Result.Insert(
		AdditionalReportsAndDataProcessorsSafeModeInterface.DataSendingToInternetType(),
		New Structure(
			"Presentation,Details,Consequences,Parameters",
			Presentation,
			Details,
			Consequences,
			Parameters));
	
	// End {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}SendFileToInternet
	
	// {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}SoapConnect
	
	Presentation = NStr("en = 'Access web services in the Internet'");
	Details = NStr("en = 'Additional report or data processor is allowed to access web services located in the Internet. This can include sending data to the Internet or receiving data from the Internet.'");
	Consequences = NStr("en = 'Attention! Additional reports or data processors can use web services to perform operations not authorized explicitly by infobase administrator.
                        |
                        |Use the additional report or data processor only if you trust its vendor, and also set appropriate restrictions (connection address) to the data processor permissions.'");
	
	Parameters = ParameterTable();
	AddParameter(Parameters, "WsdlDestination", NStr("en = 'at address: %1'"), NStr("en = 'at any address'"));
	
	Result.Insert(
		AdditionalReportsAndDataProcessorsSafeModeInterface.WSConnectionType(),
		New Structure(
			"Presentation,Details,Consequences,Parameters",
			Presentation,
			Details,
			Consequences,
			Parameters));
	
	// End {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}SoapConnect
	
	// {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}CreateComObject
	
	Presentation = NStr("en = 'Create COM objects'");
	Details = NStr("en = 'Additional report or data processor is allowed to utilize third-party software functionality using COM connections.'");
	Consequences = NStr("en = 'Attention! Additional reports or data processors can use third-party software to perform operations not authorized explicitly by infobase administrator, including operations intended to bypass safe mode restrictions.
                        |
                        |Use the additional report or data processor only if you trust its vendor, and set appropriate restrictions (software ID) to the data processor permissions.'");
	
	Parameters = ParameterTable();
	AddParameter(Parameters, "ProgId", NStr("en = 'with software ID: %1'"), NStr("en = 'with any software ID'"));
	
	Result.Insert(
		AdditionalReportsAndDataProcessorsSafeModeInterface.COMObjectCreationType(),
		New Structure(
			"Presentation,Details,Consequences,Parameters",
			Presentation,
			Details,
			Consequences,
			Parameters));
	
	// End {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}CreateComObject
	
	// {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}AttachAddin
	
	Presentation = NStr("en = 'Create add-in objects'");
	Details = NStr("en = 'Additional report or data processor is allowed to utilize third-party software functionality through creation of add-in objects based on add-ins supplied in the configuration template.'");
	Consequences = NStr("en = 'Attention! Additional reports or data processors can use third-party software to perform operations not authorized explicitly by infobase administrator, including operations intended to bypass safe mode restrictions.
                        |
                        |Use the additional report or data processor only if you trust its vendor, and set appropriate restrictions (name of the template used to attach an add-in) to the data processor permissions.'");
	
	Parameters = ParameterTable();
	AddParameter(Parameters, "TemplateName", NStr("en = 'from template: %1'"), NStr("en = 'from any template'"));
	
	Result.Insert(
		AdditionalReportsAndDataProcessorsSafeModeInterface.AddInAttachingType(),
		New Structure(
			"Presentation,Details,Consequences,Parameters",
			Presentation,
			Details,
			Consequences,
			Parameters));
	
	// End {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}AttachAddin
	
	// {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}GetFileFromExternalSoftware
	
	Presentation = NStr("en = 'Receive files from external objects'");
	Details = NStr("en = 'Additional report or data processor is allowed to receive files from third-party software (for example, using a COM connection or an add-in).'");
	
	Result.Insert(
		AdditionalReportsAndDataProcessorsSafeModeInterface.FileReceivingFromExternalObjectType(),
		New Structure(
			"Presentation,Details",
			Presentation,
			Details));
	
	// End {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}GetFileFromExternalSoftware
	
	// {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}SendFileToExternalSoftware
	
	Presentation = NStr("en = 'Send files to external objects'");
	Details = NStr("en = 'Additional report or data processor is allowed to send files to third-party software (for example, using a COM connection or an add-in).'");
	
	Result.Insert(
		AdditionalReportsAndDataProcessorsSafeModeInterface.TransferFileToExternalObjectType(),
		New Structure(
			"Presentation,Details",
			Presentation,
			Details));
	
	// End {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}SendFileToExternalSoftware
	
	// {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}SendFileToInternet
	
	Presentation = NStr("en = 'Post documents'");
	Details = NStr("en = 'Additional report or data processor is allowed to post documents or clear posting.'");
	
	
  Parameters = ParameterTable();
  AddParameter(Parameters, "DocumentType", NStr("en = 'documents with type %1'"), NStr("en = 'any documents'"));
  AddParameter(Parameters, "Action", NStr("en = 'allowed action: %1'"), NStr("en = 'both post and clear posting'"));
	
	Result.Insert(
		AdditionalReportsAndDataProcessorsSafeModeInterface.DocumentPostingType(),
		New Structure(
			"Presentation,Details,Parameters,ShowToUser",
			Presentation,
			Details,
			Parameters));
	
	// End {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}SendFileToInternet
	
	Return Result;
	
EndFunction

#EndRegion

#Region InternalProceduresAndFunctions

Procedure AddParameter(Val ParameterTable, Val Name, Val Details, Val AnyValueDetails)
	
	Parameter = ParameterTable.Add();
	Parameter.Name = Name;
	Parameter.Details = Details;
	Parameter.AnyValueDetails = AnyValueDetails;
	
EndProcedure

Function ParameterTable()
	
	Result = New ValueTable();
	Result.Columns.Add("Name", New TypeDescription("String"));
	Result.Columns.Add("Details", New TypeDescription("String"));
	Result.Columns.Add("AnyValueDetails", New TypeDescription("String"));
	
	Return Result;
	
EndFunction

#EndRegion
