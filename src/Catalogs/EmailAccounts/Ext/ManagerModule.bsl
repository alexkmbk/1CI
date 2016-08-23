#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Interface

////////////////////////////////////////////////////////////////////////////////
// Batch object modification

// Returns a list of attributes that are excluded from the scope
// of the batch object modification data processor
//
Function BatchProcessingEditableAttributes() Export
	
	Result = New Array;
	Result.Add("UseForSending");
	Result.Add("UseForReceiving");
	Return Result;
	
EndFunction

#EndRegion

#Region InternalProceduresAndFunctions

// For internal use only
Procedure FillPermissions(PermissionList) Export
	
	AccountPermissions = AccountPermissions();
	For Each Account In AccountPermissions Do
		PermissionDetails = PermissionList.Add();
		PermissionDetails.Key = Account.Key;
		PermissionDetails.Permissions = Account.Values;
	EndDo;
	
EndProcedure

// For internal use only
Function AccountPermissions(Account = Undefined) Export
	
	Result = New Map;
	
	QueryText = 
	"SELECT
	|	EmailAccounts.ProtocolForIncomingMail AS Protocol,
	|	EmailAccounts.IncomingMailServer AS Server,
	|	EmailAccounts.IncomingMailServerPort AS Port,
	|	EmailAccounts.Ref
	|INTO MailServers
	|FROM
	|	Catalog.EmailAccounts AS EmailAccounts
	|WHERE
	|	EmailAccounts.ProtocolForIncomingMail <> """"
	|	AND EmailAccounts.DeletionMark = FALSE
	|	AND EmailAccounts.UseForReceiving = TRUE
	|	AND EmailAccounts.IncomingMailServer <> """"
	|	AND EmailAccounts.IncomingMailServerPort > 0
	|
	|UNION ALL
	|
	|SELECT
	|	""SMTP"",
	|	EmailAccounts.OutgoingMailServer,
	|	EmailAccounts.OutgoingMailServerPort,
	|	EmailAccounts.Ref
	|FROM
	|	Catalog.EmailAccounts AS EmailAccounts
	|WHERE
	|	EmailAccounts.DeletionMark = FALSE
	|	AND EmailAccounts.UseForSending = TRUE
	|	AND EmailAccounts.OutgoingMailServer <> """"
	|	AND EmailAccounts.OutgoingMailServerPort > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MailServers.Ref AS Ref,
	|	MailServers.Protocol AS Protocol,
	|	MailServers.Server AS Server,
	|	MailServers.Port AS Port
	|FROM
	|	MailServers AS MailServers
	|WHERE
	|	(&Ref = UNDEFINED
	|			OR MailServers.Ref = &Ref)
	|
	|GROUP BY
	|	MailServers.Protocol,
	|	MailServers.Server,
	|	MailServers.Port,
	|	MailServers.Ref
	|TOTALS BY
	|	Ref";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Account);
	
	Accounts = Query.Execute().Select(QueryResultIteration.ByGroups);
	While Accounts.Next() Do
		Permissions = New Array;
		AccountSettings = Accounts.Select();
		While AccountSettings.Next() Do
			Permissions.Add(
				SafeMode.PermissionToUseInternetResource(
					AccountSettings.Protocol,
					AccountSettings.Server,
					AccountSettings.Port,
					NStr("en = 'Email.'")
				)
			);
		EndDo;
		Result.Insert(Accounts.Ref, Permissions);
	EndDo;
	
	Return Result;
	
EndFunction

// For internal use only
Function SingleAccountPermissions(Account) Export
	
	For Each Result In AccountPermissions(Account) Do
		Return Result.Value;
	EndDo;
	
	Return New Array;
	
EndFunction

// For internal use only
Function ExternalPermissionsQueryForAccount(Val Account) Export
	
	Return SafeMode.RequestToUseExternalResources(
		SingleAccountPermissions(Account), Account);
	
EndFunction

#EndRegion

#EndIf

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInfo, StandardProcessing)
	
	If FormType = "ObjectForm" And Not Parameters.Property("Key") And Not Parameters.Property("CopyingValue") Then
		SelectedForm = "AccountSetupWizard";
		StandardProcessing = False;
	EndIf;
	
EndProcedure

#EndRegion