////////////////////////////////////////////////////////////////////////////////
// Additional reports and data processors subsystem, safe mode extension.
// 
////////////////////////////////////////////////////////////////////////////////

#Region ObsoleteInterface

// Creates a TextDocument object and fills it with data from a file stored a in temporary storage. 
// The temporary storage address is set in BinaryDataAddress parameter.
// Parameters:
// BinaryDataAddress - String - file binary data address in a temporary storage. 
// FileType          - TextEncoding or String - text encoding of the file, 
//                   see description of TextDocument.Read() method in Syntax Assistant.
// LineSeparator     - String - line separator, see description 
//                   of TextDocument.Read() method in Syntax Assistant.
//
// Returns: TextDocument.
//
Function TextDocumentFromBinaryData(Val BinaryDataAddress, Val FileType = Undefined, Val LineSeparator = Undefined) Export
	
	ValidateCallByEnvironmentCorrectness();
	
	TempFile = AdditionalReportsAndDataProcessorsSafeModeInternal.GetFileFromTemporaryStorage(BinaryDataAddress);
	TextDocument = New TextDocument();
	TextDocument.Read(TempFile, FileType, LineSeparator);
	Try
		DeleteFiles(TempFile);
	Except
	EndTry;
	
	Return TextDocument;
	
EndFunction

// Writes a text document to a temporary file, stores binary data to
// a temporary storage, and returns file binary data address in the temporary storage.
//
// Parameters:
//  TextDocument  - TextDocument to be stored. 
//  FileType      - TextEncoding or String - text encoding of the file,
//                see description of TextDocument.Write() method in Syntax Assistant.
//  LineSeparator - String - line separator, see description 
//                 of TextDocument.Write() method in Syntax Assistant. 
//  Address       - String or UUID - address in a temporary storage where data
//                will be stored, or UUID of the form whose temporary storage 
//                will stored the data, see description of PutToTempStorage global
//                context method in Syntax Assistant.
//
// Returns: String - address in a temporary storage.
//
Function TextDocumentToBinaryData(Val TextDocument, Val FileType = Undefined, Val LineSeparator = Undefined, Val Address = Undefined) Export
	
	ValidateCallByEnvironmentCorrectness();
	
	TempFile = GetTempFileName();
	TextDocument.Write(TempFile, FileType, LineSeparator);
	Address = PutToTempStorage(New BinaryData(TempFile), Address);
	Try
		DeleteFiles(TempFile);
	Except
	EndTry;
	
	Return Address;
	
EndFunction

// Creates a SpreadsheetDocument object and fills it with data from a file stored in a temporary storage. 
// The temporary storage address is set in BinaryDataAddress parameter.
//
// Parameters:
//  BinaryDataAddress - String - file binary data address in a temporary storage.
//
// Returns: SpreadsheetDocument.
//
Function SpreadsheetDocumentFromBinaryData(Val BinaryDataAddress) Export
	
	ValidateCallByEnvironmentCorrectness();
	
	TempFile = AdditionalReportsAndDataProcessorsSafeModeInternal.GetFileFromTemporaryStorage(BinaryDataAddress);
	SpreadsheetDocument = New SpreadsheetDocument();
	SpreadsheetDocument.Read(TempFile);
	Try
		DeleteFiles(TempFile);
	Except
	EndTry;
	
	Return SpreadsheetDocument;
	
EndFunction

// Writes a spreadsheet document to a temporary file, stores binary data
// to a temporary storage, and returns file binary data address in the temporary storage.
//
// Parameters:
//  SpreadsheetDocument - SpreadsheetDocument to be stored.
//  FileType            - SpreadsheetDocumentFileType - spreadsheet document format,
//                      see description of SpreadsheetDocument.Read() method in Syntax Assistant. 
//  Address             - String or UUID - address in a temporary storage where data
//                      will be stored, or UUID of the form whose temporary storage will store the
//                      data (in this case the function returns the new address), see description
//                      of PutToTempStorage global context method in Syntax Assistant.
//
// Returns: String - address in a temporary storage.
//
Function SpreadsheetDocumentToBinaryData(Val SpreadsheetDocument, Val FileType = Undefined, Val Address = Undefined) Export
	
	ValidateCallByEnvironmentCorrectness();
	
	TempFile = GetTempFileName();
	SpreadsheetDocument.Write(TempFile, FileType);
	Address = PutToTempStorage(New BinaryData(TempFile), Address);
	Try
		DeleteFiles(TempFile);
	Except
	EndTry;
	
	Return Address;
	
EndFunction

// Writes a formatted document to a temporary file, stores binary data to
// a temporary storage, and returns file binary data address in the temporary storage.
//
// Parameters:
//  FormattedDocument - FormattedDocument to be stored. 
//  FileType          - FormattedDocumentFileType - formatted document format,
//                    see description of FormattedDocument.Write() method in Syntax Assistant.
//  Address           - String or UUID - address in a temporary storage where data
//                    will be stored, or UUID of the form whose temporary storage will 
//                    store the data (in this case the function returns the new address),
//                    see description of PutToTempStorage global context method in Syntax Assistant.
//
// Returns: String - address in a temporary storage.
//
Function FormattedDocumentToBinaryData(Val FormattedDocument, Val FileType = Undefined, Val Address = Undefined) Export
	
	ValidateCallByEnvironmentCorrectness();
	
	TempFile = GetTempFileName();
	FormattedDocument.Write(TempFile, FileType);
	Address = PutToTempStorage(New BinaryData(TempFile), Address);
	Try
		DeleteFiles(TempFile);
	Except
	EndTry;
	
	Return Address;
	
EndFunction

// Returs text contents of a file in the temporary storage. 
// The temporary storage address is set in BinaryDataAddress parameter.
//
// Parameters:
//  BinaryDataAddress        - String - file binary data address in a temporary storage.
//  Encoding                 - TextEncoding or String - text encoding of the file,
//                           see description of TextReader.Open() method in Syntax Assistant.
//  LineSeparator            - String - line separator in the file, see description 
//                           of TextDocument.Open() method in Syntax Assistant.
//  ConvertibleLineSeparator - String - string that is converted to standart line separator,
//                           see description of TextReader.Open() method in Syntax Assistant.   
//
// Returns: String.
//
Function StringFromBinaryData(Val BinaryDataAddress, Val Encoding = Undefined, Val LineSeparator = Undefined, Val ConvertibleLineSeparator = Undefined) Export
	
	ValidateCallByEnvironmentCorrectness();
	
	TempFile = AdditionalReportsAndDataProcessorsSafeModeInternal.GetFileFromTemporaryStorage(BinaryDataAddress);
	Read = New TextReader();
	Read.Open(TempFile, Encoding, LineSeparator, ConvertibleLineSeparator );
	Result = Read.Read();
	Read.Close();
	Try
		DeleteFiles(TempFile);
	Except
	EndTry;
	
	Return Result;
	
EndFunction

// Writes a passed string to a temporary file, stores binary data
// to a temporary storage, and returns file binary data address in the temporary storage.
//
// Parameters:
//  String                   - FormattedDocument to be stored.
//  Encoding                 - TextEncoding or String - text encoding of the file, 
//                           see description of TextReader.Open() in Syntax Assistant. 
//  LineSeparator            - String - line separator in the file,
//                           see description of TextDocument.Open() method in Syntax Assistant. 
//  ConvertibleLineSeparator - String - string that is converted to standart line separator, 
//                           see description of TextReader.Open() method in Syntax Assistant.
//  Address                  - String or UUID - address in a temporary storage where data
//                           will be stored, or UUID of the form whose temporary storage will 
//                           store the data (in this case the function returns the new address),
//                           see description of PutToTempStorage global
//                           context method in Syntax Assistant.
 
//
// Returns: String - address in a temporary storage.
//
Function StringToBinaryData(Val String, Val Encoding = Undefined, Val LineSeparator = Undefined, Val ConvertibleLineSeparator = Undefined, Val Address = Undefined) Export
	
	ValidateCallByEnvironmentCorrectness();
	
	TempFile = GetTempFileName();
	Write = New TextWriter();
	Write.Open(TempFile, Encoding, LineSeparator, False, ConvertibleLineSeparator);
	Write.Write(String);
	Write.Close();
	Address = PutToTempStorage(New BinaryData(TempFile), Address);
	Try
		DeleteFiles(TempFile);
	Except
	EndTry;
	
	Return Address;
	
EndFunction

// Unpacks a ZIP archive.
//
// Parameters:
//  BinaryDataAddress - String - file binary data address in a temporary storage.
//  Password          - String - password for accessing the ZIP file if the file is encrypted.
//  FormID            - UUID - form UUID, see description of PutToTempStorage
//                    global context method in Syntax Assistant.
//
// Returns:
//  Map:
//    Key   - file or directory name in the archive.
//    Value – for archived files, it is the file binary data temporary storage address.
//    For directories, it is a similar map.  
//
Function UnpackArchive(Val BinaryDataAddress, Val Password = Undefined, Val FormID = Undefined) Export
	
	ValidateCallByEnvironmentCorrectness();
	
	TempFile = AdditionalReportsAndDataProcessorsSafeModeInternal.GetFileFromTemporaryStorage(BinaryDataAddress);
	DirectoryForUnpacking = GetTempFileName();
	CreateDirectory(DirectoryForUnpacking);
	Read = New ZipFileReader();
	Read.Open(TempFile, Password);
	Read.ExtractAll(DirectoryForUnpacking, ZIPRestoreFilePathsMode.Restore);
	Read.Close();
	ArchiveDescription = New Map;
	ArchiveUnpackingIteration(DirectoryForUnpacking + "\", ArchiveDescription, FormID);
	Try
		DeleteFiles(TempFile);
		DeleteFiles(DirectoryForUnpacking);
	Except
	EndTry;
	
	Return ArchiveDescription;
	
EndFunction

// Packs files to a ZIP archive.
//
// Parameters:
//  ArchiveDescription - Map:
//    Key   - file or directory name in the archive.
//    Value – for archived files, it is the file binary data temporary storage address.
//    For directories, it is a similar.  
//  Password          - String - password for accessing the ZIP file if the file is encrypted.
//  Comment           - String - a comment describing the ZIP file.
//  CompressionMethod - ZIPCompressionMethod - the method used to compress the ZIP file.
//  CompressionLevel  - ZIPCompressionLevel - the level of data compression.
//  EncryptionMethod  - ZIPEncryptionMethod - encryption algorithm
//                    that is used to encrypte the ZIP file.
//  Address - Return value.
//
// Returns:
//  String - address of archive binary data in a temporary storage.
//
Function PackFilesToArchive(Val ArchiveDescription, Val Password = Undefined, Val Comment = Undefined, Val CompressionMethod = Undefined, Val CompressionLevel = Undefined, Val EncryptionMethod = Undefined, Val Address = Undefined) Export
	
	ValidateCallByEnvironmentCorrectness();
	
	If CompressionMethod = Undefined Then
		CompressionMethod = ZIPCompressionMethod.Deflate;
	EndIf;
	
	If CompressionLevel = Undefined Then
		CompressionLevel = ZIPCompressionLevel.Optimal;
	EndIf;
	
	If EncryptionMethod = Undefined Then
		EncryptionMethod = ZIPEncryptionMethod.Zip20;
	EndIf;
	
	TempFile = GetTempFileName();
	PackagingDirectory = GetTempFileName();
	CreateDirectory(PackagingDirectory);
	ArchivePackagingIteration(ArchiveDescription, PackagingDirectory + "\");
	Write = New ZipFileWriter();
	Write.Open(TempFile, Password, Comment, CompressionMethod, CompressionLevel, EncryptionMethod);
	Write.Add(PackagingDirectory,
		ZIPStorePathMode.StoreRelativePath,
		ZIPSubDirProcessingMode.ProcessRecursively);
	Write.Write();
	Address = PutToTempStorage(New BinaryData(TempFile), Address);
	Try
		DeleteFiles(TempFile);
		DeleteFiles(PackagingDirectory);
	Except
	EndTry;
	
	Return Address;
	
EndFunction

// Executes additional report or data processor scenario in safe mode.
//
// Parameters:
//  SessionKey       - UUID - session key of safe mode extension.
//  ScenarioAddress  - String - address of value table (scenario) in a temporary storage.
//  ExecutionParameters.
//  ParametersToSave - Structure.
//  TargetObjects.
// Returns: Arbitrary.
//
Function ExecuteScenarioInSafeMode(Val SessionKey, Val ScenarioAddress, ExecutionParameters = Undefined, ParametersToSave = Undefined, TargetObjects = Undefined) Export
	
	ValidateCallByEnvironmentCorrectness();
	
	Scenario = GetFromTempStorage(ScenarioAddress);
	ExecutableObject = AdditionalReportsAndDataProcessors.GetExternalDataProcessorsObject(
		Catalogs.AdditionalReportsAndDataProcessors.GetRef(SessionKey));
	
	AdditionalReportsAndDataProcessorsSafeModeInternal.ExecuteSafeModeScenario(
		SessionKey, Scenario, ExecutableObject, ExecutionParameters, ParametersToSave, TargetObjects);
	
EndFunction

#EndRegion

#Region InternalProceduresAndFunctions

// For internal use.
Function ArchiveUnpackingIteration(Val DirectoryForUnpacking, ArchiveDescription, Val FormID)
	
	Content = FindFiles(DirectoryForUnpacking, "*" , False);
	For Each ContentItem In Content Do
		If ContentItem.IsDirectory() Then
			
			ArchiveDescription.Insert(ContentItem.Name,
				ArchiveUnpackingIteration(
					ContentItem.Path + "\", New Map(), FormID));
			
		Else
			
			ArchiveDescription.Insert(ContentItem.Name,
				PutToTempStorage(New BinaryData(ContentItem.FullName),
					FormID));
			
		EndIf;
	EndDo;
	
EndFunction

// For internal use.
Procedure ArchivePackagingIteration(Val ArchiveDescription, Val PackagingDirectory)
	
	For Each ArchiveItem In ArchiveDescription Do
		
		If TypeOf(ArchiveItem.Value) = Type("Map") Then
			
			SubdirectoryName = PackagingDirectory + ArchiveItem.Key;
			CreateDirectory(SubdirectoryName);
			ArchivePackagingIteration(ArchiveItem.Value, SubdirectoryName + "\");
			
		Else
			
			GetFromTempStorage(ArchiveItem.Value).Write(
				PackagingDirectory + ArchiveItem.Key);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ValidateCallByEnvironmentCorrectness()
	
	If Not AdditionalReportsAndDataProcessorsSafeModeInternal.ValidateCallByEnvironmentCorrectness() Then
		
		Raise NStr("en = Invalid AdditionalReportsAndDataProcessorsSafeModeServerCall common module function call.
                    |In the safe mode exported functions of this module must be only called from scenarios
                    |or from client application context.'");
		
	EndIf;
	
EndProcedure

#EndRegion
