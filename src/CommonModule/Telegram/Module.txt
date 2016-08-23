////////////////////////////////////////////////////////////////////////////////
//Telegram messenger

//
//
Function ReadTelegramMessages(Body)
	
	Result = New Array;
	
	Reader = New JSONReader();
	Reader.SetString(Body);
	
	
	Message = New Structure(); 
	
	IsFirst = True;
	
	While Reader.Read() Do
		
		If Reader.CurrentValueType = ТипЗначенияJSON.ИмяСвойства Then
			If Reader.CurrentValue = "update_id" Then
				If Not IsFirst Тогда
					Result.Add(Message);
				Else 
					IsFirst = False;
				EndIf;
				Message = New Structure(); 
				Reader.Read();
				Message.Insert("update_id", Reader.CurrentValue); 
			EndIf;
		EndIf;
		
		If Reader.CurrentValueType = ТипЗначенияJSON.ИмяСвойства Then		

			If Reader.CurrentValue = "text" Тогда
				Reader.Read();
				Text = TrimAll(Reader.CurrentValue);
				Message.Insert("text", Text); 		
				Message.Insert("Password", ""); 
				Words = StringFunctionsClientServer.SplitStringIntoSubstringArray(Text, " ");
				If Words.Count() >= 2 Then
					 If Words[0] = "/connect" or  Words[0] = "/start" Then
					 	Message.Insert("Password", Words[1]); 
					 EndIf; 
				EndIf; 
			EndIf;
		EndIf;
		
		If Reader.CurrentValueType = ТипЗначенияJSON.ИмяСвойства Then		

			If Reader.CurrentValue = "username" Тогда
				Reader.Read();
				Message.Insert("username", Reader.CurrentValue); 		
			EndIf;
		EndIf;
		
		If Reader.CurrentValueType = ТипЗначенияJSON.ИмяСвойства Then		

			If Reader.CurrentValue = "first_name" Тогда
				Reader.Read();
				Message.Insert("first_name", Reader.CurrentValue); 		
			EndIf;
		EndIf;

		If Reader.CurrentValueType = ТипЗначенияJSON.ИмяСвойства Then		

			If Reader.CurrentValue = "last_name" Тогда
				Reader.Read();
				Message.Insert("last_name", Reader.CurrentValue); 		
			EndIf;
		EndIf;
		
		If Reader.CurrentValueType = ТипЗначенияJSON.ИмяСвойства Then		

			If Reader.CurrentValue = "chat" Тогда
				Reader.Read();
				Reader.Read();
				Reader.Read();
				Message.Insert("ChatID", Reader.CurrentValue); 		
			EndIf;
		EndIf;		
		
	EndDo;
	
	If IsFirst Then
		Return Result;
	EndIf;
	
	Result.Add(Message);
	
	Return Result;
		
EndFunction
 

//
//
Function SendTelegramMessage(LogLineNumber, Action, CommonParams, UserName, ChatID, Message, StorageAddress = Undefined ) Export
	
	BotToken = Constants.TelegramBotToken.Get();
	If Not ValueIsFilled(BotToken) Then
		RepositoryTasks.WriteLog(LogLineNumber, CommonParams.TaskRunningEventRef, Action, Enums.ActionEventTypes.Error, "Sending report by telegram error: the constant ""TelegramBotToken"" is not specified.", StorageAddress);	
		Return False;
	EndIf; 
	
	
	SSL = New OpenSSLSecureConnection(Undefined, Undefined);	
	Connection = New HTTPConnection("api.telegram.org/bot" + BotToken,,,,,,SSL);	
	
	UpdateID = Constants.TelegramBotUpdateID.Get();
	
	// Update ChatID info (if there was a message with new ChatID)
	If UpdateID = 0 Then
		Request = New HTTPRequest("/getUpdates");
	Else
		Request = New HTTPRequest("/getUpdates?offset=" + Формат(UpdateID + 1, "ЧГ=")); 
	EndIf;
	
	Res = Connection.Get(Request);
	If Res.StatusCode = 200 Then
	MessageList = ReadTelegramMessages(Res.GetBodyAsString("UTF-8"));	
	EndIf;
		
	IndexLastMessage = MessageList.Count() - 1;	
	Если IndexLastMessage >=0 Тогда		
		 Constants.TelegramBotUpdateID.Set(MessageList[IndexLastMessage].update_id);		 
	КонецЕсли;
	
	TelegramUserNames = New Array();
	
	For Each Item In MessageList Do
		TelegramUserNames.Add(Item.username);	
	EndDo; 
	
	Query = New Query;
	Query.Text = "SELECT
	|	TelegramUsersInfo.UserName,
	|	TelegramUsersInfo.ChatID
	|FROM
	|	InformationRegister.TelegramUsersInfo AS TelegramUsersInfo
	|WHERE
	|	TelegramUsersInfo.UserName IN (&TelegramUserNames)";
	Query.SetParameter("TelegramUserNames", TelegramUserNames);
	
	TelegramUsersInfo = Query.Execute().Unload();
	
	TelegramBotPassword = TrimAll(Constants.TelegramBotPassword.Get());
	
	For Each Item In MessageList Do
		
		If ValueIsFilled(TelegramBotPassword) Then
			
			If Not ValueIsFilled(Item.Password) Then
				Request = New HTTPRequest("/sendMessage?chat_id=" + Format(Item.ChatID,"ЧГ=") + "&text=you need to input <b>password</b>.&parse_mode=HTML");				
				Connection.Get(Request);
				Continue;
			ElsIf TelegramBotPassword <> Item.Password Then
				Request = New HTTPRequest("/sendMessage?chat_id=" + Format(Item.ChatID,"ЧГ=") + "&text=Given <b>pasword</> is incorrect.&parse_mode=HTML");				
				Connection.Get(Request);
				Continue;
			EndIf; 
			
		EndIf; 
		
		TelegramUserInfo = TelegramUsersInfo.Find(Item.username, "UserName");
		If TelegramUserInfo = Undefined OR TelegramUserInfo.ChatID <> Item.ChatID AND ValueIsFilled(Item.ChatID) Then
			NewRecord = InformationRegisters.TelegramUsersInfo.CreateRecordManager();
			NewRecord.UserName = Item.username;
			NewRecord.ChatID = Item.ChatID;
			NewRecord.Write(True);
			If TelegramUserInfo <> Undefined Then
				TelegramUserInfo.ChatID = Item.ChatID;	
			EndIf; 
			
			If Item.username = UserName Then
				ChatID = Item.ChatID;
			EndIf; 
		EndIf; 
		
	EndDo; 
	
	Request = New HTTPRequest("/sendMessage?chat_id=" + Format(ChatID,"ЧГ=") + "&text=" + Message + "&parse_mode=HTML");
	Res = Connection.Get(Request);
	
	If Res.StatusCode <> 200 Then
		RepositoryTasks.WriteLog(LogLineNumber, CommonParams.TaskRunningEventRef, Action, Enums.ActionEventTypes.Error, "Sending report by telegram error: " + Res.GetBodyAsString("UTF-8"), StorageAddress);			
		Return False;
	EndIf;
	
	Return True;
	
EndFunction
