﻿#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then


Procedure SessionParametersSetting(SessionParameterNames)
	
	// StandardSubsystems
	StandardSubsystemsServer.SessionParametersSetting(SessionParameterNames);
	// End StandardSubsystems
	
EndProcedure

#EndIf