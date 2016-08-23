////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
// Common use server procedures and functions for working with:
// - security profiles.
//
////////////////////////////////////////////////////////////////////////////////

#Region InternalInterface

// Retrieves an array of the separators that are in the configuration.
//
// Returns:
//  FixedArray(String) - array of String. Contains the common attributes that
//  are the separators.
//
Function SeparatorArray() Export
	
	SeparatorArray = New Array;
	
	For Each CommonAttribute In Metadata.CommonAttributes Do
		If CommonAttribute.DataSeparation = Metadata.ObjectProperties.CommonAttributeDataSeparation.Separate Then
			SeparatorArray.Add(CommonAttribute.Name);
		EndIf;
	EndDo;
	
	Return New FixedArray(SeparatorArray);
	
EndFunction

// Returns internal metadata object ID used for storing configuration permissions
// (not configuration object permissions).
//
// Returns:
//  CatalogRef.MetadataObjectIDs.
//
Function InternalMOID() Export
	
	Return Catalogs.MetadataObjectIDs.EmptyRef();
	
EndFunction

#EndRegion