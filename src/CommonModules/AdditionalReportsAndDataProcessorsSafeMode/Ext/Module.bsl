////////////////////////////////////////////////////////////////////////////////
// Additional reports and data processors subsystem, safe mode extension. 
////////////////////////////////////////////////////////////////////////////////


#Region ObsoleteInterface

// Creates XMLReader object and initializes it with data data from a file
// located in a temporary storage. 
// The file address is specified in BinaryDataAddress parameter.
//
// Parameters:
//  BinaryDataAddress - String - address of the binary data file
//                      in a temporary storage. 
//  ReaderSettings    - XMLReaderSettings - used for reading XML data.
//
// Returns: XMLReader.
//
Function XMLReaderFromBinaryData(Val BinaryDataAddress, Val ReaderSettings = Undefined) Export
	
	ValidateCallByEnvironmentCorrectness();
	
	String = AdditionalReportsAndDataProcessorsSafeModeServerCall.StringFromBinaryData(
		BinaryDataAddress);
	
	XMLReader = New XMLReader();
	XMLReader.SetString(String);
	
	Return XMLReader;
	
EndFunction

// Writes content of XMLWriter object to a temporary file, stores binary data to
// a temporary storage, and returns address of file binary data in the temporary storage.
//
// Parameters:
//  XMLWriter - XMLWriter or CanonicalXMLWriter object - the object whose content is written.
//  Address   - String or UUID - address in a temporary storage where data will be stored,
//              or UUID of the form whose temporary storage will store the data 
//              (in this case the function returns the new address),
//              see description of PutToTempStorage global context method in Syntax Assistant.
//
// Returns: String, address in a temporary storage.
//
Function XMLWriterToBinaryData(Val XMLWriter, Val Address) Export
	
	ValidateCallByEnvironmentCorrectness();
	
	String = XMLWriter.Close();
	Return AdditionalReportsAndDataProcessorsSafeModeServerCall.StringToBinaryData(
		String,
		,
		,
		,
		Address);
	
EndFunction

// Creates HTMLReader object and initializes it with data from a file 
// located in a temporary storage.
// The file address is specified in BinaryDataAddress parameter.
//
// Parameters:
//  BinaryDataAddress - String - address of the binary data file
//                      in a temporary storage.
//  Encoding          - String - encoding used for HTML parsing. 
//
// Returns: HTMLReader.
//
Function HTMLReaderFromBinaryData(Val BinaryDataAddress, Val Encoding = Undefined) Export
	
	ValidateCallByEnvironmentCorrectness();
	
	String = AdditionalReportsAndDataProcessorsSafeModeServerCall.StringFromBinaryData(
		BinaryDataAddress);
	
	HTMLReader = New HTMLReader();
	HTMLReader.SetString(String);
	
	Return HTMLReader;
	
EndFunction

// Writes content of HTMLWriter object to a temporary file, stores binary data to
// a temporary storage, and returns address of file binary data in the temporary storage.
//
// Parameters:
//  HTMLWriter - HTMLWriter object whose content is written.
//  Address    - String or UUID - address in a temporary storage where data will be stored,
//               or UUID of the form whose temporary storage will store the data 
//               (in this case the function returns the new address), 
//               see description of PutToTempStorage global context method in Syntax Assistant.
//
// Returns: String, address in a temporary storage.
//
Function HTMLWriterToBinaryData(Val HTMLWriter, Val Address) Export
	
	ValidateCallByEnvironmentCorrectness();
	
	String = HTMLWriter.Close();
	Return AdditionalReportsAndDataProcessorsSafeModeServerCall.StringToBinaryData(
		String,
		,
		,
		,
		Address);
	
EndFunction

// Creates FastInfosetReader object and initializes it with data from a file
// located in a temporary storage. 
// The file address is specified in BinaryDataAddress parameter.
//
// Parameters:
//  BinaryDataAddress - String - address of the binary data file
//                      in a temporary storage.
//
// Returns: FastInfosetReader.
//
Function FastInfosetReaderFromBinaryData(Val BinaryDataAddress) Export
	
	ValidateCallByEnvironmentCorrectness();
	
	Data = GetFromTempStorage(BinaryDataAddress);
	FastInfosetReader = New FastInfosetReader();
	FastInfosetReader.SetBinaryData(Data);
	
	Return FastInfosetReader;
	
EndFunction

// Writes content of FastInfoSetWriter object to a temporary file, stores binary data to
// a temporary storage, and returns address of file binary data in the temporary storage.
//
// Parameters:
//  FastInfosetWriter - FastInfosetWriter object whose content is written.
//  Address           - String or UUID - address in a temporary storage where
//                      data will be stored, or UUID of the form whose temporary storage
//                      will store the data (in this case the function returns the new address),
//                      see description of PutToTempStorage global context method in Syntax Assistant.
//
// Returns: String, address in a temporary storage.
//
Function WritingFastInfosetToBinaryData(Val FastInfosetWriter, Val Address) Export
	
	ValidateCallByEnvironmentCorrectness();
	
	Data = FastInfosetWriter.Close();
	Address = PutToTempStorage(Data, Address);
	
	Return Address;
	
EndFunction

// Creates a COM object for use in additional reports and data processors
// that are executed in server context.
//
// The object that calls the function must be granted the following permission:
// {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/1.0.0.1}CreateComObject
//
// Parameters:
//  SessionKey - UUID - session key of safe mode extension.
//  ProgId     - String - ProgID of the COM class registered in the system.
//               For example, "Excel.Application".
//
// Result:
//  COMObject.
//
Function CreateCOMObject(Val SessionKey, Val ProgId) Export
	
	ValidateCallByEnvironmentCorrectness();
	
	AdditionalReportsAndDataProcessorsSafeModeInternal.ValidateOperationLegitimacy(SessionKey,
		AdditionalReportsAndDataProcessorsSafeModeInterface.PermissionToCreateCOMObject(
			ProgId));
	
	Return New COMObject(ProgId);
	
EndFunction

// Attaches an add-in from a common configuration template
// for using it in additional reports and data processors 
// that are executed in server context.
//  
// The object that calls the function must be granted the following permission:
// {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/1.0.0.1}AttachAddin
//  
// Parameters:
//  SessionKey         - UUID - session key of safe mode extension.
//  CommonTemplateName - String - name of common configuration template that stores the add-in.
//                       For example, "BarcodePrintingAddIn". 
//  AddInName          - String - add-in name that satisfies 1C:Enterprise script naming conventions. 
//  AddInType          - AddInType.
//  
// Result: Boolean - if True, the add-in is attached successfully.
//  
//
Function AttachAddInFromCommonConfigurationTemplate(Val SessionKey, Val CommonTemplateName, Val AddInName, Val AddInType) Export
	
	ValidateCallByEnvironmentCorrectness();
	
	AdditionalReportsAndDataProcessorsSafeModeInternal.ValidateOperationLegitimacy(SessionKey,
		AdditionalReportsAndDataProcessorsSafeModeInterface.ConnectAddInFormConfigurationCommonTemplatePermission(
			CommonTemplateName));
	
	Return AttachAddIn(
		"CommonTemplate." + CommonTemplateName,
		AddInName,
		AddInType);
	
EndFunction

// Attaches an add-in from a configuration metadata object template
// for using it in additional reports and data processors
// that are executed in server context.
//  
// The object that calls the function must be granted the following permission:
// {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/1.0.0.1}AttachAddin
//  
// Parameters:
//  SessionKey     - UUID - session key of safe mode extension.
//  MetadataObject - MetadataObject - add-in template owner. 
//  TemplateName   - String - configuration template name that stores the add-in.  
//                   For example, "BarcodePrintingAddIn".
//  AddInName      - String - add-in name that satisfies 1C:Enterprise script 
//                   naming conventions. 
//  AddInType      - AddInType.
//  
// Result: Boolean - if True, the add-in is attached successfully.
//  
//
Function AttachAddInFromConfigurationTemplate(Val SessionKey, Val MetadataObject, Val TemplateName, Val AddInName, Val AddInType) Export
	
	ValidateCallByEnvironmentCorrectness();
	
	AdditionalReportsAndDataProcessorsSafeModeInternal.ValidateOperationLegitimacy(SessionKey,
		AdditionalReportsAndDataProcessorsSafeModeInterface.PermissionToAttachAddInFromConfigurationTemplate(
			MetadataObject, TemplateName));
	
	Return AttachAddIn(
		MetadataObject.FullName() + ".Template." + TemplateName,
		AddInName,
		AddInType);
	
EndFunction

// Gets a file from an external object, stores it to a temporary 
// storage, and returns address of file binary data in the temporary storage.
//
// The object that calls the function must be granted the following permission:
//
// {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/1.0.0.1}GetFileFromExternalSoftware
//
// Parameters:
//  SessionKey     - UUID - session key of safe mode extension.
//  ExternalObject - ExternalObject - external object that stores the file. 
//  MethodName     - String - name of the external object method that
//                   gets a file from the external object.
//  Parameters     - Array(Arbitrary) - parameters of the method that gets a file from an external object.
//                  For the parameter that stores the file name in the file system,
//                  add the following XDTODataObject to the array:
//                  {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}InternalFileHandler.
//  Address        - String or UUID - address in a temporary storage where
//                   data will be stored, or UUID of the form whose temporary storage
//                   will store the data (in this case the function returns the new address),
//                   see description of PutToTempStorage global context method in Syntax Assistant.
//
// Returns:
//  String, address in a temporary storage.
//
Function GetFileFromExternalObject(Val SessionKey, ExternalObject, Val MethodName, Val Parameters, Val Address = Undefined) Export
	
	ValidateCallByEnvironmentCorrectness();
	
	AdditionalReportsAndDataProcessorsSafeModeInternal.ValidateOperationLegitimacy(SessionKey,
		AdditionalReportsAndDataProcessorsSafeModeInterface.PermissionToGetFileFromExternalObject());
	
	ValidateExternalObjectMethodNameCorrectness(MethodName);
	
	TempFile = GetTempFileName();
	ParameterString = GenerateParameterStringForExternalObjectMethod(Parameters);
	Execute("ExternalObject." + MethodName + "(" + ParameterString + ");");
	
	Address = PutToTempStorage(New BinaryData(TempFile), Address);
	Try
		DeleteFiles(TempFile);
	Except
	EndTry;
	Return Address;
	
EndFunction

// Gets a file from a temporary storage and sends it to an external object.
//
// The object that calls the function must be granted the following permission:
// {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/1.0.0.1}SendFileToExternalSoftware
//
// Parameters:
//  SessionKey        - UUID - session key of safe mode extension.
//  ExternalObject    - ExternalObject - external object that serves as a file source.
//  BinaryDataAddress - String - address of the binary data file in a temporary storage.
//  MethodName        - String - name of the external object method 
//                      that gets a file from an external object.
//  Parameters        - Array(Arbitrary) - parameters of the method that gets a file from an external object.
//                     For the parameter that stores the file name in the file system,
//                     add the following XDTODataObject to the array:
//                     {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/a.b.c.d}InternalFileHandler.
//
Procedure SendFileToExternalObject(Val SessionKey, ExternalObject, Val BinaryDataAddress, Val MethodName, Val Parameters) Export
	
	ValidateCallByEnvironmentCorrectness();
	
	AdditionalReportsAndDataProcessorsSafeModeInternal.ValidateOperationLegitimacy(SessionKey,
		AdditionalReportsAndDataProcessorsSafeModeInterface.PermissionToSendFileToExternalObject());
	
	ValidateExternalObjectMethodNameCorrectness(MethodName);
	
	TempFile = AdditionalReportsAndDataProcessorsSafeModeInternal.GetFileFromTemporaryStorage(BinaryDataAddress);
	ParameterString = GenerateParameterStringForExternalObjectMethod(Parameters);
	Execute("ExternalObject." + MethodName + "(" + ParameterString + ");");
	
	Try
		DeleteFiles(TempFile);
	Except
	EndTry;
	
EndProcedure

// Gets a file from the Internet using HTTP(S) or FTP.
//
// The object that calls the function must be granted the following permission:
// {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/1.0.0.1}GetFileFromInternet
//
// Parameters:
//  SessionKey - UUID - session key of safe mode extension.
//  URL        - String - URL of the file to be downloaded.
//  Port       - Number - network port number.
//  UserName   - String - user name for authorization on a remote server.
//               It should be specified only if authorization is required to get the file.
//  Password   - String - password for authorization on a remote server. 
//               It should be specified only if authorization is required to get the file.
//  Timeout    - operation timeout in seconds, the default value is 20 seconds,
//               the maximum value is 10 minutes.
//
// Result:
//  String - address of the retrieved file in a temporary storage.
//
Function GetFileFromInternet(Val SessionKey, Val URL, Val Port = 0, Val UserName = "", Val Password = "", Val Timeout = 20,Val SecureConnection = Undefined, Val PassiveConnection = Undefined) Export
	
	ValidateCallByEnvironmentCorrectness();
	
	If Not CommonUse.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		Raise NStr("en = 'The application does not support the AdditionalReportsAndDataProcessorsSafeMode.GetFileFromInternet method.'");
	EndIf;
	
	FileReceivingHandler = CommonUse.CommonModule("GetFilesFromInternetClientServer");
	
	If Port = 0 Then
		
		FullURLStructure = CommonUseClientServer.URIStructure(URL);
		
		If Not IsBlankString(FullURLStructure.Port) Then
			ServerName = FullURLStructure.Domain;
			Port = FullURLStructure.Port;
		EndIf;
		
	EndIf;
	
	If Timeout > 600 Then
		Timeout = 600;
	EndIf;
	
	URLStructure = FileReceivingHandler.SplitURL(URL);
	Protocol = URLStructure.Protocol;
	ServerName = URLStructure.ServerName;
	PathToFileAtServer  = URLStructure.PathToFileAtServer;
	
	If Port = 0 Then
		
		If Upper(Protocol) = "HTTP" Then
			Port = 80;
		ElsIf Upper(Protocol) = "FTP" Then
			Port = 21;
		ElsIf Upper(Protocol) = "HTTPS" Then
			Port = 443;
		EndIf;
		
	EndIf;
	
	AdditionalReportsAndDataProcessorsSafeModeInternal.ValidateOperationLegitimacy(SessionKey,
		AdditionalReportsAndDataProcessorsSafeModeInterface.PermissionToGetDataFromInternet(
			Upper(Protocol), ServerName, Port));
			
	ReceivingParameters = New Structure;
	ReceivingParameters.Insert("User",              UserName);
	ReceivingParameters.Insert("Password",          Password);
	ReceivingParameters.Insert("Port",              Port);
	ReceivingParameters.Insert("Timeout",           Timeout);
	ReceivingParameters.Insert("SecureConnection",  SecureConnection);
	ReceivingParameters.Insert("PassiveConnection", PassiveConnection);
	
	Result = FileReceivingHandler.PrepareFileReceiving(
		URL,
		ReceivingParameters,
		New Structure(
			"Storage, Path",
			"TempStorage",
			Undefined));
	
	If Result.Status Then
		Return Result.Path;
	Else
		Raise Result.ErrorMessage;
	EndIf;
	
EndFunction

// Uploads a file to the Internet using HTTP(S) or FTP.
//
// The object that calls the function must be granted the following permission:
// {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/1.0.0.1}SendFileToInternet
//
// Parameters:
//  SessionKey        - UUID - session key of safe mode extension.
//  BinaryDataAddress - String - address of the binary file to be uploaded
//                      in a temporary storage.
//  URL               - String - URL for uploading the file. 
//  Port              - Number - network port number. 
//  UserName          - String - user name for authorization on a remote server. 
//                      It should be specified only if authorization
//                      is required to upload the file. 
//  Password          - String - password for authorization on a remote server. 
//                      It should be specified only if authorization
//                      is required to upload the file.
//   Timeout          - operation timeout in seconds, the default value is 20 seconds,
//                      the maximum value is 10 minutes.
//
Function SendFileToInternet(Val SessionKey, Val BinaryDataAddress, Val URL, Val Port = 0, Val UserName = "", Val Password = "", Val Timeout = 20,Val SecureConnection = Undefined, Val PassiveConnection = Undefined) Export
	
	ValidateCallByEnvironmentCorrectness();
	
	If Not CommonUse.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		Raise NStr("en = 'The application does not support the AdditionalReportsAndDataProcessorsSafeMode.SendFileToInternet method.'");
	EndIf;
	
	GetFilesFromInternetClientServerModule = CommonUse.CommonModule("GetFilesFromInternetClientServer");
	
	If Port = 0 Then
		
		FullURLStructure = CommonUseClientServer.URIStructure(URL);
		
		If Not IsBlankString(FullURLStructure.Port) Then
			ServerName = FullURLStructure.Domain;
			Port = FullURLStructure.Port;
		EndIf;
		
	EndIf;
	
	If Timeout > 600 Then
		Timeout = 600;
	EndIf;
	
	URLStructure = GetFilesFromInternetClientServerModule.SplitURL(URL);
	Protocol = URLStructure.Protocol;
	ServerName = URLStructure.ServerName;
	PathToFileAtServer  = URLStructure.PathToFileAtServer;
	
	AdditionalReportsAndDataProcessorsSafeModeInternal.ValidateOperationLegitimacy(SessionKey,
		AdditionalReportsAndDataProcessorsSafeModeInterface.SendDataToInternetPermission(
			Upper(Protocol), ServerName, Port));
	
	TempFile = AdditionalReportsAndDataProcessorsSafeModeInternal.GetFileFromTemporaryStorage(BinaryDataAddress);
	
	If Upper(Protocol) = "HTTPS" Then
		SecureConnection = True;
	EndIf;
	
	Proxy = GetFilesFromInternetClientServerModule.GetProxy(Protocol);
	
	If Upper(Protocol) = "FTP" Then
		Try
			Connection = New FTPConnection(ServerName, Port, UserName, Password, Proxy, PassiveConnection, Timeout);
		Except
			ErrorInfo = ErrorInfo();
			ErrorMessage = NStr("en = 'Error creating FTP connection to the %1 server:'") + Chars.LF + "%2";
			
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				ErrorMessage, ServerName, DetailErrorDescription(ErrorInfo));
		EndTry;
			
	Else
		If SecureConnection = True Then
			SecureConnection = New OpenSSLSecureConnection;
		Else
			SecureConnection = Undefined;
		EndIf;
		
		Try
			Connection = New HTTPConnection(ServerName, Port, UserName, Password, Proxy, Timeout, SecureConnection);
		Except
			ErrorInfo = ErrorInfo();
			ErrorMessage = NStr("en = 'Error creating HTTP connection to the %1 server:'") + Chars.LF + "%2";
			
			Raise StringFunctionsClientServer.SubstituteParametersInString(ErrorMessage, ServerName, 
				DetailErrorDescription(ErrorInfo));
		EndTry;
	EndIf;
	
	Try
		Connection.Write(TempFile, PathToFileAtServer);
	Except
		ErrorInfo = ErrorInfo();
		ErrorMessage = NStr("en = 'Error uploading file to the %1 server:'") + Chars.LF + "%2";
		
		Raise StringFunctionsClientServer.SubstituteParametersInString(ErrorMessage, ServerName, 
			DetailErrorDescription(ErrorInfo));
	EndTry;
	
EndFunction

// Creates a WSProxy object for web service connection.
//
// The object that calls the function must be granted the following permission:
// {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/1.0.0.1}SoapConnection
//
// Parameters:
//  SessionKey          - UUID - session key of safe mode extension.
//  WSDLAddress         - String - WSDL file location. 
//  NamespaceURI        - String - web service namespace URI. 
//  ServiceName         - String - service name. 
//  ConnectionPointName - String - formed as <ServiceName>Soap if not specified explicitly. 
//  UserName            - String - user name for authorization on the server.
//  Password            - String - user password for authorization on the server. 
//  Timeout             - Number - timeout for proxy operations.
//
// Returns: WSProxy.
//
Function WSConnection(Val SessionKey, Val WSDLAddress, Val NamespaceURI, Val ServiceName, Val EndpointName = "", Val UserName = "", Val Password = "", Val Timeout = 20) Export
	
	ValidateCallByEnvironmentCorrectness();
	
	If Timeout > 600 Then
		Timeout = 600;
	EndIf;
	
	AdditionalReportsAndDataProcessorsSafeModeInternal.ValidateOperationLegitimacy(SessionKey,
		AdditionalReportsAndDataProcessorsSafeModeInterface.WSConnectionPermission(
			WSDLAddress));
	
	Return CommonUse.WSProxy(
		WSDLAddress,
		NamespaceURI,
		ServiceName,
		EndpointName,
		UserName,
		Password,
		Timeout);
	
EndFunction

// Posts documents or clears document posting.
//
// The object that calls the function must be granted the following permission:
// {http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/1.0.0.1}DocumentPosting
//
// Parameters:
//  SessionKey  - UUID - session key of safe mode extension.
//  Documents   - Array(DocumentObject) - array of documents to be written. 
//  WriteMode   - DocumentWriteMode - document writing mode.
//  PostingMode - DocumentPostingMode.
//
Function DocumentPosting(Val SessionKey, Documents, Val WriteMode = Undefined, Val PostingMode = Undefined) Export
	
	ValidateCallByEnvironmentCorrectness();
	
	If WriteMode = Undefined Then
		WriteMode = DocumentWriteMode.Write;
	EndIf;
	
	If PostingMode = Undefined Then
		PostingMode = DocumentPostingMode.RealTime;
	EndIf;
	
	BeginTransaction();
	
	Try
		
		For Each Document In Documents Do
			
			If WriteMode = DocumentWriteMode.Write Then
				
				If Document.Posted Then
					WriteModeToValidate = DocumentWriteMode.Posting;
				Else
					WriteModeToValidate = DocumentWriteMode.UndoPosting;
				EndIf;
				
			Else
				
				WriteModeToValidate = WriteMode;
				
			EndIf;
			
			AdditionalReportsAndDataProcessorsSafeModeInternal.ValidateOperationLegitimacy(SessionKey,
				AdditionalReportsAndDataProcessorsSafeModeInterface.DocumentPostingPermission(
					Document.Metadata().FullName, WriteModeToValidate));
			
			Document.Write(WriteMode, PostingMode);
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndFunction

#EndRegion

#Region InternalProceduresAndFunctions

Procedure ValidateExternalObjectMethodNameCorrectness(Val MethodName)
	
	IllegalChars = New Array();
	IllegalChars.Add(",");
	IllegalChars.Add("(");
	IllegalChars.Add(")");
	IllegalChars.Add(";");
	
	For Each IllegalChar In IllegalChars Do
		
		If Find(MethodName, IllegalChar) > 0 Then
			
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Invalid COM object or add-in object method name: %1.'"),
				MethodName);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function GenerateParameterStringForExternalObjectMethod(Val Parameters)
	
	ParameterString = "";
	Iterator = 0;
	For Each Parameter In Parameters Do
		
		If Not IsBlankString(ParameterString) Then
			ParameterString = ParameterString + ", ";
		EndIf;
		
		FileSending = False;
		If TypeOf(Parameter) = Type("XDTOObjectType") Then
			If Parameter = AdditionalReportsAndDataProcessorsSafeModeInterface.ParameterPassedFile() Then
				FileSending = True;
			EndIf;
		EndIf;
		
		If FileSending Then
			ParameterString = ParameterString + "TempFile";
		Else
			ParameterString = ParameterString + "Parameters[" + Format(Iterator, "NFD=0; NZ=0; NG=0") + "]";
		EndIf;
		
		Iterator = Iterator + 1;
		
	EndDo;
	
	Return ParameterString;
	
EndFunction

Procedure ValidateCallByEnvironmentCorrectness()
	
	If Not AdditionalReportsAndDataProcessorsSafeModeInternal.ValidateCallByEnvironmentCorrectness() Then
		
		Raise NStr("en = 'Invalid AdditionalReportsAndDataProcessorsSafeModeServerCall common module function call.
                     |In the safe mode exported functions of this module must
                     |be only called from scenarios.'");
		
	EndIf;
	
EndProcedure

#EndRegion
