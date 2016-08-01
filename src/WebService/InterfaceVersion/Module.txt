/////////////////////////////////////////////////////////////////////////////////
// Interface versioning
//

// Returns the array of version number names supported by the InterfaceName
// subsystem.
//
// Parameters:
//  InterfaceName - String - subsystem name.
//
// Returns:
//  Array of String.
//
// Example:
//
// 	// Returns the file transfer WSProxy object for the specified version.
// 	// If FileTransferVersion = Undefined, the function returns the basic version (1.0.1.1) proxy. 
// //
// Function GetFileTransferProxy(Val ConnectionParameters, Val FileTransferVersion = Undefined)
// 	// …………………………………………………
// EndFunction
//
// Function GetFromStorage(Val FileID, Val ConnectionParameters) Export
//
// 	// Common functionality of all versions 
// 	// …………………………………………………
//
// 	// Considering the versioning
// 	SupportedVersionArray = StandardSubsystemsServer.GetSubsystemVersionArray(
// 		ConnectionParameters, "FileTransferService");
// 	If SupportedVersionArray.Find("1.0.2.1") = Undefined Then
// 		HasVersion2Support = False;
// 		Proxy = GetFileTransferProxy(ConnectionParameters);
// 	Else
// 		HasVersion2Support = True;
// 		Proxy = GetFileTransferProxy(ConnectionParameters, "1.0.2.1");
// 	EndIf;
//
// 	PartCount = Undefined;
// 	PartSize = 20 * 1024; // KB
// 	If HasVersion2Support Then
//  		TransferID = Proxy.PrepareGetFile(FileID, PartSize, PartCount);
// 	Else
// 		TransferID = Undefined;
// 		Proxy.PrepareGetFile(FileID, PartSize, TransferID, PartCount);
// 	EndIf;
//
// 	// Common functionality of all versions
// 	// …………………………………………………	
//
// EndFunction
//
Function GetVersions(InterfaceName)
	
 	VersionArray = Undefined;

	SupportedVersionStructure = New Structure;
	
	EventHandlers = CommonUse.InternalEventHandlers(
		"StandardSubsystems.BaseFunctionality\SupportedInterfaceVersionsOnDefine");
	
	For Each Handler In EventHandlers Do
		Handler.Module.SupportedInterfaceVersionsOnDefine(SupportedVersionStructure);
	EndDo;
	
	CommonUseOverridable.SupportedInterfaceVersionsOnDefine(SupportedVersionStructure);
	
	SupportedVersionStructure.Property(InterfaceName, VersionArray);
	
	If VersionArray = Undefined Then
		Return XDTOSerializer.WriteXDTO(New Array);
	Else

		Return XDTOSerializer.WriteXDTO(VersionArray);
	EndIf;	
EndFunction