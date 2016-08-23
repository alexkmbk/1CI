#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

// Prevents metadata object IDs editing.
// Handles duplicates of the distributed infobase subordinate node.
//
Procedure BeforeWrite(Cancel)
	
	StandardSubsystemsCached.CatalogMetadataObjectIDsUsageCheck();
	
	// Disabling the object change record mechanism.
	AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
	
	// Recording object changes in all nodes DIB.
	For Each ExchangePlan In StandardSubsystemsCached.DIBExchangePlans() Do
		StandardSubsystemsServer.RecordObjectChangesInAllNodes(ThisObject, ExchangePlan);
	EndDo;
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not AdditionalProperties.Property("ExecutingAutomaticCatalogDataUpdate") Then
		
		If IsNew() Then
		
			RaiseByError(StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Metadata object ID can be only created automatically
				           |during a catalog data update.'"),
				FullName));
				
		ElsIf Catalogs.MetadataObjectIDs.CannotChangeFullName(ThisObject) Then
			
			RaiseByError(StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'During metadata object ID change the full name 
				           |is specified as ""%1"". This name can only be
				           |set automatically during a catalog data update.'"),
				FullName));
		
		ElsIf Catalogs.MetadataObjectIDs.FullNameUsed(FullName, Ref) Then
			
			RaiseByError(StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'During metadata object ID change the full name 
				           |is specified as ""%1"". One of the catalog items 
 				          |already has this name.'"),
				FullName));
		
		EndIf;
		
		Catalogs.MetadataObjectIDs.UpdateIDProperties(ThisObject);
	EndIf;
	
	If CommonUse.IsSubordinateDIBNode() Then
		
		If IsNew()
		   And Not Catalogs.MetadataObjectIDs.IsCollection(GetNewObjectRef()) Then
			
			RaiseByError(
				NStr("en = 'Items can be added in the master node 
				           |of a distributed infobase only.'"));
		EndIf;
		
		If Not DeletionMark
		   And Not Catalogs.MetadataObjectIDs.IsCollection(Ref) Then
			
			If Upper(FullName) <> Upper(CommonUse.ObjectAttributeValue(Ref, "FullName")) Then
				RaiseByError(
					NStr("en = 'The full name can be changed in the master node 
				             |of a distributed infobase only.'"));
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

// Prevents deletion of metadata object IDs that are not marked for deletion.
Procedure BeforeDelete(Cancel)
	
	StandardSubsystemsCached.CatalogMetadataObjectIDsUsageCheck();
	
	// Disabling the  object change record mechanism.
	// ID references are deleted independently in all nodes
	// through the mechanisms of marking for deletion and marked object deletion.
	AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not DeletionMark Then
		RaiseByError(
			NStr("en = 'Cannot delete IDs of metadata objects whose ""Deletion mark""
                |attribute is set to False.'"));
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// AUXILIARY PROCEDURES AND FUNCTIONS

Procedure RaiseByError(ErrorText);
	
	Raise
		NStr("en = '""Metadata object IDs"" catalog error.'") + "
		           |
		           |" + ErrorText;
	
EndProcedure

#EndRegion

#EndIf
