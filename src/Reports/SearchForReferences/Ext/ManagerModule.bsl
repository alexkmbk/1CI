#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region InternalInterface

// Report pane layout settings.
//
// Parameters:
//   Settings       - Collection - is used to set report settings and report options.
//                    See ReportOptions.ConfigurationReportOptionSettingsTree() for
//                    details.
//   ReportSettings - ValueTreeRow - layout settings for all report options.
//                    See "Attributes that can be changed" of the 
//                    ReportOptions.ConfigurationReportOptionSettingsTree() function.
//
// Details:
//   See ReportOptionsOverridable.SetUpReportOptions().
//
// Auxiliary methods:
//  OptionSettings = ReportOptions.OptionDetails(Settings, ReportSettings, <OptionName>);
//  ReportOptions.SetOutputModeInReportPanes(Settings, ReportSettings, True/False);
//  The report can be generated only in this mode.
//
Procedure SetUpReportOptions(Settings, ReportSettings) Export
	ReportOptionsModule = CommonUse.CommonModule("ReportOptions");
	ReportOptionsModule.SetOutputModeInReportPanes(Settings, ReportSettings, False);
	
	OptionSettings = ReportOptionsModule.OptionDetails(Settings, ReportSettings, "Default");
	OptionSettings.Enabled = False;
	OptionSettings.Details = NStr("en = 'Search where application objects are used.'");
EndProcedure

#EndRegion

#EndIf